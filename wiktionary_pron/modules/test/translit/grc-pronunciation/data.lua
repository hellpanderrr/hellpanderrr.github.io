local U = mw.ustring.char
local gmatch = mw.ustring.gmatch
local m_utils_data = require("grc-utilities/data")
local diacritics = m_utils_data.diacritics

local nonsyllabic = U(0x32F)
local high = U(0x341)  -- combining acute tone mark
local low = U(0x340)  -- combining grave tone mark
local midHigh = U(0x1DC4)  -- mid–high pitch
local midLow = U(0x1DC6)  -- mid–low pitch
local highMid = U(0x1DC7)  -- high–mid pitch
local rising = U(0x30C)		-- combining caron
local falling = diacritics.Latin_circum	-- combining circumflex
local voiceless = U(0x325) -- combining ring below
local aspirated = 'ʰ'
local stress_mark = 'ˈ'
local long = 'ː'
local macron = diacritics.spacing_macron
local breve = diacritics.spacing_breve

local circumflex_on_long_vowel = falling
local acute_on_long_vowel = rising
local acute_on_short_vowel = high
local grave_pitch_mark = low

local data = {}


local function get_pitch_marks(accent_type, long)
	if accent_type == 'acute' then
		if long then
			return acute_on_long_vowel
		else
			return acute_on_short_vowel
		end
	elseif accent_type == 'grave' then
		return grave_pitch_mark
	elseif accent_type == 'circum' then
		return circumflex_on_long_vowel
	end
	
	return ''
end

local function alpha(breathing, accent, iota, isLong)
	local breathing = breathing == 'rough' and { 'h', '(h)' } or { '', '' }
	local stress = accent and stress_mark or ''
	local pitch = get_pitch_marks(accent, isLong)
	local length = (isLong or iota or accent == 'circum') and long or ''
	local offglide = iota and ('i' .. nonsyllabic) or ''
	
	return {
			['cla'] = breathing[1] .. 'a' .. pitch .. length .. offglide,
			['koi1'] = breathing[2] .. stress .. 'a',
			['koi2'] = stress .. 'a',
			['byz1'] = stress .. 'a',
			['byz2'] = stress .. 'a'
		}
end

local function iota(breathing, accent, isLong)
	local breathing = breathing == 'rough' and { 'h', '(h)' } or { '', '' }
	local stress = accent and stress_mark or ''
	local pitch = get_pitch_marks(accent, isLong)
	local length = (isLong or accent == 'circum') and long or ''
	
	return {
			['cla'] = breathing[1] .. 'i' .. pitch .. length,
			['koi1'] = breathing[2] .. stress .. 'i',
			['koi2'] = stress .. 'i',
			['byz1'] = stress .. 'i',
			['byz2'] = stress .. 'i'
		}
end

local function ypsilon(breathing, accent, isLong)
	local breathing = breathing == 'rough' and { 'h', '(h)' } or { '', '' }
	local stress = accent and stress_mark or ''
	local pitch = get_pitch_marks(accent, isLong)
	local length = (isLong or accent == 'circum') and long or ''
	
	return {
			['cla'] = breathing[1] .. 'y' .. pitch .. length,
			['koi1'] = breathing[2] .. stress .. 'y',
			['koi2'] = stress .. 'y',
			['byz1'] = stress .. 'y',
			['byz2'] = stress .. 'i'
		}
end

local function omicron(breathing, accent)
	local breathing = breathing == 'rough' and { 'h', '(h)' } or { '', '' }
	local stress = accent and stress_mark or ''
	local pitch = get_pitch_marks(accent, false)
	
	return {
			['cla'] = breathing[1] .. 'o' .. pitch,
			['koi1'] = breathing[2] .. stress .. 'o',
			['koi2'] = stress .. 'o',
			['byz1'] = stress .. 'o',
			['byz2'] = stress .. 'o'
		}
end

local function epsilon(breathing, accent)
	local breathing = breathing == 'rough' and { 'h', '(h)' } or { '', '' }
	local stress = accent and stress_mark or ''
	local pitch = get_pitch_marks(accent, false)
	
	return {
			['cla'] = breathing[1] .. 'e' .. pitch,
			['koi1'] = breathing[2] .. stress .. 'e',
			['koi2'] = stress .. 'e',
			['byz1'] = stress .. 'e',
			['byz2'] = stress .. 'e'
		}
