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
    /** ~800 chunk records covering the whole wordlist, keyed by firstWord */
    private readonly CHUNK_STORE;
    /** Row-per-entry store for Morpheus-analyzed unknown words (small, grows
     * incrementally — the chunk layout is immutable after load) */
    private readonly EXTRA_STORE;
    /** Single meta record: schema/data version + entry count */
    private readonly META_STORE;
    /** Bump when the packing logic changes incompatibly. */
    private readonly SCHEMA_VERSION;
    /** Bump when macrons.txt content changes, so returning visitors reload
     * instead of keeping a stale dictionary forever. */
    private readonly DATA_VERSION;
    /** Entries per chunk. 1000 keeps a chunk ~100KB — one get() per unseen
     * wordform neighborhood, small enough to clone cheaply. */
    private readonly CHUNK_SIZE;
    /** Sorted chunk keys, loaded once per session (~800 strings). */
    private chunkKeys;
    /** Fetched chunks by firstWord — bounded by chunk count (~800); cleared in
     * clearEntriesCache() together with the per-word cache. */
    private chunksCache;
    /** Full in-memory groups map, present only in the session that parsed the
     * file. Serves lookups instantly while chunks persist in the background. */
    private memGroups;
    /** Resolves when the background chunk persist finishes (tests await this). */
    private persistPromise;
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
    private idbGet;
    /**
     * Check if database is populated with the current schema+data version.
     * A stale version (schema change or updated macrons.txt) reads as empty,
     * which makes the caller re-download and overwrite.
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
    /** Binary search the sorted chunk keys for the chunk that could contain
     * `word` (greatest firstWord <= word), fetch it, and read the group. */
    private lookupInChunks;
    private lookupInExtras;
    /**
     * Normalize tag format (convert dots to dashes for consistency with RFTagger)
     */
    private normalizeTag;
    /**
     * Add single entry (Morpheus-analyzed unknown word). Goes to the extras
     * store — the chunk layout is immutable after the bulk load, and extras
     * only ever exist for words the wordlist file doesn't contain.
     */
    addEntry(entry: WordlistEntry): Promise<void>;
    /** Normalize a parsed file entry once, before grouping. */
    private normalizeEntry;
    /** Group entries by wordform, preserving file order within each group —
     * the same order the old (wordform, seq) index cursor produced. */
    private buildGroups;
    /**
     * Batch add entries (for file loading). Packs the wordlist into ~800
     * sorted range chunks instead of 812k individual rows — measured ~20x
     * faster to persist, and lookups become one direct get() per chunk.
     */
    addEntries(entries: WordlistEntry[], onProgress?: (count: number) => void): Promise<void>;
    /**
     * Clear all stores
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
    /** Await the background chunk persist (no-op if none is running). Lets
     * tests and shutdown paths ensure durability before closing the page. */
    flush(): Promise<void>;
    /**
     * Load wordlist from URL (fetch + parse)
     */
    /**
     * Load wordlist from URL. A `.gz` URL is decompressed in the browser
     * (32MB of text ships as ~4MB); it falls back to the uncompressed file
     * if the .gz is missing or the browser cannot gunzip.
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