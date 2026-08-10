# Next

_Updated 2026-08-10 — branch `main`_

## State
**Scansion (M-013/M-013b) is the active front: 150 → 26 failing lines** over
18 engine commits (15 this session). ~80 gold-verified `ACCENT_OVERRIDES`
(brute-forced against hypotactic per-syllable data, NOT surface macrons) +
3 corpus fixes + hypermeter support (`2ee8322`, verse-end `-que` dual
candidate). Verified: gate PASS (26 baseline, 23 golden), jest 38/38.
Gloss (M-022) is closed; ~7 commits unpushed.

## Open threads
- **Scansion: 26 hard lines remain** — multi-elision hypermeters (deorumque,
  coloremque), hemistichs (`Italiam non sponte sequor`, `et matri praereptus
  amor` — not hexameters by transmission), Catullus structural (praeoptarit,
  divolso, natisque), quantity-corruption-risky (emicat Euryalus, Zacynthos).
  Start from `test/e2e/test-scansion-corpus.mjs` + `test/trace-scansion.mjs`;
  judge by the whole-file gate. Details: ISSUES.md M-013.
- **Push M-021/M-022 to GitHub Pages** — `git push origin main` publishes the
  gloss layer; verify live after. Nothing deployed since `f28355d`.
- **Gloss residual**: ~1600 single-family Gemini re-audit flags (M-022d) — only
  chase via intersection with a fresh stepfun run. 193 golden-covered lemmas
  still show L&S literal (needs semantic synonym re-key).

## Running / unfinished
Nothing running. Scansion snapshot: `test/data/scansion-failures-snapshot.json`
(26), regenerate with `node test/regen-snapshot.mjs` after an intended change.
Gold data (temp): hypotactic `vergil.json`/`catullus.json` (per-syllable).
Gloss audit outputs in `tmp/` (never commit).

## Don't redo
- **Judge scansion by the whole-file gate ONLY** — per-line runs differ
  (RFTagger POS). `test-scansion-corpus.mjs` is the truth.
- **Never corrupt vowel quantities to make a line scan** — print chosen forms,
  check against the edition (the ui-diphthong false positive).
- **Gold per-syllable data > surface macrons** (rēligiō: short re on surface,
  long re per-syllable). Brute-force `_`/`^` forms against the L/S pattern.
- **`git restore dist/` after tsc silently drops NEW src overrides** — rebuild
  after restore, or a gate run shows the old failure.
- **No global h-position rule** — gold is inconsistent (videt S-L vs venit S-S);
  use per-word overrides.
- **Hypermeter = offer both `#`/`V` readings for verse-end `-que`, never splice
  lines** (splicing broke `scannedFeet` alignment, 283 regressions).
- **est-prodelision already handled** by the `'V'`-elision branch.
- **Corpus text errors → fix the corpus, not the engine** (verify vs gold first).
- **Gloss don't-redo**: auditor is a noisy filter — compare intersections, never
  counts; numbered homographs → L&S key; every LLM fix wave needs a re-audit.
