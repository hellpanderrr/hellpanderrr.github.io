local export = {}

local m_form_of = require("form of")
local m_params = require("parameters")
local put_module = "Module:parse utilities"
local rfind = mw.ustring.find
local rmatch = mw.ustring.match
local rsplit = mw.text.split
local rgsplit = mw.text.gsplit

-- Add tracking category for PAGE when called from TEMPLATE. The tracking category linked to is
-- [[Template:tracking/form-of/TEMPLATE/PAGE]]. If TEMPLATE is omitted, the tracking category is of the form
-- [[Template:tracking/form-of/PAGE]].
local function track(page, template)
	require("debug/track")("form-of/" .. (template and template .. "/" or "") .. page)
end


-- Equivalent to list.extend(new_items) in Python. Appends items in `new_items` (a list) to `list`.
local function extend_list(list, new_items)
	for _, item in ipairs(new_items) do
		table.insert(list, item)
	end
end


local function get_script(sc, param_for_error)
	return sc and require("scripts").getByCode(sc, param_for_error) or nil
end


local function get_common_template_params()
	return {
		-- Named params not controlling link display
		["cat"] = {list = true},
		["notext"] = {type = "boolean"},
		["sort"] = {},
		["enclitic"] = {},
		-- FIXME! The following should only be available when withcap=1 in invocation args. Before doing that, need to
		-- remove all uses of nocap= in other circumstances.
		["nocap"] = {type = "boolean"},
		-- FIXME! The following should only be available when withdot=1 in invocation args. Before doing that, need to
		-- remove all uses of nodot= in other circumstances.
		["nodot"] = {type = "boolean"},
		["pagename"] = {}, -- for testing, etc.
	}
end

--[=[
Process parent arguments. This is similar to the following:
	require("parameters").process(parent_args, params)
but in addition it does the following:
(1) Supplies default values for unspecified parent arguments as specified in
	DEFAULTS, which consist of specs of the form "ARG=VALUE". These are
	added to the parent arguments prior to processing, so boolean and number
	parameters will process the value appropriately.
(2) Removes parent arguments specified in IGNORESPECS, which consist either
	of bare argument names to remove, or list-argument names to remove of the
	form "ARG:list".
(3) Tracks the use of any parent arguments specified in TRACKED_PARAMS, which
	is a set-type table where the keys are arguments as they exist after
	processing (hence numeric arguments should be numbers, not strings)
	and the values should be boolean true.
]=]--
local function process_parent_args(template, parent_args, params, defaults, ignorespecs, tracked_params, function_name)
	if #defaults > 0 or #ignorespecs > 0 then
		local new_parent_args = {}
		for _, default in ipairs(defaults) do
			local defparam, defval = rmatch(default, "^(.-)=(.*)$")
			if not defparam then
				error("Bad default spec " .. default)
			end
			new_parent_args[defparam] = defval
		end

		local params_to_ignore = {}
		local numbered_list_params_to_ignore = {}
		local named_list_params_to_ignore = {}

		for _, ignorespec in ipairs(ignorespecs) do
			for ignore in rgsplit(ignorespec, ",") do
				local param = rmatch(ignore, "^(.*):list$")
				if param then
					if rfind(param, "^[0-9]+$") then
						table.insert(numbered_list_params_to_ignore, tonumber(param))
					else
						table.insert(named_list_params_to_ignore,
							"^" .. require("utilities").pattern_escape(param) .. "[0-9]*$")
					end
				else
					if rfind(ignore, "^[0-9]+$") then
						ignore = tonumber(ignore)
					end
					params_to_ignore[ignore] = true
				end
			end
		end

		for k, v in pairs(parent_args) do
			if not params_to_ignore[k] then
				local ignore_me = false
				if type(k) == "number" then
					for _, lparam in ipairs(numbered_list_params_to_ignore) do
						if k >= lparam then
							ignore_me = true
							break
						end
					end
				else
					for _, lparam in ipairs(named_list_params_to_ignore) do
						if rfind(k, lparam) then
							ignore_me = true
							break
						end
					end
				end
				if not ignore_me then
					new_parent_args[k] = v
				end
			end
		end
		parent_args = new_parent_args
	end

	local args = m_params.process(parent_args, params, nil, "form of/templates", function_name)

	-- Tracking for certain user-specified params. This is generally used for
	-- parameters that we accept but ignore, so that we can eventually remove
	-- all uses of these params and stop accepting them.
	if tracked_params then
		for tracked_param, _ in pairs(tracked_params) do
			if parent_args[tracked_param] then
				track("arg/" .. tracked_param, template)
			end
		end
	end

	return args
