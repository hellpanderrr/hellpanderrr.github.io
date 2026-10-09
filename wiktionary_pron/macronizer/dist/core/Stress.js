/**
 * Stress.ts
 * Liturgical prose accentuation (acute placement) for macronized Latin.
 *
 * Implements the notational rules of the Roman liturgical books as documented
 * in gregorio-project/latin-ecclesiastic-accents `doc/accentuation-rules.md`:
 *
 *   1. Words of one or two syllables carry no written accent (the modern rule;
 *      Solesmes' optional "tíbi" convention is not used).
 *   2. With an enclitic (-que, -ne, -ve) the accent falls on the syllable
 *      immediately before the enclitic, whatever its quantity: rosáque,
 *      Filiúmque. Enclitic-ness comes from the token layer (the tokenizer has
 *      already split the word); it is NOT guessed from the letters, or words
 *      like "sanguine" and "carmen" would be misread.
 *   3. Otherwise the penult takes the accent if it is long by nature (long
 *      vowel or diphthong) or by position; else the antepenult: excélsis,
 *      desídero.
 *   4. Muta cum liquida does not make position in prose: génitrix, séptuplum,
 *      vólucres, ténebrae.
 *   5. A diphthong is accented on its first element: cǽli, áuribus.
 *
 * Position counting follows Allen & Greenough §§ 11–12 with the liturgical
 * corpus as arbiter: the glide u of qu is not a consonant (§ 11, Note 3), so
 * dénique / réliquus / áliquid take the antepenult, while a consonantal i
 * closes a syllable like x (§ 11.d): alicúius, eiúsdem.
 *
 * The quantity comes from the macronizer's chosen accented reading (the same
 * `_` / `^` markers the display uses), so the stress always reflects the
 * length marks shown in the text.
 *
 * The syllabifier here is deliberately separate from the verse one in
 * Scansion.segmentAccented, which strips h and expands x/z/qu for the meter.
 */
/**
 * Diphthongs that form one nucleus for accentuation. Measured against the
 * liturgical corpus: `ei` is a hiatus (fí-de-i, e-lé-i-son), and native `eu`
 * is too (cé-re-us); Greek loans with `eu` have a long penult anyway.
 */
const DIPHTHONGS = ['ae', 'au', 'oe'];
/** Muta cum liquida: stop + liquid = one onset for position in prose. */
const MUTA = 'pbtdcgf';
const LIQUID = 'rl';
/** Clusters pronounced as a single consonant for position. */
const SINGLE_SOUND = ['ch', 'th', 'ph'];
const VOWELS = 'aeiouy';
/** Macron (and breve) vowels count as their base vowel for syllabification and
 *  coordinates: they are one character in the input and one in the output, so
 *  mapping stays 1:1 while `sānctificētur` stays a valid stress input. */
const VOWEL_BASE = {
    ā: 'a', ē: 'e', ī: 'i', ō: 'o', ū: 'u', ȳ: 'y',
    ă: 'a', ĕ: 'e', ĭ: 'i', ŏ: 'o', ŭ: 'u',
    Ā: 'a', Ē: 'e', Ī: 'i', Ō: 'o', Ū: 'u', Ȳ: 'y',
    Ă: 'a', Ĕ: 'e', Ĭ: 'i', Ŏ: 'o', Ŭ: 'u',
};
function vowelBase(ch) {
    var _a;
    return (_a = VOWEL_BASE[ch]) !== null && _a !== void 0 ? _a : ch;
}
/**
 * Words whose liturgical syllabification deviates from the plain letter
 * sequence. Values are expected nucleus starts (in the ligature-expanded
 * lowercase string); -1 means "no written accent". Each entry carries its
 * corpus citation.
 */
