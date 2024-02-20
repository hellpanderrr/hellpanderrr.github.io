<div style="float: right; width: 22em; margin: 0 0 1em 0.5em; border: 1px solid darkgray; padding: 0.5em;>
<inputbox>
type=fulltext
prefix=Module:category tree/poscatboiler/data
searchbuttonlabel=Search this module and its submodules
</inputbox>
</div>
==Introduction==
This is the documentation page for the [[Module:category tree/poscatboiler/data|main data module]] for [[Module:category tree/poscatboiler]], as well as for its submodules. Collectively, these modules handle generating the descriptions and categorization for almost all category pages. The only current exception is topic pages such as [[:Category:en:Birds]] and [[:Category:zh:State capitals of Germany]], and the corresponding non-language-specific pages such as [[:Category:Birds]] and [[:Category:State capitals of Germany]]; these are handled by [[Module:category tree/topic cat]].

Originally, there were a large number of [[Module:category tree]] implementations, of which [[Module:category tree/poscatboiler]] was only one. It originally handled part-of-speech categories like [[:Category:French nouns]] and [[:Category:German lemmas]] (and corresponding "umbrella" categories such as [[:Category:Nouns by language]] and [[:Category:Lemmas by language]]); hence the name. However, it has long since been generalized, and the name no longer describes its current use.

The main data module at [[Module:category tree/poscatboiler/data]] does not contain data itself, but rather imports the data from its submodules, and applies some post-processing.

* To find which submodule implements a specific category, use the search box on the right.
* To add a new data submodule, copy an existing submodule and modify its contents. Then, add its name to the <code>subpages</code> list at the top of [[Module:category tree/poscatboiler/data]].

{{maintenance box|yellow<!--
-->| title = The text of any category page using this module should simply read <code><nowiki>{{auto cat}}</nowiki></code>.<!--
-->| image = [[File:Text-x-generic with pencil.svg|40px]]<!--
-->| text = The correct way to invoke [[Module:category tree/poscatboiler]] on a given category page that it handles is through {{temp|auto cat}}. You should not normally invoke {{temp|poscatboiler}} directly. If you find a category page that directly invokes {{temp|poscatboiler}}, it is probably old, from before when {{temp|auto cat}} was created, and should be changed.<!--
-->}}

