local function get_text(allowEtymLang, allowFamily)
	local list = {"language"}
	if allowEtymLang then
		table.insert(list, "etymology language")
	end
	if allowFamily then
		table.insert(list, "family")
	end
	return mw.text.listToText(list, nil, " or ")
end

local export = {}

function export.code(code, paramForError, allowEtymLang, allowFamily)
	local text = get_text(allowEtymLang, allowFamily) .. " code"
	require("languages/error")(code, paramForError, text)
end

function export.canonicalName(name, allowEtymLang, allowFamily)
	local text = get_text(allowEtymLang, allowFamily) .. " name"
	error("The " .. text .. " \"" .. name .. "\" is not valid.")
end

return export