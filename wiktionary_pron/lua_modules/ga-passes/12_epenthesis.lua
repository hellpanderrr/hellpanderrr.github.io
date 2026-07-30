-- Pass #12: Epenthesis (Svarabhakti vowel insertion).
-- Inserts a vowel between heterorganic sonorant+voiced-obstruent
-- clusters when the preceding vowel is SHORT and STRESSED.
-- NOT restricted to monosyllables. (Corrected per Hickey II.2.8)
-- References: Hickey II.2.8 (svarabhakti — sonorant + heterorganic obstruent → vowel insertion)

local S = require("ga-passes._shared")

-- Hickey II.2.8: heterorganic clusters trigger epenthesis:
--   sonorant (l,n,r) + heterorganic voiced obstruent (b,d,g) or fricative (ch,f,m,bh,mh)
--   Condition: preceding vowel is SHORT and STRESSED
local function is_heterorganic_cluster(tokens, i)
  local t1 = tokens[i]
  local t2 = tokens[i + 1]
  if not t1 or not t2 then return false end
  -- Heterorganic: sonorant followed by a different-place obstruent
  -- Broad clusters: rC, lC, nC (where C is a stop like b/d/g)
  local sonorants_broad = { r = true, l = true, n = true }
  if sonorants_broad[t1.ortho] then
    if t2.ortho == "b" or t2.ortho == "d" or t2.ortho == "g" then
      return true
    end
  end
  return false
end

