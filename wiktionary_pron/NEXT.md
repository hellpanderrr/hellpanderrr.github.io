# Next

_Updated 2026-08-10 — branch `main`_

## State
**Scansion (M-013/M-013b/M-013c) is the active front: 150 → 12 failing
lines** over 18 engine commits. ~85 gold-verified `ACCENT_OVERRIDES`
(brute-forced against hypotactic per-syllable data, NOT surface macrons) +
3 corpus fixes + hypermeter support. M-013c (`6c49747`) found the root cause
of the last -que failures: scanVerse rejected a completed meter when
elided trailing words followed; guard relaxation + complete-reading tie-break
+ verse-final-only min-penalty merge → 26 → 15, then obruimur/pater
(`2711098`) and Numitor (`3758533`) → 12. Verified: gate PASS (12 baseline,
no new failures), jest 38/38. Gloss (M-022) is closed; ~11 commits unpushed.

## Open threads
- **Scansion: 12 hard lines remain** (snapshot regenerated each batch):
  structural Greek-name syllabification (Euryalus LSSL — no engine form
  reaches it, emicat Euryalus; Zacynthos — scans manually but not whole-file),
  hemistichs (`Italiam non sponte sequor` — not a hexameter by transmission),
  Catullus edition variants (praeoptarit — engine can't merge prae+op;
  divolso; Scamandri), Aeneid 6 (ferreique; nomen et arma locum servant te
  amice), malesuada (suā diphthong). Start from `test/brute-line.mjs` +
  `test/gold-diag.mjs`; judge by the whole-file gate. Details: ISSUES.md M-013.
- **Push M-021/M-022 to GitHub Pages** — `git push origin main` publishes the
  gloss layer; verify live after. Nothing deployed since `f28355d`.
- **Gloss residual**: ~1600 single-family Gemini re-audit flags (M-022d) — only
  chase via intersection with a fresh stepfun run. 193 golden-covered lemmas
  still show L&S literal (needs semantic synonym re-key).

## Running / unfinished
Nothing running. Scansion snapshot: `test/data/scansion-failures-snapshot.json`
(12), regenerate with `node test/regen-snapshot.mjs` after an intended change.
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
- **Hypermeter = verse-final -que dual #/V candidate, never splice lines**
  (splicing broke `scannedFeet` alignment, 283 regressions). The elision-
  completion guard (`6c49747`) lets the meter finish with elided trailing
  words. **Do NOT apply the min-penalty merge to mid-line -que** — it leaked
  the # reading's cheap penalty and flipped hīc→hĭc / vāgīnā (27-line
  regression, scoped back to verse-final only).
- **Overridden wordforms clear isUnknown** so allVowelsAmbiguous isn't layered
  on top (the Cymodoce all-long false candidate).
- **est-prodelision already handled** by the `'V'`-elision branch.
- **Corpus text errors → fix the corpus, not the engine** (verify vs gold first).
- **Gloss don't-redo**: auditor is a noisy filter — compare intersections, never
  counts; numbered homographs → L&S key; every LLM fix wave needs a re-audit.
