local export = {}

local m_utilities = require("utilities")
local inFundamental = mw.loadData("category tree/data")

local show_error, link_box, show_catfix, show_categories, show_topright, show_editlink, show_pagelist,
	show_breadcrumbs, show_description, show_appendix, show_children, show_TOC


-- The main entry point.
-- This is the only function that can be invoked from a template.
function export.show(frame)
	local template = frame.args["template"]
	
	if not template or template == "" then
		error("The \"template\" parameter was not specified.")
	end
	
	if mw.title.getCurrentTitle().nsText == "Template" then
		local text = {}
		table.insert(text, "This template should be used on pages in the Category: namespace, ")
		table.insert(text, "and automatically generates descriptions and categorization for categories of a recognized type (see below).")
		table.insert(text, " It is implemented by [[Module:category tree]] and its submodule [[Module:category tree/")
		table.insert(text, template .. "]].")
		if frame.args["useautocat"] then
			table.insert(text, " It is preferable not to invoke this template directly, but to simply use ")
			table.insert(text, require("template link").format_link({"auto cat"}))
			table.insert(text, " (with no parameters), which will automatically invoke this template on appropriately-named category pages.")
		end
		return table.concat(text)
	elseif mw.title.getCurrentTitle().nsText ~= "Category" then
		error("This template/module can only be used on pages in the Category: namespace.")
	end
	
	local submodule = require("category tree/" .. template)
	
	-- Get all the parameters and the label data
	local current
	
	if submodule.new_main then
		current = submodule.new_main(frame)
	else
		local info = {}
		
		for key, val in pairs(frame.args) do
			if val ~= "" and key ~= "useautocat" then
				info[key] = val
			end
		end
	
		info.template = nil
		current = submodule.new(info, true)
	end
	
	local functions = {
		"getBreadcrumbName",
		"getDataModule",
		"canBeEmpty",
		"getDescription",
		"getParents",
		"getChildren",
		"getUmbrella",
		"getAppendix",
		"getTOCTemplateName",
	}
	
	if current then
		for i, functionName in pairs(functions) do
			if type(current[functionName]) ~= "function" then
				require("debug").track{ "category tree/missing function", "category tree/missing function/" .. functionName }
			end
		end
	end

	local boxes = {}
	local display = {}
	local categories = {}

	if template == "topic cat" then
		table.insert(categories, "[[Category:topic cat]]")
	end
	
	-- Check if the category is empty
	local isEmpty = mw.site.stats.pagesInCategory(mw.title.getCurrentTitle().text, "all") == 0
	
	-- Are the parameters valid?
	if not current then
		-- WARNING: The following name is hardcoded and checked for in [[Module:auto cat]]. If you change it, you
		-- also need to change that module.
		table.insert(categories, "[[Category:Categories that are not defined in the category tree]]")
		table.insert(categories, isEmpty and "[[Category:Empty categories]]" or nil)
		table.insert(display, show_error(
			"Double-check the category name for typos. <br>" ..
			"[[Special:Search/Category: " .. mw.title.getCurrentTitle().text:gsub("^.+:", ""):gsub(" ", "~2 ") .. '~2|Search existing categories]] to check if this category should be created under a different name (for example, "Fruits" instead of "Fruit"). <br>' ..
			"To add a new category to Wiktionary's category tree, please consult " .. mw.getCurrentFrame():expandTemplate{title = "section link", args = {
				"Help:Category#How_to_create_a_category",
			}} .. "."))
		
		-- Exit here, as all code beyond here relies on current not being nil
		return table.concat(categories, "") .. table.concat(display, "\n\n")
	end
	
	-- Does the category have the correct name?
	if mw.title.getCurrentTitle().text ~= current:getCategoryName() then
		table.insert(categories, "[[Category:Categories with incorrect name]]")
		table.insert(display, show_error(
			"Based on the parameters given to the " ..
			require("template link").format_link{template} ..
			" template, this category should be called '''[[:Category:" .. current:getCategoryName() .. "]]'''."))
	end
	
	-- Add cleanup category for empty categories
	local canBeEmpty = current:canBeEmpty()
	if isEmpty and not canBeEmpty then
		table.insert(categories, "[[Category:Empty categories]]")
	end
	
	if current:isHidden() then
		table.insert(categories, "__HIDDENCAT__")
	end

	if canBeEmpty then
		table.insert(categories, " __EXPECTUNUSEDCATEGORY__")
	end

	-- Put all the float-right stuff into a <div> that does not clear, so that float-left stuff like the breadcrumbs and
	-- description can go opposite the float-right stuff without vertical space.
	table.insert(boxes, "<div style=\"float: right;\">")
	table.insert(boxes, show_topright(current))
	table.insert(boxes, show_editlink(current))
	table.insert(boxes, show_related_changes())
	table.insert(boxes, show_pagelist(current))
	table.insert(boxes, "</div>")
	
	-- Generate the displayed information
	table.insert(display, show_breadcrumbs(current))
	table.insert(display, show_description(current))
	table.insert(display, show_appendix(current))
	table.insert(display, show_children(current))
	table.insert(display, show_TOC(current))
	table.insert(display, show_catfix(current))
	table.insert(display, '<br class="clear-both-in-vector-2022-only">')
	
	show_categories(current, categories)
	
	return table.concat(boxes, "\n") .. "\n" .. table.concat(display, "\n\n") .. table.concat(categories, "")
