local concat = table.concat
local insert = table.insert
local next = next
local rawget = rawget
local rawset = rawset
local remove = table.remove
local setmetatable = setmetatable
local tostring = tostring
local type = type
local unpack = unpack

------------------------------------------------------------------------------------
--
-- Node proxy
--
------------------------------------------------------------------------------------

local Proxy = {}

function Proxy:__index(k)
	return Proxy[k] or self.__chars[k]
end

function Proxy:__newindex(k, v)
	local key = self.__keys[k]
	if key then
		self.__chars[k] = v
		self.__parents[key] = v
	elseif key == false then
		error("Character is immutable.")
	else
		error("Invalid key.")
	end
end

function Proxy:build(a, b, c)
	local len = self.__len + 1
	self.__chars[len] = a
	self.__parents[len] = b
	self.__keys[len] = c
	self.__len = len
end

function Proxy:iter(i)
	i = i + 1
	local char = self.__chars[i]
	if char then
		return i, self[i], self, self.__parents[i], self.__keys[i]
	end
end

------------------------------------------------------------------------------------
--
-- Nodes
--
------------------------------------------------------------------------------------

local Node = {}
Node.__index = Node

function Node:new_proxy()
	return setmetatable({
		__node = self,
		__chars = {},
		__parents = {},
		__keys = {},
		__len = 0
	}, Proxy)
end

function Node:next(i)
	i = i + 1
	return self[i], i
end

function Node:next_node(i)
	local v
	repeat
		i = i + 1
		v = self[i]
	until v == nil or type(v) == "table"
	return v, i
end

-- Implements recursive iteration over a node tree, using functors to maintain state (which uses a lot less memory than closures). Iterator1 exists only to return the calling node on the first iteration, while Iterator2 uses a stack to store the state of each layer in the tree.

-- When a node is encountered (which may contain other nodes), it is returned on the first iteration, and then any child nodes are returned on each subsequent iteration; the same process is followed if any of those children contain nodes themselves. Once a particular node has been fully traversed, the iterator moves back up one layer and continues with any sibling nodes.

-- Each iteration returns three values: `value`, `node` and `key`. Together, these can be used to manipulate the node tree at any given point without needing to know the full structure. Note that when the input node is returned on the first iteration, `node` and `key` will be nil.

-- By default, the iterator will use the `next` method of each node, but this can be changed with the `next_func` parameter, which accepts a string argument with the name of a next method. This is because trees might consist of several different classes of node, and each might have different next methods that are tailored to their particular structures. In addition, each class of node might have multiple different next methods, which can be named according to their purposes. `next_func` ensures that the iterator uses equivalent next methods between different types of node.

-- Currently, two next methods are available: `next`, which simply iterates over the node conventionally, and `next_node`, which only returns children that are themselves nodes. Custom next methods can be declared by any calling module.
do
	local Iterator1, Iterator2 = {}, {}
	Iterator1.__index = Iterator2 -- Not a typo.
	Iterator2.__index = Iterator2
	
	function Iterator1:__call()
		setmetatable(self, Iterator2)
		return self[1].node
	end
	
	function Iterator2:push(node)
		local len = self.len + 1
		self[len] = {
			k = 0,
			node = node
		}
		self[-1] = self[len]
		self.len = len
		return self
	end
	
	function Iterator2:pop()
		local len = self.len
		self[len] = nil
		len = len - 1
		self[-1] = self[len]
		self.len = len
	end
	
	function Iterator2:__call()
		local node, v = self[-1].node
		v, self[-1].k = node[self.next_func](node, self[-1].k)
		if v == nil then
			self:pop()
			if self[-1] then
				return self:__call()
			end
			return
		end
		local k = self[-1].k
		if type(v) == "table" then
			self:push(v)
		end
		return v, node, k
	end
	
	function Node:__pairs(next_func)
		return setmetatable({
			next_func = next_func or "next",
			len = 0
		}, Iterator1):push(self)
	end
end

function Node:rawpairs()
	return next, self
end

-- Note: recursively calling tostring() adds to the C stack (limit: 200), whereas calling __tostring metamethods directly does not. Occasionally relevant when dealing with very deep nesting.
function Node:__tostring()
	local output = {}
	for i = 1, #self do
		local v = self[i]
		insert(output, type(v) == "table" and v:__tostring() or tostring(v))
	end
	return concat(output)
end

local function new(self, t)
	rawset(t, "handler", nil)
	rawset(t, "override", nil)
	rawset(t, "route", nil)
	rawset(t, "bad_route", nil)
	return setmetatable(t, self)
end

function Node:new(type)
	local t = {
		__concat = self.__concat,
		__pairs = self.__pairs,
		__tostring = self.__tostring,
		type = type,
		new = new
	}
	t.__index = t
	return setmetatable(t, self)
end

local Wikitext = Node:new("wikitext")

function Wikitext:new(t, force_wrapper)
	if not force_wrapper and t.len == 1 and type(t[1]) == "table" then
		return t[1]
	end
	return new(self, t)
end

do
	local deepcopy
	
	local function insert_clone(output, n)
		if n.type == "wikitext" then
			for i = 1, #n do
				insert(output, deepcopy(n[i]))
			end
		else
			insert(output, deepcopy(n))
		end
	end
	
	function Node:__concat(a)
		deepcopy = deepcopy or require("table").deepcopy
		local output = Wikitext:new{}
		insert_clone(output, self)
		insert_clone(output, a)
		return output
	end
end

