local export = {}

local debug_track_module = "Module:debug/track"
local links_module = "Module:links"
local script_utilities_module = "Module:script utilities"
local usex_data_module = "Module:usex/data"

local rsubn = mw.ustring.gsub
local rsplit = mw.text.split
local rfind = mw.ustring.find
local uupper = mw.ustring.upper
local u = mw.ustring.char

local translit_data = mw.loadData("transliteration/data")
local needs_translit = translit_data[1]

local BRACKET_SUB = u(0xFFF0)
local original_text = "<small>''original:''</small> "

-- microformat2 classes, see https://phabricator.wikimedia.org/T138709
local css_classes = {
	container_ux = 'h-usage-example',
	container_quotation = 'h-quotation',
	example = 'e-example',
	quotation = 'e-quotation',
	quotation_with_citation = 'e-quotation cited-passage',
	translation = 'e-translation',
	-- The following are added by [[Module:script utilities]], using [[Module:script utilities/data]]
--	transliteration = 'e-transliteration',	
--	transcription = 'e-transcription',
	normalization = 'e-normalization',
	literally = 'e-literally',
	source = 'e-source',
	footer = 'e-footer'
}


-- helper functions

local function track(page)
	require(debug_track_module)("usex/" .. page)
	return true
end


-- version of rsubn() that discards all but the first return value
local function rsub(term, foo, bar)
	local retval = rsubn(term, foo, bar)
	return retval
end


local function wrap(tag, class, text, lang)
	if lang then
		lang = ' lang="' .. lang .. '"'
	else
		lang = ""
	end
	
	if text and class then
		return table.concat{'<', tag, ' class="', class, '"', lang, '>', text, '</', tag, '>'}
	else
		return nil
	end
end

local function span(class, text) return wrap('span', class, text) end
local function div(class, text) return wrap('div', class, text) end

--[==[
Apply the substitutions in `subst` (from the {{para|subst}} parameter or similar) to the example or quotation in
`usex` after removing links, returning the resulting text. `track`, if supplied, is a function of one argument that is
used to insert tracking categories: one for any call to this function, another if a single / is used in the `subst`
argument.
]==]
function export.apply_subst(usex, subst, track)
	local subbed_usex = require(links_module).remove_links(usex)
	local function do_track(page)
		if track then
			track(page)
		end
		return true
	end

	if subst then
		-- [[Special:WhatLinksHere/Template:tracking/usex/subst]]
		do_track("subst")
		
		subst = rsplit(subst, ",")
		for _, subpair in ipairs(subst) do
			-- [[Special:WhatLinksHere/Template:tracking/usex/subst-single-slash]]
			local subsplit = rsplit(subpair, rfind(subpair, "//") and "//" or do_track("subst-single-slash") and "/")
			subbed_usex = rsub(subbed_usex, subsplit[1], subsplit[2])
		end
	end

	return subbed_usex
end

