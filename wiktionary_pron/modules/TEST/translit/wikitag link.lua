local export = {}

local doc_table = {
	-- translusion tags: [[mw:Transclusion#Transclusion markup]]
	["noinclude"      ] = "mw:Transclusion#Transclusion markup";
	["includeonly"    ] = "mw:Transclusion#Transclusion markup";
	["onlyinclude"    ] = "mw:Transclusion#Transclusion markup";

	-- built-in parser extension tags
	["pre"            ] = "mw:Help:Formatting"; -- not a good target, but there is no better one
	["nowiki"         ] = "mw:Help:Formatting"; -- not a good target, but there is no better one
	["gallery"        ] = "mw:Help:Images#Rendering a gallery of images";
	
	-- tags provided by extensions
	["timeline"       ] = "mw:Extension:EasyTimeline";
	["hiero"          ] = "mw:Extension:WikiHiero";
	["charinsert"     ] = "mw:Extension:CharInsert";
	["ref"            ] = "mw:Extension:Cite#Example";
	["references"     ] = "mw:Extension:Cite#<references />";
	["inputbox"       ] = "mw:Extension:InputBox";
	["imagemap"       ] = "mw:Extension:ImageMap";
	["source"         ] = "mw:Extension:SyntaxHighlight";
	["syntaxhighlight"] = "mw:Extension:SyntaxHighlight";
	["poem"           ] = "mw:Extension:Poem";
	["section"        ] = "mw:Extension:Labeled Section Transclusion";
	["score"          ] = "mw:Extension:Score";
	["dynamicpagelist"] = "mw:Extension:DynamicPageList (Wikimedia)";
	["talkpage"       ] = "mw:Extension:LiquidThreads"; -- undocumented
	["thread"         ] = "mw:Extension:LiquidThreads"; -- undocumented
	["templatedata"   ] = "mw:Extension:TemplateData";
	["templatestyles" ] = "mw:Extension:TemplateStyles";
	["math"           ] = "mw:Extension:Math";
	["categorytree"   ] = "mw:Extension:CategoryTree";
	
	-- HTML tags are not listed.
}

export.doc_table = doc_table -- used by [[Module:template link]]

function export.show(frame)
	local output = { "<code>&lt;" }
	local args = frame:getParent().args
	
	local label = args[1]
	if not label then
		if mw.title.getCurrentTitle().fullText == frame:getParent():getTitle() then
			label = "nowiki"
		else
			error("The tag name must be given")
		end
	end
	
	local slash, tagname, after = label:match("^(/?)(%a+)(.-)$")
	local lctagname = mw.ustring.lower(tagname)
	if doc_table[lctagname] then
		table.insert(output, ("%s[[%s|%s]]%s"):format(slash, doc_table[lctagname], tagname, after))
	else
		table.insert(output, label)
	end
	
	table.insert(output, "&gt;")
	table.insert(output, "</code>")
	return table.concat(output)
end

return export