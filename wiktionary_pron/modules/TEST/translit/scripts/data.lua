--[=[
	When adding new scripts to this file, please don't forget to add
	style definitons for the script in [[MediaWiki:Common.css]].
]=]
local concat = table.concat
local insert = table.insert
local remove = table.remove
local select = select
local sort = table.sort
local u = mw.ustring.char

------------------------------------------------------------------------------------
--
-- Helper functions
--
------------------------------------------------------------------------------------

-- Note: a[2] > b[2] means opens are sorted before closes if otherwise equal.
local function sort_ranges(a, b)
	return a[1] < b[1] or a[1] == b[1] and a[2] > b[2]
end

-- Returns the union of two or more range tables.
local function union(...)
	local ranges = {}
	for i = 1, select("#", ...) do
		local argt = select(i, ...)
		for j, v in ipairs(argt) do
			insert(ranges, {v, j % 2 == 1 and 1 or -1})
		end
	end
	sort(ranges, sort_ranges)
	local ret, i = {}, 0
	for _, range in ipairs(ranges) do
		i = i + range[2]
		if i == 0 and range[2] == -1 then -- close
			insert(ret, range[1])
		elseif i == 1 and range[2] == 1 then -- open
			if ret[#ret] and range[1] <= ret[#ret] + 1 then
				remove(ret) -- merge adjacent ranges
			else
				insert(ret, range[1])
			end
		end
	end
	return ret
end

-- Adds the `characters` key, which is determined by a script's `ranges` table.
local function process_ranges(sc)
	local ranges, chars = sc.ranges, {}
	for i = 2, #ranges, 2 do
		if ranges[i] == ranges[i - 1] then
			insert(chars, u(ranges[i]))
		else
			insert(chars, u(ranges[i - 1]))
			if ranges[i] > ranges[i - 1] + 1 then
				insert(chars, "-")
			end
			insert(chars, u(ranges[i]))
		end
	end
	sc.characters = concat(chars)
	ranges.n = #ranges
	return sc
end

------------------------------------------------------------------------------------
--
-- Data
--
------------------------------------------------------------------------------------

local m = {}

m["Adlm"] = process_ranges{
	"Adlam",
	"alphabet",
	ranges = {
		0x061F, 0x061F,
		0x0640, 0x0640,
		0x1E900, 0x1E94B,
		0x1E950, 0x1E959,
		0x1E95E, 0x1E95F,
	},
	capitalized = true,
	direction = "rtl",
}

m["Afak"] = {
	"Afaka",
	"syllabary",
	-- Not in Unicode
}

m["Aghb"] = process_ranges{
	"Caucasian Albanian",
	"alphabet",
	ranges = {
		0x10530, 0x10563,
		0x1056F, 0x1056F,
	},
}

m["Ahom"] = process_ranges{
	"Ahom",
	"abugida",
	ranges = {
		0x11700, 0x1171A,
		0x1171D, 0x1172B,
		0x11730, 0x11746,
	},
}

m["Arab"] = process_ranges{
	"Arabic",
	"abjad",	-- more precisely, impure abjad
	varieties = {"Jawi", {"Nastaliq", "Nastaleeq"}},
	ranges = {
		0x0600, 0x06FF,
		0x0750, 0x077F,
		0x0870, 0x088E,
		0x0890, 0x0891,
		0x0898, 0x08E1,
		0x08E3, 0x08FF,
		0xFB50, 0xFBC2,
		0xFBD3, 0xFD8F,
		0xFD92, 0xFDC7,
		0xFDCF, 0xFDCF,
		0xFDF0, 0xFDFF,
		0xFE70, 0xFE74,
		0xFE76, 0xFEFC,
		0x102E0, 0x102FB,
		0x10E60, 0x10E7E,
		0x10EFD, 0x10EFF,
		0x1EE00, 0x1EE03,
		0x1EE05, 0x1EE1F,
		0x1EE21, 0x1EE22,
		0x1EE24, 0x1EE24,
		0x1EE27, 0x1EE27,
		0x1EE29, 0x1EE32,
		0x1EE34, 0x1EE37,
		0x1EE39, 0x1EE39,
		0x1EE3B, 0x1EE3B,
		0x1EE42, 0x1EE42,
		0x1EE47, 0x1EE47,
		0x1EE49, 0x1EE49,
		0x1EE4B, 0x1EE4B,
		0x1EE4D, 0x1EE4F,
		0x1EE51, 0x1EE52,
		0x1EE54, 0x1EE54,
		0x1EE57, 0x1EE57,
		0x1EE59, 0x1EE59,
		0x1EE5B, 0x1EE5B,
		0x1EE5D, 0x1EE5D,
		0x1EE5F, 0x1EE5F,
		0x1EE61, 0x1EE62,
		0x1EE64, 0x1EE64,
		0x1EE67, 0x1EE6A,
		0x1EE6C, 0x1EE72,
		0x1EE74, 0x1EE77,
		0x1EE79, 0x1EE7C,
		0x1EE7E, 0x1EE7E,
		0x1EE80, 0x1EE89,
		0x1EE8B, 0x1EE9B,
		0x1EEA1, 0x1EEA3,
		0x1EEA5, 0x1EEA9,
		0x1EEAB, 0x1EEBB,
		0x1EEF0, 0x1EEF1,
	},
	direction = "rtl",
	normalizationFixes = {
		from = {"ٳ"},
		to = {"اٟ"}
	},
}

	m["fa-Arab"] = {
		"Arabic",
		m["Arab"][2],
		ranges = m["Arab"].ranges,
		characters = m["Arab"].characters,
		otherNames = {"Perso-Arabic"},
		direction = "rtl",
		parent = "Arab",
		normalizationFixes = m["Arab"].normalizationFixes,
	}

	m["kk-Arab"] = {
		"Arabic",
		m["Arab"][2],
		ranges = m["Arab"].ranges,
		characters = m["Arab"].characters,
		direction = "rtl",
		parent = "Arab",
		normalizationFixes = m["Arab"].normalizationFixes,
	}
	
	m["ks-Arab"] = m["fa-Arab"]
	m["ku-Arab"] = m["fa-Arab"]
	m["ms-Arab"] = m["kk-Arab"]
	m["mzn-Arab"] = m["fa-Arab"]
	m["ota-Arab"] = m["fa-Arab"]
	
	m["pa-Arab"] = {
		"Shahmukhi",
		m["Arab"][2],
		ranges = m["Arab"].ranges,
		characters = m["Arab"].characters,
		otherNames = {"Arabic"},
		direction = "rtl",
		parent = "Arab",
		normalizationFixes = m["Arab"].normalizationFixes,
	}
	
	m["ps-Arab"] = m["fa-Arab"]
	m["sd-Arab"] = m["fa-Arab"]
	m["tt-Arab"] = m["fa-Arab"]
	m["ug-Arab"] = m["fa-Arab"]
	m["ur-Arab"] = m["fa-Arab"]

-- Aran (Nastaliq) is subsumed into Arab

m["Armi"] = process_ranges{
	"Imperial Aramaic",
	"abjad",
	ranges = {
		0x10840, 0x10855,
		0x10857, 0x1085F,
	},
	direction = "rtl",
}

m["Armn"] = process_ranges{
	"Armenian",
	"alphabet",
	ranges = {
		0x0531, 0x0556,
		0x0559, 0x058A,
		0x058D, 0x058F,
		0xFB13, 0xFB17,
	},
	capitalized = true,
}

m["Avst"] = process_ranges{
	"Avestan",
	"alphabet",
	ranges = {
		0x10B00, 0x10B35,
		0x10B39, 0x10B3F,
	},
	direction = "rtl",
}

	m["pal-Avst"] = {
		"Pazend",
		m["Avst"][2],
		ranges = m["Avst"].ranges,
		characters = m["Avst"].characters,
		direction = "rtl",
		parent = "Avst",
	}

m["Bali"] = process_ranges{
	"Balinese",
	"abugida",
	ranges = {
		0x1B00, 0x1B4C,
		0x1B50, 0x1B7E,
	},
}

m["Bamu"] = process_ranges{
	"Bamum",
	"syllabary",
	ranges = {
		0xA6A0, 0xA6F7,
		0x16800, 0x16A38,
	},
}

m["Bass"] = process_ranges{
	"Bassa",
	"alphabet",
	aliases = {"Bassa Vah", "Vah"},
	ranges = {
		0x16AD0, 0x16AED,
		0x16AF0, 0x16AF5,
	},
}

m["Batk"] = process_ranges{
	"Batak",
	"abugida",
	ranges = {
		0x1BC0, 0x1BF3,
		0x1BFC, 0x1BFF,
	},
}

m["Beng"] = process_ranges{
	"Bengali",
	"abugida",
	ranges = {
		0x0951, 0x0952,
		0x0964, 0x0965,
		0x0980, 0x0983,
		0x0985, 0x098C,
		0x098F, 0x0990,
		0x0993, 0x09A8,
		0x09AA, 0x09B0,
		0x09B2, 0x09B2,
		0x09B6, 0x09B9,
		0x09BC, 0x09C4,
		0x09C7, 0x09C8,
		0x09CB, 0x09CE,
		0x09D7, 0x09D7,
		0x09DC, 0x09DD,
		0x09DF, 0x09E3,
		0x09E6, 0x09EF,
		0x09F2, 0x09FE,
		0x1CD0, 0x1CD0,
		0x1CD2, 0x1CD2,
		0x1CD5, 0x1CD6,
		0x1CD8, 0x1CD8,
		0x1CE1, 0x1CE1,
		0x1CEA, 0x1CEA,
		0x1CED, 0x1CED,
		0x1CF2, 0x1CF2,
		0x1CF5, 0x1CF7,
		0xA8F1, 0xA8F1,
	},
	normalizationFixes = {
		from = {"অা", "ঋৃ", "ঌৢ"},
		to = {"আ", "ৠ", "ৡ"}
	},
}

	m["as-Beng"] = process_ranges{
		"Assamese",
		m["Beng"][2],
		otherNames = {"Bengali-Assamese", "Eastern Nagari"},
		ranges = {
			0x0951, 0x0952,
			0x0964, 0x0965,
			0x0980, 0x0983,
			0x0985, 0x098C,
			0x098F, 0x0990,
			0x0993, 0x09A8,
			0x09AA, 0x09AF,
			0x09B2, 0x09B2,
			0x09B6, 0x09B9,
			0x09BC, 0x09C4,
			0x09C7, 0x09C8,
			0x09CB, 0x09CE,
			0x09D7, 0x09D7,
			0x09DC, 0x09DD,
			0x09DF, 0x09E3,
			0x09E6, 0x09FE,
			0x1CD0, 0x1CD0,
			0x1CD2, 0x1CD2,
			0x1CD5, 0x1CD6,
			0x1CD8, 0x1CD8,
			0x1CE1, 0x1CE1,
			0x1CEA, 0x1CEA,
			0x1CED, 0x1CED,
			0x1CF2, 0x1CF2,
			0x1CF5, 0x1CF7,
			0xA8F1, 0xA8F1,
		},
		normalizationFixes = m["Beng"].normalizationFixes,
	}

m["Bhks"] = process_ranges{
	"Bhaiksuki",
	"abugida",
	ranges = {
		0x11C00, 0x11C08,
		0x11C0A, 0x11C36,
		0x11C38, 0x11C45,
		0x11C50, 0x11C6C,
	},
}

m["Blis"] = {
	"Blissymbols",
	"logography",
	aliases = {"Blissymbolics"},
	-- Not in Unicode
}

m["Bopo"] = process_ranges{
	"Zhuyin",
	"semisyllabary",
	aliases = {"Zhuyin Fuhao", "Bopomofo"},
	ranges = {
		0x02EA, 0x02EB,
		0x3001, 0x3003,
		0x3008, 0x3011,
		0x3013, 0x301F,
		0x302A, 0x302D,
		0x3030, 0x3030,
		0x3037, 0x3037,
		0x30FB, 0x30FB,
		0x3105, 0x312F,
		0x31A0, 0x31BF,
		0xFE45, 0xFE46,
		0xFF61, 0xFF65,
	},
}

m["Brah"] = process_ranges{
	"Brahmi",
	"abugida",
	ranges = {
		0x11000, 0x1104D,
		0x11052, 0x11075,
		0x1107F, 0x1107F,
	},
	normalizationFixes = {
		from = {"𑀅𑀸", "𑀋𑀾", "𑀏𑁂"},
		to = {"𑀆", "𑀌", "𑀐"}
	},
}

m["Brai"] = process_ranges{
	"Braille",
	"alphabet",
	ranges = {
		0x2800, 0x28FF,
	},
}

m["Bugi"] = process_ranges{
	"Buginese",
	"abugida",
	aliases = {"Lontara"},
	ranges = {
		0x1A00, 0x1A1B,
		0x1A1E, 0x1A1F,
		0xA9CF, 0xA9CF,
	},
}

m["Buhd"] = process_ranges{
	"Buhid",
	"abugida",
	ranges = {
		0x1735, 0x1736,
		0x1740, 0x1751,
		0x1752, 0x1753,
	},
}

m["Cakm"] = process_ranges{
	"Chakma",
	"abugida",
	ranges = {
		0x09E6, 0x09EF,
		0x1040, 0x1049,
		0x11100, 0x11134,
		0x11136, 0x11147,
	},
}

m["Cans"] = process_ranges{
	"Canadian syllabics",
	"abugida",
	ranges = {
		0x1400, 0x167F,
		0x18B0, 0x18F5,
		0x11AB0, 0x11ABF,
	},
}

m["Cari"] = process_ranges{
	"Carian",
	"alphabet",
	ranges = {
		0x102A0, 0x102D0,
	},
}

m["Cham"] = process_ranges{
	"Cham",
	"abugida",
	ranges = {
		0xAA00, 0xAA36,
		0xAA40, 0xAA4D,
		0xAA50, 0xAA59,
		0xAA5C, 0xAA5F,
	},
}

m["Cher"] = process_ranges{
	"Cherokee",
	"syllabary",
	ranges = {
		0x13A0, 0x13F5,
		0x13F8, 0x13FD,
		0xAB70, 0xABBF,
	},
}

m["Chis"] = {
	"Chisoi",
	"abugida",
	-- Not in Unicode
}

m["Chrs"] = process_ranges{
	"Chorasmian",
	"abjad",
	ranges = {
		0x10FB0, 0x10FCB,
	},
	direction = "rtl",
}

m["Copt"] = process_ranges{
	"Coptic",
	"alphabet",
	ranges = {
		0x03E2, 0x03EF,
		0x2C80, 0x2CF3,
		0x2CF9, 0x2CFF,
		0x102E0, 0x102FB,
	},
	capitalized = true,
}

m["Cpmn"] = process_ranges{
	"Cypro-Minoan",
	"syllabary",
	aliases = {"Cypro Minoan"},
	ranges = {
		0x10100, 0x10101,
		0x12F90, 0x12FF2,
	},
}

m["Cprt"] = process_ranges{
	"Cypriot",
	"syllabary",
	ranges = {
		0x10100, 0x10102,
		0x10107, 0x10133,
		0x10137, 0x1013F,
		0x10800, 0x10805,
		0x10808, 0x10808,
		0x1080A, 0x10835,
		0x10837, 0x10838,
		0x1083C, 0x1083C,
		0x1083F, 0x1083F,
	},
	direction = "rtl",
}

m["Cyrl"] = process_ranges{
	"Cyrillic",
	"alphabet",
	ranges = {
		0x0400, 0x052F,
		0x1C80, 0x1C88,
		0x1D2B, 0x1D2B,
		0x1D78, 0x1D78,
		0x1DF8, 0x1DF8,
		0x2DE0, 0x2DFF,
		0x2E43, 0x2E43,
		0xA640, 0xA69F,
		0xFE2E, 0xFE2F,
		0x1E030, 0x1E06D,
		0x1E08F, 0x1E08F,
	},
	capitalized = true,
}

m["Cyrs"] = {
	"Old Cyrillic",
	m["Cyrl"][2],
	aliases = {"Early Cyrillic"},
	ranges = m["Cyrl"].ranges,
	characters = m["Cyrl"].characters,
	capitalized = m["Cyrl"].capitalized,
	wikipedia_article = "Early Cyrillic alphabet",
	normalizationFixes = {
		from = {"Ѹ", "ѹ"},
		to = {"Ꙋ", "ꙋ"}
	},
}

m["Deva"] = process_ranges{
	"Devanagari",
	"abugida",
	ranges = {
		0x0900, 0x097F,
		0x1CD0, 0x1CF6,
		0x1CF8, 0x1CF9,
		0x20F0, 0x20F0,
		0xA830, 0xA839,
		0xA8E0, 0xA8FF,
		0x11B00, 0x11B09,
	},
	normalizationFixes = {
		from = {"ॆॆ", "ेे", "ाॅ", "ाॆ", "ाꣿ", "ॊॆ", "ाे", "ाै", "ोे", "ाऺ", "ॖॖ", "अॅ", "अॆ", "अा", "एॅ", "एॆ", "एे", "एꣿ", "ऎॆ", "अॉ", "आॅ", "अॊ", "आॆ", "अो", "आे", "अौ", "आै", "ओे", "अऺ", "अऻ", "आऺ", "अाꣿ", "आꣿ", "ऒॆ", "अॖ", "अॗ", "ॶॖ", "्‍?ा"},
		to = {"ꣿ", "ै", "ॉ", "ॊ", "ॏ", "ॏ", "ो", "ौ", "ौ", "ऻ", "ॗ", "ॲ", "ऄ", "आ", "ऍ", "ऎ", "ऐ", "ꣾ", "ꣾ", "ऑ", "ऑ", "ऒ", "ऒ", "ओ", "ओ", "औ", "औ", "औ", "ॳ", "ॴ", "ॴ", "ॵ", "ॵ", "ॵ", "ॶ", "ॷ", "ॷ"}
	},
}

m["Diak"] = process_ranges{
	"Dhives Akuru",
	"abugida",
	aliases = {"Dhivehi Akuru", "Dives Akuru", "Divehi Akuru"},
	ranges = {
		0x11900, 0x11906,
		0x11909, 0x11909,
		0x1190C, 0x11913,
		0x11915, 0x11916,
		0x11918, 0x11935,
		0x11937, 0x11938,
		0x1193B, 0x11946,
		0x11950, 0x11959,
	},
}

m["Dogr"] = process_ranges{
	"Dogra",
	"abugida",
	ranges = {
		0x0964, 0x096F,
		0xA830, 0xA839,
		0x11800, 0x1183B,
	},
}

m["Dsrt"] = process_ranges{
	"Deseret",
	"alphabet",
	ranges = {
		0x10400, 0x1044F,
	},
	capitalized = true,
}

m["Dupl"] = process_ranges{
	"Duployan",
	"alphabet",
	ranges = {
		0x1BC00, 0x1BC6A,
		0x1BC70, 0x1BC7C,
		0x1BC80, 0x1BC88,
		0x1BC90, 0x1BC99,
		0x1BC9C, 0x1BCA3,
	},
}

m["Egyd"] = {
	"Demotic",
	"abjad, logography",
	-- Not in Unicode
}

m["Egyh"] = {
	"Hieratic",
	"abjad, logography",
	-- Unified with Egyptian hieroglyphic in Unicode
}

m["Egyp"] = process_ranges{
	"Egyptian hieroglyphic",
	"abjad, logography",
	ranges = {
		0x13000, 0x13455,
	},
	varieties = {"Hieratic"},
	wikipedia_article = "Egyptian hieroglyphs",
	normalizationFixes = {
		from = {"𓃁", "𓆖"},
		to = {"𓃀𓐶𓂝", "𓆓𓐳𓐷𓏏𓐰𓇿𓐸"}
	},
}

m["Elba"] = process_ranges{
	"Elbasan",
	"alphabet",
	ranges = {
		0x10500, 0x10527,
	},
}

m["Elym"] = process_ranges{
	"Elymaic",
	"abjad",
	ranges = {
		0x10FE0, 0x10FF6,
	},
	direction = "rtl",
}

m["Ethi"] = process_ranges{
	"Ethiopic",
	"abugida",
	aliases = {"Ge'ez"},
	ranges = {
		0x1200, 0x1248,
		0x124A, 0x124D,
		0x1250, 0x1256,
		0x1258, 0x1258,
		0x125A, 0x125D,
		0x1260, 0x1288,
		0x128A, 0x128D,
		0x1290, 0x12B0,
		0x12B2, 0x12B5,
		0x12B8, 0x12BE,
		0x12C0, 0x12C0,
		0x12C2, 0x12C5,
		0x12C8, 0x12D6,
		0x12D8, 0x1310,
		0x1312, 0x1315,
		0x1318, 0x135A,
		0x135D, 0x137C,
		0x1380, 0x1399,
		0x2D80, 0x2D96,
		0x2DA0, 0x2DA6,
		0x2DA8, 0x2DAE,
		0x2DB0, 0x2DB6,
		0x2DB8, 0x2DBE,
		0x2DC0, 0x2DC6,
		0x2DC8, 0x2DCE,
		0x2DD0, 0x2DD6,
		0x2DD8, 0x2DDE,
		0xAB01, 0xAB06,
		0xAB09, 0xAB0E,
		0xAB11, 0xAB16,
		0xAB20, 0xAB26,
		0xAB28, 0xAB2E,
		0x1E7E0, 0x1E7E6,
		0x1E7E8, 0x1E7EB,
		0x1E7ED, 0x1E7EE,
		0x1E7F0, 0x1E7FE,
	},
}

m["Gara"] = {
	"Garay",
	"alphabet",
	capitalized = true,
	direction = "rtl",
	-- Not in Unicode
}

m["Geok"] = process_ranges{
	"Khutsuri",
	"alphabet",
	ranges = { -- Ⴀ-Ⴭ is Asomtavruli, ⴀ-ⴭ is Nuskhuri
		0x10A0, 0x10C5,
		0x10C7, 0x10C7,
		0x10CD, 0x10CD,
		0x10FB, 0x10FB,
		0x2D00, 0x2D25,
		0x2D27, 0x2D27,
		0x2D2D, 0x2D2D,
	},
	varieties = {"Nuskhuri", "Asomtavruli"},
	capitalized = true,
}

m["Geor"] = process_ranges{
	"Georgian",
	"alphabet",
	ranges = { -- ა-ჿ is lowercase Mkhedruli; Ა-Ჿ is uppercase Mkhedruli (Mtavruli)
		0x10D0, 0x10FF,
		0x1C90, 0x1CBA,
		0x1CBD, 0x1CBF,
	},
	varieties = {"Mkhedruli", "Mtavruli"},
	capitalized = true,
}

m["Glag"] = process_ranges{
	"Glagolitic",
	"alphabet",
	ranges = {
		0x0484, 0x0484,
		0x0487, 0x0487,
		0x2C00, 0x2C5F,
		0x2E43, 0x2E43,
		0xA66F, 0xA66F,
		0x1E000, 0x1E006,
		0x1E008, 0x1E018,
		0x1E01B, 0x1E021,
		0x1E023, 0x1E024,
		0x1E026, 0x1E02A,
	},
	capitalized = true,
}

m["Gong"] = process_ranges{
	"Gunjala Gondi",
	"abugida",
	ranges = {
		0x0964, 0x0965,
		0x11D60, 0x11D65,
		0x11D67, 0x11D68,
		0x11D6A, 0x11D8E,
		0x11D90, 0x11D91,
		0x11D93, 0x11D98,
		0x11DA0, 0x11DA9,
	},
}

m["Gonm"] = process_ranges{
	"Masaram Gondi",
	"abugida",
	ranges = {
		0x0964, 0x0965,
		0x11D00, 0x11D06,
		0x11D08, 0x11D09,
		0x11D0B, 0x11D36,
		0x11D3A, 0x11D3A,
		0x11D3C, 0x11D3D,
		0x11D3F, 0x11D47,
		0x11D50, 0x11D59,
	},
}

m["Goth"] = process_ranges{
	"Gothic",
	"alphabet",
	ranges = {
		0x10330, 0x1034A,
	},
}

m["Gran"] = process_ranges{
	"Grantha",
	"abugida",
	ranges = {
		0x0951, 0x0952,
		0x0964, 0x0965,
		0x0BE6, 0x0BF3,
		0x1CD0, 0x1CD0,
		0x1CD2, 0x1CD3,
		0x1CF2, 0x1CF4,
		0x1CF8, 0x1CF9,
		0x20F0, 0x20F0,
		0x11300, 0x11303,
		0x11305, 0x1130C,
		0x1130F, 0x11310,
		0x11313, 0x11328,
		0x1132A, 0x11330,
		0x11332, 0x11333,
		0x11335, 0x11339,
		0x1133B, 0x11344,
		0x11347, 0x11348,
		0x1134B, 0x1134D,
		0x11350, 0x11350,
		0x11357, 0x11357,
		0x1135D, 0x11363,
		0x11366, 0x1136C,
		0x11370, 0x11374,
		0x11FD0, 0x11FD1,
		0x11FD3, 0x11FD3,
	},
}

m["Grek"] = process_ranges{
	"Greek",
	"alphabet",
	ranges = {
		0x0342, 0x0342,
		0x0345, 0x0345,
		0x0370, 0x0377,
		0x037A, 0x037F,
		0x0384, 0x038A,
		0x038C, 0x038C,
		0x038E, 0x03A1,
		0x03A3, 0x03E1,
		0x03F0, 0x03FF,
		0x1D26, 0x1D2A,
		0x1D5D, 0x1D61,
		0x1D66, 0x1D6A,
		0x1DBF, 0x1DBF,
		0x2126, 0x2127,
		0x2129, 0x2129,
		0x213C, 0x2140,
		0xAB65, 0xAB65,
		0x10140, 0x1018E,
		0x101A0, 0x101A0,
		0x1D200, 0x1D245,
	},
	capitalized = true,
}

	m["Polyt"] = process_ranges{
		"Greek",
		m["Grek"][2],
		ranges = union(m["Grek"].ranges, {
			0x1F00, 0x1F15,
			0x1F18, 0x1F1D,
			0x1F20, 0x1F45,
			0x1F48, 0x1F4D,
			0x1F50, 0x1F57,
			0x1F59, 0x1F59,
			0x1F5B, 0x1F5B,
			0x1F5D, 0x1F5D,
			0x1F5F, 0x1F7D,
			0x1F80, 0x1FB4,
			0x1FB6, 0x1FC4,
			0x1FC6, 0x1FD3,
			0x1FD6, 0x1FDB,
			0x1FDD, 0x1FEF,
			0x1FF2, 0x1FF4,
			0x1FF6, 0x1FFE,
		}),
		capitalized = m["Grek"].capitalized,
		parent = "Grek",
	}

m["Gujr"] = process_ranges{
	"Gujarati",
	"abugida",
	ranges = {
		0x0951, 0x0952,
		0x0964, 0x0965,
		0x0A81, 0x0A83,
		0x0A85, 0x0A8D,
		0x0A8F, 0x0A91,
		0x0A93, 0x0AA8,
		0x0AAA, 0x0AB0,
		0x0AB2, 0x0AB3,
		0x0AB5, 0x0AB9,
		0x0ABC, 0x0AC5,
		0x0AC7, 0x0AC9,
		0x0ACB, 0x0ACD,
		0x0AD0, 0x0AD0,
		0x0AE0, 0x0AE3,
		0x0AE6, 0x0AF1,
		0x0AF9, 0x0AFF,
		0xA830, 0xA839,
	},
	normalizationFixes = {
		from = {"ઓ", "અાૈ", "અા", "અૅ", "અે", "અૈ", "અૉ", "અો", "અૌ", "આૅ", "આૈ", "ૅા"},
		to = {"અાૅ", "ઔ", "આ", "ઍ", "એ", "ઐ", "ઑ", "ઓ", "ઔ", "ઓ", "ઔ", "ૉ"}
	},
}

m["Gukh"] = {
	"Khema",
	"abugida",
	aliases = {"Gurung Khema", "Khema Phri", "Khema Lipi"},
	-- Not in Unicode
}

m["Guru"] = process_ranges{
	"Gurmukhi",
	"abugida",
	ranges = {
		0x0951, 0x0952,
		0x0964, 0x0965,
		0x0A01, 0x0A03,
		0x0A05, 0x0A0A,
		0x0A0F, 0x0A10,
		0x0A13, 0x0A28,
		0x0A2A, 0x0A30,
		0x0A32, 0x0A33,
		0x0A35, 0x0A36,
		0x0A38, 0x0A39,
		0x0A3C, 0x0A3C,
		0x0A3E, 0x0A42,
		0x0A47, 0x0A48,
		0x0A4B, 0x0A4D,
		0x0A51, 0x0A51,
		0x0A59, 0x0A5C,
		0x0A5E, 0x0A5E,
		0x0A66, 0x0A76,
		0xA830, 0xA839,
	},
	normalizationFixes = {
		from = {"ਅਾ", "ਅੈ", "ਅੌ", "ੲਿ", "ੲੀ", "ੲੇ", "ੳੁ", "ੳੂ", "ੳੋ"},
		to = {"ਆ", "ਐ", "ਔ", "ਇ", "ਈ", "ਏ", "ਉ", "ਊ", "ਓ"}
	},
}

m["Hang"] = process_ranges{
	"Hangul",
	"syllabary",
	aliases = {"Hangeul"},
	ranges = {
		0x1100, 0x11FF,
		0x3001, 0x3003,
		0x3008, 0x3011,
		0x3013, 0x301F,
		0x302E, 0x3030,
		0x3037, 0x3037,
		0x30FB, 0x30FB,
		0x3131, 0x318E,
		0x3200, 0x321E,
		0x3260, 0x327E,
		0xA960, 0xA97C,
		0xAC00, 0xD7A3,
		0xD7B0, 0xD7C6,
		0xD7CB, 0xD7FB,
		0xFE45, 0xFE46,
		0xFF61, 0xFF65,
		0xFFA0, 0xFFBE,
		0xFFC2, 0xFFC7,
		0xFFCA, 0xFFCF,
		0xFFD2, 0xFFD7,
		0xFFDA, 0xFFDC,
	},
}

m["Hani"] = process_ranges{
	"Han",
	"logography",
	ranges = {
		0x2E80, 0x2E99,
		0x2E9B, 0x2EF3,
		0x2F00, 0x2FD5,
		0x3001, 0x3003,
		0x3005, 0x3011,
		0x3013, 0x301F,
		0x3021, 0x302D,
		0x3030, 0x3030,
		0x3037, 0x303F,
		0x3190, 0x319F,
		0x31C0, 0x31E3,
		0x3220, 0x3247,
		0x3280, 0x32B0,
		0x32C0, 0x32CB,
		0x30FB, 0x30FB,
		0x32FF, 0x32FF,
		0x3358, 0x3370,
		0x337B, 0x337F,
		0x33E0, 0x33FE,
		0x3400, 0x4DBF,
		0x4E00, 0x9FFF,
		0xA700, 0xA707,
		0xF900, 0xFA6D,
		0xFA70, 0xFAD9,
		0xFE45, 0xFE46,
		0xFF61, 0xFF65,
		0x16FE2, 0x16FE3,
		0x16FF0, 0x16FF1,
		0x1D360, 0x1D371,
		0x1F250, 0x1F251,
		0x20000, 0x2A6DF,
		0x2A700, 0x2B739,
		0x2B740, 0x2B81D,
		0x2B820, 0x2CEA1,
		0x2CEB0, 0x2EBE0,
		0x2EBF0, 0x2EE5D,
		0x2F800, 0x2FA1D,
		0x30000, 0x3134A,
		0x31350, 0x323AF,
	},
	varieties = {"Hanzi", "Kanji", "Hanja", "Chu Nom"},
	spaces = false,
}

	m["Hans"] = {
		"Simplified Han",
		m["Hani"][2],
		ranges = m["Hani"].ranges,
		characters = m["Hani"].characters,
		spaces = m["Hani"].spaces,
		parent = "Hani",
	}

	m["Hant"] = {
		"Traditional Han",
		m["Hani"][2],
		ranges = m["Hani"].ranges,
		characters = m["Hani"].characters,
		spaces = m["Hani"].spaces,
		parent = "Hani",
	}

m["Hano"] = process_ranges{
	"Hanunoo",
	"abugida",
	ranges = {
		0x1720, 0x1736,
	},
}

m["Hatr"] = process_ranges{
	"Hatran",
	"abjad",
	ranges = {
		0x108E0, 0x108F2,
		0x108F4, 0x108F5,
		0x108FB, 0x108FF,
	},
	direction = "rtl",
}

m["Hebr"] = process_ranges{
	"Hebrew",
	"abjad",	-- more precisely, impure abjad
	ranges = {
		0x0591, 0x05C7,
		0x05D0, 0x05EA,
		0x05EF, 0x05F4,
		0x2135, 0x2138,
		0xFB1D, 0xFB36,
		0xFB38, 0xFB3C,
		0xFB3E, 0xFB3E,
		0xFB40, 0xFB41,
		0xFB43, 0xFB44,
		0xFB46, 0xFB4F,
	},
	direction = "rtl",
}

m["Hira"] = process_ranges{
	"Hiragana",
	"syllabary",
	ranges = {
		0x3001, 0x3003,
		0x3008, 0x3011,
		0x3013, 0x301F,
		0x3030, 0x3035,
		0x3037, 0x3037,
		0x303C, 0x303D,
		0x3041, 0x3096,
		0x3099, 0x30A0,
		0x30FB, 0x30FC,
		0xFE45, 0xFE46,
		0xFF61, 0xFF65,
		0xFF70, 0xFF70,
		0xFF9E, 0xFF9F,
		0x1B001, 0x1B11F,
		0x1B132, 0x1B132,
		0x1B150, 0x1B152,
		0x1F200, 0x1F200,
	},
	varieties = {"Hentaigana"},
	spaces = false,
}

m["Hluw"] = process_ranges{
	"Anatolian Hieroglyphs",
	"logography, syllabary",
	ranges = {
		0x14400, 0x14646,
	},
	wikipedia_article = "Anatolian hieroglyphs",
}

m["Hmng"] = process_ranges{
	"Pahawh Hmong",
	"semisyllabary",
	aliases = {"Hmong"},
	ranges = {
		0x16B00, 0x16B45,
		0x16B50, 0x16B59,
		0x16B5B, 0x16B61,
		0x16B63, 0x16B77,
		0x16B7D, 0x16B8F,
	},
}

m["Hmnp"] = process_ranges{
	"Nyiakeng Puachue Hmong",
	"alphabet",
	ranges = {
		0x1E100, 0x1E12C,
		0x1E130, 0x1E13D,
		0x1E140, 0x1E149,
		0x1E14E, 0x1E14F,
	},
}

m["Hung"] = process_ranges{
	"Old Hungarian",
	"alphabet",
	aliases = {"Hungarian runic"},
	ranges = {
		0x10C80, 0x10CB2,
		0x10CC0, 0x10CF2,
		0x10CFA, 0x10CFF,
	},
	capitalized = true,
	direction = "rtl",
}

m["Ibrn"] = {
	"Iberian",
	"semisyllabary",
	-- Not in Unicode
}

m["Imag"] = {
	-- To be used to avoid any formatting or link processing
	"Image-rendered",
	-- This should not have any characters listed
	translit = false,
	character_category = false,
}

m["Inds"] = {
	"Indus",
	aliases = {"Harappan", "Indus Valley"},
}

m["Ipach"] = {
	"International Phonetic Alphabet",
	aliases = {"IPA"},
}

m["Ital"] = process_ranges{
	"Old Italic",
	"alphabet",
	ranges = {
		0x10300, 0x10323,
		0x1032D, 0x1032F,
	},
}

m["Java"] = process_ranges{
	"Javanese",
	"abugida",
	ranges = {
		0xA980, 0xA9CD,
		0xA9CF, 0xA9D9,
		0xA9DE, 0xA9DF,
	},
}

m["Jurc"] = {
	"Jurchen",
	"logography",
	spaces = false,
}

m["Kali"] = process_ranges{
	"Kayah Li",
	"abugida",
	ranges = {
		0xA900, 0xA92F,
	},
}

m["Kana"] = process_ranges{
	"Katakana",
	"syllabary",
	ranges = {
		0x3001, 0x3003,
		0x3008, 0x3011,
		0x3013, 0x301F,
		0x3030, 0x3035,
		0x3037, 0x3037,
		0x303C, 0x303D,
		0x3099, 0x309C,
		0x30A0, 0x30FF,
		0x31F0, 0x31FF,
		0x32D0, 0x32FE,
		0x3300, 0x3357,
		0xFE45, 0xFE46,
		0xFF61, 0xFF9F,
		0x1AFF0, 0x1AFF3,
		0x1AFF5, 0x1AFFB,
		0x1AFFD, 0x1AFFE,
		0x1B000, 0x1B000,
		0x1B120, 0x1B122,
		0x1B155, 0x1B155,
		0x1B164, 0x1B167,
	},
	spaces = false,
}

m["Kawi"] = process_ranges{
	"Kawi",
	"abugida",
	ranges = {
		0x11F00, 0x11F10,
		0x11F12, 0x11F3A,
		0x11F3E, 0x11F59,
	},
}

m["Khar"] = process_ranges{
	"Kharoshthi",
	"abugida",
	ranges = {
		0x10A00, 0x10A03,
		0x10A05, 0x10A06,
		0x10A0C, 0x10A13,
		0x10A15, 0x10A17,
		0x10A19, 0x10A35,
		0x10A38, 0x10A3A,
		0x10A3F, 0x10A48,
		0x10A50, 0x10A58,
	},
	direction = "rtl",
}

m["Khmr"] = process_ranges{
	"Khmer",
	"abugida",
	ranges = {
		0x1780, 0x17DD,
		0x17E0, 0x17E9,
		0x17F0, 0x17F9,
		0x19E0, 0x19FF,
	},
	spaces = false,
	normalizationFixes = {
		from = {"ឣ", "ឤ"},
		to = {"អ", "អា"}
	},
}

m["Khoj"] = process_ranges{
	"Khojki",
	"abugida",
	ranges = {
		0x0AE6, 0x0AEF,
		0xA830, 0xA839,
		0x11200, 0x11211,
		0x11213, 0x11241,
	},
	normalizationFixes = {
		from = {"𑈀𑈬𑈱", "𑈀𑈬", "𑈀𑈱", "𑈀𑈳", "𑈁𑈱", "𑈆𑈬", "𑈬𑈰", "𑈬𑈱", "𑉀𑈮"},
		to = {"𑈇", "𑈁", "𑈅", "𑈇", "𑈇", "𑈃", "𑈲", "𑈳", "𑈂"}
	},
}

m["Kitl"] = {
	"Khitan Large",
	"logography",
	spaces = false,
}

m["Kits"] = process_ranges{
	"Khitan Small",
	"logography, syllabary",
	ranges = {
		0x16FE4, 0x16FE4,
		0x18B00, 0x18CD5,
	},
	spaces = false,
}

m["Knda"] = process_ranges{
	"Kannada",
	"abugida",
	ranges = {
		0x0951, 0x0952,
		0x0964, 0x0965,
		0x0C80, 0x0C8C,
		0x0C8E, 0x0C90,
		0x0C92, 0x0CA8,
		0x0CAA, 0x0CB3,
		0x0CB5, 0x0CB9,
		0x0CBC, 0x0CC4,
		0x0CC6, 0x0CC8,
		0x0CCA, 0x0CCD,
		0x0CD5, 0x0CD6,
		0x0CDD, 0x0CDE,
		0x0CE0, 0x0CE3,
		0x0CE6, 0x0CEF,
		0x0CF1, 0x0CF3,
		0x1CD0, 0x1CD0,
		0x1CD2, 0x1CD2,
		0x1CDA, 0x1CDA,
		0x1CF2, 0x1CF2,
		0x1CF4, 0x1CF4,
		0xA830, 0xA835,
	},
	normalizationFixes = {
		from = {"ಉಾ", "ಋಾ", "ಒೌ"},
		to = {"ಊ", "ೠ", "ಔ"}
	},
}

m["Kpel"] = {
	"Kpelle",
	"syllabary",
	-- Not in Unicode
}

m["Krai"] = {
	"Kirat Rai",
	"abugida",
	aliases = {"Rai", "Khambu Rai", "Rai Barṇamālā", "Kirat Khambu Rai"},
	-- Not in Unicode
}

m["Kthi"] = process_ranges{
	"Kaithi",
	"abugida",
	ranges = {
		0x0966, 0x096F,
		0xA830, 0xA839,
		0x11080, 0x110C2,
		0x110CD, 0x110CD,
	},
}

m["Lana"] = process_ranges{
	"Tai Tham",
	"abugida",
	aliases = {"Tham", "Tua Mueang", "Lanna"},
	ranges = {
		0x1A20, 0x1A5E,
		0x1A60, 0x1A7C,
		0x1A7F, 0x1A89,
		0x1A90, 0x1A99,
		0x1AA0, 0x1AAD,
	},
	spaces = false,
}

m["Laoo"] = process_ranges{
	"Lao",
	"abugida",
	ranges = {
		0x0E81, 0x0E82,
		0x0E84, 0x0E84,
		0x0E86, 0x0E8A,
		0x0E8C, 0x0EA3,
		0x0EA5, 0x0EA5,
		0x0EA7, 0x0EBD,
		0x0EC0, 0x0EC4,
		0x0EC6, 0x0EC6,
		0x0EC8, 0x0ECE,
		0x0ED0, 0x0ED9,
		0x0EDC, 0x0EDF,
	},
	spaces = false,
}

m["Latn"] = process_ranges{
	"Latin",
	"alphabet",
	aliases = {"Roman"},
	ranges = {
		0x0041, 0x005A,
		0x0061, 0x007A,
		0x00AA, 0x00AA,
		0x00BA, 0x00BA,
		0x00C0, 0x00D6,
		0x00D8, 0x00F6,
		0x00F8, 0x02B8,
		0x02C0, 0x02C1,
		0x02E0, 0x02E4,
		0x0363, 0x036F,
		0x0485, 0x0486,
		0x0951, 0x0952,
		0x10FB, 0x10FB,
		0x1D00, 0x1D25,
		0x1D2C, 0x1D5C,
		0x1D62, 0x1D65,
		0x1D6B, 0x1D77,
		0x1D79, 0x1DBE,
		0x1E00, 0x1EFF,
		0x202F, 0x202F,
		0x2071, 0x2071,
		0x207F, 0x207F,
		0x2090, 0x209C,
		0x20F0, 0x20F0,
		0x2100, 0x2125,
		0x2128, 0x2128,
		0x212A, 0x2134,
		0x2139, 0x213B,
		0x2141, 0x214E,
		0x2160, 0x2188,
		0x2C60, 0x2C7F,
		0xA700, 0xA707,
		0xA722, 0xA787,
		0xA78B, 0xA7CA,
		0xA7D0, 0xA7D1,
		0xA7D3, 0xA7D3,
		0xA7D5, 0xA7D9,
		0xA7F2, 0xA7FF,
		0xA92E, 0xA92E,
		0xAB30, 0xAB5A,
		0xAB5C, 0xAB64,
		0xAB66, 0xAB69,
		0xFB00, 0xFB06,
		0xFF21, 0xFF3A,
		0xFF41, 0xFF5A,
		0x10780, 0x10785,
		0x10787, 0x107B0,
		0x107B2, 0x107BA,
		0x1DF00, 0x1DF1E,
		0x1DF25, 0x1DF2A,
	},
	varieties = {"Rumi", "Romaji", "Rōmaji", "Romaja"},
	capitalized = true,
	translit = false,
}

	m["Latf"] = {
		"Fraktur",
		m["Latn"][2],
		ranges = m["Latn"].ranges,
		characters = m["Latn"].characters,
		otherNames = {"Blackletter"}, -- Blackletter is actually the parent "script"
		capitalized = m["Latn"].capitalized,
		translit = m["Latn"].translit,
		parent = "Latn",
	}
	
	m["Latg"] = {
		"Gaelic",
		m["Latn"][2],
		ranges = m["Latn"].ranges,
		characters = m["Latn"].characters,
		otherNames = {"Irish"},
		capitalized = m["Latn"].capitalized,
		translit = m["Latn"].translit,
		parent = "Latn",
	}
	
	m["pjt-Latn"] = {
		"Latin",
		m["Latn"][2],
		ranges = m["Latn"].ranges,
		characters = m["Latn"].characters,
		capitalized = m["Latn"].capitalized,
		translit = m["Latn"].translit,
		parent = "Latn",
	}

m["Leke"] = {
	"Leke",
	"abugida",
	-- Not in Unicode
}

m["Lepc"] = process_ranges{
	"Lepcha",
	"abugida",
	ranges = {
		0x1C00, 0x1C37,
		0x1C3B, 0x1C49,
		0x1C4D, 0x1C4F,
	},
}

m["Limb"] = process_ranges{
	"Limbu",
	"abugida",
	ranges = {
		0x0965, 0x0965,
		0x1900, 0x191E,
		0x1920, 0x192B,
		0x1930, 0x193B,
		0x1940, 0x1940,
		0x1944, 0x194F,
	},
}

m["Lina"] = process_ranges{
	"Linear A",
	ranges = {
		0x10107, 0x10133,
		0x10600, 0x10736,
		0x10740, 0x10755,
		0x10760, 0x10767,
	},
}

m["Linb"] = process_ranges{
	"Linear B",
	ranges = {
		0x10000, 0x1000B,
		0x1000D, 0x10026,
		0x10028, 0x1003A,
		0x1003C, 0x1003D,
		0x1003F, 0x1004D,
		0x10050, 0x1005D,
		0x10080, 0x100FA,
		0x10100, 0x10102,
		0x10107, 0x10133,
		0x10137, 0x1013F,
	},
}

m["Lisu"] = process_ranges{
	"Lisu",
	"alphabet",
	aliases = {"Fraser"},
	ranges = {
		0xA4D0, 0xA4FF,
		0x11FB0, 0x11FB0,
	},
	normalizationFixes = {
		from = {"['’]", "[.ꓸ][.ꓸ]", "[.ꓸ][,ꓹ]"},
		to = {"ʼ", "ꓺ", "ꓻ"}
	},
}

m["Loma"] = {
	"Loma",
	"syllabary",
	-- Not in Unicode
}

m["Lyci"] = process_ranges{
	"Lycian",
	"alphabet",
	ranges = {
		0x10280, 0x1029C,
	},
}

m["Lydi"] = process_ranges{
	"Lydian",
	"alphabet",
	ranges = {
		0x10920, 0x10939,
		0x1093F, 0x1093F,
	},
	direction = "rtl",
}

m["Mahj"] = process_ranges{
	"Mahajani",
	"abugida",
	ranges = {
		0x0964, 0x096F,
		0xA830, 0xA839,
		0x11150, 0x11176,
	},
}

m["Maka"] = process_ranges{
	"Lontara",
	"abugida",
	aliases = {"Makasar"},
	ranges = {
		0x11EE0, 0x11EF8,
	},
}

m["Mand"] = process_ranges{
	"Mandaic",
	aliases = {"Mandaean"},
	ranges = {
		0x0640, 0x0640,
		0x0840, 0x085B,
		0x085E, 0x085E,
	},
	direction = "rtl",
}

m["Mani"] = process_ranges{
	"Manichaean",
	"abjad",
	ranges = {
		0x0640, 0x0640,
		0x10AC0, 0x10AE6,
		0x10AEB, 0x10AF6,
	},
	direction = "rtl",
}

m["Marc"] = process_ranges{
	"Marchen",
	"abugida",
	ranges = {
		0x11C70, 0x11C8F,
		0x11C92, 0x11CA7,
		0x11CA9, 0x11CB6,
	},
}

m["Maya"] = process_ranges{
	"Maya",
	aliases = {"Maya hieroglyphic", "Mayan", "Mayan hieroglyphic"},
	ranges = {
		0x1D2E0, 0x1D2F3,
	},
}

m["Medf"] = process_ranges{
	"Medefaidrin",
	aliases = {"Oberi Okaime", "Oberi Ɔkaimɛ"},
	ranges = {
		0x16E40, 0x16E9A,
	},
	capitalized = true,
}

m["Mend"] = process_ranges{
	"Mende",
	aliases = {"Mende Kikakui"},
	ranges = {
		0x1E800, 0x1E8C4,
		0x1E8C7, 0x1E8D6,
	},
	direction = "rtl",
}

m["Merc"] = process_ranges{
	"Meroitic cursive",
	"abugida",
	ranges = {
		0x109A0, 0x109B7,
		0x109BC, 0x109CF,
		0x109D2, 0x109FF,
	},
	direction = "rtl",
}

m["Mero"] = process_ranges{
	"Meroitic hieroglyphic",
	"abugida",
	ranges = {
		0x10980, 0x1099F,
	},
	direction = "rtl",
}

m["Mlym"] = process_ranges{
	"Malayalam",
	"abugida",
	ranges = {
		0x0951, 0x0952,
		0x0964, 0x0965,
		0x0D00, 0x0D0C,
		0x0D0E, 0x0D10,
		0x0D12, 0x0D44,
		0x0D46, 0x0D48,
		0x0D4A, 0x0D4F,
		0x0D54, 0x0D63,
		0x0D66, 0x0D7F,
		0x1CDA, 0x1CDA,
		0x1CF2, 0x1CF2,
		0xA830, 0xA832,
	},
	normalizationFixes = {
		from = {"ഇൗ", "ഉൗ", "എെ", "ഒാ", "ഒൗ", "ക്‍", "ണ്‍", "ന്‍റ", "ന്‍", "മ്‍", "യ്‍", "ര്‍", "ല്‍", "ള്‍", "ഴ്‍", "െെ", "ൻ്റ"},
		to = {"ഈ", "ഊ", "ഐ", "ഓ", "ഔ", "ൿ", "ൺ", "ൻറ", "ൻ", "ൔ", "ൕ", "ർ", "ൽ", "ൾ", "ൖ", "ൈ", "ന്റ"}
	},
}

m["Modi"] = process_ranges{
	"Modi",
	"abugida",
	ranges = {
		0xA830, 0xA839,
		0x11600, 0x11644,
		0x11650, 0x11659,
	},
	normalizationFixes = {
		from = {"𑘀𑘹", "𑘀𑘺", "𑘁𑘹", "𑘁𑘺"},
		to = {"𑘊", "𑘋", "𑘌", "𑘍"}
	},
}

m["Mong"] = process_ranges{
	"Mongolian",
	"alphabet",
	aliases = {"Mongol bichig", "Hudum Mongol bichig"},
	ranges = {
		0x1800, 0x1805,
		0x180A, 0x1819,
		0x1820, 0x1842,
		0x1878, 0x1878,
		0x1880, 0x1897,
		0x18A6, 0x18A6,
		0x18A9, 0x18A9,
		0x200C, 0x200D,
		0x202F, 0x202F,
		0x11660, 0x11668,
	},
	direction = "vertical-ltr",
}

	m["mnc-Mong"] = process_ranges{
		"Manchu",
		m["Mong"][2],
		ranges = {
			0x1801, 0x1801,
			0x1804, 0x1804,
			0x1808, 0x180F,
			0x1820, 0x1820,
			0x1823, 0x1823,
			0x1828, 0x182A,
			0x182E, 0x1830,
			0x1834, 0x1838,
			0x183A, 0x183A,
			0x185D, 0x185D,
			0x185F, 0x1861,
			0x1864, 0x1869,
			0x186C, 0x1871,
			0x1873, 0x1877,
			0x1880, 0x1888,
			0x188F, 0x188F,
			0x189A, 0x18A5,
			0x18A8, 0x18A8,
			0x18AA, 0x18AA,
			0x200C, 0x200D,
			0x202F, 0x202F,
		},
		direction = "vertical-ltr",
		parent = "Mong",
	}
	
	m["sjo-Mong"] = process_ranges{
		"Xibe",
		m["Mong"][2],
		aliases = {"Sibe"},
		ranges = {
			0x1804, 0x1804,
			0x1807, 0x1807,
			0x180A, 0x180F,
			0x1820, 0x1820,
			0x1823, 0x1823,
			0x1828, 0x1828,
			0x182A, 0x182A,
			0x182E, 0x1830,
			0x1834, 0x1838,
			0x183A, 0x183A,
			0x185D, 0x1872,
			0x200C, 0x200D,
			0x202F, 0x202F,
		},
		direction = "vertical-ltr",
		parent = "mnc-Mong",
	}
	
	m["xwo-Mong"] = process_ranges{
		"Clear Script",
		m["Mong"][2],
		aliases = {"Todo", "Todo bichig"},
		ranges = {
			0x1800, 0x1801,
			0x1804, 0x1806,
			0x180A, 0x1820,
			0x1828, 0x1828,
			0x182F, 0x1831,
			0x1834, 0x1834,
			0x1837, 0x1838,
			0x183A, 0x183B,
			0x1840, 0x1840,
			0x1843, 0x185C,
			0x1880, 0x1887,
			0x1889, 0x188F,
			0x1894, 0x1894,
			0x1896, 0x1899,
			0x18A7, 0x18A7,
			0x200C, 0x200D,
			0x202F, 0x202F,
			0x11669, 0x1166C,
		},
		direction = "vertical-ltr",
		parent = "Mong",
	}

m["Moon"] = {
	"Moon",
	"alphabet",
	aliases = {"Moon System of Embossed Reading", "Moon type", "Moon writing", "Moon alphabet", "Moon code"},
	-- Not in Unicode
}

m["Morse"] = {
	"Morse code",
}

m["Mroo"] = process_ranges{
	"Mro",
	ranges = {
		0x16A40, 0x16A5E,
		0x16A60, 0x16A69,
		0x16A6E, 0x16A6F,
	},
}

m["Mtei"] = process_ranges{
	"Meitei Mayek",
	"abugida",
	aliases = {"Meetei Mayek", "Manipuri"},
	ranges = {
		0xAAE0, 0xAAF6,
		0xABC0, 0xABED,
		0xABF0, 0xABF9,
	},
}

m["Mult"] = process_ranges{
	"Multani",
	"abugida",
	ranges = {
		0x0A66, 0x0A6F,
		0x11280, 0x11286,
		0x11288, 0x11288,
		0x1128A, 0x1128D,
		0x1128F, 0x1129D,
		0x1129F, 0x112A9,
	},
}

m["Music"] = process_ranges{
	"Musical notation",
	"pictography",
	ranges = {
		0x2669, 0x266F,
		0x1D100, 0x1D126,
		0x1D129, 0x1D1EA,
	},
	translit = false,
}

m["Mymr"] = process_ranges{
	"Burmese",
	"abugida",
	aliases = {"Myanmar"},
	ranges = {
		0x1000, 0x109F,
		0xA92E, 0xA92E,
		0xA9E0, 0xA9FE,
		0xAA60, 0xAA7F,
	},
	spaces = false,
}

m["Nagm"] = process_ranges{
	"Nag Mundari",
	"alphabet",
	ranges = {
		0x1E4D0, 0x1E4F9,
	},
}

m["Nand"] = process_ranges{
	"Nandinagari",
	"abugida",
	ranges = {
		0x0964, 0x0965,
		0x0CE6, 0x0CEF,
		0x1CE9, 0x1CE9,
		0x1CF2, 0x1CF2,
		0x1CFA, 0x1CFA,
		0xA830, 0xA835,
		0x119A0, 0x119A7,
		0x119AA, 0x119D7,
		0x119DA, 0x119E4,
	},
}

m["Narb"] = process_ranges{
	"Old North Arabian",
	"abjad",
	ranges = {
		0x10A80, 0x10A9F,
	},
	direction = "rtl",
}

m["Nbat"] = process_ranges{
	"Nabataean",
	"abjad",
	aliases = {"Nabatean"},
	ranges = {
		0x10880, 0x1089E,
		0x108A7, 0x108AF,
	},
	direction = "rtl",
}

m["Newa"] = process_ranges{
	"Newa",
	"abugida",
	aliases = {"Newar", "Newari", "Prachalit Nepal"},
	ranges = {
		0x11400, 0x1145B,
		0x1145D, 0x11461,
	},
}

m["Nkdb"] = {
	"Dongba",
	"pictography",
	aliases = {"Naxi Dongba", "Nakhi Dongba", "Tomba", "Tompa", "Mo-so"},
	spaces = false,
	-- Not in Unicode
}

m["Nkgb"] = {
	"Geba",
	"syllabary",
	aliases = {"Nakhi Geba", "Naxi Geba"},
	spaces = false,
	-- Not in Unicode
}

m["Nkoo"] = process_ranges{
	"N'Ko",
	"alphabet",
	ranges = {
		0x060C, 0x060C,
		0x061B, 0x061B,
		0x061F, 0x061F,
		0x07C0, 0x07FA,
		0x07FD, 0x07FF,
		0xFD3E, 0xFD3F,
	},
	direction = "rtl",
}

m["None"] = {
	"Unspecified", -- renders as 'unspecified script'
	-- This should not have any characters listed
	translit = false,
	character_category = false,
}

m["Nshu"] = process_ranges{
	"Nüshu",
	"syllabary",
	aliases = {"Nushu"},
	ranges = {
		0x16FE1, 0x16FE1,
		0x1B170, 0x1B2FB,
	},
	spaces = false,
}

m["Ogam"] = process_ranges{
	"Ogham",
	ranges = {
		0x1680, 0x169C,
	},
}

m["Olck"] = process_ranges{
	"Ol Chiki",
	ranges = {
		0x1C50, 0x1C7F,
	},
}

m["Onao"] = {
	"Ol Onal",
	"alphabet",
	-- Not in Unicode
}

m["Orkh"] = process_ranges{
	"Orkhon runes",
	aliases = {"Old Turkic"},
	ranges = {
		0x10C00, 0x10C48,
	},
	direction = "rtl",
}

m["Orya"] = process_ranges{
	"Odia",
	"abugida",
	aliases = {"Oriya"},
	ranges = {
		0x0951, 0x0952,
		0x0964, 0x0965,
		0x0B01, 0x0B03,
		0x0B05, 0x0B0C,
		0x0B0F, 0x0B10,
		0x0B13, 0x0B28,
		0x0B2A, 0x0B30,
		0x0B32, 0x0B33,
		0x0B35, 0x0B39,
		0x0B3C, 0x0B44,
		0x0B47, 0x0B48,
		0x0B4B, 0x0B4D,
		0x0B55, 0x0B57,
		0x0B5C, 0x0B5D,
		0x0B5F, 0x0B63,
		0x0B66, 0x0B77,
		0x1CDA, 0x1CDA,
		0x1CF2, 0x1CF2,
	},
	normalizationFixes = {
		from = {"ଅା", "ଏୗ", "ଓୗ"},
		to = {"ଆ", "ଐ", "ଔ"}
	},
}

m["Osge"] = process_ranges{
	"Osage",
	ranges = {
		0x104B0, 0x104D3,
		0x104D8, 0x104FB,
	},
	capitalized = true,
}

m["Osma"] = process_ranges{
	"Osmanya",
	ranges = {
		0x10480, 0x1049D,
		0x104A0, 0x104A9,
	},
}

m["Ougr"] = process_ranges{
	"Old Uyghur",
	"abjad, alphabet",
	ranges = {
		0x0640, 0x0640,
		0x10AF2, 0x10AF2,
		0x10F70, 0x10F89,
	},
	-- This should ideally be "vertical-ltr", but getting the CSS right is tricky because it's right-to-left horizontally, but left-to-right vertically. Currently, displaying it vertically causes it to display bottom-to-top.
	direction = "rtl",
}

m["Palm"] = process_ranges{
	"Palmyrene",
	ranges = {
		0x10860, 0x1087F,
	},
	direction = "rtl",
}

m["Pauc"] = process_ranges{
	"Pau Cin Hau",
	ranges = {
		0x11AC0, 0x11AF8,
	},
}

m["Perm"] = process_ranges{
	"Old Permic",
	ranges = {
		0x0483, 0x0483,
		0x10350, 0x1037A,
	},
}

m["Phag"] = process_ranges{
	"Phags-pa",
	"abugida",
	ranges = {
		0x1802, 0x1803,
		0x1805, 0x1805,
		0x200C, 0x200D,
		0x202F, 0x202F,
		0x3002, 0x3002,
		0xA840, 0xA877,
	},
	direction = "vertical-ltr",
}

m["Phli"] = process_ranges{
	"Inscriptional Pahlavi",
	"abjad",
	ranges = {
		0x10B60, 0x10B72,
		0x10B78, 0x10B7F,
	},
	direction = "rtl",
}

m["Phlp"] = process_ranges{
	"Psalter Pahlavi",
	"abjad",
	ranges = {
		0x0640, 0x0640,
		0x10B80, 0x10B91,
		0x10B99, 0x10B9C,
		0x10BA9, 0x10BAF,
	},
	direction = "rtl",
}

m["Phlv"] = {
	"Book Pahlavi",
	"abjad",
	direction = "rtl",
	-- Not in Unicode
}

m["Phnx"] = process_ranges{
	"Phoenician",
	"abjad",
	ranges = {
		0x10900, 0x1091B,
		0x1091F, 0x1091F,
	},
	direction = "rtl",
}

m["Plrd"] = process_ranges{
	"Pollard",
	"abugida",
	aliases = {"Miao"},
	ranges = {
		0x16F00, 0x16F4A,
		0x16F4F, 0x16F87,
		0x16F8F, 0x16F9F,
	},
}

m["Prti"] = process_ranges{
	"Inscriptional Parthian",
	ranges = {
		0x10B40, 0x10B55,
		0x10B58, 0x10B5F,
	},
	direction = "rtl",
}

m["Ranj"] = {
	"Ranjana",
	"abugida",
	-- Not in Unicode
}

m["Rjng"] = process_ranges{
	"Rejang",
	"abugida",
	ranges = {
		0xA930, 0xA953,
		0xA95F, 0xA95F,
	},
}

m["Rohg"] = process_ranges{
	"Hanifi Rohingya",
	"alphabet",
	ranges = {
		0x060C, 0x060C,
		0x061B, 0x061B,
		0x061F, 0x061F,
		0x0640, 0x0640,
		0x06D4, 0x06D4,
		0x10D00, 0x10D27,
		0x10D30, 0x10D39,
	},
	direction = "rtl",
}

m["Roro"] = {
	"Rongorongo",
	-- Not in Unicode
}

m["Rumin"] = process_ranges{
	"Rumi numerals",
	ranges = {
		0x10E60, 0x10E7E,
	},
	character_category = "Rumi numerals",
}

m["Runr"] = process_ranges{
	"Runic",
	"alphabet",
	ranges = {
		0x16A0, 0x16EA,
		0x16EE, 0x16F8,
	},
}

m["Samr"] = process_ranges{
	"Samaritan",
	"abjad",
	ranges = {
		0x0800, 0x082D,
		0x0830, 0x083E,
	},
	direction = "rtl",
}

m["Sarb"] = process_ranges{
	"Old South Arabian",
	"abjad",
	ranges = {
		0x10A60, 0x10A7F,
	},
	direction = "rtl",
}

m["Saur"] = process_ranges{
	"Saurashtra",
	"abugida",
	ranges = {
		0xA880, 0xA8C5,
		0xA8CE, 0xA8D9,
	},
}

m["Semap"] = {
	"flag semaphore",
	"pictography",
}

m["Sgnw"] = process_ranges{
	"SignWriting",
	"pictography",
	aliases = {"Sutton SignWriting"},
	ranges = {
		0x1D800, 0x1DA8B,
		0x1DA9B, 0x1DA9F,
		0x1DAA1, 0x1DAAF,
	},
	translit = false,
}

m["Shaw"] = process_ranges{
	"Shavian",
	aliases = {"Shaw"},
	ranges = {
		0x10450, 0x1047F,
	},
}

m["Shrd"] = process_ranges{
	"Sharada",
	"abugida",
	ranges = {
		0x0951, 0x0951,
		0x1CD7, 0x1CD7,
		0x1CD9, 0x1CD9,
		0x1CDC, 0x1CDD,
		0x1CE0, 0x1CE0,
		0xA830, 0xA835,
		0xA838, 0xA838,
		0x11180, 0x111DF,
	},
}

m["Shui"] = {
	"Sui",
	"logography",
	spaces = false,
	-- Not in Unicode
}

m["Sidd"] = process_ranges{
	"Siddham",
	"abugida",
	ranges = {
		0x11580, 0x115B5,
		0x115B8, 0x115DD,
	},
}

m["Sidt"] = {
	"Sidetic",
	"alphabet",
	direction = "rtl",
	-- Not in Unicode
}

m["Sind"] = process_ranges{
	"Khudawadi",
	"abugida",
	aliases = {"Khudabadi"},
	ranges = {
		0x0964, 0x0965,
		0xA830, 0xA839,
		0x112B0, 0x112EA,
		0x112F0, 0x112F9,
	},
	normalizationFixes = {
		from = {"𑊰𑋠", "𑊰𑋥", "𑊰𑋦", "𑊰𑋧", "𑊰𑋨"},
		to = {"𑊱", "𑊶", "𑊷", "𑊸", "𑊹"}
	},
}

m["Sinh"] = process_ranges{
	"Sinhalese",
	"abugida",
	aliases = {"Sinhala"},
	ranges = {
		0x0964, 0x0965,
		0x0D81, 0x0D83,
		0x0D85, 0x0D96,
		0x0D9A, 0x0DB1,
		0x0DB3, 0x0DBB,
		0x0DBD, 0x0DBD,
		0x0DC0, 0x0DC6,
		0x0DCA, 0x0DCA,
		0x0DCF, 0x0DD4,
		0x0DD6, 0x0DD6,
		0x0DD8, 0x0DDF,
		0x0DE6, 0x0DEF,
		0x0DF2, 0x0DF4,
		0x1CF2, 0x1CF2,
		0x111E1, 0x111F4,
	},
	normalizationFixes = {
		from = {"අා", "අැ", "අෑ", "උෟ", "ඍෘ", "ඏෟ", "එ්", "එෙ", "ඔෟ", "ෘෘ"},
		to = {"ආ", "ඇ", "ඈ", "ඌ", "ඎ", "ඐ", "ඒ", "ඓ", "ඖ", "ෲ"}
	},
}

m["Sogd"] = process_ranges{
	"Sogdian",
	"abjad",
	ranges = {
		0x0640, 0x0640,
		0x10F30, 0x10F59,
	},
	direction = "rtl",
}

m["Sogo"] = process_ranges{
	"Old Sogdian",
	"abjad",
	ranges = {
		0x10F00, 0x10F27,
	},
	direction = "rtl",
}

m["Sora"] = process_ranges{
	"Sorang Sompeng",
	aliases = {"Sora Sompeng"},
	ranges = {
		0x110D0, 0x110E8,
		0x110F0, 0x110F9,
	},
}

m["Soyo"] = process_ranges{
	"Soyombo",
	"abugida",
	ranges = {
		0x11A50, 0x11AA2,
	},
}

m["Sund"] = process_ranges{
	"Sundanese",
	"abugida",
	ranges = {
		0x1B80, 0x1BBF,
		0x1CC0, 0x1CC7,
	},
}

m["Sunu"] = {
	"Sunuwar",
	"alphabet",
	-- Not in Unicode
}

m["Sylo"] = process_ranges{
	"Syloti Nagri",
	"abugida",
	aliases = {"Sylheti Nagari"},
	ranges = {
		0x0964, 0x0965,
		0x09E6, 0x09EF,
		0xA800, 0xA82C,
	},
}

m["Syrc"] = process_ranges{
	"Syriac",
	"abjad",	-- more precisely, impure abjad
	ranges = {
		0x060C, 0x060C,
		0x061B, 0x061C,
		0x061F, 0x061F,
		0x0640, 0x0640,
		0x064B, 0x0655,
		0x0670, 0x0670,
		0x0700, 0x070D,
		0x070F, 0x074A,
		0x074D, 0x074F,
		0x0860, 0x086A,
		0x1DF8, 0x1DF8,
		0x1DFA, 0x1DFA,
	},
	direction = "rtl",
}

-- Syre, Syrj, Syrn are apparently subsumed into Syrc; discuss if this causes issues

m["Tagb"] = process_ranges{
	"Tagbanwa",
	"abugida",
	ranges = {
		0x1735, 0x1736,
		0x1760, 0x176C,
		0x176E, 0x1770,
		0x1772, 0x1773,
	},
}

m["Takr"] = process_ranges{
	"Takri",
	"abugida",
	ranges = {
		0x0964, 0x0965,
		0xA830, 0xA839,
		0x11680, 0x116B9,
		0x116C0, 0x116C9,
	},
	normalizationFixes = {
		from = {"𑚀𑚭", "𑚀𑚴", "𑚀𑚵", "𑚆𑚲"},
		to = {"𑚁", "𑚈", "𑚉", "𑚇"}
	},
}

m["Tale"] = process_ranges{
	"Tai Nüa",
	"abugida",
	aliases = {"Tai Nuea", "New Tai Nüa", "New Tai Nuea", "Dehong Dai", "Tai Dehong", "Tai Le"},
	ranges = {
		0x1040, 0x1049,
		0x1950, 0x196D,
		0x1970, 0x1974,
	},
	spaces = false,
}

m["Talu"] = process_ranges{
	"New Tai Lue",
	"abugida",
	ranges = {
		0x1980, 0x19AB,
		0x19B0, 0x19C9,
		0x19D0, 0x19DA,
		0x19DE, 0x19DF,
	},
	spaces = false,
}

m["Taml"] = process_ranges{
	"Tamil",
	"abugida",
	ranges = {
		0x0951, 0x0952,
		0x0964, 0x0965,
		0x0B82, 0x0B83,
		0x0B85, 0x0B8A,
		0x0B8E, 0x0B90,
		0x0B92, 0x0B95,
		0x0B99, 0x0B9A,
		0x0B9C, 0x0B9C,
		0x0B9E, 0x0B9F,
		0x0BA3, 0x0BA4,
		0x0BA8, 0x0BAA,
		0x0BAE, 0x0BB9,
		0x0BBE, 0x0BC2,
		0x0BC6, 0x0BC8,
		0x0BCA, 0x0BCD,
		0x0BD0, 0x0BD0,
		0x0BD7, 0x0BD7,
		0x0BE6, 0x0BFA,
		0x1CDA, 0x1CDA,
		0xA8F3, 0xA8F3,
		0x11301, 0x11301,
		0x11303, 0x11303,
		0x1133B, 0x1133C,
		0x11FC0, 0x11FF1,
		0x11FFF, 0x11FFF,
	},
	normalizationFixes = {
		from = {"அூ", "ஸ்ரீ"},
		to = {"ஆ", "ஶ்ரீ"}
	},
}

m["Tang"] = process_ranges{
	"Tangut",
	"logography, syllabary",
	ranges = {
		0x16FE0, 0x16FE0,
		0x17000, 0x187F7,
		0x18800, 0x18AFF,
		0x18D00, 0x18D08,
	},
	spaces = false,
}

m["Tavt"] = process_ranges{
	"Tai Viet",
	"abugida",
	ranges = {
		0xAA80, 0xAAC2,
		0xAADB, 0xAADF,
	},
	spaces = false,
}

m["Tayo"] = {
	"Lai Tay",
	"abugida",
	aliases = {"Tai Yo"},
	direction = "vertical-rtl",
	-- Not in Unicode
}

m["Telu"] = process_ranges{
	"Telugu",
	"abugida",
	ranges = {
		0x0951, 0x0952,
		0x0964, 0x0965,
		0x0C00, 0x0C0C,
		0x0C0E, 0x0C10,
		0x0C12, 0x0C28,
		0x0C2A, 0x0C39,
		0x0C3C, 0x0C44,
		0x0C46, 0x0C48,
		0x0C4A, 0x0C4D,
		0x0C55, 0x0C56,
		0x0C58, 0x0C5A,
		0x0C5D, 0x0C5D,
		0x0C60, 0x0C63,
		0x0C66, 0x0C6F,
		0x0C77, 0x0C7F,
		0x1CDA, 0x1CDA,
		0x1CF2, 0x1CF2,
	},
	normalizationFixes = {
		from = {"ఒౌ", "ఒౕ", "ిౕ", "ెౕ", "ొౕ"},
		to = {"ఔ", "ఓ", "ీ", "ే", "ో"}
	},
}

m["Teng"] = {
	"Tengwar",
}

m["Tfng"] = process_ranges{
	"Tifinagh",
	"abjad, alphabet",
	ranges = {
		0x2D30, 0x2D67,
		0x2D6F, 0x2D70,
		0x2D7F, 0x2D7F,
	},
	otherNames = {"Libyco-Berber", "Berber"}, -- per Wikipedia, Libyco-Berber is the parent
}

m["Tglg"] = process_ranges{
	"Baybayin",
	"abugida",
	aliases = {"Tagalog"},
	ranges = {
		0x1700, 0x1715,
		0x171F, 0x171F,
		0x1735, 0x1736,
	},
}

m["Thaa"] = process_ranges{
	"Thaana",
	"abugida",
	ranges = {
		0x060C, 0x060C,
		0x061B, 0x061C,
		0x061F, 0x061F,
		0x0660, 0x0669,
		0x0780, 0x07B1,
		0xFDF2, 0xFDF2,
		0xFDFD, 0xFDFD,
	},
	direction = "rtl",
}

m["Thai"] = process_ranges{
	"Thai",
	"abugida",
	ranges = {
		0x0E01, 0x0E3A,
		0x0E40, 0x0E5B,
	},
	spaces = false,
}

m["Tibt"] = process_ranges{
	"Tibetan",
	"abugida",
	ranges = {
		0x0F00, 0x0F47,
		0x0F49, 0x0F6C,
		0x0F71, 0x0F97,
		0x0F99, 0x0FBC,
		0x0FBE, 0x0FCC,
		0x0FCE, 0x0FD4,
		0x0FD9, 0x0FDA,
	},
	normalizationFixes = {
		combiningClasses = {["༹"] = 1},
		from = {"ཷ", "ཹ"},
		to = {"ྲཱྀ", "ླཱྀ"}
	},
}

	m["sit-tam-Tibt"] = {
		"Tamyig",
		m["Tibt"][2],
		ranges = m["Tibt"].ranges,
		characters = m["Tibt"].characters,
		parent = "Tibt",
		normalizationFixes = m["Tibt"].normalizationFixes,
	}

m["Tirh"] = process_ranges{
	"Tirhuta",
	"abugida",
	ranges = {
		0x0951, 0x0952,
		0x0964, 0x0965,
		0x1CF2, 0x1CF2,
		0xA830, 0xA839,
		0x11480, 0x114C7,
		0x114D0, 0x114D9,
	},
	normalizationFixes = {
		from = {"𑒁𑒰", "𑒋𑒺", "𑒍𑒺", "𑒪𑒵", "𑒪𑒶"},
		to = {"𑒂", "𑒌", "𑒎", "𑒉", "𑒊"}
	},
}

m["Tnsa"] = process_ranges{
	"Tangsa",
	"alphabet",
	ranges = {
		0x16A70, 0x16ABE,
		0x16AC0, 0x16AC9,
	},
}

m["Todr"] = {
	"Todhri",
	"alphabet",
	direction = "rtl",
	-- Not in Unicode
}

m["Tols"] = {
	"Tolong Siki",
	"alphabet",
	-- Not in Unicode
}

m["Toto"] = process_ranges{
	"Toto",
	"abugida",
	ranges = {
		0x1E290, 0x1E2AE,
	},
}

m["Tutg"] = {
	"Tigalari",
	"abugida",
	aliases = {"Tulu"},
	-- Not in Unicode
}

m["Ugar"] = process_ranges{
	"Ugaritic",
	"abjad",
	ranges = {
		0x10380, 0x1039D,
		0x1039F, 0x1039F,
	},
}

m["Vaii"] = process_ranges{
	"Vai",
	"syllabary",
	ranges = {
		0xA500, 0xA62B,
	},
}

m["Visp"] = {
	"Visible Speech",
	"alphabet",
	-- Not in Unicode
}

m["Vith"] = process_ranges{
	"Vithkuqi",
	"alphabet",
	ranges = {
		0x10570, 0x1057A,
		0x1057C, 0x1058A,
		0x1058C, 0x10592,
		0x10594, 0x10595,
		0x10597, 0x105A1,
		0x105A3, 0x105B1,
		0x105B3, 0x105B9,
		0x105BB, 0x105BC,
	},
	capitalized = true,
}

m["Wara"] = process_ranges{
	"Varang Kshiti",
	aliases = {"Warang Citi"},
	ranges = {
		0x118A0, 0x118F2,
		0x118FF, 0x118FF,
	},
	capitalized = true,
}

m["Wcho"] = process_ranges{
	"Wancho",
	"alphabet",
	ranges = {
		0x1E2C0, 0x1E2F9,
		0x1E2FF, 0x1E2FF,
	},
}

m["Wole"] = {
	"Woleai",
	"syllabary",
	-- Not in Unicode
}

m["Xpeo"] = process_ranges{
	"Old Persian",
	ranges = {
		0x103A0, 0x103C3,
		0x103C8, 0x103D5,
	},
}

m["Xsux"] = process_ranges{
	"Cuneiform",
	aliases = {"Sumero-Akkadian Cuneiform"},
	ranges = {
		0x12000, 0x12399,
		0x12400, 0x1246E,
		0x12470, 0x12474,
		0x12480, 0x12543,
	},
}

m["Yezi"] = process_ranges{
	"Yezidi",
	"alphabet",
	ranges = {
		0x060C, 0x060C,
		0x061B, 0x061B,
		0x061F, 0x061F,
		0x0660, 0x0669,
		0x10E80, 0x10EA9,
		0x10EAB, 0x10EAD,
		0x10EB0, 0x10EB1,
	},
	direction = "rtl",
}

m["Yiii"] = process_ranges{
	"Yi",
	"syllabary",
	ranges = {
		0x3001, 0x3002,
		0x3008, 0x3011,
		0x3014, 0x301B,
		0x30FB, 0x30FB,
		0xA000, 0xA48C,
		0xA490, 0xA4C6,
		0xFF61, 0xFF65,
	},
}

m["Zanb"] = process_ranges{
	"Zanabazar Square",
	ranges = {
		0x11A00, 0x11A47,
	},
}

m["Zmth"] = process_ranges{
	"mathematical notation",
	ranges = {
		0x00AC, 0x00AC,
		0x00B1, 0x00B1,
		0x00D7, 0x00D7,
		0x00F7, 0x00F7,
		0x03D0, 0x03D2,
		0x03D5, 0x03D5,
		0x03F0, 0x03F1,
		0x03F4, 0x03F6,
		0x0606, 0x0608,
		0x2016, 0x2016,
		0x2032, 0x2034,
		0x2040, 0x2040,
		0x2044, 0x2044,
		0x2052, 0x2052,
		0x205F, 0x205F,
		0x2061, 0x2064,
		0x207A, 0x207E,
		0x208A, 0x208E,
		0x20D0, 0x20DC,
		0x20E1, 0x20E1,
		0x20E5, 0x20E6,
		0x20EB, 0x20EF,
		0x2102, 0x2102,
		0x2107, 0x2107,
		0x210A, 0x2113,
		0x2115, 0x2115,
		0x2118, 0x211D,
		0x2124, 0x2124,
		0x2128, 0x2129,
		0x212C, 0x212D,
		0x212F, 0x2131,
		0x2133, 0x2138,
		0x213C, 0x2149,
		0x214B, 0x214B,
		0x2190, 0x21A7,
		0x21A9, 0x21AE,
		0x21B0, 0x21B1,
		0x21B6, 0x21B7,
		0x21BC, 0x21DB,
		0x21DD, 0x21DD,
		0x21E4, 0x21E5,
		0x21F4, 0x22FF,
		0x2308, 0x230B,
		0x2320, 0x2321,
		0x237C, 0x237C,
		0x239B, 0x23B5,
		0x23B7, 0x23B7,
		0x23D0, 0x23D0,
		0x23DC, 0x23E2,
		0x25A0, 0x25A1,
		0x25AE, 0x25B7,
		0x25BC, 0x25C1,
		0x25C6, 0x25C7,
		0x25CA, 0x25CB,
		0x25CF, 0x25D3,
		0x25E2, 0x25E2,
		0x25E4, 0x25E4,
		0x25E7, 0x25EC,
		0x25F8, 0x25FF,
		0x2605, 0x2606,
		0x2640, 0x2640,
		0x2642, 0x2642,
		0x2660, 0x2663,
		0x266D, 0x266F,
		0x27C0, 0x27FF,
		0x2900, 0x2AFF,
		0x2B30, 0x2B44,
		0x2B47, 0x2B4C,
		0xFB29, 0xFB29,
		0xFE61, 0xFE66,
		0xFE68, 0xFE68,
		0xFF0B, 0xFF0B,
		0xFF1C, 0xFF1E,
		0xFF3C, 0xFF3C,
		0xFF3E, 0xFF3E,
		0xFF5C, 0xFF5C,
		0xFF5E, 0xFF5E,
		0xFFE2, 0xFFE2,
		0xFFE9, 0xFFEC,
		0x1D400, 0x1D454,
		0x1D456, 0x1D49C,
		0x1D49E, 0x1D49F,
		0x1D4A2, 0x1D4A2,
		0x1D4A5, 0x1D4A6,
		0x1D4A9, 0x1D4AC,
		0x1D4AE, 0x1D4B9,
		0x1D4BB, 0x1D4BB,
		0x1D4BD, 0x1D4C3,
		0x1D4C5, 0x1D505,
		0x1D507, 0x1D50A,
		0x1D50D, 0x1D514,
		0x1D516, 0x1D51C,
		0x1D51E, 0x1D539,
		0x1D53B, 0x1D53E,
		0x1D540, 0x1D544,
		0x1D546, 0x1D546,
		0x1D54A, 0x1D550,
		0x1D552, 0x1D6A5,
		0x1D6A8, 0x1D7CB,
		0x1D7CE, 0x1D7FF,
		0x1EE00, 0x1EE03,
		0x1EE05, 0x1EE1F,
		0x1EE21, 0x1EE22,
		0x1EE24, 0x1EE24,
		0x1EE27, 0x1EE27,
		0x1EE29, 0x1EE32,
		0x1EE34, 0x1EE37,
		0x1EE39, 0x1EE39,
		0x1EE3B, 0x1EE3B,
		0x1EE42, 0x1EE42,
		0x1EE47, 0x1EE47,
		0x1EE49, 0x1EE49,
		0x1EE4B, 0x1EE4B,
		0x1EE4D, 0x1EE4F,
		0x1EE51, 0x1EE52,
		0x1EE54, 0x1EE54,
		0x1EE57, 0x1EE57,
		0x1EE59, 0x1EE59,
		0x1EE5B, 0x1EE5B,
		0x1EE5D, 0x1EE5D,
		0x1EE5F, 0x1EE5F,
		0x1EE61, 0x1EE62,
		0x1EE64, 0x1EE64,
		0x1EE67, 0x1EE6A,
		0x1EE6C, 0x1EE72,
		0x1EE74, 0x1EE77,
		0x1EE79, 0x1EE7C,
		0x1EE7E, 0x1EE7E,
		0x1EE80, 0x1EE89,
		0x1EE8B, 0x1EE9B,
		0x1EEA1, 0x1EEA3,
		0x1EEA5, 0x1EEA9,
		0x1EEAB, 0x1EEBB,
		0x1EEF0, 0x1EEF1,
	},
	translit = false,
	character_category = "Mathematical notation symbols", -- ?
}

m["Zsym"] = process_ranges{
	"symbol",
	"pictography",
	ranges = {
		0x20DD, 0x20E0,
		0x20E2, 0x20E4,
		0x20E7, 0x20EA,
		0x20F0, 0x20F0,
		0x2100, 0x2101,
		0x2103, 0x2106,
		0x2108, 0x2109,
		0x2114, 0x2114,
		0x2116, 0x2117,
		0x211E, 0x2123,
		0x2125, 0x2127,
		0x212A, 0x212B,
		0x212E, 0x212E,
		0x2132, 0x2132,
		0x2139, 0x213B,
		0x214A, 0x214A,
		0x214C, 0x214F,
		0x21A8, 0x21A8,
		0x21AF, 0x21AF,
		0x21B2, 0x21B5,
		0x21B8, 0x21BB,
		0x21DC, 0x21DC,
		0x21DE, 0x21E3,
		0x21E6, 0x21F3,
		0x2300, 0x2307,
		0x230C, 0x231F,
		0x2322, 0x237B,
		0x237D, 0x239A,
		0x23B6, 0x23B6,
		0x23B8, 0x23CF,
		0x23D1, 0x23DB,
		0x23E3, 0x23FF,
		0x2500, 0x259F,
		0x25A2, 0x25AD,
		0x25B8, 0x25BB,
		0x25C2, 0x25C5,
		0x25C8, 0x25C9,
		0x25CC, 0x25CE,
		0x25D4, 0x25E1,
		0x25E3, 0x25E3,
		0x25E5, 0x25E6,
		0x25ED, 0x25F7,
		0x2600, 0x2604,
		0x2607, 0x263F,
		0x2641, 0x2641,
		0x2643, 0x265F,
		0x2664, 0x266C,
		0x2670, 0x27BF,
		0x2B00, 0x2B2F,
		0x2B45, 0x2B46,
		0x2B4D, 0x2B73,
		0x2B76, 0x2B95,
		0x2B97, 0x2BFF,
		0x4DC0, 0x4DFF,
		0x1F000, 0x1F02B,
		0x1F030, 0x1F093,
		0x1F0A0, 0x1F0AE,
		0x1F0B1, 0x1F0BF,
		0x1F0C1, 0x1F0CF,
		0x1F0D1, 0x1F0F5,
		0x1F300, 0x1F6D7,
		0x1F6DC, 0x1F6EC,
		0x1F6F0, 0x1F6FC,
		0x1F700, 0x1F776,
		0x1F77B, 0x1F7D9,
		0x1F7E0, 0x1F7EB,
		0x1F7F0, 0x1F7F0,
		0x1F800, 0x1F80B,
		0x1F810, 0x1F847,
		0x1F850, 0x1F859,
		0x1F860, 0x1F887,
		0x1F890, 0x1F8AD,
		0x1F8B0, 0x1F8B1,
		0x1F900, 0x1FA53,
		0x1FA60, 0x1FA6D,
		0x1FA70, 0x1FA7C,
		0x1FA80, 0x1FA88,
		0x1FA90, 0x1FABD,
		0x1FABF, 0x1FAC5,
		0x1FACE, 0x1FADB,
		0x1FAE0, 0x1FAE8,
		0x1FAF0, 0x1FAF8,
		0x1FB00, 0x1FB92,
		0x1FB94, 0x1FBCA,
		0x1FBF0, 0x1FBF9,
	},
	translit = false,
	character_category = false, -- none
}

m["Zyyy"] = {
	"undetermined",
	-- This should not have any characters listed, probably
	translit = false,
	character_category = false, -- none
}

m["Zzzz"] = {
	"uncoded",
	-- This should not have any characters listed
	translit = false,
	character_category = false, -- none
}

-- These should be defined after the scripts they are composed of.

m["Hrkt"] = process_ranges{
	"Kana",
	"syllabary",
	aliases = {"Japanese syllabaries"},
	ranges = union(
		m["Hira"].ranges,
		m["Kana"].ranges
	),
	spaces = false,
}

m["Jpan"] = process_ranges{
	"Japanese",
	"logography, syllabary",
	ranges = union(
		m["Hrkt"].ranges,
		m["Hani"].ranges,
		m["Latn"].ranges
	),
	spaces = false,
	sort_by_scraping = true,
}

m["Kore"] = process_ranges{
	"Korean",
	"logography, syllabary",
	ranges = union(
		m["Hang"].ranges,
		m["Hani"].ranges
	),
}

return m