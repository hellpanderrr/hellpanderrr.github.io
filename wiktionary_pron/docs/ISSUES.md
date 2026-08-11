# Issues

Findings that outlived the session in which they were discovered. IDs are
stable and never renumbered; fixed rows stay, with `Status: FIXED` and the
evidence that closed them.

Totals: 6 open, 10 fixed (15 total).

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
**Status: FIXED** (2026-08-07, site `5ad9391` + `5c62e5b` + `6a453cf`).
Users can now tell *populus* (people) from *populus* (poplar): the readings
popup has a quiet `r-def` column, filled from `macronizer/glosses.tsv.gz`
(exact-key-first, so `populus2`→poplar). Built by `utils/build_glosses.cjs`
(L&S + WORDS, Node because the WORDS fallback is npm-only). 85.6% of
(lemma|tag) rows glossed, 456 KB gz. Audited ~99% usable / 0% wrong on common
words; residue 3.88%. One known wrong word remains: `appello`→"To drive"
(inherent wordlist conflation of appello1/2 under one bare lemma).
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

**2026-08-07 real-text stress test (the Caesar passage) → 4 more systematic
fixes.** Typing *"Gallia est omnis divisa..."* exposed wrong glosses on the most
common words, all now fixed in `_probe_refined.cjs` + `utils/build_glosses.cjs`:
- **Case-collision guard** — the wordlist spells the pronoun *other* as `Alius`
  (capitalized), colliding with L&S's proper-noun `Alius1` ("native of Elis").
  When a capitalized wordlist lemma's L&S homograph-1 is a capitalized proper
  noun and a numbered sibling exists, resolve the sibling (`Alius`→`alius2`→
  "another, other").
- **Quantifier + interrogative openers** — "All, every", "who? which? what?"
  now score as strong definition openers (word-boundary match, so "All," works).
