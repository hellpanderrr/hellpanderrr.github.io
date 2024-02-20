local u = mw.ustring.char
local m_langdata = require("languages/data")
local c = m_langdata.chars
local p = m_langdata.puaChars
local s = m_langdata.shared

-- Ideally, we want to move these into [[Module:languages/data]], but because (a) it's necessary to use require on that module, and (b) they're only used in this data module, it's less memory-efficient to do that at the moment. If it becomes possible to use mw.loadData, then these should be moved there.
s["no-sortkey"] = {
	remove_diacritics = c.grave .. c.acute .. c.circ .. c.tilde .. c.macron .. c.dacute .. c.caron .. c.cedilla,
	remove_exceptions = {"å"},
	from = {"æ", "ø", "å"},
	to = {"z" .. p[1], "z" .. p[2], "z" .. p[3]}
}

s["no-standardchars"] = "AaBbDdEeFfGgHhIiJjKkLlMmNnOoPpRrSsTtUuVvYyÆæØøÅå" .. c.punc

local m = {}

m["aa"] = {
	"Afar",
	27811,
	"cus-eas",
	"Latn, Ethi",
	entry_name = {Latn = {remove_diacritics = c.acute}},
}

m["ab"] = {
	"Abkhaz",
	5111,
	"cau-abz",
	"Cyrl, Geor, Latn",
	translit = {
		Cyrl = "ab-translit",
		Geor = "Geor-translit",
	},
	override_translit = true,
	display_text = {Cyrl = s["cau-Cyrl-displaytext"]},
	entry_name = {
		Cyrl = s["cau-Cyrl-entryname"],
		Latn = s["cau-Latn-entryname"],
	},
	sort_key = {
		Cyrl = {
			from = {
				"х'ә", -- 3 chars
				"гь", "гә", "ӷь", "ҕь", "ӷә", "ҕә", "дә", "ё", "жь", "жә", "ҙә", "ӡә", "ӡ'", "кь", "кә", "қь", "қә", "ҟь", "ҟә", "ҫә", "тә", "ҭә", "ф'", "хь", "хә", "х'", "ҳә", "ць", "цә", "ц'", "ҵә", "ҵ'", "шь", "шә", "џь", -- 2 chars
				"ӷ", "ҕ", "ҙ", "ӡ", "қ", "ҟ", "ԥ", "ҧ", "ҫ", "ҭ", "ҳ", "ҵ", "ҷ", "ҽ", "ҿ", "ҩ", "џ", "ә" -- 1 char
			},
			to = {
				"х" .. p[4],
				"г" .. p[1], "г" .. p[2], "г" .. p[5], "г" .. p[6], "г" .. p[7], "г" .. p[8], "д" .. p[1], "е" .. p[1], "ж" .. p[1], "ж" .. p[2], "з" .. p[2], "з" .. p[4], "з" .. p[5], "к" .. p[1], "к" .. p[2], "к" .. p[4], "к" .. p[5], "к" .. p[7], "к" .. p[8], "с" .. p[2], "т" .. p[1], "т" .. p[3], "ф" .. p[1], "х" .. p[1], "х" .. p[2], "х" .. p[3], "х" .. p[6], "ц" .. p[1], "ц" .. p[2], "ц" .. p[3], "ц" .. p[5], "ц" .. p[6], "ш" .. p[1], "ш" .. p[2], "ы" .. p[3],
				"г" .. p[3], "г" .. p[4], "з" .. p[1], "з" .. p[3], "к" .. p[3], "к" .. p[6], "п" .. p[1], "п" .. p[2], "с" .. p[1], "т" .. p[2], "х" .. p[5], "ц" .. p[4], "ч" .. p[1], "ч" .. p[2], "ч" .. p[3], "ы" .. p[1], "ы" .. p[2], "ь" .. p[1]
			}
		},
	},
}

m["ae"] = {
	"Avestan",
	29572,
	"ira-cen",
	"Avst, Gujr",
	translit = {Avst = "Avst-translit"},
	wikipedia_article = "Avestan",
}

m["af"] = {
	"Afrikaans",
	14196,
	"gmw-frk",
	"Latn, Arab",
	ancestors = "nl",
	sort_key = {
		Latn = {
			remove_diacritics = c.grave .. c.acute .. c.circ .. c.tilde .. c.diaer .. c.ringabove .. c.cedilla .. "'",
			from = {"['ʼ]n"},
			to = {"n" .. p[1]}
		}
	},
}

m["ak"] = {
	"Akan",
	28026,
	"alv-ctn",
	"Latn",
}

m["am"] = {
	"Amharic",
	28244,
	"sem-eth",
	"Ethi",
	translit = "Ethi-translit",
}

m["an"] = {
	"Aragonese",
	8765,
	"roa-ibe",
	"Latn",
	ancestors = "roa-oan",
}

m["ar"] = {
	"Arabic",
	13955,
	"sem-arb",
	"Arab, Hebr, Syrc, Brai",
	translit = {Arab = "ar-translit"},
	entry_name = {Arab = "ar-entryname"},
	-- put Judeo-Arabic (Hebrew-script Arabic) under the category header
	-- U+FB21 HEBREW LETTER WIDE ALEF so that it sorts after Arabic script titles
	sort_key = {
		Hebr = {
			from = {"^%f[" .. u(0x5D0) .. "-" .. u(0x5EA) .. "]"},
			to = {u(0xFB21)},
		},
	},
}

m["as"] = {
	"Assamese",
	29401,
	"inc-eas",
	"as-Beng",
	ancestors = "inc-mas",
	translit = "as-translit",
}

m["av"] = {
	"Avar",
	29561,
	"cau-ava",
	"Cyrl, Latn, Arab",
	ancestors = "oav",
	translit = {
		Cyrl = "cau-nec-translit",
		Arab = "ar-translit",
	},
	override_translit = true,
	display_text = {Cyrl = s["cau-Cyrl-displaytext"]},
	entry_name = {
		Cyrl = s["cau-Cyrl-entryname"],
		Latn = s["cau-Latn-entryname"],
	},
	sort_key = {
		Cyrl = {
			from = {"гъ", "гь", "гӏ", "ё", "кк", "къ", "кь", "кӏ", "лъ", "лӏ", "тӏ", "хх", "хъ", "хь", "хӏ", "цӏ", "чӏ"},
			to = {"г" .. p[1], "г" .. p[2], "г" .. p[3], "е" .. p[1], "к" .. p[1], "к" .. p[2], "к" .. p[3], "к" .. p[4], "л" .. p[1], "л" .. p[2], "т" .. p[1], "х" .. p[1], "х" .. p[2], "х" .. p[3], "х" .. p[4], "ц" .. p[1], "ч" .. p[1]}
		},
	},
}

m["ay"] = {
	"Aymara",
	4627,
	"sai-aym",
	"Latn",
}

m["az"] = {
	"Azerbaijani",
	9292,
	"trk-ogz",
	"Latn, Cyrl, fa-Arab",
	ancestors = "trk-oat",
	dotted_dotless_i = true,
	entry_name = {
		Latn = {
			from = {"ʼ"},
			to = {"'"},
		},
		["fa-Arab"] = "ar-entryname",
	},
	display_text = {
		Latn = {
			from = {"'"},
			to = {"ʼ"}
		}
	},
	sort_key = {
		Latn = {
			from = {
				"i", -- Ensure "i" comes after "ı".
				"ç", "ə", "ğ", "x", "ı", "q", "ö", "ş", "ü", "w"
			},
			to = {
				"i" .. p[1],
				"c" .. p[1], "e" .. p[1], "g" .. p[1], "h" .. p[1], "i", "k" .. p[1], "o" .. p[1], "s" .. p[1], "u" .. p[1], "z" .. p[1]
			}
		},
		Cyrl = {
			from = {"ғ", "ә", "ы", "ј", "ҝ", "ө", "ү", "һ", "ҹ"},
			to = {"г" .. p[1], "е" .. p[1], "и" .. p[1], "и" .. p[2], "к" .. p[1], "о" .. p[1], "у" .. p[1], "х" .. p[1], "ч" .. p[1]}
		},
	},
}

m["ba"] = {
	"Bashkir",
	13389,
	"trk-kbu",
	"Cyrl",
	translit = "ba-translit",
	override_translit = true,
	sort_key = {
		from = {"ғ", "ҙ", "ё", "ҡ", "ң", "ө", "ҫ", "ү", "һ", "ә"},
		to = {"г" .. p[1], "д" .. p[1], "е" .. p[1], "к" .. p[1], "н" .. p[1], "о" .. p[1], "с" .. p[1], "у" .. p[1], "х" .. p[1], "э" .. p[1]}
	},
}

m["be"] = {
	"Belarusian",
	9091,
	"zle",
	"Cyrl, Latn",
	ancestors = "zle-obe",
	translit = {Cyrl = "be-translit"},
	entry_name = {
		remove_diacritics = c.grave .. c.acute,
		remove_exceptions = {"Ć", "ć", "Ń", "ń", "Ś", "ś", "Ź", "ź"},
	},
	sort_key = {
		Cyrl = {
			from = {"ґ", "ё", "і", "ў"},
			to = {"г" .. p[1], "е" .. p[1], "и" .. p[1], "у" .. p[1]}
		},
		Latn = {
			from = {"ć", "č", "dz", "dź", "dž", "ch", "ł", "ń", "ś", "š", "ŭ", "ź", "ž"},
			to = {"c" .. p[1], "c" .. p[2], "d" .. p[1], "d" .. p[2], "d" .. p[3], "h" .. p[1], "l" .. p[1], "n" .. p[1], "s" .. p[1], "s" .. p[2], "u" .. p[1], "z" .. p[1], "z" .. p[2]}
		},
	},
	standardChars = {
		Cyrl = "АаБбВвГгДдЕеЁёЖжЗзІіЙйКкЛлМмНнОоПпРрСсТтУуЎўФфХхЦцЧчШшЫыЬьЭэЮюЯя",
		Latn = "AaBbCcĆćČčDdEeFfGgHhIiJjKkLlŁłMmNnŃńOoPpRrSsŚśŠšTtUuŬŭVvYyZzŹźŽž",
		(c.punc:gsub("'", "")) -- Exclude apostrophe.
	},
}

m["bg"] = {
	"Bulgarian",
	7918,
	"zls",
	"Cyrl",
	ancestors = "cu-bgm",
	translit = "bg-translit",
	entry_name = {
		remove_diacritics = c.grave .. c.acute,
		remove_exceptions = {"%f[^%z%s]ѝ%f[%z%s]"},
	},
	standardChars = "АаБбВвГгДдЕеЖжЗзИиЙйКкЛлМмНнОоПпРрСсТтУуФфХхЦцЧчШшЩщЪъЬьЮюЯя" .. c.punc,
}

m["bh"] = {
	"Bihari",
	135305,
	"inc-eas",
	"Deva",
}

m["bi"] = {
	"Bislama",
	35452,
	"crp",
	"Latn",
	ancestors = "en",
}

m["bm"] = {
	"Bambara",
	33243,
	"dmn-emn",
	"Latn",
	sort_key = {
		from = {"ɛ", "ɲ", "ŋ", "ɔ"},
		to = {"e" .. p[1], "n" .. p[1], "n" .. p[2], "o" .. p[1]}
	},
}

