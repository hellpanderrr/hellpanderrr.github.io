local export = {}

local rsplit = mw.text.split
local u = mw.ustring.char
local TEMPCOMMA = u(0xFFF0)

local function track(page)
	require("debug/track")("dialect tags/" .. page)
	return true
end

-- See if the language's dialectal data module has a label corresponding to the dialect argument.
function export.getLabel(dialect, dialect_data)
	local data = dialect_data[dialect] or ( dialect_data.labels and dialect_data.labels[dialect] )
	local alias_of = ( dialect_data.aliases and dialect_data.aliases[dialect] )
	if not data then
		if alias_of then
			data = dialect_data[alias_of] or ( dialect_data.labels and dialect_data.labels[alias_of] )
		end
	end
	if data then
		local display = data.display or dialect
		if data.appendix then
			dialect = '[[Appendix:' .. data.appendix .. '|' .. display .. ']]'
		else
			local target = data.link
			dialect = target and '[[w:'.. target .. '|' .. display .. ']]' or display
		end
	end
	return dialect
end

function export.make_dialects(raw, lang)
	local dialect_page = 'Module:'.. lang:getCode() ..':Dialects'
	local dialect_info
	if raw[1] then
		dialect_info = mw.title.new(dialect_page).exists and mw.loadData(dialect_page) or false
	end
		
	local dialects = {}
	
	for _, dialect in ipairs(raw) do
		table.insert(dialects, dialect_info and export.getLabel(dialect, dialect_info) or dialect)
	end
	
	return dialects
end

-- Used when splitting on commas. If comma+whitespace is seen, replace the comma with a temporary char. Return whether
-- the replacement was done (meaning that it has to be undone).
function export.escape_comma_whitespace(val)
	track("escape-comma-whitespace")
	local need_tempcomma_undo = false
	if val:find(",%s") then
		val = val:gsub(",(%s)", TEMPCOMMA .. "%1")
		need_tempcomma_undo = true
	end
	return val, need_tempcomma_undo
end

-- Undo the replacement of comma with a temporary char. See split_on_comma().
function export.unescape_comma_whitespace(val)
	track("unescape-comma-whitespace")
	val = val:gsub(TEMPCOMMA, ",") -- assign to temp to discard second retval
	return val
end

-- Split a value on commas, but don't split on comma+whitespace. Lua doesn't have negative lookahead
-- assertions so it's a bit harder to do this. We do it by replacing comma followed by whitespace
-- with a temporary char, doing the split and undoing the temporary char replacement.
function export.split_on_comma(val)
	track("split-on-comma")
	local escaped_val, need_tempcomma_undo = export.escape_comma_whitespace(val)
	escaped_val = rsplit(escaped_val, ",")
	if need_tempcomma_undo then
		for i, ev in ipairs(escaped_val) do
			escaped_val[i] = export.unescape_comma_whitespace(ev)
		end
	end
	return escaped_val
end

function export.post_format_dialects(dialects)
	dialects = "&mdash; ''" .. table.concat(dialects, ", ") .. "''"
	-- Fixes the problem of '' being added to '' at the end of last dialect parameter
	dialects = dialects:gsub("''''", "")
	return dialects
end

return export