local u = mw.ustring.char

local modules = {
	["Module:languages/data/2"] = true,
	["Module:languages/data/exceptional"] = true,
}
for i = 1, 26 do
	modules["Module:languages/data/3/" .. u(0x60+i)] = true
end

local m = {}

for mname in pairs(modules) do
	for key, value in pairs(require(mname)) do
		if value[4] == "All" then
			local scripts = {}
			for script in pairs(require("scripts/data")) do
				table.insert(scripts, script)
			end
			value[4] = scripts
		end
		m[key] = value
	end
	local xname = mname .. "/extra"
	for lkey, lvalue in pairs(require(xname)) do
		if m[lkey] then
			for key, value in pairs(lvalue) do
				m[lkey][key] = lvalue[key]
			end
		end
	end
end

return m