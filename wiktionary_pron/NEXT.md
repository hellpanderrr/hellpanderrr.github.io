# Next

_Updated 2026-08-05 — branch `main`_

## State
Macronizer scansion saga fully resolved. Site `main` (live on Pages) = `748b6c3`;
engine `main` (was `macronizer-ui-support`, now fast-forwarded, branch deleted)
= `e7fb22a`. Both pushed, both working trees clean.

What's fixed and committed:
- **M-003** scansion display + root cause: `macrons.txt` had `italorum` short-`I^`,
  but hendecasyllable pos 8 needs `Ītalōrum`. Fixed via `ACCENT_OVERRIDES` in the
  engine (dual reading, prose keeps short), not a one-off wordlist edit (33MB
  file is regenerated upstream).
- **M-010/011/012** popup honesty: "Wordlist: Found" no longer lies for
  Morpheus-rescued words, Morpheus rows deduplicated, RFTagger-vs-reading POS
  disagreement noted. Guarded by `e2e/popup-check.spec.js`.

## Open threads
- **M-013 — the scansion wordlist-gap miner.** Tooling is committed (engine
  `test/miner-scansion.mjs` + `test/data/corpus/`). **176 lines flagged** across
  Aeneid 1-6 + Catullus (5,507 lines). Three buckets: Greek names (engine
  limitation), ambiguous/enclitic forms (candidate gaps), and common-word
  failures like Catullus 13.11 `nam unguentum dabo` (automaton strictness).
  **Next action: Phase 2** — confirm flagged lines against Pedecerto
  (pedecerto.eu/scansioni, single-verse lookup, no bulk scrape) to separate
  real gaps from engine limits. Run: `node test/miner-scansion.mjs` in the
  engine repo.
- **Reply to the r/latin thread.** M-003 is fixed too now. See `docs/ISSUES.md`.

## Running / unfinished
Nothing running. A local static server may still be on :8993 (harmless).

## Don't redo
- **`^` means short, `_` means long — full stop.** The initial "ambiguous marker"
  fix to `possibleScans` was WRONG and reverted. `italorum` was a data gap, not
  an engine bug. (Classicist agent confirmed Ītalōrum is required by Catullus
  1.5 itself; Ellis 1.5 note is about chronica realia, not quantity.)
- **`public/macrons.txt` is regenerated from upstream** — never hand-edit it for
  a one-off fix; the edit silently vanishes on next pull. Use
  `ACCENT_OVERRIDES` in `src/core/Tokenization.ts` instead.
- **The Aeneid corpus must be stripped of Latin Library line numbers** (every 5th
  line). The miner's ~160-fail-per-book artifact was those trailing digits.
- **Catullus 8 is choliambic, not hendecasyllable** — assigning it to the
  hendecasyllable corpus made all 19 lines "fail." Same for 4/29/52 (iambic
  trimeter, engine's "iambic" is trimeter+dimeter).
- **Morpheus is NOT broken** (see prior NEXT.md) — the byte-grep false lead.
- **Never run `build-morpheus-wasm.sh` against a read-write engine mount.**
