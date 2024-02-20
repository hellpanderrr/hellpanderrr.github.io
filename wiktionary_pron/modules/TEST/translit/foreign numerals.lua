local export = {}

-- Roman numerals

local from_Roman_tab = {
	M  = 1000; CM = 900; D  = 500; CD = 400;
	C  =  100; XC =  90; L  =  50; XL =  40;
	X  =   10; IX =   9; V  =   5; IV =   4;
	I  =    1;
}

local to_Roman_tab = {
	{ 1000, "M"  }; {  900, "CM" }; {  500, "D"  }; {  400, "CD" };
	{  100, "C"  }; {   90, "XC" }; {   50, "L"  }; {   40, "XL" };
	{   10, "X"  }; {    9, "IX" }; {    5, "V"  }; {    4, "IV" };
	{    1, "I"  };
}

local new_to_Roman_tab = {}

local overline = mw.ustring.char(0x305)
local double_overline = mw.ustring.char(0x33F)
for _, v in ipairs(to_Roman_tab) do
	local number, symbol = unpack(v)
	if number > 1 then
		table.insert(new_to_Roman_tab, { number * 1000, (symbol:gsub(".", "%1" .. overline)) })
		table.insert(new_to_Roman_tab, { number * 1000000, (symbol:gsub(".", "%1" .. double_overline)) })
	end
end

for _, v in ipairs(to_Roman_tab) do
	table.insert(new_to_Roman_tab, v)
end

to_Roman_tab = new_to_Roman_tab

function export.to_Roman(numeral)
	if type(numeral) == 'table' then
		numeral = tonumber(numeral.args[1])
	else
		-- accept strings for use by [[Module:number list/data/la]], which is invoked from [[Module:number list]]
		-- with the number in string format to allow for very large numbers
		numeral = tonumber(numeral)
	end
	
	local output = {}
	for _, item in ipairs(to_Roman_tab) do
		local limit, letter = item[1], item[2]
		while numeral >= limit do
			table.insert(output, letter)
			numeral = numeral - limit
		end
	end

	return table.concat(output)
end

function export.from_Roman(numeral)
	if type(numeral) == 'table' then
		numeral = numeral.args[1]
	end
	if tonumber(numeral) then
		return tonumber(numeral)	
	end
	
	local accum = 0
	-- shame on Lua for having no regex alternations...

	while numeral ~= "" do
		local l2, l1 = numeral:sub(1, 2), numeral:sub(1, 1)
		if from_Roman_tab[l2] then
			accum = accum + from_Roman_tab[l2]
			numeral = numeral:sub(3)
		elseif from_Roman_tab[l1] then
			accum = accum + from_Roman_tab[l1]
			numeral = numeral:sub(2)
		else
			return nil
		end
	end
	
	return accum
end

-- Armenian numerals

local from_Armenian_tab = {
	["Ա"] =    1; ["Բ"] =    2; ["Գ"] =    3; ["Դ"] =    4; ["Ե"] =    5; ["Զ"] =    6; ["Է"] =    7; ["Ը"] =    8; ["Թ"] =    9;
	["Ժ"] =   10; ["Ի"] =   20; ["Լ"] =   30; ["Խ"] =   40; ["Ծ"] =   50; ["Կ"] =   60; ["Հ"] =   70; ["Ձ"] =   80; ["Ղ"] =   90;
	["Ճ"] =  100; ["Մ"] =  200; ["Յ"] =  300; ["Ն"] =  400; ["Շ"] =  500; ["Ո"] =  600; ["Չ"] =  700; ["Պ"] =  800; ["Ջ"] =  900;
	["Ռ"] = 1000; ["Ս"] = 2000; ["Վ"] = 3000; ["Տ"] = 4000; ["Ր"] = 5000; ["Ց"] = 6000; ["Ւ"] = 7000; ["Փ"] = 8000; ["Ք"] = 9000;
}

function export.from_Armenian(numeral)
	if type(numeral) == 'table' then
		numeral = numeral.args[1]
	end
	if tonumber(numeral) then
		return tonumber(numeral)	
	end

	local accum = 0
	for cp in mw.ustring.gcodepoint(numeral) do
		local value = from_Armenian_tab[mw.ustring.char(cp)]
		if value then
			accum = accum + value
		else
			return nil
		end
	end

	return accum	
