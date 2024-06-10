local export = {}
local mw = require('mw')
local m_params = require("parameters")
local m_IPA = require("IPA")
local m_str_utils = require("string utilities")
local m_syllables = require("syllables")

local lang = require("languages").getByCode("cs")
local sc = require("scripts").getByCode("Latn")

function export.tag_text(text, face)
    return require("script utilities").tag_text(text, lang, sc, face)
end

function export.link(term, face)
    return require("links").full_link(
            { term = term, lang = lang, sc = sc }, face
    )
end

local lower = m_str_utils.lower
local pattern_escape = m_str_utils.pattern_escape
local replacement_escape = m_str_utils.replacement_escape
local rmatch = m_str_utils.match
local rfind = m_str_utils.find
local rsubn = m_str_utils.gsub
local rsplit = m_str_utils.split
local toNFC = mw.ustring.toNFC
local U = mw.ustring.char
local long = "ː"
local nonsyllabic = U(0x32F)    -- inverted breve below
local syllabic = U(0x0329)
local syllabic_below = U(0x030D)
local raised = U(0x031D)        -- uptack below
local ringabove = U(0x030A)        -- ring above
local caron = U(0x030C)            -- combining caron
local tie = U(0x0361)            -- combining double inverted breve
local AC = U(0x0301)            -- combining acute accent
local primary_stress = "ˈ"
local secondary_stress = "ˌ"

local single_char_subs = {
    ["á"] = "a" .. long,
    ["c"] = "t" .. tie .. "s",
    ["č"] = "t" .. tie .. "ʃ",
    ["ď"] = "ɟ",
    ["e"] = "ɛ",
    ["é"] = "ɛ" .. long,
    ["ě"] = "jɛ",
    ["g"] = "ɡ",
    ["h"] = "ɦ",
    ["i"] = "ɪ",
    ["í"] = "i" .. long,
    ["ň"] = "ɲ",
    ["ó"] = "o" .. long,
    ["q"] = "k",
    ["ř"] = "r" .. raised,
    ["š"] = "ʃ",
    ["t"] = "t",
    ["ť"] = "c",
    ["ú"] = "u" .. long,
    ["ů"] = "u" .. long,
    ["w"] = "v",
    ["x"] = "ks",
    ["y"] = "ɪ",
    ["ý"] = "i" .. long,
    ["ž"] = "ʒ",
    ["\""] = primary_stress,
    ["%"] = secondary_stress,
    ["?"] = "ʔ",
}

--[[	This allows multiple-character sounds to be replaced
		with single characters to make them easier to process.	]]

local multiple_to_single = {
    ["t" .. tie .. "s"] = "ʦ",
    ["t" .. tie .. "ʃ"] = "ʧ",
    ["r" .. raised .. ringabove] = "ṙ",
    ["d" .. tie .. "z"] = "ʣ",
    ["d" .. tie .. "ʒ"] = "ʤ",
    ["r" .. raised] = "ř",
}

--[[	"voiceless" and "voiced" are obstruents only;
		sonorants are not involved in voicing assimilation.	]]

-- ʦ, ʧ, "ṙ" replace t͡s, t͡ʃ, r̝̊
local voiceless = { "p", "t", "c", "k", "f", "s", "ʃ", "x", "ʦ", "ʧ", "ṙ", "ʔ" }
-- "ʣ", ʤ, ř replace d͡z, d͡ʒ, r̝
local voiced = { "b", "d", "ɟ", "ɡ", "v", "z", "ʒ", "ɦ", "ʣ", "ʤ", "ř", }
local sonorants = { "m", "n", "ɲ", "r", "l", "j", }
local consonant = "[" .. table.concat(sonorants) .. "ŋ"
        .. table.concat(voiceless) .. table.concat(voiced) .. "]"
assimil_consonants = {}
assimil_consonants.voiceless = voiceless
assimil_consonants.voiced = voiced

local features = {}
local indices = {}
for index, consonant in pairs(voiceless) do
    if not features[consonant] then
        features[consonant] = {}
    end
    features[consonant]["voicing"] = "voiceless"
    indices[consonant] = index
end

