local labels = {}
local handlers = {}

local rfind = mw.ustring.find
local rmatch = mw.ustring.match
local rsubn = mw.ustring.gsub

-- version of rsubn() that discards all but the first return value
local function rsub(term, foo, bar)
	local retval = rsubn(term, foo, bar)
	return retval
end


--------------------------------- Verbs --------------------------------

labels["verbs by class"] = {
	description = "Belarusian verbs categorized by class.",
	parents = {{name = "verbs by inflection type", sort = "class"}},
}

labels["verbs by class and accent pattern"] = {
	description = "Belarusian verbs categorized by class and accent pattern.",
	parents = {{name = "verbs by inflection type", sort = "class and accent pattern"}},
}

table.insert(handlers, function(data)
	local cls, variant, pattern = rmatch(data.label, "^class ([0-9]*)(°?)([abc]?) verbs")
	if cls then
		if pattern == "" then
			return {
				description = "Belarusian class " .. cls .. " verbs.",
				breadcrumb = cls,
				parents = {{name = "verbs by class", sort = cls .. variant}},
			}
		else
			return {
				description = "Belarusian class " .. cls .. " verbs of " ..
					"accent pattern " .. pattern .. (
					variant == "" and "" or " and variant " .. variant) .. ". " .. (
					pattern == "a" and "With this pattern, all forms are stem-stressed."
					or pattern == "b" and "With this pattern, all forms are ending-stressed."
					or "With this pattern, the first singular present indicative and all forms " ..
					"outside of the present indicative are ending-stressed, while the remaining " ..
					"forms of the present indicative are stem-stressed.").. (
					variant == "" and "" or
					cls == "3" and variant == "°" and " The variant code indicates that the -н of the stem " ..
					"is missing in most non-present-tense forms." or
					cls == "6" and variant == "°" and
					" The variant code indicates that the present tense is not " ..
					"[[Appendix:Glossary#iotation|iotated]]. (In most verbs of this class, " ..
					"the present tense is iotated, e.g. піса́ць with present tense " ..
					"пішу́, пі́шеш, пі́ше, etc.)"
				),
				breadcrumb = cls .. variant .. pattern,
				parents = {
					{name = "class " .. cls .. " verbs", sort = pattern},
					{name = "verbs by class and accent pattern", sort = cls .. pattern},
				},
			}
		end
	end
end)


--------------------------------- Adjectives --------------------------------

labels["adjectives by stem type and stress"] = {
	description = "Belarusian adjectives categorized by stem type and stress. " ..
		"Unlike for nouns, adjectives are consistently either stem-stressed or ending-stressed.",
	parents = {{name = "adjectives by inflection type", sort = "stem type and stress"}},
}


local adj_stem_expl = {
	["soft"] = "a soft consonant",
	["hard"] = "a hard consonant other than a velar",
	["velar-stem"] = "a velar consonant",
	["possessive"] = "-ов, -ев, -ын or -ін",
}

local adj_decl_endings = {
	["hard stem-stressed"] = {"-ы", "-ая", "-ае", "-ыя"},
	["hard ending-stressed"] = {"-ы́", "-а́я", "-о́е", "-ы́я"},
	["velar-stem stem-stressed"] = {"-і", "-ая", "-ае", "-ія"},
	["velar-stem ending-stressed"] = {"-і́", "-а́я", "-о́е", "-і́я"},
	["soft"] = {"-і", "-яя", "-яе", "-ія"},
	-- FIXME, not sure the rest are correct
	["possessive"] = {"-", "-а", "-а", "-і"},
	["surname"] = {"-", "-а", "(nil)", "-і"},
}

