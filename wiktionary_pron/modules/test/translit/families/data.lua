--[=[
	This module contains definitions for all language family codes on Wiktionary.
]=]--

local m = {}

m["aav"] = {
	"Austroasiatic",
	33199,
	aliases = {"Austro-Asiatic"},
}

m["aav-khs"] = {
	"Khasian",
	3073734,
	"aav",
	aliases = {"Khasic"},
}

m["aav-nic"] = {
	"Nicobarese",
	217380,
	"aav",
}

m["aav-pkl"] = {
	"Pnar-Khasi-Lyngngam",
	nil,
	"aav-khs",
}

m["afa"] = {
	"Afroasiatic",
	25268,
	aliases = {"Afro-Asiatic"},
}

m["alg"] = {
	"Algonquian",
	33392,
	"aql",
}

m["alg-abp"] = {
	"Abenaki-Penobscot",
	197936,
	"alg-eas",
}

m["alg-ara"] = {
	"Arapahoan",
	2153686,
	"alg",
}

m["alg-eas"] = {
	"Eastern Algonquian",
	2257525,
	"alg",
}

m["alg-sfk"] = {
	"Sac-Fox-Kickapoo",
	1440172,
	"alg",
}

m["alv"] = {
	"Atlantic-Congo",
	771124,
	"nic",
}

m["alv-aah"] = {
	"Ayere-Ahan",
	750953,
	"alv-von",
}

m["alv-ada"] = {
	"Adamawa",
	32906,
	"alv-sav",
}

m["alv-bag"] = {
	"Baga",
	2746083,
	"alv-mel",
}

m["alv-bak"] = {
	"Bak",
	1708174,
	"alv-sng",
}

m["alv-bam"] = {
	"Bambukic",
	4853456,
	"alv-ada",
	aliases = {"Yungur-Jen"},
}

m["alv-bny"] = {
	"Banyum",
	2892477,
	"alv-nyn",
}

m["alv-bua"] = {
	"Bua",
	4982094,
	"alv-mbd",
}

m["alv-bwj"] = {
	"Bikwin-Jen",
	84542501,
	"alv-bam",
}

m["alv-cng"] = {
	"Cangin",
	1033184,
	"alv-fwo",
}

m["alv-ctn"] = {
	"Central Tano",
	1658486,
	"alv-ptn",
	aliases = {"Akan"},
}

m["alv-dlt"] = {
	"Delta Edoid",
	nil,
	"alv-edo",
}

m["alv-dur"] = {
	"Duru",
	5316788,
	"alv-lni",
}

m["alv-ede"] = {
	"Ede",
	35368,
	"alv-yor",
}

m["alv-edk"] = {
	"Edekiri",
	5336735,
	"alv-yrd",
}

m["alv-edo"] = {
	"Edoid",
	1287469,
	"alv-von",
}

m["alv-eeo"] = {
	"Edo-Esan-Ora",
	nil,
	"alv-nce",
}

m["alv-fli"] = {
	"Fali",
	3450166,
	"alv",
}

m["alv-fwo"] = {
	"Fula-Wolof",
	12631267,
	"alv-sng",
}

m["alv-gba"] = {
	"Gbaya",
	3099986,
	"alv-sav",
	protoLanguage = "gba",
}

m["alv-gbe"] = {
	"Gbe",
	668284,
	"alv-von",
}

m["alv-gbf"] = {
	"Eastern Gbaya",
	nil,
	"alv-gba",
}

m["alv-gbs"] = {
	"Southern Gbaya",
	nil,
	"alv-gba",
}

m["alv-gbw"] = {
	"Western Gbaya",
	nil,
	"alv-gba",
}

m["alv-gda"] = {
	"Ga-Dangme",
	3443338,
	"alv-kwa",
}

m["alv-gng"] = {
	"Guang",
	684009,
	"alv-ptn",
}

m["alv-gtm"] = {
	"Ghana-Togo Mountain",
	493020,
	"alv-kwa",
	aliases = {"Togo Remnant", "Central Togo"},
}

m["alv-hei"] = {
	"Heiban",
	108752116,
	"alv-the",
}

m["alv-ido"] = {
	"Idomoid",
	974196,
	"alv-von",
}

m["alv-igb"] = {
	"Igboid",
	1429100,
	"alv-von",
}

m["alv-jfe"] = {
	"Jola-Felupe",
	1708174,
	"alv-jol",
	aliases = {"Ejamat"},
}

m["alv-jol"] = {
	"Jola",
	35176,
	"alv-bak",
	aliases = {"Diola"},
}

m["alv-kim"] = {
	"Kim",
	6409701,
	"alv-mbd",
}

m["alv-kis"] = {
	"Kissi",
	35696,
	"alv-mel",
}

m["alv-krb"] = {
	"Karaboro",
	4213541,
	"alv-snf",
}

m["alv-ktg"] = {
	"Ka-Togo",
	5972796,
	"alv-gtm",
}

m["alv-kul"] = {
	"Kulango",
	16977424,
	"alv-sav",
	aliases = {"Kulango-Lorhon", "Kulango-Lorom"},
}

m["alv-kwa"] = {
	"Kwa",
	33430,
	"nic-vco",
}

m["alv-lag"] = {
	"Lagoon",
	111210042,
	"alv-kwa",
}

m["alv-lek"] = {
	"Leko",
	6520642,
	otherNames = {"Sambaic"}, -- appears to be an alias in Glottolog
	"alv-lni",
}

m["alv-lim"] = {
	"Limba",
	35825,
	"alv",
}

m["alv-lni"] = {
	"Leko-Nimbari",
	1708170,
	"alv-ada",
	otherNames = {"Central Adamawa"},
	aliases = {"Chamba-Mumuye"},
}

m["alv-mbd"] = {
	"Mbum-Day",
	6799816,
	"alv-ada",
}

m["alv-mbm"] = {
	"Mbum",
	6799814,
	"alv-mbd",
}

m["alv-mel"] = {
	"Mel",
	12122355,
	"alv",
}

m["alv-mum"] = {
	"Mumuye",
	84607009,
	"alv-mye",
}

m["alv-mye"] = {
	"Mumuye-Yendang",
	6935539,
	"alv-lni",
}

m["alv-nal"] = {
	"Nalu",
	nil,
	"alv-sng",
}

m["alv-nce"] = {
	"North-Central Edoid",
	16110869,
	"alv-edo",
}

m["alv-ngb"] = {
	"Nupe-Gbagyi",
	12638649,
	"alv-nup",
	aliases = {"Nupe-Gbari"},
}

m["alv-ntg"] = {
	"Na-Togo",
	nil,
	"alv-gtm",
}

m["alv-nup"] = {
	"Nupoid",
	1429143,
	"alv-von",
}

m["alv-nwd"] = {
	"Northwestern Edoid",
	16111012,
	"alv-edo",
}

m["alv-nyn"] = {
	"Nyun",
	nil,
	"alv-fwo",
}

m["alv-pap"] = {
	"Papel",
	7132562,
	"alv-bak",
}

m["alv-pph"] = {
	"Phla-Pherá",
	3849625,
	"alv-gbe",
	aliases = {"Phla–Pherá"},
}

m["alv-ptn"] = {
	"Potou-Tano",
	1475003,
	"alv-kwa",
}

m["alv-sav"] = {
	"Savanna",
	4403672,
	"nic-vco",
	aliases = {"Savannas"},
}

m["alv-sma"] = {
	"Suppire-Mamara",
	4446348,
	"alv-snf",
}

m["alv-snf"] = {
	"Senufo",
	33795,
	"alv",
	aliases = {"Senufic", "Senoufo"},
}

m["alv-sng"] = {
	"Senegambian",
	1708753,
	"alv",
}

m["alv-snr"] = {
	"Senari",
	4416084,
	"alv-snf",
}

m["alv-swd"] = {
	"Southwestern Edoid",
	12633903,
	"alv-edo",
}

m["alv-tal"] = {
	"Talodi",
	12643302,
	"alv-the",
}

m["alv-tdj"] = {
	"Tagwana-Djimini",
	7675362,
	"alv-snf",
}

m["alv-ten"] = {
	"Tenda",
	3217535,
	"alv-fwo",
}

m["alv-the"] = {
	"Talodi-Heiban",
	1521145,
	"alv",
}

m["alv-von"] = {
	"Volta-Niger",
	34177,
	"nic-vco",
}

m["alv-wan"] = {
	"Wara-Natyoro",
	7968830,
	"alv-sav",
}

m["alv-wjk"] = {
	"Waja-Kam",
	nil,
	"alv-ada",
}

m["alv-yek"] = {
	"Yekhee",
	nil,
	"alv-nce",
}

m["alv-yor"] = {
	"Yoruba",
	nil,
	"alv-edk",
}

m["alv-yrd"] = {
	"Yoruboid",
	1789745,
	"alv-von",
}

m["alv-yun"] = {
	"Yungur",
	84601642,
	"alv-bam",
	aliases = {"Bena-Mboi"},
}

m["apa"] = {
	"Apachean",
	27758,
	"ath",
	aliases = {"Southern Athabaskan"},
}

m["aqa"] = {
	"Alacalufan",
	1288430,
}

m["aql"] = {
	"Algic",
	721612,
	aliases = {"Algonquian-Ritwan", "Algonquian-Wiyot-Yurok"},
}

m["art"] = {
	"constructed",
	33215,
	"qfa-not",
	aliases = {"artificial", "planned"},
}

m["ath"] = {
	"Athabaskan",
	27475,
	"xnd",
}

m["ath-nor"] = {
	"North Athabaskan",
	20738,
	"ath",
	aliases = {"Northern Athabaskan"},
}

m["ath-pco"] = {
	"Pacific Coast Athabaskan",
	20654,
	"ath",
}

m["auf"] = {
	"Arauan",
	626772,
	aliases = {"Arahuan", "Arauán", "Arawa", "Arawan", "Arawán"},
}

--[=[
	Exceptional language and family codes for Australian Aboriginal languages
	can use the prefix "aus-", though "aus" is no longer itself a family code.
]=]--
m["aus-arn"] = {
	"Arnhem",
	2581700,
	aliases = {"Gunwinyguan", "Macro-Gunwinyguan"},
}

m["aus-bub"] = {
	"Bunuban",
	2495148,
	aliases = {"Bunaban"},
}

m["aus-cww"] = {
	"Central New South Wales",
	5061507,
	"aus-pam",
}

m["aus-dal"] = {
	"Daly",
	2478079,
}

m["aus-dyb"] = {
	"Dyirbalic",
	1850666,
	"aus-pam",
}

m["aus-gar"] = {
	"Garawan",
	5521951,
}

m["aus-gun"] = {
	"Gunwinyguan",
	2581700,
	"aus-arn",
	aliases = {"Gunwingguan"},
}

m["aus-jar"] = {
	"Jarrakan",
	2039423,
}

m["aus-kar"] = {
	"Karnic",
	4215578,
	"aus-pam",
}

m["aus-mir"] = {
	"Mirndi",
	4294095,
}

m["aus-nga"] = {
	"Ngayarda",
	16153490,
	"aus-psw",
}

m["aus-nyu"] = {
	"Nyulnyulan",
	2039408,
}

m["aus-pam"] = {
	"Pama-Nyungan",
	33942,
}

m["aus-pmn"] = {
	"Paman",
	2640654,
	"aus-pam",
}

m["aus-psw"] = {
	"Southwest Pama-Nyungan",
	2258160,
	"aus-pam",
}

m["aus-rnd"] = {
	"Arandic",
	4784071,
	"aus-pam",
}

m["aus-tnk"] = {
	"Tangkic",
	1823065,
}

m["aus-wdj"] = {
	"Iwaidjan",
	4196968,
	aliases = {"Yiwaidjan"},
}

m["aus-wor"] = {
	"Worrorran",
	2038619,
}

m["aus-yid"] = {
	"Yidinyic",
	4205849,
	"aus-pam",
}

m["aus-yng"] = {
	"Yangmanic",
	42727644,
}

m["aus-yol"] = {
	"Yolngu",
	2511254,
	"aus-pam",
	aliases = {"Yolŋu", "Yolngu Matha"},
}

m["aus-yuk"] = {
	"Yuin-Kuric",
	3833021,
	"aus-pam",
}

m["awd"] = {
	"Arawakan",
	626753,
	aliases = {"Arawak", "Maipurean", "Maipuran"},
}

m["awd-nwk"] = {
	"Nawiki",
	nil,
	"awd",
	aliases = {"Newiki"},
}

m["awd-taa"] = {
	"Ta-Arawakan",
	7672731,
	"awd",
	aliases = {"Ta-Arawak", "Ta-Maipurean"},
}

m["azc"] = {
	"Uto-Aztecan",
	34073,
	aliases = {"Uto-Aztekan"},
}

m["azc-cup"] = {
	"Cupan",
	19866871,
	"azc-tak",
}

m["azc-nah"] = {
	"Nahuan",
	11965602,
	"azc",
	aliases = {"Aztecan"},
}

m["azc-num"] = {
	"Numic",
	2657541,
	"azc",
}

m["azc-tak"] = {
	"Takic",
	1280305,
	"azc",
}

m["azc-trc"] = {
	"Taracahitic",
	4245032,
	"azc",
	aliases = {"Taracahitan"},
}

m["bad"] = {
	"Banda",
	806234,
	"nic-ubg",
}

m["bad-cnt"] = {
	"Central Banda",
	3438391,
	"bad",
}

