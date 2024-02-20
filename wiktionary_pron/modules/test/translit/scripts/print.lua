local export = {}

local function generate_table(name_to_code)
	local result = {}
	local script_data = mw.loadData("scripts/data")
	
	local iterate
	if name_to_code then
		for code, data in pairs(script_data) do
			if not result[data[1]] or #code == 4 then
				-- Sometimes, multiple scripts have the same name, e.g. 'Arab',
				-- 'fa-Arab', 'ur-Arab' and several others are called "Arabic".
				-- Prefer the one with four characters when disambiguating.
				result[data[1]] = code
			end
		end
	else
		for code, data in pairs(script_data) do
			result[code] = data[1]
		end
	end
	
	return result
end

local function dump(data, name_to_code)
	local output = { "return {" }
	local i = 1
	local sorted_pairs = require "table".sortedPairs
	
	for k, v in sorted_pairs(data) do
		i = i + 1
		output[i] = ('\t[%q] = %q,'):format(k, v)
	end
	
	table.insert(output, "}")
	
	return table.concat(output, "\n")
end

function export.code_to_name(frame)
	return require "debug".highlight(dump(generate_table(false), false))
end

function export.name_to_code(frame)
	return require "debug".highlight(dump(generate_table(true), true))
end

return export