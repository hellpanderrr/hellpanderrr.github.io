local export = {}
local u = mw.ustring.char
local pua = {}
for i = 1, 7 do
	pua[i] = u(0xF000+i-1)
end

local py_tone_num_to_mark = {
	["1"] = "̄",
	["2"] = "́",
	["3"] = "̌",
	["4"] = "̀"
}

local py_tone_mark_to_num = {}
for k, v in pairs(py_tone_num_to_mark) do
	py_tone_mark_to_num[v] = k
end

export.py_tone_num_to_mark = py_tone_num_to_mark
export.py_tone_mark_to_num = py_tone_mark_to_num

export.py_mark_priority = {
	"[iuü][aeêiouü]",
	"[aeê]",
	"o",
	"[iuü]",
	"[mn]"
}

export.tones = "[̄́̌̀]"

export.py_ipa_initials = {
	["b"] = "p", ["p"] = "pʰ",
	["d"] = "t", ["t"] = "tʰ",
	["g"] = "k", ["k"] = "kʰ", ["h"] = "x",
	["j"] = "t͡ɕ", ["q"] = "t͡ɕʰ", ["x"] = "ɕ",
	["ẑ"] = "ʈ͡ʂ", ["ĉ"] = "ʈ͡ʂʰ", ["ŝ"] = "ʂ",
	["r"] = "ʐ", ["z"] = "t͡s", ["c"] = "t͡sʰ",
}

export.py_ipa_initials_tl = {
	["p"] = "b̥",
	["t"] = "d̥",
	["k"] = "g̊",
	["t͡ɕ"] = "d͡ʑ̥",
	["ʈ͡ʂ"] = "ɖ͡ʐ̥",
	["t͡s"] = "d͡z̥",
}

export.py_ipa_finals = {
	["a"] = "ä", ["o"] = "ɔ", ["e"] = "ɤ", ["ê"] = "ɛ",
	["ai"] = "aɪ̯", ["ei"] = "eɪ̯",
	["au"] = "ɑʊ̯", ["ou"] = "oʊ̯",
	["em"] = "əm",
	["aim"] = "aɪ̯m",
	["an"] = "än", ["en"] = "ən", ["ên"] = "ɛn",
	["aŋ"] = "ɑŋ", ["oŋ"] = "ʊŋ", ["eŋ"] = "ɤŋ", ["êŋ"] = "ɛŋ",
	["ia"] = "i̯ä", ["io"] = "i̯ɔ", ["iê"] = "i̯ɛ",
	["iai"] = "i̯aɪ̯",
	["iau"] = "i̯ɑʊ̯", ["iou"] = "i̯oʊ̯",
	["ian"] = "i̯ɛn",
	["iaŋ"] = "i̯ɑŋ",
	["ua"] = "u̯ä", ["uo"] = "u̯ɔ", ["uê"] = "u̯ɛ",
	["uai"] = "u̯aɪ̯", ["uei"] = "u̯eɪ̯",
	["uom"] = "u̯ɔm",
	["uan"] = "u̯än", ["un"] = "u̯ən",
	["uaŋ"] = "u̯ɑŋ", ["uŋ"] = "u̯əŋ",
	["ü"] = "y", ["üo"] = "y̯ɔ", ["üê"] = "y̯ɛ",
	["üan"] = "y̯ɛn", ["ün"] = "yn",
	["üŋ"] = "i̯ʊŋ",
	["ɨ"] = "ʐ̩",
	["m"] = "m̩", ["n"] = "n̩", ["ŋ"] = "ŋ̍",
}

export.py_ipa_erhua = {
	{"än?", "[ɔɤɛʐ]̩?", "([ɑʊɤɛ])ŋ", "[iy]n?", "aɪ̯", "eɪ̯", "ɑʊ̯", "oʊ̯", "ən", "ɛn", "iŋ", "u", "əŋ"},
	{"ɑɻ", "%0ɻ", "%1̃ɻ", "%1ə̯ɻ", "ɑɻ", "əɻ", "aʊ̯ɻʷ", "ɤʊ̯ɻʷ", "əɻ", "ɑɻ", "iɤ̯̃ɻ", "uɻʷ", "ʊ̃ɻ"}
}

export.py_ipa_t_values = {
	["1"] = "⁵⁵",
	["1-2"] = "⁵⁵⁻³⁵",
	["1-4"] = "⁵⁵⁻⁵¹",
	["2"] = "³⁵",
	["3"] = "²¹⁴",
	["4"] = "⁵¹",
	["4-2"] = "⁵¹⁻³⁵",
}

