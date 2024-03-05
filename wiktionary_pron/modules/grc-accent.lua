local export = {}

local m_data = mw.loadData("grc-utilities/data")
local m_table = require("table")

local diacritics_list = m_data.diacritics
local ACUTE = diacritics_list.acute
local GRAVE = diacritics_list.grave
local CIRCUMFLEX = diacritics_list.circum
local DIAERESIS = diacritics_list.diaeresis
local SMOOTH = diacritics_list.smooth
local ROUGH = diacritics_list.rough
local MACRON = diacritics_list.macron
local BREVE = diacritics_list.breve
local SUBSCRIPT = diacritics_list.subscript

local diacritic_pattern = m_data.all
local diacritic_groups = m_data.diacritic_groups
local tonal_diacritic = diacritic_groups[3] -- acute, grave, circumflex
local long_diacritics = MACRON .. SUBSCRIPT .. CIRCUMFLEX

local either_vowel = "[ΑαΙιΥυ]"

local find = mw.ustring.find
local gsub = mw.ustring.gsub
local match = mw.ustring.match
local lower = mw.ustring.lower
local decompose = mw.ustring.toNFD

local tokenize = require('grc-utilities').tokenize
local copy = m_table.shallowcopy

local function if_not_empty(var)
	if var == "" then
		return nil
	else
		return var
	end
end

local function contains_vowel(token)
	return find(token, '[ΑΕΗΙΟΥΩαεηιουω]')
end

export.contains_vowel = contains_vowel

local function is_diphthong(token)
	if find(token, "[ΑαΕεΗηΙιΟοΥυΩω][ΙιΥυ]") then
		return true
	else
		return false
	end
end

local libraryUtil = require('libraryUtil')
local checkType = libraryUtil.checkType
local checkTypeMulti = libraryUtil.checkTypeMulti

local function _check(funcName, expectType)
	if type(expectType) == "string" then
		return function(argIndex, arg, nilOk)
			checkType(funcName, argIndex, arg, expectType, nilOk)
		end
	else
		return function(argIndex, arg, expectType, nilOk)
			if type(expectType) == "table" then
				checkTypeMulti(funcName, argIndex, arg, expectType, nilOk)
			else
				checkType(funcName, argIndex, arg, expectType, nilOk)
			end
		end
	end
end

--[[
	A vowel with a breve or a lone epsilon or omicron is considered short.
	Everything else is considered long, including unmarked alphas, iotas, and
	upsilons. Sigh.
]]
local function is_short(token)
	if find(token, BREVE) or find(token, '[ΕΟεο]') and not find(token, '[ιυ]') then
		return true
	else
		return false
	end
end

local function conditional_gsub(...)
	local str, count = gsub(...)
	if count and count > 0 then
		return str
	else
		return nil
	end
end

local accent_adding_functions = {
	-- This will not throw an error if η or ω has a macron on it.
	[CIRCUMFLEX] = function(vowel)
		return (gsub(
			vowel,
			"([ΑαΗηΙιΥυΩω])" .. MACRON .. "?(" .. diacritic_groups[2] .. "?)(" .. SUBSCRIPT .. "?)$",
			"%1%2" .. CIRCUMFLEX .. "%3"
		))
	end,
	[ACUTE] = function(vowel)
		return (
			conditional_gsub(vowel,
				"([Εε])([Ωω])",
				"%1" .. ACUTE .. "%2") or
			gsub(vowel,
				"([ΑαΕεΗηΙιΟοΥυΩω]" .. diacritic_groups[1] .. "?" .. diacritic_groups[2] .. "?)(" .. SUBSCRIPT .. "?)$",
				"%1" .. ACUTE .. "%2"))
	end,
	[MACRON] = function(vowel)
		if find(vowel, "[" .. long_diacritics .. "]") or is_diphthong(vowel) then
			return vowel
		elseif find(vowel, "[ΕΟεο]") then
			error("The vowel " .. vowel ..
					" is short, so a macron cannot be added to it.")
		else
			return (gsub(vowel, "(" .. either_vowel .. ")", "%1" .. MACRON))
		end
	end,
	[BREVE] = function(vowel)
		if find(vowel, "[" .. long_diacritics .. "]") then
			error("The vowel " .. vowel ..
					" has a iota subscript, a macron, or a circumflex, so a breve cannot be added to it.")
		elseif is_diphthong(vowel) then
			error("The vowel " .. vowel ..
					" is a diphthong, so a breve cannot be added to it.")
		else
			return (gsub(vowel, "(" .. either_vowel .. ")", "%1" .. BREVE))
		end
	end,
	-- This will insert a diaeresis on a single iota or upsilon, or on a
	-- iota or upsilon that is the second element of a diphthong.
	-- It does nothing if the vowel has a breathing on it.
	[DIAERESIS] = function(vowel)
		return (gsub(
			vowel,
			"([ΙιΥυ]" .. diacritic_groups[1] .. "?)(" .. tonal_diacritic .. "?)$",
			"%1" .. DIAERESIS .. "%2"
		))
	end
}

