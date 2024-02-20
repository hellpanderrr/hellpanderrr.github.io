local labels = {}
local raw_categories = {}
local handlers = {}



-----------------------------------------------------------------------------
--                                                                         --
--                                  LABELS                                 --
--                                                                         --
-----------------------------------------------------------------------------

labels["terms by script"] = {
	description = "{{{langname}}} terms categorized by the script they are written in (for languages with multiple native scripts).",
	umbrella_parents = "Terms by lexical property subcategories by language",
	parents = {"terms by orthographic property"},
}



-----------------------------------------------------------------------------
--                                                                         --
--                              RAW CATEGORIES                             --
--                                                                         --
-----------------------------------------------------------------------------


raw_categories["Terms by script subcategories by language"] = {
	description = "Umbrella categories covering topics related to terms categorized by their script.",
	additional = "{{{umbrella_meta_msg}}}",
	parents = {
		"Umbrella metacategories",
		{name = "terms by script", is_label = true, sort = " "},
	},
}



-----------------------------------------------------------------------------
--                                                                         --
--                                 HANDLERS                                --
--                                                                         --
-----------------------------------------------------------------------------


table.insert(handlers, function(data)
	local script = data.label:match("^terms in (.+) script$")
	if script then
		return {
			description = "{{{langname}}} terms written in " .. script .. " script.",
			umbrella_parents = "Terms by script subcategories by language",
			parents = {{
				name = "terms by script",
				sort = script,
			}},
		}
	end
end)


return {LABELS = labels, RAW_CATEGORIES = raw_categories, HANDLERS = handlers}