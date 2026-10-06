/**
 * Print real engine output for help-page examples. Run from scripts/tests/:
 *   node ipa_cli.mjs <Language> <Style> <Form> word1 word2 ...
 *   node ipa_cli.mjs --raw <code> <luaFunction> word1 ... [--extra '[true]']   (call the Lua export directly)
 * Lexicons are not loaded, so this shows the rule-based (Lua) path only.
 */
import "./setup.cjs";

const initTest = (await import("./init.js")).default;
await initTest();
const { get_ipa_no_cache } = await import("../utils.js");

const CODES = {
  Latin: "la", German: "de", Portuguese: "pt", Spanish: "es", French: "fr", Russian: "ru",
  Belorussian: "be", Polish: "pl", Bulgarian: "bg", Ukrainian: "uk", Lithuanian: "lt",
  Czech: "cs", Armenian: "hy", Greek: "grc", Icelandic: "is", Mongolian: "mn", Irish: "ga",
};

async function loadLanguage(code) {
  const lua = global.window.lua;
  await lua.doString(`${code} = require("${code}-pron_wasm")`);
  global.window[code + "_ipa"] = lua.global.get(code);
}

const args = process.argv.slice(2);
if (args[0] === "--raw") {
  let [, code, fn, ...words] = args;
  let extra = [];
  const ei = words.indexOf("--extra");
  if (ei !== -1) { extra = JSON.parse(words[ei + 1]); words.splice(ei, 2); }
  await loadLanguage(code);
  for (const w of words) {
    let out;
    try { out = global.window[code + "_ipa"][fn](w, ...extra); } catch (e) { out = `THROWS: ${e.message}`; }
    console.log(`RESULT\t${w}\t${typeof out === "object" ? JSON.stringify(out) : out}`);
  }
} else {
  const [lang, style, form, ...words] = args;
  await loadLanguage(CODES[lang]);
  for (const w of words) {
    let out;
    try { out = get_ipa_no_cache(w, `${lang};${style};${form}`).value; } catch (e) { out = `THROWS: ${e.message}`; }
    console.log(`RESULT\t${w}\t${out}`);
  }
}
process.exit(0);
