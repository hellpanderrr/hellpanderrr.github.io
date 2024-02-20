local lang = require("languages").getByCode("se")

local export = {}
local output = {}


-- Inflection functions

function export.even(frame)
	local params = {
		[1] = {required = true, default = "{{{1}}}"},
		
		["output"] = {default = "table"},
	}
	
	local args = require("parameters").process(frame:getParent().args, params)
	local stem = require("se-common").Stem(args[1], true)
	
	local data = {
		forms = {},
		info = "even " .. require("links").full_link({lang = lang, alt = stem.uvowel}, "term") .. "-stem",
		categories = {},
	}
	
	if stem.gradation then
		data.info = data.info .. ", " ..
			require("links").full_link({lang = lang, alt = stem.gradation.strong.scons}, "term") .. "-" ..
			require("links").full_link({lang = lang, alt = stem.gradation.weak.scons}, "term") .. " gradation"
	else
		data.info = data.info .. ", no gradation"
	end
	
	if not mw.ustring.find(stem.uvowel, "^[aiu]$") and mw.title.getCurrentTitle().nsText ~= "Template" then
		error("The final vowel(s) of the stem must be one of a, i, u.")
	end
	
	table.insert(data.categories, lang:getCanonicalName() .. " even verbs")
	table.insert(data.categories, lang:getCanonicalName() .. " even " .. (stem.uvowel or "") .. "-stem verbs")
	
	data.forms["inf"]       = {stem:make_form{grade = "strong", ending = "t"}}
	data.forms["pres|ptcp"] = {stem:make_form{grade = "extra", variant = "j_contr_final"}}
	data.forms["past|ptcp"] = {stem:make_form{grade = "strong", ending = "n", variant = "e"}}
	data.forms["agnt|ptcp"] = {stem:make_form{grade = "strong", ending = "n"}}
	
	data.forms["anoun"]      = {stem:make_form{grade = "strong", ending = "n"}}
	data.forms["action|ine"] = {stem:make_form{grade = "strong", ending = "min"}, stem:make_form{grade = "strong", ending = "me"}}
	data.forms["action|ela"] = {stem:make_form{grade = "strong", ending = "mis"}}
	data.forms["action|com"] = {stem:make_form{grade = "strong", ending = "miin"}}
	data.forms["abe"]        = {stem:make_form{grade = "weak", ending = "keahttá", variant = "short"}}
	
	data.forms["1|s|pres|indc"] = {stem:make_form{grade = "weak", ending = "n", variant = "pres_12sg"}}
	data.forms["2|s|pres|indc"] = {stem:make_form{grade = "weak", ending = "t", variant = "pres_12sg"}}
	data.forms["3|s|pres|indc"] = {stem:make_form{grade = "strong", variant = "pres_3sg"}}
	data.forms["1|d|pres|indc"] = {stem:make_form{grade = "strong", variant = "j_contr"}}
	data.forms["2|d|pres|indc"] = {stem:make_form{grade = "strong", ending = "beahtti"}}
	data.forms["3|d|pres|indc"] = {stem:make_form{grade = "strong", ending = "ba"}}
	data.forms["1|p|pres|indc"] = {stem:make_form{grade = "strong", ending = "t"}}
	data.forms["2|p|pres|indc"] = {stem:make_form{grade = "strong", ending = "bēhtet"}}
	data.forms["3|p|pres|indc"] = {stem:make_form{grade = "strong", ending = "t", variant = "j_contr"}}
	data.forms["pres|indc|conn"] = {stem:make_form{grade = "weak", variant = "short"}}
	
	data.forms["1|s|past|indc"] = {stem:make_form{grade = "strong", ending = "n", variant = "j_contr"}}
	data.forms["2|s|past|indc"] = {stem:make_form{grade = "strong", ending = "t", variant = "j_contr"}}
	data.forms["3|s|past|indc"] = {stem:make_form{grade = "weak", ending = "i", variant = "j"}}
	data.forms["1|d|past|indc"] = {stem:make_form{grade = "weak", ending = "ime", variant = "j"}}
	data.forms["2|d|past|indc"] = {stem:make_form{grade = "weak", ending = "ide", variant = "j"}}
	data.forms["3|d|past|indc"] = {stem:make_form{grade = "weak", ending = "iga", variant = "j"}}
	data.forms["1|p|past|indc"] = {stem:make_form{grade = "weak", ending = "imet", variant = "j"}}
	data.forms["2|p|past|indc"] = {stem:make_form{grade = "weak", ending = "idet", variant = "j"}}
	data.forms["3|p|past|indc"] = {stem:make_form{grade = "strong", variant = "j_contr"}}
	data.forms["past|indc|conn"] = {stem:make_form{grade = "strong", ending = "n", variant = "e"}}
	
	data.forms["1|s|impr"] = {stem:make_form{grade = "strong", ending = "n", variant = "impr"}}
	data.forms["2|s|impr"] = {stem:make_form{grade = "weak", variant = "short"}}
	data.forms["3|s|impr"] = {stem:make_form{grade = "strong", ending = "s", variant = "impr"}}
	data.forms["1|d|impr"] = {stem:make_form{grade = "extra", variant = "impr_final"}}
	data.forms["2|d|impr"] = {stem:make_form{grade = "extra", variant = "j_contr_final"}}
	data.forms["3|d|impr"] = {stem:make_form{grade = "strong", ending = "ska", variant = "impr"}}
	data.forms["1|p|impr"] = {stem:make_form{grade = "strong", ending = "t", variant = "impr"}, stem:make_form{grade = "extra", ending = "t", variant = "impr_final"}}
	data.forms["2|p|impr"] = {stem:make_form{grade = "strong", ending = "t", variant = "j_contr"}, stem:make_form{grade = "extra", ending = "t", variant = "j_contr_final"}}
	data.forms["3|p|impr"] = {stem:make_form{grade = "strong", ending = "set", variant = "impr"}}
	data.forms["impr|conn"] = {stem:make_form{grade = "weak", variant = "short"}}
	
	data.forms["1|s|cond1"] = {stem:make_form{grade = "weak", ending = "šin", variant = "e"}, stem:make_form{grade = "weak", ending = "šedjen", variant = "e"}}
	data.forms["2|s|cond1"] = {stem:make_form{grade = "weak", ending = "šit", variant = "e"}, stem:make_form{grade = "weak", ending = "šedjet", variant = "e"}}
	data.forms["3|s|cond1"] = {stem:make_form{grade = "weak", ending = "šii", variant = "e"}}
	data.forms["1|d|cond1"] = {stem:make_form{grade = "weak", ending = "šeimme", variant = "e"}}
	data.forms["2|d|cond1"] = {stem:make_form{grade = "weak", ending = "šeidde", variant = "e"}}
	data.forms["3|d|cond1"] = {stem:make_form{grade = "weak", ending = "šeigga", variant = "e"}}
	data.forms["1|p|cond1"] = {stem:make_form{grade = "weak", ending = "šeimmet", variant = "e"}}
	data.forms["2|p|cond1"] = {stem:make_form{grade = "weak", ending = "šeiddet", variant = "e"}}
	data.forms["3|p|cond1"] = {stem:make_form{grade = "weak", ending = "še", variant = "e"}, stem:make_form{grade = "weak", ending = "šedje", variant = "e"}}
	data.forms["cond1|conn"] = {stem:make_form{grade = "weak", ending = "še", variant = "e"}}
	
	data.forms["1|s|cond2"] = {stem:make_form{grade = "weak", ending = "lin", variant = "e"}, stem:make_form{grade = "weak", ending = "ledjen", variant = "e"}}
	data.forms["2|s|cond2"] = {stem:make_form{grade = "weak", ending = "lit", variant = "e"}, stem:make_form{grade = "weak", ending = "ledjet", variant = "e"}}
	data.forms["3|s|cond2"] = {stem:make_form{grade = "weak", ending = "lii", variant = "e"}}
	data.forms["1|d|cond2"] = {stem:make_form{grade = "weak", ending = "leimme", variant = "e"}}
	data.forms["2|d|cond2"] = {stem:make_form{grade = "weak", ending = "leidde", variant = "e"}}
	data.forms["3|d|cond2"] = {stem:make_form{grade = "weak", ending = "leigga", variant = "e"}}
	data.forms["1|p|cond2"] = {stem:make_form{grade = "weak", ending = "leimmet", variant = "e"}}
	data.forms["2|p|cond2"] = {stem:make_form{grade = "weak", ending = "leiddet", variant = "e"}}
	data.forms["3|p|cond2"] = {stem:make_form{grade = "weak", ending = "le", variant = "e"}, stem:make_form{grade = "weak", ending = "ledje", variant = "e"}}
	data.forms["cond2|conn"] = {stem:make_form{grade = "weak", ending = "le", variant = "e"}}
	
	data.forms["1|s|potn"] = {stem:make_form{grade = "weak", ending = "žan", variant = "i"}}
	data.forms["2|s|potn"] = {stem:make_form{grade = "weak", ending = "žat", variant = "i"}}
	data.forms["3|s|potn"] = {stem:make_form{grade = "weak", ending = "ža", variant = "i"}, stem:make_form{grade = "weak", ending = "š", variant = "i"}}
	data.forms["1|d|potn"] = {stem:make_form{grade = "weak", ending = "žetne", variant = "i"}}
	data.forms["2|d|potn"] = {stem:make_form{grade = "weak", ending = "žeahppi", variant = "i"}}
	data.forms["3|d|potn"] = {stem:make_form{grade = "weak", ending = "žeaba", variant = "i"}}
	data.forms["1|p|potn"] = {stem:make_form{grade = "weak", ending = "žit", variant = "i"}, stem:make_form{grade = "weak", ending = "žat", variant = "i"}}
	data.forms["2|p|potn"] = {stem:make_form{grade = "weak", ending = "žēhpet", variant = "i"}}
	data.forms["3|p|potn"] = {stem:make_form{grade = "weak", ending = "žit", variant = "i"}}
	data.forms["potn|conn"] = {stem:make_form{grade = "weak", ending = "š", variant = "i"}}
	
	postprocess(args, data)
	
	return output[args["output"]](data)
