local export = {}

local m_IPA = require("IPA")

local lang = require("languages").getByCode("pl")

local letters2phones = {
	["a"] = {
		["u"] = { "a", "w" },
		[false] = "a",
	},
	["ą"] = {
		["l"] = { "ɔ", "l" },
		["ł"] = { "ɔ", "w" },
		[false] = "ɔ̃",
	},
	["b"] = {
		["i"] = {
			["ą"] = {
				["l"] = { "bʲ", "j", "ɔ", "l" },
				["ł"] = { "bʲ", "j", "ɔ", "w" },
				[false] = { "bʲ", "j", "ɔ̃" }
			},
			["ę"] = {
				["l"] = { "bʲ", "j", "ɛ", "l" },
				["ł"] = { "bʲ", "j", "ɛ", "w" },
				[false] = { "bʲ", "j", "ɛ̃" }
			},
			["a"] = { "bʲ", "j", "a" },
			["e"] = { "bʲ", "j", "ɛ" },
			["i"] = { "bʲ", "i" },
			["o"] = { "bʲ", "j", "ɔ" },
			["ó"] = { "bʲ", "j", "u" },
			["u"] = { "bʲ", "j", "u" },
			[false] = { "bʲ", "i" }
		},
		[false] = "b"
	},
	["c"] = {
		["i"] = {
			["ą"] = {
				["l"] = { "t͡ɕ", "ɔ", "l" },
				["ł"] = { "t͡ɕ", "ɔ", "w" },
				[false] = { "t͡ɕ", "ɔ̃" }
			},
			["ę"] = {
				["l"] = { "t͡ɕ", "ɛ", "l" },
				["ł"] = { "t͡ɕ", "ɛ", "w" },
				[false] = { "t͡ɕ", "ɛ̃" }
			},
			["a"] = { "t͡ɕ", "a" },
			["e"] = { "t͡ɕ", "ɛ" },
			["o"] = { "t͡ɕ", "ɔ" },
			["ó"] = { "t͡ɕ", "u" },
			["u"] = { "t͡ɕ", "u" },
			["y"] = { "t͡ɕ", "ɨ" },
			[false] = { "t͡ɕ", "i" }
		},
		["h"] = {
			["i"] = {
				["ą"] = {
					["l"] = { "xʲ", "j", "ɔ", "l" },
					["ł"] = { "xʲ", "j", "ɔ", "w" },
					[false] = { "xʲ", "j", "ɔ̃" }
				},
				["ę"] = {
					["l"] = { "xʲ", "j", "ɛ", "l" },
					["ł"] = { "xʲ", "j", "ɛ", "w" },
					[false] = { "xʲ", "j", "ɛ̃" }
				},
				["a"] = { "xʲ", "j", "a" },
				["e"] = { "xʲ", "j", "ɛ" },
				["i"] = { "xʲ", "j", "i" },
				["o"] = { "xʲ", "j", "ɔ" },
				["ó"] = { "xʲ", "j", "u" },
				["u"] = { "xʲ", "j", "u" },
				[false] = { "xʲ", "i" }
			},
			[false] = "x"
		},
		["z"] = "t͡ʂ",
		[false] = "t͡s"
	},
	["ć"] = "t͡ɕ",
	["d"] = {
		["i"] = {
			["ą"] = {
				["l"] = { "dʲ", "j", "ɔ", "l" },
				["ł"] = { "dʲ", "j", "ɔ", "w" },
				[false] = { "dʲ", "j", "ɔ̃" }
			},
			["ę"] = {
				["l"] = { "dʲ", "j", "ɛ", "l" },
				["ł"] = { "dʲ", "j", "ɛ", "w" },
				[false] = { "dʲ", "j", "ɛ̃" }
			},
			["a"] = { "dʲ", "j", "a" },
			["e"] = { "dʲ", "j", "ɛ" },
			["i"] = { "dʲ", "i" },
			["o"] = { "dʲ", "j", "ɔ" },
			["ó"] = { "dʲ", "j", "u" },
			["u"] = { "dʲ", "j", "u" },
			[false] = { "dʲ", "i" }
		},
		["z"] = {
			["i"] = {
				["ą"] = {
					["l"] = { "d͡ʑ", "ɔ", "l" },
					["ł"] = { "d͡ʑ", "ɔ", "w" },
					[false] = {"d͡ʑ", "ɔ̃" }
				},
				["ę"] = {
					["l"] = { "d͡ʑ", "ɛ", "l" },
					["ł"] = { "d͡ʑ", "ɛ", "w" },
					[false] = { "d͡ʑ", "ɛ̃" }
				},
				["a"] = { "d͡ʑ", "a" },
				["e"] = { "d͡ʑ", "ɛ" },
				["o"] = { "d͡ʑ", "ɔ" },
				["ó"] = { "d͡ʑ", "u" },
				["u"] = { "d͡ʑ", "u" },
				["y"] = { "d͡ʑ", "ɨ" },
				[false] = { "d͡ʑ", "i" }
			},
			[false] = "d͡z"
		},
		["ż"] = "d͡ʐ",
		["ź"] = "d͡ʑ",
		[false] = "d"
	},
	["e"] = {
		["u"] = { "ɛ", "w" },
		[false] = "ɛ",
	},
	["ę"] = {
		["l"] = { "ɛ", "l" },
		["ł"] = { "ɛ", "w" },
		[false] = "ɛ̃",
	},
	["f"] = {
		["i"] = {
			["ą"] = {
				["l"] = { "fʲ", "j", "ɔ", "l" },
				["ł"] = { "fʲ", "j", "ɔ", "w" },
				[false] = { "fʲ", "j", "ɔ̃" }
			},
			["ę"] = {
				["l"] = { "fʲ", "j", "ɛ", "l" },
				["ł"] = { "fʲ", "j", "ɛ", "w" },
				[false] = { "fʲ", "j", "ɛ̃" }
			},
			["a"] = { "fʲ", "j", "a" },
			["e"] = { "fʲ", "j", "ɛ" },
			["i"] = { "fʲ", "j", "i" },
			["o"] = { "fʲ", "j", "ɔ" },
			["ó"] = { "fʲ", "j", "u" },
			["u"] = { "fʲ", "j", "u" },
			[false] = { "fʲ", "i" }
		},
		[false] = "f"
	},
	["g"] = {
		["i"] = {
			["ą"] = {
				["l"] = { "ɡʲ", "j", "ɔ", "l" },
				["ł"] = { "ɡʲ", "j", "ɔ", "w" },
				[false] = { "ɡʲ", "j", "ɔ̃" }
			},
			["ę"] = {
				["l"] = { "ɡʲ", "j", "ɛ", "l" },
				["ł"] = { "ɡʲ", "j", "ɛ", "w" },
				[false] = { "ɡʲ", "j", "ɛ̃" }
			},
			["a"] = { "ɡʲ", "j", "a" },
			["e"] = { "ɡʲ", "j", "ɛ" },
			["i"] = { "ɡʲ", "j", "i" },
			["o"] = { "ɡʲ", "j", "ɔ" },
			["ó"] = { "ɡʲ", "j", "u" },
			["u"] = { "ɡʲ", "j", "u" },
			[false] = { "ɡʲ", "i" }
		},
		[false] = "ɡ"
	},
	["h"] = {
		["i"] = {
			["ą"] = {
				["l"] = { "xʲ", "j", "ɔ", "l" },
				["ł"] = { "xʲ", "j", "ɔ", "w" },
				[false] = { "xʲ", "j", "ɔ̃" }
			},
			["ę"] = {
				["l"] = { "xʲ", "j", "ɛ", "l" },
				["ł"] = { "xʲ", "j", "ɛ", "w" },
				[false] = { "xʲ", "j", "ɛ̃" }
			},
			["a"] = { "xʲ", "j", "a" },
			["e"] = { "xʲ", "j", "ɛ" },
			["i"] = { "xʲ", "j", "i" },
			["o"] = { "xʲ", "j", "ɔ" },
			["ó"] = { "xʲ", "j", "u" },
			["u"] = { "xʲ", "j", "u" },
			[false] = { "xʲ", "i" }
		},
		[false] = "x"
	},
	["i"] = "i",
	["j"] = "j",
	["k"] = {
		["i"] = {
			["ą"] = {
				["l"] = { "kʲ", "j", "ɔ", "l" },
				["ł"] = { "kʲ", "j", "ɔ", "w" },
				[false] = { "kʲ", "j", "ɔ̃" }
			},
			["ę"] = {
				["l"] = { "kʲ", "j", "ɛ", "l" },
				["ł"] = { "kʲ", "j", "ɛ", "w" },
				[false] = { "kʲ", "j", "ɛ̃" }
			},
			["a"] = { "kʲ", "j", "a" },
			["e"] = { "kʲ", "j", "ɛ" },
			["i"] = { "kʲ", "j", "i" },
			["o"] = { "kʲ", "j", "ɔ" },
			["ó"] = { "kʲ", "j", "u" },
			["u"] = { "kʲ", "j", "u" },
			[false] = { "kʲ", "i" }
		},
		[false] = "k"
	},
	["l"] = {
		["i"] = {
			["ą"] = {
				["l"] = { "lʲ", "j", "ɔ", "l" },
				["ł"] = { "lʲ", "j", "ɔ", "w" },
				[false] = { "lʲ", "j", "ɔ̃" }
			},
			["ę"] = {
				["l"] = { "lʲ", "j", "ɛ", "l" },
				["ł"] = { "lʲ", "j", "ɛ", "w" },
				[false] = { "lʲ", "j", "ɛ̃" }
			},
			["a"] = { "lʲ", "j", "a" },
			["e"] = { "lʲ", "j", "ɛ" },
			["i"] = { "lʲ", "j", "i" },
			["o"] = { "lʲ", "j", "ɔ" },
			["ó"] = { "lʲ", "j", "u" },
			["u"] = { "lʲ", "j", "u" },
			[false] = { "lʲ", "i" }
		},
		[false] = "l"
	},
	["ł"] = "w",
	["m"] = {
		["i"] = {
			["ą"] = {
				["l"] = { "mʲ", "j", "ɔ", "l" },
				["ł"] = { "mʲ", "j", "ɔ", "w" },
				[false] = { "mʲ", "j", "ɔ̃" }
			},
			["ę"] = {
				["l"] = { "mʲ", "j", "ɛ", "l" },
				["ł"] = { "mʲ", "j", "ɛ", "w" },
				[false] = { "mʲ", "j", "ɛ̃" }
			},
			["a"] = { "mʲ", "j", "a" },
			["e"] = { "mʲ", "j", "ɛ" },
			["i"] = { "mʲ", "j", "i" },
			["o"] = { "mʲ", "j", "ɔ" },
			["ó"] = { "mʲ", "j", "u" },
			["u"] = { "mʲ", "j", "u" },
			[false] = { "mʲ", "i" }
		},
		[false] = "m"
	},
	["n"] = {
		["k"] = { 
			["i"] = {
				["ą"] = {
					["l"] = { "ŋ", "kʲ", "j", "ɔ", "l" },
					["ł"] = { "ŋ", "kʲ", "j", "ɔ", "w" },
					[false] = { "ŋ", "kʲ", "j", "ɔ̃" }
				},
				["ę"] = {
					["l"] = { "ŋ", "kʲ", "j", "ɛ", "l" },
					["ł"] = { "ŋ", "kʲ", "j", "ɛ", "w" },
					[false] = { "ŋ", "kʲ", "j", "ɛ̃" }
				},
				["a"] = { "ŋ", "kʲ", "j", "a" },
				["e"] = { "ŋ", "kʲ", "j", "ɛ" },
				["i"] = { "ŋ", "kʲ", "j", "i" },
				["o"] = { "ŋ", "kʲ", "j", "ɔ" },
				["ó"] = { "ŋ", "kʲ", "j", "u" },
				["u"] = { "ŋ", "kʲ", "j", "u" },
				[false] = { "ŋ", "kʲ", "i" }
			},
			[false] = { "ŋ", "k" }
		},
		["g"] = {
			["i"] = {
				["ą"] = {
					["l"] = { "ŋ", "ɡʲ", "j", "l" },
					["ł"] = { "ŋ", "ɡʲ", "j", "w" },
					[false] = { "ŋ", "ɡʲ", "j", "ɔ̃" }
				},
				["ę"] = {
					["l"] = { "ŋ", "ɡʲ", "j", "ɛ", "l" },
					["ł"] = { "ŋ", "ɡʲ", "j", "ɛ", "w" },
					[false] = { "ŋ", "ɡʲ", "j", "ɛ̃" }
				},
				["a"] = { "ŋ", "ɡʲ", "j", "a" },
				["e"] = { "ŋ", "ɡʲ", "j", "ɛ" },
				["i"] = { "ŋ", "ɡʲ", "j", "i" },
				["o"] = { "ŋ", "ɡʲ", "j", "ɔ" },
				["ó"] = { "ŋ", "ɡʲ", "j", "u" },
				["u"] = { "ŋ", "ɡʲ", "j", "u" },
				[false] = { "ŋ", "ɡʲ", "i" }
			},
			[false] = { "ŋ", "ɡ" }
		},
		["i"] = {
			["ą"] = {
				["l"] = { "ɲ", "ɔ", "l" },
				["ł"] = { "ɲ", "ɔ", "w" },
				[false] = { "ɲ", "ɔ̃" }
			},
			["ę"] = {
				["l"] = { "ɲ", "ɛ", "l" },
				["ł"] = { "ɲ", "ɛ", "w" },
				[false] = { "ɲ", "ɛ̃" }
			},
			["a"] = { "ɲ", "a" },
			["e"] = { "ɲ", "ɛ" },
			["i"] = { "ɲ", "j", "i" },
			["o"] = { "ɲ", "ɔ" },
			["ó"] = { "ɲ", "u" },
			["u"] = { "ɲ", "u" },
			[false] = { "ɲ", "i" }
		},
		[false] = "n"
	},
	["ń"] = "ɲ",
	["o"] = {
		[false] = "ɔ",
	},
	["ó"] = "u",
	["p"] = {
		["i"] = {
			-- piątek, piasek, etc.
			["ą"] = {
				["l"] = { "pʲ", "j", "ɔ", "l" },
				["ł"] = { "pʲ", "j", "ɔ", "w" },
				[false] = { "pʲ", "j", "ɔ̃" }
			},
			["ę"] = {
				["l"] = { "pʲ", "j", "ɛ", "l" },
				["ł"] = { "pʲ", "j", "ɛ", "w" },
				[false] = { "pʲ", "j", "ɛ̃" }
			},
			["a"] = { "pʲ", "j", "a" },
			["e"] = { "pʲ", "j", "ɛ" },
			["i"] = { "pʲ", "j", "i" },
			["o"] = { "pʲ", "j", "ɔ" },
			["ó"] = { "pʲ", "j", "u" },
			["u"] = { "pʲ", "j", "u" },
			[false] = { "pʲ", "i" }
		},
		[false] = "p"
	},
	["r"] = {
		["i"] = {
			["ą"] = {
				["l"] = { "rʲ", "j", "ɔ", "l" },
				["ł"] = { "rʲ", "j", "ɔ", "w" },
				[false] = { "rʲ", "j", "ɔ̃" }
			},
			["ę"] = {
				["l"] = { "rʲ", "j", "ɛ", "l" },
				["ł"] = { "rʲ", "j", "ɛ", "w" },
				[false] = { "rʲ", "j", "ɛ̃" }
			},
			["a"] = { "rʲ", "j", "a" },
			["e"] = { "rʲ", "j", "ɛ" },
			["i"] = { "rʲ", "j", "i" },
			["o"] = { "rʲ", "j", "ɔ" },
			["ó"] = { "rʲ", "j", "u" },
			["u"] = { "rʲ", "j", "u" },
			[false] = { "rʲ", "i" }
		},
		["z"] = "ʐ",
		[false] = "r"
	},
	["q"] = {
		["u"] = { "k", "v" },
		[false] = false
	},
	["s"] = {
		["i"] = {
			["ą"] = {
				["l"] = { "ɕ", "ɔ", "l" },
				["ł"] = { "ɕ", "ɔ", "w" },
				[false] = { "ɕ", "ɔ̃" }
			},
			["ę"] = {
				["l"] = { "ɕ", "ɛ", "l" },
				["ł"] = { "ɕ", "ɛ", "w" },
				[false] = { "ɕ", "ɛ̃" }
			},
			["a"] = { "ɕ", "a" },
			["e"] = { "ɕ", "ɛ" },
			["o"] = { "ɕ", "ɔ" },
			["ó"] = { "ɕ", "u" },
			["u"] = { "ɕ", "u" },
			["y"] = { "ɕ", "ɨ" },
			[false] = { "ɕ", "i" }
		},
		["z"] = "ʂ",
		[false] = "s",
	},
	["ś"] = "ɕ",
	["t"] = {
		["i"] = {
			["ą"] = {
				["l"] = { "tʲ", "j", "ɔ", "l" },
				["ł"] = { "tʲ", "j", "ɔ", "w" },
				[false] = { "tʲ", "j", "ɔ̃" }
			},
			["ę"] = {
				["l"] = { "tʲ", "j", "ɛ", "l" },
				["ł"] = { "tʲ", "j", "ɛ", "w" },
				[false] = { "tʲ", "j", "ɛ̃" }
			},
			["a"] = { "tʲ", "j", "a" },
			["e"] = { "tʲ", "j", "ɛ" },
			["i"] = { "tʲ", "i" },
			["o"] = { "tʲ", "j", "ɔ" },
			["ó"] = { "tʲ", "j", "u" },
			["u"] = { "tʲ", "j", "u" },
			[false] = { "tʲ", "i" }
		},
		[false] = "t"
	},
	["u"] = "u",
	["v"] = {
		["i"] = {
			["ą"] = {
				["l"] = { "vʲ", "j", "ɔ", "l" },
				["ł"] = { "vʲ", "j", "ɔ", "w" },
				[false] = { "vʲ", "j", "ɔ̃" }
			},
			["ę"] = {
				["l"] = { "vʲ", "j", "ɛ", "l" },
				["ł"] = { "vʲ", "j", "ɛ", "w" },
				[false] = { "vʲ", "j", "ɛ̃" }
			},
			["a"] = { "vʲ", "j", "a" },
			["e"] = { "vʲ", "j", "ɛ" },
			["i"] = { "vʲ", "j", "i" },
			["o"] = { "vʲ", "j", "ɔ" },
			["ó"] = { "vʲ", "j", "u" },
			["u"] = { "vʲ", "j", "u" },
			[false] = { "vʲ", "i" }
		},
		[false] = "v"
	},
	["w"] = {
		["i"] = {
			["ą"] = {
				["l"] = { "vʲ", "j", "ɔ", "l" },
				["ł"] = { "vʲ", "j", "ɔ", "w" },
				[false] = { "vʲ", "j", "ɔ̃" }
			},
			["ę"] = {
				["l"] = { "vʲ", "j", "ɛ", "l" },
				["ł"] = { "vʲ", "j", "ɛ", "w" },
				[false] = { "vʲ", "j", "ɛ̃" }
			},
			["a"] = { "vʲ", "j", "a" },
			["e"] = { "vʲ", "j", "ɛ" },
			["i"] = { "vʲ", "j", "i" },
			["o"] = { "vʲ", "j", "ɔ" },
			["ó"] = { "vʲ", "j", "u" },
			["u"] = { "vʲ", "j", "u" },
			[false] = { "vʲ", "i" }
		},
		[false] = "v"
	},
	["x"] = { "k", "s" },
	["y"] = "ɨ",
	["z"] = {
		["i"] = {
			["ą"] = {
				["l"] = { "ʑ", "ɔ", "l" },
				["ł"] = { "ʑ", "ɔ", "w" },
				[false] = { "ʑ", "ɔ̃" }
			},
			["ę"] = {
				["l"] = { "ʑ", "ɛ", "l" },
				["ł"] = { "ʑ", "ɛ", "w" },
				[false] = { "ʑ", "ɛ̃" }
			},
			["a"] = { "ʑ", "a" },
			["e"] = { "ʑ", "ɛ" },
			["o"] = { "ʑ", "ɔ" },
			["ó"] = { "ʑ", "u" },
			["u"] = { "ʑ", "u" },
			[false] = { "ʑ", "i" }
		},
		[false] = "z"
	},
	["ź"] = "ʑ",
	["ż"] = "ʐ",
	["-"] = {},
}

