local M = {}

local len = mw.ustring.len
local sub = mw.ustring.sub
local gsub = mw.ustring.gsub
local match = mw.ustring.match
local find = mw.ustring.find
local cmn_pron = nil

function M.extract_pron(title, variety, cap)
	-- if title contains the asterisk "*" that disables everything fancy
	-- like [[t:ltc-l]]
	-- then stop early instead of trying to :getContent()
	-- (wtf?)
	if string.find(title, "*") then
		return
	end

	local tr = nil
	local title = mw.title.new(title)
	local content = title:getContent()
	local cat = nil
	if content then
		content = gsub(content, ",([^ ])", ";%1")
		local template = match(content, "{{zh%-pron[^}]*| ?" .. variety .. "=([^};|\n]+)")
		cap = cap or find(content, "{{zh%-pron[^}]*| ?" .. variety .. "=([^}|\n]+);cap%=y")
		if template and template ~= "" then
			if cmn_pron == nil then
			   cmn_pron = require("cmn-pron")
			end
			tr = cmn_pron.str_analysis(template, 'link')
		end
	else
		cat = "[[Category:Chinese redlinks/zh-l]]"
	end
	if cap then
		tr = gsub(tr, '^(.)', mw.ustring.upper)
	end
	return tr, cat
end

function M.extract_gloss(content, useetc)
	local senses = {}
	local len = mw.ustring.len
	local literally = match(content, 'zh%-forms[^}]*|lit=([^{|}]+)[|}]')
	local sense_id = 0
	local etc = false
	local translingual_section, zh_section, j, pos, section
	while true do
		-- Find language sections beginning with ==...== and ending with the same
		-- or an empty string. Grab the Chinese and Translingual ones.
		_, j, language_name, section = content:find("%f[=]==%s*([^=]+)%s*==(\n.-)\n==%f[^=]", pos)
		
		if j == nil then
			i, j, language_name, section = content:find("%f[=]==%s*([^=]+)%s*==(\n.+)", pos)
		end
		
		if j == nil then
			break
		else
			-- Move to the beginning of "==" at the end of the current match.
			pos = j - 1
		end
		
		if language_name == 'Translingual' then
			translingual_section = section
		elseif language_name == 'Chinese' then
			zh_section = section
			break
		end
	end
	
	if not zh_section then
		zh_section = translingual_section
		if not zh_section then
			return ""
		end
	elseif translingual_section then -- also use translingual section if Chinese section contains only rfdef
		zh_section = zh_section..translingual_section
	end

	-- Delete etymology and glyph origin sections, 
	-- because they sometimes contain ordered lists,
	-- which would then be interpreted as definitions.
	zh_section = zh_section:gsub("\n===+Etymology.-(\n==)", "%1")
	zh_section = zh_section:gsub("\n===+Glyph origin.-(\n==)", "%1")
	
	for sense in zh_section:gmatch('\n# ([^\n]+)') do
		if not sense:match('rfdef') and not sense:match('defn') then
			sense_id = sense_id + 1
			if sense_id > 2 then
				etc = true
				break
			end
			table.insert(senses, sense)
		end
	end
	gloss_text = (literally and literally .. "; " or "") .. (senses[1] or "")
	local gloss_text_extend = gloss_text .. (senses[2] and "; " .. senses[2] or "")
	gloss_text = (len(gloss_text) < 80 and len(gloss_text_extend) < 160) and gloss_text_extend or gloss_text
	if gloss_text ~= gloss_text_extend then etc = true end

	local function replace_gloss(text)
		local function replace_wp(text)
			return text:gsub('{{w|([^|}]+)|?([^|}]*)}}',
				function(w_link, w_display)
					return '[[w:'..w_link..'｜'..(w_display~='' and w_display or w_link)..']]'
			end)
		end
		
		if text:find("{{") then
			text = replace_wp(text)
			text = text:gsub(' %({{taxlink[^}%)]+}}%)', '')
				:gsub('{{zh%-l|%*([^}]*)}}', '%1')
				:gsub('{{lb|zh|[^}]*}}', '')
				:gsub('{{zh%-erhua form of|word=[^}]+}}', '')
				:gsub('{{zh%-erhua form of|([^}]+)}}', '%1')
				:gsub('{{zh%-alt%-name|[^}]+|([^\n]+)}}', '%1')
				:gsub('{{zh%-short%-comp|[^}]+|t=([^\n}|]+)[^}]*}}', '%1')
				:gsub('{{zh%-short%-comp|[^}]+}}', '')
				:gsub('{{zh%-classifier|[^}]+|t=([^\n}|]+)[^}]*}}', '%1')
				:gsub('{{zh%-classifier|[^}]+}}', '')
				:gsub('{{zh%-alt%-form|[^}]+}}', '')
				:gsub('{{zh%-[^dm|}][^|}]+|[^|}]+|([^\n}|]+)}}', '%1')
				:gsub('{{vern', '{{w')
				:gsub('%b{}', function(matched_braces)
					if matched_braces:find("^{{place|zh|") then
						local template_name, template_args = require "template parser".parseTemplate(matched_braces)
						if template_name then
							return template_args.t or template_args.t1
						end
					end
				end)
				:gsub('｜', "|")
		end
		text = text:gsub('( ?)([{%(]+[^}%){%(]+[}%)]+)', function(space, captured)
			local taxlink = captured:match("{{taxlink|([^|}]+)")
			local wiki_link = 
				 taxlink and "''" .. taxlink .. "''" or 
				(match(captured, "({{w|.+}})") or false)
			return wiki_link and space..wiki_link or "" end)
		text = mw.text.split(text, ';')
		local text_sec = {}
		for _, s in ipairs(text) do
			if s:find'%w' then
				table.insert(text_sec, (s:gsub('^%s+',''):gsub('%s+$','')))
			end
		end
		return table.concat(text_sec, '; ')
	end
	gloss_text = replace_gloss(gloss_text)
	gloss_text = replace_gloss(gloss_text)
	if etc and useetc and gloss_text ~= "" then
		gloss_text = gloss_text .. "; etc."
	end
	if gloss_text:find("{{") or gloss_text:find("}}") or gloss_text:find("=") then --temporary solution to suppress wikitext issues
		gloss_text = ""
	end
	return gloss_text
end

return M