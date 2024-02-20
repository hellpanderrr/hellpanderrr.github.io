local export = {}

local m_string_utilities = require("string utilities")

local rfind = mw.ustring.find
local rsplit = mw.text.split
local u = mw.ustring.char
local rsubn = mw.ustring.gsub

-- version of rsubn() that discards all but the first return value
local function rsub(term, foo, bar)
	local retval = rsubn(term, foo, bar)
	return retval
end


--[=[
In order to understand the following parsing code, you need to understand how inflected text specs work. They are
intended to work with inflected text where individual words to be inflected may be followed by inflection specs in
angle brackets. The format of the text inside of the angle brackets is up to the individual language and part-of-speech
specific implementation. A real-world example is as follows: "[[медичний|меди́чна]]<+> [[сестра́]]<*,*#.pr>". This is the
inflection of a multiword expression "меди́чна сестра́", which means "nurse" in Ukrainian (literally "medical sister"),
consisting of two words: the adjective меди́чна ("medical" in the feminine singular) and the noun сестра́ ("sister"). The
specs in angle brackets follow each word to be inflected; for example, <+> means that the preceding word should be
declined as an adjective.

The code below works in terms of balanced expressions, which are bounded by delimiters such as < > or [ ]. The
intention is to allow separators such as spaces to be embedded inside of delimiters; such embedded separators will not
be parsed as separators. For example, Ukrainian noun specs allow footnotes in brackets to be inserted inside of angle
brackets; something like "меди́чна<+> сестра́<pr.[this is a footnote]>" is legal, as is
"[[медичний|меди́чна]]<+> [[сестра́]]<pr.[this is an <i>italicized footnote</i>]>", and the parsing code should not be
confused by the embedded brackets, spaces or angle brackets.

The parsing is done by two functions, which work in close concert: parse_balanced_segment_run() and
split_alternating_runs(). To illustrate, consider the following:

parse_balanced_segment_run("foo<M.proper noun> bar<F>", "<", ">") =
  {"foo", "<M.proper noun>", " bar", "<F>", ""}

then

split_alternating_runs({"foo", "<M.proper noun>", " bar", "<F>", ""}, " ") =
  {{"foo", "<M.proper noun>", ""}, {"bar", "<F>", ""}}

Here, we start out with a typical inflected text spec "foo<M.proper noun> bar<F>", call parse_balanced_segment_run() on
it, and call split_alternating_runs() on the result. The output of parse_balanced_segment_run() is a list where
even-numbered segments are bounded by the bracket-like characters passed into the function, and odd-numbered segments
consist of the surrounding text. split_alternating_runs() is called on this, and splits *only* the odd-numbered
segments, grouping all segments between the specified character. Note that the inner lists output by
split_alternating_runs() are themselves in the same format as the output of parse_balanced_segment_run(), with
bracket-bounded text in the even-numbered segments. Hence, such lists can be passed again to split_alternating_runs().
]=]


--[==[
Parse a string containing matched instances of parens, brackets or the like. Return a list of strings, alternating
between textual runs not containing the open/close characters and runs beginning and ending with the open/close
characters. For example,

{parse_balanced_segment_run("foo(x(1)), bar(2)", "(", ")") = {"foo", "(x(1))", ", bar", "(2)", ""}}
]==]
function export.parse_balanced_segment_run(segment_run, open, close)
	return m_string_utilities.capturing_split(segment_run, "(%b" .. open .. close .. ")")
end

-- The following is an equivalent, older implementation that does not use %b (written before I was aware of %b).
--[=[
function export.parse_balanced_segment_run(segment_run, open, close)
	local break_on_open_close = m_string_utilities.capturing_split(segment_run, "([%" .. open .. "%" .. close .. "])")
	local text_and_specs = {}
	local level = 0
	local seg_group = {}
	for i, seg in ipairs(break_on_open_close) do
		if i % 2 == 0 then
			if seg == open then
				table.insert(seg_group, seg)
				level = level + 1
			else
				assert(seg == close)
				table.insert(seg_group, seg)
				level = level - 1
				if level < 0 then
					error("Unmatched " .. close .. " sign: '" .. segment_run .. "'")
				elseif level == 0 then
					table.insert(text_and_specs, table.concat(seg_group))
					seg_group = {}
				end
			end
		elseif level > 0 then
			table.insert(seg_group, seg)
		else
			table.insert(text_and_specs, seg)
		end
	end
	if level > 0 then
		error("Unmatched " .. open .. " sign: '" .. segment_run .. "'")
	end
	return text_and_specs
end
]=]


