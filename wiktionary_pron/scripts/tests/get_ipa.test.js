import { get_ipa_no_cache } from "../utils.js";
import assert from "node:assert";

async function loadLanguage(code) {
  const lua = global.window.lua;
  await lua.doString(`${code} = require("${code}-pron_wasm")`);
  // Get a global lua function as a JS function
  global["window"][code + "_ipa"] = lua.global.get(code);

  // Set a JS function to be a global lua function
}

console.log = function () {};

describe("get_ipa_no_cache", function () {
  function testCases(tests) {
    tests.forEach(({ text, args, expected }) => {
      it(` ${text} should return ${expected} for ${args}`, function () {
        const res = get_ipa_no_cache(text, args).value;
        assert.strictEqual(res, expected);
      });
    });
  }

  before(async function () {
    await (await import("./init.js")).default();
  });
  describe("German", function () {
    before(async function () {
      await loadLanguage("de");
    });
    const tests = [
      {
        text: "aufeinanderzupassende",
        args: "German;Default;Phonemic",
        expected: "aʊ̯f(ʔ)aɪ̯ˈnandɐt͡suˌpasəndə",
      },
      {
        text: "aufeinanderzupassende",
        args: "German;Default;Phonetic",
        expected: "ʔaʊ̯f(ʔ)aɪ̯ˈnan.dɐt͡sʰuˌpʰa.sn̩.də",
      },
    ];

    testCases(tests);
  });

  describe("Latin", function () {
    before(async function () {
      await loadLanguage("la");
    });
    const tests = [
      {
        text: "provinciarum",
        args: "Latin;Ecc;Phonemic",
        expected: "pro.vinˈt͡ʃi.a.rum",
      },
      {
        text: "provinciarum",
        args: "Latin;Ecc;Phonetic",
        expected: "provin̠ʲˈt͡ʃiːärum",
      },
      {
        text: "provinciarum",
        args: "Latin;Classical;Phonemic",
        expected: "pro.u̯inˈki.a.rum",
      },
      {
        text: "provinciarum",
        args: "Latin;Classical;Phonetic",
        expected: "prou̯ɪŋˈkiärʊ̃ˑ",
      },
    ];
    testCases(tests);
  });

  describe("Spanish", function () {
    before(async function () {
      await loadLanguage("es");
    });
    const tests = [
      {
        text: "accidental",
        args: "Spanish;Latin_American;Phonetic",
        expected: "aɣ̞.si.ð̞ẽn̪ˈt̪al",
      },
      {
        text: "accidental",
        args: "Spanish;Castilian;Phonetic",
        expected: "aɣ̞.θi.ð̞ẽn̪ˈt̪al",
      },
      {
        text: "susceptible",
        args: "Spanish;Castilian;Phonetic",
        expected: "sus.θeβ̞ˈt̪i.β̞le",
      },
      {
        text: "susceptible",
        args: "Spanish;Latin_American;Phonetic",
        expected: "su.seβ̞ˈt̪i.β̞le",
      },
    ];
    testCases(tests);
  });

  describe("French", function () {
    before(async function () {
      await loadLanguage("fr");
    });
    const tests = [
      {
        text: "troisièmement",
        args: "French;Default;Phonemic",
        expected: "tʁwa.zjɛm.mɑ̃",
      },
      {
        text: "exponentiel",
        args: "French;Default;Phonemic",
        expected: "ɛk.spɔ.nɑ̃.sjɛl",
      },
    ];
    testCases(tests);
  });

  describe("Polish", function () {
    before(async function () {
      await loadLanguage("pl");
    });
    const tests = [
      {
        text: "zewnętrzny",
        args: "Polish;Default;Phonemic",
        expected: "zɛvˈnɛn.tʂnɨ",
      },
      {
        text: "grałybyśmy",
        args: "Polish;Default;Phonemic",
        expected: "ˈɡra.wɨ.bɨɕ.mɨ",
      },
    ];
    testCases(tests);
  });

  describe("Ancient Greek", function () {
    before(async function () {
      await loadLanguage("grc");
    });
    const tests = [
      {
        text: "ἀρχιμανδρῑ́της",
        args: "Greek;15th CE Constantinopolitan;Phonetic",
        expected: "ar.çi.manˈdri.tis",
      },
      {
        text: "κέλευσμα",
        args: "Greek;15th CE Constantinopolitan;Phonetic",
        expected: "ˈce.levz.ma",
      },
    ];
    testCases(tests);
  });
});