end


-- Split TAGSPECS (inflection tag specifications) on SPLIT_REGEX, which
-- may be nil for no splitting.
local function split_inflection_tags(tagspecs, split_regex)
	if not split_regex then
		return tagspecs
	end
	local inflection_tags = {}
	for _, tagspec in ipairs(tagspecs) do
		for tag in rgsplit(tagspec, split_regex) do
			table.insert(inflection_tags, tag)
		end
	end
	return inflection_tags
end


local term_param_mods = {
	t = {
		-- We need to store the <t:...> inline modifier into the "gloss" key of the parsed part, because that is what
		-- [[Module:links]] expects.
		item_dest = "gloss",
	},
	gloss = {},
	tr = {},
	ts = {},
	g = {
		-- We need to store the <g:...> inline modifier into the "genders" key of the parsed part, because that is what
		-- [[Module:links]] expects.
		item_dest = "genders",
		convert = function(arg, parse_err)
			return rsplit(arg, ",")
		end,
	},
	id = {},
	alt = {},
	q = {},
	qq = {},
	lit = {},
	pos = {},
	sc = {
		convert = function(arg, parse_err)
			return get_script(arg, parse_err)
		end,
	}
}


local function parse_terms_with_inline_modifiers(paramname, val, lang)
	local function generate_obj(term)
		return {lang = lang, term = term}
	end

	local retval
	-- Check for inline modifier, e.g. מרים<tr:Miryem>. But exclude HTML entry with <span ...>, <i ...>, <br/> or
	-- similar in it, caused by wrapping an argument in {{l|...}}, {{af|...}} or similar. Basically, all tags of
	-- the sort we parse here should consist of a less-than sign, plus letters, plus a colon, e.g. <tr:...>, so if
	-- we see a tag on the outer level that isn't in this format, we don't try to parse it. The restriction to the
	-- outer level is to allow generated HTML inside of e.g. qualifier tags, such as foo<q:similar to {{m|fr|bar}}>.
	if val:find("<") and not val:find("^[^<]*<[a-z]*[^a-z:]") then
		retval = require(put_module).parse_inline_modifiers(val, {
			paramname = paramname,
			param_mods = term_param_mods,
			generate_obj = generate_obj,
			splitchar = ",",
		})
	else
		if val:find(",<") then
			-- this happens when there's an embedded {{,}} template, as in [[MMR]], [[TMA]], [[DEI]], where an initialism
			-- expands to multiple terms; easiest not to try and parse the lemma spec as multiple lemmas
			retval = {val}
		elseif val:find(",%s") or (val:find(",") and val:find("[\\%[<]")) then
			-- Comma after whitespace not split; nor are backslash-escaped commas or commas inside of square or
			-- angle brackets. If we see any of these, use the more sophisticated algorithm in
			-- [[Module:parse utilities]]. Otherwise it's safe to just split on commas directly. This optimization avoids
			-- loading [[Module:parse utilities]] unnecessarily.
			retval = require(put_module).split_on_comma(val)
		else
			retval = rsplit(val, ",")
		end
		for i, split in ipairs(retval) do
			retval[i] = generate_obj(split)
		end
	end

	return retval
end


local link_params = { "term", "alt", "t", "gloss", "sc", "tr", "ts", "pos", "id", "lit" }
local link_param_set = {}
for _, param in ipairs(link_params) do
	link_param_set[param] = true
end