m["bn"] = {
	"Bengali",
	9610,
	"inc-eas",
	"Beng, Newa",
	ancestors = "inc-mbn",
	translit = {Beng = "bn-translit"},
}

m["bo"] = {
	"Tibetan",
	34271,
	"sit-tib",
	"Tibt", -- sometimes Deva?
	ancestors = "xct",
	translit = "Tibt-translit",
	override_translit = true,
	display_text = s["Tibt-displaytext"],
	entry_name = s["Tibt-entryname"],
	sort_key = "Tibt-sortkey",
}

m["br"] = {
	"Breton",
	12107,
	"cel-brs",
	"Latn",
	ancestors = "xbm",
	sort_key = {
		from = {"ch", "c['ʼ’]h"},
		to = {"c" .. p[1], "c" .. p[2]}
	},
}

m["ca"] = {
	"Catalan",
	7026,
	"roa-ocr",
	"Latn",
	ancestors = "roa-oca",
	sort_key = {
		remove_diacritics = c.grave .. c.acute .. c.diaer .. c.cedilla,
		from = {"l·l"},
		to = {"ll"}
	},
	standardChars = "AaÀàBbCcÇçDdEeÉéÈèFfGgHhIiÍíÏïJjLlMmNnOoÓóÒòPpQqRrSsTtUuÚúÜüVvXxYyZz·" .. c.punc,
}

m["ce"] = {
	"Chechen",
	33350,
	"cau-vay",
	"Cyrl, Latn, Arab",
	translit = {
		Cyrl = "cau-nec-translit",
		Arab = "ar-translit",
	},
	override_translit = true,
	display_text = {Cyrl = s["cau-Cyrl-displaytext"]},
	entry_name = {
		Cyrl = s["cau-Cyrl-entryname"],
		Latn = s["cau-Latn-entryname"],
	},
	sort_key = {
		Cyrl = {
			from = {"аь", "гӏ", "ё", "кх", "къ", "кӏ", "оь", "пӏ", "тӏ", "уь", "хь", "хӏ", "цӏ", "чӏ", "юь", "яь"},
			to = {"а" .. p[1], "г" .. p[1], "е" .. p[1], "к" .. p[1], "к" .. p[2], "к" .. p[3], "о" .. p[1], "п" .. p[1], "т" .. p[1], "у" .. p[1], "х" .. p[1], "х" .. p[2], "ц" .. p[1], "ч" .. p[1], "ю" .. p[1], "я" .. p[1]}
		},
	},
}

m["ch"] = {
	"Chamorro",
	33262,
	"poz-sus",
	"Latn",
	sort_key = {
		remove_diacritics = "'",
		from = {"å", "ch", "ñ", "ng"},
		to = {"a" .. p[1], "c" .. p[1], "n" .. p[1], "n" .. p[2]}
	},
}

m["co"] = {
	"Corsican",
	33111,
	"roa-itd",
	"Latn",
	sort_key = {
		from = {"chj", "ghj", "sc", "sg"},
		to = {"c" .. p[1], "g" .. p[1], "s" .. p[1], "s" .. p[2]}
	},
	standardChars = "AaÀàBbCcDdEeÈèFfGgHhIiÌìÏïJjLlMmNnOoÒòPpQqRrSsTtUuÙùÜüVvZz" .. c.punc,
}

m["cr"] = {
	"Cree",
	33390,
	"alg",
	"Cans, Latn",
	translit = {Cans = "cr-translit"},
}

m["cs"] = {
	"Czech",
	9056,
	"zlw",
	"Latn",
	ancestors = "cs-ear",
	sort_key = {
		from = {"á", "č", "ď", "é", "ě", "ch", "í", "ň", "ó", "ř", "š", "ť", "ú", "ů", "ý", "ž"},
		to = {"a" .. p[1], "c" .. p[1], "d" .. p[1], "e" .. p[1], "e" .. p[2], "h" .. p[1], "i" .. p[1], "n" .. p[1], "o" .. p[1], "r" .. p[1], "s" .. p[1], "t" .. p[1], "u" .. p[1], "u" .. p[2], "y" .. p[1], "z" .. p[1]}
	},
	standardChars = "AaÁáBbCcČčDdĎďEeÉéĚěFfGgHhIiÍíJjKkLlMmNnŇňOoÓóPpRrŘřSsŠšTtŤťUuÚúŮůVvYyÝýZzŽž" .. c.punc,
}

m["cu"] = {
	"Old Church Slavonic",
	35499,
	"zls",
	"Cyrs, Glag",
	translit = {Cyrs = "Cyrs-translit", Glag = "Glag-translit"},
	entry_name = {Cyrs = s["Cyrs-entryname"]},
	sort_key = {Cyrs = s["Cyrs-sortkey"]},
}

m["cv"] = {
	"Chuvash",
	33348,
	"trk-ogr",
	"Cyrl",
	ancestors = "cv-mid",
	translit = "cv-translit",
	override_translit = true,
	sort_key = {
		from = {"ӑ", "ё", "ӗ", "ҫ", "ӳ"},
		to = {"а" .. p[1], "е" .. p[1], "е" .. p[2], "с" .. p[1], "у" .. p[1]}
	},
}

m["cy"] = {
	"Welsh",
	9309,
	"cel-brw",
	"Latn",
	ancestors = "wlm",
	sort_key = {
		remove_diacritics = c.grave .. c.acute .. c.circ .. c.diaer .. "'",
		from = {"ch", "dd", "ff", "ng", "ll", "ph", "rh", "th"},
		to = {"c" .. p[1], "d" .. p[1], "f" .. p[1], "g" .. p[1], "l" .. p[1], "p" .. p[1], "r" .. p[1], "t" .. p[1]}
	},
	standardChars = "ÂâAaBbCcDdEeÊêFfGgHhIiÎîLlMmNnOoÔôPpRrSsTtUuÛûWwŴŵYyŶŷ" .. c.punc,
}

m["da"] = {
	"Danish",
	9035,
	"gmq-eas",
	"Latn",
	ancestors = "gmq-oda",
	sort_key = {
		remove_diacritics = c.grave .. c.acute .. c.circ .. c.tilde .. c.macron .. c.dacute .. c.caron .. c.cedilla,
		remove_exceptions = {"å"},
		from = {"æ", "ø", "å"},
		to = {"z" .. p[1], "z" .. p[2], "z" .. p[3]}
	},
	standardChars = "AaBbDdEeFfGgHhIiJjKkLlMmNnOoPpRrSsTtUuVvYyÆæØøÅå" .. c.punc,
}

m["de"] = {
	"German",
	188,
	"gmw-hgm",
	"Latn, Latf",
	ancestors = "gmh",
	sort_key = {
		remove_diacritics = c.grave .. c.acute .. c.circ .. c.diaer .. c.ringabove,
		from = {"æ", "œ", "ß"},
		to = {"ae", "oe", "ss"}
	},
	standardChars = "AaÄäBbCcDdEeFfGgHhIiJjKkLlMmNnOoÖöPpQqRrSsẞßTtUuÜüVvWwXxYyZz" .. c.punc,
}

m["dv"] = {
	"Dhivehi",
	32656,
	"inc-ins",
	"Thaa, Diak",
	translit = {
		Thaa = "dv-translit",
		Diak = "Diak-translit",
	},
	override_translit = true,
}

m["dz"] = {
	"Dzongkha",
	33081,
	"sit-tib",
	"Tibt",
	ancestors = "xct",
	translit = "Tibt-translit",
	override_translit = true,
	display_text = s["Tibt-displaytext"],
	entry_name = s["Tibt-entryname"],
	sort_key = "Tibt-sortkey",
}

m["ee"] = {
	"Ewe",
	30005,
	"alv-gbe",
	"Latn",
	sort_key = {
		remove_diacritics = c.tilde,
		from = {"ɖ", "dz", "ɛ", "ƒ", "gb", "ɣ", "kp", "ny", "ŋ", "ɔ", "ts", "ʋ"},
		to = {"d" .. p[1], "d" .. p[2], "e" .. p[1], "f" .. p[1], "g" .. p[1], "g" .. p[2], "k" .. p[1], "n" .. p[1], "n" .. p[2], "o" .. p[1], "t" .. p[1], "v" .. p[1]}
	},
}

m["el"] = {
	"Greek",
	9129,
	"grk",
	"Grek, Polyt, Brai",
	ancestors = "el-kth",
	translit = {
		Grek = "el-translit",
		Polyt = "grc-translit",
	},
	override_translit = true,
	entry_name = {
		Grek = {remove_diacritics = c.caron .. c.diaerbelow .. c.brevebelow},
		Polyt = {
			remove_diacritics = c.macron .. c.breve .. c.dbrevebelow,
			from = {"[" .. c.RSQuo .. c.psili .. c.coronis .. "]"},
			to = {"'"}
		},
	},
	sort_key = {
		Grek = s["Grek-sortkey"],
		Polyt = s["Grek-sortkey"],
	},
	standardChars = {
		Grek = "΅·ͺ΄ΑαΆάΒβΓγΔδΕεέΈΖζΗηΉήΘθΙιΊίΪϊΐΚκΛλΜμΝνΞξΟοΌόΠπΡρΣσςΤτΥυΎύΫϋΰΦφΧχΨψΩωΏώ",
		Brai = c.braille,
		c.punc
	},
}

m["en"] = {
	"English",
	1860,
	"gmw-ang",
	"Latn, Brai, Shaw, Dsrt", -- entries in Shaw or Dsrt might require prior discussion
	wikimedia_codes = "en, simple",
	ancestors = "en-ear",
	sort_key = {
		Latn = {
			remove_diacritics = c.grave .. c.acute .. c.circ .. c.tilde .. c.macron .. c.diaer .. c.ringabove .. c.caron .. c.cedilla .. "'%-%s",
			from = {"æ", "œ"},
			to = {"ae", "oe"}
		},
	},
	standardChars = {
		Latn = "AaBbCcDdEeFfGgHhIiJjKkLlMmNnOoPpQqRrSsTtUuVvWwXxYyZz",
		Brai = c.braille,
		c.punc
	},
}

m["eo"] = {
	"Esperanto",
	143,
	"art",
	"Latn",
	sort_key = {
		remove_diacritics = c.grave .. c.acute,
		from = {"ĉ", "ĝ", "ĥ", "ĵ", "ŝ", "ŭ"},
		to = {"c" .. p[1], "g" .. p[1], "h" .. p[1], "j" .. p[1], "s" .. p[1], "u" .. p[1]}
	},
	standardChars = "AaBbCcĈĉDdEeFfGgĜĝHhĤĥIiJjĴĵKkLlMmNnOoPpRrSsŜŝTtUuŬŭVvZz" .. c.punc,
}

m["es"] = {
	"Spanish",
	1321,
	"roa-ibe",
	"Latn, Brai",
	ancestors = "osp",
	sort_key = {
		Latn = {
			remove_diacritics = c.acute .. c.diaer .. c.cedilla,
			from = {"ñ"},
			to = {"n" .. p[1]}
		},
	},
	standardChars = {
		Latn = "AaÁáBbCcDdEeÉéFfGgHhIiÍíJjLlMmNnÑñOoÓóPpQqRrSsTtUuÚúÜüVvXxYyZz",
		Brai = c.braille,
		c.punc
	},
}