m["bai"] = {
	"Bamileke",
	806005,
	"nic-gre",
}

m["bat"] = {
	"Baltic",
	33136,
	"ine-bsl",
}

m["bat-eas"] = {
	"East Baltic",
	149944,
	"bat",
}

m["bat-wes"] = {
	"West Baltic",
	149946,
	"bat",
}

m["ber"] = {
	"Berber",
	25448,
	"afa",
	aliases = {"Tamazight"},
}

m["bnt"] = {
	"Bantu",
	33146,
	"nic-bds",
}

m["bnt-baf"] = {
	"Bafia",
	799784,
	"bnt",
}

m["bnt-bbo"] = {
	"Bafo-Bonkeng",
	nil,
	"bnt-saw",
}

m["bnt-bdz"] = {
	"Boma-Dzing",
	1729203,
	"bnt",
}

m["bnt-bek"] = {
	"Bekwilic",
	nil,
	"bnt-ndb",
}

m["bnt-bki"] = {
	"Bena-Kinga",
	16113307,
	"bnt-bne",
}

m["bnt-bmo"] = {
	"Bangi-Moi",
	nil,
	"bnt-bnm",
}

m["bnt-bne"] = {
	"Northeast Bantu",
	7057832,
	"bnt",
}

m["bnt-bnm"] = {
	"Bangi-Ntomba",
	806477,
	"bnt-bte",
}

m["bnt-boa"] = {
	"Boan",
	4931250,
	"bnt",
	aliases = {"Buan", "Ababuan"},
}

m["bnt-bot"] = {
	"Botatwe",
	4948532,
	"bnt",
}

m["bnt-bsa"] = {
	"Basaa",
	809739,
	"bnt",
}

m["bnt-bsh"] = {
	"Bushoong",
	5001551,
	"bnt-bte",
}

m["bnt-bso"] = {
	"Southern Bantu",
	980498,
	"bnt",
}

m["bnt-bta"] = {
	"Bati-Angba",
	4869303,
	"bnt-boa",
	otherNames = {"Late Bomokandian"},
	aliases = {"Bwa"},
}

m["bnt-btb"] = {
	"Beti",
	35118,
	"bnt",
}

m["bnt-bte"] = {
	"Bangi-Tetela",
	4855181,
	"bnt",
}

m["bnt-bun"] = {
	"Buja-Ngombe",
	4986733,
	"bnt-mbb",
}

m["bnt-chg"] = {
	"Chaga",
	33016,
	"bnt-cht",
}

m["bnt-cht"] = {
	"Chaga-Taita",
	nil,
	"bnt-bne",
}

m["bnt-clu"] = {
	"Chokwe-Luchazi",
	3339273,
	"bnt",
}

m["bnt-com"] = {
	"Comorian",
	33077,
	"bnt-sab",
}

m["bnt-glb"] = {
	"Great Lakes Bantu",
	5599420,
	"bnt-bne",
}

m["bnt-haj"] = {
	"Haya-Jita",
	25502360,
	"bnt-glb",
}

m["bnt-kak"] = {
	"Kako",
	nil,
	"bnt-pob",
}

m["bnt-kav"] = {
	"Kavango",
	116544179,
	"bnt-ksb",
}

m["bnt-kbi"] = {
	"Komo-Bira",
	6428591,
	"bnt-boa",
}

m["bnt-kel"] = {
	"Kele",
	1738162,
	"bnt-kts",
	aliases = {"Sheke"},
}

m["bnt-kil"] = {
	"Kilombero",
	6408121,
	"bnt",
}

m["bnt-kka"] = {
	"Kikuyu-Kamba",
	18419596,
	"bnt-bne",
	aliases = {"Thagiicu"},
}

m["bnt-kmb"] = {
	"Kimbundu",
	16947687,
	"bnt",
}

m["bnt-kng"] = {
	"Kongo",
	6429214,
	"bnt",
}

m["bnt-kpw"] = {
	"Kpwe",
	36428,
	"bnt-saw",
}

m["bnt-ksb"] = {
	"Kavango-Southwest Bantu",
	6379098,
	"bnt",
}

m["bnt-kts"] = {
	"Kele-Tsogo",
	6385577,
	"bnt",
}

m["bnt-lbn"] = {
	"Luban",
	4536504,
	"bnt",
}

m["bnt-leb"] = {
	"Lebonya",
	6511395,
	"bnt",
}

m["bnt-lgb"] = {
	"Lega-Binja",
	6517694,
	"bnt",
}

m["bnt-lok"] = {
	"Logooli-Kuria",
	nil,
	"bnt-glb",
}

m["bnt-lub"] = {
	"Luba",
	nil,
	"bnt-lbn",
}

m["bnt-lun"] = {
	"Lunda",
	6704091,
	"bnt",
}

m["bnt-mak"] = {
	"Makua",
	6740431,
	"bnt-bso",
	aliases = {"Makhuwa"},
}

m["bnt-mbb"] = {
	"Mboshi-Buja",
	6799764,
	"bnt",
}

m["bnt-mbe"] = {
	"Mbole-Enya",
	6799728,
	"bnt",
}

m["bnt-mbi"] = {
	"Mbinga",
	nil,
	"bnt-rur",
}

m["bnt-mbo"] = {
	"Mboshi",
	6799763,
	"bnt-mbb",
}

m["bnt-mbt"] = {
	"Mbete",
	1346910,
	"bnt-tmb",
	aliases = {"Mbere"},
}

m["bnt-mby"] = {
	"Mbeya",
	nil,
	"bnt-ruk",
}

m["bnt-mij"] = {
	"Mijikenda",
	6845474,
	"bnt-sab",
}

m["bnt-mka"] = {
	"Makaa",
	nil,
	"bnt-ndb",
}

m["bnt-mne"] = {
	"Manenguba",
	31147471,
	"bnt",
	aliases = {"Mbo", "Ngoe"},
}

m["bnt-mnj"] = {
	"Makaa-Njem",
	1603899,
	"bnt-pob",
}

m["bnt-mon"] = {
	"Mongo",
	nil,
	"bnt-bnm",
}

m["bnt-mra"] = {
	"Mbugwe-Rangi",
	6799795,
	"bnt",
}

m["bnt-msl"] = {
	"Masaba-Luhya",
	12636428,
	"bnt-glb",
}

m["bnt-mwi"] = {
	"Mwika",
	nil,
	"bnt-ruk",
}

m["bnt-ncb"] = {
	"Northeast Coast Bantu",
	7057848,
	"bnt-bne",
}

m["bnt-ndb"] = {
	"Ndzem-Bomwali",
	nil,
	"bnt-mnj",
}

m["bnt-ngn"] = {
	"Ngondi-Ngiri",
	7022532,
	"bnt-mbb",
}

m["bnt-ngu"] = {
	"Nguni",
	961559,
	"bnt-bso",
	aliases = {"Ngoni"},
}

m["bnt-nya"] = {
	"Nyali",
	7070832,
	"bnt-leb",
}

m["bnt-nyb"] = {
	"Nyanga-Buyi",
	7070882,
	"bnt",
}

m["bnt-nyg"] = {
	"Nyoro-Ganda",
	12638666,
	"bnt-glb",
}

m["bnt-nys"] = {
	"Nyasa",
	7070921,
	"bnt",
}

m["bnt-nze"] = {
	"Nzebi",
	1755498,
	"bnt-tmb",
	aliases = {"Njebi"},
}

m["bnt-ova"] = {
	"Ovambo",
	36489,
	"bnt-swb",
	aliases = {"Oshivambo", "Oshiwambo", "Owambo"},
}

m["bnt-par"] = {
	"Pare",
	nil,
	"bnt-ncb",
}

m["bnt-pen"] = {
	"Pende",
	7162373,
	"bnt",
}

m["bnt-pob"] = {
	"Pomo-Bomwali",
	nil,
	"bnt",
}

m["bnt-ruk"] = {
	"Rukwa",
	7378902,
	"bnt",
}

m["bnt-run"] = {
	"Rungwe",
	nil,
	"bnt-ruk",
}

m["bnt-rur"] = {
	"Rufiji-Ruvuma",
	7377947,
	"bnt",
}

m["bnt-ruv"] = {
	"Ruvu",
	nil,
	"bnt-ncb",
}

m["bnt-rvm"] = {
	"Ruvuma",
	nil,
	"bnt-rur",
}

m["bnt-sab"] = {
	"Sabaki",
	2209395,
	"bnt-ncb",
}

m["bnt-saw"] = {
	"Sawabantu",
	532003,
	"bnt",
}

m["bnt-sbi"] = {
	"Sabi",
	7396071,
	"bnt",
}

m["bnt-seu"] = {
	"Seuta",
	nil,
	"bnt-ncb",
}

m["bnt-shh"] = {
	"Shi-Havu",
	nil,
	"bnt-glb",
}

m["bnt-sho"] = {
	"Shona",
	2904660,
	"bnt",
}

m["bnt-sir"] = {
	"Sira",
	1436372,
	"bnt",
	aliases = {"Shira-Punu"},
}

m["bnt-ske"] = {
	"Soko-Kele",
	nil,
	"bnt-bte",
}

m["bnt-sna"] = {
	"Sena",
	nil,
	"bnt-nys",
}

m["bnt-sts"] = {
	"Sotho-Tswana",
	2038386,
	"bnt-bso",
}

m["bnt-swb"] = {
	"Southwest Bantu",
	116543539,
	"bnt-ksb",
}

m["bnt-swh"] = {
	"Swahili",
	nil,
	"bnt-sab",
}

m["bnt-tek"] = {
	"Teke",
	36528,
	"bnt-tmb",
}

m["bnt-tet"] = {
	"Tetela",
	7706059,
	"bnt-bte",
}

m["bnt-tkc"] = {
	"Central Teke",
	nil,
	"bnt-tek",
}

m["bnt-tkm"] = {
	"Takama",
	nil,
	"bnt-bne",
}

m["bnt-tmb"] = {
	"Teke-Mbede",
	7695332,
	"bnt",
	aliases = {"Teke-Mbere"},
}

m["bnt-tso"] = {
	"Tsogo",
	2458420,
	otherNames = {"Okani"}, --appears to be an alias in Glottolog
	"bnt-kts",
}

m["bnt-tsr"] = {
	"Tswa-Ronga",
	12643962,
	"bnt-bso",
}

m["bnt-yak"] = {
	"Yaka",
	8047027,
	"bnt",
}

m["bnt-yko"] = {
	"Yasa-Kombe",
	nil,
	"bnt-saw",
}

m["bnt-zbi"] = {
	"Zamba-Binza",
	nil,
	"bnt-bnm",
}

m["btk"] = {
	"Batak",
	1998595,
	"poz-nws",
}

--[=[
	Exceptional language and family codes for Central American Indian languages
	may use the prefix "cai-", though "cai" is no longer itself a family code.
]=]--

--[=[
	Exceptional language and family codes for Caucasian languages can use
	the prefix "cau-", though "cau" is no longer itself a family code.
]=]--

m["cau-abz"] = {
	"Abkhaz-Abaza",
	4663617,
	"cau-nwc",
	otherNames = {"Abkhaz-Tapanta"},
	aliases = {"Abazgi"},
}

m["cau-and"] = {
	"Andian",
	492152,
	"cau-ava",
	aliases = {"Andic"},
}

m["cau-ava"] = {
	"Avaro-Andian",
	4827766,
	"cau-nec",
	aliases = {"Avar-Andian", "Avar-Andi", "Avar-Andic"},
}

m["cau-cir"] = {
	"Circassian",
	858543,
	"cau-nwc",
	aliases = {"Cherkess"},
}

m["cau-drg"] = {
	"Dargwa",
	5222637,
	"cau-nec",
	otherNames = {"Dargin"},
}

m["cau-esm"] = {
	"Eastern Samur",
	nil,
	"cau-sam",
}

m["cau-ets"] = {
	"East Tsezian",
	121437666,
	"cau-tsz",
	aliases = {"East Tsezic", "East Didoic"},
}

m["cau-lzg"] = {
	"Lezghian",
	2144370,
	"cau-nec",
	aliases = {"Lezgi", "Lezgian", "Lezgic"},
}

m["cau-nkh"] = {
	"Nakh",
	24441,
	"cau-nec",
	aliases = {"North-Central Caucasian"},
}

m["cau-nec"] = {
	"Northeast Caucasian",
	27387,
	"ccn",
	aliases = {"Dagestanian", "Nakho-Dagestanian", "Caspian"},
}

m["cau-nwc"] = {
	"Northwest Caucasian",
	33852,
	"ccn",
	aliases = {"Abkhazo-Adyghean", "Abkhaz-Adyghe", "Pontic"},
}

m["cau-sam"] = {
	"Samur",
	15229151,
	"cau-lzg",
}

m["cau-ssm"] = {
	"Southern Samur",
	nil,
	"cau-sam",
}

m["cau-tsz"] = {
	"Tsezian",
	1651530,
	"cau-nec",
	aliases = {"Tsezic", "Didoic"},
}

m["cau-vay"] = {
	"Vainakh",
	4102486,
	"cau-nkh",
	aliases = {"Veinakh", "Vaynakh"},
}

m["cau-wsm"] = {
	"Western Samur",
	nil,
	"cau-sam",
}

m["cau-wts"] = {
	"West Tsezian",
	121437697,
	"cau-tsz",
	aliases = {"West Tsezic", "West Didoic"},
}

