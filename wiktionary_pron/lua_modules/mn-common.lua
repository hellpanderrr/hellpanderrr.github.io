local m_str_utils = require("string utilities")
local m_table = require("table_new")
local export = {}

local concat = table.concat
local find = m_str_utils.find
local insert = table.insert
local len = m_str_utils.len
local match = m_str_utils.match
local gmatch = m_str_utils.gmatch
local sub = m_str_utils.sub
local gsub = m_str_utils.gsub
local lower = m_str_utils.lower
local reverse = m_str_utils.reverse
local reverse_array = m_table.reverse

local remove_duplicates = m_table.removeDuplicates
local sort = table.sort
local u = m_str_utils.char

export.FVS1 = u(0x180B)
export.FVS2 = u(0x180C)
export.FVS3 = u(0x180D)
export.FVS4 = u(0x180F)
export.MVS = u(0x180E)
export.NNBSP = u(0x202F)
export.stem_barrier = u(0xF000)

local function format_Mongolian_text(text)
    return "<span class=\"Mong\" lang=\"mn\">" .. text .. "</span>"
end

function export.see(frame)
    local params = {
        [1] = {},
    }

    local args = require("parameters").process(frame:getParent().args, params)
    local title = args[1]
    local curr_title = mw.title.getCurrentTitle().subpageText
    local content = mw.title.new(title):getContent()
    local senses = {}
    local sense_id = 0
    local j, pos, s, section

    if title == curr_title then
        return error("The soft-directed item is the same as the page title.")
    end

    if content then
        if not match(content, "==Mongolian==") then
            categories = categories .. "[[Category:Mongolian redlinks/mn-see]]"
        elseif not match(content, "mn%-IPA") and not match(content, "mn%-see") then
            require("debug").track("mn-see/unidirectional reference to variant")
        elseif not match(content, curr_title) then
            require("debug").track("mn-see/unidirectional reference variant→orthodox")
        end
    end

    while true do
        _, j, language_name, s = content:find("%f[=]==%s*([^=]+)%s*==(\n.-)\n==%f[^=]", pos)

        if j == nil then
            i, j, language_name, s = content:find("%f[=]==%s*([^=]+)%s*==(\n.+)", pos)
        end

        if j == nil then
            break
        else
            pos = j - 1
        end

        if language_name == "Mongolian" then
            section = s
        end
    end

    if not section then
        return ""
    end

    section = section:gsub("\n===+Etymology.-(\n==)", "%1")

    local text = {}

    for sense in section:gmatch("\n# ([^\n]+)") do
        if not sense:match("rfdef") and not sense:match("defn") then
            sense_id = sense_id + 1
            insert(senses, sense)
        end
    end
    insert(text, concat(senses, "\n# "))

    insert(text, "</div>")

    return frame:preprocess(concat(text))

end

function export.ipasee(frame)
    local params = {
        [1] = {},
    }

    local args = require("parameters").process(frame:getParent().args, params)
    local title = args[1]
    local curr_title = mw.title.getCurrentTitle().subpageText
    local content = mw.title.new(title):getContent()
    local senses = {}
    local sense_id = 0
    local j, pos, s, section

    if title == curr_title then
        return error("The soft-directed item is the same as the page title.")
    end

    if content then
        if not match(content, "==Mongolian==") then
            categories = categories .. "[[Category:Mongolian redlinks/mn-IPA-see]]"
        elseif not match(content, "mn%-IPA") and not match(content, "mn%-see") and not match(content, "mn%-IPA-see") then
            require("debug").track("mn-IPA-see/unidirectional reference to variant")
        elseif not match(content, curr_title) then
            require("debug").track("mn-IPA-see/unidirectional reference variant→orthodox")
        end
    end

    while true do
        _, j, language_name, s = content:find("%f[=]==%s*([^=]+)%s*==(\n.-)\n==%f[^=]", pos)

        if j == nil then
            i, j, language_name, s = content:find("%f[=]==%s*([^=]+)%s*==(\n.+)", pos)
        end

        if j == nil then
            break
        else
            pos = j - 1
        end

        if language_name == "Mongolian" then
            section = s
        end
    end

    if not section then
        return ""
    end

    section = section:gsub("\n===+Etymology.-(\n==)", "%1")

    local text = {}

    if section:match("{{mn-IPA%|([^\n]+)}}") then
        return frame:expandTemplate { title = "mn-IPA", args = { section:match("{{mn-IPA%|([^\n]+)}}") } }
    else
        return frame:expandTemplate { title = "mn-IPA", args = { title } }
    end


