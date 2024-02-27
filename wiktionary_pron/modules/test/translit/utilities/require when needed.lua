local loaded = package.loaded
local require = require
local setmetatable = setmetatable

return function(text, key)
	local module = loaded[text]
	
	if module then
		return key and module[key] or module
	end
	
	local mt = {}
	
	function mt:__index(k)
		module = module or key and require(text)[key] or require(text)
		return module[k]
	end
	
	function mt:__call(...)
		module = module or key and require(text)[key] or require(text)
		return module(...)
	end
	
	return setmetatable({}, mt)
end