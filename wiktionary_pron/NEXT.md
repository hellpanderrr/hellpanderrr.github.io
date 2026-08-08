# Next

_Updated 2026-08-08 — branch `main`_

## State
M-005 (dictionary glosses in the word popup) is **DONE, restructured, committed,
verified**. The Aeneid stress test exposed 11 wrong common-word glosses the shipped
"99.1% usable" holdout missed; a gate-then-rank restructure fixed them all
(committed `93d1cef`):
- **89.8% coverage** (was 85.6%), 32,799 lemmas, 467 KB gz.
- **Golden suite** `utils/gloss_golden.json` (75 rows) + `utils/test_gloss_regression.cjs`
  (~2s, `npm run test:gloss`, wired into `npm test`).
- **Build memoized** (resolve/wGloss per lemma): 841s → 50s, byte-identical.
- `npm test` green (unit 81 + IPA + gloss 75). Tree clean except pre-existing junk.
NOT pushed.

## Open threads
- **M-005 residue (accepted, fail-safe):** ~198 rare-name/edge glosses now null →
  "—" dash. Deliberate trade (null is fail-safe, wrong is fail-loud). `appello`→"To
  drive" remains inherent wordlist conflation.
- **UI test coverage (M-015):** stale CI exclusion unfixed —
  `--grep-invert macronizer` in `.github/workflows/tests.yml:57` only drops
  macronizer.spec.js; editing/popup-check (wordlist-heavy) still run in CI.
- **Engine coverage** — Scansion.js / MorpheusAnalyzer / alignMacronized are
  engine correctness (M-013), fix with unit tests in the **engine repo**.
- **M-004 Phase 3** — accepted-names list + input-hash snapshot (edit
  persistence). Snapshot must serialize the active-reading index.
- **Push the M-005 commits** when ready for GitHub Pages — they're not pushed.

## Running / unfinished
Nothing running. Note: `package.json` has `whitakers-words` as a devDependency
(used by the gloss build — commit-worthy, currently uncommitted).

## Don't redo
- **The gloss extractor is gate-then-rank at `build_glosses.cjs`.** Do NOT regress
  to content-blind scoring (first-clause or score-everything): it shipped wrong
  common-word glosses the holdout couldn't see. The golden suite
  (`utils/gloss_golden.json`, 75 rows) is the correctness gate — grow it per-fix
  (monotone rule: any fix adds its target lemma in the SAME commit).
- **Measure correctness, not fragment-ness.** A labeled holdout on well-formedness
  can't catch `terra`→"the sea". Sample by frequency (top-1000 words matter most);
  test multiple registers (Caesar prose AND Aeneid epic).
- **`resolve()` is pure per lemma** — the build loop must memoize by exact lemma
  string (case-sensitive for the collision guard). 673k rows / 40k lemmas = 17×
  redundant otherwise.
- **The `r-def` lookup must be exact-key-first** (`populus2`→poplar). `fetchAsset`
  appends `.gz` — pass `macronizer/glosses.tsv`. See `docs/LESSONS.md`.
- **Don't commit `utils/ext_tmp/`** (30MB L&S data), `gloss_lemma_cache.json.gz`
  (derived), or `_probe*`/`_audit_*` scratch — gitignored.
- **Don't multiply e2e tests** — each fresh context re-parses the wordlist;
  extend the shared-page popup-check.spec.js.
- **CI exclusion is title-based + stale** — don't trust it to exclude wordlist suites.
- **Do NOT build a "decisions replay" state machine** (M-004/M-007) — snapshot +
  accepted-names.
