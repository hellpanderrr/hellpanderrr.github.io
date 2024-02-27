local require_when_needed = require("utilities/require when needed")

local dump = mw.dumpObject
local floor = math.floor
local get_family = require_when_needed("Module:families", "getByCode")
local get_language = require_when_needed("Module:languages", "getByCode")
local get_script = require_when_needed("Module:scripts", "getByCode")
local get_wm_language = require_when_needed("Module:wikimedia languages", "getByCode")
local gsplit = mw.text.gsplit
local gsub = string.gsub
local huge = math.huge
local insert = table.insert
local list_to_text = mw.text.listToText
local match = string.match
local max = math.max
local pairs = pairs
local pattern_escape = require_when_needed("Module:string/pattern_escape")
local remove_holes = require_when_needed("Module:parameters/remove holes")
local scribunto_param_key = require_when_needed("Module:utilities/scribunto parameter key")
local sort = table.sort
local trim = mw.text.trim
local type = type
local yesno = require_when_needed("Module:yesno")

local export = {}

local function track(page)
	require("debug/track")("parameters/" .. page)
end

local function save_pattern(name, list_name, patterns)
	name = type(name) == "string" and gsub(name, "[\1=]", "") or name
	if match(list_name, "[\1=]") then
		patterns["^" .. gsub(pattern_escape(list_name), "[\1=]", "([1-9]%%d*)") .. "$"] = name
	else
		patterns["^" .. pattern_escape(list_name) .. "([1-9]%d*)$"] = name
	end
end

local function concat_list(list, conjunction, dump_vals)
	if dump_vals then
		for i = 1, #list do
			list[i] = dump(list[i])
		end
	end
	return list_to_text(list, nil, conjunction)
end

