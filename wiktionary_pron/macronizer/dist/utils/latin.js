/**
 * Latin text processing utilities
 * Ported from latin_macronizer/helpers.py
 */
// Prefixes with short 'j' sound
export const prefixesWithShortJ = [
    'bij', 'fidej', 'Foroj', 'foroj', 'ju_rej', 'multij',
    'praej', 'quadrij', 'rej', 'retroj', 'se_mij', 'sesquij',
    'u_nij', 'introj'
];
/**
 * Convert Latin extended characters to ASCII
 * e.g., "æ" → "ae", "œ" → "oe"
 */
export function toAscii(text) {
    const replacements = [
        ['æ', 'ae'], ['Æ', 'Ae'],
        ['œ', 'oe'], ['Œ', 'Oe'],
        ['ä', 'a'], ['ë', 'e'],
        ['ï', 'i'], ['ö', 'o'],
        ['ü', 'u'], ['ÿ', 'u']
    ];
    let result = text;
    for (const [from, to] of replacements) {
        result = result.replace(new RegExp(from, 'g'), to);
    }
    return result;
}
/**
 * Convert to UI orthography (v→u, j→i)
 */
export function toUiOrthography(text) {
    return text
        .replace(/v/g, 'u')
        .replace(/V/g, 'U')
        .replace(/j/g, 'i')
        .replace(/J/g, 'I');
}
/**
 * Reverse UI orthography (u→v, i→j)
 */
export function fromUiOrthography(text, utov, itoj) {
    let result = text;
    if (utov) {
        result = result.replace(/u/g, 'v').replace(/U/g, 'V');
    }
    if (itoj) {
        result = result.replace(/i/g, 'j').replace(/I/g, 'J');
    }
    return result;
}
/**
 * Check if character is a Latin vowel
 */
export function isVowel(c) {
    return 'aeiouyAEIOUY'.includes(c);
}
/**
 * Check if character is a Latin consonant
 */
export function isConsonant(c) {
    return /[bcdfghjklmnpqrstvxzBCDFGHJKLMNPQRSTVXZ]/.test(c);
}
/**
 * Check if word starts with vowel
 */
export function startsWithVowel(word) {
    if (!word)
        return false;
    const first = word[0].toLowerCase();
    return 'aeiouy'.includes(first);
}
/**
 * Check if word starts with prefix that has short 'j'
 */
export function startsWithShortJPrefix(word) {
    const lower = word.toLowerCase();
    return prefixesWithShortJ.some(prefix => lower.startsWith(prefix));
}
/**
 * Normalize word for lookup (lowercase, toAscii)
 */
export function normalizeWord(word) {
    return toAscii(word).toLowerCase().trim();
}
/**
 * Split text into sentences
 * Simple heuristic: split on . ! ? followed by space or end
 */
export function splitSentences(text) {
    return text
        .replace(/([.!?])(\s+)/g, '$1\n')
        .split('\n')
        .map(s => s.trim())
        .filter(s => s.length > 0);
}
/**
 * Check if character ends a sentence
 */
export function isSentenceEnder(c) {
    // Python tokenization.py: any(i in token.text for i in '.;:?!')
    return '.;:?!'.includes(c);
}
/**
 * Check if token is punctuation
 */
export function isPunctuation(token) {
    return /^[^\w\s]*$/.test(token);
}
/**
 * Check if token is whitespace
 */
export function isWhitespace(token) {
    return /^\s*$/.test(token);
}
/**
 * Common Latin enclitics (generic split only)
 * Python splits: -que (len>3), -ve/-ue/-ne/-st (len>2)
 * -cum and -met are handled via special list only, not generic
 */
export const enclitics = ['que', 've', 'ue', 'ne', 'st'];
/**
 * Check if word ends with enclitic
 * Returns [stem, enclitic] or null
 */
export function splitEnclitic(word) {
    const lower = word.toLowerCase();
    for (const enclitic of enclitics) {
        if (lower.endsWith(enclitic) && lower.length > enclitic.length) {
            const stem = word.slice(0, -enclitic.length);
            // Python: split unconditionally if word ends with enclitic (no stem validation)
            return [stem, enclitic];
        }
    }
    return null;
}
/**
 * Identify vowel clusters in Latin word
 * Returns array of [start, end] positions
 */
export function findVowelClusters(word) {
    const clusters = [];
    const vowelPattern = /[aeiouyAEIOUY]/;
    let i = 0;
    while (i < word.length) {
        if (vowelPattern.test(word[i])) {
            let start = i;
            // Check for diphthongs (ae, au, ei, eu, oe)
            if (i + 1 < word.length) {
                const pair = word.slice(i, i + 2).toLowerCase();
                if (['ae', 'au', 'ei', 'eu', 'oe'].includes(pair)) {
                    i += 2;
                }
                else {
                    i += 1;
                }
            }
            else {
                i += 1;
            }
            clusters.push([start, i]);
        }
        else {
            i += 1;
        }
    }
    return clusters;
}
/**
 * Check if vowel position is ambiguous
 * (can be either long or short)
 */
