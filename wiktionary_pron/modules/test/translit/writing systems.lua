local export = {}

local System = {}


function System:getCode()
	return self._code
end

function System:getCanonicalName()
	return self._rawData.canonicalName
end

function System:getOtherNames()
	return self._rawData.otherNames or {}
end

--function System:getAllNames()
--	return self._rawData.names
--end

--[==[Given a list of types as strings, returns true if the script has all of them. Possible types are explained in [[Module:scripts/data]].]==]
function System:hasType(...)
	if not self._type then
		self._type = {["writing system"] = true}
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

function System:getCategoryName()
	return self._rawData.category or mw.getContentLanguage():ucfirst(self:getCanonicalName() .. "s")
end

function System:getRawData()
	return self._rawData
end

function System:toJSON()
	if not self._type then
		self:hasType()
	end
	local types = {}
	for type in pairs(self._type) do
		table.insert(types, type)
	end
	
	local ret = {
		canonicalName = self:getCanonicalName(),
		categoryName = self:getCategoryName(),
		code = self:getCode(),
		otherNames = self:getOtherNames(),
		type = types,
	}
	
	return require("JSON").toJSON(ret)
end

System.__index = System

function export.makeObject(code, data)
	return data and setmetatable({_rawData = data, _code = code}, System) or nil
end

function export.getByCode(code)
	return export.makeObject(code, mw.loadData("writing systems/data")[code])
end

return export