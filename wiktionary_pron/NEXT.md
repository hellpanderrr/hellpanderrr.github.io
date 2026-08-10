# Next

_Updated 2026-08-10 — branch `main`_

## State
**Scansion (M-013b/c/d) is the active front: 150 → 12 snapshot failures**
over 19 engine commits, plus ~85 gold-verified `ACCENT_OVERRIDES` + hypermeter
support. M-013c (`6c49747`) fixed the hypermeter elision-completion guard
(26 → 15); obruimur/pater/Numitor → 12; `05f87e3` fixed a verseFinalQue
punctuation bug that was silently reverting ~19 lines to 5-foot partials.
Verified: gate exit 0 (12 baseline), jest 38/38. Gloss (M-022) is closed;
~19 commits unpushed.

## Open threads
- **Harden the scansion gate to catch partial scans — highest value.** The
  gate checks `feet === ''` only, so a hexameter that scans 5 feet (`SSDDD`)
  passes. M-013d audit: 13 genuine 5-foot partials are hidden this way.
  Change `test/e2e/test-scansion-corpus.mjs` to treat `feet.length < 6`
  (hexameter) as a failure, regenerate the snapshot, then chase the 9
  brute-fixable overrides (Nereidum matri, apparet Camerina, cum tacet omnis,
  ductores, victor Simoenta, scrupea, supplicium, flammati Phaethontis, cum
  Phrygii Teucro). Corpus fix: Cat 64.204 `ecens` → `exposcens`.
  Start: `test/brute-line.mjs` + `test/gold-diag.mjs`. Details: ISSUES M-013d.
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
- **verseFinalQue detection must skip punctuation** (`05f87e3`) — `-que.`/
  `-que,` lines otherwise revert to 5-foot partials the gate masks.
- **Overridden wordforms clear isUnknown** so allVowelsAmbiguous isn't layered
  on top (the Cymodoce all-long false candidate).
- **est-prodelision already handled** by the `'V'`-elision branch.
- **Corpus text errors → fix the corpus, not the engine** (verify vs gold first).
- **Gloss don't-redo**: auditor is a noisy filter — compare intersections, never
  counts; numbered homographs → L&S key; every LLM fix wave needs a re-audit.
