local export = {}

local m_links = require("links")

--[=[

Terminology:

Number = a bare number; a mathematical entity which has different form types (e.g. cardinal, ordinal)
Form type = a category of the forms that represent a number; examples are cardinal, ordinal, distributive, fractional
Form = a word or expression that represents a number in a given language
Tag = an identifier attached to a form that allows different logical subtypes of forms from the same form type to be
      identified; e.g. 'vuitanta-vuit<tag:Central>' vs. 'huitanta-huit<tag:Valencian>' to identify variants of
	  Catalan cardinal number 88 for different dialectal standards; there can be multiple tags per form, e.g.
	  'tair ar ddeg<tag:vigesimal><tag:feminine>' for the Welsh number 13 where there are both decimal/vigesimal and
	  masculine/feminine variants of this number
Tag list = a list of tags in the order they are specified in the data, e.g. {"vigesimal", "feminine"} for the example
           above
Combined tag = the string representation of a tag list, using ||| to separate individual tags
]=]

local default_form_types = {
	{key = "cardinal", display = "[[cardinal number|Cardinal]]"},
	{key = "ordinal", display = "[[ordinal number|Ordinal]]"},
	{key = "ordinal_abbr", display = "[[ordinal number|Ordinal]] [[abbreviation]]"},
	{key = "adverbial", display = "[[adverbial number|Adverbial]]"},
	{key = "multiplier", display = "[[multiplier|Multiplier]]"},
	{key = "distributive", display = "[[distributive number|Distributive]]"},
	{key = "collective", display = "[[collective number|Collective]]"},
	{key = "fractional", display = "[[fractional|Fractional]]"},
}

-- Keys in a `numbers` entry that aren't form types.
local non_form_types = {
	numeral = true,
	wplink = true,
	next = true,
	prev = true,
	next_outer = true,
	prev_outer = true,
	upper = true,
	lower = true,
}

local function track(page)
	require("debug/track")("number list/" .. page)
	return true
end

--[=[
--
-- General set intersection
local function set_intersection(sets)
	local intersection = {}
	for key, _ in pairs(sets[1]) do
		intersection[key] = true
	end
	for i = 2, #sets do
		local this_set = sets[i]
		for key, _ in pairs(intersection) do
			if not this_set[key] then
				-- See https://stackoverflow.com/questions/6167555/how-can-i-safely-iterate-a-lua-table-while-keys-are-being-removed
				-- It is safe to modify or remove a key while iterating over the table.
				intersection[key] = nil
			end
		end
	end
	return intersection
end
]=]

local function set_intersection(set1, set2)
	local intersection = {}
	for key, _ in pairs(set1) do
		intersection[key] = true
	end
	for key, _ in pairs(intersection) do
		if not set2[key] then
			-- See https://stackoverflow.com/questions/6167555/how-can-i-safely-iterate-a-lua-table-while-keys-are-being-removed
			-- It is safe to modify or remove a key while iterating over the table.
			intersection[key] = nil
		end
	end
	return intersection
end

local function list_to_set(list)
	local set = {}
	for _, item in ipairs(list) do
		set[item] = true
	end
	return set
end

function export.get_data_module_name(langcode, must_exist)
	local module_name = "Module:number list/data/" .. langcode
	if must_exist and not mw.title.new(module_name).exists then
		error(("Data module [[%s]] for language code '%s' does not exist"):format(module_name, langcode))
	end
	return module_name
end

local function power_of(n)
	return "1" .. string.rep("0", n)
end

-- Format a number (either a Lua number or a string) in fixed point without any decimal point or scientific notation.
-- `tostring()` doesn't work because it converts large numbers such as 1000000000000000 to "1e+15".
function export.format_fixed(number)
	if type(number) == "string" then
		return number
	else
		return ("%.0f"):format(number)
	end
end

-- Parse a form with modifiers such as 'vuitanta-vuit<tag:Central>' or 'سیزده<tr:sizdah>'
-- or 'سیزده<tr:sizdah><tag:Iranian>' into its component parts. Return a form object, i.e. an object with fields
-- `form` for the form, and `tr`, `tag`, `q`, `qq` or `link` for the modifiers. The `tag` field is a tag list
-- (see above).
function export.parse_form_and_modifiers(form_with_modifiers)
	local retval = {}
	local form
	form = form_with_modifiers
	while true do
		local new_form, angle_bracketed = form:match("^(.-)(%b<>)$")
		if not new_form then
			break
		end
		local prefix, content = angle_bracketed:match "^<(%w+):(.+)>$"
		if not prefix then
			break
		end
		if prefix == "tag" then
			if retval.tag then
				table.insert(retval.tag, content)
			else
				retval.tag = {content}
			end
		elseif prefix == "q" or prefix == "qq" or prefix == "tr" or prefix == "link" then
			if retval[prefix] then
				error(("Duplicate modifier '%s' in data module form, already saw value '%s': %s"):format(prefix,
					retval[prefix], form_with_modifiers))
			else
				retval[prefix] = content
			end
		else
			error(("Unrecognized modifier '%s' in data module form: %s"):format(prefix, form_with_modifiers))
		end
		form = new_form
	end
	retval.form = form
	return retval
end

-- Find the `numbers` object for a given number (which should be in string representation).
function export.lookup_data(m_data, numstr)
	-- Don't try to convert very large numbers to Lua numbers because they may overflow.
	-- Powers of 10 >= 10^22 cannot be represented exactly as a Lua number.
	return m_data.numbers[numstr] or #numstr < 22 and m_data.numbers[tonumber(numstr)] or nil
end

-- Return true if a < b, where either may be a Lua number or the string representation of a number.
function export.numbers_less_than(a, b)
	a, b = export.format_fixed(a), export.format_fixed(b)
	local alen = #a
	local blen = #b
	if alen < blen then
		return true
	end
	if alen > blen then
		return false
	end
	return a < b
end

-- Return true if a > b, where either may be a Lua number or the string representation of a number.
function export.numbers_greater_than(a, b)
	return export.numbers_less_than(b, a)
end

-- Given a number form, convert it to its independent (un-affixed) form. This only makes sense for certain languages
-- where there is a difference between independent and affixed forms of numerals. Currently the only such language
-- is Swahili, where e.g. the cardinal number form for 3 is affixed [[-tatu]], independent [[tatu]], and the ordinal
-- number form is [[-a tatu]], independent [[tatu]]. We rely on a set of Lua pattern substitutions to convert from
-- affixed to independent form.
--
-- FIXME: This needs major rethinking in a way that isn't specific to Swahili.
local function maybe_unaffix(m_data, form)
	if not m_data.unaffix then
		return form
	end
	for _, entry in ipairs(m_data.unaffix) do
		local from, to = unpack(entry)
		form = mw.ustring.gsub(form, from, to)
	end
	return form
