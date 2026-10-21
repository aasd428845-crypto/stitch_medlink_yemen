#!/usr/bin/env bash
# =============================================================
# PHASE 64 §6 — isolated-DB verification of bonus earn → GL
# integration (0028 + 0030, plus the new 0029 mapping table).
#
# This is a SIBLING of replay-chain.sh (ph51) — it does NOT touch the
# medlink_ph51_test container or the ph51 image. It boots a FRESH,
# throwaway scratch container labelled medlink-purpose=ph64-bonus-gl-test,
# replays the shared chain 0001..0024, then applies 0028/0029/0030 and the
# ph64 probe suite (ph64-probes.sql). The container is removed on exit.
#
# §7 safety: NO supabase db push; NO commit/push/deploy; NO stop/delete of any
# existing container (medlink_ph51_test, ph51_pg, etc.); NO production refs;
# NO secrets in files. Applies only to the throwaway ph64 scratch.
# =============================================================
set -euo pipefail

REPO="/home/adman/stitch_medlink_yemen"
CONTAINER="medlink_ph64_bonus_gl_test"
IMAGE="public.ecr.aws/supabase/postgres:17.6.1.155"   # same image as the ph51 scratch (locally present)
ROOT_MIG="$REPO/supabase/migrations"
WEB_MIG="$REPO/Medlik-Waap/supabase/migrations"
PROBE="$REPO/scripts/test-env/ph64-probes.sql"
FIXTURE="$REPO/scripts/test-env/ph51-fixtures.sql"
BOOTSTRAP="$REPO/scripts/test-env/bootstrap-prereqs.sql"

# --- guard: refuse anything that resembles a production target ---------------
for banned in lmkomzqioneuyvatzsov hhqhoqwpebnmfuhwhllw ph51 medlink_ph51_test ph51_pg; do
  [[ "$CONTAINER" == *"$banned"* ]] && { echo "ABORT: reserved/targeting name '$CONTAINER'"; exit 1; }
done
# NOTE (mirrors replay-chain.sh semantics): a local supabase link marker may
# exist in the repo, but this script NEVER reads or uses project-ref — it only
# ever `docker exec`s psql into the throwaway scratch container above. No
# `supabase db push` is ever issued; the banned-ref check above (on the
# container NAME) is the real production guard.
if [[ -e "$REPO/supabase/.temp/project-ref" ]]; then
  echo "NOTE: repo link present but unused (psql is scoped to $CONTAINER only; no db push)";
fi

# --- guard: never stop/delete the ph51 scratch; only manage our own container --
cleanup() {
  if docker ps -a --format '{{.Names}}' 2>/dev/null | grep -qx "$CONTAINER"; then
    echo "== cleanup: removing only $CONTAINER (ph51 is untouched) =="
    docker rm -f "$CONTAINER" 2>/dev/null || true
  fi
}
trap cleanup EXIT

# start a FRESH isolated scratch container (rm if a stale sibling exists)
if docker ps -a --format '{{.Names}}' 2>/dev/null | grep -qx "$CONTAINER"; then
  echo "== reusing stale scratch $CONTAINER (will reset) =="; docker rm -f "$CONTAINER" 2>/dev/null || true
fi
echo "== starting isolated scratch: $CONTAINER (label ph64-bonus-gl-test) =="
# Local ephemeral scratch only (never exposed/published): trust auth is the
# same posture replay-chain.sh's ph51 compose applies to the scratch DB.
docker run -d --rm \
  --name "$CONTAINER" \
  --label "medlink-purpose=ph64-bonus-gl-test" \
  -e POSTGRES_HOST_AUTH_METHOD=trust \
  "$IMAGE" >/dev/null

echo "== waiting for postgres to become ready (past init + post-init restart) =="
# The supabase/postgres image boots an init-mode postgres, runs its init scripts
# (/docker-entrypoint-initdb.d/migrate.sh builds the `auth` schema + `pg_graphql`
# skeleton + storage), prints "PostgreSQL init process complete; ready for start
# up." and RESTARTS postgres ONCE to settle into real mode. auth.users / auth.uid
# ARE callable in init-mode too, so a naive readiness gate can pass mid-init and
# the single restart will then kill the postgres that serves the very next
# migration `exec` (we saw "container is not running" land exactly here once).
#
# Defence: (1) wait for the init-complete marker in docker logs — this only fires
# after init-mode scripts finish and the real postgres is about to take over;
# (2) THEN demand auth.users present + auth.uid callable + container health
# "healthy", twice in a row, so we ride past the transient unhealthy window that
# the restart opens. 400 x 2s is generous for the slow, variable image init.
#
# NOTE: we deliberately do NOT run a probe DDL here — the image leaves pg_graphql
# in a half-installed state (increment_schema_version exists, its sequence does
# not) and a DDL would trip that event trigger. bootstrap-prereqs.sql completes
# pg_graphql (creating the sequence) BEFORE any migration DDL runs.
init_seen=0
for i in $(seq 1 300); do
  if docker logs "$CONTAINER" 2>&1 | grep -q "PostgreSQL init process complete; ready for start up\."; then
    init_seen=1; break
  fi
  sleep 2
