local concat = table.concat
local get_etym_lang = require("etymology languages").getByCanonicalName
local gsub = mw.ustring.gsub
local insert = table.insert
local split = mw.text.split
local trim = mw.text.trim
local u = mw.ustring.char

local function track(track_id)
	local tracking_page = "headword/" .. track_id
	local m_debug_track = require("debug/track")
	m_debug_track(tracking_page)
	return true
end

local frame = mw.getCurrentFrame()
local title = mw.title.getCurrentTitle()
local content = title:getContent()
	:gsub("<!%-%-.-%-%->", "")
	:gsub("<!%-%-.*", "")
local content_lang = mw.getContentLanguage()

local data = {}

------ 1. Lists that will be converted into sets. ------

data.invariable = {
	"cmavo",
	"cmene",
	"fu'ivla",
	"gismu",
	"Han tu",
	"hanja",
	"hanzi",
	"jyutping",
	"kanji",
	"lujvo",
	"phrasebook",
	"pinyin",
	"rafsi",
	"romaji",
}

data.lemmas = {
	"abbreviations",
	"acronyms",
	"adjectives",
	"adnominals",
	"adpositions",
	"adverbs",
	"affixes",
	"ambipositions",
	"articles",
	"circumfixes",
	"circumpositions",
	"classifiers",
	"cmavo",
	"cmavo clusters",
	"cmene",
	"combining forms",
	"conjunctions",
	"counters",
	"determiners",
	"diacritical marks",
	"equative adjectives",
	"fu'ivla",
	"gismu",
	"Han characters",
	"Han tu",
	"hanja",
	"hanzi",
	"ideophones",
	"idioms",
	"infixes",
	"initialisms",
	"interfixes",
	"interjections",
	"kanji",
	"letters",
	"ligatures",
	"logograms",
	"lujvo",
	"morphemes",
	"non-constituents",
	"nouns",
	"numbers",
	"numeral symbols",
	"numerals",
	"particles",
	"phrases",
	"postpositions",
	"postpositional phrases",
	"predicatives",
	"prefixes",
	"prepositional phrases",
	"prepositions",
	"preverbs",
	"pronominal adverbs",
	"pronouns",
	"proper nouns",
	"proverbs",
	"punctuation marks",
	"relatives",
	"roots",
	"stems",
	"suffixes",
	"syllables",
	"symbols",
	"verbs",
}

data.nonlemmas = {
	"active participle forms",
	"active participles",
	"adjectival participles",
    "adjective case forms",
	"adjective forms",
	"adjective feminine forms",
	"adjective plural forms",
	"adverb forms",
	"adverbial participles",
	"agent participles",
	"article forms",
	"circumfix forms",
	"combined forms",
	"comparative adjective forms",
	"comparative adjectives",
	"comparative adverb forms",
	"comparative adverbs",
	"conjunction forms",
	"contractions",
	"converbs",
	"determiner comparative forms",
	"determiner forms",
	"determiner superlative forms",
	"diminutive nouns",
	"elative adjectives",
	"equative adjective forms",
	"equative adjectives",
	"future participles",
	"gerunds",
	"infinitive forms",
	"infinitives",
	"interjection forms",
	"jyutping",
	"kanji readings",
	"misspellings",
	"negative participles",
	"nominal participles",
	"noun case forms",
	"noun dual forms",
	"noun forms",
	"noun paucal forms",
	"noun plural forms",
	"noun possessive forms",
	"noun singulative forms",
	"numeral forms",
	"participles",
	"participle forms",
	"particle forms",
	"passive participles",
	"past active participles",
	"past participles",
	"past participle forms",
	"past passive participles",
	"perfect active participles",
	"perfect participles",
	"perfect passive participles",
	"pinyin",
	"plurals",
	"postposition forms",
	"prefix forms",
	"preposition contractions",
	"preposition forms",
	"prepositional pronouns",
	"present active participles",
	"present participles",
	"present passive participles",
	"pronoun forms",
	"pronoun possessive forms",
	"proper noun forms",
	"proper noun plural forms",
	"rafsi",
	"romanizations",
	"root forms",
	"singulatives",
	"suffix forms",
	"superlative adjective forms",
	"superlative adjectives",
	"superlative adverb forms",
	"superlative adverbs",
	"verb forms",
	"verbal nouns",
}

-- These langauges will not have links to separate parts of the headword.
data.no_multiword_links = {
	"zh",
}

