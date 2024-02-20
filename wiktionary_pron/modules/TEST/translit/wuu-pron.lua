local export = {}

--[=[ for future direct wugniu to ipa
TODO:
- do IPA for glottalised nasal intials (currently the glottal stop is dropped)
- add Wenzhou?
- add Hangzhou mb?
]=]--

local ipa_initial = {
	['sh'] = {
		["p"] = "p", ["ph"] = "pʰ", ["b"] = "b", ["m"] = "m", ["f"] = "f", ["v"] = "v",
		["t"] = "t", ["th"] = "tʰ", ["d"] = "d", ["n"] = "n", ["l"] = "l",
		["ts"] = "t͡s", ["tsh"] = "t͡sʰ", ["s"] = "s", ["z"] = "z", ["c"] = "t͡ɕ", ["ch"] = "t͡ɕʰ",
		["j"] = "d͡ʑ", ["gn"] = "n̠ʲ", ["sh"] = "ɕ", ["zh"] = "ʑ",
		["k"] = "k", ["kh"] = "kʰ", ["g"] = "ɡ", ["ng"] = "ŋ", ["h"] = "h", ["gh"] = "ɦ"
	},
	['sz'] = {
		["p"] = "p", ["ph"] = "pʰ", ["b"] = "b", ["m"] = "m", ["f"] = "f", ["v"] = "v",
		["t"] = "t", ["th"] = "tʰ", ["d"] = "d", ["n"] = "n", ["l"] = "l",
		["ts"] = "t͡s", ["tsh"] = "t͡sʰ", ["s"] = "s", ["z"] = "z", ["c"] = "t͡ɕ", ["ch"] = "t͡ɕʰ",
		["j"] = "d͡ʑ", ["gn"] = "n̠ʲ", ["sh"] = "ɕ",
		["k"] = "k", ["kh"] = "kʰ", ["g"] = "ɡ", ["ng"] = "ŋ", ["h"] = "h", ["gh"] = "ɦ",
	},
}

local ipa_final = {
	['sh'] = {
		["a"] = "a", ["o"] = "o", ["au"] = "ɔ", ["eu"] = "ɤ", ["e"] = "e", ["oe"] = "ø",
		["i"] = "i", ["ia"] = "ia", ["io"] = "io", ["iau"] = "iɔ", ["ieu"] = "iɤ", ["ie"] = "ie",
		["u"] = "u", ["ua"] = "ua", ["ue"] = "ue", ["uoe"] = "uø",
		["iu"] = "y", ["ioe"] = "yø", 
		["an"] = "ã", ["aon"] = "ɑ̃", ["en"] = "ən", ["on"] = "oŋ",
		["aq"] = "aʔ", ["oq"] = "oʔ", ["eq"] = "əʔ",
		["ian"] = "iã", ["iaon"] = "iɑ̃", ["in"] = "in", ["ion"] = "ioŋ",
		["iaq"] = "iaʔ", ["ioq"] = "ioʔ", ["iq"] = "iɪʔ",
		["uan"] = "uã", ["uaon"] = "uɑ̃", ["uen"] = "uən",
		["uaq"] = "uaʔ", ["ueq"] = "uəʔ",
		["iun"] = "yn", ["iuq"] = "yɪʔ",
		["er"] = "əl", ["y"] = "z̩"
	},
	['sz'] = {
		["a"] = "ɑ", ["o"] = "o", ["au"] = "æ", ["eu"] = "øy", ["e"] = "e", ["oe"] = "ø", ["ou"] = "əu",
		["i"] = "i", ["ia"] = "iɑ", ["io"] = "io", ["iau"] = "iæ", ["ieu"] = "ʏ", ["ioe"] = "iø", ["ie"] = "ɪ",
		["u"] = "u", ["ua"] = "uɑ", ["ue"] = "ue", ["uoe"] = "uø",
		["iu"] = "y", ["ioe"] = "yø", 
		["an"] = "ã", ["aon"] = "ɑ̃", ["en"] = "ən", ["on"] = "oŋ",
		["aq"] = "ɑʔ", ["oq"] = "oʔ", ["eq"] = "əʔ", ["aeq"] = "aʔ",
		["ian"] = "iã", ["iaon"] = "iɑ̃", ["in"] = "in", ["ion"] = "ioŋ",
		["iaq"] = "iɑʔ", ["ioq"] = "ioʔ", ["iq"] = "iɪʔ", ["iaeq"] = "iaʔ",
		["uan"] = "uã", ["uaon"] = "uɑ̃", ["uen"] = "uən",
		["ueq"] = "uəʔ", ["uaeq"] = "uaʔ",
		["iun"] = "yn", ["iuq"] = "yəʔ", ["iuaeq"] = "yaʔ",
		["er"] = "əl", ["y"] = "z̩", ["yu"] = "z̩ʷ"
	},
}

