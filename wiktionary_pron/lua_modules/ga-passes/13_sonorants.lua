-- Pass #13: Sonorant diacritics and geminates.
-- 1. Adjust l/n diacritics to 4-way system based on following context:
--    Broad + before_cons → insert dental ̪ (l̪ˠ, n̪ˠ)
--    Broad + before_vowel/end → keep ˠ (lˠ, n̪ˠ — n already has ̪ from consonant pass)
--    Slender + before_cons → insert postalveolar ̠ (l̠ʲ, n̠ʲ)
--    Slender + before_vowel/end → keep ʲ (lʲ, nʲ)
-- 2. Handle geminate sonorants (ll, nn, rr, mm): silence second, adjust first.
-- 3. Vowel lengthening before geminate sonorants in monosyllables.
-- Runs after vowel resolution (#12) so vowel phonemes are final.
-- References: Hickey II.1.8 (sonorant system — 3-way l/n, geminates, §1.8.4 three-way
--  distinctions, §1.8.6 historical development), FG Ch.5 (Connacht sonorant inventory)

local S = require("ga-passes.shared")
local ustring = require("ustring.ustring")
local usub = ustring.sub

-- UTF-8 safe check: is the first IPA character a front vowel?
local function is_front_vowel_phon(phon)
  if not phon then return false end
  local c1 = usub(phon, 1, 1)
  return c1 == "i" or c1 == "e" or c1 == "ɪ" or c1 == "ɛ"
end

-- Insert a combining diacritic into a phoneme string after the base character.
-- phon: base phoneme string (e.g. "l", "n")
-- combining: UTF-8 combining character (U+032A dental, U+0320 postalveolar)
-- Returns: base + combining + any existing length/width diacritics already on phon
local function insert_combining(phon, combining)
  if not phon or #phon == 0 then return phon end
  -- Find the base character (first byte, which is ASCII for l/n/m/r)
  local base = phon:sub(1, 1)
  local rest = phon:sub(2)
  return base .. combining .. rest
end

local DENTAL = string.char(0xCC, 0xAA)    -- U+032A combining bridge below
local POSTALVEOLAR = string.char(0xCC, 0xA0)  -- U+0320 combining minus below

-- Check if a phoneme already contains the dental diacritic
local function has_dental(phon)
  if not phon then return false end
  return phon:find(DENTAL, 1, true) ~= nil
end

-- Check if a phoneme already contains the postalveolar diacritic
local function has_postalveolar(phon)
  if not phon then return false end
  return phon:find(POSTALVEOLAR, 1, true) ~= nil
end

-- Word-initial slender l/n get the postalveolar (retracted) diacritic l̠ʲ/n̠ʲ
-- (Hickey II.1.8: "tensor" slender sonorants in initial position).
-- However, grammatical/function words (prepositional pronouns, particles,
-- negatives) retain the lax/non-retracted lʲ/nʲ. Also excluded are loanwords
-- where the slender l/n is not part of the native tensor system.
local GRAMMATICAL_SLENDER = {
  -- Prepositional pronouns: Hickey II.3 — clitic/grammatical, no retracted sonorant
  leat=true, leatsa=true, leis=true, linn=true, liom=true, libh=true,
  leofa=true, leosan=true,
  -- Negative particle + its inflected forms
  -- Negative verb forms (ní + bhíom etc.): initial n is the particle, not stem
  ["nílid"]=true, ["nílim"]=true, ["nílir"]=true, ["níochán"]=true,
  -- Surname particle (Ní = daughter of): capitalised, not retracted
  ["Ní"]=true,
  -- Name/defective particles
  Nic=true, nis=true, ["nár"]=true,
  -- Verbal adjective prefix n-
  nite=true,
  -- Loanwords: English borrowings don't participate in the native tensor
  -- sonorant system (Hickey II.1.8: loanword nativisation is variable).
  leictreoir=true, litreach=true, litreacha=true, ["líomóid"]=true,
  -- Derived/compound forms where the initial slender l comes from a stem
  -- that does not have tensor quality.
  ["léarscáil"]=true, ["líonra"]=true,
  -- Verb forms where initial l is from a stem that is not historically tensor
  ligim=true, ["liúr"]=true,
}

-- Lexical exemptions: words where slender l/n should NOT receive the
-- postalveolar diacritic before a consonant (loanwords, verbal adjectives,
-- and other non-native formations). These words participate in the slender
-- system (lʲ/nʲ) but lack the tensor/postalveolar quality of native Irish
-- slender sonorants. Hickey II.1.8: loanword nativisation is variable.
-- Exemption applies to l̠ʲ→lʲ and n̠ʲ→nʲ before any following consonant.
local NON_TENSOR_SLENDER = {
  -- Verbal nouns/adjectives in -(a)ilt(e), -(a)int, -(a)inte
  cigilt=true, goilte=true, ceilte=true, oiltear=true, scaoilte=true,
  buailteacha=true, deighilt=true, seimint=true, innilt=true,
  -- Loanwords: English borrowings with slender l/n
  bairille=true, baraille=true, bille=true, billi=true,
  ceilp=true, ceilpe=true, cailc=true, cailce=true, stailc=true, spailpin=true,
  cillin=true, einne=true, rinnis=true, india=true, insim=true, lia=true,
  chailleas=true, muinteora=true,
  -- Abstract nouns in -int / -óint / extended -te verbal adjective
  argoint=true, peint=true, failte=true, mointeach=true,
  -- Additional verbal adjective forms (-te/-the suffix with slender n/l)
  deintear=true, puint=true, ginte=true, nuaghinte=true, oscailte=true, gabhailte=true, innealtoir=true,
  -- Loanwords and verbal suffix -t(-e) forms: n+t is non-tensor.
  -- (Listed once; a duplicate copy of this line was removed 2026-07-30.)
  caintim=true, guiochtaint=true, peinteailte=true,
  -- Loanwords and compounds: slender l/n is non-tensor
  pillin=true, milsean=true, milse=true, leorai=true, liopa=true, liopard=true,
  truaill=true, duille=true, gaedhilge=true,
}

return {
  name = "sonorants",
  writes_context = false,

  run = function(tokens, context)
    -- Phase 1: Adjust non-geminate sonorant diacritics.
    -- For l and n: insert dental/postalveolar combining mark based on context.
    -- Skip consecutive identical sonorants (handled in Phase 2).
    -- Hickey II.1.8: 3-way l/n contrast — palatal [lʲ nʲ], neutral [l n],
    --   velarized [lˠ nˠ]; dental [l̪ˠ n̪ˠ] before consonants in Connacht
    for i = 1, #tokens do
      local token = tokens[i]
      if token.type ~= "cons" then goto next_son end
      if token.phon == "" then goto next_son end
      if token.ortho ~= "l" and token.ortho ~= "n" then goto next_son end

      -- Skip already-velarized n (assimilated to ŋ/ɲ before velar stops)
      if token.ortho == "n" and token.phon:sub(1,2) == "ŋ" then goto next_son end
      if token.ortho == "n" and token.phon:sub(1,2) == "ɲ" then goto next_son end

      -- Skip if next token is same ortho (geminate pair — handled in Phase 2)
      local next_t = tokens[i + 1]
      if next_t and next_t.type == "cons" and next_t.ortho == token.ortho then
        goto next_son
      end

      -- Determine broad or slender from token palatal flag (pass 01)
      local is_broad = not token.palatal
      if token.broad ~= nil then is_broad = token.broad end
      -- Check what follows
      local followed_by_cons = next_t and next_t.type == "cons" and
        next_t.phon and next_t.phon ~= "" and
        next_t.type ~= "boundary"

      -- Check for word-initial position
      local word_initial = (i == 1) or (tokens[i-1] and tokens[i-1].type == "boundary")

      -- Check for s+onset cluster: preceded immediately by s (or its lenited form sh),
      -- e.g. sl- clusters and medial -sl- sequences.
      -- In Connacht Irish, /l/ is dental after /s/ but not after other consonants
      -- in onset clusters (cl-, gl-, pl-, etc. take lenis lˠ).
      -- Hickey II.1.8: strong (fortis) vs weak (lenis) sonorants — quality varies
      --   by preceding consonant; s+sonorant patterns differently from stop+sonorant.
      local preceded_by_s = false
      if not word_initial then
        local pt = tokens[i - 1]
        if pt and pt.type == "cons" and pt.phon and pt.phon ~= "" then
          if pt.ortho == "s" or pt.ortho == "sh" then
            preceded_by_s = true
          end
        end
      end

      if is_broad then
        if not has_dental(token.phon) then
          if followed_by_cons then
            -- Hickey II.1.8: broad l before consonant is denti-alveolar l̪ˠ
            -- in native Irish words (fortis position). Exceptions are mostly
            -- loanwords and morpheme-boundary l+r clusters.
            local word_lookup = S.strip_fadas(S.normalize_ortho(context.word_ortho or ""))
            local L_CONS_NON_DENTAL = {
              -- Loanwords where broad l before consonant keeps lenis lˠ
              -- Keys must be strip_fadas (no bare fadas in Lua table brackets)
              alpan=true, balsamach=true,
              bolcanach=true, bolcan=true, bolcain=true,
              dulra=true,
              holc=true, innealtoir=true,
              iolran=true,
              olca=true, scealp=true,
              -- l+f verb suffix (future/conditional -f-): morpheme boundary
              molfar=true,
            }
            if not L_CONS_NON_DENTAL[word_lookup] then
              token.phon = insert_combining(token.phon, DENTAL)
            end
          elseif word_initial or preceded_by_s then
            -- Hickey II.1.8: initial broad l/n and s+onset clusters are
            -- denti-alveolar l̪ˠ/n̪ˠ in Connacht. This includes sl- word-initially
            -- (slán, slua, slám) and medial -sl- (prioslaire).
            -- Note: cl-, gl-, pl-, bl- clusters take lenis lˠ, not dental.
            token.phon = insert_combining(token.phon, DENTAL)
          elseif token.from_dl then
            -- Historical dl->l reduction: l retains dental articulation even
            -- before a vowel (codlata -> kOl̪ˠət̪ˠə). Set in pass 04.
            token.phon = insert_combining(token.phon, DENTAL)
          elseif token.ortho == "l" then
            -- Broad l preceded by r: retains fortis dental articulation.
            -- Hickey II.1.8: broad l in medial r+l clusters (iarla, Bearla,
            -- Ceatharlach, tarlu, etc.) keeps denti-alveolar quality before
            -- vowels. Excludes mutation forms (Bhearla, mBearla) where
            -- lenition or eclipsis causes lenis articulation.
            local prev_t = tokens[i - 1]
            if prev_t and prev_t.ortho == "r" and prev_t.type == "cons" and prev_t.phon and prev_t.phon ~= "" then
              -- Check if word starts with a mutation marker for the base word.
              -- If so, the l is lenis and should not receive dental.
              local word = context.word_ortho or ""
              if not (word:match("^[Bb]h") or word:match("^m[Bb]")) then
                token.phon = insert_combining(token.phon, DENTAL)
              end
            else
              -- Lexical table: specific native Irish words where medial broad l
              -- before a vowel (or after epenthesis) is denti-alveolar l̪ˠ.
              -- Hickey II.1.8: fortis broad l surfaces as l̪ˠ in Connacht in
              -- specific native words, including after consonants (cl-, gl-)
              -- and between vowels. Most non-native words and transparent
              -- compounds retain lenis lˠ.
              local word_ortho = S.normalize_ortho(context.word_ortho or "")
              local lookup = S.strip_fadas(word_ortho)
              local L_VOWEL_DENTAL = {
                -- cl- before vowel: fortis l after stop
                -- Keys use strip_fadas (no bare fadas in Lua table brackets)
                clocha=true, clos=true, cluin=true, cluiteach=true,
                -- gl- before vowel
                gluaisim=true, glor=true,
                -- Intervocalic V+l+V: fortis l between vowels
                mala=true, gala=true,
                hola=true, tola=true, salu=true,
                solas=true,
                eolach=true, eolas=true, feola=true,
                seolaim=true, olaimid=true,
                ualach=true, shalach=true, sealga=true,
                folmha=true, gaelach=true, ghaelach=true,
                colur=true,
                alastar=true, polainnis=true,
                -- n+l cluster before vowel
                danlann=true, munla=true,
                fionlainnis=true,
                bhfionlainnis=true, fhionlainnis=true,
                -- coda l in compounds after consonant
                speacla=true, biobla=true,
                tslainte=true,
              }
              if L_VOWEL_DENTAL[lookup] then
                token.phon = insert_combining(token.phon, DENTAL)
              end
            end
          end
        elseif next_t and not followed_by_cons and not token.from_dl and token.ortho == "n" then
          -- Intervocalic n (followed by a vowel, not word-final): lenis nˠ
          -- Word-final n handled by Phase 1b with more nuanced rules.
          -- Hickey II.1.8: intervocalic broad n weakens to lenis [nˠ].
          -- Lexical exceptions: specific native words retain fortis n̪ˠ
          -- medially after a long vowel (déanaí, gcónaí, séanas, meánach...).
          -- A blanket long-vowel rule regressed 58 words (cána, Úna, rúnaí);
          -- the benchmark is split ~30/58, so per-word listing is required.
          local N_MEDIAL_DENTAL = {
            -- Keys strip_fadas'd (no bare fadas in Lua table brackets)
            deanai=true, gconai=true, conai=true, carbonach=true,
            seanas=true, dunaim=true, meanach=true, lunasa=true,
            maithiunas=true, bleanach=true, deanach=true, munaid=true,
            fana=true, deaganach=true, protastunach=true, eanair=true,
            cisteanach=true, deireanach=true, dhona=true, dona=true,
            meana=true, bliana=true, leanaim=true, seana=true,
          }
          local prev_t = tokens[i - 1]
          if prev_t and prev_t.type == "vowel" then
            local lookup = S.strip_fadas(S.normalize_ortho(context.word_ortho or ""))
            if not N_MEDIAL_DENTAL[lookup] then
              token.phon = S.palatal_consonant(token, "nʲ", "nˠ")
            end
          end
        end
      else
        if not has_postalveolar(token.phon) then
          if followed_by_cons then
            -- Hickey II.1.8: slender l/n before consonant → postalveolar l̠ʲ/n̠ʲ
            -- Exclude non-tensor sonorants (loanwords, verbal adjectives, etc.)
            local word_ortho = S.normalize_ortho(context.word_ortho or "")
            local is_exempt = NON_TENSOR_SLENDER[S.strip_fadas(word_ortho)]
            if not is_exempt then
              token.phon = insert_combining(token.phon, POSTALVEOLAR)
            end
          elseif word_initial or (preceded_by_s and token.ortho == "l") then
            -- Hickey II.1.8: initial slender l/n are tensor/alveolar l̠ʲ/n̠ʲ.
            -- Same for slender l after s/sh (ʃ): ʃl- onsets (sleán, Sligeach)
            -- and medial -ʃl- (ísle, dísle, uaisle) keep the tense postalveolar
            -- articulation — mirror of the broad s+l dental rule above.
            -- Skip grammatical words (prepositional pronouns, particles, etc.)
            -- also non-tensor sonorants (loanwords, etc.)
            local raw_word = context.word_ortho or ""
            local word_ortho = S.normalize_ortho(raw_word)
            if not GRAMMATICAL_SLENDER[raw_word] and not NON_TENSOR_SLENDER[S.strip_fadas(word_ortho)] then
              token.phon = insert_combining(token.phon, POSTALVEOLAR)
            end
          elseif token.ortho == "n" then
            -- Lexical table: slender n before a vowel in specific native Irish
            -- words gets postalveolar ǹov (tensor quality). Hickey II.1.8:
            -- medial slender n in native words surfaces as ǹov before vowels
            -- in Connacht (r+n, sh+n sequences, and word-initial n+e/i).
            local raw_word = context.word_ortho or ""
            local word_ortho = S.normalize_ortho(raw_word)
            local lookup = S.strip_fadas(word_ortho)
            local N_VOWEL_POSTALVEOLAR = {
              -- r+n sequences before vowel (historical -rn- clusters -> n retains tensor)
              airne=true, airnean=true, airneis=true, bairneach=true,
              cairn=true, ceirnin=true, muirnin=true, oirnis=true,
              tairne=true, toirneach=true, toirneis=true, tuirne=true,
              -- sh+n sequences before vowel (misneach, cuisneach)
              misneach=true, cuisneach=true, frisneiseach=true,
              tarcaisne=true, slisne=true,
              -- word-initial n+e/i (sní, snite, inis)
              sni=true, snite=true,
              inis=true,
              -- word-initial n+í (negative particle)
              ni=true, nios=true,
              -- native r+n where n is tense
              uigneacha=true,
            }
            if N_VOWEL_POSTALVEOLAR[lookup] then
              token.phon = insert_combining(token.phon, POSTALVEOLAR)
            end
          end
        end
      end

      ::next_son::
    end

    -- Phase 1b: Strip dental from word-final broad n when preceding vowel is
    -- LONG and UNSTRESSED. Distribution: ~125 words want nˠ vs ~93 want n̪ˠ
    -- in this context (net +41 exact). Word-final = no following non-boundary
    -- token with non-empty phon.
    -- Hickey II.1.8: final broad n → [nˠ] after unstressed long vowels in Connacht
    for i = 1, #tokens do
      local token = tokens[i]
      if token.type ~= "cons" then goto next_strip end
      if token.ortho ~= "n" then goto next_strip end
      if not token.phon or token.phon == "" then goto next_strip end
      if not has_dental(token.phon) then goto next_strip end

      local is_final = true
      for j = i + 1, #tokens do
        local t = tokens[j]
        if t.type == "boundary" then break end
        if (t.type == "cons" or t.type == "vowel") and t.phon and t.phon ~= "" then
          is_final = false; break
        end
      end
      if not is_final then goto next_strip end

      local prev_v
      for j = i - 1, 1, -1 do
        if tokens[j].type == "vowel" then prev_v = tokens[j]; break end
        if tokens[j].type == "boundary" then break end
        if tokens[j].type == "cons" and tokens[j].phon and tokens[j].phon ~= "" then break end
      end
      if not prev_v then goto next_strip end

      local pv_phon = prev_v.phon or ""
      local is_long = pv_phon:find("ː", 1, true) ~= nil
      local is_stressed = prev_v.stress or false

      -- Skip words where word-final broad n keeps dental diacritic.
      -- Hickey II.1.8: word-final broad n is dental n̪ˠ in Connacht after
      -- long stressed vowels (-an/-un/-on suffix words) and in specific
      -- monosyllables (bun, Brian, buan, cuan, srian). After unstressed
      -- long vowels the dental is lenited to nˠ (rion, buion, crion).
      -- Use quoted string keys for fada-bearing words (bare keys must be ASCII).
      local word_ortho = context.word_ortho or ""
      local KEEP_N_DENTAL = {
        -- Monosyllables: short/diphthong vowel + dental n (Hickey II.1.8)
        aon=true, Brian=true, buan=true, bun=true, chan=true, cuan=true,
        feochan=true, ghrian=true, srian=true,
        -- Stressed -an/-un/-on suffix words
        ["altán"]=true, ["bán"]=true, ["bodhrán"]=true, ["corcán"]=true,
        ["dán"]=true, ["deamhan"]=true, ["duibheagán"]=true,
        ["Eoghan"]=true,
        ["fán"]=true, ["gaothrán"]=true, ["gearrán"]=true, ["geimhriúchán"]=true,
        ["gluaisteán"]=true, ["glún"]=true, ["ghlún"]=true, ["guthán"]=true,
        ["harán"]=true, ["Idirlíon"]=true,
        ["lán"]=true, ["meán"]=true, ["milseán"]=true,
        ["príosún"]=true, ["réidhleán"]=true,
        ["sacán"]=true, ["Seán"]=true, ["Siobhán"]=true, ["smiolgadán"]=true,
        ["stáisiún"]=true, ["súsán"]=true,
      }
      if KEEP_N_DENTAL[word_ortho] then goto next_strip end

      -- Multi-word phrases where word-final broad n should lose dental
      -- even with a long vowel (usually due to phrase-level stress shift).
      local FORCE_STRIP_N = {
        ["a lán"]=true,
      }
      if FORCE_STRIP_N[word_ortho] then
        token.phon = "nˠ"
        goto next_strip
      end

      if not is_long or (is_long and not is_stressed) then
        -- Strip dental from word-final broad n preceded by:
        -- 1. Short vowel (any stress) — n̪ˠ→nˠ, OR
        -- 2. Long unstressed vowel — n̪ˠ→nˠ.
        -- Keep dental only for long stressed vowels. Hickey II.1.8: coda n weakens
        token.phon = "nˠ"
      end

      ::next_strip::
    end

    -- Phase 1c: Word-final broad l gets dental in specific native Irish words
    -- (focal, ceol, col, etc.). Excludes ao-vowel words (gaol, maol), loanwords
    -- (sceal, Pol), and lenited/eclipsed forms.
    -- Hickey II.1.8: word-final broad l can be fortis [l̪ˠ] or lenis [lˠ]
    -- depending on word etymology and morphological context.
    local FINAL_L_DENTAL = {
      ceol=true, col=true, gol=true, mol=true, ol=true, sal=true, cal=true, al=true,
      focal=true, pobal=true, seagal=true, cantal=true, taisteal=true,
      sciobol=true, parasol=true, bleidhmhiol=true,
      ainmfhocal=true, fhocal=true,
      seipeal=true, cruinneal=true, imanal=true,
    }
    for i = 1, #tokens do
      local token = tokens[i]
      if token.type ~= "cons" then goto next_fl end
      if token.ortho ~= "l" then goto next_fl end
      if not token.phon or token.phon == "" then goto next_fl end
      if has_dental(token.phon) then goto next_fl end
      if token.palatal == true then goto next_fl end

      -- Check if word-final (no following non-boundary content)
      local is_final = true
      for j = i + 1, #tokens do
        local t = tokens[j]
        if t.type == "boundary" then break end
        if (t.type == "cons" or t.type == "vowel") and t.phon and t.phon ~= "" then
          is_final = false; break
        end
      end
      if not is_final then goto next_fl end

      -- Check lexical table (strip fadas for lookup).
      -- Exclude fada-conflated words: words that reduce to the same
      -- stripped key but differ in IPA (e.g. mol vs mól).
      local word = S.strip_fadas(S.normalize_ortho(context.word_ortho or ""))
      if FINAL_L_DENTAL[word] then
        -- mól (heap/animal) conflates with mol (praise) after strip_fadas
        local EXCLUDE = context.word_ortho == "m\xC3\xB3l"  -- mól with fada
        if not EXCLUDE then
          token.phon = insert_combining(token.phon, DENTAL)
        end
      end

      ::next_fl::
    end

    -- Phase 2: Handle consecutive identical sonorants (geminate ll, nn, rr, mm).
    -- Hickey II.1.8.6: historical geminate sonorants simplified in Middle Irish;
    --   preceding vowel lengthened in compensation (Connacht/Ulster)
    for i = 1, #tokens - 1 do
      local first = tokens[i]
      local second = tokens[i + 1]
      if first.type ~= "cons" or second.type ~= "cons" then goto next_pair end
      if first.ortho ~= second.ortho then goto next_pair end
      if first.ortho ~= "n" and first.ortho ~= "l" and
         first.ortho ~= "r" and first.ortho ~= "m" then goto next_pair end

      local prev_vowel = tokens[i - 1]
      local is_slender = first.palatal == true

      -- Lexical exceptions: words where geminate polarity doesn't follow
      -- the general pattern set by the polarity pass. These are typically
      -- morphologically derived (e.g. carraig + each).
      if first.ortho == "r" and context.word_ortho then
        local w = context.word_ortho:lower()
        -- carraigeach from carraig: preserved slender r from stem
        if w == "carraigeach" then is_slender = true end
      end

      -- Determine what follows the entire geminate pair
      local after_pair = tokens[i + 2]
      local before_cons = after_pair and after_pair.type == "cons" and
        after_pair.phon and after_pair.phon ~= ""

      if first.ortho == "n" then
        if is_slender then
          -- Geminate slender nn is ALWAYS postalveolar (n̠ʲ) in native Irish
          -- Exclude loanwords and non-tensor sonorants
          if context.word_ortho and NON_TENSOR_SLENDER[S.strip_fadas(S.normalize_ortho(context.word_ortho))] then
            first.phon = "nʲ"
          else
            first.phon = "n̠ʲ"
          end
        else
          -- Geminate broad n always dental
          first.phon = "n̪ˠ"
        end
      elseif first.ortho == "l" then
        if is_slender then
          -- Geminate slender ll is ALWAYS postalveolar (l̠ʲ) in native Irish
          -- Exclude loanwords and non-tensor sonorants
          if context.word_ortho and NON_TENSOR_SLENDER[S.strip_fadas(S.normalize_ortho(context.word_ortho))] then
            first.phon = "lʲ"
          else
            first.phon = "l̠ʲ"
          end
        else
          -- Geminate broad l is ALWAYS dental (l̪ˠ) in Connacht
          -- Hickey II.1.8: historical fortis /L/ → denti-alveolar [l̪ˠ]
          first.phon = "l̪ˠ"
        end
      elseif first.ortho == "r" then
        first.phon = is_slender and "ɾʲ" or "ɾˠ"
      elseif first.ortho == "m" then
        first.phon = is_slender and "mʲ" or "mˠ"
      end
      first.source = "strong_sonorant"
      second.phon = ""
      second.source = "strong_sonorant"

      -- Vowel lengthening before geminate sonorants only in monosyllables.
      -- Hickey II.1.8.6: historical geminate sonorants trigger compensatory
      --   lengthening of the preceding vowel in Connacht/Ulster.
      -- Lexical exceptions: words where the short vowel is preserved
      -- (function words, recent borrowings, or words with analogical
      -- short vowel). Hickey II.1.8.6: loanword nativisation is variable.
      local LENGTHEN_EXCEPTIONS = {
        mall=true, mhall=true, ngeall=true, gheall=true, breall=true,
        ["i ngeall ar"]=true, ["mar gheall ar go"]=true,
      }
      -- Ulster keeps the short vowel before historical geminates
      -- (Hickey II.1.8.6: am [amˠ], ceann [can̪ˠ], donn [d̪ˠʌn̪ˠ])
      -- Munster diphthongizes in POLYSYLLABLES too (gheallta [jaul̪ˠt̪ˠə],
      -- meallfaidh [mʲaul̪ˠhə]); Connacht/Ulster lengthening stays
      -- monosyllable-only. LENGTHEN_EXCEPTIONS encodes the Connacht short-
      -- vowel words (mall, gheall) — Munster diphthongizes those as well.
      -- Munster conditions: only the CLOSED-syllable geminate diphthongizes
      -- (word-final or pre-consonant). Intervocalic geminates keep the
      -- short vowel (mallaigh [mˠɑl̪ˠɪɟ], bearradh [bʲaɾˠə]); rr lengthens
      -- to [ɑː] instead of breaking (barr [bˠɑːɾˠ], gearr [ɟɑːɾˠ]).
      local mun_closed = context.dialect == "munster" and
        not (after_pair and after_pair.type == "vowel" and
             after_pair.phon and after_pair.phon ~= "")
      if (context.is_monosyllabic or (context.dialect == "munster" and mun_closed))
         and context.dialect ~= "ulster" then
        local pv = tokens[i - 1]
        if pv and pv.type == "vowel" then
          local ortho = pv.ortho
          -- Munster (Hickey II.1.8.6): compensation is DIPHTHONGIZATION, not
          -- plain lengthening: ceann [cɑun̪ˠ], poll [pˠəul̪ˠ], am [aumˠ].
          if context.dialect == "munster" then
            -- Only stressed vowels diphthongize in polysyllables
            -- (casann [ˈkɑsˠən̪ˠ] final nn after unstressed ə stays short).
            -- rr: long vowel, not diphthong (barr → bˠɑːɾˠ).
            if first.ortho == "r" then
              if (pv.stress or context.is_monosyllabic) and
                 (ortho == "a" or ortho == "ea") then
                pv.phon = "ɑː"
                pv.source = "sonorant_lengthening"
              end
              goto munster_geminate_done
            end
            if pv.stress or context.is_monosyllabic then
              if ortho == "ea" or ortho == "a" then
                pv.phon = "au"
                pv.source = "sonorant_lengthening"
              elseif ortho == "o" then
                pv.phon = "əu"
                pv.source = "sonorant_lengthening"
              elseif ortho == "u" then
                pv.phon = "uː"
                pv.source = "sonorant_lengthening"
              elseif ortho == "i" then
                -- Hickey II.1.9: ill → South [iːlʲ] (cill [ciːlʲ])
                pv.phon = "iː"
                pv.source = "sonorant_lengthening"
              end
            end
            goto munster_geminate_done
          end
          if ortho == "ea" or ortho == "a" then
            -- Skip lengthening for lexical exceptions
            local lookup = context.word_ortho or ""
            if not LENGTHEN_EXCEPTIONS[lookup] then
              -- Preserve existing quality (a or ɑ set by vowel pass), just add length
              local c1 = usub(pv.phon, 1, 1)
              if c1 == "ɑ" then
                pv.phon = "ɑː"
              else
                pv.phon = "aː"
              end
              pv.source = "sonorant_lengthening"
            end
          elseif ortho == "o" then
            pv.phon = "oː"
            pv.source = "sonorant_lengthening"
          elseif ortho == "u" then
            pv.phon = "uː"
            pv.source = "sonorant_lengthening"
          end
          ::munster_geminate_done::
        end
      end

      ::next_pair::
    end

    -- Phase 3: Vowel lengthening before heavy sonorant clusters (rd, rl, rn).
    -- Hickey II.1.8.4: Short vowels lengthen before historically heavy
    -- consonant clusters rd, rl, rn in Connacht and Ulster.
    -- Does NOT apply to reduced vowels (schwa, from pass 11) or
    -- compound words where r+d/r+l/r+n spans a morpheme boundary.
    local PHASE3_EXCEPTIONS = {
      -- morpheme-boundary r+d/r+l/r+n (compound / derived forms)
      ["Feardorcha"]=true, ["feardorcha"]=true,
      ["Toirdhealbhach"]=true, ["toirdhealbhach"]=true,
      ["liopard"]=true, ["Risteard"]=true,
      -- Sord has historical au diphthong, not lengthened o
      ["Sord"]=true, ["sord"]=true,
    }
    for i = 1, #tokens - 2 do
      local vowel = tokens[i]
      if vowel.type ~= "vowel" then goto next_len end
      if vowel.phon == "" then goto next_len end
      -- Skip already-long vowels
      if vowel.phon:find("ː", 1, true) then goto next_len end
      -- Skip reduced vowels (schwa) — these are already phonologically
      -- weakened (unstressed) and do not participate in sonorant lengthening
      if vowel.phon:sub(1,1) == "ə" then goto next_len end

      local r_token = tokens[i + 1]
      local c_token = tokens[i + 2]
      if not r_token or r_token.type ~= "cons" or r_token.ortho ~= "r" then
        goto next_len
      end
      if not c_token or c_token.type ~= "cons" then goto next_len end
      if c_token.ortho ~= "d" and c_token.ortho ~= "l" and c_token.ortho ~= "n" then
        goto next_len
      end

      -- Check lexical exceptions (compound words)
      local word = context.word_ortho or ""
      if PHASE3_EXCEPTIONS[word] then goto next_len end

      -- Lengthen vowel. For short vowels, use the long vowel quality
      -- rather than just appending ː. Hickey II.1.8.4: short vowels
      -- raise before heavy clusters in Connacht.
      -- o/oi before rd/rn → oː; before rl → preserve ɔ quality.
      -- u/ui → uː reliably regardless of cluster.
      local phon_c1 = usub(vowel.phon, 1, 1)
      if phon_c1 == "a" and not r_token.palatal then
        -- Lexical table: ea-derived words where the lengthened vowel
        -- should be front aː, not back ɑː.
        -- FG Ch.5: Connacht vowel quality before heavy clusters
        local EA_FRONT_A = {
          bearn=true, dearnadar=true, dearnamar=true, dearnas=true,
          dhearnadar=true, dhearnamar=true, dhearnas=true,
          dtearn=true, ndearnadar=true, ndearnamar=true, ndearnas=true,
          tearn=true, thearn=true,
        }
        if EA_FRONT_A[word] then
          vowel.phon = "aː"
        else
          vowel.phon = "ɑː"
        end
      elseif phon_c1 == "ɔ" and c_token.ortho ~= "l" then
        -- o/oi before rd/rn → oː; before rl keep ɔ quality (orla)
        vowel.phon = "oː"
      elseif phon_c1 == "ʊ" then
        vowel.phon = "uː"
      elseif phon_c1 == "a" then
        vowel.phon = "aː"
      else
        vowel.phon = vowel.phon .. "ː"
      end
      vowel.source = "sonorant_lengthening"

      ::next_len::
    end

    -- Munster ɪ-lengthening before heavy nasal/lateral clusters (Hickey
    -- II.1.9: high front vowels lengthen before tense sonorants in the South
    -- even outside monosyllables): suim [sˠiːmʲ], tinte [tʲiːnʲtʲə],
    -- inse [ˈiːnʲʃə], fillfidh.
    if context.dialect == "munster" then
      for i, t in ipairs(tokens) do
        if t.type == "vowel" and t.phon == "ɪ" then
          -- collect following consonant orthos up to next vowel/boundary
          local seq = {}
          local j = i + 1
          while tokens[j] and tokens[j].type == "cons" and #seq < 3 do
            table.insert(seq, tokens[j].ortho or "")
            j = j + 1
          end
          local after = tokens[j]  -- vowel, boundary, or nil
          local word_final = (after == nil) or (after.type == "boundary")
          if #seq == 1 and seq[1] == "m" and word_final then
            t.phon = "iː"
          elseif #seq >= 2 and seq[1] == "n" and (seq[2] == "t" or seq[2] == "s") then
            t.phon = "iː"
          elseif #seq >= 3 and seq[1] == "n" and seq[2] == "n" and seq[3] == "s" then
            t.phon = "iː"
          elseif #seq >= 3 and seq[1] == "l" and seq[2] == "l" then
            t.phon = "iː"
          end
        end
      end
    end

    -- (Munster sonorant notation normalization moved to pass 15
    -- dialect_finalize so pass-14-created sonorants are covered.)

    return tokens
  end,
}
