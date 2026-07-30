-- Pass #6d: Anticipatory vowel raising (Western Irish, Connacht only).
-- Hickey II.1.9.4: Short /a/ or /o/ in the FIRST syllable raises to [ɪ] or [ʊ]
-- if the second syllable contains a long [aː].
-- coláiste → kʊlˠaːʃtʲə, caisleán → kɪʃlʲaːnˠ.
-- Only applies when anticipatory_raising = true (Connacht).
-- Runs after r_lowering (#6c), before labial_vocalization (#6e).
-- Uses orthography to check, since vowel resolution hasn't run yet.

local S = require("ga-passes._shared")

return {
  name = "anticipatory_raising",
  writes_context = false,

  run = function(tokens, context)
    local dv = S.DIALECTS[context.dialect] or S.DIALECTS.connacht
    if not dv.anticipatory_raising then return tokens end
    -- Disabled: measured against the 6593-word Connacht benchmark, this rule
    -- raises the first-syllable vowel (a->I, o->U) in 141 candidate words but
    -- matches the expected IPA in only 11 of them; the other 130 expect an
    -- unraised vowel (boscai->bOs ki:, bothan->bOhA:n, Poncan->pONkA:n,
    -- scolaireacht->skOl..., balle->bAl i:). Disabling is net +103 exact
    -- (110 improved, 7 regressed). The 7 regressions (Tomas, droman, troman,
    -- amhain, fomhuirean, gabhaltas, Tomaisin) are lexically unpredictable --
    -- even the o+m/n+a context splits 4/4 -- so no narrow guard recovers them
    -- cleanly. The original raising body is in git history (commit bca02b6);
    -- re-enable only with a lexical list.
    return tokens
  end,
}
