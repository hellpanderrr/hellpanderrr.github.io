local export = {}
local gsub = mw.ustring.gsub
local sub = mw.ustring.sub
local match = mw.ustring.match
local m_pron = require("km-pron")

local function track(page)
	require("debug/track")("km/" .. page)
	return true
end

function export.new(frame)
	local title = mw.title.getCurrentTitle().text
	local args = frame:getParent().args
	local phonSpell = args[1] or title
	local pos = args[2] or ""
	local def = args[3] or "{{rfdef|km}}"
	local pos2 = args[4] or (args[5] and "" or false)
	local def2 = args[5] or "{{rfdef|km}}"
	local pos3 = args[6] or (args[7] and "" or false)
	local def3 = args[7] or "{{rfdef|km}}"
	local etym = args["e"] or false
	local head = args["head"] or false
	local cls = args["cls"] or false
	local cat = args["cat"] or false
	
	local result = ""
	
	local function genTitle(text)
		local pos_title = {
			[""] = "Noun", ["n"] = "Noun", ["pn"] = "Proper noun", ["propn"] = "Proper noun", ["pron"] = "Pronoun",
			["v"] = "Verb", ["a"] = "Adjective", ["adj"] = "Adjective", ["adv"] = "Adverb",
			["prep"] = "Preposition", ["postp"] = "Postposition", ["conj"] = "Conjunction",
			["part"] = "Particle", ["suf"] = "Suffix",
			["prov"] = "Proverb", ["id"] = "Idiom", ["ph"] = "Phrase", ["intj"] = "Interjection", ["interj"] = "Interjection",
			["cl"] = "Classifier", ["cls"] = "Classifier", ["num"] = "Numeral", ["abb"] = "Abbreviation", ["deter"] = "Determiner"
		};
		return pos_title[text] or mw.ustring.upper(sub(text, 1, 1)) .. sub(text, 2, -1)
	end
	
	local function genHead(text)
		local pos_head = {
			[""] = "noun", ["n"] = "noun", ["pn"] = "proper noun", ["propn"] = "proper noun", ["v"] = "verb", ["a"] = "adj",
			["postp"] = "post", ["conj"] = "con", ["part"] = "particle", ["pron"] = "pronoun",
			["prov"] = "proverb", ["id"] = "idiom", ["ph"] = "phrase", ["intj"] = "interj",
			["abb"] = "abbr", ["cl"] = "cls", ["deter"] = "det"
		};
		return pos_head[text] or text
	end
	
	local function other(class, title, args)
		local code = ""
		if args[class] then
			code = code .. "\n\n===" .. title .. "===\n* {{l|km|" .. args[class] .. "}}"
			i = 2
			while args[class .. i] do
				code = code .. "\n* {{l|km|" .. args[class .. i] .. "}}"
				i = i + 1
			end
		end
		return code
	end
	
	if args["c1"] then
		etym = "From {{com|km|" .. args["c1"] .. "|" .. args["c2"] .. (args["c3"] and "|" .. args["c3"] or "") .. "}}."
		head = "[[" .. args["c1"] .. "]][[" .. args["c2"] .. "]]"
	end
	
	result = result .. "==Khmer=="
	if args["wp"] then result = result .. "\n{{wikipedia|lang=km" .. (args["wp"] ~= "y" and "|" .. args["wp"] or "") .. "}}" end
	result = result .. other("alt", "Alternative forms", args)
	
	if etym then result = result .. "\n\n===Etymology===\n" .. etym end
	
	result = result .. "\n\n===Pronunciation===\n{{km-IPA" .. ((phonSpell ~= title and phonSpell ~= "") and ("|" .. gsub(phonSpell, ",", "|")) or "") .. "}}"
	result = result .. "\n\n===" .. genTitle(pos) .. "===\n{{km-" .. genHead(pos) .. ((cls and genHead(pos) == "noun") and "|" .. cls or "") .. (head and ("|head=" .. head) or "") .. "}}\n\n# " .. def
	
	result = result .. other("syn", "=Synonyms=", args)
	result = result .. other("ant", "=Antonyms=", args)
	result = result .. other("der", "=Derived terms=", args)
	result = result .. other("rel", "=Related terms=", args)
	result = result .. other("also", "=See also=", args)
	
	if pos2 then
		result = result .. "\n\n===" .. genTitle(pos2) .. "===\n{{km-" .. genHead(pos2) .. ((cls and genHead(pos2) == "noun") and "|" .. cls or "") .. (head and ("|head=" .. head) or "") .. "}}\n\n# " .. def2
	end
	
	if pos3 then
		result = result .. "\n\n===" .. genTitle(pos3) .. "===\n{{km-" .. genHead(pos3) .. ((cls and genHead(pos2) == "noun") and "|" .. cls or "") .. (head and ("|head=" .. head) or "") .. "}}\n\n# " .. def3
	end
	
	if cat then
		result = result .. "\n\n{{C|km|" .. cat .. "}}"
	end
	
	return result
