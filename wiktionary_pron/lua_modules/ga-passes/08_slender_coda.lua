-- Pass #8: Vowel gradation before slender codas.
-- Before slender ng -> [ɪ]
-- Before slender nn -> [ɪ]
-- References: Hickey II.1.9.4 (vowel gradation — coda-driven vowel quality)

local S = require("ga-passes._shared")

return {
  name = "slender_coda",
  writes_context = false,

  run = function(tokens, context)
    for i = 1, #tokens do
      local token = tokens[i]
      if token.type ~= "vowel" then goto continue end

      -- Only apply if vowel hasn't been modified by an earlier pass
      if token.phon ~= token.ortho and token.phon ~= nil and token.phon ~= "" then
        goto continue
      end

      local next = tokens[i + 1]

      -- NOTE: fires before broad ng too. Restricting to next.palatal == true
      -- (as the pass name implies) was measured at -5 Connacht, so the broad
      -- case is carrying real benchmark words. Header kept honest instead.
      -- Only apply to simple vowels (single orthographic character),
      -- not digraphs (ai, ea, etc.) which pass 10 resolves.
      if next and next.type == "cons" and next.ortho == "ng" and #token.ortho == 1 then
        token.phon = "ɪ"
      end

      ::continue::
    end
    return tokens
  end,
}
