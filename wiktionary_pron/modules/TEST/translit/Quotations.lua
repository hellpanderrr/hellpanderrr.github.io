local m_scriptutils = require("script utilities")
local date_validation = require("Quotations/date validation")
local loadModule -- a forward declaration
local export = {}

local LanguageModule = {}
LanguageModule.__index = LanguageModule

local hasData = {
	['ae'] = true,
	['ar'] = true,
	['axm'] = true,
	['az'] = true,
	['bra'] = true,
	['chg'] = true,
	['cy'] = true,
	['egy'] = true,
	['en'] = true,
	['fa'] = true,
	['fro'] = true,
	['gmq-ogt'] = true,
	['gmq-pro'] = true,
	['grc'] = true,
	['he'] = true,
	['hi'] = true,
	['hy'] = true,
	['inc-ogu'] = true,
	['inc-mgu'] = true,
	['inc-ohi'] = true,
	['inc-opa'] = true,
	['inc-pra'] = true,
	['la'] = true,
	['lzz'] = true,
	['mt'] = true,
	['mxi'] = true,
	['oge'] = true,
	['omr'] = true,
	['ota'] = true,
	['peo'] = true,
	['pmh'] = true,
	['sa'] = true,
	['scn'] = true,
	['sv'] = true,
	['vah'] = true,
	['xcl'] = true,
}
export.hasData = hasData

function export.create(frame)
	local passed, results = pcall(function () return export.Create(frame:getParent().args) end)
	if passed then
		return results
	else
		--[[Special:WhatLinksHere/Template:tracking/Quotations/error]]
		require('debug').track('Quotations/error')
		return '<span class="wiktQuote previewonly error" data-validation="red">'..results..'</span>'
	end
end

local function warn_about_unrecognized_args(unrecognized_args)
	require('debug').track('Quotations/param error')
	
	mw.addWarning('Unrecognized parameters in '
		.. mw.text.nowiki('{{Q}}: '
		.. table.concat(require('table').keysToList(unrecognized_args), ', ')))
end

