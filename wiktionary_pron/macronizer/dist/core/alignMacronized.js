/**
 * DP alignment algorithm for macronization
 * Ported from latin_macronizer/token.py (Token.macronize method)
 *
 * This module implements edit-distance alignment between plain and accented forms
 * to determine optimal macron placement.
 */
import { toAscii, prefixesWithShortJ } from '../utils/latin.js';
/**
 * Compute insertion cost
 * ins(a) = 0 if a == '_' (macron marker) else 2
 */
function insCost(a) {
    return a === '_' ? 0 : 2;
}
/**
 * Compute substitution cost
 * sub(p, a) = 100 if a == '_' (macron marker)
 *            = 1 if (I/J or U/V equivalence, case-insensitive ASCII)
 *            = 2 otherwise
 */
function subCost(p, a) {
    if (a === '_')
        return 100;
    const pNorm = toAscii(p).toLowerCase();
    const aNorm = toAscii(a).toLowerCase();
    // Check for I/J or U/V equivalence
    if ((pNorm === 'i' && aNorm === 'j') ||
        (pNorm === 'j' && aNorm === 'i') ||
        (pNorm === 'u' && aNorm === 'v') ||
        (pNorm === 'v' && aNorm === 'u')) {
        return 1;
    }
    // Exact match (case-insensitive, ASCII-normalized)
    if (pNorm === aNorm)
        return 0;
    return 2;
}
/**
 * Compute deletion cost
 * del(_) = 2, otherwise handled by subcost in DP
 * In this DP formulation, deletion is modeled as substitution with empty string
 */
function delCost(p) {
    return p === '_' ? 2 : 2; // Deletion always costs 2
}
/**
 * Check if two characters match (case-insensitive, ASCII-normalized)
 */
function charsMatch(p, a) {
    return toAscii(p).toLowerCase() === toAscii(a).toLowerCase();
}
/**
 * Align plain text with accented text using DP edit distance
 * Returns the macronized result string (with _ markers)
 * Ported from latin_macronizer/token.py (Token.macronize method)
 */
