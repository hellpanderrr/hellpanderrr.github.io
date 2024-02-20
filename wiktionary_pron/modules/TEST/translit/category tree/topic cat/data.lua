local labels = {}
local handlers = {}

local top_level_data_module = "Module:category tree/topic cat/data"
local data_module_prefix = top_level_data_module .. "/"

local subpages = {
	"Body",
	"Buildings and structures",
	"Communication",
	"Culture",
	"Earth",
	"Food and drink",
	"Games",
	"History",
	"Human",
	"Lifeforms",
		"Animals",
		"Plants",
	"Mathematics",
	"Miscellaneous",
	"Names",
	"Nature",
	"Numbers",
	"People",
	"Philosophy",
	"Places",
	"Sciences",
	"Sex",
	"Social acts",
	"Society",
	"Sports",
	"Technology",
	"Thesaurus",
	"Time",
	"Transport",
	"Physical actions",
}

labels["all topics"] = {
	type = "toplevel",
	description = "{{{langname}}} terms organized by topic, such as \"Family\", \"Chemistry\", \"Planets\", \"Canids\" or \"Cities in France\".",
	parents = {{module = "poscatboiler", args = {label = "{{{langcat}}}", raw = true, called_from_inside = true}}},
}

for _, typ in ipairs { "related-to", "set", "type", "name", "grouping" } do
	labels["list of " .. typ .. " categories"] = {
		type = "toplevel",
		description = "All " .. typ .. " categories currently available in {{{langname}}}.",
		parents = {{name = "all topics", sort = " *"}},
	}
end

labels["list of mixed categories"] = {
	type = "toplevel",
	description = "All categories currently available in {{{langname}}} that belong to more than one type.",
	parents = {{name = "all topics", sort = " *"}},
}

for label, data in pairs(labels) do
	data.module = top_level_data_module
end

-- Import subpages
for _, subpage in ipairs(subpages) do
	local datamodule = data_module_prefix .. subpage
	local retval = require(datamodule)
	if not retval["LABELS"] then
		retval = {LABELS = retval}
	end
	for label, data in pairs(retval["LABELS"]) do
		if labels[label] and not retval["IGNOREDUP"] then
			error("Label " .. label .. " defined in both [["
				.. datamodule .. "]] and [[" .. labels[label].module .. "]].")
		end
		data.module = datamodule
		labels[label] = data
	end
	if retval["HANDLERS"] then
		for _, handler in ipairs(retval["HANDLERS"]) do
			table.insert(handlers, { module = datamodule, handler = handler })
		end
	end
end

return {LABELS = labels, HANDLERS = handlers}