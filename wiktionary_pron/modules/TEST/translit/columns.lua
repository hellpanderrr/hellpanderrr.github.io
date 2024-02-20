local export = {}

local html = mw.html.create
local m_links = require("links")
local m_languages = require("languages")
local m_table = require("table")


local function format_list_items(list, args)
	local function term_already_linked(term)
		-- FIXME: "<span" is an ugly hack to prevent double-linking of terms already run through {{l|...}}:
		-- [[Thread:User talk:CodeCat/MewBot adding lang to column templates]]
		return term:find("<span")
	end
	for _, item in ipairs(args.content) do
		if item == false then
			-- omitted item; do nothing
		else
			if type(item) == "table" then
				local link = term_already_linked(item.term.term) and item.term.term or m_links.full_link(item.term)
				if item.q then
					link = require("qualifier").format_qualifier(item.q) .. " " .. link
				end
				if item.qq then
					link = link .. " " .. require("qualifier").format_qualifier(item.qq)
				end
				item = link
			elseif args.lang and not term_already_linked(item) then
				item = m_links.full_link {lang = args.lang, term = item, sc = args.sc} 
			end
	
			list = list:node(html("li")
				:wikitext(item)
			)
		end
	end

	return list
end

function export.create_list(args)
	-- Fields in args that are used:
	-- args.column_count, args.content, args.alphabetize, args.background_color,
	-- args.collapse, args.toggle_category, args.class, args.lang
	-- Check for required fields?
	if type(args) ~= "table" then
		error("expected table, got " .. type(args))
	end

	local class = args.class or "derivedterms"
	local column_count = args.column_count or 1
	local toggle_category = args.toggle_category or "derived terms"
	local header = args.header

	if header and args.format_header then
		header = html("div")
			:addClass("term-list-header")
			:wikitext(header)
	end

	if args.alphabetize then
		local function keyfunc(item)
			if item == false then
				item = "*" -- doesn't matter, will be omitted in format_list_items()
			elseif type(item) == "table" then
				item = item.term.alt or item.term.term
			end
			return item
		end
		require("collation").sort(args.content, args.lang, keyfunc)
	end

	local list = html("ul")
	list = format_list_items(list, args)

	local output = html("div")
		:addClass(class)
		:addClass("term-list")
		:addClass("ul-column-count")
		:attr("data-column-count", column_count)
		:css("background-color", args.background_color)
		:node(list)

	if args.collapse then
		local nbsp = mw.ustring.char(0xA0)
		output = html("div")
			:node(output)
			:addClass("list-switcher")
			:attr("data-toggle-category", toggle_category)
			:node(html("div")
				:addClass("list-switcher-element")
				:attr("data-showtext", nbsp .. "show more ▼" .. nbsp)
				:attr("data-hidetext", nbsp .. "show less ▲" .. nbsp)
				:css("display", "none")
				:wikitext(nbsp)
			)
	end

	return tostring(header or "") .. tostring(output)
end


-- This function is for compatibility with earlier version of [[Module:columns]]
-- (now found in [[Module:columns/old]]).
function export.create_table(...)
	-- Earlier arguments to create_table:
	-- n_columns, content, alphabetize, bg, collapse, class, title, column_width, line_start, lang
	local args = {}
	args.column_count, args.content, args.alphabetize, args.background_color,
		args.collapse, args.class, args.header, args.column_width,
		args.line_start, args.lang = ...

	args.format_header = true

	return export.create_list(args)
end


local param_mods = {"t", "alt", "tr", "ts", "pos", "lit", "id", "sc", "g", "q", "qq"}
local param_mod_set = m_table.listToSet(param_mods)