-- These languages will not have "LANG multiword terms" categories added.
data.no_multiword_cat = {
	-------- Languages without spaces between words (sometimes spaces between phrases) --------
	"blt", -- Tai Dam
	"ja", -- Japanese
	"khb", -- Lü
	"km", -- Khmer
	"lo", -- Lao
	"mnw", -- Mon
	"my", -- Burmese
	"nan", -- Min Nan (some words in Latin script; hyphens between syllables)
	"nod", -- Northern Thai
	"ojp", -- Old Japanese
	"shn", -- Shan
	"sou", -- Southern Thai
	"tdd", -- Tai Nüa
	"th", -- Thai
	"tts", -- Isan
	"twh", -- Tai Dón
	"txg", -- Tangut
	"zh", -- Chinese (all varieties with Chinese characters)
	"zkt", -- Khitan

	-------- Languages with spaces between syllables --------
	"ahk", -- Akha
	"aou", -- A'ou
	"atb", -- Zaiwa
	"byk", -- Biao
	"cdy", -- Chadong
	--"duu", -- Drung; not sure
	--"hmx-pro", -- Proto-Hmong-Mien
	--"hnj", -- Green Hmong; not sure
	"huq", -- Tsat
	"ium", -- Iu Mien
	--"lis", -- Lisu; not sure
	"mtq", -- Muong
	--"mww", -- White Hmong; not sure
	"onb", -- Lingao
	--"sit-gkh", -- Gokhy; not sure
	--"swi", -- Sui; not sure
	"tbq-lol-pro", -- Proto-Loloish
	"tdh", -- Thulung
	"ukk", -- Muak Sa-aak
	"vi", -- Vietnamese
	"yig", -- Wusa Nasu
	"zng", -- Mang

	-------- Languages with ~ with surrounding spaces used to separate variants --------
	"mkh-ban-pro", -- Proto-Bahnaric
	"sit-pro", -- Proto-Sino-Tibetan; listed above

	-------- Other weirdnesses --------
	"mul", -- Translingual; gestures, Morse code, etc.
	"aot", -- Atong (India); bullet is a letter

	-------- All sign languages	--------
	"ads",
	"aed",
	"aen",
	"afg",
	"ase",
	"asf",
	"asp",
	"asq",
	"asw",
	"bfi",
	"bfk",
	"bog",
	"bqn",
	"bqy",
	"bvl",
	"bzs",
	"cds",
	"csc",
	"csd",
	"cse",
	"csf",
	"csg",
	"csl",
	"csn",
	"csq",
	"csr",
	"doq",
	"dse",
	"dsl",
	"ecs",
	"esl",
	"esn",
	"eso",
	"eth",
	"fcs",
	"fse",
	"fsl",
	"fss",
	"gds",
	"gse",
	"gsg",
	"gsm",
	"gss",
	"gus",
	"hab",
	"haf",
	"hds",
	"hks",
	"hos",
	"hps",
	"hsh",
	"hsl",
	"icl",
	"iks",
	"ils",
	"inl",
	"ins",
	"ise",
	"isg",
	"isr",
	"jcs",
	"jhs",
	"jls",
	"jos",
	"jsl",
	"jus",
	"kgi",
	"kvk",
	"lbs",
	"lls",
	"lsl",
	"lso",
	"lsp",
	"lst",
	"lsy",
	"lws",
	"mdl",
	"mfs",
	"mre",
	"msd",
	"msr",
	"mzc",
	"mzg",
	"mzy",
	"nbs",
	"ncs",
	"nsi",
	"nsl",
	"nsp",
	"nsr",
	"nzs",
	"okl",
	"pgz",
	"pks",
	"prl",
	"prz",
	"psc",
	"psd",
	"psg",
	"psl",
	"pso",
	"psp",
	"psr",
	"pys",
	"rms",
	"rsl",
	"rsm",
	"sdl",
	"sfb",
	"sfs",
	"sgg",
	"sgx",
	"slf",
	"sls",
	"sqk",
	"sqs",
	"ssp",
	"ssr",
	"svk",
	"swl",
	"syy",
	"tse",
	"tsm",
	"tsq",
	"tss",
	"tsy",
	"tza",
	"ugn",
	"ugy",
	"ukl",
	"uks",
	"vgt",
	"vsi",
	"vsl",
	"vsv",
	"xki",
	"xml",
	"xms",
	"ygs",
	"ysl",
	"zib",
	"zsl",
}

-- In these languages, the hyphen is not considered a word separator for the "multiword terms" category.
data.hyphen_not_multiword_sep = {
	"akk", -- Akkadian; hyphens between syllables
	"akl", -- Aklanon; hyphens for mid-word glottal stops
	"ber-pro", -- Proto-Berber; morphemes separated by hyphens
	"ceb", -- Cebuano; hyphens for mid-word glottal stops
	"cnk", -- Khumi Chin; hyphens used in single words
	"cpi", -- Chinese Pidgin English; Chinese-derived words with hyphens between syllables
	"de", -- too many false positives
	"esx-esk-pro", -- hyphen used to separate morphemes
	"fi", -- Finnish; hyphen used to separate components in compound words if the final and initial vowels match, respectively
	"hil", -- Hiligaynon; hyphens for mid-word glottal stops
	"ilo", -- Ilocano; hyphens for mid-word glottal stops
	"lcp", -- Western Lawa; dash as syllable joiner
	"lwl", -- Eastern Lawa; dash as syllable joiner
	"mfa", -- Pattani Malay in Thai script; dash as syllable joiner
	"mkh-vie-pro", -- Proto-Vietic; morphemes separated by hyphens
	"msb", -- Masbatenyo; too many false positives
	"tl", -- Tagalog; too many false positives
	"war", -- Waray-Waray; too many false positives
	"yo", -- Yoruba; hyphens used to show lengthened nasal vowels
}

