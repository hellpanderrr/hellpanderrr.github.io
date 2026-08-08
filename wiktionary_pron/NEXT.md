# Next

_Updated 2026-08-08 — branch `main`_

## State
M-005 (dictionary glosses in the word popup) is **hardened by a corpus
read-through audit** (2026-08-08, M-018) covering all 8 patterns + the verb-leak
fix. Session commits: `a5acb33` (verb-leak residue 87), `2459d07` (paren-note
strip), `5c515f2` (de-Or bound), `4113fdb` (P2 primaries), `e692d46` (P3 Latin
gate), `2194396` (stragglers), `1349033` (P4 text-critical), `80c9b15` (P6
citations), `a091ddc` (P5 collisions), `aeb5a3a` (P8 WORDS fallback), `74fb466`
(intro-phrase stragglers).
Final: `core_gloss.json` **1836**, golden **1896/1896**, census **348/348**,
artifact **33,679 lemmas @ 471 KB**, L&S 82.2% / WORDS 9.0% / none 8.8%.
`npm test` (22+81+1896+348) and macronizer e2e (3/3) both exit 0.

## Open threads
- **~100 rare participle verb-leaks remain** (M-017 residue; ADJ/ADV lemmas
  still "to X", WORDS POS-null). Lower priority — rare words.
- **P7 etymology/myth-note clauses** ("a nymph who was changed") — mitigated by
  P2 primary recognition, but a residual few remain (menta, monedula, maltha).
- **Push the M-005 commits** when ready for GitHub Pages — nothing since `da94aca`
  is pushed; ~40 commits sit on `main` locally.
- **Engine lemmatization collisions** (wordlist maps `circa`→Circe, `est`→edo,
  `versus`→verro, `demum`→demos, `sane`→sanus): patched via core entries here,
  real fix in the engine repo's wordlist/lemmatizer. `differo`/`diffido`/
  `dissilio` are NOT wordlist lemmas (0 rows) — same class.
- **UI test coverage (M-015):** stale CI exclusion — `--grep-invert macronizer`
  in `.github/workflows/tests.yml` only drops macronizer.spec.js.
- **Engine coverage (M-013)** — Scansion.js / MorpheusAnalyzer / alignMacronized.
- **M-004 Phase 3** — accepted-names list + input-hash snapshot.

## Running / unfinished
Nothing running. The 4-lens cold audit stalled (3/4 empty transcripts); the
corpus read-through subagent (M-018) COMPLETED and wrote
`utils/_corpus_pattern_report.md`. Don't re-launch the cold panel; reuse the
corpus-read recipe (see LESSONS).

## Don't redo
- **L&S `main_notes` cross-refs leak the verb infinitive onto ADJ/ADV lemmas.**
  Guarded by the "to X" build rule + golden rows. Blanket WORDS-first is WRONG.
- **The golden suite is self-referential for core_gloss keys** — trust the
  census + spot audits, not the golden count alone.
- **Measure by corpus frequency / token exposure, not wordform count** —
  `utils/token_estimate.cjs` is the honest measure.
- **Curation is bounded and monotone** (core 262→1836, golden 75→1896); every
  core entry gets a golden row in the SAME commit.
- **Scripts in `utils/` that write data files: use ABSOLUTE paths.**
- **`evalExpect` must norm BOTH `got` and the expectation.**
- **Don't commit** `utils/ext_tmp/`, `gloss_lemma_cache.json.gz`, `utils/_*`
  scratch — gitignored.
- **Do NOT build a "decisions replay" state machine** (M-004/M-007).
- **A `de\s+Or` citation strip needs `\b` + separator** — a bare regex matched
  "de or" inside "aside"/"disquietude" (declino→"to turn asi").
- **capital-first-token accept in isGlossRun**: check the ORIGINAL-case token,
  not the lowercased one (the old check was dead code), and exclude etymology
  language fragments ("Erse, aile", Osc./Goth.).
