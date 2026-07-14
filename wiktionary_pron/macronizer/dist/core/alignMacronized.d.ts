/**
 * DP alignment algorithm for macronization
 * Ported from latin_macronizer/token.py (Token.macronize method)
 *
 * This module implements edit-distance alignment between plain and accented forms
 * to determine optimal macron placement.
 */
export interface AlignOptions {
    domacronize?: boolean;
    alsomaius?: boolean;
    performutov?: boolean;
    performitoj?: boolean;
}
/**
 * Align plain text with accented text using DP edit distance
 * Returns the macronized result string (with _ markers)
 * Ported from latin_macronizer/token.py (Token.macronize method)
 */
export declare function alignMacronized(plain: string, accented: string, options?: AlignOptions): string | null;
/**
 * Main entry point: macronize a plain Latin word
 * This is a direct port of Token.macronize() logic
 */
export declare function macronizeWord(plain: string, accented: string, enclitic?: string | null, options?: AlignOptions): string | null;
//# sourceMappingURL=alignMacronized.d.ts.map