done
if [[ "$init_seen" != "1" ]] && docker inspect "$CONTAINER" --format '{{json .State.Health.Status}}' 2>/dev/null | grep -q '"healthy"'; then
  # reused/seeded container that skipped init — fall through to the auth check
  init_seen=1
fi
ready=0; stable_hits=0
for i in $(seq 1 400); do
  # NOTE: to_regclass(...) is qualified only when a schema in search_path hides the
  # name; on this image it prints the bare `users`, so test the OID directly via
  # `is not null` (returns `t`) rather than matching the display string.
  hs=$(docker inspect "$CONTAINER" --format '{{json .State.Health.Status}}' 2>/dev/null)
  if [[ "$hs" == '"healthy"' ]]; then
    if docker exec "$CONTAINER" psql -U supabase_admin -d postgres -v ON_ERROR_STOP=1 -tAc "select to_regclass('auth.users') is not null" 2>/dev/null | grep -q '^t$'; then
      if docker exec "$CONTAINER" psql -U supabase_admin -d postgres -v ON_ERROR_STOP=0 -tAc "select auth.uid() is not null or true" 2>/dev/null | grep -q '^t$'; then
        stable_hits=$((stable_hits+1))
        [ "$stable_hits" -ge 2 ] && { ready=1; break; }
      fi
    fi
  fi
  sleep 2
done
if [[ "$ready" != "1" ]]; then
  echo "ABORT: scratch not stable (init marker + auth.users/auth.uid + health)"; docker logs "$CONTAINER" 2>&1 | tail -25; exit 1
fi
echo "== scratch ready (auth.users + auth.uid present; pg_graphql completed in bootstrap) =="

exec_sql() { docker exec -i "$CONTAINER" psql -U supabase_admin -d postgres -v ON_ERROR_STOP=1 --single-transaction -q "$@"; }
sanitize() { sed -e '/^<\/content>$/d'; }

# --- helpers: resolve then APPLY one ROOT / WEB migration (own transaction) ----
R() { # R 0017  -> $ROOT_MIG/0017_*.sql (exactly one)
  local n="$1" f
  f=$(ls -1 "$ROOT_MIG"/${n}_*.sql 2>/dev/null) || true
  if [[ $(printf '%s\n' "$f" | grep -c .) -ne 1 ]]; then echo "ABORT: root $n matched ($(printf '%s\n' "$f" | grep -c .) files)"; exit 1; fi
  echo "--> R-$n"
  sanitize < "$f" | exec_sql
}
W() { # W 0006_financial_core  -> $WEB_MIG/<name>.sql
  local n="$1" f
  f="$WEB_MIG/$n.sql"
  [[ -f "$f" ]] || { echo "ABORT: web $n not found at $f"; exit 1; }
  echo "--> W-$n"
  sanitize < "$f" | exec_sql
}

# --- 1) bootstrap (storage/realtime/pg_graphql for the bare image) -------------
echo "== bootstrap-prereqs =="
exec_sql < "$BOOTSTRAP"

# --- 2) shared chain 0001..0024 (mirrors replay-chain.sh, per-migration tx) ----
echo "== replaying shared chain 0001..0024 =="
R 0001; R 0002; R 0003; R 0004; R 0005; R 0006; R 0007; R 0008
W 0001_phase1_foundation
W 0002_phase2_readonly_analytics
W 0003_phase3_offer_product_discount_columns
W 0004_phase4_expiry_and_receivables
R 0009
W 0005_flexible_notification_targeting
R 0010; R 0011; R 0012; R 0013; R 0014
W 0006_financial_core
W 0007_financial_setup_rls
W 0008_financial_audit_immutability
W 0009_financial_auto_posting
W 0010_financial_simple_entries
W 0011_financial_doctors_payouts
W 0012_financial_receipts_columns
W 0013_financial_exchange_rates_live
W 0014_product_catalog_sync
R 0015; R 0016; R 0017; R 0018; R 0019; R 0020; R 0021; R 0022
R 0023; R 0024

# --- 3) the new E1→GL integration migrations (0028/0029/0030) -----------------
echo "== applying 0028/0029/0030 (bonus earn → GL integration) =="
R 0028; R 0029; R 0030

# --- 4) fixtures (director/client users, products, etc.) ----------------------
echo "== applying ph51-fixtures =="
exec_sql < "$FIXTURE"

# --- 5) the SQL A/B/C (+D/E/F) probes -----------------------------------------
echo "== running ph64 probes =="
exec_sql < "$PROBE"

echo "== DONE: ph64 scratch verification complete =="
