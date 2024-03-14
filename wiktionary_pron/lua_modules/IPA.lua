local export = {}
local m_string_utils = require("string utilities")
-- [[Module:IPA/data]]

local m_data = mw.loadData('IPA/data') -- [[Module:IPA/data]]
local m_symbols = mw.loadData('IPA/data/symbols') -- [[Module:IPA/data/symbols]]
local m_syllables -- [[Module:syllables]]; loaded below if needed

local sub = m_string_utils.sub
local find = m_string_utils.find
local gsub = m_string_utils.gsub
local len = m_string_utils.len
local match = m_string_utils.match
local gmatch = m_string_utils.gmatch
local u = mw.ustring.char

local function track(page)
	require("debug/track")("IPA/" .. page)
	return true
end

function export.format_IPA_full(lang, items, err, separator, sortKey, no_count)
	local IPA_key, key_link, err_text, prefix, IPAs, category
	local hasKey = m_data.langs_with_infopages
	local namespace = mw.title.getCurrentTitle().nsText
	
	if err then
		err_text = '<span class="error">' .. err .. '</span>'
	else
		if hasKey[lang:getCode()] then
			IPA_key = "Appendix:" .. lang:getCanonicalName() .. " pronunciation"
		else
			IPA_key = "wikipedia:" .. lang:getCanonicalName() .. " phonology"
		end
		
		key_link = "[[" .. IPA_key .. "|key]]"
	end

	
	local prefix = "[[Wiktionary:International Phonetic Alphabet|IPA]]<sup>(" .. ( key_link or err_text ) .. ")</sup>:&#32;"
	
	IPAs = export.format_IPA_multiple(lang, items, separator, no_count)
	
	if lang and (namespace == "" or namespace == "Reconstruction") then
		sortKey = sortKey or (lang:makeSortKey(mw.title.getCurrentTitle().text))
		sortKey = sortKey and ("|" .. sortKey) or ""
		category = "[[Category:" .. lang:getCanonicalName() .. " terms with IPA pronunciation" .. sortKey .. "]]"
	else
		category = ""
	end

	return prefix .. IPAs .. category
end

local function determine_repr(pron)
	local repr_mark = {}
	local repr, reconstructed
	
	-- remove initial asterisk before representation marks, used on some Reconstruction pages
	if find(pron, "^%*") then
		reconstructed = true
		pron = sub(pron, 2)
	end
	
	local representation_types = {
		['/'] = { right = '/', type = 'phonemic', },
		['['] = { right = ']', type = 'phonetic', },
		['⟨'] = { right = '⟩', type = 'orthographic', },
		['-'] = { type = 'rhyme' },
	}
	
	repr_mark.i, repr_mark.f, repr_mark.left, repr_mark.right = find(pron, '^(.).-(.)$')
	
	local representation_type = representation_types[repr_mark.left]
	
	if representation_type then
		if representation_type.right then
			if repr_mark.right == representation_type.right then
				repr = representation_type.type
			end
		else
			repr = representation_type.type
		end
	else
		repr = nil
	end
	
	return repr, reconstructed
end

local function hasInvalidSeparators(transcription)
	if find(transcription, "%.[ˈˌ]") then
		return true
	else
		return false
	end
end