local valid_phone = {
	["a"] = true, ["b"] = true, ["bʲ"] = true, ["d"] = true, ["dʲ"] = true, ["d͡z"] = true, ["d͡ʑ"] = true,
	["d͡ʐ"] = true, ["ɛ"] = true, ["ɛ̃"] = true, ["f"] = true, ["fʲ"] = true, ["ɡ"] = true,
	["ɡʲ"] = true, ["i"] = true, ["ɨ"] = true, ["j"] = true, ["k"] = true, ["kʲ"] = true,
	["l"] = true, ["lʲ"] = true, ["m"] = true, ["mʲ"] = true, ["n"] = true, ["ŋ"] = true,
	["ɲ"] = true, ["ɔ"] = true, ["ɔ̃"] = true, ["p"] = true, ["pʲ"] = true, ["r"] = true, ["rʲ"] = true,
	["s"] = true, ["ɕ"] = true, ["ʂ"] = true, ["t"] = true, ["tʲ"] = true, ["t͡s"] = true, ["t͡ɕ"] = true, ["t͡ʂ"] = true,
	["u"] = true, ["v"] = true, ["vʲ"] = true, ["w"] = true, ["w̃"] = true, ["x"] = true, ["xʲ"] = true, ["z"] = true,
	["ʑ"] = true, ["ʐ"] = true, ["ɣ"] = true
}

