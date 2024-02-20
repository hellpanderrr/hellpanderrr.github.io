local labels = {}

local irregular_plurals = require("form of/lang-data/en/functions").irregular_plurals

-- Add irregular plural categories.
labels["irregular plurals"] = {
	description = "{{{langname}}} irregular noun plurals.",
	additional = "The criteria for inclusion and singular forms can be found in [[:Category:English nouns with irregular plurals]].",
	parents = {{name = "noun forms", sort = "*"}},
}

labels["miscellaneous irregular plurals"] = {
	description = "{{{langname}}} irregular noun plurals that do not fall into one of the most common irregular plural categories (e.g. [[:Category:English plurals in -ae with singular in -a|Category:English plurals in ''-ae'' with singular in ''-a'']] or [[:Category:English plurals in -men with singular in -man|Category:English plurals in ''-men'' with singular in ''-man'']]).",
	additional = "This mostly includes nouns whose plurals originate from a language other than Greek, Latin, Italian or French, or native irregular plurals such as {{m|en|dice}} (plural of {{m|en|die}}).",
	parents = "irregular plurals",
}

for _, irreg_plural in ipairs(irregular_plurals) do
	local description
	if irreg_plural.description then
		description = irreg_plural.description
	else
		description = irreg_plural.cat
		if irreg_plural.desc_suffix then
			description = description .. irreg_plural.desc_suffix
		end
		description = "English " .. description .. "."
	end

	local function replace_angle_brackets(text)
		return (text:gsub("<<(.-)>>", "{{m|en||%1}}")) -- discard second retval
	end
	local function replace_angle_brackets_plain(text)
		return (text:gsub("<<(.-)>>", "%1")) -- discard second retval
	end

	local cat = replace_angle_brackets_plain(irreg_plural.cat)
	local breadcrumb = irreg_plural.breadcrumb or irreg_plural.cat:gsub("^plurals in ", "")

	local displaytitle = replace_angle_brackets("English " .. irreg_plural.cat)
	local sort = irreg_plural.sort_key or replace_angle_brackets_plain(breadcrumb):gsub("^%-", "")
	breadcrumb = replace_angle_brackets(breadcrumb)
	description = replace_angle_brackets(description)
	local additional
	if irreg_plural.additional then
		additional = replace_angle_brackets(irreg_plural.additional)
	end
	labels[cat] = {
		description = description,
		additional = additional,
		displaytitle = displaytitle,
		breadcrumb = breadcrumb,
		parents = {{name = "irregular plurals", sort = sort}},
	}
end


labels["terms with early reduction of Middle English /iu̯r(ə)/"] = {
	description = "In Modern English, {{IPAchar|/jə(ɹ)/}} ({{IPAchar|/t͡ʃə(ɹ)/|/d͡ʒə(ɹ)/|/ʃə(ɹ)/|/ʒə(ɹ)/}} after historic {{IPAchar|/t/|/d/|/s/|/z/}}) is the usual reflex of unstressed Middle English {{IPAchar|/iu̯r(ə)/}}. However, in the late Middle English vernacular, there was a tendency to reduce this sound to {{IPAchar|/ir/|/ur/}}, which regularly developed to modern {{IPAchar|/ə(ɹ)/}} instead of {{IPAchar|/jə(ɹ)/}}, While forms reflecting this tendency were adopted in the standard language for some words (e.g. {{m|en|fritter}}), in others such forms were eventually relegated to nonstandard speech before becoming extinct (e.g. {{m|en|nater}} for {{m|en|nature}}).",
	parents = {"terms by phonemic property"},
}

labels["terms with /ɛ/ for Old English /y/"] = {
	description = "In [[w:Old English dialects|Kentish]] Old English, historic {{IPAchar|/y/}} became {{IPAchar|/e/}}, which regularly developed to modern {{IPAchar|/ɛ/}}. Even in Kent, these forms have been mostly replaced by those showing the usual [[w:Old English dialects|Anglian]] development to modern {{IPAchar|/ɪ/}}, but a few survive, whether in the standard language or dialectally. Note that before {{IPAchar|/ɹ/}} then a consonant, this sound has developed further to {{IPAchar|/ɜː(ɹ)/}}. Additionally, terms which never had {{IPAchar|/y/}} in the variety of Old English they come from should not be included in this category (an example is {{m|en|elder|t=senior}}, which comes from Anglian {{m|ang|eldra}}, not West Saxon {{m|ang|ieldra}}, {{m|ang|yldra}}).",
	parents = {"terms by phonemic property"},
}

