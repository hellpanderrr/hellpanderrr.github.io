local function track(page)
	require("debug/track")("etymology languages/" .. page)
	return true
end

-- FIXME: Temporary. Lists nonstandard codes to track, so we can consider eliminating them. Consider moving to
-- [[Module:etymology languages/data]] so it only gets loaded once per page; but that would require restructuring
-- [[Module:etymology languages/data]] (probably a good idea anyway).
local nonstandard_codes_to_track = {
	-- nonstandard Latin codes
	["CL."] = true,
	["EL."] = true,
	["LL."] = true,
	["ML."] = true,
	["NL."] = true,
	["RL."] = true,
	["VL."] = true,
	-- badly named Dhivehi codes
	["mlk-dv"] = true,
	["hvd-dv"] = true,
	["add-dv"] = true,
}

return function(code)
	if nonstandard_codes_to_track[code] then
		track(code)
	end
	return true
end