-- Assumes decomposed vowels (NFD).
local function add(vowel, accent)
	if type(accent_adding_functions[accent]) == "function" then
		return accent_adding_functions[accent](vowel)
	else
		local name = m_table.keyFor(diacritics_list, accent)
		if name == "circum" then
			name = "circumflex"
		end
		error("No function for adding a " .. name .. ".")
	end
end

function export.strip_accent(word)
	word = decompose(word)
	-- Parentheses suppress second return value of gsub, the number of substitutions.
	return (gsub(word, diacritic_pattern, ''))
end

function export.strip_tone(word)
	word = decompose(word)
	if find(word, CIRCUMFLEX) then
		word = copy(tokenize(word))
		for i = 1, #word do
			-- Add a macron to every vowel with a circumflex and remove the circumflex.
			word[i] = gsub(word[i],
				'^([αΑιΙυΥ])([' .. SMOOTH .. ROUGH .. DIAERESIS .. ']*)' .. CIRCUMFLEX .. '$',
				'%1' .. MACRON .. '%2')
		end
		word = table.concat(word)
	end
	return (gsub(word, tonal_diacritic, ''))
end

function export.ult(word)
	word = decompose(word)
	if find(word, tonal_diacritic) then return word end
	
	word = copy(tokenize(word))
	for i, token in m_table.reverseIpairs(word) do
		if contains_vowel(token) then
			--fortunately accents go last in combining order
			word[i] = add(token, ACUTE)
			break
		end
	end
	return table.concat(word, '')
end

--[[ WARNING: Given an unmarked α ι υ, this function will return a circmflex.
That said, if you ran into this situation in the first place, you probably
are doing something wrong. ]] --
function export.circ(word)
	word = decompose(word)
	if find(word, tonal_diacritic) then return word end
	
	word = copy(tokenize(word))
	for i, token in m_table.reverseIpairs(word) do
		if contains_vowel(token) then
			if is_short(token) then
				word[i] = add(token, ACUTE)
			else
				word[i] = add(token, CIRCUMFLEX)
			end
			break
		end
	end
	return table.concat(word, '')
end

function export.penult(orig)
	local word = decompose(orig)
	if find(word, tonal_diacritic) then return word end
	
	word = copy(tokenize(word))
	local syllables = 0
	for i, token in m_table.reverseIpairs(word) do
		if token == '-' then
			return orig
		elseif contains_vowel(token) then
			syllables = syllables + 1
			if syllables == 2 then
				word[i] = add(token, ACUTE)
				return table.concat(word, '')
			end
		end
	end
	
	return export.circ(orig)
end

