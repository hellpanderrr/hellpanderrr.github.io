local export = {}

local label_data = require("category tree/topic cat/data")
local topic_cat_utilities_module = "Module:category tree/topic cat/utilities"
local labels_ancillary_module = "Module:labels/ancillary"
local pattern_utilities_module = "Module:pattern utilities"

local rsplit = mw.text.split

-- Category object

local Category = {}
Category.__index = Category


local type_data = {
	["related-to"] = {
		desc = "terms related to",
		additional = "'''NOTE''': This is a \"related-to\" category. It should contain terms directly related to " ..
		"{{{topic}}}. Please do not include terms that merely have a tangential connection to {{{topic}}}. " ..
		"Be aware that terms for types or instances of this topic often go in a separate category.",
	},
	set = {
		desc = "terms for types or instances of",
		additional = "'''NOTE''': This is a set category. It should contain terms for {{{topic}}}, not merely " ..
		"terms related to {{{topic}}}. It may contain more general terms (e.g. types of {{{topic}}}) or more " ..
		"specific terms (e.g. names of specific {{{topic}}}), although there may be related categories "..
		"specifically for these types of terms.",
	},
	name = {
		desc = "names of specific",
		additional = "'''NOTE''': This is a name category. It should contain names of specific {{{topic}}}, not " ..
		"merely terms related to {{{topic}}}, and should also not contain general terms for types of {{{topic}}}.",
	},
	type = {
		desc = "terms for types of",
		additional = "'''NOTE''': This is a type category. It should contain terms for types of {{{topic}}}, not " ..
		"merely terms related to {{{topic}}}, and should also not contain names of specific {{{topic}}}.",
	},
	grouping = {
		desc = "categories concerning more specific variants of",
		additional = "'''NOTE''': This is a grouping category. It should not directly contain any terms, but " ..
		"only subcategories. If there are any terms directly in this category, please move them to a subcategory.",
	},
	toplevel = {
		desc = "UNUSED", -- all categories of this type hardcode their description
		additional = "'''NOTE''': This is a top-level list category. It should not directly contain any terms, but " ..
		"only a {{{topic}}}.",
	},
}

local function invalid_type(types)
	local valid_types = {}
	for typ, _ in pairs(type_data) do
		table.insert(valid_types, ("'%s'"):format(typ))
	end
	error(("Invalid type '%s', should be one or more of %s, comma-separated")
		:format(types, require("table").serialCommaJoin(valid_types, {dontTag = true})))
end

local function split_types(types)
	types = types or "related-to"
	local splitvals = rsplit(types, "%s*,%s*")
	for i, typ in ipairs(splitvals) do
		-- FIXME: Temporary
		if typ == "topic" then
			typ = "related-to"
		end
		if not type_data[typ] then
			invalid_type(types)
		end
		splitvals[i] = typ
	end
	return splitvals
end

local function gsub_escaping_replacement(str, from, to)
	return (str:gsub(from, require(pattern_utilities_module).replacement_escape(to)))
end

function Category.new_main(frame)
	local self = setmetatable({}, Category)

	local params = {
		[1] = {},
		[2] = {required = true},
		["sc"] = {},
	}

	args = require("parameters").process(frame:getParent().args, params, nil, "category tree/topic cat", "new_main")
	self._info = {code = args[1], label = args[2]}

	self:initCommon()

	if not self._data then
		return nil
	end

	return self
end

function Category.new(info)
	for key, val in pairs(info) do
		if not (key == "code" or key == "label") then
			error("The parameter “" .. key .. "” was not recognized.")
		end
	end

	local self = setmetatable({}, Category)
	self._info = info

	if not self._info.label then
		error("No label was specified.")
	end

	self:initCommon()

	if not self._data then
		error("The label “" .. self._info.label .. "” does not exist.")
	end

	return self
end

export.new = Category.new
export.new_main = Category.new_main


