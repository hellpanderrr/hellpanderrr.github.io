local export = {}

local fully_voiced_initial = {
	[3] = true,
	[7] = true,
	[11] = true,
	[15] = true,
	[17] = true,
	[20] = true,
	[22] = true,
	[25] = true,
	[27] = true,
	[30] = true,
	[33] = true,
}

local partially_voiced_initial = {
	[4] = true,
	[8] = true,
	[12] = true,
	[31] = true,
	[35] = true,
	[36] = true,
	[37] = true,
	[38] = true,
}

local fricativisation_inducing = {
	[2] = true,
	[4] = true,
	[7] = true,
	[8] = true,
	[21] = true,
	[24] = true,
	[28] = true,
	[59] = true,
	[60] = true,
	[66] = true,
	[68] = true,
	[106] = true,
	[108] = true,
	[136] = true,
	[146] = true,
	[148] = true,
}

local m_lenition_inducing = {
	[21] = true,
	[24] = true,
	[59] = true,
	[60] = true,
	[66] = true,
	[68] = true,
	[106] = true,
	[146] = true,
}

local devoicing_outcomes = {
	["b"] = "p",
	["d"] = "t",
	["z"] = "c",
	["g"] = "k",
	["zh"] = "ch",
	["sh"] = "ch",
}

local function has(str, index, ...)
	if index ~= 0 then
		str = mw.ustring.sub(str, index, index)
	end
	for i, v in ipairs{...} do
		if str == v then
			return true
		end
	end
	return false
end

local initial_outcomes_cmn = {
	[1] = "b", [2] = "p", [3] = "b", [4] = "m",
	[5] = "d", [6] = "t", [7] = "d", [8] = "n",
	[9] = "zh", [10] = "ch", [11] = "zh", [12] = "n",
	[13] = "z", [14] = "c", [15] = "z", [16] = "s", [17] = "s",
	[18] = "zh", [19] = "ch", [20] = "zh", [21] = "sh", [22] = "s",
	[23] = "zh", [24] = "ch", [25] = "sh", [26] = "sh", [27] = "sh",
	[28] = "g", [29] = "k", [30] = "g", [32] = "h", [33] = "h",
	[31] = "", [34] = "", [35] = "", [36] = "",
	[37] = "l", [38] = "r",
}

local devoicing_initial_cmn = {
	[3] = true,
	[7] = true,
	[11] = true,
	[15] = true,
	[20] = true,
	[25] = true,
	[30] = true,
}

local palatalisation_outcomes_cmn = {
	["g"] = "j",
	["k"] = "q",
	["h"] = "x",
	["z"] = "j",
	["c"] = "q",
	["s"] = "x",
}

local final_simplification_outcomes_cmn = {
	["iou"] = "iu",
	["uei"] = "ui",
	["uen"] = "un",
	["ueng"] = "ong",
}