end

function show_error(text)
	return  mw.getCurrentFrame():expandTemplate{title = "maintenance box", args = {
		"red",
		image = "[[File:Ambox warning pn.svg|50px]]",
		title = "This category is not defined in Wiktionary's category tree.",
		text = text,
		}}
end

local function get_catfix_info(current)
	local lang, sc
	if current.getCatfixInfo then
		lang, sc = current:getCatfixInfo()
	elseif not (current._info and current._info.no_catfix) then
		-- FIXME: This is hacky and should be removed.
		lang = current._lang
		sc = current._info and current._info.sc and require("scripts").getByCode(current._info.sc) or nil
	end
	return lang, sc
end

-- Show the "catfix" that adds language attributes and script classes to the page.
function show_catfix(current)
	local lang, sc = get_catfix_info(current)
	if lang then
		return m_utilities.catfix(lang, sc)
	else
		return nil
	end
end

-- Show the parent categories that the current category should be placed in.
function show_categories(current, categories)
	local parents = current:getParents()
	
	if not parents then
		return
	end
	
	for _, parent in ipairs(parents) do
		if type(parent.name) == "string" then
			table.insert(categories, "[[" .. parent.name .. "|" .. parent.sort .. "]]")
		else
			table.insert(categories, "[[Category:" .. parent.name:getCategoryName() .. "|" .. parent.sort .. "]]")
		end
	end
	
	-- Also put the category in its corresponding "umbrella" or "by language" category.
	local umbrella = current:getUmbrella()
	
	if umbrella then
		local sort
		if current._lang then
			sort = current._lang:getCanonicalName()
		else
			sort = current:getCategoryName()
		end
		
		if type(umbrella) == "string" then
			table.insert(categories, "[[" .. umbrella .. "|" .. sort .. "]]")
		else
			table.insert(categories, "[[Category:" .. umbrella:getCategoryName() .. "|" .. sort .. "]]")
		end
	end
end

function link_box(content)
	return "<div class=\"noprint plainlinks\" style=\"float: right; clear: both; margin: 0 0 .5em 1em; background: #f9f9f9; border: 1px #aaaaaa solid; margin-top: -1px; padding: 5px; font-weight: bold;\">"
		.. content .. "</div>"
end

