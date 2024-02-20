local codepoint = mw.ustring.codepoint
local decode = mw.text.decode
local trim = mw.text.trim
local type = type
local u = mw.ustring.char
local unstripNoWiki = mw.text.unstripNoWiki

local data = mw.loadData("utilities/data")

local export = {}

function export.require_when_needed(text)
	return setmetatable({}, {
		__index = function(t, k)
			t = require(text)
			return t[k]
		end,
		__call = function(t, ...)
			t = require(text)
			return t(...)
		end
	})
end

-- A helper function to escape magic characters in a string.
-- Magic characters: ^$()%.[]*+-?
function export.pattern_escape(text)
	if type(text) == "table" then
		text = text.args[1]
	end
	return (text:gsub("[%^$()%%.[%]*+%-?]", "%%%0"))
end

-- Converts decimal to hexadecimal.
-- Note: About three times as fast as the hex library.
function export.dec_to_hex(dec)
	dec = tonumber(dec)
	if not dec or dec % 1 ~= 0 then
		error("Input should be a decimal integer.")
	end
	return ("%x"):format(dec):upper()
end

-- A helper function to resolve HTML entities into plaintext.
do
	local entities
	
	local function get_named_entity(entity)
		entities = entities or mw.loadData("data/entities")
		return entities[entity]
	end
	
	-- Catches entities with capital X, which aren't supported by default.
	local function get_numbered_entity(entity)
		entity = entity:lower()
		local ret = decode(entity)
		if ret ~= entity then
			return ret
		end
	end
		
	function export.get_entities(text)
		return (text:gsub("&([^#&;]+);", get_named_entity)
			:gsub("&#[Xx]?%x+;", get_numbered_entity)
		)
	end
end

-- A helper function to convert plaintext into HTML entities where these match the characters given in set.
-- By default, this resolves any pre-existing entities into plaintext first, to allow mixed input and to avoid accidental double-conversion. This can be turned off with the raw parameter.
function export.make_entities(text, set, raw)
	text = not raw and export.get_entities(text) or text
	set = set or "<>&\"'\194\160"
	return (text:gsub("[%z\1-\127\194-\244][\128-\191]*", function(m)
		if set:find(m, 1, true) then
			return "&#x" .. export.dec_to_hex(codepoint(m)) .. ";"
		end
	end))
end

do
	local function check_level(lvl)
		if type(lvl) ~= "number" then
			error("Heading levels must be numbers.")
		elseif lvl < 1 or lvl > 6 or lvl % 1 ~= 0 then
			error("Heading levels must be integers between 1 and 6.")
		end
		return lvl
	end
	
	-- A helper function which iterates over the headings in `text`, which should be the content of a page or (main) section.
	-- Each iteration returns three values: `sec` (the section title), `lvl` (the section level) and `loc` (the index of the section in the given text, from the first equals sign). The section title will be automatically trimmed, and any HTML entities will be resolved.
	-- The optional parameter `a` (which should be an integer between 1 and 6) can be used to ensure that only headings of the specified level are iterated over. If `b` is also given, then they are treated as a range.
	-- The optional parameters `a` and `b` can be used to specify a range, so that only headings with levels in that range are returned. If only `a` is given
	function export.find_headings(text, a, b)
		a = a and check_level(a) or nil
		b = b and check_level(b) or a or nil
		local start, loc, lvl, sec = 1
		
		local function iterate()
			loc, lvl, sec, start = text:match("()%f[^%z\n\r](=+)([^\n\r]+)%2[\t ]*%f[%z\n\r]()", start)
			if not loc then
				return
			end
			lvl = #lvl
			if lvl > 6 then
				local excess = ("="):rep(lvl - 6)
				sec = excess .. sec .. excess
				lvl = 6
			end
			return sec, lvl, loc
		end
		
		return function()
			repeat
				iterate()
			until not (sec and a) or (lvl >= a and lvl <= b)
			return sec and trim(export.get_entities(sec)) or nil, lvl, loc
		end
	end
	
	local function get_section(content, name, level)
		if not (content and name) then
			return nil
		elseif name:match("[\n\r]") then
			error("Heading name cannot contain a newline.")
		end
		level = level and check_level(level) or nil
		name = trim(export.get_entities(name))
		local start
		for sec, lvl, loc in export.find_headings(content, level and 1 or nil, level) do
			if start and lvl <= level then
				return content:sub(start, loc - 1)
			elseif not start and (not level or lvl == level) and sec == name then
				start = loc
				level = lvl
			end
		end
		return start and content:sub(start)
	end
	
	-- A helper function to return the content of a page section.
	-- `content` is raw wikitext, `name` is the requested section, and `level` is an optional parameter that specifies the required section heading level. If `level` is not supplied, then the first section called `name` is returned.
	-- `name` can either be a string or table of section names. If a table, each name represents a section that has the next as a subsection. For example, {"Spanish", "Noun"} will return the first matching section called "Noun" under a section called "Spanish". These do not have to be at adjacent levels ("Noun" might be L4, while "Spanish" is L2). If `level` is given, it refers to the last name in the table (i.e. the name of the section to be returned).
	-- The returned section includes all of its subsections.
	-- If no matching section is found, returns nil.
	function export.get_section(content, names, level)
		if type(names) == "string" then
			return get_section(content, names, level)
		end
		local names_len = #names
		if names_len > 6 then
			error("Not possible specify more than 5 subsections: headings only go up to level 6.")
		end
		for i, name in ipairs(names) do
			content = get_section(content, name, i == names_len and level or nil)
		end
		return content
	end
