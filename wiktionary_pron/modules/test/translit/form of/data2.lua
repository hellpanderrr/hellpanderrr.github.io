--[=[

This module lists the less common recognized inflection tags, in the same format as for [[Module:form of/data]] (which
contains the more common tags). We split the tags this way to save memory, so we avoid loading the less common tags in
the majority of cases.
]=]

local m_form_of = require("form of")

local APPENDIX = m_form_of.APPENDIX
local WP = m_form_of.WP
local WIKT = m_form_of.WIKT

local tags = {}
local shortcuts = {}


----------------------- Person -----------------------

tags["fourth-person"] = {
	"person",
	"wikt:fourth person",
	"4",
	3348541,
}

tags["second-person-object form"] = {
	"person",
	APPENDIX,
	"2o",
}

----------------------- Number -----------------------

tags["associative plural"] = {
	"number",
	WIKT,
	{"ass p", "ass pl", "assoc p", "assoc pl"},
}

tags["collective"] = {
	"number",
	"collective number",
	"col",
	694268,
}

tags["collective-possession"] = {
	"number",
	"collective number",
	{"cpos", "colpos"},
}

tags["distributive paucal"] = {
	"number",
	WIKT,
	"dpau",
}

tags["paucal"] = {
	"number",
	WIKT,
	"pau",
	489410,
}

tags["singulative"] = {
	"number",
	"singulative number",
	"sgl",
	1450795,
}

tags["transnumeral"] = {
	"number",
	APPENDIX,
	"trn",
	113631596,
	display = "singular or plural",
}

tags["trial"] = {
	"number",
	"trial number",
	"tri",
	2142560,
}


----------------------- Gender -----------------------

tags["natural feminine"] = {
	"gender",
	"gender",
	"natf",
}

tags["virile"] = {
	"gender",
	APPENDIX,
	"vr",
}


----------------------- Animacy -----------------------


----------------------- Tense/aspect -----------------------

tags["abtemporal"] = {
	"tense-aspect",
	WIKT,
	"abtemp",
}

tags["anterior"] = {
	"tense-aspect",
	"w:relative and absolute tense",
	"ant",
}

tags["cessative"] = {
	"tense-aspect",
	WP,
	"cess",
	17027342,
}

-- Aspect in Tagalog; presumably similar to the perfect tense/aspect but not necessarily similar enough to use the same
-- Wikidata ID
tags["complete"] = {
	"tense-aspect",
	"w:Tagalog grammar#Aspect",
	"compl",
}

tags["concomitant"] = {
	"tense-aspect",
	WIKT,
	"concom",
}

tags["confirmative"] = {
	"tense-aspect",
	WIKT,
	"conf",
}

-- Aspect in Tagalog
tags["contemplative"] = {
	"tense-aspect",
	"w:Tagalog grammar#Aspect",
	"contem",
}

tags["contemporal"] = {
	"tense-aspect",
	WIKT,
	"contemp",
}

tags["continuative"] = {
	"tense-aspect",
	WP,
	nil,
	28130104,
}

tags["continuous"] = {
	"tense-aspect",
	"w:continuous aspect",
	"cont",
	12721117,
}

tags["delimitative"] = {
	"tense-aspect",
	"w:delimitative aspect",
	"delim",
	5316270,
}

tags["durative"] = {
	"tense-aspect",
	WP,
	"dur",
}

tags["futuritive"] = {
	"tense-aspect",
	WP,
	{"futv", "futrv"},
}

tags["frequentative"] = {
	"tense-aspect",
	WP,
	"freq",
	467562,
}

tags["habitual"] = {
	"tense-aspect",
	"w:habitual aspect",
	"hab",
	5636904,
}

-- same as the habitual; used in Mongolian linguistics
tags["habitive"] = {
	"tense-aspect",
	WP,
	"habv",
}

tags["immediative"] = {
	"tense-aspect",
	WIKT,
	{"imm", "immed"},
}

tags["incidental"] = {
	"tense-aspect",
	WIKT,
	"incid",
}

tags["iterative"] = {
	"tense-aspect",
	"w:iterative aspect",
	"iter",
	2866772,
}