function export.format_IPA_multiple(lang, items, separator, no_count)
	local categories = {}
	separator = separator or ', '
	
	-- Format
	if not items[1] then
		if mw.title.getCurrentTitle().nsText == "Template" then
			table.insert(items, {pron = "/aɪ piː ˈeɪ/"})
		else
			table.insert(categories, "[[Category:Pronunciation templates without a pronunciation]]")
		end
	end
	
	local bits = {}
	
	for _, item in ipairs(items) do
		local bit = export.format_IPA(lang, item.pron)
		
		if item.pretext then
			bit = item.pretext .. bit
		end
		
		if item.posttext then
			bit = bit .. item.posttext
		end

		if item.q and item.q[1] or item.qq and item.qq[1] or item.qualifiers and item.qualifiers[1]
			or item.a and item.a[1] or item.aa and item.aa[1] then
			bit = require("pron qualifier").format_qualifiers(item, bit)
		end

		if item.refs or item.note then
			local refspecs
			if item.note then
				-- FIXME: eliminate item.note in favor of item.refs. Use tracking to find places
				-- that use item.note.
				refspecs = {item.note}
				track("note")
			else
				refspecs = item.refs
			end
			local refs = {}
			if #refspecs > 0 then
				for _, refspec in ipairs(refspecs) do
					if type(refspec) ~= "table" then
						refspec = {text = refspec}
					end
					local refargs
					if refspec.name or refspec.group then
						refargs = {name = refspec.name, group = refspec.group}
					end
					table.insert(refs, mw.getCurrentFrame():extensionTag("ref", refspec.text, refargs))
				end
				bit = bit .. table.concat(refs)
			end
		end

		if item.separator then
			bit = item.separator .. bit
		end

		table.insert(bits, bit)
		
		--[=[	[[Special:WhatLinksHere/Template:tracking/IPA/syntax-error]]
				The length or gemination symbol should not appear after a syllable break or stress symbol.	]=]
		
		if find(item.pron, "[ˈˌ%.][ːˑ]") then
			track("syntax-error")
		end
		
		if lang then
			-- Add syllable count if the language's diphthongs are listed in [[Module:syllables]].
			-- Don't do this if the term has spaces or a liaison mark (‿).
			if not no_count and mw.title.getCurrentTitle().namespace == 0 then
				m_syllables = m_syllables or require('syllables')
				local langcode = lang:getCode()
				if m_data.langs_to_generate_syllable_count_categories[langcode] then
					local repr = determine_repr(item.pron)
					local use_it
					if m_data.langs_to_use_phonetic_notation[langcode] then
						use_it = repr == "phonetic"
					else
						use_it = repr == "phonemic"
					end
					if use_it and not find(item.pron, "[ ‿]") then
						local syllable_count = m_syllables.getVowels(item.pron, lang)
						if syllable_count then
							table.insert(categories, "[[Category:" .. lang:getCanonicalName() .. " " .. syllable_count .. "-syllable words]]")
						end
					end
				end
			end

			if lang:getCode() == "en" and hasInvalidSeparators(item.pron) then
				table.insert(categories, "[[Category:IPA for English using .ˈ or .ˌ]]")
			end
		end
	end

	return table.concat(bits, separator) .. table.concat(categories)
end

