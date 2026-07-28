/**
 * WasmTagger.ts
 * WebAssembly wrapper for RFTagger statistical POS tagger
 * Uses C++ class API from Emscripten (matching test-full-pipeline.html)
 */
import { resolveAssetUrl } from '../utils/assets.js';
/**
 * WebAssembly-based RFTagger implementation
 * Uses Emscripten C++ class API (new RFTagger(), loadModel(), tagSentences())
 */
export class WasmTagger {
    constructor(options = {}) {
        Object.defineProperty(this, "wasmModule", {
            enumerable: true,
            configurable: true,
            writable: true,
            value: void 0
        });
        Object.defineProperty(this, "tagger", {
            enumerable: true,
            configurable: true,
            writable: true,
            value: void 0
        });
        Object.defineProperty(this, "modelLoaded", {
            enumerable: true,
            configurable: true,
            writable: true,
            value: false
        });
        Object.defineProperty(this, "cache", {
            enumerable: true,
            configurable: true,
            writable: true,
            value: void 0
        });
        Object.defineProperty(this, "wasmPath", {
            enumerable: true,
            configurable: true,
            writable: true,
            value: void 0
        });
        Object.defineProperty(this, "wasmDir", {
            enumerable: true,
            configurable: true,
            writable: true,
            value: void 0
        });
        Object.defineProperty(this, "modelUrl", {
            enumerable: true,
            configurable: true,
            writable: true,
            value: void 0
        });
        Object.defineProperty(this, "useSentences", {
            enumerable: true,
            configurable: true,
            writable: true,
            value: void 0
        });
        Object.defineProperty(this, "beamSize", {
            enumerable: true,
            configurable: true,
            writable: true,
            value: void 0
        });
        Object.defineProperty(this, "debugMode", {
            enumerable: true,
            configurable: true,
            writable: true,
            value: void 0
        });
        const effectiveWasmPath = options.wasmPath || '../wasm/rftagger.js';
        this.wasmPath = effectiveWasmPath;
        this.wasmDir = effectiveWasmPath.substring(0, effectiveWasmPath.lastIndexOf('/') + 1);
        this.modelUrl = options.modelUrl || '/wasm/rftagger-ldt.model';
        this.cache = new Map();
        this.useSentences = true;
        this.beamSize = 0.001;
        this.debugMode = false;
    }
    /**
     * Initialize WASM module and load model
     */
    async initialize() {
        try {
            this.wasmModule = await this.loadWasmModule();
            await this.wasmModule.ready;
            this.tagger = new this.wasmModule.RFTagger();
            await this.loadModel();
            this.modelLoaded = true;
        }
        catch (error) {
            console.error('[RFTagger] Initialization failed:', error);
            throw new Error(`Failed to initialize WASM RFTagger: ${error}`);
        }
    }
    /**
     * Load Emscripten-compiled WASM module
     */
    async loadWasmModule() {
        if (typeof window === 'undefined') {
            throw new Error('WASM not supported in this environment');
        }
        const globalRFTagger = window.RFTaggerModule;
        if (globalRFTagger && typeof globalRFTagger === 'function') {
            return await globalRFTagger({
                printErr: () => { },
                locateFile: (path) => resolveAssetUrl(path, path.endsWith('.model') ? this.modelUrl : this.wasmDir + path)
            });
        }
        try {
            const module = await import(this.wasmPath);
            const exported = module.default || module;
            if (typeof exported === 'function') {
                return await exported({
                    locateFile: (path) => {
                        if (path.endsWith('.wasm') || path.endsWith('.data')) {
                            return resolveAssetUrl(path, this.wasmDir + path);
                        }
                        if (path.endsWith('.model')) {
                            return resolveAssetUrl(path, this.modelUrl);
                        }
                        return path;
                    }
                });
            }
            return exported;
        }
        catch (e) {
            throw new Error(`Failed to load RFTagger WASM module from ${this.wasmPath}: ${e}`);
        }
    }
    /**
     * Load the statistical model
     */
    async loadModel() {
        if (!this.tagger) {
            throw new Error('RFTagger instance not created');
        }
        try {
            const response = await fetch(resolveAssetUrl(this.modelUrl, this.modelUrl));
            if (!response.ok) {
                throw new Error(`Failed to fetch model: ${response.status} ${response.statusText}`);
            }
            const modelData = await response.arrayBuffer();
            try {
                this.wasmModule.FS.mkdir('/models');
            }
            catch (e) { }
            this.wasmModule.FS.writeFile('/models/rftagger-ldt.model', new Uint8Array(modelData));
            this.tagger.loadModel('/models/rftagger-ldt.model', this.useSentences, this.beamSize, this.debugMode);
            this.modelLoaded = true;
        }
        catch (error) {
            console.error('[RFTagger] Failed to load model:', error);
            throw new Error(`Failed to load model: ${error}`);
        }
    }
    /**
     * Tag a vector of words using the RFTagger statistical model.
     * Returns tags without confidence values — the WASM embind wrapper does not
     * expose beam probabilities.
     */
    tag(tokens) {
        if (!this.modelLoaded) {
            throw new Error('Model not loaded. Call initialize() first.');
        }
        const cacheKey = tokens.join(' ');
        if (this.cache.has(cacheKey)) {
            return this.cache.get(cacheKey);
        }
        const sentences = [tokens];
        const results = this.tagger.tagSentences(sentences);
        const sentTags = results.get(0);
        const results_array = [];
        for (let i = 0; i < tokens.length; i++) {
            const tag = sentTags.get(i);
            results_array.push({ token: tokens[i], tag });
        }
        this.cache.set(cacheKey, results_array);
        return results_array;
    }
    /**
     * Tag multiple sentences (batch processing).
     * This is the primary method used by the macronization pipeline.
     */
    tagSentences(sentences) {
        if (!this.modelLoaded) {
            throw new Error('Model not loaded. Call initialize() first.');
        }
        const results = this.tagger.tagSentences(sentences);
        const allResults = [];
        for (let s = 0; s < sentences.length; s++) {
            const sentTags = results.get(s);
            const sentenceResults = [];
            for (let i = 0; i < sentences[s].length; i++) {
                const tag = sentTags.get(i);
                sentenceResults.push({ token: sentences[s][i], tag });
            }
            allResults.push(sentenceResults);
        }
        return allResults;
    }
    /**
     * Clear cache
     */
    clearCache() {
        this.cache.clear();
    }
    /**
     * Check if model is loaded
     */
    isReady() {
        return this.modelLoaded && this.tagger !== undefined;
    }
    /**
     * Destroy WASM instance and free resources
     */
    destroy() {
        if (this.tagger) {
            if (this.tagger.delete) {
                this.tagger.delete();
            }
            this.tagger = null;
        }
        this.cache.clear();
        this.modelLoaded = false;
        this.wasmModule = undefined;
    }
}
/**
 * Fallback tagger for when WASM is not available
 */
export class FallbackTagger {
    constructor() {
        Object.defineProperty(this, "patterns", {
            enumerable: true,
            configurable: true,
            writable: true,
            value: void 0
        });
        this.patterns = new Map([
            ['are', 'v1sp'], ['ēre', 'v2sp'], ['ere', 'v3sp'], ['īre', 'v4sp'],
            ['us', 'n-s--m'], ['um', 'n-s--n'], ['a', 'n-s--f'],
            ['us', 'a--s--m'], ['a', 'a--s--f'], ['um', 'a--s--n'],
        ]);
    }
    tag(tokens) {
        return tokens.map(token => {
            const lower = token.toLowerCase();
            let tag = '---------';
            for (const [suffix, patternTag] of this.patterns) {
                if (lower.endsWith(suffix)) {
                    tag = patternTag;
                    break;
                }
            }
            return { token, tag };
        });
    }
}
//# sourceMappingURL=WasmTagger.js.map