local function check_set(val, name, param)
	if not param.set[val] then
		local list = {}
		for k in pairs(param.set) do
			insert(list, dump(k))
		end
		sort(list)
		-- If the parameter is not required then put "or empty" at the end of the list, to avoid implying the parameter is actually required.
		if not param.required then
			insert(list, "empty")
		end
		error("Parameter " .. dump(name) .. " must be " .. (#param.set > 1 and "either " or "") .. concat_list(list, " or ") .. "; the value " .. dump(val) .. " is not valid.")
	end
end

local get_val = setmetatable({
	["boolean"] = function(val)
		-- Set makes no sense with booleans, so don't bother checking for it.
		return yesno(val, true)
	end,
	
	["family"] = function(val, name, param)
		if param.set then
			check_set(val, name, param)
		end
		return get_family(val) or
			error("Parameter " .. dump(name) .. " should be a valid family code; the value " .. dump(val) .. " is not valid. See [[WT:LOF]].")
	end,
	
	["language"] = function(val, name, param)
		if param.set then
			check_set(val, name, param)
		end
		local lang = get_language(val, nil, param.etym_lang, param.family)
		if lang then
			return lang
		end
		local list = {"language"}
		local links = {"[[WT:LOL]]"}
		if param.etym_lang then
			insert(list, "etymology language")
			insert(links, "[[WT:LOL/E]]")
		end
		if param.family then
			insert(list, "family")
			insert(links, "[[WT:LOF]]")
		end
		error("Parameter " .. dump(name) .. " should be a valid " .. concat_list(list, " or ") .. " code; the value " .. dump(val) .. " is not valid. See " .. concat_list(links, " and ") .. ".")
	end,
	
	["number"] = function(val, name, param)
		if type(val) == "number" then
			return val
		end
		-- Avoid converting inputs like "nan" or "inf".
		val = tonumber(val:match("^[+%-]?%d+%.?%d*")) or
			error("Parameter " .. dump(name) .. " should be a valid number; the value " .. dump(val) .. " is not valid.")
		if param.set then
			check_set(val, name, param)
		end
		return val
	end,
	
	["script"] = function(val, name, param)
		if param.set then
			check_set(val, name, param)
		end
		return get_script(val) or
			error("Parameter " .. dump(name) .. " should be a valid script code; the value " .. dump(val) .. " is not valid. See [[WT:LOS]].")
	end,
	
	["string"] = function(val, name, param)
		if param.set then
			check_set(val, name, param)
		end
		return val
	end,
	
	["wikimedia language"] = function(val, name, param)
		if param.set then
			check_set(val, name, param)
		end
		local lang = get_wm_language(val)
		if lang then
			return lang
		end
		error("Parameter " .. dump(name) .. " should be a valid wikimedia language code; the value " .. dump(val) .. " is not valid.")
	end,
}, {
	__call = function(self, val, name, param)
		local func, sublist = self[param.type or "string"], param.sublist
		if not func then
			error(dump(param.type) .. " is not a recognized parameter type.")
		elseif sublist then
			local ret_val = {}
			for v in gsplit(val, sublist == true and "%s*,%s*" or sublist) do
				insert(ret_val, func(v, name, param))
			end
			return ret_val
		else
			return func(val, name, param)
		end
	end
})

function export.process(args, params, return_unknown)
	-- Process parameters for specific properties
	local args_new = {}
	local required = {}
	local patterns = {}
	local names_with_equal_sign = {}
	local list_from_index
	
	for name, param in pairs(params) do
		-- Temporary tracker, while "=" is being phased out for "\1".
		if (
			type(name) == "string" and name:match("=") or
			type(param.list) == "string" and param.list:match("=")
		) then
			track("equals sign parameter")
		end
		
		-- Populate required table, and make sure aliases aren't set to required.
		if param.required then
			if param.alias_of then
				error("`params` table error: parameter " .. dump(name) .. " is an alias of " .. dump(param.alias_of) .. ", but is also set as a required parameter. Only " .. dump(name) .. " should be set as required.")
			end
			required[name] = true
		end
		
		local alias = param.alias_of
		if alias then
			-- Check that the alias_of is set to a valid parameter.
			if not params[alias] then
				error("`params` table error: parameter " .. dump(name) .. " is an alias of an invalid parameter.")
			end
			-- Check that all the parameters in params are in the form Scribunto normalizes input argument keys into (e.g. 1 not "1", "foo" not " foo "). Otherwise, this function won't be able to normalize the input arguments in the expected way.
			local normalized = scribunto_param_key(alias)
			if alias ~= normalized then
				error("`params` table error: parameter " .. dump(alias) .. " (a " .. type(alias) .. ") given in the alias_of field of parameter " .. dump(name) .. " is not a normalized Scribunto parameter. Should be " .. dump(normalized) .. " (a " .. type(normalized) .. ").")
			-- Aliases can't be lists unless the canonical parameter is also a list.
			elseif param.list and not params[alias].list then
				error("`params` table error: the list parameter " .. dump(name) .. " is set as an alias of " .. dump(alias) .. ", which is not a list parameter.")
			-- Aliases can't be aliases of other aliases.
			elseif params[alias].alias_of then
				error("`params` table error: alias_of cannot be set to another alias: parameter " .. dump(name) .. " is set as an alias of " .. dump(alias) .. ", which is in turn an alias of " .. dump(params[alias].alias_of) .. ". Set alias_of for " .. dump(name) .. " to " .. dump(params[alias].alias_of) .. ".")
			end
		end
		
		local normalized = scribunto_param_key(name)
		if name ~= normalized then
			error("`params` table error: parameter " .. dump(name) .. " (a " .. type(name) .. ") is not a normalized Scribunto parameter. Should be " .. dump(normalized) .. " (a " .. type(normalized) .. ").")
		end
		
		if param.list then
			if not param.alias_of then
				local key = name
				if type(name) == "string" then
					key = gsub(name, "[\1=]", "")
				end
				-- _list is used as a temporary flag.
				args_new[key] = {maxindex = 0, _list = true}
			end
			
			if type(param.list) == "string" then
				-- If the list property is a string, then it represents the name
				-- to be used as the prefix for list items. This is for use with lists
				-- where the first item is a numbered parameter and the
				-- subsequent ones are named, such as 1, pl2, pl3.
				save_pattern(name, param.list, patterns)
			elseif type(name) == "number" then
				if list_from_index then
					error("`params` table error: only one numeric parameter can be a list, unless the list property is a string.")
				end
				-- If the name is a number, then all indexed parameters from
				-- this number onwards go in the list.
				list_from_index = name
			else
				save_pattern(name, name, patterns)
			end
			
			if match(name, "[\1=]") then
				insert(names_with_equal_sign, name)
			end
		end
	end
	
	--Process required changes to `params`.
	for i = 1, #names_with_equal_sign do
		local name = names_with_equal_sign[i]
		params[gsub(name, "[\1=]", "")] = params[name]
		params[name] = nil
	end
	
	-- Process the arguments
	local args_unknown = {}
	local max_index
	
	for name, val in pairs(args) do
		local orig_name, raw_type, index, normalized = name, type(name)
		
		if raw_type == "number" then
			if list_from_index ~= nil and name >= list_from_index then
				index = name - list_from_index + 1
				name = list_from_index
			end
		else
			-- Does this argument name match a pattern?
			for pattern, pname in pairs(patterns) do
				index = match(name, pattern)
				-- It matches, so store the parameter name and the
				-- numeric index extracted from the argument name.
				if index then
					index = tonumber(index)
					name = pname
					break
				end
			end
		end
		
		local param = params[name]
		
		if param and param.require_index then
			-- Disallow require_index for numeric parameter names, as this doesn't make sense.
			if raw_type == "number" then
				error("`params` table error: cannot set require_index for numeric parameter " .. dump(name) .. ".")
			-- If a parameter without the trailing index was found, and
			-- require_index is set on the param, set the param to nil to treat it
			-- as if it isn't recognized.
			elseif not index then
				param = nil
			end
		end
		
		-- If the argument is not in the list of parameters, trigger an error.
		-- return_unknown suppresses the error, and stores it in a separate list instead.
		if not param then
			if return_unknown then
				args_unknown[name] = val
			else
				error("Parameter " .. dump(name) .. " is not used by this template.", 2)
			end
		else
			-- Check that separate_no_index is not being used with a numeric parameter.
			if param.separate_no_index then
				if raw_type == "number" then
					error("`params` table error: cannot set separate_no_index for numeric parameter " .. dump(name) .. ".")
				elseif type(param.alias_of) == "number" then
					error("`params` table error: cannot set separate_no_index for parameter " .. dump(name) .. ", as it is an alias of numeric parameter " .. dump(param.alias_of) .. ".")
				end
			end
			
			-- If no index was found, use 1 as the default index.
			-- This makes list parameters like g, g2, g3 put g at index 1.
			-- If `separate_no_index` is set, then use 0 as the default instead.
			if param.list then
				index = index or param.separate_no_index and 0 or 1
			end
			
			-- Normalize to the canonical parameter name. If it's a list, but the alias is not, then determine the index.
			local raw_name = param.alias_of
			if param.alias_of then
				raw_type = type(raw_name)
				if raw_type == "number" then
					if params[raw_name].list then
						index = index or param.separate_no_index and 0 or 1
						normalized = raw_name + index - 1
					else
						normalized = raw_name
					end
					name = raw_name
				else
					name = gsub(raw_name, "[\1=]", "")
					if params[name].list then
						index = index or param.separate_no_index and 0 or 1
					end
					if not index or index == 0 then
						normalized = name
					elseif name == raw_name then
						normalized = name .. index
					else
						
						normalized = gsub(raw_name, "[\1=]", index)
					end
				end
			else
				normalized = orig_name
			end
			
			-- Remove leading and trailing whitespace unless allow_whitespace is true.
			if not param.allow_whitespace then
				val = trim(val)
			end
			
			-- Empty string is equivalent to nil unless allow_empty is true.
			if val == "" and not param.allow_empty then
				val = nil
				-- Track empty parameters, unless (1) allow_empty is set or (2) they're numbered parameters where a higher numbered parameter is also in use (e.g. track {{l|en|term|}}, but not {{l|en||term}}).
				if raw_type == "number" and not max_index then
					-- Find the highest numbered parameter that's in use/an empty string, as we don't want parameters like 500= to mean we can't track any empty parameters with a lower index than 500.
					local n = 0
					while args[n + 1] do
						n = n + 1
					end
					max_index = 0
					for n = n, 1, -1 do
						if args[n] ~= "" then
							max_index = n
							break
						end
					end
				end
				if raw_type ~= "number" or name > max_index then
					track("empty parameter")
				end
			end
			
			-- Can't use "if val" alone, because val may be a boolean false.
			if val ~= nil then
				-- Convert to proper type if necessary.
				val = get_val(val, orig_name, params[raw_name] or param)
				
				-- Mark it as no longer required, as it is present.
				required[name] = nil
				
				-- Store the argument value.
				if index then
					-- If the parameter is duplicated, throw an error.
					if args_new[name][index] ~= nil then
						error("Parameter " .. dump(normalized) .. " has been entered more than once. This is probably because a list parameter has been entered without an index and with index 1 at the same time, or because a parameter alias has been used.")
					end
					args_new[name][index] = val
					
					-- Store the highest index we find.
					args_new[name].maxindex = max(index, args_new[name].maxindex)
					if args_new[name][0] ~= nil then
						args_new[name].default = args_new[name][0]
						if args_new[name].maxindex == 0 then
							args_new[name].maxindex = 1
						end
						args_new[name][0] = nil
						
					end
					
					if params[name].list then
						-- Don't store index 0, as it's a proxy for the default.
						if index > 0 then
							args_new[name][index] = val
							-- Store the highest index we find.
							args_new[name].maxindex = max(index, args_new[name].maxindex)
						end
					else
						args_new[name] = val
					end
				else
					-- If the parameter is duplicated, throw an error.
					if args_new[name] ~= nil then
						error("Parameter " .. dump(normalized) .. " has been entered more than once. This is probably because a parameter alias has been used.")
					end
					
					if not param.alias_of then
						args_new[name] = val
					else
						if params[param.alias_of].list then
							args_new[param.alias_of][1] = val
							
							-- Store the highest index we find.
							args_new[param.alias_of].maxindex = max(1, args_new[param.alias_of].maxindex)
						else
							args_new[param.alias_of] = val
						end
					end
				end
			end
		end
	end
	
	-- Handle defaults.
	for name, param in pairs(params) do
		if param.default ~= nil then
			local arg_new = args_new[name]
			if type(arg_new) == "table" and arg_new._list then
				if arg_new[1] == nil then
					arg_new[1] = get_val(param.default, name, param)
				end
				if arg_new.maxindex == 0 then
					arg_new.maxindex = 1
				end
			elseif arg_new == nil then
				args_new[name] = get_val(param.default, name, param)
			end
		end
	end
	
	-- The required table should now be empty.
	-- If any entry remains, trigger an error, unless we're in the template namespace.
	if mw.title.getCurrentTitle().namespace ~= 10 then
		local list = {}
		for name in pairs(required) do
			insert(list, dump(name))
		end
		local n = #list
		if n > 0 then
			error("Parameter" .. (
				n == 1 and (" " .. list[1] .. " is") or
				("s " .. concat_list(list, " and ", true) .. " are")
			) .. " required.", 2)
		end
	end
	
	-- Remove holes in any list parameters if needed.
	for name, val in pairs(args_new) do
		if type(val) == "table" and val._list then
			if params[name].disallow_holes then
				local highest = 0
				for num, _ in pairs(val) do
					if type(num) == "number" and num > 0 and num < huge and floor(num) == num then
						highest = max(highest, num)
					end
				end
				for i = 1, highest do
					if val[i] == nil then
						error(("For %s=, saw hole at index %s; disallowed because `disallow_holes` specified"):format(name, i))
					end
				end
				-- Some code depends on only numeric params being present when no holes are allowed (e.g. by checking for the
				-- presence of arguments using next()), so remove `maxindex`.
				val.maxindex = nil
			elseif not params[name].allow_holes then
				args_new[name] = remove_holes(val)
			end
			val._list = nil
		end
	end
	
	if return_unknown then
		return args_new, args_unknown
	else
		return args_new
	end
end

return export