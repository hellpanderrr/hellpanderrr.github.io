# Project

## What

A client-side static site for Wiktionary-sourced IPA transcriptions and Latin glosses (macronizer + popup). Deployed on GitHub Pages from `main`.

## People

- **Solo project** — hellpanderrr does all work, reviews, and merges.

## External systems

| System | Where it lives | Purpose |
|--------|---------------|---------|
| GitHub Pages | `https://hellpanderrr.github.io/wiktionary_pron/` | Production deploy from `main` branch |
| GitHub Actions CI | `.github/workflows/tests.yml` (repo root) | Tests on push/PR |
| Cloudflare Workers | 6-proxy TTS farm (worker names in `tts.js`) | Microsoft Edge TTS proxy |
| wasmoon Lua VM | CDN (bundled via `<script>` tag) | In-browser Lua 5.4 engine for Wiktionary modules |
| Lark (grammar) | `utils/` Python scripts | L&S XML parsing |
| Pygments + aardvark-dj | `utils/` | Formatting-layer scansion helpers |

## Data sources

| Data | Format | Location | Notes |
|------|--------|----------|-------|
| Wiktionary Lua modules | `.lua` | `lua_modules/` | Verbatim from en.wiktionary.org |
| Lewis & Short XML | `.xml` via git-lfs? | `utils/ext_tmp/` (gitignored) | 30MB, not shipped |
| WORDS (Whitaker's Words) | JSON | `utils/ext_tmp/` (gitignored) | Latin morphology |
| L&S golden fixture | JSON | `utils/ls_golden_fixture.json` (tracked) | ~95-entry subset for CI |
| Core gloss overrides | JSON | `utils/core_gloss.json` (tracked) | 1887 curated entries |
| Gloss golden suite | JSON | `utils/gloss_golden.json` (tracked) | 1960 rows for CI regression gate |
| Latin macronizer WASM | `.js` + `.wasm` | `macronizer/dist/` | Synced from `latin-macronizer-wasm` repo |

## Open questions

(None currently tracked — see `docs/ISSUES.md` for open findings.)