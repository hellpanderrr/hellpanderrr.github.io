--[=[
	This module contains functions to implement quote-* templates.

	Author: Benwing2; conversion into Lua of {{quote-meta/source}} template,
	written by Sgconlaw with some help from Erutuon and Benwing2.

	The main interface is quote_t(). Note that the source display is handled by source(), which reads both the
	arguments passed to it *and* the arguments passed to the parent template, with the former overriding the latter.
]=]

local export = {}

-- Named constants for all modules used, to make it easier to swap out sandbox versions.
local check_isxn_module = "Module:check isxn"
local debug_track_module = "Module:debug/track"
local dialect_tags_module = "Module:dialect tags"
local italics_module = "Module:italics"
local languages_module = "Module:languages"
local links_module = "Module:links"
local number_utilities_module = "Module:number utilities"
local parameters_module = "Module:parameters"
local parse_utilities_module = "Module:parse utilities"
local qualifier_module = "Module:qualifier"
local roman_numerals_module = "Module:roman numerals"
local script_utilities_module = "Module:script utilities"
local scripts_module = "Module:scripts"
local string_utilities_module = "Module:string utilities"
local table_module = "Module:table"
local usex_module = "Module:usex"
local usex_templates_module = "Module:usex/templates"
local utilities_module = "Module:utilities"
local yesno_module = "Module:yesno"

local rsubn = mw.ustring.gsub
local rmatch = mw.ustring.match
local rfind = mw.ustring.find
local rsplit = mw.text.split
local rgsplit = mw.text.gsplit
local ulen = mw.ustring.len
local usub = mw.ustring.sub
local u = mw.ustring.char

-- Use HTML entities here to avoid parsing issues (esp. with brackets)
local SEMICOLON_SPACE = "&#59; "
local SPACE_LBRAC = " &#91;"
local RBRAC = "&#93;"

local TEMP_LT = u(0xFFF1)
local TEMP_GT = u(0xFFF2)
local TEMP_LBRAC = u(0xFFF3)
local TEMP_RBRAC = u(0xFFF4)
local TEMP_SEMICOLON = u(0xFFF5)
local L2R = u(0x200E)
local R2L = u(0x200F)

html_entity_to_replacement = {
  {entity="&lt;", repl=TEMP_LT},
  {entity="&gt;", repl=TEMP_GT},
  {entity="&#91;", entity_pat="&#0*91;", repl=TEMP_LBRAC},
  {entity="&#93;", entity_pat="&#0*93;", repl=TEMP_RBRAC},
}

local function track(page)
	require(debug_track_module)("quote/" .. page)
	return true
end

-- version of rsubn() that discards all but the first return value
local function rsub(term, foo, bar)
	local retval = rsubn(term, foo, bar)
	return retval
end

local function maintenance_line(text)
	return "<span class=\"maintenance-line\" style=\"color: #777777;\">(" .. text .. ")</span>"
end

local function isbn(text)
	return "[[Special:BookSources/" .. text .. "|→ISBN]]" ..
		require(check_isxn_module).check_isbn(text, "&nbsp;<span class=\"error\" style=\"font-size:88%\">Invalid&nbsp;ISBN</span>[[Category:Pages with ISBN errors]]")
end

local function issn(text)
	return "[https://www.worldcat.org/issn/" .. text .. " →ISSN]" ..
		require(check_isxn_module).check_issn(text, "&nbsp;<span class=\"error\" style=\"font-size:88%\">Invalid&nbsp;ISSN</span>[[Category:Pages with ISSN errors]]")
end

