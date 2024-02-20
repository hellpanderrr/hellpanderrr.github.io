local export = {}

local m_data = mw.loadData("typing-aids/data")
local reorderDiacritics = require("grc-utilities").reorderDiacritics
local format_link = require("template link").format_link
local listToSet = require("table").listToSet

--[=[
	Other data modules:
-- [[Module:typing-aids/data/ar]]
-- [[Module:typing-aids/data/fa]]
-- [[Module:typing-aids/data/gmy]]
-- [[Module:typing-aids/data/grc]]
-- [[Module:typing-aids/data/hit]]
-- [[Module:typing-aids/data/hy]]
-- [[Module:typing-aids/data/sa]]
-- [[Module:typing-aids/data/sux]]
-- [[Module:typing-aids/data/got]]
-- [[Module:typing-aids/data/inc-pra]]
--]=]

local U = mw.ustring.char
local gsub = mw.ustring.gsub
local find = mw.ustring.find

local acute = U(0x0301)
local macron = U(0x0304)

local function load_or_nil(module_name)
	local success, module = pcall(mw.loadData, module_name)
	if success then
		return module
	end
end

-- Try to load a list of modules. Return the first successfully loaded module
-- and its name.
local function get_module_and_title(...)
	for i = 1, select("#", ...) do
		local module_name = select(i, ...)
		if module_name then
			local module = load_or_nil(module_name)
			if module then
				return module, module_name
			end
		end
	end
end

local function clone_args(frame)
	local args = frame.getParent and frame:getParent().args or frame
	local newargs = {}
	for k, v in pairs(args) do
		if v ~= "" then
			newargs[k] = v
		end
	end
	return newargs
end
			
local function tag(text, lang)
	if lang and not find(lang, "%-tr$") then
		return '<span lang="' .. lang .. '">' .. text .. '</span>'
	else
		return text
	end
end

local acute_decomposer
-- compose Latin text, then decompose into sequences of letter and combining
-- accent, either partly or completely depending on the language.
local function compose_decompose(text, lang)
	if lang == "sa" or lang == "hy" or lang == "xcl" or lang == "kn" or lang == "inc-ash" or lang == "inc-pra" or lang == "omr" or lang == "mai" or lang == "saz" or lang == "sd" or lang == "mwr" or lang == "inc-pra-Knda" or lang == "inc-pra-Deva" or lang == "doi" or lang == "sa-Modi" or lang == "omr-Deva" then
		acute_decomposer = acute_decomposer or m_data.acute_decomposer
		text = mw.ustring.toNFC(text)
		text = gsub(text, ".", acute_decomposer)
	else
		text = mw.ustring.toNFD(text)
	end
	return text
end

local function do_one_replacement(text, from, to, before, after)
	-- FIXME! These won't work properly if there are any captures in FROM.
	if before then
		from = "(" .. before .. ")" .. from
		to = "%1" .. to
	end
	if after then
		from = from .. "(" .. after .. ")"
		to = to .. (before and "%2" or "%1")
	end
	text = gsub(text, from, to) -- discard second retval
	return text
end

local function do_key_value_replacement_table(text, tab)
	for from, repl in pairs(tab) do
		local to, before, after
		if type(repl) == "string" then
			to = repl
		else
			to = repl[1]
			before = repl.before
			after = repl.after
		end
		text = do_one_replacement(text, from, to, before, after)
	end
	-- FIXME, why is this being done here after each table?
	text = mw.text.trim(text)

	return text
end


local function do_replacements(text, repls)
	if repls[1] and repls[1][1] then
		-- new-style list
		for _, from_to in ipairs(repls) do
			text = do_one_replacement(text, from_to[1], from_to[2], from_to.before, from_to.after)
		end
		text = mw.text.trim(text)
	elseif repls[1] then
		for _, repl_table in ipairs(repls) do
			text = do_key_value_replacement_table(text, repl_table)
		end
	else
		text = do_key_value_replacement_table(text, repls)
	end

	return text
end


