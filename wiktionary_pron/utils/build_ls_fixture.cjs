#!/usr/bin/env node
// Build utils/ls_golden_fixture.json — the minimal Lewis & Short entry set the
// golden suite touches, so `npm run test:gloss` runs in CI, where the 30MB
// utils/ext_tmp/ L&S dump is deliberately NOT committed (gitignore: "build input
// ... not shipped"). The test resolves every golden row through the LIVE defs of
// build_glosses.cjs, so it needs real L&S entries; the fixture supplies exactly
// the ones the 2067+ rows can reach — including the failure-path entries a
// resolve() only touches when an earlier lookup misses (the "vestitus2" class).
//
//   node utils/build_ls_fixture.cjs
//
// Regenerate after adding/editing rows in utils/gloss_golden.json that touch new
// L&S lemmas, or after the extractor starts reading different keys. Commit the
// regenerated utils/ls_golden_fixture.json in the same commit as the golden edit.
// Needs utils/ext_tmp/ on disk — run locally, never in CI.
//
// Method: fixpoint over the eval'd defs. Start with an empty selected set and
// repeatedly (1) eval the defs with only the selected entries loaded, (2) run
// every golden row through resolve(), recording every lsByKey key it looked for
// but missed, (3) add the whole base-family of each missed key. Grows until no
// new entries appear — by construction the committed fixture reproduces the full
// 30MB dump for every golden row (enforced as a drift guard by
// test_gloss_regression.cjs when utils/ext_tmp/ is present locally).

const fs = require("fs");
const path = require("path");
const zlib = require("zlib");

const GOLDEN = "utils/gloss_golden.json";
const OUT = "utils/ls_golden_fixture.json";
const EXTRACT_ROOT = path.join("utils", "ext_tmp");

// ---- full L&S dump (local only) ----
const lsAll = new Map();
for (const c of "ABCDEFGHIJKLMNOPQRSTUVXYZ") {
  const p = path.join(EXTRACT_ROOT, `ls_${c}.json`);
  if (!fs.existsSync(p)) continue;
  for (const e of JSON.parse(fs.readFileSync(p, "utf8"))) {
    if (e && e.key) lsAll.set(String(e.key).toLowerCase(), e);
  }
}
if (!lsAll.size) {
  console.error(`${EXTRACT_ROOT}/ has no L&S data — run this locally, not in CI.`);
  process.exit(1);
}
// base ("mora", digits stripped) → all keys in that family, for O(1) closure.
const famByBase = new Map();
for (const ek of lsAll.keys()) {
  const b = ek.replace(/\d+$/, "");
  if (!famByBase.has(b)) famByBase.set(b, []);
  famByBase.get(b).push(ek);
}

// ---- eval the extractor defs with the L&S load redirected to a global array ----
const src = fs.readFileSync("utils/build_glosses.cjs", "utf8");
const head = src.slice(0, src.indexOf("// ---- build ----"));
const LS_BLOCK_RE = /\/\/ ---- L&S index ----\nconst lsByKey = new Map\(\), lsByBase = new Map\(\);\n[\s\S]*?\n\}\n/;
const WL_BLOCK = `const rows = new Map();
const formSets = new Map();
const lemmaPosCount = new Map();
for (const line of fs.readFileSync("macronizer/macrons.txt","utf8").split("\\n")) {
  const p = line.split("\\t"); if (p.length<4) continue;
  const lem = p[2].toLowerCase();
  rows.set(p[2]+"|"+p[1], {lemma:p[2], tag:p[1]});
  if (!formSets.has(lem)) formSets.set(lem, new Set());
  formSets.get(lem).add(p[0]+"|"+p[3]);
  const pos = POS_MAP[p[1][0]] || p[1][0];
  if (!lemmaPosCount.has(lem)) lemmaPosCount.set(lem, {});
  lemmaPosCount.get(lem)[pos] = (lemmaPosCount.get(lem)[pos]||0)+1;
}
`;
function makeDefs() {
  if (!LS_BLOCK_RE.test(head)) {
    throw new Error("build_glosses.cjs L&S load changed — update LS_BLOCK_RE in " + __filename);
  }
  let d = head
    .replace(WL_BLOCK, "var rows = new Map(), formSets = new Map(), formSetsTag = new Map(), lemmaPosCount = new Map();\n")
    .replace(LS_BLOCK_RE, `// ---- L&S index (fixture source) ----
var lsByKey = new Map(), lsByBase = new Map();
for (const e of globalThis.__LS_SOURCE__) {
  if (!e || !e.key) continue;
  const key = String(e.key).toLowerCase();
  lsByKey.set(key, e);
  const base = key.replace(/\\d+$/, "");
  if (!lsByBase.has(base)) lsByBase.set(base, []);
  lsByBase.get(base).push(e);
}
`);
  d = d.replace(/^const \{ createEngine \} = .*$/gm, "").replace(/^const (fs|path|zlib|engine) = .*$/gm, "").replace(/^const engine = .*$/gm, "");
  d = d.replace(/\bconst\s+/g, "var ").replace(/\blet\s+/g, "var ");
  return d;
}
const defs = makeDefs();
const golden = JSON.parse(fs.readFileSync(GOLDEN, "utf8"));

function loadCache() {
  const cache = JSON.parse(zlib.gunzipSync(fs.readFileSync("utils/gloss_lemma_cache.json.gz")));
  for (const [lem, e] of Object.entries(cache)) {
    if (e.forms) formSets.set(lem, new Set(e.forms));
    if (e.formsTag) formSetsTag.set(lem, new Set(e.formsTag));
  }
  for (const [lem, e] of Object.entries(cache)) lemmaPosCount.set(lem, e.pos);
  const origDominantPos = dominantPos;
  dominantPos = function (l) {
    const cnt = lemmaPosCount.get(l);
    if (!cnt) return origDominantPos(l);
    let best = null, bestN = 0;
    for (const [p, n] of Object.entries(cnt)) if (n > bestN) { best = p; bestN = n; }
    return best || "N";
  };
}

// ---- fixpoint ----
let selected = new Set();
for (let iter = 0; ; iter++) {
  if (iter > 60) { console.error("fixture fixpoint did not converge"); process.exit(1); }
  globalThis.__LS_SOURCE__ = [...selected].map((k) => lsAll.get(k));
  eval(defs);
  loadCache();
  // record every lsByKey lookup that came up empty
  const miss = new Set();
  const origGet = lsByKey.get.bind(lsByKey);
  lsByKey.get = function (k) {
    if (k != null && !lsByKey.has(String(k))) miss.add(String(k));
    return origGet(k);
  };
  for (const row of golden) {
    try { resolve(row.lemma, dominantPos(row.lemma.toLowerCase())); } catch (e) {}
  }
  let added = 0;
  for (const k of miss) {
    for (const ek of famByBase.get(k.replace(/\d+$/, "")) || []) {
      if (!selected.has(ek)) { selected.add(ek); added++; }
    }
  }
  if (added === 0) break;
  console.log(`iter ${iter}: ${selected.size} entries (+${added})`);
}

const out = [...selected].sort().map((k) => lsAll.get(k));
fs.writeFileSync(OUT, JSON.stringify(out));
const kb = Math.round(fs.statSync(OUT).size / 1024);
console.log(`wrote ${OUT}: ${out.length} entries, ${kb} KB (of ${lsAll.size} total)`);
