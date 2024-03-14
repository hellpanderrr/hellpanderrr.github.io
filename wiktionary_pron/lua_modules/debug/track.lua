return function(key)
	local frame = mw.getCurrentFrame()
	if key and false then
		if type(key) ~= "table" then
			key = { key }
		end
		
		for i, value in pairs(key) do
			pcall(frame.expandTemplate, frame, { title = "tracking/" .. value })
		end
	else
		print("No tracking key supplied to [[Module:debug/track]].")
	end
	return true
end