m["cba"] = {
	"Chibchan",
	520478,
	"qfa-mch", -- or none if Macro-Chibchan is considered undemonstrated
}

m["ccn"] = {
	"North Caucasian",
	33732,
}

m["ccs"] = {
	"Kartvelian",
	34030,
	aliases = {"South Caucasian"},
}

m["ccs-gzn"] = {
	"Georgian-Zan",
	34030,
	"ccs",
	aliases = {"Karto-Zan"},
}

m["ccs-zan"] = {
	"Zan",
	2606912,
	"ccs-gzn",
	aliases = {"Zanuri", "Colchian"},
}

m["cdc"] = {
	"Chadic",
	33184,
	"afa",
}

m["cdc-cbm"] = {
	"Central Chadic",
	2251547,
	"cdc",
	aliases = {"Biu-Mandara"},
}

m["cdc-est"] = {
	"East Chadic",
	2276221,
	"cdc",
}

m["cdc-mas"] = {
	"Masa",
	2136092,
	"cdc",
}

m["cdc-wst"] = {
	"West Chadic",
	2447774,
	"cdc",
}

m["cdd"] = {
	"Caddoan",
	1025090,
}

m["cel"] = {
	"Celtic",
	25293,
	"ine",
}

m["cel-bry"] = {
	"Brythonic",
	156877,
	"cel-ins",
	aliases = {"Brittonic"},
}

m["cel-brs"] = {
	"Southwestern Brythonic",
	2612853,
	"cel-bry",
	aliases = {"Southwestern Brittonic"},
}

m["cel-brw"] = {
	"Western Brythonic",
	593069,
	"cel-bry",
	aliases = {"Western Brittonic"},
}

m["cel-con"] = {
	"Continental Celtic",
	215566,
	"cel",
}

m["cel-gae"] = {
	"Goidelic",
	56433,
	"cel-ins",
	aliases = {"Gaelic"},
	protoLanguage = "pgl",
}

m["cel-his"] = {
	"Hispano-Celtic",
	4204136,
	"cel-con",
}

m["cel-ins"] = {
	"Insular Celtic",
	214506,
	"cel",
}

m["chi"] = {
	"Chimakuan",
	1073088,
}

m["chm"] = {
	"Mari",
	973685,
	"urj",
}

m["cmc"] = {
	"Chamic",
	2997506,
	"poz-mcm",
}

m["crp"] = {
	"creole or pidgin",
	nil,
	"qfa-not",
}

m["csu"] = {
	"Central Sudanic",
	190822,
	"ssa",
}

m["csu-bba"] = {
	"Bongo-Bagirmi",
	3505042,
	"csu",
}

m["csu-bbk"] = {
	"Bongo-Baka",
	4941917,
	"csu-bba",
}

m["csu-bgr"] = {
	"Bagirmi",
	4841948,
	"csu-bba",
	aliases = {"Bagirmic"},
}

m["csu-bkr"] = {
	"Birri-Kresh",
	nil,
	"csu",
}

m["csu-ecs"] = {
	"Eastern Central Sudanic",
	16911698,
	"csu",
	aliases = {"East Central Sudanic", "Central Sudanic East", "Lendu-Mangbetu"},
}

m["csu-kab"] = {
	"Kaba",
	6343715,
	"csu-bba",
}

m["csu-lnd"] = {
	"Lendu",
	6522357,
	"csu-ecs",
	aliases = {"Lenduic"},
}

m["csu-maa"] = {
	"Mangbetu",
	6748874,
	"csu-ecs",
	aliases = {"Mangbetu-Asoa", "Mangbetu-Asua"},
}

m["csu-mle"] = {
	"Mangbutu-Lese",
	17009406,
	"csu-ecs",
	aliases = {"Mangbutu–Efe", "Mangbutu", "Membi-Mangbutu-Efe"},
}

m["csu-mma"] = {
	"Moru-Madi",
	6915156,
	"csu-ecs",
}

m["csu-sar"] = {
	"Sara",
	2036691,
	"csu-bba",
}

m["csu-val"] = {
	"Vale",
	7909520,
	"csu-bba",
}

m["cus"] = {
	"Cushitic",
	33248,
	"afa",
}

m["cus-cen"] = {
	"Central Cushitic",
	56569,
	"cus",
}

m["cus-eas"] = {
	"East Cushitic",
	56568,
	"cus",
}

m["cus-hec"] = {
	"Highland East Cushitic",
	56524,
	"cus-eas",
}

m["cus-som"] = {
	"Somaloid",
	56774,
	"cus-eas",
	aliases = {"Sam", "Macro-Somali"},
}

m["cus-sou"] = {
	"South Cushitic",
	56525,
	"cus",
}

m["day"] = {
	"Land Dayak",
	2760613,
	"poz-bop",
}

m["del"] = {
	"Lenape",
	2665761,
	"alg-eas",
	aliases = {"Delaware"},
}

m["den"] = {
	"Slavey",
	13272,
	"ath-nor",
	aliases = {"Slave", "Slavé"},
}

m["dmn"] = {
	"Mande",
	33681,
	"nic",
}

m["dmn-bbu"] = {
	"Bisa-Busa",
	12627956,
	"dmn-mde",
}

m["dmn-emn"] = {
	"East Manding",
	nil,
	"dmn-man",
}

m["dmn-jje"] = {
	"Jogo-Jeri",
	nil,
	"dmn-mjo",
}

m["dmn-man"] = {
	"Manding",
	35772,
	"dmn-mmo",
}

m["dmn-mda"] = {
	"Mano-Dan",
	nil,
	"dmn-mse",
}

m["dmn-mdc"] = {
	"Central Mande",
	5972907,
	"dmn-mdw",
}

m["dmn-mde"] = {
	"Eastern Mande",
	12633080,
	"dmn",
}

m["dmn-mdw"] = {
	"Western Mande",
	16113831,
	"dmn",
}

m["dmn-mjo"] = {
	"Manding-Jogo",
	12636153,
	"dmn-mdc",
}

m["dmn-mmo"] = {
	"Manding-Mokole",
	nil,
	"dmn-mva",
}

m["dmn-mnk"] = {
	"Maninka",
	36186,
	"dmn-emn",
}

m["dmn-mnw"] = {
	"Northwestern Mande",
	5972910,
	"dmn-mdw",
}

m["dmn-mok"] = {
	"Mokole",
	16935447,
	"dmn-mmo",
}

m["dmn-mse"] = {
	"Southeastern Mande",
	5972912,
	"dmn-mde",
}

m["dmn-msw"] = {
	"Southwestern Mande",
	12633904,
	"dmn-mdw",
}

m["dmn-mva"] = {
	"Manding-Vai",
	nil,
	"dmn-mjo",
}

m["dmn-nbe"] = {
	"Nwa-Beng",
	nil,
	"dmn-mse",
}

m["dmn-sam"] = {
	"Samo",
	36327,
	"dmn-bbu",
	aliases = {"Samuic"},
}

m["dmn-smg"] = {
	"Samogo",
	7410000,
	"dmn-mnw",
	aliases = {"Duun-Seenku"},
}

m["dmn-snb"] = {
	"Soninke-Bobo",
	16111680,
	"dmn-mnw",
}

m["dmn-sya"] = {
	"Susu-Yalunka",
	nil,
	"dmn-mdc",
}

m["dmn-vak"] = {
	"Vai-Kono",
	nil,
	"dmn-mva",
}

m["dmn-wmn"] = {
	"West Manding",
	nil,
	"dmn-man",
}

m["dra"] = {
	"Dravidian",
	33311,
}

m["dra-cen"] = {
	"Central Dravidian",
	68002317,
	"dra",
}

m["dra-gki"] = {
	"Gondi-Kui",
	12631610,
	"dra-sdt",
}

m["dra-gon"] = {
	"Gondi",
	55639812,
	"dra-gki",
}

m["dra-imd"] = {
	"Irula-Muduga",
	nil,
	"dra-tkn",
}

m["dra-kan"] = {
	"Kannadoid",
	6363888,
	"dra-tkn",
	protoLanguage = "dra-okn",
}

m["dra-kki"] = {
	"Konda-Kui",
	nil,
	"dra-gki",
}

m["dra-kml"] = {
	"Kurukh-Malto",
	68002822,
	"dra-nor",
}

m["dra-knk"] = {
	"Kolami-Naiki",
	10547037,
	"dra-cen",
}

m["dra-kod"] = {
	"Kodagu",
	67983106,
	"dra-tkd",
}

m["dra-kor"] = {
	"Koraga",
	33394,
	"dra-tlk",
}

m["dra-mal"] = {
	"Malayalamoid",
	6741581,
	"dra-tml",
}

m["dra-mdy"] = {
	"Madiya",
	27602,
	"dra-gon",
}

m["dra-mlo"] = {
	"Malto",
	nil,
	"dra-kml",
}

m["dra-mur"] = {
	"Muria",
	6938499,
	"dra-gon",
}

m["dra-nor"] = {
	"North Dravidian",
	16110967,
	"dra",
}

m["dra-pgd"] = {
	"Parji-Gadaba",
	10620428,
	"dra-cen",
}

m["dra-sdo"] = {
	"South Dravidian I",
	16112843, -- Wikipedia's "South Dravidian" is South Dravidian I in this scheme.
	"dra-sou",
	aliases = {"South Dravidian"}, -- This is why I and II are used.
}

m["dra-sdt"] = {
	"South Dravidian II",
	12633975,
	"dra-sou",
	aliases = {"South-Central Dravidian"},
}

m["dra-sou"] = {
	"South Dravidian",
	nil,
	"dra",
	aliases = {"Southern Dravidian"},
}

m["dra-tam"] = {
	"Tamiloid",
	7681417,
	"dra-tml",
	protoLanguage = "oty",
}

m["dra-tel"] = {
	"Teluguic",
	nil,
	"dra-sdt",
	protoLanguage = "dra-ote",
}

m["dra-tkd"] = {
	"Tamil-Kodagu",
	25494510,
	"dra-tkn",
}

m["dra-tkn"] = {
	"Tamil-Kannada",
	6478506,
	"dra-sdo",
}

m["dra-tkt"] = {
	"Toda-Kota",
	67983857,
	"dra-tkd",
}

m["dra-tlk"] = {
	"Tulu-Koraga",
	nil,
	"dra-sdo",
}

m["dra-tml"] = {
	"Tamil-Malayalam",
	10690507,
	"dra-tkd",
}

m["egx"] = {
	"Egyptian",
	50868,
	"afa",
	protoLanguage = "egy",
}

m["esx"] = {
	"Eskimo-Aleut",
	25946,
}

m["esx-esk"] = {
	"Eskimo",
	25946,
	"esx",
}

m["esx-inu"] = {
	"Inuit",
	27796,
	"esx-esk",
}

m["euq"] = {
	"Vasconic",
	4669240,
}

m["gem"] = {
	"Germanic",
	21200,
	"ine",
}

m["gme"] = {
	"East Germanic",
	108662,
	"gem",
}

m["gmq"] = {
	"North Germanic",
	106085,
	"gem",
}

m["gmq-eas"] = {
	"East Scandinavian",
	3090263,
	"gmq",
	protoLanguage = "non-oen",
}

m["gmq-ins"] = {
	"Insular Scandinavian",
	nil,
	"gmq-wes",
}

m["gmq-wes"] = {
	"West Scandinavian",
	1792570,
	"gmq",
	protoLanguage = "non-own",
}

m["gmw"] = {
	"West Germanic",
	26721,
	"gem",
}

m["gmw-afr"] = {
	"Anglo-Frisian",
	5329170,
	"gmw-nsg",
}

m["gmw-ang"] = {
	"Anglic",
	1346342,
	"gmw-afr",
	protoLanguage = "ang",
}

m["gmw-fri"] = {
	"Frisian",
	25325,
	"gmw-afr",
	protoLanguage = "ofs",
}

m["gmw-frk"] = {
	"Low Franconian",
	153050,
	"gmw",
	protoLanguage = "odt",
}

m["gmw-hgm"] = {
	"High German",
	52040,
	"gmw",
	protoLanguage = "goh",
}

m["gmw-ian"] = {
	"Irish Anglo-Norman",
	120719384,
	"gmw-ang",
	protoLanguage = "enm",
}

m["gmw-lgm"] = {
	"Low German",
	25433,
	"gmw-nsg",
	protoLanguage = "osx",
}

m["gmw-nsg"] = {
	"North Sea Germanic",
	30134,
	"gmw",
}

m["grk"] = {
	"Hellenic",
	2042538,
	"ine",
	aliases = {"Greek"},
}

m["him"] = {
	"Western Pahari",
	12645574,
	"inc-pah",
	aliases = {"Himachali"},
}

m["hmn"] = {
	"Hmong",
	3307894,
	"hmx",
}

m["hmx"] = {
	"Hmong-Mien",
	33322,
	aliases = {"Miao-Yao"},
}

m["hmx-mie"] = {
	"Mien",
	7992695,
	"hmx",
}

m["hok"] = {
	"Hokan",
	33406,
}

m["hyx"] = {
	"Armenian",
	8785,
	"ine",
}

m["iir"] = {
	"Indo-Iranian",
	33514,
	"ine",
}

m["iir-nur"] = {
	"Nuristani",
	161804,
	"iir",
}

m["nur-nor"] = {
	"Northern Nuristani",
	nil,
	"iir-nur",
}

m["nur-sou"] = {
	"Southern Nuristani",
	nil,
	"iir-nur",
}