end

-- A function which returns the number of the page section which contains the current #invoke.
do
	local function _section(frame, offset, h)
		frame:extensionTag("nowiki", "HEADING\1" .. offset)
		return h - offset
	end
	
	local i = 0
	function export.get_current_section()
		local frame = mw.getCurrentFrame()
		-- Headings have to be unique, or they get assigned an old value.
		local h = tonumber(frame:preprocess("=" .. u(0xF0000 + i) .. "=", ""):match("%d+"))
		-- For some reason, [[Special:ExpandTemplates]] doesn't generate the strip marker, so if that happens we simply abort early.
		if not h then
			return 0
		end
		i = i + 1
		local n = tonumber(frame:extensionTag("nowiki", ""):match("[%dA-F]+"), 16)
		while n > 0 do
			n = n - 1
			local offset = unstripNoWiki(("\127'\"`UNIQ--nowiki-%08X-QINU`\"'\127"):format(n))
				:match("HEADING\1(%d+)")
			if offset then
				return _section(frame, offset + 1, h)
			end
		end
		return _section(frame, 0, h)
	end
end

-- A function which returns the name of the L2 language section which contains the current #invoke.
function export.get_current_L2()
	local section = export.get_current_section()
	if section == 0 then
		return nil
	end
	local page_L2s, L2 = mw.loadData("headword/data").page_L2s
	repeat
		L2 = page_L2s[section]
		if L2 then
			return L2
		end
		section = section - 1
	until section == 0
end

-- A helper function to strip wiki markup, giving the plaintext of what is displayed on the page.
function export.get_plaintext(text)
	text = text
		:gsub("%[%[", "\1")
		:gsub("%]%]", "\2")
	
	-- Remove strip markers and HTML tags.
	text = mw.text.unstrip(text)
		:gsub("<[^<>\1\2]+>", "")
		
	-- Parse internal links for the display text, and remove categories.
	text = require("links").remove_links(text)
	
	-- Remove files.
	for _, falsePositive in ipairs({"File", "Image"}) do
		text = text:gsub("\1" .. falsePositive .. ":[^\1\2]+\2", "")
	end

	-- Parse external links for the display text.
	text = text:gsub("%[(https?://[^%[%]]+)%]",
		function(capture)
			return capture:match("https?://[^%s%]]+%s([^%]]+)") or ""
		end)
	
	text = text
		:gsub("\1", "[[")
		:gsub("\2", "]]")
	
	-- Any remaining square brackets aren't involved in links, but must be escaped to avoid creating new links.
	text = text:gsub("[%[%]]", mw.text.nowiki)
		
	-- Strip bold, italics and soft hyphens.
	text = text
		:gsub("('*)'''(.-'*)'''", "%1%2")
		:gsub("('*)''(.-'*)''", "%1%2")
		:gsub("­", "")
	
	-- Get any HTML entities.
	-- Note: don't decode URL percent encoding, as it shouldn't be used in display text and may cause problems if % is used.
	text = export.get_entities(text)
	
	return trim(text)
