
local export = {}
mw = require('mw')
local force_cat = false -- for testing

local strutils = require("string utilities")
print('table')
local m_table = require("table")
local m_IPA = require("IPA")
local lang = require("languages").getByCode("de")


------------------------- Aliases for Unicode-safe versions of string functions -------------------------

local u = mw.ustring.char
local rsubn = mw.ustring.gsub
rsubn = memoize(rsubn)
local rfind = mw.ustring.find
rfind = memoize(rfind)
local rmatch = mw.ustring.match
rmatch = memoize(rfind)

local rsplit = mw.text.split
local rgsplit = mw.text.gsplit
local ulen = mw.ustring.len
local ulower = mw.ustring.lower


------------------------- Unicode combining characters -------------------------

local ACUTE = u(0x0301) -- COMBINING ACUTE ACCENT =  ́
local GRAVE = u(0x0300) -- COMBINING GRAVE ACCENT =  ̀
local CFLEX = u(0x0302) -- COMBINING CIRCUMFLEX ACCENT =  ̂
local TILDE = u(0x0303) -- COMBINING TILDE =  ̃
local MACRON = u(0x0304) -- COMBINING MACRON =  ̄
local BREVE = u(0x0306) -- COMBINING BREVE =  ̆
local DIA = u(0x0308) -- COMBINING DIAERESIS =  ̈
local DOTOVER = u(0x0307) -- COMBINING DOT ABOVE =  ̇
local DOUBLEGRAVE = u(0x030F) -- COMBINING DOUBLE GRAVE ACCENT =  ̏
local UNRELEASED = u(0x031A) -- COMBINING LEFT ANGLE ABOVE =  ̚
local DOTUNDER = u(0x0323) -- COMBINING DOT BELOW =  ̣
local UNVOICED = u(0x0325) -- COMBINING RING BELOW =  ̥
local CEDILLA = u(0x0327) -- COMBINING CEDILLA =  ̧
local SYLLABIC = u(0x0329) -- COMBINING VERTICAL LINE BELOW =  ̩
local INVBREVEBELOW = u(0x032F) -- COMBINING INVERTED BREVE BELOW =  ̯
local LINEUNDER = u(0x0331) -- COMBINING MACRON BELOW =  ̱
local TIE = u(0x0361) -- COMBINING DOUBLE INVERTED BREVE =  ͡


------------------------- Pattern-substitution function wrappers -------------------------

-- version of rsubn() that discards all but the first return value
local function rsub(term, foo, bar, n)
	local retval = rsubn(term, foo, bar, n)
	return retval
end

-- version of rsubn() that returns a 2nd argument boolean indicating whether a substitution was made
local function rsubb(term, foo, bar, n)
	local retval, nsubs = rsubn(term, foo, bar, n)
	return retval, nsubs > 0
end

-- like str:gsub() but discards all but the first return value
local function gsub(term, foo, bar, n)
	local retval = term:gsub(foo, bar, n)
	return retval
end

-- apply rsub() repeatedly until no change
local function rsub_repeatedly(term, foo, bar, n)
	while true do
		local new_term = rsub(term, foo, bar, n)
		if new_term == term then
			return term
		end
		term = new_term
	end
end


------------------------- Internally-used symbols -------------------------

-- We use the following internally:
-- ⁀ represents a component boundary. Two components within an orthographic word are separated by ⁀; the edge of an
--   orthographic word is denoted by ⁀⁀. The division between prefix and component, or between prefix and prefix, is
--   also denoted by ⁀.
-- ‿ represents the division between component and suffix, or suffix and suffix. We need to distinguish this from ⁀
--   for certain purposes, e.g. 'st' at the beginning of a component is /ʃt/ but 'st' at the beginning of a suffix is
--   /st/.
-- . represents a syllable boundary.
-- AUTOACUTE, AUTOGRAVE, ORIG_SUFFIX_GRAVE: Described below.
-- EXPLICIT_*: Described below.

-- Used to temporarily substitute capital I and U when lowercasing in canonicalize_and_split_words(). It is OK if these
-- overlap with other substitution symbols because their use is before any of the other symbols are used.
local TEMP_I = u(0xFFF0)
local TEMP_U = u(0xFFF1)

-- When auto-generating primary and secondary stress accents, we use these special characters, and later convert to
-- normal IPA accent marks, so we can distinguish auto-generated stress from user-specified stress.
local AUTOACUTE = u(0xFFF0)
local AUTOGRAVE = u(0xFFF1)
-- An auto-generated secondary stress in a suffix is converted to the following if the word is not composed of
-- multiple (hyphen or double-hyphen separated) components. It is eventually converted to secondary stress (if there is
-- no preceding secondary stress, and the directly preceding syllable does not have primary stress), and otherwise
-- removed.
local ORIG_SUFFIX_GRAVE = u(0xFFF2)
local SYLDIV = u(0xFFF3)


------------------------- Explicit allophone notation -------------------------

-- When the user uses the "explicit allophone" notation such as [z] or [x] to force a particular allophone, we
-- internally convert that notation into a single special character.
local EXPLICIT_S = u(0xFFF4)
local EXPLICIT_Z = u(0xFFF5)
local EXPLICIT_V = u(0xFFF6)
local EXPLICIT_B = u(0xFFF7)
local EXPLICIT_D = u(0xFFF8)
local EXPLICIT_G = u(0xFFF9)
local EXPLICIT_X = u(0xFFFA)

-- Map "explicit allophone" notation into special char. See above.
local char_to_explicit_char = {
	["s"] = EXPLICIT_S,
	["z"] = EXPLICIT_Z,
	["v"] = EXPLICIT_V,
	["b"] = EXPLICIT_B,
	["d"] = EXPLICIT_D,
	["g"] = EXPLICIT_G,
	["x"] = EXPLICIT_X,
}

-- Map "explicit allophone" notation into normal spelling, for supporting ann=.
local char_to_spelling = {
	["s"] = "s",
	["z"] = "s",
	["v"] = "v",
	["b"] = "b",
	["d"] = "d",
	["g"] = "g",
	["x"] = "ch",
}

-- Map "explicit allophone" notation into phonemes.
local explicit_char_to_phonemic = {
	[EXPLICIT_S] = "s",
	[EXPLICIT_Z] = "z",
	[EXPLICIT_V] = "v",
	[EXPLICIT_B] = "b",
	[EXPLICIT_D] = "d",
	[EXPLICIT_G] = "ɡ", -- IPA ɡ!
	[EXPLICIT_X] = "x",
}


------------------------- Character classes to simplify use of patterns -------------------------

local stress = ACUTE .. GRAVE .. DOUBLEGRAVE .. AUTOACUTE .. AUTOGRAVE .. ORIG_SUFFIX_GRAVE .. "ˈˌ"
local stress_c = "[" .. stress .. "]"
local non_stress_c = "[^" .. stress .. "]"
local acute = ACUTE .. AUTOACUTE
local acute_c = "[" .. acute .. "]"
local grave = GRAVE .. AUTOGRAVE
local grave_c = "[" .. grave .. "]"
local accent_non_stress_non_invbrevebelow = BREVE .. CFLEX .. TILDE .. DOTUNDER .. MACRON .. "ː*"
local accent_non_stress = accent_non_stress_non_invbrevebelow .. INVBREVEBELOW
local accent_non_stress_c = "[" .. accent_non_stress .. "]"
local accent = stress .. accent_non_stress
local accent_c = "[" .. accent .. "]"
local accent_non_invbrevebelow = stress .. accent_non_stress_non_invbrevebelow
local accent_non_invbrevebelow_c = "[" .. accent_non_invbrevebelow .. "]"
local non_accent_c = "[^" .. accent .. "]"
-- Use both IPA symbols and letters so it can be used at any step of the process.
local back_vowel_non_glide = "aɑoɔuʊ"
local back_vowel = back_vowel_non_glide .. "U"
local back_vowel_c = "[" .. back_vowel .. "]"
local front_vowel_non_glide = "eɛiɪyʏøœäöü"
local front_vowel = front_vowel_non_glide .. "I"
local schwalike = "əɐ"
local vowel = back_vowel .. front_vowel .. schwalike
local V = "[" .. vowel .. "]"
local non_V = "[^" .. vowel .. "]"
local vowel_non_glide = back_vowel_non_glide .. front_vowel_non_glide .. schwalike
local V_non_glide = "[" .. vowel_non_glide .. "]"
local vowel_unmarked_for_quality = "aeiouäöü"
local V_unmarked_for_quality = "[" .. vowel_unmarked_for_quality .. "]"
local charsep = accent .. "." .. SYLDIV .. "‿"
local charsep_c = "[" .. charsep .. "]"
local wordsep = charsep .. " ⁀"
local wordsep_c = "[" .. wordsep .. "]"
local cons_guts = "^" .. vowel .. wordsep .. "_" -- guts of consonant class
local C = "[" .. cons_guts .. "]" -- consonant
local C_not_lr = "[" .. cons_guts .. "lr]" -- consonant not 'l' or 'r'
local C_not_h = "[" .. cons_guts .. "h]" -- consonant not 'h'
local C_not_s = "[" .. cons_guts .. "s]" -- consonant not 's'
-- Include both regular g and IPA ɡ so it can be used anywhere
local obstruent_non_sibilant = "pbfvkgɡtdxç" .. EXPLICIT_B .. EXPLICIT_D .. EXPLICIT_G .. EXPLICIT_V .. EXPLICIT_X
local obstruent_non_sibilant_c = "[" .. obstruent_non_sibilant .. "]"
local unvoiced_cons = "ptkfsßʃxç" .. EXPLICIT_S .. EXPLICIT_X
local unvoiced_C = "[" .. unvoiced_cons .. "]"


------------------------- Allowed onsets for prefix-splitting -------------------------

-- This is a list of patterns that collectively describe all possible orthographic word onsets. This is used when
-- splitting off prefixes like [[ge-]] and [[be-]] to prevent splitting in words like [[Gertrud]] ('rtr-' is not a
-- possible word onset).
local allowed_onsets = {
	"",
	"[bcdfghjklmnpqrstvwxz]",
	-- Many single consonants can be followed by j but they are all foreign terms that can't be prefixed.
	"ch[lr]?",
	"sch[lmnrw]?",
	"[td]sch",
	"[kg]n",
	"[kgbpfc]l",
	"[kgbpdtfc]r",
	"[kgbpdt]h",
	"ph[lr]",
	"thr",
	"s[ckpt]r?",
	"s[pk]l",
	"s[pt]h",
	"sz",
	"vl",
	"w[lr]",
}


------------------------- Possible state transitions when handling prefix combinations -------------------------

-- We view the possible combinations of prefixes through the lens of a finite state machine. This allows us to
-- handle occasional cases where more than one of a given type of prefix occurs (e.g. [[überzubeanspruchen]]).
-- NOTE ABOUT STRESS: After un-, stressed prefixes lose their stress and the root takes secondary stress; cf.
-- 'únausgegòren'. But otherwise if there are two stressed prefixes, the second one takes secondary stress and
-- the root loses the stress; cf. 'ǘberbeànspruchen', 'ǘberzubeànspruchen'.
local prefix_previous_allowed_states = {
	-- un- can occur after unstressed prefixes; cf. [[verunglücken]], [[Verunreinigung]], [[verunstalten]],
	-- [[beunruhigen]]
	["un"] = m_table.listToSet { "unstressed" },
	-- stressed prefixes can occur after un- ([[unausgegoren]]) or after unstressed prefixes ([[beauftragen]],
	-- [[beabsichtigen]], [[veranlagen]])
	["stressed"] = m_table.listToSet { "un", "unstressed" },
	-- unstressed prefixes can occur after un- ([[unzerstörbar]]), after stressed prefixes ([[aufbewahren]],
	-- [[Aufenthalt]]), or after unstressed -zu- ([[aufzubewahren]])
	["unstressed"] = m_table.listToSet { "un", "stressed", "unstressed-zu" },
	-- unstressed -zu- can occur after stressed prefixes only ([[anzufangen]])
	["unstressed-zu"] = m_table.listToSet { "stressed" },
}


------------------------- Recognized prefixes -------------------------

--[=[
The following contains prefixes to be recognized specially, segmented off automatically and respelled appropriately.
The format of each entry is {PREFIX, RESPELLING, PROPS...} where PREFIX is the actual spelling of the prefix (without
any stress marks), RESPELLING is the appropriate phonemic respelling, spelled as if the prefix were a word by itself
(with appropriate acute and grave accents marking primary and secondary stress). PROPS are optional named properties;
see below. Order of the entries is important as they are checked in order. In particular, B must follow A if B is a
prefix of A. For example, "her" must follow "heraus", "herbei", "herüber", etc. and "un" must follow "unter".

The following named properties are currently recognized:
* 'restriction': Place additional restrictions on when the prefix can occur. Value is either a regex that must match
  the part of the word to the right of the prefix, or a list of such regexes, where one of them must match in the
  same fashion. An example is "emp", which has a restriction so that it is only recognized in the form "empf-", i.e.
  where the rest of the word begins with an f.
* 'prefixtype': Override the autodetected type of prefix, one of "stressed", "unstressed", "unstressed-zu" or "un".
  The types "stressed" and "unstressed" are autodetected and don't normally need to be given, but the other two must
  be given using 'prefixtype' whenever they are applicable.
* 'secstress': If the prefix is stressed, i.e. its respelling has an acute accent, this should specify the prefix --
  in its original form, not respelled form -- with the appropriate vowel given a grave accent. This can be omitted
  if the secondary stress goes on the first vowel. This is used so that the user can put secondary stress on a
  prefix (whether or not explicitly sectioned off using '<') and still have it recognized and respelled
  appropriately. An example is [[unkalkulierbar]], respelled 'ùnkalkulierbar', which generates /ˌʊnkalkuˈliːʁbaːʁ/.
  Note for example that the 'n' shows up as /n/ not /ŋ/ before 'k', and 'u' shows up as /ʊ/ not /u/, which indicates
  that 'ùn-' is correctly sectioned off as a prefix and given a respelling of 'ùnn-'.
* 'not_with_following_primary_stress': Do not recognize this prefix if there is a primary stress later on in the
  word. This is used with prefixes such as 'ab-', 'an-', 'her-', 'mit-', 'ur-' that frequently form non-prefix parts
  of foreign-origin words (e.g. [[abundant]], [[Animation]], [[hereditär]], [[mitigieren]], [[Urbanisierung]]).
  This is a heuristic as most foreign-origin words have non-initial stress; but it produces some false positives
  e.g. [[Abenteuer]], [[Annika]], [[Herkules]], [[uruguayisch]] (which need respelling like 'Ab+enteuer' with '+'
  to indicate no prefix boundary or alternatively 'Ábenteuer' with explicit stress) and occasional false negatives
  e.g. [[abalienieren]], [[anhand]] (which need respelling using '<', like 'an<hand' or 'àb<ali̯enieren'; the latter
  also puts secondary stress on the prefix, which will be propagated onto the respelling 'àbb', and uses 'i̯' to get
  a glide rather than 'ie' being interpreted as a long vowel).

Some prefixes can be both stressed and unstressed, e.g. durch-, unter-, über-, wieder-. For some, e.g. miss- and
wider-, there are systematic alternations in stress: unstressed when functioning as a verbal prefix followed by an
initial-stressed verb, stressed otherwise. This is too complex and unpredictable for us to handle, so we treat all
these prefixes as stressed. Respell using < when unstressed, e.g. 'umfahren' "to knock down with a vehicle",
'um<fahren' "to drive around, to bypass".
]=]

