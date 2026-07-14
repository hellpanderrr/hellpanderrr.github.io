/**
 * Token.ts
 * Core token representation for Latin macronizer
 * Immutable token with POS tagging and macronization capabilities
 */
import type { MorpheusAnalysis } from '../analysis/MorpheusAnalyzer';
export interface TokenOptions {
    text?: string;
    tag?: string;
    lemma?: string;
    macronized?: boolean;
    macronizedText?: string;
    originalText?: string;
    accented?: string[];
    isAmbiguous?: boolean;
    isUnknown?: boolean;
    morpheusAnalyzed?: boolean;
    morpheusResults?: MorpheusAnalysis | null;
    startssentence?: boolean;
    endssentence?: boolean;
    hasenclitic?: boolean;
    isenclitic?: boolean;
    isWord?: boolean;
    isSpace?: boolean;
    startIndex?: number;
    endIndex?: number;
}
/**
 * Immutable token class representing a word in Latin text
 */
export declare class Token {
    readonly text: string;
    readonly tag: string;
    readonly lemma: string;
    readonly macronized: boolean;
    readonly macronizedText?: string;
    readonly originalText: string;
    readonly accented?: string[];
    readonly isAmbiguous?: boolean;
    readonly isUnknown?: boolean;
    readonly morpheusAnalyzed?: boolean;
    readonly morpheusResults?: MorpheusAnalysis | null;
    readonly startssentence?: boolean;
    readonly endssentence?: boolean;
    readonly hasenclitic?: boolean;
    readonly isenclitic?: boolean;
    readonly isWord?: boolean;
    readonly isSpace?: boolean;
    readonly startIndex?: number;
    readonly endIndex?: number;
    constructor(text: string, options?: TokenOptions);
    /**
     * Create a new token with updated properties (immutable update)
     */
    with(options: Partial<TokenOptions>): Token;
}
//# sourceMappingURL=Token.d.ts.map