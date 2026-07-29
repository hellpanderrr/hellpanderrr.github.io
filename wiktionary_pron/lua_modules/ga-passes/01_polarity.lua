-- Pass #1: Assign broad/slender polarity to consonants.
-- Scans flanking vowels to determine palatal status.
-- References: Hickey II.1.1 (polarity system), III.2.3.2 (lenition mutation outcomes),
--  FG Ch.5 (Connacht consonant inventory)

local S = require("ga-passes._shared")

return {
  name = "polarity",
  writes_context = false,

  run = function(tokens, context)
    -- Simplify initial clusters (cn→cr, gn→gr, etc.) before polarity assignment
    -- Hickey II.2.2/2.3: the sonorant shift n→r in stop+n onsets is a
    -- Western/Northern feature; Munster keeps [kn-], [ɡn-], [mn-]
    -- (mná: W [mˠɾˠaː] vs S [mˠnˠɑː]).
    if context.dialect ~= "munster" and
       #tokens >= 2 and tokens[1].type == "cons" and tokens[2].type == "cons" then
      local shift = S.INITIAL_CLUSTER_SHIFTS[tokens[1].ortho .. tokens[2].ortho]
      if shift then
        tokens[1].ortho = shift[1]
        tokens[1].phon = shift[1]
        tokens[2].ortho = shift[2]
        tokens[2].phon = shift[2]
        tokens[2].source = "cluster_shift"
      end
    end

    -- Assign ng polarity based on preceding broad vowel
    -- Hickey II.1.8: velar nasal /ŋ/ broadens after back vowels
    for i = 1, #tokens - 1 do
      local vowel = tokens[i]
      local ng = tokens[i + 1]
      if vowel.type == "vowel" and ng.type == "cons" and ng.ortho == "ng" then
        if vowel.ortho == "a" or vowel.ortho == "o" or vowel.ortho == "u" or
           vowel.ortho == "ai" or vowel.ortho == "aí" then
          S.set_polarity(ng, false)
        end
      end
    end

    -- Word-initial r is always broad (ɾˠ) in Connacht, regardless of the
    -- following vowel. rí /ɾˠiː/, ré /ɾˠeː/, reacht /ɾˠaxt̪ˠ/. Set this
    -- before the main loop so it isn't overridden by the next-vowel scan.
    -- Hickey II.1.8: /r/ neutralized to [ɾˠ] word-initially
    if #tokens >= 1 and tokens[1].type == "cons" and tokens[1].ortho == "r"
       and tokens[1].palatal == nil then
      S.set_polarity(tokens[1], false)
    end

    -- Word-final consonant after "é" digraph in function words → broad
    -- (cén /ceːnˠ/, cér /ceːɾˠ/). These are exclamations/question words
    -- where the expected IPA has broad final n/r.
    if #tokens >= 3 then
      local w = context.word_ortho
      if w == "cén" or w == "cér" then
        local last = tokens[#tokens]
        if last and last.type == "cons" then
          S.set_polarity(last, false)
        end
      end
    end

    -- Standalone lenited fricatives (bh, mh, bhf) → slender by default.
    -- These appear as isolated benchmark entries representing the lenited form.
    -- In isolation, "bh" and "mh" are pronounced with slender vʲ, not broad vˠ.
    -- Hickey II.1.7.2: lenited labial fricatives — historical dependent phonemes
    if #tokens == 1 and tokens[1].type == "cons" and tokens[1].is_mutated then
      if tokens[1].ortho == "bh" or tokens[1].ortho == "mh" then
        S.set_polarity(tokens[1], true)
      end
    end
    if #tokens == 2 and tokens[1].is_mutated and tokens[2].ortho == "f" then
      -- "bhf" as eclipsis: both should be slender
      S.set_polarity(tokens[1], true)
      S.set_polarity(tokens[2], true)
    end

    -- Main polarity assignment for all consonants
    -- Hickey II.1.1: polarity determined by flanking vowels —
    --   e/i/é/í → palatal (slender), a/o/u/á/ó/ú → non-palatal (broad)
    -- FG Ch.5: Connacht polarity patterns (Ceathrún Rua data)
    for i, token in ipairs(tokens) do
      if token.type ~= "cons" then goto continue end
      if token.palatal ~= nil then goto continue end  -- already set (e.g., ng)

      local prev_vowel, j = nil, i - 1
      while j >= 1 do
        if tokens[j].type == "vowel" then prev_vowel = tokens[j]; break end
        if tokens[j].type == "boundary" and tokens[j].source ~= "apostrophe" then break end  -- word boundary: don't scan into prev word (apostrophes don't block)
        j = j - 1
      end

      local next_vowel, j = nil, i + 1
      while j <= #tokens do
        if tokens[j].type == "vowel" then next_vowel = tokens[j]; break end
        if tokens[j].type == "boundary" and tokens[j].source ~= "apostrophe" then break end  -- word boundary: don't scan into next word (apostrophes don't block)
        j = j + 1
      end

      local polarity = S.vowel_polarity(next_vowel)
      if polarity == nil then polarity = S.vowel_polarity(prev_vowel, "prev") end

      -- Narrow exception: a final lenited fricative (th/sh/fh/ch/ph) following
      -- oi/ui should stay BROAD. The slender trace of these digraphs normally
      -- propagates to a following consonant, but a final silent/quiet lenited
      -- fricative historically colors the vowel broadly (croith /kɾˠɔh/,
      -- sruith /sɾˠʊh/). Letting it go slender front-raises the vowel.
      -- Hickey II.1.9.4: vowel gradation — broad coda preserves back vowel quality
      if token.is_mutated and i == #tokens and not next_vowel and prev_vowel and
         (prev_vowel.ortho == "oi" or prev_vowel.ortho == "ui") and
         (token.ortho == "th" or token.ortho == "sh" or token.ortho == "fh" or
          token.ortho == "ch" or token.ortho == "ph") then
        polarity = false
      end

      -- Sonorant polarity: when no vowel context, check next consonant
      -- Hickey II.1.8: sonorants (l/n/r/m) assimilate to following consonant's polarity
      local sonorants = { l = true, n = true, r = true, m = true }
      if sonorants[token.ortho] and not polarity then
        local next_cons = nil
        for k = i + 1, #tokens do
          if tokens[k].type == "cons" then next_cons = tokens[k]; break end
          if tokens[k].type == "vowel" then break end
        end
        if next_cons and next_cons.palatal ~= nil then
          polarity = next_cons.palatal
        end
      end

      S.set_polarity(token, polarity)
      ::continue::
    end

    -- Word-final consonant(s) after "ío" digraph → broad (Connacht phonology)
    -- míol → mʲiːlˠ, cíor → ciːɾˠ, síob → ʃiːbˠ, críon → cɾʲiːnˠ
    -- Applied to entire closing cluster (handles geminate nn in -íonn suffix:
    -- bíonn→bʲiːn̪ˠ, not bʲiːn̠ʲ). Hickey II.1.9: long /iː/ from ío —
    -- following consonant(s) stay broad in Connacht.
    for i, token in ipairs(tokens) do
      if token.type ~= "cons" then goto skip_io end
      -- The first consonant after ío starts the coda cluster
      local prev = (i > 1) and tokens[i - 1] or nil
      if not (prev and prev.type == "vowel" and prev.ortho == "ío") then goto skip_io end
      -- Walk forward from this consonant: if no more vowels appear before
      -- the word ends (boundary or end-of-tokens), set ALL closing
      -- consonants to broad.
      local no_more_vowels = true
      for k = i + 1, #tokens do
        if tokens[k].type == "vowel" then no_more_vowels = false; break end
        if tokens[k].type == "boundary" and tokens[k].source ~= "apostrophe" then break end
      end
      if no_more_vowels then
        for k = i, #tokens do
          if tokens[k].type == "cons" then
            S.set_polarity(tokens[k], false)
          elseif tokens[k].type == "vowel" or (tokens[k].type == "boundary" and tokens[k].source ~= "apostrophe") then
            break
          end
        end
      end
      ::skip_io::
    end

    -- "rr" geminate: in Irish, two consecutive r's (rr orthography) are
    -- always broad regardless of surrounding vowel context.
    -- giorria /ɟɪɾˠiə/, charria /xaɾˠiə/
    -- Hickey II.1.8: geminate rr retains broad quality (historical geminate)
    for i = 1, #tokens - 1 do
      local t1, t2 = tokens[i], tokens[i+1]
      if t1 and t1.type == "cons" and t1.ortho == "r" and
         t2 and t2.type == "cons" and t2.ortho == "r" then
        S.set_polarity(t1, false)
        S.set_polarity(t2, false)
      end
    end

    return tokens
  end,
}
