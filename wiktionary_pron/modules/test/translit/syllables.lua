local export = {}

local diphthongs = mw.loadData("IPA/data").diphthongs
local vowels = mw.loadData("IPA/data/symbols").vowels .. "ᵻ" .. "ᵿ"

local U = mw.ustring.char

--[[ No use for this at the moment, though it is an interesting catalogue.
	It might be usable for phonetic transcriptions.
	Diacritics added to vowels:
	inverted breve above, inverted breve below,
	up tack, down tack,
	left tack, right tack,
	diaeresis (above), diaeresis below,
	right half ring, left half ring,
	plus sign below, minus sign below,
	combining x above, rhotic hook,
	tilde (above), tilde below
	ligature tie (combining double breve), ligature tie below
	]]
local diacritics = U(0x311)..U(0x32F)
	..U(0x31D)..U(0x31E)
	..U(0x318)..U(0x319)
	..U(0x308)..U(0x324)
	..U(0x339)..U(0x31C)
	..U(0x31F)..U(0x320)
	..U(0x33D)..U(0x2DE)
	..U(0x303)..U(0x330)
	..U(0x361)..U(0x35C)

--[[
combining acute and grave tone marks, circumflex
]]--
local tone = "[" .. U(0x341) .. U(0x340) ..U (0x302) .. "]"
local nonsyllabicDiacritics = U(0x311) .. U(0x32F)
local syllabicDiacritics = U(0x0329) .. U(0x030D)
local ties = U(0x361) .. U(0x35C)

-- long, half-long, extra short
local lengthDiacritics = U(0x2D0) .. U(0x2D1) .. U(0x306)
local vowel = "[" .. vowels .. "]" .. tone .. "?"
local tie = "[" .. ties .. "]"
local nonsyllabicDiacritic = "[" .. nonsyllabicDiacritics .. "]"
local syllabicDiacritic = "[" .. syllabicDiacritics .. "]"

local UTF8Char = "[\1-\127\194-\244][\128-\191]*"


function export.getVowels(remainder, lang)
	if string.find(remainder, "^[%\[/]?%-") or string.find(remainder, "%-[%\[/]?$") then
		return nil
	end	-- If a hyphen is at the beginning or end of the transcription, do not count syllables.
	
	local count = 0
	local diphs = diphthongs[lang:getCode()] or {}
	
	remainder = mw.ustring.toNFD(remainder)
	remainder = string.gsub(remainder, "%((.*)%)", "%1") -- Remove parentheses.

	while remainder ~= "" do
		-- Ignore nonsyllabic vowels
		remainder = mw.ustring.gsub(remainder, "^" .. vowel .. nonsyllabicDiacritic, "")
		
		local m =
			mw.ustring.match(remainder, "^." .. syllabicDiacritic) or  -- Syllabic consonant
			mw.ustring.match(remainder, "^" .. vowel .. tie .. vowel)  -- Tie bar
		
		-- Starts with a recognised diphthong?
		for _, diph in ipairs(diphs) do
			if m then
				break
			end
			
			m = m or mw.ustring.match(remainder, "^" .. diph)
		end
		
		-- If we haven't found anything yet, just match on a single vowel
		m = m or mw.ustring.match(remainder, "^" .. vowel)
		
		if m then
			-- Found a vowel, add it
			count = count + 1
			remainder = string.sub(remainder, #m + 1)
		else
			-- Found a non-vowel, skip it
			remainder = string.gsub(remainder, "^" .. UTF8Char, "")
		end
	end
	
	if count ~= 0 then return count end
	
	return nil
	
end


function export.countVowels2Test(frame)
	local params = {
		[1] = {required = true},
		[2] = {default = ""},
	}
	
	local args = require("parameters").process(frame.args, params)
	
	local lang = require("languages").getByCode(args[1]) or require("languages").err(args[1], 1)
	
	local count = export.getVowels(args[2], lang)
	
	return 'The text "' .. args[2] .. '" contains ' .. count .. ' vowels.'
end


local function countVowels(text)
	text = mw.ustring.toNFD(text) or error("Invalid UTF-8")
	
	local _, count = mw.ustring.gsub(text, vowel, "")
	local _, sequenceCount = mw.ustring.gsub(text, vowel.."+", "")
	local _, nonsyllabicCount = mw.ustring.gsub(text, vowel .. nonsyllabicDiacritic, "")
	local _, tieCount = mw.ustring.gsub(text, vowel .. tie .. vowel, "")
	
	local diphthongCount = count - (nonsyllabicCount + tieCount)
	
	return count, sequenceCount, diphthongCount
end


local function countDiphthongs(text, lang)
	text = mw.ustring.toNFD(text) or error("Invalid UTF-8")
	
	local diphthongs = diphthongs[lang:getCode()] or {}
	
	local _, count
	local total = 0
	
	if diphthongs then
		for i, diphthong in pairs(diphthongs) do
			_, count = mw.ustring.gsub(text, diphthong, "")
			total = total + count
		end
	end
	
	return total
end

function export.countVowels(frame)
	local params = {
		[1] = {default = ""},
	}
	
	local args = require("parameters").process(frame.args, params)
	
	local count, sequenceCount, diphthongCount = countVowels(args[1])
	
	local outputs = {}
	table.insert(outputs, (count or 'an unknown number of') .. ' vowels')
	table.insert(outputs, (sequenceCount or 'an unknown number of') .. ' vowel sequences')
	table.insert(outputs, (diphthongCount or 'an unknown number of') .. ' vowels or vowels and diphthongs')
	
	return 'The text "' .. args[1] .. '" contains ' .. mw.text.listToText(outputs) .. "."
end


function export.countVowelsDiphthongs(frame)
	local params = {
		[1] = {required = true},
		[2] = {default = ""},
	}
	
	local args = require("parameters").process(frame.args, params)
	
	local lang = require("languages").getByCode(args[1]) or require("languages").err(args[1], 1)
	
	local vowels = countVowels(args[2])
	local count = vowels - countDiphthongs(args[2], lang) or 0
	
	local out = 'The text "' .. args[2] .. '" contains ' .. (count or 'an unknown number of')
	
	if count == 1 then
		out = out .. ' vowel or diphthong.'
	else
		out = out .. ' vowels or diphthongs.'
	end
	
	return out
end

return export