local data = {}

for _, interwiki in pairs(mw.site.interwikiMap()) do
	local prefix = interwiki.prefix:gsub("_", " ")
	if prefix:find("[\194-\244]") then
		prefix = prefix:ulower()
	else
		prefix = prefix:lower()
	end
	data[prefix] = interwiki.isCurrentWiki and "current" or
		interwiki.isLocal and "local" or
		"external"
end

return data