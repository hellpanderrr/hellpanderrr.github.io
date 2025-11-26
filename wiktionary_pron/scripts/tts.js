class IndexedDBCache {
  #dbName = "ttsCacheDB";
  #storeName = "audioStore";
  #db = null;

  async #getDB() {
    if (this.#db) return this.#db;
    return new Promise((resolve, reject) => {
      const request = indexedDB.open(this.#dbName, 1);
      request.onerror = () => reject("Error opening IndexedDB.");
      request.onsuccess = (event) => {
        this.#db = event.target.result;
        resolve(this.#db);
      };
      request.onupgradeneeded = (event) => {
        const db = event.target.result;
        if (!db.objectStoreNames.contains(this.#storeName)) {
          db.createObjectStore(this.#storeName);
        }
      };
    });
  }

  async getAudio(key) {
    const db = await this.#getDB();
    return new Promise((resolve) => {
      const transaction = db.transaction([this.#storeName], "readonly");
      const store = transaction.objectStore(this.#storeName);
      const request = store.get(key);
      request.onsuccess = () => resolve(request.result || null);
      request.onerror = () => resolve(null); // Resolve with null on error
    });
  }

  async saveAudio(key, blob) {
    const db = await this.#getDB();
    const transaction = db.transaction([this.#storeName], "readwrite");
    const store = transaction.objectStore(this.#storeName);
    store.put(blob, key);
  }
}

/**
 * A class that mimics the EasySpeech API but uses the Microsoft Edge
 * streaming TTS service.
 */
class StreamingTTS {
  // --- Private Properties ---
  #WSS_URL =
    "wss://speech.platform.bing.com/consumer/speech/synthesize/readaloud/edge/v1";
  #TRUSTED_CLIENT_TOKEN = "6A5AA1D4EAFF4E9FB37E23D68491D6F4";
  #VOICES_URL = `https://speech.platform.bing.com/consumer/speech/synthesize/readaloud/voices/list?trustedclienttoken=${
    this.#TRUSTED_CLIENT_TOKEN
  }`;
  #AUDIO_FORMAT = "audio-24khz-96kbitrate-mono-mp3";
  #GEC_VERSION = "1-130.0.2849.68";
  #enableCache = false;
  #cache = new IndexedDBCache();

  #voices = [];
  #isInitialized = false;
  #audioPlayer = null;
  #mediaSource = null;
  #sourceBuffer = null;
  #audioQueue = [];
  #isAppending = false;
  #currentSocket = null;
  #apiAudioFormat = null;
  #mimeType = null;

  constructor() {
    this.#audioPlayer = new Audio();
    this.#audioPlayer.id = "streaming-tts-player";
    this.#audioPlayer.style.display = "none";
    document.body.appendChild(this.#audioPlayer);
    this.#determineAudioFormat();
  }

  #determineAudioFormat() {
    // Prefer MP3 if supported (Chrome, Edge, Safari, etc.)
    if (MediaSource.isTypeSupported("audio/mpeg")) {
      console.log("TTS Engine: MP3 is supported. Using MP3 format.");
      this.#apiAudioFormat = "audio-24khz-96kbitrate-mono-mp3";
      this.#mimeType = "audio/mpeg";
    }
    // Fallback to WebM/Opus for Firefox and other non-MP3 browsers
    else if (MediaSource.isTypeSupported('audio/webm; codecs="opus"')) {
      console.log(
        "TTS Engine: MP3 not supported, but WebM/Opus is. Using Opus format.",
      );
      this.#apiAudioFormat = "webm-24khz-16bit-mono-opus";
      this.#mimeType = 'audio/webm; codecs="opus"';
    } else {
      console.error(
        "TTS Engine: This browser supports neither MP3 nor WebM/Opus in MediaSource. Enhanced TTS will be unavailable.",
      );
    }
  }

  // --- Public API Methods ---
  async init() {
    if (!this.#apiAudioFormat) {
      return Promise.reject(
        "No compatible audio format found for this browser.",
      );
    }
    if (this.#isInitialized) return true;
    try {
      const response = await fetch(this.#VOICES_URL);
      if (!response.ok)
        throw new Error(`HTTP error! status: ${response.status}`);
      const data = await response.json();
      this.#voices = this.#transformVoiceList(data);
      this.#isInitialized = true;
      console.debug("StreamingTTS (Edge) loaded successfully.");
      return true;
    } catch (error) {
      console.error("Failed to initialize StreamingTTS:", error);
      throw error;
    }
  }

  voices() {
    if (!this.#isInitialized) {
      console.warn("StreamingTTS not initialized. Call init() first.");
      return [];
    }
    return this.#voices;
  }

  async speak(config) {
    if (!this.#apiAudioFormat) {
      console.error(
        "Cannot speak: No compatible audio format supported by this browser.",
      );
      return;
    }
    const { text, voice, rate = 1, pitch = 1, volume = 1, boundary } = config;

    if (!this.#isInitialized)
      return console.error("Speak failed: StreamingTTS not initialized.");
    if (!text) return console.error("Speak failed: No text provided.");
    if (!voice || !voice.raw)
      return console.error("Speak failed: Invalid voice object provided.");

    this.stop();
    this.#audioPlayer.volume = Math.max(0, Math.min(1, volume));

    try {
      await this.#setupMediaSource();
    } catch (e) {
      console.error("Audio setup failed:", e);
      this.stop();
      return;
    }

    this.#audioPlayer
      .play()
      .catch((e) => console.warn("Autoplay was prevented:", e));

    const secMsGec = await this.#generateSecMsGec(this.#TRUSTED_CLIENT_TOKEN);
    const connectionId = this.#generateUUID();

    const fullUrl = `${this.#WSS_URL}?TrustedClientToken=${
      this.#TRUSTED_CLIENT_TOKEN
    }&Sec-MS-GEC=${secMsGec}&ConnectionId=${connectionId}&Sec-MS-GEC-Version=${
      this.#GEC_VERSION
    }`;

    const socket = new WebSocket(fullUrl);
    socket.binaryType = "arraybuffer";
    this.#currentSocket = socket;

    socket.onopen = () => {
      const configMessage = `Content-Type:application/json; charset=utf-8\r\nPath:speech.config\r\n\r\n{"context":{"synthesis":{"audio":{"metadataoptions":{"sentenceBoundaryEnabled":"false","wordBoundaryEnabled":"false"},"outputFormat":"${
        this.#apiAudioFormat
      }"}}}}`;
      socket.send(configMessage);

      const ratePercent = ((rate - 1) * 100).toFixed(2);
      const pitchPercent = ((pitch - 1) * 100).toFixed(2);
      const ssml = `<speak version="1.0" xmlns="http://www.w3.org/2001/10/synthesis" xml:lang="${
        voice.lang
      }"><voice name="${
        voice.raw.ShortName
      }"><prosody rate="${ratePercent}%" pitch="${pitchPercent}%">${text
        .replace(/&/g, "&amp;")
        .replace(/</g, "&lt;")
        .replace(/>/g, "&gt;")}</prosody></voice></speak>`;
      socket.send(
        `X-RequestId:${this.#generateUUID()}\r\nContent-Type:application/ssml+xml\r\nPath:ssml\r\n\r\n${ssml}`,
      );
    };

    socket.onmessage = (event) => {
      if (typeof event.data === "string") {
        if (
          event.data.includes("Path:turn.start") &&
          typeof boundary === "function"
        )
          boundary({ name: "start" });
      } else if (event.data instanceof ArrayBuffer) {
        const headerDelimiter = "Path:audio\r\n";
        // Optimization: Only check the start of the buffer for the header
        const dataString = new TextDecoder().decode(event.data.slice(0, 150));
        const headerIndex = dataString.indexOf(headerDelimiter);
        if (headerIndex !== -1) {
          const audioData = event.data.slice(
            headerIndex + headerDelimiter.length,
          );
          if (audioData.byteLength > 0) {
            this.#audioQueue.push(audioData);
            this.#appendNextChunk();
          }
        }
      }
    };

    socket.onerror = (error) => {
      console.error("WebSocket Error:", error);
      this.stop();
    };
    socket.onclose = () => {
      this.#finalizeStream();
      if (this.#enableCache && audioChunks.length > 0) {
        //Use dynamic mimeType for blob creation ---
        const audioBlob = new Blob(audioChunks, { type: this.#mimeType });
        console.log(
          `Saving to cache (${(audioBlob.size / 1024).toFixed(2)} KB)`,
        );
        this.#cache.saveAudio(cacheKey, audioBlob);
      }
    };
  }

  stop() {
    // 1. Completely and safely dismantle the WebSocket connection.
    if (this.#currentSocket) {
      // Nullify ALL event handlers to prevent any lingering callbacks from firing.
      this.#currentSocket.onopen = null;
      this.#currentSocket.onmessage = null;
      this.#currentSocket.onerror = null;
      this.#currentSocket.onclose = null;

      // Defensively close the socket only if it's in an active state.
      try {
        const state = this.#currentSocket.readyState;
        if (state === WebSocket.OPEN || state === WebSocket.CONNECTING) {
          // Use the spec-compliant close method with a normal closure code.
          this.#currentSocket.close(1000, "client stop");
        }
      } catch (e) {
        // This can happen in rare cases; it's safe to ignore.
        console.debug("Error while closing WebSocket, ignoring:", e);
      }

      this.#currentSocket = null;
    }

    // 2. Clear internal state.
    this.#audioQueue = [];
    this.#isAppending = false;

    // 3. Gracefully end the MediaSource stream.
    this.#finalizeStream();

    // 4. Fully and safely reset the <audio> element.
    this.#audioPlayer.pause();

    // Revoke any object URL to prevent memory leaks.
    if (this.#audioPlayer.src && this.#audioPlayer.src.startsWith("blob:")) {
      URL.revokeObjectURL(this.#audioPlayer.src);
    }

    // Remove the source and call load() to force the element to reset.
    this.#audioPlayer.removeAttribute("src");
    try {
      this.#audioPlayer.load();
    } catch (e) {
      // This can fail in some browsers/states; it's safe to ignore.
      console.debug("Error while resetting audio element, ignoring:", e);
    }
  }

  // --- Private Helper Methods ---
  #finalizeStream() {
    // This is the more robust version that prevents Firefox warnings and is generally safer.
    if (!this.#mediaSource || this.#mediaSource.readyState !== "open") {
      return;
    }

    const end = () => {
      if (this.#mediaSource.readyState === "open") {
        try {
          this.#mediaSource.endOfStream();
        } catch (e) {
          console.warn(
            "Error calling endOfStream, stream likely already closed.",
            e,
          );
        }
      }
    };

    if (this.#sourceBuffer && this.#sourceBuffer.updating) {
      const onUpdateEnd = () => {
        this.#sourceBuffer.removeEventListener("updateend", onUpdateEnd);
        end();
      };
      this.#sourceBuffer.addEventListener("updateend", onUpdateEnd);
    } else {
      end();
    }
  }

  #setupMediaSource() {
    this.#mediaSource = new MediaSource();
    this.#audioPlayer.src = URL.createObjectURL(this.#mediaSource);
    return new Promise((resolve, reject) => {
      this.#mediaSource.addEventListener(
        "sourceopen",
        () => {
          try {
            this.#sourceBuffer = this.#mediaSource.addSourceBuffer(
              this.#mimeType,
            );
            this.#sourceBuffer.addEventListener(
              "updateend",
              this.#processAudioQueue.bind(this),
            );
            resolve();
          } catch (e) {
            reject(e);
          }
        },
        { once: true },
      );
    });
  }

  #processAudioQueue() {
    this.#isAppending = false;
    if (this.#audioQueue.length > 0) this.#appendNextChunk();
  }

  #appendNextChunk() {
    if (
      !this.#isAppending &&
      this.#sourceBuffer &&
      !this.#sourceBuffer.updating &&
      this.#audioQueue.length > 0
    ) {
      this.#isAppending = true;
      try {
        this.#sourceBuffer.appendBuffer(this.#audioQueue.shift());
      } catch (e) {
        console.error("Buffer append error:", e);
        this.#isAppending = false;
      }
    }
  }

  #transformVoiceList(list) {
    return list
      .map((voice) => ({
        name: voice.FriendlyName,
        lang: voice.Locale.replace(/_/g, "-"), // Normalize locale format from en_US to en-US
        default: false,
        raw: voice,
      }))
      .sort((a, b) => a.name.localeCompare(b.name));
  }

  #generateUUID = () =>
    "xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx".replace(/[xy]/g, (c) => {
      const r = (Math.random() * 16) | 0;
      return (c == "x" ? r : (r & 0x3) | 0x8).toString(16);
    });

  async #generateSecMsGec(token) {
    const timestamp = Math.floor(Date.now() / 1000) + 11644473600;
    const s = (timestamp - (timestamp % 300)) * 10000000;
    const encodedData = new TextEncoder().encode(`${s}${token}`);
    const hashBuffer = await crypto.subtle.digest("SHA-256", encodedData);
    return Array.from(new Uint8Array(hashBuffer))
      .map((b) => b.toString(16).padStart(2, "0"))
      .join("")
      .toUpperCase();
  }
}

let EdgeTTS;
try {
  EdgeTTS = new StreamingTTS();
} catch (error) {
  console.log("Failed to load Edge TTS engine: ", error);
}
const engines = {
  browser: EasySpeech,
  edge: EdgeTTS,
};
let activeEngine = engines.browser; // Default to the standard browser engine
let activeEngineName = "browser";

function populateVoiceList(langCode) {
  const voiceSelect = document.querySelector("#tts");
  if (!voiceSelect) return;
  const voices = activeEngine
    .voices()
    .toSorted((a, b) => a.lang.localeCompare(b.lang));

  voiceSelect.innerHTML = ""; // Clear existing options

  voices.forEach((voice) => {
    const option = document.createElement("option");
    const displayName = voice.name || voice.friendlyName;
    option.textContent = `${displayName} (${voice.lang})`;
    option.value = displayName;
    option.setAttribute("data-lang", voice.lang);
    option.setAttribute("data-name", displayName);
    voiceSelect.appendChild(option);
  });
  if (langCode) {
    const voices = Array.from(voiceSelect.options);
    const relevantVoices = voices.filter((option) =>
      (option.getAttribute("data-lang") || "").includes(langCode),
    );
    if (relevantVoices.length > 0) {
      document.querySelector("#tts").value = relevantVoices[0].value;
    }
  }
}

function getSelectedVoice() {
  const voices = activeEngine.voices();
  const selectedVoiceName = document
    .querySelector("#tts")
    ?.selectedOptions[0]?.getAttribute("data-name");

  if (!selectedVoiceName) return voices[0];

  return voices.find((v) => (v.name || v.friendlyName) === selectedVoiceName);
}

function tts(transcriptionMode) {
  console.log("Attaching TTS listeners");
  const text_els =
    transcriptionMode === "line"
      ? document.querySelectorAll(".input_text")
      : document.querySelectorAll("#result span");
  const lineButtons = document.querySelectorAll(".audio-popup-line");
  const getVolume = () =>
    parseFloat(document.querySelector("#tts_volume").value) / 100;
  const getSpeed = () =>
    parseFloat(document.querySelector("#tts_speed").value) / 100;

  lineButtons.forEach((button) => {
    button.addEventListener("click", (e) => {
      let lineText = Array.from(
        e.currentTarget.parentElement.querySelectorAll(".input_text"),
      )
        .map((x) => x.textContent)
        .join(" ");
      if (!lineText)
        lineText = Array.from(
          e.currentTarget.parentElement.querySelectorAll(".ipa"),
        )
          .map((x) => x.getAttribute("data-word"))
          .join(" ");
      activeEngine.speak({
        text: lineText,
        voice: getSelectedVoice(),
        pitch: 1,
        rate: getSpeed(),
        volume: getVolume(),
        boundary: (e) => console.debug(`${e.name} boundary reached`),
      });
    });
  });

  Array.from(text_els).forEach((el) => {
    let timer;
    const popup = el.previousElementSibling;
    if (!popup) return;
    const getTextContent = (el) => {
      switch (transcriptionMode) {
        case "default":
          return el.getAttribute("data-word");
        case "line":
          return el.textContent;
        case "sideBySide":
          return el.getAttribute("data-word") || el.textContent;
        default:
          return el.textContent;
      }
    };
    popup.addEventListener("click", () =>
      activeEngine.speak({
        text: getTextContent(el),
        voice: getSelectedVoice(),
        pitch: 1,
        rate: getSpeed(),
        volume: getVolume(),
        boundary: (e) => console.debug(`${e.name} boundary reached`),
      }),
    );
    el.addEventListener("mouseenter", () => {
      popup.style.opacity = "1";
      popup.classList.add("show-popup");
      popup.addEventListener("mouseenter", () => clearTimeout(timer));
      popup.addEventListener("mouseleave", () => {
        timer = setTimeout(() => {
          popup.style.opacity = "0";
          setTimeout(() => popup.classList.remove("show-popup"), 500);
        }, 3000);
      });
    });
    el.addEventListener("mouseleave", () => {
      timer = setTimeout(() => {
        popup.style.opacity = "0";
        setTimeout(() => popup.classList.remove("show-popup"), 500);
      }, 3000);
    });
  });
}

function handleEngineChange(event) {
  const selectedEngine = event.target.value;
  if (selectedEngine === activeEngineName) return;

  console.log(`Switching TTS engine to: ${selectedEngine}`);
  activeEngineName = selectedEngine;
  activeEngine = engines[selectedEngine];

  populateVoiceList(globalThis.transcriptionLangCode);
}

let availableEngineNames = [];
let engineSwitch = null;
let voiceSelect = null;

function setLanguageAndFindVoice(language) {
  try {
    if (!voiceSelect) return;

    // Normalize language code format (convert en_US to en-US for consistent matching)
    const normalizedLanguage = language.replace(/_/g, "-");

    // 1. Search the currently active engine first
    const currentVoices = activeEngine.voices();
    let bestVoice = currentVoices.find((v) =>
      v.lang.replace(/_/g, "-").startsWith(normalizedLanguage),
    );

    if (bestVoice) {
      console.log(
        `Found ${language} voice in current engine ${currentVoices[0]}, ('${activeEngineName}'). ${bestVoice.name}, ${bestVoice.lang}`,
      );
      voiceSelect.value = bestVoice.name || bestVoice.friendlyName;
      return; // Found a match, we're done.
    }

    // 2. If not found, search other available engines
    const otherEngineNames = availableEngineNames.filter(
      (name) => name !== activeEngineName,
    );
    for (const engineName of otherEngineNames) {
      const otherEngine = engines[engineName];
      bestVoice = otherEngine
        .voices()
        .find((v) => v.lang.replace(/_/g, "-").startsWith(normalizedLanguage));

      if (bestVoice) {
        console.log(
          `Found better voice in '${engineName}' engine. Switching...`,
        );
        // Switch the engine programmatically
        activeEngineName = engineName;
        activeEngine = otherEngine;
        engineSwitch.value = engineName; // Update the switch UI

        // Repopulate the voice list and select the found voice
        populateVoiceList();
        voiceSelect.value = bestVoice.name || bestVoice.friendlyName;
        return;
      }
    }

    console.warn(
      `No voice found for language '${language}' in any available engine.`,
    );
  } catch (error) {
    console.error("Error setting language and finding voice:", error);
  }
}

// ============================================================================
// ==  Part 3: Initialization and Event Handling
// ============================================================================

// Self-invoking async function to initialize everything
try {
  (async () => {
    engineSwitch = document.querySelector("#tts_switch");
    voiceSelect = document.querySelector("#tts");

    // Health Check: Initialize both engines in parallel.
    const results = await Promise.allSettled([
      EasySpeech.init({ maxTimeout: 5000, interval: 250 }),
      EdgeTTS.init(),
    ]);
    if (results[0].status === "fulfilled") availableEngineNames.push("browser");
    if (results[1].status === "fulfilled") availableEngineNames.push("edge");

    const browserSuccess = availableEngineNames.includes("browser");
    const edgeSuccess = availableEngineNames.includes("edge");

    // Handle case where both engines fail to load
    if (!browserSuccess && !edgeSuccess) {
      console.error("All TTS engines failed to initialize.");
      engineSwitch.innerHTML = "<option>TTS Unavailable</option>";
      return; // Stop execution
    }

    // Gracefully disable the "Enhanced" option if it fails to load
    if (!edgeSuccess) {
      console.warn(
        "Enhanced Edge TTS engine failed to load and will be disabled.",
      );
      const edgeOption = engineSwitch.options[1];
      edgeOption.disabled = true;
      edgeOption.textContent += " (Unavailable)";
    }

    if (!browserSuccess) {
      console.error("Standard browser TTS engine failed to load.");
      engineSwitch.options[0].disabled = true;
      // If Edge is available, make it the default
      if (edgeSuccess) {
        engineSwitch.value = "edge";
        activeEngineName = "edge";
        activeEngine = engines.edge;
      }
    }

    // If at least one engine is ready, enable the switch and attach the listener
    engineSwitch.addEventListener("change", handleEngineChange);

    // Populate the initial voice list from the default active engine
    populateVoiceList();

    if (document.readyState === "loading") {
      document.addEventListener("DOMContentLoaded", () => tts("default"));
    } else {
      tts("default");
    }
  })();
} catch (error) {
  console.error("Error loading TTS engines: ", error);
}

export { tts, setLanguageAndFindVoice };