local sylmarks = {
	["."] = ".", ["'"] = "ˈ", ["ˈ"] = "ˈ", [","] = "ˌ"
}

local vowel = {
	["a"] = true, ["ɛ"] = true, ["ɛ̃"] = true,
	["i"] = true, ["ɨ"] = true, ["ɔ"] = true,
	["ɔ̃"] = true, ["u"] = true
}

local devoice = {
	["b"] = "p", ["d"] = "t", ["d͡z"] = "t͡s", ["d͡ʑ"] = "t͡ɕ",
	["d͡ʐ"] = "t͡ʂ", ["ɡ"] = "k", ["v"] = "f", ["vʲ"] = "fʲ",
	["z"] = "s", ["ʑ"] = "ɕ", ["ʐ"] = "ʂ",

	-- non-devoicable
	["bʲ"] = "bʲ", ["dʲ"] = "dʲ", ["ɡʲ"] = "ɡʲ", ["m"] = "m", ["mʲ"] = "mʲ",
	["n"] = "n", ["ɲ"] = "ɲ", ["ŋ"] = "ŋ", ["w"] = "w", ["w̃"] = "w̃",
	["l"] = "l", ["lʲ"] = "lʲ", ["j"] = "j", ["r"] = "r", ["rʲ"] = "rʲ", ["tʲ"] = "tʲ",
}

