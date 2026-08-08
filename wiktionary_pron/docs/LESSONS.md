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
