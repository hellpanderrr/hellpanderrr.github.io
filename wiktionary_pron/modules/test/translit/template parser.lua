--[[
NOTE: This module works by using recursive backtracking to build a node tree, which can then be traversed as necessary.

Because it is called by a number of high-use modules, it has been optimised for speed using a profiler, since it is used to scrape data from large numbers of pages very quickly. To that end, it rolls some of its own methods in cases where this is faster than using a function from one of the standard libraries. Please DO NOT "simplify" the code by removing these, since you are almost guaranteed to slow things down, which could seriously impact performance on pages which call this module hundreds or thousands of times.

It has also been designed to emulate the native parser's behaviour as much as possible, which in some cases means replicating bugs or unintuitive behaviours in that code; these should not be "fixed", since it is important that the outputs are the same. Most of these originate from deficient regular expressions, which can't be used here, so the bugs have to be manually reintroduced as special cases (e.g. onlyinclude tags being case-sensitive and whitespace intolerant, unlike all other tags). If any of these are fixed, this module should also be updated accordingly.
]]

local concat = table.concat
local gmatch = string.gmatch
local insert = table.insert
local lower = string.lower
local match = string.match
local new_title = mw.title.new
local rawset = rawset
local select = select
local sub = string.sub
local tonumber = tonumber
local tostring = tostring
local type = type
local ulower = string.ulower
local uupper = string.uupper

local m_parser = require("parser")
local data = mw.loadData("template parser/data")
local frame = mw.getCurrentFrame()

local export = {}

------------------------------------------------------------------------------------
--
-- Utilities
--
------------------------------------------------------------------------------------

-- Table lookup is much faster than match. \v and \f are excluded as the parser treats them as invalid. \r can't appear in page content (as the parser normalizes newlines to \n), but it might be needed in some niche cases.
local ascii_spaces = {
	[" "] = true,
	["\t"] = true,
	["\n"] = true,
	["\r"] = true
}

-- Trims ASCII spacing characters.
-- Note: loops + sub make this much faster than the equivalent string patterns.
local function trim(str)
	local n
	for i = 1, #str do
		if not ascii_spaces[sub(str, i, i)] then
			n = i
			break
		end
	end
	if not n then
		return ""
	end
	for i = #str, n, -1 do
		if not ascii_spaces[sub(str, i, i)] then
			return sub(str, n, i)
		end
	end
end

------------------------------------------------------------------------------------
--
-- Nodes
--
------------------------------------------------------------------------------------

local Node = m_parser.Node
local Wikitext = m_parser.Wikitext

local Tag = Node:new("tag")

function Tag:__tostring()
	local open_tag = {"<", self.name}
	if self.ignored then
		return ""
	elseif self.attributes then
		for attr, value in pairs(self.attributes) do
			insert(open_tag, " " .. attr .. "=\"" .. value .. "\"")
		end
	end
	if self.self_closing then
		insert(open_tag, "/>")
		return concat(open_tag)
	end
	insert(open_tag, ">")
	return concat(open_tag) .. concat(self) .. "</" .. self.name .. ">"
end

local Argument = Node:new("argument")

function Argument:__tostring()
	if self[2] then
		local output, i = {"{{{", tostring(self[1])}, 2
		while self[i] do
			insert(output, "|")
			insert(output, tostring(self[i]))
			i = i + 1
		end
		insert(output, "}}}")
		return concat(output)
	elseif self[1] then
		return "{{{" .. tostring(self[1]) .. "}}}"
	else
		return "argument"
	end
end

function Argument:next(i)
	i = i + 1
	if i <= 2 then
		return self[i], self, i
	end
end

local Parameter = Node:new("parameter")

function Parameter:__tostring()
	if self.key then
		return tostring(self.key) .. "=" .. Node.__tostring(self)
	end
	return Node.__tostring(self)
end

local Template = Node:new("template")

function Template:__tostring()
	if self[2] then
		local output, n = {"{{", tostring(self[1])}, 2
		if self.colon then
			insert(output, ":")
			insert(output, tostring(self[3]))
			n = 3
		end
		for i = n, #self do
			insert(output, "|")
			insert(output, tostring(self[i]))
		end
		insert(output, "}}")
		return concat(output)
	elseif self[1] then
		return "{{" .. tostring(self[1]) .. "}}"
	else
		return "template"
	end
