local gsub = string.gsub

return function(str)
	return (gsub(str, "[$%%()*+%-.?[%]^]", "%%%0"))
end