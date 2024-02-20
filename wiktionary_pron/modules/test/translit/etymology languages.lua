local export = {}

function export.makeObject(code)
	local data = mw.loadData("etymology languages/data")[code]
	code = data and data.main_code or code
	
	if not data then
		return nil
	end
	
	local EtymologyLanguage = require("languages").getByCode(data[5], nil, true, true)
	
	local familyCode
	if EtymologyLanguage:hasType("family") then
		-- Substrates are treated as child languages of "undetermined".
		if EtymologyLanguage:getCode() == "qfa-sub" then
			EtymologyLanguage = require("languages").getByCode("und")
		end
		-- True etymology-only families (e.g. "ira-old") still need to grab the family code.
		familyCode = data[5]
	end
	-- Delete cached _type table to prevent the new object's hasType method from finding it via the metatable, as it only includes the parent's types.
	EtymologyLanguage._type = nil
	
	if not EtymologyLanguage then
		return nil
	end
	
	EtymologyLanguage.__index = EtymologyLanguage
	
	local lang = {_code = code}
	
	-- Parent is full language.
	if not EtymologyLanguage._stack then
		-- Create stack, accessed with rawData metamethod.
		lang._stack = {EtymologyLanguage._rawData, data}
		lang._rawData = setmetatable({}, {
			__index = function(t, k)
				-- Data that isn't inherited from the parent.
				local noInherit = {aliases = true, varieties = true, otherNames = true, main_code = true}
				if noInherit[k] then
					return lang._stack[#lang._stack][k]
				end
				-- Data that is appended by each generation.
				local append = {type = true}
				if append[k] then
					local parts = {}
					for i = 1, #lang._stack do
						table.insert(parts, lang._stack[i][k])
					end
					if type(parts[1]) == "string" then
						return table.concat(parts, ", ")
					end
				-- Otherwise, iterate down the stack, looking for a match.
				else
					local i = #lang._stack
					while not lang._stack[i][k] and i > 1 do
						i = i - 1
					end
					return lang._stack[i][k]
				end
			end,
			-- Retain immutability (as writing to rawData will break functionality).
			__newindex = function()
				error("table from mw.loadData is read-only")
			end
		})
		-- Non-etymological code is the parent code.
		lang._nonEtymologicalCode = EtymologyLanguage._code
	-- Parent is etymology language.
	else
		-- Copy over rawData and stack to the new object, and add new layer to stack.
		lang._rawData = EtymologyLanguage._rawData
		lang._stack = EtymologyLanguage._stack
		table.insert(lang._stack, data)
		-- Copy non-etymological code.
		lang._nonEtymologicalCode = EtymologyLanguage._nonEtymologicalCode
	end
	
	lang._familyCode = familyCode
	
	return setmetatable(lang, EtymologyLanguage)
end

function export.getByCode(code)
	return export.makeObject(code)
end

function export.getByCanonicalName(name)
	local byName = mw.loadData("etymology languages/canonical names")
	local code = byName and byName[name] or
		byName[name:gsub(" [Ss]ubstrate$", "")] or
		byName[name:gsub("^a ", "")] or
		byName[name:gsub("^a ", ""):gsub(" [Ss]ubstrate$", "")]
	
	if not code then
		return nil
	end
	
	return export.makeObject(code)
end

return export