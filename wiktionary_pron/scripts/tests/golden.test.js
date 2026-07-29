/**
 * Golden-file regression tests: every language engine that runs under Node,
 * checked word-by-word against scripts/tests/golden/golden.json.
 *
 * If a failure here is an INTENDED engine change (e.g. you updated a Lua
 * module from Wiktionary), regenerate with:  node golden/generate.js
 * and review the golden.json diff before committing.
 */
import assert from "node:assert";
import { createRequire } from "node:module";

const require = createRequire(import.meta.url);
const golden = require("./golden/golden.json");

const LANG_CODES = {
  Czech: "cs",
  Lithuanian: "lt",
  Icelandic: "is",
  Belorussian: "be",
  Bulgarian: "bg",
  Mongolian: "mn",
  Armenian: "hy",
  Russian: "ru",
  Ukrainian: "uk",
  Portuguese: "pt",
  Irish: "ga",
};

let get_ipa_no_cache;

async function loadLanguage(code) {
  const lua = global.window.lua;
  await lua.doString(`${code} = require("${code}-pron_wasm")`);
  global.window[code + "_ipa"] = lua.global.get(code);
}

describe("golden files", function () {
  before(async function () {
    await (await import("./init.js")).default();
    ({ get_ipa_no_cache } = await import("../utils.js"));
  });

  for (const [lang, cases] of Object.entries(golden)) {
    describe(lang, function () {
      before(async function () {
        await loadLanguage(LANG_CODES[lang]);
      });

      for (const { text, args, status, value } of cases) {
        it(`${text} (${args}) -> ${value}`, function () {
          const res = get_ipa_no_cache(text, args);
          assert.strictEqual(res.status, status);
          assert.strictEqual(res.value, value);
        });
      }
    });
  }
});
