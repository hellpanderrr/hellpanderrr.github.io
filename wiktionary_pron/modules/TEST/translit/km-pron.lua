--- Reference: 'Khmer pronouncing dictionary: standard Khmer and Phnom Penh dialect'
--- https://unesdoc.unesco.org/ark:/48223/pf0000246360

local export = {}

local gsub = mw.ustring.gsub
local find = mw.ustring.find
local match = mw.ustring.match
local len = mw.ustring.len
local pagename = mw.title.getCurrentTitle().text

local j = "្"
local c = "កខគឃងចឆជឈញដឋឌឍណតថទធនបផពភមយរលវឝឞសហឡអ"
local cMod = "៉៊"
local vIndep = "ឣឤឥឦឧឨឩឪឫឬឭឮឯឰឱឲឳ"
local vDiac = "ាិីឹឺុូួើឿៀេែៃោៅំះៈ័៏"
local vPost = "់"
local apos = "'"

local kmChar = "ក-៹'"
local kmString = "[" .. kmChar .. "]+"
local recessive = "[ŋɲñnmjyrlʋv]"

local cCapt, cUncapt = "([" .. c .. "][" .. cMod .. "]?)", "[" .. c .. "][" .. cMod .. "]?"
local cOptCapt = "([" .. c .. "]?[" .. cMod .. "]?)"
local cCaptClus = {
	"([" .. c .. "][" .. cMod .. "]?)",
	"([" .. c .. "][" .. cMod .. "]?" .. j .. cUncapt .. ")",
	"([" .. c .. "][" .. cMod .. "]?" .. j .. cUncapt .. j .. cUncapt .. ")",
	"([" .. c .. "][" .. cMod .. "]?" .. j .. cUncapt .. j .. cUncapt .. j .. cUncapt .. ")"
}
local vCapt, vCaptB, vCaptM = "([" .. vDiac .. "])", "([" .. vDiac .. j .. "])", "([" .. vDiac .. "]*)"
local cvCapt = "([" .. c .. cMod .. vDiac .. "])"
local vPostCapt = "([" .. vPost .. "]?)"

local postInit = vCaptM .. cOptCapt .. vPostCapt .. "(" .. apos .. "?)"