function Category:initCommon()
	if self._info.code then
		self._lang = require("languages").getByCode(self._info.code, true)
	end

	-- Convert label to lowercase if possible
	local lowercase_label = mw.getContentLanguage():lcfirst(self._info.label)

	-- Check if the label exists
	local labels = label_data["LABELS"]

	if labels[lowercase_label] then
		self._info.label = lowercase_label
	end

	self._data = labels[self._info.label]

	-- Go through handlers
	if not self._data then
		for _, handler in ipairs(label_data["HANDLERS"]) do
			self._data = handler.handler(self._info.label)
			if self._data then
				self._data.module = handler.module
				break
			end
		end
	end
end


function Category:getInfo()
	return self._info
end


function ucfirst(txt)
	local italics, raw_txt = txt:match("^('*)(.-)$")
	return italics .. mw.getContentLanguage():ucfirst(raw_txt)
end


function Category:uclabel()
	return ucfirst(self._info.label)
end


function Category:format_displaytitle(include_lang_prefix, upcase)
	local displaytitle = self._data.displaytitle
	if not displaytitle then
		return nil
	end
	if type(displaytitle) == "function" then
		displaytitle = displaytitle(self._info.label, lang)
	end
	if upcase then
		displaytitle = ucfirst(displaytitle)
	end
	if include_lang_prefix and self._lang then
		displaytitle = ("%s:%s"):format(self._lang:getCode(), displaytitle)
	end

	return displaytitle
end


function Category:getBreadcrumbName()
	local ret

	if self._lang then
		ret = self._data.breadcrumb or self:format_displaytitle(false, "upcase")
	else
		ret = self._data.umbrella and self._data.umbrella.breadcrumb or
			self._data.breadcrumb or self:format_displaytitle(false, "upcase")
	end
	if not ret then
		ret = self._info.label
	end

	if type(ret) == "string" or type(ret) == "number" then
		ret = {name = ret}
	end

	local name = self:substitute_template_specs(ret.name)
	local nocap = ret.nocap

	return name, nocap
end


function Category:getDataModule()
	return self._data.module
end


function Category:canBeEmpty()
	if self._lang then
		return false
	else
		return true
	end
end


function Category:isHidden()
	return false
end




function Category:getCategoryName()
	if self._lang then
		return self._lang:getCode() .. ":" .. self:uclabel()
	else
		return self:uclabel()
	end
end


function Category:process_default(desc)
	local stripped_desc = desc
	local no_singularize, wikify, add_the
	while true do
		local new_stripped_desc = stripped_desc:match("^(.+) no singularize$")
		if new_stripped_desc then
			no_singularize = true
		end
		if not new_stripped_desc then
			new_stripped_desc = stripped_desc:match("^(.+) wikify$")
			if new_stripped_desc then
				wikify = true
			end
		end
		if not new_stripped_desc then
			new_stripped_desc = stripped_desc:match("^(.+) with the$")
			if new_stripped_desc then
				add_the = true
			end
		end
		if new_stripped_desc then
			stripped_desc = new_stripped_desc
		else
			break
		end
	end
	if stripped_desc == "default" then
		return true, no_singularize, wikify, add_the
	else
		return false
	end
end


function Category:replace_special_descriptions(desc)
	if not desc then
		return desc
	end

	local function format_desc(desc)
		local desc_parts = {}
		local types = split_types(self._data.type)
		for _, typ in ipairs(types) do
			table.insert(desc_parts, type_data[typ].desc .. " " .. desc)
		end
		return "{{{langname}}} " .. require("table").serialCommaJoin(desc_parts) .. "."
	end

	if desc:find("^=") then
		desc = desc:gsub("^=", "")
		return format_desc(desc)
	end

	local is_default, no_singularize, wikify, add_the = self:process_default(desc)
	if is_default then
		local linked_label = require(topic_cat_utilities_module).link_label(self._info.label, no_singularize, wikify)
		if add_the then
			linked_label = "the " .. linked_label
		end
		return format_desc(linked_label)
	else
		return desc
	end