end

local function eta(breathing, accent, iota)
	local breathing = breathing == 'rough' and { 'h', '(h)' } or { '', '' }
	local stress = accent and stress_mark or ''
	local pitch = get_pitch_marks(accent, true)
	local offglide = iota and ('i' .. nonsyllabic) or ''
	
	return {
			['cla'] = breathing[1] .. 'ɛ' .. pitch .. long .. offglide,
			['koi1'] = breathing[2] .. stress .. 'e̝',
			['koi2'] = stress .. 'i',
			['byz1'] = stress .. 'i',
			['byz2'] = stress .. 'i'
		}
end

local function omega(breathing, accent, iota)
	local breathing = breathing == 'rough' and { 'h', '(h)' } or { '', '' }
	local stress = accent and stress_mark or ''
	local pitch = get_pitch_marks(accent, true)
	local offglide = iota and ('i' .. nonsyllabic) or ''
	
	return {
			['cla'] = breathing[1] .. 'ɔ' .. pitch .. long .. offglide,
			['koi1'] = breathing[2] .. stress .. 'o',
			['koi2'] = stress .. 'o',
			['byz1'] = stress .. 'o',
			['byz2'] = stress .. 'o'
		}
end

local function ai(breathing, accent)
	local breathing = breathing == 'rough' and { 'h', '(h)' } or { '', '' }
	local stress = accent and stress_mark or ''
	local pitch = get_pitch_marks(accent, true)
	
	return {
			['cla'] = breathing[1] .. 'a' .. pitch .. 'i' .. nonsyllabic,
			['koi1'] = breathing[2] .. stress .. 'ɛ',
			['koi2'] = stress .. 'ɛ',
			['byz1'] = stress .. 'e',
			['byz2'] = stress .. 'e'
		}
end

local function ei(breathing, accent)
	local breathing = breathing == 'rough' and { 'h', '(h)' } or { '', '' }
	local stress = accent and stress_mark or ''
	local pitch = get_pitch_marks(accent, true)
	
	return {
			['cla'] = breathing[1] .. 'e' .. pitch .. long,
			['koi1'] = breathing[2] .. stress .. 'i',
			['koi2'] = stress .. 'i',
			['byz1'] = stress .. 'i',
			['byz2'] = stress .. 'i'
		}
end

local function oi(breathing, accent)
	local breathing = breathing == 'rough' and { 'h', '(h)' } or { '', '' }
	local stress = accent and stress_mark or ''
	local pitch = get_pitch_marks(accent, true)
	
	return {
			['cla'] = breathing[1] .. 'o' .. pitch .. 'i' .. nonsyllabic,
			['koi1'] = breathing[2] .. stress .. 'y',
			['koi2'] = stress .. 'y',
			['byz1'] = stress .. 'y',
			['byz2'] = stress .. 'i'
		}
end

local function ui(breathing, accent)
	local breathing = breathing == 'rough' and { 'h', '(h)' } or { '', '' }
	local stress = accent and stress_mark or ''
	local pitch = get_pitch_marks(accent, true)
	
	return {
			['cla'] = breathing[1] .. 'y' .. pitch .. long,
			['koi1'] = breathing[2] .. stress .. 'y',
			['koi2'] = stress .. 'y',
			['byz1'] = stress .. 'y',
			['byz2'] = stress .. 'i'
		}
end

local function au(breathing, accent)
	local breathing = breathing == 'rough' and { 'h', '(h)' } or { '', '' }
	local stress = accent and stress_mark or ''
	local pitch = get_pitch_marks(accent, true)
	
	return {
		['cla'] = breathing[1] .. 'a' .. pitch .. 'u' .. nonsyllabic,
		['koi1'] = {
			{'2=σ+3=μ', stress .. 'a' .. 'w'},
			{'2.unvoiced', breathing[2] .. stress .. 'a' .. 'ʍ'},
			breathing[2] .. stress .. 'a' .. 'w',
		},
		['koi2'] = {
			{'2=σ+3=μ', stress .. 'aβ', },
			{ '2.unvoiced', stress .. 'aɸ', },
			stress .. 'aβ',
		},
		['byz1'] = {
			{'2=σ+3=μ', stress .. 'av', },
			{ '2.unvoiced', stress .. 'af', },
			stress .. 'av',
		},
		['byz2'] = {
			{'2=σ+3=μ', stress .. 'av', },
			{ '2.unvoiced', stress .. 'af', },
			stress .. 'av',
		},
	}