const STRESS_EXCEPTIONS = {
    // Liturgical synizesis: Iesu(s) counts two syllables, so no accent is
    // written. Corpus: "Iesu Christe" (Gloria), "Iesum Christum" (Credo).
    iesus: -1,
    iesum: -1,
    iesu: -1,
    // Hebrew name with long penult í (rule: -ia "the Lord" accents the penult).
    // Corpus: "María Vírgine" (Credo), "beátæ Maríæ" (Benedictiones).
    maria: 3,
    mariae: 3,
    // Dative of quisque: the ī is long (cuīque), but the wordlist row carries no
    // mark, so the position rule would fall back to the antepenult. Corpus:
    // "prout cuíque opus erat" (Regula Sancti Benedicti ×2 files), "dare
    // unicuíque secúndum ópera sua" (Adventus; Psalterium monasticum 1981).
    cuique: 2,
    // tibi + enclitic -ne (A&G § 12: tĭbĭ'ne). The whole-word rows are forms of
    // the unrelated tibinus, so the token layer never splits and the enclitic
    // rule (rule 2) never fires; the accent is lexically on the ī.
    tibine: 3,
};
/**
 * Expand ligatures to two letters, recording for each expanded position the
 * index of the original character it came from.
 */
function expandLigatures(s) {
    let expanded = '';
    const map = [];
    for (let i = 0; i < s.length; i++) {
        const ch = s[i];
        if (ch === 'æ' || ch === 'Æ') {
            expanded += 'ae';
            map.push(i, i);
        }
        else if (ch === 'œ' || ch === 'Œ') {
            expanded += 'oe';
            map.push(i, i);
        }
        else {
            expanded += ch;
            map.push(i);
        }
    }
    return { expanded, map };
}
/**
 * Split a lowercase, ligature-expanded word into syllable nuclei.
 * `u` after q/g before a vowel is the consonantal glide (quó-ni-am, sán-guis).
 */
function syllabify(word) {
    const nuclei = [];
    let i = 0;
    while (i < word.length) {
        const ch = vowelBase(word[i]);
        if (VOWELS.includes(ch)) {
            const pair = word.slice(i, i + 2).split('').map(vowelBase).join('');
            if (DIPHTHONGS.includes(pair)) {
                nuclei.push({ start: i, end: i + 2 });
                i += 2;
            }
            else if (ch === 'u' &&
                i > 0 &&
                (word[i - 1] === 'q' || word[i - 1] === 'g') &&
                i + 1 < word.length &&
                VOWELS.includes(vowelBase(word[i + 1]))) {
                // Consonantal u in qu/gu — part of the onset, not a nucleus.
                i += 1;
            }
            else {
                nuclei.push({ start: i, end: i + 1 });
                i += 1;
            }
        }
        else {
            i += 1;
        }
    }
    return nuclei;
}
/**
 * Map "index in the length-marked accented string's expanded form" -> marker.
 * A marker applies to the character it follows; `_^` (ambiguous) is treated as
 * short, matching the displayed reading, which shows no macron there.
 */
function lengthMarks(accented) {
    const { expanded } = expandLigatures(accented.toLowerCase());
    const marks = new Map();
    let idx = 0;
    for (const ch of expanded) {
        if (ch === '_' || ch === '^') {
            if (idx > 0)
                marks.set(idx - 1, ch);
        }
        else {
            idx += 1;
        }
    }
    return marks;
}
/**
 * Is the penult (nuclei[length-2]) long?
 * Long by nature: `_` on any nucleus character, or a diphthong nucleus.
 * Long by position: the consonant run up to the next nucleus closes it —
 * x/z count double, ch/th/ph count single, exactly one muta cum liquida pair
 * counts single, and the glide u of qu/gu counts not at all: it belongs to
 * the onset, so dé-ni-que has an open penult (A&G § 11, Note 3 — "nor is the
 * apparently consonantal u in qu, gu, su"; the corpus writes dénique, réliqui,
 * áliquid, útique, ítaque, never deníque / relíqui / alíquid).
 * A consonantal i (j) makes position by itself, like x/z (liturgical rules,
 * quantity Rule 3: "x, z or a semi-consonantic i"; A&G § 11. d) — that is how
 * alicúius takes its penult accent (corpus: Regula Sancti Benedicti).
 */
