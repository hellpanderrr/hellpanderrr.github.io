# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repo layout & Deploy

- **This directory is a subdirectory** of the git repo `hellpanderrr/hellpanderrr.github.io` (the repo root is the parent directory `F:\projects\wiktionary_pron`). Git paths are prefixed `wiktionary_pron/`.
- **No build step.** Static site deployed on GitHub Pages from the `main` branch; live at https://hellpanderrr.github.io/wiktionary_pron/.
- To preview: serve the repo root with any static file server (e.g. `python -m http.server` or VS Code Live Server). The Lua `require` shim fetches modules via relative paths like `../wiktionary_pron/lua_modules/...`, so serve from the parent directory.

## Tests

`npm install` once in this directory (`wiktionary_pron/`), then:

```bash
npm test           # unit + IPA engine tests (Mocha, ~3s)
npm run test:unit  # pure JS helpers: sanitize, memoizeLocalStorage, V3/V4 lexicon decode
npm run test:ipa   # wasmoon Lua engine: exact-IPA tests + golden files (15 languages)
npm run test:e2e   # Playwright browser tests, excludes macronizer (~5 min: includes Russian lexicon load)
npm run test:e2e:macronizer  # macronizer smoke tests (~30s; covers first-visit and return-visit wordlist paths)
npx playwright test -g "Latin"   # run a single e2e test
```

Golden files: `scripts/tests/golden/golden.json` holds expected IPA for ~50 word/language pairs. After an *intended* engine change (e.g. updating a Lua module from Wiktionary), regenerate with `cd scripts/tests && node golden/generate.js` and review the diff. Czech is Node-incompatible (module load fails under the test shim) — covered by e2e instead.

`e2e/pending-features.spec.js` holds skipped acceptance tests for the stashed french-liaison and portuguese-support features — un-skip when applying those stashes.

Notes:
- `scripts/tests/setup.cjs` shims `localStorage` for Node (utils.js touches it at import time). Do **not** shim `document` there — wasmoon's Emscripten glue uses its presence for environment detection.
- The e2e server serves the **parent** directory (repo root) because the Lua require shim fetches `../wiktionary_pron/lua_modules/...` relative to the page URL.
- E2E tests must wait for `#lang` to be enabled before interacting — main.js top-level-awaits the wasmoon engine and attaches all listeners only after.
- The browser Latin flow macronizes input before IPA (provinciarum → prōvinciārum), so e2e Latin expectations differ from the Node suite's.
- CI: `.github/workflows/tests.yml` (repo root) runs both suites on push/PR.

## Architecture

### Entry flow

1. `index.html` loads `scripts/main.js` (ES module) which imports everything else.
2. On page load, `lua_init.js` initializes the **wasmoon** Lua 5.4 VM. It installs a custom Lua-side `require` shim:
   - Converts dot-separated paths (e.g. `ustring.charsets`) to slash-separated (`ustring/charsets`)
   - Fetches `.lua` files from `lua_modules/` over HTTP (or filesystem in tests)
   - Memoizes all requires via a Lua `memoize` wrapper to avoid redundant fetches
3. `loadLanguage(code)` runs `require("<code>-pron_wasm")` inside Lua, which loads the Wiktionary pronunciation module and exposes it as `window[code + "_ipa"]`.
4. When the user hits "Show transcription", `main.js` → `getIpa()` (memoized in localStorage) → `get_ipa_no_cache()` in `utils.js`.

### IPA Router (`utils.js`)

`get_ipa_no_cache(text, args)` is the central routing function. `args` is a semicolon-delimited string `"Language;Style;Form"` (e.g. `"Latin;Classical;Phonetic"`).

The `ipaHandlers` object maps each language to a handler function that:
- Receives `{ cleanText, lang, langStyle, langForm }`
- Optionally consults a lexicon (`lookupInLexicon()`)
- Calls the appropriate Lua-generated function (e.g. `window.la_ipa.convert_words(...)`)
- Applies language-specific post-processing

**Language handler groups:**
- **Complex handlers** (Latin, Portuguese, Spanish, Greek, Armenian, Ukrainian, Russian, Italian) — bespoke logic per language
- **Direct generation** (Belorussian, Bulgarian, Polish, Mongolian) — no lexicon fallback
- **Lexicon lookup + generation** (German, French, Czech, Lithuanian, Icelandic) — try dictionary first, fall back to Lua rules

### Lua Modules (`lua_modules/`)

Two categories:
- **Wiktionary modules** — verbatim from en.wiktionary.org (pronunciation modules like `la-pronunc` → inside `la-pron_wasm.lua` via require). Also MediaWiki compat layer: `mw.lua`, `mw-text.lua`, `mw-title.lua`, `ustring/`, `debug/`, etc.
- **`*_wasm.lua` adapters** (16 languages) — thin wrappers that bridge the Wiktionary module's API to the interface expected by `loadLanguage()`. Each requires `mw`, the language's pronunciation module, and exports a function like `convert_words(...)` or `IPA(...)` that JavaScript calls via `window[code + "_ipa"].functionName(...)`.

Example: `la-pron_wasm.lua`:
```lua
local m_IPA = require("IPA")
local lang = require("languages").getByCode("la")
-- exports convert_words(word, phonetic, eccl, vul)
```

### Lexicons (`scripts/lexicon.js`)