m["ijo"] = {
	"Ijoid",
	1325759,
	"nic",
	otherNames = {"Ijaw"}, -- Ijaw may be a subfamily
}

m["inc"] = {
	"Indo-Aryan",
	33577,
	"iir",
	aliases = {"Indic"},
}

m["inc-bhi"] = {
	"Bhil",
	4901727,
	"inc-cen",
}

m["inc-cen"] = {
	"Central Indo-Aryan",
	10979187,
	"inc-psu",
}

m["inc-chi"] = {
	"Chitrali",
	11732797,
	"inc-dar",
}

m["inc-dar"] = {
	"Dardic",
	161101,
	"inc",
	protoLanguage = "sa",
}

m["inc-dre"] = {
	"Eastern Dardic",
	nil,
	"inc-dar",
}

m["inc-eas"] = {
	"Eastern Indo-Aryan",
	16590069,
	"inc",
	protoLanguage = "pra-mag",
}

m["inc-hie"] = {
	"Eastern Hindi",
	4126648,
	"inc",
	aliases = {"Purabiyā"},
	protoLanguage = "pra-ard",
}

m["inc-hiw"] = {
	"Western Hindi",
	12600937,
	"inc-cen",
	protoLanguage = "inc-sap",
}

m["inc-hnd"] = {
	"Hindustani",
	11051,
	"inc-hiw",
	aliases = {"Hindi-Urdu"},
	protoLanguage = "hi-mid",
}

m["inc-ins"] = {
	"Insular Indo-Aryan",
	12179302,
	"inc",
	protoLanguage = "pra-hel",
}

m["inc-kas"] = {
	"Kashmiric",
	nil,
	"inc-dre",
	aliases = {"Kashmiri"},
}

m["inc-koh"] = {
	"Kohistani",
	111971091,
	"inc-dre",
}

m["inc-kun"] = {
	"Kunar",
	nil,
	"inc-dar",
}

m["inc-mid"] = {
	"Middle Indo-Aryan",
	3236316,
	"inc",
	aliases = {"Middle Indic"},
}

m["inc-nwe"] = {
	"Northwestern Indo-Aryan",
	41355020,
	"inc-psu",
	protoLanguage = "pra-pai",
}

m["inc-nor"] = {
	"Northern Indo-Aryan",
	12642170,
	"inc",
	protoLanguage = "pra-kha",
}

m["inc-old"] = {
	"Old Indo-Aryan",
	118976896,
	"inc",
	aliases = {"Old Indic"},
}

m["inc-pah"] = {
	"Pahari",
	946077,
	"inc-nor",
	aliases = {"Pahadi"},
}

m["inc-pan"] = {
	"Punjabi-Lahnda",
	nil,
	"inc-nwe",
	protoLanguage = "inc-tak",
}

m["inc-pas"] = {
	"Pashayi",
	36670,
	"inc-dar",
	aliases = {"Pashai"},
}

m["inc-psu"] = {
	"Sauraseni Prakrit",
	2452885,
	"inc",
	aliases = {"Sauraseni", "Shauraseni"},
	protoLanguage = "pra-sau",
}

m["inc-rom"] = {
	"Romani",
	13201,
	"inc-psu",
	aliases = {"Romany", "Gypsy", "Gipsy"},
	protoLanguage = "rom",
}

m["inc-shn"] = {
	"Shinaic",
	12646125,
	"inc-dre",
}

m["inc-snd"] = {
	"Sindhi",
	7522212,
	"inc-nwe",
	protoLanguage = "inc-vra",
}

m["inc-sou"] = {
	"Southern Indo-Aryan",
	12179304,
	"inc",
	protoLanguage = "pra-mah",
}

m["inc-wes"] = {
	"Western Indo-Aryan",
	nil,
	"inc-psu",
	protoLanguage = "inc-gup",
}

m["ine"] = {
	"Indo-European",
	19860,
	aliases = {"Indo-Germanic"},
}

m["ine-ana"] = {
	"Anatolian",
	147085,
	"ine",
}

m["ine-bsl"] = {
	"Balto-Slavic",
	147356,
	"ine",
}

m["ine-toc"] = {
	"Tocharian",
	37029,
	"ine",
	aliases = {"Tokharian"},
}

m["ira"] = {
	"Iranian",
	33527,
	"iir",
}

m["ira-csp"] = {
	"Caspian",
	5049123,
	"ira-mpr",
}

m["ira-cen"] = {
	"Central Iranian",
	nil,
	"ira",
}

m["ira-kms"] = {
	"Komisenian",
	nil,
	"ira-mpr",
	aliases = {"Semnani"},
}

m["ine-luw"] = {
	"Luwic",
	115748615,
	"ine-ana",
	aliases = {"Luvic"},
}

m["ira-mny"] = {
	"Munji-Yidgha",
	nil,
	"ira-sym",
	aliases = {"Yidgha-Munji"},
}

m["ira-msh"] = {
	"Mazanderani-Shahmirzadi",
	nil,
	"ira-csp",
}

m["ira-nei"] = {
	"Northeastern Iranian",
	10775567,
	"ira",
}

m["ira-nwi"] = {
	"Northwestern Iranian",
	390576,
	"ira-wes",
}

m["ira-orp"] = {
	"Ormuri-Parachi",
	nil,
	"ira-sei",
}

m["ira-pat"] = {
	"Pathan",
	nil,
	"ira-sei",
}

m["ira-sbc"] = {
	"Sogdo-Bactrian",
	nil,
	"ira-nei",
}

m["ira-mpr"] = {
	"Medo-Parthian",
	nil,
	"ira-nwi",
	aliases = {"Partho-Median"},
}

m["ira-sgi"] = {
	"Sanglechi-Ishkashimi",
	18711232,
	"ira-sei",
}

m["ira-shy"] = {
	"Shughni-Yazghulami",
	nil,
	"ira-sym",
}

m["ira-sgc"] = {
	"Sogdic",
	nil,
	"ira-sbc",
	aliases = {"Sogdian"},
}

m["ira-sei"] = {
	"Southeastern Iranian",
	3833002,
	"ira",
}

m["ira-swi"] = {
	"Southwestern Iranian",
	390424,
	"ira-wes",
}

m["ira-sym"] = {
	"Shughni-Yazghulami-Munji",
	nil,
	"ira-sei",
}

m["ira-wes"] = {
	"Western Iranian",
	129850,
	"ira",
}

m["ira-zgr"] = {
	"Zaza-Gorani",
	167854,
	"ira-mpr",
	aliases = {"Zaza-Gurani", "Gorani-Zaza"},
}

m["iro"] = {
	"Iroquoian",
	33623,
}

m["iro-nor"] = {
	"North Iroquoian",
	nil,
	"iro",
}

m["itc"] = {
	"Italic",
	131848,
	"ine",
}

m["itc-sbl"] = {
	"Osco-Umbrian",
	515194,
	"itc",
	aliases = { "Sabellian" },
}

m["jpx"] = {
	"Japonic",
	33612,
	aliases = {"Japanese", "Japanese-Ryukyuan"},
}

m["jpx-ryu"] = {
	"Ryukyuan",
	56393,
	"jpx",
}

m["kar"] = {
	"Karen",
	1364815,
	"sit",
}

--[=[
	Exceptional language and family codes for Khoisan and Kordofanian languages can use
	the prefix "khi-" and "kdo-" respectively, though they are no longer family codes themselves.
]=]--

m["khi-kal"] = {
	"Kalahari Khoe",
	nil,
	"khi-kho",
}

m["khi-khk"] = {
	"Khoekhoe",
	nil,
	"khi-kho",
}

m["khi-kkw"] = {
	"Khoe-Kwadi",
	3833005,
	aliases = {"Kwadi-Khoe"},
}

m["khi-kho"] = {
	"Khoe",
	2736449,
	"khi-kkw",
	aliases = {"Central Khoisan"},
}

m["khi-kxa"] = {
	"Kx'a",
	6450587,
	aliases = {"Kxa", "Ju-ǂHoan"},
}

m["khi-tuu"] = {
	"Tuu",
	631046,
	aliases = {"Kwi", "Taa-Kwi", "Southern Khoisan", "Taa-ǃKwi", "Taa-ǃUi", "ǃUi-Taa"},
}

m["kro"] = {
	"Kru",
	33535,
	"nic-vco",
}

m["kro-aiz"] = {
	"Aizi",
	4699431,
	"kro",
}

m["kro-bet"] = {
	"Bété",
	32956,
	"kro-ekr",
}

m["kro-did"] = {
	"Dida",
	32685,
	"kro-ekr",
}

m["kro-ekr"] = {
	"Eastern Kru",
	5972899,
	"kro",
}

m["kro-grb"] = {
	"Grebo",
	5601537,
	"kro-wkr",
}

m["kro-wee"] = {
	"Wee",
	nil,
	"kro-wkr",
}

m["kro-wkr"] = {
	"Western Kru",
	5972897,
	"kro",
}

m["ku"] = {
	"Kurdish",
	36368,
	"ira-nwi",
}

m["map"] = {
	"Austronesian",
	49228,
}

m["map-ata"] = {
	"Atayalic",
	716610,
	"map",
}

m["mjg"] = {
	"Monguor",
	34214,
	"xgn-shr",
}

m["mkh"] = {
	"Mon-Khmer",
	33199,
	"aav",
}

m["mkh-asl"] = {
	"Aslian",
	3111082,
	"mkh",
}

m["mkh-ban"] = {
	"Bahnaric",
	56309,
	"mkh",
}

m["mkh-kat"] = {
	"Katuic",
	56697,
	"mkh",
}

m["mkh-khm"] = {
	"Khmuic",
	1323245,
	"mkh",
}

m["mkh-kmr"] = {
	"Khmeric",
	nil,
	"mkh",
}

m["mkh-mnc"] = {
	"Monic",
	3217497,
	"mkh",
}

m["mkh-mng"] = {
	"Mangic",
	3509556,
	"mkh",
}

m["mkh-nbn"] = {
	"North Bahnaric",
	56309,
	"mkh-ban",
}

m["mkh-pal"] = {
	"Palaungic",
	2391173,
	"mkh",
}

m["mkh-pea"] = {
	"Pearic",
	3073022,
	"mkh",
}

m["mkh-pkn"] = {
	"Pakanic",
	nil,
	"mkh-mng",
}

m["mkh-vie"] = {
	"Vietic",
	2355546,
	"mkh",
}

m["mno"] = {
	"Manobo",
	3217483,
	"phi",
}

m["mun"] = {
	"Munda",
	33892,
	"aav",
}

m["myn"] = {
	"Mayan",
	33738,
}

--[=[
	Exceptional language and family codes for North American Indian languages
	can use the prefix "nai-", though "nai" is no longer itself a family code.
]=]--
m["nai-cat"] = {
	"Catawban",
	3446638,
	"nai-sca",
}

m["nai-chu"] = {
	"Chumashan",
	1288420,
}

m["nai-ckn"] = {
	"Chinookan",
	610586,
}

m["nai-coo"] = {
	"Coosan",
	940278,
}

m["nai-jcq"] = {
	"Jicaquean",
	12179308,
	"hok"
	
}

m["nai-ker"] = {
	"Keresan",
	35878,
}

m["nai-klp"] = {
	"Kalapuyan",
	1569040,
}

m["nai-kta"] = {
	"Kiowa-Tanoan",
	386288,
}

m["nai-len"] = {
	"Lencan",
	36189,
	aliases = {"Lenca"},
}

m["nai-mdu"] = {
	"Maiduan",
	33502,
}

m["nai-miz"] = {
	"Mixe-Zoquean",
	954016,
	aliases = {"Mixe-Zoque"},
}

m["nai-min"] = {
	"Misumalpan",
	281693,
	"qfa-mch",
	aliases = {"Misuluan", "Misumalpa"},
}

m["nai-mus"] = {
	"Muskogean",
	902978,
	aliases = {"Muskhogean"},
}

m["nai-pak"] = {
	"Pakawan",
	65085487,
	"hok",
}

m["nai-pal"] = {
	"Palaihnihan",
	1288332,
}

m["nai-plp"] = {
	"Plateau Penutian",
	2307476,
}

m["nai-pom"] = {
	"Pomoan",
	2618420,
	"hok",
	aliases = {"Pomo", "Kulanapan"},
}

m["nai-sca"] = {
	"Siouan-Catawban",
	34181,
}

m["nai-shp"] = {
	"Sahaptian",
	114782,
	"nai-plp",
}

m["nai-shs"] = {
	"Shastan",
	2991735,
	"hok",
}

m["nai-tot"] = {
	"Totozoquean",
	7828419,
}

m["nai-ttn"] = {
	"Totonacan",
	34039,
	aliases = {"Totonac-Tepehua", "Totonacan-Tepehuan"},
	varieties = {"Totonac"},
}

m["nai-tqn"] = {
	"Tequistlatecan",
	1754988,
	"hok",
	aliases = {"Tequistlatec", "Chontal", "Chontalan", "Oaxacan Chontal", "Chontal of Oaxaca"},
}

m["nai-tsi"] = {
	"Tsimshianic",
	34134,
}

m["nai-utn"] = {
	"Utian",
	13371763,
	"nai-you",
	aliases = {"Miwok-Costanoan", "Mutsun"},
}

m["nai-wtq"] = {
	"Wintuan",
	1294259,
	aliases = {"Wintun"},
}

m["nai-xin"] = {
	"Xincan",
	1546494,
	aliases = {"Xinca"},
}

