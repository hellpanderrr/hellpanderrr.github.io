-- Irish G2P adapter for wiktionary_pron.
-- Exports transcribe(word, dialect) for JS window.ga_ipa.transcribe().
--
-- Pre-warms ustring's lazy sub-modules (normalization-data, etc.) by forcing
-- a dummy toNFC at init time.  This ensures the lazy require inside the
-- ustring code fires inside the doString coroutine where :await() is legal,
-- not from a JS→Lua callback where yielding is blocked.
local export = {}
mw = require('mw')
mw.ustring = require('ustring.ustring')

-- Pre-warm: force ustring.lua's lazy sub-module loads (normalization-data,
-- upper, charsets) via a dummy NFC call with a non-ASCII character.
mw.ustring.toNFC("á")

-- Requiring the engine also eager-loads the lex_subs tables (see the
-- module-scope pcall(require, ...) block in ga-irish_engine.lua), so they too
-- are resolved inside the doString coroutine rather than from a JS callback.
local engine = require('ga-irish_engine')

export.transcribe = engine.transcribe

function export.show(frame)
  local args = frame:getParent().args
  local word = args[1] or mw.title.getCurrentTitle().text
  local dialect = args.dialect or 'connacht'
  return engine.transcribe(word, dialect)
end

return export
