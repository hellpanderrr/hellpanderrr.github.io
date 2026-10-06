/**
 * Check "known issues"-style table rows (<td>word</td><td>/system output/</td>...) against the engine.
 * Run from scripts/tests/:  node verify_issue_tables.mjs <page.html> <Language> <Style[,Style]> <Form[,Form]>
 * A row passes if the second cell equals the engine output for any listed style/form combination.
 */
import "./setup.cjs";
import { readFileSync } from "node:fs";

const [page, lang, style, form] = process.argv.slice(2);
const html = readFileSync(page, "utf8");
const CODES = { German: "de", French: "fr", Polish: "pl", Spanish: "es", Latin: "la", Armenian: "hy", Greek: "grc",
  Irish: "ga", Russian: "ru", Ukrainian: "uk", Belorussian: "be", Bulgarian: "bg", Icelandic: "is",
  Lithuanian: "lt", Mongolian: "mn", Portuguese: "pt", Czech: "cs" };
const strip = (s) => s.replace(/<[^>]+>/g, "").replace(/&nbsp;/g, " ").trim();
const norm = (s) => s.normalize("NFC").replace(/^[\/\[]+|[\/\]]+$/g, "").trim();

const rows = [];
for (const tr of html.matchAll(/<tr>([\s\S]*?)<\/tr>/g)) {
  const cells = [...tr[1].matchAll(/<td[^>]*>([\s\S]*?)<\/td>/g)].map((m) => strip(m[1]));
  if (cells.length < 3) continue;
  const [word, out] = cells;
  if (!/^[\p{L}\p{M}'’-]+$/u.test(word)) continue;
  if (!/^[\/\[][^\/\[\]]+[\/\]]$/.test(out)) continue;
  rows.push({ word, out: norm(out) });
}

const initTest = (await import("./init.js")).default;
await initTest();
const { get_ipa_no_cache } = await import("../utils.js");
const code = CODES[lang];
await global.window.lua.doString(`${code} = require("${code}-pron_wasm")`);
global.window[code + "_ipa"] = global.window.lua.global.get(code);

let ok = 0;
for (const r of rows) {
  const outs = [];
  for (const s of style.split(",")) for (const f of form.split(",")) {
    try { outs.push(String(get_ipa_no_cache(r.word, `${lang};${s};${f}`).value)); } catch (e) { outs.push(`THROWS`); }
  }
  const variants = new Set(outs.flatMap((o) => [norm(o), ...o.split(",").map(norm)]));
  if (variants.has(r.out)) ok++;
  else console.log(`  STALE ${r.word}\tpage=${r.out}\tengine=${[...new Set(outs)].join(" || ")}`);
}
console.log(`ISSUE-TABLES ${page}: rows=${rows.length} ok=${ok} stale=${rows.length - ok}`);
process.exit(0);
