# Next

_Updated 2026-10-11 — fix merged (engine PR #2 `831cf70`, site PR #11 `81595ad`) and deployed_

## State
Morpheus words no longer display as their lemma (`effuget → effugo`, M-031),
live-verified. Full-prayer token test on the live page: wrong-word tokens
12 → 0, strict 99.14% → 99.49%, 11 of 16 remaining misses shared with
Accenteur (M-033). Green: engine jest 70/70, gold 98.86%, parity EXACT;
site 2075 + 348, e2e 5/5.

## Open threads
- Latin SE 27176, answer 27340: moderator cmw commented "concerned about the
  2-3% difference". Reply with per-token strict numbers from M-033 (n=3152,
  revision-labeled), never mixed with the 1140-word figures. User posts it.
- M-032: the page writes æ/œ back as ae/oe (176/192 ligature tokens) — mirror
  them from the input in `applyOrtho`, by position, like j/v.
- M-034: wire `filterAccents` into `parseAnalysisLine` (Python parity), re-measure.
- ISSUES H-002, H-003, M-023m `meneni` still need owner decisions.

## Running / unfinished
- `python -m http.server 8000` (PID 12644 on 2026-10-11). Before killing, confirm
  the PID still owns port 8000:
  `Get-NetTCPConnection -LocalPort 8000 -State Listen` → `OwningProcess`.
- Deploys are manual: `gh workflow run jekyll-gh-pages.yml --ref main`.
- Prayer harness + findings: `_sessions/2026-10-11-prayer-test/`; it reads the
  Accenteur copies from `F:/temp/lea/accenteur/` (re-fetch steps in FINDINGS.md).
- Not yet seen in a real browser: the stale-row clear on a RETURNING visit
  (only unit-tested). Check in your own Chrome: console line
  `stored Morpheus analyses are stale, clearing them`, then `effuget` → `effuget`.

## Don't redo
- **Bare-lemma Morpheus lines echo the typed word** (Python postags.py 426-436);
  `EXTRAS_VERSION` clears old rows. Pinned: `test/unit/morpheus.test.ts`, e2e.
- **Distinct-word gold (98.86%) can't see Morpheus words or wrong-word output** —
  it's a regression gate; accuracy claims come from the full-prayer test, strict.
- **Gentium Plus** + manual mark drawing in the PDF (pdf-lib ignores GPOS, M-030).
- **qu/gu counting**, **one stress mode** (no classical/ecclesiastical switch).
- **`seipsum` split** is Python-identical (dividenda on an OOV compound) — not a bug.
- `/adv`: `solar` times out on ~270K-char transcripts; `muse` works.
- Don't `git add -A` at the repo root (2,416 untracked scratch files).
- e2e: `npx playwright test -c playwright.chrome.config.js` — the default config
  needs a Playwright browser install that isn't present.
