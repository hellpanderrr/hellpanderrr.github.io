local export = {}
local mn = require("mn-common")
local gsub = mw.ustring.gsub
local u = require("string/char")

-- CHANGED: Initial short vowels. 'э' merges to 'i' in Standard Halh (Svantesson 1.1).
local vowels1 = {
    ['а'] = 'a', ['о'] = 'ɔ', ['у'] = 'ʊ',
    ['э'] = 'i', -- Was 'e'
    ['ө'] = 'ɵ', ['ү'] = 'u',
    ['и'] = 'i', ['й'] = 'i', ['ы'] = 'i', --й very occasionally used at the start of loanwords
    ['я'] = 'ja', ['ю'] = 'jʊ', ['ё'] = 'jɔ', ['е'] = 'jɵ',
    ['ъ'] = '', ['ә'] = 'ə',
}

-- ADDED: Non-initial short vowels reduce to schwa (Svantesson 6.3).
local vowels1_reduced = {
    ['а'] = 'ə', ['о'] = 'ə', ['у'] = 'ə',
    ['э'] = 'ə', ['ө'] = 'ə', ['ү'] = 'ə',
    ['и'] = 'i', ['й'] = 'i', ['ы'] = 'i', -- /i/ is generally stable/transparent
    ['я'] = 'jə', ['ю'] = 'jə', ['ё'] = 'jə', ['е'] = 'jə',
    ['ъ'] = '', ['ә'] = 'ə',
}

-- CHANGED: Diphthongs restored (Svantesson 1.2). Removed Inner Mongolian monophthongization.
local vowels2 = {
    ['аа'] = 'aː', ['ай'] = 'ai', ['яа'] = 'jaː', ['яй'] = 'jai', ['ъя'] = 'ja', ['ао'] = 'ɒː', ['ау'] = 'aʊ̯', ['яу'] = 'jaʊ̯',
    ['оо'] = 'ɔː', ['ой'] = 'ɔi', ['ёо'] = 'jɔː', ['ёй'] = 'jɔi', ['ъё'] = 'jɔ', ['оа'] = 'ʊ̯a', ['ёу'] = 'joʊ',
    ['уу'] = 'ʊː', ['уй'] = 'ʊi', ['уа'] = 'u̯a', ['юу'] = 'jʊː', ['юй'] = 'jʊi', ['уи'] = 'u̯iː',
    ['ээ'] = 'eː', ['эй'] = 'ei', ['еэ'] = 'jeː', ['ей'] = 'jei', ['еа'] = 'ia', ['ео'] = 'eɔ', ['еу'] = 'iʊ̯', ['еү'] = 'iuː',
    ['өө'] = 'ɵː', ['өй'] = 'ɵi', ['ье'] = 'jɵ',
    ['үү'] = 'uː', ['үй'] = 'ui', ['юү'] = 'juː', ['юй'] = 'jui',
    ['ии'] = 'iː', ['ий'] = 'iː', ['иа'] = 'i̯aː', ['ио'] = 'i̯oː', ['иу'] = 'i̯ʊː', ['иэ'] = 'i̯eː', ['иө'] = 'i̯ɵː', ['иү'] = 'i̯uː',
}

local vowels3 = {
    ['ъяа'] = 'jaː', ['ъёо'] = 'jɔː', ['ьеэ'] = 'jeː',
    ['яай'] = 'jɛː', ['уай'] = 'u̯ɛː', ['ёий'] = 'jiː',
    ['аоа'] = 'aʊ̯a',
}

-- CHANGED: Mapped lenis series to voiced symbols (b, d, g...) for broad transcription consistency.
local consonants1 = {
    ['п'] = 'pʰ', ['б'] = 'b', ['т'] = 'tʰ', ['д'] = 'd', ['к'] = 'kʰ', ['г'] = 'ɡ',
    ['ц'] = 't͡sʰ', ['з'] = 'd͡z', ['ч'] = 't͡ɕʰ', ['ж'] = 'd͡ʒ',
    ['ф'] = 'f', ['в'] = 'w̜', ['с'] = 's', ['ш'] = 'ɕ', ['щ'] = 'ɕ', ['х'] = 'x',
    ['м'] = 'm', ['н'] = 'n',
    ['р'] = 'r', ['л'] = 'ɮ',
    ['ь'] = 'ʲ',
}

