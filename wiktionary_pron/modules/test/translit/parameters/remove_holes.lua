
-- A helper function that removes empty numeric indexes in a table,
-- so that the values are tightly packed like in a normal Lua table.
-- equivalent to require("table").compressSparseArray
return function(t)
	local highest = 0
	for num, _ in pairs(t) do
		if type(num) == "number" and num > 0 and num < math.huge and math.floor(num) == num then
			highest = math.max(highest, num)
		end
	end
	local need_to_compress = false
	for i = 1, highest do
		if t[i] == nil then
			need_to_compress = true
			break
		end
	end
	if not need_to_compress then
		-- The previous algorithm always copied, which implicitly removed 'maxindex' (and other non-numeric keys).
		-- Some code calls next(val) to check for a value being present, which depends on 'maxindex' not being present,
		-- so remove it.
		t.maxindex = nil
		return t
	else
		local ret = {}
		local index = 1
		for i = 1, highest do
			if t[i] ~= nil then
				ret[index] = t[i]
				index = index + 1
			end
		end
		return ret
	end
end