end

--Breaks down a string into vowel harmonic segments
function export.vowelharmony(text, params)

    if not params then
        params = {}
    end

    local vh = {}
    local breaks = { 1 }

    local switchers = { "ау", "оу", "уу", "иу", "яу", "ёу", "еу", "юу", "уй", "эү", "өү", "үү", "иү", "еү", "юү", "үй", " ", "-" }
    local switchers2 = { "аа", "оо", "өө", "ээ", "яа", "ёо", "еө", "еэ", "Аа", "Оо", "Өө", "Ээ", "Яа", "Ёо", "Еө", "Еэ" }

    for _, v in pairs(switchers) do
        v = gsub(v, "(.)(.)", "%1" .. u(0x301) .. "?" .. u(0x300) .. "?%2")
        local c = 0
        while c ~= nil do
            c = find(lower(text), v, c + 1)
            if c ~= nil and c ~= 1 then
                insert(breaks, c)
            end
        end
    end

    if params.bor then
        for _, v in pairs(switchers2) do
            if match(text, v .. "$") then
                insert(breaks, len(text) - 1)
            end
        end
    end

    sort(breaks)

    for i, b in ipairs(breaks) do
        insert(vh, { Cyrl = {}, Mong = {} })
        if i == #breaks then
            vh[i].substring = sub(text, b, len(text))
        else
            vh[i].substring = sub(text, b, breaks[i + 1] - 1)
        end
    end

    if params.bor then
        for i, s in ipairs(vh) do
            vh[i] = { Cyrl = {}, Mong = {} }
            local orig_text = s.substring
            s.substring = lower(s.substring)
            if params.bor == "Russian" then
                s.substring = gsub(s.substring, "у", "ү")
            end
            local substring_nostress = gsub(s.substring, "[" .. u(0x301) .. u(0x300) .. "]", "")
            if match(s.substring, "кило" .. u(0x301) .. "?$") then
                -- irregular
                vh[i].Cyrl.a = "э"
                vh[i].location = find(s.substring, "[эүею]")
                vh[i].position = "front"
                vh[i].quality = "unrounded"
            elseif match(substring_nostress, "[аеёиоөуүэюя]у") or match(substring_nostress, "уй") then
                vh[i].Cyrl.a = "а"
                vh[i].location = 1
                vh[i].position = "back"
                vh[i].quality = "unrounded"
            elseif match(substring_nostress, "[аеёиоөуүэюя]ү") or match(substring_nostress, "үй") then
                vh[i].Cyrl.a = "э"
                vh[i].location = 1
                vh[i].position = "front"
                vh[i].quality = "unrounded"
            elseif match(s.substring, "[ауяᠠᠣᠤ]" .. u(0x301)) then
                vh[i].Cyrl.a = "а"
                vh[i].location = find(s.substring, u(0x301)) - 1
                vh[i].position = "back"
                vh[i].quality = "unrounded"
            elseif match(s.substring, "[оё]" .. u(0x301)) then
                vh[i].Cyrl.a = "о"
                vh[i].location = find(s.substring, u(0x301)) - 1
                vh[i].position = "back"
                vh[i].quality = "rounded"
            elseif (match(substring_nostress, "[ауяоё]") and (find(substring_nostress, "[ауяоё]") == find(substring_nostress, "[ауя]"))) or match(substring_nostress, "[ᠠᠣᠤ]") then
                vh[i].Cyrl.a = "а"
                vh[i].location = find(substring_nostress, "[ауя]")
                vh[i].position = "back"
                vh[i].quality = "unrounded"
            elseif match(substring_nostress, "[ауяоё]") and find(substring_nostress, "[ауяоё]") == find(substring_nostress, "[оё]") then
                vh[i].Cyrl.a = "о"
                vh[i].location = find(substring_nostress, "[оё]")
                vh[i].position = "back"
                vh[i].quality = "rounded"
            elseif (match(substring_nostress, "[эүеюө]") and find(substring_nostress, "[эүеюө]") == find(substring_nostress, "[эүею]")) or match(substring_nostress, "[ᠡᠥᠦᠧ]") then
                vh[i].Cyrl.a = "э"
                vh[i].location = find(substring_nostress, "[эүею]")
                vh[i].position = "front"
                vh[i].quality = "unrounded"
            elseif match(substring_nostress, "[эүеюө]") and find(substring_nostress, "[эүеюө]") == find(substring_nostress, "ө") then
                vh[i].Cyrl.a = "ө"
                vh[i].location = find(substring_nostress, "ө")
                vh[i].position = "front"
                vh[i].quality = "rounded"
            else
                vh[i].Cyrl.a = "э"
                vh[i].location = find(substring_nostress, "и") or 1
                vh[i].position = "front"
                vh[i].quality = "unrounded"
            end
            if match(vh[i].Cyrl.a, "[ао]") then
                vh[i].Cyrl.ii = "ы"
                vh[i].Cyrl.u = "у"
                vh[i].Mong.a = "ᠠ"
                vh[i].Mong.u = "ᠤ"
            else
                vh[i].Cyrl.ii = "ий"
                vh[i].Cyrl.u = "ү"
                vh[i].Mong.a = "ᠡ"
                vh[i].Mong.u = "ᠦ"
            end
            if match(vh[i].Cyrl.a, "ө") then
                -- ө takes the diphthong эй not өй
                vh[i].Cyrl.ai = "эй"
            else
                vh[i].Cyrl.ai = vh[i].Cyrl.a .. "й"
            end
            vh[i].Cyrl.aa = vh[i].Cyrl.a .. vh[i].Cyrl.a
            vh[i].Cyrl.uu = vh[i].Cyrl.u .. vh[i].Cyrl.u
            vh[i].substring = orig_text
        end
    else
        local location
        local pattern
        for i, s in ipairs(vh) do
            local orig = s.substring
            s.substring = reverse(lower(s.substring))
            local vowel = match(s.substring, "[аеёоөуүэюя]")
            location = (find(s.substring, "[аеёоөуүэюя]"))
            if vh[i].Cyrl.a == nil then
                vh[i].Cyrl.a = "э"
                vh[i].position = "front"
                vh[i].quality = "unrounded"
                pattern = "и"
            end
            vh[i].Cyrl.a = lower(vh[i].Cyrl.a)
            if vowel == "а" or vowel == "у" or vowel == "я" then
                vh[i].Cyrl.a = "а"
                vh[i].position = "back"
                vh[i].quality = "unrounded"
                pattern = "[ауюя]"
                if match(s.substring, "[еёоөүэ]") then
                    vh[i].violation = true
                else
                    vh[i].violation = false
                end
            elseif vowel == "о" or vowel == "ё" then
                vh[i].Cyrl.a = "о"
                vh[i].position = "back"
                vh[i].quality = "rounded"
                pattern = "[ёо]"
                if match(s.substring, "[аеөуүэюя]") then
                    vh[i].violation = true
                else
                    vh[i].violation = false
                end
            elseif vowel == "э" then
                vh[i].position = "front"
                if location and sub(s.substring, location - 1, location - 1) == "й" and match(s.substring, "[аеёоөуүэюя]", location + 1) == "ө" then
                    vh[i].Cyrl.a = "ө"
                    vh[i].quality = "rounded"
                    pattern = "[еө]"
                    if match(s.substring, "[аёоуүэюя]") then
                        vh[i].violation = true
                    else
                        vh[i].violation = false
                    end
                else
                    vh[i].Cyrl.a = "э"
                    vh[i].quality = "unrounded"
                    pattern = "[еүэю]"
                    if match(s.substring, "[аёоөуя]") then
                        vh[i].violation = true
                    else
                        vh[i].violation = false
                    end
                end
            elseif vowel == "ү" then
                vh[i].Cyrl.a = "э"
                vh[i].position = "front"
                vh[i].quality = "unrounded"
                pattern = "[еүэю]"
                if match(s.substring, "[аёоөуя]") then
                    vh[i].violation = true
                else
                    vh[i].violation = false
                end
            elseif vowel == "ө" then
                vh[i].Cyrl.a = "ө"
                vh[i].position = "front"
                vh[i].quality = "rounded"
                pattern = "[еө]"
                if match(s.substring, "[аёоуүэюя]") then
                    vh[i].violation = true
                else
                    vh[i].violation = false
                end
            elseif vowel == "е" then
                vh[i].position = "front"
                if match(s.substring, "ө", location + 1) then
                    vh[i].Cyrl.a = "ө"
                    vh[i].quality = "rounded"
                    pattern = "[еө]"
                    if match(s.substring, "[аёоуүэюя]") then
                        vh[i].violation = true
                    else
                        vh[i].violation = false
                    end
                else
                    vh[i].Cyrl.a = "э"
                    vh[i].quality = "unrounded"
                    pattern = "[еүэю]"
                    if match(s.substring, "[аёоөуя]") then
                        vh[i].violation = true
                    else
                        vh[i].violation = false
                    end
                end
            elseif vowel == "ю" then
                vh[i].quality = "unrounded"
                if match(s.substring, "[ауя]", location + 1) then
                    vh[i].Cyrl.a = "а"
                    vh[i].position = "back"
                    pattern = "[ауюя]"
                    if match(s.substring, "[еёоөүэ]") then
                        vh[i].violation = true
                    else
                        vh[i].violation = false
                    end
                else
                    vh[i].Cyrl.a = "э"
                    vh[i].position = "front"
                    pattern = "[еүэю]"
                    if match(s.substring, "[аёоөуя]") then
                        vh[i].violation = true
                    else
                        vh[i].violation = false
                    end
                end
            end
            location = 0
            local function prev_vowel(n)
                return match(s.substring, "[аеёиоөуүэюя]", n + 1)
            end
            local function prev_hvowel(n)
                return match(s.substring, pattern, n + 1)
            end
            while prev_vowel(location) and (prev_vowel(location) == prev_hvowel(location) or prev_vowel(location) == "и") do
                if prev_vowel(location) == prev_hvowel(location) then
                    location = find(s.substring, pattern, location + 1)
                else
                    -- if и
                    local icheck = location + 1
                    while prev_vowel(icheck) == "и" do
                        icheck = find(s.substring, "и", icheck + 1)
                    end
                    if prev_vowel(icheck) and prev_vowel(icheck) == prev_hvowel(icheck) then
                        location = icheck
                    elseif not prev_vowel(icheck) and vowel == "э" then
                        location = icheck
                    elseif vowel == "э" and sub(s.substring, icheck - 1, icheck - 1) == "й" then
                        location = icheck
                    else
                        break
                    end
                end
            end
            if match(vh[i].Cyrl.a, "[ао]") then
                vh[i].Cyrl.ii = "ы"
                vh[i].Cyrl.u = "у"
                vh[i].Mong.a = "ᠠ"
                vh[i].Mong.u = "ᠤ"
            else
                vh[i].Cyrl.ii = "ий"
                vh[i].Cyrl.u = "ү"
                vh[i].Mong.a = "ᠡ"
                vh[i].Mong.u = "ᠦ"
            end
            if match(vh[i].Cyrl.a, "ө") then
                -- ө takes the diphthong эй not өй
                vh[i].Cyrl.ai = "эй"
            else
                vh[i].Cyrl.ai = vh[i].Cyrl.a .. "й"
            end
            vh[i].Cyrl.aa = vh[i].Cyrl.a .. vh[i].Cyrl.a
            vh[i].Cyrl.uu = vh[i].Cyrl.u .. vh[i].Cyrl.u
            s.substring = orig
            vh[i].location = len(s.substring) + breaks[i] - location
        end
    end

    return vh