table.insert(handlers, function(data)
	local breadcrumb, stem, stress = rmatch(data.label, "^(([^ ]*) ([^ *]*)-stressed) adjectives")
	if not breadcrumb then
		breadcrumb, stem = rmatch(data.label, "^(([^ ]*)) adjectives")
		stress = ""
	end
	if breadcrumb and adj_stem_expl[stem] and adj_decl_endings[breadcrumb] then
		local m, f, n, p = unpack(adj_decl_endings[breadcrumb])
		local stresstext = stress == "stem" and
			"The adjectives in this category have stress on the stem." or
			stress == "ending" and
			"The adjectives in this category have stress on the endings." or
			"All adjectives of this type have stress on the stem."
		local endingtext = "ending in the nominative in masculine singular " .. m ..
			", feminine singular " .. f .. ", neuter singular " .. p .. " and plural " ..
			p .. "."
		local stemtext = " The stem ends in " .. adj_stem_expl[stem] .. "."
		return {
			description = "Belarusian " .. stem .. " adjectives, " .. endingtext .. stemtext .. " " .. stresstext,
			breadcrumb = breadcrumb,
			parents = {"adjectives by stem type and stress"},
		}
	end
end)

--------------------------------- Nouns/Pronouns/Numerals --------------------------------

for _, pos in ipairs({"nouns", "pronouns", "numerals"}) do
	local sgpos = pos:gsub("s$", "")
	labels[pos .. " by stem type and gender"] = {
		description = "Belarusian " .. pos .. " categorized by stem type and typical gender. " ..
			"Note that \"typical gender\" means the gender that is typical for the " .. sgpos .. "'s ending (e.g. most " ..
			pos .. " in ''-я'' with accusative in ''-ю'' are feminine, and hence all such " .. pos .. " are considered " ..
			"to be \"typically feminine'\"; but some are in fact masculine). See [[Template:be-ndecl]] for further " ..
			"information on accent patterns.",
		parents = {{name = pos .. " by inflection type", sort = "stem type and gender"}},
	}

	labels[pos .. " by stem type, gender and accent pattern"] = {
		description = "Belarusian " .. pos .. " categorized by stem type, typical gender and accent pattern. " ..
			"Note that \"typical gender\" means the gender that is typical for the " .. sgpos .. "'s ending (e.g. most " ..
			pos .. " in ''-я'' with accusative in ''-ю'' are feminine, and hence all such " .. pos .. " are considered " ..
			"to be \"typically feminine'\"; but some are in fact masculine). See [[Template:be-ndecl]] for further " ..
			"information on accent patterns.",
		parents = {{name = pos .. " by inflection type", sort = "stem type, gender and accent pattern"}},
	}

	labels[pos .. " by vowel alternation"] = {
		description = "Belarusian " .. pos .. " categorized according to their (unpredictable) vowel alternation pattern (e.g. ''а'' vs. ''о'').",
		parents = {{name = pos, sort = "vowel alternation"}},
	}

	labels[pos .. " by accent pattern"] = {
		description = "Belarusian " .. pos .. " categorized according to their accent pattern (see [[Template:be-ndecl]]).",
		parents = {{name = pos .. " by inflection type", sort = "accent pattern"}},
	}

	labels[pos .. " with reducible stem"] = {
		description = "Belarusian " .. pos .. " with a reducible stem, where an extra vowel is inserted " ..
			"before the last stem consonant in the nominative singular and/or genitive plural.",
		parents = {{name = pos .. " by inflection type", sort = "reducible stem"}},
	}

	labels[pos .. " with multiple stems"] = {
		description = "Belarusian " .. pos .. " with multiple stems.",
		parents = {{name = pos .. " by inflection type", sort = "multiple stems"}},
	}

	labels[pos .. " with multiple accent patterns"] = {
		description = "Belarusian " .. pos .. " with multiple accent patterns. See [[Template:be-ndecl]].",
		parents = {{name = pos .. " by inflection type", sort = "multiple accent patterns"}},
	}

	labels["adjectival " .. pos] = {
		description = "Belarusian " .. pos .. " with adjectival endings.",
		parents = {pos},
	}

	labels[pos .. " with irregular stem"] = {
		description = "Belarusian " .. pos .. " with an irregular stem, which occurs in all cases except the nominative singular and maybe the accusative singular.",
		parents = {{name = "irregular " .. pos, sort = "stem"}},
	}

	labels[pos .. " with irregular plural stem"] = {
		description = "Belarusian " .. pos .. " with an irregular plural stem, which occurs in all cases.",
		parents = {{name = "irregular " .. pos, sort = "plural stem"}},
	}
end

