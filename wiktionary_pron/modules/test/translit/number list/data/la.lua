local export = {numbers = {}}
export.numeral_config = {
	module = "foreign numerals",
	func = "to_Roman",
}
local numbers = export.numbers
numbers[0] = {
	cardinal = "nihil",
}
numbers[1] = {
	cardinal = "ūnus",
	ordinal = "prīmus",
	adverbial = "semel",
	multiplier = {"simplex", "simplus"},
	distributive = "singulī",
	fractional = { "integer" },
	collective = { "ūniō" },
}
numbers[2] = {
	cardinal = "duo",
	ordinal = {"secundus", "alter"},
	adverbial = "bis",
	multiplier = { "duplex", "duplus" },
	distributive = "bīnī",
	fractional = { "dīmidius", "sēmis" },
	collective = { "bīniō" },
}
numbers[3] = {
	cardinal = "trēs",
	ordinal = "tertius",
	adverbial = "ter",
	multiplier = { "triplex", "triplus" },
	distributive = { "ternī", "trīnī" },
	fractional = "triēns",
	collective = { "terniō" },
}
numbers[4] = {
	cardinal = "quattuor",
	ordinal = "quārtus",
	adverbial = "quater",
	multiplier = { "quadruplex", "quadruplus" },
	distributive = { "quadrīnī", "quaternī" },
	fractional = { "quadrāns", "teruncius" },
	collective = { "quaterniō" },
}
numbers[5] = {
	cardinal = {"quīnque"},
	ordinal = "quīntus",
	adverbial = {"quīnquiēs", "quīnquiēns"},
	multiplier = { "quīnquiplus", "quīnquiplex", "quīntuplus", "quīntuplex" },
	distributive = "quīnī",
	fractional = "quīntāns",
	collective = { "quīniō" },
}
numbers[6] = {
	cardinal = "sex",
	ordinal = "sextus",
	adverbial = {"sexiēs", "sexiēns"},
	multiplier = { "sexuplus", "sexuplex", "sextuplus", "seplex" },
	distributive = "sēnī",
	fractional = "sextāns",
	collective = { "sēniō" },
}
numbers[7] = {
	cardinal = "septem",
	ordinal = "septimus",
	adverbial = {"septiēs", "septiēns"},
	multiplier = { "septimplus", "septemplus", "septimplex", "septemplex", "septuplus", "septuplex" },
	distributive = "septēnī",
	fractional = "septāns",
}
numbers[8] = {
	cardinal = "octō",
	ordinal = "octāvus",
	adverbial = {"octiēs", "octiēns"},
	multiplier = { "octuplus", "octuplex", "octoplus" },
	distributive = "octōnī",
	fractional = "octāns",
}
numbers[9] = {
	cardinal = "novem",
	ordinal = "nōnus",
	adverbial = {"noviēs", "noviēns", "nōniēs", "nōniēns"},
	multiplier = { "novemplus", "novemplex", "nōnuplus", "nōnuplex", "noncuplus", "noncuplex", "novemcuplus", "novemcuplex" },
	distributive = "novēnus",
	fractional = "nōnus",
}
numbers[10] = {
	cardinal = "decem",
	ordinal = "decimus",
	adverbial = {"deciēs", "deciēns"},
	multiplier = { "decuplus", "decuplex", "decemplus", "decemplex" },
	distributive = "dēnī",
	fractional = { "decima", "decimus" },
}
numbers[11] = {
	cardinal = "ūndecim",
	ordinal = "ūndecimus",
	adverbial = {"ūndeciēs", "ūndeciēns"},
	multiplier = { "undecuplus", "undecuplex", "undecimplus", "undecimplex", "undecemplus", "undecemplex" },
	distributive = "ūndēnī",
	fractional = "ūndecimus",
}
numbers[12] = {
	cardinal = "duodecim",
	ordinal = "duodecimus",
	adverbial = {"duodeciēs", "duodeciēns"},
	multiplier = { "duodecuplus", "duodecuplex", "duodecimplus", "duodecimplex", "duodecemplus", "duodecemplex" },
	distributive = "duodēnī",
	fractional = "ū̆ncia",
}
numbers[13] = {
	cardinal = "tredecim",
	ordinal = {"tertiusdecimus", "tertius decimus"},
	adverbial = {"terdeciēs", "terdeciēns", "tredeciēs", "tredeciēns"},
	multiplier = {"terdecuplus", "terdecuplex"},
	distributive = "terdēnī",
	fractional = {"tertiusdecimus", "tertius decimus"},
}
numbers[14] = {
	cardinal = "quattuordecim",
	ordinal = {"quārtusdecimus", "quārtus decimus"},
}
numbers[15] = {
	cardinal = "quīndecim",
	ordinal = {"quīntusdecimus", "quīntus decimus"},
}
numbers[16] = {
	cardinal = "sēdecim",
	ordinal = {"sextusdecimus", "sextus decimus"},
}
numbers[17] = {
	cardinal = "septendecim",
	ordinal = {"septimusdecimus", "septimus decimus"},
}
numbers[18] = {
	cardinal = { "duodēvīgintī", "octōdecim" },
	ordinal = { "duodēvīcēsimus", "octōdecimus" },
	distributive = "duodēvīcēnī",
}
numbers[19] = {
	cardinal = { "ūndēvīgintī", "novemdecim", "novendecim" },
	ordinal = { "ūndēvīcēsimus", "novemdecimus", "novendecimus" },
}
numbers[20] = {
	cardinal = "vīgintī",
	ordinal = { "vīcēsimus", "vīgēsimus", "vīcēnsimus", "vīgēnsimus", "vīcēnsumus" },
	adverbial = { "vīciēs", "vīciēns", "vīgēsiēs" },
	distributive = { "vīcēnī", "vīgēnī" },
	fractional = { "vīcēsimus", "vīgēsimus", "vīcēnsimus", "vīgēnsimus", "vīcēnsumus" },
}
numbers[21] = {
	cardinal = {"vīgintī ūnus", "ūnus et vīgintī"},
}
numbers[22] = {
	cardinal = {"vīgintī duo", "duo et vīgintī"},
}
numbers[23] = {
	cardinal = "vīgintī trēs",
}
numbers[24] = {
	cardinal = "vīgintī quattuor",
}
numbers[25] = {
	cardinal = "vīgintī quīnque",
}
numbers[26] = {
	cardinal = "vīgintī sex",
}
numbers[27] = {
	cardinal = "vīgintī septem",
}
numbers[28] = {
	cardinal = "duodētrīgintā",
	ordinal = "duodētrīcēsimus",
	adverbial = "duodētrīciēns",
}
numbers[29] = {
	cardinal = "ūndētrīgintā",
	ordinal = "ūndētrīcēsimus",
}
numbers[30] = {
	cardinal = "trīgintā",
	ordinal = "trīcēsimus",
	adverbial = {"trīciēns", "trīciēs"},
	distributive = "trīcēnī",
}
numbers[31] = {
	cardinal = "trīgintā ūnus",
}
numbers[32] = {
	cardinal = "trīgintā duo",
}
numbers[33] = {
	cardinal = "trīgintā trēs",
}
numbers[34] = {
	cardinal = "trīgintā quattuor",
}
numbers[35] = {
	cardinal = "trīgintā quīnque",
}
numbers[36] = {
	cardinal = "trīgintā sex",
}
numbers[37] = {
	cardinal = "trīgintā septem",
}
numbers[38] = {
	cardinal = "duodēquadrāgintā",
	ordinal = "duodēquadrāgēsimus",
	distributive = "duodēquādrāgēnī",
}
numbers[39] = {
	cardinal = "ūndēquadrāgintā",
	ordinal = "ūndēquadrāgēsimus",
	adverbial = "ūndēquadrāgiēns",
}
numbers[40] = {
	cardinal = "quadrāgintā",
	ordinal = "quadrāgēsimus",
	adverbial = {"quadrāgiēns", "quadrāgiēs"},
	distributive = "quādrāgēnī",
}
numbers[41] = {
	cardinal = "quadrāgintā ūnus",
	ordinal = "ūnus et quadrāgēsimus",
	distributive = "quādrāgēnī singulī",
}
numbers[42] = {
	cardinal = "quadrāgintā duo",
}
numbers[43] = {
	cardinal = "quadrāgintā trēs",
}
numbers[44] = {
	cardinal = "quadrāgintā quattuor",
}
numbers[45] = {
	cardinal = "quadrāgintā quīnque",
}
numbers[46] = {
	cardinal = "quadrāgintā sex",
}
numbers[47] = {
	cardinal = "quadrāgintā septem",
}
numbers[48] = {
	cardinal = "duodēquīnquāgintā",
	ordinal = "duodēquīnquāgēsimus",
	distributive = "duodēquīnquāgēnī",
}
numbers[49] = {
	cardinal = "ūndēquīnquāgintā",
	ordinal = "ūndēquīnquāgēsimus",
}
numbers[50] = {
	cardinal = {"quīnquāgintā"},
	ordinal = "quīnquāgēsimus",
	adverbial = "quīnquāgiēns",
	distributive = "quīnquāgēnī",
}
numbers[51] = {
	cardinal = "quīnquāgintā ūnus",
}
numbers[52] = {
	cardinal = "quīnquāgintā duo",
}
numbers[53] = {
	cardinal = "quīnquāgintā trēs",
}
numbers[54] = {
	cardinal = "quīnquāgintā quattuor",
}
numbers[55] = {
	cardinal = "quīnquāgintā quīnque",
}
numbers[56] = {
	cardinal = "quīnquāgintā sex",
}
numbers[57] = {
	cardinal = "quīnquāgintā septem",
}
numbers[58] = {
	cardinal = "duodēsexāgintā",
	ordinal = "duodēsexāgēsimus",
}
numbers[59] = {
	cardinal = "ūndēsexāgintā",
	ordinal = "ūndēsexāgēsimus",
}
numbers[60] = {
	cardinal = "sexāgintā",
	ordinal = "sexāgēsimus",
	adverbial = {"sexāgiēns", "sexāgiēs"},
	distributive = "sexāgēnī",
}
numbers[61] = {
	cardinal = "sexāgintā ūnus",
}
numbers[62] = {
	cardinal = "sexāgintā duo",
}
numbers[63] = {
	cardinal = "sexāgintā trēs",
}
numbers[64] = {
	cardinal = "sexāgintā quattuor",
}
numbers[65] = {
	cardinal = "sexāgintā quīnque",
}
numbers[66] = {
	cardinal = "sexāgintā sex",
}
numbers[67] = {
	cardinal = "sexāgintā septem",
}
numbers[68] = {
	cardinal = "duodēseptuāgintā",
	ordinal = "duodēseptuāgēsimus",
}
numbers[69] = {
	cardinal = "ūndēseptuāgintā",
	ordinal = "ūndēseptuāgēsimus",
}
numbers[70] = {
	cardinal = "septuāgintā",
	ordinal = "septuāgēsimus",
	adverbial = "septuāgiēs",
	distributive = "septuāgēnī",
}
numbers[71] = {
	cardinal = "septuāgintā ūnus",
}
numbers[72] = {
	cardinal = "septuāgintā duo",
}
numbers[73] = {
	cardinal = "septuāgintā trēs",
}
numbers[74] = {
	cardinal = "septuāgintā quattuor",
}
numbers[75] = {
	cardinal = "septuāgintā quīnque",
}
numbers[76] = {
	cardinal = "septuāgintā sex",
}
numbers[77] = {
	cardinal = "septuāgintā septem",
}
numbers[78] = {
	cardinal = "duodeoctōgintā",
}
numbers[79] = {
	cardinal = "ūndeoctōgintā",
}
numbers[80] = {
	cardinal = {"octōgintā", "octāgintā"},
	ordinal = "octōgēsimus",
	adverbial = {"octōgiēns", "octōgiēs"},
	distributive = "octōgēnī",
}
numbers[81] = {
	cardinal = "octōgintā ūnus",
}
numbers[82] = {
	cardinal = "octōgintā duo",
}
numbers[83] = {
	cardinal = "octōgintā trēs",
}
numbers[84] = {
	cardinal = "octōgintā quattuor",
}
numbers[85] = {
	cardinal = "octōgintā quīnque",
}
numbers[86] = {
	cardinal = "octōgintā sex",
}
numbers[87] = {
	cardinal = "octōgintā septem",
}
numbers[88] = {
	cardinal = "duodēnōnāgintā",
}
numbers[89] = {
	cardinal = "ūndēnōnāgintā",
}
numbers[90] = {
	cardinal = {"nōnāgintā"},
	ordinal = "nōnāgēsimus",
	adverbial = "nōnāgiēns",
	distributive = "nōnāgēnī",
}
numbers[91] = {
	cardinal = "nōnāgintā ūnus",
}
numbers[92] = {
	cardinal = "nōnāgintā duo",
}
numbers[93] = {
	cardinal = "nōnāgintā trēs",
}
numbers[94] = {
	cardinal = "nōnāgintā quattuor",
}
numbers[95] = {
	cardinal = "nōnāgintā quīnque",
}
numbers[96] = {
	cardinal = "nōnāgintā sex",
}
numbers[97] = {
	cardinal = "nōnāgintā septem",
}
numbers[98] = {
	cardinal = { "nōnāgintā octō", "octō et nōnāgintā", "duodēcentum" },
	ordinal = { "nōnāgēsimus octāvus", "duodēcentēsimus" },
}
numbers[99] = {
	cardinal = { "nōnāgintā novem", "novem et nōnāgintā", "ūndēcentum" },
	ordinal = { "nōnāgēsimus nōnus", "ūndēcentēsimus" },
}
numbers[100] = {
	cardinal = "centum",
	ordinal = "centēsimus",
	adverbial = { "centiēs", "centiēns" },
	multiplier = { "centūplus", "centuplex", "centumgeminus" },
	distributive = "centēnī",
	fractional = "centēsimus",
}
numbers[200] = {
	cardinal = "ducentī",
	ordinal = "ducentēsimus",
	distributive = "ducēnī",
}
numbers[300] = {
	cardinal = {"trecentī", "trecentum"},
	ordinal = "trecentēsimus",
	distributive = "trecēnī",
}
numbers[400] = {
	cardinal = "quadringentī",
	ordinal = "quadringentēsimus",
	distributive = "quadringēnī",
}
numbers[500] = {
	cardinal = "quīngentī",
	ordinal = "quīngentēsimus",
	distributive = {"quingēnī", "quingentēnī"},
}
numbers[600] = {
	cardinal = {"sescentī", "sexcentī"},
	ordinal = "sescentēsimus",
	distributive = "sescēnī",
}
numbers[700] = {
	cardinal = "septingentī",
	ordinal = "septingentēsimus",
	distributive = "septingēnī",
}
numbers[800] = {
	cardinal = "octingentī",
	ordinal = "octingentēsimus",
	distributive = "octingēnī",
}
numbers[900] = {
	cardinal = "nōngentī",
	ordinal = "nōngentēsimus",
	distributive = "nongēnī",
}
numbers[999] = {
	ordinal = "ūndēmīllēsimus",
}
numbers[1000] = {
	cardinal = "mīlle",
	ordinal = "mīllēsimus",
	adverbial = {"mīlliēns", "mīlliēs"},
	distributive = "mīllēnī",
}
numbers[1000000] = {
	cardinal = "milliō",
	ordinal = "milliōnēsimus",
}
--[[
numbers[2] = {
	cardinal = "",
	ordinal = "",
	adverbial = "",
	multiplier = "",
	distributive = "",
	fractional = "",
}
--]]
return export