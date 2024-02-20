local m = {}

--[=[
This table maps *FROM* Wikimedia language codes (used in lang-specific Wikipedias and Wiktionaries) into English Wiktionary language codes.

See also the following:
* `interwiki_langs` in [[Module:translations/data]], which maps in the other direction (from English Wiktionary codes to foreign Wiktionaries),
   specifically for {{t+}};
* the `wiktprefix` field of the `metadata` variable in [[MediaWiki:Gadget-TranslationAdder-Data.js]], which also maps from English Wiktionary
  codes to foreign Wiktionaries for use with the TranslationAdder gadget;
* the `wikimedia_codes` field of the language data in e.g. [[Module:languages/data/2]], which also maps from English Wiktionary codes to
  Wikimedia language codes.
]=]

m["als"] = {
	wiktionary_code = "gsw",
}

m["bat-smg"] = {
	wiktionary_code = "sgs",
}

m["be-tarask"] = {
	canonicalName = "Taraškievica Belarusian",
	wiktionary_code = "be",
}

m["bs"] = {
	canonicalName = "Bosnian",
	wiktionary_code = "sh",
}

m["bxr"] = {
	wiktionary_code = "bua",
}

m["diq"] = {
	wiktionary_code = "zza",
}

m["eml"] = {
	canonicalName = "Emiliano-Romagnolo",
	wiktionary_code = "egl",
}

m["fiu-vro"] = {
	wiktionary_code = "vro",
}

m["hr"] = {
	canonicalName = "Croatian",
	wiktionary_code = "sh",
}

m["ksh"] = {
	wiktionary_code = "gmw-cfr",
}

m["ku"] = {
	canonicalName = "Kurdish",
	wiktionary_code = "kmr",
}

m["kv"] = {
	canonicalName = "Komi",
	wiktionary_code = "kpv",
}

m["nrm"] = {
	wiktionary_code = "nrf",
}

m["prs"] = {
	wiktionary_code = "fa",
}

m["roa-rup"] = {
	wiktionary_code = "rup",
}

m["roa-tara"] = {
	wiktionary_code = "roa-tar",
}

m["simple"] = {
	canonicalName = "Simple English",
	wiktionary_code = "en",
}

m["sr"] = {
	canonicalName = "Serbian",
	wiktionary_code = "sh",
}

m["zh-classical"] = {
	wiktionary_code = "ltc",
}

m["zh-min-nan"] = {
	wiktionary_code = "nan",
}

m["zh-yue"] = {
	wiktionary_code = "yue",
}

return m