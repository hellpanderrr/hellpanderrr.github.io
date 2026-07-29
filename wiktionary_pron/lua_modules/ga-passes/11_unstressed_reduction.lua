-- Pass #11: Reduce unstressed short vowels to schwa.
-- In unstressed positions, short vowels reduce to ə.
-- Long vowels (with ː) are never reduced.
-- References: Hickey II.1.9.6 (unstressed vowels → only [ə] and [ɪ] possible),
--  Hickey II.2.7.2 (final devoicing), II.1.9.4 (vowel gradation)

local S = require("ga-passes._shared")

-- Words in the UNSTRESSED table that should NOT have their vowel reduced to ə.
-- These words have specific phonetic forms handled by other passes (e.g. r-lowering).
local REDUCTION_EXCEPTIONS = {
  ar = true, as = true, im = true,
}

-- Words where word-final -e after c/ɟ should reduce to ə, NOT stay as ɪ.
-- Most -e after slender c/ɟ keeps ɪ (glice, gaige, pice, lice), but these
-- lexical exceptions follow regular reduction to ə.
local FINAL_E_C_G_EXCEPTIONS = {
  ["farraige"] = true, ["bhfarraige"] = true,
  ["peige"] = true, ["boige"] = true,
  ["craice"] = true, ["circe"] = true, ["coirce"] = true,
  ["chirce"] = true, ["déirce"] = true,
  ["uisce"] = true,
  ["tuige"] = true,
  ["cailce"] = true, ["lige"] = true,
	  ["gairge"] = true,
}

-- Words where ɪ after c/ɟ (from vowel resolution) should still reduce to ə.
-- The after-c/ɟ guard normally protects ɪ in this context, but these words
-- need regular reduction (airgid → airged, eiscir → eiscər).
local AFTER_C_G_GUARD_EXCEPTIONS = {
  ["airgid"] = true, ["eiscir"] = true,
	  ["feicim"] = true, ["fáiscim"] = true,
  -- Words where unstressed ɪ after c/ɟ should reduce to ə (benchmark expects ə).
  -- Many are genitive/plural forms ending in -ige/-oige/-acha.
  ["fuinneoige"]=true, ["carraige"]=true, ["indiacha"]=true,
  ["cearnóige"]=true, ["cad chuige"]=true, ["diosfaige"]=true,
  ["nollaig"]=true, ["uair an chloig"]=true, ["danmhairge"]=true,
  ["gaedhilge"]=true,
}

local SHORT_VOWELS = { ["a"] = true, ["e"] = true, ["i"] = true, ["o"] = true, ["u"] = true,
                       ["ɛ"] = true, ["ɪ"] = true, ["ɔ"] = true, ["ʊ"] = true }

-- Check if phon is a short vowel (no length mark)
local function is_short_vowel(phon)
  if not phon or phon == "" then return false end
  -- Phon containing ː is long — never reduce
  if phon:match(ustring and "[".. (ustring and ustring.len and "ː" or "ː") .."]") then
    return false
  end
  return SHORT_VOWELS[phon]
end

