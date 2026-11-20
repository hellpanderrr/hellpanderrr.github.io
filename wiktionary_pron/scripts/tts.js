// Cache key for a synthesized utterance. It must cover the WHOLE text: the old key
// was "voice-rate-pitch-length-<first 50 chars with every non-ASCII-letter
// stripped>", so for Russian, Ukrainian, Greek, ... the text part was EMPTY and two
// different sentences of the same length shared one cache entry (the second played
// the first's audio). cyrb53 is a small, fast, well-distributed 53-bit string hash;
// the length rides along as a cheap extra discriminator.
export function ttsCacheKey(voiceShortName, rate, pitch, text) {
  let h1 = 0xdeadbeef;
  let h2 = 0x41c6ce57;
  for (let i = 0; i < text.length; i++) {
    const ch = text.charCodeAt(i);
    h1 = Math.imul(h1 ^ ch, 2654435761);
    h2 = Math.imul(h2 ^ ch, 1597334677);
  }
  h1 = Math.imul(h1 ^ (h1 >>> 16), 2246822507) ^ Math.imul(h2 ^ (h2 >>> 13), 3266489909);
  h2 = Math.imul(h2 ^ (h2 >>> 16), 2246822507) ^ Math.imul(h1 ^ (h1 >>> 13), 3266489909);
  const hash = (4294967296 * (2097151 & h2) + (h1 >>> 0)).toString(16);
  return `${voiceShortName}-${rate}-${pitch}-${text.length}-${hash}`;
}

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
      request.onerror = () => resolve(null);
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
 * streaming TTS service via a Cloudflare Worker farm.
 */
