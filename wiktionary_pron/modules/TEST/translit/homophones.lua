local export = {}

local m_links = require("links")

local function track(page)
	require("debug/track")("homophones/" .. page)
	return true
end

--[=[
Meant to be called from a module. `data` is a table containing the following fields:

{
  lang = LANGUAGE_OBJECT,
  homophones = {TERM_OBJECT, ...},
     where TERM_OBJECT can contain all the fields in the object passed to full_link() in [[Module:links]] except for
	 `lang` and `sc` (which are copied from the outer level), and in addition can contain the following fields:
	    q = nil or {"LEFT_QUALIFIER", "LEFT_QUALIFIER", ...}
	    qualifiers = nil or {"QUALIFIER", "QUALIFIER", ...}
	    qq = nil or {"RIGHT_QUALIFIER", "RIGHT_QUALIFIER", ...}
		a = nil or {"LEFT_ACCENT_QUALIFIER", "LEFT_ACCENT_QUALIFIER", ...},
		aa = nil or {"RIGHT_ACCENT_QUALIFIER", "RIGHT_ACCENT_QUALIFIER", ...}
  sc = nil or SCRIPT_OBJECT,
  sort = nil or "SORTKEY",
  caption = nil or "CAPTION",
  nocaption = BOOLEAN,
}

Here:

* `lang` is a language object.
* `homophones` is the list of homophones to display. TERM_OBJECT describes the specific homophone; the homophone itself
  goes in the `term` field, while `alt`, `gloss`, `tr`, `ts`, `g`, `pos` and `lit` are as in full_link() in
  [[Module:links]]. LEFT_QUALIFIER is a qualifier string to display before the specific homophone in question, formatted
  using format_qualifier() in [[Module:qualifier]]. RIGHT_QUALIFIER similarly displays after the homophone.
  QUALIFIER for compatibility displays after the homophone, but you should not use this in new code.
  LEFT_ACCENT_QUALIFIER is an accent qualifier (as in {{a}}) to display before the homophone, and RIGHT_ACCENT_QUALIFIER
  similarly displays after the homophone.
* `sc`, if specified, is a script object.
* `sort`, if specified, is a sort key.
* `caption`, if specified, overrides the default caption "Homophone"/"Homophones". A colon and space is automatically
  added after the caption.
* `nocaption`, if specified, suppresses the caption entirely.
]=]
function export.format_homophones(data)
	local hmptexts = {}
	local hmpcats = {}

	for _, hmp in ipairs(data.homophones) do
		hmp.lang = data.lang
		hmp.sc = data.sc
		local text = m_links.full_link(hmp)
		if hmp.q and hmp.q[1] or hmp.qq and hmp.qq[1] or hmp.qualifiers and hmp.qualifiers[1]
			or hmp.a and hmp.a[1] or hmp.aa and hmp.aa[1] then
			-- FIXME, change handling of `qualifiers`
			text = require("pron qualifier").format_qualifiers(hmp, text, "qualifiers right")
		end
		table.insert(hmptexts, text)
	end

	table.insert(hmpcats, data.lang:getCanonicalName() .. " terms with homophones")
	local text = table.concat(hmptexts, ", ")
	local caption = data.nocaption and "" or (
		data.caption or "[[Appendix:Glossary#homophone|Homophone" .. (#data.homophones > 1 and "s" or "") .. "]]"
	) .. ": "
	text = "<span class=\"homophones\">" .. caption .. text .. "</span>"
	local categories = require("utilities").format_categories(hmpcats, data.lang, data.sort)
	return text .. categories
end


-- Entry point for {{homophones}} template (also written {{homophone}} and {{hmp}}).
function export.show(frame)
	local parent_args = frame:getParent().args
	local compat = parent_args["lang"]
	local offset = compat and 0 or 1

	local params = {
		[compat and "lang" or 1] = {required = true, default = "en"},
		[1 + offset] = {list = true, required = true, allow_holes = true, default = "term"},
		["alt"] = {list = true, allow_holes = true},
		["pos"] = {list = true, allow_holes = true},
		["t"] = {list = true, allow_holes = true},
		["tr"] = {list = true, allow_holes = true},
		["q"] = {list = true, allow_holes = true},
		["qq"] = {list = true, allow_holes = true},
		["caption"] = {},
		["nocaption"] = {type = "boolean"},
		["sc"] = {},
		["sort"] = {},
	}

	local args = require("parameters").process(parent_args, params)

	local lang = require("languages").getByCode(args[compat and "lang" or 1], compat and "lang" or 1)
	local sc = args["sc"] and require("scripts").getByCode(args["sc"], "sc") or nil

	local maxindex = math.max(
		args[1 + offset].maxindex,
		args["alt"].maxindex,
		args["pos"].maxindex,
		args["t"].maxindex,
		args["tr"].maxindex
	)

	local data = {
		lang = lang,
		homophones = {},
		caption = args.caption,
		nocaption = args.nocaption,
		sc = sc,
		sort = args.sort,
	}

	for i = 1, maxindex do
		table.insert(data.homophones, {
			term = args[1 + offset][i],
			alt = args["alt"][i],
			pos = args["pos"][i],
			gloss = args["t"][i],
			tr = args["tr"][i],
			qualifiers = args["q"][i] and track("q") and {args["q"][i]} or nil,
			qq = args["qq"][i] and {args["qq"][i]} or nil,
		})
	end

	return export.format_homophones(data)
end

return export