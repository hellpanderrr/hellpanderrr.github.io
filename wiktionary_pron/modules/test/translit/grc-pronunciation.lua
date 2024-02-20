local export = {}

local mark_implied_length = require('grc-accent').mark_implied_length
local strip_accent = require('grc-accent').strip_accent
-- [[Module:grc-utilities]] converts sequences of diacritics to the order required by this module,
-- then replaces combining macrons and breves with spacing ones.
local m_utils = require("grc-utilities")
local m_general_utils = require("utilities")
local rearrangeDiacritics = m_utils.pronunciationOrder
local m_utils_data = require("grc-utilities/data")
local diacritics = m_utils_data.diacritics
local m_data = mw.loadData("grc-pronunciation/data")
local m_IPA = require("IPA")
local m_a = require("accent qualifier")
local lang = require("languages").getByCode("grc")
local sc = require("scripts").getByCode("Polyt")

local full_link = m_utils.link
local tag_text = m_utils.tag

local periods = {'cla', 'koi1', 'koi2', 'byz1', 'byz2'}
local inlinePeriods = {'cla', 'koi2', 'byz2'}

local title = mw.title.getCurrentTitle()
local pagename = title.text
local namespace = title.nsText

local rsplit = mw.text.split
local rfind = mw.ustring.find
local usub = mw.ustring.sub
local rmatch = mw.ustring.match
local rsubn = mw.ustring.gsub
local ulen = mw.ustring.len
local ulower = mw.ustring.lower
local U = mw.ustring.char
local function fetch(s, i)
	--[==[
	because we fetch a single character at a time so often
	out of bounds fetch gives ''
	]==]
	i = tonumber(i)
	
	if type(i) ~= "number" then
		error("fetch requires a number or a string equivalent to a number as its second argument.")
	end
	
	if i == 0 then
		return ""
	end
	
	local n = 0
	for character in string.gmatch(s, "[\1-\127\194-\244][\128-\191]*") do
		n = n + 1
		if n == i then
			return character
		end
	end
	
	return ""
end

--Combining diacritics are tricky.
local tie = U(0x35C)				-- tie bar
local nonsyllabic = U(0x32F)		-- combining inverted breve below
local high = U(0x341)				-- combining acute tone mark
local low = U(0x340)				-- combining grave tone mark
local rising = U(0x30C)				-- combining caron
local falling = diacritics.Latin_circum	-- combining circumflex
local midHigh = U(0x1DC4)			-- mid–high pitch
local midLow = U(0x1DC6)			-- mid–low pitch
local highMid = U(0x1DC7)			-- high–mid pitch
local voiceless = U(0x325)			-- combining ring below
local aspirated = 'ʰ'
local macron = '¯'
local breve = '˘'

local function is(text, X)
	if not text or not X then
		return false
	end
	pattern = m_data.chars[X] or error('No data for "' .. X .. '".', 2)
	if X == "frontDiphth" or X == "Greekdiacritic" then
		pattern = "^" .. pattern .. "$"
	else
		pattern = "^[" .. pattern .. "]$"
	end
	return rfind(text, pattern)
end

local env_functions = {
	preFront = function(term, index)
		local letter1, letter2 = fetch(term, index + 1), fetch(term, index + 2)
		return is(strip_accent(letter1), "frontVowel") or (is(strip_accent(letter1 .. letter2), "frontDiphth") and not is(letter2, "iDiaer"))
	end,
	isIDiphth = function(term, index)
		local letter = fetch(term, index + 1)
		return strip_accent(letter) == 'ι' and not m_data[letter].diaer
	end,
	isUDiphth = function(term, index)
		local letter = fetch(term, index + 1)
		return strip_accent(letter) == 'υ' and not m_data[letter].diaer
	end,
	hasMacronBreve = function(term, index)
		return fetch(term, index + 1) == macron or fetch(term, index + 1) == breve
	end,
}