tags["momentane"] = {
	"tense-aspect",
	WP,
	nil,
	6897160,
}

tags["momentaneous"] = {
	"tense-aspect",
	WIKT,
	"mom",
	115110791,
}

tags["posterior"] = {
	"tense-aspect",
	"w:relative and absolute tense",
	"post",
}

tags["preconditional"] = {
	"tense-aspect",
	WIKT,
	"precond",
}

-- Type of participle in Hindi; also called agentive or agentive-prospective
tags["prospective"] = {
	"tense-aspect",
	"w:prospective aspect",
	"pros",
}

tags["purposive"] = {
	"tense-aspect",
	WIKT,
	"purp",
}

-- Aspect in Tagalog; presumably similar to the perfect tense/aspect but not necessarily similar enough to use the same
-- Wikidata ID
tags["recently complete"] = {
	"tense-aspect",
	"w:Tagalog grammar#Aspect",
	"rcompl",
}

tags["resultative"] = {
	"tense-aspect",
	WP,
	"res",
	7316356,
}

tags["semelfactive"] = {
	"tense-aspect",
	WP,
	"semf",
	7449203,
}

tags["serial"] = {
	"tense-aspect",
	WIKT,
	"ser",
}

tags["successive"] = {
	"tense-aspect",
	WIKT,
	"succ",
}

-- be careful not to clash with terminative case tag
tags["terminative aspect"] = {
	"tense-aspect",
	"w:cessative aspect",
	"term",
	display = "terminative",
}

----------------------- Mood -----------------------

tags["benedictive"] = {
	"mood",
	WP,
	"bened",
	4887358,
}

tags["cohortative"] = {
	"mood",
	"w:cohortative mood",
	{"coho", "cohort"},
}

tags["concessive"] = {
	"mood",
	WIKT,
	"conc",
}

tags["contrafactual"] = {
	"mood",
	WIKT,
	"cfact",
	110323459,
}

-- Same as the contrafactual, but terminology depends on language.
tags["counterfactual"] = {
	"mood",
	WP,
	"counterf",
	1783264, -- for "counterfactual conditional"
}

tags["desiderative"] = {
	"mood",
	WP,
	{"des", "desid"},
	1200631,
}

tags["dubitative"] = {
	"mood",
	"w:dubitative mood",
	"dub",
	1263049,
}

tags["energetic"] = {
	"mood",
	"w:energetic mood",
	"ener",
}

tags["inferential"] = {
	"mood",
	"w:inferential mood",
	{"infer", "infr"},
	-- Per [[w:inferential mood]], also called "renarrative mood" or (in Estonian) "oblique mood" (but
	-- "renarrative mood" may be different, see its entry).
	3332616,
}

-- It's not clear that this is exactly a mood, but I'm not sure where
-- else to group it
tags["intensive"] = {
	"mood",
	WP,
	"inten",
	10965321, -- for "intensive word form"
}

tags["intentional"] = {
	"mood",
	WIKT,
	"intent",
}

tags["interrogative"] = {
	"mood",
	WP,
	{"interr", "interrog"},
	12021746,
}

tags["necessitative"] = {
	"mood",
	WIKT,
	"nec",
}

tags["permissive"] = {
	"mood",
	"w:permissive mood",
	"perm",
	4351483,
}

tags["potential"] = {
	"mood",
	"w:potential mood",
	"potn",
	2296856,
}

tags["precative"] = {
	"mood",
	WIKT,
	"prec",
}

tags["prescriptive"] = {
	"mood",
	WIKT,
	"prescr",
}

tags["presumptive"] = {
	"mood",
	"w:presumptive mood",
	"presump",
	25463575,
}

-- Exists at least in Estonian
tags["quotative"] = {
	"mood",
	"w:quotative evidential mood",
	"quot",
	-- 7272884, -- this is for "quotative" morphemes, not the same
}

