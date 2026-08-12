# Lessons

Date-stamped, append-only notes of non-obvious gotchas that cost real debugging
time. The one-line versions live in `CLAUDE.md` (loaded every session); this
file keeps the detail.

## 2026-08-07 — M-005 dictionary-gloss pipeline

- **`fetchAsset(path)` always appends `.gz`.** Calling `fetchAsset('macronizer/glosses')`
  fetches `macronizer/glosses.gz` (nonexistent) then falls back to a plain
  fetch of `macronizer/glosses` (also nonexistent). The file is
  `glosses.tsv.gz`, so the argument must be the **`.tsv` base name**:
  `fetchAsset('macronizer/glosses.tsv')`. Caught only by the e2e test showing
  all-glosses-as-`—`. (`macronizer.html` gloss loader.)
- **The popup gloss lookup must be EXACT-KEY-FIRST.** Stripping the homograph
  number before lookup makes `populus2`→"the people" (should be "poplar"),
  silently defeating the whole feature. Exact key (`populus2`) first, bare key
  only as fallback. (`glossFor` in `macronizer.html`.)
- **Case-collision: wordlist "Alius" = the pronoun "other", capitalized.**
  It collides with L&S's proper-noun `Alius1` ("native of Elis"), so `resolve`
  returned "a native of Elis" for *aliam/alii*. Guard: when a capitalized
  wordlist lemma's L&S homograph-1 is itself a capitalized proper noun AND a
  numbered sibling exists, resolve the sibling. (`numberedSibling` in
  `build_glosses.cjs`.)
- **Quantifier/interrogative openers need word-boundary, not `\s`.** "All,
  every" is `all\b` — `all\s` fails because the comma intervenes. STRONG_OPEN
  uses `\b` for `all/every/each/another/who/which/what/...`.
- **Usage notes score as definitions unless penalized.** "The rel. freq. agrees
  with the foll. word" and "the neutr. plur. omnia is often closely connected"
  open with "the" (+3). Penalize grammar-abbrev density (neutr/plur/rel/foll/
  subst/interrog...) by −4, and a bare author name glued to a clause end by −4.
- **Era preference on the RAW clause, not the cleaned one.** `cleanOne` strips
  "(late Lat.)", so the era check must run on the pre-clean clause: `(class)` +1,
  `(late|post-Aug|ante-class|arch)` −1. This is why `incolo`→"to cultivate"
  (late Lat.) was beating "to inhabit" (class.).
- **Primary-first needs both a strong-score pass and a terse pass.** A deep
  translated example ("a te, qui nobis omnia summa tribuis") can out-score the
  primary "All, every" on verb-bonus. Fix: among the first 3 flattened senses,
  prefer a short (≤80 chars) clean gloss scoring ≥3; else fall back to the full
  argmax. Raising the terse threshold from ≥2 to ≥3 fixed `venio` regressing to
  a 37-char example.
- **"Engl. else], another, other" — definitions follow a closing bracket.** The
  clause-splitter needs a bracket-close split (`]\s*,?\s+(?=a|an|the|one|who|
  which|what|to|another|other)`) to reach `alius2`'s real gloss, buried after
  the etymology bracket.
- **`.replace()` without `/g` only replaces the FIRST match.** The probe/harness
  strip of `const (fs|path|zlib|engine) = require(...)` lines silently left
  later ones, causing "Identifier already declared" — until `/gm` was added.

## 2026-08-08 — M-005 gate-then-rank restructure + Aeneid stress test

- **The "99.1% usable" holdout could not see `terra`→"the sea".** It measured
  *fragment-ness* (well-formed English) on an unstratified 120-row sample; "the
  sea" is perfect English. The Aeneid 1.1–11 stress test (a different register
  than Caesar prose) found 11 wrong common-word glosses. Lesson: audit
  correctness (does the gloss MEAN the lemma?) not well-formedness, and sample
  by frequency — the top-1000 words are what users actually hover.
- **Whack-a-mole ⇒ decouple detection from selection.** Fusing "is this a
  usable gloss?" and "which is primary?" into one score + surface tiebreaks
  (comma-count, shorter, runTokens) traded one failure class for another ~30
  times this session. The fix: hard per-clause REJECTION gates (fragments,
  citations, usage-notes, pure-Latin) that remove candidates before ranking,
  then rank by score → latinCount → sense-order → runTokens → shorter.
  Rejection is monotone (only removes candidates); position is fixed. The
  golden suite (`utils/gloss_golden.json`, 75 rows) is the anti-whack-a-mole:
  grow it per-fix, same commit.
- **`latToks` lowercased proper nouns before the capitalization check.**
  `Senones`/`Euryalus`/`Venus` became `senones`/`euryalus`/`venus`, matched
  Latin inflections (-es/-us), and tripped the pure-Latin reject — nulling
  ~171 proper-noun glosses. This directly contradicted `latinCount` (which
  skips capitalized words). Fix: check capitalization BEFORE lowercasing.
  Cost a whole council round to diagnose.
- **The Latin-tail truncation cut gloss SYNONYMS, not just examples.** The
  strip fired on any Latin-looking word followed by more text, so "Easily
  broken, or crumbled to pieces, friable" → "Easily broken, or crumbled to"
  and "One who flees or runs away" → "One who". Fix: only truncate when a
  LATIN word (not more English gloss) follows the Latin-looking one.
- **"perh." is a frequency hedge, NOT a late/rare marker.** The era penalty
  `(late|post-Aug|ante-class|arch|very rare|perh.)` −3 demoted the classical
  primary of `dignitas` — "(so, rarely, and perh. only in Cic.)" — below a
  marginal clause. Remove `perh.` from the era regex.
- **The gloss build was 17× redundant.** 673k `(lemma|tag)` rows over ~40k
  unique lemmas, and `resolve()` is pure per lemma. Memoize by the EXACT lemma
  string (case-sensitive — the collision guard keys `Gallia` ≠ `gallia`):
  841s → 50s, byte-identical artifact. WORDS `parseWord` is cheap (0.6ms); the
  L&S resolve was the cost.
- **The gloss "top-1000 common words" was ranked by WORDFORM COUNT — the wrong
  proxy.** 2026-08-08: a hand-curated 79-word top-frequency check exposed the
  function-word/closed-class stratum as ~40% WRONG (`autem`→"the parent of all
  evil", `et`→"used for et ... et", `sum`→"to pass, elapse"), while every prior
  audit claimed "99.1% usable." Root cause of the blind spot: wordform count is
  ANTI-correlated with text frequency — `et`/`in`/`cum` carry 1–6 wordforms and
  rank ~30k of 40k lemmas, so "top-1000 most-attested" samples were all content
  words. Measure by corpus frequency (exposure), not morphological richness. The
  fix added `utils/gloss_census.cjs` (241 frequency-stratified rows, wired into
  `npm test` + CI) so this stratum can never hide again.
- **L&S numbers the RARE homograph as `-1` for many common words.** `caelum1`=
  chisel (sky is caelum2), `lego1`=bequeath (read is lego2), `dico1`=dedicate
  (say is dico2), `frons1`=leaf (brow is frons2). The extractor's base1 fallback
  therefore picks the wrong word. This generalizes the `appello` problem: the
  closed class + homograph-inverted words are INHERENTLY a curated-table problem
  — no scoring rule deduces "and"/"but"/"to be"/"sky" from data that never says
  it. Fix: `utils/core_gloss.json` (262 hand-curated entries) applied pre-resolve.
- **"Curate vs rule" line for gloss fixes:** fixable-by-rule = the gloss EXISTS in
  L&S and only loses on score/floor/steering (cum, in, autem, mons — EN_WORDS gap
  or steering); must-curate = the gloss does NOT exist in L&S (et, sed, sum, deus,
  mare — usage-notes/etymology only). Whitaker's WORDS first-result (frequency-
  ordered) is a pre-curated fallback that covers most of the closed class; a small
  core table covers where WORDS itself is imperfect (enim→"for", cis→"this side").
