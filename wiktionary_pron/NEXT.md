# Next

_Updated 2026-08-07 — branch `main`_

## State
Test-coverage work committed + pushed (`5520f93`, `19644d4`): editing.spec.js +
popup-check.spec.js serial with shared pages (8→1 wordlist parse/file), added
Escape/scrim/Back/multi-line-undo/dark-chip/CSV-content + unknown-word and
copy-after-edit tests; V8 collector extended to drive touch paths via CDP in
the same context. Measured 66.4% stmts (macronizer.html 78.2%). Clean.

## Open threads
- **M-005 dictionary gloss — research DONE, not built.** `whitakers-words`
  (WORDS) + L&S JSON (`utils/ext_tmp/ls_*.json`, 30MB) evaluated + audited by
  2 subagents. Rule + numbers in `_probe_final.cjs` and ISSUES.md M-005.
  **Build `utils/build_glosses.py`**: L&S-exact-key → L&S-fallback → WORDS,
  emit `macronizer/glosses.tsv.gz` (~570 KB), quiet `r-def` column on reading
  rows, `—`/link fallback for ambiguous.
- **UI test coverage (M-015)**: stale CI exclusion unfixed —
  `--grep-invert macronizer` in `.github/workflows/tests.yml:57` only drops
  macronizer.spec.js; editing/popup-check (wordlist-heavy) still run in CI.
- **Engine coverage** — Scansion.js / MorpheusAnalyzer / alignMacronized are
  engine correctness (M-013), fix with unit tests in the **engine repo**.
- **M-004 Phase 3** — accepted-names list + input-hash snapshot (edit
  persistence). Snapshot must serialize the active-reading index.

## Running / unfinished
Nothing running. Coverage tooling: `npm run test:coverage`. Note: `package.json`
now has `whitakers-words` as a devDependency (from the M-005 research) — commit
only if the gloss build uses it.

## Don't redo
- **Gloss source research is settled.** Prefer L&S-exact-key (WORDS mis-keys
  numbered homographs: paro2/acceptor2/virosus2), Perseus tag gender is index 6,
  `senses[0]` is the clean definition. See CLAUDE.md "Dictionary-gloss traps".
  Dead end ruled out: WORDS-first priority ships ~2-3% wrong glosses.
- **Don't deep-walk L&S `senses[1+]`** — returns subsection fragments for only
  2.4% of a small bucket; not worth it.
- **Don't commit `utils/ext_tmp/`** — 30MB of L&S JSON + WORDS data, a build
  input not shipped. Add `ext_tmp/` to `.gitignore` rather than commit it.
- **Don't multiply e2e tests** — each fresh context re-parses the wordlist.
- **Do NOT build a "decisions replay" state machine** (M-004/M-007) — snapshot +
  accepted-names.
- **CI exclusion is title-based + stale** — don't trust it to exclude wordlist
  suites.
