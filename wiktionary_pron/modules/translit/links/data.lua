local encode = mw.text.encode
local u = mw.ustring.char
local data = {}

data.ignore_cap = {
	["ko"] = true,
}

data.phonetic_extraction = {
	["th"] = "Module:th",
	["km"] = "Module:km",
}

data.pos_tags = {
	["a"] = "adjective",
	["adv"] = "adverb",
	["int"] = "interjection",
	["n"] = "noun",
	["pron"] = "pronoun",
	["v"] = "verb",
	["vi"] = "intransitive verb",
	["vt"] = "transitive verb",
	["vti"] = "transitive and intransitive verb",
}

-- Scheme for using unsupported characters in titles.
data.unsupported_characters = {
	["#"] = "`num`",
	["%"] = "`percnt`", -- only escaped in percent encoding
	["&"] = "`amp`", -- only escaped in HTML entities
	["."] = "`period`", -- only escaped in dot-slash notation
	["<"] = "`lt`",
	[">"] = "`gt`",
	["["] = "`lsqb`",
	["]"] = "`rsqb`",
	["_"] = "`lowbar`",
	["`"] = "`grave`", -- used to enclose unsupported characters in the scheme, so a raw use in an unsupported title must be escaped to prevent interference
	["{"] = "`lcub`",
	["|"] = "`vert`",
	["}"] = "`rcub`",
	["~"] = "`tilde`", -- only escaped when 3 or more are consecutive
	["\239\191\189"] = "`repl`" -- replacement character U+FFFD, which can't be typed directly here due to an abuse filter
}

-- Manually specified unsupported titles. Only put titles here if there is a different reason why they are unsupported, and not just because they contain one of the unsupported characters above.
data.unsupported_titles = {
	[" "] = "Space",
	["&amp;"] = "`amp`amp;",
	["λοπαδοτεμαχοσελαχογαλεοκρανιολειψανοδριμυποτριμματοσιλφιοκαραβομελιτοκατακεχυμενοκιχλεπικοσσυφοφαττοπεριστεραλεκτρυονοπτοκεφαλλιοκιγκλοπελειολαγῳοσιραιοβαφητραγανοπτερύγων"] = "Ancient Greek dish",
	["กรุงเทพมหานคร อมรรัตนโกสินทร์ มหินทรายุธยา มหาดิลกภพ นพรัตนราชธานีบูรีรมย์ อุดมราชนิเวศน์มหาสถาน อมรพิมานอวตารสถิต สักกะทัตติยวิษณุกรรมประสิทธิ์"] = "Thai name of Bangkok",
	[u(0x1680)] = "Ogham space",
	[u(0x3000)] = "Ideographic space"
}

-- Valid URI schemes in external links, which therefore have to be escaped if used in entry names (e.g. [[sms:a]]).
local uri_schemes = {
	"bitcoin:",
	"ftp://",
	"ftps://",
	"geo:",
	"git://",
	"gopher://",
	"http://",
	"https://",
	"irc:",
	"ircs:",
	"magnet:",
	"mailto:",
	"matrix:",
	"mms://",
	"news:",
	"nntp://",
	"redis://",
	"sftp://",
	"sip:",
	"sips:",
	"sms:",
	"ssh://",
	"svn://",
	"tel:",
	"telnet://",
	"urn:",
	"worldwind://",
	"xmpp:",
}
-- Convert into lookup table.
local uri_lookup = {}
for _, scheme in ipairs(uri_schemes) do
	uri_lookup[scheme] = encode(scheme, ":")
end
data.uri_schemes = uri_lookup

return data