end


function Category:substitute_template_specs(desc)
	if not desc then
		return desc
	end
	if type(desc) == "number" then
		desc = tostring(desc)
	end
	-- FIXME, when does this occur? It doesn't occur in the corresponding place in [[Module:category tree/poscatboiler]].
	if type(desc) ~= "string" then
		return desc
	end
	desc = gsub_escaping_replacement(desc, "{{PAGENAME}}", mw.title.getCurrentTitle().text)

	if desc:find("{{{umbrella_msg}}}") then
		local eninfo = mw.clone(self._info)
		eninfo.code = "en"
		local en = Category.new(eninfo)
		desc = desc:gsub("{{{umbrella_msg}}}", "This category contains no dictionary entries, only other categories. The subcategories are of two sorts:\n\n" ..
			"* Subcategories named like \"aa:" .. self:uclabel() ..
			"\" (with a prefixed language code) are categories of terms in specific languages. " ..
			"You may be interested especially in [[:Category:" .. en:getCategoryName() .. "]], for English terms.\n" ..
			"* Subcategories of this one named without the prefixed language code are further categories just like this one, but devoted to finer topics."
		)
	end
	if self._lang then
		desc = gsub_escaping_replacement(desc, "{{{langname}}}", self._lang:getCanonicalName())
		desc = gsub_escaping_replacement(desc, "{{{langcode}}}", self._lang:getCode())
		desc = gsub_escaping_replacement(desc, "{{{langcat}}}", self._lang:getCategoryName())
		desc = gsub_escaping_replacement(desc, "{{{langlink}}}", self._lang:makeCategoryLink())
	end

	if desc:find("{{{topic}}}") then
		local function get_displaytitle_or_label()
			return self:format_displaytitle(false) or self._info.label
		end

		local function process_default_add_the(topic)
			local is_default, no_singularize, wikify, add_the = self:process_default(topic)
			if is_default then
				topic = get_displaytitle_or_label()
				if add_the then
					topic = "the " .. topic
				end
			end
			return topic, is_default
		end

		-- Compute the value for {{{topic}}}. If the user specified `topic`, use it. (If we're an umbrella category,
		-- allow a separate value for `umbrella.topic`, falling back to `topic`.) Otherwise, see if the description
		-- was specified as 'default' or a variant; if so, parse it to determine whether to add "the" to the label.
		-- Otherwise, just use the label directly.
		local topic = not self._lang and self._data.umbrella and self._data.umbrella.topic or self._data.topic
		if topic then
			topic, _ = process_default_add_the(topic)
		else
			local desc
			if not self._lang then
				desc = self._data.umbrella and self._data.umbrella.description or self._data.umbrella_description
			end
			desc = desc or self._data.description
			local defaulted_desc, is_default = process_default_add_the(desc)
			if is_default then
				topic = defaulted_desc
			else
				topic = get_displaytitle_or_label()
			end
		end

		desc = gsub_escaping_replacement(desc, "{{{topic}}}", topic)
	end

	if desc:find("{") then
		desc = mw.getCurrentFrame():preprocess(desc)
	end

	return desc
end


function Category:substitute_template_specs_in_args(args)
	if not args then
		return args
	end
	local pinfo = {}
	for k, v in pairs(args) do
		k = self:substitute_template_specs(k)
		v = self:substitute_template_specs(v)
		pinfo[k] = v
	end
	return pinfo
end


function Category:getTopright()
	local def_topright_parts = {}
	local function process_box(val, pattern)
		if not val then
			return
		end
		local defval = self:uclabel()
		if type(val) ~= "table" then
			val = {val}
		end
		for _, v in ipairs(val) do
			if v == true then
				table.insert(def_topright_parts, pattern:format(defval))
			else
				table.insert(def_topright_parts, pattern:format(v))
			end
		end
	end

	process_box(self._data.wp, "{{wikipedia|%s}}")
	process_box(self._data.wpcat, "{{wikipedia|category=%s}}")
	process_box(self._data.commonscat, "{{commonscat|%s}}")

	local def_topright
	if #def_topright_parts > 0 then
		def_topright = table.concat(def_topright_parts, "\n")
	end

	if self._lang then
		return self:substitute_template_specs(self._data.topright or def_topright)
	else
		return self._data.umbrella and self:substitute_template_specs(self._data.umbrella.topright) or
			self:substitute_template_specs(def_topright)
	end