export.py_ipa_tl_ts = {
	["1"] = "²",
	["2"] = "³",
	["3"] = "⁴",
	["4"] = "¹",
	["5"] = "¹"
}

export.py_zhuyin_consonant = {
	["b"] = "ㄅ", ["p"] = "ㄆ", ["m"] = "ㄇ", ["f"] = "ㄈ",
	["d"] = "ㄉ", ["t"] = "ㄊ", ["n"] = "ㄋ", ["l"] = "ㄌ",
	["g"] = "ㄍ", ["k"] = "ㄎ", ["h"] = "ㄏ",
	["j"] = "ㄐ", ["q"] = "ㄑ", ["x"] = "ㄒ",
	["ẑ"] = "ㄓ", ["ĉ"] = "ㄔ", ["ŝ"] = "ㄕ",
	["r"] = "ㄖ", ["z"] = "ㄗ", ["c"] = "ㄘ", ["s"] = "ㄙ",
	["v"] = "ㄪ", ["ŋ"] = "ㄫ", ["ɲ"] = "ㄬ"
}

export.py_zhuyin_glide = {
	["i"] = "ㄧ", ["u"] = "ㄨ", ["ü"] = "ㄩ", ["ɨ"] = ""
}

export.py_zhuyin_nucleus = {
	["a"] = "ㄚ", ["o"] = "ㄛ", ["e"] = "ㄜ", ["ê"] = "ㄝ"
}

export.py_zhuyin_final = {
	["ㄚㄧ"] = "ㄞ", ["ㄝㄧ"] = "ㄟ",
	["ㄚㄨ"] = "ㄠ", ["ㄛㄨ"] = "ㄡ",
	["ㄚㄋ"] = "ㄢ", ["ㄜㄋ"] = "ㄣ",
	["ㄚㄫ"] = "ㄤ", ["ㄜㄫ"] = "ㄥ"
}

export.py_zhuyin_syllabic_nasal = {
	["ㄇ"] = "ㆬ", ["ㄋ"] = "ㄯ", ["ㄫ"] = "ㆭ"
}

export.py_zhuyin_tone = {["1"] = "", ["2"] = "ˊ", ["3"] = "ˇ", ["4"] = "ˋ", ["5"] = "˙"}

export.zhuyin_py_initial = {
	["ㄅ"] = "b", ["ㄆ"] = "p", ["ㄇ"] = "m", ["ㄈ"] = "f",
	["ㄉ"] = "d", ["ㄊ"] = "t", ["ㄋ"] = "n", ["ㄌ"] = "l",
	["ㄍ"] = "g", ["ㄎ"] = "k", ["ㄏ"] = "h",
	["ㄐ"] = "j", ["ㄑ"] = "q", ["ㄒ"] = "x",
	["ㄓ"] = "zh", ["ㄔ"] = "ch", ["ㄕ"] = "sh",
	["ㄗ"] = "z", ["ㄘ"] = "c", ["ㄙ"] = "s", ["ㄖ"] = "r",
	["ㄭ"] = "i",
	["ㄪ"] = "v",
	[""] = ""
}

export.zhuyin_py_final = {
	['ㄚ'] = 'a', ['ㄛ'] = 'o', ['ㄜ'] = 'e', ['ㄝ'] = 'ê', ['ㄞ'] = 'ai', ['ㄟ'] = 'ei', ['ㄠ'] = 'ao', ['ㄡ'] = 'ou', ['ㄢ'] = 'an', ['ㄣ'] = 'en', ['ㄤ'] = 'ang', ['ㄥ'] = 'eng',
	['ㄧ'] = 'i', ['ㄧㄚ'] = 'ia', ['ㄧㄛ'] = 'io', ['ㄧㄝ'] = 'ie', ['ㄧㄞ'] = 'iai', ['ㄧㄠ'] = 'iao', ['ㄧㄡ'] = 'iu', ['ㄧㄢ'] = 'ian', ['ㄧㄣ'] = 'in', ['ㄧㄤ'] = 'iang', ['ㄧㄥ'] = 'ing',
	['ㄨ'] = 'u', ['ㄨㄚ'] = 'ua', ['ㄨㄛ'] = 'uo', ['ㄨㄞ'] = 'uai', ['ㄨㄟ'] = 'ui', ['ㄨㄢ'] = 'uan', ['ㄨㄣ'] = 'un', ['ㄨㄤ'] = 'uang', ['ㄨㄥ'] = 'ong',
	['ㄩ'] = 'ü', ['ㄩㄝ'] = 'ue', ['ㄩㄝ'] = 'üe', ['ㄩㄢ'] = 'üan', ['ㄩㄣ'] = 'ün', ['ㄩㄥ'] = 'iong',
	['ㄨㄝ'] = 'uê', ['ㄝㄋ'] = 'ên',
	['ㄦ'] = 'er', ['ㄫ'] = 'ng', ['ㄇ'] = 'm', [''] = 'i'
}