function export.pencirc(orig)
	local word = decompose(orig)
	if find(word, tonal_diacritic) then return word end
	
	word = copy(tokenize(word))
	local syllables = 0
	local long_ult = false
	for i, token in m_table.reverseIpairs(word) do
		if token == '-' then return orig end
		if contains_vowel(token) then
			syllables = syllables + 1
			if syllables == 1 and not is_short(token) then
				long_ult = true
				if word[#word] == 'αι' or word[#word] == 'οι' then long_ult = false end
			elseif syllables == 2 then
				if is_short(token) or long_ult then
					word[i] = add(token, ACUTE)
				else
					word[i] = add(token, CIRCUMFLEX)
				end
				return table.concat(word, '')
			end
		end
	end
	
	return export.circ(orig)
end

function export.antepenult(orig)
	local word = decompose(orig)
	if find(word, tonal_diacritic) then return word end
	
	word = copy(tokenize(word))
	local syllables = 0
	local long_ult = false
	for i, token in m_table.reverseIpairs(word) do
		if token == '-' then return orig end
		if contains_vowel(token) then
			syllables = syllables + 1
			if syllables == 1 and not is_short(token) then
				long_ult = true
				if word[#word] == 'αι' or word[#word] == 'οι' then long_ult = false end
			elseif syllables == 2 and long_ult then
				word[i] = add(token, ACUTE)
				return table.concat(word, '')
			elseif syllables == 3 then
				word[i] = add(token, ACUTE)
				return table.concat(word, '')
			end
		end
	end
	
	return export.pencirc(orig)
end

--[[
	Counts from the beginning or end of the word, and returns the position and
	type of the first accent found. Position means the number of vowels
	(syllables) that have been encountered, not the number of characters.
	
	Arguments:
	- word:			string	(Ancient Greek word)
	- from_end:		boolean	(whether to count from the end of the word)
]]
local accent_cache = { [true] = {}, [false] = {} }

function export.detect_accent(word, from_end)
	local check = _check("detect_accent")
	check(1, word, "string")
	check(2, from_end, "boolean", true)
	
	local cache = accent_cache[from_end == true][decompose(word)]
	if cache then
		return unpack(cache)
	end
	
	local names = {
		[ACUTE] 		= "acute",
		[GRAVE] 		= "grave",
		[CIRCUMFLEX]	= "circumflex",
	}
	
	local syllable = 0
	local accent_name
	
	for _, token in
			(from_end and m_table.reverseIpairs or ipairs)(tokenize(word))
			do
		if contains_vowel(token) then
			syllable = syllable + 1
			
			accent_name = names[match(token, tonal_diacritic)]
			if accent_name then
				accent_cache[from_end == true][decompose(word)] = { syllable, accent_name }
				return syllable, accent_name
			end
		end
	end
	
	return nil
end

--[[
	Returns classification based on first accent found
	when traveling back from the end of the word.
]]
function export.get_accent_term(word)
	local syllable, accent_name = export.detect_accent(word, true)
	
	local terms = {
		["grave"]		= { "barytone" },
		["acute"] 		= { "oxytone", "paroxytone", "proparoxytone" },
		["circumflex"]	= { "perispomenon", "properispomenon" },
	}
	
	local ordinals = { "first", "second", "third", "fourth", "fifth", }
	
	local term
	if syllable and accent_name then
		term = terms[accent_name][syllable]
	end
	
	if term then
		return term
	else
		return nil,
			syllable and 'There is no term for a word with a ' .. accent_name ..
				' accent on the ' .. ordinals[syllable] ..
				' syllable from the end of the word.'
			or 'No accent found.'
	end
end

-- is_noun is a boolean or nil; if it is true, αι and οι will be
-- treated as short.
function export.get_length(token, short_diphthong)
	local token = lower(token)
	-- not needed at the moment
	-- token = decompose(token)
	
	if not contains_vowel(token) then
		return nil
		-- error("The thing supplied to get_length does not have any vowels")
	end
	
	-- η, ω; ᾳ, ῃ, ῳ; ᾱ, ῑ, ῡ; diphthongs
	if find(token, "[ηω" .. long_diacritics .. "]") then
		return "long"
	end
	
	if short_diphthong and find(token, "^[αο]ι") then
		return "short"
	end
	
	if is_diphthong(token) then
		return "long"
	end
	
	-- ε, ο; ᾰ, ῐ, ῠ
	if find(token, "[εο" .. BREVE .. "]") then
		return "short"
	end
	
	-- anything else
	return "either"
end

-- Takes a table of tokens and returns a table containing tables of each vowel's
-- characteristics.
function export.get_vowel_info(tokens, short_diphthong)
	if type(tokens) ~= "table" then
		error("The argument to get_vowel_info must be a table.")
	end
	
	local vowels = {}
	local vowel_i = 1
	if find(tokens[#tokens], m_data.consonant .. "$") then
		short_diphthong = false
	end
	
	for i, token in m_table.reverseIpairs(tokens) do
		if contains_vowel(token) then
			if vowel_i ~= 1 then
				short_diphthong = false
			end
			local length, accent =
				export.get_length(token, short_diphthong),
				if_not_empty(match(token,
					"[" .. ACUTE .. GRAVE .. CIRCUMFLEX .. "]"))
			vowels[vowel_i] = {
					index = i,
					length = length,
					accent = accent,
			}
			vowel_i = vowel_i + 1
		end
	end
	
	return vowels
end

function export.mark_implied_length(word, return_tokens, short_diphthong)
	word = decompose(word)
	-- Do nothing if there are no vowel letters that could be ambiguous.
	if not find(word, either_vowel) then
		if return_tokens then
			return tokenize(word)
		else
			return word
		end
	end
	local tokens = copy(tokenize(word))
	local vowels = export.get_vowel_info(tokens, short_diphthong)
	if #vowels >= 2 then
		local ultima = vowels[1]
		local ultima_i = ultima.index
		
		local penult = vowels[2]
		local penult_i = penult.index
		
		if penult.length == "either" and ultima.length == "short" then
			if penult.accent == CIRCUMFLEX then
				tokens[penult_i] = add(tokens[penult_i], MACRON)
			elseif penult.accent == ACUTE then
				tokens[penult_i] = add(tokens[penult_i], BREVE)
			end
		elseif penult.length == "long" and ultima.length == "either" then
			if penult.accent == CIRCUMFLEX then
				tokens[ultima_i] = add(tokens[ultima_i], BREVE)
			elseif penult.accent == ACUTE then
				tokens[ultima_i] = add(tokens[ultima_i], MACRON)
			end
		end
		
		local antepenult = vowels[3]
		if antepenult and antepenult.accent and ultima.length == "either" then
			tokens[ultima_i] = add(tokens[ultima_i], BREVE)
		end
	end
	if return_tokens then
		return tokens
	else
		return table.concat(tokens)
	end
end

-- Returns the length of a syllable specified by its position from the end of the word.
function export.length_at(word, syllable)
	local tokens = tokenize(word)
	
	if type(word) ~= "string" then
		error("First argument of length_at should be a string.")
	end
	
	if type(syllable) ~= "number" then
		error("Second argument of length_at should be a number.")
	end
	
	local syllable_count = 0
	for _, token in m_table.reverseIpairs(tokens) do
		local length = export.get_length(token)
		if length then
			syllable_count = syllable_count + 1
			if syllable_count == syllable then
				return length
			end
		end
	end
	
	if syllable_count < syllable then
		error("Length for syllable " .. syllable .. " from the end of the word was not found.")
	end
end

local function find_breathing(token)
	return match(token, "([" .. ROUGH .. SMOOTH .. "])")
end

local function has_same_breathing_as(token1, token2)
	return find_breathing(token1) == find_breathing(token2)
end

-- Make token have the length specified by the string "length".
local function change_length(length, token)
	local diacritic
	if length == "long" then
		diacritic = MACRON
	elseif length == "short" then
		diacritic = BREVE
	end
	
	if diacritic then
		return add(token, diacritic)
	else
		return token
	end
end

--[[
	Take two words, mark implied length on each, then harmonize any macrons and
	breves that disagree.
]]
function export.harmonize_length(word1, word2)
	word1 = decompose(word1)
	-- Do nothing if there are no vowel letters that could be ambiguous.
	if not (find(word1, either_vowel) or find(word2, either_vowel)) then
		return word1, word2
	end
	
	local tokens1, tokens2 = export.mark_implied_length(word1, true), export.mark_implied_length(word2, true)
	local strip1, strip2 = copy(tokenize(export.strip_accent(word1))), copy(tokenize(export.strip_accent(word2)))
	
	for i, token1 in pairs(tokens1) do
		local token2 = tokens2[i]
		
		if strip1[i] == strip2[i] then
			if has_same_breathing_as(token1, token2) then
				local length1, length2 = export.get_length(token1), export.get_length(token2)
				if length1 and length2 and length1 ~= length2 then
						if length1 == "either" then
							tokens1[i] = change_length(length2, token1)
						elseif length2 == "either" then
							tokens2[i] = change_length(length1, token2)
						end
				end
			else
				break
			end
		else
			break
		end
	end
	
	local new_word1, new_word2 = table.concat(tokens1), table.concat(tokens2)
	
	return new_word1, new_word2
end

--[[
	Get weight of nth syllable from end of word. Position defaults to 1, the last
	syllable. Returns "heavy" or "light", or nil if syllable is open with an
	ambiguous vowel.
]]
function export.get_weight(word, position)
	if not if_not_empty(word) then
		return nil
	end
	local tokens = tokenize(word)
	
	if not position then
		position = 1
	end
	
	local vowel
	local vowel_index = 0
	
	-- Find nth vowel from end of word.
	for i, token in m_table.reverseIpairs(tokens) do
		local length = export.get_length(token)
		if length then
			vowel_index = vowel_index + 1
			if vowel_index == position then
				vowel = { index = i, length = length }
				break
			end
		end
	end
	
	if not vowel then
		return nil
	end
	
	if vowel.length == "long" then
		return "heavy"
	else
		-- Count consonants after the vowel.
		local consonant_count = 0
		
		for i = vowel.index + 1, #tokens do
			if not contains_vowel(tokens[i]) then
				consonant_count = consonant_count + 1
			else
				break
			end
		end
		
		if consonant_count > 1 then
			return "heavy"
		elseif vowel.length == "short" then
			return "light"
		else
			return nil
		end
	end
end

--[[
	Add accent mark at position. Position is a number that refers to the nth
	vowel from the beginning of the word. Respects the rules of accent.
	Examples:
	- δημος,	1		=> δῆμος
	- προτερᾱ,	1		=> προτέρᾱ	(position changed to 2 because ultima is long)
	- μοιρα,	1, true	=> μοῖρα	(circumflex can be added because ultima is
										ambiguous)
	- χωρᾱ,		1, true	=> χώρᾱ		(circumflex can't be added because ultima
										is long)
	- τοιουτος,	2		=> τοιοῦτος	(circumflex because ultima is short)
	
	Arguments:
	- word:					string	(hopefully an Ancient Greek word or stem)
	- syllable_position:	number	(less than the number of monophthongs or diphthongs
										in the word)
	- options:				table
		- circumflex		boolean		(add a circumflex if allowed)
		- synaeresis		boolean		(accent can fall before εω in penult
											and ultima: πόλεως)
		- short_diphthong	boolean		(word-final οι, αι count as short)
]]
function export.add_accent(word, syllable_position, options)
	local check = _check("add_accent")
	check(1, word, "string")
	check(2, syllable_position, "number")
	check(3, options, "table", true)
	
	word = decompose(word)
	if find(word, tonal_diacritic) then
		return word
	end
	
	options = options or {}
	
	local tokens = copy(tokenize(word))
	local vowels = export.get_vowel_info(tokens, options.short_diphthong)
	local vowel_count = #vowels
	
	-- Convert positions in relation to the beginning of the word
	-- to positions in relation to the end of the word.
	-- The farthest back that an accent can be placed is 3 (the antepenult),
	-- so that is the greatest allowed position.
	if syllable_position > 0 then
		syllable_position = math.min(3, vowel_count - syllable_position + 1)
	-- If the position is in relation to the end of the word and it is greater
	-- than the length of the word, then reduce it to the length of the word.
	-- This is for practical reasons. Positions in relation to the beginning of
	-- the word do not need leeway.
	elseif syllable_position < 0 then
		syllable_position = math.min(-syllable_position, vowel_count)
	end
	
	if syllable_position == 0 then
		error("Invalid position value " .. syllable_position .. ".")
	elseif syllable_position > vowel_count then
		error("The position " .. syllable_position .. " is invalid, because the word has only " .. vowel_count .. " vowels.")
	end
	
	-- Apply accent rules to change the accent's position or type.
	local accent_mark = options.circumflex and CIRCUMFLEX or ACUTE
	local ultima = vowels[1]
	
	-- If synaeresis is selected, a final vowel sequence εω (optionally
	-- separated by an undertie) counts as one syllable.
	if syllable_position == 3 then
		local penult = vowels[2]
		if not options.force_antepenult and (ultima.length == "long"
				and not (options.synaeresis
				and ("Ωω"):find(tokens[ultima.index], 1, true)
				and ("Εε"):find(tokens[penult.index], 1, true)
				and (ultima.index == penult.index + 1
				or ultima.index == penult.index + 2
				and tokens[penult.index + 1] == mw.ustring.char(0x035C)))) then
			syllable_position = 2
		else
			accent_mark = ACUTE
		end
	end
	
	if syllable_position == 2 then
		if ultima.length == "short" and vowels[2].length == "long"  then
			accent_mark = CIRCUMFLEX
		elseif ultima.length == "long" then
			accent_mark = ACUTE
		end
	end
	
	local vowel = vowels[syllable_position]
	if not vowel then
		error('No vowel at position ' .. syllable_position ..
			' from the end of the word ' .. word .. '.')
	end
	if vowel.length == "short" then
		accent_mark = ACUTE
	end
	
	local i = vowel.index
	tokens[i] = add(tokens[i], accent_mark)
	
	return table.concat(tokens)
end

function export.syllables(word, func, number)
	local check = _check('syllables')
	check(1, word, 'string')
	check(2, func, 'string', true)
	check(3, number, 'number', true)
	
	if not func then
		error('No function specified')
	end
	
	local functions = {
		eq = function (word, number)
			local vowels = 0
			for _, token in ipairs(tokenize(word)) do
				if contains_vowel(token) then
					vowels = vowels + 1
					if vowels > number then
						return false
					end
				end
			end
			if vowels == number then
				return true
			end
			return false
		end
	}
	
	func = functions[func]
	if func then
		return func(word, number)
	else
		error('No function ' .. func)
	end
end

return export