m["et"] = {
	"Estonian",
	9072,
	"urj-fin",
	"Latn",
	sort_key = {
		from = {
			"š", "ž", "õ", "ä", "ö", "ü", -- 2 chars
			"z" -- 1 char
		},
		to = {
			"s" .. p[1], "s" .. p[3], "w" .. p[1], "w" .. p[2], "w" .. p[3], "w" .. p[4],
			"s" .. p[2]
		}
	},
	standardChars = "AaBbDdEeFfGgHhIiJjKkLlMmNnOoPpRrSsTtUuVvÕõÄäÖöÜü" .. c.punc,
}

m["eu"] = {
	"Basque",
	8752,
	"euq",
	"Latn",
	sort_key = {
		from = {"ç", "ñ"},
		to = {"c" .. p[1], "n" .. p[1]}
	},
	standardChars = "AaBbDdEeFfGgHhIiJjKkLlMmNnÑñOoPpRrSsTtUuXxZz" .. c.punc,
}

m["fa"] = {
	"Persian",
	9168,
	"ira-swi",
	"fa-Arab, Hebr",
	ancestors = "fa-cls",
	entry_name = {
		from = {"هٔ", "ٱ"}, -- character "ۂ" code U+06C2 to "ه"; hamzatu l-waṣli to a regular alif
		to = {"ه", "ا"},
		remove_diacritics = c.fathatan .. c.dammatan .. c.kasratan .. c.kashida .. c.fatha .. c.damma .. c.kasra .. c.shadda .. c.sukun .. c.superalef,
	},
	-- put Judeo-Persian (Hebrew-script Persian) under the category header
	-- U+FB21 HEBREW LETTER WIDE ALEF so that it sorts after Arabic script titles
	sort_key = {
		Hebr = {
			from = {"^%f[" .. u(0x5D0) .. "-" .. u(0x5EA) .. "]"},
			to = {u(0xFB21)},
		},
	},
}

m["ff"] = {
	"Fula",
	33454,
	"alv-fwo",
	"Latn, Adlm",
}

m["fi"] = {
	"Finnish",
	1412,
	"urj-fin",
	"Latn",
	display_text = {
		from = {"'"},
		to = {"’"}
	},
	entry_name = { -- used to indicate gemination of the next consonant
		remove_diacritics = "ˣ",
		from = {"’"},
		to = {"'"},
	},
	sort_key = {
		remove_diacritics = c.grave .. c.acute .. c.circ .. c.tilde .. c.macron .. c.dacute .. c.caron .. c.cedilla .. "':",
		remove_exceptions = {"å"},
		from = {"ø", "æ", "œ", "ß", "å", "aͤ", "oͤ", "(.)['%-]"},
		to = {"o", "ae", "oe", "ss", "z" .. p[1], "ä", "ö", "%1"}
	},
	standardChars = "AaBbDdEeFfGgHhIiJjKkLlMmNnOoPpRrSsTtUuVvYyÄäÖö" .. c.punc,
}

m["fj"] = {
	"Fijian",
	33295,
	"poz-occ",
	"Latn",
}

m["fo"] = {
	"Faroese",
	25258,
	"gmq-ins",
	"Latn",
	sort_key = {
		from = {"á", "ð", "í", "ó", "ú", "ý", "æ", "ø"},
		to = {"a" .. p[1], "d" .. p[1], "i" .. p[1], "o" .. p[1], "u" .. p[1], "y" .. p[1], "z" .. p[1], "z" .. p[2]}
	},
	standardChars = "AaÁáBbDdÐðEeFfGgHhIiÍíJjKkLlMmNnOoÓóPpRrSsTtUuÚúVvYyÝýÆæØø" .. c.punc,
}

m["fr"] = {
	"French",
	150,
	"roa-oil",
	"Latn, Brai",
	display_text = {
		from = {"'"},
		to = {"’"}
	},
	entry_name = {
		from = {"’"},
		to = {"'"},
	},
	ancestors = "frm",
	sort_key = {Latn = s["roa-oil-sortkey"]},
	standardChars = {
		Latn = "AaÀàÂâBbCcÇçDdEeÉéÈèÊêËëFfGgHhIiÎîÏïJjLlMmNnOoÔôŒœPpQqRrSsTtUuÙùÛûÜüVvXxYyZz",
		Brai = c.braille,
		c.punc
	},
}

m["fy"] = {
	"West Frisian",
	27175,
	"gmw-fri",
	"Latn",
	sort_key = {
		remove_diacritics = c.grave .. c.acute .. c.circ .. c.diaer,
		from = {"y"},
		to = {"i"}
	},
	standardChars = "AaâäàÆæBbCcDdEeéêëèFfGgHhIiïìYyỳJjKkLlMmNnOoôöòPpRrSsTtUuúûüùVvWwZz" .. c.punc,
}

m["ga"] = {
	"Irish",
	9142,
	"cel-gae",
	"Latn, Latg",
	ancestors = "mga",
	sort_key = {
		remove_diacritics = c.acute,
		from = {"ḃ", "ċ", "ḋ", "ḟ", "ġ", "ṁ", "ṗ", "ṡ", "ṫ"},
		to = {"bh", "ch", "dh", "fh", "gh", "mh", "ph", "sh", "th"}
	},
	standardChars = "AaÁáBbCcDdEeÉéFfGgHhIiÍíLlMmNnOoÓóPpRrSsTtUuÚúVv" .. c.punc,
}

m["gd"] = {
	"Scottish Gaelic",
	9314,
	"cel-gae",
	"Latn, Latg",
	ancestors = "mga",
	sort_key = {remove_diacritics = c.grave .. c.acute},
	standardChars = "AaÀàBbCcDdEeÈèFfGgHhIiÌìLlMmNnOoÒòPpRrSsTtUuÙù" .. c.punc,
}

m["gl"] = {
	"Galician",
	9307,
	"roa-ibe",
	"Latn",
	ancestors = "roa-opt",
	sort_key = {
		remove_diacritics = c.acute,
		from = {"ñ"},
		to = {"n" .. p[1]}
	},
	standardChars = "AaÁáBbCcDdEeÉéFfGgHhIiÍíÏïLlMmNnÑñOoÓóPpQqRrSsTtUuÚúÜüVvXxZz" .. c.punc,
}

m["gn"] = {
	"Guaraní",
	35876,
	"tup-gua",
	"Latn",
}

m["gu"] = {
	"Gujarati",
	5137,
	"inc-wes",
	"Arab, Gujr",
	ancestors = "inc-mgu",
	translit = {
		Gujr = "gu-translit",
	},
	entry_name = {
		remove_diacritics = c.fathatan .. c.dammatan .. c.kasratan .. c.fatha .. c.damma .. c.kasra .. c.kasra .. c.shadda .. c.sukun .. "઼"
	},
}

m["gv"] = {
	"Manx",
	12175,
	"cel-gae",
	"Latn",
	ancestors = "mga",
	sort_key = {remove_diacritics = c.cedilla .. "-"},
	standardChars = "AaBbCcÇçDdEeFfGgHhIiJjKkLlMmNnOoPpQqRrSsTtUuVvWwYy" .. c.punc,
}

m["ha"] = {
	"Hausa",
	56475,
	"cdc-wst",
	"Latn, Arab",
	entry_name = {Latn = {remove_diacritics = c.grave .. c.acute .. c.circ .. c.tilde .. c.macron}},
	sort_key = {
		Latn = {
			from = {"ɓ", "b'", "ɗ", "d'", "ƙ", "k'", "sh", "ƴ", "'y"},
			to = {"b" .. p[1], "b" .. p[2], "d" .. p[1], "d" .. p[2], "k" .. p[1], "k" .. p[2], "s" .. p[1], "y" .. p[1], "y" .. p[2]}
		},
	},
}

m["he"] = {
	"Hebrew",
	9288,
	"sem-can",
	"Hebr, Phnx, Brai",
	ancestors = "he-med",
	entry_name = {Hebr = {remove_diacritics = u(0x0591) .. "-" .. u(0x05BD) .. u(0x05BF) .. "-" .. u(0x05C5) .. u(0x05C7) .. c.CGJ}},
}

m["hi"] = {
	"Hindi",
	1568,
	"inc-hnd",
	"Deva, Kthi, Newa",
	ancestors = "inc-ohi",
	translit = {Deva = "hi-translit"},
	standardChars = {
		Deva = "अआइईउऊएऐओऔकखगघङचछजझञटठडढणतथदधनपफबभमयरलवशषसहत्रज्ञक्षक़ख़ग़ज़झ़ड़ढ़फ़काखागाघाङाचाछाजाझाञाटाठाडाढाणाताथादाधानापाफाबाभामायारालावाशाषासाहात्राज्ञाक्षाक़ाख़ाग़ाज़ाझ़ाड़ाढ़ाफ़ाकिखिगिघिङिचिछिजिझिञिटिठिडिढिणितिथिदिधिनिपिफिबिभिमियिरिलिविशिषिसिहित्रिज्ञिक्षिक़िख़िग़िज़िझ़िड़िढ़िफ़िकीखीगीघीङीचीछीजीझीञीटीठीडीढीणीतीथीदीधीनीपीफीबीभीमीयीरीलीवीशीषीसीहीत्रीज्ञीक्षीक़ीख़ीग़ीज़ीझ़ीड़ीढ़ीफ़ीकुखुगुघुङुचुछुजुझुञुटुठुडुढुणुतुथुदुधुनुपुफुबुभुमुयुरुलुवुशुषुसुहुत्रुज्ञुक्षुक़ुख़ुग़ुज़ुझ़ुड़ुढ़ुफ़ुकूखूगूघूङूचूछूजूझूञूटूठूडूढूणूतूथूदूधूनूपूफूबूभूमूयूरूलूवूशूषूसूहूत्रूज्ञूक्षूक़ूख़ूग़ूज़ूझ़ूड़ूढ़ूफ़ूकेखेगेघेङेचेछेजेझेञेटेठेडेढेणेतेथेदेधेनेपेफेबेभेमेयेरेलेवेशेषेसेहेत्रेज्ञेक्षेक़ेख़ेग़ेज़ेझ़ेड़ेढ़ेफ़ेकैखैगैघैङैचैछैजैझैञैटैठैडैढैणैतैथैदैधैनैपैफैबैभैमैयैरैलैवैशैषैसैहैत्रैज्ञैक्षैक़ैख़ैग़ैज़ैझ़ैड़ैढ़ैफ़ैकोखोगोघोङोचोछोजोझोञोटोठोडोढोणोतोथोदोधोनोपोफोबोभोमोयोरोलोवोशोषोसोहोत्रोज्ञोक्षोक़ोख़ोग़ोज़ोझ़ोड़ोढ़ोफ़ोकौखौगौघौङौचौछौजौझौञौटौठौडौढौणौतौथौदौधौनौपौफौबौभौमौयौरौलौवौशौषौसौहौत्रौज्ञौक्षौक़ौख़ौग़ौज़ौझ़ौड़ौढ़ौफ़ौक्ख्ग्घ्ङ्च्छ्ज्झ्ञ्ट्ठ्ड्ढ्ण्त्थ्द्ध्न्प्फ्ब्भ्म्य्र्ल्व्श्ष्स्ह्त्र्ज्ञ्क्ष्क़्ख़्ग़्ज़्झ़्ड़्ढ़्फ़्।॥०१२३४५६७८९॰",
		c.punc
	},
}