==Concepts==
The poscatboiler system internally distinguishes the following types of categories:
# '''Language categories'''. These are of the form <code>''LANG'' ''LABEL''</code> (e.g. [[:Category:French lemmas]] and [[:Category:English learned borrowings from Late Latin]]). Here, <code>''LANG''</code> is the name of a language, and <code>''LABEL''</code> can be anything, but should generally describe a topic that can apply to multiple languages. Note that the language mentioned by <code>''LANG''</code> must currently be a regular language, not an etymology-only language. (Etymology-only languages include lects such as [[:Category:Provençal|Provençal]], considered a variety of [[:Category:Occitan language|Occitan]], and [[:Category:Biblical Hebrew|Biblical Hebrew]], considered a variety of [[:Category:Hebrew language|Hebrew]]. See [[WT:LOL/E|here]] for the list of such lects.) Most language categories have an associated ''umbrella category''; see below.
# '''Umbrella categories'''. These are normally of the form <code>''LABEL'' by language</code>, and group all categories with the same label. Examples are [[:Category:Lemmas by language]] and [[:Category:Learned borrowings from Late Latin by language]]. Note that the label appears with an initial lowercase letter in a language category, but with an initial uppercase letter in an umbrella category, consistent with the general principle that category names are capitalized. Umbrella categories themselves are grouped into '''umbrella metacategories''', which group related umbrella categories under a given high-level topic. Examples are [[:Category:Lemmas subcategories by language]] (which groups umbrella categories describing different types of lemmas, such as [[:Category:Nouns by language]] and [[:Category:Interrogative adverbs by language]]) and [[:Category:Terms derived from Proto-Indo-European roots]] (which groups umbrella categories describing terms derived from particular Proto-Indo-European roots, such as [[:Category:Terms derived from the Proto-Indo-European root *preḱ-]] and [[:Category:Terms derived from the Proto-Indo-European root *bʰeh₂- (speak)]]). The names of umbrella metacategories are not standardized (although many end in <code>subcategories by language</code>), and internally they are handled as raw categories; see below.
#* Note that umbrella categories are just a special type of parent category with built-in support in the category-handling system. In particular, some types of categories have what is logically an umbrella category but which has a nonstandard name. These are handled as just another parent category, with a separate raw-category entry for the parent itself. An example is categories of the form <code>''LANG'' phrasebook/''AREA''</code> (e.g. [[:Category:English phrasebook/Health]]), whose umbrella category has the nonstandard name <code>Phrasebooks by language/''AREA''</code> (e.g. [[:Category:Phrasebooks by language/Health]]). Another example is categories of the form <code>''LANG'' terms borrowed back into ''LANG''</code>, with a nonstandard umbrella category [[:Category:Terms borrowed back into the same language]]. Both of these examples are handled by disabling the standard umbrella category support and listing the nonstandard umbrella category as an additional parent.
#* Some umbrella categories are missing the <code>by language</code> suffix; an example is [[:Category:Terms borrowed from Latin]], which groups categories of the form <code>''LANG'' terms borrowed from Latin</code>. There is special support for umbrella categories of this nature, so they do not need to be handled as described above for umbrella categories with nonstandard names.
# '''Language-specific categories'''. These are of the same form <code>''LANG'' ''LABEL''</code> as regular language categories, but with the difference that the label in question applies only to a single language, rather than to all or a large group of languages. Examples are [[:Category:Belarusian class 4c verbs]], [[:Category:Dutch separable verbs with bloot]], and [[:Category:Japanese kanji by kan'yōon reading]]. For these categories, it does not make sense to have a corresponding umbrella category.
# '''Raw categories'''. These can have any form whatsoever, and may or may not have a language name in them. Examples are [[:Category:Requests for images in Korean entries]] and [[:Category:Terms with redundant transliterations/ru]] (which logically are language categories but do not follow the standard format of a language category); [[:Category:Phrasebooks by language/Health]] (which is logically an umbrella category, but again with a nonstandard name); [[:Category:Terms by etymology subcategories by language]] (an umbrella metacategory); and [[:Category:Templates]] (a miscellaneous high-level category).

Under the hood, the poscatboiler system distinguishes two types of implementations for categories: individual labels (or individual raw categories), and handlers. Individual labels describe a single label, such as <code>nouns</code> or <code>refractory rhymes</code>. Similarly, an individual raw category describes a single raw category. Handlers, on the other hand, describe a whole class of similar labels or raw categories, e.g. labels of the form <code>learned borrowings from ''SOURCE''</code> where <code>''SOURCE''</code> is any language or etymology language. Handlers are more powerful than individual labels, but require knowledge of Lua to implement.

==Adding, removing or modifying categories==
A sample entry is as follows (in this case, found in [[Module:category tree/poscatboiler/data/lemmas]]):

<pre>
labels["adjectives"] = {
	description = "{{{langname}}} terms that give attributes to nouns, extending their definitions.",
	parents = {"lemmas"},
	umbrella_parents = "Lemmas subcategories by language",
}
</pre>

This generates the description and categorization for all categories of the form "LANG adjectives" (e.g. [[:Category:English adjectives]] or [[:Category:Norwegian Bokmål adjectives]]), as well as for the ''umbrella category'' [[:Category:Adjectives by language]].

