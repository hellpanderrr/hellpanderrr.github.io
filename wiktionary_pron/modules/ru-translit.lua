local export = {}

--[=[

FIXME:

1. (DONE) If you write '''Б'''ез, it transliterates to '''B'''jez instead of
   '''B'''ez, as it should.
   -- NOTE: This currently doesn't work due to an issue in [[Module:languages]]
   -- which means this module won't see style apostrophes.
2. (DONE) Convert ъ to nothing before comma or other non-letter particle, e.g.
   in Однимъ словомъ, идешь на чтеніе.
3. (DONE) Make special-casing for adjectives in -го and for что (and friends)
    be the default, and implement transformations in Cyrillic rather than after
    translit so that we can display the transformed Cyrillic in the
    "phonetic respelling" notation of {{ru-IPA}}.
]=]
local u = mw.ustring.char
local explode = require("string utilities").explode_utf8
local concat = table.concat
local insert = table.insert
local remove = table.remove
local rfind = mw.ustring.find
local rsub = mw.ustring.gsub
local rsplit = mw.text.split
local toNFC = mw.ustring.toNFC
local toNFD = mw.ustring.toNFD
local decompose = require("ru-common").decompose

local UTF8 = "[%z\1-\127\194-\244][\128-\191]*"
local AC = u(0x301) -- acute = ́
local GR = u(0x0300) -- grave = ̀
local BR = u(0x0306) -- breve ̆
local DI = u(0x0308) -- diaeresis = ̈
local DIACRITICS = AC .. GR .. BR .. DI ..
	u(0x0302) .. -- circumflex ̂
	u(0x0304) .. -- macron ̄
	u(0x0307) .. -- dot above ̇
	u(0x030A) .. -- ring above ̊
	u(0x030C) .. -- caron ̌
	u(0x030F) .. -- double grave ̏
	u(0x0323) .. -- dot below ̣
	u(0x0328)    -- ogonek ̨
local TEMP_G = u(0xFFF1) -- substitute to preserve g from changing to v
local word_chars = "%a’%(%)%[%]" .. DIACRITICS

local function ine(x) -- if not empty
	if x == "" then return nil else return x end
end

-- Main letter conversion table.
local letters = {
	["а"] = "a", ["б"] = "b", ["в"] = "v", ["г"] = "g", ["д"] = "d", ["е"] = "je", ["ж"] = "ž", ["з"] = "z", ["и"] = "i", ["й"] = "j", ["к"] = "k", ["л"] = "l", ["м"] = "m", ["н"] = "n", ["о"] = "o", ["п"] = "p", ["р"] = "r", ["с"] = "s", ["т"] = "t", ["у"] = "u", ["ф"] = "f", ["х"] = "x", ["ц"] = "c", ["ч"] = "č", ["ш"] = "š", ["щ"] = "šč", ["ъ"] = "ʺ", ["ы"] = "y", ["ь"] = "ʹ", ["э"] = "e", ["ю"] = "ju", ["я"] = "ja",
	["А"] = "A", ["Б"] = "B", ["В"] = "V", ["Г"] = "G", ["Д"] = "D", ["Е"] = "Je", ["Ж"] = "Ž", ["З"] = "Z", ["И"] = "I", ["Й"] = "J", ["К"] = "K", ["Л"] = "L", ["М"] = "M", ["Н"] = "N", ["О"] = "O", ["П"] = "P", ["Р"] = "R", ["С"] = "S", ["Т"] = "T", ["У"] = "U", ["Ф"] = "F", ["Х"] = "X", ["Ц"] = "C", ["Ч"] = "Č", ["Ш"] = "Š", ["Щ"] = "Šč", ["Ъ"] = "ʺ", ["Ы"] = "Y", ["Ь"] = "ʹ", ["Э"] = "E", ["Ю"] = "Ju", ["Я"] = "Ja",
	-- Russian style quotes
	["«"] = "“", ["»"] = "”",
	-- archaic, pre-1918 letters
	["і"] = "i", ["ѳ"] = "f", ["ѣ"] = "jě", ["ѵ"] = "i",
	["І"] = "I", ["Ѳ"] = "F", ["Ѣ"] = "Jě", ["Ѵ"] = "I",
	-- archaic, pre-1708 letters (most of these are covered by aliases below)
	["ѥ"] = "je", ["ѯ"] = "ks", ["ѱ"] = "ps",
	["Ѥ"] = "Je", ["Ѯ"] = "Ks", ["Ѱ"] = "Ps",
}