local rhyme_outcomes_cmn = {
	[1] = "ueng",
	[2] = { "ueng", 3, "iong" },
	[3] = "u",
	[4] = "u",
	[5] = "ueng",
	[6] = "u",
	[7] = { "ueng", 3, "iong" },
	[8] = "u",
	[9] = { "uang", 3, "iang" },
	[10] = { "uo", 3, "üe" },
	[11] = { "er", 3, "i" },
	[12] = { "uei", 2, "uai" },
	[13] = { "er", 3, "i" },
	[14] = { "uei", 2, "uai" },
	[15] = { "er", 3, "i" },
	[16] = { "uei", 2, "uai" },
	[17] = { "er", 3, "i" },
	[18] = { "uei", 2, "uai" },
	[19] = { "er", 3, "i" },
	[20] = { "er", 3, "i" },
	[21] = { "uei", 2, "uai" },
	[22] = "ü",
	[23] = "u",
	[24] = "ü",
	[25] = "ai",
	[26] = "uei",
	[27] = "i",
	[28] = "uei",
	[29] = { "ai", 3, "ie" },
	[30] = "uai",
	[31] = { "ai", 3, "ia" },
	[32] = { "uai", 3, "ua" },
	[33] = { "ai", 3, "ie" },
	[34] = "uai",
	[35] = "i",
	[36] = { "uei", 2, "uai" },
	[37] = "i",
	[38] = { "uei", 2, "uai" },
	[39] = "i",
	[40] = "uei",
	[41] = "ai",
	[42] = "uei",
	[43] = "in",
	[44] = "in",
	[45] = "ün",
	[46] = "en",
	[47] = "ün",
	[48] = "i",
	[49] = "i",
	[50] = { "ü", 2, "uai" },
	[51] = "e",
	[52] = { "ü", 2, "uai" },
	[53] = { "uen", 3, "en" },
	[54] = "e",
	[55] = "uen",
	[56] = { "u", 1, "o" },
	[57] = "in",
	[58] = "i",
	[59] = { "uen", 3, "ün" },
	[60] = "ü",
	[61] = "an",
	[62] = "uan",
	[63] = { "a", 3, "e" },
	[64] = "uo",
	[65] = "ian",
	[66] = "üan",
	[67] = "ie",
	[68] = { "a", 3, "üe" },
	[69] = { "an", 3, "ian" },
	[70] = "uan",
	[71] = { "a", 3, "ia" },
	[72] = "ua",
	[73] = { "an", 3, "ian" },
	[74] = "uan",
	[75] = { "a", 3, "ia" },
	[76] = "ua",
	[77] = "ian",
	[78] = "üan",
	[79] = "ian",
	[80] = "üan",
	[81] = "ie",
	[82] = "üe",
	[83] = "ie",
	[84] = "üe",
	[85] = "ian",
	[86] = "üan",
	[87] = "ie",
	[88] = "üe",
	[89] = "ao",
	[90] = { "ao", 3, "iao" },
	[91] = "iao",
	[92] = "iao",
	[93] = "iao",
	[94] = { "uo", 3, "e" },
	[95] = "uo",
	[96] = "ie",
	[97] = "üe",
	[98] = { "a", 3, "ia" },
	[99] = "ua",
	[100] = "ie",
	[101] = "ang",
	[102] = "uang",
	[103] = { "uo", 3, "e" },
	[104] = "uo",
	[105] = { "iang", 2, "uang" },
	[106] = "uang",
	[107] = { "üe", 1, "o" },
	[108] = { "üe", 1, "o" },
	[109] = "eng",
	[110] = "ueng",
	[111] = "ing",
	[112] = "iong",
	[113] = "e",
	[114] = "uo",
	[115] = "i",
	[116] = "ü",
	[117] = "eng",
	[118] = "ueng",
	[119] = "e",
	[120] = "uo",
	[121] = "ing",
	[122] = "iong",
	[123] = "i",
	[124] = "ü",
	[125] = "ing",
	[126] = "iong",
	[127] = "i",
	[128] = "ü",
	[129] = "eng",
	[130] = "ueng",
	[131] = "e",
	[132] = "uo",
	[133] = "ing",
	[134] = { "i", 2, "e" },
	[135] = "ü",
	[136] = { "iou", 1, "ou" },
	[137] = "ou",
	[138] = { "iou", 1, "iao" },
	[139] = "in",
	[140] = "in",
	[141] = { "i", 2, "e" },
	[142] = { "i", 2, "e" },
	[143] = "an",
	[144] = { "a", 3, "e" },
	[145] = { "an", 3, "ian" },
	[146] = "uan",
	[147] = "ie",
	[148] = { "a", 3, "ia" },
	[149] = { "an", 3, "ian" },
	[150] = { "a", 3, "ia" },
	[151] = { "an", 3, "ian" },
	[152] = { "a", 3, "ia" },
	[153] = "ian",
	[154] = "ian",
	[155] = "ie",
	[156] = "ie",
	[157] = "ian",
	[158] = "ie",
	[159] = "an",
	[160] = { "a", 3, "e" },
}

local labial_openness_normalisation_cmn = {
	[12] = 11,
	[14] = 13,
	[16] = 15,
	[18] = 17,
	[21] = 20,
	[25] = 26,
	[28] = 27,
	[36] = 35,
	[38] = 37,
	[40] = 39,
	[63] = 64,
	[67] = 68,
	[105] = 106,
	[112] = 111,
	[113] = 114,
	[119] = 120,
	[122] = 121,
	[126] = 125,
	[131] = 132,
}

