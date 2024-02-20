local export = {}

local m_links = require("links")

-- if not empty
local function ine(val)
	if val == "" then
		return nil
	end
	return val
end

local function parse_form(args, i, default)
	local m_form_data = mw.loadData('form of/data')

	local output = {}
	while args[i] do
		local tag = args[i]
		if m_form_data.shortcuts[tag] then
			tag = m_form_data.shortcuts[tag]
		end
		table.insert(output, tag)
		i = i + 1
	end

	return (#output > 0) and table.concat(output, " ") or default
end

function export.show_bare(frame)
	local pargs = frame:getParent().args
	
	local lang = pargs[1]
	local means = pargs["means"]
	
	if mw.title.getCurrentTitle().nsText == "Template" then
		lang = "und"
		means = means or "meaning"
	end
	
	lang = lang and require("languages").getByCode(lang) or require("languages").err(lang, 1)
	
	return "[+" .. parse_form(pargs, 2, "object") .. (means and (" = " .. means) or "") .. "]"
end

function export.show_prep(frame)
	local pargs = frame:getParent().args
	
	local lang = pargs[1]
	local means = pargs["means"]
	local term = ine(pargs[2])
	local alt = ine(pargs["alt"])
	local senseid = ine(pargs["senseid"])
	
	if mw.title.getCurrentTitle().nsText == "Template" then
		lang = "und"
		means = means or "meaning"
		term = term or "preposition"
	end
	
	lang = lang and require('languages').getByCode(lang) or require('languages').err(lang, 1)

	return "[+ <span>" ..
		require('links').full_link({lang = lang, term = term, alt = alt, id = senseid, tr = "-"}, "term") ..
		" <span>(" .. parse_form(pargs, 3, "object") .. ")</span></span>" .. (means and (" = " .. means) or "") .. "]"
end

function export.show_postp(frame)
	local pargs = frame:getParent().args
	
	local lang = pargs[1]
	local means = pargs["means"] or nil
	local term = ine(pargs[2])
	local alt = ine(pargs["alt"])
	local senseid = ine(pargs["senseid"])
	
	if mw.title.getCurrentTitle().nsText == "Template" and mw.title.getCurrentTitle().text == "+posto" then
		lang = "und"
		means = means or "meaning"
		term = term or "postposition"
	end
	
	lang = lang and require('languages').getByCode(lang) or require('languages').err(lang, 1)

	return "[+ <span><span>(" .. parse_form(pargs, 3, "object") .. ")</span> " ..
		require('links').full_link({lang = lang, term = term, alt = alt, id = senseid, tr = "-"}, "term") ..
		"</span>" .. (means and (" = " .. means) or "") .. "]"
end


function export.show_aux(frame)
	local pargs = frame:getParent().args

	local params = {
		[1] = {required = true, default = "und"},
		[2] = {list = true, allow_holes = true},
		["alt"] = {list = true, allow_holes = true},
		["q"] = {list = true, allow_holes = true},
		["id"] = {list = true, allow_holes = true},
		["senseid"] = {list = true, allow_holes = true, alias_of = "id"},
		["means"] = {list = true, allow_holes = true},
	}

	local args = require("parameters").process(frame:getParent().args, params)
	local lang = require("languages").getByCode(args[1], 1)

	-- Find the maximum index among any of the list parameters.
	local maxmaxindex = 0
	for k, v in pairs(args) do
		if type(v) == "table" and v.maxindex and v.maxindex > maxmaxindex then
			maxmaxindex = v.maxindex
		end
	end

	if mw.title.getCurrentTitle().nsText == "Template" and mw.title.getCurrentTitle().text == "+aux" then
		return "[auxiliary " .. m_links.full_link({lang = lang, term = "auxiliary"}, "term") .. " = meaning]"
	end

	local parts = {}
	for i = 1, maxmaxindex do
		local term = m_links.full_link({lang = lang, term = args[2][i], alt = args.alt[i], id = args.id[i]}, "term")
		if args.means[i] then
			term = term .. " = " .. args.means[i]
		end
		if args.q[i] then
			term = require("qualifier").format_qualifier(args.q[i]) .. " " .. term
		end
		table.insert(parts, term)
	end

	return "[auxiliary " .. require("table").serialCommaJoin(parts, {conj = "or"}) .. "]"
end


return export