local consonants2 = {
    ['бб'] = 'b',
    ['вб'] = 'b',
    ['дд'] = 't͉.t',
    ['лл'] = 'ɮː', ['лх'] = 'ɬʰ',
    ['мм'] = 'mː',
    ['нб'] = 'mp', ['нн'] = 'nː',
    ['рк'] = 'r̥kʰ', ['рп'] = 'r̥pʰ', ['рт'] = 'r̥tʰ', ['рц'] = 'r̥t͡sʰ', ['рч'] = 'r̥t͡ɕʰ',
    ['сс'] = 'sː',
}

local double_consonants = {
    ['пп'] = 'п', ['тт'] = 'т', ['кк'] = 'к', ['гг'] = 'г',
    ['цц'] = 'ц', ['зз'] = 'з', ['чч'] = 'ч', ['жж'] = 'ж',
    ['фф'] = 'ф', ['вв'] = 'в', ['шш'] = 'ш', ['щщ'] = 'щ', ['хх'] = 'х',
    ['рр'] = 'р',
}

local palatalisation = {
    ['пе'] = 'пʲө', ['пю'] = 'пʲу', ['пё'] = 'пʲо', ['пя'] = 'пʲа',
    ['бе'] = 'бʲө', ['бю'] = 'бʲу', ['бё'] = 'бʲо', ['бя'] = 'бʲа',
    ['те'] = 'тʲө', ['тю'] = 'тʲу', ['тё'] = 'тʲо', ['тя'] = 'тʲа',
    ['де'] = 'дʲө', ['дю'] = 'дʲу', ['дё'] = 'дʲо', ['дя'] = 'дʲа',
    ['ке'] = 'кʲө', ['кю'] = 'кʲу', ['кё'] = 'кʲо', ['кя'] = 'кʲа',
    ['ге'] = 'гʲө', ['гю'] = 'гʲу', ['гё'] = 'гʲо', ['гя'] = 'гʲа',
    ['фе'] = 'фʲө', ['фю'] = 'фʲу', ['фё'] = 'фʲо', ['фя'] = 'фʲа',
    ['ве'] = 'вʲө', ['вю'] = 'вʲу', ['вё'] = 'вʲо', ['вя'] = 'вʲа',
    ['хе'] = 'хʲө', ['хю'] = 'хʲу', ['хё'] = 'хʲо', ['хя'] = 'хʲа',
    ['ме'] = 'мʲө', ['мю'] = 'мʲу', ['мё'] = 'мʲо', ['мя'] = 'мʲа',
    ['не'] = 'нʲө', ['ню'] = 'нʲу', ['нё'] = 'нʲо', ['ня'] = 'нʲа',
    ['ре'] = 'рʲө', ['рю'] = 'рʲу', ['рё'] = 'рʲо', ['ря'] = 'рʲа',
    ['ле'] = 'лʲө', ['лю'] = 'лʲу', ['лё'] = 'лʲо', ['ля'] = 'лʲа',
}

