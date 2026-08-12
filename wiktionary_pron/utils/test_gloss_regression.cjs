#!/usr/bin/env node
// Golden-suite regression runner for the gloss extractor (M-005). Hand-labeled
// expectations in utils/gloss_golden.json are resolved through the LIVE defs of
// utils/build_glosses.cjs (same eval trick as _probe_one.cjs) — no 6-minute build.
//
// The L&S source is the COMMITTED fixture utils/ls_golden_fixture.json (the 30MB
// utils/ext_tmp/ dump is gitignored, so CI has no L&S data), giving the suite
// IDENTICAL semantics in CI and locally. Regenerate the fixture after golden
// edits with `npm run build:gloss-fixture` and commit it alongside. When
// utils/ext_tmp/ IS present locally, a drift guard re-runs against the full dump
// and fails if the fixture no longer reproduces it (see utils/build_ls_fixture.cjs).
//
// The wordlist parse (macrons.txt, 812k lines) is cached in
// utils/gloss_lemma_cache.json.gz so a run is ~1-2s, not ~4s+3.3s.
//
//   node utils/test_gloss_regression.cjs             # run the golden suite
//   node utils/test_gloss_regression.cjs --rebuild-cache   # rebuild wordlist meta
//   node utils/test_gloss_regression.cjs --tier=full        # resolve all lemmas → /tmp
//
// Exit code 0 iff every golden row passes. The suite is the anti-whack-a-mole:
// every past failure class is locked forever (add a row in the same commit as a fix).

const fs = require("fs");
const path = require("path");
const zlib = require("zlib");

const CACHE = "utils/gloss_lemma_cache.json.gz";
const GOLDEN = "utils/gloss_golden.json";

// ---- load the extractor's defs (eval'd, like _probe_one.cjs) ----
const src = fs.readFileSync("utils/build_glosses.cjs", "utf8");
const head = src.slice(0, src.indexOf("// ---- build ----"));
// Strip the wordlist parse loop; the maps get populated from cache below.
const WL_BLOCK = `const rows = new Map();
const formSets = new Map();
const lemmaPosCount = new Map();
for (const line of fs.readFileSync("macronizer/macrons.txt","utf8").split("\\n")) {
  const p = line.split("\\t"); if (p.length<4) continue;
  const lem = p[2].toLowerCase();
  rows.set(p[2]+"|"+p[1], {lemma:p[2], tag:p[1]});
  if (!formSets.has(lem)) formSets.set(lem, new Set());
  // ACCENT-BASED form signature (must match build_glosses.cjs H1 fix — the
  // wordlist's field-4 accented form disambiguates distinct homographs).
  formSets.get(lem).add(p[0]+"|"+p[3]);
  const pos = POS_MAP[p[1][0]] || p[1][0];
  if (!lemmaPosCount.has(lem)) lemmaPosCount.set(lem, {});
  lemmaPosCount.get(lem)[pos] = (lemmaPosCount.get(lem)[pos]||0)+1;
}
`;
let defs = head.replace(WL_BLOCK, "var rows = new Map(), formSets = new Map(), formSetsTag = new Map(), lemmaPosCount = new Map();\n");
const FIXTURE = "utils/ls_golden_fixture.json";
const hasFullLs = fs.existsSync(path.join("utils", "ext_tmp"));
// ---- L&S source = the committed fixture (see build_ls_fixture.cjs) ----
const LS_BLOCK_RE = /\/\/ ---- L&S index ----\nconst lsByKey = new Map\(\), lsByBase = new Map\(\);\n[\s\S]*?\n\}\n/;
const LS_FIXTURE_BLOCK = `// ---- L&S index (CI fixture: utils/ls_golden_fixture.json) ----
var lsByKey = new Map(), lsByBase = new Map();
for (const e of JSON.parse(fs.readFileSync("utils/ls_golden_fixture.json", "utf8"))) {
  if (!e || !e.key) continue;
  const key = String(e.key).toLowerCase();
  lsByKey.set(key, e);
  const base = key.replace(/\\d+$/, "");
  if (!lsByBase.has(base)) lsByBase.set(base, []);
  lsByBase.get(base).push(e);
}
`;
function makeDefs(useFixture) {
  let d = head.replace(WL_BLOCK, "var rows = new Map(), formSets = new Map(), formSetsTag = new Map(), lemmaPosCount = new Map();\n");
  if (useFixture) {
    if (!LS_BLOCK_RE.test(d)) throw new Error("build_glosses.cjs L&S load changed — update LS_BLOCK_RE in " + __filename);
    d = d.replace(LS_BLOCK_RE, LS_FIXTURE_BLOCK);
  }
  d = d.replace(/^const \{ createEngine \} = .*$/gm, "").replace(/^const (fs|path|zlib|engine) = .*$/gm, "").replace(/^const engine = .*$/gm, "");
  d = d.replace(/\bconst\s+/g, "var ").replace(/\blet\s+/g, "var ");
  return d;
}
if (!fs.existsSync(FIXTURE)) {
  console.error(`Missing ${FIXTURE} — run \`npm run build:gloss-fixture\` locally (needs utils/ext_tmp/) and commit it.`);
  process.exit(1);
}
// Authoritative pass always uses the fixture → identical semantics in CI and locally.
eval(makeDefs(true));

