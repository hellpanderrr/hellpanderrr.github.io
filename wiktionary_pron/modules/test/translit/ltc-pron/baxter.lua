local export = {}
local m_string_utils = require("string utilities")

local gsub = m_string_utils.gsub
local match = m_string_utils.match

local baxter_initial = {
	[1] = "p", [2] = "ph", [3] = "b", [4] = "m", [5] = "t",
	[6] = "th", [7] = "d", [8] = "n", [9] = "tr", [10] = "trh",
	[11] = "dr", [12] = "nr", [13] = "ts", [14] = "tsh", [15] = "dz",
	[16] = "s", [17] = "z", [18] = "tsr", [19] = "tsrh", [20] = "dzr",
	[21] = "sr", [22] = "zr", [23] = "tsy", [24] = "tsyh", [25] = "dzy",
	[26] = "sy", [27] = "zy", [28] = "k", [29] = "kh", [30] = "g",
	[31] = "ng", [32] = "x", [33] = "h", [34] = "ʔ", [35] = "h",
	[36] = "y", [37] = "l", [38] = "ny"
}

local baxter_final = {
	[1] = "uwng", [2] = "juwng", [3] = "uwk", [4] = "juwk", [5] = "owng", 
	[6] = "owk", [7] = "jowng", [8] = "jowk", [9] = "æwng", [10] = "æwk", 
	[11] = "jie", [12] = "jwie", [13] = "je", [14] = "jwe", [15] = "jij", 
	[16] = "jwij", [17] = "ij", [18] = "wij", [19] = "i", [20] = "jɨj", 
	[21] = "jwɨj", [22] = "jo", [23] = "u", [24] = "ju", [25] = "aj", 
	[26] = "waj", [27] = "joj", [28] = "jwoj", [29] = "æj", [30] = "wæj", 
	[31] = "ɛɨ", [32] = "wɛɨ", [33] = "ɛj", [34] = "wɛj", [35] = "jiej", 
	[36] = "jwiej", [37] = "jej", [38] = "jwej", [39] = "ej", [40] = "wej", 
	[41] = "oj", [42] = "woj", [43] = "jin", [44] = "in", [45] = "win", 
	[46] = "in", [47] = "jwin", [48] = "jit", [49] = "it", [50] = "wit", 
	[51] = "it", [52] = "jwit", [53] = "on", [54] = "ot", [55] = "won", 
	[56] = "wot", [57] = "jɨn", [58] = "jɨt", [59] = "jun", [60] = "jut", 
	[61] = "an", [62] = "wan", [63] = "at", [64] = "wat", [65] = "jon", 
	[66] = "jwon", [67] = "jot", [68] = "jwot", [69] = "æn", [70] = "wæn", 
	[71] = "æt", [72] = "wæt", [73] = "ɛn", [74] = "wɛn", [75] = "ɛt", 
	[76] = "wɛt", [77] = "jien", [78] = "jwien", [79] = "jen", [80] = "jwen", 
	[81] = "jiet", [82] = "jwiet", [83] = "jet", [84] = "jwet", [85] = "en", 
	[86] = "wen", [87] = "et", [88] = "wet", [89] = "aw", [90] = "æw", 
	[91] = "jiew", [92] = "jew", [93] = "ew", [94] = "a", [95] = "wa", 
	[96] = "ja", [97] = "jwa", [98] = "æ", [99] = "wæ", [100] = "jæ", 
	[101] = "ang", [102] = "wang", [103] = "ak", [104] = "wak", [105] = "jang", 
	[106] = "jwang", [107] = "jak", [108] = "jwak", [109] = "æng", [110] = "wæng", 
	[111] = "jæng", [112] = "jwæng", [113] = "æk", [114] = "wæk", [115] = "jæk", 
	[116] = "jwæk", [117] = "ɛng", [118] = "wɛng", [119] = "ɛk", [120] = "wɛk", 
	[121] = "jieng", [122] = "jwieng", [123] = "jiek", [124] = "jwiek", [125] = "eng", 
	[126] = "weng", [127] = "ek", [128] = "wek", [129] = "ong", [130] = "wong", 
	[131] = "ok", [132] = "wok", [133] = "ing", [134] = "ik", [135] = "wik", 
	[136] = "juw", [137] = "uw", [138] = "jiw", [139] = "jim", [140] = "im", 
	[141] = "jip", [142] = "ip", [143] = "am", [144] = "ap", [145] = "jæm", 
	[146] = "jom", [147] = "jæp", [148] = "jop", [149] = "æm", [150] = "æp", 
	[151] = "ɛm", [152] = "ɛp", [153] = "jiem", [154] = "jem", [155] = "jiep", 
	[156] = "jep", [157] = "em", [158] = "ep", [159] = "om", [160] = "op"
}

local reverse_drjowngX_nrjuwX = {
	[11] = "je", [12] = "jwe", [15] = "ij", [16] = "wij", [35] = "jej", 
	[36] = "jwej", [43] = "in", [47] = "win", [48] = "it", [52] = "wit", 
	[77] = "jen", [78] = "jwen", [81] = "jet", [82] = "jwet", [91] = "jew", 
	[121] = "jeng", [122] = "jweng", [123] = "jek", [124] = "jwek", [138] = "iw", 
	[139] = "im", [141] = "ip", [153] = "jem", [155] = "jep"
}

local function is_coronal(initial_type)
	return (initial_type >= 5 and initial_type <= 27) or (initial_type >= 36 and initial_type <= 38)
end

local function is_labial(initial_type)
	return (initial_type >= 1 and initial_type <= 4)
end

local function is_palatal(initial_type)
	return (initial_type >= 23 and initial_type <= 27) or (initial_type == 36) or (initial_type == 38)
end

function export.baxter_1992(initial_type, final_type, tone_label)
	local initial = baxter_initial[initial_type]
	local final = baxter_final[final_type]
	if is_coronal(initial_type) then
		final = reverse_drjowngX_nrjuwX[final_type] or final
	end
	if is_palatal(initial_type) then
		final = string.gsub(final, "^j", "")
	elseif is_labial(initial_type) then 
		if (final_type ~= 42) and (final_type ~= 55) and (final_type ~= 56) then
			final = string.gsub(final, "^w", "")
			final = string.gsub(final, "^jw", "j")
		end
	end
	return initial .. final .. tone_label
end

local baxter_1992_to_2014_map = {
    {pattern = "ɛɨ", replace = "ɛ"},
    {pattern = "ɛ", replace = "ea"},
    {pattern = "æ", replace = "ae"},
    {pattern = "ɨ", replace = "+"},
    {pattern = "ʔ", replace = "'"},
}

function export.baxter_2014(initial_type, final_type, tone_label)
    local output = export.baxter_1992(initial_type, final_type, tone_label)
    for _, item in ipairs(baxter_1992_to_2014_map) do
		output = output:gsub(item.pattern, item.replace)
    end
    return output
end

export.baxter = export.baxter_2014

return export