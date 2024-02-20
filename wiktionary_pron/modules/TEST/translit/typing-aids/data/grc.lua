local U = mw.ustring.char

local data = {
	{
		["a"] = "α",
		["b"] = "β",
		["c"] = "ξ",
		["d"] = "δ",
		["e"] = "ε",
		["f"] = "φ",
		["g"] = "γ",
		["h"] = "η",
		["([^_])i"] = "%1ι",
		["^i"] = "ι",
		["k"] = "κ",
		["l"] = "λ",
		["m"] = "μ",
		["n"] = "ν",
		["o"] = "ο",
		["p"] = "π",
		["q"] = "θ",
		["r"] = "ρ",
		["s"] = "σ",
		["t"] = "τ",
		["u"] = "υ",
		["v"] = "ϝ",
		["w"] = "ω",
		["x"] = "χ",
		["y"] = "ψ",
		["z"] = "ζ",
		["A"] = "Α",
		["B"] = "Β",
		["C"] = "Ξ",
		["D"] = "Δ",
		["E"] = "Ε",
		["F"] = "Φ",
		["G"] = "Γ",
		["H"] = "Η",
		["I"] = "Ι",
		["K"] = "Κ",
		["L"] = "Λ",
		["M"] = "Μ",
		["N"] = "Ν",
		["O"] = "Ο",
		["P"] = "Π",
		["Q"] = "Θ",
		["R"] = "Ρ",
		["S"] = "Σ",
		["T"] = "Τ",
		["U"] = "Υ",
		["V"] = "Ϝ",
		["W"] = "Ω",
		["X"] = "Χ",
		["Y"] = "Ψ",
		["Z"] = "Ζ",
		["_i"] = U(0x345),		-- iota subscript (ypogegrammeni)
		["_"] = U(0x304),		-- macron
		[U(0xAF)] = U(0x304),	-- non-combining macron
		[U(0x2C9)] = U(0x304),	-- modifier letter macron
		["%^"] = U(0x306),		-- breve
		["˘"] = U(0x306),		-- non-combining breve
		["%+"] = U(0x308),		-- diaeresis
		["%("] = U(0x314),		-- rough breathing (reversed comma)
		["%)"] = U(0x313),		-- smooth breathing (comma)
		["/"] = U(0x301),		-- acute
		["\\"] = U(0x300),		-- grave
		["="] = U(0x342),		-- Greek circumflex (perispomeni)
		["~"] = U(0x342),
		["{{=}}"] = U(0x342),
		["'"] = "’",		-- right single quotation mark (curly apostrophe)
		["ϑ"] = "θ",
		["ϰ"] = "κ",
		["ϱ"] = "ρ",
		["ϕ"] = "φ",
	},
	{
		["σ%f[%s%p%z]"] = "ς",
	},
	{
		["ς%*"] = "σ",	-- used to block conversion to final sigma
		["ς%-"] = "σ-",	-- used to block conversion to final sigma
		["!"] = "|",
		["%?"] = U(0x37E),	-- Greek question mark
		[";"] = "·",		-- interpunct
		["^" .. U(0x314)] = "῾",	-- spacing rough breathing
		["^" .. U(0x313)] = "᾿",	-- spacing smooth breathing
	},
}

return data