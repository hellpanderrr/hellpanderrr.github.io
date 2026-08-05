# Issues

Findings that outlived the session in which they were discovered. IDs are
stable and never renumbered; fixed rows stay, with `Status: FIXED` and the
evidence that closed them.

Totals: 7 open, 2 fixed (9 total).

---

## M-001 — Morpheus accented form keeps the `,lemma` suffix
**Status: FIXED** (2026-08-05, engine `797f779` / site `1cb1771`)
`parseAnalysisLine` stored `currito_,curro` as the accented form instead of
`currito_`. Python reference strips it (`postags.py:434-436`). Corrupted DP
alignment for every out-of-wordlist word on return visits.

## M-002 — `addEntry` left a stale `entriesCache`
**Status: FIXED** (2026-08-05, same commits)
`ensureAnalyzed` cached the empty lookup for a missing word; the Morpheus row
written immediately after was invisible to `getAccents`, which fell through to
the `tag_to_endings` heuristic. Broke first visits: `currito` → `currītō`.

## M-003 — Scansion feet vanish when a line number trails the line
**Status: OPEN.** Reported on r/latin. Reproduced on Catullus 1: line 4
renders no metrical notation while the macronized words stay correct.
Cause is display-side — `scannedFeet[lineIdx]` in `macronizer.html` (~line
1150) misaligns when a trailing line-number token shifts the line index.
Engine macronization is *not* affected. Not a parity bug.

## M-004 — Output is not editable
**Status: OPEN.** Adoption blocker per r/latin feedback: users macronize to
catch typos and normalize spellings (`-īs` → `-ēs`) and cannot correct the
result. Winge's original site made the output `contenteditable` in May 2017
plus per-vowel click-to-toggle. Substantial build: contenteditable +
re-macronize + re-export + surviving the cycle/click handlers.

## M-005 — Word popup shows no dictionary definition
**Status: OPEN.** Users cannot tell *populus* (people) from *populus* (poplar),
or the two *malus* lemmas, from the readings list alone. Add a dictionary link
per reading — `accentedSources` already carries lemma+tag per row.

## M-006 — Popup buries the useful section under debug detail
**Status: OPEN.** r/latin feedback: "Possible readings" is the only part users
want; the RFTagger/Morpheus detail reads as debug output. Move readings to the
top, collapse the rest behind `<details>`. Also the heading is misleading — it
lists *distinct macronizations*, not all morphological readings (readings that
differ only in a short vowel collapse into one row).

## M-007 — Individual words/lines cannot be selected or copied
**Status: OPEN.** Only the bulk "copy" button works. Structural: words render
via `<span class="ipa" content="…">` painted with CSS `attr(content)`, so the
selectable text is empty, and the popup/cycle handlers own the click.

## M-008 — `rftagger.js` ships an assertions (debug) build
**Status: OPEN.** CodeRabbit finding on PR #7. `assert()` bodies,
`checkStackCookie`, `runtimeDebug` and the missing/unexported symbol tables are
all present, unlike the release-style `cruncher.js` beside it. Inflates the
one-time download and keeps assertions on hot paths. Fix belongs in the engine
repo's build, then re-sync `dist/`.

## M-009 — Deployed WASM assets are untracked
**Status: OPEN.** `macronizer/wasm/cruncher.*` is untracked (not ignored), so
the bytes actually served have no verifiable provenance. Commit them, or record
the build SHA that produced them.
