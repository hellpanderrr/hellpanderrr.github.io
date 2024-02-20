return function (str)
	return mw.ustring.gsub(str, "([%(%)%.%%%+%-%*%?%[%^%$%]])", "%%%1")
end