end

local function eu(breathing, accent)
	local breathing = breathing == 'rough' and { 'h', '(h)' } or { '', '' }
	local stress = accent and stress_mark or ''
	local pitch = get_pitch_marks(accent, true)
	
	return {
		['cla'] = breathing[1] .. 'e' .. pitch .. 'u' .. nonsyllabic,
		['koi1'] = {
			{'2=σ+3=μ', stress .. 'e' .. 'w'},
			{'2.unvoiced+3=μ', breathing[2] .. stress .. 'e' .. 'ʍ'},
			breathing[2] .. stress .. 'e' .. 'w',
		},
		['koi2'] = {
			{'2=σ+3=μ', stress .. 'eβ', },
			{ '2.unvoiced', stress .. 'eɸ', },
			stress .. 'eβ',
		},
		['byz1'] = {
			{'2=σ+3=μ', stress .. 'ev', },
			{ '2.unvoiced', stress .. 'ef', },
			stress .. 'ev',
		},
		['byz2'] = {
			{'2=σ+3=μ', stress .. 'ev', },
			{ '2.unvoiced', stress .. 'ef', },
			stress .. 'ev',
		},
	}
end

local function hu(breathing, accent)
	local breathing = breathing == 'rough' and { 'h', '(h)' } or { '', '' }
	local stress = accent and stress_mark or ''
	local pitch = get_pitch_marks(accent, true)
	
	return {
		['cla'] = breathing[1] .. 'ɛ' .. pitch .. 'ːu' .. nonsyllabic,
		['koi1'] = {
			{'2=σ+3=μ', stress .. 'e̝' .. 'w'},
			{'2.unvoiced', breathing[2] .. stress .. 'e̝' .. 'ʍ'},
			breathing[2] .. stress .. 'e̝' .. 'w',
		},
		['koi2'] = {
			{'2=σ+3=μ', stress .. 'iβ', },
			{ '2.unvoiced', stress .. 'iɸ', },
			stress .. 'iβ',
		},
		['byz1'] = {
			{'2=σ+3=μ', stress .. 'iv', },
			{ '2.unvoiced', stress .. 'if', },
			stress .. 'iv',
		},
		['byz2'] = {
			{'2=σ+3=μ', stress .. 'iv', },
			{ '2.unvoiced', stress .. 'if', },
			stress .. 'iv',
		},
	}
end

local function ou(breathing, accent)
	local breathing = breathing == 'rough' and { 'h', '(h)' } or { '', '' }
	local stress = accent and stress_mark or ''
	local pitch = get_pitch_marks(accent, true)
	
	return {
			['cla'] = breathing[1] .. 'u' .. pitch .. long,
			['koi1'] = breathing[2] .. stress .. 'u',
			['koi2'] = stress .. 'u',
			['byz1'] = stress .. 'u',
			['byz2'] = stress .. 'u'
		}
end

data[' '] = {
	['p'] = {
		['cla'] = ' ',
		['koi1'] = ' ',
		['koi2'] = ' ',
		['byz1'] = ' ',
		['byz2'] = ' ',
	},
}

data['β'] = {
	['clusters'] = {
		['δ'] = true,
		['λ'] = true,
		['ρ'] = true,
	},
	['p'] = {
		['cla'] = 'b',
		['koi1'] = 'b',
		['koi2'] = {
			{ '-1=μ', 'b', },
			'β'
		},
		['byz1'] = {
			{ '-1=μ', 'b', },
			'v'
		},
		['byz2'] = {
			{ '1=β', '', },
			{ '-1=μ', 'b', },
			'v',
		},
	},
}

