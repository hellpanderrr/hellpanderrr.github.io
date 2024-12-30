local export = {}
mw = require('mw')
local m_table = require("table")
function listToSet(t)
    local set = {}
    for _, item in ipairs(t) do
        set[item] = true
    end
    return set
end
m_table.listToSet = listToSet
local u = mw.ustring.char
local rfind = mw.ustring.find
local rsubn = mw.ustring.gsub
local rmatch = mw.ustring.match
local rsplit = mw.text.split
local usub = mw.ustring.sub
local ulen = mw.ustring.len

-- version of rsubn() that discards all but the first return value
local function rsub(term, foo, bar)
    local retval = rsubn(term, foo, bar)
    return retval
end

-- apply function repeatedly until no change
local function do_sub_repeatedly(term, fun)
    while true do
        local new_term = fun(term)
        if new_term == term then
            return term
        end
        term = new_term
    end
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

local grave = u(0x300)
local acute = u(0x301)
local stress = u(0x2C8)
local secondary_stress = u(0x2CC)
local tie = u(0x361)

local correspondences = {
    ["а"] = "a",
    ["б"] = "b",
    ["в"] = "v",
    ["г"] = "ɣ",
    ["ґ"] = "ɡ",
    ["д"] = "d",
    ["дз"] = "d" .. tie .. "z",
    ["дж"] = "d" .. tie .. "ʐ",
    ["е"] = "ʲe", -- or ɛ
    ["ё"] = "ʲo",
    ["ж"] = "ʐ",
    ["з"] = "z",
    ["і"] = "ʲi",
    ["й"] = "j",
    ["к"] = "k",
    ["л"] = "l",
    ["м"] = "m",
    ["н"] = "n",
    ["о"] = "o", -- or ɔ
    ["п"] = "p",
    ["р"] = "r",
    ["с"] = "s",
    ["т"] = "t",
    ["у"] = "u",
    ["ў"] = "w",
    ["ф"] = "f",
    ["х"] = "x",
    ["ц"] = "t" .. tie .. "s",
    ["ч"] = "t" .. tie .. "ʂ",
    ["ш"] = "ʂ",
    ["ы"] = "ɨ",
    ["ь"] = "ʲ",
    ["э"] = "ɛ",
    ["ю"] = "ʲu",
    ["я"] = "ʲa",
    [acute] = stress,
    [grave] = secondary_stress,
    -- Space
    [" "] = " ",
    -- Apostrophes
    [u(0x27)] = "j",
    [u(0x2019)] = "j",
    [u(0x2BC)] = "j"
}

local devoicing = {
    ['b'] = 'p', ['d'] = 't', ['ɡ'] = 'k',
    ['z'] = 's', ['ʐ'] = 'ʂ', ['ɣ'] = 'x'
}

local voicing = {
    ['p'] = 'b', ['t'] = 'd', ['k'] = 'ɡ',
    ['s'] = 'z', ['ʂ'] = 'ʐ', ['x'] = 'ɣ',
    ['f'] = 'v'
}

local vowel = "aeɛiɨou"
local vowel_c = "[" .. vowel .. "]"
local consonant = "jmnlrvwbdzʐɡɣpftskxʂ"
local consonant_c = "[" .. consonant .. "]"

local accent = stress .. secondary_stress
local accent_c = "[" .. accent .. "]"

local perm_syl_onset = m_table.listToSet({
    'spr', 'str', 'skr', 'spl', 'skl',
    'sp', 'st', 'sk', 'sf', 'sx', 'sl', 'sm', 'sn',
    -- WARNING, IPA ɡ used in the next two lines (and throughout this module)
    'pr', 'br', 'tr', 'dr', 'kr', 'ɡr', 'ɣr', 'fr', 'xr',
    'pl', 'bl', 'kl', 'ɡl', 'ɣl', 'fl', 'xl',
})

