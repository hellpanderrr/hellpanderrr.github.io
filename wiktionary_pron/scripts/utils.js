async function asyncMapStrict(arr, fn) {
  const result = [];
  // console.time("Elapsed time :");
  for (let idx = 0; idx < arr.length; idx += 1) {
    const cur = arr[idx];
    await new Promise((resolve) => setTimeout(resolve, 0.0001));

    result.push(await fn(cur, idx, arr));
  }
  // console.timeEnd("Elapsed time :")
  return result;
}

function sanitize(text) {
  return text
    .replace(/[^\p{L}\p{M}'’-]/gu, "")
    .replaceAll("’", "'")
    .normalize("NFKC");
}

/**
 * Memoizes the given function in local storage.
 * @param {Function} fn - The function to memoize.
 * @param {Object} options - Memoization options.
 * @param {number} options.ttl - Time to live for cached results in milliseconds.
 * @param {boolean} options.backgroundRefresh - Whether to refresh the cache in the background.
 * @throws {Error} Throws an error if the function is anonymous.
 * @returns {Function} Returns the memoized function.
 */
/**
 * Memoizes both sync and async functions in localStorage with TTL support
 * @param {Function} fn - The function to memoize
 * @param {Object} options - Memoization options
 * @param {number} options.ttl - Time to live in milliseconds
 * @param {boolean} options.backgroundRefresh - Whether to refresh cache in background
 */
function memoizeLocalStorage(
  fn,
  options = { ttl: 100, backgroundRefresh: false },
) {
  if (!fn.name) {
    console.warn("Warning: memoizeLocalStorage called with anonymous function");
    throw new Error("memoizeLocalStorage only accepts non-anonymous functions");
  }

  let cache = JSON.parse(localStorage.getItem(fn.name) || "{}");
  const debug = options.debug || false;

  function log(...args) {
    if (debug) console.log(`[Memoize:${fn.name}]`, ...args);
  }

  async function executeAndCache(args, argsKey) {
    log("Executing function with args:", args);
    try {
      const result = fn(...args);
      const isPromise = result instanceof Promise;

      const finalResult = isPromise ? await result : result;
      const cacheEntry = {
        expiration: Date.now() + options.ttl,
        result: finalResult,
        isPromise,
      };

      cache[fn.name] = {
        ...cache[fn.name],
        [argsKey]: cacheEntry,
      };

      try {
        localStorage.setItem(fn.name, JSON.stringify(cache));
        log("Cached result:", finalResult);
      } catch (e) {
        console.warn(`Cache storage failed for ${fn.name}:`, e);
        // Clear old entries if storage fails
        cache = { [fn.name]: { [argsKey]: cacheEntry } };
        localStorage.setItem(fn.name, JSON.stringify(cache));
      }

      return finalResult;
    } catch (error) {
      console.error(`Execution failed for ${fn.name}:`, error);
      throw error;
    }
  }

  return function memoized(...args) {
    const argsKey = JSON.stringify(args);
    const now = Date.now();
    const currentCache = cache[fn.name]?.[argsKey];

    if (currentCache && currentCache.expiration > now) {
      log("Cache hit");

      // Background refresh near expiration
      if (
        options.backgroundRefresh &&
        currentCache.expiration - now < options.ttl * 0.2
      ) {
        log("Starting background refresh");
        executeAndCache(args, argsKey).catch((error) =>
          console.error(`Background refresh failed for ${fn.name}:`, error),
        );
      }

      // Return cached result, wrapping in Promise if original was async
      return currentCache.isPromise
        ? Promise.resolve(currentCache.result)
        : currentCache.result;
    }

    log("Cache miss");
    return executeAndCache(args, argsKey);
  };
}

// Utility functions for cache management
memoizeLocalStorage.clearCache = function (fnName) {
  if (fnName) {
    localStorage.removeItem(fnName);
  } else {
    Object.keys(localStorage)
      .filter((key) => localStorage.getItem(key).includes('"expiration":'))
      .forEach((key) => localStorage.removeItem(key));
  }
};

memoizeLocalStorage.getCacheStats = function (fnName) {
  const cache = JSON.parse(localStorage.getItem(fnName) || "{}");
  const now = Date.now();

  return {
    totalEntries: Object.keys(cache[fnName] || {}).length,
    validEntries: Object.values(cache[fnName] || {}).filter(
      (entry) => entry.expiration > now,
    ).length,
    oldestEntry: Math.min(
      ...Object.values(cache[fnName] || {}).map((entry) => entry.expiration),
    ),
    newestEntry: Math.max(
      ...Object.values(cache[fnName] || {}).map((entry) => entry.expiration),
    ),
  };
};

async function wait(ms = 1) {
  await new Promise((resolve) => setTimeout(resolve, ms));
}

function clearStorage() {
  // const cache = JSON.parse(localStorage.getItem("get_ipa_no_cache") || "{}");
  // cache["get_ipa_no_cache"] = "";
  // localStorage.setItem("get_ipa_no_cache", JSON.stringify(cache));
  localStorage.clear();
  localforage.clear();
}

function updateLoadingText(filePath, fileExtension, rawText) {
  const loadingBar = document.getElementById("loading_text");
  rawText = rawText || "";

  if (!filePath && !fileExtension && !rawText) {
    loadingBar.innerHTML = "";
    loadingBar.style.display = "none";
  } else if (filePath && fileExtension) {
    loadingBar.innerHTML = `Loading ${filePath}.${fileExtension}`;
    loadingBar.style.display = "block";
  } else if (rawText) {
    loadingBar.innerHTML = rawText;
    loadingBar.style.display = "block";
  }
}

/**
 * Helper function to encapsulate the repeated lexicon lookup logic.
 * @param {string} lexiconName - The name of the lexicon (e.g., "German").
 * @param {string} text - The text to look up.
 * @returns {string|null} The dictionary record or null if not found.
 */
function lookupInLexicon(lexiconName, text) {
  if (!globalThis.lexicon || !globalThis.lexicon[lexiconName]) {
    return null;
  }
  const lexicon = globalThis.lexicon[lexiconName];
  const cleanedForLookup = text.replace(/[^\p{Letter}\p{Mark}-]+/gu, "");

  let dictRecord = lexicon.get(cleanedForLookup);
  if (!dictRecord) {
    dictRecord = lexicon.get(cleanedForLookup.toLowerCase());
  }

  console.log(`Lexicon lookup for "${text}" in ${lexiconName}:`, dictRecord);
  return dictRecord;
}

/**
 * A map of language-specific handlers to replace the main switch statement.
 * Each handler receives a context object and returns the calculated IPA string.
 */
const ipaHandlers = {
  // --- Group 1: Unique/Complex Handlers ---

  Latin: ({ cleanText, langStyle, langForm }) => {
    const isPhonetic = langForm === "Phonetic";
    const options = {
      Ecclesiastical: { ecclesiastical: true, vulgar: false },
      Classical: { ecclesiastical: false, vulgar: false },
      Vulgar: { ecclesiastical: false, vulgar: true },
    };
    const styleOptions = options[langStyle];
    if (!styleOptions) return null;

    return window.la_ipa.convert_words(
      cleanText,
      isPhonetic,
      styleOptions.ecclesiastical,
      styleOptions.vulgar,
    );
  },

  Portuguese: ({ cleanText, langStyle, langForm }) => {
    const region = langStyle === "Brazil" ? "rio" : "pt";
    const result = window.pt_ipa.IPA(cleanText, region);
    return result?.[0]?.[langForm.toLowerCase()];
  },

  Spanish: ({ cleanText, langStyle, langForm }) => {
    const dialect =
      langStyle === "Castilian" ? "distincion-yeismo" : "seseo-yeismo";
    const isPhonetic = langForm === "Phonetic";
    const result = window.es_ipa.IPA(cleanText, dialect, isPhonetic);
    return result?.text;
  },

  Ukrainian: ({ cleanText, langForm }) => {
    if (langForm !== "Phonetic") return null;

    // --- Stage 1: Check for a definitive version in the dictionary ---
    if (globalThis.lexicon?.["Ukrainian"] && cleanText.trim().length > 0) {
      const dictRecord =
        globalThis.lexicon["Ukrainian"].get(
          cleanText.replace(/[^\p{Letter}\p{Mark}-]+/gu, ""),
        ) ||
        globalThis.lexicon["Ukrainian"].get(
          cleanText.replace(/[^\p{Letter}\p{Mark}-]+/gu, "").toLowerCase(),
        );
      if (dictRecord) {
        console.log("Ukrainian: Found in dictionary:", dictRecord);

        // 1. Split by comma in case there are multiple forms (e.g., "замо́к,за́мок").
        // 2. Trim whitespace from each resulting word.
        const stressedForms = dictRecord.split(",").map((word) => word.trim());

        // Generate an IPA for each stressed form provided by the dictionary.
        const ipas = stressedForms
          .map((form) => window.uk_ipa.pronunciation(form, true))
          .filter((ipa) => ipa) // Filter out any unsuccessful IPA generations
          .map((ipa) => `/${ipa}/`) // Format each successful IPA
          .join(","); // Join into the final string, e.g., "/ipa1/,/ipa2/"

        return ipas || null;
      }
    }

    // --- Stage 2: If not in dictionary, analyze and process ---
    const VOWEL_REGEX = /[аеиіоуєюяї]/i;
    const STRESS_MARK = "\u0301";
    const applyStress = (vowel) => vowel + STRESS_MARK;

    const syllables = cleanText.match(new RegExp(VOWEL_REGEX.source, "gi"));
    const syllableCount = syllables ? syllables.length : 0;

    // Case A: 0 or 1 syllables. Stress it and return a single IPA.
    if (syllableCount <= 1) {
      const stressedText =
        syllableCount === 1
          ? cleanText.replace(/[аеиіоуєюяїАЕИІОУЄЮЯЇ]/, applyStress)
          : cleanText;
      return window.uk_ipa.pronunciation(stressedText, true);
    }

    // Case B (Concise): Multi-syllable. Generate all variants using a functional chain.
    const possibleIPAs = [...cleanText]
      .map((char, index) => (VOWEL_REGEX.test(char) ? index : -1)) // Get indices of all vowels
      .filter((index) => index !== -1) // Filter out non-vowel markers
      .map((index) => {
        // For each vowel index, create a stressed word and get its IPA
        const stressedVowel = applyStress(cleanText[index]);
        const stressedWord =
          cleanText.slice(0, index) +
          stressedVowel +
          cleanText.slice(index + 1);
        return window.uk_ipa.pronunciation(stressedWord, true);
      })
      .filter((ipa) => ipa) // Filter out any unsuccessful IPA generations
      .map((ipa) => `/${ipa}/`) // Format each successful IPA
      .join(","); // Join into the final string

    return possibleIPAs || null; // Return the generated string or null if empty
  },
  Russian: ({ cleanText, langForm }) => {
    if (langForm !== "Phonetic") return null;

    // --- Stage 1: Check for definitive versions in the dictionary (Unchanged) ---
    if (globalThis.lexicon?.["Russian"] && cleanText.trim().length > 0) {
      const cleanedKey = cleanText.replace(/[^\p{Letter}\p{Mark}-]+/gu, "");

      const dictRecord =
        globalThis.lexicon["Russian"].get(cleanedKey) ||
        globalThis.lexicon["Russian"].get(cleanedKey.toLowerCase());

      function prioritizeStressedIpa(ipaString) {
        return (
          ipaString &&
          Object.values(
            // Use a Set to efficiently handle identical duplicates from the start
            Array.from(new Set(ipaString.split(",")))
              .map((ipa) => ipa.trim().replace(/^\/|\/$/g, "")) // Clean up each IPA string
              .filter(Boolean) // Remove any empty strings
              .reduce((best, ipa) => {
                // Reduce the array to an object of the best versions
                const base = ipa.replace(/ˈ/g, ""); // The key for grouping is the IPA without stress
                const existing = best[base];
                // The new `ipa` is better if no version exists yet, or if the new one is stressed and the old one isn't.
                if (
                  !existing ||
                  (ipa.includes("ˈ") && !existing.includes("ˈ"))
                ) {
                  best[base] = ipa;
                }
                return best;
              }, {}),
          )
            .map((ipa) => `/${ipa}/`)
            .join(",")
        ); // Format the final values back into a string
      }

      if (dictRecord) {
        console.log("Russian: Found in dictionary:", dictRecord);
        const stressedForms = dictRecord.split(",").map((word) => word.trim());
        const ipas = stressedForms
          .map((form) => window.ru_ipa.ipa_string(form))
          .filter((ipa) => ipa)
          .map((ipa) => `/${ipa}/`)
          .join(",");
        return prioritizeStressedIpa(ipas) || null;
      }
    }

    // --- Stage 2: Fallback logic for words not in the dictionary  ---
    const VOWEL_REGEX = /[аэиуеюяёоы]/i; // Russian vowels
    const STRESS_MARK = "\u0301";
    const applyStress = (vowel) => vowel + STRESS_MARK;

    const syllables = cleanText.match(new RegExp(VOWEL_REGEX.source, "gi"));
    const syllableCount = syllables ? syllables.length : 0;

    // Case A: 0 or 1 syllables. Stress it and return a single IPA.
    if (syllableCount <= 1) {
      const stressedText =
        syllableCount === 1
          ? cleanText.replace(/[аэиуеюяёоАЭИУЕЮЯЁОЫ]/, applyStress) // Russian vowel set
          : cleanText;
      const singleIpa = window.ru_ipa.ipa_string(stressedText); // Russian IPA function
      return singleIpa ? `/${singleIpa}/` : null;
    }

    // Case B: Multi-syllable. Generate all variants using a functional chain.
    const possibleIPAs = [...cleanText]
      .map((char, index) => (VOWEL_REGEX.test(char) ? index : -1))
      .filter((index) => index !== -1)
      .map((index) => {
        const stressedVowel = applyStress(cleanText[index]);
        const stressedWord =
          cleanText.slice(0, index) +
          stressedVowel +
          cleanText.slice(index + 1);
        return window.ru_ipa.ipa_string(stressedWord); // Russian IPA function
      })
      .filter((ipa) => ipa)
      .map((ipa) => `/${ipa}/`)
      .join(",");

    return possibleIPAs || null;
  },

  Greek: ({ cleanText, langStyle }) => {
    const styleMap = {
      "5th BCE Attic": "cla",
      "1st CE Egyptian": "koi1",
      "4th CE Koine": "koi2",
      "10th CE Byzantine": "byz1",
      "15th CE Constantinopolitan": "byz2",
    };
    const styleCode = styleMap[langStyle];
    if (!styleCode) return null;
    const result = window.grc_ipa.IPA(cleanText, styleCode);
    return result?.[styleCode]?.IPA;
  },

  Armenian: ({ cleanText, langStyle, langForm }) => {
    const system = langStyle === "Western" ? "west" : "east";
    const methodMap = { Phonemic: "phonemic_IPA", Phonetic: "phonetic_IPA" };
    const method = methodMap[langForm];
    return method ? window.hy_ipa[method](cleanText, system) : null;
  },

  Italian: ({ cleanText, langForm }) => {
    if (langForm === "Phonemic") {
      const result = window.it_ipa.to_phonemic(cleanText, "TEST");
      return result?.phonemic;
    }
    return null;
  },

  // --- Group 2: Direct Generation for Phonemic form (No Lexicon) ---
  ...Object.fromEntries(
    ["Belorussian", "Bulgarian", "Polish"].map((lang) => [
      lang,
      ({ cleanText, langForm }) => {
        if (langForm !== "Phonemic") return null;
        const generators = {
          Belorussian: () => window.be_ipa.toIPA(cleanText),
          Bulgarian: () => window.bg_ipa.toIPA(cleanText),
          Polish: () => window.pl_ipa.convert_to_IPA(cleanText),
        };
        return generators[lang]();
      },
    ]),
  ),

  // --- Group 3: Lexicon Lookup with Generation Fallback ---
  ...Object.fromEntries(
    ["German", "French", "Czech", "Lithuanian", "Icelandic"].map((lang) => [
      lang,
      ({ cleanText, langForm, langStyle }) => {
        // langStyle needed for French post-processing
        let ipa = null;

        // Step 1: Attempt lexicon lookup for Phonemic form
        if (langForm === "Phonemic") {
          const dictRecord = lookupInLexicon(lang, cleanText);
          if (dictRecord) {
            ipa = dictRecord;
          }
        }

        // Step 2: If no record found, use a generator
        if (ipa === null) {
          const generators = {
            German: {
              Phonemic: () => window.de_ipa.phonemic(cleanText),
              Phonetic: () => window.de_ipa.phonetic(cleanText),
            },
            French: {
              Phonemic: () => window.fr_ipa.show(cleanText)?.[0],
            },
            Czech: {
              Phonemic: () => window.cs_ipa.toIPA(cleanText),
            },
            Lithuanian: {
              Phonemic: () => window.lt_ipa.toIPA(cleanText, true),
            },
            Icelandic: {
              Phonemic: () => window.is_ipa.toIPA(cleanText, "", ""),
            },
          };
          const langGenerator = generators[lang]?.[langForm];
          if (langGenerator) {
            ipa = langGenerator();
          }
        }

        // Step 3: Apply language-specific post-processing
        if (
          lang === "French" &&
          langStyle === "Parisian (experimental)" &&
          ipa
        ) {
          ipa = ipa
            .replace(/ɔ̃̃̃̃̃̃|ɔ̃/g, "õ")
            .replace(/ɑ̃/g, "ɔ̃")
            .replace(/œ̃|ɛ̃/g, "ɑ̃");
        }

        return ipa;
      },
    ]),
  ),
};

/**
 * Retrieves the IPA transcription for a given text without using a cache.
 */
function get_ipa_no_cache(text, args) {
  const cleanText = sanitize(text);
  console.log("doing actual IPA", text, cleanText, args);

  const [lang, langStyle, langForm] = args.split(";");

  let ipa = "";
  try {
    const handler = ipaHandlers[lang];
    if (handler) {
      ipa = handler({ cleanText, lang, langStyle, langForm }) || "";
      console.log(`Handler for "${lang}" returned:`, ipa);
    } else {
      console.log(`No handler found for language: "${lang}"`);
    }
  } catch (err) {
    ipa = ""; // Ensure ipa is reset on error
    console.error("Error during IPA conversion:", err);
  }

  if (!ipa) {
    return { value: text, status: "error" };
  }

  // The French post-processing has been moved into its specific handler.
  // The main function is now cleaner.
  console.log("final ipa ", ipa);
  return { value: ipa, status: "success" };
}
function createElementFromHTML(htmlString) {
  var div = document.createElement("div");
  div.innerHTML = htmlString.trim();

  // Change this to div.childNodes to support multiple top-level nodes.
  return div.firstChild;
}

async function loadFileFromZipOrPath(zipPathOrBlob, filename) {
  return new Promise((resolve, reject) => {
    loadJs("./scripts/lib/jszip.min.js", async () => {
      await loadJs("./scripts/lib/jszip-utils.min.js", async () => {
        let data;
        if (!(typeof zipPathOrBlob === "string")) {
          console.log("blob", zipPathOrBlob);
          data = zipPathOrBlob;
        } else {
          console.log("path", zipPathOrBlob);
          const response = await fetchWithCache(zipPathOrBlob);
          data = await response.blob();
        }
        JSZip.loadAsync(data)
          .then(async (zip) => {
            const fileData = await zip.file(filename).async("string");
            resolve(fileData);
          })
          .catch((error) => {
            console.error(error);
            reject(error); // or handle the error as needed
          });
      });
    });
  });
}

async function sendParallelRequests(urls) {
  const promises = urls.map((url) => fetch(url));

  try {
    const results = await Promise.any(promises);
    return results;
  } catch (error) {
    return null; // Handle errors if no promises resolve successfully
  }
}

async function fetchWithCacheMultiple(urls) {
  const url = urls[0].split("/").slice(-2).join("/");

  console.log("    reading cache", url);
  const cachedResponse = await localforage.getItem(url);
  if (cachedResponse) {
    console.log("    reading from cache", url);
    if (cachedResponse instanceof Blob) {
      const response = new Response(cachedResponse);
      response.headers.set("X-From-Cache", "true");
      console.log("Returned cached blob ", url);
      return response;
    }
    const response = new Response(JSON.parse(cachedResponse));
    response.headers.set("X-From-Cache", "true");
    console.log("    Returned cached string ", url);
    return response;
  }
  console.log("    caching ", url);

  // const response = await fetch(url);
  const response = await sendParallelRequests(urls);

  const contentType = response.headers.get("content-type");
  let responseContent;
  let responseWithHeaders;

  if (contentType == "application/zip") {
    responseContent = await response.blob();
    try {
      await localforage.setItem(url, responseContent);
    } catch (err) {
      console.log(err);
    }
  } else {
    responseContent = await response.text();
    try {
      await localforage.setItem(url, JSON.stringify(responseContent));
    } catch (err) {
      console.log(err);
    }
  }
  responseWithHeaders = new Response(responseContent, response);
  return responseWithHeaders;
}

async function fetchWithCache(
  url,
  onProgress = (progress) => console.log(`Progress: ${progress.toFixed(2)}%`),
) {
  console.log("    reading cache", url);
  let cachedResponse = await localforage.getItem(url);
  if (cachedResponse) {
    console.log("    reading from cache", url);
    if (cachedResponse instanceof Blob) {
      const response = new Response(cachedResponse);
      response.headers.set("X-From-Cache", "true");
      console.log("    Returned cached blob ", url);
      return response;
    }
    const response = new Response(JSON.parse(cachedResponse));
    response.headers.set("X-From-Cache", "true");
    console.log("    Returned cached string ", url);
    return response;
  }
  console.log("    caching ", url);
  const response = await fetch(url);

  const contentLength = response.headers.get("content-length");
  const contentEncoding = response.headers.get("content-encoding");
  const isCompressed =
    contentEncoding === "gzip" ||
    contentEncoding === "br" ||
    contentEncoding === "deflate";

  // If the content is compressed, we'll estimate the uncompressed size
  // Average compression ratio for text/json is roughly 4:1, for binary files about 1.5:1
  const contentType = response.headers.get("content-type");
  const compressionRatio =
    contentType?.includes("text") || contentType?.includes("json") ? 4 : 1.5;
  const total =
    isCompressed && contentLength
      ? parseInt(contentLength, 10) * compressionRatio
      : parseInt(contentLength, 10);

  let loaded = 0;

  const reader = response.body.getReader();
  const stream = new ReadableStream({
    start(controller) {
      function read() {
        reader
          .read()
          .then(({ done, value }) => {
            if (done) {
              controller.close();
              return;
            }
            loaded += value.length;
            if (onProgress && total) {
              onProgress((loaded / total) * 100);
            }
            controller.enqueue(value);
            read();
          })
          .catch((error) => {
            console.error("    Stream reading error:", error);
            controller.error(error);
          });
      }

      read();
    },
  });

  const newResponse = new Response(stream, {
    headers: response.headers,
  });

  let responseContent;

  if (contentType && contentType.includes("zip")) {
    responseContent = await newResponse.blob();
    try {
      await localforage.setItem(url, responseContent);
    } catch (err) {
      console.log(err);
    }
  } else {
    responseContent = await newResponse.text();
    try {
      await localforage.setItem(url, JSON.stringify(responseContent));
    } catch (err) {
      console.log(err);
    }
  }

  return new Response(responseContent, {
    headers: newResponse.headers,
  });
}

const loadedScripts = {};

async function loadJs(url, code) {
  console.log(loadedScripts);
  if (loadedScripts[url]) {
    return new Promise((resolve) => {
      setTimeout(() => {
        code();
        resolve();
      }, 0);
    });
  }
  loadedScripts[url] = true;

  return new Promise((resolve, reject) => {
    const script = document.createElement("script");

    script.onload = () => {
      code();
      resolve();
    };

    script.onerror = reject;
    script.src = url;

    document.head.appendChild(script);
  });
}

/**
 * Disables all form elements on the page
 */
function disableAll(include_elements = []) {
  // Select all the forms on the page
  const forms = Array.from(document.querySelectorAll("form"));

  // Iterate through each form and disable all its elements
  forms.forEach((form) => {
    Array.from(form.elements)
      .concat(include_elements)
      .forEach((element) => {
        element.disabled = true;
      });
  });
}

function enableAll(include_elements = []) {
  // Get all the form elements on the page
  const forms = Array.from(document.querySelectorAll("form"));
  forms.forEach((form) => {
    // Enable all elements in the form
    Array.from(form.elements)
      .concat(include_elements)
      .forEach((element) => {
        element.disabled = false;
      });
  });
}

async function translateWithFallback(text, sourceLang = "auto", targetLang) {
  if (!text.match(/\p{L}/u)) {
    return {
      text: text, // Return original text
      source: "no-translation-needed",
    };
  }
  // First attempt: GTX API
  try {
    await wait(1); // Rate limiting
    const gtxUrl = `https://translate.googleapis.com/translate_a/single?client=gtx&sl=${sourceLang}&tl=${targetLang}&dt=t&q=${encodeURIComponent(
      text,
    )}`;
    const gtxResponse = await fetch(gtxUrl);

    if (gtxResponse.ok) {
      const gtxData = await gtxResponse.json();
      return {
        text: gtxData[0][0][0],
        source: "google-gtx",
      };
    }
  } catch (error) {
    console.warn("GTX API failed:", error);
  }

  // Second attempt: Clients5 API
  try {
    await wait(1); // Rate limiting
    const clients5Url = `https://clients5.google.com/translate_a/single?dj=1&dt=t&dt=sp&dt=ld&dt=bd&client=dict-chrome-ex&sl=${sourceLang}&tl=${targetLang}&q=${encodeURIComponent(
      text,
    )}`;
    const clients5Response = await fetch(clients5Url);

    if (clients5Response.ok) {
      const clients5Data = await clients5Response.json();
      return {
        text: clients5Data.sentences[0].trans,
        source: "google-clients5",
      };
    }
  } catch (error) {
    console.warn("Clients5 API failed:", error);
  }

  throw new Error("All translation attempts failed");
}

const translateWithFallbackWrapper = function (...args) {
  return translateWithFallback(...args)
    .then((result) => result)
    .catch((error) => {
      console.error("Translation failed:", error);
      throw error;
    });
};

// Now memoize the wrapper function
const translateWithFallbackCached = memoizeLocalStorage(
  translateWithFallbackWrapper,
  {
    ttl: 24 * 60 * 60 * 1000, // 24 hours
    backgroundRefresh: true,
  },
);
export {
  asyncMapStrict,
  sanitize,
  clearStorage,
  wait,
  get_ipa_no_cache,
  memoizeLocalStorage,
  loadJs,
  loadFileFromZipOrPath,
  createElementFromHTML,
  fetchWithCache,
  fetchWithCacheMultiple,
  disableAll,
  enableAll,
  updateLoadingText,
  translateWithFallbackCached,
};