for index, consonant in pairs(voiced) do
    if not features[consonant] then
        features[consonant] = {}
    end
    features[consonant]["voicing"] = "voiced"
    indices[consonant] = index
end

local short_vowel = "[aɛɪou]"
local long_vowel = "[aɛiou]" .. long
local diphthong = "[aɛo]u" .. nonsyllabic
local syllabic_consonant = "[mnrl]" .. syllabic

local written_vowel = "[aeiouyáéíóúýěů]"
local written_acute_vowel = "[áéíóúý]"
local written_acute_to_plain_vowel = {
    ["á"] = "a",
    ["é"] = "e",
    ["í"] = "i",
    ["ó"] = "o",
    ["ú"] = "u",
    ["ý"] = "y",
}

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

local function compose(text)
    return toNFC(text)
end

-- Canonicalize multiple spaces and remove leading and trailing spaces.
local function canon_spaces(text)
    text = rsub(text, "%s+", " ")
    text = rsub(text, "^ ", "")
    text = rsub(text, " $", "")
    return text
end

-- all but v and r̝
local causing_assimilation = rsub(
        "[" .. table.concat(voiceless) .. table.concat(voiced) .. "ʔ]",
        "[vř]",
        ""
)

local assimilable = "[" .. table.concat(voiceless):gsub("ʔ", "") .. table.concat(voiced) .. "]"

local function regressively_assimilate(IPA)
    IPA = rsub(
            IPA,
            "(" .. assimilable .. "+)(" .. causing_assimilation .. ")",
            function(assimilated, assimilator)
                local voicing = features[assimilator] and features[assimilator].voicing
                        or error('The consonant "' .. consonant
                        .. '" is not recognized by the function "regressively_assimilate".')
                return rsub(
                        assimilated,
                        ".",
                        function(consonant)
                            return assimil_consonants[voicing][indices[consonant]]
                        end)
                        .. assimilator
            end)

    IPA = rsub(IPA, "smus", "zmus")

    return IPA
end

local function devoice_finally(IPA)
    local obstruent = "[" .. table.concat(voiced) .. table.concat(voiceless) .. "]"

    IPA = rsub(
            IPA,
            "(" .. obstruent .. "+)#",
            function(final_obstruents)
                return rsub(
                        final_obstruents,
                        ".",
                        function(obstruent)
                            return voiceless[indices[obstruent]]
                        end)
                        .. "#"
            end)

    return IPA
end

local function devoice_fricative_r(IPA)
    -- all but r̝̊, which is added by this function
    local voiceless = rsub("[" .. table.concat(voiceless) .. "]", "ṙ", "")

    -- ř represents r̝, "ṙ" represents r̝̊
    IPA = rsub(IPA, "(" .. voiceless .. ")" .. "ř", "%1ṙ")
    IPA = rsub(IPA, "ř" .. "(" .. voiceless .. ")", "ṙ%1")

    return IPA
end

local function syllabicize_sonorants(IPA)
    -- all except ɲ and j
    local sonorant = rsub("[" .. table.concat(sonorants) .. "]", "[ɲj]", "")
    local obstruent = "[" .. table.concat(voiced) .. table.concat(voiceless) .. "]"

    -- between a consonant and an obstruent
    IPA = rsub(
            IPA,
            "(" .. consonant .. "+" .. sonorant .. ")(" .. consonant .. ")",
            "%1" .. syllabic .. "%2"
    )

    -- at the end of a word after an obstruent
    IPA = rsub(IPA, "(" .. obstruent .. sonorant .. ")#", "%1" .. syllabic)

    return IPA
end

local function assimilate_nasal(IPA)
    local velar = "[ɡk]"

    IPA = rsub(IPA, "n(" .. velar .. ")", "ŋ%1")

    return IPA
end

local function add_stress(IPA)
    local syllable_count = m_syllables.getVowels(IPA, lang)

    if not (rfind(IPA, " ") or rfind(IPA, primary_stress)) then
        IPA = primary_stress .. IPA
    end

    return IPA
end

