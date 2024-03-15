import "./lua_init.js";
import {
  asyncMapStrict,
  clearStorage,
  get_ipa_no_cache,
  wait,
} from "./utils.js";
import { tts } from "./tts.js";
document.querySelector("#lang").disabled = false;

function prepareTranscribe() {
  const inputText = document.getElementById("text_to_transcribe").value;
  const textLines = inputText.split("\n");
  const resultDiv = document.getElementById("result");
  resultDiv.innerHTML = "";
  return [resultDiv, textLines];
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
          '<div class="cell"style="float:left;margin-left:5px;margin-top:5px;"><button class="fa fa-volume-down audio-popup"></button>' +
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

    async function processSideBySide(paragraph) {
      const words = paragraph.split(" ");
      const results = await Promise.all(
        words.map(async (word) => {
          await wait(1);
          return await getIpa(word, lang, langStyle, langForm);
        }),
      );

      const container = document.createElement("div");
      container.style.display = "flex";
      container.style.alignContent = "center";
      container.style.maxWidth = "1000px";
      container.style.marginLeft = "auto";
      container.style.marginRight = "auto";

      const leftColumn = document.createElement("div");
      leftColumn.style.flex = "1";

      const rightColumn = document.createElement("div");
      rightColumn.style.flex = "1";

      for (let i = 0; i < words.length; i++) {
        const wordSpan = document.createElement("span");
        wordSpan.textContent = words[i];
        wordSpan.classList.add("input_text", "word");
        wordSpan.style.display = "inline-block";

        const resultSpan = document.createElement("span");
        resultSpan.textContent = results[i].value;
        resultSpan.classList.add(
          results[i].status === "error" ? "error" : "ipa",
        );
        resultSpan.style.display = "inline-block";

        leftColumn.appendChild(wordSpan);
        rightColumn.appendChild(resultSpan);
      }

      container.appendChild(leftColumn);
      container.appendChild(rightColumn);
      resultDiv.appendChild(document.createElement("br"));
      resultDiv.appendChild(container);
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
      case "sideBySide":
        selectedProcess = processSideBySide;
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
    tts();
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
  .addEventListener("click", () => transcribe("sideBySide"));

document.getElementById("clear_button").addEventListener("click", clear_input);

document
  .getElementById("clear_storage")
  .addEventListener("click", clearStorage);

function clear_input() {
  const form = document.getElementById("text_to_transcribe");
  form.value = "";
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
