--[[

Author: Benwing; some very early work by CodeCat and Atitarev

This module holds some commonly used functions for the Russian language.
It's generally for use from other modules, not #invoke, although some functions
can be invoked from a template (export.iotation(), export.reduce_stem(),
export.dereduce_stem() -- this was actually added to support calling from a
bot script rather than from a user template). There's also export.main(),
which supposedly can be used to invoke most functions in this module from a
template, but it may or may not work. There may also be issues when invoking
such functions from templates when transliteration is present, due to the
need for the transliteration to be decomposed, as mentioned below (all strings
from Wiktionary pages are normally in composed form).

NOTE NOTE NOTE: All functions assume that transliteration (but not Russian)
has had its acute and grave accents decomposed using export.decompose().
This is the first thing that should be done to all user-specified
transliteration and any transliteration we compute that we expect to work with.
]]

local export = {}

local lang = require("languages").getByCode("ru")

local strutils = require("string utilities")
local m_table_tools = require("table tools")
-- Prevents an infinite require loop since ru-translit requires a different function in this module.
local m_ru_translit = require("utilities/require when needed")("Module:ru-translit")


local u = mw.ustring.char
local rfind = mw.ustring.find
local rsubn = mw.ustring.gsub
local ulen = mw.ustring.len
local rmatch = mw.ustring.match
local rsplit = mw.text.split
local toNFD = mw.ustring.toNFD
local ulower = mw.ustring.lower
local uupper = mw.ustring.upper
local usub = mw.ustring.sub

local AC = u(0x0301) -- acute =  ́
local GR = u(0x0300) -- grave =  ̀
local CFLEX = u(0x0302) -- circumflex =  ̂
local BREVE = u(0x0306) -- breve  ̆
local DIA = u(0x0308) -- diaeresis =  ̈
local CARON = u(0x030C) -- caron  ̌
local OGONEK = u(0x0328) -- ogonek  ̨

local PSEUDOVOWEL = u(0xFFF1) -- pseudovowel placeholder
local PSEUDOCONS = u(0xFFF2) -- pseudoconsonant placeholder

-- any accent
export.accent = AC .. GR .. DIA .. BREVE .. CARON .. OGONEK
-- regex for any optional accent(s)
export.opt_accent = "[" .. export.accent .. "]*"
-- any composed Cyrillic vowel with grave accent
export.composed_grave_vowel = "ѐЀѝЍ"
-- any Cyrillic vowel except ёЁ
export.vowel_no_jo = "аеиоуяэыюіѣѵАЕИОУЯЭЫЮІѢѴ" .. PSEUDOVOWEL .. export.composed_grave_vowel
-- any Cyrillic vowel, including ёЁ
export.vowel = export.vowel_no_jo .. "ёЁ"
-- any vowel in transliteration
export.tr_vowel = "aeěɛiouyAEĚƐIOUY" .. PSEUDOVOWEL
-- any consonant in transliteration, omitting soft/hard sign
export.tr_cons_no_sign = "bcčdfghjklmnpqrsštvwxzžBCČDFGHJKLMNPQRSŠTVWXZŽ" .. PSEUDOCONS
-- any consonant in transliteration, including soft/hard sign
export.tr_cons = export.tr_cons_no_sign .. "ʹʺ"
-- regex for any consonant in transliteration, including soft/hard sign,
-- optionally followed by any accent
export.tr_cons_acc_re = "[" .. export.tr_cons .. "]" .. export.opt_accent
-- any Cyrillic consonant except sibilants and ц
export.cons_except_sib_c = "бдфгйклмнпрствхзьъБДФГЙКЛМНПРСТВХЗЬЪ" .. PSEUDOCONS
-- Cyrillic sibilant consonants
export.sib = "шщчжШЩЧЖ"
-- Cyrillic sibilant consonants and ц
export.sib_c = export.sib .. "цЦ"
-- any Cyrillic consonant
export.cons = export.cons_except_sib_c .. export.sib_c
-- Cyrillic velar consonants
export.velar = "кгхКГХ"
-- uppercase Cyrillic consonants
export.uppercase = "АЕИОУЯЭЫЁЮІѢѴБДФГЙКЛМНПРСТВХЗЬЪШЩЧЖЦ"

-- version of rsubn() that discards all but the first return value
local function rsub(term, foo, bar)
	local retval = rsubn(term, foo, bar)
	return retval
end

local function ine(x)
	return x ~= "" and x or nil
end

-- this function enables the module to be called from a template;
-- FIXME, does this actually work?
function export.main(frame)
	-- FIXME: Not used. Consider deleting.
	if type(export[frame.args[1]]) == 'function' then
		return export[frame.args[1]](frame.args[2], frame.args[3])
	else
		return export[frame.args[1]][frame.args[2]]
	end
end

-- selects preposition о, об or обо for next phrase, which can start from
-- punctuation
function export.obo(phr)
	-- FIXME: Not used. Consider deleting.
	--Algorithm design is mainly inherited from w:ru:template:Обо
	local w = rmatch(phr,"[%p%s%c]*(.-)[%p%s%c]") or rmatch(phr,"[%p%s%c]*(.-)$")
	if not w then return nil end
	if string.find(" всей всём всех мне ",' '..ulower(w)..' ',1,true) then return 'обо' end
	local ws=usub(w,1,2)
	if ws==uupper(ws) then -- abbrev
		if rmatch(ws,"^[ЙУНФЫАРОЛЭСМИRYUIOASFHLXNMÖÜÄΑΕΟΥΩ]") then return 'об' else return 'о' end
	elseif rmatch(uupper(w),"^[АОЭИУЫAOIEÖÜÄΑΕΟΥΩ]") then
		return 'об'
	else
		return 'о'
	end
end

