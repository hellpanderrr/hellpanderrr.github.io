import {
  fetchWithCache,
  loadFileFromZipOrPath,
  updateLoadingText,
} from "./utils.js";

const LEXICON_LANGUAGES = {
  German: "german_lexicon_v3.zip",
  Czech: "czech_lexicon.zip",
  French: "french_lexicon_v3.zip",
  Lithuanian: "lt_lexicon.zip",
  Ukrainian: "uk_lexicon_v4.zip",
  Russian: "ru_lexicon_v4.zip",
  Icelandic: "is_lexicon.zip",
};

const LEXICON_FOLDER = "./utils/";

class OptimizedV3Lexicon {
  constructor() {
    this.entries = new Map();
    this.isLoaded = false;
    this.stats = {
      downloadTime: 0,
      parseTime: 0,
      memoryUsage: 0,
      lookupCount: 0,
      avgLookupTime: 0,
    };
  }

  async loadFromBlob(blob, language) {
    const startTime = performance.now();

    try {
      updateLoadingText("", "", "Extracting lexicon");

      // Extract JSON data using existing utility
      const jsonStr = await loadFileFromZipOrPath(blob, "lexicon.json");
      updateLoadingText("", "", "Parsing lexicon data");

      const parseStart = performance.now();
      await this.parseV3Data(jsonStr, language);
      this.stats.parseTime = performance.now() - parseStart;

      this.calculateMemoryUsage();
      this.isLoaded = true;

      console.log(`✅ Optimized V3 lexicon loaded:`);
      console.log(`   📦 Download: ${this.stats.downloadTime.toFixed(0)}ms`);
      console.log(`   ⚡ Parse: ${this.stats.parseTime.toFixed(0)}ms`);
      console.log(
        `   🧠 Memory: ${(this.stats.memoryUsage / 1024 / 1024).toFixed(1)}MB`,
      );
      console.log(`   📊 Entries: ${this.entries.size.toLocaleString()}`);

      return true;
    } catch (error) {
      console.error("❌ Failed to load optimized V3 lexicon:", error);
      updateLoadingText("", "", "Failed to load optimized lexicon");
      return false;
    }
  }

  async parseV3Data(jsonStr, language) {
    const data = JSON.parse(jsonStr);

    if (Array.isArray(data)) {
      // V3 format with prefix compression: [[prefix_len, suffix, ipa], ...]
      const isV4Format = language === "Russian" || language === "Ukrainian";

      if (isV4Format) {
        console.log("📂 Processing V4 prefix/value compression format");
      } else {
        console.log("📂 Processing V3 prefix compression format");
      }

      let currentKey = "";
      const totalEntries = data.length;
      const progressInterval = Math.floor(totalEntries / 50); // Update every 2%
      const STRESS_MARK = "\u0301";

      for (let i = 0; i < data.length; i++) {
        if (isV4Format) {
          // V4 DECODING LOGIC
          const [prefixLen, suffix, valueEncoding] = data[i];
          currentKey = currentKey.substring(0, prefixLen) + suffix;

          let finalValue;
          if (typeof valueEncoding === "number") {
            // It's an integer: the index of the stressed vowel.
            const stressPos = valueEncoding;
            finalValue =
              currentKey.slice(0, stressPos + 1) +
              STRESS_MARK +
              currentKey.slice(stressPos + 1);
          } else {
            // It's a string: an exception (e.g., multi-form). Use it directly.
            finalValue = valueEncoding;
          }
          this.entries.set(currentKey, finalValue);
        } else {
          // V3 DECODING LOGIC (original code)
          const [prefixLen, suffix, ipa] = data[i];
          currentKey = currentKey.substring(0, prefixLen) + suffix;
          this.entries.set(currentKey, ipa);
        }

        // Progress update with yielding for responsiveness
        if (i % progressInterval === 0) {
          const progress = (i / totalEntries) * 100;
          updateLoadingText(
            "",
            "",
            `Parsing entries: ${i.toLocaleString()}/${totalEntries.toLocaleString()} (${progress.toFixed(
              1,
            )}%)`,
          );

          // Yield control every 2nd progress update to prevent blocking
          if (i % (progressInterval * 2) === 0) {
            await new Promise((resolve) => setTimeout(resolve, 0));
          }
        }
      }
    } else {
      // Standard dictionary format
      console.log("📂 Processing standard dictionary format");
      const entries = Object.entries(data);
      const totalEntries = entries.length;
      const progressInterval = Math.floor(totalEntries / 50);

      for (let i = 0; i < entries.length; i++) {
        const [key, value] = entries[i];
        this.entries.set(key, value);

        if (i % progressInterval === 0) {
          const progress = (i / totalEntries) * 100;
          updateLoadingText(
            "",
            "",
            `Parsing entries: ${i.toLocaleString()}/${totalEntries.toLocaleString()} (${progress.toFixed(
              1,
            )}%)`,
          );

          if (i % (progressInterval * 4) === 0) {
            await new Promise((resolve) => setTimeout(resolve, 0));
          }
        }
      }
    }

    console.log(`✅ Parsed ${this.entries.size.toLocaleString()} entries`);
  }

