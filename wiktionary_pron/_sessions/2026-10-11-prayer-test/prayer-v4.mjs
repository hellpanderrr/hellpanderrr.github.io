// Prayer test v4 — every token of complete prayers through the LIVE page, no
// lexicon filtering, with per-token coverage flags so results can be split
// into: all tokens / tokens accenteur knows / tokens our engine is confident
// on / tokens BOTH cover. This is the "proper test on a prayer".
import fs from 'node:fs';
import vm from 'node:vm';
import { createRequire } from 'node:module';

const require = createRequire('F:/projects/wiktionary_pron/wiktionary_pron/package.json');
const { chromium } = require('playwright');

const GOLD_DIR = 'F:/projects/latin-macronizer-wasm/test/data/accent-corpus';
const EXTRA = [
  ['Preface — Christo universorum Rege',
   'F:/temp/lea/latin-ecclesiastic-accents-master/corpus/missal/prefaces/De Christo universorum Rege.txt'],
];
const LIVE_URL = process.env.PRAYER_URL || 'https://hellpanderrr.github.io/wiktionary_pron/macronizer.html';
const OUT = process.env.PRAYER_OUT || 'F:/temp/lea/prayer/records.json';
process.stderr.write(`target: ${LIVE_URL}\n`);
const WORD_RE = /[A-Za-z\u00C0-\u024F\u1E00-\u1EFF\u0300-\u036F]+/g;

const deaccent = (s) => s.normalize('NFD').replace(/\u0301/g, '').normalize('NFC');
const normWord = (s) => s.normalize('NFD').replace(/\u0301/g, '').normalize('NFC')
  .toLowerCase().replace(/æ/g, 'ae').replace(/œ/g, 'oe').replace(/j/g, 'i');
const lineIsGold = (line) => /\u0301/.test(line.normalize('NFD')) || /[ǽǼ]/.test(line);

function accentIndexes(word) {
  const out = []; let idx = 0;
  for (const ch of word.toLowerCase()) {
    const nfd = ch.normalize('NFD');
    if (nfd.includes('\u0301')) out.push(idx);
    const base = nfd.replace(/[\u0300-\u036f]/g, '');
    if (base) idx += base === 'æ' || base === 'œ' ? 2 : 1;
  }
  return out;
}
function matchesGold(goldTok, cand) {
  const g = accentIndexes(goldTok);
  if (g.length > 1) return false;
  if (cand === null || cand === undefined) return g.length === 0; // bare counts only if gold bare
  let ci = accentIndexes(cand);
  if (ci.length > 1) return false;
  return ci.length === g.length && g.every((v, k) => v === ci[k]);
}
// For gold-bare tokens any output is a miss UNLESS bare — handled above: bare
// gold + bare candidate = ok; bare gold + accented candidate = miss (the
// distinct-word test counted acutes-on-bare-gold as misses too, same rule).

// ---------- accenteur ----------
function loadAccenteur(dataF, coreF) {
  const ctx = vm.createContext({ console });
  for (const f of [dataF, coreF]) {
    vm.runInContext(fs.readFileSync(`F:/temp/lea/accenteur/${f}`, 'utf8'), ctx, { filename: f });
  }
  return ctx.accentify;
}
const ACC = {
  pinned: loadAccenteur('data_pinned.js', 'core_pinned.js'),
  live: loadAccenteur('data.js', 'accenteur_core.js'),
};
const accCache = new Map();
function accOutputs(word) {
  if (accCache.has(word)) return accCache.get(word);
  const usable = (arr) => { try { return (arr ?? []).filter((c) => !/<span|<error/.test(c)); } catch { return []; } };
  const r = {
    pinF: usable(ACC.pinned(word))[0] ?? null,
    pinA: usable(ACC.pinned(word)),
    livF: usable(ACC.live(word))[0] ?? null,
    livA: usable(ACC.live(word)),
  };
  accCache.set(word, r);
  return r;
}