--[=[
Process parameters for usex text (either the primary text or the original text) and associated annotations. On input,
the following fields are recognized in `data` (all are optional except as marked):

* `lang`: Language object of text; may be an etymology language (REQUIRED).
* `termlang`: The language object of the term being illustrated, which may be different from the language of the main
			  quotation text and should always be based off of the main text, not the original text. Used for
			  categories. May be an etymology language (REQUIRED).
* `quotelang`: The language object of the main quotation, which should always be based off of the main quotation text,
			   not the original text. Used for categories. May be an etymology language (REQUIRED).
* `usex`: Text of usex/quotation.
* `sc`: Script object of text.
* `tr`: Manual transliteration.
* `ts`: Transcription.
* `norm`: Normalized version of text.
* `normsc`: Script object of normalized version of text, or "auto".
* `subst`: String of substitutions for transliteration purposes.
* `quote`: If non-nil, this is a quotation (using {{tl|quote}} or {{tl|quote-*}}) instead of a usage example (using
  {{tl|usex}}). If it has the specific value "quote-meta", this is a quotation with citation (invoked from
  {{tl|quote-*}}). This controls the CSS class used to display the quotation, as well as the face used to tag the usex
  (which in turn results in the usex being upright text if a quotation, and italic text if a usage example).
* `title`: Title object of the current page (REQUIRED).
* `q`: List of left qualifiers.
* `qq`: List of right qualifiers.
* `ref`: String to display directly after any right qualifier, with no space. (FIXME: Should be converted into
         an actual ref.)
* `nocat`: Overall `data.nocat` value.
* `categories`: List to insert categories into (REQUIRED).
* `example_type`: Either "quotation" (if `quote` specified) or "usage example" (otherwise) (REQUIRED).

On output, return an object with four fields:
* `usex`: Formatted usex, including qualifiers attached to both sides and `ref` attached to the right. Always specified.
* `tr`: Formatted transliteration; may be nil.
* `ts`: Formatted transcription; may be nil.
* `norm`: Formatted normalized version of usex; may be nil.
]=]
local function process_usex_text(data)
	local lang = data.lang
	local termlang = data.termlang
	local quotelang = data.quotelang
	local usex = data.usex
	local sc = data.sc
	local tr = data.tr
	local ts = data.ts
	local norm = data.norm
	local normsc = data.normsc
	local subst = data.subst
	local quote = data.quote
	local leftq = data.q
	local rightq = data.qq
	local ref = data.ref
	local nocat = data.nocat
	local categories = data.categories
	local example_type = data.example_type
	local title = data.title

	if normsc == "auto" then
		normsc = nil
	elseif not normsc then
		normsc = sc
	end

	if not sc then
		sc = lang:findBestScript(usex)
	end
	if not normsc and norm then
		normsc = lang:findBestScript(norm)
	end

	local langcode = lang:getNonEtymologicalCode()

	-- tr=- means omit transliteration altogether
	if tr == "-" then
		tr = nil
	else
		-- Try to auto-transliterate.
		if not tr then
			-- First, try transliterating the normalization, if supplied.
			if norm and normsc and not normsc:getCode():find("Lat") then -- Latn, Latf, Latg, pjt-Latn
				local subbed_norm = export.apply_subst(norm, subst, track)
				tr = (lang:transliterate(subbed_norm, normsc))
			end
			-- If no normalization, or the normalization is in a Latin script, or the transliteration of the
			-- normalization failed, fall back to transliterating the usex.
			if not tr then
				local subbed_usex = export.apply_subst(usex, subst, track)
				tr = (lang:transliterate(subbed_usex, sc))
			end
			
			-- If the language doesn't have capitalization and is specified in [[Module:usex/data]], then capitalize any sentences.
			-- Exclamation marks and question marks need to be unescaped then re-escaped.
			if tr and mw.loadData(usex_data_module).capitalize_sentences[langcode] then
				tr = tr:gsub("&#x21;", "!")
					:gsub("&#x3F;", "?")
				tr = rsub(tr, "%f[^%z%p%s](.)(.-[%.%?!‽])", function(m1, m2)
					return uupper(m1) .. m2
				end)
				tr = tr:gsub("!", "&#x21;")
					:gsub("%?", "&#x3F;")
			end
		end

		-- If there is still no transliteration, then add a cleanup category.
		if not tr and needs_translit[langcode] then
			table.insert(categories, ("Requests for transliteration of %s %ss"):format(quotelang:getCanonicalName(),
				example_type))
		end
	end
	if tr then
		tr = require(script_utilities_module).tag_translit(tr, langcode, "usex")
	end
	if ts then
		ts = require(script_utilities_module).tag_transcription(ts, langcode, "usex")
		ts = "/" .. ts .. "/"
	end

	local function do_language_and_script_tagging(usex, lang, sc, css_class)
		usex = require(links_module).embedded_language_links{term = usex, lang = lang, sc = sc}
		
		local face
		if quote then
			face = nil
		else
			face = "term"
		end
		
		usex = require(script_utilities_module).tag_text(usex, lang, sc, face, css_class)

		return usex
	end

	if usex then
		usex = do_language_and_script_tagging(usex, lang, sc,
			quote == "quote-meta" and css_classes.quotation_with_citation or
			quote and css_classes.quotation or css_classes.example)
		
		if not nocat then
			-- Only add [[Citations:foo]] to [[:Category:LANG terms with quotations]] if [[foo]] exists.
			local ok_to_add_cat
			if title.nsText ~= "Citations" then
				ok_to_add_cat = true
			else
				-- Here we don't want to use the subpage text because we check [[Citations:foo]] against [[foo]] and
				-- if there's a slash in what follows 'Citations:', we want to check against the full page with the
				-- slash.
				local mainspace_title = mw.title.new(title.text)
				if mainspace_title and mainspace_title.exists then
					ok_to_add_cat = true
				end
			end
			if ok_to_add_cat then
				-- Categories beginning with the language name should use non-etymology-only languages as that's what the poscat
				-- system requires, but 'Requests for' categories can use etymology-only languages.
				table.insert(categories, ("%s terms with %ss"):format(termlang:getNonEtymologicalName(), example_type))
			end
		end
	else
		if tr then
			table.insert(categories, ("Requests for native script in %s %ss"):format(quotelang:getCanonicalName(),
				example_type))
		end
		
		-- TODO: Trigger some kind of error here
		usex = "<small>(please add the primary text of this " .. example_type .. ")</small>"
	end

	if norm then
		-- Use brackets in HTML entity format just to make sure we don't interfere with links; add brackets before
		-- script tagging so that if the script tagging increases the font size, the brackets get increased too.
		norm = "&#91;" .. norm .. "&#93;"
		norm = do_language_and_script_tagging(norm, lang, normsc, css_classes.normalization)
	end

	local result = {}

	if leftq and #leftq > 0 then
		table.insert(result, require("qualifier").format_qualifier(leftq) .. " ")
	end
	table.insert(result, usex)
	if rightq and #rightq > 0 then
		table.insert(result, " " .. require("qualifier").format_qualifier(rightq))
	end

	if ref and ref ~= "" then
		track("ref")
		table.insert(result, ref)
	end

	return {
		usex = table.concat(result),
		tr = tr,
		ts = ts,
		norm = norm
	}