end

-- Explicit parameter keys are converted to numbers if:
-- (a) They are integers, with no decimals (2.0) or leading zeroes (02).
-- (b) They are <= 2^53 and >= -2^53.
-- Note: Lua integers are only accurate to 2^53 - 1, so 2^53 and -2^53 have to be specifically checked for since Lua will evaluate 2^53 as equal to 2^53 + 1.
-- Explicit parameters are trimmed (key and value), but implicit parameters are not.
function Template:get_params()
	local params, implicit = {}, 0
	for i = 2, self.len do
		local param = self[i]
		local key, value = param.key
		if key then
			key = trim(tostring(key))
			if match(key, "^-?[1-9]%d*$") or key == "0" then
				local num = tonumber(key)
				key = (
					num <= 9007199254740991 and num >= -9007199254740991 or
					key == "9007199254740992" or
					key == "-9007199254740992"
				) and num or key
			end
			value = trim(Node.__tostring(param))
		else
			implicit = implicit + 1
			key = implicit
			value = tostring(param)
		end
		params[key] = value
	end
	return params
end

function Template:get_array_params()
	local params = {}
	for i = 2, self.len do
		local key = self[i].key
		if key then
			params[i - 1] = tostring(key) .. "=" .. Node.__tostring(self[i])
		else
			params[i - 1] = Node.__tostring(self[i])
		end
	end
	return params
end

------------------------------------------------------------------------------------
--
-- Parser
--
------------------------------------------------------------------------------------

local Parser = m_parser.Parser

-- Extension to the `new` method which also sets raw_head.
do
	local _new = Parser.new
	function Parser:new(text)
		local parser = _new(self, text)
		parser.raw_head = 1
		return parser
	end
end

-- Modified `advance` method which keeps track of raw_head.
function Parser:advance(n)
	local head = self.head
	if not n or n == 1 then
		self.raw_head = self.raw_head + (self.raw_lens[head] or 0)
		self.head = head + 1
	elseif n > 1 then
		for _ = 1, n do
			self.raw_head = self.raw_head + (self.raw_lens[head] or 0)
			head = head + 1
		end
		self.head = head
	else
		for _ = 1, -n do
			head = head - 1
			self.raw_head = self.raw_head - (self.raw_lens[head] or 0)
		end
		self.head = head
	end
end

-- Extension to the `get` method which also resets raw_head if a bad route is returned.
do
	local get = Parser.get
	
	function Parser:get(route, ...)
		local raw_head = self.raw_head
		local layer = get(self, route, ...)
		if layer == self.n.bad_route then
			self.raw_head = raw_head
		end
		return layer
	end
end

-- Argument.
-- First value is the argument name.
-- Second value is the argument's default value.
-- Any additional values are ignored: "{{{a|b|c}}}" is argument "a" with default value "b" (*not* "b|c").
do
	local function handle_argument(self, this)
		if this == "|" then
			self:emit(Wikitext:new(self:pop_sublayer()))
			self:push_sublayer()
		elseif this == "}" and self:read(1) == "}" then
			if self:read(2) == "}" then
				self:emit(Wikitext:new(self:pop_sublayer()))
				self:advance(2)
				return self:pop()
			end
			return self:fail_route()
		elseif this == "" then
			return self:fail_route()
		else
			return self:block_handler(this)
		end
	end
	
	function Parser:do_argument()
		rawset(self.n, "handler", handle_argument)
		self:push_sublayer()
	end

	function Parser:argument()
		local argument = self:get("do_argument")
		if argument == self.n.bad_route then
			self:template()
		else
			self:emit_template_or_argument(argument, Argument, 3)
		end
	end
end

