local data = {}

local U = mw.ustring.char

local anusvAra = U(0x902)
local visarga = U(0x903)
local virAma = U(0x94D)
local avagraha = "ऽ"
local consonants = "कखगघङचछजझञटठडढणतथदधनपफबभमयरलळवशषसह"
local consonant = "[" .. consonants .. "]"

local Lconsonants = "kgṅcjñṭḍṇtdnpbmyrlvśṣs" -- excludes h and ḷ
local Lcons1 = "[" .. Lconsonants .. "h]"
local Lcons2 = "[" .. Lconsonants .. "]"
local Lvowels = "āeĕēiïīoŏōuŭuṛṝl̥̄l̥ḹ" -- excludes a
local Lvowel1 = "[" .. Lvowels .. "]"
local Lvowel2 = "[" .. Lvowels .. "a]"
local accents = U(0x301, 0x306, 0x308) -- combining acute, breve and diaeresis
local accent = "[" .. accents .. "]"
local acute = U(0x301)		-- combining acute
data["sa"] = {
	-- Resolve ḷ where possible
	{"("..Lcons1..")(ḷ)", "%1l̥"}, -- It's a vowel next to a consonant
	{"(ḷ)("..Lcons2..")", "l̥%2"},
	{"("..Lvowel1..accent.."?)(ḷ)", "%1L"}, -- It's a consonant next to a vowel.
	{"(ḷ)(h?"..Lvowel2..")", "L%2"},

	-- Vowels and modifiers. Do the diphthongs and diaereses first.
	{"ai", "ऐ"},
	{"au", "औ"},

	{".", {	["ä"] = "अ", ["ö"] = "ओ", ["ï"] = "इ", ["ü"] = "उ",
			["a"] = "अ", ["ā"] = "आ", ["i"] = "इ", ["ī"] = "ई",
			["u"] = "उ", ["ū"] = "ऊ", ["e"] = "ए", ["o"] = "ओ",
			["ṝ"] = "ॠ", ["ṛ"] = "ऋ", ["ḹ"] = "ॡ", ["ḷ"] = "ऌ", }},
	{"r̥", "ऋ"},
	{"l̥", "ऌ"},
	{"l̥̄", "ॡ"},
	{"(अ)[%-/]([इउ])", "%1%2"},		-- a-i, a-u for अइ, अउ; must follow rules for "ai", "au"

	-- Two-letter consonants must go before h.
	{".h", {["kh"] = "ख", ["gh"] = "घ", ["ch"] = "छ", ["jh"] = "झ",
			["ṭh"] = "ठ", ["ḍh"] = "ढ", ["th"] = "थ", ["dh"] = "ध",
			["ph"] = "फ", ["bh"] = "भ", }},
	-- Other letters
	{".", {h = "ह",
				-- Other stops.
			  k = "क",       g = "ग",   c = "च", j =  "ज",
			["ṭ"] = "ट", ["ḍ"] = "ड", t = "त", d = "द",
			  p   = "प",   b   = "ब",
	-- Nasals.
			["ṅ"] = "ङ", ["ñ"] = "ञ", ["ṇ"] = "ण", ["n"] = "न",
			  n   = "न",   m   = "म",
	-- Remaining consonants.
			  y   = "य",   r   = "र",    l   = "ल",   L   = "ळ",
			  v   = "व", ["ś"] = "श",  ["ṣ"] = "ष",   s   = "स",
			["ẏ"] = "य़", ["ṃ"] = anusvAra, 	["ḥ"] =  visarga,
			["'"] = avagraha,
			}},
	-- This rule must be applied twice because a consonant may only be in one capture per operation,
	-- so "CCC" will only recognize the first two consonants. Must follow all consonant conversions.
	{"(" .. consonant .. ")(" .. consonant .. ")", "%1" .. virAma .. "%2"},
	{"(" .. consonant .. ")(" .. consonant .. ")", "%1" .. virAma .. "%2"},
	{"(" .. consonant .. ")$", "%1" .. virAma},
	{acute, ""},
}

local vowels = {
	["इ"] = U(0x93F),
	["उ"] = U(0x941),
	["ऋ"] = U(0x943),
	["ऌ"] = U(0x962),
	["ए"] = U(0x947),
	["ओ"] = U(0x94B),
	["आ"] = U(0x93E),
	["ई"] = U(0x940),
	["ऊ"] = U(0x942),
	["ॠ"] = U(0x944),
	["ॡ"] = U(0x963),
	["ऐ"] = U(0x948),
	["औ"] = U(0x94C),
}

-- Convert independent vowels to diacritics after consonants. Must go after all consonant conversions.
local independentForms = {}
for independentForm in pairs(vowels) do
	-- assert(mw.ustring.len(independentForm) == 1)
	table.insert(independentForms, independentForm)
end
table.insert(data["sa"], {"%f[^" .. consonants .. "]([" .. table.concat(independentForms) .. "])", vowels})

-- This must go last, after independent vowels are converted to diacritics, or "aï", "aü" won't work.
table.insert(data["sa"], {"(" .. consonant .. ")अ", "%1"})

-- [[w:Harvard-Kyoto]] to [[w:International Alphabet of Sanskrit Transliteration]]
data["sa-tr"] = {
	[1] = {
		["A"] = "ā",
		["ĕ"] = "e",
		["I"] = "ī",
		["U"] = "ū",
		["ŏ"] = "o",
		["J"] = "ñ",
		["T"] = "ṭ",
		["D"] = "ḍ",
		["N"] = "ṇ",
		["G"] = "ṅ",
		["z"] = "ś",
		["S"] = "ṣ",
		["M"] = "ṃ",
		["H"] = "ḥ",
		["lRR"] = "ḹ",
		["/"] = acute,
	},
	[2] = {
		["lR"] = "l̥", -- was "ḷ",
		["RR"] = "ṝ",
	},
	[3] = {
		["R"] = "ṛ",
	},
}

return data