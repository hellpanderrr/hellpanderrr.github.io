local export = {}
local m_IPA = require("mw")
local lang = require("languages").getByCode("uk")

local m_IPA = require("IPA")
local m_table = require("table")
local com = require("uk-common")
require("script utilities")
local u = mw.ustring.char
local rfind = mw.ustring.find
local rsplit = mw.text.split
local rsubn = mw.ustring.gsub
local AC = u(0x301)
local GR = u(0x300)

local vowel_no_i = "aɛɪuɔɐoʊe"
local vowel = vowel_no_i .. "i"
local vowel_c = "[" .. vowel .. "]"
local consonant_no_w = "bdzʒɡɦmnlrpftskxʃj"
local consonant_no_w_c = "[" .. consonant_no_w .. "]"
local consonant = consonant_no_w .. "ʋβ̞wʍ"
local consonant_c = "[" .. consonant .. "]"
local palatalizable = "tdsznlrbpʋfɡmkɦxʃʒ"
local palatalizable_c = "[" .. palatalizable .. "]"

-- version of rsubn() that discards all but the first return value
local function rsub(term, foo, bar)
	local retval = rsubn(term, foo, bar)
	return retval
end


function export.remove_pron_notations(text, remove_grave)
	-- Remove grave accents from annotations but maybe not from phonetic respelling
	if remove_grave then
		text = mw.ustring.toNFC(rsub(mw.ustring.toNFD(text), GR, ""))
	end
	return text
end

	
local perm_syl_onset = m_table.listToSet({
	'spr', 'str', 'skr', 'spl', 'skl',
	'sp', 'st', 'sk', 'sf', 'sx',
	'pr', 'br', 'tr', 'dr', 'kr', 'gr', 'ɦr', 'fr', 'xr',
	'pl', 'bl', 'kl', 'gl', 'ɦl', 'fl', 'xl',
})


