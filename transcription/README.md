
# German IPA Generator

A browser-based tool that converts German text into IPA phonetic transcription
using a dictionary lookup against a Wiktionary-derived lexicon (700 000+ entries).

**Live:** https://hellpanderrr.github.io/transcription/main.html

> **Note:** An updated multi-language version with rule-based fallback is available at
> https://hellpanderrr.github.io/wiktionary_pron/

---

## Features

- **700 000+ entry lexicon** — derived from Wiktionary data dumps via
  [wiktionary_ipa_phoneme_lexicons](https://github.com/bmilde/wiktionary_ipa_phoneme_lexicons)
- **Three display modes** — inline, line-by-line, and column-to-column (original ↔ IPA)
- **Custom lexicon upload** — load any plain-text lexicon file at runtime
- **Unknown word highlighting** — words not found in the dictionary are shown in red
- **No server required** — runs entirely in the browser; lexicon is loaded client-side

---

## Usage

1. Open `main.html` in a modern browser (or use the live link above).
2. Wait for the lexicon to finish loading — the status bar shows progress and entry count.
3. Type or paste German text into the textarea.
4. Click one of the three buttons:

| Button | Output |
|--------|--------|
| **Show transcription** | All words on one line, IPA inline |
| **Show transcription line-by-line** | Each word stacked: original above, IPA below |
| **Show transcription column to column** | Two-column table: original word \| IPA |

Words not found in the lexicon are displayed in **red**.

---

## Custom lexicon

You can replace the built-in German lexicon with any compatible file:

1. Click **Choose File** at the top of the page.
2. Select a plain-text file in the following format:

```
word transcription
```

One entry per line, word and IPA separated by a **space**. Entries containing `|`
(multiple pronunciations) are silently skipped.

Example:
```
Haus haʊ̯s
Hund hʊnt
schön ʃøːn
```

---

## Architecture

```
transcription/
├── main.html      # UI, rendering, and all JS logic
├── data.js        # Fallback JS-bundled lexicon (subset, loaded via <script>)
└── data/
    └── german_ipa.txt   # Full lexicon (fetched at runtime)
```

### How it works

1. On page load, `german_ipa.txt` is fetched and parsed asynchronously in chunks
   of 10 000 lines to keep the UI responsive.
2. Each line is split on the first space into `[word, ipa]`; entries with `|` are
   excluded (they contain ambiguous/multiple pronunciations).
3. The result is stored as a `Map` for O(1) lookups.
4. If `data.js` exports a `lines_from_js` array (fallback for environments where
   `fetch` is unavailable), that is used instead.
5. On transcription, each word is looked up with three fallback attempts:
   - exact match
   - lowercased match
   - lowercased with `ß → ss` substitution
6. Punctuation surrounding a word is preserved in the output.

---

## Lexicon source

The German lexicon was extracted from Wiktionary data dumps using
[bmilde/wiktionary_ipa_phoneme_lexicons](https://github.com/bmilde/wiktionary_ipa_phoneme_lexicons).

---

## Related tools

| Tool | Description |
|------|-------------|
| [wiktionary_pron](../wiktionary_pron/) | Multi-language IPA transcriber with rule-based fallback (16 languages) |
| [French Liaison Analyzer](../misc/french/french_liaison.html) | Liaison marker insertion for French text |

---