-- These languages will not have "LANG masculine nouns" and similar categories added.
data.no_gender_cat = {
	-- Languages without gender but which use the gender field for other purposes
	"ja",
	"th",
}

data.notranslit = {
	"ams",
	"az",
	"bbc",
	"bug",
	"cia",
	"cjm",
	"cmn",
	"cpi",
	"hak",
	"ja",
	"kzg",
	"lad",
	"lzh",
	"ms",
	"mul",
	"mvi",
	"nan",
	"oj",
	"okn",
	"ryn",
	"rys",
	"ryu",
	"sh",
	"tgt",
	"th",
	"tkn",
	"tly",
	"txg",
	"und",
	"vi",
	"xug",
	"yoi",
	"yox",
	"yue",
	"za",
	"zh",
}

-- Script codes for which a script-tagged display title will be added.
data.toBeTagged = {
	"Ahom",
	"Arab",
		"fa-Arab",
		"glk-Arab",
		"kk-Arab",
		"ks-Arab",
		"ku-Arab",
		"mzn-Arab",
		"ms-Arab",
		"ota-Arab",
		"pa-Arab",
		"ps-Arab",
		"sd-Arab",
		"tt-Arab",
		"ug-Arab",
		"ur-Arab",
	"Armi",
	"Armn",
	"Avst",
	"Bali",
	"Bamu",
	"Batk",
	"Beng",
		"as-Beng",
	"Bopo",
	"Brah",
	"Brai",
	"Bugi",
	"Buhd",
	"Cakm",
	"Cans",
	"Cari",
	"Cham",
	"Cher",
	"Copt",
	"Cprt",
	"Cyrl",
	"Cyrs",
	"Deva",
	"Dsrt",
	"Egyd",
	"Egyp",
	"Ethi",
	"Geok",
	"Geor",
	"Glag",
	"Goth",
	"Grek",
		"Polyt",
		"polytonic",
	"Gujr",
	"Guru",
	"Hang",
	"Hani",
	"Hano",
	"Hebr",
	"Hira",
	"Hluw",
	"Ital",
	"Java",
	"Kali",
	"Kana",
	"Khar",
	"Khmr",
	"Knda",
	"Kthi",
	"Lana",
	"Laoo",
	"Latn",
		"Latf",
		"Latg",
		"Latnx",
		"Latinx",
		"pjt-Latn",
	"Lepc",
	"Limb",
	"Linb",
	"Lisu",
	"Lyci",
	"Lydi",
	"Mand",
	"Mani",
	"Marc",
	"Merc",
	"Mero",
	"Mlym",
	"Mong",
		"mnc-Mong",
		"sjo-Mong",
		"xwo-Mong",
	"Mtei",
	"Mymr",
	"Narb",
	"Nkoo",
	"Ogam",
	"Olck",
	"Orkh",
	"Orya",
	"Osma",
	"Ougr",
	"Palm",
	"Phag",
	"Phli",
	"Phlv",
	"Phnx",
	"Plrd",
	"Prti",
	"Rjng",
	"Runr",
	"Samr",
	"Sarb",
	"Saur",
	"Sgnw",
	"Shaw",
	"Shrd",
	"Sinh",
	"Sora",
	"Sund",
	"Sylo",
	"Syrc",
	"Tagb",
	"Tale",
	"Talu",
	"Taml",
	"Tang",
	"Tavt",
	"Telu",
	"Tfng",
	"Tglg",
	"Thaa",
	"Thai",
	"Tibt",
	"Ugar",
	"Vaii",
	"Xpeo",
	"Xsux",
	"Yiii",
	"Zmth",
	"Zsym",

	"Ipach",
	"IPAchar",
	"Music",
	"musical",
	"Rumin",
	"Ruminumerals",
}

-- Parts of speech which will not be categorised in categories like "English terms spelled with É" if
-- the term is the character in question (e.g. the letter entry for English [[é]]). This contrasts with
-- entries like the French adjective [[m̂]], which is a one-letter word spelled with the letter.
data.pos_not_spelled_with_self = {
	"diacritical marks",
	"Han characters",
	"Han tu",
	"hanja",
	"hanzi",
	"kanji",
	"letters",
	"ligatures",
	"logograms",
	"numeral symbols",
	"numerals",
	"symbols",
}

-- Convert lists into sets.
for key, list in pairs(data) do
	data[key] = {}
	for _, item in ipairs(list) do
		data[key][item] = true
	end
end

------ 2. Lists that will not be converted into sets. ------

