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
    throw error;
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

function createLexiconInterface(lexiconData) {
  return {
    data: lexiconData,
    get(key) {
      return this.data[key];
    },
  };
}

export { loadLexicon };
