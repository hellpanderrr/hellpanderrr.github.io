local export = {}

-- This module contains ancillary functions for manipulating labels. Currently the supported functions are for finding
-- the labels that generate a given category.

local labels_module = "Module:labels"

--[==[
Find the labels matching category `cat` of type `cat_type` (currently supported values are {"topic"} for topic
categories, e.g. {en:Water}; {"pos"} for POS categories, e.g. {English attenuative verbs}; {"regional"} for regional
categories, e.g. {Ghanaian English}; {"sense"} for sense categories, e.g. {English obsolete terms} or
{English terms with obsolete senses}; and {"plain"} for plain categories, e.g. {Issime Walser}) for language `lang`
(which may be {nil} for umbrella or plain categories). The format of `cat` depends on `cat_type`, but in general is
the portion of the category minus the language prefix or suffix. For topic categories it should be e.g. {"water"} or
{"Water"} (either form works); for POS categories it should be e.g. {"attenuative verbs"}; for regional categories it
should be e.g. {"Ghanaian"}; for sense categories it should be e.g. {"obsolete"}; and for plain categories it should be
e.g. {"Issime Walser"} (the actual category name).
]==]
function export.find_labels_for_category(cat, cat_type, lang)
	local function ucfirst(txt)
		return mw.getContentLanguage():ucfirst(txt)
	end
	
	local function transform_cat_for_comparison(cat)
		if cat_type ~= "pos" and cat_type ~= "sense" then
			cat = ucfirst(cat)
		end
		return cat
	end

	local function should_error_on_cat(cat)
		if cat_type == "topic" then
			return cat:find("^[Aa]ll ")
		elseif cat_type == "pos" then
			return cat == "lemmas"
		elseif cat_type == "regional" then
			return "British" -- an arbitrary known regional category
		elseif cat_type == "sense" then
			return "obsolete" -- an arbitrary known sense category
		else
			return "Issime Walser" -- an arbitrary known plain category
		end
	end

	local function labcat_matches(labcat)
		if cat_type ~= "pos" and cat_type ~= "sense" then
			return ucfirst(labcat) == cat
		else
			return labcat == cat
		end
	end

	local function fetch_labdata_cats(labdata)
		if cat_type == "topic" then
			return labdata.topical_categories
		elseif cat_type == "pos" then
			return labdata.pos_categories
		elseif cat_type == "regional" then
			return labdata.regional_categories
		elseif cat_type == "sense" then
			return labdata.sense_categories
		else
			return labdata.plain_categories
		end
	end

	cat = transform_cat_for_comparison(cat)

	local cat_labels_found = {}
	local prev_modules_labels_found = {}
	local this_module_labels_found

	local submodules_to_check = require(labels_module).get_submodules(lang)
	for _, submodule_to_check in ipairs(submodules_to_check) do
		if this_module_labels_found then
			for label, _ in pairs(this_module_labels_found) do
				prev_modules_labels_found[label] = true
			end
		end
		this_module_labels_found = {}
		local submodule = mw.loadData(submodule_to_check)
		for label, labdata in pairs(submodule) do
			local canonical = label
			local num_hops = 0
			local hop_error = false
			while type(labdata) == "string" do
				num_hops = num_hops + 1
				if num_hops >= 10 then
					if should_error_on_cat(cat) then
						error(("Internal error: Likely alias loop processing label '%s' in submodule '%s'"):format(label, submodule_to_check))
					else
						hop_error = true
						break
					end
				end
				-- an alias
				canonical = labdata
				labdata = submodule[labdata]
			end
			if hop_error then
				-- skip this label
			elseif not labdata then
				if should_error_on_cat(cat) then
					-- Only error at top level to avoid a flood of errors.
					error(("Internal error: In submodule '%s', label '%s' is aliased to '%s', which doesn't exist"):format(submodule_to_check, label, canonical))
				end
			else
				-- Deprecated labels directly assign an object to aliases, where `canonical` is the canonical label.
				if labdata.canonical then
					canonical = labdata.canonical
				end
				local labcats = fetch_labdata_cats(labdata)
				local matching_labcat
				if labcats then
					if type(labcats) ~= "table" then
						labcats = {labcats}
					end
					for _, labcat in ipairs(labcats) do
						if labcat == true then
							labcat = canonical
						end
						if labcat_matches(labcat) then
							matching_labcat = true
							break
						end
					end
				end
				if matching_labcat and not prev_modules_labels_found[canonical] then
					this_module_labels_found[canonical] = true
					if not cat_labels_found[canonical] then
						cat_labels_found[canonical] = {}
					end
					if canonical ~= label then
						table.insert(cat_labels_found[canonical], label)
					end
				end
			end
		end
	end

	return cat_labels_found
end

--[==[
Format the labels that categorize into some category for display in the text for that category. `lang` is the
language of the category, or {nil}. `labels` are the labels that categorize when invoked using {{tl|lb}}, while
`tlb_labels` are the labels that categorize when invoked using {{tl|tlb}}. Returns {nil} if there are no labels.
]==]
function export.format_labels_categorizing(labels, tlb_labels, lang)
	local function make_code(txt)
		return ("<code>%s</code>"):format(txt)
	end
	local function generate_label_set_text(labels, use_tlb, include_in_addition)
		local formatted_labels = {}
		local has_aliases = false
		for label, aliases in pairs(labels) do
			if #aliases == 0 then
				table.insert(formatted_labels, make_code(label))
			elseif #aliases == 1 then
				table.insert(formatted_labels, ("%s (alias %s)"):format(make_code(label), make_code(aliases[1])))
				has_aliases = true
			else
				table.sort(aliases)
				for i, alias in ipairs(aliases) do
					aliases[i] = make_code(alias)
				end
				table.insert(formatted_labels, ("%s (aliases %s)"):format(make_code(label), table.concat(aliases, ", ")))
				has_aliases = true
			end
		end
		template = use_tlb and "tlb" or "lb"
		if #formatted_labels > 0 then
			table.sort(formatted_labels)
			local intro_wording = include_in_addition and "In addition, the" or "The"
			local sense_dependent = use_tlb and "sense-dependent " or ""
			local retval = ("%s following %slabel%s generate%s this category: %s."):format(intro_wording,
				sense_dependent, #formatted_labels == 1 and "" or "s", #formatted_labels == 1 and "s" or "",
				table.concat(formatted_labels, "; "))
			local this_label_text
			if #formatted_labels == 1 and not has_aliases then
				this_label_text = "this label"
			else
				this_label_text = "one of these labels"
			end
			if lang then
				retval = retval .. (" To generate this category using %s, use {{tl|%s|%s|<var>label</var>}}."):format(
					this_label_text, template, lang:getCode())
			else
				retval = retval .. (" To generate this category using %s, use {{tl|%s|<var>langcode</var>|<var>label</var>}}, " ..
					"where <code><var>langcode</var></code> is the appropriate language code for the language in question " ..
					"(see [[Wiktionary:List of languages]])."):format(this_label_text, template)
			end
			return retval
		end
	end

	local labels_text = generate_label_set_text(labels)
	local tlb_labels_text = tlb_labels and
		generate_label_set_text(tlb_labels, "use tlb", labels_text and "include in addition") or nil
	if labels_text and tlb_labels_text then
		return ("%s\n\n%s"):format(labels_text, tlb_labels_text)
	else
		return labels_text or tlb_labels_text
	end
end

return export