-- Passes initializer. Loads all 16 passes in order.

local S = require("ga-passes.shared")

local passes = {}
passes[1]  = require("ga-passes.01_polarity")
passes[2]  = require("ga-passes.02_stress")
passes[3]  = require("ga-passes.03_eclipsis")
passes[4]  = require("ga-passes.04_cluster_simplify")
passes[5]  = require("ga-passes.05_mutated_fricatives")
passes[6]  = require("ga-passes.06_vocalization")
passes[7]  = require("ga-passes.06d_anticipatory_raising")
passes[8]  = require("ga-passes.07_nasalization")
passes[9]  = require("ga-passes.08_slender_coda")
passes[10] = require("ga-passes.09_consonants")
passes[11] = require("ga-passes.09b_vowel_adjunct")
passes[12] = require("ga-passes.10_vowels")
passes[13] = require("ga-passes.11_unstressed_reduction")
passes[14] = require("ga-passes.12_epenthesis")
passes[15] = require("ga-passes.13_sonorants")
passes[16] = require("ga-passes.14_final_cleanup")
passes[17] = require("ga-passes.15_dialect_finalize")

local function run_all(tokens, context)
  for i = 1, #passes do
    tokens = passes[i].run(tokens, context)
  end
  return tokens
end

return {
  passes = passes,
  run_all = run_all,
}
