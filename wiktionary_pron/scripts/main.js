const factory = await lb.factory;
const lua = await factory.createEngine();

// Set a JS function to be a global lua function
lua.global.set("fetch", (url) => fetch(url));

async function mountFile(file_path, lua_path) {
  const x = await fetch(file_path).then((data) => data.text());
  await factory.mountFile(lua_path, x);
}

await mountFile("../wiktionary_pron/modules/memoize.lua", "memoize.lua");

await lua.doString(`
          memoize = require('memoize')
          function require(path, extension)
              extension = extension or 'lua'
              print('required '..path,'from:', debug.getinfo(2).name)
              if select(2,string.gsub(path, "%.", "")) > 0 then
                   new_path = string.gsub(path,"%.", "/",1)
                   print('replacing ', path,'->', new_path)
                   path = new_path
              end
              local resp = fetch(string.format('../wiktionary_pron/modules/%s.%s',path,extension) ):await()
              local text = resp:text():await()
              local module =  load(text)()
              print('loaded '..path)
              return module
          end

          require = memoize(require)
          require('debug/track')
          require('ustring/charsets')
          require('ustring/lower')
          require('mw-title')
          mw = require('mw')
        `);
console.log(lua);
window.lua = lua;
document.querySelector("#lang").disabled = false;

async function loadLanguage(code) {
  const lua = window.lua;
  console.log(lua);
  await lua.doString(`${code} = require("${code}-pron_wasm")`);
  // Get a global lua function as a JS function
  window[code + "_ipa"] = lua.global.get(code);

  // Set a JS function to be a global lua function
}

function sanitize(text) {
  return text.replace(/[^\p{L}\p{M}]/gu, "");
}

function prepareTranscribe() {
  const inputText = document.getElementById("text_to_transcribe").value;
  const textLines = inputText.split("\n");
  const resultDiv = document.getElementById("result");
  resultDiv.innerHTML = "";
  return [resultDiv, textLines];
}

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

async function wait(ms = 1) {
  await new Promise((resolve) => setTimeout(resolve, ms));
}

/**
 * Transcribes the text and shows the result in the result div based on the selected presentation mode.
 * @param {string} mode - The mode for transcribing the text (default, line, column).
 */
async function transcribe(mode) {
  disableAll();
  try {
    const [resultDiv, textLines] = prepareTranscribe();
    const { lang, langStyle, langForm } = getLangStyleForm();

    async function processDefault(line) {
      const words = line.split(" ");
      resultDiv.insertAdjacentHTML("beforeend", "</br>");

      async function processWord(word) {
        const { status, value } = await getIpa(word, lang, langStyle, langForm);
        const span = document.createElement("span");
        span.className = status === "error" ? "error" : "";
        span.appendChild(document.createTextNode(value + " "));
        resultDiv.appendChild(span);
      }

      await Promise.all(
        words.map(async (word) => {
          await wait(1);
          await processWord(word);
        }),
      );
    }

    async function processLine(line) {
      const words = line.split(" ");
      const results = await Promise.all(
        words.map(async (word) => {
          await wait(1);
          return await getIpa(word, lang, langStyle, langForm);
        }),
      );

      const formattedResults = results.map((result) =>
        result.status === "error"
          ? `<div class="error">${result.value} </div>`
          : `<div class="ipa">${result.value} </div>`,
      );

      const newRow = resultDiv.insertRow(-1);
      const formattedWords = words.map(
        (word) => `<div class="input_text">${word} </div>`,
      );
      const combinedResults = formattedResults.map(
        (formattedResult, index) =>
          '<div style="float:left;margin-left:5px;margin-top:5px;">' +
          formattedWords[index] +
          formattedResult +
          "</div>",
      );
      combinedResults
        .reverse()
        .map((r) => newRow.insertAdjacentHTML("afterbegin", r));
    }

    async function processColumn(line) {
      const words = line.split(" ");
      const results = await Promise.all(
        words.map(async (word) => {
          await wait(1);
          return await getIpa(word, lang, langStyle, langForm);
        }),
      );

      const formattedResults = results.map((result) =>
        result.status === "error"
          ? `<td class="error">${result.value} </td>`
          : `<td class="ipa">${result.value} </td>`,
      );

      function insertRow(div, cells) {
        const row = resultDiv.insertRow(-1);
        cells.forEach((cell) => {
          const newCell = row.insertCell(-1);
          newCell.outerHTML = cell;
        });
      }

      const inputTextCells = words.map(
        (word) => `<td class="input_text">${word} </td>`,
      );
      formattedResults.forEach((formattedResult, index) =>
        insertRow(resultDiv, [inputTextCells[index], formattedResult]),
      );
    }

    let selectedProcess;
    switch (mode) {
      case "default":
        selectedProcess = processDefault;
        break;
      case "line":
        selectedProcess = processLine;
        break;
      case "column":
        selectedProcess = processColumn;
        break;
    }

    console.time();
    await asyncMapStrict(textLines, selectedProcess);
    console.timeEnd();
    console.log("finished");
  } catch (err) {
    console.log(err);
  } finally {
    console.log("finally");
    enableAll();
  }
}

/**
 * Disables all form elements on the page
 */
function disableAll() {
  // Select all the forms on the page
  const forms = Array.from(document.querySelectorAll("form"));

  // Iterate through each form and disable all its elements
  forms.forEach((form) => {
    Array.from(form.elements).forEach((element) => {
      element.disabled = true;
    });
  });
}

