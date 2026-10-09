# Next

_Updated 2026-10-09 — branch `feat/macronizer-stress-accents` (PR #10 open), engine branch `feat/stress-accents` (PR #1 open)_

## State
Stress accents (the liturgical acute) are implemented, verified, and in review:
engine `Stress.ts` + 98.86% gold corpus, site option + Gentium Plus font (the
font fix for stacked macron+acute), help page, e2e. Plus the A&G §§ 11–12
position-counting fix (`67feead` engine / `8c18320` site dist): the qu glide is
no longer a closing consonant (`dénique`, `réliquus`, `áliquid`, `ítaque`,
`ántequam`), a consonantal i closes like x (`alicúius`, `eiúsdem`). Verified
over the full Gregorio corpus (871 files, 13,960 words, hymns excluded):
97.74% → 97.93%, 27 fixed, 0 regressions. Both PRs are open and mergeable;
green as of the last completed checks (node-tests + e2e + pullfrog + CodeRabbit
on the site — every push re-triggers them; engine has no CI, local: 58 jest,
gold 98.86%, byte-parity exact).

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
  Pinned in `test/unit/stress.test.ts`; don't "simplify" the interlude loop
  without re-running the A&G battery. `cuique`/`tibine` are lexical exceptions
  with corpus citations — not bugs.
- Help-page IPA only from `ipa_cli.mjs`; verify with `verify_help_page.mjs`,
  `verify_issue_tables.mjs`, `check_help_links.mjs`.
- No "Overview" sections; prose in reference-grammar register.
- e2e here: `npx playwright test -c playwright.chrome.config.js` (bundled browser
  missing); macronizer e2e needs the local server up.
- Don't `git add -A` at the repo root (2,416 untracked scratch files).
- Macronizer gold comparison is SCAN-based; L&S headword arbitrates quantity.
  Sync site via `MACRONIZER_SITE_DIR=F:/projects/wiktionary_pron/wiktionary_pron/macronizer node sync-site.cjs`.