end

-- Convert the given number form (taken from the data for `lang`, after parsing the form for modifiers and stripping
-- the modifiers) to an entry name. The form may have links and/or accent/length marks that need to be stripped.
local function form_to_entry_name(form, lang)
	return (lang:makeEntryName(m_links.remove_links(form)))
end

-- Return true if the given number form object (taken from the data for `lang`, after parsing the form for modifiers)
-- matches `pagename`. If there is a <link:...> modifier, we check against it. Otherwise, we check against the form
-- itself. In this case, the form may have links and/or accent/length marks that need to be stripped, and we may need
-- to convert the form to its independent (un-affixed) form, if there is a difference between independent and affixed
-- forms (as in Swahili).
local function form_equals_pagename(formobj, pagename, m_data, lang)
	if formobj.link == pagename then
		return true
	end
	local entry_name = form_to_entry_name(formobj.form, lang)
	return entry_name == pagename or maybe_unaffix(m_data, entry_name) == pagename
end

-- Given the data for a language and a number (which should be in string representation), find the next and previous
-- numbers to display (in string representation).
local function get_next_and_prev_keys(m_data, numstr)
	local numdata = export.lookup_data(m_data, numstr)
	if not numdata then
		return nil, nil
	end
	local nextnum = numdata.next
	local prevnum = numdata.prev
	if not nextnum or not prevnum then
		-- Find the next/previous numbers by sorting all the keys and locating the number in question among them.
		local sorted_list = {}
		local index = 1
		for key, _ in pairs(m_data.numbers) do
			sorted_list[index] = key
			index = index + 1
		end

		table.sort(sorted_list, export.numbers_less_than)

		-- We could binary search to save time, but given that we already sort, which is supra-linear, it won't
		-- matter to search linearly.
		for i, key in ipairs(sorted_list) do
			if export.format_fixed(key) == numstr then
				nextnum = nextnum or sorted_list[i + 1]
				prevnum = prevnum or sorted_list[i - 1]
				break
			end
		end
	end

	if nextnum then
		nextnum = export.format_fixed(nextnum)
	end
	if prevnum then
		prevnum = export.format_fixed(prevnum)
	end

	return nextnum, prevnum
end

-- Find the "description objects" (a two-element list {NUMBER, TYPE}, where NUMBER is either a Lua number or a string,
-- depending on how it appears in the underlying data) that matches `pagename` and (if given) `matching_type`.
-- Return a list of such objects.
local function lookup_number_by_form(lang, m_data, pagename, matching_type)
	local retval = {}
	local function check_form(form, num, typ)
		local formobj = export.parse_form_and_modifiers(form)
		if form_equals_pagename(formobj, pagename, m_data, lang) and (not matching_type or typ == matching_type) then
			-- It's possible the same pagename occurs multiply for a given type and number, e.g. with different length
			-- or accent marks. The calling code is OK with multiple entries for a given number (which can also occur
			-- with different types, e.g. the ordinal and fractional forms for a given number are the same), but will
			-- throw an error if different numbers are seen.
			table.insert(retval, {num, typ})
		end
	end

	for num, numdata in pairs(m_data.numbers) do
		for numtype, forms in pairs(numdata) do
			if non_form_types[numtype] then
				-- do nothing
			elseif type(forms) == "table" then
				for _, form in ipairs(forms) do
					check_form(form, num, numtype)
				end
			else
				check_form(forms, num, numtype)
			end
		end
	end

	return retval
end

-- additional_types is an array of tables like form_types,
-- but each table can contain the keys "before" or "after", which specify
-- the numeral type that the form should appear before or after.
-- The transformations are applied in order.
local function add_form_types(form_types, additional_types)
	local types = require("table").deepcopy(form_types)
	for _, type in ipairs(additional_types) do
		if not (type.before or type.after) then
			table.insert(types, type)
		else
			if type.before and type.after then
				error("The form type '" .. type.key .. "' is specifying both before and after, which is not allowed")
			end

			local index
			local anchor = type.before or type.after

			for i, another_type in ipairs(types) do
				if another_type.key == anchor then
					index = i
					break
				end
			end

			if index and type.after then
				index = index + 1
			end

			type = require("table").shallowcopy(type)
			type.before, type.after = nil, nil
			
			if not index then
				mw.log("Number type "
					.. (type.before or type.after)
					.. " was not found.")
				table.insert(types, type)
			else
				table.insert(types, index, type)
			end
		end
	end
	return types
end

-- Return all form types for the language in question, in order.
function export.get_number_types(m_data)
	local form_types = default_form_types
	if m_data.additional_number_types then
		return add_form_types(form_types, m_data.additional_number_types)
	else
		return form_types
	end
end

-- Convert a number type object (an object with `display` and `key` fields) to its displayed form.
function export.display_number_type(number_type)
	if number_type.display then
		return number_type.display
	else
		return (number_type.key:gsub("^.", string.upper):gsub("_", " "))
	end
end

-- Group digits with a separator, such as a comma or a period. See [[w:Digit grouping]].
local function add_separator(numstr, separator, group, start)
	start = start or group
	if start >= #numstr then
		return numstr
	end

	local parts = { numstr:sub(-start) }
	for i = start + 1, #numstr, group do
		table.insert(parts, 1, numstr:sub(-(i + group - 1), -i))
	end

	return table.concat(parts, separator)
end

function export.add_thousands_separator(numstr, separator)
	if #numstr < 4 then -- < 1000
		return numstr
	end
	return add_separator(numstr, separator or ",", 3)
end

local function add_Indic_separator(numstr, separator)
	return add_separator(numstr, separator, 2, 3)
end

