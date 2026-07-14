/**
 * EndingPatternEngine.ts
 * Pattern-based vowel length determination for Latin macronization
 * Uses suffix patterns and morphological rules
 */
export interface EndingPattern {
    suffix: string;
    replacement: string;
    posTags?: string[];
    priority?: number;
}
export declare class EndingPatternEngine {
    private loaded;
    /** Raw Python tag_to_endings: exact 9-char LDT tag → ORDERED accented endings
     *  (underscore/caret notation), straight from endings.json. */
    private rawEndings;
    constructor();
    /**
     * Python: tag_to_endings.get(tag, []) — exact-tag lookup, list order preserved.
     */
    getEndingsForTag(tag: string): string[];
    /**
     * Load ending patterns
     */
    load(data?: any): Promise<void>;
    /**
     * Check if a pattern exists for this word
     */
    hasPattern(word: string): boolean;
    /**
     * Get number of tag ending lists
     */
    size(): number;
    /**
     * Check if loaded
     */
    isLoaded(): boolean;
    /**
     * Normalize RFTagger tag format (n.-.s.-.-.-.f.b.-) to pattern format (n-s--f-)
     */
    private normalizeTag;
}
//# sourceMappingURL=EndingPatternEngine.d.ts.map