-- Modify PARAMS in-place by adding parameters that control the link to the
-- main entry. TERM_PARAM is the number of the param specifying the main
-- entry itself; TERM_PARAM + 1 will be the display text, and TERM_PARAM + 2
-- will be the gloss, unless NO_NUMBERED_GLOSS is given.
local function add_link_params(parent_args, params, term_param, no_numbered_gloss)
	for k, v in pairs(parent_args) do
		if type(k) == "string" then
			local base, num = k:match("^([a-z]+)([0-9]+)$")
			if base and link_param_set[base] then
				track("multiple-lemmas")
				error("Support for the separate-parameter style of multiple lemmas in form-of templates is going away; use a comma-separated lemma param with inline modifiers")
			end
		end
	end
	-- If no params for the second or higher term exist, use a simpler param setup to save memory.
	params[term_param + 1] = {alias_of = "alt"}
	if not no_numbered_gloss then
		params[term_param + 2] = {alias_of = "t"}
	end
	-- Numbered params controlling link display
	params[term_param] = {}

	-- Named params controlling link display
	params["gloss"] = {alias_of = "t"}
	params["g"] = {list = true}
	for _, param in ipairs(link_params) do
		if param ~= "gloss" and param ~= "g" and param ~= "term" then
			params[param] = {}
		end
	end
end


local function add_base_lemma_params(parent_args, iargs, params, compat)
	-- Need to do what [[Module:parameters]] does to string arguments from parent_args as we're running this
	-- before calling [[Module:parameters]] on parent_args.
	local function ine(arg)
		if not arg then
			return nil
		end
		arg = mw.text.trim(arg)
		return arg ~= "" and arg or nil
	end

	local langcode = ine(parent_args[compat and "lang" or 1]) or iargs["lang"] or "und"
	if m_form_of.langs_with_lang_specific_tags[langcode] then
		local langdata = mw.loadData(m_form_of.form_of_lang_data_module_prefix .. langcode)
		if langdata.base_lemma_params then
			for _, param in ipairs(langdata.base_lemma_params) do
				params[param.param] = {}
			end
			return langdata.base_lemma_params
		end
	end
end