--[==[
Like parse_balanced_segment_run() but accepts multiple sets of delimiters. For example,

{parse_multi_delimiter_balanced_segment_run("foo[bar(baz[bat])], quux<glorp>", {{"[", "]"}, {"(", ")"}, {"<", ">"}}) =
	{"foo", "[bar(baz[bat])]", ", quux", "<glorp>", ""}}.

Each element in the list of delimiter pairs is a string specifying an equivalence class of possible delimiter
characters. You can use this, for example, to allow either "[" or "&amp;#91;" to be treated equivalently, with either
one closed by either "]" or "&amp;#93;". To do this, first replace "&amp;#91;" and "&amp;#93;" with single Unicode
characters such as U+FFF0 and U+FFF1, and then specify a two-character string containing "[" and U+FFF0 as the opening
delimiter, and a two-character string containing "]" and U+FFF1 as the corresponding closing delimiter.

If `no_error_on_unmatched` is given and an error is found during parsing, a string is returned containing the error
message instead of throwing an error.
]==]
function export.parse_multi_delimiter_balanced_segment_run(segment_run, delimiter_pairs, no_error_on_unmatched)
	local escaped_delimiter_pairs = {}
	local open_to_close_map = {}
	local open_close_items = {}
	local open_items = {}
	for _, open_close in ipairs(delimiter_pairs) do
		local open, close = unpack(open_close)
		open = rsub(open, "([%[%]%%%%-])", "%%%1")
		close = rsub(close, "([%[%]%%%%-])", "%%%1")
		table.insert(open_close_items, open)
		table.insert(open_close_items, close)
		table.insert(open_items, open)
		open = "[" .. open .. "]"
		close = "[" .. close .. "]"
		open_to_close_map[open] = close
		table.insert(escaped_delimiter_pairs, {open, close})
	end
	local open_close_pattern = "([" .. table.concat(open_close_items) .. "])"
	local open_pattern = "([" .. table.concat(open_items) .. "])"
	local break_on_open_close = m_string_utilities.capturing_split(segment_run, open_close_pattern)
	local text_and_specs = {}
	local level = 0
	local seg_group = {}
	local open_at_level_zero

	for i, seg in ipairs(break_on_open_close) do
		if i % 2 == 0 then
			table.insert(seg_group, seg)
			if level == 0 then
				if not rfind(seg, open_pattern) then
					local errmsg = "Unmatched close sign " .. seg .. ": '" .. segment_run .. "'"
					if no_error_on_unmatched then
						return errmsg
					else
						error(errmsg)
					end
				end
				assert(open_at_level_zero == nil)
				for _, open_close in ipairs(escaped_delimiter_pairs) do
					local open, close = unpack(open_close)
					if rfind(seg, open) then
						open_at_level_zero = open
			            break
					end
				end
				if open_at_level_zero == nil then
					error(("Internal error: Segment %s didn't match any open regex"):format(seg))
				end
				level = level + 1
			elseif rfind(seg, open_at_level_zero) then
				level = level + 1
			elseif rfind(seg, open_to_close_map[open_at_level_zero]) then
				level = level - 1
				assert(level >= 0)
				if level == 0 then
					table.insert(text_and_specs, table.concat(seg_group))
					seg_group = {}
					open_at_level_zero = nil
				end
			end
		elseif level > 0 then
			table.insert(seg_group, seg)
		else
			table.insert(text_and_specs, seg)
		end
	end
	if level > 0 then
		local errmsg = "Unmatched open sign " .. open_at_level_zero .. ": '" .. segment_run .. "'"
		if no_error_on_unmatched then
			return errmsg
		else
			error(errmsg)
		end
	end
	return text_and_specs
end


--[==[
Split a list of alternating textual runs of the format returned by `parse_balanced_segment_run` on `splitchar`. This
only splits the odd-numbered textual runs (the portions between the balanced open/close characters).  The return value
is a list of lists, where each list contains an odd number of elements, where the even-numbered elements of the sublists
are the original balanced textual run portions. For example, if we do

{parse_balanced_segment_run("foo<M.proper noun> bar<F>", "<", ">") =
  {"foo", "<M.proper noun>", " bar", "<F>", ""}}

then

{split_alternating_runs({"foo", "<M.proper noun>", " bar", "<F>", ""}, " ") =
  {{"foo", "<M.proper noun>", ""}, {"bar", "<F>", ""}}}

Note that we did not touch the text "<M.proper noun>" even though it contains a space in it, because it is an
even-numbered element of the input list. This is intentional and allows for embedded separators inside of
brackets/parens/etc. Note also that the inner lists in the return value are of the same form as the input list (i.e.
they consist of alternating textual runs where the even-numbered segments are balanced runs), and can in turn be passed
to split_alternating_runs().

If `preserve_splitchar` is passed in, the split character is included in the output, as follows:

{split_alternating_runs({"foo", "<M.proper noun>", " bar", "<F>", ""}, " ", true) =
  {{"foo", "<M.proper noun>", ""}, {" "}, {"bar", "<F>", ""}}}

Consider what happens if the original string has multiple spaces between brackets, and multiple sets of brackets
without spaces between them.

{parse_balanced_segment_run("foo[dated][low colloquial] baz-bat quux xyzzy[archaic]", "[", "]") =
  {"foo", "[dated]", "", "[low colloquial]", " baz-bat quux xyzzy", "[archaic]", ""}}

then

{split_alternating_runs({"foo", "[dated]", "", "[low colloquial]", " baz-bat quux xyzzy", "[archaic]", ""}, "[ %-]") =
  {{"foo", "[dated]", "", "[low colloquial]", ""}, {"baz"}, {"bat"}, {"quux"}, {"xyzzy", "[archaic]", ""}}}

If `preserve_splitchar` is passed in, the split character is included in the output,
as follows:

{split_alternating_runs({"foo", "[dated]", "", "[low colloquial]", " baz bat quux xyzzy", "[archaic]", ""}, "[ %-]", true) =
  {{"foo", "[dated]", "", "[low colloquial]", ""}, {" "}, {"baz"}, {"-"}, {"bat"}, {" "}, {"quux"}, {" "}, {"xyzzy", "[archaic]", ""}}}

As can be seen, the even-numbered elements in the outer list are one-element lists consisting of the separator text.
]==]
function export.split_alternating_runs(segment_runs, splitchar, preserve_splitchar)
	local grouped_runs = {}
	local run = {}
	for i, seg in ipairs(segment_runs) do
		if i % 2 == 0 then
			table.insert(run, seg)
		else
			local parts =
				preserve_splitchar and m_string_utilities.capturing_split(seg, "(" .. splitchar .. ")") or
				rsplit(seg, splitchar)
			table.insert(run, parts[1])
			for j=2,#parts do
				table.insert(grouped_runs, run)
				run = {parts[j]}
			end
		end
	end
	if #run > 0 then
		table.insert(grouped_runs, run)
	end
	return grouped_runs