function export.display_from(frame_args, parent_args, frame)
	local iparams = {
		["class"] = {},
		-- Default for auto-collapse. Overridable by template |collapse= param.
		["collapse"] = {type = "boolean"},
		-- If specified, this specifies the number of columns, and no columns
		-- parameter is available on the template. Otherwise, the columns
		-- parameter is the first available numbered param after the language-code
		-- parameter.
		["columns"] = {type = "number"},
		-- If specified, this specifies the language code, and no language-code
		-- parameter is available on the template. Otherwise, the language-code
		-- parameter can be specified as either |lang= or |1=.
		["lang"] = {},
		-- Default for auto-sort. Overridable by template |sort= param.
		["sort"] = {type = "boolean"},
		-- The following is accepted but currently ignored, per an extended discussion in
		-- [[Wiktionary:Beer parlour/2018/November#Titles of morphological relations templates]].
		["title"] = {default = ""},
		["toggle_category"] = {},
	}

	local iargs = require("parameters").process(frame_args, iparams, nil, "columns", "display_from")

	local compat = iargs["lang"] or parent_args["lang"]
	local lang_param = compat and "lang" or 1
	local columns_param, first_content_param

	-- New-style #columns specification is through parameter n= so we can transition to the situation where
	-- omitting it results in auto-determination. Old-style #columns specification is through the first numbered
	-- parameter after the lang parameter.
	if parent_args["n"] then
		columns_param = "n"
		first_content_param = compat and 1 or 2
	else
		columns_param = compat and 1 or 2
		first_content_param = columns_param + (iargs["columns"] and 0 or 1)
	end
	local deprecated

	local params = {
		[lang_param] = not iargs["lang"] and {required = true, default = "und"} or nil,
		[columns_param] = not iargs["columns"] and {required = true, default = 2} or nil,
		[first_content_param] = {list = true},

		["title"] = {},
		["collapse"] = {type = "boolean"},
		["sort"] = {type = "boolean"},
		["sc"] = {},
		["omit"] = {list = true}, -- used when calling from [[Module:saurus]] so the page displaying the synonyms/antonyms doesn't occur in the list
	}

	if lang_param == "lang" then
		deprecated = true
	end

	local args = require("parameters").process(parent_args, params, nil, "columns", "display_from")

	local langcode = iargs["lang"] or args[lang_param]
	local lang = m_languages.getByCode(langcode, lang_param)

	local sc = args["sc"] and require("scripts").getByCode(sc, "sc") or nil

	local sort = iargs["sort"]
	if args["sort"] ~= nil then
		sort = args["sort"]
	end
	local collapse = iargs["collapse"]
	if args["collapse"] ~= nil then
		collapse = args["collapse"]
	end
	
	local langs = {
		[langcode] = lang
	}
	local put
	for i, item in ipairs(args[first_content_param]) do
		-- Parse off an initial language code (e.g. 'la:minūtia' or 'grc:[[σκῶρ|σκατός]]'). Don't parse if there's a spac
		-- after the colon (happens e.g. if the user uses {{desc|...}} inside of {{col}}, grrr ...).
		local termlangcode, actual_term = item:match("^([%w%-.]+):([^ ].*)$")
		local termlang
		-- Make sure that only real language codes are handled as language links, so as to not catch interwiki
		-- or namespaces links.
		if termlangcode then
			termlang = langs[termlangcode]
			if termlang == nil then
				termlang = m_languages.getByCode(termlangcode, nil, "allow etym")
				if termlang then
					langs[termlangcode] = termlang
				else
					-- Memoize false positives so that we don't try them again.
					langs[termlangcode] = false
				end
			end
		end
		if not termlang then
			termlang = lang
			termlangcode = nil
		else
			item = actual_term
		end
		local termobj = {term = {lang = termlang, sc = sc}}

		-- Check for inline modifier, e.g. מרים<tr:Miryem>. But exclude HTML entry with <span ...>, <i ...>, <br/> or
		-- similar in it, caused by wrapping an argument in {{l|...}}, {{af|...}} or similar. Basically, all tags of
		-- the sort we parse here should consist of a less-than sign, plus letters, plus a colon, e.g. <tr:...>, so if
		-- we see a tag on the outer level that isn't in this format, we don't try to parse it. The restriction to the
		-- outer level is to allow generated HTML inside of e.g. qualifier tags, such as foo<q:similar to {{m|fr|bar}}>.
		if item:find("<") and not item:find("^[^<]*<[a-z]*[^a-z:]") then
			if not put then
				put = require("parse utilities")
			end
			local run = put.parse_balanced_segment_run(item, "<", ">")
			local orig_param = first_content_param + i - 1
			local function parse_err(msg)
				error(msg .. ": " .. orig_param .. "= " .. table.concat(run))
			end
			termobj.term.term = run[1]

			for j = 2, #run - 1, 2 do
				if run[j + 1] ~= "" then
					parse_err("Extraneous text '" .. run[j + 1] .. "' after modifier")
				end
				local modtext = run[j]:match("^<(.*)>$")
				if not modtext then
					parse_err("Internal error: Modifier '" .. modtext .. "' isn't surrounded by angle brackets")
				end
				local prefix, arg = modtext:match("^([a-z]+):(.*)$")
				if not prefix then
					parse_err("Modifier " .. run[j] .. " lacks a prefix, should begin with one of '" ..
						table.concat(param_mods, ":', '") .. ":'")
				end
				if param_mod_set[prefix] then
					local obj_to_set
					if prefix == "q" or prefix == "qq" then
						obj_to_set = termobj
					else
						obj_to_set = termobj.term
					end
					if prefix == "t" then
						prefix = "gloss"
					elseif prefix == "g" then
						prefix = "genders"
						arg = mw.text.split(arg, ",")
					elseif prefix == "sc" then
						arg = require("scripts").getByCode(arg, orig_param .. ":sc")
					end
					if obj_to_set[prefix] then
						parse_err("Modifier '" .. prefix .. "' occurs twice, second occurrence " .. run[j])
					end
					obj_to_set[prefix] = arg
				else
					parse_err("Unrecognized prefix '" .. prefix .. "' in modifier " .. run[j])
				end
			end
		else
			termobj.term.term = item
		end
		-- If a separate language code was given for the term, display the language name as a right qualifier.
		-- Otherwise it may not be obvious that the term is in a separate language (e.g. if the main language is 'zh'
		-- and the term language is a Chinese lect such as Min Nan). But don't do this for Translingual terms, which
		-- are often added to the list of English and other-language terms.
		if termlangcode and termlangcode ~= langcode and termlangcode ~= "mul" then
			termobj.qq = {termlang:getCanonicalName(), termobj.qq}
		end

		local omitted = false
		for _, omitted_item in ipairs(args.omit) do
			if omitted_item == termobj.term.term then
				omitted = true
				break
			end
		end
		if omitted then
			-- signal create_list() to omit this item
			args[first_content_param][i] = false
		else
			args[first_content_param][i] = termobj
		end
	end

	local ret = export.create_list { column_count = iargs["columns"] or args[columns_param],
		content = args[first_content_param],
		alphabetize = sort,
		header = args["title"], background_color = "#F8F8FF",
		collapse = collapse,
		toggle_category = iargs["toggle_category"],
		class = iargs["class"], lang = lang, sc = sc, format_header = true }

	return deprecated and frame:expandTemplate{title = "check deprecated lang param usage", args = {ret, lang = args[lang_param]}} or ret
end

function export.display(frame)
	return export.display_from(frame.args, frame:getParent().args, frame)
end

return export