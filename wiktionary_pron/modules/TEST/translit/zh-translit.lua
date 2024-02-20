local findTemplates = require("template parser").findTemplates
local get_section = require("utilities").get_section
local insert = table.insert
local sub = string.sub
local toNFD = mw.ustring.toNFD
local trim = mw.text.trim
local ulower = string.ulower

local frame = mw.getCurrentFrame()
local tag

local lect_code = mw.loadData("zh/data/lect codes").langcode_to_abbr

local export = {}

local function fail(lang, request)
	local langObj, req, cat = require("languages").getByCode(lang)
	if request then
		cat = {"Requests for transliteration of " .. langObj:getCanonicalName() .. " terms"}
	end
	return nil, true, cat
end

local function get_content(title)
	local content = mw.title.new(title)
	if not content then
		return false
	end
	return get_section(content:getContent(), "Chinese", 2)
end

local function get_reading(readings, lang, i, i_end, start)
	if i == i_end then
		return sub(readings, start, i - 1)
	end
	local c = sub(readings, i, i)
	if c == "," and (
		lang == "cmn" or
		lang == "wuu" or
		lang == "yue" or
		lang == "zh" or
		lang == "zhx-tai"
	) then
		if sub(readings, i + 1, i + 1) ~= " " then
			return sub(readings, start, i - 1)
		end
	elseif c == "/" then
		return sub(readings, start, i - 1)
	end
end

local function handle_readings(readings, lang, tr)
	if lang == "ltc" or lang == "och" then
		if tr and readings ~= tr then
			return false
		end
		return readings
	end
	local i, start, i_end, c, reading = 1, 1, #readings + 1
	while i <= i_end do
		reading = get_reading(readings, lang, i, i_end, start)
		if reading and not reading:match("=") then
			if (
				not tr or
				tr == reading or
				ulower(tr) == reading
			) then
				tr = reading
			elseif ulower(reading) ~= tr then
				return false
			end
			start = i + 1
		end
		i = i + 1
	end
	return tr
end

local function iterate_content(content, lang, see, seen, tr)
	for template, args in findTemplates(content) do
		if template == "zh-pron" then
			for k, v in pairs(args) do
				if (
					#v > 0 and
					type(k) == "string" and
					frame:preprocess(k) == lect_code[lang]
				) then
					tr = handle_readings(frame:preprocess(v), lang, tr)
					break
				end
			end
			if tr == false then
				return tr
			end
		elseif template == "zh-see" then
			local arg = trim(frame:preprocess(args[1]))
			if not seen[arg] then
				insert(see, arg)
			end
		end
	end
	return tr
end

function export.tr(text, lang, sc)
	if (not text) or text == "" then
		return text
	end
	
	if not lect_code[lang] then
		lang = require("languages").getByCode(lang, nil, true):getNonEtymologicalCode()
	end
	
	local content = get_content(text)
	if not content then
		return fail(lang)
	end
	
	local see = {}
	local seen = {
		[text] = true
	}
	local tr = iterate_content(content, lang, see, seen)
	
	if tr == nil then
		local i, title = 1
		while i <= #see do
			title = see[i]
			content = get_content(title)
			if content then
				tr = iterate_content(content, lang, see, seen, tr)
				if tr == false then
					return fail(lang)
				end
				seen[title] = true
			end
			i = i + 1
		end
	end
	
	if not tr then
		return fail(lang)
	end
	
	if lang == "cmn" or lang == "zh" then
		tr = tr:gsub("#", "")
		if tr:match("[\194-\244]") then
			tag = tag or mw.loadData("zh/data/cmn-tag").MT
			tr = tr:gsub("[%z\1-\127\194-\244][\128-\191]*", function(m)
				if m == "一" then
					return "yī"
				elseif m == "不" then
					return "bù"
				else
					m = tag[m] and tag[m][1]
					if m then
						return toNFD(m):gsub("^[aeiou]", "'%0")
					end
				end
			end)
				:gsub("^'", "") --remove initial apostrophe inserted by previous function
		end
	elseif lang == "cmn-sic" then
		tr = tr
			:gsub("([%d-])(%a)", "%1 %2")
			:gsub("[%d-]+", "<sup>%0</sup>")
	elseif lang == "hak" then
		-- TODO
	elseif lang == "ltc" or lang == "och" then
		if tr == "n" then
			return fail(lang)
		end
		local index = {}
		if tr then
			if lang == "ltc" then
				index = mw.text.split(tr, ",")
			else
				index = mw.text.split(tr, ";")
			end
		end
		for i = 1, mw.ustring.len(text) do
			local module_type = lang .. "-pron"
			if lang == "och" then
				module_type = module_type .. "-ZS"
			end
			
			local success, data_module = pcall(require, "Module:zh/data/" .. module_type .. "/" .. mw.ustring.sub(text, i, i))
			
			if not success or (((not index[i]) or index[i] == "y") and #data_module > 1) then
				return fail(lang)
			end
			
			if index[i] == "y" then
				index[i] = 1
			elseif index[i] then
				index[i] = tonumber(index[i])
			end
			
			index[i] = index[i] and data_module[index[i]] or data_module[1]
			
			if lang == "ltc" then
				local data = mw.loadData("ltc-pron/data")
				local initial, final, tone = require("ltc-pron").infer_categories(index[i])
				tone = tone ~= "" and ("<sup>" .. tone .. "</sup>") or tone
				index[i] = data.initialConv["Zhengzhang"][initial] .. data.finalConv["Zhengzhang"][final] .. tone
			else
				index[i] = index[i][6]
			end
		end
		tr = table.concat(index, " ")
		if lang == "och" then
			tr = "*" .. tr
		end
	elseif lang == "nan" then
		-- TODO
	elseif lang == "yue" then
		tr = tr:gsub("[%d-]+", "<sup>%0</sup>")
	elseif lang == "zhx-tai" then
		tr = tr:gsub("[%d*]+%-?[%d*]*", "<sup>%0</sup>")
	elseif lang == "zhx-teo" then
		-- TODO
	elseif lang == "wuu" then
		tr = require("wuu-pron").wugniu_format(tr)
	else
		tr = require("" .. lang .. "-pron").rom(tr)
	end
	
	-- End with a space so that concurrent parts of running text that need to be transliterated separately (e.g. due to links) are still properly separated.
	return tr .. " "
end

return export