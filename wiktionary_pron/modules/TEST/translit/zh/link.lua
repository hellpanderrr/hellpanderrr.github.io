local M = {}

local len = mw.ustring.len
local sub = mw.ustring.sub
local gsub = mw.ustring.gsub
local match = mw.ustring.match
local find = mw.ustring.find

local function format_Chinese_text(text) return '<span class="Hani" lang="zh">' .. text .. '</span>' end
local function format_Chinese_text_trad(text) return '<span class="Hant" lang="zh-Hant">' .. text .. '</span>' end
local function format_Chinese_text_simp(text) return '<span class="Hans" lang="zh-Hans">' .. text .. '</span>' end
local function format_rom(text) return text and '<i><span class="tr Latn">' .. text .. '</span></i>' or nil end
local function format_gloss(text) return text and '“' .. text .. '”' or nil end

function M.link(frame, mention, args, pagename, no_transcript)
	if (args and args[1] == '') or (frame and frame:getParent().args and frame:getParent().args[1] == '') then
		return ''
	end

	local params = {
		[1] = {},
		[2] = {},
		[3] = {},
		[4] = {},
		['gloss'] = {},
		['tr'] = {},
		['lit'] = {},
		['t'] = { alias_of = 'gloss' },
	}

	if mention then
		params['note'] = {}
	end

	local moduleCalled
	if args then
		moduleCalled = true
	end
	args = args or frame:getParent().args
	if not moduleCalled then
		params[1].required = true
	end
	args = require("parameters").process(args, params)
	if moduleCalled then
		if not args[1] then
			return ""
		end
	end
	pagename = pagename or mw.title.getCurrentTitle().text

	local text, tr, gloss, cat

	if args[2] and match(args[2], '[一-龯㐀-䶵]') then
		gloss = args[4]
		tr = args[3]
		text = args[1] .. '/' .. args[2]
	else
		text = args[1]
		if args['gloss'] then
			tr = args[2]
			gloss = args['gloss']
		else
			if args[3] or (args[2] and (match(args[2], '[āōēīūǖáóéíúǘǎǒěǐǔǚàòèìùǜâêîôû̍ⁿ]') or match(args[2], '[bcdfghjklmnpqrstwz]h?y?[aeiou][aeiou]?[iumnptk]?g?[1-9]'))) then
				tr = args[2]
				gloss = args[3]
			else
				gloss = args[2]
			end
		end
	end
	if args['tr'] then
		tr = args['tr']
		gloss = gloss or args[2]
	end
	if text then
		if not text:match'%[%[.+%]%]' then
			local m_zh = require("zh")
			local words = mw.text.split(text, "/", true)
			if #words == 1 and m_zh.ts_determ(words[1]) == 'trad' and not match(words[1], '%*') then
				table.insert(words, m_zh.ts(words[1]))
			end
			if not tr and not no_transcript and words[1] then
				cap = find(words[1], "^%^")
				words[1] = gsub(words[1], "^%^", "")
				if words[2] then
					words[2] = gsub(words[2], "^%^", "")
				end
				tr, cat = require("zh/extract").extract_pron(words[1], "m", cap)
			end

			for i, word in ipairs(words) do
				word = gsub(word, '%*', '')
				if mention then
					if	m_zh.ts_determ(words[i]) == 'both' then
						words[i] = '<i class="Hani mention" lang="zh">[[' .. word .. '#Chinese|' .. word .. ']]</i>'
					elseif	m_zh.ts_determ(words[i]) == 'trad' then
						words[i] = '<i class="Hant mention" lang="zh-Hant">[[' .. word .. '#Chinese|' .. word .. ']]</i>'
					else
						words[i] = '<i class="Hans mention" lang="zh-Hans">[[' .. word .. '#Chinese|' .. word .. ']]</i>'
					end
	--[[ (disabled to allow links to, for example, a link to 冥王星#Chinese from 冥王星#Japanese. 18 May, 2016)
				elseif word == pagename then
					word = format_Chinese_text('<b>' .. word .. '</b>')
	]]
				else
					if	m_zh.ts_determ(words[i]) == 'both' then
						words[i] = format_Chinese_text('[[' .. word .. '#Chinese|' .. word .. ']]')
					elseif	m_zh.ts_determ(words[i]) == 'trad' then
						words[i] = format_Chinese_text_trad('[[' .. word .. '#Chinese|' .. word .. ']]')
					else
						words[i] = format_Chinese_text_simp('[[' .. word .. '#Chinese|' .. word .. ']]')
					end
				end
			end
			text = table.concat(words, format_Chinese_text('／'))
		else
			text = require("links").language_link{
				term = text,
				lang = require("languages").getByCode("zh"),
			}
			if mention then
				text = '<i class="Hani mention" lang="zh">' .. gsub(text, "%*", "") .. '</i>'
			else
				text = format_Chinese_text(gsub(text, "%*", ""))
			end
		end
	end
	if tr == '-' or no_transcript then
		tr = nil -- allow translit to be disabled: remove translit if it is "-", just like normal {{l}}
	end
	local notes = args['note']
	local lit = args['lit']
	if tr or gloss or notes or lit then
		local annotations = {}
		if tr then
			tr = format_rom(tr)
			tr = gsub(tr, "&#39;", "'")
			tr = gsub(tr, "#", "")
			table.insert(annotations, tr)
		end
		if gloss then
			table.insert(annotations, format_gloss(gloss))
		end
		table.insert(annotations, notes)
		if lit then
			table.insert(annotations, "literally " .. format_gloss(lit))
		end
		annotations = table.concat(annotations, ", ")
		text = text .. " (" .. annotations .. ")"
	end
	return text .. (cat or "")
end

-- we cannot just return the function here because this is also invoked by a template.
return M