local gmatch = string.gmatch
local mw = require('mw')
local module_name = "string_utilities"

local export = {}
local char = mw.ustring.char

local concat = table.concat
local format_escapes = {
	["op"] = "{",
	["cl"] = "}",
}

function export.format_fun(str, fun)
	return (str:gsub("{(\\?)((\\?)[^{}]*)}", function (p1, name, p2)
		if #p1 + #p2 == 1 then
			return format_escapes[name] or error(module_name .. ".format: unrecognized escape sequence '{\\" .. name .. "}'")
		else
			if fun(name) and type(fun(name)) ~= "string" then
				error(module_name .. ".format: '" .. name .. "' is a " .. type(fun(name)) .. ", not a string")
			end
			return fun(name) or error(module_name .. ".format: '" .. name .. "' not found in table")
		end
	end))
end

--[==[This function, unlike {{code|lua|string.format}} and {{code|lua|mw.ustring.format}}, takes just two parameters—a format string and a table—and replaces all instances of {{code|lua|{param_name}}} in the format string with the table's entry for {{code|lua|param_name}}. The opening and closing brace characters can be escaped with <code>{\op}</code> and <code>{\cl}</code>, respectively. A table entry beginning with a slash can be escaped by doubling the initial slash.
====Examples====
* {{code|lua|2=string_utilities.format("{foo} fish, {bar} fish, {baz} fish, {quux} fish", {["foo"]="one", ["bar"]="two", ["baz"]="red", ["quux"]="blue"})}}
*: produces: {{code|lua|"one fish, two fish, red fish, blue fish"}}
* {{code|lua|2=string_utilities.format("The set {\\op}1, 2, 3{\\cl} contains {\\\\hello} elements.", {["\\hello"]="three"})}}
*: produces: {{code|lua|"The set {1, 2, 3} contains three elements."}}
*:* Note that the single and double backslashes should be entered as double and quadruple backslashes when quoted in a literal string.]==]
function export.format(str, tbl)
	return export.format_fun(str, function (key) return tbl[key] end)
end

--[==[Explodes a string into an array of UTF8 characters. '''Warning''': this function has no safety checks for non-UTF8 byte sequences, to optimize speed and memory use. Inputs containing them therefore result in undefined behaviour.]==]
function export.explode_utf8(str)
	local text,  i = {}, 0
	for char in gmatch(str, "[%z\1-\127\194-\244][\128-\191]*") do
    	i = i + 1
		text[i] = char
	end
	return text
end