m["nai-ykn"] = {
	"Yukian",
	2406722,
	aliases = {"Yuki-Wappo"},
}

m["nai-yok"] = {
	"Yokutsan",
	34249,
	"nai-you",
	aliases = {"Yokuts", "Mariposan", "Mariposa"},
}

m["nai-you"] = {
	"Yok-Utian",
	2886186,
}

m["nai-yuc"] = {
	"Yuman-Cochimí",
	579137,
}

m["ngf"] = {
	"Trans-New Guinea",
	34018,
}

m["ngf-fin"] = {
	"Finisterre",
	5450373,
	"ngf",
}

m["ngf-mad"] = {
	"Madang",
	11217556,
	"ngf",
}

m["ngf-okk"] = {
	"Ok",
	7081687,
	"ngf",
}

m["ngf-sbh"] = {
	"South Bird's Head",
	7566330,
	"ngf",
}

m["nic"] = {
	"Niger-Congo",
	33838,
	aliases = {"Niger-Kordofanian"},
}

m["nic-alu"] = {
	"Alumic",
	4737355,
	"nic-plt",
}

m["nic-bas"] = {
	"Basa",
	4866154,
	"nic-knj",
}

m["nic-bbe"] = {
	"Eastern Beboid",
	nil,
	"nic-beb",
}

m["nic-bco"] = {
	"Benue-Congo",
	33253,
	"nic-vco",
}

m["nic-bcr"] = {
	"Bantoid-Cross",
	806983,
	"nic-bco",
}

m["nic-bdn"] = {
	"Northern Bantoid",
	nil,
	"nic-bod",
	aliases = {"North Bantoid"},
}

m["nic-bds"] = {
	"Southern Bantoid",
	3183152,
	"nic-bod",
	aliases = {"Wide Bantu", "Bin"},
}

m["nic-beb"] = {
	"Beboid",
	813549,
	"nic-bds",
}

m["nic-ben"] = {
	"Bendi",
	4887065,
	"nic-bcr",
}

m["nic-beo"] = {
	"Beromic",
	4894642,
	"nic-plt",
}

m["nic-bod"] = {
	"Bantoid",
	806992,
	"nic-bcr",
}

m["nic-buk"] = {
	"Buli-Koma",
	nil,
	"nic-ovo",
}

m["nic-bwa"] = {
	"Bwa",
	12628562,
	"nic-gur",
	otherNames = {"Bwamu", "Bomu"},
}

m["nic-cde"] = {
	"Central Delta",
	3813191,
	"nic-cri",
}

m["nic-cri"] = {
	"Cross River",
	1141096,
	"nic-bcr",
}

m["nic-dag"] = {
	"Dagbani",
	nil,
	"nic-wov",
}

m["nic-dak"] = {
	"Dakoid",
	1157745,
	"nic-bdn",
}

m["nic-dge"] = {
	"Escarpment Dogon",
	5397128,
	"qfa-dgn",
}

m["nic-dgw"] = {
	"West Dogon",
	nil,
	"qfa-dgn",
}

m["nic-eko"] = {
	"Ekoid",
	1323395,
	"nic-bds",
}

m["nic-eov"] = {
	"Eastern Oti-Volta",
	nil,
	"nic-ovo",
	aliases = {"Samba"},
}

m["nic-fru"] = {
	"Furu",
	5509783,
	"nic-bds",
}

m["nic-gne"] = {
	"Eastern Gurunsi",
	12633072,
	"nic-gns",
	aliases = {"Eastern Grũsi"},
}

m["nic-gnn"] = {
	"Northern Gurunsi",
	nil,
	"nic-gns",
	aliases = {"Northern Grũsi"},
}

m["nic-gnw"] = {
	"Western Gurunsi",
	nil,
	"nic-gns",
	aliases = {"Western Grũsi"},
}

m["nic-gns"] = {
	"Gurunsi",
	721007,
	"nic-gur",
	aliases = {"Grũsi"},
}

m["nic-gre"] = {
	"Eastern Grassfields",
	5330160,
	"nic-grf",
}

m["nic-grf"] = {
	"Grassfields",
	750932,
	"nic-bds",
	aliases = {"Grassfields Bantu", "Wide Grassfields"},
}

m["nic-grm"] = {
	"Gurma",
	30587833,
	"nic-ovo",
}

m["nic-grs"] = {
	"Southwest Grassfields",
	7571285,
	"nic-grf",
}

m["nic-gur"] = {
	"Gur",
	33536,
	"alv-sav",
	aliases = {"Voltaic"},
}

m["nic-ief"] = {
	"Ibibio-Efik",
	2743643,
	"nic-lcr",
}

m["nic-jer"] = {
	"Jera",
	nil,
	"nic-kne",
}

m["nic-jkn"] = {
	"Jukunoid",
	1711622,
	"nic-pla",
}

m["nic-jrn"] = {
	"Jarawan",
	1683430,
	"nic-mba",
}

m["nic-jrw"] = {
	"Jarawa",
	35423,
	"nic-jrn",
}

m["nic-kam"] = {
	"Kambari",
	6356294,
	"nic-knj",
}

m["nic-ktl"] = {
	"Katloid",
	nil,
	"nic",
}

m["nic-kau"] = {
	"Kauru",
	nil,
	"nic-kne",
}

m["nic-kmk"] = {
	"Kamuku",
	6359821,
	"nic-knj",
}

m["nic-kne"] = {
	"East Kainji",
	5328687,
	"nic-knj",
}

m["nic-knj"] = {
	"Kainji",
	681495,
	"nic-pla",
}

m["nic-knn"] = {
	"Northwest Kainji",
	7060098,
	"nic-knj",
}

m["nic-ktl"] = {
	"Katloid",
	6377681,
	"nic",
	aliases = {"Katla", "Katla-Tima"},
}

m["nic-lcr"] = {
	"Lower Cross River",
	3813193,
	"nic-cri",
}

m["nic-mam"] = {
	"Mamfe",
	2005898,
	"nic-bds",
	aliases = {"Nyang"},
}

m["nic-mba"] = {
	"Mbam",
	687826,
	"nic-bds",
}

m["nic-mbc"] = {
	"Mba",
	6799561,
	"nic-ubg",
}

m["nic-mbw"] = {
	"West Mbam",
	nil,
	"nic-mba",
}

m["nic-mmb"] = {
	"Mambiloid",
	1888151,
	otherNames = {"North Bantoid"}, -- per Wikipedia, North Bantoid is the parent family
	"nic-bdn",
}

m["nic-mom"] = {
	"Momo",
	6897393,
	"nic-grf",
}

m["nic-mre"] = {
	"Moré",
	nil,
	"nic-wov",
}

m["nic-ngd"] = {
	"Ngbandi",
	36439,
	"nic-ubg",
}

m["nic-nge"] = {
	"Ngemba",
	7022271,
	"nic-gre",
}

m["nic-ngk"] = {
	"Ngbaka",
	3217499,
	"nic-ubg",
}

m["nic-nin"] = {
	"Ninzic",
	7039282,
	"nic-plt",
}

m["nic-nka"] = {
	"Nkambe",
	7042520,
	"nic-gre",
}

m["nic-nkb"] = {
	"Baka",
	nil,
	"nic-nkw",
}

m["nic-nke"] = {
	"Eastern Ngbaka",
	nil,
	"nic-ngk",
}

m["nic-nkg"] = {
	"Gbanziri",
	nil,
	"nic-nkw",
}

m["nic-nkk"] = {
	"Kpala",
	nil,
	"nic-nkw",
}

m["nic-nkm"] = {
	"Mbaka",
	nil,
	"nic-nkw",
}

m["nic-nkw"] = {
	"Western Ngbaka",
	nil,
	"nic-ngk",
}

m["nic-npd"] = {
	"North Plateau Dogon",
	nil,
	"qfa-dgn",
}

m["nic-nun"] = {
	"Nun",
	13654297,
	"nic-gre",
}

m["nic-nwa"] = {
	"Nanga-Walo",
	nil,
	"qfa-dgn",
}

m["nic-ogo"] = {
	"Ogoni",
	2350726,
	"nic-cri",
	aliases = {"Ogonoid"},
}

m["nic-ovo"] = {
	"Oti-Volta",
	1157178,
	"nic-gur",
}

m["nic-pla"] = {
	"Platoid",
	453244,
	"nic-bco",
	aliases = {"Central Nigerian"},
}

m["nic-plc"] = {
	"Central Plateau",
	5061668,
	"nic-plt",
}

m["nic-pld"] = {
	"Plains Dogon",
	nil,
	"qfa-dgn",
}

m["nic-ple"] = {
	"East Plateau",
	5329154,
	"nic-plt",
}

m["nic-pls"] = {
	"South Plateau",
	7568236,
	"nic-plt",
	aliases = {"Jilic-Eggonic"},
}

m["nic-plt"] = {
	"Plateau",
	1267471,
	"nic-pla",
}

m["nic-ras"] = {
	"Rashad",
	3401986,
	"nic",
}

m["nic-rnc"] = {
	"Central Ring",
	nil,
	"nic-rng",
}

m["nic-rng"] = {
	"Ring",
	2269051,
	"nic-grf",
	aliases = {"Ring Road"},
}

m["nic-rnn"] = {
	"Northern Ring",
	nil,
	"nic-rng",
}

m["nic-rnw"] = {
	"Western Ring",
	nil,
	"nic-rng",
}

m["nic-ser"] = {
	"Sere",
	7453058,
	"nic-ubg",
}

m["nic-shi"] = {
	"Shiroro",
	7498953,
	"nic-knj",
	aliases = {"Pongu"},
}

m["nic-sis"] = {
	"Sisaala",
	36532,
	"nic-gnw",
}

m["nic-tar"] = {
	"Tarokoid",
	2394472,
	"nic-plt",
}

m["nic-tiv"] = {
	"Tivoid",
	752377,
	"nic-bds",
}

m["nic-tvc"] = {
	"Central Tivoid",
	nil,
	"nic-tiv",
}

m["nic-tvn"] = {
	"Northern Tivoid",
	nil,
	"nic-tiv",
}

m["nic-ubg"] = {
	"Ubangian",
	33932,
	"nic-vco", -- or none
}

m["nic-uce"] = {
	"East-West Upper Cross River",
	nil,
	"nic-ucr",
}

m["nic-ucn"] = {
	"North-South Upper Cross River",
	nil,
	"nic-ucr",
}

m["nic-ucr"] = {
	"Upper Cross River",
	4108624,
	"nic-cri",
	aliases = {"Upper Cross"},
}

m["nic-vco"] = {
	"Volta-Congo",
	37228,
	"alv",
}

m["nic-wov"] = {
	"Western Oti-Volta",
	nil,
	"nic-ovo",
	aliases = {"Moré-Dagbani"}
}

m["nic-ykb"] = {
	"Yukubenic",
	16909196,
	"nic-plt",
	aliases = {"Oohum"},
}

m["nic-ymb"] = {
	"Yambasa",
	nil,
	"nic-mba",
}

m["nic-yon"] = {
	"Yom-Nawdm",
	nil,
	"nic-ovo",
	aliases = {"Moré-Dagbani"}
}

m["nub"] = {
	"Nubian",
	1517194,
	"sdv-nes",
}

m["nub-hil"] = {
	"Hill Nubian",
	5762211,
	"nub",
	aliases = {"Kordofan Nubian"},
}

m["omq"] = {
	"Oto-Manguean",
	33669,
}

m["omq-cha"] = {
	"Chatino",
	35111,
	"omq-zap",
}

m["omq-chi"] = {
	"Chinantecan",
	35828,
	"omq",
}

m["omq-cui"] = {
	"Cuicatec",
	616024,
	"omq-mix",
}

m["omq-maz"] = {
	"Mazatecan",
	36230,
	"omq",
	aliases = {"Mazatec"},
}

m["omq-mix"] = {
	"Mixtecan",
	21996392,
	"omq",
}

m["omq-mxt"] = {
	"Mixtec",
	36363,
	"omq-mix",
}

m["omq-otp"] = {
	"Oto-Pamean",
	nil,
	"omq",
}

m["omq-pop"] = {
	"Popolocan",
	5132273,
	"omq",
}

m["omq-tri"] = {
	"Trique",
	780200,
	"omq-mix",
	aliases = {"Triqui"},
}

m["omq-zap"] = {
	"Zapotecan",
	8066463,
	"omq",
}

m["omq-zpc"] = {
	"Zapotec",
	13214,
	"omq-zap",
}

m["omv"] = {
	"Omotic",
	33860,
	"afa",
}

m["omv-aro"] = {
	"Aroid",
	3699526,
	"omv",
	aliases = {"Ari-Banna", "South Omotic", "Somotic"},
}

m["omv-diz"] = {
	"Dizoid",
	430251,
	"omv",
	aliases = {"Maji", "Majoid"},
}

m["omv-eom"] = {
	"East Ometo",
	20527288,
	"omv-ome",
}

m["omv-gon"] = {
	"Gonga",
	4143043,
	"omv",
	aliases = {"Kefoid"},
}

m["omv-mao"] = {
	"Mao",
	1351495,
	"omv",
}

m["omv-nom"] = {
	"North Ometo",
	nil,
	"omv-ome",
}

m["omv-ome"] = {
	"Ometo",
	36310,
	"omv",
}

m["oto"] = {
	"Otomian",
	1270220,
	"omq-otp",
}

m["oto-otm"] = {
	"Otomi",
	nil,
	"oto",
}

m["paa"] = {
	"Papuan",
	236425,
	"qfa-not",
}

m["paa-arf"] = {
	"Arafundi",
	4783702,
}

m["paa-asa"] = {
	"Arai-Samaia",
	48803569,
}

m["paa-bng"] = {
	"Baining",
	748487,
	aliases = {"East New Britain"},
}

m["paa-brd"] = {
	"Border",
	1752158,
	aliases = {"Upper Tami"},
}

m["paa-egb"] = {
	"East Geelvink Bay",
	1497678,
	aliases = {"East Cenderawasih"},
}

m["paa-eng"] = {
	"Engan",
	3217449,
}

m["paa-iwm"] = {
	"Iwam",
	15147853,
}

m["paa-kag"] = { -- recode as ngf-kag?
	"Kainantu-Goroka",
	3217463,
	"ngf",
}

m["paa-kiw"] = {
	"Kiwaian",
	338449,
}

m["paa-kut"] = {
	"Kutubuan",
	48767893,
	"paa-pag",
}

m["paa-kwm"] = {
	"Kwomtari",
	2075415,
}

m["paa-lkp"] = {
	"Lakes Plain",
	6478969,
}

m["paa-lsp"] = {
	"Lower Sepik",
	7061700,
	aliases = {"Nor-Pondo"},
}

m["paa-mai"] = {
	"Mairasi",
	6736896,
}

m["paa-msk"] = {
	"Sko",
	953509,
	aliases = {"Skou"},
}

m["paa-nbo"] = {
	"North Bougainville",
	749496,
}

m["paa-nim"] = {
	"Nimboran",
	12638426,
}

m["paa-nha"] = {
	"North Halmahera",
	nil,
	"paa-wpa",
}

m["paa-pag"] = {
	"Papuan Gulf",
	48803685,
}

m["paa-pau"] = {
	"Pauwasi",
	7155496,
}

m["paa-ram"] = {
	"Ramu",
	3442808,
}

m["paa-sbo"] = {
	"South Bougainville",
	3217380,
}

m["paa-sen"] = {
	"Sentani",
	17044584,
	"paa-wpa",
}

m["paa-spk"] = {
	"Sepik",
	3508772,
}

m["paa-tkw"] = {
	"Tor-Kwerba",
	7827523,
}

m["paa-wpa"] = {
	"West Papuan",
	1363026,
}

m["paa-yam"] = {
	"Yam",
	15062272,
	aliases = {"Morehead and Upper Maro River"},
}

m["paa-yua"] = {
	"Yuat",
	8060096,
}

m["phi"] = {
	"Philippine",
	947858,
	"poz-bop",
}

m["phi-kal"] = {
	"Kalamian",
	3217466,
	"phi",
	aliases = {"Calamian"},
}

m["poz"] = {
	"Malayo-Polynesian",
	143158,
	"map",
}

m["poz-aay"] = {
	"Admiralty Islands",
	2701306,
	"poz-oce",
}

m["poz-bnn"] = {
	"North Bornean",
	1427907,
	"poz-bop",
}

m["poz-bop"] = {
	"Borneo-Philippines",
	4273393,
	"poz",
}

m["poz-bre"] = {
	"East Barito",
	2701314,
	"poz-bop",
}

m["poz-brw"] = {
	"West Barito",
	2761679,
	"poz-bop",
}

m["poz-btk"] = {
	"Bungku-Tolaki",
	3217381,
	"poz-clb",
}

m["poz-cet"] = {
	"Central-Eastern Malayo-Polynesian",
	2269883,
	"poz",
}

m["poz-clb"] = {
	"Celebic",
	1078041,
	"poz-sus",
}

m["poz-cln"] = {
	"New Caledonian",
	3091221,
	"poz-occ",
}

m["poz-cma"] = {
	"Central Maluku",
	3217479,
	"poz-cet",
}

m["poz-hce"] = {
	"Halmahera-Cenderawasih",
	2526616,
	"pqe",
}

m["poz-kal"] = {
	"Kaili-Pamona",
	3217465,
	"poz-clb",
}

m["poz-lgx"] = {
	"Lampungic",
	49215,
	"poz-sus",
}

m["poz-mcm"] = {
	"Malayo-Chamic",
	nil,
	"poz-msa",
}

m["poz-mic"] = {
	"Micronesian",
	420591,
	"poz-occ",
}

m["poz-mly"] = {
	"Malayic",
	662628,
	"poz-mcm",
}

m["poz-msa"] = {
	"Malayo-Sumbawan",
	1363818,
	"poz-sus",
}

m["poz-mun"] = {
	"Muna-Buton",
	3037924,
	"poz-clb",
}

m["poz-nws"] = {
	"Northwest Sumatran",
	2071308,
	"poz-sus",
}

m["poz-occ"] = {
	"Central-Eastern Oceanic",
	2068435,
	"poz-oce",
}

m["poz-oce"] = {
	"Oceanic",
	324457,
	"pqe",
}

m["poz-ocw"] = {
	"Western Oceanic",
	2701282,
	"poz-oce",
}

m["poz-pep"] = {
	"Eastern Polynesian",
	390979,
	"poz-pnp",
}

m["poz-pnp"] = {
	"Nuclear Polynesian",
	743851,
	"poz-pol",
}

m["poz-pol"] = {
	"Polynesian",
	390979,
	"poz-occ",
}

m["poz-san"] = {
	"Sabahan",
	3217517,
	"poz-bnn",
}

m["poz-sbj"] = {
	"Sama-Bajaw",
	2160409,
	"poz-bop",
}

m["poz-slb"] = {
	"Saluan-Banggai",
	3217519,
	"poz-clb",
}

m["poz-sls"] = {
	"Southeast Solomonic",
	3119671,
	"poz-occ",
}

m["poz-ssw"] = {
	"South Sulawesi",
	2778190,
	"poz-sus",
}

m["poz-sus"] = {
	"Sunda-Sulawesi",
	319552,
	"poz",
}

m["poz-swa"] = {
	"North Sarawakan",
	538569,
	"poz-bnn",
}

m["poz-tim"] = {
	"Timoric",
	7806987,
	"poz-cet",
}

m["poz-tot"] = {
	"Tomini-Tolitoli",
	3217541,
	"poz-clb",
}

m["poz-vnc"] = {
	"North-Central Vanuatu",
	3039118,
	"poz-occ",
}

m["poz-wot"] = {
	"Wotu-Wolio",
	1041317,
	"poz-clb",
}

m["pqe"] = {
	"Eastern Malayo-Polynesian",
	2269883,
	"poz-cet",
}

m["pra"] = {
	"Prakrit",
	192170,
	"inc",
	aliases = {"Prakritic"},
	protoLanguage = "inc-pra",
}

m["qfa-adc"] = {
	"Central Great Andamanese",
	nil,
	"qfa-adm",
}

m["qfa-adm"] = {
	"Great Andamanese",
	3515103,
}

m["qfa-adn"] = {
	"Northern Great Andamanese",
	nil,
	"qfa-adm",
}

m["qfa-ads"] = {
	"Southern Great Andamanese",
	nil,
	"qfa-adm",
}

m["qfa-bet"] = {
	"Be-Tai",
	nil,
	"qfa-tak",
	aliases = {"Tai-Be", "Daic-Beic", "Beic-Daic"},
}

m["qfa-buy"] = {
	"Buyang",
	1109927,
	"qfa-kra",
}

m["qfa-cka"] = {
	"Chukotko-Kamchatkan",
	33255,
}

m["qfa-ckn"] = {
	"Chukotkan",
	2606732,
	"qfa-cka",
}

m["qfa-dgn"] = {
	"Dogon",
	1234776,
	"nic",
}

m["qfa-dny"] = {
	"Dene-Yeniseian",
	21103,
	aliases = {"Dené-Yeniseian"},
}

m["qfa-gel"] = {
	"Gelao",
	56401,
	"qfa-kra",
}

m["qfa-hur"] = {
	"Hurro-Urartian",
	1144159,
}

m["qfa-iso"] = {
	"isolate",
	33648,
	"qfa-not",
}

m["qfa-kad"] = {
	"Kadu", -- considered either Nilo-Saharan or independent/none
	1720989,
}

m["qfa-kms"] = {
	"Kam-Sui",
	1023641,
	"qfa-tak",
}

m["qfa-kor"] = {
	"Koreanic",
	11263525,
}

m["qfa-kra"] = {
	"Kra",
	1022087,
	"qfa-tak",
}

m["qfa-lic"] = {
	"Hlai",
	1023648,
	"qfa-tak",
	aliases = {"Hlaic"},
}

m["qfa-mal"] = {
	"Left May",
	614468,
	"paa-asa",
}

m["qfa-mch"] = { -- used in both N and S America
	"Macro-Chibchan",
	3438062,
}

m["qfa-mix"] = {
	"mixed",
	33694,
	"qfa-not",
}

m["qfa-not"] = {
	"not a family",
	nil,
	"qfa-not",
}

m["qfa-onb"] = {
	"Be",
	nil,
	"qfa-bet",
	aliases = {"Ong-Be", "Beic"},
}

m["qfa-ong"] = {
	"Ongan",
	2090575,
	aliases = {"Angan", "South Andamanese", "Jarawa-Onge"},
}

m["qfa-sub"] = {
	"substrate",
	20730913,
}

m["qfa-tak"] = {
	"Kra-Dai",
	34171,
	aliases = {"Tai-Kadai", "Kadai"},
}

m["qfa-tap"] = {
	"Timor-Alor-Pantar",
	16590002,
}

m["qfa-tor"] = {
	"Torricelli",
	1333831,
}

m["qfa-tyn"] = {
	"Tyrsenian",
	1344038,
}

m["qfa-xgs"] = {
	"Serbi-Mongolic",
	108887939,
}

m["qfa-xgx"] = {
	"Para-Mongolic",
	107619002,
	"qfa-xgs",
}

m["qfa-yen"] = {
	"Yeniseian",
	27639,
	"qfa-dny",
	aliases = {"Yeniseic", "Yenisei-Ostyak"},
}

m["qfa-yno"] = {
	"Northern Yeniseian",
	nil,
	"qfa-yen",
}

m["qfa-yso"] = {
	"Southern Yeniseian",
	nil,
	"qfa-yen",
}

m["qfa-yuk"] = {
	"Yukaghir",
	34164,
	aliases = {"Yukagir", "Jukagir"},
}

m["qwe"] = {
	"Quechuan",
	5218,
}

m["roa"] = {
	"Romance",
	19814,
	"itc",
	aliases = {"Romanic", "Latin", "Neolatin", "Neo-Latin"},
	protoLanguage = "la",
}

m["roa-eas"] = {
	"Eastern Romance",
	147576,
	"roa",
}

m["roa-ibe"] = {
	"West Iberian",
	1377152,
	"roa",
}

m["roa-itd"] = {
	"Italo-Dalmatian",
	3313381,
	"roa",
}

m["roa-git"] = {
	"Gallo-Italic",
	516074,
	"roa",
}

m["roa-oil"] = {
	"Oïl",
	37351,
	"roa",
	protoLanguage = "fro",
}

m["roa-ocr"] = {
	"Occitano-Romance",
	599958,
	"roa",
}

m["roa-rhe"] = {
	"Rhaeto-Romance",
	515593,
	"roa",
}

--[=[
	Exceptional language and family codes for South American Indian languages
	can use the prefix "sai-", though "sai" is no longer itself a family code.
]=]--
m["sai-ara"] = {
	"Araucanian",
	626630,
}

m["sai-aym"] = {
	"Aymaran",
	33010,
}

m["sai-bar"] = {
	"Barbacoan",
	807304,
	aliases = {"Barbakoan"},
}

m["sai-bor"] = {
	"Boran",
	43079266,
}

m["sai-cah"] = {
	"Cahuapanan",
	1025793,
}

m["sai-car"] = {
	"Cariban",
	33090,
	aliases = {"Carib"},
}

m["sai-cer"] = {
	"Cerrado",
	98078151,
	"sai-jee",
	aliases = {"Amazonian Jê"},
}

m["sai-chc"] = {
	"Chocoan",
	1075616,
	aliases = {"Choco", "Chocó"},
}

m["sai-cho"] = {
	"Chonan",
	33019,
	aliases = {"Chon"},
}

m["sai-cje"] = {
	"Central Jê",
	18010843,
	"sai-cer",
	aliases = {"Akuwẽ"},
}

m["sai-cpc"] = {
	"Chapacuran",
	1062626,
}

m["sai-crn"] = {
	"Charruan",
	3112423,
	aliases = {"Charrúan"},
}

m["sai-ctc"] = {
	"Catacaoan",
	5051139,
}

m["sai-guc"] = {
	"Guaicuruan",
	1974973,
	"sai-mgc",
	aliases = {"Guaicurú", "Guaycuruana", "Guaikurú", "Guaycuruano", "Guaykuruan", "Waikurúan"},
}

m["sai-guh"] = {
	"Guahiban",
	944056,
	aliases = {"Guahiboan", "Guajiboan", "Wahivoan"},
}

m["sai-gui"] = {
	"Guianan",
	nil,
	"sai-car",
	aliases = {"Guianan Carib", "Guiana Carib"},
}

m["sai-har"] = {
	"Harákmbut",
	1584402,
	"sai-hkt",
	aliases = {"Harákmbet"},
}

m["sai-hkt"] = {
	"Harákmbut-Katukinan",
	17107635,
}

