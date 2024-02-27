local labels = {}
local raw_categories = {}
local raw_handlers = {}


-----------------------------------------------------------------------------
--                                                                         --
--                                  LABELS                                 --
--                                                                         --
-----------------------------------------------------------------------------


labels["entry maintenance"] = {
	description = "{{{langname}}} entries, or entries in other languages containing {{{langname}}} terms, that are being tracked for attention and improvement by editors.",
	parents = {{name = "{{{langcat}}}", raw = true}},
	umbrella_parents = "Fundamental",
}

labels["entries with incorrect language header"] = {
	description = "{{{langname}}} entries that which have been placed under the wrong language header.",
	additional = "This can happen for several reasons:\n" ..
	"* Typos.\n" ..
	"* Vandalism.\n" ..
	"* Using the wrong language code.\n" ..
	"* Using an alternative name for the language.\n" ..
	"* Using special characters which haven't been used in the name given in the language data modules.",
	parents = {"entry maintenance"},
	can_be_empty = true,
	hidden = true,
}

labels["entries without References header"] = {
	description = "{{{langname}}} entries without a References header.",
	parents = {"entry maintenance"},
	can_be_empty = true,
	hidden = true,
}

labels["entries without References or Further reading header"] = {
	description = "{{{langname}}} entries without a References or Further reading header.",
	parents = {"entry maintenance"},
	can_be_empty = true,
	hidden = true,
}

labels["entries that don't exist"] = {
	description = "{{{langname}}} terms that do not meet the [[Wiktionary:Criteria for inclusion|criteria for inclusion]] (CFI). They are added to the category with the template {{tl|no entry|{{{langcode}}}}}.",
	parents = {"entry maintenance"},
}

labels["entries with language name categories using raw markup"] = {
	description = "{{{langname}}} entries that have been placed in a language name category using raw wiki markup (i.e. <code><nowiki>[[Category:{{{langname}}} ...]]</nowiki></code>). They should be added using {{tl|cln|{{{langcode}}}|...}} instead.",
	parents = {"entry maintenance"},
	can_be_empty = true,
	hidden = true,
}

labels["entries with topic categories using raw markup"] = {
	description = "{{{langname}}} entries that have been placed in a topic category using raw wiki markup (i.e. <code><nowiki>[[Category:{{{langcode}}}:...]]</nowiki></code>). They should be added using {{tl|C|{{{langcode}}}|...}} instead.",
	parents = {"entry maintenance"},
	can_be_empty = true,
	hidden = true,
}

labels["entries with outdated source"] = {
	description = "{{{langname}}} entries that have been partly or fully imported from an outdated source.",
	parents = {"entry maintenance"},
}

labels["undefined derivations"] = {
	description = "{{{langname}}} etymologies using {{tl|undefined derivation}}, where a more specific template such as {{tl|borrowed}} or {{tl|inherited}} should be used instead.",
	parents = {"entry maintenance"},
	can_be_empty = true,
	hidden = true,
}

labels["descendants to be fixed in desctree"] = {
	description = "Entries that use {{tl|desctree}} to link to {{{langname}}} entries with no Descendants section.",
	parents = {"entry maintenance"},
	can_be_empty = true,
	hidden = true,
}

labels["term requests"] = {
	description = "Entries with [[Template:der]], [[Template:inh]], [[Template:m]] and similar templates lacking the parameter for linking to {{{langname}}} terms.",
	parents = {"entry maintenance"},
	can_be_empty = true,
	hidden = true,
}

labels["redlinks"] = {
	description = "Links to {{{langname}}} entries that have not been created yet.",
	parents = {"entry maintenance"},
	catfix = false,
	can_be_empty = true,
	hidden = true,
}

labels["terms with IPA pronunciation"] = {
	description = "{{{langname}}} terms that include the pronunciation in the form of IPA.",
	additional = "For requests related to this category, see [[:Category:Requests for pronunciation in {{{langname}}} entries]].",
	parents = {"entry maintenance"},
}

labels["terms with hyphenation"] = {
	description = "{{{langname}}} terms that include hyphenation.",
	parents = {"entry maintenance"},
}

labels["terms with audio links"] = {
	description = "{{{langname}}} terms that include the pronunciation in the form of an audio link.",
	parents = {"entry maintenance"},
}

local function add_manual_param_category(label, desc, addl_intro, include_addl_continuation)
	labels[label] = {
		description = desc or "Pages containing {{{langname}}} " .. label .. ".",
		additional = addl_intro .. (not include_addl_continuation and "" or "\n\n" ..
		"Note that the pages in this category are not necessarily the same as the actual term in question. This " ..
		"frequently happens, for example, with English pages with translation sections, where the term that " ..
		"triggers the addition of the category is one of the translations."),
		parents = {"entry maintenance"},
		-- Set catfix = false because the page will have a mixture of native-language and
		-- non-native-language pages, but include the normal native-language table of contents headers
		-- because most pages are in the native language.
		catfix = false,
		toc_template = "{{{langcode}}}-categoryTOC",
		toc_template_full = "{{{langcode}}}-categoryTOC/full",
		can_be_empty = true,
		hidden = true,
	}
end

add_manual_param_category("terms in nonstandard scripts", nil,
	"Pages are placed here if they contain terms written in a script that isn't in the language's " ..
	"list of scripts in the language data. This may mean the script should be added to the list, or that the wrong language code has been used.",
	true)

add_manual_param_category("terms with non-redundant manual transliterations", nil,
	"Pages are placed here if they contain terms whose transliteration has been specified manually using " ..
	"{{para|tr}} or a similar parameter and is different from the transliteration which is automatically generated.",
	true)

add_manual_param_category("terms with redundant transliterations", nil,
	"Pages are placed here if they contain terms whose transliteration has been specified manually using " ..
	"{{para|tr}} or a similar parameter and is the same as the transliteration which is automatically generated.",
	true)

add_manual_param_category("terms with non-redundant manual script codes", nil,
	"Pages are placed here if they contain terms whose script code has been specified manually using " ..
	"{{para|sc}} or a similar parameter and is different from the script code which is automatically generated.",
	true)

add_manual_param_category("terms with redundant script codes", nil,
	"Pages are placed here if they contain terms whose script code has been specified manually using " ..
	"{{para|sc}} or a similar parameter and is the same as the script code which is automatically generated.",
	true)