function show_related_changes()
	local title = mw.title.getCurrentTitle().fullText
	return link_box(
		"["
		.. tostring(mw.uri.fullUrl("Special:RecentChangesLinked", {
			target = title,
			showlinkedto = 0,
		}))
		.. ' <span title="Recent edits and other changes to pages in ' .. title .. '">Recent changes</span>]')
end

function show_editlink(current)
	return link_box(
		"[" .. tostring(mw.uri.fullUrl(current:getDataModule(), "action=edit"))
		.. " Edit category data]")
end

function show_pagelist(current)
	local namespace = "namespace="
	local info = current:getInfo()
	
	local lang_code = info.code
	if info.label == "citations" or info.label == "citations of undefined terms" then
		namespace = namespace .. "Citations"
	elseif lang_code then
		local lang = require("languages").getByCode(lang_code)
		if lang then
			-- Proto-Norse (gmq-pro) is the probably language with a code ending in -pro
			-- that's intended to have mostly non-reconstructed entries.
			if (lang_code:find("%-pro$") and lang_code ~= "gmq-pro") or lang:hasType("reconstructed") then
				namespace = namespace .. "Reconstruction"
			elseif lang:hasType("appendix-constructed") then
				namespace = namespace .. "Appendix"
			end
		end
	elseif info.label:match("templates") then
		namespace = namespace .. "Template"
	elseif info.label:match("modules") then
		namespace = namespace .. "Module"
	elseif info.label:match("^Wiktionary") or info.label:match("^Pages") then
		namespace = ""
	end
	
	local recent = mw.getCurrentFrame():callParserFunction{
		name = "#tag",
		args = {
			"DynamicPageList",
			"category=" .. mw.title.getCurrentTitle().text .. "\n" ..
			namespace .. "\n" ..
			"count=10\n" ..
			"mode=ordered\n" ..
			"ordermethod=categoryadd\n" ..
			"order=descending"
		}
	}
	
	local oldest = mw.getCurrentFrame():callParserFunction{
		name = "#tag",
		args = {
			"DynamicPageList",
			"category=" .. mw.title.getCurrentTitle().text .. "\n" ..
			namespace .. "\n" ..
			"count=10\n" ..
			"mode=ordered\n" ..
			"ordermethod=lastedit\n" ..
			"order=ascending"
		}
	}
	
	return [=[
{| id="newest-and-oldest-pages" class="wikitable mw-collapsible" style="float: right; clear: both; margin: 0 0 .5em 1em;"
! Newest and oldest pages&nbsp;
|-
| id="recent-additions" style="font-size:0.9em;" | '''Newest pages ordered by last [[mw:Manual:Categorylinks table#cl_timestamp|category link update]]:'''
]=] .. recent .. [=[

|-
| id="oldest-pages" style="font-size:0.9em;" | '''Oldest pages ordered by last edit:'''
]=] .. oldest .. [=[

|}]=]
end

-- Show navigational "breadcrumbs" at the top of the page.
function show_breadcrumbs(current)
	local steps = {}
	
	-- Start at the current label and move our way up the "chain" from child to parent, until we can't go further.
	while current do
		local category = nil
		local display_name = nil
		local nocap = nil
		
		if type(current) == "string" then
			category = current
			display_name = current:gsub("^Category:", "")
		else
			category = "Category:" .. current:getCategoryName()
			display_name, nocap = current:getBreadcrumbName()
		end

		if not nocap then
			display_name = mw.getContentLanguage():ucfirst(display_name)
		end
		table.insert(steps, 1, "[[:" .. category .. "|" .. display_name .. "]]")
		
		-- Move up the "chain" by one level.
		if type(current) == "string" then
			current = nil
		else
			current = current:getParents()
		end
		
		if current then
			current = current[1].name
		elseif inFundamental[category] then
			current = "Category:Fundamental"
		end	
	end
	
	local templateStyles = require("TemplateStyles")("Module:category tree/styles.css")
	
	local ol = mw.html.create("ol")
	for i, step in ipairs(steps) do
		local li = mw.html.create("li")
		if i ~= 1 then
			local span = mw.html.create("span")
				:attr("aria-hidden", "true")
				:addClass("ts-categoryBreadcrumbs-separator")
				:wikitext(" » ")
			li:node(span)
		end
		li:wikitext(step)
		ol:node(li)
	end
	local div = mw.html.create("div")
		:attr("role", "navigation")
		:attr("aria-label", "Breadcrumb")
		:addClass("ts-categoryBreadcrumbs")
		:node(ol)
	
	return templateStyles .. tostring(div)