local prefixes = {
	-- To reduce false positives, we don't recognize when main part or suffix has primary stress, e.g. [[abandonnieren]]
	-- /abandɔnˈiːʁən/, [[Abasie]] /abaˈziː/, [[Abbreviation]] /abʁevi̯aˈt͡si̯oːn/, [[Abbreviatur]] /abʁevi̯aˈtuːʁ/,
	-- [[Abchasisch]] /apˈxaːzɪʃ/, [[abdominal]] /apdomiˈnaːl/, [[Abduktor]] /apˈdʊktoːʁ/, [[abessinisch]] /abɛˈsiːnɪʃ/,
	-- [[Abitur]] /ˌabiˈtuːʁ/, [[Abonnement]] /abɔnəˈmɑ̃ː/, [[abonnieren]] /abɔˈniːʁən/, [[Abort]] (one meaning)
	-- /aˈbɔʁt/, [[Abrasion]] /apʁaˈzi̯oːn/ or /abʁaˈzi̯oːn/, [[abrasiv]] /abʁaˈziːf/, [[Absence]] /apˈsãːs/, [[Absinth]]
	-- /apˈzɪnt/, [[absolut]] /apzoˈluːt/, [[Absolvent]] /apz̥ɔlˈvɛnt/, [[absorbieren]] /apzɔʁˈbiːʁən/, [[Absorption]]
	-- /apzɔʁpˈt͡si̯oːn/, [[abstinent]] /apstiˈnɛnt/, [[Abstinenz]] /apstiˈnɛnt͡s/, [[abstrahieren]] /apstʁaˈhiːʁən/,
	-- [[Abstraktum]] /apˈstʀaktʊm/, [[abstrus]] /apˈstʁuːs/, [[absurd]] /apˈzʊʁt/, [[Absurdität]] /ˌapzʊʁdiˈtɛːt/,
	-- [[Abtei]] /apˈtaɪ̯/, [[Abu Dhabi]] [[ˈabu ˈdaːbi]], [[Abulie]] /abuˈliː/, [[abundant]] /abʊnˈdant/.
	--
	-- We don't restrict to not preceding vowels because of words like [[abändern]], [[abarbeiten]], [[Abart]],
	-- [[abeisen]], [[aberkennen]], [[abirren]], [[abisolieren]], [[Abordnung]], [[Abort]] (one meaning).
	--
	-- We still have a few false positives needing '+', e.g. [[Abakus]] /ˈabakʊs/, [[Abend]] /ˈaːbənt/, [[Abenteuer]]
	-- /ˈaːbəntɔɪ̯ɐ/, ([[aber]] /ˈaːbɐ/; main part too short so won't be segmented in any case), [[Ablativ]]
	-- /ˈaplaˌtiːf/, [[Abraham]] /ˈaːbʁaˌha(ː)m/.
	--
	-- We have a few false negatives needing '<' or '<<', e.g. [[Abalienation]] /ˌapˌʔali̯enaˈt͡si̯oːn/, [[abalienieren]]
	-- /ˌapʔali̯eˈniːʁən/, [[abaxial]] /apʔaˈksi̯aːl/, [[abhanden]] /apˈhandən/, [[abscheulich]] /apˈʃɔɪ̯lɪç/.
	{"ab", "ább", not_with_following_primary_stress = true},
	{"aneinander", "ànn<einánder", secstress = "aneinànder"},
	{"anheim", "ann<héim", secstress = "anhèim"},
	-- Must follow aneinander- and anheim-.
	--
	-- To reduce false positives, we don't recognize when main part or suffix has primary stress, e.g. [[anabol]]
	-- /anaˈboːl/, [[Anabolikum]] /anaˈboːlikʊm/, [[anal]] /aˈnaːl/, [[analog]] /anaˈloːk/, [[Analogie]] /analoˈɡiː/,
	-- [[Analyse]] /anaˈlyːzə/, [[analysieren]] /ˌanalyːˈziːʁən/, [[Analysis]] /aˈnaːlyzɪs/, [[analytisch]]
	-- /ˌanaˈlyːtɪʃ/, [[anamorph]] /anaˈmɔʁf/, [[Anapäst]] /anaˈpɛːst/, [[Anaptyxe]] /anapˈtʏksə/, [[anarchisch]]
	-- /aˈnaʁxiʃ/, [[Anathema]] /aˈnaːtema/, [[Anatomie]] /anatoˈmiː/, [[anatomisch]] /anaˈtoːmɪʃ/, [[Anchovis]]
	-- /anˈʃoːvɪs/, [[Andalusien]] /ˌandaˈluːzi̯ən/, [[Andorraner]] /andɔˈʁaːnɐ/, [[Andrea]] /anˈdʁeːa/, [[Androgen]]
	-- /andʁoˈɡeːn/, [[androgyn]] /andʁoˈɡyːn/, [[Android]] /andʁoˈiːt/, [[Andrologie]] /andʁoloˈɡiː/, [[Anekdote]]
	-- /anɛkˈdoːtə/, [[Angela]] /aŋˈɡeːla/, [[Angeliter]] /aŋɡeˈliːtɐ/, [[Anglikaner]] /aŋɡliˈkaːnɐ/, [[Anglistik]]
	-- /aŋˈɡlɪstɪk/, [[Angola]] /aŋˈɡoːlaː/, [[angolanisch]] /aŋɡoˈlaːnɪʃ/, [[Anilingus]] /aniˈlɪŋɡʊs/, [[Animation]]
	-- /animaˈt͡si̯oːn/, [[animieren]] /aniˈmiːʁən/, [[Animosität]] /ˌanimoziˈtɛːt/, [[Anis]] /aˈniːs/, [[Annalen]]
	-- /aˈnaːlən/, [[annektieren]] /anɛkˈtiːʁən/, [[annullieren]] /anʊˈliːʁən/, [[anonym]] /ˌanoˈnyːm/, [[Anonymität]]
	-- /anonymiˈtɛːt/, [[Antagonismus]] /antaɡoˈnɪsmʊs/, [[Antenne]] /anˈtɛnə/, [[anterior]] /anˈteːʁioːʁ/,
	-- [[Anthrazit]] /ˌantʁaˈt͡siːt/ or /ˌantʁaˈt͡sɪt/, [[Anthropologie]] /antʁopoloˈɡiː/, [[anthropomorph]]
	-- /antʁopoˈmɔʁf/, [[Anthropomorphismus]] /ˌantʁopomɔʁˈfɪsmʊs/, [[Anthroposophie]] /antʁopozoˈfiː/, [[Antonym]]
	-- /antoˈnyːm/, [[Antonymie]] /antonyˈmiː/, [[Antwerpen]] /antˈvɛʁpən/.
	--
	-- We don't restrict to not preceding vowels because of words like [[anecken]] /ˈanˌʔɛkən/, [[Aneignung]]
	-- /ˈanˌʔaɪ̯ɡnʊŋ/, [[anekeln]] /ˈanˌʔeːkəln/, [[Anerbieten]] /ˈan(ʔ)ɛʁˌbiːtən/, [[anerkennen]] /ˈan(ʔ)ɛʁˌkɛnən/,
	-- [[anöden]] /ˈanˌʔøːdən/, [[anordnen]] /ˈanˌʔɔʁdnən/.
	--
	-- We still have some false positives needing '+', e.g. [[Ananas]] /ˈananas/, ([[Anden]] /ˈandən/; main part too
	-- short so won't be segmented in any case), [[anderens]] /ˈandərəns/, [[anderer]] /ˈandərər/, [[anderleuts]]
	-- /ˈandɐˌlɔɪ̯t͡s/, [[Aneis]] /ˈanaɪ̯s/, ([[Angel]] /ˈaŋəl/; main part too short so won't be segmented in any case),
	-- [[Angela]] /ˈaŋɡela/ or /ˈaŋəla/, [[angeln]] /ˈaŋəln/, ([[Anger]] /ˈaŋər/; main part too short so won't be
	-- segmented in any case), ([[Angler]] /ˈaŋlɐ/; main part too short so won't be segmented in any case), [[Anika]]
	-- /ˈaniˌka/, [[Anime]] /ˈanime/, ([[Anis]] /ˈaːnɪs/ or /ˈanɪs/; main part too short so won't be segmented in any
	-- case), [[ankern]] /ˈaŋkɐn/, ([[Anna]] /ˈʔana/; main part too short so won't be segmented in any case), [[Annam]]
	-- /ˈanam/, [[Annika]] /ˈaniˌka/, [[Anorak]] /ˈanoʁak/, [[Anton]] /ˈantoːn/ ([[Anus]] /ˈʔaːnʊs/; main part too
	-- short so won't be segmented in any case).
	--
	-- We have a few false negatives needing '<' or '<<': [[aneinander]] /anʔaɪ̯ˈnandɐ/, [[anhand]] /anˈhant/.
	--
	-- We add a restriction to not segment in anti-.
	{"an", "ánn", not_with_following_primary_stress = true, restriction = {"^[^t]", "^t[^i]"}},
	{"aufeinander", "auf<einánder", secstress = "aufeinànder"},
	-- Must follow aufeinander-.
	{"auf", "áuf"},
	{"auseinander", "aus<einánder", secstress = "auseinànder"},
	-- Must follow auseinander-.
	{"aus", "áus"},
	{"außer", "áußer"},
	{"beieinander", "bei<einánder", secstress = "beieinànder"},
	-- FIXME, secondary stress in beiseite should get demoted to tertiary when handling explicit secondary stress
	-- from user.
	{"beiseite", "beiséite", secstress = "beisèite"},
	-- Must follow beieinander-.
	{"bei", "béi"},
	-- Allow be- before -u- only in beur-, beun-; cf. [[beurlauben]], [[Beunruhigung]]. Must follow bei-.
	{"be", "bə", restriction = {"^[^ui]", "^u[rn]"}},
	{"dafür", "dafǘr", secstress = "dafǜr"},
	{"dagegen", "dagégen", secstress = "dagègen"},
	{"daher", "dahér", secstress = "dahèr"},
	{"dahinter", "dahínter", secstress = "dahìnter"},
	-- Must follow dahinter-.
	{"dahin", "dahínn", secstress = "dahìn"},
	{"daneben", "danében", secstress = "danèben"},
	-- To reduce false positives, we don't recognize when main part or suffix has primary stress, e.g. [[darauf]]
	-- /daˈʁaʊ̯f/, and additionally include a restriction to not segment when a vowel follows, e.g. the alternative
	-- pronunciation of [[darauf]] as /ˈdaːʁaʊ̯f/ (without this restriction we'd get #/ˈdaːʁˌʔaʊ̯f/). The
	-- `not_with_following_primary_stress` condition is mostly redundant given the non-vowel restriction.
	{"dar", "dár", not_with_following_primary_stress = true, restriction = "^" .. C},
	{"davon", "dafónn", secstress = "davòn"},
	{"davor", "dafór", secstress = "davòr"},
	{"dazu", "dazú", secstress = "dazù"},
	{"durcheinander", "durch<einánder", secstress = "durcheinànder"},
	-- Must follow durcheinander-.
	{"durch", "dúrch"},
	{"ein", "éin"},
	{"empor", "empór", secstress = "empòr"},
	-- Must follow empor-.
	{"emp", "emp", restriction = "^f"},
	{"entgegen", "entgégen", secstress = "entgègen"},
	{"entlang", "ent.láng", secstress = "entlàng"},
	{"entzwei", "ent.zwéi", secstress = "entzwèi"},
	-- Must follow entgegen- and entlang-.
	{"ent", "ent"},
	{"er", "err"},
	{"fort", "fórt"},
	{"gegenüber", "gehgen<ǘber", secstress = "gegenǜber"},
	-- Most words in 'gei-' aren't past participles, cf. [[Geier]], [[Geifer]], [[geifern]], [[Geige]], [[geigen]],
	-- [[Geiger]], [[geil]], [[geilo]], [[Geisel]], [[Geiser]], [[Geisha]], [[Geiß]], [[Geißel]], [[geißeln]],
	-- [[Geist]], [[Geister]], [[geistig]], [[Geiz]], [[geizen]]. There are only a few, e.g. [[geimpft]], which need
	-- respelling, e.g. 'ge<impft'. No restriction on 'geu-' because only one non-past-participle observed:
	-- [[Geusenwort]] (which needs respelling like 'Géusen-wort'), and there are various past participles in 'geu-',
	-- especially 'geur-'.
	{"ge", "gə", restriction = "^[^i]"},
	{"herab", "herrább", secstress = "heràb"},
	{"heran", "herránn", secstress = "heràn"},
	{"herauf", "herráuf", secstress = "heràuf"},
	{"heraus", "herráus", secstress = "heràus"},
	{"herbei", "herbéi", secstress = "herbèi"},
	{"herein", "herréin", secstress = "herèin"},
	{"hernieder", "herníeder", secstress = "hernìeder"},
	{"herüber", "herrǘber", secstress = "herǜber"},
	{"herum", "herrúmm", secstress = "herùm"},
	{"herunter", "herrúnter", secstress = "herùnter"},
	{"hervor", "herfór", secstress = "hervòr"},
	-- Must follow herab-, heran-, etc.
	--
	-- To reduce false positives, we don't recognize when main part or suffix has primary stress, e.g. [[Heraldik]]
	-- /heˈʁaldɪk/, [[Herbarium]] /hɛʁˈbaːʁi̯ʊm/, [[hereditär]] /heʁediˈtɛːʁ/, [[herein]] /hɛˈʁain/, [[Hermaphrodit]]
	-- /ˌhɛʁ.ma.fʁoˈdiːt/ or /ˌhɛʁm.ʔa.fʁoˈdiːt/, [[Hermelin]] /hɛʁməˈliːn/, [[Hermeneutik]] /ˌhɛʁmeˈnɔɪ̯tɪk/,
	-- [[hermetisch]] /hɛʁˈmeːtɪʃ/, [[hermitesch]] /hɛʁˈmiːtɛʃ/, [[Heroin]] /heʁoˈiːn/, [[heroisch]] /heˈʁoːɪʃ/,
	-- [[Herold]] /ˈheːrɔlt/, [[Herzegowina]] /ˌhɛʁt͡seˈɡoːvina/ or /ˌhɛʁt͡seɡoˈviːna/.
	--
	-- We still have some false positives needing '+', e.g. [[Herberge]] /ˈhɛʁˌbɛʁɡə/, [[Hering]] /ˈheːʁɪŋ/,
	-- [[Herkules]] /ˈhɛʁkuˌlɛs/, [[Herling]] /ˈheːʁ.lɪŋ/, [[Hermann]] /ˈhɛʁ.man/, ([[Heros]] /ˈheːʁɔs/; main part too
	-- short so won't be segmented in any case), [[Herrin]] /ˈhɛʁɪn/, [[herrisch]] /ˈhɛʁɪʃ/, [[herzig]] /ˈhɛʁt͡sɪç/,
	-- [[Herzog]] /ˈhɛʁˌt͡soːk/.
	{"her", "hér", not_with_following_primary_stress = true},
	{"hinab", "hinnább", secstress = "hinàb"},
	{"hinan", "hinnánn", secstress = "hinàn"},
	{"hinauf", "hinnáuf", secstress = "hinàuf"},
	{"hinaus", "hinnáus", secstress = "hinàus"},
	{"hindurch", "hindúrch", secstress = "hindùrch"},
	{"hinein", "hinnéin", secstress = "hinèin"},
	{"hintan", "hint<ánn", secstress = "hintàn"},
	{"hinterher", "hinter<hér", secstress = "hinterhèr"},
	{"hinter", "hínter"},
	{"hinüber", "hinnǘber", secstress = "hinǜber"},
	{"hinunter", "hinnúnter", secstress = "hinùnter"},
	{"hinweg", "hinwéck", secstress = "hinwèg"},
	-- Must follow hinab-, hinan-, etc.
	{"hin", "hínn"},
	-- too many false positives for in-
	{"miss", "míss"},
	{"mit", "mítt", not_with_following_primary_stress = true},
	{"nach", "nahch"},
	{"nebeneinander", "nehben<einánder", secstress = "nebeneinànder"},
	{"neben", "nében"},
	{"nieder", "níeder"},
	{"übereinander", "ühber<einánder", secstress = "übereinànder"},
	-- Must follow übereinander-.
	{"über", "ǘber"},
	-- Unstressed variant of über-. We include this for cases like [[zürucküberweisen]].
	{"über", "ühber"},
	-- umeinander- only dialectal (West Bavarian)
	{"um", "úmm"},
	{"unter", "únter"},
	-- Must follow unter-. Has its own prefixtype; cf. [[unvorhergesehen]] /ˈʊnfoːʁheːʁɡəˌzeːən/.
	{"un", "únn", prefixtype = "un"},
	-- To reduce false positives, we don't recognize when main part or suffix has primary stress, e.g. [[Urämie]]
	-- /uʁɛˈmiː/, [[Uran]] /uˈʁaːn/, [[uranhaltig]] /uˈʁaːnˌhaltɪç/, [[urban]] /ʊʁˈbaːn/, [[urbanisieren]]
	-- /ʊʁbaniˈziːʁən/, [[urbanophil]] /ʊʁbanoˈfiːl/, [[Urethan]] /uʁeˈtaːn/, [[urgieren]] /ʊʁˈɡiːʁən/, [[Urin]]
	-- /uˈʁiːn/, [[urinal]] /uʁiˈnaːl/, [[urinieren]] /uʁiˈniːʁən/, [[uroborisch]] /uˈʁoːboʁɪʃ/, [[Urologe]]
	-- /ˌuʁoˈloːɡə/, [[Urologin]] /ˌuʁoˈloːɡɪn/, [[urologisch]] /ˌuːʁoˈloːɡɪʃ/. We don't restrict to not preceding
	-- vowels because of words like [[uramerikanisch]], [[Uraufführung]], [[Ureinwohner]], [[Uropa]]. We still
	-- have a few false positives needing '+', e.g. [[Uranus]] /ˈuːʁanʊs/, [[uruguayisch]] /ˈuːʁuɡvaɪ̯ɪʃ/.
	--
	-- Stress pattern is like un-; [[Urabstimmung]] /ˈuːʁʔapˌʃtɪmʊŋ/, [[Uraufführung]] /ˈuːʁʔaʊ̯fˌfyːʁʊŋ/,
	-- [[uraufgeführt]] /ˈuːʁʔaʊ̯fɡəˌfyːʁt/, [[Ureinwohner]] /ˈuːʁʔaɪ̯nˌvoːnɐ/; note [[Urzustand]] given in dewikt as
	-- /ˈuːʁˌt͡suːʃtant/ but audio sounds more like /ˈuːʁt͡suːˌʃtant/.
	{"ur", "úr", prefixtype = "un", not_with_following_primary_stress = true},
	{"ver", "ferr"},
	-- vorab-: only [[vorabeintscheiden]]
	{"voran", "foránn", secstress = "voràn"},
	-- vorauf-: only [[voraufgehen]]
	{"voraus", "foráus", secstress = "voràus"},
	{"vorbei", "fohrbéi", secstress = "vorbèi"}, -- respell per dewikt pronun
	{"vorher", "fohrhér", secstress = "vorhèr"}, -- respell per dewikt pronun
	{"vorüber", "forǘber", secstress = "vorǜber"},
	-- Must follow voran-, voraus-, etc.
	{"vor", "fór"},
	{"weg", "wéck"},
	{"weiter", "wéiter"},
	{"wider", "wíder"},
	{"wieder", "wíeder"},
	{"zer", "zerr"},
	{"zueinander", "zu<einánder", secstress = "zueinànder"},
	{"zurecht", "zurécht", secstress = "zurècht"},
	{"zurück", "zurǘck", secstress = "zurǜck"},
	{"zusammen", "zusámmen", secstress = "zusàmmen"},
	-- Listed twice, first as stressed then as unstressed, because of zu-infinitives like [[anzufangen]]. At the
	-- beginning of a word, stressed zú- will take precedence, but after another prefix, stressed prefixes can't occur,
	-- and unstressed -zu- will occur. Must follow zueinander-, zurecht-, etc.
	{"zu", "zú"},
	-- We use a separate type for unstressed -zu- because it can be followed by another unstressed prefix, e.g.
	-- [[auszubedingen]], whereas normally two unstressed prefixes cannot occur.
	{"zu", "zu", prefixtype = "unstressed-zu"},
	{"zwischen", "zwíschen"},
}


------------------------- Recognized "component-like" suffixes -------------------------

--[=[
The following contains suffixes that maintain their stress after a stressed syllable, as in [[handfest]], [[reißfest]],
and "steal" the secondary stress, as in [[albtraumhaft]] /ˈalptʁaʊ̯mˌhaft/. The format of each entry is approximately
the same as for prefixes above. The differences are:
* Order matters, as for prefixes, but in this case the rule is that B must follow A if B is a suffix of A, e.g. "bar"
  must follow "ierbar" and "haft" must follow "schaft".
* The respelling can be a list of possible pronunciations, in which case multiple pronunciations are produced on
  output. This is used e.g. for "-sam", which has two possible pronunciations, with the vowel long or short.
  (FIXME: We don't actually support this yet.)
* There is an additional named property 'pos' that is intended to specify the resulting part of speech (a string, one
  of 'n' = noun, 'v' = verb, 'a' = adjective, 'b' = adverb, or a list of such strings). This is currently underused and
  may be deleted.
* The named properties 'prefixtype' and 'not_with_following_primary_stress' do not exist.
* The named property 'restriction' works as for prefixes except that it matches the part *before* the suffix. For
  example, "erweise" is restricted to follow a consonant.
]=]

local component_like_suffixes = {
	-- Not necessary; we split off -erweise in a first pass, and then -lich will be recognized.
	-- {"licherweise", ">lich>er-weise", pos = "b"},
	{"erweise", ">er--weise", restriction = C .. "$", pos = "b"},
	-- Examples: [[bibelfest]] /ˈbiːbəlˌfɛst/ (would be same if regular stress), [[bissfest]] /ˈbɪsˌfɛst/, [[handfest]]
	-- /ˈhantˌfɛst/, [[kratzfest]] /ˈkʁat͡sˌfɛst/, [[krisenfest]] /ˈkʁiːzənˌfɛst/ (would be same if regular stress),
	-- [[reißfest]] /ˈʁaɪ̯sˌfɛst/, [[säurefest]] /ˈzɔɪ̯ʁəˌfɛst/ (would be same if regular stress), [[schossfest]]
	-- /ˈʃɔsˌfɛst/, [[wasserfest]] /ˈvasɐˌfɛst/ (would be same if regular stress), [[witterungsfest]] /ˈvɪtəʁʊŋsˌfɛst/
	-- (would be same if regular stress)
	{"fest", "--fest", pos = "a"}, -- can follow a vowel as in [[säurefest]]
	-- Examples: [[akzentfrei]] /akˈt͡sɛntˌfʁaɪ̯/, [[alkoholfrei]] /alkoˈhoːlˌfʁaɪ̯/, [[apothekenfrei]] /apoˈteːkənˌfʁaɪ̯/
	-- (would be same if regular stress), [[bleifrei]] /ˈblaɪ̯ˌfʁaɪ̯/, [[bündnisfrei]] /ˈbʏntnɪsˌfʁaɪ̯/ (would be same if
	-- regular stress), [[einwandfrei]] /ˈaɪ̯nvantˌfʁaɪ̯/, [[erschütterungsfrei]] /ɛʁˈʃʏtəʁʊŋsˌfʁaɪ̯/ (would be same if
	-- regular stress), [[gastfrei]] /ˈɡastˌfʁaɪ̯/, [[gemeinfrei]] /ɡəˈmaɪ̯nˌfʁaɪ̯/, [[glutenfrei]] /ɡluˈteːnˌfʁaɪ̯/,
	-- [[holzschlifffrei]] /ˈhɔlt͡sʃlɪfˌfʁaɪ̯/, [[keimfrei]] /ˈkaɪ̯mˌfʁaɪ̯/, [[kontextfrei]] /ˈkɔntɛkstˌfʁaɪ̯/
	-- (would be same if regular stress), [[niederschlagsfrei]] /ˈniːdɐʃlaːksˌfʁaɪ̯/, [[nikotinfrei]] /nikoˈtiːnfʁaɪ̯/,
	-- [[rechtsfrei]] /ˈʁɛçt͡sˌfʁaɪ̯/, [[säurefrei]] /ˈzɔɪ̯ʁəˌfʁaɪ̯/ (would be same if regular stress), [[schadstofffrei]]
	-- /ˈʃaːtʃtɔfˌfʁaɪ̯/, [[schneefrei]] /ˈʃneːˌfʁaɪ̯/, [[schulfrei]] /ˈʃuːlˌfʁaɪ̯/, [[steuerfrei]] /ˈʃtɔɪ̯ɐˌfʁaɪ̯/,
	-- [[straffrei]] /ˈʃtʁaːfˌfʁaɪ̯/, [[stressfrei]] /ˈʃtʁɛsˌfʁaɪ̯/, [[unfallfrei]] /ˈʊnfalˌfʁaɪ̯/, [[versandkostenfrei]]
	-- /fɛʁˈzantkɔstənˌfʁaɪ̯/, [[vibrationsfrei]] /vibʁaˈt͡si̯oːnsˌfʁaɪ̯/, [[visafrei]] /ˈviːzaˌfʁaɪ̯/ (would be same if
	-- regular stress)
	{"frei", "--frei", pos = "a"},
	-- Examples: [[Arbeitslosigkeit]] /ˈaʁbaɪ̯t͡sˌloːzɪçkaɪ̯t/ (would be same if regular suffix), [[Arglosigkeit]]
	-- /ˈaʁkˌloːzɪçkaɪ̯t/, [[Ausnahmslosigkeit]] /ˈaʊ̯snaːmsloːzɪçkaɪ̯t/, [[Bedeutungslosigkeit]] /bəˈdɔɪ̯tʊŋsˌloːzɪçkaɪ̯t/
	-- (would be same if regular suffix), [[Charakterlosigkeit]] /kaˈʁaktɐˌloːzɪçkaɪ̯t/ (would be same if regular
	-- suffix), [[Gefühllosigkeit]] /ɡəˈfyːlˌloːzɪçkaɪ̯t/, [[Jugendarbeitslosigkeit]] /ˈjuːɡəntˌʔaʁbaɪ̯t͡sloːzɪçkaɪ̯t/
	-- (FIXME: our rules produce ˈjuːɡəntʔaʁbaɪ̯t͡sˌloːzɪçkaɪ̯t), [[Obdachlosigkeit]] /ˈɔpdaxˌloːzɪçkaɪ̯t/ (FIXME: dewikt
	-- and enwikt have no secondary stress), [[Pietätlosigkeit]] /ˌpiːəˈtɛːtlozɪçˌkaɪ̯t/ (FIXME: our rules produce
	-- ˌpiːəˈtɛːtˌlozɪçkaɪ̯t), [[Reglosigkeit]] /ˈʁeːkˌloːzɪçkaɪ̯t/ (FIXME: dewikt and enwikt have no secondary stress),
	-- [[Ruchlosigkeit]] /ˈʁuːxˌloːzɪçkaɪ̯t/ or /ˈʁʊxˌloːzɪçkaɪ̯t/, [[Rücksichtslosigkeit]] /ˈʁʏkzɪçt͡sˌloːzɪçkaɪ̯t/,
	-- [[Schlaflosigkeit]] /ˈʃlaːfloːzɪçkaɪ̯t/ (FIXME: dewikt and enwikt have no secondary stress),
	-- [[Teilnahmslosigkeit]] /ˈtaɪ̯lnaːmsˌloːzɪçkaɪ̯t/, [[Willenlosigkeit]] /ˈvɪlənˌloːsɪçkaɪ̯t/ (would be same if
	-- regular stress), [[Zügellosigkeit]] /ˈt͡syːɡəlˌloːzɪçkaɪ̯t/ (would be same if regular stress)
	{"losigkeit", "--losigkèit", pos = "n"},
	-- Examples: [[alternativlos]] /ˌaltɐnaˈtiːfˌloːs/, [[anstandslos]] /ˈanʃtant͡sˌloːs/, [[arglos]] /ˈaʁkˌloːs/,
	-- [[atemlos]] /ˈaːtəmˌloːs/ (would be same if regular suffix), [[ausdruckslos]] /ˈaʊ̯sdʁʊksˌloːs/, [[ausweglos]]
	-- /ˈaʊ̯sveːkˌloːs/, [[bargeldlos]] /ˈbaːʁɡɛltˌloːs/, [[bedingungslos]] /bəˈdɪŋʊŋsˌloːs/ (would be same if regular
	-- suffix), [[besitzlos]] /bəˈzɪt͡sˌloːs/ (FIXME: enwikt but not dewikt have secondary stress), [[charakterlos]]
	-- /kaˈʁaktɐˌloːs/ (would be same if regular suffix), [[einflusslos]] /ˈaɪ̯nflʊsˌloːs/, [[ersatzlos]] /ɛʁˈzat͡sˌloːs/,
	-- [[erwerbslos]] /ɛʁˈvɛʁpsˌloːs/, [[fraglos]] /ˈfʁaːkˌloːs/ (FIXME: dewikt and enwikt have no secondary stress),
	-- [[furchtlos]] /ˈfʊʁçtˌloːs/, [[gefühllos]] /ɡəˈfyːlˌloːs/, [[gesichtslos]] /ɡəˈzɪçt͡sˌloːs/, [[gottlos]]
	-- /ˈɡɔtˌloːs/, [[haarlos]] /ˈhaːʁˌloːs/, [[inhaltslos]] /ˈɪnhalt͡sˌloːs/, [[konkurrenzlos]] /kɔŋkʊˈʁɛnt͡sˌloːs/,
	-- [[kontrolllos]] /kɔnˈtʁɔlˌloːs/, [[kopflos]] /ˈkɔp͡fˌloːs/, [[leidenschaftslos]] /ˈlaɪ̯dənʃaft͡sˌloːs/,
	-- [[merkmallos]] /ˈmɛʁkmaːlˌloːs/, [[papierlos]] /paˈpiːʁˌloːs/, [[planlos]] /ˈplaːnˌloːs/, [[reglos]]
	-- /ˈʁeːkˌloːs/, [[schnurlos]] /ˈʃnuːʁˌloːs/, [[stillos]] /ˈʃtiːlˌloːs/ or /ˈstiːlˌloːs/, [[systemlos]]
	-- /zʏsˈteːmˌloːs/, [[tonlos]] /ˈtoːnˌloːs/, [[verständnislos]] /fɛʁˈʃtɛntnɪsˌloːs/ (would be same if regular
	-- prefix), [[zahnlos]] /ˈt͡saːnˌloːs/, [[zwanglos]] /ˈt͡svaŋˌloːs/
	{"los", "--los", pos = "a"},
	-- Not necessary; we split off -reich in a first pass, and then -nis will be recognized.
	-- {"nisreich", ">nis-reich", restriction = C .. "$", pos = "a"},
	-- Examples: [[anregungsreich]] /ˈanʁeːɡʊŋsˌʁaɪ̯ç/, [[einfallsreich]] /ˈaɪ̯nfalsˌʁaɪ̯ç/, [[einwohnerreich]]
	-- /ˈaɪ̯nvoːnɐˌʁaɪ̯ç/, [[geistreich]] /ˈɡaɪ̯stˌʁaɪ̯ç/, [[glorreich]] /ˈɡloːʁˌʁaɪ̯ç/, [[kohlenhydratreich]]
	-- /ˈkoːlənhydʁaːtˌʁaɪ̯ç/, [[nährstoffreich]] /ˈnɛːʁʃtɔfˌʁaɪ̯ç/, [[niederschlagsreich]] /ˈniːdɐʃlaːksˌʁaɪ̯ç/,
	-- [[ruhmreich]] /ˈʁuːmˌʁaɪ̯ç/, [[schneereich]] /ˈʃneːˌʁaɪ̯ç/, [[siegreich]] /ˈziːkˌʁaɪ̯ç/, [[tugendreich]]
	-- /ˈtuːɡəntˌʁaɪ̯ç/ (would be same if regular suffix), [[verlustreich]] /fɛʁˈlʊstˌʁaɪ̯ç/
	{"reich", "--reich", pos = "a"},
	-- Not necessary; we split off -voll in a first pass, and then -nis will be recognized.
	-- {"nisvoll", "nisfòll", restriction = C .. "$", pos = "a"},
	-- Examples: [[eindrucksvoll]] /ˈaɪ̯ndʁʊksˌfɔl/, [[gefühlvoll]] /ɡəˈfyːlˌfɔl/, [[geheimnisvoll]] /ɡəˈhaɪ̯mnɪsˌfɔl/
	-- (would be same if regular suffix), [[geräuschvoll]] /ɡəˈʁɔɪ̯ʃˌfɔl/, [[gramvoll]] /ˈɡʁaːmˌfɔl/ (NOTE: enwikt has
	-- no secondary stress here), [[humorvoll]] /huˈmoːʁˌfɔl/, [[klangvoll]] /ˈklaŋˌfɔl/, [[kraftvoll]] /ˈkʁaftˌfɔl/,
	-- [[maßvoll]] /ˈmaːsˌfɔl/, [[qualvoll]] /ˈkvaːlˌfɔl/, [[randvoll]] /ˈʁantˌfɔl/, [[respektvoll]] /ʁeˈspɛktˌfɔl/,
	-- [[rücksichtsvoll]] /ˈʁʏkzɪçt͡sˌfɔl/, [[unheilvoll]] /ˈʊnhaɪ̯lˌfɔl/, [[unschuldsvoll]] /ˈʊnʃʊlt͡sˌfɔl/,
	-- [[verantwortungsvoll]] /fɛʁˈʔantvɔʁtʊŋsˌfɔl/, [[wundervoll]] /ˈvʊndɐˌfɔl/ (would be same if regular suffix)
	{"voll", "--foll", pos = "a"},
	-- Examples: [[abschnittweise]] /ˈapʃnɪtˌvaɪ̯zə/, [[allerleiweise]] /ˈalɐlaɪ̯ˌvaɪ̯zə/, [[ansatzweise]] /ˈanzat͡sˌvaɪ̯zə/,
	-- [[ausnahmsweise]] /ˈaʊ̯snaːmsˌvaɪ̯zə/, [[beispielsweise]] /ˈbaɪ̯ʃpiːlsˌvaɪ̯zə/, [[esslöffelweise]] /ˈɛslœfəlˌvaɪ̯zə/,
	-- [[fallweise]] /ˈfalˌvaɪ̯zə/, [[haufenweise]] /ˈhaʊ̯fənˌvaɪ̯zə/ (would be same if regular suffix), [[leihweise]]
	-- /ˈlaɪ̯ˌvaɪ̯zə/, [[probeweise]] /ˈpʁoːbəˌvaɪ̯zə/ (would be same if regular suffix), [[quartalsweise]]
	-- /kvaʁˈtaːlsˌvaɪ̯zə/, [[scheibchenweise]] /ˈʃaɪ̯bçənˌvaɪ̯zə/, [[stückchenweise]] /ˈʃtʏkçənˌvaɪ̯zə/, [[stückweise]]
	-- /ˈʃtʏkˌvaɪ̯zə/, [[teilweise]] /ˈtaɪ̯lˌvaɪ̯zə/, [[versuchsweise]] /fɛʁˈzuːxsˌvaɪ̯zə/, [[zwangsweise]] /ˈt͡svaŋsˌvaɪ̯zə/
	{"weise", "--weise", pos = "a"},
}


------------------------- Recognized regular-stressing suffixes -------------------------

--[=[
The following contains suffixes that have regular suffix stress. That is, if stressed with secondary stress, they take
secondary stress only when the preceding syllable has no stress and there is no preceding secondary stress, e.g. for
-lein in [[Fingerlein]], [[Schwesterlein]] or [[Müllerlein]] /ˈmʏlɐˌlaɪ̯n/. In most words, this condition doesn't hold,
and so e.g. -lein has no stress, e.g. [[Äuglein]] /ˈɔɪ̯klaɪ̯n/ or [[Bäumlein]] /ˈbɔɪ̯mlaɪ̯n/. This includes secondary
stress of the type found in [[Ecklädlein]] /ˈɛkˌlɛːtlaɪn/, [[Hofkirchlein]] /ˈhoːfˌkɪʁçlaɪ̯n/, [[Apfelbäumlein]]
/ˈap͡fəlˌbɔɪ̯mlaɪ̯n/. This is contrary to the behavior of compounds-of-compounds like [[Hubschrauberlandeplatz]] and
[[Maulwurfshügel]] described above; by that rule, we'd expect #/ˈap͡fəlbɔɪ̯mˌlaɪ̯n/ or similar. Cf. similarly
[[Abhängigkeit]] /ˈapˌhɛŋɪçkaɪ̯t/.

The format of each entry is as for component-like suffixes above.

Note that vowel-initial suffixes are joined phonemically directly onto the preceding part, without any sort of morpheme
boundary. As a result, vowel-initial suffixes that bear no stress and require no respelling, such as "ung" and "isch",
do not need to be given here.
]=]

local suffixes = {
	{"ant", "ánt", pos = {"n", "a"}},
	{"anz", "ánz", pos = "n"},
	{"abel", "ábel", pos = "a"},
	{"ibel", "íbel", pos = "a"},
	-- I considered an exception for -mal but there are many counter-exceptions like [[normal]], [[minimal]],
	-- [[dermal]], [[dezimal]], [[prodromal]].
	{"al", "ál", pos = "a"},
	{"ierbar", "íerbàr", pos = "a"},
	-- Normally following consonant but there a few exceptions like [[abbaubar]], [[recyclebar]], [[unüberschaubar]].
	-- Cases like [[isobar]] will be respelled with an accent and not affected.
	{"bar", "bàr", pos = "a"},
	-- Restrict to not follow a vowel or s (except for -ss) to avoid issues with nominalized infinitives in -chen.
	-- Words with -chen after a vowel or s need to be respelled with '>chen', as in [[Frauchen]], [[Wodkachen]],
	-- [[Häuschen]], [[Bläschen]], [[Füchschen]], [[Gänschen]], etc. Occasional gerunds of verbs in -rchen may need
	-- to be respelled with '+chen' to avoid the preceding vowel being long, as in [[Schnarchen]].
	{"chen", "çen", pos = "n", restriction = {C_not_s .. "$", "ss$"}},
	{"erei", "əréi", pos = "n", restriction = C .. "$"},
	{"ei", "éi", pos = "n", restriction = C .. "$"},
	{"ent", "ént", pos = {"n", "a"}},
	{"enz", "énz", pos = "n"},
	-- -haft is down below -schaft
	{"heit", "hèit", pos = "n"},
	{"ie", "íe", restriction = C .. "$", pos = "n"},
	-- No restriction to not occur after a/e; [[kreieren]] does occur and noun form and verbs in -en after -aier/-eier
	-- should not occur (instead you get -aiern/-eiern). Occurs with both nouns and verbs.
	{"ieren", "íeren", pos = "v"},
	-- See above. Occurs with adjectives and participles, and also [[Gefiert]].
	{"iert", "íert", pos = "a"},
	-- See above. Occurs with nouns.
	{"ierung", "íerung", pos = "n"},
	-- "isch" not needed here; no respelling needed and vowel-initial
	{"tionismus", "zionísmus", restriction = "[^s]$", pos = "n"},
	{"ismus", "ísmus", pos = "n"},
	-- Restrict to not occur after -a or -e as it may form a diphthong ([[allermeist]], [[verwaist]], etc.). Words
	-- with suffix -ist after -a or -e need respelling, e.g. [[Judaist]], [[Atheist]], [[Deist]], [[Monotheist]].
	{"ist", "íst", respelling = "[^ae]$", pos = "n"},
	{"istisch", "ístisch", respelling = "[^ae]$", pos = "a"},
	{"iv", "ív", pos = {"n", "a"}},
	-- This entry causes unstressed -iv to still be lengthened. The previous entry won't apply when the main part has
	-- primary stress, in which case this entry applies.
	{"iv", "ihv", pos = {"n", "a"}},
	{"ierbarkeit", "íerbàhrkèit", pos = "n"},
	{"barkeit", "bàhrkèit", pos = "n"},
	{"schaftlichkeit", "schàft.lichkèit", pos = "n"},
	{"lichkeit", "lichkèit", pos = "n"},
	-- FIXME! Allow two replacement specs.
	-- {"samkeit", {"sahmkèit", "samkèit"}, pos = "n"},
	{"samkeit", "sahmkèit", pos = "n"},
	{"keit", "kèit", pos = "n"},
	-- See comment above about secondary stress.
	{"lein", "lèin", pos = "n"},
	{"barlich", "bàhrlich", pos = "a"},
	{"schaftlich", "schàft.lich", pos = "a"},
	{"lich", "lich", pos = "a"},
	-- Restrict to not be after -l (cf. [[Drilling]], [[Helling]], [[Marshalling]], [[Schilling]], [[Spilling]],
	-- [[Zwilling]]). Instances after vowels do occur ([[Dreiling]], [[Edeling]], [[Neuling]], [[Reling]]); words
	-- [[Feeling]], [[Homeschooling]] need respelling in any case.
	{"ling", "ling", restriction = "[^l]$", pos = "n"},
	-- Included because of words like [[Ergebnis]], [[Erlebnis]], [[Befugnis]], [[Begräbnis]], [[Betrübnis]],
	-- [[Gelöbnis]], [[Ödnis]], [[Verlöbnis]], [[Wagnis]], etc. Also [[Zeugnis]] with /k/ (syllable division 'g.n')
	-- instead of expected syllable division '.gn'. Only recognized when following a consonant to exclude [[Anis]],
	-- [[Denis]], [[Penis]], [[Spiritus lenis]], [[Tunis]] (although these would be excluded in any case for the
	-- pre-suffix part being too short). [[Tennis]] needs respelling 'Ten+nis'.
	{"nis", "nis", restriction = C .. "$", pos = "n"},
	{"or", "ohr", pos = "n"},
	{"ös", "ö́s", pos = "a"},
	-- Two possible pronunciations (long and short). Occurs after a vowel in [[grausam]] (also false positives
	-- [[Bisam]], [[Sesam]], which will be excluded as the pre-suffix part is too short).
	-- FIXME! Allow two replacement specs.
	-- {"sam", {"sahm", "sam"}, pos = "a"},
	{"sam", "sahm", pos = "a"},
	-- FIXME: Is the secondary stress correct? It occurs in some words in enwikt with an intervening unstressed
	-- syllable, as in [[Bauerschaft]], [[Leidenschaft]], [[Liegenschaft]], [[Mutterschaft]], [[Schwägerschaft]],
	-- [[Täterschaft]], [[Wissenschafterin]], [[Wissenschaftlerin]], [[Witwenschaft]], [[Zeugenschaft]], but not
	-- in many similar words, e.g. [[Bauernschaft]], [[Eigenschaft]], [[Elternschaft]], [[Errungenschaft]],
	-- [[Hundertschaft]], [[Komplizenschaft]], [[Leserschaft]], [[Partnerschaft]], [[Priesterschaft]],
	-- [[Rechenschaft]], [[Richterschaft]], [[Ritterschaft]], [[Schwangerschaft]], [[Vaterschaft]], [[Völkerschaft]],
	-- [[Wählerschaft]], [[Wanderschaft]], [[Wissenschaft]]. In dewikt, of the above words, [[Mutterschaft]] and
	-- [[Schwägerschaft]] (from the former list) and [[Elternschaft]] and [[Vaterschaft]] (from the latter list) are
	-- the only ones with secondary stress on -schaft.
	{"schaft", "schàft", pos = "n"},
	-- Examples: [[beispielhaft]] /ˈbaɪ̯ˌʃpiːlhaft/ (FIXME: dewikt and enwikt have no secondary stress but audio sounds
	-- more like our rendering), [[engelhaft]] /ˈɛŋəlˌhaft/, [[fabelhaft]] /ˈfaːbəlˌhaft/, [[gebresthaft]]
	-- /ɡəˈbʁɛsthaft/, [[glaubhaft]] /ˈɡlaʊ̯phaft/, [[habhaft]] /ˈhaːphaft/, [[kometenhaft]] /koˈmeːtənˌhaft/,
	-- [[mädchenhaft]] /ˈmɛːtçənhaft/, [[namhaft]] /ˈnaːmhaft/, [[rechtsfehlerhaft]] /ˈʁɛçt͡sˌfeːlɐhaft/,
	-- [[unstatthaft]] /ˈʊnˌʃtathaft/, [[vorbildhaft]] /ˈfoːʁˌbɪlthaft/
	{"haft", "hàft", pos = "a"},
	-- Almost all words in -tät are in -ität but a few aren't: [[Majestät]], [[Fakultät]], [[Pietät]], [[Pubertät]],
	-- [[Sozietät]], [[Varietät]]. Unlike most other suffixes, -tät after a consonant does not result in the
	-- preceding vowel being pronounced close. Cf. [[Fakultät]] /fakʊlˈtɛːt/.
	{"tät", "tä́t", pos = "n"},
	-- Unlike most other suffixes, -tion after a consonant does not result in the preceding vowel being pronounced
	-- close. Cf. [[Produktion]] /pʁodʊkˈt͡si̯oːn/, [[Konvention]] /kɔnvɛnˈt͡si̯oːn/.
	{"tion", "zión", restriction = "[^s]$", pos = "n"},
	-- This must follow -tion. Most words in -ion besides those in -tion are still end-stressed abstract nouns, e.g.
	-- [[Religion]], [[Version]], [[Union]], [[Vision]], [[Explosion]], [[Aggression]], [[Rebellion]], or other words
	-- with the same stress pattern, e.g. [[Skorpion]], [[Million]], [[Fermion]]. There are several in -ion that are
	-- various types of ions, e.g. [[Cadiumion]], [[Hydridion]], [[Gegenion]], which need respelling with a hyphen, and
	-- some miscellaneous words that aren't end-stressed, e.g. [[Amnion]], [[Champion]], [[Camion]], [[Ganglion]],
	-- needing respelling of various sorts.
	{"ion", "ión", restriction = C .. "$", pos = "n"},
	-- "ung" not needed here; no respelling needed and vowel-initial
}


-- Convert `text` into a string where Unicode characters >= 0xFFF0 are displayed in hex format.
local function reveal_unicode(text)
	local parts = {}
	for codepoint in mw.ustring.gcodepoint(text) do
		if codepoint >= 0xFFF0 then
			table.insert(parts, ("\\U+%X"):format(codepoint))
		else
			table.insert(parts, u(codepoint))
		end
	end

	return table.concat(parts)
end


local function reorder_accents(text)
	-- The order should be: (1) DOTUNDER (removed early), (2) */INVBREVEBELOW, (3) TILDE, (4) BREVE/CFLEX, (5) MACRON/ː,
	-- (6) ˈ and ˌ, (7) ACUTE/GRAVE/DOUBLEGRAVE.
	local function reorder_accent_string(accentstr)
		local accents = rsplit(accentstr, "")
		local accent_order = {
			[DOTUNDER] = 1,
			["*"] = 2,
			[INVBREVEBELOW] = 2,
			[TILDE] = 3,
			[BREVE] = 4,
			[CFLEX] = 4,
			[MACRON] = 5,
			["ː"] = 5,
			["ˈ"] = 6,
			["ˌ"] = 6,
			[ACUTE] = 7,
			[GRAVE] = 7,
			[DOUBLEGRAVE] = 7,
		}
		table.sort(accents, function(ac1, ac2)
			return accent_order[ac1] < accent_order[ac2]
		end)
		return table.concat(accents)
	end
	-- IPA stress marks as given by the user should precede a vowel; make them follow so they become part of the set of
	-- accents following a vowel.
	text = rsub(text, "([ˈˌ])(" .. V .. ")", "%2%1")
	text = rsub(text, "(" .. accent_c .. "+)", reorder_accent_string)
	-- Remove duplicate accents.
	text = rsub_repeatedly(text, "(" .. accent_c .. ")%1", "%1")
	return text
end

-- Apply canonical Unicode decomposition to text, e.g. è → e + ◌̀. But recompose ä ö ü so we can treat them as single
-- vowels, and recompose ç for use in respelling.
local function decompose(text)
	text = mw.ustring.toNFD(text)
	text = rsub(text, "." .. "[" .. DIA .. CEDILLA .. "]", {
		["a" .. DIA] = "ä",
		["A" .. DIA] = "Ä",
		["o" .. DIA] = "ö",
		["O" .. DIA] = "Ö",
		["u" .. DIA] = "ü",
		["U" .. DIA] = "Ü",
		["c" .. CEDILLA] = "ç",
		["C" .. CEDILLA] = "Ç",
	})
	return text
end
decompose = memoize(decompose)

-- Decompose the text, canonicalize in various ways, lowercase and split into words, returning each word along with
-- whether the word was initially capitalized.
--
-- The canonicalization does the following:
-- * remove leading, trailing and multiple spaces
-- * remove exclamation points, question marks and periods at end of sentence (elsewhere they become foot boundaries)
-- * convert commas and em/en dashes to foot boundaries
-- * handle special uses of capital letters (N = nasalization, O/U/I/Y after consonant = high glide, I/U after vowel =
--   near-high glide)
-- * convert macrons to long marks
-- * reorder accents appropriately
local function canonicalize_and_split_words(text)
	text = decompose(text)
	text = rsub(text, "%s+", " ")
	text = rsub(text, "^ ", "")
	text = rsub(text, " $", "")
	-- Capital N after a vowel (including after vowel + accent marks + possibly an h) denotes nasalization.
	text = rsub(text, "(" .. V .. accent_c .. "*)(h?)N", "%1" .. TILDE .. "%2")
	-- The user can use respelling with macrons but internally we convert to the long mark ː.
	text = rsub(text, MACRON, "ː")
	-- Reorder so ACUTE/GRAVE/DOUBLEGRAVE go last.
	text = reorder_accents(text)

	-- convert commas and em/en dashes to IPA foot boundaries
	text = rsub_repeatedly(text, "%s*[–—]%s*", " | ")
	-- comma must be followed by a space; otherwise it might denote absolute secondary stress
	text = rsub_repeatedly(text, "%s*,%s", " | ")
	-- period, question mark, exclamation point in the middle of a sentence or end of a non-final sentence -> IPA foot
	-- boundary; there must be a space after the punctuation, as we use ! and ? in component-separation indicators to
	-- control the production of glottal stops at the beginning of the next word.
	text = rsub_repeatedly(text, "([^%s])%s*[!?.]%s([^%s])", "%1 | %2")
	text = rsub(text, "[!?.]$", "") -- eliminate absolute phrase-final punctuation

	local result = {}
	for word in rgsplit(text, " ") do
		-- Lowercase the word and check if it was capitalized.
		local lcword = mw.getContentLanguage():lcfirst(word)
		local is_cap = lcword ~= word
		-- capital vowel between consonant and vowel represents a glide o̯/u̯/i̯/y̯
		word = rsub(word, "(" .. C .. "%.?)([OUIY])(" .. V .. ")", function(c, cap_v, v)
			return c .. ulower(cap_v) .. INVBREVEBELOW .. v
		end)
		-- Capital I/U after another vowel represents a near-high glide ɪ̯/ʊ̯; but conversion to these symbols happens
		-- late, so we need to maintain the I/U when lowercasing the word.
		word = rsub(word, "(" .. V .. accent_c .. "*)I", "%1" .. TEMP_I)
		word = rsub(word, "(" .. V .. accent_c .. "*)U", "%1" .. TEMP_U)
		word = ulower(word)
		word = rsub(word, TEMP_I, "I")
		word = rsub(word, TEMP_U, "U")
		table.insert(result, {word = ulower(word), is_cap = is_cap})
	end
	return result
end


-- Given a respelling (typically originating from one of the lists of known prefixes or suffixes), replace ACUTE/GRAVE
-- with their autogenerated equivalent characters. The reason for doing this is that in the affix list, we specify the
-- respelling with acute/grave accents for convenience, but ultimately when we substitute the affix respelling for the
-- original affix spelling we need to mark the accents as autogenerated since the user didn't explicitly specify the
-- accents.
local function replace_stress_with_auto(respelling)
	respelling = gsub(respelling, ACUTE, AUTOACUTE)
	respelling = gsub(respelling, GRAVE, AUTOGRAVE)
	return respelling
end


-- Check a user-specified affix `affix` against a known list of affixes in `affix_specs`. If the affix is found, return
-- the corresponding respelling given in `affix_specs`. This respelling is originally given in `affix_specs` with acute
-- and grave accents marking primary and secondary stress; decompose and convert the accents to their auto-variants
-- (ACUTE -> AUTOACUTE, GRAVE -> AUTOGRAVE), since the user didn't originally specify them. Furthermore, if
-- `replace_stress_with_double_grave` is given, convert acute and grave accents to double-grave (tertiary stress),
-- so that stressed vowels are still lengthened in open syllables but no visible stress marker is included.
--
-- In addition, for affixes in `affix_specs` that have primary stress, if the user-specified affix includes secondary
-- stress on the stressed syllable but otherwise matches, return the corresponding respelling with primary stress
-- (acute) replaced with secondary stress (grave). Here, we do not convert to AUTOGRAVE because the secondary stress
-- was explicitly given by the user.
--
-- If no affixes match, return nil.
local function check_for_affix_respelling(affix, affix_specs, replace_stress_with_double_grave)
	for _, spec in ipairs(affix_specs) do
		if affix == spec[1] then
			local respelling = decompose(spec[2])
			respelling = replace_stress_with_auto(respelling)
			if replace_stress_with_double_grave then
				-- The user didn't request stress, so replace stress marks with double-grave, which preserves length
				-- in originally stressed syllables (e.g. in über-).
				respelling = rsub(respelling, stress_c, DOUBLEGRAVE)
			end
			return respelling
		end
	end

	-- Also check for secondary-stress variant.
	for _, spec in ipairs(affix_specs) do
		local respelling = decompose(spec[2])
		if rfind(respelling, ACUTE) then
			local secstressed_affix = spec.secstress or rsub(spec[1], "^(.-" .. V .. accent_c .. "*)", "%1" .. GRAVE)
			if affix == secstressed_affix then
				return rsub(respelling, ACUTE, GRAVE)
			end
		end
	end

	return nil
end


-- Check if `cluster` (a consonant cluster) matches any of the patterns in `patterns`, which are intended to contain
-- allowable onsets or offsets. Matching is anchored on both ends.
local function check_onset_offset(cluster, patterns)
	for _, pattern in ipairs(patterns) do
		if rfind(cluster, "^" .. pattern .. "$") then
			return true
		end
	end
	return false
end


-- Check text against a pattern restriction. If it matches, return true; otherwise, return false. If the restriction
-- is a list of patterns, return true if any of them matches.
local function meets_restriction(rest, restriction)
	if restriction == nil then
		-- no restriction.
		return true
	end
	if type(restriction) == "table" then
		-- If any of the restrictions pass, the affix is restricted.
		for _, restrict in ipairs(restriction) do
			if rfind(rest, restrict) then
				return true
			end
		end
	else
		if rfind(rest, restriction) then
			return true
		end
	end
	return false
end


-- "Demote" grave to double-grave, and maybe acute to grave.
local function demote_stress(part, demote_acute)
	part = rsub(part, "[" .. GRAVE .. AUTOGRAVE .. ORIG_SUFFIX_GRAVE .. "]", DOUBLEGRAVE)
	if demote_acute then
		part = rsub(part, AUTOACUTE, AUTOGRAVE)
		part = rsub(part, ACUTE, GRAVE)
	end
	return part
end


-- Add `accent_to_add` to the first vowel of `mainpart`. But don't add it to initial 'y' + vowel, as in [[Yacht]], and
-- don't add it to a vowel indicated as nonsyllabic, e.g. [[Pointe]] respelled 'POẽte' or 'Po̯ẽte'.
local function add_stress_to_mainpart(mainpart, accent_to_add)
	local changed
	-- First check for nonsyllabic vowel as first vowel, and add to the following vowel.
	mainpart, changed = rsubb(mainpart, "^(" .. non_V .. "*" .. V .. INVBREVEBELOW .. non_V .. "*" .. V .. accent_c .. "*)",
		"%1" .. accent_to_add)
	if changed then
		return mainpart
	end
	-- Then check for initial y + vowel.
	mainpart, changed = rsubb(mainpart, "^(y" .. V .. accent_c .. "*)", "%1" .. accent_to_add)
	if changed then
		return mainpart
	end
	-- Finally add to first vowel (if any).
	return rsub(mainpart, "^(" .. non_V .. "*" .. V .. accent_c .. "*)", "%1" .. accent_to_add)
end


-- Split a word into components and split off any prefixes or suffixes. On entry, components are separated by '-' or
-- '--'. Prefixes may be explicitly notated using '<' and suffixes using '>'. A component may be prefixed with '*' to
-- indicate it takes primary stress and '**' to indicate secondary stress; otherwise, the first component takes
-- primary stress and all others take secondary stress. On exit, (1) stress marks are added to components and affixes
-- as appropriate; (2) component boundaries are indicated by ⁀; (3) prefix-prefix and prefix-mainpart boundaries are
-- indicated by ⁀; (4) suffix-suffix and mainpart-suffix boundaries are indicated by ‿; (5) word boundaries are
-- indicated by ⁀⁀.
--
-- The following parameters are used:
-- * `word` is the word to split.
-- * `pos` is the "part of speech" (currently underused).
-- * `affix_type` is "prefix" if the word itself is a prefix (indicated by '-' at the end of the word), "suffix" if
--   the word itself is a suffix (indicated by '-' at the beginning of the word), else nil.
-- * `depth` is used internally to handle components separated by '-' and '--': at depth 0 (or nil), we split on '--'
--   and recursively process each component; at depth 1, we further split on '-' and recursively process each
--   component; at depth 2 we do the actual work of handling prefixes and suffixes and assigning stress.
-- * `is_compound` is true when this function is called recursively and there is more than one component. In this case,
--   original secondary stress is demoted to tertiary (double-grave) stress (which causes vowels in open syllables to
--   lengthen, as with primary and secondary stress, but does not display with an explicit stress mark), and original
--   primary stress is demoted to secondary stress if the component does not carry primary stress.
local function split_word_on_components_and_apply_affixes(word, pos, affix_type, depth, is_compound)
	depth = depth or 0

	-- First check for component-like suffixes. An example is '-los', which, from the point of view of stress, behave
	-- similarly to a separate component; cf. [[Ausdruck]] 'Áusdrùck' but [[ausdrucklos]] 'áusdrucklòs' as if it were
	-- 'ausdruck-los'. Normal suffix behavior would lead to #'áusdrùcklos'.
	if depth == 0 then
		local has_double_dash = rfind(word, "%-%-")

		local function respell_respelling(respelling)
			if has_double_dash then
				respelling = rsub(respelling, "%-%-", "-")
			end
			return respelling
		end

		local components = strutils.capturing_split(word, "(%-%-?)")
		for i, component in ipairs(components) do
			if i % 2 == 1 then -- component, not separator
				local parts = strutils.capturing_split(component, "([<>]+)")
				local j = #parts
				while j >= 1 do
					if j > 1 and parts[j - 1] == ">>" then -- suffix
						local respelling = check_for_affix_respelling(parts[j], component_like_suffixes)
						if respelling then
							parts[j] = respell_respelling(respelling)
							parts[j - 1] = ""
						end
					else
						-- FIXME! Handle secondary-stressed suffixes.
						for _, suffixspec in ipairs(component_like_suffixes) do
							local suffix_pattern = suffixspec[1]
							local rest = rmatch(parts[j], "^(.-)" .. suffix_pattern .. "$")
							if rest then
								if not meets_restriction(rest, suffixspec.restriction) then
									-- restriction not met, don't split here
								elseif rfind(rest, "%+$") then
									-- explicit non-boundary here, so don't split here
								elseif not rfind(rest, V) then
									-- no vowels, don't split here
								else
									-- Use non_V so that we pick up things like explicit syllable divisions, which we
									-- check for below.
									local before_cluster, final_cluster = rmatch(rest, "^(.-)(" .. non_V .. "*)$")
									if rfind(final_cluster, "%..") then
										-- syllable division within or before final cluster, don't split here
									else
										parts[j] = rest .. respell_respelling(suffixspec[2])
										break
									end
								end
							end
						end
					end
					j = j - 2
				end
				components[i] = table.concat(parts)
			end
		end
		word = table.concat(components)
	end

	-- If at depth 0, split on --, recursively process the parts, and combine. Similarly, at depth 1, split on -,
	-- recursively process the parts, and combine. At depth 2 we do the actual work.
	if depth == 0 or depth == 1 then
		local parts = rsplit(word, depth == 0 and "%-%-" or "%-")
		if #parts == 1 then
			return split_word_on_components_and_apply_affixes(word, pos, affix_type, depth + 1, is_compound)
		else
			-- Figure out which components bear primary stress. We check for * or + before a component, which indicates
			-- primary stress. If * is used, the component stress "propagates" up to top level. For example, in
			-- a compound of the form A-B--C-*D, subcomponent D gets primary stress and component C-D also gets primary
			-- stress, whereas in a compound of the form A-B--C-+D, subcomponent D gets primary stress but component
			-- C-D gets secondary stress, with the primary component stress on A-B (meaning that relative primary
			-- stress on D ends up as absolute secondary stress, whereas relative primary stress on A ends up as
			-- absolute primary stress and relative primary stress on B and C end up as absolute tertiary stress).
			local stresses = {}
			-- Did we see explicit stress on a non-initial component? If so, the first component doesn't get primary
			-- stress.
			local saw_non_initial_stress = false
			-- Did we see explicit '*'? If so, propagate it up so the higher-level component also bears stress.
			local saw_explicit_propagating_stress = false

			-- First, pull out * and + indicators.
			for i, part in ipairs(parts) do
				local rest
				local stress_marker, rest = rmatch(part, "^([*+])(.-)$")
				if stress_marker then
					stresses[i] = true
					parts[i] = rest
					if i > 1 then
						saw_non_initial_stress = true
					end
				end
				if stress_marker == "*" then
					saw_explicit_propagating_stress = true
				end
			end

			-- Recursively compute the stress.
			for i, part in ipairs(parts) do
				local saw_explicit_stress
				parts[i], saw_explicit_stress = split_word_on_components_and_apply_affixes(part, pos, affix_type, depth + 1, "is compound")
				if saw_explicit_stress then
					-- * was used in a non-initial subcomponent. The component containing this subcomponent also
					-- gets primary stress.
					stresses[i] = true
					if i > 1 then
						saw_non_initial_stress = true
					end
					saw_explicit_propagating_stress = true
				end
			end

			-- Initial component gets auto-stressed unless another component was explicitly marked as such.
			if not saw_non_initial_stress then
				stresses[1] = true
			end

			-- Now "demote" the component stresses. Secondary stress becomes tertiary, and primary stress becomes
			-- secondary unless the component is marked for primary stress.
			for i, part in ipairs(parts) do
				parts[i] = demote_stress(part, not stresses[i])
			end

			-- Finally, put the components together.
			return table.concat(parts, "⁀"), saw_explicit_propagating_stress
		end
	end

	-- Interaction between stresses in prefix/mainpart/suffix:
	-- 1. By default, a normally stressed suffix like -ieren takes secondary stress if there is a stressed prefix.
	-- Cf. [[ausprobieren]] /ˈʔaʊ̯spʁoˌbiːʁən/, [[ausstaffieren]] /ˈaʊ̯sʃtaˌfiːʁən/, [[aufaddieren]] /ˈaʊ̯fʔaˌdiːʁən/,
	-- [[aufmarschieren]] /ˈaʊ̯fmaʁˌʃiːʁən/, [[anprobieren]] /ˈanpʁoˌbiːʁən/, [[anlegieren]] /ˈanleˌɡiːʁən/,
	-- [[überdosieren]] /ˈyːbɐdoˌziːʁən/, [[überreagieren]] /ˈyːbɐʁeaˌɡiːʁən/.
	-- 2. If the mainpart is given an explicit primary stress, sometimes a prefix gets secondary stress, sometimes not.
	-- We handle this by assuming a prefix has no stress in this situation. If the prefix needs secondary stress, add
	-- it explicitly; we will still recognize the prefix provided it is stressable (e.g. vor- but not ver-, which is
	-- always unstressed).
	-- 3. If a suffix is given explicit primary stress, the same rules apply as in (2).

	local retparts = {}
	local parts = strutils.capturing_split(word, "([<>])")
	-- The type of the preceding prefix. Used to implement a finite state machine to track allowable combinations of
	-- prefixes.
	local previous_prefixtype = nil
	-- Have we seen stressed un- previously? If so, a following stressed suffix loses its stress, while the main part
	-- gets secondary stress, cf. [[unausgegoren]] 'únausgegòren'.
	local saw_primary_un_stress = false
	-- Have we seen a stressed prefix previously (user or auto)? If so, the main part gets secondary stress.
	local saw_primary_prefix_stress = false
	-- Have we seen two primary stressed prefixes (user or auto), as in [[überbeanspruchen]] 'ǘberbeànspruchen'? If so, the
	-- main part loses its stress.
	local saw_double_primary_prefix_stress = false
	-- Have we seen a primary-stressed suffix like -anz or -ieren (user or auto)? If so, the main part loses its stress.
	local saw_primary_suffix_stress = false
	-- Have we seen a suffix with explicit user-specified primary stress? If so, prefixes get secondary stress.
	local saw_user_primary_suffix_stress = false

	local function replace_part_with_multiple_parts(new_parts, inspos, separator)
		-- Replace the original part that the new parts were derived from.
		parts[inspos] = new_parts[1]
		local i = 2
		for i=2, #new_parts do
			inspos = inspos + 1
			table.insert(parts, inspos, separator)
			inspos = inspos + 1
			table.insert(parts, inspos, new_parts[i])
		end
	end

	local function has_user_specified_primary_stress(part)
		-- If there are multiple components (separated by - or --), we want to treat explicit user-specified
		-- absolute secondary stress like primary stress because we only show the component primary stresses.
		-- The overall word primary stress shows as ˈ and other component primary stresses show as ˌ.
		return rfind(part, "[" .. ACUTE .. "ˈ]") or is_compound and rfind(part, "ˌ")
	end

	-- FIXME! Handle absolute stresses using ˈ and ˌ.
	-- FIXME! Clarify why we still need AUTOACUTE and AUTOGRAVE when they are relative.

	-- Break off any explicitly-specified prefixes.
	local from_left = 1
	-- FIXME! Recognize <<.
	while from_left < #parts and parts[from_left + 1] == "<" do
		local prefix = parts[from_left]
		local unstressed_prefix = rsub(prefix, stress_c, "")
		if unstressed_prefix == "un" or unstressed_prefix == "ur" then
			previous_prefixtype = "un"
		elseif rfind(prefix, stress_c) then
			previous_prefixtype = "stressed"
		elseif prefix == "zu" then
			previous_prefixtype = "unstressed-zu"
		else
			previous_prefixtype = "unstressed"
		end
		if has_user_specified_primary_stress(prefix) then
			saw_primary_prefix_stress = true
			if previous_prefixtype == "un" then
				saw_primary_un_stress = true
			end
		end
		-- The user didn't request stress, so replace stress marks with double-grave, which preserves length
		-- in originally stressed syllables (e.g. in über-).
		local respelling = check_for_affix_respelling(prefix, prefixes, "replace stress with double grave")
		local must_continue = false
		if respelling then
			local respelling_parts = rsplit(respelling, "<")
			if #respelling_parts > 1 then
				replace_part_with_multiple_parts(respelling_parts, from_left, "<")
				must_continue = true
			end
		end
		if not must_continue then
			table.insert(retparts, prefix)
			from_left = from_left + 2
		end
	end

	-- Break off any explicitly-specified suffixes.
	local insert_position = #retparts + 1
	local from_right = #parts
	-- FIXME! Recognize >>.
	while from_right > 1 and parts[from_right - 1] == ">" do
		if has_user_specified_primary_stress(parts[from_right]) then
			saw_user_primary_suffix_stress = true
			saw_primary_suffix_stress = true
		end
		-- FIXME! Use check_for_affix_respelling().
		table.insert(retparts, insert_position, parts[from_right])
		from_right = from_right - 2
	end
	if from_left ~= from_right then
		error("Saw < to the right of > in word: " .. word)
	end

	local mainpart = parts[from_left]
	local saw_user_primary_mainpart_stress = has_user_specified_primary_stress(mainpart)

	-- Split off any remaining suffixes. Do this before splitting prefixes as for some prefixes (e.g. ur-) we need to
	-- know if there is a stressed suffix.
	while true do
		-- If there was a user-specified suffix with explicit stress, don't try to look for more suffixes.
		if saw_user_primary_suffix_stress then
			break
		end
		local broke_suffix = false
		-- FIXME! Handle secondary-stressed suffixes.
		-- FIXME! Handle restrictions on -chen suffix (initial capital unless component-like suffix occurs as in
		-- [[scheibchenweise]]).
		for _, suffixspec in ipairs(suffixes) do
			local suffix_pattern = suffixspec[1]
			local rest = rmatch(mainpart, "^(.-)" .. suffix_pattern .. "$")
			if rest then
				if not meets_restriction(rest, suffixspec.restriction) then
					-- restriction not met, don't split here
				elseif rfind(rest, "%+$") then
					-- explicit non-boundary here, so don't split here
				elseif not rfind(rest, V) then
					-- no vowels, don't split here
				else
					local suffix_respell = decompose(suffixspec[2])
					if saw_user_primary_mainpart_stress and rfind(suffix_respell, ACUTE) then
						-- primary-stressed suffix like -iert but main part already has primary stress; don't split here
					else
						-- Use non_V so that we pick up things like explicit syllable divisions, which we
						-- check for below.
						local before_cluster, final_cluster = rmatch(rest, "^(.-)(" .. non_V .. "*)$")
						if rfind(final_cluster, "%..") then
							-- syllable division within or before final cluster, don't split here
						else
							-- break the word in two; next iteration we process the rest, which may need breaking
							-- again
							mainpart = rest

							-- We may remove the suffix grave entirely later on. For now, convert it to a special
							-- symbol so we can handle it properly later (in handle_suffix_secondary_stress), after
							-- splitting on syllables.
							suffix_respell = gsub(suffix_respell, GRAVE, ORIG_SUFFIX_GRAVE)
							if rfind(suffix_respell, ACUTE) then
								saw_primary_suffix_stress = true
								-- If there is primary prefix stress, we later convert this to AUTOGRAVE.
								suffix_respell = gsub(suffix_respell, ACUTE, AUTOACUTE)
							end
							table.insert(retparts, insert_position, suffix_respell)
							broke_suffix = true
							break
						end
					end
				end
			end
		end
		-- There is a surrounding loop with the idea that we could handle multiple suffixes (e.g. inflectional suffixes), but
		-- it seems unlikely we will do so.
		break
	end

	-- Split off any remaining prefixes.
	while true do
		local broke_prefix = false
		for _, prefixspec in ipairs(prefixes) do
			local prefix_pattern = prefixspec[1]
			local prefix_respell = decompose(prefixspec[2])
			local stressed_prefix = rfind(prefix_respell, ACUTE)
			local prefix, rest = rmatch(mainpart, "^(" .. prefix_pattern .. ")(.*)$")
			if not prefix and stressed_prefix then
				-- Also check for secondary-stress variant.
				local secstressed_prefix = prefixspec.secstress or
					rsub(prefix_pattern, "^(.-" .. V .. accent_c .. "*)", "%1" .. GRAVE)
				prefix, rest = rmatch(mainpart, "^(" .. secstressed_prefix .. ")(.*)$")
				if prefix then
					prefix_respell = rsub(prefix_respell, ACUTE, GRAVE)
				end
			end
			if prefix then
				local prefixtype = prefixspec.prefixtype or stressed_prefix and "stressed" or "unstressed"
				if prefixspec.not_with_following_primary_stress and (
					saw_user_primary_mainpart_stress or saw_primary_suffix_stress) then
					-- prefix not allowed when mainpart or suffix stress, don't split here
				elseif not meets_restriction(rest, prefixspec.restriction) then
					-- restriction not met, don't split here
				elseif rfind(rest, "^%+") then
					-- explicit non-boundary here, so don't split here
				elseif not rfind(rest, V) then
					-- no vowels, don't split here
				elseif rfind(rest, "^..?$") then
					-- only two letters, unlikely to be a word, probably an ending, so don't split
					-- here
				else
					-- Use non_V so that we pick up things like explicit syllable divisions, which will
					-- prevent the allowed-onset check from succeeding.
					local initial_cluster, after_cluster = rmatch(rest, "^(" .. non_V .. "*)(.-)$")
					if not check_onset_offset(initial_cluster, allowed_onsets) then
						-- initial cluster isn't a possible onset, don't split here
					elseif rfind(after_cluster, "^" .. V .. "?$") then
						-- remainder is a cluster + single vowel, unlikely to be a word so don't split here
						-- most such words have impermissible onsets, but cf. [[Beta]], [[Bete]], [[Bede]],
						-- [[Bethe]], [[Geste]], [[verso]], [[Verve]], [[vorne]], [[Erbe]], [[Erde]], [[ergo]],
						-- [[Erle]], [[erste]],  etc.
					elseif not rfind(prefix, stress_c) and rfind(after_cluster, "^e" .. C_not_h .. "$") then
						-- remainder is a cluster + e + single consonant after an unstressed prefix, unlikely
						-- to be a word so don't split here; most such words have impermissible onsets, but cf.
						-- [[Bebel]], [[beben]], [[Besen]], [[beten]], [[geben]], [[Geber]], [[gegen]],
						-- [[gehen]], [[geten]], [[Becher]], [[Gegner]], [[Verschen]], [[erben]], [[erden]],
						-- [[Erker]], [[erlen]], [[Erpel]], [[erzen]], [[Erster]], etc.; a few legitimate
						-- prefixed words get rejected, e.g. [[Beleg]], [[Gebet]], which need respelling
					elseif previous_prefixtype and not prefix_previous_allowed_states[prefixtype][previous_prefixtype] then
						-- disallowed prefixtype transition
					else
						-- break the word in two; next iteration we process the rest, which may need breaking
						-- again
						mainpart = rest
						previous_prefixtype = prefixtype
						prefix_respell = replace_stress_with_auto(prefix_respell)
						if rfind(prefix_respell, AUTOACUTE) then
							-- Stressed prefix. If we've seen un- already, the prefix loses its stress (marked with
							-- double grave to preserve length on the stressed syllable, in über-); cf. [[unausgegoren]]
							-- 'únausgegòren'. Otherwise if we've seen a stressed prefix, the prefix gets secondary
							-- stress, cf. [[überbeanspruchen]] 'ǘberbeànspruchen'. Otherwise it retains primary
							-- stress.
							if saw_primary_un_stress then
								prefix_respell = gsub(prefix_respell, AUTOACUTE, DOUBLEGRAVE)
							elseif saw_primary_prefix_stress or saw_user_primary_mainpart_stress or saw_user_primary_suffix_stress then
								if saw_primary_prefix_stress then
									-- main part should not get stress, as in [[überbeanspruchen]]
									saw_double_primary_prefix_stress = true
								end
								prefix_respell = gsub(prefix_respell, AUTOACUTE, AUTOGRAVE)
							end
							saw_primary_prefix_stress = true
						end
						-- Split on < (e.g. for auseindander- respelled 'aus<einánder') and insert each part.
						local prefix_respell_parts = rsplit(prefix_respell, "<")
						for _, part in ipairs(prefix_respell_parts) do
							table.insert(retparts, insert_position, part)
							insert_position = insert_position + 1
						end
						broke_prefix = true
						break
					end
				end
			end
		end
		if not broke_prefix then
			break
		end
	end

	if rfind(mainpart, DOTUNDER) then
		-- remove DOTUNDER but don't accent
		mainpart = gsub(mainpart, DOTUNDER, "")
	elseif saw_user_primary_mainpart_stress or saw_primary_suffix_stress or saw_double_primary_prefix_stress then
		-- do nothing
	elseif rfind(mainpart, "^" .. non_V .. "*" .. V .. accent_c .. "*" .. stress_c) then
		-- first vowel already followed by a stress accent; do nothing
	elseif saw_primary_prefix_stress and rfind(mainpart, GRAVE) then
		-- going to add secondary stress but secondary stress already present, e.g. [[hinausposaunen]] respelled
		-- 'hinausposàunen'; do nothing
	else
		-- Add primary or secondary stress on the part; primary stress if no primary stress yet, otherwise secondary
		-- stress.
		local accent_to_add = saw_primary_prefix_stress and AUTOGRAVE or AUTOACUTE
		mainpart = add_stress_to_mainpart(mainpart, accent_to_add)
	end
	table.insert(retparts, insert_position, mainpart)
	insert_position = insert_position + 1

	-- remove any +, which has served its purpose
	for i, part in ipairs(retparts) do
		retparts[i] = gsub(part, "%+", "")
	end

	-- Put components together. Put ⁀ between two prefixes or between prefix and main part. Suffixes may join directly
	-- to preceding part; otherwise, put ‿ before a suffix.
	local wordparts = {}
	for i, part in ipairs(retparts) do
		if i >= insert_position then
			-- Handling a suffix. Vowel-initial suffixes join directly to the preceding part so that e.g. written 'ig'
			-- is pronounced as IPA /ɪɡ/ not as /ɪç/. Primary-stressed consonant-initial suffixes (-tät, -tion) also
			-- join directly to the preceding part so that a preceding vowel-consonant sequence as in [[Fakultät]],
			-- [[Konvention]] does not result in a close vowel, e.g. /kɔnvɛnˈt͡si̯oːn/ not #/kɔnvenˈt͡si̯oːn/ (in other
			-- consonant-initial suffixes, the vowel does lengthen and become close, as in [[möglich]] /ˈmøːklɪç/).
			local join_directly = rfind(part, "^" .. V)  or rfind(part, AUTOACUTE) or rfind(part, ACUTE)
			if saw_primary_prefix_stress then
				-- Primary-stressed suffix gets demoted to secondary stress if there is a primary-stressed prefix, e.g.
				-- [[ausprobieren]] /ˈaʊ̯spʁoˌbiːʁən/.
				part = gsub(part, AUTOACUTE, AUTOGRAVE)
			end
			if join_directly then
				wordparts[#wordparts] = wordparts[#wordparts] .. part
			else
				table.insert(wordparts, "‿" .. part)
			end
		else
			-- handling a prefix or main part
			table.insert(wordparts, (i > 1 and "⁀" or "") .. part)
		end
	end
	return table.concat(wordparts)
end

-- Secondary stress in a suffix disappears if there is a preceding secondary stress or if the immediately preceding
-- syllable has primary stress. If there are multiple such secondary stresses, I *think* we need to process them
-- left to right because of the way words are built up. E.g. FOObarkeit is really (FOO + -bar) + -keit, so if FOO is
-- one syllable, we get Fúbarkèit (-bar loses secondary stress because of the immediately preceding primary stress,
-- then -keit keeps it) but if FOO is two syllables, we get Fúdebàrkeit (-bar keeps stress so -keit loses it
-- because there is a preceding secondary stress).
local function handle_suffix_secondary_stress(word)
	if not rfind(word, ORIG_SUFFIX_GRAVE) then
		return word
	end
	local parts = strutils.capturing_split(word, "([.⁀‿]+)")
	local saw_secondary_stress = false
	local saw_primary_stress_preceding = false

	-- There should never be ORIG_SUFFIX_GRAVE in a compound word (i.e. multicomponent word where the components were
	-- originally separated by hyphen or double hyphen in respelling), so we should treat user-specified GRAVE as
	-- secondary stress rather than as primary stress in a non-primary component.
	local secondary_stress_c = "[" .. grave .. DOUBLEGRAVE .. ORIG_SUFFIX_GRAVE .. "]"
	for i, part in ipairs(parts) do
		if i % 2 == 1 then
			if saw_secondary_stress or saw_primary_stress_preceding then
				parts[i] = rsub(part, ORIG_SUFFIX_GRAVE, "")
			end
			saw_secondary_stress = saw_secondary_stress or rfind(part, secondary_stress_c)
			saw_primary_stress_preceding = rfind(part, acute_c)
		end
	end

	return table.concat(parts)
end


-- This function contains the main rules that transform an orthographic word into "phonemic" IPA. In reality we show
-- some things that are arguably allophonic, such as displaying /əʁ/ as /ɐ/ (but otherwise syllable-final /ʁ/ is still
-- shown as such); showing word-internal glottal stops; and showing /ŋ/, which in some analyses is treated as
-- underlyingly being /nɡ/.
--
-- The word on entry has already had the following applied:
-- (1) Unicode decomposition.
-- (2) Prefix and suffix splitting, with the addition of ⁀ or ‿ at boundaries of words, components, prefixes and
--     suffixes; see comment at top of split_word_on_components_and_apply_affixes().
-- (3) Addition of default primary and secondary stresses on the appropriate vowels. Autogenerated stresses use the
--     symbols AUTOACUTE, AUTOGRAVE and ORIG_SUFFIX_GRAVE, while user-specified stresses use ACUTE and GRAVE, so that
--     they can be distinguished (e.g. towards the end we remove autogenerated primary stress in monosyllabic words,
--     but leave user-specified primary stress).
-- The output of this function is maybe fed into apply_phonetic_rules() to get "phonetic", i.e. narrower, IPA. In
-- addition, the actual displayed phonemic pronunciation is obtained by removing ⁀ and ‿ symbols as well as the dot (.)
-- symbol marking syllable boundaries.
--
-- Note that if the input contains multiple words, they are split on spaces and passed separately to this function,
-- and then put back together at the end.
local function apply_phonemic_rules(word)

	-- Utility function for displaying the partially formatted word using error().
	local function dbg(word)
		-- Don't display line number of dbg() call itself, but of caller.
		error(reveal_unicode(word), 2)
	end

	------------------------- Misc early conversions -------------------------

	word = rsub(word, "ǝ", "ə") -- "Wrong" schwa (U+01DD) to correct schwa (U+0259)
	word = rsub(word, MACRON, "ː") -- The user can use respelling with macrons but internally we convert to the long mark ː
	word = rsub(word, "x", "ks")
	-- 'sch' and related graphemes; must precede handling of 'ts'
	word = rsub(word, "tsch", "ʧʧ")
	word = rsub(word, "dsch", "ʤʤ")
	word = rsub(word, "sch", "ʃʃ")
	-- We treat written 'ts' same as 'tz', e.g. [[aufwärts]], [[Aufenhaltsgenehmigung]], [[Rätsel]] and
	-- foreign-derived words such as [[Botsuana]], [[Fietse]], [[Lotse]], [[Mitsubishi]], [[Hatsa]], [[Tsatsiki]],
	-- [[Whatsapp]]. To prevent this, insert a syllable boundary (.), a component boundary (-), a prefix or suffix
	-- boundary (< or >), etc.
	word = rsub(word, "t[sz]", "ʦʦ")
	word = rsub(word, "z", "ʦ")
	word = rsub(word, "qu", "kv")
	word = rsub(word, "q", "k")
	word = rsub(word, "w", "v")
	word = rsub(word, "dt", "tt")


	------------------------- Generation of /ŋ/ -------------------------

	-- [[Pinguin]], [[Linguistik]], [[konsanguin]], [[Lingua franca]], [[bilingual]]
	word = rsub(word, "ngu(" .. V .. ")", "ŋgu%1")
	-- In -ngr-, -ngl-, -ngV- with a following stress in the same component, the 'g' is usually pronounced and the 'n'
	-- is usually /ŋ/. Cf. [[Gangrän]], [[kongruent]], [[Kongruenz]], [[Kaliningrad]]/[[Leningrad]]/[[Stalingrad]],
	-- [[Kongress]], [[Mangrove]], [[Sangria]], [[Anglikaner]], [[anglikanisch]], [[Anglistik]], [[Anglizismus]],
	-- [[Bangladesch]], [[Jonglage]]/[[Jongleur]]/[[jonglieren]], [[Konglomerat]], [[Angela]], [[Angeliter]],
	-- [[Angola]], [[Angolaner]], [[evangelisch]], [[Evangelium]], [[fingieren]], [[fungieren]], [[fungibilität]],
	-- [[Gingivitis]], [[Klingonisch]], [[Kongolese]], [[Kontingenz]], [[Langobarde]], [[Languste]], [[Mangan]],
	-- [[Mongolisch]], [[rektangulär]], [[restringieren]], [[singapurisch]], [[singulär]], [[Singultus]],
	-- [[stringent]], [[tangibel]], [[tangieren]], [[triangulieren]], [[Vercingetorix]], etc. Cases without stress and
	-- with the 'g' unpronounced are [[hungrig]], [[Angler]], [[Spengler]], [[Umzinglung]], [[England]], [[Engländer]],
	-- [[Englisch]], [[Denglisch]], [[einenglischen]], etc. Some of the above optionally have /n/ instead of /ŋ/; these
	-- need respelling with 'n.gr' or 'n.gl'.
	--
	-- 'ng' followed by 'a' or 'o' also usually has pronounced 'g' and /ŋ/, e.g. [[Bungalow]], [[Ingolstadt]],
	-- [[Kongo]], [[Manga]], [[Singapur]], [[Tango]], [[Tonga]], [[Ungar]].
	--
	-- Exceptions to both rules will need respelling, e.g. [[Ingrid]] 'Inggrid', [[Ganglion]] 'Ganggli.on' (one
	-- pronunciation; unpronounced 'g' is also possible), [[Adstringens]] 'Adstrínggĕns', [[Anilingus]] 'Anilínggus',
	-- [[Ingrimm] 'Inggrimm', [[Singular]] 'Singgular' (although if spelled 'Singulàr', the first rule will take effect
	-- with the following stress).
	word = rsub_repeatedly(word, "ng([lr]?" .. V .. "[^⁀‿]*" .. stress_c .. ")", "ŋ.g%1")
	word = rsub(word, "ng([lr]?[ao])", "ŋ.g%1")
	word = rsub(word, "ng", "ŋŋ")
	-- Cf. [[Funke]], [[Gedanke]], [[Kranker]], [[Beschränkung]], [[Erkrankung]], [[Verrenkung]], [[gelenkig]],
	-- [[stinkig]], etc. with no following stress; [[trinkbar]], [[Frankreich]], etc. within a syllable; [[Bankett]],
	-- [[bankrott]], [[Concorde]], [[Delinquent]] ('qu' respelled 'kv' above, feeding this rule), [[flankieren]],
	-- [[Frankierung]], [[Konklave]], [[Konkordia]], [[konkret]], [[melancholisch]] (respelled 'melankólisch'),
	-- etc. with following stress. Words with initial 'in-' pronounced /ɪn/ e.g. [[Inkarnation]], [[Inklusion]],
	-- [[inkohärent]], [[inkompatibel]], [[inkompetent]] will need respelling with a syllable divider 'In.karnation',
	-- 'In.klusion', 'in.ko.härent', [[in.kompatibel]], [[in.kompetent]]. (Similarly [[ingeniös]], [[Ingredienz]]
	-- respelled 'in.geniös', 'In.grêdienz'.)
	word = rsub(word, "nk", "ŋk")


	------------------------- 'c' other than 'ch' -------------------------

	-- Italian-derived words: [[Catenaccio]], [[Stracciatella]]
	word = rsub(word, "cci(" .. V .. ")", "ʧʧ%1")
	-- Italian-derived words: [[Cappuccino]], [[Fibonaccizahl]]
	word = rsub(word, "cc([ei])", "ʧʧ%1")
	word = rsub(word, "ck", "kk")
	-- Mostly Romance-origin words: [[Account]], [[Alpacca]], [[Broccoli]], [[Latte macchiato]], [[Macchie]], [[Mocca]],
	-- [[Occasion]], [[Occopirmus]], [[Piccolo]], [[Rebecca]], [[staccatoartig]], [[Zucchini]], etc. This needs to
	-- go before kh -> k so that cch -> kk.
	word = rsub(word, "cc", "kk")
	word = rsub(word, "c([^h])", "ʦ%1")


	------------------------- 'y' -------------------------

	--[=[
	In general, we convert 'y' to either 'ü', 'i', 'I' or 'j'. Do this before handling diphthongs because the resulting
	'i' may be in the combination 'ai' or 'ei', which needs to be handled as a diphthong.

	1. Accented 'y' always becomes 'ü'.
	2. Initial 'y' followed by a vowel becomes 'j', as in [[New York]] respelled 'Nju Yórk' /njuː ˈjɔrk/, [[Yacht]]
	/jaxt/, [[Yak]] /jak/, [[Yang]] /jaŋ/, [[Yannick]] /ˈjanɪk/, [[Yen]] /jɛn/, [[Yersiniose]] /jɛʁziˈni̯oːzə/, [[Yeti]]
	/ˈjeːti/, [[Yobibyte]] respelled 'Yóbibàit' /ˈjoːbiˌbaɪ̯t/, [[Yoga]] /ˈjoːɡa/, [[Yoni]] /ˈjoːni/, [[Yottabyte]]
	respelled 'Yóttabàit' /ˈjɔtaˌbaɪ̯t/, [[Yuppie]] respelled 'Yuppi' /ˈjʊpi/.
	3. Initial 'y' not followed by a vowel becomes 'ü', as in [[Ylid]] /yˈliːt/, [[Yperit]] /ypəˈʁiːt/, [[Ypern]]
	/ˈyːpɐn/, [[Ypsilon]] /ˈʏpsilɔn/, [[Ytterbium]] /ʏˈtɛʁbi̯ʊm/, [[Yttererde]] /ˈʏtɐˌʔeːɐ̯də/, [[Yttrium]] /ˈʏtʁiʊm/.
	Some words of this form need respelling: [[Ybbsitz]] respelled 'Ibbsitz', [[Ysop]] respelled 'Isop', [[Yspertal]]
	respelled 'Isper-tal', [[Yvonne]] respelled 'Ivónn'.
	4. Final 'y' after a consonant becomes 'i', as in [[Hobby]] /ˈhɔbi/, [[Body]] respelled 'Boddy' /ˈbɔdi/,
    [[Stransky]] /ˈʃtʀanski/, [[Monopoly]] /moˈnoːpoli/, [[Whisky]] /ˈwɪski/, [[Sony]] /ˈzoːni/, etc.
	5. Other 'y' after a consonant becomes 'ü', as in [[symmetrisch]] /zʏˈmeːtʁɪʃ/, [[Pyramide]] /ˌpyʁaˈmiːdə/,
	[[Psychologie]] /psyçoloˈɡiː/, [[Acryl]] /aˈkʁyːl/, [[Aerodynamik]] /aeʁodyˈnaːmɪk/, [[Ägypten]] /ˌɛˈɡʏptn̩/,
	[[analytisch]] /anaˈlyːtɪʃ/, [[Beryllium]] /beˈʁʏli̯ʊm/, etc. Also between a consonant and a vowel, e.g. [[Cyan]]
	/t͡syˈaːn/, [[Kryometer]] /kʁyoˈmeːtɐ/, [[Dryade]] /dʁyˈaːdə/, [[Eukaryot]] /ɔɪ̯kaʁyˈoːt/, [[euryök]] /ɔɪ̯ʁyˈʔøːk/,
	[[Harpyie]] /haʁˈpyːjə/, [[Amblyopie]] /amblyoˈpiː/, [[Myon]] /ˈmyːɔn/, [[Karyatide]] /kaʁyaˈtiːdə/. Some words of
	the latter form need respelling, e.g. [[Myanmar]] respelled 'Miánmahr' /ˈmi̯anmaːɐ̯/, [[Libyen]] respelled 'Libien'
	/ˈliːbi̯ən/, [[Magyar]] respelled 'Madjáhr' /maˈdjaːɐ̯/, [[Polyamorie]] respelled 'Poly-amoríe' /ˌpoːliʔamoˈʁiː/,
	[[Polyester]] respelled 'Poliéster' /poˈli̯ɛstɐ/, [[Prokaryot]] respelled 'Prokary̯ót' /pʁokaˈʁy̯oːt/, [[Rallye]]
	respelled 'Rally' /ˈʁali/ or 'Relly' /ˈʁɛli/, [[Canyon]] respelled 'Kenjen' /ˈkɛnjən/, [[Babyöl]] respelled
	'Beby-öl' /ˈbeːbiˌʔøːl/, [[Ichthyologie]] respelled 'Ichthy̯ologie' /ɪçty̯oloˈɡiː/, etc. More rarely, some words of
	the former form also need respelling, e.g. [[Calypso]] respelled 'Kalípso' /kaˈlɪpso/.
	6. In the sequences 'ay', 'oy' not followed by a vowel, or followed by e/i/u and no stress follows, the 'y'
	becomes 'I', e.g. [[Bayern]] /ˈbaɪ̯ɐn/, [[Hoyerswerda]] respelled 'Hoyers-*verda' /hɔɪ̯ɐsˈvɛʁda/, [[Mayer]] /ˈmaɪ̯ɐ/,
	[[Paraguay]] /ˈpaːʁaɡvaɪ̯/ or /ˈpaʁaɡvaɪ̯/ or /paʁaˈɡu̯aɪ̯/, [[Uraguayer]] /ˈuːʁuɡvaɪ̯ɐ/ or /ˈʊʁuɡvaɪ̯ɐ/ or /ˌuʁuˈɡu̯aɪ̯ɐ/,
	[[Payerbach]] respelled 'Payer-bach', [[Bayreuth]] /baɪ̯ˈʁɔʏ̯t/, [[bayrisch]] /ˈbaɪ̯ʁɪʃ/, [[Boykott]] /ˌbɔɪ̯ˈkɔt/,
	[[Malaysia]] /maˈlaɪ̯zi̯a/, [[Maybach]] /ˈmaɪbax/.
	7. In the sequence 'ey' in the same circumstances as the previous entry, the 'y' becomes 'i', e.g. [[Meyer]]
	/ˈmaɪ̯ɐ/, [[Leyermann]] respelled 'Leyer-mann' /ˈlaɪ̯ɐˌman/, [[Speyer]] /ˈʃpaɪ̯ɐ/, [[Leyen]] /ˈlaɪ̯ən/, obsolete
	spellings like [[beyde]] for [[beide]] or [[dabey]] for [[dabei]] or [[meyn]] for [[mein]], [[Geysir]] /ɡaɪ̯ˈziːʁ/.
	8. Other 'y' after vowels becomes 'j', e.g. [[Alija]] /aˈlija/, [[Ayatollah]] /ˌajaˈtɔla/, [[Ayurveda]]
	/ajʊʁˈveːda/, [[Cayenne]] respelled 'Kayén' /kaˈjɛn/, [[Chaya]] respelled 'Tschaya' /ˈt͡ʃaːja/, [[Cherimoya]]
	respelled 'Tscherimoya' /t͡ʃeʁiˈmoːja/, [[flamboyant]] respelled 'flãbOayant' /flɑ̃bo̯aˈjant/, [[Guyana]] /ɡuˈjaːna/,
	[[Französisch-Guayana]] /[fʁanˌt͡søːzɪʃ ɡuaˈjaːna/, [[Himalaya]] /hiˈmaːlaja/ or /himaˈlaːja/, [[Larmoyanz]]
	respelled 'LarmOayanz' /laʁmo̯aˈjant͡s/, [[loyal]] /loˈjaːl/, [[Malayalam]] /malaˈjaːlam/ or /malajaˈlaːm/, [[Maya]]
	/ˈmaːja/, [[Mayo]] /ˈmaːjo/, [[oktroyieren]] respelled 'oktrOayieren' /ɔktʁo̯aˈjiːʁən/, [[Oriya]] /oˈʁiːja/,
	[[Papaya]] /paˈpaːja/, [[Toyota]] /toˈjoːta/.
	]=]
	word = rsub(word, "y(" .. accent_c .. "*" .. stress_c .. ")", "ü%1") -- #1 above
	word = rsub(word, "([⁀‿])y(" .. V .. ")", "%1j%2") -- #2 above
	word = rsub(word, "([⁀‿])y", "%1ü") -- #3 above
	word = rsub(word, "(" .. C .. "%.?)y([⁀‿])", "%1i%2") -- #4 above
	word = rsub(word, "(" .. C .. "%.?)y", "%1ü") -- #5 above
	word = rsub(word, "([ao]" .. accent_c .. "*" .. ")y(" .. non_V .. ")", "%1I%2") -- #6 above
	word = rsub(word, "([ao]" .. accent_c .. "*" .. ")y([eiu" .. schwalike .. "]" .. non_stress_c .. "*[⁀‿])", "%1I%2") -- #6 above
	word = rsub(word, "(e" .. accent_c .. "*" .. ")y(" .. non_V .. ")", "%1i%2") -- #7 above
	word = rsub(word, "(e" .. accent_c .. "*" .. ")y([eiu" .. schwalike .. "]" .. non_stress_c .. "*[⁀‿])", "%1i%2") -- #7 above
	word = rsub(word, "y", "j") -- #8 above


	------------------------- Diphthongs -------------------------

	-- 'äu', 'eu' -> /ɔɪ̯/. /ɪ̯/ is two characters so we use I to represent it and convert later.
	word = rsub_repeatedly(word, "[äe](" .. accent_c .. "*" .. ")u(" .. non_accent_c .. ")", "ɔ%1I%2")
	-- 'au' -> /aʊ̯/. /ʊ̯/ is two characters so we use U to represent it and convert later.
	word = rsub_repeatedly(word, "a(" .. accent_c .. "*" .. ")u(" .. non_accent_c .. ")", "a%1U%2")
	-- 'ai', 'ei' -> /aɪ̯/.
	word = rsub_repeatedly(word, "[ae](" .. accent_c .. "*" .. ")i(" .. non_accent_c .. ")", "a%1I%2")
	-- 'ie' -> /iː/. But be careful not to trigger on nonsyllabic 'i̯', as in [[Familie]].
	word = rsub_repeatedly(word, "i(" .. accent_non_invbrevebelow_c .. "*" .. ")e(" .. non_accent_c .. ")", "iː%1%2")
	-- Doubled vowels as in [[Haar]], [[Boot]], [[Schnee]], [[dööfer]], etc. become long. This should follow -ie-
	-- handling to get the right output for 'knieen' (respelling or old spelling of [[knien]]).
	word = rsub_repeatedly(word, "([aeoäöü])(" .. accent_c .. "*" .. ")%1(" .. non_accent_c .. ")", "%1ː%2%3")


	------------------------- Consonant clusters with 'h' -------------------------

	-- Not ff. Compare [[Graph]] with long /a/, [[Apostrophe]] with long second /o/.
	word = rsub(word, "ph", "f")
	-- dh: [[Buddha]], [[Abu Dhabi]], [[Sindhi]]; [[Adhäsion]], [[adhäsiv]] are exceptions, can be written ''ad.häsív''
	--     etc.
	-- th: [[Methode]], [[Abendroth]], [[Absinth]], [[Theater]], [[Agathe]] (note long /a/ here), [[Akolyth]] (note long
	--      /y/ here), [[Algorithmus]], [[katholisch]], etc.
	-- kh: [[Dzongkha]], [[khaki]]. Fed by 'cch' above.
	-- gh: [[Afghane]], [[Afghanistan]], [[Balogh]], [[Edinburgh]], [[Ghana]], [[Ghetto]], [[Ghostwriter]], [[Joghurt]],
	--     [[maghrebinisch]], [[Sorghum]], [[Spaghetti]].
	-- bh: [[Bhutan]].
	-- rh: [[Arrhythmie]], [[Rhythmus]], [[Rhodos]], [[Rhabarber]], [[Rhapsodie]], [[Rheda]], [[Rhein]], [[Rhenium]],
	--     [[Rhetorik]], [[Rheuma]], [[rhexigen]], [[Rhone]], etc.
	-- wh: [[Whatsapp]], [[Whirlpool]], [[Whisky]], [[Whist]], [[Whistleblower]], [[Whiteboard]], [[Whiteout]], etc.
	word = rsub(word, "([dtkgbrw])h", "%1")
	-- Handling of 'ch'. Must follow diphthong handling so 'äu', 'eu' trigger ich-laut.
	word = rsub(word, "chs", "ks")
	-- When implementing ach-laut, make sure to account for 'h' in respelling (which hasn't yet been converted to the
	-- length marker 'ː').
	word = rsub(word, "([aɔoʊuU][" .. accent .. "h]*)ch", "%1xx")
	word = rsub(word, "ch", "çç")


	------------------------- Remaining 'h' -------------------------

	--[=[
	'h' between vowels should be lengthening only if no stress follows and the following vowel isn't a or o, and if
	followed by i or u, that vowel should not be word-final (cf. [[Estomihi]], [[Uhu]], [[Bahuvrihi]] with pronounced
	'h' before word-final 'i' or 'u').

	Cf. [[Reha]] /ˈʁeːha/, [[Dschihadist]] /d͡ʒihaːˈdɪst/, [[Johann]] /ˈjoːhan/, [[Lahar]] /ˈlaːhaʁ/, [[Mahagoni]]
	/ˌmahaˈɡoːni/, [[Maharadscha]] /ˌmahaˈʁaːdʒa/ (prescriptive) or /ˌmahaˈʁadʒa/ (more common) or /ˌmahaˈʁatʃa/
	(usual), [[Mohammed]] /ˈmoː.(h)a.mɛt/, [[Rehabilitation]] /ˌʁehabilitaˈt͡si̯oːn/, [[stenohalin]] /ʃtenohaˈliːn/,
	[[Tomahawk]] /ˈtɔ.ma.haːk/ or /ˈtɔ.ma.hoːk/, [[Bethlehem]] /ˈbeːt.ləˌhɛm/ or /ˈbeːt.ləˌheːm/ (sometimes without
	secondary stress), [[Bohemien]] /bo.(h)eˈmjɛ̃/, [[Bohemistik]] /boheˈmɪstɪk/, [[Ahorn]] /ˈʔaːhɔʁn/, [[Alkoholismus]]
	/ˌalkohoˈlɪsmʊs/, [[Jehova]] /jeˈhoːva/, [[Kohorte]] /koˈhɔʁtə/, [[Nihonium]] /niˈhoːni̯ʊm/, [[Bahuvrihi]]
	/bahuˈvʁiːhi/, [[Marihuana]] 'Marihu.ána' /maʁihuˈaːna/ (one pronunciation per dewikt), [[abstrahieren]]
	/apstʁaˈhiːʁən/, [[ahistorisch]] /ˈahɪsˌtoːʁɪʃ/, [[Annihilation]] /anihilaˈt͡si̯oːn/, [[Antihistaminikum]]
	/antihɪstaˈmiːnikʊm/ [[Mohammedaner]] /mohameˈdaːnɐ/, [[nihilistisch]] /nihiˈlɪstɪʃ/, [[Prohibition]]
	/pʁohibiˈt͡si̯oːn/, [[Vehikel]] /veˈhiːkəl/, [[huhu]] /ˈhuːhu/, [[Uhu]] /ˈuːhu/, [[Estomihi]] /ɛstoˈmiːhi/,
	[[Tohuwabohu]] /ˌtoːhuvaˈboːhu/.

	Cf. (not pronounced) [[Abziehung]] /ˈapt͡siːʊŋ/, [[Aufblähung]] /ˈaʊ̯fˌblɛːʊŋ/, [[Auferstehung]] /ˈaʊ̯f(ʔ)ɛʁˈʃteːʊŋ/,
	[[Bedrohung]] /bəˈdʁoːʊŋ/, [[arbeitsfähig]] /ˈaʁbaɪ̯t͡sˌfɛːɪç/, [[befähigt]] /bəˈfɛːɪçt/, [[Beruhigen]] /bəˈʁuːɪɡən/,
	[[Ehe]], /ˈeːə/, [[viehisch]] /ˈfiːɪʃ/.

	Exception needing respelling with '.' before the 'h': [[Uhudler]] 'U.huhdler' /ˈuːhuːdlɐ/.

	We temporarily convert 'h' that should be preserved to 'H', then remove remaining 'h' after vowel, then convert
	'H' back to 'h'.
	]=]
	word = rsub_repeatedly(word, "h(" .. V .. "[^⁀‿]*" .. stress_c .. ")", "H%1")
	word = rsub(word, "h([ao])", "H%1")
	word = rsub(word, "h([iu][⁀‿])", "H%1")
	-- Remaining 'h' after a vowel (not including a glide like I or U from dipthongs) indicates vowel length. Make sure
	-- to put the ː before stress marks.
	word = rsub(word, "(" .. V_non_glide .. accent_non_invbrevebelow_c .. "-)(" .. stress_c .. "*" .. ")h", "%1ː%2")
	-- If we ended up with two ː signs (e.g. from superfluous lengthening 'h' as in [[Vieh]], [[ziehen]]), remove one
	-- of them.
	word = rsub(word, "ːː", "ː")
	-- Remaining 'h' after a vowel is superfluous, e.g. [[rauh]], [[leihen]], [[Geweih]].
	word = rsub(word, "(" .. V .. accent_c .. "*" .. ")h", "%1")
	-- Convert special 'H' symbol (to indicate pronounced /h/ between vowels) back to /h/.
	word = rsub(word, "H", "h")


	------------------------- French and English sounds -------------------------

	word = rsub(word, "([eo])(" .. accent_c .. "*[IU])", function(eo, iu)
		-- 'eI' as in 'SpreI' for [[Spray]]; 'eU' not in French or English but kept for parallelism
		-- 'oI' as in 'KauboI' for [[Cowboy]]; 'oU' as in 'HoUmpehdsch' for [[Homepage]]
		local lower_eo = {["e"] = "ɛ", ["o"] = "ɔ"}
		return lower_eo[eo] .. iu
	end)
	word = rsub(word, "e" .. TILDE, "ɛ" .. TILDE)
	word = rsub(word, "ö" .. TILDE, "œ" .. TILDE)


	------------------------- 's' -------------------------

	word = rsub(word, "([⁀‿])s(" .. V .. ")", "%1z%2")
	word = rsub(word, "([" .. vowel .. "lrmnŋj]" .. accent_c .. "*%.?)s(" .. V .. ")", "%1z%2")
	-- /bs/ -> [pz] before the stress as in [[absentieren]], [[Absinth]], [[absolut]], [[absorbieren]], [[absurd]],
	-- [[observieren]], [[obsessiv]], [[Obsidian]], [[Obsoleszenz]], [[subsumtiv]], but -> [ps] after the stress,
	-- as in [[Erbse]], [[Kebse]], [[obsen]], [[schubsen]]. Similarly for /ds/ -> [tz] before the stress as in
	-- [[adsorbieren]] but -> [ts] after the stress as in [[Landser]]. Note, we do not count cases like [[betriebsam]],
	-- [[beredsam]] with [pz], [tz] after the stress; -sam is treated as a separate word. In [[Trübsal]], -sal is a
	-- suffix and should be treated as if a separate word; hence, lengthened ü. [[Überbleibsel]] is given with [ps]
	-- in dewikt and Pons, consistent with the rule, but with [bz] in enwikt, which may be wrong. [[Absence]] is
	-- given with word-final stress and [ps] in dewikt, contrary to the rule, but this is an unadapted French word
	-- with a nasal vowel in it.
	--
	-- For /gs/, [[bugsieren]] is an exception with [ks]. Cf. also [[pumperlgsund]] with [ks]. All other examples with
	-- /gs/ in enwikt have a component boundary in the middle.
	--
	-- No apparent examples involving /vs/, /zs/, /(d)ʒs/ that don't involve clear morpheme boundaries.
	word = rsub(word, "([bd])s(" .. V .. "[^⁀‿]*" .. stress_c .. ")", "%1z%2")
	word = rsub(word, "⁀s([pt])", "⁀ʃ%1")

	------------------------- Reduce extraneous geminate consonants -------------------------

	-- Reduce extraneous geminate consonants (some generated above when handling digraphs etc.). Geminate consonants
	-- only have an effect directly after a vowel, and not when before a consonant other than l or r.
	-- FIXME: Probably not necessary since we remove geminates down below after vowel lengthening, and causes problems.
	-- Once we're sure these aren't necessary, remove them.
	-- word = rsub(word, "(" .. non_V .. ")(" .. C .. ")%2", "%1%2")
	-- word = rsub(word, "(" .. C .. ")%1(" .. C_not_lr .. ")", "%1%2")


	------------------------- 'i' and 'u' in hiatus -------------------------

	-- 'i' and 'u' in hiatus should be nonsyllabic by default; add '.' afterwards to prevent this.
	word = rsub(word, "(" .. C .. "[iu])(" .. V .. ")", "%1" .. INVBREVEBELOW .. "%2")


	------------------------- Divide into syllables -------------------------

	-- Existing potentially-relevant hyphenations/pronunciations: [[abenteuerdurstig]] -> aben|teu|er|durs|tig,
	-- [[Agraffe]] -> /aˈɡʁafə/ (but Ag|raf|fe); [[Agrarbiologie]] -> /aˈɡʁaːʁbioloˌɡiː/ (but Ag|rar|bio|lo|gie);
	-- [[Anagramm]] -> (per dewikt) [anaˈɡʁam] Ana·gramm; [[Abraham]] -> /ˈaːbʁaˌha(ː)m/; [[Fabrik]] -> (per dewikt)
	-- [faˈbʁiːk] Fa·b·rik; [[administrativ]] -> /atminɪstʁaˈtiːf/; [[adjazent]] -> (per dewikt) [ˌatjaˈt͡sɛnt]
	-- ad·ja·zent; [[Adjektiv]] -> /ˈa.djɛkˌtiːf/ or /ˈat.jɛk-/, but only [ˈatjɛktiːf] per dewikt; [[Adlatus]] ->
	-- /ˌatˈlaːtʊs/ or /ˌaˈdlaːtʊs/ (same in dewikt); [[Adler]] -> /ˈaːdlɐ/; [[adrett]] -> /aˈdʁɛt/; [[Adstrat]] ->
	-- [atˈstʁaːt]; [[asthenisch]] -> /asˈteːnɪʃ/; [[Asthenosphäre]] -> /astenoˈsfɛːʁə/; [[Asthma]] -> [ˈast.ma];
	-- [[Astronaut]] -> /ˌas.tʁoˈnaʊ̯t/; [[asturisch]] -> /asˈtuːʁɪʃ/; [[synchron]] -> /zʏnˈkʁoːn/; [[Syndrom]] ->
	-- [zʏnˈdʁoːm]; [[System]] -> /zɪsˈteːm/ or /zʏsˈteːm/.
	-- Change user-specified . into SYLDIV so we don't shuffle it around when dividing into syllables.
	word = rsub(word, "%.", SYLDIV)
	-- Divide before the last consonant. We then move the syllable division marker leftwards over clusters that can
	-- form onsets.
	word = rsub_repeatedly(word, "(" .. V .. accent_c .. "*" .. C .. "-)(" .. C .. V .. ")", "%1.%2")
	-- Cases like [[Agrobiologie]] /ˈaːɡʁobioloˌɡiː/ show that Cl or Cr where C is a non-sibilant obstruent should be
	-- kept together. It's unclear with 'dl', cf. [[Adlatus]] /ˌatˈlaːtʊs/ or /ˌaˈdlaːtʊs/; but the numerous words
	-- like [[Adler]] /ˈaːdlɐ/ (reduced from ''*Adeler'') suggest we should keep 'dl' together. For 'tl', we have
	-- on the one hand [[Atlas]] /ˈatlas/ and [[Detlef]] [ˈdɛtlɛf] (dewikt) but on the other hand [[Bethlehem]]
	-- /ˈbeːt.ləˌhɛm/. For simplicity we treat 'dl' and 'tl' the same.
	word = rsub(word, "(" .. obstruent_non_sibilant_c .. ")%.([lr])", ".%1%2")
	-- Cf. [[Liquid]] [liˈkviːt]; [[Liquida]] [ˈliːkvida]; [[Mikwe]] /miˈkveː/; [[Taekwondo]] [tɛˈkvɔndo] (dewikt);
	-- [[Uruguayerin]] [ˈuːʁuɡvaɪ̯əʁɪn] (dewikt).
	word = rsub(word, "([kg])%.v", ".%1v")
	-- We need special handling of /ks/ so it stays together on the same side of the syllable divider but triggers
	-- vowel shortening; cf. [[Oxid]] /ɔˈksiːt/, [[Reflexion]] /ʁeflɛˈksi̯oːn/. The extra /k/ will be removed below
	-- when we remove remaining geminates within a component.
	word = rsub(word, "k%.s", "k.ks")
	-- [[Signal]] [zɪˈɡnaːl] (dewikt); [[designieren]] [dezɪˈɡniːʁən] (dewikt); if split 'g.n', we'd expect [k.n].
	-- But notice the short 'i' (which we handle by a rule below). Cf. [[Kognition]] [ˌkɔɡniˈt͡si̯oːn] (dewikt) and
	-- [[Kognat]] [kɔˈɡnaːt] (dewikt) vs. [[Prognose]] [ˌpʁoˈɡnoːzə] (dewikt) with short closed 'o' (secondary stress
	-- doesn't lengthen vowel before primary stress). Cf. also [[orthognath]] [ɔʁtoˈɡnaːt] (dewikt), [[prognath]]
	-- [pʁoˈɡnaːt] (dewikt). Cf. [[Agnes]] [ˈaɡnɛs] (dewikt) but /ˈaː.ɡnəs/ (enwikt). Cf. [[regnen]] /ˈʁeː.ɡnən/
	-- "prescriptive standard" (enwikt), /ˈʁeːk.nən/ "most common" (enwikt). Similarly [[Gegner]], [[segnen]],
	-- [[Regnum]]. Also [[leugnen]], [[Leugner]] with the same /gn/ prescriptive, /kn/ more common; whereas [[Zeugnis]]
	-- always with /kn/ (because -nis is a suffix).
	word = rsub(word, "g%.n", ".gn")
	-- Divide two vowels. But don't divide if the first vowel is indicated as non-syllabic ([[Familie]], [[Ichthyologie]],
	-- etc.), or we will wrongly get e.g. 'Fa.mi.li.e' instead of 'Fa.mi.lie'. Also don't divide if the second vowel is a
	-- glide (I or U), or we will wrongly get e.g. 'me.in' instead of 'mein' for [[mein]]. Do divide if the first vowel is
	-- a glide, in words like [[Bayern]], which should be divided 'Bay.ern'.
	word = rsub_repeatedly(word, "(" .. V .. accent_non_invbrevebelow_c .. "*)(" .. V_non_glide .. ")", "%1.%2")
	-- User-specified syllable divider should now be treated like regular one.
	word = rsub(word, SYLDIV, ".")


	------------------------- Convert some unstressed 'e' to schwa -------------------------

	-- It seems the following holds (excluding [[be-]] and [[ge-]] from -- consideration):
	-- 1. 'e' is less likely to be schwa before the stress than after.
	-- 2. Before the stress, 'e' in a closed syllable is never a schwa.
	-- 2. Initial unstressed 'e' as in [[Elektrizität]] is never a schwa.
	-- 3. Before the stress, 'e' in the first syllable is not normally a schwa, cf. [[Negativität]], [[Benefaktiv]].
	-- 4. Before the stress, 'e' in hiatus is not a schwa, cf. [[Idealisierung]].
	-- 5. In open non-initial syllables before the stress, it *MAY* be a schwa, esp. before 'r', e.g.
	--    [[Temperatur]] with /ə/; [[Generalität]] with /ə/; [[Souveränität]] with /ə/; [[Heterogenität]] with /ə/ before 'r' but /e/ later on;
	--    same for [[Kanzerogenität]]; but [[Immaterialität]] with /e/; [[Benediktiner]] optionally with /ə/ in second
	--    syllable; [[Pietät]] with /ə/; [[Sozietät]] with /ə/ but [[Varietät]] with /e/, [[abalienieren]] with /e/;
	--    [[Extremität]] with /e/; [[Illegalität]] with /e/; [[Integrität]] with /e/; [[Abbreviation]] with /e/;
	--    [[acetylieren]] with /e/; [[akkreditieren]] with /e/; [[ameliorieren]] with /e/; [[anästhesieren]] with /e/;
	--    [[degenerieren]] with /e/ /e/ /ə/; etc.
	-- 6. After the stress, 'e' is more likely to be schwa, e.g. [[zumindestens]] /t͡suˈmɪndəstəns/. But not always,
	--    e.g. [[Latex]] [ˈlaːtɛks] (dewikt); [[Index]] /ɪndɛks/; [[Alex]] /ˈalɛks/; [[Achilles]] [aˈxɪlɛs] (dewikt);
	--    [[Adjektiv]] /ˈa.djɛkˌtiːf/ or /ˈat.jɛk-/; [[Adstringens]] [atˈstrɪŋɡɛns]; [[Adverb]] /ˈat.vɛʁp/
	--    (or /atˈvɛʁp/); [[Agens]] /ˈaːɡɛns/; [[Ahmed]] /ˈaxmɛt/; [[Bizeps]] /ˈbiːt͡sɛps/; [[Borretsch]] /ˈbɔʁɛt͡ʃ/;
	--    [[Bregenz]] /ˈbʁeːɡɛnt͡s/; [[Clemens]] [ˈkleːmɛns]; [[Comeback]] /ˈkambɛk/; [[Daniel]] /ˈdaːni̯ɛl/;
	--    [[Dezibel]] /ˈdeːt͡sibɛl/; [[Diabetes]] /diaˈbeːtəs/ or /-tɛs/; [[Dolmetscher]] /ˈdɔlmɛtʃər/;
	--    [[Dubstep]] /ˈdapstɛp/; etc.
	-- 7. Given this analysis, we do the following:
	--    a. If before the stress, 'e' -> schwa only in an internal open syllable preceding 'r'.
	--    b. If after the stress, 'e' -> schwa only before certain clusters: [lmrn]s? or [lr]ns? or rlns? or s?t? or
	--       nds?.
	--
	-- Implement (7a) above.

	word = rsub_repeatedly(word, "(" .. V .. "[^⁀‿]*)e(%.r[^⁀‿]*" .. stress_c .. ")", "%1ə%2")
	-- Implement (7b) above.
	-- First, make sure we don't convert any 'e' to schwa that is followed by an accent or length mark.
	word = rsub(word, "e(" .. accent_c .. ")", "E%1")
	-- Now convert 'e' to schwa when followed by the right clusters. Exclude 'e' from the capture directly following
	-- the 'e' that will be converted, so we work right-to-left and handle cases like [[Indexen]].
	word = rsub_repeatedly(word, "e([^⁀" .. stress .. "e]*⁀)", function(rest)
		local rest_no_syldiv = gsub(rest, "%.", "")
		local cl = rmatch(rest_no_syldiv, "^(" .. C .. "*)")
		if rfind(cl, "^[lmrn]s?$") or rfind(cl, "^[lr]ns?$") or rfind(cl, "^rlns?$") or rfind(cl, "^s?t?$") or
			rfind(cl, "^nds?$") then
			return "ə" .. rest
		else
			return "e" .. rest
		end
	end)
	-- Now put back the 'e' that we protected from being converted.
	word = rsub(word, "E", "e")


	------------------------- Mark some vowels as short -------------------------

	-- Handle vowel quality/length changes in open vs. closed syllables, part a: Some vowels that would be
	-- expected to be long (particularly before a single consonant word-finally) are actually short.
	-- Unstressed final 'i' before a single consonant is short: especially in -in, -is, -ig, but also -ik as in
	-- [[Organik]], [[Linguistik]], etc.; -im as in [[Interim]], [[Isegrim]], [[Joachim]], [[Muslim]] (one
	-- pronunciation), [[privatim]], [[Achim]] (one pronunciation), etc. Those in -il are usually end-stressed
	-- with long 'i', e.g. [[Automobil]], [[fragil]], [[Fossil]], [[grazil]], [[hellenophil]], [[stabil]], [[imbezil]],
	-- [[mobil]], [[fertil]], etc. Those in -it are usually end-stressed and refer to minerals, where the 'i' can be
	-- long or short. Those in -id are usually end-stressed and refer to chemicals, with long 'i'; but cf. [[David]]
	-- /ˈdaːvɪt/; [[Ingrid]] [ˈɪŋɡʁɪt] or [ˈɪŋɡʁiːt] (dewikt).
	word = rsub(word, "i(" .. C .. "[⁀‿])", "i" .. BREVE .. "%1")
	-- 'i' before 'g' is short including across syllable boundaries without a following stress ([[Entschuldigung]],
	-- [[verständigen]], [[Königin]], [[ängstigend]]; [[ewiglich]] with voiced [g]).
	word = rsub_repeatedly(word, "i(%.?g[^⁀" .. stress .. "]*⁀)", "i" .. BREVE .. "%1")
	-- 'i' before 'gn' is short including across syllable boundaries, even with a following stress ([[Signal]],
	-- [[designieren]], [[indigniert]], [[Lignin]] with voiced [g]). Not commonly before gl + stress, e.g.
	-- [[Diglossie]], [[Triglyph]], [[Epiglottis]] or gr + stress, e.g. [[Digraph]], [[Emigrant]], [[Epigramm]],
	-- [[filigran]], [[Kalligraphie]], [[Migräne]], [[Milligramm]]. [[ewiglich]], [[königlich]] etc. with short 'i'
	-- handled by previous entry.
	word = rsub(word, "i(%.?gn)", "i" .. BREVE .. "%1")
	-- Unstressed final '-us', '-um' normally short, e.g. [[Kaktus]], [[Museum]].
	word = rsub(word, "u([ms][⁀‿])", "u" .. BREVE .. "%1")
	-- Unstressed final '-on' normally short, e.g. [[Aaron]], [[Abaton]], [[Natron]], [[Analogon]], [[Myon]], [[Anton]]
	-- (either long or short 'o'), [[Argon]], [[Axon]], [[Bariton]], [[Biathlon]], [[Bison]], etc. Same with unstressed
	-- '-os', e.g. [[Albatros]], [[Amos]], [[Amphiprostylos]], [[Barbados]], [[Chaos]], [[Epos]], [[Gyros]], [[Heros]],
	-- [[Kokos]], [[Kolchos]], [[Kosmos]], etc.
	word = rsub(word, "o([ns][⁀‿])", "o" .. BREVE .. "%1")


	------------------------- Handle vowel quality/length changes  -------------------------

	-- Handle vowel quality/length changes in open vs. closed syllables, part b: Lengthen/shorten as appropriate.
	--
	-- Vowel with secondary stress in open syllable before primary stress later in the same component takes close
	-- quality without lengthening.
	word = rsub_repeatedly(word, "(" .. V_unmarked_for_quality .. ")([" .. grave .. DOUBLEGRAVE .. "][.‿][^⁀]*" .. acute_c .. ")", "%1" .. CFLEX .. "%2")
	-- Any nasal vowel with secondary stress before primary stress later in the same component does not lengthen.
	-- Cf. [[Rendezvous]]. We signal that by inserting a circumflex before the tilde, which normally comes directly
	-- after the vowel.
	word = rsub_repeatedly(word, "(" .. V .. ")" .. TILDE .. "([" .. grave .. DOUBLEGRAVE .. "][^⁀]*" .. acute_c .. ")", "%1" .. CFLEX .. TILDE .. "%2")
	-- Vowel with tertiary stress in open syllable before secondary stress later in the same component takes close
	-- quality without lengthening if component has no primary stress.
	word = rsub_repeatedly(word, "(⁀[^⁀" .. acute .. "]*" .. V_unmarked_for_quality .. ")(" .. DOUBLEGRAVE .. "[.‿][^⁀" .. acute .. "]*" .. grave_c .. "[^⁀" .. acute .. "]*⁀)",
		"%1" .. CFLEX .. "%2")
	-- Any nasal vowel with tertiary stress before secondary stress later in the same component takes does not lengthen
	-- if component has no primary stress. See above change for [[Rendezvous]].
	word = rsub_repeatedly(word, "(⁀[^⁀" .. acute .. "]*" .. V .. ")" .. TILDE .. "(" .. DOUBLEGRAVE .. "[^⁀" .. acute .. "]*" .. grave_c .. "[^⁀" .. acute .. "]*⁀)",
		"%1" .. CFLEX .. TILDE .. "%2")
	-- Remaining stressed vowel in open syllable lengthens.
	word = rsub(word, "(" .. V_unmarked_for_quality .. ")(" .. stress_c .. "[.⁀‿])", "%1ː%2")
	-- Same when followed by a single consonant word-finally or before a suffix.
	word = rsub(word, "(" .. V_unmarked_for_quality .. ")(" .. stress_c .. C .. "[⁀‿])", "%1ː%2")
	-- Remaining stressed nasal vowel lengthens.
	word = rsub(word, "(" .. V .. TILDE .. ")(" .. stress_c .. ")", "%1ː%2")
	-- Now remove CFLEX before TILDE, which was inserted to prevent lengthening.
	word = rsub(word, CFLEX .. TILDE, TILDE)
	-- Unstressed vowel in open syllable takes close quality without lengthening.
	word = rsub(word, "(" .. V_unmarked_for_quality .. ")(" .. "[.⁀‿])", "%1" .. CFLEX .. "%2")
	-- Same when followed by a single consonant word-finally or before a suffix.
	word = rsub(word, "(" .. V_unmarked_for_quality .. ")(" .. C .. "[⁀‿])", "%1" .. CFLEX .. "%2")
	-- Remaining vowel followed by a consonant becomes short in quantity and open in quality.
	word = rsub(word, "(" .. V_unmarked_for_quality .. ")(" .. stress_c .. "?" .. C .. ")", "%1" .. BREVE .. "%2")
	-- Vowel explicitly marked long gets close quality.
	word = rsub(word, "(" .. V_unmarked_for_quality .. ")ː", "%1" .. CFLEX .. "ː")
	-- Now change vowel to appropriate quality.
	word = rsub(word, "(" .. V_unmarked_for_quality .. ")" .. CFLEX, {
		["a"] = "a",
		["e"] = "e",
		["i"] = "i",
		["o"] = "o",
		["u"] = "u",
		-- FIXME, should be split depending on "style"
		["ä"] = "ɛ",
		["ö"] = "ø",
		["ü"] = "y",
	})
	word = rsub(word, "(" .. V_unmarked_for_quality .. ")" .. BREVE, {
		["a"] = "a",
		["e"] = "ɛ",
		["i"] = "ɪ",
		["o"] = "ɔ",
		["u"] = "ʊ",
		["ä"] = "ɛ",
		["ö"] = "œ",
		["ü"] = "ʏ",
	})
	-- Remove * that prevents vowel quality/length changes.
	word = rsub(word, "(" .. V .. ")%*", "%1")
	-- Convert syllable-final -er to /ɐ/. Must precede adding glottal stops between vowels.
	word = rsub(word, "ər", "ɐ")


	------------------------- Eliminate remaining geminate consonants  -------------------------

	-- Eliminate remaining geminate consonants within a component (geminates can legitimately exist across a component
	-- boundary). These have served their purpose of keeping the preceding vowel short. Normally such geminates will
	-- always occur across a syllable boundary, but this may not be the case in the presence of user-specified syllable
	-- boundaries. We need to do this prior to coda devoicing to avoid a word like [[Buddha]] ending up as /ˈbʊtda/.
	local function eliminate_geminates(word)
		return rsub_repeatedly(word, "(" .. C .. ")([.‿]*)%1", "%2%1")
	end
	word = eliminate_geminates(word)


	------------------------- Devoice consonants coda-finally  -------------------------

	-- 'ĭg' is pronounced [ɪç] word-finally or before an obstruent (not before an approximant as in [[ewiglich]] or
	-- [[Königreich]] when divided as ''ewig.lich'', ''König.reich'').
	word = rsub(word, "ɪg⁀", "ɪç⁀")
	word = rsub(word, "ɪg([.‿]*" .. C_not_lr .. ")", "ɪç%1")
	-- Devoice consonants coda-finally. There may be more than one such consonant to devoice (cf. [[Magd]]), or the
	-- consonant to devoice may be surrounded by non-voiced or non-devoicing consonants (cf. [[Herbst]]).
	word = rsub_repeatedly(word, "(" .. V .. accent_c .. "*" .. C .. "*)([bdgvzʒʤ])", function(init, voiced)
		local voiced_to_voiceless = {
			["b"] = "p",
			["d"] = "t",
			["g"] = "k",
			["v"] = "f",
			["z"] = "s",
			["ʒ"] = "ʃ",
			["ʤ"] = "ʧ",
		}
		return init .. voiced_to_voiceless[voiced]
	end)
	-- Eliminate geminates again so we eliminate the 'd' in words like [[verwandte]].
	word = eliminate_geminates(word)


	------------------------- Add glottal stops  -------------------------

	-- Add glottal stop at beginning of component before a vowel. FIXME: Sometimes this should not be present, I think.
	-- We need symbols to control this.
	--
	-- If previous component ends in a vowel, glottal stop is mandatory, e.g. [[wiederentdecken]].
	word = rsub(word, "(" .. V .. accent_c .. "*⁀)(" .. V .. ")", "%1ʔ%2")
	-- Before a stressed vowel at a component boundary, glottal stop is mandatory (except at beginning of word, where
	-- it is not shown in the phonemic notation).
	word = rsub(word, "([^⁀]⁀)(" .. V .. accent_c .. "*" .. stress_c .. ")", "%1ʔ%2")
	-- Before an unstressed vowel at a component boundary (again, except at beginning of word), glottal stop is
	-- optional, e.g. [[Aufenthalt]] /ˈaʊ̯f.(ʔ)ɛntˌhalt/.
	word = rsub(word, "([^⁀]⁀)(" .. V .. ")", "%1(ʔ)%2")


	------------------------- Remove ⁀ and ‿ before non-syllabic components  -------------------------

	-- Remove ⁀ and ‿ (component/suffix boundaries) before non-syllabic components and suffixes. Examples where this
	-- can occur are final -t/-st inflectional suffixes (-t for third-person singular, second-person plural or past
	-- participle; -st for second-person singular or superlative) and -s- interfix between components, which may be
	-- respelled with hyphens around it (in such a case it should be grouped with the preceding syllable). Don't do
	-- this at the beginning of a word (which normally shouldn't happen but might in a dialectal word). This should
	-- precede 'ts' -> 'ʦ' just below.
	word = rsub_repeatedly(word, "([^⁀‿])([⁀‿])(" .. non_V .. "+[⁀‿])", "%1%3")
	-- FIXME: Consider removing ⁀ and ‿ after non-syllabic component/prefix at the beginning of a word in case of
	-- dialectal spellings like 'gsund' for [[gesund]]; but to handle this properly we need additional rules to
	-- devoice the 'g' in such circumstances.


	------------------------- Misc late symbol conversions  -------------------------

	-- -s- frequently occurs as a component by itself (really an interfix), e.g. in [[Wirtschaftswissenschaft]]
	-- respelled 'Wirtschaft-s-wissenschaft' to make it easier to identify suffixes like the -schaft in [[Wirtschaft]].
	-- Once we remove ⁀ and ‿ before non-syllabic components and suffixes, we get lots of 'ts' that should be rendered
	-- as t͡s. Handle this now. This should also apply in 'd-s-' e.g. [[Abschiedsbrief]] respelled 'Abschied-s-brief'
	-- /ˈapʃiːt͡sˌbʁiːf/, as coda 'd' gets devoiced to /t/ above.
	word = rsub(word, "t(%.?)s", "%1ʦ")

	-- Misc symbol conversions.
	word = rsub(word, ".", {
		["I"] = "ɪ̯",
		["U"] = "ʊ̯",
		["ʧ"] = "t͡ʃ",
		["ʤ"] = "d͡ʒ",
		["ʦ"] = "t͡s",
		["g"] = "ɡ", -- map to IPA ɡ
		["r"] = "ʁ",
		["ß"] = "s",
	})
	word = rsub(word, "p(%.?)f", "%1p͡f")


	------------------------- Convert ORIG_SUFFIX_GRAVE to either GRAVE or nothing -------------------------

	-- This must happen after removing ⁀ and ‿ before non-syllabic components and suffixes because it depends on being
	-- able to accurately identify syllables.
	word = handle_suffix_secondary_stress(word)


	------------------------- Generate IPA stress marks  -------------------------

	-- Remove primary stress from monosyllabic words, but only for autogenerated stress, not if the user explicitly
	-- added a stress mark.
	word = rsub(word, "^(⁀⁀[^.⁀‿]*)" .. AUTOACUTE .. "([^.⁀‿]*⁀⁀)$", "%1%2")
	word = rsub(word, acute_c, "ˈ")
	word = rsub(word, grave_c, "ˌ")
	word = rsub(word, DOUBLEGRAVE, "")
	-- Move IPA stress marks to the beginning of the syllable.
	word = rsub(word, "([.⁀‿])([^.⁀‿ˈˌ]*)([ˈˌ])", "%1%3%2")
	-- Suppress syllable mark before IPA stress indicator.
	word = rsub(word, "%.([ˈˌ])", "%1")


	------------------------- Convert explicit character notations -------------------------

	-- Convert explicit character notation to regular character.
	word = rsub(word, ".", explicit_char_to_phonemic)

	return word
end


-- This function contains the main rules that transform from phonemic IPA to phonetic IPA. This is called on the output
-- of apply_phonemic_rules().
--
-- FIXME: This needs work before being ready for release.
local function apply_phonetic_rules(word)
	-- At the beginning of a word, glottal stop is mandatory before a vowel.
	word = rsub(word, "(⁀⁀)(" .. V .. ")", "%1ʔ%2")
	-- FIXME: Evaluate whether the following rules should apply across the ‿ symbol.
	-- -ken, -gen at end of word have syllabic ŋ
	word = rsub(word, "([kɡ]ə)n⁀", "%1" .. "ŋ⁀") -- IPA ɡ
	-- schwa + resonant becomes syllabic (written over ŋ, otherwise under)
	word = rsub(word, "ə([lmn])", "%1" .. SYLLABIC)
	word = rsub(word, "əŋ", "ŋ̍")
	-- coda r /ʁ/ becomes a semivowel
	word = rsub(word, "(" .. V .. "ː?)ʁ", "%1ɐ̯")
	-- unvoiced stops and affricates become affricated word-finally and before vowel, /ʁ/ or /l/ (including syllabic
	-- /l/), but not before syllabic nasal; cf. [[zurücktreten]], with aspirated 'z', 'ck' and first 't' but not second;
	-- also not before homorganic stop across component boundary like [[Abbildung]] [ˈʔap̚.b̥ɪl.dʊŋ]
	word = rsub(word, "p([.⁀]*b)", "p" .. UNRELEASED .. "%1")
	word = rsub(word, "t([.⁀]*d)", "t" .. UNRELEASED .. "%1")
	word = rsub(word, "k([.⁀]*ɡ)", "k" .. UNRELEASED .. "%1") -- IPA ɡ
	word = rsub(word, "([ptk])(%.?[⁀" .. vowel .. "ʁl])", "%1ʰ%2")
	word = rsub(word, "(t" .. TIE .. "[sʃ])(%.?[⁀" .. vowel .. "ʁl])", "%1ʰ%2")
	-- voiced stops/fricatives become unvoiced after unvoiced sound; cf. [[Abbildung]] [ˈʔap̚.b̥ɪl.dʊŋ]
	word = rsub(word, "(" .. unvoiced_C .. "[.⁀]*[bdɡvzʒ])", "%1" .. UNVOICED) -- IPA ɡ
	-- FIXME: Other possible phonemic/phonetic differences:
	-- (1) Omit syllable boundaries in phonemic notation?
	-- (2) Maybe not show some or all glottal stops in phonemic notation? Existing phonemic examples tend to omit it.
	-- (3) Maybe show -ieren as if written -iern; but this may be colloquial.
	return word
end


local function generate_phonemic_word(word, is_cap)
	word = rsub(word, "(.)%*", char_to_explicit_char)
	-- local pos = default_pos(word, pos)
	local pos = nil
	local affix_type
	if word:find("^%-") and word:find("%-$") then
		affix_type = "interfix"
	elseif word:find("%-$") then
		affix_type = "prefix"
	elseif word:find("^%-") then
		affix_type = "suffix"
	end
	-- FIXME: Handling of prefixes/suffixes is currently broken.
	word = gsub(word, "^%-?(.-)%-?$", "%1")
	word = split_word_on_components_and_apply_affixes(word, pos, affix_type)
	word = "⁀⁀" .. word .. "⁀⁀"
	word = apply_phonemic_rules(word)
	return word
end

local function do_phonemic_phonetic(text, is_phonetic)
	if type(text) == "table" then
		text = text[1]
	end
	local result = {}
	local words = canonicalize_and_split_words(text)
	for _, wordspec in ipairs(words) do
		local word = generate_phonemic_word(wordspec.word, wordspec.is_cap)
		if is_phonetic then
			word = apply_phonetic_rules(word)
		end
		table.insert(result, word)
	end
	result = table.concat(result, " ")
	result = rsub(result, "[⁀‿]", "")
	if not is_phonetic then
		-- Remove explicit syllable boundaries in phonemic notation. (FIXME: Is this the right thing to do?)
		result = gsub(result, "%.", "")
	end
	-- It doesn't matter so much whether we return composed or decomposed Unicode except for unit tests, where the expected
	-- values are composed.
	return mw.ustring.toNFC(result)
end

-- External entry point to convert arbitrary text to its phonemic IPA representation.
function export.phonemic(text)
	return do_phonemic_phonetic(text, false)
end

-- External entry point to convert arbitrary text to its phonetic IPA representation.
function export.phonetic(text)
	return do_phonemic_phonetic(text, true)
end

function export.show(frame)
	local parent_args = frame:getParent().args
	local params = {
		[1] = { required = true, default = "Aufenthalt>s-genehmigung", list = true },
		["pos"] = {},
		["ann"] = {},
	}
	local args = require("parameters").process(parent_args, params)

	local IPA_args = {}
	for _, arg in ipairs(args[1]) do
		local phonemic = export.phonemic(arg, args.pos)
		local phonetic = export.phonetic(arg, args.pos)
		table.insert(IPA_args, {pron = '/' .. phonemic .. '/'})
		if phonemic ~= phonetic then
			table.insert(IPA_args, {pron = '[' .. phonetic .. ']'})
		end
	end

	local anntext
	if args.ann then
		anntext = "'''" .. args.ann .. "''':&#32;"
	else
		anntext = ""
	end

	return anntext .. m_IPA.format_IPA_full(lang, IPA_args)
end
local text = "Hat"
print(export.phonemic(text))


return export