local require_when_needed = require("utilities/require when needed")

local concat = table.concat
local insert = table.insert
local process_params = require_when_needed("Module:parameters", "process")

local export = {}

--[=[
	Modules used:
	[[Module:script utilities/data]]
	[[Module:scripts]]
	[[Module:senseid]] (only when id's present)
	[[Module:string utilities]] (only when hyphens in Korean text or spaces in vertical text)
	[[Module:languages]]
	[[Module:parameters]]
	[[Module:utilities]]
	[[Module:debug/track]]
]=]

function export.is_Latin_script(sc)
	-- Latn, Latf, Latg, pjt-Latn
	return sc:getCode():find("Lat") and true or false
end

--[==[{{temp|#invoke:script utilities|lang_t}}
This is used by {{temp|lang}} to wrap portions of text in a language tag. See there for more information.]==]
do
	local function get_args(frame)
		local plain = {}
		return process_params(frame:getParent().args, {
			[1] = {required = true, type = "language", etym_lang = true, default = "und"},
			[2] = {required = true, allow_empty = true, default = ""},
			["sc"] = {type = "script"},
			["face"] = plain,
			["class"] = plain,
		})
	end
	
	function export.lang_t(frame)
		local args = get_args(frame)
		
		local lang = args[1]
		local sc = args["sc"]
		local text = args[2]
		local cats = {}
		
		if sc then
			-- Track uses of sc parameter.
			if sc:getCode() == lang:findBestScript(text):getCode() then
				insert(cats, lang:getNonEtymologicalName() .. " terms with redundant script codes")
			else
				insert(cats, lang:getNonEtymologicalName() .. " terms with non-redundant manual script codes")
			end
		else
			sc = lang:findBestScript(text)
		end
		
		text = require("links").embedded_language_links{
			term = text,
			lang = lang,
			sc = sc
		}
		
		cats = #cats > 0 and require("utilities").format_categories(cats, lang, "-", nil, nil, sc) or ""
		
		local face = args["face"]
		local class = args["class"]
		
		return export.tag_text(text, lang, sc, face, class) .. cats
	end
end

-- Ustring turns on the codepoint-aware string matching. The basic string function
-- should be used for simple sequences of characters, Ustring function for
-- sets – [].
local function trackPattern(text, pattern, tracking, ustring)
	local find = ustring and mw.ustring.find or string.find
	if pattern and find(text, pattern) then
		require("debug/track")("script/" .. tracking)
	end
end

local function track(text, lang, sc)
	local u = mw.ustring.char
	
	if lang and text then
		local langCode = lang:getNonEtymologicalCode()
		
		-- [[Special:WhatLinksHere/Template:tracking/script/ang/acute]]
		if langCode == "ang" then
			local decomposed = mw.ustring.toNFD(text)
			local acute = u(0x301)
			
			trackPattern(decomposed, acute, "ang/acute")
		
		--[=[
		[[Special:WhatLinksHere/Template:tracking/script/Greek/wrong-phi]]
		[[Special:WhatLinksHere/Template:tracking/script/Greek/wrong-theta]]
		[[Special:WhatLinksHere/Template:tracking/script/Greek/wrong-kappa]]
		[[Special:WhatLinksHere/Template:tracking/script/Greek/wrong-rho]]
			ϑ, ϰ, ϱ, ϕ should generally be replaced with θ, κ, ρ, φ.
		]=]
		elseif langCode == "el" or langCode == "grc" then
			trackPattern(text, "ϑ", "Greek/wrong-theta")
			trackPattern(text, "ϰ", "Greek/wrong-kappa")
			trackPattern(text, "ϱ", "Greek/wrong-rho")
			trackPattern(text, "ϕ", "Greek/wrong-phi")
		
			--[=[
			[[Special:WhatLinksHere/Template:tracking/script/Ancient Greek/spacing-coronis]]
			[[Special:WhatLinksHere/Template:tracking/script/Ancient Greek/spacing-smooth-breathing]]
			[[Special:WhatLinksHere/Template:tracking/script/Ancient Greek/wrong-apostrophe]]
				When spacing coronis and spacing smooth breathing are used as apostrophes, 
				they should be replaced with right single quotation marks (’).
			]=]
			if langCode == "grc" then
				trackPattern(text, u(0x1FBD), "Ancient Greek/spacing-coronis")
				trackPattern(text, u(0x1FBF), "Ancient Greek/spacing-smooth-breathing")
				trackPattern(text, "[" .. u(0x1FBD) .. u(0x1FBF) .. "]", "Ancient Greek/wrong-apostrophe", true)
			end
		
		-- [[Special:WhatLinksHere/Template:tracking/script/Russian/grave-accent]]
		elseif langCode == "ru" then
			local decomposed = mw.ustring.toNFD(text)
			
			trackPattern(decomposed, u(0x300), "Russian/grave-accent")
		
		-- [[Special:WhatLinksHere/Template:tracking/script/Tibetan/trailing-punctuation]]
		elseif langCode == "bo" then
			trackPattern(text, "[་།]$", "Tibetan/trailing-punctuation", true)
			trackPattern(text, "[་།]%]%]$", "Tibetan/trailing-punctuation", true)

		--[=[
		[[Special:WhatLinksHere/Template:tracking/script/Thai/broken-ae]]
		[[Special:WhatLinksHere/Template:tracking/script/Thai/broken-am]]
		[[Special:WhatLinksHere/Template:tracking/script/Thai/wrong-rue-lue]]
		]=]
		elseif langCode == "th" then
			trackPattern(text, "เ".."เ", "Thai/broken-ae")
			trackPattern(text, "ํ[่้๊๋]?า", "Thai/broken-am", true)
			trackPattern(text, "[ฤฦ]า", "Thai/wrong-rue-lue", true)

		--[=[
		[[Special:WhatLinksHere/Template:tracking/script/Lao/broken-ae]]
		[[Special:WhatLinksHere/Template:tracking/script/Lao/broken-am]]
		[[Special:WhatLinksHere/Template:tracking/script/Lao/possible-broken-ho-no]]
		[[Special:WhatLinksHere/Template:tracking/script/Lao/possible-broken-ho-mo]]
		[[Special:WhatLinksHere/Template:tracking/script/Lao/possible-broken-ho-lo]]
		]=]
		elseif langCode == "lo" then
			trackPattern(text, "ເ".."ເ", "Lao/broken-ae")
			trackPattern(text, "ໍ[່້໊໋]?າ", "Lao/broken-am", true)
			trackPattern(text, "ຫນ", "Lao/possible-broken-ho-no")
			trackPattern(text, "ຫມ", "Lao/possible-broken-ho-mo")
			trackPattern(text, "ຫລ", "Lao/possible-broken-ho-lo")

		--[=[
		[[Special:WhatLinksHere/Template:tracking/script/Lü/broken-ae]]
		[[Special:WhatLinksHere/Template:tracking/script/Lü/possible-wrong-sequence]]
		]=]
		elseif langCode == "khb" then
			trackPattern(text, "ᦵ".."ᦵ", "Lü/broken-ae")
			trackPattern(text, "[ᦀ-ᦫ][ᦵᦶᦷᦺ]", "Lü/possible-wrong-sequence", true)
		end
	end
end

--[==[Wraps the given text in HTML tags with appropriate CSS classes (see [[WT:CSS]]) for the [[Module:languages#Language objects|language]] and script. This is required for all non-English text on Wiktionary.
The actual tags and CSS classes that are added are determined by the <code>face</code> parameter. It can be one of the following:
; {{code|lua|"term"}}
: The text is wrapped in {{code|html|2=<i class="(sc) mention" lang="(lang)">...</i>}}.
; {{code|lua|"head"}}
: The text is wrapped in {{code|html|2=<strong class="(sc) headword" lang="(lang)">...</strong>}}.
; {{code|lua|"hypothetical"}}
: The text is wrapped in {{code|html|2=<span class="hypothetical-star">*</span><i class="(sc) hypothetical" lang="(lang)">...</i>}}.
; {{code|lua|"bold"}}
: The text is wrapped in {{code|html|2=<b class="(sc)" lang="(lang)">...</b>}}.
; {{code|lua|nil}}
: The text is wrapped in {{code|html|2=<span class="(sc)" lang="(lang)">...</span>}}.
The optional <code>class</code> parameter can be used to specify an additional CSS class to be added to the tag.]==]
function export.tag_text(text, lang, sc, face, class, id)
	if not sc then
		sc = lang:findBestScript(text)
	end
	
	track(text, lang, sc)
		
	-- Replace space characters with newlines in Mongolian-script text, which is written top-to-bottom.
	if sc:getDirection():match("vertical") and text:find(" ") then
		text = require("munge_text")(text, function(txt)
			-- having extra parentheses makes sure only the first return value gets through
			return (txt:gsub(" +", "<br>"))
		end)
	end

	-- Hack Korean script text to remove hyphens.
	-- XXX: This should be handled in a more general fashion, but needs to
	-- be efficient by not doing anything if no hyphens are present, and currently this is the only
	-- language needing such processing.
	-- 20220221: Also convert 漢字(한자) to ruby, instead of needing [[Template:Ruby]].
	if sc:getCode() == "Kore" and (text:find("%-") or text:find("[()]")) then
		local m_scripts = require("scripts")
		text = require("munge_text")(text, function(txt)
			txt = txt:gsub("%-", "")
			txt = mw.ustring.gsub(txt, "([".. m_scripts.getByCode("Hani"):getCharacters() .. "]+)%(([" .. m_scripts.getByCode("Hang"):getCharacters() .. "]+)%)", "<ruby>%1<rp>(</rp><rt>%2</rt><rp>)</rp></ruby>")
			return txt
		end)
	end
	
	if sc:getCode() == "Imag" then
		face = nil
	end

	local function class_attr(classes)
		-- if the script code is hyphenated (i.e. language code-script code, add the last component as a class as well)
		-- e.g. ota-Arab adds both Arab and ota-Arab as classes
		if mw.ustring.find(sc:getCode(), "%-") then
			insert(classes, 1, (mw.ustring.gsub(sc:getCode(), ".+%-", "")))
			insert(classes, 2, sc:getCode())
		else
			insert(classes, 1, sc:getCode())
		end
		if class and class ~= '' then
			insert(classes, class)
		end
		return 'class="' .. concat(classes, ' ') .. '"'
	end
	
	local function tag_attr(...)
		local output = {}
		if id then
			insert(output, 'id="' .. require("senseid").anchor(lang, id) .. '"')
		end
		
		insert(output, class_attr({...}) )
		
		if lang then
			-- FIXME: Is it OK to insert the etymology-only lang code and have it fall back to the first part of the
			-- lang code (by chopping off the '-...' part)? It seems the :lang() selector does this; not sure about
			-- [lang=...] attributes.
			insert(output, 'lang="' .. lang:getNonEtymologicalCode() .. '"')
		end
		
		return concat(output, " ")
	end
	
	if face == "hypothetical" then
	-- [[Special:WhatLinksHere/Template:tracking/script-utilities/face/hypothetical]]
		require("debug/track")("script-utilities/face/hypothetical")
	end
	
	local data = mw.loadData("script utilities/data").faces[face or "plain"]
	
	-- Add directionality characters for (horizontal) right-to-left scripts.
	-- Note: this shouldn't be used for vertical RTL scripts, since it causes them to be displayed bottom-to-top.
	local pre, post = "", ""
	if sc:getDirection() == "rtl" then
		pre = "&#x2067;" -- right-to-left isolate
		post = "&#x2069;" -- pop directional isolate
	end
	
	-- Add a script wrapper
	if data then
		return pre .. ( data.prefix or "" ) .. '<' .. data.tag .. ' ' .. tag_attr(data.class) .. '>' .. text .. '</' .. data.tag .. '>' .. post
	else
		error('Invalid script face "' .. face .. '".')
	end
end

--[==[Tags the transliteration for given text {translit} and language {lang}. It will add the language, script subtag (as defined in [https://www.rfc-editor.org/rfc/bcp/bcp47.txt BCP 47 2.2.3]) and [https://developer.mozilla.org/en-US/docs/Web/HTML/Global_attributes/dir dir] (directional) attributes as needed.
The optional <code>kind</code> parameter can be one of the following:
; {{code|lua|"term"}}
: tag transliteration for {{temp|mention}}
; {{code|lua|"usex"}}
: tag transliteration for {{temp|usex}}
; {{code|lua|"head"}}
: tag transliteration for {{temp|head}}
; {{code|lua|"default"}}
: default
The optional <code>attributes</code> parameter is used to specify additional HTML attributes for the tag.]==]
function export.tag_translit(translit, lang, kind, attributes, is_manual)
	if type(lang) == "table" then
		-- FIXME: Do better support for etym languages; see https://www.rfc-editor.org/rfc/bcp/bcp47.txt
		lang = lang.getNonEtymologicalCode and lang:getNonEtymologicalCode()
			or error("Second argument to tag_translit should be a language code or language object.")
	end
	
	local data = mw.loadData("script utilities/data").translit[kind or "default"]
	
	local opening_tag = {}
	
	insert(opening_tag, data.tag)
	if lang == "ja" then
		insert(opening_tag, 'class="' .. (data.classes and data.classes .. " " or "") .. (is_manual and "manual-tr " or "") .. 'tr"')
	else
		insert(opening_tag, 'lang="' .. lang .. '-Latn"')
		insert(opening_tag, 'class="' .. (data.classes and data.classes .. " " or "") .. (is_manual and "manual-tr " or "") .. 'tr Latn"')
	end
	
	if data.dir then
		insert(opening_tag, 'dir="' .. data.dir .. '"')
	end
	
	insert(opening_tag, attributes)
	
	return "<" .. concat(opening_tag, " ") .. ">" .. translit .. "</" .. data.tag .. ">"
end

function export.tag_transcription(transcription, lang, kind, attributes)
	if type(lang) == "table" then
		-- FIXME: Do better support for etym languages; see https://www.rfc-editor.org/rfc/bcp/bcp47.txt
		lang = lang.getNonEtymologicalCode and lang:getNonEtymologicalCode()
			or error("Second argument to tag_transcription should be a language code or language object.")
	end
	
	local data = mw.loadData("script utilities/data").transcription[kind or "default"]
	
	local opening_tag = {}
	
	insert(opening_tag, data.tag)
	if lang == "ja" then
		insert(opening_tag, 'class="' .. (data.classes and data.classes .. " " or "") .. 'ts"')
	else
		insert(opening_tag, 'lang="' .. lang .. '-Latn"')
		insert(opening_tag, 'class="' .. (data.classes and data.classes .. " " or "") .. 'ts Latn"')
	end
	
	if data.dir then
		insert(opening_tag, 'dir="' .. data.dir .. '"')
	end
	
	insert(opening_tag, attributes)
	
	return "<" .. concat(opening_tag, " ") .. ">" .. transcription .. "</" .. data.tag .. ">"	
end

--[==[Generates a request to provide a term in its native script, if it is missing. This is used by the {{temp|rfscript}} template as well as by the functions in [[Module:links]].
The function will add entries to one of the subcategories of [[:Category:Requests for native script by language]], and do several checks on the given language and script. In particular:
* If the script was given, a subcategory named "Requests for (script) script" is added, but only if the language has more than one script. Otherwise, the main "Requests for native script" category is used.
* Nothing is added at all if the language has no scripts other than Latin and its varieties.]==]
function export.request_script(lang, sc, usex, nocat, sort_key)
	local scripts = lang.getScripts and lang:getScripts() or error('The language "' .. lang:getCode() .. '" does not have the method getScripts. It may be unwritten.')
	
	-- By default, request for "native" script
	local cat_script = "native"
	local disp_script = "script"
	
	-- If the script was not specified, and the language has only one script, use that.
	if not sc and #scripts == 1 then
		sc = scripts[1]
	end
	
	-- Is the script known?
	if sc and sc:getCode() ~= "None" then
		-- If the script is Latin, return nothing.
		if export.is_Latin_script(sc) then
			return ""
		end
		
		if (not scripts[1]) or sc:getCode() ~= scripts[1]:getCode() then
			disp_script = sc:getCanonicalName()
		end
		
		-- The category needs to be specific to script only if there is chance of ambiguity. This occurs when when the language has multiple scripts (or with codes such as "und").
		if (not scripts[1]) or scripts[2] then
			cat_script = sc:getCanonicalName()
		end
	else
		-- The script is not known.
		-- Does the language have at least one non-Latin script in its list?
		local has_nonlatin = false
		
		for i, val in ipairs(scripts) do
			if not export.is_Latin_script(val) then
				has_nonlatin = true
				break
			end
		end
		
		-- If there are no non-Latin scripts, return nothing.
		if not has_nonlatin then
			return ""
		end
	end
	
	local category
	
	if usex then
		local usex_type = usex == "quote" and "quotations" or "usage examples"
		-- Etymology languages have their own categories, whose parents are the regular language.
		category = "Requests for " .. cat_script .. " script in " .. lang:getCanonicalName() .. " " .. usex_type
	else
		category = "Requests for " .. cat_script .. " script for " .. lang:getCanonicalName() .. " terms"
	end
	
	return "<small>[" .. disp_script .. " needed]</small>" ..
		(nocat and "" or require("utilities").format_categories({category}, lang, sort_key))
end

--[==[This is used by {{temp|rfscript}}. See there for more information.]==]
do
	local function get_args(frame)
		local boolean = {type = "boolean"}
		return process_params(frame:getParent().args, {
			[1] = {required = true, type = "language", etym_lang = true, default = "und"},
			["sc"] = {type = "script"},
			["usex"] = boolean,
			["quote"] = boolean,
			["nocat"] = boolean,
			["sort"] = {},
		})
	end
	
	function export.template_rfscript(frame)
		local args = get_args(frame)
		
		local ret = export.request_script(args[1], args["sc"], args.quote and "quote" or args.usex, args.nocat, args.sort)
		
		if ret == "" then
			error("This language is written in the Latin alphabet. It does not need a native script.")
		else
			return ret
		end
	end
end

function export.checkScript(text, scriptCode, result)
	local scriptObject = require("scripts").getByCode(scriptCode)
	
	if not scriptObject then
		error('The script code "' .. scriptCode .. '" is not recognized.')
	end
	
	local originalText = text
	
	-- Remove non-letter characters.
	text = mw.ustring.gsub(text, "[%A]", "")
	
	-- Remove all characters of the script in question.
	text = mw.ustring.gsub(text, "[" .. scriptObject:getCharacters() .. "]", "")
	
	if text ~= "" then
		if type(result) == "string" then
			error(result)
		else
			error('The text "' .. originalText .. '" contains the letters "' .. text .. '" that do not belong to the ' .. scriptObject:getDisplayForm() .. '.', 2)
		end
	end
end

return export