function export.Create(args)
	-- Set up our initial variables; set empty parameters to false
	local processed_args = {}
	local unrecognized_args = {}
	local params = {
		['thru'] = true,
		['quote'] = true,
		['trans'] = true,
		['transauthor'] = true,
		['transyear'] = true,
		['t'] = true,
		['lit'] = true,
		['style'] = true,
		['object'] = true,
		['notes'] = true,
		['refn'] = true,
		['form'] = true,
		['year'] = true,
		['termlang'] = true,
		['tr'] = true, -- This is simply ignored if quote is in Latin script.
		['ts'] = true, -- This is simply ignored if quote is in Latin script.
		['subst'] = true, -- This is simply ignored if quote is in Latin script.
		['nocat'] = true,
	}

	local max_numbered_param = 4
	for k, v in pairs(args) do
		if type(k) == 'number' then
			if k > max_numbered_param then
				max_numbered_param = k
			end
		elseif not params[k] then
			unrecognized_args[k] = v
		end
		
		if v == '' then
			if k == "lang" then
				processed_args[k] = nil
			else
				processed_args[k] = false
			end
		else
			processed_args[k] = v
		end
	end
	
	if next(unrecognized_args) then
		warn_about_unrecognized_args(unrecognized_args)
	end
	
	-- Ensure that all numbered parameters up to the greatest numbered parameter
	-- are not nil.
	for i = 1, max_numbered_param do
		processed_args[i] = processed_args[i] or false
	end
	
	args = processed_args -- Overwrite original args.
	
	local lang = args[1]
	lang = require("languages").getByCode(lang) or require("languages").err(lang, 1)
	
	local ante = {}
	
	if hasData[lang:getCode()] then
		local m_langModule = LanguageModule.new(lang)
		ante = m_langModule:expand(args)
	else
		require("debug").track {
			'Quotations/no data',
			'Quotations/no data/' .. lang:getCode(),
		}
	end
	
	if ante.author == nil then
		ante.author = args[2]
	end
	if ante.work == nil then
		ante.work = args[3]
	end
	if ante.ref == nil then
		local ref = {}
		for i = 4, 10 do
			if args[i] then
				table.insert(ref, args[i])
			else
				break
			end
		end
		ante.ref = table.concat(ref, '.')
	end
	
	for k,v in pairs(args) do
		if type(k) ~= 'number' then
			ante[k] = args[k]
		end
	end

	local penult = {['year'] = '', ['author'] = '', ['work'] = '', ['object'] = '', ['ref'] = '', ['termlang'] = '',
		['notes'] = '', ['refn'] = '', ['otherLines'] = {}, ['s1'] = '', ['s2'] = '',
		['s3'] = '', ['s4'] = '', ['s5'] = '', ['style1'] = '', ['style2'] = ''}
	local comma = false
	--Language specific modules are responsible for first line parameters.
	--Base formatting module will poll for other parameters,
	--pulling them only if the language module hasn't returned them.

	local otherOtherLineStuff = {'quote', 'transyear', 'transauthor', 'trans', 'termlang'}
	for _, item in ipairs(otherOtherLineStuff) do
		ante[item] = ante[item] or args[item]
	end

	if not ante.code then
		penult.elAttr = ' class="wiktQuote" data-validation="white">'
	else
		penult.elAttr = ' class="wiktQuote" data-validation="'..ante.code..'">'
	end
	if ante.year then
		penult.year = "'''"..date_validation.main(ante.year).."'''"
		comma = true
	end
	if ante.author then
		penult.s1 = (comma and ', ' or '')
		penult.author = ante.author
		comma = true
	end
	if ante.work then
		penult.s2 = (comma and ', ' or '')
		penult.work = ante.work
		comma = true
	end
	if ante.object then
		penult.s5 = (comma and ' ' or '')
		penult.object = '('..ante.object..')'
		comma = true
	end
	if ante.ref then
		penult.s3 = (comma and ' ' or '')
		penult.ref = ante.ref
	end
	if ante.style == 'no' or penult.work == '' then
		penult.style1 = ''
		penult.style2 = ''
	elseif ante.style == 'q' then
		penult.style1 = '“'
		penult.style2 = '”'
	else
		penult.style1 = "''"
		penult.style2 = "''"
	end
	if ante.termlang then
		ante.termlang = require("languages").getByCode(ante.termlang) or require("languages").err(ante.termlang, 1)
		penult.termlang = ' (in '..lang:getCanonicalName()..')'
	end
	
	local form = args['form'] or 'full'
	local ultimate
	if form == 'full' then
		local categories = {}
		local namespace = mw.title.getCurrentTitle().nsText

		if ante.notes then
			penult.s4 = (comma and ', ' or '')
			penult.notes = '('..ante.notes..')'
		end
		if ante.refn then
			penult.refn = ante.refn
		end
		
		if ante.t then
			ante.trans = ante.t
		end
		
		if ante.quote or (ante.trans and ante.trans ~= "-") then
			penult.refn = ":" .. penult.refn
			local translitwithtrans = false
			table.insert(penult.otherLines, "<dl><dd>")
			if ante.quote then
				local sc = lang:findBestScript(ante.quote)
				local quote = ante.quote
				-- fix up links with accents/macrons/etc.
				if quote:find("[[", 1, true) then
					 quote = require("links").language_link{term = quote, lang = lang}
				end
				table.insert(penult.otherLines, m_scriptutils.tag_text(quote, lang, sc, nil, "e-quotation"))
				if (namespace == "" or namespace == "Reconstruction") and not args.nocat then
					if ante.termlang then
						table.insert(categories, ante.termlang:getCanonicalName() .. " terms with quotations")
					else
						table.insert(categories, lang:getCanonicalName() .. " terms with quotations")
					end
				end
				if not m_scriptutils.is_Latin_script(sc) or lang:getCode() == "egy" then

					-- Handle subst=		
					local subbed_quote = require("links").remove_links(quote)
					if args.subst then
						local substs = mw.text.split(args.subst, ",")
						for _, subpair in ipairs(substs) do
							local subsplit = mw.text.split(subpair, mw.ustring.find(subpair, "//") and "//" or "/")
							subbed_quote = mw.ustring.gsub(subbed_quote, subsplit[1], subsplit[2])
						end
					end

					local transliteration = args.tr or (lang:transliterate(subbed_quote, sc))
					if transliteration then
						transliteration = "<dd>" .. m_scriptutils.tag_translit(transliteration, lang, "usex") .. "</dd>"
					end
					local transcription = args.ts and "<dd>/" .. m_scriptutils.tag_transcription(args.ts, lang, "usex") .. "/</dd>"
					if transliteration or transcription then
						local translitend = "</dl>"
						if ante.trans and ante.trans ~= "-" and not ante.transyear and not ante.transauthor then
							translitwithtrans = true
							translitend = ""
						end
						table.insert(penult.otherLines, "<dl>" .. (transliteration or "") .. (transcription or "") .. translitend)
					end
				end
			end

			if ante.trans == "-" then
				ante.trans = nil
				table.insert(categories, "Omitted translation in the main namespace")
			elseif ante.trans then
				local litline = ""
				if ante.lit then
					litline = "<dd>(literally, “"..ante.lit.."”)</dd>"
				end
				if ante.transyear or ante.transauthor then
					table.insert(penult.otherLines, "<ul><li>")
					if ante.transyear then
						table.insert(penult.otherLines, "'''" .. ante.transyear .. "''' translation")
					else
						table.insert(penult.otherLines, "Translation")
					end
					if ante.transauthor then
						table.insert(penult.otherLines, " by " .. ante.transauthor)
					end
					table.insert(penult.otherLines, "<dl><dd>" .. ante.trans .. "</dd>" .. litline .. "</dl></li></ul>")
				else
					if not ante.quote then
						table.insert(penult.otherLines, ante.trans)
					else
						local transstart = "<dl><dd>"
						if translitwithtrans then
							transstart = "<dd>"
						end
						table.insert(penult.otherLines, transstart .. ante.trans .. "</dd>" .. litline .. "</dl>")
					end
				end
			elseif lang:getCode() ~= "en" and lang:getCode() ~= "und" then
				-- add trreq category if translation is unspecified and language is not English or undetermined
				table.insert(categories, "Requests for translations of " .. lang:getCanonicalName() .. " quotations")
			end
			table.insert(penult.otherLines, "</dd></dl>")
		end
		penult.otherLines = table.concat(penult.otherLines)
		
		ultimate = '<div'..penult.elAttr..penult.year..penult.s1..penult.author..penult.s2..penult.style1..penult.work..penult.termlang..penult.style2..penult.s5..penult.object..penult.s3..penult.ref..penult.s4..penult.notes..penult.refn..penult.otherLines..'</div>'..require("utilities").format_categories(categories, lang)
	elseif form == 'inline' then
		ultimate = '<span'..penult.elAttr..penult.author..penult.s2..penult.style1..penult.work..penult.termlang..penult.style2..penult.s5..penult.object..penult.s3..penult.ref..'</span>'
	elseif form == 'work' then
		ultimate = '<span'..penult.elAttr..penult.style1..penult.work..penult.termlang..penult.style2..penult.s5..penult.object..penult.s3..penult.ref..'</span>'
	elseif form == 'ref' then
		ultimate = '<span'..penult.elAttr..penult.ref..'</span>'
	end
	return ultimate