local noun_stem_expl = {
	["hard"] = "a hard consonant",
	["velar-stem"] = "a velar (-к, -г or -х)",
	["soft"] = "a soft consonant",
	["n-stem"] = "-м (with -ен- or -ён- in some forms)",
	["t-stem"] = "-я or -а (with -т- or -ц- in most forms)",
	["possessive"] = "-ов, -ав, -ев, -ёв, -ін or -ын",
	["surname"] = "-ов, -ав, -ев, -ёв, -ін or -ын",
}

local noun_stem_to_declension = {
	["hard third-declension"] = "third",
	["soft third-declension"] = "third",
	["fourth-declension"] = "fourth",
	["t-stem"] = "fourth",
	["n-stem"] = "fourth",
}

local noun_stem_gender_endings = {
    masculine = {
		["hard"]              = {"a hard consonant", "-ы"},
		["velar-stem"]        = {"a velar", "-і"},
		["soft"]              = {"-ь", "-і"},
	},
    feminine = {
		["hard"]              = {"-а", "-ы"},
		["velar-stem"]        = {"a velar", "-і"},
		["soft"]              = {"-я", "-і"},
		["hard third-declension"]  = {"-р or a hushing consonant", "-ы"},
		["soft third-declension"]  = {"-ь or -ў", "-і"},
	},
    neuter = {
		["hard"]              = {"-а or -о", "-ы"},
		["velar-stem"]        = {"-а or -о", "-і"},
		["soft"]              = {"-е or -ё", "-і"},
		["fourth-declension"] = {"-я", "-і"},
		["t-stem"]            = {"-я or -а", "-ты"},
		["n-stem"]            = {"-я", "-ёны"},
	},
}

local noun_vowel_alternation_expl = {
	["а-е"] = "unstressed -а- in the lemma and stressed -э- in some remaining forms, or unstressed -я- in the lemma and stressed or unstressed -е- in some remaining forms",
	["а-о"] = "unstressed -а- in the lemma and stressed -о- in some remaining forms, or unstressed -я- in the lemma and stressed -ё- in some remaining forms",
	["а-во"] = "unstressed (usually word-initial) а- in the lemma and stressed во- in some remaining forms",
	["во-а"] = "stressed (usually word-initial) во- in the lemma and unstressed а- in some remaining forms",
	["о-ы"] = "stressed -о- in the lemma and unstressed -ы- in some remaining forms",
	["ы-о"] = "unstressed -ы- in the lemma and stressed -о- in some remaining forms",
}