export function alignMacronized(plain, accented, options = {}) {
    const { domacronize = true, alsomaius = false, performutov = false, performitoj = false } = options;
    // Early exit: if no macronization and no conversions, return plain
    if (!domacronize && !performutov && !performitoj) {
        return plain;
    }
    // Clean accented: remove breve markers (_^ and ^)
    // Python: accented = accented.replace("_^", "").replace("^", "")
    let accentedNorm = accented.split('_^').join('').split('^').join('');
    // Apply alsomaius transformation if needed (only on accented)
    // Match both 'i' and 'j' since wordlist uses 'i' but Morpheus uses 'j' orthography
    if (domacronize && alsomaius && /[ij]/.test(accentedNorm)) {
        const lowerAcc = accentedNorm.toLowerCase();
        const startsWithShortJPrefix = prefixesWithShortJ.some(prefix => lowerAcc.startsWith(prefix));
        if (!startsWithShortJPrefix) {
            // Insert underscore after vowel before i/j+vowel: ([aeiouy])([ij][aeiouy]) → \1_\2
            accentedNorm = accentedNorm.replace(/([aeiouy])([ij][aeiouy])/gi, (_, v, ijv) => `${v}_${ijv}`);
        }
    }
    // Early exact match: if plain equals accented without underscores, return accented (with underscores).
    // Python Token.macronize() matches this path when plain == accented.replace("_","") — it returns
    // accented directly (with macrons) when domacronize, or plain otherwise.
    // Crucially, Python does NOT apply u→v or i→j conversion here — those ONLY happen inside the DP
    // backtrack (lines 192-202), and only when the wordlist accented form specifically has 'v'/'j'
    // at that position.  Blanket replacement here would convert e.g. "cum" → "cvm" (wrong) because
    // "cum" has no 'v' in its wordlist entry.
    const accentedWithoutUnderscores = accentedNorm.replace(/_/g, '');
    const isExactMatch = options.alsomaius
        ? plain.toLowerCase() === accentedWithoutUnderscores.toLowerCase()
        : plain === accentedWithoutUnderscores;
    if (isExactMatch) {
        // Python: return plain when not macronizing (no macron markers), accented otherwise
        if (!domacronize)
            return plain;
        let result = accentedNorm;
        if (options.alsomaius && plain[0] !== accentedNorm[0]) {
            result = plain[0] + accentedNorm.slice(1);
        }
        return result;
    }
    const n = plain.length;
    const m = accentedNorm.length;
    // DP matrix: distance[i][j] = min cost to align plain[0:i] with accented[0:j]
    const distance = Array(n + 1).fill(null).map(() => Array(m + 1).fill(Infinity));
    // Store backtrack directions (which move led to min cost)
    const backtrackDir = Array(n + 1).fill(null).map(() => Array(m + 1).fill('diag'));
    // Base case
    distance[0][0] = 0;
    backtrackDir[0][0] = 'diag';
    // First row: insertions from accented
    for (let j = 1; j <= m; j++) {
        const aChar = accentedNorm[j - 1];
        distance[0][j] = distance[0][j - 1] + insCost(aChar);
        backtrackDir[0][j] = 'up';
    }
    // First column: deletions from plain
    for (let i = 1; i <= n; i++) {
        const pChar = plain[i - 1];
        distance[i][0] = distance[i - 1][0] + delCost(pChar);
        backtrackDir[i][0] = 'left';
    }
    // Fill DP matrix
    for (let i = 1; i <= n; i++) {
        const pChar = plain[i - 1];
        for (let j = 1; j <= m; j++) {
            const aChar = accentedNorm[j - 1];
            const diagCost = distance[i - 1][j - 1] + subCost(pChar, aChar);
            const upCost = distance[i][j - 1] + insCost(aChar);
            const leftCost = distance[i - 1][j] + delCost(pChar);
            let minCost = diagCost;
            let bestMove = 'diag';
            if (upCost < minCost) {
                minCost = upCost;
                bestMove = 'up';
            }
            if (leftCost < minCost) {
                minCost = leftCost;
                bestMove = 'left';
            }
            distance[i][j] = minCost;
            backtrackDir[i][j] = bestMove;
        }
    }
    // Backtrack to build result string
    let result = '';
    let i = n;
    let j = m;
    while (i > 0 || j > 0) {
        const move = backtrackDir[i][j];
        if (move === 'diag' && i > 0 && j > 0) {
            const pChar = plain[i - 1];
            const aChar = accentedNorm[j - 1];
            const pLower = pChar.toLowerCase();
            const aLower = aChar.toLowerCase();
            // Determine output character
            // u→v and i→j conversion: ONLY when accented has 'v'/'j' AND plain has 'u'/'i'.
            // This matches Python token.py lines 100-107 exactly — converts only consonantal
            // positions (where wordlist accented form uses 'v'/'j'), preserves macronized vowels.
            let outChar;
            if (performutov && aLower === 'v' && pChar === 'u') {
                outChar = 'v';
            }
            else if (performutov && aLower === 'v' && pChar === 'U') {
                outChar = 'V';
            }
            else if (performitoj && aLower === 'j' && pChar === 'i') {
                outChar = 'j';
            }
            else if (performitoj && aLower === 'j' && pChar === 'I') {
                outChar = 'J';
            }
            else {
                outChar = pChar;
            }
            if (charsMatch(pChar, aChar)) {
                // Match: prepend character
                result = outChar + result;
            }
            else if (aChar === '_' && domacronize) {
                // Substitution with macron: prepend char + macron
                result = outChar + '_' + result;
            }
            else {
                // Other substitution: prepend char
                result = outChar + result;
            }
            i--;
            j--;
        }
        else if (move === 'up' && j > 0) {
            const aChar = accentedNorm[j - 1];
            // Insertion: prepend '_' if domacronize and aChar is '_'
            if (domacronize && aChar === '_') {
                result = '_' + result;
            }
            j--;
        }
        else if (move === 'left' && i > 0) {
            const pChar = plain[i - 1];
            // Deletion: prepend plain char
            result = pChar + result;
            i--;
        }
        else {
            // Safety: break if stuck
            break;
        }
    }
    // Clean up double macrons (e.g., from multiple insertions)
    result = result.replace(/_+/g, '_');
    // Note: Do NOT strip trailing underscore — it marks a macron on the final vowel
    return result;
}
/**
 * Main entry point: macronize a plain Latin word
 * This is a direct port of Token.macronize() logic
 */
export function macronizeWord(plain, accented, enclitic = null, options = {}) {
    const { performutov = false } = options;
    // Special case: if enclitic is 'ue' and performutov, return plain (skip macronization)
    if (performutov && enclitic === 'ue') {
        return plain;
    }
    // Exact match shortcut
    if (plain.toLowerCase() === accented.toLowerCase()) {
        return accented;
    }
    // Run alignment
    return alignMacronized(plain, accented, options);
}
//# sourceMappingURL=alignMacronized.js.map