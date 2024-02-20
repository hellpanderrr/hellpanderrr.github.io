local export = {}

local accent_qualifier_data_module = "Module:accent qualifier/data"
local labels_qualifiers_module = "Module:labels/data/qualifiers"

-- WARNING: Destructively modifies `qualifiers`.
function export.format_qualifiers(qualifiers)
	local m_data = mw.loadData(accent_qualifier_data_module)
	local m_labels_qualifiers
	
	if type(qualifiers) ~= "table" then
		qualifiers = { qualifiers }
	end
	
	-- local categories = {}

	local omit_preComma = false
	local omit_postComma = true
	local omit_preSpace = false
	local omit_postSpace = true
	
	for i, accent in ipairs(qualifiers) do
		omit_preComma = omit_postComma
		omit_postComma = false
		omit_preSpace = omit_postSpace
		omit_postSpace = false

		local data
		local to_insert
		
		-- Replace an alias with the label that has a data table.
		if m_data.aliases[accent] then
			accent = m_data.aliases[accent]
		end
		
		-- Retrieve the label's data table.
		if m_data.labels[accent] then
			data = m_data.labels[accent]
		end
		
		-- Use the link and displayed text in the data table, if they exist.
		if data then
			if data.link then
				to_insert = "[[w:" .. data.link .. "|" ..  (data.display or data.link) .. "]]"
			elseif data.display then
				to_insert = data.display
			end
			
			--[[
			if data[accent] then
				if data[accent].type == "sound change" then
					table.insert(categories, lang:getCanonicalName() .. " terms with pronunciations exhibiting " .. accent)
				end
			end
			]]
		elseif #qualifiers > 1 then
			-- Only check label qualifiers if there's more than one accent given, as an optimization.
			m_labels_qualifiers = m_labels_qualifiers or mw.loadData(labels_qualifiers_module)

			local labdata = m_labels_qualifiers[accent]
			if labdata and (type(labdata) == "string" or labdata.alias_of) then
				accent = labdata.alias_of or labdata
				labdata = m_labels_qualifiers[accent]
			end
			if labdata then
				omit_preComma = omit_preComma or labdata.omit_preComma
				omit_postComma = labdata.omit_postComma
				omit_preSpace = omit_preSpace or labdata.omit_preSpace
				omit_postSpace = labdata.omit_postSpace
				to_insert = labdata.display or accent
			else
				to_insert = accent
			end
		else
			to_insert = accent
		end

		if to_insert then
			if to_insert ~= "" then
				to_insert =
					(omit_preComma and "" or '<span class="ib-comma">,</span>') ..
					(omit_preSpace and "" or "&#32;") ..
					to_insert
			end
			qualifiers[i] = to_insert
		else
			-- FIXME: Does this happen?
			qualifiers[i] = ""
		end
	end
	
	return
		"<span class=\"ib-brac\">(</span><span class=\"ib-content\">" ..
		table.concat(qualifiers, "") ..
		"</span><span class=\"ib-brac\">)</span>"
end

-- Called by {{accent}} or {{a}}.
function export.show(frame)
	local args = frame.getParent and frame:getParent().args or frame
	
	if (not args[1] or args[1] == "") and mw.title.getCurrentTitle().nsText == "Template" then
		return export.format_qualifiers("{{{1}}}")
	end
	
	local params = {
		[1] = {required = true, list = true}
	}
	args = require("parameters").process(args, params)
	
	return export.format_qualifiers(args[1])
end

return export