local data = {}

local function normalize(name)
	return name:gsub("_", " "):ulower()
end

for _, namespace in pairs(mw.site.namespaces) do
	local prefix = normalize(namespace.name)
	data[prefix] = prefix
	for _, alias in pairs(namespace.aliases) do
		data[normalize(alias)] = prefix
	end
end

return data