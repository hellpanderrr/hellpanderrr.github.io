local export = {}
local m_string_utils = require("string utilities")
local cmn = require("languages").getByCode("cmn")

local find = mw.ustring.find
local gsub = mw.ustring.gsub
local len = mw.ustring.len
local match = mw.ustring.match
local gmatch = mw.ustring.gmatch
local sub = mw.ustring.sub
local split = mw.text.split
local gsplit = mw.text.gsplit
local lower = mw.ustring.lower
local upper = mw.ustring.upper
local format = mw.ustring.format
local u = mw.ustring.char
local toNFD = mw.ustring.toNFD
local toNFC = mw.ustring.toNFC
local trim = mw.text.trim

local pua = {}
for i = 1, 7 do
	pua[i] = u(0xF000+i-1)
end

local m_data = mw.loadData("cmn-pron/data")
local m_zh = require("zh")
local _m_zh_data = nil
local hom_data = nil

local function track(page)
	local tracking_page = "cmn-pron/" .. page
	require("debug/track")(tracking_page)
	return true
end

local function hom_data_part(pinyin)
	local x = toNFD(pinyin):sub(1,1)
	if "a" <= x and x <= "g" then
		return 1
	elseif "h" <= x and x <= "m" then
		return 2
	elseif "n" <= x and x <= "w" then
		return 3
	end
	return 4
end

local function get_hom_data(py)
	if hom_data == nil then
		hom_data = require("zh/data/cmn-hom/" .. hom_data_part(py))
	end
	return hom_data
end

-- if not empty
local function ine(var)
	if var == "" then
		return nil
	else
		return var
	end
end

local breve, hacek, circumflex = u(0x306), u(0x30C), u(0x302)
local function input_error(text)
	if type(text) ~= "string" then
		return
	end
	local subs, err = {[breve] = hacek, [circumflex] = "h", ["ŋ"] = "ng", ["Ŋ"] = "Ng"}
	text = toNFD(text)
	if find(text, breve) and (find(text, "[zcsZCS]" .. circumflex) or find(text, "[ŋŊ]")) then
		err = "a breve and an uncommon shorthand"
	elseif find(text, breve) then
		err = "a breve"
	elseif find(text, "[zcsZCS]" .. circumflex) or find(text, "[ŋŊ]") then
		err = "an uncommon shorthand"
	end
	if err then error('The pinyin text "' .. text .. '" contains ' .. err .. '. Replace it with "' .. gsub(text, ".", subs) .. '".', 2) end
end

local function m_zh_data()
	if _m_zh_data == nil then _m_zh_data = require("zh/data/cmn-tag") end;
	return _m_zh_data;
end

function export.py_detone(text)
	return toNFC(gsub(toNFD(text), "[̄́̌̀]", ""))
end

function export.tone_determ(text)
	text = toNFD(text)
	return m_data.py_tone_mark_to_num[match(text, m_data.tones)] or '5'
end

local function sup(text)
	local ret = mw.html.create("sup"):wikitext(text)
	return tostring(ret)
end

function export.py_transf(text)
	return export.py_detone(text) .. export.tone_determ(text)
end

local function decompose_tones(text)
	return (toNFD(text):gsub("[EeUu]\204[\130\136]", toNFC))
end

function export.py_transform(text, detone, not_spaced)
	if find(text, "​") then
		error("Pinyin contains the hidden character: ​ (U+200B). Please remove that character from the text.")
	elseif find(text, "%d") then
		-- e.g. ma1 instead of mā
		error("Numbered tones should be given with tone marks instead.")
	end
	
	local tones = m_data.tones
	detone = ine(detone)
	not_spaced = ine(not_spaced)
	
	text = decompose_tones(text)
	
	text = text
		:gsub("\204[\128\129\132\140]", {["̄"] = "\1", ["́"] = "\2", ["̌"] = "\3", ["̀"] = "\4"})
		:gsub("\195[\138\156\170\188]", {["ê"] = "\5", ["ü"] = "\6", ["Ê"] = "\14", ["Ü"] = "\15"})
		:gsub("\228\184[\128\141]", {["一"] = "\7", ["不"] = "\8"})
	
	local function plaintext(text)
		return (text:gsub("\16([\1-\4])", "n%1g")
			:gsub("[\1-\8\14-\18]", function(m)
			return ({"\204\132", "\204\129", "\204\140", "\204\128", "ê", "ü", "一", "不", [14] = "Ê", [15] = "Ü", [16] = "ng", [17] = "gn", [18] = "'"})[m:byte()]
		end))
	end
	
	if not not_spaced then
		local i = 1
		local function check_apostrophes(check_text)
			i = i + 1
			local new_text = check_text
				:gsub("([^mnMN][\1-\4][iouIOU]?)([aeiou\5\6AEIOU\14\15]%f[\1-\4])", "%1'%2")
				:gsub("([\1-\4])([aeiou\5\6AEIOU\14\15]%f[\1-\4])", "%1'%2")
				:gsub("([a-gi-zA-GI-Z\5\6\14\15])([mnMN]%f[\1-\4])", "%1'%2")
				:gsub("([b-dfgj-np-tv-zB-DFGJ-NP-TV-Z])([mnMN]%f[%z%s%p])", "%1'%2")
				:gsub("([mnMN][\1-\4])([mnMN]%f[%z%s%p])", "%1'%2")
				:gsub("([\7\8])([aeiou\5\6mnAEIOU\14\15MN]%f[\1-\4%z%s%p])", "%1'%2")
			if new_text ~= check_text then
				check_apostrophes(new_text)
			elseif new_text ~= text then
				error(("Missing apostrophe before null-initial syllable - should be \"%s\" instead."):format(plaintext(new_text)), i)
			end
		end
		check_apostrophes(text)
	end
	
	local check_text = gsub(text,"([AOEaoe])([iou])(" .. tones .. ")", "%1%3%2")
	check_text = gsub(check_text,"([iuü])(" .. tones .. ")([aeiou])", "%1%3%2")
	if text ~= check_text then
		error("Incorrect diacritic placement in Pinyin - should be \"".. check_text .. "\" instead.")
	end
	
	text = lower(text)
		:gsub(" *([,.?]) *", " %1 ")
		:gsub("[#0]", {["#"] = " #", ["0"] = "5"})
		:gsub("%. +%. +%.", "...")
		:gsub("(%d)([%a\5-\8])", "%1 %2")
		:gsub("n([\1-\4]?)g", "\16%1")
		:gsub("%f[^aeiou\1-\6]\16%f[aeiou\1-\6]", "ng")
		:gsub("gn%f[aeiou\5\6]", "\17")
		:gsub("'r", "\18r")
		:gsub("\18r([aeiou\5\6])", "'r%1")
		:gsub("([aeiou\5\6][\1-\4]?[mn\16]?\18?r?)([bpmfvdtnlgkhjqxzcsywr\16\17\7\8])", "%1 %2")
		:gsub("([mn\16\7\8][\1-\4]?\18?r?)([bpmfvdtnlgkhjqxzcsywr\16\17\7\8])", "%1 %2")
		:gsub(" r%f[%z%d%s'%-]", "r")
		:gsub("([aeiou\5\6][\1-\4]?) ([mn\16])%f[%z%d%s'%-]", "%1%2")
		:gsub("['%-]", " ")
	
	if detone or text:find("%d") then
		text = text
			:gsub("([\1-\4])([^ ]*)", function(m1, m2)
				return m2 .. m1:byte()
			end)
			:gsub("[^%d\7\8]%f[%z%s,.?]", "%05")
			:gsub("([\7\8]\18?r)5", "%1")
	end
	
	text = plaintext(text)
	
	if not_spaced then
		text = text:gsub(" ", "")
	end
	
	return (toNFC(trim(text)):gsub(" +", " "))
end

local function iterate_words(text)
	local pos, word, non_word
	
	local function get_word()
		word, non_word, pos = text:match("([^%s]+)([%s]*)()", pos)
		if pos then
			return word, non_word
		end
	end
	
	return get_word
end