local function decode(condition, x, term)
	--[==[
		"If" and "and" statements.
		Note that we're finding the last operator first, 
		which means that the first will get ultimately get decided first.
		If + ("and") or / ("or") is found, the function is called again,
		until if-statements are found.
		In if-statements:
		* A number represents the character under consideration:
			 -1 is the previous character, 0 is the current, and 1 is the next.
		* Equals sign (=) checks to see if the character under consideration
			is equal to a character.
		* Period (.) plus a word sends the module to the corresponding entry
			in the letter's data table.
		* Tilde (~) calls a function on the character under consideration,
			if the function exists.
	]==]
	if rfind(condition, '[+/]') then
		-- Find slash or plus sign preceded by something else, and followed by anything
		-- (including another sequence of slash or plus sign and something else).
		local subcondition1, sep, subcondition2 = rmatch(condition, "^([^/+]-)([/+])(.*)$")
		if not (subcondition1 or subcondition2) then
			error('Condition "' .. tostring(condition) .. '" is improperly formed')
		end
		
		if sep == '/' then		-- logical operator: or
			return decode(subcondition1, x, term) or decode(subcondition2, x, term)
		elseif sep == '+' then	-- logical operator: and
			return decode(subcondition1, x, term) and decode(subcondition2, x, term)
		end
	elseif rfind(condition, '=') then				-- check character identity
		local offset, char = unpack(rsplit(condition, "="))
		if namespace == "Module" or namespace == "Template" then
			mw.log(term, offset, char, x + offset, fetch(term, x + offset), char == fetch(term, x + offset) )
		end
		return char == fetch(term, x + offset) -- out of bounds fetch gives ''
	elseif rfind(condition, '%.') then				-- check character quality
		local offset, quality = unpack(rsplit(condition, "%."))
		local character = fetch(term, x + offset)
		return m_data[character] and m_data[character][quality] or false
	elseif rfind(condition, '~') then				-- check character(s) using function
		local offset, func = unpack(rsplit(condition, "~"))
		return env_functions[func] and env_functions[func](term, x + offset) or false
	end
end

local function check(p, x, term)
	if type(p) == 'string' or type(p) == 'number' then
		return p
	elseif type(p) == 'table' then   --This table is sequential, with a variable number of entries.
		for _, possP in ipairs(p) do
			if type(possP) == 'string' or type(possP) == 'number' then
				return possP
			elseif type(possP) == 'table' then    --This table is paired, with two values: a condition and a result.
				rawCondition, rawResult = possP[1], possP[2]
				if decode(rawCondition, x, term) then
					return (type(rawResult) == 'string') and rawResult or check(rawResult, x, term)
				end	
			end
		end
	else
		error('"p" is of unrecongized type ' .. type(p))
	end
end

local function convert_term(term, periodstart)
	if not term then error('The variable "term" in the function "convert_term" is nil.') end
	local IPAs = {}
	local start
	local outPeriods = {}
	if periodstart and periodstart ~= "" then
		start = false
	else
		start = true
	end
	for _, period in ipairs(periods) do 
		if period == periodstart then
			start = true
		end
		if start then
			IPAs[period] = {}
			table.insert(outPeriods, period)
		end
	end
	local length, x, advance, letter, p = ulen(term), 1, 0, '', nil
	while x <= length do
		letter = fetch(term, x)
		local data = m_data[letter]
		if not data then		-- no data found
			-- explicit pass
		else
			-- check to see if a multicharacter search is warranted
			advance = data.pre and check(data.pre, x, term) or 0
			p = (advance ~= 0) and m_data[usub(term, x, x + advance)].p or data.p
			for _, period in ipairs(outPeriods) do
				table.insert(IPAs[period], check(p[period], x, term))
			end
			x = x + advance
		end
		x = x + 1
	end
	
	--Concatenate the IPAs
	for _, period in ipairs(outPeriods) do
		IPAs[period] = { IPA = table.concat(IPAs[period], '')}
	end
	
	return IPAs, outPeriods
end