local function lccn(text)
	local origtext = text
	text = rsub(text, " ", "")
	if rfind(text, "%-") then
		-- old-style LCCN; reformat per request by [[User:The Editor's Apprentice]]
		local prefix, part1, part2 = rmatch(text, "^(.-)([0-9]+)%-([0-9]+)$")
		if prefix then
			if ulen(part2) < 6 then
				part2 = ("0"):rep(6 - ulen(part2)) .. part2
			end
			text = prefix .. part1 .. part2
		end
	end
	return "[https://lccn.loc.gov/" .. mw.uri.encode(text) .. " →LCCN]"
end

local function format_date(text)
	return mw.getCurrentFrame():callParserFunction{name="#formatdate", args=text}
end

local function tag_nowiki(text)
	return mw.getCurrentFrame():callParserFunction{name="#tag", args={"nowiki", text}}
end

local function split_on_comma(term)
	if term:find(",%s") then
		return require(parse_utilities_module).split_on_comma(term)
	else
		return rsplit(term, ",")
	end
end

local function yesno(val, default)
	if not val then
		return default
	end
	return require(yesno_module)(val, default)
end

-- Convert a raw tag= param (or nil) to a list of formatted dialect tags; unrecognized tags are passed through
-- unchanged. Return nil if nil passed in.
local function tags_to_dialects(lang, tags)
	if not tags then
		return nil
	end
	return require(dialect_tags_module).make_dialects(split_on_comma(tags), lang)
end

-- Convert a comma-separated list of language codes to a comma-separated list of language names. `fullname` is the
-- name of the parameter from which the list of language codes was fetched.
local function format_langs(langs, fullname)
	langs = rsplit(langs, ",")
	for i, langcode in ipairs(langs) do
		local lang = require(languages_module).getByCode(langcode, fullname, "allow etym")
		langs[i] = lang:getCanonicalName()
	end
	if #langs == 1 then
		return langs[1]
	else
		return require(table_module).serialCommaJoin(langs)
	end
end


local function get_first_lang(langs, fullname, get_non_etym, required)
	local langcode = langs and rsplit(langs, ",")[1] or not required and "und" or nil
	local lang = require(languages_module).getByCode(langcode, fullname, "allow etym")
	if get_non_etym then
		lang = lang:getNonEtymological()
	end
	return lang
end


--[=[
Normally we parse off inline modifiers and language code prefixes in various places, e.g. he:מרים<tr:Miryem>. But we
exclude HTML entries with <span ...>, <i ...>, <br/> or similar in it, caused by wrapping an argument in {{l|...}},
{{lang|...}} or similar. Basically, all tags of the sort we parse here should consist of a less-than sign, plus letters,
plus a colon, e.g. <tr:...>, so if we see a tag on the outer level that isn't in this format, we don't try to parse it.
The restriction to the outer level is to allow generated HTML inside of e.g. qualifier modifiers, such as
foo<q:similar to {{m|fr|bar}}> (if we end up supporting such modifiers).

Also exclude things that look like URL's from being parsed as having language code prefixes.
]=]
local function val_should_not_be_parsed_for_annotations(val)
	return val:find("^[^<]*<[a-z]*[^a-z:]") or val:find("^[a-z]+://")
end


local param_mods = {
	t = {
		-- <t:...> and <gloss:...> are aliases.
		item_dest = "gloss",
	},
	gloss = {},
	alt = {},
	tr = {},
	ts = {},
	subst = {},
	sc = {
		convert = function(arg, parse_err)
			return require(scripts_module).getByCode(arg, parse_err)
		end,
	},
	f = {
		convert = function(arg, parse_err)
			local prefix, val = rmatch(arg, "^(.-):([^ ].*)$")
			if not prefix then
				prefix = ""
				val = arg
			end
			local tags, sc = rmatch(prefix, "^(.*)/(.-)$")
			if sc then
				sc = require(scripts_module).getByCode(sc, parse_err)
			else
				tags = prefix
			end
			local quals
			if tags ~= "" then
				quals = split_on_comma(tags)
				for i, qual in ipairs(quals) do
					local obj = require(languages_module).getByCode(qual, nil, "allow etym")
					if not obj then
						obj = require(scripts_module).getByCode(qual)
					end
					quals[i] = obj or qual
				end
			end
			return {
				quals = quals,
				sc = sc,
				val = val,
			}
		end,
		store = "insert",
	},
	q = {},
	qq = {},
}

--[=[
Parse a textual property that may be in a foreign language or script and may be annotated with a language prefix and/or
inline modifiers. `val` is the value of the parameter and `fullname` is the name of the parameter from which the value
was retrieved. `explicit_gloss`, if specified and non-nil, overrides any gloss specified using the <t:...> or
<gloss:...> inline modifier.

If `val` is nil, the return value of this function is nil. Otherwise it is parsed for a language prefix (e.g.
'ar:مُؤَلِّف') and inline modifiers (e.g. 'ar:مُؤَلِّف<t:Author>'), and the return value is an object with the following
fields:
  `lang`: The language object corresponding to the language prefix, if specified, or nil if no language prefix is
          given.
  `text`: The text after stripping off any language prefix and inline modifiers.
  `link`: The link part of the text if it consists of a two-part link; otherwise, same as `text`.
  `alt`: Display text specified using the <alt:...> modifier, if given; otherwise, nil.
  `subst`: Substitutions used to generate the transliteration, in the same format as the subst= parameter.
  `sc`: The script object corresponding to the <sc:...> modifier, if given; otherwise nil.
  `tr`: The transliteration corresponding to the <tr:...> modifier, if given; otherwise nil.
  `ts`: The transcription corresponding to the <ts:...> modifier, if given; otherwise nil.
  `gloss`: The gloss/translation corresponding to the `explicit_gloss` parameter (if given and non-nil), otherwise
           the <t:...> or <gloss:...> modifiers if given, otherwise nil.
  `f`: Foreign versions of the text.
  `q`: Left qualifiers.
  `qq`: Right qualifiers.

Note that as a special case, if `val` contains HTML tags at the top level (e.g. '<span class="Arab">...</span>', as
might be generated by specifying {{lang|ar|مُؤَلِّف}}), no language prefix or inline modifiers are parsed, and the return
value has the `noscript` field set to true, which tells format_annotated_text() not to try to identify the script of
the text and CSS-tag the text accordingly, but to leave the text untagged.

This object can be passed to format_annotated_text() to format a string displaying the text (appropriately
script-tagged, unless `noscript` is set, as described above) and modifiers.
]=]
local function parse_annotated_text(val, fullname, explicit_gloss)
	if not val then
		return nil
	end
	-- When checking for inline modifiers, exclude HTML entry with <span ...>, <i ...>, <br/> or similar in it, caused
	-- by wrapping an argument in {{l|...}}, {{lang|...}} or similar. Also exclude URL's from being parsed as having
	-- language code prefixes. See val_should_not_be_parsed_for_annotations() for more information. If we find a
	-- parameter value with top-level HTML in it, add 'noscript = true' to indicate that we should not try to do script
	-- inference and tagging. (Otherwise, e.g. if you specify {{lang|ar|مُؤَلِّف}} as the author, you'll get an extra big
	-- font coming from the fact that {{lang|...}} wraps the Arabic text in CSS that increases the size from the
	-- default, and then we do script detection and again wrap the text in the same CSS, which increases the size even
	-- more.)
	if val_should_not_be_parsed_for_annotations(val) then
		return {text = val, link = val, noscript = true}
	end
	local function generate_obj(text, parse_err_or_paramname)
		local obj = {}
		if text:find(":[^ ]") or text:find("%[%[") then
			obj.text, obj.lang, obj.link = require(parse_utilities_module).parse_term_with_lang(text,
				parse_err_or_paramname)
		else
			obj.text = text
			obj.link = text
		end
		return obj
	end

	local obj
	if val:find("<") then
		-- Check for inline modifier.
		obj = require(parse_utilities_module).parse_inline_modifiers(val, {
			paramname = fullname,
			param_mods = param_mods,
			generate_obj = generate_obj,
		})
	else
		obj = generate_obj(val, fullname)
	end

	if explicit_gloss then
		obj.gloss = explicit_gloss
	end

	return obj
end


local function undo_html_entity_replacement(txt)
	txt = txt:gsub(TEMP_SEMICOLON, ";")
	for _, html_entity_to_repl in ipairs(html_entity_to_replacement) do
		txt = txt:gsub(html_entity_to_repl.repl, html_entity_to_repl.entity)
	end
	return txt
end


--[=[
Similar to parse_annotated_text() but the parameter value may contain multiple semicolon-separated entities, each with
their own inline modifiers. Some examples:
* mainauthor=Paula Pattengale; Terea Sonsthagen
* author=Katie Brick; J. Cody Nielsen; Greg Jao; Eric Paul Rogers; John A. Monson
* author=Suzanne Brockmann; Patrick G. Lawlor (Patrick Girard); Melanie Ewbank
* author=G Ristori; et al.
* author=Jason Scott; zh:王晰宁<t:Wang Xining>
* editors=zh:包文俊; zh:金心雯
* quotee=zh:張福運<t:Chang Fu-yun>; zh:張景文<t:Chang Ching-wen>

There may be embedded semicolons within brackets, braces or parens that should not be treated as delimiters, e.g.:
* author=Oliver Optic [pseudonym; {{w|William Taylor Adams}}]
* author=author=Shannon Drake (pen name; {{w|Heather Graham Pozzessere}})
* author=James (the Elder;) Humphrys

There may also be HTML entities with semicolons in them:
* author=&#91;{{w|Gilbert Clerke}}&#93;
* 2ndauthor=Martin Biddle &amp; Sally Badham
* author=Peter Christen Asbj&oslash;rnsen

There may be both embedded semicolons and HTML entities with semicolons in them:
* author=&#91;{{w|Voltaire}} [pseudonym; François-Marie Arouet]&#93;

In general we want to treat &#91; like an opening bracket and &#93; like a closing bracket. Beware that they may be
mismatched:
* author=Anonymous &#91;{{w|Karl Maria Kertbeny}}]

Here, `val` is the value of the parameter and `fullname` is the name of the parameter from which the value was
retrieved. `explicit_gloss`, if specified and non-nil, overrides any gloss specified using the <t:...> or <gloss:...>
inline modifier, and `explicit_gloss_fullname` is the name of the parameter from which this value was retrieved. (If
`explicit_gloss` is specified and multiple values were seen, an error results.)

Return value is a list of objects of the same sort as returned by parse_annotated_text().
]=]
local function parse_multivalued_annotated_text(val, fullname, explicit_gloss, explicit_gloss_fullname)
	if not val then
		return nil
	end
	-- NOTE: In the code that follows, we use `entity` most of the time to refer to one of the semicolon-separated
	-- values in the multivalued param. Entities are most commonly people (typically authors, editors, translators or
	-- the like), but may be the names of publishers, locations, or other entities. "Entity" can also refer to HTML
	-- entities; in the places where this occurs, the variable name contains 'html' in it.

	-- NOTE: We try hard to optimize this function for the common cases and avoid loading [[Module:parse utilities]]
	-- in such cases. The cases we can handle without loading [[Module:parse utilities]] are single values (no
	-- semicolons present) without inline modifiers or language prefixes, and multi-entity values (semicolons present)
	-- without (a) brackets of any kind (including parens, braces and angle brackets; angle brackets typically indicate
	-- inline modifiers and other brackets may protect a semicolon from being interpreted as a delimiter);
	-- (b) ampersands (which may indicate HTML entities, which protect a semicolon from being interpreted as a
	-- delimiter); and (c) colons not followed by a space (which may indicate a language prefix).
	local function generate_obj(text, parse_err_or_paramname, no_undo_html_entity_replacement)
		local obj = {}
		if text:find(":[^ ]") or text:find("%[%[") then
			obj.text, obj.lang, obj.link = require(parse_utilities_module).parse_term_with_lang(text,
				parse_err_or_paramname)
		else
			obj.text = text
			obj.link = text
		end
		if not no_undo_html_entity_replacement then
			obj.text = undo_html_entity_replacement(obj.text)
			obj.link = undo_html_entity_replacement(obj.link)
		end
		return obj
	end

	local splitchar, english_delim
	if val:find("^,") then
		splitchar = ","
		english_delim = "comma"
		val = val:gsub("^,", "")
	else
		splitchar = ";"
		english_delim = "semicolon"
	end

	-- Optimization #1: No semicolons/commas or angle brackets (indicating inline modifiers).
	if not val:find("[<" .. splitchar .. "]") then
		if val_should_not_be_parsed_for_annotations(val) then
			return {{text = val, link = val, noscript = true}}
		else
			return {generate_obj(val, fullname, "no undo html entity replacement")}
		end
	end

	-- Optimization #2: Semicolons/commas but no angle brackets (indicating inline modifiers), braces, brackets, or
	-- parens (any of which would protect the semicolon/comma from interpretation as a delimiter), and no ampersand
	-- (which might indicate an HTML entity with a terminating semicolon, which should not be interpreted as a
	-- delimiter).
	if not val:find("[<>%[%](){}&]") then
		local entity_objs = {}
		for entity in rgsplit(val, "%s*" .. splitchar .. "%s*") do
			if val_should_not_be_parsed_for_annotations(entity) then
				table.insert(entity_objs, {text = entity, link = entity, noscript = true})
			else
				table.insert(entity_objs, generate_obj(entity, fullname, "no undo html entity replacement"))
			end
		end
		return entity_objs
	end

	-- The rest of the code does the general case. First we replace certain special HTML entities (those that are
	-- bracket-like) with single Unicode characters.
	for _, html_entity_to_repl in ipairs(html_entity_to_replacement) do
		val = rsub(val, html_entity_to_repl.entity_pat or html_entity_to_repl.entity, html_entity_to_repl.repl)
	end
	-- HTML entities per https://en.wikipedia.org/wiki/List_of_XML_and_HTML_character_entity_references must be either
	-- decimal numeric (&#8209;), hexadecimal numeric (&#x200E;) or named (&Aring;, &frac34;, etc.). In all three
	-- cases, we replace the semicolon with a special character so it won't get interpreted as a delimiter.
	val = val:gsub("(&#[0-9]+);", "%1" .. TEMP_SEMICOLON)
	val = val:gsub("(&#x[0-9a-fA-F]+);", "%1" .. TEMP_SEMICOLON)
	val = val:gsub("(&[0-9a-zA-Z_]+);", "%1" .. TEMP_SEMICOLON)
	val = val:gsub(L2R, ""):gsub(R2L, "")

	local put = require(parse_utilities_module)

	-- Parse balanced segment runs, treating HTML entities for left and right bracket and left and right angle bracket
	-- as matching literal versions of the same characters.
	local entity_runs = put.parse_multi_delimiter_balanced_segment_run(val,
		{{"[" .. TEMP_LBRAC, "]" .. TEMP_RBRAC}, {"(", ")"}, {"{", "}"}, {"<" .. TEMP_LT, ">" .. TEMP_GT}},
		true)
	if type(entity_runs) == "string" then
		local undo_val = undo_html_entity_replacement(val)
		-- Parse error due to unbalanced delimiters. Don't throw an error here; instead, don't attempt to parse off
		-- any annotations, but return the value directly, maybe allowing script tagging (not allowing it if it appears
		-- the text is already script-tagged).
		return {{text = undo_val, link = undo_val, noscript = not not val_should_not_be_parsed_for_annotations(val)}}
	end

	-- Split on semicolon (or comma), possibly surrounded by whitespace.
	local separated_groups = put.split_alternating_runs(entity_runs, "%s*" .. splitchar .. "%s*")

	-- Process each value.
	local entity_objs = {}
	for _, entity_group in ipairs(separated_groups) do
		-- Rejoin runs that don't involve <...>.
		local j = 2
		while j <= #entity_group do
			if not entity_group[j]:find("^<.*>$") then
				entity_group[j - 1] = entity_group[j - 1] .. entity_group[j] .. entity_group[j + 1]
				table.remove(entity_group, j)
				table.remove(entity_group, j)
			else
				j = j + 2
			end
		end

		local oneval = undo_html_entity_replacement(table.concat(entity_group))
		-- When checking for inline modifiers, exclude HTML entry with <span ...>, <i ...>, <br/> or similar in it,
		-- caused by wrapping an argument in {{l|...}}, {{lang|...}} or similar. Also exclude URL's from being parsed
		-- as having language code prefixes. This works analogously to parse_annotated_text(); see there for more.
		if val_should_not_be_parsed_for_annotations(oneval) then
			table.insert(entity_objs, {text = oneval, link = oneval, noscript = true})
		else
			local obj
			if #entity_group > 1 then
				-- Check for inline modifier.
				obj = put.parse_inline_modifiers_from_segments {
					group = entity_group,
					arg = oneval,
					props = {
						paramname = fullname,
						param_mods = param_mods,
						generate_obj = generate_obj,
					}
				}
			else
				obj = generate_obj(entity_group[1], fullname)
			end
			table.insert(entity_objs, obj)
		end
	end

	if explicit_gloss then
		if #entity_objs > 1 then
			error(("Can't specify |%s= along with multiple %s-separated entities in |%s=; use the <t:...> "
				.. "inline modifier attached to the individual entities"):format(
				explicit_gloss_fullname, english_delim, fullname))
		end
		entity_objs[1].gloss = explicit_gloss
	end

	return entity_objs
end


--[=[
Format a text property that may be in a foreign language or script, along with annotations. This is conceptually
similar to the full_link() function in [[Module:links]], but displays the annotations in a different format that is
more appropriate for bibliographic entries. The output looks like this:

TEXT [TRANSLIT /TRANSCRIPTION/, GLOSS]

`textobj` is as returned by parse_annotated_text(). `tag_text`, if supplied, is a function of one argument to further
wrap the text after it has been processed and CSS-tagged appropriately, directly before insertion. `tag_gloss` is a
similar function for the gloss.
]=]
local function format_annotated_text(textobj, tag_text, tag_gloss)
	if not textobj then
		return nil
	end
	local text, link = textobj.text, textobj.link
	local subst, tr, ts, f, gloss, alt = textobj.subst, textobj.tr, textobj.ts, textobj.f, textobj.gloss, textobj.alt

	if alt then
		if link:find("%[%[") or link:find("%]%]") then
			errmsg = ("Can't currently handled embedded links in '%s', with <alt:...> text '%s'"):format(link, alt)
			error(require(parse_utilities_module).escape_wikicode(errmsg))
		end
		text = ("[[%s|%s]]"):format(link, alt)
	end

	-- See above for `noscript`, meaning HTML was found in the text value, probably generated using {{lang|...}}.
	-- {{lang}} already script-tags the text and processes embedded language links, so we don't want to do it again (in
	-- fact, the code below within the if-clause is similar to what {{lang}} does). In such a case, an explicit language
	-- won't be available and findBestScriptWithoutLang() may not be accurate, so we can't do automatic transliteration.
	if not textobj.noscript then
		local lang = textobj.lang
		-- As an optimization, don't do script detection on an argument that contains only ASCII.
		local sc = textobj.sc or lang and lang:findBestScript(text) or not text:find("^[ -~]$") and
			require(scripts_module).findBestScriptWithoutLang(text) or nil
		-- As an optimization, don't do any of the following if there's no language, script, translit or transcription,
		-- as will be the case with simple ASCII values.
		if lang or sc or tr or ts then
			lang = lang or require(languages_module).getByCode("und", true)

			if tr == "-" then
				tr = nil
			elseif not tr and sc and not sc:getCode():find("Lat") then -- Latn, Latf, Latg, pjt-Latn
				-- might return nil
				local text_for_tr = text
				if subst then
					text_for_tr = require(usex_module).apply_subst(text_for_tr, subst)
				else
					text_for_tr = require(links_module).remove_links(text)
				end

				tr = (lang:transliterate(text_for_tr, sc))
			end

			text = require(links_module).embedded_language_links{
				term = text,
				lang = lang,
				sc = sc,
			}
			if lang:getCode() ~= "und" or sc:getCode() ~= "Latn" then
				text = require(script_utilities_module).tag_text(text, lang, sc)
			end

			if tr then
				-- Should we link to the transliteration of languages with lang:link_tr()? Probably not because `text` is not
				-- likely to be a term that has an entry.
				tr = require(script_utilities_module).tag_translit(tr, lang, "usex")
			end
			if ts then
				ts = require(script_utilities_module).tag_transcription(ts, lang, "usex")
			end
		end
	end

	text = require(italics_module).unitalicize_brackets(text)
	if tag_text then
		text = tag_text(text)
	end

	local parts = {}
	local function ins(txt)
		table.insert(parts, txt)
	end

	if textobj.q then
		ins(require(qualifier_module).format_qualifier(textobj.q) .. " ")
	end

	ins(text)

	if tr or ts or f or gloss then
		local parts = {}
		ins(SPACE_LBRAC)
		if tr or ts then
			local tr_ts
			if ts then
				ts = "/" .. ts .. "/"
			end
			if tr and ts then
				tr_ts = tr .. " " .. ts
			else
				tr_ts = tr or ts
			end
			table.insert(parts, tr_ts)
		end
		if f then
			for _, ff in ipairs(f) do
				local sc = ff.sc
				local lang
				if not sc and ff.quals then
					local qual = ff.quals[1]
					if type(qual) == "string" then
						-- do nothing; we'll do script detection farther down
					elseif qual:hasType("script") then
						sc = qual
					else -- language
						sc = qual:findBestScript(ff.val)
						lang = qual
					end
				end
				lang = lang or require(languages_module).getByCode("und", true)
				sc = sc or require(scripts_module).findBestScriptWithoutLang(ff.val)
				local val = require(links_module).embedded_language_links{
					term = ff.val,
					lang = lang,
					sc = sc
				}
				if lang:getCode() ~= "und" or sc:getCode() ~= "Latn" then
					val = require(script_utilities_module).tag_text(val, lang, sc)
				end
				local qual_prefix
				if ff.quals then
					for i, qual in ipairs(ff.quals) do
						if type(qual) ~= "string" and (qual:hasType("script") or qual:hasType("language")) then
							ff.quals[i] = qual:getCanonicalName()
						end
					end
					qual_prefix = table.concat(ff.quals, "/") .. ": "
				else
					qual_prefix = ""
				end
				table.insert(parts, qual_prefix .. val)
			end
		end
		if gloss then
			gloss = '<span class="e-translation">' .. gloss .. "</span>"
			gloss = require(italics_module).unitalicize_brackets(gloss)
			if tag_gloss then
				gloss = tag_gloss(gloss)
			end
			table.insert(parts, gloss)
		end
		ins(table.concat(parts, ", "))
		ins(RBRAC)
	end

	if textobj.qq then
		ins(" " .. require(qualifier_module).format_qualifier(textobj.qq))
	end

	return table.concat(parts)
end


--[=[
Format a multivalued text property that may be in a foreign language or script, along with annotations. This is the
multivalued analog to format_annotated_text(), and formats each individual entity using format_annotated_text(),
joining the results with `delimiter`, which defaults to ", ". It `delimiter` is "and" or "or", join the results using
serialCommaJoin() in [[Module:table]] with the specified conjunction.

`textobjs` is as returned by parse_multivalued_annotated_text(). `tag_text` and `tag_gloss` are as in
format_annotated_text().
]=]
local function format_multivalued_annotated_text(textobjs, delimiter, tag_text, tag_gloss)
	if not textobjs then
		return nil
	end
	if #textobjs == 1 then
		return format_annotated_text(textobjs[1], tag_text, tag_gloss)
	end
	local parts = {}
	for _, textobj in ipairs(textobjs) do
		table.insert(parts, format_annotated_text(textobj, tag_text, tag_gloss))
	end
	if rfind(parts[#parts], "^'*et al[.']*$") then
		-- Special handling for 'et al.'
		parts[#parts] = "''et al.''"
		if #parts == 2 then
			return table.concat(parts, " ")
		end
		if delimiter == "and" or delimiter == "or" then
			delimiter = ", "
		end
		return table.concat(parts, delimiter)
	end
	if delimiter == "and" or delimiter == "or" then
		return require(table_module).serialCommaJoin(parts, {conj = delimiter})
	else
		return table.concat(parts, delimiter or ", ")
	end
end


-- Fancy version of ine() (if-not-empty). Converts empty string to nil, but also strips leading/trailing space.
local function ine(arg)
	if not arg then return nil end
	arg = mw.text.trim(arg)
	if arg == "" then return nil end
	return arg
end


local abbrs = {
	["a."] = { anchor = "a.", full = "ante", },
	["c."] = { anchor = "c.", full = "circa", },
	["p."] = { anchor = "p.", full = "post", },
}

-- Process prefixes 'a.' (ante), 'c.' (circa) and 'p.' (post) at the beginning of an arbitrary date or year spec.
-- Returns two values, the formatted version of the prefix and the date spec minus the prefix. If no prefix is found,
-- returns an empty string and the full date.
local function process_ante_circa_post(date)
	local prefix = usub(date, 1, 2)
	local abbr = abbrs[prefix]
	local abbr_prefix = ""

	if abbr then
		abbr_prefix = "''[[Appendix:Glossary#" .. abbr.anchor .. '|<abbr title="' .. abbr.full .. '">' ..
			abbr.anchor .. "</abbr>]]'' "
		-- Remove lowercase letter, period, and space from beginning of date parameter.
		date = rsub(date, "^%l%.%s*", "")
	end

	return abbr_prefix, date
end


-- Format the arguments that specify the date of the quotation. These include the following:
-- |date=: The date. If |start_date= is given, this is the end date.
-- |year=, |month=: Year and month of quotation date or end of range, if |date= isn't given.
-- |start_date=: The start date, to specify a range.
-- |start_year=, |start_month=: Year and month of start of range, if |start_date= isn't given.
-- |accessdate=: Date a website was accessed; processed if no other date was given.
-- |nodate=: Indicate that no date is present; otherwise a maintenance line will be displayed if there is no date.
--
-- If `parampref` and/or `paramsuf` are given, this modifies all the date arguments accordingly. For example, if
-- `parampref` == "orig" and `paramsuf` is omitted, the date is specified using |origdate= or |origyear=/|origmonth=,
-- and the start of the range is |origstart_date=, etc. Similarly, if `parampref` is omitted and `paramsuf` is
-- "_published", the date is specified using |date_published= or |year_published=/|month_published=, and the start of
-- the range is |start_date_published=, etc.
--
-- `a` and `get_full_paramname` are functions with the same interpretation as the local functions of the same name in
-- source(). These are used to fetch parameters and get their full names. Note that this may cause all arguments to
-- have an index added to them (|date2=, |year2=, |month2=, etc.).
--
-- `alias_map` is as in source() and is used to map canonical arguments to their aliases when aliases were used.
--
-- If `bold_year` is given, displayed years are boldfaced unless boldface is present in the parameter value.
--
-- If `maintenance_line_no_date` is specified, it should be a string that will be returned if no date is found (i.e.
-- neither |date= nor |year=, or their appropriate equivalents per `parampref` and `paramsuf`, are specified, and
-- neither |nodate= is given to indicate that there is no date, or |accessdate= is given).
--
-- Returns two values: the formatted date and a boolean indicating whether to add a maintenance category
-- [[:Category:Requests for date in LANG entries]]. The first return value will be nil if nothing is to be added
-- (in which case the scond return value will always be nil).
local function format_date_args(a, get_full_paramname, alias_map, parampref, paramsuf, bold_year,
	maintenance_line_no_date)
	local output = {}

	parampref = parampref or ""
	paramsuf = paramsuf or ""
	local function getp(param)
		return a(parampref .. param .. paramsuf)
	end
	local function pname(param)
		local fullname = get_full_paramname(parampref .. param .. paramsuf)
		return alias_map[fullname] or fullname
	end

	local function ins(text)
		table.insert(output, text)
	end

	-- Format `timestamp` (a timestamp referencing a date) according to the spec in `code`. `param` is the base name of
	-- the parameter from which the timestamp was fetched, for error messages.
	local function format_date_with_code(code, timestamp, param)
		local language = mw.getContentLanguage()
		local ok, date = pcall(language.formatDate, language, code, timestamp)
		if ok then
			return date
		else
			-- All the formats used in format_date_args() are fine, so the timestamp must be at fault.
			error(("Timestamp |%s=%s (possibly canonicalized from its original format) could not be parsed; see the "
				.. "[[mw:Help:Extension:ParserFunctions##time|documentation for the #time parser function]]"
				):format(pname(param), tostring(timestamp)))
		end
	end

	-- Try to figure out if the given timestamp has the day of the month explicitly given. We use the following
	-- algorithm:
	-- 1. Format as year-month-day; if the day is not 1, the day was explicitly given, since if only the year/month are
	--    given, the day shows up as 1.
	-- 2. If the day shows up as 1 and there isn't a 1 or 01 in the timestamp, the day wasn't explicitly given.
	-- 3. Otherwise, if there are three separate numbers (e.g. 2022-07-01), or two separate numbers plus a capitalized
	--    letter (taken as an English month, e.g. 2022 July 1), the day was explicitly given, otherwise not.
	--
	-- `param` is the base name of the parameter from which the timestamp was fetched.
	local function date_has_day_specified(timestamp, param)
		local day = format_date_with_code("j", timestamp, param)
		if day ~= "1" then
			return true
		end
		local english_month = timestamp:find("[A-Z]")
		local canon_timestamp = mw.text.trim((timestamp:gsub("[^0-9]+", " ")))
		local seen_nums = rsplit(canon_timestamp, " ")
		local saw_one = false
		for _, num in ipairs(seen_nums) do
			if num == "1" or num == "01" then
				saw_one = true
				break
			end
		end
		if not saw_one then
			return false
		end
		return #seen_nums >= 3 or english_month and #seen_nums >= 2
	end


	-- Format a date with boldfaced year, as e.g. '''2023''' August 3. `explicit_day_given` indicates whether to include
	-- the day; if false, the return value will be e.g. '''2023''' August. `date_param` is the base name of the param
	-- from which the date was fetched, for error messages.
	local function format_bold_date(date, explicit_day_given, date_param)
		local month_day_code = explicit_day_given and "F j" or "F"
		if bold_year then
			-- This formats like "'''2023''' August 3" (or "'''2023''' August" if day not explicitly given).
			return format_date_with_code("'''Y''' " .. month_day_code, date, date_param)
		else
			-- This formats like "2023 August 3" (or "2023 August" if day not explicitly given).
			return format_date_with_code("Y " .. month_day_code, date, date_param)
		end
	end

	-- The formatDate method of the mw.language object behaves like the {{#time:}} parser function, which doesn't
	-- accept the formats "monthday monthname, year" or "year monthname monthday", but outputs garbage when it receives
	-- them, behavior inherited from PHP. {{#formatdate:}} magic word is more forgiving. Fix dates so that, for
	-- instance, the |date= parameter of {{quote-journal}} (which uses this code) and the |accessdate= parameter (which
	-- uses {{#formatdate:}}) accept similar date formats. See:
	-- * [[mw:Extension:Scribunto/Lua_reference_manual#mw.language:formatDate]]
	-- * [[mw:Help:Extension:ParserFunctions##time]]
	-- * [[mw:Help:Magic_words#Formatting]]
	-- `date` is the date spec from the user, which is assumed to come from a parameter whose base name ends in "date";
	-- `parampref` is the prefix added to "date" to get the parameter name.
	local function fix_date(date, param_pref)
		if tonumber(date) ~= nil then
			error(("|%s= should contain a full date (year, month, day of month); use |%s= for year"):
				format(pname(param_pref .. "date"), pname(param_pref .. "year")))
		elseif date and date:find "%s*%a+,%s*%d+%s*$" then
			error(("|%s= should contain a full date (year, month, day of month); use |%s=, |%s= for month and year"):
				format(pname(param_pref .. "date"), pname(param_pref .. "month"), pname(param_pref .. "year")))
		end
		if date then
			date = rsub(date, "(%d+ %a+),", "%1")
			date = rsub(date, "^(%d%d%d%d) (%a+ %d%d?)$", "%2 %1")
			return date
		end
	end

	local start_date, date = fix_date(getp("start_date"), "start_"), fix_date(getp("date"), "")
	local year = getp("year")
	local month = getp("month")
	local start_year = getp("start_year")
	local start_month = getp("start_month")

	if date and year then
		error(("Only one of |%s= or |%s= should be specified"):format(pname("date"), pname("year")))
	end
	if date and month then
		error(("|%s= should only be specified in conjunction with |%s=, not with |%s="):
			format(pname("month"), pname("year"), pname("date")))
	end
	if start_date and start_year then
		error(("Only one of |%s= or |%s= should be specified"):format(pname("start_date"), pname("start_year")))
	end
	if start_date and start_month then
		error(("|%s= should only be specified in conjunction with |%s=, not with |%s="):
			format(pname("start_month"), pname("start_year"), pname("start_date")))
	end
	if (start_date or start_year) and not (date or year) then
		error(("|%s= or |%s=/|%s= cannot be specified without specifying |%s= or |%s=/|%s="):
			format(pname("start_date"), pname("start_year"), pname("start_month"),
				pname("date"), pname("year"), pname("month")))
	end

	local dash = "&nbsp;– "

	local day_explicitly_given = date and date_has_day_specified(date, "date")
	local start_day_explicitly_given = start_date and date_has_day_specified(start_date, "start_date")

	-- Format a date with boldfaced year, as e.g. '''2023''' August 3 (if `explicit_day_given` specified) or
	-- '''2023''' August (if `explicit_day_given` not specified). If no date specified, fall back to formatting based
	-- on the year and (optionally) month params given in `yearobj` and `monthobj`, boldfacing the year if not already.
	-- `date_param` is the base name of the param from which the date was fetched, for error messages.
	local function format_date_or_year_month(date, yearobj, monthobj, explicit_day_given, date_param)
		if date then
			return format_bold_date(date, explicit_day_given, date_param)
		else
			-- Boldface a year spec if it's not already boldface.
			if bold_year and not yearobj.text:find("'''") then
				-- Clone the year object before modifying it because we may use it later to check against the current
				-- year (if we're dealing with start_year).
				yearobj = require(table_module).shallowcopy(yearobj)
				yearobj.text = "'''" .. yearobj.text .. "'''"
				if yearobj.alt then
					yearobj.alt = "'''" .. yearobj.alt .. "'''"
				end
			end
			return format_annotated_text(yearobj) .. (monthobj and " " .. format_annotated_text(monthobj) or "")
		end
	end

	local yearobj = parse_annotated_text(year, pname("year"))
	local monthobj = parse_annotated_text(month, pname("month"))
	local start_yearobj = parse_annotated_text(start_year, pname("start_year"))
	local start_monthobj = parse_annotated_text(start_month, pname("start_month"))

	if yearobj then
		local abbr_prefix
		abbr_prefix, yearobj.text = process_ante_circa_post(yearobj.text)
		_, yearobj.link = process_ante_circa_post(yearobj.link)
		ins(abbr_prefix)
	end

	if start_date or start_year then
		ins(format_date_or_year_month(start_date, start_yearobj, start_monthobj, start_day_explicitly_given,
			"start_date"))
		local cur_year = yearobj and yearobj.text or format_date_with_code("Y", date, "date")
		local cur_month = monthobj and monthobj.text or date and format_date_with_code("F", date, "date") or nil
		local cur_day = date and day_explicitly_given and format_date_with_code("j", date, "date") or nil
		local beg_year = start_yearobj and start_yearobj.text or format_date_with_code("Y", start_date, "start_date")
		local beg_month = start_monthobj and start_monthobj.text or
			start_date and format_date_with_code("F", start_date, "start_date") or nil
		local beg_day = start_date and start_day_explicitly_given and
			format_date_with_code("j", start_date, "start_date") or nil

		if cur_year ~= beg_year then
			-- Different years; insert current date in full.
			if not cur_month or cur_month == beg_month then
				ins("–")
			else
				ins(dash)
			end
			ins(format_date_or_year_month(date, yearobj, monthobj, day_explicitly_given, "date"))
		elseif cur_month and cur_month ~= beg_month then
			local month_ins = monthobj and format_annotated_text(monthobj) or cur_month
			-- Same year but different months; insert current month and (if available) current day.
			if cur_day then
				ins(dash)
				ins(month_ins)
				ins(" " .. cur_day)
			else
				if beg_day then
					ins(dash)
				else
					ins("–")
				end
				ins(month_ins)
			end
		elseif cur_day and cur_day ~= beg_day then
			-- Same year and month but different days; insert current day.
			ins("–")
			ins(cur_day)
		else
			-- Same year, month and day; or same year and month, and day not available; or same year, and month and
			-- day not available. Do nothing. FIXME: Should we throw an error?
		end
	elseif date or yearobj then
		ins(format_date_or_year_month(date, yearobj, monthobj, day_explicitly_given, "date"))
	elseif not maintenance_line_no_date then
		-- Not main quote date. Return nil, caller will handle.
		return nil, nil
	elseif not getp("nodate") then
		local accessdate = getp("accessdate")
		if accessdate then
			local explicit_day_given = date_has_day_specified(accessdate, "accessdate")
			ins(format_bold_date(accessdate, explicit_day_given, "accessdate") .. " (last accessed)")
		else
			if mw.title.getCurrentTitle().nsText ~= "Template" then
				return maintenance_line(maintenance_line_no_date), true
			else
				return nil, nil
			end
		end
	end

	return ine(table.concat(output)), nil
end


local function tag_with_cite(txt)
	return "<cite>" .. txt .. "</cite>"
end


local function pluralize(txt)
	-- Try to shortcut loading [[Module:string utilities]].
	if txt:find("[sxzhy%]]$") then
		return require(string_utilities_module).pluralize(txt)
	else
		return txt .. "s"
	end
end


-- Display the source line of the quote, above the actual quote text. This contains the majority of the logic of this
-- module (formerly contained in {{quote-meta/source}}).
function export.source(args, alias_map)
	local tracking_categories = {}

	local argslang = args.lang or args[1]
	if not argslang then
		-- For the moment, only trigger an error on mainspace pages and
		-- other pages that are not user pages or pages containing discussions.
		-- These are the same pages that appear in the appropriate tracking
		-- categories. User and discussion pages have not generally been
		-- fixed up to include a language code and so it's more helpful
		-- to use a maintenance line than signal an error.
		local FULLPAGENAME = mw.title.getCurrentTitle().fullText
		local NAMESPACE = mw.title.getCurrentTitle().nsText

		if NAMESPACE ~= "Template" and not require(usex_templates_module).page_should_be_ignored(FULLPAGENAME) then
			require(languages_module).err(nil, 1)
		end
	end

	-- Given a canonical param, convert it to the original parameter specified by the user (which may have been an
	-- alias).
	local function alias(param)
		return alias_map[param] or param
	end

	local output = {}
	local sep

	-- Add text to the output. The text goes into a list, and we concatenate all the list components together at the
	-- end. To make it easier to handle comma-separated items, we keep track (in `sep`) of the separator (if any) that
	-- needs to be inserted before the next item added. For example, if we're in the "newversion" code (ind ~= ""), and
	-- there's no title and no URL, then the first time we add anything after the title, we don't want to add a
	-- separating comma because the preceding text will say "republished " or "republished as " or "translated as " or
	-- similar. In all- other cases, we do want to add a separating comma. The bare add() function reset the separator
	-- to be nothing, while the add_with_sep() function resets the separator to be the value of `next_sep` (defaulting
	-- to ", "), so the next time around we do add a comma to separate `text` from the preceding piece of text.
	local function add(text)
		if sep then
			table.insert(output, sep)
		end
		table.insert(output, text)
		sep = nil
	end
	local function add_with_sep(text, next_sep)
		add(text)
		sep = next_sep or ", "
	end

	-- Return a function that generates the actual parameter name associated with a base param (e.g. "author", "last").
	-- The actual parameter name may have an index added (an empty string for the first set of params, e.g. author=,
	-- last=, or a numeric index for further sets of params, e.g. author2=, last2=, etc.).
	local function make_get_full_paramname(ind)
		return function(param)
			return param .. ind
		end
	end
	-- Function to fetch the actual parameter name associated with a base param (see make_get_full_paramname() above).
	-- Assigned at various times below by calling make_get_full_paramname(). We do it this way so that we can have
	-- wrapper functions that access params and define them only oncec.
	local get_full_paramname
	-- Return two values: the value of a parameter given the base param name (which may have a numeric index added),
	-- and the parameter name from which the value was fetched (which may be an alias, i.e. you can't necessarily fetch
	-- the parameter value from args[] given this name). The base parameter can be a list of such base params, which
	-- are checked in turn, or nil, in which case nil is returned.
	local function a_with_name(param)
		if type(param) == "table" then
			for _, par in ipairs(param) do
				local val, fullname = a_with_name(par)
				if val then
					return val, fullname
				end
			end
			return nil
		end
		if not param then
			return nil
		end
		local fullname = get_full_paramname(param)
		return args[fullname], alias(fullname)
	end
	-- Fetch the value of a parameter given the base param name (which may have a numeric index added). The base
	-- parameter can be a list of such base params, which are checked in turn, or nil, in which case nil is returned.
	local function a(param)
		return (a_with_name(param))
	end

	-- Identical to a_with_name(param) except that it verifies that no space is present. Should be used for URL's.
	local function aurl_with_name(param)
		local value, fullname = a_with_name(param)
		if value and value:find(" ") and not value:find("%[") then
			error(("URL not allowed to contain a space, but saw |%s=%s"):format(fullname, value))
		end
		return value, fullname
	end
	-- Identical to a(param) except that it verifies that no space is present. Should be used for URL's.
	local function aurl(param)
		return (aurl_with_name(param))
	end

	-- Convenience function to fetch a parameter that may be in a foreign language or text (and may consequently have
	-- a language prefix and/or inline modifiers), parse the annotations and convert the result into a formatted string.
	-- This is the same as parse_and_format_annotated_text() below but also returns the full param name as the second
	-- return value.
	local function parse_and_format_annotated_text_with_name(param, tag_text, tag_gloss)
		local val, fullname = a_with_name(param)
		local obj = parse_annotated_text(val, fullname)
		return format_annotated_text(obj, tag_text, tag_gloss), fullname
	end

	-- Convenience function to fetch a parameter that may be in a foreign language or text (and may consequently have
	-- a language prefix and/or inline modifiers), parse the modifiers and convert the result into a formatted string.
	-- This is a wrapper around parse_annotated_text() and format_annotated_text(). `param` is the base parameter name (see
	-- a_with_name()), `tag_text` is an optional function to tag the parameter text after all other processing (e.g.
	-- wrap in <cite>...</cite> tags), and `tag_gloss` is a similar function for the parameter translation/gloss.
	local function parse_and_format_annotated_text(param, tag_text, tag_gloss)
		return (parse_and_format_annotated_text_with_name(param, tag_text, tag_gloss))
	end

	-- Convenience function to fetch a multivalued parameter that may be in a foreign language or text (and may
	-- consequently have a language prefix and/or inline modifiers), parse the modifiers and convert the result into a
	-- formatted string. This is the multivalued analog to parse_and_format_annotated_text_with_name() and returns two
	-- values, the formatted string and the full name of the parameter fetched. `delimiter` is as in
	-- format_multivalued_annotated_text().
	local function parse_and_format_multivalued_annotated_text_with_name(param, delimiter, tag_text, tag_gloss)
		local val, fullname = a_with_name(param)
		local objs = parse_multivalued_annotated_text(val, fullname)
		local num_objs = objs and #objs or 0
		return format_multivalued_annotated_text(objs, delimiter, tag_text, tag_gloss), fullname, num_objs
	end

	-- Convenience function to fetch a multivalued parameter that may be in a foreign language or text (and may
	-- consequently have a language prefix and/or inline modifiers), parse the modifiers and convert the result into a
	-- formatted string. This is the multivalued analog to parse_and_format_annotated_text(). `delimiter` is as in
	-- format_multivalued_annotated_text().
	local function parse_and_format_multivalued_annotated_text(param, delimiter, tag_text, tag_gloss)
		return (parse_and_format_multivalued_annotated_text_with_name(param, delimiter, tag_text, tag_gloss))
	end

	-- This determines whether to display "Mary Bloggs, transl." (if there's no author preceding) or "translated by
	-- Mary Bloggs" (if there's an author preceding).
	local author_outputted = false

	local function is_anonymous(val)
		return rfind(val, "^[Aa]nonymous$") or rfind(val, "^[Aa]non%.?$")
	end

	-- Add a formatted author (whose values may be specified using `author` or, for compatibility purposes, split
	-- among various parameters):
	-- * `author` is the value of the author param (e.g. "author", "author2" or "2ndauthor"), and `author_fullname` is
	--   the full parameter name holding that value;
	-- * `trans_author` is the optional value of the param holding the gloss/translation of the author, and
	--   `trans_author_fullname` is the full parameter name holding that value (or nil for no such parameter);
	-- * `authorlink` is the value of the authorlink param, which holds the Wikipedia link of the author(s) in `author`,
	--    and `authorlink_fullname` is the full parameter name holding that value;
	-- * `trans_authorlink` is the optional value of the param holding the Wikipedia link of the gloss/translation of
	--    the author, and `trans_authorlink_fullname` is the full parameter name holding that value (or nil for no such
	--    parameter);
	-- * `first` is the value of the parameter holding the first name of the author, and `first_fullname` is the full
	--    parameter name holding that value;
	-- * `trans_first` is the value of the corresponding parameter holding the gloss/translation of the first name
	--    (e.g. "trans-first"), and `trans_first_fullname` is the full parameter name holding that value (or nil for
	--    no such parameter);
	-- * `last` is the value of the parameter holding the last name of the author, and `last_fullname` is the full
	--    parameter name holding that value;
	-- * `trans_last` is the value of the corresponding parameter holding the gloss/translation of the last name
	--    (e.g. "trans-last"), and `trans_last_fullname` is the full parameter name holding that value (or nil for
	--    no such parameter).
	local function add_author(author, author_fullname, trans_author, trans_author_fullname, authorlink,
		authorlink_fullname, trans_authorlink, trans_authorlink_fullname, first, first_fullname, trans_first,
		trans_first_fullname, last, last_fullname, trans_last, trans_last_fullname)
		local function make_author_with_url(txt, txtparam, authorlink, authorlink_param)
			if authorlink then
				if authorlink:find("%[%[") then
					error(("Can't specify links in |%s=%s"):format(authorlink_param, authorlink))
				end
				if txt:find("%[%[") then
					error(("Can't specify links in %s=%s"):format(txtparam, txt))
				end
				return "[[w:" .. authorlink .. "|" .. txt .. "]]"
			else
				return txt
			end
		end

		local num_authorobjs
		if author then
			local authorobjs = parse_multivalued_annotated_text(author, author_fullname, trans_author,
				trans_author_fullname)
			num_authorobjs = #authorobjs
			if num_authorobjs == 1 then
				if is_anonymous(authorobjs[1].text) then
					authorobjs[1].text = "anonymous author"
					authorobjs[1].link = "anonymous author"
				end
				if authorlink then
					authorobjs[1].text = make_author_with_url(authorobjs[1].text, "|" .. author_fullname,
						authorlink, "|" .. authorlink_fullname)
					authorobjs[1].link = make_author_with_url(authorobjs[1].link, "|" .. author_fullname,
						authorlink, "|" .. authorlink_fullname)
				end
				if authorobjs[1].gloss and trans_authorlink then
					authorobjs[1].gloss = make_author_with_url(authorobjs[1].gloss,
						("<t:...> in |%s"):format(author_fullname), trans_authorlink, "|" .. trans_author_fullname)
				end
				add(format_multivalued_annotated_text(authorobjs))
			elseif trans_authorlink then
				error(("Can't specify |%s= along with multiple semicolon-separated entities in |%s=; use the "
					.. "<t:...> inline modifier attached to the individual entities and put the link directly "
					.. "in the value of the inline modifier"):format(trans_authorlink_fullname, author_fullname))
			else
				-- Allow an authorlink with multiple authors, e.g. for use with |author=Max Mills; Harvey Mills
				-- with |authorlink=Max and Harvey. For this we have to generate the entire text and link it
				-- all.
				local formatted_text = format_multivalued_annotated_text(authorobjs)
				if authorlink then
					formatted_text = make_author_with_url(formatted_text, "|" .. author_fullname, authorlink,
						"|" .. authorlink_fullname)
				end
				add(formatted_text)
			end
		else
			num_authorobjs = 1
			-- Author separated into first name + last name. We don't currently support non-Latin-script
			-- authors separated this way and probably never will.
			if first then
				author = first .. " " .. last
			else
				author = last
			end
			if authorlink then
				local authorparam = first and ("|%s |%s"):format(first_fullname, last_fullname) or "|" .. last_fullname
				author = make_author_with_url(author, authorparam, authorlink, authorlink_fullname)
			end
			local trans_author
			if trans_last then
				if trans_first then
					trans_author = trans_first .. " " .. trans_last
				else
					trans_author = trans_last
				end
				if trans_authorlink then
					local trans_authorparam = trans_first and
						("|%s |%s"):format(trans_first_fullname, trans_last_fullname) or "|" .. trans_last_fullname
					trans_author = make_author_with_url(trans_author, trans_authorparam, trans_authorlink,
						trans_authorlink_fullname)
				end
			end
			add(author)
			if trans_author then
				add(SPACE_LBRAC)
				add(trans_author)
				add(RBRAC)
			end
		end

		author_outputted = true

		return num_authorobjs
	end

	local function add_authorlike(param, prefix_with_preceding_authors, suffix_without_preceding_authors,
		suffix_if_multiple, anonymous_suffix)
		local delimiter = author_outputted and "and" or ", "
		local entities, _, num_entities = parse_and_format_multivalued_annotated_text_with_name(param, delimiter)
		if not entities then
			return
		end
		if is_anonymous(entities) then
			-- If tlr=anonymous or similar given, display as "anonymous translator" or similar. If a specific
			-- anonymous suffix not given, try to derive the anonymous suffix from the non-preceding-author suffix.
			if not anonymous_suffix then
				local cleaned_suffix = suffix_without_preceding_authors:gsub("&#32;", " "):gsub("&nbsp;", " ")
					:gsub("&#160;", " "):gsub("&#91;", "["):gsub("&#93;", "]")
				cleaned_suffix = mw.text.trim(cleaned_suffix)
				if not anonymous_suffix then
					anonymous_suffix = " " .. cleaned_suffix:match("^, (.*)$")
				end
				if not anonymous_suffix then
					anonymous_suffix = " " .. cleaned_suffix:match("^%((.*)%)$")
				end
				if not anonymous_suffix then
					anonymous_suffix = " " .. cleaned_suffix:match("^%[(.*)%]$")
				end
				if not anonymous_suffix then
					anonymous_suffix = suffix_without_preceding_authors
				end
			end
			add_with_sep("anonymous" .. anonymous_suffix)
		elseif prefix_with_preceding_authors and (author_outputted or not suffix_without_preceding_authors) then
			add_with_sep(prefix_with_preceding_authors .. entities)
		elseif suffix_if_multiple and num_entities > 1 then
			add_with_sep(entities .. suffix_if_multiple)
		else
			add_with_sep(entities .. suffix_without_preceding_authors)
		end
		author_outputted = true
	end

	local function add_authorlabel()
		local default_authorlabel = a("default-authorlabel")
		if default_authorlabel and yesno(a("authorlabel"), true) then
			sep = nil
			add_with_sep(" " .. default_authorlabel)
		end
	end

	local function has_new_title_or_author()
		return args["2ndauthor"] or args["2ndlast"] or args.chapter2 or args.title2 or
			args.tlr2 or args.mainauthor2 or args.editor2 or args.editors2 or args.compiler2 or args.compilers2 or
			args.director2 or args.directors2
	end

	local function has_newversion()
		return args.newversion or args.location2 or has_new_title_or_author()
	end

	-- Handle chapter=, section=, etc. `param` is the base name of the parameter in question, e.g. "chapter" or
	-- "section". If numeric (either Arabic or Roman), add `numeric_prefix`; otherwise, parse as textual (allowing for
	-- language prefixes, inline modifiers, etc.), prefix with `textual_prefix` (if given) and suffix with
	-- `textual_suffix` (if given). Also checks for and handles the following (assuming param == "chapter"):
	-- * chapterurl=: URL of the chapter.
	-- * trans-chapter=: Chapter translation (can be given using an inline modifier <t:...>).
	-- * chapter_number=: Chapter number, when chapter= is also given (otherwise put the chapter number in chapter=).
	-- * chapter_plain=: Plain version of the chapter number; the "chapter " prefix isn't added.
	-- * chapter_series=: Series that the chapter is within (used e.g. for journal articles part of a series).
	-- * chapter_seriesvolume=: Volume of the series (compare seriesvolume=).
	--
	-- Returns nil if no value specified for the main parameter, otherwise the formatted value.
	local function format_chapterlike(param, numeric_prefix, textual_prefix, textual_suffix)
		local chap, chap_fullname = a_with_name(param)
		local chap_num, chap_num_fullname = a_with_name(param .. "_number")
		local chap_plain, chap_plain_fullname = parse_and_format_annotated_text_with_name(param .. "_plain")
		if chap_num and chap_plain then
			error(("Specify only one of |%s= or %s="):format(chap_num_fullname, chap_plain_fullname))
		end
		local chap_series, chap_series_fullname =
			parse_and_format_annotated_text_with_name(param .. "_series", tag_with_cite, tag_with_cite)
		local chap_seriesvolume, chap_seriesvolume_fullname =
			parse_and_format_annotated_text_with_name(param .. "_seriesvolume")
		if chap_series then
			chap_series = ", " .. chap_series
		end
		if chap_seriesvolume then
			if not chap_series then
				error(("Cannot specify |%s= without %s="):format(chap_series_fullname, chap_seriesvolume_fullname))
			end
			chap_series = chap_series .. " (" .. chap_seriesvolume .. ")"
		end

		if not chap then
			if chap_num then
				error(("Cannot specify |%s= without |%s=; put the numeric value in |%s= directly"):
					format(chap_num_fullname, chap_fullname, chap_fullname))
			end
			if chap_plain then
				return chap_plain .. (chap_series or "")
			end
			return nil
		end

		local cleaned_chap = chap:gsub("<sup>[^<>]*</sup>", ""):gsub("[*+#]", "")
		local chapterurl = aurl(param .. "url")
		local function make_chapter_with_url(chap)
			if chapterurl then
				return "[" .. chapterurl .. " " .. chap .. "]"
			else
				return chap
			end
		end

		local formatted

		if require(number_utilities_module).get_number(cleaned_chap) then
			-- Arabic chapter number
			formatted = numeric_prefix .. make_chapter_with_url(chap)
		elseif rfind(cleaned_chap, "^[mdclxviMDCLXVI]+$") and require(roman_numerals_module).roman_to_arabic(cleaned_chap, true) then
			-- Roman chapter number
			formatted = numeric_prefix .. make_chapter_with_url(mw.ustring.upper(chap))
		else
			-- Must be a chapter name
			local chapterobj = parse_annotated_text(chap, chap_fullname, a("trans-" .. param))
			chapterobj.text = make_chapter_with_url(chapterobj.text)
			chapterobj.link = make_chapter_with_url(chapterobj.link)
			formatted = (textual_prefix or "") .. format_annotated_text(chapterobj) .. (textual_suffix or "")
		end

		if chap_num or chap_plain then
			-- NOTE: Up above we throw an error if both chap_num and chap_plain are specified.
			formatted = formatted .. " (" .. (chap_plain or numeric_prefix .. chap_num) .. ")"
		end
		if chap_series then
			formatted = formatted .. chap_series
		end

		return formatted
	end

	------------------- Now we start outputting text ----------------------

	-- Set this now so a() works just below.
	get_full_paramname = make_get_full_paramname("")

	if args.brackets then
		add("[")
	end

	local need_comma = false
	local formatted_date, need_date = format_date_args(a, get_full_paramname, alias_map, nil, nil, "bold year",
		"Can we [[:Category:Requests for date|date]] this quote?")
	if formatted_date then
		need_comma = true
		add(formatted_date)
	end

	-- Fetch origdate=/origyear=/origmonth= and format appropriately.
	local formatted_origdate = format_date_args(a, get_full_paramname, alias_map, "orig")
	if formatted_origdate then
		need_comma = true
		add(SPACE_LBRAC .. formatted_origdate .. RBRAC)
	end

	if need_comma then
		sep = ", "
	end

	-- Find maximum indexed author or last name.
	local maxind = math.max(args.author.maxindex, args.last.maxindex)
	-- Include max index of ancillary params so we get an error message about their use without the primary params.
	local ancillary_params = { "trans-author", "authorlink", "trans-authorlink", "first", "trans-first", "trans-last" }
	for _, ancillary in ipairs(ancillary_params) do
		maxind = math.max(maxind, args[ancillary].maxindex)
	end

	local num_authors = 0
	for i = 1, maxind do
		local ind = i == 1 and "" or i
		local author = args.author[i]
		local last = args.last[i]
		if args.author[i] or args.last[i] then
			local this_num_authors = add_author(args.author[i], "author" .. ind, args["trans-author"][i],
				"trans-author" .. ind, args.authorlink[i], "authorlink" .. ind, args["trans-authorlink"][i],
				"trans-authorlink" .. ind, args.first[i], "first" .. ind, args["trans-first"][i], "trans-first" .. ind,
				args.last[i], "last" .. ind, args["trans-last"][i], "trans-last" .. ind)
			num_authors = num_authors + this_num_authors
			sep = ", "
		else
			for _, cant_have in ipairs(ancillary_params) do
				if args[cant_have][i] then
					error(("Can't have |%s%s= without |author%s= or |last%s="):format(cant_have, ind, ind, ind))
				end
			end
		end
	end

	-- This handles everything after displaying the author, starting with the chapter and ending with page, column,
	-- line and then other=. It is currently called twice: Once to handle the main portion of the citation, and once to
	-- handle a "newversion" citation. `ind` is either "" for the main portion or a number (currently only 2) for a
	-- "newversion" citation. In a few places we conditionalize on `ind` to take actions depending on its value.
	local function postauthor(ind, num_authors)
		get_full_paramname = make_get_full_paramname(ind)

		if author_outputted then
			add_authorlabel()
		end

		local coauthors = parse_and_format_multivalued_annotated_text("coauthors", "and")
		if coauthors then
			local with_prefix = ""
			if author_outputted then
				with_prefix = "with "
				if num_authors == 1 then
					sep = " "
				end
			end
			add_with_sep(with_prefix .. coauthors)
			author_outputted = true
		end

		add_authorlike("quotee", "quoting ", ", quotee", ", quotees")

		add_authorlike("chapter_tlr", "translated by ", ", transl.", nil, " translator")

		local formatted_chapter = format_chapterlike("chapter", "chapter ", "“", "”")
		if formatted_chapter then
			add_with_sep(formatted_chapter)
			if not a("notitle") then
				add("in ")
				author_outputted = false
			end
		end

		local mainauthor = parse_and_format_multivalued_annotated_text("mainauthor")
		if mainauthor then
			add_with_sep(mainauthor)
			author_outputted = true
		end

		add_authorlike("tlr", "translated by ", ", transl.", nil, " translator")

		local function add_sg_and_pl_authorlike(noun, verbed)
			local sgparam = noun
			local plparam = noun .. "s"
			local sgval, sgval_fullname = a_with_name(sgparam)
			local plval, plval_fullname = a_with_name(plparam)
			if sgval and plval then
				error(("Can't specify both |%s= and |%s="):format(sgval_fullname, plval_fullname))
			end
			if sgval or plval then
				local verbed_by = verbed .. " by "
				local comma_sgnoun = ", " .. noun
				local comma_plnoun = ", " .. noun .. "s"
				add_authorlike(sgparam, verbed_by, comma_sgnoun, comma_plnoun)
				add_authorlike(plparam, verbed_by, comma_plnoun)
			end
		end

		add_sg_and_pl_authorlike("editor", "edited")
		add_sg_and_pl_authorlike("compiler", "compiled")
		add_sg_and_pl_authorlike("director", "directed")

		add_authorlike("lyricist", nil, " (lyrics)", nil, " lyricist")
		add_authorlike("lyrics-translator", nil, " (translation)", nil, " lyrics translator")
		add_authorlike("composer", nil, " (music)", nil, " composer")

		local title, title_fullname = a_with_name("title")
		local need_comma = false
		if title then
			local titleobj = parse_annotated_text(title, title_fullname, a("trans-title"))
			add(format_annotated_text(titleobj, tag_with_cite, tag_with_cite))
			local series = parse_and_format_annotated_text("series")
			if series then
				add(" (" .. series)
				local seriesvolume = parse_and_format_annotated_text("seriesvolume")
				if seriesvolume then
					add(SEMICOLON_SPACE .. seriesvolume)
				end
				add(")")
			end
			need_comma = true
		elseif ind == "" then
			if not a("notitle") then
				add(maintenance_line("Please provide the book title or journal name"))
				need_comma = true
			end
		end

		local archiveurl, archiveurl_fullname = aurl_with_name("archiveurl")
		local url, url_fullname = aurl_with_name("url")
		local urls, urls_fullname = aurl_with_name("urls")
		if url and urls then
			error(("Supply only one of |%s= and |%s="):format(url_fullname, urls_fullname))
		end
		local function verify_title_supplied(url_name)
			if not title then
				-- There are too many cases of this to throw an error at this time.
				-- error(("If |%s= is given, |%s= must also be supplied"):format(url_name, title_fullname))
			end
		end
		if archiveurl or url then
			verify_title_supplied(archiveurl and archiveurl_fullname or url_fullname)
			sep = nil
			add("&lrm;<sup>[" .. (archiveurl or url) .. "]</sup>")
		elseif urls then
			verify_title_supplied(urls_fullname)
			sep = nil
			add("&lrm;<sup>" .. urls .. "</sup>")
		end

		if need_comma then
			sep = ", "
		end

		local edition, edition_fullname = parse_and_format_annotated_text_with_name("edition")
		local edition_plain, edition_plain_fullname = parse_and_format_annotated_text_with_name("edition_plain")
		if edition and edition_plain then
			error(("Supply only one of |%s= and |%s="):format(edition_fullname, edition_plain_fullname))
		end
		if edition then
			add_with_sep(edition .. " edition")
		end
		if edition_plain then
			add_with_sep(edition_plain)
		end

		-- Display a numeric param such as page=, volume=, column=. For each `paramname`, four params are actually
		-- recognized, e.g. for paramname == "page", the params page=, pages=, page_plain= and pageurl= are recognized
		-- and checked (or the same with an index, e.g. page2=, pages2=, page_plain2= and pageurl2= respectively if
		-- ind == "2"). Only one of the first three can be specified; an error results if more than one are given.
		-- If none are given, the return value is nil; otherwise it is a string. The numeric spec is taken directly
		-- from e.g. page_plain= if given; otherwise if e.g. pages= is given, or if page= is given and looks like a
		-- combination of numbers (i.e. it has a hyphen or dash in it, a comma, or the word " and "), it is prefixed
		-- by `singular_desc` + "s" (e.g. "pages "), otherwise it is prefixed by just `singular_desc` (e.g. "page ").
		-- (As a special case, if either e.g. page=unnumbered or pages=unnumbered is given, the numeric spec is
		-- "unnumbered page".) The resulting spec is returned directly unless e.g. pageurl= is given, in which case
		-- it is linked to the specified URL. Note that any of the specs can be foreign text, e.g. foreign numbers
		-- (including with optional inline modifiers), and such text is handled appropriately.
		local function format_numeric_param(paramname, singular_desc)
			local sgval, sg_fullname = a_with_name(paramname)
			local sgobj = parse_annotated_text(sgval, paramname)
			local plparamname = paramname .. "s"
			local plval, pl_fullname = a_with_name(plparamname)
			local plobj = parse_annotated_text(plval, plparamname)
			local plainval, plain_fullname = parse_and_format_annotated_text_with_name(paramname .. "_plain")
			local howmany = (sgval and 1 or 0) + (plval and 1 or 0) + (plainval and 1 or 0)
			if howmany > 1 then
				local params_specified = {}
				local function insparam(param)
					if param then
						table.insert(params_specified, ("|%s="):format(param))
					end
				end
				insparam(sg_fullname)
				insparam(pl_fullname)
				insparam(plain_fullname)
				error(("Can't specify more than one of %s"):format(
					require(table_module).serialCommaJoin(params_specified, {dontTag = true})))
			end
			if howmany == 0 then
				return nil
			end
			-- Merge page= and pages= and treat alike because people often mix them up in both directions.
			local numspec
			if plainval then
				numspec = plainval
			else
				local val = sgobj and sgobj.text or plobj.text
				if val == "unnumbered" then
					numspec = "unnumbered " .. singular_desc
				else
					local function get_plural_desc()
						-- Only call when needed to potentially avoid a module load.
						return pluralize(singular_desc)
					end
					local desc
					if val:find("^!") then
						val = val:gsub("^!", "")
						desc = sgval and singular_desc or get_plural_desc()
					else
						local check_val = val
						if check_val:find("%[") then
							check_val = require(links_module).remove_links(check_val)
							-- convert URL's of the form [URL DISPLAY] to the displayed value
							check_val = check_val:gsub("%[[^ %[%]]* ([^%[%]]*)%]", "%1")
						end
						-- in case of negative page numbers (do they exist?), don't treat as multiple pages
						check_val = check_val:gsub("^%-", "")
						-- replace HTML entity en-dashes and em-dashes with their literal codes
						check_val = check_val:gsub("&ndash;", "–")
						check_val = check_val:gsub("&#8211;", "–")
						check_val = check_val:gsub("&mdash;", "—")
						check_val = check_val:gsub("&#8212;", "—")
						-- Check for en-dash or em-dash, or two numbers (possibly with stuff after like 12a-15b)
						-- separated by a hyphen or by comma a followed by a space (to avoid firing on thousands separators).
						if rfind(check_val, "[–—]") or check_val:find(" and ") or rfind(check_val, "[0-9]+[^ ]* *%- *[0-9]+")
							or rfind(check_val, "[0-9]+[^ ]* *, +[0-9]+")  then
							desc = get_plural_desc()
						else
							desc = singular_desc
						end
					end
					local obj = sgobj or plobj
					obj.text = val
					if obj.link:find("^!") then
						obj.link = obj.link:gsub("^!", "")
					end
					val = format_annotated_text(obj)
					numspec = desc .. " " .. val
				end
			end
			local url = a(paramname .. "url")
			if url then
				return "[" .. url .. " " .. numspec .. "]"
			else
				return numspec
			end
		end

		local volume = format_numeric_param("volume", a("volume_prefix") or "volume")
		if volume then
			add_with_sep(volume)
		end

		local issue = format_numeric_param("issue", a("issue_prefix") or "number")
		if issue then
			add_with_sep(issue)
		end

		-- number= is an alias for issue= (except in {{quote-av}}, where it is the episode number)
		local number = format_numeric_param("number", a("number_prefix") or "number")
		if number then
			add_with_sep(number)
		end

		local annotations = {}
		local genre = a("genre")
		if genre then
			table.insert(annotations, genre)
		end
		local format = a("format")
		if format then
			table.insert(annotations, format)
		end
		local medium = a("medium")
		if medium then
			table.insert(annotations, medium)
		end

		-- Now handle the display of language annotations like "(in French)" or
		-- "(quotation in Nauruan; overall work in German)".
		local quotelang = args.lang or args[1]
		local quotelang_fullname = 1
		if not quotelang then
			if ind == "" then
				-- This can only happen for certain non-mainspace pages, e.g. Talk pages; otherwise an error is thrown
				-- above.
				table.insert(annotations, maintenance_line("Please specify the language of the quote using |1="))
			else
				-- do nothing in newversion= portion
			end
		elseif ind == "" then
			local worklang, worklang_fullname = a_with_name("worklang")
			local termlang, termlang_fullname = a_with_name("termlang")
			worklang = worklang or quotelang
			termlang = termlang or quotelang

			if worklang == quotelang then
				if worklang == termlang then
					-- do nothing
				else
					table.insert(annotations, "in " .. format_langs(quotelang, quotelang_fullname))
				end
			else
				if quotelang ~= termlang then
					table.insert(annotations, "quotation in " .. format_langs(quotelang, quotelang_fullname))
				end
				table.insert(annotations, "overall work in " .. format_langs(worklang, worklang_fullname))
			end
		else
			local lang2, lang2_fullname = a_with_name("lang")
			if lang2 then
				table.insert(annotations, "in " .. format_langs(lang2, lang2_fullname))
			end
		end

		if #annotations > 0 then
			sep = nil
			add_with_sep(" (" .. table.concat(annotations, SEMICOLON_SPACE) .. ")")
		end

		local artist = parse_and_format_multivalued_annotated_text("artist", "and")
		if artist then
			add_with_sep("performed by " .. artist)
		end

		local feat = parse_and_format_multivalued_annotated_text("feat", "and")
		if feat then
			sep = " "
			add_with_sep("ft. " .. feat)
		end
	
		local role = parse_and_format_multivalued_annotated_text("role", "and")
		local actor_val, actor_fullname = a_with_name("actor")
		local actor_objs = parse_multivalued_annotated_text(actor_val, actor_fullname)
		local actor = format_multivalued_annotated_text(actor_objs, "and")
		if role then
			add_with_sep("spoken by " .. role)
			if actor then
				sep = nil
				add_with_sep(" (" .. actor .. ")")
			end
		elseif actor then
			add_with_sep(actor .. " (" .. (#actor_objs > 1 and "actors" or "actor") .. ")")
		end

		local others = parse_and_format_annotated_text("others")
		if others then
			add_with_sep(others)
		end
		local quoted_in = parse_and_format_annotated_text("quoted_in", tag_with_cite, tag_with_cite)
		if quoted_in then
			add_with_sep("quoted in " .. quoted_in)
			table.insert(tracking_categories, "Quotations using quoted-in parameter")
		end

		local location = parse_and_format_multivalued_annotated_text("location")
		local publisher = parse_and_format_multivalued_annotated_text("publisher", "; ")
		if publisher then
			if location then
				add_with_sep(location) -- colon
				sep = "&#58; " -- colon
			end
			add_with_sep(publisher)
		elseif location then
			add_with_sep(location)
		end

		local source = parse_and_format_multivalued_annotated_text("source", "and")
		if source then
			add_with_sep("sourced from " .. source)
		end

		local original = parse_and_format_annotated_text("original", tag_with_cite, tag_with_cite)
		local by = parse_and_format_multivalued_annotated_text("by", "and")
		local origtype = a("deriv") or "translation"
		if original or by then
			add_with_sep(origtype .. " of " .. (original or "original") .. (by and " by " .. by or ""))
		end

		-- Handle origlang=, origworklang=. How we handle them depends on whether the original title or author are explicitly
		-- given.
		local origlang, origlang_fullname = a_with_name("origlang")
		local origworklang, origworklang_fullname = a_with_name("origworklang")
		local origlangtext, origworklangtext
		if origlang then
			origlangtext = "in " .. format_langs(origlang, origlang_fullname)
		end
		if origworklang then
			origworklangtext = "overall work in " .. format_langs(origworklang, origworklang_fullname)
		end
		if origlang or origworklang then
			if original or by then
				local orig_annotations = {}
				if origlangtext then
					table.insert(orig_annotations, origlangtext)
				end
				if origworklangtext then
					table.insert(orig_annotations, origworklangtext)
				end
				sep = nil
				add_with_sep(" (" .. table.concat(orig_annotations, SEMICOLON_SPACE) .. ")")
			else
				add_with_sep(origtype .. " of original" .. (origlangtext and " " .. origlangtext or ""))
				if origworklangtext then
					sep = nil
					add_with_sep(" (" .. origworklangtext .. ")")
				end
			end
		end

		-- Fetch date_published=/year_published=/month_published= and format appropriately.
		local formatted_date_published = format_date_args(a, get_full_paramname, alias_map, "", "_published")
		local platform = parse_and_format_multivalued_annotated_text("platform", "and")
		if formatted_date_published then
			add_with_sep("published " .. formatted_date_published .. (platform and " via " .. platform or ""))
		elseif platform then
			add_with_sep("via " .. platform)
		end

		if ind ~= "" and has_newversion() then
			local formatted_new_date, this_need_date = format_date_args(a, get_full_paramname, alias_map, "", "", nil, 
				"Please provide a date or year")
			need_date = need_date or this_need_date
			if formatted_new_date then
				add_with_sep(formatted_new_date)
			end
		end

		-- From here on out, there should always be a preceding item, so we
		-- can dispense with add_with_sep() and always insert the comma.
		sep = nil

		local function small(txt)
			add(", <small>")
			add(txt)
			add("</small>")
		end

		-- Add an identifier to a book or article database such as DOI, ISBN, JSTOR, etc. `param_or_params`
		-- is a string identifying the base param, or a list of such strings to check in turn. If found, the value
		-- of the parameter is processed using `process` (a function of one argument, defaulting to mw.uri.encode()),
		-- and then the actual URL to insert is generated by preceding with `pretext`, following with `posttext`,
		-- and running the resulting string through small(), which first adds a comma and then the URL in small font.
		local function add_identifier(param_or_params, pretext, posttext, process)
			local val = a(param_or_params)
			if val then
				val = (process or mw.uri.encode)(val)
				small(pretext .. val .. posttext)
			end
		end

		add_identifier("bibcode", "[https://adsabs.harvard.edu/abs/", " →Bibcode]")
		add_identifier("doi", "<span class=\"neverexpand\">[https://doi.org/", " →DOI]</span>")
		add_identifier("isbn", "", "", isbn)
		add_identifier("issn", "", "", issn)
		add_identifier("jstor", "[https://www.jstor.org/stable/", " →JSTOR]")
		add_identifier("lccn", "", "", lccn)
		add_identifier("oclc", "[https://www.worldcat.org/title/", " →OCLC]")
		add_identifier("ol", "[https://openlibrary.org/works/OL", "/ →OL]")
		add_identifier("pmid", "[https://www.ncbi.nlm.nih.gov/pubmed/", " →PMID]")
		add_identifier("pmcid", "[https://www.ncbi.nlm.nih.gov/pmc/articles/", "/ →PMCID]")
		add_identifier("ssrn", "[https://ssrn.com/abstract=", " →SSRN]")
		local id = a("id")
		if id then
			small(id)
		end

		local archiveurl, archiveurl_fullname = aurl_with_name("archiveurl")
		if archiveurl then
			add(", archived from ")
			local url, url_fullname = aurl_with_name("url")
			if not url then
				-- attempt to infer original URL from archive URL; this works at
				-- least for Wayback Machine (web.archive.org) URL's
				url = rmatch(archiveurl, "/(https?:.*)$")
				if not url then
					error(("When |%s= is specified, |%s= must also be included"):format(archiveurl_fullname,
						url_fullname))
				end
			end
			add("[" .. url .. " the original] on ")
			local archivedate, archivedate_fullname = a_with_name("archivedate")
			if archivedate then
				add(format_date(archivedate))
			elseif (string.sub(archiveurl, 1, 28) == "https://web.archive.org/web/") then
				-- If the archive is from the Wayback Machine, then it already contains the date
				-- Get the date and format into ISO 8601
				local wayback_date = string.sub(archiveurl, 29, 29+7)
				wayback_date = string.sub(wayback_date, 1, 4) .. "-" .. string.sub(wayback_date, 5, 6) .. "-" ..
					string.sub(wayback_date, 7, 8)
				add(format_date(wayback_date))
			else
				error(("When |%s= is specified, |%s= must also be included"):format(
					archiveurl_fullname, archivedate_fullname))
			end
		end
		if a("accessdate") then
			--Otherwise do not display here, as already used as a fallback for missing date= or year= earlier.
			if (a("date") or a("nodate") or a("year")) and not a("archivedate") then
				add(", retrieved " .. format_date(a("accessdate")))
			end
		end

		local formatted_section = format_chapterlike("section", "section ")
		if formatted_section then
			add(", ")
			add(formatted_section)
		end

		-- video game stuff
		local system = parse_and_format_annotated_text("system")
		if system then
			add(", " .. system)
		end
		local scene = parse_and_format_annotated_text("scene")
		if scene then
			add(", scene: " .. scene)
		end
		local level = parse_and_format_annotated_text("level")
		if level then
			add(", level/area: " .. level)
		end

		local note = parse_and_format_annotated_text("note")
		if note then
			add(", " .. note)
		end

		local note_plain = parse_and_format_annotated_text("note_plain")
		if note_plain then
			add(" " .. note_plain)
		end

		-- Wrapper around format_numeric_param that inserts the formatted text with optional preceding text.
		local function handle_numeric_param(paramname, singular_desc, pretext)
			local numspec = format_numeric_param(paramname, singular_desc)
			if numspec then
				add((pretext or "") .. numspec)
			end
		end

		handle_numeric_param("page", a("page_prefix") or "page", ", ")
		handle_numeric_param("column", a("column_prefix") or "column", ", ")
		handle_numeric_param("line", a("line_prefix") or "line", ", ")
		-- FIXME: Does this make sense? What is other=?
		local other = parse_and_format_annotated_text("other")
		if other then
			add(", " .. other)
		end
	end

	-- Display all the text that comes after the author, for the main portion.
	postauthor("", num_authors)

	author_outputted = false

	-- If there's a "newversion" section, add the new-version text.
	if has_newversion() then
		sep = nil
		--Test for new version of work.
		add(SEMICOLON_SPACE)
		if args.newversion then -- newversion= is intended for English text, e.g. "quoted in" or "republished as".
			add(args.newversion)
		elseif not args.edition2 then
			if has_new_title_or_author() then
				add("republished as")
			else
				add("republished")
			end
		end
		add(" ")
		sep = ""
	else
		sep = ", "
	end

	-- Add the newversion author(s).
	if args["2ndauthor"] or args["2ndlast"] then
		num_authors = add_author(args["2ndauthor"], "2ndauthor", nil, nil, args["2ndauthorlink"], "2ndauthorlink", nil,
			nil, args["2ndfirst"], "2ndfirst", nil, nil, args["2ndlast"], "2ndlast", nil, nil)
		sep = ", "
	else
		for _, cant_have in ipairs { "2ndauthorlink", "2ndfirst" } do
			if args[cant_have] then
				error(("Can't have |%s= without |2ndauthor= or |2ndlast="):format(cant_have))
			end
		end
	end

	-- Display all the text that comes after the author, for the "newversion" section.
	postauthor(2, num_authors)

	if not args.nocolon then
		sep = nil
		add(":")
	end

	-- Concatenate output portions to form output text.
	local output_text = table.concat(output)

	-- Remainder of code handles adding categories. We add one or more of the following categories:
	--
	-- 1. [[Category:LANG terms with quotations]], based on the first language code in termlang= or 1=. Added to
	--    mainspace, Reconstruction: and Appendix: pages as well as Citations: pages if the corresponding mainspace
	--    page exists. Not added if nocat= is given. Note that [[Module:usex]] adds the same category using the same
	--    logic, but we do it here too because we may not have a quotation to format. (We add in those circumstances
	--    because typically when there's no quotation to format, it's because it's formatted manually underneath the
	--    citation, or using {{ja-x}}, {{th-x}} or similar.)
	-- 2. [[Category:Requests for date in LANG entries]], based on the first language code in 1=. Added to mainspace,
	--    Reconstruction:, Appendix: and Citations: pages unless nocat= is given.
	-- 3. [[Category:Quotations using nocat parameter]], if nocat= is given. Added to mainspace, Reconstruction:,
	--    Appendix: and Citations: pages.

	local categories = {}

	local termlang = get_first_lang(args.termlang or argslang, true)

	if args.nocat then
		table.insert(tracking_categories, "Quotations using nocat parameter")
	else
		local title
		if args.pagename then -- for testing, doc pages, etc.
			title = mw.title.new(args.pagename)
			if not title then
				error(("Bad value for `args.pagename`: '%s'"):format(args.pagename))
			end
		else
			title = mw.title.getCurrentTitle()
		end
		-- Only add [[Citations:foo]] to [[:Category:LANG terms with quotations]] if [[foo]] exists.
		local ok_to_add_cat
		if title.nsText ~= "Citations" then
			ok_to_add_cat = true
		else
			local mainspace_title = mw.title.new(title.text)
			if mainspace_title and mainspace_title.exists then
				ok_to_add_cat = true
			end
		end
		if ok_to_add_cat then
			table.insert(categories, termlang:getNonEtymologicalName() .. " terms with quotations")
		end
		if need_date then
			local argslangobj = get_first_lang(argslang, 1)
			table.insert(categories, "Requests for date in " .. argslangobj:getCanonicalName() .. " entries")
		end
	end

	local FULLPAGENAME = mw.title.getCurrentTitle().fullText
	return output_text .. (not lang and "" or
		(#categories > 0 and require(utilities_module).format_categories(categories, lang, args.sort) or "") ..
		(#tracking_categories > 0 and require(utilities_module).format_categories(tracking_categories, lang, args.sort,
			nil, not require(usex_templates_module).page_should_be_ignored(FULLPAGENAME)) or ""))
end


-- Alias specs for type= and type2=. Each spec is `{canon, aliases, with_newversion}` where `canon` is the canonical
-- parameter (with "2" added if type2= is being handled), `aliases` is a comma-separated string of aliases (with "2"
-- added if type2= is being handled, except for numeric params), and `with_newversion` indicates whether we should
-- process this spec if type2= is being handled.
local type_alias_specs = {
	book = {
		{"author", "3"},
		{"chapter", "entry", true},
		{"chapterurl", "entryurl", true},
		{"trans-chapter", "trans-entry", true},
		{"chapter_series", "entry_series", true},
		{"chapter_seriesvolume", "entry_seriesvolume", true},
		{"chapter_number", "entry_number", true},
		{"chapter_plain", "entry_plain", true},
		{"title", "4"},
		{"url", "5"},
		{"year", "2"},
		{"page", "6"},
		{"text", "7"},
		{"t", "8"},
	},
	journal = {
		{"year", "2"},
		{"author", "3"},
		{"chapter", "title,article,4", true},
		{"chapterurl", "titleurl,articleurl", true},
		{"trans-chapter", "trans-title,trans-article", true},
		{"chapter_tlr", "article_tlr", true},
		{"chapter_series", "article_series", true},
		{"chapter_seriesvolume", "article_seriesvolume", true},
		{"chapter_number", "article_number", true},
		{"chapter_plain", "title_plain,article_plain", true},
		{"title", "journal,magazine,newspaper,work,5", true},
		{"trans-title", "trans-journal,trans-magazine,trans-newspaper,trans-work", true},
		{"url", "6"},
		{"page", "7"},
		{"source", "newsagency", true},
		{"text", "8"},
		{"t", "9"},
	},
}


-- Process interally-handled aliases related to type= or type2=. `args` is a table of arguments; `typ` is the value of
-- type= or type2=; newversion=true if we're dealing with type2=; alias_map is used to keep track of alias mappings
-- seen.
local function process_type_aliases(args, typ, newversion, alias_map)
	local ind = newversion and "2" or ""
	local deprecated = ine(args.lang)
	if not type_alias_specs[typ] then
		local possible_values = {}
		for possible, _ in pairs(type_alias_specs) do
			table.insert(possible_values, possible)
		end
		table.sort(possible_values)
		error(("Unrecognized value '%s' for type%s=; possible values are %s"):format(
			typ, ind, table.concat(possible_values, ",")))
	end

	for _, alias_spec in ipairs(type_alias_specs[typ]) do
		local canon, aliases, with_newversion = unpack(alias_spec)
		if with_newversion or not newversion then
			canon = canon .. ind
			aliases = rsplit(aliases, ",")
			local saw_alias = nil
			for _, alias in ipairs(aliases) do
				if rfind(alias, "^[0-9]+$") then
					alias = tonumber(alias)
					if deprecated then
						alias = alias - 1
					end
				else
					alias = alias .. ind
				end
				if args[alias] then
					if saw_alias == nil then
						saw_alias = alias
					else
						error(("|%s= and |%s= are aliases; cannot specify a value for both"):format(saw_alias, alias))
					end
				end
			end
			if saw_alias and (not newversion or type(saw_alias) == "string") then
				if args[canon] then
					error(("|%s= is an alias of |%s=; cannot specify a value for both"):format(saw_alias, canon))
				end
				args[canon] = args[saw_alias]
				-- Wipe out the original after copying. This important in case of a param that has general significance
				-- but has been redefined (e.g. {{quote-av}} redefines number= for the episode number, and
				-- {{quote-journal}} redefines title= for the chapter= (article). It's also important due to unhandled
				-- parameter checking.
				args[saw_alias] = nil
				alias_map[canon] = saw_alias
			end
		end
	end
end


-- Clone and combine frame's and parent's args while also assigning nil to empty strings. Handle aliases and ignores.
local function clone_args(direct_args, parent_args)
	local args = {}

	-- Processing parent args must come first so that direct args override parent args. Note that if a direct arg is
	-- specified but is blank, it will still override the parent arg (with nil).
	for pname, param in pairs(parent_args) do
		-- [[Special:WhatLinksHere/Template:tracking/quote/param/PARAM]]
		track("param/" .. pname)
		args[pname] = ine(param)
	end

	-- Process ignores. The value of `ignore` is a comma-separated list of parameter names to ignore (erase). We need to
	-- do this before aliases due to {{quote-song}}, which sets chapter= to the value of title= in the direct params and
	-- sets title= to the value of album= using an alias. If we do the ignores after aliases, we get an error during alias
	-- processing, saying that title= and its alias album= are both present.
	local ignores = ine(direct_args.ignore)
	if ignores then
		for ignore in rgsplit(ignores, "%s*,%s*") do
			args[ignore] = nil
		end
	end

	local alias_map = {}

	-- Process internally-specified aliases using type= or type2=.
	local typ = args.type or direct_args.type
	if typ then
		process_type_aliases(args, typ, false, alias_map)
	end
	local typ2 = args.type2 or direct_args.type2
	if typ2 then
		process_type_aliases(args, typ2, true, alias_map)
	end

	-- Process externally-specified aliases. The value of `alias` is a list of semicolon-separated specs, each of which
	-- is of the form DEST:SOURCE,SOURCE,... where DEST is the canonical name of a parameter and SOURCE refers to an
	-- alias. Whitespace is allowed between all delimiters. The order of aliases may be important. For example, for
	-- {{quote-journal}}, title= contains the article name and is an alias of underlying chapter=, while journal= or
	-- work= contains the journal name and is an alias of underlying title=. As a result, the title -> chapter alias
	-- must be specified before the journal/work -> title alias.
	--
	-- Whenever we copy a value from argument SOURCE to argument DEST, we record an entry for the pair in alias_map, so
	-- that when we would display an error message about DEST, we display SOURCE instead.
	--
	-- Do alias processing (and ignore and error_if processing) before processing direct_args so that e.g. we can set up
	-- an alias of title -> chapter and then set title= to something else in the direct args ({{quote-hansard}} does
	-- this).
	--
	-- FIXME: Delete this once we've converted all alias processing to internal.
	local aliases = ine(direct_args.alias)
	if aliases then
		-- Allow and discard a trailing semicolon, to make managing multiple aliases easier.
		aliases = rsub(aliases, "%s*;$", "")
		for alias_spec in rgsplit(aliases, "%s*;%s*") do
			local alias_spec_parts = rsplit(alias_spec, "%s*:%s*")
			if #alias_spec_parts ~= 2 then
				error(("Alias spec '%s' should have one colon in it"):format(alias_spec))
			end
			local dest, sources = unpack(alias_spec_parts)
			sources = rsplit(sources, "%s*,%s*")
			local saw_source = nil
			for _, source in ipairs(sources) do
				if rfind(source, "^[0-9]+$") then
					source = tonumber(source)
				end
				if args[source] then
					if saw_source == nil then
						saw_source = source
					else
						error(("|%s= and |%s= are aliases; cannot specify a value for both"):format(saw_source, source))
					end
				end
			end
			if saw_source then
				if args[dest] then
					error(("|%s= is an alias of |%s=; cannot specify a value for both"):format(saw_source, dest))
				end
				args[dest] = args[saw_source]
				-- Wipe out the original after copying. This important in case of a param that has general significance
				-- but has been redefined (e.g. {{quote-av}} redefines number= for the episode number, and
				-- {{quote-journal}} redefines title= for the chapter= (article). It's also important due to unhandled
				-- parameter checking.
				args[saw_source] = nil
				alias_map[dest] = saw_source
			end
		end
	end

	-- Process error_if. The value of `error_if` is a comma-separated list of parameter names to throw an error if seen
	-- in parent_args (they are params we overwrite in the direct args).
	local error_ifs = ine(direct_args.error_if)
	if error_ifs then
		for error_if in rgsplit(error_ifs, "%s*,%s*") do
			if ine(parent_args[error_if]) then
				error(("Cannot specify a value |%s=%s as it would be overwritten or ignored"):format(error_if, ine(parent_args[error_if])))
			end
		end
	end
	
	for pname, param in pairs(direct_args) do
		-- ignore control params
		if pname ~= "ignore" and pname ~= "alias" and pname ~= "error_if" then
			args[pname] = ine(param)
		end
	end

	return args, alias_map
end

-- External interface, meant to be called from a template. Replaces {{quote-meta}} and meant to be the primary
-- interface for {{quote-*}} templates.
function export.quote_t(frame)
	-- FIXME: We are processing arguments twice, once in clone_args() and then again in [[Module:parameters]]. This is
	-- wasteful of memory.
	local parent_args = frame:getParent().args
	local cloned_args, alias_map = clone_args(frame.args, parent_args)
	local deprecated = ine(parent_args.lang)

	-- First, the "single" params that don't have FOO2 or FOOn versions.
	local params = {
		[deprecated and "lang" or 1] = {required = true, default = "und"},
		newversion = {},
		["2ndauthor"] = {},
		["2ndauthorlink"] = {},
		["2ndfirst"] = {},
		["2ndlast"] = {},
		nocat = {type = "boolean"},
		nocolon = {type = "boolean"},
		lang2 = {},

		-- quote params
		text = {},
		passage = {alias_of = "text"},
		tr = {},
		transliteration = {alias_of = "tr"},
		ts = {},
		transcription = {alias_of = "ts"},
		norm = {},
		normalization = {alias_of = "norm"},
		sc = {},
		normsc = {},
		sort = {},
		subst = {},
		footer = {},
		lit = {},
		t = {},
		translation = {alias_of = "t"},
		gloss = {alias_of = "t"},
		tag = {},
		brackets = {type = "boolean"},
		-- original quote params
		origtext = {},
		origtr = {},
		origts = {},
		orignorm = {},
		origsc = {},
		orignormsc = {},
		origsubst = {},
		origtag = {},
	}

	-- Then the list params (which have FOOn versions).
	local list_spec = {list = true, allow_holes = true}
	for _, list_param in ipairs {
		"author", "last", "first", "authorlink", "trans-author", "trans-last", "trans-first", "trans-authorlink"
	} do
		params[list_param] = list_spec
	end

	-- Then the newversion params (which have FOO2 versions).
	for _, param12 in ipairs {
		-- author-like params; author params themselves are either list params (author=, last=, etc.) or single params
		-- (2ndauthor=, 2ndlast=, etc.)
		"coauthors", "quotee", "tlr", "editor", "editors", "mainauthor", "compiler", "compilers", "director", "directors",
		"lyricist", "lyrics-translator", "composer", "role", "actor", "artist", "feat",

		-- author control params
		"default-authorlabel",
		"authorlabel",

		-- title
		"title", "trans-title", "series", "seriesvolume", "notitle",

		-- chapter
		"chapter", "chapterurl", "chapter_number", "chapter_plain", "chapter_series", "chapter_seriesvolume",
		"trans-chapter", "chapter_tlr",

		-- section
		"section", "sectionurl", "section_number", "section_plain", "section_series", "section_seriesvolume",
		"trans-section",

		-- other video-game params
		"system", "scene", "level",

		-- URL
		"url", "urls", "archiveurl",

		-- edition
		"edition", "edition_plain",

		-- language params
		"worklang", "termlang", "origlang", "origworklang",

		-- ID params
		"bibcode", "doi", "isbn", "issn", "jstor", "lccn", "oclc", "ol", "pmid", "pmcid", "ssrn", "id",

		-- misc date params; most date params handled below
		"archivedate", "accessdate", "nodate",

		-- numeric params handled below

		-- other params
		"type", "genre", "format", "medium", "others", "quoted_in", "location", "publisher",
		"original", "by", "deriv",
		"note", "note_plain",
		"other", "source", "platform",
	} do
		params[param12] = {}
		params[param12 .. "2"] = {}
	end

	-- Then the aliases of newversion params (which have FOO2 versions).
	for _, param12_aliased in ipairs {
		{"role", "roles"},
		{"role", "speaker"},
		{"tlr", "translator"},
		{"tlr", "translators"},
		{"doi", "DOI"},
		{"isbn", "ISBN"},
		{"issn", "ISSN"},
		{"jstor", "JSTOR"},
		{"lccn", "LCCN"},
		{"oclc", "OCLC"},
		{"ol", "OL"},
		{"pmid", "PMID"},
		{"pmcid", "PMCID"},
		{"ssrn", "SSRN"},
	} do
		local canon, alias = unpack(param12_aliased)
		params[alias] = {alias_of = canon}
		params[alias .. "2"] = {alias_of = canon .. "2"}
	end

	-- Then the date params.
	for _, datelike in ipairs { {"", ""}, {"orig", ""}, {"", "_published"} } do
		local pref, suf = unpack(datelike)
		for _, arg in ipairs { "date", "year", "month", "start_date", "start_year", "start_month" } do
			params[pref .. arg .. suf] = {}
			params[pref .. arg .. suf .. "2"] = {}
		end
	end

	-- Then the numeric params.
	for _, numeric in ipairs { "volume", "issue", "number", "line", "page", "column" } do
		for _, suf in ipairs { "", "s", "_plain", "url", "_prefix" } do
			params[numeric .. suf] = {}
			params[numeric .. suf .. "2"] = {}
		end
	end
	
	local args = require(parameters_module).process(cloned_args, params, nil, "quote", "quote_t")

	local parts = {}
	local function ins(text)
		table.insert(parts, text)
	end

	ins('<div class="citation-whole"><span class="cited-source">')
	ins(export.source(args, alias_map))
	ins("</span><dl><dd>")

	local text = args.text
	local gloss = args.t
	local tr = args.tr
	local ts = args.ts
	local norm = args.norm
	local sc = args.sc and require(scripts_module).getByCode(args.sc, "sc") or nil
	local normsc = args.normsc == "auto" and args.normsc or
		args.normsc and require(scripts_module).getByCode(args.normsc, "normsc") or nil

	-- Fetch original-text parameters.
	local origtext, origtextlang, origsc, orignormsc
	if args.origtext then
		-- Wiktionary language codes have at least two lowercase letters followed possibly by lowercase letters and/or
		-- hyphens (there are more restrictions but this is close enough). Also check for nonstandard Latin etymology
		-- language codes (e.g. VL. or LL.). (There used to be more nonstandard codes but they have all been
		-- eliminated.)
		origtextlang, origtext = args.origtext:match("^([a-z][a-z][a-z-]*):([^ ].*)$")
		if not origtextlang then
			-- Special hack for Latin variants, which can have nonstandard etym codes, e.g. VL., LL.
			origtextlang, origtext = args.origtext:match("^([A-Z]L%.):([^ ].*)$")
		end
		if not origtextlang then
			error("origtext= should begin with a language code prefix")
		end
		origtextlang = require("languages").getByCode(origtextlang, "origtext", "allow etym")
		origsc = args.origsc and require(scripts_module).getByCode(args.origsc, "origsc") or nil
		orignormsc = args.orignormsc == "auto" and args.orignormsc or
			args.orignormsc and require(scripts_module).getByCode(args.orignormsc, "orignormsc") or nil
	else
		for _, noparam in ipairs { "origtr", "origts", "origsc", "orignorm", "orignormsc", "origsubst", "origtag" } do
			if args[noparam] then
				error(("Cannot specify %s= without origtext="):format(noparam))
			end
		end
	end

	-- If any quote-related args are present, display the actual quote; otherwise, display nothing.
	if text or gloss or tr or ts or norm or args.origtext then
		-- Pass "und" here rather than cause an error; there will be an error on mainspace, Citations, etc. pages
		-- in any case in source() if the language is omitted.
		local lang = get_first_lang(args[1] or args.lang, 1)
		local termlang = args.termlang and get_first_lang(args.termlang, "termlang") or lang

		local usex_data = {
			lang = lang,
			termlang = termlang,
			usex = text,
			sc = sc,
			translation = gloss,
			normalization = norm,
			normsc = normsc,
			transliteration = tr,
			transcription = ts,
			brackets = args.brackets,
			subst = args.subst,
			lit = args.lit,
			footer = args.footer,
			qq = tags_to_dialects(lang, args.tag),
			quote = "quote-meta",
			orig = origtext,
			origlang = origtextlang,
			origsc = origsc,
			orignorm = args.orignorm,
			orignormsc = orignormsc,
			origtr = args.origtr,
			origts = args.origts,
			origsubst = args.origsubst,
			origqq = tags_to_dialects(lang, args.origtag),
		}
		ins(require(usex_module).format_usex(usex_data))
	end
	ins("</dd></dl></div>")
	local retval = table.concat(parts)
	return deprecated and frame:expandTemplate{title = "check deprecated lang param usage", args = {retval, lang = args.lang}} or retval
end


-- External interface, meant to be called from a template.
function export.call_quote_template(frame)
	local iparams = {
		["template"] = {},
		["textparam"] = {},
		["pageparam"] = {},
		["allowparams"] = {list = true},
		["propagateparams"] = {list = true},
	}
	local iargs, other_direct_args = require(parameters_module).process(frame.args, iparams, "return unknown", "quote", "call_quote_template")
	local direct_args = {}
	for pname, param in pairs(other_direct_args) do
		direct_args[pname] = ine(param)
	end

	local function process_paramref(paramref)
		if not paramref then
			return {}
		end
		local params = rsplit(paramref, "%s*,%s*")
		for i, param in ipairs(params) do
			if rfind(param, "^[0-9]+$") then
				param = tonumber(param)
			end
			params[i] = param
		end
		return params
	end

	local function fetch_param(source, params)
		for _, param in ipairs(params) do
			if source[param] then
				return source[param]
			end
		end
		return nil
	end

	local params = {
		["text"] = {},
		["passage"] = {},
		["footer"] = {},
		["brackets"] = {},
	}
	local textparams = process_paramref(iargs.textparam)
	for _, param in ipairs(textparams) do
		params[param] = {}
	end
	local pageparams = process_paramref(iargs.pageparam)
	if #pageparams > 0 then
		params["page"] = {}
		params["pages"] = {}
		for _, param in ipairs(pageparams) do
			params[param] = {}
		end
	end

	local parent_args = frame:getParent().args
	local allow_all = false
	for _, allowspec in ipairs(iargs.allowparams) do
		for _, allow in ipairs(rsplit(allowspec, "%s*,%s*")) do
			local param = rmatch(allow, "^(.*):list$")
			if param then
				if rfind(param, "^[0-9]+$") then
					param = tonumber(param)
				end
				params[param] = {list = true}
			elseif allow == "*" then
				allow_all = true
			else
				if rfind(allow, "^[0-9]+$") then
					allow = tonumber(allow)
				end
				params[allow] = {}
			end
		end
	end

	local params_to_propagate = {}
	for _, propagate_spec in ipairs(iargs.propagateparams) do
		for _, param in ipairs(process_paramref(propagate_spec)) do
			table.insert(params_to_propagate, param)
			params[param] = {}
		end
	end

	local args = require(parameters_module).process(parent_args, params, allow_all, "quote", "call_quote_template")
	parent_args = require(table_module).shallowcopy(parent_args)

	if textparams[1] ~= "-" then
		other_direct_args.passage = args.text or args.passage or fetch_param(args, textparams)
	end
	if #pageparams > 0 and pageparams[1] ~= "-" then
		other_direct_args.page = fetch_param(args, pageparams) or args.page or nil
		other_direct_args.pages = args.pages
	end
	if args.footer then
		other_direct_args.footer = frame:expandTemplate { title = "small", args = {args.footer} }
	end
	other_direct_args.brackets = args.brackets
	if not other_direct_args.authorlink and other_direct_args.author and not other_direct_args.author:find("[%[<]") and not other_direct_args.author:match("w:") then
		other_direct_args.authorlink = other_direct_args.author
	end
	for _, param in ipairs(params_to_propagate) do
		if args[param] then
			other_direct_args[param] = args[param]
		end
	end

	return frame:expandTemplate { title = iargs.template or "quote-book", args = other_direct_args }
end

local paramdoc_param_replacements = {
	passage = {
		param_with_synonym = '<<synonym>>, {{para|text}}, or {{para|passage}}',
		param_no_synonym = '{{para|text}} or {{para|passage}}',
		text = [=[
* <<params>> – the passage to be quoted.]=],
	},
	page = {
		param_with_synonym = '<<synonym>> or {{para|page}}, or {{para|pages}}',
		param_no_synonym = '{{para|page}} or {{para|pages}}',
		text = [=[
* <<params>> – '''mandatory in some cases''': the page number(s) quoted from. When quoting a range of pages, note the following:
** Separate the first and last pages of the range with an [[en dash]], like this: {{para|pages|10–11}}.
** You must also use {{para|pageref}} to indicate the page to be linked to (usually the page on which the Wiktionary entry appears).
: This parameter must be specified to have the template link to the online version of the work.]=]
	},
	page_with_roman_preface = {
		param_with_synonym = {"inherit", "page"},
		param_no_synonym = {"inherit", "page"},
		text = [=[
* <<params>> – '''mandatory in some cases''': the page number(s) quoted from. If quoting from the preface, specify the page number(s) in lowercase Roman numerals. When quoting a range of pages, note the following:
** Separate the first and last page number of the range with an [[en dash]], like this: {{para|pages|10–11}} or {{para|pages|iii–iv}}.
** You must also use {{para|pageref}} to indicate the page to be linked to (usually the page on which the Wiktionary entry appears).
: This parameter must be specified to have the template link to the online version of the work.]=]
	},
	chapter = {
		param_with_synonym = '<<synonym>> or {{para|chapter}}',
		param_no_synonym = '{{para|chapter}}',
		text = [=[
* <<params>> – the name of the chapter quoted from.]=],
	},
	roman_chapter = {
		param_with_synonym = {"inherit", "chapter"},
		param_no_synonym = {"inherit", "chapter"},
		text = [=[
* <<params>> – the chapter number quoted from in uppercase Roman numerals.]=],
	},
	arabic_chapter = {
		param_with_synonym = {"inherit", "chapter"},
		param_no_synonym = {"inherit", "chapter"},
		text = [=[
* <<params>> – the chapter number quoted from in Arabic numerals.]=],
	},
	trailing_params = {
		text = [=[
* {{para|footer}} – a comment on the passage quoted.
* {{para|brackets}} – use {{para|brackets|on}} to surround a quotation with [[bracket]]s. This indicates that the quotation either contains a mere mention of a term (for example, “some people find the word '''''manoeuvre''''' hard to spell”) rather than an actual use of it (for example, “we need to '''manoeuvre''' carefully to avoid causing upset”), or does not provide an actual instance of a term but provides information about related terms.]=],
	}
}

function export.paramdoc(frame)
	local params = {
		[1] = {},
	}

	local parargs = frame:getParent().args
	local args = require(parameters_module).process(parargs, params, nil, "quote", "paramdoc")

	local text = args[1]

	local function do_param_with_optional_synonym(param, text_to_sub, paramtext_synonym, paramtext_no_synonym)
		local function sub_param(synonym)
			local subbed_paramtext
			if synonym then
				subbed_paramtext = rsub(paramtext_synonym, "<<synonym>>", "{{para|" .. synonym .. "}}")
			else
				subbed_paramtext = paramtext_no_synonym
			end
			return frame:preprocess(rsub(text_to_sub, "<<params>>", subbed_paramtext))
		end
		text = rsub(text, "<<" .. param .. ">>", function() return sub_param() end)
		text = rsub(text, "<<" .. param .. ":(.-)>>", sub_param)
	end

	local function fetch_text(param_to_replace, key)
		local spec = paramdoc_param_replacements[param_to_replace]
		local val = spec[key]
		if type(val) == "string" then
			return val
		end
		if type(val) == "table" and val[1] == "inherit" then
			return fetch_text(val[2], key)
		end
		error("Internal error: Unrecognized value for param '" .. param_to_replace .. "', key '" .. key .. "': "
			.. mw.dumpObject(val))
	end

	for param_to_replace, spec in pairs(paramdoc_param_replacements) do
		local function fetch(key)
			return fetch_text(param_to_replace, key)
		end

		if not spec.param_no_synonym then
			-- Text to substitute directly.
			text = rsub(text, "<<" .. param_to_replace .. ">>", function() return frame:preprocess(fetch("text")) end)
		else
			do_param_with_optional_synonym(param_to_replace, fetch("text"), fetch("param_with_synonym"),
				fetch("param_no_synonym"))
		end
	end

	-- Remove final newline so template code can add a newline after invocation
	text = text:gsub("\n$", "")
	return text
end

return export