  get(word) {
    const startTime = performance.now();
    const result = this.entries.get(word) || null;

    this.stats.lookupCount++;
    const lookupTime = performance.now() - startTime;
    this.stats.avgLookupTime =
      (this.stats.avgLookupTime * (this.stats.lookupCount - 1) + lookupTime) /
      this.stats.lookupCount;

    return result;
  }

  has(word) {
    return this.entries.has(word);
  }

  size() {
    return this.entries.size;
  }

  calculateMemoryUsage() {
    let memory = 0;

    // Entries Map
    for (const [key, value] of this.entries) {
      memory += key.length * 2 + value.length * 2; // UTF-16
    }

    this.stats.memoryUsage = memory;
  }

  getMemoryUsage() {
    return this.stats.memoryUsage / (1024 * 1024); // MB
  }

  getPerformanceStats() {
    return {
      downloadTime: this.stats.downloadTime,
      parseTime: this.stats.parseTime,
      memoryUsageMB: this.getMemoryUsage(),
      entryCount: this.entries.size,
      lookupCount: this.stats.lookupCount,
      avgLookupTime: this.stats.avgLookupTime,
      efficiency: {
        downloadSpeed: this.stats.downloadTime < 2000 ? "Excellent" : "Good",
        parseSpeed:
          this.stats.parseTime < 500
            ? "Excellent"
            : this.stats.parseTime < 1000
            ? "Good"
            : "Fair",
        memoryEfficiency: this.getMemoryUsage() < 40 ? "Excellent" : "Good",
        lookupSpeed: this.stats.avgLookupTime < 0.1 ? "Excellent" : "Good",
      },
    };
  }
}

// ===========================================================================
// Chunked IndexedDB lexicon store
//
// Decoded lexicon entries are persisted once as ~500-1000 sorted range-chunk
// records (~1000 words each) instead of being re-parsed from the zip on every
// visit. Return visits skip download+unzip+prefix-decode entirely: they read
// the ~500 chunk keys (instant) and fetch only the chunks a text actually
// touches via prefetch(). Same design as the macronizer's wordlist store,
// where it took the first-visit persist from ~10min to seconds.
// ===========================================================================

const CHUNK_DB_NAME = "LexiconChunksDB_v1";
const CHUNK_WORDS_PER_CHUNK = 1000;

let chunkDbPromise = null;
function openChunkDb() {
  if (!chunkDbPromise) {
    chunkDbPromise = new Promise((resolve, reject) => {
      const req = indexedDB.open(CHUNK_DB_NAME, 1);
      req.onupgradeneeded = () => {
        const db = req.result;
        // Composite key: one store serves every language
        db.createObjectStore("chunks", { keyPath: ["lang", "firstWord"] });
        db.createObjectStore("meta", { keyPath: "lang" });
      };
      req.onsuccess = () => resolve(req.result);
      req.onerror = () => reject(req.error);
    });
  }
  return chunkDbPromise;
}

function idbReq(request) {
  return new Promise((resolve, reject) => {
    request.onsuccess = () => resolve(request.result);
    request.onerror = () => reject(request.error);
  });
}

/** Range covering every chunk key of one language. */
function langRange(lang) {
  return IDBKeyRange.bound([lang, ""], [lang + " ", ""], false, true);
}