local function find_syllable_break(word, nVowel, wordEnd)
	if not word then error('The variable "word" in the function "find_syllable_break" is nil.') end
	if wordEnd then
		return ulen(word)
	elseif is(fetch(word, nVowel - 1), "liquid") then
		if is(fetch(word, nVowel - 2), "obst") then
			return nVowel - 3
		elseif fetch(word, nVowel - 2) == aspirated and is(fetch(word, nVowel - 3), "obst") then
			return nVowel - 4
		else
			return nVowel - 2
		end
	elseif is(fetch(word, nVowel - 1), "cons") then
		return nVowel - 2
	elseif fetch(word, nVowel - 1) == aspirated and is(fetch(word, nVowel - 2), "obst") then
		return nVowel - 3
	elseif fetch(word, nVowel - 1) == voiceless and fetch(word, nVowel - 2) == 'r' then
		return nVowel - 3
	else
		return nVowel - 1
	end
end

local function syllabify_word(word)
	local syllables = {}
	--[[	cVowel means "current vowel", nVowel "next vowel",
			sBreak "syllable break".							]]--
	local cVowel, nVowel, sBreak, stress, wordEnd, searching
	while word ~= '' do
		cVowel, nVowel, sBreak, stress = false, false, false, false
		
		--First thing is to find the first vowel.
		searching = 1
		cVowelFound = false
		while not cVowel do
			letter = fetch(word, searching)
			local nextLetter = fetch(word, searching + 1)
			if cVowelFound then
				if (is(letter, "vowel") and nextLetter ~= nonsyllabic) or is(letter, "cons") or letter == '' or letter == 'ˈ' then
					cVowel = searching - 1
				elseif is(letter, "diacritic") then
					searching = searching + 1
				elseif letter == tie then
					cVowelFound = false
					searching = searching + 1
				else
					searching = searching + 1
				end
			else
				if is(letter, "vowel") then
					cVowelFound = true
				elseif letter == 'ˈ' then
					stress = true
				end
				searching = searching + 1
			end
		end
	
		--Next we try and find the next vowel or the end.
		searching = cVowel + 1
		while (not nVowel) and (not wordEnd) do
			letter = fetch(word, searching)
			if is(letter, "vowel") or letter == 'ˈ' then
				nVowel = searching
			elseif letter == '' then
				wordEnd = true
			else
				searching = searching + 1
			end
		end
		
		--Finally we find the syllable break point.
		sBreak = find_syllable_break(word, nVowel, wordEnd)
		
		--Pull everything up to and including the syllable Break.
		local syllable = usub(word, 1, sBreak)
		
		--If there is a stress accent, then we need to move it to the 
		--beginning of the syllable, unless it is a monosyllabic word,
		--in which case we remove it altogether.
		if stress then
			if next(syllables) or syllable ~= word then
				syllable = 'ˈ' .. rsubn(syllable, 'ˈ', '')
			else 
				syllable = rsubn(syllable, 'ˈ', '')
			end
			stress = false
		end
		table.insert(syllables, syllable)
		word = usub(word, sBreak + 1)
	end
	
	local out = nil
	
	if #syllables > 0 then
		out = table.concat(syllables, '.')
		out = rsubn(out, '%.ˈ', 'ˈ')
	end
	return out
end

local function syllabify(IPAs, periods)
	--Syllabify
	local word_ipa = ''
	local ipa = {}
	for _, period in ipairs(periods) do
		ipa = {}
		for _, word in ipairs(rsplit(IPAs[period].IPA, ' ')) do
			word_ipa = syllabify_word(word)
			if word_ipa then
				table.insert(ipa, word_ipa)
			end
		end
		IPAs[period].IPA = table.concat(ipa, ' ')
	end
	return IPAs
end

