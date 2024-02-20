local labels = {}
local raw_categories = {}
local handlers = {}
local raw_handlers = {}

local subpages = {
	"affixes and compounds",
	"characters",
	"entry maintenance",
	"families",
	"figures of speech",
	"language varieties",
	"languages",
	"lemmas",
	"miscellaneous",
	"modules",
	"names",
	"non-lemma forms",
	"phrases",
	"rhymes",
	"scripts",
	"shortenings",
	"symbols",
	"templates",
	"terms by etymology",
	"terms by grammatical category",
	"terms by lexical property",
	"terms by semantic function",
	"terms by script",
	"terms by usage",
	"transliterations",
	"unicode",
	"wiktionary",
	"wiktionary maintenance",
	"word of the day",
}

-- Import subpages
for _, subpage in ipairs(subpages) do
	local datamodule = "Module:category tree/poscatboiler/data/" .. subpage
	local retval = require(datamodule)
	if retval["LABELS"] then
		for label, data in pairs(retval["LABELS"]) do
			if labels[label] and not retval["IGNOREDUP"] then
				error("Label " .. label .. " defined in both [["
					.. datamodule .. "]] and [[" .. labels[label].module .. "]].")
			end
			data.module = datamodule
			labels[label] = data
		end
	end
	if retval["RAW_CATEGORIES"] then
		for category, data in pairs(retval["RAW_CATEGORIES"]) do
			if raw_categories[category] and not retval["IGNOREDUP"] then
				error("Raw category " .. category .. " defined in both [["
					.. datamodule .. "]] and [[" .. raw_categories[category].module .. "]].")
			end
			data.module = datamodule
			raw_categories[category] = data
		end
	end
	if retval["HANDLERS"] then
		for _, handler in ipairs(retval["HANDLERS"]) do
			table.insert(handlers, { module = datamodule, handler = handler })
		end
	end
	if retval["RAW_HANDLERS"] then
		for _, handler in ipairs(retval["RAW_HANDLERS"]) do
			table.insert(raw_handlers, { module = datamodule, handler = handler })
		end
	end
end

-- Add child categories to their parents
local function add_children_to_parents(hierarchy, raw)
	for key, data in pairs(hierarchy) do
		local parents = data.parents
		if parents then
			if type(parents) ~= "table" then
				parents = {parents}
			end
			if parents.name or parents.module then
				parents = {parents}
			end
			for _, parent in ipairs(parents) do
				if type(parent) ~= "table" or not parent.name and not parent.module then
					parent = {name = parent}
				end
				if parent.name and not parent.module and type(parent.name) == "string" and not parent.name:find("^Category:") then
					local parent_is_raw
					if raw then
						parent_is_raw = not parent.is_label
					else
						parent_is_raw = parent.raw
					end
					-- Don't do anything if the child is raw and the parent is lang-specific,
					-- otherwise e.g. "Lemmas subcategories by language" will be listed as a
					-- child of every "LANG lemmas" category.
					-- FIXME: We need to rethink this mechanism.
					if not raw or parent_is_raw then
						local child_hierarchy = parent_is_raw and raw_categories or labels
						if child_hierarchy[parent.name] then
							local child = {name = key, sort = parent.sort, raw = raw}
							if child_hierarchy[parent.name].children then
								table.insert(child_hierarchy[parent.name].children, child)
							else
								child_hierarchy[parent.name].children = {child}
							end
						end
					end
				end
			end
		end
	end
end

add_children_to_parents(labels)
add_children_to_parents(raw_categories, true)

return {
	LABELS = labels, RAW_CATEGORIES = raw_categories,
	HANDLERS = handlers, RAW_HANDLERS = raw_handlers
}