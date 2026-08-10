# Next

_Updated 2026-08-10 — branch `main`_

## State
M-013 scansion cut 150 → 113 failing corpus lines (25%) across 4 engine
commits (`7fd0113`, `381a97a`, `e3320e4`, `c40f8e8`): -ērunt/-ĕrunt
alternation, 22 gold-confirmed ACCENT_OVERRIDES, the empty-verse alignment
fix, and 4 corpus-text corrections. All verified: gate PASS (113 baseline, 21
golden lines), jest 38/38, 5-meter smoke 6/6, site e2e (macronizer 3/3 +
coverage) PASS. M-005 gloss layer (M-021c) remains shipped and verified.

## Open threads
- **y-synizesis engine gap** (Aen 5.337 `emicat Euryalus...`): `possibleScans`
  handles synizesis only for `ui` and `s/ng+u+vowel`, not `y+vowel` (Greek
  names mid-foot). Start: `latin-macronizer-wasm/src/core/Scansion.ts` +
  `test/e2e/test-scansion-corpus.mjs`.
- **Remaining ~113 failures** are mostly elision/synizesis/automaton-strictness
  prosody gaps + unverifiable proper-noun quantities. Triage method: gold
  quantities → whole-file gate → print chosen forms. See `docs/ISSUES.md` M-013.
- **193 golden-covered lemmas still show L&S literal** (veho→"be carried").
  Semantic synonym-buckets authored from the headword, not the LLM output.
  Start: `utils/gloss_golden.json` + M-021 list.
- **~70 audited-but-skipped BAD glosses** — review `tmp/_llm_audit_out.json`.
- **Push M-005+ to GitHub Pages** — nothing since `da94aca`; ~70 commits local.
- **Engine lemmatization collisions** (circa→Circe, est→edo) — patched via
  core; real fix in engine. **M-004 Phase 3** accepted-names list.

## Running / unfinished
Nothing running. Engine scratch: gold reference is remote (hypotactic.com
`aeneidAll_i_v_es.txt`); `test/regen-snapshot.mjs` regenerates the failure
snapshot after an intended engine change.

## Don't redo
- **Judge scansion fixes by the whole-file gate ONLY** — per-line runs differ
  (RFTagger POS) and overcount. `test-scansion-corpus.mjs` is the truth.
- **Never corrupt vowel quantities to make a line scan** — the ui-diphthong
  merge was a false positive (obstupuī → 3-syllable LSL, 44-line regression).
  Print chosen forms and check against the edition.
- **est-prodelision is already handled** by the `'V'`-elision branch — rejected.
- **Empty verses must emit placeholders** or scannedFeet/line alignment shifts.
- **Corpus text errors → fix the corpus, not the engine** (solaciolum, ligatam,
  a misera); verify against Latin Library/wikisource/negenborn first.
- **ACCENT_OVERRIDES append candidates; prose keeps accented[0]** — overrides
  change scansion readings without touching prose macrons.
- **Gloss don't-redo** (unchanged): L&S beats all sources for everyday primary;
  LLM audit is a FILTER not a verdict; golden-covered lemmas keep L&S;
  `isSpurious` uses DUAL signature; all `_*` scratch lives in `tmp/`; no
  "decisions replay" state machine.
