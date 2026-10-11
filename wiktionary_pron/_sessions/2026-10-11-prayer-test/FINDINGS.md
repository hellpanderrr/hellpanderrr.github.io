# Full-prayer token test — macronizer page vs Accenteur (2026-10-11)

**Question.** The SE answer (latin.SE 27176, answer 27340) quoted "97-98% agreement"
from a distinct-word list filtered to our wordlist; a moderator questioned the
gap. What do the tools score on whole prayers, as a user runs them?

**Files.** `prayer-v4.mjs` is here; the records JSONs and Accenteur copies are
not committed. To re-run, re-fetch Accenteur's `static/js/data.js` +
`accenteur_core.js` at `91823fe07b269189e8c0dd87a39caefdc1052c7d` (saved as
`data_pinned.js`/`core_pinned.js`) and at master (`data.js`/`accenteur_core.js`)
into `F:/temp/lea/accenteur/`, the path the script reads (edit it if moved); the
Preface comes from the gregorio corpus (`corpus/missal/prefaces/`).

**Method.** `prayer-v4.mjs` (run from `F:/projects/wiktionary_pron/wiktionary_pron`
so Playwright resolves; `PRAYER_URL` = live or local page, `PRAYER_OUT` = records file).
- Texts: the 13 Ordo Missae gold files (`latin-macronizer-wasm/test/data/accent-corpus`)
  + the Preface "De Christo universorum Rege" (gregorio corpus). Input = the gold
  text with acutes removed. Lines with no acute are rubrics and are skipped
  (same rule as `test:accent`); 3152 gold-line tokens.
- Ours: the real page in Chrome, "Mark long vowels" off, "Stress accents" on;
  spans read per result row, aligned per line (merge-aware).
- Accenteur: `accentify()` run in a Node VM at `91823fe` (README link,
  `data_pinned.js`/`core_pinned.js`) and master (`data.js`/`accenteur_core.js`,
  byte-identical to the live demo). Files in `F:/temp/lea/accenteur/`.
- Scoring per token: accent position must equal gold; bare gold needs bare
  output; unknown = miss. **Strict** also requires the same word (æ≡ae, j≡i).

**Results** (`records.json` = live before fix, `records-local-fix.json` = local after M-031):

| | before (live) | after fix (local) |
|---|---|---|
| ours, strict | 3125/3152 = 99.14% | 3136/3152 = 99.49% |
| ours, raw (position only) | 99.37% | 99.49% |
| wrong-word tokens | 12 | 0 |
| Accenteur 91823fe, first / any | 98.79% / 99.43% | same |
| Accenteur master, first / any | 98.22% / 99.33% | same |
| same output as Accenteur 91823fe | 98.83% | 98.95% |
| both-cover subset (3111): ours / Acc 91823fe | 99.39% / 99.13% | 99.52% / 99.13% |

**Hand-verified:** the 12 wrong-word tokens (Morpheus bare-lemma lines, raw
cruncher output captured from the page); the fix (unit tests on those lines,
e2e on `effuget Adae`); the stale-render and alignment harness bugs (see LESSONS
2026-10-11). **Not verified:** whether each remaining shared miss is a corpus
error vs a quantity error (classified only for the 1140-word set, M-024/M-027).

**Caveats.** Per-token and distinct-word figures have different denominators —
never quote them together. The page expands æ/œ to ae/oe (M-032); strict scoring
treats them as the same word.

**Every miss, live after the fix** (3152 tokens; corpus-wide counts from all 871 files):

Ours — 16 tokens:
- Books contradict their own majority (our form = the majority) — 6: `Filii`
  (vs `Fílii` 116×), `Omnipotens` (vs 101×), `igitur` (vs 14×), `pariter` (vs 22×),
  `perséveret` (vs `persevéret` 2×), `indignátionem` (vs `indignatiónem` 6×).
- Convention — 3: `Angelo`, `Alitur`, `Angelis`. The corpus never writes an acute
  on a capitalized initial (Solesmes Option 2; 2 cases in 871 files); we do, by design.