// ---------- live page ----------
async function runPage(page, text) {
  await page.evaluate(() => { const t = document.getElementById('resultText'); if (t) t.innerHTML = ''; });
  await page.fill('#text_to_macronize', text);
  await page.click('#macronize_btn');
  await page.waitForFunction(() => document.querySelectorAll('#resultText tr.line').length > 0, null, { timeout: 120_000 });
  let prev = -1;
  for (let i = 0; i < 80; i++) {
    const n = await page.evaluate(() =>
      document.querySelectorAll('#resultText tr.line').length + 10000 * document.querySelectorAll('#resultText span.ipa').length);
    if (n === prev && n > 0) break;
    prev = n; await page.waitForTimeout(200);
  }
  return page.evaluate(() =>
    Array.from(document.querySelectorAll('#resultText tr.line')).map((tr) =>
      Array.from(tr.querySelectorAll('span.ipa')).map((s) => ({
        content: s.getAttribute('content') ?? s.textContent,
        unknown: s.classList.contains('unknown'),
      }))));
}

// alignment within one line; every pair records which spans it consumed
function alignLine(goldToks, spans) {
  const pairs = []; let g = 0, o = 0;
  const spanText = spans.map((s) => s.content);
  while (g < goldToks.length) {
    const gt = goldToks[g];
    if (o < spans.length && normWord(spanText[o]) === normWord(gt)) {
      pairs.push({ gi: g, gold: gt, ours: spanText[o], oFrom: o, oTo: o, flag: '' }); g++; o++; continue;
    }
    let done = false;
    for (let k = 2; k <= 4 && o + k <= spans.length; k++) {
      if (normWord(spanText.slice(o, o + k).join('')) === normWord(gt)) {
        pairs.push({ gi: g, gold: gt, ours: spanText.slice(o, o + k).join(''), oFrom: o, oTo: o + k - 1, flag: 'our-split' });
        g++; o += k; done = true; break;
      }
    }
    if (done) continue;
    for (let k = 2; k <= 4 && g + k <= goldToks.length; k++) {
      if (o < spans.length && normWord(spanText[o]) === normWord(goldToks.slice(g, g + k).join(''))) {
        pairs.push({ gi: g, gold: goldToks.slice(g, g + k).join(''), ours: spanText[o], oFrom: o, oTo: o, flag: 'gold-merged' });
        g += k; o++; done = true; break;
      }
    }
    if (done) continue;
    if (o + 1 < spans.length && normWord(spanText[o + 1]) === normWord(gt)) {
      pairs.push({ gi: g, gold: '(skipped)', ours: spanText[o], oFrom: o, oTo: o, flag: 'extra-span' }); o++; continue;
    }
    if (g + 1 < goldToks.length && o < spans.length && normWord(spanText[o]) === normWord(goldToks[g + 1])) {
      pairs.push({ gi: g, gold: gt, ours: '(none)', oFrom: -1, oTo: -1, flag: 'dropped-span' }); g++; continue;
    }
    pairs.push({ gi: g, gold: gt, ours: o < spans.length ? spanText[o] : null, oFrom: o, oTo: o, flag: 'desync' });
    g++; o++;
  }
  return pairs;
}

const files = fs.readdirSync(GOLD_DIR).filter((f) => f.endsWith('.txt')).sort()
  .map((f) => [f.replace(/\.txt$/, ''), `${GOLD_DIR}/${f}`]).concat(EXTRA);

const browser = await chromium.launch({ channel: 'chrome', headless: true });
const page = await browser.newPage();
await page.goto(LIVE_URL);
await page.waitForSelector('#macronize_btn:not([disabled])', { timeout: 300_000 });
await page.evaluate(() => {
  document.getElementById('macronize').checked = false;
  document.getElementById('accent').checked = true;
});

