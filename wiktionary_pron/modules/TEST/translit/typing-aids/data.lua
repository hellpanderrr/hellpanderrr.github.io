local U = mw.ustring.char

local stops = "PpBbTtDdKkGgQq"
local velars = "GgKk"
local diacritics = "_%^\'0"
local vowels = "AaEeIiOoUu"
local sonorants = "RrLlMmNn"
local not_laryngeal_numbers = "[^123₁₂₃]"
local ProtoGreekpalatalized = "TtDdLlNnRr"
local ProtoGreekaspirated = "PpTtKk"
local acute = U(0x0301)

local data = {}
data["all"] = {
	["h1"] = "h₁",
	["h2"] = "h₂",
	["h3"] = "h₃",
	["e1"] = "ə₁",
	["e2"] = "ə₂",
	["e3"] = "ə₃",
	["e%-2"] = "ē₂",
	["_w"] = "ʷ",
	["%^w"] = "ʷ",
	["_h"] = "ʰ",
	["%^h"] = "ʰ",
	["wh"] = { "ʷʰ", before = "["..velars.."]", after = not_laryngeal_numbers, },
	["h"] = { "ʰ", before = "["..stops.."]", after = not_laryngeal_numbers, },
	["w"] = { "ʷ", before = "["..velars.."]", },
	["_e"] = "ₔ", -- sometimes used for the schwa secundum
	["_"] = U(0x304), -- macron
	["^"] = { U(0x302), before = "["..vowels.."]["..diacritics.."]?", }, -- circumflex
	["\'"] = { U(0x301), before = "["..velars..vowels..sonorants.."]["..diacritics.."]?", }, -- acute
	["0"] = { U(0x325), before = "["..sonorants.."]["..diacritics.."]?", }, -- ring below
	["`"] = { U(0x328), before = "["..vowels.."]["..diacritics.."]?", }, -- ogonek
	["t\'"] = "þ",
	["T\'"] = "Þ",
	["@"] = "ə",
	["%^"] = { U(0x30C), before = "["..ProtoGreekpalatalized.."]", }, -- caron
	["~"] = "⁓", -- swung dash
}
data["ine-pro"] = {
	[1] = {
		["h1"] = "h₁",
		["h2"] = "h₂",
		["h3"] = "h₃",
		["e1"] = "ə₁",
		["e2"] = "ə₂",
		["e3"] = "ə₃",
		["_w"] = "ʷ",
		["%^w"] = "ʷ",
		["_h"] = "ʰ",
		["%^h"] = "ʰ",
		["wh"] = { "ʷʰ", before = "["..velars.."]", after = not_laryngeal_numbers, },
		["h"] = { "ʰ", after = not_laryngeal_numbers, },
		["w"] = { "ʷ", before = "["..velars.."]", },
		["_e"] = "ₔ", -- sometimes used for the schwa secundum
		["'"] = { U(0x301), before = "["..velars..vowels..sonorants.."]["..diacritics.."]?", }, -- acute
		["_"] = { U(0x304), before = "["..vowels.."]["..diacritics.."]?", }, -- macron
		["0"] = { U(0x325), before = "["..sonorants.."]["..diacritics.."]?", }, -- ring below
		["~"] = "⁓", -- swung dash
		["%^"] = { U(0x311), before = "["..velars.."]", }, -- inverted breve above
	},
	[2] = {
		["%^"] = { U(0x32F), before = "[iu]", }, -- inverted breve above
	},
}
data["PIE"] = data["ine-pro"]

data["gem-pro"] = {
	["e_2"] = "ē₂",
	["`"] = { U(0x328), before = "["..vowels.."]["..diacritics.."]?", }, -- ogonek
	["t\'"] = "þ",
	["T\'"] = "Þ",
	["_"] = { U(0x304), before = "["..vowels.."]["..diacritics.."]?", }, -- macron
	["%^"] = { U(0x302), before = "["..vowels.."]["..diacritics.."]?", }, -- circumflex
}
data["PG"] = data["gem-pro"]

