import {
  fetchWithCache,
  loadFileFromZipOrPath,
  updateLoadingText,
} from "./utils.js";

const LEXICON_LANGUAGES = {
  German: "german_lexicon.zip",
  Czech: "czech_lexicon.zip",
  French: "french_lexicon.zip",
  Lithuanian: "lt_lexicon.zip",
};

const LEXICON_FOLDER = "./utils/";

async function loadLexicon(language) {
  if (!LEXICON_LANGUAGES[language]) {
    throw new Error(`Unsupported language: ${language}`);
  }

  console.time("LexiconLoad");
  let worker;

  try {
    // Download lexicon zip
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

class LargeDictionaryHandler {
  constructor(data, chunkSize = 100000) {
    console.log("init LargeDictionaryHandler", chunkSize);
    this.chunks = this.chunkify(data, chunkSize);
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
export { loadLexicon };
