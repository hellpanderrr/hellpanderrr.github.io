/**
 * Tokenization module
 * Ported from latin_macronizer/tokenization.py
 * Handles Latin text tokenization with enclitic support
 */
import { Token } from './Token';
import { WasmTagger } from '../analysis/WasmTagger';
import { LemmaEngine } from '../analysis/LemmaEngine';
import { EndingPatternEngine } from '../analysis/EndingPatternEngine';
import { WordlistEngine } from '../analysis/WordlistEngine';
import { MeterAutomaton } from './Scansion';
export interface TokenizationOptions {
    preserveWhitespace?: boolean;
}
/**
 * Tokenization class - splits Latin text into tokens
 * Handles enclitics (-que, -ve, -ne), sentence boundaries
 */
export declare class Tokenization {
    tokens: Token[];
    text: string;
    originalText: string;
    private _scannedFeet;
    private static dividenda;
    private static specialEncliticWords;
    constructor(text: string, options?: TokenizationOptions);
    /**
     * Main tokenization method
     */
    /**
     * Tokenize text into words, whitespace, and punctuation.
     * Sentence boundary detection matches Python tokenization.py exactly:
     * - A punctuation mark (.;:?!) ends a sentence ONLY if the preceding word
     *   was longer than 1 character. This prevents false boundaries at Latin
     *   abbreviations like "M." (Marcus), "L." (Lucius), "ā. d." (ante diem).
     * - Single-char words + period do NOT end the sentence.
     */
    private tokenize;
    /**
     * Detect sentence boundaries and mark startssentence on tokens
     */
    private detectSentenceBoundaries;
    /**
     * Add a word token (without splitting enclitics yet)
     */
    private addWordToken;
    /**
     * Split enclitics after wordlist is loaded (Python's two-pass strategy)
     * Returns list of word forms that need to be tagged (excluding enclitics)
     */
    splitEnclitics(wordlistEngine: WordlistEngine): Promise<string[]>;
    /**
     * Get all word forms for lookup
     */
    allWordForms(): string[];
    /**
     * Add tags to tokens from RFTagger output
     */
    addTags(tags: Array<{
        word: string;
        tag: string;
    }>): void;
    /**
     * Tag tokens using WasmTagger
     * Gets words from tokens and applies POS tags from RFTagger
     */
    tagWithWasm(tagger: WasmTagger): Promise<void>;
    /**
     * Add lemmas to tokens.
     * Exact port of Python tokenization.py addlemmas():
     *   wordform = toascii(token.text)          # ORIGINAL case
     *   best_lemma = "-"; max_freq = -1
     *   Tier 1: wordform in wordform_to_corpus_lemmas →
     *           best corpus lemma by word_lemma_freq[(wordform, lemma)]
     *   Tier 2: wordform.lower() in wordlist.formtolemmas →
     *           best wordlist lemma by lemma_frequency.get(lemma, 0)
     * (No POS tag involved; strict > keeps the FIRST max in iteration order.)
     */
    addLemmas(lemmaEngine: LemmaEngine, wordlistEngine?: WordlistEngine): Promise<void>;
    /**
     * Get accents for tokens
     * Ported from latin_macronizer/tokenization.py (getaccents method)
     * Determines the best accented form (with _ markers) for each token
     */
    getAccents(wordlistEngine: WordlistEngine, endingEngine: EndingPatternEngine): Promise<void>;
    /**
     * Apply macronization to all tokens
     */
    macronize(domacronize: boolean, alsomaius: boolean, performutov: boolean, performitoj: boolean): void;
    /**
     * Macronize single token
     * Ported from latin_macronizer/tokenization.py (macronize method)
     * Uses DP alignment to add macrons to the token's accented form
     */
    private macronizeToken;
    /**
     * Convert tokens back to text
     */
    detokenize(): string;
    /**
     * Get plain text without HTML
     */
    getPlainText(): string;
    /**
     * Scan verses using meter automata
     */
    scanVerses(meterAutomatons: MeterAutomaton[]): void;
    /**
     * Get scanned feet (if scansion was performed)
     */
    get scannedFeet(): string[];
}
//# sourceMappingURL=Tokenization.d.ts.map