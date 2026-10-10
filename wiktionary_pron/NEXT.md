# Next

_Updated 2026-10-10 — everything merged to main and deployed live_

## State
The stress-accents feature is **shipped**: engine PR #1 (merge `a446ed3`) and site
PR #10 (merge `1c8fc11`) on main, Pages deployed, live site verified serving the
new code (accent checkbox, Gentium Plus, correct PDF stacking). Final fixes:
A&G §§ 11–12 counting (`67feead`), marked-u-after-g (`fe3e23f`), popup label
acute (`b5ccdf7`), PDF GPOS stacking (`4b9ceaa`, M-030). Suites green: engine
jest 60/60, gold 98.86%, parity EXACT; site 2075 gloss + 348 census + e2e.

## Open threads
- ISSUES.md H-002, H-003 and M-023m `meneni` still need owner decisions.
- Catullus blocker counts from `gold/catullus/iambic/` unreliable until re-binned
  (`test/catullus-meter-ab.mjs`; thresholds now dimeter-aware).
- If prose reading selection is ever fixed, re-run `npm run test:accent --update`;
  lever order for >97.94% is in M-027/M-029.

## Running / unfinished
- `python -m http.server 8000` still running (PID 12644) — kill with
  `taskkill //PID 12644 //F` if it lingers.
- Merged branches still checked out (`feat/macronizer-stress-accents` site,
  `feat/stress-accents` engine) — safe to delete.
- Deploys are manual: `gh workflow run jekyll-gh-pages.yml --ref main`.

## Don't redo
- **Gentium Plus** for macronizer Latin text/PDF — the text is correct Unicode;
  don't regenerate it.
- **PDF export draws marks manually** (`drawWord`): pdf-lib never applies GPOS.
  Don't simplify back to `page.drawText(word)` (M-030, e2e-pinned).
- **qu/gu counting**: u after q not closing (A&G § 11 Note 3); MARKED u after
  g/q vocalic (`árguas`); consonantal i doubles like x (`alicúius`). Pinned in
  `test/unit/stress.test.ts`; `cuique`/`tibine` are cited exceptions.
- **One mode, not classical/ecclesiastical** — rules are shared; classical
  disyllable accent and Solesmes capitals are deliberately not implemented
  (named in the help page). Flags, not a mode switch, if ever asked.
- **97.94% distinct-pair / 99.24% token-weighted** — quote both or neither;
  the corpus scan is a one-off diagnostic, not a committed test.
- **`/adv` aliases**: `DS`/`bunny` dead; `solar` works; `mimo`/`muse` time out
  on >500K transcripts.
- Don't `git add -A` at the repo root (2,416 untracked scratch files).
- e2e: `npx playwright test -c playwright.chrome.config.js` (macronizer needs
  the local server); CI excludes macronizer specs — `npm run test:e2e:macronizer`.