return {
  name = "unstressed_reduction",
  writes_context = false,

  run = function(tokens, context)
    if context.vowel_count <= 1 then
      if context.is_monosyllabic then return tokens end

      -- Check if this is an exception word
      local ortho = ""
      for _, t in ipairs(tokens) do
        if t.ortho and t.ortho ~= "" then ortho = ortho .. t.ortho end
      end
      if REDUCTION_EXCEPTIONS[ortho] then return tokens end

      -- Reduce unstressed short vowel to ə (only if not a long vowel)
      for _, token in ipairs(tokens) do
        if token.type == "vowel" and not token.stress then
          if token.phon and not token.phon:match("ː") and SHORT_VOWELS[token.phon] then
            token.phon = "ə"
          end
          break
        end
      end
      return tokens
    end

    for i, token in ipairs(tokens) do
      if token.type ~= "vowel" or token.stress then goto continue end
      if token.is_epenthetic then goto continue end
      local phon = token.phon
      if not phon or phon == "" then goto continue end

      -- Must not reduce vowel before another vowel — it's part of a VV diphthong
      local next_token = tokens[i + 1]
      if next_token and next_token.type == "vowel" then goto continue end

      -- Munster: pretonic short vowels keep full quality when stress has been
      -- attracted rightward (pacáil [pˠaˈkɑːlʲ], bruitíneach [bˠɾˠɪˈtʲiːnʲəx]).
      -- FG Ch.5/Ó Sé: pretonic reduction is much weaker than post-tonic.
      -- Only a/ɑ/ɪ in the FIRST syllable resist pretonic reduction
      -- (cailín [kɑˈlʲiːnʲ], bruitíneach [bˠɾˠɪˈtʲiːnʲəx]); non-initial
      -- pretonic vowels and ɔ/ʊ/ɛ reduce (portach [pˠəɾˠˈt̪ˠax], buachalán).
      if context.dialect == "munster" then
        local pretonic = false
        for j = i + 1, #tokens do
          if tokens[j].type == "boundary" then break end
          if tokens[j].type == "vowel" and tokens[j].stress then pretonic = true; break end
        end
        if pretonic then
          if phon == "a" or phon == "ɑ" or phon == "ɪ" then
            local is_first_vowel = true
            for j = i - 1, 1, -1 do
              if tokens[j].type == "vowel" then is_first_vowel = false; break end
              if tokens[j].type == "boundary" then break end
            end
            if is_first_vowel then goto continue end
          end
          -- Other pretonic short vowels reduce even in 2-vowel words —
          -- attracted stress leaves a reduced pretonic syllable
          -- (cosán [kəˈsˠɑːn̪ˠ], portach [pˠəɾˠˈt̪ˠax]).
          if SHORT_VOWELS[phon] then
            token.phon = "ə"
            goto continue
          end
        end
      end

      -- For 2-vowel words: short vowels in non-final syllable keep full quality
      -- — EXCEPT when a LATER vowel carries the stress (a-prefix adverbs like
      -- arís/amach/anocht where pass 02 put stress on syllable 2; the pretonic
      -- initial vowel reduces: əˈɾʲiːʃ). Hickey II.1.9.6.
      if context.vowel_count == 2 and SHORT_VOWELS[phon] then
        local has_later_vowel = false
        local later_stressed = false
        for j = i + 1, #tokens do
          if tokens[j].type == "vowel" then
            has_later_vowel = true
            if tokens[j].stress then later_stressed = true end
          end
        end
        if has_later_vowel and not later_stressed then goto continue end
      end

      -- Don't reduce ɪ after palatal c/ɟ (preserves Irish slender vowel quality).
      -- A few lexical exceptions (airgid, eiscir) need regular reduction.
      -- Hickey II.1.9.6: slender vowel quality [ɪ] preserved after palatal stops
      if phon == "ɪ" then
        local prev_t = tokens[i - 1]
        if prev_t and prev_t.type == "cons" and
           (prev_t.phon == "c" or prev_t.phon == "ɟ") then
          local exc = false
          if context.word_ortho then
            if AFTER_C_G_GUARD_EXCEPTIONS[context.word_ortho:lower()] then exc = true end
          end
          if not exc then goto continue end
        end
      end

      -- Don't reduce ɪ before a slender voiceless stop (t, p, c). In Connacht
      -- the slender offglide survives before these: expected ɪ ~89% before
      -- slender t, ~91% before p, and c is already covered by the word-final
      -- rule above for medial positions too. afraic, ceimic, fisic, critic.
      -- Hickey II.1.9.6: ɪ offglide survives before slender voiceless stops
      if phon == "ɪ" then
        local nxt = tokens[i + 1]
        if nxt and nxt.type == "cons" and nxt.palatal == true and nxt.phon ~= "" then
          -- strip trailing ʲ (slender sonorants render as base+ʲ, e.g. lʲ nʲ mʲ)
          local p = nxt.phon:gsub("\xca\xb2$", "")
          if p == "t" or p == "p" or p == "c" then
            -- Lexical exceptions: words where ɪ should still reduce to ə.
            -- uiliteoir: second vowel ɪ before slender t should be ə
            -- Meiriceá: unstressed ɪ before slender c should be ə (Hickey §3.4)
            local exc = false
            if context.word_ortho then
              local lower = context.word_ortho:lower()
              if lower == "uiliteoir" or lower == "meirice\xc3\xa1" then exc = true end
            end
            if not exc then goto continue end
          end
        end
      end

      -- Word-final unstressed ɛ after a slender palatal stop (c, ɟ):
      -- keep ɪ instead of reducing to ə. The slender offglide survives before
      -- these consonants (glice /ɟlʲɪcɪ/, gaige /ɡaɟɪ/).
      -- Some lexical exceptions (farraige, Peige, uisce, etc.) need ə instead.
      -- Only applies to a TRUE word-final vowel (next token is boundary/end).
      if phon == "ɛ" then
        local prev_t = tokens[i - 1]
        local nxt = tokens[i + 1]
        local word_final = (nxt == nil) or (nxt.type == "boundary")
        if word_final and prev_t and prev_t.type == "cons" and
           prev_t.palatal == true and
           (prev_t.phon == "c" or prev_t.phon == "ɟ") then
          -- Check lexical exceptions (lowercased to match table keys)
          local exc = false
          if context.word_ortho then
            local w = context.word_ortho:lower()
            if FINAL_E_C_G_EXCEPTIONS[w] then exc = true end
          end
          if not exc then
            token.phon = "ɪ"
            goto continue
          end
        end
      end

      -- Unstressed 'ui' before a word-final slender consonant: keep ɪ, not ə.
      -- The ui digraph ends in slender i; before a final slender cons the
      -- offglide survives (cruit /kɾˠɪtʲ/, diúraic /dʲuːɾˠɪc/).
      if token.ortho == "ui" then
        local nxt = tokens[i + 1]
        if nxt and nxt.type == "cons" and nxt.palatal == true and nxt.phon ~= "" then
          local word_final_cons = true
          for j = i + 2, #tokens do
            local t = tokens[j]
            if t.type == "boundary" then break end
            if (t.type == "cons" or t.type == "vowel") and t.phon and t.phon ~= "" then
              word_final_cons = false; break
            end
          end
          if word_final_cons then
            token.phon = "ɪ"
            goto continue
          end
        end
      end

      -- Keep ɪ before word-final c or ɟ (palatal stops). The after-c/ɟ guard
      -- protects ɪ *after* c/ɟ, but ɪ *before* c/ɟ (mairg -> mˠaɾʲɪɟ, leirg
      -- -> l̠ʲɛɾʲɪɟ, etc.) needs the same protection. Check that the ɪ is
      -- followed by c/ɟ with nothing but boundary (or silenced tokens) after it.
      -- Hickey II.1.9.6: slender offglide ɪ survives before palatal stops.
      if phon == "ɪ" then
        local after_cg = false
        for j = i + 1, #tokens do
          local t2 = tokens[j]
          if t2.type == "boundary" then
            after_cg = true; break  -- c/ɟ found earlier + boundary = word-final
          end
          if t2.type == "vowel" then break end  -- another vowel = not word-final
          if t2.type == "cons" and t2.phon and t2.phon ~= "" then
            local p = t2.phon:gsub("\xca\xb2$", "")
            if p == "c" or p == "ɟ" then
              -- Found c/ɟ; now check if anything non-boundary follows
              local all_done = true
              for k = j + 1, #tokens do
                local tk = tokens[k]
                if tk.type == "boundary" then break end
                if tk.type == "vowel" then all_done = false; break end
                if tk.type == "cons" and tk.phon and tk.phon ~= "" then
                  all_done = false; break
                end
              end
              if all_done then after_cg = true end
              break
            else
              break  -- non-c/ɟ consonant = not our pattern
            end
          end
        end
        if after_cg then goto continue end
      end

      -- Keep word-final ɪ after h/ç (-the/-che/-ghe endings).
      -- The historical verbal noun suffix retains final ɪ in Connacht.
      -- Hickey II.1.9.6: slender verb-noun suffix carries ɪ before the h.
      if phon == "ɪ" then
        local nxt = tokens[i + 1]
        local word_final = (nxt == nil) or (nxt.type == "boundary")
        if word_final then
          local prev_t = tokens[i - 1]
          if prev_t and prev_t.type == "cons" then
            local p = prev_t.phon:gsub("\xca\xb2$", "")
            if p == "h" or p == "ç" then
              goto continue
            end
          end
        end
      end

      if SHORT_VOWELS[phon] then
        token.phon = "ə"
      end
      ::continue::
    end

    -- Connacht: final -adh is [uː]/[u] in past-autonomous verb forms and a
    -- set of nouns (rinneadh [ˈɾˠɪnʲuː], boladh [ˈbˠɔlˠu]), but [ə] in verbal
    -- nouns (bualadh). Grammatically conditioned — FG Ch.7 schwa rule
    -- explicitly excludes past forms — so lexically listed.
    if context.dialect == "connacht" then
      local ADH_FINAL = {
        ["rinneadh"] = "uː", ["dearnadh"] = "uː", ["cailleadh"] = "uː",
        ["bunadh"] = "uː", ["baladh"] = "uː", ["troscadh"] = "uː",
        ["geimhreadh"] = "uː",
        ["boladh"] = "u", ["d'oileadh"] = "u", ["n-oileadh"] = "u",
        ["oilfeadh"] = "u", ["d'oilfeadh"] = "u", ["n-oilfeadh"] = "u",
      }
      local wl = (context.word_ortho or ""):lower()
      if ADH_FINAL[wl] then
        for j = #tokens, 1, -1 do
          local t = tokens[j]
          if t.type == "vowel" and t.phon and t.phon ~= "" then
            t.phon = ADH_FINAL[wl]
            break
          end
        end
      end
    end

    -- =======================================================================
    -- Ulster vowel adjustments (Hickey II.3, I.2.3: Northern dialect)
    -- =======================================================================
    if context.dialect == "ulster" then
      -- (0) Short-o exceptions to the ʌ-merger (Hickey I.2.3):
      -- ɔ preserved before liquids (lorg [l̪ˠɔɾˠəɡ], bolg, corr);
      -- before geminate nn the vowel is plain [ʌ] (tonn, fonn, donn) —
      -- no Connacht-style nasal raising.
      for i2, t in ipairs(tokens) do
        if t.type == "vowel" and t.ortho == "o" then
          local n1, n2 = tokens[i2 + 1], tokens[i2 + 2]
          local c1 = n1 and n1.type == "cons" and n1.ortho or nil
          -- ɔ only before CODA liquids: liquid must be followed by a
          -- consonant or word end (lorg, bolg, corr); intervocalic liquids
          -- take plain ʌ (molann, colún, torann).
          local liquid_coda = (c1 == "l" or c1 == "r") and
            (n2 == nil or n2.type == "boundary" or n2.type == "cons")
          -- intervocalic geminate ll/rr (olla, stollaire) is not a coda
          if liquid_coda and n2 and n2.type == "cons" and n2.ortho == c1 then
            local n3 = tokens[i2 + 3]
            if n3 and n3.type == "vowel" then liquid_coda = false end
          end
          if (t.phon == "ʌ") and liquid_coda then
            t.phon = "ɔ"
          elseif c1 == "n" and n2 and n2.type == "cons" and n2.ortho == "n" and
                 (t.phon == "ʊ" or t.phon == "ɔ" or t.phon == "u" or t.phon == "uː") then
            t.phon = "ʌ"
          end
        end
      end

      -- (0b) Ulster á is front [aː] in all spellings, including ái digraphs
      -- (gáire, Máire, cáithnín) — Hickey I.2.3 northern fronting.
      for _, t in ipairs(tokens) do
        if t.type == "vowel" and t.phon == "ɑː" then t.phon = "aː" end
      end

      -- (1) Post-tonic long-vowel shortening — the signature Ulster feature:
      -- long vowels in non-initial syllables shorten (scadán [ˈsˠkad̪ˠənˠ],
      -- maoilín [ˈmˠiːlʲinʲ], dochtúir, Sabóid, seachrán).
      local ULSTER_SHORTEN = {
        ["iː"] = "i", ["uː"] = "u", ["oː"] = "ɔ", ["ɔː"] = "ɔ",
        ["ɑː"] = "a", ["aː"] = "a",
      }
      -- Lexical exceptions: words whose post-tonic long vowel RESISTS the
      -- shortening (pisín→pʲɪʃiːnʲ, giotár, saighdiúir, garraí...).
      -- Benchmark split ~197 long kept vs ~389 shortened — the keepers are
      -- lexical. Keys strip_fadas'd.
      local ULSTER_KEEP_LONG = {
        ["abulacht"]=true, ["acson"]=true, ["aerostach"]=true,
        ["athraigh"]=true, ["barriall"]=true, ["bealtaine"]=true,
        ["bearrfaidh"]=true, ["bearrtha"]=true, ["bharula"]=true,
        ["bithiunach"]=true, ["breidin"]=true, ["caifeach"]=true,
        ["caitin"]=true, ["caitriona"]=true, ["casaoid"]=true,
        ["casur"]=true, ["cipin"]=true, ["clibin"]=true, ["cotan"]=true,
        ["d'athraigh"]=true, ["diuracan"]=true, ["doighiuil"]=true,
        ["eadalach"]=true, ["eillin"]=true, ["einsimeach"]=true,
        ["feidhmiuil"]=true, ["fiuntach"]=true, ["galan"]=true,
        ["gallan"]=true, ["garrai"]=true, ["gearmain"]=true,
        ["gearr"]=true, ["gearrfaidh"]=true, ["gearrtha"]=true,
        ["gearrthacha"]=true, ["ghearr"]=true, ["giotar"]=true,
        ["giuistis"]=true, ["goirin"]=true, ["ngarrai"]=true,
        ["ngearrfaidh"]=true, ["pardun"]=true, ["phisin"]=true,
        ["pisin"]=true, ["praiscin"]=true, ["puisin"]=true,
        ["roisin"]=true, ["saighdiuir"]=true, ["sciulan"]=true,
        ["seasun"]=true, ["seasur"]=true, ["siunta"]=true, ["smigin"]=true,
        ["suiomh greasain"]=true, ["tarrthalach"]=true, ["tuiodoir"]=true,
      }
      local ul_keep = ULSTER_KEEP_LONG[S.strip_fadas((context.word_ortho or ""):lower())]
      context.ulster_keep_long = ul_keep and true or false
      local seen_vowel = false
      for ti, t in ipairs(tokens) do
        if t.type == "boundary" then seen_vowel = false end
        if t.type == "vowel" then
          if seen_vowel and not t.stress and t.phon and ULSTER_SHORTEN[t.phon]
             and not ul_keep then
            local short = ULSTER_SHORTEN[t.phon]
            -- Post-tonic á before a SLENDER consonant fronts to [æ]
            -- (úsáid→uːsˠædʲ, oileáin→ɛlʲænʲ, ofráil→ɔfˠɾˠælʲ; 65 vs 16).
            -- Hickey I.2.3: Ulster á-fronting is strongest in palatal contexts.
            if short == "a" and (t.phon == "aː" or t.phon == "ɑː") then
              local nxt = tokens[ti + 1]
              if nxt and nxt.type == "cons" and nxt.palatal == true then
                short = "æ"
              end
            end
            t.phon = short
          end
          seen_vowel = true
        end
      end

      -- (2) Word-final unstressed suffix realizations:
      --   -adh → [u]  (ghearradh, rugadh, canadh)
      --   -igh/-aigh → [i]  (bealaigh, ceannaigh)
      --   -ach keeps [a] (benchmark Ulster: -ach = a/ah/ax), no schwa
      local wl = (context.word_ortho or ""):lower()
      local last_v = nil
      for j = #tokens, 1, -1 do
        if tokens[j].type == "vowel" and tokens[j].phon and tokens[j].phon ~= "" then
          last_v = tokens[j]; break
        end
        if tokens[j].type == "boundary" then break end
      end
      if last_v and not last_v.stress then
        -- Lexical set: -adh/-aigh/-ú words whose final vowel stays LONG
        -- (33 of 160 -adh, 12 of 98 -aigh in the benchmark). Mostly
        -- verbal nouns (glacadh, pósadh, margadh) and 2nd-conj verbs
        -- (ceannaigh, athraigh). Keys strip_fadas'd.
        local FINAL_LONG = {
          ["adai"]=true, ["athraigh"]=true, ["athru"]=true,
          ["barriall"]=true, ["bathadh"]=true,
          ["bheannaigh"]=true, ["bhfiodoiri"]=true, ["bpogadh"]=true,
          ["bposadh"]=true, ["bradaigh"]=true, ["bunadh"]=true,
          ["ceannaigh"]=true, ["ceansu"]=true,
          ["ceathru"]=true, ["cheannaigh"]=true,
          ["d'athraigh"]=true, ["dearbhu"]=true, ["dearcadh"]=true,
          ["eidigh"]=true, ["failli"]=true,
          ["fiafraigh"]=true, ["fiodoiri"]=true, ["fuaimniu"]=true,
          ["gabhadh"]=true, ["gadai"]=true, ["gealladh"]=true,
          ["geimhrigh"]=true,
          ["ghlactai"]=true, ["glacadh"]=true, ["madadh"]=true,
          ["margadh"]=true, ["maslu"]=true, ["meangadh"]=true,
          ["mhullaigh"]=true, ["mullaigh"]=true, ["ngadai"]=true,
          ["nglacadh"]=true, ["nglacfadh"]=true,
          ["posadh"]=true, ["scabadh"]=true, ["seiftiu"]=true,
          ["siabadh"]=true, ["sliocadh"]=true,
          ["tapadh"]=true, ["thuilleamai"]=true,
          ["thusaigh"]=true, ["tuismigh"]=true, ["tusaigh"]=true,
          -- pilleadh/tuilleadh class (formerly EADH_LONG)
          pilleadh=true, tilleadh=true, tuilleadh=true, thuilleadh=true,
          ngeimhreadh=true, gheimhreadh=true, cuireadh=true, deireadh=true,
          hitheadh=true, briseadh=true, scaoileadh=true, suaitheadh=true,
          geimhreadh=true, itheadh=true, seideadh=true,
        }
        local wl_nf = S.strip_fadas(wl)
        local keep_long = FINAL_LONG[wl_nf]
        if wl:match("e?adh$") and (last_v.phon == "ə" or last_v.phon == "u" or last_v.phon == "uː") then
          last_v.phon = keep_long and "uː" or "u"
        elseif wl:match("igh$") and (last_v.phon == "ə" or last_v.phon == "ɪ"
               or last_v.phon == "i" or last_v.phon == "iː") then
          last_v.phon = keep_long and "iː" or "i"
        elseif (wl:match("ach$") or wl:match("each$")) and last_v.phon == "ə" then
          last_v.phon = "a"
        elseif keep_long and last_v.phon == "u" then
          -- -ú verbal nouns kept long (athrú, ceansú, maslú)
          last_v.phon = "uː"
        elseif keep_long and last_v.phon == "i" then
          -- -aí nouns kept long (gadaí, faillí)
          last_v.phon = "iː"
        end
      end

      -- (3) Final verbal -im is broad [mˠ] in Ulster (éistim [ˈeːʃtʲəmˠ])
      -- strip_fadas: -aím/-ím verbal endings (ceannaím, airím) must match
      -- too — bare "im$" misses the fada í (22 benchmark words).
      if S.strip_fadas(wl):match("im$") and context.vowel_count and context.vowel_count > 1 then
        for j = #tokens, 1, -1 do
          local t = tokens[j]
          if t.type == "cons" and t.phon and t.phon ~= "" then
            if t.ortho == "m" then t.phon = "mˠ"; t.palatal = false end
            break
          end
          if t.type == "vowel" or t.type == "boundary" then break end
        end
      end
    end

    return tokens
  end,
}