end

local function add_self(func)
	return function(self, ...)
		return func(...)
	end
end

function LanguageModule.new(lang)
	local sema = require('Quotations/' .. lang:getCode())
	sema.library = mw.loadData("Quotations/" .. lang:getCode() .. "/data")
	
	setmetatable(sema, LanguageModule)
	
	-- Have to insert unused self parameter or Lua–PHP interface complains about
	-- table with boolean keys.
	sema.lower = add_self(mw.ustring.lower)
	
	sema.period = '.'
	
	return sema
end

setmetatable(LanguageModule, { __index = function (self, key)
	if key == 'numToIndian' then
		-- This should only be loaded if needed so that [[Module:foreign numerals]]
		-- is not transcluded on every page that [[Module:Quotations]] is.
		local func = require('foreign numerals').to_Indian
		self.numToIndian = func
		return func
	end
end })

function LanguageModule:changeCode(color)
	if color == 'orange' then
		self.code = 'orange'
	end
	if (color == 'yellow') and (self.code == 'green') then
		self.code = 'yellow'
	end
end

function LanguageModule:reroute(route)
	local temp = {}
	local data = self.library.data
	
	for k, v in pairs(route) do
		temp[k] = self:interpret(v)
	end
	
	for k, v in pairs(temp) do
		self[k] = v
	end
	
	if self.author ~= nil and data[self.author] then
		self.aData = data[self.author]
		if self.work ~= nil and self.aData.works[self.work] then
			self.wData = self.aData.works[self.work]
		end
	end
