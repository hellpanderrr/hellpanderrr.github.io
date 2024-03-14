local export = {}
mw = require('mw')
local m_IPA = require("IPA")
local m_table = require("table")
local m_strutils = require("string utilities")
local m_qual = require("qualifier")
local u = mw.ustring.char
local rfind = mw.ustring.find
local rsubn = mw.ustring.gsub
local rmatch = mw.ustring.match
local rsplit = mw.text.split
local ulower = mw.ustring.lower
local uupper = mw.ustring.upper
local usub = mw.ustring.sub
local ulen = mw.ustring.len

local AC = u(0x0301) -- acute =  ́
local GR = u(0x0300) -- grave =  ̀ = open vowel quality without stress in Portugal only
local MACRON = u(0x0304) -- macron =  ̄ = closed vowel quality without stress in Portugal only
local CFLEX = u(0x0302) -- circumflex =  ̂
local TILDE = u(0x0303) -- tilde =  ̃
local DIA = u(0x0308) -- diaeresis =  ̈
local CEDILLA = u(0x0327) -- cedilla =  ̧
local DOTOVER = u(0x0307) -- dot over =  ̇
-- DOTUNDER indicates an explicitly unstressed syllable; useful when accompanied by a quality marker (acute or
-- circumflex), or by itself with a/e/o, where it defaults to acute (except in the following circumstances, where it
-- defaults to circumflex: (1) in the diphthongs ei/eu/oi/ou; (2) in a nasal vowel).
local DOTUNDER = u(0x0323) -- dot under =  ̣
-- LINEUNDER indicates an explicit secondary stress; normally not necessary as primary stress is converted to secondary
-- stress if another primary stress follows, but can be used e.g. after a primary stress; can be accompanied by a
-- quality marker (acute or circumflex) with a/e/o; if not, defaults to acute (except in the same circumstances where
-- dot under defaults to circumflex).
local LINEUNDER = u(0x0331) -- line under =  ̱
-- Serves to temorarily mark where a syllable division should not happen; temporarily substitutes for comma+space;
-- temporarily substitutes for #.
local TEMP1 = u(0xFFF0)
local SYLDIV = u(0xFFF1) -- used to represent a user-specific syllable divider (.) so we won't change it
local PSEUDOCONS = u(0xFFF2) -- pseudo-consonant at the edge of prefixes ending in a vowel and suffixes beginning with a vowel
local PREFIX_MARKER = u(0xFFF3) -- marker indicating a prefix so we can convert primary to secondary accents

