import { loadLanguage } from "./lua_init.js";

import {
  asyncMapStrict,
  clearStorage,
  get_ipa_no_cache,
  memoizeLocalStorage,
  wait,
} from "./utils.js";
import { tts } from "./tts.js";
import { toPdf } from "./pdf_export.js";

document.querySelector("#lang").disabled = false;

function prepareTranscribe() {
  const inputText = document.getElementById("text_to_transcribe").value;
  const textLines = inputText.trim().split("\n");
  const resultDiv = document.getElementById("result");
  resultDiv.innerHTML = "";
  return [resultDiv, textLines];
}

const get_ipa_cache = memoizeLocalStorage(get_ipa_no_cache);

/**
 * Retrieve the International Phonetic Alphabet (IPA) for the given text in the specified language.
 *
 * @param {string} text - The input text for which IPA needs to be retrieved.
 * @param {string} lang - The language of the input text.
 * @param {string} lang_style - The style (dialect) of the language.
 * @param {string} lang_form - The form (phonetic or phonemic) of the transcription.
 * @return {object} An object containing the IPA representation and the status of the conversion
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
  disableAll([document.querySelector("#export_pdf")]);
  const [resultDiv, textLines] = prepareTranscribe();
  const { lang, langStyle, langForm } = getLangStyleForm();
  try {
    async function processDefault(line) {
      const words = line.split(" ").concat(["\n"]);

      const container = document.createElement("tr");
      resultDiv.appendChild(container);

      async function processWord(word) {
        console.log("processing", word);
        const { status, value } = await getIpa(word, lang, langStyle, langForm);
        const div = document.createElement("div");
        div.className = "cell";

        const span = document.createElement("span");
        const ttsButton = document.createElement("button");
        ttsButton.className = "fa fa-volume-down audio-popup";
        div.appendChild(ttsButton);
        span.className = status === "error" ? "error" : "";
        span.setAttribute("data-word", word);

        span.appendChild(document.createTextNode(value + " "));

        div.appendChild(span);
        if (word.includes("\n")) {
          div.appendChild(document.createElement("br"));
        }
        container.appendChild(div);
      }

      await Promise.all(
        words.map(async (word) => {
          await wait(1);
          await processWord(word);
        }),
      );
    }

    async function processLine(line) {
      if (line === "") {
        return;
      }
      const words = line.split(" ");

      const results = await Promise.all(
        words.map(async (word) => {
          await wait(1);
          const ipa = getIpa(word, lang, langStyle, langForm);
          return { word, ipa };
        }),
      );
      window.x = results;
      const formattedResults = results.map(({ ipa }) =>
        result.status === "error"
          ? `<div class="error">${ipa.value} </div>`
          : `<div class="ipa">${ipa.value} </div>`,
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

      const container = document.createElement("tr");
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
        const wordDiv = document.createElement("div");
        wordDiv.className = "cell";
        const wordSpan = document.createElement("span");
        wordSpan.textContent = words[i];
        wordSpan.classList.add("input_text");
        wordSpan.style.display = "inline-block";
        const ttsWordButton = document.createElement("button");
        ttsWordButton.className = "fa fa-volume-down audio-popup";
        wordDiv.appendChild(ttsWordButton);
        wordDiv.appendChild(wordSpan);

        const resultDiv = document.createElement("div");
        resultDiv.className = "cell";
        const resultSpan = document.createElement("span");
        resultSpan.textContent = results[i].value;
        resultSpan.setAttribute("data-word", words[i]);
        resultSpan.classList.add(
          results[i].status === "error" ? "error" : "ipa",
        );
        resultSpan.style.display = "inline-block";
        const ttsResultButton = document.createElement("button");
        ttsResultButton.className = "fa fa-volume-down audio-popup";

        resultDiv.appendChild(ttsResultButton);
        resultDiv.appendChild(resultSpan);

        leftColumn.appendChild(wordDiv);
        rightColumn.appendChild(resultDiv);
      }

      container.appendChild(leftColumn);
      container.appendChild(rightColumn);

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
    globalThis.transcriptionMode = mode;
    globalThis.transcriptionLang = lang;
    enableAll([document.querySelector("#export_pdf")]);
    tts(transcriptionMode);
  }
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
    styles: ["Classical", "Ecclesiastical", "Vulgar"],
    forms: ["Phonetic", "Phonemic"],
    langCode: "la",
    ttsCode: "it-IT",
  },
  German: {
    styles: ["Default"],
    forms: ["Phonetic", "Phonemic"],
    langCode: "de",
    ttsCode: "de-DE",
  },
  Portuguese: {
    styles: ["Brazil", "Portugal"],
    forms: ["Phonetic", "Phonemic"],
    langCode: "pt",
    ttsCode: "pt-BR",
  },
  Spanish: {
    styles: ["Castilian", "Latin_American "],
    forms: ["Phonetic", "Phonemic"],
    langCode: "es",
    ttsCode: "es-ES",
  },
  French: {
    styles: ["Default"],
    forms: ["Phonemic"],
    langCode: "fr",
    ttsCode: "fr-FR",
  },
  Russian: {
    styles: ["Default"],
    forms: ["Phonetic"],
    langCode: "ru",
    ttsCode: "ru-RU",
  },
  Polish: {
    styles: ["Default"],
    forms: ["Phonemic"],
    langCode: "pl",
    ttsCode: "pl-PL",
  },

  Ukrainian: {
    styles: ["Default"],
    forms: ["Phonetic"],
    langCode: "uk",
    ttsCode: "uk-UA",
  },
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
    ttsCode: "el-GR",
  },
};

const langSelect = document.querySelector("#lang");
const styleSelect = document.querySelector("#lang_style");
const formSelect = document.querySelector("#lang_form");

Object.entries(languages).forEach(function ([lang, details]) {
  const langOption = document.createElement("option");
  langOption.value = lang;
  langOption.text = lang;
  langSelect.appendChild(langOption);

  details.styles.forEach(function (style) {
    const styleOption = document.createElement("option");
    styleOption.setAttribute("data-option", lang);
    styleOption.text = style;
    styleSelect.appendChild(styleOption);
  });

  details.forms.forEach(function (form) {
    const formOption = document.createElement("option");
    formOption.setAttribute("data-option", lang);
    formOption.text = form;
    formSelect.appendChild(formOption);
  });
});

const styleOptions = styleSelect.querySelectorAll("option");
const formOptions = formSelect.querySelectorAll("option");

const loadedLanguages = {};

async function updateOptionsUponLanguageSelection(event) {
  const selectedLanguageElement = event.target;
  const selectedLanguage = selectedLanguageElement.value;
  const lang = languages[selectedLanguage];

  if (!(selectedLanguage in loadedLanguages)) {
    disableAll();
    await loadLanguage(lang.langCode);
    enableAll();
    loadedLanguages[selectedLanguage] = true;
  }

  selectTTS(lang.ttsCode);

  function updateSelectOptions(selectedValue, selectElement, options) {
    selectElement.innerHTML = "";
    for (const option of options) {
      if (option.dataset.option === selectedValue) {
        selectElement.appendChild(option);
      }
    }
    selectElement.disabled = false;
    selectElement.selectedIndex = 0;
  }

  updateSelectOptions(selectedLanguage, styleSelect, styleOptions);
  updateSelectOptions(selectedLanguage, formSelect, formOptions);
}

function selectTTS(language) {
  const voices = Array.from(document.querySelector("#tts").options);
  const relevantVoices = voices.filter((option) =>
    (option.getAttribute("data-lang") || "").includes(language),
  );

  if (relevantVoices.length > 0) {
    document.querySelector("#tts").value = relevantVoices[0].value;
  }
}

const isDarkMode = () => document.body.classList.contains("dark_mode");

document
  .getElementById("lang")
  .addEventListener("change", updateOptionsUponLanguageSelection);

async function pdfExport(event) {
  const buttonElement = event.currentTarget;
  const iconElement = buttonElement.querySelector("i");

  buttonElement.disabled = true;
  const oldIconClass = iconElement.className;
  iconElement.className = "fa fa-spinner fa-spin";

  await toPdf(
    globalThis.transcriptionMode,
    isDarkMode(),
    globalThis.transcriptionLang,
  );

  iconElement.className = oldIconClass;
  buttonElement.disabled = false;
}

document.getElementById("export_pdf").addEventListener("click", pdfExport);

function toggleDarkMode() {
  console.log("setting dark");
  if (document.body.classList.contains("dark_mode")) {
    console.log("dark already setting light");
    toggleLightMode();
  } else {
    document.body.classList.add("dark_mode");
    document.querySelector("#header > a > i").className = "fa fa-sun-o";
  }
}

function toggleLightMode() {
  document.querySelector("#header>a>i").className = "fa fa-moon-o";
  document.body.classList.remove("dark_mode");
}

document.getElementById("dark_mode").addEventListener("click", toggleDarkMode);