end


function export.strip_spaces(text)
	return rsub(text, "^%s*(.-)%s*$", "%1")
end


--[==[
Apply an arbitrary function `frob` to the "raw-text" segments in a split run set (the output of
split_alternating_runs()). We leave alone stuff within balanced delimiters (footnotes, inflection specs and the
like), as well as splitchars themselves if present. `preserve_splitchar` indicates whether splitchars are present
in the split run set. `frob` is a function of one argument (the string to frob) and should return one argument (the
frobbed string). We operate by only frobbing odd-numbered segments, and only in odd-numbered runs if
preserve_splitchar is given.
]==]
function export.frob_raw_text_alternating_runs(split_run_set, frob, preserve_splitchar)
	for i, run in ipairs(split_run_set) do
		if not preserve_splitchar or i % 2 == 1 then
			for j, segment in ipairs(run) do
				if j % 2 == 1 then
					run[j] = frob(segment)
				end
			end
		end
	end
end


--[==[
Like split_alternating_runs() but applies an arbitrary function `frob` to "raw-text" segments in the result (i.e.
not stuff within balanced delimiters such as footnotes and inflection specs, and not splitchars if present). `frob`
is a function of one argument (the string to frob) and should return one argument (the frobbed string).
]==]
function export.split_alternating_runs_and_frob_raw_text(run, splitchar, frob, preserve_splitchar)
	local split_runs = export.split_alternating_runs(run, splitchar, preserve_splitchar)
	export.frob_raw_text_alternating_runs(split_runs, frob, preserve_splitchar)
	return split_runs
end


--[==[
Split the non-modifier parts of an alternating run (after parse_balanced_segment_run() is called) on a Lua pattern,
but not on certain sequences involving characters in that pattern (e.g. comma+whitespace). `splitchar` is the pattern
to split on; `preserve_splitchar` indicates whether to preserve the delimiter and is the same as in
split_alternating_runs(). `escape_fun` is called beforehand on each run of raw text and should return two values:
the escaped run and whether unescaping is needed. If any call to `escape_fun` indicates that unescaping is needed,
`unescape_fun` will be called on each run of raw text after splitting on `splitchar`. The return value of this
function is as in split_alternating_runs().
]==]
function export.split_alternating_runs_escaping(run, splitchar, preserve_splitchar, escape_fun, unescape_fun)
	-- First replace comma with a temporary character in comma+whitespace sequences.
	local need_unescape = false
	for i, seg in ipairs(run) do
		if i % 2 == 1 then
			local this_need_unescape
			run[i], this_need_unescape = escape_fun(run[i])
			need_unescape = need_unescape or this_need_unescape
		end
	end

	if need_unescape then
		return export.split_alternating_runs_and_frob_raw_text(run, splitchar, unescape_fun, preserve_splitchar)
	else
		return export.split_alternating_runs(run, splitchar, preserve_splitchar)
	end
end


--[==[
Replace comma with a temporary char in comma + whitespace.
]==]
function export.escape_comma_whitespace(run, tempcomma)
	tempcomma = tempcomma or u(0xFFF0)
	local escaped = false

	if run:find("\\,") then
		run = run:gsub("\\,", "\\" .. tempcomma) -- assign to temp to discard second return value
		escaped = true
	end
	if run:find(",%s") then
		run = run:gsub(",(%s)", tempcomma .. "%1") -- assign to temp to discard second return value
		escaped = true
	end
	return run, escaped
