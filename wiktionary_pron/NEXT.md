# Next

_Updated 2026-08-11 — branch `main`_

## State
Two tracks, both verified by their own gates (`npm test` exit 0, scansion gate
exit 0):
- **Scansion (M-013b/c/d/e) is the active front**: 150 → 16 snapshot failures
  over 21 engine commits, ~85 gold-verified `ACCENT_OVERRIDES` + hypermeter
  support. **M-013e (`47b7e5f`)** fixed the mid-line `-que` elision leak
  (24 → 16), 3 corpus transcription errors (Cat 64.204 `ecens`→`exposcens`,
  64.293 `aerea`→`aeria`, 64.346 restored `campī`), and **hardened the gate**
  (5-foot partials now fail, not just empty feet). Hyperameter preserved.
  Details: ISSUES.md M-013d/e.
- **Gloss (M-005 → M-023)**: full 3-family audit + closure re-audit + full
  two-family intersection processed. **M-023 (2026-08-11) re-opened the
  numbered-homograph hole**: 236 corrupt numbered keys stripped from the llm
  layer + 24 numbered core overrides (manlius2, pilus2, cillo2, porus2,
  praes2, uber2...). Artifact 34,342 lemmas / 448 KB gz / L&S 89.7%. Tests:
  22 unit + 81 IPA + 2016 golden + 348 census. ~22 commits unpushed.

## Open threads
- **Chase the last 5-foot partials — the non-empty-foot snapshot lines.**
  The hardened gate surfaces 5-foot partials; the snapshot now holds 16 lines
  (12 empty-foot + 4 remaining 5-foot). Of the original 13, six were the
  mid-line `-que` leak (fixed) and three were corpus errors (fixed). Remaining
  partials to verify against gold: **Nereidum matri** (Aen 3.74),
  **victor apud rapidum Simoenta** (Aen 5.261), **Tune ille Aeneas** (Aen
  1.617), **discedam explebo** (Aen 6.545). Note the brute-force solutions for
  the first two use NON-gold quantities (diphthong splits) — verify against
  hypotactic per-syllable gold before adding overrides. Start:
  `test/brute-line.mjs` + `test/gold-diag.mjs` (fixed Catullus path). Details:
  ISSUES M-013d/e.
- **Push to GitHub Pages** — ~22 commits unpushed (M-021/M-022/M-023 gloss
  series + scansion M-013b/c/d/e). Live site serves pre-M-021. `git push
  origin main`, verify live after.

## Running / unfinished
Nothing running. Scansion snapshot: `test/data/scansion-failures-snapshot.json`
(16), regenerate with `node test/regen-snapshot.mjs` after an intended change.
Gold data (temp): hypotactic `vergil.json`/`catullus.json` (per-syllable).
Gloss audit outputs in `tmp/` (never commit) — all already applied to
`utils/llm_glosses.tsv` and committed.

## Don't redo
- **Judge scansion by the whole-file gate ONLY** — per-line runs differ
  (RFTagger POS). `test-scansion-corpus.mjs` is the truth.
- **Never corrupt vowel quantities to make a line scan**; print chosen forms,
  check against the edition.
- **Gold per-syllable data > surface macrons** (rēligiō). Brute-force `_`/`^`
  forms against the L/S pattern.
- **Hypermeter = verse-final -que dual #/V candidate, never splice lines.**
  The elision-completion guard (`6c49747`) finishes the meter. **Do NOT apply
  the min-penalty merge to mid-line -que** (27-line regression). `verseFinalQue`
  detection must skip punctuation (`05f87e3`). **Mid-line -que before a
  consonant must not offer the V (eliding) reading at all** (`47b7e5f` — the
  spurious `que[]` cheap-penalty leak flipped 6 lines to 5-foot partials).
- **No global h-position rule** — gold is inconsistent; use per-word overrides.
- **Overridden wordforms clear isUnknown** (the Cymodoce all-long trap).
- **Corpus text errors → fix the corpus, not the engine** (verify vs gold).
- **Gloss don't-redo**: the two-family intersection is ~80% FP — both models
  share wrong-POS/twin-sense errors; agreement is a filter, never a verdict,
  only the L&S-primary cross-check decides. Adverb-POS is invisible to
  word-overlap L&S filters (L&S adverbs open "Fin.") — detect via wordlist POS.
  Numbered homographs → L&S key authoritative, never generate for them.
  Numbered L&S key ≠ wordlist numbered sense (porus2 wordlist "pore" = L&S
  porus1). Never put numbered keys in the llm layer — strip them (M-023). Fix
  waves carry ~2.5-5% L&S-contradiction — re-run the applied-vs-L&S scan after
  every batch. POS guard in `build_glosses.cjs` is live; don't "fix" what it
  bypasses.
