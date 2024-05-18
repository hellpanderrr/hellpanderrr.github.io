import { loadFileFromZip } from "./utils.js";

async function loadLexicon(language) {
  const languages = {
    German: "german_lexicon.zip",
  };
  const lexiconFolder = "./utils/";
  const wordPairsList = await loadFileFromZip(
    lexiconFolder + languages[language],
    "de_lexicon.json",
  );

  function process_lexicon(text) {
    return new Promise((resolve) => {
      const worker = new Worker("scripts/lexicon_loader_worker.js");

      worker.onmessage = function (e) {
        resolve(e.data);
      };

      worker.postMessage(text);
    });
  }

  const lexicon = await process_lexicon(wordPairsList);
  return lexicon;
}

export { loadLexicon };