end


--[==[
Format a usex or quotation. Implementation of {{tl|ux}}, {{tl|quote}} and {{tl|quote-*}} templates (e.g.
{{tl|quote-book}}, {{tl|quote-journal}}, {{tl|quote-web}}, etc.). FIXME: Should also be used by {{tl|Q}} and
[[Module:Quotations]].

Takes a single object `data`, containining the following fields:

* `usex`: The text of the usex or quotation to format. Semi-mandatory (a maintenance line is displayed if missing).
* `lang`: The language object of the text. Mandatory. May be an etymology language.
* `termlang`: The language object of the term, which may be different from the language of the text. Defaults to `lang`.
              Used for categories. May be an etymology language.
* `sc`: The script object of the text. Autodetected if not given.
* `quote`: If specified, this is a quotation rather than a usex (uses a different CSS class that affects formatting).
* `inline`: If specified, format the usex or quotation inline (on one line).
* `translation`: Translation of the usex or quotation, if in a foreign language.
* `lit`: Literal translation (if the translation in `translation` is idiomatic and differs significantly from the
		 literal translation).
* `normalization`: Normalized version of the usex or quotation (esp. for older languages where nonstandard spellings
				   were common).
* `normsc`: Script object of the normalized text. If unspecified, use the script object given in `sc` if any, otherwise
            do script detection on the normalized text. If "auto", do script detection on the normalized text even if
			a script was specified in `sc`.
* `transliteration`: Transliteration of the usex. If unspecified, transliterate the normalization if specified and not
                     in a Latin script and transliterable, otherwise fall back to transliterating the usex text.
* `transcription`: Transcription of the usex, for languages where the transliteration differs significantly from the
                   pronunciation.
* `subst`: String indicating substitutions to perform on the usex/quotation and normalization prior to transliterating
           them. Multiple substs are comma-separated and individual substs are of the form FROM//TO where FROM is a
		   Lua pattern and TO is a Lua replacement spec. (FROM/TO is also recognized if no // is present in the
		   substitution.)
* `q`: If specified, a list of left qualifiers to display before the usex/quotation text.
* `qq`: If specified, a list of right qualifiers to display after the usex/quotation text.
* `qualifiers`: If specified, a list of right qualifiers to display after the usex/quotation text, for compatibility
                purposes.
* `ref`: Reference text to display directly after the right qualifiers. (FIXME: Instead, this should be actual
         references.)
* `orig`: Original text, if the primary text of the usex or quotation is a translation.
* `origlang`: The language object of the original text. Mandatory if original text given. May be an etymology language.
* `origsc`: The script object of the original text. Autodetected if not given.
* `orignorm`: Normalized version of the original text (esp. for older languages where nonstandard spellings were
              common).
* `orignormsc`: Script object of the normalized original text. If unspecified, use the script object given in `origsc`
                if any, otherwise do script detection on the normalized original text. If "auto", do script detection
                on the normalized text even if a script was specified in `origsc`.
* `origtr`: Transliteration of the original text. If unspecified, transliterate the normalized original text if
            specified and not in a Latin script and transliterable, otherwise fall back to transliterating the original
            text.
* `origts`: Transcription of the original text, for languages where the transliteration differs significantly from the
            pronunciation.
* `origsubst`: String indicating substitutions to perform on the original text and normalization thereof prior to
               transliterating them. Multiple substs are comma-separated and individual substs are of the form FROM//TO
               where FROM is a Lua pattern and TO is a Lua replacement spec. (FROM/TO is also recognized if no // is
               present in the substitution.)
* `origq`: If specified, a list of left qualifiers to display before the original text.
* `origqq`: If specified, a list of right qualifiers to display after the original text.
* `origref`: Reference text to display directly after the right qualifiers of the original text. (FIXME: Instead, this
             should be actual references.)
* `source`: Source of the quotation, displayed in parens after the quotation text.
* `footer`: Footer displaying miscellaneous information, shown after the quotation. (Typically this should be in a
            small font.)
* `nocat`: Suppress categorization.
* `sortkey`: Sort key for categories.
* `brackets`: If specified, show a bracket at the end (used with brackets= in {{tl|quote-*}} templates, which show the
              bracket at the beginning, to indicate a mention rather than a use).
* `class`: Additional CSS class surrounding the entire formatted text.
]==]