data["grk-pro"] = {
	[1] = {
		["_\'"] = { U(0x304) .. U(0x301), before = "["..vowels.."]", }, -- macron and acute
		["\'_"] = { U(0x304) .. U(0x301), before = "["..vowels.."]", }, -- macron and acute
		["hw"] = { "ʷʰ", before = "["..velars.."]", },
		["wh"] = { "ʷʰ", before = "["..velars.."]", },
		["\'"] = { U(0x30C), before = "["..ProtoGreekpalatalized.."]", }, -- caron
	},
	[2] = {
		["%^"] = U(0x30C), -- caron
		["@"] = "ə",
		["_"] = { U(0x304), before = "["..vowels.."]["..diacritics.."]?", }, -- macron
		["\'"] = { U(0x301), before = "["..velars..vowels..sonorants.."]["..diacritics.."]*", }, -- acute
		["h"] = { "ʰ", before = "["..ProtoGreekaspirated.."]", },
		["w"] = { "ʷ", before = "["..velars.."]", },
	}
}
data["PGr"] = data ["grk-pro"]

data["ru"] = {
	[1] = {
		["Jo"] = "Ё",
		["jo"] = "ё",
		["Ju"] = "Ю",
		["ju"] = "ю",
		["Ja"] = "Я",
		["ja"] = "я",
		["C'"] = "Ч",
		["c'"] = "ч",
		["S'"] = "Ш",
		["s'"] = "ш",
		["j'"] = "й",
	},
	[2] = {
		["A"] = "А",
		["a"] = "а",
		["B"] = "Б",
		["b"] = "б",
		["V"] = "В",
		["v"] = "в",
		["G"] = "Г",
		["g"] = "г",
		["D"] = "Д",
		["d"] = "д",
		["E"] = "Е",
		["e"] = "е",
		["Z'"] = "Ж",
		["z'"] = "ж",
		["Z"] = "З",
		["z"] = "з",
		["I"] = "И",
		["i"] = "и",
		["J"] = "Й",
		["j"] = "й",
		["K"] = "К",
		["k"] = "к",
		["L"] = "Л",
		["l"] = "л",
		["M"] = "М",
		["m"] = "м",
		["N"] = "Н",
		["n"] = "н",
		["O"] = "О",
		["o"] = "о",
		["P"] = "П",
		["p"] = "п",
		["R"] = "Р",
		["r"] = "р",
		["S"] = "С",
		["s"] = "с",
		["T"] = "Т",
		["t"] = "т",
		["U"] = "У",
		["u"] = "у",
		["F"] = "Ф",
		["f"] = "ф",
		["H"] = "Х",
		["h"] = "х",
		["C"] = "Ц",
		["c"] = "ц",
		["X"] = "Щ",
		["x"] = "щ",
		["``"] = "Ъ",
		["`"] = "ъ",
		["Y"] = "Ы",
		["y"] = "ы",
		["''"] = "Ь",
		["'''"] = "ь",
		["`E"] = "Э",
		["`e"] = "э",
		["/"] = U(0x301), -- acute
	},
}

--[[
The shortcut (or regex search pattern) is enclosed in [""],
and the replacement is enclosed in quotes after the equals sign:
		["shortcut"] = "replacement",

if the shortcut includes a parenthesis "()",
the replacement will contain a capture string "%1" or "%2",
which matches the contents of first or second parenthesis.

]]

data.acute_decomposer = {
	["á"] = "a" .. acute,
	["é"] = "e" .. acute,
	["í"] = "i" .. acute,
	["ó"] = "o" .. acute,
	["ú"] = "u" .. acute,
	["ý"] = "y" .. acute,
	["ḗ"] = "ē" .. acute,
	["ṓ"] = "ō" .. acute,
	["Á"] = "A" .. acute,
	["É"] = "E" .. acute,
	["Í"] = "I" .. acute,
	["Ó"] = "O" .. acute,
	["Ú"] = "U" .. acute,
	["Ý"] = "Y" .. acute,
	["Ḗ"] = "Ē" .. acute,
	["Ṓ"] = "Ō" .. acute,
}