tags["renarrative"] = {
	"mood",
	"w:renarrative mood",
	"renarr",
	-- Per [[w:inferential mood]], renarrative and inferential mood are the same; but per
	-- [[w:Bulgarian verbs#Evidentials]], they are different, and Bulgarian has both.
	3332616,
}

tags["volitive"] = {
	"mood",
	"w:volitive mood",
	"voli",
	10716592,
}

tags["voluntative"] = {
	"mood",
	WIKT,
	{"voln", "volun"},
}


----------------------- Voice/valence -----------------------

tags["antipassive"] = {
	"voice-valence",
	"w:antipassive voice",
	{"apass", "apasv", "apsv"},
	287232,
}

tags["applicative"] = {
	"voice-valence",
	"w:applicative voice",
	"appl",
	621634,
}

tags["cooperative"] = { -- ("all together") used in Mongolian
	"voice-valence",
	"wikt:cooperative voice",
	"coop",
	114033228,
}

tags["pluritative"] = { -- ("many together") used in Mongolian
	"voice-valence",
	"wikt:pluritative voice",
	"plur",
	114033289,
}

tags["reciprocal"] = {
	"voice-valence",
	"w:reciprocal (grammar)",
	{"recp", "recip"},
	1964083,
}

-- Specific to Modern Irish, similar to impersonal
tags["autonomous"] = {
	"voice-valence",
	WIKT,
	"auton",
}


----------------------- Non-finite -----------------------

-- be careful not to clash with agentive case tag
tags["agentive"] = {
	"non-finite",
	"w:agent noun",
	{"ag", "agent"},
}

-- Latin etc.
tags["gerundive"] = {
	"non-finite",
	WP,
	"gerv",
	731298, -- Wikidata claims this is a grammatical mood, which is not really correct
}

-- Old Irish etc.
tags["verbal of necessity"] = {
	"non-finite",
	"w:gerundive",
	"verbnec",
	731298, -- gerundive
}

tags["l-participle"] = {
	"non-finite",
	"participle",
	{"l-ptcp", "lptcp"},
	814722,  -- "participle"
}

-- Finnish agent participle
tags["agent participle"] = {
	"non-finite",
	"w:Finnish grammar#Agent participle",
	"agentpart",
}

-- Hungarian participle
tags["verbal participle"] = {
	"non-finite",
	WIKT,
	nil,
	2361676, -- attributive verb, aka verbal participle
}

tags["converb"] = {
	"non-finite",
	WP,
	"conv",
	149761,
}

tags["connegative"] = {
	"non-finite",
	APPENDIX,
	{"conn", "conneg"},
	5161718,
}

-- Occurs in Hindi as a type of participle used to conjoin two clauses; similarly occurs in Japanese as the "te-form"
tags["conjunctive"] = {
	"non-finite",
	"w:serial verb construction", -- FIXME! No good link for "conjunctive"; another possibility is "converb"
	"conj",
}

tags["absolutive verb form"] = {
	"non-finite",
	"wikt:absolutive#Noun",
	"absvf",
	display = "absolutive",
}

-- FIXME! Should this be a mood?
tags["debitive"] = {
	"non-finite",
	WP,
	"deb",
	17119041,
}


----------------------- Case -----------------------

tags["abessive"] = {
	"case",
	"w:abessive case",
	"abe",
	319822,
}

tags["absolutive"] = {
	"case",
	"w:absolutive case",
	"absv", -- FIXME, find uses of "abs" = absolutive
	332734,
}

tags["adessive"] = {
	"case",
	"w:adessive case",
	"ade",
	281954,
}

-- be careful not to clash with adverbial grammar tag
tags["adverbial case"] = {
	"case",
	WP,
	"advc",
	display = "adverbial",
}

-- be careful not to clash with agentive non-finite tag
tags["agentive case"] = {
	"case",
	WP,
	"agc",
	display = "agentive",
}

tags["allative"] = {
	"case",
	"wikt:allative case",
	"all",
	655020,
}

--No evidence of the existence of this case on the web, and the shortcuts are better used elsewhere.
--tags["anterior"] = {
--	"case",
--	nil,
--	{"ant"},
--}

tags["associative"] = {
	"case",
	"w:associative case",
	{"ass", "assoc"},
	15948746,
}

tags["benefactive"] = {
	"case",
	"w:benefactive case",
	{"ben", "bene"},
	664905,
}

tags["causal"] = {
	"case",
	"w:causal case",
	{"cauc", "causc"},
	2943136,
}

tags["causal-final"] = {
	"case",
	"w:causal-final case",
	{"cfi", "cfin"},
	18012653,
}

tags["comitative"] = {
	"case",
	"w:comitative case",
	"com",
	838581,
}

-- be careful not to clash with comparative degree
tags["comparative case"] = {
	"case",
	WP,
	"comc",
	5155633,
	display = "comparative",
}

tags["delative"] = {
	"case",
	"w:delative case",
	"del",
	1183901,
}

tags["direct"] = {
	"case",
	"w:direct case",
	"dir",
	1751855,
}

tags["directive"] = {
	"case",
	"wikt:directive case",
	"dirc",
	56526905,
}

tags["distributive"] = {
	"case",
	"w:distributive case",
	{"dis", "dist", "distr"},
	492457,
}

tags["elative"] = {
	"case",
	"elative case",
	"ela",
	394253,
}

tags["ergative"] = {
	"case",
	"ergative case",
	"erg",
	324305,
}

-- be careful not to clash with equative degree tag
tags["equative"] = {
	"case",
	"w:equative case",
	"equc",
	3177653,
}

tags["essive-formal"] = {
	"case",
	"w:essive-formal case",
	{"esf", "efor"},
	3827688,
}

tags["essive-modal"] = {
	"case",
	"w:essive-modal case",
	{"esm", "emod"},
	3827703,
}

tags["essive"] = {
	"case",
	"w:essive case",
	"ess",
	148465,
}

--No evidence of the existence of this case on the web, and the shortcuts are better used elsewhere.
--tags["exclusive"] = {
--	"case",
--	nil,
--	{"exc", "excl"},
--}

tags["illative"] = {
	"case",
	"w:illative case",
	"ill",
	474668,
}

tags["indirect"] = {
	"case",
	"w:direct case",
	"indir",
	1233197, -- Same as oblique.
}

tags["inessive"] = {
	"case",
	"w:inessive case",
	"ine",
	282031,
}

tags["instructive"] = {
	"case",
	"w:instructive case",
	"ist",
	1665275,
}

tags["lative"] = {
	"case",
	"w:lative case",
	"lat",
	260425,
}

tags["limitative"] = {
	"case",
	"w:list of grammatical cases",
	"lim",
	35870079,
}

tags["locative-qualitative"] = {
	"case",
	"locative-qualitative case",
	{"lqu", "lqua"},
}

tags["objective"] = {
	"case",
	"objective case",
	"objv", -- obj used for "object"
	1233197, -- Same as oblique.
}

tags["oblique"] = {
	"case",
	"oblique case",
	"obl",
	1233197,
}

tags["partitive"] = {
	"case",
	"w:partitive case",
	{"ptv", "par"},
	857325,
}

--certain languages use this term for the abessive
tags["privative"] = {
	"case",
	"w:privative case",
	"priv",
	319822,
}

tags["prolative"] = {
	"case",
	"w:prolative case",
	{"pro", "prol"},
	952933,
}

tags["sociative"] = {
	"case",
	"w:sociative case",
	"soc",
	3773161,
}

tags["subjective"] = {
	"case",
	"w:subjective case",
	{"subjv", "sbjv"}, -- "sub" and "subj" used for subjunctive, "sbj" for "subject"
	131105, -- Same as nominative.
}

tags["sublative"] = {
	"case",
	"w:sublative case",
	{"sbl", "subl"},
	2120615,
}

tags["superessive"] = {
	"case",
	"w:superessive case",
	{"spe", "supe"},
	222355,
}

tags["temporal"] = {
	"case",
	"w:temporal case",
	{"tem", "temp"},
	3235219,
}

-- be careful not to clash with terminative aspect tag
tags["terminative case"] = {
	"case",
	WP,
	"ter",
	747019,
	display = "terminative",
}

tags["translative"] = {
	"case",
	"w:translative case",
	{"tra", "tran"},
	950170,
}


----------------------- State -----------------------

tags["independent genitive"] = {
	"state",
	WIKT,
	"indgen",
}

tags["possessor"] = {
	"state",
	WIKT,
	{"posr", "possr"},
}

tags["reflexive possessive"] = {
	"state",
	WIKT,
	{"reflposs", "refl poss"},
}

tags["substantive"] = {
	"state",
	APPENDIX,
	{"subs", "subst"},
}


----------------------- Degrees of comparison -----------------------

tags["absolute superlative degree"] = {
	"comparison",
	"wikt:absolute superlative",
	{"asupd", "absolute superlative"},
}

tags["relative superlative degree"] = {
	"comparison",
	"wikt:relative superlative",
	{"rsupd", "relative superlative"},
}

tags["elative degree"] = {
	"comparison",
	"elative",
	"elad",  -- Can't use "elative" as shortcut because that's already used for the elative case
	1555419,
}

-- be careful not to clash with equative case tag
tags["equative degree"] = {
	"comparison",
	"w:equative",
	"equd",
	5384239,
}

tags["excessive degree"] = {
	"comparison",
	nil,
	"excd",
}


----------------------- Register -----------------------

tags["familiar"] = {
	"register",
	"w:T–V distinction",
	"fam",
}

tags["polite"] = {
	"register",
	"w:T–V distinction",
	"pol",
}

tags["intimate"] = {
	"register",
	-- "intimate" is also a possible formality level in the sociolinguistic register sense.
	"w:T–V distinction",
	"intim",
}

tags["formal"] = {
	"register",
	"w:register (sociolinguistics)",
}

tags["informal"] = {
	"register",
	"w:register (sociolinguistics)",
	"inform",
}

tags["colloquial"] = {
	"register",
	"w:colloquialism",
	"colloq",
}

tags["slang"] = {
	"register",
	WP,
}

tags["contemporary"] = {
	"register",
	WIKT,
	"conty",
}

tags["literary"] = {
	"register",
	"w:literary language",
	"lit",
}

tags["dated"] = {
	"register",
	WIKT,
}

tags["archaic"] = {
	"register",
	"w:archaism",
	"arch",
}

tags["obsolete"] = {
	"register",
	WIKT,
	"obs",
}

tags["emphatic"] = {
	"register",
	WIKT,
	"emph",
}


----------------------- Deixis -----------------------

tags["proximal"] = {
	"deixis",
	"w:deixis",
	{"prox", "prxl"},
}

tags["medial"] = {
	"deixis",
	"w:deixis",
	"medl",
}

tags["distal"] = {
	"deixis",
	"w:deixis",
	"dstl",
}


----------------------- Clusivity -----------------------

tags["inclusive"] = {
	"clusivity",
	"w:clusivity",
	"incl",
}

tags["exclusive"] = {
	"clusivity",
	"w:clusivity",
	"excl",
}

tags["obviative"] = {
	"clusivity",
	"w:clusivity",
	"obv",
}


----------------------- Inflectional class -----------------------

tags["absolute"] = {
	"grammar",
	WIKT,
	"abs",
}

tags["conjunct"] = {
	"grammar",
	WP,
	"conjt",
}

tags["deuterotonic"] = {
	"grammar",
	"w:dependent and independent verb forms",
	"deut",
}

tags["prototonic"] = {
	"grammar",
	"w:dependent and independent verb forms",
	"prot",
}


----------------------- Attitude -----------------------

tags["endearing"] = {
	"attitude",
	-- FIXME! No good glossary entry for this; the entry for "hypocoristic" refers specifically to proper names.
	"w:hypocoristic",
	"end",
	1130279, -- entry for "hypocorism"
}

tags["moderative"] = {
	"attitude",
	WIKT,
	"moder",
}


----------------------- Sound changes -----------------------

tags["alliterative"] = {
	"sound change",
	"w:alliteration",
	nil,
	484495,
}

tags["back"] = {
	"sound change",
	"w:back vowel",
	nil,
	853589,
}

tags["front"] = {
	"sound change",
	"w:front vowel",
	nil,
	5505949,
}

tags["rounded"] = {
	"sound change",
	"w:roundedness",
	"round",
}

tags["sigmatic"] = {
	"sound change",
	WIKT,
	"sigm",
}

tags["unrounded"] = {
	"sound change",
	"w:roundedness",
	"unround",
}

tags["vowel harmonic"] = {
	"sound change",
	"w:vowel harmony",
	"vharm",
	147137,
}


----------------------- Misc grammar -----------------------

tags["relative"] = {
	"grammar",
	WIKT,
	"rel",
}

tags["direct relative"] = {
	"grammar",
	"w:relative_clause#Celtic_languages",
	"dirrel",
}

tags["indirect relative"] = {
	"grammar",
	"w:relative_clause#Celtic_languages",
	"indrel",
}

tags["synthetic"] = {
	"grammar",
	WIKT,
	"synth",
}

tags["analytic"] = {
	"grammar",
	WIKT,
	{"anal", "analytical"},
}

tags["periphrastic"] = {
	"grammar",
	WIKT,
	"peri",
}

tags["affirmative"] = {
	"grammar",
	"w:affirmation and negation",
	"aff",
}

tags["possessed"] = {
	"grammar",
	"w:possessive affix",
	{"possd", "possed"}, -- posd = positive degree
	804020, -- for possessive affix
}

tags["non-possessed"] = {
	"grammar",
	"w:possessive affix",
	{"npossd", "npossed", "nonpossessed"},
}

tags["possessive affix"] = {
	"grammar",
	WP,
	{"posaf", "possaf"},
	804020,
}

tags["possessive suffix"] = {
	"grammar",
	"w:possessive affix",
	"possuf",
	804020,
}

tags["possessive prefix"] = {
	"grammar",
	"w:possessive affix",
	{"pospref", "posspref"},
	804020,
}

tags["prefix"] = {
	"grammar",
	APPENDIX,
	"pref", -- pre = prepositional
	134830,
}

tags["prefixal"] = {
	"grammar",
	WIKT,
	"prefl", -- pre = prepositional
	134830,
}

tags["suffix"] = {
	"grammar",
	APPENDIX,
	{"suf", "suff"},
	102047,
}

tags["suffixal"] = {
	"grammar",
	WIKT,
	{"sufl", "suffl"},
	102047,
}

tags["affix"] = {
	"grammar",
	WP,
	"af", -- aff = affirmative
	62155,
}

tags["affixal"] = {
	"grammar",
	WIKT,
	"afl", -- aff = affirmative
	62155,
}

tags["circumfix"] = {
	"grammar",
	WP,
	{"circ", "cirf", "circf"},
	124939,
}

tags["circumfixal"] = {
	"grammar",
	WIKT,
	{"circl", "cirfl", "circfl"},
	124939,
}

tags["infix"] = {
	"grammar",
	WP,
	"infx",
	201322,
}

tags["infixal"] = {
	"grammar",
	WIKT,
	"infxl",
	201322,
}

tags["subject"] = {
	"grammar",
	APPENDIX,
	"sbj", -- sub and subj used for subjunctive
}

tags["object"] = {
	"grammar",
	APPENDIX,
	"obj",
}

tags["nonfinite"] = {
	"grammar",
	APPENDIX,
	"nonfin",
	1050494, -- entry for "non-finite verb"
}

tags["tense"] = {
	"grammar",
	APPENDIX,
	nil,
	177691,
}

tags["tenseless"] = {
	"grammar",
	WIKT,
}

tags["aspect"] = {
	"grammar",
	APPENDIX,
	"asp",
	208084,
}

tags["augmented"] = {
	"grammar",
	"augment",
	nil,
	760437,
}

tags["unaugmented"] = {
	"grammar",
	"augment",
	nil,
	760437,
}


----------------------- Other tags -----------------------

tags["–"] = { -- Unicode en-dash
	"other",
	no_space_on_left = true,
	no_space_on_right = true,
}

tags["—"] = { -- Unicode em-dash
	"other",
	no_space_on_left = true,
	no_space_on_right = true,
}


----------------------- Create the shortcuts list -----------------------

m_form_of.finalize_tag_data(tags, shortcuts)

return {tags = tags, shortcuts = shortcuts}