--[=[
Given processed invocation arguments IARGS and processed parent arguments ARGS, as well as TERM_PARAM (the parent
argument specifying the first main entry/lemma) and COMPAT (true if the language code is found in args["lang"] instead
of args[1]), return an object as follows:
{
	lang = LANG,
	lemmas = {LEMMA_OBJ, LEMMA_OBJ, ...},
	enclitics = {ENCLITIC_OBJ, ENCLITIC_OBJ, ...},
	base_lemmas = {BASE_LEMMA_OBJ, BASE_LEMMA_OBJ, ...},
	categories = {"CATEGORY", "CATEGORY", ...},
}

where

* LANG is the language code;
* LEMMAS is a sequence of objects specifying the main entries/lemmas, as passed to full_link in [[Module:links]];
  however, if the invocation argument linktext= is given, it will be a string consisting of that text, and if the
  invocation argument nolink= is given, it will be nil;
* ENCLITICS is nil or a sequence of objects specifying the enclitics, as passed to full_link in [[Module:links]];
* BASE_LEMMA_OBJ is a sequence of objects specifying the base lemma(s), which are used when the lemma is itself a
  form of another lemma (the base lemma), e.g. a comparative, superlative or participle; each object is of the form
  { paramobj = PARAM_OBJ, lemmas = {LEMMA_OBJ, LEMMA_OBJ, ...} } where PARAM_OBJ describes the properties of the
  base lemma parameter (i.e. the relationship between the intermediate and base lemmas) and LEMMA_OBJ is of the same
  format of ENCLITIC_OBJ, i.e. an object suitable to be passed to full_link in [[Module:links]]; PARAM_OBJ is of the
  format { param = "PARAM", tags = {"TAG", "TAG", ...} } where PARAM is the name of the parameter to {{inflection of}}
  etc. that holds the base lemma(s) of the specified relationship and the tags describe the relationship, such as
  {"comd"} or {"past", "part"};
* CATEGORIES is the categories to add the page to (consisting of any categories specified in the invocation or
  parent args and any tracking categories, but not any additional lang-specific categories that may be added by
  {{inflection of}} or similar templates).

This is a subfunction of construct_form_of_text().
]=]
local function get_lemmas_and_categories(iargs, args, term_param, compat, base_lemma_params)
	local lang = args[compat and "lang" or 1] or iargs["lang"] or "und"
	lang = require("languages").getByCode(lang, compat and "lang" or 1)

	-- Determine categories for the page, including tracking categories

	local categories = {}

	if not args["nocat"] then
		for _, cat in ipairs(iargs["cat"]) do
			table.insert(categories, lang:getCanonicalName() .. " " .. cat)
		end
	end
	for _, cat in ipairs(args["cat"]) do
		table.insert(categories, lang:getCanonicalName() .. " " .. cat)
	end

	-- Format the link, preceding text and categories

	local function add_term_tracking_categories(term)
		-- add tracking category if term is same as page title
		if term and mw.title.getCurrentTitle().text == (lang:makeEntryName(term)) then
			table.insert(categories, "Forms linking to themselves")
		end
		-- maybe add tracking category if primary entry doesn't exist (this is an
		-- expensive call so we don't do it by default)
		if iargs["noprimaryentrycat"] and term and mw.title.getCurrentTitle().nsText == ""
			and not mw.title.new(term).exists then
			table.insert(categories, lang:getCanonicalName() .. " " .. iargs["noprimaryentrycat"])
		end
	end

	local lemmas

	if iargs["nolink"] then
		lemmas = nil
	elseif iargs["linktext"] then
		lemmas = iargs["linktext"]
	else
		local term = args[term_param]

		if not term and not args["alt"] and not args["tr"] and not args["ts"] then
			if mw.title.getCurrentTitle().nsText == "Template" then
				term = "term"
			else
				error("No linked-to term specified; either specify term, alt, translit or transcription")
			end
		end

		if term then
			lemmas = parse_terms_with_inline_modifiers(term_param, term, lang)
			for _, lemma in ipairs(lemmas) do
				add_term_tracking_categories(lemma.term)
			end
		else
			lemmas = {{ lang = lang }}
		end

		-- sc= but not invocation arg sc= should override inline modifier sc=.
		local sc
		if args["sc"] then
			lemmas[1].sc = get_script(args["sc"], "sc")
		elseif not lemmas[1].sc and iargs["sc"] then
			lemmas[1].sc = get_script(iargs["sc"], "sc")
		end

		if #args["g"] > 0 then
			local genders = {}
			for _, g in ipairs(args["g"]) do
				extend_list(genders, rsplit(g, ","))
			end
			lemmas[1].genders = genders
		end
		if args["t"] then
			lemmas[1].gloss = args["t"]
		end
		for _, param in ipairs(link_params) do
			if param ~= "sc" and param ~= "term" and param ~= "g" and param ~= "gloss" and param ~= "t" and
				args[param] then
				lemmas[1][param] = args[param]
			end
		end
	end

	local enclitics
	if args.enclitic then
		enclitics = parse_terms_with_inline_modifiers("enclitic", args.enclitic, lang)
	end
	local base_lemmas = {}
	if base_lemma_params then
		for _, base_lemma_param_obj in ipairs(base_lemma_params) do
			local param = base_lemma_param_obj.param
			if args[param] then
				table.insert(base_lemmas, {
					paramobj = base_lemma_param_obj,
					lemmas = parse_terms_with_inline_modifiers(param, args[param], lang),
				})
			end
		end
	end

	return {
		lang = lang,
		lemmas = lemmas,
		enclitics = enclitics,
		base_lemmas = base_lemmas,
		categories = categories,
	}
end


