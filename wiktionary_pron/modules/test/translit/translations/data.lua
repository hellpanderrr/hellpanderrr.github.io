local export = {}

export.categorize = {
	["en"] = true,
	["mul"] = true,
	["und"] = true
}

local function lang_info(code)
	return require("languages").getByCode(code):getCanonicalName() .. " (" .. code .. ")"
end

-- Mainspace languages not allowed in translation sections.
-- The value is the part of the error message given after "Translations not allowed in LANG. LANG translations should ...".
local disallowed = {}
disallowed["ltc"] = "be given as " .. lang_info("lzh") .. "."
disallowed["och"] = disallowed["ltc"]
-- disallowed["zh"] = "be given as a specific lect. For Modern Standard Chinese, use " .. lang_info("cmn") .. "." -- To be enabled once all current instances have been converted.
export.disallowed = disallowed

export.interwiki_langs = {
	["fa-cls"] = "fa",
	["fa-ira"] = "fa",
	["kmr"] = "ku",
	["lki"] = "ku",
	["nds-de"] = "nds",
	["nds-nl"] = "nds",
	["pdt"] = "nds",
	["prs"] = "fa",
	["sdh"] = "ku",
}

-- languages needing superscripts in tr
export.need_super = {
	["cjy"] = true,
	["gan"] = true,
	["hak"] = true,
	["hsn"] = true,
	["nan"] = true,
	["wuu"] = true,
	["yue"] = true,
	["zhx-lui"] = true,
	["zhx-tai"] = true,
	["zhx-teo"] = true,
}

return export