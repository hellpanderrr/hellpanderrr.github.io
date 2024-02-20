local export = {}

local m_links = require("links")
local m_languages = require("languages")


-- Custom functions for generating a sortkey that will achieve the desired sort
-- order.
-- name of module and name of exported function
local custom_sort_functions = {
	egy = { "egy-utilities", "make_sortkey" },
	zh = { "Hani-sortkey", "makeSortKey" },
}


local function get_col_lengths(n_columns, n_items)
	local r = math.mod(n_items, n_columns)
	local col_lengths = {}
	
	for i = 1, n_columns do
		table.insert(col_lengths, (n_items - r) / n_columns)
		if (i <= r) then
			col_lengths[i] = col_lengths[i] + 1
		end
	end
	
	return col_lengths
end


local function set_columns(n_columns, items, line_start, lang)
	local col_lengths = get_col_lengths(n_columns, #items)
	local result = {}
	local count = 1
	
	for i = 1, n_columns do
		local col = {}
		for j = 1, col_lengths[i] do
			local item = items[count]
			
			if lang and not string.find(item, "<span") then
				item = m_links.full_link({lang = lang, term = item})
			end
			
			table.insert(col, "\n")
			table.insert(col, line_start)
			table.insert(col, item)
			
			count = count + 1
		end
		result[i] = table.concat(col)
	end
	
	return result
end


-- Compares bytes, which always yields the same result as comparing code points
-- in valid UTF-8 strings.
local laborious_comp
do
	local byte, min = string.byte, math.min
	laborious_comp = function (item1, item2)
		local l1, l2 = #item1, #item2
		for i = 1, min(l1, l2) do
			local char1, char2 = byte(item1, i, i), byte(item2, i, i)
			if char1 ~= char2 then
				return char1 < char2
			end
		end
		return l1 < l2
	end
end


-- Returns true if table contains strings that can be compared with < (less than).
-- This requires that they do not have code points above U+FFFF. The C locale
-- used by our copy of Lua does not handle them correctly. These code points
-- are encoded by byte sequences four bytes long that begin with the bytes 240
-- to 244 (0xF0 to 0xF4).
local function contains_safely_comparable_strings(strings)
	for _, str in ipairs(strings) do
		if str:find '[\240-\244]' then
			return false
		end
	end
	return true
end


local function do_alphabetize(content, lang)
	local safely_comparable = contains_safely_comparable_strings(content)
	if safely_comparable then
		-- This is actually tracking presence of characters outside of the
		-- [[w:Basic Multilingual Plane]] (BMP), many of which are in the
		-- [[w:Supplementary Multilingual Plane]] (SMP).
		--[[Special:WhatLinksHere/Template:tracking/columns/SMP]]
		require 'debug'.track('columns/SMP')
	end
	
	if lang then
		local cache = {}
		
		local custom_sort_function = custom_sort_functions[lang:getCode()]
		local makeSortKey =
			custom_sort_function and require("" .. custom_sort_function[1])[custom_sort_function[2]]
			or function(text)
			return (lang:makeSortKey(text))
		end
		local function prepare(element)
			local result = cache[element]
			
			if result then
				return result
			end
			
			result = m_links.remove_links(element)
			result = mw.ustring.gsub(result, "[%p ]", "")
			result = makeSortKey((lang:makeEntryName(result)))
			cache[element] = result
			
			return result
		end
		
		local comp = not safely_comparable and function(item1, item2)
				return laborious_comp(prepare(item1), prepare(item2))
			end
			or function (item1, item2)
				return prepare(item1) < prepare(item2)
			end
		
		table.sort(content, comp)
	else
		table.sort(content, not safely_comparable and laborious_comp or nil)
	end
end


local function get_col_header(bg, collapse, class, title, column_width)
	if collapse then
		return table.concat {'<div class="NavFrame">\n<div class="NavHead">',
						title,
						'</div>\n<div class="NavContent">\n{| style="width: 100%;" role="presentation" class="',
						class,
						'"\n|-\n| style="vertical-align: top; text-align: left; background-color: ',
						bg,
						';  width: ',
						column_width,
						'%;" |'}
	else
		return table.concat {'<div style="width: auto; margin: 0; overflow: auto;">\n{| role="presentation" style="width: 100%"\n|-\n| style="background: ',
						bg,
						'; vertical-align: top; width: ',
						column_width,
						'%" |'}
	end

end


function export.create_table(n_columns, content, alphabetize, bg, collapse, class, title, column_width, line_start, lang)
	if column_width then
		require("debug").track("columns/column_width")
	end
	
	column_width = column_width or math.floor(80 / n_columns)
	
	if line_start then
		require("debug").track("columns/line_start")
	end
	
	line_start = line_start or "* "
	
	local separator = '\n| style="width: 1%;" |\n| style="background: ' .. bg .. '; vertical-align: top; text-align: left; width: ' .. column_width .. '%;" |'
	local final = ''
	if collapse then
		final = '\n|}</div></div>'
	else
		final = '\n|}</div>'
	end
	
	if alphabetize then
		do_alphabetize(content, lang)
	end
	
	local header = get_col_header(bg, collapse, class, title, column_width)
	local output = set_columns(n_columns, content, line_start, lang)
	
	-- Add separator between each column.
	for i = 2, (#output - 1) * 2, 2 do
		table.insert(output, i, separator)
	end
	
	table.insert(output, 1, header)
	table.insert(output, final)
	
	return table.concat(output)
end


function export.display(frame)
	local params = {
		["class"] = {default = "derivedterms"},
		["collapse"] = {type = "boolean"},
		["columns"] = {type = "number", default = 1},
		["lang"] = {},
		["sort"] = {type = "boolean"},
		["title"] = {default = ""},
	}
	
	local frame_args = require("parameters").process(frame.args, params)
	
	params = {
		[1] = {list = true},
		
		["title"] = {},
		["lang"] = not frame_args["lang"] and {required = true, default = "und"} or nil,
		["collapse"] = {},
	}
	
	local args = require("parameters").process(frame:getParent().args, params)
	
	local lang = frame_args["lang"] or args["lang"]
	lang = m_languages.getByCode(lang) or m_languages.err(lang, "lang")
	
	return export.create_table(frame_args["columns"], args[1], frame_args["sort"], "#F8F8FF", frame_args["collapse"], frame_args["class"], args["title"] or frame_args["title"], nil, nil, lang)
end


return export