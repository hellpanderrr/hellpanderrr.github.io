local export = {}

local Script = {}

--[==[Returns the script code of the language. Example: {{code|lua|"Cyrl"}} for Cyrillic.]==]
function Script:getCode()
	return self._code
end

--[==[Returns the canonical name of the script. This is the name used to represent that script on Wiktionary. Example: {{code|lua|"Cyrillic"}} for Cyrillic.]==]
function Script:getCanonicalName()
	return self._rawData[1] or self._rawData.canonicalName
end

--[==[Returns the display form of the script. For scripts, this is the same as the value returned by <code>:getCategoryName("nocap")</code>, i.e. it reads "NAME script" (e.g. {{code|lua|"Arabic script"}}). For regular and etymology languages, this is the same as the canonical name, and for families, it reads "NAME languages" (e.g. {{code|lua|"Indo-Iranian languages"}}). The displayed text used in <code>:makeCategoryLink</code> is always the same as the display form.]==]
function Script:getDisplayForm()
	return self:getCategoryName("nocap")
end

function Script:getOtherNames(onlyOtherNames)
	return require("language-like").getOtherNames(self, onlyOtherNames)
end

function Script:getAliases()
	return self._rawData.aliases or {}
end

function Script:getVarieties(flatten)
	return require("language-like").getVarieties(self, flatten)
end

--[==[Returns the parent of the script. Example: {{code|lua|"Arab"}} for {{code|lua|"fa-Arab"}}. It returns {{code|lua|"top"}} for scripts without a parent, like {{code|lua|"Latn"}}, {{code|lua|"Grek"}}, etc.]==]
function Script:getParent()
	return self._rawData.parent
end

function Script:getSystemCodes()
	if not self._systemCodes then
		if type(self._rawData[2]) == "table" then
			self._systemCodes = self._rawData[2]
		elseif type(self._rawData[2]) == "string" then
			self._systemCodes = mw.text.split(self._rawData[2], "%s*,%s*")
		else
			self._systemCodes = {}
		end
	end
	return self._systemCodes
end

function Script:getSystems()
	if not self._systemObjects then
		local m_systems = require("writing systems")
		self._systemObjects = {}
		
		for _, ws in ipairs(self:getSystemCodes()) do
			table.insert(self._systemObjects, m_systems.getByCode(ws))
		end
	end
	
	return self._systemObjects
end

--[==[Check whether the script is of type `system`, which can be a writing system code or object. If multiple systems are passed, return true if the script is any of the specified systems.]==]
function Script:isSystem(...)
	for _, system in ipairs{...} do
		if type(system) == "table" then
			system = system:getCode()
		end
		for _, s in ipairs(self:getSystemCodes()) do
			if system == s then
				return true
			end
		end
	end
	return false
end

--function Script:getAllNames()
--	return self._rawData.names
--end

--[==[Given a list of types as strings, returns true if the script has all of them. 

Currently the only possible type is {script}; use {{lua|hasType("script")}} to determine if an object that
may be a language, family or script is a script.
]==]	
function Script:hasType(...)
	if not self._type then
		self._type = {script = true}
		if self._rawData.type then
			for _, type in ipairs(mw.text.split(self._rawData.type, "%s*,%s*")) do
				self._type[type] = true
			end
		end
	end
	for _, type in ipairs{...} do
		if not self._type[type] then
			return false
		end
	end
	return true
end

--[==[Returns the name of the main category of that script. Example: {{code|lua|"Cyrillic script"}} for Cyrillic, whose category is at [[:Category:Cyrillic script]].
Unless optional argument <code>nocap</code> is given, the script name at the beginning of the returned value will be capitalized. This capitalization is correct for category names, but not if the script name is lowercase and the returned value of this function is used in the middle of a sentence. (For example, the script with the code <code>Semap</code> has the name <code>"flag semaphore"</code>, which should remain lowercase when used as part of the category name [[:Category:Translingual letters in flag semaphore]] but should be capitalized in [[:Category:Flag semaphore templates]].) If you are considering using <code>getCategoryName("nocap")</code>, use <code>getDisplayForm()</code> instead.]==]
function Script:getCategoryName(nocap)
	local name = self._rawData[1] or self._rawData.canonicalName
	
	-- If the name already has "script", "code" or "semaphore" at the end, don't add it.
	if not (
		name:find("[ %-][Ss]cript$") or
		name:find("[ %-][Cc]ode$") or
		name:find("[ %-][Ss]emaphore$")
	) then
		name = name .. " script"
	end
	if not nocap then
		name = mw.getContentLanguage():ucfirst(name)
	end
	return name
