local export = {}

local rsplit = mw.text.split
local u = mw.ustring.char
local MARK_CONJOINED_SHORTCUT = u(0xFFF0)
local split_term_regex = "%*~!"

local m_table = require("table")
local form_of_module = "Module:form of"

--[=[
The purpose of the acceleration code is to auto-generate pages for non-lemma forms (inflections) of a given lemma.
The way it works is approximately as follows:

1. When you have the accelerator gadget in [[MediaWiki:Gadget-AcceleratedFormCreation.js]] enabled, and you click on a
   green link, the JavaScript code gathers all the green links on the page that have the same language and pagename as
   the clicked-on green link and sends them to the generate_JSON() function in this module, which is a thin wrapper
   around the generate() function. Each individual green link maps to an "entry" and has associated accelerator
   properties that were specified by the `accel` object passed into full_link() in [[Module:links]]. Note that there can
   -- be multiple entries passed to a single generate() call for various reasons, e.g.:
   (1) Inside of a single inflection table there is syncretism, with two different inflections having the same form;
       e.g. the same Latin form ''bonī'' occurs in three different inflections of the lemma [[bonus]]: the masculine
	   genitive singular, neuter genitive singular and masculine nominative plural. Hence there will be three entries.
   (2) Inside of a single inflection table there are inflections that are spelled differently but map to the same
       pagename due to diacritic removal; e.g. Latin ''bona'' (occurring in five different inflections: the feminine
	   nominative and vocative singular and the neuter nominative, accusative and vocative plural) and Latin ''bonā''
	   (the feminine ablative singular) will be merged together into a single call to generate() with six entries.
   (3) There are two or more inflection tables, partly or completely duplicative. E.g. if a given lemma has
       Etymology 1 and Etymology 2 sections, and the inflection of each separate etymology is the same and associated
	   with its own table, then clicking on any green link will result in (at least) two entries.

2. The generate() function is invoked like a template call, meaning all its arguments come as strings and need to be
   parsed. It does the following steps:

   (1) Parse its arguments.
   (2) Convert each set of per-entry parameters into a `params` object.
   (3) For each `params` object, generate a default entry, then, if there is a language-specific accelerator submodule,
       call that module to customize the entry.
   (4) Merge duplicate entries. This not only looks for completely duplicated entries but tries to merge entries that
       differ only in the definition. In general, this will result in multiple definition lines under a single entry,
	   but definition lines that consist of calls to {{infl of}} will be further merged. For example, for the
	   example above with ''bona'' and ''bonā'', the five inflections of ''bona'' will be merged into a single entry
	   with a single call to {{infl of}} that looks something like this:
	   # {{infl of|la|bonus||nom//voc|f|s|;|nom//acc//voc|n|p}}
	   In other words, not only are the inflections combined into a single call to {{infl of}}, but inflections
	   with partly shared tags are further merged.
   (5) Generate the Pronunciation and Etymology sections that go at the top, above all the entries. This is done either
       by calling custom generate functions in the language-specific accelerator submodule, or (if those aren't given)
	   by merging the individual pronunciation and etymology lines, removing duplicates. Note that the default entry
	   generated in step (3) has no pronunciation or etymology (which are generated only by a language-specific
	   submodule), so by default there will be no Pronunciation or Etymology section.
   (6) Assemble the parts of each entry into a string and paste all the strings together, along with any combined
       Pronunciation and Etymology sections, to form the text of the entire per-language L2 section. Note that if you
	   have enabled the OrangeLinks gadget, accelerator entries can be created on already-existing pages, as long as
	   there's no L2 section for the language of the entries.
]=]

-- A simple implementation of an ordered set.
local function create_ordered_set()
	return {
		array = {},
		set = {},
	}
end

-- Add an item to the ordered set. `squashed_item` is a representation of the item as a string or number, so that we
-- can use it as the key in a set. `orig_item` is the original item and can be omitted if it's the same as
-- `squashed_item`.
local function add_item(ordered_set, squashed_item, orig_item)
	if not ordered_set.set[squashed_item] then
		table.insert(ordered_set.array, orig_item or squashed_item)
		ordered_set.set[squashed_item] = true
	end
end


-- Generate the default entry 
function export.default_entry(params)
	local function make_head(pos, default_gender)
		local gender = params.gender or default_gender
		local genderspec = ""
		if gender then
			local genders = rsplit(gender, ",")
			for i, g in ipairs(genders) do
				if i == 1 then
					genders[i] = "|g=" .. g
				else
					genders[i] = "|g" .. i .. "=" .. g
				end
			end
			genderspec = table.concat(genders)
		end
		local parts = {}
		table.insert(parts, "{{head|" .. params.lang:getCode() .. "|" .. pos)
		for i, target in ipairs(params.targets) do
			local paramnum = i == 1 and "" or tostring(i)
			if target.term ~= params.target_pagename then
				table.insert(parts, ("|head%s=%s"):format(paramnum, target.term))
			end
			if target.translit then
				table.insert(parts, ("|tr%s=%s"):format(paramnum, target.translit))
			end
		end
		table.insert(parts, genderspec .. "}}")
		return table.concat(parts)
	end

	local function make_def(tempname, extra_params)
		local parts = {}
		table.insert(parts, "{{" .. tempname .. "|" .. params.lang:getCode())
		for i, origin in ipairs(params.origins) do
			local termparam, trparam
			if i == 1 then
				termparam = ""
				trparam = "tr="
			else
				termparam = "term" .. i .. "="
				trparam = "tr" .. i .. "="
			end
			table.insert(parts, ("|%s%s"):format(termparam, origin.term))
			if origin.translit then
				table.insert(parts, ("|%s%s"):format(trparam, origin.translit))
			end
		end
		table.insert(parts, (extra_params or "") .. "}}")
		return table.concat(parts)
	end

	local function no_rule_error(params)
		-- FIXME, verify the 2 below (number of stack frames to pop off); may be wrong now that we moved this function
		-- underneath default_entry().
		return error(('No rule for "%s" in language "%s" ("%s").')
			:format(params.form, params.lang:getCode(), params.lang:getCanonicalName()), 2)
	end

	local entry = {
		etymology = nil,
		pronunc = nil,
		pos_header = mw.getContentLanguage():ucfirst(params.pos),
		head = make_head(params.pos .. " form"),
		def = make_def("infl of", "||" .. params.form),
		inflection = nil,
		declension = nil,
		conjugation = nil,
		mutation = nil,
		altforms = nil,
		-- also pass in functions
		make_head = make_head,
		make_def = make_def,
		no_rule_error = no_rule_error,
	}

	-- Exceptions for some forms
	local templates = {
		["p"] = "plural of",
		["f"] = "feminine of",
		["f|s"] = "feminine singular of",
		["m|p"] = "masculine plural of",
		["f|p"] = "feminine plural of",
		["pejorative"] = "pejorative of",
	}

	if params.form == "comparative" or params.form == "superlative" or params.form == "equative" then
		entry.head = make_head(params.form .. " " .. params.pos)
		entry.def = make_def(params.form .. " of", params.pos ~= "adjective" and "|POS=" .. params.pos or "")
	elseif params.form == "diminutive" or params.form == "augmentative" then
		entry.head = make_head(params.pos)
		entry.def = make_def(params.form .. " of", params.pos ~= "noun" and "|POS=" .. params.pos or "")
	elseif params.form == "f" and params.pos == "noun" then
		entry.head = make_head(params.pos, "f")
		entry.def = make_def("female equivalent of")
	elseif (params.form == "past|part" or params.form == "past|ptcp") and params.pos == "verb" then
		entry.pos_header = "Participle"
		entry.head = make_head("past participle")
	elseif (params.form == "pres|part" or params.form == "pres|ptcp") and params.pos == "verb" then
		entry.pos_header = "Participle"
		entry.head = make_head("present participle")
	elseif (params.form == "abstract noun" or params.form == "verbal noun") and params.pos == "noun" then
		entry.head = make_head(params.pos)
		entry.def = make_def(params.form .. " of")
	elseif templates[params.form] then
		entry.def = make_def(templates[params.form])
	end

	return entry
end

-- Canonicalize multipart shortcuts (e.g. "123" -> "1//2//3") and non-conjoined list shortcuts (e.g. "1s" ->
-- {"1", "s"}); leave others alone, including conjoined shortcuts. The purpose of canonicalizing list shortcuts is so
-- that e.g. we can combine '1s|pres|ind' with '2|s|pres|ind'. However, conjoined shortcuts like "e-form" ->
-- {"pl", ";", "def", "s", "attr"} would require significantly more logic to handle correctly, and it's highly unlikely
-- we could find another similar enough tag to combine with (if it even makes sense to do so at all).
local function canonicalize_multipart_and_list_shortcuts(tags, lang)
	local result = {}
	for _, tag in ipairs(tags) do
		local expansion = require(form_of_module).lookup_shortcut(tag, lang)
		if type(expansion) == "string" and not expansion:find("//", nil, true) then
			expansion = tag
		end
		if type(expansion) == "table" then
			if m_table.contains(expansion, ";") then
				table.insert(result, tag)
			else
				m_table.extendList(result, expansion)
			end
		else
			table.insert(result, expansion)
		end
	end
	return result
end

-- Split a multipart tag into component tags, normalize each component, and return the resulting list. If
-- MAP_TO_CANONICAL_SHORTCUT is given, attempt to map each normalized component tag to its "canonical shortcut", i.e.
-- the first shortcut listed among its shortcuts.
--
-- If given a two-level multipart tag such as "1:sg//3:pl", the resulting return value will be {"first:singular",
-- "third:plural"}, or {"1:s", "3:p"} if MAP_TO_CANONICAL_SHORTCUT is given.
local function split_and_normalize_tag(tag, lang, map_to_canonical_shortcut)
	local m_form_of = require(form_of_module)
	local normalized = m_form_of.normalize_tag_set({tag}, lang)
	if #normalized > 1 then
		-- Tag is a conjoined shortcut. We leave these in their non-canonicalized form; see comment above
		-- canonicalize_multipart_and_list_shortcuts(). But we mark them with a special character so we know that
		-- they are non-normalized conjoined shortcuts, and later remove the mark.
		return {tag .. MARK_CONJOINED_SHORTCUT}
	end
	normalized = normalized[1]
	assert(#normalized == 1, "Internal error: Encountered list tag " .. tag .. ", which should have been canonicalized earlier")
	local multipart = normalized[1]
	if type(multipart) == "string" then
		multipart = {multipart}
	end
	if map_to_canonical_shortcut then
		local function get_canonical_shortcut(tag, lang)
			local tagobj = m_form_of.lookup_tag(tag, lang)
			local tag_shortcuts = tagobj and tagobj[m_form_of.SHORTCUTS]
			if tag_shortcuts and type(tag_shortcuts) == "table" then
				tag_shortcuts = tag_shortcuts[1]
			end
			return tag_shortcuts or tag
		end
		for i, mpart in ipairs(multipart) do
			if type(mpart) == "table" then
				-- two-level multipart
				for j, single_tag in ipairs(mpart) do
					mpart[j] = get_canonical_shortcut(single_tag, lang)
				end
				multipart[i] = table.concat(mpart, ":")
			else
				multipart[i] = get_canonical_shortcut(mpart, lang)
			end
		end
	else
		for i, mpart in ipairs(multipart) do
			if type(mpart) == "table" then
				-- two-level multipart
				multipart[i] = table.concat(mpart, ":")
			end
		end
	end
	return multipart
end

-- Given a normalized tag, return its tag type, or "unknown" if a tag type
-- cannot be located (either the tag isn't recognized or for some reason
-- it doesn't specify a tag type).
local function get_normalized_tag_type(tag, lang)
	-- Make sure to return 'unknown' for non-normalized conjoined shortcuts as well as URL's and parts of two-level
	-- multipart tags (both of the latter two have colons in them). NOTE: In practice, the presence of the
	-- MARK_CONJOINED_SHORTCUT means we won't find a normalized tag having the same name even if one would exist in the
	-- absence of this mark, so this is more of an optimization.
	if tag:find(MARK_CONJOINED_SHORTCUT) or tag:find(":") then
		return "unknown"
	end
	local m_form_of = require(form_of_module)
	local tagobj = m_form_of.lookup_tag(tag, lang)
	return tagobj and tagobj[m_form_of.TAG_TYPE] or "unknown"
end

--[=[
Combine multiple semicolon-separated tag sets into multipart tags if possible. We combine tag sets that differ in
only one tag in a given dimension, and repeat this until no changes in case we can reduce along multiple dimensions,
e.g.

{{infl of|la|canus||dat|m|p|;|dat|f|p|;|dat|n|p|;|abl|m|p|;|abl|f|p|;|abl|n|p}}

{{infl of|la|canus||dat//abl|m//f//n|p}}

`tag_sets` is a list of objects of the form {tags = {"TAG", "TAG", ...}, labels = {"LABEL", "LABEL", ...}}, i.e. of the
same format as `data.tag_sets` as passed to tagged_inflections() in [[Module:form of]]. Also accepted is an "old-style"
list of strings, one element per tag, with tag sets separated by a semicolon, the same as in {{infl of}}.

The return value is in the same format as was passed into `tag_sets`. If an old-style tag list was passed in, and
labels are present, they are attached to the last tag in a tag set using an inline modifier.
]=]

function export.combine_tag_sets_into_multipart(tag_sets, lang, POS)
	if type(tag_sets) ~= "table" then
		error("`tag_sets` should be a table but is a(n) `" .. type(tag_sets) .. "`")
	end
	if not tag_sets[1] then
		error("Expected at least one item in `tag_sets`")
	end
	local old_style_tags = false
	if type(tag_sets[1]) == "string" then
		old_style_tags = true
	end

	-- First, as an optimization, make sure there are multiple tag sets. Otherwise, do nothing.
	if old_style_tags then
		local found_semicolon = false
		for _, tag in ipairs(tag_sets) do
			if tag == ";" then
				found_semicolon = true
				break
			end
		end
		if not found_semicolon then
			return tag_sets
		end
	elseif #tag_sets == 1 then
		return tag_sets
	end

	local m_form_of = require(form_of_module)

	-- If old-style tags (list of strings), convert to list of tag set objects.
	if old_style_tags then
		tag_sets = m_form_of.split_tags_into_tag_sets(tag_sets)
		for i, tag_set in ipairs(tag_sets) do
			tag_sets[i] = m_form_of.parse_tag_set_properties(tag_set)
		end
	else
		-- Otherwise, make a copy as we may modify the list in-place.
		tag_sets = m_table.deepcopy(tag_sets)
	end

	-- Repeat until no changes can be made.
	while true do
		-- First, determine the auto-generated label for each tag set and append to any user-specified labels.
		-- Best to do this on the raw tag sets, before canonicalize_multipart_and_list_shortcuts(). Then canonicalize
		-- 1s etc. into 1|s.
		for i, tag_set in ipairs(tag_sets) do
			tag_set.labels_with_auto = m_table.deepcopy(tag_set.labels or {})
			local normalized_tag_sets = m_form_of.normalize_tag_set(tag_set.tags, lang)
			for _, normalized_tag_set in ipairs(normalized_tag_sets) do
				local this_categories, this_labels = m_form_of.fetch_categories_and_labels(normalized_tag_set, lang, POS)
				m_table.extendList(tag_set.labels_with_auto, this_labels)
			end
			tag_set.tags = canonicalize_multipart_and_list_shortcuts(tag_set.tags, lang)
		end

		local canonicalized_tag_sets = tag_sets
		local old_canonicalized_tag_sets = canonicalized_tag_sets

		-- Try combining in two different styles ("adjacent-first" = do two passes, where the first pass only combines
		-- adjacent tag sets, while the second pass combines nonadjacent tag sets; "all-first" = do one pass combining
		-- nonadjacent tag sets). Sometimes one is better, sometimes the other.
		--
		-- An example where adjacent-first is better:
		--
		-- {{infl of|la|medius||m|acc|s|;|n|nom|s|;|n|acc|s|;|n|voc|s}}
		--
		-- all-first results in
		--
		-- {{infl of|la|medius||m//n|acc|s|;|n|nom//voc|s}}
		--
		-- which isn't ideal.
		--
		-- If we do adjacent-first, we get
		--
		-- {{infl of|la|medius||m|acc|s|;|n|nom//acc//voc|s}}
		--
		-- which is much better.
		--
		-- The opposite happens in
		--
		-- {{infl of|grc|βουλόμενος||n|nom|s|;|m|acc|s|;|n|acc|s|;|n|voc|s}}
		--
		-- where all-first results in
		--
		-- {{infl of|grc|βουλόμενος||n|nom//acc//voc|s|;|m|acc|s}}
		--
		-- which is better than the result from adjacent-first, which is
		--
		-- {{infl of|grc|βουλόμενος||n|nom//voc|s|;|m//n|acc|s}}
		--
		-- To handle this conundrum, we try both, and look to see which one results in fewer "combinations" (where a
		-- tag with // in it counts as a combination). If both are different but have the same # of combinations, we
		-- prefer adjacent-first, we seems generally a better approach.

		local tag_sets_by_style = {}

		for _, combine_style in ipairs({"adjacent-first", "all-first"}) do
			-- Now, we do two passes. The first pass only combines adjacent tag sets, while the second pass combines
			-- nonadjacent tag sets. Copy canonicalized_tag_sets, since we destructively modify the list.
			local this_tag_sets = m_table.deepcopy(canonicalized_tag_sets)
			local combine_passes
			if combine_style == "adjacent-first" then
				combine_passes = {"adjacent", "all"}
			else
				combine_passes = {"all"}
			end
			for _, combine_pass in ipairs(combine_passes) do
				local tag_ind = 1
				while tag_ind <= #this_tag_sets do
					local from, to
					if combine_pass == "adjacent" then
						if tag_ind == 1 then
							from = 1
							to = 0
						else
							from = tag_ind - 1
							to = tag_ind - 1
						end
					else
						from = 1
						to = tag_ind - 1
					end
					local inner_broken = false
					for prev_tag_ind = from, to do
						local cur_tag_set = this_tag_sets[prev_tag_ind]
						local tag_set = this_tag_sets[tag_ind]
						if #cur_tag_set.tags == #tag_set.tags and
							m_table.deepEquals(cur_tag_set.labels_with_auto, tag_set.labels_with_auto) then
							local mismatch_ind = nil
							local innermost_broken = false
							for i = 1, #tag_set.tags do
								local tag1 = split_and_normalize_tag(cur_tag_set.tags[i], lang)
								local tag2 = split_and_normalize_tag(tag_set.tags[i], lang)
								if not m_table.deepEquals(m_table.listToSet(tag1), m_table.listToSet(tag2)) then
									if mismatch_ind then
										innermost_broken = true
										break
									end
									local combined_dims = {}
									for _, tag in ipairs(tag1) do
										combined_dims[get_normalized_tag_type(tag, lang)] = true
									end
									for _, tag in ipairs(tag2) do
										combined_dims[get_normalized_tag_type(tag, lang)] = true
									end
									if m_table.size(combined_dims) == 1 and not combined_dims["unknown"] then
										mismatch_ind = i
									else
										innermost_broken = true
										break
									end
								end
							end
							if not innermost_broken then
								-- No break, we either match perfectly or are combinable
								if not mismatch_ind then
									-- Two identical tag sets
									table.remove(this_tag_sets, tag_ind)
									inner_broken = true
									break
								else
									-- Combine tag sets at mismatch_ind, using the canonical shortcuts.
									tag1 = cur_tag_set.tags[mismatch_ind]
									tag2 = tag_set.tags[mismatch_ind]
									tag1 = split_and_normalize_tag(tag1, lang, true)
									tag2 = split_and_normalize_tag(tag2, lang, true)
									-- Combine the normalized tags and remove the special MARK_CONJOINED_SHORTCUT mark
									-- on conjoined shortcuts so we have normal tags again.
									local combined_tag =
										table.concat(m_table.append(tag1, tag2), "//"):gsub(MARK_CONJOINED_SHORTCUT, "")
									local new_tag_set = {}
									for i = 1, #cur_tag_set.tags do
										if i == mismatch_ind then
											table.insert(new_tag_set, combined_tag)
										else
											local cur_canon_tag = split_and_normalize_tag(cur_tag_set.tags[i], lang)
											local canon_tag = split_and_normalize_tag(tag_set.tags[i], lang)
											assert(m_table.deepEquals(m_table.listToSet(cur_canon_tag),
												m_table.listToSet(canon_tag)))
											table.insert(new_tag_set, cur_tag_set.tags[i])
										end
									end
									this_tag_sets[prev_tag_ind].tags = new_tag_set
									table.remove(this_tag_sets, tag_ind)
									inner_broken = true
									break
								end
							end
						end
					end
					if not inner_broken then
						-- No break from inner for-loop. Break from that loop indicates that we found that the current
						-- tag set can be combined with a preceding tag set, did the combination and deleted the
						-- current tag set. The next iteration then processes the same numbered tag set again (which is
						-- actually the following tag set, because we deleted the tag set before it). No break
						-- indicates that we couldn't combine the current tag set with any preceding tag set, and need
						-- to advance to the next one.
						tag_ind = tag_ind + 1
					end
				end
			end
			tag_sets_by_style[combine_style] = this_tag_sets
		end

		if not m_table.deepEquals(tag_sets_by_style["adjacent-first"], tag_sets_by_style["all-first"]) then
			local function num_combinations(group)
				local num_combos = 0
				for _, tag_set in ipairs(group) do
					for _, tag in ipairs(tag_set.tags) do
						if tag:find("//") then
							num_combos = num_combos + 1
						end
					end
				end
				return num_combos
			end

			local num_adjacent_first_combos = num_combinations(tag_sets_by_style["adjacent-first"])
			local num_all_first_combos = num_combinations(tag_sets_by_style["all-first"])
			if num_adjacent_first_combos < num_all_first_combos then
				tag_sets = tag_sets_by_style["adjacent-first"]
			elseif num_all_first_combos < num_adjacent_first_combos then
				tag_sets = tag_sets_by_style["all-first"]
			else
				tag_sets = tag_sets_by_style["adjacent-first"]
			end
		else
			-- Both are the same, pick either one
			tag_sets = tag_sets_by_style["adjacent-first"]
		end

		if m_table.deepEquals(tag_sets, old_canonicalized_tag_sets) then
			break
		end
		-- FIXME, we should consider reversing the transformation 1s -> 1|s,
		-- but it's complicated to figure out when the transformation occurred;
		-- not really important as both are equivalent
	end

	if old_style_tags then
		local retval = {}
		for _, tag_set in ipairs(tag_sets) do
			if tag_set.labels and #tag_set.labels > 0 then
				tag_set.tags[#tag_set.tags] =
					tag_set.tags[#tag_set.tags] .. "<lb:" .. table.concat(tag_set.labels, ",") .. ">"
			end
			if #retval > 0 then
				table.insert(retval, ";")
			end
			m_table.extendList(retval, tag_set.tags)
		end
		return retval
	else
		for _, tag_set in ipairs(tag_sets) do
			tag_sets.labels_with_auto = nil
		end
		return tag_sets
	end
end

-- Test function, callable externally.
function export.test_combine_tag_sets_into_multipart(frame)
	local iparams = {
		[1] = {list = true, required = true},
		lang = {required = true},
	}

	local args = require("parameters").process(frame.args, iparams)
	local lang = require("languages").getByCode(args.lang, true)
	local combined_tags = export.combine_tag_sets_into_multipart(args[1], lang)
	return table.concat(combined_tags, "|")
end

-- Check whether `entry` (an object describing a given non-lemma form, with properties such as `pronunc` for
-- pronunciation, `def` for definition, etc.) can be merged with any of the existing entries listed in `candidates`.
-- "Can be merged" means that all relevant properties (basically, everything but the definition) can are the same.
-- Return the first such candidate found, or nil if no candidates match `entry`.
local function find_mergeable(entry, candidates)
	local function can_merge(candidate)
		for _, key in ipairs({"pronunc", "etymology", "pos_header", "head", "inflection", "declension", "conjugation", "altforms"}) do
			local val1 = entry[key]
			local val2 = candidate[key]
			local is_equal
			-- `pronunc` and `etymology` could be tables; the default code for merging pronunciation and etymology can
			-- handle tables of strings.
			if type(val1) == "table" and type(val2) == "table" then
				is_equal = m_table.deepEquals(val1, val2)
			else
				is_equal = val1 == val2
			end

			if not is_equal then
				return false
			end
		end

		return true
	end

	for _, candidate in ipairs(candidates) do
		if can_merge(candidate) then
			return candidate
		end
	end

	return nil
end


-- Merge multiple entries into one if they differ only in the definition, with all other
-- properties the same. The combined entry has multiple definition lines. We then do
-- further frobbing of {{infl of}} lines:
--
-- 1. Convert lang= param to param 1 (there shouldn't be any remaining cases of accelerator
--    modules generating {{infl of}} templates with lang=, but we do this just in case).
-- 2. Combine adjacent {{infl of}} lines that differ only in the tags, e.g.:
--
--    # {{infl of|la|bonus||nom|m|s}}
--    # {{infl of|la|bonus||nom|n|s}}
--    # {{infl of|la|bonus||acc|n|s}}
--    # {{infl of|la|bonus||voc|n|s}}
--
--    becomes
--
--    # {{infl of|la|bonus||nom|m|s|;|nom|n|s|;|acc|n|s|;|voc|n|s}}
--
-- 3. Further group {{infl of}} lines with multiple tag sets (as may be generated b y
--    the previous step) using multipart tags, e.g. for the Latin entry ''bonum'',
--
--    # {{infl of|la|bonus||nom|m|s|;|nom|n|s|;|acc|n|s|;|voc|n|s}}
--
--    becomes
--
--    # {{infl of|la|bonus||nom|m|s|;|nom//acc//voc|n|s}}
--
--    This grouping can group across multiple dimensions, e.g. for the Latin entry ''bonīs'',
--
--    # {{infl of|la|bonus||dat|m|p|;|dat|f|p|;|dat|n|p|;|abl|m|p|;|abl|f|p|;|abl|n|p}}
--
--    becomes
--
--    # {{infl of|la|bonus||dat//abl|m//f//n|p}}
--
--    Another complex real-world example, for the Old English weak adjective form ''dēorenan'':
--
--    # {{infl of|ang|dēoren||wk|acc|m|sg|;|wk|acc|f|sg|;|wk|gen|m|sg|;|wk|gen|f|sg|;|wk|gen|n|sg|;|wk|dat|m|sg|;|wk|dat|f|sg|;|wk|dat|n|sg|;|wk|ins|m|sg|;|wk|ins|f|sg|;|wk|ins|n|sg|;|wk|nom|m|pl|;|wk|nom|f|pl|;|wk|nom|n|pl|;|wk|acc|m|pl|;|wk|acc|f|pl|;|wk|acc|n|pl}}
--
--    becomes
--
--    # {{infl of|ang|dēoren||wk|acc|m//f|sg|;|wk|gen//dat//ins|m//f//n|sg|;|wk|nom//acc|m//f//n|pl}}
--
--    Here, 17 separate tag sets are combined down into 3.
local function merge_entries(entries_obj)
	local entries_new = {}

	-- First rewrite {{infl of|...|lang=LANG}} to {{infl of|LANG|...}}
	for _, entry in ipairs(entries_obj.entries) do
		local params = entry.def:match("^{{infl of|([^{}]+)}}$")
		if not params then
			params = entry.def:match("^{{inflection of|([^{}]+)}}$")
		end
		if params then
			params = rsplit(params, "|", true)
			local new_params = {}
			for _, param in ipairs(params) do
				local lang = param:match("^lang=(.*)$")
				if lang then
					table.insert(new_params, 1, lang)
				else
					table.insert(new_params, param)
				end
			end
			entry.def = "{{infl of|" .. table.concat(new_params, "|") .. "}}"
		end
	end

	-- Merge entries that match in all of the following properties:
	-- "pronunc", "etymology", "pos_header", "head", "inflection", "declension", "conjugation", "altforms"
	-- This will merge any two mergeable entries even if non-consecutive.
	-- The definitions of the merged entries do not have to match, but any matching
	-- definitions will be deduped.
	for _, entry in ipairs(entries_obj.entries) do
		-- See if this entry can be merged with any previous entry.
		local merge_entry = find_mergeable(entry, entries_new)

		if merge_entry then
			local duplicate_def = false
			-- If we can merge, check whether the definition of the new entry is
			-- the same as any previous definitions.
			for _, def in ipairs(merge_entry.defs) do
				if def == entry.def then
					duplicate_def = true
					break
				end
			end

			if not duplicate_def then
				table.insert(merge_entry.defs, entry.def)
			end
		else
			entry.defs = {entry.def}
			table.insert(entries_new, entry)
		end
	end

	-- Combine the definitions for each entries, merging all {{infl of}} calls
	-- into one such call with multiple tag sets.
	for _, entry in ipairs(entries_new) do
		local existing_defs = {}
		for _, new_def in ipairs(entry.defs) do
			local did_merge = false
			local new_params = new_def:match("^{{infl of|([^{}]+)}}$")
			if not new_params then
				new_params = entry.def:match("^{{inflection of|([^{}]+)}}$")
			end
			if new_params then
				-- The new definition is {{infl of}}. See if there is an
				-- {{infl of}} among the definitions seen so far.
				for i, existing_def in ipairs(existing_defs) do
					local existing_params = existing_def:match("^{{infl of|([^{}]+)}}$")
					if not existing_params then
						existing_params = existing_def:match("^{{inflection of|([^{}]+)}}$")
					end
					if existing_params then
						-- Merge the existing and new {{infl of}} calls.
						-- Find the last unnamed parameter of the first template.
						existing_params = rsplit(existing_params, "|", true)
						local last_numbered_index

						for j, param in ipairs(existing_params) do
							if not param:find("=", nil, true) then
								last_numbered_index = j
							end
						end

						-- Add grammar tags of the second template
						new_params = rsplit(new_params, "|")
						local tags = {}
						local n = 0

						for k, param in ipairs(new_params) do
							if not param:find("=", nil, true) then
								n = n + 1

								-- Skip the first three unnamed parameters,
								-- which don't indicate grammar tags
								if n >= 4 then
									-- Now append the tags
									table.insert(tags, param)
								end
							end
						end

						-- Add the new parameters after the existing ones
						existing_params[last_numbered_index] = existing_params[last_numbered_index] .. "|;|" .. table.concat(tags, "|")
						existing_defs[i] = "{{infl of|" .. table.concat(existing_params, "|") .. "}}"
						did_merge = true
						break
					end
				end
			end

			if not did_merge then
				table.insert(existing_defs, new_def)
			end
		end

		entry.def = table.concat(existing_defs, "\n# ")
	end

	-- Now combine tag sets inside a multiple-tag-set {{infl of}} call
	for i, entry in ipairs(entries_new) do
		local infl_of_params = entry.def:match("^{{infl of|([^{}]+)}}$")
		if not infl_of_params then
			infl_of_params = entry.def:match("^{{inflection of|([^{}]+)}}$")
		end
		if infl_of_params then
			infl_of_params = rsplit(infl_of_params, "|", true)

			-- Find the last unnamed parameter
			local last_numbered_index

			for j, param in ipairs(infl_of_params) do
				if not param:find("=", nil, true) then
					last_numbered_index = j
				end
			end

			-- Split the params in three:
			-- (1) Params before the inflection tags, and any named params mixed in with the tags
			-- (2) The tags themselves
			-- (3) Named params after the tags
			local pre_tag_params = {}
			local tags = {}
			local post_tag_params = {}
			local n = 0

			for j, param in ipairs(infl_of_params) do
				if not param:find("=", nil, true) then
					n = n + 1

					-- Skip the first three unnamed parameters, which don't indicate grammar tags
					if n >= 4 then
						table.insert(tags, param)
					else
						table.insert(pre_tag_params, param)
					end
				elseif n >= last_numbered_index then
					table.insert(post_tag_params, param)
				else
					table.insert(pre_tag_params, param)
				end
				if not param:find("=", nil, true) then
					last_numbered_index = j
				end
			end

			-- Now combine tag sets.
			tags = export.combine_tag_sets_into_multipart(tags, entries_obj.lang)

			-- Put the template back together.
			local combined_params = m_table.append(pre_tag_params, tags, post_tag_params)
			entry.def = "{{infl of|" .. table.concat(combined_params, "|") .. "}}"
		end
	end

	entries_obj.entries = entries_new
end


local function merge_field(entries, field)
	local seen_fields = create_ordered_set()
	for _, entry in ipairs(entries) do
		local fieldval = entry[field]
		if fieldval then
			if type(fieldval) == "table" then
				-- already a table
			else
				fieldval = rsplit(fieldval, "\n")
			end
			for _, val in ipairs(fieldval) do
				if val ~= "" then -- skip newlines, including if there's a final newline when split
					add_item(seen_fields, val)
				end
			end
		end
	end
	return seen_fields.array
end


local function default_merge_pronunciation(entries_obj)
	local pronuncs = merge_field(entries_obj.entries, "pronunc")
	if #pronuncs > 0 then
		return table.concat(pronuncs, "\n")
	else
		return nil
	end
end


local function generate_merged_pronunciation(entries_obj)
	if entries_obj.lang_module and entries_obj.lang_module.generate_pronunciation then
		entries_obj.pronunciation = lang_module.generate_pronunciation(entries_obj)
	else
		entries_obj.pronunciation = default_merge_pronunciation(entries_obj)
	end
end


local function default_merge_etymology(entries_obj)
	local etyms = merge_field(entries_obj.entries, "etymology")
	if #etyms > 1 then
		-- Hack! If multiple etymology entries, put a * before each one so they don't run together.
		-- In such a case we may be better off using a custom merge function.
		for i, item in ipairs(etyms) do
			etyms[i] = "* " .. item
		end
	end
	if #etyms > 0 then
		return table.concat(etyms, "\n")
	else
		return nil
	end
end


local function generate_merged_etymology(entries_obj)
	if entries_obj.lang_module and entries_obj.lang_module.generate_etymology then
		entries_obj.etymology = lang_module.generate_etymology(entries_obj)
	else
		entries_obj.etymology = default_merge_etymology(entries_obj)
	end
end


local function entries_to_text(entries_obj)
	for i, entry in ipairs(entries_obj.entries) do
		if entry.override then
			entry = "\n" ..(entry.override or "")
		else
			entry =
				"\n\n" ..
				"===" .. entry.pos_header .. "===\n" ..
				entry.head .. "\n\n" ..
				"# " .. entry.def ..
				(entry.inflection and "\n\n====Inflection====\n" .. entry.inflection or "") ..
				(entry.declension and "\n\n====Declension====\n" .. entry.declension or "") ..
				(entry.conjugation and "\n\n====Conjugation====\n" .. entry.conjugation or "") ..
				(entry.altforms and "\n\n====Alternative forms====\n" .. entry.altforms or "") ..
				-- FIXME, if there are multiple entries, there should either be only one merged L3 Mutation or several
				-- L4 Mutation sections. Not yet implemented.
				(entry.mutation and "\n\n===Mutation===\n" .. entry.mutation or "")
		end
		entries_obj.entries[i] = entry
	end
	return "==" .. entries_obj.lang:getCanonicalName() .. "==" ..
		(entries_obj.etymology and "\n\n===Etymology===\n" .. entries_obj.etymology or "") ..
		(entries_obj.pronunciation and "\n\n===Pronunciation===\n" .. entries_obj.pronunciation or "") ..
		table.concat(entries_obj.entries)
end


local function split_and_zip_term_and_translit(encoded_term, encoded_translit)
	local terms = rsplit(encoded_term, split_term_regex)
	local translits = encoded_translit and rsplit(encoded_translit, split_term_regex) or {}
	if #translits > #terms then
		error(("Saw %s translits, which is > the %s terms seen: encoded_term=%s, encoded_translit=%s"):
			format(#translits, #terms, encoded_term, encoded_translit))
	end
	local result = {}
	for i, term in ipairs(terms) do
		local translit = translits[i]
		if translit == "" then
			translit = nil
		end
		table.insert(result, {term = term, translit = translit})
	end
	return result
end


local function paste_term_translit(termobj)
	if termobj.translit then
		return termobj.term .. "//" .. termobj.translit
	else
		return termobj.term
	end
end


function export.generate(frame)
	local fparams = {
		lang            = {required = true},
		origin_pagename = {required = true},
		target_pagename = {required = true},
		num             = {required = true, type = "number"},

		pos                    = {list = true, allow_holes = true},
		form                   = {list = true, allow_holes = true},
		gender                 = {list = true, allow_holes = true},
		transliteration        = {list = true, allow_holes = true},
		origin                 = {list = true, allow_holes = true},
		origin_transliteration = {list = true, allow_holes = true},
		-- I'm pretty sure this is actually required and must have args.num entries in it.
		target                 = {list = true, allow_holes = true},
	}

	local args = require("parameters").process(frame.args, fparams, nil, "accel", "generate")
	local lang = require("languages").getByCode(args.lang, "lang")

	-- Try to use a language-specific module, if one exists.
	local success, lang_module = pcall(require, "Module:accel/" .. args.lang)

	local entries = {}

	-- Generate each entry
	local seen_origins = create_ordered_set()
	local seen_targets = create_ordered_set()
	local params_list = {}
	for i = 1, args.num do
		local params = {
			lang = lang,
			origin_pagename = args.origin_pagename,
			target_pagename = args.target_pagename,

			pos = args.pos[i] or error("The argument \"pos\" is missing for entry " .. i),
			form = args.form[i] or error("The argument \"form\" is missing for entry " .. i),
			gender = args.gender[i],
			origin = args.origin[i] or error("The argument \"origin\" is missing for entry " .. i),
			origin_transliteration = args.origin_transliteration[i],
			target = args.target[i],
			transliteration = args.transliteration[i],
			num_entries = args.num,
		}

		params.form = params.form:gsub("&#124;", "|")
		params.targets = split_and_zip_term_and_translit(params.target, params.transliteration)
		params.origins = split_and_zip_term_and_translit(params.origin, params.origin_transliteration)

		for _, origin in ipairs(params.origins) do
			add_item(seen_origins, paste_term_translit(origin), origin)
		end

		for _, target in ipairs(params.targets) do
			add_item(seen_targets, paste_term_translit(target), target)
		end

		table.insert(params_list, params)
	end

	-- Generate entries.
	for _, params in ipairs(params_list) do
		-- Add overall stats to all params objects.
		params.seen_origins = seen_origins
		params.seen_targets = seen_targets

		-- Make a default entry.
		local entry = export.default_entry(params)

		if success then
			lang_module.generate(params, entry)
		end

		-- Add it to the list.
		table.insert(entries, entry)
	end

	local entries_obj = {
		entries = entries,
		lang = lang,
		lang_module = lang_module,
		seen_origins = seen_origins,
		seen_targets = seen_targets,
	}

	-- Merge entries if possible.
	merge_entries(entries_obj)

	-- Now generate merged pronunciation and etymology, either using a custom generation function or by merging the
	-- individually specified pronunciation and etymology lines.
	generate_merged_pronunciation(entries_obj)
	generate_merged_etymology(entries_obj)

	return entries_to_text(entries_obj)
end


function export.generate_JSON(frame)
	local success, entries = pcall(export.generate, frame)

	-- If success is false, entries is an error message.
	-- It appears we need to specify `messages` or nothing will be displayed.
	local ret = { [success and "entries" or "error"] = entries, messages = require("array")()}

	return require("JSON").toJSON(ret)
end


return export