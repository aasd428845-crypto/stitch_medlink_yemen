#!/usr/bin/env bash
# =============================================================
# PHASE 64 §6 — isolated-DB snapshot-isolation probe for the
# bonus-earn → GL integration (PROBE G: policy/mapping change does
# not rewrite history).
#
# This is a FOCUSED sibling of ph64-bonus-gl-verify.sh: it boots the SAME
# throwaway scratch container (medlink_ph64_bonus_gl_test), replays the shared
# chain 0001..0024 + 0028/0029/0030, loads ph51-fixtures, then runs ONLY
# ph64-snapshot-isolation.sql (PROBE G). It does NOT re-run A–F.
#
# §7 safety: NO supabase db push; NO commit/push/deploy; NO stop/delete of any
# existing container; NO production refs; NO secrets. Scratch only; removed on exit.
# =============================================================
set -euo pipefail

REPO="/home/adman/stitch_medlink_yemen"
CONTAINER="medlink_ph64_bonus_gl_test"
IMAGE="public.ecr.aws/supabase/postgres:17.6.1.155"   # same image as ph51 scratch (locally present)
ROOT_MIG="$REPO/supabase/migrations"
WEB_MIG="$REPO/Medlik-Waap/supabase/migrations"
PROBE="$REPO/scripts/test-env/ph64-snapshot-isolation.sql"
FIXTURE="$REPO/scripts/test-env/ph51-fixtures.sql"
BOOTSTRAP="$REPO/scripts/test-env/bootstrap-prereqs.sql"

# --- guard: refuse anything that resembles a production target ------------------
for banned in lmkomzqioneuyvatzsov hhqhoqwpebnmfuhwhllw ph51 medlink_ph51_test ph51_pg; do
  [[ "$CONTAINER" == *"$banned"* ]] && { echo "ABORT: reserved/targeting name '$CONTAINER'"; exit 1; }
done
if [[ -e "$REPO/supabase/.temp/project-ref" ]]; then
  echo "NOTE: repo link present but unused (psql is scoped to $CONTAINER only; no db push)";
fi

# --- guard: never stop/delete the ph51 scratch; only manage our own container ---
cleanup() {
  if docker ps -a --format '{{.Names}}' 2>/dev/null | grep -qx "$CONTAINER"; then
    echo "== cleanup: removing only $CONTAINER (ph51 is untouched) =="
    docker rm -f "$CONTAINER" 2>/dev/null || true
  fi
}
trap cleanup EXIT

if docker ps -a --format '{{.Names}}' 2>/dev/null | grep -qx "$CONTAINER"; then
  echo "== reusing stale scratch $CONTAINER (will reset) =="; docker rm -f "$CONTAINER" 2>/dev/null || true
fi
echo "== starting isolated scratch: $CONTAINER (label ph64-snapshot-isolation) =="
docker run -d --rm \
  --name "$CONTAINER" \
  --label "medlink-purpose=ph64-snapshot-isolation" \
  -e POSTGRES_HOST_AUTH_METHOD=trust \
  "$IMAGE" >/dev/null

echo "== waiting for postgres to become ready (past init + post-init restart) =="
init_seen=0
for i in $(seq 1 300); do
  if docker logs "$CONTAINER" 2>&1 | grep -q "PostgreSQL init process complete; ready for start up\."; then
    init_seen=1; break
  fi
  sleep 2
done
if [[ "$init_seen" != "1" ]] && docker inspect "$CONTAINER" --format '{{json .State.Health.Status}}' 2>/dev/null | grep -q '"healthy"'; then
  init_seen=1
fi
ready=0; stable_hits=0
for i in $(seq 1 400); do
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

R() { # R 0017 -> $ROOT_MIG/0017_*.sql (exactly one)
  local n="$1" f
  f=$(ls -1 "$ROOT_MIG"/${n}_*.sql 2>/dev/null) || true
  if [[ $(printf '%s\n' "$f" | grep -c .) -ne 1 ]]; then echo "ABORT: root $n matched ($(printf '%s\n' "$f" | grep -c .) files)"; exit 1; fi
  echo "--> R-$n"
  sanitize < "$f" | exec_sql
}
W() { # W 0006_financial_core -> $WEB_MIG/<name>.sql
  local n="$1" f
  f="$WEB_MIG/$n.sql"
  [[ -f "$f" ]] || { echo "ABORT: web $n not found at $f"; exit 1; }
  echo "--> W-$n"
  sanitize < "$f" | exec_sql
}

echo "== bootstrap-prereqs =="
exec_sql < "$BOOTSTRAP"

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

echo "== applying 0028/0029/0030 (bonus earn → GL integration) =="
R 0028; R 0029; R 0030

echo "== applying ph51-fixtures =="
exec_sql < "$FIXTURE"

echo "== running ph64 snapshot-isolation probe (PROBE G only) =="
exec_sql < "$PROBE"

echo "== DONE: ph64 snapshot-isolation probe complete =="
