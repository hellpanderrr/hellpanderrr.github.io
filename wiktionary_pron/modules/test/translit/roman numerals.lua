local roman_dict = {M = 1000, D = 500, C = 100, L = 50, X = 10, V = 5, I = 1}
local repeatable = {M = true, C = true, X = true, I = true}
local roman_table =  {'M',  'CM', 'D', 'CD', 'C', 'XC', 'L', 'XL', 'X', 'IX', 'V', 'IV', 'I'}
local arabic_table = {1000, 900,  500, 400,  100, 90,   50,  40,   10,  9,    5,   4,    1  }

local export = {}

local function nil_or_error(msg, no_error)
	if no_error then
		return nil
	else
		error(msg, 2)
	end
end

function export.arabic_to_roman(arabic, no_error, to_lower, use_j, use_iiii)
	if arabic == '' or arabic == nil then return nil end
	
	arabic = mw.ustring.gsub(arabic, ",", "")
	
	local j = tonumber(arabic)
	
	if j == nil then return nil end
	
	if j <= 0 or j > 3999 then
		return nil_or_error("Out of valid range", no_error)
	end

	local result = {}
	local a, count
	
	for i, r in ipairs(roman_table) do
		a = arabic_table[i]
		count = math.floor(j / a)
		table.insert(result, string.rep(r, count))
		j = j % a
		if j <= 0 then break end
	end
	
	local out = table.concat(result)
	if to_lower then out = mw.ustring.lower(out) end
	
	if use_iiii and out:sub(-2, -1) == "IV" then out = out:sub(1, -3) .. "IIII" end
	if use_iiii and out:sub(-2, -1) == "iv" then out = out:sub(1, -3) .. "iiii" end
	
	if use_j and out:sub(-1, -1) == "I" then out = out:sub(1, -2) .. "J" end
	if use_j and out:sub(-1, -1) == "i" then out = out:sub(1, -2) .. "j" end
	
	return out
end

function export.roman_to_arabic(roman, no_error)
	if roman == '' or roman == nil then
		return nil
	else
		roman = mw.ustring.upper(roman):gsub("J", "I")
	end
	
	if not mw.ustring.match(roman, "^[MDCLXVI]+$") then
		return nil_or_error("Illegal Roman numeral format", no_error)
	end
	
	local result = 0
	
	local i = 1
	local s1, s2, c2
	local length = #roman
	
	while i <= length do
		s1 = roman_dict[roman:sub(i, i)]
		if s1 == nil then
			return nil_or_error("Unrecognized character in input", no_error)
		elseif (i + 1) <= length then
			c2 = roman:sub(i + 1, i + 1)
			s2 = roman_dict[c2]
			if s2 == nil then 
				return nil_or_error("Unrecognized character in input", no_error)
			elseif s1 >= s2 then
				if s1 == s2 and not repeatable[c2] then
					return nil_or_error("Illegal Roman numeral format: “" .. c2 .. "” may not appear adjacent to itself", no_error)
				end
				result = result + s1
			else
				result = result + s2 - s1
				i = i + 1
			end
		else
			result = result + s1
		end
		i = i + 1
	end
	
	return result
	
end

-- implements {{R2A}}
function export.roman_to_arabic_t(frame)
	local params = {
		[1] = {},
		['no_error'] = {type = 'boolean'},
	}
	
	local args = require("parameters").process(frame:getParent().args, params)
	
	return export.roman_to_arabic(args[1], args.no_error)
end

-- implements {{A2R}}
function export.arabic_to_roman_t(frame)
	local params = {
		[1] = {},
		['lower'] = {type = 'boolean'},
		['j'] = {type = 'boolean'},
		['iiii'] = {type = 'boolean'},
		['no_error'] = {type = 'boolean'},
	}
	
	local args = require("parameters").process(frame:getParent().args, params)
	
	return export.arabic_to_roman(args[1], args.no_error, args.lower, args.j, args.iiii)
end

return export