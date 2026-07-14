/**
 * MacronizerAPI.ts
 * Simple API wrapper for the Latin Macronizer (used by index.html)
 * Imports compiled TypeScript modules from dist/ and exposes a clean interface
 */
import type { Statistics } from '../core/Macronizer.js';
import type { MorpheusAnalysis } from '../analysis/MorpheusAnalyzer.js';
/** JSON-serialized token shape returned by MacronizerAPI.process() */
export interface ApiToken {
    text: string;
    tag: string;
    lemma: string;
    macronizedText?: string;
    isAmbiguous?: boolean;
    isUnknown?: boolean;
    morpheusAnalyzed?: boolean;
    morpheusResults?: MorpheusAnalysis | null;
    startIndex?: number;
    endIndex?: number;
    accented?: string[];
}
/** Return type of MacronizerAPI.process() */
export interface ApiResult {
    original: string;
    macronized: string;
    tokens: ApiToken[];
    statistics: Statistics;
    confidence: number;
    processingTime: number;
    scannedFeet?: string[];
}
export declare class MacronizerAPI {
    private macronizer;
    private initialized;
    constructor();
    initialize(onProgress?: (percent: number, message: string) => void): Promise<void>;
    process(text: string, options?: any): Promise<ApiResult>;
    destroy(): void;
    isReady(): boolean;
    /**
     * Load wordlist (called from UI). If already loaded during initialize(), this is a no-op.
     * Otherwise, loads from the configured wordlistUrl.
     */
    loadWordlist(_mode: 'indexeddb' | 'memory', onProgress?: (progress: any) => void): Promise<void>;
    isWordlistLoaded(): boolean;
    getWordlistMode(): string;
    clearWordlistCache(): Promise<void>;
}
export default MacronizerAPI;
//# sourceMappingURL=MacronizerAPI.d.ts.map