end

function LanguageModule:choose(choice, optionA, optionB)
	optionB = optionB or ''
	choice = self:interpret(choice)
	local chosenPath = {}
	if choice then
		chosenPath = optionA
	else
		chosenPath = optionB
	end
	for j=1, 30 do
		local innerCurrent = chosenPath[j]
		if innerCurrent then
			table.insert(self.refLink, self:interpret(current))
		else
			break
		end
	end
	local ongoingDecision
	decision = self:interpret(decision)
	return decision
end

function LanguageModule:isLetter(input)
	local isit = not tonumber(input)
	return isit
end

function LanguageModule:digits(width, num)
	local decimal = '%' .. width .. 'd'
	return string.format(decimal, num)
end

function LanguageModule:separ(values, separator)
  return table.concat(values, separator)
end

function LanguageModule:roundDown(period, verse)
	if not tonumber(verse) then
		self:changeCode('orange')
	else
		local rounded = math.floor(verse/period) * period
		return rounded
	end
end

function LanguageModule:chapterSelect(rubric, verse)
	verse = tonumber(verse)
	for k,v in pairs(rubric) do
		if v[1] <= verse and verse <= v[2] then
			return k
		end
	end
	self:changeCode('orange')
end

function LanguageModule:interpret(item)
	local output
	
	if type(item) == 'string' then
		if string.len(item) > 1 and string.sub(item, 1, 1) == '.' then
			local address = string.sub(item, 2)
			local returnable = self[address] or self.library.data.Sundry and self.library.data.Sundry[address]
			output = returnable
		else
			output = item
		end
	elseif type(item) == 'table' then
	--If it's a table, it's either a function call or a nested address.
		local presumedFunction = self:interpret(item[1])
		if type(presumedFunction) == 'function' then
			local parameters = {}
			for i = 2, 30 do
				if item[i] ~= nil then
					table.insert(parameters, self:interpret(item[i]))
				else
					break
				end
			end
			output = presumedFunction(self, unpack(parameters))
		else
			local nested = self
			for i = 1, 30 do
				local address = item[i]
				if address and nested then
					nested = nested[address]
				else
					break
				end
			end
			output = nested
		end
	else
		output = item
	end
	
	return output
end

function LanguageModule:convert(scheme, initiate)
	if type(scheme) == "table" then
		local initiate = tonumber(initiate) or initiate
		local converted = scheme[initiate]
		if converted == nil then
			self:changeCode('orange')
		end
		return converted
	end
	if type(scheme) == "function" then
		local initiate = tonumber(initiate) or initiate
		local converted = scheme(initiate)
		if converted == nil then
			self:changeCode('orange')
		end
		return converted
	end
	self:changeCode('orange')
