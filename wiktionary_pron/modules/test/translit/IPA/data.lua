local data = {}

--[=[
This should list the language codes of all languages that have a pronunciation
page in the appendix of the form ''Appendix:LANG pronunciation'', e.g.
[[Appendix:Russian pronunciation]]. For these languages, the text "key" next to
the generated pronunciation links to such pages; for other languages, it links
to the "LANG phonology" page in Wikipedia (which may or may not exist).
[[Module:IPA]] is responsible for this linking; see format_IPA_full().
]=]
local langs_with_infopages = {
	"acw",
	"ady",
	"ang",
	"arc",
	"ba",
	"bg",
	"bo",
	"ca",
	"cho",
	"cmn",
	"cs",
	"cv",
	"cy",
	"da",
	"de",
	"dsb",
	"dz",
	"egl",
	"egy",
	"el",
	"en",
	"enm",
	"eo",
	"es",
	"fa",
	"fi",
	"fo",
	"fr",
	"fy",
	"ga",
	"gd",
	"gem-pro",
	"got",
	"he",
	"hi",
	"hrx",
	"hu",
	"hy",
    "id",
	"ii",
	"is",
	"it",
	"iu",
	"ja",
	"jbo",
	"ka",
	"kls",
	"ko",
	"kw",
	"la",
	"lb",
	"liv",
	"lt",
	"lv",
	"mdf",
	"mfe",
	"mic",
	"mk",
	"mns",
	"ms",
	"mt",
	"mul",
	"my",
	"nan",
	"nci",
	"nl",
	"nn",
	"no",
	"nov",
	"nv",
	"pjt",
	"pl",
	"ps",
	"pt",
	"ro",
	"ru",
	"scn",
	"sco",
	"sga",
	"sh",
	"sl",
	"sq",
	"sv",
	"sw",
	"syc",
	"szl",
	"tg",
	"th",
	"tl",
	"tr",
	"tyv",
	"ug",
	"uk",
	"vi",
	"vo",
	"wlm",
	"yi",
	"yue",
	"zlw-mas"
}

data.langs_with_infopages = {}

-- Convert the list in `langs_with_infopages` to a set.
for _, langcode in ipairs(langs_with_infopages) do
	data.langs_with_infopages[langcode] = true
end

