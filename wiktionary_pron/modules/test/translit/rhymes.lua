local concat = table.concat
local insert = table.insert
local split = mw.text.split

local export = {}

local force_cat = false -- for testing

local function tag_rhyme(rhyme, lang)
	local formatted_rhyme, cat
	-- FIXME, should not be here. Telugu should use IPA as well.
	if lang:getCode() == "te" then
		formatted_rhyme = require("script utilities").tag_text(rhyme, lang)
		cat = ""
	else
		formatted_rhyme, cat = require("IPA").format_IPA(lang, rhyme, true)
	end
	return formatted_rhyme, cat
end

local function make_rhyme_link(lang, link_rhyme, display_rhyme)
	local retval
	if not link_rhyme then
		retval = concat{"[[Rhymes:", lang:getCanonicalName(), "|", lang:getCanonicalName(), "]]"}
	else
		local formatted_rhyme, cat = tag_rhyme(display_rhyme or link_rhyme, lang)
		retval = concat{"[[Rhymes:", lang:getCanonicalName(), "/", link_rhyme, "|", formatted_rhyme, "]]", cat}
	end
	return retval
end

function export.show_row(frame)
	local args = require("parameters").process(
		frame.getParent and frame:getParent().args or frame,
		{
			[1] = {required = true, type = "language"},
			[2] = {required = true},
			[3] = {},
		}
	)
	
	if not args[1] then
		return "[[Rhymes:English/aɪmz|<span class=\"IPA\">-aɪmz</span>]]"
	end

	return make_rhyme_link(args[1], args[2], "-" .. args[2]) .. (args[3] and (" (''" .. args[3] .. "'')") or "")
end

