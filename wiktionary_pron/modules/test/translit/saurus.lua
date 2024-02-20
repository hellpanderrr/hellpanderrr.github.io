local export = {}

local rsplit = mw.text.split
local rfind = mw.ustring.find

local function track(page)
	return require("debug/track")("saurus/" .. page)
end

local function saurus_error(text, page)
	mw.log(text)
	track(page)
	return '<span class="error";>' .. text .. '</span>'
end

function export.saurus(frame)
	local iparams = {
		["header"] = {},
		["templates"] = {default = "col[0-9]*"},
		["nolang_templates"] = {},
	}

	local iargs = require("parameters").process(frame.args, iparams, nil, "saurus", "saurus")

	local params = {
		[1] = {required = true, default = "und"},
		[2] = {},
		["header"] = {},
		["templates"] = {},
		["nolang_templates"] = {},
		["pagename"] = {},
	}

	local args = require("parameters").process(frame:getParent().args, params, nil, "saurus", "saurus")
	local lang = require("languages").getByCode(args[1], 1)
	local header = args.header or iargs.header
	if not header then
		error("header= is required unless it is passed in using the frame arguments (e.g. by using [[Template:syn-saurus]] or [[Template:ant-saurus]])")
	end
	local templates = args.templates or iargs.templates
	local template_patterns = rsplit(templates, ",")
	for i, pattern in ipairs(template_patterns) do
		template_patterns[i] = "^" .. pattern .. "$"
	end
	local nolang_templates = args.nolang_templates or iargs.nolang_templates
	local nolang_template_patterns
	if nolang_templates then
		nolang_template_patterns = rsplit(nolang_templates, ",")
		for i, pattern in ipairs(nolang_template_patterns) do
			nolang_template_patterns[i] = "^" .. pattern .. "$"
		end
	end

	local pagename = args.pagename or mw.title.getCurrentTitle().subpageText
	local source_page = args[2] or pagename
	source_page = "Thesaurus:" .. source_page
	local source_page_obj = mw.title.new(source_page)
	if not source_page_obj then
		return saurus_error(("Misformed source page '''[[%s]]'''"):format(source_page), "misformed-source-page")
	end
	
	local content = source_page_obj:getContent()
	if not content then
		return saurus_error(("Page '''[[%s]]''' not found"):format(source_page), "page-not-found")
	end

	-- Second return value is index of end of match.
	local _, secindex = string.find(content, "\n(====?=?)[ \t]*" .. header .. "[ \t]*%1")

	if not secindex then
		return saurus_error(("Header '%s' not found in '''[[%s]]'''"):format(header, source_page), "header-not-found")
	end

	-- Index of start of next subsection; may be nil.
	local next_secindex = string.find(content, "\n(=+)[^=]+%1", secindex)
	
	local sectext = string.sub(content, secindex, next_secindex)
	for name, args in require("template parser").findTemplates(sectext) do
		local matched = false
		for _, pattern in ipairs(template_patterns) do
			if rfind(name, pattern) and args[1] == lang:getCode() then
				matched = true
				break
			end
		end
		if not matched and nolang_template_patterns then
			for _, pattern in ipairs(nolang_template_patterns) do
				if rfind(name, pattern) then
					matched = true
					break
				end
			end
		end
		if matched then
			args.omit = pagename
			return frame:expandTemplate { title = name, args = args }
		end
	end

	return saurus_error(("Can't locate appropriate {{col*}} (or variant) template in '''[[%s]]'''"):format(source_page),
		"template-not-found")
end

return export