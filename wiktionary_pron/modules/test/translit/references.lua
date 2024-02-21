local export = {}

local rsplit = mw.text.split

-- Parse a references spec as used in the |ref= param to {{IPA}} and {{IPAchar}} and soon the |fNref= param to {{head}}.
--
-- Multiple references are separated by !!! (optionally with spaces around it), and the equivalent of
-- <ref name="bendo">{{R:it:DiPI|bendo}}</ref><ref>{{R:it:Olivetti}}</ref> can be specified using a syntax like the following:
-- {{IPA|it|ˈben.do|ˈbɛn.do|ref2={{R:it:DiPI|bendo}}<<name:bendo>> !!! {{R:it:Olivetti}}}}
-- To include a group as in,<ref name="bendo" group="pron">...</ref> use:
-- {{IPA|it|ˈben.do|ˈbɛn.do|ref2={{R:it:DiPI|bendo}}<<name:bendo>><<group:pron>>}}
-- To reference a prior name, as in <ref name="bendo"/>, leave the reference text blank:
-- {{IPA|it|ˈben.do|ˈbɛn.do|ref2=<<name:bendo>>}}
-- Similarly, to reference a prior name in a particular group, as in <ref name="bendo" group="pron"/>, use:
-- {{IPA|it|ˈben.do|ˈbɛn.do|ref2=<<name:bendo>><<group:pron>>}}
--
-- The return value consists of a list of objects of the form {text = TEXT, name = NAME, group = GROUP}.
-- This is the same format as is expected in the part.refs in [[Module:headword]] and item.refs in
-- [[Module:IPA]].
function export.parse_references(text)
	local refs = {}
	local raw_notes = rsplit(text, "%s*!!!%s*")
	for _, raw_note in ipairs(raw_notes) do
		local note
		if raw_note:find("<<") then
			local splitvals = require("string utilities").capturing_split(raw_note, "(<<[a-z]+:.->>)")
			note = {text = splitvals[1]}
			for i = 2, #splitvals, 2 do
				local key, value = splitvals[i]:match("^<<([a-z]+):(.*)>>$")
				if not key then
					error("Internal error: Can't parse " .. splitvals[i])
				end
				if key == "name" or key == "group" then
					note[key] = value
				else
					error("Unrecognized key '" .. key .. "' in " .. splitvals[i])
				end
				if splitvals[i + 1] ~= "" then
					error("Extraneous text '" .. splitvals[i + 1] .. "' after " .. splitvals[i])
				end
			end
		else
			note = raw_note
		end
		table.insert(refs, note)
	end
	
	return refs
end

return export