function enableAll() {
  // Get all the form elements on the page
  const forms = Array.from(document.querySelectorAll("form"));
  forms.forEach((form) => {
    // Enable all elements in the form
    Array.from(form.elements).forEach((element) => {
      element.disabled = false;
    });
  });
}

var form = document.getElementById("frm1");

document
  .getElementById("submit")
  .addEventListener("click", () => transcribe("default"));
document
  .getElementById("submit_by_line")
  .addEventListener("click", () => transcribe("line"));
document
  .getElementById("submit_by_col")
  .addEventListener("click", () => transcribe("column"));

document.getElementById("clear_button").addEventListener("click", clear_input);

document
  .getElementById("clear_storage")
  .addEventListener("click", clear_storage);

function clear_storage() {
  const cache = JSON.parse(localStorage.getItem("get_ipa_no_cache") || "{}");
  cache["get_ipa_no_cache"] = "";
  localStorage.setItem("get_ipa_no_cache", JSON.stringify(cache));
}

function clear_input() {
  i = document.getElementById("text_to_transcribe");
  i.value = "";
}

/**
 * Retrieves the language, style, and form data from the DOM
 * @returns {Object} An object containing the language, language style, and language form data
 */
function getLangStyleForm() {
  const lang = document.querySelector("#lang").value;
  const langStyle = document.querySelector("#lang_style").value;
  const langForm = document.querySelector("#lang_form").value;

  return { lang, langStyle, langForm };
}

/**
 * Retrieve the International Phonetic Alphabet (IPA) for the given text in the specified language.
 *
 * @param {string} text - The input text for which IPA needs to be retrieved.
 * @param {string} lang - The language of the input text.
 * @param {string} lang_style - The style (dialect) of the language.
 * @param {string} lang_form - The form (phonetic or phonemic) of the transcription.
 * @returns {string} - The IPA representation of the input text.
 */
function getIpa(text, lang, lang_style, lang_form) {
  // Concatenate the language, style, and form parameters
  let args = lang + ";" + lang_style + ";" + lang_form;
  // Call memoized get_ipa_cache function to retrieve the IPA representation
  return get_ipa_cache(text, args);
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

  const split = text.split(/([\p{L}\p{M}]+)/gu);
  const indexInSplit = split.findIndex((x) => x === cleanText);

  split[indexInSplit] = ipa;

  if (!ipa) {
    return { value: text, status: "error" };
  }

  ipa = split.join("");
  return { value: ipa, status: "success" };
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

const get_ipa_cache = memoizeLocalStorage(get_ipa_no_cache);

const languages = {
  Latin: {
    styles: ["Classical", "Ecc"],
    forms: ["Phonetic", "Phonemic"],
    langCode: "la",
  },
  German: {
    styles: ["Default"],
    forms: ["Phonetic", "Phonemic"],
    langCode: "de",
  },
  Portuguese: {
    styles: ["Brazil", "Portugal"],
    forms: ["Phonetic", "Phonemic"],
    langCode: "pt",
  },
  Spanish: {
    styles: ["Castilian", "Latin_American "],
    forms: ["Phonetic", "Phonemic"],
    langCode: "es",
  },
  French: { styles: ["Default"], forms: ["Phonemic"], langCode: "fr" },
  Russian: { styles: ["Default"], forms: ["Phonetic"], langCode: "ru" },
  Polish: { styles: ["Default"], forms: ["Phonemic"], langCode: "pl" },

  Ukrainian: { styles: ["Default"], forms: ["Phonetic"], langCode: "uk" },
  Greek: {
    styles: [
      "5th BCE Attic",
      "1st CE Egyptian",
      "4th CE Koine",
      "10th CE Byzantine",
      "15th CE Constantinopolitan",
    ],
    forms: ["Phonetic"],
    langCode: "grc",
  },
};

var sel1 = document.querySelector("#lang");
var sel2 = document.querySelector("#lang_style");
var sel3 = document.querySelector("#lang_form");
Object.entries(languages).map(function (args) {
  var lang = args[0];
  var opt = document.createElement("option");
  opt.value = lang;
  opt.text = lang;
  sel1.appendChild(opt);

  for (var i = 0; i < args[1].styles.length; i++) {
    var opt = document.createElement("option");
    opt.setAttribute("data-option", lang);
    opt.text = args[1].styles[i];
    sel2.appendChild(opt);
  }
  for (var i = 0; i < args[1].forms.length; i++) {
    var opt = document.createElement("option");
    opt.setAttribute("data-option", lang);
    opt.text = args[1].forms[i];
    sel3.appendChild(opt);
  }
});
var options2 = sel2.querySelectorAll("option");
var options3 = sel3.querySelectorAll("option");

const loadedLanguages = {};

async function giveSelection(selValue) {
  selValue = this.value;
  if (!(selValue in loadedLanguages)) {
    const langCode = languages[selValue].langCode;
    disableAll();
    await loadLanguage(langCode);
    enableAll();
    loadedLanguages[selValue] = true;
  }

  sel2.innerHTML = "";
  for (const option of options2) {
    if (option.dataset.option === selValue) {
      sel2.appendChild(option);
    }
  }
  sel2.disabled = false;

  sel3.innerHTML = "";
  for (const option of options3) {
    if (option.dataset.option === selValue) {
      sel3.appendChild(option);
    }
  }
  sel3.disabled = false;
}
document.getElementById("lang").addEventListener("change", giveSelection);