/**
 * A lexicon backed by the chunk store. Two modes:
 * - "memory": the session that parsed the zip — full Map resident, sync get()
 *   hits it directly while chunks persist in the background.
 * - "chunked": return visits — only chunk keys are resident; prefetch(words)
 *   pulls the needed chunks before the (sync) get() calls run.
 */
class ChunkedLexicon {
  constructor(language) {
    this.language = language;
    this.fullMap = null; // memory mode
    this.chunkKeys = null; // chunked mode: sorted firstWords
    this.chunkCache = new Map(); // firstWord -> {word: value}
    this.persistPromise = null;
  }

  get mode() {
    return this.fullMap ? "memory" : "chunked";
  }

  /** Sorted-array binary search: greatest chunk key <= word. */
  chunkKeyFor(word) {
    const keys = this.chunkKeys;
    if (!keys || keys.length === 0) return null;
    let lo = 0,
      hi = keys.length - 1,
      pos = -1;
    while (lo <= hi) {
      const mid = (lo + hi) >> 1;
      if (keys[mid] <= word) {
        pos = mid;
        lo = mid + 1;
      } else hi = mid - 1;
    }
    return pos === -1 ? null : keys[pos];
  }

  /** Sync lookup — from the Map (memory mode) or prefetched chunks. */
  get(key) {
    if (this.fullMap) return this.fullMap.get(key) ?? null;
    const chunkKey = this.chunkKeyFor(key);
    if (chunkKey === null) return null;
    const chunk = this.chunkCache.get(chunkKey);
    if (!chunk) {
      // Word wasn't covered by prefetch() — sync API can't fetch now.
      console.warn(
        `[ChunkedLexicon:${this.language}] get("${key}") missed prefetch`,
      );
      return null;
    }
    return chunk[key] ?? null;
  }

  has(key) {
    return this.get(key) !== null;
  }

  size() {
    return this.fullMap ? this.fullMap.size : -1;
  }

  /**
   * Ensure the chunks for these words (and their lookup variants) are in
   * memory. Variants mirror every sync caller: lookupInLexicon strips
   * non-letters, and both it and the RU/UK stress code retry lowercased.
   */
  async prefetch(words) {
    if (this.fullMap) return; // memory mode: everything is resident
    if (!this.chunkKeys) await this.loadChunkKeys();

    const needed = new Set();
    for (const raw of words) {
      const cleaned = String(raw).replace(/[^\p{Letter}\p{Mark}-]+/gu, "");
      if (!cleaned) continue;
      for (const candidate of [cleaned, cleaned.toLowerCase()]) {
        const chunkKey = this.chunkKeyFor(candidate);
        if (chunkKey !== null && !this.chunkCache.has(chunkKey)) {
          needed.add(chunkKey);
        }
      }
    }
    if (needed.size === 0) return;

    // Non-fatal like every other IDB path here: a blocked/broken IndexedDB
    // degrades to lookup misses (rule-based fallback), not a dead transcribe()
    try {
      const db = await openChunkDb();
      const tx = db.transaction(["chunks"], "readonly");
      const store = tx.objectStore("chunks");
      await Promise.all(
        [...needed].map(async (firstWord) => {
          const rec = await idbReq(store.get([this.language, firstWord]));
          // kv is stored as a JSON string: cloning one string in/out of
          // IndexedDB is far cheaper than structured-cloning a 1000-key object
          this.chunkCache.set(firstWord, rec ? JSON.parse(rec.kv) : {});
        }),
      );
    } catch (e) {
      console.warn(`[ChunkedLexicon:${this.language}] prefetch failed`, e);
    }
  }

  async loadChunkKeys() {
    try {
      const db = await openChunkDb();
      const tx = db.transaction(["chunks"], "readonly");
      const keys = await idbReq(
        tx.objectStore("chunks").getAllKeys(langRange(this.language)),
      );
      // Composite keys arrive as [lang, firstWord], ascending
      this.chunkKeys = keys.map((k) => k[1]);
    } catch (e) {
      console.warn(`[ChunkedLexicon:${this.language}] loadChunkKeys failed`, e);
      // Leave chunkKeys null so a later prefetch() retries after a
      // transient failure; chunkKeyFor() treats null as "no chunks"
    }
  }

