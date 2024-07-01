--[=[

Author: Benwing, rewritten from original by Kc kennylau

Generates French IPA from spelling. Implements template {{fr-IPA}}; also
used in [[Module:fr-verb]] (particularly [[Module:fr-verb/pron]], the submodule
handling pronunciation of verbs).

--]=]
require('mw')
local export = {}

local str_gsub = string.gsub

local u = mw.ustring.char
local rfind = mw.ustring.find
local rsubn = mw.ustring.gsub
local rmatch = mw.ustring.match
local rsplit = mw.text.split
local ulower = mw.ustring.lower
local uupper = mw.ustring.upper
local usub = mw.ustring.sub
local ulen = mw.ustring.len

local TILDE = u(0x0303) -- tilde =  ̃

local EXPLICIT_H = u(0xFFF0)
local EXPLICIT_X = u(0xFFF1)
local EXPLICIT_J = u(0xFFF2)

local explicit_sound_to_substitution = {
	["h"] = EXPLICIT_H,
	["x"] = EXPLICIT_X,
	["j"] = EXPLICIT_J,
}

local explicit_substitution_to_sound = {}
local explicit_substitution_regex = {}
for from, to in pairs(explicit_sound_to_substitution) do
	explicit_substitution_to_sound[to] = from
	table.insert(explicit_substitution_regex, to)
end
explicit_substitution_regex = "[" .. table.concat(explicit_substitution_regex) .. "]"

-- If enabled, compare this module with new version of module in
-- [[Module:User:Benwing2/fr-pron]] to make sure all pronunciations are the same.
-- To check for differences, go to [[Template:tracking/fr-pron/different-pron]]
-- and look at what links to the page.
local test_new_fr_pron_module = false

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

local function ine(x)
	if x == "" then return nil else return x end
end

local function track(page)
	local m_debug = require("debug").track("fr-pron/" .. page)
	return true
end

-- pairs of consonants where a schwa between them cannot be deleted in VCəCV
-- within a word
local no_delete_schwa_in_vcvcv_word_internally_list = {
	'ʁʁ', 'ɲʁ', 'ɲl'
}
-- generate set
local no_delete_schwa_in_vcvcv_word_internally = {}
for _, x in ipairs(no_delete_schwa_in_vcvcv_word_internally_list) do
	no_delete_schwa_in_vcvcv_word_internally[x] = true
end

-- pairs of consonants where a schwa between them cannot be deleted in VCəVC
-- across a word boundary; primarily, consonants that are the same except
-- possibly for voicing
local no_delete_schwa_in_vcvcv_across_words_list = {
	'kɡ', 'ɡk', 'kk', 'ɡɡ', -- WARNING: IPA ɡ used here
	'td', 'dt', 'tt', 'dd',
	'bp', 'pb', 'pp', 'bb',
	'ʃʒ', 'ʒʃ', 'ʃʃ', 'ʒʒ',
	'fv', 'vf', 'ff', 'vv',
	'sz', 'zs', 'ss', 'zz',
	'jj', 'ww', 'ʁʁ', 'll', 'nn', 'ɲɲ', 'mm'
	-- FIXME, should be others
}
-- generate set
local no_delete_schwa_in_vcvcv_across_words = {}
for _, x in ipairs(no_delete_schwa_in_vcvcv_across_words_list) do
	no_delete_schwa_in_vcvcv_across_words[x] = true
end

local remove_diaeresis_from_vowel =
	{['ä']='a', ['ë']='e', ['ï']='i', ['ö']='o', ['ü']='u', ['ÿ']='i'}

-- True if C1 and C2 form an allowable onset (in which case we always
-- attempt to place them after the syllable break)
local function allow_onset_2(c1, c2)
	-- WARNING: Both IPA and non-IPA g below, and both r and ʁ, because it is
	-- called both before and after the substitutions of these chars.
	return (c2 == "l" or c2 == "r" or c2 == "ʁ") and rmatch(c1, "[bkdfgɡpstv]") or
		c1 == "d" and c2 == "ʒ" or
		c1 ~= "j" and (c2 == "j" or c2 == "w" or c2 == "W" or c2 == "ɥ")
end

-- list of vowels, including both input Latin and output IPA; note that
-- IPA nasal vowels are two-character sequences with a combining tilde,
-- which we include as the last char
local oral_vowel_no_schwa_no_i = "aeouAEOUéàèùâêôûäëöüăŏŭɑɛɔæœø"
local oral_vowel_schwa = "əƏĕė"
local oral_vowel_i = "iyIYîŷïÿ"
local oral_vowel = oral_vowel_no_schwa_no_i .. oral_vowel_schwa .. oral_vowel_i
local nasal_vowel = TILDE
local non_nasal_c = "[^" .. TILDE .. "]"
local vowel_no_schwa = oral_vowel_no_schwa_no_i .. oral_vowel_i .. nasal_vowel
local vowel = oral_vowel .. nasal_vowel
local vowel_c = "[" .. vowel .. "]"
local vowel_no_schwa_c = "[" .. vowel_no_schwa .. "]"
local vowel_maybe_nasal_r = "[" .. oral_vowel .. "]" .. TILDE .. "?"
local non_vowel_c = "[^" .. vowel .. "]"
local oral_vowel_c = "[" .. oral_vowel .. "]"
-- FIXME: Previously vowel_no_i specified the vowels explicitly and didn't include the nasal combining diacritic;
-- should we include it?
local vowel_no_i = oral_vowel_no_schwa_no_i .. oral_vowel_schwa
local vowel_no_i_c = "[" .. vowel_no_i .. "]"
-- special characters that should be carried through but largely ignored when
-- syllabifying; single quote prevents interpretation of sequences,
-- ‿ indicates liaison, ⁀ is a word boundary marker, - is a literal hyphen
-- (we include word boundary markers because they mark word boundaries with
-- words joined by hyphens, but should be ignored for syllabification in
-- such a case), parens are used to explicitly indicate an optional sound, esp.
-- a schwa
local syljoiner_c = "[_'‿⁀%-()]" -- don't include syllable marker or space
local opt_syljoiners_c = syljoiner_c .. "*"
local schwajoiner_c = "[_'‿⁀%-. ]" -- also include . and space but not ()
local opt_schwajoiners_c = schwajoiner_c .. "*"
local cons_c = "[^" .. vowel .. ".⁀ %-]" -- includes underscore, quote and liaison marker
local cons_no_liaison_c = "[^" .. vowel .. ".⁀‿ %-]" -- includes underscore and quote but not liaison marker
local real_cons_c = "[^" .. vowel .. "_'‿.⁀ %-()]" -- excludes underscore, quote and liaison marker
local cons_or_joiner_c = "[^" .. vowel .. ". ]" -- includes all joiners
local front_vowel = "eiîéèêĕėəɛæœyŷ" -- should not include capital E, used in cœur etc.
local front_vowel_c = "[" .. front_vowel .. "]"
local word_begin = "'‿⁀%-" -- characters indicating the beginning of a word
local word_begin_c = "[" .. word_begin .. "]"

