# Next

_Updated 2026-08-11 — branch `main`_

## State
Two tracks, both verified by their own gates (`npm test` exit 0, scansion gate
exit 0):
- **Scansion (M-013b/c/d) is the active front**: 150 → 12 snapshot failures
  over 19 engine commits, ~85 gold-verified `ACCENT_OVERRIDES` + hypermeter
  support. See M-013c/d notes below and ISSUES.md M-013.
- **Gloss (M-005 → M-023)**: full 3-family audit + closure re-audit + full
  two-family intersection processed. **M-023 (2026-08-11) re-opened the
  numbered-homograph hole**: 236 corrupt numbered keys stripped from the llm
  layer + 24 numbered core overrides (manlius2, pilus2, cillo2, porus2,
  praes2, uber2...). Artifact 34,342 lemmas / 448 KB gz / L&S 89.7%. Tests:
  22 unit + 81 IPA + 2016 golden + 348 census. ~22 commits unpushed.

## Open threads
- **Harden the scansion gate to catch partial scans — highest value.** The gate
  checks `feet === ''` only, so a hexameter scanning 5 feet (`SSDDD`) passes.
  M-013d audit: 13 genuine 5-foot partials hidden this way. Change
  `test/e2e/test-scansion-corpus.mjs` to treat `feet.length < 6` as a failure,
  regenerate the snapshot, then chase the 9 brute-fixable overrides (Nereidum
  matri, apparet Camerina, cum tacet omnis, ductores, victor Simoenta, scrupea,
  supplicium, flammati Phaethontis, cum Phrygii Teucro). Corpus fix: Cat 64.204
  `ecens` → `exposcens`. Start: `test/brute-line.mjs` + `test/gold-diag.mjs`.
  Details: ISSUES M-013d.
- **Push to GitHub Pages** — 21 commits unpushed (M-021/M-022 gloss series +
  scansion M-013b/c/d). Live site serves pre-M-021. `git push origin main`,
  verify live after.

## Running / unfinished
Nothing running. Scansion snapshot: `test/data/scansion-failures-snapshot.json`
(12), regenerate with `node test/regen-snapshot.mjs` after an intended change.
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
  detection must skip punctuation (`05f87e3`).
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
