local export = {}

local data = mw.loadData("palindromes/data")

local function ignoreCharacters(term, lang, sc, langdata)
	term = mw.ustring.lower(term)
	term = mw.ustring.gsub(term, "[ ,%.%?!%%%-'\"]", "")
	
	-- Language-specific substitutions

	-- Ignore entire scripts (e.g. romaji in Japanese)
	if langdata.ignore then
		sc_name = sc and sc:getCode() or lang:findBestScript(term):getCode()
		for _, script in ipairs(langdata.ignore) do
			if script == sc_name then
				return ""
			end
		end
	end
	
	for i, from in ipairs(langdata.from or {}) do
		term = mw.ustring.gsub(term, from, langdata.to[i] or "")
	end
	
	return term
end

function export.is_palindrome(term, lang, sc)
	local langdata = data[lang:getCode()] or data[lang:getNonEtymologicalCode()] or {}

	-- Affixes aren't palindromes
	if mw.ustring.find(term, "^%-") or mw.ustring.find(term, "%-$") then
		return false
	end
	
	-- Remove punctuation and casing
	term = ignoreCharacters(term, lang, sc, langdata)
	local len = mw.ustring.len(term)
	
	if langdata.allow_repeated_char then
		-- Ignore single-character terms
		if len < 2 then
			return false
		end
	else
		-- Ignore terms that consist of just one character repeated
		-- This also excludes terms consisting of fewer than 3 characters
		if term == mw.ustring.rep(mw.ustring.sub(term, 1, 1), len) then
			return false
		end
	end
	
	local charlist = {}
	
	for c in mw.ustring.gmatch(term, ".") do
		table.insert(charlist, c)
	end
	
	for i = 1, math.floor(len / 2) do
        if charlist[i] ~= charlist[len - i + 1] then
        	return false
        end
    end
    
    return true
end

return export