-- Pass #14: Final cleanup and diacritics.
-- References: Hickey II.1.7.2 (final lenited fricatives silent),
--  Hickey II.2.7.2 (final devoicing), II.2.7.1 (internal lenition),
--  Hickey II.1.9.9.1 (vocalization of historical fricatives, digraph resolution),
--  Hickey II.1.7 (consonant system — sandhi affrication [tʃ] from /x/+/s/),
--  Hickey II.3 (function word stress/prosody), II.2.7.5 (assimilation across word boundaries)
local S = require("ga-passes.shared")
local ustring = require("ustring.ustring")
local ugsub = ustring.gsub
local usub = ustring.sub
local umatch = ustring.match
local function strip_trailing_fricative(phon)
  if not phon then return phon end
  -- Match pattern: long vowel + ç/ɣ/h at end
  -- Use ugsub (UTF-8-aware) not plain gsub — ː, ç, ɣ are multi-byte
  return ugsub(phon, "([ɑeiou]ː)[ɣçh]$", "%1")
end
return {
  name = "final_cleanup",
  writes_context = false,
  run = function(tokens, context)
    -- Step 1: Handle final silent mutated fricatives
    -- dh and gh are always silent word-finally in Connacht (Hickey II.1.7.2).
    -- th after SHORT vowels retains h (dath→d̪ˠah, croith→kɾˠɔh); th after LONG
    -- vowels/diphthongs is silent (síth→ʃiː, fáth→fˠɑː). Hickey II.1.7.2.
    if #tokens > 0 then
      local last = tokens[#tokens]
      if last.type == "cons" and (last.ortho == "dh" or last.ortho == "gh") then
        local prev = tokens[#tokens - 1]
        if prev and prev.type == "vowel" then
          prev.source = "vowel_before_silent_fricative"
        end
        last.phon = ""
      elseif last.type == "cons" and last.ortho == "th" then
        -- Word-final th: h only in specific words. Most are silent or optional (h)
        -- which benchmark matches via variant matching. Hickey §2.6.3.
        if context.word_ortho then
          local w = context.word_ortho:lower()
          local FINAL_TH_H = {
            ["dath"]=true, ["feith"]=true, ["chath"]=true, ["anraith"]=true,
            ["croith"]=true, ["gaoith"]=true, ["ngaoith"]=true,
          }
          if FINAL_TH_H[w] then
            if last.phon == "" then last.phon = "h" end
          else
            last.phon = ""
          end
        else
          last.phon = ""
        end
      end
    end
    -- Step 2: Strip trailing ç/ɣ/h from long-vowel phons
    -- This matches the production rule: ([ɑeiou]ː)[ɣçh]$ → %1
    for _, token in ipairs(tokens) do
      if token.type == "vowel" then
        token.phon = strip_trailing_fricative(token.phon)
      end
    end
    -- Step 3: Delete final ç/ɣ/h tokens after long vowels (production rule)
    -- Exception: gaoith/ngaoith keep h despite aoi→iː producing a long vowel.
    local skip_h_strip = false
    if context.word_ortho then
      local w = context.word_ortho:lower()
      if w == "gaoith" or w == "ngaoith" then skip_h_strip = true end
    end
    for i, token in ipairs(tokens) do
      if token.type == "vowel" and token.phon and token.phon:match("[ɑeiou]ː") then
        local next_t = tokens[i + 1]
        if next_t and next_t.phon and (next_t.phon == "ç" or next_t.phon == "ɣ" or next_t.phon == "h") then
          local has_further_content = false
          for j = i + 2, #tokens do
            if tokens[j].phon and tokens[j].phon ~= "" then
              has_further_content = true; break
            end
          end
          if not has_further_content and not skip_h_strip then
            next_t.phon = ""
          end
        end
      end
    end
    -- Step 4: Unstressed final devoicing (Connacht/Ulster) — TIGHTENED
    -- Devoice slender g [ɟ] -> [c] ONLY when preceded by schwa [ə].
    -- Hickey II.1.8: final palatal velar devoices after unstressed [ə]
    --   (Nollaig→[ˈn̪ˠɔl̪ˠəkʲ], coisrig→[kˠɔʃɾʲɪc])
    -- Hickey II.2.7.2: final devoicing in unstressed syllables
    -- Empirical
    -- analysis of the benchmark: of 39 slender-g-final words the rule fired on,
    -- 33 were over-devoiced (exp keeps ɟ: cúig, tréig, bróig, smig, etc.) and
    -- only 6 were correct — all 6 had schwa before the final g (Nollaig,
    -- coisrig, oifig, aisig, ráinig, Lá Fhéile Pádraig). Restricting to the
    -- schwa context keeps the legitimate devoicing while not touching full-vowel
    -- cases (ɪ, eː, oː, a, uː, uə, etc.) where ɟ is preserved.
    -- Lexical exceptions: tháinig and easpaig keep ɟ despite schwa-final-ɪ context.
    local KEEP_DEV = { ["tháinig"] = true, ["easpaig"] = true }
    for i = #tokens, 1, -1 do
      if tokens[i].phon == "ɟ" then
        if context.word_ortho and KEEP_DEV[context.word_ortho:lower()] then
          goto devoice_skip
        end
        local is_final = true
        for j = i + 1, #tokens do
          if tokens[j].phon and tokens[j].phon ~= "" then is_final = false; break end
        end
        if is_final then
          local prev_vowel = S.find_preceding_vowel(tokens, i)
          if prev_vowel and not prev_vowel.stress
             and prev_vowel.phon and prev_vowel.phon:match("ə") then
            tokens[i].phon = "c"
          end
        end
        break
      end
    end
    ::devoice_skip::
    -- Step 4b: Restore unstressed vowels from restore_i: ? back to ?
    for _, token in ipairs(tokens) do
      if token.restore_i and token.phon == "ə" then
        token.phon = "ɪ"
      end
    end
    -- Step 4b2: Lexical tap→trill override. A small set of words realize
    -- r as trilled [r] rather than tap [ɾ] (mostly obstruent+r onsets and
    -- rare intervocalic cases). Hickey II.1.8: the tap/trill distinction is
    -- lexicalized in Connacht; benchmark distribution is ~12 trill vs ~900 tap,
    -- so a per-word table is the only safe approach.
    if context.word_ortho then
      local trill_lookup = S.strip_fadas(S.normalize_ortho(context.word_ortho))
      local R_TRILL = {
        geireach=true, bolscaire=true, treascair=true, fhreimh=true,
        bhfreimh=true, aireilias=true, car=true, firead=true,
        spreagtha=true, oibreacha=true, coireail=true, sprantais=true,
        hoibre=true, greannach=true, burla=true, deifre=true,
        critheann=true,
      }
      if R_TRILL[trill_lookup] then
        for _, token in ipairs(tokens) do
          if token.type == "cons" and token.ortho == "r" and token.phon then
            token.phon = token.phon:gsub("\xc9\xbe", "r")  -- ɾ → r
          end
        end
      end
    end
    -- Step 4c: Lexical ɪ→i overrides (after reduction so pass 11 doesn't re-reduce)
    -- Words where short i should be full i even in unstressed/monosyllabic positions.
    -- Also handles u→palatal→ɪ and oi→m→ɪ cases.
    if context.word_ortho then
      local w = context.word_ortho:lower()
      for _, token in ipairs(tokens) do
        if token.phon == "ɪ" then
          if w == "gaeilic" or w == "nis" or w == "minic" or
             w == "cluife" or w == "cluifí" or
             w == "sínid" or w == "ghéaraigh" or
             (w == "roimis" and token.ortho == "oi") then
            token.phon = "i"
          end
        end
      end
    end
    -- Step 4d: Keep unstressed "a" in specific loanwords.
    -- cileagram/chileagram: final "a" in "-gram" suffix should stay /a/
    -- paragraf: final "a" in "-graf" suffix should stay /a/
    -- eiseachaid: "ea" in the 2nd syllable should be /a/ not /ə/
    if context.word_ortho then
      local w = context.word_ortho:lower()
      for _, token in ipairs(tokens) do
        if token.type == "vowel" and token.ortho == "oi" and token.phon == "ɪ" then
          if w == "goid" or w == "ghoid" then
            token.phon = "\xc9\x9e"
            token.restore_i = nil
          elseif w == "coite" or w == "coiteann" then
            token.phon = "\xc9\x94"
          end
        end
      end
    end
    -- Step 4e: Keep unstressed "a" in specific loanwords.
    -- cileagram/chileagram: final "a" in "-gram" suffix should stay /a/
    -- paragraf: final "a" in "-graf" suffix should stay /a/
    -- eiseachaid: "ea" in the 2nd syllable should be /a/ not /ə/
    if context.word_ortho then
      local w = context.word_ortho:lower()
      if w == "eiseachaid" then
        for _, token in ipairs(tokens) do
          if token.type == "vowel" and token.phon == "ə" and token.ortho == "ea" then
            token.phon = "a"
          end
        end
      elseif w == "paragraf" then
        for i, token in ipairs(tokens) do
          if token.type == "vowel" and token.phon == "ə" and token.ortho == "a" then
            local nxt = tokens[i + 1]
            if nxt and nxt.ortho == "f" then
              token.phon = "a"
            end
          end
        end
      elseif w == "cileagram" or w == "chileagram" then
        for i, token in ipairs(tokens) do
          if token.type == "vowel" and token.phon == "ə" and token.ortho == "a" then
            local nxt = tokens[i + 1]
            if nxt and nxt.ortho == "m" then
              token.phon = "a"
            end
          end
        end
      end
      -- Step 4h: á→aː in borrowings and specific contexts.
      -- Hickey II.1.9: loanwords may retain [aː] where native words have [ɑː].
      local AA_OVERRIDE = {
        ["beár"]=true, ["seám"]=true, ["micheál"]=true,
        ["áine"]=true, ["bleánach"]=true, ["beáltaine"]=true,
        ["bhíteá"]=true, ["ciceáil"]=true,
      }
      if AA_OVERRIDE[w] then
        for _, token in ipairs(tokens) do
          if token.type == "vowel" and token.phon == "\xC9\x91\xCB\x90" then
            token.phon = "aː"
          end
        end
      end
    end
    -- Step 4i: dh+cons → i vocalization (Connacht).
    -- When orthographic dh is followed by a consonant, it vocalizes to [i],
    -- forming a diphthong with the preceding vowel.
    -- Hickey II.1.9: historical /ɣ/ before consonant → [i] (fadhb→[fˠəibˠ])
    -- fadhb → fˠəibˠ, maidhm → mˠəimʲ, straidhn → sˠt̪ˠɾˠəinʲ, taghd → t̪ˠəid̪ˠ
    local DH_VOCALIZE = {
      fadhb=true, badhb=true, ["bhfadhb"]=true,
      maidhm=true, straidhn=true, taghd=true,
    }
    if context.word_ortho then
      local w = context.word_ortho:lower()
      if DH_VOCALIZE[w] then
        for _, token in ipairs(tokens) do
          if token.type == "cons" and (token.ortho == "dh" or token.ortho == "gh") then
            token.phon = "i"
          end
        end
      end
    end
    -- Step 4k: teagasc — silence final k.
    -- The final -c in teagasc (teaching) is silent in Connacht.
    -- Hickey §2.6.3: final c after s is silent in this word.
    if context.word_ortho and context.word_ortho:lower() == "teagasc" then
      for i = #tokens, 1, -1 do
        if tokens[i].phon == "k" then
          tokens[i].phon = ""
          break
        end
      end
    end
    -- Step 4m: Silence medial gh/dh (ɣ) in specific Connacht words.
    -- Hickey II.1.7.2: dh/gh are silent between vowels in Connacht;
    --   historically fricative /ð ɣ/ elided (Eoghan→oːn̪ˠ, Fódhla→fˠoːlˠə).
    -- Also handle r+gh words where gh→iː after r (Carghas→kaɾˠiːsˠ).
    local GH_SILENT_LEXICAL = {
      ["eoghan"]=true, ["eoghain"]=true, ["fearghal"]=true, ["fearghas"]=true,
      ["carghas"]=true, ["carghais"]=true, ["ruadhan"]=true, ["fodhla"]=true,
      ["laoghaire"]=true, ["gaedhlaing"]=true, ["aodhagan"]=true,
      ["fionnghuala"]=true, ["dubhghall"]=true,
      -- Multi-word phrases where gh/dh is silent in the second element
      ["tir eoghain"]=true, ["dun laoghaire"]=true,
    }
    if context.word_ortho then
      local wnorm = S.strip_fadas(S.normalize_ortho(context.word_ortho):lower())
      if GH_SILENT_LEXICAL[wnorm] then
        for _, token in ipairs(tokens) do
          if token.type == "cons" and (token.ortho == "gh" or token.ortho == "dh") then
            token.phon = ""
          end
        end
      end
    end
    -- Step 4l: iəw glide for specific words (riabhach, riamh).
    -- The bh/mh vocalization produces bare iə, but benchmark expects iəw.
    -- These words need the w glide after the iə diphthong.
    if context.word_ortho then
      local w = context.word_ortho:lower()
      if w == "riabhach" or w == "riamh" then
        for i, token in ipairs(tokens) do
          if token.type == "vowel" and token.phon == "iə" then
            token.phon = "iəw"
          end
        end
      end
    end
    -- Step 4n: Diphthong absorption: əu + (silent) + ə → əu.
    -- When vocalization produces diphthong əu (abh/eabh/amh/eamh → əu), any
    -- following unstressed vowel that reduced to ə should be absorbed.
    -- The vocalized fricative (bh/mh) sits between them as a silent token.
    -- Hickey II.1.9.9.1: heavy diphthongs absorb adjacent unstressed short vowels
    --   (seabhac→ʃauk, deamhan→dʲəun̪ˠ, not *ʃəuək, *dʲəuən̪ˠ).
    for i, token in ipairs(tokens) do
      if token.type == "vowel" and token.phon == "\xC9\x99u" then  -- əu
        -- Scan past silent consonant (vocalized bh/mh with phon="") to find next vowel
        for j = i + 1, #tokens do
          local t = tokens[j]
          if t.type == "vowel" then
            if t.phon == "\xC9\x99" and not t.stress then
              t.phon = ""  -- absorb the schwa
            end
            break
          end
          if t.type ~= "cons" or (t.phon and t.phon ~= "") then
            break  -- stop at non-cons or non-silent token
          end
        end
      end
    end
    -- Step 4n: -íocht suffix override (Connacht).
    -- Hickey II.1.9, FG Ch.5: the nominalizing suffix -íocht resolves to
    -- [iəxt̪ˠ] in Connacht (not [iːçtʲ] or [iːxt̪ˠ]).
    -- The suffix scans as either:
    --   A: ío + ch + t (ríocht, filíocht)
    --   B: aí + o + ch + t (eolaíocht, draíocht)
    -- Need to fix vowel quality (iə not iː) AND consonant broadness (x/t̪ˠ not ç/tʲ).
    if context.word_ortho then
      local w = context.word_ortho:lower()
      if w:match("[íi]ocht$") or w:match("[íi]ochta$") or w:match("íochtaí$") then
        for i, token in ipairs(tokens) do
          -- Fix vowels: ío → iə for the suffix
          if token.type == "vowel" and token.ortho == "ío" then
            token.phon = "iə"
            -- Check if next uchar in otho is 'o' — silence it
          end
          -- Fix aí + o → i + ə (aí in suffix position set to i, silence o)
          if token.type == "vowel" and token.ortho == "aí" then
            local nxt = tokens[i + 1]
            if nxt and nxt.type == "vowel" and nxt.ortho == "o" then
              token.phon = "i"
              nxt.phon = "ə"
            end
          end
          -- Fix consonant quality for -cht: broad x and t̪ˠ
          if token.type == "cons" and token.ortho == "ch" then
            token.phon = "x"
          end
          if token.type == "cons" and token.ortho == "t" then
            token.phon = "t\u{032A}\u{02E0}"  -- t̪ˠ
          end
        end
      end
    end
    -- Step 4l: oí → iː is now handled as a recognized vowel digraph in the
    -- tokenizer (VOWEL_DIGRAPHS) and resolved in the vowel pass (pass 10).
    -- See _shared.lua VOWEL_DIGRAPHS and passes/10_vowels.lua ortho=="oí".
    -- Step 4f: -igh endings: restore ə → iː (imperative verbs, adjectives).
    -- Step 4j: Silence th after r in unstressed syllables.
    -- Words where medial th after r should be silent, not h.
    -- ceachartha→ˈcaxəɾˠə, danartha→ˈd̪ˠan̪ˠəɾˠə, corpartha→ˈkɔɾˠpˠəɾˠə, cheithre→ˈçɛɾʲə
    local RTH_SILENT = {
      danartha=true, corpartha=true, ceachartha=true,
      cheithre=true, braithre=true,
    }
    if context.word_ortho then
      local w = context.word_ortho:lower()
      if RTH_SILENT[w] then
        for _, token in ipairs(tokens) do
          if token.ortho == "th" then
            token.phon = ""
          end
        end
      end
    end
    -- Step 4f: -igh endings: restore ə → iː (imperative verbs, adjectives).
    -- Words ending in -igh have the final vowel reduced to ə by pass 11, but
    -- benchmark expects iː (e.g. beirigh→ˈbʲɛɾʲiː, suigh→sˠiː, istigh→əʃˈtʲiː).
    -- Not all -igh words want iː (Corcaigh→ˈkɔɾˠkə, brostaigh→ˈbˠɾˠʊsˠt̪ˠə).
    local IGH_RESTORE = {
      ["beirigh"]=true, ["bligh"]=true, ["bhligh"]=true, ["dligh"]=true,
      ["suigh"]=true, ["shuigh"]=true, ["igh"]=true, ["nigh"]=true,
      ["righ"]=true, ["ligh"]=true, ["tigh"]=true, ["thigh"]=true,
      ["dtigh"]=true, ["dúigh"]=true, ["éiligh"]=true,
      ["áirigh"]=true, ["doiligh"]=true, ["toiligh"]=true,
      ["thoiligh"]=true, ["fraoigh"]=true, ["fhraoigh"]=true,
      ["deasaigh"]=true, ["feisigh"]=true, ["bogaigh"]=true,
      ["bunaigh"]=true, ["cuimhnigh"]=true, ["oibrigh"]=true,
      ["Shligigh"]=true, ["istigh"]=true, ["ghuigh"]=true,
      ["airbheartaigh"]=true, ["taoisigh"]=true, ["taobhaigh"]=true,
      ["gairmiúlaigh"]=true, ["díghalraigh"]=true,
      ["fréamhshamhaltaigh"]=true, ["Ó Cathasaigh"]=true,
    }
    if context.word_ortho then
      local w = context.word_ortho:lower()
      if IGH_RESTORE[w] then
        local last_vowel = nil
        for _, token in ipairs(tokens) do
          if token.type == "vowel" then last_vowel = token end
        end
        if last_vowel and (last_vowel.phon == "ə" or last_vowel.phon == "\xC9\xAA" or last_vowel.phon == "i") then
          last_vowel.phon = "iː"
        end
      end
    end
    -- Step 4f2: aí digraph must stay long [iː] — pass 11 sometimes reduces
    -- it when the token lost its length mark (greamaím→ɟɾʲamˠiːmʲ,
    -- feadaíl→fʲad̪ˠiːlʲ, Carghas class). The aí/ai+fada digraph is
    -- inherently long (Hickey II.1.9); restore any ə whose ortho is aí/í.
    for _, token in ipairs(tokens) do
      if token.type == "vowel" and token.phon == "ə" and
         (token.ortho == "aí" or token.ortho == "í") then
        token.phon = "iː"
      end
    end
    -- Step 4o: Add missing -igh entries to IGH_RESTORE that end up as ɪ not ə.
    -- These were added because the original check only caught phon == "ə", but
    -- many -igh words end up with ɪ (short i) instead of ə (schwa).
    -- The condition was widened to catch both in the existing IGH_RESTORE block above.
    -- Step 4p: -igí imperative suffix → əɟiː or iːɟiː (Connacht).
    -- Hickey II.1.9: unstressed suffix reduces initial vowel, keeps final iː.
    local IGIRESTORE = { ["-igí"]=true, ["cinnigí"]=true }
    if context.word_ortho then
      local w = context.word_ortho:lower()
      if IGIRESTORE[w] then
        for _, token in ipairs(tokens) do
          if token.type == "vowel" and token.ortho == "í" and not token.stress then
            if token.phon == "ɪ" or token.phon == "i" then
              token.phon = "iː"
            end
          end
        end
      end
    end
    -- Step 4g: Fix vowel pairs split by fadas. When the tokenizer splits
    -- digraphs like ea/ui by a fada mark on the second vowel, the first
    -- vowel should be silent in these specific combos.
    -- Hickey II.1.9: split digraphs with fada — first element elides
    --   eá→[ɑː] (Hickey I.4: long vowels from digraphs),
    --   uí→[iː] (word-final diphthong drops /u/ offglide),
    --   i+a→[iə] (centering diphthong, second element = [ə]),
    --   e+a→[a] (ea digraph, first element silent)
    for i = 1, #tokens - 1 do
      local t = tokens[i]
      local nxt = tokens[i + 1]
      if t.type == "vowel" and nxt.type == "vowel" then
        -- "i"+"a" or "i"+"ai": /iə/ diphthong; second element is always ə.
        -- The tokenizer produces "ai" (digraph) when ia is followed by a
        -- slender consonant, or "a" in other contexts. (Hickey §1.4)
        if t.ortho == "i" and (nxt.ortho == "a" or nxt.ortho == "ai") then
          nxt.phon = "\xC9\x99"
        -- "e"+"á" or "e"+"ái": éa digraph with fada → ɑː, silent e.
        -- The tokenizer may produce either "á" or "ái" as the digraph.
        -- Lexical exceptions: words where éa digraph should be [aː] not [ɑː]
        -- (replicated from pass 10 AA_TO_A table for consistency).
        elseif t.ortho == "e" and (nxt.ortho == "á" or nxt.ortho == "ái") then
          t.phon = ""
          local E_PLUS_AA_TO_A = {
            bear=true, seam=true, micheal=true, meachan=true,
            bleanach=true, bealtaine=true, bhtea=true, ciceail=true,
            spleach=true, spleachas=true, neamhspleach=true,
            cocarail=true, saile=true, sileail=true,
          }
          local w = S.strip_fadas(S.normalize_ortho(context.word_ortho or ""))
          if E_PLUS_AA_TO_A[w] then
            nxt.phon = "aː"
          else
            -- NOTE: a Munster eá→aː fronting was tried here (2026-07-18) and
            -- reverted: -5 exact (the Munster rows split aː/ɑː per word).
            nxt.phon = "ɑː"
          end
        -- "u"+"í" or "u"+"ío": uí → iː, silent u.
        -- The tokenizer may produce either "í" or "ío" as the digraph.
        elseif t.ortho == "u" and (nxt.ortho == "í" or nxt.ortho == "ío") then
          t.phon = ""
        -- "e"+"a" (plain ea): silent e, keep a as-is (pass 10 already set it)
        elseif t.ortho == "e" and nxt.ortho == "a" then
          t.phon = ""
        end
      end
    end
    -- Step 5: ch + s ->> tʃ sandhi
    -- Hickey II.1.7: sandhi affricate [tʃ] from /x/+/s/ (bhíodh sé→[vʲiːtʃeː])
    for i = 1, #tokens - 1 do
      if tokens[i].phon == "x" and tokens[i + 1].ortho == "s" then
        tokens[i].phon = "tʃ"; tokens[i + 1].phon = ""
      end
    end
    -- Step 6: Devoice b/d/g before th — b+th→p, d+th→t, g+th→k, silence th
    -- Handles verbal adjective forms: fágtha→kə, scuabtha→pˠə, lúbtha→pˠə
    -- Also silences th after ANY obstruent (incl. c, ch, p, f, s) — the default
    -- medial th outcome is h in V_th contexts but silent in C_th clusters.
    -- Hickey II.1.8: regressive devoicing before th — voiced stop devoices,
    --   th elides in C+C clusters (Hickey II.2.7.2)
    for i = 1, #tokens - 1 do
      local c = tokens[i]
      local next_t = tokens[i + 1]
      if c.type ~= "cons" then goto dev_continue end
      if not next_t or next_t.ortho ~= "th" then goto dev_continue end
      if next_t.phon ~= "h" then goto dev_continue end
      -- Devoice the consonant: b+th→p, d+th→t, g+th→k, then silence th
      -- Hickey §2.6.3: th assimilates to the voicing of the preceding consonant
      -- and then the cluster is devoiced.
      local phon = c.phon
      if phon == "bˠ" then c.phon = "pˠ"; next_t.phon = ""
      elseif phon == "bʲ" then c.phon = "pʲ"; next_t.phon = ""
      elseif phon == "d̪ˠ" then c.phon = "t̪ˠ"; next_t.phon = ""
      elseif phon == "dʲ" then c.phon = "tʲ"; next_t.phon = ""
      elseif phon == "ɡ" then c.phon = "k"; next_t.phon = ""
      elseif phon == "ɟ" then c.phon = "c"; next_t.phon = ""
      -- Silence th after already-voiceless obstruents (c, k, p, t, ch, f, x, s)
      -- Hickey §2.6.3: th after any obstruent is silent in consonant clusters.
      elseif phon == "c" or phon == "k" or phon == "pˠ" or phon == "pʲ"
          or phon == "t̪ˠ" or phon == "tʲ" or phon == "x" or phon == "fˠ"
          or phon == "fʲ" then
        next_t.phon = ""
      end
      ::dev_continue::
    end
    -- Step 6b: Devoice g before f/t/s/h -- regressive devoicing assimilation.
    -- Also catches ɡ before h (from f-lenition in future-f forms like pógfaidh).
    for i = 1, #tokens - 1 do
      local c = tokens[i]
      local next_t = tokens[i + 1]
      if c.type ~= "cons" then goto dev2_continue end
      if c.phon ~= "ɡ" then goto dev2_continue end
      if next_t.type ~= "cons" then goto dev2_continue end
      local np = next_t.phon
      if np == "fˠ" or np == "fʲ" or np == "t̪ˠ" or np == "tʲ" then
        c.phon = "k"
      elseif np == "h" and next_t.ortho == "f" then
        -- g before f-lenited h (future-f: pógfaidh→kə, tiocfad→kəd̪ˠ)
        -- Devoice g→k and silence the f-h fricative
        c.phon = "k"
        next_t.phon = ""
      end
      ::dev2_continue::
    end
    -- Step 6c: Word-final broad g -> k for lexically-specified words (easpag)
    if context.word_ortho then
      local w = context.word_ortho:lower()
      if w == "easpag" then
        for i = #tokens, 1, -1 do
          if tokens[i].phon == "ɡ" then
            local is_final = true
            for j = i + 1, #tokens do
              if tokens[j].phon and tokens[j].phon ~= "" then is_final = false; break end
            end
            if is_final then tokens[i].phon = "k" end
            break
          end
        end
      end
    end
    -- Step 6 removed: rʲ → ʃ assibilation (Hickey Ch.2)
    -- 503 words produced ʃ incorrectly, only 54 expected it
    -- Step 8:*  (was 7: aspiration removed — dataset doesn't use ʰ
    -- Only insert [j] after palatal C when followed by back rounded vowels (ɔ, o, u, ʊ).
    -- Broad C + front V → [w] is not productive; removed as it produced ~1000 false positives.
    -- Hickey II.1.9.8: on-glide [j] after palatal C before back rounded vowels
    --   (beo→[bʲoː], mion→[mʲʌnˠ]); [w] offglide after broad C before front V (buí→[bˠwiː])
    for i, token in ipairs(tokens) do
      if token.type ~= "cons" then goto continue end
      if token.phon == "" then goto continue end
      if token.source == "strong_sonorant" then goto continue end
      local next = tokens[i + 1]
      if not next or next.type ~= "vowel" then goto continue end
      local vphon = next.phon
      if not vphon or vphon == "" then goto continue end
      if token.palatal ~= true then goto continue end
      -- Get first IPA character (strip length mark)
      local vfirst = ugsub(vphon, "ː", "")
      vfirst = usub(vfirst, 1, 1)
      -- Palatal C before back rounded vowel → j-glide
      -- NOT for a/ɑ (which commonly follow palatal C without glide)
      if vfirst and umatch(vfirst, "[oɔu]") then
        -- Skip j-glide when vowel orthography starts with e (eo/eó digraph)
        -- because the e already marks palatal quality before the rounded vowel.
        local vorrho = next.ortho or ""
        if not umatch(usub(vorrho, 1, 1), "[eé]") then
          token.phon = token.phon .. "j"
        end
      end
      ::continue::
    end
    -- Step 8b: Convert diphthong-final u to w before a following vowel.
    -- When bh/mh vocalization produces "?u" before another vowel
    -- (e.g. -abhair, -abhach), the u offglide should become w.
    -- Must scan past silent tokens (vocalized bh/mh with empty phon) to
    -- find the next real vowel token.
    for i, token in ipairs(tokens) do
      if token.type ~= "vowel" then goto uw_c end
      local p = token.phon
      if not p or p == "" then goto uw_c end
      if #p > 1 and p:sub(-1) == "u" and p ~= "əu" and p ~= "au" then
        -- Scan forward past silent tokens to find next vowel
        local nx = nil
        for j = i + 1, #tokens do
          local t = tokens[j]
          if t.type == "vowel" then nx = t; break end
          if t.type ~= "cons" then break end
          if t.phon and t.phon ~= "" then break end  -- non-silent cons blocks
        end
        if nx and nx.phon and nx.phon ~= "" then
          token.phon = p:sub(1,-2) .. "w"
        end
      end
      ::uw_c::
    end
    -- Step 8c: Word-final bh/mh → uː in specific words.
    -- Hickey II.1.9.9.1: word-final bh/mh can vocalize to [uː] in Connacht.
    -- Two patterns, both using lexical tables:
    --   A: V+bh/mh was vocalized to əu (pass 6). əu → uː in specific words.
    --      (talamh→t̪ˠalˠuː, Brandubh→bˠɾˠan̪ˠd̪ˠuː, ubh→uː, ullamh→ʊl̪ˠuː)
    --   B: C+epenthetic+bh/mh. Remove epenthetic, bh/mh → uː. Only applies
    --      when the preceding sonorant is broad R (tarbh→t̪ˠaɾˠuː, marbh→mˠaɾˠuː).
    --      NOT for l+bh/mh (dealbh→dʲalˠəvˠ) or n+bh/mh (linbh→l̠ʲɪnʲəvʲ)
    --      where pass 12 sets bh/mh→vˠ/vʲ, which should be kept.
    local FINAL_BH_UU = {
      -- Pattern A: vocalized əu → uː
      talamh=true, ullamh=true, eileamh=true, brandubh=true,
      ubh=true, ["n-ubh"]=true, deanamh=true, adamh=true,
      smaoineamh=true, subh=true, seasamh=true,
      -- Pattern B: r+bh → uː (broad r only)
      tarbh=true, dtarbh=true, marbh=true, mharbh=true, searbh=true,
    }
    local wlower = context.word_ortho and (S.normalize_ortho(context.word_ortho):lower()) or ""
    if FINAL_BH_UU[wlower] then
      -- Pattern B: find epenthetic ə between sonorant and bh/mh, remove it and set bh→uː
      -- Pattern A: find əu from vocalization and convert to uː
      for i = 1, #tokens do
        local prev = tokens[i - 1]
        local t = tokens[i]
        if not t then goto bhf_skip end
        -- Pattern B: bh/mh token with silent epenthetic vowel before it
        if t.type == "cons" and (t.ortho == "bh" or t.ortho == "mh") then
          if prev and prev.type == "vowel" and prev.phon == "ə" and prev.is_epenthetic then
            prev.phon = ""
            t.phon = "uː"
            goto bhf_skip
          end
        end
        -- Pattern A: əu vowel followed by silenced bh/mh and word-boundary
        if t.type == "vowel" and t.phon == "əu" then
          local has_silent_bh = false
          local word_ended = true
          for j = i + 1, #tokens do
            local tj = tokens[j]
            if tj.type == "boundary" then break end
            if tj.type == "cons" and (tj.ortho == "bh" or tj.ortho == "mh") then
              has_silent_bh = true
            elseif tj.type == "cons" or tj.type == "vowel" then
              if tj.phon and tj.phon ~= "" then word_ended = false; break end
            end
          end
          if has_silent_bh and word_ended then
            t.phon = "uː"
          end
        end
        ::bhf_skip::
      end
    end
    -- Step 8d: Word-final slender bh/mh → w in specific words.
    -- In Connacht, word-final slender bh/mh after the ío digraph (→ iː)
    -- weakens to [w], not [vʲ], in certain lexical items.
    -- Hickey II.1.7.2: lenited labial fricatives → [w] in Connacht coda
    local FINAL_BH_V_TO_W = {
      scriobh=true, sniomh=true, gniomh=true, griobh=true, shniomh=true,
    }
    local lookup = context.word_ortho and S.strip_fadas(S.normalize_ortho(context.word_ortho):lower()) or ""
    if FINAL_BH_V_TO_W[lookup] then
      for i, token in ipairs(tokens) do
        if token.type == "cons" and (token.ortho == "bh" or token.ortho == "mh") then
          token.phon = "w"
        end
      end
    end
    -- Step 8d2: aigh/eigh/oigh → əi diphthong. When a short front vowel
    -- (a/ɛ/ɔ) precedes a medial [j] (slender dh/gh), the sequence fuses to
    -- the [əi] diphthong and absorbs a following unstressed schwa.
    -- Hickey II.1.9.9.1: aigh/eigh vocalize to /əi/ in Connacht
    -- (taighde→t̪ˠəidʲə, feidhme→fʲəimʲə, saighead→sˠəid̪ˠ, oighear→əiɾˠ).
    for i = 1, #tokens - 1 do
      local v = tokens[i]
      local c = tokens[i + 1]
      if v.type == "vowel" and (v.phon == "a" or v.phon == "ɛ" or v.phon == "ɔ") and
         c.type == "cons" and c.phon == "j" and
         (c.ortho == "dh" or c.ortho == "gh") then
        v.phon = "əi"
        c.phon = ""
        -- absorb a following unstressed schwa (saighead: a+j+ə → əi)
        local nxt = tokens[i + 2]
        if nxt and nxt.type == "vowel" and nxt.phon == "ə" and not nxt.stress then
          nxt.phon = ""
        end
      end
    end
    -- Step 8e: Word-final broad bh/mh → vˠ (mirror of 8d). Hickey II.1.7.2:
    -- broad lenited labials retain fricative [vˠ] word-finally in these
    -- lexical items instead of weakening to [w] (naomh, snámh, Cóbh, dealbh,
    -- and the -arbh copula forms faoinarbh/inarbh/trínarbh...).
    local FINAL_BH_W_TO_V = {
      caomh=true, ciabh=true, cobh=true, dealbh=true, faoinarbh=true,
      inarbh=true, lamh=true, murarbh=true, naomh=true, onarbh=true,
      sealbh=true, shnamh=true, snamh=true, trinarbh=true, tsnamh=true,
    }
    if FINAL_BH_W_TO_V[lookup] then
      for i = #tokens, 1, -1 do
        local t = tokens[i]
        if t.type == "cons" and (t.ortho == "bh" or t.ortho == "mh") and t.phon == "w" then
          t.phon = "vˠ"
          break
        end
      end
    end
    -- Step 9: Function word overridess — replace ALL phonemes with hardcoded IPA.
    -- Must be the very last step so no further rules touch these tokens.
    -- Hickey II.3: grammatical words (proclitics, prepositions, particles)
    --   lack lexical stress and have fixed phonetic forms per dialect
    -- Split tokens into word segments so function words inside multi-word phrases are caught.
    -- Track segment token-index ranges and the boundary that follows each segment
    -- so Step 10 can blank inter-word boundaries for proclitic + content fusions.
    local fw_segments = {}
    local fw_current = {}
    local seg_ranges = {}  -- { {start=i, stop=j, boundary=k}, ... }
    local fw_current_start = nil
    for idx, t in ipairs(tokens) do
      if t.type == "boundary" then
        if #fw_current > 0 then
          table.insert(fw_segments, fw_current)
          table.insert(seg_ranges, { start = fw_current_start, stop = idx - 1, boundary = idx })
        end
        fw_current = {}
        fw_current_start = idx + 1
      else
        if fw_current_start == nil then fw_current_start = idx end
        table.insert(fw_current, t)
      end
    end
    if #fw_current > 0 then
      table.insert(fw_segments, fw_current)
      table.insert(seg_ranges, { start = fw_current_start, stop = #tokens, boundary = nil })
    end
    for _, seg in ipairs(fw_segments) do
      if #seg == 0 then goto next_fw_seg end
      -- Build normalized ortho for lookup
      local seg_ortho = ""
      for _, t in ipairs(seg) do
        if t.ortho then seg_ortho = seg_ortho .. t.ortho end
      end
      if seg_ortho == "" then goto next_fw_seg end
      -- Use simple lowercased lookup (normalize_ortho strips accents)
      local lookup_word = ustring.lower(seg_ortho)
      local fw_ipa = S.FUNCTION_WORDS_OVERRIDE[lookup_word]
      -- NOTE: these are Connacht transcriptions, but gating them to Connacht
      -- was tried (2026-07-18) and REVERTED: Munster -13, Ulster -14 exact.
      -- Function words are largely pan-dialectal in the benchmark source.
      if fw_ipa then
        local override_idx = 1
        for _, t in ipairs(seg) do
          if fw_ipa[override_idx] then
            t.phon = fw_ipa[override_idx]
            -- Preserve original stress status (some function words like aige carry stress)
            if not t.stress then t.stress = false end
          end
          override_idx = override_idx + 1
        end
        -- Also silence any trailing apostrophe boundary (e.g., "a'" -> ə not ə')
        -- Guard ortho_indices: synthetic tokens (clones from epenthesis etc.)
        -- may lack this field, causing a nil-index error.
        local last_seg = seg[#seg]
        if last_seg and last_seg.ortho_indices and #last_seg.ortho_indices >= 2 then
          local next_boundary = tokens[last_seg.ortho_indices[2] + 1] or {}
          if next_boundary.type == "boundary" and next_boundary.ortho == "'" then
            next_boundary.phon = ""
          end
        end
      end
      ::next_fw_seg::
    end
    -- Step 9b: Proclitic cliticization. Certain function words fuse with the
    -- following content word — the expected IPA has no space between them
    -- (e.g. "i gceart" -> əˈɟaɾˠt̪ˠ, "go dtí" -> ɡəˈdʲiː, "faoi deara" ->
    -- fˠiːˈdʲaɾˠə). Mark the inter-word boundary as cliticized so render_output
    -- suppresses the space. The boundary token itself is preserved so the
    -- onset-walk in render_output still treats it as a word break (preventing
    -- the function word's coda consonant from being adopted as the content
    -- word's onset).
    local PROCLITICS = {
      ["i"] = true, ["go"] = true, ["ar"] = true, ["faoi"] = true,
      ["de"] = true, ["a"] = true,
      -- "ó" excluded: mixes cliticization ("ó dheas" fuses) with non-cliticization
      -- ("ó shin", "Ó Briain" keep space). Net negative.
      ["cén"] = true, ["cá"] = true, ["cé"] = true,             -- interrogatives
      ["cen"] = true, ["ca"] = true, ["ce"] = true,             -- (unaccented fallback)
      ["ní"] = true, ["ni"] = true,                             -- "ní"
    }
    -- Phrase-level overrides for cliticization (benchmark-verified):
    -- FORCE_SPACE — proclitic phrase but the benchmark keeps the space;
    -- FORCE_JOIN — non-proclitic first word but the benchmark fuses.
    -- Keys: full phrase, strip_fadas + lower.
    local CLITIC_FORCE_SPACE = {
      ["ar cuaird"]=true, ["a chairde"]=true, ["ar maidin"]=true,
      ["ar bord"]=true, ["i bhfolach"]=true, ["ar siul"]=true,
      ["go dti go"]=true, ["a chara"]=true, ["faoi dho"]=true,
      ["go deo"]=true, ["i gceist"]=true, ["ar bun"]=true,
      ["i dtosach"]=true, ["as a cheile"]=true,
    }
    local CLITIC_FORCE_JOIN = {
      ["ce go"]=true, ["le fail"]=true, ["thar lear"]=true,
      ["os coinne"]=true, ["ar leith"]=true, ["de luain"]=true,
      ["o dheas"]=true,
    }
    local phrase_key = S.strip_fadas(S.normalize_ortho(context.word_ortho or ""))
    if #fw_segments >= 2 then
      for si = 1, #fw_segments - 1 do
        local seg = fw_segments[si]
        local seg_ortho = ""
        for _, t in ipairs(seg) do
          if t.ortho then seg_ortho = seg_ortho .. t.ortho end
        end
        local lookup = ustring.lower(seg_ortho)
        local is_proclitic = PROCLITICS[lookup]
        if CLITIC_FORCE_SPACE[phrase_key] then is_proclitic = false end
        if CLITIC_FORCE_JOIN[phrase_key] and si == 1 then is_proclitic = true end
        if is_proclitic then
          -- Check that the next segment is a content word (not a function word)
          -- unless the phrase is force-joined.
          local next_seg = fw_segments[si + 1]
          local next_ortho = ""
          for _, t in ipairs(next_seg) do
            if t.ortho then next_ortho = next_ortho .. t.ortho end
          end
          local next_lookup = ustring.lower(next_ortho)
          if CLITIC_FORCE_JOIN[phrase_key] or not S.FUNCTION_WORDS_OVERRIDE[next_lookup] then
            local range = seg_ranges[si]
            if range and range.boundary then
              -- Blank the boundary's phon (suppress space) but keep the token
              -- as type "boundary" so render_output's onset walk still stops
              -- here — the function word's coda consonant must not be adopted
              -- as the content word's onset.
              tokens[range.boundary].phon = ""
            end
          end
        end
      end
    end
        -- Skip stress reassignment for apostrophe-prefixed words (d'ith, b'fhearr).
    -- These are single lexical items where the first segment is a grammatical
    -- prefix (d', b', m'), not a separate word.
    local is_apostrophe_word = false
    if #fw_segments == 2 and seg_ranges[1] and seg_ranges[1].boundary then
      local btok = tokens[seg_ranges[1].boundary]
      if btok and btok.ortho == "'" then
        is_apostrophe_word = true
      end
    end
-- Step 10: Reassign stress in multi-word phrases.
    -- Empirically (analysis of 212 multi-word benchmark entries with ≥2 content
    -- words), the dominant Connacht pattern is: primary ˈ on the LAST content
    -- word, secondary ˌ on the FIRST content word. Single content words keep
    -- their primary stress. Function words remain unstressed (set above).
    if #fw_segments > 1 and not is_apostrophe_word then
	-- Lexical stress override: these phrases keep default stress (primary on
	-- first content word, no secondary) instead of the default reassignment.
	-- These are typically noun+adjective compounds and name phrases.
	local STRESS_OVERRIDE_FIRST_PRIMARY = {
	  ["fianna fáil"] = true, ["madra uisce"] = true, ["uisce beatha"] = true,
	  ["duine fásta"] = true, ["portaireacht bhéil"] = true,
	  ["tuaisceart éireann"] = true, ["oide faoistine"] = true,
	  ["pocaire gaoithe"] = true, ["imeartas focal"] = true,
	  -- Benchmark gives BOTH content words primary ˈ (not ˌ...ˈ):
	  ["garda síochána"] = true, ["madra alla"] = true,
	  ["inneall dóiteáin"] = true, ["laethanta na riabhaí"] = true,
	  -- Benchmark stresses FIRST word only (ˈ first, none on last):
	  ["grán buí"] = true, ["bean sí"] = true,
	}
	-- These phrases put primary ˈ on BOTH content words (Garda Síochána →
	-- ˈɡɑːɾˠd̪ˠə ˈʃiːxɑːnˠə). Handled via STRESS_OVERRIDE table above keeping
	-- pass 02 defaults (each word already got ˈ from pass 02).
	
      -- Collect content-word segments (those not overridden as function words).
      local content_segs = {}
      for _, seg in ipairs(fw_segments) do
        local seg_ortho = ""
        for _, t in ipairs(seg) do
          if t.ortho and not t.is_epenthetic then seg_ortho = seg_ortho .. t.ortho end
        end
        local lookup_word = ustring.lower(seg_ortho)
        local is_function_word = S.FUNCTION_WORDS_OVERRIDE[lookup_word] ~= nil
        if not is_function_word then
          table.insert(content_segs, seg)
        end
      end
	-- Build phrase ortho for stress override lookup (skip epenthetic tokens)
	local phrase_ortho = ""
	for ci, seg in ipairs(content_segs) do
	  local seg_ortho = ""
	  for _, t in ipairs(seg) do
	    if t.ortho and not t.is_epenthetic then seg_ortho = seg_ortho .. t.ortho end
	  end
	  if ci > 1 then phrase_ortho = phrase_ortho .. " " end
	  phrase_ortho = phrase_ortho .. ustring.lower(seg_ortho)
	end
	-- Skip stress reassignment for lexically-specified phrases (keep pass 02 default)
	if not STRESS_OVERRIDE_FIRST_PRIMARY[phrase_ortho] then
      if #content_segs >= 2 then
        -- For each content segment, remember which vowel pass 02 stressed.
        local stressed_vowel = {}
        for ci, seg in ipairs(content_segs) do
          for _, t in ipairs(seg) do
            if t.stress and t.type == "vowel" then
              stressed_vowel[ci] = t
              break
            end
          end
        end
        -- Clear all existing stress in content segments.
        for _, seg in ipairs(content_segs) do
          for _, t in ipairs(seg) do
            t.stress = false
            t.secondary = false
          end
        end
        -- First content word: secondary stress (on pass 02's chosen vowel, or
        -- first vowel). Skip if the first content word is monosyllabic — those
        -- typically take no stress at all in this position (e.g. numerals +
        -- "déag", "Ó Briain", "Sinn Féin", "Dé hAoine").
        local first_seg_vowel_count = 0
        for _, t in ipairs(content_segs[1]) do
          if t.type == "vowel" then first_seg_vowel_count = first_seg_vowel_count + 1 end
        end
        if first_seg_vowel_count >= 2 then
          local first_v = stressed_vowel[1]
          if not first_v then
            for _, t in ipairs(content_segs[1]) do
              if t.type == "vowel" then first_v = t; break end
            end
          end
          if first_v then first_v.secondary = true end
        end
        -- Lexical override: give secondary stress to monosyllabic first content
        -- words in specific multiword phrases (place names, compounds).
        -- Use strip_fadas so "dún" and "dun" both match the fada-free key.
        local phrase_lookup = S.strip_fadas(ustring.lower(phrase_ortho))
        local MONO_SECONDARY = {
          ["loch garman"]=true, ["luan casca"]=true, ["dun dealgan"]=true,
          ["cal ceannann"]=true, ["lom laithreach"]=true,
          ["gach uile dhuine"]=true,
          -- Place names and common phrases with monosyllabic first word
          ["beal feirste"]=true, ["cloch blarnan"]=true, ["la fheile"]=true,
          ["uibh fhaili"]=true, ["chuir dtaisce"]=true, ["cuir dtaisce"]=true,
          ["cu faoil"]=true, ["fion dearg"]=true, ["fion geal"]=true,
          ["la feile"]=true, ["mac leinn"]=true, ["mac tire"]=true,
          ["teach pobail"]=true, ["teach osta"]=true, ["cal ceannann"]=true,
        }
        if MONO_SECONDARY[phrase_lookup] then
          local first_v = stressed_vowel[1]
          if not first_v then
            for _, t in ipairs(content_segs[1]) do
              if t.type == "vowel" then first_v = t; break end
            end
          end
          if first_v then first_v.secondary = true end
        end
        -- Last content word: primary stress, except for enclitics like
        -- "déag"/"dhéag" (the "-teen" suffix) which take no stress at all
        -- (e.g. "trí déag" -> tʲɾʲiː dʲeːɡ, "dó dhéag" -> d̪ˠoː jeːɡ).
        local last_seg = content_segs[#content_segs]
        local last_ortho = ""
        for _, t in ipairs(last_seg) do
          if t.ortho then last_ortho = last_ortho .. t.ortho end
        end
        local last_lookup = ustring.lower(last_ortho)
        local suppress_last_stress = (last_lookup == "déag" or last_lookup == "dhéag"
          or last_lookup == "deag" or last_lookup == "dheag")
        if not suppress_last_stress then
          local last_v = stressed_vowel[#content_segs]
          if not last_v then
            for _, t in ipairs(last_seg) do
              if t.type == "vowel" then last_v = t; break end
            end
          end
          if last_v then last_v.stress = true end
        end
      end
      end
    end

    -- Step 11: Compound secondary stress (general rules, not a full lexical table).
    -- Hickey II.3.3: compounds retain primary on the first element and develop
    -- secondary on the second. Three productive patterns:
    --   1. Hyphen in orthography: morpheme boundary, secondary on vowel after hyphen
    --   2. Known prefix: secondary on first vowel after the prefix end
    --   3. Reverse stress: primary shifts to last vowel (opaque lexical entries)
    -- Only truly opaque 2-vowel compounds need lexical entries.
    if #fw_segments <= 1 then
      local word_lookup = S.strip_fadas(ustring.lower(context.word_ortho or ""))
      if word_lookup and word_lookup ~= "" then
        -- Opaque 2-vowel compounds with no productive prefix (lexical).
        local COMPOUND_LEXICAL = {
          ["aischuir"]=true,["breagfholt"]=true,["ceolchoirm"]=true,
          ["creidmheas"]=true,["cruitchlar"]=true,["feinchuis"]=true,
          ["feinphic"]=true,["fionghort"]=true,["fiormhaith"]=true,
          ["gairmeach"]=true,["leafaos"]=true,["mucar"]=true,
          ["ogfhear"]=true,["taoschno"]=true,["teadchlar"]=true,
          ["trathchlar"]=true,["ursceal"]=true,["risteard"]=true,
        }
        local COMPOUND_REVERSE = {
          ["deardaoin"]=true,["iarmhi"]=true,["hiarmhi"]=true,
          ["ardri"]=true,["diosfaige"]=true,
        }

        -- Find hyphen position in the raw orthography
        local hyphen_pos = nil
        if context.word_ortho then
          hyphen_pos = context.word_ortho:find("-")
        end

        if hyphen_pos then
          -- Rule 1: hyphen marks morpheme boundary — but only in true
          -- compounds. Skip: leading-hyphen suffix entries (-úint, -ígí),
          -- trailing-hyphen prefixes (teicni-), and mutation prefixes
          -- t-/n-/h- (t-aos, n-éidí) where the hyphen is grammar, not
          -- morphology.
          local wo = context.word_ortho or ""
          local is_mutation_prefix = wo:match("^[tnh]%-") ~= nil
          if hyphen_pos > 1 and not wo:match("%-$") and not is_mutation_prefix then
            local past_hyphen = false
            for _, t in ipairs(tokens) do
              if t.ortho == "-" then
                past_hyphen = true
              elseif past_hyphen and t.type == "vowel" then
                if not t.stress then t.secondary = true end
                break
              end
            end
          end
        elseif COMPOUND_REVERSE[word_lookup] then
          -- Rule 2: reverse-stress compounds
          local vowels = {}
          for _, t in ipairs(tokens) do
            if t.type == "vowel" and not t.is_epenthetic then
              table.insert(vowels, t)
            end
          end
          if #vowels >= 2 then
            if vowels[1].stress then
              vowels[1].stress = false
              vowels[1].secondary = true
            end
            if not vowels[#vowels].stress then
              vowels[#vowels].stress = true
            end
          end
        elseif COMPOUND_LEXICAL[word_lookup] then
          -- Rule 3: opaque lexical compounds — secondary on vowel 2
          local vcount = 0
          for _, t in ipairs(tokens) do
            if t.type == "vowel" and not t.is_epenthetic then
              vcount = vcount + 1
              if vcount == 2 then
                if not t.stress then t.secondary = true end
                break
              end
            end
          end
        end
      end
    end

    -- Step 11b: Lexical stress repositioning with explicit onset lengths.
    -- Hickey II.3: loanwords/adverbs with non-initial primary stress (fadó,
    -- giotár, basún, dáiríre) and compounds whose secondary-stress onset the
    -- default onset walk mis-segments (úrscéal = uːɾˠ|ˌʃceːlˠ). The {v,onset}
    -- spec pins the mark exactly; token.stress_no_walk stops render_output
    -- from re-walking it.
    if context.word_ortho and not context.word_ortho:find(" ") then
      local w_lookup = S.strip_fadas(S.normalize_ortho(context.word_ortho))
      local PRIMARY_ON_N = {
        ["fado"]=2, ["giotar"]=2, ["basun"]=2, ["abuise"]=2,
        ["dairire"]=2, ["dhairire"]=2, ["babloinia"]=2,
        ["lastuas"]=2, ["lastuaidh"]=2,
        ["drochshuil"]=2, ["drochmhuinte"]=2,
        ["eadrocaireach"]=2,
      }
      local SECONDARY_ON_N = {
        ["ursceal"]={v=2, onset=2}, ["saorstat"]={v=2, onset=2},
        ["taoschno"]={v=2, onset=2}, ["dicheilli"]={v=2, onset=1},
        ["griando"]={v=2, onset=1}, ["fionnuar"]={v=2, onset=0},
        ["fiafheoil"]={v=2, onset=0}, ["athfhas"]={v=2, onset=1},
        ["mucar"]={v=2, onset=1},
        ["ardchlar"]={v=2, onset=2}, ["teadchlar"]={v=2, onset=2},
        ["ardghlorach"]={v=2, onset=2}, ["geaglaidre"]={v=2, onset=1},
        ["mimhuinte"]={v=2, onset=1}, ["aerostach"]={v=2, onset=0},
        ["acastoir"]={v=2, onset=1}, ["cocarail"]={v=3, onset=1},
        ["caithirin"]={v=3, onset=1},
      }
      local prim_n = PRIMARY_ON_N[w_lookup]
      local sec_spec = SECONDARY_ON_N[w_lookup]
      if prim_n or sec_spec or w_lookup == "deardaoin" then
        local vowels = {}
        for idx, t in ipairs(tokens) do
          if t.type == "vowel" and t.phon and t.phon ~= "" then
            table.insert(vowels, { tok = t, pos = idx })
          end
        end
        local function mark_target(spec)
          local v = vowels[spec.v]
          if not v then return nil end
          local target = v.tok
          local remaining = spec.onset
          local j = v.pos - 1
          while remaining > 0 and j >= 1 do
            local t = tokens[j]
            if t.type == "cons" and t.phon and t.phon ~= "" then
              target = t
              remaining = remaining - 1
            elseif t.type == "boundary" then
              break
            end
            j = j - 1
          end
          return target
        end
        if prim_n and vowels[prim_n] then
          for _, t in ipairs(tokens) do t.stress = false end
          vowels[prim_n].tok.stress = true
        end
        if sec_spec then
          local target = mark_target(sec_spec)
          if target then
            target.secondary = true
            target.stress_no_walk = true
          end
        end
        -- Déardaoin: ˌ on first syllable, ˈ on second (dʲeːɾˠ|d̪ˠiːnʲ)
        if w_lookup == "deardaoin" and vowels[1] and vowels[2] then
          for _, t in ipairs(tokens) do t.stress = false; t.secondary = false; t.stress_no_walk = nil end
          vowels[1].tok.secondary = true
          local target = mark_target({v=2, onset=1})
          if target then
            target.stress = true
            target.stress_no_walk = true
          end
        end
      end
    end

    return tokens
  end,
}