m["ho"] = {
	"Hiri Motu",
	33617,
	"crp",
	"Latn",
	ancestors = "meu",
}

m["ht"] = {
	"Haitian Creole",
	33491,
	"crp",
	"Latn",
	ancestors = "ht-sdm",
	sort_key = {
		from = {
			"oun", -- 3 chars
			"an", "ch", "è", "en", "ng", "ò", "on", "ou", "ui" -- 2 chars
		},
		to = {
			"o" .. p[4],
			"a" .. p[1], "c" .. p[1], "e" .. p[1], "e" .. p[2], "n" .. p[1], "o" .. p[1], "o" .. p[2], "o" .. p[3], "u" .. p[1]
		}
	},
}

m["hu"] = {
	"Hungarian",
	9067,
	"urj-ugr",
	"Latn, Hung",
	ancestors = "ohu",
	sort_key = {
		Latn = {
			from = {
				"dzs", -- 3 chars
				"á", "cs", "dz", "é", "gy", "í", "ly", "ny", "ó", "ö", "ő", "sz", "ty", "ú", "ü", "ű", "zs", -- 2 chars
			},
			to = {
				"d" .. p[2],
				"a" .. p[1], "c" .. p[1], "d" .. p[1], "e" .. p[1], "g" .. p[1], "i" .. p[1], "l" .. p[1], "n" .. p[1], "o" .. p[1], "o" .. p[2], "o" .. p[3], "s" .. p[1], "t" .. p[1], "u" .. p[1], "u" .. p[2], "u" .. p[3], "z" .. p[1],
			}
		},
	},
	standardChars = {
		Latn = "AaÁáBbCcDdEeÉéFfGgHhIiÍíJjKkLlMmNnOoÓóÖöŐőPpQqRrSsTtUuÚúÜüŰűVvWwXxYyZz",
		c.punc
	},
}

m["hy"] = {
	"Armenian",
	8785,
	"hyx",
	"Armn, Brai",
	ancestors = "axm",
	translit = {Armn = "Armn-translit"},
	override_translit = true,
	entry_name = {
		Armn = {
			remove_diacritics = "՛՜՞՟",
			from = {"եւ", "<sup>յ</sup>", "<sup>ի</sup>", "<sup>է</sup>"},
			to = {"և", "յ", "ի", "է"}
		},
	},
	sort_key = {
		Armn = {
			from = {
				"ու", "եւ", -- 2 chars
				"և" -- 1 char
			},
			to = {
				"ւ", "եվ",
				"եվ"
			}
		},
	},
}

m["hz"] = {
	"Herero",
	33315,
	"bnt-swb",
	"Latn",
}

m["ia"] = {
	"Interlingua",
	35934,
	"art",
	"Latn",
}

m["id"] = {
	"Indonesian",
	9240,
	"poz-mly",
	"Latn",
	ancestors = "ms",
	standardChars = "AaBbCcDdEeFfGgHhIiJjKkLlMmNnOoPpQqRrSsTtUuVvWwXxYyZz" .. c.punc,
}

m["ie"] = {
	"Interlingue",
	35850,
	"art",
	"Latn",
	type = "appendix-constructed",
	entry_name = {remove_diacritics = c.grave .. c.acute .. c.circ},
}

m["ig"] = {
	"Igbo",
	33578,
	"alv-igb",
	"Latn",
	entry_name = {remove_diacritics = c.grave .. c.acute .. c.macron},
	sort_key = {
		from = {"gb", "gh", "gw", "ị", "kp", "kw", "ṅ", "nw", "ny", "ọ", "sh", "ụ"},
		to = {"g" .. p[1], "g" .. p[2], "g" .. p[3], "i" .. p[1], "k" .. p[1], "k" .. p[2], "n" .. p[1], "n" .. p[2], "n" .. p[3], "o" .. p[1], "s" .. p[1], "u" .. p[1]}
	},
}

m["ii"] = {
	"Nuosu",
	34235,
	"tbq-nlo",
	"Yiii",
	translit = "ii-translit",
}

m["ik"] = {
	"Inupiaq",
	27183,
	"esx-inu",
	"Latn",
	sort_key = {
		from = {
			"ch", "ġ", "dj", "ḷ", "ł̣", "ñ", "ng", "r̂", "sr", "zr", -- 2 chars
			"ł", "ŋ", "ʼ" -- 1 char
		},
		to = {
			"c" .. p[1], "g" .. p[1], "h" .. p[1], "l" .. p[1], "l" .. p[3], "n" .. p[1], "n" .. p[2], "r" .. p[1], "s" .. p[1], "z" .. p[1],
			"l" .. p[2], "n" .. p[2], "z" .. p[2]
		}
	},
}

m["io"] = {
	"Ido",
	35224,
	"art",
	"Latn",
}

m["is"] = {
	"Icelandic",
	294,
	"gmq-ins",
	"Latn",
	sort_key = {
		from = {"á", "ð", "é", "í", "ó", "ú", "ý", "þ", "æ", "ö"},
		to = {"a" .. p[1], "d" .. p[1], "e" .. p[1], "i" .. p[1], "o" .. p[1], "u" .. p[1], "y" .. p[1], "z" .. p[1], "z" .. p[2], "z" .. p[3]}
	},
	standardChars = "AaÁáBbDdÐðEeÉéFfGgHhIiÍíJjKkLlMmNnOoÓóPpRrSsTtUuÚúVvXxYyÝýÞþÆæÖö" .. c.punc,
}

m["it"] = {
	"Italian",
	652,
	"roa-itd",
	"Latn",
	ancestors = "it-oit",
	sort_key = {remove_diacritics = c.grave .. c.acute .. c.circ .. c.diaer .. c.ringabove},
	standardChars = "AaÀàBbCcDdEeÈèÉéFfGgHhIiÌìLlMmNnOoÒòPpQqRrSsTtUuÙùVvZz" .. c.punc,
}

m["iu"] = {
	"Inuktitut",
	29921,
	"esx-inu",
	"Cans, Latn",
	translit = {Cans = "cr-translit"},
	override_translit = true,
}

m["ja"] = {
	"Japanese",
	5287,
	"jpx",
	"Jpan, Latn, Brai",
	ancestors = "ja-ear",
	translit = s["Jpan-translit"],
	link_tr = true,
	sort_key = s["Jpan-sortkey"],
}
m.ja.sort_key.Latn = {remove_diacritics = c.tilde .. c.macron .. c.diaer}

m["jv"] = {
	"Javanese",
	33549,
	"poz-sus",
	"Latn, Java",
	ancestors = "kaw",
	translit = {Java = "jv-translit"},
	link_tr = true,
	entry_name = {remove_diacritics = c.circ}, -- Modern jv don't use ê
	sort_key = {
		Latn = {
			from = {"å", "dh", "é", "è", "ng", "ny", "th"},
			to = {"a" .. p[1], "d" .. p[1], "e" .. p[1], "e" .. p[2], "n" .. p[1], "n" .. p[2], "t" .. p[1]}
		},
	},
}

m["ka"] = {
	"Georgian",
	8108,
	"ccs-gzn",
	"Geor, Geok, Hebr", -- Hebr is used to write Judeo-Georgian
	ancestors = "ka-mid",
	translit = {
		Geor = "Geor-translit",
		Geok = "Geok-translit",
	},
	override_translit = true,
	entry_name = {remove_diacritics = c.circ},
}

m["kg"] = {
	"Kongo",
	33702,
	"bnt-kng",
	"Latn",
}

m["ki"] = {
	"Kikuyu",
	33587,
	"bnt-kka",
	"Latn",
}

m["kj"] = {
	"Kwanyama",
	1405077,
	"bnt-ova",
	"Latn",
}

m["kk"] = {
	"Kazakh",
	9252,
	"trk-kno",
	"Cyrl, Latn, kk-Arab",
	translit = {
		Cyrl = {
			from = {
				"Ё", "ё", "Й", "й", "Нг", "нг", "Ӯ", "ӯ", -- 2 chars; are "Ӯ" and "ӯ" actually used?
				"А", "а", "Ә", "ә", "Б", "б", "В", "в", "Г", "г", "Ғ", "ғ", "Д", "д", "Е", "е", "Ж", "ж", "З", "з", "И", "и", "К", "к", "Қ", "қ", "Л", "л", "М", "м", "Н", "н", "Ң", "ң", "О", "о", "Ө", "ө", "П", "п", "Р", "р", "С", "с", "Т", "т", "У", "у", "Ұ", "ұ", "Ү", "ү", "Ф", "ф", "Х", "х", "Һ", "һ", "Ц", "ц", "Ч", "ч", "Ш", "ш", "Щ", "щ", "Ъ", "ъ", "Ы", "ы", "І", "і", "Ь", "ь", "Э", "э", "Ю", "ю", "Я", "я", -- 1 char
			},
			to = {
				"E", "e", "İ", "i", "Ñ", "ñ", "U", "u",
				"A", "a", "Ä", "ä", "B", "b", "V", "v", "G", "g", "Ğ", "ğ", "D", "d", "E", "e", "J", "j", "Z", "z", "İ", "i", "K", "k", "Q", "q", "L", "l", "M", "m", "N", "n", "Ñ", "ñ", "O", "o", "Ö", "ö", "P", "p", "R", "r", "S", "s", "T", "t", "U", "u", "Ū", "ū", "Ü", "ü", "F", "f", "X", "x", "H", "h", "S", "s", "Ç", "ç", "Ş", "ş", "Ş", "ş", "", "", "Y", "y", "I", "ı", "", "", "É", "é", "Ü", "ü", "Ä", "ä",
			}
		}
	},
--	override_translit = true,
	sort_key = {
		Cyrl = {
			from = {"ә", "ғ", "ё", "қ", "ң", "ө", "ұ", "ү", "һ", "і"},
			to = {"а" .. p[1], "г" .. p[1], "е" .. p[1], "к" .. p[1], "н" .. p[1], "о" .. p[1], "у" .. p[1], "у" .. p[2], "х" .. p[1], "ы" .. p[1]}
		},
	},
	standardChars = {
		Cyrl = "АаӘәБбВвГгҒғДдЕеЁёЖжЗзИиЙйКкҚқЛлМмНнҢңОоӨөПпРрСсТтУуҰұҮүФфХхҺһЦцЧчШшЩщЪъЫыІіЬьЭэЮюЯя",
		c.punc
	},
}

m["kl"] = {
	"Greenlandic",
	25355,
	"esx-inu",
	"Latn",
	sort_key = {
		from = {"æ", "ø", "å"},
		to = {"z" .. p[1], "z" .. p[2], "z" .. p[3]}
	}
}

m["km"] = {
	"Khmer",
	9205,
	"mkh-kmr",
	"Khmr",
	ancestors = "xhm",
	translit = "km-translit",
}

m["kn"] = {
	"Kannada",
	33673,
	"dra-kan",
	"Knda, Tutg",
	ancestors = "dra-mkn",
	translit = "kn-translit",
}

m["ko"] = {
	"Korean",
	9176,
	"qfa-kor",
	"Kore, Brai",
	ancestors = "ko-ear",
	translit = {Kore = "ko-translit"},
	entry_name = {Kore = s["Kore-entryname"]},
}

