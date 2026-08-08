# Next

_Updated 2026-08-08 — branch `main`_

## State
M-005 (dictionary glosses in the word popup) has been through TWO audits:
1. **Corpus read-through** (M-018) fixed 8 systematic classes (de-Or bound,
   compact primaries, Latin-quote gate, text-critical gate, citation lists,
   proper-noun collisions, WORDS fallback).
2. **4-expert panel** (M-019, 2026-08-08) returned 3 FAIL / 1 conditional-pass
   and found the homograph-conflation + coverage defects. All 8 architect bugs
   + data findings fixed (H1-H7 + common words).
Final: `core_gloss.json` **1856**, golden **1941/1941**, census **348/348**,
artifact **33,958 lemmas @ 472 KB**, L&S 83.3% / WORDS 9.2% / none 7.6%.
`npm test` (22+81+1941+348) and macronizer e2e (3/3) both exit 0.

## Open threads
- **~100 rare participle verb-leaks remain** (M-017 residue; ADJ/ADV lemmas
  still "to X", WORDS POS-null). Lower priority — rare words.
- **P7 etymology/myth-note clauses** (menta "a nymph who was changed",
  monedula) — a residual few remain; mitigated by P2 primary recognition.
- **Some remaining core values may be wrong** — the data audit found 2
  contradictions (castus2, litus2) among 1836; a full core-vs-L&S audit could
  find more (68 dead keys noted).
- **Push the M-005 commits** when ready for GitHub Pages — nothing since
  `da94aca` is pushed; ~60 commits sit on `main` locally.
- **Engine lemmatization collisions** (wordlist maps `circa`→Circe, `est`→edo,
  `versus`→verro, `demum`→demos, `sane`→sanus): patched via core here, real fix
  in the engine repo. `differo`/`diffido`/`dissilio`/`ius`/`valde`/`quod`/
  `iacio` are NOT wordlist lemmas (0 rows) — resolved via inflected forms.
- **UI test coverage (M-015):** stale CI exclusion (`--grep-invert macronizer`).
- **Engine coverage (M-013)** — Scansion.js / MorpheusAnalyzer / alignMacronized.
- **M-004 Phase 3** — accepted-names list + input-hash snapshot.

## Running / unfinished
Nothing running. The 4-expert audit panel COMPLETED (all 4 wrote reports:
`utils/_audit_classicist.md`, `_audit_product.md`, `_audit_architect.md`,
`_audit_data.md`). Its findings are committed; a re-audit would verify.

## Don't redo
- **L&S `main_notes` cross-refs leak the verb infinitive onto ADJ/ADV lemmas.**
  Guarded by the "to X" build rule + golden rows. Blanket WORDS-first is WRONG.
- **The golden suite is self-referential for core_gloss keys** — trust the
  census + spot audits, not the golden count alone. The 4-expert panel proved
  it: golden 100% while 39+ homograph rows were wrong.
- **Measure by corpus frequency / token exposure, not wordform count.**
- **Curation is bounded and monotone** (core 262→1856, golden 75→1941); every
  core entry gets a golden row in the SAME commit.
- **`isSpurious` must use form+ACCENT signature** (not form+tag) — distinct
  vowel length = distinct homograph (levo2 "to smooth" ≠ levo "to lift").
  The golden-runner cache must match (form+accent too).
- **`from X` cross-ref recursion needs a "Part." guard** — "locative from is"
  (inde) is etymology, not a cross-ref.
- **A `de\s+Or` citation strip needs `\b` + separator.**
- **capital-first-token accept in isGlossRun**: check original-case token,
  exclude etymology language fragments ("Erse, aile").
- **Unassimilated prefixes** (adfacio→afficio) need an explicit compound table,
  not just prefix rules (vowel changes too).
- **Scripts in `utils/` that write data files: use ABSOLUTE paths.**
- **Don't commit** `utils/ext_tmp/`, `gloss_lemma_cache.json.gz`, `utils/_*`
  scratch — gitignored.
- **Do NOT build a "decisions replay" state machine** (M-004/M-007).
