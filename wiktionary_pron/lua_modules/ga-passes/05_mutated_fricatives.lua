-- Pass #5: Handle lenited fricatives (bh, mh, ch, th, sh, fh).
-- fh is always silent but leaves a ghost-palatal trace on the preceding
-- consonant. bh/mh/dh/gh after vowels are resolved to approximants.
-- th/sh after vowels resolve to h (slender) or ç (broad).
-- References: Hickey II.1.7.2 (lenited fricatives — dependent phonemes),
--  Hickey III.2.3.2 (lenition — grammatical mutation), FG Ch.7 (mutation outcomes per dialect)

local S = require("ga-passes._shared")

return {
  name = "mutated_fricatives",
  writes_context = false,

  run = function(tokens, context)
    for i, token in ipairs(tokens) do
      if token.type ~= "cons" then goto continue end
      if not token.is_mutated then goto continue end

      local prev = tokens[i - 1]
      local next_t = tokens[i + 1]

      -- fh: always silent, ghost-palatal trace
      -- Hickey II.1.7.2: /f/ deleted under lenition — palatal trace survives
      --   (an-fhiach → [ənʲˈiəx], Hickey II.1.3)
      if token.ortho == "fh" then
        if prev and prev.type == "cons" then
          prev.palatal = token.palatal
        end
        token.phon = ""

      -- th: check polarity if followed by a vowel
      -- Hickey II.1.7.2: th→[h] from historical *t lenition
      elseif token.ortho == "th" then
        if i == #tokens then
          -- Handled by final_cleanup or remove_final_silent_mutated_fricatives
          -- But if preceded by vowel, may get ç appended there
          token.phon = ""
        else
          -- Medial th: phon set in consonants pass; here just leave it
          -- (will be resolved by pass #9)
        end

      -- sh: resolved in consonants pass (#9) - will get h

      -- bh/mh: resolve based on polarity and position
      -- Hickey II.1.7.2: bh/mh→[vˠ/vʲ] or [w] depending on position and dialect
      elseif token.ortho == "bh" or token.ortho == "mh" then
        -- Final-position polarity based on preceding vowel
        if i == #tokens and prev and prev.type == "vowel" and S.vowel_has_slender_trace(prev) then
          S.set_polarity(token, true)
        end
      end
      ::continue::
    end

    return tokens
  end,
}
