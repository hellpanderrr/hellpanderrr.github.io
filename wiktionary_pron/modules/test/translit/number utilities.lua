local export = {}

function export.get_number(text)
	if text == '' or text == nil then return nil end
	
	if type(text) == 'string' then
		text = mw.ustring.gsub(text, ",", "")
	end
	
	local j = tonumber(text)
	if j ~= nil then
		return j
	else
		return nil
	end
end

function export.is_number(frame)
	return export.get_number(frame:getParent().args[1])
end

function export.is_hex_number(frame)
	local args = frame:getParent().args
	local hex = args[1]
	if hex then
		hex = mw.text.trim(hex)
		if hex:find("^%x*$") then
			if args.digits then
				local digits = tonumber(args.digits)
				if digits then
					if #hex == digits then
						return "1"
					elseif #hex == 0 and args.allow_empty then
						return "1"
					else
						return ""
					end
				else
					error("Invalid number " .. digits)
				end
			else
				return "1"
			end
		else
			return ""
		end
	else
		if args.allow_empty then
			return "1"
		else
			return ""
		end
	end
end

return export