return {
  name = "epenthesis",
  writes_context = false,

  run = function(tokens, context)
    local new_tokens = {}
    local i = 1
    while i <= #tokens do
      table.insert(new_tokens, tokens[i])

      -- Check: current token is sonorant, next is heterorganic obstruent or fricative
      -- Hickey §2.8: Svarabhakti occurs between sonorants and following heterorganic
      -- consonants — not just voiced stops. r+ch (dorchadas), r+f (dearfa),
      -- r+m (gairme), n+ch (seanchas), l+m (calma), r+bh/r+mh (thairbhe, dearbhú)
      -- all take epenthetic schwa.
      -- Exclude homorganic clusters (rd, rl, rn, nd, ld) — Hickey §2.8
      local cur_ortho = tokens[i].ortho
      local next_ortho = tokens[i + 1] and tokens[i + 1].ortho
      local is_homorganic = (cur_ortho == "r" and (next_ortho == "d" or next_ortho == "l" or next_ortho == "n")) or
        (cur_ortho == "n" and next_ortho == "d") or (cur_ortho == "l" and next_ortho == "d")
      -- NOTE: bh/mh stay in this generic branch. Excluding them (so only the
      -- dedicated l+bh/mh branch below fires) was measured at -31 Connacht /
      -- -37 Munster: the dedicated branch gates on word-final position, so the
      -- exclusion silently drops legitimate medial svarabhakti. Do not re-apply.
      if S.is_sonorant(tokens[i]) and tokens[i + 1] and not is_homorganic and
         (S.is_voiced_obstruent(tokens[i + 1]) or
          tokens[i + 1].ortho == "ch" or
          tokens[i + 1].ortho == "f" or
          tokens[i + 1].ortho == "m" or
          tokens[i + 1].ortho == "bh" or
          tokens[i + 1].ortho == "mh") then

        -- Skip epenthesis before future -f- suffixes (f + vowel + dh/d/s/mid).
        -- The f in future-tense markers (-fidh, -faidh, -feadh, -fas, -faimid)
        -- is a morphemic suffix, not a genuine heterorganic cluster trigger.
        if tokens[i + 1].ortho == "f" then
          local f_next1 = tokens[i + 2]
          local f_next2 = tokens[i + 3]
          if f_next1 and f_next1.type == "vowel" then
            local is_suffix = (f_next1.ortho == "\xC3\xA1")  -- -fá (no f_next2)
            if not is_suffix and f_next2 then
              is_suffix = (f_next1.ortho == "i" and f_next2.ortho == "dh")
                or (f_next1.ortho == "ai" and (f_next2.ortho == "dh" or f_next2.ortho == "mid"))
                or (f_next1.ortho == "ea" and (f_next2.ortho == "d" or f_next2.ortho == "dh"))
                or (f_next1.ortho == "a" and (f_next2.ortho == "s" or f_next2.ortho == "dh" or f_next2.ortho == "r"))
            end
            if is_suffix then
              goto skip_epenthesis
            end
          end
        end

        -- Find preceding vowel
        local prev_vowel = S.find_preceding_vowel(tokens, i)
        -- Condition: preceding vowel is stressed AND short
        -- Monosyllabic words (dearg, gorm) have context.is_monosyllabic=true
        -- but their vowel token lacks stress=true, so check both.
        -- Munster: epenthesis also applies in UNSTRESSED syllables (Ó Sé §2.8:
        -- svarabhakti is general in Munster — Colmán→kəl̪ˠəˈmˠɑːn̪ˠ,
        -- purgóid→pˠəɾˠəˈɡoːdʲ, ionnarb — because stress attraction moves
        -- primary stress off the cluster's syllable).
        if prev_vowel and S.is_short_vowel(prev_vowel) and
           (prev_vowel.stress or context.is_monosyllabic
            or context.dialect == "munster") then
          -- Insert epenthetic vowel (always ə initially)
          -- Lexical overrides: feirge/deirge expect ɪ instead.
          local epenthetic = S.clone_token(tokens[i])
          epenthetic.type = "vowel"
          epenthetic.phon = "\xc9\x99"  -- ə
          epenthetic.is_epenthetic = true
          epenthetic.stress = false
          epenthetic.source = "epenthesis"
          if tokens[i].palatal == true then
            epenthetic.ortho = "i"
          else
            epenthetic.ortho = "a"
          end
          if context.word_ortho and epenthetic.ortho == "i" then
            local w = context.word_ortho:lower()
            -- Slender r+g epenthesis takes ɪ, not ə, in -irg(e) words
            -- (Hickey II.2.8: svarabhakti vowel copies frontness of the
            -- flanking slender context). This also blocks final devoicing
            -- ɟ→c in pass 14 Step 4, which requires preceding ə.
            if w == "feirge" or w == "deirge" or w == "gairge" or
               w:match("airg$") or w:match("eirg$") then
              epenthetic.phon = "\xc9\xaa"  -- ɪ
            end
          end
          table.insert(new_tokens, epenthetic)
          -- Hickey II.3 + II.2.8: svarabhakti makes a monosyllabic root
          -- disyllabic (dearg → dʲaɾˠəɡ); disyllabic content words carry
          -- primary stress on the first syllable. Pass 02 skipped stress
          -- because it saw one vowel. Grammatical words (orm, "-as", d'/b'
          -- forms) keep no stress via context.no_lexical_stress.
          if not prev_vowel.stress and context.is_monosyllabic and
             not context.no_lexical_stress and context.word_ortho and
             not context.word_ortho:find(" ") then
            prev_vowel.stress = true
          end
        end

      -- Also handle l+bh/mh cluster: insert epenthetic schwa and change bh/mh -> vˠ/vʲ
      -- e.g. dealbh -> dʲalˠəvˠ, colbha -> kɔlˠəvˠə
      -- Only when bh/mh is word-final or followed by the final vowel (no more consonants after).
      elseif tokens[i] and tokens[i].ortho == "l" and tokens[i + 1] and
             (tokens[i + 1].ortho == "bh" or tokens[i + 1].ortho == "mh") then
        local prev_vowel = S.find_preceding_vowel(tokens, i)
        -- Check that bh/mh is word-final or followed only by a final vowel
        local bh_idx = i + 1
        local after_bh = tokens[bh_idx + 1]
        local is_final = after_bh == nil or after_bh.type == "boundary"
        local is_final_vowel = after_bh and after_bh.type == "vowel" and
          S.is_short_vowel(after_bh) and
          (tokens[bh_idx + 2] == nil or tokens[bh_idx + 2].type == "boundary")
        -- Condition: preceding vowel is short AND bh/mh is at word end or before final vowel
        if prev_vowel and S.is_short_vowel(prev_vowel) and (is_final or is_final_vowel) then
          -- Insert epenthetic schwa
          local epenthetic = S.clone_token(tokens[i])
          epenthetic.type = "vowel"
          epenthetic.phon = "ə"
          epenthetic.is_epenthetic = true
          epenthetic.stress = false
          epenthetic.source = "epenthesis"
          if tokens[i].palatal == true then
            epenthetic.ortho = "i"
          else
            epenthetic.ortho = "a"
          end
          table.insert(new_tokens, epenthetic)
          -- Change bh/mh from w to vˠ (broad) or vʲ (slender)
          if tokens[i + 1].palatal == true then
            tokens[i + 1].phon = "vʲ"
          else
            tokens[i + 1].phon = "vˠ"
          end
          -- Same stress repair as above: svarabhakti disyllabified the root.
          if not prev_vowel.stress and context.is_monosyllabic and
             not context.no_lexical_stress and context.word_ortho and
             not context.word_ortho:find(" ") then
            prev_vowel.stress = true
          end
        end
      end

      ::skip_epenthesis::
      i = i + 1
    end
    return new_tokens
  end,
}
