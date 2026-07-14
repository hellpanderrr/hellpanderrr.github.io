/**
 * Scansion.ts
 * Port of latin_macronizer/scansion.py
 * Scans Latin verse using meter automata (dactylic hexameter, pentameter, etc.)
 */
import { prefixesWithShortJ } from '../utils/latin.js';
const DIAERESISPENALTY = 2;
const NOSYNEZISPENALTY = 2;
const SYNEZISPENALTY = 3;
const HIATUSPENALTY = 3;
const MUTACUMLIQUIDAPENALTY = 1;
const REPRIORITIZEPENALTY = 1;
/**
 * Generate accented forms for unknown words: mark all vowels as ambiguous (short)
 */
export function allVowelsAmbiguous(accented) {
    accented = accented.replace(/([aeiouy])/g, '$1_^');
    accented = accented.replace(/qu_\^/g, 'qu');
    accented = accented.replace(/_\^(ns|nf|nct)/g, '_$1');
    accented = accented.replace(/_\^([bcdfgjklmnpqrstv]{2,}|[xz])/g, '$1');
    accented = accented.replace(/_\^m$/g, 'm');
    return accented;
}
/**
 * Split ambiguous vowels into all possible combinations.
 * Input: ['ba_^ce_^']
 * Output: ['bace', 'ba_ce', 'bace_', 'ba_ce_']
 */
export function separateAmbiguousVowels(accenteds) {
    const modifications = {
        'nescio_': 'nescio_^',
        'u_ni_us': 'u_ni_^us',
        'illi_us': 'illi_^us',
        'ipsi_us': 'ipsi_^us',
        'alteri_us': 'alteri_^us',
    };
    const newAccenteds = [];
    for (let accented of accenteds) {
        accented = modifications[accented] || accented;
        const parts = accented.split('_^');
        // Generate all 2^(n-1) variants (each _^ either becomes _ or is removed)
        for (let variant = 0; variant < (1 << (parts.length - 1)); variant++) {
            const newAccented = [];
            for (let bitPos = 0; bitPos < parts.length; bitPos++) {
                newAccented.push(parts[bitPos]);
                if ((1 << bitPos) & variant) {
                    newAccented.push('_');
                }
            }
            newAccenteds.push(newAccented.join(''));
        }
    }
    return newAccenteds;
}
/**
 * Split an accented form into vowel phonemes and consonant clusters
 */
export function segmentAccented(accented) {
    if (accented === 'hoc') {
        return ['o', 'cc'];
    }
    // Python str.replace() replaces ALL occurrences; JS string replace only the first.
    // Must use regex with /g flag to match Python behavior.
    const text = accented.toLowerCase().replace(/qu/g, 'q').replace(/x/g, 'cs').replace(/z/g, 'ds').replace(/\+/g, '^') + '#';
    const segments = [];
    let segmentStart = 0;
    let pos = 0;
    while (true) {
        // Diphthong check — Python also requires that the character after the
        // potential diphthong NOT be a length marker (_^+).  If it IS marked,
        // treat as separate vowels (e.g. "ae_" → two vowel segments).
        if (['ae', 'au', 'ei', 'eu', 'oe'].includes(text.substring(pos, pos + 2))
            && !'_^+'.includes(text.charAt(pos + 2))) {
            pos += 2;
        }
        // Single vowel + length markers
        else if ('aeiouy'.includes(text.charAt(pos))) {
            pos++;
            while ('_^+'.includes(text.charAt(pos))) {
                pos++;
            }
        }
        // Consonant cluster
        else {
            while (!'aeiouy#'.includes(text.charAt(pos))) {
                pos++;
            }
        }
        const segment = text.substring(segmentStart, pos).replace(/h/g, '');
        if (segment !== '') {
            segments.push(segment);
        }
        if (text.charAt(pos) === '#') {
            break;
        }
        segmentStart = pos;
    }
    return segments;
}
/**
 * Generate possible scansions for a word given its accented forms and the following segment.
 * followingSegment: one of "V", "C", "CC", "#"
 * Returns sorted [(penalty, scansion, accented), ...]
 */