-- Recognized aliases for parts of speech (param 2=). Key is the short form and value is the canonical singular (not
-- pluralized) form. It is singular so that the same table can be used in [[Module:form of]] for the p=/POS= param
-- and [[Module:links]] for the pos= param.
data.pos_aliases = {
	a = "adjective",
	adj = "adjective",
	adv = "adverb",
	art = "article",
	det = "determiner",
	cnum = "cardinal number",
	conj = "conjunction",
	conv = "converb",
	int = "interjection",
	interj = "interjection",
	intj = "interjection",
	n = "noun",
	num = "numeral",
	part = "participle",
	pcl = "particle",
	phr = "phrase",
	pn = "proper noun",
	postp = "postposition",
	pre = "preposition",
	prep = "preposition",
	pro = "pronoun",
	pron = "pronoun",
	prop = "proper noun",
	proper = "proper noun",
	onum = "ordinal number",
	v = "verb",
	vb = "verb",
	vi = "intransitive verb",
	vt = "transitive verb",
	vti = "transitive and intransitive verb",
}

-- Parts of speech for which categories like "German masculine nouns" or "Russian imperfective verbs"
-- will be generated if the headword is of the appropriate gender/number.
data.pos_for_gender_number_cat = {
	["nouns"] = "nouns",
	["proper nouns"] = "nouns",
	["suffixes"] = "suffixes",
	-- We include verbs because impf and pf are valid "genders".
	["verbs"] = "verbs",
}

-- Convert a numeric list of characters and ranges to the equivalent Lua pattern. WARNING: This destructively modifies
-- the contents of `ranges`.
local function char_ranges_to_pattern(ranges)
	for j, range in ipairs(ranges) do
		if type(range) == "table" then
			for k, char in ipairs(range) do
				range[k] = u(char)
			end
			ranges[j] = table.concat(range, "-")
		else
			ranges[j] = u(range)
		end
	end
	return table.concat(ranges)
end