local function get_replacements(lang, script)
	local module_data = m_data.modules[lang]
	local replacements_module
	if not module_data then
		replacements_module = m_data
	else
		local success
		local resolved_name = "Module:typing-aids/data/"
			.. (module_data[1] or module_data[script] or module_data.default)
		replacements_module = load_or_nil(resolved_name)
		if not replacements_module then
			error("Data module " .. resolved_name
				.. " specified in 'modules' table of [[Module:typing-aids/data]] does not exist.")
		end
	end
	
	local replacements
	if not module_data then
		if lang then
			replacements = replacements_module[lang]
		else
			replacements = replacements_module.all
		end
	elseif module_data[2] then
		replacements = replacements_module[module_data[2]]
	else
		replacements = replacements_module
	end
	
	return replacements
end

local function interpret_shortcuts(text, origlang, script, untouchedDiacritics, moduleName)
	if not text or type(text) ~= "string" then
		return nil
	end

	local lang = origlang
	if lang == "xcl" then lang = "hy" end
	local replacements = moduleName and load_or_nil("Module:typing-aids/data/" .. moduleName)
		or get_replacements(lang, script)
		or error("The language code \"" .. tostring(origlang) ..
			"\" does not have a set of replacements in Module:typing-aids/data or its submodules.")
	
	-- Hittite transliteration must operate on composed letters, because it adds
	-- diacritics to Basic Latin letters: s -> š, for instance.
	if lang ~= "hit-tr" then
		text = compose_decompose(text, lang)
	end
	
	if lang == "ae" or lang == "sa" or lang == "got" or lang == "hy" or lang == "xcl" or lang == "kn" or lang == "inc-ash" or lang == "inc-pra" or lang == "pal" or lang == "sog" or lang == "xpr" or lang == "omr" or lang == "mai" or lang == "saz" or lang == "sd" or lang == "mwr" or lang == "inc-pra-Knda" or lang == "inc-pra-Deva" or lang == "doi" or lang == "sa-Modi" or lang == "omr-Deva" then
		local transliterationTable = get_replacements(lang .. "-tr")
			or script and get_replacements(script .. "-tr")
		
		if not transliterationTable then
			error("No transliteration table for " .. lang .. "-tr" .. (script and (" or " .. script .. "-tr") or " and no script has been provided"))
		end
		
		text = do_replacements(text, transliterationTable)
		
		text = compose_decompose(text, lang)
		
		text = do_replacements(text, replacements)
	else
		text = do_replacements(text, replacements)
		
		if lang == "grc" and not untouchedDiacritics then
			text = reorderDiacritics(text)
		end
	end
	
	return text
end

export.interpret_shortcuts = interpret_shortcuts

local function hyphen_separated_replacements(text, lang)
	local module = mw.loadData("typing-aids/data/" .. lang)
	local replacements = module[lang] or module
	if not replacements then
		error("??")
	end
	
	text = text:gsub("<sup>(.-)</sup>%-?", "%1-")
	
	if replacements.pre then
		for k, v in pairs(replacements.pre) do
			text = gsub(text, k, v)
		end
	end
	
	local output = {}
	-- Find groups of characters that aren't hyphens or whitespace.
	for symbol in text:gmatch("([^%-%s]+)") do
		table.insert(output, replacements[symbol] or symbol)
	end
	
	return table.concat(output)
end

local function add_parameter(list, args, key, content)
	if not content then content = args[key] end
	args[key] = nil
	if not content then return false end

	if find(content, "=") or type(key) == "string" then
		table.insert(list, key .. "=" .. content)
	else
		while list.maxarg < key - 1 do
			table.insert(list, "")
			list.maxarg = list.maxarg + 1
		end
		table.insert(list, content)
		list.maxarg = key
	end
	return true
end