end


function export.odd(frame)
	local params = {
		[1] = {required = true, default = "{{{1}}}"},
		
		["final"] = {},
		["output"] = {default = "table"},
	}
	
	local args = require("parameters").process(frame:getParent().args, params)
	local stem = require("se-common").Stem(args[1])
	
	local data = {
		forms = {},
		info = "odd, no gradation",
		categories = {},
	}
	
	if stem.ucons == "" and mw.title.getCurrentTitle().nsText ~= "Template" then
		error("The stem must end in a consonant.")
	end
	
	table.insert(data.categories, lang:getCanonicalName() .. " odd verbs")
	
	data.forms["inf"]       = {stem:make_form{ending = "it"}}
	data.forms["pres|ptcp"] = {stem:make_form{ending = "eaddji"}}
	data.forms["past|ptcp"] = {stem:make_form{ending = "an"}}
	data.forms["agnt|ptcp"] = {stem:make_form{ending = "an"}}
	
	data.forms["anoun"]      = {stem:make_form{ending = "eapmi"}}
	data.forms["action|ine"] = {stem:make_form{ending = "eamen"}, stem:make_form{ending = "eame"}}
	data.forms["action|ela"] = {stem:make_form{ending = "eamis"}}
	data.forms["action|com"] = {stem:make_form{ending = "ēmiin"}}
	data.forms["abe"]        = {stem:make_form{ending = "keahttá"}}
	
	data.forms["1|s|pres|indc"] = {stem:make_form{ending = "an"}}
	data.forms["2|s|pres|indc"] = {stem:make_form{ending = "at"}}
	data.forms["3|s|pres|indc"] = {stem:make_form{ending = "a"}}
	data.forms["1|d|pres|indc"] = {stem:make_form{ending = "etne"}}
	data.forms["2|d|pres|indc"] = {stem:make_form{ending = "eahppi"}}
	data.forms["3|d|pres|indc"] = {stem:make_form{ending = "eaba"}}
	data.forms["1|p|pres|indc"] = {stem:make_form{ending = "it"}, stem:make_form{ending = "at"}}
	data.forms["2|p|pres|indc"] = {stem:make_form{ending = "ēhpet"}}
	data.forms["3|p|pres|indc"] = {stem:make_form{ending = "it"}}
	data.forms["pres|indc|conn"] = {stem:make_form{}}
	
	data.forms["1|s|past|indc"] = {stem:make_form{ending = "in"}, stem:make_form{ending = "edjen"}}
	data.forms["2|s|past|indc"] = {stem:make_form{ending = "it"}, stem:make_form{ending = "edjet"}}
	data.forms["3|s|past|indc"] = {stem:make_form{ending = "ii"}}
	data.forms["1|d|past|indc"] = {stem:make_form{ending = "eimme"}}
	data.forms["2|d|past|indc"] = {stem:make_form{ending = "eidde"}}
	data.forms["3|d|past|indc"] = {stem:make_form{ending = "eigga"}}
	data.forms["1|p|past|indc"] = {stem:make_form{ending = "eimmet"}}
	data.forms["2|p|past|indc"] = {stem:make_form{ending = "eiddet"}}
	data.forms["3|p|past|indc"] = {stem:make_form{ending = "e"}, stem:make_form{ending = "edje"}}
	data.forms["past|indc|conn"] = {stem:make_form{ending = "an"}}
	
	data.forms["1|s|impr"] = {stem:make_form{ending = "ēhkon"}}
	data.forms["2|s|impr"] = {stem:make_form{}}
	data.forms["3|s|impr"] = {stem:make_form{ending = "ēhkos"}, stem:make_form{ending = "us"}}
	data.forms["1|d|impr"] = {stem:make_form{ending = "eadnu"}}
	data.forms["2|d|impr"] = {stem:make_form{ending = "eahkki"}}
	data.forms["3|d|impr"] = {stem:make_form{ending = "ēhkoska"}}
	data.forms["1|p|impr"] = {stem:make_form{ending = "ēhkot"}, stem:make_form{ending = "eatnot"}}
	data.forms["2|p|impr"] = {stem:make_form{ending = "ēhket"}}
	data.forms["3|p|impr"] = {stem:make_form{ending = "ēhkoset"}}
	data.forms["impr|conn"] = {stem:make_form{}}
	
	data.forms["1|s|cond1"] = {stem:make_form{ending = "ivččen"}}
	data.forms["2|s|cond1"] = {stem:make_form{ending = "ivččet"}}
	data.forms["3|s|cond1"] = {stem:make_form{ending = "ivččii"}}
	data.forms["1|d|cond1"] = {stem:make_form{ending = "ivččiime"}}
	data.forms["2|d|cond1"] = {stem:make_form{ending = "ivččiide"}}
	data.forms["3|d|cond1"] = {stem:make_form{ending = "ivččiiga"}}
	data.forms["1|p|cond1"] = {stem:make_form{ending = "ivččiimet"}}
	data.forms["2|p|cond1"] = {stem:make_form{ending = "ivččiidet"}}
	data.forms["3|p|cond1"] = {stem:make_form{ending = "ivčče"}}
	data.forms["cond1|conn"] = {stem:make_form{ending = "ivčče"}}
	
	data.forms["1|s|potn"] = {stem:make_form{ending = "eaččan"}}
	data.forms["2|s|potn"] = {stem:make_form{ending = "eaččat"}}
	data.forms["3|s|potn"] = {stem:make_form{ending = "eš"}, stem:make_form{ending = "eaš"}, stem:make_form{ending = "eažžá"}}
	data.forms["1|d|potn"] = {stem:make_form{ending = "ežže"}}
	data.forms["2|d|potn"] = {stem:make_form{ending = "eažžabeahtti"}}
	data.forms["3|d|potn"] = {stem:make_form{ending = "eažžaba"}}
	data.forms["1|p|potn"] = {stem:make_form{ending = "eažžat"}}
	data.forms["2|p|potn"] = {stem:make_form{ending = "eažžabehtet"}}
	data.forms["3|p|potn"] = {stem:make_form{ending = "ežžet"}}
	data.forms["potn|conn"] = {stem:make_form{ending = "eš"}, stem:make_form{ending = "eaš"}, stem:make_form{ending = "eačča"}}
	
	postprocess(args, data)
	
	return output[args["output"]](data)
