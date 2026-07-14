/**
 * WasmTagger.ts
 * WebAssembly wrapper for RFTagger statistical POS tagger
 * Uses C++ class API from Emscripten (matching test-full-pipeline.html)
 */
export interface WasmTaggerOptions {
    wasmPath?: string;
    modelUrl?: string;
    memorySize?: number;
    enableCache?: boolean;
}
export interface TagResult {
    token: string;
    tag: string;
}
/**
 * WebAssembly-based RFTagger implementation
 * Uses Emscripten C++ class API (new RFTagger(), loadModel(), tagSentences())
 */
export declare class WasmTagger {
    private wasmModule;
    private tagger;
    private modelLoaded;
    private cache;
    private readonly wasmPath;
    private readonly wasmDir;
    private readonly modelUrl;
    private readonly useSentences;
    private readonly beamSize;
    private readonly debugMode;
    constructor(options?: WasmTaggerOptions);
    /**
     * Initialize WASM module and load model
     */
    initialize(): Promise<void>;
    /**
     * Load Emscripten-compiled WASM module
     */
    private loadWasmModule;
    /**
     * Load the statistical model
     */
    private loadModel;
    /**
     * Tag a vector of words using the RFTagger statistical model.
     * Returns tags without confidence values — the WASM embind wrapper does not
     * expose beam probabilities.
     */
    tag(tokens: string[]): TagResult[];
    /**
     * Tag multiple sentences (batch processing).
     * This is the primary method used by the macronization pipeline.
     */
    tagSentences(sentences: string[][]): TagResult[][];
    /**
     * Clear cache
     */
    clearCache(): void;
    /**
     * Check if model is loaded
     */
    isReady(): boolean;
    /**
     * Destroy WASM instance and free resources
     */
    destroy(): void;
}
/**
 * Fallback tagger for when WASM is not available
 */
export declare class FallbackTagger {
    private patterns;
    constructor();
    tag(tokens: string[]): TagResult[];
}
//# sourceMappingURL=WasmTagger.d.ts.map