local function syllabify(IPA)
    local syllables = {}

    local working_string = IPA

    local noninitial_cluster = rmatch(working_string, ".(" .. consonant .. consonant .. ").")
    local has_cluster = noninitial_cluster and not rfind(noninitial_cluster, "(.)%1")

    if not (has_cluster or rfind(working_string, " ")) then
        while #working_string > 0 do
            local syllable = rmatch(working_string, "^" .. consonant .. "*" .. diphthong)
                    or rmatch(working_string, "^" .. consonant .. "*" .. long_vowel)
                    or rmatch(working_string, "^" .. consonant .. "*" .. short_vowel)
                    or rmatch(working_string, "^" .. consonant .. "*" .. syllabic_consonant)
            if syllable then
                table.insert(syllables, syllable)
                working_string = rsub(working_string, syllable, "", 1)
            elseif rfind(working_string, "^" .. consonant .. "+$")
                    or rfind(working_string, primary_stress)
            then

                syllables[#syllables] = syllables[#syllables] .. working_string
                working_string = ""
            else
                error('The function "syllabify" could not find a syllable '
                        .. 'in the IPA transcription "' .. working_string .. '".')
            end
        end
    end

    if #syllables > 0 then
        IPA = table.concat(syllables, ".")
    end

    return IPA
end

local function apply_rules(IPA)
    -- Handle consonantal prepositions: v, z.
    IPA = rsub(
            IPA,
            "(#[vz])# #(.)",
            function(preposition, initial_sound)
                if rfind(initial_sound, short_vowel) then
                    return preposition .. "ʔ" .. initial_sound
                else
                    return preposition .. initial_sound
                end
            end)

    for sound, character in pairs(multiple_to_single) do
        IPA = rsub(IPA, sound, character)
    end
    IPA = regressively_assimilate(IPA)
    IPA = devoice_finally(IPA)
    IPA = devoice_fricative_r(IPA)
    IPA = syllabicize_sonorants(IPA)
    IPA = assimilate_nasal(IPA)
    IPA = add_stress(IPA)
    for sound, character in pairs(multiple_to_single) do
        IPA = rsub(IPA, character, sound)
    end
    --[[	This replaces double (geminate) with single consonants,
            and changes a stop plus affricate to affricate:
            for instance, [tt͡s] to [t͡s].								]]
    IPA = rsub(IPA, "(" .. consonant .. ")%1", "%1")

    -- Remove # at word boundaries.
    IPA = rsub(IPA, "#", "")
    return IPA
end

function export.toIPA(text)
    local orig_respelling = text

    text = lower(text)

    -- convert commas and en/en dashes to IPA foot boundaries
    text = rsub_repeatedly(text, "%s*[,–—]%s*", " | ")
    -- question mark or exclamation point in the middle of a sentence -> IPA foot boundary
    text = rsub_repeatedly(text, "([^%s])%s*[!?]%s+([^%s])", "%1 | %2")
    text = rsub(text, "[!?]$", "") -- eliminate remaining punctuation

    text = canon_spaces(text)

    -- put # at word beginning and end and double ## at text/foot boundary beginning/end
    text = rsub(text, " | ", "# | #")
    text = "##" .. rsub(text, " ", "# #") .. "##"

    text = rsub(text, "^%-", "")
    text = rsub(text, "%-$", "")
    text = rsub(text, "%-", " ")
    text = rsub(text, "nn", "n") -- similar operation is applied to IPA above

    -- Handle palatalization before ě, i and í.
    text = rsub(text, "([tdn])ě", "%1" .. caron .. "e")
    text = rsub(text, "([tdn])([ií])", "%1" .. caron .. "%2")
    text = rsub(text, "mě", "mn" .. caron .. "e")
    text = compose(text) -- recompose combining caron

    -- Handle initial ex- pronounced /egz/.
    text = rsub(text, "#exh", "#egzh")
    text = rsub(text, "#ex(" .. written_vowel .. ")", "#egz%1")

    -- Initial i- and y- + vowel are pronounced like /j/. Other sequences of i/y/í/ý + vowel need an interpolated /j/.
    text = rsub(text, "#[iy](" .. written_vowel .. ")", "#j%1")
    text = rsub(text, "([iyíý])(" .. written_vowel .. ")", "%1j%2")

    text = rsub(text, "ch", "X") -- temporary substitution

    -- convert to approximate phonetic notation; FIXME: this is being done way too early
    text = rsub(text, "([oa])u", "%1u" .. nonsyllabic)
    text = rsub(text, "eu", "ɛu" .. nonsyllabic)
    text = rsub(text, "eu", "ɛu" .. nonsyllabic)
    text = rsub(text, ".", single_char_subs)

    text = rsub(text, "X", "x")

    text = apply_rules(text)

    return text
end

local function convert_respelling_to_original(to, pagename, whole_word)
    local from = rsub(to, "[yý]", "i"):gsub("z", "s"):gsub("%?", "")
    from = rsub(from, written_acute_vowel, written_acute_to_plain_vowel)
    local escaped_from = pattern_escape(from)
    if whole_word then
        escaped_from = "%f[%a]" .. escaped_from .. "%f[%A]"
    end
    if rfind(pagename, escaped_from) then
        return from
    end
    -- Check for partial replacement.
    escaped_from = pattern_escape(to)
    -- Replace specially-handled characters with a class matching the character and possible replacements. Order of the
    -- following substitutions is important to avoid a later substitution interfering with an earlier one.
    escaped_from = rsub(escaped_from, "[áéíóú]", function(v)
        return "[" .. v .. written_acute_to_plain_vowel[v] .. "]"
    end)
    escaped_from = "(" .. escaped_from:gsub("y", "[iy]"):gsub("ý", "[iíyý]"):gsub("z", "[sz]"):gsub("%%%?", "[?]?") .. ")"
    if whole_word then
        escaped_from = "%f[%a]" .. escaped_from .. "%f[%A]"
    end
    local match = rmatch(pagename, escaped_from)
    if match then
        if match == to then
            error(("Single substitution spec '%s' found in pagename '%s', replacement would have no effect"):
            format(to, pagename))
        end
        return match
    end
    error(("Single substitution spec '%s' couldn't be matched to pagename '%s'"):format(to, pagename))
end


-- Given raw respelling, canonicalize it. This currently applies substitutions of the form e.g. [ny] or [th:t,nýz].
local function canonicalize(text, pagename)
    if text == "+" then
        text = pagename
    elseif rfind(text, "^%[.*%]$") then
        local subs = rsplit(rmatch(text, "^%[(.*)%]$"), ",")
        text = pagename
        local function err(msg)
            error(msg .. ": " .. text)
        end
        for _, sub in ipairs(subs) do
            local from, escaped_from, to, escaped_to, whole_word
            if rfind(sub, "^~") then
                -- whole-word match
                sub = rmatch(sub, "^~(.*)$")
                whole_word = true
            end
            if sub:find(":") then
                from, to = rmatch(sub, "^(.-):(.*)$")
            else
                to = sub
                from = convert_respelling_to_original(to, pagename, whole_word)
            end
            escaped_from = pattern_escape(from)
            if whole_word then
                escaped_from = "%f[%a]" .. escaped_from .. "%f[%A]"
            end
            escaped_to = replacement_escape(to)
            local subbed_text, nsubs = rsubn(text, escaped_from, escaped_to)
            if nsubs == 0 then
                err(("Substitution spec %s -> %s didn't match processed pagename"):format(from, to))
            elseif nsubs > 1 then
                err(("Substitution spec %s -> %s matched multiple substrings in processed pagename, add more context"):format(from, to))
            else
                text = subbed_text
            end
        end
    end

    return text
end

function export.show(frame)
    local params = {
        [1] = { list = true },
        ["pagename"] = {}, -- for testing
    }

    local parargs = frame:getParent().args
    local args = m_params.process(parargs, params)
    local title = mw.title.getCurrentTitle()
    local pagename = args.pagename or title.subpageText

    -- Parse the arguments.
    local respellings = #args[1] > 0 and args[1] or title.namespace == "Template" and pagename == "cs-IPA" and "příklad" or { "+" }
    local prons = {}
    for i, respelling in ipairs(respellings) do
        respelling = canonicalize(respelling, pagename)
        local IPA = export.toIPA(respelling)
        IPA = "[" .. IPA .. "]"
        IPA = m_IPA.format_IPA_full { lang = lang, items = { { pron = IPA } } }
        table.insert(prons, IPA)
    end

    return table.concat(prons, "\n* ")
end

print(export.toIPA("tropický"))

return export