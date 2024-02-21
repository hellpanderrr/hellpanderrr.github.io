local data = {}

local langcode_to_abbr = {
	cdo = "md",				-- Min Dong
	cjy = "j",				-- Jin
	cmn = "m",				-- Mandarin
	["cmn-sic"] = "m-s",	-- Sichuanese
--	cnp 					-- Northern Pinghua
--	cpx 					-- Puxian Min
--	csp 					-- Southern Pinghua
--	czh 					-- Huizhou
--	czo 					-- Min Zhong
	dng = "dg",				-- Dungan
	gan = "g",				-- Gan
	hak = "h",				-- Hakka
	hsn = "x",				-- Xiang
	ltc = "mc",				-- Middle Chinese
	lzh = "m",				-- Literary (Classical) Chinese
	mnp = "mb",				-- Min Bei
	nan = "mn",				-- Min Nan
	och = "oc",				-- Old Chinese
	wuu = "w",				-- Wu
--	wxa 					-- Waxiang
	yue = "c",				-- Cantonese
	zh = "m",				-- Chinese (general)
	["zhx-lui"] = "mn-l",	-- Leizhou
--	["zhx-sht"]				-- Shaozhou Tuhua
	["zhx-tai"] = "c-t",	-- Taishanese
	["zhx-teo"] = "mn-t",	-- Teochew
}

local abbr_to_langcode = {}
for k, v in pairs(langcode_to_abbr) do
	if k ~= "zh" and k ~= "lzh" then
		abbr_to_langcode[v] = k
	end
end

return {
	langcode_to_abbr = langcode_to_abbr,
	abbr_to_langcode = abbr_to_langcode
}