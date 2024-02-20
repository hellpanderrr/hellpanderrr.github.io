local export = {}
local m_string_utils = require("string utilities")

local find = m_string_utils.find
local match = m_string_utils.match
local gsub = m_string_utils.gsub

function export.i(text)
	if text == "" or text == nil then
		return nil
	end
	
	if type(text) == "table" and text.args then
		text = text.args[1]
	end
	
	-- Remove whitespace from beginning and end of text.
	text = mw.text.trim(text)
	
	-- Find parenthesized text.
	local parenthesis = ""
	if find(text, "%b()$") then
		text, parenthesis = match(text, "^(.*)(%b())$")
		if text == "" or text == nil then
			error("Malformed page name: " .. text)
		end
	end
	
	text = "''" .. text .. "''"
	
	--[[ Adds italics toggle ('') around the whitespace
		that surrounds various things that aren't supposed to be italicized:
		for instance, Fragaria × ananassa becomes ''Fragaria'' × ''ananassa''.
		(The hybridization symbol × isn't supposed to be italicized.) ]]
	local notItalicized = {
		["subsp."] = true, ["ssp."] = true, ["var."] = true, ["f."] = true,
		["sect."] = true, ["subsect."] = true, ["subg."] = true, ["infrasp."] =  true,
        ["forma"] = true, ["form"] = true, ["morph"] = true, ["morpha"] = true
	}
	local hybrid = "×"
	
	text = text:gsub("(%s*([a-z]+%.)%s*)",
		function(wholeMatch, abbreviation)
			if notItalicized[abbreviation] then
				return "''" .. wholeMatch .. "''"
			end
		end)
	
	text = text:gsub("%s*" .. hybrid .. "%s*", "''%0''"):gsub("%f[']''''%f[^']", "")
	
	return text .. parenthesis
end

function export.unitalicize_brackets(text)
	if type(text) == "table" and text.args then
		text = text.args[1]
	end
	
	if not text or text == "" then
		return nil
	end
	
	local function unitalicize(text)
		return '<span style="font-style: normal;">' .. text .. '</span>'
	end
	
	local function process(text)
		if text:find("[[", 1, true) then
			if text:find("|") then
				return text:gsub(
					"|.-%]%]",
					function (piping)
						return piping:gsub("%b[]", process)
					end)
			end
			-- do nothing with un-piped wikilinks
		--[=[
		elseif text:find("[http", 1, true) then
			return text:gsub(
				"%[([^ ]+ )([^%]]+)%]",
				function (URL, link_text)
					return "[" .. URL .. process(link_text) .. "]"
				end)
		--]=]
		elseif text:find("^%[https?://") then
				return text:gsub(
					" .+",
					function (link_text)
						return link_text:gsub("%b[]", process)
					end)
		else
			local inside_brackets = text:sub(2, -2)
			if inside_brackets == "..." or inside_brackets == "…" then
				return unitalicize(text)
			else
				return unitalicize("[") .. inside_brackets .. unitalicize("]")
			end
		end
	end
	
	text = text:gsub("%b[]", process)
	
	return text
end

function export.test(frame)
	local text = frame.args[1]
	local quote = require("yesno")(frame.args.quote)
	if quote then
		return export.unitalicize_brackets(text)
	else
		return export.i(text)
	end
end

return export