local export = {}

local variables_nullary = {}
local variables_nonnullary = {}

for _, v in ipairs{"CURRENTYEAR", "CURRENTMONTH", "CURRENTMONTH1", "CURRENTMONTH2", "CURRENTMONTHNAME", "CURRENTMONTHNAMEGEN", "CURRENTMONTHABBREV", "CURRENTDAY", "CURRENTDAY2", "CURRENTDOW", "CURRENTDAYNAME", "CURRENTTIME", "CURRENTHOUR", "CURRENTWEEK", "CURRENTTIMESTAMP", "LOCALYEAR", "LOCALMONTH", "LOCALMONTH1", "LOCALMONTH2", "LOCALMONTHNAME", "LOCALMONTHNAMEGEN", "LOCALMONTHABBREV", "LOCALDAY", "LOCALDAY2", "LOCALDOW", "LOCALDAYNAME", "LOCALTIME", "LOCALHOUR", "LOCALWEEK", "LOCALTIMESTAMP"} do
	variables_nullary[v] = "mw:Help:Magic words#Date and time"
end

local technical_metadata = "mw:Help:Magic words#Technical metadata"
for _, v in ipairs{"SITENAME", "SERVER", "SERVERNAME", "DIRMARK", "DIRECTIONMARK", "ARTICLEPATH", "SCRIPTPATH", "STYLEPATH", "CURRENTVERSION", "CONTENTLANGUAGE", "CONTENTLANG", "PAGEID", "PAGELANGUAGE", "TRANSLATIONLANGUAGE", "CASCADINGSOURCES", "REVISIONID", "REVISIONDAY", "REVISIONDAY2", "REVISIONMONTH", "REVISIONMONTH1", "REVISIONYEAR", "REVISIONTIMESTAMP", "REVISIONUSER", "REVISIONSIZE", "NUMBEROFPAGES", "NUMBEROFARTICLES", "NUMBEROFFILES", "NUMBEROFEDITS", "NUMBEROFUSERS", "NUMBEROFADMINS", "NUMBEROFACTIVEUSERS"} do
	variables_nullary[v] = technical_metadata
end
for _, v in ipairs{"PROTECTIONLEVEL", "PROTECTIONEXPIRY", "DISPLAYTITLE", "DEFAULTSORT", "DEFAULTSORTKEY", "DEFAULTCATEGORYSORT", "PAGESINCATEGORY", "PAGESINCAT", "NUMBERINGROUP", "NUMINGROUP", "PAGESINNS", "PAGESINNAMESPACE"} do
	variables_nonnullary[v] = technical_metadata
end

for _, v in ipairs{"PAGEID", "PAGESIZE", "CASCADINGSOURCES", "REVISIONID", "REVISIONDAY", "REVISIONDAY2", "REVISIONMONTH", "REVISIONMONTH1", "REVISIONYEAR", "REVISIONTIMESTAMP", "REVISIONUSER"} do
	variables_nonnullary[v] = "mw:Help:Magic words#Technical metadata of another page"
end

local page_names = "mw:Help:Magic words#Page names"
for _, v in ipairs{"FULLPAGENAME", "PAGENAME", "BASEPAGENAME", "ROOTPAGENAME", "SUBPAGENAME", "SUBJECTPAGENAME", "ARTICLEPAGENAME", "TALKPAGENAME"} do
	variables_nullary[v] = page_names
	variables_nullary[v .. "E"] = page_names
	variables_nonnullary[v] = page_names
	variables_nonnullary[v .. "E"] = page_names
end

local namespaces = "mw:Help:Magic words#Namespaces"
for _, v in ipairs{"NAMESPACE", "SUBJECTSPACE", "ARTICLESPACE", "TALKSPACE"} do
	variables_nullary[v] = namespaces
	variables_nullary[v .. "E"] = namespaces
	variables_nonnullary[v] = namespaces
	variables_nonnullary[v .. "E"] = namespaces
