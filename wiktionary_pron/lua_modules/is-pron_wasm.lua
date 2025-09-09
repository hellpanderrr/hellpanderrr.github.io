local export = {}
mw = require('mw')

local lang = require("languages").getByCode("is")
local sc = require("scripts").getByCode("Latn")
local m_ipa = require("IPA")

function export.tag_text(text, face)
    return require("script utilities").tag_text(text, lang, sc, face)
end

function export.link(term, face)
    return require("links").full_link({ term = term, lang = lang, sc = sc }, face)
end

local sub = mw.ustring.sub
local find = mw.ustring.find
local format = mw.ustring.format
local gmatch = mw.ustring.gmatch
local gsub = mw.ustring.gsub
local len = mw.ustring.len
local lower = mw.ustring.lower
local split = mw.text.split

local U = mw.ustring.char
local nonsyllabic = U(0x32F)    -- inverted breve below
local voiceless = U(0x325)      -- combining ring below
local long = U(0x2D0)           -- triangular colon
local primary_stress = "ˈ"
local secondary_stress = "ˌ"

local consonants = "bdðfghjklmnprstvxþ"
local consonant = "[" .. consonants .. "]"

local vowels = "aɛɪiʏyœɔou"
local vowel = "[" .. vowels .. "]+" .. nonsyllabic .. "?" .. long .. "?"

local stress = "[" .. primary_stress .. secondary_stress .. "]"

-- pronunciation data
local data = {
    -- consonants: initial, internal/word-final in arrays
    -- trigraphs
    ["trigraphs"] = {
        ["fnd"] = "mt",
        ["fnt"] = "m" .. voiceless .. "t",
        ["mbd"] = "mt",
        ["mbg"] = "mk",
        ["mbs"] = "ms",
        ["mbt"] = "m" .. voiceless .. "t"
    },
    -- digraphs
    ["digraphs"] = {
        ["ll"] = "tl" .. voiceless,
        ["ff"] = "ff",
        ["gj"] = { "c", "gj" },
        ["kj"] = { "cʰ", "c" },
        ["rl"] = "rtl" .. voiceless,
        ["rn"] = "rtn" .. voiceless,
        ["sl"] = "stl" .. voiceless,
        ["sn"] = "stn" .. voiceless,
        ["qu"] = "kʰv",
        ["hv"] = "kʰv",
        ["hl"] = "l" .. voiceless,
        ["hn"] = "n" .. voiceless,
        ["hr"] = "r" .. voiceless,
        ["hj"] = "ç"
    },
    -- single chars
    ["single"] = {
        ["b"] = "p",
        ["d"] = "t",
        ["g"] = { "k", "g" },
        ["p"] = { "pʰ", "p" },
        ["t"] = { "tʰ", "t" },
        ["k"] = { "kʰ", "k" },
        ["q"] = { "kʰ", "k" },
        ["x"] = { "s", "xs" },
        ["f"] = { "f", "v" },
        ["þ"] = "θ"
    },
    -- vowels: regular, before gi, before ng/nk
    ["vowels"] = {
        ["au"] = {
            "œy" .. nonsyllabic,
            "œy" .. nonsyllabic,
            "œy" .. nonsyllabic
        },
        ["ei"] = {
            "ɛi" .. nonsyllabic,
            "ɛi" .. nonsyllabic,
            "ɛi" .. nonsyllabic
        },
        ["a"] = {
            "a",
            "ai" .. nonsyllabic,
            "au" .. nonsyllabic
        },
        ["á"] = {
            "au" .. nonsyllabic,
            "au" .. nonsyllabic,
            "au" .. nonsyllabic
        },
        ["e"] = {
            "ɛ",
            "ei" .. nonsyllabic,
            "ɛi" .. nonsyllabic
        },
        ["é"] = {
            "jɛ",
            "jɛ",
            "jɛ"
        },
        ["i"] = {
            "ɪ",
            "i",
            "i"
        },
        ["í"] = {
            "i",
            "i",
            "i"
        },
        ["o"] = {
            "ɔ",
            "ɔi" .. nonsyllabic,
            "ɔi" .. nonsyllabic
        },
        ["ó"] = {
            "ou" .. nonsyllabic,
            "ou" .. nonsyllabic,
            "ou" .. nonsyllabic
        },
        ["u"] = {
            "ʏ",
            "ʏi" .. nonsyllabic,
            "u"
        },
        ["ú"] = {
            "u",
            "u",
            "u"
        },
        ["æ"] = {
            "ai" .. nonsyllabic,
            "ai" .. nonsyllabic,
            "ai" .. nonsyllabic
        },
        ["ö"] = {
            "œ",
            "œy" .. nonsyllabic,
            "œy" .. nonsyllabic
        }
    }
}

