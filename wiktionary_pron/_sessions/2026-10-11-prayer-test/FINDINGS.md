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
| ours, page | 99.10% | 265 | 33 | 15 | 349 | 0.49% |
| ours, engine output | 99.12% | 265 | 33 | 0 | 353 | 0.48% |
| Accenteur 91823fe | 99.17% | 0 | 33 | 142 | 441 | 0.79% |
| Accenteur master (live) | 98.50% | 0 | 31 | 268 | 807 | 1.45% |

"books-inconsistent" is per tool: the corpus has 41 places where the book
writes a minority form of the same word (compared within the same initial
case); a tool is counted there only if it wrote the majority form. At those 41:
ours 33 majority / 2 matched the book (`décore`, `ínvenit`) / 6 other
(`Mariam→Máriam`); Accenteur 91823fe 33 / 1 / 7. Two earlier classifier
versions were wrong: lowercasing all votes let the capital convention ('Omnia'
bare) outvote 'ómnia'; lowercase-only voting let 'mária' (seas) outvote the
name 'María'.

\* capitalized word the corpus leaves bare, accented on its first letter — the
corpus applies Solesmes Option 2 with 2 exceptions in 871 files; we deliberately don't.
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

## Independent review of the full-corpus numbers (2026-10-11)

A cold reviewer (separate agent, own code, `F:/temp/lea/review/`) recomputed
everything from the raw records: all four accuracy figures, the class counts,
agreement 98.63%, Accenteur any-candidate 99.72%, per-section numbers and the
Option-2 counterfactual reproduce exactly (one token differs in class:
`áëris`, a gold diaeresis). Gold token sequence matches the corpus text for
all 73,961 tokens; no alignment shift. Exclusions verified. Corrections to how
the numbers were described above:

- **Raw is a statistical tie, not a lead either way.** Engine - Accenteur
  91823fe = -0.05 pp; 95% bootstrap CI by file [-0.18, +0.13], by word type
  [-0.44, +0.40].
- **About 9% of tokens are repeated lines** (antiphon books overlap, Exsultet
  brevior/longior). De-duplicated: Accenteur 91823fe 99.26% vs ours 99.10%
  (99.43% with Option 2) — a small Accenteur lead raw.
- **"0.48% vs 0.79% real+unknown errors" is Option-2-adjusted for ours only.**
  Counting the capital-initial tokens as errors: ours 0.84% vs Accenteur 0.79%.
- **The Option-2 lead (+0.32 pp) is likely real in direction but not
  established**: CI by file [+0.18, +0.54], by word type [-0.03, +0.75]. It is
  concentrated in a few frequent words (Accenteur: `ubíque` 88, `María` 80,
  `Maríæ` 37 of its 583 misses; ours: `Ierúsalem` 56).
- **"Option 2 without exception" was wrong**: 2 counterexamples in 871 files,
  one scored (`Ángelum`, antiphons/Adventus.txt) — Option 2 is worth +264, not +265.
- **Where ours is clearly ahead**: on the 1,771 tokens where Accenteur has 2+
  candidates, its first choice is right 76.5%, ours 94%. Ours also guesses
  unknown words (619 flagged, 76% right) where Accenteur abstains (142).
  On tokens Accenteur knows: ours engine 99.17% raw (99.53% Option 2),
  Accenteur 99.36%.
- **Development overlap**: the Ordo files are the engine's gold test
  (`test:accent`), and ours leads exactly in Ordo and Prefaces — in-sample.
- Required wording: "accent-position accuracy on a Solesmes/Vatican prose
  subset, with ae/oe respelling ignored".

**Live after deploy** (`records-live-fix.json`, 2026-10-11, merges `831cf70`/`81595ad`):
identical to the local run — strict 3136/3152 = 99.49%, 0 wrong-word tokens,
16 misses, 11 of them shared with Accenteur 91823fe.
