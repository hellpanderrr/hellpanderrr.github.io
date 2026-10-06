# Next

_Updated 2026-10-05 — help-page work committed on branch `help-pages-engine-verified` (PR open)_

## State
All 17 language help pages share one skeleton (TOC, About, Dialects, Forms, Glossary,
How to Read IPA, Pronunciation Guide, Mapping, **Using the Tool: Practical Notes**
`id="faq"`, Implementation Details, Common Issues, **Related Pronunciation Guides**
`id="related"`) plus search metadata (`utils/help_seo_head.mjs`); help index + macronizer
help have metadata too; sitemap has all help pages. 8 pages written new (ru uk be bg is lt mn pt),
French restructured, old pages corrected against the engine. App fixes: pt `unpack`,
ru/uk double stress, ru lowercase ы, Armenian ՛ kept by `sanitize()` (ISSUES H-001).
Czech now runs under Node (BOM removed; test shim decodes like the browser) and its page is
verified. Gates green: npm test (23 unit, 88 IPA, 2075 gloss, 348 census), full e2e 37 passed
(system Chrome config), all pages render with 0 errors / 0 broken anchors.

## Open threads
- Merge the help-page PR after review.
- **Macronizer scansion triage (M-023m, 2026-09-21) is NOT in that PR and NOT committed:**
  `wiktionary_pron/macronizer/dist/` (synced site copy with the `hoc`/`vorago` overrides) and
  the engine repo `/f/projects/latin-macronizer-wasm` (`src/core/Tokenization.ts`, `dist/`,
  `test/catullus-meter-ab.mjs`). Its docs (ISSUES M-023m triage, LESSONS 2026-09-21) are also
  still uncommitted in the working tree. Commit engine repo first, then the site dist + docs.
- ISSUES H-002 (module-internal bugs, documented only) and H-003 (Icelandic `special`
  arg, Brazilian epenthesis) need owner decisions. Czech now runs under Node.
- Prior macronizer threads (M-023m `meneni`, M-013 scansion) unchanged.

## Running / unfinished
A python http.server may still be running on port 8000 (started for the user).
Nothing else running.

## Don't redo
- Help-page IPA comes only from `scripts/tests/ipa_cli.mjs`; check with
  `verify_help_page.mjs` + `verify_issue_tables.mjs` (false positives documented in
  `docs/LESSONS.md` 2026-10-05: English labels, letter-mapping rows, hyphenated forms).
- No "Overview"/"At a Glance" sections — removed at the user's request. Prose standard:
  reference-grammar register, no snippet bait, no FAQ schema markup.
- `golden/generate.js` now covers Irish and Czech; regenerate freely and review the diff.
- e2e: Playwright's bundled browser is missing here; run
  `npx playwright test -c playwright.chrome.config.js` (system Chrome).
- Macronizer don't-redo items from the previous baton still apply (scan-based gold
  comparison; L&S headword arbitrates quantity; sync engine to site via
  `MACRONIZER_SITE_DIR=F:/projects/wiktionary_pron/wiktionary_pron/macronizer node sync-site.cjs`).
