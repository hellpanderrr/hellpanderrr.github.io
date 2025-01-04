local export = {}
mw = require('mw')
local substring = mw.ustring.sub
local rsubn = mw.ustring.gsub
local rmatch = mw.ustring.match
local rsplit = mw.text.split
local U = mw.ustring.char
local lang = require("languages").getByCode("bg")
local script = require("scripts").getByCode("Cyrl")

local GRAVE = U(0x300)
local ACUTE = U(0x301)
local BREVE = U(0x306)
local PRIMARY = U(0x2C8)
local SECONDARY = U(0x2CC)
local TIE = U(0x361)
local FRONTED = U(0x31F)
local DOTUNDER = U(0x323)
local HYPH = U(0x2027)
local BREAK_MARKER = "."
local vowels = "aɤɔuɛiɐo"
local vowels_c = "[" .. vowels .. "]"
local cons = "bvɡdʒzjklwmnprstfxʃɣʲ" .. TIE
local cons_c = "[" .. cons .. "]"
local voiced_cons = "bvɡdʒzɣ" .. TIE
local voiced_cons_c = "[" .. voiced_cons .. "]"
local hcons_c = "[бвгджзйклмнпрстфхшщьчц#БВГДЖЗЙКЛМНПРСТФХШЩЬЧЦ=]"
local hvowels_c = "[аъоуеияѝюАЪОУЕИЯЍЮ]"
local accents = PRIMARY .. SECONDARY
local accents_c = "[" .. accents .. "]"

-- single characters that map to IPA sounds
local phonetic_chars_map = {
    ["а"] = "a",
    ["б"] = "b",
    ["в"] = "v",
    ["г"] = "ɡ",
    ["д"] = "d",
    ["е"] = "ɛ",
    ["ж"] = "ʒ",
    ["з"] = "z",
    ["и"] = "i",
    ["й"] = "j",
    ["к"] = "k",
    ["л"] = "l",
    ["м"] = "m",
    ["н"] = "n",
    ["о"] = "ɔ",
    ["п"] = "p",
    ["р"] = "r",
    ["с"] = "s",
    ["т"] = "t",
    ["у"] = "u",
    ["ў"] = "w",
    ["ф"] = "f",
    ["х"] = "x",
    ["ц"] = "t" .. TIE .. "s",
    ["ч"] = "t" .. TIE .. "ʃ",
    ["ш"] = "ʃ",
    ["щ"] = "ʃt",
    ["ъ"] = "ɤ",
    ["ь"] = "ʲ",
    ["ю"] = "ʲu",
    ["я"] = "ʲa",

    [GRAVE] = SECONDARY,
    [ACUTE] = PRIMARY
}

local devoicing = {
    ["b"] = "p", ["d"] = "t", ["ɡ"] = "k",
    ["z"] = "s", ["ʒ"] = "ʃ",
    ["v"] = "f"
}

local voicing = {
    ["p"] = "b", ["t"] = "d", ["k"] = "ɡ",
    ["s"] = "z", ["ʃ"] = "ʒ", ["x"] = "ɣ",
    ["f"] = "v"
}


-- Prefixes where, if they occur at the beginning of the word and the stress is on the next syllable, we place the
-- syllable division directly after the prefix. For example, the default syllable-breaking algorithm would convert
-- безбра́чие to беˈзбрачие; but because it begins with без-, we convert it to безˈбрачие. Note that we don't (yet?)
-- convert измра́ to изˈмра instead of default измˈра, although we probably should.
--
-- Think twice before putting prefixes like на-, пре- and от- here, because of the existence of над-, пред-, and о-,
-- which are also prefixes.
local IPA_prefixes = { "bɛz", "vɤz", "vɤzproiz", "iz", "naiz", "poiz", "prɛvɤz", "proiz", "raz" }


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

local function char_at(str, index)
    return substring(str, index, index)
end