// ---- wordlist cache ----
if (process.argv.includes("--rebuild-cache") || !fs.existsSync(CACHE)) {
  console.log("building wordlist cache...");
  const rowsM = new Map();
  for (const line of fs.readFileSync("macronizer/macrons.txt", "utf8").split("\n")) {
    const p = line.split("\t"); if (p.length < 4) continue;
    rowsM.set(p[2], true);
  }
  const out = {};
  // rebuild per-lemma form sets + POS counts from the raw forms
  const fMap = new Map();
  for (const line of fs.readFileSync("macronizer/macrons.txt", "utf8").split("\n")) {
    const p = line.split("\t"); if (p.length < 4) continue;
    const lem = p[2].toLowerCase();
    const pos = POS_MAP[p[1][0]] || p[1][0];
    let e = out[lem];
    if (!e) { e = out[lem] = { pos: {}, forms: [], formsTag: [] }; }
    e.pos[pos] = (e.pos[pos] || 0) + 1;
    // DUAL-SIGNATURE (must match build_glosses.cjs): form+accent for formSets,
    // form+tag for formSetsTag — isSpurious requires both to match the bare twin.
    e.forms.push(p[0] + "|" + p[3]);
    e.formsTag.push(p[0] + "|" + p[1]);
  }
  fs.writeFileSync(CACHE, zlib.gzipSync(JSON.stringify(out)));
  console.log(`cached ${Object.keys(out).length} lemmas`);
}

function loadWordlistCache() {
  const cache = JSON.parse(zlib.gunzipSync(fs.readFileSync(CACHE)));
  for (const [lem, e] of Object.entries(cache)) {
    if (e.forms) formSets.set(lem, new Set(e.forms));
    if (e.formsTag) formSetsTag.set(lem, new Set(e.formsTag));
  }
  // dominantPos reads lemmaPosCount — rebuild it faithfully, then override dominantPos
  for (const [lem, e] of Object.entries(cache)) lemmaPosCount.set(lem, e.pos);
  const origDominantPos = dominantPos;
  dominantPos = function (l) {
    const cnt = lemmaPosCount.get(l);
    if (!cnt) return origDominantPos(l);
    let best = null, bestN = 0;
    for (const [p, n] of Object.entries(cnt)) if (n > bestN) { best = p; bestN = n; }
    return best || "N";
  };
  return cache;
}
const cache = loadWordlistCache();

