local canonical_AD = 'AD'
local canonical_BCE = 'BCE'
local AD_limit = 999 -- maximum year to append CE
local export = {}

local function validate_year(yearstring)
	local year = tonumber(yearstring)
	if (year == nil) then
		return false
	end
	if (year <= 0) then
		return false
	end
	return year
end

local function validate_tp(tpstring)
	-- validates ad, bc, bce, ...
	local tpstring = string.upper(tpstring)
	local tpstring = string.gsub(tpstring, "%.", "")

	local bcetable = {["BC"] = true, ["BCE"] = true}
	local adtable = {["AD"] = true, ["CE"] = true}

	if bcetable[tpstring] then
		return canonical_BCE
	end
	if adtable[tpstring] then
		return canonical_AD
	end
	return false
end

local function validate_approx(approxstring)
	approxstring = string.lower(approxstring)
	approxstring = string.gsub(approxstring, "%.", "")

	local approx_table = {["a"] = true,
				          ["c"] = true,
					      ["circa"] = true,
					      ["approx"] = true}

	if approx_table[approxstring] then
		return "a"
	end
	return false
end
	
local function parse_date(datestring)
	local result = {}
	local separators = {'-', '–'}
	local canonical_separator = '-'
	
	for i, separator in pairs(separators) do -- replace any nonstandard separators
		datestring = string.gsub(datestring, separator, canonical_separator)
	end
	
	local datetable = mw.text.split(datestring, canonical_separator)
	
	for i, yearstring in ipairs(datetable) do
		local yeartable_temp = mw.text.split(yearstring, ' ')
		
		local yeartable = {}
		for i, v in ipairs(yeartable_temp) do -- remove any empty strings
			if (v ~= '') then
				table.insert(yeartable, v)
			end
		end
		
		if (#yeartable == 1) then
			-- only year is specified
			table.insert(result, {'e', validate_year(yeartable[1]), "?"})
		end
		
		if (#yeartable == 2) then
			-- either year, BCE/AD or c, year
			local yt1 = validate_year(yeartable[1])
			local yt2 = validate_year(yeartable[2])
			
			if (yt1 ~= false) then -- year, BCE/AD
				table.insert(result, {'e', yt1, validate_tp(yeartable[2])})
			end
			
			if (yt1 == false) then -- c, year
				table.insert(result, {validate_approx(yeartable[1]), yt2, "?"})
			end
		end
		
		if (#yeartable == 3) then
			-- c, year, BCE/AD
			table.insert(result, {validate_approx(yeartable[1]), validate_year(yeartable[2]), validate_tp(yeartable[3])})
		end
		
	end

	for i, v in pairs(result) do
		for i_, v_ in pairs(v) do
			if (v_ == false) then
				return false
			end
		end
	end
	
	if (#result == 1) then
		if result[1][3] == "?" then
			result[1][3] = canonical_AD
		end
		return result
	end
	
	if (#result == 2) then
		-- add in missing time periods
		if result[1][3] == "?" then
			if result[2][3] == "?" then
				result[1][3] = canonical_AD
				result[2][3] = canonical_AD
			end
			if result[2][3] == canonical_AD then
				result[1][3] = canonical_AD
			end
			if result[2][3] == canonical_BCE then
				result[1][3] = canonical_BCE
			end
		end
		
		if result[1][3] == canonical_AD then
			if result[2][3] == "?" then
				result[2][3] = canonical_AD
			end
			if result[2][3] == canonical_BCE then
				return false
			end
		end
		
		if result[1][3] == canonical_BCE then
			if result[2][3] == "?" then
				result[2][3] = canonical_BCE
			end
		end

		-- validate time ranges
        if result[1][3] == result[2][3] then
            if result[1][3] == canonical_BCE then
                if result[2][2] > result[1][2] then
                    return false
                end
            else
            	if result[2][2] < result[1][2] then
            		return false
        		end
        	end
    	else
        	if result[1][3] == canonical_AD and result[2][3] == canonical_BCE then
            	return false
        	end
        end

		return result
	end
	
	return false
end

local function display_date(parsed_date)
	local separator = ' – '

    local CE = "<small class='ce-date'>[[Appendix:Glossary#CE|<span title=\"Glossary and display preference\">CE</span>]]</small>"
    local BCE = "<small class='ce-date'>[[Appendix:Glossary#BCE|<span title=\"Glossary and display preference\">BCE</span>]]</small>"
    local circa = "''[[circa|c.]]''"
    
    local result = {}
    
    for i, v in ipairs(parsed_date) do
    	local s = ""
    	if v[1] == 'a' then
    		s = s..circa.." "
		end
		s = s..tostring(v[2]).." "
		if v[3] == canonical_BCE then
			s = s..BCE
		end
		if v[3] == canonical_AD then
			if (v[2] <= AD_limit) then
				s = s..CE
			end
		end
		table.insert(result, mw.text.trim(s))
	end
	
	return table.concat(result, separator)
end

function export.main(datestring)

	local parsed_date = parse_date(datestring)
	if (parsed_date ~= false) then
		return display_date(parsed_date)
	end
	return datestring
end

return export