local ipa_syllabic = {
	["m"] = "m̩", ["n"] = "n̩", ["ng"] = "ŋ̍",
}

local tone_contours = {
	['sh'] = {
		["1-0"] = "", ["1--"] = "³³",
		["1-1"] = "⁵³", ["2-1"] = "⁵⁵ ²¹", ["3-1"] = "⁵⁵ ³³ ²¹", ["4-1"] = "⁵⁵ ³³ ³³ ²¹", ["5-1"] = "⁵⁵ ³³ ³³ ³³ ²¹", 
		["1-5"] = "³⁴", ["2-5"] = "³³ ⁴⁴", ["3-5"] = "³³ ⁵⁵ ²¹", ["4-5"] = "³³ ⁵⁵ ³³ ²¹", ["5-5"] = "³³ ⁵⁵ ³³ ³³ ²¹", 
		["1-6"] = "²³", ["2-6"] = "²² ⁴⁴", ["3-6"] = "²² ⁵⁵ ²¹", ["4-6"] = "²² ⁵⁵ ³³ ²¹", ["5-6"] = "²² ⁵⁵ ³³ ³³ ²¹", 
		["1-7"] = "⁵⁵", ["2-7"] = "³³ ⁴⁴", ["3-7"] = "³³ ⁵⁵ ²¹", ["4-7"] = "³³ ⁵⁵ ³³ ²¹", ["5-7"] = "³³ ⁵⁵ ³³ ³³ ²¹", 
		["1-8"] = "¹²", ["2-8"] = "¹¹ ²³", ["3-8"] = "¹¹ ²² ²³", ["4-8"] = "²² ⁵⁵ ³³ ²¹", ["5-8"] = "²² ⁵⁵ ³³ ³³ ²¹",
		
		--RPS
		["1-single"] = "⁴⁴", ["5-single"] = "⁴⁴", ["6-single"] = "³³", ["7-single"] = "⁴⁴", ["8-single"] = "²²",
		["multiple"] = "³³"
	},
	['sz'] = {
		["1-0"] = "", 
		["1--"] = "³³",  ["2--"] = "³³ ³³", ["3--"] = "³³ ³³ ³³", ["4--"] = "³³ ³³ ³³ ³³",
		["1-1"] = "⁴⁴",  ["2-1"] = "⁴⁴ 0",  ["3-1"] = "⁴⁴ ⁴⁴ 0",  ["4-1"] = "⁴⁴ ⁴⁴ ⁴⁴ 0", 
		["1-2"] = "²²³", ["2-2"] = "²² ³³", ["3-2"] = "²² ³³ 0",  ["4-2"] = "²² ³³ ⁴⁴ 0",
		["1-3"] = "⁵¹",  ["2-3"] = "⁵⁵ ¹¹", ["3-3"] = "⁵⁵ ¹¹ 0",  ["4-3"] = "⁵⁵ ¹¹ ¹¹ 0",
		["1-5"] = "⁵²³", ["2-5"] = "⁵² ³³", ["3-5"] = "⁵² ³³ 0",  ["4-5"] = "⁵² ³³ ⁴⁴ 0",
		["1-6"] = "²³¹", ["2-6"] = "²³ ¹¹", ["3-6"] = "²³ ¹¹ 0",  ["4-6"] = "²³ ¹¹ ¹¹ 0",
		["1-7"] = "⁴³",  ["1-8"] = "²³", 
		
		["2-7-1"] = "⁴⁴ ²³", ["3-7-1"] = "⁴⁴ ²³ 0",  ["4-7-1"] = "⁴⁴ ²³ ⁴⁴ 0",
		["2-7-2"] = "⁴⁴ ²³", ["3-7-2"] = "⁴⁴ ²³ 0",  ["4-7-2"] = "⁴⁴ ²³ ⁴⁴ 0",
		["2-7-3"] = "⁵⁵ ⁵¹", ["3-7-3"] = "⁵⁵ ⁵¹ 0",  ["4-7-3"] = "⁵⁵ ⁵¹ ¹¹ 0",
		["2-7-5"] = "⁵⁵ ²³", ["3-7-5"] = "⁵⁵ ⁵² ³³", ["4-7-5"] = "⁵⁵ ⁵² ²² ³³",
		["2-7-6"] = "⁵⁵ ²³", ["3-7-6"] = "⁵⁵ ⁵² ³³", ["4-7-6"] = "⁵⁵ ⁵² ²² ³³",
		["2-7-7"] = "⁴⁴ ⁴⁴", ["3-7-7"] = "⁴⁴ ⁴⁴ 0",  ["4-7-7"] = "⁴⁴ ⁴⁴ ⁴⁴ ²²",
		["2-7-8"] = "⁴⁴ ⁴⁴", ["3-7-8"] = "⁴⁴ ⁴⁴ 0",  ["4-7-8"] = "⁴⁴ ⁴⁴ ⁴⁴ ²²",
		
		["2-8-1"] = "²² ³³", ["3-8-1"] = "²² ³³ 0",  ["4-8-1"] = "²² ³³ ⁴⁴ 0",
		["2-8-2"] = "²² ³³", ["3-8-2"] = "²² ³³ 0",  ["4-8-2"] = "²² ³³ ⁴⁴ 0",
		["2-8-3"] = "²² ⁵¹", ["3-8-3"] = "²² ⁵¹ 0",  ["4-8-3"] = "²² ⁵¹ ¹¹ 0",
		["2-8-5"] = "²² ²³", ["3-8-5"] = "²² ⁵² ³³", ["4-8-5"] = "²² ⁵² ²² ³³",
		["2-8-6"] = "²² ²³", ["3-8-6"] = "²² ⁵² ³³", ["4-8-6"] = "²² ⁵² ²² ³³",
		["2-8-7"] = "³³ ⁴⁴", ["3-8-7"] = "³³ ⁴⁴ 0",  ["4-8-7"] = "³³ ⁴⁴ ²² 0",
		["2-8-8"] = "³³ ⁴⁴", ["3-8-8"] = "³³ ⁴⁴ 0",  ["4-8-8"] = "³³ ⁴⁴ ²² 0",
		
		--RPS
		["1-single"] = "⁴⁴",  ["2-single"] = "²²³", ["3-single"] = "⁵¹", ["5-single"] = "⁵¹",
		["6-single"] = "²³¹", ["7-single"] = "⁴³",  ["8-sngle"] = "²³", 
		["multiple"] = "³³"
	},
}