-- Treat most archaic letters as aliases. Exceptions:
-- ѥ is not the same as е, because it doesn't lose iotation after a consonant.
-- ѯ and ѱ can't be treated as aliases, because mapping 1 character to 2 messes
-- can cause the logic which checks the capitalization of adjacent letters to
-- become unreliable. This only affects the uppercase forms, but the lowercase
-- forms are also excepted for consistency.
local aliases = {
	["є"] = "е", ["ꙁ"] = "з", ["ꙃ"] = "з", ["ѕ"] = "з", ["ї"] = "і", ["ꙋ"] = "у", ["ѡ"] = "о", ["ѿ"] = "о", ["ꙑ"] = "ы", ["ꙗ"] = "я", ["ѧ"] = "я", ["ѫ"] = "у", ["ѩ"] = "я", ["ѭ"] = "ю",
	["Є"] = "Е", ["Ꙁ"] = "З", ["Ꙃ"] = "З", ["Ѕ"] = "З", ["Ї"] = "І", ["Ꙋ"] = "У", ["Ѡ"] = "О", ["Ѿ"] = "О", ["Ꙑ"] = "Ы", ["Ꙗ"] = "Я", ["Ѧ"] = "Я", ["Ѫ"] = "У", ["Ѩ"] = "Я", ["Ѭ"] = "Ю", ["'"] = "’"
}

local plain_e = {
	["е"] = "e", ["ѣ"] = "ě", ["э"] = "ɛ",
	["Е"] = "E", ["Ѣ"] = "Ě", ["Э"] = "Ɛ"
}

local jo_letters = {
	["ё"] = "jo", ["ѣ̈"] = "jǒ", ["я̈"] = "jǫ",
	["Ё"] = "Jo", ["Ѣ̈"] = "Jǒ", ["Я̈"] = "Jǫ"
}

local vowels = "аеиіоуыѣэюяѥѵaæɐeəɛiɪɨoɵuyʊʉАЕИІОУЫѢЭЮЯѤѴAEƐIOUY"

