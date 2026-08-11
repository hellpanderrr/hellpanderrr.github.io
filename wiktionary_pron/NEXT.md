# Next

_Updated 2026-08-11 — branch `main`_

## State
Two tracks, both verified by their own gates (`npm test` exit 0, scansion gate
exit 0):
- **Scansion (M-013b/c/d/e/f) is the active front**: 150 → 13 snapshot failures
  over 22 engine commits, ~85 gold-verified `ACCENT_OVERRIDES` + hypermeter
  support. **M-013e (`47b7e5f`)** fixed the mid-line `-que` elision leak
  (24 → 16), 3 corpus transcription errors (Cat 64.204 `ecens`→`exposcens`,
  64.293 `aerea`→`aeria`, 64.346 restored `campī`), and **hardened the gate**
  (5-foot partials now fail, not just empty feet). **M-013f (`17a7049`)** added
  a bounded completion bonus (=3, one HIATUS/SYNEZIS) + gold overrides
  (ilio LSS, euryalus LSSL), resolving 3 of the 4 five-foot partials
  (16 → 13). Hypermeter preserved. Details: ISSUES.md M-013d/e/f.
- **Gloss (M-005 → M-023)**: full 3-family audit + closure re-audit + full
  two-family intersection processed. **M-023 (2026-08-11) re-opened the
  numbered-homograph hole**: 236 corrupt numbered keys stripped from the llm
  layer + 24 numbered core overrides (manlius2, pilus2, cillo2, porus2,
  praes2, uber2...). Artifact 34,342 lemmas / 448 KB gz / L&S 89.7%. Tests:
  22 unit + 81 IPA + 2016 golden + 348 census. ~22 commits unpushed.

## Open threads
- **The 13 remaining snapshot lines are mostly segmenter limitations, not
  overrides.** Diagnosed against gold (hypotactic per-syllable): the blockers
  are the segmenter's inability to produce gold patterns (malesuāda SSLS —
  `sua` always splits; Dryopes SSLS — `y` always consonantizes; alveo LL —
  `veo` always 3-syll; Nereidum gold path is pen6 above the cheap path, so a
  bounded bonus correctly leaves it a 5-foot partial). These need segmenter
  work, not `ACCENT_OVERRIDES` — each is risky and needs a full-gate
  regression check. The one candidate that may be an ENGINE fix (not
  segmenter): `nomen et arma` (Aen 6.507) needs elision to NOT cross
  punctuation (`tē, amīce` — comma blocks elision, but the engine skips
  punctuation when computing followingSegment). Verify against Python
  reference before attempting; punctuation-elision is a deliberate deviation.
- **Push to GitHub Pages** — ~22 commits unpushed (M-021/M-022/M-023 gloss
  series + scansion M-013b/c/d/e/f). Live site serves pre-M-021. `git push
  origin main`, verify live after.

## Running / unfinished
Nothing running. Scansion snapshot: `test/data/scansion-failures-snapshot.json`
(13), regenerate with `node test/regen-snapshot.mjs` after an intended change.
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
- **Completion bonus must be bounded (< cost of a corrupt alternative).** The
  bonus (=3, one HIATUS/SYNEZIS) fixes hexameters within one concession but
  must NOT be 6+ — that forced Nereidum to complete with wrong 12-syllable
  quantities. Verify every fixed line uses GOLD forms, not just any 6-foot
  path (`17a7049`).
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