function export.predict_cmn(initial, final, tone)
	local initial_result = initial_outcomes_cmn[initial]

	if fricativisation_inducing[final] and initial <= 3 then
		initial_result = "f"

	elseif m_lenition_inducing[final] and initial == 4 then
		initial_result = "w"

	elseif tone == 1 and devoicing_initial_cmn[initial] then
		initial_result = devoicing_outcomes[initial_result]
	end

	if initial <= 4 then
		final = labial_openness_normalisation_cmn[final] or final
	end
	local final_result = rhyme_outcomes_cmn[final]

	if type(final_result) == "table" then
		if final_result[2] == 1 and initial <= 4
		or final_result[2] == 2 and initial >= 18 and initial <= 22
		or final_result[2] == 3 and initial >= 28 and initial <= 36 then
			final_result = final_result[3]
		else
			final_result = final_result[1]
		end
	end

	if has(final_result, 1, "i", "ü") then
		initial_result = palatalisation_outcomes_cmn[initial_result] or initial_result
	end

	if final_result == "er" then
		if initial_result == "r" then
			initial_result = ""
		else
			final_result = "i"
		end
	end

	if has(initial_result, 0, "zh", "ch", "sh", "r") then
		final_result = mw.ustring.gsub(final_result, "^in", "en")
		final_result = mw.ustring.gsub(final_result, "^i(.)", "%1")
		final_result = mw.ustring.gsub(final_result, "^üe$", "uo")
	end

	if initial <= 4 then
		final_result = mw.ustring.gsub(final_result, "^u(.)", "%1")
		if has(initial_result, 0, "f", "w") then
			final_result = mw.ustring.gsub(final_result, "^[iü](.)", "%1")
			final_result = mw.ustring.gsub(final_result, "^i$", "ei")
		else
			final_result = mw.ustring.gsub(final_result, "^ü", "i")
		end
	end

	if has(initial_result, 0, "n", "l") and has(final_result, 0, "ua", "uai", "uang", "uei") then
		final_result = mw.ustring.gsub(final_result, "^u", "")
	end
	if has(final_result, 1, "ü") and
		not (has(initial_result, 0, "n", "l") and has(final_result, 0, "ü", "üe")) then
		if initial_result == "" then
			initial_result = "y"
		end
		final_result = mw.ustring.gsub(final_result, "^ü", "u")
	end

	if initial_result == "" then
		if has(final_result, 1, "i") then
			initial_result = "y"
		end
		if has(final_result, 1, "u") then
			initial_result = "w"
		end
		if initial_result ~= "" then
			final_result = mw.ustring.gsub(final_result, "^.([^n])", "%1")
		end
	end

	final_result = final_simplification_outcomes_cmn[final_result] or final_result
	
	local tone_result
	if tone == 1 then
		if fully_voiced_initial[initial] or partially_voiced_initial[initial] then
			tone_result = 2
		else
			tone_result = 1
		end
	elseif tone == 2 then
		if fully_voiced_initial[initial] then
			tone_result = 4
		else
			tone_result = 3
		end
	elseif tone == 3 then
		tone_result = 4
	else
		if fully_voiced_initial[initial] then
			tone_result = 2
		elseif partially_voiced_initial[initial] then
			tone_result = 4
		else
			tone_result = ""
		end
	end

	return initial_result .. final_result .. tone_result
end

local initial_outcomes_yue = {
	[1] = "b", [2] = "p", [3] = "b", [4] = "m",
	[5] = "d", [6] = "t", [7] = "d", [8] = "n",
	[9] = "z", [10] = "c", [11] = "z", [12] = "n",
	[13] = "z", [14] = "c", [15] = "z", [16] = "s", [17] = "z",
	[18] = "z", [19] = "c", [20] = "z", [21] = "s", [22] = "z",
	[23] = "z", [24] = "c", [25] = "s", [26] = "s", [27] = "s",
	[28] = "g", [29] = "k", [30] = "g", [31] = "ng", [32] = "h",
	[33] = "h", [34] = "", [35] = "", [36] = "",
	[37] = "l", [38] = "j",
}

local devoicing_initial_yue = {
	[3] = true,
	[7] = true,
	[11] = true,
	[15] = true,
	[17] = true,
	[20] = true,
	[22] = true,
	[30] = true,
}