local function get_tone(text, word_length, loc)
	local tone = text:sub(1, 1)
	if word_length == 1 then
		return tone_contours[loc]["1".."-"..tone] or error("Tone notation is incorrect. See [[WT:AWUU]].")
	elseif loc == 'sz' and tone:match("[78]") then
		local second_tone = text:match("^[0-9a-z]+ ([0-9])") or error("Tone of second syllable must be specified for tone sandhi!")
		return tone_contours[loc][word_length.."-"..tone.."-"..second_tone] or error("Tone notation is incorrect. See [[WT:AWUU]].")
	else
		return tone_contours[loc][word_length.."-"..tone] or error("Tone notation is incorrect. See [[WT:AWUU]].")
	end
end

local function RPS_tone_determ(word_length, tone, loc)
	if word_length == 1 then
		return tone_contours[loc][tone .. "-single"]
	else
		return tone_contours[loc]["multiple"]
	end
end


local function rom_check(text) --this checks wugniu
	if text:find("[0-9-]['qx]") or text:find('ny') or text:find('hh') then
		error('Invalid syllable: ' .. text ..'. Wugniu expected, but Wiktionary romanisation is supplied.')
	end
	if text:find('ghi') then
		error('Invalid initial "ghi". Use "yi" instead.')
	end
	if text:find('ghu') then
		error('Invalid initial "ghu". Use "wu" instead.')
	end
	if text:find('[^a-z]y[^a-z]') or text:find('[^a-z]y$') then
		error('Invalid syllable "y"')
	end
	if text:find('gn[aeou]') then
		error('Palatalization expected. Insert an "i" after the "gn".')
	end
	return nil
end

function export.ipa_syl_conv(text, loc)
	local result = "?"
	if text == "m" or text == "n" or text == "ng" then
		result = text:gsub("^.+$", function(text) return ipa_syllabic[text] end)
	elseif text:find("^y") then
		result = text:gsub("^y(.+)$", function(final) return "ɦ"..ipa_final[loc][final:gsub("^i?", "i")] end)
	elseif text:find("^w") then
		result = text:gsub("^w(.+)$", function(final) return "ɦ"..ipa_final[loc][final:gsub("^u?", "u")] end)
	elseif text:find("^([pbmfvtdnlszcjghk]s?[hng]?)") then
		result = text:gsub("^([pbmfvtdnlszcjgkh]s?[hng]?)(.+)$", function(initial, final) return (ipa_initial[loc][initial])..(ipa_final[loc][final]) end)
	else
		result = text:gsub("^.+$", function(final) return ipa_final[loc][final] end)
	end
	if result:find("?") then
		return error(("Invalid syllable: \"%s\""):format(text))
	end
	return result
