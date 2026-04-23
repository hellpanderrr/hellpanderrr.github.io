# French Liaison Analyzer

A browser-based tool that automatically detects and annotates **liaison** phenomena in French text. Paste any French text and get an interactive, color-coded view of where liaisons occur, where they are blocked, and why.

**Live:** https://hellpanderrr.github.io/misc/french/french_liaison.html

---

## What is liaison?

Liaison is a phonetic phenomenon in French where a normally silent consonant at the end of a word is pronounced when the next word begins with a vowel sound.

> `les amis` → `les‿amis` (the final *s* of *les* is pronounced)  
> `les haricots` → `les haricots` (no liaison — *haricot* has an aspirated H)

---

## Features

- **Automatic detection** — uses [`fr-compromise`](https://github.com/spencermountain/compromise) for French part-of-speech tagging
- **Rule-based engine** — covers obligatory, forbidden, and standard-register liaisons
- **Interactive markers** — hover over any marker to see the two words involved and the rule that was applied
- **Omission tracking** — blocked liaisons are highlighted in red with an explanation
- **300+ test cases** — in-browser Mocha/Chai test suite at `french_liaison_test.html`
- **No server required** — runs entirely in the browser

---

## Usage

1. Open `misc/french/french_liaison.html` in a modern browser (or use the live link above).
2. Type or paste French text into the textarea.
3. Click **Analyze**.
4. Hover over blue markers (‿) to see active liaisons; hover over red markers to see blocked liaisons.

---

## Marker types

| Marker | Color | Meaning |
|--------|-------|---------|
| `‿` | Blue | Liaison occurs here |
| ` ` | Red | Liaison is blocked here |

Both markers show a tooltip with the word pair and the rule name (e.g. *Article + Noun*, *H-Aspiré / Blocked Word*).

---

## Liaison rules implemented

### Obligatory liaisons

| Context | Example |
|---------|---------|
| Article + Noun | `les‿amis`, `un‿arbre` |
| Possessive + Noun | `mon‿ami`, `mes‿enfants` |
| Demonstrative + Noun | `ces‿arbres` |
| Pronoun + Verb | `nous‿avons`, `ils‿ont` |
| Pre-nominal Adjective + Noun | `petit‿arbre`, `grand‿ours` |
| Number + Noun | `deux‿heures`, `trois‿ans` |
| Adverb + Adjective | `très‿important`, `bien‿aimé` |
| Preposition + Noun | `dans‿un`, `sans‿effort` |

### Forbidden liaisons

| Context | Example |
|---------|---------|
| H aspiré | `les haricots` (no liaison) |
| After conjunction *et* | `et alors` (no liaison) |
| Proper nouns | `Paris est` (no liaison) |
| Singular noun + adjective | `chat adorable` (no liaison) |
| After inversion | `dit-il à` (no liaison after pronoun) |
| Special words: *oui*, *onze*, *ou* | blocked unconditionally |

### Standard-register liaisons

| Context | Example |
|---------|---------|
| Être / Avoir forms | `c'est‿un`, `il est‿impossible` |
| Modal verbs | `dois‿aller`, `peut‿être` |
| Fixed expressions | `sang‿impur`, `vingt‿et un`, `États‿Unis` |

---

## Architecture

```
misc/french/
├── french_liaison.html       # UI shell and rendering layer
├── french_liaison_test.html  # Mocha/Chai in-browser test suite
├── liaison.js                # Core rule engine (insertLiaisonMarkers)
└── liaison_old.js            # Superseded implementation (kept for reference)
```

### How it works

1. `insertLiaisonMarkers(text)` is called with raw French text.
2. [`fr-compromise`](https://unpkg.com/fr-compromise) tags each token with POS information.
3. Adjacent token pairs are evaluated through an ordered rule pipeline:
   - Hyphen handling (fixed expressions vs. regular compounds)
   - Punctuation boundaries
   - Blocked words (`BLOCK_LIAISON_BEFORE`, `BLOCK_LIAISON_AFTER`)
   - Inversion detection
   - Proper noun check
   - Phonetic gate (`LIAISON_CONSONANTS` + `VOWELS`)
   - Grammar rules (fixed expressions → mandatory word list → adjective/noun → pronoun/verb → être/avoir → plural noun)
4. The function returns `{ text, liaisons[], omissions[] }`.
5. `createInteractiveResult()` in `french_liaison.html` walks the output character by character and wraps markers in styled `<span>` elements with tooltip children.

---

## Running the tests

Open `misc/french/french_liaison_test.html` in a browser. The Mocha test runner executes automatically and displays results inline. No build step or server is needed.

Test categories:
1. **Obligatory liaisons** — determiner/pronoun/adjective/number contexts
2. **Forbidden liaisons** — H aspiré, *et*, proper nouns, singular nouns, special numbers
3. **Standard register** — être/avoir, modal verbs
4. **Phonetic transformations** — S/X→Z, D→T, F→V

---

## Dependencies

| Library | Source | Purpose |
|---------|--------|---------|
| [`fr-compromise`](https://github.com/spencermountain/compromise) | unpkg CDN | French POS tagging |
| [Mocha](https://mochajs.org/) | unpkg CDN | Test runner (test file only) |
| [Chai](https://www.chaijs.com/) | unpkg CDN | Assertions (test file only) |

---