local consonants = {
	["ក"] = { class = 1, ["ipa"] = { "k", "k" }, ["tc"] = { "k", "k" } },
	["ខ"] = { class = 1, ["ipa"] = { "kʰ", "k" }, ["tc"] = { "kh", "k" } },
	["គ"] = { class = 2, ["ipa"] = { "k", "k" }, ["tc"] = { "k", "k" } },
	["ឃ"] = { class = 2, ["ipa"] = { "kʰ", "k" }, ["tc"] = { "kh", "k" } },
	["ង"] = { class = 2, ["ipa"] = { "ŋ", "ŋ" }, ["tc"] = { "ng", "ng" } },
	["ង៉"] = { class = 1, ["ipa"] = { "ŋ", "ŋ" }, ["tc"] = { "ng", "ng" } },
	["ច"] = { class = 1, ["ipa"] = { "c", "c" }, ["tc"] = { "c", "c" } },
	["ឆ"] = { class = 1, ["ipa"] = { "cʰ", "c" }, ["tc"] = { "ch", "c" } },
	["ជ"] = { class = 2, ["ipa"] = { "c", "c" }, ["tc"] = { "c", "c" } },
	["ឈ"] = { class = 2, ["ipa"] = { "cʰ", "c" }, ["tc"] = { "ch", "c" } },
	["ញ"] = { class = 2, ["ipa"] = { "ɲ", "ɲ" }, ["tc"] = { "ñ", "ñ" } },
	["ញ៉"] = { class = 1, ["ipa"] = { "ɲ", "ɲ" }, ["tc"] = { "ñ", "ñ" } },
	["ដ"] = { class = 1, ["ipa"] = { "ɗ", "t" }, ["tc"] = { "d", "t" } },
	["ឋ"] = { class = 1, ["ipa"] = { "tʰ", "t" }, ["tc"] = { "th", "t" } },
	["ឌ"] = { class = 2, ["ipa"] = { "ɗ", "t" }, ["tc"] = { "d", "t" } },
	["ឍ"] = { class = 2, ["ipa"] = { "tʰ", "t" }, ["tc"] = { "th", "t" } },
	["ណ"] = { class = 1, ["ipa"] = { "n", "n" }, ["tc"] = { "n", "n" } },
	["ត"] = { class = 1, ["ipa"] = { "t", "t" }, ["tc"] = { "t", "t" } },
	["ថ"] = { class = 1, ["ipa"] = { "tʰ", "t" }, ["tc"] = { "th", "t" } },
	["ទ"] = { class = 2, ["ipa"] = { "t", "t" }, ["tc"] = { "t", "t" } },
	["ធ"] = { class = 2, ["ipa"] = { "tʰ", "t" }, ["tc"] = { "th", "t" } },
	["ន"] = { class = 2, ["ipa"] = { "n", "n" }, ["tc"] = { "n", "n" } },
	["ន៉"] = { class = 1, ["ipa"] = { "n", "n" }, ["tc"] = { "n", "n" } },
	["ប"] = { class = 1, ["ipa"] = { "ɓ", "p" }, ["tc"] = { "b", "p" } },
	["ប៉"] = { class = 1, ["ipa"] = { "p", "p" }, ["tc"] = { "p", "p" } },
	["ប៊"] = { class = 2, ["ipa"] = { "ɓ", "p" }, ["tc"] = { "b", "p" } },
	["ផ"] = { class = 1, ["ipa"] = { "pʰ", "p" }, ["tc"] = { "ph", "p" } },
	["ព"] = { class = 2, ["ipa"] = { "p", "p" }, ["tc"] = { "p", "p" } },
	["ភ"] = { class = 2, ["ipa"] = { "pʰ", "p" }, ["tc"] = { "ph", "p" } },
	["ម"] = { class = 2, ["ipa"] = { "m", "m" }, ["tc"] = { "m", "m" } },
	["ម៉"] = { class = 1, ["ipa"] = { "m", "m" }, ["tc"] = { "m", "m" } },
	["យ"] = { class = 2, ["ipa"] = { "j", "j" }, ["tc"] = { "y", "y" } },
	["យ៉"] = { class = 1, ["ipa"] = { "j", "j" }, ["tc"] = { "y", "y" } },
	["រ"] = { class = 2, ["ipa"] = { "r", "" }, ["tc"] = { "r", "" } },
	["រ៉"] = { class = 1, ["ipa"] = { "r", "" }, ["tc"] = { "r", "" } },
	["ល"] = { class = 2, ["ipa"] = { "l", "l" }, ["tc"] = { "l", "l" } },
	["ល៉"] = { class = 1, ["ipa"] = { "l", "l" }, ["tc"] = { "l", "l" } },
	["វ"] = { class = 2, ["ipa"] = { "ʋ", "w" }, ["tc"] = { "v", "w" } },
	["វ៉"] = { class = 1, ["ipa"] = { "ʋ", "w" }, ["tc"] = { "v", "w" } },
	["ឝ"] = { class = 1, ["ipa"] = { "s", "h" }, ["tc"] = { "s", "h" } },
	["ឞ"] = { class = 1, ["ipa"] = { "s", "h" }, ["tc"] = { "s", "h" } },
	["ស"] = { class = 1, ["ipa"] = { "s", "h" }, ["tc"] = { "s", "h" } },
	["ស៊"] = { class = 2, ["ipa"] = { "s", "h" }, ["tc"] = { "s", "h" } },
	["ហ"] = { class = 1, ["ipa"] = { "h", "h" }, ["tc"] = { "h", "h" } },
	["ហ៊"] = { class = 2, ["ipa"] = { "h", "h" }, ["tc"] = { "h", "h" } },
	["ឡ"] = { class = 1, ["ipa"] = { "l", "l" }, ["tc"] = { "l", "l" } },
	["អ"] = { class = 1, ["ipa"] = { "ʔ", "" }, ["tc"] = { "ʼ", "ʼ" } },
	["អ៊"] = { class = 2, ["ipa"] = { "ʔ", "" }, ["tc"] = { "ʼ", "ʼ" } },
	
	["ហក"] = { class = 1, ["ipa"] = { "ɡ", "k" }, ["tc"] = { "g", "k" } },
	["ហគ"] = { class = 2, ["ipa"] = { "ɡ", "k" }, ["tc"] = { "g", "k" } },
    ["ហគ៊"] = { class = 2, ["ipa"] = { "ɡ", "k" }, ["tc"] = { "g", "k" } },
	["ហន"] = { class = 1, ["ipa"] = { "n", "" }, ["tc"] = { "n", "n" } },
	["ហម"] = { class = 1, ["ipa"] = { "m", "" }, ["tc"] = { "m", "m" } },
	["ហល"] = { class = 1, ["ipa"] = { "l", "" }, ["tc"] = { "l", "l" } },
	["ហវ"] = { class = 1, ["ipa"] = { "f", "f" }, ["tc"] = { "f", "f" } },
	["ហវ៊"] = { class = 2, ["ipa"] = { "f", "f" }, ["tc"] = { "f", "f" } },
	["ហស"] = { class = 1, ["ipa"] = { "z", "z" }, ["tc"] = { "z", "z" } },
	["ហស៊"] = { class = 2, ["ipa"] = { "z", "z" }, ["tc"] = { "z", "z" } },
	
	[""] = { class = 1, ["ipa"] = { "", "" }, ["tc"] = { "", "" } },
}