end


--[==[
Undo the replacement of comma with a temporary char.
]==]
function export.unescape_comma_whitespace(run, tempcomma)
	tempcomma = tempcomma or u(0xFFF0)

	run = run:gsub(tempcomma, ",") -- assign to temp to discard second return value
	return run
end


--[==[
Split the non-modifier parts of an alternating run (after parse_balanced_segment_run() is called) on comma, but not
on comma+whitespace. See `split_on_comma()` above for more information and the meaning of `tempcomma`.
]==]
function export.split_alternating_runs_on_comma(run, tempcomma)
	tempcomma = tempcomma or u(0xFFF0)

	-- Replace comma with a temporary char in comma + whitespace.
	local function escape_comma_whitespace(seg)
		return export.escape_comma_whitespace(seg, tempcomma)
	end

	-- Undo replacement of comma with a temporary char in comma + whitespace.
	local function unescape_comma_whitespace(seg)
		return export.unescape_comma_whitespace(seg, tempcomma)
	end

	return export.split_alternating_runs_escaping(run, ",", false, escape_comma_whitespace, unescape_comma_whitespace)
end


--[==[
Split text on a Lua pattern, but not on certain sequences involving characters in that pattern (e.g.
comma+whitespace). `splitchar` is the pattern to split on; `preserve_splitchar` indicates whether to preserve the
delimiter between split segments. `escape_fun` is called beforehand on the text and should return two values: the
escaped run and whether unescaping is needed. If the call to `escape_fun` indicates that unescaping is needed,
`unescape_fun` will be called on each run of text after splitting on `splitchar`. The return value of this a list
of runs, interspersed with delimiters if `preserve_splitchar` is specified.
]==]
function export.split_escaping(text, splitchar, preserve_splitchar, escape_fun, unescape_fun)
	if not rfind(text, splitchar) then
		return {text}
	end

	-- If there are square or angle brackets, we don't want to split on delimiters inside of them. To effect this, we
	-- use parse_multi_delimiter_balanced_segment_run() to parse balanced brackets, then do delimiter splitting on the
	-- non-bracketed portions of text using split_alternating_runs_escaping(), and concatenate back to a list of
	-- strings. When calling parse_multi_delimiter_balanced_segment_run(), we make sure not to throw an error on
	-- unbalanced brackets; in that case, we fall through to the code below that handles the case without brackets.
	if text:find("[%[<]") then
		local runs = export.parse_multi_delimiter_balanced_segment_run(text, {{"[", "]"}, {"<", ">"}},
			"no error on unmatched")
		if type(runs) ~= "string" then
			local split_runs = export.split_alternating_runs_escaping(runs, splitchar, preserve_splitchar, escape_fun,
				unescape_fun)
			for i = 1, #split_runs, (preserve_splitchar and 2 or 1) do
				split_runs[i] = table.concat(split_runs[i])
			end
			return split_runs
		end
	end

	-- First escape sequences we don't want to count for splitting.
	local need_unescape
	text, need_unescape = escape_fun(text)

	local parts =
		preserve_splitchar and m_string_utilities.capturing_split(text, "(" .. splitchar .. ")") or
		rsplit(text, splitchar)
	if need_unescape then
		for i = 1, #parts, (preserve_splitchar and 2 or 1) do
			parts[i] = unescape_fun(parts[i])
		end
	end
	return parts
end


--[==[
Split text on comma, but not on comma+whitespace. This is similar to `mw.text.split(text, ",")` but will not split
on commas directly followed by whitespace, to handle embedded commas in terms (which are almost always followed by
a space). `tempcomma` is the Unicode character to temporarily use when doing the splitting; normally U+FFF0, but
you can specify a different character if you use U+FFF0 for some internal purpose.
]==]
function export.split_on_comma(text, tempcomma)
	-- Don't do anything if no comma. Note that split_escaping() has a similar check at the beginning, so if there's a
	-- comma we effectively do this check twice, but this is worth it to optimize for the common no-comma case.
	if not text:find(",") then
		return {text}
	end

	tempcomma = tempcomma or u(0xFFF0)

	-- Replace comma with a temporary char in comma + whitespace.
	local function escape_comma_whitespace(run)
		return export.escape_comma_whitespace(run, tempcomma)
	end

	-- Undo replacement of comma with a temporary char in comma + whitespace.
	local function unescape_comma_whitespace(run)
		return export.unescape_comma_whitespace(run, tempcomma)
	end

	return export.split_escaping(text, ",", false, escape_comma_whitespace, unescape_comma_whitespace)
end


