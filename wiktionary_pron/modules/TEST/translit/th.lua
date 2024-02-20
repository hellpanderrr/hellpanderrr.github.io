local export = {}
local gsub = mw.ustring.gsub
local sub = mw.ustring.sub
local match = mw.ustring.match
local m_translit = require("th-translit")

local function track(page)
	require("debug/track")("th/" .. page)
	return true
end

function export.new(frame)
	local title = mw.title.getCurrentTitle().text
	local args = frame:getParent().args
	local phonSpell = args[1] or title
	local pos = args[2] or ""
	local def = args[3] or "{{rfdef|th}}"
	local pos2 = args[4] or (args[5] and "" or false)
	local def2 = args[5] or "{{rfdef|th}}"
	local pos3 = args[6] or (args[7] and "" or false)
	local def3 = args[7] or "{{rfdef|th}}"
	local etym = args["e"] or false
	local head = args["head"] or false
	local cls = args["cls"] or false
	local cat = args["cat"] or false
	local pic = args["pic"] or false
	local caption = args["caption"] or false
	local verb = args["verb"] or false
	
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
			code = code .. "\n\n===" .. title .. "===\n{{col3|th|" .. 
				table.concat(mw.text.split(args[class], ","), "|")
			i = 2
			while args[class .. i] do
				code = code .. "|" .. args[class .. i]
				i = i + 1
			end
			code = code .. "}}"
		end
		return code
	end
	
	if args["c1"] then
		etym = "From {{com|th|" .. args["c1"] .. "|" .. args["c2"] .. (args["c3"] and "|" .. args["c3"] or "") .. "}}."
		head = "[[" .. args["c1"] .. "]][[" .. args["c2"] .. "]]"
	end
	
	result = result .. "==Thai=="
	if args["wp"] then result = result .. "\n{{wikipedia|lang=th" .. (args["wp"] ~= "y" and "|" .. args["wp"] or "") .. "}}" end
	if pic then result = result .. "\n[[File:" .. pic .. "|thumb|" .. (caption or "{{lang|th|" .. title .. "}}") .. "]]" end
	result = result .. other("alt", "Alternative forms", args)
	
	if etym then result = result .. "\n\n===Etymology===\n" .. etym end
	
	result = result .. "\n\n===Pronunciation===\n{{th-pron" .. ((phonSpell ~= title and phonSpell ~= "") and ("|" .. gsub(phonSpell, ",", "|")) or "") .. "}}"
	result = result .. "\n\n===" .. genTitle(pos) .. "===\n{{th-" .. genHead(pos) ..
	((cls and genHead(pos) == "noun") and "|" .. cls or "") .. 
	(head and ("|head=" .. head) or "") .. 
	((verb and genHead(pos) == "verb") and "|~" or "") .. "}}\n\n# " .. def
	
	result = result .. other("syn", "=Synonyms=", args)
	result = result .. other("ant", "=Antonyms=", args)
	result = result .. other("der", "=Derived terms=", args)
	result = result .. other("rel", "=Related terms=", args)
	result = result .. other("also", "=See also=", args)
	
	if pos2 then
		result = result .. "\n\n===" .. genTitle(pos2) .. "===\n{{th-" .. genHead(pos2) .. 
		((cls and genHead(pos2) == "noun") and "|" .. cls or "") .. 
		(head and ("|head=" .. head) or "") .. 
		((verb and genHead(pos2) == "verb") and "|~" or "") .. 
		"}}\n\n# " .. def2
	end
	
	if pos3 then
		result = result .. "\n\n===" .. genTitle(pos3) .. "===\n{{th-" .. genHead(pos3) .. 
		((cls and genHead(pos2) == "noun") and "|" .. cls or "") .. 
		(head and ("|head=" .. head) or "") .. 
		((verb and genHead(pos3) == "verb") and "|~" or "") .. 
		"}}\n\n# " .. def3
	end
	
	if cat then
		result = result .. "\n\n{{C|th|" .. cat .. "}}"
	end
	
	return result
