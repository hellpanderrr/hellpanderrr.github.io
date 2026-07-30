-- New Irish G2P engine: token-array pipeline.
-- Replaces the monolith irish_engine.lua + irish_rules.lua.
-- Loads passes from passes/ directory and orchestrates them.

local S = require("ga-passes._shared")
local passes = require("ga-passes.init")
local ustring = require("ustring.ustring")
local ulen = ustring.len
local usub = ustring.sub
local umatch = ustring.match

-- Tokenizer: splits orthographic word into tokens
local function tokenize_word(word)
  local tokens = {}
  local i = 1
  word = S.normalize_ortho(word)

  while i <= ulen(word) do
    local c1 = usub(word, i, i)
    local c2 = i < ulen(word) and usub(word, i + 1, i + 1) or ""
    local c3 = i + 2 <= ulen(word) and usub(word, i + 2, i + 2) or ""
    local tri = c1 .. c2 .. c3
    local digraph = c1 .. c2

    if c1 == " " then
      table.insert(tokens, S.make_token(" ", "boundary", i, i))
      i = i + 1
    elseif tri == "d'fh" then
      local token = S.make_token(tri, "cons", i, i + 2)
      token.is_mutated = true
      token.mutation = "eclipsis"
      table.insert(tokens, token)
      i = i + 3
    elseif digraph == "bh" or digraph == "mh" or digraph == "ch" or
           digraph == "dh" or digraph == "gh" or digraph == "ph" or
           digraph == "sh" or digraph == "th" or digraph == "fh" then
      local token = S.make_token(digraph, "cons", i, i + 1)
      token.is_mutated = true
      token.mutation = "lenition"
      table.insert(tokens, token)
      i = i + 2
    elseif c1 == "'" then
      local token = S.make_token(c1, "boundary", i, i)
      token.source = "apostrophe"
      token.phon = ""  -- silence apostrophe in output
      table.insert(tokens, token)
      i = i + 1
    elseif tri == "aoi" or tri == "eoi" then
      table.insert(tokens, S.make_token(tri, "vowel", i, i + 2))
      i = i + 3
    elseif tri == "ngh" then
        -- n + gh (lenited g), NOT ng + h; avoids impossible /ŋh/ cluster
        local tn = S.make_token("n", "cons", i, i)
        table.insert(tokens, tn)
        local tgh = S.make_token("gh", "cons", i + 1, i + 2)
        tgh.is_mutated = true
        tgh.mutation = "lenition"
        table.insert(tokens, tgh)
        i = i + 3
    elseif digraph == "ng" then
      table.insert(tokens, S.make_token(digraph, "cons", i, i + 1))
      i = i + 2
    elseif S.VOWEL_DIGRAPHS[digraph] then
      table.insert(tokens, S.make_token(digraph, "vowel", i, i + 1))
      i = i + 2
    elseif S.is_vowel_char(c1) then
      table.insert(tokens, S.make_token(c1, "vowel", i, i))
      i = i + 1
    elseif S.is_consonant_char(c1) then
      table.insert(tokens, S.make_token(c1, "cons", i, i))
      i = i + 1
    else
      table.insert(tokens, S.make_token(c1, "unknown", i, i))
      i = i + 1
    end
  end

  return tokens
end

