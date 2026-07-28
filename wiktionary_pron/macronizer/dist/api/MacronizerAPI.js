/**
 * MacronizerAPI.ts
 * Simple API wrapper for the Latin Macronizer (used by index.html)
 * Imports compiled TypeScript modules from dist/ and exposes a clean interface
 */
import { Macronizer } from '../core/Macronizer.js';
export class MacronizerAPI {
    constructor() {
        Object.defineProperty(this, "macronizer", {
            enumerable: true,
            configurable: true,
            writable: true,
            value: null
        });
        Object.defineProperty(this, "initialized", {
            enumerable: true,
            configurable: true,
            writable: true,
            value: false
        });
        this.macronizer = null;
        this.initialized = false;
    }
    async initialize(onProgress) {
        if (this.initialized)
            return;
        console.log('[MacronizerAPI] initialize() called');
        // Create macronizer with default options
        this.macronizer = new Macronizer({
            useWasm: true,
            enableCache: true,
            // Paths relative to Vite server root (public/ serves as /)
            wasmModelPath: '/wiktionary_pron/macronizer/wasm/rftagger-ldt.model', // Path to the model file
            wasmPath: '/wiktionary_pron/macronizer/wasm/rftagger.js', // Path to the JS wrapper
            morpheusWasmPath: '/wiktionary_pron/macronizer/wasm/cruncher.js',
            wordlistUrl: '/wiktionary_pron/macronizer/macrons.txt.gz' // ← ADDED: Load wordlist from public/
        });
        console.log('[MacronizerAPI] Macronizer created, wordlistUrl:', '/wiktionary_pron/macronizer/macrons.txt.gz');
        console.log('[MacronizerAPI] Calling macronizer.initialize()...');
        await this.macronizer.initialize((percent, message) => {
            onProgress === null || onProgress === void 0 ? void 0 : onProgress(percent, message);
        });
        console.log('[MacronizerAPI] macronizer.initialize() completed');
        onProgress === null || onProgress === void 0 ? void 0 : onProgress(100, 'Ready!');
        this.initialized = true;
        console.log('MacronizerAPI: initialized');
    }
    async process(text, options = {}) {
        if (!this.initialized || !this.macronizer) {
            throw new Error('Macronizer not initialized. Call initialize() first.');
        }
        const result = await this.macronizer.macronize(text, {
            macronize: options.macronize !== false,
            alsomaius: options.alsomaius || false,
            performutov: options.performutov || false,
            performitoj: options.performitoj || false,
            scan: options.scan || 'prose'
        });
        // Convert Token objects to plain JSON for serialization
        const tokens = result.taggedTokens.map((t) => ({
            text: t.text,
            tag: t.tag,
            lemma: t.lemma,
            macronizedText: t.macronizedText,
            isAmbiguous: t.isAmbiguous,
            isUnknown: t.isUnknown,
            morpheusAnalyzed: t.morpheusAnalyzed,
            morpheusResults: t.morpheusResults ? {
                word: t.morpheusResults.word,
                analyses: t.morpheusResults.analyses.map((a) => ({
                    lemma: a.lemma,
                    stem: a.stem,
                    ending: a.ending,
                    accented: a.accented,
                    formInfo: a.formInfo,
                    raw: a.raw
                })),
                success: t.morpheusResults.success,
                raw: t.morpheusResults.raw
            } : null,
            startIndex: t.startIndex,
            endIndex: t.endIndex,
            accented: t.accented,
            accentedSources: t.accentedSources,
            hasenclitic: t.hasenclitic,
            isenclitic: t.isenclitic,
            startssentence: t.startssentence
        }));
        return {
            original: result.original,
            macronized: result.macronized,
            tokens,
            statistics: result.statistics,
            confidence: result.confidence,
            processingTime: result.processingTime,
            scannedFeet: result.scannedFeet
        };
    }
    destroy() {
        if (this.macronizer) {
            this.macronizer.destroy();
            this.macronizer = null;
            this.initialized = false;
        }
    }
    isReady() {
        return this.initialized && this.macronizer !== null && this.macronizer.isReady();
    }
    /**
     * Load wordlist (called from UI). If already loaded during initialize(), this is a no-op.
     * Otherwise, loads from the configured wordlistUrl.
     */
    async loadWordlist(_mode, onProgress) {
        if (!this.macronizer) {
            throw new Error('Macronizer not created. Call initialize() first.');
        }
        console.log(`[MacronizerAPI] loadWordlist(mode=${_mode}) called`);
        await this.macronizer.loadWordlist(onProgress);
    }
    isWordlistLoaded() {
        var _a, _b;
        return (_b = (_a = this.macronizer) === null || _a === void 0 ? void 0 : _a.isWordlistLoaded()) !== null && _b !== void 0 ? _b : false;
    }
    getWordlistEntryCount() {
        var _a;
        return ((_a = this.macronizer) === null || _a === void 0 ? void 0 : _a.getWordlistEntryCount()) || 0;
    }
    getWordlistMode() {
        var _a, _b;
        return (_b = (_a = this.macronizer) === null || _a === void 0 ? void 0 : _a.getWordlistMode()) !== null && _b !== void 0 ? _b : 'indexeddb';
    }
    async clearWordlistCache() {
        var _a;
        await ((_a = this.macronizer) === null || _a === void 0 ? void 0 : _a.clearWordlistCache());
    }
}
export default MacronizerAPI;
//# sourceMappingURL=MacronizerAPI.js.map