end
variables_nullary["NAMESPACENUMBER"] = namespaces
variables_nonnullary["NAMESPACENUMBER"] = namespaces

for _, v in ipairs{"!", "="} do
	variables_nullary[v] = "mw:Help:Magic words#Other"
end

local parser_functions = {
	["#invoke"] = "mw:Extension:Scribunto";
 	["#babel"] = "mw:Extension:Babel";
 	["#categorytree"] = "mw:Extension:CategoryTree#The {{#categorytree}} parser function";
 	["#lqtpagelimit"] = "mw:Extension:LiquidThreads";
	["#useliquidthreads"] = "mw:Extension:LiquidThreads";
	["#target"] = "mw:Extension:MassMessage"; -- not documented yet
}

for _, v in ipairs{"localurl", "localurle", "fullurl", "fullurle", "canonicalurl", "canonicalurle", "filepath", "urlencode", "anchorencode"} do
	parser_functions[v] = "mw:Help:Magic words#URL data"
end

for _, v in ipairs{"ns", "nse"} do
	parser_functions[v] = namespaces
end

for _, v in ipairs{"formatnum", "#dateformat", "#formatdate", "lc", "lcfirst", "uc", "ucfirst", "padleft", "padright", "bidi"} do
	parser_functions[v] = "mw:Help:Magic words#Formatting"
end

for _, v in ipairs{"PLURAL", "GRAMMAR", "GENDER", "int"} do
	parser_functions[v] = "mw:Help:Magic words#Localization"
end

for _, v in ipairs{"#language", "#special", "#speciale", "#tag"} do
	parser_functions[v] = "mw:Help:Magic words#Miscellaneous"
end

for _, v in ipairs{"#lst", "#lstx", "#lsth"} do
	parser_functions[v] = "mw:Extension:Labeled Section Transclusion"
end

for _, v in ipairs{"#expr", "#if", "#ifeq", "#iferror", "#ifexpr", "#ifexist", "#rel2abs", "#switch", "#time", "#timel", "#titleparts"} do
	parser_functions[v] = "mw:Help:Extension:ParserFunctions#" .. v
end

local subst = {}

for _, v in ipairs{"subst", "safesubst"} do
	subst[v] = "mw:Manual:Substitution"
end

local msg = {}

for _, v in ipairs{"msg", "msgnw"} do
	msg[v] = "mw:Help:Magic words#Transclusion modifiers"
end

local function is_valid_pagename(pagename)
	return not not mw.title.new(pagename)
end

local function hook_special(page)
	return is_valid_pagename(page) and ("[[Special:" .. page .. "|" .. page .. "]]") or page
end

local parser_function_hooks = {
	["#special"] = hook_special;
	["#speciale"] = hook_special;
	
	["int"] = function (mesg)
		if is_valid_pagename(mesg) then
			return ("[[:MediaWiki:" .. mesg .. "|" .. mesg .. "]]")
		else
			return mesg
		end
	end;
	
	["#categorytree"] = function (cat)
		if is_valid_pagename(cat) and not (mw.title.getCurrentTitle().fullText == ("Category:" .. cat)) then
			return ("[[:Category:" .. cat .. "|" .. cat .. "]]")
		else
			return cat
		end
	end;
	
	["#invoke"] = function (mod)
		if is_valid_pagename(mod) and not (mw.title.getCurrentTitle().fullText == ("Module:" .. mod)) then
			return ("[[Module:%s|%s]]"):format(mod, mod)
		else
			return mod
		end
	end;
	
	["#tag"] = function (tag)
		local doc_table = require('wikitag link').doc_table
		if doc_table[tag] then
			return ("[[%s|%s]]"):format(doc_table[tag], tag)
		else
			return tag
		end
	end;
}

