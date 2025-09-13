import {
  fetchWithCache,
  fetchWithCacheMultiple,
  updateLoadingText,
} from "./utils.js";

const factory = await lb.factory;
const lua = await factory.createEngine();

// Set a JS function to be a global lua function

lua.global.set("fetch", (url) => fetchWithCache(url));
lua.global.set("fetchMultiple", (url) => fetchWithCacheMultiple(url));

async function mountFile(file_path, lua_path) {
  const content = await fetch(file_path).then((data) => data.text());
  await factory.mountFile(lua_path, content);
}

lua.global.set("updateLoadingText", (file_path, extension) =>
  updateLoadingText(file_path, extension),
);

await mountFile("../wiktionary_pron/lua_modules/memoize.lua", "memoize.lua");
//await mountFile("lua_modules/memoize.lua", "memoize.lua");

await lua.doString(`
          memoize = require('memoize')
          t = {}
          function require(path, extension)
              extension = extension or 'lua'
              print('     required '..path,'from:', debug.getinfo(2).name)
              table.insert(t, 'lua_modules'..string.char(92)..path)
              if select(2,string.gsub(path, "%.", "")) > 0 then
                   new_path = string.gsub(path,"%.", "/",1)
                   print('replacing ', path,'->', new_path)
                   path = new_path
              end
              
              
              updateLoadingText(path, extension)
             
             resp = fetch(string.format('../wiktionary_pron/lua_modules/%s.%s',path,extension)):await()
             
            
              
              updateLoadingText("", "")
              
              local text = resp:text():await()
              local module =  load(text)()
              print('    loaded '..path)
              return module
          end



          require = memoize(require)
          require('debug/track')
          require('ustring/charsets')
          require('ustring/lower')
          require('mw-title')
          mw = require('mw')
        `);
console.log(lua);

async function loadLanguage(code) {
  console.log(lua);

  await lua.doString(`t = {}
  ${code} = require("${code}-pron_wasm")`);
  // Get a global lua function as a JS function
  window[code + "_ipa"] = lua.global.get(code);
  // Set a JS function to be a global lua function
}

export { loadLanguage, updateLoadingText };