- **The `class.` era bonus (+1) and enCount suffix expansion look safe but are
  NOT — they regressed golden content words.** `curro` ("to move quickly, to
  hasten" beat "To run" after `-ly` counted as English) and `impedio` (era=0
  removed the tie that let the earlier "To entangle, embarrass (class.)" win).
  The golden suite caught both in seconds. Lesson: gate-then-rank's scoring
  function is tightly tuned; don't touch it to fix a stratum a curated table
  handles more safely.
- **The 2026-08-08 M-005 fix is precedent that a bounded curated override IS
  principled, not whack-a-mole:** the closed class is finite (~262 entries covers
  it), it's exactly where curated knowledge is irreplaceable, and it's the same
  decision already made for `appello`. Every core entry gets a golden row in the
  same commit (monotone rule).
- **A script inside `utils/` that `require`s a data file must use a path relative
  to the script, not the repo root — and a node -e heredoc with apostrophes breaks
  silently.** 2026-08-08: `_add_weather.cjs` (in `utils/`) did `require("./utils/
  core_gloss.json")` (wrong, module-relative) but `fs.writeFileSync("core_gloss.json")`
  (cwd-relative) — the fixes landed in a stray REPO-ROOT `core_gloss.json`, the
  real `utils/core_gloss.json` never changed, and a later script overwrote the
  stray. Cost an entire curation round before a count-mismatch exposed it. Fix:
  absolute paths in throwaway scripts, and ALWAYS verify a fix reached the artifact
  (rebuild + grep the lemma), not just that core_gloss.json changed.
- **The golden suite's `evalExpect` normalized `got` (stripped trailing punctuation)
  but compared against the RAW `contains` string.** Proper-noun glosses ending
  "B.C." always failed: norm("...b.c.")→"b.c" vs raw "b.c.". Fix: norm BOTH sides.
  This is why "contains" and "startsWith" must go through the same normalization.
- **Curation at scale is bounded and monotone.** 14 rounds (2026-08-08) grew
  core_gloss 262 → 1587 entries and the golden suite 75 → 1651 rows, all green,
  artifact size FIXED at ~464 KB (curated entries replace verbose L&S narratives).
  The class is finite — each semantic area (function words, homographs, verbs,
  nouns, adjectives, proper nouns, buildings, body parts, weather, abstract,
  legal, military) adds a bounded batch; the golden+census gates lock every fix.
  This is the "principled not whack-a-mole" precedent, scaled.
- **L&S `main_notes` cross-refs leak the base verb's INFINITIVE onto ADJ/ADV lemmas.**
  Cold audit (2026-08-08): L&S stores adverbs/participles as main_notes pointing
  at the base verb ("amanter, adv., v. amo", "potens, v. possum", "mortuus, v.
  morior"); resolve()'s cross-ref recursion then returns the verb gloss, so
  cito→"to put in motion" (should be "quickly"), mortuus→"to die" ("dead"),
  potens→"to be able" ("powerful"), malus→"an evil" (the wordlist is 192/197
  ADJ-tagged → "bad"). Fixed with a SCOPED build rule: an ADV/ADJ-dominant lemma
  whose L&S result is a verb-infinitive ("to X") prefers WORDS POS-filtered
  (wGloss). Scoping matters — a blanket WORDS-first regresses memor/superus/
  saevus/certo (real adjective glosses, golden-locked). ✅ enforced by the golden
  suite (malus/cito/potens/mortuus rows) + the "to X" guard in build_glosses.cjs.
- **4 cold-audit subagents: 3 produced EMPTY transcripts and silently did nothing.**
  2026-08-08: launched a 4-lens panel (classicist/measurement/bug-hunter/architect)
  in background; an hour later 3 of 4 were 0 bytes (stalled at launch, no error),
  only the bug-hunter ran (69 probes, then went quiet mid-report). Lesson: a
  background subagent panel is not reliable — verify each transcript grew, and
  treat the run as best-effort. The useful cold audit was done INLINE (direct
  node probes by the parent) which found MORE than the one surviving subagent.
  The bug-hunter's half-written transcript was still recoverable (parse its
  .output JSONL for tool_use results + assistant text) and gave the systemic class.

## Corpus read-through beats grep-hunting for systematic errors (2026-08-08, M-018)
The 4-lens cold audit of 2026-08-08 stalled (3/4 empty transcripts) and only
surfaced ONE pattern (the cross-ref verb-leak). The follow-up that actually
worked was a **single subagent told to READ the L&S corpus in bulk and let
patterns emerge** — no grep for suspected patterns. It read 6,716 entries (dense
D+M + stride-all-26) and found **8 systematic classes** my grep probes missed:
the `de Or` mid-word truncation (my own in-progress fix was BROKEN and it caught
it), abstract-run primary scoring, Latin-quote rescue, text-critical notes,
proper-noun collisions, citation residue, etymology fragments, and missing
common verbs.
- **Prompt it with a coverage strategy and a file-deliverable**: "dense pass
  over 2 full letter files + stride every Nth across all 26; write the report to
  disk BEFORE finishing (a stalled agent must not lose it)". The report landed
  even though prior agents went silent.
- **Tell it what's already fixed** so it doesn't re-confirm the known classes
  (it still flagged residuals, which were the highest-signal items).
- **The artifact-vs-raw `lemma|raw|artifact` TSV is the key data shape** — the
  agent can spot the divergence pattern in bulk without knowing each lemma.
- **Re-measure after every fix**: the capital-first-token accept I added was
  DEAD CODE (toks were lowercased before the /^[A-Z]/ test), and once enabled it
  over-fired on etymology fragments ("Erse, aile") — a rebuild + golden + census
  per change caught both immediately.

## A broken in-progress fix can be the highest-value audit find (2026-08-08)
The corpus agent's #1 finding was that my OWN uncommitted `de Or` strip
(added hours earlier, artifact already rebuilt) was mangling `declino`→"to turn
asi" — the `/i` + optional-punctuation regex matched "de or" inside English
words. A bare `\bde` + required separator fixed it. Lesson: get in-progress
changes audited before trusting them; an audit that only finds bugs in committed
code misses the freshly-broken working tree.

## The 4-expert audit panel beat the cold audit — here's the recipe (2026-08-08, M-019)
The 2026-08-08 4-expert panel (classicist, product, adversarial architect, data
expert) returned 3 FAIL + 1 conditional-pass and found real defects the cold
audit missed (39 homograph conflations, 6 missing common words, 8 architect
bugs). Why it worked when the earlier cold audit (M-017) stalled:
- **Give each agent a concrete method + a file deliverable**: "sample 120 random
  + 80 frequency + 40 homograph; write the report to DISK before finishing."
  All 4 completed with reports on disk (the cold audit's 3/4 produced empty
  transcripts).
- **The adversarial architect actually RAN the pipeline** — extracted the helper
  block and exercised resolve()/lsExtract() over all 51k L&S keys + 812k
  wordlist rows. Every bug had a concrete `lemma → wrong gloss → should be`.
  A static-read-only reviewer would have missed them.
