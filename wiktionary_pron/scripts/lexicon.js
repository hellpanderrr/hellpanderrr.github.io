import { loadFileFromZipOrPath, fetchWithCache } from "./utils.js";

async function loadLexicon(language) {
  const languages = {
    German: "german_lexicon.zip",
    Czech: "czech_lexicon.zip",
    French: "french_lexicon.zip",
  };
  const lexiconFolder = "./utils/";
  console.time("A");
  console.log("Fetching zip");

  const zipBlob = await fetchWithCache(lexiconFolder + languages[language]);
  console.timeLog("A");
  console.log("Loaded zip");
  const blob = await zipBlob.blob();
  console.timeLog("A");
  console.log("Loaded blob");
  const wordPairsList = await loadFileFromZipOrPath(blob, "lexicon.json");
  console.timeLog("A");

  console.log("Loaded lexicon string");
  const worker = new Worker("scripts/lexicon_loader_worker.js");

  function process_lexicon(text) {
    return new Promise((resolve) => {
      worker.onmessage = function (e) {
        resolve(e.data);
      };

      worker.postMessage(text);
    });
  }

  globalThis.wordPairsList = wordPairsList;
  const lexicon = await process_lexicon(wordPairsList);
  const getMethod = function (key) {
    return this.data[key];
  };

  const jsonWithGetMethod = {
    data: lexicon,
  };

  // Attach the get method to the object
  jsonWithGetMethod.get = getMethod;
  console.timeEnd("A");

  console.log("Loaded lexicon dict");

  worker.terminate();
  return jsonWithGetMethod;
}

export { loadLexicon };