end

--Breaks down a string into syllables and returns a table
function export.syllables(text, params)

    local consonant = "[БВГДЖЗКЛМНПРСТФХЦЧШЩбвгджзклмнпрстфхцчшщ]"
    local vowel = "[АОУЭӨҮИЙЫЯЕЁЮаоуэөүийыяеёю]"
    local sign = "[ЪЬъь]"
    local iotated = "[ЯЕЁЮяеёю]"
    local punctuation = "[%s%p]"
    local final_clusters = require("mn.data").syll_final_cons
    local stress = u(0x301) .. u(0x300)

    -- Strip diacritics.
    local chars = {}
    for v in gmatch(text, "[%w%s%p" .. stress .. export.stem_barrier .. "]") do
        insert(chars, v)
    end

    local breaks = {}
    for i, v in pairs(chars) do
        -- First letter.
        if i == 1 or match(chars[i - 1], punctuation) then
            insert(breaks, i)
            -- Stem barrier is used by the inflection templates.
        elseif match(chars[i - 1], export.stem_barrier) then
            insert(breaks, i)
            -- If a vowel preceded by a hard sign or the temporary break character, then must be the break.
        elseif match(v, vowel) and match(chars[i - 1], "[Ъъ]") then
            insert(breaks, i)
            -- If Е/е preceded by a soft sign, count backwards until vowel, punctuation/space or start of string is found; if a vowel is found first, then preceding sign must be medial, so is the break; if punctuation/start of string found first, letter is part of word-initial cluster, so is not the break (occurs in loanwords, e.g. Вьет|нам ("Vietnam")).
        elseif match(v, "[Ее]") and match(chars[i - 1], "[Ьь]") then
            local j = i - 1
            while j > 1 and (match(chars[j], consonant) or match(chars[j], sign) or match(chars[j], "[" .. stress .. "]")) do
                j = j - 1
                if match(chars[j], vowel) then
                    -- If break, replaces the consonant preceding the soft sign as the break.
                    if breaks[#breaks] == i - 2 then
                        breaks[#breaks] = nil
                    end
                    insert(breaks, i)
                end
            end
            -- If Ю/ю preceded by a soft sign, calculate vowel harmony and iterate through vowel harmonic segments until reaching the one the letter is in; once found, if front harmonic then letter is the break.
        elseif match(v, "[Юю]") and match(chars[i - 1], "[Ьь]") then
            vh = export.vowelharmony(text, params)
            local k = 0
            for j, substring in ipairs(vh) do
                local k_increase = mw.ustring.len(gsub(vh[j].substring, "[^%w%s%p" .. stress .. export.stem_barrier .. "]", ""))
                if k + k_increase > i then
                    if vh[j].position == "front" then
                        -- If break, replaces the consonant preceding the soft sign as the break.
                        if breaks[#breaks] == i - 2 then
                            breaks[#breaks] = nil
                        end
                        insert(breaks, i)
                    end
                    break
                end
                k = k + k_increase
            end
            -- If a consonant followed by vowel (i.e. if lone/cluster-final), count backwards until vowel, punctuation/space or start of string is found; if a vowel is found first, then letter must be medial and lone/cluster-final, so is the break; if punctuation/start of string found first, letter is part of word-initial cluster, so is not the break (occurs in loanwords, e.g. трол|лей|бус ("trolleybus")).
        elseif match(v, consonant) and chars[i + 1] and (match(chars[i + 1], vowel) or (match(chars[i + 1], "[Ьь]") and chars[i + 2] and match(chars[i + 2], vowel))) then
            local j = i
            while j > 1 and (match(chars[j], consonant) or match(chars[j], sign) or match(chars[j], "[" .. stress .. "]")) do
                j = j - 1
                if match(chars[j], vowel) then
                    insert(breaks, i)
                end
            end
            -- If word-final consonant, count backwards until vowel, checking if each cluster is allowed as a word-final cluster; if it is, increase "stable" (the number of stable consonants (and signs) at the end) by one; if a vowel is found before an unstable cluster, the loop ends with no change; if an unstable cluster is found, "stable" will not iterate which will trigger an additional unvoweled syllable break at that consonant (occurs in loanwords, e.g. буд|ди|зм ("Buddhism"), ал|ге|бр ("algebra")).
        elseif (match(v, consonant) or match(v, sign)) and (i == #chars or match(chars[i + 1], punctuation)) then
            local j = i
            local check = { chars[j] }
            local stable = 1
            while j > 1 and j > i - #final_clusters and stable > i - j and (match(chars[j - 1], consonant) or match(chars[j - 1], sign)) do
                j = j - 1
                insert(check, chars[j])
                for k, cluster in ipairs(final_clusters[#check]) do
                    if match(concat(reverse_array(check)), cluster) then
                        stable = stable + 1
                        break
                    end
                end
                if stable == i - j then
                    insert(breaks, j)
                end
            end
            -- Iotated ("ya"-type) vowel after a vowel.
        elseif match(v, iotated) and (match(chars[i - 1], vowel) or (match(chars[i - 1], "[" .. stress .. "]") and match(chars[i - 2], vowel))) then
            insert(breaks, i)
        end
    end

    -- Reform text without diacritics.
    text = concat(chars)

    breaks = remove_duplicates(breaks)

    local syll = {}
    for i, v in ipairs(breaks) do
        if i == #breaks then
            insert(syll, sub(text, v))
        else
            insert(syll, sub(text, v, breaks[i + 1] - 1))
        end
    end

    return syll
end

function export.remove_final_short_vowel(text, params)

    if not params then
        params = {}
    end
    local vh = export.vowelharmony(text, params)[#export.vowelharmony(text, params)]
    local syllables = #export.syllables(text)
    local reduced = text
    local no_fv = false
    if (syllables > 1 and match(text, "[бвгджзклмнпрстфхцчшщ][аоөэиь]$")) or match(text, "[ьъ]$") then

        local matches = {
            not params.bor,
            match(text, "[ьъ]$"),
            match(text, "[ауя][влмн]ба$"),
            match(text, "[оё][влмн]бо$"),
            match(text, "ө[влмн]бө$"),
            match(text, "[эүе][влмн]бэ$"),
            match(text, "[бвглмнр]" .. vh.Cyrl.a .. u(0x301) .. "?" .. u(0x300) .. "?н" .. vh.Cyrl.a .. "$"),
            match(text, "[ауя]нга$"),
            match(text, "[оё]нго$"),
            match(text, "өнгө$"),
            match(text, "[эүе]нгэ$")
        }

        for _, v in pairs(matches) do
            if v then
                reduced = sub(text, 1, len(text) - 1)
                no_fv = true
            end
        end
    end
    return reduced, no_fv
end

function export.remove_penultimate_short_vowel(text, params)

    if not params then
        params = {}
    end
    local vh = export.vowelharmony(text, params)[#export.vowelharmony(text, params)]
    local syllables = reverse_array(export.syllables(text))

    if not params.proper and (vh.location ~= len(text) - 1 or vh.violation == false) and not params.bor then
        -- exclude proper nouns, loanwords and terms where the deleted vowel determines the vowel harmony

        local check
        local syllable_orig
        for i, syllable in ipairs(syllables) do
            if i ~= 1 and i ~= #syllables then
                syllable_orig = syllable
                if match(syllable, export.stem_barrier) then
                    break
                end
                local prev_syllable = gsub(syllables[i + 1], export.stem_barrier, "")
                check = (match(prev_syllable, "[бвгджзклмнпрстфхцчшщь]*$") or "") .. syllable .. (match(syllables[i - 1], "^[бвгджзклмнпрстфхцчшщь]*") or "")
                local matches = {
                    -- CVC
                    match(check, "^[влмр]ь?[аиоөэ][вгклмнпр]$"), -- not [бн]VC
                    match(check, "^гь?[аиоөэ][влмнр]$") and vh.position == "front", -- гV[влмнр] if front vowel only
                    -- CCVC
                    match(check, "^[вглмнр]?ь?[джзкпстхцчшщ]ь?[аиоөэ][вгджзклмнпрстцчшщ]$"),
                    match(check, "^[вглмнр]?ь?[сх]ь?[тч]ь?[аиоөэ][вглмнр]$"),
                }
                local exclusions = {
                    match(check, "[лм]ь?[аиоөэ]в$"), -- not [лм]Vв
                    match(check, "[вдзклмпрстхц]ь?и[вгджзлмнпрстцчшщ]$"), -- only [кжчш]иC
                }
                for _, v in pairs(matches) do
                    if v then
                        syllables[i] = sub(syllable, 1, len(syllable) - 1)
                        for _, e in pairs(exclusions) do
                            if e then
                                syllables[i] = syllable_orig
                            end
                        end
                    end
                end
                if syllables[i] ~= syllable_orig then
                    break
                end
            end
        end
    end
    return concat(reverse_array(syllables))
end

function export.concat_forms_in_slot(forms)
    if forms then
        local new_vals = {}
        for _, v in ipairs(forms) do
            local val = gsub(v.form, "|", "<!>")
            insert(new_vals, val)
        end
        return concat(new_vals, ",")
    else
        return nil
    end
end

function export.combine_stem_ending(stem, ending)
    if stem == "?" then
        return "?"
    else
        return stem .. ending
    end
end

function export.generate_form(form, footnotes)
    if type(footnotes) == "string" then
        footnotes = { footnotes }
    end
    if footnotes then
        return { form = form, footnotes = footnotes }
    else
        return form
    end
end

return export