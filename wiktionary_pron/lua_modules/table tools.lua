local export = {}

local m_links = require("links")

local u = mw.ustring.char
local notes_ranges = {
  -- First three represent symbols in ISO-8859-1
  -- Including ÷ (U+00F7) × (U+00D7) § (U+00B7) ¤ (U+00A4)
  {0xA1,0xBF},
  {0xD7,0xD7}, -- ×
  {0xF7,0xF7}, -- ÷
  -- Next two are "General Punctuation" minus non-spacing chars
  -- First one includes † (U+2020) ‡ (U+2021) • (U+2022)  ※ (U+203B) ⁕ (U+2055)
  {0x2010,0x2027},
  {0x2030,0x205E},
  -- Next one is "Superscripts and Subscripts" and "Currency Symbols"
  {0x2070,0x20CF},
  -- Next one is a whole series of symbol ranges
  {0x2100,0x2B5F},
  -- Next one is "Supplemental Punctuation"
  {0x2E00,0x2E3F}
}

local unicode_ranges = {}
for _, range in ipairs(notes_ranges) do
  table.insert(unicode_ranges, u(range[1]) .. "-" .. u(range[2]))
end
local unicode_range_str = table.concat(unicode_ranges, "")
local notes_re = "[%*%~%@%#%$%%%^%&%+0-9_ " .. unicode_range_str .. "]*"

local function manipulate_entry(entries, f)
	entries = entries or ""
	entries = mw.text.split(mw.ustring.gsub(entries, "^%s*(.-)%s*$", "%1"), "%s*,%s*")
	
	local sep = ""
	local ret = ""
	
	for _, entry in ipairs(entries) do
		ret = ret .. sep .. (entry == "-" and "—" or entry == "" and "" or f(entry))
		sep = ", "
	end
	
	return ret
end

local function gather_args(frame)
	local args = {}
	for key, val in pairs(frame.args) do
		if val ~= "" then
			args[key] = val
		end
	end
	local i = 1
	for _, val in ipairs(frame:getParent().args) do
		if val and val ~= "" then
			while args[i] do
				i = i + 1
			end
			args[i] = val
			i = i + 1
		end
	end
	local lang = args["lang"]
	
	if not lang then
		lang = args[1]
		local n = 1
		while args[n] do
			args[n] = args[n + 1]
			n = n + 1
		end
	end
	
	return lang, args
end

function export.separate_notes(entry)
	local notes
	entry, notes = mw.ustring.match(entry, "^(.-)(" .. notes_re .. ")$")
	return entry, notes
end

function export.superscript_notes(notes)
	if notes ~= "" then
		notes = "<sup>" .. mw.ustring.gsub(notes, "_", " ") .. "</sup>"
	end
	return notes
end
	
function export.get_notes(entry)
	local notes
	entry, notes = export.separate_notes(entry)
	notes = export.superscript_notes(notes)	
	return entry, notes
end

function export.separate_initial_notes(entry)
	local notes
	notes, entry = mw.ustring.match(entry, "^(" .. notes_re .. ")(.*)$")
	return notes, entry
end
	
function export.get_initial_notes(entry)
	local notes
	notes, entry = export.separate_initial_notes(entry)
	notes = export.superscript_notes(notes)	
	return notes, entry
end

function export.linkify_entry(lang, entries, prep)
	if type(lang) == "table" then
		local args
		lang, args = gather_args(lang)
		if (args["prep"] or "") ~= "" then
			local mod, func = unpack(mw.text.split(args["prep"], "#", true))
			prep = require("" .. mod)[func]
		end
		entries = args[1]
	end
	lang = require("languages").getByCode(lang)
	
	local function f(entry)
		local e, notes = export.get_notes(entry)
		local ep = prep and prep(e)
		return m_links.language_link{lang = lang, term = ep or e, alt = ep and e} .. notes
	end
	
	return manipulate_entry(entries, f)
end

function export.translit_entry(lang, entries)
	if type(lang) == "table" then
		local args
		lang, args = gather_args(lang)
		entries = args[1]
	end
	lang = require("languages").getByCode(lang)

	local function f(entry)
		local e, notes = export.get_notes(entry)
		return ((lang:transliterate(e)) or e) .. notes
	end
	
	return manipulate_entry(m_links.remove_links(entries), f)
end

function export.format_entry(lang, entries)
	if type(lang) == "table" then
		local args
		lang, args = gather_args(lang)
		entries = args[1]
	end
	
	return manipulate_entry(m_links.remove_links(entries), function(entry) local e, n = export.get_notes(entry); return e .. n end)
end

function export.first_entry(lang, entries)
	if type(lang) == "table" then
		local args
		lang, args = gather_args(lang)
		entries = args[1]
	end

	local entry = mw.text.split(mw.ustring.gsub(entries, "^%s*(.-)%s*$", "%1"), "%s*,%s*")[1]
	
	local e, notes = export.get_notes(entry)
	return e .. notes
end

return export