-- Template.
do
	local handle_name
	local handle_parameter
	
	function handle_name(self, this)
		if this == "|" then
			self:emit(Wikitext:new(self:pop_sublayer()))
			self.n.handler = handle_parameter
			self:push_sublayer()
		elseif this == "}" and self:read(1) == "}" then
			self:emit(Wikitext:new(self:pop_sublayer()))
			self:advance()
			return self:pop()
		elseif this == "" then
			return self:fail_route()
		else
			return self:block_handler(this)
		end
	end
	
	function handle_parameter(self, this)
		if this == "=" and not self.n.key and (
			self:read(1) ~= "=" or
			self:read(-1) ~= "\n" and self:read(-1) ~= ""
		) then
			local key = self:pop_sublayer()
			self:push_sublayer()
			rawset(self.n, "key", Wikitext:new(key))
		elseif this == "|" then
			self:emit(Parameter:new(self:pop_sublayer()))
			self:push_sublayer()
		elseif this == "}" and self:read(1) == "}" then
			self:emit(Parameter:new(self:pop_sublayer()))
			self:advance()
			return self:pop()
		elseif this == "" then
			return self:fail_route()
		else
			return self:block_handler(this)
		end
	end
	
	function Parser:do_template()
		rawset(self.n, "handler", handle_name)
		self:push_sublayer()
	end
	
	function Parser:template()
		local template = self:get("do_template")
		if template == self.n.bad_route then
			self:advance(-1)
			for _ = 1, self.n.braces do
				self:emit(self.n.emit_pos, "{")
			end
			self.n.braces = 0
		else
			self:emit_template_or_argument(template, Template, 2)
		end
	end
	
	function Parser:emit_template_or_argument(node, node_type, n)
		if self.n.len == self.n.emit_pos then
			local inner = self:remove()
			if type(node[1]) == "table" then
				insert(node[1], 1, inner)
			else
				node[1] = Wikitext:new{inner, node[1]}
			end
		end
		self.n.braces = self.n.braces - n
		self.n.brace_head = self.n.brace_head - n
		node.pos = self.n.brace_head
		node.raw = sub(self.str, node.pos, self.raw_head)
		self:emit(node_type:new(node))
	end
	
	function Parser:template_or_argument()
		self:advance(2)
		self.n.braces = 2
		while self:read() == "{" do
			self:advance()
			self.n.braces = self.n.braces + 1
		end
		self.n.emit_pos = self.n.len + 1
		self.n.brace_head = self.raw_head
		repeat
			if self.n.braces == 1 then
				self:emit(self.n.emit_pos, "{")
				break
			elseif self.n.braces == 2 then
				self:template()
			else
				self:argument()
			end
			self:advance()
		until self.n.braces == 0
		self:advance(-1)
	end
end

-- Text not in <onlyinclude></onlyinclude>.
function Parser:not_onlyinclude()
	local this, nxt, nxt2 = self:read(), self:read(1), self:read(2)
	while not (
		this == "" or
		this == "<" and nxt == "onlyinclude" and nxt2 == ">"
	) do
		self:advance()
		this, nxt, nxt2 = nxt, nxt2, self:read(2)
	end
	self:advance(2)
end