local function move_stress(transcription)
    -- The following logic for placing the stress mark on a syllable boundary is copied from
    -- [[Module:uk-pronunciation]].
    -- (1) Put the stress mark before the final consonant of a cluster (if any).
    transcription = rsub(transcription, "([^#" .. vowel .. "]?[ʲː]*" .. vowel_c .. ")(" .. accent_c .. ")", "%2%1")
    -- (2) Continue moving it over the rest of an affricate with a tie bar.
    transcription = rsub(transcription, "([^#" .. vowel .. "]͡)(" .. accent_c .. ")", "%2%1")
    -- (3) Continue moving it over any "permanent onset" clusters (e.g. st, skr, pl, also Cj).
    transcription = rsub(transcription, "(.)(ʲ?)(" .. consonant_c .. ")(ʲ?)(" .. accent_c .. ")(" .. consonant_c .. ")",
            function(a, aj, b, bj, stress, c)
                if perm_syl_onset[a .. b .. c] then
                    return stress .. a .. aj .. b .. bj .. c
                elseif perm_syl_onset[b .. c] or c == "j" then
                    return a .. aj .. stress .. b .. bj .. c
                else
                    return a .. aj .. b .. bj .. stress .. c
                end
            end)
    -- (4) If we're in the middle of an affricate with a tie bar, continue moving back
    --     if the following consonant is /j/, else move forward.
    transcription = rsub(transcription, "([^#" .. vowel .. "]͡)(" .. accent_c .. ")(.ʲ?j)", "%2%1%3")
    transcription = rsub(transcription, "([^#" .. vowel .. "]͡)(" .. accent_c .. ")(.ʲ?)", "%1%3%2")
    -- (5) Move back over any remaining consonants at the beginning of a word.
    transcription = rsub(transcription, "#([^#" .. vowel .. "]+)(" .. accent_c .. ")", "#%2%1")
    -- (6) Move back over u̯ or i̯ at the beginning of a word.
    transcription = rsub(transcription, "#([ui]̯)(" .. accent_c .. ")", "#%2%1")
    return transcription
end

local function assimilate_voicing(transcription)
    return do_sub_repeatedly(transcription, function(text)
        text = rsub(text, "([bdɡɣzʐ])([ʲː" .. tie .. "]*[ptkfxsʂ#])", function(a, b)
            return devoicing[a] .. b
        end)
        text = rsub(text, "([ptkfxsʂ])([ʲː" .. tie .. "]*v?[ʲː" .. tie .. "]*[bdɡɣzʐ])", function(a, b)
            return voicing[a] .. b
        end)
        return text
    end)
end

local function assimilate_sibilants(transcription)
    return rsub_repeatedly(transcription, "[sʂzʐ]([td]?" .. tie .. "?)([sʂzʐ])", "%2%1%2")
end

-- Can probably be simplified
local function assimilate_palatals(transcription)
    return do_sub_repeatedly(transcription, function(text)
        text = rsub(text, "([bzɡɣpfskxmnlv])%1ʲ", "%1ʲ%1ʲ")
        text = rsub(text, "([szn])j", "%1ʲj")
        text = rsub(text, "([sn])(" .. accent_c .. "?[td]" .. tie .. "[sz]ʲ)", "%1ʲ%2")
        text = rsub(text, "([sz])([nl])ʲ", "%1ʲ%2ʲ")

        -- No assimilation in a final, non-initial syllable
        text = rsub_repeatedly(text, "([sz])([bmpfv])ʲ([^#]*" .. vowel_c .. "[^#]*" .. vowel_c .. ")", "%1ʲ%2ʲ%3")
        text = rsub(text, "#([^#" .. vowel .. "]*)([sz])([bmpfv])ʲ", "%1%2ʲ%3ʲ")

        text = rsub(text, "([td]" .. tie .. "[sz])vʲ", "%1ʲvʲ")
        text = rsub(text, "tsʲ", "t" .. tie .. "sʲsʲ")
        text = rsub(text, "dzʲ", "d" .. tie .. "zʲzʲ")
        text = rsub(text, "tt" .. tie .. "sʲ", "t" .. tie .. "sʲt" .. tie .. "sʲ")
        text = rsub(text, "dd" .. tie .. "zʲ", "d" .. tie .. "zʲd" .. tie .. "zʲ")
        return text
    end)
end