local function add_and_convert_parameter(list, args, key, altkey1, altkey2, trkey, lang, scriptKey)
	if altkey1 and args[altkey1] then
		add_and_convert_parameter(list, args, key, nil, nil, nil, lang, scriptKey)
		key = altkey1
	elseif altkey2 and args[altkey2] then
		add_and_convert_parameter(list, args, key, nil, nil, nil, lang, scriptKey)
		key = altkey2
	end
	local content = args[key]
	if trkey and args[trkey] then
		if not content then
			content = args[trkey]
			args[trkey] = nil
		else
			if args[trkey] ~= "-" then
				error("Can't specify manual translit " .. trkey .. "=" ..
					args[trkey] .. " along with parameter " .. key .. "=" .. content)
			end
		end
	end
	if not content then return false end
	local trcontent = nil
	-- If Sanskrit or Prakrit or Kannada and there's an acute accent specified somehow or other
	-- in the source content, preserve the translit, which includes the
	-- accent when the Devanagari doesn't. 
	if lang == "sa" or lang == "kn" or lang == "inc-ash" or lang == "inc-pra" or lang == "omr" or lang == "mai" or lang == "saz" or lang == "sd" or lang == "mwr" or lang == "inc-pra-Knda" or lang == "inc-pra-Deva" or lang == "doi" or lang == "sa-Modi" or lang == "omr-Deva" then
		local proposed_trcontent = interpret_shortcuts(content, lang .. "-tr")
		if find(proposed_trcontent, acute) then
			trcontent = proposed_trcontent
		end
	end
	-- If Gothic and there's a macron specified somehow or other
	-- in the source content that remains after canonicalization, preserve
	-- the translit, which includes the accent when the Gothic doesn't.
	if lang == "got" then
		local proposed_trcontent = interpret_shortcuts(content, "got-tr")
		if find(proposed_trcontent, macron) then
			trcontent = proposed_trcontent
		end
	end
	
	--[[
	if lang == "gmy" then
		local proposed_trcontent = interpret_shortcuts(content, "gmy-tr")
		if find(proposed_trcontent, macron) then
			trcontent = proposed_trcontent
		end
	end
	--]]
	
	local converted_content
	if lang == "hit" or lang == "akk" then
		trcontent = interpret_shortcuts(content, lang .. "-tr")
		converted_content = hyphen_separated_replacements(content, lang)
	elseif lang == "sux" or lang == "gmy" then
		converted_content = hyphen_separated_replacements(content, lang)
	elseif lang == "pal" or lang == "sog" or lang == "xpr" then
		local script = args[scriptKey] or m_data.modules[lang].default
		local script_object = require "scripts".getByCode(script)
		local proposed_trcontent = interpret_shortcuts(content, script .. "-tr")
		local auto_tr = (require "languages".getByCode(lang)
			:transliterate(converted_content, script_object))
		if proposed_trcontent ~= auto_tr then
			trcontent = proposed_trcontent
		end
		converted_content = interpret_shortcuts(content, lang, script, nil, args.module)
	else
		converted_content = interpret_shortcuts(content, lang, args[scriptKey], nil, args.module)
	end
	
	add_parameter(list, args, key, converted_content)
	if trcontent then
		add_parameter(list, args, trkey, trcontent)
	end
	return true
end
	

local is_compound = listToSet{ "affix", "af", "compound", "com", "suffix", "suf", "prefix", "pre", "con", "confix", "surf" }
-- Technically lang, ux, and uxi aren't link templates, but they have many of the same parameters.
local is_link_template = listToSet{
	"m", "m+", "langname-mention", "l", "ll",
	"cog", "noncog", "cognate", "ncog", "nc", "noncognate", "cog+",
	"m-self", "l-self",
	"alter", "alt", "syn",
	"alt sp", "alt form",
	"alternative spelling of", "alternative form of",
	"desc", "desctree", "lang", "usex", "ux", "uxi"
}
local is_two_lang_link_template = listToSet{ "der", "inh", "bor", "slbor",  "lbor", "calque", "cal", "translit", "inh+", "bor+" }
local is_trans_template = listToSet{ "t", "t+", "t-check", "t+check" }