end


function export.contr(frame)
	local params = {
		[1] = {required = true, default = "{{{1}}}"},
		
		["output"] = {default = "table"},
	}
	
	local args = require("parameters").process(frame:getParent().args, params)
	local stem = require("se-common").Stem(args[1])
	
	local data = {
		forms = {},
		info = "contracted " .. require("links").full_link({lang = lang, alt = stem.uvowel}, "term") .. "-stem, no gradation",
		categories = {},
	}
	
	if not mw.ustring.find(stem.uvowel, "^[áeo]$") and mw.title.getCurrentTitle().nsText ~= "Template" then
		error("The final vowel(s) of the stem must be one of á, e, o.")
	end
	
	table.insert(data.categories, lang:getCanonicalName() .. " contracted verbs")
	table.insert(data.categories, lang:getCanonicalName() .. " contracted " .. (stem.uvowel or "") .. "-stem verbs")
	
	data.forms["inf"]       = {stem:make_form{ending = "t"}}
	data.forms["pres|ptcp"] = {stem:make_form{ending = "jeaddji"}}
	data.forms["past|ptcp"] = {stem:make_form{ending = "n"}}
	data.forms["agnt|ptcp"] = {stem:make_form{ending = "n"}}
	
	data.forms["anoun"]      = {stem:make_form{ending = "n"}}
	data.forms["action|ine"] = {stem:make_form{ending = "min"}, stem:make_form{ending = "me"}}
	data.forms["action|ela"] = {stem:make_form{ending = "mis"}}
	data.forms["action|com"] = {stem:make_form{ending = "miin"}}
	data.forms["abe"]        = {stem:make_form{ending = "keahttá"}}
	
	data.forms["1|s|pres|indc"] = {stem:make_form{ending = "n"}}
	data.forms["2|s|pres|indc"] = {stem:make_form{ending = "t"}}
	data.forms["3|s|pres|indc"] = {stem:make_form{}}
	data.forms["1|d|pres|indc"] = {stem:make_form{ending = "jetne"}}
	data.forms["2|d|pres|indc"] = {stem:make_form{ending = "beahtti"}}
	data.forms["3|d|pres|indc"] = {stem:make_form{ending = "ba"}}
	data.forms["1|p|pres|indc"] = {stem:make_form{ending = "t"}}
	data.forms["2|p|pres|indc"] = {stem:make_form{ending = "bēhtet"}}
	data.forms["3|p|pres|indc"] = {stem:make_form{ending = "jit"}}
	data.forms["pres|indc|conn"] = {stem:make_form{}}
	
	data.forms["1|s|past|indc"] = {stem:make_form{ending = "jin"}}
	data.forms["2|s|past|indc"] = {stem:make_form{ending = "jit"}}
	data.forms["3|s|past|indc"] = {stem:make_form{ending = "i", variant = "j"}}
	data.forms["1|d|past|indc"] = {stem:make_form{ending = "ime", variant = "j"}}
	data.forms["2|d|past|indc"] = {stem:make_form{ending = "ide", variant = "j"}}
	data.forms["3|d|past|indc"] = {stem:make_form{ending = "iga", variant = "j"}}
	data.forms["1|p|past|indc"] = {stem:make_form{ending = "imet", variant = "j"}}
	data.forms["2|p|past|indc"] = {stem:make_form{ending = "idet", variant = "j"}}
	data.forms["3|p|past|indc"] = {stem:make_form{ending = "jedje"}}
	data.forms["past|indc|conn"] = {stem:make_form{ending = "n"}}
	
	data.forms["1|s|impr"] = {stem:make_form{ending = "jēhkon"}}
	data.forms["2|s|impr"] = {stem:make_form{}}
	data.forms["3|s|impr"] = {stem:make_form{ending = "jēhkos"}}
	data.forms["1|d|impr"] = {stem:make_form{ending = "jeadnu"}, stem:make_form{ending = "jeahkku"}}
	data.forms["2|d|impr"] = {stem:make_form{ending = "jeahkki"}}
	data.forms["3|d|impr"] = {stem:make_form{ending = "jēhkoska"}}
	data.forms["1|p|impr"] = {stem:make_form{ending = "jētnot"}, stem:make_form{ending = "jēhkot"}, stem:make_form{ending = "jeahkkot"}, stem:make_form{ending = "jeadnot"}}
	data.forms["2|p|impr"] = {stem:make_form{ending = "jēhket"}}
	data.forms["3|p|impr"] = {stem:make_form{ending = "jēhkoset"}}
	data.forms["impr|conn"] = {stem:make_form{}}
	
	data.forms["1|s|cond1"] = {stem:make_form{ending = "šin"}, stem:make_form{ending = "šedjen"}}
	data.forms["2|s|cond1"] = {stem:make_form{ending = "šit"}, stem:make_form{ending = "šedjet"}}
	data.forms["3|s|cond1"] = {stem:make_form{ending = "šii"}}
	data.forms["1|d|cond1"] = {stem:make_form{ending = "šeimme"}}
	data.forms["2|d|cond1"] = {stem:make_form{ending = "šeidde"}}
	data.forms["3|d|cond1"] = {stem:make_form{ending = "šeigga"}}
	data.forms["1|p|cond1"] = {stem:make_form{ending = "šeimmet"}}
	data.forms["2|p|cond1"] = {stem:make_form{ending = "šeiddet"}}
	data.forms["3|p|cond1"] = {stem:make_form{ending = "še"}, stem:make_form{ending = "šedje"}}
	data.forms["cond1|conn"] = {stem:make_form{ending = "še"}}
	
	data.forms["1|s|cond2"] = {stem:make_form{ending = "lin"}, stem:make_form{ending = "ledjen"}}
	data.forms["2|s|cond2"] = {stem:make_form{ending = "lit"}, stem:make_form{ending = "ledjet"}}
	data.forms["3|s|cond2"] = {stem:make_form{ending = "lii"}}
	data.forms["1|d|cond2"] = {stem:make_form{ending = "leimme"}}
	data.forms["2|d|cond2"] = {stem:make_form{ending = "leidde"}}
	data.forms["3|d|cond2"] = {stem:make_form{ending = "leigga"}}
	data.forms["1|p|cond2"] = {stem:make_form{ending = "leimmet"}}
	data.forms["2|p|cond2"] = {stem:make_form{ending = "leiddet"}}
	data.forms["3|p|cond2"] = {stem:make_form{ending = "le"}, stem:make_form{ending = "ledje"}}
	data.forms["cond2|conn"] = {stem:make_form{ending = "le"}}
	
	data.forms["1|s|potn"] = {stem:make_form{ending = "žan"}}
	data.forms["2|s|potn"] = {stem:make_form{ending = "žat"}}
	data.forms["3|s|potn"] = {stem:make_form{ending = "ža"}, stem:make_form{ending = "š"}}
	data.forms["1|d|potn"] = {stem:make_form{ending = "žetne"}}
	data.forms["2|d|potn"] = {stem:make_form{ending = "žeahppi"}}
	data.forms["3|d|potn"] = {stem:make_form{ending = "žeaba"}}
	data.forms["1|p|potn"] = {stem:make_form{ending = "žit"}, stem:make_form{ending = "žat"}}
	data.forms["2|p|potn"] = {stem:make_form{ending = "žēhpet"}}
	data.forms["3|p|potn"] = {stem:make_form{ending = "žit"}}
	data.forms["potn|conn"] = {stem:make_form{ending = "š"}}
	
	postprocess(args, data)
	
	return output[args["output"]](data)
