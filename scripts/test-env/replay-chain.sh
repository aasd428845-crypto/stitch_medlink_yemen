#!/usr/bin/env bash
# PHASE 51 — replay the interleaved migration chain (PHASE-8 §5.2) into the
# ISOLATED scratch container medlink_ph51_test.
# Hard isolation guards (PHASE-50 §4.2 C1/C3):
#   * target is always `docker exec` into the named scratch container;
#   * abort if the container ref/label looks like a production target;
#   * never read supabase/.temp/project-ref, never pass --linked, never run db push/reset.
set -euo pipefail

REPO="/home/adman/stitch_medlink_yemen"
CONTAINER="medlink_ph51_test"
ROOT_MIG="$REPO/supabase/migrations"
WEB_MIG="$REPO/Medlik-Waap/supabase/migrations"
STOP_AT="${1:-0022}"   # "0022" = pre-fix tip; "0023" = +fix; "0024" = +posted-journal fix; "0030" = +E1 GL config (0028/0029/0030)

# --- guard: refuse anything that resembles a production target ---------------
for banned in lmkomzqioneuyvatzsov hhqhoqwpebnmfuhwhllw; do
  [[ "$STOP_AT" == *"$banned"* || "$CONTAINER" == *"$banned"* ]] && { echo "ABORT: banned target"; exit 1; }
done
LABEL=$(docker inspect -f '{{index .Config.Labels "medlink-purpose"}}' "$CONTAINER" || true)
[[ "$LABEL" != "ph51-isolated-bonus-test" ]] && { echo "ABORT: container $CONTAINER is not the isolated ph51 scratch"; exit 1; }

# --- guard: container is not linked to any cloud project ---------------------
[[ -e "$REPO/supabase/.temp/project-ref" ]] && { echo "NOTE: repo link exists but this script never uses it."; }

exec_sql() { docker exec -i "$CONTAINER" \
  psql -U supabase_admin -d postgres -v ON_ERROR_STOP=1 --single-transaction -q; }

echo "== prerequisites =="
exec_sql < "$REPO/scripts/test-env/bootstrap-prereqs.sql"

# Known repo defect: supabase/migrations/0013_invoices_select_rls.sql is tracked
# in git with a stray XML closing tag `</content>` at EOF (pre-existing corruption,
# NOT introduced by this phase). Migration files are never modified; replay pipes
# them through a sanitizer that drops that exact stray line.
sanitize() { sed -e '/^<\/content>$/d'; }

R() { echo "--> R-$1"; sanitize < "$ROOT_MIG/$1_"*".sql" | exec_sql; }
W() { echo "--> W-$1"; sanitize < "$WEB_MIG/$1.sql" | exec_sql; }

# Root 0001-0008 (base schema).
R 0001; R 0002; R 0003; R 0004; R 0005; R 0006; R 0007; R 0008
# Web foundation through the unblocker W-0004 (creates invoices + warehouse_inventory).
W 0001_phase1_foundation
W 0002_phase2_readonly_analytics
W 0003_phase3_offer_product_discount_columns
W 0004_phase4_expiry_and_receivables
# R-0009 needs those web tables.
R 0009; W 0005_flexible_notification_targeting
R 0010; R 0011; R 0012; R 0013; R 0014
# Web financial chain.
W 0006_financial_core
W 0007_financial_setup_rls
W 0008_financial_audit_immutability
W 0009_financial_auto_posting
W 0010_financial_simple_entries
W 0011_financial_doctors_payouts
W 0012_financial_receipts_columns
W 0013_financial_exchange_rates_live
W 0014_product_catalog_sync
# Divergence point 0015/0016: use the MAIN-REPO variants (root is the richer,
# authoritative version of the shared schema; the web copies claim to mirror it).
R 0015
R 0016
# Bonus core + earn engine + discounts + cancellation: R-0017 .. R-0022
R 0017; R 0018; R 0019; R 0020; R 0021; R 0022

if [[ "$STOP_AT" == "0023" || "$STOP_AT" == "0024" || "$STOP_AT" == "0030" ]]; then
  echo "--> R-0023 (the fix)"
  exec_sql < "$ROOT_MIG/0023_bonus_rule_max_earn_contract_fix.sql"
fi

if [[ "$STOP_AT" == "0024" || "$STOP_AT" == "0030" ]]; then
  echo "--> R-0024 (posted/pending triggers)"
  exec_sql < "$ROOT_MIG/0024_fix_posted_journal_posting.sql"
fi

# Chain-integrity assertion (PHASE 72): at the fixed tip the four guard
# functions must carry the corrected 0024 bodies and the three protection
# triggers must exist. Fails closed (ON_ERROR_STOP aborts the script) if the
# chain stopped early or a legacy W-0008/W-0010 fragment was applied on top of
# 0024. Read-only; see scripts/test-env/ph72-chain-integrity.sql.
if [[ "$STOP_AT" == "0024" || "$STOP_AT" == "0030" ]]; then
  echo "== chain integrity assertion (ph72) =="
  exec_sql < "$REPO/scripts/test-env/ph72-chain-integrity.sql"
fi

# PHASE 4B — E1 → GL fully-configurable account policy (0028/0029/0030).
# 0028 = fail-closed decision hook + AFTER INSERT trigger (PENDING request);
# 0029 = director role→account map + journal leg layout; 0030 = the director
# post RPC (reads debit/credit codes from the per-earn snapshot — no hardcode).
if [[ "$STOP_AT" == "0030" ]]; then
  echo "--> R-0028 (E1 decision hook + trigger)"
  exec_sql < "$ROOT_MIG/0028_bonus_earn_gl_integration.sql"
  echo "--> R-0029 (role→account map + journal leg layout)"
  exec_sql < "$ROOT_MIG/0029_bonus_role_account_mapping.sql"
  echo "--> R-0030 (director GL post RPC)"
  exec_sql < "$ROOT_MIG/0030_bonus_earn_gl_posting.sql"
fi

echo "== DONE at $STOP_AT =="
