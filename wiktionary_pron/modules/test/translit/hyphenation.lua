local export = {}

--[=[
Meant to be called from a module. `data` is a table containing the following fields:

{
  lang = LANGUAGE_OBJECT,
  hyphs = {
    {hyph = {"SYL", "SYL", ...},
	 q = nil or {"LEFT_QUALIFIER", "LEFT_QUALIFIER", ...},
	 qualifiers = nil or {"LEFT_QUALIFIER", "LEFT_QUALIFIER", ...},
	 qq = nil or {"RIGHT_QUALIFIER", "RIGHT_QUALIFIER", ...},
	 a = nil or {"LEFT_ACCENT_QUALIFIER", "LEFT_ACCENT_QUALIFIER", ...},
	 aa = nil or {"RIGHT_ACCENT_QUALIFIER", "RIGHT_ACCENT_QUALIFIER", ...},
	 }, ...},
  sc = nil or SCRIPT_OBJECT,
  caption = nil or "CAPTION",
  nocaption = BOOLEAN,
}

Here:

* `lang` is a language object.
* `hyphs` is the list of hyphenations to display. SYL is a syllable. LEFT_QUALIFIER is a qualifier string to display
  before the specific rhyme in question, formatted using format_qualifier() in [[Module:qualifier]]. RIGHT_QUALIFIER
  similarly displays after the rhyme. LEFT_ACCENT_QUALIFIER is an accent qualifier (as in {{a}}) to display before the
  rhyme, and RIGHT_ACCENT_QUALIFIER similarly displays after the rhyme.
* `hyphs` is the list of hyphenations to display. SYL is a syllable. QUALIFIER is a qualifier string to display before
  the specific hyphenation in question, formatted using format_qualifier() in [[Module:qualifier]].
* `sc`, if specified, is a script object.
* `caption`, if specified, overrides the default caption "Hyphenation". A colon and space is automatically added after
  the caption.
* `nocaption`, if specified, suppresses the caption entirely.
]=]
function export.format_hyphenations(data)
	local hyphtexts = {}

	for _, hyph in ipairs(data.hyphs) do
		if #hyph.hyph == 0 then
			error("Saw empty hyphenation; use || to separate hyphenations")
		end
		local text = require("links").full_link {
			lang = data.lang, sc = data.sc, alt = table.concat(hyph.hyph, "‧"), tr = "-" }
		if hyph.q and hyph.q[1] or hyph.qq and hyph.qq[1] or hyph.qualifiers and hyph.qualifiers[1]
			or hyph.a and hyph.a[1] or hyph.aa and hyph.aa[1] then
			text = require("pron qualifier").format_qualifiers(hyph, text)
		end
		table.insert(hyphtexts, text)
	end
	
	local prefix = (data.nocaption and "") or ((data.caption or "Hyphenation") .. ": ")
	local text = table.concat(hyphtexts, ", ")
	return prefix .. text
end


-- The implementation of the {{hyphenation}} template. Broken out so that it can function as an (older) entry point
-- for modules. FIXME: Convert modules that use this to use format_hyphenations() directly.
function export.hyphenate(parent_args)
	local compat = parent_args["lang"]
	local offset = compat and 0 or 1
	local params = {
		[compat and "lang" or 1] = {required = true, default = "und"},
		[1 + offset] = {list = true, required = true, allow_holes = true, default = "{{{2}}}"},
		["q"] = {list = true, allow_holes = true},
		["caption"] = {},
		["nocaption"] = {type = "boolean"},
		["sc"] = {},
	}
	local args = require("parameters").process(parent_args, params)
	
	local lang = require("languages").getByCode(args[compat and "lang" or 1], compat and "lang" or 1)
	local sc = args["sc"] and require("scripts").getByCode(args["sc"], "sc") or nil

	local data = {
		lang = lang,
		sc = sc,
		hyphs = {},
		caption = args.caption,
		nocaption = args.nocaption,
	}
	local this_hyph = {hyph = {}}
	local maxindex = args[1 + offset].maxindex
	local function insert_hyph()
		local hyphnum = #data.hyphs + 1
		if args["q"][hyphnum] then
			this_hyph.qualifiers = {args["q"][hyphnum]}
		end
		table.insert(data.hyphs, this_hyph)
	end
	for i=1, maxindex do
		local syl = args[1 + offset][i]
		if not syl then
			insert_hyph()
			this_hyph = {hyph = {}}
		else
			table.insert(this_hyph.hyph, syl)
		end
	end
	insert_hyph()

	return export.format_hyphenations(data)
end


-- Entry point for {{hyphenation}} template.
function export.hyphenation(frame)
	local parent_args = frame:getParent().args
	return export.hyphenate(parent_args)
end


return export