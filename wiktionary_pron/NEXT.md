# Next

_Updated 2026-08-06 — branch `main`_

## State
Session: UI fixes + M-013 Phase 2 (scansion investigation) complete. Site `main`
= `ddb8d44`; engine `main` = `e7fb22a`. New commits pending in both (see below).

Fixed and committed this session:
- **divisa/diviso click-cycle bug** — display now mirrors the input's own u/v
  orthography (`divisa` stays `dīvīsa`, `diuisa` stays `dīuīsa`). Previously
  the wordlist's classical-`v` form showed briefly, then the first click forced
  `u` and the original was unreachable. `applyOrtho` now takes the input text.
- **Grey `—` box (M-003 regression)** — the foot placeholder now only renders
  when a meter is selected (prose shows nothing). And trailing line numbers
  (`urbem, 5`, `libellum 1.1`) are stripped before processing — a trailing
  number changed the last word's "following segment" and made the verse
  impossible to scan.
- **M-013 Phase 2** — see `docs/ISSUES.md`. Conclusion: the 153 flagged lines
  are **engine/prosody limitations, not wordlist gaps**. Aen 2.774 (`obstupui,
  steteruntque comae...`) is canonical hexameter the engine can't scan because
  `ui` isn't treated as a diphthong. `ACCENT_OVERRIDES` was right for italorum
  but there's no pile of similar cases.

## Open threads
- **M-013 Phase 3 (if pursued): the scansion engine's prosody rules** —
  diphthong `ui`, elision across `-m`, automaton strictness. The regression
  gate now exists: `npm run test:scansion` (engine) asserts 5 canonical lines
  scan and no NEW failures beyond `test/data/scansion-failures-snapshot.json`
  (153 lines). Any future scansion fix must keep that gate green.
- **Commit the pending work in BOTH repos** — the session ended with uncommitted
  changes:
  - Site: `macronizer.html` + `e2e/popup-check.spec.js` + `e2e/macronizer.spec.js`
    + `docs/ISSUES.md` + `NEXT.md` (this file).
  - Engine: corpus cleanup (9 files), `test/categorize-miner.mjs`,
    `test/culprit-words.mjs`, `test/e2e/test-scansion-corpus.mjs`,
    `test/data/scansion-failures-snapshot.json`, `package.json` script.
  Commit + push both.
- **Reply to the r/latin thread** — M-003 is fixed. See `docs/ISSUES.md`.

## Running / unfinished
Nothing running. The corpus test takes ~1-2 min (WASM + wordlist load).

## Don't redo
- **`^` means short, `_` means long — full stop.** `italorum` was a data gap,
  not an engine bug.
- **`public/macrons.txt` is regenerated from upstream** — never hand-edit. Use
  `ACCENT_OVERRIDES` in `src/core/Tokenization.ts`.
- **The Aeneid corpus must be stripped of line numbers and page furniture** —
  trailing digits AND the `Vergil` / `The Classics Page` footers break scansion.
- **Catullus 62 refrains ("Hymen o Hymenaee") are lyric chants, not hexameter** —
  don't put them in the hexameter corpus (verified via Tavily).
- **Catullus 8 is choliambic**; 4/29/52 iambic trimeter (engine's "iambic" is
  trimeter+dimeter).
- **normalizeLine must strip macrons BEFORE [^a-z ]** — the corpus is stored
  macronized; a naive strip mangles `canō` → `can`.
- **Pedecerto is IP-blocked (HTTP 412)** even with a browser UA — use Tavily.
- **Morpheus is NOT broken.** **Never run `build-morpheus-wasm.sh` against a
  read-write engine mount.**