end

function export.getTranslit(lemmas, phonSpell)
	local m_km_pron = require("km-pron")
	if not phonSpell then
		phonSpell = lemmas
		for lemma in mw.ustring.gmatch(lemmas, "[ក-៩ %-]+") do
			if mw.title.new(lemma).exists then
				local content = mw.title.new(lemma):getContent()
				local template = match(content, "{{km%-IPA[^}]*}}")
				if template ~= "" then
					lemma = gsub(lemma, "%-", "%" .. "-")
					template = match(content, "{{km%-IPA|([^}]+)}}")
					phonSpell = gsub(phonSpell, lemma, template and mw.text.split(template, "|")[1] or lemma)
					phonSpell = gsub(phonSpell, "%%%-", "-")
				end
			end
		end
	end
	local transcription = m_km_pron.convert(phonSpell, "tc")
	if not transcription or transcription == "" then transcription = require("km-translit").tr(phonSpell, "km", "Khmr") end
	transcription = (transcription and transcription ~= "") and transcription or nil
	return transcription
end

function export.usex(frame)
	local parent_args = frame:getParent().args
	if parent_args.bold then
		track("usex-bold")
	end
	local params = {
		[1] = {required = true},
		[2] = {},
		["bold"] = {}, -- dafuq??? FIXME: This should be nobold=1.
		["inline"] = {type = "boolean"},
		["pagename"] = {}, -- for testing or documentation purposes
	}
	local args = require("parameters").process(parent_args, params)
	local boldCode = "%'%'%'"
	local pagename = args.pagename or mw.title.getCurrentTitle().text
	local text = {}
	local example = args[1]
	local translation = args[2]
	local noBold = args["bold"] or false
	local exSet, romSet = {}, {}
	local inline = frame.args.inline or args.inline
	
	if match(example, "​") then error("The example contains the zero-space width character. Please remove it.") end
	boldify = example ~= pagename and true or false
	if not match(example, boldCode) and boldify and not noBold and mw.ustring.len(pagename) > 1 then
		pagename = gsub(pagename, "%-", mw.ustring.char(0x2011))
		example = gsub(example, "%-", mw.ustring.char(0x2011))
		example = gsub(example, "(.?)(" .. pagename .. ")(.?)", function(pre, captured, post)
			if not match(pre .. post, "[ក-៩]") then
				for captured_part in mw.text.gsplit(captured, " ") do
					captured = gsub(captured, captured_part, "'''" .. captured_part .. "'''")
				end
			end
			return pre .. captured .. post
		end)
	end
	
	example = gsub(example, mw.ustring.char(0x2011), "-")
	example = gsub(example, "'''({[^}]+})", "%1'''")
	example = gsub(example, "%*", pagename) -- shorthand
	example = gsub(example, "។", ". ")
	example = gsub(example, " ។", ". ")
	example = gsub(example, "  ", " & ")
	example = gsub(example, "([^ក-៩{}%-%.]+)", " %1 ")
	example = gsub(example, " +", " ")
	example = gsub(example, "^ ", "")
	example = gsub(example, " $", "")
	
	local syllables = mw.text.split(example, " ", true)
	local count = 0
	
	for index, khmerWord in ipairs(syllables) do
		local phonSpell, content, template = "", "", ""
		if khmerWord == "'''" then
			count = count + 1
			khmerWord = count % 2 == 1 and "<b>" or "</b>"
		end
		if match(khmerWord, "[ក-៩]") then
			phonSpell = khmerWord
			if match(khmerWord, "[{}]") then
				phonSpell = match(phonSpell, "{([^}]+)}")
				khmerWord = match(khmerWord, "^[^{}]+")
			else
				local titleWord = khmerWord == "ๆ" and lastWord or khmerWord
				if match(titleWord, "^[ក-៩%-]+$") and mw.title.new(titleWord).exists then
					content = mw.title.new(titleWord):getContent()
					template = match(content, "{{km%-IPA[^}]*}}")
					if template ~= "" then
						template = match(content, "{{km%-IPA|([^}]+)}}")
						phonSpell = template and mw.text.split(template, "|")[1] or titleWord
					else
						phonSpell = titleWord
					end
				else
					phonSpell = titleWord
				end
			end
			lastWord = khmerWord
			table.insert(exSet, "[[" .. khmerWord .. "]]")
			khmerWord = gsub(khmerWord, boldCode .. "([^%']+)" .. boldCode, "<b>%1</b>")
			
			local transcript = m_pron.convert(phonSpell, "tc")
			if not transcript then
				if mw.title.new(khmerWord).exists then
					error("The word " .. khmerWord .. " was not romanised successfully. " ..
						"Please try adding bolding markup to the example, " ..
						"or apply |bold=n to the template. If both are still unsuccessful, " ..
						"please report the problem at [[Template talk:km-usex]].")
				else
					error("The word [[" .. khmerWord .. "]] was not romanised successfully. " ..
						"Please supply its syllabified phonetic respelling, " .. 
						"enclosed by {} and placed after the word (see [[Template:km-usex]]).")
				end
			end
			table.insert(romSet, transcript)
		else
			table.insert(exSet, khmerWord)
			table.insert(romSet, m_pron.convert(khmerWord, "tc"))
		end
	end
	
	example = table.concat(exSet)
	example = gsub(example, " ", "")
	example = gsub(example, "&", " ")
	example = gsub(example, "។", ". ")
	example = gsub(example, " ។", ". ")
	example = gsub(example, "([^ ])(%[%[ๆ%]%])", "%1 %2")
	example = gsub(example, "(%[%[ๆ%]%])([^ %.,])", "%1 %2")
	
	translit = table.concat(romSet, " ")
	translit = gsub(translit, "^ +", "")
	translit = gsub(translit, " & ", " · ")
	translit = gsub(translit, "&", " ")
	
	translit = gsub(translit, "<b> ", "<b>")
	translit = gsub(translit, " </b>", "</b>")
	translit = gsub(translit, " :", ":")
	translit = gsub(translit, "%( ", "(")
	translit = gsub(translit, " %)", ")")
	translit = gsub(translit, " ([%?%!])", "%1")
	
	while match(translit, "[\"']") do
		translit = gsub(translit, "'", "‘", 1)
		translit = gsub(translit, "'", "’", 1)
		translit = gsub(translit, '"', "“", 1)
		translit = gsub(translit, '"', "”", 1)
	end	
	translit = gsub(translit, "([‘“]) ", "%1")
	translit = gsub(translit, " ([’”])", "%1")
	translit = gsub(translit, "(%a)%- ", "%1-")
	
	if translation == "" then
		table.insert(text, '<span lang="km" class="Khmr">' .. example .. '</span>' .. '<span>(<i>' .. translit .. '</i>)</span>')
	else
		table.insert(text, ('<span lang="km" class="Khmr">%s</span>'):format(example))
		if not inline and (match(example, "[%.%?!।]") or mw.ustring.len(example) > 50) then
			table.insert(text, "<dl><dd>''" .. translit .. "''</dd><dd>" .. translation .. "</dd></dl>")
		else
			table.insert(text, "&nbsp; ―&nbsp; ''" .. translit .. "''&nbsp; ―&nbsp; " .. translation)
		end
	end
	return table.concat(text)
end

return export