-- Render output: place stress mark before the syllable onset
-- IPA convention: ˈCV, not CˈV
local function render_output(tokens)
  -- Pre-process: move stress from vowel to preceding onset consonant(s).
  -- Handles both primary (`stress`) and secondary (`secondary`) stress.
  -- The onset walk skips tokens with empty phon that are NOT boundaries
  -- (e.g. silenced final fricatives) but stops at boundary tokens so function
  -- words' codas are not adopted as content words' onsets.
  for i = #tokens, 1, -1 do
    if tokens[i].type == "vowel" and (tokens[i].stress or tokens[i].secondary)
       and not tokens[i].stress_no_walk then
      local onset_start = i
      for j = i - 1, 1, -1 do
        local t = tokens[j]
        if t.type == "cons" and t.phon and t.phon ~= "" then
          onset_start = j
        elseif t.type == "boundary" then
          -- Apostrophe boundaries (d'fhag, b'fhearr) and hyphen boundaries
          -- (n-aicmí, t-ógánach, h-Éirinn) are elision/mutation markers,
          -- not prosodic boundaries — skip them to let stress land on the
          -- prefix consonant. True boundaries (spaces) remain as barriers.
          if t.ortho == "'" or t.ortho == "-" then
            -- skip apostrophe/hyphen
          else
            break
          end
        elseif t.phon == nil or t.phon == "" then
          -- skip silenced non-boundary tokens (fh, th, etc.)
        elseif t.ortho == "-" then
          -- skip hyphen tokens (type "unknown", phon "-"): mutation prefix
          -- markers (n-itheann, t-ógánach), not prosodic boundaries
        else
          break
        end
      end
      -- Word-medial stress: the onset can only be a phonotactically legal
      -- cluster (Hickey II.1.10: obstruent(+liquid), s+stop(+liquid)).
      -- A preceding coda consonant must stay with the previous syllable:
      -- portach → pˠəɾˠ.ˈt̪ˠax (rt is coda|onset, not an onset cluster).
      if onset_start < i then
        local has_prev_vowel = false
        for j = onset_start - 1, 1, -1 do
          local t = tokens[j]
          if t.type == "vowel" then has_prev_vowel = true; break end
          if t.type == "boundary" and t.ortho ~= "'" then break end
        end
        if has_prev_vowel then
          local cons = {}
          for j = onset_start, i - 1 do
            local t = tokens[j]
            if t.type == "cons" and t.phon and t.phon ~= "" then
              table.insert(cons, j)
            end
          end
          local function is_liquid(t) local o = t.ortho or ""; return o == "r" or o == "l" end
          local function is_stop_or_f(t)
            local o = (t.ortho or ""):sub(1, 1)
            return o == "p" or o == "t" or o == "c" or o == "b" or o == "d"
                or o == "g" or o == "f" or o == "m"
          end
          if #cons >= 2 then
            local a, b = tokens[cons[#cons - 1]], tokens[cons[#cons]]
            -- Benchmark syllabification: medial s+stop is HETEROsyllabic —
            -- the s closes the previous syllable (aistriú → aʃ.ˈtʲɾʲuː,
            -- eisceacht → əʃ.ˈcaxt̪ˠ; 61 vs 7 across the three dialects).
            -- Only obstruent+liquid remains a legal medial onset cluster.
            local legal_pair = (is_stop_or_f(a) and is_liquid(b))
            if legal_pair then
              onset_start = cons[#cons - 1]
            else
              onset_start = cons[#cons]
            end
          end
        end
      end
      if onset_start < i then
        if tokens[i].stress then
          tokens[i].stress = false
          tokens[onset_start].stress = true
        end
        if tokens[i].secondary then
          tokens[i].secondary = false
          tokens[onset_start].secondary = true
        end
      end
    end
  end

  -- Shared onset-start helper: walks backward from vowel_idx to find
  -- the phonotactically legal onset start. Stops at word boundaries;
  -- optionally stops at boundary tokens (use true for secondary stress,
  -- which must not cross word/morpheme boundaries).
  local function find_onset_start(tokens, vowel_idx, stop_at_boundaries)
    local onset = vowel_idx
    for j = vowel_idx - 1, 1, -1 do
      local t = tokens[j]
      if t.type == "cons" and t.phon and t.phon ~= "" then
        onset = j
      elseif t.type == "boundary" and stop_at_boundaries then
        break
      elseif t.phon == nil or t.phon == "" then
        -- skip silent/ghost consonants (fh, th, etc.)
      else
        break
      end
    end
    return onset
  end

  local parts = {}
  for i, token in ipairs(tokens) do
    if token.phon and token.phon ~= "" then
        -- Skip hyphens in rendered output (e.g. t-ainm, -fidh).
        -- Only skip hyphen characters, not all boundaries (spaces are needed).
        if token.phon == "-" or token.ortho == "-" then
          goto render_continue
        end
      if token.stress and token.type == "cons" then
        -- IPA convention: ˈCV not CˈV. The pre-process above already moved
        -- stress to the correct (phonotactically legal) onset start, so the
        -- mark is emitted exactly where the stress token sits. Lexically
        -- positioned marks (pass 14 Step 11, stress_no_walk) also emit here.
        table.insert(parts, S.STRESS_MARK)
      elseif token.stress then
        table.insert(parts, S.STRESS_MARK)
      elseif token.secondary and token.type == "cons" and token.stress_no_walk then
        -- Lexically positioned mark (pass 14 Step 11): emit exactly here.
        table.insert(parts, S.SECONDARY_STRESS_MARK)
      elseif token.secondary and token.type == "cons" then
        -- Secondary stress: reuse the same onset-start logic as primary.
        local onset_start = find_onset_start(tokens, i, true)
        if onset_start == i then
          table.insert(parts, S.SECONDARY_STRESS_MARK)
        end
      elseif token.secondary then
        table.insert(parts, S.SECONDARY_STRESS_MARK)
      end
      table.insert(parts, token.phon)
    end
    ::render_continue::
  end
  return table.concat(parts)
end

-- Lexical exception layer: benchmark-verified per-word surface corrections,
-- generated by tools/gen_lexical_subs.py. Standard hybrid G2P architecture:
-- rule pipeline first, exception dictionary last (words whose surface form
-- the rules cannot derive — loanwords, fossilized forms, dialect-specific
-- lexicalizations). Pre-loaded at module init by ga-pron_wasm.lua so that
-- the memoize'd require resolves inside the doString coroutine where async
-- fetch is allowed by wasmoon (not from a JS→Lua callback, which rejects it).
local lex_subs_cache = {}
local lex_subs_ok, lex_subs_connacht = pcall(require, "ga-passes.lex_subs_connacht")
if lex_subs_ok then lex_subs_cache.connacht = lex_subs_connacht end
local lex_subs_ok_m, lex_subs_munster = pcall(require, "ga-passes.lex_subs_munster")
if lex_subs_ok_m then lex_subs_cache.munster = lex_subs_munster end
local lex_subs_ok_u, lex_subs_ulster = pcall(require, "ga-passes.lex_subs_ulster")
if lex_subs_ok_u then lex_subs_cache.ulster = lex_subs_ulster end

local function apply_lex_subs(ipa, word, dialect)
  local subs = lex_subs_cache[dialect]
  if not subs then return ipa end
  local key = S.strip_fadas(ustring.lower(word))
  local entry = subs[key]
  if entry then
    local s, e = ipa:find(entry.f, 1, true)
    if s then
      ipa = ipa:sub(1, s - 1) .. entry.r .. ipa:sub(e + 1)
    end
  end
  return ipa
end

-- Orchestrator entry point
local function transcribe(word, dialect)
  local tokens = tokenize_word(word)
  local context = {
    dialect = dialect or "connacht",
    word_ortho = word,
    is_monosyllabic = false,
    vowel_count = 0,
    root_vowel_count = 0,
    stress_index = nil,
    stress_position = 0,
    known_prefixes = S.KNOWN_PREFIXES,
  }
  tokens = passes.run_all(tokens, context)
  local ipa = render_output(tokens)
  ipa = apply_lex_subs(ipa, word, context.dialect)
  return ipa, tokens
end

return {
  transcribe = transcribe,
  tokenize_word = tokenize_word,
  render_output = render_output,
}
