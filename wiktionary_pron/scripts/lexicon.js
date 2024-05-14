import { loadFileFromZip, splitAndAppend } from "./utils.js";

async function loadLexicon(language) {
  const languages = {
    German: "german_lexicon.zip",
  };
  const lexiconFolder = "./utils/";
  const wordPairsList = await loadFileFromZip(
    lexiconFolder + languages[language],
    "lexicon.txt",
  );

  function process_lexicon(text) {
    const split = text.split(/\r?\n/);
    const lines = [];

    const chunk = 10000;
    let index = 0;

    function processChunk() {
      return new Promise((resolve) => {
        let cnt = chunk;
        while (cnt-- && index < split.length) {
          const [text, ipa] = splitAndAppend(split[index], "\t", 1);
          if (!ipa.includes("|")) {
            lines.push([text, ipa.split(" ").join("")]);
          }
          index++;
        }
        if (index < split.length) {
          // simulate async iteration
          setTimeout(() => resolve(processChunk()), 1);
        } else {
          const dict = new Map(lines.reverse());
          resolve(dict);
        }
      });
    }

    return processChunk();
  }

  const lexicon = await process_lexicon(wordPairsList);
  return lexicon;
}

export { loadLexicon };