export function possibleScans(accentedCandidates, followingSegment) {
    let isFirstAccented = true;
    const scans = [];
    for (const accented of separateAmbiguousVowels(accentedCandidates)) {
        const segments = segmentAccented(accented);
        // Add following segment to the list — it's processed in the loop for:
        // - 'C'/'CC': makes preceding vowel long by position (2+ consonants)
        // - 'V': handles elision (word ending in vowel before vowel-initial word)
        segments.push(followingSegment);
        const basePenalty = isFirstAccented ? 0 : REPRIORITIZEPENALTY;
        let temps = [[basePenalty, '']];
        for (let i = 0; i < segments.length; i++) {
            const thisSeg = segments[i];
            const prevSeg = i === 0 ? '#' : segments[i - 1];
            const nextSeg = i === segments.length - 1 ? '#' : segments[i + 1];
            // Skip initial consonant cluster
            if (i === 0 && !'aeiouy'.includes(thisSeg.charAt(0))) {
                continue;
            }
            const news = [];
            for (const [penaltySoFar, scanSoFar] of temps) {
                // Long by position (has _ marker)
                if (thisSeg.includes('_')) {
                    news.push([penaltySoFar, scanSoFar + 'L']);
                }
                // Diphthong: always long, or split with diaeresis penalty
                else if (['ae', 'au', 'ei', 'oe', 'eu'].includes(thisSeg)) {
                    news.push([penaltySoFar, scanSoFar + 'L']);
                    news.push([penaltySoFar + DIAERESISPENALTY, scanSoFar + 'VV']);
                }
                // Special synizesis: s/ng + u + vowel → u is consonant or vowel
                else if ((prevSeg.endsWith('s') || prevSeg.endsWith('ng')) && thisSeg === 'u' && 'aeiouy'.includes(nextSeg.charAt(0))) {
                    news.push([penaltySoFar, scanSoFar + 'C']);
                    news.push([penaltySoFar + NOSYNEZISPENALTY, scanSoFar + 'V']);
                }
                // u/i could be consonant (synizesis) when adjacent to vowel
                else if ('ui'.includes(thisSeg.charAt(0)) && ('aeiouy'.includes(nextSeg.charAt(0)) || 'aeiouy'.includes(prevSeg.charAt(0)))) {
                    news.push([penaltySoFar, scanSoFar + 'V']);
                    news.push([penaltySoFar + SYNEZISPENALTY, scanSoFar + 'C']);
                }
                // Normal vowel
                else if ('aeiouy'.includes(thisSeg.charAt(0))) {
                    news.push([penaltySoFar, scanSoFar + 'V']);
                }
                // Final -m before vowel/consonant/end → elision
                else if (thisSeg === 'm' && 'VCC#'.includes(nextSeg)) {
                    news.push([penaltySoFar, scanSoFar + 'M']);
                }
                // j (consonantal i)
                else if (thisSeg === 'j' && prevSeg !== '#') {
                    if (prefixesWithShortJ.some(prefix => accented.toLowerCase().startsWith(prefix))) {
                        news.push([penaltySoFar, scanSoFar + 'C']);
                    }
                    else {
                        news.push([penaltySoFar, scanSoFar + 'CC']);
                    }
                }
                // Next word begins with vowel → elision
                else if (thisSeg === 'V') {
                    if (scanSoFar.endsWith('V') || scanSoFar.endsWith('L')) {
                        news.push([penaltySoFar, scanSoFar.slice(0, -1)]); // elision
                        news.push([penaltySoFar + HIATUSPENALTY, scanSoFar]); // hiatus
                    }
                    else if (scanSoFar.endsWith('M')) {
                        news.push([penaltySoFar, scanSoFar.slice(0, -2)]); // elision with -m
                        news.push([penaltySoFar + HIATUSPENALTY, scanSoFar]); // hiatus
                    }
                    else {
                        news.push([penaltySoFar, scanSoFar]); // consonant ending, no elision
                    }
                }
                // End of word
                else if (thisSeg === '#') {
                    news.push([penaltySoFar, scanSoFar]);
                }
                // Single consonant
                else if (thisSeg.length === 1) {
                    news.push([penaltySoFar, scanSoFar + 'C']);
                }
                // Muta cum liquida: single cluster, or split with penalty
                else if (thisSeg.length === 2 && 'tpcdbgf'.includes(thisSeg.charAt(0)) && 'rl'.includes(thisSeg.charAt(1))) {
                    news.push([penaltySoFar, scanSoFar + 'C']);
                    news.push([penaltySoFar + MUTACUMLIQUIDAPENALTY, scanSoFar + 'CC']);
                }
                // Other consonant cluster
                else {
                    news.push([penaltySoFar, scanSoFar + 'CC']);
                }
            }
            temps = news;
        }
        // Convert raw scansion to L/S pattern
        // Python re.sub replaces ALL occurrences by default; JS replace needs /g flag
        for (const [penalty, scansion] of temps) {
            let normalized = scansion;
            normalized = normalized.replace(/VMC*|VCCC*|LM?C*/g, 'L');
            normalized = normalized.replace(/VC?/g, 'S');
            normalized = normalized.replace(/^C*/g, '');
            scans.push({ penalty, scansion: normalized, accented });
        }
        isFirstAccented = false;
    }
    // Deduplicate by scansion pattern, keeping lowest penalty
    scans.sort((a, b) => a.penalty - b.penalty);
    const filtered = [];
    const seenScansions = new Set();
    for (const scan of scans) {
        if (!seenScansions.has(scan.scansion)) {
            filtered.push(scan);
            seenScansions.add(scan.scansion);
        }
    }
    return filtered;
}
/**
 * Scan a single verse using the meter automaton.
 * verse: [(tokenIndex, [(penalty, scansion, accented), ...]), ...]
 * Returns: { indexAccentPairs, feet }
 */
