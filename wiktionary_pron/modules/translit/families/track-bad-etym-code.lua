local function track(page)
	require("debug/track")("families/" .. page)
	return true
end

-- FIXME: Temporary. Lists nonstandard codes to track, so we can consider eliminating them.
local nonstandard_codes_to_track = {
	["OIr."] = true,
	["MIr."] = true,
}

return function(code)
	if nonstandard_codes_to_track[code] then
		track(code)
	end
	return true
end