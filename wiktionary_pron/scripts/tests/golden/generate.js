/**
 * Golden-file generator. Run from scripts/tests/:
 *   node golden/generate.js
 *
 * Loads every language engine in Node (no lexicons — this exercises the pure
 * Lua-rules path) and records get_ipa_no_cache() output for a fixed word list.
 * Review the diff before committing: a change means engine behavior changed.
 */
import "../setup.cjs";
import { writeFileSync } from "node:fs";
import { fileURLToPath } from "node:url";
import { dirname, join } from "node:path";

const initTest = (await import("../init.js")).default;
await initTest();
const { get_ipa_no_cache } = await import("../../utils.js");

async function loadLanguage(code) {
  const lua = global.window.lua;
  await lua.doString(`${code} = require("${code}-pron_wasm")`);
  global.window[code + "_ipa"] = lua.global.get(code);
}

// lang → { codes: lua module code, cases: [args, [words]] }
const PLAN = {
  Czech: { code: "cs", argsList: ["Czech;Default;Phonemic"], words: ["dobrý", "den", "přítel", "město", "hrad", "voda", "čeština"] },
  Lithuanian: { code: "lt", argsList: ["Lithuanian;Default;Phonemic"], words: ["labas", "diena", "draugas", "miestas", "vanduo"] },
  Icelandic: { code: "is", argsList: ["Icelandic;Default;Phonemic"], words: ["góðan", "daginn", "vinur", "borg", "vatn"] },
  Belorussian: { code: "be", argsList: ["Belorussian;Default;Phonemic"], words: ["добры", "дзень", "горад", "вада"] },
  Bulgarian: { code: "bg", argsList: ["Bulgarian;Default;Phonemic"], words: ["добър", "ден", "приятел", "град", "вода"] },
  Mongolian: { code: "mn", argsList: ["Mongolian;Default;Phonemic"], words: ["сайн", "найз", "хот", "ус"] },
  Armenian: {
    code: "hy",
    argsList: ["Armenian;Eastern;Phonemic", "Armenian;Western;Phonemic"],
    words: ["բարեւ", "ընկեր", "քաղաք", "ջուր"],
  },
  Russian: { code: "ru", argsList: ["Russian;Default;Phonetic"], words: ["вода́", "стол", "кни́га", "дом"] },
  Ukrainian: { code: "uk", argsList: ["Ukrainian;Default;Phonetic"], words: ["вода́", "стіл", "кни́га", "дім"] },
  Portuguese: {
    code: "pt",
    argsList: ["Portuguese;Brazil;Phonetic", "Portuguese;Portugal;Phonemic"],
    words: ["obrigado", "cidade", "água", "amigo"],
  },
};

// Languages whose Lua modules are known not to load under the Node shim.
// Anything else failing to load is a regression — fail generation loudly
// instead of silently dropping the language from golden.json.
const NODE_UNSUPPORTED = new Set(["Czech"]);

const golden = {};
for (const [lang, { code, argsList, words }] of Object.entries(PLAN)) {
  process.stderr.write(`Loading ${lang} (${code})...\n`);
  try {
    await loadLanguage(code);
  } catch (e) {
    if (!NODE_UNSUPPORTED.has(lang)) {
      throw new Error(`${lang} module failed to load: ${e.message}`);
    }
    process.stderr.write(`  SKIPPED (known Node-unsupported): ${e.message}\n`);
    continue;
  }
  golden[lang] = [];
  for (const args of argsList) {
    for (const text of words) {
      let value, status;
      try {
        ({ value, status } = get_ipa_no_cache(text, args));
      } catch (e) {
        value = `THROWS: ${e.message}`;
        status = "throws";
      }
      golden[lang].push({ text, args, status, value });
      process.stderr.write(`  ${args} ${text} -> [${status}] ${value}\n`);
    }
  }
}

const out = join(dirname(fileURLToPath(import.meta.url)), "golden.json");
writeFileSync(out, JSON.stringify(golden, null, 2) + "\n");
process.stderr.write(`\nWrote ${out}\n`);
process.exit(0);
