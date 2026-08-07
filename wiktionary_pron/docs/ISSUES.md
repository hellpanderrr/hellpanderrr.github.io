# Issues

Findings that outlived the session in which they were discovered. IDs are
stable and never renumbered; fixed rows stay, with `Status: FIXED` and the
evidence that closed them.

Totals: 8 open, 7 fixed (15 total).

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
**Status: FIXED** (2026-08-05, site `fe9081b`)
The `.verse-foot` span was only created when `scannedFeet[lineIdx]` was
truthy; an empty string rendered nothing, so unmetered lines looked broken.
Now the span always renders, showing a muted `—` placeholder via a new
`.verse-foot.no-scan` class. Same commit also fixed the wider scansion
story: `macrons.txt` had `italorum` with a short initial `I^`, but the
hendecasyllable's fixed-long position 8 requires `Ītalōrum`. The fix is a
JS `ACCENT_OVERRIDES` map in the engine (`e7fb22a`) carrying both readings,
not a one-off wordlist edit (the 33MB file is regenerated upstream).

## M-004 — Output is not editable
**Status: OPEN** (editable output shipped `54d425e`; Phase 3 persistence remains)
Output is now real editable text: contenteditable lines, click-vowel macron
toggle, Ctrl+Z/Y undo, and a mobile tap-flagged→readings-sheet (site `54d425e`,
`e5fa491`). What remains from the plan (`docs/EDITING-OVERHAUL-PLAN.md` Phase 3):
the accepted-names list and input-hash snapshot — the pieces that make edits
*survive* a revisit, not the in-session editing itself.

