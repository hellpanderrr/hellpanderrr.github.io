--[=====[ 
Currently missing:
* Function for final obstruent devoicing of d, g, b, s, r (ɐ̯)
* Function for pre-consonantal obstruent devoicing of d, g, b, s
* Function to reduce geminates
* List of environments which trigger the palatalisation of /x/ (liquids + non-low front vowels)
* Function to determine if H is word initial (> /h/) or non-initial (> 0)  (⟨-ehe⟩- should be /eː/ in verbs only)
* Function to put stress in general, function to check for prefixes and realign stress accordingly.
* Function to convert ⟨e⟩ in unstressed syllables to ə > Function to reduce -ər to -r + "devoicing"
* Function to convert ⟨c⟩ before front vowels to /t͡s/?
* An input whether the word is Germanic or Romanic might make a lot of exceptions
  predictable/automatable, e.g. /ɪ, ɔ, ʊ/ > /i, o, u/ for short vowels in closed syllables,
  penultimate or final stress
* The unseparable prefixes do not take stress > Stress on the 2nd syllable
** A complete list could be compiled and the process automated, instead of making the user enter the stress by hand
* Rules to determine when to make vowels short vs. long. There will need to be
  ways to override this; I think they should be adding an h to force length,
  and either using a breve (e.g. ă ĕ ĭ) or maybe doubling the following consonant
  to force shortness. What should those rules be? Some guesses:
  - vowels should be short before a geminate consonant
  - vowels should be long in a stressed open syllable
  - vowels should probably be long in a stressed final syllable before a single
    consonant (but with possible exceptions, e.g. '-eg')
  - vowels should probably be short before two consonants (except possibly 'st'?)
  - syllables with secondary stress should be treated as if stressed
  - syllables directly following a known prefix (aus-, zu-, über-, ge-, etc.)
    should be treated as if stressed, whether they are actually stressed or not
  - when there's an explicit slash to separate compounds, all parts should be
    treated as if they were separate words for vowel-length purposes (e.g.
    '-tag' in 'Reichs/tag' should be long)
  - what about other unstressed syllables?
--]=====]

local export = {}

local u = mw.ustring.char
local rfind = mw.ustring.find
local rsubn = mw.ustring.gsub
local rmatch = mw.ustring.match
local rsplit = mw.text.split
local ulower = mw.ustring.lower
local uupper = mw.ustring.upper
local usub = mw.ustring.sub
local ulen = mw.ustring.len

-- version of rsubn() that discards all but the first return value
local function rsub(term, foo, bar)
	local retval = rsubn(term, foo, bar)
	return retval
end

-- apply rsub() repeatedly until no change
local function rsub_repeatedly(term, foo, bar)
	while true do
		local new_term = rsub(term, foo, bar)
		if new_term == term then
			return term
		end
		term = new_term
	end
end

local function ine(x)
	if x == "" then return nil else return x end
end

local AC = u(0x0301)
local GR = u(0x0300)
local BREVE = u(0x0306)
local stress_accent = AC .. GR
local stress_accent_c = "[" .. stress_accent .. "]"
local accent = stress_accent .. BREVE
local accents_r = "[" .. accent .. "]*"
local DIA = u(0x0308)
local vowel = "aeiouyäöüæœ" .. accent
local vowel_c = "[" .. vowel .. "]"
local cons_c = "[^" .. vowel .. ".⁀ %-()]"
local cons_or_boundary_c = "[^" .. vowel .. "rl. %-()]" -- includes ⁀  -- I have added /l/ & /r/ as a stopgap against Brücke -> /ˈprʏkə/, but this may need a new name.
local front_vowel = "eiyæœ"
local front_vowel_c = "[" .. front_vowel .. "]"