- **Split by lens, not by file**: classicist (correctness), product (coverage/
  UI copy), architect (break the code), data (honest numbers + test integrity).
  The overlap (data's homograph count == classicist's homograph sample ==
  architect's Bug 6) cross-validated the finding.
- **The data audit checked the TEST SUITES' honesty** — it found golden/census
  were blind to homograph conflation (0 of 34 misfire lemmas tested). Test
  gates that pass 100% while data is wrong are a data-integrity problem, not a
  code-quality one.
- **Verify every claim before fixing** — I confirmed each wrong gloss against
  the L&S raw + wordlist accent before curating. Some audit values were wrong
  (anathema2 "accursed" was actually L&S "an offering"; the classicist's
  dico2/caelum2/lego2/frons2 were already correct as-is). The accent signature
  was the ground truth that separated true homographs (levo2≠levo) from
  wordlist duplicates (paro2==paro).

## Stalled-agent work is recoverable from its transcript JSONL (2026-08-08, M-019)
Two subagents this session wrote a report to disk (good) but TWO more ran 35-50
min with a 0-byte `.output` file and no report. Both had done substantive work
before stalling:
- The **architect re-audit** discovered a REGRESSION in my own H1 fix (accent-
  signature isSpurious wrongly collapsed testis2 "testicle" to "witness" —
  identical-accent distinct homographs) and verified it through resolve(). Its
  last live message ("v.infra in main_notes would make the cross-ref regex
  recurse into infra") pointed at a real low-impact bug. All recoverable.
- The **data verifier** confirmed all 90 homographs are byte-identical
  paradigm duplicates — the fact that validated the advisory panel's approach.
Recovery path: the agent's full conversation is at
`C:\Users\<user>\.claude\projects\<project>\...\subagents\agent-<id>.jsonl`
(the `.output` file stays 0 bytes!). Extract the `type=="assistant"` message
texts (skip tool calls) — the reasoning is there even if no final report.
`python -c` + `tmp/` write beats printing (Unicode arrows crash cp1251 console).
Lesson: the transcript is the record of a stalled agent's work — recover it
before re-running or assuming nothing happened.

## Form+accent ALONE regresses homograph detection — use BOTH signatures (2026-08-08)
The H1 accent-signature fix separated levo2 "smooth" (distinct accent) from
levo "lift", but REGRESSED testis2 "testicle" (identical accent AND forms to
testis "witness" — only the TAG set differs). Neither single signature wins:
form+tag separates testis2, form+accent separates levo2. The correct predicate:
a numbered lemma is spuriously duplicated ONLY when BOTH form+accent AND
form+tag match the bare twin (paro2==paro, acceptor2==acceptor). Also: the
~90 remaining "unresolvable" homographs are byte-identical on ALL signatures
AND row count (Perseus duplicates the whole paradigm per page-split), so no
automatic signal exists — L&S numbers the primary -1 and rarer -2, meaning the
COMMON sense is often the numbered entry (osculo2 "to kiss"). Curate by
dictionary judgement, never by row count. Full panel reasoning:
`tmp/_panel_homograph.md` + `tmp/_panel_product.md`.

## LLM offline batch generation/audit via the poolside rotator (2026-08-09)
The free local rotator (`POST http://127.0.0.1:5000/cline/v1/chat/completions`,
model `poolside/laguna-s-2.1:free`, recipe in `F:\projects\fohlio\...\POOLSIDE_RECIPE.md`)
reliably generates everyday glosses at **concurrency 10** — the earlier ~80%
ECONNREFUSED at concurrency 8 was transient spread-account exhaustion, not a
hard limit (verified: 10/10 ok). Write the checkpoint JSON **after every call**
so a kill loses at most one row and resume is exact; 0 errors at c10 + 3×retry.

**The LLM is the only source that reliably gives the everyday primary** where
L&S opens literal (neco→"kill" not "drown", impetro→"obtain" not "accomplish").
Measured: Lewis Elementary 5.8% on golden vs our L&S 91.5%; WORDS-first-V
~25-30% worse (homograph collisions); kaikki net-negative. The LLM preserves
homographs (levo2→"smooth") where WORDS fails.

**Audit-as-filter, not verdict:** a second LLM pass (`"OK"` / `"BAD: reason :
correct"`) flags ~12% of glosses, but ~half are FALSE positives (it prefers a
synonym; even gets facts wrong — rejects pareo=obey). Apply only objective
fixes (conjugated slips video→"to see", broken strings); review the rest by hand.

**Conjugated-slip catch:** verb lemma + gloss not starting with "to " = flag.
Real cases: video→"I see", scio→"I know", nosco→"learn". Fix to infinitive.

**Golden-gate brittleness:** the gate checks exact L&S substrings, so correct
LLM glosses "fail" ~168 of 193 golden-covered lemmas. Keep golden-covered
lemmas on L&S (hand-audited) rather than re-baselining; a semantic synonym-
bucket re-key is deferred (must not be a rubber stamp). Adding a core key
(e.g. nolo) requires a golden row in the SAME commit (golden-runner enforces).

## Scansion failure triage: the method that worked (2026-08-10, M-013)

The M-013 scansion failures went 150 → 113 (25% cut) this session. The
non-obvious method lessons, in the order they bit:

- **The gold-quantity experiment splits causes in one shot.** Feed the gold
  per-word quantities (hypotactic.com's macronized Aeneid) into `scanVerse`.
  If the line still fails with correct quantities, it's a PROSODY-MODEL gap,
  not a wordlist gap. Only ~1/4 of the corpus failures fixed with gold.
- **Judge fixes by the whole-file corpus gate, NEVER per-line.** RFTagger
  assigns different POS per-line vs whole-file, so a line that scans alone
  may still fail in the file. My per-line reconstruction "fixed" 21 lines;
  only 10 survived the real gate. `test/e2e/test-scansion-corpus.mjs` is
  the truth; the snapshot delta is the number to report.
- **A scansion "fix" that corrupts quantity is worse than no fix.** A
  word-final `ui`-diphthong merge turned obstupuī into a 3-syllable LSL
  (genuinely 4: ob-sti-pu-ī) and caused a 44-line corpus regression
  (sanguine/anguis — `gu` makes the u consonantal). The automaton found A
  path, not THE correct one. Always print the CHOSEN accented forms and
  check the quantities against the edition before accepting a fix.
- **`scannedFeet` alignment breaks on empty verses.** `scanVerses` emitted a
  foot only for non-empty verses, so the `* * * * * * * *` divider lines in
  catullus-LXII/LXIV shifted every subsequent line's feet index — creating
  spurious failures AND hiding 8 real LXIV ones. Fix: empty verses emit
  empty-foot placeholders; the gate + snapshot-regenerator skip non-verse
  (normalized-empty) lines. Generalizable: any index-aligned output must
  handle empty inputs, or every row after the gap misreads.
  ✅ enforced by `Scansion.ts` `scanVerses` (empty-verse placeholder) AND the
  hypermeter dual-candidate fix `2ee8322` (kept alignment by offering both
  readings rather than splicing lines — see the new hypermeter lesson).
- **est-prodelision ("puero est" → "puerō 'st") is already handled** by the
  existing `'V'`-elision branch — a 1-syllable "est" after a vowel-final word
  gets the final vowel elided, which is metrically identical. Tested and
  rejected: only 2 failing lines contain est, neither on the death path.
- **Corpus text errors belong in the corpus, not the engine.** 4 lines in
  catullus-II/LXIV had typos/editorial markers (solacium→solaciolum,
  [est/es]→est, ligitam→ligatam, misera→a misera). Verify against Latin
  Library / wikisource / negenborn scanned Catullus before editing.
- **ACCENT_OVERRIDES append candidates; prose keeps accented[0]** — so an
  override changes scansion-mode readings without touching prose macrons.
  Verify each override against the gold word before adding.
- **A "documented cause" fix can leave the headline line broken for a
  different reason — re-run the gold experiment after fixing.** The y-synizesis
  gap was logged as THE cause of Aen 5.337 `emicat Euryalus...`. Implementing
  consonantal-y (gate 113 → 111, fixed 5.322 `tertius Euryalus` + 5.334
  `non tamen Euryali...`) did NOT fix 5.337: even with Eu-rya-lus the gold
  quantities give `lŭs et` (S-S), which cannot open a foot, and no
  gold-consistent reading fits the automaton at all. The cause was real but
  not the blocker. Lesson: after applying the fix named in the issue, re-derive
  the line's failure from scratch before writing "still open".
- **Brute-force the meter automaton with candidate L/S readings** to enumerate
  exactly which quantity readings fit a line. Feed each word's plausible L/S
  strings through `meters.json['dactylichexameter']` (state 0 start/accept) and
  print the accepted combinations. If NO gold-consistent reading is accepted,
  the line is genuinely unfittable (prosody/transmission gap), not a wordlist
  or synizesis gap — and you skip the quantity-corruption trap. Faster and more
  decisive than reading scansion marks off a rendered PDF.

- **Gold SURFACE text ≠ gold PER-SYLLABLE data — trust the latter.** The
  hypotactic macronized Aeneid surface shows `rēligiō` with short re, but the
  per-syllable JSON (`vergil.json`/`catullus.json`, `syllables[].length`) shows
  `re:long` — L&S double quantity, Vergil scans long re. Brute-forcing `_`/`^`
  forms against the per-syllable L/S pattern (not the surface macrons) was the
  decisive method for ~80 overrides. Surface macrons can mislead on exactly the
  ambiguous quantities that matter.

- **`git restore dist/` after tsc silently loses NEW src overrides from dist.**
  The CRLF-churn cleanup (`git restore dist/...` after every rebuild) also
  reverted freshly-added `ACCENT_OVERRIDES` entries from `dist/core/Tokenization.js`,
  so a gate run kept showing the OLD failure and looked like the override "didn't
  work." Symptom: src has the override, `grep dist` doesn't. Fix: rebuild AFTER
  the restore, or restore only the whitespace-only files (`git diff
  --ignore-all-space` first). Cost a whole debugging cycle on `dehiscent`.

- **Rejected — h-position as a universal rule.** `videt hominesne` needs `det`
  long (Aen 1.308, gold S-L), but `venit Hic` keeps `nit` short (Aen 1.52, gold
  S-S) — the gold is INCONSISTENT on "word-final C + h makes position." A global
  `C + h → position` rule caused 283 regressions. The safe form is a per-word
  override (videt → `vi_det`). Verify the RULE against multiple gold lines
  before implementing it as code.

- **Hypermeter: offer BOTH readings, never splice lines.** A verse-final `-que`
  that elides into the next line's initial vowel is the hypermeter. The working
  fix: give verse-end `-que` both the `#` (final-anceps) and `V` (eliding)
  candidate sets and let the automaton choose. Splicing the two lines into one
  verse (my first attempt) broke `scannedFeet` index alignment and caused a
  283-line regression — an index-aligned output array must keep one slot per
  source line no matter what.

## LLM batch-audit instability (2026-08-09, M-021d/e)

- **Two independent audit runs of the SAME artifact flagged 2794 vs 3084 words; only 1106 overlapped.** The auditor is a filter with ~60-75% recall that is *not stable run-to-run* — it catches different words each pass. Comparing flag COUNTS between runs is meaningless; the reliable signal is the **intersection** (both runs independently flagged it = definitely defective). Never conclude "regression" from a higher second-pass count.
- **Auto-applying audit corrections to `core_gloss.json` is dangerous for mythological/proper-noun entries.** The auditor is confidently wrong on obscure names: it claimed `pituinus`="of phlegm" (L&S: pines), `flaminia`="Via Flaminia" (WORDS: priestess of a flamen), `maera`/`hypseus`/`menalippus` (wrong mythological figures), `lacrima` gum-drop "anachronistic" (L&S sense[2] is exactly gum-drop). Of 22 core flags, only **4** were real fixes (deflagro, aspalathus, phlegraeus, naubolides); 18 reverted. **Verify every core suggestion against L&S before applying.**
- **Audit corrections for LLM-layer words are much safer** (same-source refinement): applied 149 wrong-POS + 170 wrong-meaning with zero golden breakage. The LLM layer is the right place to auto-apply; core is not.
- **LLM generation for L&S-flagged words can pick the wrong homograph** (utriculus2→"pouch" should be "belly" = utriculus1's sense). The `lemma2`/`lemma3` numbered keys need exact-key protection; a generated gloss for a numbered lemma must not conflate its twin.
- **Parser gates that DID work** (zero golden regressions): (1) `fr.`/`from` in ETYMOLOGY notes ("orig. fr. aceo") no longer recurses into the base verb → acetum→"vinegar"; (2) noun-dominant lemma whose L&S cross-ref yields a verb-infinitive prefers WORDS-noun → actum→"act, deed". Both scoped narrowly (the ADV/ADJ verb-leak guard already existed; extended to N).
- **Golden lock catches auditor truth**: when golden + L&S agreed but the auditor disagreed, golden was right 18/22 times. The 4 auditor-wins (deflagro "to go out" not in L&S, aspalathus=thorny shrub, phlegraeus=of Phlegra, naubolides=patronymic) each needed a golden row update to match.

## Gemini lite as the batch-audit engine + the LLM-layer corruption discovery (2026-08-10, M-022)

- **Gemini 3.5/3.1 flash-lite audits the FULL 34k-lemma artifact in ~8 min** (859 batches, batch 40, concurrency 16, 8 keys round-robin via the fohlio LLMProcessor, checkpoint-per-call). No dropped rows at batch 40 — stepfun dropped rows >20. It also finds defects stepfun missed entirely (both stepfun runs + Gemini = 3-family agreement is the gold standard, but Gemini-only still surfaces ~50% real).
- **The M-021c "hand-verified everyday-gloss" LLM layer itself carried 174 gross errors** — geographic adjectives hallucinated into verbs (canusinus→"to sing loudly", dictaeus→"to speak or say", caecubus→"to hinder or obstruct"), conversational filler in-gloss (curetis→"Could you verify the spelling?", cecropius→"...let me think..."), cross-root confusion (anguis→"tight situation" from angustus). Root cause: generation WITHOUT L&S context. Fix: context-grounded generation (lemma + current gloss + audit finding).
- **Numbered homographs: the auditor structurally cross-suggests the bare twin's sense.** esurio2 "hungry person"→verb, cancellarius2 "living behind bars"→chancellor, scopa2 "speculation"→broom, junctus2 "joining"→joined were ALL auditor FPs — L&S numbered key is authoritative. **Never auto-apply fixes to numbered lemmas; remove them from the LLM layer and let L&S's numbered key win.**
- **Systemic fix beats point fixes: the POS guard.** The auditor systematically returns wrong-POS "to X" verb glosses for ADJ/ADV-dominant lemmas (aptus→"to be fit or proper", carus→"to care for", bidens→"to bite", intestatus→"to castrate", arabicus→"to Arabia relating to Arabia"). Added a POS guard in resolve(): an ADJ/ADV-dominant lemma never gets a verb-infinitive gloss from the llm layer → falls through to POS-aware L&S/WORDS. Fixed 104 artifact-wide wrong-POS glosses in one shot. Also exposes a/d lemmas whose ONLY gloss was the wrong verb (geographic/ethnic adjectives) — regenerate those. ✅ enforced by `build_glosses.cjs` resolve() POS guard (M-022b, fc8aa81)
- **Generation fixes carry a ~5% inversion/garbage rate** that only a closing re-audit exposes: inopinor→"unexpected" (L&S: suppose), stellatura→"stars" (L&S: soldiers' ration deduction), tabulinum→"chest" (L&S: balcony), salax→"sharp-witted" (L&S: lustful), largus→"large dare", reliquus→"the correct read. is". **Every fix wave needs a full re-audit of the FIXED artifact** (M-022d: 1723 flags vs 3145, -45%; 2086/2286 fixes clean, 11 confirmed regressions reverted).
- **The auditor is noisy even when two runs agree** — generation inherits its confidence and can produce the OPPOSITE of L&S (immunitus fix was "fortified" when L&S says "unfortified"). The L&S primary cross-check (senses[0] first clause) is the mandatory gate on every applied fix.

## The hypermeter elision-completion guard — and two ways it can regress (2026-08-10, M-013c)

- **`scanVerse` was rejecting genuine hypermeters.** Its guard killed ANY word that
  completed the hexameter (returned to state 0) when later words followed —
  even fully-elided ones. A verse-final `-que` that elides into the next line's
  initial vowel (deorumqu' aut, nexaequ' aere) completes the meter at the
  penultimate word with a trailing 0-syllable `que`. The dual-candidate fix
  (2ee8322) couldn't reach it because the automaton was never offered the path
  where the meter finishes before the last word. Fix: allow a completed meter
  when every trailing word is fully elided, + prefer the COMPLETE reading over
  a partial one at equal penalty (an elided verse-final -que at penalty 0
  otherwise beats a real final syllable at penalty 0 — the Cymodoce 5-foot
  scan). 10 lines fixed in one commit.
- **The min-penalty hypermeter merge must be verse-final ONLY.** The dual-candidate
  code runs for EVERY `-que` word (mid-line atque/namque too, to preserve the
  pre-existing candidate set). Switching its dedup to "keep lowest penalty" leaked
  the # reading's cheap penalty into mid-line contexts and flipped 27 lines'
  chosen quantities (hīc→hĭc, vāgīnā→vāgina) — gold said those were regressions.
  Scoping the min-penalty merge to verse-final `-que` (detected by "next content
  token is a newline") restored byte-identical candidates for mid-line words.
  Lesson: a candidate-set optimization that changes *penalties* (not just adds
  candidates) silently re-ranks every line that word appears in — scope it by
  the exact structural condition it's meant for.
- **Overrides must suppress the allVowelsAmbiguous fallback.** A word with an
  authoritative ACCENT_OVERRIDE that is also marked `isUnknown` gets the engine's
  "guess every vowel length" form on top — and the cheapest (often wrong) combo
  wins (Cymodoce all-long L-L-L-L beating the gold LSSL). The override injection
  now clears `isUnknown`, so the ambiguity fallback isn't layered on. Check this
  whenever an override for an unknown/named word doesn't take effect.
- **A "passing" line can be a false positive that masks a bug.** Aen 5.826
  (Cymodoceque) reported `SSDDD` — an INCOMPLETE 5-foot hexameter — as "scanned."
  The gate only checks non-empty feet, so it never noticed the partial scan.
  After the M-013c fixes, the tie-break turned it into a complete `SSDDDT`. When
  chasing scansion bugs, verify every line ends at state 0, not just that feet
  are non-empty.
  - ⚠️ **RECURRED + quantified 2026-08-10:** a full-corpus audit (all 5,478
    verse lines, `feet.length < 6` for hexameter) found **32 hidden 5-foot
    partials** the gate reports as passing — the true error count was 12
    snapshot + 13 remaining partials = 25/5,478 (0.46%), not 0.22%. ~19 of
    them were caused by a `verseFinalQue` punctuation bug (see below) and are
    now complete. ✅ **FIXED 2026-08-11 (M-013e):** the gate now treats
    `feet.length === 5` (hexameter) as a failure — 5-foot partials are no
    longer masked. Of the 13, six more were a mid-line `-que` elision leak (see
    the next lesson) and three were corpus transcription errors; 16 lines
    remain (0.29%).
- **Heredocs in Git Bash eat backslashes** — a `ROOT.replace(/\/g, '/')` in a
  `<<'EOF'` heredoc became `/\/g` and broke the script. Use the Write tool for
  any JS with regexes.
- **Verse-final -que detection must skip punctuation, not just spaces** (2026-08-10,
  `05f87e3`). The `verseFinalQue` scan in `scanVerses` stopped at the FIRST
  content token: for a line ending `-que.` or `-que,` the `.`/`,` is neither
  space nor newline, so the loop broke with `verseFinalQue=false`. That
  misclassified verse-final -que lines ending in punctuation as mid-line,
  dropping the cheap `#` (final-anceps) reading and silently reverting ~19
  lines to 5-foot partial scans — including Aen 5.826 Cymodoceque (`SSDDD`),
  which the gate masked as passing. Fix: skip spaces AND punctuation, stop only
  at a word (mid-line) or newline/end (verse-final). **This is exactly why the
  gate needs a foot-completeness check** — a `-que.` regression is invisible
  to `feet === ''`.
- **Mid-line -que before a consonant must NOT offer the eliding (V) reading**
  (2026-08-11, M-013e, `47b7e5f`). The hypermeter branch offered
  `possibleScans(cands, 'V')` as an extra candidate for ANY `-que` — but that
  reading is only meaningful when the following sound is a VOWEL (hypermeter
  into the next line, or `atque`/`namque` before a vowel). A mid-line `-que`
  before a consonant (`pictaeque volucres`, `campique Geloi`) cannot elide, so
  the extra `que[]` empty-scansion candidate was spurious. Its cheap penalty
  (0) let the DP skip the syllable and pick an INCOMPLETE 5-foot scan over the
  correct complete hexameter, because the `complete` tie-break only fires on
  EQUAL penalty: `que[S]+volucres[SLL]` = 6ft pen1 loses to `que[]+volucres[SSL]`
  = 5ft pen0. Fix: only compute the extra reading when `followingSegment ===
  'V'`. **Resolved 6 lines** the M-013d audit misclassified — including
  `rursum ex diverso` and `sive deae`, which it called "structural/no 6-foot
  solution" but are genuine complete hexameters the leak was masking. Lesson:
  an elision/optional-syllable candidate that is phonologically impossible in a
  context silently wins on cheap penalty; gate candidate *generation* by the
  same phonological condition the meter assumes.
- **A flat "prefer completion" bonus corrupts; a bounded one is safe** (2026-08-11,
  M-013f, `17a7049`). The DP treats "stop early" as free, so a complete 6-foot
  hexameter whose real quantities cost 3-6 penalty loses to a 5-foot partial.
  But a LARGE completion bonus (6) forces WRONG completions: Nereidum matri
  completed as a corrupt 12-syllable all-spondee `SSSSSS` using short forms
  (`ma_tri_` as L, `neptu_no_` as LL) instead of the gold 13-syllable
  `DSSSSS` (nē-rē-i-dum 4-syll). Bounding the bonus at 3 (one HIATUS/SYNEZIS
  penalty) fixed Tune ille + victor Simoenta (complete paths within 3 penalty)
  while Nereidum correctly stayed a 5-foot partial (its gold path is pen6
  above — completing would corrupt). Lesson: a "prefer X" heuristic must be
  bounded below the cost of a corrupt alternative, and every fixed line must
  be verified to use GOLD forms, not just any 6-foot path. A "fix" that makes
  a line scan by corrupting quantities is worse than leaving it failing.
- **Wordlist quantity errors vs segmenter limitations.** Many remaining
  empty-foot lines are NOT override-fixable: the segmenter can't produce the
  gold pattern (malesuāda SSLS — `sua` always splits; Dryopes SSLS — `y` always
  consonantizes; alveo LL — `veo` always 3-syll). Diagnose by checking whether
  ANY `_`/`^` marking of the word gives the gold L/S pattern via
  `possibleScans`; if none does, it's a segmenter limitation, not an override.
  ✅ **enforced by `test/gold-blocker.mjs`** (2026-08-11) — automates exactly
  this diagnosis per failing line and reports the first blocked word.

## A "low scansion error rate" is only as meaningful as corpus breadth (2026-08-11, M-013g expansion)

- **A corpus of Aeneid 1-6 under-reports the error rate by ~10x.** The old
  5,478-line corpus (books 1-6 + 7 Catullus poems) measured 0.24% failures.
  Expanding to Aeneid 7-12 + Georgics + Eclogues + 47 Catullus elegies
  (16,690 lines, extracted from hypotactic gold via `test/extract-gold-corpus.mjs`)
  surfaced a **2.2% true baseline** — later books hit systematic
  wordlist-quantity errors books 1-6 never did (Greek proper names like
  Euander/Arcades, `bijugis` clusters, common 2-syll verbs like sinit/dabat).
  Lesson: sample breadth matters more than polish; a headline "0.24% error"
  claim is only as good as the texts it was measured on. Every metric needs
  the corpus composition attached.
- **Gold lacunae desync alternating-meter automata** (`fba0aab`). An empty
  verse position with a line number (Catullus 68 lines 47/142/143 — 3 lacunae)
  broke the hex/pent alternation of elegiac distichs: the gate FILTERED empty
  lines, and `scanVerses` did NOT advance the automaton on empty verses, so
  every subsequent pentameter was scanned against the hexameter automaton —
  ~112 of Catullus 68's failures were that single desync. Fix: advance the
  automaton on empty verses (harmless for single-meter corpora where the index
  wraps) AND preserve interior empty lines in the gate/regen (drop only the
  trailing file-final newline). **When a gold-extracted corpus file has fewer
  lines than gold, suspect lacunae before suspecting the engine.**
- **The hypotactic gold data lives in the OS temp dir — back it up.** It was
  purged mid-session by a disk-full cleanup; recovered from
  `hypotactic_data.zip` (the original download). The gold JSONs are the
  verification substrate for all of M-013; losing them means re-downloading
  100MB+ per work. Keep a copy outside temp.

## Closing the two-family audit loop (2026-08-10, M-022 closure)

- **The intersection of TWO audit families is still ~80% false-positive.** stepfun∩Gemini on the fixed artifact = 460 lemmas; after the L&S-primary cross-check only ~90 were real defects. Both models share the same systematic errors (wrong-POS on adjectives, numbered-homograph twin-sense, truncated-tail FP on clean glosses), so agreement between them is NOT independent confirmation. The ONLY reliable gate is the L&S primary cross-check. "Both families agree" is a necessary filter, never a verdict.
- **adverb-POS is a whole defect class invisible to word-overlap L&S filters.** 32 remaining intersection lemmas were ADVERBS glossed as adjectives (velociter "swift"→"swiftly", crudeliter "cruel"→"cruelly", mendaciter "a liar"→"mendaciously"). The L&S primary for adverbs opens with "Fin." (grammar cross-ref), so the word-overlap test sees no shared words and skips them. Detect via the WORDLIST POS: an adverb-dominant lemma (all d-tags, or d-majority with no n/v/a) whose gloss has no adverb form (-ly / "in a ... manner"). Fix with an adverb-specific generation prompt.
- **Fix waves carry a ~2.5% L&S-contradiction rate that only a post-apply check catches.** Of 268 generated fixes, 7 contradicted a clearly-correct L&S primary (arater "plough"→"ploughman", inodoro "to scent"→"to make odorless" — the OPPOSITE, latrina "bath"→"toilet"). Always re-run the applied-fixes-vs-L&S-primary conflict scan after any generation batch; revert the contradictions.
- **The M-022 line of work reached its plateau.** Full artifact: 34,338 lemmas / 448 KB gz, L&S 89.8%. Three-family audit (2× stepfun + Gemini) + closure re-audit of the FIXED artifact + 432/432 of the final two-family intersection processed. Remaining intersection lemmas were either numbered homographs (L&S authoritative) or FP both models shared. The gloss track is done; further passes would be chasing model noise.

## Numbered-homograph hole in the LLM layer (2026-08-11, M-023)

- **The LLM layer held 236 numbered-homograph entries, and they were systematically corrupt.** `resolve()` returns the llm gloss for a numbered lemma BEFORE the L&S/WORDS path, so `manlius2`→"to manage affairs competently" (proper-noun pollution), `araneus2`→"to be spider-like", `cujus2`→"of whom or whose", `pilus2`→"a new word, primipilus... was formed)" (citation fragment) all shipped. The memory rule was already "numbered → L&S authoritative, never generate" — the layer violated it silently. Fix: strip ALL numbered keys from `llm_glosses.tsv` (236 removed). The llm layer now carries only bare lemmas, where it's grounded.
- **Numbered wordlist homographs differ from numbered L&S homographs.** `porus2` (wordlist, "a pore") = L&S `porus1` — the wordlist and L&S number homographs independently, so a numbered L&S key is NOT the wordlist's numbered sense. When a numbered wordlist lemma misses on the exact key, L&S's NUMBERED key is often the wrong (rarer/etymological) sense; the numbered lemma needs a hand-curated core override, not the numbered L&S fallback.
- **~93 numbered wordlist lemmas are unassimilated compound verbs with no L&S/WORDS sense** (abcedo2, adfrigo2, conpario2, inmoror2...). No gloss is better than a hallucinated one — they fall to "—" (skipped). Hand-curate the real, attestable ones (porus2 "a pore", praes2 "at hand", varicus2 "straddling") as core overrides.
- **The wordlist-vs-L&S numbering mismatch is exactly what the isSpurious dual-signature check is FOR** — a numbered key that matches the bare twin on BOTH signatures is a duplicate and resolves to the bare sense (safe). The failures are the ones where the signatures DIFFER (cupa2 vs cupa: formSets sizes differ) but the numbered key is still the *wordlist's* intended common sense — there the bare twin is a *different* L&S entry entirely and WORDS fills the gap with noise. These need core overrides, not a parse-rule change.
- **Result:** 18 numbered core overrides + 6 restored-numbered (porus2/praes2/varicus2/tropa2/disvulgo2/inmoror2) + 236 llm numbered stripped. Artifact 34,342 lemmas / 448 KB / L&S 89.7%. Golden 2016 / census 348, all green.

## Caesar stress test re-run (2026-08-11, M-023)

- **The popup lemma path is the WORDLIST lemma, not the treebank lemma.** A
  LemmaEngine (treebank-corpus) lemmatizer gives `quod`→lemma "quod" (freq 103)
  and `incolunt`→(missing) — but the popup uses `glossFor(p.lemma)` where
  p.lemma comes from the wordlist (macrons.txt) entry, which maps `quod`→`qui`
  and `longissime`→`longus`. The right stress-test harness is
  form→wordlist-lemma→artifact-gloss, not the treebank path.
- **Proper-noun L&S entries can die on a leading gender+author fragment.**
  `Garumna` (the Garonne, a river of Gaul — L&S has it) was MISSING from the
  artifact because senses[0] opens `"Fem., Aus. Mos. 483), = ... Strab., a
  river of Gaul, the Garonne"` — the gender+author+book prefix masks the gloss
  and the gates reject the clause. Only 1 such entry is in the wordlist
  (garumna), so a core override beats a parser change. `Amisia` (the Ems) has
  the same shape but isn't in the wordlist.
- **Adverb forms can be lemmatized under the adjective.** `longe`/`longissime`
  ("far") are wordlist forms of lemma `longus` (adverb d-tag under the
  adjective). A core override on `longus` ("long, tall; far, at a distance")
  covers all three; a core key on `longe` is dead because no such lemma exists.
- **differunt ("they differ") resolves to L&S's literal disfero** ("carry
  away, spread abroad") — the everyday sense is WORDS's "differ, disagree".
  Core override `disfero` = "to differ, be different, disagree; to spread
  abroad".
- **Remaining stress-test gaps are lemmatization, not glosses**: `quod`→qui
  (conjunction "because" vs pronoun), `matrona`→"married woman" (the river
  Matrona vs the common noun), `minimeque`/`proximique` (enclitic -que forms
  out of the wordlist; Morpheus rescues them to minime/proximus). Fixing those
  means changing the wordlist/Morpheus pipeline, not the gloss artifact.
- **Artifact after M-023 stress fixes:** 34,343 lemmas / 448 KB / L&S 89.7%.
  Golden 2020 / census 348, all green.

## Full Bellum Gallicum I stress test (2026-08-11, M-023b)

- **The proper-noun case fallback was the big structural win.** The wordlist
  keys proper nouns lowercase (`harudes`, `leuci`) while L&S keys them
  Capitalized (`Harudes`, `Leuci`). `lsByKey` lowercases every key at load, so
  a naive `lsByKey.get("Harudes")` always misses. Fix: keep an
  original-case map (`lsByOrig`) and add `lsByCapitalized(word)` — fires only
  when the lowercase key misses, so it can't override a common-word gloss.
  +20 proper-noun lemmas recovered (harudes, leuci, leucus, hermandica,
  querquedula, ostrya...).
- **`perh.` (perhaps) is a frequency hedge, not a grammar abbreviation — but
  it was in GRAMMAR_ABBR (−4).** A proper-noun gloss "A Germanic tribe in the
  army of Ariovistus, perh. the same as the Charudes..." scored STRONG_OPEN +3
  − GRAMMAR_ABBR −4 = −1, and the citation tail "1, 51, 2 Monum" (score 0)
  won by tiebreak. Removing `perh` from GRAMMAR_ABBR fixed harudes and ~20
  other proper nouns/words, at the cost of 2 regressions (laquearius,
  olivarius — both now core overrides). Re-run the applied-vs-L&S scan after
  any score-table change.
- **The build's lemma set is the WORDLIST (macrons.txt), not the corpus.** A
  full-text stress test must resolve form→wordlist-lemma→artifact-gloss. The
  LemmaEngine treebank lemmatizes differently (`quod`→quod vs wordlist
  `quod`→qui) and misses verb forms the wordlist has.
- **Unassimilated compound table needs the de-/inter-/prae- set.** `deesset`
  → wordlist lemma `deedo`, which needs `deedo→desum`, `interedo→intersum`,
  `praeedo→praesum` in the TABLE (WORDS has neither the lemma nor the forms).
  After adding: deedo "to fail, be wanting", interedo "to be between",
  praeedo "to superintend".
- **Adverb/particle lemmas that ARE the wordform need core overrides.**
  `commode` (adv "conveniently"), `necne` "or not", `neve` "and not, nor",
  `tanto` "by so much", `dubium` "doubtfully", `stipendiarius` "tributary" —
  L&S opens them with usage-notes (adverb-POS class) or empty senses, and the
  wordlist lemma = the wordform itself, so a core key on the lemma works.
  (plerumque's lemma is plerusque, so a core key on plerumque is dead.)
- **Full BG 1 result: 1926/1929 lemmas glossed (99.8%).** The last 3
  (ide→idem, jamque→jam, pleraque→plerusque) are Morpheus-rescued forms whose
  lemmas ARE glossed in the artifact — the popup resolves them correctly.
  Artifact 34,379 lemmas / 449 KB / L&S 89.7%. Golden 2034 / census 348.

## Cross-author stress tests (2026-08-11, M-023d)

Ran 4 full books through the popup lemma path: Caesar BG 1, Cicero In
Catilinam I, Vergil Aeneid I, Ovid Metamorphoses I.

| Text | tokens | lemmas | glossed | % | missing |
|------|--------|--------|---------|---|---------|
| Caesar BG 1 | 8186 | 1929 | 1926 | 99.8% | 3 |
| Cicero Cat. 1 | ~3600 | 1299 | 1291 | 99.4% | 8 |
| Vergil Aen. 1 | ~4400 | 2322 | 2289 | 98.6% | 33 |
| Ovid Met. 1 | ~5900 | 2391 | 2376 | 99.4% | 15 |

- **The remaining misses are LEXICOGRAPHIC coverage, not gloss bugs.** The
  bulk of each text's missing lemmas are (a) mythological patronymics/geographical
  epithets L&S keys under a DIFFERENT lemma (Helena not helene, Idalium not
  idalia, Teucer not teucrus, Mycenae not mycene, Pyrrha not pyrrhe), (b)
  Morpheus-rescued forms whose lemma IS glossed (ide→idem, jamque→jam), and
  (c) rare unassimilated compound forms. A core override fixes the common ones;
  the patronymic tail is not recoverable without a dedicated proper-noun lexicon.
- **Unassimilated TABLE grows per-author.** Cicero: adsedeo→assideo, confor→
  confero, exlapso→elabor, quaestiono→quaestio, nemen→nemo, exduco→educo,
  extulo→effero. Ovid: distulo→differo, obstupeo→stupeo, subcubo→subcumbo,
  transsum→transeo. Vergil: adforo→affor, inrego→irrigo, introgradior→
  introgredior, perfor→perfero, baco→bacatus. Each is a hand-verified
  wordlist-form→assimilated-lemma mapping; the entry in the artifact must exist.
- **The adverb/particle class (wordform = lemma) recurs across authors.** Each
  text surfaced a few: commode/necne/neve/tanto/dubium/stipendiarius (Cicero),
  dehinc/venatrix/miserabile (Vergil), semideus/priores (Ovid). Same fix:
  core override where the wordlist lemma = the wordform.
- **Prose (Cicero/Caesar) has a distinct miss profile from verse (Vergil/Ovid).**
  Prose misses are verb forms + unassimilated compounds; verse misses are
  mytho-geographical proper nouns. Both are ~1-2% of lemmas and hand-curatable
  via core overrides, but the verse tail (patronymics) has no L&S entry at all.
- **Golden now 2051 rows; artifact 34,412 lemmas / 450 KB / L&S 89.8%.**

## Full-artifact defect scan (2026-08-11, M-023e)

- **The offline LLM layer shipped `</think>` / `<tool_call>` tokens INSIDE gloss values.** 10 entries in `utils/llm_glosses.tsv` (acte, adjaceo, concupisco, condico, fuco, futurus, piger, quintus, torquatus, unctus) had the LLM's reasoning leaked into the gloss ("to paint or dye</think>To color, paint, dye.", "fifth</think>*(Note: ..."). The generator didn't strip thinking-token output. All 10 have a clean gloss prefix before the artifact marker; strip everything after `</think>`/`<tool_call>`/`Note:` at the data layer. A whole-artifact scan for `</think>` etc. is the only way to catch these — the cross-author stress tests can't (they sample by lemma, and these words didn't appear).
- **L&S parenthetical Latin examples survive extraction.** "The hair of the head (hence barba comaeque, Ov. M. 7, 288)" — the "(hence LATIN, Author. book)" is a worked example, not a gloss, and the parser keeps it. Only 2 in the artifact (coma, sphaera) — core override, not a parser rule.
- **L&S senses[1+] can beat senses[0] on score and carry a fragment tail.** altanus: senses[0] "A south-southwest wind, between the Africus and Libonotus" lost to senses[1] "the sea winds were so called quod ab alto spirant)" (Latin quote + unclosed paren). statarius: senses[0] "stationary, standing firm" lost to senses[1] "a kind of comedy... Heaut. prol. 36 sq." (citation tail). Both need core overrides.
- **Heuristic scans of the whole artifact are mostly false-positive.** "First token ends in -is/-it/-am" flags 1707 glosses but they're English verbs ("drive", "made", "cattle"). "relative-clause openers" flags proper nouns whose L&S gloss genuinely starts "who...". The reliable scans were: LLM-artifact tokens (zero false positives), parenthetical-Latin-citation (2 real), dangling-comma-tail (1 real, armus). Measure the class before fixing it.
- **WORDS `[~ X => Y]` is a legitimate metaphor notation** ("pessum → to the lowest part, [~ dare => destroy, ruin]"), not LLM junk — don't strip it.
- **Artifact after M-023e: 34,412 lemmas / 449 KB / L&S 89.8%. Golden 2056 / census 348, all green.**

## The isSpurious homograph guard (2026-08-11, M-023f) — biggest gloss fix in weeks

- **isSpurious() was too aggressive: it collapsed real L&S numbered homographs
  to their bare twin.** The dual-signature test (form+accent AND form+tag both
  match the bare twin) correctly catches wordlist DUPLICATES (paro2 = paro), but
  it ALSO fires for genuine homographs whose inflections are identical — mora2
  "the echeneis fish" vs mora "a delay", labes2 "a stain" vs labes "a fall",
  munificus2 "on duty" vs munificus "bountiful", olor2 "a smell" vs olor "a swan".
  These identical-form homographs passed BOTH signatures and got collapsed to
  the bare sense. 94 such lemmas had their own L&S numbered key with distinct
  senses, and 327 artifact glosses changed once the guard was added.
- **The fix is a guard BEFORE the dual-signature test: if the L&S NUMBERED key
  (mora2) has its own senses, the wordlist lemma X2 is a real homograph, never
  spurious.** Falls through to the dual-signature test only when L&S has no
  numbered key (true duplicates like paro2). This preserves every regression
  case (testis2 "testicle", levo2 "smooth", populus2 "poplar") while fixing
  mora2/labes2/olor2/munificus2/carmen2/etc.
- **The numbered pairs are now correct across the board**: carmen "a prophecy"/
  carmen2 "a card"; mora "delay"/mora2 "fish"; labes "fall"/labes2 "stain";
  populus "people"/populus2 "poplar"; levo "lift"/levo2 "smooth"; testis
  "witness"/testis2 "testicle"; hostio "to make even"/hostio2 "to strike".
- **Two old core keys were themselves wrong**: core['acer']="sharp, keen,
  piercing (adj.); the maple tree" mixed both homographs (acer1 maple, acer2
  sharp) — fixed to "sharp, keen, piercing". Added core['altus']="high, deep,
  lofty" (WORDS had given "a polar word meaning both high and deep").
- **Post-guard check for fragment regressions caught 2**: aenus3 "a bronze
  vessel" (L&S primary is "of copper or bronze"; parser picked the Lit. tail),
  fabrefacio "perh. to be written separately fabre facio)" (L&S senses[0] tail).
  Both core-fixed.
- **Artifact after M-023f: 34,411 lemmas / 450 KB / L&S 89.8%. Golden 2066 /
  census 348, all green.** ~310 numbered homographs now carry their own sense
  instead of the bare twin's.

## Popup gloss race: stale "—" for every word hovered before the download finished (2026-08-12)

- **Symptom.** Full sentences showed glosses for the FIRST word(s) only; all
  others rendered "—" even after the glosses.tsv.gz download completed. Single
  words ("Gallia est") worked. The user could close+reopen and still get "—".
- **Root cause.** `span.__popupHtml` is built ONCE when the result renders
  (`macronizer.html` `buildPopupHtml(token, ...)` at span creation). If
  glossCache was still null (download in flight), the html captured "—" permanently.
  `ensureGlosses().then()` rebuilt ONLY the popup that happened to be open when
  the download resolved — every other span kept its stale html, and hovers just
  re-rendered it. Clicking a reading row rebuilt it (`__cycle`), but a plain
  hover never did.
- **Fix.** After `glossCache` is populated, iterate `#resultText tr.line td .ipa`
  and rebuild every span's `__popupHtml` from the now-populated cache. Idempotent
  and cheap (~a few hundred spans). Also covers spans whose popup was never opened.
- **Test.** `e2e/popup-check.spec.js` "glosses land in every reading row even
  when popups open before the download finishes" — hovers every word of
  "Gallia est omnis divisa in partes tres" with only 120ms between, waits for the
  download, re-hovers, asserts zero "—". This is browser-only (Playwright); the
  Node gloss suite can't see it because there's no async download.
- **Lesson.** Any lazy-loaded glossary/asset that a building step snapshots into
  per-element HTML creates this class of bug: snapshot-then-render must be
  invalidated on load, not just the "currently visible" instance.

## Popup overflow: <details> toggle isn't captured by the position clamp (2026-08-12)

- **Symptom.** Expanding "Analysis details" in the popup made it overflow the
  viewport bottom (bottom ~934 vs 900 viewport) — the expanded content was
  unreachable and overflowed visibly.
- **Root cause.** positionPopup measures `popupEl.offsetHeight` and sets a fixed
  `maxHeight` + `overflowY` — but only runs when the popup OPENS. Expanding the
  <details> after that grows the popup past the clamp, and `overflowY:visible`
  (set because the pre-expansion height was under maxHeight) lets it spill.
- **The trap:** the `toggle` event does NOT bubble, so a delegated listener on
  the popup container never fires. It must attach directly to the `<details>` —
  AND the popup HTML is replaced (innerHTML) both on open and by the gloss-
  rebuild, which drops the listener. So the listener must be re-attached after
  every rebuild. Wrapped in `wirePopupDetails()` called from both sites.
- **Fix.** `wirePopupDetails()` attaches a direct `toggle` listener that calls
  `positionPopup(popupSpan)` when not docked; called from `showPopupFor` and the
  `ensureGlosses().then()` rebuild. Verified at 1600x900 and 800x600 with
  details open — popup stays inside the viewport.
- **Lesson.** Any non-bubbling structural event on dynamically-rebuilt DOM needs
  a "wire after every rebuild" helper, not a one-time delegated listener.