-- A helper function which takes a string, position and type ("byte" or "char"), and returns the equivalent position for the other type (e.g. iterate_utf8("字典", 2, "char") returns 4, because character 2 of "字典" begins with byte 4). `pos` can be positive or negative, and the function will iterate over the string forwards or backwards (respectively) until it reaches the input position. Checks byte-by-byte; skipping over trailing bytes, and then calculating the correct byte trail for any leading bytes (i.e. how many trailing bytes should follow); these trailing bytes are then checked together.
-- The optional parameters `init_from_type` and `init_to_type` can be used to start part-way through an iteration to improve performance, if multiple values need to be returned from the same string. For example, iterate_utf8("слова́рь", 11, "byte", 5, 3) will begin checking at byte 5/the start of character 3. Note: The function won't check if these values match each other (as the only way to do this would be to run the iteration from the beginning), so mismatched values will return incorrect results.
local function iterate_utf8(text, pos, from_type, init_from_type, init_to_type)
	-- Position 0 is always valid and never changes.
	if pos == 0 then
		return pos
	end
	
	local to_type
	if from_type == "char" then
		to_type = "byte"
	else
		to_type = "char"
	end
	
	-- Positive positions iterate forwards; negative positions iterate backwards.
	local iterate_val
	if pos > 0 then
		iterate_val = 1
	else
		iterate_val = -1
	end
	
	-- Adjust init_from_type and init_to_type to the iteration before, so that matches for the position given by them will work.
	local trail, cp, min, b = 0
	local c, leading_byte = {}
	c[from_type] = init_from_type and init_from_type ~= 0 and init_from_type - iterate_val or 0
	c[to_type] = init_to_type and init_to_type ~= 0 and init_to_type - iterate_val or 0
	
	while true do
		if pos > 0 then
			b = text:byte(c.byte + 1)
		else
			b = text:byte(text:len() + c.byte)
		end
		-- Position byte doesn't exist, so iterate the return value and return it.
		if not b then
			return c[to_type] + iterate_val
		elseif b < 0x80 then
			-- 1-byte codepoint, 00-7F.
			trail = 0
			cp = b
			min = 0
			leading_byte = true
		elseif b < 0xc0 then
			-- A trailing byte.
			leading_byte = false
		elseif b < 0xc2 then
			-- An overlong encoding for a 1-byte codepoint.
			error("String " .. text .. " is not UTF-8.")
		elseif b < 0xe0 then
			-- 2-byte codepoint, C2-DF.
			trail = 1
			cp = b - 0xc0
			min = 0x80
			leading_byte = true
		elseif b < 0xf0 then
			-- 3-byte codepoint, E0-EF.
			trail = 2
			cp = b - 0xe0
			min = 0x800
			leading_byte = true
		elseif b < 0xf4 then
			-- 4-byte codepoint, F0-F3.
			trail = 3
			cp = b - 0xf0
			min = 0x10000
			leading_byte = true
		elseif b == 0xf4 then
			-- 4-byte codepoint, F4.
			-- Make sure it doesn't decode to over U+10FFFF.
			if text:byte(c.byte + 2) > 0x8f then
				error("String " .. text .. " is not UTF-8.")
			end
			trail = 3
			cp = 4
			min = 0x100000
			leading_byte = true
		else
			-- Codepoint over U+10FFFF, or invalid byte.
			error("String " .. text .. " is not UTF-8.")
		end
		
		-- Check subsequent bytes for multibyte codepoints.
		if leading_byte then
			local from, to
			if pos > 0 then
				from, to = c.byte + 2, c.byte + 1 + trail
			else
				from, to = text:len() + c.byte + 1, text:len() + c.byte + trail
			end
			for trailing_byte = from, to do
				b = text:byte(trailing_byte)
				if not b or b < 0x80 or b > 0xbf then
					error("String " .. text .. " is not UTF-8.")
				end
				cp = cp * 0x40 + b - 0x80
			end
			local next_byte = text:byte(to + 1)
			if next_byte and next_byte >= 0x80 and next_byte <= 0xbf then
				-- Too many trailing bytes.
				error("String " .. text .. " is not UTF-8.")
			elseif cp < min then
				-- Overlong encoding.
				error("String " .. text .. " is not UTF-8.")
			end
		end
		
		c.byte = c.byte + iterate_val
		if leading_byte then
			c.char = c.char + iterate_val
		end
		
		if c[from_type] == pos then
			return c[to_type]
		end
	end
end

function export.reverse(str)
    return reverse(gsub(str, "[\194-\244][\128-\191]*", reverse))
end

do
    local function err(cp)
        error("Codepoint " .. cp .. " is out of range: codepoints must be between 0x0 and 0x10FFFF.", 2)
    end

    local function round(number)
        if (number - (number % 0.1)) - (number - (number % 1)) < 0.5 then
            number = number - (number % 1)
        else
            number = (number - (number % 1)) + 1
        end
        return number
    end

    local function utf8_char(cp)
        cp = tonumber(cp)

        if cp < 0 then
            err("-0x" .. format("%X", -cp + 1))
        elseif cp < 0x80 then
            return char(cp)
        elseif cp < 0x800 then
            return char(
                    0xC0 + cp / 0x40,
                    0x80 + cp % 0x40
            )
        elseif cp < 0x10000 then
            if cp >= 0xD800 and cp < 0xE000 then
                return "?" -- mw.ustring.char returns "?" for surrogates.
            end
            return char(
                    0xE0 + cp / 0x1000,
                    0x80 + cp / 0x40 % 0x40,
                    0x80 + cp % 0x40
            )
        elseif cp < 0x110000 then
            return char(
                    0xF0 + cp / 0x40000,
                    0x80 + cp / 0x1000 % 0x40,
                    0x80 + cp / 0x40 % 0x40,
                    0x80 + cp % 0x40
            )
        end
        err("0x" .. format("%X", cp))
    end

    function export.char(cp, ...)
        if ... == nil then
            local utf8 = utf8_char(cp)
            return utf8
        end
        local ret = { cp, ... }
        for i = 1, select("#", cp, ...) do
            ret[i] = utf8_char(ret[i])
        end
        return concat(ret)
    end
    u = export.char