local devoiced_cons = {b="p", d="t", g="k", r="ɐ̯"}
local sequences = {
	["a"] = {
		["a"   ] = "a";
		["ah"  ] = "aː";
		["ai"  ] = "aɪ̯";
		["au"  ] = "aʊ̯";
		["auch"] = { "aʊ̯", "x" };
	};
	["ä"] = {
		["ä"   ] = "ɛ";
		["äh"  ] = "ɛː";
		["äu"  ] = "ɔʏ̯";
	};
	["b"] = {
		["b"   ] = "b";
		["bb"  ] = "b";
	};
	["c"] = {
		["c"   ] = "ts"; -- ???
		["ch"  ] = "ç";
	};
	["d"] = {
		["d"   ] = "d";
		["dd"  ] = "d";
		["dsch"] = "dʒ";
	};
	["e"] = {
		["e"   ] = "ɛ";
		["ee"  ] = "eː";
		["ei"  ] = "aɪ̯";
		["eich"] = { "aɪ̯", "ç" };
		["eu"  ] = "ɔʏ̯";
	};
	["f"] = "f";
	["g"] = "ɡ";
	["h"] = "h";
	["i"] = {
		["i"   ] = "ɪ";
		["ie"  ] = "iː";
	};
	["j"] = "j";
	["k"] = {
		["k"   ] = "k";
		["kk"  ] = "k";
		["ck"  ] = "k";
	};
	["l"] = "l";
	["m"] = "m";
	["n"] = {
		["n"   ] = "n";
		["ng"  ] = "ŋ";
		["nn"  ] = "n";
	};
	["o"] = {
		["oo"  ] = "oː";
		["os"  ] = { "ɔ", "s" };
		["o"   ] = "ɔ";
	};
	["ö"] = {
		 -- XXX: manchmal /øː/
		["ö"   ] = "œ";
		["ös"  ] = { "œ", "s" };
	};
	["p"] = {
		["ph"  ] = "f";
		["pp"  ] = "p";
		["p"   ] = "p";
	};
	["q"] = {
		["qu"  ] = { "k", "f" };
		["q"   ] = "k"; -- XXX
	};
	["r"] = {
		 -- XXX: /ʀ/? /r/?; manchmal /ɐ/ ("Uhr"); auch /ər/ ("oder")
		["r"   ] = "r";
		["rr"  ] = "r";
	};
	["s"] = {
		["s"   ] = "s";
		["sch" ] = "ʃ";
		["sp"  ] = { "ʃ", "p" }; 
		["ss"  ] = "s";
		["st"  ] = { "ʃ", "t" };
	};
	["t"] = {
		["t"   ] = "t";
		["tsch"] = "t͡ʃ";
		["tt"  ] = "t";
		["tion"] = { "t͡s", "i̯", "o", "n" };
	};
	["u"] = {
		["u"   ] = "ʊ";
		["uch" ] = { "ʊ", "x" };
	};
	["ü"] = {
		["ü"   ] = "yː";
		["üh"  ] = "yː";
	};
	["v"] = "f";
	["w"] = "ʋ";
	["x"] = { "k", "s" }; -- XXX
	["y"] = "i";
	["z"] = "z"; -- already converted from s
	["ß"] = "s";
	["́"] = "ˈ"; -- FIXME
	["-"] = {};
}

function export.IPA(text, orig, pos)
	if type(text) == 'table' then
		text, orig, pos = ine(text.args[1]), ine(text.args.orig), ine(text.args.pos)
	end
	text = text or mw.title.getCurrentTitle().text
	text = ulower(text)
	-- decompose, then recompose umlauted vowels, and convert ae oe ue to
	-- umlauted vowels
	text = mw.ustring.toNFD(text)
	-- while we're doing this, don't get confused by wrongly-ordered umlauts/e's
	-- and other accents
	text = rsub(text, "(" .. accents_r .. ")([e" .. DIA .. "])", "%2%1")
	text = rsub(text, "([aou])[e" .. DIA .. "]", {a="ä", o="ö", u="ü"})
	-- put breves before acute/grave accents
	text = rsub(text, "(" .. stress_accent_c .. ")" .. BREVE, BREVE .. "%1")

	-- To simplify checking for word boundaries and liaison markers, we
	-- add ⁀ at the beginning and end of all words, and remove it at the end.
	-- Note that the liaison marker is ‿.
	text = rsub(text, "%s*,%s*", '⁀⁀ | ⁀⁀')
	text = rsub(text, "%s+", '⁀ ⁀')
	text = rsub(text, "%-+", '⁀-⁀')
	text = '⁀⁀' .. text .. '⁀⁀'

	text = rsub(text, "([aou]" .. accents_r .. ")" .. "ch", "%1χ")
	text = rsub(text, "sch", "ʃ")
	text = rsub(text, "ch", "ç")
	text = rsub(text, "ck", "kk")
	text = rsub(text, "z", "c")
	text = rsub(text, "s(" .. vowel_c .. ")", "z%1")
	text = rsub(text, "([bdgr])(" .. cons_or_boundary_c .. ")",
		function(c1, c2)
			return devoiced_cons[c1] .. c2
		end)
	
	-- Buchstaben in Foneme konvertieren
	local phones, i, n = {}, 1, ulen(text)
	while i <= n do
		local bid = ulower(usub(text, i, i))
		local value = sequences[bid]
		
		if (type(value) == 'table') and not value[1] then
			local bidl = ulen(bid)
			for seq in pairs(value) do
				local seql = ulen(seq)
				if seql > bidl then
					if (ulower(usub(text, i, i + seql - 1)) == seq) then
						bid = seq
						bidl = ulen(bid)
					end
				end
			end
			value = value[bid]
		end
		
		if type(value) == 'string' then
			table.insert(phones, value)
		elseif not value then
			table.insert(phones, bid)
		else
			for _, phone in ipairs(value) do
				table.insert(phones, phone)
			end
		end
		
		i = i + ulen(bid)
	end

	text = table.concat(phones)
	--remove hyphens and word-boundary markers
	text = rsub(text, '[⁀%-]', '')
	return text
end

return export