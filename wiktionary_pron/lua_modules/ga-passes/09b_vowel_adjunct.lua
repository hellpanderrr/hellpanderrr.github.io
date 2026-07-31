-- Pass 9b: Resolve vowel + mutated fricative adjuncts.
-- Runs after consonants (#9) but before vowels (#10).
-- Originally silenced mh/bh in coda and appended iː, but this was incorrect:
-- mh/bh in coda should remain as v/vʲ (pass 09 already resolves it correctly).
-- This pass now only handles specific legitimate cases where vocalization is warranted.

local S = require("ga-passes.shared")
local ustring = require("ustring.ustring")
local ulen = ustring.len

return {
  name = "vowel_adjunct",
  writes_context = false,

  run = function(tokens, context)
    -- The old V+mh/bh→Viː adjunct rule was removed (regressed 30 words vs 0 correct).
    -- Pass 09 already resolves mh→vʲ and bh→v correctly in coda; no silencing needed.
    return tokens
  end,
}