  /** Persist the full map as sorted range chunks (background, non-fatal). */
  persistInBackground(sourceFile) {
    this.persistPromise = (async () => {
      const db = await openChunkDb();
      const words = [...this.fullMap.keys()].sort();
      const chunks = [];
      for (let i = 0; i < words.length; i += CHUNK_WORDS_PER_CHUNK) {
        const kv = {};
        for (const w of words.slice(i, i + CHUNK_WORDS_PER_CHUNK)) {
          kv[w] = this.fullMap.get(w);
        }
        // Serialize once: one string clones into IndexedDB far faster than
        // a 1000-key object (this was most of the persist wall time)
        chunks.push({
          lang: this.language,
          firstWord: words[i],
          kv: JSON.stringify(kv),
        });
      }

      // Replace any stale chunks, write new ones in a few transactions
      await new Promise((resolve, reject) => {
        const tx = db.transaction(["chunks", "meta"], "readwrite");
        tx.objectStore("chunks").delete(langRange(this.language));
        tx.objectStore("meta").delete(this.language);
        tx.oncomplete = resolve;
        tx.onerror = () => reject(tx.error);
      });
      const PER_TX = 100;
      for (let i = 0; i < chunks.length; i += PER_TX) {
        const batch = chunks.slice(i, i + PER_TX);
        await new Promise((resolve, reject) => {
          const tx = db.transaction(["chunks"], "readwrite");
          batch.forEach((c) => tx.objectStore("chunks").put(c));
          tx.oncomplete = resolve;
          tx.onerror = () => reject(tx.error);
        });
        // Reloading mid-save discards it (meta is written last), so tell the
        // user it's running instead of failing silently on every early reload
        updateLoadingText(
          "",
          "",
          `Saving dictionary for faster future visits… ${Math.round(((i + batch.length) / chunks.length) * 100)}%`,
        );
        await new Promise((r) => setTimeout(r, 0));
      }
      // Meta written last: an interrupted persist reads as unpopulated
      await new Promise((resolve, reject) => {
        const tx = db.transaction(["meta"], "readwrite");
        tx.objectStore("meta").put({
          lang: this.language,
          sourceFile,
          count: this.fullMap.size,
          storedAt: Date.now(),
        });
        tx.oncomplete = resolve;
        tx.onerror = () => reject(tx.error);
      });
      updateLoadingText("", "", "Dictionary saved — next visit loads instantly ✓");
      setTimeout(() => updateLoadingText("", "", ""), 4000);
      console.log(
        `[ChunkedLexicon:${this.language}] persisted ${chunks.length} chunks (${this.fullMap.size} words)`,
      );
    })().catch((err) => {
      // Non-fatal: this session works from memory; next visit re-parses
      console.warn(
        `[ChunkedLexicon:${this.language}] background persist failed:`,
        err,
      );
    });
  }
}

/**
 * Try to serve a language from previously persisted chunks. Returns a
 * ChunkedLexicon in chunked mode, or null if absent/stale (sourceFile is the
 * zip filename — bumping the version in LEXICON_LANGUAGES invalidates).
 */
async function loadFromChunkStore(language, sourceFile) {
  try {
    const db = await openChunkDb();
    const meta = await idbReq(
      db.transaction(["meta"], "readonly").objectStore("meta").get(language),
    );
    if (!meta || meta.sourceFile !== sourceFile || !(meta.count > 0)) {
      return null;
    }
    const lexicon = new ChunkedLexicon(language);
    await lexicon.loadChunkKeys();
    if (lexicon.chunkKeys.length === 0) return null;
    console.log(
      `[ChunkedLexicon:${language}] serving from ${lexicon.chunkKeys.length} stored chunks (${meta.count} words)`,
    );
    return lexicon;
  } catch (err) {
    console.warn(`[ChunkedLexicon:${language}] store unavailable:`, err);
    return null;
  }
}

/** Wrap a freshly parsed entries Map and start the background persist. */
function makeMemoryLexicon(language, entriesMap, sourceFile) {
  const lexicon = new ChunkedLexicon(language);
  lexicon.fullMap = entriesMap;
  lexicon.persistInBackground(sourceFile);
  return lexicon;
}