local vowels = {
	[""] = { ["ipa"] = { "ɑː", "ɔː" }, ["tc"] = { "ɑɑ", "ɔɔ" } },
    ["៏"] = { ["ipa"] = { "ɑ", "ɔ" }, ["tc"] = { "ɑ", "ɔ" } },
	["់"] = { ["ipa"] = { "ɑ", "ŭə" }, ["tc"] = { "ɑ", "ŭə" } },
	["់2"] = { ["ipa"] = { "ɑ", "u" }, ["tc"] = { "ɑ", "u" } }, --before labial finals
	["័"] = { ["ipa"] = { "a", "ŏə" }, ["tc"] = { "a", "ŏə" } },
	["័2"] = { ["ipa"] = { "a", "ĕə" }, ["tc"] = { "a", "ĕə" } }, --before velar finals
	["័យ"] = { ["ipa"] = { "aj", "ɨj" }, ["tc"] = { "ay", "ɨy" } },
	["័រ"] = { ["ipa"] = { "aə", "ŏə" }, ["tc"] = { "", "ɔə" } },
	["ា"] = { ["ipa"] = { "aː", "iə" }, ["tc"] = { "aa", "iə" } },
	["ា់"] = { ["ipa"] = { "a", "ŏə" }, ["tc"] = { "a", "ŏə" } },
	["ា់2"] = { ["ipa"] = { "a", "ĕə" }, ["tc"] = { "a", "ĕə" } }, --before velar finals
	["ិ"] = { ["ipa"] = { "eʔ", "iʔ" }, ["tc"] = { "eʼ", "iʼ" } }, --glottal coda only in stressed syllables
	["ិ2"] = { ["ipa"] = { "ə", "ɨ" }, ["tc"] = { "ə", "ɨ" } }, --with non-glottal coda
	["ិយ"] = { ["ipa"] = { "əj", "iː" }, ["tc"] = { "əy", "ii" } },
	["ិះ"] = { ["ipa"] = { "eh", "ih" }, ["tc"] = { "eh", "ih" } }, --["tc"] inferred
	["ី"] = { ["ipa"] = { "əj", "iː" }, ["tc"] = { "əy", "ii" } },
	["ឹ"] = { ["ipa"] = { "ə", "ɨ" }, ["tc"] = { "ə", "ɨ" } },
	["ឹះ"] = { ["ipa"] = { "əh", "ɨh" }, ["tc"] = { "əh", "ɨh" } },
	["ឺ"] = { ["ipa"] = { "əɨ", "ɨː" }, ["tc"] = { "əɨ", "ɨɨ" } },
	["ុ"] = { ["ipa"] = { "oʔ", "uʔ" }, ["tc"] = { "oʼ", "uʼ" } }, --glottal coda only in stressed syllables
	["ុ2"] = { ["ipa"] = { "o", "u" }, ["tc"] = { "o", "u"  }}, --with non-glottal coda
	["ុះ"] = { ["ipa"] = { "oh", "uh" }, ["tc"] = { "oh", "uh" } },
	["ូ"] = { ["ipa"] = { "ou", "uː" }, ["tc"] = { "ou", "uu" } },
	["ូវ"] = { ["ipa"] = { "əw", "ɨw" }, ["tc"] = { "əw", "ɨw" } },
	["ួ"] = { ["ipa"] = { "uə", "uə" }, ["tc"] = { "uə", "uə" } },
	["ើ"] = { ["ipa"] = { "aə", "əː" }, ["tc"] = { "aə", "əə" } },
	["ើះ"] = { ["ipa"] = { "aəh", "əh" }, ["tc"] = { "əh", "" } },
	["ឿ"] = { ["ipa"] = { "ɨə", "ɨə" }, ["tc"] = { "ɨə", "ɨə" } },
	["ៀ"] = { ["ipa"] = { "iə", "iə" }, ["tc"] = { "iə", "iə" } },
	["េ"] = { ["ipa"] = { "eː", "ei" }, ["tc"] = { "ee", "ei" } },
	["េ2"] = { ["ipa"] = { "ə", "ɨ" }, ["tc"] = { "ə", "ɨ" } }, --before palatals
	["េះ"] = { ["ipa"] = { "eh", "ih" }, ["tc"] = { "eh", "ih" } },
	["ែ"] = { ["ipa"] = { "ae", "ɛː" }, ["tc"] = { "ae", "ɛɛ" } },
	["ែះ"] = { ["ipa"] = { "aeh", "ɛh" }, ["tc"] = { "eh", "" } },
	["ៃ"] = { ["ipa"] = { "aj", "ɨj" }, ["tc"] = { "ay", "ɨy" } },
	["ោ"] = { ["ipa"] = { "ao", "oː" }, ["tc"] = { "ao", "oo" } },
	["ោះ"] = { ["ipa"] = { "ɑh", "ŭəh" }, ["tc"] = { "ɑh", "ŭəh" } },
	["ៅ"] = { ["ipa"] = { "aw", "ɨw" }, ["tc"] = { "aw", "ɨw" } },
	["ុំ"] = { ["ipa"] = { "om", "um" }, ["tc"] = { "om", "um" } },
	["ំ"] = { ["ipa"] = { "ɑm", "um" }, ["tc"] = { "ɑm", "um" } },
	["ាំ"] = { ["ipa"] = { "am", "ŏəm" }, ["tc"] = { "am", "ŏəm" } },
	["ាំង"] = { ["ipa"] = { "aŋ", "ĕəŋ" }, ["tc"] = { "ang", "ĕəng" } },
	["ះ"] = { ["ipa"] = { "ah", "ĕəh" }, ["tc"] = { "ah", "ĕəh" } },
	["ៈ"] = { ["ipa"] = { "aʔ", "ĕəʔ" }, ["tc"] = { "aʼ", "ĕəʼ" } },
	["'"] = { ["ipa"] = { "ə", "ə" }, ["tc"] = { "ə", "ə" } },
}