end

function export.wugniu_to_ipa(original_text, loc)
	local text, conv_text = "", ""
	local tone_number = ""
	local reading = mw.text.split(original_text, ",", true)
	local syllable = {}
	local syl_tone = {}
	for reading_index = 1, #reading, 1 do
		local components = mw.text.split(reading[reading_index], "&", true)
		for component_index = 1, #components do
			local indep_words = mw.text.split(components[component_index], "+", true)
			for indep_index = 1, #indep_words do
				text = indep_words[indep_index]:gsub(' ([a-z]+)([0-9-])', ' %2%1')
				local word_length = string.len(text:gsub("[^ ]", "")) + 1
				rom_check(text)
				local tone = ""
				tone_number = text:sub(1, 1)
				tone = get_tone(text, word_length, loc) or error("Tone notation is incorrect. See [[WT:AZH/Wu]].")
				text = text:gsub("[0-9-]", "")
				local syllable = mw.text.split(text, " ", true)
				local syl_tone = mw.text.split(tone, " ", true)
				for i = 1, word_length, 1 do
					--RPS
					if i == word_length and indep_words[indep_index + 1] and tone ~= "³³" then
						syl_tone[i] = RPS_tone_determ(word_length, tone_number, loc)
					end
					
					if syllable[i] ~= "" then
						if syl_tone[i] == "0" then
							syllable[i] = export.ipa_syl_conv(syllable[i], loc)
						else
							syllable[i] = export.ipa_syl_conv(syllable[i], loc) .. syl_tone[i]
						end
					end
				end
				indep_words[indep_index] = table.concat(syllable, " ")
			end
			components[component_index] = table.concat(indep_words, " &nbsp;")
		end
		reading[reading_index] = table.concat(components, " ")
	end
	return table.concat(reading, "/, /")
end

function export.wikt_to_wugniu(text)
	if type(text) == "table" then text = text.args[1] end

	return text
	--initials
		:gsub("'''", "\1") --escape bold markup
		:gsub("'", "")
		:gsub("\1", "'''")
		:gsub("j", "c")
		:gsub("cc", "j") --jj
		:gsub("q(%a)", "ch%1")
		:gsub("x", "sh")
		:gsub("shsh", "zh") --xx
		:gsub("ny", "gni")
		:gsub('ii', 'i')
		:gsub('iy', 'y')
		:gsub("hh", "gh")
	
	--vowels
		:gsub("un", "uen")
		:gsub("yoe", "ioe")
		:gsub("y", "iu")
		:gsub("aan", "aon")
		:gsub("([^e])r", "%1y")
		:gsub("mm", "m")
		:gsub("ngg", "ng")

	--tones	
		:gsub("5", "8")
		:gsub("4", "7")
		:gsub("3", "6")
		:gsub("2", "5")
		
	--gh rules
		:gsub("ghi", "yi")
		:gsub("yi([aeou])", "y%1")
		:gsub("ghu", "wu")
		:gsub("wu([aeo])", "w%1")
		:gsub("ghng", "ng")
		:gsub("ghm", "m")
end

function export.wugniu_to_wikt(text)
	if type(text) == "table" then text = text.args[1] end
	--initials
	--Glottal stops? text = text:gsub("", "'")
	return text
		:gsub("j", "jj")
		:gsub("ch", "q")
		:gsub("c", "j")
		:gsub("([^t])sh", "%1x")
		:gsub("zh", "xx")
		:gsub("([^a-z])y", "%1hhi")
		:gsub("w", "hhu")
		:gsub("gn", "ny")
		:gsub("gh", "hh")

	--vowels
		:gsub("y(%A)", "r%1")
		:gsub("y$", "r")
		:gsub("uen", "un")
		:gsub("ioe", "yoe")
		:gsub("iu", "y")
		:gsub("aon", "aan")
	
	--syllabics
		:gsub("(%d)m(%A)", "%1hhmm%2")
		:gsub("(%d)m$", "%1hhmm")
		:gsub("(%d)ng(%A)", "%1hhngg%2")
		:gsub("(%d)ng$", "%1hhngg")
		
	--other fixes
		:gsub("ii", "i")
		:gsub("uu", "u")
		
	--tones	
		:gsub("5", "2"):gsub("6", "3"):gsub("7", "4"):gsub("8", "5")
end

