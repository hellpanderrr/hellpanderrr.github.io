/**
 * MorpheusAnalyzer.ts
 * TypeScript wrapper for Morpheus WASM morphological analyzer
 *
 * Provides clean API for analyzing Latin words using Morpheus engine
 * compiled to WebAssembly. Matches Python latin_macronizer.wordlist.crunchwords()
 */
import { resolveAssetUrl } from '../utils/assets.js';
// PrntFlags from prntflags.h (decimal values)
const SHOW_ANAL = 1; // 0o1
const SHOW_LEMMA = 2; // 0o2
const SHOW_MISSES = 4; // 0o4
const BUFFER_ANALS = 8; // 0o10
const CHECK_PREVERB = 16; // 0o20
const KEEP_BETA = 32; // 0o40
const SHOW_FULL_INFO = 64; // 0o100
const DBASEFORMAT = 128; // 0o200
const DBASESHORT = 384; // 0o400|DBASEFORMAT
const STRICT_CASE = 512; // 0o1000
const PARSE_FORMAT = 1024; // 0o2000
const PERSEUS_FORMAT = 2048; // 0o4000
const ENDING_INDEX = 4096; // 0o10000
const IGNORE_ACCENTS = 8192; // 0o20000
const LEXICON_OUTPUT = 16384; // 0o40000
const GREEK = 0; // 0
const LATIN = 32768; // 0o100000
const LEMCOUNT = 65536; // 0o200000
const VERBS_ONLY = 131072; // 0o400000
const ITALIAN = 262144; // 0o1000000
/**
 * MorpheusAnalyzer class
 * WebAssembly wrapper for Morpheus morphological analyzer
 */