data['γ'] = {
	['clusters'] = {
		['λ'] = true,
		['ν'] = true,
		['ρ'] = true,
	},
	['p'] = {
		['cla'] = {
			{ '1.dorsal/1=μ', 'ŋ', },
			'ɡ',
		},
		['koi1'] = {
			{ '1.dorsal', 'ŋ', },
			'ɡ',
		},
		['koi2'] = {
			{ '1.dorsal',
				{
					{ '1~preFront', 'ɲ', },
					'ŋ',
				},
			},
			{ '0~preFront',
				{
					{ '-1=γ', 'ɟ', },
					'ʝ',
				},
			},
			{ '-1=γ', 'ɡ', },
			'ɣ',		},
		['byz1'] = {
			{ '1.dorsal',
				{
					{ '1~preFront', 'ɲ', },
					'ŋ',
				},
			},
			{ '0~preFront',
				{
					{ '-1=γ', 'ɟ', },
					'ʝ',
				},
			},
			{ '-1=γ', 'ɡ', },
			'ɣ',
		},
		['byz2'] = {
			{ '1.dorsal', {
				{ '1~preFront', 'ɲ', },
				'ŋ', },
			},
			{ '0~preFront',
				{
					{ '-1=γ', 'ɟ', },
					'ʝ',
				},
			},
			{ '-1=γ', 'ɡ', },
			'ɣ',
		},
	},
}

data['δ'] = {
	['clusters'] = {
		['ρ'] = true,
	},
	['p'] = {
		['cla'] = 'd',
		['koi1'] = 'd',
		['koi2'] = {
			{ '-1=ν', 'd', },
			'ð',
		},
		['byz1'] = {
			{ '-1=ν', 'd', },
			'ð',
		},
		['byz2'] = {
			{ '1=δ', '', },
			{ '-1=ν', 'd', },
			'ð',
		},
	},
}

data['ζ'] = {
	['clusters'] = { },
	['p'] = {
		['cla'] = 'zd',
		['koi1'] = 'z',
		['koi2'] = 'z',
		['byz1'] = 'z',
		['byz2'] = {
			{ '1=ζ', '', },
			'z',
		},
	},
}

data['θ'] = {
	['clusters'] = {
		['ρ'] = true,
	},
	['p'] = {
		['cla'] = 'tʰ',
		['koi1'] = 'tʰ',
		['koi2'] = 'θ',
		['byz1'] = 'θ',
		['byz2'] = {
			{ '1=θ', '', },
			'θ',
		},
	},
}

data['κ'] = {
	['clusters'] = {
		['λ'] = true,
		['ν'] = true,
		['τ'] = true,
		['ρ'] = true,
	},
	['p'] = {
		['cla'] = {
			{ '1.voiced+1.stop', 'ɡ', },
			{ '1.aspirated', 'kʰ', },
			'k',
		},
		['koi1'] = {
			{ '1.voiced+1.stop', 'ɡ', },
			'k',
		},
		['koi2'] = {
			{ '1=κ', '', },
			{ '1.voiced+1.stop', 'ɡ', },
			{
				'-1=γ',
				{
					{ '0~preFront', 'ɟ' },
					'ɡ',
				},
			},
			{ '0~preFront', 'c', },
			'k',
		},
		['byz1'] = {
			{ '1=κ', '', },
			{ '1.voiced+1.stop', 'ɡ', },
			{
				'-1=γ',
				{
					{ '0~preFront', 'ɟ' },
					'ɡ',
				},
			},
			{ '0~preFront', 'c', },
			'k',
		},
		['byz2'] = {
			{ '1=κ', '', },
			{ '1.voiced+1.stop', 'ɡ', }, -- In what case does a voiced stop precede κ?
			{
				'-1=γ',
				{
					{ '0~preFront', 'ɟ' },
					'ɡ',
				},
			},
			{ '0~preFront', 'c', },
			'k',
		},
	},
}

data['λ'] = {
	['clusters'] = { },
	['p'] = {
		['cla'] = 'l',
		['koi1'] = 'l',
		['koi2'] = 'l',
		['byz1'] = 'l',
		['byz2'] = {
			{ '1=λ', '', },
			'l',
		},
	},
}

data['μ'] = {
	['clusters'] = {
		['ν'] = true,
	},
	['p'] = {
		['cla'] = 'm',
		['koi1'] = 'm',
		['koi2'] = 'm',
		['byz1'] = 'm',
		['byz2'] = {
			{ '1=μ', '', },
			'm',
		},
	},
}