end

function export.getTranslit(lemmas, phonSpell)
	local m_th_pron = require("th-pron")
	if not phonSpell then
		phonSpell = lemmas
		for lemma in mw.ustring.gmatch(lemmas, "[ก-๛ %-]+") do
			local title = mw.title.new(lemma)
			if title and title.exists then
				local content = title:getContent()
				local template = match(content, "{{th%-pron[^}]*}}")
				if template ~= "" then
					lemma = gsub(lemma, "%-", "%" .. "-")
					if template == "{{th-pron}}" then phonSpell = lemma break end
					template = match(content, "{{th%-pron|([^}]+)}}")
					phonSpell = gsub(phonSpell, lemma, template and mw.text.split(template, "|")[1] or lemma)
					phonSpell = gsub(phonSpell, "%%%-", "-")
				end
			end
		end
	end
	local transcription = m_th_pron.translit(phonSpell, "th", "Thai", "paiboon", "translit-module")
	transcription = transcription or nil
	return transcription
end
	
function export.link(frame)
	local args = frame:getParent().args
	local lemma = args[1] or error("Page to be linked to has not been specified. Please pass parameter 1 to the module invocation.")
	local phonSpell = args["p"] or false
	local gloss = args[2] or args["gloss"] or ""
	local transcription = export.getTranslit(lemma, phonSpell)
	return frame:expandTemplate{ title = "l", args = {"th", lemma, nil, gloss = gloss, sc = "Thai", tr = transcription}}
end

