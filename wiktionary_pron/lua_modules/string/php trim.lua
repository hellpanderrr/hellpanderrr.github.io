local sub = string.sub

-- Note: PHP does not trim \f but does trim \0.
local spaces = {
	["\0"] = true,
	["\t"] = true,
	["\n"] = true,
	["\v"] = true,
	["\r"] = true,
	[" "] = true,
}

return function(text)
	local n
	for i = 1, #text do
		if not spaces[sub(text, i, i)] then
			n = i
			break
		end
	end
	if not n then
		return ""
	end
	for i = #text, n, -1 do
		if not spaces[sub(text, i, i)] then
			return sub(text, n, i)
		end
	end
end