end

function export.plain_gsub(text, pattern, replacement)
	local invoked = false
	
	if type(text) == "table" then
		invoked = true
		
		if text.args then
			local frame = text
			
			local params = {
				[1] = {},
				[2] = {},
				[3] = { allow_empty = true },
			}
			
			local args = require("parameters").process(frame.args, params, nil, "utilities", "plain_gsub")
			
			text = args[1]
			pattern = args[2]
			replacement = args[3]
		else
			error("If the first argument to plain_gsub is a table, it should be a frame object.")
		end
	else
		if not ( type(pattern) == "string" or type(pattern) == "number" ) then
			error("The second argument to plain_gsub should be a string or a number.")
		end
		
		if not ( type(replacement) == "string" or type(replacement) == "number" ) then
			error("The third argument to plain_gsub should be a string or a number.")
		end
	end
	
	pattern = export.pattern_escape(pattern)
	
	local gsub = require("string utilities").gsub
	if invoked then
		return (gsub(text, pattern, replacement))
	else
		return gsub(text, pattern, replacement)
	end
end

--[[
Format the categories with the appropriate sort key. CATEGORIES is a list of
categories.
	-- LANG is an object encapsulating a language; if nil, the object for
		language code 'und' (undetermined) will be used.
	-- SORT_KEY is placed in the category invocation, and indicates how the
		page will sort in the respective category. Normally this should be nil,
		and a default sort key based on the subpage name (the part after the
		colon) will be used.
	-- SORT_BASE lets you override the default sort key used when SORT_KEY is
		nil. Normally, this should be nil, and a language-specific default sort
		key is computed from the subpage name (e.g. for Russian this converts
		Cyrillic ё to a string consisting of Cyrillic е followed by U+10FFFF,
		so that effectively ё sorts after е instead of the default Wikimedia
		sort, which (I think) is based on Unicode sort order and puts ё after я,
		the last letter of the Cyrillic alphabet.
	-- FORCE_OUTPUT forces normal output in all namespaces. Normally, nothing
		is output if the page isn't in the main, Appendix:, Reconstruction: or
		Citations: namespaces.
	-- SC is a script object; if nil, the default will be used from the sort
		base.
]]
function export.format_categories(categories, lang, sort_key, sort_base, force_output, sc)
	if type(lang) == "table" and not lang.getCode then
		error("The second argument to format_categories should be a language object.")
	end

	local title_obj = mw.title.getCurrentTitle()	
	local allowedNamespaces = {
		[0] = true, [100] = true, [110] = true, [114] = true, [118] = true -- (main), Appendix, Thesaurus, Citations, Reconstruction
	}

	if force_output or allowedNamespaces[title_obj.namespace] or title_obj.prefixedText == "Wiktionary:Sandbox" then
		local headword_data = mw.loadData("headword/data")
		local pagename = headword_data.pagename
		local pagename_defaultsort = headword_data.pagename_defaultsort
		
		-- Generate a default sort key.
		if sort_key ~= "-" then
			if not lang then
				lang = require("languages").getByCode("und")
			end
			sort_base = lang:makeSortKey(sort_base or pagename, sc)
			if sort_key and sort_key ~= "" then
				if lang:getCode() ~= "und" then
					if sort_key:uupper() == sort_base then
						table.insert(categories, lang:getNonEtymologicalName() .. " terms with redundant sortkeys")
					else
						table.insert(categories, lang:getNonEtymologicalName() .. " terms with non-redundant non-automated sortkeys")
					end
				end
			else
				sort_key = sort_base
			end
			-- If the sort key is empty, remove it.
			if sort_key == "" then
				sort_key = nil
			end
		-- If the sort key is "-", bypass the process of generating a sort key altogether. This is desirable when categorising (e.g.) translation requests, as the pages to be categorised are always in English/Translingual.
		else
			sort_key = sort_base and sort_base:uupper() or pagename_defaultsort
		end
		
		local out_categories = {}
		for key, cat in ipairs(categories) do
			out_categories[key] = "[[Category:" .. cat .. (sort_key and "|" .. sort_key or "") .. "]]"
		end
		
		return table.concat(out_categories, "")
	else
		return ""
	end
end

function export.catfix(lang, sc)
	if not lang or not lang.getCanonicalName then
		error('The first argument to the function "catfix" should be a language object from [[Module:languages]] or [[Module:etymology languages]].')
	end
	if sc and not sc.getCode then
		error('The second argument to the function "catfix" should be a script object from [[Module:scripts]].')
	end
	local canonicalName = lang:getCanonicalName()
	local nonEtymologicalName = lang:getNonEtymologicalName()

	-- To add script classes to links on pages created by category boilerplate templates.
	if not sc then
		sc = data.catfix_scripts[lang:getCode()] or data.catfix_scripts[lang:getNonEtymologicalCode()]
		if sc then
			sc = require("scripts").getByCode(sc)
		end
	end

	local catfix_class = "CATFIX-" .. mw.uri.anchorEncode(canonicalName)
	if nonEtymologicalName ~= canonicalName then
		catfix_class = catfix_class .. " CATFIX-" .. mw.uri.anchorEncode(nonEtymologicalName)
	end
	return "<span id=\"catfix\" style=\"display:none;\" class=\"" .. catfix_class .. "\">" ..
		require("script utilities").tag_text("&nbsp;", lang, sc, nil) ..
		"</span>"
end

function export.catfix_template(frame)
	local params = {
		[1] = {},
		[2] = { alias_of = "sc" },
		["sc"] = {},
	}
	
	local args = require("parameters").process(frame:getParent().args, params, nil, "utilities", "catfix_template")
	
	local lang = require("languages").getByCode(args[1], 1, "allow etym")
	
	local sc = args.sc
	if sc then
		sc = require("scripts").getByCode(sc, "sc")
	end
	
	return export.catfix(lang, sc)
end

function export.make_id(lang, str)
	--[[	If called with invoke, first argument is a frame object.
			If called by a module, first argument is a language object. ]]
	local invoked = false
	
	if type(lang) == "table" then
		if lang.args then
			invoked = true
			
			local frame = lang
			
			local params = {
				[1] = {},
				[2] = {},
			}
			
			local args = require("parameters").process(frame:getParent().args, params, nil, "utilities", "make_id")
			
			local langCode = args[1]
			str = args[2]
			
			local m_languages = require("languages")
			lang = m_languages.getByCode(langCode, 1, "allow etym")
		elseif not lang.getCanonicalName then
			error("The first argument to make_id should be a language object.")
		end
	end

	if not ( type(str) == "string" or type(str) == "number" ) then
		error("The second argument to make_id should be a string or a number.")
	end
	
	local id = require("senseid").anchor(lang, str)
	
	if invoked then
		return '<li class="senseid" id="' .. id .. '">'
	else
		return id
	end
end

-- Given a type (as a string) and an arbitrary number of entities, checks whether all of those entities are language, family, script, writing system or Wikimedia language objects. Useful for error handling in functions that require one of these kinds of object.
-- If noErr is set, the function returns false instead of throwing an error, which allows customised error handling to be done in the calling function.
function export.check_object(typ, noErr, ...)
	local function fail(message)
		if noErr then
			return false
		else
			error(message, 3)
		end
	end
	
	local objs = {...}
	if #objs == 0 then
		return fail("Must provide at least one object to check.")
	end
	for _, obj in ipairs{...} do
		if type(obj) ~= "table" or type(obj.hasType) ~= "function" then
			return fail("Function expected a " .. typ .. " object, but received a " .. type(obj) .. " instead.")
		elseif not (typ == "object" or obj:hasType(typ)) then
			for _, wrong_type in ipairs{"family", "language", "script", "Wikimedia language", "writing system"} do
				if obj:hasType(wrong_type) then
					return fail("Function expected a " .. typ .. " object, but received a " .. wrong_type .. " object instead.")
				end
			end
			return fail("Function expected a " .. typ .. " object, but received another type of object instead.")
		end
	end
	return true
end

return export