local voice = {
	["p"] = "b", ["t"] = "d", ["t͡s"] = "d͡z", ["t͡ɕ"] = "d͡ʑ",
	["t͡ʂ"] = "d͡ʐ", ["k"] = "ɡ", ["f"] = "v", ["fʲ"] = "vʲ",
	["s"] = "z", ["ɕ"] = "ʑ", ["ʂ"] = "ʐ", ["x"] = "ɣ",

	-- non-voicable
	["bʲ"] = "bʲ", ["dʲ"] = "dʲ", ["ɡʲ"] = "ɡʲ", ["m"] = "m", ["mʲ"] = "mʲ",
	["n"] = "n", ["ɲ"] = "ɲ", ["ŋ"] = "ŋ", ["w"] = "w", ["w̃"] = "w̃",
	["l"] = "l", ["lʲ"] = "lʲ", ["j"] = "j", ["r"] = "r", ["rʲ"] = "rʲ", ["tʲ"] = "tʲ",
}

local forward_assimilants = {
	["v"] = true, ["vʲ"] = true
}

local denasalized = {
	["ɛ̃"] = "ɛ",
	["ɔ̃"] = "ɔ",
}

local nasal_map = {
	["p"] = "m", ["pʲ"] = "m", ["b"] = "m", ["bʲ"] = "m", -- zębu, klępa
	["k"] = "ŋ", ["kʲ"] = "ŋ", ["ɡ"] = "ŋ", ["ɡʲ"] = "ŋ", -- pąk, łęgowy
	["t"] = "n", ["d"] = "n", -- wątek, piątek, mądrość

	["t͡ɕ"] = "ɲ", ["d͡ʑ"] = "ɲ", ["ɕ"] = "ɲ", ["ʑ"] = "ɲ", -- pięć, pędziwiatr, łabędź
	-- gęsi, więzi
	["t͡ʂ"] = "n", ["d͡ʐ"] = "n", -- pączek, ?
	-- węszyć, mężny
	["t͡s"] = "n", ["d͡z"] = "n", -- wiedząc, pieniędzy
}

