local export = {}

-- Custom functions for generating a sortkey that will achieve the desired sort
-- order.
-- name of module and name of exported function
local custom_sort_functions = {
	ahk = { "Mymr-sortkey", "makeSortKey" },
	aio = { "Mymr-sortkey", "makeSortKey" },
	blk = { "Mymr-sortkey", "makeSortKey" },
	egy = { "egy-utilities", "make_sortkey" },
	kac = { "Mymr-sortkey", "makeSortKey" },
	kht = { "Mymr-sortkey", "makeSortKey" },
	ksw = { "Mymr-sortkey", "makeSortKey" },
	kyu = { "Mymr-sortkey", "makeSortKey" },
	["mkh-mmn"] = { "Mymr-sortkey", "makeSortKey" },
	mnw = { "Mymr-sortkey", "makeSortKey" },
	my  = { "Mymr-sortkey", "makeSortKey" },
	phk = { "Mymr-sortkey", "makeSortKey" },
	pwo = { "Mymr-sortkey", "makeSortKey" },
	omx = { "Mymr-sortkey", "makeSortKey" },
	shn = { "Mymr-sortkey", "makeSortKey" },
	tjl = { "Mymr-sortkey", "makeSortKey" },
}

local function is_lang_object(lang)
	return type(lang) == "table" and type(lang.getCanonicalName) == "function"
end

local function check_lang_object(funcName, argIdx, lang)
	if not is_lang_object(lang) then
		error("bad argument #" .. argIdx .. " to " .. funcName
			.. ": expected language object, got " .. type(lang) .. ".", 2)
	end
end

local function check_function(funcName, argIdx, func)
	if type(func) ~= "function" then
		error("bad argument #" .. argIdx .. " to " .. funcName
			.. ": expected function object, got " .. type(func) .. ".", 2)
	end
end

-- UTF-8-encoded characters that do not belong to the Basic Multilingual Plane
-- (that is, with code points greater than U+FFFF) have byte sequences that
-- begin with the bytes 240 to 244.
local function contains_non_BMP(str)
	return str:find '[\240-\244]'
end

-- Compares bytes, which always yields the same result as comparing code points
-- in valid UTF-8 strings.
-- A fix for the < operator for strings, which treats all code points above
-- U+FFFF as equal. See this comment on the related bug report for more
-- information: [[phab:T193096#4161287]].
do
	local byte, min = string.byte, math.min
	function export.laborious_comp(item1, item2)
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

function export.make_sortkey_func(lang, keyfunc)
	check_lang_object("make_sortkey_func", 1, lang)
	keyfunc = keyfunc or function(elem) return elem end
	check_function("make_sortkey_func", 2, keyfunc)
	
	local cache = {}
	
	local custom_sort_function = custom_sort_functions[lang:getCode()]
	local makeSortKey =
		custom_sort_function and require("" .. custom_sort_function[1])[custom_sort_function[2]]
		or function(text)
			return (lang:makeSortKey(text))
		end
	
	return function (element)
		element = keyfunc(element)
		local result = cache[element]
		
		if result then
			return result
		end
		
		result = require("utilities").get_plaintext(element)
		result = makeSortKey((lang:makeDisplayText(result)), lang:getCode())
		cache[element] = result
		
		return result
	end
end

function export.make_compare_func(lang, non_BMP, keyfunc)
	local make_sortkey = export.make_sortkey_func(lang, keyfunc)
	
	-- When comparing two elements with code points outside the BMP, the
	-- less-than operator does not work correctly because of a bug in glibc.
	-- See [[phab:T193096]].
	if non_BMP then
		return function (elem1, elem2)
			return export.laborious_comp(make_sortkey(elem1), make_sortkey(elem2))
		end
	else
		return function (elem1, elem2)
			return make_sortkey(elem1) < make_sortkey(elem2)
		end
	end
end

function export.sort(elems, lang, keyfunc)
	local non_BMP
	for _, elem in ipairs(elems) do
		if keyfunc then
			elem = keyfunc(elem)
		end
		if contains_non_BMP(elem) then
			non_BMP = true
			break
		end
	end
	
	return table.sort(elems, is_lang_object(lang) and export.make_compare_func(lang, non_BMP, keyfunc) or nil)
end

function export.sort_template(frame)
	if not mw.isSubsting() then
		error("This template must be substed.")
	end
	
	local args
	if frame.args.parent then
		args = frame:getParent().args
	else
		args = frame.args
	end
	
	local elems = require("table").shallowcopy(args)
	local m_languages = require("languages")
	local lang
	if args.lang then
		lang = m_languages.getByCode(args.lang) or m_languages.err(args.lang, 'lang')
	else
		local code = table.remove(elems, 1)
		code = code and mw.text.trim(code)
		lang = m_languages.getByCode(code) or m_languages.err(code, 1)
	end
	export.sort(elems, lang)
	return table.concat(elems, args.sep or "|")
end

return export