export function isAmbiguousVowel(word) {
    // Common ambiguous patterns
    const ambiguousPatterns = [
        /_\^/, // Marked as ambiguous in pattern
    ];
    for (const pattern of ambiguousPatterns) {
        if (pattern.test(word))
            return true;
    }
    return false;
}
/**
 * Escape HTML entities
 */
export function escapeHtml(text) {
    const div = document.createElement('div');
    div.textContent = text;
    return div.innerHTML;
}
/**
 * Compute Levenshtein distance between two strings
 */
export function levenshteinDistance(a, b) {
    const matrix = [];
    const lenA = a.length;
    const lenB = b.length;
    // Initialize matrix
    for (let i = 0; i <= lenB; i++) {
        matrix[i] = [i];
    }
    for (let j = 0; j <= lenA; j++) {
        matrix[0][j] = j;
    }
    // Fill matrix
    for (let i = 1; i <= lenB; i++) {
        for (let j = 1; j <= lenA; j++) {
            if (b.charAt(i - 1) === a.charAt(j - 1)) {
                matrix[i][j] = matrix[i - 1][j - 1];
            }
            else {
                matrix[i][j] = Math.min(matrix[i - 1][j - 1] + 1, // substitution
                matrix[i][j - 1] + 1, // insertion
                matrix[i - 1][j] + 1 // deletion
                );
            }
        }
    }
    return matrix[lenB][lenA];
}
/**
 * Convert underscore macron markers to Unicode macrons
 * a_ → ā, e_ → ē, etc.
 */
export function underscoreToUnicode(text) {
    return text
        .replace(/a_/g, 'ā')
        .replace(/e_/g, 'ē')
        .replace(/i_/g, 'ī')
        .replace(/o_/g, 'ō')
        .replace(/u_/g, 'ū')
        .replace(/y_/g, 'ȳ')
        .replace(/A_/g, 'Ā')
        .replace(/E_/g, 'Ē')
        .replace(/I_/g, 'Ī')
        .replace(/O_/g, 'Ō')
        .replace(/U_/g, 'Ū')
        .replace(/Y_/g, 'Ȳ');
}
/**
 * Convert Unicode macrons to underscore markers (inverse of underscoreToUnicode)
 */
export function unicodeToUnderscore(text) {
    return text
        .replace(/ā/g, 'a_')
        .replace(/ē/g, 'e_')
        .replace(/ī/g, 'i_')
        .replace(/ō/g, 'o_')
        .replace(/ū/g, 'u_')
        .replace(/ȳ/g, 'y_')
        .replace(/Ā/g, 'A_')
        .replace(/Ē/g, 'E_')
        .replace(/Ī/g, 'I_')
        .replace(/Ō/g, 'O_')
        .replace(/Ū/g, 'U_')
        .replace(/Ȳ/g, 'Y_');
}
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
export function filterAccents(accented) {
    let result = accented;
    // Step 1: swap "^_" to "_^"
    result = result.replace(/\^_/g, '_^');
    // Step 2: convert "_^" followed by consonant+l/r to "^" + consonant
    result = result.replace(/_\^([bcdfgpt][lr])/g, '^$1');
    // Step 3: "u_m" → "um"
    result = result.replace(/u_m$/g, 'um');
    // Step 4: add macron before n in patterns like an^s, in^ct, etc.
    result = result.replace(/([AEIOUYaeiouy])\^?n([sfx]|ct)/g, '$1_n$2');
    return result;
}
/**
 * Normalize RFTagger tag format to LDT 9-char format.
 * RFTagger dotted (17-chars): n.-.s.-.-.-.f.b.- → remove dots → n-s---fb- (9-char LDT)
 * RFTagger undotted (17-chars): n---s-------f-b-- → extract even positions → n-s---fb-
 * LDT: n-s---fn- (9 chars: pos+person+number+tense+mood+voice+gender+case+degree)
 *
 * Works with any odd-length tag format where data lives at even indices
 * and separators at odd indices (both dotted and undotted variants).
 */
export function normalizeTag(tag) {
    if (tag.length === 9 || tag.length === 12) {
        return tag;
    }
    // Remove dots (RFTagger 17-char dotted format: v.3.s.p.i.a.-.-.- → v3spia---- → extract
    // even positions → v3spia---). Also handles any odd-length dotted variants.
    const undotted = tag.replace(/\./g, '');
    if (undotted.length >= 9) {
        // Extract data at even positions (0=pos, 2=person, 4=number, 6=tense, 8=mood,
        // 10=voice, 12=gender, 14=case, 16=degree), capped at 9 chars.
        let result = '';
        for (let i = 0; i < undotted.length && result.length < 9; i += 2) {
            result += undotted[i];
        }
        return result;
    }
    if (tag.length !== 17) {
        console.warn(`normalizeTag: unexpected tag format length=${tag.length}: "${tag}"`);
        return tag;
    }
    return tag;
}
/**
 * Decode an LDT tag into structured feature pairs, omitting empty (`-`) slots.
 *
 * Returns an array of { feature, value, raw } objects — one per filled
 * position — suitable for rendering as labeled rows in a UI table.
 */
