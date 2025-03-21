import "./dynamic_meta.js";
import { languages } from "./languages.js";
import { loadLanguage } from "./lua_init.js";

import {
  asyncMapStrict,
  clearStorage,
  createElementFromHTML,
  disableAll,
  enableAll,
  get_ipa_no_cache,
  memoizeLocalStorage,
  translateWithFallbackCached,
  updateLoadingText,
  wait,
} from "./utils.js";
import { tts } from "./tts.js";
import { toPdf } from "./pdf_export.js";
import { toCsv } from "./csv_export.js";
import { loadLexicon } from "./lexicon.js";
import { macronize } from "./macronizer.js";

document.querySelector("#lang").disabled = false;

async function prepareTranscribe(lang, inputText) {
  if (lang === "Latin") {
    try {
      inputText = await macronize(inputText);
    } catch (e) {
      console.error(e);
      console.warn("Failed to macronize text");
    }
  }
  const textLines = inputText.trim().split("\n");
  const resultDiv = document.getElementById("result");
  resultDiv.innerHTML = "";
  return [resultDiv, textLines];
}

const get_ipa_cache = memoizeLocalStorage(get_ipa_no_cache, {
  ttl: 7 * 24 * 60 * 60 * 1000, // 7*24 hours
  backgroundRefresh: true,
  debug: true,
});

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
async function transcribe(mode, translate = false, inputText = null) {
  disableAll([
    document.querySelector("#export_pdf"),
    document.querySelector("#export_csv"),
  ]);
  const { lang, langStyle, langForm } = getLangStyleForm();
  console.log(1111111111111111, lang, langStyle, langForm);
  const [resultDiv, textLines] = await prepareTranscribe(
    lang,
    inputText || document.getElementById("text_to_transcribe").value,
  );
  console.log(textLines);
  try {
    async function processDefault(line) {
      const words = line.split(" ").concat(["\n"]);

      const container = document.createElement("tr");
      container.className = "line";
      resultDiv.appendChild(container);

      const ttsButton = document.createElement("button");

      ttsButton.className = "audio-popup-line";
      const audioButton = document.createElement("i");
      audioButton.className = "icon icon-volume";
      ttsButton.appendChild(audioButton);

      container.prepend(ttsButton);

      async function processWord(word) {
        console.log("processing", word);
        let { status, value } = await getIpa(word, lang, langStyle, langForm);
        let values = "";
        if (lang === "German") {
          [value, values] = processGermanIpa(value);
        }

        const div = document.createElement("div");
        div.className = "cell";

        const ttsButton = document.createElement("button");
        ttsButton.className = "audio-popup";
        const audioButton = document.createElement("i");
        audioButton.className = "icon icon-volume ";
        ttsButton.appendChild(audioButton);
        div.appendChild(ttsButton);

        let spanHTML = "";
        const spanClass = status === "error" ? "error" : "ipa";
        if (values !== "") {
          spanHTML = `<span class="${spanClass}" data-word="${word}" all_values="${values}">${value}  </span>`;
        } else {
          spanHTML = `<span class="${spanClass}" data-word="${word}">${value}  </span>`;
        }

        const span = createElementFromHTML(spanHTML);

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

    function processGermanIpa(value) {
      let values = "";
      if (value?.includes("/,")) {
        console.log(value);
        values = value.split("/,");
        values = values.map((value) => value.replace("/", "").replace("/", ""));
        value = values[0];
        values = values.join("&#xa;");
      }
      value = value.replace("/", "").replace("/", "");
      return [value, values];
    }

    async function processLine(line) {
      if (line === "") {
        return;
      }
      const words = line.split(" ");

      const results = await Promise.all(
        words.map(async (word) => {
          await wait(1);
          const ipa = await getIpa(word, lang, langStyle, langForm);
          return { word, ipa };
        }),
      );
      window.x = results;

      const formattedResults = results.map(({ ipa }) => {
        let values;
        let value;
        console.log(ipa.value);
        value = ipa.value;
        if (lang === "German" || lang === "Czech" || lang === "Lithuanian") {
          [value, values] = processGermanIpa(value);
        } else {
          values = "";
        }

        console.log(values);
        return ipa.status === "error"
          ? `<div class="error">${value} </div>`
          : Boolean(values)
          ? `<div class="ipa" all_values="${values}" content="${value}"></div>`
          : `<div class="ipa" content="${value}" ></div>`;
      });

      const newRow = resultDiv.insertRow(-1);
      newRow.className = "line";
      const formattedWords = words.map(
        (word) => `<div class="input_text">${word}</div>`,
      );
      const combinedResults = formattedResults.map(
        (formattedResult, index) =>
          '<div class="cell""><button class="audio-popup"><i class="icon icon-volume"></i></button>' +
          formattedWords[index] +
          formattedResult +
          "</div>",
      );
      combinedResults
        .reverse()
        .map((r) => newRow.insertAdjacentHTML("afterbegin", r));

      const ttsButton = document.createElement("button");
      const audioButton = document.createElement("i");
      ttsButton.className = "audio-popup-line";
      audioButton.className = "icon icon-volume";
      ttsButton.appendChild(audioButton);

      newRow.prepend(ttsButton);
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
      console.log("para", paragraph);
      let words = paragraph.split(" ");
      let results;
      if (!translate) {
        results = await Promise.all(
          words.map(async (word) => {
            await wait(1);
            return await getIpa(word, lang, langStyle, langForm);
          }),
        );
      } else {
        const result = await translateWithFallbackCached(
          paragraph,
          "auto",
          "en",
        );
        console.log(result);
        console.log(result.text);
        console.log(result.source);
        results = Array.from(result.text.split(" ")).map(function (x) {
          return { value: x, status: "success" };
        });
      }
      console.log(123, translate);
      console.log(345, results);
      const container = document.createElement("tr");
      container.style.display = "flex";
      container.style.alignContent = "center";
      container.style.maxWidth = "1000px";
      container.style.marginLeft = "auto";
      container.style.marginRight = "auto";

      const leftColumn = document.createElement("div");
      leftColumn.classList.add("left-column");

      const rightColumn = document.createElement("div");
      rightColumn.classList.add("right-column");

      for (let i = 0; i < Math.max(words.length, results.length); i++) {
        const wordDiv = document.createElement("div");
        wordDiv.className = "cell";
        const wordSpan = document.createElement("span");
        wordSpan.textContent = words[i];
        wordSpan.classList.add("input_text");
        wordSpan.style.display = "inline-block";
        const ttsWordButton = document.createElement("button");
        ttsWordButton.className = "audio-popup";
        const audioButton = document.createElement("i");
        audioButton.className = "icon icon-volume";
        ttsWordButton.appendChild(audioButton);
        wordDiv.appendChild(ttsWordButton);
        wordDiv.appendChild(wordSpan);

        const resultDiv = document.createElement("div");
        resultDiv.className = "cell";
        let value, values;

        if (lang === "German" || lang === "Czech") {
          [value, values] = processGermanIpa(results[i]?.value || "");
        } else {
          value = results[i]?.value;
          values = "";
        }

        const spanClass = results[i]?.status === "error" ? "error" : "ipa";
        let spanHTML = "";
        if (values) {
          spanHTML = `<span class="${spanClass}" style="display: inline-block" data-word="${words[i]}" all_values="${values}">${value}  </span>`;
        } else {
          spanHTML = `<span class="${spanClass}" style="display: inline-block" data-word="${words[i]}">${value}  </span>`;
        }
        const resultSpan = createElementFromHTML(spanHTML);
        const ttsResultButton = document.createElement("button");
        ttsResultButton.className = "audio-popup";
        const resultAudioButton = document.createElement("i");
        resultAudioButton.className = "icon icon-volume";
        ttsResultButton.appendChild(resultAudioButton);

        resultDiv.appendChild(ttsResultButton);
        resultDiv.appendChild(resultSpan);

        leftColumn.appendChild(wordDiv);

        rightColumn.appendChild(resultDiv);
      }
      if (!(paragraph.trim() === "")) {
        const leftTTSButton = document.createElement("button");
        leftTTSButton.className = "audio-popup-line";

        const leftAudioButton = document.createElement("i");
        leftAudioButton.className = "icon icon-volume";
        leftTTSButton.appendChild(leftAudioButton);

        leftColumn.prepend(leftTTSButton);

        const rightTTSButton = document.createElement("button");
        rightTTSButton.className = "audio-popup-line";
        const rightAudioButton = document.createElement("i");
        rightAudioButton.className = "icon icon-volume";
        rightTTSButton.appendChild(rightAudioButton);
        rightColumn.prepend(rightTTSButton);
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
    if (lang === "German" || lang === "Czech" || lang === "Lituanian") {
      Array.from(document.querySelectorAll(".ipa")).map((x) => {
        if (
          Boolean(x.getAttribute("all_values")) &&
          x.getAttribute("all_values").trim() !== ""
        ) {
          x.classList.add("multiple-values");
        }
        x.addEventListener("click", (event) => {
          const current = event.target;

          const all_values = current.getAttribute("all_values");
          if (all_values === "") {
            return;
          }
          const c = event.target.textContent;

          function cycle(all_values, current) {
            const split = all_values.split("\n");
            if (split.length > 1) {
              const index = split.indexOf(current.trim());
              if (index === split.length - 1) {
                return split[0];
              } else {
                return split[index + 1];
              }
            }
          }

          const new_value = cycle(all_values, c);
          if (mode === "line") {
            event.target.setAttribute("content", new_value);
          } else {
            event.target.textContent = new_value;
          }
          current.setAttribute("all_values", all_values);
        });
      });
    }

    globalThis.transcriptionMode = mode;
    globalThis.transcriptionLang = lang;
    enableAll([
      document.querySelector("#export_pdf"),
      document.querySelector("#export_csv"),
    ]);
    tts(transcriptionMode);
  }
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

document
  .getElementById("translate_by_col")
  .addEventListener("click", async function () {
    return transcribe("sideBySide", true);
  });

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
 * @returns {Object} An object containing the language, language style, and language form values.
 */
function getLangStyleForm() {
  const lang = document.querySelector("#lang").value;
  const langStyle = document.querySelector("#lang_style").value;
  const langForm = document.querySelector("#lang_form").value;

  return { lang, langStyle, langForm };
}

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
globalThis.lexicon = {};

async function updateOptionsUponLanguageSelection(event) {
  const selectedLanguageElement = event.target;
  const selectedLanguage = selectedLanguageElement.value;
  const lang = languages[selectedLanguage];
  const urlParams = new URLSearchParams(window.location.search);
  let useDictionary = urlParams.get("dict");
  if (useDictionary === null) {
    useDictionary = "true";
  }
  console.log("changing language to ", selectedLanguage);
  try {
    if (urlParams.get("lang") !== selectedLanguage) {
      window.history.pushState({}, "", `?lang=${selectedLanguage}`);
    }
  } catch (err) {
    console.log(err);
  }
  if (!(selectedLanguage in loadedLanguages)) {
    disableAll();
    await loadLanguage(lang.langCode);

    if (selectedLanguage === "Latin") {
      updateLoadingText("Macrons list", "");
      try {
        await macronize("");
      } catch (err) {
        console.log(err);
        console.log("Failed to load macrons list");
      }
      updateLoadingText("", "");
    }

    if (selectedLanguage === "German" && useDictionary === "true") {
      updateLoadingText("German lexicon", "");
      globalThis.lexicon["German"] = await loadLexicon("German");
      updateLoadingText("", "");
    }
    if (selectedLanguage === "Czech" && useDictionary === "true") {
      updateLoadingText("Czech lexicon", "");
      globalThis.lexicon["Czech"] = await loadLexicon("Czech");
      updateLoadingText("", "");
    }
    if (selectedLanguage === "French" && useDictionary === "true") {
      updateLoadingText("French lexicon", "");
      globalThis.lexicon["French"] = await loadLexicon("French");
      updateLoadingText("", "");
    }

    if (selectedLanguage === "Lithuanian" && useDictionary === "true") {
      updateLoadingText("Lithuanian lexicon", "");
      globalThis.lexicon["Lithuanian"] = await loadLexicon("Lithuanian");
      updateLoadingText("", "");
    }
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

  document.title = `Online ${selectedLanguage} IPA transcription`;
  const availableStyles = lang.styles.join(", ");
  const availableForms = lang.forms.map((form) => form.toLowerCase()).join("/");
  document.head.children.description.content = `Online ${selectedLanguage} to IPA ${availableForms} transcription generator. Dialects: ${availableStyles}`;

  console.log("Finished changing language to ", selectedLanguage);
  await processTextParam();
  rememberText();
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

async function csvPdfExport(event, exportFunction) {
  const buttonElement = event.currentTarget;
  const iconElement = buttonElement.querySelector("i");

  buttonElement.disabled = true;
  const oldIconClass = iconElement.className;
  iconElement.className = "icon icon--spinner";

  let lines;
  const layoutType = globalThis.transcriptionMode;
  switch (layoutType) {
    case "line":
      lines = [...document.querySelectorAll("#result > tr.line")].map((line) =>
        [...line.querySelectorAll("div.cell")].map((x) => ({
          text: x.querySelector("div.input_text").textContent,
          ipa: x.querySelector("div.ipa")
            ? x.querySelector("div.ipa").getAttribute("content")
            : "",
        })),
      );
      break;
    case "sideBySide":
      lines = [...document.querySelectorAll("#result > tr")].map((x) => ({
        text: [
          ...x.querySelectorAll(":scope > div")[0].querySelectorAll("div.cell"),
        ].map((x) => x.textContent),
        ipa: [
          ...x.querySelectorAll(":scope > div")[1].querySelectorAll("div.cell"),
        ].map((x) => x.textContent),
      }));

      break;
    case "default":
      const rows = document.querySelectorAll("#result > tr");
      lines = Array.from(rows).map((row) =>
        Array.from(row.querySelectorAll("div.cell")).map(
          (cell) => cell.textContent,
        ),
      );
      break;
  }

  await exportFunction(
    lines,
    layoutType,
    isDarkMode(),
    globalThis.transcriptionLang,
  );

  iconElement.className = oldIconClass;
  buttonElement.disabled = false;
}

document
  .getElementById("export_pdf")
  .addEventListener("click", (e) => csvPdfExport(e, toPdf));
document
  .getElementById("export_csv")
  .addEventListener("click", (e) => csvPdfExport(e, toCsv));

function toggleDarkMode() {
  console.log("setting dark");
  if (document.body.classList.contains("dark_mode")) {
    console.log("dark already setting light");
    toggleLightMode();
  } else {
    document.body.classList.add("dark_mode");
    document.querySelector("#header > a > i").className = "icon icon-sun";
  }
}

function toggleLightMode() {
  document.querySelector("#header>a>i").className = "icon icon-moon";
  document.body.classList.remove("dark_mode");
}

document.getElementById("dark_mode").addEventListener("click", toggleDarkMode);

function triggerLanguageChange() {
  const urlParams = new URLSearchParams(window.location.search);
  const selectedLanguage = urlParams.get("lang");

  if (selectedLanguage) {
    const languageSelect = document.querySelector("#lang");
    const languageOption = document.querySelector(
      `#lang option[value="${selectedLanguage}"]`,
    );

    if (languageOption) {
      languageSelect.value = selectedLanguage;
      languageSelect.dispatchEvent(new Event("change"));
    }
  }
}

triggerLanguageChange();

function rememberText() {
  const textArea = document.getElementById("text_to_transcribe");
  console.log(12345);

  // Check if the event listener is already added
  if (!textArea.hasAttribute("data-listener-added")) {
    // Save text to local storage on input
    textArea.addEventListener("input", function () {
      console.log("input", textArea.value);
      localStorage.setItem("inputText", textArea.value);
    });

    // Set a flag to indicate that the listener has been added
    textArea.setAttribute("data-listener-added", "true");
  }

  // Retrieve text from local storage on page load
  console.log("DOMContentLoaded", localStorage.getItem("inputText"));
  const savedText = localStorage.getItem("inputText");
  if (savedText) {
    textArea.value = savedText;
  }
}
rememberText();

// Check for 'text' parameter in URL and process it

async function processTextParam() {
  const urlParams = new URLSearchParams(window.location.search);
  const textParam = urlParams.get("text");
  const lang = urlParams.get("lang");
  console.log(555555555, textParam, lang);

  if (textParam) {
    const textArea = document.getElementById("text_to_transcribe");
    textArea.value = textParam;

    textArea.dispatchEvent(new Event("input"));

    await transcribe("line", false, textParam);
  }
}