end


local function remove_lang_params(desc)
	desc = desc:gsub("^{{{langname}}} ", "")
	desc = desc:gsub("{{{langcode}}}:", "")
	desc = desc:gsub("^{{{langcode}}} ", "")
	desc = desc:gsub("^{{{langcat}}} ", "")
	return desc
end


function Category:getDescription(isChild)
	-- Allows different text in the list of a category's children
	local isChild = isChild == "child"

	local function display_title()
		local displaytitle = self:format_displaytitle("include lang prefix", "upcase")
		if displaytitle then
			displaytitle = self:substitute_template_specs(displaytitle)
			mw.getCurrentFrame():callParserFunction("DISPLAYTITLE", "Category:" .. displaytitle)
		end
	end

	if not isChild and self._data.displaytitle then
		display_title()
	end

	local function get_labels_categorizing()
		local m_labels_ancillary = require(labels_ancillary_module)
		return m_labels_ancillary.format_labels_categorizing(
			m_labels_ancillary.find_labels_for_category(self._info.label, "topic", self._lang), nil, self._lang)
	end

	local function get_additional_msg()
		local types = split_types(self._data.type)
		if #types > 1 then
			local parts = {}
			local function ins(txt)
				table.insert(parts, txt)
			end
			ins("'''NOTE''': This is a mixed category. It may contain terms of any of the following category types:")
			for i, typ in ipairs(types) do
				ins(("* %s {{{topic}}}%s"):format(type_data[typ].desc, i == #types and "." or ";"))
			end
			ins("'''WARNING''': Such categories are strongly dispreferred and should be split into separate per-type categories.")
			return table.concat(parts, "\n")
		else
			return type_data[types[1]].additional
		end
	end

	if self._lang then
		local desc = self._data.description

		desc = self:replace_special_descriptions(desc)
		if not isChild and desc then
			if self._data.preceding then
				desc = self._data.preceding .. "\n\n" .. desc
			end
			if self._data.additional then
				desc = desc .. "\n\n" .. self._data.additional
			end
			desc = desc .. "\n\n" .. get_additional_msg()
			local labels_msg = get_labels_categorizing()
			if labels_msg then
				desc = desc .. "\n\n" .. labels_msg
			end
		end

		return self:substitute_template_specs(desc)
	else
		if self._info.label == "all topics" then
			return "This category applies to content and not to meta material about the Wiki."
		end

		local desc = self._data.umbrella and self._data.umbrella.description or self._data.umbrella_description
		local has_umbrella_desc = not not desc
		if not desc then
			 desc = self._data.description
			 if desc then
		 		desc = self:replace_special_descriptions(desc)
				desc = remove_lang_params(desc)
				desc = desc:gsub("%.$", "")
				desc = "This category concerns the topic: " .. desc .. "."
			 end
		end
		if not desc then
			desc = "Categories concerning " .. self._info.label .. " in various specific languages."
		end

		if not isChild then
			local preceding = self._data.umbrella and self._data.umbrella.preceding or
				not has_umbrella_desc and self._data.preceding
			local additional = self._data.umbrella and self._data.umbrella.additional or
				not has_umbrella_desc and self._data.additional
			if preceding then
				desc = remove_lang_params(preceding) .. "\n\n" .. desc
			end
			if additional then
				desc = desc .. "\n\n" .. remove_lang_params(additional)
			end
			desc = desc .. "\n\n{{{umbrella_msg}}}"
			desc = desc .. "\n\n" .. get_additional_msg()
			local labels_msg = get_labels_categorizing()
			if labels_msg then
				desc = desc .. "\n\n" .. labels_msg
			end
		end
		desc = self:substitute_template_specs(desc)
		return desc
	end
end


function Category:getParents()
	local parents = self._data["parents"]
	local label = self._info.label

	if not self._lang and label == "all topics" then
		return {{ name = "Category:Fundamental", sort = "topics" }}
	end

	if not parents or #parents == 0 then
		return nil
	end

	local ret = {}

	for key, parent in ipairs(parents) do
		parent = mw.clone(parent)

		if type(parent) ~= "table" then
			parent = {name = parent}
		end

		if not parent.sort then
			-- When defaulting sort key to label, strip 'The ' (e.g. in 'The Matrix', 'The Hunger Games')
			-- and 'A ' (e.g. in 'A Song of Ice and Fire', 'A Christmas Carol') from label.
			local stripped_sort = label:match("^[Tt]he (.*)$")
			if stripped_sort then
				parent.sort = stripped_sort
			end
			if not stripped_sort then
				stripped_sort = label:match("^[Aa] (.*)$")
				if stripped_sort then
					parent.sort = stripped_sort
				end
			end
			if not stripped_sort then
				parent.sort = label
			end
		end

		if self._lang then
			parent.sort = self:substitute_template_specs(parent.sort)
		elseif parent.sort:find("{{{langname}}}") or parent.sort:find("{{{langcat}}}") or parent.module then
			return nil
		end

		if not self._lang then
			parent.sort = " " .. parent.sort
		end

		if parent.name and parent.name:find("^Category:") then
			if self._lang then
				parent.name = self:substitute_template_specs(parent.name)
			elseif parent.name:find("{{{langname}}}") or parent.name:find("{{{langcat}}}") or parent.module then
				return nil
			end
		else
			local pinfo = mw.clone(self._info)
			pinfo.label = parent.name

			if parent.module then
				-- A reference to a category using another category tree module.
				if not parent.args then
					error("Missing .args in parent table with module=\"" .. parent.module .. "\" for '" ..
						label .. "' topic entry in module '" .. (self._data.module or "unknown") .. "'")
				end
				parent.name = require("category tree/" .. parent.module).new(self:substitute_template_specs_in_args(parent.args))
			else
				parent.name = Category.new(pinfo)
			end
		end

		table.insert(ret, parent)
	end


	if self._data.type ~= "toplevel" then
		local types = split_types(self._data.type)
		for _, typ in ipairs(types) do
			local pinfo = mw.clone(self._info)
			pinfo.label = ("list of %s categories"):format(typ)
			table.insert(ret, {name = Category.new(pinfo), sort = (not self._lang and " " or "") .. label})
		end
		if #types > 1 then
			local pinfo = mw.clone(self._info)
			pinfo.label = ("list of mixed categories"):format(typ)
			table.insert(ret, {name = Category.new(pinfo), sort = (not self._lang and " " or "") .. label})
		end
	end

	return ret
end


function Category:getChildren()
	return nil
end


function Category:getUmbrella()
	if not self._lang then
		return nil
	end

	-- We take advantage of the fact that this function (getUmbrella) is fully overridden in
	-- [[Module:category tree/ws topic cat]]. That code never calls this function. Moreover,
	-- this function is only called when attempting to display the category boilerplate, not
	-- simply when a category object is instantiated. This makes it a safe place to throw an
	-- error when a user tries to create a thesaurus-only category under a regular mainspace
	-- title.
	if self._data and self._data.thesaurusonly then
		error('This is a thesaurus-only category, you cannot do this')
	end

	local uinfo = mw.clone(self._info)
	uinfo.code = nil
	return Category.new(uinfo)
end


function Category:getTOCTemplateName()
	local lang = self._lang
	local code = lang and lang:getCode() or "en"
	return "Template:" .. code .. "-categoryTOC"
end


return export