function export.format_link(frame)
	if mw.isSubsting() then
		return require('unsubst').unsubst_template("format_link")
	end

	local args = (frame.getParent and frame:getParent().args) or frame -- Allows function to be called from other modules.
	local output = { (frame.args and frame.args.nested) and "&#123;&#123;" or "<code>&#123;&#123;" }
	
	local templ = (frame.args and frame.args.annotate) or args[1]
	local noargs = (frame.args and not frame.args.annotate) and next(args) == nil
	
	if not templ then
		if mw.title.getCurrentTitle().fullText == frame:getParent():getTitle() then
			-- demo mode
			return "<code>{{<var>{{{1}}}</var>|<var>{{{2}}}</var>|...}}</code>"
		else
			error("The template name must be given.")
		end
	end

	local function render_title(templ)
		local marker, rest = templ:match("^([^:]+):(.*)")
		local key = marker and marker:lower()
		if key and subst[key] then
			table.insert(output, ("[[%s|%s]]:"):format(subst[key], marker))
			templ = rest
		end
	
		if noargs and variables_nullary[templ] then
			table.insert(output, ("[[%s|%s]]"):format(variables_nullary[templ], templ))
			return
		end
		
		marker, rest = templ:match("^([^:]+):(.*)")
		key = marker and marker:lower()
		if key and msg[key] then
			table.insert(output, ("[[%s|%s]]:"):format(msg[key], marker))
			templ = rest
		end
		
		marker, rest = templ:match("^([^:]+):(.*)")
		key = marker and marker:lower()
		if key == "raw" then
			table.insert(output, ("[[%s|%s]]:"):format("mw:Help:Magic words#Transclusion modifiers", marker))
			templ = rest
		end
		
		if templ:match("^%s*/") then
			table.insert(output, ("[[%s]]"):format(templ))
			return	
		end
		
		marker, rest = templ:match("^([^:]+):(.*)")
		key = marker and marker:lower()
		if key and parser_functions[key] then
			if parser_function_hooks[key] then
				rest = parser_function_hooks[key](rest)
			end
			table.insert(output, ("[[%s|%s]]:%s"):format(mw.uri.encode(parser_functions[key], "WIKI"), marker, rest))
			return
		elseif marker and variables_nonnullary[marker] then
			table.insert(output, ("[[%s|%s]]:%s"):format(variables_nonnullary[marker], marker, rest))
			return
		end
	
		if not is_valid_pagename(templ) then
			table.insert(output, templ)
			return
		end

		if marker then
			if mw.site.namespaces[marker] then
				if (title == "") or (mw.title.getCurrentTitle().fullText == templ) then -- ?? no such variable "title"
					table.insert(output, templ)
				elseif marker == "" and templ:find("^:") then
					-- for cases such as {{temp|:entry}}; MediaWiki displays [[:entry]] without a colon, like [[entry]], but colon should be shown
					table.insert(output, ("[[%s|%s]]"):format(templ, templ))
				else
					table.insert(output, ("[[:%s|%s]]"):format(templ, templ))
				end
				return
			elseif mw.site.interwikiMap()[marker:lower()] then
				-- XXX: not sure what to do now…
				table.insert(output, ("[[:%s:|%s]]:%s"):format(marker, marker, rest))
				return
			end
		end

		if (templ == "") or (mw.title.getCurrentTitle().fullText == ("Template:" .. templ)) then
			table.insert(output, templ)
		else
			table.insert(output, ("[[Template:%s|%s]]"):format(templ, templ))
		end
	end

	render_title(templ)

	local i = (frame.args and frame.args.annotate) and 1 or 2
	while args[i] do
		table.insert(output, "&#124;" .. args[i])
		i = i + 1
	end
	
	for key, value in require("table").sortedPairs(args) do
		if type(key) == "string" then
			table.insert(output, "&#124;" .. key .. "=" .. value)
		end
	end
	
	table.insert(output, (frame.args and frame.args.nested) and "&#125;&#125;" or "&#125;&#125;</code>")
	return table.concat(output)
end

return export