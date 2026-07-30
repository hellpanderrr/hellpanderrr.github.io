-- Pass #7: Vowel nasal raising.
-- Short o/u -> [ʊ] before geminate nasals (nn, ng).
-- Long ó/ú retain their quality; not raised to [uː].
-- Runs after vocalization so vocalized forms aren't re-nasalized.
-- References: Hickey II.1.9.4 (vowel gradation — nasal raising before geminate sonorants)

local S = require("ga-passes._shared")

return {
  name = "nasalization",
  writes_context = false,

  run = function(tokens, context)
    for i, token in ipairs(tokens) do
      if token.type ~= "vowel" then goto continue end

      local next = tokens[i + 1]
      local ortho = token.ortho

      -- Only raise if vowel hasn't been modified by earlier passes
      if token.phon ~= ortho and token.phon ~= nil and token.phon ~= "" then
        goto continue
      end

      local is_broad_nasal = next and next.type == "cons" and
          (next.ortho == "nn" or next.ortho == "ng") and
          (next.palatal == false or next.palatal == nil)

      local is_geminate_n = next and next.type == "cons" and next.ortho == "n" and
          tokens[i + 2] and tokens[i + 2].type == "cons" and tokens[i + 2].ortho == "n"

      if is_broad_nasal or is_geminate_n then
        -- Only SHORT o/u raise before geminate nasals (Hickey II.1.9.4: /o/→[ʊ] before
        -- nasals). Long ó/ú already carry length and keep it (dhónna->oːn,
        -- not ʊn). brúnn keeps uː.
        if ortho == "o" or ortho == "u" then
          -- Lexical exceptions: words where the expected quality keeps ɔ/o
          -- (bronnaim → ɔ, Connachtach/Connachta → o, etc.)
          local no_raise = false
          if context.word_ortho then
            local w = context.word_ortho:lower()
            if w == "bronnaim" or w == "connachtach" or w == "connachta" then
              no_raise = true
            end
          end
          if not no_raise then
            token.phon = "ʊ"
          end
        end
      end

      ::continue::
    end
    return tokens
  end,
}
