local export = {}

local m_languages = require("languages")
local table_module = "Module:table"
local usex_module = "Module:usex"

local rsplit = mw.text.split
local rfind = mw.ustring.find

local function track(page)
	require("debug/track")("usex/templates/" .. page)
	return true
end

function export.usex_t(frame)
	-- Invocation arguments (passed in the template #invoke call).
	local iparams = {
		["quote"] = {},
		["compat"] = {type = "boolean"},
		["inline"] = {type = "boolean"},
		["nocat"] = {type = "boolean"},
		["class"] = {},
	}

	local iargs = require("parameters").process(frame.args, iparams)
	local compat = iargs.compat

	-- Template (parent) arguments.
	local params = {
		-- Usex/quotation text parameters
		[1] = {required = true},
		[2] = {},
		["termlang"] = {},
		["tr"] = {},
		["transliteration"] = {alias_of = "tr"},
		["ts"] = {},
		["transcription"] = {alias_of = "ts"},
		["sc"] = {},
		["norm"] = {},
		["normalization"] = {alias_of = "norm"},
		["normsc"] = {},
		["subst"] = {},
		["q"] = {list = true},
		["qq"] = {list = true},
		["ref"] = {},

		-- Translation of usex text
		[3] = {},
		["t"] = {alias_of = 3},
		["translation"] = {alias_of = 3},
		["lit"] = {},

		-- Original text, if the usex/quotation is a translation
		["orig"] = {},
		["origlang"] = {},
		["origtr"] = {},
		["origts"] = {},
		["origsc"] = {},
		["orignorm"] = {},
		["orignormsc"] = {},
		["origsubst"] = {},
		["origq"] = {list = true},
		["origqq"] = {list = true},
		["origref"] = {},

		-- Citation-related parameters; for anything more complex, usex {{quote-*}}
		["source"] = {},
		["footer"] = {},

		-- Formatting parameters
		["inline"] = {type = "boolean"},
		["brackets"] = {type = "boolean"},

		-- Categorization parameters
		["nocat"] = {type = "boolean"},
		["sort"] = {},
	}

	if compat then
		params["lang"] = {required = true}
		params["t"].alias_of = 2
		params["translation"].alias_of = 2
		table.remove(params, 1)
	end

	local args = require("parameters").process(frame:getParent().args, params)

	local langparam = compat and "lang" or 1
	local lang = m_languages.getByCode(args[langparam] or "und", langparam, "allow etym")
	local sc = args.sc
	sc = sc and require("scripts").getByCode(sc, "sc") or nil
	local normsc = args.normsc
	normsc = normsc == "auto" and normsc or normsc and require("scripts").getByCode(normsc, "normsc") or nil
	if normsc and not args.norm then
		error("Cannot specify normsc= without norm=")
	end

	if #args.qq > 0 then
		track("qq")
	end
	if #args.q > 0 then
		track("q")
	end

	local termlang
	if args.termlang then
		termlang = m_languages.getByCode(args.termlang, "termlang", "allow etym")
		table.insert(args.qq, 1, "in " .. lang:getCanonicalName())
	end

	local origlang, origsc, orignormsc
	if args.orig then
		origlang = m_languages.getByCode(args.origlang, "origlang", "allow etym")
		table.insert(args.origqq, 1, "in " .. origlang:getCanonicalName())
		origsc = args.origsc
		origsc = origsc and require("scripts").getByCode(origsc, "origsc") or nil
		orignormsc = args.orignormsc
		orignormsc = orignormsc == "auto" and orignormsc or
			orignormsc and require("scripts").getByCode(orignormsc, "normsc") or nil
		if orignormsc and not args.orignorm then
			error("Cannot specify orignormsc= without orignorm=")
		end
	else
		for _, noparam in ipairs { "origlang", "origtr", "origts", "origsc", "orignorm", "orignormsc", "origsubst",
			"origref" } do
			if args[noparam] then
				error(("Cannot specify %s= without orig="):format(noparam))
			end
		end
		if #args.origq > 0 then
			error("Cannot specify origq= without orig=")
		end
		if #args.origqq > 0 then
			error("Cannot specify origqq= without orig=")
		end
	end

	local data = {
		lang = lang,
		sc = sc,
		normsc = normsc,
		usex = args[compat and 1 or 2],
		translation = args[compat and 2 or 3],
		transliteration = args.tr,
		transcription = args.ts,
		normalization = args.norm,
		inline = args.inline or iargs.inline,
		ref = args.ref,
		quote = iargs.quote,
		lit = args.lit,
		subst = args.subst,
		-- FIXME, change to left and right qualifiers
		qq = #args.qq > 0 and args.qq or args.q,
		source = args.source,
		footer = args.footer,
		nocat = args.nocat or iargs.nocat,
		brackets = args.brackets,
		sortkey = args.sort,
		class = iargs.class,

		-- Original text, if the usex/quotation is a translation
		orig = args.orig,
		origlang = origlang,
		origtr = args.origtr,
		origts = args.origts,
		origsc = origsc,
		orignorm = args.orignorm,
		orignormsc = orignormsc,
		origsubst = args.origsubst,
		origq = args.origq,
		origqq = args.origqq,
		origref = args.origref,
	}
	
	return require(usex_module).format_usex(data)
end

local ignore_prefixes = {"User:", "Talk:",
	"Wiktionary:Beer parlour", "Wiktionary:Translation requests",
	"Wiktionary:Grease pit", "Wiktionary:Etymology scriptorium",
	"Wiktionary:Information desk", "Wiktionary:Tea room",
	"Wiktionary:Requests for", "Wiktionary:Votes"
}

function export.page_should_be_ignored(page)
	-- Ignore user pages, talk pages and certain Wiktionary pages
	for _, ip in ipairs(ignore_prefixes) do
		if rfind(page, "^" .. ip) then
			return true
		end
	end
	if rfind(page, " talk:") then
		return true
	end
	return false
end

function export.page_should_be_ignored_t(frame)
	return export.page_should_be_ignored(frame.args[1]) and "true" or ""
end

return export