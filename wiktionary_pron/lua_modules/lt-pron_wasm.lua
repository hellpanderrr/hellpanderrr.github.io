local export = {}
require('mw')

--local U = require("string/char")
local U = mw.ustring.char

local udecomp = mw.ustring.toNFD
local rsubn = mw.ustring.gsub
local sub = mw.ustring.sub
local rmatch = mw.ustring.match
local rfind = mw.ustring.find
local ugmatch = mw.ustring.gmatch
local ulen = mw.ustring.len
local ulower = mw.ustring.lower

-- version of rsubn() that discards all but the first return value
local function rsub(term, foo, bar, n)
    local retval = rsubn(term, foo, bar, n)
    return retval
end

-- unicode codepoints
local ACUTE = U(0x0301) -- acute =  ́
local GRAVE = U(0x0300) -- grave =  ̀
local CIRC = U(0x0302) -- circumflex =  ̂
local TILDE = U(0x0303) -- tilde =  ̃
local MACRON = U(0x0304) -- macron =  ̄
local BREVE = U(0x0306) -- breve =  ̆
local DOT = U(0x0307) -- dot above = ̇
local CARON = U(0x030C) -- caron =  ̌
local OGONEK = U(0x0328) -- ogonek =  ̨

-- character classes
local accents = ACUTE .. GRAVE .. CIRC .. TILDE .. MACRON .. BREVE
local diacritics = accents .. DOT .. CARON .. OGONEK
local vowels = "[aeiouy]"
local consonants = "[bcdfghklmnprstvzðþx]" -- does not include j

-- various substitutions
local subs = {
    glyphs = {
        ["ch"] = "ç",
        ["ts"] = "ć",
        ["dz"] = "ð",
        ["dz" .. CARON] = "þ",
        ["o" .. BREVE] = "ɔ"
    },
    ipa_c = {
        ["c" .. CARON] = "t͡ʃ",
        ["c"] = "t͡s",
        ["c" .. ACUTE] = "t͡s",
        ["ç"] = "x",
        ["þ"] = "d͡ʒ",
        ["ð"] = "d͡z",
        ["g"] = "ɡ",
        ["h"] = "ɣ",
        ["qu"] = "kʋ",
        ["q"] = "k",
        ["s" .. CARON] = "ʃ",
        ["v"] = "ʋ",
        ["z" .. CARON] = "ʒ"
    },
    ipa_v = {
        ["a"] = "ɐ",
        ["e"] = "ɛ",
        ["i"] = "ɪ",
        ["u"] = "ʊ"
    }
}

local lang = require("languages").getByCode("lt")

function export.link(term)
    return require("links").full_link { term = term, lang = lang }
end

--[=[
Takes the orthographic representation to make it closer
to the phonological output by respelling and adding missing segments
]=]
function export.respell(term)
    -- decompose accents from term
    term = udecomp(term)

    -- replace digraph consonants with temporary placeholders
    term = rsub(term, ".[" .. CARON .. BREVE .. "hsz]?", subs.glyphs)

    -- add missing /j/: ievà > jievà
    if rfind(term, "^i[" .. ACUTE .. GRAVE .. "]?e" .. TILDE .. "?") then
        term = "j" .. term
    end
    -- pãieškos > pãjieškos
    term = rsub(
            term,
            "(" .. vowels .. "[" .. diacritics .. "]*)" .. "(i[" .. ACUTE .. GRAVE .. "]?e" .. TILDE .. "?)",
            "%1j%2"
    )

    -- show palatalisation
    term = rsub(term, "i([aou][" .. accents .. "]*)(.?)",
            function(vow, next_char)
                if next_char == "u" then
                    return "i" .. vow .. next_char
                else
                    return "ʲ" .. vow .. next_char
                end
            end
    )
    term = rsub(term, "(" .. consonants .. CARON .. "?)([iejy])", "%1ʲ%2")
    term = rsub(term, "(" .. consonants .. "+)(" .. consonants .. "ʲ)",
            function(cons, soft)
                local out = ""
                for c in ugmatch(cons, ".") do
                    -- k does not become palatalised: krienas, apniūkti do not have kʲ
                    if c == "k" then
                        out = out .. c
                    else
                        out = out .. c .. "ʲ"
                    end
                end
                return out .. soft
            end
    )
    print(term)
    return term
end

--[=[
Splits the term into its syllable boundaries
]=]
function export.syllabify(term, table)
    term = rsub(term,
            "([aeioɔuy" .. diacritics ..
                    "]*[^aeioɔuy]-)([sz]?" .. CARON .. "?ʲ?[ptkbdðþgçćc]?" .. CARON .. "?ʲ?[lmnrvj]?ʲ?[aeioɔuy])",
            "%1.%2"
    )
    term = rsub(term, "^%.", "")
    term = rsub(term, "%.ʲ", "ʲ.")
    term = rsub(term, "%.([ptbdðþ]ʲ?)([mn])", "%1.%2")
    print(term)
    return table and ugmatch(term, ".") or term
