let macronsList = null;

async function macronize(text) {
  if (!macronsList) {
    macronsList = new Map(
      JSON.parse(await fetch("./utils/macrons.json").then((x) => x.text())),
    );
  }

  function isUpper(x) {
    if (typeof x !== "string") return false;
    return x[0] === x[0].toUpperCase();
  }

  function capitalize(x) {
    if (typeof x !== "string") return false;
    return x[0].toUpperCase() + x.slice(1);
  }

  const get = (id) => macronsList.get(id) ?? id;

  /**
   * Macronize all words, keep surrounding punctuation.
   *
   */
  function processText(text) {
    return text
      .normalize("NFKC")
      .split(" ")
      .map((word) => word.split(/([\waeiouyȳāēīōūăĕĭŏŭ]+)/gi)) // splits into 3 parts, middle one has text itself
      .filter((wordParts) => wordParts[1] !== null)
      .map((wordParts) => {
        const middlePart = wordParts[1];
        const processedMiddlePart = isUpper(middlePart)
          ? capitalize(get(middlePart.toLowerCase()))
          : get(middlePart) || middlePart;
        return [wordParts[0], processedMiddlePart, wordParts[2]].join("");
      })
      .join(" ")
      .normalize("NFC");
  }

  return processText(text);
}

export { macronize };