add_manual_param_category("terms with non-redundant non-automated sortkeys",
	"{{{langname}}} terms with non-redundant non-automated sortkeys.",
	"Terms are placed here if they have been sorted using a sortkey other than the one which is automatically " ..
	"generated. This can happen for two reasons:\n# A different sortkey has been specified using the {{para|sort}} " ..
	"parameter.\n# One or more categories have been added using raw wikitext, which means the page's default " ..
	"sortkey is used for that category. If that default sortkey is different from the automatic sortkey, then the " ..
	"page will also be added here.")

add_manual_param_category("terms with redundant sortkeys",
	"{{{langname}}} terms with redundant sortkeys.",
	"Terms are placed here if their sortkey has been specified using the {{para|sort}} parameter, and it the same " ..
	"as the one which is automatically generated.")

add_manual_param_category("links with redundant target parameters",
	"Pages containing {{{langname}}} links where the alt text could replace the link target, instead of being given " ..
	"separately.",
	"This occurs when the only difference between the link target and the alt text is that the alt text contains " ..
	"diacritics (or other characters) which would have been ignored anyway had they been included in the link " ..
	"target. For example, {{tl|l|la|amo|amō}} ({{l|la|amo|amō}}) is exactly the same as {{tl|l|la|amō}} " ..
	"({{l|la|amō}}), because macrons are automatically stripped from Latin link targets, even though they're still " ..
	"displayed.")

add_manual_param_category("links with ignored alt parameters",
	"Pages containing {{{langname}}} links where the {{para|alt}} parameter has been ignored.",
	"This occurs when the main linked text includes a wikilink.")

add_manual_param_category("links with redundant alt parameters",
	"Pages containing {{{langname}}} links where the {{para|alt}} parameter is redundant.",
	"This occurs when the alt text makes no difference to the output. For example, {{tl|l|en|foo|foo}} " ..
	"({{l|en|foo|foo}}) is exactly the same as {{tl|l|en|foo}} ({{l|en|foo}}).")

add_manual_param_category("links with ignored id parameters",
	"Pages containing {{{langname}}} links where the {{para|id}} parameter has been ignored.",
	"This occurs when the main linked text includes a wikilink.")

add_manual_param_category("links with redundant wikilinks",
	"Pages containing {{{langname}}} links which contain a redundant wikilink.",
	"This occurs if link target consists of a single wikilink, which should instead be entered in the " ..
	"conventional manner without link brackets. For example, {{tl|l|en|<nowiki>[[foo]]</nowiki>}} " ..
	"is the same as {{tl|l|en|foo}}, and {{tl|l|en|<nowiki>[[foo|bar]]</nowiki>}} is the same as " ..
	"{{tl|l|en|foo|bar}}.\n\nThis also occurs when link templates are nested inside each other " ..
	"unnecessarily: e.g. {{tl|l|en|{{tl|l|en|foo}}}}")

add_manual_param_category("links with manual fragments",
	"Pages containing {{{langname}}} links where a manual link fragment has been given.",
	"This occurs when the link fragment has been specified using <code>#</code> after the term, " ..
	"which overrides the normal fragment generated by link templates that points to the relevant " ..
	"language section.\n\nLink fragments are used to point to a specific section on a target page, and " ..
	"it is preferable to use the {{para|id}} parameter to do this, since it is less likely to break if " ..
	"additional content is added to the target page: for example, the fragment <code>#Adjective</code> " ..
	"will start pointing to the wrong section if another language with an adjective section is added above " ..
	"the intended language.")

labels["descendant hubs"] = {
	description = "{{{langname}}} terms that do not mean more than the sum of their parts but exist for listing two or more inclusion-worthy descendants.",
	parents = {"entry maintenance"},
}

labels["terms needing to be assigned to a sense"] = {
	description = "{{{langname}}} entries that have terms under headers such as \"Synonyms\" or \"Antonyms\" not assigned to a specific sense of the entry in which they appear. Use [[Template:syn]] or [[Template:ant]] to fix these.",
	parents = {"entry maintenance"},
	can_be_empty = true,
	hidden = true,
}

--[=[
labels["terms with inflection tables"] = {
	description = "{{{langname}}} entries that contain inflection tables.".
	additional = "For requests related to this category," see [[:Category:Requests for inflections in {{{langname}}} entries]].",
	parents = {"entry maintenance"},
}
]=]

labels["terms with collocations"] = {
	description = "{{{langname}}} entries that contain [[collocation]]s that were added using templates such as {{tl|co}}.",
	additional = "For requests related to this category, see [[:Category:Requests for collocations in {{{langname}}}]]. See also [[:Category:Requests for quotations in {{{langname}}}]] and [[:Category:Requests for example sentences in {{{langname}}}]].",
	parents = {"entry maintenance"},
}

labels["terms with usage examples"] = {
	description = "{{{langname}}} entries that contain usage examples that were added using templates such as {{tl|ux}}.",
	additional = "For requests related to this category, see [[:Category:Requests for example sentences in {{{langname}}}]]. See also [[:Category:Requests for collocations in {{{langname}}}]] and [[:Category:Requests for quotations in {{{langname}}}]].",
	parents = {"entry maintenance"},
}

labels["terms with quotations"] = {
	description = "{{{langname}}} entries that contain quotes that were added using templates such as {{tl|quote}}, {{tl|quote-book}}, {{tl|quote-journal}}, etc.",
	additional = "For requests related to this category, see [[:Category:Requests for quotations in {{{langname}}}]]. See also [[:Category:Requests for collocations in {{{langname}}}]] and [[:Category:Requests for example sentences in {{{langname}}}]].",
	parents = {"entry maintenance"},
}

labels["terms with redundant head parameter"] = {
	description = "{{{langname}}} terms that contain a redundant head= parameter in their headword (called using {{tl|head}} or a language-specific equivalent).",
	additional = "Individual languages can prevent terms from being added to this category by setting `data.no_redundant_head_cat`.",
	parents = {"entry maintenance"},
	can_be_empty = true,
	hidden = true,
}

labels["terms with red links in their headword lines"] = {
	description = "{{{langname}}} terms that contain red links (i.e. uncreated forms) in their headword lines.",
	parents = {"redlinks"},
	can_be_empty = true,
	hidden = true,
}

labels["terms with red links in their inflection tables"] = {
	description = "{{{langname}}} terms that contain red links (i.e. uncreated forms) in their inflection tables.",
	parents = {"redlinks"},
	can_be_empty = true,
	hidden = true,
}

labels["requests for English equivalent term"] = {
	description = "{{{langname}}} entries with definitions that have been tagged with {{tl|rfeq}}. Read the documentation of the template for more information.",
	parents = {"entry maintenance"},
	can_be_empty = true,
	hidden = true,
}