end

--[==[Converts a character position to the equivalent byte position.]==]
function export.charsToBytes(text, pos)
	return iterate_utf8(text, pos, "char")
end

--[==[Converts a byte position to the equivalent character position.]==]
function export.bytesToChars(text, pos)
	local byte = text:byte(pos)
	if byte and byte >= 0x80 and byte <= 0xbf then
		error("Byte " .. pos .. " is not a leading byte.")
	end
	return iterate_utf8(text, pos, "byte")
end

-- A helper function which iterates through a pattern, and returns two values: a potentially modified version of the pattern, and a boolean indicating whether the returned pattern is simple (i.e. whether it can be used with the stock string library); if not, then the pattern is complex (i.e. it must be used with the ustring library, which is much more resource-intensive).
local function patternSimplifier(text, pattern, plain)
	pattern = tostring(pattern)
	-- If `plain` is set, then the pattern is treated as literal (so is always simple). Only used by find.
	if plain then
		return pattern, true
	--If none of these are present, then the pattern has to be simple.
	elseif not (
		pattern:match("%[.-[\128-\255].-%]") or
		pattern:match("[\128-\255][%*%+%?%-]") or
		pattern:match("%%[abcdlpsuwxACDLPSUWXZ]") or
		pattern:match("%[%^[^%]]+%]") or
		pattern:match("%.[^%*%+%-]") or
		pattern:match("%.$") or
		pattern:match("%%b.?[\128-\255]") or
		pattern:match("()", 1, true)
	) then
		return pattern, true
	end
	-- Otherwise, the pattern could go either way.
	-- Build up the new pattern in a table, then concatenate at the end. we do it this way, as occasionally entries get modified along the way.
	local new_pattern = {}
	local len, pos, b = pattern:len(), 0
	local char, next_char
	
	-- `escape` and `balanced` are counters, which ensure the effects of % or %b (respectively) are distributed over the following bytes.
	-- `set` is a boolean that states whether the current byte is in a charset.
	-- `capture` keeps track of how many layers of capture groups the position is in, while `captures` keeps a tally of how many groups have been detected (due to the string library limit of 32).
	local escape, set, balanced, capture, captures = 0, false, 0, 0, 0
	
	while pos < len do
		pos = pos + 1
		b = pattern:byte(pos)
		if escape > 0 then escape = escape - 1 end
		if balanced > 0 then balanced = balanced - 1 end
		char = next_char or pattern:sub(pos, pos)
		next_char = pattern:sub(pos + 1, pos + 1)
		if escape == 0 then
			if char == "%" then
				-- Apply % escape.
				if next_char == "." or next_char == "%" or next_char == "[" or next_char == "]" then
					escape = 2
					if balanced > 0 then balanced = balanced + 1 end
				-- These charsets make the pattern complex.
				elseif next_char:match("[acdlpsuwxACDLPSUWXZ]") then
					return pattern, false
				-- This is "%b".
				elseif next_char == "b" then
					balanced = 4
				end
			-- Enter or leave a charset.
			elseif char == "[" then
				set = true
			elseif char == "]" then
				set = false
			elseif char == "(" then
				capture = capture + 1
			elseif char == ")" then
				if capture > 0 and set == false and balanced == 0 then
					captures = captures + 1
					capture = capture - 1
				end
			end
		end
		
		-- Multibyte char.
		if b > 0x7f then
			-- If followed by "*", "+" or "-", then 2-byte chars can be converted into charsets. However, this is not possible with 3 or 4-byte chars, as the charset would be too permissive, because if the trailing bytes were in a different order then this could be a different valid character.
			if next_char == "*" or next_char == "+" or next_char == "-" then
				local prev_pos = pattern:byte(pos - 1)
				if prev_pos > 0xc1 and prev_pos < 0xe0 then
					new_pattern[#new_pattern] = "[" .. new_pattern[#new_pattern]
					table.insert(new_pattern, char .. "]")
				else
					return pattern, false
				end
			-- If in a charset or used in "%b", then the pattern is complex.
			-- If followed by "?", add "?" after each byte.
			elseif next_char == "?" then
				table.insert(new_pattern, char .. "?")
				local check_pos, check_b, i = pos, pattern:byte(pos), #new_pattern
				while check_b and check_b < 0xc0 do
					check_pos = check_pos - 1
					check_b = pattern:byte(check_pos)
					i = i - 1
					new_pattern[i] = new_pattern[i] .. "?"
				end
				pos = pos + 1
				next_char = pattern:sub(pos + 1, pos + 1)
			elseif set or balanced > 0 then
				return pattern, false
			else
				table.insert(new_pattern, char)
			end
		elseif char == "." then
			-- "*", "+", "-" are always okay after ".", as they don't care how many bytes a char has.
			if set or next_char == "*" or next_char == "+" or next_char == "-" or escape > 0 then
				table.insert(new_pattern, char)
			-- If followed by "?", make sure "?" is after the leading byte of the UTF-8 char pattern, then skip forward one.
			elseif next_char == "?" then
				table.insert(new_pattern, "[%z\1-\127\194-\244]?[\128-\191]*")
				pos = pos + 1
				next_char = pattern:sub(pos + 1, pos + 1)
			-- If used with "%b", pattern is complex.
			elseif balanced > 0 then
				return pattern, false
			-- Otherwise, add the UTF-8 char pattern.
			else
				table.insert(new_pattern, "[%z\1-\127\194-\244][\128-\191]*")
			end
		-- Negative charsets are always complex, unless the text has no UTF-8 chars.
		elseif char == "[" and next_char == "^" and escape == 0 and text:match("[\128-\255]") then
			return pattern, false
		-- "()" matches the position unless escaped or used with "%b", so always necessitates ustring (as we need it to match the char position, not the byte one).
		elseif char == "(" and next_char == ")" and balanced == 0 and escape == 0 and text:match("[\128-\255]") then
			return pattern, false
		else
			table.insert(new_pattern, char)
		end
	end
	if captures > 32 then
		return pattern, false
	else
		pattern = table.concat(new_pattern)
		return pattern, true
	end
end

--[==[A version of len which uses string.len, but returns the same result as mw.ustring.len.]==]
function export.len(text)
	text = tostring(text)
	local len_bytes = text:len()
	if not text:match("[\128-\255]") then
		return len_bytes
	else
		return iterate_utf8(text, len_bytes, "byte")
	end
end

--[==[A version of sub which uses string.sub, but returns the same result as mw.ustring.sub.]==]
function export.sub(text, i_char, j_char)
	text = tostring(text)
	if not text:match("[\128-\255]") then
		return text:sub(i_char, j_char)
	end
	local i_byte, j_byte
	if j_char then
		if i_char > 0 and j_char > 0 then
			if j_char < i_char then return "" end
			i_byte = iterate_utf8(text, i_char, "char")
			j_byte = iterate_utf8(text, j_char + 1, "char", i_char, i_byte) - 1
		elseif i_char < 0 and j_char < 0 then
			if j_char < i_char then return "" end
			j_byte = iterate_utf8(text, j_char + 1, "char") - 1
			i_byte = iterate_utf8(text, i_char, "char", j_char, j_byte)
		-- For some reason, mw.ustring.sub with i=0, j=0 returns the same result as for i=1, j=1, while string.sub always returns "". However, mw.ustring.sub does return "" with i=1, j=0. As such, we need to adjust j_char to 1 if i_char is either 0, or negative with a magnitude greater than the length of the string.
		elseif j_char == 0 then
			i_byte = iterate_utf8(text, i_char, "char")
			if i_byte == 0 or -i_byte > text:len() then j_char = 1 end
			j_byte = iterate_utf8(text, j_char + 1, "char") - 1
		else
			i_byte = iterate_utf8(text, i_char, "char")
			j_byte = iterate_utf8(text, j_char + 1, "char") - 1
		end
	else
		i_byte = iterate_utf8(text, i_char, "char")
	end
	return text:sub(i_byte, j_byte)
end

--[==[A version of lower which uses string.lower when possible, but otherwise uses mw.ustring.lower.]==]
function export.lower(text)
	text = tostring(text)
	if not text:match("[\128-\255]") then
		return text:lower()
	else
		return mw.ustring.lower(text)
	end
end

--[==[A version of upper which uses string.upper when possible, but otherwise uses mw.ustring.upper.]==]
function export.upper(text)
	text = tostring(text)
	if not text:match("[\128-\255]") then
		return text:upper()
	else
		return mw.ustring.upper(text)
	end
end

--[==[A version of find which uses string.find when possible, but otherwise uses mw.ustring.find.]==]
function export.find(text, pattern, init_char, plain)
	text = tostring(text)
	local simple
	pattern, simple = patternSimplifier(text, pattern, plain)
	-- If the pattern is simple but multibyte characters are present, then init_char needs to be converted into bytes for string.find to work properly, and the return values need to be converted back into chars.
	if simple then
		if not text:match("[\128-\255]") then
			return text:find(pattern, init_char, plain)
		else
			local init_byte = init_char and iterate_utf8(text, init_char, "char")
			local byte1, byte2, c1, c2, c3, c4, c5, c6, c7, c8, c9 = text:find(pattern, init_byte, plain)
			
			-- If string.find returned nil, then return nil.
			if not (byte1 and byte2) then
				return nil
			end
			
			-- Get first return value. If we have a positive init_char, we can save resources by resuming at that point.
			local char1, char2
			if (not init_char) or init_char > 0 then
				char1 = iterate_utf8(text, byte1, "byte", init_byte, init_char)
			else
				char1 = iterate_utf8(text, byte1, "byte")
			end
			
			-- If byte1 and byte2 are the same, don't bother running iterate_utf8 twice. Otherwise, resume iterate_utf8 from byte1 to find char2.
			if byte1 == byte2 then
				char2 = char1
			else
				char2 = iterate_utf8(text, byte2, "byte", byte1, char1)
			end
			
			return unpack{char1, char2, c1, c2, c3, c4, c5, c6, c7, c8, c9}
		end
	else
		return mw.ustring.find(text, pattern, init_char, plain)
	end
end

--[==[A version of match which uses string.match when possible, but otherwise uses mw.ustring.match.]==]
function export.match(text, pattern, init)
	text = tostring(text)
	local simple
	pattern, simple = patternSimplifier(text, pattern)
	if simple then
		if init and text:find("[\128-\255]") then
			init = iterate_utf8(text, init, "char")
		end
		return text:match(pattern, init)
	else
		return mw.ustring.match(text, pattern, init)
	end
end

--[==[A version of gmatch which uses string.gmatch when possible, but otherwise uses mw.ustring.gmatch.]==]
function export.gmatch(text, pattern)
	text = tostring(text)
	local simple
	pattern, simple = patternSimplifier(text, pattern)
	if simple then
		return gmatch(text, pattern)
	else
		return mw.ustring.gmatch(text, pattern)
	end
end

--[==[A version of gsub which uses string.gsub when possible, but otherwise uses mw.ustring.gsub.]==]
function export.gsub(text, pattern, repl, n)
	text = tostring(text)
	local simple
	pattern, simple = patternSimplifier(text, pattern)
	if simple then
		return text:gsub(pattern, repl, n)
	else
		return mw.ustring.gsub(text, pattern, repl, n)
	end
end

--[==[
-- Reimplementation of mw.ustring.split() that includes any capturing
-- groups in the splitting pattern. This works like Python's re.split()
-- function, except that it has Lua's behavior when the split pattern
-- is empty (i.e. advancing by one character at a time; Python returns the
-- whole remainder of the string).
]==]
function export.capturing_split(str, pattern)
	local ret = {}
	-- (.-) corresponds to (.*?) in Python or Perl; () captures the
	-- current position after matching.
	pattern = "(.-)" .. pattern .. "()"
	local start = 1
	while true do
		-- Did we reach the end of the string?
		if start > #str then
			table.insert(ret, "")
			return ret
		end
		-- match() returns all captures as multiple return values;
		-- we need to insert into a table to get them all.
		local captures = {export.match(str, pattern, start)}
		-- If no match, add the remainder of the string.
		if #captures == 0 then
			table.insert(ret, export.sub(str, start))
			return ret
		end
		local newstart = table.remove(captures)
		-- Special case: If we don't advance by any characters, then advance
		-- by one character; this avoids an infinite loop, and makes splitting
		-- by an empty string work the way mw.ustring.split() does. If we
		-- reach the end of the string this way, return immediately, so we
		-- don't get a final empty string.
		if newstart == start then
			table.insert(ret, export.sub(str, start, start))
			table.remove(captures, 1)
			start = start + 1
			if start > #str then
				return ret
			end
		else
			table.insert(ret, table.remove(captures, 1))
			start = newstart
		end
		-- Insert any captures from the splitting pattern.
		for _, x in ipairs(captures) do
			table.insert(ret, x)
		end
	end
end

local function uclcfirst(text, dolower)
	local function douclcfirst(text)
		-- Actual function to re-case of the first letter.
		local first_letter = export.sub(text, 1, 1)
		first_letter = dolower and export.lower(first_letter) or export.upper(first_letter)
		return first_letter .. export.sub(text, 2)
	end
	-- If there's a link at the beginning, re-case the first letter of the
	-- link text. This pattern matches both piped and unpiped links.
	-- If the link is not piped, the second capture (linktext) will be empty.
	local link, linktext, remainder = export.match(text, "^%[%[([^|%]]+)%|?(.-)%]%](.*)$")
	if link then
		return "[[" .. link .. "|" .. douclcfirst(linktext ~= "" and linktext or link) .. "]]" .. remainder
	end
	return douclcfirst(text)
end

function export.ucfirst(text)
	return uclcfirst(text, false)
end

function export.lcfirst(text)
	return uclcfirst(text, true)
end

-- Faster version of mw.text.nowiki, with minor changes to match the PHP equivalent: ";" always escapes, and colons in unslashed protocols only escape after regex \b.
do
	local function escape_char(str1, str2)
		if str2 then
			return str1 .. "&#" .. str2:byte() .. ";"
		end
		return "&#" .. str1:byte() .. ";"
	end
	
	local function escape_uri(uri)
		local uri_schemes = mw.loadData("string utilities/data").uri_schemes
		return uri_schemes[uri:lower()] and uri .. "&#58;" or uri .. ":"
	end
	
	function export.nowiki(text)
		return (text
			:gsub("[\"&';<=>%[%]{|}]", escape_char)
			:gsub("^[\t\n\r #%*:]", escape_char)
			:gsub("([\n\r])([\t\n\r #%*:])", escape_char)
			:gsub("%f[^%z\r\n]%-(%-%-%-)", "&#45;%1")
			:gsub("__", "_&#95;")
			:gsub("://", "&#58;//")
			:gsub("(ISBN)(%s)", escape_char)
			:gsub("(PMID)(%s)", escape_char)
			:gsub("(RFC)(%s)", escape_char)
			:gsub("([%w_]+):", escape_uri))
	end
end

function export.capitalize(text)
	if type(text) == "table" then
		-- allow calling from a template
		text = text.args[1]
	end
	-- Capitalize multi-word that is separated by spaces
	-- by uppercasing the first letter of each part.
	-- I assume nobody will input all CAP text.
	w2 = {}
	for w in export.gmatch(text, "%S+") do
		table.insert(w2, uclcfirst(w, false))
	end
	return table.concat(w2, " ")
end

function export.pluralize(text)
	if type(text) == "table" then
		-- allow calling from a template
		text = text.args[1]
	end
	-- Pluralize a word in a smart fashion, according to normal English rules.
	-- 1. If word ends in consonant + -y, replace the -y with -ies.
	-- 2. If the word ends in -s, -x, -z, -sh, -ch, add -es.
	-- 3. Otherwise, add -s.
	-- This handles links correctly:
	-- 1. If a piped link, change the second part appropriately.
	-- 2. If a non-piped link and rule #1 above applies, convert to a piped link
	--    with the second part containing the plural.
	-- 3. If a non-piped link and rules #2 or #3 above apply, add the plural
	--    outside the link.
	
	local function word_ends_in_consonant_plus_y(text)
		-- FIXME, a subrule of rule #1 above says the -ies ending doesn't
		-- apply to proper nouns, hence "the Gettys", "the public Ivys".
		-- We should maybe consider applying this rule here; but it may not
		-- be important as this function is almost always called on common nouns
		-- (e.g. parts of speech, place types).
		return text:find("[^aeiouAEIOU ]y$")
	end
	
	local function word_takes_es_plural(text)
		return text:find("[sxz]$") or text:find("[cs]h$")
	end
	
	local function do_pluralize(text)
		if word_ends_in_consonant_plus_y(text) then
			-- avoid returning multiple values
			local hack_single_retval = text:gsub("y$", "ies")
			return hack_single_retval
		elseif word_takes_es_plural(text) then
			return text .. "es"
		else
			return text .. "s"
		end
	end
		
	-- Check for a link. This pattern matches both piped and unpiped links.
	-- If the link is not piped, the second capture (linktext) will be empty.
	local beginning, link, linktext = export.match(text, "^(.*)%[%[([^|%]]+)%|?(.-)%]%]$")
	if link then
		if linktext ~= "" then
			return beginning .. "[[" .. link .. "|" .. do_pluralize(linktext) .. "]]"
		end
		if word_ends_in_consonant_plus_y(link) then
			return beginning .. "[[" .. link .. "|" .. link:gsub("y$", "ies") .. "]]"
		end
		return beginning .. "[[" .. link .. "]]" .. (word_takes_es_plural(link) and "es" or "s")
	end
	return do_pluralize(text)
end

function export.singularize(text)
	if type(text) == "table" then
		-- allow calling from a template
		text = text.args[1]
	end
	-- Singularize a word in a smart fashion, according to normal English rules.
	-- Works analogously to pluralize().
	-- NOTE: This doesn't always work as well as pluralize(). Beware. It will
	-- mishandle cases like "passes" -> "passe", "eyries" -> "eyry".
	-- 1. If word ends in -ies, replace -ies with -y.
	-- 2. If the word ends in -xes, -shes, -ches, remove -es. [Does not affect
	--    -ses, cf. "houses", "impasses".]
	-- 3. Otherwise, remove -s.
	-- This handles links correctly:
	-- 1. If a piped link, change the second part appropriately. Collapse the
	--    link to a simple link if both parts end up the same.
	-- 2. If a non-piped link, singularize the link.
	-- 3. A link like "[[parish]]es" will be handled correctly because the
	--    code that checks for -shes etc. allows ] characters between the
	--    'sh' etc. and final -es.
	local function do_singularize(text)
		local sing = text:match("^(.-)ies$")
		if sing then
			return sing .. "y"
		end
		-- Handle cases like "[[parish]]es"
		local sing = text:match("^(.-[sc]h%]*)es$")
		if sing then
			return sing
		end
		-- Handle cases like "[[box]]es"
		local sing = text:match("^(.-x%]*)es$")
		if sing then
			return sing
		end
		local sing = text:match("^(.-)s$")
		if sing then
			return sing
		end
		return text
	end

	local function collapse_link(link, linktext)
		if link == linktext then
			return "[[" .. link .. "]]"
		else
			return "[[" .. link .. "|" .. linktext .. "]]"
		end
	end

	-- Check for a link. This pattern matches both piped and unpiped links.
	-- If the link is not piped, the second capture (linktext) will be empty.
	local beginning, link, linktext = export.match(text, "^(.*)%[%[([^|%]]+)%|?(.-)%]%]$")
	if link then
		if linktext ~= "" then
			return beginning .. collapse_link(link, do_singularize(linktext))
		end
		return beginning .. "[[" .. do_singularize(link) .. "]]"
	end

	return do_singularize(text)
end

function export.add_indefinite_article(text, uppercase)
	local is_vowel = false
	-- If there's a link at the beginning, examine the first letter of the
	-- link text. This pattern matches both piped and unpiped links.
	-- If the link is not piped, the second capture (linktext) will be empty.
	local link, linktext, remainder = export.match(text, "^%[%[([^|%]]+)%|?(.-)%]%](.*)$")
	if link then
		is_vowel = export.find(linktext ~= "" and linktext or link, "^[AEIOUaeiou]")
	else
		is_vowel = export.find(text, "^[AEIOUaeiou]")
	end
	return (is_vowel and (uppercase and "An " or "an ") or (uppercase and "A " or "a ")) .. text
end

return export