-- Takes an IPA pronunciation and formats it and adds cleanup categories.
function export.format_IPA(lang, pron, split_output)
	local err = {}
	local categories = {}
	
	-- Remove wikilinks, so that wikilink brackets are not misinterpreted as
	-- indicating phonemic transcription
	local str_gsub = string.gsub
	local without_links = str_gsub(pron, '%[%[[^|%]]+|([^%]]+)%]%]', '%1')
	without_links = str_gsub(without_links, '%[%[[^%]]+%]%]', '%1')
	
	-- Detect whether this is a phonemic or phonetic transcription
	local repr, reconstructed = determine_repr(without_links)
	
	if reconstructed then
		pron = sub(pron, 2)
		without_links = sub(without_links, 2)
	end
	
	-- If valid, strip the representation marks
	if repr == "phonemic" then
		pron = sub(pron, 2, -2)
		without_links = sub(without_links, 2, -2)
	elseif repr == "phonetic" then
		pron = sub(pron, 2, -2)
		without_links = sub(without_links, 2, -2)
	elseif repr == "orthographic" then
		pron = sub(pron, 2, -2)
		without_links = sub(without_links, 2, -2)
	elseif repr == "rhyme" then
		pron = sub(pron, 2)
		without_links = sub(without_links, 2)
	else
		table.insert(categories, "[[Category:IPA pronunciations with invalid representation marks]]")
		-- table.insert(err, "invalid representation marks")
		-- Removed because it's annoying when previewing pronunciation pages.
	end
	
	if pron == "" then
		table.insert(categories, "[[Category:IPA pronunciations with no pronunciation present]]")
	end
	
	-- Check for obsolete and nonstandard symbols
	for i, symbol in ipairs(m_data.nonstandard) do
		local result
		for nonstandard in gmatch(pron, symbol) do
			if not result then
				result = {}
			end
			table.insert(result, nonstandard)
			table.insert(categories, "[[Category:IPA pronunciations with obsolete or nonstandard characters|" .. nonstandard .. "]]")
		end
		
		if result then
			table.insert(err, "obsolete or nonstandard characters (" .. table.concat(result) .. ")")
			break
		end
	end
	
	--[[ Check for invalid symbols after removing the following:
			1. wikilinks (handled above)
			2. paired HTML tags
			3. bolding
			4. italics
			5. HTML entity for space
			6. asterisk at beginning of transcription
			7. comma followed by spacing characters
			8. superscripts enclosed in superscript parentheses		]]
	local found_HTML
	local result = str_gsub(without_links, "<(%a+)[^>]*>([^<]+)</%1>",
		function(tagName, content)
			found_HTML = true
			return content
		end)
	result = str_gsub(result, "'''([^']*)'''", "%1")
	result = str_gsub(result, "''([^']*)''", "%1")
	result = str_gsub(result, "&[^;]+;", "") -- This may catch things that are not valid character entities.
	result = str_gsub(result, "^%*", "")
	result = gsub(result, ",%s+", "")
	
	-- VS15
	local vs15_class = "[" .. m_symbols.add_vs15 .. "]"
	if find(pron, vs15_class) then
		local vs15 = u(0xFE0E)
		if find(result, vs15) then
			result = gsub(result, vs15, "")
			pron = gsub(pron, vs15, "")
		end
		pron = gsub(pron, "(" .. vs15_class .. ")", "%1" .. vs15)
	end

	if result ~= '' then
		mw.log(pron, result)
		local namespace = mw.title.getCurrentTitle().namespace
		local suggestions = {}
		for k, v in pairs(m_symbols.invalid) do
			if result:match(k) then
				table.insert(suggestions, k .. " with " .. v)
			end
		end
		if suggestions[1] then
			if namespace == 0 or namespace == 118 then
				error("Invalid IPA: replace " .. mw.text.listToText(suggestions))
			else
				table.insert(err, "replace " .. mw.text.listToText(suggestions))
			end
		end
		result = gsub(result, "⁽[".. m_symbols.superscripts .. "]+⁾", "")
		result = gsub(result, '[' .. m_symbols.valid .. ']', '')
		if result ~= '' then
			local category = "IPA pronunciations with invalid IPA characters"
			if namespace ~= 0 and namespace ~= 118 then
				category = category .. "/non_mainspace"
			end
			table.insert(categories, "[[Category:" .. category .. "]]")
			table.insert(err, "invalid IPA characters (" .. result .. ")")
		end
	end
	
	if found_HTML then
		table.insert(categories, "[[Category:IPA pronunciations with paired HTML tags]]")
	end
	
	-- Reference inside IPA template usage
	-- FIXME: Doesn't work; you can't put HTML in module output.
	--if find(pron, '</ref>') then
	--	table.insert(categories, "[[Category:IPA pronunciations with reference]]")
	--end
	
	if repr == "phonemic" or repr == "rhyme" then
		if lang and m_data.phonemes[lang:getCode()] then
			local valid_phonemes = m_data.phonemes[lang:getCode()]
			local rest = pron
			local phonemes = {}
			
			while len(rest) > 0 do
				local longestmatch = ""
				
				if sub(rest, 1, 1) == "(" or sub(rest, 1, 1) == ")" then
					longestmatch = sub(rest, 1, 1)
				else
					for _, phoneme in ipairs(valid_phonemes) do
						if len(phoneme) > len(longestmatch) and sub(rest, 1, len(phoneme)) == phoneme then
							longestmatch = phoneme
						end
					end
				end
				
				if len(longestmatch) > 0 then
					table.insert(phonemes, longestmatch)
					rest = sub(rest, len(longestmatch) + 1)
				else
					local phoneme = sub(rest, 1, 1)
					table.insert(phonemes, "<span style=\"color: red\">" .. phoneme .. "</span>")
					rest = sub(rest, 2)
					table.insert(categories, "[[Category:IPA pronunciations with invalid phonemes/" .. lang:getCode() .. "]]")
					track("invalid phonemes/" .. phoneme)
				end
			end
			
			pron = table.concat(phonemes)
		end
		
		if repr == "phonemic" then
			pron = "/" .. pron .. "/"
		else
			pron = "-" .. pron
		end
	elseif repr == "phonetic" then
		pron = "[" .. pron .. "]"
	elseif repr == "orthographic" then
		pron = "⟨" .. pron .. "⟩"
	end
	
	if reconstructed then
		pron = "*" .. pron
	end
	
	if err[1] then
		err = '<span class="previewonly error" style="font-size: small;>&#32;' .. table.concat(err, ', ') .. '</span>'
	else
		err = ""
	end
	
	if split_output then -- for use of IPA in links 
		return '<span class="IPA">' .. pron .. '</span>', table.concat(categories), err
	else
		return '<span class="IPA">' .. pron .. '</span>' .. err .. table.concat(categories)
	end
end

return export