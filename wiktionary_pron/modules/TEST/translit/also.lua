local export = {}

local m_debug = require("debug")
local m_links = require("links")
local m_params = require("parameters")
local m_scripts = require("scripts")
local m_util = require("utilities")
local yesno = require("yesno")
local und = require("languages").getByCode("und")

function export.main(frame)
	local params = {
		[1] = {required = true, list = true},
		["sc"] = {list = true, allow_holes = true},
		["uni"] = {list = true, allow_holes = true, separate_no_index = true},
		["detectsc"] = {type = "boolean"}
	}
	
	local args = m_params.process(frame:getParent().args or frame.args, params)
	
	if args["sc"].maxindex > 0 then
		-- [[Special:WhatLinksHere/Template:tracking/also/sc param]]
		m_debug.track("also/sc param")
	end
	
	local uni_default = yesno((args["uni"]["default"] == "auto") or args["uni"]["default"]) and "auto" or nil
	
	local title = mw.title.getCurrentTitle()
	local full_pagename = title.fullText
	
	-- Disables tagging outside of mainspace, where {{also}} more often links to
	-- pages that are not entries and don't need tagging. Tagging in Reconstruction
	-- would be more complicated and is often unnecessary, and there are very few
	-- entries in Appendix.
	local detect_sc = title.nsText == ""
		or args["detectsc"] -- to test the script detection capabilities
	
	local items = {}
	local use_semicolon = false
	local arg_plaintext
		
	for i, arg in ipairs(args[1]) do
		local uni = args["uni"][i] or uni_default
		local sc = args["sc"][i] and m_scripts.getByCode(args["sc"][i]) or und:findBestScript(arg)
		
		if arg:find(",", 1, true) then
			use_semicolon = true
		end
		
		if not yesno(uni, uni) then
			uni = nil
		end
		
		-- Create the link.
		arg = m_links.plain_link{term = arg, lang = und, sc = sc}
		
		-- We use the link to determine if arg is the current page, so that it works on edge cases like unsupported titles.
		if not arg:match("<strong class=\"selflink\">") then
			arg = '<b class="' .. sc:getCode() .. '">' .. arg .. "</b>"
			
			local codepoint
			if uni then
				local len = require("string utilities").len
				m_debug.track("also/uni")
				
				if uni == 'auto' then
					arg_plaintext = m_util.get_plaintext(arg)
					codepoint = (len(arg_plaintext) == 1) and mw.ustring.codepoint(arg_plaintext, 1, 1)
				else
					codepoint = tonumber(uni)
					
					if len(arg) ~= 1 or codepoint ~= mw.ustring.codepoint(arg, 1, 1) then
						m_debug.track("also/uni/noauto")
					else
						m_debug.track("also/uni/auto")
					end
				end
			end
			
			if codepoint then
				local m_unidata = require('Unicode data')
				
				arg = arg .. (" <small>[U+%04X %s]</small>"):format(
					codepoint,
					m_unidata.lookup_name(codepoint):gsub("<", "&lt;")
				)
			end
			
			-- Add directionality characters for (horizontal) right-to-left scripts.
			-- Note: this shouldn't be used for vertical RTL scripts, since it causes them to be displayed bottom-to-top.
			if sc:getDirection() == "rtl" then
				arg = "&#x2067;" .. arg .. "&#x2069;"
			end
			
			table.insert(items, arg)
		end
	end
	
	if #items == 0 then
		table.insert(items, "{{{1}}}")
	end
	
	-- Join with serial "and" and serial comma
	local function serial_comma_join(seq, conjunction)
		conjunction = conjunction or ","
		if #seq == 0 then
			return ""
		elseif #seq == 1 then
			return seq[1] -- nothing to join
		elseif #seq == 2 then
			return seq[1] .. " ''and'' " .. seq[2]
		else
			return table.concat(seq, conjunction .. " ", 1, #seq - 1)
				.. "<span class='serial-comma'>" .. conjunction .. "</span>" ..
				"''<span class='serial-and'> and</span>'' " ..
				seq[#seq]
		end
	end
	
	return ("<div class=\"disambig-see-also%s\">''See also:'' %s</div>"):format(
		(#items == 2) and "-2" or "",
		serial_comma_join(items, use_semicolon and ";" or ",")
	)
end

return export