data['ν'] = {
	['clusters'] = { },
	['p'] = {
		['cla'] = 'n',
		['koi1'] = 'n',
		['koi2'] = 'n',
		['byz1'] = 'n',
		['byz2'] = {
			{ '1=ν', '', },
			'n',
		},
	},
}

data['ξ'] = {
	['clusters'] = { },
	['p'] = {
		['cla'] = 'ks',
		['koi1'] = 'ks',
		['koi2'] = 'ks',
		['byz1'] = 'ks',
		['byz2'] = 'ks',
	},
}

data['π'] = {
	['clusters'] = {
		['λ'] = true,
		['ν'] = true,
		['ρ'] = true,
		['τ'] = true,
	},
	['p'] = {
		['cla'] = { 
			{ '1.aspirated', 'pʰ', },
			'p',
		},
		['koi1'] = 'p',
		['koi2'] = 'p',
		['byz1'] = 'p',
		['byz2'] = {
			{ '-1=μ', 'b' },
			{ '1=π', '', },
			'p',
		},
	},
}

data['ρ'] = {
	['clusters'] = { },
	['p'] = {
		['cla'] = {
			{ '1=ρ/1=ῥ/-1=ρ', 'r̥', },
			'r',
		},
		['koi1'] = 'r',
		['koi2'] = 'r',
		['byz1'] = 'r',
		['byz2'] = {
			{ '1=ρ', '', },
			'r',
		},
	},
}

data['ῥ'] = {
	['clusters'] = { },
	['p'] = {
		['cla'] = 'r̥',
		['koi1'] = 'r',
		['koi2'] = 'r',
		['byz1'] = 'r',
		['byz2'] = {
			{ '1=ρ', '', },
			'r',
		},
	},
}

data['σ'] = {
	['clusters'] = {
		['β'] = true,
		['θ'] = true,
		['κ'] = true,
		['μ'] = true,
		['π'] = true,
		['τ'] = true,
		['φ'] = true,
		['χ'] = true,
	},
	['p'] = {
		['cla'] = {
			{ '1.voiced', 'z', },
			's',
		},
		['koi1'] = {
			{ '1.voiced', 'z', },
			's',
		},
		['koi2'] = {
			{ '1.voiced', 'z', },
			's',
		},
		['byz1'] = {
			{ '1.voiced', 'z', },
			's',
		},
		['byz2'] = {
			{ '1=σ', '', },
			{ '1.voiced', 'z', },
			's',
		},
	},
}

data['τ'] = {
	['clusters'] = {
		['λ'] = true,
		['μ'] = true,
		['ρ'] = true,
	},
	['p'] = {
		['cla'] = {
			{ '1.aspirated', 'tʰ', },
			't',
		},
		['koi1'] = 't',
		['koi2'] = 't',
		['byz1'] = 't',
		['byz2'] = {
			{ '-1=ν', 'd' },
			{ '1=τ', '', },
			't',
		},
	},
}

data['φ'] = {
	['clusters'] = {
		['θ'] = true,
		['λ'] = true,
		['ρ'] = true,
	},
	['p'] = {
		['cla'] = 'pʰ',
		['koi1'] = 'pʰ',
		['koi2'] = 'ɸ',
		['byz1'] = 'f',
		['byz2'] = {
			{ '1=φ', '', },
			'f',
		},
	},
}

data['χ'] = {
	['clusters'] = {
		['θ'] = true,
		['λ'] = true,
		['ρ'] = true,
	},
	['p'] = {
		['cla'] = 'kʰ',
		['koi1'] = 'kʰ',
		['koi2'] = {
			{ '1=χ', '', },
			{ '0~preFront', 'ç', },
			'x', },
		['byz1'] = {
			{ '1=χ', '', },
			{ '0~preFront', 'ç', },
			'x', },
		['byz2'] = {
			{ '1=χ', '', },
			{ '0~preFront', 'ç', },
			'x',
		},
	},
}

data['ψ'] = {
	['clusters'] = { },
	['p'] = {
		['cla'] = 'ps',
		['koi1'] = 'ps',
		['koi2'] = 'ps',
		['byz1'] = 'ps',
		['byz2'] = 'ps',
	},
}

