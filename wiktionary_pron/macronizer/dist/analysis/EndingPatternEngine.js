/**
 * EndingPatternEngine.ts
 * Pattern-based vowel length determination for Latin macronization
 * Uses suffix patterns and morphological rules
 */
export class EndingPatternEngine {
    constructor() {
        Object.defineProperty(this, "loaded", {
            enumerable: true,
            configurable: true,
            writable: true,
            value: void 0
        });
        /** Raw Python tag_to_endings: exact 9-char LDT tag → ORDERED accented endings
         *  (underscore/caret notation), straight from endings.json. */
        Object.defineProperty(this, "rawEndings", {
            enumerable: true,
            configurable: true,
            writable: true,
            value: void 0
        });
        /** All endings with quantity marks stripped, for O(len) suffix lookup in hasPattern(). */
        Object.defineProperty(this, "plainEndings", {
            enumerable: true,
            configurable: true,
            writable: true,
            value: void 0
        });
        Object.defineProperty(this, "maxEndingLength", {
            enumerable: true,
            configurable: true,
            writable: true,
            value: void 0
        });
        this.loaded = false;
        this.rawEndings = new Map();
        this.plainEndings = new Set();
        this.maxEndingLength = 0;
    }
    /**
     * Python: tag_to_endings.get(tag, []) — exact-tag lookup, list order preserved.
     */
    getEndingsForTag(tag) {
        var _a;
        return (_a = this.rawEndings.get(tag)) !== null && _a !== void 0 ? _a : [];
    }
    /**
     * Load ending patterns
     */
    async load(data) {
        if (this.loaded)
            return;
        // Try to load ending patterns from JSON
        const paths = [
            new URL('../data/endings.json', import.meta.url).href,
            '/data/endings.json',
            '/src/data/endings.json'
        ];
        let found = false;
        for (const path of paths) {
            try {
                const response = await fetch(path);
                if (response.ok) {
                    const json = await response.json();
                    for (const [tag, endings] of Object.entries(json)) {
                        this.rawEndings.set(tag, endings);
                        for (const ending of endings) {
                            const plain = ending.replace(/[_^]/g, '');
                            this.plainEndings.add(plain);
                            if (plain.length > this.maxEndingLength)
                                this.maxEndingLength = plain.length;
                        }
                    }
                    console.log(`[EndingPatternEngine] Loaded ${this.rawEndings.size} tag ending lists from ${path}`);
                    found = true;
                    break;
                }
            }
            catch (e) {
                // Try next path
            }
        }
        if (!found) {
            console.warn('[EndingPatternEngine] Could not load endings JSON from any path');
        }
        this.loaded = true;
    }
    /**
     * Check if a pattern exists for this word
     */
    hasPattern(word) {
        // True if any tag's ending (quantity marks stripped) is a suffix of the word.
        // Checked against a precomputed set: O(longest ending) rather than O(all endings).
        const lower = word.toLowerCase();
        if (this.plainEndings.has(''))
            return true;
        const start = Math.max(0, lower.length - this.maxEndingLength);
        for (let i = start; i < lower.length; i++) {
            if (this.plainEndings.has(lower.slice(i)))
                return true;
        }
        return false;
    }
    /**
     * Get number of tag ending lists
     */
    size() {
        return this.rawEndings.size;
    }
    /**
     * Check if loaded
     */
    isLoaded() {
        return this.loaded;
    }
    /**
     * Normalize RFTagger tag format (n.-.s.-.-.-.f.b.-) to pattern format (n-s--f-)
     */
    normalizeTag(tag) {
        if (!tag)
            return '---------';
        return tag.replace(/\./g, '-').substring(0, 9);
    }
}
//# sourceMappingURL=EndingPatternEngine.js.map