class StreamingTTS {
  #workers = [
    {base: "https://silent-unit-b6ca.hellpanderrr.workers.dev", lastUsed: 0},
    {base: "https://tts-2.hellpanderrr.workers.dev", lastUsed: 0},
    {base: "https://tts-3.hellpanderrr.workers.dev", lastUsed: 0},
    {base: "https://tts-4.hellpanderrr.workers.dev", lastUsed: 0},
    {base: "https://tts-5.hellpanderrr.workers.dev", lastUsed: 0},
    {base: "https://tts-6.hellpanderrr.workers.dev", lastUsed: 0},
    // Vercel fallback — *.vercel.app is reachable from any ISP/VPN-excluded
    // browser (workers.dev is blocked on some direct connections). Token-gated
    // (not an open proxy) per Vercel AUP: only the Vercel worker carries a token.
    {base: "https://edge-tts-vercel-sigma.vercel.app/api", lastUsed: 0, token: "b77402b99345df4c803a1c61af805c0e8485db885b70aba9"}
  ];

  #requestDelayMs = 3000;
  #lastGlobalRequestTime = 0;

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

    this.#audioPlayer.onerror = (e) => {
      console.error("Audio Player Error:", this.#audioPlayer.error);
      this.#isPlaying = false;
    };

    this.#audioPlayer.onended = () => {
      this.#isPlaying = false;
      if (this.#audioPlayer.src) URL.revokeObjectURL(this.#audioPlayer.src);
    };

    document.body.appendChild(this.#audioPlayer);
  }

  #getBestWorker() {
    // Round-robin starting from a random point, so concurrent requests spread
    // across the whole farm instead of piling onto whichever worker has the
    // oldest lastUsed timestamp (which stacks concurrent jobs on one worker
    // and trips Cloudflare's ~21s request ceiling -> the observed hangs).
    const startIdx = Math.floor(Math.random() * this.#workers.length);
    return this.#workers[(startIdx + 1) % this.#workers.length];
  }

  // Abort a request to one worker after this long so a hung worker fails fast
  // and the rotation loop moves on, instead of waiting out Cloudflare's full
  // ~21s platform kill before failing over.
  #workerTimeoutMs = 9000;

  // Bumped by every speak() and every stop(). A speak() remembers its own number
  // and gives up after any await if the number has moved on, so a slow or stopped
  // request can never play over a newer one (or after the reader pressed stop).
  #speakSeq = 0;

  // Tuning / test hook: { requestDelayMs, workerTimeoutMs }.
  configure(opts = {}) {
    if (opts.requestDelayMs !== undefined) this.#requestDelayMs = opts.requestDelayMs;
    if (opts.workerTimeoutMs !== undefined) this.#workerTimeoutMs = opts.workerTimeoutMs;
  }

  // Fetch with a per-worker timeout. The request runs on a CHILD controller that is
  // aborted when the timeout fires or when `parent` (the current speak()) is
  // aborted, so a hung worker's connection is actually torn down instead of left
  // running after the rotation loop moves on. A timed-out worker counts as a failed
  // attempt so the loop rotates to the next worker.
  async #fetchWithTimeout(url, init, parent) {
    const child = new AbortController();
    const onParentAbort = () => child.abort();
    if (parent.signal.aborted) child.abort();
    else parent.signal.addEventListener("abort", onParentAbort, {once: true});
    let timer = null;
    try {
      return await new Promise((resolve, reject) => {
        timer = setTimeout(() => {
          child.abort();
          reject(new Error("Worker timeout"));
        }, this.#workerTimeoutMs);
        fetch(url, {...init, signal: child.signal}).then(resolve, reject);
      });
    } finally {
      clearTimeout(timer);
      parent.signal.removeEventListener("abort", onParentAbort);
    }
  }

  get isPlaying() {
    return this.#isPlaying;
  }

  async init() {
    if (this.#isInitialized) return true;

    // 1. Try Direct Microsoft URL FIRST (Usually much faster and doesn't get blocked for /voices)
    try {
      const directUrl = "https://speech.platform.bing.com/consumer/speech/synthesize/readaloud/voices/list?trustedclienttoken=6A5AA1D4EAFF4E9FB37E23D68491D6F4";
      const response = await fetch(directUrl);
      if (!response.ok) throw new Error(`Direct error: ${response.status}`);
      const data = await response.json();
      this.#voices = this.#transformVoiceList(data);
      this.#isInitialized = true;
      console.debug("StreamingTTS initialized via Direct MS URL.");
      return true;
    } catch (directError) {
      console.warn("Direct voice fetch failed, attempting proxy workers...", directError);
    }

    // 2. Fallback to Proxies if direct fails
    for (let i = 0; i < this.#workers.length; i++) {
      const worker = this.#workers[i];
      try {
        const response = await fetch(`${worker.base}/voices`, {
          headers: worker.token ? { "Authorization": `Bearer ${worker.token}` } : {}
        });
        if (!response.ok) throw new Error(`Proxy error: ${response.status}`);

        const data = await response.json();
        this.#voices = this.#transformVoiceList(data);
        this.#isInitialized = true;
        console.debug(`StreamingTTS initialized via Proxy (${worker.base}).`);
        return true;
      } catch (proxyError) {
        console.warn(`Voice fetch failed for worker ${worker.base}`);
      }
    }

    // 3. Ultimate Fallback
    console.error("All voice fetch methods failed. Using default voice.");
    this.#voices = [{
      name: "Microsoft Aria Online (Natural) - English (United States)",
      lang: "en-US",
      default: true,
      raw: {ShortName: "en-US-AriaNeural"}
    }];
    this.#isInitialized = true;
    return true;
  }

  voices() {
    if (!this.#isInitialized) {
      console.warn("StreamingTTS not initialized. Call init() first.");
      return [];
    }
    return this.#voices;
  }

  async speak(config) {
    const {text, voice, rate = 1, pitch = 1, volume = 1} = config;

    if (!this.#isInitialized) return console.error("TTS not initialized.");
    if (!text) return console.error("No text provided.");
    if (!voice?.raw?.ShortName) return console.error("Invalid voice object.");

    this.stop(); // bumps #speakSeq, invalidating any speak still in flight
    const call = ++this.#speakSeq;
    this.#audioPlayer.volume = Math.max(0, Math.min(1, volume));

    const cacheKey = ttsCacheKey(voice.raw.ShortName, rate, pitch, text);

    if (this.#enableCache) {
      try {
        const cachedBlob = await this.#cache.getAudio(cacheKey);
        // The lookup is async: a newer speak() (or a stop()) may have happened.
        if (call !== this.#speakSeq) return;
        if (cachedBlob && cachedBlob.size > 0) {
          console.log("TTS: Cache hit");
          this.#playBlob(cachedBlob);
          return;
        }
      } catch (e) {
        console.warn("Cache read error:", e);
      }
    }

    const rateStr = (Math.round((rate - 1) * 100) >= 0 ? "+" : "") + Math.round((rate - 1) * 100) + "%";
    const pitchStr = (Math.round((pitch - 1) * 10) >= 0 ? "+" : "") + Math.round((pitch - 1) * 10) + "Hz";

    // A LOCAL controller. stop() nulls the shared field and a newer speak() replaces
    // it, so reading `this.#currentAbortController` after an await either threw (null)
    // or tested somebody else's controller and played stale audio.
    const ctl = new AbortController();
    this.#currentAbortController = ctl;
    const stale = () => ctl.signal.aborted || call !== this.#speakSeq;

    // 1. Global delay execution (happens only ONCE per speak call)
    const now = Date.now();
    const timeSinceLastGlobal = now - this.#lastGlobalRequestTime;

    if (timeSinceLastGlobal < this.#requestDelayMs) {
      const waitTime = this.#requestDelayMs - timeSinceLastGlobal;
      await new Promise(resolve => setTimeout(resolve, waitTime));
    }

    if (stale()) return;

    // Set timestamp AFTER the delay so next calls wait properly
    this.#lastGlobalRequestTime = Date.now();

    let attempts = 0;
    const maxAttempts = this.#workers.length;
    let audioBlob = null;

    // 2. Worker rotation loop
    while (attempts < maxAttempts) {
      if (stale()) return;

      const worker = this.#getBestWorker();
      worker.lastUsed = Date.now();

      try {
        const response = await this.#fetchWithTimeout(`${worker.base}/tts`, {
          method: "POST",
          headers: {
            "Content-Type": "application/json",
            ...(worker.token ? { "Authorization": `Bearer ${worker.token}` } : {})
          },
          body: JSON.stringify({
            text,
            voice: voice.raw.ShortName,
            rate: rateStr,
            pitch: pitchStr,
            volume: "+0%"
          })
        }, ctl);

        if (!response.ok) {
          const errorText = await response.text();
          throw new Error(`Worker Error ${response.status}: ${errorText}`);
        }

        const blob = await response.blob();
        if (stale()) return; // stopped (or superseded) while the audio downloaded
        if (blob.size < 100) {
          throw new Error("Received empty audio from Worker.");
        }

        audioBlob = blob;
        break;

      } catch (error) {
        if (error.name === 'AbortError') {
          return;
        } else {
          attempts++;
          console.warn(`Worker ${worker.base} failed. Attempt ${attempts}/${maxAttempts}. Error:`, error.message);
        }
      }
    }

    if (audioBlob) {
      if (this.#enableCache) {
        this.#cache.saveAudio(cacheKey, audioBlob);
      }
      if (stale()) return;
      this.#playBlob(audioBlob);
    } else {
      console.error("All workers failed.");
    }
  }

  stop() {
    this.#speakSeq += 1;
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

let activeEngine = engines.browser;
let activeEngineName = "browser";

function populateVoiceList(langCode) {
  const voiceSelect = document.querySelector("#tts");
  if (!voiceSelect) return;
  const voices = activeEngine
      .voices()
      .toSorted((a, b) => a.lang.localeCompare(b.lang));

  voiceSelect.innerHTML = "";

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
    const optionsArray = Array.from(voiceSelect.options);
    const relevantVoices = optionsArray.filter((option) =>
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
  const text_els =
      transcriptionMode === "line"
          ? document.querySelectorAll(".input_text")
          : document.querySelectorAll("#result span");
  const lineButtons = document.querySelectorAll(".audio-popup-line");
  const getVolume = () => parseFloat(document.querySelector("#tts_volume").value) / 100;
  const getSpeed = () => parseFloat(document.querySelector("#tts_speed").value) / 100;

  lineButtons.forEach((button) => {
    button.addEventListener("click", (e) => {
      let lineText = Array.from(e.currentTarget.parentElement.querySelectorAll(".input_text"))
          .map((x) => x.textContent).join(" ");
      if (!lineText)
        lineText = Array.from(e.currentTarget.parentElement.querySelectorAll(".ipa"))
            .map((x) => x.getAttribute("data-word")).join(" ");

      activeEngine.speak({
        text: lineText,
        voice: getSelectedVoice(),
        pitch: 1,
        rate: getSpeed(),
        volume: getVolume()
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
          volume: getVolume()
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
    const normalizedLanguage = language.replace(/_/g, "-");

    const currentVoices = activeEngine.voices();
    let bestVoice = currentVoices.find((v) =>
        v.lang.replace(/_/g, "-").startsWith(normalizedLanguage),
    );

    if (bestVoice) {
      voiceSelect.value = bestVoice.name || bestVoice.friendlyName;
      return;
    }

    const otherEngineNames = availableEngineNames.filter((name) => name !== activeEngineName);
    for (const engineName of otherEngineNames) {
      const otherEngine = engines[engineName];
      bestVoice = otherEngine.voices().find((v) => v.lang.replace(/_/g, "-").startsWith(normalizedLanguage));

      if (bestVoice) {
        activeEngineName = engineName;
        activeEngine = otherEngine;
        engineSwitch.value = engineName;
        populateVoiceList();
        voiceSelect.value = bestVoice.name || bestVoice.friendlyName;
        return;
      }
    }
  } catch (error) {
    console.error("Error setting language and finding voice:", error);
  }
}

// ============================================================================
// ==  Parallel Initialization (Decoupled)
// ============================================================================
try {
  engineSwitch = document.querySelector("#tts_switch");
  voiceSelect = document.querySelector("#tts");

  // Indicate that Edge is loading initially
  if (engineSwitch && engineSwitch.options[1]) {
    engineSwitch.options[1].disabled = true;
    engineSwitch.options[1].textContent += " (Loading...)";
  }

  // 1. Initialize Browser Engine (Fast)
  EasySpeech.init({maxTimeout: 5000, interval: 250})
      .then(() => {
        availableEngineNames.push("browser");
        if (activeEngineName === "browser") {
          populateVoiceList(); // Populate immediately
        }
      })
      .catch((error) => {
        console.error("Standard browser TTS engine failed to load.", error);
        if (engineSwitch && engineSwitch.options[0]) {
          engineSwitch.options[0].disabled = true;
        }
      });

  // 2. Initialize Edge Engine in Background
  EdgeTTS.init()
      .then(() => {
        availableEngineNames.push("edge");
        if (engineSwitch && engineSwitch.options[1]) {
          engineSwitch.options[1].disabled = false;
          engineSwitch.options[1].textContent = engineSwitch.options[1].textContent.replace(" (Loading...)", "").replace(" (Unavailable)", "");
        }

        // Auto-switch to Edge if it's supposed to be default or if Browser failed
        if (!availableEngineNames.includes("browser") || activeEngineName === "edge") {
          engineSwitch.value = "edge";
          activeEngineName = "edge";
          activeEngine = engines.edge;
          populateVoiceList();
        }
      })
      .catch((error) => {
        console.error("Enhanced Edge TTS engine failed to load.", error);
        if (engineSwitch && engineSwitch.options[1]) {
          engineSwitch.options[1].disabled = true;
          engineSwitch.options[1].textContent = engineSwitch.options[1].textContent.replace(" (Loading...)", " (Unavailable)");
        }
      });

  // 3. Attach Event Listeners Immediately
  if (engineSwitch) {
    engineSwitch.addEventListener("change", handleEngineChange);
  }

  if (document.readyState === "loading") {
    document.addEventListener("DOMContentLoaded", () => tts("default"));
  } else {
    tts("default");
  }

} catch (error) {
  console.error("Error loading TTS setup: ", error);
}

export { tts, setLanguageAndFindVoice, StreamingTTS };