- **Grammar-note penalty** — usage notes ("The rel. freq. agrees with the foll.
  word", "the neutr. plur. omnia is often closely connected...") get −4 via
  grammar-abbrev density; bare author names glued to a clause end get −4 too.
- **Primary-first + terse preference** — among the first 3 flattened senses,
  prefer a short (≤80 chars) high-score clean gloss; then fall back to the full
  argmax. A marginal secondary ("to cultivate (late Lat.)", era −1) can no longer
  beat the primary ("to inhabit (class.)", era +1); a deep translated example
  can't out-score "All, every". Bracket-close split ("Engl. else], another, other").
- **Result on the passage:** `alius`→"another, other", `omnis`→"All, every",
  `qui`→"who? which? what?", `incolo`→"to dwell or abide in a place",
  `venio`→"to come. spring, be descended", `ipse`→"the master, himself".
  `appello`→"To drive" is the ONE remaining wrong word — inherent: the wordlist
  conflates appello1 (drive) and appello2 (call) under one bare lemma.
- **Re-measured after fixes:** coverage 85.6% (L&S 81.3 + WORDS 4.3), 31,704
  lemmas, 456 KB gz; L&S residue **3.88%** (down from 4.41%), WORDS 1.10%.

**2026-08-08 restructure (site `93d1cef`): the Aeneid stress test broke the
"99.1% usable" claim.** A second real-text test (Aeneid 1.1–11, epic register vs
Caesar's prose) exposed ~11 WRONG common-word glosses the 120-row holdout had
missed: `terra`→"the sea", `vis`→"the same as Juno", `superus`→"the Adriatic and
Ionian Sea", `memor`→"which remembers the Marsian war", `profugus`→"a proelio",
`fatum`→"that which is said", plus saevus/altus/ira/ille/multus. The holdout
measured *fragment-ness* (well-formed English) not *correctness*, on an
unstratified sample — it structurally could not see "the sea" as wrong. Root
cause (3-advisor panel): the extractor was content-blind to L&S's positional
structure — the real primary sits at the TAIL of senses[0] after the etymology
block, and the ETYM guard skipped exactly those, forcing fall-through to
secondaries/examples.
- **Restructure (decoupled gate-then-rank):** hard per-clause gates (fragments,
  citations, usage-notes, pure-Latin) REMOVE candidates before ranking;
  selection = score → latinCount → sense-order → runTokens → shorter. Plus
  ETYM-tail exemption, hyphen-compound tolerance, exhaustive citation stripping,
  proper-noun preamble strip, leading-etymology-prefix strip, era demotion.
- **Golden suite (new):** `utils/gloss_golden.json` (75 hand-labeled rows) +
  `utils/test_gloss_regression.cjs` (~2s, `npm run test:gloss`, wired into
  `npm test`). Locks content, not well-formedness.
- **Build memoized:** resolve()/wGloss() per lemma → 841s → 50s, byte-identical.
- **Result:** 89.8% coverage (was 85.6%), 32,799 lemmas, 467 KB gz; stress batch
  all correct; 75/75 golden. Known accepted residue: ~198 rare-name/edge glosses
  now null (shown as "—") — a deliberate trade: null is fail-safe, wrong is
  fail-loud. `appello`→"To drive" remains inherent.

**2026-08-08 panel audit + function-word fix (the "89.8% coverage" claim was
misleading).** A hand-curated 79-word top-frequency check exposed that the
function-word/closed-class stratum — conjunctions, prepositions, pronouns,
copula, core adverbs — was ~40% WRONG (`autem`→"the parent of all evil",
`et`→"used for et ... et", `cum`→"A being or bringing together",
`sum`→"to pass, elapse", `in`→"hand, busied", `caelum`→"a graver"). A 3-advisor
panel (classicist, data-expert, adversarial-architect) verified the root causes:
- **Scoring asymmetry:** `STRONG_OPEN` (+3) rewards clauses opening "the/a/an/
  used for"; real particle primaries open weak ("on/with/but/for", +1 or 0), so a
  translated example ("the parent of all evil") outranks the gloss.
- **Homograph inversion:** L&S numbers the RARE sense as homograph-1 (`caelum1`=
  chisel, `lego1`=bequeath, `dico1`=dedicate); `resolve()` falls through to base1.
- **EN_WORDS gaps:** "always/forever/together/within/upon" not in EN_WORDS; real
  primaries score 0, examples with common words pass the acceptance floor.
- **Era bonus + cross-ref misfire:** `class.`-marked senses flip ties (`sum`);
  `semper`→"a single time" via a `v. semel` cross-ref.
- **Measurement failure (KEY):** every prior "top-1000 common words" sample ranked
  by WORDFORM COUNT (morphological richness), which is anti-correlated with text
  frequency — function words carry 1–6 wordforms and rank ~30k of 40k lemmas, so
  the failing stratum was structurally excluded. Same lesson as terra→"the sea":
  measure by frequency, not wordform count. The breakage is PRE-EXISTING (proved
  by running the pre-restructure extractor).

**Fix (committed with this section):**
- **CORE_GLOSS override table** (`utils/core_gloss.json`, now **1587 entries**) —
  hand-curated everyday glosses for the closed function-word class + homograph-
  inverted content words + content verbs/nouns whose L&S primary is etymological
  (`scribo`→"to write", `credo`→"to believe", `ago`→"to drive, do, act",
  `os2`→"a bone", `albus`→"white") + proper-noun truncations (`caesar`→"Caesar;
  an emperor") + abstract/legal/military/body/weather terms. L&S never states
  "and"/"but"/"to be" — no scoring rule can recover them. Applied pre-resolve;
  wins over everything. Supports explicit-null → fail-safe "—" (a wrong gloss is
  worse than none). A 14-round curation loop (2026-08-08) grew it from 262
  entries, each round gated by the golden suite + census (monotone rule).
- **WORDS-first for the closed particle class** — lemmas with any r/c/e attestation
  (157 lemmas) prefer Whitaker's WORDS first-result (frequency-ordered) over L&S.
  Scoped so it touches zero content-word golden rows.
- **EN_WORDS expansion** — added together/always/forever/within/upon/among/company/
  however/nevertheless/mount/mountain/sea/heaven/sky.
- **Era cap + enCount suffix expansion TRIED and REVERTED** — they regressed
  `curro`/`impedio` golden rows; the override table handles those cases instead.
- **Measurement gate:** `utils/gloss_census.cjs` — 341 frequency-stratified rows
  (closed-class census + high-frequency content words). Moved the stratum from
  ~38% → **100% correct (341/341)**. Wired into `npm test` + CI.
- **Golden suite extended:** 75 → **1651 rows** (every core_gloss key must have a
  golden row — enforced by test_gloss_regression.cjs; also locks a test-runner
  norm fix for "B.C." glosses). 1651/1651 pass.
- **Result:** artifact 464 KB gz (curated entries REPLACE verbose L&S narratives,
  so size is stable); coverage 89.9%; frequency census
  241/241. A Caesar page now shows correct glosses on the words a student hovers
  most (et→"and", in→"in, within", sum→"to be", autem→"but, however").

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
**Status: PARTIALLY FIXED** (2026-08-11 — engine 25 commits: 150 → **220
failing lines on a 3× corpus** (16,690 lines, 1.32%). The `6c49747`→`fba0aab`
series fixed hypermeter, mid-line `-que`, 5-foot partials (completion bonus),
3 corpus transcription errors, and the gold-lacuna automaton desync, and
HARDENED the gate (`feet.length === 5` fails). The 3× expansion (Aeneid 7-12
+ Georgics + Eclogues + 47 Catullus elegies, `e39b29f`) surfaced a **2.2% true
baseline** that the 6-book corpus under-reported as 0.24% — see M-013g. The
`ui`-diphthong theory was tested and REJECTED, see below. 220 lines remain —
see M-013g.)
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

**2026-08-10 — root cause found (the -ērunt/-ĕrunt alternation).** A
gold-quantities experiment (hypotactic.com's macronized Aeneid) proved the
dominant cause was NOT the ui-diphthong theory from the original analysis:
feeding the gold per-word quantities into `scanVerse` still left ~80/107 lines
failing, and adding a `ui` diphthong rule only unlocked 1–2 lines. The real
systematic mechanism turned out to be the **3rd-pl-perfect -ērunt/-ĕrunt
alternation**: the wordlist marks the e in `stetērunt`/`cōnstitērunt` long, but
the poetic license allows it short. The obstipuī line (and cōnstitērunt) only
scan when `stetĕrunt` reads short.
- **Fix** (engine `Scansion.ts`, `separateAmbiguousVowels`): an accented form
  ending in `[aeiouy]_runt` now also generates the `_^`-ambiguous variant, so
  `possibleScans` offers both lengths. Chosen readings stay correct: obstipuī
  remains 4-syllable `LSSL` (ob-sti-pu-ī), steterunt → `stetĕrunt`.
- **Result:** 3 corpus lines fixed with zero regressions (153 → 150 snapshot
  baseline). Whole-file scansion of Aen 1.1–4 now yields `DDSSDS | DSDSDT |
  DSSSDS | DSDSDS` — line 2's `vēnit` correctly disambiguated by the meter.
- **Rejected:** a word-final `ui`-diphthong merge was tested and produced a
  FALSE positive (obstupuī → 3-syllable `LSL`), and caused a 44-line corpus
  regression (sanguine/anguis where `gu` makes the u consonantal). It was
  reverted. Both the `sanguine` non-merge guard and the 4-syllable obstipuī
  are now locked by unit tests.
- **Tests added:** `test/unit/scansion.test.ts` (8 tests — the first Scansion
  unit coverage) + the obstipuī/cōnstitērunt lines added to the GOLDEN list in
  the corpus gate (7 golden lines now). The golden check was ALSO fixed: it
  previously marked a needle as passing regardless of `feet`, so a golden line
  that stopped scanning would silently pass — it now requires non-empty feet.

**2026-08-10 (same session) — ACCENT_OVERRIDES for gold-confirmed quantity
errors.** A per-word gold comparison against hypotactic.com's macronized
Aeneid found a second systematic class: the wordlist marks several words'
first syllable long where the edition has it short. 7 overrides added to
`Tokenization.ts` `ACCENT_OVERRIDES` (each verified against the gold word):
Lāvini→la^vi_ni_, Orīōn→o^ri_o_n, dehīscēns→de^hi_sce_ns, ecqua→ecqua,
Phryges→phry^ges, Trōes→tro_es, Dīāna→di_a_na (inverse — wordlist had it
short). **10 more corpus lines fixed, zero regressions** (150 → 140 snapshot).
Overrides are injected as extra scansion candidates (prose keeps the wordlist
form), so prose macronization is unchanged.
- The 10 fixed lines: Aen 1.106 (dehiscens), 1.30 (Troes), 1.263/6.890
  (Lavini), 1.102 (Phryges), 1.499 (Diana), 1.535/4.52 (Orion), 3.488
  (ecqua), 3.379 (Lavini).
- GOLDEN list now 14 lines; display output verified to match the edition
  (Orīōn, ecqua, Dīāna).
- Note: the corpus gate still counts a few lines that my per-line
  reconstruction "fixed" but the whole-file gate does not (RFTagger POS
  differs per-line vs whole-file) — always judge by the whole-file gate.

**2026-08-10 (same session) — empty-verse alignment + Catullus/Greek-name
overrides + corpus fixes.** Two subagents parallelized the remaining buckets.
- **Empty-verse alignment bug (engine `Scansion.ts`):** `scanVerses` emitted a
  foot only for non-empty verses, so the `* * * * * * * *` divider lines in
  catullus-LXII/LXIV shifted every subsequent line's feet index. This produced
  spurious failures ("tertia sola tua est" reported failing) and HID 8 real
  LXIV failures. Now empty verses emit empty-foot placeholders (alignment
  preserved; automaton not advanced). Gate + `regen-snapshot.mjs` skip
  non-verse lines. 140 → 137 baseline.
- **15 more ACCENT_OVERRIDES** (subagent-verified against Latin Library /
  wikisource / negenborn scanned Catullus / virgil.org): soluit, inelegantes,
  fragrans, volo, dabo, cyrenis, mane, abite, quandoquidem, tete (missing from
  wordlist), oilei, thesea (unlocks 5 lines), euryalus/euryalum, letum.
  **24 more lines fixed, zero regressions** (137 → 113). Chosen readings
  verified: sŏ-lu-it, in-ē-lĕ-gantēs, fra-grāns (ā by position), vŏlŏ, dăbŏ,
  cŷ-rē-nīs, mănĕ (hiatus), ă-bī-te, tētĕ, ŏ-ĭ-lē-ī, Thē-sĕ-ă, Eu-ry-ă-lus.
- **4 corpus text corrections** (the corpus, not the engine, was wrong):
  catullus-II:7 `solacium`→`solaciolum`, catullus-II:11 `[est/es]`→`est`
  (editorial bracket), catullus-II:13 `ligitam`→`ligatam`, catullus-LXIV:72
  `misera`→`a misera` (missing interjection a). Two hemistichs
  (Nisus et Euryalus primi, tertius Euryalus) are metrically incomplete
  fragments by transmission — the first now scans partially (DDS); the second
  now scans fully (y-synizesis, below).
- GOLDEN list now **23 lines**; baseline **111 failing lines**.
- **Rejected:** est-prodelision ("puero est" → "puero 'st") — only 2 failing
  lines contain est, neither on the death path, and the metrical effect is
  already produced by the existing `'V'`-elision branch. Not worth the risk.
- **FIXED (2026-08-10, engine `c8fcf56`) — y-synizesis for Greek names.**
  `possibleScans` treated u/i as consonantizable (synizesis) when adjacent to a
  vowel but not `y`. Greek names (Euryalus, Euryali) put `y` between a
  consonant and a vowel; treating it as a consonant merges ry+a into one
  syllable and lets the line scan. Whole-file gate 113 → 111 failing lines,
  zero regressions. Fixed Aen 5.322 `tertius Euryalus` and Aen 5.334
  `non tamen Euryali, non ille oblitus amorum` (both added to GOLDEN).
- **Still OPEN — Aen 5.337 `emicat Euryalus et munere victor amici`** remains
  a known failure for a DIFFERENT reason: even with y-synizesis (Eu-rya-lus,
  3 syllables), the gold quantities genuinely do not fit the dactylic-hexameter
  automaton — `lŭs et` (S S) cannot open a foot, `et`-lengthening by position
  fails, and `mūnere` (LSS) / the 5th-foot placement leave no valid reading.
  Only corrupt non-gold quantity readings scan (the quantity-corruption trap),
  so it stays in the baseline.

**2026-08-10 (M-013b) — bulk gold-verified overrides + hypermeter support,
150 → 26 failing lines.** A whole-artifact attack on the 111-line baseline
using the hypotactic per-syllable gold (`vergil.json`/`catullus.json`, NOT the
surface macron text — `rēligiō` shows short re in the surface text but long re
per-syllable). Method per batch: brute-force candidate `_`/`^` forms through
`possibleScans` until the form matches the gold L/S pattern, add as an
`ACCENT_OVERRIDES` entry, rebuild dist, whole-file gate. 15 engine commits,
each gate-verified 0 regressions, snapshot regenerated each time:
- `3f52e73` religio family (long rē, 6 lines) + closed-prefix compounds
  (subiciunt/obicitur/coniciunt/inice — prefix vowel short but syllable
  CLOSED, `su_bi^ciunt`).
- `3df84ee` 15 Greek names (Ilionea, Mnesthea, Tritonidis, Panthus, etc).
- `f8a0253`/`d78a6fc`/`aa9055e`/`74de3cc`/`ddbbc46`/`75afbfa`/`b69d887`
  Aeneid + Catullus quantity fixes (oreades → SLSS, thraces → LS, pulvis →
  LL, aereum → LSSL, tene → LS, etc).
- **`2ee8322` — hypermeter support (the biggest structural win).** A
  verse-final `-que` now offers BOTH the line-final (anceps) and the eliding
  (hypermeter) reading; the automaton picks whichever scans. Lookahead for
  `-que` skips the newline to find the next line's initial vowel. Alignment
  preserved (no line-splicing). Fixed `munera laetitiamque dii`,
  `totumque dehiscit`. REJECTED first approach (splice verses across `\n`) —
  broke `scannedFeet` index alignment, 283-line regression, reverted.
- **Rejected: h-position as a global rule.** `videt hominesne` needs det long
  (Aen 1.308), but `venit Hic` keeps nit short (Aen 1.52) — the gold is
  INCONSISTENT, so no universal "C + h makes position" rule. Added `videt` →
  `vi_det` override instead (line still fails on other words).
- **Rejected: diphthong expansion** for `malesuāda` (suā) and `alveō` (veō) —
  the engine's diphthong set is fixed (ae/au/ei/eu/oe); adding su/ve would
  corrupt ordinary words.
- **Gate: 26 failing lines remain**, all hard: multi-elision hypermeters
  (deorumque, coloremque with 2 elisions), hemistichs (`Italiam non sponte
  sequor`, `et matri praereptus amor` — not hexameters by transmission),
  Catullus structural (praeoptarit — engine can't merge prae+op; divolso —
  edition not in gold), and the quantity-corruption-risky lines (emicat
  Euryalus, Zacynthos line scans manually but not whole-file — POS-context
  dependent).

**2026-08-10 (M-013c) — hypermeter elision-completion guard, 26 → 12.**
Three engine commits, all gate-verified 0 regressions (whole-file feet dump
byte-identical except the fixed lines) + jest 38/38 each time:
- **`6c49747` — scanVerse guard + tie-break + verse-final -que merge
  (26 → 15).** Root cause of the 10 remaining -que failures: scanVerse
  rejected ANY word that completed the meter (returned to state 0) when later
  words followed — even fully-elided ones. That blocked genuine hypermeters
  where the verse-final -que elides into the next line's initial vowel
  (deorumqu' aut, nexaequ' aere). Three-part fix: (a) guard allows a completed
  meter when every trailing word is fully elided; (b) tie-break prefers the
  COMPLETE reading (ends at state 0) over a partial one at equal penalty —
  an elided verse-final -que (penalty 0) otherwise beats a real final
  syllable (also penalty 0); (c) for verse-final -que only, merge the # and V
  readings keeping the LOWEST penalty per (scansion, accent) — dedup-first
  dropped the cheap # que[S], making a real final -que impossible (Aen 5.826
  Cymodoceque). **The min-penalty merge was initially applied to ALL -que
  (incl. mid-line atque/namque), which leaked the # reading's cheap penalty
  and flipped hīc→hĭc / vāgīnā across 27 lines — scoped to verse-final only,
  mid-line keeps the pre-existing dedup (byte-identical candidates).** Gold
  overrides in the same commit: videt → vĭ-dēt (SL, the prior vi_det LS was
  WRONG — final -t before h+vowel makes no position, and gold=SL); cymodoce
  → Cȳ-mo-do-cē (LSSL); dehiscit → dĕ-hīs-cit (SLL, Aen 5.142). Overridden
  wordforms now clear isUnknown so allVowelsAmbiguous (which guesses every
  vowel combo and lets the cheapest form win) isn't layered on top.
- **`2711098` (15 → 13):** obruimur → ō-bru-i-mur (LSSL, Aen 2.411) + pater →
  pă-tēr (SL, Aen 5.521), both gold-verified.
- **`3758533` (13 → 12):** Numitor → Nu-mi-tor (SSL, Aen 6.768).
- **`05f87e3` (12 → 12 + 19 partials fixed):** verseFinalQue detection now
  skips punctuation before the newline — `-que.`/`-que,` lines were being
  misclassified as mid-line, silently reverting ~19 lines to 5-foot partials
  (incl. Aen 5.826 Cymodoceque SSDDD → SSDDDT). The gate didn't catch this
  because it only checks `feet === ''`.
- **12 remaining** (snapshot `scansion-failures-snapshot.json`): mostly
  structural — Greek names the engine can't syllabify (Euryalus LSSL,
  Zacynthos), hemistichs (Italiam non sponte sequor), Catullus edition
  variants (praeoptarit, divolso, Scamandri), and 2 Aeneid 6 lines
  (ferreique, nomen te amice). New tools: `test/brute-line.mjs` (arbitrary
  `_`/`^` forms through the automaton), `test/gold-align.mjs` +
  `test/gold-diag.mjs` (gold L/S pattern vs engine candidates).

**2026-08-10 (M-013d) — the gate under-counts: 32 hidden 5-foot partials.**
A full-corpus audit (all 5,478 verse lines; hexameter judged by
`feet.length < 6`) found the gate reports **partial scans as passing** — it
checks `feet === ''` only. **32 lines scan 5 feet of a hexameter and pass.**
~19 were the `-que.` punctuation bug (now fixed, `05f87e3`). **13 genuine
5-foot partials remain**, brute-forced with arbitrary `_`/`^` quantities:
- Fixable quantity errors (brute finds a full 6-foot solution): Nereidum
  matri (Aen 3.74), apparet Camerina (Aen 3.701), cum tacet omnis (Aen
  4.526), ductores longe (Aen 5.133), victor apud rapidum Simoenta (Aen
  5.261), scrupea tuta lacu (Aen 6.238), supplicium saevis (Cat 64.204),
  flammati Phaethontis (Cat 64.293), cum Phrygii Teucro (Cat 64.346).
- Structural / no 6-foot solution: Tune ille Aeneas (Aen 1.617), rursum ex
  diverso (Aen 3.232), sive deae (Aen 3.262), discedam explebo (Aen 6.545).
- **Corpus transcription error (not engine):** Cat 64.204 "supplicium saevis
  **ecens** anxia factis" should be **exposcens** — fix the corpus file, the
  line then has a brute solution.
- **Action:** harden the gate to treat `feet.length < 6` (hexameter) as a
  failure. That surfaces the 13 instead of hiding them; then chase the 9
  brute-fixable quantity overrides. True error rate today: 25/5,478 (0.46%),
  not the gate-reported 0.22%.

**2026-08-11 (M-013e) — the mid-line `-que` elision leak: 24 → 16.** The
root cause of SIX of the 13 hidden 5-foot partials was a spurious candidate,
not a missing quantity:
- **Bug:** the hypermeter branch offered `possibleScans(cands, 'V')` as an
  extra reading for ANY `-que`, even a MID-LINE `-que` followed by a
  consonant. That injected an empty-scansion `que[]` candidate (pen 0). The DP
  then preferred `que[]` + incomplete path over the correct complete
  hexameter, because the `complete` flag only breaks penalty TIES:
  `cum tacet omnis... pictaeque volucres`: `que[S]+volucres[SLL]` = 6ft pen1
  (complete) loses to `que[]+volucres[SSL]` = 5ft pen0 (incomplete).
- **Fix:** the extra `#/V` reading is only offered when `followingSegment ===
  'V'` (real hypermeter into the next line's vowel, or mid-line `atque`/
  `namque` before a vowel). A mid-line `-que` before a consonant cannot elide
  — no extra candidate. (`src/core/Scansion.ts`, engine `47b7e5f`.)
- **Resolved 6 lines**, two of which M-013d had misclassified as "structural /
  no 6-foot solution": `rursum ex diverso` (Aen 3.232) and `sive deae` (Aen
  3.262) are genuine complete hexameters the leak was masking.
- **3 corpus transcription errors fixed** (gold-verified against hypotactic
  per-syllable data): Cat 64.204 `ecens` → `exposcens`; Cat 64.293 `aerea` →
  `aeria` (āeriā, "airy"); Cat 64.346 missing final word `campī` restored.
  These resolve `supplicium`, `flammati Phaethontis`, `cum Phrygii Teucro`.
- **Gate hardened** (the M-013d action): `test-scansion-corpus.mjs` treats
  `feet.length === 5` (hexameter) as a failure, not just `feet === ''`. This
  surfaces 5-foot partials going forward. `regen-snapshot.mjs` mirrors the
  criteria exactly. `gold-diag.mjs` Catullus path fixed (poem 64 under
  `Catullus.Poems.poems`).
- **Result:** snapshot 24 → **16** failing lines (12 empty-foot + 4 remaining
  5-foot partials). Gate exit 0, jest 38/38, hypermeter (Aen 5.826 Cymodoce)
  still scans 6 feet. True error rate: 16/5,478 (0.29%).

**2026-08-11 (M-013f) — the completion bonus for 5-foot partials: 16 → 13.**
The DP treats "stop early" as free (0 penalty), so a 5-foot partial that
avoids phonological penalties by not finishing beats a complete 6-foot
hexameter whose real quantities (long vowels, y-synizesis) cost 1-3.
- **Fix:** `COMPLETIONBONUS = 3` in `scanVerse` — a reading ending at state 0
  gets up to one HIATUS/SYNEZIS penalty off. This prefers a genuine hexameter
  within one concession, and **does NOT force multi-corruption completions**
  (Nereidum matri: gold complete is pen6 above the cheap path, so it stays a
  correct 5-foot partial rather than completing with wrong 12-syllable
  quantities — verified, not corrupted). A hemistich has no complete path, so
  the bonus never invents completion. (Engine `17a7049`.)
- **Overrides added** (gold-verified, hypotactic per-syllable): `ilio`
  (`i_li^o^`, LSS for Aen 5.261); `euryalus`/`euryalum` gain the
  y-as-consonant 4-syllable reading (`e^u^ry^a^lu_s`, LSSL for Aen 5.337).
- **Resolved 3 of the 4 remaining five-foot partials**, all gold-consistent:
  `Tune ille Aeneas` (Aen 1.617, SSSDSS), `emicat Euryalus` (Aen 5.337,
  DDSDDS), `victor apud rapidum Simoenta` (Aen 5.261, DDSDDS).
- **Result:** snapshot 16 → **13** failing lines (12 empty-foot + 1 remaining
  5-foot partial: Nereidum matri, correctly partial). Gate exit 0, jest 38/38.

**2026-08-11 (M-013g) — corpus expansion exposed the true error rate + gold
lacuna desync. Snapshot 13 → 220 on 16,690 lines (1.32%).**
- **3× corpus expansion** (`e39b29f`): Aeneid 7-12 (5,141 hexameter lines) +
  Georgics 1-4 (2,187) + Eclogues 1-10 (830) + 47 Catullus elegiac distichs
  (650), all extracted gold-verified from hypotactic per-syllable data via
  `test/extract-gold-corpus.mjs`. The old corpus (books 1-6) reported 0.24%
  failures; the expansion surfaced a **2.2% true baseline** — later books hit
  systematic wordlist-quantity errors books 1-6 never did (Greek proper names
  like Euander/Arcades, `bijugis` clusters, common 2-syll verbs sinit/dabat).
  **Lesson: corpus breadth, not polish, sets the real error rate.**
- **Gold-lacuna automaton desync fixed** (`fba0aab`): empty verse positions in
  alternating-meter poems (Catullus 68 lines 47/142/143) broke hex/pent
  alternation — the gate filtered empty lines and `scanVerses` didn't advance
  the automaton, so ~112 of Catullus 68's failures were pentameters scanned
  against the hexameter automaton. Fix: advance automaton on empty verses +
  preserve interior empty lines (lacunae) in gate/regen.
- **M-013g override batch** (gold-verified): Euander cluster (LLL/LLS — u as
  vowel), obice/obiciunt (closed-prefix), Laride, Cisseis, Atinas, Mago,
  sinit, dabat, juvat, Thybri. 349 → 220.
- **Result:** 220 failing lines / 16,690 (1.32%), concentrated in Aeneid 10
  (29), 12 (22), 7 (17), Georgics 4 (17), 11 (15). Gate exit 0, jest 38/38.
- **Remaining 220** triaged by `test/gold-blocker.mjs` (per-line: the first
  word whose gold L/S pattern the engine can't produce). Systematic clusters
  still open: Arcades (segmenter can't make LSS), bijugis/quadrijugis
  (y-synizesis), alveo (veo), inicit/manibus. The hypotactic corpus has 28
  works (Ovid, Lucretius, Lucan, Statius...) — further expansion is one
  command (`extract-gold-corpus.mjs`) away.

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

## M-017 — Gloss artifact had a systemic L&S cross-ref verb-leak (ADJ/ADV lemmas)
**Status: FIXED** (2026-08-08, site `c291be4`).
Cold audit (4-lens panel, 2026-08-08) found L&S `main_notes` cross-refs
("amanter, adv., v. amo", "potens, v. possum") make `resolve()` recurse into the
base verb, so ADJ/ADV lemmas showed the verb INFINITIVE: `cito`→"to put in
motion" (should be "quickly"), `mortuus`→"to die" ("dead"), `potens`→"to be
able" ("powerful"), `strenuus`→"unproductive" ("vigorous"), `malus`→"an evil"
(the wordlist is 192/197 ADJ-tagged; should be "bad"), plus `rabies`,
`commodus`, `assiduus` and the N→verb class (`lator`, `debitum`, `nupta`,
`sponsa`). Measured: 89 ADV→verb + 56 ADJ→verb + 93 N→verb rows affected.
**Fix:** scoped build rule — an ADV/ADJ-dominant lemma whose L&S result is a
verb-infinitive ("to X") prefers WORDS POS-filtered (wGloss); + 24 core entries
for rule-blind cases (malus, strenuus, rabies, commodus, assiduus, calceatus,
maledictus, lator, acceptum, debitum, nupta, sponsa, discepto, mansuetus, + 10
adverbs). Blanket WORDS-first REJECTED (regressed memor/superus/saevus/certo,
golden-locked). **Residue (accepted):** ~100 rare participles still verb-glossed
(WORDS POS-null). golden 1783→1794; census 341/341; `npm test` + e2e green.

## M-018 — Corpus read-through audit found 8 systematic gloss-extraction patterns
**Status: FIXED** (2026-08-08, sites `5c515f2`..`74fb466`).
A subagent read 6,716 L&S entries in bulk (dense D+M + stride-all) and compared
raw senses vs the artifact, surfacing 8 patterns grep-hunting would have missed:
- **P1** `de Or` strip matched "de or" mid-word (`declino`→"to turn asi"). Fixed
  with `\bde` + required separator.
- **P2** compact L&S primaries scored 0 (abstract-run first tokens, single-cap
  primary rejection, un-stripped "freq. and class." parens, that/those openers).
  Fixed isGlossRun suffixes + capital-accept (was dead code — toks lowercased
  first), usable() single-cap relax, paren-note + bare "(class.)" strip,
  WEAK_OPEN that/those/this. divinitas "Godhead, divinity", dulcis "Sweet",
  mucidus "Mouldy, musty", magnitudo "Greatness, size, bulk, magnitude",
  discordia, mamma.
- **P3** Latin-quote clauses ("an quod te imperator consulit") won via article
  STRONG_OPEN. Hard gate: article-opened + 0-enCount + ≥3 non-English tokens.
- **P4** text-critical editor notes ("the best reading is", "the form discribo")
  gated. declinatus "inflection...", meio "urinate, make water".
- **P5** lowercase-key proper-noun collisions: musa "a Muse", murena "a moray
  eel", tyrius, trivia, dis "rich", minor "less", dido. 12 core entries.
- **P6** citation author lists extended (Lampr, Ambros, Val, Macr, Nep, Aus,
  Flor, Hier, Cassiod, Sid, Pall) + book-part residue (". de Tob", ". adv",
  ". Coel. Aur"). 47→0 residue.
- **P7** etymology/myth-note clauses ("a nymph who was changed") — mitigated by
  P2 primary recognition; residual few left.
- **P8** common V/N lemmas fell to "—" (L&S orthography-heavy + WORDS
  non-unique). WORDS-first fallback rescued +976 lemmas (adlevo "lift/raise",
  adpello "call (upon)"). The audit's differo/diffido/dissilio are NOT wordlist
  lemmas — nothing to show.
- Relative-clause gloss guard ("she who rules") + ETYM language markers
  (Osc./Goth./O.H.Germ.) + era-note sync (paren "class." no double-bonus) + 3
  straggler core entries (superbus, domina, deformitas).
golden 1881→1896, census 341→348, artifact 32,748→33,679 lemmas. All exit 0.

## M-019 — 4-expert audit panel found systematic homograph + coverage defects (M-005)
**Status: FIXED** (2026-08-08, sites `7b82f7d`..`17133fb`).
A 4-expert panel (classicist/product/architect/data) audited the post-M-018
artifact and returned 3 FAIL + 1 conditional-pass. All 8 concrete architect bugs
+ the data audit's homograph/core/coverage findings fixed:
- **H1 accent-signature homograph detection**: `isSpurious()` conflated distinct
  homographs sharing a paradigm (levo2, plaga2/3, labrum2, specula2, pila3,
  striga2, utriculus2, molitor2, rapina2, viripotens2). formSets now keys by
  form+accented-form (field 4) — distinct vowel length = distinct word.
- **H2 literal/etym primary verbs** (verto, vexo, orno, crucio, crepo, accuso,
  contemno, solvo, exigo, provideo, exspecto, contamino) curated in core.
- **H3 opp./v.X cross-ref tails**: ", opp. X" (levis2 was MISSING) + ", v. X"
  (diva "A goddess, v. divus") stripped in cleanOne.
- **H4 ?-gloss acceptance + short citation tails**: qui2 (interrogative) was
  MISSING; Inscr./R.R./Vitr./init/med/al citation tails stripped.
- **H5 participle coverage**: cross-ref recursion handles fr./from (+ POS-skip
  fixes abscido's "v. a. caedo"→caedo), wAdjFirst fallback, verb-leak guard
  extended. diligens, corruptus, demissus, serius, laudatus, confertus, + core
  for WORDS-ADJ-less participles. +208 lemmas.
- **H6 unassimilated-prefix coverage + core contradictions**: adfacio→afficio,
  inpleo→impleo, obfero→offero, disfero→differo, etc. (compound normalization
  table); castus2 (noun "chastity" not adj "pure"), litus2 ("a smearing").
- **H7 homograph regression tests**: 14 golden rows + golden-runner cache fixed
  to accent signature.
- **Common-word curation**: castra, sacerdos, facilis, celer, appello, dominus,
  exercitus2, taurus, tribunus, recens (broken/narrow senses).
golden 1910→1941, census 348/348, artifact 33,678→33,958 lemmas, L&S 83.3% /
WORDS 9.2% / none 7.6%. All exit 0 + e2e green.

## M-020 — Architect re-audit + advisory panel on homograph detection (M-005)
**Status: FIXED** (2026-08-08/09, sites `daaa36d`..`55417ba`).
The M-019 architect re-audit stalled mid-run, but its transcript (recovered from
the subagent JSONL) found a regression in H1's accent-signature `isSpurious`:
genuinely-distinct homographs with identical forms AND accents (testis2
"testicle" vs testis "witness", carmen2 "wool-card" vs carmen "song") were
wrongly collapsed to the bare twin (~21 lemmas, 96 total lose a distinct sense).
**Fix:** `isSpurious` now requires BOTH signatures — form+accent AND form+tag —
to match the bare twin. Form+tag alone regressed levo2; form+accent alone
regressed testis2; the intersection captures every available signal. The
golden-runner cache stores both (forms + formsTag).
**Advisory panel** (2026-08-08, 3 experts) on the remaining 90 unresolvable
homographs (byte-identical on all three signatures AND row count — Perseus
duplicates the full paradigm per page-split, so row count is NOT a frequency
signal). Key finding: L&S numbers the PRIMARY word -1 and rarer secondary -2,
so the COMMON sense is often the NUMBERED entry (osculo2 "to kiss" vs osculo1
"supply with a mouth"; comparo2 "make ready"; luo2 "pay/atone"). The artifact
was showing the rare bare-twin gloss for these common words. **Fixed:** 17 core
entries (animosus2 bold, aveo2 fare-well, comparo2 make-ready, deformo2 deform,
luo2 pay, jugis2 perennial, patrius2 native, pila2 pillar, satyricus2 satiric,
pediculus2 louse + protector acceptor2/osculo2/ravus2/paro2/excretus2/
incitus2/inclinis2); stale paro2 golden updated (panel confirmed paro2 is a
distinct word "make equal", root par). ~71 rare/antiquarian pairs left
uncurated — the panel saw no user value (fish-names, citation-only homographs).
golden 1944→1960, census 348/348. All exit 0 + e2e green.

## M-021 — Frequency-stratified re-audit found L&S literal/passive disease (M-005)
**Status: FIXED** (2026-08-09, sites `77e7ed3` + `49e5cf5`). The wordform-count
holdouts structurally missed wrong glosses; a frequency-stratified sweep found
the residual ~8% error concentrated in the top stratum: L&S opens entries with
the literal/etymological sense (neco→"drown", impetro→"accomplish" calque,
attendo→"stretch a bow", veho→passive "be carried"). Two-part fix:
- **`77e7ed3`**: apud/Doed citation-tail strip (cleared 31 fragment glosses) +
  20 curated core overrides (homeo-/verb-leaks, homograph twins). golden→1960.
- **`49e5cf5` (M-021c)**: an **LLM everyday-gloss layer** (`utils/llm_glosses.tsv`,
  5,916 lemmas, freq≥30) generated via free offline poolside batch, audited,
  applied between core_gloss and L&S for non-golden/non-core lemmas only. Fixed
  the literal/passive disease across the readable stratum: neco→"to kill",
  sperno→"to despise", misceo→"to mix", capio→"to take", levo2→"to smooth"
  (homograph preserved), servo→"to save". none-rate 7.5%→5.6%, total→94.4%.
golden→1981, census 348/348, npm test + e2e green.

**OPEN — golden-covered lemmas still show L&S literal** (veho→"be carried",
invenio→"find"): the golden gate checks exact L&S substrings, so re-baselining
the 193 golden-covered top lemmas to the LLM's correct-but-differently-worded
gloss needs a semantic synonym-bucket re-key (not substring), authored from the
headword meaning and never from the LLM output (else rubber stamp).

**OPEN — ~70 audited-but-skipped BAD glosses**: the LLM audit flagged 238
candidates (~12%), ~half false positives (auditor wrongly rejects pareo=obey,
prefers synonyms). Applied only the objective fixes (conjugated slips, broken
strings); the ~70 genuinely-wrong remainder (invented nuance, homograph
conflation) sit as review candidates in `tmp/_llm_audit_out.json`.

**FIXED (2026-08-09, sites `533da9d` + `6d17ec6`, M-021d/e)** — full-artifact
LLM batch audit (34,335 words, stepfun flash batch-40 retry-on-incomplete,
~3h) + fixes:
- **1688 of 2794 audit1 flags now pass audit2.** wrong-POS 613→107,
  truncated 294→18, garbled 112→1.
- Parser gates: `fr.`/`from` in etymology notes no longer recurses into the
  base verb (acetum→"vinegar"); noun-dominant lemma with verb cross-ref
  prefers WORDS-noun (actum→"act, deed", argentaria→"bank").
- LLM-layer: 149 wrong-POS + 170 wrong-meaning + 601 generated everyday
  glosses merged into `llm_glosses.tsv` (now 7,996 entries).
- Core: 22 flagged entries verified vs L&S; **4 real fixes** (deflagro,
  aspalathus, phlegraeus, naubolides), 18 reverted (auditor wrong on
  mythological/proper-noun entries). golden→1989, census 348/348, npm test
  + e2e green.
- **Key evidence — auditor is an UNSTABLE filter**: a second audit run
  flagged 3084 words (2794 first); only **1106 overlap**. Single-run flag
  counts are meaningless; use the intersection. The 1106 persistent are
  definite defects, largely semantic (alii→garlic vs "others", adoperio→
  "uncover" vs "cover up", aedilis truncated).

**OPEN — 1106 persistent defects (both audits agree)** — the reliable
remaining target, mostly L&S/WORDS semantic: wrong homograph (alii→garlic),
opposite meanings (adoperio→uncover), declined-forms-as-lemmas (alia→"native
of Elis"), truncated tails (adonia, aedilis). Verdicts in
`tmp/_audit2_out.json`. Fix via LLM-corrections in `llm_glosses.tsv` with an
L&S-agreement gate (the 1978 audit2-only flags are largely auditor noise —
do not chase them).

**OPEN — golden-covered lemmas still show L&S literal** (unchanged, see above).

## M-022 — Gemini full-artifact audit trilogy (2026-08-10) ✅

Three waves closing the 34,338-lemma artifact audit (commits a00e915, fc8aa81,
45effbe, f89811a):

- **W1 (690 triple-agreed)** — all 3 audits (2× stepfun + Gemini) agreed wrong:
  fixed all 690. 666 non-numbered context-grounded corrections into
  `llm_glosses.tsv`; 24 numbered homographs REMOVED from llm layer → L&S
  numbered key authoritative (auditor cross-suggests the bare twin); 3 core
  fixes golden-locked (pone "behind, after", rutulus "a Rutulian", alia
  "otherwise").
- **W2 (1281 Gemini-only)** — 1209 non-numbered corrections applied, 72
  numbered skipped/removed. Exposed the SYSTEMIC wrong-POS defect → POS guard
  in `build_glosses.cjs` (ADJ/ADV lemma never gets "to X" from llm layer)
  fixed 104 artifact-wide in one shot; 71 ethnic/geographic adjectives whose
  only gloss was the wrong verb regenerated ("Achaean", "Arabian", "Ithacan").
- **W3 (396 stepfun-both-not-Gemini)** — Gemini's 69% recall missed these; 388
  corrections applied; 8 reverted after L&S check (auditor was wrong on
  cholera/heius/pausea/immunitus/sutela/fibrinus/mantice/spurium).
- **Closure re-audit (M-022d)** — full Gemini re-run of the FIXED artifact:
  1723 flags (was 3145, −45%); 2086/2286 fix targets now clean (91%);
  11 confirmed regressions reverted (inopinor, stellatura, tabulinum,
  immundo, salax, memorialis, reliquus, incolumis, puter, largus,
  nonigesimus).
- **Two-family intersection closure (M-022e…m)** — a fresh stepfun run over the
  FIXED artifact (859 batches, ~6h, thinking budget 1000) produced 1336 flags;
  intersection with the Gemini re-audit = **460 lemmas**. Processed to zero:
  432/432 non-numbered (137 L&S-confirmed + 18 + 62 + 27 + 9 + 32 adverb-POS +
  268 audit-reason-grounded, minus 7 reverted after L&S contradiction), 28
  numbered left to L&S. **Key finding: the two-family intersection is still
  ~80% FP** — both models share the wrong-POS / twin-sense / truncation-FP
  errors, so agreement is NOT independent confirmation; only the L&S-primary
  cross-check is the verdict. The adverb-POS class (32 lemmas: velociter
  "swift"→"swiftly") was invisible to word-overlap filters because L&S adverbs
  open with "Fin." — caught via wordlist-POS instead.

**Status: FIXED** — M-022 gloss track closed. Full artifact 34,338 lemmas /
448 KB gz, L&S 89.8%, llm layer 10,081 entries. Tests 1992 golden + 348 census
green. Three-family audit + closure re-audit + full two-family intersection all
processed; remaining flags are numbered homographs (L&S authoritative) or
two-family-shared FP. Further passes chase model noise — the gloss track is at
its plateau.

**Pipeline lesson** (M-022a…m): every LLM fix wave must close with a full
re-audit of the FIXED artifact + L&S primary cross-check on all changes;
intersection-of-families is a filter, never a verdict.

## M-023 — Numbered-homograph hole in the LLM layer (2026-08-11) ✅

**Symptom.** The llm everyday-gloss layer (`utils/llm_glosses.tsv`) carried 236
numbered-homograph keys, and `resolve()` returns the llm gloss for a numbered
lemma before the L&S/WORDS path. Since the llm layer has no POS/numbering
signal, numbered entries were systematically corrupt: `manlius2`→"to manage
affairs competently" (proper-noun Manlius), `araneus2`→"to be spider-like",
`cujus2`→"of whom or whose" (not a gloss), `pilus2`→"a new word, primipilus...
was formed)" (citation fragment), `cillo2`→"sodomite" (L&S cillo2 empty →
WORDS noise), `convector2`→"the deity..." (sense of convector1, not the
fellow-passenger of convector2), `uber2`→"cf. ibid. II. C.], rich..." (crossref
fragment), `adeo2`→"who restrained his anger so little that" (citation).

**Root cause.** The memory rule "numbered → L&S authoritative, never generate
for them" was enforced only at the *audit* layer; the llm *layer itself* was
never stripped. Also, the wordlist (Morpheus/Perseus) and L&S number homographs
independently, so a numbered L&S key is NOT the wordlist's numbered sense
(`porus2` wordlist "a pore" = L&S `porus1`; L&S `porus2` is "tufa"). And ~93
numbered wordlist lemmas are unassimilated compound verbs with no L&S/WORDS
sense at all (abcedo2, adfrigo2, conpario2, inmoror2...).

**Fix.**
1. Stripped all 236 numbered keys from `llm_glosses.tsv` — the llm layer now
   covers bare lemmas only.
2. 18 numbered core overrides + 6 restored-numbered (porus2 "a pore",
   praes2 "at hand", varicus2 "straddling", tropa2 "turning", disvulgo2,
   inmoror2) in `utils/core_gloss.json` (now 1943 entries) — each with a
   golden row (now 2016).
3. Left the ~93 unassimilated compound verbs to fall through to "—" (no gloss
   beats a hallucination).

**Result.** Artifact 34,342 lemmas / 448 KB / L&S 89.7% (from 34,338 / 89.8% —
net L&S share essentially flat, corruption removed). Tests: 22 unit + 81 IPA +
2016 golden + 348 census, all green. One numbered gap remains by design:
numbered homographs whose signatures differ from the bare twin and whose L&S
numbered sense is the wrong (rarer/etymological) one need a core override, not
a parse-rule change — that's a curation tail, not a bug.

## M-023b — Caesar BG 1.1 stress test re-run (2026-08-11) ✅

Re-ran the real-text quality gate (the Caesar passage) after M-023. Three
real gloss defects found and fixed:

1. **garumna → "—"** (MISSING). L&S has it ("a river of Gaul, the Garonne"),
   but senses[0] opens with a gender+author+book fragment ("Fem., Aus. Mos.
   483), = ... Strab., a river of Gaul") that masks the gloss and trips the
   gates. Only 1 such wordlist entry exists (garumna); core override added
   + golden. (Amisia "the Ems" is the same shape but not in the wordlist.)
2. **longe/longissime ("far") → "Long, stretched out"** (adjective). Wordlist
   lemmatizes the adverb forms under `longus`. Core override on `longus`
   ("long, tall; far, at a distance") covers the adverb forms too. A core key
   on `longe` would be dead — no such lemma exists.
3. **differunt ("they differ") → "to carry away, remove"** (literal disfero).
   Everyday sense is WORDS's "differ, disagree". Core override `disfero`.

Non-gloss gaps (lemmatization, out of scope): `quod`→qui (conjunction
"because" vs pronoun), `matrona`→"married woman" (river vs common noun),
`minimeque`/`proximique` (enclitic -que, Morpheus-rescued).

**Status: FIXED.** Artifact 34,343 lemmas / 448 KB / L&S 89.7%. Golden 2020 /
census 348 / 22 unit / 81 IPA, all green.

## M-023c — Full Bellum Gallicum I stress test (2026-08-11) ✅

Ran the ENTIRE Caesar BG 1 (8186 tokens, 1929 unique lemmas) through the
popup lemma path (form → wordlist lemma → artifact gloss). Two structural
finds + one score-table fix + coverage tail:

1. **Proper-noun case mismatch (390 lemmas affected).** Wordlist keys proper
   nouns lowercase, L&S Capitalized. `lsByCapitalized()` fallback + `lsByOrig`
   original-case map recovered +20 proper-noun lemmas (harudes, leuci, leucus,
   hermandica, querquedula, ostrya, pagurus, regaliolus...).
2. **`perh` in GRAMMAR_ABBR was a −4 penalty that killed proper-noun glosses.**
   "A Germanic tribe in the army of Ariovistus, perh. the same as the
   Charudes..." scored +3 −4 = −1; the citation tail "1, 51, 2 Monum" (score
   0) won by tiebreak → harudes MISSING. Removed `perh` from GRAMMAR_ABBR
   (it's a frequency hedge, not a grammar note). +~20 lemmas, 2 regressions
   (laquearius, olivarius) → core overrides.
3. **Unassimilated compound table extended**: deedo→desum, interedo→intersum,
   praeedo→praesum.
4. **Adverb/particle core overrides**: commode, dubium, necne, neve, plerusque,
   tanto, stipendiarius (wordlist lemma = wordform; L&S opens with usage-notes).
5. **Tribal proper-noun core overrides**: rauracum, rauracis, tolosates, norici,
   lingonus.

**Status: FIXED.** 1926/1929 lemmas glossed (99.8%). Last 3 (ide→idem,
jamque→jam, pleraque→plerusque) are Morpheus-rescued forms whose lemmas are
glossed in the artifact — the popup resolves them. Artifact 34,379 lemmas /
449 KB / L&S 89.7%. Tests: 22 unit + 81 IPA + 2034 golden + 348 census green.

## M-023d — Cross-author stress tests: Cicero, Vergil, Ovid (2026-08-11) ✅

Extended the Caesar BG 1 stress gate to 3 more full texts (Cicero In Catilinam
I, Vergil Aeneid I, Ovid Metamorphoses I), all through the popup lemma path.

Coverage: Caesar 99.8%, Cicero 99.4%, Vergil 98.6%, Ovid 99.4%. Total ~21k
tokens / 7,941 unique lemmas.

Fixes:
- **Unassimilated TABLE** (+14 mappings): adsedeo→assideo, confor→confero,
  exlapso→elabor, quaestiono→quaestio, nemen→nemo, exduco→educo, extulo→
  effero, adforo→affor, inrego→irrigo, introgradior→introgredior, perfor→
  perfero, baco→bacatus, distulo→differo, obstupeo→stupeo, subcubo→subcumbo,
  transsum→transeo.
- **Core overrides** (+14): commode, dubium, necne, neve, plerusque, tanto,
  stipendiarius, simila, totiens, ecquis, quodam (Cicero); dehinc, venatrix,
  miserabile, opos (Vergil); semideus, priores, pyrrhe + proper nouns pyrrha,
  erinys, latonia, latonius, scythia, parnasius, maenala, phoce, lerne (Ovid).
- **Vergil proper-noun case mismatch** confirmed the lsByCapitalized() fix
  from M-023c; remaining Vergil misses are patronymics L&S keys under another
  lemma (Helena/helene, Idalium/idalia) — lexicographic, not gloss bugs.

Remaining misses per text are mytho-geographical patronymics (no L&S entry)
and Morpheus-rescued forms whose lemmas ARE glossed (ide→idem, jamque→jam).

**Status: FIXED.** Artifact 34,412 lemmas / 450 KB / L&S 89.8%. Golden 2051 /
census 348 / 22 unit / 81 IPA, all green.

## M-023e — Full-artifact defect scan + LLM-layer artifact cleanup (2026-08-11) ✅

Ran targeted scans over ALL 34k artifact glosses, not just the stress-test
samples. Found and fixed:

1. **LLM-layer `</think>`/`<tool_call>` tokens leaked into gloss VALUES (10
   entries).** acte, adjaceo, concupisco, condico, fuco, futurus, piger,
   quintus, torquatus, unctus had reasoning output inside the gloss ("to
   paint or dye</think>To color..."). Stripped everything after the artifact
   marker at the data layer (55 llm entries cleaned total). Invisible to
   cross-author stress tests — only a whole-artifact token scan catches it.
2. **L&S parenthetical Latin examples survived extraction (2):** coma
   "(hence barba comaeque, M. 7, 288)", sphaera "(pure Lat. globus. N. D.
   2, 18, 47)" → core overrides "the hair of the head" / "a ball, globe,
   sphere".
3. **L&S senses[1+] beating senses[0] on score + fragment tail (2):** altanus
   "the sea winds were so called quod ab alto spirant)" → "a south-southwest
   wind"; statarius "...Heaut. prol. 36 sq." → "stationary, standing firm".
4. **Dangling-comma tail (1):** armus "the fore quarter , and" → "the
   shoulder, fore quarter".

Full-artifact heuristics also confirmed non-issues: "a kind of X" species
glosses, relative-clause proper-noun glosses, and [~ dare => destroy] WORDS
metaphor notation are all legitimate.

**Status: FIXED.** Artifact 34,412 lemmas / 449 KB / L&S 89.8%. Tests:
22 unit + 81 IPA + 2056 golden + 348 census, all green.

## M-023f — isSpurious homograph guard + full-artifact numbered audit (2026-08-11) ✅

**Symptom.** 94 numbered wordlist lemmas were glossed with their BARE twin's
sense instead of their own L&S homograph sense. isSpurious() collapsed mora2
(the echeneis fish) to mora (a delay), labes2 (a stain) to labes (a fall),
munificus2 (on duty) to munificus (bountiful), olor2 (a smell) to olor (a
swan), carmen2 (a card) to carmen (a prophecy). The dual-signature test
(form+accent AND form+tag matching the bare twin) can't distinguish identical-
form homographs from true duplicates.

**Fix.** Added a homograph guard at the top of isSpurious(): if the L&S
NUMBERED key (mora2) has its own senses, the lemma is a real homograph — never
spurious. Falls through to the dual-signature test only when L&S has no
numbered key (true duplicates like paro2). 327 numbered glosses changed; all
regression cases (testis2, levo2, populus2, paro2) preserved.

Also fixed from the audit: core['acer'] mixed both homographs (now "sharp,
keen, piercing"); added core['altus']="high, deep, lofty" (WORDS had given a
nonsense gloss); aenus3/fabrefacio fragment tails (parser picked the Lit.
secondary) → core.

**Status: FIXED.** Artifact 34,411 lemmas / 450 KB / L&S 89.8%. Tests: 22 unit
+ 81 IPA + 2066 golden + 348 census, all green. ~310 numbered homographs now
carry their own sense.

## M-023f.2 — post-guard verification: infucatus2 (2026-08-11) ✅

After the homograph guard, verified all 94 restored numbered homographs
against L&S. One residual wrong: infucatus2 (wordlist homograph) got "colored"
(from infucatus1/fuco) instead of L&S infucatus2 = "not painted (late Lat.)".
The guard let it through (numbered key has own senses) but the L&S sense
extraction for infucatus2 (gated by the "(late Lat.)" era note) returned null,
so it fell back. Core override added.

Common-numbered-lemma sanity: 0 common numbered homographs (corpus freq ≥2) now
carry a rare/obscure sense — the guard correctly routes every frequent word to
its everyday meaning.

**Status: FIXED.** Golden 2067 / census 348 / 22 unit / 81 IPA, all green.
