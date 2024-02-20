local export = {}
local m_string_utils = require("string utilities")

local codepoint = mw.ustring.codepoint
local gsub = m_string_utils.gsub
local match = m_string_utils.match
local len = m_string_utils.len
local u = mw.ustring.char

local m_ltc_predict = require("ltc-pron/predict")
local m_cmn_pron = require("cmn-pron")
local m_baxter = require("ltc-pron/baxter")
local data = mw.loadData("ltc-pron/data")

function export.infer_categories(text)
	local t = mw.text.split(text, "", true)
	
	local initial, final, deng, openness, tone = t[1], t[2], t[3], t[4], t[6]
	if match(text, "-") then
		deng = mw.text.split(text, "-")[2] .. deng
	end
	if tone == "入" then final = data.fin_conv[final] or final end
	local initial_type = data.init_type[initial]
	local tone_label = data.tone_symbol[tone]
	local final_type
	
	if match(final, data.final_type_1) then
		final_type = data.fin_type_open[final..openness]
	
	elseif match(final, data.final_type_2) then
		final_type = data.final_deng[final..deng]
	
	elseif match(final, data.final_type_3) then
		final_type = data.fin_type_deng_open[final..deng..openness]
	
	elseif match(final, data.final_type_4) then
		if deng == "重鈕三" then
			final_type = data.final_openness[final..openness]
		else
			final_type = data.final_deng[final..deng]
		end

	elseif match(final, data.final_type_5) then
		final_type = data.fin_type[final]
	
	else
		return error("Final not recognised.")
	end
	
	return initial_type, final_type, tone_label
end

local function zh_fmt(text)
	return '<span class="Hani" lang="zh">' .. text .. '</span>'
end

local function ltc_table(titlechar, text, indiv_num, count)
	local people = { "Zhengzhang", "Pan", "Shao", "Pulleyblank", "Li", "Wang", "Karlgren" }
	local pronunciation = {}
	local t = mw.text.split(text, "", true)
	
	local initial, final, deng, openness, she, tone, fanqieA, fanqieB = t[1], t[2], t[3], t[4], t[5], t[6], t[7], t[8]
	local initial_type, final_type, tone_label = export.infer_categories(text)

	for ind, person in ipairs(people) do
		table.insert(pronunciation, '<span class="IPAchar" lang="zh">/' ..
			data.initialConv[person][initial_type] .. data.finalConv[person][final_type] .. "<sup>" .. tone_label .. "</sup>" .. "/</span>")
	end
	local baxter = '<span lang="zh">' ..
		m_baxter.baxter(initial_type, final_type, tone_label) .. "</span>"
	return {
		nil,
		'<b>'..zh_fmt(titlechar)..'</b>', 
		indiv_num .. "/" .. count,
		zh_fmt("[["..initial.."]]") .. " (" .. initial_type .. ")",
		zh_fmt("[["..final.."]]") .. " (" .. final_type .. ")",
		data.tonality[tone],
		data.open_closed[openness],
		data.division[deng],
		fanqieB and zh_fmt(gsub(fanqieA .. fanqieB, "(.)", "[[%1]]") .. "切") or "",
		baxter,
		nil,
		pronunciation[1],
		pronunciation[2],
		pronunciation[3],
		pronunciation[4],
		pronunciation[5],
		pronunciation[6],
		pronunciation[7],
		m_cmn_pron.py_number_to_mark(m_ltc_predict.predict_cmn(initial_type, final_type, data.tone_number[tone])),
		m_ltc_predict.predict_yue(initial_type, final_type, data.tone_number[tone]),
	}
end

