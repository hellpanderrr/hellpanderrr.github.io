/**
 * Scansion.ts
 * Port of latin_macronizer/scansion.py
 * Scans Latin verse using meter automata (dactylic hexameter, pentameter, etc.)
 */
export interface ScanResult {
    penalty: number;
    scansion: string;
    accented: string;
}
export type VerseEntry = [number, ScanResult[]];
export type MeterAutomaton = Record<string, [number, string, number]>;
/**
 * Generate accented forms for unknown words: mark all vowels as ambiguous (short)
 */
export declare function allVowelsAmbiguous(accented: string): string;
/**
 * Split ambiguous vowels into all possible combinations.
 * Input: ['ba_^ce_^']
 * Output: ['bace', 'ba_ce', 'bace_', 'ba_ce_']
 */
export declare function separateAmbiguousVowels(accenteds: string[]): string[];
/**
 * Split an accented form into vowel phonemes and consonant clusters
 */
export declare function segmentAccented(accented: string): string[];
/**
 * Generate possible scansions for a word given its accented forms and the following segment.
 * followingSegment: one of "V", "C", "CC", "#"
 * Returns sorted [(penalty, scansion, accented), ...]
 */
export declare function possibleScans(accentedCandidates: string[], followingSegment: string): ScanResult[];
/**
 * Scan a single verse using the meter automaton.
 * verse: [(tokenIndex, [(penalty, scansion, accented), ...]), ...]
 * Returns: { indexAccentPairs, feet }
 */
export declare function scanVerse(verse: VerseEntry[], automaton: MeterAutomaton): {
    indexAccentPairs: [number, string][];
    feet: string;
};
/**
 * Main entry point: scan all verses in the token list.
 * Reorders accented candidates so the best scansion form is first.
 * Returns array of scansion feet strings (one per verse).
 */
export declare function scanVerses(tokens: {
    text: string;
    isWord?: boolean;
    isSpace?: boolean;
    isUnknown?: boolean;
    accented?: string[];
}[], meterAutomatons: MeterAutomaton[]): string[];
//# sourceMappingURL=Scansion.d.ts.map