-- Combining character data used when categorising unusual characters. These resolve into two patterns, used to find single combining characters (i.e. character + diacritic(s)) or double combining characters (i.e. character + diacritic(s) + character).
local comb_chars = {
	single = {
		{0x0300, 0x034E},
		-- Exclude combining grapheme joiner.
		{0x0350, 0x035B},
		{0x0363, 0x036F},
		{0x0483, 0x0489},
		{0x0591, 0x05BD},
		0x05BF,
		{0x05C1, 0x05C2},
		{0x05C4, 0x05C5},
		0x05C7,
		{0x0610, 0x061A},
		{0x064B, 0x065F},
		0x0670,
		{0x06D6, 0x06DC},
		{0x06DF, 0x06E4},
		{0x06E7, 0x06E8},
		{0x06EA, 0x06ED},
		0x0711,
		{0x0730, 0x074A},
		{0x07A6, 0x07B0},
		{0x07EB, 0x07F3},
		0x07FD,
		{0x0816, 0x0819},
		{0x081B, 0x0823},
		{0x0825, 0x0827},
		{0x0829, 0x082D},
		{0x0859, 0x085B},
		{0x0898, 0x089F},
		{0x08CA, 0x08E1},
		{0x08E3, 0x0903},
		{0x093A, 0x093C},
		{0x093E, 0x094F},
		{0x0951, 0x0957},
		{0x0962, 0x0963},
		{0x0981, 0x0983},
		0x09BC,
		{0x09BE, 0x09C4},
		{0x09C7, 0x09C8},
		{0x09CB, 0x09CD},
		0x09D7,
		{0x09E2, 0x09E3},
		0x09FE,
		{0x0A01, 0x0A03},
		0x0A3C,
		{0x0A3E, 0x0A42},
		{0x0A47, 0x0A48},
		{0x0A4B, 0x0A4D},
		0x0A51,
		{0x0A70, 0x0A71},
		0x0A75,
		{0x0A81, 0x0A83},
		0x0ABC,
		{0x0ABE, 0x0AC5},
		{0x0AC7, 0x0AC9},
		{0x0ACB, 0x0ACD},
		{0x0AE2, 0x0AE3},
		{0x0AFA, 0x0AFF},
		{0x0B01, 0x0B03},
		0x0B3C,
		{0x0B3E, 0x0B44},
		{0x0B47, 0x0B48},
		{0x0B4B, 0x0B4D},
		{0x0B55, 0x0B57},
		{0x0B62, 0x0B63},
		0x0B82,
		{0x0BBE, 0x0BC2},
		{0x0BC6, 0x0BC8},
		{0x0BCA, 0x0BCD},
		0x0BD7,
		{0x0C00, 0x0C04},
		0x0C3C,
		{0x0C3E, 0x0C44},
		{0x0C46, 0x0C48},
		{0x0C4A, 0x0C4D},
		{0x0C55, 0x0C56},
		{0x0C62, 0x0C63},
		{0x0C81, 0x0C83},
		0x0CBC,
		{0x0CBE, 0x0CC4},
		{0x0CC6, 0x0CC8},
		{0x0CCA, 0x0CCD},
		{0x0CD5, 0x0CD6},
		{0x0CE2, 0x0CE3},
		0x0CF3,
		{0x0D00, 0x0D03},
		{0x0D3B, 0x0D3C},
		{0x0D3E, 0x0D44},
		{0x0D46, 0x0D48},
		{0x0D4A, 0x0D4D},
		0x0D57,
		{0x0D62, 0x0D63},
		{0x0D81, 0x0D83},
		0x0DCA,
		{0x0DCF, 0x0DD4},
		0x0DD6,
		{0x0DD8, 0x0DDF},
		{0x0DF2, 0x0DF3},
		0x0E31,
		{0x0E34, 0x0E3A},
		{0x0E47, 0x0E4E},
		0x0EB1,
		{0x0EB4, 0x0EBC},
		{0x0EC8, 0x0ECE},
		{0x0F18, 0x0F19},
		0x0F35,
		0x0F37,
		0x0F39,
		{0x0F3E, 0x0F3F},
		{0x0F71, 0x0F84},
		{0x0F86, 0x0F87},
		{0x0F8D, 0x0F97},
		{0x0F99, 0x0FBC},
		0x0FC6,
		{0x102B, 0x103E},
		{0x1056, 0x1059},
		{0x105E, 0x1060},
		{0x1062, 0x1064},
		{0x1067, 0x106D},
		{0x1071, 0x1074},
		{0x1082, 0x108D},
		0x108F,
		{0x109A, 0x109D},
		{0x135D, 0x135F},
		{0x1712, 0x1715},
		{0x1732, 0x1734},
		{0x1752, 0x1753},
		{0x1772, 0x1773},
		{0x17B4, 0x17D3},
		0x17DD,
		-- Exclude Mongolian variation selectors.
		{0x1885, 0x1886},
		0x18A9,
		{0x1920, 0x192B},
		{0x1930, 0x193B},
		{0x1A17, 0x1A1B},
		{0x1A55, 0x1A5E},
		{0x1A60, 0x1A7C},
		0x1A7F,
		{0x1AB0, 0x1ACE},
		{0x1B00, 0x1B04},
		{0x1B34, 0x1B44},
		{0x1B6B, 0x1B73},
		{0x1B80, 0x1B82},
		{0x1BA1, 0x1BAD},
		{0x1BE6, 0x1BF3},
		{0x1C24, 0x1C37},
		{0x1CD0, 0x1CD2},
		{0x1CD4, 0x1CE8},
		0x1CED,
		0x1CF4,
		{0x1CF7, 0x1CF9},
		{0x1DC0, 0x1DCC},
		{0x1DCE, 0x1DFB},
		{0x1DFD, 0x1DFF},
		{0x20D0, 0x20F0},
		{0x2CEF, 0x2CF1},
		0x2D7F,
		{0x2DE0, 0x2DFF},
		{0x302A, 0x302F},
		{0x3099, 0x309A},
		{0xA66F, 0xA672},
		{0xA674, 0xA67D},
		{0xA69E, 0xA69F},
		{0xA6F0, 0xA6F1},
		0xA802,
		0xA806,
		0xA80B,
		{0xA823, 0xA827},
		0xA82C,
		{0xA880, 0xA881},
		{0xA8B4, 0xA8C5},
		{0xA8E0, 0xA8F1},
		0xA8FF,
		{0xA926, 0xA92D},
		{0xA947, 0xA953},
		{0xA980, 0xA983},
		{0xA9B3, 0xA9C0},
		0xA9E5,
		{0xAA29, 0xAA36},
		0xAA43,
		{0xAA4C, 0xAA4D},
		{0xAA7B, 0xAA7D},
		0xAAB0,
		{0xAAB2, 0xAAB4},
		{0xAAB7, 0xAAB8},
		{0xAABE, 0xAABF},
		0xAAC1,
		{0xAAEB, 0xAAEF},
		{0xAAF5, 0xAAF6},
		{0xABE3, 0xABEA},
		{0xABEC, 0xABED},
		0xFB1E,
		{0xFE20, 0xFE2F},
		0x101FD,
		0x102E0,
		{0x10376, 0x1037A},
		{0x10A01, 0x10A03},
		{0x10A05, 0x10A06},
		{0x10A0C, 0x10A0F},
		{0x10A38, 0x10A3A},
		0x10A3F,
		{0x10AE5, 0x10AE6},
		{0x10D24, 0x10D27},
		{0x10EAB, 0x10EAC},
		{0x10EFD, 0x10EFF},
		{0x10F46, 0x10F50},
		{0x10F82, 0x10F85},
		{0x11000, 0x11002},
		{0x11038, 0x11046},
		0x11070,
		{0x11073, 0x11074},
		{0x1107F, 0x11082},
		{0x110B0, 0x110BA},
		0x110C2,
		{0x11100, 0x11102},
		{0x11127, 0x11134},
		{0x11145, 0x11146},
		0x11173,
		{0x11180, 0x11182},
		{0x111B3, 0x111C0},
		{0x111C9, 0x111CC},
		{0x111CE, 0x111CF},
		{0x1122C, 0x11237},
		0x1123E,
		0x11241,
		{0x112DF, 0x112EA},
		{0x11300, 0x11303},
		{0x1133B, 0x1133C},
		{0x1133E, 0x11344},
		{0x11347, 0x11348},
		{0x1134B, 0x1134D},
		0x11357,
		{0x11362, 0x11363},
		{0x11366, 0x1136C},
		{0x11370, 0x11374},
		{0x11435, 0x11446},
		0x1145E,
		{0x114B0, 0x114C3},
		{0x115AF, 0x115B5},
		{0x115B8, 0x115C0},
		{0x115DC, 0x115DD},
		{0x11630, 0x11640},
		{0x116AB, 0x116B7},
		{0x1171D, 0x1172B},
		{0x1182C, 0x1183A},
		{0x11930, 0x11935},
		{0x11937, 0x11938},
		{0x1193B, 0x1193E},
		0x11940,
		{0x11942, 0x11943},
		{0x119D1, 0x119D7},
		{0x119DA, 0x119E0},
		0x119E4,
		{0x11A01, 0x11A0A},
		{0x11A33, 0x11A39},
		{0x11A3B, 0x11A3E},
		0x11A47,
		{0x11A51, 0x11A5B},
		{0x11A8A, 0x11A99},
		{0x11C2F, 0x11C36},
		{0x11C38, 0x11C3F},
		{0x11C92, 0x11CA7},
		{0x11CA9, 0x11CB6},
		{0x11D31, 0x11D36},
		0x11D3A,
		{0x11D3C, 0x11D3D},
		{0x11D3F, 0x11D45},
		0x11D47,
		{0x11D8A, 0x11D8E},
		{0x11D90, 0x11D91},
		{0x11D93, 0x11D97},
		{0x11EF3, 0x11EF6},
		{0x11F00, 0x11F01},
		0x11F03,
		{0x11F34, 0x11F3A},
		{0x11F3E, 0x11F42},
		0x13440,
		{0x13447, 0x13455},
		{0x16AF0, 0x16AF4},
		{0x16B30, 0x16B36},
		0x16F4F,
		{0x16F51, 0x16F87},
		{0x16F8F, 0x16F92},
		-- Exclude Khitan Small Script filler.
		{0x16FF0, 0x16FF1},
		{0x1BC9D, 0x1BC9E},
		{0x1CF00, 0x1CF2D},
		{0x1CF30, 0x1CF46},
		{0x1D165, 0x1D169},
		{0x1D16D, 0x1D172},
		{0x1D17B, 0x1D182},
		{0x1D185, 0x1D18B},
		{0x1D1AA, 0x1D1AD},
		{0x1D242, 0x1D244},
		{0x1DA00, 0x1DA36},
		{0x1DA3B, 0x1DA6C},
		0x1DA75,
		0x1DA84,
		{0x1DA9B, 0x1DA9F},
		{0x1DAA1, 0x1DAAF},
		{0x1E000, 0x1E006},
		{0x1E008, 0x1E018},
		{0x1E01B, 0x1E021},
		{0x1E023, 0x1E024},
		{0x1E026, 0x1E02A},
		0x1E08F,
		{0x1E130, 0x1E136},
		0x1E2AE,
		{0x1E2EC, 0x1E2EF},
		{0x1E4EC, 0x1E4EF},
		{0x1E8D0, 0x1E8D6},
		{0x1E944, 0x1E94A},
	},
	double = {
		{0x035C, 0x0362},
		0x1DCD,
		0x1DFC,
	},
	vs = { -- variation selectors; separated out so that we don't get categories for them
		{0xFE00, 0xFE0F},
		{0xE0100, 0xE01EF},
	}
}
for key, set in pairs(comb_chars) do
	comb_chars[key] = char_ranges_to_pattern(set)
