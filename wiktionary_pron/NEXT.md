# Next

_Updated 2026-08-09 — branch `main`_

## State
M-005 (word-popup glosses) is shipped and verified. An **LLM everyday-gloss
layer** (M-021c, `49e5cf5`) now sits between core_gloss and L&S: 5,916
freq≥30 lemmas get correct everyday primaries (neco→"to kill" not "drown",
sperno→"to despise", levo2→"to smooth"), fixing L&S's literal/passive opening.
none-rate 7.5%→5.6%, total 94.4%. `npm test` exit 0 (22+81+1981+348), macronizer
e2e 3/3. LLM recipe in memory `llm-batch-gloss-layer` + `docs/ISSUES.md` M-021.

## Open threads
- **193 golden-covered lemmas still show L&S literal** (veho→"be carried",
  invenio→"find"). The gate checks L&S substrings; re-baselining needs semantic
  synonym-buckets authored from the headword (not the LLM output), else rubber
  stamp. Start: `utils/gloss_golden.json` + the 193 in `docs/ISSUES.md` M-021.
- **~70 audited-but-skipped BAD glosses** (invented nuance, homograph conflation)
  — flagged but not fixed (auditor ~50% precise). Review list:
  `tmp/_llm_audit_out.json`.
- **~100 rare participle verb-leaks** (M-017 residue) — low priority, rare words.
- **Push M-005 commits to GitHub Pages** — nothing since `da94aca` pushed; ~60
  commits on `main` locally.
- **Engine lemmatization collisions** (circa→Circe, est→edo) — patched via core,
  real fix in engine repo. **UI test coverage (M-015)**, **engine coverage
  (M-013)**, **M-004 Phase 3** accepted-names list.

## Running / unfinished
Nothing running. Scratch in `tmp/` (gitignored): `_llm_batch_out.json` (1,932
gen), `_llm_gen2_out.json` (4,511 gen), `_llm_audit_out.json` (238 BAD flags),
`_llm_batch_fixed.json` (corrected), `llm_glosses.tsv` (merged). Generator:
`tmp/_llm_gen2.cjs`; auditor: `tmp/_llm_audit.cjs` (concurrency 10, per-call resume).

## Don't redo
- **No single source beats L&S for the everyday primary** — measured: Lewis
  Elementary 5.8% on golden, WORDS-first-V ~25-30% worse (homograph collisions),
  kaikki net-negative. The LLM is the only reliable everyday-primary source.
- **LLM audit is a FILTER, not a verdict** — ~half its BAD flags are false
  positives (rejects pareo=obey, prefers synonyms). Apply only objective fixes
  (conjugated slip = verb gloss lacking "to "); review the rest by hand.
- **Rotator handles concurrency 10** (c8's ~80% ECONNREFUSED was transient
  spread-account exhaustion). Write checkpoint after EVERY call for exact resume.
- **Golden-covered lemmas keep L&S by design** — don't let the LLM override
  them; re-baselining is the deferred semantic-gate work.
- **Golden/core monotone rule stands** — every new core key needs a golden row
  in the SAME commit (nolo was a census catch).
- **`isSpurious` uses DUAL signature** (form+accent AND form+tag). **~90
  unresolvable homographs are byte-identical paradigm duplicates** — curate by
  judgement, never collapse numbered→bare. **All `_*` scratch lives in `tmp/`**.
- **Do NOT build a "decisions replay" state machine** (M-004/M-007).
