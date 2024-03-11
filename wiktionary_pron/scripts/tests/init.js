import { createRequire } from "module";

const require = createRequire(import.meta.url);
const fs = require("fs");

export default async function test() {
  const { LuaFactory } = require("wasmoon");
  const factory = new LuaFactory();
  const lua = await factory.createEngine();

  function fetch(path) {
    return new Promise((resolve, reject) =>
      fs.readFile(path, (err, data) => (err ? reject(err) : resolve(data))),
    );
  }

  // Set a JS function to be a global lua function
  lua.global.set("fetch", (url) => fetch(url));

  async function mountFile(file_path, lua_path) {
    console.log(file_path);
    const x = await fetch(file_path).then((data) => data);
    await factory.mountFile(lua_path, x);
  }

  await mountFile("../../modules/memoize.lua", "memoize.lua");

  await lua.doString(`
          memoize = require('memoize')
          function require(path, extension)
              extension = extension or 'lua'
              if select(2,string.gsub(path, "%.", "")) > 0 then
                   new_path = string.gsub(path,"%.", "/",1)
                   print('replacing ', path,'->', new_path)
                   path = new_path
              end
              local resp = fetch(string.format('../..//modules/%s.%s',path,extension) ):await()
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
