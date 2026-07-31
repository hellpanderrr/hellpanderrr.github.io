-- Pass #3: Handle eclipsis clusters and t-prefix mutation.
-- Word-initial eclipsis: mb→m, gc→g, dt→d, bp→b, nd→n, nn→n, ng→ŋ, bhf→w
-- Silences the eclipsed consonant. Survivor keeps its ortho and resolves normally in pass 09.
-- Also handles T-prefix (Hickey III.2.2.2): ts at word start → s silent,
-- and tch at word start → ch silent.
-- Now scans EVERY word start (position 1 or after a boundary token),
-- so multi-word eclipsis (i bhfad, i dtosach) works.
-- References: Hickey III.2.3.1 (nasalisation / eclipsis), Hickey III.2.2.2 (T-prefix), FG Ch.7 (mutation mapping)

local S = require("ga-passes.shared")

local ECLIPSIS_PAIRS = { mb = true, gc = true, dt = true, bp = true, nd = true, nn = true, bhf = true }

return {
  name = "eclipsis",
  writes_context = false,

  run = function(tokens, context)
    -- Scan for word-start positions (index 1 = start of string, or after boundary)
    local i = 1
    while i <= #tokens do
      -- If not at position 1, skip to next word start (past the boundary token)
      if i > 1 then
        if tokens[i].type ~= "boundary" then i = i + 1; goto continue end
        i = i + 1  -- skip the boundary token
      end

      local t1 = tokens[i]
      local t2 = tokens[i + 1]
      if not t1 or not t2 then i = i + 1; goto continue end

      if t1.type == "cons" and t2.type == "cons" then
        local pair = t1.ortho .. t2.ortho

        if pair == "bhf" then
          -- bh + f → w (bh resolves to w in pass 09, f is silenced)
          -- Hickey III.2.3.1: bhf eclipsis → [w] (labial glide from nasalisation)
          t2.phon = ""
          t2.source = "eclipsis_silenced"
          i = i + 2
          goto continue
        end

        if ECLIPSIS_PAIRS[pair] then
          -- Silence the eclipsed consonant(s), survivor resolves normally in pass 09
          t2.phon = ""
          t2.source = "eclipsis_silenced"
          i = i + 2
          goto continue
        end

        -- T-prefix (Hickey III.2.2.2): ts at word start → s is silent, only t pronounced
        -- The t inherits polarity from the following vowel. This is distinct from eclipsis
        -- but follows the same silencing pattern.
        if pair == "ts" then
          t2.phon = ""
          t2.source = "eclipsis_silenced"
          i = i + 2
          goto continue
        end

        -- tch at word start: ch is silent, only t pronounced
        -- Connacht variant of chí (feiceann), e.g. tchí → tʲiː
        if pair == "tch" then
          t2.phon = ""
          t2.source = "eclipsis_silenced"
          i = i + 2
          goto continue
        end
      end

      -- Single-token ng at word start: eclipsis of g → ŋ/ɲ depending on following vowel
      -- Hickey III.2.3.1: velar nasal /ŋ/ from nasalised g
      if t1.type == "cons" and t1.ortho == "ng" then
        -- Scan forward to find the next vowel to determine polarity
        local next_vowel = nil
        for j = i + 1, #tokens do
          if tokens[j].type == "vowel" then next_vowel = tokens[j]; break end
        end
        local polarity = next_vowel and S.vowel_polarity(next_vowel) or false
        S.set_polarity(t1, polarity)
        i = i + 1
        goto continue
      end

      i = i + 1
      ::continue::
    end

    return tokens
  end,
}
