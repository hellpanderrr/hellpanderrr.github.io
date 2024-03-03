local match = string.match
local tonumber = tonumber
local trim = require("string/php trim")
local type = type

local extra = {
	["9007199254740992"] = true,
	["-9007199254740992"] = true
}

return function(key)
	if type(key) ~= "string" then
		return key
	end
	key = trim(key)
	if match(key, "^-?[1-9]%d*$") then
		local num = tonumber(key)
		key = (num <= 9007199254740991 and num >= -9007199254740991 or extra[key]) and num or key
	elseif key == "0" then
		return 0
	end
	return key
end