local initial_class_yue = {
	[1] = 1,
	[2] = 1,
	[3] = 1,
	[4] = 1,
	[5] = 2,
	[6] = 2,
	[7] = 2,
	[8] = 2,
	[9] = 3,
	[10] = 3,
	[11] = 3,
	[12] = 2,
	[13] = 4,
	[14] = 4,
	[15] = 4,
	[16] = 4,
	[17] = 4,
	[18] = 5,
	[19] = 5,
	[20] = 5,
	[21] = 5,
	[22] = 5,
	[23] = 6,
	[24] = 6,
	[25] = 6,
	[26] = 6,
	[27] = 6,
	[28] = 7,
	[29] = 7,
	[30] = 7,
	[31] = 8,
	[32] = 7,
	[33] = 7,
	[34] = 8,
	[35] = 8,
	[36] = 8,
	[37] = 2,
	[38] = 6,
}

local final_class_yue = {
	[1] = 20,
	[2] = 20,
	[3] = 20,
	[4] = 20,
	[5] = 20,
	[6] = 20,
	[7] = 20,
	[8] = 20,
	[9] = 34,
	[10] = 34,
	[11] = 35,
	[12] = 21,
	[13] = 35,
	[14] = 21,
	[15] = 35,
	[16] = 21,
	[17] = 35,
	[18] = 21,
	[19] = 35,
	[20] = 35,
	[21] = 21,
	[22] = 36,
	[23] = 24,
	[24] = 36,
	[25] = 39,
	[26] = 28,
	[27] = 6,
	[28] = 6,
	[29] = 2,
	[30] = 33,
	[31] = 2,
	[32] = 33,
	[33] = 2,
	[34] = 33,
	[35] = 6,
	[36] = 21,
	[37] = 6,
	[38] = 21,
	[39] = 6,
	[40] = 6,
	[41] = 17,
	[42] = 25,
	[43] = 8,
	[44] = 8,
	[45] = 22,
	[46] = 8,
	[47] = 22,
	[48] = 8,
	[49] = 8,
	[50] = 22,
	[51] = 8,
	[52] = 22,
	[53] = 8,
	[54] = 8,
	[55] = 38,
	[56] = 38,
	[57] = 8,
	[58] = 8,
	[59] = 8,
	[60] = 8,
	[61] = 31,
	[62] = 32,
	[63] = 31,
	[64] = 32,
	[65] = 26,
	[66] = 27,
	[67] = 26,
	[68] = 27,
	[69] = 4,
	[70] = 4,
	[71] = 4,
	[72] = 4,
	[73] = 4,
	[74] = 4,
	[75] = 4,
	[76] = 4,
	[77] = 13,
	[78] = 30,
	[79] = 13,
	[80] = 30,
	[81] = 13,
	[82] = 30,
	[83] = 13,
	[84] = 30,
	[85] = 13,
	[86] = 30,
	[87] = 13,
	[88] = 30,
	[89] = 19,
	[90] = 5,
	[91] = 15,
	[92] = 15,
	[93] = 15,
	[94] = 16,
	[95] = 16,
	[96] = 11,
	[97] = 29,
	[98] = 1,
	[99] = 1,
	[100] = 11,
	[101] = 18,
	[102] = 18,
	[103] = 18,
	[104] = 18,
	[105] = 37,
	[106] = 18,
	[107] = 37,
	[108] = 18,
	[109] = 9,
	[110] = 9,
	[111] = 40,
	[112] = 40,
	[113] = 9,
	[114] = 9,
	[115] = 14,
	[116] = 14,
	[117] = 9,
	[118] = 9,
	[119] = 9,
	[120] = 9,
	[121] = 14,
	[122] = 14,
	[123] = 14,
	[124] = 14,
	[125] = 14,
	[126] = 14,
	[127] = 14,
	[128] = 14,
	[129] = 9,
	[130] = 9,
	[131] = 9,
	[132] = 9,
	[133] = 14,
	[134] = 14,
	[135] = 14,
	[136] = 10,
	[137] = 10,
	[138] = 10,
	[139] = 7,
	[140] = 7,
	[141] = 7,
	[142] = 7,
	[143] = 23,
	[144] = 23,
	[145] = 12,
	[146] = 3,
	[147] = 12,
	[148] = 3,
	[149] = 3,
	[150] = 3,
	[151] = 3,
	[152] = 3,
	[153] = 12,
	[154] = 12,
	[155] = 12,
	[156] = 12,
	[157] = 12,
	[158] = 12,
	[159] = 23,
	[160] = 23,
}

