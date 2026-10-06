/**
 * Check a help page against the engine. Run from scripts/tests/:
 *   node verify_help_page.mjs <page.html> <Language> <Style> <Form> [--raw <code> <fn> [--extra '[true]']]
 * 1. Every TOC href="#x" must resolve to an id="x".
 * 2. Every "<word> <span class="ipa">/x/</span>" pair (a Latin/Cyrillic word directly followed by an IPA span)
 *    is re-run through the engine; the IPA must equal the engine output (slashes/brackets stripped).
 *    Comma-joined multi-variant outputs match if the page IPA is one of the variants.
 * Pairs the script can't attribute to a word are not checked — this is a fabrication tripwire, not a proof.
 */
import "./setup.cjs";
import { readFileSync, writeFileSync } from "node:fs";

const [page, lang, style, form, ...rest] = process.argv.slice(2);
// Inline emphasis inside a word ("<strong>b</strong>ok", "<u>ś</u>miech") would split it; drop such tags.
const html = readFileSync(page, "utf8").replace(
  /(?<=[\p{L}\p{M}])<\/?(?:b|strong|u|mark)>(?=[\p{L}\p{M}])/gu,
  "",
);

const ids = new Set([...html.matchAll(/\bid="([^"]+)"/g)].map((m) => m[1]));
const badAnchors = [...html.matchAll(/href="#([^"]+)"/g)].map((m) => m[1]).filter((a) => !ids.has(a));

const strip = (s) => s.replace(/<[^>]+>/g, "").trim();
const norm = (s) => s.normalize("NFC").replace(/^[\/\[]+|[\/\]]+$/g, "").trim();
// A word preceded by a comma is the tail of a list ("ласка, ліс | /ɫaska/, /lʲis/") — can't be paired, skip.
const pairRe = /(?<![\p{L}\p{M}'’-]|,\s*)([\p{L}\p{M}'’-]+)\s*(?:<\/?(?:em|i|b|strong|td)>\s*)*(?:→\s*)?<span class="ipa">([^<]+)<\/span>/gu;
const SCRIPT = { Russian: /\p{Script=Cyrillic}/u, Belorussian: /\p{Script=Cyrillic}/u, Bulgarian: /\p{Script=Cyrillic}/u,
  Ukrainian: /\p{Script=Cyrillic}/u, Mongolian: /\p{Script=Cyrillic}/u, Armenian: /\p{Script=Armenian}/u,
  Greek: /\p{Script=Greek}/u };
const inScript = SCRIPT[lang] || /\p{Script=Latin}/u;
const pairs = new Map();
for (const m of html.matchAll(pairRe)) {
  const word = strip(m[1]);
  if (!inScript.test(word) || word.length < 2) continue;
  const ipa = norm(m[2]);
  if ([...ipa].length < 3 || /\s/.test(ipa)) continue;
  if (!pairs.has(word)) pairs.set(word, new Set());
  pairs.get(word).add(ipa);
}

const initTest = (await import("./init.js")).default;
await initTest();
const { get_ipa_no_cache } = await import("../utils.js");
const CODES = { Russian: "ru", Belorussian: "be", Bulgarian: "bg", Ukrainian: "uk", Lithuanian: "lt",
  Icelandic: "is", Mongolian: "mn", Portuguese: "pt", Armenian: "hy", German: "de", French: "fr",
  Greek: "grc", Irish: "ga", Latin: "la", Polish: "pl", Spanish: "es", Czech: "cs" };
// Style/Form may be comma lists ("Classical,Ecclesiastical" "Phonetic,Phonemic"); a pair passes if ANY combination matches.
const styles = style.split(",");
const forms = form.split(",");
let raw = null;
if (rest[0] === "--raw") {
  raw = { code: rest[1], fn: rest[2], extra: rest[3] === "--extra" ? JSON.parse(rest[4]) : [] };
}
const code = raw ? raw.code : CODES[lang];
const luaState = global.window.lua;
await luaState.doString(`${code} = require("${code}-pron_wasm")`);
global.window[code + "_ipa"] = luaState.global.get(code);

const runOne = (w, s, f) => {
  try {
    if (raw) return String(global.window[code + "_ipa"][raw.fn](w, ...raw.extra));
    return String(get_ipa_no_cache(w, `${lang};${s};${f}`).value);
  } catch (e) { return `THROWS: ${e.message}`; }
};
const runAll = (w) => {
  const outs = [];
  for (const s of styles) for (const f of forms) outs.push(runOne(w, s, f));
  return outs;
};

let ok = 0;
const mismatches = [];
for (const [word, ipas] of pairs) {
  const outs = runAll(word);
  const variants = new Set(outs.flatMap((o) => [norm(o), ...o.split(",").map(norm)]));
  for (const ipa of ipas) {
    if (variants.has(ipa)) ok++;
    else mismatches.push({ word, page: ipa, engine: [...new Set(outs)].join(" || ") });
  }
}
// --sync: rewrite page IPA to the closest engine variant when the difference is notational
// (normalized edit distance <= SYNC_MAX); larger differences are only reported for manual review.
if (process.argv.includes("--sync")) {
  const SYNC_MAX = 0.34;
  const lev = (a, b) => {
    a = [...a]; b = [...b];
    const d = Array.from({ length: a.length + 1 }, (_, i) => [i, ...Array(b.length).fill(0)]);
    for (let j = 1; j <= b.length; j++) d[0][j] = j;
    for (let i = 1; i <= a.length; i++)
      for (let j = 1; j <= b.length; j++)
        d[i][j] = Math.min(d[i - 1][j] + 1, d[i][j - 1] + 1, d[i - 1][j - 1] + (a[i - 1] === b[j - 1] ? 0 : 1));
    return d[a.length][b.length];
  };
  let text = readFileSync(page, "utf8");
  let synced = 0;
  for (const m of mismatches) {
    if (/-/.test(m.word)) { console.log(`  REVIEW(hyphen) ${m.word}\tpage=${m.page}`); continue; }
    if (m.engine.includes("THROWS")) { console.log(`  REVIEW ${m.word}\tpage=${m.page}\tengine=${m.engine}`); continue; }
    const cands = [...new Set(m.engine.split(" || ").flatMap((o) => o.split(",")).map(norm).filter(Boolean))];
    const best = cands.map((c) => ({ c, r: lev(c, m.page) / Math.max([...c].length, [...m.page].length) }))
      .sort((x, y) => x.r - y.r)[0];
    if (!best || best.r > SYNC_MAX) { console.log(`  REVIEW ${m.word}\tpage=${m.page}\tengine=${m.engine}`); continue; }
    const wordRe = m.word.replace(/[.*+?^${}()|[\]\\]/g, "\\$&");
    const pageRe = m.page.replace(/[.*+?^${}()|[\]\\]/g, "\\$&");
    const re = new RegExp(`(${wordRe}\\s*(?:</?(?:em|i|b|strong|td)>\\s*)*(?:→\\s*)?<span class="ipa">[/\\[]?)${pageRe}([/\\]]?</span>)`, "gu");
    const before = text;
    text = text.replace(re, `$1${best.c}$2`);
    if (text !== before) { synced++; console.log(`  SYNC ${m.word}\t${m.page} -> ${best.c}`); }
    else console.log(`  REVIEW(no-match) ${m.word}\tpage=${m.page}\tengine=${m.engine}`);
  }
  writeFileSync(page, text, "utf8");
  console.log(`SYNCED ${synced}`);
}
console.log(`VERIFY ${page}: anchors-bad=${badAnchors.length} pairs-checked=${ok + mismatches.length} ok=${ok} mismatch=${mismatches.length}`);
for (const a of badAnchors) console.log(`  BAD-ANCHOR #${a}`);
for (const m of mismatches) console.log(`  MISMATCH ${m.word}\tpage=${m.page}\tengine=${m.engine}`);
process.exit(0);