local tl = {
	["ក"] = "k", ["ខ"] = "kʰ", ["គ"] = "g", ["ឃ"] = "gʰ", ["ង"] = "ṅ", 
	["ច"] = "c", ["ឆ"] = "cʰ", ["ជ"] = "j", ["ឈ"] = "jʰ", ["ញ"] = "ñ", 
	["ដ"] = "ṭ", ["ឋ"] = "ṭʰ", ["ឌ"] = "ḍ", ["ឍ"] = "ḍʰ", ["ណ"] = "ṇ", 
	["ត"] = "t", ["ថ"] = "tʰ", ["ទ"] = "d", ["ធ"] = "dʰ", ["ន"] = "n",
	["ប"] = "p", ["ផ"] = "pʰ", ["ព"] = "b", ["ភ"] = "bʰ", ["ម"] = "m",
	["យ"] = "y", ["រ"] = "r", ["ល"] = "l", ["វ"] = "v",
	["ឝ"] = "ś", ["ឞ"] = "ṣ", ["ស"] = "s", 
	["ហ"] = "h", ["ឡ"] = "ḷ", ["អ"] = "ʼ", 

	["ឣ"] = "a", ["ឤ"] = "ā", ["ឥ"] = "i", ["ឦ"] = "ī", 
	["ឧ"] = "u", ["ឨ"] = "uk", ["ឩ"] = "ū", ["ឪ"] = "uv", 
	["ឫ"] = "ṛ", ["ឬ"] = "ṝ", ["ឭ"] = "ḷ", ["ឮ"] = "ḹ", 
	["ឯ"] = "e", ["ឰ"] = "ai", ["ឱ"] = "o", ["ឲ"] = "o", ["ឳ"] = "au",
	
	["ា"] = "ā", ["ិ"] = "i", ["ី"] = "ī", ["ឹ"] = "ẏ", ["ឺ"] = "ȳ", 
	["ុ"] = "u", ["ូ"] = "ū", ["ួ"] = "ua",
	["ើ"] = "oe", ["ឿ"] = "ẏa", ["ៀ"] = "ia", 
	["េ"] = "e", ["ែ"] = "ae", ["ៃ"] = "ai", ["ោ"] = "o", ["ៅ"] = "au", 
	["ំ"] = "ṃ", ["ះ"] = "ḥ", ["ៈ"] = "`",
	
	["៉"] = "″", ["៊"] = "′", ["់"] = "´", ["៌"] = "ŕ", ["៍"] = "̊", 
	["៎"] = "⸗", ["៏"] = "ʿ", ["័"] = "˘", ["៑"] = "̑", ["្"] = "̥",
	["៓"] = "🤷", ["។"] = "ǂ", ["៕"] = "ǁ", ["៖"] = "🤷", ["ៗ"] = "«", 
	["៘"] = "🤷", ["៙"] = "§", ["៚"] = "»", ["៛"] = "", 
	["ៜ"] = "🤷", ["៝"] = "🤷",
	
	["០"] = "0", ["១"] = "1", ["២"] = "2", ["៣"] = "3", ["៤"] = "4", 
	["៥"] = "5", ["៦"] = "6", ["៧"] = "7", ["៨"] = "8", ["៩"] = "9", 
	["៰"] = "🤷", ["៱"] = "🤷", ["៲"] = "🤷", ["៳"] = "🤷", ["៴"] = "🤷",
	["៵"] = "🤷", ["៶"] = "🤷", ["៷"] = "🤷", ["៸"] = "🤷", ["៹"] = "🤷",
}