function export.usex(frame)
	local parent_args = frame:getParent().args
	if parent_args.bold then
		track("usex-bold")
	end
	local params = {
		[1] = {required = true},
		[2] = {},
		["nobold"] = {type = "boolean"},
		["inline"] = {type = "boolean"},
		["pagename"] = {}, -- for testing or documentation purposes
	}
	local args = require("parameters").process(parent_args, params)
	local boldCode = "%'%'%'"
	local pagename = args.pagename or mw.title.getCurrentTitle().text
	local text = {}
	local example = args[1]
	local translation = args[2]
	local noBold = args["nobold"]
	local exSet, romSet = {}, {}
	local inline = frame.args.inline or args.inline
	
	boldify = example ~= pagename
	if not match(example, boldCode) and boldify and not noBold and mw.ustring.len(pagename) > 1 then
		pagename = gsub(pagename, "%-", mw.ustring.char(0x2011))
		example = gsub(example, "%-", mw.ustring.char(0x2011))
		example = gsub(example, "(.?)(" .. pagename .. ")(.?)", function(pre, captured, post)
			if not match(pre .. post, "[ก-๛]") then
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
	example = gsub(example, "ฯ  ", "ฯ ")
	example = gsub(example, "  ", " & ")
	example = gsub(example, "([^ก-๛{}%-%.0-9]+)", " %1 ") -- Allow European digits
	example = gsub(example, " +", " ")
	example = gsub(example, "^ ", "")
	example = gsub(example, " $", "")
	
	local syllables = mw.text.split(example, " ", true)
	local count = 0
	
	for index, thaiWord in ipairs(syllables) do
		local phonSpell, content, template = "", "", ""
		if thaiWord == "'''" then
			count = count + 1
			thaiWord = count % 2 == 1 and "<b>" or "</b>"
		end
		if match(thaiWord, "[ก-๛]") then
			phonSpell = thaiWord
			if match(thaiWord, "[{}]") then
				phonSpell = match(phonSpell, "{([^}]+)}")
				thaiWord = match(thaiWord, "^[^{}]+")
			else
				local titleWord = thaiWord == "ๆ" and lastWord or thaiWord
				if match(titleWord, "^[ก-๎%-]+$") and mw.title.new(titleWord).exists then
					content = mw.title.new(titleWord):getContent()
					template = match(content, "{{th%-pron[^}]*}}")
					if template ~= "" then
						template = match(content, "{{th%-pron|([^}]+)}}")
						phonSpell = template and mw.text.split(template, "|")[1] or titleWord
					else
						phonSpell = titleWord
					end
				else
					phonSpell = titleWord
				end
			end
			lastWord = thaiWord
			table.insert(exSet, "[[" .. thaiWord .. "]]")
			thaiWord = gsub(thaiWord, boldCode .. "([^%']+)" .. boldCode, "<b>%1</b>")
			
			local transcript = m_translit.tr(phonSpell, "th", "Thai")
			if not transcript then
				if mw.title.new(thaiWord).exists then
					error("The word " .. thaiWord .. " was not romanised successfully. " ..
						"Please try adding bolding markup to the example, " ..
						"or apply |bold=n to the template. If both are still unsuccessful, " ..
						"please report the problem at [[Template talk:th-usex]].")
				else
					error("The word [[" .. thaiWord .. "]] was not romanised successfully. " ..
						"Please supply its syllabified phonetic respelling, " .. 
						"enclosed by {} and placed after the word (see [[Template:th-usex]]).")
				end
			end
			table.insert(romSet, transcript)
		else
			table.insert(exSet, thaiWord)
			table.insert(romSet, m_translit.tr(thaiWord, "th", "Thai"))
		end
	end
	
	example = table.concat(exSet)
	example = gsub(example, " ", "")
	example = gsub(example, "&", " ")
	example = gsub(example, "ฯ", "ฯ ")
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
	
	if not translation then
		table.insert(text, '<span lang="th" class="Thai">' .. example .. '</span>' .. '<span>(<i>' .. translit .. '</i>)</span>')
	else
		table.insert(text, ('<span lang="th" class="Thai">%s</span>'):format(example))
		if not inline then -- match(example, "[.?!।]") or mw.ustring.len(example) > 50 then
			table.insert(text, "<dl><dd>''" .. translit .. "''</dd><dd>" .. translation .. "</dd></dl>")
		else
			table.insert(text, "&nbsp; ―&nbsp; ''" .. translit .. "''&nbsp; ―&nbsp; " .. translation)
		end
	end
	return table.concat(text)
end

function export.derived(frame, other_types)
	local obsolete_note = '<sup><span class="explain" title="Archaic, obsolete or dated.">†</span></sup>'
	local m_columns = require("columns")
	local lang = require("languages").getByCode("th")
	local m_links = require("links")
	local args = frame:getParent().args
	local pagename = mw.title.getCurrentTitle().text
	local result = {}
	local length = 0
	
	unfold = args["unfold"] and true or false
	title = args["title"] or false
	title_text = title or other_types or "Derived terms"

	if args["see"] then
		return '<div class="pseudo NavFrame" ><div class="NavHead" style="text-align:left">' .. title_text ..
			' <span style="font-weight: normal" >— <i>see</i></span > ' .. m_links.full_link({ lang = lang, term = args["see"] }) .. '</div></div>'
	end

	for i, word in ipairs(args) do
		word, is_obsolete = gsub(word, "†", "")
		obsolete = is_obsolete > 0 and obsolete_note or ""
		local word_parts = mw.text.split(gsub(word, "\n", "" ), ":")
		table.insert(result, obsolete .. 
			m_links.full_link({ lang = lang, term = word_parts[1], gloss = word_parts[2] or nil }))
		
		length = math.max(mw.ustring.len(word), length)
	end
	
	return 
		m_columns.create_table(
			(length > 15 and 2 or 3), 
			result, 
			1, 
			"#F5F5FF",
			((unfold or #result < 7) and false or true), 
			"Derived terms",
			title_text, 
			nil, 
			nil,
			lang
		)
end

function export.synonym(frame)
	return export.derived(frame, "Synonyms")
end

function export.antonym(frame)
	return export.derived(frame, "Antonyms")
end

function export.also(frame)
	return export.derived(frame, "See also")
end

function export.alternative(frame)
	return export.derived(frame, "Alternative forms")
end

function export.related(frame)
	return export.derived(frame, "Related terms")
end

return export