data['ϝ'] = {
	['clusters'] = { },
	['p'] = {
		['cla'] = 'w',
		['koi1'] = '',
		['koi2'] = '',
		['byz1'] = '',
		['byz2'] = '',
	},
}

data['α'] = {
	['pre'] = {
		{ '0~isIDiphth/0~isUDiphth/0~hasMacronBreve', 1},
		0,
	},
	['p'] = {
		['cla'] = 'a',
		['koi1'] = 'a',
		['koi2'] = 'a',
		['byz1'] = 'a',
		['byz2'] = 'a',
	},
}

data['ε'] = {
	['pre'] = {
		{ '0~isIDiphth/0~isUDiphth', 1},
		0,
	},
	['p'] = {
		['cla'] = 'e',
		['koi1'] = 'e',
		['koi2'] = 'e',
		['byz1'] = 'e',
		['byz2'] = 'e',
	},
}

data['η'] = {
	['pre'] = {
		{ '0~isUDiphth', 1},
		0,
	},
	['p'] = {
		['cla'] = 'ɛ',
		['koi1'] = 'e̝',
		['koi2'] = 'i',
		['byz1'] = 'i',
		['byz2'] = 'i',
	},
}

data['ι'] = {
	['p'] = {
		['cla'] = 'i',
		['koi1'] = 'i',
		['koi2'] = 'i',
		['byz1'] = 'i',
		['byz2'] = 'i',
	},
}

data['ο'] = {
	['pre'] = {
		{ '0~isIDiphth/0~isUDiphth', 1},
		0,
	},
	['p'] = {
		['cla'] = 'o',
		['koi1'] = 'o',
		['koi2'] = 'o',
		['byz1'] = 'o',
		['byz2'] = 'o',
	},
}

data['υ'] = {
	['pre'] = {
		{ '0~isIDiphth/0~hasMacronBreve', 1},
		0,
	},
	['p'] = {
		['cla'] = 'y',
		['koi1'] = 'y',
		['koi2'] = 'y',
		['byz1'] = 'y',
		['byz2'] = 'i',
	},
}

data['ω'] = {
	['p'] = {
		['cla'] = 'ɔ',
		['koi1'] = 'o',
		['koi2'] = 'o',
		['byz1'] = 'o',
		['byz2'] = 'o',
	},
}