const records = []; // every gold-line token pair
for (const [name, srcPath] of files) {
  const gold = fs.readFileSync(srcPath, 'utf8').replace(/\r\n/g, '\n');
  const plain = deaccent(gold);
  const linesAll = plain.trim().split('\n');
  const linesGold = gold.trim().split('\n');
  process.stderr.write(`run: ${name}\n`);
  const rows = await runPage(page, plain.trim());
  let lineRows = rows;
  if (rows.length !== linesAll.length) {
    const ne = linesAll.filter((l) => l.trim());
    const neRows = rows.filter((r) => r.length > 0);
    if (neRows.length === ne.length) lineRows = neRows; // empty-line difference
  }
  const n = Math.min(lineRows.length, linesAll.length);
  for (let li = 0; li < n; li++) {
    const goldLine = linesGold[li] ?? '';
    if (!lineIsGold(goldLine)) continue;      // same skip rule as the 1140-word test
    const spans = lineRows[li];
    const goldToks = [...goldLine.matchAll(WORD_RE)].map((m) => m[0]);
    const pairs = alignLine(goldToks, spans);
    for (const p of pairs) {
      const oursUnknown = p.oFrom >= 0 && spans.slice(p.oFrom, p.oTo + 1).every((s) => s.unknown);
      const at = accOutputs(deaccent(p.gold === '(skipped)' ? 'x' : p.gold));
      records.push({
        file: name, line: li, flag: p.flag,
        gold: p.gold, ours: p.ours, oursUnknown,
        pinF: at.pinF, pinA: at.pinA, livF: at.livF, livA: at.livA,
        okOurs: matchesGold(p.gold, p.ours),
        okPinF: matchesGold(p.gold, at.pinF),
        okPinA: at.pinA.some((c) => matchesGold(p.gold, c)),
        okLivF: matchesGold(p.gold, at.livF),
        okLivA: at.livA.some((c) => matchesGold(p.gold, c)),
      });
    }
  }
}
await browser.close();

function bucket(rows, label) {
  const N = rows.length;
  const pct = (k) => {
    const ok = rows.filter((r) => r[k]).length;
    return { ok, N, p: 100 * ok / N };
  };
  const o = pct('okOurs'), pf = pct('okPinF'), pa = pct('okPinA'), lf = pct('okLivF'), la = pct('okLivA');
  // mutual: ours vs pinned-first as accent positions (both bare = same)
  const same = rows.filter((r) => {
    const a = accentIndexes(r.ours ?? '').join(','), b = accentIndexes(r.pinF ?? '').join(',');
    return r.ours !== null && r.pinF !== null && a === b;
  }).length;
  console.log(`\n-- ${label}: ${N} tokens`);
  console.log(`   OURS live page        : ${o.ok}/${N} = ${o.p.toFixed(2)}%`);
  console.log(`   ACC pin 91823fe first : ${pf.ok}/${N} = ${pf.p.toFixed(2)}%`);
  console.log(`   ACC pin any candidate : ${pa.ok}/${N} = ${pa.p.toFixed(2)}%`);
  console.log(`   ACC live master first : ${lf.ok}/${N} = ${lf.p.toFixed(2)}%`);
  console.log(`   ACC live any candidate: ${la.ok}/${N} = ${la.p.toFixed(2)}%`);
  console.log(`   ours == acc-pinned-first output: ${same}/${N} = ${(100 * same / N).toFixed(2)}%`);
}

console.log('\n=================== PRAYER TEST v4 (live page, accents-only) ===================');
bucket(records, 'A. ALL gold-line tokens (no filtering)');
bucket(records.filter((r) => r.pinF !== null), 'B. tokens accenteur (pinned) covers');
bucket(records.filter((r) => !r.oursUnknown), 'C. tokens our engine is confident on (not flagged unknown)');
bucket(records.filter((r) => !r.oursUnknown && r.pinF !== null), 'D. BOTH cover (no unknown on either side)');

console.log('\nflags:');
const flags = {};
for (const r of records) if (r.flag) flags[r.flag] = (flags[r.flag] ?? 0) + 1;
console.log('  ', JSON.stringify(flags));

console.log('\nour misses on gold lines, with flags and accenteur-side status:');
for (const r of records.filter((x) => !x.okOurs)) {
  console.log(`   ${r.file} L${r.line}: ${r.gold}→${r.ours ?? '(none)'}${r.flag ? ' [' + r.flag + ']' : ''}${r.oursUnknown ? ' [unknown]' : ''} | acc-pin: ${r.pinF ?? '(none)'}${r.okPinA ? ' (any-ok)' : ''}`);
}
fs.writeFileSync(OUT, JSON.stringify(records, null, 1));
console.log(`\nrecords: ${OUT}`);
