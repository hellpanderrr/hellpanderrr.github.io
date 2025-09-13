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

/**
 * Enhanced LargeDictionaryHandler for optimized lexicon
 * Maintains compatibility with existing code
 */
class LargeDictionaryHandler {
  constructor(data, chunkSize = 100000) {
    console.log("init LargeDictionaryHandler", chunkSize);
    console.time("Chunkfify");
    // If data is a Map (from optimized lexicon), convert to chunks
    if (data instanceof Map) {
      this.chunks = this.chunkifyMap(data, chunkSize);
    } else {
      this.chunks = this.chunkify(data, chunkSize);
    }
    console.timeEnd("Chunkfify");
    console.log("finished init LargeDictionaryHandler", chunkSize);
    this.chunkSize = chunkSize;
  }

  chunkify(data, chunkSize) {
    const chunks = [];
    const entries = Object.entries(data);

    for (let i = 0; i < entries.length; i += chunkSize) {
      const chunk = Object.fromEntries(entries.slice(i, i + chunkSize));
      chunks.push(chunk);
    }

    return chunks;
  }

  chunkifyMap(map, chunkSize) {
    const chunks = [];
    const entries = Array.from(map.entries());

    for (let i = 0; i < entries.length; i += chunkSize) {
      const chunk = Object.fromEntries(entries.slice(i, i + chunkSize));
      chunks.push(chunk);
    }

    return chunks;
  }

  get(key) {
    for (const chunk of this.chunks) {
      if (key in chunk) {
        return chunk[key];
      }
    }
    return undefined;
  }

  // Search within a specific chunk for better performance
  getFromChunk(key, chunkIndex) {
    if (chunkIndex >= 0 && chunkIndex < this.chunks.length) {
      return this.chunks[chunkIndex][key];
    }
    return undefined;
  }

  // Get the chunk index for a given key
  findChunkIndex(key) {
    return this.chunks.findIndex((chunk) => key in chunk);
  }

  // Iterator for processing all entries safely
  *entries() {
    for (const chunk of this.chunks) {
      for (const [key, value] of Object.entries(chunk)) {
        yield [key, value];
      }
    }
  }
}

function createLexiconInterface(lexiconData) {
  const handler = new LargeDictionaryHandler(lexiconData);

  return {
    data: lexiconData,
    get(key) {
      return handler.get(key);
    },
  };
}

async function loadLexicon(language) {
  if (!LEXICON_LANGUAGES[language]) {
    throw new Error(`Unsupported language: ${language}`);
  }

  console.time("LexiconLoad");
  let worker;

  try {
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

    // Create lexicon interface
    const lexiconInterface = createLexiconInterface(lexiconData);

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

    // Create compatible interface
    const lexiconInterface = {
      data: optimizedLexicon.entries, // Map for compatibility
      get(key) {
        return optimizedLexicon.get(key);
      },
      has(key) {
        return optimizedLexicon.has(key);
      },

      size() {
        return optimizedLexicon.size();
      },
      getMemoryUsage() {
        return optimizedLexicon.getMemoryUsage();
      },
      getPerformanceStats() {
        return optimizedLexicon.getPerformanceStats();
      },
    };

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

export { loadLexicon };