--[==[
Ensure that Wikicode (bracketed links, HTML, bold/italics, etc.) displays literally in error messages by inserting
a Unicode word-joiner symbol after all characters that may trigger Wikicode interpr. Replacing with equivalent
HTML escapes doesn't work because they are displayed literally. I could not get this to work using
<nowiki>...</nowiki> (those tags display literally) and using using {{#tag:nowiki|...}} (same thing).
FIXME: This is a massive hack; there must be a better way.
]==]
function export.escape_wikicode(term)
	term = term:gsub("([%[<'])", "%1" .. u(0x2060))
	return term
end


function export.make_parse_err(arg_gloss)
	return function(msg, stack_frames_to_ignore)
		error(export.escape_wikicode(("%s: %s"):format(msg, arg_gloss)), stack_frames_to_ignore)
	end
end


-- Parse a term that may include a link '[[LINK]]' or a two-part link '[[LINK|DISPLAY]]'. FIXME: Doesn't currently
-- handle embedded links like '[[FOO]] [[BAR]]' or [[FOO|BAR]] [[BAZ]]' or '[[FOO]]s'; if they are detected, it returns
-- the term unchanged and `nil` for the display form.
local function parse_bracketed_term(term, parse_err)
	local inside = term:match("^%[%[(.*)%]%]$")
	if inside then
		if inside:find("%[%[") or inside:find("%]%]") then
			-- embedded links, e.g. '[[FOO]] [[BAR]]'; FIXME: we should process them properly
			return term, nil
		end
		local parts = rsplit(inside, "|")
		if #parts > 2 then
			parse_err("Saw more than two parts inside a bracketed link")
		end
		return unpack(parts)
	end
	return term, nil
end


--[==[
Parse a term that may have a language code preceding it (e.g. {la:minūtia} or {grc:[[σκῶρ|σκατός]]}). Return
two arguments, the term minus the language code and the language object corresponding to the language code.
Etymology-only languages are allowed. This function also correctly handles Wikipedia prefixes (e.g. 'w:Abatemarco'
or 'w:it:Colle Val d'Elsa' or 'lw:ru:Филарет') and Wikisource prefixes (e.g. 's:Twelve O'Clock' or
's:[[Walden/Chapter XVIII|Walden]]' or 's:fr:Perceval ou le conte du Graal' or 's:ro:[[Domnul Vucea|Mr. Vucea]]' or
'ls:ko:이상적 부인' or 'ls:ko:[[조선 독립의 서#一. 槪論|조선 독립의 서]]') and converts them into two-part links,
with the display form not including the Wikipedia or Wikisource prefix unless it was explicitly specified using a
two-part link as in 'lw:ru:[[Филарет (Дроздов)|Митрополи́т Филаре́т]]' or
'ls:ko:[[조선 독립의 서#一. 槪論|조선 독립의 서]]'. The difference between 'w:' ("Wikipedia") and 'lw:' ("Wikipedia
link") is that the latter requires a language code and returns the corresponding language object; same for the
difference between 's:' ("Wikisource") and 'ls:' ("Wikisource link"). Returns four objects, `term`, `language_code`,
`link` and `display`, where if a two-part link is given or needs to be generated (as is the case with Wikipedia and
Wikisource prefixes), it is separated into link and display forms (otherwise `link` is the same as `term` and
`display` is nil). (NOTE: Embedded links are not correctly handled currently. If an embedded link is detected, the
whole term is returned as the link part, and the display part is nil. If you construct your own link from the link
and display parts, you must check for this.)

`parse_err_or_paramname` is an optional function of one or two arguments to display an error, or a string naming a
parameter to display in the error message. If omitted, a function is generated based off of `term`. (The second
argument to the function is the number of stack frames to ignore when calling error(); if you declare your error
function with only one argument, things will still work fine).
]==]
function export.parse_term_with_lang(term, parse_err_or_paramname, return_parts)
	local parse_err = type(parse_err_or_paramname) == "function" and parse_err_or_paramname or
		parse_err_or_paramname and export.make_parse_err(("%s=%s"):format(parse_err_or_paramname, term)) or
		export.make_parse_err(term)
	-- Parse off an initial language code (e.g. 'la:minūtia' or 'grc:[[σκῶρ|σκατός]]'). First check for Wikipedia
	-- prefixes ('w:Abatemarco' or 'w:it:Colle Val d'Elsa' or 'lw:zh:邹衡') and Wikisource prefixes
	-- ('s:ro:[[Domnul Vucea|Mr. Vucea]]' or 'ls:ko:이상적 부인'). Wikipedia/Wikisource language codes follow a similar
	-- format to Wiktionary language codes (see below).
	local termlang, foreign_wiki, actual_term = term:match("^(l?[ws]):([a-z][a-z][a-z-]*):([^ ].*)$")
	if not termlang then
		termlang, actual_term = term:match("^([ws]):([^ ].*)$")
	end
	if termlang then
		local wiki_links = termlang:find("^l")
		local base_wiki_prefix = termlang:find("w$") and "w:" or "s:"
		local wiki_prefix = base_wiki_prefix .. (foreign_wiki and foreign_wiki .. ":" or "")
		local link, display = parse_bracketed_term(actual_term, parse_err)
		if link:find("%[%[") or display and display:find("%[%[") then
			-- FIXME, this should be handlable with the right parsing code
			parse_err("Cannot have embedded brackets following a Wikipedia (w:... or lw:...) link; expand the term to a fully bracketed term w:[[LINK|DISPLAY]] or similar")
		end
		local lang = wiki_links and require("languages").getByCode(foreign_wiki, parse_err, "allow etym") or nil
		local prefixed_link = wiki_prefix .. link
		return ("[[%s|%s]]"):format(prefixed_link, display or link), lang, prefixed_link, display
	end

	-- Wiktionary language codes are in one of the following formats, where 'x' is a lowercase letter and 'X' an uppercase
	-- letter:
	-- xx
	-- xxx
	-- xxx-xxx
	-- xxx-xxx-xxx
	-- xx-xxx (for etymology-only languages)
	-- xx-xxx-xxx (maybe? for etymology-only languages)
	-- xx-XX (for etymology-only languages, where XX is a country code, e.g. en-US)
	-- xxx-XX (for etymology-only languages, where XX is a country code)
	--
	-- We check for these formats as well as nonstandard Latin etymology language codes (e.g. VL. or LL.). (There used to
	-- be more nonstandard codes but they have all been eliminated.)
	termlang, actual_term = term:match("^([a-z][a-z][a-z]?):([^ ].*)$")
	if not termlang then
		termlang, actual_term = term:match("^([a-z][a-z][a-z]?%-[A-Z][A-Z]):([^ ].*)$")
	end
	if not termlang then
		termlang, actual_term = term:match("^([a-z][a-z][a-z]?%-[a-z][a-z][a-z]):([^ ].*)$")
	end
	if not termlang then
		termlang, actual_term = term:match("^([a-z][a-z][a-z]?%-[a-z][a-z][a-z]%-[a-z][a-z][a-z]):([^ ].*)$")
	end
	if not termlang then
		-- Special hack for Latin variants, which can have nonstandard etym codes, e.g. VL., LL.
		termlang, actual_term = term:match("^([A-Z]L%.):([^ ].*)$")
	end
	if termlang then
		termlang = require("languages").getByCode(termlang, parse_err, "allow etym")
		term = actual_term
	end
	local link, display = parse_bracketed_term(term, parse_err)
	return term, termlang, link, display
end


--[==[
Parse a term that may have inline modifiers attached (e.g. {rifiuti<q:plural-only>} or
{rinfusa<t:bulk cargo><lit:resupplying><qq:more common in the plural {{m|it|rinfuse}}>}).
* `arg` is the term to parse.
* `props` is an object holding further properties controlling how to parse the term (only `param_mods` and
  `generate_obj` are required):
** `paramname` is the name of the parameter where `arg` comes from, or nil if this isn't available (it is used only in
   error messages).
** `param_mods` is a table describing the allowed inline modifiers (see below).
** `generate_obj` is a function of one or two arguments that should parse the argument minus the inline modifiers and
   return a corresponding parsed object (into which the inline modifiers will be rewritten). If declared with one
   argument, that will be the raw value to parse; if declared with two arguments, the second argument will be the
   `parse_err` function (see below).
** `parse_err` is an optional function of one argument (an error message) and should display the error message, along
   with any desired contextual text (e.g. the argument name and value that triggered the error). If omitted, a default
   function will be generated which displays the error along with the original value of `arg` (passed through
   {escape_wikicode()} above to ensure that Wikicode (such as links) is displayed literally).
** `splitchar` is a Lua pattern. If specified, `arg` can consist of multiple delimiter-separated terms, each of which
   may be followed by inline modifiers, and the return value will be a list of parsed objects instead of a single
   object. Note that splitting on delimiters will not happen in certain protected sequences (by default
   comma+whitespace; see below). The algorithm to split on delimiters is sensitive to inline modifier syntax and will
   not be confused by delimiters inside of inline modifiers, which do not trigger splitting (whether or not contained
   within protected sequences).
** `outer_container`, if specified, is used when multiple delimiter-separated terms are possible, and is the object
   into which the list of per-term objects is stored (into the `terms` field) and into which any modifiers that are
   given the `overall` property (see below) will be stored. If given, this value will be returned as the value of
   {parse_inline_modifiers()}. If `outer_container` is not given, {parse_inline_modifiers()} will return the list of
   per-term objects directly, and no modifier may have an `overall` property.
** `preserve_splitchar`, if specified, causes the actual delimiter matched by `splitchar` to be returned in the
   parsed object describing the element that comes after the delimiter. The delimiter is stored in a key whose
   name is controlled by `separator_key`, which defaults to "separator".
** `separator_key` controls the key into which the actual delimiter is written when `preserve_splitchar` is used.
   See above.
** `escape_fun` and `unescape_fun` are as in split_escaping() and split_alternating_runs_escaping() above and
   control the protected sequences that won't be split. By default, `escape_comma_whitespace` and
   `unescape_comma_whitespace` are used, so that comma+whitespace sequences won't be split.

`param_mods` is a table describing allowed modifiers. The keys of the table are modifier prefixes and the values are
tables describing how to parse and store the associated modifier values. Here is a typical example:

<pre>
local param_mods = {
	t = {
		item_dest = "gloss",
	},
	gloss = {},
	pos = {},
	alt = {},
	lit = {},
	id = {},
	g = {
		item_dest = "genders",
		convert = function(arg)
			return rsplit(arg, ",")
		end,
	},
}
</pre>

In the table values:
* `item_dest` specifies the destination key to store the object into (if not the same as the modifier key itself).
* `convert` is a function of one or two arguments (the modifier value and optionally the {parse_err} function as passed
  in or generated), and should parse and convert the value into the appropriate object. If omitted, the string value is
  stored unchanged.
* `store` describes how to store the converted modifier value into the parsed object. If omitted, the converted value
  is simply written into the parsed object under the appropriate key; but an error is generated if the key already has
  a value. (This means that multiple occurrences of a given modifier are allowed if `store` is given, but not
  otherwise.) `store` can be one of the following:
** {"insert"}: the converted value is appended to the key's value using {table.insert()}; if the key has no value, it
   is first converted to an empty list;
** {"insertIfNot"}: is similar but appends the value using {insertIfNot()} in [[Module:table]];
** {"insert-flattened"}, the converted value is assumed to be a list and the objects are appended one-by-one into the
   key's existing value using {table.insert()};
** {"insertIfNot-flattened"} is similar but appends using {insertIfNot()} in [[Module:table]]; (WARNING: When using
   {"insert-flattened"} and {"insertIfNot-flattened"}, if there is no existing value for the key, the converted value is
   just stored directly. This means that future appends will side-effect that value, so make sure that the return value
   of the conversion function for this key generates a fresh list each time.)
** a function of one argument, an object with the following properties:
*** `dest`: the object to write the value into;
*** `key`: the field where the value should be written;
*** `converted`: the (converted) value to write;
*** `raw_val`: the raw, user-specified value (a string);
*** `parse_err`: a function of one argument (an error string), which signals an error, and includes extra context in
    the message about the modifier in question, the angle-bracket spec that includes the modifier in it, the overall
	value, and (if `paramname` was given) the parameter holding the overall value.
* `overall` only applies if `splitchar` is given. In this case, the modifier applies to the entire argument rather than
   to an individual term in the argument, and must occur after the last item separated by `splitchar`, instead of being
   allowed to occur after any of them. The modifier will be stored into the outer container object, which must exist
   (i.e. `outer_container` must have been given).

The return value of {parse_inline_modifiers()} depends on whether `splitchar` and `outer_container` have been given. If
neither is given, the return value is the object returned by `generate_obj`. If `splitchar` but not `outer_container` is
given, the return value is a list of per-term objects, each of which is generated by `generate_obj`. If both `splitchar`
and `outer_container` are given, the return value is the value of `outer_container` and the per-term objects are stored
into the `terms` field of this object.
]==]
function export.parse_inline_modifiers(arg, props)
	local segments = export.parse_balanced_segment_run(arg, "<", ">")

	local function verify_no_overall()
		for mod, mod_props in pairs(props.param_mods) do
			if mod_props.overall then
				error("Internal caller error: Can't specify `overall` for a modifier in `param_mods` unless `outer_container` property is given")
			end
		end
	end

	if not props.splitchar then
		if props.outer_container then
			error("Internal caller error: Can't specify `outer_container` property unless `splitchar` is given")
		end
		verify_no_overall()
		return export.parse_inline_modifiers_from_segments {
			group = segments,
			group_index = nil,
			separated_groups = nil,
			arg = arg,
			props = props
		}
	else
		local terms = {}
		if props.outer_container then
			props.outer_container.terms = terms
		else
			verify_no_overall()
		end
		local separated_groups = export.split_alternating_runs_escaping(segments, props.splitchar,
			props.preserve_splitchar, props.escape_fun or export.escape_comma_whitespace,
			props.unescape_fun or export.unescape_comma_whitespace)
		for j = 1, #separated_groups, (props.preserve_splitchar and 2 or 1) do
			local parsed = export.parse_inline_modifiers_from_segments {
				group = separated_groups[j],
				group_index = j,
				separated_groups = separated_groups,
				arg = arg,
				props = props
			}
			if props.preserve_splitchar and j > 1 then
				parsed[props.separator_key or "separator"] = separated_groups[j - 1][1]
			end
			table.insert(terms, parsed)
		end
		if props.outer_container then
			return props.outer_container
		else
			return terms
		end
	end
end


--[==[
Parse a single term that may have inline modifiers attached. This is a helper function of {parse_inline_modifiers()} but
is exported separately in case the caller needs to make their own call to {parse_balanced_segment_run()} (as in
[[Module:quote]], which splits on several matched delimiters simultaneously). It takes only a single argument, `data`,
which is an object with the following fields:
* `group`: A list of segments as output by {parse_balanced_segment_run()} (see the overall comment at the top of
  [[Module:parse utilities]]), or one of the lists returned by calling {split_alternating_runs()}.
* `separated_groups`: The list of groups (each of which is of the form of `group`) describing all the terms in the
  argument parsed by {parse_inline_modifiers()}, or {nil} if this isn't applicable (i.e. multiple terms aren't allowed
  in the argument).
* `group_index`: The index into `separated_groups` where `group` can be found, or {nil} if not applicable.
* `arg`: The original user-specified argument being parsed; used only for error messages.
* `props`: The `props` argument to {parse_inline_modifiers()}.

The return value is the object created by `generate_obj`, with properties filled in describing the modifiers of the
term in question.
]==]
function export.parse_inline_modifiers_from_segments(data)
	local props = data.props
	local group = data.group
	local function get_valid_prefixes()
		local valid_prefixes = {}
		for param_mod, _ in pairs(props.param_mods) do
			table.insert(valid_prefixes, param_mod)
		end
		table.sort(valid_prefixes)
		return valid_prefixes
	end

	local function get_arg_gloss()
		if props.paramname then
			return ("%s=%s"):format(props.paramname, data.arg)
		else
			return data.arg
		end
	end

	local parse_err = props.parse_err or export.make_parse_err(get_arg_gloss())
	local term_obj = props.generate_obj(group[1], parse_err)
	for k = 2, #group - 1, 2 do
		if group[k + 1] ~= "" then
			parse_err("Extraneous text '" .. group[k + 1] .. "' after modifier")
		end
		local modtext = group[k]:match("^<(.*)>$")
		if not modtext then
			parse_err("Internal error: Modifier '" .. group[k] .. "' isn't surrounded by angle brackets")
		end
		local prefix, val = modtext:match("^([a-zA-Z0-9+_-]+):(.*)$")
		if not prefix then
			local valid_prefixes = get_valid_prefixes()
			for i, valid_prefix in ipairs(valid_prefixes) do
				valid_prefixes[i] = "'" .. valid_prefix .. ":'"
			end
			parse_err("Modifier " .. group[k] .. " lacks a prefix, should begin with one of " ..
				require("table").serialCommaJoin(valid_prefixes, {dontTag = true}))
		end
		local prefix_parse_err =
			export.make_parse_err(("modifier prefix '%s' in %s in %s"):format(prefix, group[k], get_arg_gloss()))
		if props.param_mods[prefix] then
			local mod_props = props.param_mods[prefix]
			local key = mod_props.item_dest or prefix
			local convert = mod_props.convert
			local dest
			if mod_props.overall then
				if not data.separated_groups then
					prefix_parse_err("Internal error: `data.separated_groups` not given when `overall` is seen")
				end
				if not props.outer_container then
					-- This should have been caught earlier during validation in parse_inline_modifiers().
					prefix_parse_err("Internal error: `props.outer_container` not given when `overall` is seen")
				end
				if data.group_index ~= #data.separated_groups then
					prefix_parse_err("Prefix should occur after the last comma-separated term")
				end
				dest = props.outer_container
			else
				dest = term_obj
			end

			local converted
			if convert then
				converted = convert(val, prefix_parse_err)
			else
				converted = val
			end
			local store = props.param_mods[prefix].store
			if not store then
				if dest[key] then
					prefix_parse_err("Prefix occurs twice")
				end
				dest[key] = converted
			elseif store == "insert" then
				if not dest[key] then
					dest[key] = {converted}
				else
					table.insert(dest[key], converted)
				end
			elseif store == "insertIfNot" then
				if not dest[key] then
					dest[key] = {converted}
				else
					require("table").insertIfNot(dest[key], converted)
				end
			elseif store == "insert-flattened" then
				if not dest[key] then
					dest[key] = obj
				else
					for _, obj in ipairs(converted) do
						table.insert(dest[key], obj)
					end
				end
			elseif store == "insertIfNot-flattened" then
				if not dest[key] then
					dest[key] = obj
				else
					for _, obj in ipairs(converted) do
						require("table").insertIfNot(dest[key], obj)
					end
				end
			elseif type(store) == "string" then
				prefix_parse_err(("Internal caller error: Unrecognized value '%s' for `store` property"):format(store))
			elseif type(store) ~= "function" then
				prefix_parse_err(("Internal caller error: Unrecognized type for `store` property %s"):format(
					mw.dumpObject(store)))
			else
				store {
					dest = dest,
					key = key,
					converted = converted,
					raw = val,
					parse_err = prefix_parse_err
				}
			end
		else
			local valid_prefixes = get_valid_prefixes()
			for i, valid_prefix in ipairs(valid_prefixes) do
				valid_prefixes[i] = "'" .. valid_prefix .. "'"
			end
			prefix_parse_err("Unrecognized prefix, should be one of " ..
				require("table").serialCommaJoin(valid_prefixes, {dontTag = true}))
		end
	end
	return term_obj
end


return export