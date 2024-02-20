local export = {numbers = {}}

-- Automatically create new subtables of export.numbers through __index,
-- automatically add new fields of export.numbers
-- without overwriting old ones through __newindex.
local actual_numbers = export.numbers

local namespace = mw.title.getCurrentTitle().nsText
local function log(...)
	if namespace == "Module" then
		mw.log(...)
	end
end

local proxy_number_metatable = {
	__newindex = function (self, k, v)
		local old = rawget(self.__actual, k)
		if old then
			log("k: " .. k .. "; old " .. old .. "; new " .. v .. "; old == new: " .. tostring(old == v))
		end
		
		if type(old) == "table" then
			table.insert(old, v)
		elseif type(old) == "string" then
			if old ~= v then
				rawset(self.__actual, k, { old, v })
			end
		else
			rawset(self.__actual, k, v)
		end
	end,
	__index = function (self, k)
		return rawget(self.__actual, k)
	end,
}

local proxy_subtables = {}
local function get_proxy_number_table(k, actual_table)
	local t = proxy_subtables[k]
	if not t then
		t = setmetatable({ __actual = actual_table }, proxy_number_metatable)
		proxy_subtables[k] = t
	end
	return t
end

local function get_actual_number_table(k)
	local t = actual_numbers[k]
	if not t then
		t = {}
		actual_numbers[k] = t
	end
	return t
end

local proxy_numbers = setmetatable({}, {
	__newindex = function (self, k1, fields)
		local subtable = get_actual_number_table(k1)
		local proxy_subtable = get_proxy_number_table(k1, subtable)
		if not proxy_subtable then
			proxy_subtable = new_proxy_number_table(subtable)
			mw.log("new proxy_subtable for " .. k1)
			rawset(proxy_subtables, k1, proxy_subtable)
		end
		for k, v in pairs(fields) do
			proxy_subtable[k] = v
		end
	end,
	__index = function (self, k)
		local actual_table = get_actual_number_table(k)
		local proxy_table = get_proxy_number_table(k, actual_table)
		return proxy_table
	end,
})
local numbers = proxy_numbers

local adverbial_suffix = "ჯერ"
local multiplier_suffix = "მაგი"
local distributive_suffix = "ად"
local collective_suffix = "ვე"
local fractional_suffix = "დი"

numbers[0].cardinal = "ნული"

numbers[1] = {
	cardinal = "ერთი",
	ordinal = "პირველი",
	multiplier = "ერთმაგი",
	distributive = "ერთმაგად",
	adverbial = "ერთხელ",
	collective = "ერთივე",
	fractional = { "მთლიანი", "სრული", "ერთიანი" },
}

numbers[2] = {
	cardinal = "ორი",
	multiplier = "ორმაგი",
	distributive = "ორმაგად",
	adverbial = "ორჯერ",
	collective = "ორივე",
	fractional = "ნახევარი", -- regular fractional added below
}

numbers[3] = {
	cardinal = "სამი",
	distributive = "სამმაგად",
	adverbial = "სამჯერ",
	collective = "სამივე",
	fractional = "მესამედი",
}

numbers[4] = {
	cardinal = "ოთხი",
	distributive = "ოთხმაგად",
	adverbial = "ოთხჯერ",
	collective = "ოთხივე",
	fractional = "მეოთხედი",
}

numbers[5] = {
	cardinal = "ხუთი",
	distributive = "ხუთმაგად",
	adverbial = "ხუთჯერ",
	collective = "ხუთივე",
	fractional = "მეხუთედი",
}

numbers[6] = {
	cardinal = "ექვსი",
	distributive = "ექვსმაგად",
	adverbial = "ექვსჯერ",
	collective = "ექვსივე",
	fractional = "მეექვსედი",
}

numbers[7] = {
	cardinal = "შვიდი",
	distributive = "შვიდმაგად",
	adverbial = "შვიდჯერ",
	collective = "შვიდივე",
	fractional = "მეშვიდედი",
}

numbers[8] = {
	cardinal = "რვა",
	distributive = "რვამაგად",
	adverbial = "რვაჯერ",
	collective = "რვავე",
	fractional = "მერვედი",
}

numbers[9] = {
	cardinal = "ცხრა",
	distributive = "ცხრამაგად",
	adverbial = "ცხრაჯერ",
	collective = "ცხრავე",
	fractional = "მეცხრედი",
}

numbers[10] = {
	cardinal = "ათი",
	distributive = "ათმაგად",
	adverbial = "ათჯერ",
	collective = "ათივე",
	fractional = "მეათედი",
}

numbers[11] = {
	cardinal = "თერთმეტი",
	multiplier = "თერთმეტმაგი",
	distributive = "თერთმეტმაგად",
	adverbial = "თერთმეტჯერ",
	collective = "თერთმეტივე",
	fractional = "მეთერთმეტედი",
}

