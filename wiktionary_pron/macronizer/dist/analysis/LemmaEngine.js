/**
 * LemmaEngine.ts
 * Lemma data for Latin macronization — exact port of Python lemmas.py tables.
 *
 * Python (latin_macronizer/lemmas.py) exposes three tables used by
 * tokenization.addlemmas():
 *   - wordform_to_corpus_lemmas: wordform (ORIGINAL case) → [corpus lemmas]
 *   - word_lemma_freq:           (wordform, lemma) → treebank frequency
 *   - lemma_frequency:           lemma → corpus frequency
 * These are exported to src/data/lemma-data.json by
 * native/build/export-lemma-data.py as:
 *   { "corpus": { wordform: [[lemma, freq], ...] },   // order preserved
 *     "lemmaFrequency": { lemma: freq } }
 */
export class LemmaEngine {
    constructor() {
        /** lemma → corpus frequency (Python lemma_frequency) */
        Object.defineProperty(this, "lemmaFrequency", {
            enumerable: true,
            configurable: true,
            writable: true,
            value: void 0
        });
        /** wordform (original case) → ordered [lemma, word_lemma_freq] pairs (Python tier 1) */
        Object.defineProperty(this, "corpusLemmas", {
            enumerable: true,
            configurable: true,
            writable: true,
            value: void 0
        });
        Object.defineProperty(this, "loaded", {
            enumerable: true,
            configurable: true,
            writable: true,
            value: void 0
        });
        this.lemmaFrequency = new Map();
        this.corpusLemmas = new Map();
        this.loaded = false;
    }
    /**
     * Load lemma data from JSON
     */
    async load(data) {
        if (this.loaded)
            return;
        let json = data;
        if (!json) {
            const paths = [
                new URL('../data/lemma-data.json', import.meta.url).href,
                '/data/lemma-data.json',
                '/src/data/lemma-data.json'
            ];
            for (const path of paths) {
                try {
                    const response = await fetch(path);
                    if (response.ok) {
                        json = await response.json();
                        console.log(`[LemmaEngine] Loaded lemma data from ${path}`);
                        break;
                    }
                }
                catch (e) {
                    // Try next path
                }
            }
        }
        if (json && json.lemmaFrequency && json.corpus) {
            for (const [lemma, freq] of Object.entries(json.lemmaFrequency)) {
                this.lemmaFrequency.set(lemma, freq);
            }
            for (const [wordform, pairs] of Object.entries(json.corpus)) {
                this.corpusLemmas.set(wordform, pairs);
            }
            console.log(`[LemmaEngine] ${this.lemmaFrequency.size} lemma frequencies, ${this.corpusLemmas.size} corpus wordforms`);
        }
        else {
            console.warn('[LemmaEngine] lemma-data.json not found or malformed — lemma disambiguation degraded');
        }
        this.loaded = true;
    }
    /**
     * Tier 1: corpus lemmas for a wordform (ORIGINAL case key, matching Python).
     * Returns ordered [lemma, word_lemma_freq] pairs, or null when absent.
     */
    getCorpusLemmas(wordform) {
        var _a;
        return (_a = this.corpusLemmas.get(wordform)) !== null && _a !== void 0 ? _a : null;
    }
    /**
     * Python: lemma_frequency.get(lex_lemma, 0) — exact-key lookup, no fallbacks.
     */
    getFrequency(lemma) {
        var _a;
        return (_a = this.lemmaFrequency.get(lemma)) !== null && _a !== void 0 ? _a : 0;
    }
    /**
     * Rough existence check (used only for statistics/confidence display).
     */
    hasLemma(word) {
        return this.corpusLemmas.has(word) || this.lemmaFrequency.has(word) ||
            this.lemmaFrequency.has(word.toLowerCase());
    }
    /**
     * Get dictionary size
     */
    size() {
        return this.lemmaFrequency.size;
    }
    /**
     * Check if loaded
     */
    isLoaded() {
        return this.loaded;
    }
}
//# sourceMappingURL=LemmaEngine.js.map