--[=[
This should list the diphthongs of a language (in the form of Lua patterns),
provided they do *NOT* contain semivowel symbols such as /j w ɰ ɥ/ or vowels
with nonsyllabic diacritics such as /i̯ u̯/. For example, list /au/ or /aʊ/,
but do not list /aw/ or /au̯/. The data in this table is used to count the
number of syllables in a word. [[Module:syllables]] automatically knows how
to correctly handle semivowel symbols and nonsyllabic diacritics.

Any language listed here will automatically have categories of the form
"LANG #-syllable words" generated. In addition, any language listed below under
`langs_to_generate_syllable_count_categories` will also have such categories
generated.

NOTE: There are some additional languages that have these categories.
For example:
* Thai words have these categories added by [[Module:th-pron]].
]=]
data.diphthongs = {
	["cs"] = { -- [[w:Czech phonology#Diphthongs]]
		"[aeo]u",
		},
	["de"] = {
		"a[ɪʊ]",
		"ɔ[ʏɪ]",
		},
	["en"] = { -- from [[Appendix:English pronunciation]] mostly, but /ʌɪ/ is from the OED
		"[aɑeɛoɔʌ][ɪi]",
		"[ɑɒæo]e",
		"[əɐ]ʉ",
		"[aɒəoɔæ]ʊ",
		"æo",
		"[ɛeɪiɔʊʉ]ə",	-- /iə/ is a diphthong in NZE, but a disyllabic sequence in GA.
						-- /ɪə/ is both a disyllabic sequence and a diphthong in old-fashioned RP.
		"[aʌ][ʊɪ]ə",	-- May be a disyllabic sequence in some or all dialects?
		},
	["grc"] = {
		"[aeyo]i",
		"[ae]u",
		"[ɛɔa]ː[iu]",
		},
	["hrx"] = {
		"aɪ̯",
		"aʊ̯",
		"oɪ̯",
		"eʊ̯",
	},
	["is"] = {			-- [[w:Icelandic phonology#Vowels]]
		"[aeø][iɪy]",	-- Wikipedia is oddly specific about the second element: ei and ai, but øɪ.
		"[ao]u",
		},
	["it"] = {
		"[aeɛoɔu]i",
		"[aeɛioɔ]u",
		},
	["la"] = {
		"[eaou]i",
		"[eao]u",
		"[ao]e",
		},
	["lb"] = {
		"[iu]ə",
		"[ɜoæɑ]ɪ",
		"[əæɑ]ʊ",
	},
}

--[=[
This should list any languages for which categories of the form
"LANG #-syllable words", e.g. [[:Category:Russian 3-syllable words]], should be
generated. Do not list languages here if they have an entry above under
`data.diphthongs`; such languages are automatically added to this list.
]=]
local langs_to_generate_syllable_count_categories = {
	"ar",	-- Arabic has diphthongs, but they are transcribed
			-- with semivowel symbols.
	"ary",	-- Moroccan Arabic has diphthongs, but they are transcribed
			-- with semivowel symbols.
	"ca",	-- Catalan has diphthongs, but they are generally transcribed using
			-- /w/ and /j/, so do not need to be listed (see [[w:Catalan language#Diphthongs and triphthongs]].
	"es",	-- Spanish has diphthongs, but they are transcribed with i̯ etc.
	"fi",	-- Finnish has diphthongs, but they are now automatically transcribed with
			-- the nonsyllabic diacritic
	"fr",	-- French has diphthongs, but they are transcribed
			-- with semivowel symbols: [[w:French phonology#Glides and diphthongs]].
    "id",   -- Indonesian has diphthongs, but they are transcribed with i̯ or /j/ etc.
	"ka",
    "kmr",
	"ku",
	"mk",
    "ms",   -- Malay has diphthongs, but they are transcribed with i̯ or /j/ etc.
    "mt",	-- Maltese has diphthongs, but they are transcribed
			-- with semivowel symbols.
	"pl",   -- No diphthongs, properly speaking; sequences of a vowel and /w/ or /j/ though.
	"pt",	-- Portuguese has diphthongs, but they are transcribed with i̯ or /j/ etc.
	"ru",	-- No diphthongs, properly speaking; sequences of a vowel and /j/ though.
	"sk",	-- Slovak has rising diphthongs, /i̯e, i̯a, i̯u, u̯o/, which are probably always spelled with the nonsyllabic diacritic, so do not need to be listed.
	"sl",	-- No diphthongs, properly speaking; sequences of a vowel, /j/ and /w/ though
	"sq",	-- [[w:Albanian language#Vowels]] doesn't mention anything about diphthongs.
    "tl",   -- Tagalog has diphthongs, but they are transcribed with i̯ or /j/ etc.
	"ug",	-- No diphthongs.
}

data.langs_to_generate_syllable_count_categories = {}

-- Convert the list in `langs_to_generate_syllable_count_categories` to a set.
for _, langcode in ipairs(langs_to_generate_syllable_count_categories) do
	data.langs_to_generate_syllable_count_categories[langcode] = true
end
-- Also add languages listed under `data.diphthongs`.
for langcode, _ in pairs(data.diphthongs) do
	data.langs_to_generate_syllable_count_categories[langcode] = true
end


-- Languages to use the phonetic not phonemic notation to compute syllables counts.
local langs_to_use_phonetic_notation = {
	"es",
	"mk",
	"ru",
}

data.langs_to_use_phonetic_notation = {}

-- Convert the list in `langs_to_use_phonetic_notation` to a set.
for _, langcode in ipairs(langs_to_use_phonetic_notation) do
	data.langs_to_use_phonetic_notation[langcode] = true
end


-- Non-standard or obsolete IPA symbols.
data.nonstandard = {
	--[[	The following symbols consist of more than one character,
			so we can't put them in the line below.		]]
	"ɑ̢", "ɔ̗", "ɔ̖",
	"[?ƍσƺƪƞƛłščžǰǧǯẋᵻᵿⱻʚω∅ØȣᴀᴇⱻQKPT]"
}

-- See valid IPA characters at [[Module:IPA/data/symbols]].

data.phonemes = {}
data.phonemes["dz"] = {
	"m", "n", "ŋ",
	"p", "t", "ʈ", "k",
	"pʰ", "tʰ", "ʈʰ", "kʰ",
	"t͡s", "t͡ɕ",
	"t͡sʰ", "t͡ɕʰ",
	"w", "s", "z", "ɬ", "l", "r", "ɕ", "ʑ", "j", "h",
	"ɑ", "e", "i", "o", "u",
	"ɑː", "eː", "ɛː", "iː", "oː", "øː", "uː", "yː",
	"ɑ˥", "e˥", "i˥", "o˥", "u˥",
	"ɑː˥", "eː˥", "ɛː˥", "iː˥", "oː˥", "øː˥", "uː˥", "yː˥",
	"m˥", "n˥", "ŋ˥", "p˥", "k˥", "k̚˥", "w˥", "l˥", "r˥", "ɕ˥", "j˥", ")˥",
	"ɑ˩", "e˩", "i˩", "o˩", "u˩",
	"ɑː˩", "eː˩", "ɛː˩", "iː˩", "oː˩", "øː˩", "uː˩", "yː˩",
	"m˩", "n˩", "ŋ˩", "p˩", "k˩", "k̚˩", "w˩", "l˩", "r˩", "ɕ˩", "j˩", ")˩",
	".", ",", "-",
}
data.phonemes["eo"] = {
	"a", "b", "d", "d͡ʒ", "d͡z", "e", "f", "h", "i", "j", "k",
	"l", "m", "n", "o", "p", "r", "s", "t", "t͡s", "t͡ʃ",
	"u", "v", "w", "x", "z", "ɡ", "ʃ", "ʒ",
	"ˈ", ".", " ", "-",
}
data.phonemes["hy"] = {
	"ɑ", "b", "ɡ", "d", "ɛ", "z", "ɛ", "ə", "tʰ", "ʒ", "i", "l", "χ", "t͡s",
	"k", "h", "d͡z", "ʁ", "t͡ʃ", "m", "j", "n", "ʃ", "ɔ", "t͡ʃʰ", "p", "d͡ʒ",
	"r", "s", "v", "t", "ɾ", "t͡sʰ", "v", "pʰ", "kʰ", "ɔ", "f", "ŋɡ", "ŋk",
	"ŋχ", "u", "ˈ", "ˌ", ".", " ", "ː",
}
data.phonemes["nl"] = {
	"m", "n", "ŋ",
	"p", "b", "t", "d", "k", "ɡ",
	"f", "v", "s", "z", "ʃ", "ʒ", "x", "ɣ", "ɦ",
	"ʋ", "l", "j", "r",
	"ɪ", "ʏ", "ɛ", "ə", "ɔ", "ɑ",
	"i", "iː", "y", "yː", "u", "uː", "eː", "øː", "oː", "ɛː", "œː", "ɔː", "aː",
	"ɛi̯", "œy̯", "ɔi̯", "ɑu̯", "ɑi̯",
	"iu̯", "yu̯", "ui̯", "eːu̯", "oːi̯", "aːi̯",
	"ˈ", "ˌ", ".", " ", "-",
}
data.phonemes["mt"] = {
	"m", "n",
	"p", "t", "k", "ʔ",
	"b", "d", "ɡ",
	"t͡s", "t͡ʃ",
	"d͡z", "d͡ʒ",
	"f", "s", "ʃ", "ħ",
	"v", "z", "ʒ", "ɣ",
	"l", "j", "w",
	"r",
	"ɪ", "ɛ", "ɔ", "a", "u",
	"ɛˤ", "ɔˤ", "aˤ", "əˤ",
	"ɛˤː", "ɔˤː", "aˤː", "əˤː", "ɪˤː",
	"iː", "ɪː", "ɛː", "ɔː", "aː", "uː",
	"ˈ", "ˌ", ".", " ", "‿", "-"
}

return data