export function decodeLdtTagToFeatures(tag) {
    const normalized = normalizeTag(tag);
    if (normalized.length !== 9)
        return [];
    const f = (i) => i < normalized.length ? normalized[i] : '-';
    const posMap = { n: 'noun', v: 'verb', a: 'adjective', d: 'adverb', c: 'conjunction', r: 'preposition', p: 'pronoun', m: 'numeral', i: 'interjection', e: 'exclamation', u: 'punctuation' };
    const personMap = { '1': '1st person', '2': '2nd person', '3': '3rd person' };
    const numMap = { s: 'singular', p: 'plural' };
    const tenseMap = { p: 'present', i: 'imperfect', r: 'perfect', l: 'pluperfect', t: 'future perfect', f: 'future' };
    const moodMap = { i: 'indicative', s: 'subjunctive', n: 'infinitive', m: 'imperative', p: 'participle', d: 'gerund', g: 'gerundive', u: 'supine' };
    const voiceMap = { a: 'active', p: 'passive' };
    const genderMap = { m: 'masculine', f: 'feminine', n: 'neuter' };
    const caseMap = { n: 'nominative', g: 'genitive', d: 'dative', a: 'accusative', b: 'ablative', v: 'vocative', l: 'locative' };
    const degreeMap = { c: 'comparative', s: 'superlative' };
    const defs = [
        ['POS', posMap, 0],
        ['Person', personMap, 1],
        ['Number', numMap, 2],
        ['Tense', tenseMap, 3],
        ['Mood', moodMap, 4],
        ['Voice', voiceMap, 5],
        ['Gender', genderMap, 6],
        ['Case', caseMap, 7],
        ['Degree', degreeMap, 8],
    ];
    const out = [];
    for (const [featName, map, pos] of defs) {
        const raw = f(pos);
        if (raw === '-')
            continue;
        const value = map[raw] || `unknown (${raw})`;
        out.push({ feature: featName, value, raw });
    }
    return out;
}
/**
 * Legacy: decode an LDT tag into a comma-separated string.
 * Prefer decodeLdtTagToFeatures for structured UI rendering.
 */
export function decodeLdtTag(tag) {
    return decodeLdtTagToFeatures(tag).map(f => f.value).join(', ') || 'unknown';
}
/**
 * Compute distance between two LDT tags
 * Ported from latin_macronizer/postags.py (tag_distance function)
 *
 * LDT tags are 9-char or 12-char strings encoding morphological features.
 * For nomina (nouns, adjectives, verbs-as-participles), tense/mood/voice
 * positions are ignored when comparing tags of different types.
 */
export function tagDistance(tag1, tag2) {
    // Normalize tags first (convert RFTagger 15-char to LDT 9-char)
    tag1 = normalizeTag(tag1);
    tag2 = normalizeTag(tag2);
    // Validate lengths
    const len1 = tag1.length;
    const len2 = tag2.length;
    if (!((len1 === 9 || len1 === 12) && (len2 === 9 || len2 === 12))) {
        console.warn('Warning: Strange or mismatching tags!', tag1, tag2);
        return 0;
    }
    // If lengths differ, we cannot compare directly
    // But in practice they should be same length. Normalize to same length by truncating to 9 if needed.
    if (len1 !== len2) {
        if (len1 === 12)
            tag1 = tag1.slice(0, 9);
        else if (len2 === 12)
            tag2 = tag2.slice(0, 9);
    }
    const t1 = tag1;
    const t2 = tag2;
    /**
     * Check if tag represents a nomen (noun, adjective, or verb-as-participle)
     * In LDT: pos1 = 'n' (noun), 'a' (adjective), or 'v' with participle features (rpp/ppa)
     */
    function isNomen(tag) {
        const pos = tag[0];
        if (pos === 'n' || pos === 'a')
            return true;
        if (pos === 'v' || pos === 'V') {
            // Check for participle: positions 3-5 (0-indexed) for 9-char, or 4-7 for 12-char
            const stem = tag.length === 12 ? tag.slice(4, 7) : tag.slice(3, 6);
            return stem === 'rpp' || stem === 'ppa';
        }
        return false;
    }
    const isNomen1 = isNomen(t1);
    const isNomen2 = isNomen(t2);
    let bothNomenButDifferent = false;
    if (isNomen1 && isNomen2 && t1[0] !== t2[0]) {
        bothNomenButDifferent = true;
    }
    let dist = 0;
    const len = Math.min(t1.length, t2.length);
    for (let i = 0; i < len; i++) {
        // Skip tense/mood/voice positions for nomina of different types
        // 9-char: skip indices 3,4,5 (tense, mood, voice)
        // 12-char: skip indices 4,5,6 (tense, mood, voice)
        if (bothNomenButDifferent) {
            if ((t1.length === 9 && (i === 3 || i === 4 || i === 5)) ||
                (t1.length === 12 && (i === 4 || i === 5 || i === 6))) {
                continue;
            }
        }
        if (t1[i] !== t2[i]) {
            dist += 1;
        }
    }
    return dist;
}
//# sourceMappingURL=latin.js.map