end

function LanguageModule:numToRoman(item)
	local j = tonumber(item)
	if (j == nil) then
		return item
	end
	if (j <= 0) then
		return item
	end

	local ints = {1000, 900,  500, 400, 100,  90, 50,  40, 10,  9,   5,  4,   1}
	local nums = {'M',  'CM', 'D', 'CD','C', 'XC','L','XL','X','IX','V','IV','I'}

	local result = ""
	for k = 1, #ints do
		local count = math.floor(j / ints[k])
		result = result .. string.rep(nums[k], count)
		j = j - ints[k]*count
	end
	return result
end

-- Iterate through "array" and its sublevels. Find indices in "array" that
-- contain a string matching "valToFind". Return last index where that string
-- (minus its first letter) is the key for a field in "self", as well as last
-- index where that string was found.
-- Used to locate the place where the "rlformat" should be skipped out of,
-- because there's no ".ref" value supplied for what comes next.
-- For instance, if book but not line number has been supplied.
local function findLastValidRefIndex(self, array, valToFind)
	local lastValidIndex, lastIndex
	for i, val in ipairs(array) do
		if type(val) == 'table' then
			local res1, res2 = findLastValidRefIndex(self, val, valToFind)
			if res1 then
				lastValidIndex = i
			end
			if res2 then
				lastIndex = i
			end
		elseif type(val) == 'string' and val:find(valToFind) then
			lastIndex = i
			if self[val:sub(2)] then
				lastValidIndex = i
			end
		end
	end
	return lastValidIndex, lastIndex
end