local SPECIAL_FLAGS = {
	IS_RZ = "IS_RZ",
}

local third_last_syllable_stress = {
	"łbym", "łabym", "łbyś", "łabyś", "łby", "łaby", "łoby", "liby", "łyby",
}

local fourth_last_syllable_stress = {
	"libyśmy", "łybyśmy", "libyście", "łybyście",
}

---
-- Check whether phone doesn't change due to voicing/devoicing
---@param phone string
---@return boolean
local function is_neutral(phone)
	return (devoice[phone] and voice[phone]) and (voice[phone] == devoice[phone])
end

---
-- Check whether phone is a special character (syllable mark or word boundary)
---@param phone string
---@return boolean
local function is_special(phone)
	return phone == " " or sylmarks[phone]
end

---
-- Check whether phone is voiced
---@param phone string
---@return boolean
local function is_voiced(phone)
	return devoice[phone] and phone ~= devoice[phone]
end

---
-- Check whether phone is prone to forward assimilation
---@param phone string
---@param flags table Special flags for this phone
---@return boolean
local function is_forward_assimilant(phone, flags)
	return forward_assimilants[phone] or (flags and flags[SPECIAL_FLAGS.IS_RZ])
end

---
-- Check whether phone cluster is a palatalized cluster
---@param cluster string
---@return boolean
local function is_palatalized_cluster(cluster)
	return cluster:find("[ɡxkfbmprvdtl]ʲj[aɔ̃ɛɛ̃iɔu]") ~= nil