export.zhuyin_py_tone = {
	["ˊ"] = "\204\129", ["ˇ"] = "\204\140", ["ˋ"] = "\204\128", ["˙"] = "", [""] = "\204\132"	
}

export.py_wg_consonant = {
	["b"] = "p", ["p"] = "pʻ",
	["d"] = "t", ["t"] = "tʻ",
	["g"] = "k", ["k"] = "kʻ",
	["j"] = "ch", ["q"] = "chʻ", ["x"] = "hs",
	["ẑ"] = "ch", ["ĉ"] = "chʻ", ["ŝ"] = "sh",
	["r"] = "j", ["z"] = "ts", ["c"] = "tsʻ",
	["ŋ"] = "ng", ["ɲ"] = "gn"
}

export.py_wg_consonant_dental = {["z"] = "tz", ["c"] = "tzʻ", ["s"] = "ss"}

export.py_wg_glide = {["ɨ"] = "ih"}

export.py_wg_nucleus = {["e"] = "ê", ["ê"] = "eh"}

export.py_wg_o = {[""] = true, ["g"] = true, ["k"] = true, ["ŋ"] = true, ["h"] = true}

export.py_gwoyeu_initial = {
	['b'] = 'b',  ['p'] = 'p',  ['m'] = 'm',  ['f'] = 'f',
	['d'] = 'd',  ['t'] = 't',  ['n'] = 'n',  ['l'] = 'l',
	['g'] = 'g',  ['k'] = 'k',  ['h'] = 'h',
	['j'] = 'j',  ['q'] = 'ch',  ['x'] = 'sh',
	['zh'] = 'j', ['ch'] = 'ch', ['sh'] = 'sh', ['r'] = 'r',
	['z'] = 'tz', ['c'] = 'ts',  ['s'] = 's',
	['y'] = 'i',  ['w'] = 'u',
	['v'] = 'v',
	[''] = ''
}

export.py_gwoyeu_initials = export.py_gwoyeu_initial

export.py_gwoyeu_final = {
	['a'] = 'a',   ['ai'] = 'ai',  ['ao'] = 'au',   ['an'] = 'an',   ['ang'] = 'ang',   ['e'] = 'e',   ['ei'] = 'ei',  ['ou'] = 'ou',  ['en'] = 'en',  ['eng'] = 'eng',   ['o'] = 'o',
	['ia'] = 'ia',     ['iai'] = 'iai',    ['iao'] = 'iau',  ['ian'] = 'ian',  ['iang'] = 'iang',  ['ie'] = 'ie',          ['iu'] = 'iou',  ['in'] = 'in',  ['ing'] = 'ing',   ['i'] = 'i',
	['ua'] = 'ua',  ['uai'] = 'uai',         ['uan'] = 'uan',  ['uang'] = 'uang',  ['uo'] = 'uo',  ['ui'] = 'uei',         ['un'] = 'uen', ['ong'] = 'ong',   ['u'] = 'u',
	['ɨ'] = 'y',                  ['üan'] = 'iuan',          ['üe'] = 'iue',    ['üo'] = 'iuo',             ['ün'] = 'iun', ['iong'] = 'iong',  ['ü'] = 'iu',
	['io'] = 'io', ['ê'] = 'è', ['ên'] = 'èn', ['êng'] = 'èng',
	--erhua
	['ar'] = 'al',  ['air'] = 'al',  ['aor'] = 'aul',  ['anr'] = 'al',  ['angr'] = 'angl',  ['er'] = "e'l",  ['eir'] = 'el', ['our'] = 'oul', ['enr'] = 'el', ['engr'] = 'engl',  ['or'] = 'ol',
	['iar'] = 'ial',    ['iair'] = 'ial',    ['iaor'] = 'iaul', ['ianr'] = 'ial', ['iangr'] = 'iangl', ['ier'] = "ie'l",         ['iur'] = 'ioul', ['inr'] = 'iel', ['ingr'] = 'iengl', ['ir'] = 'iel',
	['uar'] = 'ual', ['uair'] = 'ual',         ['uanr'] = 'ual', ['uangr'] = 'uangl', ['uor'] = 'uol', ['uir'] = 'uel',        ['unr'] = 'uel', ['ongr'] = 'ongl',  ['ur'] = 'ul',
	['ɨr'] = 'el',                 ['üanr'] = 'iual',          ['üer'] = "iue'l",  ['üor'] = 'iuol',              ['ünr'] = 'iul', ['iongr'] = 'iongl', ['ür'] = 'iuel', ['ênr'] = 'èl', ['êngr'] = 'èngl',
}

