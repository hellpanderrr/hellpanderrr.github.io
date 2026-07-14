/**
 * WordlistEngine.ts
 * IndexedDB-based wordlist for accurate Latin macronization
 * Stores exact wordform + tag → macronized form mappings from macrons.txt
 * Integrates with Morpheus for unknown words
 */
import { MorpheusAnalyzer, MorpheusAnalysis } from './MorpheusAnalyzer';
export interface WordlistEntry {
    wordform: string;
    tag: string;
    macronized: string;
    accentedUnderscore: string;
    lemma: string;
    seq?: number;
}
export declare class WordlistEngine {
    private db;
    private loaded;
    private entryCount;
    private morpheusAnalyzer;
    private loadingPromise;
    private nextSeq;
    private readonly DB_NAME;
    private readonly DB_VERSION;
    private readonly STORE_NAME;
    /** Cache of Morpheus analyses by normalized wordform (for UI display) */
    private morpheusCache;
    /** In-memory cache for getAllEntries — eliminates redundant IndexedDB cursor
     * calls across the 3+ passes (ensureAnalyzed, addLemmas, getAccents) that
     * each look up every wordform. Keyed by lowered wordform. */
    private entriesCache;
    /**
     * Initialize IndexedDB database
     */
    init(): Promise<void>;
    /**
     * Check if database is populated
     */
    isPopulated(): Promise<boolean>;
    /**
     * Get entry count
     */
    size(): number;
    /** Clear the in-memory getAllEntries cache. Call between large documents
     * to prevent unbounded memory growth — the cache repopulates on demand. */
    clearEntriesCache(): void;
    /**
     * Lookup exact macronized form for word + tag
     */
    lookup(wordform: string, tag: string): Promise<string | null>;
    /**
     * Get all entries for a wordform (for candidate generation)
     * Returns entries with accentedUnderscore populated
     */
    getAllEntries(wordform: string): Promise<WordlistEntry[]>;
    /**
     * Normalize tag format (convert dots to dashes for consistency with RFTagger)
     */
    private normalizeTag;
    /**
     * Add single entry to wordlist
     */
    addEntry(entry: WordlistEntry): Promise<void>;
    /**
     * Batch add entries (for file loading)
     */
    addEntries(entries: WordlistEntry[], onProgress?: (count: number) => void): Promise<void>;
    /**
     * Clear all entries
     */
    clear(): Promise<void>;
    /**
     * Convert macron marks to Unicode
     * ^ = breve (short vowel), _ = macron (long vowel)
     * a^ -> ă, a_ -> ā
     */
    private convertMacronMarks;
    /**
     * Clean lemma string: remove #, 1, spaces→+, -, ^, _
     * Matches Python wordlist.clean_lemma()
     */
    private cleanLemma;
    /**
     * Load from parsed macrons.txt data
     * Expected format: whitespace-separated (tab or space) columns:
     *   wordform  tag  lemma  accented
     * e.g. "a\te--------\ta\ta_"
     */
    loadFromText(text: string, onProgress?: (count: number) => void): Promise<void>;
    /**
     * Load wordlist from URL (fetch + parse)
     */
    loadFromUrl(url: string, onProgress?: (count: number) => void): Promise<void>;
    /**
     * Check if loaded
     */
    isLoaded(): boolean;
    /**
     * Close database connection
     */
    close(): void;
    /**
     * Set Morpheus analyzer for unknown words
     */
    setMorpheusAnalyzer(analyzer: MorpheusAnalyzer): void;
    /**
     * Get cached Morpheus analysis for a wordform (if available)
     */
    getMorpheusAnalysis(wordform: string): MorpheusAnalysis | undefined;
    /**
     * Check if a word has Morpheus analysis cached
     */
    hasMorpheusAnalysis(wordform: string): boolean;
    /**
     * Analyze unknown words using Morpheus and cache results
     * Ported from latin_macronizer/wordlist.py::crunchwords()
     * Produces multiple entries per word (different lemma+tag combinations)
     */
    analyzeUnknownWords(words: string[]): Promise<WordlistEntry[]>;
    /**
     * Ensure all given wordforms have entries in the wordlist.
     * For missing words, analyzes with Morpheus and caches results.
     * Matches Python Wordlist.loadwords() behavior.
     */
    ensureAnalyzed(wordForms: string[]): Promise<void>;
    /**
     * Convert a Morpheus analysis to an LDT 9-char tag
     * Ported from latin_macronizer/postags.py (parse_to_ldt)
     */
    private analysisToLdtTag;
}
//# sourceMappingURL=WordlistEngine.d.ts.map