-- Apply Proto-Slavic iotation. This is the change that is affected by a
-- Slavic -j- after a consonant.
function export.iotation(stem, tr, shch)
	local combine_tr = false
	
	-- so this can be called from a template	
	if type(stem) == 'table' then
		stem, tr, shch = ine(stem.args[1]), ine(stem.args[2]), ine(stem.args[3])
		combine_tr = true
	end
	
	stem = rsub(stem, "[сх]$", "ш")
	stem = rsub(stem, "ск$", "щ")
	stem = rsub(stem, "ст$", "щ")
	stem = rsub(stem, "[кц]$", "ч")

	-- normally "т" is iotated as "ч" but there are many verbs that are iotated with "щ"
	if shch == "щ" then
		stem = rsub(stem, "т$", "щ")
	else
		stem = rsub(stem, "т$", "ч")
	end

	stem = rsub(stem, "[гдз]$", "ж")

	stem = rsub(stem, "([бвмпф])$", "%1л")

	if tr then
		tr = rsub(tr, "[sx]$", "š")
		tr = rsub(tr, "sk$", "šč")
		tr = rsub(tr, "st$", "šč")
		tr = rsub(tr, "[kc]$", "č")

		-- normally "т" is iotated as "ч" but there are many verbs that are iotated with "щ"
		if shch == "щ" then
			tr = rsub(tr, "t$", "šč")
		else
			tr = rsub(tr, "t$", "č")
		end

		tr = rsub(tr, "[gdz]$", "ž")

		tr = rsub(tr, "([bvmpf])$", "%1l")
	end

	if combine_tr then
		return export.combine_russian_tr(stem, tr)
	else
		return stem, tr
	end
end

-- Does a set of Cyrillic words in connected text need accents? We need to
-- split by word and check each one.
function export.needs_accents(text)
	local function word_needs_accents(word)
		-- A word needs accents if it is unstressed and contains more than
		-- one vowel, unless it's a prefix or suffix
		return not rfind(word, "^%-") and not rfind(word, "%-$") and
			export.is_unstressed(word) and not export.is_monosyllabic(word)
	end
	local words = rsplit(text, "%s")
	for _, word in ipairs(words) do
		if word_needs_accents(word) then
			return true
		end
	end
	return false
end

