return function(key)
    print(44,key)

	local frame = mw.getCurrentFrame()
	print(555,frame)
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