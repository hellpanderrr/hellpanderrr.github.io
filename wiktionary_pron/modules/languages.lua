local insert = table.insert
local remove = table.remove
local ugsub = mw.ustring.gsub

local export = {}

--[=[
This module implements fetching of language-specific information and processing text in a given language.

There are two types of languages: full languages and etymology-only languages. The essential difference is that only
full languages appear in L2 headings in vocabulary entries, and hence categories like [[:Category:French nouns]] exist
only for full languages. Etymology-only languages have either a full language or another etymology-only language as
their parent (in the parent-child inheritance sense), and for etymology-only languages with another etymology-only
language as their parent, a full language can always be derived by following the parent links upwards. For example,
"Canadian French", code 'fr-CA', is an etymology-only language whose parent is the full language "French", code 'fr'.
An example of an etymology-only language with another etymology-only parent is "Northumbrian Old English", code
'ang-nor', which has "Anglian Old English", code 'ang-ang' as its parent; this is an etymology-only language whose
parent is "Old English", code "ang", which is a full language. (This is because Northumbrian Old English is considered
a variety of Anglian Old English.) Sometimes the parent is the "Undetermined" language, code 'und'; this is the case,
for example, for "substrate" languages such as "Pre-Greek", code 'qsb-grc', and "the BMAC substrate", code 'qsb-bma'.

It is important to distinguish language ''parents'' from language ''ancestors''. The parent-child relationship is one
of containment, i.e. if X is a child of Y, X is considered a variety of Y. On the other hand, the ancestor-descendant
relationship is one of descent in time. For example, "Classical Latin", code 'la-cla', and "Late Latin", code 'la-lat',
are both etymology-only languages with "Latin", code 'la', as their parents, because both of the former are varieties
of Latin. However, Late Latin does *NOT* have Classical Latin as its parent because Late Latin is *not* a variety of
Classical Latin; rather, it is a descendant. There is in fact a separate 'ancestors' field that is used to express the
ancestor-descendant relationship, and Late Latin's ancestor is given as Classical Latin. It is also important to note
that sometimes an etymology-only language is actually the conceptual ancestor of its parent language. This happens,
for example, with "Old Italian" (code 'roa-oit'), which is an etymology-only variant of full language "Italian" (code
'it'), and with "Old Latin" (code 'itc-ola'), which is an etymology-only variant of Latin. In both cases, the full
language has the etymology-only variant listed as an ancestor. This allows a Latin term to inherit from Old Latin
using the {{tl|inh}} template (where in this template, "inheritance" refers to ancestral inheritance, i.e. inheritance
in time, rather than in the parent-child sense); likewise for Italian and Old Italian.

Full languages come in three subtypes:
* {regular}: This indicates a full language that is attested according to [[WT:CFI]] and therefore permitted in the
			 main namespace. There may also be reconstructed terms for the language, which are placed in the
			 {Reconstruction} namespace and must be prefixed with * to indicate a reconstruction. Most full languages
			 are natural (not constructed) languages, but a few constructed languages (e.g. Esperanto and Volapük,
			 among others) are also allowed in the mainspace and considered regular languages.
* {reconstructed}: This language is not attested according to [[WT:CFI]], and therefore is allowed only in the
				   {Reconstruction} namespace. All terms in this language are reconstructed, and must be prefixed with
				   *. Languages such as Proto-Indo-European and Proto-Germanic are in this category.
* {appendix-constructed}: This language is attested but does not meet the additional requirements set out for
						  constructed languages ([[WT:CFI#Constructed languages]]). Its entries must therefore be in
						  the Appendix namespace, but they are not reconstructed and therefore should not have *
						  prefixed in links. Most constructed languages are of this subtype.

Both full languages and etymology-only languages have a {Language} object associated with them, which is fetched using
the {getByCode} function in [[Module:languages]] to convert a language code to a {Language} object. Depending on the
options supplied to this function, etymology-only languages may or may not be accepted, and family codes may be
accepted (returning a {Family} object as described in [[Module:families]]). There are also separate {getByCanonicalName}
functions in [[Module:languages]] and [[Module:etymology languages]] to convert a language's canonical name to a
{Language} object (depending on whether the canonical name refers to a full or etymology-only language).

Textual strings belonging to a given language come in several different ''text variants'':
# The ''input text'' is what the user supplies in wikitext, in the parameters to {{tl|m}}, {{tl|l}}, {{tl|ux}},
  {{tl|t}}, {{tl|lang}} and the like.
# The ''display text'' is the text in the form as it will be displayed to the user. This can include accent marks that
  are stripped to form the entry text (see below), as well as embedded bracketed links that are variously processed
  further. The display text is generated from the input text by applying language-specific transformations; for most
  languages, there will be no such transformations. Examples of transformations are bad-character replacements for
  certain languages (e.g. replacing 'l' or '1' to [[palochka]] in certain languages in Cyrillic); and for Thai and
  Khmer, converting space-separated words to bracketed words and resolving respelling substitutions such as [กรีน/กฺรีน],
  which indicate how to transliterate given words.
# The ''entry text'' is the text in the form used to generate a link to a Wiktionary entry. This is usually generated
  from the display text by stripping certain sorts of diacritics on a per-language basis, and sometimes doing other
  transformations. The concept of ''entry text'' only really makes sense for text that does not contain embedded links,
  meaning that display text containing embedded links will need to have the links individually processed to get
  per-link entry text in order to generate the resolved display text (see below).
# The ''resolved display text'' is the result of resolving embedded links in the display text (e.g. converting them to
  two-part links where the first part has entry-text transformations applied, and adding appropriate language-specific
  fragments) and adding appropriate language and script tagging. This text can be passed directly to MediaWiki for
  display.
# The ''source translit text'' is the text as supplied to the language-specific {transliterate()} method. The form of
  the source translit text may need to be language-specific, e.g Thai and Khmer will need the full unprocessed input
  text, whereas other languages may need to work off the display text. [FIXME: It's still unclear to me how embedded
  bracketed links are handled in the existing code.] In general, embedded links need to be removed (i.e. converted to
  their "bare display" form by taking the right part of two-part links and removing double brackets), but when this
  happens is unclear to me [FIXME]. Some languages have a chop-up-and-paste-together scheme that sends parts of the
  text through the transliterate mechanism, and for others (those listed in {contiguous_substition} in
  [[Module:languages/data]]) they receive the full input text, but preprocessed in certain ways. (The wisdom of this is
  still unclear to me.)
# The ''transliterated text'' (or ''transliteration'') is the result of transliterating the source translit text.
  Unlike for all the other text variants except the transcribed text, it is always in the Latin script.
# The ''transcribed text'' (or ''transcription'') is the result of transcribing the source translit text, where
  "transcription" here means a close approximation to the phonetic form of the language in languages (e.g. Akkadian,
  Sumerian, Ancient Egyptian, maybe Tibetan) that have a wide difference between the written letters and spoken form.
  Unlike for all the other text variants other than the transliterated text, it is always in the Latin script.
  Currently, the transcribed text is always supplied manually be the user; there is no such thing as a
  {lua|transcribe()} method on language objects.
# The ''sort key'' is the text used in sort keys for determining the placing of pages in categories they belong to. The
  sort key is generated from the pagename or a specified ''sort base'' by lowercasing, doing language-specific
  transformations and then uppercasing the result. If the sort base is supplied and is generated from input text, it
  needs to be converted to display text, have embedded links removed (i.e. resolving them to their right side if they
  are two-part links) and have entry text transformations applied.
# There are other text variants that occur in usexes (specifically, there are normalized variants of several of the
  above text variants), but we can skip them for now.

The following methods exist on {Language} objects to convert between different text variants:
# {makeDisplayText}: This converts input text to display text.
# {lua|makeEntryName}: This converts input or display text to entry text. [FIXME: This needs some rethinking. In
  particular, {lua|makeEntryName} is sometimes called on display text (in some paths inside of [[Module:links]]) and
  sometimes called on input text (in other paths inside of [[Module:links]], and usually from other modules). We need
  to make sure we don't try to convert input text to display text twice, but at the same time we need to support
  calling it directly on input text since so many modules do this. This means we need to add a parameter indicating
  whether the passed-in text is input or display text; if that former, we call {lua|makeDisplayText} ourselves.]
# {lua|transliterate}: This appears to convert input text with embedded brackets removed into a transliteration.
  [FIXME: This needs some rethinking. In particular, it calls {lua|processDisplayText} on its input, which won't work
  for Thai and Khmer, so we may need language-specific flags indicating whether to pass the input text directly to the
  language transliterate method. In addition, I'm not sure how embedded links are handled in the existing translit code;
  a lot of callers remove the links themselves before calling {lua|transliterate()}, which I assume is wrong.]
# {lua|makeSortKey}: This converts entry text (?) to a sort key. [FIXME: Clarify this.]
]=]