-- Construct and return the full definition line for a form-of-type template invocation, given processed invocation
-- arguments IARGS, processed parent arguments ARGS, TERM_PARAM (the parent argument specifying the main entry), COMPAT
-- (true if the language code is found in args["lang"] instead of args[1]), and DO_FORM_OF, which is a function that
-- returns the actual definition-line text and any language-specific categories. The terminating period/dot will be
-- added as appropriate, the language-specific categories will be added to any categories requested by the invocation
-- or parent args, and then whole thing will be appropriately formatted.
--
-- DO_FORM_OF takes one argument, the return value of get_lemmas_and_categories() (an object describing the lemmas,
-- clitics, base lemmas and categories fetched).
--
-- DO_FORM_OF should return two arguments:
--
-- (1) The actual definition-line text, marked up appropriately with <span>...</span> but without any terminating
--     period/dot.
-- (2) Any extra categories to add the page to (other than those that can be derived from parameters specified to the
--     invocation or parent arguments, which will automatically be added to the page).
local function construct_form_of_text(iargs, args, term_param, compat, base_lemma_params, do_form_of)
	local lemma_data = get_lemmas_and_categories(iargs, args, term_param, compat, base_lemma_params)

	local form_of_text, lang_cats = do_form_of(lemma_data)
	extend_list(lemma_data.categories, lang_cats)
	local text = form_of_text .. (
		args["nodot"] and "" or args["dot"] or iargs["withdot"] and "." or ""
	)
	if #lemma_data.categories == 0 then
		return text
	end
	return text .. require("utilities").format_categories(lemma_data.categories, lemma_data.lang, args["sort"],
		-- If lemma_is_sort_key is given, supply the first lemma term as the sort base if possible. If sort= is given,
		-- it will override the base; otherwise, the base will be converted appropriately to a sort key using the
		-- same algorithm applied to pagenames.
		iargs.lemma_is_sort_key and type(lemma_data.lemmas) == "table" and lemma_data.lemmas[1].term,
		-- Supply the first lemma's script for sort key computation.
		m_form_of.force_cat, type(lemma_data.lemmas) == "table" and lemma_data.lemmas[1].sc)
end


-- Invocation parameters shared between form_of_t(), tagged_form_of_t() and inflection_of_t().
local function get_common_invocation_params()
	return {
		["term_param"] = {type = "number"},
		["lang"] = {},
		["sc"] = {},
		["cat"] = {list = true},
		["ignore"] = {list = true},
		["def"] = {list = true},
		["withcap"] = {type = "boolean"},
		["withdot"] = {type = "boolean"},
		["nolink"] = {type = "boolean"},
		["linktext"] = {},
		["posttext"] = {},
		["noprimaryentrycat"] = {},
		["lemma_is_sort_key"] = {},
	}
end


