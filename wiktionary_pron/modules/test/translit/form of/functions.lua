--[=[
DISPLAY_HANDLERS is a list of one or more functions that provide special handling for multipart tags. Each function
takes formerly a single argument (the multipart tag), now temporarily two arguments (the multipart tag and the join
strategy, which can be nil to use the default), and should either return the formatted display text or nil to check the
next handler. If no handlers apply, there is a default handler that appropriately formats most multipart tags.

CAT_FUNCTIONS is a map from function names to functions of a single argument, as described in [[Module:form of/cats]].
There are two types of functions: condition handlers (which return true or false) and spec handlers (which return a
specification, as described in [[Module:form of/cats]]). We need to put the functions here rather than in
[[Module:form of/cats]] because that module is loaded using mw.loadData(), which can't directly handle functions.
]=]

local export = {}

function export.multipart_join_strategy()
	-- Recognized values:
	-- "and": Join with "and", using commas for 3 or more items
	-- "en-dash": Join with – (en-dash)
	-- "slash": Join with / (slash)
	return "slash"
end

local function wrap_in_inflection_of_sep(text)
	return '<span class="inflection-of-sep">' .. text .. '</span>'
end
	
-- This is a local version of serialCommaJoin from [[Module:table]] that
-- implements it a bit differently.
local function join_multiparts_with_serial_comma(seq)
	local length = #seq

	if length == 0 then
		return ""
	elseif length == 1 then
		return seq[1] -- nothing to join
	elseif length == 2 then
		return seq[1] .. wrap_in_inflection_of_sep("&#32;and&#32;") .. seq[2]
	else
		local comma = '<span class="serial-comma">,</span>'
		local conj = '<span class="serial-and">&#32;and&#32;</span>'
		return table.concat(seq, wrap_in_inflection_of_sep(",&#32;"), 1, length - 1) ..
			wrap_in_inflection_of_sep(comma .. conj) .. seq[length]
	end
end

function export.join_multiparts(parts, joiner)
	-- Display the elements of a multipart tag. Currently we use "and",
	-- with commas when then are three or more elements, of the form
	-- "foo, bar, baz and bat"; but we are seriously considering switching
	-- to en-dash, e.g. "foo–bar–baz–bat". Arguably,
	--   dative–ablative masculine–feminine–neuter plural
	-- looks better then
	--   dative and ablative masculine, feminine and neuter plural
	-- and
	--   first–second–third-person singular present subjunctive
	-- looks better than
	--   first-, second- and third-person singular present subjunctive
	local strategy = joiner or export.multipart_join_strategy()
	local retval
	if strategy == "and" then
		retval = join_multiparts_with_serial_comma(parts)
	elseif strategy == "en-dash" then
		retval = table.concat(parts, wrap_in_inflection_of_sep("–"))
	elseif strategy == "slash" then
		retval = table.concat(parts, wrap_in_inflection_of_sep("/"))
	else
		error("Unrecognized multipart join strategy: " .. strategy)
	end
	return '<span class="inflection-of-conjoined">' .. retval .. '</span>'
end

export.cat_functions = {}

export.display_handlers = {}

-- Display handler to clean up display of multiple persons by omitting
-- redundant "person" in all but the last element. For example, the tag
-- "123" maps to "1//2//3", which in turn gets displayed as (approximately)
-- "first-, second- and third-person" (with appropriate glossary links, and
-- appropriate spans marking the serial comma).
table.insert(export.display_handlers,
	function(tags, joiner)
		local els = {}
		local numtags = #tags
		local strategy = joiner or export.multipart_join_strategy()
		for i, tag in ipairs(tags) do
			local suffix = i == numtags and "-person]]" or
				strategy == "and" and "-]]" or "]]"
			if tag == "first-person" then
				table.insert(els, "[[Appendix:Glossary#first person|first" .. suffix)
			elseif tag == "second-person" then
				table.insert(els, "[[Appendix:Glossary#second person|second" .. suffix)
			elseif tag == "third-person" then
				table.insert(els, "[[Appendix:Glossary#third person|third" .. suffix)
			else
				return nil
			end
		end
		return export.join_multiparts(els, joiner)
	end
)

return export