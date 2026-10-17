// Full-corpus accent test: the live macronizer page vs BrRoman/accenteur, on
// every prose text of the gregorio latin-ecclesiastic-accents corpus that has
// independent (Solesmes / Vatican) accents. Same scoring as prayer-v4.mjs:
// every token of every gold line, in order; unknown = miss.
//
// Excluded: hymns/ (metrical — the corpus says they cannot be accented
// automatically), psalms/vatican/ (accents generated with Collatinus, the data
// Accenteur is built from — circular), various/Breviarium O.P. 1952 (hymns),
// the duplicate Regula "with dates" and the duplicate various/Gloria.
//
// Resumable: one JSON record file per corpus file under OUT_DIR; finished
// files are skipped on restart.
//
// Run from wiktionary_pron/ (Playwright resolves there):
//   node _sessions/2026-10-11-prayer-test/corpus-run.mjs
// Env: CORPUS (corpus root), ACC_DIR (accenteur copies), OUT_DIR, PRAYER_URL.
import fs from 'node:fs';
import path from 'node:path';
import vm from 'node:vm';
import { createRequire } from 'node:module';

const require = createRequire(path.resolve('package.json'));
const { chromium } = require('playwright');

const CORPUS = process.env.CORPUS || 'F:/temp/lea/latin-ecclesiastic-accents-master/corpus';
const ACC_DIR = process.env.ACC_DIR || 'F:/temp/lea/accenteur';
const OUT_DIR = process.env.OUT_DIR || 'F:/temp/lea/corpus-run';
const URL = process.env.PRAYER_URL || 'https://hellpanderrr.github.io/wiktionary_pron/macronizer.html';
const CHUNK = 100; // input lines per page run

const WORD_RE = /[A-Za-z\u00C0-\u024F\u1E00-\u1EFF\u0300-\u036F]+/g;
const HAS_WORD = /[A-Za-z\u00C0-\u024F\u1E00-\u1EFF]/;
const LIMIT = Number(process.env.LIMIT || Infinity);
const deaccent = (s) => s.normalize('NFD').replace(/\u0301/g, '').normalize('NFC');
const normWord = (s) => deaccent(s).toLowerCase().replace(/æ/g, 'ae').replace(/œ/g, 'oe').replace(/j/g, 'i');
const isGoldLine = (l) => /\u0301/.test(l.normalize('NFD')) || /[ǽǼ]/.test(l);

// ---------- file selection ----------
function walk(dir) {
  return fs.readdirSync(dir, { withFileTypes: true }).flatMap((d) =>
    d.isDirectory() ? walk(path.join(dir, d.name)) : [path.join(dir, d.name)]);
}
const EXCLUDE = [/[\\/]hymns[\\/]/, /[\\/]psalms[\\/]vatican[\\/]/, /Breviarium O\.P\. 1952/,
  /Regula Sancti Benedicti with dates/, /[\\/]various[\\/]Gloria in excelsis/];
const files = walk(CORPUS).filter((f) => f.endsWith('.txt') && !EXCLUDE.some((re) => re.test(f))).sort().slice(0, LIMIT);

// ---------- accenteur ----------
function loadAccenteur(dataF, coreF) {
  const ctx = vm.createContext({ console });
  for (const f of [dataF, coreF]) vm.runInContext(fs.readFileSync(path.join(ACC_DIR, f), 'utf8'), ctx, { filename: f });
  return ctx.accentify;
}
const ACC = { pinned: loadAccenteur('data_pinned.js', 'core_pinned.js'), live: loadAccenteur('data.js', 'accenteur_core.js') };
const accCache = new Map();
function acc(word) {
  if (accCache.has(word)) return accCache.get(word);
  const usable = (fn) => { try { return (fn(word) ?? []).filter((c) => !/<span|<error/.test(c)); } catch { return []; } };
  const p = usable(ACC.pinned), l = usable(ACC.live);
  const r = { pinF: p[0] ?? null, pinA: p, livF: l[0] ?? null, livA: l };
  accCache.set(word, r);
  return r;
}

// ---------- page ----------
async function runPage(page, text) {
  await page.evaluate(() => { const t = document.getElementById('resultText'); if (t) t.innerHTML = ''; });
  await page.fill('#text_to_macronize', text);
  await page.click('#macronize_btn');
  await page.waitForFunction(() => document.querySelectorAll('#resultText tr.line').length > 0, null, { timeout: 300_000 });
  let prev = -1;
  for (let i = 0; i < 150; i++) {
    const n = await page.evaluate(() =>
      document.querySelectorAll('#resultText tr.line').length + 100000 * document.querySelectorAll('#resultText span.ipa').length);
    if (n === prev && n > 0) break;
    prev = n; await page.waitForTimeout(200);
  }
  return page.evaluate(() =>
    Array.from(document.querySelectorAll('#resultText tr.line')).map((tr) =>
      Array.from(tr.querySelectorAll('span.ipa')).map((s) => ({
        content: s.getAttribute('content') ?? s.textContent,
        // The engine's own output (marks aligned onto the typed letters) —
        // the page re-renders from the wordlist candidate instead.
        engine: s.__token && s.__token.stressedText != null
          ? s.__token.stressedText + (s.__enclitic || '') : null, // enclitic is merged into the span
        unknown: s.classList.contains('unknown'),
      }))));
}

