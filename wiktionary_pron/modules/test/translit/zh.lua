local M = {}

local codepoint = mw.ustring.codepoint
local find = mw.ustring.find
local len = mw.ustring.len
local sub = mw.ustring.sub
local u = mw.ustring.char

local m_ts = mw.loadData("zh/data/ts")
local m_st = mw.loadData("zh/data/st")
local lang = require("languages").getByCode("zh")

function M.ts_determ(f)
	local text = type(f) == "table" and f.args[1] or f
	local sc = lang:findBestScript(text):getCode()
	return sc == "Hani" and "both" or sc == "Hant" and "trad" or "simp"
end

function M.ts(f)
	local text = type(f) == "table" and f.args[1] or f
	return (text:gsub("[\194-\244][\128-\191]*", m_ts))
end

function M.st(f)
	local text = type(f) == "table" and f.args[1] or f
	return (text:gsub("[\194-\244][\128-\191]*", m_st))
end

function M.py(text, comp, pos, p, is_erhua)
	local m_cmn_pron = mw.loadData("zh/data/cmn-pron")
	if not is_erhua then is_erhua = false end
	if type(text) == "table" then
		text, comp, pos, p, is_erhua = text.args[1], text.args[2], text.args[3], text.args[4], text.args[5]
	end
	comp = comp or ''
	local q = {}
	local sum = 0
	local length = len(text)
	if is_erhua then length = length - 1 end
	local textconv = text
	text = ''
	if comp ~= '' and comp ~= '12' and comp ~= '21' and not ((pos == 'cy' or pos == 'Idiom' or pos == 'idiom') and length == 4) and not is_erhua then
		for i = 1, len(comp) do
			sum = sum + tonumber(sub(comp,i,i))
			q[sum] = 'y'
		end
	end
	if not p then p={} end
	local initial = true
	for i = 1, length do
		if p[i] and p[i] ~= '' then --pronunciation supplied
			text = text .. p[i]
		else
			local char = sub(textconv,i,i)
			char = m_cmn_pron.py[char] or m_cmn_pron.py[M.ts(char)] or char
			if not is_erhua and not initial and find(char,'^[aoeāōēáóéǎǒěàòè]') then
				text = text .. "&#39;"
			end
			text = text .. char
			
			initial = char == sub(textconv,i,i)
				and sub(textconv,i-3,i) ~= "</b>" --checks for closing bold tag
				and (i-2 == 1 or sub(textconv,i-2,i) ~= "<b>" or sub(textconv,i-3,i) == "^<b>") --checks for opening bold tag
				and (i-3 == 1 or sub(textconv,i-3,i) ~= "^<b>") --checks for opening bold tag with capitalization
		end
		if q[i] == 'y' and i ~= length and not is_erhua then text = text .. ' ' end
	end
	text = text:gsub("<b>&#39;", "&#39;<b>") --fix bolding of apostrophe
	
	if is_erhua then text = text .. 'r' end
	if pos == 'pn' or pos == 'propn' then
		local characters = mw.text.split(text,' ')
		for i=1,#characters do
			characters[i] = mw.language.getContentLanguage():ucfirst(characters[i])
		end
		text = table.concat(characters,' ')
	end
	return text
end

-- function M.py_er(text,comp,pos,p)
-- 	return M.py(text,comp,pos,p,true)
-- end

function M.check_pron(text, variety, length)
	if type(text) == "table" then
		text, variety = text.args[1], text.args[2]
	end
	if not text then
		return
	end
	local startpoint, address = { ['yue'] = 51, ['hak'] = 19968, ['nan'] = 19968 }, { ['yue'] = 'yue-word/%03d', ['hak'] = 'hak-pron/%02d', ['nan'] = 'nan-pron/%03d' }
	local unit = 1000
	local first_char = sub(text, 1, 1)
	local result, success, data
	if length == 1 and variety == "yue" then
		success, data = pcall(mw.loadData, 'Module:zh/data/Jyutping character')
	else
		local page_index = math.floor((codepoint(first_char) - startpoint[variety]) / unit)
		success, data = pcall(mw.loadData,
			('Module:zh/data/' .. address[variety]):format(page_index)
		)
	end
	if success then
		result = data[text] or false
	else
		result = false
	end
	return result
end

return M