function export.format_usex(data)
	local lang = data.lang
	local termlang = data.termlang or lang
	local translation = data.translation
	local quote = data.quote
	local lit = data.lit
	local source = data.source
	local brackets = data.brackets
	local footer = data.footer
	local sortkey = data.sortkey

	local title
	if data.pagename then -- for testing, doc pages, etc.
		title = mw.title.new(data.pagename)
		if not title then
			error(("Bad value for `data.pagename`: '%s'"):format(data.pagename))
		end
	else
		title = mw.title.getCurrentTitle()
	end

	--[[
	if title.nsText == "Reconstruction" or lang:hasType("reconstructed") then
		error("Reconstructed languages and reconstructed terms cannot have usage examples, as we have no record of their use.")
	end
	]]
	
	if lit then
		lit = "(literally, “" .. span(css_classes.literally, lit) .. "”)"
	end

	if source then
		source = "(" .. span(css_classes.source, source) .. ")"
	end

	if footer then
		footer = span(css_classes.footer, footer)
	end
	
	local example_type = quote and "quotation" or "usage example" -- used in error messages and categories
	local categories = {}

	local usex_obj = process_usex_text {
		lang = lang,
		termlang = termlang,
		quotelang = lang,
		usex = data.usex,
		sc = data.sc,
		tr = data.transliteration,
		ts = data.transcription,
		norm = data.normalization,
		normsc = data.normsc,
		subst = data.subst,
		quote = data.quote,
		title = title,
		q = data.q,
		qq = data.qq,
		ref = data.ref,
		nocat = data.nocat,
		categories = categories,
		example_type = example_type,
	}

	local orig_obj = data.orig and process_usex_text {
		lang = data.origlang,
		-- Any categories derived from the original text should use the language of the main text or the term inside it,
		-- not the language of the original text.
		termlang = termlang,
		quotelang = lang,
		usex = data.orig,
		sc = data.origsc,
		tr = data.origtr,
		ts = data.origts,
		norm = data.orignorm,
		normsc = data.orignormsc,
		subst = data.origsubst,
		quote = data.quote,
		title = title,
		q = data.origq,
		qq = data.origqq,
		ref = data.origref,
		nocat = data.nocat,
		categories = categories,
		example_type = example_type,
	} or nil

	if translation == "-" then
		translation = nil
		table.insert(categories, ("%s %ss with omitted translation"):format(lang:getNonEtymologicalName(),
			example_type))
	elseif translation then
		translation = span(css_classes.translation, translation)
	else
		local langcode = lang:getNonEtymologicalCode()
		local origlangcode = data.origlang and data.origlang:getNonEtymologicalCode()
		if langcode ~= "en" and langcode ~= "mul" and langcode ~= "und" and origlangcode ~= "en" then
			-- add trreq category if translation is unspecified and language is not english, translingual or
			-- undetermined
			table.insert(categories, ("Requests for translations of %s %ss"):format(lang:getCanonicalName(),
				example_type))
			if quote then
				translation = "<small>(please [[WT:Quotations#Adding translations to quotations|add an English translation]] of this "
					.. example_type .. ")</small>"
			else
				translation = "<small>(please add an English translation of this " .. example_type .. ")</small>"
			end
		end
	end

	local result = {}
	local function ins(text)
		table.insert(result, text)
	end

	ins(usex_obj.usex)

	if data.inline then
		local function insert_annotations(obj)
			if obj.norm then
				ins(" " .. obj.norm)
			end
			if obj.tr or obj.ts then
				ins(" ―")
				if obj.tr then
					ins(" " .. obj.tr)
				end
				if obj.ts then
					ins(" " .. obj.ts)
				end
			end
		end

		insert_annotations(usex_obj)

		if orig_obj then
			ins(" (")
			ins("[" .. original_text .. orig_obj.usex .. "]")
			insert_annotations(orig_obj)
			ins(")")
		end

		if translation then
			ins(" ― " .. translation)
		end

		if lit then
			ins(" " .. lit)
		end
		
		if source then
			ins(" " .. source)
		end

		if footer then
			ins(" " .. footer)
		end

		if data.brackets then
			ins("]")
		end

		result = table.concat(result)
	else
		local any_usex_annotations = usex_obj.tr or usex_obj.ts or usex_obj.norm or translation or lit
		local any_orig_annotations = orig_obj and (orig_obj.tr or orig_obj.ts or orig_obj.norm)
		if any_usex_annotations or orig_obj or source or footer then
			ins("<dl>")

			local function insert_dd(text)
				if text then
					ins("<dd>")
					ins(text)
					if data.brackets then
						ins(BRACKET_SUB)
					end
					ins("</dd>")
				end
			end

			insert_dd(usex_obj.norm)
			insert_dd(usex_obj.tr)
			insert_dd(usex_obj.ts)

			if orig_obj then
				insert_dd("[" .. original_text .. orig_obj.usex .. "]")
				if any_orig_annotations then
					ins("<dd><dl>")
					insert_dd(orig_obj.norm)
					insert_dd(orig_obj.tr)
					insert_dd(orig_obj.ts)
					ins("</dl></dd>")
				end
			end

			insert_dd(translation)
			insert_dd(lit)

			if source or footer then
				if any_usex_annotations then
					ins("<dd><dl>")
				end
				insert_dd(source)
				insert_dd(footer)
				if any_usex_annotations then
					ins("</dl></dd>")
				end
			end

			ins("</dl>")
		elseif data.brackets then
			ins(BRACKET_SUB)
		end

		result = table.concat(result)
		if data.brackets then
			result = result:gsub("^(.*)" .. BRACKET_SUB, "%1]"):gsub(BRACKET_SUB, "")
		end
	end

	local class = quote and css_classes.container_quotation or css_classes.container_ux
	if data.class then
		class = class .. " " .. data.class
	end
	result = (data.inline and span or div)(class, result)
	return result .. require("utilities").format_categories(categories, lang, sortkey)
end

return export