function export.to_IPA(text)

    local orig_text = text
    text = mw.ustring.lower(text)

    text = gsub(text, '-', '')

    text = gsub(text, "ы$", "ы~")
    text = gsub(text, "ы(%s)", "ы~%1")

    -- CHANGED: Removed stress logic (Svantesson Ch 7: Stress is non-phonemic).
    -- text = gsub(text, "'", u(0x02C8))
    -- ... (block generating stress marks commented out/removed) ...

    for k, v in pairs(double_consonants) do
        text = gsub(text, k, v)
        text = gsub(text, k, v) --remove double consonants
    end
    for k, v in pairs(palatalisation) do
        text = gsub(text, k, v)
        text = gsub(text, k, v) --convert iotated vowels following consonants
    end

    -- Process syllables for vowel reduction
    -- CHANGED: Replaced simple gsub logic with syllable-aware processing
    local syllables_list = mn.syllables(text)
    local processed_sylls = {}

    for i, syl in ipairs(syllables_list) do
        -- Apply long vowels/diphthongs (independent of position)
        for k, v in pairs(vowels3) do
            syl = gsub(syl, k, v)
        end
        for k, v in pairs(vowels2) do
            syl = gsub(syl, k, v)
        end

        -- Apply short vowels (Position dependent)
        if i == 1 then
            -- Initial syllable: Full vowels (e.g. 'э' -> 'i')
            syl = gsub(syl, '[аоуэөүийяюёеъә]', vowels1)
        else
            -- Non-initial syllable: Reduced vowels (e.g. 'а' -> 'ə')
            syl = gsub(syl, '[аоуэөүийяюёеъә]', vowels1_reduced)
        end

        table.insert(processed_sylls, syl)
    end
    text = table.concat(processed_sylls, "")

    for k, v in pairs(consonants2) do
        text = gsub(text, k, v)
        text = gsub(text, k, v)
    end

    -- CHANGED: Commented out Russian loanword spirantization rule (Svantesson 3.3)
    -- text = gsub(text, '([aɛoɔʊi̯eɵuə])p([aɛoɔʊi̯eɵuə])', '%1β%2')

    text = gsub(text, '[бвгджзйклмнпрстфхцчшщь]%*?', consonants1)
    text = gsub(text, '([aɛoɔʊi̯eɵuə])t͡ɕ([aɛoɔʊi̯eɵuə])', '%1d͡ʑ%2')
    text = gsub(text, '([aɛoɔʊi̯eɵuə])p([aɛoɔʊi̯eɵuə])', '%1β%2')
    text = gsub(text, '([aɛoɔʊi̯eɵuə])k([aɛoɔʊi̯eɵuə])', '%1ɣ%2')
    text = gsub(text, 'n([%sˈ]*)%f[pbmf]', 'm%1')

    -- CHANGED: Included 'x' (and new 'ɡ') in nasal assimilation (Svantesson 2.3, 5.3)
    text = gsub(text, 'n%f[ɡɢkxʃ%s%p%z]', 'ŋ')

    text = gsub(text, 'r%f[%s%p%z]', 'r̥')

    text = gsub(text, '([aɔuʊ])i%f[%s%p%z]', '%1ⁱ')

    -- Keep final vowel deletion (standard practice for 'n' stems etc)
    if #mn.syllables(orig_text) ~= 1 then
        text = gsub(text, '[aeiɔɵuʊə]%f[%s%p%z]', '')
    end

    text = gsub(text, 'ⁱ', 'i')
    text = gsub(text, 'ʲj', 'j')

    --put ~ at the end of respelling to prevent vowel cutoff
    text = gsub(text, '~', '')

    return text

end

-- only works with Cyrillic Mongolian
function export.show(frame)
    local args = frame:getParent().args
    local page_title = mw.title.getCurrentTitle().text
    local text = args[1] or page_title
    local qualifier = args["q"] or nil
    local lang = require("Module:languages").getByCode("mn")
    local script = require("Module:scripts").getByCode("Cyrl")

    local syllables = mn.syllables(text)
    local transcription = export.to_IPA(text)
    local IPA = "<li>" .. (qualifier and require("Module:qualifier").format_qualifier { qualifier } .. " " or "") ..
            require("Module:IPA").format_IPA_full {
                lang = lang,
                items = { { pron = "/" .. transcription .. "/" } },
            } .. "</li>"
    local hyphenation = "<li>" .. require("Module:hyphenation").format_hyphenations {
        lang = lang,
        hyphs = { { hyph = syllables } },
        sc = script,
        caption = "[[syllabification|Syllabification]]",
    } .. mw.ustring.char(0x2002) .. "(" .. #syllables .. " syllable"
    if #syllables >= 2 then
        hyphenation = hyphenation .. "s"
    end
    hyphenation = hyphenation .. ")</li>"

    return "<ul>" .. IPA .. hyphenation .. "</ul>"
end

print(export.to_IPA("абстракт"))
return export