table.insert(handlers, function(data)
	local function escape_accent(accent)
		return rsub(accent, "'", "&#39;")
	end

	local function get_stem_gender_text(stem, genderspec, pos)
		local gender = genderspec
		gender = rsub(gender, " in %-[ао]$", "")
		if not noun_stem_gender_endings[gender] then
			return nil
		end
		local endings = noun_stem_gender_endings[gender][stem]
		if not endings then
			return nil
		end
		local sgending, plending = endings[1], endings[2]
		local stemtext = noun_stem_expl[stem] and " The stem ends in " .. noun_stem_expl[stem] .. "." or ""
		local decltext =
			rfind(stem, "declension") and "" or
			" This is traditionally considered to belong to the " .. (
				noun_stem_to_declension[stem] or gender == "feminine" and "first" or "second"
			) .. " declension."
		local genderdesc
		if rfind(genderspec, "in %-[ао]$") then
			genderdesc = rsub(genderspec, "in (%-[ао])$", pos .. "s ending in %1")
		else
			genderdesc = "usually " .. gender .. " " .. pos .. "s"
		end
		return stem .. ", " .. genderdesc .. ", normally ending in " .. sgending .. " in the nominative singular " ..
			" and " .. plending .. " in the nominative plural." .. stemtext .. decltext
	end

	local stem, gender, accent, pos = rmatch(data.label, "^(.*) (.-) adjectival accent%-(.-) (.*)s$")
	if not stem then
		stem, gender, pos = rmatch(data.label, "^(.*) (.-) adjectival (.*)s$")
	end
	if stem and noun_stem_expl[stem] then
		local stemspec
		if stem == "hard" then
			stemspec = accent == "a" and "hard stem-stressed" or "hard ending-stressed"
		else
			stemspec = stem
		end
		local endings = adj_decl_endings[stemspec]
		if endings then
			local stemtext = " The stem ends in " .. noun_stem_expl[stem] .. "."
			local accentdesc = accent == "a" and
				"This " .. pos .. " is stressed according to accent pattern a (stress on the stem)." or
				accent == "b" and
				"This " .. pos .. " is stressed according to accent pattern b (stress on the ending)." or
				"All " .. pos .. "s of this class are stressed according to accent pattern a (stress on the stem)."
			local accenttext = accent and " accent-" .. accent or ""
			local m, f, n, pl = unpack(endings)
			local sg =
				gender == "masculine" and m or
				gender == "feminine" and f or
				gender == "neuter" and n or
				nil
			return {
				description = "Belarusian " .. stem .. " " .. gender .. " " .. pos ..
				"s, with adjectival endings, ending in " .. (sg and sg .. " in the nominative singular and " or "") ..
				pl .. " in the nominative plural." .. stemtext .. " " .. accentdesc,
				breadcrumb = stem .. " " .. gender .. accenttext,
				parents = {
					{name = "adjectival " .. pos .. "s", sort = stem .. " " .. gender .. accenttext},
					pos .. "s by stem type, gender and accent pattern",
				}
			}
		end
	end

	-- First group is .* to capture e.g. "hard third-declension".
	local part1, stem, gender, accent, part2, pos = rmatch(data.label, "^((.*) (.-)%-form) accent%-(.-)( (.*)s)$")
	local ending
	if not stem then
		-- check for e.g. 'Belarusian hard masculine accent-a nouns in -а'
		part1, stem, gender, accent, part2, pos, ending = rmatch(data.label, "^((.-) ([a-z]+ine)) accent%-(.-)( (.*)s in %-([ао]))$")
		if stem then
			gender = gender .. " in -" .. ending
		end
	end
	if stem then
		local stem_gender_text = get_stem_gender_text(stem, gender, pos)
		if stem_gender_text then
			local accent_text = " This " .. pos .. " is stressed according to accent pattern " ..
				escape_accent(accent) .. " (see [[Template:be-ndecl]])."
			return {
				description = "Belarusian " .. stem_gender_text .. accent_text,
				breadcrumb = "Accent-" .. escape_accent(accent),
				parents = {
					{name = part1 .. part2, sort = accent},
					pos .. "s by stem type, gender and accent pattern",
				}
			}
		end
	end

	-- First group is .* to capture e.g. "hard third-declension".
	local stem, gender, pos = rmatch(data.label, "^(.*) (.-)%-form (.*)s$")
	if not stem then
		-- check for e.g. 'Belarusian hard masculine nouns in -а'
		stem, gender, pos, ending = rmatch(data.label, "^(.-) ([a-z]+ine) (.*)s in %-([ао])$")
		if stem then
			gender = gender .. " in -" .. ending
		end
	end
	if stem then
		local stem_gender_text = get_stem_gender_text(stem, gender, pos)
		if stem_gender_text then
			return {
				description = "Belarusian " .. stem_gender_text,
				breadcrumb = ending and stem .. " " .. gender or stem .. " " .. gender .. "-form",
				parents = {pos .. "s by stem type and gender"},
			}
		end
	end

	local pos, accent = rmatch(data.label, "^(.*)s with accent pattern (.*)$")
	if accent then
		return {
			description = "Belarusian " .. pos .. "s with accent pattern " .. escape_accent(accent) ..
				" (see [[Template:be-ndecl]]).",
			breadcrumb = {name = escape_accent(accent), nocap = true},
			parents = {{name = pos .. "s by accent pattern", sort = accent}},
		}
	end

	local pos, alternation = rmatch(data.label, "^(.*)s with (.*%-.*) alternation$")
	if alternation then
		return {
			description = "Belarusian " .. pos .. "s with vowel alternation between " ..
				noun_vowel_alternation_expl[alternation] .. ".",
			breadcrumb = {name = alternation, nocap = true},
			parents = {{name = pos .. "s by vowel alternation", sort = alternation}},
		}
	end
end)


return {LABELS = labels, HANDLERS = handlers}