#!/usr/bin/env bash
# ph64 gate self-tests — NO network, NO app launch, NO database contact.
# Fixtures live in /tmp only (never the repo). Exit non-zero on first failure.
set -euo pipefail
REPO="/home/adman/stitch_medlink_yemen"
GATE="$REPO/local-test/ph64/preflight.mjs"
SRC="$REPO/Medlik-Waap/artifacts/pharma-pwa/src/lib/supabaseClient.ts"
TDIR="$(mktemp -d /tmp/opencode/ph64-gate-XXXXXX)"
trap 'rm -rf "$TDIR"' EXIT
URL="http://127.0.0.1:55421"; AUTH="http://127.0.0.1:55999"
REFS="lmkomzqioneuyvatzsov,hhqhoqwpebnmfuhwhllw"
pass=0; fail=0
expect() { # $1=name $2=expected_exit $3...=gate args
  local name="$1" want="$2"; shift 2
  set +e; out=$(node "$GATE" "$@" 2>&1); code=$?; set -e
  if [ "$code" -eq "$want" ]; then pass=$((pass+1)); echo "PASS $name (exit $code)";
  else fail=$((fail+1)); echo "FAIL $name (want $want, got $code)"; echo "$out" | head -8; fi
}
# Mint a REAL local anon JWT (HS256, node:crypto) from the local secret.
# Never stored in the repo; lives only in $TDIR fixtures.
KEY=$(node -e '
const fs=require("fs"),crypto=require("crypto");
const secret=fs.readFileSync("'"$REPO"'/local-test/ph61/.jwt_secret","utf8").trim();
const b64=(o)=>Buffer.from(JSON.stringify(o)).toString("base64url");
const h=b64({alg:"HS256",typ:"JWT"}),p=b64({role:"anon",exp:9999999999});
process.stdout.write(h+"."+p+"."+crypto.createHmac("sha256",secret).update(h+"."+p).digest("base64url"));')
mk() { printf 'VITE_SUPABASE_URL=%s\nVITE_SUPABASE_ANON_KEY=%s\n%s' "$2" "$3" "${4:-}" > "$TDIR/$1"; }

STD="--expected-url $URL --expected-auth-url $AUTH --client-src $SRC --deny-refs $REFS"
mk ok.env "$URL" "$KEY"
# T1: derivation-contract control (auth URL = base + /auth/v1) proves the pass path.
expect T1-derivation-contract 0 --env-path "$TDIR/ok.env" --expected-url "$URL" --expected-auth-url "$URL/auth/v1" --client-src "$SRC" --deny-refs "$REFS"
# T1b: REAL stack topology (GoTrue on :55999, no Kong) must FAIL auth-derivation.
# This is the honest current verdict: no single-URL config can reach both services.
set +e; node "$GATE" --env-path "$TDIR/ok.env" $STD >/tmp/opencode/t1b.out 2>&1; t1b=$?; set -e
if [ "$t1b" -ne 0 ] && grep -q "FAIL auth-derivation" /tmp/opencode/t1b.out; then pass=$((pass+1)); echo "PASS T1b-stack-topology-blocked (auth-derivation fails as designed)"; else fail=$((fail+1)); echo "FAIL T1b-stack-topology-blocked"; fi
rm -f /tmp/opencode/t1b.out
expect T2-missing-file 2 --env-path "$TDIR/nope.env" $STD
mk nourl.env "" "$KEY"; sed -i '/^VITE_SUPABASE_URL=$/d' "$TDIR/nourl.env" 2>/dev/null || true
printf 'VITE_SUPABASE_ANON_KEY=%s\n' "$KEY" > "$TDIR/nourl.env"
expect T3-missing-url 1 --env-path "$TDIR/nourl.env" $STD
mk cloud.env "https://lmkomzqioneuyvatzsov.supabase.co" "sb_publishable_yxm5GTZm87Y3wQwi019lXQ_IMLplZQc"
OUTCLOUD=$(node "$GATE" --env-path "$TDIR/cloud.env" $STD 2>&1; true)
set +e; node "$GATE" --env-path "$TDIR/cloud.env" $STD >/dev/null 2>&1; cc=$?; set -e
[ "$cc" -ne 0 ] && pass=$((pass+1)) && echo "PASS T4-cloud-rejected (exit $cc)" || { fail=$((fail+1)); echo "FAIL T4-cloud-rejected"; }
echo "$OUTCLOUD" | grep -q "sb_publishable_yxm5" && { fail=$((fail+1)); echo "FAIL T4b-secret-leaked-in-output"; } || { pass=$((pass+1)); echo "PASS T4b-no-secret-in-output"; }
mk nokey.env "$URL" ""
printf 'VITE_SUPABASE_URL=%s\n' "$URL" > "$TDIR/nokey.env"
expect T5-missing-key 1 --env-path "$TDIR/nokey.env" $STD
mk conflict.env "$URL" "$KEY" "VITE_X=https://evil.example/hook"
expect T6-conflicting-var 1 --env-path "$TDIR/conflict.env" $STD
printf 'VITE_OTHER=%s\nVITE_SUPABASE_ANON_KEY=%s\n' "$URL" "$KEY" > "$TDIR/unresolved.env"
expect T7-unresolved-fallback 1 --env-path "$TDIR/unresolved.env" $STD
mk badauth.env "$URL" "$KEY"
expect T8-auth-mismatch 1 --env-path "$TDIR/badauth.env" --expected-url "$URL" --expected-auth-url "http://127.0.0.1:12345" --client-src "$SRC" --deny-refs "$REFS"
echo "=== gate self-tests: pass=$pass fail=$fail ==="
[ "$fail" -eq 0 ]
