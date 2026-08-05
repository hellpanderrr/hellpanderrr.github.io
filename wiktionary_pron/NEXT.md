# Next

_Updated 2026-08-05 — branch `main`_

## State
Fixed the macronizer parity bug reported on r/latin: `currito` → `curritō` and
`diffregit` → `diffrēgit` now match Winge's original. Two interacting port bugs
(M-001 Morpheus `,lemma` suffix never stripped; M-002 `addEntry` left a stale
`entriesCache`). Verified first-visit *and* return-visit in a real browser;
81 node tests + 3 macronizer e2e green on exit code. Site `main` = `1cb1771`
(live on Pages), engine `macronizer-ui-support` = `797f779`. Both pushed, both
working trees clean.

## Open threads
- **M-003, the obvious next one**: scansion feet disappear when a line number
  trails the line. Display-only — start at `scannedFeet[lineIdx]` in
  `macronizer.html` (~line 1150). Reproduce with Catullus 1 in hendecasyllable
  mode; line 4 shows no foot.
- **Reply to the r/latin thread.** Both macronization bugs are genuinely fixed
  and were real bugs in the port — say so. See `docs/ISSUES.md` M-003..M-007
  for the rest of that feedback.
- Remaining findings have IDs in `docs/ISSUES.md` (7 open) — read it rather
  than re-deriving from the thread.

## Running / unfinished
Nothing running. A local static server may still be on :8993
(`curl -s -o/dev/null -w "%{http_code}" http://127.0.0.1:8993/wiktionary_pron/macronizer.html`);
harmless, and `npm run test:e2e` starts its own.

## Don't redo
- **Morpheus is NOT broken.** A long stretch of last session chased "missing
  Latin stemlib indices in `cruncher.data`". False. Two independent agents
  refuted it and the shipped WASM analyzes `currito`/`diffregit`/`aqua`
  correctly. The byte-grep that "proved" it was meaningless — filenames live in
  `cruncher.js`'s manifest, not the `.data` blob.
- **Always `morpheus_set_language(32768)` before analyzing.** Skipping it makes
  the cruncher read `stemlib/Greek/` and return 0 for every word, which looks
  exactly like a broken build.
- **`macrons.txt`, `tag_to_endings`, the RFTagger model and `toAscii` are all
  byte-identical to upstream Alatius.** Already diffed. Not the problem.
- **The `macronizer-py-compare` Docker image is not a usable reference** — its
  cruncher defaults to Greek and the build strips `stemlib/Greek`, so it fails
  on every word and "agrees" with any wrong output.
- **The scansion of `iam tum, cum ausus es unus Italorum` is not a parity bug.**
  Prose and scan modes give identical output in both engines.
- **Never run `build-morpheus-wasm.sh` against a read-write mount of the engine
  repo** — its `rm -rf stemlib/Greek` deleted 711 tracked files last session
  (restored).