function export.pronunciation(text, allow_unstressed, output, ann)
	if type(text) == "table" then
		local iparams = {
			["output"] = {},
		}
		local params = {
			[1] = {},
			["allow_unstressed"] = {type = "boolean"},
			["ann"] = {},
			["output"] = {},
		}
		local iargs = require("parameters").process(text.args, iparams)
		local args = require("parameters").process(text:getParent().args, params)
		text, allow_unstressed, output, ann = args[1], args.allow_unstressed, iargs.output, args.ann
	end
	
	if not text then
		text = mw.title.getCurrentTitle().text
	end

	--	Returns an error if the text contains alphabetic characters that are not Cyrillic.
	require("script utilities").checkScript(text, "Cyrl")

	local origterm = text
	-- Lowercase and decompose ѐ and ѝ into letter + accent char
	text = mw.ustring.lower(com.decompose_grave(text))

	if not allow_unstressed and com.needs_accents(text) then
		error("Multisyllabic words that are not prefixes or suffixes must have an acute accent marking the stress, unless allow_unstressed=1 is given: " .. text)
	end

	-- convert commas and en/en dashes to IPA foot boundaries
	text = rsub(text, '%s*[,–—]%s*', ' | ')

	-- canonicalize multiple spaces
	text = rsub(text, '%s+', ' ')

	local phonetic_chars_map = {
	
		-- single characters that map to IPA sounds; these are processed last
		[3] = {
			["а"] = "a",	["б"] = "b",	["в"] = "ʋ",	["г"] = "ɦ",	["ґ"] = "ɡ", 
			["д"] = "d",	["е"] = "ɛ",	["є"] = "jɛ",	["ж"] = "ʒ",	["з"] = "z", 
			["и"] = "ɪ",	["і"] = "i",	["ї"] = "ji",	["й"] = "j",	["к"] = "k", 
			["л"] = "l",	["м"] = "m",	["н"] = "n",	["о"] = "ɔ",	["п"] = "p", 
			["р"] = "r",	["с"] = "s",	["т"] = "t",	["у"] = "u",	["ф"] = "f", 
			["х"] = "x",	["ц"] = "t͡s",	["ч"] = "t͡ʃ",	["ш"] = "ʃ",	["щ"] = "ʃt͡ʃ", 
			["ь"] = "ʲ",	["ю"] = "ju",	["я"] = "ja",	["’"] = "j",
			-- accented vowels
			[AC] = "ˈ", [GR] = "ˌ",
		},
	
		-- character sequences of two that map to IPA sounds
		[2] = {
			["дж"] = "d͡ʒ",	["дз"] = "d͡z",
		-- Dental plosives assimilate to following hissing/hushing consonants, which is not noted in the spelling.
			["дс"] = "d͡zs",   ["дш"] = "d͡ʒʃ",   ["дч"] = "d͡ʒt͡ʃ", ["дц"] = "d͡zt͡s",
			["тс"] = "t͡s",	["тш"] = "t͡ʃʃ",   ["тч"] = "t͡ʃː", ["тц"] = "t͡sː", 
		},
	
		-- character sequences of three that map to IPA sounds
		[1] = {
			["дзь"] = "d͡zʲ", 
		-- Dental plosives assimilate to following hissing/hushing consonants, which is not noted in the spelling.
			["тьс"] = "t͡sʲː"
		},
	}
	
	local pronuns = {}
	-- FIXME, not completely correct, we need to treat hyphens at beginning and end of
	-- a word as indicating unstressed pronunciation.
	for _, phonetic in ipairs(rsplit(text, "[%s%-]+")) do
		phonetic = "#" .. phonetic .. "#"
		local orthographic_replacements = {
			-- first apply consonant cluster simplifications that always occur orthographically
			["нтськ"	] = "ньськ",
			["стськ"	] = "ськ",
			["нтст"		] = "нст",
			["стч"		] = "шч",
			["стд"		] = "зд",
			["стс"		] = "сː",
			["стськ"	] = "ськ",
			["#зш"		] = "#шː",
			["зш"		] = "жш",
			["#зч"		] = "#шч",
			["зч"		] = "жч",
		
			-- then long consonants that are orthographically geminated.
			["([бвгґд])%1"			] = "%1ː",
			["([^д]+)жж"			] = "%1жː", -- джж sequence encode diphonemic дж
			["([^д]+)зз"			] = "%1зː", -- дзз sequence encode diphonemic дз
			["([йклмнпрстфхцчшщ])%1"] = "%1ː",
			["дждж"					] = "джː",
			["дздз"					] = "дзː",
		}
		
		for regex, replacement in pairs(orthographic_replacements) do
			phonetic = rsub(phonetic, regex, replacement)
		end
		
		-- remap apostrophe to '!' so that it doesn't conflict with IPA stress mark
		phonetic = rsub(phonetic, "'", "!")
		
		-- replace multiple letter sequences
		for _, replacements in ipairs(phonetic_chars_map) do
			for key, replacement in pairs(replacements) do
				phonetic = rsub(phonetic, key, replacement)
			end
		end

		-- move stress mark, added by phonetic_chars_map, before vowel
		phonetic = rsub(phonetic, "([aɛiɪuɔ])([ˈˌ])", "%2%1")

		-- add accent if the word is monosyllabic and not allow_unstressed,
		-- so that monosyllabic words without explicit stress marks get stressed
		-- vowel allophones; we use a different character from the regular
		-- primary stress mark so we can later remove it without affecting
		-- explicitly user-added accents on monosyllabic words, as in нема́ за́ що.
		local _, numberOfVowels = rsubn(phonetic, "[aɛiɪuɔ]", "")
		if (numberOfVowels == 1) and not allow_unstressed then
			phonetic = rsub(phonetic, "([aɛiɪuɔ])", "⁀%1")
		end
		
		-- palatalizable consonants before /i/ or /j/ become palatalized
		phonetic = rsub(phonetic, "(" .. palatalizable_c .. ")([ː]?)([ˈˌ⁀]?)i", "%1ʲ%2%3i")
		phonetic = rsub(phonetic, "(" .. palatalizable_c .. ")([ː]?)j", "%1ʲ%2")

		-- eliminate garbage sequences of [ʲːj] resulting from -тьс- cluster followed by [j]
		phonetic = rsub(phonetic, "ʲːj", "ʲː")

		-- consonant simplification: ст + ц' → [с'ц']. We do it here because of palatalization.
		-- Due to the т +ц → [ц:] rule length is present. According to Орфоепскі словник p. 13,
		-- both forms are proper, without length in normal (colloquial) speech and with length
		-- in slow speech, so we parenthesize the length as optional.
		phonetic = rsub(phonetic, "st͡sʲ([ː]?)", "sʲt͡sʲ(%1)")
		
		-- assimilation: voiceless + voiced = voiced + voiced
		-- should /ʋ/ be included as voiced? Орфоепічний словник doesn't voice initial cluster of шв (p. 116)
		local voiced_obstruent = "[bdzʒɡɦ]"
		local voicing = {
			["p"] = "b",
			["f"] = "v",
			["t"] = "d",
			["tʲ"] = "dʲ",
			["s"] = "z",
			["sʲ"] = "zʲ",
			["ʃ"] = "ʒ",
			["k"] = "ɡ",
			["x"] = "ɦ",
			["t͡s"] = "d͡z",
			["t͡sʲ"] = "d͡zʲ",
			["t͡ʃ"] = "d͡ʒ",
			["ʃt͡ʃ"] = "ʒd͡ʒ",
		}
		for voiceless, voiced in pairs(voicing) do
			phonetic = rsub(phonetic, voiceless .. "(" .. voiced_obstruent .. "+)", voiced .. "%1")
		end

		-- In the sequence of two consonants, of which the second is soft, the first is pronounced soft too
		-- unless the first consonant is a labial, namely б, п, в, ф, м.
		phonetic = rsub(phonetic, "([tdsznl])(.)ʲ", "%1ʲ%2ʲ")
		phonetic = rsub(phonetic, "([tdsznl])t͡sʲ", "%1ʲt͡sʲ")
		phonetic = rsub(phonetic, "([tdsznl])d͡zʲ", "%1ʲd͡zʲ")
		phonetic = rsub(phonetic, "t͡s(.)ʲ", "t͡sʲ%1ʲ")
		phonetic = rsub(phonetic, "d͡z(.)ʲ", "d͡zʲ%1ʲ")
		phonetic = rsub(phonetic, "d͡zt͡sʲ", "d͡zʲt͡sʲ")
		phonetic = rsub(phonetic, "t͡sd͡zʲ", "t͡sʲd͡zʲ")

		-- Hushing consonants ж, ч, ш assimilate to the following hissing consonants, giving a long hissing consonant:
		-- [ʒ] + [t͡sʲ] → [zʲt͡sʲ], [t͡ʃ] + [t͡sʲ] → [t͡sʲː], [ʃ] + [t͡sʲ] → [sʲt͡sʲ], [ʃ] + [sʲ] → [sʲː]
		phonetic = rsub(phonetic, "ʒt͡sʲ", "zʲt͡sʲ")
		phonetic = rsub(phonetic, "t͡ʃt͡sʲ", "t͡sʲː")
		phonetic = rsub(phonetic, "ʃt͡sʲ", "sʲt͡sʲ")
		phonetic = rsub(phonetic, "ʃsʲ", "sʲː")

		-- Hissing consonants before hushing consonants within a word assimilate - on зш and зч word-initially and 
		-- word-medially see above.
		-- [s] + [ʃ] → [ʃː],  [z] + [ʃ] → [ʒʃ], [z] + [t͡ʃ] → [ʒt͡ʃ]
		-- [z] + [d͡ʒ] → [ʒd͡ʒ]
		phonetic = rsub(phonetic, "zʒ", "ʒː")
		phonetic = rsub(phonetic, "sʃ", "ʃː")
		phonetic = rsub(phonetic, "zt͡ʃ", "ʒt͡ʃ")
		phonetic = rsub(phonetic, "zd͡ʒ", "ʒd͡ʒ")
		phonetic = rsub(phonetic, "t͡ʒ", "d͡ʒ")
		phonetic = rsub(phonetic, "t͡z", "d͡z")
		
		-- cleanup: excessive palatalization: CʲCʲCʲ → CCʲCʲ
		phonetic = rsub(phonetic, "([^aɛiɪuɔ]+)ʲ([^aɛiɪuɔ]+)ʲ([^aɛiɪuɔ]+)ʲ", "%1%2ʲ%3ʲ")

		-- unstressed /a/ has an allophone [ɐ]
		phonetic = rsub(phonetic, "([^ˈˌ⁀])a", "%1ɐ")
		-- unstressed /u/ has an allophone [ʊ]
		phonetic = rsub(phonetic, "([^ˈˌ⁀])u", "%1ʊ")
		-- unstressed /ɔ/ has by assimilation an allophone [o] before a stressed syllable with /u/ or /i/
		phonetic = rsub(phonetic, "ɔ([bdzʒɡɦmnlrpftskxʲʃ͡]+)([ˈˌ⁀][uiʊ])", "o%1%2")
		-- one allophone [e] covers unstressed /ɛ/ and /ɪ/
		phonetic = rsub(phonetic, "([^ˈˌ⁀])[ɛɪ]", "%1e")

		-- Remove the monosyllabic stress we auto-added to ensure that vowels in
		-- monosyllabic words get stressed allophones. Do this before vocalizing
		-- /ʋ/ and /j/. NOTE: Nothing below should depend on stress marks being
		-- present.
		phonetic = rsub(phonetic, "⁀", "")

		-- /ʋ/ has an allophone [u̯] in a syllable coda
		phonetic = rsub(phonetic, "(" .. vowel_c .. ")ʋ([" .. consonant_no_w .. "#])", "%1u̯%2")
		-- /ʋ/ has an allophone [w] before /ɔ, u/ and voiced consonants (not after a vowel; [ʋ] before vowel already converted)
		phonetic = rsub(phonetic, "ʋ([ˈˌ]?[ɔuoʊbdzʒɡɦmnlr])", "w%1")
		-- /ʋ/ has an allophone [β̞] before remaining vowels besides /i/
		-- Not sure whether this looks good.
		-- phonetic = rsub(phonetic, "ʋ([ˈˌʲ]*[" .. vowel_no_i .. "])", "β̞%1")
		-- /ʋ/ has an allophone [ʍ] before before voiceless consonants (not after a vowel; [ʋ] before vowel already converted)
		phonetic = rsub(phonetic, "ʋ([pftskxʃ])", "ʍ%1")

		-- in a syllable-final position (i.e. the first position of a syllable coda) /j/ has an allophone [i̯]:
		phonetic = rsub(phonetic, "(" .. vowel_c .. ")j([" .. consonant_no_w .. "#])", "%1i̯%2")
		-- also at the beginning of a word before a consonant
		phonetic = rsub(phonetic, "#j(" .. consonant_no_w_c .. ")", "#i̯%1")
	 
		-- remove old orthographic apostrophe
		phonetic = rsub(phonetic, "!", "")
		-- stress mark in correct place
		-- (1) Put the stress mark before the final consonant of a cluster (if any).
		phonetic = rsub(phonetic, "([^#" .. vowel .. "]?[ʲː]*)([ˈˌ])", "%2%1")
		-- (2) Continue moving it over the rest of an affricate with a tie bar.
		phonetic = rsub(phonetic, "([^#" .. vowel .. "]͡)([ˈˌ])", "%2%1")
		-- (3) Continue moving it over any "permanent onset" clusters (e.g. st, skr, pl, also Cj).
		phonetic = rsub(phonetic, "(.)(ʲ?)(" .. consonant_c .. ")(ʲ?)([ˈˌ])(" .. consonant_c .. ")",
			function(a, aj, b, bj, stress, c)
				if perm_syl_onset[a .. b .. c] then
					return stress .. a .. aj .. b .. bj .. c
				elseif perm_syl_onset[b .. c] or c == "j" then
					return a .. aj .. stress .. b .. bj .. c
				else
					return a .. aj .. b .. bj .. stress .. c
				end
			end)
		-- (4) If we're in the middle of an affricate with a tie bar, continue moving back
		--     if the following consonant is /j/, else move forward.
		phonetic = rsub(phonetic, "([^#" .. vowel .. "]͡)([ˈˌ])(.ʲ?j)", "%2%1%3")
		phonetic = rsub(phonetic, "([^#" .. vowel .. "]͡)([ˈˌ])(.ʲ?)", "%1%3%2")
		-- (5) Move back over any remaining consonants at the beginning of a word.
		phonetic = rsub(phonetic, "#([^#" .. vowel .. "]+)([ˈˌ])", "#%2%1")
		-- (6) Move back over u̯ or i̯ at the beginning of a word.
		phonetic = rsub(phonetic, "#([ui]̯)([ˈˌ])", "#%2%1")

		phonetic = rsub(phonetic, "ʲ?ːʲ", "ʲː")

		-- use dark [ɫ] for non-palatal /l/
		phonetic = rsub(phonetic, "l([^ʲ])", "ɫ%1")

		table.insert(pronuns, phonetic)
	end

	phonetic = rsub(table.concat(pronuns, " "), "#", "")
	
	if output == "template" then
		local ipa = m_IPA.format_IPA_full(lang, { { pron = "[" .. phonetic .. "]" } } )
		local anntext
		if ann == "1" or ann == "y" then
			-- remove secondary stress annotations
			anntext = "'''" .. export.remove_pron_notations(origterm, true) .. "''':&#32;"
		elseif ann then
			anntext = "'''" .. ann .. "''':&#32;"
		else
			anntext = ""
		end

		return anntext .. ipa
	else
		return phonetic
	end
end

return export