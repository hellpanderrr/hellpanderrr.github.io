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
/**
 * A class that mimics the EasySpeech API but proxies requests through
 * a Cloudflare Worker to bypass Microsoft Edge CORS/Origin restrictions.
 */
class StreamingTTS {
  // --- Private Properties ---
  #WORKER_BASE = "https://silent-unit-b6ca.hellpanderrr.workers.dev";
  #WORKER_TTS_URL = `${this.#WORKER_BASE}/tts`;
  #WORKER_VOICES_URL = `${this.#WORKER_BASE}/voices`;

  #enableCache = true;
  #cache = new IndexedDBCache();

  #voices = [];
  #isInitialized = false;
  #audioPlayer = null;
  #currentAbortController = null;
  #isPlaying = false;

  constructor() {
    this.#audioPlayer = new Audio();
    this.#audioPlayer.id = "streaming-tts-player";
    this.#audioPlayer.style.display = "none";

    // Handle playback errors (e.g., corrupt audio)
    this.#audioPlayer.onerror = (e) => {
      console.error("Audio Player Error:", this.#audioPlayer.error);
      this.#isPlaying = false;
    };

    this.#audioPlayer.onended = () => {
      this.#isPlaying = false;
      // Revoke URL to prevent memory leaks
      if (this.#audioPlayer.src) URL.revokeObjectURL(this.#audioPlayer.src);
    };

    document.body.appendChild(this.#audioPlayer);
  }

  // --- Public API Methods ---

  /**
   * Returns whether audio is currently playing
   */
  get isPlaying() {
    return this.#isPlaying;
  }

  async init() {
    if (this.#isInitialized) return true;
    try {
      // 1. Try fetching voices from your Worker (Proxy)
      // This prevents CORS issues and keeps all traffic through your worker
      const response = await fetch(this.#WORKER_VOICES_URL);
      if (!response.ok) throw new Error(`Proxy error: ${response.status}`);

      const data = await response.json();
      this.#voices = this.#transformVoiceList(data);
      this.#isInitialized = true;
      console.debug("StreamingTTS initialized via Proxy.");
      return true;
    } catch (proxyError) {
      console.warn("Proxy voice fetch failed, attempting direct fallback...", proxyError);

      // 2. Fallback: Try Direct Microsoft URL
      try {
        const directUrl = "https://speech.platform.bing.com/consumer/speech/synthesize/readaloud/voices/list?trustedclienttoken=6A5AA1D4EAFF4E9FB37E23D68491D6F4";
        const response = await fetch(directUrl);
        if (!response.ok) throw new Error(`Direct error: ${response.status}`);
        const data = await response.json();
        this.#voices = this.#transformVoiceList(data);
        this.#isInitialized = true;
        return true;
      } catch (directError) {
        console.error("All voice fetch methods failed.", directError);
        // 3. Ultimate Fallback: Hardcoded defaults so the UI doesn't crash
        this.#voices = [{
          name: "Microsoft Aria Online (Natural) - English (United States)",
          lang: "en-US",
          default: true,
          raw: {ShortName: "en-US-AriaNeural"}
        }];
        this.#isInitialized = true;
        return true;
      }
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
    const { text, voice, rate = 1, pitch = 1, volume = 1, boundary } = config;

    if (!this.#isInitialized) return console.error("TTS not initialized.");
    if (!text) return console.error("No text provided.");
    if (!voice?.raw?.ShortName) return console.error("Invalid voice object.");

    // Warn about missing feature
    if (boundary) {
      console.warn("Word boundary events are not supported in HTTP-Proxy mode.");
    }

    this.stop(); // Stop previous audio

    // Set volume immediately
    this.#audioPlayer.volume = Math.max(0, Math.min(1, volume));

    // Generate a shorter, safer cache key
    // Key format: Voice-Rate-Pitch-Length-First50Chars
    const safeTextSnippet = text.slice(0, 50).replace(/[^a-z0-9]/gi, '');
    const cacheKey = `${voice.raw.ShortName}-${rate}-${pitch}-${text.length}-${safeTextSnippet}`;

    // --- Cache Check ---
    if (this.#enableCache) {
      try {
        const cachedBlob = await this.#cache.getAudio(cacheKey);
        if (cachedBlob && cachedBlob.size > 0) {
          console.log("TTS: Cache hit");
          this.#playBlob(cachedBlob);
          return;
        }
      } catch (e) {
        console.warn("Cache read error:", e);
      }
    }

    // --- Prepare Network Request ---
    const rateStr = (Math.round((rate - 1) * 100) >= 0 ? "+" : "") + Math.round((rate - 1) * 100) + "%";
    const pitchStr = (Math.round((pitch - 1) * 10) >= 0 ? "+" : "") + Math.round((pitch - 1) * 10) + "Hz";

    this.#currentAbortController = new AbortController();

    try {
      console.log(`TTS: Fetching... (${text.length} chars)`);
      const response = await fetch(this.#WORKER_TTS_URL, {
        method: "POST",
        headers: {"Content-Type": "application/json"},
        body: JSON.stringify({
          text,
          voice: voice.raw.ShortName,
          rate: rateStr,
          pitch: pitchStr,
          volume: "+0%"
        }),
        signal: this.#currentAbortController.signal
      });

      if (!response.ok) {
        const errorText = await response.text();
        throw new Error(`Worker Error ${response.status}: ${errorText}`);
      }

      const audioBlob = await response.blob();

      // --- CRITICAL CHECK: Ensure audio is not empty ---
      if (audioBlob.size < 100) { // < 100 bytes is likely just a header or empty
        throw new Error("Received empty audio from Worker.");
      }

      if (this.#enableCache) {
        this.#cache.saveAudio(cacheKey, audioBlob);
      }

      // Check if we were stopped while fetching
      if (this.#currentAbortController.signal.aborted) return;

      this.#playBlob(audioBlob);

    } catch (error) {
      if (error.name === 'AbortError') {
        console.log("TTS request aborted by user.");
      } else {
        console.error("TTS Proxy Error:", error);
        // Optional: Trigger a UI error callback here if you add one to config
      }
    }
  }

  stop() {
    if (this.#currentAbortController) {
      this.#currentAbortController.abort();
      this.#currentAbortController = null;
    }

    this.#isPlaying = false;
    this.#audioPlayer.pause();
    this.#audioPlayer.currentTime = 0;

    if (this.#audioPlayer.src && this.#audioPlayer.src.startsWith("blob:")) {
      URL.revokeObjectURL(this.#audioPlayer.src);
    }
    this.#audioPlayer.removeAttribute("src");
  }

  // --- Private Helper Methods ---

  #playBlob(blob) {
    const url = URL.createObjectURL(blob);
    this.#audioPlayer.src = url;
    this.#isPlaying = true;

    this.#audioPlayer.play()
        .catch((e) => {
          console.warn("Autoplay prevented or playback failed:", e);
          this.#isPlaying = false;
        });
  }

  #transformVoiceList(list) {
    // Use spread syntax to avoid mutating the incoming data if it's reused elsewhere
    return [...list]
        .map((voice) => ({
          name: voice.FriendlyName,
          lang: voice.Locale.replace(/_/g, "-"),
          default: false,
          raw: voice,
        }))
        .sort((a, b) => a.name.localeCompare(b.name));
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