end

-- Hebrew numerals

local from_Hebrew_tab = {
	['א'] = 1,
	['ב'] = 2,
	['ג'] = 3,
	['ד'] = 4,
	['ה'] = 5,
	['ו'] = 6,
	['ז'] = 7,
	['ח'] = 8,
	['ט'] = 9,
	['י'] = 10,
	['כ'] = 20,
	['ך'] = 20,
	['ל'] = 30,
	['מ'] = 40,
	['ם'] = 40,
	['נ'] = 50,
	['ן'] = 50,
	['ס'] = 60,
	['ע'] = 70,
	['פ'] = 80,
	['ף'] = 80,
	['צ'] = 90,
	['ץ'] = 90,
	['ק'] = 100,
	['ר'] = 200,
	['ש'] = 300,
	['ת'] = 400,
}

local to_Hebrew_ones = {[0] = '', 'א', 'ב', 'ג', 'ד', 'ה', 'ו', 'ז', 'ח', 'ט'}
local to_Hebrew_tens = {[0] = '', 'י', 'כ', 'ל', 'מ', 'נ', 'ס', 'ע', 'פ', 'צ'}
local to_Hebrew_hundreds = {[0] = '', 'ק', 'ר', 'ש', 'ת', 'תק', 'תר', 'תש', 'תת', 'תתק'}
local to_Hebrew_special = {
	[15] = 'טו',
	[16] = 'טז',
}

-- This only works for numbers such that 0 < value < 1000, because beyond that the logic gets complicated
function export.from_Hebrew(numeral)
	if type(numeral) == 'table' then
		numeral = numeral.args[1]
	end
	if tonumber(numeral) then
		return tonumber(numeral)
	end

	local value = 0
	for c in mw.ustring.gmatch(numeral, '[א-ת]') do
		value = value + (from_Hebrew_tab[c] or 0)
	end

	if value == 0 then
		return nil
	end

	return value
end

-- This only works for numbers such that 0 < value < 1000, because beyond that the logic gets complicated
function export.to_Hebrew(value, use_gershayim)
	if type(value) == 'table' then
		use_gershayim = value.args[2] ~= '' and value.args[2]
		value = value.args[1]
	end
	if type(value) ~= 'number' then
		if tonumber(value) then
			value = tonumber(value)
		else
			return nil
		end
	end

	if value <= 0 or value >= 1000 then
		return nil
	end

	local tens_and_ones = value % 100
	local hundreds = to_Hebrew_hundreds[(value - tens_and_ones) / 100]
	if to_Hebrew_special[tens_and_ones] then
		tens_and_ones = to_Hebrew_special[tens_and_ones]
	else
		local ones = tens_and_ones % 10
		local tens = (tens_and_ones - ones) / 10
		tens_and_ones = to_Hebrew_tens[tens] .. to_Hebrew_ones[ones]
	end

	local numeral = hundreds .. tens_and_ones

	if use_gershayim then
		if mw.ustring.match(numeral, '^.$') then
			numeral = numeral .. '׳'
		else
			numeral = mw.ustring.gsub(numeral, '.$', '״%0')
		end
	end

	return numeral
end

-- Indian numerals

function export.from_Indian(numeral)
	if type(numeral) == 'table' then
		value = numeral.args[1]
	else
		value = numeral
	end
	text = mw.ustring.gsub(
		tostring(value),
		'.',
		{
			['०'] = '0',
			['१'] = '1',
			['२'] = '2',
			['३'] = '3',
			['४'] = '4',
			['५'] = '5',
			['६'] = '6',
			['७'] = '7',
			['८'] = '8',
			['९'] = '9',
		}
	)
	return text
end

function export.to_Indian(numeral)
	if type(numeral) == 'table' then
		value = numeral.args[1]
	else
		value = numeral
	end
	text = mw.ustring.gsub(
		tostring(value),
		'.',
		{
			[0] = '०',
			[1] = '१',
			[2] = '२',
			[3] = '३',
			[4] = '४',
			[5] = '५',
			[6] = '६',
			[7] = '७',
			[8] = '८',
			[9] = '९',
		}
	)
	return text
end

return export