-- Apply transformations to the Cyrillic to more closely match pronunciation.
-- Return two arguments: the "original" text (after decomposing composed
-- grave characters), and the transformed text. If the two are different,
-- {{ru-IPA}} should display a "phonetic respelling" notation. 
-- NOADJ disables special-casing for adjectives in -го, while FORCEADJ forces
-- special-casing for adjectives, including those in -аго (pre-reform spelling)
-- and disables checking for exceptions (e.g. много, ого). NOSHTO disables
-- special-casing for что and related words.
function export.apply_tr_fixes(text, noadj, noshto, forceadj)
	-- normalize any aliases
	text = text:gsub(UTF8, aliases)
	-- decompose stress accents without decomposing letters we want to treat
	-- as units (e.g. й or ё)
	text = decompose(text)

	local origtext = text
	-- the second half of the if-statement below is an optimization; see above.
	if not noadj and text:find("го") then
		local v = {["г"] = "в", ["Г"] = "В"}
		local repl = function(e, g, o, sja) return e .. v[g] .. o .. (sja or "") end
		-- Handle какого-нибудь/-либо/-то; must be done first because of an exception
		-- made for бого-, снего-, etc.
		text = rsub(text, "([кКтТ][аА][кК][оеОЕ" .. (forceadj and "аА" or "") .. "][" .. AC .. GR .. "]?)([гГ])([оО]%-)", repl)
		if not forceadj then
			local function go(text, case)
				local pattern = rsub(case, "^(.)(.*)(го[" .. AC .. GR .. "]?)(%-?)$", function(m1, m2, m3, m4)
					m1 = "%f[%a" .. AC .. GR .. "]([" .. uupper(m1) .. m1 .. "]"
					m2 = m2:gsub("\204[\128\129]", "[" .. AC .. GR .. "]?") .. ")"
					m3 = m3:gsub("\204[\128\129]", "[" .. AC .. GR .. "]?")
						:gsub("^г(.*)", "г(%1")
					m4 = m4 == "-" and "%-)" or ")%f[^%a" .. AC .. GR .. "]"
					return m1 .. m2 .. m3 .. m4
				end)
				return rsub(text, pattern, "%1" .. TEMP_G .. "%2")
			end
			for _, case in ipairs{"мно́го", "н[еа]мно́го", "до́рого", "недо́рого", "стро́го", "нестро́го", "на́строго", "убо́го", "пол[ао]́го"} do
				text = go(text, case)
			end
			-- check for neuter short forms of compound adjectives in -но́гий
			if rfind(text, "но[" .. AC .. GR .. "]?го%f[^%a" .. AC .. GR .. "]") then
				for _, case in ipairs{"безно́го", "босоно́го", "веслоно́го", "длинноно́го", "двуно́го", "коротконо́го", "кривоно́го", "одноно́го", "пятино́го", "трёхно́го", "трехно́го", "хромоно́го", "четвероно́го", "шестино́го"} do
					text = go(text, case)
				end
			end
			for _, case in ipairs{"ого́", "го́го", "ваго́го", "ло́го", "п[ео]́го", "со́го", "То́го", "ле́го", "игого́", "огого́", "альбиньязего", "д[иі]е́го", "бо́лого", "гр[иі]е́го", "манче́го", "пичис[иі]е́го", "тенкодого", "хио́го", "аго-", "его-", "ого-"} do
				text = go(text, case)
			end
		end
		--handle genitive/accusative endings, which are spelled -ого/-его/-аго
		-- (-ogo/-ego/-ago) but transliterated -ovo/-evo/-avo; only for adjectives
		-- and pronouns, excluding words like много, ого (-аго occurs in
		-- pre-reform spelling); \204\129 is an acute accent, \204\128 is a grave accent
		local pattern = "([оеОЕ" .. (forceadj and "аА" or "") .. "][" .. AC .. GR .. "]?)([гГ])([оО][" .. AC .. GR .. "]?)"
		local reflexive = "([сС][яЯ][" .. AC .. GR .. "]?)"
		text = rsub(text, pattern .. "%f[^%a" .. AC .. GR .. TEMP_G .. "]", repl)
		text = rsub(text, pattern .. reflexive .. "%f[^%a" .. AC .. GR .. TEMP_G .. "]", repl)
		-- handle сегодня
		text = rsub(text, "%f[%a" .. AC .. GR .. "]([Сс]е)г(о[" .. AC .. GR .. "]?дня)%f[^%a" .. AC .. GR .. "]", "%1в%2")
		-- handle сегодняшн-
		text = rsub(text, "%f[%a" .. AC .. GR .. "]([Сс]е)г(о[" .. AC .. GR .. "]?дняшн)", "%1в%2")
		-- replace TEMP_G with g; must be done after the -go -> -vo changes
		text = rsub(text, TEMP_G, "г")
	end

	-- the second half of the if-statement below is an optimization; see above.
	if not noshto and text:find("то") then
		local ch2sh = {["ч"] = "ш", ["Ч"] = "Ш"}
		-- Handle что
		text = rsub(text, "%f[%a" .. AC .. GR .. "]([Чч])(то[" .. AC .. GR .. "]?)%f[^%a" .. AC .. GR .. "]",
			function(ch, to) return ch2sh[ch] .. to end)
		-- Handle чтобы, чтоб
		text = rsub(text, "%f[%a" .. AC .. GR .. "]([Чч])(то[" .. AC .. GR .. "]?бы?)%f[^%a" .. AC .. GR .. "]",
			function(ch, to) return ch2sh[ch] .. to end)
		-- Handle ничто
		text = rsub(text, "%f[%a" .. AC .. GR .. "]([Нн]и)ч(то[" .. AC .. GR .. "]?)%f[^%a" .. AC .. GR .. "]", "%1ш%2")
	end

	-- Handle мягкий, лёгкий, легчать, etc.
	text = rsub(text, "([МмЛл][яеё][" .. AC .. GR .. "]?)г([кч])", "%1х%2")

	return origtext, text
end

