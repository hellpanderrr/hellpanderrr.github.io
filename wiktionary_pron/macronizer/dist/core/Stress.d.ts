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
 * The quantity comes from the macronizer's chosen accented reading (the same
 * `_` / `^` markers the display uses), so the stress always reflects the
 * length marks shown in the text.
 *
 * The syllabifier here is deliberately separate from the verse one in
 * Scansion.segmentAccented, which strips h and expands x/z/qu for the meter.
 */
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
export declare function applyStress(plain: string, accented: string, enclitic?: boolean): string;
//# sourceMappingURL=Stress.d.ts.map