-- Actual implementation of [[Template:fr-IPA]], compatible in spirit with
-- [[Template:IPA]].
function export.fr_IPA(frame)
	local params = {
		[1] = {list = true, allow_holes = true},
		["n"] = {list = true, allow_holes = true},
		["qual"] = {list = true, allow_holes = true},
		["noalternatives"] = {type = "boolean"},
		["noalt"] = {alias_of = "noalternatives"},
		["pos"] = {},
		["pagename"] = {},
	}

	local err = nil
	local args = require("parameters").process(frame:getParent().args, params)

	local items = {}

	local has_refs_or_quals = args.n.maxindex > 0 or args.qual.maxindex > 0

	if has_refs_or_quals then
		local default_prons
		-- If there are references or qualifiers, don't remove duplicates; it gets harder to handle duplicates properly
		-- in the presence of references or qualifiers, and it may in any case be wrong.
		for i = 1, math.max(args[1].maxindex, args.n.maxindex, 1) do
			local prons = export.show(args[1][i], args.pos, args.noalternatives, args.pagename)
			for _, pron in ipairs(prons) do
				local note = args.n[i]
				local qual = args.qual[i]
				table.insert(items, {pron = "/" .. pron .. "/", note = note, qualifiers = {qual}})
			end

			-- Check whether explicitly given pronunciations are redundant.
			if args[1][i] and args[1][i] ~= "+" then
				default_prons = default_prons or export.show(nil, args.pos, args.noalternatives, args.pagename, "no test new module")
				for _, default_pron in ipairs(default_prons) do
					if require("table").contains(prons, default_pron) then
						track("redundant-pron")
					else
						track("needed-pron")
					end
				end
			end
		end
	else
		local all_prons
		for i = 1, math.max(args[1].maxindex, 1) do
			local prons = export.show(args[1][i], args.pos, args.noalternatives, args.pagename)
			if not all_prons then
				all_prons = prons
			else
				for _, pron in ipairs(prons) do
					require("table").insertIfNot(all_prons, pron)
				end
			end
		end
		for _, pron in ipairs(all_prons) do
			table.insert(items, {pron = "/" .. pron .. "/"})
		end

		-- Check whether explicitly given pronunciations are redundant.
		for i = 1, args[1].maxindex do
			if args[1][i] and args[1][i] ~= "+" then
				local default_prons = export.show(nil, args.pos, args.noalternatives, args.pagename, "no test new module")
				for _, default_pron in ipairs(default_prons) do
					if require("table").contains(all_prons, default_pron) then
						track("redundant-pron")
					else
						track("needed-pron")
					end
				end
			end
		end
	end

	local lang = require("languages").getByCode("fr")
	return require("IPA").format_IPA_full(lang, items, err)
end


function export.canonicalize_pron(text, pagename)
	if not text or text == "+" then
		text = pagename
	end

	text = rsub(text, "%[([hHxXjJ])%]", function(sound)
		return explicit_sound_to_substitution[ulower(sound)]
	end)

	if rfind(text, "^%[.*%]$") then
		local subs = rsplit(rmatch(text, "^%[(.*)%]$"), ",")
		text = pagename
		for _, sub in ipairs(subs) do
			local fromto = rsplit(sub, ":")
			if #fromto ~= 2 then
				error("Bad substitution spec " .. sub .. " in {{fr-IPA}}")
			end
			local from, to = fromto[1], fromto[2]
			if rfind(from, "^~") then
				-- formerly, ~ was required to match within a word
				from = rmatch(from, "^~(.*)$")
			end
			local newtext = text
			if rfind(from, "^%^") then
				-- whole-word match
				from = rmatch(from, "^%^(.*)$")
				newtext = rsub(text, "%f[%a]" .. require("string/pattern escape")(from) .. "%f[%A]", to)
			else
				newtext = rsub(text, require("string/pattern escape")(from), to)
			end
			if newtext == text then
				error("Substitution spec " .. sub .. " didn't match respelling '" .. text .. "'")
			end
			text = newtext
		end
	end

	text = ulower(text)
	return text
end