end

--[=[
Render pronunciation
]=]
local function pron(term)
    -- replace consonants with their ipa equivalents
    term = rsub(term, ".[" .. CARON .. "u]?", subs.ipa_c)

    -- consonant allophones
    term = rsub(term, "ʃʲ", "ɕ")
    term = rsub(term, "ʒʲ", "ʑ")
    term = rsub(term, "l([^ʲ])", "ɫ%1")
    term = rsub(term, "n(ʲ?%.?[kɡ])", "ŋ%1")

    -- vowels
    term = rsub(term,
            "^([^%." .. ACUTE .. GRAVE .. TILDE .. "]-[" .. ACUTE .. GRAVE .. TILDE .. "])",
            "ˈ%1"
    )
    term = rsub(term,
            "%.([^%." .. ACUTE .. GRAVE .. TILDE .. "]-[" .. ACUTE .. GRAVE .. TILDE .. "])",
            "ˈ%1"
    )
    -- diphtongs
    term = rsub(term, "ia" .. ACUTE .. "u", "æ" .. CIRC .. "ʊ")
    term = rsub(term, "iau" .. TILDE .. "?", "ɛʊ")
    term = rsub(term, "au" .. TILDE .. "?", "ɐʊ̯")
    term = rsub(term, "a" .. ACUTE .. "i", "ɐ" .. CIRC .. "ɪ")
    term = rsub(term, "ai" .. TILDE .. "?", "ɐɪ")
    term = rsub(term, "e" .. ACUTE .. "i", "ɛ" .. CIRC .. "ɪ")
    term = rsub(term, "ei" .. TILDE .. "?", "ɛɪ")
    term = rsub(term, "a" .. ACUTE .. "u", "a" .. CIRC .. "ʊ")
    term = rsub(term, "au" .. TILDE .. "?", "ɒʊ")
    term = rsub(term, "e" .. ACUTE .. "u", "ɛ" .. CIRC .. "ʊ")
    term = rsub(term, "eu" .. TILDE .. "?", "ɛʊ")
    term = rsub(term, "i" .. ACUTE .. "e", "i" .. CIRC .. "ə")
    term = rsub(term, "ie" .. TILDE .. "?", "iə")
    term = rsub(term, "u" .. ACUTE .. "o", "u" .. CIRC .. "ə")
    term = rsub(term, "uo" .. TILDE .. "?", "uə")
    term = rsub(term, "u" .. ACUTE .. "i", "ʊ" .. CIRC .. "ɪ")
    term = rsub(term, "ui" .. TILDE .. "?", "ʊɪ")
    term = rsub(term, "o" .. ACUTE .. "u", "ɔ" .. CIRC .. "ɪ")
    term = rsub(term, "u" .. ACUTE .. "u", "ɔ" .. CIRC .. "ʊ")

    term = rsub(term, "a", "ɐ")
    term = rsub(term, "ɐ" .. ACUTE, "âː")
    term = rsub(term, "ɐ" .. TILDE, "aː")

    term = rsub(term, "e", "ɛ")
    term = rsub(term, "ɛ" .. DOT, "eː")
    term = rsub(term, "ɛ" .. OGONEK, "æː")

    term = rsub(term, "i", "ɪ")
    term = rsub(term, "ɪ" .. OGONEK, "iː")

    term = rsub(term, "y", "iː")

    term = rsub(term, "u", "ʊ")
    term = rsub(term, "ʊ" .. MACRON, "uː")
    term = rsub(term, "ʊ" .. OGONEK, "uː")

    term = rsub(term, "o" .. TILDE .. "?", "oː")
    term = rsub(term, "ʲaː", "ʲæː")
    term = rsub(term, "ʲɐ", "ʲɛ")

    term = rsub(term, "ː" .. ACUTE, CIRC .. "ː") -- acutes = stressed + circumflex tone
    term = rsub(term, TILDE, "") -- tilde = stressed + long
    term = rsub(term, GRAVE, "") -- grave = stressed + short

    term = rsub(term, "([ʲj])a(" .. OGONEK .. "?)", "%1e%2")
    return term
end

--[=[
	Returns the respelled term and its pronunciation
]=]
function export.test_respell(frame)
    local args = require("parameters").process(frame:getParent().args, { [1] = { default = "" } })
    local syll = export.syllabify(export.respell(args[1]))

    return syll .. " → [" .. pron(syll) .. "]"
end

--[=[
Converts the term to IPA
]=]
function export.toIPA(text)
    return pron(ulower(export.syllabify(export.respell(text))))
end

--[=[
	Displays the IPA of the term
]=]
function export.show(frame)
    local params = {
        [1] = { default = mw.title.getCurrentTitle().text }
    }
    local args = require("parameters").process(frame:getParent().args, params)

    return args[1]
end

print(export.toIPA("gyvẽnimas"))

return export