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
  return text.replace(
    /[^\p{L}\p{M}'pbtdʈɖcɟkɡqɢʔmɱnɳɲŋɴʙrʀⱱɾɽɸβfvθðszʃʒʂʐçʝxɣχʁħʕhɦɬɮʋɹɻjɰlɭʎʟʘǀǃǂǁɓɗʄɠʛʼiyɨʉɯuɪʏʊeøɘɵɤoəɛœɜɞʌɔæɐaɶɑɒʍwɥʜʢʡɕʑɺɧ͜͡ˈˌːˑ̆|‖.‿̥̬ʰ̹̜̟̠̩̯̈̽˞̤̰̼ʷʲˠˤ̴̝̞̘̙̪̺̻̃ⁿˡ̋̚˥̌˩́˦̂̄˧᷄̀˨᷅̏᷈-]/gu,
    "",
  );
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
        case "Ecc":
          command =
            langForm === "Phonetic"
              ? `window.la_ipa.convert_words('${cleanText}',true,true,false)`
              : `window.la_ipa.convert_words('${cleanText}',false,true,false)`;
          break;
        case "Classical":
          command =
            langForm === "Phonetic"
              ? `window.la_ipa.convert_words('${cleanText}',true,false,false)`
              : `window.la_ipa.convert_words('${cleanText}',false,false,false)`;
          break;
      }
      break;
    case "German":
      command =
        langForm === "Phonetic"
          ? `(window.de_ipa.phonetic('${cleanText}'))`
          : `(window.de_ipa.phonemic('${cleanText}'))`;
      break;
    case "Portuguese":
      command =
        langStyle === "Brazil"
          ? `window.pt_ipa.IPA('${cleanText}',"rio")[0].${langForm.toLowerCase()}`
          : `window.pt_ipa.IPA('${cleanText}',"pt")[0].${langForm.toLowerCase()}`;
      break;
    case "Spanish":
      const dialect =
        langStyle === "Castilian" ? "distincion-yeismo" : "seseo-yeismo";
      command = `window.es_ipa.IPA('${cleanText}','${dialect}', ${
        langForm === "Phonetic"
      }).text`;
      break;
    case "French":
      if (langForm === "Phonemic") {
        command = `(window.fr_ipa.show('${cleanText}')[0])`;
      }
      break;
    case "Ukrainian":
      if (langForm === "Phonetic") {
        command = `(window.uk_ipa.pronunciation('${cleanText}',true))`;
      }
      break;
    case "Russian":
      if (langForm === "Phonetic") {
        command = `(window.ru_ipa.ipa_string('${cleanText}'))`;
      }
      break;
    case "Italian":
      if (langForm === "Phonemic") {
        command = `(window.it_ipa.to_phonemic('${cleanText}','TEST').phonemic)`;
      }
      break;
    case "Greek":
      switch (langStyle) {
        case "5th BCE Attic":
          command = `window.grc_ipa.IPA('${cleanText}','cla').cla.IPA`;
          break;
        case "1st CE Egyptian":
          command = `window.grc_ipa.IPA('${cleanText}','koi1').koi1.IPA`;
          break;
        case "4th CE Koine":
          command = `window.grc_ipa.IPA('${cleanText}','koi2').koi2.IPA`;
          break;
        case "10th CE Byzantine":
          command = `window.grc_ipa.IPA('${cleanText}','byz1').byz1.IPA`;
          break;
        case "15th CE Constantinopolitan":
          command = `window.grc_ipa.IPA('${cleanText}','byz2').byz2.IPA`;
          break;
      }
      break;

    case "Polish":
      if (langForm === "Phonemic") {
        command = `(window.pl_ipa.convert_to_IPA('${cleanText}'))`;
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

export {
  asyncMapStrict,
  sanitize,
  clearStorage,
  wait,
  get_ipa_no_cache,
  memoizeLocalStorage,
};