## M-005 — Word popup shows no dictionary definition
**Status: OPEN.** Users cannot tell *populus* (people) from *populus* (poplar),
or the two *malus* lemmas, from the readings list alone. Add a dictionary link
per reading — `accentedSources` already carries lemma+tag per row.
**2026-08-07 research (not yet built):** Two gloss sources were evaluated against
the real wordlist and audited by subagents.
- **Source** = `whitakers-words` npm (MIT, kigawas port of Whitaker's WORDS) +
  Lewis & Short JSON (`utils/ext_tmp/ls_*.json`, Perseus, CC-BY-SA). Both
  Perseus-sourced so the wordlist lemma → L&S numbered key aligns.
- **Measured:** 84% of (lemma|POS) resolve; ~92% of rendered *wordforms* (a
  WORDS-on-wordform fallback +2.6pp). Gap is rare names/derived verbs, not
  everyday words. Bundled map ≈ **568 KB gz**.
- **Extraction rule** (in `_probe_final.cjs`): WORDS-first is **WRONG** — WORDS
  parses only the bare base and returns homograph-1, mis-keying `paro2`,
  `acceptor2`, `virosus2`, `sustentaculum`. **Prefer L&S by exact numbered key
  first** (both subagents independently agreed). L&S `senses[0]`, strip
  multi-token leading abbrev (`V. a.,`/`Lit.,`/`V. inch. n. [..]`), split on
  `;:`, strip author-citations, reject crossrefs (`init./fin./v.the foll.art.`)
  and grammar fragments (`Part.`/`Sup.`/`Gen.`/`In gram`).
- **Gotcha:** Perseus tag gender is at **index 6** (`n-s---fn-`), not index 3 —
  reading tag[3] makes gender always empty. The `tag[3]` value is the
  *subcategorization*, not gender.
- **Build:** `utils/build_glosses.cjs` (Node, not Python — the WORDS fallback
  needs the `whitakers-words` npm engine) → `macronizer/glosses.tsv.gz`
  (`lemma\tgloss`, gzipped, ~476 KB), site-side, no engine change; render as a
  quiet `r-def` column on reading rows (council design); fallback to `—`/link
  for the ~5% ambiguous (L&S exact-key when N≥2, else WORDS, else omit).

**2026-08-07 refined pipeline + labeled-holdout audit (BUILT as `utils/build_glosses.cjs`):** Two
advisor audits (quality + measurement) found the first-clause extractor
("88%") shipped ~15% fragment/garbage glosses (common verbs came out as
citation fragments: `verto`→"Lucr", `amo`→"Amāsse = amavisse"), and the first
scoring pass traded coverage for correctness. A second pass (`_probe_refined.cjs`)
fixed the systemic issues and was audited on a fresh 120-row labeled holdout.
The pipeline is ported verbatim to `utils/build_glosses.cjs` (Node, because the
WORDS fallback is npm-only) and produces `macronizer/glosses.tsv.gz`.
- **The 6 extraction fixes** (all in `_probe_refined.cjs` + `utils/build_glosses.cjs`):
  1. **POS-gated verb bonus** — only verbs get +2 for a `to X` clause; nouns/adjectives *lose* points for one. Killed the dominant wrong-gloss class (`acus`→"to embroider" was a needle, `fames`→"to leave" was hunger): 322 of 17,861 noun-glosses used to start with "to".
  2. **Spurious-homograph skip** — when the wordlist `lemmaN` form-set is byte-identical to its bare `lemma` twin (210 lemmas / 5,690 rows), the wordlist duplicated one homograph under two keys; prefer the bare-key gloss instead of exact-key (else `paro2`→"make equal" when the wordlist's `paro2` is the *prepare* verb).
  3. **Bare-capital-adjective recognition** — L&S adjectives open with a capitalized English word ("Useful", "Empty", "Desolate"); these now score as definitions. Guarded against function-word openers ("With inf", "Of persons" are NOT adjectives).
  4. **Primary-first + strict-higher-score + earlier-tiebreak** — the argmax across all flattened clauses prefers the primary L&S sense over deep example/translation strings.
  5. **POS-aware cross-ref resolution** — `main_notes "v. X"` recurses into the target using the *target's* POS (`potens`→"to be able", `versor`→"to turn", `beatus`→"the rich", `certo`→"Determined, resolved, fixed" via `certus`).
  6. **Fragment blockers** — scope-labels ("Of persons."), etymology context ("root div-, to gleam" AND Greek words "Gr. φλυω" rejected unless a `]` intervenes), dangling-"hence" markers, unclosed trailing paren (clause-split broke "(syn.: ...)" across clauses — `fleo`→"to weep" was losing to "to neigh").
- **Measured (final):** L&S 80.6% + WORDS 4.1% = **84.7%** of (lemma|tag) rows;
  unique-lemma **77.9%**; frequency-weighted **87.0%**; top-1000 most-attested
  **97.6%**. Artifact **476 KB gz** (under the 568 KB budget).
- **Labeled-holdout audit (120 rows, independent subagent):** 104 CORRECT / 11
  MINOR-FLAW / 1 WRONG / 4 cannot-judge → **99.1% usable, 0.9% wrong** (the one
  wrong row was `aequalis`→"Of persons.", a section label — since fixed).
  Common words: 100% usable, 0% wrong (but ~13% show a literal/secondary sense
  like `fero`→"set in motion" vs "carry" — L&S's first-listed sense). Rare
  words: 98% usable. **Shippable as "machine-extracted, not hand-verified."**
- **2026-08-07 re-audit on the FINAL pipeline (85.9%, post-build-fixes):**
  deterministic residue scan + fresh 120-row sample (seed 424242).
  Residue over 28,658 L&S glosses: **4.41%** (trailing usage-note 1.25%,
  trailing author 0.55%, trailing citation 0.47%, trailing etc/al/sq 1.96%,
  mid cross-ref 0.06%, unconverted macron 0.01%). WORDS glosses: 1.07%
  residue. Fresh sample: **0 WRONG** (common-60 all usable; ~6 minor literal-
  sense verbs — `fero`/`impedio`/`amo`/`juvo`/`volvo`/`veho`; random-60 a few
  citation tails `Truc. prol`/`Cato R. R`). Zero wrong-homograph cases in the
  artifact (populus/populus2/malus2/paro2/levo2/vestitus2 all correct).
  Re-confirms: **shippable**, ~0% wrong, 4.4% cosmetic residue.
- **Remaining known gaps (don't chase):** sense-ordering for polysemous verbs
  (surface the idiomatic primary, not L&S's first section) and a few
  citation residues (`(class.)`, `de Or`, `Truc. prol`) — cosmetic, not wrong.

## M-006 — Popup buries the useful section under debug detail
**Status: OPEN.** r/latin feedback: "Possible readings" is the only part users
want; the RFTagger/Morpheus detail reads as debug output. Move readings to the
top, collapse the rest behind `<details>`. Also the heading is misleading — it
lists *distinct macronizations*, not all morphological readings (readings that
differ only in a short vowel collapse into one row).

## M-007 — Individual words/lines cannot be selected or copied
**Status: FIXED** (2026-08-06, site `54d425e`)
Words render as real text nodes (`setDisplay` syncs textContent + content), so
they are natively selectable/copyable/findable. The per-line copy *button* was
added then removed (redundant with native selection + caused a popup-overlap
bug) — native selection is the mechanism now.

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

## M-010 — Word popup showed "Wordlist: Found" for Morpheus-rescued words
**Status: FIXED** (2026-08-05, site `fe9081b`)
`currito`/`diffregit` aren't in `macrons.txt` but the popup said "Found".
`getAllEntries` merges Morpheus extras into wordlist hits, so `isUnknown`
stayed false. Fixed by keying the label on `token.morpheusAnalyzed` —
extras only ever exist for file-absent words — showing "Not found — via
Morpheus" instead.

## M-011 — Duplicate Morpheus rows in the word popup
**Status: FIXED** (2026-08-05, site `fe9081b`)
Morpheus emits the same parse across case-variant runs, and the popup
rendered them raw. Deduplicated in `macronizer.html` keyed on
lemma+accented+rendered-features (comparing `formInfo` objects failed —
their conditional fields differ in structure).

## M-012 — RFTagger POS silently contradicted the selected reading
**Status: FIXED** (2026-08-05, site `fe9081b`)
`currito` tagged `d--------` (adverb) but read as a verb. The popup now
compares the RFTagger POS against the active reading's POS and shows a
note when they disagree.

## M-013 — Scansion wordlist-gap miner + corpus (found, not fixed)
**Status: OPEN** (engine `e7fb22a` added the tooling; `bfb5035` Phase 2 analysis)
`test/miner-scansion.mjs` + `test/data/corpus/` feed Aeneid 1–6 + Catullus
(5,507 lines) through the macronizer and flag lines whose scansion returns
empty — the italorum signature. **153 lines flagged** after corpus cleanup
(176 minus page furniture — `Vergil`/`The Classics Page` footers, a stray
`+`, em-dashes — and the Catullus 62 refrains, which are lyric chants, not
hexameter). Categorized via `test/categorize-miner.mjs`:
- **Known words but scansion fails (155)** — the italorum signature. Deep
  dive: Aen 2.774 `obstupui, steteruntque comae et vox faucibus haesit` is
  canonical hexameter but the engine stores `obstipui → obsti^pu^i_` (4
  syllables) and `segmentAccented` doesn't treat `ui` as a diphthong — a
  prosody-model limitation, not a wordlist gap. No word shows a wrong
  quantity; the top culprits (`que`, `et`, `non`) are correctly macronized.
- **Contains unknown word (7)** — Greek names (`Thesea`, `Euryalus`,
  `Helymus`), an engine limitation.
- **Conclusion: NO wordlist gaps beyond the already-fixed italorum.**
  `ACCENT_OVERRIDES` was right for italorum but there is no pile of similar
  cases. The real next step is the scansion engine's prosody rules
  (diphthong `ui`, elision, automaton strictness).
Phase 2 added `test/e2e/test-scansion-corpus.mjs` — a regression gate that
asserts 5 canonical lines scan (including italorum) and that no NEW failures
appear beyond the recorded snapshot `test/data/scansion-failures-snapshot.json`.
Run: `npm run test:scansion` (engine repo). Pedecerto (pedecerto.eu) is
IP-blocked (HTTP 412) even with a browser UA, so confirmation was done via
Tavily instead.

## M-014 — Dark-mode `—` chip for unscannable verse is indistinguishable
**Status: FIXED** (2026-08-06, site `fcfd1bc`/`e5fa491`)
The `.verse-foot.no-scan` placeholder lost to `body.dark_mode .verse-foot` on
specificity, so unscannable lines rendered the same purple as real feet in dark
mode. Fixed with `body.dark_mode .verse-foot.no-scan` (0,3,1 beats 0,2,1). Was
**untracked** (only folded into M-003's evidence) — recorded here for a complete
tracker. Not asserted by any e2e test (see M-015).

## M-015 — Test infra: no coverage measurement; e2e re-parses wordlist per test
**Status: OPEN** (2026-08-06)
Two test-infrastructure findings:
1. **No coverage tooling existed** until this session. Now wired: `npm run
   test:coverage` (c8 for unit/IPA + opt-in `COVERAGE=1` V8 collector
   `e2e/coverage-collect.spec.js` + `scripts/tests/coverage-merge.mjs`).
   Measured 2026-08-06: **61.92% statements** overall; `macronizer.html` 71.6%;
   **Scansion.js 12%, MorpheusAnalyzer 42%, alignMacronized 29%** (engine
   correctness, not UI — unit tests belong in the engine repo).
   2026-08-07: the collector now drives the desktop paths exhaustively
   (Escape, outside-click, multi-line undo, unknown-word, scansion, dark-mode
   chip) plus the touch/sheet paths via a second page in the same context with
   CDP touch emulation (shares IndexedDB — no second wordlist parse). Measured:
   **66.44% statements** overall; `macronizer.html` **78.16%**; Scansion.js
   **85%, alignMacronized 74%, MorpheusAnalyzer 55%**.
2. **Every macronizer e2e test re-downloads + re-parses the 812k wordlist** in
   its fresh context (8 parses/CI run across editing + popup-check). Fix:
   share one context per spec file. Also the CI exclusion `--grep-invert
   macronizer` is title-based + stale — wordlist-heavy editing/popup-check DO
   run in CI (`../.github/workflows/tests.yml:57` comment is outdated).
   Coverage-gap plan (from a 3-agent council): extend existing tests (Escape,
   scrim/Back/blur, multi-line undo, dark-mode chip, CSV content) + 2 new
   (unknown-word red flow, copy-after-edit).
   **2026-08-07 done:** editing.spec.js and popup-check.spec.js are now `serial`
   with one shared page (8 parses → 1 for those files), and gained all the
   plan's gaps: Escape+focus-return, scrim/Android-Back/blur in the touch test,
   multi-line undo, dark-mode `.no-scan` chip, CSV content (cycled spelling),
   + new unknown-word red-flow and copy-after-edit tests. The stale CI
   exclusion (item above) is NOT yet fixed.