local glottify = {
	["a"] = 1, ["aː"] = 1, ["ɑ"] = 1, ["ɑː"] = 1, ["ɔ"] = 1, ["ɔː"] = 1,
	["ĕə"] = 1, ["ŭə"] = 1, ["iə"] = 1, ["ɨə"] = 1, ["uə"] = 1
}

local err = {
	["័"] = 1, ["័រ"] = 1,
}

local ambig = {
	["k%-h"] = "k​h", ["c%-h"] = "c​h", ["t%-h"] = "t​h", ["p%-h"] = "p​h",
	["n%-g"] = "n​g",
}

function export.syllabify(text)
	text = gsub(text, "([%'់])([^,%- ])", "%1-%2")
	local seq1 = cvCapt .. cCapt .. vCaptB
	while find(text, seq1) do text = gsub(text, seq1, "%1-%2%3") end
	return text
end

function export.syl_analysis(syllable)
	for ind = 4, 1, -1 do
		if match(syllable, "^" .. cCaptClus[ind] .. postInit .. "$") then
			return match(syllable, "^" .. cCaptClus[ind] .. postInit .. "$")
		end
	end
	return nil
end

local function sylRedist(text, block)
	for word in mw.ustring.gmatch(text, "[" .. kmChar .. "%-]+") do
		local originalWord = word
		local allSyl, syls, newWord = {}, mw.text.split(word, "%-"), {}
		for sylId = 1, #syls do
			if syls[sylId] == "" then table.insert(allSyl, {})
			else
				local set = export.syl_analysis(syls[sylId])
				if not set or set == "" then return nil end
				table.insert(allSyl, { export.syl_analysis(syls[sylId]) })
				if sylId ~= 1 and allSyl[sylId - 1][3] == "" and find(allSyl[sylId][1], j) and not block then
					allSyl[sylId - 1][3], allSyl[sylId][1] =
						match(allSyl[sylId][1], "^([^" .. j .. "]+)"),
						match(allSyl[sylId][1], "^[^" .. j .. "]+" .. j .. "(.+)")
				end
				if #syls == 2 and sylId == 2 and allSyl[sylId - 1][2] .. allSyl[sylId - 1][4] == "" then
					allSyl[sylId - 1][4] = vPost
				end
			end
		end
		for sylId = 1, #syls do
			table.insert(newWord, table.concat(allSyl[sylId]))
		end
		text = gsub(text, (gsub(originalWord, "%-", "%-")), table.concat(newWord, "%-"), 1)
	end
	return text
end