-- Convert a number (represented as a string) to non-Arabic form based on the specs in `numeral_config`.
-- This is used, for example, to display the Hindu, Eastern Arabic or Roman form of a number along with the standard
-- Arabic form. Most of the code below assumes that the non-Arabic numerals are decimal, and the digits map one-to-one
-- with Arabic numerals. If this is not the case (e.g. for Roman numerals), a special module function is called to do
-- the conversion.
function export.generate_non_arabic_numeral(numeral_config, numstr)
	-- `numstr` is a number represented as a string. See comment near top of show_box().
	if numeral_config.module and numeral_config.func then
		return require("" .. numeral_config.module)[numeral_config.func](numstr)
	end

	local thousands_separator, Indic_separator, zero_codepoint =
		numeral_config.thousands_separator,
		numeral_config.Indic_separator,
		numeral_config.zero_codepoint

	if not zero_codepoint then
		return nil
	end

	if thousands_separator then
		numstr = export.add_thousands_separator(numstr, thousands_separator)
	elseif Indic_separator then
		numstr = add_Indic_separator(numstr, Indic_separator)
	end

	return numstr:gsub("[0-9]", function (digit)
		return mw.ustring.char(zero_codepoint + tonumber(digit))
	end)
end


-- Format a number (either a Lua number or a string) for display. Sufficiently small numbers are displayed in fixed
-- point with thousands separators. Larger numbers are displayed in both fixed point and scientific notation using
-- superscripts, and sufficiently large numbers are displayed only in scientific notation.
function export.format_number_for_display(number)
	local MAX_NUM_DIGITS_FOR_FIXED_ONLY = 6
	local MIN_NUM_DIGITS_FOR_SCIENTIFIC_ONLY = 13
	local numstr = export.format_fixed(number)
	local fixed = export.add_thousands_separator(numstr)
	if #numstr <= MAX_NUM_DIGITS_FOR_FIXED_ONLY then
		return fixed
	end
	local kstr = numstr:match("^([0-9]*[1-9])0*$")
	if not kstr then
		error("Internal error: Unable to match number '" .. numstr .. "'")
	end
	local exponent = ("10<sup>%s</sup>"):format(#numstr - 1)
	local mantissa
	if kstr == "1" then
		mantissa = ""
	elseif #kstr == 1 then
		mantissa = kstr .. " x "
	else
		mantissa = kstr:gsub("^([0-9])", "%1.") .. " x "
	end
	local scientific = mantissa .. exponent
	if #numstr >= MIN_NUM_DIGITS_FOR_SCIENTIFIC_ONLY then
		return scientific
	else
		return fixed .. " (" .. scientific .. ")"
	end
end

-- Map a list of tags to a single string that is equivalent. We need to do this because we can't easily put lists in the
-- keys of tables.
local function tag_list_to_combined_tag(tag_list)
	return table.concat(tag_list, "|||")
end

-- Given a list of forms with attached inline modifiers (e.g. 'huitanta-huit<tag:Valencian>' or
-- 'tair ar ddeg<tag:vigesimal><tag:feminine>'), parse the forms into form objects (the return value of
-- parse_form_and_modifiers()) and group by the tag. Three values are returned:
-- `seen_forms`, `forms_by_tag`, `seen_tags` where:
-- (1) `seen_forms` is the list of parsed form objects;
-- (2) `forms_by_tag` is a table grouping the form objects by combined tag, where the key is the tag and the value is
--      a list of the form objects seen with that tag (forms without tag are grouped under the empty-string tag);
-- (3) `seen_tags` is a list of the combined tags encountered, in the order they were encountered;
-- (4) `combined_tags_to_tag_lists` is a map from combined tags to the corresponding tag lists.
function export.group_numeral_forms_by_tag(forms)
	local seen_forms = {}
	local forms_by_tag = {}
	local seen_tags = {}
	local combined_tags_to_tag_lists = {}

	for _, form in ipairs(forms) do
		local formobj = export.parse_form_and_modifiers(form)
		table.insert(seen_forms, formobj)
		local combined_tag = formobj.tag and tag_list_to_combined_tag(formobj.tag) or ""
		if not forms_by_tag[combined_tag] then
			table.insert(seen_tags, combined_tag)
			forms_by_tag[combined_tag] = {}
			combined_tags_to_tag_lists[combined_tag] = formobj.tag or {}
		end
		table.insert(forms_by_tag[combined_tag], formobj)
	end

	return seen_forms, forms_by_tag, seen_tags, combined_tags_to_tag_lists
end

-- Given a form object (as returned by parse_form_and_modifiers()), format as appropriate for the current language.
function export.format_formobj(formobj, m_data, lang)
	local left_q = formobj.q and require("qualifier").format_qualifier(formobj.q) .. " " or ""
	local right_q = formobj.qq and " " .. require("qualifier").format_qualifier(formobj.qq) or ""
	return left_q .. m_links.full_link{
		lang = lang, term = maybe_unaffix(m_data, formobj.form), alt = formobj.form, tr = formobj.tr,
	} .. right_q
end

-- Implementation of {{number box}}.
function export.show_box(frame)
	local full_link = m_links.full_link

	local params = {
		[1] = {required = true},
		[2] = {},
		["pagename"] = {},
		["type"] = {},
	}

	local parent_args = frame:getParent().args
	if parent_args.pagename then
		track("show-box-pagename")
	end
	local args = require("parameters").process(parent_args, params, nil, "number list", "show_box")

	local langcode = args[1] or "und"
	local lang = require("languages").getByCode(langcode, "1")

	-- Get the data from the data module. Some modules (e.g. currently [[Module:number list/data/ka]]) have to be
	-- loaded with require() because the exported numbers table has a metatable.
	local module_name = export.get_data_module_name(langcode, "must exist")
	local m_data = require(module_name)

	local pagename = args.pagename or (mw.title.getCurrentTitle().nsText == "Reconstruction" and "*" or "") .. mw.title.getCurrentTitle().subpageText
	-- Resolve any risky characters which makeEntryName will escape, so that any matches involving them work correctly.
	pagename = (lang:makeEntryName(pagename))
	local cur_type = args.type

	-- We represent all numbers as strings in this function to deal with the limited precision inherent in Lua numbers.
	-- These large numbers do occur, such as 100 trillion ([[རབ་བཀྲམ་ཆེན་པོ]]), 1 sextillion, etc. Lua represents all
	-- numbers as 64-bit floats, meaning that some numbers above 2^53 cannot be represented exactly. The first power of
	-- 10 that cannot be represented exactly is 10^22 (ten sextillion in short scale, ten thousand trillion in long
	-- scale), but the first power of ten whose neighboring numbers cannot be represented exactly is 10^16 (ten
	-- quadrillion or ten thousand billion). Ideally we would use a big integer library of some kind, but unfortunately
	-- Wiktionary does not seem to have any such library installed. MediaWiki docs make mention of bcmath, but
	-- mw.bcmath.new() throws an error.
	--
	-- In module data, we allow numbers to be indexed as Lua numbers or as strings. See lookup_data() above.
	local cur_num = args[2] or langcode == "und" and mw.title.getCurrentTitle().nsText == "Template" and "2" or nil

	-- If a current number wasn't specified, find it by looking through the data for the current language and matching
	-- forms against the pagename.
	if not cur_num then
		local nums_and_types = lookup_number_by_form(lang, m_data, pagename, cur_type)
		if #nums_and_types == 0 then
			error("The current page name '" .. pagename .. "' does not match the spelling of any known number in [[" ..
				module_name .. "]]. Check the data module or the spelling of the page.")
		end
		for _, num_and_type in ipairs(nums_and_types) do
			local num, typ = unpack(num_and_type)
			num = export.format_fixed(num)
			if cur_num and num ~= cur_num then
				local errparts = {}
				for _, num_and_type in ipairs(nums_and_types) do
					local num, typ = unpack(num_and_type)
					table.insert(errparts, ("%s (%s)"):format(num, typ))
				end
				error("The current page name '" .. pagename .. "' matches the spelling of multiple numbers in [[" ..
					module_name .. "]]: " .. table.concat(errparts, ",") .. ". Please specify the number explicitly.")
			else
				cur_num = num
			end
		end
	end

	cur_num = cur_num:gsub(",", "") -- remove thousands separators
	if not cur_num:find("^%d+$") then
		error("Extraneous characters in parameter 2: should be decimal number (integer): '" .. cur_num .. "'")
	end

	-- Wrapper around `export.lookup_data` that may throw an error if the number can't be found (specifically if
	-- param_for_error is given).
	local function lookup_data(numstr, param_for_error)
		local retval = export.lookup_data(m_data, numstr)
		if not retval and param_for_error then
			error(('The %s number "%s" specified in the "numbers" table entry for "%s" cannot be found in '
				.. "[[%s]]; please fix the module."):format(param_for_error, numstr, cur_num, module_name))
		end
		return retval
	end

	local cur_data = lookup_data(cur_num)
	if not cur_data then
		error('The number "' .. cur_num .. '" is not found in the "numbers" table in [[' .. module_name .. "]].")
	end

	local formatted_forms = {}

	if cur_type and not cur_data[cur_type] then
		error("The numeral type " .. cur_type .. " for " .. cur_num .. " is not found in [[" .. module_name .. "]].")
	end

	-- See above for the definition of "combined tag" and "tag list". The combined tag is just the concatenation of the
	-- tag list with ||| between the tags.
	local cur_tag_list, cur_combined_tag

	local form_types = export.get_number_types(m_data)
	
	-- LONG COMMENT EXPLAINING TAG HANDLING:
	--
	-- For each form type (see `form_types` at top of file), group the entries for that form type by tag and figure out
	-- what the current form type and tag is, i.e. the form type and tag for the form matching the pagename. Tags are
	-- e.g. as in 'vuitanta-vuit<tag:Central>' or 'huitanta-huit<tag:Valencian>' for Catalan and allow different
	-- logical sets of numbers for the same form type to be identified. There can potentially be multiple tags per
	-- form, e.g. 'tair ar ddeg<tag:vigesimal><tag:feminine>' for the Welsh number 13 where there are both decimal/
	-- vigesimal and masculine/feminine variants of this number.
	--
	-- We need to do two passes over all form types. In the first pass, for each form type we parse all the forms,
	-- group them by tag, and store the results in a per-form-type table. In the second pass, we then format all forms
	-- for all form types. The reason for doing two passes is because we need to know the current tag in order to
	-- display a form type correctly (because we display the forms for the current tag before the forms for any other
	-- tags), but we won't know the current tag until we have done a pass over all form types and forms of those form
	-- types in order to determine which one matches the pagename.
	--
	-- We use the current tag in two ways:
	-- 1. When displaying all the forms for a given number, we group both by form type and tag, and display the forms
	--    for a given form type/tag combination on a single line. For a given form type, we display the forms for each
	--    tag in the order the tags were specified in the data, except that the forms for the current tag are placed
	--    before all others (so e.g. for Catalan, if the current tag is "Valencian", we list the Valencian form(s)
	--    first even if the Central form(s) are listed first in the data file).
	-- 2. When displaying links to adjacent numbers in display_adjacent_number_links(), if there aren't form(s) for the
	--    current type, we don't display any links; but if there are mutiple tagged forms for the current type, we only
	--    display links for the forms for the current tag if there are any such forms, otherwise we display links for
	--    all forms of all tags.
	--
	-- In the presence of multiple tags, things get a bit more complicated:
	-- 1. When displaying links to adjacent numbers, say the current tag is vigesimal+feminine, we want to prefer an
	--    adjacent-number form that's both vigesimal and feminine, but otherwise we prefer one that's vigesimal or
	--    feminine over one that's neither. Say the current tag is just vigesimal; we of course prefer an
	--    adjacent-number form that's just vigesimal, but otherwise we prefer a tag that's vigesimal + either masculine
	--    or feminine to a tag that's not vigesimal. So it seems we want the form(s) that have the maximum intersection
	--    of tags, and if there are two different tag lists with the same number of intersecting tags (e.g. the current
	--    tag is vigesimal+feminine and we have a choice of decimal+feminine or just vigesimal), we should prefer the
	--    form that has fewer non-matching tags, hence we prefer the just-vigesimal form.
	-- 2. By the same logic, when displaying all the forms for a given number, we should order by the size of the
	--    intersection of the tag list in question with the current tag list, then inversely by the size of the tag list
	--    (so we prefer tag lists with fewer non-matching tags), then by the order of the tag lists in the data file.

	local forms_by_tag_per_form_type = {}
	local seen_tags_per_form_type = {}
	local combined_tags_to_tag_lists_per_form_type = {}

	for _, form_type in ipairs(form_types) do
		local numeral = cur_data[form_type.key]
		if numeral then
			local numerals
			if type(numeral) == "string" then
				numerals = {numeral}
			elseif type(numeral) == "table" then
				numerals = numeral
			end

			local seen_forms, forms_by_tag, seen_tags, combined_tags_to_tag_lists = export.group_numeral_forms_by_tag(numerals)
			forms_by_tag_per_form_type[form_type] = forms_by_tag
			seen_tags_per_form_type[form_type] = seen_tags
			combined_tags_to_tag_lists_per_form_type[form_type] = combined_tags_to_tag_lists
			for _, formobj in ipairs(seen_forms) do
				if not cur_tag_list and form_equals_pagename(formobj, pagename, m_data, lang) then
					cur_tag_list = formobj.tag or {}
					cur_combined_tag = tag_list_to_combined_tag(cur_tag_list)
					cur_type = cur_type or form_type.key
				end
			end
		end
	end

	-- Error if we couldn't locate the pagename among the forms for the current number. This only happens if the
	-- number if given explicitly in 2=.

	if not cur_type and mw.title.getCurrentTitle().nsText ~= "Template" then
		error("The current page name '" .. pagename .. "' does not match any of the numbers listed in [[" ..
			module_name .. "]] for " .. cur_num .. ". Check the data module or the spelling of the page.")
	end

	-- Now, format all the forms for all form types for the current number.

	local function sort_combined_tags(combined_tags, seen_tags, combined_tags_to_tag_lists)
		-- cur_tag_list should normally never be nil, but can be so in template space
		local cur_tag_set = list_to_set(cur_tag_list or {})
		local tags_to_order = {}
		for i, tag in ipairs(seen_tags) do
			tags_to_order[tag] = i
		end
		local function compare_tags(tag1, tag2)
			-- See long comment above.
			-- First compare by number of tags in common with the current tag list.
			local tag_list1 = combined_tags_to_tag_lists[tag1]
			local tag_list2 = combined_tags_to_tag_lists[tag2]
			local common1 = set_intersection(cur_tag_set, list_to_set(tag_list1))
			local common2 = set_intersection(cur_tag_set, list_to_set(tag_list2))
			if #common1 ~= #common2 then
				return #common1 < #common2
			end
			-- Then compare inversely by number of tags not in common with the current tag list (which is equivalent to
			-- comparing by total number of tags, since tags should be distinct).
			if #tag_list1 ~= #tag_list2 then
				return #tag_list1 > #tag_list2
			end
			-- Finally, compare by the original ordering in the number data, but if a tag is the same as the current
			-- tag, put it first, and if somehow we encounter a tag that's not in the original ordering, put it last.
			local index1 = tag1 == cur_combined_tag and 0 or tags_to_order[tag1] or #seen_tags + 1
			local index2 = tag2 == cur_combined_tag and 0 or tags_to_order[tag2] or #seen_tags + 1
			return index1 < index2
		end
		table.sort(combined_tags, compare_tags)
	end

	for _, form_type in ipairs(form_types) do
		local forms_by_tag = forms_by_tag_per_form_type[form_type]
		local seen_tags = seen_tags_per_form_type[form_type]
		local combined_tags_to_tag_lists = combined_tags_to_tag_lists_per_form_type[form_type]
		if forms_by_tag then
			local function insert_forms_by_tag(tag)
				local formatted_tag_forms = {}

				local pagename_among_forms = false
				for _, formobj in ipairs(forms_by_tag[tag]) do
					table.insert(formatted_tag_forms, export.format_formobj(formobj, m_data, lang))
					if form_equals_pagename(formobj, pagename, m_data, lang) then
						pagename_among_forms = true
					end
				end

				if tag ~= "" then
					local tag_list = combined_tags_to_tag_lists[tag]
					tag = table.concat(tag_list, " / ")
				end
				local displayed_number_type = export.display_number_type(form_type) .. (tag == "" and "" or (" (%s)"):format(tag))
				if pagename_among_forms then
					displayed_number_type = "'''" .. displayed_number_type .. "'''"
				end

				table.insert(formatted_forms, " &nbsp;&nbsp;&nbsp; ''" .. displayed_number_type .. "'': " ..
					table.concat(formatted_tag_forms, ", "))
			end

			sort_combined_tags(seen_tags, seen_tags, combined_tags_to_tag_lists)
			for _, tag in ipairs(seen_tags) do
				insert_forms_by_tag(tag)
			end
		end
	end

	-- Current number in header
	local cur_display = export.format_number_for_display(cur_num)

	local numeral
	if m_data.numeral_config then
		numeral = export.generate_non_arabic_numeral(m_data.numeral_config, cur_num)
	elseif cur_data["numeral"] then
		numeral = export.format_fixed(cur_data["numeral"])
	end

	if numeral then
		cur_display = full_link{lang = lang, alt = numeral, tr = "-"} .. "<br/><span style=\"font-size: smaller;\">" .. cur_display .. "</span>"
	end

	--------------------- Determine next/prev, next/prev outer, and upper/lower numbers. ----------------------

	-- We have three series of numbers to determine:
	--
	-- 1. The next/previous numbers, which are always those in the sorted series of available numbers unless overridden
	--    by `next`/`prev` specs in an individual number.
	-- 2. The next/previous outer numbers, which are displayed to the outside of the next/previous numbers. These can
	--    be overridden for an individual number using `next_outer`/`prev_outer`. Otherwise, we try according to an
	--    algorithm described below in the code for computing the outer numbers.
	-- 3. The upper/lower numbers, which are displayed above or below the central number box. These can be overridden
	--    for an individual number using `upper`/`lower`. These are always 10x greater or less than the number in
	--    question, number not considering a number if it's the same as the next/previous number.

	local next_num, prev_num = get_next_and_prev_keys(m_data, cur_num)
	local next_data = next_num and lookup_data(next_num, "next")
	local prev_data = prev_num and lookup_data(prev_num, "previous")

	--------- Decompose number into mantissa (k) and exponent (m). ----------

	local k, m
	if cur_num == "0" then
		k = 0
		m = 1
	else
		local kstr, mstr = cur_num:match("^([0-9]*[1-9])(0*)$")
		if not kstr then
			error("Internal error: Unable to match number '" .. cur_num .. "'")
		elseif #kstr > 15 then
			-- This is because some numbers with 16 or more digits can't be represented exactly.
			error("Can't handle number with more than 15 digits before the trailing zeros: '" .. cur_num .. "'")
		end
		k = tonumber(kstr)
		m = #mstr
	end

	-- Find the next greater power of 10 for cur_num, up to 10^6. `try` should look up the data for a power of 10
	-- and return it if it's available and the number passes any checks, otherwise nil.
	local function make_greater_power_of_ten(power)
		return cur_num .. string.rep("0", power)
	end

	-- Find the next lesser power of 10 for cur_num, up to 10^6. `try` should look up the data for a power of 10
	-- and return it if it's available and the number passes any checks, otherwise nil.
	local function make_lesser_power_of_ten(power)
		local desired_zeros = m - power
		if desired_zeros < 0 then
			return nil
		end
		return k .. string.rep("0", desired_zeros)
	end


	local next_outer_data, prev_outer_data
	local next_outer_num, prev_outer_num = cur_data.next_outer, cur_data.prev_outer

	-- When trying to find then next/previous outer numbers, first, if the base-10 mantissa is not 1 or 0, we add 1 to
	-- or subtract 1 from the mantissa, keeping the same number of zeros. Hence, for 300, we try 400 for the next outer,
	-- 200 for the previous outer. For 900, we try 1000 for the next outer and 800 for the previous outer. If the
	-- mantissa is 1, the next outer is computed the same but for the previous outer we use 9 followed by one fewer
	-- zero. Hence, for 100 we try 200 for the next outer but 90 for the previous outer. If the mantissa is 0 (i.e. the
	-- entire number is 0), we try 10 for the next outer, and have no previous outer.
	--
	-- Next, if the number is an even power of 10, we try 10x, 1000x greater, 100x greater and 1,000,000x greater, in
	-- that sequence. Essentially, first we try the next power of 10; then we try the next short-scale number (billion,
	-- trillion, etc. where large numbers follow a 10^3 sequence); then we try the next long-scale number (where large
	-- numbers follow a 10^6 sequence); then we try the next Indic-scale number (where large numbers follow a 10^2
	-- sequence: lakh, crore, arab, ...). We don't just try powers of 10 in order because then if e.g. we have entries
	-- for one million, ten million, one hundred million and one billion, and the current number is one million, the
	-- next number will be ten million and the next outer number one hundred million, when it would be cleaner to have
	-- one billion as the outer number (and in many cases, there is no Wiktionary entry for one hundred million).
	--
	-- For the previous outer number, we do an analogous algorithm but make sure we don't try numbers less than 1.
	local power_of_10_sequence = { 1, 3, 2, 6 }

	--------- Determine next outer number. ----------
	if next_outer_num then
		next_outer_data = lookup_data(next_outer_num, "next outer")
	else
		local function try(num)
			local data = (not next_num or export.numbers_greater_than(num, next_num)) and lookup_data(num) or nil
			if data then
				next_outer_num = num
				next_outer_data = data
			end
			return data
		end
		if not try((k + 1) .. string.rep("0", m)) and k == 1 then
			-- Try looking up a greater power of ten instead.
			for _, power_of_10 in ipairs(power_of_10_sequence) do
				if try(make_greater_power_of_ten(power_of_10)) then
					break
				end
			end
		end
	end

	--------- Determine previous outer number. ----------
	if prev_outer_num then
		prev_outer_data = lookup_data(prev_outer_num, "previous outer")
	else
		local function try(num)
			local data = (not prev_num or export.numbers_less_than(num, prev_num)) and lookup_data(num) or nil
			if data then
				prev_outer_num = num
				prev_outer_data = data
			end
			return data
		end
		if k == 0 or m == 0 then
			-- less than 10; no previous outer num
		else
			local num_to_try
			if k == 1 then
				num_to_try = "9" .. string.rep("0", m - 1)
			else
				num_to_try = (k - 1) .. string.rep("0", m)
			end
			if not try(num_to_try) and k == 1 then
				-- Try looking up a smaller power of ten instead.
				for _, power_of_10 in ipairs(power_of_10_sequence) do
					local num_to_try = make_lesser_power_of_ten(power_of_10)
					if num_to_try and try(num_to_try) then
						break
					end
				end
			end
		end
	end

	local upper_data, lower_data
	local upper_num, lower_num = cur_data.upper, cur_data.lower

	--------- Determine upper number. ----------
	if upper_num then
		upper_data = lookup_data(upper_num, "upper")
	else
		-- Try looking up the next power of ten.
		upper_num = make_greater_power_of_ten(1)
		if upper_num == next_num or cur_num == "0" then
			upper_num = nil
		else
			upper_data = lookup_data(upper_num)
		end
	end

	--------- Determine lower number. ----------
	if lower_num then
		lower_data = lookup_data(lower_num, "lower")
	elseif k == 0 or m == 0 then
		-- less than 10; no lower num
	else
		-- Try looking up the previous power or 10.
		lower_num = make_lesser_power_of_ten(1)
		if lower_num == prev_num then
			lower_num = nil
		else
			lower_data = lookup_data(lower_num)
		end
	end

	-- For a number `num` (an "adjacent" number to the current number, i.e. either next, previous, next/previous outer,
	-- or upper/lower) with corresponding entry data `num_data`, display link(s) to the form(s) for this number that
	-- are associated with the current type and tag. If there is a single form to be linked to, the form is linked
	-- using the number itself as the display text; otherwise, the multiple forms are linked with superscripted [a],
	-- [b], etc. and the number it displayed adjacent to the links. In either case, beside the number there may be an
	-- arrow. If `arrow` == "rarrow", the format is like this:
	--		if multiple entries:
	--			<numeral> → <sup>[a], [b], ...</sup>
	--		else
	--			<numeral> →
	-- If `arrow` == "larrow", the format is like this:
	--		if multiple entries:
	--			<sup>[a], [b], ...</sup> ← <numeral>
	--		else
	--			← <numeral>
	-- Otherwise, the format is like this:
	--		if multiple entries:
	--			<numeral><sup>[a], [b], ...</sup>
	--		else
	--			<numeral>
	--
	-- Returns nil if `num_data` is nil or there is no entry in `num_data` for the current number type.
	--
	-- For the handling of tags in this function, see the "LONG COMMENT EXPLAINING TAG HANDLING" above.
	local function display_adjacent_number_links(num, num_data, arrow)
		if not num_data then
			return nil
		end
		local num_type_data = num_data[cur_type]
		if not num_type_data then
			return nil
		end
		local forms = num_type_data
		if type(forms) ~= "table" then
			forms = {forms}
		end

		local seen_forms, forms_by_tag = export.group_numeral_forms_by_tag(forms)

		local forms_to_display
		if cur_tag and forms_by_tag[cur_tag] then
			forms_to_display = forms_by_tag[cur_tag]
		else
			forms_to_display = seen_forms
		end

		for i, form_to_display in ipairs(forms_to_display) do
			forms_to_display[i] = form_to_display.link or maybe_unaffix(m_data,
				form_to_entry_name(form_to_display.form, lang))
		end

		local seen_pagenames = {}
		local pagenames_to_display = {}
		for _, form in ipairs(forms_to_display) do
			if not seen_pagenames[form] then
				table.insert(pagenames_to_display, form)
				seen_pagenames[form] = true
			end
		end

		if #pagenames_to_display == 0 then
			return nil
		end

		num = export.format_number_for_display(num)
		local num_arrow =
			arrow == "rarrow" and num .. "&nbsp;&nbsp;→&nbsp;" or
			arrow == "larrow" and "&nbsp;←&nbsp;&nbsp;" .. num or
			num
		if #pagenames_to_display > 1 then
			local a = ("a"):byte()
			local links = {}
			for i, term in ipairs(pagenames_to_display) do
				links[i] = m_links.language_link{lang = lang, term = term, alt = "[" .. string.char(a + i - 1) .. "]"}
			end
			links = "<sup>" .. table.concat(links, ", ") .. "</sup>"
			return arrow == "larrow" and links .. num_arrow or num_arrow .. links
		else
			return m_links.language_link {
				lang = lang,
				term = pagenames_to_display[1],
				alt = num_arrow,
			}
		end
	end

	-- Display links to previous/next numbers
	local prev_display = display_adjacent_number_links(prev_num, prev_data, "larrow") or ""
	local next_display = display_adjacent_number_links(next_num, next_data, "rarrow") or ""

	-- Display links to previous/next outer numbers
	local prev_outer_display = display_adjacent_number_links(prev_outer_num, prev_outer_data, "larrow")
	local next_outer_display = display_adjacent_number_links(next_outer_num, next_outer_data, "rarrow")

	-- Display links to upper/lower numbers
	local upper_display = display_adjacent_number_links(upper_num, upper_data)
	local lower_display = display_adjacent_number_links(lower_num, lower_data)

	local canonical_name = lang:getCanonicalName()
	local appendix1 = canonical_name .. " numerals"
	local appendix2 = canonical_name .. " numbers"
	local appendix
	local title
	if mw.title.new(appendix1, "Appendix").exists then
		appendix = appendix1
	elseif mw.title.new(appendix2, "Appendix").exists then
		appendix = appendix2
	end

	if appendix then
		title = "[[Appendix:" .. appendix .. "|" .. appendix2 .. "]]"
	else
		title = appendix2
	end

	local function format_cell(contents, class_name, colspan, bold)
		class_name = class_name and (" " .. class_name) or ""
		colspan = colspan and ('colspan="%s" '):format(colspan) or ""
		bold = bold and "!" or "|"
		return ('%s %sclass="table-cell %s | %s\n'):format(bold, colspan, class_name, contents)
	end

	local has_outer_display = not not (prev_outer_display or next_outer_display)
	local function format_upper_lower_display_row(display)
		local blank_cell
		if has_outer_display then
			blank_cell = '| colspan="2" |\n'
		else
			blank_cell = "|\n"
		end
		local parts = {'|- class="adjacent-panel"\n'}
		table.insert(parts, blank_cell)
		table.insert(parts, format_cell(display, "adjacent-number"))
		table.insert(parts, blank_cell)
		return table.concat(parts)
	end

	upper_display = upper_display and format_upper_lower_display_row(upper_display) or ""
	lower_display = lower_display and format_upper_lower_display_row(lower_display) or ""

	local function format_display_cell(display)
		return format_cell(display, "adjacent-number")
	end

	prev_display = format_display_cell(prev_display)
	next_display = format_display_cell(next_display)
	prev_outer_display = has_outer_display and format_display_cell(prev_outer_display or "") or ""
	next_outer_display = has_outer_display and format_display_cell(next_outer_display or "") or ""
	cur_display = format_cell(cur_display, "current-number", nil, "bold")

	local forms_display = ('| colspan="%s" style="text-align: center;" | %s\n'):format(
		has_outer_display and 5 or 3, table.concat(formatted_forms, "<br/>"))

	local footer_display
	if cur_data.wplink then
		local footer =
			"[[w:" .. lang:getCode() .. ":Main Page|" .. lang:getCanonicalName() .. " Wikipedia]] article on " ..
			m_links.full_link{lang = lang, term = "w:" .. lang:getCode() .. ":" .. cur_data.wplink,
			alt = export.format_number_for_display(cur_num)}
		footer_display = '|- style="text-align: center;"\n' .. format_cell(footer, "footer-cell", has_outer_display and 5 or 3)
	else
		footer_display = ""
	end

	local edit_link = ' <sup>(<span class="plainlinks">[' ..
		tostring(mw.uri.fullUrl(module_name, { action = "edit" })) ..
		" edit]</span>)</sup>"

	return [=[{| class="floatright number-box" cellpadding="5" cellspacing="0" style="background: #ffffff; border: 1px #aaa solid; border-collapse: collapse; margin-top: .5em;" rules="all"
|+ ''']=] .. title .. edit_link .. "'''\n" ..
	upper_display .. '|- style="text-align: center;"\n' ..
	prev_outer_display .. prev_display .. cur_display .. next_display .. next_outer_display .. "|-\n" ..
	lower_display .. "|-\n" ..
	forms_display .. footer_display .. "|}" .. require("TemplateStyles")("Template:number box/styles.css")
end


-- Assumes string or nil (or false), the types that can be found in an args table.
local function if_not_empty(val)
	if val and mw.text.trim(val) == "" then
		return nil
	else
		return val
	end
end


function export.show_box_manual(frame)
	local m_links = require("links")
	local num_type = frame.args["type"]

	local args = {}
	--cloning parent's args while also assigning nil to empty strings
	for pname, param in pairs(frame:getParent().args) do
		args[pname] = if_not_empty(param)
	end

	local lang = args[1] or (mw.title.getCurrentTitle().nsText == "Template" and "und") or error("Language code has not been specified. Please pass parameter 1 to the template.")
	local sc = args["sc"];
	local headlink = args["headlink"]
	local wplink = args["wplink"]
	local alt = args["alt"]
	local tr = args["tr"]

	local prev_symbol = if_not_empty(args[2])
	local cur_symbol = if_not_empty(args[3]);
	local next_symbol = if_not_empty(args[4])

	local prev_term = if_not_empty(args[5])
	local next_term = if_not_empty(args[6])

	local cardinal_term = args["card"]; local cardinal_alt = args["cardalt"]; local cardinal_tr = args["cardtr"]

	local ordinal_term = args["ord"]; local ordinal_alt = args["ordalt"]; local ordinal_tr = args["ordtr"]

	local adverbial_term = args["adv"]; local adverbial_alt = args["advalt"]; local adverbial_tr = args["advtr"]

	local multiplier_term = args["mult"]; local multiplier_alt = args["multalt"]; local multiplier_tr = args["multtr"]

	local distributive_term = args["dis"]; local distributive_alt = args["disalt"]; local distributive_tr = args["distr"]

	local collective_term = args["coll"]; local collective_alt = args["collalt"]; local collective_tr = args["colltr"]

	local fractional_term = args["frac"]; local fractional_alt = args["fracalt"]; local fractional_tr = args["fractr"]

	local optional1_title = args["opt"]
	local optional1_term = args["optx"]; local optional1_alt = args["optxalt"]; local optional1_tr = args["optxtr"]

	local optional2_title = args["opt2"]
	local optional2_term = args["opt2x"]; local optional2_alt = args["opt2xalt"]; local optional2_tr = args["opt2xtr"]


	lang = require("languages").getByCode(lang) or error("The language code \"" .. lang .. "\" is not valid.")
	sc = (sc and (require("scripts").getByCode(sc) or error("The script code \"" .. sc .. "\" is not valid.")) or nil)

	track(lang:getCode())

	if sc then
		track("sc")
	end

	if headlink then
		track("headlink")
	end

	if wplink then
		track("wplink")
	end

	if alt then
		track("alt")
	end

	if cardinal_alt or ordinal_alt or adverbial_alt or multiplier_alt or distributive_alt or collective_alt or fractional_alt or optional1_alt or optional2_alt then
		track("xalt")
	end

	local subpage = mw.title.getCurrentTitle().subpageText
	local is_reconstructed = lang:hasType("reconstructed") or mw.title.getCurrentTitle().nsText == "Reconstruction"
	
	-- Commenting out this line prevents passing redundant alts to full_link;
	-- however, there may have been a purpose to it.
	-- alt = alt or (is_reconstructed and "*" or "") .. subpage

	if num_type == "cardinal" then
		cardinal_term = (is_reconstructed and "*" or "") .. subpage
		cardinal_alt = alt
		cardinal_tr = tr
	elseif num_type == "ordinal" then
		ordinal_term = (is_reconstructed and "*" or "") .. subpage
		ordinal_alt = alt
		ordinal_tr = tr
	end

	local header = lang:getCanonicalName() .. " " .. num_type .. " numbers"

	if headlink then
		header = "[[" .. headlink .. "|" .. header .. "]]"
	end

	local previous = ""

	if prev_term or prev_symbol then
		previous = m_links.full_link{lang = lang, sc = sc, term = prev_term, alt = "&nbsp;&lt;&nbsp;&nbsp;" .. prev_symbol, tr = "-", no_alt_ast = true}
	end

	local current = m_links.full_link{lang = lang, sc = sc, alt = cur_symbol, tr = "-", no_alt_ast = true}

	local next = ""

	if next_term or next_symbol then
		next = m_links.full_link{lang = lang, sc = sc, term = next_term, alt = next_symbol .. "&nbsp;&nbsp;&gt;&nbsp;", tr = "-", no_alt_ast = true}
	end

	local forms = {}

	if cardinal_term then
		table.insert(forms, " &nbsp;&nbsp;&nbsp; ''[[cardinal number|Cardinal]]'' : " .. m_links.full_link{lang = lang, sc = sc, term = cardinal_term, alt = cardinal_alt, tr = cardinal_tr})
	end

	if ordinal_term then
		table.insert(forms, " &nbsp;&nbsp;&nbsp; ''[[ordinal number|Ordinal]]'' : " .. m_links.full_link{lang = lang, sc = sc, term = ordinal_term, alt = ordinal_alt, tr = ordinal_tr})
	end

	if adverbial_term then
		table.insert(forms, " &nbsp;&nbsp;&nbsp; ''[[adverbial number|Adverbial]]'' : " .. m_links.full_link{lang = lang, sc = sc, term = adverbial_term, alt = adverbial_alt, tr = adverbial_tr})
	end

	if multiplier_term then
		table.insert(forms, " &nbsp;&nbsp;&nbsp; ''[[multiplier|Multiplier]]'' : " .. m_links.full_link{lang = lang, sc = sc, term = multiplier_term, alt = multiplier_alt, tr = multiplier_tr})
	end

	if distributive_term then
		table.insert(forms, " &nbsp;&nbsp;&nbsp; ''[[distributive number|Distributive]]'' : " .. m_links.full_link{lang = lang, sc = sc, term = distributive_term, alt = distributive_alt, tr = distributive_tr})
	end

	if collective_term then
		table.insert(forms, " &nbsp;&nbsp;&nbsp; ''[[collective number|Collective]]'' : " .. m_links.full_link{lang = lang, sc = sc, term = collective_term, alt = collective_alt, tr = collective_tr})
	end

	if fractional_term then
		table.insert(forms, " &nbsp;&nbsp;&nbsp; ''[[fractional|Fractional]]'' : " .. m_links.full_link{lang = lang, sc = sc, term = fractional_term, alt = fractional_alt, tr = fractional_tr})
	end

	if optional1_title then
		table.insert(forms, " &nbsp;&nbsp;&nbsp; ''" .. optional1_title .. "'' : " .. m_links.full_link{lang = lang, sc = sc, term = optional1_term, alt = optional1_alt, tr = optional1_tr})
	end

	if optional2_title then
		table.insert(forms, " &nbsp;&nbsp;&nbsp; ''" .. optional2_title .. "'' : " .. m_links.full_link{lang = lang, sc = sc, term = optional2_term, alt = optional2_alt, tr = optional2_tr})
	end

	local footer = ""

	if wplink then
		footer =
			"[[w:" .. lang:getCode() .. ":Main Page|" .. lang:getCanonicalName() .. " Wikipedia]] article on " ..
			m_links.full_link{lang = lang, sc = sc, term = "w:" .. lang:getCode() .. ":" .. wplink, alt = alt, tr = tr}
	end

	return [=[{| class="floatright number-box" cellpadding="5" cellspacing="0" rules="all"
|+ ''']=] .. header .. [=['''
|-
| class="adjacent-slot" | ]=] .. previous .. [=[

! class="current-slot" | ]=] .. current .. [=[

| class="adjacent-slot" | ]=] .. next .. [=[

|-
| colspan="3" class="form-slot" | ]=] .. table.concat(forms, "<br/>") .. [=[

|-
| colspan="3" class="footer-slot" | ]=] .. footer .. [=[

|}]=] .. require("TemplateStyles")("Template:number box/styles.css")
end

return export