end

-- Show the text that goes at the very top right of the page.
function show_topright(current)
	return (current.getTopright and current:getTopright() or "")
end

-- Show a short description text for the category.
function show_description(current)
	return (current:getDescription() or "")
end

function show_appendix(current)
	local appendix
	
	if current.getAppendix then
		appendix = current:getAppendix()
	end
	
	if appendix then
		return "For more information, see [[" .. appendix .. "]]."
	else
		return nil
	end
end

-- Show a list of child categories.
function show_children(current)
	local children = current:getChildren()
	
	if not children then
		return nil
	end
	
	table.sort(children, function(first, second) return mw.ustring.upper(first.sort) < mw.ustring.upper(second.sort) end)
	
	local children_list = {}
	
	for _, child in ipairs(children) do
		local child_pagetitle
		if type(child.name) == "string" then
			child_pagetitle = child.name
		else
			child_pagetitle = "Category:" .. child.name:getCategoryName()
		end
		local child_page = mw.title.new(child_pagetitle)
		
		if child_page.exists then
			local child_description =
				child.description or
				type(child.name) == "string" and child.name:gsub("^Category:", "") .. "." or
				child.name:getDescription("child")
			table.insert(children_list, "* [[:" .. child_pagetitle .. "]]: " .. child_description)
		end
	end
	
	return table.concat(children_list, "\n")
end

-- Show a table of contents with links to each letter in the language's script.
function show_TOC(current)
	local titleText = mw.title.getCurrentTitle().text
	
	local inCategoryPages = mw.site.stats.pagesInCategory(titleText, "pages")
	local inCategorySubcats = mw.site.stats.pagesInCategory(titleText, "subcats")

	local TOC_type

	-- Compute type of table of contents required.
	if inCategoryPages > 2500 or inCategorySubcats > 2500 then
		TOC_type = "full"
	elseif inCategoryPages > 200 or inCategorySubcats > 200 then
		TOC_type = "normal"
	else
		-- No (usual) need for a TOC if all pages or subcategories can fit on one page;
		-- but allow this to be overridden by a custom TOC handler.
		TOC_type = "none"
	end

	if current.getTOC then
		local TOC_text = current:getTOC(TOC_type)
		if TOC_text ~= true then
			return TOC_text
		end
	end

	if TOC_type ~= "none" then
		local templatename = current:getTOCTemplateName()

		local TOC_template
		if TOC_type == "full" then
			-- This category is very large, see if there is a "full" version of the TOC.
			local TOC_template_full = mw.title.new(templatename .. "/full")
			
			if TOC_template_full.exists then
				TOC_template = TOC_template_full
			end
		end

		if not TOC_template then
			local TOC_template_normal = mw.title.new(templatename)
			if TOC_template_normal.exists then
				TOC_template = TOC_template_normal
			end
		end

		if TOC_template then
			return mw.getCurrentFrame():expandTemplate{title = TOC_template.text, args = {}}
		end
	end

	return nil
end

function export.test(frame)
	local template = frame.args[1]
	local submodule = require("category tree/" .. template)
	
	if submodule.new_main then
		current = submodule.new_main(frame)
	else
		local info = {}
		
		for key, val in pairs(frame.args) do
			info[key] = val; if info[key] == "" then info[key] = nil end
		end
	
		info.template = nil
		current = submodule.new(info, true)
	end
end

return export