do
	local function get_prev_char(word, i)
		local j, ch = 0
		repeat
			j = j + 1
			ch = word[i - j]
		until not (ch and (DIACRITICS .. "()’"):find(ch, 1, true))
		return ch
	end
	
	local function get_next_char(word, i)
		local j, ch = 0
		repeat
			j = j + 1
			ch = word[i + j]
		until ch ~= "(" and ch ~= ")"
		-- If и, check if it's actually й to avoid wrongly treating it as
		-- a vowel.
		if (ch == "и" or ch == "И") and word[i + j + 1] == BR then
			remove(word, i + j + 1)
			ch = toNFC(ch .. BR)
			word[i + j] = ch
		end
		return ch
	end
	
	-- Check if a vowel should be made "plain" (usually by removing the "j"
	-- in the transliteration). Returns true if `prev` is in the string `check`.
	-- If `this` and `prev` are both uppercase, always returns false (on the
	-- assumption the term is an initialism).
	-- Note: We check both because of terms like Романо-д’Эццелино and
	-- Комон-л’Эванте, where an uppercase `this` follows a lowercase `prev`,
	-- (since the apostrophe is ignored).
	local function check_plain(this, prev, check, in_check)
		if prev and (this == ulower(this) or prev == ulower(this)) then
			if check:match(prev, 1, true) then
				return in_check
			end
			return not in_check
		end
	end
	
	-- Convert any jos (ё, ѣ̈, я̈) as a special-case.
	local function is_jo_letter(this, prev, output, word, d)
		local tr = jo_letters[this]
		if not tr then
			return
		end
		-- Remove "j" if preceded by a hushing consonant (ж ч ш щ).
		if check_plain(this, prev, "жчшщЖЧШЩ", true) then
			tr = tr:sub(2)
			if this == uupper(this) then
				tr = uupper(tr)
			end
		end
		insert(output, tr)
		-- Note the position, so we can give it an implicit primary stress
		-- if necessary (unless it already has secondary stress; shouldn't
		-- ever come after primary stress, but just in case it does we
		-- shouldn't override it or give the jo two stress marks.
		if word[d.i + 1] ~= GR then
			d.final_jo = #output
		end
		return true
	end
	
	local function do_iteration(output, word, d)
		-- Get current, previous and next characters, skipping over brackets, and
		-- ignoring diacritics for the previous character (which simplifies checks).
		local this = word[d.i]
		local prev = get_prev_char(word, d.i)
		local nxt = get_next_char(word, d.i)
		-- A word is monosyllabic if it has only one vowel.
		if vowels:find(this, 1, true) then
			d.vowels = d.vowels + 1
		end
		if nxt == DI then
			d.i = d.i + 1
			this = toNFC(this .. DI)
			if is_jo_letter(this, prev, output, word, d) then
				return
			end
		elseif nxt == BR then
			d.i = d.i + 1
			this = toNFC(this .. BR)
		-- Note that explicit stress has been found, which prevents any
		-- implicit stress from being added for jos.
		elseif this == AC then
			d.primary = true
		-- After a lowercase consonant or at the start of a suffix, е becomes
		-- e, ѣ becomes ě and э becomes ɛ.
		elseif plain_e[this] and (
			check_plain(this, prev, vowels .. "ъьЪЬʹʺ", false) or
			not prev and d.dash_before
		) then
			insert(output, plain_e[this])
			return
		-- ю is becomes u if if preceded by ж or ш.
		elseif (
			(this == "ю" or this == "Ю") and
			check_plain(this, prev, "жшЖШ", true)
		) then
			insert(output, this == "ю" and "u" or "U")
			return
		-- Make lowercase izhitsa display as -v- after /a/, /e/ and /i/
		-- (matching the equivalent Greek digraphs αυ, ευ and ηυ).
		elseif (
			this == "ѵ" and
			prev and ("аеиіѣэяѥaæɐeəɛiɪɨАЕИІѢЭЯѤAEƐI"):find(prev, 1, true)
		) then
			this = "в"
			word[d.i] = "в"
		-- Ignore word-final hard signs.
		elseif (this == "ъ" or this == "Ъ") and d.i == #word then
			return
		end
		insert(output, letters[this] or this)
	end

	-- Transliterate after the pronunciation-related transformations of
	-- export.apply_tr_fixes() have been applied. Called from {{ru-IPA}}.
	-- `jo_accent` is as in export.tr().
	function export.tr_after_fixes(text, jo_accent)
		-- normalize any aliases
		text = toNFC(text:gsub(UTF8, aliases))
		local output = {}
		
		-- Note: We use ustring gsub because ustring gmatch is bugged, and
		-- it's easy to make gsub do the same thing.
		rsub(text, "([^" .. word_chars .. "]*)([" .. word_chars .. "]*)", function(before, word)
			for _, ch in ipairs(explode(before)) do
				insert(output, ch)
			end
			-- FIXME: Do this in one loop instead of splitting by word.
			word = explode(toNFD(word))
			local d = {
				i = 0,
				vowels = 0
			}
			-- Prefix if it's preceded by "^-" or " -".
			if output[#output] == "-" then
				local prev = output[#output - 1]
				if not prev or rfind(prev, "%s") then
					d.dash_before = true
				end
			end
			while d.i < #word do
				d.i = d.i + 1
				do_iteration(output, word, d)
			end
			-- Add an implicit primary stress to a jo (if applicable).
			-- Jos do not implicitly take stress accents if an explicit primary
			-- stress is given. Otherwise, the final jo which doesn't have
			-- secondary stress takes primary stress.
			-- Prefixes do not take implicit primary stress.
			-- Primary stress will be shown on monosyllables if either they
			-- are a suffix or `jo_accent` is "mono".
			if (
				jo_accent ~= "none" and
				d.final_jo and
				(not (d.primary or word[#word] == "-")) and
				(jo_accent == "mono" or d.vowels > 1 or d.dash_before)
			) then
				output[d.final_jo] = output[d.final_jo] .. AC
			end
		end)
		
		return toNFC(concat(output))
	end
end

-- Transliterates text, which should be a single word or phrase. It should
-- include stress marks, which are then preserved in the transliteration.
-- ё is a special case: it is rendered (j)ó in multisyllabic words and
-- monosyllabic words in multi-word phrases, but rendered (j)o without an
-- accent in isolated monosyllabic words. This can be overridden with the
-- JO_ACCENT parameter: if set to "mono", monosyllabic words will also be
-- given as (j)ó (this is used in conjugation and declension tables); if set
-- to "none", it will always be rendered (j)o.
-- NOADJ disables special-casing for adjectives in -го, while FORCEADJ forces
-- special-casing for adjectives and disables checking for exceptions
-- (e.g. много). NOSHTO disables special-casing for что and related words.
function export.tr(text, lang, sc, jo_accent, noadj, noshto, forceadj)
	local origtext, subbed_text = export.apply_tr_fixes(text, noadj, noshto, forceadj)
	return export.tr_after_fixes(subbed_text, jo_accent)
end

-- translit with various special-case substitutions; NOADJ disables
-- special-casing for adjectives in -го, while FORCEADJ forces special-casing
-- for adjectives and disables checking for expections (e.g. много).
-- NOSHTO disables special-casing for что and related words. SUB is used
-- to implement arbitrary substitutions in the Cyrillic text before other
-- transformations are applied and before translit. It is of the form
-- FROM/TO,FROM/TO,...
function export.tr_sub(text, jo_accent, noadj, noshto, sub,
	forceadj)
	if type(text) == "table" then -- called directly from a template
		jo_accent = ine(text.args.jo_accent)
		noadj = ine(text.args.noadj)
		noshto = ine(text.args.noshto)
		sub = ine(text.args.sub)
		text = text.args[1]
	end

	if sub then
		local subs = rsplit(sub, ",")
		for _, subpair in ipairs(subs) do
			local subsplit = rsplit(subpair, "/")
			text = rsub(text, subsplit[1], subsplit[2])
		end
	end

	return export.tr(text, nil, nil, jo_accent, noadj, noshto, forceadj)
end

--for adjectives, pronouns
function export.tr_adj(text, jo_accent)
	if type(text) == "table" then -- called directly from a template
		jo_accent = ine(text.args.jo_accent)
		text = text.args[1]
	end

	-- we have to include "forceadj" because typically when tr_adj() is called
	-- from the noun or adjective modules, it's called with suffix ого, which
	-- would otherwise trigger the exceptional case and be transliterated as ogo
	return export.tr(text, nil, nil, jo_accent, false,
		"noshto", "forceadj")
end

return export

-- For Vim, so we get 4-space tabs
-- vim: set ts=4 sw=4 noet: