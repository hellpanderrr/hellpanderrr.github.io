--[=[
This module lists the more common recognized inflection tags, along with their shortcut aliases, the corresponding
 glossary entry or page describing the tag, and the corresponding wikidata entry. The less common tags are in
[[Module:form of/data2]]. We divide the tags this way to save memory space. Be careful adding more tags to this module;
add them to the other module unless you're sure they are common.

TAGS is a table where keys are the canonical form of an inflection tag and the corresponding values are tables
describing the tags, consisting of the following keys:

	- 1: Type of the tag ("person", "number", "gender", "case", "animacy", "tense-aspect", "mood", "voice-valence",
		 etc.).
	- 2: Anchor or page describing the inflection tag, with the following values:
		 * nil: No link.
		 * APPENDIX: Anchor in [[Appendix:Glossary]] whose name is the same as the tag
		 * WIKT: Page in the English Wiktionary whose name is the same as the tag.
		 * WP: Page in the English Wikipedia whose name is the same as the tag.
		 * A string: If prefixed by 'w:' the specified page in the English Wikipedia. If prefixed by 'wikt:', the
		   specified page in the English Wiktionary. Otherwise, an anchor in [[Appendix:Glossary]].
		 NOTE: GLOSSARY ANCHORS ARE PREFERRED. Other types of entries should be migrated to the glossary, with links to
		 Wikipedia and/or Wiktionary entries as appropriate.
	- 3: List of shortcuts (i.e. aliases for the inflection tag) or a single shortcut string, or nil.
	- 4: Numeric value of Wikidata identifier (see wikidata.org) for the concept most closely describing this tag.
		 (The actual Wikidata identifier is a string formed by prefixing the number with Q.)
	- display: If specified, consists of text to display in the definition line, in lieu of the canonical form of the
			   inflection tag. If there is a glossary entry, the displayed text forms the right side of the two-part
			   glossary link.
	- no_space_on_left: If specified, don't display a space to the left of the tag. Used for punctuation.
	- no_space_on_right: If specified, don't display a space to the right of the tag. Used for punctuation.

SHORTCUTS is a table mapping shortcut aliases to canonical inflection tag names. Shortcuts are of one of three types:
(1) A simple alias of a tag. These do not need to be entered explicitly into the table; code at the end of the module
	automatically fills in these entries based on the information in TAGS.
(2) An alias to a multipart tag. For example, the alias "mf" maps to the multipart tag "m//f", which will in turn be
	expanded into the canonical multipart tag {"masculine", "feminine"}, which will display as (approximately)
	"[[Appendix:Glossary#gender|masculine]] and [[Appendix:Glossary#gender|feminine]]". The number of such aliases
	should be liminted, and should cover only the most common combinations.

	Normally, multipart tags are displayed using serialCommaJoin() in [[Module:table]] to appropriately join the display
	form of the individual tags using commas and/or "and". However, some multipart tags are displayed specially; see
	DISPLAY_HANDLERS below. Note that aliases to multipart tags can themselves contain simple aliases in them.
(3) An alias to a list of multiple tags (which may themselves be simple or multipart aliases). Specifying the alias is
	exactly equivalent to specifying the tags in the list in order, one after another. An example is "1s", which maps to
	the list {"1", "s"}. The number of such aliases should be limited, and should cover only the most common
	combinations.

NOTE: In some cases below, multiple tags point to the same wikidata, because Wikipedia considers them synonyms. Examples
are indirect case vs. objective case vs. oblique case, and inferential mood vs. renarrative mood. We do this because
(a) we want to allow users to choose their own terminology; (b) we want to be able to use the terminology most common
for the language in question; (c) terms considered synonyms may or may not actually be synonyms, as different languages
may use the terms differently. For example, although the Wikipedia page on [[w:inferential mood]] claims that
inferential and renarrative moods are the same, the page on [[w:Bulgarian_verbs#Evidentials]] claims that Bulgarian has
both, and that they are not the same.
]=]

local m_form_of = require("form of")

local APPENDIX = m_form_of.APPENDIX
local WP = m_form_of.WP
local WIKT = m_form_of.WIKT

local tags = {}
local shortcuts = {}


----------------------- Person -----------------------

tags["first-person"] = {
	"person",
	"first person",
	"1",
	21714344,
}

tags["second-person"] = {
	"person",
	"second person",
	"2",
	51929049,
}

tags["third-person"] = {
	"person",
	"third person",
	"3",
	51929074,
}

tags["impersonal"] = {
	"person",
	APPENDIX,
	"impers",
}

shortcuts["12"] = "1//2"
shortcuts["13"] = "1//3"
shortcuts["23"] = "2//3"
shortcuts["123"] = "1//2//3"


----------------------- Number -----------------------

tags["singular"] = {
	"number",
	"singular number",
	{"s", "sg"},
	110786,
}

tags["dual"] = {
	"number",
	"dual number",
	{"d", "du"},
	110022,
}

tags["plural"] = {
	"number",
	"plural number",
	{"p", "pl"},
	146786,
}

tags["single-possession"] = {
	"number",
	"singular number",
	"spos",
	110786, -- Singular
}

tags["multiple-possession"] = {
	"number",
	"plural number",
	"mpos",
	146786, -- Plural
}

shortcuts["1s"] = {"1", "s"}
shortcuts["2s"] = {"2", "s"}
shortcuts["3s"] = {"3", "s"}
shortcuts["1d"] = {"1", "d"}
shortcuts["2d"] = {"2", "d"}
shortcuts["3d"] = {"3", "d"}
shortcuts["1p"] = {"1", "p"}
shortcuts["2p"] = {"2", "p"}
shortcuts["3p"] = {"3", "p"}


----------------------- Gender -----------------------

tags["masculine"] = {
	"gender",
	"gender",
	"m",
	499327,
}

-- This is useful e.g. in Swedish.
tags["natural masculine"] = {
	"gender",
	"gender",
	"natm",
}

tags["feminine"] = {
	"gender",
	"gender",
	"f",
	1775415,
}

tags["neuter"] = {
	"gender",
	"gender",
	"n",
	1775461,
}

tags["common"] = {
	"gender",
	"gender",
	"c",
	1305037,
}

tags["nonvirile"] = {
	"gender",
	APPENDIX,
	"nv",
}

shortcuts["mf"] = "m//f"
shortcuts["mn"] = "m//n"
shortcuts["fn"] = "f//n"
shortcuts["mfn"] = "m//f//n"


----------------------- Animacy -----------------------

-- (may be useful sometimes for [[Module:object usage]].)

tags["animate"] = {
	"animacy",
	APPENDIX,
	"an",
	51927507,
}

tags["inanimate"] = {
	"animacy",
	APPENDIX,
	{"in", "inan"},
	51927539,
}

tags["personal"] = {
	"animacy",
	nil,
	{"pr", "pers"},
	63302102,
}


----------------------- Tense/aspect -----------------------

tags["present"] = {
	"tense-aspect",
	"present tense",
	"pres",
	192613,
}

tags["past"] = {
	"tense-aspect",
	"past tense",
	nil,
	1994301,
}

tags["future"] = {
	"tense-aspect",
	"future tense",
	{"fut", "futr"},
	501405,
}

tags["future perfect"] = {
	"tense-aspect",
	APPENDIX,
	{"futp", "fperf"},
	1234617,
}

tags["non-past"] = {
	"tense-aspect",
	"non-past tense",
	"npast",
	16916993,
}

tags["progressive"] = {
	"tense-aspect",
	APPENDIX,
	"prog",
	56653945,
}

tags["preterite"] = {
	"tense-aspect",
	APPENDIX,
	"pret",
	442485,
}

tags["perfect"] = {
	"tense-aspect",
	APPENDIX,
	"perf",
	625420,
}

tags["imperfect"] = {
	"tense-aspect",
	APPENDIX,
	{"impf", "imperf"},
}

tags["pluperfect"] = {
	"tense-aspect",
	APPENDIX,
	{"plup", "pluperf"},
	623742,
}

tags["aorist"] = {
	"tense-aspect",
	"aorist tense",
	{"aor", "aori"},
	216497,
}

tags["past historic"] = {
	"tense-aspect",
	nil,
	"phis",
	442485,  -- Preterite
}

tags["imperfective"] = {
	"tense-aspect",
	APPENDIX,
	{"impfv", "imperfv"},
	371427,
}

tags["perfective"] = {
	"tense-aspect",
	APPENDIX,
	{"pfv", "perfv"},
	1424306,
}

shortcuts["spast"] = {"simple", "past"}
shortcuts["simple past"] = {"simple", "past"}
shortcuts["spres"] = {"simple", "present"}
shortcuts["simple present"] = {"simple", "present"}


----------------------- Mood -----------------------

tags["imperative"] = {
	"mood",
	"imperative mood",
	{"imp", "impr", "impv"},
	22716,
}

tags["indicative"] = {
	"mood",
	"indicative mood",
	{"ind", "indc", "indic"},
	682111,
}

tags["subjunctive"] = {
	"mood",
	"subjunctive mood",
	{"sub", "subj"},
	473746,
}

tags["conditional"] = {
	"mood",
	"conditional mood",
	"cond",
	625581,
}

tags["modal"] = {
	"mood",
	"w:modality (linguistics)",
	"mod",
	1243600,
}

tags["optative"] = {
	"mood",
	"optative mood",
	{"opta", "opt"},
	527205,
}

tags["jussive"] = {
	"mood",
	"jussive mood",
	"juss",
	462367,
}

tags["hortative"] = {
	"mood",
	WP,
	"hort",
	5906629,
}


----------------------- Voice/valence -----------------------

-- This tag type combines what is normally called "voice" (active, passive, middle, mediopassive) with other tags that
-- aren't normally called voice but are similar in that they control the valence/valency (number and structure of the
-- arguments of a verb).
tags["active"] = {
	"voice-valence",
	"active voice",
	{"act", "actv"},
	1317831,
}

tags["middle"] = {
	"voice-valence",
	"middle voice",
	{"mid", "midl"},
}

tags["passive"] = {
	"voice-valence",
	"passive voice",
	{"pass", "pasv"},
	1194697,
}

tags["mediopassive"] = {
	"voice-valence",
	APPENDIX,
	{"mp", "mpass", "mpasv", "mpsv"},
	1601545,
}

tags["reflexive"] = {
	"voice-valence",
	APPENDIX,
	"refl",
	13475484, -- for "reflexive verb"
}

tags["transitive"] = {
	"voice-valence",
	"transitive verb",
	{"tr", "vt"},
	1774805, -- for "transitive verb"
}

tags["intransitive"] = {
	"voice-valence",
	"intransitive verb",
	{"intr", "vi"},
	Q1166153, -- for "intransitive verb"
}

tags["ditransitive"] = {
	"voice-valence",
	"ditransitive verb",
	"ditr",
	Q2328313, -- for "ditransitive verb"
}

tags["causative"] = {
	"voice-valence",
	APPENDIX,
	"caus",
	56677011, -- for "causative verb"
}


----------------------- Non-finite -----------------------

tags["infinitive"] = {
	"non-finite",
	APPENDIX,
	"inf",
	179230,
}

-- A form found in Portuguese and Galician, as well as in Hungarian. This is probably unnecessary and can be replaced
-- with the regular "infinitive" tag. A personal infinitive is not a separate infinitive from the plain infinitive, just
-- an inflection of the infinitive.
tags["personal infinitive"] = {
	"non-finite",
	"w:Portuguese verb conjugation",
	"pinf",
}

tags["participle"] = {
	"non-finite",
	APPENDIX,
	{"part", "ptcp"},
	814722,
}

tags["verbal noun"] = {
	"non-finite",
	APPENDIX,
	"vnoun",
	1350145,
}

tags["gerund"] = {
	"non-finite",
	APPENDIX,
	"ger",
	1923028,
}

tags["supine"] = {
	"non-finite",
	APPENDIX,
	"sup",
	548470,
}

tags["transgressive"] = {
	"non-finite",
	APPENDIX,
	nil,
	904896,
}


----------------------- Case -----------------------

tags["ablative"] = {
	"case",
	"ablative case",
	"abl",
	156986,
}

tags["accusative"] = {
	"case",
	"accusative case",
	"acc",
	146078,
}

tags["dative"] = {
	"case",
	"dative case",
	"dat",
	145599,
}

tags["genitive"] = {
	"case",
	"genitive case",
	"gen",
	146233,
}

tags["instrumental"] = {
	"case",
	"instrumental case",
	"ins",
	192997,
}

tags["locative"] = {
	"case",
	"locative case",
	"loc",
	202142,
}

tags["nominative"] = {
	"case",
	"nominative case",
	"nom",
	131105,
}

tags["prepositional"] = {
	"case",
	"prepositional case",
	{"pre", "prep"},
	2114906,
}

tags["vocative"] = {
	"case",
	"vocative case",
	"voc",
	185077,
}


----------------------- State -----------------------

tags["construct"] = {
	"state",
	"construct state",
	{"cons", "construct state"},
	1641446,
	display = "construct state",
}

tags["definite"] = {
	"state",
	APPENDIX,
	{"def", "defn", "definite state"},
	53997851,
}

tags["indefinite"] = {
	"state",
	APPENDIX,
	{"indef", "indf", "indefinite state"},
	53997857,
}

tags["possessive"] = {
	"state",
	WP,
	"poss",
	2105891,
}

tags["strong"] = {
	"state",
	"indefinite",
	"str",
	53997857, -- Indefinite
}

tags["weak"] = {
	"state",
	"definite",
	"wk",
	53997851, -- Definite
}

tags["mixed"] = {
	"state",
	APPENDIX,
	"mix",
	63302161,
}

tags["attributive"] = {
	"state",
	APPENDIX,
	"attr",
}

tags["predicative"] = {
	"state",
	APPENDIX,
	"pred",
}


----------------------- Degrees of comparison -----------------------

tags["positive degree"] = {
	"comparison",
	"positive",
	{"posd", "positive"},
	3482678, -- Doesn't exist in English; only in Czech, Estonian, Finnish and various Nordic languages.
}

tags["comparative degree"] = {
	"comparison",
	"comparative",
	{"comd", "comparative"},
	14169499,
}

tags["superlative degree"] = {
	"comparison",
	"superlative",
	{"supd", "superlative"},
	1817208,
}


----------------------- Register -----------------------

----------------------- Deixis -----------------------

----------------------- Clusivity -----------------------

----------------------- Inflectional class -----------------------

tags["pronominal"] = {
	"class",
	WIKT,
	"pron",
	12721180, -- for "pronominal attribute", existing only in the Romanian Wikipedia
}


----------------------- Attitude -----------------------

-- This is a vague tag type grouping augmentative, diminutive and pejorative, which generally indicate the speaker's
-- attitude towards the object in question (as well as often indicating size).

tags["augmentative"] = {
	"attitude",
	APPENDIX,
	"aug",
	1358239,
}

tags["diminutive"] = {
	"attitude",
	APPENDIX,
	"dim",
	108709,
}

tags["pejorative"] = {
	"attitude",
	APPENDIX,
	"pej",
	545779,
}


----------------------- Sound changes -----------------------

tags["contracted"] = {
	"sound change",
	nil,
	"contr",
	126473,
}

tags["uncontracted"] = {
	"sound change",
	nil,
	"uncontr",
}

----------------------- Misc grammar -----------------------

tags["simple"] = {
	"grammar",
	nil,
	"sim",
}

tags["short"] = {
	"grammar",
}

tags["long"] = {
	"grammar",
}

tags["form"] = {
	"grammar",
}

tags["adjectival"] = {
	"grammar",
	WIKT,
	"adj",
}

tags["adverbial"] = {
	"grammar",
	APPENDIX,
	"adv",
}

tags["negative"] = {
	"grammar",
	"w:affirmation and negation",
	"neg",
	63302088,
}

tags["nominalized"] = {
	"grammar",
	nil,
	"nomz",
	4683152, -- entry for "nominalized adjective"
}

tags["nominalization"] = {
	"grammar",
	nil,
	"nomzn",
	1500667,
}

tags["root"] = {
	"grammar",
	nil,
	nil,
	111029,
}

tags["stem"] = {
	"grammar",
	nil,
	nil,
	210523,
}

tags["dependent"] = {
	"grammar",
	nil,
	"dep",
	1122094, -- entry for "dependent clause"
}

tags["independent"] = {
	"grammar",
	nil,
	"indep",
	1419215, -- entry for "independent clause"
}


----------------------- Other tags -----------------------

-- This consists of non-content words like "and" as well as punctuation characters. If the punctuation characters appear
-- by themselves as tags, we special-case the handling of surrounding spaces so the output looks correct.

tags["and"] = {
	"other",
}

tags[","] = {
	"other",
	no_space_on_left = true,
}

tags[":"] = {
	"other",
	no_space_on_left = true,
}

tags["/"] = {
	"other",
	no_space_on_left = true,
	no_space_on_right = true,
}

tags["("] = {
	"other",
	no_space_on_right = true,
}

tags[")"] = {
	"other",
	no_space_on_left = true,
}

tags["["] = {
	"other",
	no_space_on_right = true,
}

tags["]"] = {
	"other",
	no_space_on_left = true,
}

tags["-"] = { -- regular hyphen-minus
	"other",
	no_space_on_left = true,
	no_space_on_right = true,
}


----------------------- Create the shortcuts list -----------------------

m_form_of.finalize_tag_data(tags, shortcuts)

return {tags = tags, shortcuts = shortcuts}