end
comb_chars.both = comb_chars.single .. comb_chars.double .. comb_chars.vs
comb_chars = {
	combined_single = "[^" .. comb_chars.both .. "][" .. comb_chars.single .. comb_chars.vs .. "]+%f[^" .. comb_chars.both .. "]",
	combined_double = "[^" .. comb_chars.both .. "][" .. comb_chars.single .. comb_chars.vs .. "]*[" .. comb_chars.double .. "]+[" .. comb_chars.both .. "]*.[" .. comb_chars.single .. comb_chars.vs .. "]*",
	diacritics_single = "[" .. comb_chars.single .. "]",
	diacritics_double = "[" .. comb_chars.double .. "]"
}
data.comb_chars = comb_chars

-- From https://unicode.org/Public/emoji/15.1/emoji-sequences.txt
local emoji_chars = {
	{0x231A, 0x231B}, --  watch..hourglass done                                          # E0.6   [2] (⌚..⌛)
	{0x23E9, 0x23EC}, --  fast-forward button..fast down button                          # E0.6   [4] (⏩..⏬)
	0x23F0,           --  alarm clock                                                    # E0.6   [1] (⏰)
	0x23F3,           --  hourglass not done                                             # E0.6   [1] (⏳)
	{0x25FD, 0x25FE}, --  white medium-small square..black medium-small square           # E0.6   [2] (◽..◾)
	{0x2614, 0x2615}, --  umbrella with rain drops..hot beverage                         # E0.6   [2] (☔..☕)
	{0x2648, 0x2653}, --  Aries..Pisces                                                  # E0.6  [12] (♈..♓)
	0x267F,           --  wheelchair symbol                                              # E0.6   [1] (♿)
	0x2693,           --  anchor                                                         # E0.6   [1] (⚓)
	0x26A1,           --  high voltage                                                   # E0.6   [1] (⚡)
	{0x26AA, 0x26AB}, --  white circle..black circle                                     # E0.6   [2] (⚪..⚫)
	{0x26BD, 0x26BE}, --  soccer ball..baseball                                          # E0.6   [2] (⚽..⚾)
	{0x26C4, 0x26C5}, --  snowman without snow..sun behind cloud                         # E0.6   [2] (⛄..⛅)
	0x26CE,           --  Ophiuchus                                                      # E0.6   [1] (⛎)
	0x26D4,           --  no entry                                                       # E0.6   [1] (⛔)
	0x26EA,           --  church                                                         # E0.6   [1] (⛪)
	{0x26F2, 0x26F3}, --  fountain..flag in hole                                         # E0.6   [2] (⛲..⛳)
	0x26F5,           --  sailboat                                                       # E0.6   [1] (⛵)
	0x26FA,           --  tent                                                           # E0.6   [1] (⛺)
	0x26FD,           --  fuel pump                                                      # E0.6   [1] (⛽)
	0x2705,           --  check mark button                                              # E0.6   [1] (✅)
	{0x270A, 0x270B}, --  raised fist..raised hand                                       # E0.6   [2] (✊..✋)
	0x2728,           --  sparkles                                                       # E0.6   [1] (✨)
	0x274C,           --  cross mark                                                     # E0.6   [1] (❌)
	0x274E,           --  cross mark button                                              # E0.6   [1] (❎)
	{0x2753, 0x2755}, --  red question mark..white exclamation mark                      # E0.6   [3] (❓..❕)
	0x2757,           --  red exclamation mark                                           # E0.6   [1] (❗)
	{0x2795, 0x2797}, --  plus..divide                                                   # E0.6   [3] (➕..➗)
	0x27B0,           --  curly loop                                                     # E0.6   [1] (➰)
	0x27BF,           --  double curly loop                                              # E1.0   [1] (➿)
	{0x2B1B, 0x2B1C}, --  black large square..white large square                         # E0.6   [2] (⬛..⬜)
	0x2B50,           --  star                                                           # E0.6   [1] (⭐)
	0x2B55,           --  hollow red circle                                              # E0.6   [1] (⭕)
	{0x1F300, 0x1FAFF}, --  emoji in Plane 1
	-- NOTE: There are lots more emoji sequences involving non-emoji Plane 0 symbols followed by 0xFE0F, which we don't
	-- (yet?) handle.
}
emoji_chars = char_ranges_to_pattern(emoji_chars)
data.emoji_pattern = "[" .. emoji_chars .. "]"

