local labels = {}
local handlers = {}

local rmatch = mw.ustring.match


--------------------------------- Verbs --------------------------------

labels["verbs by conjugation"] = {
	description = "Bulgarian verbs categorized by conjugation.",
	parents = {{name = "verbs by inflection type", sort = "conjugation"}},
}

conj_desc = {
	["1"] = "2nd singular present in -еш.",
	["2"] = "2nd singular present in -иш.",
	["3"] = "lemma in -ам or -ям (never with ending stress).",
}

subconj_desc = {
	["1.1"] = "Lemma ends in stressed -а́ (always after т, д, с or к). Exception: вля́за, сля́за, which are " ..
		"irregular in many ways. 1st singular aorist in unstressed -ох.",
	["1.2"] = "Quite common class. Lemma ends in -а (may or may not be stressed; never follows т, д, с, з, к, " ..
		"or a hushing consonant). A common subclass ends in unstressed -на. 1st singular aorist in -ах with " ..
		"stress matching lemma (if stress on stem, also has dialectal ending-stressed aorist in -а́х).\n" ..
		"* Special case: verbs in -ера́, which lose the -е- in the aorist.\n" ..
		"* Special case: греба́, гриза́, with stem-stressed aorists гре́бах, гри́зах.",
	["1.3"] = "A small class. Lemma ends in unstressed -я; 1st singular aorist in -ах (also has " ..
		"dialectal ending-stressed aorist in -а́х).",
	["1.4"] = "A small class. Lemma ends in unstressed -а after a hushing consonant. 1st singular aorist " ..
		"in -ах and final stem consonant changes to its non-iotated equivalent (ж -> г in лъ́жа, стри́жа, стъ́ржа " ..
		"and derivatives, otherwise з; ч-> к; ш -> с). Also has dialectal ending-stressed aorist in -а́х.",
	["1.5"] = "A very small class. Lemma ends in consonant + stressed -ра (exception: ща). 1st singular " ..
		"aorist in -я́х.",
	["1.6"] = "A small class. Lemma ends in -е́я, -а́я or rarely -я́я. 1st singular aorist in -ях. Also has " ..
		"dialectal ending-stressed aorist in -я́х.\n" ..
		"* Beware: зна́я is in this class, but prefixed derivatives are in class 1.7.",
	["1.7"] = "A fairly large class. Lemma ends in stressed vowel + -я. 1st singular aorist ends in -х " ..
		"directly added onto the final vowel of the stem. (The common subclass of verbs in -е́я have aorist in " ..
		"-я́х, or -а́х after a hushing consonant.)",
	["2.1"] = "Extremely common class. Lemma ends in -я (or -а after a hushing consonant), may or may not have ending stress. 1st singular aorist in -их with stress matching lemma (if stress on stem, also has dialectal ending-stressed aorist in -и́х).",
	["2.2"] = "Lemma ends in stressed -я́ (not after a hushing consonant), 1st singular aorist in -я́х.",
	["2.3"] = "Lemma ends in stressed -а́ after a hushing consonant, 1st singular aorist in -а́х.",
}


table.insert(handlers, function(data)
	local conj = rmatch(data.label, "^conjugation ([1-9]) verbs$")
	if conj and conj_desc[conj] then
		return {
			description = "Bulgarian conjugation " .. conj .. " verbs, with " .. conj_desc[conj],
			breadcrumb = conj,
			parents = {{name = "verbs by conjugation", sort = conj}},
		}
	end
	local subconj, conj, conj2 = rmatch(data.label, "^conjugation (([1-9])%.([1-9])) verbs$")
	if subconj and subconj_desc[subconj] then
		return {
			description = "Bulgarian conjugation " .. subconj .. " verbs, with " .. conj_desc[conj] .. " " ..
				subconj_desc[subconj],
			breadcrumb = subconj,
			parents = {{name = "conjugation " .. conj .. " verbs", sort = conj2}},
		}
	end
end)


return {LABELS = labels, HANDLERS = handlers}