for _, quot_type in ipairs { "quotations", "usage examples" } do
	labels[quot_type .. " with omitted translation"] = {
		description = "{{{langname}}} " .. quot_type .. " where a translation would normally be required but the translation has explicitly been omitted by specifying <code>-</code>. The translation should be supplied instead.",
		parents = {"entry maintenance"},
		can_be_empty = true,
		hidden = true,
	}
end

for _, pos in ipairs({"nouns", "proper nouns", "verbs", "adjectives", "adverbs", "participles", "determiners", "pronouns", "numerals", "suffixes", "contractions"}) do
	labels[pos .. " with red links in their headword lines"] = {
		description = "{{{langname}}} " .. pos .. " that contain red links (i.e. uncreated forms) in their headword lines.",
		parents = {"terms with red links in their headword lines"},
		breadcrumb = pos,
		can_be_empty = true,
		hidden = true,
	}

	labels[pos .. " with red links in their inflection tables"] = {
		description = "{{{langname}}} " .. pos .. " that contain red links (i.e. uncreated forms) in their inflection tables.",
		parents = {"terms with red links in their inflection tables"},
		breadcrumb = pos,
		can_be_empty = true,
		hidden = true,
	}
end


for _, pos in ipairs { "nouns", "proper nouns", "pronouns" } do
	local label = pos .. " with unknown or uncertain plurals"
	labels[label] = {
		description = "{{{langname}}} " .. label .. ".",
		additional = "Terms are usually added to this category by specifying <code>?</code> as the plural. As much " ..
		"is possible, a plural should be added or, if the noun is uncountable, indicated appropriately (usually " ..
		"using <code>-</code> in place of the plural). Some languages support the value <code>!</code> to indicate " ..
		"that a plural cannot be attested but the noun is theoretically countable.",
		breadcrumb = "with unknown or uncertain plurals",
		parents = {
			{name = pos, sort = "unknown or uncertain plurals"},
			"entry maintenance",
		},
	}
end


-- Add 'umbrella_parents' key if not already present.
for key, data in pairs(labels) do
	if not data.umbrella_parents then
		data.umbrella_parents = "Entry maintenance subcategories by language"
	end
end





-----------------------------------------------------------------------------
--                                                                         --
--                              RAW CATEGORIES                             --
--                                                                         --
-----------------------------------------------------------------------------


raw_categories["Entry maintenance subcategories by language"] = {
	description = "Umbrella categories covering topics related to entry maintenance.",
	additional = "{{{umbrella_meta_msg}}}",
	parents = {
		"Umbrella metacategories",
		{name = "entry maintenance", is_label = true, sort = " "},
	},
}

raw_categories["Requests"] = {
	topright = "{{shortcut|WT:CR|WT:RQ}}",
	description = "A parent category for the various request categories.",
	parents = {"Category:Wiktionary"},
}

raw_categories["Requests by language"] = {
	description = "Categories with requests in various specific languages.",
	additional = "{{{umbrella_msg}}}",
	parents = {
		{name = "Request subcategories by language", sort = " "},
		{name = "Requests", sort = " "},
	},
	breadcrumb = "By language",
}

raw_categories["Request subcategories by language"] = {
	description = "Umbrella categories covering topics related to requests.",
	additional = "{{{umbrella_meta_msg}}}",
	parents = {
		"Umbrella metacategories",
		{name = "Requests", sort = " "},
	},
}

raw_categories["Requests for quotations by source"] = {
	description = "Categories with requests for quotation, broken out by the source of the quotation.",
	additional = "Some abbreviated names of sources are explained at [[Wiktionary:Abbreviated Authorities in Webster]].",
	parents = {{name = "Requests for quotations", sort = "source"}},
	breadcrumb = "By source",
}

raw_categories["Requests for quotations"] = {
	-- FIXME
	description = "Words are added to this category by the inclusion in their entries of {{tl|rfv-quote}}.",
	parents = {{name = "Requests", sort = "quotations"}},
	breadcrumb = "Quotations",
}

raw_categories["Requests for date by source"] = {
	description = "{{rfd}}Categories with requests for date, broken out by the source of the quotation whose date is sought.",
	parents = {{name = "Requests for date", sort = "source"}},
	breadcrumb = "By source",
}

raw_categories["Requests for date"] = {
	description = "Requests for a date to be added to a quotation.",
	additional = "To add an article to this category, use {{tl|rfdate}} or {{tl|rfdatek}} to include the author. " ..
	"Please remove the template from the article once the date has been provided.",
	parents = {{name = "Requests", sort = "date"}},
	breadcrumb = "Date",
}

raw_categories["Requests for translations in user-competency categories by number of users"] = {
	description = "Requests for translations to be added to user-competency categories, sorted by number of users with that competency.",
	parents = {{name = "Requests", sort = "translations"}},
	breadcrumb = "Translations in user-competency categories by number of users",
}

raw_categories["Requests for translations in user-competency categories by language"] = {
	description = "Requests for translations to be added to user-competency categories, sorted by language.",
	parents = {{name = "Requests", sort = "translations"}},
	breadcrumb = "Translations in user-competency categories by language",
	hidden = true,
}

raw_categories["Entries using missing taxonomic names"] = {
	description = "Entries that link to wikispecies because there is no corresponding Wiktionary entry for the taxonomic name in the template {{tl|taxlink}}.",
	additional = "The missing name is one or more of those enclosed in {{tl|taxlink}}. The entries are sorted by the missing taxonomic name." ..
	"\n\nSee [[:Category:mul:Taxonomic names]].",
	parents = {{name = "entry maintenance", is_label = true, lang = "mul"}},
	breadcrumb = "Missing taxonomic names",
	hidden = true,
}


-----------------------------------------------------------------------------
--                                                                         --
--                               RAW HANDLERS                              --
--                                                                         --
-----------------------------------------------------------------------------

local function script_name_to_code(name)
	local sc = require("scripts").getByCanonicalName(name)
	if not sc then
		error("Unrecognized script name '" .. name .. "'")
	end
	return sc:getCode()
end