export function scanVerse(verse, automaton) {
    function recurse(wordIndex, oldNodeIndex) {
        if (wordIndex === verse.length) {
            return { tail: [], tailFeet: [], tailPenalty: 0 };
        }
        const [tokenIndex, wordScans] = verse[wordIndex];
        let bestTail = [];
        let bestTailFeet = [];
        let bestTailPenalty = 100;
        for (const { penalty: scanPenalty, scansion, accented } of wordScans) {
            let nodeIndex = oldNodeIndex;
            const feet = [];
            let finished = false;
            let meterPenalty = 0;
            for (const syllable of scansion) {
                const key = `(${nodeIndex}, '${syllable}')`;
                const transition = automaton[key];
                if (!transition) {
                    nodeIndex = -1;
                    break;
                }
                const nextNode = transition[0];
                const foot = transition[1];
                const penaltyPart = transition[2];
                // nextNode = -1 means invalid transition (like state 0 + S in hexameter)
                if (nextNode === -1) {
                    nodeIndex = -1;
                    break;
                }
                nodeIndex = nextNode;
                meterPenalty += penaltyPart;
                if (nodeIndex === 0) {
                    finished = true;
                }
                feet.push(foot);
            }
            if (nodeIndex === -1 || (finished && (nodeIndex !== 0 || wordIndex !== verse.length - 1))) {
                continue;
            }
            const { tail, tailFeet, tailPenalty } = recurse(wordIndex + 1, nodeIndex);
            if (scanPenalty + meterPenalty + tailPenalty < bestTailPenalty) {
                bestTail = [[tokenIndex, accented], ...tail];
                bestTailFeet = [...feet, ...tailFeet];
                bestTailPenalty = scanPenalty + meterPenalty + tailPenalty;
            }
        }
        return { tail: bestTail, tailFeet: bestTailFeet, tailPenalty: bestTailPenalty };
    }
    const { tail, tailFeet } = recurse(0, 0);
    const feet = tailFeet.join('');
    return { indexAccentPairs: tail, feet };
}
/**
 * Main entry point: scan all verses in the token list.
 * Reorders accented candidates so the best scansion form is first.
 * Returns array of scansion feet strings (one per verse).
 */
