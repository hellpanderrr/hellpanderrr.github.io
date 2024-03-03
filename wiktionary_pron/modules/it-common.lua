local ex = {} -- normally called `export` but there are so many references to exported functions in this module

local put_module = "Module:parse utilities"
local romut_module = "Module:romance utilities"
local strutil_module = "Module:string utilities"

local u = mw.ustring.char
local rfind = mw.ustring.find
local rsubn = mw.ustring.gsub
local rsplit = mw.text.split


local prepositions = {
	-- a, da + optional article
	"d?al? ",
	"d?all[oae] ",
	"d?all'",
	"d?ai ",
	"d?agli ",
	-- di, in + optional article
	"di ",
	"d'",
	"in ",
	"[dn]el ",
	"[dn]ell[oae] ",
	"[dn]ell'",
	"[dn]ei ",
	"[dn]egli ",
	-- su + optional article
	"su ",
	"sul ",
	"sull[oae] ",
	"sull'",
	"sui ",
	"sugli ",
	-- others
	"come ",
	"con ",
	"per ",
	"tra ",
	"fra ",
}


-- version of rsubn() that discards all but the first return value
function ex.rsub(term, foo, bar)
	local retval = rsubn(term, foo, bar)
	return retval
end

-- version of rsubn() that returns a 2nd argument boolean indicating whether
-- a substitution was made.
function ex.rsubb(term, foo, bar)
	local retval, nsubs = rsubn(term, foo, bar)
	return retval, nsubs > 0
end

-- apply rsub() repeatedly until no change
function ex.rsub_repeatedly(term, foo, bar)
	while true do
		local new_term = ex.rsub(term, foo, bar)
		if new_term == term then
			return term
		end
		term = new_term
	end
end


---------------------- Pronunciation -----------------

ex.AC = u(0x301)
ex.GR = u(0x300)
ex.CFLEX = u(0x302)
ex.DOTOVER = u(0x0307) -- dot over =  ̇ = signal unstressed word
ex.DOTUNDER = u(0x0323) -- dot under =  ̣ = unstressed vowel with quality marker
ex.LINEUNDER = u(0x0331) -- line under =  ̱ = secondary-stressed vowel with quality marker
ex.DIA = u(0x0308) -- diaeresis = ̈
ex.TIE = u(0x0361) -- tie =  ͡
ex.stress = "ˈˌ"
ex.stress_c = "[" .. ex.stress .. "]"
ex.quality = ex.AC .. ex.GR
ex.quality_c = "[" .. ex.quality .. "]"
ex.accent = ex.stress .. ex.quality .. ex.CFLEX .. ex.DOTOVER .. ex.DOTUNDER .. ex.LINEUNDER
ex.accent_c = "[" .. ex.accent .. "]"

-- Apply canonical Unicode decomposition to text, e.g. è → e + ◌̀. But recompose ö and ü so we can treat them as single
-- vowels, and put ex.LINEUNDER/ex.DOTUNDER/ex.DOTOVER after acute/grave (canonical decomposition puts ex.LINEUNDER and ex.DOTUNDER
-- first).
function ex.decompose(text)
	text = mw.ustring.toNFD(text)
	text = ex.rsub(text, "." .. ex.DIA, {
		["o" .. ex.DIA] = "ö",
		["O" .. ex.DIA] = "Ö",
		["u" .. ex.DIA] = "ü",
		["U" .. ex.DIA] = "Ü",
	})
	text = ex.rsub(text, "([" .. ex.LINEUNDER .. ex.DOTUNDER .. ex.DOTOVER .. "])(" .. ex.quality_c .. ")", "%2%1")
	return text
end

-- Apply canonical Unicode composition to text, e.g. e + ◌̀ → è.
function ex.compose(text)
	return mw.ustring.toNFC(text)
end

-- Split into words. Hyphens separate words but not when used to denote affixes, i.e. hyphens between non-spaces
-- separate words. Return value includes alternating words and separators. Use table.concat(words) to reconstruct
-- the initial text.
function ex.split_but_rejoin_affixes(text)
	if not rfind(text, "[%s%-]") then
		return {text}
	end
	-- First replace hyphens separating words with a special character. Remaining hyphens denote affixes and don't
	-- get split. After splitting, replace the special character with a hyphen again.
	local TEMP_HYPH = u(0xFFF0)
	text = ex.rsub_repeatedly(text, "([^%s])%-([^%s])", "%1" .. TEMP_HYPH .. "%2")
	local words = require(strutil_module).capturing_split(text, "([%s" .. TEMP_HYPH .. "]+)")
	for i, word in ipairs(words) do
		if word == TEMP_HYPH then
			words[i] = "-"
		end
	end
	return words
