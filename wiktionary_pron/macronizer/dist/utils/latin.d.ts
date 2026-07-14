/**
 * Latin text processing utilities
 * Ported from latin_macronizer/helpers.py
 */
export declare const prefixesWithShortJ: string[];
/**
 * Convert Latin extended characters to ASCII
 * e.g., "æ" → "ae", "œ" → "oe"
 */
export declare function toAscii(text: string): string;
/**
 * Convert to UI orthography (v→u, j→i)
 */
export declare function toUiOrthography(text: string): string;
/**
 * Reverse UI orthography (u→v, i→j)
 */
export declare function fromUiOrthography(text: string, utov: boolean, itoj: boolean): string;
/**
 * Check if character is a Latin vowel
 */
export declare function isVowel(c: string): boolean;
/**
 * Check if character is a Latin consonant
 */
export declare function isConsonant(c: string): boolean;
/**
 * Check if word starts with vowel
 */
export declare function startsWithVowel(word: string): boolean;
/**
 * Check if word starts with prefix that has short 'j'
 */
export declare function startsWithShortJPrefix(word: string): boolean;
/**
 * Normalize word for lookup (lowercase, toAscii)
 */
export declare function normalizeWord(word: string): string;
/**
 * Split text into sentences
 * Simple heuristic: split on . ! ? followed by space or end
 */
export declare function splitSentences(text: string): string[];
/**
 * Check if character ends a sentence
 */
export declare function isSentenceEnder(c: string): boolean;
/**
 * Check if token is punctuation
 */
export declare function isPunctuation(token: string): boolean;
/**
 * Check if token is whitespace
 */
export declare function isWhitespace(token: string): boolean;
/**
 * Common Latin enclitics (generic split only)
 * Python splits: -que (len>3), -ve/-ue/-ne/-st (len>2)
 * -cum and -met are handled via special list only, not generic
 */
export declare const enclitics: string[];
/**
 * Check if word ends with enclitic
 * Returns [stem, enclitic] or null
 */
export declare function splitEnclitic(word: string): [string, string] | null;
/**
 * Identify vowel clusters in Latin word
 * Returns array of [start, end] positions
 */
export declare function findVowelClusters(word: string): Array<[number, number]>;
/**
 * Check if vowel position is ambiguous
 * (can be either long or short)
 */
export declare function isAmbiguousVowel(word: string): boolean;
/**
 * Escape HTML entities
 */
export declare function escapeHtml(text: string): string;
/**
 * Compute Levenshtein distance between two strings
 */
export declare function levenshteinDistance(a: string, b: string): number;
/**
 * Convert underscore macron markers to Unicode macrons
 * a_ → ā, e_ → ē, etc.
 */
export declare function underscoreToUnicode(text: string): string;
/**
 * Convert Unicode macrons to underscore markers (inverse of underscoreToUnicode)
 */
export declare function unicodeToUnderscore(text: string): string;
/**
 * Filter and normalize accent forms from Morpheus output
 * Ported from latin_macronizer/postags.py filter_accents()
 *
 * Morpheus can produce accent forms with markers in non-standard order.
 * This function normalizes them to the expected underscore notation.
 *
 * Transformations:
 *   "^_" → "_^"  (swap order)
 *   "_^" + consonant+l/r → "^" + consonant  (e.g., a_^cl → a^cl)
 *   "u_m" → "um"  (special case)
 *   vowel + "^?" + n + (s/f/x/ct) → vowel + "_n" + ending  (e.g., an^s → a_ns)
 */
export declare function filterAccents(accented: string): string;
/**
 * Normalize RFTagger tag format to LDT 9-char format.
 * RFTagger dotted (17-chars): n.-.s.-.-.-.f.b.- → remove dots → n-s---fb- (9-char LDT)
 * RFTagger undotted (17-chars): n---s-------f-b-- → extract even positions → n-s---fb-
 * LDT: n-s---fn- (9 chars: pos+person+number+tense+mood+voice+gender+case+degree)
 *
 * Works with any odd-length tag format where data lives at even indices
 * and separators at odd indices (both dotted and undotted variants).
 */
export declare function normalizeTag(tag: string): string;
/**
 * Decode an LDT tag into human-readable morphological feature labels.
 *
 * LDT tags are 9-character strings where each position encodes a feature:
 *   pos, person, number, tense, mood, voice, gender, case, degree
 * Position values are defined in latin_macronizer/postags.py (ldt_to_parse).
 *
 * Unknown/empty (`-`) features are omitted from the output so the string
 * is readable at a glance (e.g. "verb, 3rd person singular, present
 * indicative active" instead of "verb, 3rd, singular, present, indicative,
 * active, -, -, -").
 */
/** Structured morphological feature returned by decodeLdtTagToFeatures */
export interface LdtFeature {
    feature: string;
    value: string;
    raw: string;
}
/**
 * Decode an LDT tag into structured feature pairs, omitting empty (`-`) slots.
 *
 * Returns an array of { feature, value, raw } objects — one per filled
 * position — suitable for rendering as labeled rows in a UI table.
 */
export declare function decodeLdtTagToFeatures(tag: string): LdtFeature[];
/**
 * Legacy: decode an LDT tag into a comma-separated string.
 * Prefer decodeLdtTagToFeatures for structured UI rendering.
 */
export declare function decodeLdtTag(tag: string): string;
/**
 * Compute distance between two LDT tags
 * Ported from latin_macronizer/postags.py (tag_distance function)
 *
 * LDT tags are 9-char or 12-char strings encoding morphological features.
 * For nomina (nouns, adjectives, verbs-as-participles), tense/mood/voice
 * positions are ignored when comparing tags of different types.
 */
export declare function tagDistance(tag1: string, tag2: string): number;
//# sourceMappingURL=latin.d.ts.map