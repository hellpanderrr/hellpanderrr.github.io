
[![Ask DeepWiki](https://deepwiki.com/badge.svg)](https://deepwiki.com/hellpanderrr/hellpanderrr.github.io)

# hellpanderrr.github.io

A collection of browser-based phonetic and linguistic tools. All processing runs
client-side — no server required after initial page load.

Live site: **[hellpanderrr.github.io](https://hellpanderrr.github.io)**

---

## Tools

### [Multi-language IPA Transcriber](wiktionary_pron/index.html) | [Live](https://hellpanderrr.github.io/wiktionary_pron/index.html)
Generates IPA transcriptions using Wiktionary's Lua pronunciation modules,
executed in-browser via [wasmoon](https://github.com/ceifa/wasmoon) (WebAssembly).
For several languages, a compressed lexicon is consulted first for accuracy.

**Supported languages:** German, French, Spanish, Portuguese, Latin, Ancient Greek,
Polish, Czech, Ukrainian, Russian, Belorussian, Bulgarian, Armenian, Lithuanian, Icelandic, Mongolian

Features:
- Three transcription display modes (default, line-by-line, side-by-side)
- Text-to-speech playback (browser native + Edge TTS via Cloudflare Workers)
- PDF and CSV export
- IPA result caching (localStorage, 7-day TTL)

---

### [German IPA Generator](transcription/main.html) | [Live](https://hellpanderrr.github.io/transcription/main.html)
Pure dictionary lookup against a Wiktionary-derived German lexicon (700k+ entries).
Supports uploading a custom lexicon file.

---

### [Latin Macronizer](wiktionary_pron/macronizer.html) | [Live](https://hellpanderrr.github.io/wiktionary_pron/macronizer.html)
Adds macrons to Latin text using a predefined dictionary of unambiguous macronized
words ([`wiktionary_pron/utils/macrons.json`](https://github.com/hellpanderrr/hellpanderrr.github.io/blob/main/wiktionary_pron/utils/macrons.json)).

---

### [French Liaison Inserter](misc/french/french_liaison.html) | [Live](https://hellpanderrr.github.io/misc/french/french_liaison.html)
Inserts liaison markers into arbitrary French text using a rule-based approach
with a POS tagger from `fr-compromise`.

---

### Legacy: [Multi-language IPA Transcriber (Fengari)](wiktionary_pron/index_fengari.html) | [Live](https://hellpanderrr.github.io/wiktionary_pron/index_fengari.html)
Older version using the [Fengari](https://fengari.io/) Lua interpreter instead of
wasmoon. Latin and German only. Slower than the current version.

---

## Browser Extensions

- [YouTube Subtitles Downloader](https://chromewebstore.google.com/detail/ohaffflnoldhljinhgbfapajaechogam)
- [TabCloser](https://chromewebstore.google.com/detail/tabcloser/cpdcoloomjapfkdpnijcgecimknajloa)

---


## Repository Structure

```
wiktionary_pron/   # Main IPA transcription app (16 languages)
transcription/     # German standalone tool
misc/french/       # French liaison analyzer
index.html         # Landing portal
sitemap.xml        # SEO sitemap
```

---

## License

See [`wiktionary_pron/LICENSE`](https://github.com/hellpanderrr/hellpanderrr.github.io/blob/main/wiktionary_pron/LICENSE).





