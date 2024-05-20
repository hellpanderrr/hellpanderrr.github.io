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
    .replace(
      /[^\p{L}\p{M}'pbtdʈɖcɟkɡqɢʔmɱnɳɲŋɴʙrʀⱱɾɽɸβfvθðszʃʒʂʐçʝxɣχʁħʕhɦɬɮʋɹɻjɰlɭʎʟʘǀǃǂǁɓɗʄɠʛʼiyɨʉɯuɪʏʊeøɘɵɤoəɛœɜɞʌɔæɐaɶɑɒʍwɥʜʢʡɕʑɺɧ͜͡ˈˌːˑ̆|‖.‿̥̬ʰ̹̜̟̠̩̯̈̽˞̤̰̼ʷʲˠˤ̴̝̞̘̙̪̺̻̃ⁿˡ̋̚˥̌˩́˦̂̄˧᷄̀˨᷅̏᷈-]/gu,
      "",
    )
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
function memoizeLocalStorage(
  fn,
  options = { ttl: 100, backgroundRefresh: false },
) {
  if (!fn.name)
    throw new Error("memoizeLocalStorage only accepts non-anonymous functions");
  // Fetch localstorage or init new object
  let cache = JSON.parse(localStorage.getItem(fn.name) || "{}");

  //executes and caches result
  function executeAndCacheFn(fn, args, argsKey) {
    const result = fn(...args);
    // reset the cache value
    cache[fn.name] = {
      ...cache[fn.name],
      [argsKey]: { expiration: Date.now() + options.ttl, result },
    };
    localStorage.setItem(fn.name, JSON.stringify(cache));
  }

  return function () {
    // Note: JSON.stringify is non-deterministic,
    // consider something like json-stable-stringify to avoid extra cache misses

    const argsKey = JSON.stringify(arguments);

    if (
      !cache[fn.name] ||
      !cache[fn.name][argsKey] ||
      cache[fn.name][argsKey].expiration >= Date.now()
    ) {
      executeAndCacheFn(fn, arguments, argsKey);
      return cache[fn.name][argsKey].result;
    } else if (options.backgroundRefresh) {
      executeAndCacheFn(fn, arguments, argsKey);
      return cache[fn.name][argsKey].result;
    }
    console.log("Using cached", argsKey);

    return cache[fn.name][argsKey].result;
  };
}

async function wait(ms = 1) {
  await new Promise((resolve) => setTimeout(resolve, ms));
}

function clearStorage() {
  const cache = JSON.parse(localStorage.getItem("get_ipa_no_cache") || "{}");
  cache["get_ipa_no_cache"] = "";
  localStorage.setItem("get_ipa_no_cache", JSON.stringify(cache));
}

function get_ipa_no_cache(text, args) {
  console.log("doing actual IPA", text, args);
  const cleanText = sanitize(text);

  const [lang, langStyle, langForm] = args.split(";");
  let command = "";

  switch (lang) {
    case "Latin":
      switch (langStyle) {
        case "Ecclesiastical":
          command =
            langForm === "Phonetic"
              ? `window.la_ipa.convert_words("${cleanText}",true,true,false)`
              : `window.la_ipa.convert_words("${cleanText}",false,true,false)`;
          break;
        case "Classical":
          command =
            langForm === "Phonetic"
              ? `window.la_ipa.convert_words("${cleanText}",true,false,false)`
              : `window.la_ipa.convert_words("${cleanText}",false,false,false)`;
          break;
        case "Vulgar":
          command =
            langForm === "Phonetic"
              ? `window.la_ipa.convert_words("${cleanText}",true,false,true)`
              : `window.la_ipa.convert_words("${cleanText}",false,false,true)`;
          break;
      }
      break;
    case "German":
      if (langForm === "Phonemic") {
        let dictRecord = globalThis.lexicon.get(
          cleanText.replace(/[^\p{Letter}\p{Mark}-]+/gu, ""),
        );
        if (!dictRecord) {
          dictRecord = globalThis.lexicon.get(
            cleanText.replace(/[^\p{Letter}\p{Mark}-]+/gu, "").toLowerCase(),
          );
        }
        console.log(cleanText, dictRecord);
        if (dictRecord) {
          command = 'ipa="' + dictRecord + '";';
          break;
        }
      }
      command =
        langForm === "Phonetic"
          ? `(window.de_ipa.phonetic("${cleanText}"))`
          : `(window.de_ipa.phonemic("${cleanText}"))`;
      break;
    case "Portuguese":
      command =
        langStyle === "Brazil"
          ? `window.pt_ipa.IPA("${cleanText}","rio")[0].${langForm.toLowerCase()}`
          : `window.pt_ipa.IPA("${cleanText}","pt")[0].${langForm.toLowerCase()}`;
      break;
    case "Spanish":
      const dialect =
        langStyle === "Castilian" ? "distincion-yeismo" : "seseo-yeismo";
      command = `window.es_ipa.IPA("${cleanText}","${dialect}", ${
        langForm === "Phonetic"
      }).text`;
      break;
    case "French":
      if (langForm === "Phonemic") {
        command = `(window.fr_ipa.show("${cleanText}")[0])`;
      }
      break;
    case "Ukrainian":
      if (langForm === "Phonetic") {
        command = `(window.uk_ipa.pronunciation("${cleanText}",true))`;
      }
      break;
    case "Russian":
      if (langForm === "Phonetic") {
        command = `(window.ru_ipa.ipa_string("${cleanText}"))`;
      }
      break;
    case "Italian":
      if (langForm === "Phonemic") {
        command = `(window.it_ipa.to_phonemic("${cleanText}",'TEST').phonemic)`;
      }
      break;
    case "Greek":
      switch (langStyle) {
        case "5th BCE Attic":
          command = `window.grc_ipa.IPA("${cleanText}",'cla').cla.IPA`;
          break;
        case "1st CE Egyptian":
          command = `window.grc_ipa.IPA("${cleanText}",'koi1').koi1.IPA`;
          break;
        case "4th CE Koine":
          command = `window.grc_ipa.IPA("${cleanText}",'koi2').koi2.IPA`;
          break;
        case "10th CE Byzantine":
          command = `window.grc_ipa.IPA("${cleanText}",'byz1').byz1.IPA`;
          break;
        case "15th CE Constantinopolitan":
          command = `window.grc_ipa.IPA("${cleanText}",'byz2').byz2.IPA`;
          break;
      }
      break;

    case "Polish":
      if (langForm === "Phonemic") {
        command = `(window.pl_ipa.convert_to_IPA("${cleanText}"))`;
      }
      break;
  }

  let ipa = "";
  try {
    ipa = eval(command);
    console.log(command, ipa);
  } catch (err) {
    ipa = "";
    console.log(err);
  }

  if (!ipa) {
    return { value: text, status: "error" };
  }

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
    loadJs("./scripts/jszip.min.js", async () => {
      await loadJs("./scripts/jszip-utils.min.js", async () => {
        let data;
        if (!(typeof zipPathOrBlob === "string")) {
          console.log("blob", zipPathOrBlob);
          data = await zipPathOrBlob.blob();
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

async function fetchWithCache(url) {
  console.log("reading cache", url);
  const cachedResponse = await localforage.getItem(url);
  if (cachedResponse) {
    console.log("reading from cache", url);
    if (cachedResponse instanceof Blob) {
      const response = new Response(cachedResponse);
      response.headers.set("X-From-Cache", "true");
      console.log("Returned cached blob ", url);
      return response;
    }
    const response = new Response(JSON.parse(cachedResponse));
    response.headers.set("X-From-Cache", "true");
    console.log("Returned cached string ", url);
    return response;
  }
  console.log("caching ", url);
  const response = await fetch(url);

  const contentType = response.headers.get("content-type");
  let responseContent;
  let responseWithHeaders;

  if (contentType == "application/zip") {
    const responseContent = await response.blob();
    await localforage.setItem(url, responseContent);
  } else {
    responseContent = await response.text();
    await localforage.setItem(url, JSON.stringify(responseContent));
  }
  responseWithHeaders = new Response(responseContent, response);
  return responseWithHeaders;
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
};
