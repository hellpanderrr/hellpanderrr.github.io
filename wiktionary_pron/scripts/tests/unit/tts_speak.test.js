import assert from "node:assert";
import "fake-indexeddb/auto";

// StreamingTTS (scripts/tts.js): cache key, stop() races, stale audio, timeouts.
// fetch is mocked, so nothing touches the network.
//
// tts.js needs a few browser globals at import time (`EasySpeech`, and
// `new StreamingTTS()` -> `new Audio()` / `document.body`). They are installed in
// before() and REMOVED in after(): mocha loads every test file before running any,
// so top-level stubs would leak into the other unit tests, and scripts/tests/setup.cjs
// says never to shim `document` globally (wasmoon's Emscripten glue sniffs it).

const VOICE = { name: "Test", lang: "de-DE", raw: { ShortName: "de-DE-TestNeural" } };
const VOICES = [{ FriendlyName: "Test", Locale: "de-DE", ShortName: "de-DE-TestNeural" }];

const deferred = () => {
  let resolve;
  const promise = new Promise((r) => (resolve = r));
  return { promise, resolve };
};
const audio = () => new Blob([new Uint8Array(4000).fill(1)], { type: "audio/mpeg" });
const tick = (ms = 20) => new Promise((r) => setTimeout(r, ms));
// Wait for a condition (not a guessed delay): race tests must synchronize on the
// checkpoint the interleaving needs, or a slow machine lets them pass without
// exercising the race.
const until = async (cond, ms = 3000) => {
  const t0 = Date.now();
  while (!cond()) {
    if (Date.now() - t0 > ms) throw new Error("timed out waiting for the test checkpoint");
    await tick(5);
  }
};

