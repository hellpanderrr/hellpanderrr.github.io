U = mw.ustring.char

local fatHa = U(0x64E)
local fatHatan = U(0x64B)
local kasratan = U(0x64D)
local Dammatan = U(0x64C)
local kasra = U(0x650)
local Damma = U(0x64F)
local superscript_alif = U(0x670)
local sukuun = U(0x652)
local shadda = U(0x651)
local vowel_diacritics = fatHa .. kasra .. Damma .. fatHatan .. kasratan .. Dammatan
local short_vowel = "[" .. fatHa .. kasra .. Damma .. "]"

local taTwiil = U(0x640)

local alif = "ا"
local waaw = "و"
local yaa = "ي"
local alif_maqSuura = "ى"

local laam = "ل"

local madda = "آ"
local waSla = "ٱ"
local hamza = "ء"
local alif_hamza = "أ"
local alif_hamza_below = "إ"
local yaa_hamza = "ئ"
local waaw_hamza = "ؤ"

local taa_marbuuTa = "ة"

local article = alif .. laam

local consonants = "بتثجحخدذرزسشصضطظعغقفلكمنءة"
local consonant = "[" .. consonants .. "]"
local sun_letters = "تثدذرزسشصضطظلن"
local sun_letter = "[" .. sun_letters .. "]"

-- Mostly [[w:Bikdash Arabic Transliteration Rules]], some [[w:Arabic chat alphabet]]
replacements = {
	[1] = {
		["eaa"] = madda,
		["aaa"] = fatHa .. alif_maqSuura,
		["_a"] = superscript_alif,
		["t\'"] = taa_marbuuTa,
		["z\'"] = "ذ",
		["d\'"] = "ض",
		["6\'"] = "ظ",
		["3\'"] = "ع",
		["5\'"] = "خ",
		["al%-"] = article,
		[","] = "،",
		[";"] = "؛",
		["?"] = "؟",
	},
	[2] = {
		["aa"] = fatHa .. alif,
		["ii"] = kasra .. yaa,
		["uu"] = Damma .. waaw,
		["aN"] = fatHatan,
		["iN"] = kasratan,
		["uN"] = Dammatan,
		["A"] = alif,
		["W"] = waSla,
		["b"] = "ب",
		["c"] = "ث",
		["d"] = "د",
		["e"] = hamza,
		["2"] = hamza,
		["'"] = hamza,
		["E"] = "ع",
		["3"] = "ع",
		["`"] = "ع",
		["f"] = "ف",
		["D"] = "ض",
		["g"] = "غ",
		["h"] = "ه",
		["H"] = "ح",
		["7"] = "ح",
		["j"] = "ج",
		["k"] = "ك",
		["K"] = "خ",
		["l"] = "ل",
		["L"] = "ﷲ",	-- Allah ligature
		["m"] = "م",
		["n"] = "ن",
		["p"] = "پ",
		["q"] = "ق",
		["r"] = "ر",
		["s"] = "س",
		["S"] = "ص",
		["9"] = "ص",
		["t"] = "ت",
		["T"] = "ط",
		["6"] = "ط",
		["v"] = "ڤ",
		["w"] = waaw,
		["y"] = yaa,
		["x"] = "ش",
		["z"] = "ز",
		["Z"] = "ظ",
		["^%-"] = taTwiil,
		["%s%-"] = taTwiil,
		["%-$"] = taTwiil,
		["%-%s"] = taTwiil,
	},
	[3] = {
		["a"] = fatHa,
		["i"] = kasra,
		["u"] = Damma,
		["^i"] = alif .. kasra,
		["^u"] = alif .. Damma,
		["([^" .. hamza .. taa_marbuuTa .. "])" .. fatHatan] = "%1" .. fatHatan .. alif,
		["^(" .. article .. sun_letter .. ")"] = "%1" .. shadda,
		["(%s" .. article .. sun_letter .. ")"] = "%1" .. shadda,
	},
	[4] = {
		["(" .. consonant .. ")([^" .. vowel_diacritics .. "%s])"] = "%1" .. sukuun .. "%2",
		["(" .. fatHa .. "[" .. waaw .. yaa .. "])" .. "([^" .. vowel_diacritics .. "])"] = "%1" .. sukuun .. "%2",
		["^" .. hamza] = { alif_hamza, after = "[" .. fatHa .. Damma .. "]" },
		["^" .. hamza .. kasra] = alif_hamza_below .. kasra,
		["(%s)" .. hamza .. kasra] = "%1" .. alif_hamza_below .. kasra,
	},
	[5] = {	
		-- remove sukuun from definite article before sun letter
		["^" .. article .. sukuun .. "(" .. sun_letter .. ")"] = article .. "%1",
		["(%s)" .. article .. sukuun .. "(" .. sun_letter .. ")"] = "%1" .. article .. "%2",
		-- to add final sukuun
		["0"] = "",
		["(" .. consonant .. ")" .. sukuun .. "%1"] = "%1" .. shadda,
		["([" .. waaw .. yaa .. "])%1"] = "%1" .. shadda,
		[kasra .. hamza] = kasra .. yaa_hamza,
		[hamza .. kasra] = yaa_hamza .. kasra,
		[Damma .. hamza] = {
			Damma .. waaw_hamza,
			after = "[^" .. kasra .. "]",
		},
		[fatHa .. hamza] = fatHa .. alif_hamza,
		["([^" .. waaw .. alif .. "])" .. hamza .. fatHa] = "%1" .. alif_hamza .. fatHa,
	},
	[6] = {
		["(" .. short_vowel .. "%s)" .. article] = "%1" .. waSla .. laam,
		["(" .. fatHa .. alif .. "%s)" .. article] = "%1" .. waSla .. laam,
		["(" .. kasra .. yaa .. "%s)" .. article] = "%1" .. waSla .. laam,
		["(" .. Damma .. waaw .. "%s)" .. article] = "%1" .. waSla .. laam,
		["(" .. fatHa .. alif_maqSuura .. "%s)" .. article] = "%1" .. waSla .. laam,
	},
}
--	[""] = "",

return replacements