-- add data for preaspirated stop clusters
for letter_a in gmatch("ptk", ".") do
    data.digraphs[letter_a .. letter_a] = "h" .. letter_a
    for letter_b in gmatch("lmn", ".") do
        data.digraphs[letter_a .. letter_b] = "h" .. letter_a .. letter_b .. voiceless
    end
end

-- list pronunciation substitutions
local rules = {
    [1] = {
        { "(" .. stress .. consonant .. "*" .. vowel .. ")nn", "%1tn" .. voiceless },
        { "(" .. vowel .. ")" .. "g" .. "([aʏðlr])", "%1ɣ%2" },
        { "(" .. vowel .. ")" .. "g" .. "([ji])", "%1j%2" },
        { "(" .. vowel .. ")" .. "[kg]" .. "([ts])", "%1x%2" },
        { "(" .. vowel .. ")" .. "p" .. "([tsk])", "%1f%2" },
        { "v" .. "([tsk])", "f%1" }
    },
    [2] = { -- set 2 only applies when special=false
        { "(u" .. nonsyllabic .. "?" .. long .. "?)[vɣ]", "%1" },
        { "kʏ(" .. long .. "?)ð", "kvʏ%1ð" }
    },
    [3] = {
        { "ng([ls])", "ŋ%1" },
        { "g", "k" },
        { "k(ʰ?[ɛiɪ])", "c%1" },
        { "k(ʰ?ai)", "c%1" },
        { "kj", "c" },
        { "(" .. long .. "?)jj", "i" .. nonsyllabic .. "%1j" },
        { "nk", "ŋk" },
        { "kc", "c" .. long },
        { "(.)%1", "%1" .. long }
    }
}

-- function to track accents
function export.markAccent(term, string)
    -- count number of compounds in term
    local _, term_count = gsub(term, "[%- ]", "")
    -- build default stress positions if no accent string provided
    if not string then
        local array = {}
        for i = 1, term_count + 1 do
            array[i] = "1"
        end
        return array
    end
    -- otherwise count number of commas in accent string
    local _, string_count = gsub(string, ",", "")

    -- ensure correct number of stress positions are present
    if term_count ~= string_count then
        error(format("Incorrect number of stress positions specified (%d). Specify %d stress positions.", string_count + 1, term_count + 1))
    else
        -- dash represents no stress in single compound words
        if term_count == 0 then
            string = gsub(string, "%-", "0")
            -- otherwise dash represents default initial stress
        else
            string = gsub(string, "%-", "1")
        end

        -- return stressed positions as comma-separated array
        return split(string, ",")
    end
end

-- function to determine vowel length
local function determineLength(v, next_chars)
    -- short if before x as it's treated like two consonants
    if find(next_chars, "x") then
        return v
        -- long if word-final, preceding a single consonant followed by a vowel
        -- or preceding the consonant clusters b/d/g/k/p/s/t + j/r/v
    elseif len(next_chars) <= 1 or
            find(next_chars, consonant .. "[^" .. consonants .. "%-]") or
            find(next_chars, "[bdgkpst][jrv]") then
        return v .. long
        -- short otherwise
    else
        return v
    end
end

-- function to determine vowel type
local function determineVowel(v, term, pos, is_stressed)
    -- check next two chars
    local next_chars = sub(term, pos + 1, pos + 2)

    -- before ng/nk
    if next_chars == "ng" or next_chars == "nk" then
        return data.vowels[v][3]
        -- before gi
    elseif next_chars == "gi" then
        return data.vowels[v][2]
        -- determine vowel length if stressed
    elseif is_stressed then
        return determineLength(data.vowels[v][1], next_chars)
        -- otherwise
    else
        return data.vowels[v][1]
    end
end

-- function to count syllables
local function countSyllables(term)
    local count = 0
    local poss = {}

    -- match positions of all vowels
    for i in gmatch(term, vowel) do
        count = count + 1
        table.insert(poss, i)
    end

    -- return syllable count
    return count, poss
end

-- function to generate rhyme
local function getRhyme(term)
    local count, poss = countSyllables(term)
    local start = 0

    -- mark start of rhyme
    if count == 1 then
        -- start at last syllable
        start = "-" .. term[poss[1]]
    else
        -- start at second-last syllable
        start = "-" .. term[poss[count - 1]]
    end

    -- return rhymes
    return sub(term, start)
end