-- True if either:
-- (1) A vowel is marked with explicit primary stress.
-- (2) The word has a single jo in it (which doesn't have secondary stress).
-- This is because a word with multiple jos requires explicit stress to be
-- marked, since we can't infer where primary stress lies.
-- Jo can be ё, ѣ̈,  or я̈ (e.g. сѣ̈дла, plural of сѣдло́).
function export.is_stressed(word)
	if word:match(AC) then
		return true
	end
	word = toNFD(word)
	return (
		select(2, rsubn(word, "[еѣяЕѢЯ]" .. DIA, "")) == 1 and
		not rmatch(word, "[еѣяЕѢЯ]" .. DIA .. GR)
	)
end

-- True if a Cyrillic word requires explicit stress.
function export.is_unstressed(word)
	return not export.is_stressed(word)
end

-- True if Cyrillic word is stressed on the last syllable
function export.is_ending_stressed(word)
	return rfind(word, "[ёЁ][^" .. export.vowel .. "]*$") or
		rfind(word, "[" .. export.vowel .. "][́̈][^" .. export.vowel .. "]*$")
end

-- True if a Cyrillic word has two or more stresses (acute or diaeresis)
function export.is_multi_stressed(word)
	word = rsub(word, "[ёЁ]", "е́")
	return rfind(word, "[" .. export.vowel .. "][́̈].*[" .. export.vowel .. "][́̈]")
end

-- True if Cyrillic word is stressed on the first syllable
function export.is_beginning_stressed(word)
	return rfind(word, "^[^" .. export.vowel .. "]*[ёЁ]") or
		rfind(word, "^[^" .. export.vowel .. "]*[" .. export.vowel .. "]́")
end

-- True if Cyrillic word has no vowel. Don't treat suffixes as nonsyllabic
-- even if they have no vowel, as they are generally added onto words with
-- vowels.
function export.is_nonsyllabic(word)
	return not rfind(word, "^%-") and not rfind(word, "[" .. export.vowel .. "]")
end

-- True if Cyrillic word has no more than one vowel; includes non-syllabic
-- stems such as льд-
function export.is_monosyllabic(word)
	return not rfind(word, "[" .. export.vowel .. "].*[" .. export.vowel .. "]")
end

local recomposer = {
	-- Cyrillic letters
	["е" .. DIA] = "ё",
	["Е" .. DIA] = "Ё",
	["и" .. BREVE] = "й",
	["И" .. BREVE] = "Й",
	["і" .. DIA] = "ї",
	["І" .. DIA] = "Ї",
	-- Latin letters
	["c" .. CARON] = "č",
	["C" .. CARON] = "Č",
	["e" .. CARON] = "ě",
	["E" .. CARON] = "Ě",
	["o" .. CARON] = "ǒ",
	["O" .. CARON] = "Ǒ",
	["o" .. OGONEK] = "ǫ",
	["O" .. OGONEK] = "Ǫ",
	["s" .. CARON] = "š",
	["S" .. CARON] = "Š",
	["z" .. CARON] = "ž",
	["Z" .. CARON] = "Ž",
	-- used in ru-pron:
	["ж" .. BREVE] = "ӂ", -- used in ru-pron
	["Ж" .. BREVE] = "Ӂ",
	["j" .. CFLEX] = "ĵ",
	["J" .. CFLEX] = "Ĵ",
	["j" .. CARON] = "ǰ",
	-- no composed uppercase equivalent of J-caron
	["ʒ" .. CARON] = "ǯ",
	["Ʒ" .. CARON] = "Ǯ",
}

-- Decompose acute, grave, etc. on letters (esp. Latin) into individivual
-- character + combining accent. But recompose Cyrillic and Latin characters
-- that we want to treat as units and get caught in the crossfire. We mostly
-- want acute and grave decomposed; perhaps should just explicitly decompose
-- those and no others.
function export.decompose(text)
	text = toNFD(text)
	text = rsub(text, ".[" .. BREVE .. DIA .. CARON .. OGONEK .. "]", recomposer)
	return text
end

function export.assert_decomposed(text)
	assert(not rfind(text, "[áéíóúýàèìòùỳäëïöüÿÁÉÍÓÚÝÀÈÌÒÙỲÄËÏÖÜŸ]"))
end

-- Transliterate text and then apply acute/grave decomposition.
function export.translit(text, no_include_monosyllabic_jo_accent)
	local jo_accent = not no_include_monosyllabic_jo_accent and "mono" or nil
	return export.decompose(m_ru_translit.tr(text, nil, nil, jo_accent))
end

-- Recompose acutes and graves into preceding vowels. Probably not necessary.
function export.recompose(text)
	return mw.ustring.toNFC(text)
end

local grave_decomposer = {
	["ѐ"] = "е" .. GR,
	["Ѐ"] = "Е" .. GR,
	["ѝ"] = "и" .. GR,
	["Ѝ"] = "И" .. GR,
}

-- decompose precomposed Cyrillic chars w/grave accent; not necessary for
-- acute accent as there aren't precomposed Cyrillic chars w/acute accent,
-- and undesirable for precomposed ё and Ё
function export.decompose_grave(word)
	return rsub(word, "[ѐЀѝЍ]", grave_decomposer)
end

local grave_deaccenter = {
	[GR] = "", -- grave accent
	["ѐ"] = "е", -- composed Cyrillic chars w/grave accent
	["Ѐ"] = "Е",
	["ѝ"] = "и",
	["Ѝ"] = "И",
}

local deaccenter = mw.clone(grave_deaccenter)
deaccenter[AC] = "" -- acute accent

-- Remove acute and grave accents; don't affect composed diaeresis in ёЁ or
-- uncomposed diaeresis in -ѣ̈- (as in plural сѣ̈дла of сѣдло́).
-- NOTE: Translit must already be decomposed! See comment at top.
function export.remove_accents(word, tr)
	local ru_removed = rsub(word, "[́̀ѐЀѝЍ]", deaccenter)
	if not tr then
		return ru_removed, nil
	end
	return ru_removed, rsub(tr, "[" .. AC .. GR .. "]", deaccenter)
end

-- Remove grave accents; don't affect acute or composed diaeresis in ёЁ or
-- uncomposed diaeresis in -ѣ̈- (as in plural сѣ̈дла of сѣдло́).
-- NOTE: Translit must already be decomposed! See comment at top.
function export.remove_grave_accents(word, tr)
	local ru_removed = rsub(word, "[̀ѐЀѝЍ]", grave_deaccenter)
	if not tr then
		return ru_removed, nil
	end
	return ru_removed, rsub(tr, GR, "")
end

-- Remove acute and grave accents in monosyllabic words; don't affect
-- diaeresis (composed or uncomposed) because it indicates a change in vowel
-- quality, which still applies to monosyllabic words. Don't change suffixes,
-- where a "monosyllabic" stress is still significant (e.g. -ча́т short
-- masculine of -ча́тый, vs. -́чат short masculine of -́чатый).
-- NOTE: Translit must already be decomposed! See comment at top.
function export.remove_monosyllabic_accents(word, tr)
	if export.is_monosyllabic(word) and not rfind(word, "^%-") then
		return export.remove_accents(word, tr)
	else
		return word, tr
	end
end

local destresser = mw.clone(deaccenter)
destresser["ё"] = "е"
destresser["Ё"] = "Е"
destresser["̈"] = "" -- diaeresis

-- Subfunction of split_syllables(). On input we get sections of text
-- consisting of CONSONANT - VOWEL - CONSONANT - VOWEL ... - CONSONANT,
-- where CONSONANT consists of zero or more consonants and VOWEL consists
-- of exactly one vowel plus any following accent(s); we combine these into
-- syllables as required by split_syllables().
local function combine_captures(captures)
	if #captures == 1 then
		return captures
	end
	local combined = {}
	for i = 1,(#captures-1),2 do
		table.insert(combined, captures[i] .. captures[i+1])
	end
	combined[#combined] = combined[#combined] .. captures[#captures]
	return combined
end

-- Split Russian text and transliteration into syllables. Syllables end with
-- vowel + accent(s), except for the last syllable, which includes any
-- trailing consonants.
-- NOTE: Translit must already be decomposed! See comment at top.
function export.split_syllables(ru, tr)
	-- Split into alternating consonant/vowel sequences, as described in
	-- combine_captures(). Uses capturing_split(), which is like rsplit()
	-- but also includes any capturing groups in the split pattern.
	local rusyllables = combine_captures(strutils.capturing_split(ru, "([" .. export.vowel .. "]" .. export.opt_accent .. ")"))
	local trsyllables
	if tr then
		export.assert_decomposed(tr)
		trsyllables = combine_captures(strutils.capturing_split(tr, "([" .. export.tr_vowel .. "]" .. export.opt_accent .. ")"))
		if #rusyllables ~= #trsyllables then
			error("Russian " .. ru .. " doesn't have same number of syllables as translit " .. tr)
		end
	end
	--error(table.concat(rusyllables, "/") .. "(" .. #rusyllables .. (trsyllables and (") || " .. table.concat(trsyllables, "/") .. "(" .. #trsyllables .. ")") or ""))
	return rusyllables, trsyllables
end

-- Split Russian word and transliteration into hyphen-separated components.
-- Rejoining with table.concat(..., "-") will recover the original word.
-- If the original word ends in a hyphen, that hyphen gets included with the
-- preceding component (this is the only case when an individual component has
-- a hyphen in it).
function export.split_hyphens(ru, tr)
	local rucomponents = rsplit(ru, "%-")
	if rucomponents[#rucomponents] == "" and #rucomponents > 1 then
		rucomponents[#rucomponents - 1] = rucomponents[#rucomponents - 1] .. "-"
		table.remove(rucomponents)
	end
	local trcomponents
	if tr then
		trcomponents = rsplit(tr, "%-")
		if trcomponents[#trcomponents] == "" and #trcomponents > 1 then
			trcomponents[#trcomponents - 1] = trcomponents[#trcomponents - 1] .. "-"
			table.remove(trcomponents)
		end
		if #rucomponents ~= #trcomponents then
			error("Russian " .. ru .. " doesn't have same number of hyphenated components as translit " .. tr)
		end
	end
	return rucomponents, trcomponents
end

-- Apply j correction, converting je to e after consonants, jo to o after
-- a sibilant, ju to u after hard sibilant.
-- NOTE: Translit must already be decomposed! See comment at top.
function export.j_correction(tr)
	tr = rsub(tr, "([" .. export.tr_cons_no_sign .. "]" .. export.opt_accent ..")[Jj]([EeĚě])", "%1%2")
	tr = rsub(tr, "([žščŽŠČ])[Jj]([Oo])", "%1%2")
	tr = rsub(tr, "([žšŽŠ])[Jj]([Uu])", "%1%2")
	return tr
end

local function make_unstressed_ru(ru)
	-- The following regexp has grave+acute+diaeresis after the bracket
	--
	return rsub(ru, "[̀́̈ёЁѐЀѝЍ]", destresser)
end

-- Remove all stress marks (acute, grave, diaeresis).
-- NOTE: Translit must already be decomposed! See comment at top.
function export.make_unstressed(ru, tr)
	if not tr then
		return make_unstressed_ru(ru), nil
	end
	-- In the presence of TR, we need to do things the hard way: Splitting
	-- into syllables and only converting Latin o to e opposite a ё.
	rusyl, trsyl = export.split_syllables(ru, tr)
	for i=1,#rusyl do
		if rfind(rusyl[i], "[ёЁ]") then
			trsyl[i] = rsub(trsyl[i], "[Oo]", {["O"] = "E", ["o"] = "e"})
		end
		rusyl[i] = make_unstressed_ru(rusyl[i])
		-- the following should still work as it will affect accents only
		trsyl[i] = make_unstressed_ru(trsyl[i])
	end
	-- Also need to apply j correction as otherwise we'll have je after cons, etc.
	return table.concat(rusyl, ""),
		export.j_correction(table.concat(trsyl, ""))
end

local function remove_jo_ru(word)
	return rsub(word, "[̈ёЁ]", destresser)
end

-- Remove diaeresis stress marks only.
-- NOTE: Translit must already be decomposed! See comment at top.
function export.remove_jo(ru, tr)
	if not tr then
		return remove_jo_ru(ru), nil
	end
	-- In the presence of TR, we need to do things the hard way: Splitting
	-- into syllables and only converting Latin o to e opposite a ё.
	rusyl, trsyl = export.split_syllables(ru, tr)
	for i=1,#rusyl do
		if rfind(rusyl[i], "[ёЁ]") then
			trsyl[i] = rsub(trsyl[i], "[Oo]", {["O"] = "E", ["o"] = "e"})
		end
		rusyl[i] = remove_jo_ru(rusyl[i])
		-- the following should still work as it will affect accents only
		trsyl[i] = make_unstressed_once_ru(trsyl[i])
	end
	-- Also need to apply j correction as otherwise we'll have je after cons, etc.
	return table.concat(rusyl, ""),
		export.j_correction(table.concat(trsyl, ""))
end

local function make_unstressed_once_ru(word)
	-- leave graves alone
	return rsub(word, "([́̈ёЁ])([^́̈ёЁ]*)$", function(x, rest) return destresser[x] .. rest; end, 1)
end

local function map_last_hyphenated_component(fn, ru, tr)
	if rfind(ru, "%-") then
		-- If there is a hyphen, do it the hard way by splitting into
		-- individual components and doing the last one. Otherwise we just do
		-- the whole string.
		local rucomponents, trcomponents = export.split_hyphens(ru, tr)
		local lastru, lasttr = fn(rucomponents[#rucomponents],
			trcomponents and trcomponents[#trcomponents] or nil)
		rucomponents[#rucomponents] = lastru
		ru = table.concat(rucomponents, "-")
		if trcomponents then
			trcomponents[#trcomponents] = lasttr
			tr = table.concat(trcomponents, "-")
		end
		return ru, tr
	end
	return fn(ru, tr)
end

-- Make last stressed syllable (acute or diaeresis) unstressed; leave
-- unstressed; leave graves alone; if NOCONCAT, return individual syllables.
-- NOTE: Translit must already be decomposed! See comment at top.
local function make_unstressed_once_after_hyphen_split(ru, tr, noconcat)
	if not tr then
		return make_unstressed_once_ru(ru), nil
	end
	-- In the presence of TR, we need to do things the hard way, as with
	-- make_unstressed().
	rusyl, trsyl = export.split_syllables(ru, tr)
	for i=#rusyl,1,-1 do
		local stressed = export.is_stressed(rusyl[i])
		if stressed then
			if rfind(rusyl[i], "[ёЁ]") then
				trsyl[i] = rsub(trsyl[i], "[Oo]", {["O"] = "E", ["o"] = "e"})
			end
			rusyl[i] = make_unstressed_once_ru(rusyl[i])
			-- the following should still work as it will affect accents only
			trsyl[i] = make_unstressed_once_ru(trsyl[i])
			break
		end
	end
	if noconcat then
		return rusyl, trsyl
	end
	-- Also need to apply j correction as otherwise we'll have je after cons
	return table.concat(rusyl, ""),
		export.j_correction(table.concat(trsyl, ""))
end

-- Make last stressed syllable (acute or diaeresis) to the right of any hyphen
-- unstressed (unless the hyphen is word-final); leave graves alone. We don't
-- destress a syllable to the left of a hyphen unless the hyphen is word-final
-- (i.e. a prefix). Otherwise e.g. the accents in the first part of words like
-- ко́е-како́й and а́льфа-лу́ч won't remain.
-- NOTE: Translit must already be decomposed! See comment at top.
function export.make_unstressed_once(ru, tr)
	return map_last_hyphenated_component(make_unstressed_once_after_hyphen_split, ru, tr)
end

local function make_unstressed_once_at_beginning_ru(word)
	-- leave graves alone
	return rsub(word, "^([^́̈ёЁ]*)([́̈ёЁ])", function(rest, x) return rest .. destresser[x]; end, 1)
end

-- Make first stressed syllable (acute or diaeresis) unstressed; leave
-- graves alone; if NOCONCAT, return individual syllables.
-- NOTE: Translit must already be decomposed! See comment at top.
function export.make_unstressed_once_at_beginning(ru, tr, noconcat)
	if not tr then
		return make_unstressed_once_at_beginning_ru(ru), nil
	end
	-- In the presence of TR, we need to do things the hard way, as with
	-- make_unstressed().
	rusyl, trsyl = export.split_syllables(ru, tr)
	for i=1,#rusyl do
		local stressed = export.is_stressed(rusyl[i])
		if stressed then
			if rfind(rusyl[i], "[ёЁ]") then
				trsyl[i] = rsub(trsyl[i], "[Oo]", {["O"] = "E", ["o"] = "e"})
			end
			rusyl[i] = make_unstressed_once_at_beginning_ru(rusyl[i])
			-- the following should still work as it will affect accents only
			trsyl[i] = make_unstressed_once_at_beginning_ru(trsyl[i])
			break
		end
	end
	if noconcat then
		return rusyl, trsyl
	end
	-- Also need to apply j correction as otherwise we'll have je after cons
	return table.concat(rusyl, ""),
		export.j_correction(table.concat(trsyl, ""))
end

-- Subfunction of make_ending_stressed(), make_beginning_stressed(), which
-- add an acute accent to a syllable that may already have a grave accent;
-- in such a case, remove the grave.
-- NOTE: Translit must already be decomposed! See comment at top.
function export.correct_grave_acute_clash(word, tr)
	word = rsub(word, "([̀ѐЀѝЍ])́", function(x) return grave_deaccenter[x] .. AC; end)
	word = rsub(word, AC .. GR, AC)
	if not tr then
		return word, nil
	end
	tr = rsub(tr, GR .. AC, AC)
	tr = rsub(tr, AC .. GR, AC)
	return word, tr
end

local function make_ending_stressed_ru(word)
	-- If already ending stressed, just return word so we don't mess up ё
	if export.is_ending_stressed(word) then
		return word
	end
	-- Destress the last stressed syllable
	word = make_unstressed_once_ru(word)
	-- Add an acute to the last syllable
	word = rsub(word, "([" .. export.vowel_no_jo .. "])([^" .. export.vowel .. "]*)$",
		"%1́%2")
	-- If that caused an acute and grave next to each other, remove the grave
	return export.correct_grave_acute_clash(word)
end

-- Remove the last primary stress from the word and put it on the final
-- syllable. Leave grave accents alone except in the last syllable.
-- If final syllable already has primary stress, do nothing.
-- NOTE: Translit must already be decomposed! See comment at top.
local function make_ending_stressed_after_hyphen_split(ru, tr)
	if not tr then
		return make_ending_stressed_ru(ru), nil
	end
	-- If already ending stressed, just return ru/tr so we don't mess up ё
	if export.is_ending_stressed(ru) then
		return ru, tr
	end
	-- Destress the last stressed syllable; pass in "noconcat" so we get
	-- the individual syllables back
	rusyl, trsyl = make_unstressed_once_after_hyphen_split(ru, tr, "noconcat")
	-- Add an acute to the last syllable of both Russian and translit
	rusyl[#rusyl] = rsub(rusyl[#rusyl], "([" .. export.vowel_no_jo .. "])",
		"%1" .. AC)
	trsyl[#trsyl] = rsub(trsyl[#trsyl], "([" .. export.tr_vowel .. "])",
		"%1" .. AC)
	-- If that caused an acute and grave next to each other, remove the grave
	rusyl[#rusyl], trsyl[#trsyl] =
		export.correct_grave_acute_clash(rusyl[#rusyl], trsyl[#trsyl])
	-- j correction didn't get applied in make_unstressed_once because
	-- we short-circuited it and made it return lists of syllables
	return table.concat(rusyl, ""),
		export.j_correction(table.concat(trsyl, ""))
end

-- Remove the last primary stress from the portion of the word to the right of
-- any hyphen (unless the hyphen is word-final) and put it on the final
-- syllable. Leave grave accents alone except in the last syllable. If final
-- syllable already has primary stress, do nothing. (See make_unstressed_once()
-- for why we don't affect stresses to the left of a hyphen.)
-- NOTE: Translit must already be decomposed! See comment at top.
function export.make_ending_stressed(ru, tr)
	return map_last_hyphenated_component(make_ending_stressed_after_hyphen_split, ru, tr)
end

local function make_beginning_stressed_ru(word)
	-- If already beginning stressed, just return word so we don't mess up ё
	if export.is_beginning_stressed(word) then
		return word
	end
	-- Destress the first stressed syllable
	word = make_unstressed_once_at_beginning_ru(word)
	-- Add an acute to the first syllable
	word = rsub(word, "^([^" .. export.vowel .. "]*)([" .. export.vowel_no_jo .. "])",
		"%1%2́")
	-- If that caused an acute and grave next to each other, remove the grave
	return export.correct_grave_acute_clash(word)
end

-- Remove the first primary stress from the word and put it on the initial
-- syllable. Leave grave accents alone except in the first syllable.
-- If initial syllable already has primary stress, do nothing.
-- NOTE: Translit must already be decomposed! See comment at top.
function export.make_beginning_stressed(ru, tr)
	if not tr then
		return make_beginning_stressed_ru(ru), nil
	end
	-- If already beginning stressed, just return ru/tr so we don't mess up ё
	if export.is_beginning_stressed(ru) then
		return ru, tr
	end
	-- Destress the first stressed syllable; pass in "noconcat" so we get
	-- the individual syllables back
	rusyl, trsyl = export.make_unstressed_once_at_beginning(ru, tr, "noconcat")
	-- Add an acute to the first syllable of both Russian and translit
	rusyl[1] = rsub(rusyl[1], "([" .. export.vowel_no_jo .. "])",
		"%1" .. AC)
	trsyl[1] = rsub(trsyl[1], "([" .. export.tr_vowel .. "])",
		"%1" .. AC)
	-- If that caused an acute and grave next to each other, remove the grave
	rusyl[1], trsyl[1] = export.correct_grave_acute_clash(rusyl[1], trsyl[1])
	-- j correction didn't get applied in make_unstressed_once_at_beginning
	-- because we short-circuited it and made it return lists of syllables
	return table.concat(rusyl, ""),
		export.j_correction(table.concat(trsyl, ""))
end

-- used for tracking and categorization
local trailing_letter_type = {
	["ш"] = {"sibilant", "cons"},
	["щ"] = {"sibilant", "cons"},
	["ч"] = {"sibilant", "cons"},
	["ж"] = {"sibilant", "cons"},
	["ц"] = {"c", "cons"},
	["к"] = {"velar", "cons"},
	["г"] = {"velar", "cons"},
	["х"] = {"velar", "cons"},
	["ь"] = {"soft-cons", "cons"},
	["ъ"] = {"hard-cons", "cons"},
	["й"] = {"palatal", "cons"},
	["а"] = {"vowel", "hard-vowel"},
	["я"] = {"vowel", "soft-vowel"},
	["э"] = {"vowel", "hard-vowel"},
	["е"] = {"vowel", "soft-vowel"},
	["ѣ"] = {"vowel", "soft-vowel"},
	["и"] = {"i", "vowel", "soft-vowel"},
	["і"] = {"i", "vowel", "soft-vowel"},
	["ѵ"] = {"i", "vowel", "soft-vowel"},
	["ы"] = {"vowel", "hard-vowel"},
	["о"] = {"vowel", "hard-vowel"},
	["ё"] = {"vowel", "soft-vowel"},
	["у"] = {"vowel", "hard-vowel"},
	["ю"] = {"vowel", "soft-vowel"},
}

function export.get_stem_trailing_letter_type(stem)
	local hint = ulower(usub(export.remove_accents(stem), -1))
	local hint_types = trailing_letter_type[hint] or {"hard-cons", "cons"}
	return hint_types
end

-- Reduce stem by eliminating the "epenthetic" vowel. Applies to
-- nominative singular masculine 2nd-declension hard and soft, and
-- 3rd-declension feminine in -ь (e.g. любовь). STEM should be the
-- result after calling detect_stem_type(), but with final -й if
-- present. Normally returns two arguments (STEM and TR), but can be
-- called from a template using #invoke and will return one argument
-- (STEM, or STEM//TR if TR is present). Returns nil if unable to
-- reduce.
-- NOTE: Translit must already be decomposed! See comment at top.
function export.reduce_stem(stem, tr, soft_n)
	local pre, letter, post
	local pretr, lettertr, posttr
	local combine_tr = false

	-- test cases with translit:
	-- =p.reduce_stem("фе́ез", "fɛ́jez") -> фе́йз, fɛ́jz
	-- =p.reduce_stem("фе́йез", "fɛ́jez") -> фе́йз, fɛ́jz
	-- =p.reduce_stem("фе́без", "fɛ́bez") -> фе́бз, fɛ́bz
	-- =p.reduce_stem("фе́лез", "fɛ́lez") -> фе́льз, fɛ́lʹz
	-- =p.reduce_stem("феёз", p.decompose("fɛjóz")) -> фейз, fɛjz
	-- =p.reduce_stem("фейёз", p.decompose("fɛjjóz")) -> фейз, fɛjz
	-- =p.reduce_stem("фебёз", p.decompose("fɛbjóz")) -> фебз, fɛbz
	-- =p.reduce_stem("фелёз", p.decompose("fɛljóz")) -> фельз, fɛlʹz
	-- =p.reduce_stem("фе́бей", "fɛ́bej") -> фе́бь, fɛ́bʹ
	-- =p.reduce_stem("фебёй", p.decompose("fɛbjój")) -> фебь, fɛbʹ
	-- =p.reduce_stem("фе́ей", "fɛ́jej") -> фе́йй, fɛ́jj
	-- =p.reduce_stem("феёй", p.decompose("fɛjój")) -> фейй, fɛjj

	-- so this can be called from a template	
	if type(stem) == 'table' then
		stem, tr = ine(stem.args[1]), ine(stem.args[2])
		combine_tr = true
	end

	pre, letter, post = rmatch(stem, "^(.*)([оОеЕёЁ])́?([" .. export.cons .. "]+)$")
	if not pre then
		return nil, nil
	end
	if tr then
		-- FIXME, may not be necessary to write the posttr portion as a
		-- consonant + zero or more consonant/accent combinations -- when will
		-- we ever get an accent after a consonant? That would indicate a
		-- failure of the decompose mechanism.
		pretr, lettertr, posttr = rmatch(tr, "^(.*)([oOeE])́?([" .. export.tr_cons .. "][" .. export.tr_cons .. export.accent .. "]*)$")
		if not pretr then
			return nil, nil -- should not happen unless tr is really messed up
		end
		-- Remove any trailing j's on the translit stem which don't have a
		-- corresponding й on the Cyrillic stem. This avoids excess j's with
		-- cases like индонези́ец//indonɛzíjec, but retains multiple j's  where
		-- necessary.
		pretr = rsub(pretr, "[jJ]+$", function(m)
			return usub(m, 1, ulen(rmatch(pre, "[йЙ]*$")))
		end)
	end
	if letter == "О" or letter == "о" then
		-- FIXME, what about when the accent is on the removed letter?
		if post == "й" or post == "Й" then
			-- FIXME, is this correct?
			return nil, nil
		end
		letter = ""
	else
		local is_upper = rfind(post, "[" .. export.uppercase .. "]")
		if rfind(pre, "[" .. export.vowel .. "]́?$") then
			letter = is_upper and "Й" or "й"
		elseif post == "й" or post == "Й" then
			letter = is_upper and "Ь" or "ь"
			post = ""
			if posttr then
				posttr = ""
			end
		elseif rfind(post, "[" .. export.velar .. "]$") and rfind(pre, "[" .. export.cons_except_sib_c .. "]$") or
			rfind(post, "[^йЙ" .. export.velar .. "]$") and rfind(pre, "[лЛ]$") or
			soft_n and rfind(pre, "[нН]$") then
			letter = is_upper and "Ь" or "ь"
		else
			letter = ""
		end
	end
	stem = pre .. letter .. post
	if tr then
		tr = pretr .. export.translit(letter) .. posttr
	end
	if combine_tr then
		return export.combine_russian_tr(stem, tr)
	else
		return stem, tr
	end
end

-- Generate the dereduced stem given STEM and EPENTHETIC_STRESS (which
-- indicates whether the epenthetic vowel should be stressed); this is
-- without any terminating non-syllabic ending, which is added if needed by
-- the calling function. Normally returns two arguments (STEM and TR), but
-- can be called from a template using #invoke and will return one argument
-- (STEM, or STEM//TR if TR is present). Returns nil if unable to dereduce.
-- NOTE: Translit must already be decomposed! See comment at top.
function export.dereduce_stem(stem, tr, epenthetic_stress)
	local combine_tr = false
	
	-- so this can be called from a template	
	if type(stem) == 'table' then
		stem, tr, epenthetic_stress = ine(stem.args[1]), ine(stem.args[2]), ine(stem.args[3])
		combine_tr = true
	end

	if epenthetic_stress then
		stem, tr = export.make_unstressed_once(stem, tr)
	end

	local pre, letter, post
	local pretr, lettertr, posttr
	-- FIXME!!! Deal with this special case
	--if not (z.stem_type == 'soft' and _.equals(z.stress_type, {'b', 'f'}) -- we should ignore asterix for 2*b and 2*f (so to process it just like 2b or 2f)
	--		 or _.contains(z.specific, '(2)') and _.equals(z.stem_type, {'velar', 'letter-ц', 'vowel'}))  -- and also the same for (2)-specific and 3,5,6 stem-types
	--then

	-- I think this corresponds to our -ья and -ье types, which we
	-- handle separately
	--if z.stem_type == 'vowel' then  -- 1).
	--	if _.equals(z.stress_type, {'b', 'c', 'e', 'f', "f'", "b'" }) then  -- gen_pl ending stressed  -- TODO: special vars for that
	--		z.stems['gen_pl'] = _.replace(z.stems['gen_pl'], 'ь$', 'е́')
	--	else
	--		z.stems['gen_pl'] = _.replace(z.stems['gen_pl'], 'ь$', 'и')
	--	end
	--end

	pre, letter, post = rmatch(stem, "^(.*)([" .. export.cons .. "])([" .. export.cons .. "])$")
	if tr then
		pretr, lettertr, posttr = rmatch(tr, "^(.*)(" .. export.tr_cons_acc_re .. ")(" .. export.tr_cons_acc_re .. ")$")
		if pre and not pretr then
			return nil, nil -- should not happen unless tr is really messed up
		end
	end
	if pre then
		local is_upper = rfind(post, "[" .. export.uppercase .. "]")
		local epvowel
		if rfind(letter, "[ьйЬЙ]") then
			letter = ""
			lettertr = ""
			if rfind(post, "[цЦ]$") or not epenthetic_stress then
				epvowel = is_upper and "Е" or "е"
			else
				epvowel = is_upper and "Ё" or "ё"
			end
		elseif rfind(letter, "[" .. export.cons_except_sib_c .. "]") and rfind(post, "[" .. export.velar .. "]") or
				rfind(letter, "[" .. export.velar .. "]") then
			epvowel = is_upper and "О" or "о"
		elseif post == "ц" or post == "Ц" then
			epvowel = is_upper and "Е" or "е"
		elseif epenthetic_stress then
			if rfind(letter, "[" .. export.sib .. "]") then
				epvowel = is_upper and "О́" or "о́"
			else
				epvowel = is_upper and "Ё" or "ё"
			end
		else
			epvowel = is_upper and "Е" or "е"
		end
		assert(epvowel)
		stem = pre .. letter .. epvowel .. post
		if tr then
			tr = pretr .. lettertr .. export.translit(epvowel) .. posttr
			tr = export.j_correction(tr)
		end

		if epenthetic_stress then
			stem, tr = export.make_ending_stressed(stem, tr)
		end
		if combine_tr then
			return export.combine_russian_tr(stem, tr)
		else
			return stem, tr
		end
	end
	return nil, nil
end

-- Parse an entry that potentially has final footnote symbols and initial *
-- for a hypothetical entry into initial symbols, text and final symbols.
function export.split_symbols(entry, do_subscript)
	local prefentry, finalnotes = m_table_tools.separate_notes(entry)
	local initnotes, text = rmatch(prefentry, "(%*?)(.*)$")
	return initnotes, text, finalnotes
end

--------------------------------------------------------------------------
--                        Used for manual translit                      --
--------------------------------------------------------------------------

function export.translit_no_links(text)
	return export.translit(require("links").remove_links(text))
end

function export.split_russian_tr(term, dopair)
	local ru, tr
	if not rfind(term, "//") then
		ru = term
	else
		splitvals = rsplit(term, "//")
		if #splitvals ~= 2 then
			error("Must have at most one // in a Russian//translit expr: '" .. term .. "'")
		end
		ru, tr = splitvals[1], export.decompose(splitvals[2])
	end
	if dopair then
		return {ru, tr}
	else
		return ru, tr
	end
end

function export.combine_russian_tr(ru, tr)
	if type(ru) == "table" then
		ru, tr = unpack(ru)
	end
	if tr then
		return ru .. "//" .. tr
	else
		return ru
	end
end

local function concat_maybe_moving_notes(x, y, movenotes)
	if movenotes then
		local xentry, xnotes = m_table_tools.separate_notes(x)
		local yentry, ynotes = m_table_tools.separate_notes(y)
		return xentry .. yentry .. xnotes .. ynotes
	else
		return x .. y
	end
end

-- Concatenate two Russian strings RU1 and RU2 that may have corresponding
-- manual transliteration TR1 and TR2 (which should be nil if there is no
-- manual translit). If DOPAIR, return a two-item list of the combined
-- Russian and manual translit (which will be nil if both TR1 and TR2 are
-- nil); else, return two values, the combined Russian and manual translit.
-- If MOVENOTES, extract any footnote symbols at the end of RU1 and move
-- them to the end of the concatenated string, before any footnote symbols
-- for RU2; same thing goes for TR1 and TR2.
function export.concat_russian_tr(ru1, tr1, ru2, tr2, dopair, movenotes)
	local ru, tr
	if not tr1 and not tr2 then
		ru = concat_maybe_moving_notes(ru1, ru2, movenotes)
	else
		if not tr1 then
			tr1 = export.translit_no_links(ru1)
		end
		if not tr2 then
			tr2 = export.translit_no_links(ru2)
		end
		ru, tr = concat_maybe_moving_notes(ru1, ru2, movenotes), export.j_correction(concat_maybe_moving_notes(tr1, tr2, movenotes))
	end
	if dopair then
		return {ru, tr}
	else
		return ru, tr
	end
end

-- Concatenate two Russian/translit combinations (where each combination is
-- a two-element list of {RUSSIAN, TRANSLIT} where TRANSLIT may be nil) by
-- individually concatenating the Russian and translit portions, and return
-- a concatenated combination as a two-element list. If the manual translit
-- portions of both terms on entry are nil, the result will also have nil
-- manual translit. If MOVENOTES, extract any footnote symbols at the end
-- of TERM1 and move them after the concatenated string and before any
-- footnote symbols at the end of TERM2.
function export.concat_paired_russian_tr(term1, term2, movenotes)
	assert(type(term1) == "table")
	assert(type(term2) == "table")
	local ru1, tr1 = term1[1], term1[2]
	local ru2, tr2 = term2[1], term2[2]
	return export.concat_russian_tr(ru1, tr1, ru2, tr2, "dopair", movenotes)
end

function export.concat_forms(forms)
	local joined_rutr = {}
	for _, form in ipairs(forms) do
		table.insert(joined_rutr, export.combine_russian_tr(form))
	end
	return table.concat(joined_rutr, ",")
end

-- Given a list of forms, where each form is a two-element list of {RUSSIAN, TRANSLIT}, strip footnote symbols from the
-- end of the Russian and translit.
function export.strip_notes_from_forms(forms)
	local newforms = {}
	for _, form in ipairs(forms) do
		local ru, tr = form[1], form[2]
		ru, _ = m_table_tools.separate_notes(ru)
		if tr then
			tr, _ = m_table_tools.separate_notes(tr)
		end
		table.insert(newforms, {ru, tr})
	end
	return newforms
end

-- Given a list of forms, where each form is a two-element list of {RUSSIAN, TRANSLIT}, unzip into parallel lists of
-- Russian and translit. The latter list may have gaps in it.
function export.unzip_forms(forms)
	local rulist = {}
	local trlist = {}
	for i, form in ipairs(forms) do
		local ru, tr = form[1], form[2]
		rulist[i] = ru
		trlist[i] = tr
	end
	return rulist, trlist
end

-- Given parallel lists of Russian and translit (where the latter list may have gaps in it), return a list of forms,
-- where each form is a two-element list of {RUSSIAN, TRANSLIT}.
function export.zip_forms(rulist, trlist)
	local forms = {}
	for i, ru in ipairs(rulist) do
		table.insert(forms, {ru, trlist[i]})
	end
	return forms
end

local function any_forms_have_translit(forms)
	for _, form in ipairs(forms) do
		if form[2] then
			return true
		end
	end
	return false
end

-- Given a list of forms, where each form is a two-element list of {RUSSIAN, TRANSLIT}, combine forms with
-- identical Russian, concatenating the translit with a comma in between.
function export.combine_translit_of_duplicate_forms(forms)
	if #forms == 0 then
		return forms
	end

	-- Optimization to avoid creating a new list in the majority case when no translit exists.
	if not any_forms_have_translit(forms) then
		return forms
	end

	local newforms = {}
	table.insert(newforms, {forms[1][1], forms[1][2]})
	for i = 2, #forms do
		local found_duplicate = false
		for j = 1, #newforms do
			-- If the Russian of the next form is the same as that of the last one, combine their translits and modify
			-- newforms[] in-place. Otherwise add the next form to newforms[]. Make sure to clone the form rather than
			-- just appending it directly since we may modify it in-place; we don't want to side-effect `forms` as passed
			-- in.
			if forms[i][1] == newforms[j][1] then
				local tr1 = newforms[j][2]
				local tr2 = forms[i][2]
				if not tr1 and not tr2 then
					-- this shouldn't normally happen
				else
					tr1 = tr1 or export.translit_no_links(newforms[j][1])
					tr2 = tr2 or export.translit_no_links(forms[i][1])
					if tr1 == tr2 then
						-- this shouldn't normally happen
					else
						newforms[j][2] = tr1 .. ", " .. tr2
					end
				end
				found_duplicate = true
				break
			end
		end
		if not found_duplicate then
			table.insert(newforms, {forms[i][1], forms[i][2]})
		end
	end
	return newforms
end

-- Given a list of forms, where each form is a two-element list of {RUSSIAN, TRANSLIT}, split cases where two different
-- transliterations have been packed into a single translit field by creating two adjacent term/translit pairs. This is
-- the opposite operation of combine_translit_of_duplicate_forms().
function export.split_translit_of_duplicate_forms(forms)
	if #forms == 0 then
		return forms
	end

	-- Optimization to avoid creating a new list in the majority case when no translit exists.
	if not any_forms_have_translit(forms) then
		return forms
	end

	local newforms = {}
	for _, form in ipairs(forms) do
		local ru, tr = unpack(form)
		if not tr or not tr:find(",") or ru:find(",") then
			table.insert(newforms, form)
		else
			local split_trs = rsplit(tr, ",%s*")
			local default_tr = export.translit_no_links(ru)
			for _, split_tr in ipairs(split_trs) do
				if split_tr == default_tr then
					split_tr = nil
				end
				table.insert(newforms, {ru, split_tr})
			end
		end
	end
	return newforms
end

function export.strip_ending(ru, tr, ending)
	local strippedru = rsub(ru, ending .. "$", "")
	if strippedru == ru then
		error("Argument " .. ru .. " doesn't end with expected ending " .. ending)
	end
	ru = strippedru
	tr = export.strip_tr_ending(tr, ending)
	return ru, tr
end

function export.strip_tr_ending(tr, ending)
	if not tr then return nil end
	local endingtr = rsub(export.translit_no_links(ending), "^([Jj])", "%1?")
	local strippedtr = rsub(tr, endingtr .. "$", "")
	if strippedtr == tr then
		error("Translit " .. tr .. " doesn't end with expected ending " .. endingtr)
	end
	return strippedtr
end

return export