numbers[12] = {
	cardinal = "თორმეტი",
	multiplier = "თორმეტმაგი",
	distributive = "თორმეტმაგად",
	adverbial = "თორმეტჯერ",
	collective = "თორმეტივე",
	fractional = "მეთორმეტედი",
}

numbers[13] = {
	cardinal = "ცამეტი",
	multiplier = "ცამეტმაგი",
	distributive = "ცამეტმაგად",
	adverbial = "ცამეტჯერ",
	collective = "ცამეტივე",
	fractional = "მეცამეტედი",
}

numbers[14] = {
	cardinal = "თოთხმეტი",
	multiplier = "თოთხმეტმაგი",
	distributive = "თოთხმეტმაგად",
	adverbial = "თოთხმეტჯერ",
	collective = "თოთხმეტივე",
	fractional = "მეთოთხმეტედი",
}

numbers[15] = {
	cardinal = "თხუთმეტი",
	multiplier = "თხუთმეტმაგი",
	distributive = "თხუთმეტმაგად",
	adverbial = "თხუთმეტჯერ",
	collective = "თხუთმეტივე",
	fractional = "მეთხუთმეტედი",
}

numbers[16] = {
	cardinal = "თექვსმეტი",
	multiplier = "თექვსმეტმაგი",
	distributive = "თექვსმეტმაგად",
	adverbial = "თექვსმეტჯერ",
	collective = "თექვსმეტივე",
	fractional = "მეთექვსმეტედი",
}

numbers[17] = {
	cardinal = "ჩვიდმეტი",
	multiplier = "ჩვიდმეტმაგი",
	distributive = "ჩვიდმეტმაგად",
	adverbial = "ჩვიდმეტჯერ",
	collective = "ჩვიდმეტივე",
	fractional = "მეჩვიდმეტედი",
}

numbers[18] = {
	cardinal = "თვრამეტი",
	multiplier = "თვრამეტმაგი",
	distributive = "თვრამეტმაგად",
	adverbial = "თვრამეტჯერ",
	collective = "თვრამეტივე",
	fractional = "მეთვრამეტედი",
}

numbers[19] = {
	cardinal = "ცხრამეტი",
	multiplier = "ცხრამეტმაგი",
	distributive = "ცხრამეტმაგად",
	adverbial = "ცხრამეტჯერ",
	collective = "ცხრამეტივე",
	fractional = "მეცხრამეტედი",
}


numbers[20].multiplier = "ოც" .. multiplier_suffix

local function remove_final_vowel(word)
	return (mw.ustring.gsub(word, "[აეიოუ]$", ""))
end

local function remove_final_i(word)
	return word:gsub("ი$", "")
end

local function get_cardinal(number)
	return numbers[number].cardinal
end

local function get(number, type)
	return numbers[number][type]
end

local function circumfix_ordinal(cardinal)
	return "მე" .. remove_final_vowel(cardinal) .. "ე"
end

for number = 2, 19 do
	numbers[number].ordinal = circumfix_ordinal(get_cardinal(number))
end

for number = 1, 10 do
	numbers[number].adverbial = remove_final_i(get_cardinal(number))
		.. adverbial_suffix
end

for number = 2, 10 do
	numbers[number].multiplier = remove_final_i(get_cardinal(number))
		.. multiplier_suffix
	
	numbers[number].distributive = remove_final_i(get(number, "multiplier"))
		.. distributive_suffix
	
	numbers[number].collective = get_cardinal(number)
		.. collective_suffix
	
	numbers[number].fractional = remove_final_i(get(number, "ordinal"))
		.. fractional_suffix
end

local twenty = "ოცი"
-- Add cardinals and ordinals for 20-99.
for i = 1, 4 do
	local twenties = i * 20
	local twenties_cardinal
	if i ~= 1 then
		twenties_cardinal = (remove_final_vowel(get_cardinal(i)) .. "მ" .. twenty)
			:gsub("მმ", "მ")
	else
		twenties_cardinal = twenty
	end
	numbers[twenties] = {
		cardinal = twenties_cardinal,
		ordinal = circumfix_ordinal(twenties_cardinal),
	}
	
	local twenties_and = remove_final_vowel(twenties_cardinal) .. "და"
	
	for ones = 1, 19 do
		numbers[twenties + ones] = {
			cardinal = twenties_and .. get_cardinal(ones),
			ordinal = twenties_and .. circumfix_ordinal(get_cardinal(ones)),
		}
	end
end

local hundred_cardinal = "ასი"
numbers[100].multiplier = "ას" .. multiplier_suffix

for i = 1, 10 do
	local cardinal
	if i == 1 then
		cardinal = hundred_cardinal
	else
		cardinal = remove_final_vowel(get_cardinal(i)) .. hundred_cardinal
	end
	numbers[i * 100] = {
		cardinal = cardinal,
		ordinal = circumfix_ordinal(cardinal), -- is this right?
	}
end

numbers[1000].multiplier = "ათას" .. multiplier_suffix

numbers[1000000] = {
	cardinal = "მილიონი",
	ordinal = "მემილიონე"
}

return export