local function getCons(c1Set)
	local c1l, i, consSet = #c1Set, 1, {}
	while i < c1l + 1 do
		for j = 3, 1, -1 do
			local conss = i + j - 1 > c1l and "a" or table.concat(c1Set, "", i, i + j - 1)
			if consonants[conss] then
				table.insert(consSet, conss)
				i = i + j
				break
			end
			if j == 1 then return nil end
		end
	end
	return consSet
end

local function initClus(c1, mode)
	local fittest, init, cData, pos = "", {}, {}, 1
	c1 = gsub(c1, j, "")
	if consonants[c1] then
		local cData = consonants[c1]
		c1, fittest = cData[mode][pos], cData.class
	else
		local consSet = getCons(mw.text.split(c1, ""))
		if not consSet then return error("Error handling initial " .. c1 .. ".") end
		for seq, ch in ipairs(consSet) do
			local cData = consonants[ch]
			fittest = (not find(cData[mode][pos], recessive) and not find(cData[mode][pos], "ng")
				or (fittest == "" and seq == #consSet)) 
				and cData.class or fittest
			table.insert(init, cData[mode][pos])
		end
		c1 = table.concat(init)
	end
	
	c1 = gsub(c1, "[ɓb](.)", "p%1")
    --Very rare in native/Indic words, worst case can be respelt (ដ្បិត)​. Keep /d/ for borrowings from French / English (sodium, hydro-).
	--c1 = gsub(c1, "[ɗd](.)", "t%1")
	if mode == "ipa" then
		c1 = gsub(c1, "p([knŋcɲdtnjls])", "pʰ%1")
		c1 = gsub(c1, "pʰ([^knŋcɲdtnjls])", "p%1")
		c1 = gsub(c1, "t([kŋnmjlʋ])", "tʰ%1")
		c1 = gsub(c1, "tʰ([^kŋnmjlʋ])", "t%1")
		c1 = gsub(c1, "k([ctnbmlʋs])", "kʰ%1")
		c1 = gsub(c1, "kʰ([^ctnbmlʋs])", "k%1")
		c1 = gsub(c1, "c([kŋnmlʋʔ])", "cʰ%1")
		c1 = gsub(c1, "cʰ([^kŋnmlʋʔ])", "c%1")
	end
	return c1, fittest
end

local function rime(v1, c2, fittest, red, mode)
	if red == apos then v1 = red end
	if vowels[v1 .. c2] then return vowels[v1 .. c2][mode][fittest] end
	c2 = consonants[c2][mode][2] or c2
	if ((v1 == "័" or v1 == "ា់") and (find(c2, "[kŋ]") or c2 == "ng")) or
		(v1 == "េ" and (find(c2, "[cɲ]") or c2 == "ñ")) or
		(v1 == "់" and find(c2, "[mp]")) or
		((v1 == "ិ" or v1 == "ុ") and c2 ~= "") then
		v1 = v1 .. "2"
	end
	v1 = vowels[v1] and vowels[v1][mode][fittest] or v1
	if (glottify[v1] and mode == "ipa") and c2 == "k" then c2 = "ʡ" end --proxy
	return v1 .. c2
end

function export.convert(text, mode, source)
	local block = find(text, "%-")
	text = sylRedist(export.syllabify(text), block)
	if not text then return nil end
	
	for syllable in mw.ustring.gmatch(text, kmString) do
		local unchanged, sylStruc = syllable, {}
		local c1, v1, c2, bantak, red = export.syl_analysis(syllable)
		if not c1 then return nil end
		local fittest
		c1, fittest = initClus(c1, mode)
		if source == "temp" and (err[v1..c2] or err[v1]) then
			require("debug").track("km-pron/error-prone finals")
		end
		local v1c2 = rime(v1 .. bantak, c2, fittest, red, mode)
		if not v1c2 then return nil end
		text = gsub(text, unchanged, c1 .. v1c2, 1)
	end
	
	text = gsub(text, "(.%%%-.)", ambig)
	text = gsub(text, "%%", "")
	text = gsub(text, "%-", ".")
	text = gsub(text, "​", "-")
	text = gsub(text, "ʔ([ptkhlɲŋmnjw])", "%1")
	text = gsub(text, "ŭə%.", "ɔ.")
	text = gsub(text, "([eiou])[ʔʼ]%.", "%1.")
	text = gsub(text, "ʡ%.s", "k.s")
	text = gsub(text, "ʡ", "ʔ")
	if mode == "tc" then
		text = gsub(text, "%.%.%.", "…")
		text = gsub(text, "%.", "")
	else
		text = gsub(text, "%-", ".")
		local readings = {}
		for reading in mw.text.gsplit(text, ", ") do
			table.insert(readings, (gsub(reading, "^([^%.]+)%.([^%.]+)$", "%1.ˈ%2")))
		end
		text = table.concat(readings, ", ")
		text = gsub(text, "^([^%. ]+) ([^%. ]+)$", "%1 ˈ%2")
	end
	return text
end

local function return_error()
	return error("The entry title or respelling contains zero-space width character. Please remove it.")
end

function export.make(frame)
	local params = {
		[1] = { list = true },
		["a"] = {},
		["audio"] = { alias_of = "a" },
		["word"] = { default = pagename },
	}
	local args = require("parameters").process(frame:getParent().args, params)
	local output_text, respellings, transcriptions, ipas = {}, {}, {}, {}
	
	if find(pagename, "​") then return_error() end
	if #args[1] == 0  then args[1] = { args.word } end
	for _, param in ipairs(args[1]) do
		if find(param, "​") then return_error() end
		table.insert(respellings, export.syllabify(param))
		table.insert(transcriptions, export.convert(param, "tc", "temp"))
		table.insert(ipas, export.convert(param, "ipa"))
	end
	separate = (gsub(table.concat(respellings), "[%- ]", "")) ~= args.word
	respelling = table.concat(respellings, " / ")
	
	local function row(a, b, class, lang, size)
		return "\n<tr>" .. 
			
		tostring( mw.html.create( "td" )
			:css( "padding-right", "0.8em" )
			:css( "padding-left", "0.7em" )
			:css( "font-size", "10.5pt" )
			:css( "color", "#555" )
			:css( "font-weight", "bold" )
			:css( "background-color", "#F8F9F8" )
			:wikitext(a)) .. "\n" ..
		
		tostring( mw.html.create( "td" )
			:css( "padding-left", "0.8em" )
			:css( "padding-right", "0.8em" )
			:css( "padding-top", ".4em" )
			:css( "padding-bottom", ".4em" )
			:wikitext(b)) ..
		
		"</tr>"
	end
	
	local function textFormat(text, class, size, lang)
		return tostring( mw.html.create( "span" )
			:attr( "class", class or "Khmr" )
			:css( "font-size", size or (class == "IPA" and "95%" or "130%") )
			:attr( "lang", lang or (class == "IPA" and nil or "km") )
			:wikitext(text))
	end
	
	table.insert(output_text, 
	[=[{| style="margin: 0 .4em .4em .4em"
	|
	<table cellpadding=1 style="border: 1px solid #DFDFDF; text-align: center; line-height: 25pt; padding: .1em .3em .1em .3em">]=] ..

	row(separate
			and "''[[w:Khmer alphabet|Orthographic]]''"
			or "''[[w:Khmer alphabet|Orthographic and Phonemic]]''", 
		textFormat(args.word) .. "<br>" .. textFormat(gsub(gsub(args.word, ".", tl), "ʰ̥", "̥ʰ"), "IPA")
	) ..
	
	(separate
		and row("''[[w:Khmer alphabet|Phonemic]]''", 
			textFormat(respelling) .. "<br>" ..
			textFormat(gsub(gsub(respelling, ".", tl), "ʰ̥", "̥ʰ"), "IPA"))
		or "") ..
	
	row("''[[Wiktionary:Khmer romanization|WT romanisation]]''",
		textFormat(table.concat(transcriptions, ", "), "IPA", "100%")
	) ..
	
	row(
		"(''[[w:Khmer language|standard]]'') [[Wiktionary:International Phonetic Alphabet|IPA]]" .. 
		"<sup>([[Wiktionary:Khmer romanization|key]])</sup>",
		textFormat("/" .. table.concat(ipas, "/ ~ /") .. "/", "IPA", "110%")
	) ..
	
	(args.a 
		and row("Audio", mw.getCurrentFrame():expandTemplate{ 
			title = "Template:audio", 
			args = { args.a == "y" and "Km-" .. args.word .. ".ogg" or args.a, lang = "km" }} )
		or ""
	) ..

	"</table>\n|}" .. "[[Category:Khmer terms with IPA pronunciation]]")
	
	return table.concat(output_text)
end

return export