--[=[
Function that implements {{form of}} and the various more specific form-of
templates (but not {{inflection of}} or templates that take tagged inflection
parameters).

Invocation params:

1= (required):
	Text to display before the link.
term_param=:
	Numbered param holding the term linked to. Other numbered params come after. Defaults to 1 if invocation or template
	param lang= is present, otherwise 2.
lang=:
	Default language code for language-specific templates. If specified, no language code needs to be specified, and if
	specified it needs to be set using lang=, not 1=.
sc=:
	Default script code for language-specific templates. The script code can still be overridden using template param
	sc=.
cat=, cat2=, ...:
	Categories to place the page into. The language name will automatically be prepended. Note that there is also a
	template param cat= to specify categories at the template level. Use of nocat= disables categorization of categories
	specified using invocation param cat=, but not using template param cat=.
ignore=, ignore2=, ...:
	One or more template params to silently accept and ignore. Useful e.g. when the template takes additional parameters
	such as from= or POS=. Each value is a comma-separated list of either bare parameter names or specifications of the
	form "PARAM:list" to specify that the parameter is a list parameter.
def=, def2=, ...:
	One or more default values to supply for template args. For example, specifying '|def=tr=-' causes the default for
	template param '|tr=' to be '-'. Actual template params override these defaults.
withcap=:
	Capitalize the first character of the text preceding the link, unless template param nocap= is given.
withdot=:
	Add a final period after the link, unless template param nodot= is given to suppress the period, or dot= is given to
	specify an alternative punctuation character.
nolink=:
	Suppress the display of the link. If specified, none of the template params that control the link (TERM_PARAM,
	TERM_PARAM + 1, TERM_PARAM + 2, t=, gloss=, sc=, tr=, ts=, pos=, g=, id=, lit=) will be available. If the calling
	template uses any of these parameters, they must be ignored using ignore=.
linktext=:
	Override the display of the link with the specified text. This is useful if a custom template is available to format
	the link (e.g. in Hebrew, Chinese and Japanese). If specified, none of the template params that control the link
	(TERM_PARAM, TERM_PARAM + 1, TERM_PARAM + 2, t=, gloss=, sc=, tr=, ts=, pos=, g=, id=, lit=) will be available. If
	the calling template uses any of these parameters, they must be ignored using ignore=.
posttext=:
	Additional text to display directly after the formatted link, before any terminating period/dot and inside of
	"<span class='use-with-mention'>".
noprimaryentrycat=:
	Category to add the page to if the primary entry linked to doesn't exist. The language name will automatically be
	prepended.
lemma_is_sort_key=:
	If the user didn't specify a sort key, use the lemma as the sort key (instead of the page itself).
]=]--
function export.form_of_t(frame)
	local iparams = get_common_invocation_params()
	iparams[1] = {required = true}
	local iargs = m_params.process(frame.args, iparams, nil, "form of/templates", "form_of_t")
	local parent_args = frame:getParent().args

	local term_param = iargs["term_param"]

	local compat = iargs["lang"] or parent_args["lang"]
	term_param = term_param or compat and 1 or 2

	local params = get_common_template_params()
	-- Numbered params
	params[compat and "lang" or 1] = {required = not iargs["lang"]}

	local base_lemma_params
	if not iargs["nolink"] and not iargs["linktext"] then
		add_link_params(parent_args, params, term_param)
		base_lemma_params = add_base_lemma_params(parent_args, iargs, params, compat)
	end

	if next(iargs["cat"]) then
		params["nocat"] = {type = "boolean"}
	end

	local ignored_params = {}

	if iargs["withdot"] then
		params["dot"] = {}
	else
		ignored_params["nodot"] = true
	end

	if not iargs["withcap"] then
		params["cap"] = {type = "boolean"}
		ignored_params["nocap"] = true
	end

	local args = process_parent_args("form-of-t", parent_args, params, iargs["def"],
		iargs["ignore"], ignored_params, "form_of_t")

	local text = args["notext"] and "" or iargs[1]
	if args["cap"] or iargs["withcap"] and not args["nocap"] then
		text = require("string utilities").ucfirst(text)
	end

	return construct_form_of_text(iargs, args, term_param, compat, base_lemma_params,
		function(lemma_data)
			return m_form_of.format_form_of {text = text, lemmas = lemma_data.lemmas, enclitics = lemma_data.enclitics,
				base_lemmas = lemma_data.base_lemmas, lemma_face = "term", posttext = iargs["posttext"]}, {}
		end
	)
end


--[=[
Construct and return the full definition line for a form-of-type template invocation that is based on inflection tags.
This is a wrapper around construct_form_of_text() and takes the following arguments: processed invocation arguments
IARGS, processed parent arguments ARGS, TERM_PARAM (the parent argument specifying the main entry), COMPAT (true if the
language code is found in args["lang"] instead of args[1]), and TAGS, the list of (non-canonicalized) inflection tags.
It returns that actual definition-line text including terminating period/full-stop, formatted categories, etc. and
should be directly returned as the template function's return value. JOINER is the optional strategy to join multipart
tags for display; currently accepted values are "and", "slash", "en-dash"; defaults to "slash".
]=]
local function construct_tagged_form_of_text(iargs, args, term_param, compat, base_lemma_params, tags, joiner)
	return construct_form_of_text(iargs, args, term_param, compat, base_lemma_params,
		function(lemma_data)
			-- NOTE: tagged_inflections returns two values, so we do too.
			return m_form_of.tagged_inflections {
				lang = lemma_data.lang,
				tags = tags,
				lemmas = lemma_data.lemmas,
				enclitics = lemma_data.enclitics,
				base_lemmas = lemma_data.base_lemmas,
				lemma_face = "term",
				POS = args["p"],
				pagename = args["pagename"],
				-- Set no_format_categories because we do it ourselves in construct_form_of_text().
				no_format_categories = true,
				nocat = args["nocat"],
				notext = args["notext"],
				capfirst = args["cap"] or iargs["withcap"] and not args["nocap"],
				posttext = iargs["posttext"],
				joiner = joiner,
			}
		end
	)
end