--[=[
This array consists of category match specs. Each spec contains one or more properties, whose values are (a) strings
that may contain references to other properties using the {{{PROPERTY}}} syntax; (b) functions of one argument, an
`items` table of the same properties that are accessible using the {{{PROPERTY}} syntax. Each such spec should have at
least a `regex` property that matches the name of the category. Capturing groups in this regex can be referenced in
other properties using {{{1}}} for the first group, {{{2}}} for the second group, etc. (or using keys "1", "2", etc. in
functions). Property expansion happens recursively if needed (i.e. a property can reference another property, which in
turn references a third property).

If there is a `language_name` propery, it specifies the language name (and will typically be a reference to a capturing
group from the `regex` property); if not specified, it defaults to "{{{1}}}" unless the `nolang` property is set, in
which case there is no language name associated with the category name. The language name must be the canonical name of
a recognized full language, or an error is thrown; however, if the `allow_etym_lang` property is set, the language name
may also be the canonical name of an etymology-only language. Based on the language name, the `language_code` and
`language_object` properties are automatically filled in. If `language_name` is an etymology-only language, additional
properties `parent_language_name`, `parent_language_code` and `parent_language_object` are set for the parent full
language of the etymology-only language.

If the `regex` values of multiple category specs match, the first one takes precedence.

Recognized or predefined properties:

`pagename`: Current pagename.
`regex`: See above.
`1`, `2`, `3`, ...: See above.
`language_name`, `language_code`, `language_object`: See above.
`parent_language_name`, `parent_language_code`, `parent_language_object`: See above.
`nolang`: See above.
`allow_etym_lang`: Language names may be etymology-only languages. See above.
`description`: Override the description (normally taken directly from the pagename).
`template_name`: Name of template which generates this category.
`template_sample_call`: Syntax for calling the template. Defaults to "{{{template_name}}}|{{{language_code}}}". Used to
   display an example template call and the output of this call.
`template_actual_sample_call`: Syntax for calling the template. Takes precedence over `template_sample_call` when
   generating example template output (but not when displaying an example template call) and is intended for a template
   call that uses the |nocat=1 parameter.
`template_example_output`: Override the text that displays example template output (see `template_sample_call`).
`additional_template_description`: Extra text to be displayed after the example template output.
`parents`: Parent categories. Should be a list of elements, each of which is an object containing at least a name= and
   sort= field (same format as parents= for regular raw categories, except that the name= and sort= field will have
   {{{PROPERTY}}} references expanded). If no parents are specified, and the pagename is of the form "Requests for FOO
   by language", the parent will be "Request subcategories by language" with FOO as the sort key. Otherwise, the
   `language_name` property must exist, and the parent will be "Requests concerning LANGNAME", with the pagename minus
   any initial "Requests for " as the sort key. Note that this does *NOT* apply if an etymology-only language is
   associated with the category, in which case `etym_parents` is used instead.
`etym_parents`: Parent categories for categories with associated etymology-only languages. The format is the same as
   `parents`. If omitted, there are two parents by default: (1) The pagename (i.e. category name) with the language name
   replaced by the corresponding parent language name, with the value of `language_name` as the sort key; (2) "Requests
   concerning LANGNAME", with the pagename minus any initial "Requests for " as the sort key.
`umbrella`: Parent all-language category. Sort key is based on the language name. This applies *ONLY* if a full language
   is associated with the category name (i.e. not if `nolang` is set or if `allow_etym_lang` is set and the associated
   language is an etymology-only language); otherwise there will be no umbrella category.
`breadcrumb`: Specify the breadcrumb. If `parents` is given, there is no default (i.e. it will end up being the
   pagename). Otherwise, if the pagename is of the form "Requests for FOO by language", "Requests for FOO in BAR", or
   "Requests for FOO", it will be FOO. Note that this does *NOT* apply if an etymology-only language is associated with
   the category, in which case `etym_breadcrumb` is used instead.
`etym_breadcrumb`: Specify the breadcrumb for categories with associated etymology-only languages. Defaults to the value
   of `language_name`.
`not_hidden_category`: Don't hide the category.
`catfix`: Same as `catfix` in regular labels and raw categories, except that request-specific {{{PROPERTY}}} syntax is
   expanded.
`toc_template`, `toc_template_full`: Same as the corresponding fields in regular labels and raw categories, except that
   request-specific {{{PROPERTY}}} syntax is expanded.

In general, properties can contain references to templates (e.g. {{tl}} and {{para}}), which will be appropriately
expanded (this expansion happens in the poscatboiler code, not in this module). The major exception is in the
`template_sample_call` and `template_actual_sample_call` properties, which are surrounded by <pre>...</pre> when
inserted, so template references are not expanded. Triple-brace property references are still expanded in these
properties; but beware that if any of those property references contain template references, they won't be expanded.
(This actually happens in the handlers for 'Request for SCRIPT script for LANG terms'; the sample call references
{{{script_code}}}, whose definition therefore cannot contain template references. The solution is to define this
property using a function.)
]=]
local requests_categories = {
	{
		regex = "^Requests concerning (.+)$",
		allow_etym_lang = true,
		description = "Categories with {{{1}}} entries that need the attention of experienced editors.",
		parents = {{name = "entry maintenance", is_label = true, sort = "requests"}},
		etym_parents = {{name = "Requests concerning {{{parent_language_name}}}", sort = "{{{1}}}"}},
		umbrella = "Requests by language",
		breadcrumb = "Requests",
		not_hidden_category = true,
	},
	{
		regex = "^Requests for etymologies in (.+) entries$",
		allow_etym_lang = true,
		umbrella = "Requests for etymologies by language",
		template_name = "rfe",
	},
	{
		regex = "^Requests for expansion of etymologies in (.+) entries$",
		umbrella = "Requests for expansion of etymologies by language",
		template_name = "etystub",
	},
	{
		regex = "^Requests for pronunciation in (.+) entries$",
		umbrella = "Requests for pronunciation by language",
		template_name = "rfp",
	},
	{
		regex = "^Requests for audio pronunciation in (.+) entries$",
		umbrella = "Requests for audio pronunciation by language",
		template_name = "rfap",
	},
	{
		regex = "^Requests for definitions in (.+) entries$",
		umbrella = "Requests for definitions by language",
		template_name = "rfdef",
	},
	{
		regex = "^Requests for clarification of definitions in (.+) entries$",
		umbrella = "Requests for clarification of definitions by language",
		template_name = "rfclarify",
	},
	{
		-- This is for part-of-speech-specific categories such as
		-- "Requests for inflections in Northern Ndebele noun entries" or
		-- "Requests for accents in Ukrainian proper noun entries".
		-- Here and below, we assume that the part of speech is begins with
		-- a lowercase letter, while the preceding language name ends in a
		-- capitalized word. Note that this entry comes before the
		-- following one and takes precedence over it.
		regex = "^Requests for inflections in (.-) ([a-z]+[a-z ]*) entries$",
		parents = {{name = "Requests for inflections in {{{language_name}}} entries", sort = "{{{2}}}"}},
		umbrella = "Requests for inflections of {{{2}}}s by language",
		breadcrumb = "{{{2}}}",
		template_name = "rfinfl",
		template_sample_call = "{{rfinfl|{{{language_code}}}|{{{2}}}}}",
	},
	{
		regex = "^Requests for inflections in (.+) entries$",
		umbrella = "Requests for inflections by language",
		template_name = "rfinfl",
	},
	{
		regex = "^Requests for inflections of (.+) by language$",
		nolang = true,
	},
	{
		regex = "^Requests for tone in (.-) ([a-z]+[a-z ]*) entries$",
		parents = {{name = "Requests for tone in {{{language_name}}} entries", sort = "{{{2}}}"}},
		umbrella = "Requests for tone of {{{2}}}s by language",
		breadcrumb = "{{{2}}}",
		template_name = "rftone",
		template_sample_call = "{{rftone|{{{language_code}}}|{{{2}}}}}",
	},
	{
		regex = "^Requests for tone in (.+) entries$",
		umbrella = "Requests for tone by language",
		template_name = "rftone",
	},
	{
		regex = "^Requests for tone of (.+) by language$",
		nolang = true,
	},
	{
		regex = "^Requests for accents in (.-) ([a-z]+[a-z ]*) entries$",
		parents = {{name = "Requests for accents in {{{language_name}}} entries", sort = "{{{2}}}"}},
		umbrella = "Requests for accents of {{{2}}}s by language",
		breadcrumb = "{{{2}}}",
		template_name = "rfaccents",
		template_sample_call = "{{rfaccents|{{{language_code}}}|{{{2}}}}}",
	},
	{
		regex = "^Requests for accents in (.+) entries$",
		umbrella = "Requests for accents by language",
		template_name = "rfaccents",
	},
	{
		regex = "^Requests for accents of (.+) by language$",
		nolang = true,
	},
	{
		regex = "^Requests for aspect in (.-) ([a-z]+[a-z ]*) entries$",
		parents = {{name = "Requests for aspect in {{{language_name}}} entries", sort = "{{{2}}}"}},
		umbrella = "Requests for aspect of {{{2}}}s by language",
		breadcrumb = "{{{2}}}",
		template_name = "rfaspect",
		template_sample_call = "{{rfaspect|{{{language_code}}}|{{{2}}}}}",
	},
	{
		regex = "^Requests for aspect in (.+) entries$",
		umbrella = "Requests for aspect by language",
		template_name = "rfaspect",
	},
	{
		regex = "^Requests for aspect of (.+) by language$",
		nolang = true,
	},
	{
		regex = "^Requests for gender in (.-) ([a-z]+[a-z ]*) entries$",
		parents = {{name = "Requests for gender in {{{language_name}}} entries", sort = "{{{2}}}"}},
		umbrella = "Requests for gender of {{{2}}}s by language",
		breadcrumb = "{{{2}}}",
		template_name = "rfgender",
		template_sample_call = "{{rfgender|{{{language_code}}}|{{{2}}}}}",
	},
	{
		regex = "^Requests for gender in (.+) entries$",
		umbrella = "Requests for gender by language",
		template_name = "rfgender",
	},
	{
		regex = "^Requests for gender of (.+) by language$",
		nolang = true,
	},
	{
		regex = "^Requests for example sentences in (.+)$",
		umbrella = "Requests for example sentences by language",
		template_name = "rfex",
	},
	{
		regex = "^Requests for collocations in (.+)$",
		umbrella = "Requests for collocations by language",
		template_name = "rfcoll",
	},
	{
		regex = "^Requests for quotations in (.+)$",
		umbrella = "Requests for quotations by language",
		template_name = "rfquote",
	},
	{
		regex = "^Requests for translations into (.+)$",
		allow_etym_lang = true,
		umbrella = "Requests for translations by language",
		template_name = "t-needed",
		catfix = "en",
	},
	{
		regex = "^Requests for translations of (.+) usage examples$",
		allow_etym_lang = true,
		umbrella = "Requests for translations of usage examples by language",
		breadcrumb = "Translations of usage examples",
		template_name = "t-needed",
		template_sample_call = "{{t-needed|{{{language_code}}}|usex}}",
		template_actual_sample_call = "{{t-needed|{{{language_code}}}|usex|nocat=1}}",
		additional_template_description = "The {{tl|ux}}, {{tl|uxi}}, {{tl|ja-usex}} and {{tl|zh-x}} templates automatically add the page to this category if the example is in a foreign language and the translation is missing."
	},
	{
		regex = "^Requests for translations of (.+) quotations$",
		allow_etym_lang = true,
		umbrella = "Requests for translations of quotations by language",
		breadcrumb = "Translations of quotations",
		template_name = "t-needed",
		template_sample_call = "{{t-needed|{{{language_code}}}|quote}}",
		template_actual_sample_call = "{{t-needed|{{{language_code}}}|quote|nocat=1}}",
		additional_template_description = "The {{tl|quote}}, and {{tl|Q}} templates automatically add the page to this category if the example is in a foreign language and the translation is missing."
	},
	{
		regex = "^Requests for review of (.+) translations$",
		allow_etym_lang = true,
		umbrella = "Requests for review of translations by language",
		breadcrumb = "Review of translations",
		template_name = "t-check",
		template_sample_call = "{{t-check|{{{language_code}}}|example}}",
		template_example_output = "",
		catfix = "en",
	},
	{
		regex = "^Requests for transliteration of (.+) terms$",
		umbrella = "Requests for transliteration by language",
		template_name = "rftranslit",
		additional_template_description = "The {{tl|head}} template, and the large number of language-specific variants of it, automatically add " ..
		"the page to this category if the example is in a foreign language and no transliteration can be generated (particularly in languages without " ..
		"automated transliteration, such as Hebrew and Persian).",
	},
	{
		regex = "^Requests for transliteration of (.+) usage examples$",
		umbrella = "Requests for transliteration of usage examples by language",
		template_name = "rftranslit",
		template_sample_call = "{{rftranslit|{{{language_code}}}|usex=1}}",
		template_actual_sample_call = "{{rftranslit|{{{language_code}}}|usex=1|nocat=1}}",
		catfix = false,
		additional_template_description = "The {{tl|ux}} and {{tl|uxi}} templates automatically add the page to this category if the example " ..
		"is in a foreign language and no transliteration can be generated (particularly in languages without automated transliteration, such as " ..
		"Hebrew and Persian).",
	},
	{
		regex = "^Requests for transliteration of (.+) quotations$",
		umbrella = "Requests for transliteration of quotations by language",
		template_name = "rftranslit",
		template_sample_call = "{{rftranslit|{{{language_code}}}|quote=1}}",
		template_actual_sample_call = "{{rftranslit|{{{language_code}}}|quote=1|nocat=1}}",
		catfix = false,
		additional_template_description = "The {{tl|quote}} and {{tl|quote-*}} templates automatically add the page to this category if the quotation " ..
		"is in a foreign language and no transliteration can be generated (particularly in languages without automated transliteration, such as " ..
		"Hebrew and Persian).",
	},
	{
		regex = "^Requests for native script for (.+) terms$",
		allow_etym_lang = true,
		etym_parents = {
			{name = "Requests for native script for {{{parent_language_name}}} terms", sort = "{{{1}}}"},
			{name = "Requests concerning {{{language_name}}}", sort = "native script"},
		},
		umbrella = "Requests for native script by language",
		template_name = "rfscript",
		template_actual_sample_call = "{{rfscript|{{{language_code}}}|nocat=1}}",
		catfix = false,
		additional_template_description = "Many templates such as {{tl|l}}, {{tl|m}} and {{tl|t}} automatically place the page in this category when they are missing the term but have been provided with a transliteration."
	},
	{
		regex = "^Requests for native script in (.+) usage examples$",
		umbrella = "Requests for native script in usage examples by language",
		template_name = "rfscript",
		template_sample_call = "{{rfscript|{{{language_code}}}|usex=1}}",
		template_actual_sample_call = "{{rfscript|{{{language_code}}}|usex=1|nocat=1}}",
		catfix = false,
		additional_template_description = "The {{tl|ux}} and {{tl|uxi}} templates automatically add the page to this category if the example itself is missing but the translation is supplied."
	},
	{
		regex = "^Requests for native script in (.+) quotations$",
		umbrella = "Requests for native script in quotations by language",
		template_name = "rfscript",
		template_sample_call = "{{rfscript|{{{language_code}}}|quote=1}}",
		template_actual_sample_call = "{{rfscript|{{{language_code}}}|quote=1|nocat=1}}",
		catfix = false,
		additional_template_description = "The {{tl|quote}} and {{tl|quote-*}} templates automatically add the page to this category if the quotation itself is missing but the translation is supplied."
	},
	{
		regex = "^Requests for (.+) script for (.+) terms$",
		language_name = "{{{2}}}",
		allow_etym_lang = true,
		parents = {{name = "Requests for native script for {{{language_name}}} terms", sort = "{{{1}}} script"}},
		etym_parents = {
			{name = "Requests for native script for {{{language_name}}} terms", sort = "{{{1}}} script"},
			{name = "Requests for {{{1}}} script for {{{parent_language_name}}} terms", sort = "{{{language_name}}}"},
			{name = "Requests concerning {{{language_name}}}", sort = "{{{1}}} script"},
		},
		umbrella = "Requests for {{{1}}} script by language",
		breadcrumb = "{{{1}}} script",
		etym_breadcrumb = "{{{1}}} script",
		template_name = "rfscript",
		-- NOTE: The following is used in `template_sample_call` and `template_actual_sample_call`, meaning the
		-- conversion of script name to script code needs to be done using an inline function like this, instead of
		-- a {{#invoke:...}} template call.
		script_code = function(items)
			return script_name_to_code(items["1"])
		end,
		template_sample_call = "{{rfscript|{{{language_code}}}|sc={{{script_code}}}}}",
		template_actual_sample_call = "{{rfscript|{{{language_code}}}|sc={{{script_code}}}|nocat=1}}",
		catfix = false,
		additional_template_description = "Many templates such as {{tl|l}}, {{tl|m}} and {{tl|t}} automatically place the page in this category when they are missing the term but have been provided with a transliteration."
	},
	{
		regex = "^Requests for (.+) script by language$",
		parents = {{name = "Requests for script by language", sort = "{{{1}}} script"}},
		nolang = true,
	},
	{
		regex = "^Requests for script by language$",
		nolang = true,
	},
	{
		regex = "^Requests for images in (.+) entries$",
		umbrella = "Requests for images by language",
		template_name = "rfi",
	},
	{
		regex = "^Requests for references for (.+) terms$",
		umbrella = "Requests for references by language",
		template_name = "rfref",
	},
	{
		regex = "^Requests for references for etymologies in (.+) entries$",
		parents = {{name = "Requests for references for {{{language_name}}} terms", sort = "etymologies"}},
		umbrella = "Requests for references for etymologies by language",
		breadcrumb = "Etymologies",
		template_name = "rfv-etym",
	},
	{
		regex = "^Requests for references for pronunciations in (.+) entries$",
		parents = {{name = "Requests for references for {{{language_name}}} terms", sort = "pronunciations"}},
		umbrella = "Requests for references for pronunciations by language",
		breadcrumb = "Pronunciations",
		template_name = "rfv-pron",
	},
	{
		regex = "^Requests for attention concerning (.+)$",
		umbrella = "Requests for attention by language",
		template_name = "attention",
		template_example_output = "This template does not generate any text in entries.",
		-- These pages typically contain a mixture of English and native-language entries, so disable catfix.
		catfix = false,
		-- Setting catfix = false will normally trigger the English table of contents template.
		-- We still want the native-language table of contents template, though.
		toc_template = "{{{language_code}}}-categoryTOC",
		toc_template_full = "{{{language_code}}}-categoryTOC/full", 
	},
	{
		regex = "^Requests for cleanup in (.+) entries$",
		umbrella = "Requests for cleanup by language",
		template_name = "rfc",
		template_actual_sample_call = "{{rfc|{{{language_code}}}|nocat=1}}",
	},
	{
		regex = "^Requests for cleanup of Pronunciation N headers in (.+) entries$",
		umbrella = "Requests for cleanup of Pronunciation N headers by language",
		template_name = "rfc-pron-n",
		template_actual_sample_call = "{{rfc-pron-n|{{{language_code}}}|nocat=1}}",
		template_example_output = "This template does not generate any text in entries.",
		additional_template_description = [=[
The purpose of this category is to tag entries that use headers with "Pronunciation" and a number.

While these headers and structure are sometimes used, they are not specifically prescribed by [[WT:ELE]]. No complete proposal has yet been made on how they should work, what the semantics are, or how they interact with multiple etymologies. As a result they should generally be avoided. Instead, merge the entries (possibly under multiple Etymology sections, if appropriate), and list all pronunciations, appropriately tagged, under a Pronunciation header.

[[User:KassadBot|KassadBot]] tags these entries (or used to tag these entries, when the bot was operational). At some point if a proposal is made and adopted as policy, these entries should be reviewed.

This category is hidden.]=],
	},
	{
		regex = "^Requests for deletion in (.+) entries$",
		umbrella = "Requests for deletion by language",
		template_name = "rfd",
		template_actual_sample_call = "{{rfd|{{{language_code}}}|nocat=1}}",
	},
	{
		regex = "^Requests for verification in (.+) entries$",
		umbrella = "Requests for verification by language",
		template_name = "rfv",
	},
	{
		regex = "^Requests for attention in (.+) etymologies$",
		umbrella = "Requests for attention by language"
	},
	{
		regex = "^Requests for quotations/(.+)$",
		description = "Requests for a quotation or for quotations from {{{1}}}.",
		parents = {{name = "Requests for quotations by source", sort = "{{{1}}}"}},
		breadcrumb = "{{{1}}}",
		nolang = true,
		template_name = "rfquotek",
		template_sample_call = "{{rfquotek|LANGCODE|{{{1}}}}}",
		template_example_output = "\n(where LANGCODE is the language code of the entry)\n\nIt results in the message below:\n\n{{rfquotek|und|{{{1}}}}}",
	},
	{
		regex = "^Requests for date in (.+) entries$",
		umbrella = "Requests for date by language",
		template_name = "rfdate",
		additional_template_description = "The quotation templates, such as {{tl|quote-book}} and {{tl|quote-journal}}, " ..
		"automatically add the page to this category if neither {{para|date}} nor {{para|year}} is provided. Providing the " ..
		"parameter in each case on the page automatically removes the article from this category. See " ..
		"[[Wiktionary:Quotations]] for information about formatting dates and quotations.",
	},
	{
		regex = "^Requests for date/(.+)$",
		description = "{{rfd|section=Category:Requests for date by source}}Requests for a date for a quotation or quotations from {{{1}}}.",
		parents = {{name = "Requests for date by source", sort = "{{{1}}}"}},
		breadcrumb = "{{{1}}}",
		nolang = true,
		template_name = "rfdatek",
		template_sample_call = "{{rfdatek|LANGCODE|{{{1}}}}}",
		template_example_output = "\n(where LANGCODE is the language code of the entry)\n\nIt results in the message below:\n\n{{rfdatek|und|{{{1}}}}}",
	},
	{
		regex = "^Requests for attestation of (.+) terms$",
		umbrella = "Requests for attestation of terms by language",
		breadcrumb = "Attestation",
		additional_template_description = "The {{tl|LDL}} template adds this category when a language code is supplied in {{para|1}} (as it should be)."
	},
}

local user_competency_additional_template_description = "This is added by user-competency categories such as " ..
	"[[:Category:User fr-4]], which groups users who speak French at level 4 (near-native proficiency), when " ..
	"the native-language text indicating this fact is missing. The appropriate translation should mirror the " ..
	"English text also displayed (e.g. in this case \"These users speak French at a '''near native''' " ..
	"level.\"), and should be supplied to {{tl|auto cat}} using the {{para|text}} parameter. The mention of the " ..
	"language in the text should be surrounded by double angle brackets, e.g. \"&lt;&lt;français>>\", which " ..
	"causes it to be automatically linked to the appropriate parent category."
local user_competency_parents = {{name = "Requests for translations in user-competency categories by number of users",
	sort = function(items)
		return " " .. ("%010d"):format(items["1"])
	end,
}}

table.insert(requests_categories,
	{
		regex = "^Requests for translations in user%-competency categories with ([0-9]+)%-([0-9]+) users$",
		description = "Requests for translation of phrases indicating user competencies for specific languages and specific competency levels, for categories with {{{1}}}-{{{2}}} users.",
		additional_template_description = user_competency_additional_template_description,
		parents = user_competency_parents,
		breadcrumb = "{{{1}}}-{{{2}}}",
		nolang = true,
	}
)
table.insert(requests_categories,
	{
		regex = "^Requests for translations in user%-competency categories with ([0-9]+) (users?)$",
		description = "Requests for translation of phrases indicating user competencies for specific languages and specific competency levels, for categories with {{{1}}} {{{2}}}.",
		additional_template_description = user_competency_additional_template_description,
		parents = user_competency_parents,
		breadcrumb = "{{{1}}}",
		nolang = true,
	}
)

table.insert(raw_handlers, function(data)
	local items

	local function init_items()
		items = {pagename = data.category}
	end

	local function expand_value(item, val)
		if type(val) == "function" then
			return expand_value(item .. " ⇒ function", val(items))
		end
			
		if not val then
			return val
		end

		if type(val) == "number" then
			val = tostring(val)
		end

		if type(val) ~= "string" then
			error(("The item '%s' on page %s is of type %s and can't be concatenated"):format(
				item, items.pagename, type(val)))
		end

		-- Replaces pseudo-template code {{{ }}} with the corresponding member of the "items" table. Has to be done
		-- recursively, since some of the items are nested:
		-- {{{template_sample_call_with_temp}}}
		--			⇓
		-- {{{{{template_name}}}|{{{language_code}}}}}
		--			⇓
		-- {{attention|en}}
		if val:find("{{{") then
			val = mw.ustring.gsub(val, "{{{([^%}%{]+)}}}", function(prop)
				local propval = items[prop]
				if not propval then
					error(("The item '%s' (expanded from property '%s' on page %s) was not found in the 'items' table"):
					format(prop, item, items.pagename))
				end
				return expand_value(item .. " ⇒ " .. prop, propval)
			end
			)
		end

		return val
	end

	local function expand_items_value(item)
		return expand_value(item, items[item])
	end

	local function convert_items_to_category_data(items)
		if not items.nolang then
			items.language_name = items.language_name or "{{{1}}}"
			items.language_name = expand_items_value("language_name")
			items.language_object = require("languages").getByCanonicalName(items.language_name, true,
				items.allow_etym_lang)
			items.language_code = items.language_object:getCode()
			items.is_etym_lang = items.language_object:hasType("etymology-only")
			if items.is_etym_lang then
				items.parent_language_object = items.language_object:getNonEtymological()
				-- Reject weird cases where etymology language has no parent.
				if not items.parent_language_object then
					return nil
				end
				items.parent_language_code = items.parent_language_object:getCode()
				items.parent_language_name = items.parent_language_object:getCanonicalName()
				-- Reject weird cases where the parent language has the same name as the child etymology language. In
				-- that case, we'll get an infinite parent-category loop. This actually happens, e.g. with Rudbari and
				-- Bashkardi.
				if items.parent_language_name == items.language_name then
					return nil
				end
			else
			end
		end

		if items.template_name then
			items.template_sample_call = items.template_sample_call or "{{{{{template_name}}}|{{{language_code}}}}}"
			items.full_text_about_the_template = "To make this request, in this specific language, use this code in the entry (see also the documentation at [[Template:{{{template_name}}}]]):\n\n<pre>{{{template_sample_call}}}</pre>"

			if items.template_example_output then
				items.full_text_about_the_template = items.full_text_about_the_template .. " " .. items.template_example_output
			else
				items.template_actual_sample_call = items.template_actual_sample_call or items.template_sample_call
				items.full_text_about_the_template = items.full_text_about_the_template .. "\nIt results in the message below:\n\n{{{template_actual_sample_call}}}"
			end
			if items.additional_template_description then
				items.full_text_about_the_template = items.full_text_about_the_template .. "\n\n" .. items.additional_template_description
			end
		else
			items.full_text_about_the_template = items.additional_template_description
		end

		local parents, breadcrumb
		if items.is_etym_lang then
			parents = items.etym_parents
			breadcrumb = expand_items_value("etym_breadcrumb") or items.language_name
		else
			parents = items.parents
			breadcrumb = expand_items_value("breadcrumb")
		end

		if parents then
			for _, parent in ipairs(parents) do
				parent.name = expand_value("parent.name", parent.name)
				parent.sort = expand_value("parent.sort", parent.sort)
			end
		else
			local umbrella_type = items.pagename:match("^Requests for (.+) by language$")
			if umbrella_type then
				breadcrumb = breadcrumb or umbrella_type
				parents = {{name = "Request subcategories by language", sort = umbrella_type}}
			elseif not items.language_name then
				error("Internal error: Don't know how to compute parents for non-language-specific category '" .. items.pagename .. "'")
			else
				local requests_concerning_breadcrumb =
					items.pagename:match("^Requests for (.+) in .*$") or items.pagename:match("^Requests for (.+)$")
				local requests_concerning_parent =
					{name = "Requests concerning " .. items.language_name, sort = requests_concerning_breadcrumb}
				if items.is_etym_lang then
					local patutil = require("pattern utilities")
					local parent_lang_cat = items.pagename:gsub(patutil.pattern_escape(items.language_name),
						patutil.replacement_escape(items.parent_language_name))
					parents = {
						{name = parent_lang_cat, sort = items.language_name},
						requests_concerning_parent
					}
				else
					breadcrumb = breadcrumb or requests_concerning_breadcrumb
					parents = {requests_concerning_parent}
				end
			end
		end

		if not items.nolang and not items.is_etym_lang and items.umbrella ~= false then
			table.insert(parents, {name = expand_items_value("umbrella"), sort = items.language_name})
		end

		local additional = expand_items_value("full_text_about_the_template")
		if items.pagename:find(" by language$") then
			additional = "{{{umbrella_msg}}}" .. (additional and "\n\n" .. additional or "")
		end

		return {
			description = expand_items_value("description") or items.pagename .. ".",
			lang = items.parent_language_code or items.language_code,
			additional = additional,
			parents = parents,
			-- If no breadcrumb= and not an etym-only language, it will default to the category name
			breadcrumb = breadcrumb,
			catfix = expand_items_value("catfix"),
			toc_template = expand_items_value("toc_template"),
			toc_template_full = expand_items_value("toc_template_full"),
			hidden = not items.not_hidden_category,
			can_be_empty = true,
		}
	end

	-- First look for a regular (usually language or script-specific) category.
	for i, category in ipairs(requests_categories) do
		local matchvals = {mw.ustring.match(data.category, category.regex)}
		if #matchvals > 0 then
			init_items()
			for key, value in pairs(category) do
				items[key] = value
			end
			for key, value in ipairs(matchvals) do
				items["" .. key] = value
			end
			local catdata = convert_items_to_category_data(items)
			if catdata then
				return catdata
			end
		end
	end

	-- Now look for umbrella categories.
	for i, category in ipairs(requests_categories) do
		if data.category == category.umbrella then
			init_items()
			items.nolang = true
			local catdata = convert_items_to_category_data(items)
			if catdata then
				return catdata
			end
		end
	end

	return nil
end)


local recognized_taxtypes = require("table/listToSet") {
  "ambiguous",
  "binomial",
  "branch",
  "clade",
  "cladus",
  "class",
  "cohort",
  "convariety",
  "cultivar group",
  "cultivar",
  "division",
  "empire",
  "epifamily",
  "epithet",
  "family",
  "form taxon",
  "form",
  "genus",
  "grade",
  "grandorder",
  "group",
  "hybrid",
  "informal group",
  "infraclass",
  "infracohort",
  "infrakingdom",
  "infraorder",
  "infraphylum",
  "infraspecies",
  "kingdom",
  "magnorder",
  "megacohort",
  "mirorder",
  "morph",
  "nothogenus",
  "nothospecies",
  "nothosubspecies",
  "nothovariety",
  "obsolete",
  "oofamily",
  "order",
  "parvclass",
  "parvorder",
  "phylum",
  "section",
  "series",
  "serovar",
  "species group",
  "species",
  "stem",
  "strain",
  "subclass",
  "subcohort",
  "subdivision",
  "subfamily",
  "subgenus",
  "subgroup",
  "subinfraorder",
  "subkingdom",
  "suborder",
  "subphylum",
  "subsection",
  "subspecies",
  "subterclass",
  "subtribe",
  "superclass",
  "supercohort",
  "superfamily",
  "supergroup",
  "superorder",
  "superphylum",
  "supertribe",
  "taxon",
  "tribe",
  "trinomial",
  "undescribed species",
  "unknown",
  "unranked group",
  "variety",
  "virus complex",
}

table.insert(raw_handlers, function(data)
	local taxtype = data.category:match("^Entries using missing taxonomic name %((.*)%)$")
	if taxtype and recognized_taxtypes[taxtype] then
		return {
			description = "Entries that link to wikispecies because there is no corresponding Wiktionary entry for the taxonomic name in the template {{tl|taxlink}}.",
			additional = "The missing name is one or more of those enclosed in {{tl|taxlink}}. The entries are sorted by the missing taxonomic name.",
			parents = {{name = "Entries using missing taxonomic names", sort = taxtype}},
			breadcrumb = taxtype,
			hidden = true,
		}
	end
end)

return {LABELS = labels, RAW_CATEGORIES = raw_categories, RAW_HANDLERS = raw_handlers}