local function convert(text)
    -- convert commas and em/en dashes to IPA foot boundaries
    text = rsub(text, '%s*[,–—]%s*', ' | ')
    -- convert hyphen to space
    text = rsub(text, "%-", " ")
    -- canonicalize spaces
    text = rsub(text, "%s+", " ")
    text = rsub(text, "^%s", "")
    text = rsub(text, "%s$", "")
    local working_string = mw.ustring.lower(text)
    local IPA = {}
    while ulen(working_string) > 0 do
        local IPA_letter

        local letter = usub(working_string, 1, 1)
        local twoletters = usub(working_string, 1, 2) or ""

        if correspondences[twoletters] then
            IPA_letter = correspondences[twoletters]
            working_string = usub(working_string, 3)
        else
            IPA_letter = correspondences[letter] or letter
            working_string = usub(working_string, 2)
        end

        table.insert(IPA, IPA_letter)
    end
    IPA = table.concat(IPA)

    -- Mark word boundaries
    IPA = rsub(IPA, "(%s+)", "#%1#")
    IPA = "#" .. IPA .. "#"

    -- Change ʲ to j between vowels or after another ʲ.
    IPA = rsub_repeatedly(IPA, "([#w" .. vowel .. "ʲ]" .. accent_c .. "?)ʲ(" .. vowel_c .. ")", "%1j%2")
    IPA = rsub(IPA, "jʲ", "j")

    -- /г/ is a stop in /зг/, /жг/
    IPA = rsub(IPA, "([sʂzʐ])ɣ", "%1ɡ")

    -- Mark stress
    IPA = rsub_repeatedly(IPA, "(#[^#o" .. stress .. "]*)o([^#o" .. stress .. "]*[aeɛiɨu][^#o" .. stress .. "]*#)", "%1o" .. stress .. "%2")
    IPA = rsub_repeatedly(IPA, "(#[^#o" .. stress .. "]*[aeɛiɨu][^#o" .. stress .. "]*)o([^#o" .. stress .. "]*#)", "%1o" .. stress .. "%2")

    -- Syllable-final /в/ is [u̯]
    IPA = rsub_repeatedly(IPA, "([" .. vowel .. accent .. "]+)w([^" .. vowel .. "])", "%1u̯%2")

    return IPA
end

function export.toIPA(term)
    --	Returns an error if the word contains alphabetic characters that are not Cyrillic.
    require("script utilities").checkScript(term, "Cyrl")

    IPA = convert(term)

    -- Voicing assimilation
    IPA = assimilate_voicing(IPA)

    -- Sibilant assimilation
    IPA = assimilate_sibilants(IPA)

    -- Palatal assimilation
    IPA = assimilate_palatals(IPA)

    -- Soft and hard /л/
    IPA = rsub(IPA, "l([^ʲ])", "ɫ%1")

    -- Convert identical consonant sequences to geminates
    IPA = rsub(IPA, "([td]" .. tie .. "[szʂʐ]ʲ?)%1", "%1ː")
    IPA = rsub_repeatedly(IPA, "([^" .. tie .. "])([bdzʐɡɣpftskxʂmnlrjvw]ʲ?)%2", "%1%2ː")

    IPA = move_stress(IPA)

    -- Remove #s
    IPA = rsub(IPA, "#", "")

    return IPA
end

function export.remove_pron_notations(text, remove_grave)
    -- Remove grave accents from annotations but maybe not from phonetic respelling
    if remove_grave then
        text = mw.ustring.toNFC(rsub(mw.ustring.toNFD(text), grave, ""))
    end
    return text
end

function export.show(frame)
    local params = {
        [1] = {},
        ["ann"] = {},
    }

    local title = mw.title.getCurrentTitle()

    local args = require("parameters").process(frame:getParent().args, params)
    local term = args[1] or title.nsText == "Template" and "пры́клад" or title.text

    local IPA = export.toIPA(term)

    IPA = "[" .. IPA .. "]"
    IPA = require("IPA").format_IPA_full {
        lang = require("languages").getByCode("be"),
        items = { { pron = IPA } },
    }

    local anntext
    if args.ann == "1" or args.ann == "y" then
        -- remove secondary stress annotations
        anntext = "'''" .. export.remove_pron_notations(term, true) .. "''':&#32;"
    elseif args.ann then
        anntext = "'''" .. args.ann .. "''':&#32;"
    else
        anntext = ""
    end

    return anntext .. IPA
end

print(export.toIPA("Злу́чаныя Шта́ты Аме́рыкі"))

return export