local function starts_with(str, substr)
    return substring(str, 1, mw.ustring.len(substr)) == substr
end

local function count_vowels(word)
    local _, vowel_count = mw.ustring.gsub(word, hvowels_c, "")
    return vowel_count
end

function export.remove_pron_notations(text, remove_grave)
    text = rsub(text, "[." .. DOTUNDER .. "]", "")
    text = rsub(text, "ў", "у")
    text = rsub(text, "Ў", "У")

    -- Remove grave accents from annotations but maybe not from phonetic respelling
    if remove_grave then
        text = mw.ustring.toNFC(rsub(mw.ustring.toNFD(text), GRAVE, ""))
    end
    return text
end

function export.toIPA(term, endschwa)
    if type(term) == "table" then
        -- called from a template or a bot
        endschwa = term.args.endschwa
        term = term.args[1]
    end

    local origterm = term

    term = mw.ustring.toNFD(mw.ustring.lower(term))
    term = rsub(term, "у" .. BREVE, "ў") -- recompose ў
    term = rsub(term, "и" .. BREVE, "й") -- recompose й

    if term:find(GRAVE) and not term:find(ACUTE) then
        error("Use acute accent, not grave accent, for primary stress: " .. origterm)
    end

    -- allow DOTUNDER to signal same as endschwa=1
    term = rsub(term, "а(" .. accents_c .. "?)" .. DOTUNDER, "ъ%1")
    term = rsub(term, "я(" .. accents_c .. "?)" .. DOTUNDER, "ʲɤ%1")
    term = rsub(term, ".", phonetic_chars_map)

    -- Mark word boundaries
    term = rsub(term, "(%s+)", "#%1#")
    term = "#" .. term .. "#"

    -- Convert verbal and definite endings
    if endschwa then
        term = rsub(term, "a(" .. PRIMARY .. "t?#)", "ɤ%1")
    end

    -- Change ʲ to j after vowels or word-initially
    term = rsub(term, "([" .. vowels .. "#]" .. accents_c .. "?)ʲ", "%1j")

    -------------------- Move stress ---------------

    -- First, move leftwards over the vowel.
    term = rsub(term, "(" .. vowels_c .. ")(" .. accents_c .. ")", "%2%1")
    -- Then, move leftwards over j or soft sign.
    term = rsub(term, "([jʲ])(" .. accents_c .. ")", "%2%1")
    -- Then, move leftwards over a single consonant.
    term = rsub(term, "(" .. cons_c .. ")(" .. accents_c .. ")", "%2%1")
    -- Then, move leftwards over Cl/Cr combinations where C is an obstruent (NOTE: IPA ɡ).
    term = rsub(term, "([bdɡptkxfv]" .. ")(" .. accents_c .. ")([rl])", "%2%1%3")
    -- Then, move leftwards over kv/gv (NOTE: IPA ɡ).
    term = rsub(term, "([kɡ]" .. ")(" .. accents_c .. ")(v)", "%2%1%3")
    -- Then, move leftwards over sC combinations, where C is a stop or resonant (NOTE: IPA ɡ).
    term = rsub(term, "([sz]" .. ")(" .. accents_c .. ")([bdɡptkvlrmn])", "%2%1%3")
    -- Then, move leftwards over affricates not followed by a consonant.
    term = rsub(term, "([td]" .. TIE .. "?)(" .. accents_c .. ")([szʃʒ][" .. vowels .. "ʲ])", "%2%1%3")
    -- If we ended up in the middle of a tied affricate, move to its right.
    term = rsub(term, "(" .. TIE .. ")(" .. accents_c .. ")(" .. cons_c .. ")", "%1%3%2")
    -- Then, move leftwards over any remaining consonants at the beginning of a word.
    term = rsub(term, "#(" .. cons_c .. "*)(" .. accents_c .. ")", "#%2%1")
    -- Then correct for known prefixes.
    for _, prefix in ipairs(IPA_prefixes) do
        prefix_prefix, prefix_final_cons = rmatch(prefix, "^(.-)(" .. cons_c .. "*)$")
        if prefix_final_cons then
            -- Check for accent moved too far to the left into a prefix, e.g. безбрачие accented as беˈзбрачие instead
            -- of безˈбрачие
            term = rsub(term, "#(" .. prefix_prefix .. ")(" .. accents_c .. ")(" .. prefix_final_cons .. ")", "#%1%3%2")
        end
    end
    -- Finally, if there is an explicit syllable boundary in the cluster of consonants where the stress is, put it there.
    -- First check for accent to the right of the explicit syllable boundary.
    term = rsub(term, "(" .. cons_c .. "*)%.(" .. cons_c .. "*)(" .. accents_c .. ")(" .. cons_c .. "*)", "%1%3%2%4")
    -- Then check for accent to the left of the explicit syllable boundary.
    term = rsub(term, "(" .. cons_c .. "*)(" .. accents_c .. ")(" .. cons_c .. "*)%.(" .. cons_c .. "*)", "%1%3%2%4")
    -- Finally, remove any remaining syllable boundaries.
    term = rsub(term, "%.", "")

    -------------------- Vowel reduction (in unstressed syllables) ---------------
    local function reduce_vowel(vowel)
        return rsub(vowel, "[aɔɤu]", { ["a"] = "ɐ", ["ɔ"] = "o", ["ɤ"] = "ɐ", ["u"] = "o" })
    end

    -- Reduce all vowels before the stress, except if the word has no accent at all. (FIXME: This is presumably
    -- intended for single-syllable words without accents, but if the word is multisyllabic without accents,
    -- presumably all vowels should be reduced.)

    term = rsub(term, "(#[^#" .. accents .. "]*)(.-#)", function(a, b)
        if count_vowels(origterm) <= 1 then
            return a .. b
        else
            return reduce_vowel(a) .. b
        end
    end)
    -- Reduce all vowels after the accent except the first vowel after the accent mark (which is stressed).
    term = rsub(term, "(" .. accents_c .. "[^aɛiɔuɤ#]*[aɛiɔuɤ])([^#" .. accents .. "]*)", function(a, b)
        return a .. reduce_vowel(b)
    end)

    -------------------- Vowel assimilation to adjacent consonants (fronting/raising) ---------------
    term = rsub(term, "([ʃʒʲj])([aouɤ])", "%1%2" .. FRONTED)

    -- Hard l
    term = rsub_repeatedly(term, "l([^ʲɛi])", "ɫ%1")


    -- Voicing assimilation
    term = rsub(term, "([bdɡzʒv" .. TIE .. "]*)(" .. accents_c .. "?[ptksʃfx#])", function(a, b)
        return rsub(a, ".", devoicing) .. b
    end)
    term = rsub(term, "([ptksʃfx" .. TIE .. "]*)(" .. accents_c .. "?[bdɡzʒ])", function(a, b)
        return rsub(a, ".", voicing) .. b
    end)
    term = rsub(term, "n(" .. accents_c .. "?[ɡk]+)", "ŋ%1")
    term = rsub(term, "m(" .. accents_c .. "?[fv]+)", "ɱ%1")

    -- -- Correct for clitic pronunciation of с and в
    -- term = rsub(term, "#s# #(.)", "#s" .. TIE .. "%1")
    -- term = rsub(term, "#f# #(.)", "#f" .. TIE .. "%1")
    -- term = rsub(term, "([sfzv]" .. TIE .. ")" .. "(" .. accents_c .. ")", "%2%1")
    -- term = rsub(term, "s" .. TIE .. "(" .. voiced_cons_c .. ")", "z" .. TIE .. "%1")
    -- term = rsub(term, "f" .. TIE .. "(" .. voiced_cons_c .. ")", "v" .. TIE .. "%1")

    -- Sibilant assimilation
    term = rsub(term, "[sz](" .. accents_c .. "?[td]?" .. TIE .. "?)([ʃʒ])", "%2%1%2")

    -- Reduce consonant clusters
    term = rsub(term, "([szʃʒ])[td](" .. accents_c .. "?)([tdknml])", "%2%1%3")

    -- Strip hashes
    term = rsub(term, "#", "")

    return term