local categories = {
	[1] = {
		["stop"] = { "π", "τ", "κ", "β", "δ", "γ", "φ", "θ", "χ", "ψ", "ξ", },
		["dorsal"] = { "κ", "γ", "χ", "ξ", },
		["voiced"] = { "β", "δ", "γ", "ζ", "μ", "ν", "λ", "ρ", "ϝ", },
		["unvoiced"] = { "π", "ψ", "τ", "κ", "ξ", "φ", "θ", "χ", "σ", "ς", },
		["aspirated"] = { "φ", "θ", "χ", },
		["diaer"] = { "ϊ", "ϋ", "ΐ", "ΰ", "ῒ", "ῢ", "ῗ", "ῧ", },
		["subi"] = { "ᾳ", "ῃ", "ῳ", "ᾴ", "ῄ", "ῴ", "ᾲ", "ῂ", "ῲ", "ᾷ", "ῇ", "ῷ", "ᾀ", "ᾐ", "ᾠ", "ᾄ", "ᾔ", "ᾤ", "ᾂ", "ᾒ", "ᾢ", "ᾆ", "ᾖ", "ᾦ", "ᾁ", "ᾑ", "ᾡ", "ᾅ", "ᾕ", "ᾥ", "ᾃ", "ᾓ", "ᾣ", "ᾇ", "ᾗ", "ᾧ", },
		},
	["type"] = {
		["vowel"] = { "α", "ε", "η", "ι", "ο", "ω", "υ", }, -- Not currently used; if it were, it might need to include all the accented vowel characters.
		["consonant"] = { "β", "γ", "δ", "ζ", "θ", "κ", "λ", "μ", "ν", "ξ", "π", "ρ", "σ", "ς", "τ", "φ", "χ", "ψ", },
		["long"] = { "η", "ω", "ᾱ", "ῑ", "ῡ", },
		["short"] = { "ε", "ο", "ᾰ", "ῐ", "ῠ", },
		["either"] = { "α", "ι", "υ", },
		["diacritic"] = { diacritics.macron, diacritics.spacing_macron, diacritics.modifier_macron, diacritics.breve, diacritics.spacing_breve, diacritics.rough, diacritics.smooth, diacritics.diaeresis, diacritics.acute, diacritics.grave, diacritics.circum, diacritics.Latin_circum, diacritics.coronis, diacritics.subscript, },
		},
	["accent"] = {
		["acute"] = { "ά", "έ", "ή", "ί", "ό", "ύ", "ώ", "ᾴ", "ῄ", "ῴ", "ἄ", "ἔ", "ἤ", "ἴ", "ὄ", "ὔ", "ὤ", "ᾄ", "ᾔ", "ᾤ", "ἅ", "ἕ", "ἥ", "ἵ", "ὅ", "ὕ", "ὥ", "ᾅ", "ᾕ", "ᾥ", "ΐ", "ΰ", },
		["grave"] = { "ὰ", "ὲ", "ὴ", "ὶ", "ὸ", "ὺ", "ὼ", "ᾲ", "ῂ", "ῲ", "ἂ", "ἒ", "ἢ", "ἲ", "ὂ", "ὒ", "ὢ", "ᾂ", "ᾒ", "ᾢ", "ἃ", "ἓ", "ἣ", "ἳ", "ὃ", "ὓ", "ὣ", "ᾃ", "ᾓ", "ᾣ", "ῒ", "ῢ", },
		["circum"] = { "ᾶ", "ῆ", "ῖ", "ῦ", "ῶ", "ᾷ", "ῇ", "ῷ", "ἆ", "ἦ", "ἶ", "ὖ", "ὦ", "ᾆ", "ᾖ", "ᾦ", "ἇ", "ἧ", "ἷ", "ὗ", "ὧ", "ᾇ", "ᾗ", "ᾧ", "ῗ", "ῧ", },
		},
	["breath"] = {
		["rough"] = { "ἁ", "ἑ", "ἡ", "ἱ", "ὁ", "ὑ", "ὡ", "ᾁ", "ᾑ", "ᾡ", "ἅ", "ἕ", "ἥ", "ἵ", "ὅ", "ὕ", "ὥ", "ᾅ", "ᾕ", "ᾥ", "ἃ", "ἓ", "ἣ", "ἳ", "ὃ", "ὓ", "ὣ", "ᾃ", "ᾓ", "ᾣ", "ἇ", "ἧ", "ἷ", "ὗ", "ὧ", "ᾇ", "ᾗ", "ᾧ", },
		["smooth"] = { "ἀ", "ἐ", "ἠ", "ἰ", "ὀ", "ὐ", "ὠ", "ᾀ", "ᾐ", "ᾠ", "ῤ", "ἄ", "ἔ", "ἤ", "ἴ", "ὄ", "ὔ", "ὤ", "ᾄ", "ᾔ", "ᾤ", "ἂ", "ἒ", "ἢ", "ἲ", "ὂ", "ὒ", "ὢ", "ᾂ", "ᾒ", "ᾢ", "ἆ", "ἦ", "ἶ", "ὖ", "ὦ", "ᾆ", "ᾖ", "ᾦ", },
		},
	}

for key1, list in pairs(categories) do
	for key2, letters in pairs(list) do
		if type(key1) == "number" then
			for _, letter in ipairs(letters) do
				if not data[letter] then
					data[letter] = {}
				end
				data[letter][key2] = true
			end
		elseif type(key1) == "string" then
			for _, letter in ipairs(letters) do
				if not data[letter] then
					data[letter] = {}
				end
				data[letter][key1] = key2
			end
		end
	end
end

for letter in gmatch("εέὲἐἔἒἑἕἓ", ".") do
	local l_data = data[letter]
	l_data.p = epsilon(l_data.breath, l_data.accent)
end

for letter in gmatch("οόὸὀὄὂὁὅὃ", ".") do
	local l_data = data[letter]
	l_data.p = omicron(l_data.breath, l_data.accent)
