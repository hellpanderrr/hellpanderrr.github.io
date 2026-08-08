# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repo layout & Deploy

- **This directory is a subdirectory** of the git repo `hellpanderrr/hellpanderrr.github.io` (the repo root is the parent directory `F:\projects\wiktionary_pron`). Git paths are prefixed `wiktionary_pron/`.
- **No build step.** Static site deployed on GitHub Pages from the `main` branch; live at https://hellpanderrr.github.io/wiktionary_pron/.
- To preview: serve the repo root with any static file server (e.g. `python -m http.server` or VS Code Live Server). The Lua `require` shim fetches modules via relative paths like `../wiktionary_pron/lua_modules/...`, so serve from the parent directory.

## Tests

`npm install` once in this directory (`wiktionary_pron/`), then:

```bash
npm test           # unit + IPA engine tests + gloss golden suite (Mocha + node, ~5s)
npm run test:unit  # pure JS helpers: sanitize, memoizeLocalStorage, V3/V4 lexicon decode
npm run test:ipa   # wasmoon Lua engine: exact-IPA tests + golden files (15 languages)
npm run test:gloss # macronizer gloss-extraction golden suite (utils/gloss_golden.json, ~2s)
npm run test:census # macronizer gloss frequency census (utils/gloss_census.cjs, 241 rows, ~1s)
npm run build:gloss # rebuild macronizer/glosses.tsv.gz from L&S + WORDS + core_gloss.json (~45s)
npm run test:e2e   # Playwright browser tests, excludes macronizer (~5 min: includes Russian lexicon load)
npm run test:e2e:macronizer  # macronizer smoke tests (~30s; covers first-visit and return-visit wordlist paths)
npm run test:coverage   # real coverage: c8 (unit/IPA) + opt-in V8 e2e collector → merged % (see Testing traps)
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

## Self-correcting notes (mistakes made and fixed — don't repeat them)

Each of these cost real debugging time in past sessions. Check this list before "fixing" related symptoms.

**Testing traps**
- **Never shim `document` in `scripts/tests/setup.cjs`** — wasmoon's Emscripten glue uses `typeof document` for environment detection and dies with "Invalid URL" under Node. Shim it per-test-file only in suites that don't load wasmoon (see `unit/lexicon_decode.test.js`).
- **Lexicon test words must be letters only.** Every lookup path strips `[^\p{Letter}\p{Mark}-]` — synthetic words like `word000042` contain digits, get cleaned to `word`, and silently never match. Cost a failed "language isolation" test until spotted.
- **Macronizer words now render as REAL text** (Phase 1, `54d425e`): `setDisplay` syncs `textContent` AND `content`. Assert `content` for exports/aria (still the machine source), but the output is selectable textContent now. The transcriber's line mode still paints via `attr(content)`, so that page's `.ipa` text remains empty.
- **Coverage: `npm run test:coverage`** (c8 unit/IPA + opt-in `COVERAGE=1` V8 collector `e2e/coverage-collect.spec.js` → `coverage-merge.mjs`). The collector drives desktop paths (Escape, outside-click, multi-line undo, unknown-word, scansion, dark-mode chip) + touch/sheet paths via a SECOND PAGE in the SAME context with CDP touch emulation (`Emulation.setTouchEmulationEnabled` flips `(pointer: coarse)`; shares IndexedDB — no second wordlist parse). Measured 2026-08-06: **61.9% stmts**, macronizer.html 71.6%. Re-measured 2026-08-07: **66.4% stmts**, macronizer.html **78.2%**, Scansion.js 85%, alignMacronized 74%, MorpheusAnalyzer 55%.
- **Every macronizer e2e test used to re-parse the 812k wordlist in its fresh context** (~30–60s each; 8/CI run). As of 2026-08-07, editing.spec.js and popup-check.spec.js are `serial` with one shared page (one parse per file; the touch test still opens its own hasTouch context and pays its own). Prefer EXTENDING existing tests over adding new ones. And `--grep-invert macronizer` in CI only excludes `macronizer.spec.js` — editing/popup-check (wordlist-heavy) still run in CI (exclusion is title-based + stale).
- **E2E must wait for `#lang` to be enabled before any interaction** — `main.js` top-level-awaits the wasmoon engine; clicking earlier hits elements with no listeners attached. Symptom: clear/dark-mode/persistence tests fail with stale values. 2026-08-05: recurred on **macronizer.html**, where the gate is `#macronize_btn` being enabled — the dark-mode test clicked straight after `goto()` and was intermittently flaky (60s timeout, passed on retry). ✅ enforced by the readiness wait in `e2e/macronizer.spec.js`.
- **Browser Latin ≠ Node Latin**: the browser flow macronizes input first (provinciarum → prōvinciārum), so e2e IPA expectations carry length marks that the Node suite's don't.
- **RU/UK stress-transfer skips multi-form dictionary entries by design** — test it with a single-form word (голова → голова́), not вода (record "во́да, вода́" has a comma → skipped).
- **`scripts/tests/init.js` was silently cwd-dependent** — its `fs.readFile` resolved `../../lua_modules/...` against `process.cwd()`, so the IPA suite only ran from `scripts/tests/`. Fixed 2026-08-06 by anchoring `LUA_ROOT` to the module path; keep it cwd-independent (coverage runs it from the repo root).

