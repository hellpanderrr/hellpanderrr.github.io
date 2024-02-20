local data = {
	"All language families",
	"All languages",
	"All scripts",
	"Categories only containing subcategories",
	"Character boxes",
	"Characters by script",
	"Entries with audio examples",
	"Entries with redirects",
	"Entry maintenance by language",
	"Figures of speech by language",
	"Gestures",
	"Lemmas by language",
	"Letters",
	"Lists",
	"Non-lemma forms by language",
	"Phrasebooks by language",
	"Protologisms",
	"Regionalisms",
	"Rhymes by language",
	"Sentences by language",
	"All sets",
	"Shortenings by language",
	"Symbols by language",
	"Synchronized entries by language",
	"Terms by etymology by language",
	"Terms by lexical property by language",
	"Terms by semantic function by language",
	"Terms by usage by language",
	"All topics",
	"Unicode blocks",
	"Unsupported titles",
	"Wiktionary",
	"Wiktionary pages that don't exist",
	"Wiktionary-namespace discussion pages",
}

for i, category in ipairs(data) do
	data[i] = nil
	data["Category:" .. category] = true
end

return data