function export.wugniu_format(text)
	return text
		:gsub("-", "")
		:gsub(" ", "-")
		:gsub("[&+]", " ")
		:gsub(",", "; ")
		:gsub('([%d]+)([a-z]+)([%d]+)', '<sup>%1</sup>%2<sub>%3</sub>')
		:gsub('([%d]+)([a-z]+)', '<sup>%1</sup>%2')
		:gsub('%-<sup>([%d]+)</sup>([a-z]+)', '-%2<sub>%1</sub>')
		:gsub('([a-z]+)<sub>([%d]+)</sub><sub>([%d]+)</sub>', '<sup>%2</sup>%1<sub>%3</sub>')
		:gsub('([a-z]+)([%d]+)', '%1<sub>%2</sub>')
end

function export.wikt_format(text)
	return text
		:gsub(" ", "-")
		:gsub("([%d]+)", '<sup>%1</sup>')
		:gsub("([a-z])<sup>([%d]+)</sup>", '%1<sub>%2</sub>')
		:gsub("[&+]", " ")
		:gsub(",", "; ")
		:gsub("'", "")
		:gsub("[])]([a-z])", ") %1")
end

function export.make(text, mode) --mode: textShow > true / textHide > false
	local result = ""
	local t = ""
	text = text:gsub("勿", "6veq8") -- for backwards compatibility
	if text:match(':') then
		text = mw.text.split(text, ';')
		for i = 1,#text,1 do
			local t = text[i]:sub(4)
			if text[i]:match("^sh:") then
				result = result .. '\n** <small>(<i>[[w:Shanghainese|Shanghainese]]</i>)</small>'
				if mode then
					result = result .. ': <span style="font-family: Consolas, monospace;">' .. export.wugniu_format(t) .. '</span>'
				else
					result = result .. '\n*** <small><i>[[Wiktionary:About Chinese/Wu|Wugniu]]</i></small>: <span style="font-family: Consolas, monospace;">' .. export.wugniu_format(t) .. '</span>'
					.. '\n*** <small><i>[[Wiktionary:About Chinese/Wu|Wiktionary Romanisation]]</i></small>: <span style="font-family: Consolas, monospace;">' .. export.wikt_format(export.wugniu_to_wikt(t)) .. '</span>'
					.. '\n*** <small>Sinological [[Wiktionary:International Phonetic Alphabet|IPA]] <sup>([[w:Shanghainese|key]])</sup></small>: <span class="IPA">/' .. export.wugniu_to_ipa(t, 'sh') .. '/</span>'
				end
			elseif text[i]:match("^sz:") then
				result = result .. '\n** <small>(<i>[[w:Suzhou dialect|Suzhounese]]</i>)</small>'
				if mode then
					result = result .. ': <span style="font-family: Consolas, monospace;">' .. export.wugniu_format(t) .. '</span>'
				else
					result = result .. '\n*** <small><i>[[Wiktionary:About Chinese/Wu|Wugniu]]</i></small>: <span style="font-family: Consolas, monospace;">' .. export.wugniu_format(t)
					.. '\n*** <small>Sinological [[Wiktionary:International Phonetic Alphabet|IPA]] <sup>([[w:Suzhou dialect|key]])</sup></small>: <span class="IPA">/' .. export.wugniu_to_ipa(t, 'sz') .. '/</span>'
				end
			else
				local e = mw.text.split(text[i], ":")
				if #e == 1 then
					error("Wugniu: prefix is required")
				else
					error('Wugniu: prefix "' .. e[1] .. '" is not recognized')
				end
			end
		end
	else -- backwards compatibility
		result = result .. '\n** <small>(<i>[[w:Shanghainese|Shanghainese]]</i>)</small>'
		if mode then
			result = result .. ': <span style="font-family: Consolas, monospace;">' .. export.wugniu_format(export.wikt_to_wugniu(text)) .. '</span>'
		else
			result = result .. '\n*** <small><i>[[Wiktionary:About Chinese/Wu|Wugniu]]</i></small>: <span style="font-family: Consolas, monospace;">' .. export.wugniu_format(export.wikt_to_wugniu(text)) .. '</span>'
			.. '\n*** <small><i>[[Wiktionary:About Chinese/Wu|Wiktionary Romanisation]]</i></small>: <span style="font-family: Consolas, monospace;">' .. export.wikt_format(text) .. '</span>'
			.. '\n*** <small>Sinological [[Wiktionary:International Phonetic Alphabet|IPA]] <sup>([[w:Shanghainese|key]])</sup></small>: <span class="IPA">/' .. export.wugniu_to_ipa(export.wikt_to_wugniu(text), 'sh') .. '/</span>'
		end
	end
	return result
end

return export