export.py_gwoyeu_finals = export.py_gwoyeu_final

export.py_yale_initial = {
	["c"] = "ts", ["q"] = "ch", ["x"] = "sy", ["z"] = "dz"
}

export.py_yale_initials = {
	["q"] = "ch", ["x"] = "sy",
	["ẑ"] = "j", ["ĉ"] = "ch", ["ŝ"] = "sh",
	["z"] = "dz", ["c"] = "ts",
}

export.py_yale_one_medial = {
	["ê"] = "e", ["ü"] = "yu"
}

export.py_yale_two_medials = {
	["ao"] = "au", ["iu"] = "you", ["ui"] = "wei", ["un"] = "wun"
}

export.py_yale_finals = {
	["ê"] = "e",
	["ên"] = "en",
	["aŋ"] = "ang", ["oŋ"] = "ung", ["eŋ"] = "eng", ["êŋ"] = "eng",
	["ia"] = "ya", ["io"] = "yo", ["iê"] = "ye",
	["iai"] = "yai",
	["iau"] = "yau", ["iou"] = "you",
	["ian"] = "yan",
	["iaŋ"] = "yang",
	["ua"] = "wa", ["uo"] = "wo", ["uê"] = "we",
	["uai"] = "wai", ["uei"] = "wei",
	["uom"] = "wom",
	["uan"] = "wan", ["un"] = "wun",
	["uaŋ"] = "wang", ["uŋ"] = "wung",
	["ü"] = "yu", ["üo"] = "ywo", ["üê"] = "ywe",
	["üan"] = "ywan", ["ün"] = "yun",
	["üŋ"] = "ung",
	["ɨ"] = "r",
}

export.py_palladius_one_initial = {
	["b"] = "б", ["p"] = "п", ["m"] = "м", ["f"] = "ф", ["d"] = "д", ["t"] = "т", ["n"] = "н",
	["l"] = "л", ["g"] = "г", ["k"] = "к", ["h"] = "х", ["j"] = "цз", ["q"] = "ц", ["x"] = "с",
	["r"] = "ж", ["z"] = "цз" .. pua[1], ["c"] = "ц" .. pua[1], ["s"] = "с" .. pua[1],
	["v"] = "в" .. pua[2], ["w"] = "в", ["y"] = "i"
}
	
export.py_palladius_two_initials = {
	["zh"] = "чж", ["ch"] = "ч", ["sh"] = "ш"
}
	
export.py_palladius_one_medial = {
	["a"] = "а", ["e"] = "э", ["i"] = "и",
	["o"] = "о", ["u"] = "у", ["ü"] = "юй"
}
	
export.py_palladius_two_medials = {
	["ai"] = "ай", ["ao"] = "ао", ["ê"] = "эй", ["ei"] = "эй",
	["ia"] = "я", ["ie"] = "е", ["io"] = "йо", ["iu"] = "ю", ["iü"] = "юй",
	["ou"] = "оу", ["ua"] = "уа", ["ui"] = "уй", ["uo"] = "о",
	["üa"] = "юа", ["üe"] = "юэ"
}
	
export.py_palladius_three_medials = {
	["iai"] = "яй", ["iao"] = "яо", ["iüa"] = "юа", ["iüe"] = "юэ",
	["uai"] = "уай"
}
	
export.py_palladius_final = {
	["m"] = "м", ["n"] = "нь", ["r"] = "р"
}

export.py_palladius_finals = export.py_palladius_final
	
export.py_palladius_specials = {
	["ву"] = "у", ["йон"] = "юн", ["йоу"] = "ю", [pua[1] .. "и"] = "ы", ["ии"] = "и", ["йн"] = "н", ["он"] = "ун", ["юу"] = "ю", ["хуй"] = "хуэй",
}

-- Note: Russian Cyrillic uses curly apostrophes.
export.py_palladius_disambig = {
	[pua[3] .. "а"] = "’а", [pua[3] .. "н" .. pua[7]] = "’н", [pua[3] .. "нь" .. pua[7]] = "’нь", [pua[3] .. "эй"] = "’эй",
	[pua[4] .. "у"] = "’у",
	[pua[5] .. "о"] = "’о", [pua[5] .. "н" .. pua[7]] = "’н", [pua[5] .. "нь" .. pua[7]] = "’нь",
	[pua[6] .. "н" .. pua[7]] = "’н", [pua[6] .. "нь" .. pua[7]] = "’нь",
}

return export