local function make_ambig_note(ambig, ambig_letter_list)
	-- The table ambig is filled with all the ambiguous vowels that have been found in the term.
	local ambig_note = ''
	if ambig and #ambig > 0 then
		local agr = (#ambig > 1) and { 's ', 'each one' } or { ' ', 'it' }
			
		ambig_note = '\n<p class="previewonly">Mark the vowel length of the ambiguous vowel' .. agr[1]
			.. mw.text.listToText(ambig) .. ' by adding a macron after ' .. agr[2]
			.. ' if it is long, or a breve if it is short. By default, [[Module:grc-pronunciation]] assumes it is short if unmarked.'
			.. '<br/><small>[This message shows only in preview mode.]</small>'
			.. m_general_utils.format_categories(
				{ 'Ancient Greek terms with incomplete pronunciation' }, lang)
			..'</p>\n'
	end
	return ambig_note
end

local function make_table(IPAs, ambig, periods, ambig_letter_list)
	--Final format
	local inlineProns = {}
	local listOfProns = {}
	local fullProns = {}
	local periods2 = {}
	
	for _, period in ipairs(periods) do
		table.insert(fullProns, '* ' .. m_a.show({'grc-' .. period}) .. ' ' ..  m_IPA.format_IPA_full(lang, {{pron = '/' .. IPAs[period].IPA .. '/'}}))
		periods2[period] = true
	end
	
	for _, period in ipairs(inlinePeriods) do
		if periods2[period] then
			local pron = '/' .. IPAs[period].IPA .. '/'
			table.insert(inlineProns, {pron = pron})
			table.insert(listOfProns, pron)
		end
	end
	
	local inlineIPAlength = math.floor( math.max( ulen("IPA(key): " .. table.concat(listOfProns, ' → ') or "") * 0.68, ulen("(15th AD Constantinopolitan) IPA(key): /" .. IPAs.byz2.IPA .. "/") * 0.68 ) )
	
	local inline = '\n<div class="vsShow" style="display:none">\n* ' .. m_IPA.format_IPA_full(lang, inlineProns, nil, ' → ') .. '</div>'
	
	local full = '\n<div class="vsHide">\n' .. table.concat(fullProns, '\n') .. make_ambig_note(ambig, ambig_letter_list) .. '</div>'
	
	return '<div class="vsSwitcher" data-toggle-category="pronunciations" style="width: ' .. inlineIPAlength .. 'em; max-width:100%;"><span class="vsToggleElement" style="float: right;">&nbsp;</span>' .. inline .. full .. '</div>'
end

function export.create(frame)
	local params = {
		[1] = {default = pagename},
		["period"] = {default = "cla"},
	}
	local args = require("parameters").process(frame.getParent and frame:getParent().args or frame, params, nil, "grc-pronunciation", "create")
	
	local term = ulower(args[1])
	local old = term
	term = m_utils.standardDiacritics(term)
	term = mark_implied_length(term)
	--[[
	if mw.ustring.toNFD(old) ~= term then
		mw.log(old .. " > " .. term)
	end
	]]
	
	local decomposed = mw.ustring.toNFD(term)
	if rfind(decomposed, "[εοηω]" .. m_utils_data.diacritic .. "*[" .. diacritics.spacing_macron .. diacritics.spacing_breve .. diacritics.breve .. diacritics.macron .. "]") then
		error("Macrons and breves cannot be placed after the letters ε, ο, η, or ω.")
	end
	
	local ambig, ambig_letter_list
	if args.period == "cla" then
		ambig, ambig_letter_list = m_utils.findAmbig(term)
	end
	term = rsubn(term, 'ς', 'σ')
	term = rsubn(term, 'ῤ', 'ρ')
	term = rearrangeDiacritics(term)
	
	local IPAs, periods = convert_term(term, args.period)
	
	IPAs = syllabify(IPAs, periods)
	
	return make_table(IPAs, ambig, periods, ambig_letter_list)
end

function export.example(frame)
	local output = { '{| class="wikitable"' }
	
	local params = {
		[1] = {}
	}
	
	local args = require("parameters").process(frame:getParent().args, params, nil, "grc-pronunciation", "example")
	
	local terms = mw.text.split(args[1], ",%s+")
	
	for _, term in pairs(terms) do
		local period = rmatch(term, "%(period ?= ?([^%)]+)%)") or "cla"
		local entry = rmatch(term, "([^%(]+) %(") or term or error('No term found in "' .. term .. '".') 
		local link = full_link(entry)
		local IPA = export.create{ entry, ["period"] = period }
		table.insert(output, "\n|-\n| " .. link .. " || " .. IPA)
	end
	
	table.insert(output, "\n|}")
	
	return table.concat(output)
end

return export
--Things we still need:
--Voicing of sigma around (after?) voiced stops. 
--Proper alerts for editors, especially on ambiguous vowels.