labels["terms with /ʌ~ʊ/ for Old English /y/"] = {
	description = "In Southwestern Middle English, Old English {{IPAchar|/y/}} became {{IPAchar|/u/}}, which regularly developed to modern {{IPAchar|/ɛ/}}. Even in Southwestern England, these forms have been mostly replaced by those showing the usual Midland development to modern {{IPAchar|/ʌ~ʊ/|/aʊ/}}, but some survive, whether in the standard language or dialectally, especially in the vicinity of a following {{IPAchar|/ɹ/}} or postalveolar consonant.  Note that before {{IPAchar|/ɹ/}} then a consonant, this sound has developed further to {{IPAchar|/ɜː(ɹ)/}}.",
	parents = {"terms by phonemic property"},
}

labels["terms with /i/ for expected final /ə/"] = {
	description = "In [[rhotic]] dialects of English, final {{IPAchar|/ə/}} generally does not appear in native vocabulary; as a result, some rhotic or historically-rhotic dialects tended to use word-final {{IPAchar|/i/}} where {{IPAchar|/ə/}} occurs in the standard language. Due to the influence of the standard language and other dialects, this feature is nearly extinct, though it has been adopted in the stanard language in {{m|en|nary}} (from {{m|en|ne'er}} {{m|en|a}}).",
	parents = {"terms by phonemic property"},
}

labels["terms with assimilation of historic /ɹ/"] = {
	description = "Begininning in the Middle English period, a tendency developed for {{IPAchar|/ɹ/}} to be assimilated before coronal consonants, especially {{IPAchar|/s/}}; this is distinct from later non-[[rhoticity]]. While forms reflecting this tendency have been adopted for some words in the standard language (such as {{m|en|bass|id=fish|t=fish}} ← {{m+|ang|bærs}}), others survive only dialectally or informally (e.g. {{m|en|hoss}}, {{m|en|passel}}).",
	parents = {"terms by phonemic property"},
}

labels["terms with dissimilation of historic /ɹ/"] = {
	description = "Begininning in the Middle English period, a tendency developed for {{IPAchar|/ɹ/}} to be lost in words when another {{IPAchar|/ɹ/}} occured. While forms reflecting this tendency have been adopted for some words in the standard language, others survive only dialectally or informally (e.g. {{m|en|catridge}}).",
	parents = {"terms by phonemic property"},
}

labels["terms with unetymological /ɹ/"] = {
	description = "Many English words have acquired an unetymological {{IPAchar|/ɹ/}}, either due to either purely phonetic processes or various kinds of {{glossary|hypercorrection}} (of non-rhoticity, the [[:Category:English terms with assimilation of historic /ɹ/|assimilation of {{IPAchar|/ɹ/}} before coronals]], or [[:Category:English terms with dissimilation of historic /ɹ/|dissimilation of {{IPAchar|/ɹ/}}]]). While forms reflecting this tendency have been adopted in the standard language (e.g. {{m|en|parsnip}}), others survive only dialectally or informally (e.g. {{m|en|warsh}}).",
	parents = {"hypercorrections"},
}

labels["terms with unexpected final devoicing"] = {
	description = "In prehistoric Old English, final fricatives were {{w|final-obstruent devoicing|devoiced}}; compare {{m+|ang|līf}} to {{m+|goh|līb|t=life}}. In standard English, this process did not affect {{glossary|plosive|plosives}} (e.g. {{m|en|road}}) or secondary word-final fricatives (e.g. {{m|en|love}}), but some dialects devoiced these consonants, especially when unstressed (this was particularly common in Middle English). No modern variety universally has this devoicing, but some devoiced forms survive dialectally (e.g. {{m|en|anythink}}) or have been adopted in the standard language (most notably in the past tense of some irregular verbs, such as {{m|en|sent}}, aided by analogy with e.g. {{m|en|kept}}).",
	parents = {"terms by phonemic property"},
}

return {LABELS = labels}