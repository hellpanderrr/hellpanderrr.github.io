local export = {}
 
local rsubn = mw.ustring.gsub

-- version of rsubn() that discards all but the first return value
local function rsub(term, foo, bar)
	local retval = rsubn(term, foo, bar)
	return retval
end

local regular_tt = {
	["А"]='A', ["а"]='a', ["Б"]='B', ["б"]='b', ["В"]='V', ["в"]='v', ["Г"]='H', ["г"]='h', 
	["Ґ"]='G', ["ґ"]='g', ["Д"]='D', ["д"]='d', ["Е"]='E', ["е"]='e', ["Є"]='Je', ["є"]='je', 
	["Ж"]='Ž', ["ж"]='ž', ["З"]='Z', ["з"]='z', ["И"]='Y', ["и"]='y', ["І"]='I', ["і"]='i', 
	["Ї"]='Ji', ["ї"]='ji', ["Й"]='J', ["й"]='j', ["К"]='K', ["к"]='k', ["Л"]='L', ["л"]='l', 
	["М"]='M', ["м"]='m', ["Н"]='N', ["н"]='n', ["О"]='O', ["о"]='o', ["П"]='P', ["п"]='p', 
	["Р"]='R', ["р"]='r', ["С"]='S', ["с"]='s', ["Т"]='T', ["т"]='t', ["У"]='U', ["у"]='u', 
	["Ф"]='F', ["ф"]='f', ["Х"]='X', ["х"]='x', ["Ц"]='C', ["ц"]='c', ["Ч"]='Č', ["ч"]='č', 
	["Ш"]='Š', ["ш"]='š', ["Щ"]='Šč', ["щ"]='šč', ["Ь"]='ʹ', ["ь"]='ʹ', ["Ю"]='Ju', ["ю"]='ju', 
	["Я"]='Ja', ["я"]='ja', 
	-- right single quotation mark, modifier letter apostrophe → modifier letter double prime
	["’"]='ʺ', ["ʼ"]= 'ʺ', 
	-- Ukrainian style quotes
	['«']='“', ['»']='”',
	-- Special char used in [[ₚосія]]
	['ₚ']='ᵣ',
}

-- These need to be separated from the `regular_tt` so they don't interfere with reverse translit.
local obsolete_tt = {
	-- obsolete letters, pre-refom
	["Ё"]='Ë', ["ё"]='ë', ["Ъ"]='ʺ', ["ъ"]='ʺ', ["Ы"]='Y', ["ы"]='y', ["Ѣ"]='I', ["ѣ"]='i', 
	["Э"]='È', ["э"]='è', ["Ј"]='J', ["ј"]='j',
	-- obsolete letters, Middle Ukrainian
	["Ѥ"]='Je', ["ѥ"]='je', ["Ъ"]='ʺ', ["ъ"]='ʺ', ["Ы"]='Y', ["ы"]='y', ["Ѣ"]='I', ["ѣ"]='i', 
	["Ѧ"]='Ja', ["ѧ"]='ja', ["Ѩ"]='Ja', ["ѩ"]='ja', ["Ѫ"]='U', ["ѫ"]='u', ["Ѭ"]='Ju', ["ѭ"]='ju', 
	["Ѯ"]='Ks', ["ѯ"]='ks', ["Ѱ"]='Ps', ["Ѱ"]='ps', ["Ѳ"]='F', ["ѳ"]='f', ["Ѵ"]='I', ["ѵ"]='i', 
	["Ѡ"]='O', ["ѡ"]='o', 
}

local AC = mw.ustring.char(0x0301) -- acute =  ́
local acute_decomposer = {
	["á"] = "a" .. AC,
	["é"] = "e" .. AC,
	["í"] = "i" .. AC,
	["ó"] = "o" .. AC,
	["ú"] = "u" .. AC,
	["ý"] = "y" .. AC,
	["Á"] = "A" .. AC,
	["É"] = "E" .. AC,
	["Í"] = "I" .. AC,
	["Ó"] = "O" .. AC,
	["Ú"] = "U" .. AC,
	["Ý"] = "Y" .. AC,
}


function export.tr(text, lang, sc)--translit any words or phrases
	-- Remove word-final hard sign, either utterance-finally or followed by
	-- a non-letter character such as space, comma, period, hyphen, etc.
	text = rsub(text, "[Ъъ]$", "")
	text = rsub(text, "[Ъъ]([%A])", "%1")

	text = rsub(text, "'+", { ["'"] = 'ʺ' }) -- neutral apostrophe
	text = rsub(text, '.', regular_tt)
	text = rsub(text, '.', obsolete_tt)

	return text
end


function export.reverse_tr(text)--reverse-translit any words or phrases
	local reverse_tt = {}
	for k, v in pairs(regular_tt) do
		reverse_tt[v] = k
	end
	reverse_tt['ʺ'] = "'"
	reverse_tt['ʹ'] = "ь"
	reverse_tt['y'] = "и"
	reverse_tt['Y'] = "И"
	text = rsub(text, '.', acute_decomposer)
	text = rsub(text, '[Jj][aeiu]', reverse_tt)
	text = rsub(text, '[Šš]č', reverse_tt)
	text = rsub(text, '.', reverse_tt)
	return text
end

return export