<div style="float: right; width: 22em; margin: 0 0 1em 0.5em; border: 1px solid darkgray; padding: 0.5em;>
<inputbox>
type=fulltext
prefix=Module:category tree/poscatboiler/data/lang-specific
searchbuttonlabel=Search this module and its submodules
</inputbox>
</div>
This is the documentation page for the [[Module:category tree/poscatboiler/data|main language-specific data module]] for [[Module:category tree/poscatboiler]], as well as for its submodules. Collectively, these modules handle generating the descriptions and categorization for language-specific category pages of the format "LANG LABEL" (e.g. [[:Category:Bulgarian conjugation 2.1 verbs]] and [[:Category:Russian velar-stem neuter-form nouns]]). "Language-specific" means that the category labels (in these examples, "conjugation 2.1 verbs" and "velar-stem neuter-form nouns") are specialized to apply only to particular languages, unlike a category such as [[:Category:Bulgarian verbs]] or [[:Category:Russian nouns]], where the labels "verbs" and "nouns" apply to all languages.

To understand how these data modules work, you should first familiarize yourself with how poscatboiler labels and handlers work in general. See [[Module:category tree/poscatboiler/data/documentation]] for information on this.

Language-specific labels and handlers work almost identically to non-language-specific labels and handlers. Labels have the same fields, and handlers are called with the same arguments and should return the same types of objects. The only real difference is that language-specific categories don't normally have corresponding umbrella categories, so there is no need to set the <code>umbrella</code> or <code>umbrella_parents</code> fields.

The language-specific module for a given language should be named <code>Module:category tree/poscatboiler/data/lang-specific/''LANGCODE''</code> where ''LANGCODE'' is the language code for the language in question, e.g. [[Module:category tree/poscatboiler/data/lang-specific/bg]] for Bulgarian. To add a new data submodule, copy an existing submodule and modify its contents. Then, add its language code to the <code>langs_with_modules</code> list at the top of [[Module:category tree/poscatboiler/data/lang-specific]]. Note that the module for a given language is only loaded when a category referencing that particular language is encountered and the category's label is unrecognized.

{{maintenance box|yellow<!--
-->| title = The text of any category page using this module should simply read <code><nowiki>{{auto cat}}</nowiki></code>.<!--
-->| image = [[File:Text-x-generic with pencil.svg|40px]]<!--
-->| text = The correct way to invoke this module on a given category page that it handles is through {{temp|auto cat}}. You should not normally invoke {{temp|poscatboiler}} directly. If you find a category page that directly invokes {{temp|poscatboiler}}, it is probably old, from before when {{temp|auto cat}} was created, and should be changed.<!--
-->}}

==Adding, removing or modifying categories==
A sample entry is as follows (in this case, found in [[Module:category tree/poscatboiler/data/lang-specific/be]]):

<pre>
labels["verbs by class and accent pattern"] = {
	description = "Belarusian verbs categorized by class and accent pattern.",
	parents = {{name = "verbs by inflection type", sort = "class and accent pattern"}},
}

</pre>

See [[Module:category tree/poscatboiler/data/documentation]] for more information.

==Handlers==
A sample handler follows (in this case for Belarusian categories of the form [[:Category:Belarusian class 2 verbs]] or [[:Category:Belarusian class 4c verbs]]):

<pre>
table.insert(handlers, function(data)
	local cls, pattern = data.label:match("^class ([0-9]*)([abc]?) verbs")
	if cls then
		if pattern == "" then
			return {
				description = "{{{langname}}} class " .. cls .. " verbs.",
				breadcrumb = cls,
				parents = {{name = "verbs by class", sort = cls}},
			}
		else
			return {
				description = "{{{langname}}} class " .. cls .. " verbs of " ..
					"accent pattern " .. pattern .. ". " .. (
					pattern == "a" and "With this pattern, all forms are stem-stressed."
					or pattern == "b" and "With this pattern, all forms are ending-stressed."
					or "With this pattern, the first singular present indicative and all forms " ..
					"outside of the present indicative are ending-stressed, while the remaining " ..
					"forms of the present indicative are stem-stressed."
				),
				breadcrumb = cls .. pattern,
				parents = {
					{name = "class " .. cls .. " verbs", sort = pattern},
					{name = "verbs by class and accent pattern", sort = cls .. pattern},
				},
			}
		end
	end
end)
</pre>

Another example, for categories like [[:Category:Dutch prefixed verbs with ver-]]:

<pre>
table.insert(handlers, function(data)
	local pref = data.label:match("^prefixed verbs with (.+%-)$")
	if pref then
		return {
			description = "{{{langname}}} prefixed verbs with the prefix {{m|nl|" .. link .. "}}.",
			displaytitle = "{{{langname}}} prefixed verbs with {{m|nl||" .. altlink .. "}}",
			breadcrumb = "{{m|nl||" .. altlink .. "}}",
			parents = {{name = "prefixed verbs", sort = pref}},
		}
	end
end)
</pre>

Here, we use <code>displaytitle=</code> to italicize the prefix in the title (and also italicize it in the breadcrumb and description). Note the use of the {{para|3}} (alternative display form) parameter in the displaytitle and breadcrumb to avoid creating a link; this will cause an error in the displaytitle, and lead to a poor user experience in the breadcrumb.

See [[Module:category tree/poscatboiler/data/documentation]] for more information.

==Subpages==
{{subpages|Module:category_tree/poscatboiler/data/lang-specific}}

<includeonly>
[[Category:Category tree data modules/poscatboiler| ]]
</includeonly>