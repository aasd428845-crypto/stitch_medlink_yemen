#!/usr/bin/env node
/**
 * ph64 preflight gate — fail-closed launch guard for LOCAL bonus E2E runs.
 *
 * Verifies, WITHOUT any network access, that the Supabase configuration an
 * app build/dev run would consume points exclusively at the isolated local
 * stack. Exit 0 = all checks pass. Any failure exits non-zero with a plain
 * message. NEVER prints secret values (presence + length only).
 *
 * Usage:
 *   node preflight.mjs --env-path <path> --expected-url <http://127.0.0.1:55421>
 *     --expected-auth-url <http://127.0.0.1:55999> --client-src <supabaseClient.ts>
 *     [--deny-refs lmkomzqioneuyvatzsov,hhqhoqwpebnmfuhwhllw]
 */
import { readFileSync, existsSync } from 'node:fs';

const FAIL = [];
function check(name, ok, detail = '') {
  console.log(`${ok ? 'PASS' : 'FAIL'} ${name}${detail ? ` — ${detail}` : ''}`);
  if (!ok) FAIL.push(name);
}

function parseArgs(argv) {
  const out = {};
  for (let i = 2; i < argv.length; i += 2) {
    const k = argv[i].replace(/^--/, '').replace(/-/g, '_');
    out[k] = argv[i + 1];
  }
  return out;
}

function parseEnvFile(path) {
  const env = {};
  for (const raw of readFileSync(path, 'utf8').split('\n')) {
    const line = raw.trim();
    if (!line || line.startsWith('#')) continue;
    const m = line.replace(/^export\s+/, '').match(/^([A-Za-z_][A-Za-z0-9_]*)\s*=\s*(.*)$/);
    if (!m) return { error: `unparseable line: ${line.slice(0, 60)}` };
    let v = m[2].trim();
    if ((v.startsWith('"') && v.endsWith('"')) || (v.startsWith("'") && v.endsWith("'"))) v = v.slice(1, -1);
    env[m[1]] = v;
  }
  return { env };
}

const PLACEHOLDER = /(\$\{|<[^>]*>|YOUR_|CHANGEME|EXAMPLE\.COM|REPLACE)/i;
const KNOWN_PROD_KEY = 'sb_publishable_yxm5GTZm87Y3wQwi019lXQ_IMLplZQc';
const LOOPBACK = /^(http:\/\/127\.0\.0\.1(:\d+)?(\/.*)?|http:\/\/localhost(:\d+)?(\/.*)?)$/;

function main() {
  const a = parseArgs(process.argv);
  const envFile = a.env_path, expectedUrl = a.expected_url,
    expectedAuth = a.expected_auth_url, clientSrc = a.client_src;
  const denyRefs = (a.deny_refs || '').split(',').map((s) => s.trim()).filter(Boolean);
  for (const [k, v] of Object.entries({ env_path: envFile, expected_url: expectedUrl, expected_auth_url: expectedAuth, client_src: clientSrc })) {
    if (!v) { console.log(`FAIL missing-arg --${k.replace(/_/g, '-')}`); process.exit(2); }
  }
  if (!existsSync(envFile)) { console.log('FAIL env-file-missing'); process.exit(2); }
  if (!existsSync(clientSrc)) { console.log('FAIL client-src-missing'); process.exit(2); }

  const parsed = parseEnvFile(envFile);
  if (parsed.error) { console.log(`FAIL env-unparseable — ${parsed.error}`); process.exit(2); }
  const env = parsed.env;

  // 1-2. URL present, non-empty, non-placeholder, exact literal match.
  const url = env.VITE_SUPABASE_URL || '';
  check('url-present', url.length > 0);
  check('url-no-placeholder', !PLACEHOLDER.test(url));
  check('url-exact-match', url === expectedUrl, url === expectedUrl ? '' : 'value differs from expected (not shown)');

  // 3. Key present, non-empty, non-placeholder, not the known production key.
  const key = env.VITE_SUPABASE_ANON_KEY || '';
  check('key-present', key.length > 0, key.length > 0 ? `(length ${key.length})` : '');
  check('key-no-placeholder', key.length === 0 || !PLACEHOLDER.test(key));
  check('key-not-production', key.length === 0 || key !== KNOWN_PROD_KEY,
    key.length > 0 && key === KNOWN_PROD_KEY ? 'matches known production key' : '');

  // 4. Every VITE_* var scanned: loopback-only, no denied refs.
  let viteOk = true, viteDetail = '';
  for (const [k, v] of Object.entries(env)) {
    if (!k.startsWith('VITE_') || v.length === 0) continue;
    if (/https?:\/\//i.test(v) && !LOOPBACK.test(v)) { viteOk = false; viteDetail = `${k} is not loopback`; break; }
    if (/supabase\.co/i.test(v)) { viteOk = false; viteDetail = `${k} references supabase.co`; break; }
    if (denyRefs.some((r) => v.includes(r))) { viteOk = false; viteDetail = `${k} contains denied ref`; break; }
  }
  check('vite-vars-loopback-only', viteOk, viteDetail);

  // 5-6. Source audit: every env var the client reads must be defined;
  // fallback presence is recorded (env must override it, proven above).
  const src = readFileSync(clientSrc, 'utf8');
  const readVars = [...new Set([...src.matchAll(/import\.meta\.env\.(VITE_[A-Za-z0-9_]+)/g)].map((m) => m[1]))];
  check('client-src-readable-vars-found', readVars.length > 0, `reads: ${readVars.join(',') || 'none'}`);
  const missing = readVars.filter((v) => !(env[v] && env[v].length > 0));
  check('no-unresolved-fallback', missing.length === 0,
    missing.length > 0 ? `would fall back for: ${missing.join(',')}` : 'all reads satisfied by env (fallback dead code in this run)');
  const clientCalls = (src.match(/createClient\(/g) || []).length;
  check('single-client-callsite', clientCalls === 1, `createClient sites: ${clientCalls}`);

  // 7. Auth derivation contract: base + /auth/v1 must equal the expected auth URL.
  check('auth-derivation', `${url.replace(/\/$/, '')}/auth/v1` === expectedAuth);

  if (FAIL.length > 0) {
    console.log(`BLOCKED (${FAIL.length} failed: ${FAIL.join(', ')})`);
    process.exit(1);
  }
  console.log('GATE PASSED — config points exclusively at the local stack');
}
main();