describe("tts.js StreamingTTS", function () {
  this.timeout(10000);
  let StreamingTTS;
  let ttsCacheKey;
  let origFetch;
  const saved = {};
  const GLOBALS = ["Audio", "document", "EasySpeech"];

  before(async function () {
    for (const k of GLOBALS) saved[k] = Object.getOwnPropertyDescriptor(globalThis, k);
    // tts.js does real work at import: EasySpeech.init(), and `EdgeTTS.init()` on a
    // module-level instance, which fetches the voice list. Answer that from a mock
    // (never the network) and hand it DOM-shaped stubs for the elements it looks up.
    origFetch = globalThis.fetch;
    globalThis.fetch = async () => ({ ok: true, json: async () => VOICES });
    globalThis.EasySpeech = { init: () => Promise.resolve(), voices: () => [] };
    const el = () => ({
      options: [{}, {}],
      selectedOptions: [],
      innerHTML: "",
      value: "",
      style: {},
      addEventListener() {},
      appendChild() {},
    });
    globalThis.Audio = class {
      static plays = 0;
      constructor() {
        this.src = "";
        this.volume = 1;
        this.currentTime = 0;
        this.style = {};
      }
      play() {
        globalThis.Audio.plays += 1;
        return Promise.resolve();
      }
      pause() {}
      removeAttribute(name) {
        if (name === "src") this.src = "";
      }
    };
    globalThis.document = {
      body: { appendChild() {} },
      readyState: "complete",
      querySelector: () => el(),
      querySelectorAll: () => [],
      addEventListener() {},
    };
    ({ StreamingTTS, ttsCacheKey } = await import("../../tts.js"));
    await tick(100); // let the module-level init() settle against the mock
    globalThis.fetch = origFetch;
  });

  after(function () {
    for (const k of GLOBALS) {
      if (saved[k]) Object.defineProperty(globalThis, k, saved[k]);
      else delete globalThis[k];
    }
  });

  beforeEach(function () {
    globalThis.Audio.plays = 0;
  });
  afterEach(function () {
    globalThis.fetch = origFetch;
  });

  // A fresh, initialised instance whose fetch is mocked: the voice list answers at
  // once, each /tts call is handed to `onTts`.
  async function make(onTts, opts = { requestDelayMs: 0 }) {
    globalThis.fetch = (url, init = {}) => {
      if (String(url).includes("/voices") || String(url).includes("voices/list")) {
        return Promise.resolve({ ok: true, json: async () => VOICES });
      }
      return onTts(String(url), init);
    };
    const t = new StreamingTTS();
    t.configure(opts);
    await t.init();
    return t;
  }

  describe("ttsCacheKey", function () {
    it("distinguishes non-Latin sentences of the same length (the old key dropped every non-ASCII letter)", function () {
      const a = ttsCacheKey("v", 1, 1, "Привет, как дела?");
      const b = ttsCacheKey("v", 1, 1, "Спасибо, пока ещё");
      assert.strictEqual("Привет, как дела?".length, "Спасибо, пока ещё".length);
      assert.notStrictEqual(a, b);
    });

    it("is stable for the same input and changes with voice, rate, pitch and text", function () {
      const base = ttsCacheKey("v", 1, 1, "Hallo Welt");
      assert.strictEqual(ttsCacheKey("v", 1, 1, "Hallo Welt"), base);
      assert.notStrictEqual(ttsCacheKey("w", 1, 1, "Hallo Welt"), base);
      assert.notStrictEqual(ttsCacheKey("v", 1.25, 1, "Hallo Welt"), base);
      assert.notStrictEqual(ttsCacheKey("v", 1, 0.5, "Hallo Welt"), base);
      assert.notStrictEqual(ttsCacheKey("v", 1, 1, "Hallo Welt!"), base);
    });

    it("covers the WHOLE text, not just a prefix", function () {
      const long = "x".repeat(200);
      assert.notStrictEqual(ttsCacheKey("v", 1, 1, long + "a"), ttsCacheKey("v", 1, 1, long + "b"));
    });
  });

  describe("speak()", function () {
    it("stop() while the audio is downloading does not make speak() throw, and nothing plays", async function () {
      const blobGate = deferred();
      const bodyStarted = deferred();
      const t = await make(async () => ({
        ok: true,
        blob: () => {
          bodyStarted.resolve();
          return blobGate.promise;
        },
      }));
      const p = t.speak({ text: `Hallo ${Math.random()}`, voice: VOICE });
      await bodyStarted.promise; // it is now inside response.blob()
      t.stop();
      blobGate.resolve(audio());
      await assert.doesNotReject(p, "speak() must not throw when stop() lands mid-download");
      assert.strictEqual(globalThis.Audio.plays, 0, "audio started after the reader pressed stop");
    });

    it("stop() during the request-spacing delay does not make speak() throw, and nothing is requested or played", async function () {
      // tts.js waits before every request so the farm is not hammered. The abort
      // controller is created BEFORE that wait, and stop() nulls it during it; the
      // line after the wait then dereferenced null.
      let ttsCalls = 0;
      const t = await make(
        async () => {
          ttsCalls += 1;
          return { ok: true, blob: async () => audio() };
        },
        // Cache OFF: with it on, a slow IndexedDB lookup could outlast the sleep below,
        // stop() would land before the spacing wait even started, and the test would pass
        // without exercising it. With it off, speak() goes straight into the 300 ms wait.
        { requestDelayMs: 300, enableCache: false },
      );
      await t.speak({ text: `Erste ${Math.random()}`, voice: VOICE }); // sets the spacing clock
      ttsCalls = 0;
      globalThis.Audio.plays = 0;

      const p = t.speak({ text: `Zweite ${Math.random()}`, voice: VOICE }); // now waits ~300ms
      await tick(60);
      t.stop();
      await assert.doesNotReject(p, "speak() must not throw when stop() lands during the spacing delay");
      assert.strictEqual(ttsCalls, 0, "a stopped speak still hit a worker");
      assert.strictEqual(globalThis.Audio.plays, 0, "a stopped speak played");
    });

    it("stop() AFTER the response headers arrive aborts the request itself, and speak() settles", async function () {
      // fetch() resolves when the HEADERS arrive; the body is read later (response.blob()).
      // The parent-abort link must stay connected through that read: a stopped download
      // that keeps running, or a stalled body that leaves speak() pending forever, is
      // exactly what the old shared signal prevented.
      let signal;
      const bodyStarted = deferred();
      const t = await make(async (url, init) => {
        signal = init.signal;
        return {
          ok: true,
          // A body that never finishes, like a real one: it fails only if ITS request is aborted.
          blob: () =>
            new Promise((_, reject) => {
              bodyStarted.resolve();
              signal.addEventListener("abort", () =>
                reject(Object.assign(new Error("aborted"), { name: "AbortError" })),
              );
            }),
        };
      });

      const p = t.speak({ text: `Körper ${Math.random()}`, voice: VOICE });
      await bodyStarted.promise;
      assert.strictEqual(signal.aborted, false, "the request must be live before stop()");
      t.stop();

      assert.strictEqual(signal.aborted, true, "stop() must abort the request while its body is downloading");
      const settled = await Promise.race([p.then(() => "settled"), tick(500).then(() => "STILL PENDING")]);
      assert.strictEqual(settled, "settled", "speak() must not hang after stop()");
      assert.strictEqual(globalThis.Audio.plays, 0);
    });

    it("a slow first speak never plays over a newer one", async function () {
      const gates = [];
      const t = await make(async () => {
        const g = deferred();
        gates.push(g);
        return { ok: true, blob: () => g.promise };
      });
      const a = t.speak({ text: `Erste ${Math.random()}`, voice: VOICE });
      await until(() => gates.length === 1);
      const b = t.speak({ text: `Zweite ${Math.random()}`, voice: VOICE }); // stop() + new request
      await until(() => gates.length === 2);
      assert.strictEqual(gates.length, 2, "both speaks should be waiting on their audio");

      gates[0].resolve(audio()); // the OLD one finishes first
      await a;
      assert.strictEqual(globalThis.Audio.plays, 0, "the superseded speak played its stale audio");

      gates[1].resolve(audio());
      await b;
      assert.strictEqual(globalThis.Audio.plays, 1, "the newest speak should play exactly once");
    });

    it("aborts the request itself when a worker times out (no leaked connection)", async function () {
      const realWarn = console.warn;
      const realError = console.error;
      console.warn = console.error = () => {}; // 7 expected "Worker timeout" lines
      try {
        const signals = [];
        const t = await make(
          (url, init) => {
            signals.push(init.signal);
            return new Promise(() => {}); // never answers
          },
          { requestDelayMs: 0, workerTimeoutMs: 40 },
        );
        await t.speak({ text: `Zeit ${Math.random()}`, voice: VOICE });
        assert.ok(signals.length >= 2, "should have tried several workers");
        assert.ok(
          signals.every((s) => s && s.aborted),
          `${signals.filter((s) => !s.aborted).length} of ${signals.length} timed-out requests were left running`,
        );
        assert.strictEqual(globalThis.Audio.plays, 0);
      } finally {
        console.warn = realWarn;
        console.error = realError;
      }
    });
  });
});
