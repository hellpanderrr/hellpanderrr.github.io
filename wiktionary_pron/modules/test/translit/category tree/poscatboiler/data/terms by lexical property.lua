local labels = {}
local raw_categories = {}
local handlers = {}



-----------------------------------------------------------------------------
--                                                                         --
--                                  LABELS                                 --
--                                                                         --
-----------------------------------------------------------------------------


labels["terms by lexical property"] = {
	description = "{{{langname}}} terms categorized by properties relating to spelling, pronunciation or meaning.",
	umbrella_parents = "Fundamental",
	parents = {{name = "{{{langcat}}}", raw = true}},
}

labels["autohyponyms"] = {
	description = "{{{langname}}} terms that have at least two meanings, one of which is a hyponym of the other.",
	parents = {"terms by lexical property"},
}

labels["character counts"] = {
	description = "{{{langname}}} terms categorized by their quantities of characters.",
	parents = {"terms by orthographic property"},
}

labels["contranyms"] = {
	description = "{{{langname}}} terms that have two opposite meanings.",
	parents = {"terms by lexical property"},
}

labels["double negatives"] = {
	description = "{{{langname}}} terms which include a [[double negative]], either etymologically or in a definition.",
	parents = {"terms by lexical property"},
}

labels["heteronyms"] = {
	description = "{{{langname}}} terms that have different meanings depending on their etymology and/or on how they are pronounced.",
	parents = {"terms by lexical property"},
}

labels["nuqtaless forms"] = {
	description = "{{{langname}}} terms that are spelled without a [[nuqta]].",
	parents = {"terms by orthographic property"},
}

labels["palindromes"] = {
	description = "{{{langname}}} terms whose characters are read equally both from left to right and vice versa, normally ignoring spaces, [[diacritic]]s and punctuation.",
	parents = {"terms by their sequences of characters"},
}

labels["pleonastic compounds"] = {
	description = "{{{langname}}} compound terms where the head is a hyponym of its other part and whose other part is its synonym.",
	parents = {"terms by lexical property", "compound terms"},
}

labels["pleonastic compound adjectives"] = {
	description = "{{{langname}}} compound adjectives where the head is a hyponym of its other part and whose other part is its synonym.",
	parents = {"pleonastic compounds", "compound adjectives"},
}

labels["pleonastic compound nouns"] = {
	description = "{{{langname}}} compound nouns where the head is a hyponym of its other part and where the head is the synonym for the whole.",
	parents = {"pleonastic compounds", "compound nouns"},
}

labels["pronunciation spellings"] = {
	description = "{{{langname}}} terms spelled to represent a pronunciation, often a nonstandard one.",
	parents = {"terms by orthographic property"},
}

labels["tautophrases"] = {
	description = "{{{langname}}} phrases that repeat the same idea or concept using the same words.",
	parents = {"terms by lexical property"},
}

labels["terms by orthographic property"] = {
	description = "{{{langname}}} terms categorized by properties relating to [[orthography]] or [[spelling]].",
	parents = {"terms by lexical property"},
}

labels["calculator words"] = {
	description = "{{{langname}}} terms that can be spelled on a [[seven-segment]] display, as found on pocket calculators, by turning numbers upside-down.",
	parents = {"terms by orthographic property"},
}

labels["words by number of syllables"] = {
	description = "{{{langname}}} words categorized by number of syllables.",
	parents = {"terms by phonemic property"},
}

labels["terms by their individual characters"] = {
	description = "{{{langname}}} terms categorized by whether they include certain individual characters.",
	parents = {"terms by orthographic property"},
}

labels["terms by their sequences of characters"] = {
	description = "{{{langname}}} terms categorized by whether they include certain sequences of characters.",
	parents = {"terms by orthographic property"},
}

labels["terms with consecutive instances of the same letter"] = {
	description = "{{{langname}}} words categorized by the number of consecutive instances of the same letter they contain.",
	parents = {"terms by orthographic property"},
}

labels["terms containing italics"] = {
	description = "{{{langname}}} terms containing [[italics]].",
	parents = {"terms by orthographic property"},
}

labels["terms containing Roman numerals"] = {
	description = "{{{langname}}} terms containing [[Roman numeral]]s.",
	parents = {"terms by orthographic property"},
}

labels["terms with mixed convergence"] = {
	description = "{{{langname}}} terms where the spelling represents a variant pronunciation that differs from (one of) the current standard pronunciation(s).",
	parents = {"terms by orthographic property", "terms by phonemic property"},
}

labels["terms with homophones"] = {
	description = "{{{langname}}} terms that have one or more [[homophones]]: other terms that are pronounced in the same way but spelled differently.",
	parents = {"terms by lexical property"},
}

