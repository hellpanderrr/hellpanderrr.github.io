local labels = {}
local handlers = {}

local lang = require("languages").getByCode("nl")


labels["verbs by derivation type"] = {
	topright = "{{wikipedia|Dutch conjugation#By derivation}}",
	description = "Dutch verbs categorized by the type of derivation.",
	parents = {{name = "verbs", sort = "derivation"}},
}

labels["basic verbs"] = {
	description = "This category contains Dutch verbs that are neither prefixed nor separable.",
	parents = {{name = "verbs by derivation type", sort = "basic"}},
}

labels["prefixed verbs"] = {
	description = "This category contains Dutch prefixed verbs, which are verbs that are compounded with an unstressed prefix, such as " ..
	"{{m|nl|be-}}, {{m|nl|ver-}} or {{m|nl|ont-}}. The unstressed prefix replaces the {{m|nl||ge-}} prefix that normally occurs in the " ..
	"past participle.",
	parents = {{name = "verbs by derivation type", sort = "prefixed"}},
}

labels["separable verbs"] = {
	topright = "{{wikipedia}}",
	description = "This category contains Dutch separable verbs, which are verbs that are compounded with a particle, " ..
	"often an adverb. When the particle is immediately followed by the verb form, it is written together with it as one word. " ..
	"In other cases, it is separated from the main verb by a space and possibly other words.",
	parents = {{name = "verbs by derivation type", sort = "separable"}},
}

table.insert(handlers, function(data)
	local pref = data.label:match("^prefixed verbs with (.+%-)$")
	if pref then
		local link = require("links").full_link({ lang = lang, term = pref }, "term")
		local altlink = require("links").full_link({ lang = lang, alt = pref }, "term")
		return {
			description = "Dutch prefixed verbs with the prefix " .. link .. ".",
			displaytitle = "Dutch prefixed verbs with " .. altlink,
			breadcrumb = altlink,
			parents = {{name = "prefixed verbs", sort = pref}},
		}
	end
end)

table.insert(handlers, function(data)
	local particle = data.label:match("^separable verbs with (.+)$")
	if particle then
		local link = require("links").full_link({ lang = lang, term = particle }, "term")
		local altlink = require("links").full_link({ lang = lang, alt = particle }, "term")
		return {
			description = "Dutch separable verbs with the particle " .. link .. ".",
			displaytitle = "Dutch separable verbs with " .. altlink,
			breadcrumb = altlink,
			parents = {{name = "separable verbs", sort = particle}},
		}
	end
end)


return {LABELS = labels, HANDLERS = handlers}