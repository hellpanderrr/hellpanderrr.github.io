local data = {}

data.translit = {
	["term"] = {
--[=[	can't be done until Kana transliterations are correctly parsed by [[Module:links]]
		["tag"] = "i",
		]=]
		["classes"] = "mention-tr",
	},
	["usex"] = {
		["tag"] = "i",
		["classes"] = "e-transliteration",
	},
	["head"] = {
		["classes"] = "headword-tr",
		["dir"] = "ltr",
	},
	["default"] = {},
}

data.transcription = {
	["head"] = {
		["tag"] = "span",
		["classes"] = "headword-ts",
		["dir"] = "ltr",
	},
	["usex"] = {
		tag = "span",
		["classes"] = "e-transcription",
	},
	["default"] = {},
}

for key, value in pairs(data.translit) do
	if not value.tag then
		value.tag = "span"
	end
end

local faces = {}

faces["term"] = {
	tag = "i",
	class = "mention",
}

faces["head"] = {
	tag = "strong",
	class = "headword",
}

faces["hypothetical"] = {
	prefix = '<span class="hypothetical-star">*</span>',
	tag = "i",
	class = "hypothetical",
}

faces["bold"] = {
	tag = "b",
}

faces["plain"] = {
	tag = "span",
}

faces["translation"] = faces["plain"]

data.faces = faces

return data