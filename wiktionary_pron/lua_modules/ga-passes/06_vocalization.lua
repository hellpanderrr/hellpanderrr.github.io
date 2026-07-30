-- Pass #6: Vocalize vowel+fricative sequences.
-- Stress-aware: -adh stressed -> [ai/eː], unstressed -> [ə].
-- ea+bh -> [əu], u+gh -> [uː], a/o/u+bh/mh -> [əu].
-- NOTE: Does NOT silence the fricative — that's handled by pass #9b (vowel_adjunct)
-- after consonants have been resolved by pass #9.
-- References: Hickey II.1.9.9.1 (vocalisation of fricatives), II.1.9.4 (vowel gradation)

local S = require("ga-passes._shared")

return {
  name = "vocalization",
  writes_context = false,

  run = function(tokens, context)
    for i = 1, #tokens - 1 do
      local vowel = tokens[i]
      local fricative = tokens[i + 1]
      if vowel.type ~= "vowel" or not S.is_vocalizable_fricative(fricative) then
        goto continue
      end

      -- Skip vocalization when 'i' is a palatal marker (preceded by another vowel).
      -- dibh → oː + vʲ (not vocalize i+bh to əi).
      -- The 'i' between a vowel and bh/mh is marking palatalization, not forming
      -- a diphthong with the following fricative.
      -- Hickey II.1.9: i as palatal marker between two Vs, not syllabic
      if vowel.ortho == "i" then
        local prev_t = tokens[i - 1]
        if prev_t and prev_t.type == "vowel" then
          goto continue
        end
      end

      local is_slender = vowel.ortho == "e" or vowel.ortho == "i" or vowel.ortho == "ea"
      local was_vocalized = false

      -- Munster: unstressed V+bh/mh keeps consonantal [vˠ] — no vocalization
      -- (talamh [t̪ˠɑləvˠ], breitheamh [ˈbʲɾʲɪhəvˠ], amháin [əˈvˠɑːnʲ]).
      -- Hickey II.1.7.2: the South retains labiodental friction; vocalization
      -- of unstressed -amh/-eamh is a Connacht/Ulster development.
      if context.dialect == "munster" and not vowel.stress and
         (fricative.ortho == "bh" or fricative.ortho == "mh") then
        goto continue
      end

      -- Hickey II.1.9.9.1: V+bh/mh → /əu əi/ — historical /v/ absorbed into vowel
      --   (leabhar→[lʲauɾˠ], samhradh→[sˠauɾˠə])
      if vowel.ortho == "ea" and (fricative.ortho == "bh" or fricative.ortho == "mh") then
        vowel.phon = "\xc9\x99u"; was_vocalized = true
      elseif fricative.ortho == "bh" or fricative.ortho == "mh" then
        if is_slender then
          vowel.phon = "\xc9\x99i"; was_vocalized = true
        elseif vowel.ortho == "a" or vowel.ortho == "o" or vowel.ortho == "u" then
          vowel.phon = "\xc9\x99u"; was_vocalized = true
          -- Connacht: o+mh → oː in comh- prefix. Hickey II.1.9: comh- reduces
          -- to /koː/ before consonants in Connacht (vs. /kəu/ elsewhere).
          if vowel.ortho == "o" and context.word_ortho then
            local word_lower = context.word_ortho:lower()
            if word_lower:sub(1, 4) == "comh" then
              vowel.phon = "oː"
            end
          end
        end
      -- Hickey II.1.9.9.1: V+dh/gh → /ai/ stressed, /ə/ unstressed
      --   (aghaidh→[əi], radharc→[ɾˠaɾˠk])
      elseif fricative.ortho == "dh" or fricative.ortho == "gh" then
        if vowel.stress then
          if is_slender then
            vowel.phon = "\xc9\x99i"; was_vocalized = true
          elseif vowel.ortho == "a" or vowel.ortho == "o" or vowel.ortho == "u" then
            vowel.phon = "ai"; was_vocalized = true
          end
        else
          vowel.phon = "\xc9\x99"; was_vocalized = true
        end
      end

      if was_vocalized then
        fricative.phon = ""
      end

      -- Skip vocalization when a is part of a rising diphthong (ia, ua).
      -- In riamh, Niamh, ciabh, etc., ia+labial fricative = iəw/iəvˠ,
      -- not vocalization (the fricative resolves to w/vˠ in pass 09).
      -- Hickey II.1.9.7: rising diphthongs ia, ua.
      if was_vocalized and vowel.ortho == "a" and
         (fricative.ortho == "bh" or fricative.ortho == "mh") then
        local prev_t = tokens[i - 1]
        if prev_t and prev_t.type == "vowel" and
           (prev_t.ortho == "i" or prev_t.ortho == "u") then
          vowel.phon = "a"
          fricative.phon = fricative.ortho
          was_vocalized = false
        end
      end

      -- Lexical overrides: a+bh/mh → au (not əu) for specific words.
      -- Also covers ea+bh/mh → au. Hickey II.1.9.9.1: vocalization
      -- quality varies lexically — əu is the general default, but many
      -- common words have historical au.
      if was_vocalized and (fricative.ortho == "bh" or fricative.ortho == "mh") and context.word_ortho then
        local VOCALIZE_AU = {
          abhac=true, cabhail=true, dabhach=true, labhairt=true,
          ramhar=true, rabhais=true, rabhadar=true, rabhamar=true,
          amha=true, fabhtach=true, clabhta=true,
          damhsaigh=true, cabhsa=true,
          tabharthach=true,
          feabhas=true, fheabhas=true, sheabhac=true, seabhac=true,
          seabhaic=true, meabhair=true, mheabhair=true,
          leamhnacht=true, Feabhra=true,
          ["gabhaid\xC3\xADs"]=true, ghabhas=true, ngabhas=true,
        }
        if VOCALIZE_AU[context.word_ortho:lower()] then
          vowel.phon = "au"
        end
      end

      ::continue::
    end

    return tokens
  end,
}
