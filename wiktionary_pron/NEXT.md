# Next

_Updated 2026-08-06 — branch `main`_

## State
Session: UI fixes + M-013 Phase 2 done; editing/copying overhaul PLANNED (not built).
Site `main` = `1b9357b`; engine `main` = `4ebd910`. Both pushed. Working trees clean
(only the plan doc + CLAUDE.md/ISSUES.md edits from this session are uncommitted).

Done & committed this session:
- **divisa/diviso bug** — display mirrors the input's u/v (`divisa` → `dīvīsa`,
  `diuisa` → `dīuīsa`); grey `—` box fixed (meter-gated + trailing-number strip).
- **Popup reorder** (readings first, debug behind `<details>`), **CSV split button**
  (per-word default / per-line in dropdown, keyboard, persisted checkmark), **clear
  restores sample**, **dark-mode `—` chip** — all in `1b9357b`.
- **M-013 Phase 2** — 153 flagged lines are engine/prosody limits, NOT wordlist gaps.
  Corpus cleanup + `npm run test:scansion` regression gate committed in engine `4ebd910`.

## Open threads
- **M-004 + M-007 (editable + selectable/copyable output) — the plan is written,
  implementation not started.** Read `docs/EDITING-OVERHAUL-PLAN.md` (v2). Start Phase 1:
  (1) `setDisplay` setter (textContent + content sync), (2) move `.ambig`/`.unknown`
  highlighting OFF `.ipa::before` onto the span — this is the #1 trap, (3) native
  selection + per-line copy, (4) gate popup on a `dragging` flag.
- **M-013 Phase 3 (if pursued)** — scansion prosody rules (`ui` diphthong, elision,
  automaton strictness). Gate: `npm run test:scansion` in the engine must stay green.
- **Reply to the r/latin thread** — M-003 fixed; editing/copying now planned.

## Running / unfinished
Nothing running. Uncommitted this session: `docs/EDITING-OVERHAUL-PLAN.md` (new),
`CLAUDE.md` (2 UI-traps lessons), `docs/ISSUES.md` (M-004/M-007 plan refs), `NEXT.md`.

## Don't redo
- **Do NOT build a "decisions replay" state machine** — rejected by a 4-member council
  (typed edits have nothing to replay onto; "form still in candidate set" kills hand-fixes;
  surface+lemma over-applies to every occurrence; unknowns degenerate; lemmas go stale).
  Use **snapshot (input-hash) + a surface-keyed accepted-names list** — see plan's
  "Rejected (v1)" section.
- **`attr(content)` hosts the `ambig`/`unknown` highlights too** — moving text to
  `textContent` without moving the highlights collapses the flags.
- **`^` short, `_` long — full stop.** `italorum` was a data gap, not an engine bug.
  `public/macrons.txt` is regenerated upstream — use `ACCENT_OVERRIDES`.
- **Corpus**: strip line numbers AND `Vergil`/`The Classics Page` footers; Catullus 62
  refrains are lyric chants, not hexameter; Catullus 8 choliambic; 4/29/52 iambic
  trimeter. `normalizeLine` strips macrons BEFORE `[^a-z ]`.
- **Pedecerto is IP-blocked (412)** — use Tavily. **Morpheus is NOT broken.**
  **Never run `build-morpheus-wasm.sh` against a read-write engine mount.**
