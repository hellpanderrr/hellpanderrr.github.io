--[[
	{ "a", "b", "c" } -> { ["a"] = true, ["b"] = true, ["c"] = true }
--]]
return function(t)
	-- checkType("listToSet", 1, t, "table")
	
	local set = {}
	for _, item in ipairs(t) do
		set[item] = true
	end
	return set
end