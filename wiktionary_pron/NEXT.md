# Next

_Updated 2026-08-13 — branch `main`_

## State
Both repos clean, all pushed (0 unpushed). Site `npm test` green: 22 unit + 81
IPA + 2075 gloss + 348 census + 9 popup e2e.
- **Gloss (M-023i→l, site `c845beb`..`bd12ae2`)**: CI gloss golden suite now
  resolves via committed `utils/ls_golden_fixture.json` (was red in CI since
  2026-08-08); CI trigger widened to `utils/**`. Caesar full-text stragglers
  (jamque, pleraque) + the Germanis single-accented reading fix + the Caesar
  LLM-audit defect fixes (impetus, pagus, barba, leuci, itis, Gai-citations).
  Artifact 34,413 lemmas / 450 KB / L&S 89.8%.
- **Scansion (M-023m, engine `0af77d6`)**: full-Catullus scansion gold
  (negenborn, 118 poems, full long+short marks) at
  `latin-macronizer-wasm/test/data/gold/catullus/`. Scan-based blocker tool
  (`test/catullus-blocker.mjs`) found 24 wordlist-quantity candidates; **8
  gold-confirmed fixed** via ACCENT_OVERRIDES (erechthei, aerea,
  lasarpiciferis, reiecta, sic, liquisse, deprensa, pegaseo). Engine unit
  tests 8/8.

## Open threads
- **Triage the ~17 remaining blocker-FIXes** (ISSUES.md M-023m OPEN): run
  `cd /f/projects/latin-macronizer-wasm && node test/catullus-blocker.mjs`, read
  `C:/Users/HELLPA~1/AppData/Local/Temp/catullus-blocker.txt`. Verify each
  `FIX:` form against the gold word IN CONTEXT before adding (tu/hoc/ridete are
  metrical/editorial, not wordlist errors). ~247 failing lines total, dominated
  by the iambic poems.
- **The site's `macronizer/dist/` is STALE vs the engine repo** — it lacks the
  M-013b→m ACCENT_OVERRIDES and the Germanis/single-accented engine fix
  (M-023k touched both, but the site's dist still predates M-013b). Next engine
  change should sync via upstream `npm run build` (site copy is BEHIND).
- Prior M-013 scansion threads still open: `veo`/`eo`/`ua` synizesis,
  `-que`-in-arsis (~12 lines), hypotactic corpus expansion.

## Running / unfinished
Nothing running. No half-done edits. Scansion snapshot (harness) unchanged at
47 lines — the gold is decoupled from it. Regenerate with
`node test/regen-snapshot.mjs` only after an intended harness-corpus change
(the WASM wordlist-persist OOMs a single process after ~11 large files —
recreate the macronizer per file, as `regen-snapshot.mjs` now does).

## Don't redo
- **Compare the macronizer to a gold via SCAN, never per-vowel prose.**
  `accented[0]` is tagger-ranked (short-biased, context-flipping) and ~30% of
  syllables are long-by-position — a ~70% per-vowel "agreement" is a trivial
  baseline. Only lines that FAIL to scan are actionable (M-023m).
- **Override forms must produce the gold in the line's ACTUAL segment** —
  verify with `possibleScans`. Overrides only ADD candidates (monotonic, prose
  keeps accented[0]).
- **Gloss don't-redo**: `test:gloss` needs `utils/ls_golden_fixture.json` —
  regenerate it in the SAME commit as any `gloss_golden.json`/L&S-key edit
  (`npm run build:gloss-fixture`) or CI stays red. Numbered homographs → L&S
  key authoritative. Golden 2075 / census 348.
- **Popup don't-redo** (M-023g→h.4): glosses warm at init; popup anchors above
  the word; expanding details must NOT reposition (internal scroll clamps);
  `toggle` doesn't bubble + innerHTML rebuilds → re-wire via
  `wirePopupDetails()`. e2e-locked in `e2e/popup-check.spec.js`.
- **Judge scansion by the whole-file gate only** (per-line RFTagger differs);
  never corrupt vowel quantities to make a line scan; `?` in a gold pattern is
  a wildcard, not a blocker.
