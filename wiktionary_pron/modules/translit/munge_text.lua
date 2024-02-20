return function(text, fn)
	local has_html = text:find("<")
	local has_two_part_link = text:find("%[%[.*|")
	if not has_html and not has_two_part_link then
		return fn(text)
	end

	local function do_munge(text, pattern, functor)
		local index = 1
		local length = mw.ustring.len(text)
		local result = ""
		pattern = "(.-)(" .. pattern .. ")"
		while index <= length do
			local first, last, before, match = mw.ustring.find(text, pattern, index)
			if not first then
				result = result .. functor(mw.ustring.sub(text, index))
				break
			end
			result = result .. functor(before) .. match
			index = last + 1
		end
		return result
	end
	
	local function munge_text_with_html(txt)
		return do_munge(txt, "<[^>]->", fn)
	end

	if has_two_part_link then -- contains wikitext links
		return do_munge(text, "%[%[[^%[%]|]-|", has_html and munge_text_with_html or fn)
	else -- HTML tags only
		return munge_text_with_html(text)
	end
end