export function scanVerses(tokens, meterAutomatons) {
    var _a;
    const scannedFeet = [];
    let verse = [];
    let automatonIndex = 0;
    for (let index = 0; index < tokens.length; index++) {
        const token = tokens[index];
        if (token.isWord) {
            // Determine following segment (what the next word starts with)
            let followingText = '';
            let nextIndex = index;
            while (true) {
                nextIndex++;
                if (nextIndex === tokens.length || tokens[nextIndex].text.includes('\n')) {
                    break;
                }
                if (tokens[nextIndex].isSpace) {
                    followingText += ' ';
                }
                else if (tokens[nextIndex].isWord) {
                    followingText += ((_a = tokens[nextIndex].accented) === null || _a === void 0 ? void 0 : _a[0]) || '';
                    if (/[aeiouy]/.test(followingText)) {
                        break;
                    }
                }
                // else: punctuation — no action (matches Python: neither isspace nor isword → skip)
            }
            // Python uses .lower().replace("h", "") on the raw (untrimmed) followingtext,
            // then re.match with leading-space-consuming regexes.
            // Do NOT .trim() — trailing spaces affect whether the empty-string sentinel
            // triggers (Python: `" "` → regex no-match → "CC", not "#").
            followingText = followingText.toLowerCase().replace(/h/g, '');
            // Determine following segment based on how the following word BEGINS.
            // Python uses re.match(" *[aeiouy]", followingtext) — leading spaces consumed by ` *`.
            // Our ^ equivalents must include ` *` since we no longer trim.
            let followingSegment;
            if (followingText === '') {
                followingSegment = '#';
            }
            else if (/^ *[aeiouy]/.test(followingText)) {
                followingSegment = 'V';
            }
            else if (/^ *([bcdfgjklmnpqrstv] *|[tpcdbgf][lr])[aeiouy]/.test(followingText)) {
                followingSegment = 'C';
            }
            else {
                followingSegment = 'CC';
            }
            // For unknown words, add a variant with all vowels ambiguous
            const accentCandidates = [...(token.accented || [''])];
            if (token.isUnknown) {
                accentCandidates.push(allVowelsAmbiguous(token.text.toLowerCase()));
            }
            verse.push([index, possibleScans(accentCandidates, followingSegment)]);
        }
        // End of verse (newline or last token)
        if (token.text.includes('\n') || index === tokens.length - 1) {
            if (verse.length > 0) {
                const { indexAccentPairs, feet } = scanVerse(verse, meterAutomatons[automatonIndex]);
                const newlineCount = (token.text.match(/\n/g) || []).length;
                scannedFeet.push(feet);
                for (let nl = 1; nl < newlineCount; nl++) {
                    scannedFeet.push('');
                }
                // Reorder accented candidates: move best-scansion form to front
                for (const [tokenIndex, newAccented] of indexAccentPairs) {
                    const t = tokens[tokenIndex];
                    if (t.accented) {
                        const idx = t.accented.indexOf(newAccented);
                        if (idx > -1) {
                            t.accented.splice(idx, 1);
                        }
                        t.accented.unshift(newAccented);
                    }
                }
                verse = [];
                automatonIndex++;
                if (automatonIndex === meterAutomatons.length) {
                    automatonIndex = 0;
                }
            }
        }
    }
    return scannedFeet;
}
//# sourceMappingURL=Scansion.js.map