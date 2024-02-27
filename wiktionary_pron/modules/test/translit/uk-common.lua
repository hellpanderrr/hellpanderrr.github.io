local export = {}

local lang = require("languages").getByCode("uk")
local m_links = require("links")
local m_table = require("table")
local m_string_utilities = require("string utilities")
local m_uk_translit = require("uk-translit")

local u = mw.ustring.char
local rsplit = mw.text.split
local rfind = mw.ustring.find
local rmatch = mw.ustring.match
local rsubn = mw.ustring.gsub
local ulen = mw.ustring.len
local ulower = mw.ustring.lower

-- version of rsubn() that discards all but the first return value
local function rsub(term, foo, bar)
	local retval = rsubn(term, foo, bar)
	return retval
end


local AC = u(0x0301) -- acute =  ́
local GR = u(0x0300) -- acute =  `

export.VAR1 = u(0xFFF0)
export.VAR2 = u(0xFFF1)
export.VAR3 = u(0xFFF2)
export.var_code_c = "[" .. export.VAR1 .. export.VAR2 .. export.VAR3 .. "]"


export.vowel = "аеиоуіїяєюАЕИОУІЇЯЄЮ"
export.vowel_c = "[" .. export.vowel .. "]"
export.non_vowel_c = "[^" .. export.vowel .. "]"
export.cons_except_hushing_or_ts = "бдфгґйклмнпрствхзь'БДФГҐЙКЛМНПРСТВХЗЬ"
export.cons_except_hushing_or_ts_c = "[" .. export.cons_except_hushing_or_ts .. "]"
export.hushing = "чшжщЧШЖЩ"
export.hushing_c = "[" .. export.hushing .. "]"
export.hushing_or_ts = export.hushing .. "цЦ"
export.hushing_or_ts_c = "[" .. export.hushing_or_ts .. "]"
export.cons = export.cons_except_hushing_or_ts .. export.hushing_or_ts
export.cons_c = "[" .. export.cons .. "]"
-- Cyrillic velar consonants
export.velar = "кгґхКГҐХ"
export.velar_c = "[" .. export.velar .. "]"
-- uppercase Cyrillic consonants
export.uppercase = "АЕИОУІЇЯЄЮБЦДФГҐЧЙКЛМНПРСТВШХЗЖЬЩ"
export.uppercase_c = "[" .. export.uppercase .. "]"
export.accents_c = "[" .. AC .. GR .. "]"


local first_palatalization = {
	["к"] = "ч",
	["г"] = "ж",
	["ґ"] = "ж",
	["х"] = "ш",
	["ц"] = "ч",
}


local second_palatalization = {
	["к"] = "ц",
	["г"] = "з",
	["ґ"] = "з",
	["х"] = "с",
}


function export.translit_no_links(text)
	return m_uk_translit.tr(m_links.remove_links(text))
end


local grave_decomposer = {
	["ѐ"] = "е" .. GR,
	["Ѐ"] = "Е" .. GR,
	["ѝ"] = "и" .. GR,
	["Ѝ"] = "И" .. GR,
}

-- decompose precomposed Cyrillic chars w/grave accent; not necessary for
-- acute accent as there aren't precomposed Cyrillic chars w/acute accent,
-- and undesirable for precomposed й, й, ї, Ї, etc.
function export.decompose_grave(text)
	return rsub(text, "[ѐЀѝЍ]", grave_decomposer)
end


function export.needs_accents(text)
	text = export.decompose_grave(text)
	for _, word_with_hyphens in ipairs(rsplit(text, "%s+")) do
		-- A word needs accents if it contains no accent and has more than one vowel
		-- and doesn't begin or end with a hyphen (marking a prefix or suffix)
		if not rfind(word_with_hyphens, "^%-") and not rfind(word_with_hyphens, "%-$") then
			for _, word in ipairs(rsplit(word_with_hyphens, "%-")) do
				if not rfind(word, export.accents_c) and not export.is_monosyllabic(word) then
					return true
				end
			end
		end
	end
	return false
end


function export.is_stressed(word)
	return rfind(word, AC)
end


function export.is_multi_stressed(text)
	for _, word in ipairs(rsplit(text, "[%s%-]+")) do
		if ulen(rsub(word, "[^́]", "")) > 1 then
			return true
		end
	end
	return false
end


function export.remove_stress(word)
	return rsub(word, AC, "")
end


function export.remove_variant_codes(word)
	return rsub(word, export.var_code_c, "")
end


-- Handles the alternation between initial і/у and й/в.
function export.initial_alternation(word, previous)
	if rfind(word, "^[іІ]") or rfind(word, "^[йЙ]" .. export.non_vowel_c) then
		if rfind(previous, export.vowel_c .. AC .. "?$") then
			return rsub(word, "^[іІ]", {["і"] = "й", ["І"] = "Й"})
		else
			return rsub(word, "^[йЙ]", {["й"] = "і", ["Й"] = "І"})
		end
	elseif rfind(word, "^[уУ]") or rfind(word, "^[вВ]" .. export.non_vowel_c) then
		if rfind(previous, export.vowel_c .. AC .. "?$") then
			return rsub(word, "^[уУ]", {["у"] = "в", ["У"] = "В"})
		else
			return rsub(word, "^[вВ]", {["в"] = "у", ["В"] = "У"})
		end
	end
	
	return word
end


-- Check if word is monosyllabic (also includes words without vowels).
function export.is_monosyllabic(word)
	local num_syl = ulen(rsub(word, export.non_vowel_c, ""))
	return num_syl <= 1
end


-- If word is monosyllabic, add stress to the vowel.
function export.add_monosyllabic_stress(word)
	if export.is_monosyllabic(word) and not rfind(word, "^%-") and
		not rfind(word, "%-$") and not rfind(word, AC) then
		word = rsub(word, "(" .. export.vowel_c .. ")", "%1" .. AC)
	end
	return word
end


-- If word is monosyllabic, remove stress from the vowel.
function export.remove_monosyllabic_stress(word)
	if export.is_monosyllabic(word) and not rfind(word, "^%-") and
		not rfind(word, "%-$") then
		return export.remove_stress(word)
	end
	return word
end


-- Check if word is nonsyllabic.
function export.is_nonsyllabic(word)
	local num_syl = ulen(rsub(word, export.non_vowel_c, ""))
	return num_syl == 0
end


-- Check if word ends in a vowel.
function export.ends_in_vowel(stem)
	return rfind(stem, export.vowel_c .. AC .. "?$")
end


-- If word is unstressed, add stress onto initial syllable.
function export.maybe_stress_initial_syllable(word)
	if not rfind(word, AC) then
		-- stress first syllable
		word = rsub(word, "^(.-" .. export.vowel_c .. ")", "%1" .. AC)
	end
	return word
end


-- If word is unstressed, add stress onto final syllable.
function export.maybe_stress_final_syllable(word)
	if not rfind(word, AC) then
		-- stress last syllable
		word = rsub(word, "(.*" .. export.vowel_c .. ")", "%1" .. AC)
	end
	return word
end


function export.iotate(stem)
	stem = rsub(stem, "с[кт]$", "щ")
	stem = rsub(stem, "з[дгґ]$", "ждж")
	stem = rsub(stem, "к?т$", "ч")
	stem = rsub(stem, "зк$", "жч")
	stem = rsub(stem, "[кц]$", "ч")
	stem = rsub(stem, "[сх]$", "ш")
	stem = rsub(stem, "[гз]$", "ж")
	stem = rsub(stem, "д$", "дж")
	stem = rsub(stem, "([бвмпф])$", "%1л")
	return stem
end


function export.apply_first_palatalization(word)
	return rsub(word, "^(.*)([кгґхц])$",
		function(prefix, lastchar) return prefix .. first_palatalization[lastchar] end
	)
end


function export.apply_second_palatalization(word)
	return rsub(word, "^(.*)([кгґх])$",
		function(prefix, lastchar) return prefix .. second_palatalization[lastchar] end
	)
end


function export.reduce(word)
	local pre, letter, post = rmatch(word, "^(.*)([оОеЕєЄіІ])́?(" .. export.cons_c .. "+)$")
	if not pre then
		return nil
	end
	if letter == "о" or letter == "О" then
		-- FIXME, what about when the accent is on the removed letter?
		if post == "й" or post == "Й" then
			-- FIXME, is this correct?
			return nil
		end
		letter = ""
	else
		local is_upper = rfind(post, export.uppercase_c)
		if letter == "є" or letter == "Є" then
			-- англі́єц -> англі́йц-
			letter = is_upper and "Й" or "й"
		elseif post == "й" or post == "Й" then
			-- солове́й -> солов'-
			letter = "'"
			post = ""
		elseif (rfind(post, export.velar_c .. "$") and rfind(pre, export.cons_except_hushing_or_ts_c .. "$")) or
			(rfind(post, "[^йЙ" .. export.velar .. "]$") and rfind(pre, "[лЛ]$")) then
			-- FIXME, is this correct? This logic comes from ru-common.lua. The second clause that
			-- adds ь after л is needed but I'm not sure about the first one.
			letter = is_upper and "Ь" or "ь"
		else
			letter = ""
		end
	end
	return pre .. letter .. post
end


function export.dereduce(stem, epenthetic_stress)
	if epenthetic_stress then
		stem = export.remove_stress(stem)
	end
	-- We don't require there to be two consonants at the end because of ону́ка (gen pl ону́ок).
	local pre, letter, post = rmatch(stem, "^(.*)(.)(" .. export.cons_c .. ")$")
	if not pre then
		return nil
	end
	local is_upper = rfind(post, export.uppercase_c)
	local epvowel
	if rfind(letter, export.velar_c) or rfind(post, export.velar_c) or rfind(post, "[вВ]") then
		epvowel = is_upper and "О" or "о"
	elseif rfind(post, "['ьЬ]") then
		-- сім'я́ -> gen pl сіме́й
		-- ескадри́лья -> gen pl ескадри́лей
		epvowel = rfind(letter, export.uppercase_c) and "Е" or "е"
		post = ""
	elseif rfind(letter, "[йЙ]") then
		-- яйце́ -> gen pl я́єць
		epvowel = is_upper and "Є" or "є"
		letter = ""
	else
		if rfind(letter, "[ьЬ]") then
			-- кільце́ -> gen pl кі́лець
			letter = ""
		end
		epvowel = is_upper and "Е" or "е"
	end
	if epenthetic_stress then
		epvowel = epvowel .. AC
	end
	return pre .. letter .. epvowel .. post
end


function export.apply_vowel_alternation(ialt, stem)
	local modstem, origvowel
	if ialt == "io" then
		-- ріг, gen sg. ро́га; плід, gen sg. плода́/пло́ду; безкра́їсть gen sg. безкра́йості
		modstem = rsub(stem, "([іІїЇ])(́?" .. export.cons_c .. "*)$",
			function(vowel, post)
				origvowel = vowel
				if vowel == "і" then
					return "о" .. post
				elseif vowel == "І" then
					return "О" .. post
				elseif vowel == "ї" then
					return "йо" .. post
				else
					return "Йо" .. post
				end
			end
		)
		if modstem == stem then
			error("Indicator 'io' can't be applied because stem '" .. stem .. "' doesn't have an і as its last vowel")
		end
	elseif ialt == "ijo" then
		-- ко́лір, gen sg. ко́льору; вертолі́т, gen sg. вертольо́та
		modstem = rsub(stem, "і(́?" .. export.cons_c .. "*)$", "ьо%1")
		if modstem == stem then
			error("Indicator 'ijo' can't be applied because stem '" .. stem .. "' doesn't have an і as its last vowel")
		end
		origvowel = "і"
	elseif ialt == "ie" then
		modstem = rsub(stem, "([іїІЇ])(́?" .. export.cons_c .. "*)$",
			function(vowel, post)
				origvowel = vowel
				if vowel == "і" then
					-- ведмі́дь gen sg. ведме́дя
					return "е" .. post
				elseif vowel == "І" then
					return "Е" .. post
				elseif vowel == "ї" then
					-- Ки́їв gen sg. Ки́єва
					return "є" .. post
				else
					return "Є" .. post
				end
			end
		)
		if modstem == stem then
			error("Indicator 'ie' can't be applied because stem '" .. stem .. "' doesn't have an і or ї as its last vowel")
		end
	elseif ialt == "i" then
		modstem = rsub(stem, "ь?([оеОЕ])(́?" .. export.cons_c .. "*)$",
			function(vowel, post)
				origvowel = vowel
				if vowel == "о" or vowel == "е" then
					return "і" .. post
				else
					return "І" .. post
				end
			end
		)
		if modstem == stem then
			error("Indicator 'i' can't be applied because stem '" .. stem .. "' doesn't have an о or е as its last vowel")
		end
	else
		return stem, nil
	end
	return modstem, origvowel
end


-- Given a list of forms (each of which is a table of the form {form=FORM, footnotes=FOOTNOTES}),
-- concatenate into a SLOT=FORM,FORM,... string, replacing embedded | signs with <!>.
function export.concat_forms_in_slot(forms)
	if forms then
		local new_vals = {}
		for _, v in ipairs(forms) do
			table.insert(new_vals, rsub(v.form, "|", "<!>"))
		end
		return table.concat(new_vals, ",")
	else
		return nil
	end
end


function export.combine_stem_ending(stem, ending)
	if stem == "?" then
		return "?"
	elseif export.is_stressed(ending) then
		return export.remove_stress(stem) .. ending
	else
		return stem .. ending
	end
end


function export.generate_form(form, footnotes)
	if type(footnotes) == "string" then
		footnotes = {footnotes}
	end
	if footnotes then
		return {form = form, footnotes = footnotes}
	else
		return form
	end
end


function export.u_v_alternation_msg(frame)
	local params = {
		[1] = {}
	}
	local parargs = frame:getParent().args
	local args = require("parameters").process(parargs, params)
	local alternant = args[1] or mw.title.getCurrentTitle().text
	local ualt, valt, ufirst
	if rfind(alternant, "^[вВ]") then
		valt = alternant
		ualt = rsub(export.add_monosyllabic_stress(valt), "^([вВ])", {["в"] = "у", ["В"] = "У"})
		ufirst = false
	else
		ualt = alternant
		valt = export.remove_monosyllabic_stress(rsub(ualt, "^([уУ])", {["у"] = "в", ["У"] = "В"}))
		ufirst = true
	end
	ualt = m_links.full_link({lang = lang, term = ualt}, "term") .. " (used after consonants or at the beginning of a clause)"
	valt = m_links.full_link({lang = lang, term = valt}, "term") .. " (used after vowels)"
	local first, second
	if ufirst then
		first, second = ualt, valt
	else
		first, second = valt, ualt
	end
	return "The forms " .. first .. " and " .. second .. " differ in pronunciation but are considered variants of the same word."
end

function export.i_j_alternation_msg(frame)
	local params = {
		[1] = {}
	}
	local parargs = frame:getParent().args
	local args = require("parameters").process(parargs, params)
	local alternant = args[1] or mw.title.getCurrentTitle().text
	local ualt, valt, ufirst
	if rfind(alternant, "^[йЙ]") then
		valt = alternant
		ualt = rsub(export.add_monosyllabic_stress(valt), "^([йЙ])", {["й"] = "і", ["Й"] = "І"})
		ufirst = false
	else
		ualt = alternant
		valt = export.remove_monosyllabic_stress(rsub(ualt, "^([іІ])", {["і"] = "й", ["І"] = "Й"}))
		ufirst = true
	end
	ualt = m_links.full_link({lang = lang, term = ualt}, "term") .. " (used after consonants or at the beginning of a clause)"
	valt = m_links.full_link({lang = lang, term = valt}, "term") .. " (used after vowels)"
	local first, second
	if ufirst then
		first, second = ualt, valt
	else
		first, second = valt, ualt
	end
	return "The forms " .. first .. " and " .. second .. " differ in pronunciation but are considered variants of the same word."
end

return export