------------------------------------------------------------------------------------
--
-- Parser
--
------------------------------------------------------------------------------------

local function signed_index(t, n)
	return n and n <= 0 and t.len + 1 + n or n
end

local Parser = {}
Parser.__index = Parser

function Parser:read(delta)
	return self.text[self.head + (delta or 0)] or ""
end

function Parser:advance(n)
	self.head = self.head + (n or 1)
end

function Parser:layer(n)
	if n then
		return rawget(self, self.len + n)
	end
	return self.n
end

function Parser:emit(a, b)
	local layer = self.n
	if b then
		a = signed_index(layer, a)
		insert(layer, a, b)
		layer.len = layer.len + 1
	else
		local len = layer.len + 1
		rawset(layer, len, a)
		layer.len = len
	end
end

function Parser:emit_tokens(a, b)
	local layer = self.n
	local len = layer.len
	if b then
		a = signed_index(layer, a)
		for i = 1, b.len do
			len = len + 1
			insert(layer, a + i - 1, b[i])
		end
	else
		for i = 1, a.len do
			len = len + 1
			rawset(layer, len, a[i])
		end
	end
	layer.len = len
end

function Parser:remove(n)
	local layer = self.n
	local len, token = layer.len
	if n then
		n = signed_index(layer, n)
		token = remove(layer, n)
		layer.len = layer.len - 1
	else
		token = layer[len]
		layer[len] = nil
		len = len - 1
		layer.len = len
	end
	return token
end

function Parser:replace(a, b)
	local layer = self.n
	a = signed_index(layer, a)
	layer[a] = b
end

-- Unlike default table.concat, this respects __tostring metamethods.
function Parser:concat(a, b, c)
	if not a or a > 0 then
		return self:concat(0, a, b)
	end
	local layer = self:layer(a)
	b = signed_index(layer, b) or 1
	c = signed_index(layer, c) or #layer
	local ret = {}
	for i = b, c do
		insert(ret, tostring(layer[i]))
	end
	return concat(ret)
end

function Parser:emitted(delta)
	delta = delta or -1
	local i, layer = 0, self.n
	while layer and -delta > layer.len do
		delta = delta + layer.len
		i = i - 1
		layer = self:layer(i)
	end
	return layer and rawget(layer, layer.len + delta + 1)
end

function Parser:push(route)
	local layer = {
		head = self.head,
		route = route,
		len = 0
	}
	local len = self.len + 1
	self[len] = layer
	self.n = layer
	self.len = len
end

function Parser:push_sublayer(handler)
	local layer = self.n
	rawset(layer, "__index", layer)
	rawset(layer, "__newindex", layer)
	local sublayer = setmetatable({
		handler = handler,
		sublayer = true,
		len = 0
	}, layer)
	local len = self.len + 1
	self[len] = sublayer
	self.n = sublayer
	self.len = len
end

function Parser:pop()
	local len, layer = self.len
	while self.n.sublayer do
		layer = self[len]
		self[len] = nil
		len = len - 1
		self.n = self[len]
		self:emit_tokens(layer)
	end
	layer = self[len]
	self[len] = nil
	len = len - 1
	self.n = self[len] or self
	self.len = len
	rawset(layer, "__concat", nil)
	rawset(layer, "__index", nil)
	rawset(layer, "__newindex", nil)
	rawset(layer, "__pairs", nil)
	rawset(layer, "__tostring", nil)
	return layer
end

function Parser:pop_sublayer()
	local len = self.len
	local layer = self[len]
	self[len] = nil
	len = len - 1
	self.n = self[len] or self
	self.len = len
	rawset(layer, "__concat", nil)
	rawset(layer, "__index", nil)
	rawset(layer, "__newindex", nil)
	rawset(layer, "__pairs", nil)
	rawset(layer, "__tostring", nil)
	return layer
end

function Parser:get(route, ...)
	local head = self.head
	if (
		self.bad_routes and
		self.bad_routes[head]
	) then
		local bad_route = self.bad_routes[head][route]
		if bad_route then
			self.n.bad_route = bad_route
			return bad_route
		end
	end
	self:push(route)
	local layer = self[route](self, ...)
	if not layer then
		layer = self:traverse()
	end
	if layer == self.n.bad_route then
		self.head = head
	end
	return layer
end

function Parser:consume(this, ...)
	return (self.n.override or self.n.handler)(self, this or self:read(), ...)
end

function Parser:fail_route()
	local bad_route = self:pop()
	local head = bad_route.head
	if not self.bad_routes then
		self.bad_routes = {}
	end
	self.bad_routes[head] = self.bad_routes[head] or {}
	self.bad_routes[head][bad_route.route] = bad_route
	self.n.bad_route = bad_route
	return bad_route
end

function Parser:traverse()
	local layer
	while true do
		layer = self:consume()
		if layer then
			return layer
		end
		self:advance()
	end
end

function Parser:new(text)
	return setmetatable({
		text = text,
		head = 1,
		len = 0
	}, self)
end

function Parser:parse(data)
	local parser = self:new(data.text)
	local tokens = parser:get(unpack(data.route))
	if tokens == parser.bad_route then
		if data.allow_fail then
			return false, nil, parser
		end
		error("Parser exited with bad route.")
	elseif parser.len > 0 then
		error("Parser exited with non-empty stack.")
	end
	local node = data.node
	return true, node[1]:new(tokens, unpack(node, 2)), parser
end

return {
	Node = Node,
	Wikitext = Wikitext,
	Parser = Parser
}