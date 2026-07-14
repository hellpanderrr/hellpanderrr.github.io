/**
 * Token.ts
 * Core token representation for Latin macronizer
 * Immutable token with POS tagging and macronization capabilities
 */
/**
 * Immutable token class representing a word in Latin text
 */
export class Token {
    constructor(text, options = {}) {
        var _a;
        Object.defineProperty(this, "text", {
            enumerable: true,
            configurable: true,
            writable: true,
            value: void 0
        });
        Object.defineProperty(this, "tag", {
            enumerable: true,
            configurable: true,
            writable: true,
            value: void 0
        });
        Object.defineProperty(this, "lemma", {
            enumerable: true,
            configurable: true,
            writable: true,
            value: void 0
        });
        Object.defineProperty(this, "macronized", {
            enumerable: true,
            configurable: true,
            writable: true,
            value: void 0
        });
        Object.defineProperty(this, "macronizedText", {
            enumerable: true,
            configurable: true,
            writable: true,
            value: void 0
        }); // Macronized form
        Object.defineProperty(this, "originalText", {
            enumerable: true,
            configurable: true,
            writable: true,
            value: void 0
        }); // Original text before normalization
        Object.defineProperty(this, "accented", {
            enumerable: true,
            configurable: true,
            writable: true,
            value: void 0
        }); // Candidate accented forms (with _ markers)
        Object.defineProperty(this, "accentedSources", {
            enumerable: true,
            configurable: true,
            writable: true,
            value: void 0
        }); // lemma/tag behind each accented form (informational)
        Object.defineProperty(this, "isAmbiguous", {
            enumerable: true,
            configurable: true,
            writable: true,
            value: void 0
        });
        Object.defineProperty(this, "isUnknown", {
            enumerable: true,
            configurable: true,
            writable: true,
            value: void 0
        });
        Object.defineProperty(this, "morpheusAnalyzed", {
            enumerable: true,
            configurable: true,
            writable: true,
            value: void 0
        });
        Object.defineProperty(this, "morpheusResults", {
            enumerable: true,
            configurable: true,
            writable: true,
            value: void 0
        }); // Full Morpheus analysis
        Object.defineProperty(this, "startssentence", {
            enumerable: true,
            configurable: true,
            writable: true,
            value: void 0
        });
        Object.defineProperty(this, "endssentence", {
            enumerable: true,
            configurable: true,
            writable: true,
            value: void 0
        });
        Object.defineProperty(this, "hasenclitic", {
            enumerable: true,
            configurable: true,
            writable: true,
            value: void 0
        });
        Object.defineProperty(this, "isenclitic", {
            enumerable: true,
            configurable: true,
            writable: true,
            value: void 0
        });
        Object.defineProperty(this, "isWord", {
            enumerable: true,
            configurable: true,
            writable: true,
            value: void 0
        });
        Object.defineProperty(this, "isSpace", {
            enumerable: true,
            configurable: true,
            writable: true,
            value: void 0
        });
        Object.defineProperty(this, "startIndex", {
            enumerable: true,
            configurable: true,
            writable: true,
            value: void 0
        });
        Object.defineProperty(this, "endIndex", {
            enumerable: true,
            configurable: true,
            writable: true,
            value: void 0
        });
        this.text = options.text || text;
        this.tag = options.tag || '---------';
        this.lemma = options.lemma || text.toLowerCase();
        this.macronized = options.macronized || false;
        this.macronizedText = options.macronizedText;
        this.originalText = options.originalText || text;
        this.accented = options.accented;
        this.accentedSources = options.accentedSources;
        this.isAmbiguous = options.isAmbiguous || false;
        this.isUnknown = options.isUnknown || false;
        this.morpheusAnalyzed = options.morpheusAnalyzed;
        this.morpheusResults = (_a = options.morpheusResults) !== null && _a !== void 0 ? _a : null;
        this.startssentence = options.startssentence;
        this.endssentence = options.endssentence;
        this.hasenclitic = options.hasenclitic;
        this.isenclitic = options.isenclitic;
        this.isWord = options.isWord;
        this.isSpace = options.isSpace;
        this.startIndex = options.startIndex;
        this.endIndex = options.endIndex;
        Object.freeze(this);
    }
    /**
     * Create a new token with updated properties (immutable update)
     */
    with(options) {
        var _a, _b, _c, _d, _e, _f, _g, _h, _j, _k, _l, _m, _o, _p, _q, _r, _s, _t, _u;
        return new Token(this.text, {
            text: (_a = options.text) !== null && _a !== void 0 ? _a : this.text,
            tag: (_b = options.tag) !== null && _b !== void 0 ? _b : this.tag,
            lemma: (_c = options.lemma) !== null && _c !== void 0 ? _c : this.lemma,
            macronized: (_d = options.macronized) !== null && _d !== void 0 ? _d : this.macronized,
            macronizedText: (_e = options.macronizedText) !== null && _e !== void 0 ? _e : this.macronizedText,
            originalText: (_f = options.originalText) !== null && _f !== void 0 ? _f : this.originalText,
            accented: (_g = options.accented) !== null && _g !== void 0 ? _g : this.accented,
            accentedSources: options.accentedSources !== undefined ? options.accentedSources : this.accentedSources,
            isAmbiguous: (_h = options.isAmbiguous) !== null && _h !== void 0 ? _h : this.isAmbiguous,
            isUnknown: (_j = options.isUnknown) !== null && _j !== void 0 ? _j : this.isUnknown,
            morpheusAnalyzed: (_k = options.morpheusAnalyzed) !== null && _k !== void 0 ? _k : this.morpheusAnalyzed,
            morpheusResults: (_l = options.morpheusResults) !== null && _l !== void 0 ? _l : this.morpheusResults,
            startssentence: (_m = options.startssentence) !== null && _m !== void 0 ? _m : this.startssentence,
            endssentence: (_o = options.endssentence) !== null && _o !== void 0 ? _o : this.endssentence,
            hasenclitic: (_p = options.hasenclitic) !== null && _p !== void 0 ? _p : this.hasenclitic,
            isenclitic: (_q = options.isenclitic) !== null && _q !== void 0 ? _q : this.isenclitic,
            isWord: (_r = options.isWord) !== null && _r !== void 0 ? _r : this.isWord,
            isSpace: (_s = options.isSpace) !== null && _s !== void 0 ? _s : this.isSpace,
            startIndex: (_t = options.startIndex) !== null && _t !== void 0 ? _t : this.startIndex,
            endIndex: (_u = options.endIndex) !== null && _u !== void 0 ? _u : this.endIndex,
        });
    }
}
//# sourceMappingURL=Token.js.map