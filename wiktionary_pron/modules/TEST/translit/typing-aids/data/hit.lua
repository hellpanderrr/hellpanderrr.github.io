local replacements = {}

replacements["hit"] = {
	-- This converts from regular to diacriticked characters, before the
	-- shortcuts below are processed.
	-- The apostrophe is used in place of an acute, and a backslash \ in place of
	-- a grave. Plain s and h have háček and breve below added to them, and
	-- 5 and 9 are converted to superscripts.
	-- For example:
		-- pe'	-> pé	-> 𒁉
		-- sa	-> ša	-> 𒊭
		-- hal	-> ḫal	-> 𒄬
	-- Thus, plain s and h can't be used in shortcuts.
	["pre"] = {
		["a'"] = "á", ["e'"] = "é", ["i'"] = "í", ["u'"] = "ú",
		["s"] = "š", ["h"] = "ḫ", ["5"] = "₅", ["9"] = "₉", ["a\\"] = "à",
	},
	
	-- V
	["a"] = "𒀀",
	["e"] = "𒂊",
	["i"] = "𒄿",
	["ú"] = "𒌑",
	["u"] = "𒌋",
	
	-- CV
	["ba"] = "𒁀", ["be"] = "𒁁", ["bi"] = "𒁉", ["bu"] = "𒁍",
	["pa"] = "𒉺", ["pé"] = "𒁉", ["pí"] = "𒁉", ["pu"] = "𒁍",
	["da"] = "𒁕", ["de"] = "𒁲", ["di"] = "𒁲", ["du"] = "𒁺",
	["ta"] = "𒋫", ["te"] = "𒋼", ["ti"] = "𒋾", ["tu"] = "𒌅",
	["ga"] = "𒂵", ["ge"] = "𒄀", ["gi"] = "𒄀", ["gu"] = "𒄖",
	["ka"] = "𒅗", ["ke"] = "𒆠", ["ki"] = "𒆠", ["ku"] = "𒆪",
	["ḫa"] = "𒄩", ["ḫe"] = "𒄭", ["ḫé"] = "𒃶", ["ḫi"] = "𒄭", ["ḫu"] = "𒄷",
	["la"] = "𒆷", ["le"] = "𒇷", ["li"] = "𒇷", ["lu"] = "𒇻",
	["ma"] = "𒈠", ["me"] = "𒈨", ["mé"] = "𒈪", ["mi"] = "𒈪", ["mu"] = "𒈬",
	["na"] = "𒈾", ["ne"] = "𒉈", ["né"] = "𒉌", ["ni"] = "𒉌", ["nu"] = "𒉡",
	["ra"] = "𒊏", ["re"] = "𒊑", ["ri"] = "𒊑", ["ru"] = "𒊒",
	["ša"] = "𒊭", ["še"] = "𒊺", ["ši"] = "𒅆", ["šu"] = "𒋗", ["šú"] = "𒋙",
	["wa"] = "𒉿", ["wi"]= "𒃾", ["wi₅"]= "𒃾", 
	["ya"] = "𒅀",
	["za"] = "𒍝", ["ze"] = "𒍣", ["ze'"] = "𒍢", ["zé"] = "𒍢", ["zi"] = "𒍣", ["zu"] = "𒍪",
	
	-- VC
	["ab"] = "𒀊", ["eb"] = "𒅁", ["ib"] = "𒅁", ["ub"] = "𒌒",
	["ap"] = "𒀊", ["ep"] = "𒅁", ["ip"] = "𒅁", ["up"] = "𒌒",
	["ad"] = "𒀜", ["ed"] = "𒀉", ["id"] = "𒀉", ["ud"] = "𒌓",
	["at"] = "𒀜", ["et"] = "𒀉", ["it"] = "𒀉", ["ut"] = "𒌓",
	["ag"] = "𒀝", ["eg"] = "𒅅", ["ig"] = "𒅅", ["ug"] = "𒊌",
	["ak"] = "𒀝", ["ek"] = "𒅅", ["ik"] = "𒅅", ["uk"] = "𒊌",
	["aḫ"] = "𒄴", ["eḫ"] = "𒄴", ["iḫ"]= "𒄴", ["uḫ"] = "𒄴",
	["al"] = "𒀠", ["el"] = "𒂖", ["il"] = "𒅋", ["ul"] = "𒌌",
	["am"] = "𒄠", ["em"] = "𒅎", ["im"] = "𒅎", ["um"] = "𒌝",
	["an"] = "𒀭", ["en"] = "𒂗", ["in"] = "𒅔", ["un"] = "𒌦",
	["ar"] = "𒅈", ["er"] = "𒅕", ["ir"] = "𒅕", ["ur"] = "𒌨", ["úr"] = "𒌫",
	["aš"] = "𒀸", ["eš"] = "𒌍", ["iš"] = "𒅖", ["uš"] = "𒍑",
	["az"] = "𒊍", ["ez"] = "𒄑", ["iz"] = "𒄑", ["uz"] = "𒊻",
	
	-- VCV
	["ḫal"] = "𒄬", ["ḫab"] = "𒆸", ["ḫap"] = "𒆸", ["ḫaš"] = "𒋻", ["ḫad"] = "𒉺", ["ḫat"] = "𒉺",
	["ḫul"] = "𒅆", ["ḫub"] = "𒄽", ["ḫup"] = "𒄽", ["ḫar"] = "𒄯", ["ḫur"] = "𒄯",
	
	["gal"] = "𒃲", ["kal"] = "𒆗", ["gal₉"] = "𒆗", ["kam"] = "𒄰", ["gám"] = "𒄰",
	["kán"] = "𒃷", ["gán"] = "𒃷", ["kab"] = "𒆏", ["kap"] = "𒆏", ["gáb"] = "𒆏", ["gáp"] = "𒆏",
	["kar"] = "𒋼𒀀", ["kàr"] = "𒃼", ["gàr"] = "𒃼", ["kaš"] = "𒁉", ["gaš"] = "𒁉",
	["kad"] = "𒃰", ["kat"] = "𒃰", ["gad"] = "𒃰", ["gat"] = "𒃰", ["gaz"] = "𒄤",
	-- kib, kip are not encoded
	["kir"] = "𒄫", ["gir"] = "𒄫", ["kiš"] = "𒆧", ["kid₉"] = "𒃰", ["kit₉"] = "𒃰",
	["kal"] = "𒆗", ["kul"] = "𒆰", ["kúl"] = "𒄢", ["gul"] = "𒄢",
	["kum"] = "𒄣", ["gum"] = "𒄣", ["kur"] = "𒆳", ["kùr"] = "𒄥", ["gur"] = "𒄥",
	
	["lal"] = "𒇲", ["lam"] = "𒇴", ["lig"] = "𒌨", ["lik"] = "𒌨", ["liš"] = "𒇺", ["luḫ"] = "𒈛", ["lum"] = "𒈝",
	
	["maḫ"] = "𒈤", ["man"] = "𒎙", ["mar"] = "𒈥", ["maš"] = "𒈦", ["meš"] = "𒈨𒌍", 
	["mil"] = "𒅖", ["mel"] = "𒅖", ["miš"] = "𒈩", ["mur"] = "𒄯", ["mut"] = "𒄷𒄭",
	
	["nam"] = "𒉆", ["nab"] = "𒀮", ["nap"] = "𒀮", ["nir"] = "𒉪", ["niš"] = "𒎙", 
	
	["pal"] = "𒁄", ["bal"] = "𒁄", ["pár"] = "𒈦", ["bar"] = "𒈦", ["paš"] = "𒄫",
	["pád"] = "𒁁", ["pát"] = "𒁁", ["píd"] = "𒁁", ["pít"] = "𒁁", ["píl"] = "𒉋", ["bíl"] = "𒉋",
	["pir"] = "𒌓", ["piš"] = "𒄫", ["biš"] = "𒄫", ["pùš"] = "𒄫", ["pur"] = "𒁓", ["bur"] = "𒁓",
	
	["rad"] = "𒋥", ["rat"] = "𒋥", ["riš"] = "𒊕",
	
	["šaḫ"] = "𒋚", ["šag"] = "𒊕",  ["šak"] = "𒊕", ["šal"] = "𒊩", ["šam"] = "𒌑", ["šàm"] = "𒉓",
	["šab"] = "𒉺𒅁", ["šap"] = "𒉺𒅁", ["šar"] = "𒊬", ["šìp"] = "𒉺𒅁", ["šir"] = "𒋓", ["šum"] = "𒋳", ["šur"] = "𒋩",
	
	["taḫ"] = "𒈭", ["daḫ"] = "𒈭", ["túḫ"] = "𒈭", ["tág"] = "𒁖", ["ták"] = "𒁖", ["dag"] = "𒁖", ["dak"] = "𒁖",
	["tal"] = "𒊑", ["dal"] = "𒊑", ["tám"] = "𒁮", ["dam"] = "𒁮", ["tan"] = "𒆗", ["dan"] = "𒆗",
	["tab"] = "𒋰", ["tap"] = "𒋰", ["dáb"] = "𒋰", ["dáp"] = "𒋰", ["tar"] = "𒋻",
	["táš"] = "𒁹", ["dáš"] = "𒁹", ["tiš"] = "𒁹", ["diš"] = "𒁹",
	["tàš"] = "𒀾", ["tin"] = "𒁷", ["tén"] = "𒁷", ["tim"] = "𒁴", ["dim"] = "𒁴",
	["dir"] = "𒋛𒀀", ["tir"] = "𒌁", ["ter"] = "𒌁", ["tíś"] = "𒌨", ["túl"] = "𒇥",
	["tum"] = "𒌈", ["dum"] = "𒌈", ["tub"] = "𒁾", ["tup"] = "𒁾", ["dub"] = "𒁾", ["dup"] = "𒁾",
	["túr"] = "𒄙", ["dur"] = "𒄙",
	
	["zul"] = "𒂄", ["zum"] = "𒍮",
	
	-- Determiners
	["DIDLI"] ="𒀸", ["DINGIR"]="𒀭", ["DUG"]="𒂁", ["É"]="𒂍", ["GAD"]="𒃰", ["GI"]="𒄀", 
	["GIŠ"]="𒄑", ["GUD"]="𒄞", ["ḪI.A"]="𒄭𒀀", ["ḪUR.SAG"]="𒄯𒊕", ["IM"]="𒅎", ["ITU"]="𒌚",
	["KAM"]="𒄰", ["KI"]="𒆠", ["KUR"]="𒆳", ["KUŠ"]="𒋢", ["LÚ"]="𒇽", ["MEŠ"]="𒈨𒌍",["MUL"]="𒀯",
	["MUNUS"]="𒊩", ["MUŠ"]="𒈲", ["MUŠEN"]="𒄷",  ["NINDA"]="𒃻", ["SAR"]="𒊬",
	["SI"]="𒋛", ["SIG"]="𒋠", ["TÚG"]="𒌆", ["𒌑"]="𒌑", ["URU"]="𒌷", ["URUDU"]="𒍐", ["UZU"]="𒍜",
	-- Logograms
	["KASKAL"]="𒆜", ["LUGAL"]="𒈗",  ["GÌR"]="𒄊", ["GÍR"]="𒄈", ["IGI"]="𒃲", ["SÍG"]="𒋠" ,["IŠKUR"]="𒅎"
}

replacements["hit-tr"] = {
		["a'"] = "á", ["e'"] = "é", ["i'"] = "í", ["u'"] = "ú",
	["s"] = "š", ["s'"] = "ś", ["h"] = "ḫ", ["5"] = "₅", ["9"] = "₉", ["a\\"] = "à",
}

return replacements