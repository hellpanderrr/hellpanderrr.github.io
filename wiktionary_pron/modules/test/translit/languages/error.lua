
--[=[
Throw an error for an invalid language code or script code.

`lang_code` (required) is the bad code and can be nil or a non-string.

`param` (required) is the name of the parameter in which the code was contained. It can be a string, a number (for a
	numeric param, in which case the param will show up in the error message as an ordinal such as "first" or "second"),
	or `true` if no parameter can be clearly identified. It can also be a function of one argument (an error message) or
	two arguments (an error message and a number of stack frames to ignore, same as in the error() function itself), in
	which case the function will be called with the same error message as if `true` were passed in. (This is useful e.g.
	when parsing inline modifiers, where the parameter name may not be available or may not be so clearly identifiable,
	but an error function is often available.)

`code_desc` (optional) is text describing what the code is; by default, "language code".

`template_text` (optional) is a string specifying the template that generated the error, or a function
	to generate this string. If given, it will be displayed in the error message.

`not_real_lang` (optional), if given, indicates that the code is not in the form of a language code
	(e.g. it's a script code). Normally, this function checks for things that could plausibly be a language code:
	two or three lowercase letters, two or three groups of three lowercase letters with hyphens between them.
	If such a pattern is found, a different error message is displayed (indicating an invalid code) than otherwise
	(indicating a missing code). If `not_real_lang` is given, this check is suppressed.
]=]

return function(lang_code, param, code_desc, template_tag, not_real_lang)
	local ordinals = {
		"first", "second", "third", "fourth", "fifth", "sixth",
		"seventh", "eighth", "ninth", "tenth", "eleventh", "twelfth",
		"thirteenth", "fourteenth", "fifteenth", "sixteenth", "seventeenth",
		"eighteenth", "nineteenth", "twentieth"
	}
	
	code_desc = code_desc or "language code"

	local param_type = type(param)
	if not template_tag then
		template_tag = ""
	else
		if type(template_tag) ~= "string" then
			template_tag = template_tag()
		end
		template_tag = " (original template: " .. template_tag .. ")"
	end
	local function err(msg)
		msg = msg .. template_tag
		if param_type == "function" then
			param(msg, 3)
		else
			error(msg .. template_tag .. ".", 3)
		end
	end
	local in_the_param
	if param == true or param_type == "function" then
		-- handled specially below
		in_the_param = ""
	else
		if param_type == "number" then
			if ordinals[param] then
				param = ordinals[param] .. " parameter"
			else
				param = " parameter " .. param
			end
		elseif param_type == "string" then
			param = 'parameter "' .. param .. '"'
		else
			err("The parameter name is "
					.. (param_type == "table" and "a table" or tostring(param))
					.. ", but it should be a number or a string")
		end
		in_the_param = " in the " .. param
	end
	
	if not lang_code or lang_code == "" then
		if param == true or param_type == "function" then
			err("The " .. code_desc .. " is missing")
		else
			err("The " .. param .. " (" .. code_desc .. ") is missing")
		end
	elseif type(lang_code) ~= "string" then
		err("The " .. code_desc .. in_the_param .. " is supposed to be a string but is a " .. type(lang_code))
	-- Can use string.find because language codes only contain ASCII.
	elseif not_real_lang or lang_code:find("^%l%l%l?$")
			or lang_code:find("^%l%l%l%-%l%l%l$")
			or lang_code:find("^%l%l%l%-%l%l%l%-%l%l%l$") then
		err("The " .. code_desc .. " \"" .. lang_code .. "\"" .. in_the_param .. " is not valid (see [[Wiktionary:List of languages]])")
	else
		err("Please specify a " .. code_desc .. in_the_param .. "; the value \"" .. lang_code .. "\" is not valid (see [[Wiktionary:List of languages]])")
	end
end