local function iterate_syllables(text)
	local cap = find(text, "^%u")
	text = export.py_transform(text, true)
	text = text
		:gsub("\195[\170\188]", {["ê"] = "\1", ["ü"] = "\2"})
		:gsub("[zcs]h", {["zh"] = "\3", ["ch"] = "\4", ["sh"] = "\5"})
	local raw_syllables = split(text, " ")
	
	local function plaintext(text)
		return (text and text:gsub("[\1-\8]", function(m)
			return ({"ê", "ü", "ẑ", "ĉ", "ŝ", "ŋ", "ɲ", "ɨ"})[m:byte()]
		end))
	end
	
	local i = 0
	local function explode_syllable()
		i = i + 1
		if raw_syllables[i] then
			local syllable, tone, sandhi, block_sandhi = raw_syllables[i]
			if syllable == "" then
				return explode_syllable()
			end
			syllable = syllable
				:gsub("(\228\184[\128-\141])('?r?)$", function(m, erhua)
					sandhi = m
					return (m:gsub(".*", {["一"] = "yi1", ["不"] = "bu4"})
						:gsub("(%a+)(%d)", "%1" .. erhua .. "%2"))
				end)
				:gsub("^#", function(m)
					block_sandhi = true
					return ""
				end)
				:gsub("%d$", function(m)
					tone = m
					return ""
				end)
				:gsub("ng", "\6")
				:gsub("gn", "\7")
				:gsub("([bpmfv])(o'?r?)$", "%1u%2")
				:gsub("([jq\7x])u", "%1\2")
				:gsub("[iy]u", {["iu"] = "iou", ["yu"] = "\2"})
				:gsub("[eu]i", {["ei"] = "\1i", ["ui"] = "u\1i"})
				:gsub("ao", "au")
				:gsub("[wy]", {["w"] = "u", ["y"] = "i"})
				:gsub("([iu\2])e('?r?)$", "%1\1%2")
				:gsub("(.)o([mn\6]'?r?)$", "%1u%2")
				:gsub("iu", "\2")
				:gsub("^([^aoe\1]?[iu\2])([mn\6]'?r?)$", "%1e%2")
				:gsub("([iu])%1", "%1")
				:gsub("([\3-\5rzcs])i('?r?)$", "%1\8%2")
			local initial, glide1, nucleus, glide2, nasal, erhua = syllable:match("^([bpmfvdtnlgk\6hjq\7x\3-\5rzcs]?)([iu\2\8]?)([aoe\1]?)([iu]?)([mn\6]?)('?r?)$")
			return (syllable:gsub("[#%d]", "")), plaintext(initial), plaintext(glide1), plaintext(nucleus), glide2, plaintext(nasal), erhua, tone, sandhi, (not not block_sandhi)
		end
	end
	
	return explode_syllable
end

-- Generate a normalized pinyin version as a baseline, which everything else can work from.
local function normalize_py(text, no_words)
	local raw_words, words = split(text, " "), {}
	for i, word in ipairs(raw_words) do
		local cap = find(word, "^%u")
		word = export.py_transform(word, true)
		word = word:gsub("\195[\170\188]", {["ê"] = "\1", ["ü"] = "\2"})
		
		local raw_syllables, syllables = split(word, " "), {}
		for j, s in ipairs(raw_syllables) do
			s = s
				:gsub("[zcs]h", {["zh"] = "\3", ["ch"] = "\4", ["sh"] = "\5"})
				:gsub("ng", "\6")
				:gsub("gn", "\7")
				:gsub("([bpmfv])(or?%d)", "%1u%2")
				:gsub("([jq\7x])u", "%1\2")
				:gsub("iu", "iou")
				:gsub("yu", "\2")
				:gsub("ui", "uei")
				:gsub("ao", "au")
				:gsub("[wy]", {["w"] = "u", ["y"] = "i"})
				:gsub("([iu\2])e(r?%d)", "%1\1%2")
				:gsub("ue([n\6]r?)", "u%1")
				:gsub("io(\6r?)", "\2%1")
				:gsub("([iu])%1", "%1")
				:gsub("([\3-\5rzcs])i(r?%d)", "%1ɨ%2")
				:gsub("[\1-\7]", function(m)
					return ({"ê", "ü", "ẑ", "ĉ", "ŝ", "ŋ", "ɲ"})[m:byte()]
				end)
			table.insert(syllables, toNFC(s))
		end
		
		word = syllables
		if #word > 0 then
			word[1] = cap and gsub(word[1], "^.", upper) or word[1]
			table.insert(words, word)
		end
	end
	
	if no_words then
		local syllables = {}
		for _, word in ipairs(words) do
			for _, s in ipairs(word) do
				table.insert(syllables, s)
			end
		end
		words = syllables
	end
	
	return words
end

function export.py_ipa(text)
	local ipa_initials = m_data.py_ipa_initials
	local ipa_initials_tl = m_data.py_ipa_initials_tl
	local ipa_finals = m_data.py_ipa_finals
	local ipa_erhua = m_data.py_ipa_erhua
	local ipa_tl_ts = m_data.py_ipa_tl_ts
	local ipa_t_values = m_data.py_ipa_t_values

	local tones = {}
	local tone_cats = {}
	text = lower(text)
	
	local syllables = normalize_py(text, true)
	
	for i, s in ipairs(syllables) do
		if s:find("^[,.?]+$") then
			table.remove(syllables, i)
		end
	end
	
	for i = 1, #syllables do
		syllables[i] = syllables[i]:gsub("%d", function(m)
			tone_cats[i] = m
			return ""
		end)
		if syllables[i] == "一" then
			tone_cats[i] = syllables[i+1] and (syllables[i+1]:match("%d") == "4" or syllables[i+1] == "ge") and "1-2" or "1-4"
			syllables[i] = "i"
		elseif syllables[i] == "不" then
			tone_cats[i] = syllables[i+1] and syllables[i+1]:match("%d") == "4" and "4-2" or "4"
			syllables[i] = "bu"
		end
		tone_cats[i] = tone_cats[i] or "5"
		syllables[i] = syllables[i]:gsub("#", function(m)
			tone_cats[i] = "#" .. tone_cats[i]
			return ""
		end)
	end
	
	for i, s in ipairs(syllables) do
		s = gsub(s, "^([bpmfvdtnlgkŋhjqɲxẑĉŝrzcs]?)([^r']+)('?r?)$", function(initial, final, erhua)
			if initial == "" and find(final, "^[aeêo]") then
				initial = "ˀ"
			end
			final = ipa_finals[final] or final
			if erhua == "r" then
				for i, from in ipairs(ipa_erhua[1]) do
					final = gsub(toNFD(final), toNFD(from) .. "$", ipa_erhua[2][i])
				end
				final = toNFC(final)
			end
			if initial:find("[zcs]") then
				final = final:gsub("ʐ", "z")
			elseif initial == "" then
				final = final:gsub("[iuy]̯", {["i̯"] = "j", ["u̯"] = "w", ["y̯"] = "ɥ"})
			end
			initial = ipa_initials[initial] or initial
			if tone_cats[i] == "5" then
				initial = initial:gsub(".*", ipa_initials_tl)
				final = final:gsub("ɤ$", "ə")
			end
			return gsub(initial .. final, "ʐʐ̩", "ʐ̩")
		end)
		
		local curr_tone_cat, prev_tone_cat, next_tone_cat = tone_cats[i], tone_cats[i-1], tone_cats[i+1]
		
		if curr_tone_cat == "5" then
			tones[i] = prev_tone_cat and ipa_tl_ts[prev_tone_cat:gsub("#", "")] or ""
		else
			tones[i] = ipa_t_values[curr_tone_cat:gsub("#", "")]
		end
		
		if curr_tone_cat:find("3") then
			if i == #tone_cats then
				if i > 1 then
					tones[i] = "²¹⁴⁻²¹⁽⁴⁾"
				end
			elseif next_tone_cat == "3" then
				tones[i] = "²¹⁴⁻³⁵"
			elseif next_tone_cat ~= "5" then
				tones[i] = "²¹⁴⁻²¹"
			end
		elseif curr_tone_cat == "2" and i > 1 and i < #tone_cats and (tones[i-1]:find("³⁵$") or tones[i-1]:find("⁵⁵$")) then
			tones[i] = "³⁵⁻⁵⁵"
		elseif curr_tone_cat == "4" and (next_tone_cat == "4" or next_tone_cat == "1-4") then
			tones[i] = "⁵¹⁻⁵³"
		elseif curr_tone_cat == "1-4" and next_tone_cat == "4" then
			tones[i] = "⁵⁵⁻⁵³"
		end
		syllables[i] = s .. tones[i]
		syllables[i] = gsub(syllables[i], "#", "")
	end
	
	return table.concat(syllables, " ")
end

function export.py_number_to_mark(text)
	local priority = m_data.py_mark_priority
	local tones = m_data.py_tone_num_to_mark
	
	text = text:gsub("([^%s0-5]+)([0-5])", function(syl, tone)
		for _, pattern in ipairs(priority) do
			local syl, n = gsub(syl, pattern, "%0" .. (tones[tone] or ""))
			if n > 0 then
				return syl
			end
		end
		return syl .. tone
	end)
	
	return toNFC(text)
end