function LanguageModule:expand(args)
	--Instantiate our variables.
	local results = {}
	self.code = 'green'
	local data = self.library.data
	local ultimate = ''

	self.author = args['author'] or args[2]
	self.work = args['work'] or args[3]
	
	for i = 1, 5 do
		local refName = 'ref' .. i
		local paramNumber = i + 3
		self[refName] = args[refName] or args[paramNumber]
	end

	--Check if we've been given an author alias.
	if data.authorAliases[self.author] then
		self.author = data.authorAliases[self.author]
	end

	if not data[self.author] then
		self:changeCode('yellow')
	else
		self.aData = data[self.author]
		if self.aData.reroute then
			self:reroute(self.aData.reroute)
		else
			if self.aData.aliases and self.aData.aliases[self.work] then
				self.work = self.aData.aliases[self.work]
			end
			if not (self.aData.works and self.aData.works[self.work]) then
				self:changeCode('yellow')
			else
				self.wData = self.aData.works[self.work]
				if self.wData.reroute then
					self:reroute(self.wData.reroute)
				end
			end
		end
	end

	--Load all author-level data.
	if self.aData and self.aData.aLink then
		results.author = '[[w:'..self.aData.aLink..'|'..self.author..']]'
	else
		results.author = self.author
	end
	if self.aData and self.aData.year then
		results.year = self.aData.year
	end

	--If the database has a link for the work, incorporate it.
	if not self.wData or not self.wData['wLink'] then
		results.work = self.work
	else
		results.work = '[[w:'..self.wData['wLink']..'|'..self.work..']]'
	end
	
	--Some works have info which overrides the author-level info or fills other parameters.
	if self.wData then
		if self.wData['year'] then
			results.year = self.wData.year
		end
		if self.wData['author'] ~= nil then
			results.author = self.wData.author
		end
		if self.wData['object'] then
			results.object = self.wData.object
		end
		if self.wData['style'] then
			results.style = self.wData.style
		end
	end

	--The displayed reference usually consists of all the ref argument(s) joined with a period.
	self.refDisplay = self.ref1 and '' or (self.wData and self.wData['refDefaultDisplay'] or false)
	local separator_num = 1
	for i = 1, 5 do
		local whichRef = 'ref' .. tostring(i)
		if self[whichRef] then
			local ref = self[whichRef]
			
			local separator
			-- no separator before a letter
			if mw.ustring.match(ref, "^%a$") then
				separator = ""
			-- to allow colon between biblical chapter and verse
			elseif self.aData and self.aData.rdFormat and self.aData.rdFormat.separator then
				separator = self.aData.rdFormat.separator
			elseif self.aData and self.aData.rdFormat and self.aData.rdFormat.separators then
				separator = self.aData.rdFormat.separators[separator_num]
			else
				separator = "."
			end
			
			if i > 1 then
				self.refDisplay = self.refDisplay .. separator
				separator_num = separator_num + 1
			end
			self.refDisplay = self.refDisplay .. self[whichRef]
		else
			break
		end
	end
	if args['through'] then
		args['thru'] = args['through']
	end
	if args['thru'] then
		self.refDisplay = self.refDisplay..'–'..args['thru']
	end
	
	
	
	--[[	If the work is not in the database,
			or we don't have a source text link,
			the ref is simply the display.
			Otherwise, we have to create a reference link,
			easily the most challenging function of this script. ]]
	if self.wData and self.wData['rlFormat'] then
		self.rlFormat = self.aData['rlFormat'..tostring(self.wData.rlFormat)]
		if self.rlFormat then
			self.rlTitle = self.wData['rlTitle']
			
			-- Go through indices in "self.rlFormat" that contain a string
			-- beginning in ".ref" (either in the first level of "self.rlFormat"
			-- or a sublevel). Return the index of the string that has a
			-- corresponding field in "self", as well as the index of the last
			-- such string.
			local lastValidIndex, lastIndex = findLastValidRefIndex(self, self.rlFormat, '^%.ref(%d+)$')
			-- If there isn't another ".ref" string after the last valid index,
			-- then there is no need to cut short the rlFormat.
			local indexToStopAt
			if lastIndex and lastValidIndex and lastIndex > lastValidIndex then
				indexToStopAt = lastValidIndex
			else
				indexToStopAt = math.huge
			end
			
			self.refLink = {}
			for i, current in ipairs(self.rlFormat) do
				if i > indexToStopAt then
					break
				end
				
				table.insert(self.refLink, self:interpret(current))
			end
			self.refLink = table.concat(self.refLink)
		end
	end
	if self.wData and self.wData['xrlFormat'] then
		self.xrlFormat = self.aData['xrlFormat'..tostring(self.wData.xrlFormat)]
		if self.xrlFormat then
			self.xurl = self.wData['xurl']
			-- Go through indices in "self.xrlFormat" that contain a string
			-- beginning in ".ref" (either in the first level of "self.xrlFormat"
			-- or a sublevel). Return the index of the string that has a
			-- corresponding field in "self", as well as the index of the last
			-- such string.
			local lastValidIndex, lastIndex = findLastValidRefIndex(self, self.xrlFormat, '^%.ref(%d+)$')
			-- If there isn't another ".ref" string after the last valid index,
			-- then there is no need to cut short the rlFormat.
			local indexToStopAt
			if lastIndex and lastValidIndex and lastIndex > lastValidIndex then
				indexToStopAt = lastValidIndex
			else
				indexToStopAt = math.huge
			end
			
			self.xrefLink = {}
			for i, current in ipairs(self.xrlFormat) do
				if i > indexToStopAt then
					break
				end
				
				table.insert(self.xrefLink, self:interpret(current))
			end
			self.xrefLink = table.concat(self.xrefLink)
		end
	end
 	if self.refLink and self.refDisplay then
		results.ref = '[['..self.refLink..'|'..self.refDisplay..']]'
	elseif self.xrefLink and self.refDisplay then
		results.ref = '['..self.xrefLink..' '..self.refDisplay..']'
	else
		results.ref = self.refDisplay or ''
	end
	if args['notes'] then
		results.notes = args.notes
	end
	results.code = self.code
	
	return results

end

return export