end

function ex.remove_secondary_stress(text)
	local words = ex.split_but_rejoin_affixes(text)
	for i, word in ipairs(words) do
		if (i % 2) == 1 then -- an actual word, not a separator
			-- Remove unstressed quality marks.
			word = ex.rsub(word, ex.quality_c .. ex.DOTUNDER, "")
			-- Remove secondary stresses. Specifically:
			-- (1) Remove secondary stresses marked with ex.LINEUNDER if there's a previously stressed vowel.
			-- (2) Otherwise, just remove the ex.LINEUNDER, leaving the accent mark, which will then be removed if there's
			--     a following stressed vowel, but left if it's the only stress in the word, as in có̱lle = con le.
			--     (In the process, we remove other non-stress marks.)
			-- (3) Remove stress mark if there's a following stressed vowel.
			word = ex.rsub_repeatedly(word, "(" .. ex.quality_c .. ".*)" .. ex.quality_c .. ex.LINEUNDER, "%1")
			word = ex.rsub(word, "[" .. ex.CFLEX .. ex.DOTOVER .. ex.DOTUNDER .. ex.LINEUNDER .. "]", "")
			word = ex.rsub_repeatedly(word, ex.quality_c .. "(.*" .. ex.quality_c .. ")", "%1")
			words[i] = word
		end
	end
	return table.concat(words)
end

-- Remove all accents. NOTE: `text` on entry must be decomposed using decompose().
function ex.remove_accents(text)
	return ex.rsub(text, ex.accent_c, "")
end

-- Remove non-word-final accents. NOTE: `text` on entry must be decomposed using decompose().
function ex.remove_non_final_accents(text)
	local words = ex.split_but_rejoin_affixes(text)
	for i, word in ipairs(words) do
		if (i % 2) == 1 then -- an actual word, not a separator
			word = ex.rsub_repeatedly(word, ex.accent_c .. "(.)", "%1")
			words[i] = word
		end
	end
	return table.concat(words)
end


---------------------- References -----------------

function ex.parse_abbreviated_references_spec(spec)
	local spec_before_modifiers, modifiers = spec:match("^(.-)(<<.*>>)$")
	if spec_before_modifiers then
		spec = spec_before_modifiers
	else
		modifiers = ""
	end
	local template_name, props = spec:match("^([^:]+):(.*)$")
	if not template_name then
		template_name = spec
		props = ""
	else
		if props:find(",%s") then
			props = require(put_module).split_on_comma(props)
		else
			props = rsplit(props, ",")
		end
		for i, prop in ipairs(props) do
			if prop:find("#") then
				local param, val = prop:match("^(.-)#(.*)$")
				props[i] = "|" .. param .. "=" .. val
			else
				props[i] = "|" .. prop
			end
		end
		props = table.concat(props)
	end
	if template_name == "" and props == "" then
		return modifiers
	else
		return mw.getCurrentFrame():preprocess(("{{R:it:%s%s}}"):format(template_name, props)) .. modifiers
	end
end


---------------------- Inflection -----------------

-- Given a term `term`, if the term is multiword (either through spaces or hyphens), handle inflection of the term by
-- calling handle_multiword() in [[Module:romance utilities]]. `special` indicates which parts of the multiword term to
-- inflect, and `inflect` is a function of one argument to inflect the individual parts of the term. As an optimization,
-- if the term is not multiword and `special` is not given, do nothing.
local function call_handle_multiword(term, special, inflect)
	if not special and not term:find("[ %-]") then
		return nil
	end
	local retval = require(romut_module).handle_multiword(term, special, inflect, prepositions)
	if retval and #retval > 0 then
		if #retval ~= 1 then
			error("Internal error: Should have only one return value from inflection function: " .. table.concat(retval, ","))
		end
		return retval[1]
	end
	return nil
end

