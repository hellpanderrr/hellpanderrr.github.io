# Next

_Updated 2026-10-06 — branch `main` (PR #9 merged as `b222016`)_

## State
Help pages are done and live: all 17 language pages share one layout, every example is
engine-verified, links checked; app fixes shipped (pt `unpack`, ru/uk double stress,
ru ы, Armenian ՛, Czech BOM). Macronizer M-023m triage (`hoc`, `vorago` overrides,
meter-bin audit) is now committed in both repos (local only, not pushed).

## Open threads
- Push the macronizer commits when ready: engine repo `/f/projects/latin-macronizer-wasm`
  first, then this repo (`git push`). Site dist already matches engine HEAD.
- ISSUES.md H-002 (module-internal bugs, documented only) and H-003 (Icelandic `special`
  arg, Brazilian epenthesis) and M-023m `meneni` need owner decisions.
- Catullus blocker counts from `gold/catullus/iambic/` are unreliable until that bin is
  re-binned (7 of 13 files are hendecasyllables; probe `test/catullus-meter-ab.mjs`).
- Pullfrog has no working model: fund Cline credits or set `GEMINI_API_KEY` /
  `OPENROUTER_API_KEY` (e.g. `nvidia/nemotron-3-ultra-550b-a55b:free`), then
  comment `@pullfrog review this PR`.

## Running / unfinished
A `python -m http.server 8000` (repo root) may still be running from this session.

## Don't redo
- Help-page IPA only from `scripts/tests/ipa_cli.mjs`; verify with `verify_help_page.mjs`,
  `verify_issue_tables.mjs`, `check_help_links.mjs` (false positives in LESSONS 2026-10-05/06).
- No "Overview" sections (user removed them); prose in reference-grammar register.
- Don't build a header-spoofing proxy for Cline's free models (declined; ToS + ban risk).
- e2e here: `npx playwright test -c playwright.chrome.config.js` (bundled browser missing).
- Macronizer: compare to gold by SCAN; L&S headword arbitrates quantity (not Wiktionary
  macrons, not morphology rules); sync site via
  `MACRONIZER_SITE_DIR=F:/projects/wiktionary_pron/wiktionary_pron/macronizer node sync-site.cjs`.
