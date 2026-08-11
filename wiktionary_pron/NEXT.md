# Next

_Updated 2026-08-11 — branch `main`_

## State
Two tracks, both verified by their own gates (`npm test` exit 0, scansion gate
exit 0):
- **Scansion (M-013a→g)**: 150 → **220 failing lines on a 3× corpus** (16,690
  lines, 1.32%). The `6c49747`→`fba0aab` series fixed hypermeter, mid-line
  `-que`, 5-foot partials (bounded completion bonus), 3 corpus transcription
  errors, and the gold-lacuna automaton desync; the gate now fails on
  `feet.length === 5`. The 3× expansion (Aeneid 7-12 + Georgics + Eclogues +
  47 Catullus elegies, `e39b29f`) surfaced a 2.2% true baseline the 6-book
  corpus under-reported. Details: ISSUES.md M-013d/e/f/g.
- **Gloss (M-005 → M-023f)**: cross-author stress (Caesar/Cicero/Vergil/Ovid,
  ~99% glossed) + full-artifact scans + the isSpurious homograph guard
  (94 numbered homographs restored, 327 glosses corrected). Artifact 34,411
  lemmas / 450 KB gz / L&S 89.8%. Tests 22 unit + 81 IPA + 2067 golden + 348
  census. 4 commits unpushed (M-023c/d/e/f + f.2).

## Open threads
- **Chase the 220 snapshot failures with `test/gold-blocker.mjs`** — for each
  failing line it reports the first word whose gold L/S pattern the engine
  can't produce. Systematic clusters: Arcades (segmenter can't make LSS),
  bijugis/quadrijugis (y-synizesis), alveo (veo), inicit/manibus (common
  verbs). Run it, then batch the override-able words (verify each form via
  `possibleScans` before adding). Start: `node test/gold-blocker.mjs`.
- **Expansion roadmap**: the hypotactic corpus has 28 works (Ovid 263MB,
  Lucretius, Lucan, Statius, Silius, Propertius, Tibullus, Juvenal, Persius,
  Martial...). `node test/extract-gold-corpus.mjs` pulls any of them into the
  corpus (add a `--work` mode for non-Vergil/Catullus). Each new work will
  surface fresh wordlist gaps — that's the point.
- **Engine not pushed** (26 ahead of origin) — push only if the user asks.

## Running / unfinished
Nothing running. Scansion snapshot: `test/data/scansion-failures-snapshot.json`
(220), regenerate with `node test/regen-snapshot.mjs` after an intended change.
Gold data (temp): hypotactic at `C:/Users/HELLPA~1/AppData/Local/Temp/hypotactic_data_6_17_2025/` (recovered from `hypotactic_data.zip` after a purge — **back it up**, it's the verification substrate). New corpus files + extractor + blocker are committed (`e39b29f`).

## Don't redo
- **Judge scansion by the whole-file gate ONLY** — per-line runs differ
  (RFTagger POS). `test-scansion-corpus.mjs` is the truth.
- **Never corrupt vowel quantities to make a line scan**; print chosen forms,
  check against the edition.
- **Gold per-syllable data > surface macrons** (rēligiō). Brute-force `_`/`^`
  forms against the L/S pattern; if none produces the gold pattern, it's a
  segmenter limitation, not an override (`gold-blocker.mjs` automates this).
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
- **Corpus text errors → fix the corpus, not the engine** (verify vs gold).
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
