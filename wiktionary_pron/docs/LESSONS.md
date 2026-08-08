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