m["sai-hrp"] = {
	"Huarpean",
	1578336,
	aliases = {"Warpean", "Huarpe", "Warpe"},
}

m["sai-jee"] = {
	"Jê",
	1483594,
	"sai-mje",
	aliases = {"Gê", "Jean", "Gean", "Jê-Kaingang", "Ye"},
}

m["sai-jir"] = {
	"Jirajaran",
	3028651,
	aliases = {"Hiraháran"},
}

m["sai-jiv"] = {
	"Jivaroan",
	1393074,
	aliases = {"Hívaro", "Jibaro", "Jibaroan", "Jibaroana", "Jívaro"},
}

m["sai-ktk"] = {
	"Katukinan",
	2636000,
	"sai-hkt",
	aliases = {"Catuquinan"},
}

m["sai-kui"] = {
	"Kuikuroan",
	nil,
	"sai-car",
	aliases = {"Kuikuro", "Nahukwa"},
}

m["sai-map"] = {
	"Mapoyan",
	61096301,
	"sai-ven",
	aliases = {"Mapoyo", "Mapoyo-Yabarana", "Mapoyo-Yavarana", "Mapoyo-Yawarana"},
}

m["sai-mas"] = {
	"Mascoian",
	1906952,
	aliases = {"Mascoyan", "Maskoian", "Enlhet-Enenlhet"},
}

m["sai-mgc"] = {
	"Mataco-Guaicuru",
	255512,
}

m["sai-mje"] = {
	"Macro-Jê",
	887133,
	aliases = {"Macro-Gê"},
}

m["sai-mtc"] = {
	"Matacoan",
	2447424,
	"sai-mgc",
}

m["sai-mur"] = {
	"Muran",
	33826,
	aliases = {"Mura"},
}

m["sai-nad"] = {
	"Nadahup",
	1856439,
	aliases = {"Makú", "Macú", "Vaupés-Japurá"},
}

m["sai-nje"] = {
	"Northern Jê",
	98078225,
	"sai-cer",
	aliases = {"Core Jê"},
}

m["sai-nmk"] = {
	"Nambikwaran",
	15548027,
	aliases = {"Nambicuaran", "Nambiquaran", "Nambikuaran"},
}

m["sai-otm"] = {
	"Otomacoan",
	3217503,
	aliases = {"Otomákoan", "Otomakoan"},
}

m["sai-pan"] = {
	"Panoan",
	1544537,
	"sai-pat",
	aliases = {"Pano"},
}

m["sai-pat"] = {
	"Pano-Tacanan",
	2475746,
	aliases = {"Pano-Tacana", "Pano-Takana", "Páno-Takána", "Pano-Takánan"},
}

m["sai-pek"] = {
	"Pekodian",
	107451736,
	"sai-car",
	aliases = {"South Amazonian Carib", "Southern Cariban", "Pekodi"},
}

m["sai-pem"] = {
	"Pemongan",
	nil,
	"sai-ven",
	aliases = {"Pemong", "Pemóng", "Purukoto"},
}

m["sai-prk"] = {
	"Parukotoan",
	107451482,
	"sai-car",
	aliases = {"Parukoto"},
}

m["sai-sje"] = {
	"Southern Jê",
	98078245,
	"sai-jee",
}

m["sai-tac"] = {
	"Tacanan",
	3113762,
	"sai-pat",
}

m["sai-tar"] = {
	"Taranoan",
	105097814,
	"sai-gui",
	aliases = {"Trio", "Tarano"},
}

m["sai-tuc"] = {
	"Tucanoan",
	788144,
}

m["sai-tyu"] = {
	"Ticuna-Yuri",
	4467010,
}

m["sai-ucp"] = {
	"Uru-Chipaya",
	2475488,
	aliases = {"Uru-Chipayan"},
}

m["sai-ven"] = {
	"Venezuelan Cariban",
	nil,
	"sai-car",
	aliases = {"Venezuelan Carib", "Venezuelan", "Venezuelano"},
}

m["sai-wic"] = {
	"Wichí",
	3027047,
}

m["sai-wit"] = {
	"Witotoan",
	43079317,
	aliases = {"Huitotoan", "Uitotoan"},
}

m["sai-ynm"] = {
	"Yanomami",
	nil,
	aliases = {"Yanomam", "Shamatari", "Yamomami", "Yanomaman"},
}

m["sai-yuk"] = {
	"Yukpan",
	nil,
	"sai-car",
	aliases = {"Yukpa", "Yukpano", "Yukpa-Japreria"},
}

m["sai-zam"] = {
	"Zamucoan",
	3048461,
	aliases = {"Samúkoan"},
}

m["sai-zap"] = {
	"Zaparoan",
	33911,
	aliases = {"Záparoan", "Saparoan", "Sáparoan", "Záparo", "Zaparoano", "Zaparoana"},
}

m["sal"] = {
	"Salishan",
	33985,
}

m["sdv"] = {
	"Eastern Sudanic",
	2036148,
	"ssa",
}

m["sdv-bri"] = {
	"Bari",
	nil,
	"sdv-nie",
}

m["sdv-daj"] = {
	"Daju",
	956724,
	"sdv",
}

m["sdv-dnu"] = {
	"Dinka-Nuer",
	nil,
	"sdv-niw",
}

m["sdv-eje"] = {
	"Eastern Jebel",
	3408878,
	"sdv",
}

m["sdv-kln"] = {
	"Kalenjin",
	637228,
	"sdv-nis",
}

m["sdv-lma"] = {
	"Lotuko-Maa",
	nil,
	"sdv-nie",
}

m["sdv-lon"] = {
	"Northern Luo",
	nil,
	"sdv-luo",
}

m["sdv-los"] = {
	"Southern Luo",
	7570103,
	"sdv-luo",
}

m["sdv-luo"] = {
	"Luo",
	nil,
	"sdv-niw",
}

m["sdv-nes"] = {
	"Northern Eastern Sudanic",
	4810496,
	"sdv",
	aliases = {"Astaboran", "Ek Sudanic"},
}

m["sdv-nie"] = {
	"Eastern Nilotic",
	153795,
	"sdv-nil",
}

m["sdv-nil"] = {
	"Nilotic",
	513408,
	"sdv",
}

m["sdv-nis"] = {
	"Southern Nilotic",
	1552410,
	"sdv-nil",
}

m["sdv-niw"] = {
	"Western Nilotic",
	3114989,
	"sdv-nil",
}

m["sdv-nma"] = {
	"Nandi-Markweta",
	nil,
	"sdv-kln",
}

m["sdv-nyi"] = {
	"Nyima",
	11688746,
	"sdv-nes",
	aliases = {"Nyimang"},
}

m["sdv-tmn"] = {
	"Taman",
	3408873,
	"sdv-nes",
	aliases = {"Tamaic"},
}

m["sdv-ttu"] = {
	"Teso-Turkana",
	7705551,
	"sdv-nie",
	aliases = {"Ateker"},
}

m["sel"] = {
	"Selkup",
	34008,
	"syd",
}

m["sem"] = {
	"Semitic",
	34049,
	"afa",
}

m["sem-ara"] = {
	"Aramaic",
	28602,
	"sem-nwe",
	protoLanguage = "arc",
}

m["sem-arb"] = {
	"Arabic",
	164667,
	"sem-cen",
	protoLanguage = "ar",
}

m["sem-are"] = {
	"Eastern Aramaic",
	3410322,
	"sem-ara",
}

m["sem-arw"] = {
	"Western Aramaic",
	3394214,
	"sem-ara",
}

m["sem-ase"] = {
	"Southeastern Aramaic",
	3410322,
	"sem-are",
}

m["sem-can"] = {
	"Canaanite",
	747547,
	"sem-nwe",
}

m["sem-cen"] = {
	"Central Semitic",
	3433228,
	"sem-wes",
}

m["sem-cna"] = {
	"Central Neo-Aramaic",
	3410322,
	"sem-are",
}

m["sem-eas"] = {
	"East Semitic",
	164273,
	"sem",
}

m["sem-eth"] = {
	"Ethiopian Semitic",
	163629,
	"sem-wes",
	aliases = {"Afro-Semitic", "Ethiopian", "Ethiopic", "Ethiosemitic"},
}

m["sem-nna"] = {
	"Northeastern Neo-Aramaic",
	2560578,
	"sem-are",
}

m["sem-nwe"] = {
	"Northwest Semitic",
	162996,
	"sem-cen",
}

m["sem-osa"] = {
	"Old South Arabian",
	35025,
	"sem-cen",
	aliases = {"Epigraphic South Arabian", "Sayhadic"},
}

m["sem-sar"] = {
	"Modern South Arabian",
	1981908,
	"sem-wes",
}

m["sem-wes"] = {
	"West Semitic",
	124901,
	"sem",
}

m["sgn"] = {
	"sign",
	34228,
	"qfa-not",
}

m["sgn-fsl"] = {
	"French Sign Languages",
	5501921,
	"sgn",
}

m["sgn-gsl"] = {
	"German Sign Languages",
	5551235,
	"sgn",
}

m["sgn-jsl"] = {
	"Japanese Sign Languages",
	11722508,
	"sgn",
}

m["sio"] = {
	"Siouan",
	34181,
	"nai-sca",
}

m["sio-dhe"] = {
	"Dhegihan",
	3217420,
	"sio-msv",
}

m["sio-dkt"] = {
	"Dakotan",
	17188640,
	"sio-msv",
}

m["sio-mor"] = {
	"Missouri River Siouan",
	26807266,
	"sio",
}

m["sio-msv"] = {
	"Mississippi Valley Siouan",
	17188638,
	"sio",
}

m["sio-ohv"] = {
	"Ohio Valley Siouan",
	21070931,
	"sio",
}

m["sit"] = {
	"Sino-Tibetan",
	45961,
}

m["sit-aao"] = {
	"Ao",
	615474,
	"sit",
	aliases = {"Central Naga languages"},
}

m["sit-alm"] = {
	"Almora",
	nil,
	"sit-whm",
}

m["sit-bai"] = {
	"Bai",
	35103,
	"sit-mba",
}

m["sit-bdi"] = {
	"Bodish",
	1814078,
	"sit",
}

m["sit-cln"] = {
	"Cai-Long",
	107182612,
	"sit-mba",
	aliases = {"Cai–Long", "Ta–Li", "Ta-Li"},
}

m["sit-dhi"] = {
	"Dhimalish",
	1207648,
	"sit",
}

m["sit-ebo"] = {
	"East Bodish",
	56402,
	"sit-bdi",
}

m["sit-gma"] = {
	"Greater Magaric",
	55612963,
	"sit",
}

m["sit-gsi"] = {
	"Greater Siangic",
	52698851,
	"sit",
}

m["sit-hrs"] = {
	"Hrusish",
	1632501,
	"sit",
	aliases = {"Southeast Kamengic"},
}

m["sit-jnp"] = {
	"Jingphoic",
	nil,
	"sit-jpl",
	aliases = {"Jingpho"},
}

m["sit-jpl"] = {
	"Kachin-Luic",
	1515454,
	"tbq-bkj",
	aliases = {"Jingpho-Luish", "Jingpho-Asakian", "Kachinic"},
}

m["sit-kch"] = {
	"Konyak-Chang",
	nil,
	"sit-kon",
}

m["sit-kha"] = {
	"Kham",
	33305,
	"sit-gma",
}

m["sit-khb"] = {
	"Kho-Bwa",
	6401917,
	"sit",
	aliases = {"Bugunish", "Kamengic"},
}

m["sit-kic"] = {
	"Central Kiranti",
	nil,
	"sit-kir",
}

m["sit-kie"] = {
	"Eastern Kiranti",
	nil,
	"sit-kir",
}

m["sit-kin"] = {
	"Kinnauric",
	nil,
	"sit-whm",
	aliases = {"Kinnauri"},
}

m["sit-kir"] = {
	"Kiranti",
	922148,
	"sit",
}

m["sit-kiw"] = {
	"Western Kiranti",
	922148,
	"sit-kir",
}

m["sit-kon"] = {
	"Konyak",
	774590,
	"tbq-bkj",
	aliases = {"Konyakian", "Northern Naga"},
}

m["sit-kyk"] = {
	"Kyirong-Kagate",
	6450957,
	"sit-tib",
}

m["sit-lab"] = {
	"Ladakhi-Balti",
	6450957,
	"sit-tib",
}

m["sit-las"] = {
	"Lahuli-Spiti",
	6473510,
	"sit-tib",
}

m["sit-luu"] = {
	"Luish",
	55621439,
	"sit-jpl",
	aliases = {"Asakian", "Sak"},
}

m["sit-mar"] = {
	"Maringic",
	nil,
	"sit-tma",
}

m["sit-mba"] = {
	"Macro-Bai",
	16963847,
	"sit-sba",
	aliases = {"Greater Bai"},
}

m["sit-mdz"] = {
	"Midzu",
	6843504,
	"sit",
	aliases = {"Geman", "Midzuish", "Miju-Meyor", "Southern Mishmi"},
}

m["sit-mnz"] = {
	"Mondzish",
	6898839,
	"tbq-lob",
	aliases = {"Mangish"},
}

m["sit-mru"] = {
	"Mruic",
	16908870,
	"sit",
	aliases = {"Mru-Hkongso"},
}

m["sit-nas"] = {
	"Naish",
	25047956,
	"sit-nax",
}

m["sit-nax"] = {
	"Naic",
	6982999,
	"tbq-buq",
	aliases = {"Naxish"},
}

