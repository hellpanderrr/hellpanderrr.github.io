# Next

_Updated 2026-08-10 — branch `main`_

## State
M-013 scansion cut 150 → **111** failing corpus lines (26%) across 5 engine
commits (`7fd0113`, `381a97a`, `e3320e4`, `c40f8e8`, `c8fcf56`):
-ērunt/-ĕrunt alternation, 22 gold-confirmed ACCENT_OVERRIDES, the empty-verse
alignment fix, 4 corpus-text corrections, and **y-synizesis for Greek names**
(`c8fcf56` — unlocks Aen 5.322 `tertius Euryalus` + 5.334 `non tamen
Euryali...`; gate 113→111, zero regressions). All verified: gate PASS (111
baseline, **23** golden lines), jest 38/38, 5-meter smoke 6/6, site e2e
(macronizer 3/3 + coverage) PASS. M-005 gloss layer (M-021c) remains shipped
and verified.

## Open threads
- **Aen 5.337 `emicat Euryalus et munere victor amici` still fails** — but NOT
  via y-synizesis (now implemented). Gold quantities genuinely don't fit the
  automaton: `lŭs et` (S S) can't open a foot, et-position fails, `mūnere`
  (LSS)/5th-foot placement has no valid reading; only corrupt non-gold
  quantities scan. See `docs/ISSUES.md` M-013. Likely needs a deeper prosody
  change (elision/synizesis beyond y) or is a transmission anomaly.
- **Remaining ~111 failures** are mostly elision/synizesis/automaton-strictness
  prosody gaps + unverifiable proper-noun quantities. Triage method: gold
  quantities → whole-file gate → print chosen forms. See `docs/ISSUES.md` M-013.
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
