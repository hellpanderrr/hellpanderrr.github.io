-- Function allowing for consistent treatment of boolean-like wikitext input.
-- It works similarly to the template {{yesno}}.
local type = type

return function (val, default)
	if val == nil then
		return nil
	end
	val = type(val) == "string" and val:lower() or val
	return (
		val == true or val == "true" or val == 1 or val == "1" or
		val == "yes" or val == "y" or val == "t" or val == "on"
	) and true or not (
		val == false or val == "false" or val == 0 or val == "0" or
		val == "no" or val == "n" or val == "f" or val == "off"
	) and default
end