m["sit-nba"] = {
	"Northern Bai",
	122463830,
	"sit-bai",
}

m["sit-new"] = {
	"Newaric",
	55625069,
	"sit",
}

m["sit-nng"] = {
	"Nungish",
	1515482,
	"sit",
	aliases = {"Nung"},
}

m["sit-qia"] = {
	"Qiangic",
	1636765,
	"tbq-buq",
}

m["sit-rgy"] = {
	"Rgyalrongic",
	56936,
	"sit-qia",
	aliases = {"Jiarongic"},
}

m["sit-sba"] = {
	"Sino-Bai",
	nil,
	"sit",
	aliases = {"Greater Bai"},
}

m["sit-tam"] = {
	"Tamangic",
	3309439,
	"sit",
	aliases = {"West Bodish"},
}

m["sit-tan"] = {
	"Tani",
	3217538,
	"sit",
}

m["sit-tib"] = {
	"Tibetic",
	1641150,
	"sit-bdi",
	protoLanguage = "otb",
}
m["sit-tja"] = {
	"Tujia",
	nil,
	"sit",
}

m["sit-tma"] = {
	"Tangkhul-Maring",
	nil,
	"sit",
}

m["sit-tng"] = {
	"Tangkhulic",
	1516657,
	"sit-tma",
	aliases = {"Tangkhul"},
}

m["sit-tno"] = {
	"Tangsa-Nocte",
	nil,
	"sit-kon",
}

m["sit-tsk"] = {
	"Tshangla",
	nil,
	"sit-bdi",
}

m["sit-whm"] = {
	"West Himalayish",
	2301695,
	"sit",
}

m["sit-zem"] = {
	"Zeme",
	189291,
	"sit",
	aliases = {"Zeliangrong", "Zemeic"},
}

m["sla"] = {
	"Slavic",
	23526,
	"ine-bsl",
	aliases = {"Slavonic"},
}

m["smi"] = {
	"Sami",
	56463,
	"urj",
	aliases = {"Saami", "Samic", "Saamic"},
}

m["son"] = {
	"Songhay",
	505198,
	"ssa",
	aliases = {"Songhai"},
}

m["sqj"] = {
	"Albanian",
	8748,
	"ine",
}

m["ssa"] = {
	"Nilo-Saharan", -- possibly not a genetic grouping
	33705,
}

m["ssa-fur"] = {
	"Fur",
	2989512,
	"ssa",
}

m["ssa-klk"] = {
	"Kuliak",
	1791476,
	"ssa",
	aliases = {"Rub"},
}

m["ssa-kom"] = {
	"Koman",
	1781084,
	"ssa",
}

m["ssa-sah"] = {
	"Saharan",
	1757661,
	"ssa",
}

m["syd"] = {
	"Samoyedic",
	34005,
	"urj",
	aliases = {"Samoyed", "Samodeic"},
}

m["tai"] = {
	"Tai",
	749720,
	"qfa-bet",
	aliases = {"Daic"},
}

m["tai-wen"] = {
	"Wenma-Southwestern Tai",
	nil,
	"tai",
}

m["tai-tay"] = {
	"Tày",
	nil,
	"tai-wen",
}

m["tai-sap"] = {
	"Sapa-Southwestern Tai",
	nil,
	"tai-wen",
	aliases = {"Sapa-Thai"},
}

m["tai-swe"] = {
	"Southwestern Tai",
	3447105,
	"tai-sap",
}

m["tai-cho"] = {
	"Chongzuo Tai",
	13216,
	"tai",
}

m["tai-cen"] = {
	"Central Tai",
	5061891,
	"tai",
}

m["tai-nor"] = {
	"Northern Tai",
	7059014,
	"tai",
}

m["tbq"] = {
	"Tibeto-Burman",
	34064,
	"sit",
}

m["tbq-anp"] = {
	"Angami-Pochuri",
	530460,
	"sit",
}

m["tbq-axi"] = {
	"Axioid",
	nil,
	"tbq-sel",
}

m["tbq-bdg"] = {
	"Bodo-Garo",
	4090000,
	"tbq-bkj",
}

m["tbq-bis"] = {
	"Bisoid",
	48844742,
	"tbq-slo",
}

m["tbq-bka"] = {
	"Bi-Ka",
	12627890,
	"tbq-slo",
}

m["tbq-bkj"] = {
	"Sal",
	889900,
	"sit",
	-- Brahmaputran appears to be Glottolog's term
	aliases = {"Bodo-Konyak-Jinghpaw", "Brahmaputran", "Jingpho-Konyak-Bodo"},
}

m["tbq-brm"] = {
	"Burmish",
	865713,
	"tbq-lob",
}

m["tbq-buq"] = {
	"Burmo-Qiangic",
	16056278,
	"sit",
	aliases = {"Eastern Tibeto-Burman"},
}

m["tbq-drp"] = {
	"Downriver Phula",
	7188378,
	"tbq-rph",
}

m["tbq-han"] = {
	"Hanoid",
	17004185,
	"tbq-slo",
}

m["tbq-hph"] = {
	"Highland Phula",
	nil,
	"tbq-sel",
}

m["tbq-jin"] = {
	"Jino",
	6202716,
	"tbq-slo",
}

m["tbq-kzh"] = {
	"Kazhuoish",
	48834669,
	"tbq-lol",
}

m["tbq-kuk"] = {
	"Kukish",
	832413,
	"sit",
}

m["tbq-lal"] = {
	"Lalo",
	56548,
	"tbq-lso",
}

m["tbq-lho"] = {
	"Lahoish",
	nil,
	"tbq-lol",
}

m["tbq-llo"] = {
	"Lipo-Lolopo",
	nil,
	"tbq-lso",
}

m["tbq-lob"] = {
	"Lolo-Burmese",
	1635712,
	"tbq-buq",
}

m["tbq-lol"] = {
	"Loloish",
	37035,
	"tbq-lob",
	aliases = {"Yi", "Ngwi", "Nisoic"},
}

m["tbq-lso"] = {
	"Lisoish",
	6559055,
	"tbq-lol",
}

m["tbq-lwo"] = {
	"Lawoish",
	48847673,
	"tbq-lol",
}

m["tbq-muj"] = {
	"Muji",
	11221327,
	"tbq-hph",
}

m["tbq-nas"] = {
	"Nasoid",
	nil,
	"tbq-nlo",
}

m["tbq-nis"] = {
	"Nisu",
	56404,
	"tbq-nlo",
}

m["tbq-nlo"] = {
	"Northern Loloish",
	7058676,
	"tbq-nso",
}

m["tbq-nso"] = {
	"Nisoish",
	56990,
	"tbq-lol",
}

m["tbq-nus"] = {
	"Nusoish",
	114245231,
	"tbq-lol",
}

m["tbq-phw"] = {
	"Phowa",
	7187959,
	"tbq-hph",
}

m["tbq-rph"] = {
	"Riverine Phula",
	nil,
	"tbq-sel",
}

m["tbq-sel"] = {
	"Southeastern Loloish",
	16111894,
	"tbq-nso",
}

m["tbq-sil"] = {
	"Siloid",
	60787071,
	"tbq-slo",
}

m["tbq-slo"] = {
	"Southern Loloish",
	5649340,
	"tbq-lol",
}

m["tbq-tal"] = {
	"Taloid",
	48804018,
	"tbq-lso",
}

m["tbq-urp"] = {
	"Upriver Phula",
	7187058,
	"tbq-rph",
}

m["trk"] = {
	"Turkic",
	34090,
}

m["trk-kar"] = {
	"Karluk",
	nil,
	"trk",
	aliases = {"Qarluq", "Uyghur-Uzbek", "Southeastern Turkic"},
	varieties = {"Eastern Turkic"},
}

m["trk-kbu"] = {
	"Kipchak-Bulgar",
	3512539,
	"trk-kip",
	aliases = {"Uralian", "Uralo-Caspian"},
}

m["trk-kcu"] = {
	"Kipchak-Cuman",
	4370412,
	"trk-kip",
	aliases = {"Ponto-Caspian"},
}

m["trk-kip"] = {
	"Kipchak",
	1339898,
	"trk",
	otherNames = {"Western Turkic"},
	aliases = {"Kypchak", "Qypchaq", "Northwestern Turkic", "Western Turkic"},
	protoLanguage = "qwm",
}

m["trk-kkp"] = {
	"Kyrgyz-Kipchak",
	4221189,
	"trk-kip",
}

m["trk-kno"] = {
	"Kipchak-Nogai",
	nil,
	"trk-kip",
	aliases = {"Aralo-Caspian"},
}

m["trk-nsb"] = {
	"North Siberian Turkic",
	4537269,
	"trk-sib",
	aliases = {"Northern Siberian Turkic"},
}

m["trk-ogr"] = {
	"Oghur",
	1422731,
	"trk",
	aliases = {"Lir-Turkic", "r-Turkic"},
}

m["trk-ogz"] = {
	"Oghuz",
	494600,
	"trk",
	aliases = {"Southwestern Turkic"},
}

m["trk-sib"] = {
	"Siberian Turkic",
	nil,
	"trk",
	otherNames = {"Northern Turkic"},
	aliases = {"Northeastern Turkic"},
}

m["trk-ssb"] = {
	"South Siberian Turkic",
	nil,
	"trk-sib",
	aliases = {"Southern Siberian Turkic"},
}

m["tup"] = {
	"Tupian",
	34070,
	aliases = {"Tupi"},
}

m["tup-gua"] = {
	"Tupi-Guarani",
	148610,
	"tup",
	aliases = {"Tupí-Guaraní"},
}

m["tuw"] = {
	"Tungusic",
	34230,
	aliases = {"Manchu-Tungus", "Tungus"},
}

m["tuw-ewe"] = {
	"Ewenic",
	105889448,
	"tuw",
	aliases = {"Northern Tungusic"},
}

m["tuw-jrc"] = {
	"Jurchenic",
	105889432,
	"tuw",
	aliases = {"Manchuric"},
}

m["tuw-nan"] = {
	"Nanaic",
	105889264,
	"tuw",
}

m["tuw-udg"] = {
	"Udegheic",
	105889266,
	"tuw",
}

m["urj"] = {
	"Uralic",
	34113,
	varieties = {"Finno-Ugric"},
}

m["urj-fin"] = {
	"Finnic",
	33328,
	"urj",
	aliases = {"Baltic-Finnic", "Balto-Finnic", "Fennic"},
}

m["urj-mdv"] = {
	"Mordvinic",
	627313,
	"urj",
}

m["urj-prm"] = {
	"Permic",
	161493,
	"urj",
}

m["urj-ugr"] = {
	"Ugric",
	156631,
	"urj",
}

m["wak"] = {
	"Wakashan",
	60069,
}

m["wen"] = {
	"Sorbian",
	25442,
	"zlw",
	aliases = {"Lusatian", "Wendish"},
}

m["xgn"] = {
	"Mongolic",
	33750,
	"qfa-xgs",
	aliases = {"Mongolian"},
}

m["xgn-cen"] = {
	"Central Mongolic",
	nil,
	"xgn",
	protoLanguage = "xng-lat",
}

m["xgn-sou"] = {
	"Southern Mongolic",
	nil,
	"xgn",
	protoLanguage = "xng-ear",
}

m["xgn-shr"] = {
	"Shirongolic",
	107539435,
	"xgn-sou",
}

m["xme"] = {
	"Median",
	nil,
	"ira-mpr",
	protoLanguage = "xme-old",
}

m["xme-ttc"] = {
	"Tatic",
	nil,
	"xme",
}

m["xnd"] = {
	"Na-Dene",
	26986,
	"qfa-dny",
	aliases = {"Na-Dené"},
}

m["xsc"] = {
	"Scythian",
	nil,
	"ira-nei",
}

m["xsc-sak"] = {
	"Sakan",
	nil,
	"xsc-skw",
	aliases = {"Saka"},
}

m["xsc-skw"] = {
	"Saka-Wakhi",
	nil,
	"xsc",
}

m["ypk"] = {
	"Yupik",
	27970,
	"esx-esk",
	aliases = {"Yup'ik", "Yuit"},
}

m["zhx"] = {
	"Sinitic",
	33857,
	"sit-sba",
	aliases = {"Chinese"},
	protoLanguage = "och",
}

m["zhx-com"] = {
	"Coastal Min",
	nil,
	"zhx-min",
}

m["zhx-inm"] = {
	"Inland Min",
	nil,
	"zhx-min",
}

m["zhx-man"] = {
	"Mandarinic",
	nil,
	"zhx",
	protoLanguage = "cmn-ear",
}

m["zhx-min"] = {
	"Min",
	nil,
	"zhx",
}

m["zhx-pin"] = {
	"Pinghua",
	2735715,
	"zhx",
	protoLanguage = "ltc",
}

m["zhx-yue"] = {
	"Yue",
	7033959,
	"zhx",
	protoLanguage = "ltc",
}

m["zle"] = {
	"East Slavic",
	144713,
	"sla",
}

m["zls"] = {
	"South Slavic",
	146665,
	"sla",
}

m["zlw"] = {
	"West Slavic",
	145852,
	"sla",
}

m["zlw-lch"] = {
	"Lechitic",
	742782,
	"zlw",
	aliases = {"Lekhitic"},
}

m["zlw-pom"] = {
	"Pomeranian",
	nil,
	"zlw-lch",
}

m["znd"] = {
	"Zande",
	8066072,
	"nic-ubg",
}

return require("languages").addDefaultTypes(m, true, "family")