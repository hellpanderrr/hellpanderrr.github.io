
local export = {}

-- This module is used by any module that wants to add support for left and right regular and accent qualifiers to a
-- template that specifies a pronunciation or related property. It is currently used by [[Module:rhymes]],
-- [[Module:hyphenation]], [[Module:homophones]] and [[Module:es-pronunc]] (for specifying pronunciation, rhymes,
-- hyphenation, homophones and audio in {{es-pr}}). It should potentially also be used in {{audio}}. To reduce memory
-- usage, the caller should check that any qualifiers exist before loading the module.
function export.format_qualifiers(data, text, qualifiers_right)
	local function format_q(q)
		return require("qualifier").format_qualifier(q)
	end
	local function format_a(a)
		return require("accent qualifier").format_qualifiers(a)
	end
	-- This order puts the accent qualifiers before other qualifiers on both the left and the right.
	local leftq = data.q or not qualifiers_right and data.qualifiers
	if leftq and leftq[1] then
		text = format_q(leftq) .. " " .. text
	end
	local lefta = data.a
	if lefta and lefta[1] then
		text = format_a(lefta) .. " " .. text
	end
	local righta = data.aa
	if righta and righta[1] then
		text = text .. " " .. format_a(righta)
	end
	local rightq = data.qq or qualifiers_right and data.qualifiers
	if rightq and rightq[1] then
		text = text .. " " .. format_q(rightq)
	end
	return text
end

return export