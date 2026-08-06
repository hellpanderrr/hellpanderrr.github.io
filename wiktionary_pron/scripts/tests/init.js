import { createRequire } from "module";
import { fileURLToPath } from "url";
import path from "path";

const require = createRequire(import.meta.url);
const fs = require("fs");

// Anchor the Lua module root to THIS file, not process.cwd(). The Lua shim fetches
// "../../lua_modules/..." and fs.readFile resolves relative paths against cwd, so the
// ipa suite silently depended on being run from scripts/tests. Resolve against the
// module's own location instead — makes the suite cwd-independent (coverage runs it
// from the repo root).
const LUA_ROOT = fileURLToPath(new URL("../../lua_modules/", import.meta.url));
function resolveLua(p) {
  // Lua fetches "../../lua_modules/<rest>"; strip the prefix so the rest resolves
  // against LUA_ROOT (which already ends in lua_modules/).
  return path.resolve(LUA_ROOT, p.replace(/^\.\.\/\.\.\/lua_modules\//, ""));
}

export default async function test() {
  const { LuaFactory } = require("wasmoon");
  const factory = new LuaFactory();
  const lua = await factory.createEngine();

  function fetch(path) {
    const full = path.startsWith("..") ? resolveLua(path) : path;
    return new Promise((resolve, reject) =>
      fs.readFile(full, (err, data) => (err ? reject(err) : resolve(data))),
    );
  }

  // Set a JS function to be a global lua function
  lua.global.set("fetch", (url) => fetch(url));

  async function mountFile(file_path, lua_path) {
    console.log(file_path);
    const x = await fetch(file_path).then((data) => data);
    await factory.mountFile(lua_path, x);
  }

  await mountFile(resolveLua("../../lua_modules/memoize.lua"), "memoize.lua");

  await lua.doString(`
          memoize = require('memoize')
          function require(path, extension)
              extension = extension or 'lua'
              if select(2,string.gsub(path, "%.", "")) > 0 then
                   new_path = string.gsub(path,"%.", "/",1)
                   print('replacing ', path,'->', new_path)
                   path = new_path
              end
              local resp = fetch(string.format('../../lua_modules/%s.%s',path,extension) ):await()
              resp = tostring(resp)
              local module =  load(resp)()
              return module
          end

          require = memoize(require)
          require('debug/track')
          require('ustring/charsets')
          require('ustring/lower')
          require('mw-title')
          mw = require('mw')
        `);
  global["window"] = {};
  global["window"]["lua"] = lua;
}