end


function export.leat(frame)
	local params = {
		["output"] = {default = "table"},
	}
	
	local args = require("parameters").process(frame:getParent().args, params)
	
	local data = {
		forms = {},
		info = "odd, no gradation, irregular",
		categories = {lang:getCanonicalName() .. " odd verbs", lang:getCanonicalName() .. " irregular verbs"},
	}
	
	data.forms["inf"]   = {"leat", "leahkit"}
	data.forms["pres|ptcp"] = {"leahkki"}
	data.forms["past|ptcp"] = {"leamaš"}
	data.forms["agnt|ptcp"] = nil
	
	data.forms["anoun"]      = {"leapmi"}
	data.forms["action|ine"] = {"leamen", "leame", "leahkime"}
	data.forms["action|ela"] = {"leames"}
	data.forms["action|com"] = nil
	data.forms["abe"]        = nil
	
	data.forms["1|s|pres|indc"] = {"lean"}
	data.forms["2|s|pres|indc"] = {"leat"}
	data.forms["3|s|pres|indc"] = {"lea"}
	data.forms["1|d|pres|indc"] = {"letne"}
	data.forms["2|d|pres|indc"] = {"leahppi"}
	data.forms["3|d|pres|indc"] = {"leaba"}
	data.forms["1|p|pres|indc"] = {"leat"}
	data.forms["2|p|pres|indc"] = {"lēhpet"}
	data.forms["3|p|pres|indc"] = {"leat"}
	data.forms["pres|indc|conn"] = {"leat"}
	
	data.forms["1|s|past|indc"] = {"ledjen"}
	data.forms["2|s|past|indc"] = {"ledjet"}
	data.forms["3|s|past|indc"] = {"lei", "leai"}
	data.forms["1|d|past|indc"] = {"leimme"}
	data.forms["2|d|past|indc"] = {"leidde"}
	data.forms["3|d|past|indc"] = {"leigga", "leaigga"}
	data.forms["1|p|past|indc"] = {"leimmet"}
	data.forms["2|p|past|indc"] = {"leiddet"}
	data.forms["3|p|past|indc"] = {"ledje"}
	data.forms["past|indc|conn"] = {"lean"}
	
	data.forms["1|s|impr"] = {"lēhkon"}
	data.forms["2|s|impr"] = {"leagẹ"}
	data.forms["3|s|impr"] = {"lēhkos"}
	data.forms["1|d|impr"] = {"leadnu", "leahkku"}
	data.forms["2|d|impr"] = {"leahkki"}
	data.forms["3|d|impr"] = {"lēhkoska"}
	data.forms["1|p|impr"] = {"lēhkot", "leatnot"}
	data.forms["2|p|impr"] = {"lēhket"}
	data.forms["3|p|impr"] = {"lēhkoset"}
	data.forms["impr|conn"] = {"leagẹ"}
	
	data.forms["1|s|cond1"] = {"livččen"}
	data.forms["2|s|cond1"] = {"livččet"}
	data.forms["3|s|cond1"] = {"livččii"}
	data.forms["1|d|cond1"] = {"livččiime"}
	data.forms["2|d|cond1"] = {"livččiide"}
	data.forms["3|d|cond1"] = {"livččiiga"}
	data.forms["1|p|cond1"] = {"livččiimet"}
	data.forms["2|p|cond1"] = {"livččiidet"}
	data.forms["3|p|cond1"] = {"livčče"}
	data.forms["cond1|conn"] = {"livčče"}
	
	data.forms["1|s|potn"] = {"leaččan"}
	data.forms["2|s|potn"] = {"leaččat"}
	data.forms["3|s|potn"] = {"leš", "leaš", "leažžá"}
	data.forms["1|d|potn"] = {"ležže"}
	data.forms["2|d|potn"] = {"leažžabeahtti"}
	data.forms["3|d|potn"] = {"leažžaba"}
	data.forms["1|p|potn"] = {"leažžat"}
	data.forms["2|p|potn"] = {"leažžabehtet"}
	data.forms["3|p|potn"] = {"ležžet"}
	data.forms["potn|conn"] = {"leš", "leaš", "leačča"}
	
	postprocess(args, data)
	
	return output[args["output"]](data)