local function track(page)
	require("debug/track")("languages/" .. page)
	return true
end

local function normalize_code(code)
	return mw.loadData("languages/data").aliases[code] or code
end

local checkObject = require("utilities").check_object

-- Remove directional formatting characters from the start and end of the text.
local dir_char = "\226\128\170-\226\128\174\226\129\166-\226\129\169"
local function remove_directional_chars(text)
	return (ugsub(text, "^[" .. dir_char .. "]*(.*)%f[%z" .. dir_char .. "][" .. dir_char .. "]*$", "%1"))
end

-- Convert risky characters to HTML entities, which minimizes interference once returned (e.g. for "sms:a", "<!-- -->" etc.).
local function escape_risky_characters(text)
	local make_entities = require("utilities").make_entities
	-- Spacing characters in isolation generally need to be escaped in order to be properly processed by the MediaWiki software.
	if not mw.ustring.match(text, "%S") then
		return make_entities(text, text)
	else
		return make_entities(text, "!#%&*+/:;<=>?@[\\]_{|}")
	end
end

local function make_language(code, data, useRequire)
	local function conditionalRequire(modulename)
		if useRequire then
			return require(modulename)
		else
			return mw.loadData(modulename)
		end
	end
	
	-- Temporarily convert various formatting characters to PUA to prevent them from being disrupted by the substitution process.
	local function doTempSubstitutions(text, subbedChars, keepCarets, noTrim)
		-- Clone so that we don't insert any extra patterns into the table in package.loaded. For some reason, using require seems to keep memory use down; probably because the table is always cloned.
		local patterns = require("table").shallowcopy(require("languages/data/patterns"))
		if keepCarets then
			insert(patterns, "((\\+)%^)")
			insert(patterns, "((%^))")
		end
		-- Ensure any whitespace at the beginning and end is temp substituted, to prevent it from being accidentally trimmed. We only want to trim any final spaces added during the substitution process (e.g. by a module), which means we only do this during the first round of temp substitutions.
		if not noTrim then
			insert(patterns, "^([\128-\191\244]*(%s+))")
			insert(patterns, "((%s+)[\128-\191\244]*)$")
		end
		-- Pre-substitution, of "[[" and "]]", which makes pattern matching more accurate.
		text = text
			:gsub("%f[%[]%[%[", "\1")
			:gsub("%f[%]]%]%]", "\2")
		local i, pe = #subbedChars, require("string/pattern escape")
		for j, pattern in ipairs(patterns) do
			-- Patterns ending in \0 stand are for things like "[[" or "]]"), so the inserted PUA are treated as breaks between terms by modules that scrape info from pages.
			local term_divider
			pattern = pattern:gsub("%z$", function(divider)
				term_divider = divider == "\0"
				return ""
			end)
			text = text:gsub(pattern, function(...)
				local m = {...}
				local m1New = m[1]
				for k = 2, #m do
					local n = i + k - 1
					subbedChars[n] = m[k]
					local byte2 = math.floor(n / 4096) % 64 + (term_divider and 128 or 136)
					local byte3 = math.floor(n / 64) % 64 + 128
					local byte4 = n % 64 + 128
					m1New = m1New:gsub(pe(m[k]), "\244" .. string.char(byte2) .. string.char(byte3) .. string.char(byte4), 1)
				end
				i = i + #m - 1
				return m1New
			end)
		end
		text = text
			:gsub("\1", "%[%[")
			:gsub("\2", "%]%]")
		return text, subbedChars
	end
	
	-- Reinsert any formatting that was temporarily substituted.
	local function undoTempSubstitutions(text, subbedChars)
		local pe = require("string/pattern escape")
		for i = 1, #subbedChars do
			local byte2 = math.floor(i / 4096) % 64 + 128
			local byte3 = math.floor(i / 64) % 64 + 128
			local byte4 = i % 64 + 128
			text = text:gsub("\244[" .. string.char(byte2) .. string.char(byte2+8) .. "]" .. string.char(byte3) .. string.char(byte4), pe(subbedChars[i]))
		end
		text = text
			:gsub("\1", "%[%[")
			:gsub("\2", "%]%]")
		return text
	end
	
	-- Convert any HTML entities.
	local function noEntities(text)
		if text:match("&[^;]+;") then
			return require("utilities").get_entities(text)
		else
			return text
		end
	end
	
	-- Check if the raw text is an unsupported title, and if so return that. Otherwise, remove HTML entities. We do the pre-conversion to avoid loading the unsupported title list unnecessarily.
	local function checkNoEntities(text)
		local textNoEnc = noEntities(text)
		if textNoEnc ~= text and conditionalRequire("Module:links/data").unsupported_titles[text] then
			return text
		else
			return textNoEnc
		end
	end
	
	-- If no script object is provided (or if it's invalid or None), get one.
	local function checkScript(text, self, sc)
		if not checkObject("script", true, sc) or sc:getCode() == "None" then
			return self:findBestScript(text)
		else
			return sc
		end
	end
	
	local function normalize(text, sc)
		text = sc:fixDiscouragedSequences(text)
		return sc:toFixedNFD(text)
	end
	
	-- Split the text into sections, based on the presence of temporarily substituted formatting characters, then iterate over each one to apply substitutions. This avoids putting PUA characters through language-specific modules, which may be unequipped for them.
	local function iterateSectionSubstitutions(text, subbedChars, keepCarets, self, sc, substitution_data, function_name)
		local pe = require("string/pattern escape")
		local fail, cats, sections = nil, {}
		-- See [[Module:languages/data]].
		if not text:match("\244") or conditionalRequire("Module:languages/data").contiguous_substitution[self:getCode()] then
			sections = {text}
		else
			sections = mw.text.split(text, "[􀀀-􏿽]")
		end
		for i, section in ipairs(sections) do
			-- Don't bother processing empty strings or whitespace (which may also not be handled well by dedicated modules).
			if section:gsub("%s", "") ~= "" then
				local sub, sub_fail, sub_cats = require("languages/doSubstitutions")(section, self, sc, substitution_data, function_name)
				-- Second round of temporary substitutions, in case any formatting was added by the main substitution process. However, don't do this if the section contains formatting already (as it would have had to have been escaped to reach this stage, and therefore should be given as raw text).
				if sub and subbedChars then
					local noSub
					for _, pattern in ipairs(require("languages/data/patterns")) do
						if section:match(pattern .. "%z?") then
							noSub = true
						end
					end
					if not noSub then
						sub, subbedChars = doTempSubstitutions(sub, subbedChars, keepCarets, true)
					end
				end
				if (not sub) or sub_fail then
					text = sub
					fail = sub_fail
					cats = sub_cats or {}
					break
				end
				text = sub and text:gsub(pe(section), pe(sub), 1) or text
				if type(sub_cats) == "table" then
					for _, cat in ipairs(sub_cats) do
						insert(cats, cat)
					end
				end
			end
		end
		
		-- Trim, unless there are only spacing characters, while ignoring any final formatting characters.
		text = text and text
			:gsub("^([\128-\191\244]*)%s+(%S)", "%1%2")
			:gsub("(%S)%s+([\128-\191\244]*)$", "%1%2")
		
		-- Remove duplicate categories.
		if #cats > 1 then
			cats = require("table").removeDuplicates(cats)
		end
		
		return text, fail, cats, subbedChars
	end
	
	-- Process carets (and any escapes). Default to simple removal, if no pattern/replacement is given.
	local function processCarets(text, pattern, repl)
		local rep
		repeat
			text, rep = text:gsub("\\\\(\\*^)", "\3%1")
		until rep == 0
		return text
			:gsub("\\^", "\4")
			:gsub(pattern or "%^", repl or "")
			:gsub("\3", "\\")
			:gsub("\4", "^")
	end
	
	-- Remove carets if they are used to capitalize parts of transliterations (unless they have been escaped).
	local function removeCarets(text, sc)
		if not sc:hasCapitalization() and sc:isTransliterated() and text:match("%^") then
			return processCarets(text)
		else
			return text
		end
	end
	
	local Language = {}
	
	--[==[Returns the language code of the language. Example: {{code|lua|"fr"}} for French.]==]
	function Language:getCode()
		return self._code
	end
	
	--[==[Returns the canonical name of the language. This is the name used to represent that language on Wiktionary, and is guaranteed to be unique to that language alone. Example: {{code|lua|"French"}} for French.]==]
	function Language:getCanonicalName()
		return self._rawData[1]
	end
	
	--[==[Returns the display form of the language. The display form of a language, family or script is the form it takes when appearing as the ''SOURCE'' in categories such as <code>English terms derived from ''SOURCE''</code> or <code>English given names from ''SOURCE''</code>, and is also the displayed text in <code>:makeCategoryLink</code> links. For regular and etymology languages, this is the same as the canonical name, but for families, it reads "NAME languages" (e.g. {{code|lua|"Indo-Iranian languages"}}), and for scripts, it reads "NAME script" (e.g. {{code|lua|"Arabic script"}}).]==]
	function Language:getDisplayForm()
		if not self._displayForm then
			local form = self:getCanonicalName()
			-- Add article and " substrate" if a substrate that lacks them.
			if self:getFamilyCode() == "qfa-sub" then
				if not (form:find("^[Tt]he ") or form:find("^[Aa] ")) then
					form = "a " .. form
				end
				if not form:find("[Ss]ubstrate") then
					form = form .. " substrate"
				end
			end
			self._displayForm = form
		end
		return self._displayForm
	end
	
	--[==[Returns a table of the "other names" that the language is known by, excluding the canonical name. The names are not guaranteed to be unique, in that sometimes more than one language is known by the same name. Example: {{code|lua|{"Manx Gaelic", "Northern Manx", "Southern Manx"} }} for [[:Category:Manx language|Manx]]. If <code>onlyOtherNames</code> is given and is non-{{code|lua|nil}}, only names explicitly listed in the <code>otherNames</code> field are returned; otherwise, names listed under <code>otherNames</code>, <code>aliases</code> and <code>varieties</code> are combined together and returned. For example, for Manx, Manx Gaelic is listed as an alias, while Northern Manx and Southern Manx are listed as varieties. It should be noted that the <code>otherNames</code> field itself is deprecated, and entries listed there should eventually be moved to either <code>aliases</code> or <code>varieties</code>.]==]
	function Language:getOtherNames(onlyOtherNames)
		if #self._stack == 1 then
			self:loadInExtraData()
		end
		return require("language-like").getOtherNames(self, onlyOtherNames)
	end
	
	--[==[Returns a table of the aliases that the language is known by, excluding the canonical name. Aliases are synonyms for the language in question. The names are not guaranteed to be unique, in that sometimes more than one language is known by the same name. Example: {{code|lua|{"High German", "New High German", "Deutsch"} }} for [[:Category:German language|German]].]==]
	function Language:getAliases()
		if #self._stack == 1 then
			self:loadInExtraData()
		end
		return self._rawData.aliases or (self._extraData and self._extraData.aliases) or {}
	end
	
	--[==[Returns a table of the known subvarieties of a given language, excluding subvarieties that have been given explicit etymology language codes. The names are not guaranteed to be unique, in that sometimes a given name refers to a subvariety of more than one language. Example: {{code|lua|{"Southern Aymara", "Central Aymara"} }} for [[:Category:Aymara language|Aymara]]. Note that the returned value can have nested tables in it, when a subvariety goes by more than one name. Example: {{code|lua|{"North Azerbaijani", "South Azerbaijani", {"Afshar", "Afshari", "Afshar Azerbaijani", "Afchar"}, {"Qashqa'i", "Qashqai", "Kashkay"}, "Sonqor"} }} for [[:Category:Azerbaijani language|Azerbaijani]]. Here, for example, Afshar, Afshari, Afshar Azerbaijani and Afchar all refer to the same subvariety, whose preferred name is Afshar (the one listed first). To avoid a return value with nested tables in it, specify a non-{{code|lua|nil}} value for the <code>flatten</code> parameter; in that case, the return value would be {{code|lua|{"North Azerbaijani", "South Azerbaijani", "Afshar", "Afshari", "Afshar Azerbaijani", "Afchar", "Qashqa'i", "Qashqai", "Kashkay", "Sonqor"} }}.]==]
	function Language:getVarieties(flatten)
		if #self._stack == 1 then
			self:loadInExtraData()
		end
		return require("language-like").getVarieties(self, flatten)
	end
	
	--[==[Given a list of types as strings, returns true if the language has all of them. 

The possible types are
	* {language}: This is a language, either full or etymology-only.
	* {full}: This is a "full" (not etymology-only) language, i.e. the union of {regular}, {reconstructed} and
			  {appendix-constructed}. Note that the types {full} and {etymology-only} also exist for families, so if you
			  want to check specifically for a full language and you have an object that might be a family, you should
			  use {{lua|hasType("language", "full")}} and not simply {{lua|hasType("full")}}.
	* {etymology-only}: This is an etymology-only (not full) language, whose parent is another etymology-only
						language or a full language. Note that the types {full} and {etymology-only} also exist for
						families, so if you want to check specifically for an etymology-only language and you have an
						object that might be a family, you should use {{lua|hasType("language", "etymology-only")}}
						and not simply {{lua|hasType("etymology-only")}}.
	* {regular}: This indicates a full language that is attested according to [[WT:CFI]] and therefore permitted
				 in the main namespace. There may also be reconstructed terms for the language, which are placed in
				 the {Reconstruction} namespace and must be prefixed with * to indicate a reconstruction. Most full
				 languages are natural (not constructed) languages, but a few constructed languages (e.g. Esperanto
				 and Volapük, among others) are also allowed in the mainspace and considered regular languages.
	* {reconstructed}: This language is not attested according to [[WT:CFI]], and therefore is allowed only in the
					   {Reconstruction} namespace. All terms in this language are reconstructed, and must be prefixed
					   with *. Languages such as Proto-Indo-European and Proto-Germanic are in this category.
	* {appendix-constructed}: This language is attested but does not meet the additional requirements set out for
							  constructed languages ([[WT:CFI#Constructed languages]]). Its entries must therefore
							  be in the Appendix namespace, but they are not reconstructed and therefore should
							  not have * prefixed in links.
]==]	
	function Language:hasType(...)
		if not self._type then
			self._type = {language = true}
			if self:getNonEtymologicalCode() == self:getCode() then
				self._type.full = true
			else
				self._type["etymology-only"] = true
			end
			for _, type in ipairs(mw.text.split(self._rawData.type, "%s*,%s*")) do
				self._type[type] = true
			end
		end
		for _, type in ipairs{...} do
			if not self._type[type] then
				return false
			end
		end
		return true
	end
	
	--[==[Returns a table containing <code>WikimediaLanguage</code> objects (see [[Module:wikimedia languages]]), which represent languages and their codes as they are used in Wikimedia projects for interwiki linking and such. More than one object may be returned, as a single Wiktionary language may correspond to multiple Wikimedia languages. For example, Wiktionary's single code <code>sh</code> (Serbo-Croatian) maps to four Wikimedia codes: <code>sh</code> (Serbo-Croatian), <code>bs</code> (Bosnian), <code>hr</code> (Croatian) and <code>sr</code> (Serbian).
	The code for the Wikimedia language is retrieved from the <code>wikimedia_codes</code> property in the data modules. If that property is not present, the code of the current language is used. If none of the available codes is actually a valid Wikimedia code, an empty table is returned.]==]
	function Language:getWikimediaLanguages()
		if not self._wikimediaLanguageObjects then
			local m_wikimedia_languages = require("wikimedia languages")
			self._wikimediaLanguageObjects = {}
			local wikimedia_codes = self:getWikimediaLanguageCodes()
			for _, wlangcode in ipairs(wikimedia_codes) do
				insert(self._wikimediaLanguageObjects, m_wikimedia_languages.getByCode(wlangcode))
			end
		end
		return self._wikimediaLanguageObjects
	end
	
	function Language:getWikimediaLanguageCodes()
		if not self._wikimediaLanguageCodes then
			self._wikimediaLanguageCodes = self._rawData.wikimedia_codes or {self:getCode()}
		end
		return self._wikimediaLanguageCodes
	end
	
	--[==[
	Returns the name of the Wikipedia article for the language. If the property {wikipedia_article} is present in the
	data module it will be used first, otherwise a sitelink will be generated from {:getWikidataItem} (if set). Otherwise
	{:getCategoryName} is used as fallback, unless `noCategoryFallback` is specified, in which case {nil} is returned.]==]
	function Language:getWikipediaArticle(noCategoryFallback)
		if self._wikipedia_article == nil then
			if self._rawData.wikipedia_article then
				self._wikipedia_article = self._rawData.wikipedia_article
			elseif self:getWikidataItem() and mw.wikibase then
				self._wikipedia_article = mw.wikibase.sitelink(self:getWikidataItem(), 'enwiki')
			end
			if not self._wikipedia_article then
				self._wikipedia_article = false
			end
		end
		if not self._wikipedia_article and not noCategoryFallback then
			return self:getCategoryName():gsub("Creole language", "Creole")
		end
		return self._wikipedia_article or nil
	end
	
	function Language:makeWikipediaLink()
		return "[[w:" .. self:getWikipediaArticle() .. "|" .. self:getCanonicalName() .. "]]"
	end
	
	--[==[Returns the Wikidata item id for the language or <code>nil</code>. This corresponds to the the second field in the data modules.]==]
	function Language:getWikidataItem()
		if not self._WikidataItem then
			local item = self._rawData[2]
			if type(item) == "number" then
				self._WikidataItem = "Q" .. item
			else
				self._WikidataItem = item
			end
		end
		return self._WikidataItem
	end
	
	--[==[Returns a table of <code>Script</code> objects for all scripts that the language is written in. See [[Module:scripts]].]==]
	function Language:getScripts()
		if not self._scriptObjects then
			self._scriptObjects = {}
			if self:getScriptCodes()[1] == "All" then
				self._scriptObjects = conditionalRequire("Module:scripts/data")
			else
				for _, sc in ipairs(self:getScriptCodes()) do
					insert(self._scriptObjects, require("scripts").getByCode(sc, nil, nil, useRequire))
				end
			end
		end
		return self._scriptObjects
	end
	
	--[==[Returns the table of script codes in the language's data file.]==]
	function Language:getScriptCodes()
		if not self._scriptCodes then
			self._scriptCodes = self._rawData[4] or {"None"}
		end
		return self._scriptCodes
	end
	
	--[==[Given some text, this function iterates through the scripts of a given language and tries to find the script that best matches the text. It returns a {{code|lua|Script}} object representing the script. If no match is found at all, it returns the {{code|lua|None}} script object.]==]
	function Language:findBestScript(text, forceDetect)
		if (not text) or text == "" or text == "-" then
			return require("scripts").getByCode("None", nil, nil, useRequire)
		end
		
		if table.concat(self:getScriptCodes()) == "All" then
			return require("scripts").findBestScriptWithoutLang(text)
		end
		
		local scripts = self:getScripts()
		
		if not scripts[2] and not forceDetect then
			-- Necessary, because Hani covers the entire Han range (while the Hant & Hans lists don't list shared characters).
			if scripts[1]:getCode():match("^Han") and require("scripts").getByCode("Hani", nil, nil, useRequire):countCharacters(text) > 0 then
				return scripts[1]
			elseif scripts[1]:countCharacters(text) > 0 then
				return scripts[1]
			else
				return require("scripts").getByCode("None", nil, nil, useRequire)
			end
		end
		
		return require("languages/findBestScript")(export, self, text, scripts, forceDetect, useRequire)
	end
	
	--[==[Returns a <code>Family</code> object for the language family that the language belongs to. See [[Module:families]].]==]
	function Language:getFamily()
		if self._familyObject == nil then
			local familyCode = self:getFamilyCode()
			if familyCode then
				self._familyObject = require("families").getByCode(familyCode, useRequire)
			-- Still memoize a nil result.
			else
				self._familyObject = false
			end
		end
		return self._familyObject or nil
	end
	
	--[==[Returns the family code in the language's data file.]==]
	function Language:getFamilyCode()
		if not self._familyCode then
			self._familyCode = self._rawData[3]
		end
		return self._familyCode
	end
	
	function Language:getFamilyName()
		if self._familyName == nil then
			local family = self:getFamily()
			if family then
				self._familyName = family:getCanonicalName()
			else
				self._familyName = false
			end
		end
		return self._familyName or nil
	end
	
	--[==[Check whether the language belongs to `family` (which can be a family code or object). A list of objects can be given in place of `family`; in that case, return true if the language belongs to any of the specified families. Note that some languages (in particular, certain creoles) can have multiple immediate ancestors potentially belonging to different families; in that case, return true if the language belongs to any of the specified families.]==]
	function Language:inFamily(...)
		--checkObject("family", nil, ...)
		for _, family in ipairs{...} do
			if type(family) == "table" then
				family = family:getCode()
			end
			local self_family_code = self:getFamilyCode()
			if not self_family_code then
				return false
			elseif self_family_code == family then
				return true
			end
			local self_family = self:getFamily()
			if self_family:inFamily(family) then
				return true
			-- If the family isn't a real family (e.g. creoles) check any ancestors.
			elseif self_family:getFamilyCode() == "qfa-not" then
				local ancestors = self:getAncestors()
				for _, ancestor in ipairs(ancestors) do
					if ancestor:inFamily(family) then
						return true
					end
				end
			end
		end
		return false
	end
	
	function Language:getParent()
		if self._parentObject == nil then
			local parentCode = self:getParentCode()
			if parentCode then
				self._parentObject = export.getByCode(parentCode, nil, true, true, useRequire)
			else
				self._parentObject = false
			end
		end
		return self._parentObject or nil
	end
	
	function Language:getParentCode()
		if not self._parentCode then
			self._parentCode = self._rawData[5]
		end
		return self._parentCode
	end
	
	function Language:getParentName()
		if self._parentName == nil then
			local parent = self:getParent()
			if parent then
				self._parentName = parent:getCanonicalName()
			else
				self._parentName = false
			end
		end
		return self._parentName or nil
	end
	
	function Language:getParentChain()
		if not self._parentChain then
			self._parentChain = {}
			local parent = self:getParent()
			while parent do
				insert(self._parentChain, parent)
				parent = parent:getParent()
			end
		end
		return self._parentChain
	end
	
	function Language:hasParent(...)
		--checkObject("language", nil, ...)
		for _, otherlang in ipairs{...} do
			for _, parent in ipairs(self:getParentChain()) do
				if type(otherlang) == "string" then
					if otherlang == parent:getCode() then return true end
				else
					if otherlang:getCode() == parent:getCode() then return true end
				end
			end
		end
		return false
	end
	
	--[==[If the language is an etymology language, this iterates through parents until a regular language or family is found, and the corresponding object is returned. If the language is a regular language, then it simply returns the language.]==]
	function Language:getNonEtymological()
		if not self._nonEtymologicalObject then
			local nonEtymologicalCode = self:getNonEtymologicalCode()
			if nonEtymologicalCode ~= self:getCode() then
				self._nonEtymologicalObject = export.getByCode(nonEtymologicalCode, nil, nil, nil, useRequire)
			else
				self._nonEtymologicalObject = self
			end
		end
		return self._nonEtymologicalObject
	end
	
	function Language:getNonEtymologicalCode()
		return self._nonEtymologicalCode or self:getCode()
	end
	
	function Language:getNonEtymologicalName()
		if self._nonEtymologicalName == nil then
			local nonEtymological = self:getNonEtymological()
			if nonEtymological then
				self._nonEtymologicalName = nonEtymological:getCanonicalName()
			else
				self._nonEtymologicalName = false
			end
		end
		return self._nonEtymologicalName or nil
	end
	
	--[==[Returns a table of <code class="nf">Language</code> objects for all languages that this language is directly descended from. Generally this is only a single language, but creoles, pidgins and mixed languages can have multiple ancestors.]==]
	function Language:getAncestors()
		if not self._ancestorObjects then
			self._ancestorObjects = {}
			local ancestors = require("table").shallowcopy(self:getAncestorCodes())
			if #ancestors > 0 then
				for _, ancestor in ipairs(ancestors) do
					insert(self._ancestorObjects, export.getByCode(ancestor, nil, true, nil, useRequire))
				end
			else
				local fam = self:getFamily()
				local protoLang = fam and fam:getProtoLanguage() or nil
				-- For the cases where the current language is the proto-language
				-- of its family, or an etymology language that is ancestral to that
				-- proto-language, we need to step up a level higher right from the
				-- start.
				if protoLang and (
					protoLang:getCode() == self:getCode() or
					(self:hasType("etymology-only") and protoLang:hasAncestor(self))
				) then
					fam = fam:getFamily()
					protoLang = fam and fam:getProtoLanguage() or nil
				end
				while not protoLang and not (not fam or fam:getCode() == "qfa-not") do
					fam = fam:getFamily()
					protoLang = fam and fam:getProtoLanguage() or nil
				end
				insert(self._ancestorObjects, protoLang)
			end
		end
		return self._ancestorObjects
	end
	
	do
		-- Avoid a language being its own ancestor via class inheritance. We only need to check for this if the language has inherited an ancestor table from its parent, because we never want to drop ancestors that have been explicitly set in the data.
		-- Recursively iterate over ancestors until we either find self or run out. If self is found, return true.
		local function check_ancestor(self, lang)
			local codes = lang:getAncestorCodes()
			if not codes then
				return nil
			end
			for i = 1, #codes do
				local code = codes[i]
				if code == self:getCode() then
					return true
				end
				local anc = export.getByCode(code, nil, true, nil, useRequire)
				if check_ancestor(self, anc) then
					return true
				end
			end
		end
		
		--[==[Returns a table of <code class="nf">Language</code> codes for all languages that this language is directly descended from. Generally this is only a single language, but creoles, pidgins and mixed languages can have multiple ancestors.]==]
		function Language:getAncestorCodes()
			if self._ancestorCodes then
				return self._ancestorCodes
			elseif not self._rawData.ancestors then
				self._ancestorCodes = {}
				return self._ancestorCodes
			end
			local codes = self._rawData.ancestors
			self._ancestorCodes = codes
			if (
				#codes == 0 or
				#self._stack == 1 or
				self._stack[#self._stack].ancestors
			) then
				return codes
			end
			local i, code = 1
			while i <= #codes do
				code = codes[i]
				if check_ancestor(self, self) then
					remove(codes, i)
				else
					i = i + 1
				end
			end
			return codes
		end
	end
	
	--[==[Given a list of language objects or codes, returns true if at least one of them is an ancestor. This includes any etymology-only children of that ancestor. If the language's ancestor(s) are etymology-only languages, it will also return true for those language parent(s) (e.g. if Vulgar Latin is the ancestor, it will also return true for its parent, Latin). However, a parent is excluded from this if the ancestor is also ancestral to that parent (e.g. if Classical Persian is the ancestor, Persian would return false, because Classical Persian is also ancestral to Persian).]==]
	function Language:hasAncestor(...)
		--checkObject("language", nil, ...)
		
		local function iterateOverAncestorTree(node, func, parent_check)
			local ancestors = node:getAncestors()
			local ancestorsParents = {}
			for _, ancestor in ipairs(ancestors) do
				local ret = func(ancestor) or iterateOverAncestorTree(ancestor, func, parent_check)
				if ret then return ret end
			end
			-- Check the parents of any ancestors. We don't do this if checking the parents of the other language, so that we exclude any etymology-only children of those parents that are not directly related (e.g. if the ancestor is Vulgar Latin and we are checking New Latin, we want it to return false because they are on different ancestral branches. As such, if we're already checking the parent of New Latin (Latin) we don't want to compare it to the parent of the ancestor (Latin), as this would be a false positive; it should be one or the other).
			if not parent_check then
				return nil
			end
			for _, ancestor in ipairs(ancestors) do
				local ancestorParents = ancestor:getParentChain()
				for _, ancestorParent in ipairs(ancestorParents) do
					if ancestorParent:getCode() == self:getCode() or ancestorParent:hasAncestor(ancestor) then
						break
					else
						insert(ancestorsParents, ancestorParent)
					end
				end
			end
			for _, ancestorParent in ipairs(ancestorsParents) do
				local ret = func(ancestorParent)
				if ret then return ret end
			end
		end
		
		local function do_iteration(otherlang, parent_check)
			-- otherlang can't be self
			if (type(otherlang) == "string" and otherlang or otherlang:getCode()) == self:getCode() then
				return false
			end
			repeat
				if iterateOverAncestorTree(
					self,
					function(ancestor)
						return ancestor:getCode() == (type(otherlang) == "string" and otherlang or otherlang:getCode())
					end,
					parent_check
				) then
					return true
				elseif type(otherlang) == "string" then
					otherlang = export.getByCode(otherlang, nil, true, nil, useRequire)
				end
				otherlang = otherlang:getParent()
				parent_check = false
			until not otherlang
		end
		
		local parent_check = true
		for _, otherlang in ipairs{...} do
			local ret = do_iteration(otherlang, parent_check)
			if ret then
				return true
			end
		end
		return false
	end
	
	function Language:getAncestorChain()
		if not self._ancestorChain then
			self._ancestorChain = {}
			local step = self
			while true do
				local ancestors = step:getAncestors()
				step = #ancestors == 1 and ancestors[1] or nil
				if not step then break end
				insert(self._ancestorChain, 1, step)
			end
		end
		return self._ancestorChain
	end
	
	local function fetch_descendants(self, format)
		local languages = require("languages/code to canonical name")
		local etymology_languages = require("etymology languages/code to canonical name")
		local families = require("families/code to canonical name")
		local descendants = {}
		local family = self:getFamily()
		-- Iterate over all three datasets.
		for _, data in ipairs{languages, etymology_languages, families} do
			for code in pairs(data) do
				local lang = export.getByCode(code, nil, true, true, useRequire)
				-- Test for a descendant. Earlier tests weed out most candidates, while the more intensive tests are only used sparingly.
				if (
					code ~= self:getCode() and -- Not self.
					lang:inFamily(family) and -- In the same family.
					(
						family:getProtoLanguageCode() == self:getCode() or -- Self is the protolanguage.
						self:hasDescendant(lang) or -- Full hasDescendant check.
						(lang:getNonEtymologicalCode() == self:getCode() and not self:hasAncestor(lang)) -- Etymology-only child which isn't an ancestor.
					)
				) then
					if format == "object" then
						insert(descendants, lang)
					elseif format == "code" then
						insert(descendants, code)
					elseif format == "name" then
						insert(descendants, lang:getCanonicalName())
					end
				end
			end
		end
		return descendants
	end
	
	function Language:getDescendants()
		if not self._descendantObjects then
			self._descendantObjects = fetch_descendants(self, "object")
		end
		return self._descendantObjects
	end
	
	function Language:getDescendantCodes()
		if not self._descendantCodes then
			self._descendantCodes = fetch_descendants(self, "code")
		end
		return self._descendantCodes
	end
	
	function Language:getDescendantNames()
		if not self._descendantNames then
			self._descendantNames = fetch_descendants(self, "name")
		end
		return self._descendantNames
	end
	
	function Language:hasDescendant(...)
		for _, lang in ipairs{...} do
			if type(lang) == "string" then
				lang = export.getByCode(lang, nil, true, nil, useRequire)
			end
			if lang:hasAncestor(self) then
				return true
			end
		end
		return false
	end
	
	local function fetch_children(self, format)
		local m_etym_data = require("etymology languages/data")
		local self_code = self:getCode()
		local children = {}
		for code, data in pairs(m_etym_data) do
			local _data = data
			repeat
				parent = _data[5]
				if parent == self_code then
					if format == "object" then
						insert(children, export.getByCode(code, nil, true, nil, useRequire))
					elseif format == "code" then
						insert(children, code)
					elseif format == "name" then
						insert(children, data[1])
					end
					break
				end
				_data = m_etym_data[parent]
			until not _data
		end
		return children
	end
	
	function Language:getChildren()
		if not self._childObjects then
			self._childObjects = fetch_children(self, "object")
		end
		return self._childObjects
	end
	
	function Language:getChildrenCodes()
		if not self._childCodes then
			self._childCodes = fetch_children(self, "code")
		end
		return self._childCodes
	end
	
	function Language:getChildrenNames()
		if not self._childNames then
			self._childNames = fetch_children(self, "name")
		end
		return self._childNames
	end
	
	function Language:hasChild(...)
		local lang = ...
		if not lang then
			return false
		elseif type(lang) == "string" then
			lang = export.getByCode(lang, nil, true, nil, useRequire)
		end
		if lang:hasParent(self) then
			return true
		end
		return self:hasChild(select(2, ...))
	end
	
	--[==[Returns the name of the main category of that language. Example: {{code|lua|"French language"}} for French, whose category is at [[:Category:French language]]. Unless optional argument <code>nocap</code> is given, the language name at the beginning of the returned value will be capitalized. This capitalization is correct for category names, but not if the language name is lowercase and the returned value of this function is used in the middle of a sentence.]==]
	function Language:getCategoryName(nocap)
		if not self._categoryName then
			local name = self:getCanonicalName()
			-- Only add " language" if a regular language.
			if #self._stack == 1 then
				-- If the name already has "language" in it, don't add it.
				if not name:match("[Ll]anguage$") then
					name = name .. " language"
				end
			end
			self._categoryName = name
		end
		if nocap then
			return self._categoryName
		else
			return mw.getContentLanguage():ucfirst(self._categoryName)
		end
	end
	
	--[==[Creates a link to the category; the link text is the canonical name.]==]
	function Language:makeCategoryLink()
		return "[[:Category:" .. self:getCategoryName() .. "|" .. self:getDisplayForm() .. "]]"
	end
	
	function Language:getStandardCharacters(sc)
		if type(self._rawData.standardChars) ~= "table" then
			return self._rawData.standardChars
		else
			if sc and type(sc) ~= "string" then
				checkObject("script", nil, sc)
				sc = sc:getCode()
			end
			if (not sc) or sc == "None" then
				local scripts = {}
				for _, script in pairs(self._rawData.standardChars) do
					insert(scripts, script)
				end
				return table.concat(scripts)
			end
			if self._rawData.standardChars[sc] then
				return self._rawData.standardChars[sc] .. (self._rawData.standardChars[1] or "")
			end
		end
	end
	
	--[==[Make the entry name (i.e. the correct page name).]==]
	function Language:makeEntryName(text, sc)
		if (not text) or text == "" then
			return text, nil, {}
		end
		
		-- Remove directional characters.
		text = remove_directional_chars(text)
		
		-- Set `unsupported` as true if certain conditions are met.
		local unsupported
		-- Check if there's an unsupported character. \239\191\189 is the replacement character U+FFFD, which can't be typed directly here due to an abuse filter. Unix-style dot-slash notation is also unsupported, as it is used for relative paths in links, as are 3 or more consecutive tildes.
		if (
			text:find("[#<>%[%]_{|}]") or
			text:find("\239\191\189") or
			text:find("%f[^%z/]%.%.?%f[%z/]") or
			text:find("~~~")
		) then
			unsupported = true
		-- If it looks like an interwiki link.
		elseif text:find(":") then
			local prefix = text:gsub("^:*(.-):.*", string.ulower)
			if (
				conditionalRequire("Module:data/namespaces")[prefix] or
				conditionalRequire("Module:data/interwikis")[prefix]
			) then
				unsupported = true
			end
		end
		
		-- Check if the text is a listed unsupported title.
		local unsupportedTitles = conditionalRequire("Module:links/data").unsupported_titles
		if unsupportedTitles[text] then
			return "Unsupported titles/" .. unsupportedTitles[text], nil, {}
		end
		
		sc = checkScript(text, self, sc)
		
		local fail, cats
		text = normalize(text, sc)
		text, fail, cats = iterateSectionSubstitutions(text, nil, nil, self, sc, self._rawData.entry_name, "makeEntryName")
		
		text = ugsub(text, "^[¿¡]?([^%s%p]+)%s*[؟?!;՛՜ ՞ ՟？！︖︕।॥။၊་།]?$", "%1") or text
		
		
		-- Escape unsupported characters so they can be used in titles. ` is used as a delimiter for this, so a raw use of it in an unsupported title is also escaped here to prevent interference; this is only done with unsupported titles, though, so inclusion won't in itself mean a title is treated as unsupported (which is why it's excluded from the earlier test).
		if unsupported then
			local unsupported_characters = conditionalRequire("Module:links/data").unsupported_characters
			text = text
				:gsub("[#<>%[%]_`{|}\239]\191?\189?", unsupported_characters)
				:gsub("%f[^%z/]%.%.?%f[%z/]", function(m)
					return m:gsub("%.", "`period`")
				end)
				:gsub("~~~+", function(m)
					return m:gsub("~", "`tilde`")
				end)
			text = "Unsupported titles/" .. text
		end
		
		return text, fail, cats
	end
	
	--[==[Generates alternative forms using a specified method, and returns them as a table. If no method is specified, returns a table containing only the input term.]==]
	function Language:generateForms(text, sc)
		if self._rawData.generate_forms then
			sc = checkScript(text, self, sc)
			return require("" .. self._rawData.generate_forms).generateForms(text, self:getCode(), sc:getCode())
		else
			return {text}
		end
	end
	
	--[==[Creates a sort key for the given entry name, following the rules appropriate for the language. This removes diacritical marks from the entry name if they are not considered significant for sorting, and may perform some other changes. Any initial hyphen is also removed, and anything parentheses is removed as well.
	The <code>sort_key</code> setting for each language in the data modules defines the replacements made by this function, or it gives the name of the module that takes the entry name and returns a sortkey.]==]
	function Language:makeSortKey(text, sc)
		if (not text) or text == "" then
			return text, nil, {}
		end
		if text:find("<[^<>]+>") then
			track("track HTML tag")
		end
		-- Remove directional characters, soft hyphens, strip markers and HTML tags.
		text = ugsub(text, "[\194\173" .. dir_char .. "]", "")
		text = mw.text.unstrip(text)
			:gsub("<[^<>]+>", "")
		
		text = mw.uri.decode(text, "PATH")
		text = checkNoEntities(text)
		
		-- Remove initial hyphens and * unless the term only consists of spacing + punctuation characters.
		text = ugsub(text, "^([􀀀-􏿽]*)[-־ـ᠊*]+([􀀀-􏿽]*)(.*[^%s%p].*)", "%1%2%3")
		
		sc = checkScript(text, self, sc)
		
		text = normalize(text, sc)
		text = removeCarets(text, sc)
		
		-- For languages with dotted dotless i, ensure that "İ" is sorted as "i", and "I" is sorted as "ı".
		if self:hasDottedDotlessI() then
			text = text
				:gsub(mw.ustring.toNFD("İ"), "i")
				:gsub("I", "ı")
			text = sc:toFixedNFD(text)
		end
		-- Convert to lowercase, make the sortkey, then convert to uppercase. Where the language has dotted dotless i, it is usually not necessary to convert "i" to "İ" and "ı" to "I" first, because "I" will always be interpreted as conventional "I" (not dotless "İ") by any sorting algorithms, which will have been taken into account by the sortkey substitutions themselves. However, if no sortkey substitutions have been specified, then conversion is necessary so as to prevent "i" and "ı" both being sorted as "I".
		-- An exception is made for scripts that (sometimes) sort by scraping page content, as that means they are sensitive to changes in capitalization (as it changes the target page).
		local fail, cats
		if not sc:sortByScraping() then
			text = text:ulower()
		end
		
		text, fail, cats = iterateSectionSubstitutions(text, nil, nil, self, sc, self._rawData.sort_key, "makeSortKey")
		
		if not sc:sortByScraping() then
			if self:hasDottedDotlessI() and not self._rawData.sort_key then
				text = text
					:gsub("ı", "I")
					:gsub("i", "İ")
				text = sc:toFixedNFC(text)
			end
			text = text:uupper()
		end
		
		-- Remove parentheses, as long as they are either preceded or followed by something.
		text = text
			:gsub("(.)[()]+", "%1")
			:gsub("[()]+(.)", "%1")
		
		text = escape_risky_characters(text)
		return text, fail, cats
	end
	
	--[==[Create the form used as as a basis for display text and transliteration.]==]
	local function processDisplayText(text, self, sc, keepCarets, keepPrefixes)
		local subbedChars = {}
		text, subbedChars = doTempSubstitutions(text, subbedChars, keepCarets)
		
		text = mw.uri.decode(text, "PATH")
		text = checkNoEntities(text)
		
		sc = checkScript(text, self, sc)
		local fail, cats
		text = normalize(text, sc)
		text, fail, cats, subbedChars = iterateSectionSubstitutions(text, subbedChars, keepCarets, self, sc, self._rawData.display_text, "makeDisplayText")
		
		text = removeCarets(text, sc)
		
		-- Remove any interwiki link prefixes (unless they have been escaped or this has been disabled).
		if text:match(":") and not keepPrefixes then
			local rep
			repeat
				text, rep = text:gsub("\\\\(\\*:)", "\3%1")
			until rep == 0
			text = text
				:gsub("\\:", "\4")
			while true do
				local prefix = text:gsub("^(.-):.+", function(m1)
					return m1:gsub("\244[\128-\191]*", "")
				end)
				if not prefix or prefix == text then
					break
				end
				local lower_prefix = prefix:ulower()
				if not (conditionalRequire("Module:data/interwikis")[lower_prefix] or prefix == "") then
					break
				end
				text = text:gsub("^(.-):(.*)", function(m1, m2)
					local ret = {}
					for subbedChar in m1:gmatch("\244[\128-\191]*") do
						insert(ret, subbedChar)
					end
					return table.concat(ret) .. m2
				end)
			end
			text = text
				:gsub("\3", "\\")
				:gsub("\4", ":")
		end
		
		return text, fail, cats, subbedChars
	end
	
	--[==[Make the display text (i.e. what is displayed on the page).]==]
	function Language:makeDisplayText(text, sc, keepPrefixes)
		if (not text) or text == "" then
			return text, nil, {}
		end
		
		text = remove_directional_chars(text)
		
		local fail, cats, subbedChars
		text, fail, cats, subbedChars = processDisplayText(text, self, sc, nil, keepPrefixes)
		
		text = escape_risky_characters(text)
		return undoTempSubstitutions(text, subbedChars), fail, cats
	end
	
	--[==[Transliterates the text from the given script into the Latin script (see [[Wiktionary:Transliteration and romanization]]). The language must have the <code>translit</code> property for this to work; if it is not present, {{code|lua|nil}} is returned.
	Returns three values:
	# The transliteration.
	# A boolean which indicates whether the transliteration failed for an unexpected reason. If {{code|lua|false}}, then the transliteration either succeeded, or the module is returning nothing in a controlled way (e.g. the input was {{code|lua|"-"}}). Generally, this means that no maintenance action is required. If {{code|lua|true}}, then the transliteration is {{code|lua|nil}} because either the input or output was defective in some way (e.g. [[Module:ar-translit]] will not transliterate non-vocalised inputs, and this module will fail partially-completed transliterations in all languages). Note that this value can be manually set by the transliteration module, so make sure to cross-check to ensure it is accurate.
	# A table of categories selected by the transliteration module, which should be in the format expected by {{code|lua|format_categories}} in [[Module:utilities]].
	The <code>sc</code> parameter is handled by the transliteration module, and how it is handled is specific to that module. Some transliteration modules may tolerate {{code|lua|nil}} as the script, others require it to be one of the possible scripts that the module can transliterate, and will show an error if it's not one of them. For this reason, the <code>sc</code> parameter should always be provided when writing non-language-specific code.
	The <code>module_override</code> parameter is used to override the default module that is used to provide the transliteration. This is useful in cases where you need to demonstrate a particular module in use, but there is no default module yet, or you want to demonstrate an alternative version of a transliteration module before making it official. It should not be used in real modules or templates, only for testing. All uses of this parameter are tracked by [[Template:tracking/module_override]].
	'''Known bugs''':
	* This function assumes {tr(s1) .. tr(s2) == tr(s1 .. s2)}. When this assertion fails, wikitext markups like <nowiki>'''</nowiki> can cause wrong transliterations.
	* HTML entities like <code>&amp;apos;</code>, often used to escape wikitext markups, do not work.]==]
	function Language:transliterate(text, sc, module_override)
		-- If there is no text, or the language doesn't have transliteration data and there's no override, return nil.
		if not (self._rawData.translit or module_override) then
			return nil, false, {}
		elseif (not text) or text == "" or text == "-" then
			return text, false, {}
		end
		-- If the script is not transliteratable (and no override is given), return nil.
		sc = checkScript(text, self, sc)
		if not (sc:isTransliterated() or module_override) then
			return nil, true, {}
		end
		
		-- Remove any strip markers and directional characters.
		text = mw.text.unstrip(text)
		text = remove_directional_chars(text)
		
		-- Get the display text with the keepCarets flag set.
		local fail, cats, subbedChars
		text, fail, cats, subbedChars = processDisplayText(text, self, sc, true)
		
		-- Transliterate (using the module override if applicable).
		text, fail, cats, subbedChars = iterateSectionSubstitutions(text, subbedChars, true, self, sc, module_override or self._rawData.translit, "tr")
		
		-- Incomplete transliterations return nil.
		if text then
			if sc:countCharacters(text) > 0 then
				-- Remove any characters in Latin, which includes Latin characters also included in other scripts (as these are false positives). Anything remaining should only be script code "None" (e.g. numerals).
				local check_text = ugsub(text, "[" .. require("scripts").getByCode("Latn"):getCharacters() .. "]", "")
				if require("scripts").findBestScriptWithoutLang(check_text) ~= "None" then
					return nil, true, cats
				end
			end
		else
			return nil, true, cats
		end
		
		text = escape_risky_characters(text)
		text = undoTempSubstitutions(text, subbedChars)
		
		-- If the script does not use capitalization, then capitalize any letters of the transliteration which are immediately preceded by a caret (and remove the caret).
		if text and not sc:hasCapitalization() and text:match("%^") then
			text = processCarets(text, "%^([\128-\191\244]*%*?)([^\128-\191\244][\128-\191]*)", function(m1, m2)
				return m1 .. m2:uupper()
			end)
		end
		
		-- Track module overrides.
		if module_override ~= nil then
			track("module_override")
		end
		
		fail = text == nil and (not not fail) or false
		
		return text, fail, cats
	end
	
	function Language:overrideManualTranslit()
		return not not self._rawData.override_translit
	end
	
	--[==[Returns {{code|lua|true}} if the language has a transliteration module, or {{code|lua|false}} if it doesn't.]==]
	function Language:hasTranslit()
		return not not self._rawData.translit
	end
	
	function Language:link_tr()
		return not not self._rawData.link_tr
	end
	
	--[==[Returns {{code|lua|true}} if the language uses the letters I/ı and İ/i, or {{code|lua|false}} if it doesn't.]==]
	function Language:hasDottedDotlessI()
		return not not self._rawData.dotted_dotless_i
	end
	
	function Language:toJSON(returnTable)
		local entryNamePatterns = nil
		local entryNameRemoveDiacritics = nil
		
		if self._rawData.entry_name then
			entryNameRemoveDiacritics = self._rawData.entry_name.remove_diacritics
			if self._rawData.entry_name.from then
				entryNamePatterns = {}
				for i, from in ipairs(self._rawData.entry_name.from) do
					insert(entryNamePatterns, {from = from, to = self._rawData.entry_name.to[i] or ""})
				end
			end
		end
		
		if not self._type then
			self:hasType()
		end
		local types = {}
		for type in pairs(self._type) do
			insert(types, type)
		end

		-- mainCode should only end up non-nil if dontCanonicalizeAliases is passed to make_object().
		local ret = {
			ancestors = self:getAncestorCodes(),
			canonicalName = self:getCanonicalName(),
			categoryName = self:getCategoryName("nocap"),
			code = self:getCode(),
			mainCode = self._main_code,
			entryNamePatterns = entryNamePatterns,
			entryNameRemoveDiacritics = entryNameRemoveDiacritics,
			family = self:getFamilyCode(),
			otherNames = self:getOtherNames(true),
			aliases = self:getAliases(),
			varieties = self:getVarieties(),
			scripts = self:getScriptCodes(),
			parent = self._parentCode or nil,
			nonEtymological = self._nonEtymologicalCode or nil,
			type = types,
			wikimediaLanguages = self:getWikimediaLanguageCodes(),
			wikidataItem = self:getWikidataItem(),
		}
		
		ret = require("table").deepcopy(ret)
	
		if returnTable then
			return ret
		else
			return require("JSON").toJSON(ret)
		end
	end
	
	--[==[
	<span style="color: #BA0000">This function is not for use in entries or other content pages.</span>
	Returns a blob of data about the language. The format of this blob is undocumented, and perhaps unstable; it's intended for things like the module's own unit-tests, which are "close friends" with the module and will be kept up-to-date as the format changes.
	-- Do NOT use these methods!
	-- All uses should be pre-approved on the talk page!
	]==]
	function Language:getRawData()
		local rawData = {}
		for _, element in ipairs(self._stack) do
			for k, v in pairs(element) do
				rawData[k] = v
			end
		end
		return rawData
	end
	
	--[==[<span style="color: #BA0000">This function is not for use in entries or other content pages.</span>
	Returns a blob of data about the language that contains the "extra data". Much like with getRawData, the format of this blob is undocumented, and perhaps unstable; it's intended for things like the module's own unit-tests, which are "close friends" with the module and will be kept up-to-date as the format changes.]==]
	function Language:getRawExtraData()
		if #self._stack == 1 then
			self:loadInExtraData()
		end
		return self._extraData
	end
	
	local function getRawExtraLanguageData(code)
		local modulename = export.getExtraDataModuleName(code)
		return modulename and conditionalRequire("Module:" .. modulename)[code] or nil
	end

	function Language:loadInExtraData()
		if not self._extraData then
			-- load extra data from module and assign to _extraData field
			-- use empty table as a fallback if extra data is nil
			self._extraData = getRawExtraLanguageData(self:getCode()) or {}
		end
	end
	
	return Language
end

function export.getDataModuleName(code)
	if code:match("^%l%l$") then
		return "languages/data/2"
	elseif code:match("^%l%l%l$") then
		local prefix = code:sub(1, 1)
		return "languages/data/3/" .. prefix
	elseif code:match("^[%l-]+$") then
		return "languages/data/exceptional"
	else
		return nil
	end
end

function export.getExtraDataModuleName(code)
	local dataModule = export.getDataModuleName(code)
	return dataModule and dataModule .. "/extra" or nil
end

do
	-- Data that isn't inherited from the parent.
	local function no_inherit(lang, t, k)
		if (
			k == 2 or -- wikidata item
			k == "aliases" or
			k == "varieties" or
			k == "otherNames"
		) then
			return lang._stack[#lang._stack][k], true
		end
	end
	
	-- Data that is appended by each generation.
	local function append_data(lang, t, k)
		if k == "type" then
			local parts = {}
			for i = 1, #lang._stack do
				insert(parts, lang._stack[i][k])
			end
			if type(parts[1]) == "string" then
				return table.concat(parts, ", "), true
			end
			return nil, true
		end
	end
	
	local function inherit_data(lang, t, k)
		local i = #lang._stack
		while not lang._stack[i][k] and i > 1 do
			i = i - 1
		end
		return lang._stack[i][k]
	end
	
	local function make_stack(code, input_code, data, parent, useRequire)
		parent.__index = parent
		
		local lang = {_code = input_code}
		-- This can only happen if dontCanonicalizeAliases is passed to make_object().
		if code ~= input_code then
			lang._main_code = code
		end
		
		-- Full language.
		if not parent._stack then
			-- Create stack, accessed with rawData metamethod.
			lang._stack = parent._rawData and {parent._rawData, data} or {data}
			lang._rawData = setmetatable({}, {
				__index = function(t, k)
					-- Otherwise, iterate down the stack, looking for a match.
					local ret, stop_now = no_inherit(lang, t, k)
					if not stop_now then
						ret, stop_now = append_data(lang, t, k)
					end
					if not stop_now then
						ret = inherit_data(lang, t, k)
					end
					if (
						k == 4 or
						k == "ancestors" or
						k == "wikimedia_codes"
					) then
						if type(ret) == "table" then
							return ret
						elseif type(ret) == "string" then
							return mw.text.split(ret, "%s*,%s*")
						end
					else
						return ret
					end
				end,
				-- Retain immutability (as writing to rawData will break functionality).
				__newindex = function()
					error("not allowed to edit rawData")
				end
			})
			-- Non-etymological code is the parent code.
			lang._nonEtymologicalCode = parent._code or code
		-- Etymology-only.
		else
			-- Copy over rawData and stack to the new object, and add new layer to stack.
			lang._rawData = parent._rawData
			lang._stack = parent._stack
			insert(lang._stack, data)
			-- Copy non-etymological code.
			lang._nonEtymologicalCode = parent._nonEtymologicalCode
		end
		
		return setmetatable(lang, parent)
	end
	
	function export.makeObject(code, data, useRequire, dontCanonicalizeAliases)
		if not data then
			return nil
		end
		
		-- Convert any aliases.
		local input_code = code
		code = normalize_code(code)
		input_code = dontCanonicalizeAliases and input_code or code
	
		if data.type:find("family") and not data[5] then
			return require("families").makeObject(code, data, useRequire)
		else
			local parent
			if data[5] then
				parent = export.getByCode(data[5], nil, true, true, useRequire)
			else
				parent = make_language(code, data, useRequire)
			end
			return make_stack(code, input_code, data, parent, useRequire)
		end
	end
end

--[==[Finds the language whose code matches the one provided. If it exists, it returns a <code class="nf">Language</code> object representing the language. Otherwise, it returns {{code|lua|nil}}, unless <code class="n">paramForError</code> is given, in which case an error is generated. If <code class="n">paramForError</code> is {{code|lua|true}}, a generic error message mentioning the bad code is generated; otherwise <code class="n">paramForError</code> should be a string or number specifying the parameter that the code came from, and this parameter will be mentioned in the error message along with the bad code. If <code class="n">allowEtymLang</code> is specified, etymology language codes are allowed and looked up along with normal language codes. If <code class="n">allowFamily</code> is specified, language family codes are allowed and looked up along with normal language codes.]==]
function export.getByCode(code, paramForError, allowEtymLang, allowFamily, useRequire)
	if type(code) ~= "string" then
		local typ
		if not code then
			typ = "nil"
		elseif checkObject("language", true, code) then
			typ = "a language object"
		elseif checkObject("family", true, code) then
			typ = "a family object"
		else
			typ = "a " .. type(code)
		end
		error("The function getByCode expects a string as its first argument, but received " .. typ .. ".")
	end
	
	local function conditionalRequire(modulename)
		if useRequire then
			return require(modulename)
		else
			return mw.loadData(modulename)
		end
	end

	-- FIXME: Temporary. Lists bad codes to track, so we can consider eliminating them.
	-- We list them directly here rather than in a separate module (cf. [[Module:etymology languages/track-bad-etym-code]])
	-- in the hope that this reduces memory usage as we have to do this for every invocation of getByCode() for every
	-- language code.
	local codes_to_track = {
		-- Codes duplicated been full and etymology-only languages
		["bsg"] = true,
		["rdb"] = true,
		["tgf"] = true,
		-- Codes that will be converted to families
		["kca"] = true,
		["mns"] = true,
		["nan"] = true,
	}

	local function track_bad_code(code)
		if codes_to_track[code] then
			track(code)
		end
		return true
	end
	
	local modulename = export.getDataModuleName(code)
	
	local function get_data(code)
		return modulename and
			track_bad_code(code) and conditionalRequire("Module:" .. modulename)[code] or
			(allowEtymLang and require("etymology languages/track-bad-etym-code")(code) and conditionalRequire("Module:etymology languages/data")[code]) or
			(allowFamily and conditionalRequire("Module:families/data")[code]) or
			(allowEtymLang and allowFamily and require("families/track-bad-etym-code")(code) and conditionalRequire("Module:families/data/etymology")[code])
	end
	
	local data = get_data(code) or get_data(normalize_code(code))
	
	local retval = code and data and export.makeObject(code, data, useRequire)
	
	if not retval and paramForError then
		require("languages/errorGetBy").code(code, paramForError, allowEtymLang, allowFamily)
	end
	
	return retval
end

--[==[Finds the language whose canonical name (the name used to represent that language on Wiktionary) or other name matches the one provided. If it exists, it returns a <code class="nf">Language</code> object representing the language. Otherwise, it returns {{code|lua|nil}}, unless <code class="n">paramForError</code> is given, in which case an error is generated. If <code class="n">allowEtymLang</code> is specified, etymology language codes are allowed and looked up along with normal language codes. If <code class="n">allowFamily</code> is specified, language family codes are allowed and looked up along with normal language codes.
The canonical name of languages should always be unique (it is an error for two languages on Wiktionary to share the same canonical name), so this is guaranteed to give at most one result.
This function is powered by [[Module:languages/canonical names]], which contains a pre-generated mapping of non-etymology-language canonical names to codes. It is generated by going through the [[:Category:Language data modules]] for non-etymology languages. When <code class="n">allowEtymLang</code> is specified for the above function, [[Module:etymology languages/canonical names]] may also be used, and when <code class="n">allowFamily</code> is specified for the above function, [[Module:families/canonical names]] may also be used.]==]
function export.getByCanonicalName(name, errorIfInvalid, allowEtymLang, allowFamily, useRequire)
	local function conditionalRequire(modulename)
		if useRequire then
			return require(modulename)
		else
			return mw.loadData(modulename)
		end
	end
	
	local byName = conditionalRequire("Module:languages/canonical names")
	local code = byName and byName[name]
	
	if not code and allowEtymLang then
		byName = conditionalRequire("Module:etymology languages/canonical names")
		code = byName and byName[name] or
			byName[name:gsub(" [Ss]ubstrate$", "")] or
			byName[name:gsub("^a ", "")] or
			byName[name:gsub("^a ", ""):gsub(" [Ss]ubstrate$", "")] or
			-- For etymology families like "ira-pro".
			-- FIXME: This is not ideal, as it allows " languages" to be appended to any etymology-only language, too.
			byName[name:match("^(.*) languages$")]
	end
	
	if not code and allowFamily then
		byName = conditionalRequire("Module:families/canonical names")
		code = byName and byName[name] or
			byName[name:match("^(.*) languages$")]
	end
	
	local retval = code and export.getByCode(code, errorIfInvalid, allowEtymLang, allowFamily, useRequire)
	
	if not retval and errorIfInvalid then
		require("languages/errorGetBy").canonicalName(name, allowEtymLang, allowFamily)
	end
	
	return retval
end

--[==[Used by [[Module:languages/data/2]] (et al.) to add default types to the entities returned.]==]
function export.addDefaultTypes(data, regular, ...)
	for _, entity in pairs(data) do
		-- "regular" encompasses everything that doesn't have another type already assigned.
		if regular then
			entity.type = entity.type or "regular"
		end
		local types = table.concat({...}, ", ")
		if #types > 0 then
			entity.type =  types .. (entity.type and (", " .. entity.type) or "")
		end
	end
	return data
end

--[==[Used by [[Module:etymology languages/data]] and [[Module:families/data/etymology]] to finalize the data into the format that is actually returned.]==]
function export.finalizeEtymologyData(data)
	local aliases = {}
	for code, entity in pairs(data) do
		-- Move parent to 5 and family to 3.
		data[code][5] = data[code][3]
		data[code][3] = data[code].family
		data[code].family = nil
	end
	for code, alias in pairs(aliases) do
		data[code] = alias
	end
	return data
end

--[==[For backwards compatibility only; modules should require the /error themselves.]==]
function export.err(lang_code, param, code_desc, template_tag, not_real_lang)
	return require("languages/error")(lang_code, param, code_desc, template_tag, not_real_lang)
end

return export