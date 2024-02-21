local insert = table.insert

local export = {}

local function track(page, calling_module, calling_function, param_name)
	local track = require("debug/track")
	local tracking_page = "parameters/" .. page
	-- Cascades down in specificity, as each level is a prerequisite for the next.
	track(tracking_page)
	if calling_module then
		track(tracking_page .. "/" .. calling_module)
		if calling_function then
			track(tracking_page .. "/" .. calling_module .. "/" .. calling_function)
			if param_name then
				track(tracking_page .. "/" .. calling_module .. "/" .. calling_function .. "/" .. param_name)
			end
		end
	end
	return true
end

function export.process(args, params, return_unknown, calling_module, calling_function)
	local args_new = {}
	
	if not calling_module then
		track("no calling module")
	end
	if not calling_function then
		track("no calling function", calling_module)
	end
	
	-- Process parameters for specific properties
	local required = {}
	local patterns = {}
	local names_with_equal_sign = {}
	local list_from_index = nil
	
	for name, param in pairs(params) do
		if param.required then
			if param.alias_of then
				track("required alias", calling_module, calling_function, name)
			end
			required[name] = true
		end
		
		if param.list then
			-- A helper function to escape magic characters in a string
			-- Magic characters: ^$()%.[]*+-?
			local plain = require("string/pattern_escape")

			local key = name
			if type(name) == "string" then
				key = string.gsub(name, "=", "")
			end
			-- _list is used as a temporary type flag.
			args_new[key] = {maxindex = 0, _list = true}
			
			if type(param.list) == "string" then
				-- If the list property is a string, then it represents the name
				-- to be used as the prefix for list items. This is for use with lists
				-- where the first item is a numbered parameter and the
				-- subsequent ones are named, such as 1, pl2, pl3.
				if string.find(param.list, "=") then
					patterns["^" .. string.gsub(plain(param.list), "=", "(%%d+)") .. "$"] = name
				else
					patterns["^" .. plain(param.list) .. "(%d+)$"] = name
				end
			elseif type(name) == "number" then
				-- If the name is a number, then all indexed parameters from
				-- this number onwards go in the list.
				list_from_index = name
			else
				if string.find(name, "=") then
					patterns["^" .. string.gsub(plain(name), "=", "(%%d+)") .. "$"] = string.gsub(name, "=", "")
				else
					patterns["^" .. plain(name) .. "(%d+)$"] = name
				end
			end
			
			if string.find(name, "=") then
				-- DO NOT SIDE-EFFECT A TABLE WHILE ITERATING OVER IT.
				-- Some elements may be skipped or processed twice if you do.
				-- Instead, track the changes we want to make to `params`, and
				-- do them after the iteration over `params` is done.
				insert(names_with_equal_sign, name)
			end
		end
	end

	--Process required changes to `params`.
	if #names_with_equal_sign > 0 then
		for i = 1, #names_with_equal_sign do
			local name = names_with_equal_sign[i]
			params[name:gsub("=", "")] = params[name]
			params[name] = nil
		end
	end

	-- Process the arguments
	local args_unknown = {}
	local max_index
	
	for name, val in pairs(args) do
		local index = nil
		
		if type(name) == "number" then
			if list_from_index ~= nil and name >= list_from_index then
				index = name - list_from_index + 1
				name = list_from_index
			end
		else
			-- Does this argument name match a pattern?
			for pattern, pname in pairs(patterns) do
				index = mw.ustring.match(name, pattern)
				
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
		
		-- If a parameter without the trailing index was found, and
		-- require_index is set on the param, set the param to nil to treat it
		-- as if it isn't recognized.
		if not index and param and param.require_index then
			param = nil
		end
		
		-- If no index was found, use 1 as the default index.
		-- This makes list parameters like g, g2, g3 put g at index 1.
		-- If `separate_no_index` is set, then use 0 as the default instead.
		index = index or (param and param.separate_no_index and 0) or 1
		
		-- If the argument is not in the list of parameters, trigger an error.
		-- return_unknown suppresses the error, and stores it in a separate list instead.
		if not param then
			if return_unknown then
				args_unknown[name] = val
			else
				error("The parameter \"" .. name .. "\" is not used by this template.", 2)
			end
		else
			if params.alias_of and not params[param.alias_of] then
				error("The parameter \"" .. name .. "\" is an alias of an invalid parameter.")
			end
			
			-- Remove leading and trailing whitespace unless allow_whitespace is true.
			if not param.allow_whitespace then
				val = mw.text.trim(val)
			end
			
			-- Empty string is equivalent to nil unless allow_empty is true.
			if val == "" and not param.allow_empty then
				val = nil
				-- Track empty parameters, unless (1) allow_empty is set or (2) they're numbered parameters where a higher numbered parameter is also in use (e.g. track {{l|en|term|}}, but not {{l|en||term}}).
				if type(name) == "number" and not max_index then
					-- Find the highest numbered parameter that's in use/an empty string, as we don't want parameters like 500= to mean we can't track any empty parameters with a lower index than 500.
					local max_contiguous_index = 0
					while args[max_contiguous_index + 1] do
						max_contiguous_index = max_contiguous_index + 1
					end
					if max_contiguous_index > 0 then
						for name, val in pairs(args) do
							if type(name) == "number" and name > 0 and name <= max_contiguous_index and ((not max_index) or name > max_index) and val ~= "" then
								max_index = name
							end
						end
					end
					max_index = max_index or 0
				end
				if type(name) ~= "number" or name > max_index then
					track("empty parameter", calling_module, calling_function, name)
				end
			end
			
			-- Convert to proper type if necessary.
			if param.type == "boolean" then
				val = require("yesno")(val, true)
			elseif param.type == "lang" then
				local lang = require("languages").getByCode(val, nil, param.etym_lang, param.family)
				if not lang then
					local list = {"language"}
					if param.allowEtymLang then
						insert(list, "etymology language")
					end
					if param.allowFamily then
						insert(list, "family")
					end
					list = mw.text.listToText( list, nil, " or " )
					error("The parameter \"" .. name .. index .. "\" should be a valid " .. list .. " code; the value '" .. val .. "' is not valid.")
				end
				val = lang
			elseif param.type == "family" then
				local fam = require("families").getByCode(val)
				if not fam then
					error("The parameter \"" .. name .. index .. "\" should be a valid family code; the value '" .. val .. "' is not valid.")
				end
				val = fam
			elseif param.type == "script" then
				local sc = require("scripts").getByCode(val)
				if not sc then
					error("The parameter \"" .. name .. index .. "\" should be a valid script code; the value '" .. val .. "' is not valid.")
				end
				val = sc
			elseif param.type == "number" then
				val = tonumber(val)
			elseif param.type then
				track("unrecognized type", calling_module, calling_function, name)
				track("unrecognized type/" .. tostring(param.type), calling_module, calling_function, name)
			end
			
			-- Can't use "if val" alone, because val may be a boolean false.
			if val ~= nil then
				-- Mark it as no longer required, as it is present.
				required[param.alias_of or name] = nil
				
				-- Store the argument value.
				if param.list then
					-- If the parameter is an alias of another, store it as the original,
					-- but avoid overwriting it; the original takes precedence.
					if not param.alias_of then
						-- If the parameter is duplicated, throw an error.
						if args_new[name][index] then
							error("The parameter \"" .. name .. index .. "\" has been entered more than once. This is probably because a list parameter has been entered without an index and with index 1 at the same time.")
						end
						args_new[name][index] = val
						
						-- Store the highest index we find.
						args_new[name].maxindex = math.max(index, args_new[name].maxindex)
						if args_new[name][0] ~= nil then
							args_new[name].default = args_new[name][0]
							if args_new[name].maxindex == 0 then
								args_new[name].maxindex = 1
							end
							args_new[name][0] = nil
						end
					else
						-- If the parameter is duplicated, throw an error.
						if args_new[param.alias_of][index] ~= nil then
							error("The parameter \"" .. param.alias_of .. index .. "\" has been entered more than once. This could be due to an parameter alias being used, or a list parameter being entered without an index and with index 1 at the same time.")
						end
						if params[param.alias_of].list then
							args_new[param.alias_of][index] = val
							
							-- Store the highest index we find.
							args_new[param.alias_of].maxindex = math.max(index, args_new[param.alias_of].maxindex)
						else
							args_new[param.alias_of] = val
						end
					end
				else
					-- If the parameter is duplicated, throw an error.
					if args_new[name] ~= nil then
						error("The parameter \"" .. name .. "\" has been entered more than once. This is probably because of a parameter alias being used.")
					end
					
					if not param.alias_of then
						args_new[name] = val
					else
						if params[param.alias_of].list then
							args_new[param.alias_of][1] = val
							
							-- Store the highest index we find.
							args_new[param.alias_of].maxindex = math.max(1, args_new[param.alias_of].maxindex)
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
			if type(args_new[name]) == "table" then
				if args_new[name][1] == nil then
					args_new[name][1] = param.default
				end
				if args_new[name].maxindex == 0 then
					args_new[name].maxindex = 1
				end
			elseif args_new[name] == nil then
				args_new[name] = param.default
			end
		end
	end
	
	-- The required table should now be empty.
	-- If any entry remains, trigger an error, unless we're in the template namespace.
	if mw.title.getCurrentTitle().namespace ~= 10 then
		local list = {}
		for name in pairs(required) do
			insert(list, name)
		end
		if #list > 0 then
			error('The parameters "' .. mw.text.listToText(list, '", "', '" and "') .. '" are required.', 2)
		end
	end
	
	-- Remove holes in any list parameters if needed.
	for name, val in pairs(args_new) do
		if type(val) == "table" and val._list then
			if params[name].disallow_holes then
				local highest = 0
				for num, _ in pairs(val) do
					if type(num) == "number" and num > 0 and num < math.huge and math.floor(num) == num then
						highest = math.max(highest, num)
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
				args_new[name] = require("parameters/remove_holes")(val)
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