local replacements = {}

replacements["sux"] = {
	-- This converts from regular to diacriticked characters, before the
	-- shortcuts below are processed.
	-- The apostrophe is used in place of an acute, and a backslash \ in place of
	-- a grave. ^ is replaced with háček or breve if it follows certain
	-- consonants.
	["pre"] = {
		["a'"] = "á", ["a\\"] = "à",
		["e'"] = "é", ["e\\"] = "è",
		["i'"] = "í", ["i\\"] = "ì",
		["u'"] = "ú", ["u\\"] = "ù",
		["g~"] = "g̃",
		["s^"] = "š", ["h^"] = "ḫ", ["r^"] = "ř",
	},
	
	-- V
	["a"] = "𒀀", ["á"] = "𒀉",
	
	-- CV
	
	-- VC
	
	-- VCV
}

--[[
replacements["sux-tr"] = {
	
}
--]]

return replacements