The meanings of these fields are as follows:
* The <code>description</code> field gives the description text that will appear when a user visits the category page. Here, <code>{{{langname}}}</code> is automatically replaced with the name of the language in question. The text in this field is also used to generate the description of the umbrella category [[:Category:Adjectives by language]], by chopping off the <code>{{{langname}}}</code> and capitalizing the next letter.
* The <code>parents</code> field gives the labels of the parent categories. For example, [[:Category:English adjectives]] will have [[:Category:English lemmas]] as its parent category, and [[:Category:Norwegian Bokmål adjectives]] will have [[:Category:Norwegian Bokmål lemmas]] as its parent category. The umbrella category [[:Category:Adjectives by language]] will automatically be added as an additional parent.
* The <code>umbrella_parents</code> field specifies the parent category of the umbrella category [[:Category:Adjectives by language]] (i.e. the ''umbrella metacategory'' which this page belongs to; see [[#Concepts]] above).

===Category label fields===
The following fields are recognized for the object describing a label:

; <code>parents</code>
: A table listing one or more parent labels of this label. This controls the parent categories that the category is contained within, as well as the chain of breadcrumbs appearing across the top of the page (see below).
:* An item in the table can be either a single string (the parent label), or a table containing (at least) the two elements <code>name</code> and <code>sort</code>. In the latter case, <code>name</code> specifies the parent label name, while the <code>sort</code> value specifies the sort key to use to sort it in that category. The default sort key is the category's label.
:* If a parent label begins with <code>Category:</code> it is interpreted as a raw category name, rather than as a label name. It can still have its own sort key as usual.
:* The first listed parent controls the category's parent breadcrumb in the chain of breadcrumbs at the top of the page. (The breadcrumb of the category itself is determined by the <code>breadcrumb</code> setting, as described below.)
; <code>description</code>
: A plain English description for the label. This should generally be no longer than one sentence. Place additional, longer explanatory text in the <code>additional=</code> field described below, and put {{temp|wikipedia}} boxes in the <code>topright=</code> field described below so that they are correctly right-aligned with the description. Template invocations and special template-like references such as <code>{{{langname}}}</code> and <code>{{{langcode}}}</code> will be expanded appropriately; see [[#Template substitutions in field values]] below.
; <code>breadcrumb</code>
: The text of the last breadcrumb that appears at the top of the category page.
:* By default, it is the same as the category label, with the first letter capitalized.
:* The value can be either a string, or a table containing two elements called <code>name</code> and <code>nocap</code>. In the latter case, <code>name</code> specifies the breadcrumb text, while <code>nocap</code> can be used to disable the automatic capitalization of the breadcrumb text that normally happens.
:* Note that the breadcrumbs collectively are the chain of links that serve as a navigation aid for the hierarchical organization of categories. For example, a category like [[:Category:French adjectives]] will have a breadcrumb chain similar to "Fundamental » All languages » French » Lemmas » Adjectives", where each breadcrumb is a link to a category at the appropriate level. The last breadcrumb here is "Adjectives", and its text is controlled by this field.
; <code>displaytitle</code>
:: Apply special formatting such as italics to the category page title, as with the <code><nowiki>{{DISPLAYTITLE:...}}</nowiki></code> magic word (see [[mw:Help:Magic words]]). The value of this is either a string (which should be the formatted category title, without the preceding <code>Category:</code>) or a Lua function to generate the formatted category title. A Lua function is most useful inside of a handler (see [[#Handlers]] below). The Lua function is passed two parameters, the raw category title (without the preceding <code>Category:</code>) and the language object of the category's language (or {{code|lua|nil}} for umbrella categories), and should return the formatted category title (again without the preceding <code>Category:</code>). If the value of this field is a string, template invocations and special template-like references such as <code>{{{langname}}}</code> and <code>{{{langcode}}}</code> will be expanded appropriately; see below. See [[Module:category tree/poscatboiler/data/terms by etymology]] and [[Module:category tree/poscatboiler/data/lang-specific/nl]] for examples of using <code>displaytitle=</code>.
; <code>topright</code>
: Introductory text to display right-aligned, before the edit and recent-entries boxes on the right side. This field should be used for {{tl|wikipedia}} and other similar boxes. Template invocations and special template-like references such as <code>{{{langname}}}</code> and <code>{{{langcode}}}</code> are expanded appropriately, just as with <code>description=</code>; see [[#Template substitutions in field values]] below. Compare the <code>preceding=</code> field, which is similar to <code>topright=</code> but used for left-aligned text placed above the description.
; <code>preceding</code>
: Introductory text to display directly before the text in the <code>description=</code> field. The difference between the two is that <code>description=</code> text will also be shown in the list of children categories shown on the parent category's page, while the <code>preceding=</code> text will not. For this reason, use <code>preceding=</code> instead of <code>description=</code> for {{tl|also}} hatnotes and similar text, and keep <code>description=</code> relatively short. Template invocations and special template-like references such as <code>{{{langname}}}</code> and <code>{{{langcode}}}</code> are expanded appropriately, just as with <code>description=</code>; see [[#Template substitutions in field values]] below. Compare the <code>topright=</code> field, which is similar to <code>preceding=</code> but is right-aligned, placed above the edit and recent-entries boxes.
; <code>additional</code>
: Additional text to display directly after the text in the the <code>description=</code> field. The difference between the two is that <code>description=</code> text will also be shown in the list of children categories shown on the parent category's page, while the <code>additional=</code> text will not. For this reason, use <code>additional=</code> instead of <code>description=</code> for long explanatory notes, ''See also'' references and the like, and keep <code>description=</code> relatively short. Template invocations and special template-like references such as <code>{{{langname}}}</code> and <code>{{{langcode}}}</code> are expanded appropriately, just as with <code>description=</code>; see [[#Template substitutions in field values]] below.
; <code>umbrella</code>
: A table describing the umbrella category that collects all language-specific categories associated with this label, or the special value <code>false</code> to indicate that there is no umbrella category. The umbrella category is normally called "LABEL by language". For example, for adjectives, the umbrella category is named [[:Category:Adjectives by language]], and is a parent category (in addition to any categories specified using <code>parents</code>) of [[:Category:English adjectives]], [[:Category:French adjectives]], [[:Category:Norwegian Bokmål adjectives]], and all other language-specific categories holding adjectives. This table contains the following fields:
:; <code>name</code>
:: The name of the umbrella category. It defaults to "LABEL by language". '''You should not use this, even if the umbrella category has a nonstandard name''', because if you set it, you will have to modify [[Module:auto cat]] to recognize the new name of the umbrella category. Instead, set <code>umbrella = false</code> and list the nonstandard umbrella category as an additional parent (and add a raw-category entry for the umbrella category itself; see the implementation of categories like [[:Category:English terms borrowed back into English]] for an example).
:; <code>description</code>
:: A plain English description for the umbrella category. By default, it is derived from the <code>description</code> field of the category itself by removing any <code>{{{langname}}}</code>, <code>{{{langcode}}}</code> or <code>{{{langcat}}}</code> template parameter reference and capitalizing the remainder. Text is automatically added to the end indicating that this category is an umbrella category that only contains other categories, and does not contain pages describing terms.
:; <code>parents</code>
:: The parent category or categories of the umbrella category. This can either be a single string specifying a category (with or without the <code>Category:</code> prefix), a table with fields <code>name</code> (the category name) and <code>sort</code> (the sort key, as in the outer <code>parents</code> field described above), or a list of either type of entity.
:; <code>breadcrumb</code>
:: The last breadcrumb in the chain of breadcrumbs at the top of the category page; see above. By default, this is the category label (i.e. the same as the umbrella category name, minus the final "by language" text).
:; <code>displaytitle</code>
:: Apply special formatting such as italics to the umbrella category page title; see above.
:; <code>topright</code>
:: Like the <code>topright=</code> field on regular category pages; see above.
:; <code>preceding</code>
:: Like the <code>preceding=</code> field on regular category pages; see above.
:; <code>additional</code>
:: Like the <code>additional=</code> field on regular category pages; see above.
:; <code>toc_template</code>, <code>toc_template_full</code>
:: Override the table of contents bar used on umbrella pages. See below. It's unlikely you will ever need to set this.
; <code>umbrella_parents</code>
: The same as the <code>parents</code> subfield of the <code>umbrella</code> field. This typically specifies a single ''umbrella metacategory'' to which the page's corresponding umbrella page belongs; see [[#Concepts]] above). A separate field is provided for this because the umbrella's parent or parents always need to be given, whereas other umbrella properties can usually be defaulted. (In practice, you will find that most entries in a subpage of [[Module:category tree/poscatboiler/data]] do not explicitly specify the umbrella's parent. This is because a default value is supplied near the end of the "LABELS" section in which the entry is found.)
; <code>toc_template</code>
: The template or templates to use to display the "table of contents" bar for easier navigation on categories with multiple pages of entries. By default, categories with more than 200 entries or 200 subcategories display a language-appropriate table of contents bar whose contents are held in a template named <code>''CODE''-categoryTOC</code>, where <code>''CODE''</code> is the language code of the category's language. (If no such template exists, no table of contents bar is displayed. If the category has no associated language, as with umbrella pages, the English-language table of contents bar is used.) For example, the category [[:Category:Spanish interjections]] (and other Spanish-language categories) use [[Template:es-categoryTOC]] to display a Spanish-appropriate table of contents bar. (In the case of Spanish, this includes entries for Ñ and for acute-accented vowels such as Á and Ó.) To override this behavior, specify a template or a list of templates in <code>toc_template</code>. The first template that exists will be used; if none of the specified templates exist, the regular behavior applies, i.e. the language-appropriate table of contents bar is selected.
:* Special strings such as <code>{{{langcode}}}</code> (to specify the language code of the category's language) can be used in the template names; see below.
:* Use the special value <code>false</code> to disable the table of contents bar.
:* An example of a category that uses this property is "LANG romanizations". For example, the category [[:Category:Gothic romanizations]] would by default use the Gothic-specific template [[Template:got-categoryTOC]] to display a Gothic-script table of contents bar. This is inappropriate for this particular category, which contains Latin-script romanizations of Gothic terms rather than terms written in the Gothic script. To fix this, the "romanizations" label specifies a <code>toc_template</code> value of {{code|lua|{"{{{langcode}}}-rom-categoryTOC", "en-categoryTOC"}}}, which first checks for a special Gothic-romanization-specific template [[Template:got-rom-categoryTOC]] (which in this case does exist), and falls back to the English-language table of contents template.
; <code>toc_template_full</code>
: Similar to <code>toc_template</code> but used for categories with large numbers of entries (specifically, more than 2,500 entries or 2,500 subcategories). If none of the specified templates exist, the templates listed in <code>toc_template</code> are tried, and if none of them exist either, the default behavior applies. In this case, the default behavior is to use a language-appropriate "full" table of contents template named <code>''CODE''-categoryTOC/full</code>, and if that doesn't exist, fall back to the regular table of contents template named <code>''CODE''-categoryTOC</code>. An example of a "full" table of contents template is [[Template:es-categoryTOC/full]], which shows links for all two-letter combinations and appears on pages such as [[:Category:Spanish nouns]], with over 50,000 entries.
; <code>catfix</code>
: Specifies the language code of the language to use when calling the {{code|lua|catfix()}} function in [[Module:utilities]] on this page. The {{code|lua|catfix()}} function is used to ensure that page names in foreign scripts show up in the correct fonts and are linked to the correct language.
:* The default value is the category's language, if any (for example, the language <code>''LANG''</code> in pages of the form <code>''LANG'' ''LABEL''</code>). If the category has no associated language, or if the setting <code>catfix = false</code> is used, the catfix mechanism is not applied.
:* The setting <code>catfix = false</code> is used, for example, on the <code>romanizations</code> label (which holds Latin-script romanizations of foreign-script terms, rather than terms in the language's native script) and the <code>redlinks</code> labels (which holds pages ''linking'' to nonexistent terms in the language in question). If this is omitted, for example, then pages in [[:Category:Manchu romanizations]] will show up oriented vertically despite being in Latin script, and pages in [[:Category:Cantonese redlinks]] will show up using a double-width font despite mostly not being Cantonese-language pages.
:* The setting <code>catfix = "en"</code> is used for example on categories of the form <code>Requests for translations into ''LANG''</code> (see [[Module:category tree/poscatboiler/data/entry maintenance]]) because these categories contain English pages need translations ''into'' a given language, rather than containing pages ''of'' that language.
:* Note that setting a particular language for <code>catfix=</code> will normally cause that language's table of contents page to display in place of the category's normal language, and setting a value of <code>false</code> will normally cause the English table of contents page to display. In both cases, this behavior can be overridden by specifying the <code>toc_template=</code> or <code>toc_template_full=</code> fields.
; {{para|hidden | true}}
: Specifies that the category is hidden. This should be used for maintenance categories. (Hidden categories do not show up in the list of categories at the bottom of a page, but do show up when searched for in the search box.)
; {{para|can_be_empty | true}}
: Specifies that the category should not be deleted when empty. This should be used for maintenance categories.

===Template substitutions in field values===
Template invocations can be inserted in the text of <code>description</code>, <code>parents</code> (both name and sort key), <code>breadcrumb</code>, <code>toc_template</code> and <code>toc_template_full</code> values, and will be expanded appropriately. In addition, the following special template-like invocations are recognized and replaced by the equivalent text:
; <code><nowiki>{{PAGENAME}}</nowiki></code>
: The name of the current page. (Note that two braces are used here instead of three, as with the other parameters described below.)
; <code>{{{langname}}}</code>
: The name of the language that the category belongs to. Not recognized in umbrella fields.
; <code>{{{langcode}}}</code>
: The code of the language that the category belongs to (e.g. <code>en</code> for English, <code>de</code> for German). Not recognized in umbrella fields.
; <code>{{{langcat}}}</code>
: The name of the language's main category, which adds "language" to the regular name. Not recognized in umbrella fields.

===Raw categories===
Raw categories are treated similarly to regular labels. The main differences are:


==Handlers==
It is also possible to have handlers that can handle arbitrarily-formed labels, e.g. "###-syllable words" for any ###; "terms in XXX script" for any XXX; or "learned borrowings from LANG" for any LANG. As an example, the following is the handler for "terms coined by COINER" (such as [[:Category:English terms coined by Lewis Carroll]]):

<pre>
table.insert(handlers, function(data)
	local coiner = data.label:match("^terms coined by (.+)$")
	if coiner then
		return {
			description = "{{{langname}}} terms coined by " .. coiner .. ".",
			breadcrumb = coiner,
			umbrella = false,
			parents = {{
				name = "coinages",
				sort = coiner,
			}},
		}
	end
end)
</pre>

The handler checks if the passed-in label has a recognized form, and if so, returns an object that follows the same format as described above for directly-specified labels. In this case, the handler disables the umbrella category "Terms coined by COINER by language" because most people coin words in only one language.

The handler is passed a single argument <code>data</code>, which is an object containing the following fields:
# <code>label</code>: the label;
# <code>lang</code>: the language object of the language at the beginning of the category, or <code>nil</code> for no language (this happens with umbrella categories);
# <code>sc</code>: the script code of the script mentioned in the category, if the category is of the form "LANG LABEL in SCRIPT", or <code>nil</code> otherwise;
# <code>args</code>: a table of extra parameters passed to {{temp|auto cat}}.

If the handler interprets the extra parameters passed as <code>data.args</code>, it should return two values: a label object (as described above), and the value <code>true</code>. Otherwise, an error will be thrown if any extra parameters are passed to {{temp|auto cat}}. An example of a handler that interprets the extra parameters is the affix-cat handler in [[Module:category tree/poscatboiler/data/terms by etymology]], which supports {{temp|auto cat}} parameters {{para|alt}}, {{para|sort}}, {{para|tr}} and {{para|sc}}. The {{para|alt}} parameter in particular is used to specify extra diacritics to display on the affix that forms part of the category name, as in categories such as [[:Category:Latin terms suffixed with -inus]] (properly {{m|la|-īnus}}).

For further examples, see [[Module:category tree/poscatboiler/data/terms by lexical property]], [[Module:category tree/poscatboiler/data/terms by script]] or [[Module:category tree/poscatboiler/data/terms by etymology]].

Note that if a handler is specified, the module should return a table holding both the label and handler data; see the above modules.

==Language-specific labels==
Support exists for labels that are specialized to particular languages. A typical label such as "verbs" applies to many languages, but some categories have labels that are specialized to a particular language, e.g. [[:Category:Belarusian class 4c verbs]] or [[:Category:Dutch prefixed verbs with ver-]]. Here, the label "class 4c verbs" is specific to Belarusian with a description and other properties only for this particular language, and similarly for the Dutch-specific label "prefixed verbs with ver-". Yet, it is desirable to integrate these categories into the poscatboiler hierarchy, so that e.g. breadcrumbs and other features are available. This can be done by creating a module such as [[Module:category tree/poscatboiler/data/lang-specific/be]] (for Belarusian) or [[Module:category tree/poscatboiler/data/lang-specific/nl]] (for Dutch), and specifying labels and/or handlers in the same fashion as is done for language-agnostic categories. See [[Module:category tree/poscatboiler/data/lang-specific/documentation]] for more information.

==Subpages==
{{subpages|Module:category_tree/poscatboiler/data}}

<includeonly>
[[Category:Category tree data modules/poscatboiler| ]]
</includeonly>