async function loadLexicon(language) {
  if (!LEXICON_LANGUAGES[language]) {
    throw new Error(`Unsupported language: ${language}`);
  }

  console.time("LexiconLoad");
  let worker;

  try {
    // Return visit: serve from persisted chunks — no download, no parse
    const fromStore = await loadFromChunkStore(
      language,
      LEXICON_LANGUAGES[language],
    );
    if (fromStore) {
      console.timeEnd("LexiconLoad");
      updateLoadingText("", "", "");
      return fromStore;
    }

    // Special handling for optimized format
    if (
      language === "French" ||
      language === "German" ||
      language === "Ukrainian" ||
      language === "Russian"
    ) {
      return await loadOptimizedLexicon(language);
    }

    // Standard loading for other languages
    console.log("Fetching zip");
    updateLoadingText("", "", "Downloading lexicon");
    const zipBlob = await fetchWithCache(
      LEXICON_FOLDER + LEXICON_LANGUAGES[language],
      (progress) =>
        updateLoadingText(
          "",
          "",
          `Downloading lexicon ${progress.toFixed(2)}%`,
        ),
    );

    // Process blob
    console.log("Processing zip blob");
    const blob = await zipBlob.blob();
    updateLoadingText("", "", "Loading lexicon");

    // Extract lexicon data
    console.log("Extracting lexicon data");
    const wordPairsList = await loadFileFromZipOrPath(blob, "lexicon.json");

    // Initialize worker for processing
    worker = new Worker("scripts/lexicon_loader_worker.js");
    const lexiconData = await processLexiconWithWorker(worker, wordPairsList);

    // Serve this session from memory; persist chunks for the next visit
    const entriesMap =
      lexiconData instanceof Map
        ? lexiconData
        : new Map(Object.entries(lexiconData));
    const lexiconInterface = makeMemoryLexicon(
      language,
      entriesMap,
      LEXICON_LANGUAGES[language],
    );

    console.timeEnd("LexiconLoad");
    console.log("Lexicon loading complete");

    return lexiconInterface;
  } catch (error) {
    console.error("Lexicon loading failed:", error);
    updateLoadingText("", "", "Failed to load lexicon");
  } finally {
    if (worker) {
      worker.terminate();
    }
  }
}

async function loadOptimizedLexicon(language) {
  try {
    console.log("Loading optimized  lexicon");
    updateLoadingText("", "", "Downloading optimized lexicon");
    const downloadStart = performance.now();
    const zipBlob = await fetchWithCache(
      LEXICON_FOLDER + LEXICON_LANGUAGES[language],
      (progress) =>
        updateLoadingText(
          "",
          "",
          `Downloading optimized lexicon ${progress.toFixed(2)}%`,
        ),
    );

    const downloadTime = performance.now() - downloadStart;
    const blob = await zipBlob.blob();

    const optimizedLexicon = new OptimizedV3Lexicon();
    optimizedLexicon.stats.downloadTime = downloadTime;
    const success = await optimizedLexicon.loadFromBlob(blob, language);

    if (!success) {
      throw new Error("Failed to load optimized lexicon");
    }

    // Serve this session from memory; persist chunks for the next visit
    const lexiconInterface = makeMemoryLexicon(
      language,
      optimizedLexicon.entries,
      LEXICON_LANGUAGES[language],
    );

    console.timeEnd("LexiconLoad");
    console.log(`Optimized ${language} lexicon loading complete`);
    updateLoadingText("", "", ""); // Clear loading text

    return lexiconInterface;
  } catch (error) {
    console.error(`Optimized ${language} lexicon loading failed:`, error);
    updateLoadingText("", "", "Failed to load optimized lexicon");
    throw error;
  }
}

function processLexiconWithWorker(worker, text) {
  return new Promise((resolve, reject) => {
    worker.onmessage = (e) => {
      try {
        resolve(e.data);
      } catch (err) {
        reject(err);
      }
    };

    worker.onerror = (error) => {
      reject(new Error(`Worker error: ${error.message}`));
    };

    worker.postMessage(text);
  });
}

export { loadLexicon, OptimizedV3Lexicon, ChunkedLexicon };