end

function Script:makeCategoryLink()
	return "[[:Category:" .. self:getCategoryName() .. "|" .. self:getDisplayForm() .. "]]"
end

--[==[Returns the {{code|lua|wikipedia_article}} item in the language's data file, or else calls {{code|lua|Script:getCategoryName()}}.]==]
function Script:getWikipediaArticle()
	return self._rawData.wikipedia_article or self:getCategoryName()
end

--[==[Returns the regex defining the script's characters from the language's data file.
This can be used to search for words consisting only of this script, but see the warning above.]==]
function Script:getCharacters()
	if self._rawData.characters then
		return self._rawData.characters
	else
		return nil
	end
end

--[==[Returns the number of characters in the text that are part of this script.
'''Note:''' You should never rely on text consisting entirely of the same script. Strings may contain spaces, punctuation and even wiki markup or HTML tags. HTML tags will skew the counts, as they contain Latin-script characters. So it's best to avoid them.]==]
function Script:countCharacters(text)
	if not self._rawData.characters then
		return 0
	-- Due to the number of Chinese characters, a different determination method is used when differentiating between traditional ("Hant") and simplified ("Hans") Chinese.
	elseif self:getCode() == "Hant" or self:getCode() == "Hans" then
		local num, charData = 0, self:getCode() == "Hant" and mw.loadData("zh/data/ts") or mw.loadData("zh/data/st")
		for char in text:gmatch("[\194-\244][\128-\191]*") do
			num = num + (charData[char] and 1 or 0)
		end
		return num
	end
	return select(2, mw.ustring.gsub(text, "[" .. self._rawData.characters .. "]", ""))
end

function Script:hasCapitalization()
	return not not self._rawData.capitalized
end

function Script:hasSpaces()
	return self._rawData.spaces ~= false
end

function Script:isTransliterated()
	return self._rawData.translit ~= false
end

--[==[Returns true if the script is (sometimes) sorted by scraping page content, meaning that it is sensitive to changes in capitalization during sorting.]==]
function Script:sortByScraping()
	return not not self._rawData.sort_by_scraping
end

--[==[Returns the text direction. Horizontal scripts return {{code|lua|"ltr"}} (left-to-right) or {{code|lua|"rtl"}} (right-to-left), while vertical scripts return {{code|lua|"vertical-ltr"}} (vertical left-to-right) or {{code|lua|"vertical-rtl"}} (vertical right-to-left).]==]
function Script:getDirection()
	return self._rawData.direction or "ltr"
end


function Script:getRawData()
	return self._rawData
end

--[==[Returns {{code|lua|true}} if the script contains characters that require fixes to Unicode normalization under certain circumstances, {{code|lua|false}} if it doesn't.]==]
function Script:hasNormalizationFixes()
	return not not self._rawData.normalizationFixes
end

--[==[Corrects discouraged sequences of Unicode characters to the encouraged equivalents.]==]
function Script:fixDiscouragedSequences(text)
	if self:hasNormalizationFixes() and self._rawData.normalizationFixes.from then
		local gsub = require("string utilities").gsub
		for i, from in ipairs(self._rawData.normalizationFixes.from) do
			text = gsub(text, from, self._rawData.normalizationFixes.to[i] or "")
		end
	end
	return text
end

-- Implements a modified form of Unicode normalization for instances where there are identified deficiencies in the default Unicode combining classes.
local function fixNormalization(text, self)
	if self:hasNormalizationFixes() and self._rawData.normalizationFixes.combiningClasses then
		local combiningClassFixes = self._rawData.normalizationFixes.combiningClasses
		local charsToFix = table.concat(require("table").keysToList(combiningClassFixes))
		if require("string utilities").match(text, "[" .. charsToFix .. "]") then
			local codepoint, u = mw.ustring.codepoint, mw.ustring.char
			-- Obtain the list of default combining classes.
			local combiningClasses = mw.loadData("scripts/data/combiningClasses")
			-- For each character that needs fixing, find all characters with combining classes equal to or lower than its default class, but greater than its new class (i.e. intermediary characters).
			for charToFix, newCombiningClass in pairs(combiningClassFixes) do
				local intermediaryChars = {}
				for character, combiningClass in pairs(combiningClasses) do
					if newCombiningClass < combiningClass and combiningClass <= combiningClasses[codepoint(charToFix)] then
						table.insert(intermediaryChars, u(character))
					end
				end
				-- Swap the character with any intermediary characters that are immediately before it.
				text = require("string utilities").gsub(text, "([" .. table.concat(intermediaryChars) .. "]+)(" .. charToFix .. ")", "%2%1")
			end
		end
	end
	return text
end

function Script:toFixedNFC(text)
	return fixNormalization(mw.ustring.toNFC(text), self)
end

function Script:toFixedNFD(text)
	return fixNormalization(mw.ustring.toNFD(text), self)
end

function Script:toFixedNFKC(text)
	return fixNormalization(mw.ustring.toNFKC(text), self)
end

function Script:toFixedNFKD(text)
	return fixNormalization(mw.ustring.toNFKD(text), self)
end

function Script:toJSON()
	if not self._type then
		self:hasType()
	end
	local types = {}
	for type in pairs(self._type) do
		table.insert(types, type)
	end
	
	local ret = {
		canonicalName = self:getCanonicalName(),
		categoryName = self:getCategoryName("nocap"),
		code = self:getCode(),
		otherNames = self:getOtherNames(true),
		aliases = self:getAliases(),
		varieties = self:getVarieties(),
		type = types,
		direction = self:getDirection(),
		characters = self:getCharacters(),
		parent = self:getParent(),
		systems = self:getSystemCodes(),
		wikipediaArticle = self._rawData.wikipedia_article,
	}
	
	return require("JSON").toJSON(ret)
end

Script.__index = Script
	
function export.makeObject(code, data, useRequire)
	return data and setmetatable({_rawData = data, _code = code}, Script) or nil
end

-- Track scripts with anomalous names.
local scriptsToTrack = {
	-- scripts already renamed
	["IPAchar"] = true,
	["musical"] = true,
	["Ruminumerals"] = true,
	["polytonic"] = true,
	-- scripts not yet renamed
	["Latinx"] = true,
	["Latnx"] = true,
}

-- Temporary aliases from canonicalized names to (existing) anomalous names. Once we have converted everything we will
-- rename the scripts and remove the alias code.
local scriptAliases = {
	-- scripts already renamed; we now alias the old names to the new ones
	["IPAchar"] = "Ipach",
	["musical"] = "Music",
	["Ruminumerals"] = "Rumin",
	["polytonic"] = "Polyt",
	["Latinx"] = "Latn",
	["Latnx"] = "Latn",
}

--[==[Finds the script whose code matches the one provided. If it exists, it returns a {{code|lua|Script}} object representing the script. Otherwise, it returns {{code|lua|nil}}, unless <span class="n">paramForError</span> is given, in which case an error is generated. If <code class="n">paramForError</code> is {{code|lua|true}}, a generic error message mentioning the bad code is generated; otherwise <code class="n">paramForError</code> should be a string or number specifying the parameter that the code came from, and this parameter will be mentioned in the error message along with the bad code.]==]
function export.getByCode(code, paramForError, disallowNil, useRequire)
	if code == nil and not disallowNil then
		return nil
	end
	if scriptsToTrack[code] then
		require("debug/track")("scripts/" .. code)
	end
	code = scriptAliases[code] or code
	
	local data
	if useRequire then
		data = require("scripts/data")[code]
	else
		data = mw.loadData("scripts/data")[code]
	end
	
	local retval = export.makeObject(code, data, useRequire)
	
	if not retval and paramForError then
		require("languages/error")(code, paramForError, "script code", nil, "not real lang")
	end
	
	return retval
end

function export.getByCanonicalName(name, useRequire)
	local code
	if useRequire then
		code = require("scripts/by name")[name]
	else
		code = mw.loadData("scripts/by name")[name]
	end
	
	return export.getByCode(code, nil, nil, useRequire)
end

--[==[
	Takes a codepoint or a character and finds the script code (if any) that is
	appropriate for it based on the codepoint, using the data module
	[[Module:scripts/recognition data]]. The data module was generated from the
	patterns in [[Module:scripts/data]] using [[Module:User:Erutuon/script recognition]].

	Converts the character to a codepoint. Returns a script code if the codepoint
	is in the list of individual characters, or if it is in one of the defined
	ranges in the 4096-character block that it belongs to, else returns "None".
]==]
function export.charToScript(char)
	return require("scripts/charToScript").charToScript(char)
end

--[==[Returns the code for the script that has the greatest number of characters in <code>text</code>. Useful for script tagging text that is unspecified for language. Uses [[Module:scripts/recognition data]] to determine a script code for a character language-agnostically.]==]
function export.findBestScriptWithoutLang(text)
	return require("scripts/charToScript").findBestScriptWithoutLang(text)
end

return export