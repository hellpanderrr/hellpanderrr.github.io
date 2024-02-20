local labels = {}

-- Qualifiers and similar labels.

-- NOTE: This module is loaded both by [[Module:labels]] and by [[Module:accent qualifier]].

-- Helper labels

labels["_"] = {
	display = "",
	omit_preComma = true,
	omit_postComma = true,
}

labels["also"] = {
	omit_postComma = true,
}

labels["and"] = {
	aliases = {"&"},
	omit_preComma = true,
	omit_postComma = true,
}

labels["or"] = {
	omit_preComma = true,
	omit_postComma = true,
}

labels[";"] = {
	omit_preComma = true,
	omit_postComma = true,
	omit_preSpace = true,
}

labels["by"] = {
	omit_preComma = true,
	omit_postComma = true,
}

labels["with"] = {
	aliases = {"+"},
	omit_preComma = true,
	omit_postComma = true,
}

-- combine with "except in", "outside"? or retain for entries like "wnuczę"?
labels["except"] = {
	omit_preComma = true,
	omit_postComma = true,
}

labels["outside"] = {
	aliases = {"except in"},
	omit_preComma = true,
	omit_postComma = true,
}

-- Qualifier labels

labels["chiefly"] = {
	aliases = {"mainly", "mostly", "primarily"},
	omit_postComma = true,
}

labels["especially"] = {
	omit_postComma = true,
}

labels["excluding"] = {
	omit_postComma = true,
}

labels["extremely"] = {
	omit_postComma = true,
}

labels["frequently"] = {
	omit_postComma = true,
}

-- e.g. "highly nonstandard"
labels["highly"] = {
	omit_postComma = true,
}

labels["in"] = {
	omit_postComma = true,
}

labels["including"] = {
	omit_postComma = true,
}

-- e.g. "many dialects"
labels["many"] = {
	omit_postComma = true,
}

labels["markedly"] = {
	omit_postComma = true,
}

labels["mildly"] = {
	omit_postComma = true,
}

labels["now"] = {
	aliases = {"nowadays"},
	omit_postComma = true,
}

labels["occasionally"] = {
	omit_postComma = true,
}

labels["of"] = {
	omit_postComma = true,
}

labels["of a"] = {
	omit_postComma = true,
}

labels["of an"] = {
	omit_postComma = true,
}

labels["often"] = {
	aliases = {"commonly"},
	omit_postComma = true,
}

labels["originally"] = {
	omit_postComma = true,
}

-- e.g. "law, otherwise archaic"
labels["otherwise"] = {
	omit_postComma = true,
}

labels["particularly"] = {
	omit_postComma = true,
}

labels["possibly"] = {
--	aliases = {"perhaps"},
	omit_postComma = true,
}

labels["rarely"] = {
	omit_postComma = true,
}

labels["rather"] = {
	omit_postComma = true,
}

labels["relatively"] = {
	omit_postComma = true,
}

labels["slightly"] = {
	omit_postComma = true,
}

labels["sometimes"] = {
	omit_postComma = true,
}

labels["somewhat"] = {
	omit_postComma = true,
}

labels["strongly"] = {
	omit_postComma = true,
}

-- e.g. "then colloquial, now dated"
labels["then"] = {
	omit_postComma = true,
}

labels["typically"] = {
	omit_postComma = true,
}

labels["usually"] = {
	omit_postComma = true,
}

labels["very"] = {
	omit_postComma = true,
}

labels["with respect to"] = {
	aliases = {"wrt"},
	omit_postComma = true,
}

return require("labels").finalize_data(labels)