local rhyme_outcomes_yue = {
	[1] = "A",
	[2] = "Ai",
	[3] = "Am",
	[4] = "An",
	[5] = "Au",
	[6] = "ai",
	[7] = "am",
	[8] = "an",
	[9] = "aN",
	[10] = "au",
	[11] = "e",
	[12] = "im",
	[13] = "in",
	[14] = "IN",
	[15] = "iu",
	[16] = "o",
	[17] = "oi",
	[18] = "oN",
	[19] = "ou",
	[20] = "UN",
	[21] = { "ei", "Ei", "ai" },
	[22] = { "En", "En", "an" },
	[23] = { "Am", "Am", "om" },
	[24] = { "ou", "ou", "u" },
	[25] = { "ui", "Ei", "ui" },
	[26] = { "An", "in", "in" },
	[27] = { "An", "Yn", "Yn" },
	[28] = { "ai", "Ei", "ui" },
	[29] = { "e", "O", "O" },
	[30] = { "in", "Yn", "Yn" },
	[31] = { "un", "An", "on" },
	[32] = { "un", "Yn", "un" },
	[33] = { "Ai", "Ei", "Ai" },
	[34] = { "oN", "oN", "oN" },
	[35] = { "ei", "ei", "i", "i", "i", "i", "ei", "i" },
	[36] = { "u", "Ei", "Y", "Ei", "o", "Y", "Ei", "Y" },
	[37] = { "oN", "ON", "ON", "ON", "oN", "ON", "ON", "ON" },
	[38] = { "un", "En", "En", "Yn", "Yn", "Yn", "an", "an" },
	[39] = { "ui", "Ai", "Ai", "oi", "Ai", "Ai", "oi", "oi" },
	[40] = { "IN", "IN", "IN", "IN", "aN", "IN", "IN", "IN" },
}

local palatalisation_inducing_yue = {
	[2] = true,
	[4] = true,
	[7] = true,
	[8] = true,
	[11] = true,
	[12] = true,
	[13] = true,
	[14] = true,
	[15] = true,
	[16] = true,
	[17] = true,
	[18] = true,
	[19] = true,
	[20] = true,
	[21] = true,
	[22] = true,
	[24] = true,
	[27] = true,
	[28] = true,
	[35] = true,
	[36] = true,
	[37] = true,
	[38] = true,
	[39] = true,
	[40] = true,
	[43] = true,
	[44] = true,
	[45] = true,
	[46] = true,
	[47] = true,
	[48] = true,
	[49] = true,
	[50] = true,
	[51] = true,
	[52] = true,
	[57] = true,
	[58] = true,
	[59] = true,
	[60] = true,
	[65] = true,
	[66] = true,
	[67] = true,
	[68] = true,
	[77] = true,
	[78] = true,
	[79] = true,
	[80] = true,
	[81] = true,
	[82] = true,
	[83] = true,
	[84] = true,
	[85] = true,
	[86] = true,
	[87] = true,
	[88] = true,
	[91] = true,
	[92] = true,
	[93] = true,
	[96] = true,
	[97] = true,
	[100] = true,
	[105] = true,
	[106] = true,
	[107] = true,
	[108] = true,
	[111] = true,
	[112] = true,
	[115] = true,
	[116] = true,
	[121] = true,
	[122] = true,
	[123] = true,
	[124] = true,
	[125] = true,
	[126] = true,
	[127] = true,
	[128] = true,
	[133] = true,
	[134] = true,
	[135] = true,
	[136] = true,
	[138] = true,
	[139] = true,
	[140] = true,
	[141] = true,
	[142] = true,
	[145] = true,
	[146] = true,
	[147] = true,
	[148] = true,
	[153] = true,
	[154] = true,
	[155] = true,
	[156] = true,
	[157] = true,
	[158] = true,
}

local labialisation_inducing_yue = {
	[12] = true,
	[14] = true,
	[16] = true,
	[18] = true,
	[21] = true,
	[23] = true,
	[24] = true,
	[26] = true,
	[28] = true,
	[30] = true,
	[32] = true,
	[34] = true,
	[36] = true,
	[38] = true,
	[40] = true,
	[42] = true,
	[45] = true,
	[47] = true,
	[50] = true,
	[52] = true,
	[55] = true,
	[56] = true,
	[59] = true,
	[60] = true,
	[62] = true,
	[64] = true,
	[66] = true,
	[68] = true,
	[70] = true,
	[72] = true,
	[74] = true,
	[76] = true,
	[78] = true,
	[80] = true,
	[82] = true,
	[84] = true,
	[86] = true,
	[88] = true,
	[95] = true,
	[97] = true,
	[99] = true,
	[102] = true,
	[104] = true,
	[106] = true,
	[108] = true,
	[110] = true,
	[112] = true,
	[114] = true,
	[116] = true,
	[118] = true,
	[120] = true,
	[122] = true,
	[124] = true,
	[126] = true,
	[128] = true,
	[130] = true,
	[132] = true,
	[135] = true,
	[146] = true,
	[148] = true,
}

local glide_inducing_yue = {
	[40] = true,
	[85] = true,
	[86] = true,
	[87] = true,
	[88] = true,
	[93] = true,
	[125] = true,
	[126] = true,
	[127] = true,
	[128] = true,
	[157] = true,
	[158] = true,
}

local debuccalisation_inducing_yue = {
    [1] = true,
    [2] = true,
    [3] = true,
    [4] = true,
    [5] = true,
    [6] = true,
    [7] = true,
    [8] = true,
    [9] = true,
    [10] = true,
    [11] = true,
    [12] = true,
    [13] = true,
    [14] = true,
    [15] = true,
    [16] = true,
    [17] = true,
    [18] = true,
    [19] = true,
    [20] = true,
    [21] = true,
    [22] = true,
    [23] = true,
    [24] = true,
    [25] = true,
    [26] = true,
    [27] = true,
    [28] = true,
    [29] = true,
    [30] = true,
    [31] = true,
    [32] = true,
    [33] = true,
    [34] = true,
    [35] = true,
    [36] = true,
    [37] = true,
    [38] = true,
    [39] = true,
    [40] = true,
    [41] = true,
    [42] = true,
    [43] = true,
    [44] = true,
    [45] = true,
    [46] = true,
    [47] = true,
    [48] = true,
    [49] = true,
    [50] = true,
    [51] = true,
    [52] = true,
    [53] = true,
    [54] = true,
    [55] = true,
    [56] = true,
    [57] = true,
    [58] = true,
    [59] = true,
    [60] = true,
    [61] = true,
    [62] = true,
    [63] = true,
    [64] = true,
    [65] = true,
    [66] = true,
    [67] = true,
    [68] = true,
    [69] = true,
    [70] = true,
    [71] = true,
    [72] = true,
    [73] = true,
    [74] = true,
    [75] = true,
    [76] = true,
    [77] = true,
    [78] = true,
    [79] = true,
    [80] = true,
    [81] = true,
    [82] = true,
    [83] = true,
    [84] = true,
    [85] = true,
    [86] = true,
    [87] = true,
    [88] = true,
    [89] = true,
    [90] = true,
    [91] = true,
    [92] = true,
    [93] = true,
    [94] = true,
    [95] = true,
    [96] = true,
    [97] = true,
    [98] = true,
    [99] = true,
    [100] = true,
    [101] = true,
    [102] = true,
    [103] = true,
    [104] = true,
    [105] = true,
    [106] = true,
    [107] = true,
    [108] = true,
    [109] = true,
    [110] = true,
    [111] = true,
    [112] = true,
    [113] = true,
    [114] = true,
    [115] = true,
    [116] = true,
    [117] = true,
    [118] = true,
    [119] = true,
    [120] = true,
    [121] = true,
    [122] = true,
    [123] = true,
    [124] = true,
    [125] = true,
    [126] = true,
    [127] = true,
    [128] = true,
    [129] = true,
    [130] = true,
    [131] = true,
    [132] = true,
    [133] = true,
    [134] = true,
    [135] = true,
    [136] = true,
    [137] = true,
    [138] = true,
    [139] = true,
    [140] = true,
    [141] = true,
    [142] = true,
    [143] = true,
    [144] = true,
    [145] = true,
    [146] = true,
    [147] = true,
    [148] = true,
    [149] = true,
    [150] = true,
    [151] = true,
    [152] = true,
    [153] = true,
    [154] = true,
    [155] = true,
    [156] = true,
    [157] = true,
    [158] = true,
    [159] = true,
    [160] = true,
}

