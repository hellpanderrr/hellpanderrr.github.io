local labels = {}

local function alias(a, b) for _, v in ipairs(b) do labels[v] = a end end -- allows aliases to be entered as a list

labels["East and West Flanders"] = {
	display = "[[w:East Flanders|East]] and [[w:West Flanders|West Flanders]]",
	regional_categories = "East and West Flemish",
}
alias("East and West Flanders", {"Flanders", "Flemish"})

labels["Northern Dutch"] = {
	display = "Northern",
	Wikipedia = "Dutch dialects",
	plain_categories = true,
}

labels["Southern Dutch"] = {
	display = "Southern",
	Wikipedia = "Dutch dialects",
	plain_categories = true,
}

labels["archaic case form"] = {
	display = "archaic",
	Wikipedia = "Archaic Dutch declension",
}

labels["subjunctive"] = {
	display = "dated or formal",
	Wikipedia = "Subjunctive in Dutch",
}

labels["plural imperative"] = {
	display = "archaic",
	Wikipedia = "Dutch conjugation",
}

return labels