function penultIsLong(word, nuclei, marks) {
    const penult = nuclei[nuclei.length - 2];
    for (let p = penult.start; p < penult.end; p++) {
        if (marks.get(p) === '_')
            return true;
    }
    if (penult.end - penult.start === 2)
        return true; // diphthong
    const interlude = word.slice(penult.end, nuclei[nuclei.length - 1].start);
    if (interlude === '')
        return false;
    if (SINGLE_SOUND.includes(interlude))
        return false;
    if (interlude.length === 2 &&
        MUTA.includes(interlude[0]) &&
        LIQUID.includes(interlude[1])) {
        return false;
    }
    let count = 0;
    for (let p = 0; p < interlude.length; p++) {
        const ch = interlude[p];
        // The glide u of qu belongs to the onset, not the coda: dé-ni-que and
        // ré-li-qus have an open penult (A&G § 11, Note 3: "nor is the apparently
        // consonantal u in qu, gu, su"; the corpus writes dénique, réliqui,
        // áliquid, útique, ítaque, ántequam — never deníque / relíqui / alíquid).
        // gu is deliberately NOT skipped the same way: with the glide collapsed
        // by syllabify(), counting g+u as two consonants is what keeps the accent
        // on the i in -guu- spellings (ambíguus, exíguus; corpus: "Stat rex
        // ambíguus"). sánguine and unguéntum go through the onset-glide rule in
        // syllabify() instead.
        if (ch === 'u' && p > 0 && interlude[p - 1] === 'q')
            continue;
        // A consonantal i (j) closes the syllable by itself, like x/z (liturgical
        // quantity Rule 3: "x, z or a semi-consonantic i"; A&G § 11. d):
        // a-li-CÚ-ius, ei-ÚS-dem — corpus: alicúius, eiúsdem.
        count += ch === 'x' || ch === 'z' || ch === 'j' ? 2 : 1;
    }
    return count >= 2;
}
/**
 * Choose the accented nucleus start (in expanded coordinates) of a wordlist
 * accented form. Returns null when the word carries no written accent.
 * `enclitic` is set by the token layer for a split bearer (-que/-ne/-ve).
 */
function chooseNucleus(accented, enclitic) {
    const plain = accented.replace(/[_\^]/g, '').toLowerCase();
    const { expanded } = expandLigatures(plain);
    const exception = STRESS_EXCEPTIONS[expanded];
    if (exception !== undefined) {
        return exception >= 0 ? exception : null;
    }
    const nuclei = syllabify(expanded);
    if (nuclei.length < 3)
        return null; // rule 1
    // Rule 2: an enclitic moves the accent to the syllable before it, whatever
    // its quantity (rosáque, Filiúmque).
    if (enclitic)
        return nuclei[nuclei.length - 2].start;
    const marks = lengthMarks(accented);
    return penultIsLong(expanded, nuclei, marks)
        ? nuclei[nuclei.length - 2].start
        : nuclei[nuclei.length - 3].start;
}
/**
 * Place the stress accent on `plain`, given the accented (underscore-marked)
 * reading the macronizer chose.
 *
 * The vowel position is mapped back from the ligature-expanded coordinates to
 * `plain`'s own characters, so `cælis` would yield `cǽlis` (the acute lands on
 * the ligature) and `maior` accents its own `a`.
 *
 * Returns `plain` unchanged when the word carries no written accent or when
 * the mapping fails — never a wrong accent.
 */
export function applyStress(plain, accented, enclitic = false) {
    const nucleusStart = chooseNucleus(accented, enclitic);
    if (nucleusStart === null)
        return plain;
    const { expanded, map } = expandLigatures(plain);
    if (nucleusStart >= map.length)
        return plain;
    const originalIndex = map[nucleusStart];
    // The displayed word may already carry a macron/breve on the target vowel
    // (sānctificētur): compare on the base vowel.
    const target = vowelBase(expanded[nucleusStart].toLowerCase());
    if (originalIndex === undefined ||
        !VOWELS.includes(target)) {
        return plain;
    }
    const stressed = plain.slice(0, originalIndex + 1) + '́' + plain.slice(originalIndex + 1);
    return stressed.normalize('NFC');
}
//# sourceMappingURL=Stress.js.map