export class MorpheusAnalyzer {
    constructor(wasmPath = '/wasm/cruncher.js', debug = false) {
        Object.defineProperty(this, "wasmModule", {
            enumerable: true,
            configurable: true,
            writable: true,
            value: void 0
        });
        Object.defineProperty(this, "initialized", {
            enumerable: true,
            configurable: true,
            writable: true,
            value: false
        });
        Object.defineProperty(this, "defaultLanguage", {
            enumerable: true,
            configurable: true,
            writable: true,
            value: 'latin'
        });
        Object.defineProperty(this, "wasmPath", {
            enumerable: true,
            configurable: true,
            writable: true,
            value: void 0
        });
        Object.defineProperty(this, "debug", {
            enumerable: true,
            configurable: true,
            writable: true,
            value: void 0
        });
        this.wasmPath = wasmPath;
        this.debug = debug;
    }
    log(...args) {
        if (this.debug)
            console.log('[Morpheus]', ...args);
    }
    /**
     * Initialize the WASM module
     */
    async initialize() {
        if (this.initialized)
            return;
        try {
            this.log('Starting initialization... wasmPath:', this.wasmPath);
            await this.loadScript(this.wasmPath);
            const Module = window.Morpheus;
            if (!Module) {
                throw new Error('Morpheus not found on window');
            }
            const wasmDir = this.wasmPath.substring(0, this.wasmPath.lastIndexOf('/') + 1);
            Module['locateFile'] = (path, prefix) => {
                if (path.endsWith('.data') || path.endsWith('.wasm')) {
                    // Prefer the host page's prefetched blob, else we re-download the file.
                    return resolveAssetUrl(path, wasmDir + path);
                }
                return prefix + path;
            };
            this.wasmModule = await Module({ locateFile: Module['locateFile'] });
            this.log('Module instantiated');
            if (!this.wasmModule.ccall) {
                throw new Error('WASM module does not have ccall method');
            }
            this.wasmModule.ccall('morpheus_init', null, [], []);
            this.initialized = true;
            this.setLanguage(this.defaultLanguage);
            this.log('Initialization complete');
        }
        catch (error) {
            console.error('[Morpheus] Initialization failed:', error);
            throw new Error(`Failed to initialize Morpheus WASM: ${error}`);
        }
    }
    /**
     * Analyze a single word
     * Tries multiple case variations to find the word in Morpheus dictionary
     */
    analyze(word, options = {}) {
        if (!this.initialized) {
            throw new Error('Morpheus not initialized. Call initialize() first.');
        }
        const flags = this.optionsToFlags(options);
        const variations = [
            word,
            word.charAt(0).toUpperCase() + word.slice(1),
            word.toLowerCase(),
            word.toUpperCase()
        ];
        const uniqueVariations = [...new Set(variations)];
        for (const variant of uniqueVariations) {
            this.log('analyze("%s") flags=%s', variant, `0x${flags.toString(16)}`);
            const bufferSize = 65536;
            const bufferPtr = this.wasmModule._malloc(bufferSize);
            try {
                const numAnalyses = this.wasmModule.ccall('morpheus_analyze', 'number', ['string', 'number', 'number', 'number'], [variant, bufferPtr, bufferSize, flags]);
                const output = this.wasmModule.UTF8ToString(bufferPtr);
                if (numAnalyses > 0 && output.length > 0) {
                    this.log('SUCCESS with variant "%s"', variant);
                    return this.parseOutput(word, output, numAnalyses);
                }
            }
            finally {
                this.wasmModule._free(bufferPtr);
            }
        }
        return {
            word,
            analyses: [],
            success: false,
            raw: ''
        };
    }
    /**
     * Analyze multiple words in batch
     */
    analyzeBatch(words, options = {}) {
        if (!this.initialized) {
            throw new Error('Morpheus not initialized. Call initialize() first.');
        }
        return words.map(word => this.analyze(word, options));
    }
    /**
     * Set analysis language
     */
    setLanguage(lang) {
        if (!this.initialized) {
            throw new Error('Morpheus not initialized. Call initialize() first.');
        }
        let langCode;
        switch (lang) {
            case 'greek':
                langCode = GREEK;
                break;
            case 'latin':
                langCode = LATIN;
                break;
            case 'italian':
                langCode = ITALIAN;
                break;
            default: langCode = LATIN;
        }
        this.wasmModule.ccall('morpheus_set_language', null, ['number'], [langCode]);
        this.defaultLanguage = lang;
    }
    /**
     * Destroy the analyzer and free resources
     */
    destroy() {
        if (this.wasmModule) {
            this.wasmModule.ccall('morpheus_destroy', null, [], []);
            this.wasmModule = null;
            this.initialized = false;
        }
    }
    isInitialized() {
        return this.initialized;
    }
    // -------------------------------------------------------------------------
    // Private helpers
    // -------------------------------------------------------------------------
    loadScript(url) {
        return new Promise((resolve, reject) => {
            const script = document.createElement('script');
            script.src = url;
            script.async = true;
            script.onload = () => resolve();
            script.onerror = () => reject(new Error(`Failed to load script: ${url}`));
            document.head.appendChild(script);
        });
    }
    optionsToFlags(options) {
        let flags = PERSEUS_FORMAT;
        if (options.format === 'lemma')
            flags |= SHOW_LEMMA;
        if (options.ignoreAccents)
            flags |= IGNORE_ACCENTS;
        if (!options.strictCase)
            flags &= ~STRICT_CASE;
        if (options.checkPreverb)
            flags |= CHECK_PREVERB;
        if (options.verbsOnly)
            flags |= VERBS_ONLY;
        flags |= LATIN;
        return flags;
    }
    parseOutput(word, raw, numAnalyses) {
        const analyses = [];
        const regex = /<NL>([^<]*)<\/NL>/g;
        let match;
        while ((match = regex.exec(raw)) !== null) {
            const line = match[1].trim();
            if (line) {
                const analysis = this.parseAnalysisLine(line);
                if (analysis) {
                    analyses.push(analysis);
                }
            }
        }
        return {
            word,
            analyses,
            success: analyses.length > 0,
            raw
        };
    }
    parseAnalysisLine(line) {
        const parts = line.trim().split(/\s+/);
        if (parts.length < 2)
            return null;
        const posCode = parts[0];
        const accented = parts[1];
        const stem = accented;
        const ending = parts[parts.length - 1];
        const formInfo = this.parseFormInfo(posCode, parts.slice(2, -1));
        let lemma = stem;
        if (accented.includes(',')) {
            const commaParts = accented.split(',');
            lemma = commaParts[1];
        }
        return {
            lemma,
            stem,
            ending,
            accented,
            formInfo,
            raw: line
        };
    }
    parseFormInfo(posCode, features) {
        const info = {
            partOfSpeech: this.posCodeToName(posCode)
        };
        for (const f of features) {
            const lower = f.toLowerCase();
            if (!lower)
                continue;
            if (lower.includes('nom'))
                info.case = 'nominative';
            else if (lower.includes('gen'))
                info.case = 'genitive';
            else if (lower.includes('dat'))
                info.case = 'dative';
            else if (lower.includes('acc'))
                info.case = 'accusative';
            else if (lower.includes('abl'))
                info.case = 'ablative';
            else if (lower.includes('voc'))
                info.case = 'vocative';
            else if (lower.includes('loc'))
                info.case = 'locative';
            if (lower.includes('sg'))
                info.number = 'singular';
            else if (lower.includes('pl'))
                info.number = 'plural';
            else if (lower.includes('du'))
                info.number = 'dual';
            if (lower.includes('masc'))
                info.gender = 'masculine';
            else if (lower.includes('fem'))
                info.gender = 'feminine';
            else if (lower.includes('neut'))
                info.gender = 'neuter';
            if (lower.includes('pres'))
                info.tense = 'present';
            else if (lower.includes('impf'))
                info.tense = 'imperfect';
            else if (lower.includes('fut'))
                info.tense = 'future';
            else if (lower.includes('perf'))
                info.tense = 'perfect';
            else if (lower.includes('plup'))
                info.tense = 'pluperfect';
            if (lower.includes('ind'))
                info.mood = 'indicative';
            else if (lower.includes('sub'))
                info.mood = 'subjunctive';
            else if (lower.includes('imp'))
                info.mood = 'imperative';
            else if (lower.includes('inf'))
                info.mood = 'infinitive';
            else if (lower.includes('part'))
                info.mood = 'participle';
            if (lower.includes('act'))
                info.voice = 'active';
            else if (lower.includes('pass'))
                info.voice = 'passive';
            else if (lower.includes('mid'))
                info.voice = 'middle';
            if (lower.includes('1'))
                info.person = '1st';
            else if (lower.includes('2'))
                info.person = '2nd';
            else if (lower.includes('3'))
                info.person = '3rd';
            if (lower.includes('pos'))
                info.degree = 'positive';
            else if (lower.includes('comp'))
                info.degree = 'comparative';
            else if (lower.includes('sup'))
                info.degree = 'superlative';
        }
        return info;
    }
    posCodeToName(code) {
        const map = {
            'N': 'noun',
            'V': 'verb',
            'A': 'adjective',
            'P': 'pronoun',
            'ADV': 'adverb',
            'PREP': 'preposition',
            'CONJ': 'conjunction',
            'INTERJ': 'interjection',
            'NUM': 'numeral',
            'PART': 'particle',
            'X': 'unknown'
        };
        return map[code] || code.toLowerCase();
    }
}
export default MorpheusAnalyzer;
//# sourceMappingURL=MorpheusAnalyzer.js.map