end

---
-- Process special flags for grapheme and associate them with the recorded phone
---@param grapheme string
---@return table | nil
local function process_special_flags(grapheme)
	if grapheme == "rz" then
		return { [SPECIAL_FLAGS.IS_RZ] = true }
	end
end

---
-- Convert letters and graphemes to phones
---@param word string
---@return table<number, string>, table<number, table<string, boolean>>
local function convert_to_phones(word)
	local phones = {}
	local flags = {}
	local chbuf = ""
	local function append_phone(phone)
		table.insert(phones, phone)

		-- mark rz for assimilation later
		local grapheme_flags = process_special_flags(chbuf)
		if grapheme_flags then
			flags[#phones] = grapheme_flags
		end
		chbuf = ""
	end

	local l2ptab = letters2phones
	for ch in mw.ustring.gmatch(mw.ustring.lower(word), ".") do
		local value = l2ptab[ch]

		if value == nil then
			value = l2ptab[false]
			if value == false then
				return nil
			elseif type(value) == "table" then
				for _, phone in ipairs(value) do
					append_phone(phone)
				end
			else
				append_phone(value)
			end
			l2ptab = letters2phones
			value = l2ptab[ch]
		end

		chbuf = chbuf .. ch

		if type(value) == "table" then
			if value[false] == nil then
				for _, phone in ipairs(value) do
					append_phone(phone)
				end
				l2ptab = letters2phones
			else
				l2ptab = value
			end
		elseif type(value) == "string" then
			append_phone(value)
			l2ptab = letters2phones
		else
			append_phone(ch)
		end
	end

	if l2ptab ~= letters2phones then
		local value = l2ptab[false]
		if type(value) == "table" then
			for _, phone in ipairs(value) do
				append_phone(phone)
			end
		else
			append_phone(value)
		end
	end

	return phones, flags
end

---
-- Simplify nasals
---@param phones table<number, string>
---@return table<number, string>
local function simplify_nasals(phones, flags)
	local new_phones, new_flags = {}, {}
	for i, phone in ipairs(phones) do
		if denasalized[phone] then
			local pnext = phones[i + 1]
			if sylmarks[pnext] then
				pnext = phones[i + 2]
			end
			if phone == "ɛ̃" and (not pnext or not valid_phone[pnext]) then
				-- denasalize word-final ę
				table.insert(new_phones, denasalized[phone])
				new_flags[#new_phones] = flags[i]
			elseif nasal_map[pnext] then
				table.insert(new_phones, denasalized[phone])
				table.insert(new_phones, nasal_map[pnext])
				new_flags[#new_phones] = flags[i]
			else
				table.insert(new_phones, phone)
				new_flags[#new_phones] = flags[i]
			end
		else
			table.insert(new_phones, phone)
			new_flags[#new_phones] = flags[i]
		end
	end
	return new_phones, new_flags
end

---
-- Devoice consonant phones in terminal positions
---@param phones table<number, string> Target phone table to mutate
local function terminal_devoice(phones)
	local final_phone = phones[#phones]
	if is_voiced(final_phone) then
		phones[#phones] = devoice[final_phone]
	end
end

---
-- Process consonant cluster assimilation for single cluster
---@param cluster table<number, string> Consonant cluster
---@param flags table<number, table<string, boolean>> Flags relative to the cluster
---@param new_phones table<number, string> Target phone table to mutate
local function process_consonant_cluster(cluster, flags, new_phones)
	local determining_index = #cluster
	while cluster[determining_index] do
		local candidate = cluster[determining_index]
		-- Skip forward assimilants and neutral phones to find the first voiced/devoiced consonant which decides the entire cluster
		if not is_forward_assimilant(candidate, flags[determining_index]) and not is_neutral(candidate) and not is_special(candidate) then
			break
		end
		determining_index = determining_index - 1
	end

	-- If the cluster ends up being comprised of just neutral phones and forward assimilants, add it as-is
	if determining_index == 0 then
		for _, consonant in ipairs(cluster) do
			table.insert(new_phones, consonant)
		end
		return
	end

	-- Transform the entire cluster, forward and back, relative to the determining consonant's voicing
	local determining_consonant = cluster[determining_index]
	local target_map = is_voiced(determining_consonant) and voice or devoice

	for _, consonant in ipairs(cluster) do
		local transformed = target_map[consonant] or consonant
		table.insert(new_phones, transformed)
	end
end

---
-- Process consonant cluster assimilation for single cluster
---@param phones table<number, string>
---@param flags table<number, table<string, boolean>>
---@return table<number, string>
local function process_consonant_clusters(phones, flags)
	local new_phones = {}
	local i = 1
	while i <= #phones do
		local pcurr, pnext = phones[i]
		if not valid_phone[pcurr] or vowel[pcurr] then
			-- Other phone encountered, add it as-is
			table.insert(new_phones, pcurr)
		else
			-- Consonant cluster to process
			local cluster = {}
			-- Phone flags indexed relative to the cluster
			local cluster_flags = {}

			-- Search forward for consonant cluster
			local j = i
			while j <= #phones do
				pnext = phones[j]

				-- Break on vowel or invalid symbol and process what we have
				if vowel[pnext] or (not valid_phone[pnext] and not is_special(pnext)) then
					break
				end

				table.insert(cluster, pnext)
				-- Set the cluster-relative flag for the latest processed phoneme
				cluster_flags[#cluster] = flags[j]

				j = j + 1
			end

			if #cluster > 0 then
				if #cluster > 1 then
					-- Process actual consonant cluster
					process_consonant_cluster(cluster, cluster_flags, new_phones)
					-- Skip forward past the processed phones to avoid any unwanted duplication
					-- Offset by 1 to compensate, because i is unconditionally incremented by 1 at the very end
					i = j - 1
				else
					-- The cluster is a single consonant, add it as-is
					table.insert(new_phones, cluster[1])
				end
			end
		end
		i = i + 1
	end
	return new_phones
end

---
-- Join several phones together, handling table and nil values
---@vararg string | table Phones to join together
---@return string
local function join_phones(...)
	local args = {...}
	local str = ""
	for _, syllable in ipairs(args) do
		if type(syllable) == "table" then
			str = str .. table.concat(syllable, "")
		else
			str = str .. (syllable or "")
		end
	end
	return str
end

---
-- Group phones into syllables
---@param phones table<number, string>
---@return table<number, string>
local function collect_syllables(phones)
	local words, curword, sylmarked, sylbuf, had_vowl = {}, nil, false
	for i, pcurr in ipairs(phones) do
		local pprev, pnext, pnnext = phones[i - 1], phones[i + 1], phones[i + 2]

		if valid_phone[pcurr] then
			if not curword then
				curword, sylbuf, had_vowl, sylmarked = {}, '', false, false
				table.insert(words, curword)
			end

			local same_syl = true

			if vowel[pcurr] then
				if had_vowl then
					same_syl = false
				end
				had_vowl = true
			elseif had_vowl then
				if vowel[pnext] then
					same_syl = false
				elseif not vowel[pprev] and not vowel[pnext] then
					same_syl = false
				elseif vowel[pprev] and is_palatalized_cluster(join_phones(pcurr, pnext, pnnext)) then
					same_syl = false
				elseif ((pcurr == "s") and ((pnext == "t") or (pnext == "p") or (pnext == "k")))
						or (pnext == "r") or (pnext == "f") or (pnext == "w")
						or ((pcurr == "ɡ") and (pnext == "ʐ"))
						or ((pcurr == "d") and ((pnext == "l") or (pnext == "w") or (pnext == "ɲ")))
						or is_palatalized_cluster(join_phones(pprev, pcurr, pnext))
				then
					-- these should belong to a common syllable
					same_syl = true
				end
			end

			if same_syl then
				sylbuf = sylbuf .. pcurr
			else
				table.insert(curword, sylbuf)
				sylbuf, had_vowl = pcurr, vowel[pcurr]
			end
		elseif (curword or valid_phone[pnext]) and sylmarks[pcurr] then
			if not curword then
				curword, sylbuf, had_vowl = {}, '', false
				table.insert(words, curword)
			end
			sylmarked = true
			if sylbuf then
				table.insert(curword, sylbuf)
				sylbuf = ''
			end
			table.insert(curword, sylmarks[pcurr])
		else
			if sylbuf then
				if #curword > 0 and not had_vowl then
					curword[#curword] = curword[#curword] .. sylbuf
				else
					table.insert(curword, sylbuf)
				end
				if sylmarked then
					words[#words] = table.concat(curword)
				end
			end
			curword, sylbuf = nil, nil
			table.insert(words, pcurr)
		end
	end
	if sylbuf then
		if #curword > 0 and not had_vowl then
			curword[#curword] = curword[#curword] .. sylbuf
		else
			table.insert(curword, sylbuf)
		end
		if sylmarked then
			words[#words] = table.concat(curword)
		end
	end

	return words
end

local function get_stressed_syllable(word)
	local stressed_syllable = 1
	for i,v in ipairs(third_last_syllable_stress) do
		if word:sub(-string.len(v)) == v 
		then
			stressed_syllable = 2
		end
	end
	for i,v in ipairs(fourth_last_syllable_stress) do
		if word:sub(-string.len(v)) == v 
		then
			stressed_syllable = 3
		end
	end
	
	return stressed_syllable
end

local function is_more_than_one_word(word)
	if string.find(word, " ") then
		return true
	else
		return false
	end
end

function export.convert_to_IPA(word)
	local stressed_syllable = get_stressed_syllable(word)
	local more_than_one_word = is_more_than_one_word(word)
	local phones, flags = convert_to_phones(word)
	phones, flags = simplify_nasals(phones, flags)
	terminal_devoice(phones)
	phones = process_consonant_clusters(phones, flags)
	local words = collect_syllables(phones)
	
	-- mark syllable breaks and stress
	for i, word in ipairs(words) do
		if type(word) == "table" then
			-- unless already marked
			if not ((word[2] == ".") or (word[2] == "ˈ") or (word[2] == "ˌ")) then
				for j, syl in ipairs(word) do
					if not more_than_one_word then
						if #word < stressed_syllable+1 then
							stressed_syllable = #word-1
						end
					end
					
					if #word > 1 then
						if j == (#word - stressed_syllable) then
							word[j] = "ˈ" .. syl
						elseif j ~= 1 then
							word[j] = "." .. syl
						end
					end
				end
			end
			words[i] = table.concat(word)
		end
	end
	
	for i, word in ipairs(words) do
		-- get rid of /ʲ/
		words[i] = mw.ustring.gsub(words[i], "ʲ([ij])", "%1")
		words[i] = mw.ustring.gsub(words[i], "ʲ", "j")
		-- replace /ɔ̃/ and /ɛ̃/ with /ɔw̃/ and /ɛw̃/
		words[i] = mw.ustring.gsub(words[i], "ɛ̃", "ɛw̃")
		words[i] = mw.ustring.gsub(words[i], "ɔ̃", "ɔw̃")
		---- replace /n/ with /w̃/ before /s, z, ʂ, ʐ, ɕ, ʑ/ (currently turned off)
		-- words[i] = mw.ustring.gsub(words[i], "n([szʂʐɕʑ])", "w̃%1")
		-- words[i] = mw.ustring.gsub(words[i], "n([ˈˌ.])([szʂʐɕʑ])", "w̃%1%2")
	end

	return table.concat(words)
end

function export.show(frame)
	local page_title = mw.title.getCurrentTitle().text

	local args = require "parameters".process(frame:getParent().args, {
		[1] = { list = true },
		["qual"] = { list = true, allow_holes = true },
		["n"] = { list = true, allow_holes = true },
	})

	local Array = require "array"

	local words
	if next(args[1]) ~= nil then
		words = args[1]
	else
		words = { page_title }
	end

	local transcriptions = Array(words):map(function(word, i)
		local qualifiers = { args.qual[i] }
		return {
			pron = "/" .. export.convert_to_IPA(word) .. "/",
			qualifiers = #qualifiers > 0 and qualifiers or nil,
			note = args.n[i]
		}
	end)

	return m_IPA.format_IPA_full(lang, transcriptions)
end

return export