function export.predict_yue(initial, final, tone)
	local initial_result = initial_outcomes_yue[initial]

	if fricativisation_inducing[final] and initial <= 3 then
		initial_result = "f"

	elseif tone == 1 and devoicing_initial_yue[initial] then
		initial_result = devoicing_outcomes[initial_result]

	elseif initial == 17 and labialisation_inducing_yue[final] then
		initial_result = "s"
	end

	if initial == 29 and debuccalisation_inducing_yue[final] then
		initial_result = "h"

	elseif initial == 29 and (final == 136 or final >= 139 and final <= 142)
		or initial == 32 and (final == 136 or final == 57)
		or initial == 33 and (labialisation_inducing_yue[final] or glide_inducing_yue[final])
		or initial_result == "" and palatalisation_inducing_yue[final] then
		initial_result = "j"
	end
	
	local final_result
	if (final == 36 or final == 38) and initial == 36 then
		final_result = "Ei"

	elseif (final == 26 or final == 42) and initial == 31 then
		final_result = "oi"

	elseif final == 23 and initial == 31 then
		final_result = ""

	elseif (final == 22 or final == 24) and initial == 4 then
		final_result = "ou"

	else
		local final_class = final_class_yue[final]
		final_result = rhyme_outcomes_yue[final_class]
		if final_class >= 35 then
			final_result = final_result[initial_class_yue[initial]]
		elseif final_class >= 21 then
			final_result = final_result[math.floor((initial_class_yue[initial] + 8) / 5)]
		end
	end

	if initial == 31 and mw.ustring.find(final_result, "^[iuIUOEY]") ~= nil then
		initial_result = "j"
	end

	if labialisation_inducing_yue[final] and mw.ustring.find(final_result, "^[OEY]") == nil then
		if initial_result == "h" and mw.ustring.find(final_result, "^[iI]") == nil then
			initial_result = "f"
		elseif initial_result == "j" or initial_result == "" then
			initial_result = "w"
		elseif initial_result == "g" and mw.ustring.find(final_result, "^[uU]") == nil then
			initial_result = "gw"
		elseif initial_result == "k" and mw.ustring.find(final_result, "^[iuIU]") == nil then
			initial_result = "kw"
		end
	end
	
	local tone_result
	if tone == 4 then
		if fully_voiced_initial[initial] or partially_voiced_initial[initial] then
			tone_result = 6
		elseif mw.ustring.find(final_result, "^[AiouOY]") ~= nil then
			tone_result = 3
		else
			tone_result = 1
		end
	elseif tone == 2 and fully_voiced_initial[initial] then
		tone_result = 6
	elseif fully_voiced_initial[initial] or partially_voiced_initial[initial] then
		tone_result = 3 + tone
	else
		tone_result = tone
	end

	final_result = mw.ustring.gsub(final_result, "om", "am")

	if initial <= 4 then
		final_result = mw.ustring.gsub(final_result, "m$", "n")
	end

	if tone == 4 then
		final_result = mw.ustring.gsub(final_result, "m$", "p")
		final_result = mw.ustring.gsub(final_result, "n$", "t")
		final_result = mw.ustring.gsub(final_result, "N$", "k")
	end

	final_result = mw.ustring.gsub(final_result, "A", "aa")
	final_result = mw.ustring.gsub(final_result, "I", "i")
	final_result = mw.ustring.gsub(final_result, "U", "u")
	final_result = mw.ustring.gsub(final_result, "O", "oe")
	final_result = mw.ustring.gsub(final_result, "E", "eo")
	final_result = mw.ustring.gsub(final_result, "Y", "yu")

	final_result = mw.ustring.gsub(final_result, "N", "ng")

	return initial_result .. final_result .. "<sup>" .. tone_result .. "</sup>"
end

return export