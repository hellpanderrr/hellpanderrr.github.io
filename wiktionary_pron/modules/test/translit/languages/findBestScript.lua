return function (export, self, text, scripts, forceDetect, useRequire)
	-- Ensure that "Hant", "Hans" and "Hani" are moved to the end of the list (in that order, if present), as they are a special-case.
	local oldScripts, Hant, Hans, Hani, finalCheck = scripts
	scripts = {}
	for _, script in pairs(oldScripts) do
		if script._code == "Hant" then
			Hant = script
		elseif script._code == "Hans" then
			Hans = script
		elseif script._code == "Hani" then
			Hani = script
		else
			table.insert(scripts, script)
		end
	end
	if Hant then table.insert(scripts, Hant); finalCheck = true end
	if Hans then table.insert(scripts, Hans); finalCheck = true end
	if Hani then table.insert(scripts, Hani) end
	
	-- Remove all formatting characters.
	text = require("utilities").get_plaintext(text)
	
	-- Try to match every script against the text,
	-- and return the one with the most matching characters.
	local bestcount, bestscript = 0
	
	-- Remove any spacing or punctuation characters, and get resultant length.
	-- Counting instances of UTF-8 character pattern is faster than mw.ustring.len.
	local reducedText = mw.ustring.gsub(text, "[%s%p]+", "")
	local _, length = string.gsub(reducedText, "[\1-\127\194-\244][\128-\191]*", "")
	
	-- If the length is 0 then we're probably dealing with a punctuation character, so only remove spacing characters, in case it is script-specific.
	if length == 0 then
		reducedText = mw.ustring.gsub(text, "%s+", "")
		_, length = string.gsub(reducedText, "[\1-\127\194-\244][\128-\191]*", "")
		
		if length == 0 then
			return require("scripts").getByCode("None", nil, nil, useRequire)
		end
	end
	
	for i, script in ipairs(scripts) do
		local count = script:countCharacters(reducedText)
		
		-- Special case for "Hant", "Hans" and "Hani", which are returned if they match at least one character, under the assumption that (1) traditional and simplified characters will not be mixed if a language uses both scripts, and (2) any terms using Han characters with another script (e.g. Latin) will still need a Han code (not counting those which use Jpan or Kore). This is for efficiency, due to the special checks required for "Hant" and "Hans", and to prevent "Hani" from overriding either, as it will always match with at least as many characters, while characters used in both will only match with "Hani".
		if count >= length or ((script._code == "Hant" or script._code == "Hans" or script._code == "Hani") and count > 0) then
			return script
		elseif count > bestcount then
			bestcount = count
			bestscript = script
		end
	end
	
	-- Secondary check for languages that have "Hant" or "Hans" but not "Hani", but which still have multiple scripts (e.g. Macau Pidgin Portuguese): characters which are not exclusively traditional or simplified will not be found by the main check, so a separate "Hani" check is necessary to see if Han characters are present at all. If successful, return "Hant" or "Hans" as applicable.
	if finalCheck and not Hani then
		for _, script in ipairs(scripts) do
			if (script._code == "Hant" or script._code == "Hans") and (require("scripts").getByCode("Hani", nil, nil, useRequire):countCharacters(reducedText) > 0) then return script
			end
		end
	end
	
	if bestscript then
		return bestscript
	end
	
	-- No matching script was found, so return "None".
	return require("scripts").getByCode("None", nil, nil, useRequire)
end