function export.py_zhuyin(text)
	input_error(text)
	
	local py_zhuyin_consonant = m_data.py_zhuyin_consonant
	local py_zhuyin_glide = m_data.py_zhuyin_glide
	local py_zhuyin_nucleus = m_data.py_zhuyin_nucleus
	local py_zhuyin_final = m_data.py_zhuyin_final
	local py_zhuyin_syllabic_nasal = m_data.py_zhuyin_syllabic_nasal
	local py_zhuyin_tone = m_data.py_zhuyin_tone
	
	local output = {}
	text = export.py_transform(text)
	
	for syllable, initial, glide1, nucleus, glide2, nasal, erhua, tone in iterate_syllables(text) do
		if not (initial or glide1 or nucleus or glide2 or nasal) then
			table.insert(output, syllable)
		else
			local final = (py_zhuyin_nucleus[nucleus] or nucleus) .. (py_zhuyin_glide[glide2] or glide2)
			final = (py_zhuyin_final[final] or final) .. (py_zhuyin_consonant[nasal] or nasal)
			final = ((py_zhuyin_glide[glide1] or glide1) .. (py_zhuyin_final[final] or final))
				:gsub("(\227\132[\167-\169])ㄜ", "%1")
			syllable = (py_zhuyin_consonant[initial] or initial) .. final
			if initial:find("[bpmfv]") and syllable:find("ㄨㄛ$") then
				syllable = syllable:gsub("ㄨ", "")
			end
			syllable = syllable:gsub("^\227\132[\135\139\171]$", py_zhuyin_syllabic_nasal)
				:gsub("\227\132[\135\139\171]$", "<small>%0</small>")
			if syllable == "ㄜ" and erhua == "r" then
				syllable = "ㄦ"
				erhua = ""
			elseif #erhua > 0 then
				erhua = "ㄦ"
			end
			if tone == "5" then
				syllable = py_zhuyin_tone[tone] .. syllable .. erhua
			else
				syllable = syllable .. py_zhuyin_tone[tone] .. erhua
			end
			table.insert(output, syllable)
		end
	end
	
	return table.concat(output, " ")
end

function export.zhuyin_py(text)
	local zhuyin_py_initial = m_data.zhuyin_py_initial
	local zhuyin_py_final = m_data.zhuyin_py_final
	local zhuyin_py_tone = m_data.zhuyin_py_tone
	
 	local word = split(text, " ", true)
 	
 	local function process_syllable(syllable)
 		syllable = gsub(syllable, "^([ㄓㄔㄕㄖㄗㄘㄙ])([ˊˇˋ˙]?)$", "%1ㄧ%2")
 		return gsub(syllable, "([ㄅㄆㄇㄈㄉㄊㄋㄌㄍㄎㄏㄐㄑㄒㄓㄔㄕㄖㄗㄘㄙㄪ]?)([ㄧㄨㄩ]?[ㄚㄛㄜㄝㄞㄟㄠㄡㄢㄣㄤㄥㄦㄪㄫㄬㄧㄨㄩㄇ])([ˊˇˋ˙]?)(ㄦ?)", function(initial, final, tone, erhua)
 			
			initial = zhuyin_py_initial[initial]
			final = zhuyin_py_final[final]
			
			if erhua ~= "" then
				final = final .. "r"
			end
			if initial == "" then
				final = final
					:gsub("^([iu])(n?g?)$", function(a, b) return gsub(a, "[iu]", {["i"] = "yi", ["u"] = "wu"}) .. b end)
					:gsub("^(w?u)([in])$", "ue%2")
					:gsub("^iu$", "iou")
					:gsub("^([iu])", {["i"] = "y", ["u"] = "w"})
					:gsub("^ong", "weng")
					:gsub("^ü", "yu")
			end
			
			if initial:find("[jqx]") then
				final = final:gsub("^ü", "u")
			end
			local tone = zhuyin_py_tone[tone]
			
			if final:find("[ae]") then
				final = final:gsub("([ae])", "%1" .. tone)
			elseif final:find("i[ou]") then
				final = final:gsub("(i[ou])", "%1" .. tone)
			elseif final:find("[io]") then
				final = final:gsub("([io])", "%1" .. tone)
			else
				final = gsub(final, "^([wy]?)(.)", "%1" .. "%2" .. tone)
			end
			
 			return initial .. final
 		end)
 	end
 	
 	for i, syllable in ipairs(word) do
 		word[i] = process_syllable(syllable)
 	end
	
	return toNFC(table.concat(word, " "))
end