end


function postprocess(args, data)
	data.lemma = data.forms["inf"][1]
	data.forms["agnt|ptcp"] = nil  -- Remove until there's a reliable way to determine which verbs have it
	
	-- Check if the lemma form matches the page name
	if (lang:makeEntryName(data.lemma)) ~= mw.title.getCurrentTitle().text then
		table.insert(data.categories, lang:getCanonicalName() .. " entries with inflection not matching pagename")
	end
end


-- Make the table
output.table = function(data)
	local function repl(param)
		local accel = true
		local no_store = false
		
		if param == "info" then
			return mw.getContentLanguage():ucfirst(data.info or "")
		elseif string.sub(param, 1, 1) == "!" then
			no_store = true
			param = string.sub(param, 2)
		elseif string.sub(param, 1, 1) == "#" then
			accel = false
			param = string.sub(param, 2)
		end
		
		local forms = data.forms[param]
		
		if not forms then
			return "&mdash;"
		end
		
		local ret = {}
		
		for key, subform in ipairs(forms) do
			table.insert(ret, require("links").full_link({lang = lang, term = subform, accel = accel and {form = param, lemma = data.lemma, no_store = no_store} or nil}))
		end
		
		return table.concat(ret, "<br/>")
	end
	
	local wikicode = [=[
{| class="inflection-table vsSwitcher" data-toggle-category="inflection" style="border: solid 1px #CCCCFF;" cellspacing="1" cellpadding="2"
|- style="background: #E2F6E2; text-align: left;"
! class="vsToggleElement" colspan="4" | {{{info}}}
|- class="vsShow" style="background: #F2F2FF;"
! style="width: 11em; background: #E2F6E2;" | infinitive
| style="width: 15em;" colspan="2" | {{{!inf}}}
|- class="vsShow" style="background: #F2F2FF;"
! style="background: #E2F6E2;" | 1st&nbsp;sing.&nbsp;present
| colspan="2" | {{{!1|s|pres|indc}}}
|- class="vsShow" style="background: #F2F2FF;"
! style="background: #E2F6E2;" | 1st&nbsp;sing.&nbsp;past
| colspan="2" | {{{!1|s|past|indc}}}
|- class="vsHide" style="background: #F2F2FF;"
! style="background: #E2F6E2;" | infinitive
| data-accel-col="1" | {{{inf}}}
! style="background: #E2F6E2;" | action noun
| data-accel-col="2" | {{{#anoun}}}
|- class="vsHide" style="background: #F2F2FF;"
! style="background: #E2F6E2;" | present&nbsp;participle
| data-accel-col="1" | {{{pres|ptcp}}}
! style="background: #E2F6E2;" | action inessive
| data-accel-col="2" | {{{action|ine}}}
|- class="vsHide" style="background: #F2F2FF;"
! style="background: #E2F6E2;" | past&nbsp;participle
| data-accel-col="1" | {{{past|ptcp}}}
! style="background: #E2F6E2;" | action elative
| data-accel-col="2" | {{{action|ela}}}
|- class="vsHide" style="background: #F2F2FF;"
! style="background: #E2F6E2;" | agent&nbsp;participle
| data-accel-col="1" | {{{agnt|ptcp}}}
! style="background: #E2F6E2;" | action comitative
| data-accel-col="2" | {{{action|com}}}
|- class="vsHide" style="background: #F2F2FF;"
! style="background: #E2F6E2;" colspan="2" |
! style="background: #E2F6E2;" | abessive
| {{{abe}}}
|- class="vsHide"
! style="background: #C0E4C0; width: 11em;" |
! style="background: #C0E4C0; width: 15em;" | present indicative
! style="background: #C0E4C0; width: 15em;" | past indicative
! style="background: #C0E4C0; width: 15em;" | imperative
|- class="vsHide" style="background: #F2F2FF;"
! style="background: #E2F6E2;" | 1st&nbsp;singular
| data-accel-col="1" | {{{1|s|pres|indc}}}
| data-accel-col="2" | {{{1|s|past|indc}}}
| data-accel-col="3" | {{{1|s|impr}}}
|- class="vsHide" style="background: #F2F2FF;"
! style="background: #E2F6E2;" | 2nd&nbsp;singular
| data-accel-col="1" | {{{2|s|pres|indc}}}
| data-accel-col="2" | {{{2|s|past|indc}}}
| data-accel-col="3" | {{{2|s|impr}}}
|- class="vsHide" style="background: #F2F2FF;"
! style="background: #E2F6E2;" | 3rd&nbsp;singular
| data-accel-col="1" | {{{3|s|pres|indc}}}
| data-accel-col="2" | {{{3|s|past|indc}}}
| data-accel-col="3" | {{{3|s|impr}}}
|- class="vsHide" style="background: #F2F2FF;"
! style="background: #E2F6E2;" | 1st&nbsp;dual
| data-accel-col="1" | {{{1|d|pres|indc}}}
| data-accel-col="2" | {{{1|d|past|indc}}}
| data-accel-col="3" | {{{1|d|impr}}}
|- class="vsHide" style="background: #F2F2FF;"
! style="background: #E2F6E2;" | 2nd&nbsp;dual
| data-accel-col="1" | {{{2|d|pres|indc}}}
| data-accel-col="2" | {{{2|d|past|indc}}}
| data-accel-col="3" | {{{2|d|impr}}}
|- class="vsHide" style="background: #F2F2FF;"
! style="background: #E2F6E2;" | 3rd&nbsp;dual
| data-accel-col="1" | {{{3|d|pres|indc}}}
| data-accel-col="2" | {{{3|d|past|indc}}}
| data-accel-col="3" | {{{3|d|impr}}}
|- class="vsHide" style="background: #F2F2FF;"
! style="background: #E2F6E2;" | 1st&nbsp;plural
| data-accel-col="1" | {{{1|p|pres|indc}}}
| data-accel-col="2" | {{{1|p|past|indc}}}
| data-accel-col="3" | {{{1|p|impr}}}
|- class="vsHide" style="background: #F2F2FF;"
! style="background: #E2F6E2;" | 2nd&nbsp;plural
| data-accel-col="1" | {{{2|p|pres|indc}}}
| data-accel-col="2" | {{{2|p|past|indc}}}
| data-accel-col="3" | {{{2|p|impr}}}
|- class="vsHide" style="background: #F2F2FF;"
! style="background: #E2F6E2;" | 3rd&nbsp;plural
| data-accel-col="1" | {{{3|p|pres|indc}}}
| data-accel-col="2" | {{{3|p|past|indc}}}
| data-accel-col="3" | {{{3|p|impr}}}
|- class="vsHide" style="background: #F2F2FF;"
! style="background: #E2F6E2;" | connegative
| data-accel-col="1" | {{{pres|indc|conn}}}
| data-accel-col="2" | {{{past|indc|conn}}}
| data-accel-col="3" | {{{impr|conn}}}
|- class="vsHide"
! style="background: #C0E4C0;" |
! style="background: #C0E4C0;" | conditional&nbsp;1
! style="background: #C0E4C0;" | conditional&nbsp;2
! style="background: #C0E4C0;" | potential
|- class="vsHide" style="background: #F2F2FF;"
! style="background: #E2F6E2;" | 1st&nbsp;singular
| data-accel-col="4" | {{{1|s|cond1}}}
| data-accel-col="5" | {{{1|s|cond2}}}
| data-accel-col="6" | {{{1|s|potn}}}
|- class="vsHide" style="background: #F2F2FF;"
! style="background: #E2F6E2;" | 2nd&nbsp;singular
| data-accel-col="4" | {{{2|s|cond1}}}
| data-accel-col="5" | {{{2|s|cond2}}}
| data-accel-col="6" | {{{2|s|potn}}}
|- class="vsHide" style="background: #F2F2FF;"
! style="background: #E2F6E2;" | 3rd&nbsp;singular
| data-accel-col="4" | {{{3|s|cond1}}}
| data-accel-col="5" | {{{3|s|cond2}}}
| data-accel-col="6" | {{{3|s|potn}}}
|- class="vsHide" style="background: #F2F2FF;"
! style="background: #E2F6E2;" | 1st&nbsp;dual
| data-accel-col="4" | {{{1|d|cond1}}}
| data-accel-col="5" | {{{1|d|cond2}}}
| data-accel-col="6" | {{{1|d|potn}}}
|- class="vsHide" style="background: #F2F2FF;"
! style="background: #E2F6E2;" | 2nd&nbsp;dual
| data-accel-col="4" | {{{2|d|cond1}}}
| data-accel-col="5" | {{{2|d|cond2}}}
| data-accel-col="6" | {{{2|d|potn}}}
|- class="vsHide" style="background: #F2F2FF;"
! style="background: #E2F6E2;" | 3rd&nbsp;dual
| data-accel-col="4" | {{{3|d|cond1}}}
| data-accel-col="5" | {{{3|d|cond2}}}
| data-accel-col="6" | {{{3|d|potn}}}
|- class="vsHide" style="background: #F2F2FF;"
! style="background: #E2F6E2;" | 1st&nbsp;plural
| data-accel-col="4" | {{{1|p|cond1}}}
| data-accel-col="5" | {{{1|p|cond2}}}
| data-accel-col="6" | {{{1|p|potn}}}
|- class="vsHide" style="background: #F2F2FF;"
! style="background: #E2F6E2;" | 2nd&nbsp;plural
| data-accel-col="4" | {{{2|p|cond1}}}
| data-accel-col="5" | {{{2|p|cond2}}}
| data-accel-col="6" | {{{2|p|potn}}}
|- class="vsHide" style="background: #F2F2FF;"
! style="background: #E2F6E2;" | 3rd&nbsp;plural
| data-accel-col="4" | {{{3|p|cond1}}}
| data-accel-col="5" | {{{3|p|cond2}}}
| data-accel-col="6" | {{{3|p|potn}}}
|- class="vsHide" style="background: #F2F2FF;"
! style="background: #E2F6E2;" | connegative
| data-accel-col="4" | {{{cond1|conn}}}
| data-accel-col="5" | {{{cond2|conn}}}
| data-accel-col="6" | {{{potn|conn}}}
|}]=]

	return mw.ustring.gsub(wikicode, "{{{([#!]?[a-z0-9|]+)}}}", repl) .. require("utilities").format_categories(data.categories, lang)
end

output.Wikidata = function(data)
	local order = {
		"inf",
		"pres|ptcp",
		"past|ptcp",
		"agnt|ptcp",
		
		--"action|ine",
		--"action|ela",
		--"action|com",
		"abe",
		
		"1|s|pres|indc",
		"2|s|pres|indc",
		"3|s|pres|indc",
		"1|d|pres|indc",
		"2|d|pres|indc",
		"3|d|pres|indc",
		"1|p|pres|indc",
		"2|p|pres|indc",
		"3|p|pres|indc",
		"pres|indc|conn",
		
		"1|s|past|indc",
		"2|s|past|indc",
		"3|s|past|indc",
		"1|d|past|indc",
		"2|d|past|indc",
		"3|d|past|indc",
		"1|p|past|indc",
		"2|p|past|indc",
		"3|p|past|indc",
		"past|indc|conn",
		
		"1|s|impr",
		"2|s|impr",
		"3|s|impr",
		"1|d|impr",
		"2|d|impr",
		"3|d|impr",
		"1|p|impr",
		"2|p|impr",
		"3|p|impr",
		"impr|conn",
		
		"1|s|cond1",
		"2|s|cond1",
		"3|s|cond1",
		"1|d|cond1",
		"2|d|cond1",
		"3|d|cond1",
		"1|p|cond1",
		"2|p|cond1",
		"3|p|cond1",
		"cond1|conn",
		
		"1|s|cond2",
		"2|s|cond2",
		"3|s|cond2",
		"1|d|cond2",
		"2|d|cond2",
		"3|d|cond2",
		"1|p|cond2",
		"2|p|cond2",
		"3|p|cond2",
		"cond2|conn",
		
		"1|s|potn",
		"2|s|potn",
		"3|s|potn",
		"1|d|potn",
		"2|d|potn",
		"3|d|potn",
		"1|p|potn",
		"2|p|potn",
		"3|p|potn",
		"potn|conn",
	}
	
	local ret = {}
	
	for _, key in ipairs(order) do
		if data.forms[key] and data.forms[key][1] then
			for _, form in ipairs(data.forms[key]) do
				key = key:gsub("cond[12]", "cond")
				table.insert(ret, {
					representations = {[lang:getCode()] = {language = lang:getCode(), value = form}},
					grammaticalFeatures = require("form of").to_Wikidata_IDs(key, lang),
				})
			end
		end
	end
	
	return require("JSON").toJSON(ret)
end

return export