end

----Syllabification code----
-- Authorship: Chernorizets
-- Lua port: Kiril Kovachev

local function set_of(t)
    local out = {}

    for _, v in pairs(t) do
        out[v] = true
    end

    return out
end

local function in_set(set, value)
    return set[value] == true
end

-- Classification of letters by phonetic category
local vowels_syllab = set_of { "а", "ъ", "о", "у", "е", "и", "ю", "я" }
local sonorants = set_of { "л", "м", "н", "р", "й", "ў" }
local stops = set_of { "б", "п", "г", "к", "д", "т" }
local fricatives = set_of { "в", "ф", "ж", "ш", "з", "с", "х" }
local affricates = set_of { "ч", "ц" }

local function is_vowel(ch)
    return in_set(vowels_syllab, ch)
end

local function is_consonant(ch)
    return ch == 'щ' or is_sonorant(ch) or is_stop(ch) or is_fricative(ch) or is_affricate(ch)
end

local function is_palatalizer(ch)
    return ch == 'ь'
end

local function is_sonorant(ch)
    return in_set(sonorants, ch)
end

-- Opposite of sonorant.
local function is_obstruent(ch)
    return is_stop(ch) or is_fricative(ch) or is_affricate(ch)
end

local function is_stop(ch)
    return in_set(stops, ch)
