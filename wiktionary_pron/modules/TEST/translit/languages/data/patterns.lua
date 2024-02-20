-- Capture patterns used by [[Module:languages]] to prevent formatting from being disrupted while text is being processed.
-- Certain character sequences are substituted beforehand to make pattern matching more straightforward:
-- "\1" = "[["
-- "\2" = "]]"
return {
	"((</?link>))\0", -- Special link formatting added by [[Module:links]]
	"((<[^<>\1\2]+>))", -- HTML tag
	"((\1[Ff][Ii][Ll][Ee]:[^\1\2]+\2))\0", -- File
	"((\1[Ii][Mm][Aa][Gg][Ee]:[^\1\2]+\2))\0", -- Image
	"((\1[Cc][Aa][Tt][Ee][Gg][Oo][Rr][Yy]:[^\1\2]+\2))\0", -- Category
	"((\1[Cc][Aa][Tt]:[^\1\2]+\2))\0", -- Category
	"((\1)[^\1\2|]+(\2))\0", -- Bare internal link
	"((\1)[^\1\2|]-(|)[^\1\2]-(\2))\0", -- Piped internal link
	"((%[https?://[^[%] ]+)[^[%]]*(%]))\0", -- External link
	"((\127'\"`UNIQ%-%-%l+%-%x+%-+QINU`\"'\127))", -- Strip marker
	"('*(''').-'*('''))", -- Bold
	"('*('').-'*(''))" -- Italics
}