--[=[
Function that implements form-of templates that are defined by specific tagged inflections (typically a template
referring to a non-lemma inflection, such as {{plural of}}). This works exactly like form_of_t() except that the
"form of" text displayed before the link is based off of a pre-specified set of inflection tags (which will be
appropriately linked to the glossary) instead of arbitrary text. From the user's perspective, there is no difference
between templates implemented using form_of_t() and tagged_form_of_t(); they accept exactly the same parameters and
work the same. See also inflection_of_t() below, which is intended for templates with user-specified inflection tags.

Invocation params:

1=, 2=, ... (required):
	One or more inflection tags describing the inflection in question.
split_tags=:
	If specified, character to split specified inflection tags on. This allows
	multiple tags to be included in a single argument, simplifying template
	code.
term_param=:
lang=:
sc=:
cat=, cat2=, ...:
ignore=, ignore2=, ...:
def=, def2=, ...:
withcap=:
withdot=:
nolink=:
linktext=:
posttext=:
noprimaryentrycat=:
lemma_is_sort_key=:
	All of these are the same as in form_of_t().
]=]--
function export.tagged_form_of_t(frame)
	local iparams = get_common_invocation_params()
	iparams[1] = {list = true, required = true}
	iparams["split_tags"] = {}

	local iargs = m_params.process(frame.args, iparams, nil, "form of/templates", "tagged_form_of_t")
	local parent_args = frame:getParent().args

	local term_param = iargs["term_param"]

	local compat = iargs["lang"] or parent_args["lang"]
	term_param = term_param or compat and 1 or 2

	local params = get_common_template_params()
	-- Numbered params
	params[compat and "lang" or 1] = {required = not iargs["lang"]}
	-- Always included because lang-specific categories may be added
	params["nocat"] = {type = "boolean"}
	params["p"] = {}
	params["POS"] = {alias_of = "p"}

	local base_lemma_params
	if not iargs["nolink"] and not iargs["linktext"] then
		add_link_params(parent_args, params, term_param)
		base_lemma_params = add_base_lemma_params(parent_args, iargs, params, compat)
	end

	local ignored_params = {}

	if iargs["withdot"] then
		params["dot"] = {}
	else
		ignored_params["nodot"] = true
	end

	if not iargs["withcap"] then
		params["cap"] = {type = "boolean"}
		ignored_params["nocap"] = true
	end

	local args = process_parent_args("tagged-form-of-t", parent_args,
		params, iargs["def"], iargs["ignore"], ignored_params, "tagged_form_of_t")

	return construct_tagged_form_of_text(iargs, args, term_param, compat, base_lemma_params,
		split_inflection_tags(iargs[1], iargs["split_tags"]))
end

