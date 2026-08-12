# Next

_Updated 2026-08-11 — branch `main`_

## State
Two tracks, both verified by their own gates (`npm test` exit 0, scansion gate
exit 0):
- **Scansion (M-013a→i)**: **47 failing lines on a 3× corpus** (16,690 lines,
  0.28%) — down from 220. The `6c49747`→`aedfa89` series fixed hypermeter,
  mid-line `-que`, 5-foot partials, the gold-lacuna automaton desync, and 2
  large override batches (M-013h/i, ~140 gold-verified entries). The blocker
  tool now brute-forces override forms per word and handles `?`-wildcard gold.
  Details: ISSUES.md M-013d/e/f/g/h/i.
- **Gloss (M-005 → M-023h)**: cross-author stress (Caesar/Cicero/Vergil/Ovid
  ~99% glossed), isSpurious homograph guard (94 numbered homographs, 327 glosses
  corrected), LLM-artifact cleanup, plus the popup series (gloss race, warm-at-
  init, details-toggle overflow/jump). Artifact 34,411 lemmas / 450 KB gz /
  L&S 89.8%. Tests 22 unit + 81 IPA + 2067 golden + 348 census + 19 macronizer
  e2e (7 popup). All pushed (0 unpushed).

## Open threads
- **Remaining 47 failures** are two genuine engine limitations, neither
  override-able:
  1. **`veo`/`eo`/`ua` synizesis** (segmenter): alveo/aureo (al-vēo=2 syll),
     menestheo/eurystheo/orphea (final -eo absorbs), malesuada/nemorosa,
     deerit/deerunt/deerraverat (dē-er-it=2 syll), ponite, praeoptarit, dabis,
     daphnim. Fix = segmenter or special-casing, not ACCENT_OVERRIDES.
  2. **`-que` chains** (~12 lines): gold scans the enclitic LONG in arsis
     (Aen 12.89 ēnsemque=LLL) but the engine tokenizes `ensem`+`que` and can
     only produce short que. **Blocker blind spot**: gold fuses Xque, engine
     splits X+que, so gold-blocker's alignment skips it and reports "no word-
     level blocker". The gold stream DOES scan through the hexameter automaton
     — the gap is tokenizer/scansion-convention, not the meter. Fix would
     likely be a `-que`-specific handling (offer long when in arsis).
  Start: `node --max-old-space-size=4096 test/gold-blocker.mjs --snapshot
  test/data/scansion-failures-snapshot.json`.
- **Expansion roadmap**: hypotactic corpus has 28 works (Ovid 263MB, Lucretius,
  Lucan, Statius, Silius, Propertius, Tibullus, Juvenal, Persius, Martial...).
  `node test/extract-gold-corpus.mjs` pulls any of them in (add a `--work`
  mode for non-Vergil/Catullus). Each new work surfaces fresh wordlist gaps.
- **Engine not pushed** (27 ahead of origin) — push only if the user asks.

## Running / unfinished
Nothing running. Scansion snapshot: `test/data/scansion-failures-snapshot.json`
(47), regenerate with `node test/regen-snapshot.mjs` after an intended change.
Gold data (temp): hypotactic at `C:/Users/HELLPA~1/AppData/Local/Temp/hypotactic_data_6_17_2025/` (recovered from `hypotactic_data.zip` after a purge — **back it up**, it's the verification substrate). Blocker tool + extractor committed (`e39b29f`, reworked `aedfa89`).

## Don't redo
- **Judge scansion by the whole-file gate ONLY** — per-line runs differ
  (RFTagger POS). `test-scansion-corpus.mjs` is the truth.
- **Never corrupt vowel quantities to make a line scan**; print chosen forms,
  check against the edition.
- **Gold per-syllable data > surface macrons** (rēligiō). Brute-force `_`/`^`
  forms against the L/S pattern; if none produces the gold pattern, it's a
  segmenter limitation, not an override (`gold-blocker.mjs` automates this).
  **`?` in a gold pattern is a wildcard (uncertain syllable), not a blocker.**
- **Override forms must produce the gold in the line's ACTUAL segment** — a
  form like `bijugis` gives SSL only before consonants; `bijugi_s` (forced
  long final) gives it everywhere. Verify with `possibleScans` in the failing
  line's segment before adding.
- **Check existing overrides before "fixing" a symptom**: M-013g's `sinit`
  (`si^ni^t`) and `dabat` (`da^ba^t`) were all-short and NEVER produced the
  gold SL — a blocker that survives an override may mean the override form is
  wrong, not that the line is unfixable.
- **Corpus files can carry title lines** (aeneid-4.txt had `Aeneid IV`) that
  shift gold-vs-corpus line alignment by 1 for the whole book — the blocker
  then analyzes every line against the wrong gold. Check the first line when a
  file's failures look odd.
- **Hypermeter = verse-final -que dual #/V candidate, never splice lines.**
  `6c49747` finishes the meter. **Do NOT apply the min-penalty merge to
  mid-line -que** (27-line regression). `verseFinalQue` detection skips
  punctuation (`05f87e3`). **Mid-line -que before a consonant must not offer
  the V reading** (`47b7e5f`).
- **No global h-position rule** — gold is inconsistent; use per-word overrides.
- **Completion bonus must be bounded (< cost of a corrupt alternative).** The
  bonus (=3) fixes hexameters within one concession but must NOT be 6+ —
  that forced Nereidum to complete with wrong quantities (`17a7049`).
- **Overridden wordforms clear isUnknown** (the Cymodoce all-long trap).
- **Gold lacunae = real verse positions.** When a gold-extracted corpus file
  has fewer lines than gold, suspect lacunae (empty entries with line numbers)
  before suspecting the engine — they desync alternating-meter automata
  (`fba0aab`). Preserve interior empty lines in the gate.
- **A "low error rate" is corpus-breadth-dependent.** 0.24% on books 1-6 was
  really 2.2% over 3× the texts. State the corpus composition with any metric.
- **Gloss don't-redo**: two-family intersection is ~80% FP; agreement is a
  filter, never a verdict — only the L&S-primary cross-check decides.
  Adverb-POS is invisible to word-overlap filters. Numbered homographs → L&S
  key authoritative; never put numbered keys in the llm layer (M-023). Re-run
  the applied-vs-L&S scan after every fix batch.
- **Popup don't-redo** (M-023g→h.4): glosses warm at init — don't move back to
  lazy-on-first-hover. Popup anchors ABOVE the word; expanding details must NOT
  reposition (keeps the clicked summary under the cursor) — internal scroll
  clamps it. `toggle` does not bubble and the popup innerHTML is rebuilt on
  open+gloss-load, so any per-details listener must be re-wired via
  `wirePopupDetails()`. These are e2e-locked in `e2e/popup-check.spec.js`.
