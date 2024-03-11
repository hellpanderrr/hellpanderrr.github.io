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

async function testLanguage(language_code, cases) {
  await loadLanguage(language_code);

  cases.map(function (c) {
    console.warn(
      c.text,
      c.args,
      c.expected,
      get_ipa_no_cache(c.text, c.args).value,
    );
    if (c.expected != get_ipa_no_cache(c.text, c.args).value) {
      console.warn(
        "FAIL",
        c.text,
        c.args,
        c.expected,
        get_ipa_no_cache(c.text, c.args).value,
      );
    }
  });
}

(async function testRunner() {
  await (await import("./init.js")).default();

  const cases_la = [
    {
      text: "provinciarum",
      args: "Latin;Ecc;Phonemic",
      expected: "pro.vinˈt͡ʃi.a.rum",
      lang_code: "la",
    },
    {
      text: "provinciarum",
      args: "Latin;Ecc;Phonetic",
      expected: "provin̠ʲˈt͡ʃiːärum",
      lang_code: "la",
    },
    {
      text: "provinciarum",
      args: "Latin;Classical;Phonemic",
      expected: "pro.u̯inˈki.a.rum",
      lang_code: "la",
    },
    {
      text: "provinciarum",
      args: "Latin;Classical;Phonetic",
      expected: "prou̯ɪŋˈkiärʊ̃ˑ",
      lang_code: "la",
    },
  ];
  await testLanguage("la", cases_la);

  const cases_de = [
    {
      text: "aufeinanderzupassende",
      args: "German;Default;Phonemic",
      expected: "aʊ̯f(ʔ)aɪ̯ˈnandɐt͡suˌpasəndə",
      lang_code: "de",
    },
    {
      text: "aufeinanderzupassende",
      args: "German;Default;Phonetic",
      expected: "ʔaʊ̯f(ʔ)aɪ̯ˈnan.dɐt͡sʰuˌpʰa.sn̩.də",
      lang_code: "de",
    },
  ];

  await testLanguage("de", cases_de);
})();