--[=[
Function that implements {{inflection of}} and certain semi-specific variants,
such as {{participle of}} and {{past participle form of}}. This function is
intended for templates that allow the user to specify a set of inflection tags.
It works similarly to form_of_t() and tagged_form_of_t() except that the
calling convention for the calling template is
	{{TEMPLATE|LANG|MAIN_ENTRY_LINK|MAIN_ENTRY_DISPLAY_TEXT|TAG|TAG|...}}
instead of 
	{{TEMPLATE|LANG|MAIN_ENTRY_LINK|MAIN_ENTRY_DISPLAY_TEXT|GLOSS}}
Note that there isn't a numbered parameter for the gloss, but it can still
be specified using t= or gloss=.

Invocation params:

preinfl=, preinfl2=, ...:
	Extra inflection tags to automatically prepend to the tags specified by
	the template.
postinfl=, postinfl2=, ...:
	Extra inflection tags to automatically append to the tags specified by the
	template. Used for example by {{past participle form of}} to add the tags
	'of the|past|p' onto the user-specified tags, which indicate which past
	participle form the page refers to.
split_tags=:
	If specified, character to split specified inflection tags on. This allows
	multiple tags to be included in a single argument, simplifying template
	code. Note that this applies *ONLY* to inflection tags specified in the
	invocation arguments using preinfl= or postinfl=, not to user-specified
	inflection tags.
term_param=:
lang=:
sc=:
cat=, cat2=, ...:
ignore=, ignore2=, ...:
def=, def2=, ...:
withcap=:
withdot=:
nolink=:
linktext=:
posttext=:
noprimaryentrycat=:
lemma_is_sort_key=:
	All of these are the same as in form_of_t().
]=]--
function export.inflection_of_t(frame)
	local iparams = get_common_invocation_params()
	iparams["preinfl"] = {list = true}
	iparams["postinfl"] = {list = true}
	iparams["split_tags"] = {}

	local iargs = m_params.process(frame.args, iparams, nil, "form of/templates", "inflection_of_t")
	local parent_args = frame:getParent().args

	local term_param = iargs["term_param"]

	local compat = iargs["lang"] or parent_args["lang"]
	term_param = term_param or compat and 1 or 2
	local tagsind = term_param + 2

	local params = get_common_template_params()
	-- Numbered params
	params[compat and "lang" or 1] = {required = not iargs["lang"]}
	params[tagsind] = {list = true,
		-- at least one inflection tag is required unless preinfl or postinfl tags are given
		required = #iargs["preinfl"] == 0 and #iargs["postinfl"] == 0}

	-- Named params not controlling link display
	-- Always included because lang-specific categories may be added
	params["nocat"] = {type = "boolean"}
	params["p"] = {}
	params["POS"] = {alias_of = "p"}
	-- Temporary, allows multipart joiner to be controlled on a template-by-template basis.
	params["joiner"] = {}

	local base_lemma_params
	if not iargs["nolink"] and not iargs["linktext"] then
		add_link_params(parent_args, params, term_param, "no-numbered-gloss")
		base_lemma_params = add_base_lemma_params(parent_args, iargs, params, compat)
	end

	local ignored_params = {}

	if iargs["withdot"] then
		params["dot"] = {}
	else
		ignored_params["nodot"] = true
	end

	if not iargs["withcap"] then
		params["cap"] = {type = "boolean"}
		ignored_params["nocap"] = true
	end

	local args = process_parent_args("inflection-of-t", parent_args,
		params, iargs["def"], iargs["ignore"], ignored_params, "inflection_of_t")

	local infls
	if not next(iargs["preinfl"]) and not next(iargs["postinfl"]) then
		-- If no preinfl or postinfl tags, just use the user-specified tags directly.
		infls = args[tagsind]
	else
		-- Otherwise, we need to prepend the preinfl tags and postpend the postinfl tags. If there's only one tag set
		-- (no semicolon), it's easier. Since this is common, we optimize for it.
		infls = {}
		local saw_semicolon = false
		for _, infl in ipairs(args[tagsind]) do
			if infl == ";" then
				saw_semicolon = true
				break
			end
		end
		local split_preinfl = split_inflection_tags(iargs["preinfl"], iargs["split_tags"])
		local split_postinfl = split_inflection_tags(iargs["postinfl"], iargs["split_tags"])
		if not saw_semicolon then
			extend_list(infls, split_preinfl)
			extend_list(infls, args[tagsind])
			extend_list(infls, split_postinfl)
		else
			local groups = m_form_of.split_tags_into_tag_sets(args[tagsind])
			for _, group in ipairs(groups) do
				if #infls > 0 then
					table.insert(infls, ";")
				end
				extend_list(infls, split_preinfl)
				extend_list(infls, group)
				extend_list(infls, split_postinfl)
			end
		end
	end

	return construct_tagged_form_of_text(iargs, args, term_param, compat, base_lemma_params, infls,
		parent_args["joiner"])
end

--[=[
Normalize a part-of-speech tag given a possible abbreviation
(passed in as 1= of the invocation args). If the abbreviation
isn't recognized, the original POS tag is returned. If no POS
tag is passed in, return the value of invocation arg default=.
]=]--
function export.normalize_pos(frame)
	local iparams = {
		[1] = {},
		["default"] = {},
	}
	local iargs = m_params.process(frame.args, iparams, nil, "form of/templates", "normalize_pos")
	if not iargs[1] and not iargs["default"] then
		error("Either 1= or default= must be given in the invocation args")
	end
	if not iargs[1] then
		return iargs["default"]
	end
	return mw.loadData(m_form_of.form_of_pos_module)[iargs[1]] or iargs[1]
end

return export