function export.ipa(index_text, preview)
	local titlechar = mw.title.getCurrentTitle().text
	local reading_index = mw.text.split(index_text, ",")
	local ltc_indiv_pronunciation = {}
	local output_text = {}
	
	local fields = {
		"Rime",
		"<small>Character</small>",
		"<small>Reading #</small>",
		"<small>Initial</small> (" .. zh_fmt("聲") .. ")",
		"<small>Final</small> (" .. zh_fmt("韻") .. ")",
		"<small>Tone</small> (" .. zh_fmt("調") .. ")",
		"<small>Openness</small> (" .. zh_fmt("開合") .. ")",
		"<small>Division</small> (" .. zh_fmt("等") .. ")",
		"<small>[[w:Fanqie|Fanqie]]</small>",
		"<small>[[w:Baxter%27s_transcription_for_Middle_Chinese|Baxter]]</small>",
		"Reconstructions",
		"<small>[[w:Zhengzhang Shangfang|Zhengzhang<br>Shangfang]]</small>",
		"<small>[[w:Pan Wuyun|Pan<br>Wuyun]]</small>",
		"<small>[[w:zh:邵荣芬|Shao<br>Rongfen]]</small>",
		"<small>[[w:Edwin G. Pulleyblank|Edwin<br>Pulleyblank]]</small>",
		"<small>[[w:Li Rong (linguist)|Li<br>Rong]]</small>",
		"<small>[[w:Wang Li (linguist)|Wang<br>Li]]</small>",
		"<small>[[w:Bernhard Karlgren|Bernard<br>Karlgren]]</small>",
		"<small>Expected<br>Mandarin<br>Reflex</small>",
		"<small>Expected<br>Cantonese<br>Reflex</small>",
	}
	
	for i, cp in ipairs { codepoint(titlechar, 1, -1) } do
		local ch = u(cp)
		local success, data_module = pcall(require, "Module:zh/data/ltc-pron/" .. ch)
		if success then
			local reading_number = reading_index[i] or "y"
			local count = 0
			for index, value in ipairs(data_module) do
				count = count + 1
			end
			if reading_number == "y" then
				for ltc_reading_no, position in ipairs(data_module) do
					table.insert(ltc_indiv_pronunciation, ltc_table(ch, position, ltc_reading_no, count))
				end
			elseif reading_number == "n" then
				break
			else
				for indiv_number in mw.text.gsplit(reading_number, '%+') do
					table.insert(ltc_indiv_pronunciation, ltc_table(ch, data_module[tonumber(indiv_number)], indiv_number, count))
				end
			end
		end
	end

	if ltc_indiv_pronunciation[1] then
		local hash, results, value_eff = {}, {}
		for _, value in ipairs(ltc_indiv_pronunciation) do
			table.remove(value, 11)
			table.remove(value, 1)
			value_eff = table.concat(value)
			if (not hash[value_eff]) then
				hash[value_eff] = true
				table.insert(value, 1, nil)
				table.insert(value, 11, nil)
				results[#results + 1] = value
   			end
		end
		local rand = require("string utilities").gsub("mc-" .. value_eff, "[^A-Za-z0-9]", codepoint('%1'))
		local fmt = {
			fold = '\n* <div title="expand" class="mw-customtoggle-mc' .. rand .. '"> ' ..
					'[[w:Middle Chinese|Middle Chinese]]: <span style="font-family: Consolas, monospace;">' .. preview .. 
					'</span><span style="float:right; border:1px solid #ccc; border-radius:1px;' ..
					' padding:0 0; font-size:90%">▼</span></div>\n',
			header = '{| class="wikitable mw-collapsible mw-collapsed" id="mw-customcollapsible-mc' .. rand ..
				'" style="width:100%; margin:0; text-align:center; border-collapse: collapse; border-style: hidden;"',
			lv1 = '\n|-\n! style="background-color:' .. data.colour_1 .. '" colspan=' .. #results+1 .. '|',
			lv2 = '\n|-\n! style="background-color:' .. data.colour_2 .. '; width:8em"|',
			lv3 = '\n| style="background-color:' .. data.colour_3 .. '"|',
			closing = '\n|}'
		}
		for field_index, field in ipairs(fields) do
			if match(field, "small") then
				local field_set = {}
				for _, result in ipairs(results) do
					table.insert(field_set, result[field_index])
				end
				table.insert(output_text, fmt.lv2 .. field .. fmt.lv3 .. table.concat(field_set, fmt.lv3))
			else
				table.insert(output_text, fmt.lv1 .. field)
			end
		end
		return fmt.fold .. fmt.header .. table.concat(output_text) .. fmt.closing
	else
		return ""
	end
end

function export.retrieve_pron(text, reconstruction, index, no_intro)
	if type(text) == "table" then text = text.args[1] end
	local underline_format = "<span style=\"border-bottom: 1px dotted #000; cursor:help\" title=\"Middle Chinese\">MC</span> "
	local separator = len(text) == 1 and (no_intro and ", ") or '<span style="padding-left:2px; padding-right:2px">|</span>'

	-- remove link brackets from text, at least
	-- as [[美姫#Etymology]]
	text = text:gsub("[%[%]]", "")
	
	if reconstruction then
		return underline_format .. reconstruction
	else
		local index_set, retrieve_result = {}, {}
		if index and index ~= "y" then
			index_set = mw.text.split(index, ",")
		end
		for char_index, cp in ipairs { codepoint(text, 1, -1) } do
			local char_pronunciation = {}
			local ch = u(cp)
			local success, data_module = pcall(require, "Module:zh/data/ltc-pron/" .. ch)
			if success then
				local reading_no = index_set[char_index] or "y"
				if reading_no == "n" then
					table.insert(char_pronunciation, "?")
				elseif reading_no == "y" then
					local initial, final, tone
					for _, reading in ipairs(data_module) do
						initial, final, tone = export.infer_categories(reading)
						table.insert(char_pronunciation, m_baxter.baxter(initial, final, tone))
					end
				else
					for number in mw.text.gsplit(reading_no, "+") do
						initial, final, tone = export.infer_categories(data_module[tonumber(number)])
						table.insert(char_pronunciation, m_baxter.baxter(initial, final, tone))
					end
				end
				table.insert(retrieve_result, table.concat(char_pronunciation, separator))
			end
		end
		return retrieve_result[1] and (no_intro and "" or underline_format) .. 
			table.concat(retrieve_result, " ") or nil
	end
end

function export.link(frame)
	local args = frame:getParent().args
	local text, meaning, lit = args[1], args[2] or args['gloss'] or nil, args['lit'] or nil
	return require("zh/link").link(frame, nil,
		{ "*" .. text, tr = export.retrieve_pron(text, args["tr"] or false, args["id"] or false, false),
		gloss = meaning, lit = lit }, mw.title.getCurrentTitle().subpageText)
end

return export