local unsupported_characters = {}
for k, v in pairs(require("links/data").unsupported_characters) do
	unsupported_characters[v] = k
end

-- Get the list of unsupported titles and invert it (so the keys are pagenames and values are canonical titles).
local unsupported_titles = {}
for k, v in pairs(require("links/data").unsupported_titles) do
	unsupported_titles[v] = k
end
data.unsupported_titles = unsupported_titles

------ 3. Page-wide processing (so that it only needs to be done once per page). ------

--Get the pagename.
local pagename = title.subpageText
	:gsub("^Unsupported titles/(.*)", function(m)
		data.unsupported_title = true
		return unsupported_titles[m] or (m:gsub("`.-`", unsupported_characters))
	end)
-- Save pagename, as local variable will be destructively modified.
data.pagename = pagename
-- Decompose the pagename in Unicode normalization form D.
data.decompose_pagename = mw.ustring.toNFD(pagename)
-- Explode the current page name into a character table, taking decomposed combining characters into account.
local explode_pagename = {}
local pagename_len = 0
local function explode(char)
	explode_pagename[char] = true
	pagename_len = pagename_len + 1
	return ""
end
pagename = gsub(pagename, comb_chars.combined_double, explode)
pagename = gsub(pagename, comb_chars.combined_single, explode)
	:gsub("[%z\1-\127\194-\244][\128-\191]*", explode)

data.explode_pagename = explode_pagename
data.pagename_len = pagename_len

-- Generate DEFAULTSORT.
data.encoded_pagename = mw.text.encode(data.pagename)
data.pagename_defaultsort = require("languages").getByCode("mul"):makeSortKey(data.encoded_pagename)
frame:callParserFunction(
	"DEFAULTSORT",
	data.pagename_defaultsort
)
data.raw_defaultsort = title.text:uupper()