-- Tag.
do
	local function is_ignored_tag(self, check)
		return self.transcluded and check == "includeonly" or
			not self.transcluded and (
				check == "noinclude" or
				check == "onlyinclude"
			)
	end
	
	-- Handlers.
	local handle_start
	local handle_ignored_tag_start
	local handle_ignored_tag
	local handle_after_tag_name
	local handle_before_attribute_name
	local handle_attribute_name
	local handle_before_attribute_value
	local handle_quoted_attribute_value
	local handle_unquoted_attribute_value
	local handle_after_attribute_value
	local handle_tag_block
	local handle_end
	
	function handle_start(self, this)
		if this == "/" then
			local check = lower(self:read(1))
			if is_ignored_tag(self, check) then
				self.n.name = check
				self.n.ignored = true
				self:advance()
				self.n.handler = handle_ignored_tag_start
				return
			end
			return self:fail_route()
		end
		local check = lower(this)
		if is_ignored_tag(self, check) then
			self.n.name = check
			self.n.ignored = true
			self.n.handler = handle_ignored_tag_start
		elseif (
			check == "noinclude" and self.transcluded or
			check == "includeonly" and not self.transcluded
		) then
			self.n.name = check
			self.n.ignored = true
			self.n.handler = handle_after_tag_name
		elseif data.tags[check] then
			self.n.name = check
			self.n.handler = handle_after_tag_name
		else
			return self:fail_route()
		end
	end
	
	function handle_ignored_tag_start(self, this)
		if this == ">" then
			return self:pop()
		elseif this == "/" and self:read(1) == ">" then
			self.n.self_closing = true
			self:advance()
			return self:pop()
		elseif ascii_spaces[this] then
			self.n.handler = handle_ignored_tag
		else
			return self:fail_route()
		end
	end
	
	function handle_ignored_tag(self, this)
		if this == ">" then
			return self:pop()
		elseif this == "" then
			return self:fail_route()
		end
	end
	
	function handle_after_tag_name(self, this)
		if this == "/" and self:read(1) == ">" then
			self.n.self_closing = true
			self:advance()
			return self:pop()
		elseif this == ">" then
			self.n.handler = handle_tag_block
		elseif ascii_spaces[this] then
			self.n.handler = handle_before_attribute_name
		else
			return self:fail_route()
		end
	end
	
	function handle_before_attribute_name(self, this)
		if this == "/" and self:read(1) == ">" then
			self.n.self_closing = true
			self:advance()
			return self:pop()
		elseif this == ">" then
			self.n.handler = handle_tag_block
		elseif this ~= "/" and not ascii_spaces[this] then
			self:push_sublayer(handle_attribute_name)
			return self:consume()
		elseif this == "" then
			return self:fail_route()
		end
	end
	
	function handle_attribute_name(self, this)
		if this == "/" or this == ">" or ascii_spaces[this] then
			self:pop_sublayer()
			return self:consume()
		elseif this == "=" then
			-- Can't do `self.n.attr_name = ulower(concat(self:pop_sublayer()))` or Lua will take self.n to be the layer being popped.
			local attr_name = ulower(concat(self:pop_sublayer()))
			self.n.attr_name = attr_name
			self.n.handler = handle_before_attribute_value
		elseif this == "" then
			return self:fail_route()
		else
			self:emit(this)
		end
	end
	
	function handle_before_attribute_value(self, this)
		if this == "/" or this == ">" then
			handle_after_attribute_value(self, "")
			return self:consume()
		elseif ascii_spaces[this] then
			handle_after_attribute_value(self, "")
		elseif this == "\"" or this == "'" then
			self:push_sublayer(handle_quoted_attribute_value)
			rawset(self.n, "quoter", this)
		elseif this == "" then
			return self:fail_route()
		else
			self:push_sublayer(handle_unquoted_attribute_value)
			return self:consume()
		end
	end
	
	function handle_quoted_attribute_value(self, this)
		if this == ">" then
			handle_after_attribute_value(self, concat(self:pop_sublayer()))
			return self:consume()
		elseif this == self.n.quoter then
			handle_after_attribute_value(self, concat(self:pop_sublayer()))
		elseif this == "" then
			return self:fail_route()
		else
			self:emit(this)
		end
	end
			
	function handle_unquoted_attribute_value(self, this)
		if this == "/" or this == ">" then
			handle_after_attribute_value(self, concat(self:pop_sublayer()))
			return self:consume()
		elseif ascii_spaces[this] then
			handle_after_attribute_value(self, concat(self:pop_sublayer()))
		elseif this == "" then
			return self:fail_route()
		else
			self:emit(this)
		end
	end
	
	function handle_after_attribute_value(self, attr_value)
		self.n.attributes = self.n.attributes or {}
		self.n.attributes[self.n.attr_name] = attr_value
		self.n.attr_name = nil
		self.n.handler = handle_before_attribute_name
	end
	
	function handle_tag_block(self, this)
		if (
			this == "<" and
			self:read(1) == "/" and
			lower(self:read(2)) == self.n.name
		) then
			local tag_end = self:get("do_tag_end")
			if tag_end == self.n.bad_route then
				self:emit("<")
			else
				return self:pop()
			end
		elseif this == "" then
			return self:fail_route()
		else
			self:emit(this)
		end
	end
	
	function handle_end(self, this)
		if this == ">" then
			return self:pop()
		elseif not ascii_spaces[this] then
			return self:fail_route()
		end
	end
	
	function Parser:do_tag()
		rawset(self.n, "handler", handle_start)
		self:advance()
	end
	
	function Parser:do_tag_end()
		rawset(self.n, "handler", handle_end)
		self:advance(3)
	end
	
	function Parser:tag()
		local tag = self:get("do_tag")
		if tag == self.n.bad_route then
			self:emit("<")
		else
			self:emit(Tag:new(tag))
		end
	end
end

-- Block handlers.

-- These are blocks which can affect template/argument parsing, since they're also parsed by Parsoid at the same time (even though they aren't processed until later).

