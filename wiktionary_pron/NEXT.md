# Next

_Updated 2026-08-09 — branch `main`_

## State
M-005 (dictionary glosses in the word popup) has been through THREE audit rounds:
1. **Corpus read-through** (M-018) fixed 8 systematic classes.
2. **4-expert panel** (M-019) found homograph-conflation + coverage defects (fixed H1-H7).
3. **Architect re-audit + advisory panel** (2026-08-08/09): the architect's transcript
   found H1's accent-signature regressed distinct homographs with identical accents
   (testis2 "testicle"). Fixed with **dual-signature isSpurious** (form+accent AND
   form+tag must match). Then a 3-expert advisory panel on the remaining 90
   unresolvable homographs (identical on all three signals) recommended curating
   the ~17 where L&S's numbered -2 sense is the COMMON word (osculo2 "kiss",
   comparo2 "make ready", luo2 "pay", animosus2 "bold") — L&S numbers the primary
   -1, so the everyday sense is often the numbered entry. 17 core entries added.
Final: `core_gloss.json` **1887**, golden **1960/1960**, census **348/348**,
artifact **33,957 lemmas @ 472 KB**, L&S 83.3% / WORDS 9.2% / none 7.6%.
`npm test` (22+81+1960+348) and macronizer e2e (3/3) both exit 0.

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
Nothing running. Audit/advisory reports live in `tmp/` (gitignored; the session
scratch folder): `_audit_classicist.md`, `_audit_product.md`, `_audit_architect.md`,
`_audit_data.md`, `_audit_recheck.md`, `_panel_homograph.md`, `_panel_product.md`.
The data-verifier panel agent stalled (transcript at .claude/—extract if needed).
The remaining ~71 unresolvable homographs (identical forms/accents/tags) are
accepted residue — the panel saw no user value in curating rare/antiquarian senses.

## Don't redo
- **L&S `main_notes` cross-refs leak the verb infinitive onto ADJ/ADV lemmas.**
  Guarded by the "to X" build rule + golden rows. Blanket WORDS-first is WRONG.
- **The golden suite is self-referential for core_gloss keys** — trust the
  census + spot audits, not the golden count alone. The panel proved it: golden
  100% while wrong homograph rows passed.
- **Measure by corpus frequency / token exposure, not wordform count.**
- **Curation is bounded and monotone** (core 262→1887, golden 75→1960); every
  core entry gets a golden row in the SAME commit.
- **`isSpurious` must use the DUAL signature — form+accent AND form+tag must
  match the bare twin.** Form+accent alone regressed distinct homographs with
  identical accents (testis2 "testicle" → "witness"); form+tag alone regressed
  levo2 (same tags). Both together capture every available signal. The golden-
  runner cache (`test_gloss_regression.cjs`) must store both (forms + formsTag).
- **The ~90 "unresolvable" homographs are byte-identical paradigm duplicates**
  (same forms/accents/tags AND row count) — the wordlist gives no signal. L&S
  numbers the PRIMARY -1 and rarer secondary -2, so the COMMON sense is often
  the numbered entry (osculo2 "kiss"). Curate by dictionary judgement (~17
  done), not frequency. Do NOT collapse numbered→bare globally (breaks
  testis2/populus2/malus2 exact-key rows + the popup e2e).
- **`from X` cross-ref recursion needs a "Part." guard** — "locative from is"
  (inde) is etymology, not a cross-ref.
- **A `de\s+Or` citation strip needs `\b` + separator.**
- **capital-first-token accept in isGlossRun**: check original-case token,
  exclude etymology language fragments ("Erse, aile").
- **Unassimilated prefixes** (adfacio→afficio) need an explicit compound table,
  not just prefix rules (vowel changes too).
- **Scripts in `utils/` that write data files: use ABSOLUTE paths.**
- **All session scratch lives in `tmp/`** (gitignored) — probes, dumps, audit
  and panel reports. Never write `_*` files to `utils/`.
- **Do NOT build a "decisions replay" state machine** (M-004/M-007).