m["kr"] = {
	"Kanuri",
	36094,
	"ssa-sah",
	"Latn, Arab",
	entry_name = {Latn = {remove_diacritics = c.grave .. c.acute .. c.circ .. c.breve}}, -- the sortkey and entry_name are only for standard Kanuri; when dialectal entries get added, someone will have to work out how the dialects should be represented orthographically
	sort_key = {
		Latn = {
			from = {"ǝ", "ny", "ɍ", "sh"},
			to = {"e" .. p[1], "n" .. p[1], "r" .. p[1], "s" .. p[1]}
		},
	},
}

m["ks"] = {
	"Kashmiri",
	33552,
	"inc-kas",
	"ks-Arab, Deva, Shrd, Latn",
	translit = {
		["ks-Arab"] = "ks-Arab-translit",
		Deva = "ks-Deva-translit",
		Shrd = "Shrd-translit",
	},
}

-- "kv" IS TREATED AS "koi", "kpv", SEE WT:LT

m["kw"] = {
	"Cornish",
	25289,
	"cel-brs",
	"Latn",
	ancestors = "cnx",
	sort_key = {
		from = {"ch"},
		to = {"c" .. p[1]}
	},
}

m["ky"] = {
	"Kyrgyz",
	9255,
	"trk-kkp",
	"Cyrl, Latn, Arab",
	translit = {Cyrl = "ky-translit"},
	override_translit = true,
	sort_key = {
		Cyrl = {
			from = {"ё", "ң", "ө", "ү"},
			to = {"е" .. p[1], "н" .. p[1], "о" .. p[1], "у" .. p[1]}
		},
	},
}

m["la"] = {
	"Latin",
	397,
	"itc",
	"Latn, Ital",
	ancestors = "itc-ola",
	entry_name = {Latn = {remove_diacritics = c.macron .. c.breve .. c.diaer .. c.dinvbreve}},
	sort_key = {
		Latn = {
			from = {"æ", "œ"},
			to = {"ae", "oe"}
		},
	},
	standardChars = {
		Latn = "AaBbCcDdEeFfGgHhIiLlMmNnOoPpQqRrSsTtUuVvXxZz",
		c.punc
	},
}

m["lb"] = {
	"Luxembourgish",
	9051,
	"gmw-hgm",
	"Latn",
	ancestors = "gmw-cfr",
	sort_key = {
		from = {"ä", "ë", "é"},
		to = {"z" .. p[1], "z" .. p[2], "z" .. p[3]}
	},
}

m["lg"] = {
	"Luganda",
	33368,
	"bnt-nyg",
	"Latn",
	entry_name = {remove_diacritics = c.acute .. c.circ},
	sort_key = {
		from = {"ŋ"},
		to = {"n" .. p[1]}
	},
}

m["li"] = {
	"Limburgish",
	102172,
	"gmw-frk",
	"Latn",
	ancestors = "dum",
}

m["ln"] = {
	"Lingala",
	36217,
	"bnt-bmo",
	"Latn",
	sort_key = {
		remove_diacritics = c.acute .. c.circ .. c.caron,
		from = {"ɛ", "gb", "mb", "mp", "nd", "ng", "nk", "ns", "nt", "ny", "nz", "ɔ"},
		to = {"e" .. p[1], "g" .. p[1], "m" .. p[1], "m" .. p[2], "n" .. p[1], "n" .. p[2], "n" .. p[3], "n" .. p[4], "n" .. p[5], "n" .. p[6], "n" .. p[7], "o" .. p[1]}
	},
}

m["lo"] = {
	"Lao",
	9211,
	"tai-swe",
	"Laoo",
	translit = "lo-translit",
	sort_key = "Laoo-sortkey",
	standardChars = "0-9ກຂຄງຈຊຍດຕຖທນບປຜຝພຟມຢຣລວສຫອຮຯ-ໝ" .. c.punc,
}

m["lt"] = {
	"Lithuanian",
	9083,
	"bat-eas",
	"Latn",
	ancestors = "olt",
	entry_name = {remove_diacritics = c.grave .. c.acute .. c.tilde},
	sort_key = {
		from = {"ą", "č", "ę", "ė", "į", "y", "š", "ų", "ū", "ž"},
		to = {"a" .. p[1], "c" .. p[1], "e" .. p[1], "e" .. p[2], "i" .. p[1], "i" .. p[2], "s" .. p[1], "u" .. p[1], "u" .. p[2], "z" .. p[1]}
	},
	standardChars = "AaĄąBbCcČčDdEeĘęĖėFfGgHhIiĮįYyJjKkLlMmNnOoPpRrSsŠšTtUuŲųŪūVvZzŽž" .. c.punc,
}

m["lu"] = {
	"Luba-Katanga",
	36157,
	"bnt-lub",
	"Latn",
}