-- Generate a default plural form, which is correct for most regular nouns and adjectives.
function ex.make_plural(term, gender, special)
	local plspec
	if special == "cap*" or special == "cap*+" then
		plspec = special
		special = nil
	end
	local retval = call_handle_multiword(term, special, function(term) return ex.make_plural(term, gender, plspec) end)
	if retval then
		return retval
	end

	local function check_no_mf()
		if gender == "mf" or gender == "mfbysense" or gender == "?" then
			error("With gender=" .. gender .. ", unable to pluralize term '" .. term .. "'"
				.. (special and " using special=" .. special or "") .. " because its plural is gender-specific")
		end
	end

	if plspec == "cap*" or plspec == "cap*+" then
		check_no_mf()
		if not term:find("^capo") then
			error("With special=" .. plspec .. ", term '" .. term .. "' must begin with capo-")
		end
		if gender == "m" then
			term = term:gsub("^capo", "capi")
		end
		if plspec == "cap*" then
			return term
		end
	end

	if term:find("io$") then
		term = term:gsub("io$", "i")
	elseif term:find("ologo$") then
		term = term:gsub("o$", "i")
	elseif term:find("[ia]co$") then
		term = term:gsub("o$", "i")
	-- Of adjectives in -co but not in -aco or -ico, there are several in -esco that take -eschi, and various
	-- others that take -chi: [[adunco]], [[anficerco]], [[azteco]], [[bacucco]], [[barocco]], [[basco]],
	-- [[bergamasco]], [[berlusco]], [[bianco]], [[bieco]], [[bisiacco]], [[bislacco]], [[bisulco]], [[brigasco]],
	-- [[brusco]], [[bustocco]], [[caduco]], [[ceco]], [[cecoslovacco]], [[cerco]], [[chiavennasco]], [[cieco]],
	-- [[ciucco]], [[comasco]], [[cosacco]], [[cremasco]], [[crucco]], [[dificerco]], [[dolco]], [[eterocerco]],
	-- [[etrusco]], [[falisco]], [[farlocco]], [[fiacco]], [[fioco]], [[fosco]], [[franco]], [[fuggiasco]], [[giucco]],
	-- [[glauco]], [[gnocco]], [[gnucco]], [[guatemalteco]], [[ipsiconco]], [[lasco]], [[livignasco]], [[losco]], 
	-- [[manco]], [[monco]], [[monegasco]], [[neobarocco]], [[olmeco]], [[parco]], [[pitocco]], [[pluriconco]], 
	-- [[poco]], [[polacco]], [[potamotoco]], [[prebarocco]], [[prisco]], [[protobarocco]], [[rauco]], [[ricco]], 
	-- [[risecco]], [[rivierasco]], [[roco]], [[roiasco]], [[sbieco]], [[sbilenco]], [[sciocco]], [[secco]],
	-- [[semisecco]], [[slovacco]], [[somasco]], [[sordocieco]], [[sporco]], [[stanco]], [[stracco]], [[staricco]],
	-- [[taggiasco]], [[tocco]], [[tosco]], [[triconco]], [[trisulco]], [[tronco]], [[turco]], [[usbeco]], [[uscocco]],
	-- [[uto-azteco]], [[uzbeco]], [[valacco]], [[vigliacco]], [[zapoteco]].
	--
	-- Only the following take -ci: [[biunivoco]], [[dieco]], [[equivoco]], [[estrinseco]], [[greco]], [[inequivoco]],
	-- [[intrinseco]], [[italigreco]], [[magnogreco]], [[meteco]], [[neogreco]], [[osco]] (either -ci or -chi),
	-- [[petulco]] (either -chi or -ci), [[plurivoco]], [[porco]], [[pregreco]], [[reciproco]], [[stenoeco]],
	-- [[tagicco]], [[univoco]], [[volsco]].
	elseif term:find("[cg]o$") then
		term = term:gsub("o$", "hi")
	elseif term:find("o$") then
		term = term:gsub("o$", "i")
	elseif term:find("[cg]a$") then
		check_no_mf()
		term = term:gsub("a$", (gender == "m" and "hi" or "he"))
	elseif term:find("logia$") then
		if gender ~= "f" then
			error("Term '" .. term .. "' ending in -logia should have gender=f if it is using the default plural")
		end
		term = term:gsub("a$", "e")
	elseif term:find("[cg]ia$") then
		check_no_mf()
		term = term:gsub("ia$", (gender == "m" and "i" or "e"))
	elseif term:find("a$") then
		check_no_mf()
		term = term:gsub("a$", (gender == "m" and "i" or "e"))
	elseif term:find("e$") then
		term = term:gsub("e$", "i")
	else
		return nil
	end
	return term
end

-- Generate a default feminine form.
function ex.make_feminine(term, special)
	local retval = call_handle_multiword(term, special, ex.make_feminine)
	if retval then
		return retval
	end

	-- Don't directly return gsub() because then there will be multiple return values.
	if term:find("o$") then
		term = term:gsub("o$", "a")
	elseif term:find("tore$") then
		term = term:gsub("tore$", "trice")
	elseif term:find("one$") then
		term = term:gsub("one$", "ona")
	end

	return term
end

-- Generate a default masculine form.
function ex.make_masculine(term, special)
	local retval = call_handle_multiword(term, special, ex.make_masculine)

	-- Don't directly return gsub() because then there will be multiple return values.
	if term:find("a$") then
		term = term:gsub("a$", "o")
	elseif term:find("trice$") then
		term = term:gsub("trice$", "tore")
	end

	return term
end

return ex