-- Since we convert all symbols at the beginning and decompose accented characters (except for ç and ü), we can later
-- use capital and/or accented letters to represent additional distinctions, typically in cases where we want to
-- remember the source of a given phoneme. By convention we use capital letters, optionally with accents.
-- Specifically:
-- * A/E/O represent written a/e/o where we don't yet know the vowel quality. Towards the beginning, we convert all
--   written a/e/o to A/E/O and later convert them to their final qualities (which might include /a/ /e/ /o/, so we
--   can't use those symbols directly for this purpose).
-- * Ẽ stands for a word-initial Brazilian sound that can be pronounced either /ẽ/ (in careful speech) or /ĩ/ (in
--   natural speech) and originates from en- or em- before a consonant. We distinguish this from written in-/im-,
--   which can be only /ĩ/, and written ehn-/ehm- (or similar), which can be only /ẽ/.
-- * I is used to represent epenthetic i in Brazilian variants (which should not affect stress assignment but is
--   otherwise treated as a normal sound), and Ɨ represents deleted epenthetic i (which still palatalizes /t/ and /d/).
--   I is also used to represent Brazil e or i from initial esC-, and Portugal (i) from initial esC-.
-- * Ì is used to represent either i. in hiatus or /j/ in Brazil; likewise for Ù representing u. in hiatus or /w/.
-- * Ɔ (capital version of ɔ) stands for a Portugal sound that can be pronounced either /o/ or /ɔ/ (depending on the
--   speaker), before syllable-final /l/.
-- * Ú is used word-finally after i to represent either .u in hiatus or /w/ in Brazil.
-- * L is used word-finally in Portugal to split words ending in -le into two pronuns due to the differing pronunciation
--   of /l/ in the two cases (coda or not).
local vowel = "aɐeɛiɨoɔuüAEẼIƗÌOƆÙÚ"
local V = "[" .. vowel .. "]"
local NV_NOT_SPACING_CFLEX = "[^" .. vowel .. "%^]"
local high_front_vocalic = "iIƗÌy"
local front_vocalic = "eɛɨẼ" .. high_front_vocalic
local FRONTV = "[" .. front_vocalic .. "]"
-- W stands for regional /w/ between stressed /o/ and a following vowel in hiatus ([[voo]], [[boa]], [[perdoe]]).
local glide = "ywW"
local W = "[" .. glide .. "]" -- glide
local ipa_stress = "ˈˌ"
local ipa_stress_c = "[" .. ipa_stress .. "]"
local primary_quality = AC .. CFLEX
local primary_quality_c = "[" .. primary_quality .. "]"
local quality = AC .. CFLEX .. GR .. MACRON
local quality_c = "[" .. quality .. "]"
local stress = LINEUNDER .. DOTOVER .. DOTUNDER .. ipa_stress
local stress_c = "[" .. stress .. "]"
local non_primary_stress = LINEUNDER .. DOTUNDER .. "ˌ"
local non_primary_stress_c = "[" .. non_primary_stress .. "]"
local accent = quality .. stress .. TILDE
local accent_c = "[" .. accent .. "]"
-- Any component separator that should be "transparent" (i.e. ignored) during syllabification processes. This should
-- include a subset of the component_sep characters, currently + and * (which ++ is converted into).
local syl_transp_component_sep = "+*"
local syl_transp_component_sep_c = "[" .. syl_transp_component_sep .. "]"
-- Any character that should be "transparent" (i.e. ignored) during syllabification processes. This includes the
-- syllable-transparent component separators + and ++ (converted into *) as well as the tie character, which originates
-- from an apostrophe (e.g. [[barriga d'água]]).
local syl_transp = syl_transp_component_sep .. "‿"
local syl_transp_c = "[" .. syl_transp .. "]"
-- Zero or more syllable-transparent characters; used during syllabification.
local STC = syl_transp_c .. "*"
-- Component separators that are not transparent to syllabification. Includes colon (:), hyphen (-) and double hyphen
-- (--), which is converted internally to @.
local non_syl_transp_component_sep = ":@%-"
local non_syl_transp_component_sep_c = "[" .. non_syl_transp_component_sep .. "]"
-- "component_sep" means any symbol that may separate word components (not including #, which is added at a certain
-- point next to certain word components so that the adjacent characters are treated as if they are at word bounaries).
local component_sep = syl_transp_component_sep .. non_syl_transp_component_sep
local component_sep_c = "[" .. component_sep .. "]"
local word_or_component_sep_c = "[#" .. component_sep .. "]"
-- Syllable divider (auto-inserted or user-specified).
local syldiv = "." .. SYLDIV
local syldiv_c = "[" .. syldiv .. "]"
-- "charsep" means any symbol that may separate the individual characters that make up a word, and which should be
-- ignored for e.g. consonant-consonant assimilation processes. This currently includes accents and syllable dividers.
local charsep = accent .. syldiv
local charsep_c = "[" .. charsep .. "]"
-- Characters that may divide words, other than the tie (‿), which is transparent to syllabification.
local non_syl_transp_word_divider = " #"
-- All characters that may divide words.
local word_divider = non_syl_transp_word_divider .. "‿"
-- "wordsep_not_syl_transp" means the same as "wordsep" below but excludes syllable-transparent characters. It is used
-- in other collections of symbols (particularly when negated, so as to include syllable-transparent characters but
-- otherwise exclude word separators) rather than by itself.
local wordsep_not_syl_transp = charsep .. non_syl_transp_word_divider .. non_syl_transp_component_sep
-- "wordsep" means any symbol that may separate the individual characters that make up a word or may separate words or
-- components, and which should be ignored for e.g. consonant-consonant assimilation processes that operate across
-- words. This currently includes everything in "charsep" and "component_sep" plus symbols that may divide words.
local wordsep = wordsep_not_syl_transp .. syl_transp
local wordsep_c = "[" .. wordsep .. "]"
local C = "[^" .. vowel .. wordsep .. "_]" -- consonant
-- consonant or syllable-transparent component separator
local C_OR_SYL_TRANSP = "[^" .. vowel .. wordsep_not_syl_transp .. "_]"
local H_OR_SYL_TRANSP = "[h" .. syl_transp .. "]"
local H_GLIDE_OR_SYL_TRANSP = "[h" .. glide .. syl_transp .. "]"
local C_NOT_H_OR_GLIDE = "[^h" .. glide .. vowel .. wordsep .. "_]" -- consonant other than h, w or y
local C_OR_WORD_BOUNDARY = "[^" .. vowel .. charsep .. "_]" -- consonant or word boundary
local voiced_cons = "bdglʎmnɲŋrɾʁvzjʒʤ" -- voiced sound

-- Unstressed words with vowel reduction in Brazil and Portugal.
local unstressed_words = require("table").listToSet({
	"o", "os", -- definite articles
	"me", "te", "se", "lhe", "lhes", "nos", "vos", -- unstressed object pronouns
	-- See https://en.wikipedia.org/wiki/Personal_pronouns_in_Portuguese#Contractions_between_clitic_pronouns
	"mo", "mos", "to", "tos", "lho", "lhos", -- object pronouns combined with articles
	-- Allomorphs of articles after certain consonants
	"lo", "los", "no", -- [[nos]] above as object pronoun
	-- Allomorphs of object pronouns before other pronouns
	"vo", -- [[no]] above as allomorph of article
	"que", -- subordinating conjunctions
	"e", -- coordinating conjunctions
	"de", "do", "dos", "por", -- basic prepositions + combinations with articles; [[no]], [[nos]] above already
	-- FIXME: Portugal pronun for pelos, pela, pelas given as if spelled pêlos, etc. with stress, but differently for pelo.
	-- I am assuming the Portugal pronuns with stress are wrong.
	"pelo", "pelos", "pela", "pelas" -- preposition + article combinations
})

-- Unstressed words with vowel reduction in Portugal only.
local unstressed_full_vowel_words_brazil = require("table").listToSet({
	"a", "as", -- definite articles
	-- See https://en.wikipedia.org/wiki/Personal_pronouns_in_Portuguese#Contractions_between_clitic_pronouns
	"ma", "mas", "ta", "tas", "lha", "lhas", -- object pronouns combined with articles
	-- Allomorphs of articles after certain consonants
	"la", "las", "na", "nas",
	"da", "das", -- basic prepositions + combinations with articles; [[na]], [[nas]] above already
	-- coordinating conjunctions; [[mas]] above already
})

-- Unstressed words without vowel reduction.
local unstressed_full_vowel_words = require("table").listToSet({
	"um", "uns", -- single-syllable indefinite articles
	"meu", "teu", "seu", "meus", "teus", "seus", -- single-syllable possessives
	"ou", -- coordinating conjunctions
	-- Note that in order to match à and às we have to write them as below because at the point we are trying to
	-- match them, all text has been converted to canonical decomposed Unicode form. Writing "à" and "às" directly
	-- won't work even if you type in the text using decomposed Unicode characters because all page contents are
	-- automatically converted to canonical composed form when saved.
	"ao", "aos", "a" .. GR, "a" .. GR .. "s", -- basic prepositions + combinations with articles
	"em", "com", -- other prepositions
})

-- Special-case pronunciations for certain unstressed words with irregular pronunciations. The left side is the
-- original spelling after DOTUNDER or DOTOVER has been added; which diacritic gets added depends on whether the word
-- has vowel reduction (DOTOVER) or no vowel reduction (DOTUNDER). The right side is the respelling. See comment just
-- above for why we write "a" .. GR instead of "à".
local unstressed_pronunciation_substitution = {
	["a" .. DOTUNDER .. "o"] = "a" .. DOTUNDER .. "u",
	["a" .. DOTUNDER .. "os"] = "a" .. DOTUNDER .. "us",
	["a" .. GR .. DOTUNDER] = "a" .. DOTUNDER,
	["a" .. GR .. DOTUNDER .. "s"] = "a" .. DOTUNDER .. "s",
	["po" .. DOTOVER .. "r"] = "pu" .. DOTOVER .. "r",
}

-- Dialects and subdialects:
export.all_styles = {"gbr", "rio", "sp", "sbr", "gpt", "cpt", "spt"}
export.all_style_groups = {
	all = export.all_styles,
	br = {"gbr", "rio", "sp", "sbr"},
	pt = {"gpt", "cpt", "spt"},
}

local style_to_style_group = {}
for group, styles in pairs(export.all_style_groups) do
	if group ~= "all" then
		for _, style in ipairs(styles) do
			style_to_style_group[style] = group
		end
	end
end

export.all_style_descs = {
	-- style groups
	br = "[[w:Brazilian_Portuguese|Brazil]]",
	pt = "[[w:European_Portuguese|Portugal]]",

	-- styles
	gbr = "[[w:Brazilian_Portuguese|Brazil]]", -- "general" Brazil
	rio = "[[w:Carioca#Sociolect|Rio de Janeiro]]", -- Carioca accent
	sp = "[[w:Paulistano_dialect|São Paulo]]", -- Paulistano accent
	sbr = "Southern Brazil", -- (not added yet)
	gpt = "[[w:European_Portuguese|Portugal]]", -- "general" Portugal
	-- lisbon = "Lisbon", -- (not added yet)
	cpt = "Central Portugal", -- Central Portugal outside of Lisbon
	spt = "Southern Portugal"
}


-- version of rsubn() that discards all but the first return value
local function rsub(term, foo, bar)
	local retval = rsubn(term, foo, bar)
	return retval
end

-- version of rsubn() that returns a 2nd argument boolean indicating whether
-- a substitution was made.
local function rsubb(term, foo, bar)
	local retval, nsubs = rsubn(term, foo, bar)
	return retval, nsubs > 0
end

-- apply rsub() repeatedly until no change
local function rsub_repeatedly(term, foo, bar)
	while true do
		local new_term = rsub(term, foo, bar)
		if new_term == term then
			return term
		end
		term = new_term
	end
end


-- Flat-map a function `fun` over `items`. This is like `map` over a sequence followed by `flatten`, i.e. the function
-- must itself return a sequence and all of the returned sequences are flattened into a single sequence.
local function flatmap(items, fun)
	local new = {}
	for _, item in ipairs(items) do
		local results = fun(item)
		for _, result in ipairs(results) do
			table.insert(new, result)
		end
	end
	return new
end


-- Combine two sets of qualifiers, either of which may be nil or a list of qualifiers. Remove duplicate qualifiers.
-- Return value is nil or a list of qualifiers.
local function combine_qualifiers(qual1, qual2)
	if not qual1 then
		return qual2
	end
	if not qual2 then
		return qual1
	end
	local qualifiers = m_table.deepcopy(qual1)
	for _, qual in ipairs(qual2) do
		m_table.insertIfNot(qualifiers, qual)
	end
	return qualifiers
end


-- Reorder the diacritics (accent marks) in `text` according to a canonical order. Specifically, there can conceivably
-- be up to three accents on a vowel: a quality mark (acute/circumflex/grave/macron); a mark indicating secondary stress
-- (lineunder), tertiary stress (dotunder; i.e. no stress but no vowel reduction) or forced vowel reduction (dotover);
-- and a nasalization mark (tilde). Order them as follows: quality - stress - nasalization. `err` is a function of one
-- argument (an error string) and should throw an error if called.
local function reorder_accents(text, err)
	local function reorder_accent_string(accentstr)
		local accents = rsplit(accentstr, "")
		local accent_order = {
			[AC] = 1,
			[CFLEX] = 1,
			[GR] = 1,
			[MACRON] = 1,
			[LINEUNDER] = 2,
			[DOTUNDER] = 2,
			[DOTOVER] = 2,
			[TILDE] = 3,
		}
		table.sort(accents, function(ac1, ac2)
			return accent_order[ac1] < accent_order[ac2]
		end)
		return table.concat(accents)
	end
	text = rsub(text, "(" .. accent_c .. "+)", reorder_accent_string)
	-- Remove duplicate accents.
	text = rsub_repeatedly(text, "(" .. accent_c .. ")%1", "%1")
	-- Make sure we don't have more than one of a given class.
	if rfind(text, quality_c .. quality_c) then
		err("Two different quality diacritics cannot occur together")
	end
	if rfind(text, stress_c .. stress_c) then
		err("Two different stress diacritics cannot occur together")
	end
	-- Only a/e/o can receive a circumflex, grave or macron.
	if rfind(text, "[^aeo][" .. CFLEX .. GR .. MACRON .. "]") then
		err("Only a/e/o can be followed by circumflex, grave or macron")
	end
	return text
end


-- Generate partial IPA for a single preprocessed term respelling `text` in the specified `style` ('gbr', 'rio', etc.;
-- see all_style_descs above). If `phonetic` is given, generate phonetic output, otherwise phonemic output. `err` is a
-- function of one argument (an error string) and should throw an error if called. This function is a subfunction of
-- `IPA` and cannot really be used by itself, because it generates output containing special symbols that need to be
-- postprocessed into multiple outputs (and in addition some other final postprocessing needs to happen, e.g. to get
-- stress marks in the right place). The function `IPA` is available be called externally.
local function one_term_ipa(text, style, phonetic, err)
	-- NOTE: In the code below we assume all styles are either Brazil or Portugal, and hence we can check for Portugal
	-- using `if not brazil`. If we ever add a non-Brazil non-Portugal style, we will have to revisit the code below.
	local brazil = m_table.contains(export.all_style_groups.br, style)

	-- Initial x -> /ʃ/: [[xérox]], [[xilofone]], [[xadrez]], etc.
	text = rsub(text, "(" .. word_or_component_sep_c .. ")x", "%1ʃ")
	-- Final x -> /ks/ ([[clímax]], [[xérox]], [[córtex]], [[hélix]], [[durex]], [[lux]], etc.), but for now we map to
	-- X because later on we open unstressed vowels before final x.
	text = rsub(text, "x(" .. word_or_component_sep_c .. ")", "X%1")
	-- x after certain dipthongs (ai, ei, oi, ou) and after -en- should be /ʃ/. Other diphthongs before x are rare
	-- and mostly learned and we need to force explicit respelling.
	text = rsub(text, "(([aeo])" .. charsep_c .. "*([iun])" .. charsep_c .. "*)x",
		function(all, a, b)
			local ab = a .. b
			-- [[baixo]], [[peixe]], [[troixa]], [[frouxo]], [[enxame]], etc.
			if ab == "ai" or ab == "ei" or ab == "oi" or ab == "ou" or ab == "en" then
				return all .. "ʃ"
			else
				return all .. "x"
			end
		end)
	-- -exC- should be pronounced like -esC- in Brazil but -eisC- in Portugal. Cf. excelente, experiência, têxtil,
	-- êxtase. Not with other vowels (cf. [[Felixlândia]], [[Laxmi]], [[Oxford]]).
	-- FIXME: Maybe this applies only to Lisbon and environs?
	text = rsub(text, "(e" .. accent_c .. "*)x(" .. C .. ")", function(v, c)
		if brazil then
			return v .. "s" .. c
		elseif c == "s" then
			return v .. "isç"
		else
			return v .. "is" .. c
		end
	end)
	if rfind(text, "x") then
		err("x must be respelled z, sh, cs, ss or similar")
	end

	-- combinations with h; needs to precede handling of c and s, and needs to precede syllabification so that
	-- the consonant isn't divided from the following h.
	text = rsub(text, "([scln])h", {["s"]="ʃ", ["c"]="ʃ", ["n"]="ɲ", ["l"]="ʎ" })

	-- remove initial <h>
	text = rsub(text, "(" .. word_or_component_sep_c .. ")h([^" .. accent .. "])", "%1%2")

	-- c, g, q
	-- This should precede syllabification especially so that the latter isn't confused by gu, qu, gü, qü
	-- also, c -> ç before front vowel ensures that cc e.g. in [[cóccix]], [[occitano]] isn't reduced to single c.
	text = rsub(text, "c(" .. FRONTV .. ")", "ç%1")
	text = rsub(text, "g(" .. FRONTV .. ")", "j%1")
	text = rsub(text, "gu(" .. FRONTV .. ")", "g%1")
	-- [[camping]], [[doping]], [[jogging]], [[Bangkok]], [[angstrom]], [[tungstênio]]
	text = rsub(text, "ng([^" .. vowel .. glide .. "hlr])", brazil and "n%1" or "ngh%1")
	text = rsub(text, "qu(" .. FRONTV .. ")", "k%1")
	text = rsub(text, "ü", "u") -- [[agüentar]], [[freqüentemente]], [[Bündchen]], [[hübnerita]], etc.
	text = rsub(text, "([gq])u(" .. V .. ")", "%1w%2") -- [[quando]], [[guarda]], etc.
	text = rsub(text, "[cq]", "k") -- [[Qatar]], [[burqa]], [[Iraq]], etc.

	-- y -> i between non-vowels, cf. [[Itamaraty]] /i.ta.ma.ɾa.ˈt(ʃ)i/, [[Sydney]] respelled 'Sýdjney' or similar
	-- /ˈsid͡ʒ.nej/ (Brazilian). Most words with y need respelling in any case, but this may help.
	text = rsub(text, "(" .. C_OR_WORD_BOUNDARY .. ")y(" .. accent_c .. "*" .. C_OR_WORD_BOUNDARY .. ")", "%1i%2")

	-- Reduce double letters to single, except for rr, mm, nn and ss, which map to special single sounds. Do this
	-- before syllabification so double letters don't get divided across syllables. The case of cci, cce is handled
	-- above. nn always maps to /n/ and mm to /m/ and can be used to force a coda /n/ or /m/. As a result,
	-- [[connosco]] will need respelling 'comnôsco', 'cõnôsco' or 'con.nôsco', and [[comummente]] will similarly
	-- need respelling e.g. as 'comum.mente' or 'comũmente'. Examples of words with double letters (Brazilian
	-- pronunciation):
	-- * [[Accra]] no respelling needed /ˈa.kɾɐ/;
	-- * [[Aleppo]] respelled 'Aléppo' /aˈlɛ.pu/;
	-- * [[buffer]] respelled 'bâfferh' /ˈbɐ.feʁ/;
	-- * [[cheddar]] respelled 'chéddarh' /ˈʃɛ.daʁ/;
	-- * [[Hanna]] respelled 'Ranna' /ˈʁɐ̃.nɐ/;
	-- * [[jazz]] respelled 'djézz' /ˈd͡ʒɛs/;
	-- * [[Minnesota]] respelled 'Minnessôta' /mi.neˈso.tɐ/;
	-- * [[nutella]] respelled 'nutélla' /nuˈtɛ.lɐ/;
	-- * [[shopping]] respeled 'shópping' /ˈʃɔ.pĩ/ or 'shóppem' /ˈʃɔ.pẽj̃/;
	-- * [[Stonehenge]] respelled 'Sto̱wnn.rrendj' /ˌstownˈʁẽd͡ʒ/;
	-- * [[Yunnan]] no respelling needed /juˈnɐ̃/.
	--
	-- Note that further processing of r and s happens after syllabification and stress assignment, because we need
	-- e.g. to know the distinction between final -s and -z to assign the stress properly.
	text = rsub(text, "rr", "ʁ")
	text = rsub(text, "nn", "N")
	text = rsub(text, "mm", "M")
	-- Deleted epenthetic /i/ should prevent preceding /m/, /n/ from being converted into nasalization.
	text = rsub(text, "mƗ", "MƗ")
	text = rsub(text, "nƗ", "NƗ")
	-- Will map later to /s/; need to special case to support spellings like 'nóss' (= nós, plural of nó).
	text = rsub(text, "ss", "S")
	text = rsub(text, "(" .. C .. ")%1", "%1")

	-- muit- is special and contains nasalization. Do before palatalization of t/d so [[muitíssimo]] works.
	text = rsub(text, "(" .. word_or_component_sep_c .. "mu" .. stress_c .. "*)(it)", "%1" .. TILDE .. "%2")

	-- Palatalize t/d + Ɨ -> affricates in Brazil. Use special unitary symbols, which we later convert to regular affricate
	-- symbols, so we can distinguish palatalized d from written dj. We only do Ɨ now so we can delete it; we do another
	-- palatalization round towards the end after raising e -> i.
	local palatalize_td = {["t"] = "ʧ", ["d"] = "ʤ"}
	if brazil then
		text = rsub(text, "([td])(" .. word_or_component_sep_c .. "*Ɨ)",
			function(td, high_vocalic) return palatalize_td[td] .. high_vocalic end)
		-- Now delete the symbol for deleted epenthetic /i/; it still triggers palatalization of t and d.
		text = rsub(text, "Ɨ", "")
	end
	-- Divide words into syllables.
	-- First, change user-specified . into a special character so we won't move it around. We need to keep this
	-- going forward until after we place the stress, so we can correctly handle initial i- + vowel, as in [[ia]],
	-- [[iate]] and [[Iaundé]]. We need to divide [[ia]] as 'i.a' but [[iate]] as 'ia.te' and [[Iaundé]] as 'Ia.un.dé'.
	-- In the former case, the stress goes on i but in the latter cases not; so we always divide <ia> as 'i.a',
	-- and then after stress assignment remove the syllable divider if the <i> isn't stressed. The tricky thing is
	-- that we want to allow the user to override this by explicitly adding a . between the <i> and <a>. So we need
	-- to keep the distinction between user-specified . and auto-determined . until after stress assignment.
	text = rsub(text, "%.", SYLDIV)
	-- We have various characters indicating divisions between word components where we want to treat the components
	-- more or less like separate words (e.g. -mente, -zinho/-zinha). Some such "characters" are digraphs, which we
	-- convert internally to single characters to simplify the code. Here, -- separates off -mente/-zinho/-zinha and
	-- ++ separates off prefixes. We want to ignore at least + and ++ (converted to *) for syllabification purposes.
	text = rsub(text, "%-%-", "@")
	text = rsub(text, "%+%+", "*")

	-- Respell [[homenzinho]] as 'homemzinho' so it is stressed correctly.
	text = rsub(text, "n(" .. SYLDIV .. "?ziɲos?" .. word_or_component_sep_c .. ")", "m%1")

	-- Divide before the last consonant (possibly followed by a glide). We then move the syllable division marker
	-- leftwards over clusters that can form onsets. Note that syllable-transparent component separators will always
	-- be (and will continue to be) to the left of syllable dividers rather than to the right, so we don't need to
	-- check for the latter situation.
	text = rsub_repeatedly(text, "(" .. V .. accent_c .. "*" .. C_OR_SYL_TRANSP .. "-)(" .. C .. H_GLIDE_OR_SYL_TRANSP .. "*" .. V .. ")", "%1.%2")
	text = rsub(text, "([pbtdkgfv]" .. H_OR_SYL_TRANSP .. "*)%.([lr])", ".%1%2")
	if not brazil then
		-- "Improper" clusters of non-sibiliant-obstruent + obstruent (pt, bt, bd, dk, kt; ps, bs, bv, bʒ, tz, dv, ks;
		-- ft), non-sibiliant-obstruent + nasal (pn, bn, tm, tn, dm, dn, gm, gn), nasal + nasal (mn) are syllabified in
		-- Portugal as .pt, .bv, .mn, etc. Note ʃ.t, ʃ.p, ʃ.k, etc. But in Brazil, all of these divide between the
		-- consonants (p.t, b.v, ʃ.t, s.p, etc.). Particular case: [[ab-rogação]] divides as a.brr in Portugal but ab.rr
		-- in Brazil.
		text = rsub(text, "([pbtdkgfv]" .. H_OR_SYL_TRANSP .. "*)%.([pbtdkgfvsSçzʃʒjmMnNɲʎʁ])", ".%1%2")
		text = rsub(text, "([mM]" .. H_OR_SYL_TRANSP .. "*)%.([nN])", ".%1%2")
	else
		-- /tʃ/, /dʒ/ are normally single sounds, but adj- in [[adjetivo]], [[adjunto]] etc. should be 'ad.j'
		text = rsub(text, "(t" .. STC .. ")%.(ʃ)", ".%1%2")
		text = rsub(text, "(d" .. STC .. ")%.(j)", ".%1%2")
		text = rsub(text, "(" .. word_or_component_sep_c .. "a" .. STC .. ")%.(d" .. STC .. ")(j)", "%1%2.%3")
	end
	-- All vowels should be separated from adjacent vowels by a syllable division except
	-- (1) aeo + unstressed i/u, ([[saiba]], [[peixe]], [[noite]], [[Paulo]], [[deusa]], [[ouro]]), except when
	-- followed by nh or m/n/r/l + (non-vowel or word end), e.g. Bom.ba.im, ra.i.nha, Co.im.bra, sa.ir, but Jai.me,
	-- a.mai.nar, bai.le, ai.ro.so, quei.mar, bei.ra;
	-- (2) iu(s), ui(s) at end of word, e.g. fui, Rui, a.zuis, pa.riu, viu, sa.iu;
	-- (3) ão, ãe, õe.
	--
	-- The easiest way to handle this is to put a special symbol between vowels that should not have a syllable
	-- division between them.
	--
	-- First, put a syllable divider between [aeo].[iu][mnlr], as in [[Bombaim]], [[Coimbra]], [[saindo]], [[sair]],
	-- [[Iaundé]], [[Raul]]. Note that in cases like [[Jaime]], [[queimar]], [[fauna]], [[baile]], [[Paulo]], [[beira]],
	-- where a vowel follows the m/n/l/r, there will already be a syllable division between i.m, u.n, etc., which will
	-- block the following substitution.
	text = rsub(text, "([aeo]" .. accent_c .. "*" .. STC .. ")([iu]" .. STC .. "[mnlr])", "%1.%2")
	-- Also put a syllable divider between [aeo].[iu].ɲ coming from 'nh' ([[rainha]], [[moinho]]).
	text = rsub(text, "([aeo]" .. accent_c .. "*" .. STC .. ")([iu]" .. STC .. "%.ɲ)", "%1.%2")
	-- Prevent syllable division between final -ui(s), -iu(s). This should precede the following rule that prevents
	-- syllable division between ai etc., so that [[saiu]] "he left" gets divided as sa.iu.
	-- It doesn't make sense to have STC in the middle of a diphthong here.
	text = rsub(text, "(u" .. accent_c .. "*)(is?" .. word_or_component_sep_c .. ")", "%1" .. TEMP1 .. "%2")
	text = rsub(text, "(i" .. accent_c .. "*)(us?" .. word_or_component_sep_c .. ")", "%1" .. TEMP1 .. "%2")
	-- Prevent syllable division between ai, ou, etc. unless either the second vowel is accented [[saído]]) or there's
	-- a TEMP1 marker already after the second vowel (which will occur e.g. in [[saiu]] divided as 'sa.iu').
	text = rsub_repeatedly(text, "([aeo]" .. accent_c .. "*)([iu][^" .. accent .. TEMP1 .. "])", "%1" .. TEMP1 .. "%2")
	-- Prevent syllable division between nasal diphthongs unless somehow the second vowel is accented.
	text = rsub_repeatedly(text, "(a" .. accent_c .. "*" .. TILDE .. ")([eo][^" .. accent .. "])", "%1" .. TEMP1 .. "%2")
	text = rsub_repeatedly(text, "(o" .. accent_c .. "*" .. TILDE .. ")(e[^" .. accent .. "])", "%1" .. TEMP1 .. "%2")
	text = rsub_repeatedly(text, "(u" .. accent_c .. "*" .. TILDE .. ")(i[^" .. accent .. "])", "%1" .. TEMP1 .. "%2")
	-- All other sequences of vowels get divided.
	text = rsub_repeatedly(text, "(" .. V .. accent_c .. "*" .. STC .. ")(" .. V .. ")", "%1.%2")
	-- Remove the marker preventing syllable division.
	text = rsub(text, TEMP1, "")

	-- An acute or circumflex not followed by a stress marker has primary stress, so indicate it.
	text = rsub_repeatedly(text, "(" .. V .. quality_c .. ")([^" .. stress .. "])", "%1ˈ%2")
	-- Line-under indicates secondary stress.
	text = rsub(text, LINEUNDER, "ˌ")

	-- Add primary stress to the word if not already present.
	local function accent_word(word)
		-- Check if stress already marked. We check first for primary stress before checking for tilde in case both
		-- primary stress and tilde occur, e.g. [[bênção]], [[órgão]], [[hétmã]], [[connosco]] respelled 'cõnôsco'.
		if rfind(word, "ˈ") then
			return word
		end

		-- Preserve the syllable divider, which may be auto-added or user-specified.
		local syllables = m_strutils.capturing_split(word, "([." .. SYLDIV .. "])")

		-- Check for nasal vowel marked with tilde and without non-primary stress; assign stress to the last such
		-- syllable in case there's more than one tilde, e.g. [[pãozão]]. Note, this can happen in the part before
		-- -mente, cf. [[anticristãmente]], and before -zinho, cf. [[coraçãozinho]].
		for i = #syllables, 1, -2 do -- -2 because of the syllable dividers; see above.
			local changed
			syllables[i], changed = rsubb(syllables[i], "(" .. V .. quality_c .. "*)" .. TILDE, "%1ˈ" .. TILDE)
			if changed then
				return table.concat(syllables)
			end
		end

		-- Apply the default stress rule.
		local sylno
		-- Prefixes ending in a vowel such as pseudo- have a PSEUDOCONS after the final vowel, but we don't want that to
		-- interfere in the stress-assignment algorithm.
		if #syllables > 1 and (rfind(word, "[aeo][s" .. PSEUDOCONS .. "]?$") or rfind(word, "[ae]m$") or rfind(word, "[ae]ns$")) then
			-- Stress the last syllable but one. The -2 is because of the syllable dividers; see above.
			sylno = #syllables - 2
		else
			sylno = #syllables
		end
		-- Don't put stress on epenthetic i; instead, we stress the preceding syllable, as if epenthetic i weren't
		-- there.
		while sylno > 1 and rfind(syllables[sylno], "I") do
			sylno = sylno - 2
		end
		-- It is (vaguely) possible that we have a one-syllable word beginning with a complex cluster such as gn-
		-- followed by a normally unstressed ending such as -em. In this case, we want the ending to be stressed.
		while sylno < #syllables and rfind(syllables[sylno], "I") do
			sylno = syno + 2
		end
		-- If we are on a syllable without a vowel (can happen if it's the last syllable in a non-final component of a
		-- word, when using a component separator that is transparent to stress, such as in [[rapazinho]] respelled
		-- 'rapaz+inho'), stress the syllable to the left.
		while sylno > 1 and not rfind(syllables[sylno], V) do
			sylno = sylno - 2
		end
		if rfind(syllables[sylno], stress_c) then
			-- Don't do anything if stress mark already present. (Since we check for primary stress above, this check
			-- specifically affects non-primary stress.)
			return word
		end
		-- Add stress mark after first vowel (and any quality mark).
		syllables[sylno] = rsub(syllables[sylno], "^(.-" .. V .. quality_c .. "*)", "%1ˈ")
		return table.concat(syllables)
	end

	-- Split the text into words and the words into components so we can correctly add stress to components without it.
	local words = rsplit(text, " ")
	for j, word_with_boundary_markers in ipairs(words) do
		-- Prefixes have a PREFIX_MARKER after the # at the end of the prefix; split it off.
		local begin_marker, word, end_marker = rmatch(word_with_boundary_markers, "^(#*)(.-)([#" .. PREFIX_MARKER .. "]*)$")
		-- Words ends in -mente, -zinho(s) or -zinha(s); add primary stress to the preceding portion as if stressed
		-- (e.g. [[agitadamente]] -> 'agitádamente') unless already stressed (e.g. [[rapidamente]] respelled
		-- 'rápidamente'). The primary stress will be converted to secondary stress further below. Essentially, we
		-- rip the word apart into two words ('mente'/'zinho' and the preceding portion) and
		-- stress each one independently. Note that the effect of adding a primary stress will also be to cause
		-- an error if stressed 'e' or 'o' is not properly marked as é/ê or ó/ô; cf. [[certamente]], which must
		-- be respelled 'cértamente', and [[posteriormente]], which must be respelled 'posteriôrmente', just as
		-- with [[certa]] and [[posterior]]. To prevent this happening, you can add an accent to -mente or
		-- -zinho, e.g. [[dormente]] respelled 'dormênte', [[vizinho]] respelled 'vizínho'.
		if rfind(word, syldiv_c .. "men%.te$") then
			word = rsub(word, syldiv_c .. "(men%.te)$", "@%1")
		else
			word = rsub(word, syldiv_c .. "(zi%.ɲ[oa]s?)$", "@%1")
		end

		-- Split on components; preserve the component divider.
		local components = m_strutils.capturing_split(word, "(" .. component_sep_c .. syldiv_c .. "*)")
		for k = 1, #components, 2 do -- 2 because of the component dividers.
			-- Don't add stress to components followed by ++ (converted to *).
			if k == #components or not rfind(components[k + 1], "%*") then
				components[k] = accent_word(components[k])
			end
		end
		-- Reconstruct the word.
		words[j] = begin_marker .. table.concat(components, "") .. end_marker
	end

	-- Reconstruct the text from the words.
	text = table.concat(words, " ")

	-- Add word boundaries around component separators. We add them on both sides of - and -- (converted to @), which
	-- behave mostly like a true word separator, but only on the right side of other component separators (which
	-- corresponds to the beginning of the word following the separator). Note that some component separators (+ and ++
	-- [converted to *]) are transparent to syllable boundaries, meaning that there may be a syllable divider directly
	-- to the right of the component separator. To simplify the code below, we put the word boundary marker on the outside
	-- of the syllable boundary marker.
	text = rsub(text, "([%-@]" .. syldiv_c .. "?)", "#%1#")
	text = rsub(text, "([+:*]" .. syldiv_c .. "?)", "%1#")

	-- I has served its purpose (not considered when accenting).
	text = rsub(text, "I", "i")

	-- Remove hiatus between initial <i> and following vowel ([[Iasmim]]) unless the <i> is stressed ([[ia]]) or the
	-- user explicitly added a . (converted to SYLDIV above).
	text = rsub(text, "#i%.(" .. V .. ")", "#y%1")
	if brazil then
		-- In Brazil, hiatuses involving i. or u. have two possibilities (full vowel or glide); represent using Ì. and Ù.,
		-- which we later convert appropriately. Do this before eliminating SYLDIV so the user can force a hiatus using a
		-- period.
		local hiatus_to_optional_glide = {["i"] = "Ì", ["u"] = "Ù"}
		text = rsub(text, "(" .. C_OR_WORD_BOUNDARY .. ")([iu])(%." .. V .. ")",
			function(before, hiatus, after) return before .. hiatus_to_optional_glide[hiatus] .. after end)
		-- In Brazil, hiatuses of the form í.o (e.g. [[rio]] "river", [[vazio]]; but not [[rio]] "I laugh") have two
		-- possibilities (i.u or iw); represent using Ú, which we later convert appropriately. Do this before eliminating
		-- SYLDIV so the user can force a hiatus using a period, as in [[rio]] "I laugh" respelled 'ri.o'.
		text = rsub(text, "(i" .. ipa_stress_c .. "%.)o(s?#)", "%1Ú%2")
	else
		-- Outside of Brazil, e.i -> a.i, e.g. [[ateísta]], [[proteína]], [[proteinúrio]] respelled 'prote.inúrio'. But seems
		-- not to happen in rei- ([[reincidente]], [[reiniciar]], [[reidratar]], etc.). Note, it does occur in [[reídeo]],
		-- which needs respelling.
		text = rsub(text, "(#re" .. syldiv_c .. ")(i)", "%1" .. TEMP1 .. "%2")
		text = rsub(text, "e(" .. syldiv_c .. "i)", "a%1")
		text = rsub(text, TEMP1, "")
		-- Outside of Brazil, hiatuses involving 'e./i.' or 'o./u.' after obstruent + l/r preceding a vowel have two
		-- possibilities (full vowel or glide), as in [[criança]], [[altruista]], etc. Represent using Ì. and Ù., which
		-- we later convert appropriately. Do this before eliminating SYLDIV so the user can force a hiatus using a
		-- period.
		local hiatus_to_optional_glide = {["e"] = "Ì", ["i"] = "Ì", ["o"] = "Ù", ["u"] = "Ù"}
		text = rsub(text, "([pbtdkgfv]" .. H_OR_SYL_TRANSP .. "*[lr])([eiou])(%." .. V .. ")",
			function(before, hiatus, after) return before .. hiatus_to_optional_glide[hiatus] .. after end)
		-- Outside of Brazil, remove hiatus more generally whenever 'e./i.' or 'o./u.' precedes a vowel. Do this before
		-- eliminating SYLDIV so the user can force hiatus using a period.
		local hiatus_to_glide = {["e."] = "y", ["i."] = "y", ["o."] = "w", ["u."] = "w"}
		text = rsub(text, "(" .. C_OR_WORD_BOUNDARY .. ")([eiou]%.)(" .. V .. ")",
			function(before, hiatus, after) return before .. hiatus_to_glide[hiatus] .. after end)
	end

	-- Convert user-specified syllable division back to period. See comment above when we add SYLDIV.
	text = rsub(text, SYLDIV, ".")
	-- Vowel quality handling. First convert all a -> A, e -> E, o -> O. We will then convert A -> a/ɐ, E -> e/ɛ/ɨ,
	-- O -> o/ɔ/u depending on accent marks and context. Ultimately all vowels will be one of the nine qualities
	-- aɐeɛiɨoɔu and following each vowel will either be nothing (no stress), an IPA primary stress mark (ˈ) or an
	-- IPA secondary stress mark (ˌ), in turn possibly followed by a tilde (nasalization). After doing everything
	-- that depends on the position of stress, we will move the IPA stress marks to the beginning of the syllable.
	text = rsub(text, "[aeo]", {["a"] = "A", ["e"] = "E", ["o"] = "O"})
	text = rsub(text, DOTOVER, "") -- eliminate DOTOVER; it served its purpose of preventing stress

	-- Nasal vowel handling.
	-- Final unstressed -am (in third-person plural verbs) pronounced like unstressed -ão.
	text = rsub(text, "Am#", "A" .. TILDE .. "O#")
	if not brazil then
		-- In Portugal, final -n is really /n/, and preceding unstressed e/o are open ([[cólon]], [[crípton]], [[éon]];
		-- [[glúten]], [[hífen]], [[pólen]]).
		text = rsub(text, "n#", "N#")
		text = rsub(text, "([EO])(N#)", "%1" .. AC .. "%2")
	end
	if brazil then
		-- In Brazil, [[põem]] is pronounced like 'põe'.
		text = rsub(text, "(Oˈ" .. TILDE .. ")(Em#)", "%1E#")
	else
		-- In Portugal, circumflex accent on final -em ([[vêm]], [[mantêm]], etc.) indicates a special double nasal diphthong
		-- pronunciation.
		text = rsub(text, "E" .. CFLEX .. "ˈm#", "E" .. CFLEX .. "ˈ" .. TILDE .. "y" .. TILDE .. ".E" .. CFLEX .. "m#")
		-- In Portugal, [[põem]] is pronounced like 'põeem'.
		text = rsub(text, "(Oˈ" .. TILDE .. ")(Em#)", "%1E.%2")
	end
	-- Acute accent on final -em ([[além]], [[também]]) and final -ens ([[parabéns]]) does not indicate an open
	-- pronunciation.
	text = rsub(text, "E" .. AC .. "(ˈ[mn]s?#)", "E" .. CFLEX .. "%1")
	-- Vowel + m/n within a syllable gets converted to tilde.
	text = rsub(text, "(" .. V .. quality_c .. "*" .. stress_c .. "*)[mn]", "%1" .. TILDE)
	-- Non-high vowel without quality mark + tilde needs to get the circumflex (possibly fed by the previous change).
	text = rsub(text, "([AEO])(" .. stress_c .. "*)" .. TILDE, "%1" .. CFLEX .. "%2" .. TILDE)
	-- Primary-stressed vowel without quality mark + m/n/nh across syllable boundary gets a circumflex, cf. [[cama]],
	-- [[ano]], [[banho]].
	text = rsub(text, "(" .. V .. ")(ˈ%.[mnɲMN])", "%1" .. CFLEX .. "%2")
	if brazil then
		if style ~= "sbr" then -- Seems this happens less or not at all in South Brazil.
			-- Primary-stressed vowel + m/n across syllable boundary gets nasalized in Brazil, cf. [[cama]], [[ano]].
			text = rsub(text, "(" .. V .. quality_c .. "*)(ˈ%.[mnMN])", "%1" .. TILDE .. "%2")
		end
		-- All vowels before nh (always across syllable boundary) get circumflexed and nasalized in Brazil,
		-- cf. [[ganhar]]. I *think* the circumflexing but not nasalizing happens in South Brazil.
		text = rsub(text, "(" .. V .. stress_c .. "*)(%.ɲ)", "%1" .. CFLEX .. "%2")
		if style ~= "sbr" then -- I *think* this doesn't apply to South Brazil; need to verify.
			text = rsub(text, "(" .. V .. quality_c .. "*" .. stress_c .. "*)(%.ɲ)", "%1" .. TILDE .. "%2")
		end
		-- Convert initial unstressed em-/en- before consonant to special symbol /Ẽ/, which later on is converted
		-- to /e/ (careful pronunciation) or /i/ (natural pronunciation).
		text = rsub(text, "(#E" .. CFLEX .. TILDE ..")(%." .. C ..")", "#Ẽ" .. TILDE .. "%2")
		-- Same in [[em]] standing alone (which will have a DOTUNDER in it), and in [[em-]].
		text = rsub(text, "(#E" .. CFLEX .. DOTUNDER .. "?" .. TILDE ..")(#)", "#Ẽ" .. TILDE .. "%2")
	end

	-- Nasal diphthongs.
	local nasal_termination_to_glide = {["E"] = "y", ["O"] = "w"}
	-- In ãe, ão, the second letter represents a glide.
	text = rsub(text, "(A" .. CFLEX .. stress_c .. "*" .. TILDE .. ")([EO])",
		function(v1, v2) return v1 .. nasal_termination_to_glide[v2] .. TILDE end)
	-- Likewise for õe.
	text = rsub(text, "(O" .. CFLEX .. stress_c .. "*" .. TILDE .. ")E", "%1y" .. TILDE)
	-- Likewise for ũi (generated above from muit-).
	text = rsub(text, "(u" .. stress_c .. "*" .. TILDE .. ")i", "%1y" .. TILDE)
	-- Final -em and -ens (stressed or not) pronounced /ẽj̃(s)/. (Later converted to /ɐ̃j̃(s)/ in Portugal.)
	text = rsub(text, "(E" .. CFLEX .. stress_c .. "*" .. TILDE .. ")(s?#)", "%1y" .. TILDE .. "%2")

	-- Oral diphthongs.
	-- ei, eu, oi, ou -> êi, êu, ôi, ôu
	text = rsub(text, "([EO])(" .. stress_c .. "*[iuywY])", "%1" .. CFLEX .. "%2")
	-- ai, au -> ái, áu
	text = rsub(text, "(A)(" .. stress_c .. "*[iuywY])", "%1" .. AC .. "%2")

	-- Convert A/E/O as appropriate when followed by a secondary or tertiary stress marker. If a quality is given,
	-- it takes precedence; otherwise, act as if an acute accent were given.
	text = rsub(text, "([AEO])(" .. non_primary_stress_c .. ")", "%1" .. AC .. "%2")

	-- Stressed o in -dor, -dor, -sor ([[ganhador]], [[autor]], [[invasor]], [[agressor]], etc.) and feminines and plurals
	-- is closed /o/.
	text = rsub(text, "([dtsS])O(ˈr#)", "%1o%2")
	text = rsub(text, "([dtsS])O(ˈ%.r[EA]s?#)", "%1o%2")
	-- Stressed o in -oso is closed /o/.
	text = rsub(text, "O(ˈ%.sO#)", "o%1")
	-- Stressed o in -osa, -osos, -osas is open /ɔ/.
	text = rsub(text, "O(ˈ%.s[OA]s?#)", "ɔ%1")

	-- Unstressed syllables.
	-- Before final <x>, unstressed a/e/o are open, e.g. [[clímax]], [[córtex]], [[xérox]].
	text = rsub(text, "([AEO])(X)", "%1" .. AC .. "%2")
	-- Capital X has served its purpose, so replace it.
	text = rsub(text, "X", "kç")
	if brazil then
		if style ~= "sbr" then
			-- Final unstressed -e(s), -o(s) -> /i/ /u/ (including before -mente)
			local brazil_final_vowel = {["E"] = "i", ["O"] = "u"}
			text = rsub(text, "([EO])(s?#)", function(v, after) return brazil_final_vowel[v] .. after end)
			-- Word-final unstressed -a(s) -> /ɐ/ (not before -mente)
			text = rsub(text, "A(s?#[^@])", function(after) return "ɐ" .. after end)
			-- Word-final unstressed -ar -> /ɐr/ (e.g. [[açúcar]])
			text = rsub(text, "A(r#)", function(after) return "ɐ" .. after end)
		end
		-- Initial unmarked unstressed non-nasal e- + -sC- -> /i/ or /e/ ([[estar]], [[esmeralda]]). To defeat this,
		-- explicitly mark the <e> e.g. as <ệ> or <eh>. We reuse the special symbol /I/ for this purpose, which later
		-- on is converted to /i/ or /e/. In South Brazil, however, the raised /i/ variant doesn't seem to exist.
		if not rfind(text, "#Es.ç") then
			text = rsub(text, "#E(s" .. C .. "*%.)", style == "sbr" and "#e%1" or "#I%1")
		end
		-- Remaining unstressed a, e, o without quality mark -> /a/ /e/ /o/.
		local brazil_unstressed_vowel = {["A"] = "a", ["E"] = "e", ["O"] = "o"}
		text = rsub(text, "([AEO])([^" .. accent .. "])",
			function(v, after) return brazil_unstressed_vowel[v] .. after end)
	else
		-- In Portugal, final unstressed -r opens preceding a/e/o ([[dólar]], [[líder]], [[júnior]], [[inter-]]
		-- respelled 'ínter:...').
		text = rsub(text, "([AEO])(r" .. word_or_component_sep_c .. ")", "%1" .. AC .. "%2")
		-- In Portugal, unstressed a/e/o before coda l takes on an open quality. Note that any /l/ directly after a
		-- vowel must be a coda /l/ because otherwise there would be a syllable boundary marker.
		text = rsub(text, "([AEO])l", function(v)
			-- The symbol Ɔ is later converted to /o/ or /ɔ/.
			local vowel_to_before_l = {["A"] = "a", ["E"] = "ɛ", ["O"] = "Ɔ"}
			return vowel_to_before_l[v] .. "l"
		end)
		-- Unstressed 'ie' -> /jɛ/
		text = rsub(text, "yE([^" .. accent .. "])", "yɛ%1")
		-- Initial unmarked unstressed non-nasal e- + -sC- (seemingly also after des-, see Infopédia [[desestagnar]]) ->
		-- temporary symbol I (later changed to /(i)/, except after a vowel, in which case it is deleted). Note that /s/
		-- directly after a vowel must be a coda /s/ because otherwise there would be a syllable boundary marker.
		text = rsub(text, "#Es", "#Is")
		-- Initial unmarked unstressed non-nasal e- -> /i/, including after des-.
		text = rsub(text, "#E([^" .. accent .. "])", "#i%1")
		-- Initial unmarked unstressed non-nasal o- -> /ɔ/ if another vowel follows (not 'o', 'os' by themselves).
		text = rsub(text, "(#O)(.-#)", function(o, rest)
			if rfind(rest, "^[^" .. accent .. "]") and rfind(rest, V) then
				return "#ɔ" .. rest
			else
				return o .. rest
			end
		end)
		-- All other unmarked unstressed non-nasal e, o, a -> /ɨ/ /u/ /ɐ/
		local portugal_unstressed_vowel = {["A"] = "ɐ", ["E"] = "ɨ", ["O"] = "u"}
		text = rsub(text, "([AEO])([^" .. accent .. "])",
			function(v, after) return portugal_unstressed_vowel[v] .. after end)
	end

	-- Remaining vowels.
	-- All remaining a -> /a/ (should always be stressed).
	text = rsub(text, "A([^" .. quality .. "])", "a%1")
	-- Ignore quality markers on i, u; only one quality.
	text = rsub(text, "([iu])" .. quality_c, "%1")
	-- Convert a/e/o + quality marker appropriately.
	local vowel_quality = {
		["A" .. AC] = "a", ["A" .. CFLEX] = "ɐ",
		["E" .. AC] = "ɛ", ["E" .. CFLEX] = "e",
		["O" .. AC] = "ɔ", ["O" .. CFLEX] = "o",
	}
	text = rsub(text, "([AEO]" .. quality_c .. ")", vowel_quality)
	-- Stressed o in hiatus ([[voo]], [[boa]], [[perdoe]], etc.) is closed /o/.
	text = rsub(text, "O(ˈ%." .. V .. ")", "o%1")
	-- Stressed closed /o/ in Portugal in hiatus regionally has a following /w/. Indicate using W.
	if not brazil then
		text = rsub(text, "(oˈ%.)(" .. V .. ")", "%1W%2")
	end
	-- Any remaining E or O (always without quality marker) is an error.
	if rfind(text, "[EO]") then
		err("Stressed e or o not occurring nasalized or in a diphthong must be marked for quality using é/ê or ó/ô")
	end

	-- Finally, eliminate DOTUNDER, now that we have done all vowel reductions.
	text = rsub(text, DOTUNDER, "")

	if brazil then
		-- Epenthesize /(j)/ in [[faz]], [[mas]], [[três]], [[dez]], [[feroz]], [[luz]], [[Jesus]], etc. Note, this only
		-- triggers at actual word boundaries (not before -mente), and not on nasal vowels or diphthongs. To defeat this
		-- (e.g. in plurals), respell using 'ss' or 'hs'.
		text = rsub(text, "(" .. V .. "ˈ)([sz]#[^@])", "%1Y%2")
		-- Also should happen at least before + (cf. [[rapazinho]] respelled 'rapaz+inho', [[vozinha]] respelled
		-- 'vóz+inha').
		text = rsub(text, "(" .. V .. "ˈ)(%.?[sz]%+)", "%1Y%2")
		-- But should not happen after /i/.
		text = rsub(text, "iˈY", "iˈ")
	end
	-- 'S' here represents earlier ss. Word-finally it is used to prevent epenthesis of (j) and should behave
	-- like 's'. Elsewhere (between vowels) it should behave like 'ç'.
	text = rsub(text, "S#", "s#")
	text = rsub(text, "S", "ç")

	-- s, z
	-- s in trans + V -> z: [[transação]], [[intransigência]]
	text = rsub(text, "(trɐ" .. stress_c .. "*" .. TILDE .. ".)s(" .. V .. ")", "%1z%2")
	-- word final z -> s
	text = rsub(text, "z#", "s#")
	-- s is voiced between vowels (not nasalized) or between vowel and voiced consonant, including across word
	-- boundaries; may be fed by previous rule. We have to split this into two rules before /s/ should not be voiced
	-- between nasal vowel and another vowel ([[cansar]]) but should be voiced between nasal vowel and a voiced
	-- consonant ([[transgredir]]). Note that almost all occurrences of nasal vowel + s + voiced consonant are in
	-- trans- which potentially could be handled above, but there may be others, e.g. [[Flensburg]].
	text = rsub(text, "(" .. V .. stress_c .. "*Y?%.?)s(" .. wordsep_c .. "*h?[" .. vowel .. glide .. "])", "%1z%2")
	text = rsub(text, "(" .. V .. accent_c .. "*Y?%.?)s(" .. wordsep_c .. "*h?[" .. voiced_cons .. "])", "%1z%2")
	-- z before voiceless consonant, e.g. [[Nazca]]; c and q already removed
	text = rsub(text, "z(" .. wordsep_c .. "*[çfkpsʃt])", "s%1")
	if not brazil or style == "rio" then
		-- Outside Brazil except for Rio; s/z before consonant (including across word boundaries) or end of utterance -> ʃ/ʒ;
		-- but not word-initially (e.g. [[stressado]]).
		local shibilant = {["s"] = "ʃ", ["z"] = "j"}
		text = rsub(text, "([sz])(##)", function(sz, after) return shibilant[sz] .. after end)
		-- s/z are maintained word-initially but not following : or similar component boundary ([[antroposcopia]] respelled
		-- 'antrópò:scopia'). To implement this, insert TEMP1 directly before the s/z we want to preserve, then check for this
		-- TEMP1 not being present when converting to shibiliant, then remove TEMP1.
		text = rsub(text, "([# %-]#)([sz])", "%1" .. TEMP1 .. "%2")
		text = rsub_repeatedly(text, "([^" .. TEMP1 .. "])([sz])(" .. wordsep_c .. "*" .. C_NOT_H_OR_GLIDE .. ")",
			function(before, sz, after) return before .. shibilant[sz] .. after end)
		text = rsub(text, TEMP1, "")
	end
	text = rsub(text, "ç", "s")
	text = rsub(text, "j", "ʒ")
	-- Reduce identical sibilants/shibilants, including across word boundaries.
	text = rsub(text, "([szʃʒ])(" .. wordsep_c .. "*)(%1)", "%2%1")
	if style == "rio" then
		-- Also reduce shibilant + sibilant ([[descer]], [[as]] [[zonas]]); not in Portugal, but in Portugal we later
		-- generate two outputs in this case, either /ʃs/ and /ʒz/ (careful pronunciation) or /ʃ/ and /ʒ/ (natural
		-- pronunciation). Note that the reduction of /ʃs/ to /ʃ/ in Portugal is different from the reduction of the
		-- same to /s/ in Brazil.
		text = rsub(text, "ʃ(" .. wordsep_c .. "*s)", "%1")
		text = rsub(text, "ʒ(" .. wordsep_c .. "*z)", "%1")
	end

	-- N/M from double n/m
	text = rsub(text, "[NM]", {["N"] = "n", ["M"] = "m"})

	-- r
	-- Double rr -> ʁ already handled above.
	-- Initial r or l/n/s/z + r -> strong r (ʁ).
	text = rsub(text, "([#" .. TILDE .. "lszʃʒ]%.?)r", "%1ʁ")
	if brazil then
		-- Word-final r before vowel in verbs is /(ɾ)/.
		text = rsub(text, "([aɛei]ˈ)r(#" .. wordsep_c .. "*h?" .. V .. ")", "%1(ɾ)%2")
		-- Coda r before vowel is /ɾ/.
		text = rsub(text, "r([.#]" .. wordsep_c .. "*h?" .. V .. ")", "ɾ%1")
	end
	-- Word-final r in Brazil in verbs (not [[pôr]]) is usually dropped. Use a spelling like 'marh' for [[mar]]
	-- to prevent this. Make sure not to do this before -mente/-zinho ([[polegarzinha]], [[popularmente]]).
	if brazil then
		text = rsub(text, "([aɛei]ˈ)r(#[^@])",
			"%1(" .. (style == "sp" and "ɾ" or style == "sbr" and "ɻ" or "ʁ") .. ")%2")
		if style ~= "sp" then
			-- Coda r in Southern Brazil is [ɻ], otherwise outside of São Paulo is /ʁ/.
			text = rsub(text, "r(" .. C .. "*[.#])", (style == "sbr" and "ɻ" or "ʁ") .. "%1")
		end
	end
	-- All other r -> /ɾ/.
	text = rsub(text, "r", "ɾ")
	if brazil and phonetic then
		-- "Strong" ʁ before voiced consonant is [ɦ] in much of Brazil, [ʁ] in Rio. Use R as a temporary symbol.
		text = rsub(text, "ʁ(" .. wordsep_c .. "*[" .. voiced_cons .. "])", style == "rio" and "R%1" or "ɦ%1")
		-- Other "strong" ʁ is [h] in much of Brazil, [χ] in Rio. Use H because later we remove all <h>.
		text = rsub(text, "ʁ", style == "rio" and "χ" or "H")
		text = rsub(text, "R", "ʁ")
	end
	
	-- Diphthong <ei>
	if brazil then
		-- In Brazil, add optional /j/ in <eir>, <eij>, <eig> and <eix> (as in [[cadeira]], [[beijo]], [[manteiga]] and
		-- [[peixe]]).
		text = rsub(text, "(e" .. accent_c .. "*)i(%.[ɾʒgʃ])", "%1(j)%2")
		-- [In Brazil, add optional /j/ in <aix> (as in [[caixa]] and [[baixo]]).] -- This was added by an IP, see
		-- [[Special:Contributions/186.212.6.138]]; this seems non-standard to me. If we are to include it, it should
		-- not be done this way, but as two separate outputs with the one lacking the /j/ marked with a qualifier such
		-- as "non-standard"; compare the way the initial enC- is handled (near the end of export.IPA()), where there
		-- are two outputs, with /ẽC-/ marked as "careful pronunciation" and /ĩC-/ marked as "natural pronunciation".
		-- (Benwing2)
		-- text = rsub(text, "(a" .. accent_c .. "*)i(%.ʃ)", "%1(j)%2")
	elseif style == "spt"  then
		-- In South of Portugal, <ei>, <ou> monophthongizes to <e>, <o>
		text = rsub(text, "(e" .. accent_c .. "*)i", "%1")
		text = rsub(text, "(o" .. accent_c .. "*)u", "%1")
	elseif style == "gpt" then
		-- In general Portugal, lower e/ɛ -> ɐ before i in <ei>/<ɛi>.
		text = rsub(text, "[eɛ](" .. accent_c .. "*i)", "ɐ%1")
		-- In general Portugal, lower e -> ɐ before j, including when nasalized.
		text = rsub(text, "e(" .. accent_c .. "*%.?y)", "ɐ%1")
		-- In general Portugal, lower e -> ɐ(j) before other palatals.
		text = rsub(text, "e(" .. stress_c .. "*)(%.?[ʒʃɲʎ](" .. V .. "))", phonetic and "ɐ%1(ɪ̯)%2" or "ɐ%1(j)%2")
	end

	-- Stop consonants.
	if brazil then
		-- Palatalize t/d + i/y -> affricates in Brazil.
		text = rsub(text, "([td])(" .. word_or_component_sep_c .. "*[" .. high_front_vocalic .. "])",
			function(td, high_vocalic) return palatalize_td[td] .. high_vocalic end)
	elseif phonetic then
		-- Fricativize voiced stops in Portugal when not utterance-initial or after a nasal; also not in /ld/.
		-- Easiest way to do this is to convert all voiced stops to fricative and then back to stop in the
		-- appropriate contexts.
		local fricativize_stop = { ["b"] = "β", ["d"] = "ð", ["g"] = "ɣ" }
		local occlude_fricative = { ["β"] = "b", ["ð"] = "d", ["ɣ"] = "g" }
		text = rsub(text, "[bdg]", fricativize_stop)
		text = rsub(text, "##([βðɣ])", function(bdg) return "##" .. occlude_fricative[bdg] end)
		text = rsub(text, "(" .. TILDE .. wordsep_c .. "*)([βðɣ])", function(before, bdg) return before .. occlude_fricative[bdg] end)
		text = rsub(text, "(l" .. wordsep_c .. "*)ð", "%1d")
	end

	-- Glides and l. ou -> o(w) must precede coda l -> w in Brazil, because <ol> /ow/ cannot be reduced to /o/.
	-- ou -> o(w) before conversion of remaining diphthongs to vowel-glide combinations so <ow> can be used to
	-- indicate a non-reducible glide.
	-- Optional /w/ in <ou>.
	text = rsub(text, "(o" .. accent_c .. "*)u", "%1(w)")
	-- Handle coda /l/.
	if brazil then
		-- Coda l -> /w/ in Brazil.
		text = rsub(text, "l(" .. C .. "*[.#])", "w%1")
	elseif phonetic then
		-- Coda l -> [ɫ] in Portugal.
		text = rsub(text, "l(" .. C .. "*[.#])", "ɫ%1")
	end
	text = rsub(text, "y", "j")
	if brazil then
		text = rsub(text, "Y", "(j)") -- epenthesized in [[faz]], [[três]], etc.
	else
		-- 'I' in Portugal represents word-initial (i) before sC, except after /i/ (e.g. [[antiestático]]), in which
		-- case it is elided. In the latter case, we need to elide the word/component separators, otherwise we end up
		-- with an extra syllable divider: /ˌɐ̃.ti.ʃˈta.ti.ku/ instead of correct /ˌɐ̃.tiʃˈta.ti.ku/.
		text = rsub(text, "(i" .. accent_c .. "*)" .. word_or_component_sep_c .. "*#I", "%1")
		text = rsub(text, "I", "(i)")
	end
	local vowel_termination_to_glide = brazil and phonetic and
		{["i"] = "ɪ̯", ["j"] = "ɪ̯", ["u"] = "ʊ̯", ["w"] = "ʊ̯"} or
		{["i"] = "j", ["j"] = "j", ["u"] = "w", ["w"] = "w"}
	-- i/u as second part of diphthong becomes glide.
	text = rsub(text, "(" .. V .. accent_c .. "*" .. "%(?)([ijuw])",
		function(v1, v2) return v1 .. vowel_termination_to_glide[v2] end)

	-- nh
	if brazil and phonetic and style ~= "sbr" then
		-- [[unha]] pronounced [ˈũ.j̃ɐ]; nasalization of previous vowel handled above. But initial nh- e.g. [[nhaca]],
		-- [[nheengatu]], [[nhoque]] is [ɲ]. I *think* this doesn't happen in South Brazil. We do have the phonetic
		-- representation [ẽj̃.pũˈj̃aɾ] given for [[empunhar]], but this is the only such case and may be a mistake.
		text = rsub(text, "([^#])ɲ", "%1j" .. TILDE)
	end

	if not brazil then
		-- Suppress final -ɨ before a vowel, and make optional utterance-finally.
		text = rsub(text, "ɨ#[ %-]#(" .. V .. ")", "‿%1")
		text = rsub(text, "ɨ##", "(ɨ)##")
		-- (ɨ) after l when suppressed should convert to coda ɫ, so split it later into two pronuns.
		text = rsub(text, "l%(ɨ%)##", "L##")
	end

	text = rsub(text, "g", "ɡ") -- U+0261 LATIN SMALL LETTER SCRIPT G
	text = rsub(text, "[ʧʤ]", {["ʧ"] = "t͡ʃ", ["ʤ"] = "d͡ʒ"})
	text = rsub(text, "tʃ", "t͡ʃ")
	text = rsub(text, "dʒ", "d͡ʒ")
	text = rsub(text, "h", "")
	text = rsub(text, "H", "h")

	return text
end


-- Generate the IPA for a single term respelling `text` in the specified `style` ('gbr', 'rio', etc.; see
-- all_style_descs above). Return value is a list of objects of the following form:
--   { phonemic = STRING, phonetic = STRING, qualifiers = {STRING, ...} }
-- Note that the returned qualifiers are only those generated automatically as a result of certain characteristics of
-- the respelling, e.g. in Brazil initial em-/en- + consonant has two outputs, one labeled "careful pronunciation" and
-- the other "natural pronunciation". User-specified qualifiers are added at the end by the caller of IPA(), and
-- prepended to the auto-generated qualifiers.
function export.IPA(text, style)
	-- NOTE: In the code below we assume all styles are either Brazil or Portugal, and hence we can check for Portugal
	-- using `if not brazil`. If we ever add a non-Brazil non-Portugal style, we will have to revisit the code below.
	local brazil = m_table.contains(export.all_style_groups.br, style)

	local origtext = text

	local function err(msg)
		error(msg .. ": " .. origtext)
	end

	text = ulower(text)
	-- decompose everything but ç and ü
	text = mw.ustring.toNFD(text)
	text = rsub(text, ".[" .. CEDILLA .. DIA .. "]", {
		["c" .. CEDILLA] = "ç",
		["u" .. DIA] = "ü",
	})
	text = reorder_accents(text, err)

	-- convert commas and en/en dashes to IPA foot boundaries
	text = rsub(text, "%s*[,–—]%s*", " | ")
	-- question mark or exclamation point in the middle of a sentence -> IPA foot boundary
	text = rsub(text, "([^%s])%s*[!?]%s*([^%s])", "%1 | %2")

	-- canonicalize multiple spaces and remove leading and trailing spaces
	local function canon_spaces(text)
		text = rsub(text, "%s+", " ")
		text = rsub(text, "^ ", "")
		text = rsub(text, " $", "")
		return text
	end

	text = canon_spaces(text)

	local words = m_strutils.capturing_split(text, "([ %-]+)")
	local function word_is_prefix(i)
		-- Check for prefixes, either a final prefix (followed by "-" separator, then a blank word, then no more
		-- words) or a non-final prefix (followed by "- " separator).
		return i == #words - 2 and words[i + 1] == "-" and words[i + 2] == "" or i < #words and words[i + 1] == "- "
	end
	for i = 1, #words, 2 do
		local word = words[i]
		-- Make prefixes unstressed with vowel reduction unless they have an explicit stress marker;
		-- likewise for certain monosyllabic words (e.g. [[o]], [[se]], [[de]], etc.; also [[a]], [[das]], etc.
		-- in Portugal) without stress marks.
		if word_is_prefix(i) and not rfind(words[i], accent_c) or unstressed_words[word] or
			not brazil and unstressed_full_vowel_words_brazil[word] then
			-- add DOTOVER to the last vowel not the first one, or we will mess up 'que' by
			-- adding the DOTOVER after the 'u'
			word = rsub(word, "^(.*" .. V .. quality_c .. "*)", "%1" .. DOTOVER)
		end
		-- Make certain monosyllabic words (e.g. [[meu]], [[com]]; also [[a]], [[das]], etc. in Brazil)
		-- without stress marks be unstressed without vowel reduction.
		if unstressed_full_vowel_words[word] or brazil and unstressed_full_vowel_words_brazil[word] then
			-- add DOTUNDER to the first vowel not the last one, or we will mess up 'meu' by
			-- adding the DOTUNDER after the 'u'; add after a quality marker for à, às
			word = rsub(word, "^(.-" .. V .. quality_c .. "*)", "%1" .. DOTUNDER)
		end
		-- Some unstressed words need special pronunciation.
		word = unstressed_pronunciation_substitution[word] or word
		words[i] = word
	end
	text = table.concat(words)

	-- Now eliminate word-final question mark and exclamation point (converted to foot boundary above when word-medial).
	text = rsub(text, "[!?]", "")
	-- Apostrophe becomes tie (e.g. in [[barriga d'agua]]).
	text = rsub(text, "'", "‿")
	-- User-specified # as in i# (= i. or y) and u# (= u. or w) becomes TEMP1 so we can add # for word boundaries.
	text = rsub(text, "#", TEMP1)
	-- Put # at word beginning and end and double ## at text/foot boundary beginning/end.
	text = rsub(text, " | ", "# | #")
	text = "##" .. rsub(text, " ", "# #") .. "##"
	-- Eliminate hyphens indicating prefixes/suffixes; but preserve a marker indicating prefixes, so we can later
	-- convert primary to secondary stress.
	text = rsub(text, "(" .. V .. charsep_c .. "*)(%-#)", "%1" .. PSEUDOCONS .. "%2")
	text = rsub(text, "%-#", "#" .. PREFIX_MARKER)
	text = rsub(text, "#%-(" .. V .. ")", "#" .. PSEUDOCONS .. "%1")
	text = rsub(text, "#%-", "#")

	local variants

	-- Map over each element in `variants`. If `from` is found in the element, replace the element with two elements, one
	-- obtained by replacing `from` with `to1` and the other by replacing `from` with `to2`. If `to2` is nil, only one
	-- element replaces the original element.
	local function flatmap_and_sub_pre(from, to1, qual1, to2, qual2)
		variants = flatmap(variants, function(item)
			if rfind(item.respelling, from) then
				local retval = {
					{
						respelling = rsub(item.respelling, from, to1),
						qualifiers = combine_qualifiers(item.qualifiers, qual1),
					}
				}
				if to2 then
					table.insert(retval,
						{
							respelling = rsub(item.respelling, from, to2),
							qualifiers = combine_qualifiers(item.qualifiers, qual2),
						}
					)
				end
				return retval
			else
				return {item}
			end
		end)
	end

	if brazil then
		-- Remove grave accents and macrons, which have special meaning only for Portugal. Do this before handling o^
		-- and similar so we can write áutò^:... and have it correctly give 'autò-' in Portugal but 'áutu-,áuto-' in
		-- Brazil.
		text = rsub(text, "[" .. GR .. MACRON .. "]", "")
	else -- Portugal
		-- Convert grave accents and macrons to explicit dot-under + quality marker.
		local grave_macron_to_quality = {
			[GR] = AC,
			[MACRON] = CFLEX,
		}
		text = rsub(text, "[" .. GR .. MACRON .. "]", function(acc) return grave_macron_to_quality[acc] .. DOTUNDER end)
		-- ê*/ô* -> é/ó and é*/ó* -> ê/ô (reverse accents)
		text = rsub(text, "([eo])([" .. AC .. CFLEX .. "])%*", function(eo, acc)
			return eo .. (acc == CFLEX and AC or CFLEX) end)

		-- Treat vowel after des- as word-initial, as in Brazil.		
		text = rsub(text, "(" .. word_or_component_sep_c .. ")des%^+", "%1des++")
		-- Remove i*, i^ and i^^ not followed by a vowel (i.e. Brazilian epenthetic i), but not i^ and i^^ followed or
		-- preceded by a vowel (which has a totally different meaning, i.e. i or y in Brazil).
		-- Also remove all remaining ^.
		text = rsub(text, "i%^+(" .. V .. ")", "i%1")
		text = rsub(text, "(" .. V .. ")i%^+", "%1i")
		text = rsub(text, "i?[*%^]+", "")
	end
	variants = {{respelling = text}}

	if brazil then
		-- Handle i^ and i^^ before a vowel = /i/ or /j/.
		flatmap_and_sub_pre("i%^%^(" .. V .. ")", "y%1", nil, "i.%1", nil)
		flatmap_and_sub_pre("i%^(" .. V .. ")", "i.%1", nil, "y%1", nil)
		-- Handle i^ and i^^ after a vowel = /i/ or /j/; mostly useful for ui^
		flatmap_and_sub_pre("(" .. V .. ")i%^%^", "%1y", nil, "%1.i", nil)
		flatmap_and_sub_pre("(" .. V .. ")i%^", "%1.i", nil, "%1y", nil)
		-- Handle i^ and i^^ not before a vowel = optional epenthetic /i/.
		if style == "sbr" then
			-- Epenthetic /i/ seems less common in South Brazil. Make i^^ not epenthesize (but still palatalize /t/ and /d/),
			-- and i^ epenthesize but not as the first option.
			flatmap_and_sub_pre("i%^%^(" .. NV_NOT_SPACING_CFLEX .. ")", "Ɨ%1", nil)
			flatmap_and_sub_pre("i%^(" .. NV_NOT_SPACING_CFLEX .. ")", "Ɨ%1", nil, "I%1", nil)
		else
			flatmap_and_sub_pre("i%^%^(" .. NV_NOT_SPACING_CFLEX .. ")", "Ɨ%1", nil, "I%1", nil)
			flatmap_and_sub_pre("i%^(" .. NV_NOT_SPACING_CFLEX .. ")", "I%1", nil, "Ɨ%1", nil)
		end
		-- Handle i* = epenthetic /i/.
		flatmap_and_sub_pre("i%*", "I", nil)
		-- Handle u^ and u^^ = /u/ or /w/.
		flatmap_and_sub_pre("u%^%^", "w", nil, "u.", nil)
		flatmap_and_sub_pre("u%^", "u.", nil, "w", nil)
		if style == "sbr" then
			-- The raised variant apparently does not occur in South Brazil.
			flatmap_and_sub_pre("([eo])%^+", "%1", nil)
		else
			-- Handle e^ and e^^ = /e/ or /i/; handle o^ and o^^ = /o/ or /u/.
			-- Do e^ and o^ together so we get only two outputs, not four, if they cooccur.
			-- Likewise for e^^ and o^^.
			flatmap_and_sub_pre("([eo])%^%^",
				function(eo) return eo == "e" and "i" or "u" end, nil,
				"%1", nil)
			flatmap_and_sub_pre("([eo])%^",
				"%1", nil,
				function(eo) return eo == "e" and "i" or "u" end, nil)
		end
		-- Handle ê*/ô*/é*/ó* = same as without asterisk.
		flatmap_and_sub_pre("([eo][" .. AC .. CFLEX .. "])%*", "%1", nil)
		-- Handle des^ at beginning of word or component = des++ or dis++, and des^^ = opposite order. But apparently
		-- not in South Brazil, where the raised variant doesn't occur.
		if style == "sbr" then
			flatmap_and_sub_pre("(" .. word_or_component_sep_c .. ")des%^+", "%1des++", nil)
		else
			flatmap_and_sub_pre("(" .. word_or_component_sep_c .. ")des%^%^", "%1dis++", nil, "%1des++", nil)
			flatmap_and_sub_pre("(" .. word_or_component_sep_c .. ")des%^", "%1des++", nil, "%1dis++", nil)
		end
		for _, variant in ipairs(variants) do
			if rfind(variant.respelling, "[*%^]") then
				err(("* or ^ remains after applying all known replacements involving these characters (result is '%s')")
					:format(variant.respelling))
			end
		end
	end

	-- Replace i# and u# sequences (above we replaced # with TEMP1).
	flatmap_and_sub_pre("i" .. TEMP1, "i.", nil, "y", {"faster pronunciation"})
	flatmap_and_sub_pre("u" .. TEMP1, "u.", nil, "w", {"faster pronunciation"})

	-- Given a single variant element representing a preprocessed respelling along with any qualifiers resulting from the
	-- preprocessing, generate the phonemic and phonetic representations using one_term_ipa() and postprocess to get the
	-- final IPA. The postprocessing is there in general to handle cases where a single respelling produces multiple
	-- outputs, such as Brazil -io producing either /i.u/ or /iw/. Note that user-specified qualifiers are not yet present
	-- at any stage of this IPA generation; they are added at the end by the caller of IPA().
	local function call_one_term_ipa(variant)
		local result = {{
			phonemic = one_term_ipa(variant.respelling, style, false, err),
			phonetic = one_term_ipa(variant.respelling, style, true, err),
			qualifiers = variant.qualifiers,
		}}

		local function unpack_if_list(obj)
			if type(obj) == "table" and #obj == 2 and obj[1] then
				return unpack(obj)
			else
				return obj, obj
			end
		end

		-- Map over each element in `result`. If `from` is found in the element, replace the element with two elements, one
		-- obtained by replacing `from` with `to1` in both the phonemic and phonetic representations of the existing element,
		-- and the other similarly by replacing `from` with `to2` in both the phonemic and phonetic representations. If `to2`
		-- is nil, only one element replaces the original element. `qual1`, if non-nil, is a list of qualifiers to be added to
		-- the new element associated with `to1` (appended to any existing qualifiers). Similarly, `qual2` is a list of
		-- qualifiers to be added to the new element associated with `to2`. Normally, `to1` and `to2` can be anything that can
		-- be used as the replacement argument to the Lua gsub() function, i.e. a string, a function or a table. However, if
		-- `to1` or `to2` is a two-element list, it is unpacked into two separate substitution objects, respectively for the
		-- phonemic and phonetic representations of the element being substituted. This is used, for example, when handling
		-- Ú resulting from stressed final '-io(s)', so different phonemic vs. phonetic replacements can be used (/w/ vs [ʊ̯]).
		local function flatmap_and_sub_post(from, to1, qual1, to2, qual2)
			result = flatmap(result, function(item)
				if rfind(item.phonemic, from) or rfind(item.phonetic, from) then
					local to1_phonemic, to1_phonetic = unpack_if_list(to1)
					local retval = {
						{
							phonemic = rsub(item.phonemic, from, to1_phonemic),
							phonetic = rsub(item.phonetic, from, to1_phonetic),
							qualifiers = combine_qualifiers(item.qualifiers, qual1),
						}
					}
					if to2 then
						local to2_phonemic, to2_phonetic = unpack_if_list(to2)
						table.insert(retval,
							{
								phonemic = rsub(item.phonemic, from, to2_phonemic),
								phonetic = rsub(item.phonetic, from, to2_phonetic),
								qualifiers = combine_qualifiers(item.qualifiers, qual2),
							}
						)
					end
					return retval
				else
					return {item}
				end
			end)
		end

		if brazil then
			-- Convert Ẽ from initial [[em]] as a word by itself to either /ẽj̃/ and /ĩ/.
			flatmap_and_sub_post("Ẽ" .. TILDE .. "#", "e" .. TILDE .. "j" .. TILDE .. "#", {"careful pronunciation"},
				"i" .. TILDE .. "#", {"natural pronunciation"})
			-- Convert Ẽ from initial em-/en- + consonant to either /ẽ/ and /ĩ/.
			flatmap_and_sub_post("Ẽ", "e", {"careful pronunciation"}, "i", {"natural pronunciation"})
			flatmap_and_sub_post("I", "i", nil, "e", nil)
			-- Convert Ú resulting from stressed final '-io(s)'.
			flatmap_and_sub_post("%.Ú", ".u", nil, {"w", "ʊ̯"}, nil)
		else -- Portugal
			flatmap_and_sub_post("W", "", nil, "w", {"regional"})
			flatmap_and_sub_post("ʃ(" .. wordsep_c .. "*)s",
					"ʃ%1s", {"careful pronunciation"}, "%1ʃ", {"natural pronunciation"})
			flatmap_and_sub_post("ʒ(" .. wordsep_c .. "*)z",
					"ʒ%1z", {"careful pronunciation"}, "%1ʒ", {"natural pronunciation"})
			flatmap_and_sub_post("Ɔ", "o", nil, "ɔ", nil)
			-- Split (ɨ) after l into two pronuns, one with ɨ and the other without it (with one fewer syllables and coda [ɫ]).
			flatmap_and_sub_post("%.([^.# ]-)L#", ".%1lɨ#", nil, {"%1l#", "%1ɫ#"}, nil)
		end
		flatmap_and_sub_post("([ÌÙ])%.",
			function(iu) return iu == "Ì" and "i." or "u." end, nil,
			function(iu) return iu == "Ì" and "j" or "w" end, {"faster pronunciation"})

		return result
	end

	-- Final changes to the generated IPA to produce what's shown to the user. We used to do this at the end of
	-- one_term_ipa() but the stuff below needs to happen after the expansion of Ì. and Ù. in Brazil to either i./u.
	-- or j/w, because the latter transformation involves removing a syllable boundary, which will cause a stress mark
	-- on the following syllable to retract to the beginning of the newly combined syllable. To avoid lots of hassle,
	-- we postpone this stress mark movement till now.
	local function finalize_ipa(text, phonetic)
		-- Convert Brazil i/u in hiatus to ɪ/ʊ in the phonetic representation. This needs to happen after handling of
		-- Ì. and Ù., which feeds this change.
		if brazil and phonetic then
			local phonetic_hiatus_iu_to_actual = {["i"] = "ɪ", ["u"] = "ʊ"}
			text = rsub(text, "([iu])(%." .. V .. ")", function(iu, after) return phonetic_hiatus_iu_to_actual[iu] .. after end)
		end

		-- Stress marks and syllable dividers.
		-- Component separators that aren't transparent to syllabification need to be made into syllable dividers.
		text = rsub(text, non_syl_transp_component_sep_c, ".")
		-- IPA stress marks in components followed by + should be removed.
		text = rsub(text, ipa_stress_c .. "([^" .. word_divider .. component_sep .. "]*%+)", "%1")
		-- Component separators that are transparent to syllabification need to be removed now, before moving IPA stress marks
		-- to the beginning of the syllable, so they don't interfere in this process.
		text = rsub(text, syl_transp_component_sep_c .. "#?", "")
		-- Move IPA stress marks to the beginning of the syllable.
		text = rsub_repeatedly(text, "([#.])([^#.]*)(" .. ipa_stress_c .. ")", "%1%3%2")
		-- Suppress syllable divider before IPA stress indicator.
		text = rsub(text, "%.(#?" .. ipa_stress_c .. ")", "%1")
		-- Make all primary stresses but the last one in a given word be secondary. May be fed by the first rule above.
		text = rsub_repeatedly(text, "ˈ([^ ]+)ˈ", "ˌ%1ˈ")
		-- Make primary stresses in prefixes become secondary.
		text = rsub_repeatedly(text, "ˈ([^#]*#" .. PREFIX_MARKER .. ")", "ˌ%1")

		-- Remove # symbols at word/text boundaries, as well as _ (which forces separate interpretation), pseudo-consonant
		-- markers (at edges of some prefixes/suffixes), and prefix markers, and recompose.
		text = rsub(text, "[#_" .. PSEUDOCONS .. PREFIX_MARKER .. "]", "")
		text = mw.ustring.toNFC(text)

		return text
	end

	variants = flatmap(variants, call_one_term_ipa)
	for i, variant in ipairs(variants) do
		variants[i].phonemic = finalize_ipa(variants[i].phonemic, false)
		variants[i].phonetic = finalize_ipa(variants[i].phonetic, true)
	end
	return variants
end


-- For bot usage; {{#invoke:pt-pronunc|IPA_json|SPELLING|style=STYLE}}
-- where
--
--   1. SPELLING is the word or respelling to generate pronunciation for;
--   2. required parameter style= indicates the pronunciation style to generate
--      (e.g. "rio" for Rio/Carioca pronunciation, "lisbon" for Lisbon pronunciation;
--      see the comment above export.IPA() above for the full list);
--   3. phonetic=1 specifies to generate the phonetic rather than phonemic pronunciation;
function export.IPA_json(frame)
	local iparams = {
		[1] = {},
		["style"] = {required = true},
	}
	local iargs = require("parameters").process(frame.args, iparams)
	local pronuns = export.IPA(iargs[1], iargs.style)
	return require("JSON").toJSON(pronuns)
end


-- "Canonicalize" a single respelling (after splitting multiple respellings on comma and parsing off inline
-- modifiers). This currently handles '+' and substitution notation.
function export.canonicalize_respelling(text, pagename)
	if not text or text == "+" then
		text = pagename
	end

	-- No such substitutions currently.
	-- text = rsub(text, "%[([hHxXjJ])%]", function(sound)
	-- 	return explicit_sound_to_substitution[ulower(sound)]
	-- end)

	-- Implement substitution notation.
	if rfind(text, "^%[.*%]$") then
		local subs = rsplit(rmatch(text, "^%[(.*)%]$"), ";")
		text = pagename
		for _, sub in ipairs(subs) do
			local fromto = rsplit(sub, ":")
			if #fromto < 2 then
				error("Bad substitution spec " .. sub .. " in {{pt-IPA}}, should have a colon in it")
			end
			local from, to
			if #fromto == 2 then
				from, to = fromto[1], fromto[2]
			else
				from = fromto[1]
				table.remove(fromto, 1)
				to = table.concat(fromto, ":")
			end
			local newtext = text
			if rfind(from, "^%^") then
				-- whole-word match
				from = rmatch(from, "^%^(.*)$")
				newtext = rsub(text, "%f[%a]" .. require("utilities").pattern_escape(from) .. "%f[%A]", to)
			else
				newtext = rsub(text, require("utilities").pattern_escape(from), to)
			end
			if from ~= to and newtext == text then
				error("Substitution spec " .. sub .. " didn't match respelling '" .. text .. "'")
			end
			text = newtext
		end
	end

	return text
end


function export.express_styles(inputs, args_style, pagename)
	local pronuns_by_style = {}
	local expressed_styles = {}

	local function dostyle(style)
		pronuns_by_style[style] = {}
		for _, val in ipairs(inputs[style].terms) do
			local respelling = val.term
			respelling = export.canonicalize_respelling(respelling, pagename)

			local refs
			if #val.ref == 0 then
				refs = nil
			else
				refs = {}
				for _, refspec in ipairs(val.ref) do
					local this_refs = require("references").parse_references(refspec)
					for _, this_ref in ipairs(this_refs) do
						table.insert(refs, this_ref)
					end
				end
			end

			local pronuns = export.IPA(respelling, style)
			for _, pronun in ipairs(pronuns) do
				local qualifiers = m_table.deepcopy(val.q)
				if pronun.qualifiers then
					for _, qual in ipairs(pronun.qualifiers) do
						m_table.insertIfNot(qualifiers, qual)
					end
				end
				pronun.qualifiers = #qualifiers > 0 and qualifiers or nil
				pronun.refs = refs
				m_table.insertIfNot(pronuns_by_style[style], pronun)
			end
		end
	end

	local function all_available(styles)
		local available_styles = {}
		for _, style in ipairs(styles) do
			if pronuns_by_style[style] then
				table.insert(available_styles, style)
			end
		end
		return available_styles
	end

	local function express_style(styles, indent)
		local hidden_tag, tag
		indent = indent or 1
		if type(styles) == "string" then
			styles = {styles}
			tag = export.all_style_descs[styles[1]]
			hidden_tag = export.all_style_descs[style_to_style_group[styles[1]]]
		else
			tag = false
			hidden_tag = false
		end
		styles = all_available(styles)
		if #styles == 0 then
			return
		end
		local style = styles[1]

		-- If style specified, make sure it matches the requested style.
		local style_matches
		if not args_style then
			style_matches = true
		else
			local or_styles = rsplit(args_style, "%s*,%s*")
			for _, or_style in ipairs(or_styles) do
				local and_styles = rsplit(or_style, "%s*%+%s*")
				local and_matches = true
				for _, and_style in ipairs(and_styles) do
					local negate
					if and_style:find("^%-") then
						and_style = and_style:gsub("^%-", "")
						negate = true
					end
					local this_style_matches = false
					for _, part in ipairs(styles) do
						if part == and_style then
							this_style_matches = true
							break
						end
					end
					if negate then
						this_style_matches = not this_style_matches
					end
					if not this_style_matches then
						and_matches = false
					end
				end
				if and_matches then
					style_matches = true
					break
				end
			end
		end
		if not style_matches then
			return
		end

		local new_style = {
			tag = tag,
			represented_styles = styles,
			pronuns = pronuns_by_style[style],
			indent = indent,
			bullets = inputs[style].bullets,
			pre = inputs[style].pre,
			post = inputs[style].post,
		}
		for _, hidden_tag_style in ipairs(expressed_styles) do
			if hidden_tag_style.tag == hidden_tag then
				table.insert(hidden_tag_style.styles, new_style)
				return
			end
		end
		table.insert(expressed_styles, {
			tag = hidden_tag,
			styles = {new_style},
		})
	end

	for style, _ in pairs(inputs) do
		dostyle(style)
	end

	local function diff(style1, style2)
		if not pronuns_by_style[style1] or not pronuns_by_style[style2] then
			return true
		end
		return not m_table.deepEquals(pronuns_by_style[style1], pronuns_by_style[style2])
	end
	local gbr_sp_different = diff("gbr", "sp")
	local gbr_rio_different = diff("gbr", "rio")
	local gbr_sbr_different = diff("gbr", "sbr")
	local gpt_cpt_different = diff("gpt", "cpt")
	local gpt_spt_different = diff("gpt", "spt")
	local gbr_gpt_different = diff("gbr", "gpt") -- general differences between BP and EP
	
	if not gbr_sp_different and not gbr_rio_different and gbr_sbr_different and
		not gpt_cpt_different and not gpt_spt_different and
		not gbr_gpt_different then
		-- All the same
		express_style(export.all_styles)
	else
		-- Within Brazil
		express_style("gbr")
		if gbr_sp_different then
			express_style("sp", 2)
		end
		if gbr_rio_different then
			express_style("rio", 2)
		end
		if gbr_sbr_different then
			express_style("sbr", 2)
		end
		
		-- Within Portugal
		express_style("gpt")
		if gpt_cpt_different then
			express_style("cpt", 2)
		end
		if gpt_spt_different then
			express_style("spt", 2)
		end
	end
	return expressed_styles
end


function export.show(frame)
	-- Create parameter specs
	local params = {
		[1] = {}, -- this replaces style group 'all'
		["style"] = {},
		["pagename"] = {},
	}
	for group, _ in pairs(export.all_style_groups) do
		if group ~= "all" then
			params[group] = {}
		end
	end
	for _, style in ipairs(export.all_styles) do
		params[style] = {}
	end

	-- Parse arguments
	local parargs = frame:getParent().args
	local args = require("parameters").process(parargs, params)
	local pagename = args.pagename or mw.title.getCurrentTitle().subpageText

	-- Set inputs
	local inputs = {}
	-- If 1= specified, do all styles.
	if args[1] then
		for _, style in ipairs(export.all_styles) do
			inputs[style] = args[1]
		end
	end
	-- Then do remaining style groups other than 'all', overriding 1= if given.
	for group, styles in pairs(export.all_style_groups) do
		if group ~= "all" and args[group] then
			for _, style in ipairs(styles) do
				inputs[style] = args[group]
			end
		end
	end
	-- Then do individual style settings.
	for _, style in ipairs(export.all_styles) do
		if args[style] then
			inputs[style] = args[style]
		end
	end
	-- If no inputs given, set all styles based on current pagename.
	if not next(inputs) then
		for _, style in ipairs(export.all_styles) do
			inputs[style] = "+"
		end
	end

	-- Parse the arguments.
	local put
	for style, input in pairs(inputs) do
		if input:find("[<%[]") then
			local function parse_err(msg)
				error(msg .. ": " .. style .. "= " .. input)
			end
			if not put then
				put = require("parse utilities")
			end
			-- We don't want to split off a comma followed by a space, as in [[rei morto, rei posto]], so replace
			-- comma+space with a special character that we later undo.
			input = rsub(input, ", ", TEMP1)
			-- Parse balanced segment runs involving either [...] (substitution notation) or <...> (inline modifiers). We do this
			-- because we don't want commas inside of square or angle brackets to count as respelling delimiters. However, we
			-- need to rejoin square-bracketed segments with nearby ones after splitting alternating runs on comma. For example,
			-- if we are given "a[x]a<q:learned>,[vol:vôl;ei:éi,ei]<q:nonstandard>", after calling
			-- parse_multi_delimiter_balanced_segment_run() we get the following output:
			--
			-- {"a", "[x]", "a", "<q:learned>", ",", "[vol:vôl;ei:éi,ei]", "", "<q:nonstandard>", ""}
			--
			-- After calling split_alternating_runs(), we get the following:
			--
			-- {{"a", "[x]", "a", "<q:learned>", ""}, {"", "[vol:vôl;ei:éi,ei]", "", "<q:nonstandard>", ""}}
			--
			-- We need to rejoin stuff on either side of the square-bracketed portions.
			local segments = put.parse_multi_delimiter_balanced_segment_run(input, {{"<", ">"}, {"[", "]"}})
			-- Not with spaces around the comma; see above for why we don't want to split off comma followed by space.
			local comma_separated_groups = put.split_alternating_runs(segments, ",")

			local parsed = {terms = {}}
			for i, group in ipairs(comma_separated_groups) do
				-- Rejoin bracketed segments with nearby ones, as described above.
				local j = 2
				while j <= #group do
					if group[j]:find("^%[") then
						group[j - 1] = group[j - 1] .. group[j] .. group[j + 1]
						table.remove(group, j)
						table.remove(group, j)
					else
						j = j + 2
					end
				end
				for j, segment in ipairs(group) do
					group[j] = rsub(segment, TEMP1, ", ")
				end

				local term = {term = group[1], ref = {}, q = {}}
				for j = 2, #group - 1, 2 do
					if group[j + 1] ~= "" then
						parse_err("Extraneous text '" .. group[j + 1] .. "' after modifier")
					end
					local modtext = group[j]:match("^<(.*)>$")
					if not modtext then
						parse_err("Internal error: Modifier '" .. group[j] .. "' isn't surrounded by angle brackets")
					end
					local prefix, arg = modtext:match("^([a-z]+):(.*)$")
					if not prefix then
						parse_err("Modifier " .. group[j] .. " lacks a prefix, should begin with one of " ..
							"'pre:', 'post:', 'ref:', 'bullets:' or 'q:'")
					end
					if prefix == "ref" or prefix == "q" then
						table.insert(term[prefix], arg)
					elseif prefix == "pre" or prefix == "post" or prefix == "bullets" then
						if i < #comma_separated_groups then
							parse_err("Modifier '" .. prefix .. "' should occur after the last comma-separated term")
						end
						if parsed[prefix] then
							parse_err("Modifier '" .. prefix .. "' occurs twice, second occurrence " .. group[j])
						end
						if prefix == "bullets" then
							if not arg:find("^[0-9]+$") then
								parse_err("Modifier 'bullets' should have a number as argument")
							end
							parsed.bullets = tonumber(arg)
						else
							parsed[prefix] = arg
						end
					else
						parse_err("Unrecognized prefix '" .. prefix .. "' in modifier " .. group[j]
							.. ", should be one of 'pre', 'post', 'ref', 'bullets' or 'q'")
					end
				end
				table.insert(parsed.terms, term)
			end
			if not parsed.bullets then
				parsed.bullets = 1
			end
			inputs[style] = parsed
		else
			local terms = {}
			-- We don't want to split on comma+space, which should become a foot boundary as in
			-- [[rei morto, rei posto]].
			local subbed_input = rsub(input, ", ", TEMP1)
			for _, term in ipairs(rsplit(subbed_input, ",")) do
				term = rsub(term, TEMP1, ", ")
				table.insert(terms, {term = term, ref = {}, q = {}})
			end
			inputs[style] = {
				terms = terms,
				bullets = 1,
			}
		end
	end

	local expressed_styles = export.express_styles(inputs, args.style, pagename)

	local lines = {}

	local function format_style(tag, expressed_style, is_first)
		local pronunciations = {}
		local formatted_pronuns = {}

		-- Loop through each pronunciation. For each one, add the phonemic and (if different) phonetic versions to
		-- `pronunciations`, for formatting by [[IPA]], and also create an approximation of the formatted
		-- version so that we can compute the appropriate width of the HTML switcher div box that holds the different
		-- per-dialect variants.
		for i, pronun in ipairs(expressed_style.pronuns) do
			table.insert(pronunciations, {
				pron = "/" .. pronun.phonemic .. "/",
				qualifiers = pronun.qualifiers,
				separator = i > 1 and ", " or nil,
			})
			local formatted_phonemic = "/" .. pronun.phonemic .. "/"
			if pronun.qualifiers then
				formatted_phonemic = "(" .. table.concat(pronun.qualifiers, ", ") .. ") " .. formatted_phonemic
			end
			if i > 1 then
				formatted_phonemic = ", " .. formatted_phonemic
			end
			table.insert(formatted_pronuns, formatted_phonemic)

			-- Check if phonetic and phonemic are the same. If so, we skip displaying the phonetic version; but in this
			-- case, we need to attach any references to the phonemic version.
			if pronun.phonetic == pronun.phonemic then
				pronunciations[#pronunciations].refs = pronun.refs
			else
				table.insert(pronunciations, {
					pron = "[" .. pronun.phonetic .. "]",
					refs = pronun.refs,
					separator = " ",
				})
				local reftext = ""
				if pronun.refs then
					reftext = string.rep("[1]", #pronun.refs)
				end
				table.insert(formatted_pronuns, " [" .. pronun.phonetic .. "]" .. reftext)
			end
		end

		-- Number of bullets: When indent = 1, we want the number of bullets given by `expressed_style.bullets`,
		-- and when indent = 2, we want `expressed_style.bullets + 1`, hence we subtract 1.
		local bullet = string.rep("*", expressed_style.bullets + expressed_style.indent - 1) .. " "
		-- Here we construct the formatted line in `formatted`, and also try to construct the equivalent without HTML
		-- and wiki markup in `formatted_for_len`, so we can compute the approximate textual length for use in sizing
		-- the toggle box with the "more" button on the right.
		local pre = is_first and expressed_style.pre and expressed_style.pre .. " " or ""
		local pre_for_len = pre .. (tag and "(" .. tag .. ") " or "")
		pre = pre .. (tag and m_qual.format_qualifier(tag) .. " " or "")
		local post = is_first and (expressed_style.post and " " .. expressed_style.post or "") or ""
		local formatted = bullet .. pre .. m_IPA.format_IPA_full(lang, pronunciations, nil, "") .. post
		local formatted_for_len = bullet .. pre .. "IPA(key): " .. table.concat(formatted_pronuns) .. post
		return formatted, formatted_for_len
	end

	for i, style_group in ipairs(expressed_styles) do
		if #style_group.styles == 1 then
			style_group.formatted, style_group.formatted_for_len =
				format_style(style_group.styles[1].tag, style_group.styles[1], i == 1)
		else
			style_group.formatted, style_group.formatted_for_len =
				format_style(style_group.tag, style_group.styles[1], i == 1)
			for j, style in ipairs(style_group.styles) do
				style.formatted, style.formatted_for_len =
					format_style(style.tag, style, i == 1 and j == 1)
			end
		end
	end

	-- Remove any HTML from the formatted text, since it doesn't contribute to the textual length, and return the
	-- resulting length in characters.
	local function textual_len(text)
		text = rsub(text, "<.->", "")
		return ulen(text)
	end

	local maxlen = 0
	for i, style_group in ipairs(expressed_styles) do
		local this_len = textual_len(style_group.formatted_for_len)
		if #style_group.styles > 1 then
			for _, style in ipairs(style_group.styles) do
				this_len = math.max(this_len, textual_len(style.formatted_for_len))
			end
		end
		maxlen = math.max(maxlen, this_len)
	end

	for i, style_group in ipairs(expressed_styles) do
		if #style_group.styles == 1 then
			table.insert(lines, "<div>\n" .. style_group.formatted .. "</div>")
		else
			local inline = '\n<div class="vsShow" style="display:none">\n' .. style_group.formatted .. "</div>"
			local full_prons = {}
			for _, style in ipairs(style_group.styles) do
				table.insert(full_prons, style.formatted)
			end
			local full = '\n<div class="vsHide">\n' .. table.concat(full_prons, "\n") .. "</div>"
			local em_length = math.floor(maxlen * 0.68) -- from [[grc-pronunciation]]
			table.insert(lines, '<div class="vsSwitcher" data-toggle-category="pronunciations" style="width: ' .. em_length .. 'em; max-width:100%;"><span class="vsToggleElement" style="float: right;">&nbsp;</span>' .. inline .. full .. "</div>")
		end
	end

	-- major hack to get bullets working on the next line
	return table.concat(lines, "\n") .. "\n<span></span>"
end


return export