# Next

_Updated 2026-08-10 — branch `main`_

## State
M-013 scansion cut 150 → **111** failing corpus lines (26%) across 5 engine
commits (latest `c8fcf56`): -ērunt/-ĕrunt, 22 ACCENT_OVERRIDES, empty-verse
alignment, 4 corpus corrections, **y-synizesis for Greek names** (unlocks
5.322 `tertius Euryalus` + 5.334 `non tamen Euryali...`; gate 113→111, zero
regressions). Verified: gate PASS (111 baseline, **23** golden), jest 38/38,
smoke 6/6, site e2e 3/3. M-005 gloss layer (M-021c) still shipped.

## Open threads
- **Aen 5.337 `emicat Euryalus et munere victor amici` still fails** — NOT the
  y-synizesis gap (now implemented). Gold quantities don't fit the automaton
  (`lŭs et` S-S can't open a foot); no gold-consistent reading scans.
  `docs/ISSUES.md` M-013 — deeper prosody change or a transmission anomaly.
- **Remaining ~111 failures**: elision/synizesis/automaton-strictness gaps +
  unverifiable proper-noun quantities. Triage: gold → whole-file gate → print
  chosen forms. `docs/ISSUES.md` M-013.
- **Gloss:** 193 golden-covered lemmas show L&S literal (veho→"be carried");
  ~70 audited-but-skipped BAD glosses in `tmp/_llm_audit_out.json`.
- **Push M-005+ to GitHub Pages** — nothing since `da94aca`; ~70 commits local.
- **Engine lemmatization collisions** (circa→Circe, est→edo) — core patch only;
  real fix in engine. **M-004 Phase 3** accepted-names list.

## Running / unfinished
Nothing running. Gold ref remote (hypotactic.com `aeneidAll_i_v_es.txt`);
`test/regen-snapshot.mjs` regenerates the failure snapshot after an intended
engine change.

## Don't redo
- **Judge scansion fixes by the whole-file gate ONLY** — per-line runs differ
  (RFTagger POS) and overcount. `test-scansion-corpus.mjs` is the truth.
- **Never corrupt vowel quantities to make a line scan** — ui-diphthong merge
  was a false positive (obstupuī → LSL, 44-line regression). Print chosen
  forms; check against the edition.
- **A "documented cause" fix can leave the headline line broken for another
  reason** — re-run the gold experiment after fixing (5.337 was NOT the
  y-synizesis gap). Brute-force the meter automaton with candidate L/S
  readings to enumerate which actually fit.
- **est-prodelision is already handled** by the `'V'`-elision branch.
- **Empty verses must emit placeholders** or scannedFeet/line alignment shifts.
- **Corpus text errors → fix the corpus, not the engine**; verify against
  Latin Library/wikisource/negenborn first.
- **ACCENT_OVERRIDES append candidates; prose keeps accented[0]**.
- **Gloss don't-redo** (details in CLAUDE.md/LESSONS.md): L&S primary; LLM
  audit is a FILTER; `isSpurious` DUAL signature; `_*` scratch in `tmp/`; no
  "decisions replay" state machine.
