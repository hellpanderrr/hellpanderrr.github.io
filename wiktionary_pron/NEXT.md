# Next

_Updated 2026-10-09 — branch `feat/macronizer-stress-accents` (PR #10 open), engine branch `feat/stress-accents` (PR #1 open)_

## State
Stress accents (the liturgical acute) are implemented, verified, and in review:
engine `Stress.ts` + 98.86% gold corpus, site option + Gentium Plus font (the
font fix for stacked macron+acute), help page, e2e. Plus three position fixes
from the A&G §§ 11–12 conformance pass:
- engine `67feead` / site dist `8c18320`: the qu glide is no longer a closing
  consonant (`dénique`, `réliquus`, `áliquid`, `ítaque`, `ántequam`), a
  consonantal i closes like x (`alicúius`, `eiúsdem`);
- engine `fe3e23f` / site dist `876b327`: a MARKED u after g/q is the word's
  own vowel, not a glide (`árguas`, `argúam`, `argúere` — found via the /adv
  muse review, M-029);
- site `b5ccdf7`: popup reading labels now show the acute the click writes
  (M-028), in Gentium.
Verified over the full Gregorio corpus (500 files scanned of 871, 13,960
distinct word-readings, hymns excluded): 97.74% → **97.94%** distinct-pair,
**99.24%** token-weighted; 31 fixed, 0 true regressions; all remaining
disagreements classified (M-027 in ISSUES.md). Both PRs are open and
mergeable; green as of the last completed checks (node-tests + e2e + pullfrog
+ CodeRabbit on the site — every push re-triggers them; engine has no CI,
local: 59 jest, gold 98.86%, byte-parity exact).

## Open threads
- **Merge the PRs**: engine [latin-macronizer-wasm#1] first, then site
  [hellpanderrr.github.io#10] (the site `macronizer/dist/` is synced from the
  engine branch). Both MERGEABLE.
- ISSUES.md H-002, H-003 and M-023m `meneni` still need owner decisions.
- Catullus blocker counts from `gold/catullus/iambic/` unreliable until re-binned
  (`test/catullus-meter-ab.mjs`).
- Review the 13 pinned accent-corpus disagreements in
  `test/data/accent-failures-snapshot.json` — 6 are wordlist reading-choice
  homographs (`pervénit`/`pervĕnit`) that affect the macrons equally today; if
  prose reading selection is ever fixed, re-run `npm run test:accent --update`.

## Running / unfinished
- `python -m http.server 8000 --directory F:/projects/wiktionary_pron` is running
  (serves http://localhost:8000/wiktionary_pron/macronizer.html). Kill it with
  the netstat/taskkill pair in LESSONS if it lingers.
- Pullfrog is working again on the site repo (it failed on Cline's free models
  before); engine repo has no workflows.

## Don't redo
- **Font for stacked marks**: Gentium Plus for the macronizer's Latin text and
  PDF (EB Garamond lacks the mark-to-mark GPOS lookup — marks cross; verified in
  the font tables). Don't "fix" the old Garamond/X look by regenerating text —
  the text is correct Unicode.
- **qu/gu position counting**: u after q does NOT close a syllable (A&G § 11
  Note 3; corpus `dénique`/`áliquid`/`ítaque`); gu still counts when the glide
  collapses (`ambíguus`). Consonantal i counts double like x (`alicúius`).
  A MARKED u after g/q is vocalic (`argu^a_s` → `árguas`), unmarked is the
  glide — do not "simplify" syllabify's marks argument away. Pinned in
  `test/unit/stress.test.ts`; don't touch the interlude loop without re-running
  the A&G battery. `cuique`/`tibine` are lexical exceptions with corpus
  citations — not bugs.
- **The 97.94% full-corpus number is distinct-pair; token-weighted it is
  99.24%.** The scan is a one-off diagnostic (needs the downloaded upstream
  corpus), not a committed test — quote both numbers or neither.
- **`/adv` aliases**: `DS`/`bunny` are dead (rotator substitutes; guard
  refuses); `solar` replaces them (table updated 2026-10-09 in adv.py +
  SKILL.md). `mimo`/`muse` time out on >500K-char transcripts.
- Help-page IPA only from `ipa_cli.mjs`; verify with `verify_help_page.mjs`,
  `verify_issue_tables.mjs`, `check_help_links.mjs`.
- No "Overview" sections; prose in reference-grammar register.
- e2e here: `npx playwright test -c playwright.chrome.config.js` (bundled browser
  missing); macronizer e2e needs the local server up.
- Don't `git add -A` at the repo root (2,416 untracked scratch files).
- Macronizer gold comparison is SCAN-based; L&S headword arbitrates quantity.
  Sync site via `MACRONIZER_SITE_DIR=F:/projects/wiktionary_pron/wiktionary_pron/macronizer node sync-site.cjs`.
