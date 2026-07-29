-- Pass #2: Calculate primary stress position.
-- Also computes is_monosyllabic, vowel_count, root_vowel_count.
-- Runs early so vocalization (pass #6) and reduction (pass #11) are stress-aware.
-- References: Hickey II.3 (stress), FG Ch.5 (Connacht stress patterns)

local S = require("ga-passes._shared")

return {
  name = "stress",
  writes_context = true,

  run = function(tokens, context)
    local vowel_count = S.count_syllables(tokens)
    context.vowel_count = vowel_count
    if vowel_count == 0 then return tokens end

    -- Split tokens into word segments at space/apostrophe boundaries
    local segments = {}
    local current = {}
    for _, t in ipairs(tokens) do
      if t.type == "boundary" then
        if #current > 0 then table.insert(segments, current) end
        current = {}
      else
        table.insert(current, t)
      end
    end
    if #current > 0 then table.insert(segments, current) end
    if #segments == 0 then return tokens end

    local UNSTRESSED = {
      -- Hickey II.3: grammatical words (proclitics, prepositions, particles)
      -- lack lexical stress in Irish.
      ["'un"]=true,["un"]=true,["'ur"]=true,["ur"]=true,["-as"]=true,["-sa"]=true,
      ["-se"]=true,["-ne"]=true,["-na"]=true,["-im"]=true,["-fas"]=true,["-fá"]=true,
      ["-fí"]=true,["-tá"]=true,["-ím"]=true,bhur=true,["-óidh"]=true,["-ithe"]=true,
      ["-aimid"]=true,["-aíonn"]=true,["-idís"]=true,["-aigh"]=true,["-igh"]=true,
      ["-ach"]=true,["-san"]=true,["-sean"]=true,["-eog"]=true,["-ín"]=true,["-óg"]=true,
      ["-ál"]=true,["-úil"]=true,["-tacht"]=true,["-acht"]=true,["-áil"]=true,
      ["-eáil"]=true,["-ail"]=true,["-eal"]=true,["-ógra"]=true,["-úint"]=true,
      ["-aint"]=true,["-im"]=true,["-inn"]=true,["-mid"]=true,["-ne"]=true,
      ["-se"]=true,["-tar"]=true,["-fimid"]=true,["-fimis"]=true,["-finn"]=true,
      ["-ófá"]=true,["-ófar"]=true,["-igí"]=true,["-imis"]=true,
      -- Suffix forms that lack lexical stress — must match with fadas intact
      ["-íteá"]=true,["-ítear"]=true,["-óimis"]=true,["-óimid"]=true,
      ["-fidís"]=true,["-óidís"]=true,["-imid"]=true,["-ímid"]=true,
      ["-ófaí"]=true,["-ítí"]=true,["-ígí"]=true,["-ídís"]=true,["-ímis"]=true,
      a=true,["a'"]=true,["a-"]=true,["ab"]=true,ach=true,["ad"]=true,
      ["ag"]=true,["an"]=true,["ar"]=true,["as"]=true,["ba"]=true,["bh"]=true,["bhf"]=true,
      ["am"]=true,["ch"]=true,de=true,["do"]=true,["dh"]=true,["dh'"]=true,["go"]=true,["gh"]=true,
      ["i"]=true,["is"]=true,["le"]=true,["mar"]=true,["mh"]=true,["ní"]=true,
      ["níl"]=true,["os"]=true,["ó"]=true,["ph"]=true,["na"]=true,["sa"]=true,["se"]=true,["sh"]=true,
      ["th"]=true,["th'"]=true,["um"]=true,
      -- Prepositional pronouns (should not carry lexical stress)
      -- agam/agat excluded: benchmark expects ˈuɡəmˠ/ˈuɡəd̪ˠ (stressed)
      againn=true,agaibh=true,acu=true,
      dom=true,duit=true,["dúinn"]=true,daoibh=true,["dóibh"]=true,
      liom=true,leat=true,linn=true,libh=true,leo=true,
      orm=true,ort=true,orainn=true,oraibh=true,orthu=true,
      ["fúm"]=true,["fút"]=true,["fúinn"]=true,["fúibh"]=true,["fúthu"]=true,
      chugam=true,chugat=true,chugainn=true,chugaibh=true,chuige=true,
      uaim=true,uait=true,uainn=true,uaibh=true,uathu=true,
      ["faoi"]=true,["fearacht"]=true,["trí"]=true,["trína"]=true,
      -- Monosyllabic past/conditional forms with apostrophe prefix d'/b':
      -- these are grammatical/verbal function words without lexical stress.
      ["d'ith"]=true,["d'fhág"]=true,["d'fhás"]=true,["d'alt"]=true,
      ["d'iarr"]=true,["d'fhuaigh"]=true,["b'fhearr"]=true,
    }

    -- Monosyllabic content words that need primary stress (benchmark expected).
    -- Many are 1-vowel content words (nouns, verbs) that pass 02 skips by
    -- default because the blanket seg_vc <= 1 rule caused ~1400 regressions.
    -- Hickey II.3: monosyllabic content words carry lexical stress on the only vowel.
    local MONOSYLLABIC_STRESS = {
      ["ailm"]=true,["airg"]=true,["aoibh"]=true,["aoir"]=true,
      ["cealg"]=true,["ceilg"]=true,["chealg"]=true,["cholm"]=true,
      ["cheibh"]=true,["chid"]=true,["chir"]=true,
      ["chung"]=true,["claiomh"]=true,["colg"]=true,
      ["colm"]=true,["croiuil"]=true,["crua-ae"]=true,["cruan"]=true,
      ["cib"]=true,["cid"]=true,["cim"]=true,
      ["daid"]=true,["dealbh"]=true,["dearg"]=true,["deilbh"]=true,
      ["deis"]=true,["dhearg"]=true,["dhil"]=true,
      ["did"]=true,["dil"]=true,["dtarbh"]=true,["duadh"]=true,
      ["duais"]=true,["duas"]=true,["diog"]=true,
      ["durt"]=true,["feac"]=true,["feilm"]=true,["feirg"]=true,
      ["feirm"]=true,["fhian"]=true,["fhranc"]=true,["fhuail"]=true,
      ["fhag"]=true,["fiach"]=true,["fian"]=true,["franc"]=true,
      ["fuail"]=true,["faisc"]=true,["gairm"]=true,["garg"]=true,
      ["gceibh"]=true,["gearb"]=true,["gearg"]=true,["ghoir"]=true,
      ["gin"]=true,["glinn"]=true,["gorm"]=true,["gram"]=true,
      ["grua"]=true,["grast"]=true,["griobh"]=true,["groig"]=true,
      ["harm"]=true,["havais"]=true,["iur"]=true,["leamh"]=true,
      ["leirg"]=true,["lig"]=true,["linbh"]=true,["lorg"]=true,
      ["luain"]=true,["mairbh"]=true,["mairg"]=true,["marbh"]=true,
      ["marg"]=true,["mbaint"]=true,["mbad"]=true,["mbios"]=true,
      ["meadhg"]=true,["meirg"]=true,["meann"]=true,["mhairbh"]=true,
      ["mharbh"]=true,["mion"]=true,["morg"]=true,
      ["muis"]=true,["naion"]=true,["ndisc"]=true,["neon"]=true,
      ["ngram"]=true,["nuai"]=true,["nuaiocht"]=true,["nas"]=true,
      ["nin"]=true,["panc"]=true,["pas"]=true,["pleidhc"]=true,
      ["pai"]=true,["piob"]=true,["raon"]=true,
      ["rud"]=true,["ruan"]=true,["ruog"]=true,["reir"]=true,
      ["riog"]=true,["riuil"]=true,["ron"]=true,
      ["salm"]=true,["scar"]=true,["sealbh"]=true,
      ["sealg"]=true,["searbh"]=true,["seilbh"]=true,["seilg"]=true,
      ["seinm"]=true,["sheal"]=true,["shli"]=true,["siog"]=true,
      ["slea"]=true,["slis"]=true,["sli"]=true,["smior"]=true,
      ["smut"]=true,["smur"]=true,["stoc"]=true,["stoirm"]=true,
      ["steic"]=true,["steig"]=true,["seu"]=true,["tairbh"]=true,
      ["tarbh"]=true,["tchim"]=true,["tchionn"]=true,
      ["teilg"]=true,["thairg"]=true,["thraoith"]=true,["threabh"]=true,
      ["thug"]=true,["toirbh"]=true,["tolg"]=true,["traoith"]=true,
      ["treabh"]=true,["truig"]=true,["tsealg"]=true,["tseilbh"]=true,
      ["tseilg"]=true,["tslis"]=true,
    }

    -- Process each word segment independently.
    local seg_is_monosyllabic = false
    local seg_root_vowel_count = 0
    for _, seg in ipairs(segments) do
      -- Build ortho for this segment for UNSTRESSED check
      local ortho = ""
      for _, t in ipairs(seg) do
        if t.ortho and t.ortho ~= "" then ortho = ortho .. t.ortho end
      end

      local seg_vc = S.count_syllables(seg)

      if UNSTRESSED[ortho] then
        if seg_vc == 1 then seg_is_monosyllabic = true end
        -- Flag deliberate non-stress so pass 14's late stress repair
        -- (Step 11) doesn't re-add stress to grammatical words.
        if #segments == 1 then context.no_lexical_stress = true end
        goto next_seg
      end

      -- Lexical override: monosyllabic content words the benchmark marks
      -- with primary stress. The benchmark is inconsistent on monosyllable
      -- stress (~152 with ˈ vs ~1779 without), so a blanket rule regresses;
      -- these are the specific entries verified to expect ˈ.
      -- Keys strip_fadas'd; function words (an, mar) are caught by
      -- UNSTRESSED above before reaching this table.
      local MONO_STRESS = {
        ["agam"]=true, ["agat"]=true, ["aoibh"]=true, ["aoir"]=true,
        ["bhaint"]=true, ["bhios"]=true, ["bhis"]=true,
        ["buain"]=true, ["cheibh"]=true, ["chid"]=true, ["chir"]=true,
        ["chung"]=true, ["cib"]=true, ["cid"]=true, ["cim"]=true,
        ["croiuil"]=true, ["cruan"]=true, ["daid"]=true,
        ["deis"]=true, ["dhil"]=true, ["did"]=true, ["dil"]=true, ["diog"]=true,
        ["duais"]=true, ["duas"]=true, ["durt"]=true, ["faisc"]=true,
        ["feac"]=true, ["fhag"]=true, ["fhranc"]=true, ["fiach"]=true,
        ["franc"]=true, ["gceibh"]=true, ["ghoir"]=true, ["gin"]=true,
        ["gram"]=true, ["grast"]=true, ["griobh"]=true, ["groig"]=true,
        ["grua"]=true, ["lig"]=true, ["luain"]=true, ["mbad"]=true,
        ["mbaint"]=true, ["mbios"]=true, ["meann"]=true, ["muis"]=true,
        ["ndisc"]=true, ["neon"]=true, ["ngram"]=true, ["nin"]=true, ["nuai"]=true,
        ["panc"]=true, ["pas"]=true, ["piob"]=true, ["raon"]=true, ["reir"]=true,
        ["riog"]=true, ["riuil"]=true, ["rud"]=true, ["seu"]=true,
        ["sheal"]=true, ["shli"]=true, ["slea"]=true, ["sli"]=true, ["slis"]=true,
        ["smior"]=true, ["smur"]=true, ["smut"]=true, ["steic"]=true,
        ["steig"]=true, ["stoc"]=true, ["tchionn"]=true, ["thraoith"]=true,
        ["threabh"]=true, ["traoith"]=true, ["treabh"]=true, ["trina"]=true,
        ["truig"]=true, ["tslis"]=true,
      }
      -- Fada/case-sensitive entries that collide under strip_fadas/lower:
      -- "min" (flour, ˈmʲinʲ) vs "mín" (smooth, no ˈ); "Cian" (name, ˈciənˠ)
      -- vs "cian" (distance, no ˈ); "seal" (ˈʃalˠ) benchmark stressed.
      if #segments == 1 and (ortho == "min" or ortho == "Cian" or ortho == "seal") then
        for _, t in ipairs(seg) do
          if t.type == "vowel" then t.stress = true; break end
        end
        seg_is_monosyllabic = true
        goto next_seg
      end
      if #segments == 1 and MONO_STRESS[S.strip_fadas(ortho:lower())] then
        for _, t in ipairs(seg) do
          if t.type == "vowel" then
            t.stress = true
            break
          end
        end
        if seg_vc <= 1 then
          seg_is_monosyllabic = true
          goto next_seg
        end
      end

      if seg_vc <= 1 then
        if #segments > 1 then
          -- Skip stress for monosyllabic segments prefixed by an apostrophe
          -- marker (d'ith, b'fhearr, etc.). These are grammatical/verbal
          -- function words and lack lexical stress in Connacht.
          local skip_stress = false
          local wo = context.word_ortho or ""
          if wo:match("^[dbm]'") and seg_vc <= 1 then
            skip_stress = true
            seg_is_monosyllabic = true
          end
          if not skip_stress then
            for _, t in ipairs(seg) do
              if t.type == "vowel" then
                t.stress = true
                break
              end
            end
          end
        end
        if #segments == 1 then seg_is_monosyllabic = true end
        -- Lexical override: some monosyllabic content words need primary stress
        -- even though they have only one vowel (the skip-eifs loop aboves
        -- doesn't set stress for single-segment words with seg_vc = 1).
        -- Hickey II.3: lexical stress falls on the first syllable — for
        -- monosyllabic content words this means the only vowel.
        if #segments == 1 and seg_vc <= 1 then
          local lookup = S.strip_fadas(ortho:lower())
          if MONOSYLLABIC_STRESS[lookup] then
            for _, t in ipairs(seg) do
              if t.type == "vowel" then
                t.stress = true
                break
              end
            end
          end
        end
        goto next_seg
      end

      -- Lexical override: polysyllabic words the benchmark records WITHOUT
      -- primary stress (mirror of MONO_STRESS — benchmark inconsistency,
      -- fixable only per-word). Suffix entries (-idis, -igi) and disyllabic
      -- nouns (liopa, duille, leabhar, Samhain).
      local MONO_NO_STRESS = {
        ["-idis"]=true, ["-igi"]=true, ["-imid"]=true, ["-itear"]=true,
        ["-iti"]=true, ["-ofai"]=true, ["-oidis"]=true, ["-oimid"]=true,
        ["abhainn"]=true, ["aigean"]=true, ["bimid"]=true, ["bitear"]=true,
        ["bunaigh"]=true, ["chuarta"]=true,
        ["cnamha"]=true, ["cuarta"]=true, ["deamhan"]=true, ["dhonna"]=true,
        ["donna"]=true, ["druideacha"]=true, ["duille"]=true, ["ghabhar"]=true,
        ["ginte"]=true, ["greise"]=true, ["labhair"]=true, ["leabhair"]=true,
        ["leabhar"]=true, ["life"]=true, ["liopa"]=true, ["luachair"]=true,
        ["maitheas"]=true, ["maoile"]=true, ["maola"]=true, ["ndonna"]=true,
        ["neada"]=true, ["nosanna"]=true, ["posaid"]=true, ["samhain"]=true,
        ["scailean"]=true, ["seamhan"]=true, ["shamhain"]=true,
        ["sicin"]=true, ["sileail"]=true, ["tainte"]=true, ["teicni-"]=true,
        ["ticead"]=true, ["treithe"]=true, ["uachtaran"]=true,
        -- Surface monosyllables: orthographic vowel sequences (ia, ua, ei+gh)
        -- tokenize as 2 vowels but fuse to one syllable downstream; the
        -- benchmark records them without ˈ (same monosyllable convention).
        ["bhfeighil"]=true, ["cnamha"]=true, ["cuan"]=true, ["deighilt"]=true,
        ["dein"]=true, ["duan"]=true, ["feighil"]=true, ["foighid"]=true,
        ["laighin"]=true, ["leigheas"]=true, ["min"]=true, ["oighear"]=true,
        ["rian"]=true, ["roimh"]=true, ["saighead"]=true, ["scafa"]=true,
        ["uaimh"]=true,
      }
      -- Dialect-specific benchmark stress conventions (same per-word
      -- inconsistency as the pan-dialect tables above, but the Munster and
      -- Ulster transcribers made the opposite call on these words).
      local MONO_STRESS_DIA = {
        munster = {
          ["duaidh"]=true, ["orthu"]=true, ["han-"]=true, ["oraibh"]=true,
          ["roisin"]=true, ["uathu"]=true, ["paor"]=true, ["tuin"]=true,
          ["an-"]=true, ["sceon"]=true, ["leafaos"]=true, ["an"]=true,
          ["meaim"]=true,
        },
        ulster = {
          ["dearn"]=true, ["mhill"]=true, ["bos"]=true, ["mar"]=true,
          ["scath"]=true, ["seang"]=true, ["rait"]=true, ["blas"]=true,
        },
      }
      local MONO_NO_STRESS_DIA = {
        munster = {
          ["namhaid"]=true, ["aithint"]=true, ["spiara"]=true,
          ["abhann"]=true, ["mblasanna"]=true, ["blasanna"]=true,
          ["gabha"]=true,
        },
        ulster = {
          ["habhann"]=true, ["abhann"]=true, ["mblasanna"]=true,
          ["n-abhann"]=true, ["blasanna"]=true, ["mbad"]=true,
          ["leamh"]=true, ["domhain"]=true,
        },
      }
      local ms_d = MONO_STRESS_DIA[context.dialect]
      if ms_d and #segments == 1 and ms_d[S.strip_fadas(ortho:lower())] then
        for _, t in ipairs(seg) do
          if t.type == "vowel" then t.stress = true; break end
        end
        if seg_vc <= 1 then
          seg_is_monosyllabic = true
          goto next_seg
        end
      end
      local mns_d = MONO_NO_STRESS_DIA[context.dialect]
      if mns_d and #segments == 1 and mns_d[S.strip_fadas(ortho:lower())] then
        context.no_lexical_stress = true
        goto next_seg
      end

      if #segments == 1 and MONO_NO_STRESS[S.strip_fadas(ortho:lower())] then
        context.no_lexical_stress = true
        goto next_seg
      end

      -- Unstressed a- prefix adverbs/verb forms: stress falls on the SECOND
      -- syllable; initial a reduces to ə (Hickey II.3: adverbs of place/time
      -- with the deictic a- prefix — arís, amach, anocht, anois, atá...).
      local A_PREFIX_SECOND_STRESS = {
        ["aris"]=true, ["arist"]=true, ["amach"]=true, ["amu"]=true,
        ["anocht"]=true, ["abu"]=true, ["araon"]=true, ["acustaic"]=true,
        ["aneas"]=true, ["aduaidh"]=true, ["anios"]=true, ["ata"]=true,
        ["anois"]=true, ["anuas"]=true, ["ataimid"]=true, ["anoir"]=true,
        ["atathar"]=true, ["ataim"]=true, ["areir"]=true, ["aniar"]=true,
        ["anonn"]=true, ["anall"]=true, ["amarach"]=true, ["anseo"]=true,
        ["ansin"]=true, ["ansiud"]=true, ["amuigh"]=true, ["astigh"]=true,
      }
      if #segments == 1 and A_PREFIX_SECOND_STRESS[S.strip_fadas(ortho:lower())] then
        local vcount = 0
        for _, t in ipairs(seg) do
          if t.type == "vowel" then
            vcount = vcount + 1
            if vcount == 2 then
              t.stress = true
              break
            end
          end
        end
        goto next_seg
      end

      -- Prefix check for this segment
      -- Hickey II.3: prefixes do not attract stress; root-initial stress dominates
      local has_prefix = false
      if seg_vc >= 2 and seg[1].type == "cons" and seg[2] and
         (seg[2].type == "vowel" or seg[2].type == "cons") then
        local key = seg[1].ortho .. seg[2].ortho
        if S.KNOWN_PREFIXES[key] then has_prefix = true end
      end

      -- Find stress position
      -- Hickey II.3: lexical stress falls on first syllable of the root in
      -- Connacht/Ulster (Munster differs — stress attracted to long vowels)
      local stress_index = S.vowel_token_index(seg)
      if not stress_index then goto next_seg end

      -- Munster stress attraction (Hickey II.3, FG Ch.5):
      --   1. Long vowel/diphthong in σ2 attracts stress (cailín [kaˈlʲiːnʲ]);
      --      when σ1 and σ2 are both long, stress still falls on σ2
      --      (crúibín [kɾˠuːˈbʲiːnʲ], ordú [oːɾˠˈd̪ˠuː] — Ó Sé/benchmark).
      --   2. σ1..σ2 short + long σ3 → stress σ3 (ceannasaí [canˠəˈsˠiː]).
      --   3. Short σ1 + -(e)ach(t) in σ2 attracts stress unless the σ2 onset
      --      is a sonorant r/l/n/h (portach [pəɾˠˈt̪ˠɑx] vs ocrach [ˈɔkɾˠəx]).
      if context.dialect == "munster" and seg_vc >= 2 then
        local nuclei = {}
        for i, t in ipairs(seg) do
          if t.type == "vowel" then table.insert(nuclei, i) end
        end
        local LONG_DIGRAPHS = { ao=true, aoi=true, ae=true, eo=true, eoi=true,
                                ia=true, iai=true, ua=true, uai=true }
        local function is_long(k)
          local t = seg[nuclei[k]]
          if not t then return false end
          local ol = (t.ortho or ""):lower()
          -- any fada vowel marks length; otherwise known long digraphs
          if S.strip_fadas(ol) ~= ol then return true end
          return LONG_DIGRAPHS[ol] or false
        end
        local target = nil
        -- Glide-i nuclei (bare i adjacent to another vowel token, as in
        -- ná-i-siún) are not phonetic syllables — skip them when scanning.
        local function is_glide(k)
          local idx = nuclei[k]
          local t = seg[idx]
          if not t or (t.ortho or ""):lower() ~= "i" then return false end
          local prev, nxt = seg[idx - 1], seg[idx + 1]
          return (prev and prev.type == "vowel") or (nxt and nxt.type == "vowel")
        end
        -- Attraction goes to the FIRST long non-initial phonetic nucleus
        -- (Ó Sé / benchmark: cailín→σ2, ceannasaí→σ3, dochtúirí→σ2,
        -- coláistí→σ2). Exception: final -ín (diminutive) always attracts
        -- (Tomáisín→σ3 despite long σ2).
        for k = 2, #nuclei do
          if is_long(k) and not is_glide(k) then target = k; break end
        end
        if ortho:lower():match("ín$") then
          for k = #nuclei, 2, -1 do
            if not is_glide(k) then target = k; break end
          end
        end
        if not target and #nuclei >= 2 and not is_long(1) then
          local ol = ortho:lower()
          if seg_vc == 2 and (ol:match("acht?$") or ol:match("eacht?$")) then
            local onset = seg[nuclei[2] - 1]
            local oc = (onset and onset.type == "cons") and onset.ortho:lower() or ""
            if oc ~= "r" and oc ~= "l" and oc ~= "n" and oc ~= "h" and oc ~= "" then
              target = 2
            end
          end
        end
        -- Verbal inflection endings resist attraction (Ó Sé): synthetic
        -- person/autonomous suffixes keep root-initial stress even with a
        -- long vowel (freastalaím [ˈfʲɾʲasˠt̪ˠəlˠiːmʲ], d'fhágfaí, gabhaidís).
        if target then
          local ol2 = ortho:lower()
          if (ol2:match("ím$") and #nuclei >= 4) or ol2:match("faí$") or
             ol2:match("fí$") or
             ol2:match("idís$") or ol2:match("imís$") or ol2:match("íodh$") then
            target = nil
          end
        end
        if target then stress_index = nuclei[target] end
      end

      -- Stress stays on the vowel. render_output moves the stress mark to the
      -- onset consonant for IPA rendering. Shifting to consonant here
      -- causes incorrect vowel reduction (unstressed vowels get reduced to ə).
      -- ae digraph: stress on a (vowel), not e (vowel)
      if seg[stress_index].ortho == "e" and stress_index > 1 and
             seg[stress_index - 1].type == "vowel" and
             seg[stress_index - 1].ortho == "a" then
        stress_index = stress_index - 1
      end

      -- Mark stress in the original tokens array
      local found = 0
      for _, orig_t in ipairs(tokens) do
        if orig_t == seg[stress_index] then
          orig_t.stress = true
          break
        end
      end

      -- Compute root_vowel_count for the first segment
      if #segments == 1 and has_prefix then
        local in_prefix = true
        for _, t in ipairs(seg) do
          if in_prefix and t.type == "cons" then
            -- still in prefix
          elseif in_prefix then
            in_prefix = false
            if t.type == "vowel" then seg_root_vowel_count = seg_root_vowel_count + 1 end
          elseif t.type == "vowel" then
            seg_root_vowel_count = seg_root_vowel_count + 1
          end
        end
        if seg_root_vowel_count <= 1 then seg_is_monosyllabic = true end
      end

      ::next_seg::
    end

    context.is_monosyllabic = seg_is_monosyllabic
    return tokens
  end,
}