- Real errors — 7 tokens / 6 words: `effúget→éffuget` (Morpheus gives no vowel
  length), `Parácliti→Paraclíti`, `líberet→libéret`, `agámus→ágamus` ×2,
  `pervénit→pérvenit` (wordlist reading choice), `seípsum→seipsum` (split
  into se+ipsum, Python-identical).

Accenteur 91823fe — 38 tokens: the same 6 book contradictions; 11 unknown
(`Kýrie` ×6, `Concedátque`, `vobismetípsis`, `astántes`, `misercórdiam` — a corpus
typo for misericórdiam, `seípsum`); 21 wrong placements (`totíus→tótius` ×5,
`ubíque→úbique` ×3, `véteris→vetéris` ×2, `mæstis→máestis` ×2 (two syllables, no
accent), `María`/`Maríæ→Mária`/`Máriæ`, `eádem→éadem`, `cónditus→condítus`,
`látere→latére`, `líberet→libéret`, `Parácliti→Paraclíti`, `effúget→éffuget`,
`pervénit→pérvenit`). It follows Option 2, so the 3 capital cases are right for it.

Accenteur master (live demo) — 56: gets `Kýrie`, `astántes`, `mæstis`, `pervénit`
right, but loses `perveníre` ×4, `transíre` ×2, `servíre`, `Eiúsque`,
`cælestiúmque` (unknown) and moves the accent onto the penult of `-ere`
infinitives and similar (`redímere→redimére`, `ágere→agére`, `géneri→genéri`, …).

## Full corpus (2026-10-11): 73,961 tokens, 345 files

`corpus-run.mjs` (live page + Accenteur, resumable) → `corpus-analyze.py` →
`corpus-analysis.txt`. Prose with independent accents only: Ordo, Prefaces,
Solesmes psalms (`psalms/special`), antiphons, responsories, Regula (one copy),
Rogationes. Excluded: hymns (metrical), `psalms/vatican` (accents generated
with Collatinus = Accenteur's own data, circular), Breviarium O.P. (all hymns),
duplicate Regula/Gloria. 0 lines unaligned.

| | correct | capital* | books-inconsistent | unknown | real | unknown+real |
|---|---|---|---|---|---|---|
| ours, page | 99.10% | 265 | 38 | 15 | 344 | 0.49% |
| ours, engine output | 99.12% | 265 | 38 | 0 | 348 | 0.47% |
| Accenteur 91823fe | 99.17% | 0 | 35 | 142 | 439 | 0.79% |
| Accenteur master (live) | 98.50% | 0 | 33 | 268 | 805 | 1.45% |

\* capitalized word the corpus leaves bare, accented on its first letter — the
corpus applies Solesmes Option 2 without exception; we deliberately don't.
With Option 2 ours would score 99.46-99.48% (Accenteur unchanged, it follows it).

Per section ours leads in Ordo, Prefaces, antiphons; Accenteur leads in the
Solesmes psalms (99.50 vs 99.15), Regula, responsories — the psalm lead is the
capital convention (124 tokens): on substance, psalms ours-wrong/Acc-right 75,
Acc-wrong/ours-right 94.

Our largest fixable error groups (tokens): capital convention 265 (a decision);
`Ierúsalem→Ierusálem` 56 (exception); compounds the tokenizer splits and so
leaves unaccented — `Verúmtamen`, `semetípsum`, `idípsum`, `seípsum`,
`unusquísque`, `semetípsis` ~36 (engine: stress the rejoined word); `Maríam`
15 (extend the María exception); `Iesse→Iésse` 7 (2 syllables); `Basan→Basa`,
`Hermon→Hermo` 9 (page display drops letters the engine keeps — M-032 family);
`-ere` imperatives read as other forms (`Convértere→Convertére`, …), proper
names (`Míchael`, `Ráphael`, `Andréas`), `érue` (missing from the wordlist).
Scorer note: an œ+acute bug in an earlier analyzer version cost us 18 tokens;
fixed (combining marks attach to the preceding letter).

**Live after deploy** (`records-live-fix.json`, 2026-10-11, merges `831cf70`/`81595ad`):
identical to the local run — strict 3136/3152 = 99.49%, 0 wrong-word tokens,
16 misses, 11 of them shared with Accenteur 91823fe.
