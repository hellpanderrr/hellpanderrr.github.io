local data = {}

local U = mw.ustring.char

local anusvAra = U(0x11001)
local visarga = U(0x11002)
local virAma = U(0x11046)
local consonants = "𑀓𑀔𑀕𑀖𑀗𑀘𑀙𑀚𑀛𑀜𑀝𑀞𑀟𑀠𑀡𑀢𑀣𑀤𑀥𑀦𑀧𑀨𑀩𑀪𑀫𑀬𑀭𑀮𑀯𑀰𑀱𑀲𑀳𑀴𑀵𑀶𑀷"
local consonant = "[" .. consonants .. "]"

local acute = U(0x301)		-- combining acute

data["inc-pra"] = {
-- Priority digraphs
	{".[iuïüö]", {["ai"] = "𑀐", ["au"] = "𑀒", ["aï"] = "𑀅𑀇", ["aü"] = "𑀅𑀉",
				  ["aö"] = "𑀅𑀑",}},
-- Digraphs with 'h'
	{".h", {["kh"] = "𑀔", ["gh"] = "𑀖", ["ch"] = "𑀙", ["jh"] = "𑀛",
			["ṭh"] = "𑀞", ["ḍh"] = "𑀠", ["th"] = "𑀣", ["dh"] = "𑀥",
			["ph"] = "𑀨", ["bh"] = "𑀪",  }}, 
	{"ḹ", "𑀎"},
	{"l̥̄", "𑀎"},
	{"l̥", "𑀍"},
-- Single letters
	{".",  {["ṃ"] = anusvAra, ["ḥ"] = visarga,
			["ṅ"] = "𑀗", ["ñ"] = "𑀜", ["ṇ"] = "𑀡",   n = "𑀦",
			  m   = "𑀫",   y   = "𑀬",  r   = "𑀭",   l = "𑀮",
			  v   = "𑀯", ["ś"] = "𑀰", ["ṣ"] = "𑀱",   s = "𑀲",
			  a   = "𑀅", ["ā"] = "𑀆", 	i   = "𑀇", ["ī"] = "𑀈",
			  u   = "𑀉", ["ū"] = "𑀊",   e    = "𑀏",  o   = "𑀑",
			["ṝ"] = "𑀌", ["ḷ"] = "𑀴",
--	{"ḷ", "𑀍"}, -- Only Sanskrit uses this as a vowel.
			  k   = "𑀓",   g  = "𑀕",   c   = "𑀘",   j   = "𑀚",
			["ṭ"] = "𑀝", ["ḍ"] = "𑀟",   t   = "𑀢",  d   = "𑀤",
			  p   = "𑀧",   b   = "𑀩",  h   = "𑀳", ['̈'] = "",
			["ṛ"] = "𑀋",}},
	{"(𑀅)[%-/]([𑀇𑀉])", "%1%2"},		-- a-i, a-u for 𑀅𑀇, 𑀅𑀉; must follow rules for "ai", "au"
	{"(" .. consonant .. ")$", "%1" .. virAma},
	{acute, ""},
	-- this rule must be applied twice because a consonant may only be in one capture per operation, so "CCC" will only recognize the first two consonants
	{"(" .. consonant .. ")" .. "(" .. consonant .. ")", "%1" .. virAma .. "%2"},
	{"(" .. consonant .. ")" .. "(" .. consonant .. ")", "%1" .. virAma .. "%2"},
	{"i", "𑀇"},
	{"u", "𑀉"},
}

local vowels = {
	["𑀇"] = U(0x1103A),
	["𑀉"] = U(0x1103C),
	["𑀋"] = U(0x1103E),
	["𑀍"] = U(0x11040),
	["𑀏"] = U(0x11042),
	["𑀑"] = U(0x11044),
	["𑀆"] = U(0x11038),
	["𑀈"] = U(0x1103B),
	["𑀊"] = U(0x1103D),
	["𑀌"] = U(0x1103F),
	["𑀎"] = U(0x11041),
	["𑀐"] = U(0x11043),
	["𑀒"] = U(0x11045),
}

for independentForm, diacriticalForm in pairs(vowels) do
	table.insert(data["inc-pra"], {"(" .. consonant .. ")" .. independentForm, "%1" .. diacriticalForm})
end

-- This must go last, after independent vowels are converted to diacritics, or "aï", "aü" won't work.
table.insert(data["inc-pra"], {"(" .. consonant .. ")𑀅", "%1"})

-- [[w:Harvard-Kyoto]] to [[w:International Alphabet of Sanskrit Transliteration]]
data["inc-pra-tr"] = {
	[1] = {
		["A"] = "ā",
		["I"] = "ī",
		["U"] = "ū",
		["ĕ"] = "e", -- These two short vowels are transcriptional additions,
		["ŏ"] = "o", -- used in Pischel's transcription of Prakrit.  
		["J"] = "ñ",
		["T"] = "ṭ",
		["D"] = "ḍ",
		["N"] = "ṇ",
		["G"] = "ṅ",
		["z"] = "ś",
		["S"] = "ṣ",
		["M"] = "ṃ",
		["H"] = "ḥ",
		["ẏ"] = "y",
		["lRR"] = "l̥̄",
		["/"] = acute,
	},
	[2] = {
		["lR"] = "l̥",
		["RR"] = "ṝ",
	},
	[3] = {
		["R"] = "ṛ",
	},
}

return data