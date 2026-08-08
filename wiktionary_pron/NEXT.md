# Next

_Updated 2026-08-08 — branch `main`_

## State
M-005 (dictionary glosses in the word popup) is **DONE, fixed, verified — including
the function-word stratum**. The gate-then-rank restructure (`93d1cef`) fixed
content words; a 2026-08-08 panel audit then found the closed class (conjunctions,
prepositions, pronouns, copula, adverbs) ~40% wrong (`et`→"used for et ... et",
`sum`→"to pass, elapse"). Fixed, NOT yet committed:
- **`utils/core_gloss.json` (262 hand-curated entries)** — everyday glosses for the
  closed function-word class + homograph-inverted content words + content verbs
  with etymological L&S primaries. Applied pre-resolve; wins over everything.
- **WORDS-first for the closed particle class** (any r/c/e attestation, 157 lemmas)
  — Whitaker's WORDS first-result (frequency-ordered) beats L&S's usage-notes.
- **`utils/gloss_census.cjs` (241 rows)** — frequency-stratified census, wired into
  `npm test` + CI. Closed class went **38% → 100% correct (241/241)**.
- **Golden suite 75 → 333 rows** (every core key gets a golden row — enforced).
  333/333 pass. `npm test` green (unit 81 + IPA 22 + gloss 333 + census 241).
- Artifact `macronizer/glosses.tsv.gz` rebuilt (467 KB, unchanged), 89.9% coverage.
- Full detail: `docs/ISSUES.md` M-005, `docs/LESSONS.md`.

## Open threads
- **M-005 residue (accepted, fail-safe):** ~198 rare-name/edge glosses null → "—".
  `appello`→"To drive" inherent. `vos` is a wordlist gap (never a lemma).
- **UI test coverage (M-015):** stale CI exclusion —
  `--grep-invert macronizer` in `.github/workflows/tests.yml` only drops
  macronizer.spec.js; editing/popup-check (wordlist-heavy) still run in CI.
- **Engine coverage** — Scansion.js / MorpheusAnalyzer / alignMacronized (M-013),
  fix with unit tests in the **engine repo**.
- **M-004 Phase 3** — accepted-names list + input-hash snapshot (edit
  persistence). Snapshot must serialize the active-reading index.
- **Push the M-005 commits** (incl. this fix) when ready for GitHub Pages — not pushed.

## Running / unfinished
Nothing running. `whitakers-words` devDependency is committed (used by the build).

## Don't redo
- **The gloss extractor is gate-then-rank.** Do NOT regress to content-blind
  scoring. The golden suite + census are the correctness gates — grow them per-fix
  (monotone rule: every core entry gets a golden row in the same commit).
- **Measure by corpus frequency, not wordform count.** The old "top-1000 most-
  attested" proxy (wordform richness) structurally excludes function words — that's
  how `autem`→"the parent of all evil" shipped as "99.1% usable." `utils/gloss_census.cjs`
  is the frequency gate now.
- **Don't touch the scoring function to fix a stratum a curated table handles.**
  The `class.` era cap + enCount suffix expansion looked safe but regressed
  `curro`/`impedio` golden rows (reverted). The closed class is a CORE_GLOSS
  problem, not a scoring problem.
- **L&S numbers the RARE homograph as -1** (`caelum1`=chisel, `lego1`=bequeath,
  `dico1`=dedicate, `frons1`=leaf) — the base1 fallback is the `appello` trap
  generalized. Homograph-inverted common words go in core_gloss.
- **`resolve()` is pure per lemma** — the build memoizes by exact lemma string.
- **The `r-def` lookup must be exact-key-first.** `fetchAsset` appends `.gz`.
- **Don't commit `utils/ext_tmp/`**, `gloss_lemma_cache.json.gz`, or `utils/_*.json`/
  `utils/_*.cjs` scratch — gitignored.
- **CI exclusion is title-based + stale** — don't trust it to exclude wordlist suites.
- **Do NOT build a "decisions replay" state machine** (M-004/M-007) — snapshot +
  accepted-names.
