local export = {}

local rsplit = mw.text.split

-- Add links to `label`. It operates as follows:
-- 1. If the singular equivalent of the label (which will be the label itself if the label doesn't end in -s) exists as
--    a term in Wiktionary and `no_singularize` isn't specified, link the label to the singular equivalent.
-- 2. Otherwise link the label directly, if it exists (as a term in Wiktionary).
-- 3. Otherwise, if the label is multiword, split the label into words, singularize the last word (unless
--    `no_singularize` is specified), and attempt to link each word individually. This fails if any of the linked words
--    don't exist in Wiktionary.
-- 4. Otherwise, if the label is multiword, split the label into words and link each word individually as-is, including
--    the last one. This fails if any of the linked words don't exist in Wiktionary.
-- 5. Finally, return the label unchanged.
--
-- FIXME: This should probably check if an English term exists for each linked term rather than that the term exists at
-- all.
--
-- If `wikify` is given, just link the singular equivalent of the label to Wikipedia unless `no_singularize` is given,
-- in which case the label is linked as-is to Wikipedia.
--
-- The main use of `no_singularize` is with plural-form terms that also exist in the singular but have special meanings
-- in the plural that are different from the corresponding singular (e.g. [[acoustics]] is not the plural of
-- [[acoustic]], but will be incorrectly linked as [[acoustic]]s unless `no_singularize` is given).
function export.link_label(label, no_singularize, wikify)
	local function term_exists(term)
		local title = mw.title.new(term)
		return title and title.exists
	end

	local singular_label
	if not no_singularize then
		singular_label = require("string utilities").singularize(label)
	end

	if wikify then
		if singular_label then
			return "[[w:" .. singular_label .. "|" .. label .. "]]"
		else
			return "[[w:" .. label .. "|" .. label .. "]]"
		end
	end

	-- First try to singularize the label as a whole, unless 'no singularize' was given. If the result exists,
	-- return it.
	if singular_label and term_exists(singular_label) then
		return "[[" .. singular_label .. "|" .. label .. "]]"
	elseif term_exists(label) then
		-- Then check if the original label as a whole exists, and return if so.
		return "[[" .. label .. "]]"
	else
		-- Otherwise, if the label is multiword, split into words and try the link each one, singularizing the last
		-- one unless 'no singularize' was given.
		local split_label
		if label:find(" ") then
			if not no_singularize then
				split_label = rsplit(label, " ")
				for i, word in ipairs(split_label) do
					if i == #split_label then
						local singular_word = require("string utilities").singularize(word)
						if term_exists(singular_word) then
							split_label[i] = "[[" .. singular_word .. "|" .. word .. "]]"
						else
							split_label = nil
							break
						end
					else
						if term_exists(word) then
							split_label[i] = "[[" .. word .. "]]"
						else
							split_label = nil
							break
						end
					end
				end
				if split_label then
					split_label = table.concat(split_label, " ")
				end
			end

			-- If we weren't able to link individual words with the last word singularized, link all words as-is.
			if not split_label then
				split_label = rsplit(label, " ")
				for i, word in ipairs(split_label) do
					if term_exists(word) then
						split_label[i] = "[[" .. word .. "]]"
					else
						split_label = nil
						break
					end
				end
				if split_label then
					split_label = table.concat(split_label, " ")
				end
			end
		end

		return split_label or label
	end
end

return export