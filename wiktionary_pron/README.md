# wiktionary_pron  
  
Browser-side IPA transcription using Wiktionary's Lua pronunciation modules executed via  
[wasmoon](https://github.com/ceifa/wasmoon) (Lua 5.4 → WebAssembly).  
  
Live: https://hellpanderrr.github.io/wiktionary_pron/  
  
## Supported languages  
  
| Language | Code | Styles | Forms | Help |  
|----------|------|--------|-------|------|  
| [Latin](https://hellpanderrr.github.io/wiktionary_pron/?lang=Latin) | `la` | Classical, Ecclesiastical, Vulgar | Phonetic, Phonemic | [help](https://hellpanderrr.github.io/wiktionary_pron/help/latin.html) |  
| [Ancient Greek](https://hellpanderrr.github.io/wiktionary_pron/?lang=Greek) | `grc` | 5th BCE Attic, 1st CE Egyptian, 4th CE Koine, 10th CE Byzantine, 15th CE Constantinopolitan | Phonemic | [help](https://hellpanderrr.github.io/wiktionary_pron/help/greek.html) |  
| [Armenian](https://hellpanderrr.github.io/wiktionary_pron/?lang=Armenian) | `hy` | Western, Eastern | Phonemic, Phonetic | [help](https://hellpanderrr.github.io/wiktionary_pron/help/armenian.html) |  
| [German](https://hellpanderrr.github.io/wiktionary_pron/?lang=German) | `de` | Default | Phonemic, Phonetic | [help](https://hellpanderrr.github.io/wiktionary_pron/help/german.html) |  
| [French](https://hellpanderrr.github.io/wiktionary_pron/?lang=French) | `fr` | Default, Parisian (experimental) | Phonemic | [help](https://hellpanderrr.github.io/wiktionary_pron/help/french.html) |  
| [Spanish](https://hellpanderrr.github.io/wiktionary_pron/?lang=Spanish) | `es` | Castilian, Latin American | Phonetic, Phonemic | [help](https://hellpanderrr.github.io/wiktionary_pron/help/spanish.html) |  
| [Portuguese](https://hellpanderrr.github.io/wiktionary_pron/?lang=Portuguese) | `pt` | Brazil, Portugal | Phonetic, Phonemic | [help](https://hellpanderrr.github.io/wiktionary_pron/help/portuguese.html) |  
| [Russian](https://hellpanderrr.github.io/wiktionary_pron/?lang=Russian) | `ru` | Default | Phonetic | [help](https://hellpanderrr.github.io/wiktionary_pron/help/russian.html) |  
| [Ukrainian](https://hellpanderrr.github.io/wiktionary_pron/?lang=Ukrainian) | `uk` | Default | Phonetic | [help](https://hellpanderrr.github.io/wiktionary_pron/help/ukrainian.html) |  
| [Belorussian](https://hellpanderrr.github.io/wiktionary_pron/?lang=Belorussian) | `be` | Default | Phonemic | [help](https://hellpanderrr.github.io/wiktionary_pron/help/belorussian.html) |  
| [Polish](https://hellpanderrr.github.io/wiktionary_pron/?lang=Polish) | `pl` | Default | Phonemic | [help](https://hellpanderrr.github.io/wiktionary_pron/help/polish.html) |  
| [Bulgarian](https://hellpanderrr.github.io/wiktionary_pron/?lang=Bulgarian) | `bg` | Default | Phonemic | [help](https://hellpanderrr.github.io/wiktionary_pron/help/bulgarian.html) |  
| [Czech](https://hellpanderrr.github.io/wiktionary_pron/?lang=Czech) | `cs` | Default | Phonemic | [help](https://hellpanderrr.github.io/wiktionary_pron/help/czech.html) |  
| [Lithuanian](https://hellpanderrr.github.io/wiktionary_pron/?lang=Lithuanian) | `lt` | Default | Phonemic | [help](https://hellpanderrr.github.io/wiktionary_pron/help/lithuanian.html) |  
| [Icelandic](https://hellpanderrr.github.io/wiktionary_pron/?lang=Icelandic) | `is` | Default | Phonemic | [help](https://hellpanderrr.github.io/wiktionary_pron/help/icelandic.html) |  
| [Mongolian](https://hellpanderrr.github.io/wiktionary_pron/?lang=Mongolian) | `mn` | Default | Phonemic | [help](https://hellpanderrr.github.io/wiktionary_pron/help/mongolian.html) |  
  
## Architecture  
  
### Lua runtime (`scripts/lua_init.js`)  
  
[wasmoon](https://github.com/ceifa/wasmoon) is initialized once on page load. A custom `require`  
shim replaces the default Lua `require`:  
  
- Converts dot-separated module paths to slash-separated paths  
  (e.g. `ustring.charsets` → `ustring/charsets`)  
- Fetches `.lua` files from `lua_modules/` over HTTP  
- Executes them via `load(text)()`  
- Wraps the whole `require` in a Lua-side `memoize` to avoid redundant fetches  
  
After the runtime is ready, `loadLanguage(code)` runs `require("<code>-pron_wasm")` inside Lua  
and exposes the result as `window[code + "_ipa"]` for JS-side calls.  
  
### Lua modules (`lua_modules/`)  
  
Two categories:  
  
- **Wiktionary modules** — taken verbatim from  
  [Wiktionary pronunciation modules](https://en.wiktionary.org/wiki/Category:Pronunciation_modules)  
  and the [wiktra](https://github.com/kbatsuren/wiktra) MediaWiki compatibility layer (`mw.lua`,  
  `mw-text.lua`, `mw-title.lua`, etc.)  
- **`*_wasm.lua` wrappers** — thin adapters (e.g. `la-pron_wasm.lua`, `grc-pron_wasm.lua`)  
  that bridge the Wiktionary module API to the interface expected by `loadLanguage()`  
  
### Caching  
  
| Data | Storage | TTL |  
|------|---------|-----|  
| IPA results | `localStorage` | 7 days |  
| Audio (TTS) | IndexedDB | persistent |  
| Lexicons | IndexedDB ([localforage](https://github.com/localForage/localForage)) | persistent |  
  
IPA result caching is implemented in `scripts/utils.js` via `memoizeLocalStorage()`.  
  
### TTS (`scripts/tts.js`)  
  
- **Web Speech API** — via [EasySpeech](https://github.com/jankapunkt/easy-speech) wrapper  
- **Edge TTS** — `StreamingTTS` class, proxied through Cloudflare Workers; responses cached in  
  IndexedDB  
  
### Lexicons (`scripts/lexicon.js`)  
  
Some languages use a dictionary lookup before falling back to Lua rules. Lexicons are stored as  
compressed `.zip` files, decompressed client-side via [JSZip](https://stuk.github.io/jszip/),  
and loaded into `globalThis.lexicon` as `Map` objects. Loading is deferred until the language  
is first selected.  
  
### Other tools  
  
- [`macronizer.html`](https://hellpanderrr.github.io/wiktionary_pron/macronizer.html) — Latin  
  vowel length marking (dictionary-based)  
- `index_fengari.html` — legacy version using [fengari](https://github.com/fengari-lua/fengari)  
  (Lua 5.3 in JS), kept for reference  
  
## Dependencies  
  
| Library | Purpose |  
|---------|---------|  
| [wasmoon](https://github.com/ceifa/wasmoon) | Lua 5.4 runtime via WebAssembly |  
| [EasySpeech](https://github.com/jankapunkt/easy-speech) | Web Speech API wrapper |  
| [localforage](https://github.com/localForage/localForage) | IndexedDB/localStorage abstraction |  
| [JSZip](https://stuk.github.io/jszip/) | Lexicon decompression |  
| [pdf-lib](https://github.com/Hopding/pdf-lib) | Client-side PDF export |  
  
## Deployment  
  
GitHub Pages, no build step. All assets are static; Lua modules are fetched on demand at runtime.
