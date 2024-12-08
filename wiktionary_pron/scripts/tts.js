try {
  await EasySpeech.init({ maxTimeout: 5000, interval: 250 })
    .then(() => console.debug("load complete"))
    .catch((e) => console.error(e));
} catch (e) {
  console.error(e);
  console.warn("Failed to initialize EasySpeech");
}

function populateVoiceList() {
  const voiceSelect = document.querySelector("#tts");
  const voices = EasySpeech.voices();

  for (let i = 0; i < voices.length; i++) {
    const option = document.createElement("option");
    option.textContent = `${voices[i].name} (${voices[i].lang})`;

    if (voices[i].default) {
      option.textContent += " — DEFAULT";
    }

    option.setAttribute("data-lang", voices[i].lang);
    option.setAttribute("data-name", voices[i].name);
    voiceSelect.appendChild(option);
  }
}

try {
  populateVoiceList();
} catch (e) {
  console.error(e);
  console.warn("failed to populate voice list");
}

function getSelectedVoice() {
  const voices = EasySpeech.voices();
  const selectedVoice = document
    .querySelector("#tts")
    .selectedOptions[0].getAttribute("data-name");

  return voices.find((v) => v.name === selectedVoice);
}
function tts(transcriptionMode) {
  console.log("running tts");
  const text_els =
    transcriptionMode === "line"
      ? document.querySelectorAll(".input_text")
      : document.querySelectorAll("#result span");

  const lineButtons = document.querySelectorAll(".audio-popup-line");

  const getVolume = () => {
    return parseFloat(document.querySelector("#tts_volume").value) / 100;
  };
  const getSpeed = () => {
    return parseFloat(document.querySelector("#tts_speed").value) / 100;
  };

  lineButtons.forEach((button) => {
    button.addEventListener("click", (e) => {
      button = e.currentTarget;
      let lineText = Array.from(
        button.parentElement.querySelectorAll(".input_text"),
      )
        .map((x) => x.textContent)
        .join(" ");
      if (!lineText) {
        lineText = Array.from(button.parentElement.querySelectorAll(".ipa"))
          .map((x) => x.getAttribute("data-word"))
          .join(" ");
      }

      console.log("Speaking:", lineText);
      EasySpeech.speak({
        text: lineText,
        voice: getSelectedVoice(),
        pitch: 1,
        rate: getSpeed(),
        volume: getVolume(),
        // there are more events, see the API for supported events
        boundary: () => console.debug("boundary reached"),
      });
    });
  });

  Array.from(text_els).map(function (el) {
    let timer;
    const popup = el.previousElementSibling;

    function getTextContent(el) {
      let text;
      switch (transcriptionMode) {
        case "default":
          text = el.getAttribute("data-word");
          break;
        case "line":
          text = el.textContent;
          break;
        case "sideBySide":
          text = el.getAttribute("data-word") || el.textContent;
          break;
      }
      return text;
    }

    popup.addEventListener("click", () =>
      EasySpeech.speak({
        text: getTextContent(el),
        voice: getSelectedVoice(),
        pitch: 1,
        rate: getSpeed(),
        volume: getVolume(),
        // there are more events, see the API for supported events
        boundary: () => console.debug("boundary reached"),
      }),
    );

    el.addEventListener("mouseenter", () => {
      if (popup) {
        popup.style.opacity = "1";
        popup.classList.add("show-popup");
        popup.addEventListener("mouseenter", () => {
          clearTimeout(timer);
        });
        popup.addEventListener("mouseleave", () => {
          timer = setTimeout(() => {
            popup.style.opacity = "0";
            setTimeout(() => {
              popup.classList.remove("show-popup");
            }, 500); // Wait for the fade-out animation to complete
          }, 3000);
        });
      }
    });

    el.addEventListener("mouseleave", () => {
      if (popup) {
        timer = setTimeout(() => {
          popup.style.opacity = "0";
          setTimeout(() => {
            popup.classList.remove("show-popup");
          }, 500); // Wait for the fade-out animation to complete
        }, 3000);
      }
    });
  });
}

export { tts };
