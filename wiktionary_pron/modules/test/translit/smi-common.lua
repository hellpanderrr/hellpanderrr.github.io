local export = {}

local function gsub_nil(text, pattern, repl)
	local num
	text, num = mw.ustring.gsub(text, pattern, repl)
	
	if num == 0 then
		return nil
	else
		return text
	end
end

local function get_item(word, patterns)
	local ret, remainder
	
	for _, pattern in ipairs(patterns) do
		remainder, ret = mw.ustring.match(word, pattern)
		
		if remainder then
			return remainder, ret
		end
	end
end

local function transform(cons, patterns)
	if not patterns then
		return nil
	end
	
	local newcons
	
	for _, pattern in ipairs(patterns) do
		if newcons then
			break
		end
		
		if pattern[2] then
			newcons = gsub_nil(cons, pattern[1], pattern[2])
		else
			newcons = mw.ustring.match(cons, pattern[1])
		end
	end
	
	return newcons
end

local function make_new_pattern(from, to)
	local i = 1
	
	if from:sub(1, 1) == "^" then
		to = "^" .. to
	end
	
	if from:sub(-1) == "$" then
		to = to .. "$"
	end
	
	for match in mw.ustring.gmatch(from, "%([^()]+%)") do
		to = mw.ustring.gsub(to, "%%" .. i, match, 1)
		i = i + 1
	end
	
	i = 1
	local repls
	
	while true do
		from, repls = mw.ustring.gsub(from, "%([^()]+%)", "%%" .. i, 1)
		i = i + 1
		
		if repls == 0 then
			break
		end
	end
	
	from = mw.ustring.gsub(from, "[$^]", "")
	
	return to, from
end

export.Stem = {}
export.Stem.__index = export.Stem

export.make_constructor = function(langdata)
	-- Add weak and extra-strong patterns to the langdata
	if langdata.scons then
		for _, quantity in ipairs({3, 2}) do
			for _, pattern in ipairs(langdata.scons[quantity]) do
				if pattern[2] then
					local from = make_new_pattern(pattern[1], pattern[2])
					table.insert(langdata.scons[quantity - 1], {from})
				end
				
				if quantity == 2 and pattern[3] then
					local from, to = make_new_pattern(pattern[1], pattern[3])
					table.insert(langdata.scons[quantity + 1], {from, to})
				end
			end
		end
	end
	
	return function(stem, gradation, final)
		local self = setmetatable({langdata = langdata}, export.Stem)
		
		self.init = stem
		self.final = final
		
		-- Unstressed consonant, consonant margin
		self.init, self.ucons = get_item(self.init, self.langdata.consonant)
		
		-- Unstressed vowel, latus
		self.init, self.uvowel = get_item(self.init, self.langdata.vowel)
		
		-- Stressed consonant, consonant center
		self.init, self.scons = get_item(self.init, self.langdata.consonant)
		
		-- Stressed vowel, vowel center
		self.init, self.svowel = get_item(self.init, self.langdata.vowel)
		
		if self.langdata.preprocess then
			self.langdata.preprocess(self)
		end
		
		if self.scons ~= "" and self.langdata.scons then
			-- Determine the quantity and gradation pattern of the stressed consonant
			local matched_patterns = {}
			
			for quantity, patterns in ipairs(self.langdata.scons) do
				for _, pattern in ipairs(patterns) do
					if mw.ustring.find(self.scons, pattern[1]) then
						table.insert(matched_patterns, {pattern = pattern, quantity = quantity})
					end
				end
			end
			
			if not matched_patterns[1] then
				error("The quantity of the consonant \"" .. self.scons .. "\" cannot be determined.")
			end
			
			local scons_pattern = matched_patterns[#matched_patterns].pattern
			self.quantity = matched_patterns[#matched_patterns].quantity
			
			-- Make weak and extra-strong grades
			if gradation then
				if not scons_pattern[2] then
					error("The consonant \"" .. self.scons .. "\" cannot gradate.")
				end
				
				self.gradation = {}
				self.gradation.strong = {scons = self.scons, quantity = self.quantity}
				self.gradation.extra = {scons = self.scons, quantity = self.quantity}
				self.gradation.weak = {
					scons = mw.ustring.gsub(self.scons, scons_pattern[1], scons_pattern[2]),
					quantity = self.quantity - 1,
				}
				
				if scons_pattern[3] then
					self.gradation.extra = {
						scons = mw.ustring.gsub(self.scons, scons_pattern[1], scons_pattern[3]),
						quantity = self.quantity + 1,
					}
				end
				
				if gradation == "Q31" then
					if self.quantity ~= 3 then
						error("The consonant \"" .. self.scons "\" is not quantity 3 and therefore cannot have quantity 3-1 gradation.")
					end
					
					-- Find the weak grade of the weak grade
					local scons_pattern
					
					for _, pattern in ipairs(self.langdata.scons[2]) do
						if mw.ustring.find(self.gradation.weak.scons, pattern[1]) then
							scons_pattern = pattern
							break
						end
					end
					
					if not scons_pattern then
						error("The consonant \"" .. self.scons .. "\" cannot gradate to quantity 1.")
					end
					
					self.gradation.weak = {
						scons = mw.ustring.gsub(self.gradation.weak.scons, scons_pattern[1], scons_pattern[2]),
						quantity = 1,
					}
				end
			end
		else
			self.quantity = 1
		end
		
		return self
	end
end

function export.Stem:make_form(data)
	data.variant = data.variant or "normal"
	
	local form = {
		svowel = self.svowel,
		scons = self.scons,
		uvowel = self.uvowel,
		ucons = self.ucons,
		ending = data.ending or "",
		quantity = self.quantity,
	}
	
	if self.gradation then
		if not data.grade then
			error("No grade was specified for ending \"" .. form.ending .. "\".")
		end
		
		form.scons = self.gradation[data.grade].scons
		form.quantity = self.gradation[data.grade].quantity
	end
	
	-- Turn ucons into its word-final form if applicable
	if form.ucons ~= "" and self.langdata.make_final_if then
		for _, pattern in ipairs(self.langdata.make_final_if) do
			if mw.ustring.find(form.ending, pattern) then
				form.ucons = self.final or self:make_final(form.ucons)
				break
			end
		end
	end
	
	if data.variant == "none" then
		if form.ending ~= "" then
			error("The variant \"none\" can only be used with no ending.")
		elseif form.ucons ~= "" then
			error("The variant \"none\" can only be used with vowel-final stems.")
		end
		
		-- Turn scons into its word-final form
		form.uvowel = ""
		form.scons = self:make_final(form.scons)
	else
		-- Retrieve vowel variant data from the table
		if not self.langdata.vowel_variants[data.variant] then
			error("The stem variant \"" .. data.variant .. "\" does not exist.")
		end
		
		local vowel_info = self.langdata.vowel_variants[data.variant][form.uvowel]
		local vowel_effect
		
		if vowel_info then
			form.uvowel = vowel_info[1]
			vowel_effect = vowel_info[2]
		end
		
		-- Call language-specific function for postprocessing
		if self.langdata.postprocess then
			self.langdata.postprocess(form, vowel_effect)
		end
	end
	
	return self.init .. form.svowel .. form.scons .. form.uvowel .. form.ucons .. form.ending
end

function export.Stem:make_final(cons)
	local newcons = transform(cons, self.langdata.to_final)
	
	if newcons then
		return newcons
	else
		error("The consonant(s) \"" .. cons .. "\" are not allowed word-finally, but this template does not know how to replace them with allowed ones.")
	end
end

return export