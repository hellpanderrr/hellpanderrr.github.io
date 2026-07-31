import {
  fetchWithCache,
  fetchWithCacheMultiple,
  updateLoadingText,
} from "./utils.js";

const factory = await lb.factory;
const lua = await factory.createEngine();

// Detect extension context: chrome.runtime.getURL exists only in extensions.
const isExtension = typeof chrome !== "undefined" && chrome.runtime && chrome.runtime.getURL;
const LUA_BASE = isExtension
  ? chrome.runtime.getURL("lua_modules/")
  : "../wiktionary_pron/lua_modules/";

// Mount initial Lua files from the right place
async function mountFile(file_path, lua_path) {
  const content = await fetch(file_path).then((data) => data.text());
  await factory.mountFile(lua_path, content);
}

// Set a JS function to be a global lua function.
// In the web app we use the HTTP-caching fetch; in the extension we use a
// direct fetch that resolves chrome-extension:// URLs.
lua.global.set("fetch", isExtension
  ? (url) => fetch(url)
  : (url) => fetchWithCache(url),
);
lua.global.set("fetchMultiple", isExtension
  ? (url) => fetch(url)
  : (url) => fetchWithCacheMultiple(url),
);

lua.global.set("updateLoadingText", (file_path, extension) =>
  updateLoadingText(file_path, extension),
);

await mountFile(isExtension
  ? chrome.runtime.getURL("lua_modules/memoize.lua")
  : "../wiktionary_pron/lua_modules/memoize.lua",
  "memoize.lua");

// The require shim Lua code is identical in both contexts; only the URL it
// passes to JS-side fetch() changes via LUA_BASE.
await lua.doString(`
          memoize = require('memoize')
          t = {}
          function require(path, extension)
              extension = extension or 'lua'
              table.insert(t, 'lua_modules'..string.char(92)..path)
              if select(2,string.gsub(path, "%.", "")) > 0 then
                   new_path = string.gsub(path,"%.", "/",1)
                   path = new_path
              end
              updateLoadingText(path, extension)
              resp = fetch('${LUA_BASE}' .. string.format('%s.%s',path,extension)):await()
              updateLoadingText("", "")
              local text = resp:text():await()
              local module =  load(text)()
              return module
          end
          require = memoize(require)
          require('debug/track')
          require('ustring/charsets')
          require('ustring/lower')
          require('mw-title')
          mw = require('mw')
        `);

async function loadLanguage(code) {
  await lua.doString(`t = {}
  ${code} = require("${code}-pron_wasm")`);
  window[code + "_ipa"] = lua.global.get(code);
}

export { loadLanguage, updateLoadingText };