-- Get section numbers for the page.
do
	local page_L2s = {}
	local i = 0
	for lvl, heading in content:gmatch("%f[^%z\n](=+)([^\n\r]+)%1[\t ]*%f[%z\n]") do
		i = i + 1
		if #lvl == 2 then
			page_L2s[i] = trim(heading)
		end
	end
	data.page_L2s = page_L2s
end

------ 4. Parse page for maintenance categories. ------
content = content:gsub("%[%[", "\1"):gsub("]]", "\2")
-- Use of tab characters.
if content:find("\t") then
	data.tab_characters = frame:expandTemplate{
		title = "tracking category",
		args = {"Pages with tab characters"}
	}
end
-- Unencoded character(s) in title.
local IDS = {
	["⿰"] = true, ["⿱"] = true, ["⿲"] = true, ["⿳"] = true,
	["⿴"] = true, ["⿵"] = true, ["⿶"] = true, ["⿷"] = true,
	["⿸"] = true, ["⿹"] = true, ["⿺"] = true, ["⿻"] = true,
	["⿼"] = true, ["⿽"] = true, ["⿾"] = true, ["⿿"] = true,
	["㇯"] = true
}
for char in pairs(explode_pagename) do
	if IDS[char] and char ~= data.pagename then
		data.unencoded_char = true
		break
	end
end
-- Raw wikitext use of {{DISPLAYTITLE:}}.
if content:find("{{%s*DISPLAYTITLE:.-}}") then
	data.pagename_displaytitle_conflict = frame:expandTemplate{
		title = "tracking category",
		args = {"Pages with DISPLAYTITLE conflicts"}
	}
end
-- Raw wikitext use of a topic or langname category. Also check if any raw sortkeys have been used.
do
	-- All chars treated as spaces in links (including categories).
	local spaces = " _" ..
		"\194\160" ..
		"\225\154\128" ..
		"\225\160\142" ..
		"\226\128\128-\226\128\138" ..
		"\226\128\168" ..
		"\226\128\169" ..
		"\226\128\175" ..
		"\226\129\159" ..
		"\227\128\128"
	local wikitext_topic_cat = {}
	local wikitext_langname_cat = {}
	local raw_sortkey
	
	local langnames = mw.loadData("languages/canonical names")
	local etym_langnames = mw.loadData("etymology languages/canonical names")
	
	-- If a raw sortkey has been found, add it to the relevant table.
	-- If there's no table (or the index is just `true`), create one first.
	local function add_cat_table(marker, sortkey, tbl)
		if not sortkey then
			tbl[marker] = tbl[marker] or true
			return true
		elseif type(tbl[marker]) ~= "table" then
			tbl[marker] = {}
		end
		insert(tbl[marker], sortkey)
		return true
	end
	
	local function do_iteration(name, sortkey, wikitext_langname_cat)
		if langnames[name] then
			return add_cat_table(name, sortkey, wikitext_langname_cat)
		end
		name = etym_langnames[name] and name or content_lang:lcfirst(name)
		if etym_langnames[name] then
			name = get_etym_lang(name):getNonEtymologicalName()
			return add_cat_table(name, sortkey, wikitext_langname_cat)
		end
	end
	
	local function process_category(cat)
		cat = trim(cat, spaces)
		local code = cat:match("^([%w%-.]+):")
		local sortkey = cat:match("|(.*)")
		if sortkey then
			raw_sortkey = raw_sortkey or frame:expandTemplate{
				title = "tracking category",
				args = {"Pages with raw sortkeys"}
			}
		end
		if code then
			return add_cat_table(code, sortkey, wikitext_topic_cat)
		end
		-- Remove sortkey and split by word.
		cat = split(cat:gsub("|.*", ""), "[" .. spaces .. "]+")
		-- Iterate over the category name, starting with the longest possible name and shaving off the first word until we find one. We do it this way because:
		-- (a) Going from shortest to longest risks falsely matching (e.g.) German Low German categories as German.
		-- (b) Checking the start of category names first risks falsely match (e.g.) Alsatian French as Alsatian (a variety of Alemannic German), not French.
		-- If no matches are found, then check the start of the category name, shaving off the last word each iteration.
		local cat_len = #cat
		local n, name, done = 1
		repeat
			name = concat(cat, " ", n, cat_len)
			done = do_iteration(name, sortkey, wikitext_langname_cat)
			if done then
				return
			end
			n = n + 1
		until n > cat_len
		n = cat_len - 1
		if n <= 0 then
			return
		end
		repeat
			name = concat(cat, " ", 1, n)
			done = do_iteration(name, sortkey, wikitext_langname_cat)
			if done then
				return
			end
			n = n - 1
		until n == 0
	end
	
	for prefix, cat in content:gmatch("\1([^\1\2]-[Cc][Aa][Tt][^\1\2]-):([^\1]-)\2") do
		prefix = trim(prefix, spaces):lower()
		if prefix == "cat" or prefix == "category" then
			process_category(cat)
		end
	end
	data.wikitext_topic_cat = wikitext_topic_cat
	data.wikitext_langname_cat = wikitext_langname_cat
	data.raw_sortkey = raw_sortkey
end

return data