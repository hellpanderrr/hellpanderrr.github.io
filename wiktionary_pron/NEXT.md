# Next

_Updated 2026-10-08 — branch `feat/macronizer-stress-accents` (PR #10 open), engine branch `feat/stress-accents` (PR #1 open)_

## State
Stress accents (the liturgical acute) are implemented, verified, and in review:
engine `Stress.ts` + 98.86% gold corpus, site option + Gentium Plus font (the
font fix for stacked macron+acute), help page, e2e. Both PRs are open,
mergeable, and fully green — CI equals node-tests + e2e + pullfrog + CodeRabbit
on the site; engine has no CI (local: 54 jest, byte-parity exact).

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
- Help-page IPA only from `ipa_cli.mjs`; verify with `verify_help_page.mjs`,
  `verify_issue_tables.mjs`, `check_help_links.mjs`.
- No "Overview" sections; prose in reference-grammar register.
- e2e here: `npx playwright test -c playwright.chrome.config.js` (bundled browser
  missing); macronizer e2e needs the local server up.
- Don't `git add -A` at the repo root (2,416 untracked scratch files).
- Macronizer gold comparison is SCAN-based; L&S headword arbitrates quantity.
  Sync site via `MACRONIZER_SITE_DIR=F:/projects/wiktionary_pron/wiktionary_pron/macronizer node sync-site.cjs`.