--[=[

Meant to be called from a module. `data` is a table in the following format:
{
  lang = LANGUAGE_OBJECT,
  rhymes = {
	{rhyme = "RHYME",
	 q = nil or {"LEFT_QUALIFIER", "LEFT_QUALIFIER", ...},
	 qualifiers = nil or {"LEFT_QUALIFIER", "LEFT_QUALIFIER", ...},
	 qq = nil or {"RIGHT_QUALIFIER", "RIGHT_QUALIFIER", ...},
	 a = nil or {"LEFT_ACCENT_QUALIFIER", "LEFT_ACCENT_QUALIFIER", ...},
	 aa = nil or {"RIGHT_ACCENT_QUALIFIER", "RIGHT_ACCENT_QUALIFIER", ...},
	 num_syl = nil or {#SYL, #SYL, ...}
	 }, ...},
  qualifiers = nil or {"QUALIFIER", "QUALIFIER", ...},
  num_syl = nil or {#SYL, #SYL, ...},
  caption = nil or "CAPTION",
  nocaption = BOOLEAN,
  sort = nil or "SORTKEY",
  force_cat = BOOLEAN,
}

Here:

* `lang` is a language object.
* `rhymes` is the list of rhymes to display. RHYME is the IPA rhyme, without initial hyphen. LEFT_QUALIFIER is a
  qualifier string to display before the specific rhyme in question, formatted using format_qualifier() in
  [[Module:qualifier]]. RIGHT_QUALIFIER similarly displays after the rhyme. LEFT_ACCENT_QUALIFIER is an accent qualifier
  (as in {{a}}) to display before the rhyme, and RIGHT_ACCENT_QUALIFIER similarly displays after the rhyme.
  #SYL is the number of syllables of the word or words containing this rhyme, for categorization purposes (see below).
* `qualifiers` (at top level), if non-nil, is a list of qualifier strings to display after the caption "Rhymes:" and
  before the formatted rhymes, formatted using format_qualifier() in [[Module:qualifier]].
* `num_syl` (at top level), if non-nil, a list of the number(s) of syllables of the word or words with each rhyme
  specified in `rhymes`. This applies to all rhymes specified in `rhymes`, while the corresponding `num_syl` attached
  to an individual rhyme applies only to that rhyme (and overrides the global `num_syl`, if both are given).
* `caption`, if specified, overrides the default caption "Rhymes". A colon and space is automatically added after
  the caption.
* `nocaption`, if specified, suppresses the caption entirely.
* `sort`, if specified, is the sort key for categories.
* `force_cat`, if specified, forces categories even on non-mainspace pages (for testing).

Note that the number of syllables is currently used only for categorization; if present, an extra category will
be added such as [[Category:Rhymes:Italian/ino/3 syllables]] in addition to [[Category:Rhymes:Italian/ino]].
]=]
do
	local function add_syllable_categories(categories, lang, rhyme, num_syl)
		local prefix = "Rhymes:" .. lang .. "/" .. rhyme
		insert(categories, prefix)
		if num_syl then
			for _, n in ipairs(num_syl) do
				local c
				if n > 1 then
					c = prefix .. "/" .. n .. " syllables"
				else
					c = prefix .. "/1 syllable"
				end
				insert(categories, c)
			end
		end
	end
	
	function export.format_rhymes(data)
		local langname = data.lang:getCanonicalName()
		local links = {}
		local categories = {}
		for _, r in ipairs(data.rhymes) do
			local rhyme = r.rhyme
			local link = make_rhyme_link(data.lang, rhyme, "-" .. rhyme)
			if r.q and r.q[1] or r.qq and r.qq[1] or r.qualifiers and r.qualifiers[1]
				or r.a and r.a[1] or r.aa and r.aa[1] then
				link = require("pron qualifier").format_qualifiers(r, link)
			end
			insert(links, link)
			add_syllable_categories(categories, langname, rhyme, r.num_syl or data.num_syl)
		end
	
		local ret = data.nocaption and "" or (data.caption or "Rhymes") .. ": "
		if data.qualifiers and data.qualifiers[1] then
			ret = require("qualifier").format_qualifier(data.qualifiers) .. " " .. ret
		end
		return ret .. concat(links, ", ") ..
			require("utilities").format_categories(categories, data.lang, data.sort, nil, force_cat or data.force_cat)
	end
end

do
	local function get_args(frame)
		local plain = {}
		local params = {
			[1] = {required = true, type = "language", default = "en"},
			[2] = {required = true, list = true, default = "aɪmz"},
			["s"] = plain,
			["srhymes"] = {list = "s", allow_holes = true, require_index = true},
			["q"] = plain,
			["qrhymes"] = {list = "q", allow_holes = true, require_index = true},
			["caption"] = plain,
			["nocaption"] = {type = "boolean"},
			["sort"] = plain,
		}
		local args = frame.getParent and frame:getParent().args or frame
		local compat = args.lang
		if compat then
			params["lang"] = params[1]
			params[1] = params[2]
			params[2] = nil
		end
		return require("parameters").process(frame:getParent().args, params), compat
	end
	
	local function parse_num_syl(val)
		val = split(val, "%s*,%s*")
		local ret = {}
		for _, v in ipairs(val) do
			local n = tonumber(v) or error("Unrecognized #syllables '" .. v .. "', should be a number")
			insert(ret, n)
		end
		return ret
	end
	
	function export.show(frame)
		local args, compat = get_args(frame)
		local lang = compat and args.lang or args[1]
		local raw_rhymes = compat and args[1] or args[2]
		
		local rhymes = {}
		for i, rhyme in ipairs(raw_rhymes) do
			local rhymeobj = {rhyme = rhyme}
			if args.srhymes[i] then
				rhymeobj.num_syl = parse_num_syl(args.srhymes[i])
			end
			if args.qrhymes[i] then
				rhymeobj.qualifiers = {args.qrhymes[i]}
			end
			insert(rhymes, rhymeobj)
		end
	
		return export.format_rhymes {
			lang = lang,
			rhymes = rhymes,
			num_syl = args.s and parse_num_syl(args.s) or nil,
			qualifiers = args.q and {args.q} or nil,
			caption = args.caption,
			nocaption = args.nocaption,
			sort = args.sort,
		}
	end
end

-- {{rhymes nav}}
function export.show_nav(frame)
	local args = require("parameters").process(
		frame:getParent().args,
		{
			[1] = {required = true, type = "language", default = "und"},
			[2] = {list = true, allow_holes = true},
		}
	)
	
	local lang = args[1]
	local parts = args[2]
	
	-- Create steps
	local steps = {"[[Wiktionary:Rhymes|Rhymes]]", make_rhyme_link(lang)}
	local categories = {}

	if #parts > 0 then
		local last = parts[#parts]
		parts[#parts] = nil
		local prefix = ""

		for i, part in ipairs(parts) do
			prefix = prefix .. part
			parts[i] = prefix
		end

		for _, part in ipairs(parts) do
			insert(steps, make_rhyme_link(lang, part .. "-", "-" .. part .. "-"))
		end

		if last == "-" then
			insert(steps, make_rhyme_link(lang, prefix, "-" .. prefix))
			insert(categories, "[[Category:" .. lang:getCanonicalName() .. " rhymes" .. (prefix == "" and "" or "/" .. prefix .. "-") .. "| ]]")
		elseif mw.title.getCurrentTitle().text == lang:getCanonicalName() .. "/" .. prefix .. last .. "-" then
			insert(steps, make_rhyme_link(lang, prefix .. last .. "-", "-" .. prefix .. last .. "-"))
			insert(categories, "[[Category:" .. lang:getCanonicalName() .. " rhymes/" .. prefix .. last .. "-|-]]")
		else
			insert(steps, make_rhyme_link(lang, prefix .. last, "-" .. prefix .. last))
			insert(categories, "[[Category:" .. lang:getCanonicalName() .. " rhymes" .. (prefix == "" and "" or "/" .. prefix .. "-") .. "|" .. last .. "]]")
		end
	elseif lang:getCode() ~= "und" then
		insert(categories, "[[Category:" .. lang:getCanonicalName() .. " rhymes| ]]")
	end

	if mw.title.getCurrentTitle().nsText == "Rhymes" then
		frame:callParserFunction("DISPLAYTITLE",
			mw.title.getCurrentTitle().fullText:gsub(
				"/(.+)$",
				function (rhyme)
					return "/" .. tag_rhyme(rhyme, lang)
				end))
	end
	
	local templateStyles = require("TemplateStyles")("Module:rhymes/styles.css")
	
	local ol = mw.html.create("ol")
	for _, step in ipairs(steps) do
		ol:node(mw.html.create("li"):wikitext(step))
	end
	local div = mw.html.create("div")
		:attr("role", "navigation")
		:attr("aria-label", "Breadcrumb")
		:addClass("ts-rhymesBreadcrumbs")
		:node(ol)
	
	return templateStyles .. tostring(div) .. concat(categories)
end

return export