function export.show(text, pos, noalternatives, pagename, no_test_new_module)
	-- check_new_module=1 can be passed from a bot to compare to the new
	-- module. In that case, if there's a difference, the return value will
	-- be a string "OLD_RESULT || NEW_RESULT".
	--
	-- no_test_new_module can be passed from module code to disable the
	-- new-module check. This is used when checking for redundant pronunciation
	-- to avoid excess triggering of the [[Template:tracking/fr-pron/different-pron]]
	-- page.
	local check_new_module
	if type(text) == "table" then
		pos = ine(text.args.pos)
		noalternatives = ine(text.args.noalternatives)
		pagename = ine(text.args.pagename)
		check_new_module = ine(text.args.check_new_module)
		text = ine(text.args[1])
	end

	local new_module_result
	-- Test code to compare existing module to new one.
	if (test_new_fr_pron_module or check_new_module) and not no_test_new_module then
		local m_new_fr_pron = require("User:Benwing2/fr-pron")
		new_module_result = m_new_fr_pron.show(text, pos, noalternatives, pagename)
	end

	pagename = pagename or "title" or mw.title.getCurrentTitle().text

	text = export.canonicalize_pron(text, pagename)


	-- To simplify checking for word boundaries and liaison markers, we
	-- add ⁀ at the beginning and end of all words, and remove it at the end.
	-- Note that the liaison marker is ‿.
	text = rsub(text, "%s*,%s*", '⁀⁀ | ⁀⁀')
	text = rsub(text, "%s+", '⁀ ⁀')
	text = rsub(text, "%-+", '⁀-⁀')
	text = '⁀⁀' .. text .. '⁀⁀'

	-- various early substitutions
	text = str_gsub(text, 'ǝ', 'ə') -- replace wrong schwa with same-looking correct one
	text = str_gsub(text, 'œu', 'Eu') -- capital E so it doesn't trigger c -> s
	text = str_gsub(text, 'oeu', 'Eu')
	text = str_gsub(text, 'œil', 'Euil')
	text = str_gsub(text, 'œ', 'æ') -- keep as æ, mapping later to è or é

	-- Handle soft c, g. Do these near the very beginning before any changes
	-- that disturb the orthographic front/back vowel distinction (e.g.
	-- -ai -> -é when pos == "v" in the next section); but after special
	-- handling of œu (which should not trigger softening, as in cœur), whereas
	-- other occurrences of œ do trigger softening (cœliaque).
	text = rsub(text, "c('?" .. front_vowel_c .. ')', 'ç%1')
	text = rsub(text, 'ge([aoAOàâôäöăŏɔ])', 'j%1')
	text = rsub(text, 'g(' .. front_vowel_c .. ')', 'j%1')

	if pos == "v" then
		-- special-case for verbs
		text = rsub(text, 'ai⁀', 'é⁀')
		-- portions, retiens as verbs should not have /s/
		text = rsub(text, 'ti([oe])ns([⁀‿])', "t_i%1ns%2")
		-- retienne, retiennent as verbs should not have /s/
		text = rsub(text, 't(ienne[⁀‿])', "t_%1")
		text = rsub(text, 't(iennent[⁀‿])', "t_%1")
		-- final -ent is silent except in single-syllable words (ment, sent);
		-- vient, tient, and compounds will have to be special-cased, no easy
		-- way to distinguish e.g. initient (silent) from retient (not silent).
		text = rsub(text, '(' .. vowel_c .. cons_no_liaison_c .. '*' .. ')ent⁀', '%1e⁀')
		text = rsub(text, '(' .. vowel_c .. cons_no_liaison_c .. '*' .. ')ent‿', '%1ət‿')
	end

	-- various early substitutions #2
	text = rsub(text, '[aä]([sz][⁀‿])', 'â%1') -- pas, gaz
	text = str_gsub(text, 'à', 'a')
	text = str_gsub(text, 'ù', 'u')
	text = str_gsub(text, 'î', 'i')
	text = str_gsub(text, '[Ee]û', 'ø')
	text = str_gsub(text, 'û', 'u')
	-- absolute, obstacle, subsumer, obtus, obtenir, etc.; but not toubibs
	text = str_gsub(text, 'b([st][^⁀‿])', 'p%1')
	text = str_gsub(text, 'ph', 'f')
	text = str_gsub(text, 'gn', 'ɲ')
	text = str_gsub(text, 'compt', 'cont')
	text = str_gsub(text, 'psych', 'psik')
	-- -chrom-, -chron-, chrétien, etc.; -chlor-, etc.; -techn-, arachn-, etc.; use 'sh' to get /ʃ/
	text = str_gsub(text, 'ch([rln])', 'c%1')
	-- dinosaure, taure, restaurant, etc.; in unstressed syllables both /ɔ/ and /o/ are usually possible,
	-- but /ɔ/ is more common/natural; not in -eaur-, which occurs in compounds e.g. [[Beauregard]]
	text = str_gsub(text, '([^e])aur', '%1or')
	text = rsub(text, '(' .. word_begin_c .. ')désh', '%1déz')
	text = rsub(text, '(' .. word_begin_c .. ')et([⁀‿])', '%1é%2')
	text = rsub(text, '(' .. word_begin_c .. ')es([⁀‿])', '%1ès%2')
	text = rsub(text, '(' .. word_begin_c .. ')est([⁀‿])', '%1èt%2')
	text = rsub(text, '(' .. word_begin_c .. ')ress', '%1rəss') -- ressortir, etc. should have schwa
	text = rsub(text, '(' .. word_begin_c .. ')intrans(' .. vowel_c .. ')', '%1intranz%2')
	text = rsub(text, '(' .. word_begin_c .. ')trans(' .. vowel_c .. ')', '%1tranz%2')
	text = rsub(text, '(' .. word_begin_c .. ')eu', '%1ø') -- even in euro-
	text = rsub(text, '(' .. word_begin_c .. ')neur', '%1nør') -- neuro-, neuralgie, etc.
	 -- hyperactif, etc.; without this we get /i.pʁak.tif/ etc.
	text = rsub(text, '(' .. word_begin_c .. ')hyper', '%1hypèr')
	 -- superessif, etc.; without this we get /sy.pʁɛ.sif/ etc.
	text = rsub(text, '(' .. word_begin_c .. ')super', '%1supèr')
	-- adverbial -emment is pronounced -amment
	text = rsub(text, 'emment([⁀‿])', 'amment%1') 
	text = rsub(text, 'ie(ds?[⁀‿])', 'ié%1') -- pied, assieds, etc.
	text = rsub(text, '[eæ]([dgpt]s?[⁀‿])', 'è%1') -- permet
	text = rsub(text, 'ez([⁀‿])', 'éz%1') -- assez, avez, etc.
	text = str_gsub(text, 'er‿', 'èr‿') -- premier étage
	text = rsub(text, '([⁀‿]' .. cons_c .. '*)er(s?[⁀‿])', '%1èr%2') -- cher, fer, vers
	text = rsub(text, 'er(s?[⁀‿])', 'ér%1') -- premier(s)
	text = rsub(text, '(' .. word_begin_c .. cons_c .. '*)e(s[⁀‿])', '%1é%2') -- ses, tes, etc.
	text = str_gsub(text, 'oien', 'oyen') -- iroquoien
	-- bien, européens, païen, moyen; only word finally or before final s
	-- (possibly in liaison); doesn't apply to influence, omniscient, réengager,
	-- etc.; cases where -ien- is [jɛ̃] elsewhere in the word require respelling 
	-- using 'iain' or 'ien-', e.g. 'tient', 'viendra', 'bientôt', 'Vientiane'
	text = rsub(text, '([iïéy])en(s?[⁀‿])', '%1ɛn%2')
	-- special-case for words beginning with bien- (bientôt, bienvenu, bienheureux, etc.)
	text = rsub(text, '(' .. word_begin_c .. ')bien', '%1biɛn')

	--s, c, g, j, q (soft c/g handled above; ç handled below after dropping
	-- silent -s; x handled below)
	text = str_gsub(text, 'cueil', 'keuil') -- accueil, etc.
	text = str_gsub(text, 'gueil', 'gueuil') -- orgueil
	text = rsub(text, '(' .. vowel_c .. ')s(' .. vowel_c .. ')', '%1z%2')
	text = str_gsub(text, "qu'", "k'") -- qu'on
	text = rsub(text, 'qu(' .. vowel_c .. ')', 'k%1')

	-- gu+vowel -> g+vowel, but gu+vowel+diaeresis -> gu+vowel
	text = rsub(text, 'gu(' .. vowel_c .. ')', function(vowel)
		local undo_diaeresis = remove_diaeresis_from_vowel[vowel]
		return undo_diaeresis and 'gu' .. undo_diaeresis or 'g' .. vowel
		end)
	text = str_gsub(text, 'gü', 'gu') -- aiguë might be spelled aigüe
	-- parking, footing etc.; also -ing_ e.g. swinguer respelled swing_guer,
	-- Washington respelled Washing'tonne
	text = rsub(text, '(' .. cons_c .. ")ing(s?[_'⁀‿])", "%1iŋ%2")
	text = str_gsub(text, 'ngt', 'nt') -- vingt, longtemps
	text = str_gsub(text, 'j', 'ʒ')
	text = str_gsub(text, 's?[cs]h', 'ʃ')
	text = str_gsub(text, '[cq]', 'k')
	-- following two must follow s -> z between vowels
	text = rsub(text, '([^sçx⁀])ti([oeɛ])n', '%1si%2n') -- tion, tien
	text = rsub(text, '([^sçx⁀])ti([ae])l', '%1si%2l') -- tial, tiel

	-- special hack for uï; must follow guï handling and precede ill handling
	text = str_gsub(text, 'uï', 'ui') -- ouir, etc.

	-- special hack for oel, oil, oêl; must follow intervocal s -> z and
	-- ge + o -> j, and precede -il- handling
	text = rsub(text, 'o[eê]l', 'wAl') -- moelle, poêle
	-- poil but don't affect -oill- (otherwise interpreted as /ɔj/)
	text = str_gsub(text, 'oil([^l])', 'wAl%1')

	-- ill, il; must follow j -> ʒ above
	-- NOTE: In all of the following, we purposely do not check for a vowel
	-- following -ill-, so that respellings can use it before a consonant
	-- (e.g. [[boycotter]] respelled 'boillcotter')
	-- (1) special-casing for C+uill (juillet, cuillère, aiguille respelled
	--     aiguïlle)
	text = rsub_repeatedly(text, '(' .. cons_c .. ')uill', '%1ɥij')
	-- (2) -ill- after a vowel; repeat if necessary in case of VillVill
	--     sequence (ailloille respelling of ayoye)
	text = rsub_repeatedly(text, '(' .. vowel_c .. ')ill', '%1j')
	-- (3) any other ill, except word-initially (illustrer etc.)
	text = rsub(text, '([^⁀])ill', '%1ij')
	-- (4) final -il after a vowel; we consider final -Cil to contain a
	--     pronounced /l/ (e.g. 'il', 'fil', 'avril', 'exil', 'volatil', 'profil')
	text = rsub(text, '(' .. vowel_c .. ')il([⁀‿])', '%1j%2')
	-- (5) -il- after a vowel, before a consonant (not totally necessary;
	--     unlikely to occur normally, respelling can use -ill-)
	text = rsub(text, '(' .. vowel_c .. ')il(' .. cons_c .. ')', '%1j%2')

	-- y; include before removing final -e so we can distinguish -ay from
	-- -aye
	text = rsub(text, 'ay([⁀‿])', 'ai%1') -- Gamay
	text = str_gsub(text, 'éy', 'éj') -- used in respellings, eqv. to 'éill'
	text = rsub(text, '(' .. vowel_no_i_c .. ')y', '%1iy')
	text = rsub(text, 'yi([' .. vowel .. '.])', 'y.y%1')
	text = str_gsub(text, "'y‿", "'j‿") -- il n'y‿a
	text = rsub_repeatedly(text, '(' .. cons_c .. ')y(' .. cons_c .. ')', '%1i%2')
	text = rsub(text, '(' .. cons_c .. ')ye?([⁀‿])', '%1i%2')
	text = rsub(text, '(' .. word_begin_c .. ')y(' .. cons_c .. ')', '%1i%2')
	text = str_gsub(text, '⁀y⁀', '⁀i⁀')
	-- CyV -> CiV; will later be converted back to /j/ in most cases, but
	-- allows correct handling of embryon, dryade, cryolithe, glyoxylique, etc.
	text = rsub(text, '(' .. cons_c .. ')y(' .. vowel_c .. ')', '%1i%2')
	text = str_gsub(text, 'y', 'j')

	-- nasal hacks
	 -- make 'n' before liaison in certain cases both nasal and pronounced
	text = rsub(text, '(' .. word_begin_c .. '[mts]?on)‿', '%1N‿') --mon, son, ton, on
	text = str_gsub(text, "('on)‿", '%1N‿') --qu'on, l'on
	text = str_gsub(text, '([eɛu]n)‿', '%1N‿') --en, bien, un, chacun etc.
	-- in bon, certain etc. the preceding vowel isn't nasal
	text = str_gsub(text, 'n‿', "N‿")

	-- other liaison hacks
	text = str_gsub(text, 'd‿', 't‿') -- grand arbre, pied-à-terre
	text = str_gsub(text, '[sx]‿', 'z‿') -- vis-a-vis, beaux-arts, premiers enfants, etc.
	text = str_gsub(text, 'f‿', 'v‿') -- neuf ans, etc.
	-- treat liaison consonants that would be dropped as if they are extra-word,
	-- so that preceding "word-final" letters are still dropped and preceding
	-- vowels take on word-final qualities
	text = str_gsub(text, '([bdgkpstxz]‿)', '⁀%1')
	text = str_gsub(text, 'i‿', 'ij‿') -- y a-t-il, gentil enfant

	--silent letters
	-- do this first so we also drop preceding letters if needed
	text = str_gsub(text, '[sz]⁀', '⁀')
	-- final -x silent in prix, chevaux, eux (with eu -> ø above)
	text = str_gsub(text, '([iuø])x⁀', '%1⁀')
	-- silence -c and -ct in nc(t), but not otherwise
	text = str_gsub(text, 'nkt?⁀', 'n⁀')
	text = str_gsub(text, '([ks])t⁀', '%1T⁀') -- final -kt, -st pronounced
	text = str_gsub(text, 'ér⁀', 'é⁀') -- premier, converted earlier to premiér
	-- p in -mp, b in -mb will be dropped, but temporarily convert to capital
	-- letter so a trace remains below when we handle nasals
	text = str_gsub(text, 'm([bp])⁀', function(bp)
		local capbp = {b='B', p='P'}
		return 'm' .. capbp[bp] .. '⁀'
	end) -- plomb
	-- do the following after dropping r so we don't affect -rt
	text = str_gsub(text, '[dgpt]⁀', '⁀')
	-- remove final -e in various circumstances; leave primarily when
	-- preceded by two or more distinct consonants; in V[mn]e and Vmme/Vnne,
	-- use [MN] so they're pronounced in full
	text = rsub(text, '(' .. vowel_c .. ')n+e([⁀‿])', '%1N%2')
	text = rsub(text, '(' .. vowel_c .. ')m+e([⁀‿])', '%1M%2')
	text = rsub(text, '(' .. cons_c .. ')%1e([⁀‿])', '%1%2')
	text = rsub(text, '([mn]' .. cons_c .. ')e([⁀‿])', '%1%2')
	text = rsub(text, '(' .. vowel_c .. cons_c .. '?)e([⁀‿])', '%1%2')

	-- ç; must follow s -> z between vowels (above); do after dropping final s
	-- so that ç can be used in respelling to force a pronounced s
	text = str_gsub(text, 'ç', 's')

	-- x; (h)ex- at beginning of word (examen, exister, hexane, etc.) and after
	-- a vowel (coexister, réexaminer) and after in- (inexact, inexorable) is
	-- pronounced [egz], x- at beginning of word also pronounced [gz], all-
	-- other x's pronounced [ks] (including -ex- in lexical, sexy, perplexité,
	-- etc.).
	text = rsub(text, '([' .. word_begin .. vowel .. ']h?)[eæ]x(h?' .. vowel_c .. ')', '%1egz%2')
	text = rsub(text, '(' .. word_begin_c .. 'in)[eæ]xh?(h?' .. vowel_c .. ')', '%1egz%2')
	text = rsub(text, '(' .. word_begin_c .. ')x', '%1gz')
	text = str_gsub(text, 'x', 'ks')

	-- double consonants: eCC treated specially, then CC -> C; do after
	-- x -> ks so we handle exciter correctly
	text = rsub(text, '(' .. word_begin_c .. ')e([mn])%2(' .. vowel_c .. ')', '%1en_%2%3') -- emmener, ennui
	text = rsub(text, '(' .. word_begin_c .. ')(h?)[eæ](' .. cons_c .. ')%3', '%1%2é%3') -- effacer, essui, errer, henné
	text = rsub(text, '(' .. word_begin_c .. ')dess', '%1déss') -- dessécher, dessein, etc.
	text = rsub(text, '[eæ](' .. cons_c .. ')%1', 'è%1') -- mett(r)ons, etc.
	text = rsub(text, '(' .. cons_c .. ')%1', '%1')

	--diphthongs
	--uppercase is used to avoid the output of one change becoming the input
	--to another; we later lowercase the vowels; î and û converted early;
	--we do this before i/u/ou before vowel -> glide (for e.g. bleuet),
	--and before nasal handling because e.g. ou before n is not converted
	--into a nasal vowel (Bouroundi, Cameroun); au probably too, but there
	--may not be any such words
	text = str_gsub(text, 'ou', 'U')
	text = str_gsub(text, 'e?au', 'O')
	text = str_gsub(text, '[Ee]u([zt])', 'ø%1')
	text = rsub(text, '[Ee]uh?([⁀‿])', 'ø%1') -- (s)chleuh has /ø/
	text = rsub(text, '[Ee][uŭ]', 'œ')
	text = str_gsub(text, '[ae]i', 'ɛ')

	-- Before implementing nasal vowels, convert nh to n to correctly handle
	-- inhérent, anhédonie, bonheur, etc. But preserve enh- to handle
	-- enhardir, enharnacher, enhaché, enhoncher, enhotter, enhucher (all
	-- with "aspirate h"). Words with "mute h" need respelling with enn-, e.g.
	-- enharmonie, enherber.
	text = rsub(text, '(' .. word_begin_c .. ')enh', '%1en_h')
	text = str_gsub(text, 'nh', 'n')

	-- Nasalize vowel + n, m
	-- Do before syllabification so we syllabify quatre-vingt-un correctly.
	-- We affect (1) n before non-vowel, (2) m before b/p/f (including B/P,
	-- which indicate original b/p that are slated to be deleted in words like
	-- plomb, champs; f predominantly from original ph, as in symphonie,
	-- emphatiser; perhaps we should distinguish original ph from original f,
	-- as in occasional words such as Zemfira), (3) -om (nom, dom, pronom,
	-- condom, etc.) and (4) -aim/-eim (faim, Reims etc.), (4). We leave alone
	-- other m's, including most final m. We do this after diphthongization,
	-- which arguably simplifies things somewhat; but we need to handle the
	-- 'oi' diphthong down below so we don't run into problems with the 'noi'
	-- sequence (otherwise we'd map 'oi' to 'wa' and then nasalize the n
	-- because it no longer precedes a vowel).
	text = rsub_repeatedly(text, '(.)(' .. vowel_c .. ')([mn])(' .. non_vowel_c .. ')',
		function(v1, v2, mn, c)
			if mn == 'n' or rfind(c, '[bpBPf]') or (v2 == 'o' or v2 == 'ɛ') and c == '⁀' then
				local nasaltab = {['a']='ɑ̃', ['ä']='ɑ̃', ['e']='ɑ̃', ['ë']='ɑ̃',
					['ɛ']='ɛ̃', ['i']='ɛ̃', ['ï'] = 'ɛ̃', ['o']='ɔ̃', ['ö']='ɔ̃',
					['ø']='œ̃', ['œ']='œ̃', ['u']='œ̃', ['ü']='œ̃'} -- à jeun
				if v1 == 'o' and v2 == 'i' then
					return 'wɛ̃' .. c -- coin, point
				elseif nasaltab[v2] then
					return v1 .. nasaltab[v2] .. c
				end
			end
			return v1 .. v2 .. mn .. c
		end)
	-- special hack for maximum, aquarium, circumlunaire, etc.
	text = rsub(text, 'um(' .. non_vowel_c .. ')', 'ɔm%1')
	-- now remove BP that represent original b/p to be deleted, which we've
	-- preserved so far so that we know that preceding m can be nasalized in
	-- words like plomb, champs
	text = str_gsub(text, '[BP]', '')

	-- do after nasal handling so 'chinois' works correctly
	text = str_gsub(text, 'oi', 'wA')

	-- Remove silent h (but keep as _ after i/u to prevent glide conversion in
	-- nihilisme, jihad, etc.; don't do this after original ou, as souhaite is
	-- pronounced /swɛt/).
	-- Do after diphthongs to keep vowels apart as in envahir, but do
	-- before syllabification so it is ignored in words like hémorrhagie.
	text = str_gsub(text, '([iu])h', '%1_')
	text = str_gsub(text, 'h', '')

	--syllabify
	-- (1) break up VCV as V.CV, and VV as V.V; repeat to handle successive
	--     syllables
	text = rsub_repeatedly(text, "(" .. vowel_maybe_nasal_r .. opt_syljoiners_c .. ")(" .. real_cons_c .. "?" .. opt_syljoiners_c .. oral_vowel_c .. ')', '%1.%2')
	-- (2) break up other VCCCV as VC.CCV, and VCCV as VC.CV; repeat to handle successive syllables
	text = rsub_repeatedly(text, "(" .. vowel_maybe_nasal_r .. opt_syljoiners_c .. real_cons_c .. opt_syljoiners_c .. ")(" .. real_cons_c .. cons_or_joiner_c .. "*" .. oral_vowel_c .. ")", '%1.%2')

	local function resyllabify(text)
		-- (3) resyllabify C.C as .CC for various CC that can form an onset:
		--     resyllabify C.[lr] as .C[lr] for C = various obstruents;
		--     resyllabify d.ʒ, C.w, C.ɥ, C.j as .dʒ, .Cw, .Cɥ, .Cj (C.w comes from
		--     written Coi; C.ɥ comes from written Cuill; C.j comes e.g. from
		--     des‿yeux, although most post-consonantal j generated later);
		--     don't resyllabify j.j
		text = rsub(text, "(%(?)(" .. real_cons_c .. ")(" .. opt_syljoiners_c .. ")%.(" .. opt_syljoiners_c .. ")(" .. real_cons_c .. ")",
			function(lparen, c1, j1, j2, c2)
				if allow_onset_2(c1, c2) then
					return "." .. lparen .. c1 .. j1 .. j2 .. c2
				end
			end)
		-- (4) resyllabify .CC as C.C for CC that can't form an onset (opposite of
		--     the previous step); happens e.g. in ouest-quart
		text = rsub(text, "%.(" .. opt_syljoiners_c .. ")(" .. real_cons_c .. ")(%)?)(" .. opt_syljoiners_c .. ")(" .. real_cons_c .. ")",
			function(j1, c1, rparen, j2, c2)
				if not allow_onset_2(c1, c2) and not (c1 == "s" and rfind(c2, "^[ptk]$")) then
					return j1 .. c1 .. rparen .. "." .. j2 .. c2
				end
			end)
		-- (5) fix up dʒ and tʃ followed by another consonant (management respelled
		--     'manadjment' or similar)
		text = rsub(text, "%.([%(]?[dt]" .. opt_syljoiners_c .. "[ʒʃ])(" .. opt_syljoiners_c .. ")(" .. real_cons_c .. ")",
			"%1.%2%3")
		return text
	end

	text = resyllabify(text)

	-- (6) eliminate diaeresis (note, uï converted early)
	text = rsub(text, '[äëïöüÿ]', remove_diaeresis_from_vowel)

	--single vowels
	text = str_gsub(text, 'â', 'ɑ')
	--don't do this, too many exceptions
	--text = rsub(text, 'a(%.?)z', 'ɑ%1z')
	text = str_gsub(text, 'ă', 'a')
	text = str_gsub(text, 'e%.j', 'ɛ.j') -- réveiller
	text = rsub_repeatedly(text, 'e%.(' .. cons_no_liaison_c .. '*' .. vowel_c .. ')', 'ə.%1')
	text = rsub(text, 'e([⁀‿])', 'ə%1')
	text = str_gsub(text, 'æ%.', 'é.')
	text = rsub(text, 'æ([⁀‿])', 'é%1')
	text = rsub(text, '[eèêæ]', 'ɛ')
	text = str_gsub(text, 'é', 'e')
	text = rsub(text, 'o([⁀‿])', 'O%1')
	text = str_gsub(text, 'o(%.?)z', 'O%1z')
	text = rsub(text, '[oŏ]', 'ɔ')
	text = str_gsub(text, 'ô', 'o')
	text = str_gsub(text, 'u', 'y')

	--other consonants
	text = str_gsub(text, 'r', 'ʁ')
	text = str_gsub(text, 'g', 'ɡ') -- use IPA variant of g

	--(mostly) final schwa deletions (FIXME, combine with schwa deletions below)
	--1. delete all instances of ė
	text = rsub(text, '%.([^.⁀]+)ė', '%1')
	--2. delete final schwa, only in the last word, not in single-syllable word
	--   (⁀. can occur after a hyphen, e.g. in puis-je)
	text = rsub(text, '([^⁀])%.([^ə.⁀]+)ə⁀⁀', '%1%2⁀')
	--3. delete final schwa before vowel in the next word, not in a single-
	--   syllable word (croyez-le ou non); the out-of-position %4 looks weird
	--   but the effect is that we preserve the initial period when there's a
	--   hyphen and period after the schwa (con.tre-.a.tta.quer ->
	--   con.tra.tta.quer) but not across a space (con.tre a.tta.quer ->
	--   contr a.tta.quer)
	text = rsub(text, '([^⁀])%.([^ə.⁀]+)ə⁀([⁀ %-]*)(%.?)(' .. vowel_c .. ')', '%1%4%2⁀%3%5')
	--4. delete final schwa before vowel in liaison, not in a single-syllable
	--   word
	text = rsub(text, '([^⁀]%.[^ə.⁀]+)ə‿%.?(' .. vowel_c .. ')', '%1‿%2')
	--5. delete schwa after any vowel (agréerons, soierie)
	text = rsub(text, '(' .. vowel_c .. ').ə', '%1')
	--6. make final schwa optional after two consonants except obstruent + approximant
	--   and [lmn] + ʁ
	text = rsub(text, '(' .. cons_c .. ')(' .. '%.?' .. ')(' .. cons_c .. ')ə⁀',
		function(a, dot, b)
			return a .. dot .. b .. (
				rfind(a, '[bdfɡkpstvzʃʒ]') and rfind(b, '[mnlʁwj]') and 'ə'
				or rfind(a, '[lmn]') and b == 'ʁ' and 'ə' or '(ə)') .. '⁀'
		end)

	--i/u/ou -> glide before vowel
	-- -- do from right to left to handle continuions and étudiions
	--    correctly
	-- -- do repeatedly until no more subs (required due to right-to-left
	--    action)
	-- -- convert to capital J and W as	a signal that we can convert them
	--    back to /i/ and /u/ later on if they end up preceding a schwa or
	--    following two consonants in the same syllable, whereas we don't
	--    do this to j from other sources (y or ill) and w from other
	--    sources (w or oi); will be lowercased later; not necessary to do 
	--    something similar to ɥ, which can always be converted back to /y/
	--    because it always originates from /y/.
	while true do
		local new_text = rsub(text, '^(.*)i%.?(' .. vowel_c .. ')', '%1J%2')
		new_text = rsub(new_text, '^(.*)y%.?(' .. vowel_c .. ')', '%1ɥ%2')
		new_text = rsub(new_text, '^(.*)U%.?(' .. vowel_c .. ')', '%1W%2')
		if new_text == text then
			break
		end
		text = new_text
	end

	--hack for agréions, pronounced with /j.j/
	text = str_gsub(text, 'e%.J', 'ej%.J')

	--glides -> full vowels after two consonants in the same syllable
	--(e.g. fl, tr, etc.), but only glides from original i/u/ou (see above)
	--and not in the sequence 'ui' (e.g. bruit), and only when the second
	--consonant is l or r (not in abstiennent)
	text = rsub(text, '(' .. cons_c .. '[lʁ])J(' .. vowel_c .. ')', '%1i.j%2')
	text = rsub(text, '(' .. cons_c .. '[lʁ])W(' .. vowel_c .. ')', '%1u.%2')
	text = rsub(text, '(' .. cons_c .. '[lʁ])ɥ(' .. vowel_no_i_c .. ')', '%1y.%2')
	-- remove _ that prevents interpretation of letter sequences; do this
	-- before deleting internal schwas
	text = str_gsub(text, "_", "")

	-- internal schwa
	-- 1. delete schwa in VCəCV sequence word-internally when neither V is
	--    schwa, except in a few sequences such as ʁəʁ (déchirerez), ɲəʁ
	--    (indignerez), ɲəl (agnelet); use uppercase schwa when not deleting it,
	--    see below; FIXME, we might want to prevent schwa deletion with other
	--    consonant sequences
	text = rsub_repeatedly(text, '(' .. vowel_no_schwa_c .. ')%.(' .. real_cons_c ..
		')ə%.(' .. real_cons_c .. ')(' .. vowel_no_schwa_c .. ')',
		function(v1, c1, c2, v2)
			if no_delete_schwa_in_vcvcv_word_internally[c1 .. c2] then
				return v1 .. '.' .. c1 .. 'Ə.' .. c2 .. v2
			else
				return v1 .. c1 .. '.' .. c2 .. v2
			end
		end)
	-- 2. delete schwa in VCə.Cʁə, VCə.Clə sequence word-internally
	--    (palefrenier, vilebrequin).
	text = rsub(text, '(' .. vowel_no_schwa_c .. ')%.(' .. real_cons_c ..
		')ə%.(' .. real_cons_c .. ')([lʁ]ə)', '%1%2.%3%4')
	-- 3. make optional internal schwa in remaining VCəCV sequences, including
	-- across words, except between certain pairs of consonants (FIXME, needs
	-- to be smarter); needs to happen after /e/ -> /ɛ/ before schwa in next
	-- syllable and after removing ' and _ (or we need to take them into account);
	-- include .* so we go right-to-left, convert to uppercase schwa so
	-- we can handle sequences of schwas and not get stuck if we want to
	-- leave a schwa alone.
	text = rsub_repeatedly(text, '(.*' .. vowel_c .. opt_schwajoiners_c ..
		')(' .. real_cons_c .. ')(' .. opt_schwajoiners_c.. ')ə(' ..
		opt_schwajoiners_c .. ')(' .. real_cons_c .. ')(' ..
		opt_schwajoiners_c .. vowel_c .. ')',
		function(v1, c1, sep1, sep2, c2, v2)
			if no_delete_schwa_in_vcvcv_across_words[c1 .. c2] then
				return v1 .. c1 .. sep1 .. 'Ə' .. sep2 .. c2 .. v2
			else
				return v1 .. c1 .. sep1 .. '(Ə)' .. sep2 .. c2 .. v2
			end
		end)

	-- lowercase any uppercase letters (AOUMNJW etc.); they were there to
	-- prevent certain later rules from firing
	text = ulower(text)

	--ĕ forces a pronounced schwa
	text = str_gsub(text, 'ĕ', 'ə')

	-- need to resyllabify again in cases like 'saladerie', where deleting the
	-- schwa above caused a 'd.r' boundary that needs to become '.dr'.
	text = resyllabify(text)

	-- rewrite apostrophes as liaison markers
	text = str_gsub(text, "'", "‿")

	-- convert explicit-notation characters to their final result
	text = rsub(text, explicit_substitution_regex, explicit_substitution_to_sound)

	-- remove hyphens
	text = rsub(text, '%-', '')

	local function flatmap_result(items, fun)
		local new = {}
		for _, item in ipairs(items) do
			local results = fun(item)
			for _, result in ipairs(results) do
				table.insert(new, result)
			end
		end
		return new
	end

	local result = {text}
	if not noalternatives then
		-- Include alternative with harmonized é/è
		if rfind(text, "ɛ%.") or rfind(text, "e" .. real_cons_c .. "+%.") then
			result = flatmap_result(result, function(item)
				return {item, rsub(rsub(item, "ɛ%.", "e."), "e(" .. real_cons_c .. "+%.)", "ɛ%1")}
			end)
		end
		if rfind(text, "ism[⁀‿]") then
			result = flatmap_result(result, function(item)
				return {item, rsub(item, "ism([⁀‿])", "izm%1")}
			end)
		end
		if rfind(text, "is%.mə[⁀‿]") then
			result = flatmap_result(result, function(item)
				return {item, rsub(item, "is%.mə([⁀‿])", "iz.mə%1")}
			end)
		end
		if rfind(text, "ɑ" .. non_nasal_c) then
			result = flatmap_result(result, function(item)
				return {rsub_repeatedly(item, "ɑ(" .. non_nasal_c .. ")", "a%1"), item}
			end)
		end
	end

	--remove word-boundary markers
	for i, item in ipairs(result) do
		result[i] = rsub(item, '⁀', '')
	end

	-- Handle test_new_fr_pron_module/check_new_module if specified.
	if new_module_result then
		if test_new_fr_pron_module then
			if not require("table").deepEquals(new_module_result, result) then
				--error(table.concat(result, ",") .. " || " .. table.concat(new_module_result, ","))
				track("different-pron")
			else
				track("same-pron")
			end
		end
		if check_new_module then
			if not require("table").deepEquals(new_module_result, result) then
				result = table.concat(result, ",") .. " || " .. table.concat(new_module_result, ",")
			end
		end
	end
	return result
end

print(export.show("c'était,")[0])

return export