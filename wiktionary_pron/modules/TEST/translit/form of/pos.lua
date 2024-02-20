--[=[

This module contains abbreviations of part-of-speech tags.

--]=]

local pos_tags = {
	["a"] = "adjective",
	["adj"] = "adjective",
	["adv"] = "adverb",
	["art"] = "article",
	["det"] = "determiner",
	["cnum"] = "cardinal numeral",
	["conj"] = "conjunction",
	["conv"] = "converb",
	["int"] = "interjection",
	["intj"] = "interjection",
	["n"] = "noun",
	["num"] = "numeral",
	["part"] = "participle",
	["pcl"] = "particle",
	["pn"] = "proper noun",
	["proper"] = "proper noun",
	["postp"] = "postposition",
	["pre"] = "preposition",
	["prep"] = "preposition",
	["pro"] = "pronoun",
	["pron"] = "pronoun",
	["onum"] = "ordinal numeral",
	["v"] = "verb",
	["vb"] = "verb",
	["vi"] = "intransitive verb",
	["vt"] = "transitive verb",
	["vti"] = "transitive and intransitive verb",
}

return pos_tags

-- For Vim, so we get 4-space tabs
-- vim: set ts=4 sw=4 noet: