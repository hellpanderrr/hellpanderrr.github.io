/**
 * Latin Macronizer - Browser Edition
 * Main entry point for the library
 *
 * Based on the original Python latin_macronizer by Johan Winge
 * Ported to TypeScript for browser use with WebAssembly
 */
export { Macronizer, Token, Tokenization, Tokenizer } from './core/index.js';
export { WasmTagger, WasmTaggerOptions, TagResult, LemmaEngine, EndingPatternEngine, FallbackTagger, MorpheusAnalyzer } from './analysis/index.js';
import { MacronizerAPI } from './api/MacronizerAPI.js';
export { MacronizerAPI };
export type { ScanOption, } from './types/index.js';
export { toAscii, toUiOrthography, fromUiOrthography, isVowel, isConsonant, startsWithVowel, startsWithShortJPrefix, normalizeWord, splitSentences, isSentenceEnder, isPunctuation, isWhitespace, splitEnclitic, findVowelClusters, isAmbiguousVowel, escapeHtml, enclitics, prefixesWithShortJ } from './utils/latin.js';
export declare const VERSION = "1.0.0";
export declare const AUTHOR = "Johan Winge";
export declare const LICENSE = "MIT";
//# sourceMappingURL=index.d.ts.map