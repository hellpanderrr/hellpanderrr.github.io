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
export declare class LemmaEngine {
    /** lemma → corpus frequency (Python lemma_frequency) */
    private lemmaFrequency;
    /** wordform (original case) → ordered [lemma, word_lemma_freq] pairs (Python tier 1) */
    private corpusLemmas;
    private loaded;
    constructor();
    /**
     * Load lemma data from JSON
     */
    load(data?: any): Promise<void>;
    /**
     * Tier 1: corpus lemmas for a wordform (ORIGINAL case key, matching Python).
     * Returns ordered [lemma, word_lemma_freq] pairs, or null when absent.
     */
    getCorpusLemmas(wordform: string): Array<[string, number]> | null;
    /**
     * Python: lemma_frequency.get(lex_lemma, 0) — exact-key lookup, no fallbacks.
     */
    getFrequency(lemma: string): number;
    /**
     * Rough existence check (used only for statistics/confidence display).
     */
    hasLemma(word: string): boolean;
    /**
     * Get dictionary size
     */
    size(): number;
    /**
     * Check if loaded
     */
    isLoaded(): boolean;
}
//# sourceMappingURL=LemmaEngine.d.ts.map