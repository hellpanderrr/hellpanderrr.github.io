# Next

_Updated 2026-08-08 — branch `main`_

## State
M-005 (dictionary glosses in the word popup) is **DONE and hardened by a cold
4-lens audit** (2026-08-08). The closed-class fix (CORE_GLOSS + WORDS-first) +
a 14-round curation loop + the cold audit's systemic finds are all committed.
Final: `core_gloss.json` ~1733 entries, golden suite **1794/1794**, census
**341/341**, artifact 32,738 lemmas @ 465 KB, token-weighted coverage Caesar 95% /
Aeneid 89%. `npm test` (22+81+1794+341) and macronizer e2e (3/3) both exit 0.

## Open threads
- **~100 rare participle verb-leaks remain** (ADJ/ADV lemmas still "to X";
  WORDS has no POS entry). Accepted residue — but a WORDS VPAR-aware fallback
  could close it: check `_verb_dump*.txt`-style output if you want the list.
- **Push the M-005 commits** when ready for GitHub Pages — nothing since `da94aca`
  is pushed; ~31 commits sit on `main` locally.
- **Engine lemmatization collisions** (wordlist maps `circa`→Circe, `est`→edo,
  `versus`→verro, `demum`→demos, `sane`→sanus): patched via core entries here,
  but the real fix belongs in the **engine repo's wordlist/lemmatizer**. The
  artifact can only paper over them per-lemma.
- **UI test coverage (M-015):** stale CI exclusion — `--grep-invert macronizer`
  in `.github/workflows/tests.yml` only drops macronizer.spec.js.
- **Engine coverage (M-013)** — Scansion.js / MorpheusAnalyzer / alignMacronized.
- **M-004 Phase 3** — accepted-names list + input-hash snapshot.

## Running / unfinished
Nothing running. The 4 cold-audit subagents launched 2026-08-08 10:07 stalled —
3 produced empty transcripts (0 bytes), the bug-hunter ran 69 probes then went
quiet mid-report; its findings were recovered from its `.output` JSONL and
applied. Don't re-launch the same panel expecting reports.

## Don't redo
- **L&S `main_notes` cross-refs leak the verb infinitive onto ADJ/ADV lemmas.**
  Guarded by the "to X" build rule + golden rows (malus/cito/potens/mortuus).
  Blanket WORDS-first is WRONG — it regressed memor/superus/saevus/certo.
- **The golden suite is self-referential for core_gloss keys** (resolve()
  short-circuits to core) — it catches regressions in the extractor, not a WRONG
  hand-curated value. Don't trust "1794/1794" to mean "all correct"; trust the
  census + spot audits.
- **Measure by corpus frequency / token exposure, not wordform count** — the
  wordform proxy is anti-correlated with text frequency (function words + single-
  form adverbs like `cito` rank ~30k/40k). `utils/token_estimate.cjs` is the
  honest measure.
- **Curation is bounded and monotone** (core_gloss 262→1733, golden 75→1794,
  artifact size ~stable). Extend by semantic area; every core entry gets a golden
  row in the SAME commit.
- **Scripts in `utils/` that write data files: use ABSOLUTE paths** — a
  require (module-relative) vs writeFileSync (cwd-relative) mismatch silently
  stranded a whole round's fixes in a repo-root file.
- **`evalExpect` must norm BOTH `got` and the expectation** — glosses ending
  "B.C." fail otherwise.
- **Don't commit** `utils/ext_tmp/`, `gloss_lemma_cache.json.gz`, or `utils/_*`
  scratch — gitignored.
- **Do NOT build a "decisions replay" state machine** (M-004/M-007) — snapshot +
  accepted-names.