end

local function is_fricative(ch)
    return in_set(fricatives, ch)
end

local function is_affricate(ch)
    return in_set(affricates, ch)
end

--[===[
Sonority objects:

Sonority objects take the form of a table with the following attributes:
{
	rank (int): the numerical value representing the position of the sound in the sonority hierarchy;
	first_index (int): the index of the first letter that makes up the sound within the word.
	    The index of the first letter in a word with this sonority rank.
        The affricates "дж" and "дз" are represented by two letters each, but
        for sonority purposes they function as a "unit", hence we just need
		the index of the first letter of the affricate.
}


]===]

local function new_sonority(rank, first_index)
    return {
        ["rank"] = rank,
        ["first_index"] = first_index
    }
end

local function get_sonority_rank(ch)
    if is_fricative(ch) then
        return 1
    end

    if is_stop(ch) or is_affricate(ch) then
        return 2
    end

    if is_sonorant(ch) then
        return 3
    end

    if is_vowel(ch) then
        return 4
    end

    return 0
end

-- Get the representation of a word as a list of sequential sonority objects, stored in a table.
-- Their representation is just {[1] = (sonority object #1), [2] = (sonority object #2)} etc.
-- Please see above for description of sonority objects' layout.
local function get_sonority_model(word, start_idx, end_idx)
    local sonorities = {}

    word = mw.ustring.lower(word)

    local i = start_idx
    while i < end_idx do
        local curr = char_at(word, i)
        if curr == "щ" then
            -- One letter representing 2 sounds - decompose it.
            table.insert(sonorities, new_sonority(get_sonority_rank("ш"), i))
            table.insert(sonorities, new_sonority(get_sonority_rank("т"), i));
        elseif curr == "д" then
            -- Handle affricates with 'д' - only 'дж' here for illustration.
            local next_char = (i == end_idx - 1 and " ") or char_at(word, i + 1)

            local should_skip = false
            if next_char == "ж" then
                table.insert(sonorities, new_sonority(2, i)) -- 2 = affricate sonority rank
                i = i + 1 -- Skip over the 'ж'
                should_skip = true
            end

            if not should_skip then
                table.insert(sonorities, new_sonority(get_sonority_rank("д"), i))
            end

        elseif not is_palatalizer(curr) then
            -- Skip over 'ь' since it doesn't change the sonority.
            table.insert(sonorities, new_sonority(get_sonority_rank(curr), i))
        end
        i = i + 1
    end

    return sonorities
end

-- Forced breaks when the user inputs a break marker into the input string
-- word: string; start and end are integers indexing the string
local function find_forced_break(word, range_start, range_end)
    if range_start >= range_end then
        return -1
    end

    local marker_pos = mw.ustring.find(word, BREAK_MARKER, range_start, true) or -1
    return marker_pos >= range_end and -1 or marker_pos
end

local function strip_forced_breaks(segment)
    return rsub(segment, "[.]", "");
end

---- Morphological prefix handling
--[==[
	This code brings morphological prefix awareness to syllabification.
	This is necessary, because following the principle of rising sonority
	alone fails to determine syllable boundaries correctly in some cases
    — that is, when certain prefixes should be kept together as a first syllable.
]==]

--[==[
	Affected prefixes. Each of them ends in a consonant that can be followed
	by another consonant of a higher sonority in some words. In such cases,
	naive syllable breaking would chop off the prefix's last consonant, and
	glue it to the onset of the next syllable.
]==]

local prefixes = {
    -- без- family
    "без",

    -- из- family
    "безиз", "наиз", "поиз", "произ", "преиз", "неиз", "из",

    -- въз- family
    "безвъз", "превъз", "невъз", "въз",

    -- раз- family
    "безраз", "предраз", "пораз", "нараз", "прераз", "нераз", "раз",

    -- от- family
    "неот", "поот", "от",

    -- ending in fricatives
    "екс", "таз", "дис",

    -- ending in stops
    "пред"
}

--[==[
    Finds the (zero-based) separation point between a
    morphological prefix and the rest of the word.
    By convention, that's the index of the first character
    after the prefix.

    word: the word to check for prefixes

    return -1 if no prefix found, or if the separation point
    is handled by the sonority model. A non-zero index otherwise.
]==]

-- prefix, word are both strings
local function followed_by_higher_sonority_cons(prefix, word)
    prefix = mw.ustring.lower(prefix)
    word = mw.ustring.lower(word)

    local prefix_last_char = char_at(prefix, mw.ustring.len(prefix))
    local first_char_after_prefix = char_at(word, mw.ustring.len(prefix) + 1)

    -- Prefixes followed by vowels do, in fact, get broken up.
    if is_vowel(first_char_after_prefix) then
        return false
    end

    return get_sonority_rank(prefix_last_char) < get_sonority_rank(first_char_after_prefix)
end

local function find_separation_points(word)
    local matching_prefixes = {}

    word = mw.ustring.lower(word)

    for _, prefix in pairs(prefixes) do
        if starts_with(word, prefix) and followed_by_higher_sonority_cons(prefix, word) then
            table.insert(matching_prefixes, mw.ustring.len(prefix) + 1)
        end
    end

    return matching_prefixes

end

---- Main syllabification code

---Context objects:
--[==[ encoded as a table like
{
	word (string),
	prefix_separation_points (table[int])
}

]==]

local function new_context(word, pos)
    return {
        ["word"] = word,
        ["prefix_separation_points"] = pos
    }
end

--[==[
    Consonant clusters that exhibit rising sonority, but should be
    broken up regardless to produce natural-sounding syllables.
    The breakpoint for clusters of 3 or more consonants can vary -
    here we provide a zero-based offset within the cluster for each.
]==]
local sonority_exception_break = {
    ["км"] = 1, ["гм"] = 1, ["дм"] = 1, ["вм"] = 1,
    ["зм"] = 1, ["цм"] = 1, ["чм"] = 1,
    ["дн"] = 1, ["вн"] = 1, ["тн"] = 1, ["чн"] = 1,
    ["кн"] = 1, ["гн"] = 1, ["цн"] = 1,
    ["зд"] = 1, ["зч"] = 1, ["зц"] = 1,
    ["вк"] = 1, ["вг"] = 1, ["дл"] = 1, ["жд"] = 1,
    ["згн"] = 1, ["здн"] = 2, ["вдж"] = 1
}

local sonority_exception_keep = {
    "ств", "св", "вс"
}

local function normalize_word(word)
    if word == nil then
        return ""
    end

    word = rsub(rsub(word, "^\\s+", ""), "\\s+^", "") -- Strip spaces
    return word
end

local function normalize_syllable(syllable)
    local normalized = strip_forced_breaks(syllable)
    normalized = rsub(normalized, "ў", "у")
    normalized = rsub(normalized, "Ў", "У")
    return normalized
end

local function find_rising_sonority_break(sonorities)
    local prev_rank = -1;

    for _, curr in pairs(sonorities) do
        if curr.rank <= prev_rank then
            -- Found a break.
            return curr.first_index
        end

        prev_rank = curr.rank
    end

    -- There was no rising sonority break. Start syllable at first index.
    return sonorities[1].first_index
end

local function matches(str, substr, start_idx, end_idx)
    local strlen = end_idx - start_idx
    if strlen ~= mw.ustring.len(substr) then
        return false
    end

    str = mw.ustring.lower(str)
    substr = mw.ustring.lower(substr)

    local i = start_idx
    local j = 1
    while i < end_idx do
        if char_at(str, i) ~= char_at(substr, j) then
            return false
        end
        i = i + 1
        j = j + 1
    end

    return true
end

-- ctx: context object
-- left and right vowels: integers
-- sonority break: integer
local function fixup_syllable_onset(ctx, left_vowel, sonority_break, right_vowel)
    local word = mw.ustring.lower(ctx.word)

    -- 'щр' is a syllable onset when in front of a vowel.
    -- Although 'щ' + sonorant technically follows rising sonority, syllables
    -- like щнV, щлV etc. are unnatural and incorrect. In such cases, we treat
    -- the sonorant as the onset of the next syllable.
    if char_at(word, right_vowel - 2) == "щ" then
        local penult = char_at(word, right_vowel - 1)

        if penult == "р" then
            return (right_vowel - 2)
        end
        if is_sonorant(penult) then
            return (right_vowel - 1)
        end
    end

    -- Check for situations where we shouldn't break the cluster.
    local match_found = false
    for _, cluster in pairs(sonority_exception_keep) do
        if matches(word, cluster, left_vowel + 1, right_vowel) then
            match_found = true
            break
        end
    end

    if (match_found) then
        return left_vowel + 1
    end -- syllable onset == beginning of cluster

    -- Check for situations where we should break the cluster even if
    -- it obeys the principle of rising sonority.
    local maybe_cluster = nil
    for cluster, _ in pairs(sonority_exception_break) do
        if matches(word, cluster, left_vowel + 1, right_vowel) then
            maybe_cluster = cluster
            break
        end
    end

    if maybe_cluster ~= nil then
        local offset = sonority_exception_break[maybe_cluster]
        return left_vowel + 1 + offset
    end

    local separation_points = ctx.prefix_separation_points
    local separation_match = nil
    for _, pos in pairs(separation_points) do
        if pos > left_vowel and pos < right_vowel then
            separation_match = pos
            break
        end
    end

    if separation_match ~= nil then
        return separation_match
    else
        return sonority_break
    end
end

-- ctx: context object
-- left/right vowels: integers
local function find_next_syllable_onset(ctx, left_vowel, right_vowel)
    local n_cons = right_vowel - left_vowel - 1

    -- No consonants - syllable starts on rightVowel
    if n_cons == 0 then
        return right_vowel
    end

    -- Check for forced breaks
    local break_pos = find_forced_break(ctx.word, left_vowel + 1, right_vowel)
    if break_pos ~= -1 then
        return break_pos + 1
    end

    -- Single consonant between two vowels - starts a syllable
    if n_cons == 1 then
        return left_vowel + 1
    end

    -- Two or more consonants between the vowels. Find the point (if any)
    -- where we break from rising sonority, and treat it as the tentative
    -- onset of a new syllable.
    local sonorities = get_sonority_model(ctx.word, left_vowel + 1, right_vowel)
    local sonority_break = find_rising_sonority_break(sonorities)

    -- Apply exceptions to the rising sonority principle to avoid
    -- unnatural-sounding syllables.
    return fixup_syllable_onset(ctx, left_vowel, sonority_break, right_vowel)
end

-- Returns a table of strings (list)
local function syllabify_poly(word)
    local syllables = {}

    local ctx = new_context(word, find_separation_points(word))

    local prev_vowel = -1
    local prev_onset = 1;

    for i = 1, mw.ustring.len(word) do
        if is_vowel(mw.ustring.lower(char_at(word, i))) then
            -- A vowel, yay!
            local should_skip = false
            if prev_vowel == -1 then
                prev_vowel = i
                should_skip = true;
            end

            -- This is not the first vowel we've seen. In-between
            -- the previous vowel and this one, there is a syllable
            -- break, and the first character after the break starts
            -- a new syllable.
            if not should_skip then
                local next_onset = find_next_syllable_onset(ctx, prev_vowel, i)
                table.insert(syllables, substring(word, prev_onset, next_onset - 1))
                prev_vowel = i
                prev_onset = next_onset
            end
        end

    end

    -- Add the last syllable
    table.insert(syllables, substring(word, prev_onset))

    return syllables
end

function export.syllabify_word(word)
    local norm = normalize_word(word)

    if mw.ustring.len(norm) == 0 then
        return ""
    end ;

    local n_vowels = count_vowels(norm)
    local syllables = n_vowels <= 1 and { norm } or syllabify_poly(norm)

    local out = {}
    for k, v in pairs(syllables) do
        out[k] = normalize_syllable(v)
    end

    return table.concat(out, HYPH)
end

function tokenize_words(term)
    local out = {}
    local prev_index = 1
    for i = 1, mw.ustring.len(term) do
        local current_char = char_at(term, i)
        if current_char == "-" or current_char == " " then
            table.insert(out, substring(term, prev_index, i))
            prev_index = i + 1
        end
    end
    table.insert(out, substring(term, prev_index, i))
    return out
end

function export.syllabify(term)
    local words = tokenize_words(term)

    local out = {}
    for _, word in pairs(words) do
        table.insert(out, export.syllabify_word(word))
    end
    return table.concat(out, "")
end

---Hyphenation

-- Hyphenate a word from its existing syllabification
function export.hyphenate(syllabification)
    -- Source: http://logic.fmi.uni-sofia.bg/hyphenation/hyph-bg.html#hyphenation-rules-between-1983-and-2012
    -- Also note: the rules from 2012 onward, which encode the modern standard, are entirely
    -- backwards-compatible with the previous standard. Thus our code can generate valid 2012
    -- hyphenations despite following the older rules.

    ---Pre-processing----
    word = rsub(syllabification, "[" .. GRAVE .. ACUTE .. "]", "") -- Remove accent marks
    word = rsub_repeatedly(word, HYPH .. "дж", HYPH .. "#")
    word = rsub_repeatedly(word, "дж$", "#")
    word = rsub_repeatedly(word, "^дж", "#")
    word = rsub_repeatedly(word, "(" .. hvowels_c .. ")" .. HYPH .. "(" .. hcons_c .. ")(" .. rsub(hcons_c, '[ьЬ]', '') .. "+)", "%1%2" .. HYPH .. "%3")
    word = rsub_repeatedly(word, "(" .. rsub(hcons_c, "[йЙ]", "") .. ")(" .. hcons_c .. "+)" .. HYPH, "%1" .. HYPH .. "%2")
    word = rsub_repeatedly(word, "^(" .. hvowels_c .. ")" .. HYPH, "%1")
    word = rsub_repeatedly(word, HYPH .. "(" .. hvowels_c .. ")$", "%1")
    word = rsub_repeatedly(word, "(" .. hvowels_c .. ")" .. HYPH .. "(" .. hvowels_c .. ")" .. HYPH .. "(" .. hvowels_c .. ")", "%1%2" .. HYPH .. "%3")
    word = rsub_repeatedly(word, HYPH .. "(" .. hvowels_c .. ")" .. HYPH .. "(" .. hcons_c .. ")", HYPH .. "%1%2")
    word = rsub_repeatedly(word, "#", "дж")
    return word
end

-- Hyphenate a word directly, no need to calculate its syllabification beforehand
function export.hyphenate_total(word)
    syllabification = export.syllabify(word)
    return export.hyphenate(syllabification)
end

local function get_anntext(term, ann)
    if ann == "1" or ann == "y" then
        -- remove secondary stress annotations
        anntext = "'''" .. export.remove_pron_notations(term, true) .. "''':&#32;"
    elseif ann then
        anntext = "'''" .. ann .. "''':&#32;"
    else
        anntext = ""
    end
    return anntext
end

local HYPHENATION_LABEL = "Hyphenation<sup>([[Appendix:Bulgarian hyphenation#Hyphenation|key]])</sup>"
local SYLLABIFICATION_LABEL = "Syllabification<sup>([[Appendix:Bulgarian hyphenation#Syllabification|key]])</sup>"

local function format_hyphenation(hyphenation, label)
    local syllables = rsplit(hyphenation, HYPH)
    label = label or HYPHENATION_LABEL

    return require("hyphenation").format_hyphenations {
        lang = lang,
        hyphs = { { hyph = syllables } },
        sc = script,
        caption = label,
    }

end

-- Entry point to {{bg-hyph}}
function export.show_hyphenation(frame)
    local params = {
        [1] = {},
    }

    local title = mw.title.getCurrentTitle()

    local args = require("parameters").process(frame:getParent().args, params)
    local term = args[1] or title.nsText == "Template" and "при́мер" or title.text

    local syllabification = export.syllabify(term)
    syllabification = rsub(syllabification, "[" .. ACUTE .. GRAVE .. "]", "")
    local hyphenation = export.hyphenate(syllabification)

    local out
    -- Users must put a * before the template usage
    if syllabification == hyphenation then
        out = format_hyphenation(syllabification)
    else
        local syllabification_text = format_hyphenation(syllabification, SYLLABIFICATION_LABEL)
        local hyphenation_text = format_hyphenation(hyphenation)
        out = syllabification_text .. "\n* " .. hyphenation_text
    end

    return out
end

function export.show(frame)
    local params = {
        [1] = {},
        ["endschwa"] = { type = "boolean" },
        ["ann"] = {},
        ["q"] = { type = "qualifier" },
        ["qq"] = { type = "qualifier" },
        ["a"] = { type = "labels" },
        ["aa"] = { type = "labels" },
        ["pagename"] = {},
    }

    local args = require("parameters").process(frame:getParent().args, params)
    local term = args[1] or args.pagename or mw.title.getCurrentTitle().nsText == "Template" and "при́мер" or
            mw.loadData("headword/data").pagename

    local ipa = export.toIPA(term, args.endschwa)
    ipa = "[" .. ipa .. "]"
    local ipa_data = {
        lang = lang,
        items = { { pron = ipa } },
        q = args.q,
        qq = args.qq,
        a = args.a,
        aa = args.aa,
    }

    local ipa_text = require("IPA").format_IPA_full(ipa_data)
    local anntext = get_anntext(term, args.ann)

    return anntext .. ipa_text
end
print(export.toIPA("Съединени американски щати"))
return export