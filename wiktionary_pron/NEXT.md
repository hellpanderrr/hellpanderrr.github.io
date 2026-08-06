# Next

_Updated 2026-08-06 — branch `main`_

## State
Editing/mobile overhaul shipped + pushed (`54d425e`, `e5fa491`): real editable
output, click-vowel toggle, touch tap-flagged→readings-sheet, narrow-width fix.
Then committed + pushed the coverage tooling and the two mobile fixes
(preload, blur-before-dock, Android Back). Working tree clean; both repos on
`main` = `origin/main`.

## Open threads
- **UI test coverage gaps (M-015).** Plan from a 3-agent council: EXTEND the
  existing e2e tests (each new test re-parses the 812k wordlist, ~30-60s):
  Escape+focus-return, scrim/Back/blur in the touch test, multi-line undo,
  dark-mode `.no-scan` chip color, CSV *content* (a cycled spelling). Add 2
  new: unknown-word red flow, copy-after-edit. Then share one context per spec
  file (biggest CI-time/determinism win) and fix the stale CI exclusion
  (`--grep-invert macronizer` in `.github/workflows/tests.yml:57` only drops
  macronizer.spec.js; editing/popup-check still run in CI).
- **Engine coverage is the real gap** — Scansion.js 12%, MorpheusAnalyzer 42%,
  alignMacronized 29%. That's engine correctness (M-013 prosody), fix with unit
  tests in the **engine repo**, not UI e2e.
- **M-004 Phase 3** — accepted-names list + input-hash snapshot (the pieces
  that make edits survive a revisit). Deferred by the council; snapshot must
  serialize the active-reading index per token (technical agent's finding).

## Running / unfinished
Nothing running. Coverage tooling: `npm run test:coverage` (c8 + opt-in
`COVERAGE=1` collector + `coverage-merge.mjs`); measured 61.9% stmts.
`coverage/` is gitignored.

## Don't redo
- **Don't multiply e2e tests** — each fresh context re-parses the wordlist.
  Extend existing tests or share one context per file.
- **Scansion/Morpheus coverage = engine unit tests**, not UI e2e (a chip
  rendering ≠ feet correct). One UI test per path is enough.
- **Do NOT build a "decisions replay" state machine** (M-004/M-007) — use
  snapshot + surface-keyed accepted-names.
- **Dark-mode `.no-scan` chip** (M-014) fixed via `body.dark_mode
  .verse-foot.no-scan` (0,3,1) — was untracked; asserted by no test yet.
- **CI exclusion is title-based + stale** — don't trust it to exclude wordlist
  suites; make it structural when touching the workflow.
