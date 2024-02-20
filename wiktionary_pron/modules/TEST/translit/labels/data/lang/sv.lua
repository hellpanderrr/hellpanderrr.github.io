local labels = {}

local function alias(a, b) for _, v in ipairs(b) do labels[v] = a end end -- allows aliases to be entered as a list

labels["Southern Sweden"] = {
	display = "[[w:South Swedish dialects|Southern]]",
	regional_categories = "Southern",
}
alias("Southern Sweden", {"southern Sweden", "Southern Swedish", "southern Swedish", "South Sweden", "south Sweden", "South Swedish", "south Swedish"})

labels["past subjunctive"] = {
	display = "dated",
	Wiktionary = "Appendix:Swedish verbs",
}

labels["present subjunctive"] = {
	display = "archaic",
	Wiktionary = "Appendix:Swedish verbs",
}

labels["plural present indicative"] = {
	display = "pre-1940",
	Wiktionary = "Appendix:Swedish verbs",
}

labels["1st plural present indicative"] = {
	display = "obsolete",
	Wiktionary = "Appendix:Swedish verbs",
}

labels["2nd plural present indicative"] = {
	display = "obsolete",
	Wiktionary = "Appendix:Swedish verbs",
}

labels["plural past indicative"] = {
	display = "pre-1940",
	Wiktionary = "Appendix:Swedish verbs",
}

labels["1st plural past indicative"] = {
	display = "obsolete",
	Wiktionary = "Appendix:Swedish verbs",
}

labels["2nd plural past indicative"] = {
	display = "obsolete",
	Wiktionary = "Appendix:Swedish verbs",
}

labels["1st plural imperative"] = {
	display = "obsolete",
	Wiktionary = "Appendix:Swedish verbs",
}

labels["2nd plural imperative"] = {
	display = "archaic or dialectal",
	Wiktionary = "Appendix:Swedish verbs",
}

return labels