-- All blocks (including templates/arguments) can nest inside each other, but an inner block must be closed before the outer block which contains it. This is why, for example, the wikitext "{{template| [[ }}" will result in an unprocessed template, since the inner "[[" is treated as the opening of a wikilink block, which prevents "}}" from being treated as the closure of the template block. On the other hand, "{{template| [[ ]] }}" will process correctly, since the wikilink block is closed before the template closure. It makes no difference whether the block will be treated as valid or not when it's processed later on, so "{{template| [[ }} ]] }}" would also work, even though "[[ }} ]]" is not a valid wikilink.

-- Note that nesting also affects pipes and equals signs, in addition to block closures.

-- These blocks can be nested to any degree, so "{{template| [[ [[ [[ ]] }}" will not work, since only one of the three wikilink blocks has been closed. On the other hand, "{{template| [[ [[ [[ ]] ]] ]] }}" will work.

-- All blocks are implicitly closed by the end of the text, since their validity is irrelevant at this stage.
do
	-- Headings
	-- Opens with "\n=" (or "=" at the start of the text), and closes with "\n" or the end of the text. Note that it doesn't matter whether the heading will fail to process due to a premature newline (e.g. if there are no closing signs), so at this stage the only thing that matters for closure is the newline or end of text.
	-- Note: if directly inside a template parameter with no previous equals signs, a newline followed by a single equals sign is parsed as a parameter equals sign, not the opening of a new L1 heading block. This does not apply to any other heading levels. As such, {{template|parameter\n=}}, {{template|key\n=value}} or even {{template|\n=}} will successfully close, but {{template|parameter\n==}}, {{template|key=value\n=more value}}, {{template\n=}} etc. will not, since in the latter cases the "}}" would fall inside the new heading block.
	local function handle_heading_block(self, this)
		if this == "\n" then
			self:emit("\n")
			return self:pop()
		else
			return self:block_handler(this)
		end
	end
	
	-- Language conversion block.
	-- Opens with "-{" and closes with "}-". However, templates/arguments take priority, so "-{{" is parsed as "-" followed by the opening of a template/argument block (depending on what comes after).
	-- Note: Language conversion blocks aren't actually enabled on the English Wiktionary, but Parsoid still parses them at this stage, so they can affect the closure of outer blocks: e.g. "[[ -{ ]]" is not a valid wikilink block, since the "]]" falls inside the new language conversion block.
	local function handle_language_conversion_block(self, this)
		if this == "}" and self:read(1) == "-" then
			self:advance()
			self:emit("}")
			self:emit("-")
			return self:pop()
		else
			return self:block_handler(this)
		end
	end
	
	-- Wikilink block.
	-- Opens with "[[" and closes with "]]".
	local function handle_wikilink_block(self, this)
		if this == "]" and self:read(1) == "]" then
			self:advance()
			self:emit("]")
			self:emit("]")
			return self:pop()
		else
			return self:block_handler(this)
		end
	end
	
	function Parser:do_block(handler)
		rawset(self.n, "handler", handler)
	end
	
	function Parser:block_handler(this)
		if this == "-" and self:read(1) == "{" then
			self:advance()
			self:emit("-")
			if self:read(1) == "{" then
				self:template_or_argument()
			else
				self:emit_tokens(self:get("do_block", handle_language_conversion_block))
			end
		elseif this == "=" and (
			self:read(-1) == "\n" or
			self:read(-1) == ""
		) then
			self:advance()
			self:emit("=")
			self:emit_tokens(self:get("do_block", handle_heading_block))
		elseif this == "[" and self:read(1) == "[" then
			self:advance()
			self:emit("[")
			self:emit_tokens(self:get("do_block", handle_wikilink_block))
		else
			return self:main_handler(this)
		end
	end
end

function Parser:main_handler(this)
	if this == "<" then
		 if (
			self:read(1) == "!" and
			self:read(2) == "-" and
			self:read(3) == "-"
		 ) then
			self:advance(4)
			local this, nxt, nxt2 = self:read(), self:read(1), self:read(2)
			while not (
				this == "" or
				this == "-" and nxt == "-" and nxt2 == ">"
			) do
				self:advance()
				this, nxt, nxt2 = nxt, nxt2, self:read(2)
			end
			self:advance(2)
		 elseif (
		 	self.onlyinclude and
		 	self:read(1) == "/" and
		 	self:read(2) == "onlyinclude" and
		 	self:read(3) == ">"
		) then
			self:advance(4)
			self:not_onlyinclude()
		else
			self:tag()
		end
	elseif this == "{" and self:read(1) == "{" then
		self:template_or_argument()
	elseif this == "" then
		return self:pop()
	else
		self:emit(this)
	end
end

do
	-- If `transcluded` is true, then the text is checked for a pair of onlyinclude tags. If these are found (even if they're in the wrong order), then the start of the page is treated as though it is preceded by a closing onlyinclude tag.
	-- Note that onlyinclude tags *can* be implicitly closed by the end of the text, but the hard requirement above means this can only happen if either the tags are in the wrong order or there are multiple onlyinclude blocks.
	function Parser:do_parse(raw_lens, str, transcluded, title)
		self.str = str
		self.raw_lens = raw_lens
		self.title = title
		if transcluded then
			self.transcluded = true
			if match(str, "<onlyinclude>") and match(str, "</onlyinclude>") then
				self.onlyinclude = true
				self:not_onlyinclude()
				self:advance()
			end
		end
		rawset(self.n, "handler", self.main_handler)
	end
	
	local function get(this)
		return this, #this
	end
	
	function export.parse(str, transcluded, title)
		local text, raw_lens, start, n = {}, {}, 1, 1
		for loc, char in gmatch(str, "()([\t\n\r !\"'%-/<=>%[%]{|}])") do
			if loc > start then
				text[n], raw_lens[n] = get(sub(str, start, loc - 1))
				n = n + 1
			end
			text[n], raw_lens[n] = get(char)
			n = n + 1
			start = loc + 1
		end
		if #str >= start then
			text[n], raw_lens[n] = get(sub(str, start))
		end
		return (select(2, Parser:parse{
			text = text,
			node = {Wikitext},
			route = {"do_parse", raw_lens, str, transcluded, title}
		}))
	end
end

do
	local normalized = {}
	
	-- Normalize the template name, check it's a valid template, and use `normalized` to memoize results, using false for invalid titles.
	-- Parser functions (e.g. {{#IF:a|b|c}}) need to have the first argument extracted from the title, as it comes after the colon. Because of this, the parser function and first argument are memoized as a table.
	-- FIXME: Some parser functions have special argument handling (e.g. {{#SWITCH:}}).
	local function get_name_and_params(node)
		local name = tostring(node[1])
		local norm = normalized[name]
		if norm then
			if type(norm) == "table" then
				insert(node, 2, Parameter:new{norm[2]})
				node.len = node.len + 1
				return norm[1], node:get_array_params()
			end
			return norm, node:get_params()
		elseif norm == false then
			return
		end
		local title = trim(frame:preprocess(name))
		local pf, arg1 = match(title, "[ \t\n\r]*(.-):(.*)")
		if pf then
			local parser_funcs = data.parser_funcs
			for i = 1, 2 do
				if parser_funcs[pf] then
					normalized[name] = {pf, arg1}
					insert(node, 2, Parameter:new{arg1})
					node.len = node.len + 1
					return pf, node:get_array_params()
				elseif i == 1 then
					pf = uupper(pf)
				end
			end
		end
		title = new_title(title, 10)
		-- Mainspace titles starting with "#" should be invalid, but a bug in mw.title.new means a title object is returned that has the empty string for prefixedText, so we need to filter them out. Interwiki links aren't valid as templates, either.
		if not title or #title.prefixedText == 0 or #title.interwiki > 0 then
			normalized[name] = false
			return
		end
		local val = title.namespace == 10 and title.text or
			title.namespace == 0 and (":" .. title.text) or
			title.prefixedText
		normalized[name] = val
		return val, node:get_params()
	end
	
	function export.parseTemplate(text, not_transcluded)
		text = export.parse(text, not not_transcluded)
		if text and text.type == "template" then
			return get_name_and_params(text)
		end
	end
	
	function export.findTemplates(text, not_transcluded)
		text = export.parse(text, not not_transcluded)
		local iterate = text:__pairs("next_node")
		return function()
			local node, name, params
			repeat
				repeat
					node = iterate()
					if not node then
						return
					end
				until node.type == "template"
				name, params = get_name_and_params(node)
			until name
			return name, params, node.raw, node.pos
		end
	end
end

return export