# Next

_Updated 2026-08-07 — branch `main`_

## State
M-005 (dictionary glosses in the word popup) is **DONE, committed, verified**:
data build (`utils/build_glosses.cjs` → `macronizer/glosses.tsv.gz`, 456 KB,
85.6% of rows glossed) + client render (`r-def` column, exact-key-first
homograph disambiguation) + e2e tests. Four commits this session: `6a453cf`
(data), `5c62e5b` (client), `5ad9391` (real-text fixes), `66a16f4` (research
docs). Unit 22 passing, popup e2e 5 passing, broader e2e 11 passing (1 flaky
touch test, passes alone). Clean tree. NOT pushed.

## Open threads
- **M-005 remaining (minor):** `appello`→"To drive" is wrong (should be "to
  call") — inherent, the wordlist conflates appello1/2 under one bare lemma.
  Known and accepted.
- **UI test coverage (M-015):** stale CI exclusion unfixed —
  `--grep-invert macronizer` in `.github/workflows/tests.yml:57` only drops
  macronizer.spec.js; editing/popup-check (wordlist-heavy) still run in CI.
- **Engine coverage** — Scansion.js / MorpheusAnalyzer / alignMacronized are
  engine correctness (M-013), fix with unit tests in the **engine repo**.
- **M-004 Phase 3** — accepted-names list + input-hash snapshot (edit
  persistence). Snapshot must serialize the active-reading index.
- **Push the 3 M-005 commits** (`6a453cf` `5c62e5b` `5ad9391`) when ready for
  GitHub Pages — they're not pushed.

## Running / unfinished
Nothing running. Note: `package.json` has `whitakers-words` as a devDependency
(used by the gloss build — commit-worthy, currently uncommitted).

## Don't redo
- **Gloss extraction pipeline is settled at `_probe_refined.cjs` / `build_glosses.cjs`.**
  Do NOT regress to the first-clause approach (`_probe_final.cjs`, "88%" —
  shipped ~15% fragment glosses) or the first scoring pass (77.0% — over-
  rejected adjectives). Dead ends ruled out (advisor audits): loosening the
  accept threshold re-contaminates; the ≥2-English-words branch is near-dead-
  weight; deep-walking `senses[1+]` not worth it.
- **The `r-def` lookup must be exact-key-first** (stripping the homograph number
  makes `populus2`→"the people", defeating the feature). `fetchAsset` appends
  `.gz` — pass `macronizer/glosses.tsv`. See `docs/LESSONS.md`.
- **Real-text stress test (Caesar passage) is the quality gate** — it caught 4
  systematic bugs. Re-run `node _probe_one.cjs <words>` after any pipeline change.
- **Don't commit `utils/ext_tmp/`** (30MB L&S data) or `_probe*`/`_audit_*`
  scratch — gitignored.
- **Don't multiply e2e tests** — each fresh context re-parses the wordlist;
  extend the shared-page popup-check.spec.js.
- **CI exclusion is title-based + stale** — don't trust it to exclude wordlist
  suites.
- **Do NOT build a "decisions replay" state machine** (M-004/M-007) — snapshot +
  accepted-names.
