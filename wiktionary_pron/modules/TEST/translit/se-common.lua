local export = {}

local vowels_simp = {
	["ea"] = "ē",
	["ie"] = "ī",
	["oa"] = "ō",
	["uo"] = "ū"
}

local langdata = {
	consonant = {
		"^(.-[aạáeẹēiīoọōuūyAẠÁEẸĒIĪOỌŌUŪY])([iI][^aáeēiīoōuūyAÁEĒIĪOŌUŪY{}-]*)$",
		"^(.-)([^aạáeẹēiīoọōuūyAẠÁEẸĒIĪOỌŌUŪY{}-]*)$",
	},
	vowel = {
		"^(.-)(uo)$",
		"^(.-)(oa)$",
		"^(.-)(ea)$",
		"^(.-)(ie)$",
		"^(.-)([aạáeẹēiīoọōuūyAẠÁEẸĒIĪOỌŌUŪY]?)$",
	},
	scons = {
		[1] = {
			{"^[dhp]$"},
		},
		[2] = {
			{"^dj$", "j", "ddj"},
			{"^([đflmnŋrsšŧv])%1$", "%1", "%1ˈ%1"},
			{"^hc$", "z", "hcc"},
			{"^hč$", "ž", "hčč"},
			{"^hk$", "g", "hkk"},
			{"^hp$", "b", "hpp"},
			{"^ht$", "đ", "htt"},
			{"^h([jlmnr])%1$", "h%1", "h%1ˈ%1"},
			{"^kŋ$", "ŋ", "gŋ"},
			{"^pm$", "m", "bm"},
			{"^tn(j?)$", "n%1", "dn%1"},
			{"^nnj$", "nj", "nˈnj"},
		},
		[3] = {
			{"^bb$", "pp"},
			{"^dd$", "tt"},
			{"^gg$", "kk"},
			{"^zz$", "cc"},
			{"^žž$", "čč"},
			{"^llj$", "lj"},
			
			-- Clusters
			{"^lˈj$", "ljj"},
			{"^rbm$", "rpm"},
			{"^rdn$", "rtn"},
			{"^rdnj$", "rtnj"},
			{"^rgŋ$", "rkŋ"},
			{"^k(.*)(.)$", "v%1%2%2"},
			{"([^r])bm$", "%1mm"},
			{"([^r])dn(j?)$", "%1nn%2"},
			{"([^r])gŋ$", "%1ŋŋ"},
			
			{"^(đ)([bgjv])$", "%1%2%2"},
			{"^(i)([bcdgklprstv])$", "%1%2%2"},
			{"^(ih)([lmn])$", "%1%2%2"},
			{"^(is)([kmt])$", "%1%2%2"},
			{"^(l)([bcčdfgkpstv])$", "%1%2%2"},
			{"^(ls)([t])$", "%1%2%2"},
			{"^(m)([bpsš])$", "%1%2%2"},
			{"^(n)([cčdsštzž])$", "%1%2%2"},
			{"^(ns)([t])$", "%1%2%2"},
			{"^(ŋ)([gk])$", "%1%2%2"},
			{"^(p)([t])$", "%1%2%2"},
			{"^(r)([bcčdfgjkpsštvž])$", "%1%2%2"},
			{"^(rs)([kt])$", "%1%2%2"},
			{"^(s)([bfkmptv])$", "%1%2%2"},
			{"^(š)([kmpt])$", "%1%2%2"},
			{"^(t)([km])$", "%1%2%2"},
			{"^(v)([dgjklprstzž])$", "%1%2%2"},
			{"^(vh)([l])$", "%1%2%2"},
			
			{"^ij$"},
			{"^lfr$"},
		},
	},
	to_final = {
		-- Allowed consonants
		{"^[lnprsšt]$"},
		{"^i[dn]$"},
		
		-- Disallowed consonants
		{"^([bdgh])$", "t"},
		{"^([bdg])%1$", "t"},
		{"^h[kpt]$", "t"},
		{"^j$", "i"},
		{"^m$", "n"},
		{"^([sz])$", "s"},
		{"^([sz])%1$", "s"},
		{"^([šž])$", "š"},
		{"^([šž])%1$", "š"},
		
		-- Clusters
		{"^([lr])[dg]$", "%1"},
		{"^([lsš])[kmt]$", "%1"},
	},
	make_final_if = {
		"^$",
		"^[^aạáeẹēiīoọōuūyAẠÁEẸĒIĪOỌŌUŪY]",
	},
	vowel_variants = {
		normal        = {                                                                                                            },
		short         = {                                   ["i"] = {"ẹ"}     ,                                    ["u"] = {"ọ"}     },
		e             = {                                   ["i"] = {"á"}     ,                ["ọ"] = {"o", "S"}, ["u"] = {"o", "S"}},
		e_contr_j     = {["a"] = {"i", "S"}, ["e"] = {"i"}, ["i"] = {"á"}     , ["o"] = {"u"}, ["ọ"] = {"o", "S"}, ["u"] = {"u", "S"}},
		i             = {                                   ["i"] = {"e", "S"},                ["ọ"] = {"o", "S"}, ["u"] = {"o", "S"}},
		j             = {                    ["e"] = {"i"}, ["i"] = {"i", "S"}, ["o"] = {"u"},                     ["u"] = {"ū"}     },
		j_contr       = {["a"] = {"e", "S"},                ["i"] = {"e", "S"},                ["ọ"] = {"o", "S"}, ["u"] = {"o", "S"}},
		j_contr_final = {["a"] = {"i"}     ,                                                                                         },
		pres_12sg     = {                                   ["i"] = {"á"}     ,                                                      },
		pres_3sg      = {["a"] = {"á"}     ,                ["i"] = {"á"}     ,                                                      },
		impr          = {["a"] = {"o", "S"},                ["i"] = {"o", "S"},                ["ọ"] = {"o", "S"}, ["u"] = {"o", "S"}},
		impr_final    = {["a"] = {"u"}     ,                ["i"] = {"u"}     ,                                                      },
		contr_noun    = {["a"] = {"á"}     ,                ["i"] = {"á"}     ,                                    ["u"] = {"o", "S"}},
		contr_noun_j  = {["a"] = {"á"}     ,                ["i"] = {"á"}     , ["o"] = {"u"},                     ["u"] = {"u", "S"}},
	},
	postprocess = function(form, vowel_effect)
		if vowel_effect == "S" then
			form.svowel = vowels_simp[form.svowel] or form.svowel
		end
	end,
}

export.Stem = require("smi-common").make_constructor(langdata)

return export