function export.py_wg(text)
	local py_wg_consonant = m_data.py_wg_consonant
	local py_wg_consonant_dental = m_data.py_wg_consonant_dental
	local py_wg_glide = m_data.py_wg_glide
	local py_wg_nucleus = m_data.py_wg_nucleus
	local py_wg_o = m_data.py_wg_o
	
	local output = {}
	
	for word, non_word in iterate_words(text) do
		local cap = find(word, "^%u")
		word = cap and lower(word) or word
		local syllables = {}
		for syllable, initial, glide1, nucleus, glide2, nasal, erhua, tone in iterate_syllables(word) do
			if not (initial or glide1 or nucleus or glide2 or nasal) then
				table.insert(syllables, syllable)
			else
				if glide1 == "ɨ" and  py_wg_consonant_dental[initial] then
					syllable = py_wg_consonant_dental[initial] .. "ŭ"
				else
					syllable = ((py_wg_consonant[initial] or initial) .. (py_wg_glide[glide1] or glide1) .. (py_wg_nucleus[nucleus] or nucleus) .. glide2 .. (py_wg_consonant[nasal] or nasal))
						:gsub("ehi", "ei")
						:gsub("au", "ao")
						:gsub("iou", "iu")
						:gsub("ian$", "ien")
					if py_wg_o[initial] then
						syllable = syllable:gsub("ê$", "o")
					elseif initial ~= "ŝ" then
						syllable = syllable:gsub("uo$", "o")
					end
					syllable = (#glide1 > 0 and syllable:gsub("ê([mn]g?)", "%1") or syllable)
						:gsub("üng", "iung")
					if initial == "" then
						syllable = syllable
							:gsub("^[%z\1-\127\194-\244][\128-\191]*", {["i"] = "y", ["u"] = "w", ["ü"] = "yü"})
							:gsub("^[yw]$", {["y"] = "i", ["w"] = "wu"})
							:gsub("^([wyo])([mn])", function(m1, m2)
								return ({["w"] = "wê", ["y"] = "yi", ["o"] = "u"})[m1] .. m2
							end)
					elseif glide1 == "u" and not initial:find("[gk]") then
						syllable = syllable:gsub("uei", "ui")
					end
				end
				if syllable == "o" and nucleus == "e" and erhua == "r" then
					syllable = "êrh"
					erhua = ""
				elseif #erhua > 0 then
					erhua = "-ʼrh"
				end
				table.insert(syllables, syllable .. tone:gsub("%d", sup) .. erhua)
			end
		end
		syllables[1] = cap and gsub(syllables[1], "^.", upper) or syllables[1]
		word = table.concat(syllables, "-")
			:gsub("%-([,.?])", "%1")
		table.insert(output, word .. non_word)
	end
	
	return table.concat(output)
end

local function temp_bg(text, bg)
	if bg == 'y' then
		return '<' .. text .. '>'
	end
	return text
end
	
local function make_bg(text, bg)
	if bg == 'y' then
		return '<span style="background-color:#F5DEB3">' .. text .. '</span>'
	else
		return text
	end
end

function export.py_gwoyeu(text, original_text)
	local initials = m_data.py_gwoyeu_initial
	local finals = m_data.py_gwoyeu_final
	
	if text:find('^%s') or text:find('%s$') then error('invalid spacing') end
	local words = split(text, " ")
	local count = 0
	for i, word in ipairs(words) do
		local cap = find(toNFD(word), "^%u")
		word = export.py_transform(word, true, true)
		word = gsub(word, "([1-5])", "%1 ")
		word = gsub(word, " $", "")
		word = gsub(word, '([!-/:-@%[-`{|}~！-／：-＠［-｀｛-･])', ' %1 ')
		word = gsub(word, ' +', ' ')
		word = gsub(word, ' $', '')
		word = gsub(word, '^ ', '')
		local syllables = split(word, " ")
		for j, syllable in ipairs(syllables) do
			count = count + 1
			if not find(syllable, '^[!-/:-@%[-`{|}~！-／：-＠［-｀｛-･]+$') then
				local current = sub(mw.title.getCurrentTitle().text, count, count)
				if find(current, '^[一七八不]$') then
					local exceptions = {['一'] = 'i', ['七'] = 'chi', ['八'] = 'ba', ['不'] = 'bu'}
					syllables[j] = exceptions[current]
				else
					local initial, final, tone = '', '', ''
					syllable = gsub(syllable, '([jqxy])u', '%1ü')
					syllable = gsub(syllable, '^([zcsr]h?)i(r?[1-5])$', '%1ɨ%2')
					if find(syllable, '([bpmfvdtnlgkhjqxzcsryw]?h?)([iuü]?[aoeiɨuüê][ioun]?g?r?)([1-5])') then
						syllable = gsub(syllable, '([bpmfvdtnlgkhjqxzcsryw]?h?)([iuü]?[aoeiɨuüê][ioun]?g?r?)([1-5])', function(a, b, c)
							initial = initials[a] or error('Unrecognised initial:' .. a); final = finals[b] or error('Unrecognised final:' .. b); tone = c
							return (initial .. final .. tone) end)
					elseif not (find(mw.title.getCurrentTitle().text, "[们們呒呣哏唔哼哦嗯嘸噷姆欸誒诶麼ㄇㄝM]") or find(mw.title.getCurrentTitle().text, "cmn-pron/testcases", 1, true)) then
						error('Unrecognised syllable:' .. syllable)
					end
					local original = initial..final..tone
					if initial:find('^[iu]$') then
						final = initial .. final
						initial = ''
					end
					if initial .. final == "e'l" then
						final = "el"
					end
					final = gsub(final, '([iu])%1', '%1')
					local len = len(initial) + len(final)
					local detone = initial..final
					local replace = detone
					local fullstop = false
					if tone == 5 or tone == '5' then
						fullstop = true
						if original_text then
							tone = split(export.py_transform(original_text, true), ' ')[count]:match('[1-5]')
						elseif initial:find('^[lmnr]$') then
							tone = 2
						else tone = 1 end
						if tone == 5 or tone == '5' then
							tone = export.tone_determ(m_zh.py(current))
						end
					end
					if tone == 1 or tone == '1' then
						if initial:find('^[lmnr]$') then
							replace = initial .. 'h' .. sub(detone, 2, len)
						else
							replace = detone
						end
					elseif tone == 2 or tone == '2' then
						if not initial:find('^[lmnr]$') then
							if final:find('^[iu]') then
								replace = gsub(detone, '[iu]', {['i'] = 'y', ['u'] = 'w'}, 1)
								replace = gsub(replace, '[yw]l?$', {['y'] = 'yi', ['w'] = 'wu', ['wl'] = 'wul',})
							else
								replace = gsub(detone, '([aiueoyè]+)', '%1r')
							end
						else
							replace = detone
						end
					elseif tone == 3 or tone == '3' then
						if final:find("^iu?e'l$") then
							detone = gsub(detone, "'", '')
						end
						detone = gsub(detone, '^[iu]', {['i'] = 'yi', ['u'] = 'wu'})
						if final:find('[aeiou][aeiou]') and (not final:find('^[ie][ie]') or initial..final=="ie") and (not final:find('^[uo][uo]') or initial..final=="uo") then
							replace = gsub(detone, '[iu]', {['i'] = 'e', ['u'] = 'o'}, 1)
						elseif final:find('[aoeiuyè]') then
							replace = gsub(detone, '([iuyw]?)([aoeiuyè])', '%1%2%2', 1)
						else
							error('Unrecognised final:'..final)
						end
					elseif tone == 4 or tone == '4' then
						if final:find("^iu?e'l$") then
							detone = gsub(detone, "'", '')
						end
						detone = gsub(detone, '^[iu]', {['i'] = 'yi', ['u'] = 'wu'})
						if detone:find('[aeo][iu]l?$') then
							replace = gsub(detone, "[iu]l?$", {['i'] = 'y', ['u'] = 'w', ['ul'] = 'wl'})
						elseif detone:find('[ngl]$') then
							replace = gsub(detone, "[ng'l]l?$", {['n'] = 'nn', ['g'] = 'q', ['l'] = 'll', ['gl'] = 'ql', ["'l"] = 'hl'})
						else
							replace = detone .. 'h'
						end
						replace = gsub(replace, 'yi([aeiou])', 'y%1')
						replace = gsub(replace, 'wu([aeiou])', 'w%1')
					end
					if fullstop then replace = '.' .. replace end
					syllables[j] = gsub(syllable, original, replace)
				end
			end
		end
		words[i] = table.concat(syllables, "")
		words[i] = cap and gsub(words[i], "^.", upper) or words[i]
	end
	return table.concat(words, " ")
end

-- Converts Hanyu Pinyin into Tongyong Pinyin.
function export.py_tongyong(text)
	local ty_tone = {
		["1"] = "", ["2"] = "\204\129", ["3"] = "\204\140", ["4"] = "\204\128", ["5"] = "\204\138"
	}
	
	local function num_to_mark(syllable, tone)
		tone = ty_tone[tone]
		if tone ~= "" then
			if find(syllable, "[aeê]") then
				syllable = gsub(syllable, "([aeê])", "%1" .. tone)
			elseif find(syllable, "o") then
				syllable = gsub(syllable, "(o)", "%1" .. tone)
			elseif find(syllable, "[iu]") then
				syllable = gsub(syllable, "([iu])", "%1" .. tone)
			elseif find(syllable, "[mn]") then
				syllable = gsub(syllable, "([mn])", "%1" .. tone)
			end
		end
		return syllable
	end
	
	local words = {}
	for word in gsplit(text, " ") do
		local cap = find(toNFD(word), "^%u")
		word = export.py_transform(word, true)
		local syllables = {}
		for syllable in gsplit(word, " ") do
			syllable = toNFC(gsub(syllable, "([crsz]h?i)", "%1h"))
			syllable = gsub(syllable, "ü", "yu")
			syllable = gsub(syllable, "([jqx])u", "%1yu")
			syllable = gsub(syllable, "iu", "iou")
			syllable = gsub(syllable, "ui", "uei")
			syllable = gsub(syllable, "([wf])eng", "%1ong")
			syllable = gsub(syllable, "wen", "wun")
			syllable = gsub(syllable, "iong", "yong")
			syllable = gsub(syllable, "^zh", "jh")
			syllable = gsub(syllable, "^q", "c")
			syllable = gsub(syllable, "^x", "s")
			syllable = #syllables ~= 0 and gsub(syllable, "^([aeo])", "-%1") or syllable
			syllable = gsub(syllable, "^([^1-5]+)([1-5])$", num_to_mark)
			
			table.insert(syllables, syllable)
		end
		word = table.concat(syllables, "")
		word = cap and gsub(word, "^.", upper) or word
		table.insert(words, word)
	end
	
	return toNFC(table.concat(words, " "))
end

-- Converts Hanyu Pinyin into the Yale system.
function export.py_yale(text)
	local yale_tone = {
		["1"] = u(0x304), ["2"] = u(0x301), ["3"] = u(0x30C), ["4"] = u(0x300), ["5"] = ""
	}
	
	local function num_to_mark(syllable, tone)
		tone = yale_tone[tone]
		if tone ~= "" then
			if find(syllable, "[ae]") then
				syllable = gsub(syllable, "([ae])", "%1" .. tone)
			elseif find(syllable, "o") then
				syllable = gsub(syllable, "(o)", "%1" .. tone)
			elseif find(syllable, "[iu]") then
				syllable = gsub(syllable, "([iu])", "%1" .. tone)
			elseif find(syllable, "[mnrz]") then
				syllable = gsub(syllable, "([mnrz])", "%1" .. tone)
			end
		end
		return syllable
	end
	
	local words = {}
	for word in gsplit(text, " ") do
		local cap = find(toNFD(word), "^%u")
		word = export.py_transform(word, true)
		local syllables = {}
		for syllable in gsplit(word, " ") do
			syllable = toNFC(gsub(syllable, "^r(%d)", "er%1"))
			syllable = gsub(syllable, "^([jqxy])u", "%1ü")
			syllable = gsub(syllable, "^(.h)i(%d)", "%1r%2")
			syllable = gsub(syllable, "^ri(%d)", "r%1")
			syllable = gsub(syllable, "^([csz])i(%d)", "%1z%2")
			syllable = gsub(syllable, "^zh", "j")
			syllable = gsub(syllable, "^.", m_data.py_yale_initial)
			syllable = gsub(syllable, "^tsh", "ch")
			syllable = gsub(syllable, "i([aeo])", "y%1")
			syllable = gsub(syllable, "u([ao])", "w%1")
			syllable = gsub(syllable, "ü([ae])", "yw%1")
			for chars, replacement in pairs(m_data.py_yale_two_medials) do
				syllable = gsub(syllable, chars, replacement)
			end
			syllable = gsub(syllable, "ong", "ung")
			syllable = gsub(syllable, ".", m_data.py_yale_one_medial)
			syllable = gsub(syllable, "ü", "yu")
			syllable = gsub(syllable, "([^lwy])o(%d)$", "%1wo%2")
			syllable = gsub(syllable, "([yz])%1", "%1")
			syllable = gsub(syllable, "^([^%d]+)(%d)$", num_to_mark)
			
			table.insert(syllables, syllable)
		end
		word = table.concat(syllables, "-")
		
		word = cap and gsub(word, "^.", upper) or word
		table.insert(words, word)
	end
	
	return toNFC(table.concat(words, " "))
end

-- Converts Hanyu Pinyin into the Palladius system.
function export.py_palladius(text)
	local words = {}
	for word in gsplit(text, " ") do
		local cap = find(toNFD(word), "^%u")
		word = export.py_transform(word, true)
		local syllables = {}
		for syllable in gsplit(word, " ") do
			syllable = toNFC(gsub(syllable, "%d", ""))
			syllable = gsub(syllable, "^([jqxy])u", "%1ü")
			syllable = gsub(syllable, "([mnr])(r?)$", function(m1, m2)
				m1 = m_data.py_palladius_final[m1] or m1
				return m1 .. (m2 == "r" and "р" or "")
			end)
			syllable = gsub(syllable, "ng", "н")
			syllable = gsub(syllable, "^..", m_data.py_palladius_two_initials)
			syllable = gsub(syllable, "^.", m_data.py_palladius_one_initial)
			for chars, replacement in pairs(m_data.py_palladius_three_medials) do
				syllable = gsub(syllable, chars, replacement)
			end
			for chars, replacement in pairs(m_data.py_palladius_two_medials) do
				syllable = gsub(syllable, chars, replacement)
			end
			syllable = gsub(syllable, ".", m_data.py_palladius_one_medial)
			for chars, replacement in pairs(m_data.py_palladius_specials) do
				syllable = gsub(syllable, chars, replacement)
			end
			syllable = gsub(syllable, "н$", "%1" .. pua[1])
			syllable = gsub(syllable, "[ую]$", "%1" .. pua[3])
			syllable = gsub(syllable, "[ая]?о$", "%1" .. pua[4])
			syllable = gsub(syllable, "[ая]$", "%1" .. pua[5])
			syllable = gsub(syllable, "ю?[иэ]$", "%1" .. pua[6])
			syllable = gsub(syllable, "оу$", "%1" .. pua[6])
			if syllable == "н" or syllable == "нь" then
				syllable = syllable .. pua[7]
			end
			table.insert(syllables, syllable)
		end
		word = table.concat(syllables, "")
		word = gsub(word, "н" .. pua[1] .. "([аеёиоуэюя])", "нъ%1")
		for chars, replacement in pairs(m_data.py_palladius_disambig) do
			word = gsub(word, chars, replacement)
		end
		word = gsub(word, "[" .. pua[1] .. "-" .. pua[7] .. "]", "")
		word = cap and gsub(word, "^.", upper) or word
		table.insert(words, word)
	end
	
	return toNFC(table.concat(words, " "))
end

function export.py_format(text, cap, bg, simple)
	if cap == false then cap = nil end
	if bg == false then bg = 'n' else bg = 'y' end
	if simple == false then simple = nil end
	text = toNFD(text)
	local phon = text
	local title = mw.title.getCurrentTitle().text
	local cat = ''
	local spaced = toNFD(export.py_transform(text))
	local space_count
	spaced, space_count = spaced:gsub(' ', '@')
	local consec_third_count
	
	for _ = 1, space_count do
		spaced, consec_third_count = gsub(spaced, "([^@]+)̌([^#@]*)@([^#@]+̌)", function(a, b, c)
			return temp_bg(a..'́'..b, bg)..'@'..c end, 1)
		if consec_third_count > 0 then
			phon = gsub(spaced, '@', '')
		end
	end
	text = gsub(text, "#", "")
	phon = gsub(phon, "#", "")
	
	if title:find('一') and not text:find('一') and not simple then
		cat = cat .. '[[Category:Mandarin words containing 一 not undergoing tone sandhi]]'
	end
	
	if text:find('[一不]') and not simple then
		text = gsub(text, '[一不]$', {['一'] = 'yī', ['不'] = 'bù'})
		phon = gsub(phon, '[一不]$', {['一'] = 'yī', ['不'] = 'bù'})
		
		if find(text, '一') then
			if find(text, '一[^̄́̌̀]*[̄́̌]') then
				cat = cat .. '[[Category:Mandarin words containing 一 undergoing tone sandhi to the fourth tone]]'
				phon = gsub(phon, '一([^̄́̌̀]*[̄́̌])', function(a) return temp_bg('yì', bg) .. a end)
				text = gsub(text, '一([^̄́̌̀]*[̄́̌])', 'yī%1')
			end
			if find(text, '一[^̄́̌̀]*̀') or find(text, '一ge$') or find(text, '一ge[^nr]') then
				cat = cat .. '[[Category:Mandarin words containing 一 undergoing tone sandhi to the second tone]]'
				phon = gsub(phon, '一([^̄́̌̀]*̀)', function(a) return temp_bg('yí', bg) .. a end)
				phon = gsub(phon, '一ge', temp_bg('yí', bg) .. 'ge')
				text = gsub(text, '一([^̄́̌̀]*[̄́̌])', 'yī%1')
			end
		end
		if find(text, '不 ?[bpmfvdtnlgkhjqxzcsrwy]?[ghn]?[aeiou]*̀') then
			cat = cat .. '[[Category:Mandarin words containing 不 undergoing tone sandhi|2]]'
			phon = gsub(phon, '不( ?[bpmfvdtnlgkhjqxzcsrwy]?[ghn]?[aeiou]*̀)', function(a) return temp_bg('bú', bg) .. a end)
		end
	end
	text = gsub(text, '[一不]', {['一'] = 'yī', ['不'] = 'bù'})
	text = gsub(text, '兒', function() return make_bg('r', bg) end) -- character is deleted
	phon = gsub(phon, '[一不]', {['一'] = 'yī', ['不'] = 'bù'})
	phon = gsub(phon, '<([^>]+)>', '<span style="background-color:#F5DEB3">%1</span>')
	
	if not simple then
		if cap then
			text = gsub(text, '^%l', upper)
			phon = gsub(phon, '^%l', upper)
		end
		local linked_text = require("links").full_link{term = text, lang = cmn}
		if phon ~= text then
			text = (linked_text) .. " [Phonetic: " .. phon .. "]"
		else
			text = linked_text
		end
		if mw.title.getCurrentTitle().nsText ~= "Template" then
			text = text .. cat
		end
	end
	return toNFC(text)
end

function export.make_tl(original_text, tl_pos, bg, cap)
	if bg == false then bg = 'n' else bg = 'y' end
	local _, countoriginal = original_text:gsub(" ", " ")
	local spaced = export.py_transform(original_text)
	if sub(spaced, -1, -1) == ' ' then spaced = sub(spaced, 1, -2) end
	local _, count = spaced:gsub(" ", " ")
	local index = {}
	local start, finish
	local pos = 1
	for i = 1, count, 1 do
		if i ~= 1 then pos = (index[i-1] + 1) end
		index[i] = find(spaced, ' ', pos)
	end
	if tl_pos == 2 then
		start = index[count-1] - count + countoriginal + 2
		finish = index[count] - count + countoriginal
	elseif tl_pos == 3 then
		start = index[count-2] - count + countoriginal + 3
		finish = index[count-1] - count + countoriginal + 1
	else
		start = count == 0 and 1 or (index[count] - count + countoriginal + 1)
		finish = -1
	end
	local text = (sub(original_text, 1, start-1) .. make_bg(gsub(sub(original_text, start, finish), '.', export.py_detone), bg))
	if finish ~= -1 then text = (text .. sub(original_text, finish+1, -1)) end
	if cap == true then text = gsub(text, '^%l', upper) end
	return text
end

function export.tag(first, second, third, fourth, fifth)
	local text = "(''"
	local tag = {}
	local tagg = first or "Standard Chinese"
	tag[1] = (second ~= '') and second or "Standard Chinese"
	tag[2] = (third ~= '') and third or nil
	tag[3] = (fourth ~= '') and fourth or nil
	tag[4] = (fifth ~= '') and fifth or nil
	text = text .. ((tagg == '') and table.concat(tag, ", ") or tagg) .. "'')"
	text = gsub(text, 'Standard Chinese', "[[w:Standard Chinese|Standard Chinese]]")
	text = gsub(text, 'Mainland', "[[w:Putonghua|Mainland]]")
	text = gsub(text, 'Taiwan', "[[w:Taiwanese Mandarin|Taiwan]]")
	text = gsub(text, 'Beijing', "[[w:Beijing dialect|Beijing]]")
	text = gsub(text, 'erhua', "[[w:erhua|erhua]]")
	text = gsub(text, 'Min Nan', "[[w:Min Nan|Min Nan]]")
	text = gsub(text, 'shangkouzi', "''[[上口字|shangkouzi]]''")
	return text
end

function export.straitdiff(text, pron_ind, tag)
	local conv_text = text
	for i = 1, #text do
		if m_zh_data().MT[sub(text, i, i)] then conv_text = 'y' end
	end
	if tag == 'tag' then
		conv_text = (conv_text == 'y') and m_zh_data().MT_tag[match(text, '[丁-丌与-龯㐀-䶵]')][pron_ind] or ''
	elseif pron_ind == 1 or pron_ind == 2 or pron_ind == 3 or pron_ind == 4 or pron_ind == 5 then
		local reading = {}
		for a, b in pairs(m_zh_data().MT) do
			reading[a] = b[pron_ind]
			if reading[a] then reading[a] = gsub(reading[a], "^([āōēáóéǎǒěàòèaoe])", "'%1") end
		end
		conv_text = gsub(text, '.', reading)
		text = gsub(text, "^'", "")
		text = gsub(text, " '", " ")
		if conv_text == text and tag == 'exist' then return nil end
	end
	conv_text = gsub(conv_text, "^'", "")
	return conv_text
end

function export.str_analysis(text, conv_type, other_m_vars)
	local MT = m_zh_data().MT
	
	text = gsub(text, '{default}', '')
	text = gsub(text, '=', '—')
	text = gsub(text, ',', '隔')
	text = gsub(text, '隔 ', ', ')
	if conv_type == 'head' or conv_type == 'link' then
		if find(text, '隔cap—') then
			text = gsub(text, '[一不]', {['一'] = 'Yī', ['不'] = 'Bù'})
		end
		text = gsub(text, '[一不]', {['一'] = 'yī', ['不'] = 'bù'})
	end
	local comp = split(text, '隔', true)
	local reading = {}
	local alternative_reading = {}
	local zhuyin = {}
	--[[
	-- not used
	local param = {
		'1n', '1na', '1nb', '1nc', '1nd', 'py', 'cap', 'tl', 'tl2', 'tl3', 'a', 'audio', 'er', 'ertl', 'ertl2', 'ertl3', 'era', 'eraudio',
		'2n', '2na', '2nb', '2nc', '2nd', '2py', '2cap', '2tl', '2tl2', '2tl3', '2a', '2audio', '2er', '2ertl', '2ertl2', '2ertl3', '2era', '2eraudio',
		'3n', '3na', '3nb', '3nc', '3nd', '3py', '3cap', '3tl', '3tl2', '3tl3', '3a', '3audio', '3er', '3ertl', '3ertl2', '3ertl3', '3era', '3eraudio',
		'4n', '4na', '4nb', '4nc', '4nd', '4py', '4cap', '4tl', '4tl2', '4tl3', '4a', '4audio', '4er', '4ertl', '4ertl2', '4ertl3', '4era', '4eraudio',
		'5n', '5na', '5nb', '5nc', '5nd', '5py', '5cap', '5tl', '5tl2', '5tl3', '5a', '5audio', '5er', '5ertl', '5ertl2', '5ertl3', '5era', '5eraudio'
	}
	--]]
	
	if conv_type == '' then
		return comp[1]
	elseif conv_type == 'head' or conv_type == 'link' then
		for i, item in ipairs(comp) do
			if not find(item, '—') then
				if find(item, '[一-龯㐀-䶵]') then
					local M, T, t = {}, {}, {}
					for a, b in pairs(MT) do
						M[a] = b[1]; T[a] = b[2]; t[a] = b[3];
						M[a] = gsub(M[a], "^([āōēáóéǎǒěàòèaoe])", "'%1")
						T[a] = gsub(T[a], "^([āōēáóéǎǒěàòèaoe])", "'%1")
						if t[a] then t[a] = gsub(t[a], "^([āōēáóéǎǒěàòèaoe])", "'%1") end
					end
					local mandarin = gsub(item, '.', M)
					local taiwan = gsub(item, '.', T)
					mandarin = gsub(mandarin, "^'", "")
					mandarin = gsub(mandarin, " '", " ")
					if conv_type == 'link' then return mandarin end
					taiwan = gsub(taiwan, "^'", "")
					taiwan = gsub(taiwan, " '", " ")
					local tt = gsub(item, '.', t)
					if find(text, 'cap—') then
						mandarin = gsub(mandarin, '^%l', upper)
						taiwan = gsub(taiwan, '^%l', upper)
						tt = gsub(tt, '^%l', upper)
					end
					if tt == item then
						zhuyin[i] = export.py_zhuyin(mandarin, true) .. ', ' .. export.py_zhuyin(taiwan, true)
						reading[i] = mandarin .. ']], [[' .. taiwan
					else
						tt = gsub(tt, "^'", "")
						tt = gsub(tt, " '", " ")
						zhuyin[i] = export.py_zhuyin(mandarin, true) .. ', ' .. export.py_zhuyin(taiwan, true) .. ', ' .. export.py_zhuyin(tt, true)
						reading[i] = mandarin .. ']], [[' .. taiwan .. ']], [[' .. tt
					end
				else
					if conv_type == 'link' then return item end
					zhuyin[i] = export.py_zhuyin(item, true)
					reading[i] = item
					if len(mw.title.getCurrentTitle().text) == 1 and #split(export.py_transform(item), " ") == 1 then
						local target = export.py_transf(reading[i])
						alternative_reading[i] = "[[" .. target .. "|" .. gsub(target, '([1-5])', sup) .. "]]"
						if alternative_reading[i]:find("5") then
							alternative_reading[i] = alternative_reading[i] .. "<span class=\"Zsym mention\" style=\"font-size:100%;\">／</span>" .. alternative_reading[i]:gsub("5", "0")
						end
						local title = mw.title.new(mw.ustring.lower(target)):getContent()
						if not (title and title:find("{{cmn%-pinyin}}")) then
							track("uncreated pinyin")
						end
					end
				end
				if reading[i] ~= '' then reading[i] = '[[' .. reading[i] .. ']]' end
				reading[i] = gsub(reading[i], "#", "")
			end
			comp[i] = item
			if conv_type == 'link' then return comp[1] end
		end
		local id = m_zh.ts_determ(mw.title.getCurrentTitle().text)
		local accel
		if id == 'trad' then
			accel = '<span class="form-of pinyin-t-form-of transliteration-' .. m_zh.ts(mw.title.getCurrentTitle().text)
		elseif id == 'simp' then
			accel = '<span class="form-of pinyin-s-form-of transliteration-' .. m_zh.st(mw.title.getCurrentTitle().text)
		elseif id == 'both' then
			accel = '<span class="form-of pinyin-ts-form-of'
		end
		accel = accel .. '" lang="cmn" style="font-family: Consolas, monospace;">'
		local result = other_m_vars and "*: <small>(''[[w:Standard Chinese|Standard]]'')</small>\n*::" or "*:"
		result = result .. "<small>(''[[w:Pinyin|Pinyin]]'')</small>: " .. accel .. gsub(table.concat(reading, ", "), ", ,", ",")
		if alternative_reading[1] then
			result = result .. " (" .. table.concat(alternative_reading, ", ") .. ")"
		end
		result = result .. (other_m_vars and "</span>\n*::" or "</span>\n*:")
		result = result .. "<small>(''[[w:Zhuyin|Zhuyin]]'')</small>: " .. '<span lang="cmn-Bopo" class="Bopo">' .. gsub(table.concat(zhuyin, ", "), ", ,", ",") .. "</span>"
		return result

	elseif conv_type == '2' or conv_type == '3' or conv_type == '4' or conv_type == '5' then
		if not find(text, '隔') or (comp[tonumber(conv_type)] and find(comp[tonumber(conv_type)], '—')) then
			return ''
		else
			return comp[tonumber(conv_type)]
		end
	else
		for i = 1, #comp, 1 do
			local target = '^' .. conv_type .. '—'
			if find(comp[i], target) then
				text = gsub(comp[i], target, '')
				return text
			end
		end
		text = ''
	end
	return text
end

function export.homophones(pinyin)
	local text = ''
	if mw.title.getCurrentTitle().nsText == '' then
		local args = get_hom_data(pinyin).list[pinyin]
		text = '<div style="visibility:hidden; float:left"><sup><span style="color:#FFF">edit</span></sup></div>'
		for i, term in ipairs(args) do
			if i > 1 then
				text = text .. "<br>"
			end
			if mw.title.new(term).exists and term ~= mw.title.getCurrentTitle().text then
				local forms = { term }
				local content = mw.title.new(term):getContent()
				local template = match(content, "{{zh%-forms[^}]*}}")
				if template then
					local simp = match(template, "|s=([^|}])+")
					if simp then
						table.insert(forms, simp)
					end
					for tradVar in gmatch(template, "|t[0-9]=([^|}])+") do
						table.insert(forms, tradVar)
					end
					for simpVar in gmatch(template, "|s[0-9]=([^|}])+") do
						table.insert(forms, simpVar)
					end
					term = table.concat(forms, "／")
				end
			end
			text = text .. require("links").full_link{ term = term, lang = cmn, tr = "-" }
		end
		text = text .. '[[Category:Mandarin terms with homophones]]'
	end
	return text
end

local function erhua(word, erhua_pos, pagename)
	local title = split(pagename, '')
	local linked_title = ''
	local syllables = split(export.py_transform(word), ' ')
	local count = #syllables
	erhua_pos = find(erhua_pos, '[1-9]') and split(erhua_pos, ';') or { count }
	for _, pos in ipairs(erhua_pos) do
		pos = tonumber(pos)
		title[pos] = title[pos] .. '兒'
		syllables[pos] = syllables[pos] .. 'r'
	end
	local title = table.concat(title)
	if mw.title.new(title).exists then
		linked_title = ' (' .. require("links").full_link{ term = title, lang = cmn, tr = "-" } .. ')'
	end
	for i, syllable in pairs(syllables) do
		if i ~= 1 and toNFD(syllable):find('^[aeiou]') then
			syllables[i] = "'" .. syllable
		end
	end
	word = table.concat(syllables, '')
	return (export.tag('', '', 'erhua-ed') .. linked_title), word
end

export.erhua = erhua

function export.make(frame)
	local args = frame:getParent().args
	return export.make_args(args)
end

function export.make_args(args)
	local pagename = mw.title.getCurrentTitle().text
	local text = {}
	local reading = {args[1] or '', args[2] or '', args[3] or '', args[4] or '', args[5] or ''}
	args["1nb"] = ine(args["1nb"])
	if reading[1] ~= '' then
		local title = export.tag((args["1n"] or ''), (args["1na"] or ''), (args["1nb"] or export.straitdiff(args[1], 1, 'tag')), (args["1nc"] or ''), (args["1nd"] or ''))
		local pinyin = export.straitdiff(reading[1], 1, '')
		table.insert(text, export.make_table(title, pinyin, (args["py"] or ''), (args["cap"] or ''), (args["tl"] or ''), (args["tl2"] or ''), (args["tl3"] or ''), (args["a"] or args["audio"] or '')))
		
		if args["er"] and args["er"] ~= '' then
			title, pinyin = erhua(pinyin, args["er"], pagename)
			table.insert(text, export.make_table(title, pinyin, '', (args["cap"] or ''), (args["ertl"] or ''), (args["ertl2"] or ''), (args["ertl3"] or ''), (args["era"] or args["eraudio"] or ''), true))
		end
	end
	
	if reading[2] ~= '' or export.straitdiff(reading[1], 2, 'exist') then
		if args["2nb"] and args["2nb"] ~= '' then tagb = args["2nb"] else tagb = export.straitdiff(args[1], 2, 'tag') end
		title = export.tag((args["2n"] or ''), (args["2na"] or ''), tagb, (args["2nc"] or ''), (args["2nd"] or ''))
		pinyin = (reading[2] ~= '') and reading[2] or export.straitdiff(reading[1], 2, '')
		table.insert(text, export.make_table(title, pinyin, (args["2py"] or ''), (args["2cap"] or ''), (args["2tl"] or ''), (args["2tl2"] or ''), (args["2tl3"] or ''), (args["2a"] or args["2audio"] or ''), true))
		table.insert(text, '[[Category:Mandarin terms with multiple pronunciations|' .. (export.straitdiff(args[1], 1, '') or args[1]) .. ']]')
		
		if args["2er"] and args["2er"] ~= '' then
			title, pinyin = erhua(pinyin, args["2er"], pagename)
			table.insert(text, export.make_table(title, pinyin, '', (args["2cap"] or ''), (args["2ertl"] or ''), (args["2ertl2"] or ''), (args["2ertl3"] or ''), (args["2era"] or args["2eraudio"] or ''), true))
		end
		
		if reading[3] ~= '' or export.straitdiff(reading[1], 3, 'exist') then
			if args["3nb"] and args["3nb"] ~= '' then tagb = args["3nb"] else tagb = export.straitdiff(args[1], 3, 'tag') end
			title = export.tag((args["3n"] or ''), (args["3na"] or ''), tagb, (args["3nc"] or ''), (args["3nd"] or ''))
			if reading[3] ~= '' then pinyin = reading[3] else pinyin = export.straitdiff(reading[1], 3, '') end
			table.insert(text, export.make_table(title, pinyin, (args["3py"] or ''), (args["3cap"] or ''), (args["3tl"] or ''), (args["3tl2"] or ''), (args["3tl3"] or ''), (args["3a"] or args["3audio"] or ''), true))
			
			if args["3er"] and args["3er"] ~= '' then
				title, pinyin = erhua(pinyin, args["3er"], pagename)
				table.insert(text, export.make_table(title, pinyin, '', (args["3cap"] or ''), (args["3ertl"] or ''), (args["3ertl2"] or ''), (args["3ertl3"] or ''), (args["3era"] or args["3eraudio"] or ''), true))
			end
			
			if reading[4] ~= '' or export.straitdiff(reading[1], 4, 'exist') then
				if args["4nb"] and args["4nb"] ~= '' then tagb = args["4nb"] else tagb = export.straitdiff(args[1], 4, 'tag') end
				title = export.tag((args["4n"] or ''), (args["4na"] or ''), tagb, (args["4nc"] or ''), (args["4nd"] or ''))
				if reading[4] ~= '' then pinyin = reading[4] else pinyin = export.straitdiff(reading[1], 4, '') end
				table.insert(text, export.make_table(title, pinyin, (args["4py"] or ''), (args["4cap"] or ''), (args["4tl"] or ''), (args["4tl2"] or ''), (args["4tl3"] or ''), (args["4a"] or args["4audio"] or ''), true))
			
				if args["4er"] and args["4er"] ~= '' then
					title, pinyin = erhua(pinyin, args["4er"], pagename)
					table.insert(text, export.make_table(title, pinyin, '', (args["4cap"] or ''), (args["4ertl"] or ''), (args["4ertl2"] or ''), (args["4ertl3"] or ''), (args["4era"] or args["4eraudio"] or ''), true))
				end
				if reading[5] ~= '' or export.straitdiff(reading[1], 5, 'exist') then
					if args["5nb"] and args["5nb"] ~= '' then tagb = args["5nb"] else tagb = export.straitdiff(args[1], 5, 'tag') end
					title = export.tag((args["5n"] or ''), (args["5na"] or ''), tagb, (args["5nc"] or ''), (args["5nd"] or ''))
					if reading[5] ~= '' then pinyin = reading[5] else pinyin = export.straitdiff(reading[1], 5, '') end
					table.insert(text, export.make_table(title, pinyin, (args["5py"] or ''), (args["5cap"] or ''), (args["5tl"] or ''), (args["5tl2"] or ''), (args["5tl3"] or ''), (args["5a"] or args["5audio"] or ''), true))
				
					if args["5er"] and args["5er"] ~= '' then
						title, pinyin = erhua(pinyin, args["5er"], pagename)
						table.insert(text, export.make_table(title, pinyin, '', (args["5cap"] or ''), (args["5ertl"] or ''), (args["5ertl2"] or ''), (args["5ertl3"] or ''), (args["5era"] or args["5eraudio"] or ''), true))
					end
				end
			end
		end
	end
	if (args["tl"] or '') .. (args["tl2"] or '') .. (args["tl3"] or '') .. (args["2tl"] or '') .. (args["2tl2"] or '') .. (args["2tl3"] or '') ~= '' then
		table.insert(text, '[[Category:Mandarin words containing toneless variants|' .. export.straitdiff(args[1], 1, '') .. ']]')
	end
	return table.concat(text)
end

local function add_audio(text, audio, pinyin)
	if audio and audio ~= "" then
		if audio == "y" then audio = format('zh-%s.ogg', pinyin) end
		table.insert(text, '\n*:: [[File:')
		table.insert(text, audio)
		table.insert(text, ']]')
		table.insert(text, '[[Category:Mandarin terms with audio links]]')
	end
end

function export.make_audio(args)
	local text, reading, pinyin = {}, {}, ""
	local audio = {
		args["a"] or args["audio"] or '',
		args["2a"] or args["2audio"] or '',
		args["3a"] or args["3audio"] or '',
		args["4a"] or args["4audio"] or '',
		args["5a"] or args["5audio"] or '',
	}
	for i=1, 5 do
		reading[i] = args[i] or ''
		if i == 1 then
			pinyin = export.straitdiff(reading[1], 1, '')
		else
			pinyin = (reading ~= '') and reading[i] or export.straitdiff(reading[1], i, '')
		end
		pinyin = export.py_format(pinyin, false, false, true)
		add_audio(text, audio[i], pinyin)
	end
	return table.concat(text)
end

function export.make_table(title, pinyin, py, cap, tl, tl2, tl3, a, novariety)
	py = ine(py);cap = ine(cap);tl = ine(tl);tl2 = ine(tl2);tl3 = ine(tl3);a = ine(a);novariety = ine(novariety)
	local text = {}
	
	local pinyin_simple_fmt = export.py_format(pinyin, false, false, true)
	
	if not novariety then
		table.insert(text, '* [[w:Mandarin Chinese|Mandarin]]')
	else
		table.insert(text, '<br>')
	end
	table.insert(text, '\n** <small>' .. title .. '</small>')
	local hom_found
	if get_hom_data(pinyin_simple_fmt).list[lower(pinyin_simple_fmt)] then
		hom_found = true
	else
		hom_found = false
		table.insert(text, '<sup><small><abbr title="Add Mandarin homophones"><span class="plainlinks">[' .. tostring(mw.uri.fullUrl("Module:zh/data/cmn-hom/" .. hom_data_part(pinyin_simple_fmt), {["action"]="edit"})) .. ' +]</span></abbr></small></sup>')
	end
	table.insert(text, "\n*** <small>''[[w:Pinyin|Hanyu Pinyin]]''</small>: ")
	local id = m_zh.ts_determ(mw.title.getCurrentTitle().text)
	if id == 'trad' then
		table.insert(text, '<span class="form-of pinyin-t-form-of transliteration-')
		table.insert(text, m_zh.ts(mw.title.getCurrentTitle().text))
	elseif id == 'simp' then
		table.insert(text, '<span class="form-of pinyin-s-form-of transliteration-')
		table.insert(text, m_zh.st(mw.title.getCurrentTitle().text))
	else -- both
		table.insert(text, '<span class="form-of pinyin-ts-form-of')
	end
	table.insert(text, '" lang="cmn" style="font-family: Consolas, monospace;">')
	if py then
		table.insert(text, py)
	else
		if cap then
			table.insert(text, export.py_format(pinyin, true, true))
		else
			table.insert(text, export.py_format(pinyin, false, true))
		end
		if tl or tl2 or tl3 then
			table.insert(text, ' → ')
			if tl then tl_pos = 1 elseif tl2 then tl_pos = 2 elseif tl3 then tl_pos = 3 end
			if cap then
				table.insert(text, export.make_tl(export.py_format(pinyin, true, false, true), tl_pos, true, true))
			else
				table.insert(text, export.make_tl(pinyin_simple_fmt, tl_pos, true))
			end
		end
		if tl then table.insert(text, ' <small>(toneless final syllable variant)</small>')
			elseif tl2 or tl3 then table.insert(text, ' <small>(toneless variant)</small>') end
	end
	table.insert(text, "</span>\n*** <small>''[[w:Zhuyin|Zhuyin]]''</small>: ")
	table.insert(text, '<span lang="cmn-Bopo" class="Bopo">')
	table.insert(text, export.py_zhuyin(pinyin_simple_fmt, true))
	if tl or tl2 or tl3 then
		table.insert(text, ' → ')
		table.insert(text, export.py_zhuyin(export.make_tl(pinyin_simple_fmt, tl_pos, false), true))
	end
	table.insert(text, '</span>')
	if tl then table.insert(text, ' <small>(toneless final syllable variant)</small>')
		elseif tl2 or tl3 then table.insert(text, ' <small>(toneless variant)</small>') end
	table.insert(text, "\n*** <small>''[[w:Tongyong Pinyin|Tongyong Pinyin]]''</small>: <span lang=\"cmn-Latn-tongyong\" style=\"font-family: Consolas, monospace;\">")
	if tl or tl2 or tl3 then
		table.insert(text, export.py_tongyong(export.make_tl(pinyin_simple_fmt, tl_pos, false), pinyin_simple_fmt))
	else
		table.insert(text, export.py_tongyong(pinyin_simple_fmt))
	end
	table.insert(text, '</span>')
	table.insert(text, "\n*** <small>''[[w:Wade–Giles|Wade–Giles]]''</small>: <span lang=\"cmn-Latn-wadegile\" style=\"font-family: Consolas, monospace;\">")
	if tl or tl2 or tl3 then
				table.insert(text, export.py_wg(export.make_tl(pinyin_simple_fmt, tl_pos, false), pinyin_simple_fmt))
	else
				table.insert(text, export.py_wg(pinyin_simple_fmt))
	end
	table.insert(text, '</span>')
	table.insert(text, "\n*** <small>''[[w:Yale romanization of Mandarin|Yale]]''</small>: <span lang=\"cmn-Latn\" style=\"font-family: Consolas, monospace;\">")
	if tl or tl2 or tl3 then
				table.insert(text, export.py_yale(export.make_tl(pinyin_simple_fmt, tl_pos, false), pinyin_simple_fmt))
	else
				table.insert(text, export.py_yale(pinyin_simple_fmt))
	end
	table.insert(text, '</span>')
	table.insert(text, "\n*** <small>''[[w:Gwoyeu Romatzyh|Gwoyeu Romatzyh]]''</small>: <span lang=\"cmn-Latn\" style=\"font-family: Consolas, monospace;\">")
	if tl or tl2 or tl3 then
		table.insert(text, export.py_gwoyeu(export.make_tl(pinyin_simple_fmt, tl_pos, false), pinyin_simple_fmt))
	else
		table.insert(text, export.py_gwoyeu(pinyin_simple_fmt))
	end
	table.insert(text, '</span>')
	table.insert(text, "\n*** <small>''[[w:Cyrillization of Chinese|Palladius]]''</small>: <span style=\"font-family: Consolas, monospace;\"><span lang=\"cmn-Cyrl\">")
	local palladius
	if tl or tl2 or tl3 then
				palladius = export.py_palladius(export.make_tl(pinyin_simple_fmt, tl_pos, false), pinyin_simple_fmt)
	else
				palladius = export.py_palladius(pinyin_simple_fmt)
	end
	table.insert(text, palladius)
	table.insert(text, "</span> <span lang=\"cmn-Latn\">(")
	table.insert(text, require("ru-translit").tr(palladius, nil, nil, "none", true, true))
	table.insert(text, ")</span></span>")
	table.insert(text, '\n*** <small>Sinological [[Wiktionary:International Phonetic Alphabet|IPA]] <sup>([[Appendix:Mandarin pronunciation|key]])</sup></small>: <span class="IPA">/')
	table.insert(text, export.py_ipa(pinyin))
	if tl or tl2 or tl3 then
		table.insert(text, '/ → /')
		table.insert(text, export.py_ipa(export.make_tl(pinyin_simple_fmt, tl_pos, false)))
	end
	table.insert(text, '/</span>')
	-- if a then
	-- 	if a == 'y' then a = 'zh-' .. pinyin_simple_fmt .. '.ogg' end
	-- 	table.insert(text, '\n*** <div style="display:inline-block; position:relative; top:0.5em;">[[File:')
	-- 	table.insert(text, a)
	-- 	table.insert(text, ']]</div>[[Category:Mandarin terms with audio links]]')
	-- end
	if hom_found then
		table.insert(text, "\n*** <small>Homophones</small>: " ..
			'<table class="wikitable" style="width:15em;margin:0; position:left; text-align:center">' ..
			'<tr><th class="mw-customtoggle-cmnhom" style="color:#3366bb">[Show/Hide]</th></tr>' ..
			'<tr class="mw-collapsible mw-collapsed" id="mw-customcollapsible-cmnhom">' ..
			'<td><sup><div style="float: right; clear: right;"><span class="plainlinks">[')
		table.insert(text, tostring(mw.uri.fullUrl("Module:zh/data/cmn-hom/" .. hom_data_part(pinyin_simple_fmt), {["action"]="edit"})))
		table.insert(text, ' edit]</span></div></sup>')
		table.insert(text, export.homophones(lower(pinyin_simple_fmt)))
		table.insert(text, '</td></tr></table>')
	end
	return table.concat(text)
end

function export.py_headword(frame)
	local plain_param = {}
	local params = {
		["head"] = plain_param,
		["zhuyin"] = plain_param,
		["notr"] = {type = "boolean"},
	}
	
	local args = require("parameters").process(frame:getParent().args, params, nil, "cmn-pron", "py_headword")
	
	local head = args.head or mw.title.getCurrentTitle().text
	local head_simple = require("links").remove_links(head)
	
	local Latn = require("scripts").getByCode("Latn")
	
	local categories = {"Hanyu Pinyin", "Mandarin non-lemma forms"}
	
	local inflections = {}
	if head:find("[0-5]") then
		table.insert(categories, "Hanyu Pinyin with tone numbers")
		head = head:gsub("%d", sup)
	elseif not args.notr then
		local py_detoned = export.py_transform(head, true)
		if not py_detoned:find("%s") then
			if py_detoned:find("5") then
				py_detoned = py_detoned .. "//" .. py_detoned:gsub("5", "0")
			end
			py_detoned = py_detoned:gsub("%d", sup)
			table.insert(inflections, {py_detoned, sc = Latn})
		end
	end
	
	if not args.notr then
		local Bopo = require("scripts").getByCode("Bopo")
		head_simple = export.py_number_to_mark(head_simple)
		table.insert(inflections, {
			label = "[[Zhuyin fuhao|Zhuyin]]",
			{
				term = args.zhuyin or export.py_zhuyin(head_simple),
				sc = Bopo,
				nolink = true
			}
		})
	end
	
	-- Don't pass a redundant head value, because they get categorised as redundant.
	if head == mw.title.getCurrentTitle().text then
		head = nil
	end
	
	return require("headword").full_headword{lang = cmn, sc = Latn, heads = {head}, inflections = inflections, pos_category = "pinyin", categories = categories, noposcat = true}
end

return export