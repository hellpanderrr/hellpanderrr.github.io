# Next

_Updated 2026-08-10 — branch `main`_

## State
Gloss layer (M-021 → M-022) shipped and verified end-to-end. The full
34,338-lemma artifact has been through a **complete 3-family audit cycle**:
2× stepfun runs (M-021d/e) + 1× Gemini 3.5/3.1 flash-lite run (M-022, ~8 min),
with a closing **Gemini re-audit of the FIXED artifact** (M-022d).

Committed this session: `a00e915` (W1: 690 triple-agreed defects),
`fc8aa81` (W2: 1281 Gemini-only + POS guard), `45effbe` (W3: 388
stepfun-both-not-Gemini), `f89811a` (closure re-audit: 11 regressions),
`c7e20ec` (docs). **7 commits unpushed** (`b3bc246`..`c7e20ec`) — GitHub
Pages still serves pre-M-021 state.

Artifact: 34,338 lemmas / 450 KB gz / L&S 89.7% / WORDS 4.6% / none 5.6%.
Tests green: 22 unit + 81 IPA + 1992 golden + 348 census.

## Open threads (priority order)
- **Push to GitHub Pages** — 7 commits local, nothing deployed since
  `f28355d`. `git push origin main` publishes everything; verify the live
  macronizer gloss layer after.
- **~1600 residual re-audit flags** (M-022d) — single-family Gemini noise:
  ~1400 long-standing (pre-M-022), ~120 changed-by-waves that L&S cross-check
  cleared. Do NOT chase without an independent second model family (the
  auditor is a noisy filter — see Don't redo). Intersection with a fresh
  stepfun run on the CURRENT artifact would be the reliable next target.
- **193 golden-covered lemmas still show L&S literal** (veho→"be carried") —
  needs a semantic synonym-bucket re-key authored from the headword, not LLM
  output. Unchanged since M-005.
- **Scansion M-013** (separate track, from `b3bc246`): ~111 corpus failures;
  Aen 5.337 `emicat Euryalus...` still unfittable by any gold-consistent
  reading. See ISSUES.md M-013.

## Running / unfinished
Nothing running. Audit outputs: `tmp/_final_audit_out.json` (audit1, 2794),
`tmp/_audit2_out.json` (audit2, 3084), `tmp/_gemini_audit_out.json` (Gemini
3145), `tmp/_gemini_reaudit_full.json` (closure, 1723). Fix generators:
`tmp/_gemini_fix690/1209/396.py`, `tmp/_fix{690,1209,396}.tsv`. Workbench:
`tmp/_regressions.tsv`, `tmp/_only1281.tsv`, `tmp/_both425.tsv`. Scratch
lives in `tmp/` — never commit it.

## Don't redo
- **The auditor is a noisy filter, unstable run-to-run.** Two stepfun runs
  flagged 2794 vs 3084 (1106 overlap); Gemini added a third family. Compare
  INTERSECTIONS, never flag counts. A higher second-pass count is NOT a
  regression.
- **Numbered homographs: the auditor structurally cross-suggests the bare
  twin's sense** (esurio2 "hungry person"→verb, scopa2 "speculation"→broom,
  certo bare adverb→"to contend"). L&S numbered key is authoritative —
  REMOVE numbered lemmas from the LLM layer, never generate fixes for them.
- **Every LLM fix wave carries ~5% inversion/garbage** (inopinor→"unexpected"
  vs L&S "suppose", salax→"sharp-witted" vs "lustful"). Always close with a
  full re-audit of the FIXED artifact + an L&S primary cross-check
  (senses[0] first clause) on every changed gloss.
- **Do not auto-apply audit corrections to `core_gloss.json`** — verify each
  against L&S (18/22 were wrong on mythological/proper nouns).
- **Systemic guards beat point fixes**: the POS guard in `build_glosses.cjs`
  (ADJ/ADV lemma never gets "to X" from the llm layer) fixed 104 wrong-POS
  glosses in one shot. Add a guard before hand-fixing a class.
- **Parser gates that worked** (zero golden regressions): fr./from in ETYMOLOGY
  must not recurse into the base verb; noun-lemma verb cross-ref prefers
  WORDS-noun; spurious-homograph needs the DUAL signature (form+accent AND
  form+tag).
- **Scansion don't-redo** (from `b3bc246`): judge by whole-file gate only;
  never corrupt vowel quantities to make a line scan; re-derive a line's
  failure from scratch after applying a fix before declaring it open.
