local export = {}

local WikimediaLanguage = {}

function WikimediaLanguage:getCode()
	return self._code
end

function WikimediaLanguage:getCanonicalName()
	return self._rawData.canonicalName
end

--function WikimediaLanguage:getAllNames()
--	return self._rawData.names
--end

--[==[Given a list of types as strings, returns true if the Wikimedia language has all of them. Possible types are explained in [[Module:wikimedia languages/data]].]==]
function WikimediaLanguage:hasType(...)
	if not self._type then
		self._type = {["Wikimedia language"] = true}
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

function WikimediaLanguage:getWiktionaryLanguage()
	if not self._wiktionaryLanguageObject then
		self._wiktionaryLanguageObject = require("languages").getByCode(self._rawData.wiktionary_code)
	end
	
	return self._wiktionaryLanguageObject
end

-- Do NOT use this method!
-- All uses should be pre-approved on the talk page!
function WikimediaLanguage:getRawData()
	return self._rawData
end

WikimediaLanguage.__index = WikimediaLanguage

function export.getByCode(code)
	-- Only accept codes the software recognises
	if not mw.language.isKnownLanguageTag(code) then
		return nil
	end
	
	local rawData = mw.loadData("wikimedia languages/data")[code]
	
	-- If there is no specific Wikimedia code, then "borrow" the information
	-- from the general Wiktionary language code
	if not rawData then
		local lang = require("languages").getByCode(code)
		
		if not lang then
			return nil
		end
		
		rawData = {canonicalName = lang:getCanonicalName(), wiktionary_code = code}
	elseif not rawData.canonicalName then
		rawData = {canonicalName = require("languages").getByCode(rawData.wiktionary_code):getCanonicalName(), wiktionary_code = rawData.wiktionary_code}
	end
	
	return setmetatable({_rawData = rawData, _code = code}, WikimediaLanguage)
end

function export.getByCodeWithFallback(code)
	local object = export.getByCode(code)
	
	if object then
		return object
	end
	
	local lang = require("languages").getByCode(code)
	
	if not lang then
		return nil
	end
	
	return lang:getWikimediaLanguages()[1]
end

return export