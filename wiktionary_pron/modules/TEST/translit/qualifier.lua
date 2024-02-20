local export = {}

function export.format_qualifier(list, open, close) -- keep in sync with [[Template:qualifier]]
	if type(list) ~= "table" then
		list = { list }
	end
	
	if #list == 0 then
		return ''
	end

	return '<span class="ib-brac qualifier-brac">' .. (open or "(") .. '</span>' ..
	       '<span class="ib-content qualifier-content">' ..
	       table.concat(list, '<span class="ib-comma qualifier-comma">,</span> ') ..
		   '</span><span class="ib-brac qualifier-brac">' .. (close or ")") .. '</span>'
end

function export.sense(list) -- keep in sync with [[Template:sense]]
	return export.format_qualifier(list)
		.. '<span class="ib-colon sense-qualifier-colon">:</span>'
end

return export