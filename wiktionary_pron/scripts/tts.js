function tts() {
  console.log("running tts");
  const text_els = document.querySelectorAll(".input_text");
  Array.from(text_els).map(function (el) {
    let popup;
    let timer;
    popup = el.previousElementSibling;

    function getSelectedVoice() {
      const voices = EasySpeech.voices();
      let voice = voices[0];
      const selectedOption = document
        .querySelector("#tts")
        .selectedOptions[0].getAttribute("data-name");
      for (let i = 0; i < voices.length; i++) {
        if (voices[i].name === selectedOption) {
          voice = voices[i];
        }
      }

      console.log(voice);
      return voice;
    }

    popup.addEventListener("click", () =>
      EasySpeech.speak({
        text: el.textContent,
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