m["lv"] = {
	"Latvian",
	9078,
	"bat-eas",
	"Latn",
	entry_name = {
		-- This attempts to convert vowels with tone marks to vowels either with or without macrons. Specifically, there should be no macrons if the vowel is part of a diphthong (including resonant diphthongs such pìrksts -> pirksts not #pīrksts). What we do is first convert the vowel + tone mark to a vowel + tilde in a decomposed fashion, then remove the tilde in diphthongs, then convert the remaining vowel + tilde sequences to macroned vowels, then delete any other tilde. We leave already-macroned vowels alone: Both e.g. ar and ār occur before consonants. FIXME: This still might not be sufficient.
		from = {"([Ee])" .. c.cedilla, "[" .. c.grave .. c.circ .. c.tilde .."]", "([aAeEiIoOuU])" .. c.tilde .."?([lrnmuiLRNMUI])" .. c.tilde .. "?([^aAeEiIoOuU])", "([aAeEiIoOuU])" .. c.tilde .."?([lrnmuiLRNMUI])" .. c.tilde .."?$", "([iI])" .. c.tilde .. "?([eE])" .. c.tilde .. "?", "([aAeEiIuU])" .. c.tilde, c.tilde},
		to = {"%1", c.tilde, "%1%2%3", "%1%2", "%1%2", "%1" .. c.macron}
	},
	sort_key = {
		from = {"ā", "č", "ē", "ģ", "ī", "ķ", "ļ", "ņ", "š", "ū", "ž"},
		to = {"a" .. p[1], "c" .. p[1], "e" .. p[1], "g" .. p[1], "i" .. p[1], "k" .. p[1], "l" .. p[1], "n" .. p[1], "s" .. p[1], "u" .. p[1], "z" .. p[1]}
	},
	standardChars = "AaĀāBbCcČčDdEeĒēFfGgĢģHhIiĪīJjKkĶķLlĻļMmNnŅņOoPpRrSsŠšTtUuŪūVvZzŽž" .. c.punc,
}

m["mg"] = {
	"Malagasy",
	7930,
	"poz-bre",
	"Latn",
}

m["mh"] = {
	"Marshallese",
	36280,
	"poz-mic",
	"Latn",
	sort_key = {
		from = {"ā", "ļ", "m̧", "ņ", "n̄", "o̧", "ō", "ū"},
		to = {"a" .. p[1], "l" .. p[1], "m" .. p[1], "n" .. p[1], "n" .. p[2], "o" .. p[1], "o" .. p[2], "u" .. p[1]}
	},
}

m["mi"] = {
	"Maori",
	36451,
	"poz-pep",
	"Latn",
	sort_key = {
		remove_diacritics = c.macron,
		from = {"ng", "wh"},
		to = {"z" .. p[1], "z" .. p[2]}
	},
}

m["mk"] = {
	"Macedonian",
	9296,
	"zls",
	"Cyrl, Grek",
	ancestors = "cu",
	translit = "mk-translit",
	entry_name = {
		remove_diacritics = c.acute,
		remove_exceptions = {"Ѓ", "ѓ", "Ќ", "ќ"}
	},
	sort_key = {
		remove_diacritics = c.grave,
		from = {"ѓ", "ѕ", "ј", "љ", "њ", "ќ", "џ"},
		to = {"д" .. p[1], "з" .. p[1], "и" .. p[1], "л" .. p[1], "н" .. p[1], "т" .. p[1], "ч" .. p[1]}
	},
	standardChars = "АаБбВвГгДдЃѓЕеЖжЗзЅѕИиЈјКкЛлЉљМмНнЊњОоПпРрСсТтЌќУуФфХхЦцЧчЏџШш" .. c.punc,
}

m["ml"] = {
	"Malayalam",
	36236,
	"dra-mal",
	"Mlym",
	translit = "ml-translit",
	override_translit = true,
}

m["mn"] = {
	"Mongolian",
	9246,
	"xgn-cen",
	"Cyrl, Mong, Latn, Brai",
	ancestors = "cmg",
	translit = {
		Cyrl = "mn-translit",
		Mong = "Mong-translit",
	},
	override_translit = true,
	display_text = {Mong = s["Mong-displaytext"]},
	entry_name = {
		Cyrl = {remove_diacritics = c.grave .. c.acute},
		Mong = s["Mong-entryname"],
	},
	sort_key = {
		Cyrl = {
			remove_diacritics = c.grave,
			from = {"ё", "ө", "ү"},
			to = {"е" .. p[1], "о" .. p[1], "у" .. p[1]}
		},
	},
	standardChars = {
		Cyrl = "АаБбВвГгДдЕеЁёЖжЗзИиЙйЛлМмНнОоӨөРрСсТтУуҮүХхЦцЧчШшЫыЬьЭэЮюЯя—",
		Brai = c.braille,
		c.punc
	},
}

-- "mo" IS TREATED AS "ro", SEE WT:LT

m["mr"] = {
	"Marathi",
	1571,
	"inc-sou",
	"Deva, Modi",
	ancestors = "omr",
	translit = {
		Deva = "mr-translit",
		Modi = "mr-Modi-translit",
	},
	entry_name = {
		Deva = {
			from = {"च़", "ज़", "झ़"},
			to = {"च", "ज", "झ"}
		},
	},
}

m["ms"] = {
	"Malay",
	9237,
	"poz-mly",
	"Latn, ms-Arab",
	ancestors = "ms-cla",
	standardChars = {
		Latn = "AaBbCcDdEeFfGgHhIiJjKkLlMmNnOoPpQqRrSsTtUuVvWwXxYyZz",
		c.punc
	},
}

m["mt"] = {
	"Maltese",
	9166,
	"sem-arb",
	"Latn",
	display_text = {
		from = {"'"},
		to = {"’"}
	},
	entry_name = {
		from = {"’"},
		to = {"'"},
	},
	ancestors = "sqr",
	sort_key = {
		from = {
			"ċ", "ġ", "ż", -- Convert into PUA so that decomposed form does not get caught by the next step.
			"([cgz])", -- Ensure "c" comes after "ċ", "g" comes after "ġ" and "z" comes after "ż".
			"g" .. p[1] .. "ħ", -- "għ" after initial conversion of "g".
			p[3], p[4], "ħ", "ie", p[5] -- Convert "ċ", "ġ", "ħ", "ie", "ż" into final output.
		},
		to = {
			p[3], p[4], p[5],
			"%1" .. p[1],
			"g" .. p[2],
			"c", "g", "h" .. p[1], "i" .. p[1], "z"
		}
	},
}

m["my"] = {
	"Burmese",
	9228,
	"tbq-brm",
	"Mymr",
	ancestors = "obr",
	translit = "my-translit",
	override_translit = true,
	sort_key = {
		from = {"ျ", "ြ", "ွ", "ှ", "ဿ"},
		to = {"္ယ", "္ရ", "္ဝ", "္ဟ", "သ္သ"}
	},
}

m["na"] = {
	"Nauruan",
	13307,
	"poz-mic",
	"Latn",
}

m["nb"] = {
	"Norwegian Bokmål",
	25167,
	"gmq",
	"Latn",
	wikimedia_codes = "no",
	ancestors = "gmq-mno, da",
	sort_key = s["no-sortkey"],
	standardChars = s["no-standardchars"],
}

m["nd"] = {
	"Northern Ndebele",
	35613,
	"bnt-ngu",
	"Latn",
	entry_name = {remove_diacritics = c.grave .. c.acute .. c.circ .. c.macron .. c.caron},
}

m["ne"] = {
	"Nepali",
	33823,
	"inc-pah",
	"Deva, Newa",
	translit = {Deva = "ne-translit"},
}

m["ng"] = {
	"Ndonga",
	33900,
	"bnt-ova",
	"Latn",
}

m["nl"] = {
	"Dutch",
	7411,
	"gmw-frk",
	"Latn, Brai",
	ancestors = "dum",
	sort_key = {remove_diacritics = c.grave .. c.acute .. c.circ .. c.tilde .. c.diaer .. c.ringabove .. c.cedilla .. "'"},
	standardChars = {
		Latn = "AaBbCcDdEeFfGgHhIiJjKkLlMmNnOoPpQqRrSsTtUuVvWwXxYyZz",
		Brai = c.braille,
		c.punc
	},
}

m["nn"] = {
	"Norwegian Nynorsk",
	25164,
	"gmq-wes",
	"Latn",
	ancestors = "gmq-mno",
	entry_name = {
		remove_diacritics = c.grave .. c.acute,
	},
	sort_key = s["no-sortkey"],
	standardChars = s["no-standardchars"],
}

m["no"] = {
	"Norwegian",
	9043,
	"gmq-wes",
	"Latn",
	ancestors = "gmq-mno",
	sort_key = s["no-sortkey"],
	standardChars = s["no-standardchars"],
}

m["nr"] = {
	"Southern Ndebele",
	36785,
	"bnt-ngu",
	"Latn",
	entry_name = {remove_diacritics = c.grave .. c.acute .. c.circ .. c.macron .. c.caron},
}

m["nv"] = {
	"Navajo",
	13310,
	"apa",
	"Latn",
	sort_key = {
		remove_diacritics = c.acute .. c.ogonek,
		from = {
			"chʼ", "tłʼ", "tsʼ", -- 3 chars
			"ch", "dl", "dz", "gh", "hw", "kʼ", "kw", "sh", "tł", "ts", "zh", -- 2 chars
			"ł", "ʼ" -- 1 char
		},
		to = {
			"c" .. p[2], "t" .. p[2], "t" .. p[4],
			"c" .. p[1], "d" .. p[1], "d" .. p[2], "g" .. p[1], "h" .. p[1], "k" .. p[1], "k" .. p[2], "s" .. p[1], "t" .. p[1], "t" .. p[3], "z" .. p[1],
			"l" .. p[1], "z" .. p[2]
		}
	},
}

m["ny"] = {
	"Chichewa",
	33273,
	"bnt-nys",
	"Latn",
	entry_name = {remove_diacritics = c.acute .. c.circ},
	sort_key = {
		from = {"ng'"},
		to = {"ng"}
	},
}

m["oc"] = {
	"Occitan",
	14185,
	"roa-ocr",
	"Latn, Hebr",
	ancestors = "pro",
	sort_key = {
		Latn = {
			remove_diacritics = c.grave .. c.acute .. c.diaer .. c.cedilla,
			from = {"([lns])·h"},
			to = {"%1h"}
		},
	},
}

m["oj"] = {
	"Ojibwe",
	33875,
	"alg",
	"Cans, Latn",
	sort_key = {
		Latn = {
			from = {"aa", "ʼ", "ii", "oo", "sh", "zh"},
			to = {"a" .. p[1], "h" .. p[1], "i" .. p[1], "o" .. p[1], "s" .. p[1], "z" .. p[1]}
		},
	},
}

m["om"] = {
	"Oromo",
	33864,
	"cus-eas",
	"Latn, Ethi",
}

m["or"] = {
	"Odia",
	33810,
	"inc-eas",
	"Orya",
	ancestors = "inc-mor",
	translit = "or-translit",
}

m["os"] = {
	"Ossetian",
	33968,
	"xsc",
	"Cyrl, Geor, Latn",
	ancestors = "oos",
	translit = {
		Cyrl = "os-translit",
		Geor = "Geor-translit",
	},
	override_translit = true,
	display_text = {
		Cyrl = {
			from = {"æ"},
			to = {"ӕ"}
		},
		Latn = {
			from = {"ӕ"},
			to = {"æ"}
		},
	},
	entry_name = {
		Cyrl = {
			remove_diacritics = c.grave .. c.acute,
			from = {"æ"},
			to = {"ӕ"}
		},
		Latn = {
			from = {"ӕ"},
			to = {"æ"}
		},
	},
	sort_key = {
		Cyrl = {
			from = {"ӕ", "гъ", "дж", "дз", "ё", "къ", "пъ", "тъ", "хъ", "цъ", "чъ"},
			to = {"а" .. p[1], "г" .. p[1], "д" .. p[1], "д" .. p[2], "е" .. p[1], "к" .. p[1], "п" .. p[1], "т" .. p[1], "х" .. p[1], "ц" .. p[1], "ч" .. p[1]}
		},
	},
}

m["pa"] = {
	"Punjabi",
	58635,
	"inc-pan",
	"Guru, pa-Arab",
	ancestors = "inc-opa",
	translit = {
		Guru = "Guru-translit",
		["pa-Arab"] = "pa-Arab-translit",
	},
	entry_name = {
		["pa-Arab"] = {
			remove_diacritics = c.fathatan .. c.dammatan .. c.kasratan .. c.fatha .. c.damma .. c.kasra .. c.shadda .. c.sukun .. c.nunghunna,
			from = {"ݨ", "ࣇ"},
			to = {"ن", "ل"}
		},
	},
}

m["pi"] = {
	"Pali",
	36727,
	"inc-mid",
	"Latn, Brah, Deva, Beng, Sinh, Mymr, Thai, Lana, Laoo, Khmr, Cakm",
	ancestors = "sa",
	translit = {
		Brah = "Brah-translit",
		Deva = "sa-translit",
		Beng = "pi-translit",
		Sinh = "si-translit",
		Mymr = "pi-translit",
		Thai = "pi-translit",
		Lana = "pi-translit",
		Laoo = "pi-translit",
		Khmr = "pi-translit",
		Cakm = "Cakm-translit",
	},
	entry_name = {
		Thai = {
			from = {"ึ", u(0xF700), u(0xF70F)}, -- FIXME: Not clear what's going on with the PUA characters here.
			to = {"ิํ", "ฐ", "ญ"}
		},
		remove_diacritics = c.VS01
	},
	sort_key = { -- FIXME: This needs to be converted into the current standardized format.
		from = {"ā", "ī", "ū", "ḍ", "ḷ", "m[" .. c.dotabove .. c.dotbelow .. "]", "ṅ", "ñ", "ṇ", "ṭ", "([เโ])([ก-ฮ])", "([ເໂ])([ກ-ຮ])", "ᩔ", "ᩕ", "ᩖ", "ᩘ", "([ᨭ-ᨱ])ᩛ", "([ᨷ-ᨾ])ᩛ", "ᩤ", u(0xFE00), u(0x200D)},
		to = {"a~", "i~", "u~", "d~", "l~", "m~", "n~", "n~~", "n~~~", "t~", "%2%1", "%2%1", "ᩈ᩠ᩈ", "᩠ᩁ", "᩠ᩃ", "ᨦ᩠", "%1᩠ᨮ", "%1᩠ᨻ", "ᩣ"}
	},
}

m["pl"] = {
	"Polish",
	809,
	"zlw-lch",
	"Latn",
	ancestors = "zlw-mpl",
	sort_key = {
		from = {"ą", "ć", "ę", "ł", "ń", "ó", "ś", "ź", "ż"},
		to = {"a" .. p[1], "c" .. p[1], "e" .. p[1], "l" .. p[1], "n" .. p[1], "o" .. p[1], "s" .. p[1], "z" .. p[1], "z" .. p[2]}
	},
	standardChars = "AaĄąBbCcĆćDdEeĘęFfGgHhIiJjKkLlŁłMmNnŃńOoÓóPpRrSsŚśTtUuWwYyZzŹźŻż" .. c.punc,
}

m["ps"] = {
	"Pashto",
	58680,
	"ira-pat",
	"ps-Arab",
	entry_name = {remove_diacritics = c.fathatan .. c.dammatan .. c.kasratan .. c.fatha .. c.damma .. c.kasra .. c.shadda .. c.sukun .. c.superalef},
}

m["pt"] = {
	"Portuguese",
	5146,
	"roa-ibe",
	"Latn, Brai",
	ancestors = "roa-opt",
	sort_key = {Latn = {remove_diacritics = c.grave .. c.acute .. c.circ .. c.tilde .. c.diaer .. c.cedilla}},
	standardChars = {
		Latn = "AaÁáÂâÃãBbCcÇçDdEeÉéÊêFfGgHhIiÍíJjLlMmNnOoÓóÔôÕõPpQqRrSsTtUuÚúVvXxZz",
		Brai = c.braille,
		c.punc
	},
}

m["qu"] = {
	"Quechua",
	5218,
	"qwe",
	"Latn",
}

m["rm"] = {
	"Romansch",
	13199,
	"roa-rhe",
	"Latn",
	sort_key = {remove_diacritics = c.grave .. c.acute .. c.circ .. c.diaer .. c.small_e},
}

m["ro"] = {
	"Romanian",
	7913,
	"roa-eas",
	"Latn, Cyrl, Cyrs",
	translit = {Cyrl = "ro-translit"},
	sort_key = {
		Latn = {
			remove_diacritics = c.grave .. c.acute,
			from = {"ă", "â", "î", "ș", "ț"},
			to = {"a" .. p[1], "a" .. p[2], "i" .. p[1], "s" .. p[1], "t" .. p[1]}
		},
		Cyrl = {
			from = {"ӂ"},
			to = {"ж" .. p[1]}
		},
	},
	standardChars = {
		Latn = "AaĂăÂâBbCcDdEeFfGgHhIiÎîJjLlMmNnOoPpRrSsȘșTtȚțUuVvXxZz",
		Cyrl = "АаБбВвГгДдЕеЖжӁӂЗзИиЙйКкЛлМмНнОоПпРрСсТтУуФфХхЦцЧчШшЫыЬьЭэЮюЯя",
		c.punc
	},
}

m["ru"] = {
	"Russian",
	7737,
	"zle",
	"Cyrl, Cyrs, Brai",
	ancestors = "zle-mru",
	translit = {
		Cyrl = "ru-translit",
		Cyrs = "ru-translit",
	},
	display_text = {
		from = {"'"},
		to = {"’"}
	},
	entry_name = {
		remove_diacritics = c.grave .. c.acute .. c.diaer,
		remove_exceptions = {"Ё", "ё", "Ѣ̈", "ѣ̈", "Я̈", "я̈"},
		from = {"’"},
		to = {"'"},
	},
	sort_key = {
		from = {
			"ё", "ѣ̈", "я̈", -- 2 chars
			"і", "ѣ", "ѳ", "ѵ" -- 1 char
		},
		to = {
			"е" .. p[1], "ь" .. p[2], "я" .. p[1],
			"и" .. p[1], "ь" .. p[1], "я" .. p[2], "я" .. p[3]
		}
	},
	standardChars = {
		Cyrl = "АаБбВвГгДдЕеЁёЖжЗзИиЙйКкЛлМмНнОоПпРрСсТтУуФфХхЦцЧчШшЩщЪъЫыЬьЭэЮюЯя—",
		Brai = c.braille,
		(c.punc:gsub("'", "")) -- Exclude apostrophe.
	},
}

m["rw"] = {
	"Rwanda-Rundi",
	3217514,
	"bnt-glb",
	"Latn",
	entry_name = {remove_diacritics = c.acute .. c.circ .. c.macron .. c.caron},
}

m["sa"] = {
	"Sanskrit",
	11059,
	"inc-old",
	"as-Beng, Bali, Beng, Bhks, Brah, Mymr, xwo-Mong, Deva, Gujr, Guru, Gran, Hani, Java, Kthi, Knda, Kawi, Khar, Khmr, Laoo, Mlym, mnc-Mong, Marc, Modi, Mong, Nand, Newa, Orya, Phag, Ranj, Saur, Shrd, Sidd, Sinh, Soyo, Lana, Takr, Taml, Tang, Telu, Thai, Tibt, Tutg, Tirh, Zanb", --script codes sorted by canonical name rather than code for [[MOD:sa-convert]]
	translit = {
		Beng = "sa-Beng-translit",
		["as-Beng"] = "sa-Beng-translit",
		Brah = "Brah-translit",
		Deva = "sa-translit",
		Gujr = "sa-Gujr-translit",
		Java = "sa-Java-translit",
		Khmr = "pi-translit",
		Knda = "sa-Knda-translit",
		Lana = "pi-translit",
		Laoo = "pi-translit",
		Mlym = "sa-Mlym-translit",
		Modi = "sa-Modi-translit",
		Mong = "Mong-translit",
		["mnc-Mong"] = "mnc-translit",
		["xwo-Mong"] = "xal-translit",
		Mymr = "pi-translit",
		Orya = "sa-Orya-translit",
		Sinh = "si-translit",
		Taml = "sa-Taml-translit",
		Telu = "sa-Telu-translit",
		Thai = "pi-translit",
		Tibt = "Tibt-translit",
	},
	display_text = {
		Mong = s["Mong-displaytext"],
		Tibt = s["Tibt-displaytext"],
	},
	entry_name = {
		Mong = s["Mong-entryname"],
		Tibt = s["Tibt-entryname"],
		Thai = {
			from = {"ึ", u(0xF700), u(0xF70F)}, -- FIXME: Not clear what's going on with the PUA characters here.
			to = {"ิํ", "ฐ", "ญ"}
		},
		remove_diacritics = c.VS01
	},
	sort_key = {
		Tibt = "Tibt-sortkey",
		{ -- FIXME: This needs to be converted into the current standardized format.
			from = {"ā", "ī", "ū", "ḍ", "ḷ", "ḹ", "m[" .. c.dotabove .. c.dotbelow .. "]", "ṅ", "ñ", "ṇ", "ṛ", "ṝ", "ś", "ṣ", "ṭ", "([เโไ])([ก-ฮ])", "([ເໂໄ])([ກ-ຮ])", "ᩔ", "ᩕ", "ᩖ", "ᩘ", "([ᨭ-ᨱ])ᩛ", "([ᨷ-ᨾ])ᩛ", "ᩤ", u(0xFE00), u(0x200D)},
			to = {"a~", "i~", "u~", "d~", "l~", "l~~", "m~", "n~", "n~~", "n~~~", "r~", "r~~", "s~", "s~~", "t~", "%2%1", "%2%1", "ᩈ᩠ᩈ", "᩠ᩁ", "᩠ᩃ", "ᨦ᩠", "%1᩠ᨮ", "%1᩠ᨻ", "ᩣ"},
		},
	},
}

m["sc"] = {
	"Sardinian",
	33976,
	"roa",
	"Latn",
}

m["sd"] = {
	"Sindhi",
	33997,
	"inc-snd",
	"sd-Arab, Deva, Sind, Khoj",
	translit = {Sind = "Sind-translit"},
	entry_name = {
		["sd-Arab"] = {
			remove_diacritics = c.kashida .. c.fathatan .. c.dammatan .. c.kasratan .. c.fatha .. c.damma .. c.kasra .. c.shadda .. c.sukun .. c.superalef,
			from = {"ٱ"},
			to = {"ا"}
		},
	},
}

m["se"] = {
	"Northern Sami",
	33947,
	"smi",
	"Latn",
	display_text = {
		from = {"'"},
		to = {"ˈ"}
	},
	entry_name = {remove_diacritics = c.macron .. c.dotbelow .. "'ˈ"},
	sort_key = {
		from = {"á", "č", "đ", "ŋ", "š", "ŧ", "ž"},
		to = {"a" .. p[1], "c" .. p[1], "d" .. p[1], "n" .. p[1], "s" .. p[1], "t" .. p[1], "z" .. p[1]}
	},
	standardChars = "AaÁáBbCcČčDdĐđEeFfGgHhIiJjKkLlMmNnŊŋOoPpRrSsŠšTtŦŧUuVvZzŽž" .. c.punc,
}

m["sg"] = {
	"Sango",
	33954,
	"crp",
	"Latn",
	ancestors = "ngb",
}

m["sh"] = {
	"Serbo-Croatian",
	9301,
	"zls",
	"Latn, Cyrl, Glag",
	wikimedia_codes = "sh, bs, hr, sr",
	entry_name = {
		Latn = {
			remove_diacritics = c.grave .. c.acute .. c.tilde .. c.macron .. c.dgrave .. c.invbreve,
			remove_exceptions = {"Ć", "ć", "Ś", "ś", "Ź", "ź"}
		},
		Cyrl = {
			remove_diacritics = c.grave .. c.acute .. c.tilde .. c.macron .. c.dgrave .. c.invbreve,
			remove_exceptions = {"З́", "з́", "С́", "с́"}
		},
	},
	sort_key = {
		Latn = {
			from = {"č", "ć", "dž", "đ", "lj", "nj", "š", "ś", "ž", "ź"},
			to = {"c" .. p[1], "c" .. p[2], "d" .. p[1], "d" .. p[2], "l" .. p[1], "n" .. p[1], "s" .. p[1], "s" .. p[2], "z" .. p[1], "z" .. p[2]}
		},
		Cyrl = {
			from = {"ђ", "з́", "ј", "љ", "њ", "с́", "ћ", "џ"},
			to = {"д" .. p[1], "з" .. p[1], "и" .. p[1], "л" .. p[1], "н" .. p[1], "с" .. p[1], "т" .. p[1], "ч" .. p[1]}
		},
	},
	standardChars = {
		Latn = "AaBbCcČčĆćDdĐđEeFfGgHhIiJjKkLlMmNnOoPpRrSsŠšTtUuVvZzŽž",
		Cyrl = "АаБбВвГгДдЂђЕеЖжЗзИиЈјКкЛлЉљМмНнЊњОоПпРрСсТтЋћУуФфХхЦцЧчЏџШш",
		c.punc
	},
}

m["si"] = {
	"Sinhalese",
	13267,
	"inc-ins",
	"Sinh",
	translit = "si-translit",
	override_translit = true,
}

m["sk"] = {
	"Slovak",
	9058,
	"zlw",
	"Latn",
	ancestors = "zlw-osk",
	sort_key = {remove_diacritics = c.acute .. c.circ .. c.diaer},
	standardChars = "AaÁáÄäBbCcČčDdĎďEeFfGgHhIiÍíJjKkLlĹĺĽľMmNnŇňOoÔôPpRrŔŕSsŠšTtŤťUuÚúVvYyÝýZzŽž" .. c.punc,
}

m["sl"] = {
	"Slovene",
	9063,
	"zls",
	"Latn",
	entry_name = {
		remove_diacritics = c.grave .. c.acute .. c.circ .. c.macron .. c.dgrave .. c.invbreve .. c.dotbelow,
		from = {"Ə", "ə", "Ł", "ł"},
		to = {"E", "e", "L", "l"}
	},
	sort_key = {
		remove_diacritics = c.tilde .. c.dotabove .. c.diaer .. c.ringabove .. c.ringbelow .. c.ogonek,
		from = {"č", "š", "ž"},
		to = {"c" .. p[1], "s" .. p[1], "z" .. p[1]}
	},
	standardChars = "AaBbCcČčDdEeFfGgHhIiJjKkLlMmNnOoPpRrSsŠšTtUuVvZzŽž" .. c.punc,
}

m["sm"] = {
	"Samoan",
	34011,
	"poz-pnp",
	"Latn",
}

m["sn"] = {
	"Shona",
	34004,
	"bnt-sho",
	"Latn",
	entry_name = {remove_diacritics = c.acute},
}

m["so"] = {
	"Somali",
	13275,
	"cus-som",
	"Latn, Arab, Osma",
	entry_name = {Latn = {remove_diacritics = c.grave .. c.acute .. c.circ}},
}

m["sq"] = {
	"Albanian",
	8748,
	"sqj",
	"Latn, Grek, ota-Arab, Elba, Todr, Vith",
	entry_name = {Latn = {
		remove_diacritics = c.acute,
		from = {'^i (%w)', '^të (%w)'}, to = {'%1', '%1'},
	}},
	sort_key = {Latn = {
		remove_diacritics = c.acute .. c.circ .. c.tilde .. c.breve .. c.caron,
		from = {'ç', 'dh', 'ë', 'gj', 'll', 'nj', 'rr', 'sh', 'th', 'xh', 'zh'},
		to = {'c'..p[1], 'd'..p[1], 'e'..p[1], 'g'..p[1], 'l'..p[1], 'n'..p[1], 'r'..p[1], 's'..p[1], 't'..p[1], 'x'..p[1], 'z'..p[1]},
	}},
	standardChars = "AaBbCcÇçDdEeËëFfGgHhIiJjKkLlMmNnOoPpQqRrSsTtUuVvXxYyZz" .. c.punc,
}

m["ss"] = {
	"Swazi",
	34014,
	"bnt-ngu",
	"Latn",
	entry_name = {remove_diacritics = c.grave .. c.acute .. c.circ .. c.macron .. c.caron},
}

m["st"] = {
	"Sotho",
	34340,
	"bnt-sts",
	"Latn",
	entry_name = {remove_diacritics = c.grave .. c.acute .. c.circ .. c.macron .. c.caron},
}

m["su"] = {
	"Sundanese",
	34002,
	"poz-msa",
	"Latn, Sund",
	ancestors = "osn",
	translit = {Sund = "su-translit"},
}

m["sv"] = {
	"Swedish",
	9027,
	"gmq-eas",
	"Latn",
	ancestors = "gmq-osw-lat",
	sort_key = {
		remove_diacritics = c.grave .. c.acute .. c.circ .. c.tilde .. c.macron .. c.dacute .. c.caron .. c.cedilla .. "':",
		remove_exceptions = {"å"},
		from = {"ø", "æ", "œ", "ß", "å", "aͤ", "oͤ"},
		to = {"o", "ae", "oe", "ss", "z" .. p[1], "ä", "ö"}
	},
	standardChars = "AaBbCcDdEeFfGgHhIiJjKkLlMmNnOoPpRrSsTtUuVvXxYyÅåÄäÖö" .. c.punc,
}

m["sw"] = {
	"Swahili",
	7838,
	"bnt-swh",
	"Latn, Arab",
	sort_key = {
		Latn = {
			from = {"ng'"},
			to = {"ng" .. p[1]}
		},
	},
}

m["ta"] = {
	"Tamil",
	5885,
	"dra-tam",
	"Taml",
	ancestors = "ta-mid",
	translit = "ta-translit",
	override_translit = true,
}

m["te"] = {
	"Telugu",
	8097,
	"dra-tel",
	"Telu",
	translit = "te-translit",
	override_translit = true,
}

m["tg"] = {
	"Tajik",
	9260,
	"ira-swi",
	"Cyrl, fa-Arab, Latn",
	ancestors = "fa-cls",
	translit = {Cyrl = "tg-translit"},
	override_translit = true,
	entry_name = {remove_diacritics = c.grave .. c.acute},
	sort_key = {
		Cyrl = {
			from = {"ғ", "ё", "ӣ", "қ", "ӯ", "ҳ", "ҷ"},
			to = {"г" .. p[1], "е" .. p[1], "и" .. p[1], "к" .. p[1], "у" .. p[1], "х" .. p[1], "ч" .. p[1]}
		},
	},
}

m["th"] = {
	"Thai",
	9217,
	"tai-swe",
	"Thai, Brai",
	translit = {Thai = "th-translit"},
	sort_key = {Thai = "Thai-sortkey"},
}

m["ti"] = {
	"Tigrinya",
	34124,
	"sem-eth",
	"Ethi",
	translit = "Ethi-translit",
}

m["tk"] = {
	"Turkmen",
	9267,
	"trk-ogz",
	"Latn, Cyrl, Arab",
	entry_name = {remove_diacritics = c.macron},
	sort_key = {
		Latn = {
			from = {"ç", "ä", "ž", "ň", "ö", "ş", "ü", "ý"},
			to = {"c" .. p[1], "e" .. p[1], "j" .. p[1], "n" .. p[1], "o" .. p[1], "s" .. p[1], "u" .. p[1], "y" .. p[1]}
		},
		Cyrl = {
			from = {"ё", "җ", "ң", "ө", "ү", "ә"},
			to = {"е" .. p[1], "ж" .. p[1], "н" .. p[1], "о" .. p[1], "у" .. p[1], "э" .. p[1]}
		},
	},
}

m["tl"] = {
	"Tagalog",
	34057,
	"phi",
	"Latn, Tglg",
	translit = {Tglg = "tl-translit"},
	override_translit = true,
	entry_name = {Latn = {remove_diacritics = c.grave .. c.acute .. c.circ}},
	standardChars = {
		Latn = "AaBbKkDdEeGgHhIiLlMmNnOoPpRrSsTtUuWwYy",
		c.punc
	},
	sort_key = {
		Latn = "tl-sortkey",
	},
}

m["tn"] = {
	"Tswana",
	34137,
	"bnt-sts",
	"Latn",
}

m["to"] = {
	"Tongan",
	34094,
	"poz-pol",
	"Latn",
	entry_name = {remove_diacritics = c.acute},
	sort_key = {remove_diacritics = c.macron},
}

m["tr"] = {
	"Turkish",
	256,
	"trk-ogz",
	"Latn",
	ancestors = "ota",
	dotted_dotless_i = true,
	sort_key = {
		from = {
			-- Ignore circumflex, but account for capital Î wrongly becoming ı + circ due to dotted dotless I logic.
			"ı" .. c.circ, c.circ,
			"i", -- Ensure "i" comes after "ı".
			"ç", "ğ", "ı", "ö", "ş", "ü"
		},
		to = {
			"i", "",
			"i" .. p[1],
			"c" .. p[1], "g" .. p[1], "i", "o" .. p[1], "s" .. p[1], "u" .. p[1]
		}
	},
	standardChars = "AaÂâBbCcÇçDdEeFfGgĞğHhIıİiÎîJjKkLlMmNnOoÖöPpRrSsŞşTtUuÛûÜüVvYyZz" .. c.punc,
}

m["ts"] = {
	"Tsonga",
	34327,
	"bnt-tsr",
	"Latn",
}

m["tt"] = {
	"Tatar",
	25285,
	"trk-kbu",
	"Cyrl, Latn, tt-Arab",
	translit = {Cyrl = "tt-translit"},
	override_translit = true,
	dotted_dotless_i = true,
	sort_key = {
		Cyrl = {
			from = {"ә", "ў", "ғ", "ё", "җ", "қ", "ң", "ө", "ү", "һ"},
			to = {"а" .. p[1], "в" .. p[1], "г" .. p[1], "е" .. p[1], "ж" .. p[1], "к" .. p[1], "н" .. p[1], "о" .. p[1], "у" .. p[1], "х" .. p[1]}
		},
		Latn = {
			from = {
				"i", -- Ensure "i" comes after "ı".
				"ä", "ə", "ç", "ğ", "ı", "ñ", "ŋ", "ö", "ɵ", "ş", "ü"
			},
			to = {
				"i" .. p[1],
				"a" .. p[1], "a" .. p[2], "c" .. p[1], "g" .. p[1], "i", "n" .. p[1], "n" .. p[2], "o" .. p[1], "o" .. p[2], "s" .. p[1], "u" .. p[1]
			}
		},
	},
}

-- "tw" IS TREATED AS "ak", SEE WT:LT

m["ty"] = {
	"Tahitian",
	34128,
	"poz-pep",
	"Latn",
}

m["ug"] = {
	"Uyghur",
	13263,
	"trk-kar",
	"ug-Arab, Latn, Cyrl",
	ancestors = "chg",
	translit = {
		["ug-Arab"] = "ug-translit",
		Cyrl = "ug-translit",
	},
	override_translit = true,
}

m["uk"] = {
	"Ukrainian",
	8798,
	"zle",
	"Cyrl",
	ancestors = "zle-ouk",
	translit = "uk-translit",
	entry_name = {remove_diacritics = c.grave .. c.acute},
	sort_key = {
		from = {
			"ї", -- 2 chars
			"ґ", "є", "і" -- 1 char
		},
		to = {
			"и" .. p[2],
			"г" .. p[1], "е" .. p[1], "и" .. p[1]
		}
	},
	standardChars = "АаБбВвГгДдЕеЄєЖжЗзИиІіЇїЙйКкЛлМмНнОоПпРрСсТтУуФфХхЦцЧчШшЩщЬьЮюЯя" .. c.punc:gsub("'", ""),  -- Exclude apostrophe.
}

m["ur"] = {
	"Urdu",
	1617,
	"inc-hnd",
	"ur-Arab,Hebr",
	ancestors = "inc-ohi",
	translit = {["ur-Arab"] = "ur-translit"},
	entry_name = {
		-- character "ۂ" code U+06C2 to "ه" and "هٔ"‎ (U+0647 + U+0654) to "ه"; hamzatu l-waṣli to a regular alif
		from = {"هٔ", "ۂ", "ٱ"},
		to = {"ہ", "ہ", "ا"},
		remove_diacritics = c.fathatan .. c.dammatan .. c.kasratan .. c.fatha .. c.damma .. c.kasra .. c.shadda .. c.sukun .. c.nunghunna .. c.superalef
	},
	-- put Judeo-Urdu (Hebrew-script Urdu) under the category header
	-- U+FB21 HEBREW LETTER WIDE ALEF so that it sorts after Arabic script titles
	sort_key = {
		from = {"^%f[" .. u(0x5D0) .. "-" .. u(0x5EA) .. "]"},
		to = {u(0xFB21)},
	},
}

m["uz"] = {
	"Uzbek",
	9264,
	"trk-kar",
	"Latn, Cyrl, fa-Arab",
	ancestors = "chg",
	translit = {Cyrl = "uz-translit"},
	sort_key = {
		Latn = {
			from = {"oʻ", "gʻ", "sh", "ch", "ng"},
			to = {"z" .. p[1], "z" .. p[2], "z" .. p[3], "z" .. p[4], "z" .. p[5]}
		},
		Cyrl = {
			from = {"ё", "ў", "қ", "ғ", "ҳ"},
			to = {"е" .. p[1], "я" .. p[1], "я" .. p[2], "я" .. p[3], "я" .. p[4]}
		},
	},
}

m["ve"] = {
	"Venda",
	32704,
	"bnt-bso",
	"Latn",
}

m["vi"] = {
	"Vietnamese",
	9199,
	"mkh-vie",
	"Latn, Hani",
	ancestors = "mkh-mvi",
	sort_key = {
		Latn = "vi-sortkey",
		Hani = "Hani-sortkey",
	},
}

m["vo"] = {
	"Volapük",
	36986,
	"art",
	"Latn",
}

m["wa"] = {
	"Walloon",
	34219,
	"roa-oil",
	"Latn",
	sort_key = s["roa-oil-sortkey"],
}

m["wo"] = {
	"Wolof",
	34257,
	"alv-fwo",
	"Latn, Arab, Gara",
}

m["xh"] = {
	"Xhosa",
	13218,
	"bnt-ngu",
	"Latn",
	entry_name = {remove_diacritics = c.grave .. c.acute .. c.circ .. c.macron .. c.caron},
}

m["yi"] = {
	"Yiddish",
	8641,
	"gmw-hgm",
	"Hebr",
	ancestors = "gmh",
	translit = "yi-translit",
	sort_key = {
		from = {"א[ַָ]", "בּ", "ו[ֹּ]", "יִ", "ײַ", "פֿ"},
		to = {"א", "ב", "ו", "י", "יי", "פ"}
	},
}

m["yo"] = {
	"Yoruba",
	34311,
	"alv-yor",
	"Latn, Arab",
	entry_name = {Latn = {remove_diacritics = c.grave .. c.acute .. c.macron}},
	sort_key = {
		Latn = {
			from = {"ẹ", "ɛ", "gb", "ị", "kp", "ọ", "ɔ", "ṣ", "sh", "ụ"},
			to = {"e" .. p[1], "e" .. p[1], "g" .. p[1], "i" .. p[1], "k" .. p[1], "o" .. p[1], "o" .. p[1], "s" .. p[1], "s" .. p[1], "u" .. p[1]}
		},
	},
}

m["za"] = {
	"Zhuang",
	13216,
	"tai",
	"Latn, Hani",
	sort_key = {
		Latn = "za-sortkey",
		Hani = "Hani-sortkey",
	},
}

m["zh"] = {
	"Chinese",
	7850,
	"zhx",
	"Hani, Hant, Hans, Latn, Bopo, Nshu, Brai",
	ancestors = "ltc",
	generate_forms = "zh-generateforms",
	translit = {
		Hani = "zh-translit",
		Bopo = "zh-translit",
	},
	sort_key = {Hani = "Hani-sortkey"},
}

m["zu"] = {
	"Zulu",
	10179,
	"bnt-ngu",
	"Latn",
	entry_name = {remove_diacritics = c.grave .. c.acute .. c.circ .. c.macron .. c.caron},
}

return require("languages").addDefaultTypes(m, true)