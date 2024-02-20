local export = {}

-- A helper function to escape magic characters in a string when interpolating a string into a Lua pattern.
-- Magic characters: ^$()%.[]*+-?
function export.pattern_escape(text)
	if type(text) == "table" then
		text = text.args[1]
	end
	text = mw.ustring.gsub(text, "([%^$()%%.%[%]*+%-?])", "%%%1")
	return text
end

-- A helper function to escape magic characters in a string when interpolating a string into a Lua pattern replacement
-- string (the right side of a gsub() pattern substitution call).
-- Magic characters: %
function export.replacement_escape(text)
	if type(text) == "table" then
		text = text.args[1]
	end
	text = mw.ustring.gsub(text, "%%", "%%%%")
	return text
end

return export