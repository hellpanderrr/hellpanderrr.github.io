function tts(transcription_mode) {
  console.log("running tts");
  const text_els =
    transcription_mode === "line"
      ? document.querySelectorAll(".input_text")
      : document.querySelectorAll("#result span");

  Array.from(text_els).map(function (el) {
    let timer;
    const popup = el.previousElementSibling;

    function getTextContent(el) {
      let text;
      switch (transcription_mode) {
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

    function getSelectedVoice() {
      const voices = EasySpeech.voices();
      const selectedVoice = document
        .querySelector("#tts")
        .selectedOptions[0].getAttribute("data-name");

      return voices.find((v) => v.name === selectedVoice);
    }

    popup.addEventListener("click", () =>
      EasySpeech.speak({
        text: getTextContent(el),
        voice: getSelectedVoice(),
        pitch: 1,
        rate: 1,
        volume: 1,
        // there are more events, see the API for supported events
        boundary: (e) => console.debug("boundary reached"),
      }),
    );

    el.addEventListener("mouseenter", () => {
      if (popup) {
        popup.style.opacity = 1;
        popup.classList.add("show-popup");
        popup.addEventListener("mouseenter", () => {
          clearTimeout(timer);
        });
        popup.addEventListener("mouseleave", () => {
          timer = setTimeout(() => {
            popup.style.opacity = 0;
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
          popup.style.opacity = 0;
          setTimeout(() => {
            popup.classList.remove("show-popup");
          }, 500); // Wait for the fade-out animation to complete
        }, 3000);
      }
    });
  });
}

export { tts };