// alignment within one line (merge-aware), as in prayer-v4.mjs
function alignLine(goldToks, spans) {
  const pairs = []; let g = 0, o = 0;
  const st = spans.map((s) => s.content);
  while (g < goldToks.length) {
    const gt = goldToks[g];
    if (o < st.length && normWord(st[o]) === normWord(gt)) { pairs.push({ gi: g, gold: gt, oFrom: o, oTo: o, flag: '' }); g++; o++; continue; }
    let done = false;
    for (let k = 2; k <= 4 && o + k <= st.length; k++) {
      if (normWord(st.slice(o, o + k).join('')) === normWord(gt)) { pairs.push({ gi: g, gold: gt, oFrom: o, oTo: o + k - 1, flag: 'our-split' }); g++; o += k; done = true; break; }
    }
    if (done) continue;
    for (let k = 2; k <= 4 && g + k <= goldToks.length; k++) {
      if (o < st.length && normWord(st[o]) === normWord(goldToks.slice(g, g + k).join(''))) { pairs.push({ gi: g, gold: goldToks.slice(g, g + k).join(''), oFrom: o, oTo: o, flag: 'gold-merged' }); g += k; o++; done = true; break; }
    }
    if (done) continue;
    if (o + 1 < st.length && normWord(st[o + 1]) === normWord(gt)) { o++; continue; } // extra span
    if (g + 1 < goldToks.length && o < st.length && normWord(st[o]) === normWord(goldToks[g + 1])) { pairs.push({ gi: g, gold: gt, oFrom: -1, oTo: -1, flag: 'dropped-span' }); g++; continue; }
    pairs.push({ gi: g, gold: gt, oFrom: o, oTo: o, flag: 'desync' }); g++; o++;
  }
  return pairs.map((p) => ({
    ...p,
    ours: p.oFrom < 0 || p.oFrom >= st.length ? null : st.slice(p.oFrom, p.oTo + 1).join(''),
    engine: p.oFrom < 0 || p.oFrom >= st.length ? null
      : spans.slice(p.oFrom, p.oTo + 1).map((x) => x.engine ?? '').join('') || null,
    oursUnknown: p.oFrom >= 0 && p.oFrom < st.length && spans.slice(p.oFrom, p.oTo + 1).every((s) => s.unknown),
  }));
}

// ---------- main ----------
fs.mkdirSync(OUT_DIR, { recursive: true });
const browser = await chromium.launch({ channel: 'chrome', headless: true });
const page = await browser.newPage();
await page.goto(URL);
await page.waitForSelector('#macronize_btn:not([disabled])', { timeout: 300_000 });
await page.evaluate(() => {
  document.getElementById('macronize').checked = false;
  document.getElementById('accent').checked = true;
});
console.log(`target ${URL} | ${files.length} files`);

const t0 = Date.now();
let doneTok = 0;
for (const [fi, file] of files.entries()) {
  const rel = path.relative(CORPUS, file).replace(/\\/g, '/');
  const out = path.join(OUT_DIR, rel.replace(/[\\/]/g, '__') + '.json');
  if (fs.existsSync(out)) continue;
  // Keep only lines with at least one word, so each input line is one row.
  const lines = fs.readFileSync(file, 'utf8').replace(/\r\n/g, '\n').split('\n').filter((l) => HAS_WORD.test(l));
  const records = []; let mismatched = 0;
  for (let c = 0; c < lines.length; c += CHUNK) {
    const goldLines = lines.slice(c, c + CHUNK);
    const rows = await runPage(page, goldLines.map(deaccent).join('\n'));
    if (rows.length !== goldLines.length) { mismatched += goldLines.length; continue; } // can't align safely
    goldLines.forEach((gl, li) => {
      if (!isGoldLine(gl)) return;
      const goldToks = [...gl.matchAll(WORD_RE)].map((m) => m[0]);
      for (const p of alignLine(goldToks, rows[li])) {
        const a = acc(deaccent(p.gold));
        records.push({ line: c + li, gold: p.gold, ours: p.ours, engine: p.engine, oursUnknown: p.oursUnknown, flag: p.flag,
          pinF: a.pinF, pinA: a.pinA, livF: a.livF, livA: a.livA });
      }
    });
  }
  fs.writeFileSync(out, JSON.stringify({ file: rel, mismatchedLines: mismatched, records }));
  doneTok += records.length;
  const min = ((Date.now() - t0) / 60000).toFixed(1);
  console.log(`[${fi + 1}/${files.length}] ${rel}: ${records.length} tokens${mismatched ? `, ${mismatched} lines unaligned` : ''} (${min} min, ${doneTok} tokens this session)`);
}
await browser.close();
console.log('DONE');
