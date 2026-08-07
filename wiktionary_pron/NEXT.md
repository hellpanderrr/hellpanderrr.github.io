# Next

_Updated 2026-08-07 — branch `main`_

## State
Test-coverage work committed + pushed (`5520f93`, `19644d4`): editing.spec.js +
popup-check.spec.js serial with shared pages (8→1 wordlist parse/file), added
Escape/scrim/Back/multi-line-undo/dark-chip/CSV-content + unknown-word and
copy-after-edit tests; V8 collector extended to drive touch paths via CDP in
the same context. Measured 66.4% stmts (macronizer.html 78.2%). Clean.

## Open threads
- **M-005 dictionary gloss — extraction REFINED + BUILT + re-audited.**
  `_probe_refined.cjs` is the source of truth (not `_probe_final.cjs`).
  **Build DONE — `utils/build_glosses.cjs`** (Node, not Python — WORDS is
  npm-only): ports the refined pipeline → `macronizer/glosses.tsv.gz`
  (lemma\tgloss, **484 KB gz**). Final coverage: **85.9%** (L&S 81.9 + WORDS
  4.1), 31,966 unique lemmas. Post-build extra fixes (synced to probe+build):
  bare-adj function-word guard (`certus`→"Determined", not "With inf"),
  unclosed-paren strip (`fleo`→"to weep", was losing to "to neigh"), Greek-
  context etymology rejection, `-ed`/`-ing` adj morphology.
  **Two independent labeled-holdout audits: 99.1% / 0.9% wrong** (prior
  pipeline) and **fresh 120-row re-audit at 0% wrong** (final pipeline, seed
  424242). Residue 4.41% (L&S) / 1.07% (WORDS) — cosmetic tails only.
  Remaining: the site-side render (`r-def` column on reading rows, `—`/link
  fallback, "machine-extracted" affordance) — the M-005 build's client half.
  Reference numbers + rule: ISSUES.md M-005.
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
- **Extraction pipeline is settled at `_probe_refined.cjs`.** Do NOT regress to
  the first-clause approach (`_probe_final.cjs`, "88%" — shipped ~15% fragment
  glosses) or the first scoring pass (77.0% — over-rejected adjectives). The
  refined scoring + 6 fixes (see ISSUES.md M-005) is the source of truth.
  Dead ends ruled out (from the two advisor audits): loosening the accept
  threshold re-contaminates (recovery rules tested at +0.8% coverage / ~30%
  noise); the ≥2-English-words branch is near-dead-weight; sense-ordering for
  polysemous verbs is a UI nicety, not a correctness fix.
- **Don't deep-walk L&S `senses[1+]`** — returns subsection fragments for only
  2.4% of a small bucket; not worth it.
- **Don't commit `utils/ext_tmp/`** — 30MB of L&S JSON + WORDS data, a build
  input not shipped. Add `ext_tmp/` to `.gitignore` rather than commit it.
- **Don't multiply e2e tests** — each fresh context re-parses the wordlist.
- **Do NOT build a "decisions replay" state machine** (M-004/M-007) — snapshot +
  accepted-names.
- **CI exclusion is title-based + stale** — don't trust it to exclude wordlist
  suites.
