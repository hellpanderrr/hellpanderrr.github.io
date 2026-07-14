/**
 * WordlistEngine.ts
 * IndexedDB-based wordlist for accurate Latin macronization
 * Stores exact wordform + tag → macronized form mappings from macrons.txt
 * Integrates with Morpheus for unknown words
 */
import { unicodeToUnderscore, toAscii } from '../utils/latin.js';
import { fetchMaybeGzipped } from '../utils/assets.js';
export class WordlistEngine {
    constructor() {
        Object.defineProperty(this, "db", {
            enumerable: true,
            configurable: true,
            writable: true,
            value: null
        });
        Object.defineProperty(this, "loaded", {
            enumerable: true,
            configurable: true,
            writable: true,
            value: false
        });
        Object.defineProperty(this, "entryCount", {
            enumerable: true,
            configurable: true,
            writable: true,
            value: 0
        });
        Object.defineProperty(this, "morpheusAnalyzer", {
            enumerable: true,
            configurable: true,
            writable: true,
            value: null
        });
        Object.defineProperty(this, "loadingPromise", {
            enumerable: true,
            configurable: true,
            writable: true,
            value: null
        });
        Object.defineProperty(this, "nextSeq", {
            enumerable: true,
            configurable: true,
            writable: true,
            value: 0
        });
        Object.defineProperty(this, "DB_NAME", {
            enumerable: true,
            configurable: true,
            writable: true,
            value: 'MacronizerDB_v3'
        });
        Object.defineProperty(this, "DB_VERSION", {
            enumerable: true,
            configurable: true,
            writable: true,
            value: 1
        });
        Object.defineProperty(this, "STORE_NAME", {
            enumerable: true,
            configurable: true,
            writable: true,
            value: 'wordlist'
        });
        /** Cache of Morpheus analyses by normalized wordform (for UI display) */
        Object.defineProperty(this, "morpheusCache", {
            enumerable: true,
            configurable: true,
            writable: true,
            value: new Map()
        });
        /** In-memory cache for getAllEntries — eliminates redundant IndexedDB cursor
         * calls across the 3+ passes (ensureAnalyzed, addLemmas, getAccents) that
         * each look up every wordform. Keyed by lowered wordform. */
        Object.defineProperty(this, "entriesCache", {
            enumerable: true,
            configurable: true,
            writable: true,
            value: new Map()
        });
    }
    /**
     * Initialize IndexedDB database
     */
    async init() {
        return new Promise((resolve, reject) => {
            const request = indexedDB.open(this.DB_NAME, this.DB_VERSION);
            request.onerror = () => reject(request.error);
            request.onsuccess = () => {
                this.db = request.result;
                resolve();
            };
            request.onupgradeneeded = (event) => {
                const db = event.target.result;
                if (!db.objectStoreNames.contains(this.STORE_NAME)) {
                    // Primary key = file-order sequence number. This preserves the exact
                    // macrons.txt row order (Python iterates rows in file order) and keeps
                    // duplicate (wordform, tag, lemma) rows that a composite key would drop.
                    const store = db.createObjectStore(this.STORE_NAME, {
                        keyPath: 'seq'
                    });
                    // Cursor over this index yields (wordform, seq) order = file order per wordform
                    store.createIndex('wordform', 'wordform', { unique: false });
                }
            };
        });
    }
    /**
     * Check if database is populated
     */
    async isPopulated() {
        if (!this.db)
            await this.init();
        return new Promise((resolve, reject) => {
            const transaction = this.db.transaction([this.STORE_NAME], 'readonly');
            const store = transaction.objectStore(this.STORE_NAME);
            const countRequest = store.count();
            countRequest.onsuccess = () => {
                this.entryCount = countRequest.result;
                // Seed the sequence counter past existing rows (rows are numbered 0..n-1
                // at load; later Morpheus additions append from here)
                if (this.entryCount > this.nextSeq)
                    this.nextSeq = this.entryCount;
                resolve(this.entryCount > 0);
            };
            countRequest.onerror = () => reject(countRequest.error);
        });
    }
    /**
     * Get entry count
     */
    size() {
        return this.entryCount;
    }
    /** Clear the in-memory getAllEntries cache. Call between large documents
     * to prevent unbounded memory growth — the cache repopulates on demand. */
    clearEntriesCache() {
        this.entriesCache.clear();
    }
    /**
     * Lookup exact macronized form for word + tag
     */
    async lookup(wordform, tag) {
        // Get all entries for this wordform and find best tag match
        const entries = await this.getAllEntries(wordform);
        if (entries.length === 0)
            return null;
        // Normalize the target tag for comparison
        const normalizedTargetTag = this.normalizeTag(tag.trim());
        // Prefer entry with exact tag match
        for (const entry of entries) {
            if (entry.tag === normalizedTargetTag) {
                return entry.macronized;
            }
        }
        // Fallback: return first entry's macronized form
        return entries[0].macronized;
    }
    /**
     * Get all entries for a wordform (for candidate generation)
     * Returns entries with accentedUnderscore populated
     */
    async getAllEntries(wordform) {
        if (!this.db)
            await this.init();
        const normalizedWord = wordform.toLowerCase().trim();
        // Cache hit — avoids redundant IndexedDB trips across the 3+ passes
        const cached = this.entriesCache.get(normalizedWord);
        if (cached !== undefined)
            return cached;
        return new Promise((resolve, reject) => {
            const transaction = this.db.transaction([this.STORE_NAME], 'readonly');
            const store = transaction.objectStore(this.STORE_NAME);
            const index = store.index('wordform');
            const range = IDBKeyRange.only(normalizedWord);
            // Use getAll() instead of openCursor — returns all matching rows as a
            // single array, avoiding per-row event-loop overhead (2-5x faster).
            const request = index.getAll(range);
            request.onsuccess = () => {
                var _a;
                const all = ((_a = request.result) !== null && _a !== void 0 ? _a : []);
                // Only include entries that have accentedUnderscore (i.e., from file)
                const entries = all.filter(e => e.accentedUnderscore);
                // Populate cache for subsequent calls from any pipeline stage
                this.entriesCache.set(normalizedWord, entries);
                resolve(entries);
            };
            request.onerror = () => reject(request.error);
        });
    }
    /**
     * Normalize tag format (convert dots to dashes for consistency with RFTagger)
     */
    normalizeTag(tag) {
        if (!tag)
            return '---------';
        // Convert dots to dashes (RFTagger: n.-.s.-.-.-.f.b.- → n--s-----f-b-)
        return tag.replace(/\./g, '-');
    }
    /**
     * Add single entry to wordlist
     */
    async addEntry(entry) {
        if (!this.db)
            await this.init();
        return new Promise((resolve, reject) => {
            var _a;
            const transaction = this.db.transaction([this.STORE_NAME], 'readwrite');
            const store = transaction.objectStore(this.STORE_NAME);
            const request = store.put({
                seq: (_a = entry.seq) !== null && _a !== void 0 ? _a : this.nextSeq++,
                wordform: entry.wordform.toLowerCase().trim(),
                tag: this.normalizeTag(entry.tag.trim()),
                macronized: entry.macronized,
                accentedUnderscore: entry.accentedUnderscore,
                lemma: entry.lemma.trim()
            });
            request.onsuccess = () => {
                this.entryCount++;
                resolve();
            };
            request.onerror = () => reject(request.error);
        });
    }
    /**
     * Batch add entries (for file loading)
     */
    async addEntries(entries, onProgress) {
        if (!this.db)
            await this.init();
        const BATCH_SIZE = 50000;
        let processed = 0;
        console.log('WordlistEngine: starting addEntries, total entries:', entries.length);
        for (let i = 0; i < entries.length; i += BATCH_SIZE) {
            const batch = entries.slice(i, i + BATCH_SIZE);
            await new Promise((resolve, reject) => {
                const transaction = this.db.transaction([this.STORE_NAME], 'readwrite');
                const store = transaction.objectStore(this.STORE_NAME);
                batch.forEach(entry => {
                    var _a;
                    store.put({
                        seq: (_a = entry.seq) !== null && _a !== void 0 ? _a : this.nextSeq++,
                        wordform: entry.wordform.toLowerCase().trim(),
                        tag: this.normalizeTag(entry.tag.trim()),
                        macronized: entry.macronized,
                        accentedUnderscore: entry.accentedUnderscore,
                        lemma: entry.lemma.trim()
                    });
                });
                transaction.oncomplete = () => {
                    processed += batch.length;
                    if (onProgress)
                        onProgress(processed);
                    resolve();
                };
                transaction.onerror = () => reject(transaction.error);
            });
        }
        this.entryCount = processed;
        console.log('WordlistEngine: finished addEntries, total processed:', processed);
    }
    /**
     * Clear all entries
     */
    async clear() {
        if (!this.db)
            await this.init();
        return new Promise((resolve, reject) => {
            const transaction = this.db.transaction([this.STORE_NAME], 'readwrite');
            const store = transaction.objectStore(this.STORE_NAME);
            const request = store.clear();
            request.onsuccess = () => {
                this.entryCount = 0;
                this.nextSeq = 0;
                this.loaded = false;
                resolve();
            };
            request.onerror = () => reject(request.error);
        });
    }
    /**
     * Convert macron marks to Unicode
     * ^ = breve (short vowel), _ = macron (long vowel)
     * a^ -> ă, a_ -> ā
     */
    convertMacronMarks(text) {
        return text
            .replace(/\^a/g, 'ă')
            .replace(/\^e/g, 'ĕ')
            .replace(/\^i/g, 'ĭ')
            .replace(/\^o/g, 'ŏ')
            .replace(/\^u/g, 'ŭ')
            .replace(/\^A/g, 'Ă')
            .replace(/\^E/g, 'Ĕ')
            .replace(/\^I/g, 'Ĭ')
            .replace(/\^O/g, 'Ŏ')
            .replace(/\^U/g, 'Ŭ')
            .replace(/a_/g, 'ā')
            .replace(/e_/g, 'ē')
            .replace(/i_/g, 'ī')
            .replace(/o_/g, 'ō')
            .replace(/u_/g, 'ū')
            .replace(/A_/g, 'Ā')
            .replace(/E_/g, 'Ē')
            .replace(/I_/g, 'Ī')
            .replace(/O_/g, 'Ō')
            .replace(/U_/g, 'Ū');
    }
    /**
     * Clean lemma string: remove #, 1, spaces→+, -, ^, _
     * Matches Python wordlist.clean_lemma()
     */
    cleanLemma(lemma) {
        return lemma
            .replace(/#/g, '')
            .replace(/1/g, '')
            .replace(/ /g, '+')
            .replace(/-/g, '')
            .replace(/\^/g, '')
            .replace(/_/g, '');
    }
    /**
     * Load from parsed macrons.txt data
     * Expected format: whitespace-separated (tab or space) columns:
     *   wordform  tag  lemma  accented
     * e.g. "a\te--------\ta\ta_"
     */
    async loadFromText(text, onProgress) {
        // Guard against concurrent loads
        if (this.loadingPromise) {
            await this.loadingPromise;
            return;
        }
        this.loadingPromise = (async () => {
            const entries = [];
            const lines = text.split('\n');
            console.log('WordlistEngine: total lines in file:', lines.length);
            let parsedCount = 0;
            for (const line of lines) {
                const trimmed = line.trim();
                if (!trimmed || trimmed.startsWith('#'))
                    continue;
                // Split on any whitespace (tabs/spaces) — matches Python's line.split()
                const parts = trimmed.split(/\s+/);
                if (parts.length >= 4) {
                    const wordform = parts[0];
                    const tag = parts[1];
                    const lemma = parts[2];
                    const rawMacronized = parts[3]; // underscore/caret notation
                    const macronizedUnicode = this.convertMacronMarks(rawMacronized);
                    entries.push({
                        wordform,
                        tag,
                        lemma,
                        accentedUnderscore: rawMacronized,
                        macronized: macronizedUnicode
                    });
                    parsedCount++;
                }
            }
            console.log('WordlistEngine: parsed entries count:', parsedCount);
            await this.addEntries(entries, onProgress);
            this.loaded = true;
        })();
        await this.loadingPromise;
        this.loadingPromise = null;
    }
    /**
     * Load wordlist from URL (fetch + parse)
     */
    /**
     * Load wordlist from URL. A `.gz` URL is decompressed in the browser
     * (32MB of text ships as ~4MB); it falls back to the uncompressed file
     * if the .gz is missing or the browser cannot gunzip.
     */
    async loadFromUrl(url, onProgress) {
        const fallbackUrl = url.endsWith('.gz') ? url.slice(0, -3) : undefined;
        const bytes = await fetchMaybeGzipped(url, fallbackUrl);
        const text = new TextDecoder('utf-8').decode(bytes);
        await this.loadFromText(text, onProgress);
    }
    /**
     * Check if loaded
     */
    isLoaded() {
        return this.loaded;
    }
    /**
     * Close database connection
     */
    close() {
        if (this.db) {
            this.db.close();
            this.db = null;
        }
    }
    /**
     * Set Morpheus analyzer for unknown words
     */
    setMorpheusAnalyzer(analyzer) {
        this.morpheusAnalyzer = analyzer;
    }
    /**
     * Get cached Morpheus analysis for a wordform (if available)
     */
    getMorpheusAnalysis(wordform) {
        return this.morpheusCache.get(wordform.toLowerCase().trim());
    }
    /**
     * Check if a word has Morpheus analysis cached
     */
    hasMorpheusAnalysis(wordform) {
        return this.morpheusCache.has(wordform.toLowerCase().trim());
    }
    /**
     * Analyze unknown words using Morpheus and cache results
     * Ported from latin_macronizer/wordlist.py::crunchwords()
     * Produces multiple entries per word (different lemma+tag combinations)
     */
    async analyzeUnknownWords(words) {
        if (!this.morpheusAnalyzer || !this.morpheusAnalyzer.isInitialized()) {
            throw new Error('Morpheus analyzer not set or not initialized');
        }
        const results = [];
        const unknownWords = [];
        // Filter words not in wordlist (no entries with accentedUnderscore)
        for (const word of words) {
            const normalized = word.toLowerCase().trim();
            const entries = await this.getAllEntries(normalized);
            if (entries.length === 0) {
                unknownWords.push(word);
            }
        }
        if (unknownWords.length === 0) {
            return results;
        }
        // Analyze with Morpheus (batch)
        const analyses = this.morpheusAnalyzer.analyzeBatch(unknownWords);
        for (const analysis of analyses) {
            if (!analysis.success || analysis.analyses.length === 0) {
                continue;
            }
            // Cache the full Morpheus analysis for UI popup display
            this.morpheusCache.set(analysis.word.toLowerCase().trim(), analysis);
            // Group by (lemma, tag) to collect all accented forms for that parse
            const lemmaTagToAccented = new Map();
            for (const parse of analysis.analyses) {
                const lemma = this.cleanLemma(parse.lemma);
                const ldtTag = this.analysisToLdtTag(parse);
                const accentedRaw = parse.accented; // Use extracted accented field (underscore notation)
                // Special case: trans verbs need _ after prefix (Python wordlist.py line 147-148)
                let accentedAdjusted = accentedRaw;
                if (lemma.startsWith('trans') && accentedRaw.length > 3 && accentedRaw[3] !== '_') {
                    accentedAdjusted = accentedRaw.slice(0, 3) + '_' + accentedRaw.slice(3);
                }
                const key = `${lemma}|${ldtTag}`;
                const existing = lemmaTagToAccented.get(key) || [];
                existing.push(accentedAdjusted);
                lemmaTagToAccented.set(key, existing);
            }
            // For each (lemma, tag) group, select best accented form
            for (const [key, accenteds] of lemmaTagToAccented.entries()) {
                const [lemma, ldtTag] = key.split('|');
                // Python preference: forms with more 'v', 'j', 'J' (prefers volvit over voluit, Julius over Iulius)
                const bestAccented = accenteds.sort((a, b) => {
                    const scoreA = (a.match(/[vjJ]/g) || []).length;
                    const scoreB = (b.match(/[vjJ]/g) || []).length;
                    return scoreA - scoreB; // ascending, so highest score comes last
                }).pop(); // take highest
                const accentedUnderscore = unicodeToUnderscore(bestAccented);
                const entry = {
                    wordform: analysis.word.toLowerCase(),
                    tag: ldtTag,
                    lemma,
                    macronized: this.convertMacronMarks(bestAccented),
                    accentedUnderscore
                };
                results.push(entry);
                await this.addEntry(entry); // Cache in DB
            }
        }
        return results;
    }
    /**
     * Ensure all given wordforms have entries in the wordlist.
     * For missing words, analyzes with Morpheus and caches results.
     * Matches Python Wordlist.loadwords() behavior.
     */
    async ensureAnalyzed(wordForms) {
        // Deduplicate and normalize
        const uniqueForms = Array.from(new Set(wordForms.map(w => toAscii(w).toLowerCase().trim())));
        // Check which are missing (no entries with accentedUnderscore)
        const missing = [];
        for (const word of uniqueForms) {
            const entries = await this.getAllEntries(word);
            if (entries.length === 0) {
                missing.push(word);
            }
        }
        if (missing.length === 0) {
            return;
        }
        // Analyze missing words with Morpheus (batch)
        await this.analyzeUnknownWords(missing);
    }
    /**
     * Convert a Morpheus analysis to an LDT 9-char tag
     * Ported from latin_macronizer/postags.py (parse_to_ldt)
     */
    analysisToLdtTag(analysis) {
        var _a, _b, _c, _d, _e, _f, _g, _h, _j;
        const f = analysis.formInfo;
        let tag = '';
        // POS (position 0)
        const pos = ((_a = f.partOfSpeech) === null || _a === void 0 ? void 0 : _a.toLowerCase()) || '';
        if (pos.includes('noun'))
            tag += 'n';
        else if (pos.includes('verb'))
            tag += 'v';
        else if (pos.includes('adj'))
            tag += 'a';
        else if (pos.includes('adv') || pos.includes('adverbial'))
            tag += 'd';
        else if (pos.includes('conj'))
            tag += 'c';
        else if (pos.includes('prep'))
            tag += 'r';
        else if (pos.includes('pron'))
            tag += 'p';
        else if (pos.includes('num'))
            tag += 'm';
        else if (pos.includes('interj'))
            tag += 'i';
        else if (pos.includes('excl'))
            tag += 'e';
        else if (pos.includes('punc'))
            tag += 'u';
        else
            tag += '-';
        // Person (position 1)
        const person = ((_b = f.person) === null || _b === void 0 ? void 0 : _b.toLowerCase()) || '';
        if (person.includes('1'))
            tag += '1';
        else if (person.includes('2'))
            tag += '2';
        else if (person.includes('3'))
            tag += '3';
        else
            tag += '-';
        // Number (position 2)
        const number = ((_c = f.number) === null || _c === void 0 ? void 0 : _c.toLowerCase()) || '';
        if (number.includes('sing'))
            tag += 's';
        else if (number.includes('plur'))
            tag += 'p';
        else
            tag += '-';
        // Tense (position 3)
        const tense = ((_d = f.tense) === null || _d === void 0 ? void 0 : _d.toLowerCase()) || '';
        if (tense.includes('pres'))
            tag += 'p';
        else if (tense.includes('impf'))
            tag += 'i';
        else if (tense.includes('perf'))
            tag += 'r';
        else if (tense.includes('plup'))
            tag += 'l';
        else if (tense.includes('futperf'))
            tag += 't';
        else if (tense.includes('fut'))
            tag += 'f';
        else
            tag += '-';
        // Mood (position 4)
        const mood = ((_e = f.mood) === null || _e === void 0 ? void 0 : _e.toLowerCase()) || '';
        if (mood.includes('ind'))
            tag += 'i';
        else if (mood.includes('subj'))
            tag += 's';
        else if (mood.includes('inf'))
            tag += 'n';
        else if (mood.includes('imperat'))
            tag += 'm';
        else if (mood.includes('part'))
            tag += 'p';
        else if (mood.includes('gerund'))
            tag += 'd';
        else if (mood.includes('gerundive'))
            tag += 'g';
        else if (mood.includes('supine'))
            tag += 'u';
        else
            tag += '-';
        // Voice (position 5)
        const voice = ((_f = f.voice) === null || _f === void 0 ? void 0 : _f.toLowerCase()) || '';
        if (voice.includes('act'))
            tag += 'a';
        else if (voice.includes('pass'))
            tag += 'p';
        else
            tag += '-';
        // Gender (position 6)
        const gender = ((_g = f.gender) === null || _g === void 0 ? void 0 : _g.toLowerCase()) || '';
        if (gender.includes('masc'))
            tag += 'm';
        else if (gender.includes('fem'))
            tag += 'f';
        else if (gender.includes('neut'))
            tag += 'n';
        else
            tag += '-';
        // Case (position 7)
        const case_ = ((_h = f.case) === null || _h === void 0 ? void 0 : _h.toLowerCase()) || '';
        if (case_.includes('nom'))
            tag += 'n';
        else if (case_.includes('gen'))
            tag += 'g';
        else if (case_.includes('dat'))
            tag += 'd';
        else if (case_.includes('acc'))
            tag += 'a';
        else if (case_.includes('abl'))
            tag += 'b';
        else if (case_.includes('voc'))
            tag += 'v';
        else if (case_.includes('loc'))
            tag += 'l';
        else
            tag += '-';
        // Degree (position 8)
        const degree = ((_j = f.degree) === null || _j === void 0 ? void 0 : _j.toLowerCase()) || '';
        if (degree.includes('comp'))
            tag += 'c';
        else if (degree.includes('superl'))
            tag += 's';
        else
            tag += '-';
        return tag;
    }
}
//# sourceMappingURL=WordlistEngine.js.map