
local data = {}

-- A list of all possible "parts" that a specification can be made out of. For each part, we list
-- the class it's in (gender, animacy, etc.), the associated category (if any) and the display form.
-- In a given gender/number spec, only one part of each class is allowed.
data.codes = {
	["?"] = {type = "other", display = '<abbr title="gender incomplete">?</abbr>'},
	-- FIXME: The following should be either eliminated in favor of g! or converted to a general "gender/number unattested".
	["?!"] = {type = "other", display = '<abbr title="gender unattested">gender unattested</abbr>'},

-- Genders
	["m"] = {type = "gender", cat = "masculine POS", display = '<abbr title="masculine gender">m</abbr>'},
	["f"] = {type = "gender", cat = "feminine POS", display = '<abbr title="feminine gender">f</abbr>'},
	["n"] = {type = "gender", cat = "neuter POS", display = '<abbr title="neuter gender">n</abbr>'},
	["c"] = {type = "gender", cat = "common-gender POS", display = '<abbr title="common gender">c</abbr>'},
	["gneut"] = {type = "gender", cat = "gender-neutral POS", display = '<abbr title="gender-neutral">gender-neutral</abbr>'},
	["g!"] = {type = "gender", display = '<abbr title="gender unattested">gender unattested</abbr>'},

-- Animacy
	-- Animate = either animal or personal (for Russian, etc.)
	["an"] = {type = "animacy", cat = "animate POS", display = '<abbr title="animate">anim</abbr>'},
	["in"] = {type = "animacy", cat = "inanimate POS", display = '<abbr title="inanimate">inan</abbr>'},
	-- Animal (for Ukrainian, Belarusian, Polish, etc.)
	["anml"] = {type = "animacy", cat = "animal POS", display = '<abbr title="animal">animal</abbr>'},
	-- Personal (for Ukrainian, Belarusian, Polish, etc.)
	["pr"] = {type = "animacy", cat = "personal POS", display = '<abbr title="personal">pers</abbr>'},
	["np"] = {type = "animacy", cat = "nonpersonal POS", display = '<abbr title="nonpersonal">npers</abbr>'},
	["an!"] = {type = "animacy", display = '<abbr title="animacy unattested">animacy unattested</abbr>'},

-- Virility (for Polish)
	["vr"] = {type = "virility", cat = "virile POS", display = '<abbr title="virile (= masculine personal)">vir</abbr>'},
	["nv"] = {type = "virility", cat = "nonvirile POS", display = '<abbr title="nonvirile (= other than masculine personal)">nvir</abbr>'},

-- Numbers
	["s"] = {type = "number", display = '<abbr title="singular number">sg</abbr>'},
	["d"] = {type = "number", cat = "dualia tantum", display = '<abbr title="dual number">du</abbr>'},
	["p"] = {type = "number", cat = "pluralia tantum", display = '<abbr title="plural number">pl</abbr>'},
	["num!"] = {type = "number", display = '<abbr title="number unattested">number unattested</abbr>'},

-- Verb qualifiers
	["impf"] = {type = "aspect", cat = "imperfective POS", display = '<abbr title="imperfective aspect">impf</abbr>'},
	["pf"] = {type = "aspect", cat = "perfective POS", display = '<abbr title="perfective aspect">pf</abbr>'},
	["asp!"] = {type = "aspect", display = '<abbr title="aspect unattested">aspect unattested</abbr>'},
}

-- Combined codes that are equivalent to giving multiple specs. `mf` is the same as specifying two separate specs,
-- one with `m` in it and the other with `f`. `mfbysense` is similar but is used for nouns that can be either masculine
-- or feminine according as to whether they refer to masculine or feminine beings.
data.combinations = {
	["mf"] = {codes = {"m", "f"}},
	["mfequiv"] = {codes = {"m", "f"}, display = '<abbr title="different genders do not affect the meaning">same meaning</abbr>'},
	["mfbysense"] = {codes = {"m", "f"}, cat = "masculine and feminine POS by sense",
		display = '<abbr title="according to the gender of the referent">by sense</abbr>'},
	["biasp"] = {codes = {"impf", "pf"}},
}

-- Categories when multiple gender/number codes of a given type occur in different specs (two or more of the same type
-- cannot occur in a single spec).
data.multicode_cats = {
	["gender"] = "POS with multiple genders",
	["animacy"] = "POS with multiple animacies",
	["aspect"] = "biaspectual POS",
}

return data