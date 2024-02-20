 local substitutes

local function doRemoveExceptions(text, sc, remove_exceptions)
	local gsub = require("string utilities").gsub
	substitutes = {} or substitutes
	local i = 0
	for _, exception in ipairs(remove_exceptions) do
		exception = sc:toFixedNFD(exception)
		text = gsub(text, exception, function(m)
			i = i + 1
			table.insert(substitutes, m)
			return "\127"
		end)
	end
	return text
end

local function undoRemoveExceptions(text)
	local i = 0
	return text:gsub("\127", function(m1)
		i = i + 1
		return substitutes[i]
	end)
end

local function doSubstitutions(text, self, sc, substitution_data, function_name, recursed)
	local fail, cats = nil, {}
	-- If there are language-specific substitutes given in the data module, use those.
	if type(substitution_data) == "table" then
		-- If a script is specified, run this function with the script-specific data before continuing.
		local sc_code = sc:getCode()
		if substitution_data[sc_code] then
			text, fail, cats = doSubstitutions(text, self, sc, substitution_data[sc_code], function_name, true)
		-- Hant, Hans and Hani are usually treated the same, so add a special case to avoid having to specify each one separately.
		elseif sc_code:match("^Han") and substitution_data.Hani then
			text, fail, cats = doSubstitutions(text, self, sc, substitution_data.Hani, function_name, true)
		-- Substitution data with key 1 in the outer table may be given as a fallback.
		elseif substitution_data[1] then
			text, fail, cats = doSubstitutions(text, self, sc, substitution_data[1], function_name, true)
		end
		-- Iterate over all strings in the "from" subtable, and gsub with the corresponding string in "to". We work with the NFD decomposed forms, as this simplifies many substitutions.
		if substitution_data.from then
			local gsub = require("string utilities").gsub
			for i, from in ipairs(substitution_data.from) do
				-- We normalize each loop, to ensure multi-stage substitutions work correctly.
				text = sc:toFixedNFD(text)
				-- Check whether specific magic characters are present, as they rely on UTF-8 compatibility. If not, just use string.gsub. In most cases, doing this is faster than using mw.ustring.gsub every time.
				text = gsub(text, sc:toFixedNFD(from), substitution_data.to[i] or "")
			end
		end
		
		if substitution_data.remove_diacritics then
			text = sc:toFixedNFD(text)
			-- Convert exceptions to PUA.
			if substitution_data.remove_exceptions then
				text = doRemoveExceptions(text, sc, substitution_data.remove_exceptions)
			end
			-- Strip diacritics.
			text =  require("string utilities").gsub(text, "[" .. substitution_data.remove_diacritics .. "]", "")
			-- Convert exceptions back.
			if substitution_data.remove_exceptions then
				text = undoRemoveExceptions(text)
			end
		end
	elseif type(substitution_data) == "string" then
		-- If there is a dedicated function module, use that.
		local is_module, module = pcall(require, "Module:" .. substitution_data)
		if is_module then
			if function_name == "tr" then
				text, fail, cats = module[function_name](text, self:getCode(), sc:getCode())
			else
				text, fail, cats = module[function_name](sc:toFixedNFD(text), self:getCode(), sc:getCode())
			end
		else
			error("Substitution data '" .. substitution_data .. "' does not match an existing module or module failed to execute: " .. tostring(module) .. ".")
		end
	end
	
	-- Don't normalize to NFC if this is the inner loop or if a module returned nil.
	if recursed or not text then
		return text, fail, cats
	else
		-- Fix any discouraged sequences created during the substitution process, and normalize into the final form.
		text = sc:fixDiscouragedSequences(text)
		return sc:toFixedNFC(text), fail, cats
	end
end

-- This avoids calling into globals with require when the main function recurses.
return function (text, self, sc, substitution_data, function_name)
	return doSubstitutions(text, self, sc, substitution_data, function_name)
end