**Dictionary-gloss traps** (2026-08-07, M-005 research)
- **Perseus tag gender is at index 6, not index 3.** `n-s---fn-` → gender is `tag[6]` (`f`), `tag[3]` (`s`) is number/subcategorization. Reading `tag[3]` makes gender always empty and silently collapses (lemma|POS|gender) to (lemma|POS).
- **WORDS (`whitakers-words`) parses only the bare base and returns homograph-1** — it mis-keys numbered lemmas (`paro2`→"prepare", `acceptor2`→"receiver", `virosus2`→"having strong taste", `sustentaculum`→"nourishment"). L&S keyed by the *exact numbered headword* is correct. **Prefer L&S-exact-key → L&S-fallback → WORDS**, never WORDS-first for homographs.
- **L&S `senses[0]` is the clean primary definition** — don't over-split it. Strip only the leading multi-token abbrev (`V. a.,`/`Lit.,`/`V. inch. n. [..],`), split on `;:`, strip author-citations (`Plaut|Cic|Liv|...`), reject crossrefs (`init./fin./v.the foll.art.`/`q.v.`) and grammar fragments (`Part.`/`Sup.`/`Gen.`/`In gram`). `senses` can contain nested lists (subsections `Lit./Esp./Transf.`) — take first usable string. `ABBR` regex must drop `\b` before `.` (a `.`→space is no word boundary).
- **Source of truth for the rule + measured numbers:** `_probe_refined.cjs` (NOT `_probe_final.cjs`), M-005 in `docs/ISSUES.md`. The refined pipeline fixes 6 systemic errors the first-clause approach shipped: POS-gated verb bonus (nouns/adjectives must not reward `to X` clauses — `acus`→"to embroider" was a needle), spurious-homograph skip (`lemmaN` form-set identical to bare twin → prefer bare-key, else `paro2`→"make equal" for a *prepare* verb), bare-capital-adjective recognition ("Useful"/"Empty"/"Desolate" open L&S adjective senses), primary-first + strict-higher-score + earlier-tiebreak, POS-aware `main_notes "v. X"` cross-ref recursion, and fragment blockers (scope-labels like "Of persons.", etymology context "root div-, to gleam", dangling-"hence"). Audited at **99.1% usable / 0.9% wrong** on a 120-row holdout; 84.7% coverage, 476 KB gz.
- **L&S usage-scope labels ("Of persons.", "Of things.") are section headings, not definitions** — they carry a sub-sense's scope, not the lemma's meaning (`aequalis`→"Of persons." was the audit's only WRONG row). Reject them before scoring.
- **`fetchAsset(path)` always appends `.gz`** — pass the `.tsv` base name for `glosses.tsv.gz` (`fetchAsset('macronizer/glosses.tsv')`). ✅ enforced by the popup e2e gloss test. (More in `docs/LESSONS.md`.)
- **The popup gloss lookup must be EXACT-KEY-FIRST** — stripping the homograph number before lookup makes `populus2`→"the people" (should be "poplar"), silently defeating the feature. ✅ enforced by the popup e2e `popule`→poplar test. (More in `docs/LESSONS.md`.)
- **Case-collision: wordlist "Alius" = the pronoun "other", capitalized** — it collides with L&S proper-noun `Alius1` ("native of Elis"). Guard: capitalized wordlist lemma + capitalized L&S homograph-1 + numbered sibling exists → resolve the sibling. ✅ in `build_glosses.cjs`. (More in `docs/LESSONS.md`.)
- **Real-text stress test (Caesar passage) is the quality gate for common words** — it caught 4 systematic bugs (quantifier/interrogative openers need `\b`, grammar-note density penalty, era-preference on the RAW clause, primary-first + terse pass). Full detail in `docs/LESSONS.md`.
- **A second stress text (Aeneid) found 11 MORE wrong glosses the 120-row "99.1% usable" holdout missed.** The holdout measured *fragment-ness* (well-formed English) on an unstratified sample — it structurally could not see `terra`→"the sea" as wrong. Lesson: sample by frequency, and test more than one register. The fix was a **gate-then-rank restructure** (2026-08-08, `93d1cef`): hard per-clause rejection gates, then score → latinCount → sense-order → runTokens. Guarded by `utils/gloss_golden.json` (75 rows, `npm run test:gloss`).
- **The gloss "common words" were measured by WORDFORM COUNT, which excludes the failing stratum.** 2026-08-08: a 79-word top-frequency check found the function-word/closed-class ~40% wrong (`autem`→"the parent of all evil", `et`→"used for et...et", `sum`→"to pass, elapse") while audits claimed "99.1% usable." Wordform count is anti-correlated with text frequency (`et`/`in`/`cum` rank ~30k of 40k lemmas). **Measure by corpus frequency, not morphological richness.** Fixed with `utils/core_gloss.json` (pre-resolve override, now **1587 entries** after a 14-round curation loop — closed class + homograph-inverted words + etymological-primary verbs/nouns + proper-noun truncations + abstract/legal/military/body/weather terms; supports explicit-null → fail-safe "—") + WORDS-first for the 157 closed-class lemmas + `utils/gloss_census.cjs` (341 frequency-stratified rows, `npm run test:census`, wired into `npm test` + CI). Closed class went 38% → 100% correct (341/341). Golden suite 75 → **1651 rows** (every core key needs a golden row — enforced). Artifact 464 KB (unchanged by curation). Full detail in `docs/LESSONS.md` + `docs/ISSUES.md` M-005.
- **The gloss build memoizes resolve()/wGloss() per lemma** — the wordlist is 673k rows over ~40k unique lemmas, and resolve() is pure per lemma (keyed by exact lemma string, case-sensitive for the collision guard). 841s → 50s, byte-identical artifact.
- **Corpus read-through audit (M-018, 2026-08-08) fixed 8 systematic classes** a grep probe would have missed. Read L&S in bulk (`lemma|raw|artifact` TSV), not grep. Key fixes now in `build_glosses.cjs`: `de Or` strip needs `\bde`+separator (bare regex matched "aside or"); isGlossRun capital-accept was DEAD CODE (toks lowercased before `/^[A-Z]/`) — now checks original case but EXCLUDES etymology language fragments ("Erse, aile"); scoreGloss run/adj shape tests + tail penalties run on a paren-stripped `shape` ("magnitude (class.)" no longer +3 then −4/−2); article-opened + 0-enCount + ≥3 non-English = Latin quote (P3 gate); text-critical notes gated (P4); citation author lists extended + book-part residue strip (P6); WORDS-first fallback for common V/N rescued +976 lemmas (P8). Current: core **1836**, golden **1896**, census **348**, artifact **33,679 lemmas / 471 KB**. Full detail: `docs/ISSUES.md` M-018 + `docs/LESSONS.md`.

**Macronizer / Morpheus traps** (2026-08-05)
- **Morpheus returns `"accented_stem,lemma"`** — e.g. `currito_,curro`. The comma must be stripped from the *accented* form (Python does `accented.split(",")[0]`, `postags.py:434-436`). Keeping it corrupts `accentedUnderscore`, breaks DP alignment, and silently mis-macronizes every out-of-wordlist word. Fixed in `MorpheusAnalyzer.parseAnalysisLine`.
- **`WordlistEngine.addEntry` must invalidate `entriesCache`** — `ensureAnalyzed` caches the *empty* lookup for a missing word, then Morpheus writes the row; without invalidation `getAccents` re-reads the stale empty cache and falls through to the `tag_to_endings` guess. This is why `currito` came out `currītō` on first visit.
- **Don't byte-grep `cruncher.data` for filenames** — the preload manifest lives in **`cruncher.js`** (`{"files":[...]}` with offsets), not in the `.data` blob. Grepping the blob returns 0 hits for files that *are* packed, which sent a whole session down a false "missing stemlib" trail. Verify by reading the manifest and `cmp`-ing byte ranges.
- **The cruncher defaults to GREEK.** `morpheus_init()` only sets `MORPHLIB`; you must call `morpheus_set_language(32768)` (LATIN) before `morpheus_analyze`, or it looks in `stemlib/Greek/` and returns 0 analyses for *every* word — including trivial ones like `aqua`. Native equivalent: the `-L` flag. A probe that skips this "proves" Morpheus is broken when it isn't.
- **Don't run `build-morpheus-wasm.sh` against a read-write mount of the repo** — it does `rm -rf stemlib/Greek` and will delete 711 tracked files from your working tree. Mount read-only or copy first.

**Code traps**
- **Regex char classes with `-` between Unicode literals form ranges**: `[^\p{L}\p{M}'’-‿]` parsed `’-‿` as U+2019–U+203F and stripped ASCII hyphens from every word. Put `-` last in the class. (Was a live bug in `sanitize()` for years.)
- **`#header > a > i` selects the HOME link's icon** — the dark-mode toggle on macronizer.html restyled the wrong button for this reason. Use `#dark_mode i`.
- **Duplicated language lists in `main.js` drift**: `lang === "Lituanian"` (typo, missing h) appears in several copies of the multi-value language list — Lithuanian silently loses features in some modes. If touching those lists, extract one shared constant.
- **Cloudflare Workers kill a request at a hard ~21s wall, not a clean error.** Under concurrent load a single worker's synthesis jobs contend for CPU and trip this ceiling → one job per burst wedges ~21s then dies (`000` / truncated audio). This made the 6-proxy TTS farm "rot" identically; it's a platform throttle, not per-worker config. Fixes (in `tts.js`): a **per-worker client timeout** (~9s via `Promise.race`) so a hung worker fails fast and the rotator moves on instead of waiting out the ~21s kill; and **shuffle the farm per call** so concurrent requests spread instead of piling onto the least-recently-used worker. Worker side (CF `silent-unit-b6ca`): reject on socket close before `turn.end` (the promise was hanging forever) and retry with fresh `Sec-MS-GEC`/`ConnectionId`; keep `Sec-MS-GEC-Version` in step with the current Edge release (`…3650.75` → `…3650.96`).

**Macronizer UI traps**
- **`attr(content)` is not just the text painter — it also hosts the `ambig`/`unknown` highlights.** `.ipa::before { content: attr(content) }` (`css/style.css:451`) draws the word text; the yellow/red flag backgrounds live on the *same* pseudo-element. If you move text to `textContent` without moving the highlights to the span itself, the flags silently collapse. See `docs/EDITING-OVERHAUL-PLAN.md`.
- **Do NOT build a "decisions replay" state machine for persistence.** A 4-member council (classicist, product-framer, adversarial architect, plain-language) rejected it: a typed edit has nothing to replay onto; "form still in candidate set" kills exactly the hand-fixes it should protect (a fix exists *because* the form is outside the set); surface+lemma keys over-apply to every occurrence; unknowns have no lemma/candidate set so the anchor degenerates; stored lemmas go stale. Use **snapshot (keyed by demacronized-input hash) + a surface-keyed accepted-names list** — strictly more robust, ~15% of the complexity. Full reasoning: `docs/EDITING-OVERHAUL-PLAN.md` "Rejected (v1)" section.

**IndexedDB performance (measured in Chromium, 100k rows)**
- Row-per-entry `put()` with a secondary index is the killer: ~58s/100k. `durability: 'relaxed'` changes nothing (already default). Grouping by unique key: 1.8×. **Packing ~1000 rows per record: 20×** (2.8s/100k). This is why both the macronizer wordlist and the app lexicons use sorted range-chunk records.
- **Structured-cloning big objects is the persist wall time** — storing each chunk's payload as one JSON string (parse on read) cut the French lexicon persist ~3× to ~11s.
- **Write the meta record last** so an interrupted persist reads as unpopulated. And **show the user that the background save is running** — invisible saves get interrupted by reloads, which looks like "caching never works" (that exact bug report happened).

**Git traps (repo layout)**
- `git checkout <branch> -- <file>` **stages** the restored file — follow with `git restore --staged` if you want it unstaged.
- The git repo root is the parent directory; `.github/workflows/` and `.gitignore` live there, not here.
- GitHub Pages deploys from `main` only — work on other branches is invisible in production until merged.

## Work-in-progress state (as of 2026-07-27)

Uncommitted local work was split into stashes on `main` (with a full backup on branch `wip-everything`):

| Stash | Contents |
|-------|----------|
| `french-liaison` | Liaison preprocessing/tooltips in `main.js`, new `scripts/liaison.js`, liaison styles in `css/style.css`, checkbox in `index.html` |
| `portuguese-support` | Portuguese in `main.js` dict/multi-value lists, PT lexicon fallback in `utils.js`, PT entry in `lexicon.js` |
| `help-pages-and-fixes` | Stripped-down help pages (superseded by remote versions pulled later) + `pdf_export.js` local font-path fix |
| `utils-scripts-and-tests` | Python/CJS lexicon build scripts and Lua verify tests in `utils/` |

`wip-everything` also holds large generated lexicon data files in `utils/` that were never committed to `main`. Note: parts of `main.js`/`utils.js`/`liaison.js`/`lexicon.js` currently on `main` may not include these stashed features until the stashes are applied.

### Update 2026-07-28

Branch `macronizer` (pushed to origin, **not merged to `main`** — GitHub Pages still serves the pre-macronizer site) now carries, on top of the stash situation above:
- the macronizer page + WASM engine (`macronizer/dist/`, synced from the `latin-macronizer-wasm` repo's `macronizer-ui-support` branch — never hand-edit `dist/`)
- the full test infrastructure (see Tests section) + CI workflow
- range-chunk IndexedDB stores for both the macronizer wordlist (first visit 10min → ~10s) and the app lexicons (return visits skip parsing)
- `e2e/pending-features.spec.js` still holds skipped acceptance tests for the stashes

Applying the `french-liaison`/`portuguese-support` stashes onto this branch will conflict lightly in `main.js` (a prefetch block was added to `transcribe()`) and `lexicon.js` (chunk-store layer added) — resolve keeping both.