-- function to generate transcription
function export.toIPA(term, accent, special)
    if type(term) ~= "string" then
        error('The function "toIPA" requires a string argument.')
    end
    local accent = export.markAccent(term, nil)

    -- initialise pronunciation
    term = lower(term)
    local IPA = {}
    local pos = 1
    local is_initial = true
    local compound_index = 1

    -- respell some letters that share pronunciations with other letters
    term = gsub(term, "c([eéiíyö])", "s%1")
    term = gsub(term, "[cwyýz]", { ["c"] = "k", ["w"] = "v", ["y"] = "i", ["ý"] = "í", ["z"] = "s" })

    -- get current accent value from array
    local current_accent = tonumber(accent[compound_index])

    -- handle string
    while pos <= len(term) do
        -- mark stress when current accent is 1
        if current_accent == 1 then
            table.insert(IPA, compound_index == 1 and primary_stress or secondary_stress)
            current_accent = current_accent - 1
        end

        -- handle consonant trigraphs
        if data.trigraphs[sub(term, pos, pos + 2)] then
            local trigraph = table.insert(IPA, data.trigraphs[sub(term, pos, pos + 2)])
            table.insert(IPA, type(trigraph) == "table" and (is_initial and trigraph[1] or trigraph[2]) or trigraph)
            pos = pos + 3
            is_initial = false
            -- handle consonant digraphs
        elseif data.digraphs[sub(term, pos, pos + 1)] then
            local digraph = data.digraphs[sub(term, pos, pos + 1)]
            -- special case for ll
            if sub(term, pos, pos + 1) == "ll" and special == true then
                table.insert(IPA, "ll")
            else
                table.insert(IPA, type(digraph) == "table" and (is_initial and digraph[1] or digraph[2]) or digraph)
            end
            pos = pos + 2
            is_initial = false
            -- handle vowel digraphs (au, ei, ey)
        elseif sub(term, pos, pos + 1) == "au" or sub(term, pos, pos + 1) == "ei" then
            table.insert(IPA, determineVowel(sub(term, pos, pos + 1), term, pos + 1, current_accent == 0))
            current_accent = current_accent - 1
            pos = pos + 2
            is_initial = false
            -- handle single consonant letters
        elseif data.single[sub(term, pos, pos)] then
            local single = data.single[sub(term, pos, pos)]
            table.insert(IPA, type(single) == "table" and (is_initial and single[1] or single[2]) or single)
            pos = pos + 1
            is_initial = false
            -- handle single vowels
        elseif data.vowels[sub(term, pos, pos)] then
            table.insert(IPA, determineVowel(sub(term, pos, pos), term, pos, current_accent == 0))
            current_accent = current_accent - 1
            pos = pos + 1
            is_initial = false
            -- handle compound stress
        elseif sub(term, pos, pos) == "-" then
            -- check error for invalid stress position
            if current_accent > 0 then
                error(format("Invalid stress position %s in compound %d", accent[compound_index], compound_index))
            end
            -- increment compound index
            compound_index = compound_index + 1
            current_accent = tonumber(accent[compound_index])
            pos = pos + 1
            is_initial = true
            -- otherwise
        else
            table.insert(IPA, sub(term, pos, pos))
            pos = pos + 1
            is_initial = false
        end
    end

    -- check error for invalid stress position
    if current_accent > 0 then
        error(format("Invalid stress position %s in compound %d", accent[compound_index], compound_index))
    end

    -- combine ipa symbols into single string
    local pron = table.concat(IPA)

    -- apply phonemic rules
    for i, set_of_rules in ipairs(rules) do
        -- only use set 2 if special=false
        if not (special and i == 2) then
            for _, rule in ipairs(set_of_rules) do
                local regex, replacement = rule[1], rule[2]
                pron = gsub(pron, regex, replacement)
            end
        end
    end

    -- remove secondary stress if primary and secondary stress are both one syllable only
    pron = gsub(pron, "([^" .. secondary_stress .. "]+)(" .. secondary_stress .. "[^" .. secondary_stress .. "]+)", function(a, b)
        local count_a, _ = countSyllables(a)
        local count_b, _ = countSyllables(b)
        return a .. (count_a == 1 and count_b == 1 and gsub(b, secondary_stress, "") or b)
    end)

    -- remove any unwanted characters (e.g. full stops and commas)
    pron = gsub(pron, "[%.,]", "")

    return pron
end

-- main export function
function export.show(frame)
    local p, results = {}, {}

    local args = frame:getParent().args
    if args[1] then
        for _, v in ipairs(args) do
            table.insert(p, (v ~= "") and v or nil)
        end
    else
        p = { mw.title.getCurrentTitle().text }
    end

    for i, word in ipairs(p) do
        local accent_param = args["accent" .. i] or (i == 1 and args.accent)
        local special_param = args["special" .. i] or (i == 1 and args.special)

        local accent = export.markAccent(word, accent_param)
        local special = require("yesno")(special_param)

        local ipa = export.toIPA(word, accent, special)
        table.insert(results, { pron = "/" .. ipa .. "/" })
    end

    return m_ipa.format_IPA_full { lang = lang, items = results }
end
local accent = export.markAccent("þorn", nil)
print(export.toIPA('þorn', accent, nil))
return export