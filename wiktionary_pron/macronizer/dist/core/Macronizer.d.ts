/**
 * Macronizer.ts
 * Core macronization engine integrating WASM RFTagger with Latin rules
 * Orchestrates tokenization, POS tagging, and vowel length assignment
 */
import { Token } from './Token';
export interface MacronizerOptions {
    useWasm?: boolean;
    wasmModelPath?: string;
    wasmPath?: string;
    enableCache?: boolean;
    wordlistUrl?: string;
    morpheusWasmPath?: string;
}
export interface MacronizeOptions {
    macronize?: boolean;
    alsomaius?: boolean;
    performutov?: boolean;
    performitoj?: boolean;
    scan?: string;
}
export interface Statistics {
    totalWords: number;
    knownWords: number;
    unknownWords: number;
    ambiguousForms: number;
}
export interface MacronizeResult {
    original: string;
    macronized: string;
    tokens: Token[];
    taggedTokens: Token[];
    /** Word coverage fraction (0..1): proportion recognized by lemma/pattern engine.
     *  NOT a probabilistic confidence score — a word known to the lemma engine
     *  contributes 0.95, a pattern match 0.85, an unknown word 0.60. */
    confidence: number;
    processingTime: number;
    statistics: Statistics;
    scannedFeet?: string[];
}
/**
 * Main macronization engine
 * Coordinates all components for Latin text processing
 */
export declare class Macronizer {
    private tagger;
    private lemmaEngine;
    private endingEngine;
    private wordlistEngine;
    private morpheusAnalyzer;
    private useWasm;
    private cache;
    private wordlistUrl?;
    private morpheusWasmPath?;
    constructor(options?: MacronizerOptions);
    /**
     * Initialize the macronizer (load WASM module if enabled)
     */
    initialize(onProgress?: (percent: number, message: string) => void): Promise<void>;
    /**
     * Macronize Latin text
     * Main entry point for text processing
     * Uses Tokenization pipeline with DP alignment
     */
    macronize(text: string, options?: MacronizeOptions): Promise<MacronizeResult>;
    /**
     * Calculate word coverage fraction: what proportion of tokens are recognized
     * by the lemma or ending-pattern engine.  This is NOT a probabilistic
     * confidence score — it measures whether each token was even known to any
     * lookup table.  A word that hits the lemma engine gets 0.95, a word that
     * only matches an ending pattern gets 0.85, and an entirely unknown word
     * gets 0.60.  These are arbitrary labels, not Viterbi beam probabilities.
     */
    private calcCoverage;
    /**
     * Calculate statistics about the macronization
     */
    private calculateStatistics;
    /**
     * Batch process multiple texts
     */
    macronizeBatch(texts: string[]): Promise<MacronizeResult[]>;
    /**
     * Clear cache
     */
    clearCache(): void;
    /**
     * Get cache size
     */
    getCacheSize(): number;
    /**
     * Check if initialized
     */
    isReady(): boolean;
    /**
     * Destroy resources
     */
    destroy(): void;
    /**
     * Load wordlist (exposed for API — used when wordlist not loaded during initialize).
     */
    loadWordlist(onProgress?: (progress: any) => void): Promise<void>;
    isWordlistLoaded(): boolean;
    getWordlistMode(): string;
    clearWordlistCache(): Promise<void>;
}
//# sourceMappingURL=Macronizer.d.ts.map