end

for letter in gmatch("ηῃήῄὴῂῆῇἠᾐἤᾔἢᾒἦᾖἡᾑἥᾕἣᾓἧᾗ", ".") do
	local l_data = data[letter]
	l_data.p = eta(l_data.breath, l_data.accent, l_data.subi)
end

for letter in gmatch("ωῳώῴὼῲῶῷὠᾠὤᾤὢᾢὦᾦὡᾡὥᾥὣᾣὧᾧ", ".") do
	local l_data = data[letter]
	l_data.p = omega(l_data.breath, l_data.accent, l_data.subi)
end

for letter in gmatch("αᾳάᾴὰᾲᾶᾷἀᾀἄᾄἂᾂἆᾆἁᾁἅᾅἃᾃἇᾇ", ".") do
	local l_data = data[letter]
	l_data.p = alpha(l_data.breath, l_data.accent, l_data.subi)
	if not l_data.subi and l_data.accent ~= 'circum' then
		if not l_data.pre then
			l_data.pre =  { { '0~hasMacronBreve', 1}, 0, }
		end
		data[letter .. breve] = {p = alpha(l_data.breath, l_data.accent, false, false)}
		data[letter .. macron] = {p = alpha(l_data.breath, l_data.accent, false, true)}
	end
end

for letter in gmatch("ιίὶῖἰἴἲἶἱἵἳἷϊΐῒῗ", ".") do
	local l_data = data[letter]
	l_data.p = iota(l_data.breath, l_data.accent)
	if l_data.accent ~= 'circum' then
		l_data.pre =  { { '0~hasMacronBreve', 1}, 0, }
		data[letter .. breve] = {p = iota(l_data.breath, l_data.accent, false)}
		data[letter .. macron] = {p = iota(l_data.breath, l_data.accent, true)}
	end
	if not l_data.diar then
		data['α' .. letter] = {p = ai(l_data.breath, l_data.accent)}
		data['ε' .. letter] = {p = ei(l_data.breath, l_data.accent)}
		data['ο' .. letter] = {p = oi(l_data.breath, l_data.accent)}
		data['υ' .. letter] = {p = ui(l_data.breath, l_data.accent)}
	end
end

for letter in gmatch("υύὺῦὐὔὒὖὑὕὓὗϋΰῢῧ", ".") do
	local l_data = data[letter]
	l_data.p = ypsilon(l_data.breath, l_data.accent)
	if l_data.accent ~= 'circum' then
		if letter ~= 'υ' then l_data.pre =  { { '0~hasMacronBreve', 1}, 0, } end
		data[letter .. breve] = {p = ypsilon(l_data.breath, l_data.accent, false)}
		data[letter .. macron] = {p = ypsilon(l_data.breath, l_data.accent, true)}
	end
	if not l_data.diar then
		data['α' .. letter] = {p = au(l_data.breath, l_data.accent)}
		data['η' .. letter] = {p = hu(l_data.breath, l_data.accent)}
		data['ε' .. letter] = {p = eu(l_data.breath, l_data.accent)}
		data['ο' .. letter] = {p = ou(l_data.breath, l_data.accent)}
	end
end

data['chars'] = {
	['cons'] = 'bɡŋdzklmnprstβðɣɸθxfvɟʝcçwʍj',
	['vowel'] = "aeiouyɛɔ",
	['diacritic'] = high .. low .. midHigh .. midLow .. highMid .. long .. aspirated .. voiceless .. nonsyllabic .. rising .. falling,
	['liquid'] = "rln",
	['obst'] = "bɡdkptβðɣɸθxfv",
	['frontDiphth'] = "[αο]ι",
	['frontVowel'] = "ιηευ",
	['iDiaer'] = "ϊΐῒῗ",
	['long'] = "ηω",
	['short'] = "εο",
	['ambig'] = "αιυ",
	['uDiphth'] = 'αεηο', -- first members for diphthongs ending in 'υ'
	['iDiphth'] = 'αεου', -- first members for diphthongs ending in 'ι'
	['Greekdiacritic'] = m_utils_data.all,
	['Greekconsonant'] = m_utils_data.consonants
}
data.chars.frontDiphthong = data.chars.frontDiphth

return data