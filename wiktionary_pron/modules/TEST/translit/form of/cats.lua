local cats = {}

--[=[

This contains categorization specs for specific languages and for all languages.
The particular categories listed are listed without the preceding canonical
language name, which will automatically be prepended, and the text "<<p>>"
in a category will be replaced with the user-specified part of speech.

The value of an entry in the cats[] table is a list of specifications to apply
to inflections in a specific language (except that the entry for "und" applies
to all languages). Each specification indicates the conditions under which a
given category is applied. Each specification is processed independently; if
multiple specifications apply, all the resulting categories will be added to
the page. (This is equivalent to wrapping the specifications in a
{"multi", ...} clause; see below.)

A specification is one of:

(1) A string:

	Always apply that category.

(2) A list {"has", TAG, SPEC} or {"has", TAG, SPEC, ELSESPEC}:

	TAG is an inflection tag, and can either be the full form or any
	abbreviation; if that tag is present among the user-supplied tags, SPEC is
	applied, otherwise ELSESPEC is applied if present. SPEC and ELSESPEC are
	specifications just as at the top level; i.e. they can be strings, nested
	conditions, etc.

(2) A list {"hasall", TAGS, SPEC} or {"hasall", TAGS, SPEC, ELSESPEC}:

	Similar to {"has", ...} but only activates if all of the tags in TAGS
	(a list) are present among the user-supplied tags (in any order, and
	other tags may be present, including between the tags in TAGS).

(3) A list {"hasany", TAGS, SPEC} or {"hasany", TAGS, SPEC, ELSESPEC}:

	Similar to {"has", ...} but activates if any of the tags in TAGS
	(a list) are present among the user-supplied tags.

(4) A list {"tags=", TAGS, SPEC} or {"tags=", TAGS, SPEC, ELSESPEC}:

	Similar to {"hasall", ...} but activates only if the
	user-supplied tags exactly match the tags in TAGS, including
	the order. (But, as above, any tag abbreviation can be given
	in TAGS, and will match any equivalent abbreviation or full
	form.)

(5) A list {"p=", VALUE, SPEC} or {"p=", VALUE, SPEC, ELSESPEC}:

	Similar to {"has", ...} but activates if the value supplied for the p=
	or POS= parameters is the specified value (which can be either the full
	form or any abbreviation).

(6) A list {"pany", VALUES, SPEC} or {"pany", VALUES, SPEC, ELSESPEC}:

	Similar to {"p=", ...} but activates if the value supplied for the p=
	or POS= parameters is any of the specified values (which can be either
	the full forms or any abbreviation).

(7) A list {"pexists", SPEC} or {"pexists", SPEC, ELSESPEC}:

	Activates if any value was specified for the p= or POS= parameters.

(8) A list {"cond", SPEC1, SPEC2, ...}:

	If SPEC1 applies, it will be applied; otherwise, if SPEC2 applies, it
	will be applied; etc. This stops processing specifications as soon as it
	finds one that applies.

(9) A list {"multi", SPEC1, SPEC2, ...}:

	If SPEC1 applies, it will be applied; in addition, if SPEC2 applies, it
	will also be applied; etc. Unlike {"cond", ...}, this continues
	processing specifications even if a previous one has applied.

(10) A list {"not", CONDITION, SPEC} or {"not", CONDITION, SPEC, ELSESPEC}:

	 If CONDITION does *NOT* apply, SPEC will be applied, otherwise ELSESPEC
	 will be applied if present. CONDITION is one of:

	 -- {"has", TAG}
	 -- {"hasall", TAGS}
	 -- {"hasany", TAGS}
	 -- {"tags=", TAGS},
	 -- {"p=", VALUE}
	 -- {"pany", VALUES}
	 -- {"pexists"}
	 -- {"not", CONDITION}
	 -- {"and", CONDITION1, CONDITION2}
	 -- {"or", CONDITION1, CONDITION2}
	 -- {"call", FUNCTION} where FUNCTION is a string naming a function listed
	    in cat_functions in [[Module:form of/functions]], which is passed a
	    single argument (see (10) below) and should return true or false.

	 That is, conditions are similar to if-else SPECS but without any
	 specifications given.

(11) A list {"and", CONDITION1, CONDITION2, SPEC} or {"and", CONDITION1, CONDITION2, SPEC, ELSESPEC}:

	 If CONDITION1 and CONDITION2 both apply, SPEC will be applied, otherwise
	 ELSESPEC will be applied if present. CONDITION is as above for "not".

(12) A list {"or", CONDITION1, CONDITION2, SPEC} or {"or", CONDITION1, CONDITION2, SPEC, ELSESPEC}:

	 If either CONDITION1 or CONDITION2 apply, SPEC will be applied, otherwise
	 ELSESPEC will be applied if present. CONDITION is as above for "not".

(13) A list {"call", FUNCTION}:

	 FUNCTION is the name of a function listed in cat_functions in
	 [[Module:form of/functions]], which is passed a single argument, a table
	 containing the parameters given to the template call, and which should
	 return a specification (a string naming a category, a list of any of the
	 formats described above). In the table, the following keys are present:

	 "lang": the structure describing the language (usually the first
	         parameter);
	 "tags": the list of tags (canonicalized to their full forms);
	 "term": the term to link to (will be missing if no term is given);
	 "alt": the display form of the term (will be missing if no display form
	        is given);
	 "t": the gloss of the term (will be missing if no gloss is given);

	 In addition, any other parameters specified will be located under a key
	 corresponding to the parameter name.


As a simple example, consider this:

cats["et"] = {
	{"has", "part", "participles"},
}

This says that, for language code "et" (Estonian), if the "part" tag is
present (or if "participle" is present, which is the equivalent full form),
the page will be categorized into [[:Category:Estonian participles]].

Another example:

cats["lt"] = {
	{"p=", "part",
		{"has", "pron",
			"pronominal dalyvis participle forms",
			"dalyvis participle forms",
		}
	}
}

This says that, for language code "lt" (Lithuanian), if the "p=" parameter
was given with the value "part" (or "participle", the equivalent full form),
then if the "pron" tag is present (or the equivalent full form "pronominal"),
categorize into [[:Category:Lithuanian pronominal dalyvis participle forms]],
else categorize into [["Category:Lithuanian dalyvis participle forms]]. Note
that, if p= isn't specified, or has a value other than "part" or
"participle", no categories will be added to the page, because there is no
"else" specification associated with the "p=" specification.

--]=]

-- First, the language-independent categories; be careful here not to
-- overcategorize. In practice we achieve this using tags=; we should
-- probably be smarter. But we don't e.g. want to categorize a page
-- into "present participles" if it has the tags f|s|pres|part, which
-- is a participle form rather than a participle itself.
--
-- We include the categorization here rather than in e.g. {{augmentative of}}
-- because we want the categorization to also apply when e.g. an augmentative
-- is specified using {{inflection of|LANG|...|aug}} rather than
-- {{augmentative of|LANG}}.
cats["und"] = {
	-- Disable all of these for now as they are somewhat controversial.
	--{"tags=", {"aug"}, "augmentative <<p=n>>s"},
	--{"tags=", {"dim"}, "diminutive <<p=n>>s"},
	--{"or", {"tags=", {"end"}},
	--	{"or", {"tags=", {"end", "form"}}, {"tags=", {"end", "dim"}}},
	--	"endearing <<p=n>>s"},
	--{"tags=", {"pej"}, "derogatory terms"},
	--{"tags=", {"comd"}, "comparative <<p=a>>s"},
	--{"tags=", {"supd"}, "superlative <<p=a>>s"},
	--{"tags=", {"equd"}, "<<p=a>> equative forms"},
	--{"tags=", {"caus"}, "causative <<p=v>>s"},
	--{"tags=", {"freq"}, "frequentative <<p=v>>s"},
	--{"tags=", {"iter"}, "iterative <<p=v>>s"},
	--{"tags=", {"refl"}, "reflexive <<p=v>>s"},
	--{"or", {"tags=", {"impfv"}}, {"tags=", {"impfv", "form"}}, "imperfective <<p=v>>s"},
	--{"or", {"tags=", {"pfv"}}, {"tags=", {"pfv", "form"}}, "perfective <<p=v>>s"},
	--{"tags=", {"nomzn"}, "nominalized adjectives"},
	--{"tags=", {"ger"}, "gerunds"},
	--{"tags=", {"vnoun"}, "verbal nouns"},
	--{"tags=", {"pass"}, "<<p=v>> passive forms"},
	-- [[User:Rua]] objects to these categories
	-- {"tags=", {"past", "act", "part"}, "past active participles"},
	-- {"tags=", {"past", "pass", "part"}, "past passive participles"},
	-- {"tags=", {"past", "part"}, "past participles"},
	-- {"tags=", {"pres", "act", "part"}, "present active participles"},
	-- {"tags=", {"pres", "pass", "part"}, "present passive participles"},
	-- {"tags=", {"pres", "part"}, "present participles"},
	-- {"tags=", {"perf", "part"}, "perfect participles"},
}

cats["az"] = {
	{"hasall", {"subject", "past", "participle"}, "subject past participles"},
	{"hasall", {"broken", "plural"}, "broken noun plural forms"},
}

cats["bg"] = {
	{"cond",
		{"hasall", {"adv", "part"}, "adverbial participles"},
		{"has", "part",
			-- If this is a lemma participle form, categorize appropriately
			-- for the type of participle, otherwise put into
			-- "participle forms". We determine a lemma if all of the
			-- following apply:
			-- (1) either is masculine, or no gender listed; and
			-- (2) either is indefinite, or no definiteness listed; and
			-- (3) not listed as either subjective or objective form.
			{"and",
				{"or", {"has", "m"}, {"not", {"hasany", {"f", "n", "p"}}}},
				{"and",
					{"or", {"has", "indef"}, {"not", {"has", "def"}}},
					{"not", {"hasany", {"sbjv", "objv"}}},
				},
				{"cond",
					{"hasall", {"pres", "act"}, "present active participles"},
					{"hasall", {"past", "pass"}, "past passive participles"},
					{"hasall", {"past", "act", "aor"}, "past active aorist participles"},
					{"hasall", {"past", "act", "impf"}, "past active imperfect participles"},
				},
				-- FIXME: "participle forms" probably not necessary,
				-- should be handled by headword
				"participle forms"
			}
		}
	},
}

cats["br"] = {
	{"p=", "n",
		{"has", "p", "noun plural forms"}
	},
}

cats["ca"] = {
	{"has", "part",
		{"cond",
			-- FIXME, not clear if we need all of these conditions;
			-- may partly be handled by headword
			{"hasany", {"f", "p"}, "participle forms"},
			{"has", "pres", "present participles"},
			{"has", "past", "past participles"},
		}
	},
}

cats["de"] = {
	{"hasall", {"pres", "part"}, "present participles"},
	{"hasall", {"past", "part"}, "past participles"},
}

cats["el"] = {
	{"has", "dat", "dative forms"},
	{"p=", "v",
		{"cond",
			{"hasall", {"1", "s", "past"}, "verb past tense forms"},
			{"has", "nonfinite", "verb nonfinite forms"},
		},
	},
}

cats["en"] = {
	{"cond",
		-- The display of these labels and their categorization is controlled by [[Module:labels/data/lang/en]].
		-- This label will categorize into [[:Category:English archaic third-person singular forms]].
		{"has", "3-th", {labels = {"archaic third singular"}}},
		-- This label will categorize into [[:Category:English second-person singular forms]].
		{"hasall", {"2-st", "pres"}, {labels = {"archaic second singular present"}}},
		-- This label will categorize into [[:Category:English second-person singular past tense forms]].
		{"hasall", {"2-st", "past"}, {labels = {"archaic second singular past"}}},
	},
	-- Add irregular plural categories. The corresponding code is in [[Module:form of/lang-data/en/functions]].
	{"tags=", {"p"}, {"call", "en-irregular-plural-categories"}},
}

cats["enm"] = {
	{"not", {"hasany", {"sub", "imp"}}, 
		{"multi",
			{"hasall", {"1", "s", "pres"}, "first-person singular forms"},
			{"hasall", {"2", "s", "pres"}, "second-person singular forms"},
			{"hasall", {"3", "s", "pres"}, "third-person singular forms"},
			{"hasall", {"1//3", "s", "past"}, "first/third-person singular past forms"},
			{"hasall", {"2", "s", "past"}, "second-person singular past forms"},
			{"hasall", {"p", "pres"}, "plural forms"},
		},
	},
	{"hasall", {"p", "pres", "ind"}, "plural forms"},
	{"hasall", {"p", "pres", "sub"}, "plural subjunctive forms"},
	{"hasall", {"p", "past"}, "plural past forms"},
	{"hasall", {"s", "pres", "sub"}, "singular subjunctive forms"},
	{"hasall", {"s", "past", "sub"}, "singular past subjunctive forms"},
	{"hasall", {"s", "imp"}, "singular imperative forms"},
	{"hasall", {"p", "imp"}, "plural imperative forms"},
	{"hasall", {"pres", "part"}, "present participles"},
	{"hasall", {"past", "part"}, "past participles"},
}

cats["et"] = {
	{"has", "part", "participles"},
}

cats["fi"] = {
	{"has", "inf",
		{"cond",
			{"hasall", {"long", "first"}, "long first infinitives"},
			{"hasall", {"second", "act"}, "active second infinitives"},
			{"hasall", {"second", "pass"}, "passive second infinitives"},
			{"hasall", {"third", "act"}, "active third infinitives"},
			{"hasall", {"third", "pass"}, "passive third infinitives"},
			{"has", "fifth", "fifth infinitives"},
		}
	},
}

cats["got"] = {
	{"hasall", {"pres", "part"}, "present participles"},
	{"hasall", {"past", "part"}, "past participles"},
}

cats["hu"] = {
	{"hasall", {"past", "part"}, "past participles"},
	{"hasall", {"pres", "part"}, "present participles"},
	{"hasall", {"fut", "part"}, "future participles"},
	{"hasall", {"adv", "part"}, "adverbial participles"},
	{"hasall", {"verbal", "part"}, "verbal participles"},
}

cats["ja"] = {
	{"p=", "v",
		{"multi",
			{"has", "past", "past tense verb forms"},
			{"has", "conj", "conjunctive verb forms"},
		}
	},
}

cats["kmr"] = {
	{"hasall", {"pres", "part"}, "present participles"},
	{"hasall", {"past", "part"}, "past participles"},
}

cats["liv"] = {
	{"has", "part",
		{"cond",
			{"hasall", {"pres", "act"}, "present active participles"},
			{"hasall", {"pres", "pass"}, "present passive participles"},
			{"hasall", {"past", "act"}, "past active participles"},
			{"hasall", {"past", "pass"}, "past passive participles"},
		},
	},
	{"cond",
		{"has", "ger", "gerunds"},
		{"hasall", {"sup", "abe"}, "supine abessives"},
		{"has", "sup", "supines"},
		{"has", "deb", "debitives"},
	},
}

cats["lt"] = {
	{"has", "part",
		{"cond",
			-- Three types of adverbial participles.
			{"has", "budinys", "būdinys participles"},
			{"has", "padalyvis", "padalyvis participles"},
			{"has", "pusdalyvis", "pusdalyvis participles"},
			-- If it's a non-adverbial participle, it's a dalyvis = regular
			-- adjectival participle. It's a participle per se if it has
			-- no case, number or gender listed.
			{"not", {"hasany", {
				"nom", "gen", "dat", "acc", "ins", "loc", "voc",
				"m", "f", "s", "p"
			}}, "dalyvis participles"},
		}
	},
	{"p=", "a",
		{"has", "pron",
			{"cond",
				{"has", "comd", "comparative pronominal adjective forms"},
				{"has", "supd", "superlative pronominal adjective forms"},
			},
			{"cond",
				{"has", "comd", "comparative adjective forms"},
				{"has", "supd", "superlative adjective forms"},
			},
		}
	},
}

cats["lv"] = {
	{"tags=", {"adv", "form"}, "adverbial forms of <<p=a>>s"},
	{"has", "neg", "negative verb forms"},
	{"has", "comd",
		{"has", "def",
			"definite comparative adjectives",
			"comparative adjectives",
		},
	},
	{"has", "supd",	"superlative adjectives"},
   	{"has", "part",
   		{"cond",
   			{"hasall", {"pres", "act"}, "present active participles"},
   			{"hasall", {"pres", "pass"}, "present passive participles"},
   			{"hasall", {"past", "act"}, "past active participles"},
   			{"hasall", {"past", "pass"}, "past passive participles"},
   		},
   	},
}

cats["mk"] = {
	{"has", "vnoun", 
		{"multi", "verbal nouns", "verb forms"},
	},
	{"has", "part",
		{"multi",
			"participles",
			"verb forms",
			{"cond",
				{"hasall", {"adj", "part"}, "adjectival participles"},
				{"hasall", {"adv", "part"}, "adverbial participles"},
				{"hasall", {"perf", "part"}, "perfect participles"},
				{"hasall", {"aor", "act", "part"}, "aorist l-participles"},
				{"hasall", {"impf", "act", "part"}, "imperfect l-participles"},
			},
		}
	},
	{"has", "lptcp",
		{"multi",
			{"has", "aor", "aorist l-participles"},
			{"has", "impf", "imperfect l-participles"},
			{"hasall", {"m", "s"}, "participles", "participle forms"},
		},
	},
	{"hasall", {"col", "pl"}, "collective plurals"},
}

cats["nl"] = {
	{"tags=", {"pl", "imp"}, {labels = {"plural imperative"}}},
	{"has", "sub", {labels = {"subjunctive"}}},
	-- Depending on the part of speech, a specific case-form category is added, or if no 
    -- recognized part of speech is present, the generic case-form category is used. The 
    -- label "archaic" will also be added, for which see [[Module:labels/data/lang/nl]].
	{"hasany", {"acc", "dat", "gen"}, 
		{"multi",
			{labels = {"archaic case form"}},
			{"cond", 
				{"p=", "n", "noun case forms"},
				{"p=", "a", "adjective case forms"},
				-- Only goes to "case forms" umbrella cat if no (/no recognized) POS given
				"case forms"
			}
		}
	}
}

cats["pl"] = {
	{"has", "short", "short adjective forms"},
}

cats["sa"] = {
	{"has", "desid",
		{"multi",
			"desiderative verbs",
			"verbs derived from primitive verbs"
		},
	},
	{"has", "freq",
		{"multi",
			"frequentative verbs",
			"verbs derived from primitive verbs"
		},
	},
	{"has", "root", "root forms"},
}

cats["sco"] = {
	{"hasall", {"simple", "past"}, "verb simple past forms"},
	{"hasall", {"3", "s", "pres", "ind"}, "third-person singular forms"},
}

cats["sv"] = {
	{"cond",
		-- The display of these labels is controlled by [[Module:labels/data/lang/sv]].
		{"hasall", {"past", "sub"}, {labels = {"past subjunctive"}}},
		{"hasall", {"pres", "sub"}, {labels = {"present subjunctive"}}},
		-- If it just has 'sub' (subjunctive), not labeled as present or past, treat it like the past subjunctive, whose label
		-- is "weaker" than the present subjunctive (dated vs. archaic).
		{"has", "sub", {labels = {"past subjunctive"}}},
		{"hasall", {"1", "p", "pres"}, {labels = {"1st plural present indicative"}}},
		{"hasall", {"2", "p", "pres"}, {labels = {"2nd plural present indicative"}}},
		{"hasall", {"p", "pres"}, {labels = {"plural present indicative"}}},
		{"hasall", {"1", "p", "past"}, {labels = {"1st plural past indicative"}}},
		{"hasall", {"2", "p", "past"}, {labels = {"2nd plural past indicative"}}},
		{"hasall", {"p", "past"}, {labels = {"plural past indicative"}}},
		{"hasall", {"1", "p", "imp"}, {labels = {"1st plural imperative"}}},
		{"hasall", {"p", "imp"}, {labels = {"2nd plural imperative"}}},
	},
}

cats["uk"] = {
   	{"has", "part",
   		{"multi",
   			"participles",
   			"verb forms",
   			{"cond",
   				{"hasall", {"pres", "act"}, "present active participles"},
   				{"hasall", {"pres", "pass"}, "present passive participles"},
   				{"hasall", {"pres", "adv"}, "present adverbial participles"},
   				{"hasall", {"past", "act"}, "past active participles"},
   				{"hasall", {"past", "pass"}, "past passive participles"},
   				{"hasall", {"past", "adv"}, "past adverbial participles"},
   			},
   		}
   	},
}

return cats