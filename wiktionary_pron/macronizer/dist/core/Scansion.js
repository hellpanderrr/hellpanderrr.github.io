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
// A COMPLETE reading (ends at state 0) is preferred over an incomplete one
// even when it costs up to one phonological concession more. Rationale: a
// hexameter is DEFINED as ending at state 0 — an incomplete 5-foot scan is not
// a hexameter. But the DP treats "stop early" as free (0 penalty), so a
// complete reading that needs real quantities (long vowels, synizesis) at
// 1-3 penalty loses to a 5-foot partial that avoids those costs by simply not
// finishing. Bounded at 3 (one HIATUS/SYNEZIS penalty) so it fixes genuine
// hexameters whose complete path is within one concession (Tune ille Aen 1.617,
// victor Simoenta Aen 5.261) but does NOT force completion where the only
// complete path requires multiple corruptions (Nereidum Aen 3.74 — the gold
// path is pen6 above the cheap path, so it correctly stays a 5-foot partial
// rather than completing with wrong quantities). A genuine hemistich/fragment
// has no complete path at all, so the bonus never invents completion there.
const COMPLETIONBONUS = 3;
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
        // -ērunt/-ĕrunt (3rd-pl perfect) poetic alternation: the long ē before -runt
        // can be short (stetērunt ~ stetĕrunt). Mark it ambiguous so both lengths result.
        // This is the M-013 signature fix: Aen 2.774 "obstipui, steteruntque comae" only
        // scans when steterunt reads stetĕrunt (short e), which the wordlist marks long.
        const erunt = /^(.+?)([aeiouy])_runt$/.exec(accented);
        if (erunt) {
            accented = `${erunt[1]}${erunt[2]}_^runt`;
        }
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
                // u/i/y could be consonant (synizesis) when adjacent to vowel.
                // y is included for Greek names (Euryalus, Helymus, Cinyra): the
                // consonant y merges with the preceding consonant + following vowel
                // into one syllable (e.g. Euryalus → Eu-rya-lus).
                else if ('uiy'.includes(thisSeg.charAt(0)) && ('aeiouy'.includes(nextSeg.charAt(0)) || 'aeiouy'.includes(prevSeg.charAt(0)))) {
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
            return { tail: [], tailFeet: [], tailPenalty: 0, complete: true };
        }
        const [tokenIndex, wordScans] = verse[wordIndex];
        let bestTail = [];
        let bestTailFeet = [];
        let bestTailPenalty = 100;
        let bestComplete = false;
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
            if (nodeIndex === -1) {
                continue;
            }
            if (finished) {
                // Once the meter has completed (returned to state 0), no more
                // syllables may be added. Ending at state 0 is valid only when every
                // remaining word is fully elided (0 syllables) — the hypermeter case
                // where a verse-final -que elides into the next line (deorumque +
                // "aut": deorum completes the hexameter, the -que contributes nothing).
                if (nodeIndex !== 0)
                    continue;
                let trailingAllElided = true;
                for (let w = wordIndex + 1; w < verse.length; w++) {
                    if (!verse[w][1].some(s => s.scansion === '')) {
                        trailingAllElided = false;
                        break;
                    }
                }
                if (!trailingAllElided)
                    continue;
            }
            const { tail, tailFeet, tailPenalty, complete: subComplete } = recurse(wordIndex + 1, nodeIndex);
            const totalPenalty = scanPenalty + meterPenalty + tailPenalty;
            // A verse is "complete" only when the last word ends at state 0. Prefer
            // the complete reading over a partial one on a penalty tie — otherwise an
            // elided verse-final -que (penalty 0) can win over a real final syllable
            // (also penalty 0) and yield an incomplete 5-foot scan (Aen 5.826
            // Cymodoceque). Genuine hypermeters still need the elision because their
            // penultimate word alone completes the meter (guard above).
            const complete = wordIndex === verse.length - 1 ? nodeIndex === 0 : subComplete;
            // M-013f completion bonus: a reading that ends at state 0 gets up to
            // COMPLETIONBONUS off its penalty, so a real 6-foot hexameter wins over a
            // 5-foot truncation when its complete path is within one phonological
            // concession (Tune ille, victor Simoenta). Bounded so it does NOT force a
            // multi-corruption completion (Nereidum stays a correct 5-foot partial).
            const effectivePenalty = complete && wordIndex === verse.length - 1 ? totalPenalty - COMPLETIONBONUS : totalPenalty;
            if (effectivePenalty < bestTailPenalty || (effectivePenalty === bestTailPenalty && complete && !bestComplete)) {
                bestTail = [[tokenIndex, accented], ...tail];
                bestTailFeet = [...feet, ...tailFeet];
                bestTailPenalty = effectivePenalty;
                bestComplete = complete;
            }
        }
        return { tail: bestTail, tailFeet: bestTailFeet, tailPenalty: bestTailPenalty, complete: bestComplete };
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
    var _a, _b;
    const scannedFeet = [];
    let verse = [];
    let automatonIndex = 0;
    for (let index = 0; index < tokens.length; index++) {
        const token = tokens[index];
        if (token.isWord) {
            // Determine following segment (what the next word starts with)
            let followingText = '';
            let nextIndex = index;
            // Hypermeter: a verse-final -que elides into the next line's initial
            // vowel (e.g. nexaequ'aere). For a word ending in -que we look past the
            // line break for the next word; otherwise (normal word) a newline ends
            // the verse and followingSegment is '#' (verse-final anceps).
            const isHyperEnclitic = (((_a = token.accented) === null || _a === void 0 ? void 0 : _a[0]) || token.text || '').toLowerCase().replace(/[^a-z]/g, '').endsWith('que');
            // A verse-final -que is a genuine hypermeter candidate (its elision into
            // the next line's initial vowel completes the hexameter). Mid-line -que
            // words (atque, namque, -que) must NOT get the dual #/V treatment —
            // the # (verse-final anceps) reading is meaningless for them and leaks
            // an artificially cheap penalty that flips the chosen quantity (the
            // hīc→hĭc / vāgīnā regressions). Detect: skip spaces AND punctuation;
            // if the first content token we reach is a newline (or end of text) the
            // -que is verse-final, if it's a word it's mid-line. (The punctuation
            // skip matters: "Cymodoceque." ends que + '.' + newline — without it
            // the -que is misdetected as mid-line and loses the cheap # reading.)
            let verseFinalQue = false;
            if (isHyperEnclitic) {
                let scan = index + 1;
                while (scan < tokens.length) {
                    const t = tokens[scan];
                    if (t.isWord) {
                        verseFinalQue = false;
                        break;
                    } // mid-line -que
                    if (t.isSpace && !t.text.includes('\n')) {
                        scan++;
                        continue;
                    }
                    if (t.text.includes('\n')) {
                        verseFinalQue = true;
                        break;
                    }
                    scan++;
                    continue; // punctuation (e.g. '.', ',') — skip
                }
                if (scan >= tokens.length)
                    verseFinalQue = true;
            }
            while (true) {
                nextIndex++;
                if (nextIndex === tokens.length) {
                    break;
                }
                if (tokens[nextIndex].text.includes('\n')) {
                    if (!isHyperEnclitic)
                        break; // normal word: verse ends here
                    continue; // hypermeter: skip the newline, keep looking
                }
                if (tokens[nextIndex].isSpace) {
                    followingText += ' ';
                }
                else if (tokens[nextIndex].isWord) {
                    followingText += ((_b = tokens[nextIndex].accented) === null || _b === void 0 ? void 0 : _b[0]) || '';
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
            const scans = possibleScans(accentCandidates, followingSegment);
            // Hypermeter: a verse-final -que may elide into the next line (e.g.
            // nexaequ'aere) OR stand as a final anceps syllable. Offer both the
            // line-broken (#) reading and the eliding (V) reading so the automaton
            // can choose whichever lets the hexameter complete.
            if (isHyperEnclitic) {
                // The extra #/V reading is only meaningful for a -que that can elide
                // into a following VOWEL: a verse-final -que (hypermeter into the next
                // line) or a mid-line -que before a vowel (atque, namque). A mid-line
                // -que before a CONSONANT cannot elide — offering the V reading would
                // inject an empty-scansion que[] candidate whose cheap penalty lets the
                // DP skip the syllable and prefer an INCOMPLETE 5-foot scan over the
                // correct complete hexameter (cum tacet omnis... pictaeque volucres:
                // que[S]+volucres[SLL]=6ft pen1 loses to que[]+volucres[SSL]=5ft pen0).
                // So when the following segment is NOT a vowel, offer no extra.
                const canElide = followingSegment === 'V';
                const extra = canElide ? possibleScans(accentCandidates, followingSegment === 'V' ? '#' : 'V') : [];
                let merged;
                if (verseFinalQue) {
                    // Verse-final -que: merge both readings keeping the LOWEST penalty
                    // per (scansion, accent) pair. Dedup-first would keep the
                    // higher-penalty reading: the V (eliding) reading's que[S] costs
                    // HIATUSPENALTY 3 while the # (final-anceps) reading's que[S] costs
                    // 0 — dedup-first drops the cheap # form and the line can never
                    // complete with a real final -que (Aen 5.826 Cymodoceque).
                    const byKey = new Map();
                    for (const s of [...scans, ...extra]) {
                        const key = s.scansion + '|' + s.accented;
                        const existing = byKey.get(key);
                        if (!existing || s.penalty < existing.penalty) {
                            byKey.set(key, s);
                        }
                    }
                    merged = [...byKey.values()];
                }
                else {
                    // Mid-line -que: keep the pre-existing dedup (first-seen wins) so
                    // the candidate set is byte-identical to before — the min-penalty
                    // merge would leak the # reading's cheap penalty into mid-line
                    // contexts and flip chosen quantities (the hīc/vāgīnā regressions).
                    const seen = new Set();
                    merged = [];
                    for (const s of [...scans, ...extra]) {
                        const key = s.scansion + '|' + s.accented;
                        if (!seen.has(key)) {
                            seen.add(key);
                            merged.push(s);
                        }
                    }
                }
                merged.sort((a, b) => a.penalty - b.penalty);
                verse.push([index, merged]);
            }
            else {
                verse.push([index, scans]);
            }
        }
        // End of verse (newline or last token)
        if (token.text.includes('\n') || index === tokens.length - 1) {
            const newlineCount = (token.text.match(/\n/g) || []).length;
            if (verse.length > 0) {
                const { indexAccentPairs, feet } = scanVerse(verse, meterAutomatons[automatonIndex]);
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
            else {
                // Empty verse (e.g. a divider line with no words): emit empty-foot
                // placeholders so scannedFeet stays index-aligned with the source
                // lines. Previously these lines emitted nothing, shifting every
                // subsequent line's feet and producing spurious scansion failures.
                // Advance the meter automaton by the number of empty positions: in an
                // ALTERNATING-meter poem (elegiac distichs = hex/pent), a lacuna
                // (gold line position with no words, e.g. Catullus 68 line 47) still
                // consumes a meter slot — skipping it desyncs every subsequent line
                // (pentameters scanned against the hexameter automaton fail, ~112
                // lines in Catullus 68). For single-meter corpora (hexameter,
                // hendecasyllable) advancing is harmless — the index wraps to 0.
                // (Dividers in single-meter files were the original "don't advance"
                // rationale; in alternating-meter files there are no transcriber
                // dividers, only genuine lacunae.)
                for (let nl = 0; nl < newlineCount; nl++) {
                    scannedFeet.push('');
                    automatonIndex++;
                    if (automatonIndex === meterAutomatons.length) {
                        automatonIndex = 0;
                    }
                }
            }
        }
    }
    return scannedFeet;
}
//# sourceMappingURL=Scansion.js.map