Some languages use dictionary lookup as a faster/more-authoritative source than Lua rules:
- **German, Czech, French, Lithuanian, Ukrainian, Russian, Icelandic, Portuguese**
- Stored as compressed `.zip` files in `utils/`, each containing a `lexicon.json`
- Decompressed client-side via JSZip, loaded into `OptimizedV3Lexicon` (a `Map` wrapper)
- **V3/V4 prefix compression**: entries stored as `[prefix_len, suffix, value]` triples — the key is reconstructed incrementally (`currentKey.substring(0, prefixLen) + suffix`). V4 format for RU/UK indexes the stressed vowel position instead of storing IPA.
- Parsing yields to the browser via `setTimeout(0)` to keep UI responsive during large loads (500k+ entries for Russian).
- **Chunked IndexedDB store** (`ChunkedLexicon`): decoded entries persist once as ~1000-word sorted range-chunk records. First visit parses the zip, serves from memory, and persists chunks in the background; return visits skip download+decode entirely and load only chunk *keys*. Lookups stay synchronous — `transcribe()` in `main.js` calls `lexicon.prefetch(words)` (async, pulls the needed chunks) before the sync `get()` calls run. Prefetch normalization must mirror `lookupInLexicon` (strip non-letters, retry lowercase). The zip filename in `LEXICON_LANGUAGES` acts as the version key — renaming the file invalidates stored chunks.

### Caching Strategy

| Data | Storage | TTL | Mechanism |
|------|---------|-----|-----------|
| IPA results | `localStorage` | 7 days | `memoizeLocalStorage()` in `utils.js` — wraps any function, supports background refresh near expiry |
| Lexicon ZIPs | IndexedDB (localforage) | persistent | `fetchWithCache()` in `utils.js` — caches full HTTP responses |
| TTS audio (Edge) | IndexedDB (raw) | persistent | `IndexedDBCache` class in `tts.js` — keyed by voice+rate+pitch+text hash |

### TTS (`scripts/tts.js`)

Two engines:
- **Browser** (Web Speech API via EasySpeech wrapper) — fast, limited voices
- **Edge** (`StreamingTTS` class) — higher quality via Microsoft Edge TTS API proxied through Cloudflare Workers. Caches audio blobs in IndexedDB. Auto-falls back through a pool of 6 worker endpoints with retry logic.

### File-by-file overview

| File | Role |
|------|------|
| `scripts/main.js` | UI controller — event handlers, DOM manipulation, transcription modes (default/line/column/sideBySide), pre-processing (liaison, macrons, stress marks), cycle-through-alternative-IPA clicking, dark mode, export triggers |
| `scripts/lua_init.js` | Wasmoon engine init, custom Lua `require` shim, `loadLanguage()` |
| `scripts/utils.js` | `get_ipa_no_cache()` router, `ipaHandlers`, `memoizeLocalStorage()`, `fetchWithCache()`, helpers (`sanitize`, `loadJs`, `loadFileFromZipOrPath`) |
| `scripts/lexicon.js` | Lexicon download → decompress → parse V3/V4 → expose as Map-like interface |
| `scripts/tts.js` | Dual-engine TTS (Browser + Edge StreamingTTS with Cloudflare Workers) |
| `scripts/languages.js` | Language configs (styles, forms, langCode, ttsCode) |
| `scripts/pdf_export.js` | Client-side PDF via pdf-lib (3 layout modes, fonts from `fonts/`) |
| `scripts/csv_export.js` | Client-side CSV export |
| `scripts/liaison.js` | French liaison marker insertion (nlp via fr-compromise) |
| `scripts/macronizer.js` | Latin vowel-length dictionary lookup |
| `scripts/dynamic_meta.js` | SEO meta tag updates per language |
| `scripts/optimized_lexicon.js` | Alternative lexicon loader |
| `scripts/lexicon_loader_worker.js` | WebWorker for lexicon parsing |
| `lua_modules/*_wasm.lua` | Per-language adapter shims |
| `lua_modules/` (rest) | Wiktionary Lua modules + MediaWiki compat layer |
| `help/*.html` | Static help pages per language |
| `css/style.css` | All custom styles (dark mode, popups, liaisons) |

### Key patterns

- **No bundler, all ES modules** loaded via `<script type="module">` in the browser.
- **CDN dependencies** are loaded dynamically via `loadJs()` or static `<script>` tags: wasmoon, localforage, EasySpeech, JSZip, pdf-lib, fontkit, fr-compromise.
- **Dark/light theme** toggled via `body.dark_mode` class — all components must support both.
- **Async yielding** during long operations: `await wait(1)` / `await new Promise(r => setTimeout(r, 0))` to keep the UI thread responsive.
- **Multiple IPA values** for a word are stored in `all_values` HTML attribute and cycled on click.

## Work-in-progress state (as of 2026-07-27)

Uncommitted local work was split into stashes on `main` (with a full backup on branch `wip-everything`):

| Stash | Contents |
|-------|----------|
| `french-liaison` | Liaison preprocessing/tooltips in `main.js`, new `scripts/liaison.js`, liaison styles in `css/style.css`, checkbox in `index.html` |
| `portuguese-support` | Portuguese in `main.js` dict/multi-value lists, PT lexicon fallback in `utils.js`, PT entry in `lexicon.js` |
| `help-pages-and-fixes` | Stripped-down help pages (superseded by remote versions pulled later) + `pdf_export.js` local font-path fix |
| `utils-scripts-and-tests` | Python/CJS lexicon build scripts and Lua verify tests in `utils/` |

`wip-everything` also holds large generated lexicon data files in `utils/` that were never committed to `main`. Note: parts of `main.js`/`utils.js`/`liaison.js`/`lexicon.js` currently on `main` may not include these stashed features until the stashes are applied.
