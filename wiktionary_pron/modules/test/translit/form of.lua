local export = {}

export.force_cat = false -- for testing; set to true to display categories even on non-mainspace pages

local m_links = require("links")
local m_table = require("table")
local put_module = "Module:parse utilities"
local labels_module = "Module:labels"
export.form_of_pos_module = "Module:form of/pos"
export.form_of_functions_module = "Module:form of/functions"
export.form_of_cats_module = "Module:form of/cats"
export.form_of_lang_data_module_prefix = "Module:form of/lang-data/"
export.form_of_data_module = "Module:form of/data"
export.form_of_data2_module = "Module:form of/data2"

local ulen = mw.ustring.len
local rsubn = mw.ustring.gsub
local rmatch = mw.ustring.match
local rsplit = mw.text.split

export.TAG_TYPE = 1
export.GLOSSARY = 2
export.SHORTCUTS = 3
export.WIKIDATA = 4

export.APPENDIX = true
export.WIKIPEDIA = false
export.WIKTIONARY = 0

export.langs_with_lang_specific_tags = {
	["en"] = true,
	["got"] = true,
	["lt"] = true,
	["lv"] = true,
	["nl"] = true,
	["pi"] = true,
	["sw"] = true,
	["ttj"] = true,
}

--[=[

This module implements the underlying processing of {{form of}}, {{inflection of}} and specific variants such as
{{past participle of}} and {{alternative spelling of}}. Most of the logic in this file is to handle tags in
{{inflection of}}. Other related files:

* [[Module:form of/templates]] contains the majority of the logic that implements the templates themselves.
* [[Module:form of/data]] is a data-only file containing information on the more common inflection tags, listing the
  tags, their shortcuts, the category they belong to (tense-aspect, case, gender, voice-valence, etc.), the appropriate
  glossary link and the wikidata ID.
* [[Module:form of/data2]] is a data-only file containing information on the less common inflection tags, in the same
  format as [[Module:form of/data]].
* [[Module:form of/lang-data/LANGCODE]] is a data-only file containing information on the language-specific inflection
  tags for the language with code LANGCODE, in the same format as [[Module:form of/data]]. Language-specific tags
  override general tags.
* [[Module:form of/cats]] is a data-only file listing the language-specific categories that are added when the
  appropriate combinations of tags are seen for a given language.
* [[Module:form of/pos]] is a data-only file listing the recognized parts of speech and their abbreviations, used for
  categorization. FIXME: This should be unified with the parts of speech listed in [[Module:links]].
* [[Module:form of/functions]] contains functions for use with [[Module:form of/data]] and [[Module:form of/cats]].
  They are contained in this module because data-only modules can't contain code. The functions in this file are of two
  types:

  (1) Display handlers allow for customization of the display of multipart tags (see below). Currently there is only
      one such handler, for handling multipart person tags such as '1//2//3'.
  (2) Cat functions allow for more complex categorization logic, and are referred to by name in [[Module:form of/cats]].
	  Currently no such functions exist.

The following terminology is used in conjunction with {{inflection of}}:

* A TAG is a single grammatical item, as specified in a single numbered parameter of {{inflection of}}. Examples are
  'masculine', 'nominative', or 'first-person'. Tags may be abbreviated, e.g. 'm' for 'masculine', 'nom' for
  'nominative', or '1' for 'first-person'. Such abbreviations are called ALIASES, and some tags have multiple
  equivalent aliases (e.g. 'p' or 'pl' for 'plural'). The full, non-abbreviated form of a tag is called its CANONICAL
  FORM.
* The DISPLAY FORM of a tag is the way it's displayed to the user. Usually the displayed text of the tag is the same as
  its canonical form, and it normally functions as a link to a glossary entry explaining the tag. Usually the link is
  to an entry in [[Appendix:Glossary]], but sometimes the tag is linked to an individual dictionary entry or to a
  Wikipedia entry. Occasionally, the display text differs from the canonical form of the tag. An example is the tag
  'comparative case', which has the display text read as simply 'comparative'. Normally, tags referring to cases don't
  have the word "case" in them, but in this case the tag 'comparative' was already used as an alias for the tag
  'comparative degree', so the tag was named 'comparative case' to avoid clashing. A similar situation occurs with
  'adverbial case' vs. the grammar tag 'adverbial' (as in 'adverbial participle').
* A TAG SET is an ordered list of tags, which together express a single inflection, for example, '1|s|pres|ind', which
  can be expanded to canonical-form tags as 'first-person|singular|present|indicative'.
* A CONJOINED TAG SET is a tag set that consists of multiple individual tag sets separated by a semicolon, e.g.
  '1|s|pres|ind|;|2|s|imp', which specifies two tag sets, '1|s|pres|ind' as above and '2|s|imp' (in canonical form,
  'second-person|singular|imperative'). Multiple tag sets specified in a single call to {{inflection of}} are specified
  in this fashion. Conjoined tag sets can also occur in list-tag shortcuts.
* A MULTIPART TAG is a tag that embeds multiple tags within it, such as 'f//n' or 'nom//acc//voc'. These are used in
  the case of [[syncretism]], when the same form applies to multiple inflections. Examples are the Spanish present
  subjunctive, where the first-person and third-person singular have the same form (e.g. [[siga]] from [[seguir]] "to
  follow"), or Latin third-declension adjectives, where the dative and ablative plural of all genders have the same
  form (e.g. [[omnibus]] from [[omnis]] "all"). These would be expressed respectively as '1//3|s|pres|sub' and
  'dat//abl|m//f//n|p', where the use of the multipart tag compactly encodes the syncretism and avoids the need to
  individually list out all of the inflections. Multipart tags currently display as a list separated by a slash, e.g.
  ''dative/ablative'' or ''masculine/feminine/neuter'' where each individual word is linked appropriately. As a special
  case, multipart tags involving persons display specially; for example, the multipart tag ''1//2//3'' displays as
  ''first-, second- and third-person'', with the word "person" occurring only once.
* A TWO-LEVEL MULTIPART TAG is a special type of multipart tag that joins two or more tag sets instead of joining
  individual tags. The tags within the tag set are joined by a colon, e.g. '1:s//3:p', which is displayed as
  ''first-person singular and third-person plural'', e.g. for use with the form [[μέλλον]] of the verb [[μέλλω]]
  "to intend", which uses the tag set '1:s//3:p|impf|actv|indc|unaugmented' to express the syncretism between the first
  singular and third plural forms of the imperfect active indicative unaugmented conjugation. Two-level multipart tags
  should be used sparingly; if in doubt, list out the inflections separately. [FIXME: Make two-level multipart tags
  obsolete.]
* A SHORTCUT is a tag that expands to any type of tag described above, or to any type of tag set described above.
  Aliases are a particular type of shortcut whose expansion is a single non-multipart tag.
* A MULTIPART SHORTCUT is a shortcut that expands into a multipart tag, for example '123', which expands to the
  multipart tag '1//2//3'. Only the most common such combinations exist as shortcuts.
* A LIST SHORTCUT is a special type of shortcut that expands to a list of tags instead of a single tag. For example,
  the shortcut '1s' expands to '1|s' (first-person singular). Only the most common such combinations exist as shortcuts.
* A CONJOINED SHORTCUT is a special type of list shortcut that consists of a conjoined tag set (multiple logical tag
  sets). For example, the English language-specific shortcut 'ed-form' expands to 'spast|;|past|part', expressing the
  common syncretism between simple past and past participle in English (and in this case, 'spast' is itself a list
  shortcut that expands to 'simple|past').
]=]

-- version of rsubn() that discards all but the first return value
local function rsub(term, foo, bar)
	local retval = rsubn(term, foo, bar)
	return retval
end


local function normalize_index(list, index)
	if index < 0 then
		return #list + index + 1
	end
	return index
end

-- FIXME, consider moving to [[Module:table]]
-- Return true if the list `tags1`, treated as a set, is a subset of the list `tags2`, also treated as a set.
local function is_subset(tags1, tags2)
	tags1 = m_table.listToSet(tags1)
	tags2 = m_table.listToSet(tags2)
	for tag, _ in pairs(tags1) do
		if not tags2[tag] then
			return false
		end
	end
	return true
end


-- FIXME, move to [[Module:table]]
local function slice(list, i, j)
	--checkType("slice", 1, list, "table")
	--checkType("slice", 2, i, "number", true)
	--checkType("slice", 3, j, "number", true)
	if i == nil then
		i = 1
	else
		i = normalize_index(list, i)
	end
	j = normalize_index(list, j or -1)

	local retval = {}
	local k = 0
	for index = i, j do
		k = k + 1
		retval[k] = list[index]
	end
	return retval
end


-- Add tracking category for PAGE when called from {{inflection of}} or
-- similar TEMPLATE. The tracking category linked to is
-- [[Template:tracking/inflection of/PAGE]].
local function track(page)
	require("debug/track")("inflection of/" ..
		-- avoid including links in pages (may cause error)
		page:gsub("%[", "("):gsub("%]", ")"):gsub("|", "!"))
end


local function wrap_in_span(text, classes)
	return ("<span class='%s'>%s</span>"):format(classes, text)
end


--[=[
Lowest-level implementation of form-of templates, including the general {{form of}} as well as those that deal with
inflection tags, such as the general {{inflection of}}, semi-specific variants such as {{participle of}}, and specific
variants such as {{past participle of}}. `data` contains all the information controlling the display, with the
following fields:

`.text`: Text to insert before the lemmas. Wrapped in the value of `.text_classes`, or its default; see below.
`.lemmas`: List of objects describing the lemma(s) of which the term in question is a non-lemma form. These are passed
		   directly to full_link() in [[Module:links]]. Each object should have at minimum a `.lang` field containing
		   the language of the lemma and a `.term` field containing the lemma itself. Each object is formatted using
		   full_link() and then if there are more than one, they are joined using serialCommaJoin() in [[Module:table]].
		   Alternatively, `.lemmas` can be a string, which is displayed directly, or omitted, to show no lemma links and
		   omit the connecting text.
`.lemma_face`: "Face" to use when displaying the lemma objects. Usually should be set to "term".
`.enclitics`: List of enclitics to display after the lemmas, in parens.
`.base_lemmas`: List of base lemmas to display after the lemmas, in the case where the lemmas in `.lemmas` are
				themselves forms of another lemma (the base lemma), e.g. a comparative, superlative or participle. Each
				object is of the form { paramobj = PARAM_OBJ, lemmas = {LEMMA_OBJ, LEMMA_OBJ, ...} } where PARAM_OBJ
				describes the properties of the base lemma parameter (i.e. the relationship between the intermediate
				and base lemmas) and LEMMA_OBJ is an object suitable to be passed to full_link in [[Module:links]].
				PARAM_OBJ is of the format { param = "PARAM", tags = {"TAG", "TAG", ...} } where PARAM is the name of
				the parameter to {{inflection of}} etc. that holds the base lemma(s) of the specified relationship and
				the tags describe the relationship, such as {"comd"} or {"past", "part"}.
`.text_classes`: CSS classes used to wrap the tag text and lemma links. Default is "form-of-definition use-with-mention"
				 for the tag text and lemma links, and additionally "form-of-definition-link" specifically for the
				 lemma links. (FIXME: Should separate out the lemma links into their own field.)
`.posttext`: Additional text to display after the lemma links.
]=]
function export.format_form_of(data)
	if type(data) ~= "table" then
		error("Internal error: First argument must now be a table of arguments")
	end
	local text_classes = data.text_classes or "form-of-definition use-with-mention"
	local lemma_classes = data.text_classes or "form-of-definition-link"
	local parts = {}
	local function ins(text)
		table.insert(parts, text)
	end
	ins("<span class='" .. text_classes .. "'>")
	ins(data.text)
	if data.text ~= "" and data.lemmas then
		ins(" ")
	end
	if data.lemmas then
		if type(data.lemmas) == "string" then
			ins(wrap_in_span(data.lemmas, lemma_classes))
		else
			local formatted_terms = {}
			for _, lemma in ipairs(data.lemmas) do
				table.insert(formatted_terms, wrap_in_span(
					m_links.full_link(lemma, data.lemma_face), lemma_classes
				))
			end
			ins(m_table.serialCommaJoin(formatted_terms))
		end
	end
	if data.enclitics and #data.enclitics > 0 then
		-- The outer parens need to be outside of the text_classes span so they show in upright instead of italic, or
		-- they will clash with upright parens generated by link annotations such as transliterations and pos=.
		ins("</span>")
		local formatted_terms = {}
		for _, enclitic in ipairs(data.enclitics) do
			-- FIXME, should we have separate clitic face and/or classes?
			table.insert(formatted_terms, wrap_in_span(
				m_links.full_link(enclitic, data.lemma_face, nil, "show qualifiers"), lemma_classes
			))
		end
		ins(" (")
		ins(wrap_in_span("with enclitic" .. (#data.enclitics > 1 and "s" or "") .. " ", text_classes))
		ins(m_table.serialCommaJoin(formatted_terms))
		ins(")")
		ins("<span class='" .. text_classes .. "'>")
	end
	if data.base_lemmas and #data.base_lemmas > 0 then
		for _, base_lemma in ipairs(data.base_lemmas) do
			ins(", the </span>")
			ins(export.tagged_inflections {
				lang = base_lemma.lemmas[1].lang,
				tags = base_lemma.paramobj.tags,
				lemmas = base_lemma.lemmas,
				lemma_face = data.lemma_face,
				no_format_categories = true,
				nocat = true,
				text_classes = data.text_classes,
			})
			ins("<span class='" .. text_classes .. "'>")
		end
	end
	-- FIXME, should posttext go before enclitics? If so we need to have separate handling for the
	-- final colon when there are multiple tag sets in tagged_inflections().
	if data.posttext then
		ins(data.posttext)
	end
	ins("</span>")
	return table.concat(parts)
end


function export.is_link_or_html(tag)
	return tag:find("[[", nil, true) or tag:find("|", nil, true) or tag:find("<", nil, true)
end


-- Look up a tag (either a shortcut of any sort of a canonical long-form tag) and return its expansion. The expansion
-- will be a string unless the shortcut is a list-tag shortcut such as "1s"; in that case, the expansion will be a
-- list. The caller must handle both cases. Only one level of expansion happens; hence, "acc" expands to "accusative",
-- "1s" expands to {"1", "s"} (not to {"first", "singular"}) and "123" expands to "1//2//3". The expansion will be the
-- same as the passed-in tag in the following circumstances:
--
-- 1. The tag is ";" (this is special-cased, and no lookup is done).
-- 2. The tag is a multipart tag such as "nom//acc" (this is special-cased, and no lookup is done).
-- 3. The tag contains a raw link (this is special-cased, and no lookup is done).
-- 4. The tag contains HTML (this is special-cased, and no lookup is done).
-- 5. The tag is already a canonical long-form tag.
-- 6. The tag is unrecognized.
--
-- This function first looks up in the lang-specific data module [[Module:form of/lang-data/LANGCODE]], then in
-- [[Module:form of/data]] (which includes more common non-lang-specific tags) and finally (only if the tag is not
-- recognized as a shortcut or canonical tag, and is not of types 1-4 above) in [[Module:form of/data2]].
--
-- If the expansion is a string and is different from the tag, track it if DO_TRACK is true.
function export.lookup_shortcut(tag, lang, do_track)
	-- If there is HTML or a link in the tag, return it directly; don't try
	-- to look it up, which will fail.
	if tag == ";" or tag:find("//", nil, true) or export.is_link_or_html(tag) then
		return tag
	end
	local expansion
	local langcode = lang and lang:getCode()
	if langcode and export.langs_with_lang_specific_tags[langcode] then
		local langdata = mw.loadData(export.form_of_lang_data_module_prefix .. langcode)
		-- If this is a canonical long-form tag, just return it, and don't check for shortcuts. This is an
		-- optimization; see below.
		if langdata.tags[tag] then
			return tag
		end
		expansion = langdata.shortcuts[tag]
	end
	if not expansion then
		local m_data = mw.loadData(export.form_of_data_module)
		-- If this is a canonical long-form tag, just return it, and don't check for shortcuts (which will cause
		-- [[Module:form of/data2]] to be loaded, because there won't be a shortcut entry in [[Module:form of/data]] --
		-- or, for that matter, in [[Module:form of/data2]]). This is an optimization; the code will still work without
		-- it, but will use up more memory.
		if m_data.tags[tag] then
			return tag
		end
		expansion = m_data.shortcuts[tag]
	end
	if not expansion then
		local m_data2 = mw.loadData(export.form_of_data2_module)
		expansion = m_data2.shortcuts[tag]
	end
	if not expansion then
		return tag
	end
	-- Maybe track the expansion if it's not the same as the raw tag.
	if do_track and expansion ~= tag and type(expansion) == "string" then
		track("tag/" .. tag)
	end
	return expansion
end


-- Look up a normalized/canonicalized tag and return the data object associated with it. If the tag isn't found, return
-- nil. This first looks up in the lang-specific data module [[Module:form of/lang-data/LANGCODE]], then in
-- [[Module:form of/data]] (which includes more common non-lang-specific tags) and then finally in
-- [[Module:form of/data2]].
function export.lookup_tag(tag, lang)
	local langcode = lang and lang:getCode()
	if langcode and export.langs_with_lang_specific_tags[langcode] then
		local langdata = mw.loadData(export.form_of_lang_data_module_prefix .. langcode)
		if langdata.tags[tag] then
			return langdata.tags[tag]
		end
	end
	local m_data = mw.loadData(export.form_of_data_module)
	local tagobj = m_data.tags[tag]
	if tagobj then
		return tagobj
	end
	local m_data2 = mw.loadData(export.form_of_data2_module)
	local tagobj2 = m_data2.tags[tag]
	if tagobj2 then
		return tagobj2
	end
	return nil
end


-- Normalize a single tag, which may be a shortcut but should not be a multipart tag, a multipart shortcut or a list
-- shortcut.
local function normalize_single_tag(tag, lang, do_track)
	local expansion = export.lookup_shortcut(tag, lang, do_track)
	if type(expansion) ~= "string" then
		error("Tag '" .. tag .. "' is a list shortcut, which is not allowed here")
	end
	tag = expansion
	if not export.lookup_tag(tag, lang) and do_track then
		-- If after all expansions and normalizations we don't recognize the canonical tag, track it.
		track("unknown")
		track("unknown/" .. tag)
	end
	return tag
end


--[=[
Normalize a component of a multipart tag. This should not have any // in it, but may join multiple individual tags with
a colon, and may be a single list-tag shortcut, which is treated as if colon-separated. The return value may be a list
of tags.
]=]
local function normalize_multipart_component(tag, lang, do_track)
	-- If there is HTML or a link in the tag, don't try to split on colon. A colon may legitimately occur in either one,
	-- and we don't want these things parsed. Note that we don't do this check before splitting on //, which we don't
	-- expect to occur in links or HTML; see comment in normalize_tag().
	if export.is_link_or_html(tag) then
		return tag
	end
	local components = rsplit(tag, ":", true)
	if #components == 1 then
		-- We allow list-tag shortcuts inside of multipart tags, e.g.
		-- '1s//3p'. Check for this now.
		tag = export.lookup_shortcut(tag, lang, do_track)
		if type(tag) == "table" then
			-- Temporary tracking as we will disallow this.
			track("list-tag-inside-of-multipart")
			-- We found a list-tag shortcut; treat as if colon-separated.
			components = tag
		else
			return normalize_single_tag(tag, lang, do_track)
		end
	end
	local normtags = {}
	-- Temporary tracking as we will disallow this.
	track("two-level-multipart")
	for _, component in ipairs(components) do
		if do_track then
			-- There are multiple components; track each of the individual
			-- raw tags.
			track("tag/" .. component)
		end
		table.insert(normtags, normalize_single_tag(component, lang, do_track))
	end

	return normtags
end


--[=[
Normalize a single tag. The return value may be a list (in the case of multipart tags), which will contain nested lists
in the case of two-level multipart tags.
]=]
local function normalize_tag(tag, lang, do_track)
	-- We don't check for links or HTML before splitting on //, which we don't expect to occur in links or HTML. Doing
	-- it this way allows for a tag like '{{lb|grc|Epic}}//{{lb|grc|Ionic}}' to function correctly (the template calls
	-- will be expanded before we process the tag, and will contain links and HTML). The only check we do is for a URL,
	-- which shouldn't normally occur, but might if the user tries to put an external link into the tag. URL's with //
	-- normally have the sequence ://, which should never normally occur when // and : are used in their normal ways.
	if tag:find("://", nil, true) then
		return tag
	end
	local split_tags = rsplit(tag, "//", true)
	if #split_tags == 1 then
		local retval = normalize_multipart_component(tag, lang, do_track)
		if type(retval) == "table" then
			-- The user gave a tag like '1:s', i.e. with colon but without //. Allow this, but we need to return a
			-- nested list.
			return {retval}
		end
		return retval
	end
	local normtags = {}
	for _, single_tag in ipairs(split_tags) do
		if do_track then
			-- If the tag was a multipart tag, track each of individual raw tags.
			track("tag/" .. single_tag)
		end
		table.insert(normtags, normalize_multipart_component(single_tag, lang, do_track))
	end
	return normtags
end


--[=[
Normalize a tag set (a list of tags) into its canonical-form tags. The return value is a list of normalized tag sets
(a list because of there may be conjoined shortcuts among the input tags). A normalized tag set is a list of tag
elements, where each element is either a string (the canonical form of a tag), a list of such strings (in the case of
multipart tags) or a list of lists of such strings (in the case of two-level multipart tags). For example, the multipart
tag "nom//acc//voc" will be represented in canonical form as {"nominative", "accusative", "vocative"}, and the
two-level multipart tag "1:s//3:p" will be represented as {{"first-person", "singular"}, {"third-person", "plural"}}.

Example 1:

normalize_tag_set({"nom//acc//voc", "n", "p"}) = {{{"nominative", "accusative", "vocative"}, "masculine", "plural"}}

Example 2:

normalize_tag_set({"ed-form"}, ENGLISH) = {{"simple", "past"}, {"past", "participle"}}

Example 3:

normalize_tag_set({"archaic", "ed-form"}, ENGLISH) = {{"archaic", "simple", "past"}, {"archaic", "past", "participle"}}
]=]
function export.normalize_tag_set(tag_set, lang, do_track)
	-- We track usage of shortcuts, normalized forms and (in the case of multipart tags or list tags) intermediate
	-- forms. For example, if the tags 1s|mn|gen|indefinite are passed in, we track the following:
	-- [[Template:tracking/inflection of/tag/1s]]
	-- [[Template:tracking/inflection of/tag/1]]
	-- [[Template:tracking/inflection of/tag/s]]
	-- [[Template:tracking/inflection of/tag/first-person]]
	-- [[Template:tracking/inflection of/tag/singular]]
	-- [[Template:tracking/inflection of/tag/mn]]
	-- [[Template:tracking/inflection of/tag/m//n]]
	-- [[Template:tracking/inflection of/tag/m]]
	-- [[Template:tracking/inflection of/tag/n]]
	-- [[Template:tracking/inflection of/tag/masculine]]
	-- [[Template:tracking/inflection of/tag/neuter]]
	-- [[Template:tracking/inflection of/tag/gen]]
	-- [[Template:tracking/inflection of/tag/genitive]]
	-- [[Template:tracking/inflection of/tag/indefinite]]
	local output_tag_set = {}
	local saw_semicolon = false

	for _, tag in ipairs(tag_set) do
		if do_track then
			-- Track the raw tag.
			track("tag/" .. tag)
		end
		-- Expand the tag, which may generate a new tag (either a fully canonicalized tag, a multipart tag, or a list
		-- of tags).
		tag = export.lookup_shortcut(tag, lang, do_track)
		if type(tag) == "table" then
			saw_semicolon = m_table.contains(tag, ";")
			if saw_semicolon then
				-- If we saw a conjoined shortcut, we need to use a more general algorithm that can expand a single
				-- tag set into multiple.
				break
			end

			for _, t in ipairs(tag) do
				if do_track then
					-- If the tag expands to a list of raw tags, track each of those.
					track("tag/" .. t)
				end
				table.insert(output_tag_set, normalize_tag(t, lang, do_track))
			end
		else
			table.insert(output_tag_set, normalize_tag(tag, lang, do_track))
		end
	end

	if not saw_semicolon then
		return {output_tag_set}
	end

	-- Use a more general algorithm that handles conjoined shortcuts.
	local output_tag_set = {}
	for i, tag in ipairs(tag_set) do
		if do_track then
			-- Track the raw tag.
			track("tag/" .. tag)
		end
		-- Expand the tag, which may generate a new tag (either a fully canonicalized tag, a multipart tag, or a list
		-- of tags).
		tag = export.lookup_shortcut(tag, lang, do_track)
		if type(tag) == "table" then
			local output_tag_sets = {}
			local shortcut_tag_sets = export.split_tag_set(tag)
			local normalized_shortcut_tag_sets = {}
			for _, shortcut_tag_set in ipairs(shortcut_tag_sets) do
				m_table.extendList(normalized_shortcut_tag_sets,
					export.normalize_tag_set(shortcut_tag_set, lang, do_track))
			end
			local after_tags = slice(tag_set, i + 1)
			local normalized_after_tags_sets = export.normalize_tag_set(after_tags, lang, do_track)
			for _, normalized_shortcut_tag_set in ipairs(normalized_shortcut_tag_sets) do
				for _, normalized_after_tags_set in ipairs(normalized_after_tags_sets) do
					table.insert(output_tag_sets, m_table.append(output_tag_set, normalized_shortcut_tag_set,
						normalized_after_tags_set))
				end
			end
			return output_tag_sets
		else
			table.insert(output_tag_set, normalize_tag(tag, lang, do_track))
		end
	end

	error("Internal error: Should not get here")
end


function export.combine_multipart_tags(tag_set)
	for i, tag in ipairs(tag_set) do
		if type(tag) == "table" then
			for j, subtag in ipairs(tag) do
				if type(subtag) == "table" then
					tag[j] = table.concat(subtag, ":")
				end
			end
			tag_set[i] = table.concat(tag, "//")
		end
	end

	return tag_set
end


function export.normalize_tags(tags, lang, recombine_multitags, do_track)
	local tag_sets = export.normalize_tag_set(tags, lang, do_track)
	if recombine_multitags then
		for i, tag_set in ipairs(tag_sets) do
			tag_sets[i] = export.combine_multipart_tags(tag_set)
		end
		return export.combine_tag_sets(tag_sets)
	end
	return tag_sets
end


-- Split a tag set containing two-level multipart tags into one or more tag sets not containing such tags.
-- Single-level multipart tags are left alone. (If we need to, a slight modification of the following code
-- will also split single-level multipart tags.) This assumes that multipart tags are represented as lists
-- and two-level multipart tags are represented as lists of lists, as is output by normalize_tag_set().
-- NOTE: We have to be careful to properly handle imbalanced two-level multipart tags such as
-- <code>def:s//p</code> (or the reverse, <code>s//def:p</code>).
function export.split_two_level_multipart_tag_set(tag_set)
	for i, tag in ipairs(tag_set) do
		if type(tag) == "table" then
			-- We saw a multipart tag. Check if any of the parts are two-level.
			local saw_two_level_tag = false
			for _, first_level_tag in ipairs(tag) do
				if type(first_level_tag) == "table" then
					saw_two_level_tag = true
					break
				end
			end
			if saw_two_level_tag then
				-- We found a two-level multipart tag.
				-- (1) Extract the preceding tags.
				local pre_tags = slice(tag_set, 1, i - 1)
				-- (2) Extract the following tags.
				local post_tags = slice(tag_set, i + 1)
				-- (3) Loop over each tag set alternant in the two-level multipart tag.
				-- For each alternant, form the tag set consisting of pre_tags + alternant + post_tags,
				-- and recursively split that tag set.
				local resulting_tag_sets = {}
				for _, first_level_tag_set in ipairs(tag) do
					local expanded_tag_set = {}
					m_table.extendList(expanded_tag_set, pre_tags)
					-- The second level may have a string or a list.
					if type(first_level_tag_set) == "table" then
						m_table.extendList(expanded_tag_set, first_level_tag_set)
					else
						table.insert(expanded_tag_set, first_level_tag_set)
					end
					m_table.extendList(expanded_tag_set, post_tags)
					m_table.extendList(resulting_tag_sets, export.split_two_level_multipart_tag_set(expanded_tag_set))
				end
				return resulting_tag_sets
			end
		end
	end

	return {tag_set}
end


-- Split a tag set that may consist of multiple semicolon-separated tag sets into the component tag sets.
function export.split_tag_set(tag_set)
	local split_tag_sets = {}
	local cur_tag_set = {}
	for _, tag in ipairs(tag_set) do
		if tag == ";" then
			if #cur_tag_set > 0 then
				table.insert(split_tag_sets, cur_tag_set)
			end
			cur_tag_set = {}
		else
			table.insert(cur_tag_set, tag)
		end
	end
	if #cur_tag_set > 0 then
		table.insert(split_tag_sets, cur_tag_set)
	end
	return split_tag_sets
end

export.split_tags_into_tag_sets = export.split_tag_set


--[=[
-- Combine multiple tag sets in a tag set group into a simple tag set, with logical tag sets separated by semicolons.
-- This is the opposite of split_tag_set().
]=]
function export.combine_tag_sets(tag_sets)
	if #tag_sets == 1 then
		return tag_sets[1]
	end
	local combined_tag_set = {}
	for _, tag_set in ipairs(tag_sets) do
		if #combined_tag_set > 0 then
			table.insert(combined_tag_set, ";")
		end
		m_table.extendList(combined_tag_set, tag_set)
	end
	return tags
end


local tag_set_param_mods = {
	lb = {
		item_dest = "labels",
		convert = function(arg, parse_err)
			return rsplit(arg, "//")
		end,
	}
}


-- Parse tag set properties from a tag set (list of tags). Currently no per-tag properties are recognized, and the only
-- per-tag-set property recognized is <lb:...> for specifing label(s) for the tag set. Per-tag-set properties must be
-- attached to the last tag.
function export.parse_tag_set_properties(tag_set)
	local function generate_tag_set_obj(last_tag)
		tag_set[#tag_set] = last_tag
		return {tags = tag_set}
	end
	local last_tag = tag_set[#tag_set]
	-- Check for inline modifier, e.g. מרים<tr:Miryem>. But exclude HTML entry with <span ...>, <i ...>, <br/> or
	-- similar in it, caused by wrapping an argument in {{l|...}}, {{af|...}} or similar. Basically, all tags of
	-- the sort we parse here should consist of a less-than sign, plus letters, plus a colon, e.g. <lb:...>, so if
	-- we see a tag on the outer level that isn't in this format, we don't try to parse it. The restriction to the
	-- outer level is to allow generated HTML inside of e.g. qualifier tags, such as foo<q:similar to {{m|fr|bar}}>.
	if last_tag:find("<") and not last_tag:find("^[^<]*<[a-z]*[^a-z:]") then
		return require(put_module).parse_inline_modifiers(last_tag, {
			param_mods = tag_set_param_mods,
			generate_obj = generate_tag_set_obj,
		})
	else
		return generate_tag_set_obj(last_tag)
	end
end


function export.normalize_pos(pos)
	if not pos then
		return nil
	end
	return mw.loadData(export.form_of_pos_module)[pos] or pos
end


-- Return the display form of a single canonical-form tag. The value
-- passed in must be a string (i.e. it cannot be a list describing a
-- multipart tag). To handle multipart tags, use get_tag_display_form().
local function get_single_tag_display_form(normtag, lang)
	local data = export.lookup_tag(normtag, lang)
	local display = normtag

	-- If the tag has a special display form, use it
	if data and data.display then
		display = data.display
	end

	-- If there is a nonempty glossary index, then show a link to it
	local glossary = data and data[export.GLOSSARY]
	if glossary then
		if glossary == export.WIKTIONARY then
			display = "[[" .. normtag .. "|" .. display .. "]]"
		elseif glossary == export.WIKIPEDIA then
			display = "[[w:" .. normtag .. "|" .. display .. "]]"
		elseif glossary == export.APPENDIX then
			display = "[[Appendix:Glossary#" .. mw.uri.anchorEncode(normtag) .. "|" .. display .. "]]"
		elseif type(glossary) ~= "string" then
			error(("Internal error: Wrong type %s for glossary value %s for tag %s"):format(
				type(glossary), mw.dumpObject(glossary), normtag))
		else
			local link = rmatch(glossary, "^wikt:(.*)")
			if link then
				display = "[[" .. link .. "|" .. display .. "]]"
			end
			if not link then
				link = rmatch(glossary, "^w:(.*)")
				if link then
					display = "[[w:" .. link .. "|" .. display .. "]]"
				end
			end
			if not link then
				display = "[[Appendix:Glossary#" .. mw.uri.anchorEncode(glossary) .. "|" .. display .. "]]"
			end
		end
	end
	return display
end


--[=[
Turn a canonicalized tag spec (which describes a single, possibly multipart tag) into the displayed form. The tag spec
may be a string (a canonical-form tag); a list of canonical-form tags (in the case of a simple multipart tag); or a
list of mixed canonical-form tags and lists of such tags (in the case of a two-level multipart tag). `joiner` indicates
how to join the parts of a multipart tag, and can be either "and" ("foo and bar", or "foo, bar and -- baz" for 3 or
more), "slash" ("foo/bar"), "en-dash" ("foo–bar") or nil, which uses the global default found in
multipart_join_strategy() in [[Module:form of/functions]]. (NOTE: The global default is "slash" and this seems unlikely
to change.)
]=]
function export.get_tag_display_form(tagspec, lang, joiner)
	if type(tagspec) == "string" then
		return get_single_tag_display_form(tagspec, lang)
	end
	-- We have a multipart tag. See if there's a display handler to display them specially.
	for _, handler in ipairs(require(export.form_of_functions_module).display_handlers) do
		local displayval = handler(tagspec, joiner)
		if displayval then
			return displayval
		end
	end
	-- No display handler.
	local displayed_tags = {}
	for _, first_level_tag in ipairs(tagspec) do
		if type(first_level_tag) == "string" then
			table.insert(displayed_tags, get_single_tag_display_form(first_level_tag, lang))
		else
			-- A first-level element of a two-level multipart tag. Currently we just separate the individual components
			-- with spaces, but other ways are possible, e.g. using an underscore, colon, parens or braces.
			local components = {}
			for _, component in ipairs(first_level_tag) do
				table.insert(components, get_single_tag_display_form(component, lang))
			end
			table.insert(displayed_tags, table.concat(components, " "))
		end
	end
	return require(export.form_of_functions_module).join_multiparts(displayed_tags, joiner)
end


--[=[
Given a normalized tag set (i.e. as output by normalize_tag_set(); all tags are in canonical form, multipart tags are
represented as lists, and two-level multipart tags as lists of lists), convert to displayed form (a string). See
get_tag_display_form() for the meaning of `joiner`.
]=]
function export.get_tag_set_display_form(normalized_tag_set, lang, joiner)
	local parts = {}

	for _, tagspec in ipairs(normalized_tag_set) do
		local to_insert = export.get_tag_display_form(tagspec, lang, joiner)
		-- Maybe insert a space before inserting the display form of the tag. We insert a space if
		-- (a) we're not the first tag; and
		-- (b) the tag we're about to insert doesn't have the "no_space_on_left" property; and
		-- (c) the preceding tag doesn't have the "no_space_on_right" property.
		-- NOTE: We depend here on the fact that
		-- (1) all tags with either of the above properties set have the same display form as canonical form, and
		-- (2) all tags with either of the above properties set are single-character tags.
		-- The second property is an optimization to avoid looking up display forms resulting from multipart tags,
		-- which won't be found and which will trigger loading of [[Module:form of/data2]]. If multichar punctuation is
		-- added in the future, it's ok to change the == 1 below to <= 2 or <= 3.
		--
		-- If the first property above fails to hold in the future, we need to track the canonical form of each tag
		-- (including the previous one) as well as the display form. This would also avoid the need for the == 1 check.
		if #parts > 0 then
			local most_recent_tagobj = ulen(parts[#parts]) == 1 and export.lookup_tag(parts[#parts], lang)
			local to_insert_tagobj = ulen(to_insert) == 1 and export.lookup_tag(to_insert, lang)
			if (
				(not most_recent_tagobj or not most_recent_tagobj.no_space_on_right) and
				(not to_insert_tagobj or not to_insert_tagobj.no_space_on_left)
			) then
				table.insert(parts, " ")
			end
		end
		table.insert(parts, to_insert)
	end

	return table.concat(parts)
end


--[=[
Given a normalized tag set (i.e. as output by normalize_tag_set(); all tags are in canonical form, multipart tags are
represented as lists, and two-level multipart tags as lists of lists), fetch the associated categories and labels.
Return two values, a list of categories and a list of labels. `lang` is the language of term represented by the tag set,
and `POS` is the user-provided part of speech (which may be nil).
]=]
function export.fetch_categories_and_labels(normalized_tag_set, lang, POS, pagename, lemmas)
	local m_cats = mw.loadData(export.form_of_cats_module)
	local categories = {}
	local labels = {}

	POS = export.normalize_pos(POS)
	-- First split any two-level multipart tags into multiple sets, to make our life easier.
	for _, tag_set in ipairs(export.split_two_level_multipart_tag_set(normalized_tag_set)) do
		-- Call a named function, either from the lang-specific data in [[Module:form of/lang-specific/LANGCODE]] or
		-- in [[Module:form of/cats]].
		local function call_named_function(name, funtype)
			local data = {
				pagename = pagename or mw.title.getCurrentTitle().subpageText,
				lemmas = lemmas,
				tag_set = normalized_tag_set,
				lang = lang,
				POS = POS
			}
			-- First try lang-specific.
			local langcode = lang and lang:getCode()
			local lang_specific_module
			if langcode and export.langs_with_lang_specific_tags[langcode] then
				lang_specific_module = export.form_of_lang_data_module_prefix .. langcode .. "/functions"
				local langdata = require(lang_specific_module)
				if langdata.cat_functions then
					local fn = langdata.cat_functions[name]
					if fn then
						return fn(data)
					end
				end
			end
			local fn = require(export.form_of_functions_module).cat_functions[name]
			if fn then
				return fn(data)
			end
			local lang_specific_part
			if lang_specific_module then
				lang_specific_part = ("[[%s]] or "):format(lang_specific_module)
			else
				lang_specific_part = ""
			end
			error(("No %s function named '%s' in %s[[%s]]"):format(funtype, name, lang_specific_part,
				export.form_of_functions_module))
		end

		-- Given a tag from the current tag set (which may be a list in case of a multipart tag),
		-- and a tag from a categorization spec, check that the two match.
		-- (1) If both are strings, we just check for equality.
		-- (2) If the spec tag is a string and the tag set tag is a list (i.e. it originates from a
		-- multipart tag), we check that the spec tag is in the list. This is because we want to treat
		-- multipart tags in user-specified tag sets as if the user had specified multiple tag sets.
		-- For example, if the user said "1//3|s|pres|ind" and the categorization spec says {"has", "1"},
		-- we want this to match, because "1//3|s|pres|ind" should be treated equivalently to two tag
		-- sets "1|s|pres|ind" and "3|s|pres|ind", and the former matches the categorization spec.
		-- (3) If the spec tag is a list (i.e. it originates from a multipart tag), we check that the
		-- tag set tag is also a list and is a superset of the spec tag. For example, if the categorization
		-- spec says {"has", "1//3"}, then the tag set tag must be a multipart tag that has both "1" and "3"
		-- in it. "1//3" works, as does "1//2//3".
		local function tag_set_tag_matches_spec_tag(tag_set_tag, spec_tag)
			if type(spec_tag) == "table" then
				if type(tag_set_tag) == "table" and is_subset(spec_tag, tag_set_tag) then
					return true
				end
			elseif type(tag_set_tag) == "table" then
				if m_table.contains(tag_set_tag, spec_tag) then
					return true
				end
			elseif tag_set_tag == spec_tag then
				return true
			end
			return false
		end

		-- Check that the current tag set matches the given spec tag. This means that any of the tags
		-- in the current tag set match, according to tag_set_tag_matches_spec_tag(); see above. If the
		-- current tag set contains only string tags (i.e. no multipart tags), and the spec tag is a
		-- string (i.e. not a multipart tag), this boils down to list containment, but it gets more
		-- complex when multipart tags are present.
		local function tag_set_matches_spec_tag(spec_tag)
			spec_tag = normalize_tag(spec_tag, lang)
			for _, tag_set_tag in ipairs(tag_set) do
				if tag_set_tag_matches_spec_tag(tag_set_tag, spec_tag) then
					return true
				end
			end
			return false
		end

		-- Check whether the given spec matches the current tag set. Two values are returned:
		-- (1) whether the spec matches the tag set; (2) the index of the category to add if
		-- the spec matches.
		local function check_condition(spec)
			if type(spec) == "boolean" then
				return spec
			elseif type(spec) ~= "table" then
				error("Wrong type of condition " .. spec .. ": " .. type(spec))
			end
			local predicate = spec[1]
			if predicate == "has" then
				return tag_set_matches_spec_tag(spec[2]), 3
			elseif predicate == "hasall" then
				for _, tag in ipairs(spec[2]) do
					if not tag_set_matches_spec_tag(tag) then
						return false, 3
					end
				end
				return true, 3
			elseif predicate == "hasany" then
				for _, tag in ipairs(spec[2]) do
					if tag_set_matches_spec_tag(tag) then
						return true, 3
					end
				end
				return false, 3
			elseif predicate == "tags=" then
				local normalized_spec_tag_sets = export.normalize_tag_set(spec[2], lang)
				if #normalized_spec_tag_sets > 1 then
					error("Internal error: No support for conjoined shortcuts in category/label specs in "
						.. "[[Module:form of/cats]] when processing spec tag set " .. table.concat(spec[2], "|"))
				end
				local normalized_spec_tag_set = normalized_spec_tag_sets[1]
				-- Check for and disallow two-level multipart tags in the specs. FIXME: Remove this when we remove
				-- support for two-level multipart tags.
				for _, tag in ipairs(normalized_spec_tag_set) do
					if type(tag) == "table" then
						for _, subtag in ipairs(tag) do
							if type(subtag) == "table" then
								error("Internal error: No support for two-level multipart tags in category/label specs"
									.. "[[Module:form of/cats]] when processing spec tag set "
									.. table.concat(spec[2], "|"))
							end
						end
					end
				end
				-- Allow tags to be in different orders, and multipart tags to be in different orders. To handle this,
				-- we first check that both tag set tags and spec tags have the same length. If so, we sort the
				-- multipart tags in the tag set tags and spec tags, and then check that all tags in the spec tags are
				-- in the tag set tags.
				if #tag_set ~= #normalized_spec_tag_set then
					return false, 3
				end
				local tag_set_tags = m_table.deepcopy(tag_set)
				for i=1,#tag_set_tags do
					if type(tag_set_tags[i]) == "table" then
						table.sort(tag_set_tags[i])
					end
					if type(normalized_spec_tag_set[i]) == "table" then
						table.sort(normalized_spec_tag_set[i])
					end
				end
				for i=1,#tag_set_tags do
					if not m_table.contains(tag_set_tags, normalized_spec_tag_set[i]) then
						return false, 3
					end
				end
				return true, 3
			elseif predicate == "p=" then
				return POS == export.normalize_pos(spec[2]), 3
			elseif predicate == "pany" then
				for _, specpos in ipairs(spec[2]) do
					if POS == export.normalize_pos(specpos) then
						return true, 3
					end
				end
				return false, 3
			elseif predicate == "pexists" then
				return POS ~= nil, 2
			elseif predicate == "not" then
				local condval = check_condition(spec[2])
				return not condval, 3
			elseif predicate == "and" then
				local condval = check_condition(spec[2])
				if condval then
					condval = check_condition(spec[3])
				end
				return condval, 4
			elseif predicate == "or" then
				local condval = check_condition(spec[2])
				if not condval then
					condval = check_condition(spec[3])
				end
				return condval, 4
			elseif predicate == "call" then
				return fn(call_named_function(spec[2], "condition")), 3
			else
				error("Unrecognized predicate: " .. predicate)
			end
		end

		-- Process a given spec. This checks any conditions in the spec against the
		-- tag set, and insert any resulting categories into `categories`. Return value
		-- is true if the outermost condition evaluated to true and a category was inserted
		-- (this is used in {"cond" ...} conditions, which stop when a subcondition evaluates
		-- to true).
		local function process_spec(spec)
			if not spec then
				return false
			elseif type(spec) == "string" then
				-- A category. Substitute POS request with user-specified part of speech or default.
				spec = rsub(spec, "<<p=(.-)>>", function(default)
					return POS or export.normalize_pos(default)
				end)
				table.insert(categories, lang:getCanonicalName() .. " " .. spec)
				return true
			elseif type(spec) == "table" and spec.labels then
				-- A label spec.
				for _, label in ipairs(spec.labels) do
					m_table.insertIfNot(labels, label)
				end
				return true
			elseif type(spec) ~= "table" then
				error("Wrong type of specification " .. spec .. ": " .. type(spec))
			end
			local predicate = spec[1]
			if predicate == "multi" then
				-- WARNING! #spec doesn't work for objects loaded from loadData()
				for i, sp in ipairs(spec) do
					if i > 1 then
						process_spec(sp)
					end
				end
				return true
			elseif predicate == "cond" then
				-- WARNING! #spec doesn't work for objects loaded from loadData()
				for i, sp in ipairs(spec) do
					if i > 1 and process_spec(sp) then
						return true
					end
				end
				return false
			elseif predicate == "call" then
				return process_spec(call_named_function(spec[2], "spec"))
			else
				local condval, ifspec = check_condition(spec)
				if condval then
					process_spec(spec[ifspec])
					return true
				else
					process_spec(spec[ifspec + 1])
					-- FIXME: Are we sure this is correct?
					return false
				end
			end
		end

		local langspecs = m_cats[lang:getCode()]
		if langspecs then
			for _, spec in ipairs(langspecs) do
				process_spec(spec)
			end
		end
		if lang:getCode() ~= "und" then
			local langspecs = m_cats["und"]
			if langspecs then
				for _, spec in ipairs(langspecs) do
					process_spec(spec)
				end
			end
		end
	end

	return categories, labels
end


--[=[
Implementation of templates that display inflection tags, such as the general {{inflection of}}, semi-specific variants
such as {{participle of}}, and specific variants such as {{past participle of}}. `data` contains all the information
controlling the display, with the following fields:

`.lang`: (REQUIRED) Language to use when looking up language-specific inflection tags, categories and labels, and for
		 displaying categories and labels.
`.tags`: (REQUIRED UNLESS `.tag_sets` IS GIVEN) List of non-canonicalized inflection tags. Multiple tag sets can be
		 indicated by a ";" as one of the tags, and tag-set properties may be attached to the last tag of a tag set.
		 The tags themselves may come directly from the user (as in {{inflection of}}); come partly from the user (as
		 in {{participle of}}, which adds the tag 'part' to user-specified inflection tags); or be entirely specified
		 by the template (as in {{past participle of}}).
`.tag_sets`: (REQUIRED UNLESS `.tags` IS GIVEN) List of non-canonicalized tag sets and associated per-tag-set
			 properties. Each element of the list is an object of the form {tags = {"TAG", "TAG", ...}, labels =
			 {"LABEL", "LABEL", ...}}. If `.tag_sets` is specified, `.tags` should not be given and vice-versa.
			 Specifying `.tag_sets` in place of tags allowed per-tag set labels to be specified; otherwise, there is no
			 advantage. [[Module:pt-gl-inflections]] uses this functionality to supply labels like "Brazil" and
			 "Portugal" associated with specific tag sets.
`.lemmas`: (RECOMMENDED) List of objects describing the lemma(s) of which the term in question is a non-lemma form.
		   These are passed directly to full_link() in [[Module:links]]. Each object should have at minimum a `.lang`
		   field containing the language of the lemma and a `.term` field containing the lemma itself. Each object is
		   formatted using full_link() and then if there are more than one, they are joined using serialCommaJoin() in
		   [[Module:table]]. Alternatively, `.lemmas` can be a string, which is displayed directly. If omitted entirely,
		   no lemma links are shown and the connecting "of" is also omitted.
`.lemma_face`: (RECOMMENDED) "Face" to use when displaying the lemma objects. Usually should be set to "term".
`.POS`: (RECOMMENDED) Categorizing part-of-speech tag. Comes from the p= or POS= argument of {{inflection of}}.
`.pagename`: Page name of "current" page or nil to use the actual page title; for testing purposes.
`.enclitics`: List of enclitics to display after the lemmas, in parens.
`.no_format_categories`: If true, don't format the categories derived from the inflection tags; just return them.
`.sort`: Sort key for formatted categories. Ignored when .no_format_categories = true.
`.nocat`: Suppress computation of categories (even if `.no_format_categories` is not given).
`.notext`: Disable display of all tag text and "inflection of" text. (FIXME: Maybe not implemented correctly.)
`.capfirst`: Capitalize the first word displayed.
`.pretext`: Additional text to display before the inflection tags, but after any top-level labels.
`.posttext`: Additional text to display after the lemma links.
`.text_classes`: CSS classes used to wrap the tag text and lemma links. Default is "form-of-definition use-with-mention"
				 for the tag text, "form-of-definition-link" for the lemma links. (FIXME: Should separate out the
				 lemma links into their own field.)
`.joiner`: Override the joiner (normally a slash) used to join multipart tags. You should normally not specify this.

A typical call might look like this (for Spanish [[amo]]):
	local lang = require("languages").getByCode("es")

	local lemma_obj = {
		lang = lang,
		term = "amar",
	}

	return m_form_of.tagged_inflections({
		lang = lang, tags = {"1", "s", "pres", "ind"}, lemmas = {lemma_obj}, lemma_face = "term", POS = "verb"
	})

Normally, one value is returned, the formatted text, which has appended to it the formatted categories derived from the
tag-set-related categories generated by the specs in [Module:form of/cats]]. To suppress this, set
data.no_format_categories = true, in which case two values are returned, the formatted text without any formatted
categories appended and a list of the categories to be formatted.

NOTE: There are two sets of categories that may be generated: (1) categories derived directly from the tag sets, as
specified in [[Module:form of/cats]]; (2) categories derived from tag-set labels, either (a) set explicitly by the
caller in data.tag_sets, (b) specified by the user using <lb:...> attached to the last tag in a tag set, or
(c) specified in [[Module:form of/cats]]. The second type (label-related categories) are currently not returned in
the second return value of tagged_inflections(), and are currently inserted into the output text even if
data.no_format_categories is set to true; but they can be suppressed by setting data.nocat = true (which also
suppresses the first type of categories, those derived directly from tag sets, even if data.no_format_categories is set
to true).
]=]
function export.tagged_inflections(data)
	if not data.tags and not data.tag_sets then
		error("First argument must be a table of arguments, and `.tags` or `.tag_sets` must be specified")
	end
	if data.tags and data.tag_sets then
		error("Both `.tags` and `.tag_sets` cannot be specified")
	end
	local tag_sets = data.tag_sets
	if not tag_sets then
		tag_sets = export.split_tag_set(data.tags)
		for i, tag_set in ipairs(tag_sets) do
			tag_sets[i] = export.parse_tag_set_properties(tag_set)
		end
	end

	local inflections = {}
	local categories = {}
	for _, tag_set in ipairs(tag_sets) do
		local normalized_tag_sets = export.normalize_tag_set(tag_set.tags, data.lang, "do-track")

		for _, normalized_tag_set in ipairs(normalized_tag_sets) do
			local cur_infl = {}
			local this_categories, this_labels = export.fetch_categories_and_labels(normalized_tag_set, data.lang,
				data.POS, data.pagename, type(data.lemmas) == "table" and data.lemmas or nil)
			if not data.nocat then
				m_table.extendList(categories, this_categories)
			end
			local cur_infl = export.get_tag_set_display_form(normalized_tag_set, data.lang, data.joiner)
			if #cur_infl > 0 then
				if tag_set.labels then
					this_labels = m_table.append(tag_set.labels, this_labels)
				end
				table.insert(inflections, {infl_text = cur_infl, labels = this_labels})
			end
		end
	end

	local overall_labels, need_per_tag_set_labels
	for _, inflection in ipairs(inflections) do
		if overall_labels == nil then
			overall_labels = inflection.labels
		elseif not m_table.deepEquals(overall_labels, inflection.labels) then
			need_per_tag_set_labels = true
			overall_labels = nil
			break
		end
	end

	if not need_per_tag_set_labels then
		for _, inflection in ipairs(inflections) do
			inflection.labels = nil
		end
	end

	local format_data = m_table.shallowcopy(data)

	local function format_labels(labels, notext)
		if labels and #labels > 0 then
			return require(labels_module).show_labels { labels = labels, lang = data.lang, sort = data.sort, nocat = data.nocat } ..
				(notext and (data.pretext or "") == "" and "" or " ")
		else
			return ""
		end
	end

	local of_text = data.lemmas and " of" or ""
	local formatted_text
	if #inflections == 1 then
		if need_per_tag_set_labels then
			error("Internal error: need_per_tag_set_labels should not be set with one inflection")
		end
		format_data.text = format_labels(overall_labels, data.notext) .. (data.pretext or "") .. (data.notext and "" or
			((data.capfirst and require("string utilities").ucfirst(inflections[1].infl_text) or inflections[1].infl_text) .. of_text))
		formatted_text = export.format_form_of(format_data)
	else
		format_data.text = format_labels(overall_labels, data.notext) .. (data.pretext or "") .. (data.notext and "" or
			((data.capfirst and "Inflection" or "inflection") .. of_text))
		format_data.posttext = (data.posttext or "") .. ":"
		local link = export.format_form_of(format_data)
		local text_classes = data.text_classes or "form-of-definition use-with-mention"
		for i, inflection in ipairs(inflections) do
			inflections[i] = "\n## " .. format_labels(inflection.labels, false) ..
				"<span class='" .. text_classes .. "'>" .. inflection.infl_text .. "</span>"
		end
		formatted_text = link .. table.concat(inflections)
	end

	if not data.no_format_categories then
		if #categories > 0 then
			formatted_text = formatted_text .. require("utilities").format_categories(categories, data.lang,
				data.sort, nil, export.force_cat)
		end
		return formatted_text
	end
	return formatted_text, categories
end


-- Given a tag set, return a flattened list all Wikidata ID's of all tags in the tag set.
-- FIXME: Only used in a debugging function in [[Module:se-verbs]]; move there.
function export.to_Wikidata_IDs(tag_set, lang, skip_tags_without_ids)
	local ret = {}

	local function get_wikidata_id(tag)
		local data = export.lookup_tag(tag, lang)

		if not data or not data[export.WIKIPEDIA] then
			if not skip_tags_without_ids then
				error('The tag "' .. tag .. '" does not have a Wikidata ID defined in the form-of data modules')
			else
				return nil
			end
		else
			return ("Q%s"):format(data[export.WIKIPEDIA])
		end
	end

	local normalized_tag_sets = export.normalize_tag_set(tag_set, lang)
	for _, tag_set in ipairs(normalized_tag_sets) do
		for _, tag in ipairs(tag_set) do
			if type(tag) == "table" then
				for _, subtag in ipairs(tag) do
					if type(subtag) == "table" then
						-- two-level multipart tag; FIXME: delete support for this
						for _, subsubtag in ipairs(subtag) do
							table.insert(ret, get_wikidata_id(subsubtag))
						end
					else
						table.insert(ret, get_wikidata_id(subtag))
					end
				end
			else
				table.insert(ret, get_wikidata_id(tag))
			end
		end
	end

	return ret
end


function export.dump_form_of_data(frame)
	local data = {
		data = require(export.form_of_data_module),
		data2 = require(export.form_of_data2_module)
	}
	return require("JSON").toJSON(data)
end


function export.finalize_tag_data(tags, shortcuts)
	local function process_shortcut(name, shortcut)
		-- If the shortcut is already in the list, then there is a duplicate.
		if shortcuts[shortcut] then
			error("The shortcut \"" .. shortcut .. "\" (for the inflection tag \"" .. name .. "\") conflicts with an existing shortcut for the tag \"" .. shortcuts[shortcut] .. "\".")
		elseif tags[shortcut] then
			error("The shortcut \"" .. shortcut .. "\" (for the inflection tag \"" .. name .. "\") conflicts with an existing tag with that name.")
		end

		shortcuts[shortcut] = name
	end
	for name, data in pairs(tags) do
		local data_shortcuts = data[export.SHORTCUTS]
		if data_shortcuts then
			if type(data_shortcuts) == "string" then
				process_shortcut(name, data_shortcuts)
			else
				for _, shortcut in ipairs(data_shortcuts) do
					process_shortcut(name, shortcut)
				end
			end
		end
	end
end


return export