local function print_template(args)
	local parameters = {}
	for key, value in pairs(args) do
		parameters[key] = value
	end
	
	local template = parameters[1]
	
	local result = { }
	local lang = nil
	result.maxarg = 0
	
	add_parameter(result, parameters, 1)
	lang = parameters[2]
	add_parameter(result, parameters, 2)
	if is_link_template[template] then
		add_and_convert_parameter(result, parameters, 3, "alt", 4, "tr", lang, "sc")
		for _, param in ipairs({ 5, "gloss", "t" }) do
			add_parameter(result, parameters, param)
		end
	elseif is_two_lang_link_template[template] then
		lang = parameters[3]
		add_parameter(result, parameters, 3)
		add_and_convert_parameter(result, parameters, 4, "alt", 5, "tr", lang, "sc")
		for _, param in ipairs({ 6, "gloss", "t" }) do
			add_parameter(result, parameters, param)
		end
	elseif is_trans_template[template] then
		add_and_convert_parameter(result, parameters, 3, "alt", nil, "tr", lang, "sc")
		local i = 4
		while true do
			if not parameters[i] then
				break
			end
			add_parameter(result, parameters, i)
		end
	elseif is_compound[template] then
		local i = 1
		while true do
			local sawparam = add_and_convert_parameter(result, parameters, i + 2, "alt" .. i, nil, "tr" .. i, lang, "sc")
			if not sawparam then
				break
			end
			for _, param in ipairs({ "id", "lang", "sc", "t", "pos", "lit" }) do
				add_parameter(result, parameters, param .. i)
			end
			i = i + 1
		end
	else
		error("Unrecognized template name '" .. template .. "'")
	end
	-- Copy any remaining parameters
	for k in pairs(parameters) do
		add_parameter(result, parameters, k)
	end
	return "{{" .. table.concat(result, "|") .. "}}"
end

function export.link(frame)
	local args = frame.args or frame
	
	return print_template(args)
end

function export.replace(frame)
	local args = clone_args(frame)
	local text, lang
	
	if args[4] or args[3] or args.tr then
		return print_template(args)
	else
		if args[2] then
			lang, text = args[1], args[2]
		else
			lang, text = "all", args[1]
		end
	end
	
	if lang == "akk" or lang == "gmy" or lang == "hit" or lang == "sux" then
		return hyphen_separated_replacements(text, lang)
	else
		text = interpret_shortcuts(text, lang, args.sc, args.noreorder, args.module)
	end
	
	return text or ""
end

function export.example(frame)
	local args = clone_args(frame)
	
	local text, lang
	
	if args[2] then
		lang, text = args[1], args[2]
	else
		lang, text = "all", args[1]
	end
	
	local textparam
	if find(text, "=") then
		textparam = "2="..text -- Currently, "=" is only used in the shortcuts for Greek, and Greek is always found in the second parameter, since the first parameter specify the language, "grc".
	else
		textparam = text
	end
	
	local template = {
		[1] = "subst:chars",
		[2] = lang ~= "all" and lang or textparam,
		[3] = lang ~= "all" and textparam or nil,
	}
	
	local output = { format_link(template) }
	table.insert(output, "\n| ")
	table.insert(output, lang ~= "all" and "<span lang=\""..lang.."\">" or "")
	table.insert(output, export.replace({lang, text}))
	table.insert(output, lang ~= "all" and "</span>" or "")
	
	return table.concat(output)
end

function export.examples(frame)
	local args = frame.getParent and frame:getParent().args or frame.args[1] and frame.args or frame
	
	local examples = args[1] and mw.text.split(args[1], ";%s+") or error('No content in the first parameter.')
	local lang = args["lang"]
	
	local output = {
[[
{| class="wikitable"
! shortcut !! result
]]
	}
	
	local row = [[
|-
| templateCode || result
]]
	
	for _, example in pairs(examples) do
		local textparam
		if find(example, "=") then
			textparam = "2=" .. example -- Currently, "=" is only used in the shortcuts for Greek, and Greek is always found in the second parameter, since the first parameter specify the language, "grc".
		else
			textparam = example
		end
		
		local template = {
			[1] = "subst:chars",
			[2] = lang or textparam,
			[3] = lang and textparam,
		}
		
		local result = export.replace{lang, example}
		
		local content = {
			templateCode = format_link(template),
			result = tag(result, lang),
		}
		
		local function addContent(item)
			if content[item] then
				return content[item]
			else
				return 'No content for "' .. item .. '".'
			end
		end
		
		local row = gsub(row, "%a+", addContent)
		
		table.insert(output, row)
	end
	
	return table.concat(output) .. "|}"
end

return export