// ---- golden suite ----
const golden = JSON.parse(fs.readFileSync(GOLDEN, "utf8"));
const norm = (s) => (s || "").toLowerCase().replace(/[.,;]$/, "").replace(/\s+/g, " ").trim();
let engine = null;
// CORE_GLOSS keys must each have a golden row — a curated override with no
// regression gate would silently rot (monotone rule: every override gets a golden
// row in the same commit). No-op when utils/core_gloss.json doesn't exist yet.
const coreGlossPath = "utils/core_gloss.json";
const coreFails = [];
if (fs.existsSync(coreGlossPath)) {
  const core = JSON.parse(fs.readFileSync(coreGlossPath, "utf8"));
  const covered = new Set(golden.map(r => r.lemma.toLowerCase()));
  for (const k of Object.keys(core)) {
    if (!covered.has(k)) coreFails.push({ lemma: k, expect: { contains: core[k] }, got: "(no golden row)", note: "core_gloss override missing from golden suite" });
  }
  for (const row of golden) {
    if (core[row.lemma] && row.expect !== null && !evalExpect(row.expect, core[row.lemma], (s)=>(s||"").toLowerCase())) {
      coreFails.push({ lemma: row.lemma, expect: row.expect, got: core[row.lemma], note: "core_gloss override contradicts golden expectation" });
    }
  }
}
function runGoldenSuite() {
  const fails = [];
  let pass = 0;
  for (const row of golden) {
    const { lemma, expect, note, wordsOnly } = row;
    let got = null;
    try {
      const pos = dominantPos(lemma.toLowerCase());
      got = resolve(lemma, pos);
      if (!got && wordsOnly) {
        // WORDS-only fallback path (gender-tolerant): lazily init the engine.
        if (!engine) engine = require("whitakers-words/node").createEngine();
        got = wGloss(lemma, pos, "");
      }
    } catch (e) { got = "ERROR: " + e.message; }
    if (evalExpect(expect, got, norm)) pass++;
    else fails.push({ lemma, expect, got, note });
  }
  return { pass, fails };
}
// The authoritative run resolves through the fixture (identical in CI and locally).
const main = runGoldenSuite();

// ---- drift guard (local only): the full 30MB dump must reproduce the fixture ----
// Re-eval with the full dump whenever it exists (so --tier=full below still
// resolves against real L&S); compare against the fixture only in normal mode.
if (hasFullLs) {
  eval(makeDefs(false));
  loadWordlistCache();
  if (!process.argv.includes("--tier=full")) {
    const full = runGoldenSuite();
    const stale = main.fails.filter(f => !full.fails.some(g => g.lemma === f.lemma));
    if (stale.length) {
      console.error(`\nL&S fixture STALE: ${stale.length} rows pass with utils/ext_tmp/ but not with ${FIXTURE}.`);
      console.error(`Run \`npm run build:gloss-fixture\` and commit the regenerated fixture.`);
      for (const s of stale) console.error(`  ${s.lemma}: expect ${JSON.stringify(s.expect)} got ${JSON.stringify(s.got)}`);
    }
  }
}

const fails = [...coreFails, ...main.fails];
const fail = fails.length;
const pass = golden.length - main.fails.length;
console.log(`\n${pass} passed, ${fail} failed (${golden.length} total)`);
for (const f of fails) {
  console.log(`\nFAIL ${f.lemma}  (${f.note || ""})`);
  console.log(`  expect: ${JSON.stringify(f.expect)}`);
  console.log(`  got:    ${JSON.stringify(f.got)}`);
}
if (process.argv.includes("--tier=full")) {
  const all = [...new Set([...Object.keys(cache)])];
  const lines = [];
  for (const lem of all) {
    const pos = dominantPos(lem);
    const g = resolve(lem, pos);
    if (g) lines.push(`${lem}\t${g}`);
  }
  const outPath = "C:/Users/HELLPA~1/AppData/Local/Temp/gloss_full.tsv";
  fs.writeFileSync(outPath, lines.join("\n"));
  console.log(`\nfull resolve: ${lines.length} lemmas → ${outPath}`);
}
process.exit(fail ? 1 : 0);

function evalExpect(expect, got, norm) {
  if (expect === null) return got === null;
  const preds = Array.isArray(expect.alternates) ? expect.alternates : [expect];
  // alternates: any matching predicate passes
  for (const p of preds) {
    if (got === null) continue;
    const g = norm(got);
    if (p.exact !== undefined) {
      if (norm(p.exact) === g) return true;
    } else if (p.contains !== undefined) {
      // Normalize the expectation the SAME way as got (norm strips trailing
      // punctuation + collapses whitespace) — otherwise a gloss ending "B.C." is
      // normed to "b.c" but compared against the raw "b.c." and fails.
      if (g.includes(norm(p.contains))) return true;
    } else if (p.startsWith !== undefined) {
      if (g.startsWith(norm(p.startsWith))) return true;
    } else if (p.regex !== undefined) {
      if (new RegExp(p.regex, "i").test(got)) return true;
    }
  }
  return false;
}