--[=[
	If table is an array, the first string is the subpage of
	[[Module:typing-aids/data]] that contains the language's replacements; the
	second is the index of the field in the exported table of that module that
	contains the language's replacements.
	
	Otherwise, the table contains fields for particular scripts, specifying the
	module used when the |sc= parameter is set to that script code, as well as a
	"default" field for cases where no script has been specified.
]=]
data.modules = {
	["ae"]		= { "ae", "ae", },
	["ae-old"]	= { "ae", "ae", },
	["ae-yng"]	= { "ae", "ae", },
	["ae-tr"]	= { "ae", "ae-tr", },
	["akk"]     = { "akk", "akk-tr" },
	["ar"]		= { "ar" },
	["arc"]		= { default = "Armi", Palm = "Palm" },
	["arc-imp"]		= { default = "Armi", Palm = "Palm" },
	["arc-pal"]  = { "Palm", "Palm"},
	["cu"]		= { "Cyrs" },
	["fa"]		= { "fa" },
	["fa-cls"]		= { "fa" },
	["fa-ira"]		= { "fa" },
	["gmy"]     = { "gmy" },
	-- ["gmy-tr"]  = { "gmy", "gmy-tr" },
	["got"]		= { "got", "got" },
	["got-tr"]	= { "got", "got-tr" },
	["grc"]		= { "grc" },
	["hit"]		= { "hit", "hit" },
	["hit-tr"]	= { "hit", "hit-tr" },
	["hy"]		= { "hy", "hy", },
	["hy-tr"]	= { "hy", "hy-tr", },
	["ja"]		= { "ja", "ja" },
	["kn"]		= { "kn", "kn" },
	["kn-tr"]	= { "kn", "kn-tr" },
	["Mani-tr"] = { "Mani", "Mani-tr" },
	["Narb"]    = { "Narb", "Narb"},
	["Narb-tr"]    = { "Narb", "Narb-tr"},
	["pal"]		= { default = "Phlv", Phli = "Phli", Mani = "Mani" },
	["phn"]		= { "Phnx" },
	["orv"]		= { "Cyrs" },
	["os"]		= { "os" },
	["os-dig"]		= { "os" },
	["os-iro"]		= { "os" },
	["otk"]		= { "Orkh" },
	["oty"]		= { "oty" },
	["peo"]		= { "peo" },
	["Phli-tr"] = { "Phli", "Phli-tr" },
	["Prti-tr"]	= { "Prti", "Prti-tr" },
	["mai"]		= { "mai", "mai" },
	["mai-tr"]	= { "mai", "mai-tr" },
	["mwr"]		= { "mwr", "mwr" },
	["mwr-tr"]	= { "mwr", "mwr-tr" },
	["omr"]		= { "omr", "omr" },
	["omr-tr"]	= { "omr", "omr-tr" },
	["inc-ash"]		= { "inc-pra", "inc-pra" },
	["inc-ash-tr"]	= { "inc-pra", "inc-pra-tr" },
	["inc-pra"]		= { "inc-pra", "inc-pra" },
	["inc-pra-tr"]	= { "inc-pra", "inc-pra-tr" },
	["inc-pra-Deva"]	= { "inc-pra-Deva", "inc-pra-Deva" },
	["inc-pra-Deva-tr"]	= { "inc-pra-Deva", "inc-pra-Deva-tr" },
	["inc-pra-Knda"]	= { "inc-pra-Knda", "inc-pra-Knda" },
	["inc-pra-Knda-tr"]	= { "inc-pra-Knda", "inc-pra-Knda-tr" },
	["doi"]		= { "doi", "doi" },
	["doi-tr"]	= { "doi", "doi-tr" },
	["sa-Modi"]		= { "sa-Modi", "sa-Modi" },
	["sa-Modi-tr"]	= { "sa-Modi", "sa-Modi-tr" },
	["omr-Deva"]	= { "omr-Deva", "omr-Deva" },
	["omr-Deva-tr"]	= { "omr-Deva", "omr-Deva-tr" },
	["kho"]		= { "psu", "psu" },
	["sa"]		= { "sa", "sa" },
	["sa-tr"]	= { "sa", "sa-tr" },
	["Sarb"]    = { "Sarb", "Sarb"},
	["Sarb-tr"] = { "Sarb", "Sarb-tr"},
	["saz"]		= { "saz", "saz" },
	["saz-tr"]	= { "saz", "saz-tr" },
	["sd"]		= { "sd", "sd" },
	["sd-tr"]	= { "sd", "sd-tr" },
	["sem-tha"] = { "Narb", "Narb" },
	["sgh"]		= { "sgh-Cyrl"},
	["sog"]		= { default = "Sogd", Mani = "Mani", Sogo = "Sogo" },
	["Sogd-tr"] = { "Sogd", "Sogd-tr" },
	["Sogo-tr"] = { "Sogo", "Sogo-tr" },
	["sux"]		= { "sux" },
	["uga"]		= { "Ugar" },
	["xbc"]		= { default = "el", Mani = "Mani" },
	["xpr"]		= { default = "Mani" },
	["xco"]		= { default = "Chrs" },
	["xsa"]     = { "Sarb", "Sarb" },
	["yah"]		= { "yah-Cyrl"},
--	[""] = { "" },
}

return data