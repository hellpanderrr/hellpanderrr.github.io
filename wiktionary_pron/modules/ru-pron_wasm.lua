--[[
This module implements the template {{ru-IPA}}.

Author: Originally Wyang; rewritten by Benwing; additional contributions
        from Atitarev and a bit from others

FIXME:

1. (DONE) Geminated /j/ from -йя-: treat as any other gemination, meaning it
   may not always be pronounced geminated. Currently we geminate it very late,
   after all the code that reduces geminates. Should be done earlier and
   places that include regexps with /j/ should be modified to also include
   the gemination marker ː. Words with йя: аллилу́йя, ауйяма, ва́йя, ма́йя,
   папа́йя, парано́йя, пира́йя, ра́йя, секво́йя, Гава́йям.
2. (DONE) Should have geminated jj in йе (occurs in e.g. фойе́). Should work
   with gem=y (see FIXME #1). Words with йе: фойе́, колба Эрленмейера, скала
   Айерс, Айерс-Рок, йети, Кайенна, конве́йер, конвейерный, сайентология,
   фейерверк, Гава́йев. Note also Гава́йи with йи.
3. (DONE, CINEMANTIQUE OK WITH FIXES) In Асунсьо́н and Вьентья́н, put a syllable
   break after the н and before consonant + /j/. Use the perm_syl_onset
   mechanism or at least the code that accesses that mechanism. Should
   possibly do this also in VCʲj and V‿Cʲj and VCj and V‿Cj sequences;
   ask Cinemantique if this makes sense.
4. (DONE, CINEMANTIQUE OK WITH FIXES) Fix non-palatal е in льстец.  Other
   words that will be affected (and probably wrong): льви́ца, львя́тник,
   льняно́й, льстить, льди́на, львиный, manual pronunciation given as lʲvʲit͡sə
   and lʲvʲɵnək. Ask Cinemantique.
5. (DONE, CINEMANTIQUE SAYS NO IT DOESN'T) In львёнок, rendered as ˈlʲvɵnək
   instead of ˈlʲvʲɵnək. Apparently same issue as льстец, having to do with
   ь in beginning. This apparently has to do with the "assimilative
   palatalization of consonants when followed by front vowels" code, which
   blocks palatalization when the syllable begins with a cluster with a hard
   sign, or a soft sign followed by a consonant. Then "retraction of front
   vowels in syllables blocking assimilative palatalization" converts e to ɛ
   and i to y in such cases of blocked palatalization (not needed for žcš,
   which are handled by phon_respellings). Ask Cinemantique if this whole
   business makes any sense.
6. (DONE) In prefixes/suffixes like -ин, treat single syllable word as
   unstressed. Also support tilde to force unstressed syllable.
7. (DONE) In ни́ндзя, дз becomes palatal and н should palatal-assimilate to it.
8. (DONE) In под сту́лом, should render as pɐt͡s‿ˈstuləm when actually renders as
   pɐˈt͡s‿stuləm. Also occurs in без ша́пки (bʲɪˈʂ‿ʂapkʲɪ instead of
   bʲɪʂ‿ˈʂapkʲɪ); has something to do with ‿. Similarly occurs in
   не к ме́сту, which should render as nʲɪ‿k‿ˈmʲestʊ, and от я́блони, which
   should render as ɐt‿ˈjæblənʲɪ.
9. (STILL UNCLEAR) In собра́ние, Anatoli renders it as sɐˈbranʲɪ(j)ə with
   optional (j). Ask him when this exactly applies. Does it apply in all ɪjə
   sequences? Only word-finally? Also ijə?
10. (DONE) убе́жищa renders as ʊˈbʲeʐɨɕːʲə instead of ʊˈbʲeʐɨɕːə; уда́ча
   similarly becomes ʊˈdat͡ɕʲə instead of ʊˈdat͡ɕə.
10a. (DONE) Remove the "offending clause" just mentioned, labeled FIXME (10a),
   and fix it as the comment above it describes.
10b. (DONE) Remove the clause labeled "FIXME (10b)".
10c. (DONE) Investigate the clause labeled "FIXME (10c)".  This relates to
   FIXME #9 above concerning собра́ние.
10d. (DONE, NEEDS TESTING) Investigate the clause labeled "FIXME (10d)"
   and apply the instructions there about removing a line and seeing
   whether anything changes.
11. (DONE) тро́лль renders with geminated final l, and with ʲ on wrong side of
   gemination (ːʲ instead of ʲː); note how this also occurs above in -ɕːʲə
   from убе́жищa. (This issue with тро́лль will be masked by the change to
   generally degeminate l; use фуррь; note also галльский.)
12. (DONE, NEEDS TESTING) May be additional errors with gemination in
    combination with explicit / syllable boundary, because of the code
	expecting that syllable breaks occur in certain places; should probably
	rewrite the whole gemination code to be less fragile and not depend on
	exactly where syllable breaks occur in consonant clusters, which it does
	now (might want to rewrite to avoid the whole business of breaking by
	syllable and processing syllable-by-syllable).
13. Many assimilations won't work properly with an explicit / syllable
   boundary.
14. (DONE, ASK WYANG FOR ITS PURPOSE) Eliminate pal=y. Consider first asking
   Wyang why this was put in originally.
15. (DONE) Add test cases: Цю́рих, от а́ба, others.
15a. (DONE) Add test cases: фуррь, по абази́ну (for assimilation of schwas
    across ‿)
15b. (DONE) Add test case англо-норма́ннский (to make sure degemination of нн
    occurs when not between vowels), multi-syllable word ending in a geminate:
	ато́лл (not so good because лл always degeminated), коло́сс, Иоа́нн (good
	because of нн), ха́ос, эвфеми́зм, хору́гвь (NOTE: ruwikt claims гв is voiced,
	I doubt it, ask Cinemantique), наря́д на ку́хню (non-devoicing of д before
	н in next word, ask Cinemantique about this, does it also apply to мрл?),
	ко̀е-кто́
16. (DONE, ADDED SPECIAL HACK; REMOVED WITH NEW FINAL-Е CODE, SHOULD HANDLE
    THROUGH pos=pro; DOESN'T HAVE ANYTHING TO DO WITH SECONDARY STRESS ON О)
	Caused a change in ко̀е-кто́, perhaps because I rewrote code that accepted
	an acute or circumflex accent to also take a grave accent. See how кое is
	actually pronounced here and take action if needed. (ruwiki claims кое is
	indeed pronounced like кои, ask Cinemantique what the rule for final -е
	is and why different in кое vs. мороженое, anything to do with secondary
	stress on о?)
17. (DONE) Rewrote voicing/devoicing assimilation; should make assimilation of
    эвфеми́зм automatic and not require phon=.
18. (DONE) Removed redundant fronting-of-a code near end; make sure this
    doesn't change anything.
19. (DONE, ANSWER IS YES) do сь and зь assimilate before шж, and
    if so do they become ɕʑ? Ask Cinemantique.
20. (DONE) Add pos= to handle final -е. Possibilities appear to be neut
    (neuter noun), adj (adjective, autodetected whether singular or plural),
	comp (comparative), pre (prepositional case), adv (adverb), verb or v (2nd
	plural verb forms).
21. (DONE, DEVOICE UNLESS NEXT WORD BEGINS WITH VOICED OBSTRUENT OR V+VOICED
    OBSTRUENT) Figure out what to do with devoicing or non-devoicing before
	mnrlv vowel. Apparently non-devoicing before vowel is only in fast speech
	with a close juncture and Anatoli doesn't want that; but what about before
	the consonants?
22. (DONE) Figure out what to do with fronting of a and u after or between
	soft consonants, esp. when triggered by a following soft consonant with
	optional or compulsory assimilation. Probably the correct thing to do
	in the case of optional assimilation is to give two pronunciations
	separated by commas, one with non-front vowel + hard consonant, the
	other with front vowel + soft consonant.
23. (DONE, OK) Implement compulsory assimilation of xkʲ; ask Cinemantique to
    make sure this is correct.
24. (DONE, BUT ANATOLI THINKS CONJUNCTION A MIGHT NOT BE REDUCED) Add а to
    list of unstressed particles, but only recognize it and о (and perhaps all
	the others) when not followed by a hyphen; then fix unnecessary cases with
	о̂ (look at tracking cflex category) and the various hacks used in а ведь,
	а сейчас, а то, а не то, а также, а как же; will need to add а̂ to а капелла
	and possibly elsewhere; use different-pron tracking to catch this.
25. (DONE) Add / before цз, чж in Chinese words to ensure syllable boundary in
    right place; ensure that this doesn't mess things up when occurring at
	beginning of word or whatever.
26. (DONE) Rule on voicing assimilation before v: It says in Chew "A
    Computational Phonology of Russian" that v is an obstruent before
	obstruents and a sonorant before sonorants, i.e. v triggers voicing
	assimilation if followed by an obstruent; verify that our code works this
	way.
27. (DONE, NEEDS TESTING) Implement _ to block all assimilation; probably this
    will happen automatically and we just need to remove the _ at the end.
28. (NOT DONE, NOT CORRECT) Change unstressed palatal o to have values like
    regular o, for words like майора́т, Ога́йо, Йоха́ннесбург
29. (DONE) If we need partial reduction of non-final е/я to [ə] instead of [ɪ],
    one way is to use another diacritic, e.g. dot-under; or use a spelling
	like ьа.
30. (DONE) BUG: воѐнно-морско́й becomes [vɐˌenːə mɐrˈskoj] without [je], must be
    due to ѐ being a composed character (may be a bug in the translit module;
	add a test case).
31. In в Япо́нии, в Евро́пе, the initial [j] should be required not optional.
32. (DONE) Should be possible to write п(ь)я́нка, скам(ь)я́ and get optional
    palatalization.
33. (CODE PRESENT BUT NOT COMPLETED) Final unstressed -е that becomes [e]
    should become [ɪ] when not followed by end of utterance or pause.
34. In То́гане (phon=То́ганэ), final -э should be pronounced [e]. Should apply
    in general to -э after paired consonants, but not to e.g. се́рдце.
35. (DONE) тц,дц,тч,дч shoud be always-geminated by default.
36. (DONE) treat ! and ? as separate words so we don't have issues with
    word-final -е before them.
37. (DONE) Distinguish stress accents from other accents.
38. т(ь)ся not directly after the stress should be optionally geminated.
39. (DONE) нра̀вственно-эти́ческий should have optional not mandatory gemination
    of нн.
40. (DONE) Make дц in -дцат- be optionally-geminated, for words like
    одиннадцать, двадцать, тридцатый, etc.
41. (DONE) Don't show grave accents in annotations (but do in phon=).
42. (DONE) -чш- (as in лучший) should be pronounced as -тш-.
43. (DONE) Fix fronting of [au] in two syllables in a row.
44. (DONE) Add pos=imp for imperatives, use it to treat -ться differently from
    infinitives.
45. (DONE) CFLEX should not be treated as stress for the purpose of determining
    whether written а reduces to [ɐ] or [ə].
46. (DONE) Fix [дт]ьт, [сз]ьс sequences (esp. in imperatives) and make
    palatalization of labials optional in [мбпфв]ь[ст][еияёю] (again esp. in
    imperatives).
47. (DONE) Optional palatalization of -ся should apply only to -лся, not always.
48. (DONE) Reduction of стл -> сл should apply only in стлив, not always.
49. (DONE) Convert счит -> щит by default, as with счёт.
50. (DONE) Don't require that m_ru_translit.apply_tr_fixes() be called prior
    to ipa(), but include an argument so that text transformed this way can
    be passed in.
51. (DONE) pos=X/Y and gem=X/Y should require same number of elements as actual
    words rather than counting phonetically-joined words.
52. (DONE) Should treat suffixes as beginning with a palatalizable pseudo-
    consonant, so e.g. initial -е is indicated as palatalization of the
    preceding consonant rather than being preceding by [j], and initial -а is
    rendered as [ə] not [ɐ].
53. (DONE) Should treat prefixes as followed by a pseudoconsonant that doesn't
    trigger voicing or devoicing of preceding consonants.
54. (DONE) Don't add ‿ after prefixes like из-.
55. Suffix -ёр is rendered as unstressed rather than stressed; probably because
    the transliteration doesn't preserve the stress mark.
56. (DONE) -дцат- should be pronounced as if -дцыт-.
57. (DONE) вь (and other palatalized labials) + /j/ should have optional
    patalization.
58. (DONE) Convert unstressed initial э- into и-.
59. (DONE) Implement automatic generation of secondary [ʑː] pronunciation for
    зж/жж except as prefix boundaries; add zhpal= to override this.
60. (DONE) When checking for prefix boundaries, check all listed prefixes +
    those prefixes preceded by по-, не- or непо- (cf. поссо́рить, порассужда́ть,
    нерассуди́тельный, etc.).
]]
mw = require('mw')
local com = require("ru-common")
local m_ru_translit = require("ru-translit")
local strutils = require("string utilities")
local listToSet = require("table/listToSet")

local export = {}
local u = mw.ustring.char
local rfind = mw.ustring.find
local rsubn = mw.ustring.gsub
local rmatch = mw.ustring.match
local rsplit = mw.text.split
ulower = mw.ustring.lower
uupper = mw.ustring.upper
local usub = mw.ustring.sub
local ulen = mw.ustring.len

local remove_grave_accents_from_phonetic_respelling = true -- Anatoli's desired value

-- version of rsubn() that discards all but the first return value
local function rsub(term, foo, bar)
	local retval = rsubn(term, foo, bar)
	return retval
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

-- Clone parent's args while also assigning nil to empty strings.
local function clone_args(frame)
	local args = {}
	for pname, param in pairs(frame:getParent().args) do
		if param == "" then args[pname] = nil
		else args[pname] = param
		end
	end
	return args
end

-- If enabled, compare this module with new version of module in
-- Module:User:Benwing2/ru-pron to make sure all pronunciations are the same.
-- To check for differences, go to Template:tracking/ru-pron/different-pron
-- and look at what links to the page.
local test_new_ru_pron_module = false
-- If enabled, do new code for final -е; else, the old way
local new_final_e_code = true
-- If enabled, do special case for final -е not before a pause
local final_e_non_pausal = false

local AC = u(0x0301) -- acute =  ́
local GR = u(0x0300) -- grave =  ̀
local CFLEX = u(0x0302) -- circumflex =  ̂
local DUBGR = u(0x030F) -- double grave =  ̏
local DOTABOVE = u(0x0307) -- dot above =  ̇
local DOTBELOW = u(0x0323) -- dot below =  ̣
local PSEUDOCONS = u(0xFFF2) -- pseudoconsonant added to the beginning of suffixes and end of prefixes
local TEMPCFLEX = u(0xFFF3) -- placeholder to be converted to a circumflex
local TEMPSUB = u(0xFFF4) -- miscellaneous temporary placeholder

local vow = 'aeiouyɛəäạëöü'
local ipa_vow = vow .. 'ɐɪʊɨæɵʉ'
local vowels, vowels_c = '[' .. vow .. ']', '([' .. vow .. '])'
-- No need to include DUBGR here because we rewrite it to CFLEX very early
local acc = AC .. GR .. CFLEX .. DOTABOVE .. DOTBELOW
local accents = '[' .. acc .. ']'
local stress_accents = '[' .. AC .. GR .. ']'

local perm_syl_onset = listToSet({
	'spr', 'str', 'skr', 'spl', 'skl',
	-- FIXME, do we want sc?
	'sp', 'st', 'sk', 'sf', 'sx', 'sc',
	'pr', 'br', 'tr', 'dr', 'kr', 'gr', 'fr', 'vr', 'xr',
	'pl', 'bl', 'kl', 'gl', 'fl', 'vl', 'xl',
	-- FIXME, do we want the following? If so, do we want vn?
	'ml', 'mn',
	-- FIXME, dž is now converted to ĝž, which will have a syllable
	-- boundary in between
	'šč', 'dž',
})

-- FIXME: Consider changing ӂ internally to ʑ to match ɕ (it is used externally
-- in e.g. дроӂӂи (pronunciation spelling of дрожжи)
local translit_conv = {
	['c'] = 't͡s', ['č'] = 't͡ɕ', ['ĉ'] = 't͡ʂ',
	['g'] = 'ɡ', ['ĝ'] = 'd͡ʐ',
	['ĵ'] = 'd͡z', ['ǰ'] = 'd͡ʑ', ['ӂ'] = 'ʑ',
	['š'] = 'ʂ', ['ž'] = 'ʐ'
}

local translit_conv_j = {
	['cʲ'] = 't͡sʲ',
	['ĵʲ'] = 'd͡zʲ'
}

-- Table of allophones. Each entry is a list of three values:
-- (1) the stressed value; (2) the value immediately before primary or
-- secondary stress; (3) the value elsewhere.
local allophones = {
	['a'] = { 'a', 'ɐ', 'ə' },
	['e'] = { 'e', 'ɪ', 'ɪ' },
	['i'] = { 'i', 'ɪ', 'ɪ' },
	['o'] = { 'o', 'ɐ', 'ə' },
	['u'] = { 'u', 'ʊ', 'ʊ' },
	['y'] = { 'ɨ', 'ɨ', 'ɨ' },
	['ɛ'] = { 'ɛ', 'ɨ', 'ɨ' },
	['ä'] = { 'a', 'ɪ', 'ɪ' },
	['ạ'] = { 'a', 'ɐ', 'ə' },
	['ë'] = { 'e', 'ɪ', 'ɪ' },
	['ö'] = { 'ɵ', 'ɪ', 'ɪ' },
	['ü'] = { 'u', 'ʊ', 'ʊ' },
	['ə'] = { 'ə', 'ə', 'ə' },
}

local devoicing = {
	['b'] = 'p', ['d'] = 't', ['g'] = 'k',
	['z'] = 's', ['v'] = 'f',
	['ž'] = 'š', ['ɣ'] = 'x',
	['ĵ'] = 'c', ['ǰ'] = 'č', ['ĝ'] = 'ĉ',
	['ӂ'] = 'ɕ',
}

local voicing = {
	['p'] = 'b', ['t'] = 'd', ['k'] = 'g',
	['s'] = 'z', ['f'] = 'v',
	['š'] = 'ž', ['c'] = 'ĵ', ['č'] = 'ǰ', ['ĉ'] = 'ĝ',
	['x'] = 'ɣ', ['ɕ'] = 'ӂ'
}

local iotating = {
	['a'] = 'ä',
	['e'] = 'ë',
	['o'] = 'ö',
	['u'] = 'ü'
}

local retracting = {
	['e'] = 'ɛ',
	['i'] = 'y',
}

local fronting = {
	['a'] = 'æ',
	['u'] = 'ʉ',
	['ʊ'] = 'ʉ',
}

-- Prefixes that we recognize specially when they end in a geminated
-- consonant. The first element is the result after applying voicing/devoicing,
-- gemination and other changes. The second element is the original spelling,
-- so that we don't overmatch and get cases like Поттер. We check for these
-- prefixes at the beginning of words and also preceded by ne-, po- and nepo-.
-- The third element should be true if the prefix produces [žž] when assimilated
-- to a following ж, otherwise omitted. We use this as part of the
-- implementation of automatic ӂӂ pronunciation, which shouldn't happen at
-- prefix boundaries.
local geminate_pref = {
	--'abː', --'adː',
	{'be[szšž]ː', 'be[sz]', true},
	--'braomː',
	{'[vf]ː', 'v'},
	{'vo[szšž]ː', 'vo[sz]', true},
	{'i[szšž]ː', 'i[sz]', true},
	--'^inː',
	{'kontrː', 'kontr'},
	{'superː', 'super'},
	{'tran[szšž]ː', 'trans', true},
	{'na[tdcč]ː', 'nad'},
	{'ni[szšž]ː', 'ni[sz]', true},
	{'o[tdcč]ː', 'ot'}, --'^omː',
	{'o[bp]ː', 'ob'},
	{'obe[szšž]ː', 'obe[sz]', true},
    {'po[tdcč]ː', 'pod'},
	{'pre[tdcč]ː', 'pred'}, --'^paszː', '^pozː',
	{'ra[szšž]ː', 'ra[sz]', true},
	{'[szšž]ː', '[sz]', true},
	{'me[žš]ː', 'mež', true},
	{'če?re[szšž]ː', 'če?re[sz]', true},
	-- certain double prefixes involving ra[zs]-
	{'predra[szšž]ː', 'predra[sz]', true},
	{'bezra[szšž]ː', 'bezra[sz]', true},
	{'nara[szšž]ː', 'nara[sz]', true},
	{'vra[szšž]ː', 'vra[sz]', true},
	{'dora[szšž]ː', 'dora[sz]', true},
	-- '^sverxː', '^subː', '^tröxː', '^četyröxː',
}

local sztab = { s='cs', z='ĵz' }
local function ot_pod_sz(pre, sz)
	return pre .. sztab[sz]
end

-- Ad-hoc phonetic substitutions to apply. Each entry is a two-element list,
-- the two arguments to 'rsub()'. These are applied in order, and are
-- carefully ordered to work correctly; don't reorder them unless you know
-- what you're doing. This is called fairly early on, after transliterating,
-- splitting on words, adding ⁀ at the beginning and end of all words, and
-- applying a few other changes. It mostly implements various sorts of
-- assimilations.
local phonetic_subs = {
	{'h', 'ɣ'},

	{'šč', 'ɕː'}, -- conversion of šč to geminate

	-- the following group is ordered before changes that affect ts
	{'n[dt]sk', 'n(t)sk'},
	{'s[dt]sk', 'sck'},
	-- -дцат- (in numerals) has optionally-geminated дц; if unstressed,
	-- pronounced as -дцыт-
	{'dca(' .. accents .. '?)t', function(accent)
		if accent == '' then
			return 'c(c)yt'
		else
			return 'c(c)a' .. accent .. 't'
		end
	end
	},

	-- Add / before цз, чж sequences (Chinese words) and assimilate чж
	{'cz', '/cz'},
	{'čž', '/ĝž'},

	-- main changes for affricate assimilation of [dt] + sibilant, including ts;
	-- we either convert to "short" variants t͡s, d͡z, etc. or to "long" variants
	-- t͡ss, d͡zz, etc.
	-- 1. т с, д з across word boundary, also т/с, д/з with explicitly written
	--    slash, use long variants.
	{'[dt](ʹ?[ ‿⁀/]+)s', 'c%1s'},
	{'[dt](ʹ?[ ‿⁀/]+)z', 'ĵ%1z'},
	-- 2. тс, дз + vowel use long variants.
	{'[dt](ʹ?)s(j?' .. vowels .. ')', 'c%1s%2'},
	{'[dt](ʹ?)z(j?' .. vowels .. ')', 'ĵ%1z%2'},
	-- 3. тьс, дьз use long variants.
	{'[dt]ʹs', 'cʹs'},
	{'[dt]ʹz', 'ĵʹz'},
	-- 4. word-initial от[сз]-, под[сз]- use long variants because there is
	--    a morpheme boundary.
	{'(⁀o' .. accents .. '?)t([sz])', ot_pod_sz},
	{'(⁀po' .. accents .. '?)d([sz])', ot_pod_sz},
	-- 5. other тс, дз use short variants.
	{'[dt]s', 'c'},
	{'[dt]z', 'ĵ'},
	-- 6. тш, дж always use long variants (FIXME, may change)
	{'[dtč](ʹ?[ %-‿⁀/]*)š', 'ĉ%1š'},
	{'[dtč](ʹ?[ %-‿⁀/]*)ž', 'ĝ%1ž'},
	-- 7. soften palatalized hard hushing affricates resulting from the previous
	{'ĉʹ', 'č'},
	{'ĝʹ', 'ǰ'},

	-- changes that generate ɕː and ɕč through assimilation:
	-- зч and жч become ɕː, as does сч at the beginning of a word and in the
	-- sequence счёт when not following [цдт] (подсчёт); else сч becomes ɕč
	-- (отсчи́тываться), as щч always does (рассчитáть written ращчита́ть)
	{'[cdt]sč', 'čɕː'},
	{'ɕːč', 'ɕč'},
	{'[zž]č', 'ɕː'},
	{'[szšž]ɕː?', 'ɕː'},
	{'⁀sč', '⁀ɕː'},
	{'sč(j?[oi]' .. accents .. '?)t', 'ɕː%1t'},
	{'sč', 'ɕč'},

	-- misc. changes for assimilation of [dtsz] + sibilants and affricates
	{'[sz][dt]c', 'sc'},
	{'([rn])[dt]([cč])', '%1%2'},
	-- дц, тц, дч, тч + vowel always remain geminated, so mark this with ˑ;
	-- if not followed by a vowel, as in e.g. путч, use normal gemination
	-- (it will normally be degeminated)
	{'[dt]([cč])(' .. vowels .. ')', '%1ˑ%2'},
	{'[dt]([cč])', '%1%1'},
	-- the following is ordered before the next one, which applies assimilation
	-- of [тд] to щ (including across word boundaries)
	{'n[dt]ɕ', 'nɕ'},
	-- [сз] and [сз]ь before soft affricates [щч], including across word
	-- boundaries; note that the common sequence сч has already been handled
	{'[zs]ʹ?([ ‿⁀/]*[ɕč])', 'ɕ%1'},
	-- reduction of too many ɕ's, which can happen from the previous
	{'ɕɕː', 'ɕː'},
	-- assimilation before [тдц] and [тдц]ь before щ
	{'[cdt]ʹ?([ ‿⁀/]*)ɕ', 'č%1ɕ'},
	-- assimilation of [сз] and [сз]ь before [шж]
	{'[zs]([ ‿⁀/]*)š', 'š%1š'},
	{'[zs]([ ‿⁀/]*)ž', 'ž%1ž'},
	{'[zs]ʹ([ ‿⁀/]*)š', 'ɕ%1š'},
	{'[zs]ʹ([ ‿⁀/]*)ž', 'ӂ%1ž'},
	-- assimilation of [сз]ь before с[еияёю] (in imperatives esp. before ся)
	{'[zs]ʹs([eij])', 'sˑ%1'},
	-- assimilation of [тд]ь before т[еияёю] (e.g. in imperatives esp. before те)
	{'[td]ʹt([eij])', 'tˑ%1'},

	-- optional palatalization of palatalized labials before another consonant
	-- in [ст][еияёю] (esp. in imperatives before -те, -ся)
	-- FIXME, perhaps we should either generalize this or restrict it only
	-- to imperatives
	{'([mpbfv])ʹ([st][eij])', '%1(ʹ)%2'},
	
	{'sverxi', 'sverxy'},
	{'stʹd', 'zd'},
	-- this will often become degeminated
	{'tʹd', 'dd'},

	-- loss of consonants in certain clusters
	{'([ns])[dt]g', '%1g'},
	{'zdn', 'zn'},
	{'lnc', 'nc'},
	{'[sz]t(li' .. accents .. '?v)', 's%1'},
	{'[sz]tn', 'sn'},

	-- initial unstressed э -> и; should precede backing of /i/ in close juncture	
	{'⁀ɛ([^' .. acc .. '])', '⁀i%1'},
	-- unstressed э after a vowel -> и; repeated to handle the unlikely case
	-- where two ээ occur in a row; FIXME, this is a type of ikanye, and we
	-- mostly implement ikanye later on using the chart in 'allophones', so
	-- it would be nice to merge these two cases, but I can't think of an
	-- obvious way to do it
	{'(' .. vowels .. accents .. '?)ɛ([^' .. acc .. '])', '%1i%2'},
	{'(' .. vowels .. accents .. '?)ɛ([^' .. acc .. '])', '%1i%2'},
	-- backing of /i/ after hard consonants in close juncture
	{'([mnpbtdkgfvszxɣrlšžcĵĉĝ])⁀‿⁀i', '%1⁀‿⁀y'},
}

local cons_assim_palatal = {
	-- assimilation of tn, dn, sn, zn, st, zd, nč, nɕ is handled specially
	compulsory = listToSet({'ntʲ', 'ndʲ', 'xkʲ',
	    'csʲ', 'ĵzʲ', 'ncʲ', 'nĵʲ'}),
	optional = listToSet({'slʲ', 'zlʲ', 'nsʲ', 'nzʲ',
		'mpʲ', 'mbʲ', 'mfʲ', 'fmʲ'})
}

-- words which will be treated as accentless (i.e. their vowels will be
-- reduced), and which will liaise with a preceding or following word;
-- this will not happen if the words have an accent mark, cf.
-- по́ небу vs. по не́бу, etc.
local accentless = {
	-- class 'pre': particles that join with a following word
	pre = listToSet({'bez', 'bliz', 'v', 'vo', 'da', 'do',
       'za', 'iz', 'iz-pod', 'iz-za', 'izo', 'k', 'ko', 'mež',
       'na', 'nad', 'nado', 'ne', 'ni', 'ob', 'obo', 'ot', 'oto',
       'pered', 'peredo', 'po', 'pod', 'podo', 'pred', 'predo', 'pri', 'pro',
       's', 'so', 'u', 'čerez'}),
	-- class 'prespace': particles that join with a following word, but only
	--   if a space (not a hyphen) separates them; hyphens are used here
	--   to spell out letters, e.g. а-эн-бэ́ for АНБ (NSA = National Security
	--   Agency) or о-а-э́ for ОАЭ (UAE = United Arab Emirates)
	prespace = listToSet({'a', 'o'}),
	-- class 'post': particles that join with a preceding word
	post = listToSet({'by', 'b', 'ž', 'že', 'li', 'libo', 'lʹ', 'ka',
	   'nibudʹ', 'tka'}),
	-- class 'posthyphen': particles that join with a preceding word, but only
	--   if a hyphen (not a space) separates them
	posthyphen = listToSet({'to'}),
}

-- Pronunciation of final unstressed -е, depending on the part of speech and
--   exact ending. Also used for pronunciation of -ться in imperatives vs.
--   infinitives.
--
-- Endings:
--   oe = -ое
--   ve = any other vowel plus -е (FIXME, may have to split out -ее)
--   je = -ье
--   softpaired = soft paired consonant + -е
--   hardsib = hard sibilant (ц, ш, ж) + -е
--   softsib = soft sibilant (ч, щ) + -е
--
-- Parts of speech:
--   def = default used in absence of pos
--   n/noun = neuter noun in the nominative/accusative singular (but not ending
--     in adjectival -ое or -ее; those should be considered as adjectives)
--   pre = prepositional case singular
--   dat = dative case singular (treated same as prepositional case singular)
--   voc = vocative case (currently treated as 'mid')
--   nnp = noun nominative plural in -е (гра́ждане, боя́ре, армя́не); not
--     adjectival plurals in -ие or -ые, including adjectival nouns
--     (да́нные, а́вторские)
--   inv = invariable noun or other word (currently treated as 'mid')
--   a/adj = adjective or adjectival noun (typically either neuter in -ое or
--     -ее, or plural in -ие, -ые, or -ье, or short neuter in unpaired
--     sibilant + -е)
--   c/com = comparative (typically either in -ее or sibilant + -е)
--   adv = adverb
--   p = preposition (treated same as adverb)
--   v/vb/verb = finite verbal form (usually 2nd-plural in -те), but not
--     imperatives (use pos=imp) and not participle forms, which should be
--     treated as adjectives
--   pro = pronoun (кое-, какие-, ваше, сколькие)
--   num = number (двое, трое, обе, четыре; currently treated as 'mid')
--   pref = prefix (treated as 'high' because integral part of word)
--   hi/high = force high values ([ɪ] or [ɨ])
--   mid = force mid values ([e] or [ɨ])
--   lo/low/schwa = force low, really schwa, values ([ə])
--
-- Possible values:
--   1. ə [ə], e [e], i [ɪ] after a vowel or soft consonant
--   2. ə [ə] or y [ɨ] after a hard sibilant
--
-- If a part of speech doesn't have an entry for a given type of ending,
--   it receives the default value. If a part of speech's entry is a string,
--   it's an alias for another way of specifying the same part of speech
--   (e.g. n=noun).
local pos_properties = {
	def={oe='ə', ve='e', je='e', softpaired='e', hardsib='y', softsib='e', tsjapal='n'},
	noun={oe='ə', ve='e', je='e', softpaired='e', hardsib='ə', softsib='e'},
	n='noun',
	pre={oe='e', ve='e', softpaired='e', hardsib='y', softsib='e'},
	dat='pre',
	voc='mid',
	nnp={softpaired='e'}, -- FIXME, not sure about this
	inv='mid', --FIXME, not sure about this (e.g. вице-, кофе)
	adj={oe='ə', ve='e', je='ə'}, -- FIXME: Not sure about -ее, e.g. neut adj си́нее; FIXME, not sure about short neuter adj, e.g. похо́же from похо́жий, дорогосто́яще from дорогосто́ящий, should this be treated as neuter noun?
	a='adj',
	com={ve='e', hardsib='y', softsib='e'},
	c='com',
	adv={softpaired='e', hardsib='y', softsib='e'},
	p='adv', --FIXME, not sure about prepositions
	verb={softpaired='e'},
	v='verb',
	vb='verb',
	-- Imperatives like other verbs except that final -ться is palatalized
	imp={softpaired='e', tsjapal='y'},
	impv='imp',
	pro={oe='i', ve='i'}, --FIXME, not sure about ваше, сколькие, какие-, кое-
	num='mid', --FIXME, not sure about обе
	pref='high',
	-- forced values
	high={oe='i', ve='i', je='i', softpaired='i', hardsib='y', softsib='i'},
	hi='high',
	mid={oe='e', ve='e', je='e', softpaired='e', hardsib='y', softsib='e'},
	low={oe='ə', ve='ə', je='ə', softpaired='ə', hardsib='ə', softsib='ə'},
	lo='low',
	schwa='low'
}

local function ine(x)
	return x ~= "" and x or nil
end

function track(page)
	local track = require("debug/track")
	track("ru-pron/" .. page)
	return true
end

print(track('123'))

-- remove accents that we don't want to appear in the phonetic respelling
function phon_respelling(text, remove_grave)
	text = rsub(text, '[' .. CFLEX .. DUBGR .. DOTABOVE .. DOTBELOW .. '‿]', '')
	-- Remove grave accents from annotations but maybe not from phonetic respelling
	if remove_grave then
		text = com.remove_grave_accents(text)
	end
	return text
end

-- Direct implementation of {{ru-IPA}}.
function export.ru_IPA(frame)
	local args = clone_args(frame)
	local text = args[1] or args.phon or mw.title.getCurrentTitle().text
	local origtext, transformed_text = m_ru_translit.apply_tr_fixes(text,
		args.noadj, args.noshto)
	local pronunciations = export.ipa(transformed_text, args.adj, args.gem,
		args.bracket or "y", args.pos, args.zhpal, "transformed")
	local maintext
	if args.raw then
		return table.concat(pronunciations, ", ")
	else
		local anntext = (args.ann == "y" and "'''" .. phon_respelling(text, "remove grave") .. "''':&#32;" or
			args.ann and "'''" .. args.ann .. "''':&#32;" or
			"")
		local lang = require("languages").getByCode("ru")
		
		for i, pronunciation in ipairs(pronunciations) do
			pronunciations[i] = { pron = pronunciation }
		end
		
		maintext = require("IPA").format_IPA_full(lang, pronunciations)
		
		local respelling
		
		if args.phon then
			respelling = args.phon
		elseif origtext ~= transformed_text then
			respelling = transformed_text
		end
		
		local respelling_text = ""
		
		if respelling then
			respelling = phon_respelling(respelling, remove_grave_accents_from_phonetic_respelling)
			respelling_text = respelling and "&nbsp;(''phonetic respelling'': " .. require("script utilities").tag_text(respelling, lang) .. ")"
		end
		
		return anntext .. maintext .. respelling_text
	end
end

-- Forward function declarations
local ru_ipa_main

-- Return the actual IPA corresponding to Cyrillic text. ADJ, GEN, BRACKET
-- POS and ZHPAL are as in [[Template:ru-IPA]]. If IS_TRANFORMED is true, the
-- text has already been passed through m_ru_translit.apply_tr_fixes();
-- otherwise, this will be done. Note that the return value is a list of one or
-- more valid pronunciations.
function export.ipa(text, adj, gem, bracket, pos, zhpal, is_transformed)
	local new_module_result
	-- Test code to compare existing module to new one.
	if test_new_ru_pron_module then
		local m_new_ru_pron = require("User:Benwing2/ru-pron")
		new_module_result = m_new_ru_pron.ipa(text, adj, gem, bracket, pos,
			zhpal, is_transformed)
	end

	if type(text) == 'table' then
		text, adj, gem, bracket, pos, zhpal =
			(ine(text.args.phon) or ine(text.args[1])),
			ine(text.args.adj),
			ine(text.args.gem),
			ine(text.args.bracket),
			ine(text.args.pos),
			ine(text.args.zhpal)
		if not text then
			text = mw.title.getCurrentTitle().text
		end
	end

	if not is_transformed then
		local origtext, transformed_text = m_ru_translit.apply_tr_fixes(text)
		text = transformed_text
	end
	
	gem = gem or ""
	-- If a multipart gemination spec, split into components.
	if rfind(gem, "/") then
		gem = rsplit(gem, "/")
		for i=1,#gem do
			gem[i] = usub(gem[i], 1, 1)
		end
	else
		gem = usub(gem, 1, 1)
	end
	-- Verify that gem (or each part of multipart gem) is recognized
	for _, g in ipairs(type(gem) == "table" and gem or {gem}) do
		if g ~= "" and g ~= "y" and g ~= "o" and g ~= "n" then
			error("Unrecognized gemination spec '" .. g .. ": Should be y, yes, o, opt, n, no, or empty")
		end
	end

	bracket = ine(usub(bracket or '', 1, 1))
	if bracket == 'n' then
		bracket = nil
	end

	pos = pos or "def"
	-- If a multipart part of speech, split into components, and convert
	-- each blank component to the default.
	if rfind(pos, "/") then
		pos = rsplit(pos, "/")
		for i=1,#pos do
			if pos[i] == "" then
				pos[i] = "def"
			end
		end
	end
	-- Verify that pos (or each part of multipart pos) is recognized
	for _, p in ipairs(type(pos) == "table" and pos or {pos}) do
		if not pos_properties[p] then
			error("Unrecognized part of speech '" .. p .. "': Should be n/noun/neut, a/adj, c/com, pre, dat, adv, inv, voc, v/verb, pro, hi/high, mid, lo/low/schwa or omitted")
		end
	end

	text = ulower(text)

	local combined_gem = type(gem) == "table" and table.concat(gem, "/") or gem
	if combined_gem ~= "" then
		track("gem")
		track("gem/" .. combined_gem)
	end
	if adj then
		track("adj")
	end
	-- don't include h here because we allow it as a legitimate alternative
	-- for ɣ. Include vowels with all of the accents that have special meaning
	-- for this module. (FIXME, maybe should also include double-grave accents,
	-- although probably not used anywhere.)
	if rfind(text, "[a-gi-zščžáéíóúýàèìòùỳâêîôûŷạẹịọụỵȧėȯẏ]") then
		track("latin-text")
	end
	if rfind(text, "[сз]ч") then
		track("sch")
	end
	if rfind(text, "[шж]ч") then
		track("shch")
	end
	if rfind(text, CFLEX) then
		track("cflex")
	end
	if rfind(text, DUBGR) then
		track("dubgr")
	end

	text = rsub(text, "``", DUBGR)
	text = rsub(text, "`", GR)
	text = rsub(text, "@", DOTABOVE)
	text = rsub(text, "%^", CFLEX)
	text = rsub(text, DUBGR, CFLEX)

	-- translit doesn't always convert э to ɛ (depends on whether a consonant
	-- precedes), so do it ourselves before translit
	text = rsub(text, 'э', 'ɛ')
	-- vowel + йе should have double jj, but the translit module will translit
	-- it the same as vowel + е, so do it ourselves before translit
	text = rsub(text, '([' .. com.vowel .. ']' .. com.opt_accent .. ')й([еѐ])',
		'%1йй%2')
	-- transliterate and decompose Latin vowels with accents, recomposing
	-- certain key combinations; don't include accent on monosyllabic ё, so
	-- that we end up without an accent on such words. NOTE: Not clear we
	-- need to be decomposing like this any more, although it is still
	-- useful if the user supplies Latin text, which we allow (although
	-- undocumented).
	text = com.decompose(m_ru_translit.tr_after_fixes(text))

	-- handle old ě (e.g. сѣдло́), ǒ (e.g. сѣ̈дла) and ǫ (e.g. ея̈)
	text = text:gsub("ě", "e")
		:gsub("ǒ", "o")
		:gsub("ǫ", "o")
	-- handle sequences of accents (esp from ё with secondary/tertiary stress)
	text = rsub(text, accents .. '+(' .. accents .. ')', '%1')

	-- convert commas and en/en dashes to IPA foot boundaries
	text = rsub(text, '%s*[,–—]%s*', ' | ')

	-- canonicalize multiple spaces
	text = rsub(text, '%s+', ' ')

	-- Add primary stress to single-syllable words preceded or followed by
	-- unstressed particle or preposition. Add "tertiary" stress to remaining
	-- single-syllable words that aren't a particle, preposition, prefix or
	-- suffix and don't already bear an accent (including force-reduction
	-- accents, i.e. dot-above/dot-below); "tertiary stress" means a vowel is
	-- treated as stressed for the purposes of vowel reduction but isn't
	-- marked with a primary or secondary stress marker; we repurpose a
	-- circumflex for this purpose. We need to preserve the distinction
	-- between spaces and hyphens because (1) we only recognize certain
	-- post-accentless particles following a hyphen (to distinguish e.g.
	-- 'то' from '-то'); (2) we only recognize certain pre-accentless
	-- particles preceding a space (to distinguish particles 'о' and 'а' from
	-- spelled letters о and а, which should not be reduced); and (3) we
	-- recognize hyphens for the purpose of marking unstressed prefixes and
	-- suffixes.
	local word = strutils.capturing_split(text, "([ %-]+)")
	for i = 1, #word do
		-- check for single-syllable words that need a stress; they must meet
		-- the following conditions:
		-- 1. must not be an accentless word, which is any of the following:
		--         1a. in the "pre" class, or
		if not (accentless['pre'][word[i]] or
				-- 1b. in the "prespace" class if followed by space and another word, or
				i < #word - 1 and accentless['prespace'][word[i]] and word[i+1] == " " or
				-- 1c. in the "post" class if preceded by another word and
				--     not followed by a hyphen (this is because words like
				--     ка and же are also used for spelling initialisms), or
				i > 2 and accentless['post'][word[i]] and word[i+1] ~= "-" or
				-- 1d. in the "posthyphen" class preceded by a hyphen and another word
				--     (and not followed by a hyphen, see 1c);
				i > 2 and accentless['posthyphen'][word[i]] and word[i-1] == "-" and word[i+1] ~= "-") and
		-- 2. must be one syllable;
			ulen(rsub(word[i], '[^' .. vow .. ']', '')) == 1 and
		-- 3. must not have any accents (including dot-above, forcing reduction);
			not rfind(word[i], accents) and
		-- 4. must not be a prefix or suffix, identified by a preceding or trailing hyphen, i.e. one of the following:
		--         4a. utterance-initial preceded by a hyphen, or
			not (i == 3 and word[2] == "-" and word[1] == "" or
			    -- 4b. non-utterance-initial preceded by a hyphen, or
				i >= 3 and word[i-1] == " -" or
			    -- 4c. utterance-final followed by a hyphen, or
				i == #word - 2 and word[i+1] == "-" and word[i+2] == "" or
			    -- 4d. non-utterance-final followed by a hyphen;
				i <= #word - 2 and word[i+1] == "- ") then

		-- OK, we have a stressable single-syllable word; either add primary
		-- or tertiary stress:
		-- 1. add primary stress if preceded or followed by an accentless word,
			if (i > 2 and accentless['pre'][word[i-2]] or
				i > 2 and word[i-1] == " " and accentless['prespace'][word[i-2]] or
				i < #word - 1 and accentless['post'][word[i+2]] and word[i+3] ~= "-" or
				i < #word - 1 and word[i+1] == "-" and accentless['posthyphen'][word[i+2]] and word[i+3] ~= "-") then
				word[i] = rsub(word[i], vowels_c, '%1' .. AC)
		-- 2. else add tertiary stress
			else
				word[i] = rsub(word[i], vowels_c, '%1' .. CFLEX)
			end
		end
	end

	-- count number of words and make sure we have correct number of
	-- gemination and part-of-speech specs if a multipart spec is given
	local num_real_words = 0
	for i = 1, #word do
		if (i % 2) == 1 and word[i] ~= "" then
			num_real_words = num_real_words + 1
		end
	end
	if type(gem) == "table" and #gem ~= num_real_words then
		error("Number of gemination specs (" .. #gem .. ") should match number of words (" .. num_real_words .. ")")
	end
	if type(pos) == "table" and #pos ~= num_real_words then
		error("Number of parts of speech (" .. #pos .. ") should match number of words (" .. num_real_words .. ")")
	end

	-- make unaccented prepositions and particles liaise with the following or
	-- preceding word; in the process, fix up number of elements in gem/pos
	-- tables so there's a single element for the combined word
	local real_word_index = 0
	for i = 1, #word do
		if (i % 2) == 1 and word[i] ~= "" then
			real_word_index = real_word_index + 1
		end
		if i < #word - 1 and (accentless['pre'][word[i]] or accentless['prespace'][word[i]] and word[i+1] == " ") and
			-- don't add ‿ onto the end of a prefix; a prefix is a word followed by a hyphen that is in turn
			-- followed by a space or end of terms; note that ends of terms after a hyphen are marked by a blank
			-- string due to the way capturing_split() works
			not (word[i+1] == "-" and (word[i+2] == " " or word[i+2] == "" and i == #word - 2)) then
			word[i+1] = '‿'
			if type(gem) == "table" then
				table.remove(gem, real_word_index)
			end
			if type(pos) == "table" then
				table.remove(pos, real_word_index)
			end
		elseif i > 2 and (accentless['post'][word[i]] and word[i+1] ~= "-" or
				accentless['posthyphen'][word[i]] and word[i-1] == "-" and word[i+1] ~= "-") then
			word[i-1] = '‿'
			-- for unaccented words that liaise with the preceding word,
			-- remove the gemination spec corresponding to the unaccented word
			-- because the gemination in question is almost certainly in the
			-- preceding word, but remove the POS spec corresponding to the
			-- preceding word because it's the final -е of the unaccented word
			-- that the POS will refer to
			if type(gem) == "table" then
				table.remove(gem, real_word_index)
			end
			if type(pos) == "table" then
				table.remove(pos, real_word_index - 1)
			end
		end
	end

	-- rejoin words, convert hyphens to spaces and eliminate stray spaces
	-- resulting from this; but convert hyphens at the beginning of suffixes
	-- to a pseudoconsonant, so we treat vowels at the beginning of suffixes
	-- as if they are followed by a consonant, not word-initial. Similarly
	-- convert hyphens at the end of prefixes to a pseudoconsonant.
	text = table.concat(word, "")
	text = rsub(text, '^%-', PSEUDOCONS)
	text = rsub(text, '%s%-', ' ' .. PSEUDOCONS)
	text = rsub(text, '%-$', PSEUDOCONS)
	text = rsub(text, '%-%s', PSEUDOCONS .. ' ')
	text = rsub(text, '[%-%s]+', ' ')
	text = rsub(text, '^ ', '')
	text = rsub(text, ' $', '')

	-- add a ⁀ at the beginning and end of every word and at close juncture
	-- boundaries; we will remove this later but it makes it easier to do
	-- word-beginning and word-end rsubs
	text = rsub(text, ' ', '⁀ ⁀')
	text = rsub(text, '([!?])', '⁀%1⁀')
	text = '⁀' .. text .. '⁀'
	text = rsub(text, '‿', '⁀‿⁀')

	-- At this point, the spelling has been normalized (see the comment to
	-- ru_ipa_main() below). Now we need to handle any pronunciation-spelling
	-- variants (particularly, handling зж and жж, which have both
	-- non-palatalized and palatalized variants except at prefix boundaries)
	-- and convert each variant to IPA.

	local alltext

	-- If zž or žž occur not at a prefix boundary, then generate two variants,
	-- the first with non-palatal [ʐː] and the second with [ʑː] (potentially
	-- with nearby vowels affected appropriately for the palatalization
	-- difference). But don't do this if zhpal=n.
	if zhpal == 'n' or not rfind(text, 'ž') then
		-- speed up the majority of cases where ž doesn't occur
		alltext = {text}
	else
		-- First, go through and mark all prefix boundaries where a ž directly 
		-- follows the prefix by inserting a ˑ between prefix and ž. This
		-- prevents us from generating the [ʑː] variant (notated internally as
		-- ӂӂ). Don't do this if zhpal=y, which defeats this check.
		if zhpal ~= 'y' then
			for _, gempref in ipairs(geminate_pref) do
				local origspell = gempref[2]
				local is_zh = gempref[3]
				if is_zh then
					-- allow all vowels to have accents following them
					origspell = rsub(origspell, vowels_c, '%1' .. accents .. '?')
					text = rsub(text, '(⁀' .. origspell .. ')ž', '%1ˑž')
					text = rsub(text, '(⁀po' .. origspell .. ')ž', '%1ˑž')
					text = rsub(text, '(⁀ne' .. origspell .. ')ž', '%1ˑž')
					text = rsub(text, '(⁀nepo' .. origspell .. ')ž', '%1ˑž')
				end
			end
		end
		-- Then, if zž or žž are present (which will exclude prefix boundaries
		-- because a ˑ marker will intervene), generate the two possibilities,
		-- else generate only one.
		local alltext1
		if rfind(text, '[zž]ž') then
			alltext1 = {text, rsub(text, '[zž]ž', 'ӂӂ')}
		else
			alltext1 = {text}
		end
		-- Finally, remove the ˑ marker.
		alltext = {}
		for _, text in ipairs(alltext1) do
			table.insert(alltext, rsub(text, 'ˑ', ''))
		end
	end

	-- Now generate the pronunciation(s) for each of the spelling variants
	-- we generate above. (In some cases there are multiple pronunciation
	-- variants generated, e.g. in the sequence palatalized consonant + a/u +
	-- optionally palatalized consonant.)
	local allpron = {}
	for _, text in ipairs(alltext) do
		local thispron = ru_ipa_main(text, adj, gem, bracket, pos)
		for _, pron in ipairs(thispron) do
			table.insert(allpron, pron)
		end
	end

	-- Handle test_new_ru_pron_module if specified (tracking for changed
	-- pronunciations).
	if test_new_ru_pron_module then
		local string_version = table.concat(allpron, ", ")
		if new_module_result ~= string_version then
			--error(string_version .. " || " .. new_module_result)
			track("different-pron")
		else
			track("same-pron")
		end
	end

	return allpron
end

-- Convert normalized spelling into actual pronunciation. Return value is a
-- list of one or more valid pronunciations. "Normalized" means that various
-- normalization transformations have been applied, e.g.
-- (1) text is transliterated and accents decomposed;
-- (2) ‿ is added where appropriate to join clitics to normally-stressed words;
-- (3) ⁀ is added at the beginning and end of all words;
-- (4) primary or tertiary stress may have been added to single-syllable words
--     as appropriate;
-- (5) punctuation is removed and replaced with spaces and/or IPA foot
--     boundaries;
-- (6) etc.
-- Note that normalization does *not* implement assimilations, conversion of
-- vowels or consonants to their IPA equivalents, or other intra-word changes.
ru_ipa_main = function(text, adj, gem, bracket, pos)
	-- save original word spelling before respellings, (de)voicing changes,
	-- geminate changes, etc. for implementation of geminate_pref
	local orig_word = rsplit(text, " ", true)
	local word
	
	-- remove any apostrophes, since any still present at this stage
	-- are purely cosmetic (e.g. in foreign names)
	-- any apostrophes in the input that are standing in for hard signs
	-- should have already been dealt with by the transliteration
	-- module
	text = rsub(text, '[\'’]', '')
	
	-- insert or remove /j/ before [aou] so that palatal versions of these
	-- vowels are always preceded by /j/ and non-palatal versions never are
	-- (do this before the change below adding tertiary stress to final
	-- palatal о):
	-- (1) Non-palatal [ou] after always-hard шж (e.g. in брошю́ра, жю́ри)
	--     despite the spelling (FIXME, should this also affect [a]?)
	text = rsub(text, '([šž])j([ou])', '%2%3')
	-- (2) Palatal [aou] after always-soft щчӂ and voiced variant ǰ (NOTE:
	--     this happens before the change šč -> ɕː in phonetic_subs)
	text = rsub(text, '([čǰӂ])([aou])', '%1j%2')
	-- (3) ьо is pronounced as ьйо, i.e. like (possibly unstressed) ьё, e.g.
	--     in Асунсьо́н
	text = rsub(text, 'ʹo', 'ʹjo')

	-- add tertiary stress to some final -о (this needs to be done before
	-- eliminating dot-above, after adding ⁀, after adding /j/ before palatal о):
	-- (1) after vowels, e.g. То́кио
	text = rsub(text, '(' .. vowels .. accents .. '?o)⁀', '%1' .. CFLEX .. '⁀')
	-- (2) when palatal, e.g. ра́нчо, га́учо, ма́чо, Ога́йо
	text = rsub(text, 'jo⁀', 'jo' .. CFLEX .. '⁀')

	-- eliminate dot-above, which has served its purpose of preventing any
	-- sort of stress (needs to be done after adding tertiary stress to
	-- final -о)
	text = rsub(text, DOTABOVE, '')
	-- eliminate dot-below (needs to be done after changes above that insert
	-- j before [aou] after always-soft щчӂ)
	text = rsub(text, 'ja' .. DOTBELOW, 'jạ')
	if rfind(text, DOTBELOW) then
		error("Dot-below accent can only be placed on я or palatal а")
	end

	text = adj and rsub(text, '(.[aoe]́?)go(' .. AC .. '?)⁀', '%1vo%2⁀') or text
	text = adj and rsub(text, '(.[aoe]́?)go(' .. AC .. '?)sja⁀', '%1vo%2sja⁀') or text

	function fetch_pos_property(i, ending)
		local thispos = type(pos) == "table" and pos[i] or pos
		local chart = pos_properties[thispos]
		while type(chart) == "string" do -- handle aliases
			chart = pos_properties[chart]
		end
		assert(type(chart) == "table")
		local sub = chart[ending] or pos_properties['def'][ending]
		assert(sub)
		return sub
	end

	-- Pos-specific handling of final -ться: palatalized if pos=imp, else not
	-- (infinitives). If we have multiple parts of speech, we need to be
	-- trickier, splitting by word.
	local function final_tsja_processing(pron, i)
		local tsjapal = fetch_pos_property(i, 'tsjapal')
		if tsjapal == 'n' then
			-- FIXME!!! Should these also pay attention to grave accents?
			pron = rsub(pron, '́tʹ?sja⁀', '́cca⁀')
			pron = rsub(pron, '([^́])tʹ?sja⁀', '%1ca⁀')
		end
		return pron
	end
	if type(pos) == "table" then
		--split by word and process each word
		word = rsplit(text, " ", true)
		for i = 1, #word do
			word[i] = final_tsja_processing(word[i], i)
		end
		text = table.concat(word, " ")
	else
		text = final_tsja_processing(text, 1)
	end

	--phonetic substitutions of various sorts
	for _, phonsub in ipairs(phonetic_subs) do
		text = rsub(text, phonsub[1], phonsub[2])
	end

	--voicing, devoicing
	--NOTE: v before an obstruent assimilates in voicing and triggers voicing
	--assimilation of a preceding consonant; neither happens before a sonorant
	--1. absolutely final devoicing
	text = rsub(text, '([bdgvɣzžĝĵǰӂ])(ʹ?⁀)$', function(a, b)
		return devoicing[a] .. b end)
	--2. word-final devoicing before another word
	text = rsub(text, '([bdgvɣzžĝĵǰӂ])(ʹ?⁀ ⁀[^bdgɣzžĝĵǰӂ])', function(a, b)
		return devoicing[a] .. b end)
	--3. voicing/devoicing assimilation; repeat to handle recursive assimilation
	while true do
		local new_text = rsub(text, '([bdgvɣzžĝĵǰӂ])([ ‿⁀ʹːˑ()/]*[ptkfxsščɕcĉ])', function(a, b)
			return devoicing[a] .. b end)
		new_text = rsub(new_text, '([ptkfxsščɕcĉ])([ ‿⁀ʹːˑ()/]*v?[ ‿⁀ʹːˑ()/]*[bdgɣzžĝĵǰӂ])', function(a, b)
			return voicing[a] .. b end)
		if new_text == text then
			break
		end
		text = new_text
	end

	--re-notate orthographic geminate consonants
	text = rsub(text, '([^' .. vow .. '.%-_])' .. '%1', '%1ː')
	text = rsub(text, '([^' .. vow .. '.%-_])' .. '%(%1%)', '%1(ː)')

	--rewrite iotated vowels
	text = rsub(text, '(j[%(ːˑ%)]*)([aeou])', function(a, b)
		return a .. iotating[b] end)
	-- eliminate j after consonant and before iotated vowel (including
	-- semi-reduced ạ)
	text = rsub(text, '([^' .. vow .. acc .. 'ʹʺ‿⁀ ]/?)j([äạëöü])', '%1%2')

	--split by word and process each word
	word = rsplit(text, " ", true)

	for i = 1, #word do
		local pron = word[i]

		-- Check for gemination at prefix boundaries; if so, convert the
		-- regular gemination symbol ː to a special symbol ˑ that indicates
		-- we always preserve the gemination unless gem=n. We look for
		-- certain sequences at the beginning of a word, but make sure that
		-- the original spelling is appropriate as well (see comment above
		-- for geminate_pref).
		if rfind(pron, 'ː') then -- optimize by only doing when gemination present
			local orig_pron = orig_word[i]
			local deac = rsub(pron, accents, '')
			local orig_deac = rsub(orig_pron, accents, '')
			-- the following two are optimizations to reduce the number of regex
			-- checks in the majority of cases with words not beginning with ne-
			-- or po-.
			local is_ne = rfind(orig_deac, '⁀ne')
			local is_po = rfind(orig_deac, '⁀po')
			for _, gempref in ipairs(geminate_pref) do
				local newspell = gempref[1]
				local oldspell = gempref[2]
				-- FIXME! The rsub below will be incorrect if there is
				-- gemination in a joined preposition or particle
				if rfind(orig_deac, '⁀' .. oldspell) and rfind(deac, '⁀' .. newspell) or
					is_po and rfind(orig_deac, '⁀po' .. oldspell) and rfind(deac, '⁀po' .. newspell) or
					is_ne and rfind(orig_deac, '⁀ne' .. oldspell) and rfind(deac, '⁀ne' .. newspell) or
					is_ne and rfind(orig_deac, '⁀nepo' .. oldspell) and rfind(deac, '⁀nepo' .. newspell) then
					pron = rsub(pron, '(⁀[^‿⁀ː]*)ː', '%1ˑ')
				end
			end
		end

		--degemination, optional gemination
		local thisgem = type(gem) == "table" and gem[i] or gem
		if thisgem == 'y' then
			-- leave geminates alone, convert ˑ to regular gemination; ˑ is a
			-- special gemination symbol used at prefix boundaries that we
			-- remove only when gem=n, else we convert it to regular gemination
			pron = rsub(pron, 'ˑ', 'ː')
		elseif thisgem == 'o' then
			-- make geminates optional, except for ɕӂ, also ignore left paren
			-- in (ː) sequence
			pron = rsub(pron, '([^ɕӂ%(%)])[ːˑ]', '%1(ː)')
		elseif thisgem == 'n' then
			-- remove gemination, except for ɕӂ
			pron = rsub(pron, '([^ɕӂ%(%)])[ːˑ]', '%1')
		else
			-- degeminate l's
			pron = rsub(pron, '(l)ː', '%1')
			-- preserve gemination between vowels immediately after the stress,
			-- special gemination symbol ˑ also remains, ɕӂ remain geminated,
			-- žn remain geminated between vowels even not immediately after
			-- the stress, n becomes optionally geminated when after but not
			-- immediately after the stress, ssk and zsk remain geminated
			-- immediately after the stress, else degeminate; we signal that
			-- gemination should remain by converting to special symbol ˑ,
			-- then removing remaining ː not after ɕӂ and left paren; do
			-- various subs repeatedly in case of multiple geminations in a word
			-- 1. immediately after the stress
			pron = rsub_repeatedly(pron, '(' .. vowels .. stress_accents .. '[^ɕӂ%(%)])ː(' .. vowels .. ')', '%1ˑ%2')
			-- 2. remaining geminate n after the stress between vowels
			pron = rsub_repeatedly(pron, '(' .. stress_accents .. '.-' .. vowels .. accents .. '?n)ː(' .. vowels .. ')', '%1(ː)%2')
			-- 3. remaining ž and n between vowels
			pron = rsub_repeatedly(pron, '(' .. vowels .. accents .. '?[žn])ː(' .. vowels .. ')', '%1ˑ%2')
			-- 4. ž word initially before vowels (жжение, жжём, etc.)
			pron = rsub_repeatedly(pron, '(⁀ž)ː(' .. vowels .. ')', '%1ˑ%2')
			-- 5. ssk (and zsk, already normalized) immediately after the stress
			pron = rsub(pron, '(' .. vowels .. stress_accents .. '[^' .. vow .. ']*s)ː(k)', '%1ˑ%2')
			-- 6. eliminate remaining gemination, except for ɕː and ӂː
			pron = rsub(pron, '([^ɕӂ%(%)])ː', '%1')
			-- 7. convert special gemination symbol ˑ to regular gemination
			pron = rsub(pron, 'ˑ', 'ː')
		end

		-- handle soft and hard signs, assimilative palatalization
		-- 1. insert j before i when required
		pron = rsub(pron, 'ʹi', 'ʹji')
		-- 2. insert glottal stop after hard sign if required
		pron = rsub(pron, 'ʺ([aɛiouy])', 'ʔ%1')
		-- 3. (ь) indicating optional palatalization
		pron = rsub(pron, '%(ʹ%)', '⁽ʲ⁾')
		-- 4. assimilative palatalization of consonants when followed by
		--    front vowels or soft sign
		pron = rsub(pron, '([mnpbtdkgfvszxɣrl' .. PSEUDOCONS ..'])([ː()]*[eiäạëöüʹ])', '%1ʲ%2')
		pron = rsub(pron, '([cĵ])([ː()]*[äạöüʹ])', '%1ʲ%2')
		-- 5. remove hard and soft signs
		pron = rsub(pron, "[ʹʺ]", "")

		-- reduction of unstressed word-final -я, -е; but special-case
		-- unstressed не, же. Final -я always becomes [ə]; final -е may
		-- become [ə], [e], [ɪ] or [ɨ] depending on the part of speech and
		-- the preceding consonants/vowels.
		pron = rsub(pron, '[äạ]⁀', 'ə⁀')
		pron = rsub(pron, '⁀nʲe⁀', '⁀nʲi⁀')
		pron = rsub(pron, '⁀že⁀', '⁀žy⁀')
		-- function to fetch the appropriate value for ending and part of
		-- speech, handling aliases and defaults and converting 'e' to 'ê'
		-- so that the unstressed [e] sound is preserved
		function fetch_e_sub(ending)
			local sub = fetch_pos_property(i, ending)
			if sub == 'e' then
				-- add TEMPCFLEX (which will be converted to CFLEX) to preserve
				-- the unstressed [e] sound, which will otherwise be converted
				-- to [ɪ]; we do this instead of adding CFLEX directly because
				-- we later convert some instances of the resulting 'e' to
				-- 'i', and we don't want to do this when the user explicitly
				-- wrote a Cyrillic е with a circumflex on it. [NOTE that
				-- formerly applied when we added CFLEX directly: DO NOT
				-- use ê here directly because it's a single composed char,
				-- when we need the e and accent to be separate.]
				return 'e' .. TEMPCFLEX
			else
				return sub
			end
		end
		if new_final_e_code then
			-- as requested by Atitarev, final unstressed -ɛ should be unreduced
			pron = rsub(pron, 'ɛ⁀', 'ɛ' .. TEMPCFLEX .. '⁀')
			-- handle substitutions in two parts, one for vowel+j+e sequences
			-- and the other for cons+e sequences
			pron = rsub(pron, vowels_c .. '(' .. accents .. '?j)ë⁀', function(v, ac)
				 local ty = v == 'o' and 'oe' or 've'
				 return v .. ac .. fetch_e_sub(ty) .. '⁀'
			end)
			-- consonant may palatalized, geminated or optional-geminated
			pron = rsub(pron, '(.)(ʲ?[ː()]*)[eë]⁀', function(ch, mod)
				 local ty = ch == 'j' and 'je' or
					rfind(ch, '[cĵšžĉĝ]') and 'hardsib' or
					rfind(ch, '[čǰɕӂ]') and 'softsib' or
					'softpaired'
				 return ch ..mod .. fetch_e_sub(ty) .. '⁀'
			end)
			if final_e_non_pausal then
				-- final [e] should become [ɪ] when not followed by pause or
				-- end of utterance (in other words, followed by space plus
				-- anything but a pause symbol, or followed by tie bar).
				pron = rsub(pron, 'e' .. TEMPCFLEX .. '⁀‿', 'i⁀‿')
				if i < #word and word[i+1] ~= '⁀|⁀' then
					pron = rsub(pron, 'e' .. TEMPCFLEX .. '⁀$', 'i⁀')
				end
			end
			-- now convert TEMPCFLEX to CFLEX; we use TEMPCFLEX so the previous
			-- two regexps won't affect cases where the user explicitly wrote
			-- a circumflex
			pron = rsub(pron, TEMPCFLEX, CFLEX)
		else
			-- Do the old way, which mostly converts final -е to schwa, but
			-- has highly broken retraction code for vowel + [шжц] + е (but
			-- not with accent on vowel!) before it that causes final -е in
			-- this circumstance to become [ɨ], and a special hack for кое-.
			pron = rsub(pron, vowels_c .. '([cĵšžĉĝ][ː()]*)[eë]', '%1%2ɛ')
			pron = rsub(pron, '⁀ko(' .. stress_accents .. ')jë⁀', '⁀ko%1ji⁀')
			pron = rsub(pron, '[eë]⁀', 'ə⁀')
		end

		-- retraction of е and и after цшж
		pron = rsub(pron, '([cĵšžĉĝ][ː()]*)([ei])', function(a, b)
			return a .. retracting[b] end)

		--syllabify, inserting @ at syllable boundaries
		--1. insert @ after each vowel
		pron = rsub(pron, '(' .. vowels .. accents .. '?)', '%1@')
		--2. eliminate word-final @
		pron = rsub(pron, '@+⁀$', '⁀')
		--3. move @ forward directly before any ‿⁀, as long as at least
		--   one consonant follows that; we will move it across ‿⁀ later
		pron = rsub(pron, '@([^@' .. vow .. acc .. ']*)([‿⁀]+[^‿⁀@' .. vow .. acc .. '])', '%1@%2')
		--4. in a consonant cluster, move @ forward so it's before the
		--   last consonant
		pron = rsub(pron, '@([^‿⁀@' .. vow .. acc .. ']*)([^‿⁀@' .. vow .. acc .. 'ːˑ()ʲ]ʲ?[ːˑ()]*‿?[' .. vow .. acc .. '])', '%1@%2')
		--5. move @ backward if in the middle of a "permanent onset" cluster,
		--   e.g. sk, str, that comes before a vowel, putting the @ before
		--   the permanent onset cluster
		pron = rsub(pron, '([^‿⁀@_' .. vow .. acc .. ']?)(_*)([^‿⁀@_' .. vow .. acc .. '])(_*)@([^‿⁀@' .. vow .. acc .. 'ːˑ()ʲ])(ʲ?[ːˑ()]*[‿⁀]*[' .. vow .. acc .. '])', function(a, aund, b, bund, c, d)
			if perm_syl_onset[a .. b .. c] or c == 'j' and rfind(b, '[čǰɕӂʲ]') then
				return '@' .. a .. aund .. b .. bund .. c .. d
			elseif perm_syl_onset[b .. c] then
				return a .. aund .. '@' .. b .. bund .. c .. d
			end end)
		--6. if / is present (explicit syllable boundary), remove any @
		--   (automatic boundary) and convert / to @
		if rfind(pron, '/') then
			pron = rsub(pron, '[^' .. vow .. acc .. ']+', function(x)
				if rfind(x, '/') then
					x = rsub(x, '@', '')
					x = rsub(x, '/', '@')
				end
				return x
			end)
		end
		--7. remove @ followed by a final consonant cluster
		pron = rsub(pron, '@([^‿⁀@' .. vow .. ']+⁀)$', '%1')
		--8. remove @ preceded by an initial consonant cluster (should only
		--   happen when / is inserted by user or in цз, чж sequences)
		pron = rsub(pron, '^(⁀[^‿⁀@' .. vow .. ']+)@', '%1')
		--9. make sure @ isn't directly before linking ‿⁀
		pron = rsub(pron, '@([‿⁀]+)', '%1@')

		-- handle word-initial unstressed o and a; note, vowels always
		-- followed by at least one char because of word-final ⁀
		-- do after syllabification because syllabification doesn't know
		-- about ɐ as a vowel
		pron = rsub(pron, '^⁀[ao]([^' .. acc .. '])', '⁀ɐ%1')

		--split by syllable
		local syllable = rsplit(pron, '@', true)

		--create set of 1-based syllable indexes of stressed syllables
		--(acute, grave, circumflex)
		local stress = {}
		for j = 1, #syllable do
			if rfind(syllable[j], stress_accents) then
				stress[j] = "real"
			elseif rfind(syllable[j], CFLEX) then
				stress[j] = "cflex"
			end
		end

		-- iterate syllable by syllable to handle stress marks, vowel allophony
		local syl_conv = {}
		for j = 1, #syllable do
			local syl = syllable[j]

			local alnum

			--vowel allophony
			if stress[j] then
				-- convert acute/grave/circumflex accent to appropriate
				-- IPA marker of primary/secondary/unmarked stress
				alnum = 1
				syl = rsub(syl, '(.*)́', 'ˈ%1')
				syl = rsub(syl, '(.*)̀', 'ˌ%1')
				syl = rsub(syl, CFLEX, '')
			elseif stress[j+1] == "real" then
				-- special-casing written а immediately before the stress,
				-- but only for primary/secondary stress, not circumflex
				alnum = 2
			else
				alnum = 3
			end
			syl = rsub(syl, vowels_c, function(a)
				if a ~= '' then
					return allophones[a][alnum]
				end end)
			syl_conv[j] = syl
		end

		pron = table.concat(syl_conv, "")

		-- Optional (j) before ɪ, which is always unstressed; not following
		-- consonant across a joined word boundary
		pron = rsub(pron, '([^' .. ipa_vow .. ']⁀‿⁀)jɪ', '%1' .. TEMPSUB .. 'ɪ')
		pron = rsub(pron, '⁀jɪ', '⁀(j)ɪ')
		pron = rsub(pron, '([' .. ipa_vow .. '])jɪ', "%1(j)ɪ")
		pron = rsub(pron, TEMPSUB, 'j')

		--consonant assimilative palatalization of tn/dn/sn/zn, depending on
		--whether [rl] precedes
		pron = rsub(pron, '([rl]?)([ː()ˈˌ]*[dtsz])([ː()ˈˌ]*nʲ)', function(a, b, c)
			if a == '' then
				return a .. b .. 'ʲ' .. c
			else
				return a .. b .. '⁽ʲ⁾' .. c
			end end)

		--consonant assimilative palatalization of st/zd, depending on
		--whether [rl] precedes
		pron = rsub(pron, '([rl]?)([ˈˌ]?[sz])([ː()ˈˌ]*[td]ʲ)', function(a, b, c)
			if a == '' then
				return a .. b .. 'ʲ' .. c
			else
				return a .. b .. '⁽ʲ⁾' .. c
			end end)

		--general consonant assimilative palatalization
		pron = rsub_repeatedly(pron, '([szntdpbmfcĵx])([ː()ˈˌ]*)([szntdpbmfcĵlk]ʲ)', function(a, b, c)
			if cons_assim_palatal['compulsory'][a..c] then
				return a .. 'ʲ' .. b .. c
			elseif cons_assim_palatal['optional'][a..c] then
				return a .. '⁽ʲ⁾' .. b .. c
			else
				return a .. b .. c
			end end)

		-- further assimilation before alveolopalatals
		pron = rsub(pron, 'n([ː()ˈˌ]*)([čǰɕӂ])', 'nʲ%1%2')

		-- optional palatal assimilation of вп, вб only word-initially
		pron = rsub(pron, '⁀([ː()ˈˌ]*[fv])([ː()ˈˌ]*[pb]ʲ)', '⁀%1⁽ʲ⁾%2')

		-- optional palatal assimilation of бв but not in обв-
		pron = rsub(pron, 'b([ː()ˈˌ]*vʲ)', 'b⁽ʲ⁾%1')
		if rfind(word[i], '⁀o' .. accents .. '?bv') then
			-- ə in case of a word with a preceding preposition
			pron = rsub(pron, '⁀([ː()ˈˌ]*[ɐəo][ː()ˈˌ]*)b⁽ʲ⁾([ː()ˈˌ]*vʲ)', '⁀%1b%2')
		end

		-- palatalized labials before /j/ should be optionally palatalized
		pron = rsub(pron, '([mpbfv])ʲ([ːˈˌ]*j)', '%1⁽ʲ⁾%2')

		-- Word-final -лся (normally in past verb forms) should have optional
		-- palatalization. Need to rewrite as -лсьа to defeat this.
		-- FIXME: Should we move this to phonetic_subs?
		if rfind(word[i], 'ls[äạ]⁀') then
			pron = rsub(pron, 'lsʲə⁀', 'ls⁽ʲ⁾ə⁀')
		end

		word[i] = pron
	end

	text = table.concat(word, " ")
	if bracket then
		text = '[' .. text .. ']'
	end

	-- Front a and u between soft consonants. If between a soft and
	-- optionally soft consonant (should only occur in that order, shouldn't
	-- ever have a or u preceded by optionally soft consonant),
	-- split the result into two. We only split into two even if there
	-- happen to be multiple optionally fronted a's and u's to avoid
	-- excessive numbers of possibilities (and it simplifies the code).
	-- 1. First, temporarily add soft symbol to inherently soft consonants.
	text = rsub(text, '([čǰɕӂj])', '%1ʲ')
	-- 2. Handle case of [au] between two soft consonants
	text = rsub_repeatedly(text, '(ʲ[ː()]*)([auʊ])([ˈˌ]?.ʲ)', function(a, b, c)
		return a .. fronting[b] .. c end)
	-- 3. Handle [au] between soft consonant and optional j, which is still fronted
	text = rsub_repeatedly(text, '(ʲ[ː()]*)([auʊ])([ˈˌ]?%(jʲ%))', function(a, b, c)
			return a .. fronting[b] .. c end)
	-- 4. Handle case of [au] between soft and optionally soft consonant
	if rfind(text, 'ʲ[ː()]*[auʊ][ˈˌ]?.⁽ʲ⁾') then
		local opt_hard = rsub(text, '(ʲ[ː()]*)([auʊ])([ˈˌ]?.)⁽ʲ⁾', '%1%2%3')
		local opt_soft = rsub(text, '(ʲ[ː()]*)([auʊ])([ˈˌ]?.)⁽ʲ⁾', function(a, b, c)
			return a .. fronting[b] .. c .. 'ʲ' end)
		text = { opt_hard, opt_soft }
	else
		text = { text }
	end

	for i, pronunciation in ipairs(text) do
		-- 5. Undo addition of soft symbol to inherently soft consonants.
		pronunciation = rsub(pronunciation, '([čǰɕӂj])ʲ', '%1')

		-- convert special symbols to IPA
		pronunciation = rsub(pronunciation, '[cĵ]ʲ', translit_conv_j)
		pronunciation = rsub(pronunciation, '[cčgĉĝĵǰšžɕӂ]', translit_conv)

		-- Assimilation involving hiatus of ɐ and ə
		pronunciation = rsub(pronunciation, 'ə([‿⁀]*)[ɐə]', 'ɐ%1ɐ')

		-- Use ɫ for dark l
		pronunciation = rsub(pronunciation, 'l([^ʲ])', 'ɫ%1')

		-- eliminate ⁀ symbol at word boundaries
		-- eliminate _ symbol that prevents assimilations
		-- eliminate pseudoconsonant at beginning of suffixes or end of prefixes
		text[i] = rsub(pronunciation, '[⁀_' .. PSEUDOCONS ..']', '')
	end

	return text
end

-- Return the actual IPA corresponding to Cyrillic text as a single string.
-- This is a wrapper around export.ipa(), which returns a list; if that
-- function returns more than one item, they are separated by ", ".
function export.ipa_string(text, adj, gem, bracket, pos, zhpal, is_transformed)
	local ipa_list = export.ipa(text, adj, gem, bracket, pos, zhpal, is_transformed)
	return table.concat(ipa_list, ", ")
end
print(export.ipa_string("счастливым счастье сч"))
return export