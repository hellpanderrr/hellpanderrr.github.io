# Next

_Updated 2026-08-09 — branch `main`_

## State
Gloss layer (M-021d/e) shipped and verified: full-artifact LLM batch audit
(34,335 words) + parser gates + LLM-layer fixes. **1688 of 2794 audit1 flags
now pass audit2**; wrong-POS 613→107, truncated 294→18, garbled 112→1.
Tests green: 22 unit + 81 IPA + 1989 golden + 348 census, npm test exit 0.
Commits: `533da9d` (parser gates + LLM wrong-POS + WORDS gen), `6d17ec6`
(LLM wrong-meaning + core fixes + golden updates). On top of these sit
scansion M-013 commits from a later session (`b3bc246`..) — unrelated.

## Open threads
- **1106 persistent defects** (both audits independently agreed = definite):
  mostly L&S/WORDS semantic — wrong homograph (alii→garlic vs "others"),
  opposite meaning (adoperio→"uncover" vs "cover up"), declined-form-as-lemma
  (alia→"native of Elis"), truncated tails (adonia, aedilis). Verdicts in
  `tmp/_audit2_out.json`. Fix via LLM-corrections in `llm_glosses.tsv` with
  an **L&S-agreement gate** (core is NOT safe — auditor wrong on ~18/22
  mythological/proper-noun suggestions).
- **1978 audit2-only flags** — mostly auditor noise (unstable filter, see
  Don't redo). Do NOT chase these until the 1106 persistent are done.
- **193 golden-covered lemmas still show L&S literal** (veho→"be carried") —
  needs semantic synonym-bucket re-key, authored from headword not LLM output.
- **Push M-005+ to GitHub Pages** — nothing since `da94aca`; many commits local.
- **Scansion M-013** (separate track, from `b3bc246`): ~111 corpus failures;
  Aen 5.337 `emicat Euryalus...` still unfittable. See ISSUES.md M-013.

## Running / unfinished
Nothing running. Audit outputs: `tmp/_final_audit_out.json` (audit1, 2794
flags), `tmp/_audit2_out.json` (audit2, 3084 flags). Generators:
`tmp/_final_audit.cjs`, `tmp/_gen_words.cjs`, `tmp/_gen_meaning.cjs`.
`macronizer/glosses.tsv.gz` is rebuilt and committed.

## Don't redo
- **Auditor is an UNSTABLE filter** — two runs of the same artifact flagged
  2794 vs 3084; only 1106 overlap. Compare the INTERSECTION, never flag
  counts; a higher second-pass count is NOT a regression.
- **Do not auto-apply audit corrections to `core_gloss.json`** — verify each
  against L&S. Of 22 core flags only 4 were real (deflagro, aspalathus,
  phlegraeus, naubolides); 18 reverted (pituinus=pines, flaminia=priestess,
  lacrima gum-drop IS classical, maera/hypseus/menalippus right in golden).
- **LLM generation for numbered lemmas can pick the wrong homograph**
  (utriculus2→"pouch" should be "belly") — exact-key protect lemma2/lemma3.
- **Parser gates that worked** (zero golden regressions): fr./from in ETYMOLOGY
  must not recurse into base verb; noun-lemma verb cross-ref prefers WORDS-noun.
- **Gloss don't-redo** (details in CLAUDE.md/LESSONS.md): L&S primary; `_*`
  scratch in `tmp/`; no "decisions replay" state machine; never `git add -A`.
- **Scansion don't-redo** (from `b3bc246`): judge by whole-file gate only; never
  corrupt vowel quantities to make a line scan.
