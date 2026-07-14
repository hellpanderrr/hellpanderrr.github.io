/**
 * Macronizer.ts
 * Core macronization engine integrating WASM RFTagger with Latin rules
 * Orchestrates tokenization, POS tagging, and vowel length assignment
 */
import { Tokenization } from './Tokenization.js';
import { WasmTagger, FallbackTagger } from '../analysis/WasmTagger.js';
import { LemmaEngine } from '../analysis/LemmaEngine.js';
import { EndingPatternEngine } from '../analysis/EndingPatternEngine.js';
import { WordlistEngine } from '../analysis/WordlistEngine.js';
import { MorpheusAnalyzer } from '../analysis/MorpheusAnalyzer.js';
import { toAscii } from '../utils/latin.js';
// Import meters data
import metersData from '../data/meters.json' with { type: 'json' };
/**
 * Main macronization engine
 * Coordinates all components for Latin text processing
 */
export class Macronizer {
    constructor(options = {}) {
        var _a, _b;
        Object.defineProperty(this, "tagger", {
            enumerable: true,
            configurable: true,
            writable: true,
            value: void 0
        });
        Object.defineProperty(this, "lemmaEngine", {
            enumerable: true,
            configurable: true,
            writable: true,
            value: void 0
        });
        Object.defineProperty(this, "endingEngine", {
            enumerable: true,
            configurable: true,
            writable: true,
            value: void 0
        });
        Object.defineProperty(this, "wordlistEngine", {
            enumerable: true,
            configurable: true,
            writable: true,
            value: void 0
        });
        Object.defineProperty(this, "morpheusAnalyzer", {
            enumerable: true,
            configurable: true,
            writable: true,
            value: null
        });
        Object.defineProperty(this, "useWasm", {
            enumerable: true,
            configurable: true,
            writable: true,
            value: void 0
        });
        Object.defineProperty(this, "cache", {
            enumerable: true,
            configurable: true,
            writable: true,
            value: void 0
        });
        Object.defineProperty(this, "wordlistUrl", {
            enumerable: true,
            configurable: true,
            writable: true,
            value: void 0
        });
        Object.defineProperty(this, "morpheusWasmPath", {
            enumerable: true,
            configurable: true,
            writable: true,
            value: void 0
        });
        this.useWasm = (_a = options.useWasm) !== null && _a !== void 0 ? _a : true;
        this.cache = new Map();
        this.lemmaEngine = new LemmaEngine();
        this.endingEngine = new EndingPatternEngine();
        this.wordlistEngine = new WordlistEngine();
        this.wordlistUrl = options.wordlistUrl;
        this.morpheusWasmPath = options.morpheusWasmPath || '../wasm/cruncher.js';
        // Initialize tagger based on configuration
        if (this.useWasm) {
            this.tagger = new WasmTagger({
                modelUrl: options.wasmModelPath,
                wasmPath: options.wasmPath,
                enableCache: (_b = options.enableCache) !== null && _b !== void 0 ? _b : true,
            });
        }
        else {
            this.tagger = new FallbackTagger();
        }
        // Initialize Morpheus for unknown word analysis
        this.morpheusAnalyzer = new MorpheusAnalyzer(this.morpheusWasmPath);
    }
    /**
     * Initialize the macronizer (load WASM module if enabled)
     */
    async initialize(onProgress) {
        if (this.useWasm) {
            onProgress === null || onProgress === void 0 ? void 0 : onProgress(5, 'Loading RFTagger WASM...');
            const wasmTagger = this.tagger;
            await wasmTagger.initialize();
        }
        onProgress === null || onProgress === void 0 ? void 0 : onProgress(15, 'Loading lemma dictionary...');
        await this.lemmaEngine.load();
        await this.endingEngine.load();
        // Initialize Morpheus and connect to WordlistEngine
        if (this.morpheusAnalyzer) {
            onProgress === null || onProgress === void 0 ? void 0 : onProgress(20, 'Initializing Morpheus...');
            await this.morpheusAnalyzer.initialize();
            this.wordlistEngine.setMorpheusAnalyzer(this.morpheusAnalyzer);
            console.log('[Macronizer] Morpheus initialized and connected to WordlistEngine');
        }
        // Load wordlist if URL provided
        console.log('[Macronizer] wordlistUrl:', this.wordlistUrl);
        if (this.wordlistUrl) {
            console.log('[Macronizer] Checking if wordlist is populated...');
            const isPopulated = await this.wordlistEngine.isPopulated();
            console.log('[Macronizer] isPopulated:', isPopulated, 'size:', this.wordlistEngine.size());
            if (!isPopulated) {
                console.log('[Macronizer] Loading wordlist from:', this.wordlistUrl);
                onProgress === null || onProgress === void 0 ? void 0 : onProgress(25, 'Loading wordlist...');
                await this.wordlistEngine.loadFromUrl(this.wordlistUrl, (count) => {
                    // Map 0..812k entries → 25..95%
                    const percent = 25 + Math.round(count / 812588 * 70);
                    onProgress === null || onProgress === void 0 ? void 0 : onProgress(percent, `Loading wordlist: ${count.toLocaleString()} entries...`);
                });
                console.log(`[Macronizer] Wordlist loaded: ${this.wordlistEngine.size()} entries`);
            }
            else {
                console.log(`[Macronizer] Wordlist already in IndexedDB: ${this.wordlistEngine.size()} entries`);
            }
        }
        else {
            console.warn('[Macronizer] No wordlistUrl set, wordlist will not be loaded!');
        }
        onProgress === null || onProgress === void 0 ? void 0 : onProgress(95, 'Finalizing...');
    }
    /**
     * Macronize Latin text
     * Main entry point for text processing
     * Uses Tokenization pipeline with DP alignment
     */
    async macronize(text, options = {}) {
        const startTime = performance.now();
        // Clear the wordlist entry cache so each macronize() starts fresh.
        // The cache repopulates on the first pass (ensureAnalyzed) and serves
        // subsequent passes (addLemmas, getAccents) without redundant IDB trips.
        this.wordlistEngine.clearEntriesCache();
        // Default options
        const doMacronize = options.macronize !== false; // default true
        const alsomaius = options.alsomaius === true; // default false
        const performutov = options.performutov === true; // default false
        const performitoj = options.performitoj === true; // default false
        const scanOption = options.scan || 'prose'; // default: no scansion
        // Check cache (hashing the text avoids multi-kilobyte cache keys)
        const textHash = hashFnv32(text);
        const cacheKey = `${textHash}|m=${doMacronize}|a=${alsomaius}|v=${performutov}|j=${performitoj}|s=${scanOption}`;
        if (this.cache.has(cacheKey)) {
            return this.cache.get(cacheKey);
        }
        // Step 1: Tokenize (preserve whitespace for accurate reconstruction)
        const tokenization = new Tokenization(text, { preserveWhitespace: true });
        const originalTokens = tokenization.tokens.map(t => t.with({}));
        // Step 1.5: Split enclitics (deferred, Python-compatible strategy)
        const splitWordForms = await tokenization.splitEnclitics(this.wordlistEngine);
        // Step 1.75: Pre-analyze unknown words with Morpheus (matches Python wordlist.loadwords())
        const allWordForms = [
            ...tokenization.allWordForms(),
            ...splitWordForms
        ];
        await this.wordlistEngine.ensureAnalyzed(allWordForms);
        // Mark tokens as analyzed by Morpheus and attach full Morpheus results for UI display
        // Only tokens for words that were actually analyzed by Morpheus (not just in wordlist) get morpheusAnalyzed=true
        for (let i = 0; i < tokenization.tokens.length; i++) {
            const t = tokenization.tokens[i];
            if (t.isWord && !t.isenclitic) {
                // Normalize same way as ensureAnalyzed (toAscii + lowercase + trim) for cache lookup
                const wordNorm = toAscii(t.text).toLowerCase().trim();
                // Check if this word has Morpheus analysis cached (i.e., was unknown and analyzed)
                if (this.wordlistEngine.hasMorpheusAnalysis(wordNorm)) {
                    const morpheusResults = this.wordlistEngine.getMorpheusAnalysis(wordNorm);
                    tokenization.tokens[i] = t.with({
                        morpheusAnalyzed: true,
                        morpheusResults: morpheusResults !== null && morpheusResults !== void 0 ? morpheusResults : null
                    });
                }
            }
        }
        // Step 2: POS Tagging (WASM or fallback)
        if (this.useWasm && this.tagger.isReady()) {
            const t0 = performance.now();
            await tokenization.tagWithWasm(this.tagger);
            console.error(`WASM tag: ${(performance.now() - t0).toFixed(0)}ms`);
        }
        else {
            const wordsToTag = tokenization.allWordForms();
            const fallbackResults = this.tagger.tag(wordsToTag);
            tokenization.addTags(fallbackResults.map(r => ({ word: r.token, tag: r.tag })));
        }
        // Step 3: Add lemmas (two-tier: corpus lookup + wordlist frequency fallback)
        await tokenization.addLemmas(this.lemmaEngine, this.wordlistEngine);
        // Step 4: Get accents (wordlist lookup + candidate ranking)
        await tokenization.getAccents(this.wordlistEngine, this.endingEngine);
        // Step 4.5: Scansion (reorder accented candidates for best meter fit)
        let scannedFeet = [];
        if (scanOption !== 'prose') {
            const allMeters = metersData;
            // Compound meter dispatch: some options alternate between two meters
            const meterMap = {
                'dactylichexameter': [allMeters['dactylichexameter']],
                'hendecasyllable': [allMeters['hendecasyllable']],
                'elegiacdistichs': [allMeters['dactylichexameter'], allMeters['dactylicpentameter']],
                'iambic': [allMeters['iambictrimeter'], allMeters['iambicdimeter']],
            };
            const automatons = meterMap[scanOption];
            if (automatons) {
                console.log(`[Macronizer] Scanning verse as ${scanOption}...`);
                tokenization.scanVerses(automatons);
                scannedFeet = tokenization.scannedFeet;
                console.log(`[Macronizer] Scansion complete: ${scannedFeet.length} verse(s) scanned`);
            }
        }
        // Step 5: Macronize (DP alignment with alsomaius)
        tokenization.macronize(doMacronize, alsomaius, performutov, performitoj);
        // Final tokens
        const macronizedTokens = tokenization.tokens;
        // Step 6: Reconstruct text
        const macronizedText = tokenization.detokenize();
        // Calculate word coverage (fraction of tokens recognized by lemma or pattern engine)
        const coverage = this.calcCoverage(originalTokens, macronizedTokens);
        const statistics = this.calculateStatistics(originalTokens, macronizedTokens);
        const result = {
            original: text,
            macronized: macronizedText,
            tokens: originalTokens,
            taggedTokens: macronizedTokens,
            confidence: coverage,
            processingTime: performance.now() - startTime,
            statistics,
            scannedFeet,
        };
        // Cache result
        this.cache.set(cacheKey, result);
        return result;
    }
    /**
     * Calculate word coverage fraction: what proportion of tokens are recognized
     * by the lemma or ending-pattern engine.  This is NOT a probabilistic
     * confidence score — it measures whether each token was even known to any
     * lookup table.  A word that hits the lemma engine gets 0.95, a word that
     * only matches an ending pattern gets 0.85, and an entirely unknown word
     * gets 0.60.  These are arbitrary labels, not Viterbi beam probabilities.
     */
    calcCoverage(tokens, macronized) {
        let totalConfidence = 0;
        let count = 0;
        for (let i = 0; i < tokens.length; i++) {
            const token = tokens[i];
            // High confidence for lemma matches
            if (this.lemmaEngine.hasLemma(token.text)) {
                totalConfidence += 0.95;
            }
            // Medium confidence for pattern matches
            else if (this.endingEngine.hasPattern(token.text)) {
                totalConfidence += 0.85;
            }
            // Default confidence
            else {
                totalConfidence += 0.60;
            }
            count++;
        }
        return count > 0 ? totalConfidence / count : 0;
    }
    /**
     * Calculate statistics about the macronization
     */
    calculateStatistics(tokens, macronized) {
        let totalWords = 0;
        let knownWords = 0;
        let unknownWords = 0;
        let ambiguousForms = 0;
        for (let i = 0; i < tokens.length; i++) {
            const token = tokens[i];
            const mac = macronized[i];
            // Skip punctuation and non-word tokens
            if (!token.isWord) {
                continue;
            }
            totalWords++;
            // Check if known (has lemma or pattern match)
            if (this.lemmaEngine.hasLemma(token.text) || this.endingEngine.hasPattern(token.text)) {
                knownWords++;
            }
            else {
                unknownWords++;
            }
            // Check if ambiguous (original has diacritics or multiple forms)
            if (mac.isAmbiguous || (mac.accented && mac.accented.length > 1)) {
                ambiguousForms++;
            }
        }
        return {
            totalWords,
            knownWords,
            unknownWords,
            ambiguousForms,
        };
    }
    /**
     * Batch process multiple texts
     */
    async macronizeBatch(texts) {
        const results = [];
        for (const text of texts) {
            const result = await this.macronize(text);
            results.push(result);
        }
        return results;
    }
    /**
     * Clear cache
     */
    clearCache() {
        this.cache.clear();
        if (this.useWasm) {
            this.tagger.clearCache();
        }
    }
    /**
     * Get cache size
     */
    getCacheSize() {
        return this.cache.size;
    }
    /**
     * Check if initialized
     */
    isReady() {
        if (this.useWasm) {
            return this.tagger.isReady();
        }
        return true;
    }
    /**
     * Destroy resources
     */
    destroy() {
        if (this.useWasm) {
            this.tagger.destroy();
        }
        this.wordlistEngine.close();
        this.cache.clear();
    }
    /**
     * Load wordlist (exposed for API — used when wordlist not loaded during initialize).
     */
    async loadWordlist(onProgress) {
        if (!this.wordlistUrl) {
            throw new Error('No wordlistUrl configured');
        }
        const isPopulated = await this.wordlistEngine.isPopulated();
        if (isPopulated) {
            console.log('[Macronizer] Wordlist already loaded, skipping');
            return;
        }
        await this.wordlistEngine.loadFromUrl(this.wordlistUrl, (count) => {
            if (onProgress) {
                onProgress({ phase: 'parse', current: count, total: 812588 });
            }
        });
    }
    isWordlistLoaded() {
        return this.wordlistEngine.size() > 0;
    }
    getWordlistEntryCount() {
        return this.wordlistEngine.size();
    }
    getWordlistMode() {
        // Always 'indexeddb' — the wordlist engine always uses IndexedDB when available
        return 'indexeddb';
    }
    async clearWordlistCache() {
        // Actually empty the IndexedDB store — closing the connection left the data on disk.
        await this.wordlistEngine.clear();
        this.wordlistEngine.clearEntriesCache();
        this.clearCache();
    }
}
/**
 * FNV-1a 32-bit hash — fast, deterministic, keeps cache keys short
 * even when the input text spans thousands of characters.
 */
function hashFnv32(str) {
    let h = 0x811c9dc5;
    for (let i = 0; i < str.length; i++) {
        h ^= str.charCodeAt(i);
        h = Math.imul(h, 0x01000193);
    }
    // Return unsigned hex to keep the key readable
    return (h >>> 0).toString(16);
}
//# sourceMappingURL=Macronizer.js.map