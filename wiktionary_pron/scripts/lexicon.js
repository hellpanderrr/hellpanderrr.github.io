import { loadFileFromZipOrPath, fetchWithCache } from "./utils.js";

async function loadLexicon(language) {
  const languages = {
    German: "german_lexicon.zip",
  };
  const lexiconFolder = "./utils/";

  const zipBlob = await fetchWithCache(lexiconFolder + languages[language]);
  const blob = await zipBlob.blob();
  const wordPairsList = await loadFileFromZipOrPath(blob, "de_lexicon.json");

  const worker = new Worker("scripts/lexicon_loader_worker.js");

  function process_lexicon(text) {
    return new Promise((resolve) => {
      worker.onmessage = function (e) {
        resolve(e.data);
      };

      worker.postMessage(text);
    });
  }

  const lexicon = await process_lexicon(wordPairsList);
  worker.terminate();
  return lexicon;
}

export { loadLexicon };
