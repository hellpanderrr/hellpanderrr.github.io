local m_families = require("families/data")
local m_language_like = require("language-like")

local export = {}
local filters = {}

function export.count(frame)
	return require("table").size(require("languages/data/all"))
end

local function mergeExtra(langdata, extradata)
    for lkey, lvalue in pairs(extradata) do
    	if langdata[lkey] then
    		for key, value in pairs(lvalue) do
	    		langdata[lkey][key] = lvalue[key]
    		end
    	end
    end
end

local function getOtherNames(data)
	return table.concat(m_language_like.getOtherNames(data), ", ")
end

function export.show(frame)
	local args = frame.args
	local filter_name = args[1]
	local filter = filters[filter_name]
	local arg2 = args[2]
	local ids = args["ids"]; ids = not ids or ids == ""
		
	local fun = require("fun")
	
	local deepcopy = require("table").deepcopy
	local function copy(t)
		return deepcopy(t, true) -- omit metatables
	end
	
	local m_languages
	local use_filter = false
	
	-- Choose a data module.
	if filter_name == "two-letter code" then
		m_languages = require("languages/data/2")
		mergeExtra(m_languages, require("languages/data/2/extra"))
		if arg2 then
			use_filter = true
		end
	elseif filter_name == "three-letter code" then
		if arg2 and arg2:find("^[a-z]$") then
			m_languages = require("languages/data/3/" .. arg2)
			mergeExtra(m_languages, require("languages/data/3/" .. arg2 .. "/extra"))
		else
			m_languages = require("languages/data/all")
		end
	elseif filter_name == "exceptional" then
		m_languages = require("languages/data/exceptional")
		mergeExtra(m_languages, require("languages/data/exceptional/extra"))
	else
		m_languages = require("languages/data/all")
		-- data/all already merges extradata
		use_filter = true
	end
	
	-- Select language codes to display.
	local data_tables = {}
	if use_filter then
		filter = filter(arg2)
		data_tables = fun.filter(filter, m_languages)
	else
		data_tables = m_languages
	end
	
	-- Now go over each code, and create table rows for those that are selected
	local rows = {}
	local row_i = 1
	
	local function link_script(script)
		return "[[Wiktionary:List of scripts#" .. script .. "|<code>" .. script .. "</code>]]"
	end	
	
	for code, data in require("table").sortedPairs(data_tables) do
		local canonicalName, family, scripts = data[1], data[3], data[4]
		local row = {
			"\n|-", (ids and " id=\"" .. code .. "\" |" or ""),
			"\n|", "<code>", code, "</code>",
			"\n| [[:Category:", canonicalName, (canonicalName:find("[Ll]anguage$") and "" or " language"), "|", canonicalName, "]]",
			"\n|", (family and family ~= "qfa-und" and ("[[Wiktionary:List of families#%s|%s]]"):format(family, m_families[family] and m_families[family][1] or ("<code>" .. family .. "</code>")) or ""),
			"\n|"
		}
		
		if type(scripts) == "string" then scripts = mw.text.split(scripts, "%s*,%s*") end
		
		if scripts and scripts[1] ~= "None" then
			table.insert(
				row,
				table.concat(
					fun.map(
						link_script,
						scripts),
					", "))
		end
		
		table.insert(row, "\n|")

		table.insert(row, getOtherNames(data))

		table.insert(row,
			"\n| " .. (data.sort_key and "Yes" or "") ..
			"\n| " .. (data.entry_name and "Yes" or "")
		)
		
		rows[row_i] = table.concat(row)
		row_i = row_i + 1
	end

	return table.concat {
[[
{| class="wikitable sortable mw-datatable"
! Code
! Canonical name
! Family
! style="width: 12em" | Scripts
! Other names
! Sort?
! Diacr?]], table.concat(rows), "\n|}"
	}
end

-- Filter functions
-- They receive parameter 2 as argument and generate a new function.
-- This function returns true or false depending on whether a given code
-- should be included in the table or not.
-- They're used to build shorter sublists.
-- The arguments are in the order "data, code" because the filter function in
-- [[Module:fun]] supplies arguments to it in the order value, key.

filters["two-letter code"] = function (firstletter)
	local pattern = "^" .. (firstletter or "[a-z]") .. "[a-z]$"
	
	return function (data, code)
		return code:find(pattern) ~= nil
	end
end

filters["type"] = function (type)
	return function (data, code)
		return data.type == type
	end
end

filters["subst"] = function (arg2)
	return function (data, code)
		return data.sort_key or data.entry_name
	end
end

filters["special"] = function (arg2)
	return function (data, code)
		return data[3] == "qfa-not"
	end
end

--

function export.show_etym(frame)
	local m_languages = require("languages/data/all")
	local m_etym_data = require('etymology_languages/data') -- this probably HAS to be a require here
	local codes_list = {}
	local items = {}

	for code, data in pairs(m_etym_data) do
		if not codes_list[data] then
			codes_list[data] = {}
			table.insert(items, data)
		end
		table.insert(codes_list[data], code)
	end

	table.sort(items, function (apple, orange)
		return apple[1] < orange[1]
	end)

	local function make_parent_link(code)
		if m_languages[code] then
			return ('[[Wiktionary:List of languages#%s|%s]]'):format(code, m_languages[code][1])
		elseif m_families[code] then
			return ('[[Wiktionary:List of families#%s|%s family]]'):format(code, m_families[code][1])
		elseif m_etym_data[code] then
			return ('[[Wiktionary:List of languages/special#%s|%s]]'):format(code, m_etym_data[code][1])
		elseif code then
			return '<code>' .. code .. '</code>'
		else
			return '[missing]'
		end
	end

	local rows = {}
	for i, data in ipairs(items) do
		local codes = codes_list[data]
		table.sort(codes)
		
		for i, code in ipairs(codes) do
			codes[i] = '<code id="' .. code .. '">' .. code .. '</code>'
		end
		
		table.insert(rows,
			' \n' ..
			'| ' .. table.concat(codes, ", ") .. '\n' ..
			'| [[:Category:Terms derived from ' .. data[1] .. '|' .. data[1] .. ']]\n' ..
			'| ' .. getOtherNames(data) .. '\n' ..
			'| ' .. make_parent_link(data[3])
		)
	end

	return
		"{| class=\"wikitable sortable mw-datatable\"\n" ..
		"! Codes\n" ..
		"! Canonical name\n" ..
		"! Other names\n" ..
		"! Parent\n" ..
		"|-" .. table.concat(rows, "\n|-") .. "\n|}"
end

return export