labels["terms where the adjective follows the noun"] = {
	description = "{{{langname}}} terms where the adjective follows the noun. These adjectives within these terms are sometimes referred to as postpositive or postnominal adjectives.",
	parents = {"terms by orthographic property"},
}

labels["terms written in foreign scripts"] = {
	description = "{{{langname}}} terms that are written in a different, non-native script.",
	parents = {"terms by orthographic property"},
}

labels["terms written in multiple scripts"] = {
	description = "{{{langname}}} terms that are written using more than one script.",
	parents = {"terms by orthographic property"},
}

labels["one-letter words"] = {
	description = "{{{langname}}} individual words consisting of exactly one letter. They have meaning(s) other than their letter or the shape of their letter which are not abbreviations, names, numbers or symbols.",
	parents = {name = "character counts", sort = "1"},
}

labels["two-letter words"] = {
	description = "{{{langname}}} individual words composed of exactly two letters. They have meaning(s) beyond their component letters that are neither names nor abbreviations.",
	parents = {name = "character counts", sort = "2"},
}

labels["three-letter words"] = {
	description = "{{{langname}}} individual words composed of exactly three letters. They have meaning(s) beyond their component letters that are neither names nor abbreviations.",
	parents = {name = "character counts", sort = "3"},
}

labels["two-letter abbreviations"] = {
	description = "{{{langname}}} abbreviations composed of exactly two letters.",
	parents = {name = "character counts", sort = "2"},
}

labels["three-letter abbreviations"] = {
	description = "{{{langname}}} abbreviations composed of exactly three letters.",
	parents = {name = "character counts", sort = "3"},
}

labels["four-letter abbreviations"] = {
	description = "{{{langname}}} abbreviations composed of exactly four letters.",
	parents = {name = "character counts", sort = "4"},
}

labels["five-letter abbreviations"] = {
	description = "{{{langname}}} abbreviations composed of exactly five letters.",
	parents = {name = "character counts", sort = "5"},
}

labels["terms by phonemic property"] = {
	description = "{{{langname}}} terms categorized by properties relating to [[pronunciation]] and [[phonemics]].",
	parents = {"terms by lexical property"},
}


-- Add 'umbrella_parents' key if not already present.
for key, data in pairs(labels) do
	if not data.umbrella_parents then
		data.umbrella_parents = "Terms by lexical property subcategories by language"
	end
end


-----------------------------------------------------------------------------
--                                                                         --
--                              RAW CATEGORIES                             --
--                                                                         --
-----------------------------------------------------------------------------


raw_categories["Terms by lexical property subcategories by language"] = {
	description = "Umbrella categories covering topics related to terms categorized by their lexical properties, such as palindromes and number of letters or syllables in a word.",
	additional = "{{{umbrella_meta_msg}}}",
	parents = {
		"Umbrella metacategories",
		{name = "terms by lexical property", is_label = true, sort = " "},
	},
}

raw_categories["Words by number of syllables subcategories by language"] = {
	description = "Umbrella categories covering topics related to words categorized by their number of syllables.",
	additional = "{{{umbrella_meta_msg}}}",
	parents = {
		"Umbrella metacategories",
		{name = "words by number of syllables", is_label = true, sort = " "},
	},
}

raw_categories["Terms with consecutive instances of the same letter subcategories by language"] = {
	description = "Umbrella categories covering topics related to terms categorized by the number of consecutive instances of the same letter they contain.",
	additional = "{{{umbrella_meta_msg}}}",
	parents = {
		"Umbrella metacategories",
		{name = "terms with consecutive instances of the same letter", is_label = true, sort = " "},
	},
}


-----------------------------------------------------------------------------
--                                                                         --
--                                 HANDLERS                                --
--                                                                         --
-----------------------------------------------------------------------------


table.insert(handlers, function(data)
	local number = data.label:match("^([1-9][0-9]*)%-syllable words$")
	if number then
		return {
			description = "{{{langname}}} words that are pronounced in " .. number .. " syllable" .. (number == "1" and "" or "s") .. ".",
			breadcrumb = number,
			umbrella_parents = "Words by number of syllables subcategories by language",
			parents = {{
				name = "words by number of syllables",
				sort = ("#%02d"):format(number),
			}},
		}
	end
end)

table.insert(handlers, function(data)
	local number = data.label:match("^terms with ([1-9][0-9]*) consecutive instances of the same letter$")
	if number then
		return {
			description = "{{{langname}}} terms containing " .. number .. " consecutive instances of the same letter.",
			breadcrumb = number,
			umbrella_parents = "Terms with consecutive instances of the same letter subcategories by language",
			parents = {{
				name = "terms with consecutive instances of the same letter",
				sort = ("#%02d"):format(number),
			}},
		}
	end
end)


return {LABELS = labels, RAW_CATEGORIES = raw_categories, HANDLERS = handlers}