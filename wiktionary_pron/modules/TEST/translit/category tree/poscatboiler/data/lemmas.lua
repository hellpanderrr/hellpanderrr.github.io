local labels = {}
local raw_categories = {}
local handlers = {}



-----------------------------------------------------------------------------
--                                                                         --
--                                  LABELS                                 --
--                                                                         --
-----------------------------------------------------------------------------


local diminutive_augmentative_poses = {
	"adjectives",
	"adverbs",
	"interjections",
	"nouns",
	"numerals",
	"prefixes",
	"proper nouns",
	"pronouns",
	"suffixes",
	"verbs"
}


labels["lemmas"] = {
	description = "{{{langname}}} [[Wiktionary:Lemmas|lemmas]], categorized by their part of speech.",
	umbrella_parents = "Fundamental",
	parents = {{name = "{{{langcat}}}", raw = true, sort = "  "}},
}

labels["abstract verbs"] = {
	description = "{{{langname}}} abstract verbs of motion whose motion is multidirectional (as opposed to unidirectional) or indirect, or whose action is repeated or in a series, instead of being a single, completed action. Abstract verbs are always imperfective in aspect, even with prefixes that are normally associated with the perfective aspect.",
	additional = "See also [[abstract verb]].",
	parents = {"verbs"},
}

labels["action nouns"] = {
	description = "{{{langname}}} nouns denoting action of a verb or verbal root that it is derived from.",
	parents = {"nouns"},
}

labels["act-related adverbs"] = {
	description = "{{{langname}}} adverbs that indicate the motive or other background information for an action.",
	parents = {"adverbs"},
}

labels["active verbs"] = {
	description = "{{{langname}}} verbs that indicate an activity",
	parents = {"verbs"},
}

labels["adjective concords"] = {
	description = "{{{langname}}} concords that are prefixed to adjective stems.",
	parents = {"concords"},
}

labels["adjectives"] = {
	description = "{{{langname}}} terms that give attributes to nouns, extending their definitions.",
	parents = {"lemmas"},
}

labels["adverbial accusatives"] = {
	description = "Accusative case-forms in {{{langname}}} used as adverbs.",
	parents = {"adverbs"},
}

labels["adverbs"] = {
	description = "{{{langname}}} terms that modify clauses, sentences and phrases directly.",
	parents = {"lemmas"},
}

labels["affixes"] = {
	description = "Morphemes attached to existing {{{langname}}} words.",
	parents = {"morphemes"},
}

labels["agent nouns"] = {
	description = "{{{langname}}} nouns that denote an agent that performs the action denoted by the verb from which the noun is derived.",
	parents = {"nouns"},
}

labels["ambipositions"] = {
	description = "{{{langname}}} adpositions that can occur either before or after their objects.",
	parents = {"lemmas"},
}

labels["ambitransitive verbs"] = {
	description = "{{{langname}}} verbs that may or may not direct actions, occurrences or states to grammatical objects.",
	parents = {"verbs", "transitive verbs", "intransitive verbs"},
}

labels["animal commands"] = {
	description = "{{{langname}}} words used to communicate with animals.",
	parents = {"interjections"},
}

labels["articles"] = {
	description = "{{{langname}}} terms that indicate and specify nouns.",
	parents = {"determiners"},
}

labels["aspect adverbs"] = {
	description = "{{{langname}}} adverbs that express [[w:Grammatical aspect|grammatical aspect]], describing the flow of time in relation to a statement.",
	parents = {"adverbs"},
}

for _, pos in ipairs(diminutive_augmentative_poses) do
	labels["augmentative " .. pos] = {
		description = "{{{langname}}} " .. pos .. " that are derived from a base word to convey big size or big intensity.",
		parents = {pos},
	}
end

labels["attenuative verbs"] = {
	description = "{{{langname}}} verbs that indicate that an action or event is performed or takes place gently, lightly, partially, perfunctorily or to an otherwise reduced extent.",
	parents = {"verbs"},
}

labels["autobenefactive verbs"] = {
	description = "{{{langname}}} verbs that indicate that the agent of an action is also its benefactor.",
	parents = {"verbs"},
}

labels["automative verbs"] = {
	description = "{{{langname}}} verbs that indicate actions directed at or a change of state of the grammatical subject.",
	parents = {"verbs"},
}

labels["auxiliary verbs"] = {
	description = "{{{langname}}} verbs that provide additional conjugations for other verbs.",
	parents = {"verbs"},
}

labels["biaspectual verbs"] = {
	description = "{{{langname}}} verbs that can be both imperfective and perfective.",
	parents = {"verbs"},
}

labels["causative verbs"] = {
	description = "{{{langname}}} verbs that express causing actions or states rather than performing or being them directly. Use this only for separate verbs (as opposed to causative forms that are part of the inflection of verbs).",
	parents = {"verbs"},
}

labels["circumfixes"] = {
	description = "Affixes attached to both the beginning and the end of {{{langname}}} words, functioning together as single units.",
	parents = {"morphemes"},
}

labels["circumpositions"] = {
	description = "{{{langname}}} adpositions that appear on both sides of their objects.",
	parents = {"lemmas"},
}

labels["classifiers"] = {
	description = "{{{langname}}} terms that classify nouns according to their meanings.",
	parents = {"lemmas"},
}

labels["clitics"] = {
	description = "{{{langname}}} morphemes that function as independent words, but are always attached to another word.",
	parents = {"morphemes"},
}

for _, pos in ipairs { "nouns", "suffixes" } do
	labels["collective " .. pos] = {
		description = "{{{langname}}} " .. pos .. " that indicate groups of related things or beings, without the need of grammatical pluralization.",
		parents = {pos},
	}
end

labels["combining forms"] = {
	description = "Forms of {{{langname}}} words that do not occur independently, but are used when joined with other words.",
	parents = {"morphemes"},
}

labels["comparable adjectives"] = {
	description = "{{{langname}}} adjectives that can be inflected to display different degrees of comparison.",
	parents = {"adjectives"},
}

labels["comparable adverbs"] = {
	description = "{{{langname}}} adverbs that can be inflected to display different degrees of comparison.",
	parents = {"adverbs"},
}

labels["comparative-only adjectives"] = {
	description = "{{{langname}}} adjectives that are only used in their comparative forms.",
	parents = {"adjectives"},
}

labels["completive verbs"] = {
	description = "{{{langname}}} verbs which refer to the completion of an action which has already commenced or which has already been performed upon a subset of the entities which it affects.",
	parents = {"verbs"},
}

labels["concords"] = {
	description = "{{{langname}}} prefixes attached to words to show agreement with a noun or pronoun.",
	parents = {"prefixes"},
}

labels["concrete verbs"] = {
	description = "{{{langname}}} concrete verbs refer to a verbal aspect in verbs of motion that is unidirectional (as opposed to multidirectional), a definitely directed motion, or a single, completed action (instead of a repeated action or series of actions). Concrete verbs may be either imperfective or perfective.",
	additional = "See also [[concrete verb]].",
	parents = {"verbs"},
}

labels["conjunctions"] = {
	description = "{{{langname}}} terms that connect words, phrases or clauses together.",
	parents = {"lemmas"},
}

labels["conjunctive adverbs"] = {
	description = "{{{langname}}} adverbs that connect two independent clauses together.",
	parents = {"adverbs"},
}

labels["continuative verbs"] = {
	description = "{{{langname}}} verbs that express continuing action.",
	parents = {"verbs"},
}

labels["control verbs"] = {
	description = "{{{langname}}} verbs that take multiple arguments, one of which is another verb. One of the control verb's arguments is syntactically both an argument of the control verb and an argument of the other verb.",
	parents = {"verbs"},
}

labels["cooperative verbs"] = {
	description = "{{{langname}}} verbs that indicate cooperation",
	parents = {"verbs"},
}

labels["coordinating conjunctions"] = {
	description = "{{{langname}}} conjunctions that indicate equal syntactic importance between connected items.",
	parents = {"conjunctions"},
}

labels["copulative verbs"] = {
	description = "{{{langname}}} verbs that may take adjectives as their complement.",
	parents = {"verbs"},
}

for _, pos in ipairs { "nouns", "proper nouns" } do
	labels["countable " .. pos] = {
		description = "{{{langname}}} " .. pos .. " that can be quantified directly by numerals.",
		parents = {pos},
	}
end

labels["countable numerals"] = {
	description = "{{{langname}}} numerals that can be quantified directly by other numerals.",
	parents = {"numerals"},
}

labels["countable suffixes"] = {
	description = "{{{langname}}} suffixes that can be used to form nouns that can be quantified directly by numerals.",
	parents = {"numerals"},
}

labels["counters"] = {
	description = "{{{langname}}} terms that combine with numerals to express quantity of nouns.",
	parents = {"lemmas"},
}

labels["cumulative verbs"] = {
	description = "{{{langname}}} verbs which indicate that an action or event gradually yields a certain or significant quantity or effect.",
	parents = {"verbs"},
}

labels["degree adverbs"] = {
	description = "{{{langname}}} adverbs that express a particular degree to which the word they modify applies.",
	parents = {"adverbs"},
}

labels["delimitative verbs"] = {
	description = "{{{langname}}} verbs which indicate that an action or event is performed or takes place briefly or to an otherwise reduced extent.",
	parents = {"verbs"},
}

labels["demonstrative adjectives"] = {
	description = "{{{langname}}} adjectives that refer to nouns, comparing them to external references.",
	parents = {"adjectives", {name = "demonstrative pro-forms", sort = "adjectives"}},
}

labels["demonstrative adverbs"] = {
	description = "{{{langname}}} adverbs that refer to other adverbs, comparing them to external references.",
	parents = {"adverbs", {name = "demonstrative pro-forms", sort = "adverbs"}},
}

labels["denominal verbs"] = { -- in [[Appendix:Glossary]]; "denominative" more frequent?
	description = "{{{langname}}} verbs that derive from nouns.",
	parents = { "verbs" },
}

labels["demonstrative determiners"] = {
	description = "{{{langname}}} determiners that refer to nouns, comparing them to external references.",
	parents = {"determiners", {name = "demonstrative pro-forms", sort = "determiners"}},
}

labels["demonstrative pronouns"] = {
	description = "{{{langname}}} pronouns that refer to nouns, comparing them to external references.",
	parents = {"pronouns", {name = "demonstrative pro-forms", sort = "pronouns"}},
}

labels["deponent verbs"] = {
	description = "{{{langname}}} verbs that have active meanings but are not conjugated in the active voice.",
	parents = {"verbs"},
}

labels["derivational prefixes"] = {
	description = "{{{langname}}} prefixes that are used to create new words.",
	parents = {"prefixes"},
}

labels["derivational suffixes"] = {
	description = "{{{langname}}} suffixes that are used to create new words.",
	parents = {"suffixes"},
}

labels["derivative verbs"] = {
	description = "{{{langname}}} verbs that are derived from nouns and adjectives.",
	parents = {"verbs"},
}

labels["desiderative verbs"] = {
	description = "{{{langname}}} verbs with the following morphology: verbal root xxx + [[desiderative]] affix, and the following semantics: to wish to do the action xxx.",
	parents = {"verbs"},
}

labels["determinatives"] = {
	description = "{{{langname}}} terms that indicate the general class to which the following logogram belongs.",
	parents = {"lemmas"},
}

labels["determiners"] = {
	description = "{{{langname}}} terms that narrow down, within the conversational context, the referent of the following noun.",
	parents = {"lemmas"},
}

labels["diminutiva tantum"] = {
	description = "{{{langname}}} nouns or noun senses that are mostly or exclusively used in the diminutive form.",
	parents = {"nouns"},
}

for _, pos in ipairs(diminutive_augmentative_poses) do
	labels["diminutive " .. pos] = {
		description = "{{{langname}}} " .. pos .. " that are derived from a base word to convey endearment, small size or small intensity.",
		parents = {pos},
	}
end

labels["discourse particles"] = {
	description = "{{{langname}}} particles that manage the flow and structure of discourse.",
	parents = {"particles"},
}

labels["distributive verbs"] = {
	description = "{{{langname}}} verbs which indicate that an action or event involves multiple participants or a large quantity of an uncountable mass, usually as the grammatical subject in the case of intransitive verbs and as the grammatical object in the case of transitive verbs.",
	parents = {"verbs"},
}

labels["ditransitive verbs"] = {
	description = "{{{langname}}} verbs that indicate actions, occurrences or states of two grammatical objects simultaneously, one direct and one indirect.",
	parents = {"verbs", "transitive verbs"},
}

labels["dualia tantum"] = {
	description = "{{{langname}}} nouns that are mostly or exclusively used in the dual form.",
	parents = {"nouns"},
}

labels["duration adverbs"] = {
	description = "{{{langname}}} adverbs that express duration in time.",
	parents = {"time adverbs"},
}

labels["ergative verbs"] = {
	description = "{{{langname}}} [[Appendix:Glossary#ergative|ergative verb]]s: intransitive verbs that become causatives when used transitively.",
	parents = {"verbs", "intransitive verbs", "transitive verbs"},
}

labels["excessive verbs"] = {
	description = "{{{langname}}} verbs that indicate that an action is performed to an excessive extent.",
	parents = {"verbs"},
}

labels["enclitics"] = {
	description = "{{{langname}}} clitics that attach to the preceding word.",
	parents = {"clitics"},
}

labels["nouns with other-gender equivalents"] = {
	description = "{{{langname}}} nouns that refer to gendered concepts (e.g. [[actor]] vs. [[actress]], [[king]] vs. [[queen]]) and have corresponding other-gender equivalent terms.",
	parents = {"nouns"},
}

labels["female equivalent nouns"] = {
	description = "{{{langname}}} nouns that refer to female beings with the same characteristics as the base noun.",
	parents = {"nouns with other-gender equivalents"},
}

labels["neuter equivalent nouns"] = {
	description = "{{{langname}}} nouns that refer to neuter beings with the same characteristics as the base noun.",
	parents = {"nouns with other-gender equivalents"},
}

labels["female equivalent suffixes"] = {
	description = "{{{langname}}} suffixes that refer to female beings with the same characteristics as the base suffix.",
	parents = {"noun-forming suffixes"},
}

labels["focus adverbs"] = {
	description = "{{{langname}}} adverbs that indicate [[w:Focus (linguistics)|focus]] within the sentence.",
	parents = {"adverbs"},
}

labels["frequency adverbs"] = {
	description = "{{{langname}}} adverbs that express repetition with a certain frequency or interval.",
	parents = {"time adverbs"},
}

labels["frequentative verbs"] = {
	description = "{{{langname}}} verbs that express repeated action.",
	parents = {"verbs"},
}

labels["general pronouns"] = {
	description = "{{{langname}}} pronouns that refer to all persons, things, abstract ideas and their characteristics.",
	parents = {"pronouns"},
}

labels["generational moieties"] = {
	description = "{{{langname}}} moieties that alternate every generation.",
	parents = {"moieties"},
}

labels["ideophones"] = {
	description = "{{{langname}}} terms that evoke an idea, especially a sensation or impression, with a sound.",
	parents = {"lemmas"},
}

labels["imperfective verbs"] = {
	description = "{{{langname}}} verbs that express actions considered as ongoing or continuous, as opposed to completed events.",
	parents = {"verbs"},
}

labels["impersonal verbs"] = {
	description = "{{{langname}}} verbs that do not indicate actions, occurrences or states of any specific grammatical subject.",
	parents = {"verbs"},
}

labels["inchoative verbs"] = {
	description = "{{{langname}}} verbs that indicate the beginning of an action or event.",
	parents = {"verbs"},
}

labels["indefinite adjectives"] = {
	description = "{{{langname}}} adjectives that refer to unspecified adjective meanings.",
	parents = {"adjectives", {name = "indefinite pro-forms", sort = "adjectives"}},
}

labels["indefinite adverbs"] = {
	description = "{{{langname}}} adverbs that refer to unspecified adverbial meanings.",
	parents = {"adverbs", {name = "indefinite pro-forms", sort = "adverbs"}},
}

labels["indefinite determiners"] = {
	description = "{{{langname}}} determiners that designate an unidentified noun.",
	parents = {"determiners", {name = "indefinite pro-forms", sort = "determiners"}},
}

labels["indefinite pronouns"] = {
	description = "{{{langname}}} pronouns that refer to unspecified nouns.",
	parents = {"pronouns", {name = "indefinite pro-forms", sort = "pronouns"}},
}

labels["infixes"] = {
	description = "Affixes inserted inside {{{langname}}} words.",
	parents = {"morphemes"},
}

labels["inflectional prefixes"] = {
	description = "{{{langname}}} prefixes that are used as inflectional beginnings in noun, adjective or verb paradigms.",
	parents = {"prefixes"},
}

labels["inflectional suffixes"] = {
	description = "{{{langname}}} suffixes that are used as inflectional endings in noun, adjective or verb paradigms.",
	parents = {"suffixes"},
}

labels["intensive verbs"] = {
	description = "{{{langname}}} verbs which indicate that an action is performed vigorously, enthusiastically, forcefully or to an otherwise enlarged extent.",
	parents = {"verbs"},
}

labels["interfixes"] = {
	description = "Affixes used to join two {{{langname}}} words or morphemes together.",
	parents = {"morphemes"},
}

labels["interjections"] = {
	description = "{{{langname}}} terms that express emotions, sounds, etc. as exclamations.",
	parents = {"lemmas"},
}

labels["interrogative adjectives"] = {
	description = "{{{langname}}} adjectives that indicate questions.",
	parents = {"adjectives", {name = "interrogative pro-forms", sort = "adjectives"}},
}

labels["interrogative adverbs"] = {
	description = "{{{langname}}} adverbs that indicate questions.",
	parents = {"adverbs", {name = "interrogative pro-forms", sort = "adverbs"}},
}

labels["interrogative determiners"] = {
	description = "{{{langname}}} determiners that indicate questions.",
	parents = {"determiners", {name = "interrogative pro-forms", sort = "determiners"}},
}

labels["interrogative particles"] = {
	description = "{{{langname}}} particles that indicate questions.",
	parents = {"particles", {name = "interrogative pro-forms", sort = "particles"}},
}

labels["interrogative pronouns"] = {
	description = "{{{langname}}} pronouns that indicate questions.",
	parents = {"pronouns", {name = "interrogative pro-forms", sort = "pronouns"}},
}

labels["intransitive verbs"] = {
	description = "{{{langname}}} verbs that don't require any grammatical objects.",
	parents = {"verbs"},
}

labels["iterative verbs"] = {
	description = "{{{langname}}} verbs that express the repetition of an event.",
	parents = {"verbs"},
}

labels["location adverbs"] = {
	description = "{{{langname}}} adverbs that indicate location.",
	parents = {"adverbs"},
}

labels["male equivalent nouns"] = {
	description = "{{{langname}}} nouns that refer to male beings with the same characteristics as the base noun.",
	parents = {"nouns with other-gender equivalents"},
}

labels["manner adverbs"] = {
	description = "{{{langname}}} adverbs that indicate the manner, way or style in which an action is performed.",
	parents = {"adverbs"},
}

labels["modal adverbs"] = {
	description = "{{{langname}}} adverbs that express [[w:Linguistic modality|linguistic modality]], indicating the mood or attitude of the speaker with respect to what is being said.",
	parents = {"sentence adverbs"},
}

labels["modal particles"] = {
	description = "{{{langname}}} particles that reflect the mood or attitude of the speaker, without changing the basic meaning of the sentence.",
	parents = {"particles"},
}

labels["modal verbs"] = {
	description = "{{{langname}}} verbs that indicate [[grammatical mood]].",
	parents = {"auxiliary verbs"},
}

labels["moieties"] = {
	description = "{{{langname}}} pairs of abstract categories separating people and the environment.",
	parents = {"lemmas"},
}

labels["momentane verbs"] = {
	description = "{{{langname}}} verbs that express a sudden and brief action.",
	parents = {"verbs"},
}

labels["morphemes"] = {
	description = "{{{langname}}} word-elements used to form full words.",
	parents = {"lemmas"},
}

labels["multiword terms"] = {
	description = "{{{langname}}} lemmas that are an [[WT:CFI#Idiomaticity|idiomatic]] combination of multiple words.",
	parents = {"lemmas"},
}

labels["negative verbs"] = {
	description = "{{{langname}}} verbs that indicate the lack of an action.",
	parents = {"verbs"},
}

labels["negative particles"] = {
	description = "{{{langname}}} particles that indicate negation.",
	parents = {"particles"},
}

labels["negative pronouns"] = {
	description = "{{{langname}}} pronouns that refer to negative or non-existent references.",
	parents = {"pronouns"},
}

labels["neutral verbs"] = {
	description = "{{{langname}}} verbs that indicate either or both an activity or a result of an activity",
	parents = {"verbs"},
}

labels["nominalized adjectives"] = {
	description = "{{{langname}}} adjectives that are used as nouns.",
	parents = {"nouns", "adjectives"},
}

labels["non-constituents"] = {
	description = "{{{langname}}} terms that are not grammatical [[constituent#Noun|constituents]], and therefore need to be combined with additional terms to form a complete phrase.",
	parents = {"phrases"},
}

labels["noun prefixes"] = {
	description = "{{{langname}}} prefixes attached to a noun that display its noun class.",
	parents = {"prefixes"},
}

labels["nouns"] = {
	description = "{{{langname}}} terms that indicate people, beings, things, places, phenomena, qualities or ideas.",
	parents = {"lemmas"},
}

labels["nouns by classifier"] = {
	description = "{{{langname}}} nouns organized by the classifier they are used with.",
	parents = {{name = "nouns", sort = "classifier"}},
}

labels["numerals"] = {
	description = "{{{langname}}} terms that quantify nouns.",
	parents = {"lemmas"},
}

labels["object concords"] = {
	description = "{{{langname}}} concords used to show the grammatical object.",
	parents = {"concords"},
}

labels["object pronouns"] = {
	description = "{{{langname}}} pronouns that refer to grammatical objects.",
	parents = {"pronouns"},
}

labels["particles"] = {
	description = "{{{langname}}} terms that do not belong to any of the inflected grammatical word classes, often lacking their own grammatical functions and forming other parts of speech or expressing the relationship between clauses.",
	parents = {"lemmas"},
}

labels["passive verbs"] = {
	description = "{{{langname}}} verbs that are usually used in passive voice.",
	parents = {"verbs"},
}

labels["perfective verbs"] = {
	description = "{{{langname}}} verbs that express actions considered as completed events, as opposed to ongoing or continuous.",
	parents = {"verbs"},
}

labels["personal pronouns"] = {
	description = "{{{langname}}} pronouns that are used as substitutes for known nouns.",
	parents = {"pronouns"},
}

labels["phrasal verbs"] = {
	description = "{{{langname}}} verbs accompanied by particles, such as prepositions and adverbs.",
	parents = {"verbs", "phrases"},
}

labels["phrasal prepositions"] = {
	description = "{{{langname}}} prepositions formed with combinations of other terms.",
	parents = {"prepositions", "phrases"},
}

labels["pluralia tantum"] = {
	description = "{{{langname}}} nouns that are mostly or exclusively used in the plural form.",
	parents = {"nouns"},
}

labels["point-in-time adverbs"] = {
	description = "{{{langname}}} adverbs that reference a specific point in time, e.g. {{m|en|yesterday}}, {{m+|es|anoche||last night}} or {{m+|hu|egykor||at one o'clock}}.",
	parents = {"time adverbs"},
}

labels["possessable nouns"] = {
	description = "{{{langname}}} nouns can have their possession indicated directly by possessive pronouns.",
	parents = {"nouns"},
	umbrella = {
		description = "Categories with nouns that can have their possession indicated directly by possessive pronouns and, in some languages, be transformed into adjectives.",
		parents = {"Lemmas subcategories by language"},
		breadcrumb = "Possessable nouns by language",
	},
}

labels["possessional adjectives"] = {
	description = "{{{langname}}} adjectives that indicate that a noun is in possession of something.",
	parents = {"adjectives"},
}

labels["possessive adjectives"] = {
	description = "{{{langname}}} adjectives that indicate ownership.",
	parents = {"adjectives"},
}

labels["possessive concords"] = {
	description = "{{{langname}}} concords used to show possession.",
	parents = {"concords"},
}

labels["possessive determiners"] = {
	description = "{{{langname}}} determiners that indicate ownership.",
	parents = {"determiners"},
}

labels["possessive pronouns"] = {
	description = "{{{langname}}} pronouns that indicate ownership.",
	parents = {"pronouns"},
}

labels["postpositional phrases"] = {
	description = "{{{langname}}} phrases headed by a postposition.",
	parents = {"phrases", "postpositions"},
}

labels["postpositions"] = {
	description = "{{{langname}}} adpositions that are placed after their objects.",
	parents = {"lemmas"},
}

labels["predicatives"] = {
	description = "{{{langname}}} elements of the predicate that supplement the subject or object of a sentence via the verb.",
	parents = {"lemmas"},
}

labels["prefixes"] = {
	description = "Affixes attached to the beginning of {{{langname}}} words.",
	parents = {"morphemes"},
}

labels["prepositional phrases"] = {
	description = "{{{langname}}} phrases headed by a preposition.",
	parents = {"phrases", "prepositions"},
}

labels["prepositions"] = {
	description = "{{{langname}}} adpositions that are placed before their objects.",
	parents = {"lemmas"},
}

labels["ablative prepositions"] = {
	description = "{{{langname}}} prepositions that cause the succeeding noun to be in the ablative case.",
	parents = {"prepositions"},
}

labels["accusative prepositions"] = {
	description = "{{{langname}}} prepositions that cause the succeeding noun to be in the accusative case.",
	parents = {"prepositions"},
}

labels["dative prepositions"] = {
	description = "{{{langname}}} prepositions that cause the succeeding noun to be in the dative case.",
	parents = {"prepositions"},
}

labels["genitive prepositions"] = {
	description = "{{{langname}}} prepositions that cause the succeeding noun to be in the genitive case.",
	parents = {"prepositions"},
}

labels["instrumental prepositions"] = {
	description = "{{{langname}}} prepositions that cause the succeeding noun to be in the instrumental case.",
	parents = {"prepositions"},
}

labels["matrilineal moieties"] = {
	description = "{{{langname}}} moieties inherited from an individual's mother.",
	parents = {"moieties"},
}

labels["nominative prepositions"] = {
	description = "{{{langname}}} prepositions that cause the succeeding noun to be in the nominative case.",
	parents = {"prepositions"},
}

labels["patrilineal moieties"] = {
	description = "{{{langname}}} moieties inherited from an individual's father.",
	parents = {"moieties"},
}

labels["pejorative suffixes"] = {
	description = "{{{langname}}} suffixes that [[belittle]] (lessen in value).",
	parents = {"suffixes"},
}

labels["prepositional prepositions"] = {
	description = "{{{langname}}} prepositions that cause the succeeding noun to be in the prepositional case.",
	parents = {"prepositions"},
}

labels["prenouns"] = {
	description = "{{{langname}}} prefixes of various kinds that are attached to nouns.",
	parents = {"prefixes"},
}

labels["preverbs"] = {
	description = "{{{langname}}} prefixes of various kinds that are attached to verbs.",
	parents = {"prefixes"},
}

labels["privative verbs"] = {
	description = "{{{langname}}} verbs that indicate that the grammatical object is deprived of something or that something is removed from the object.",
	parents = {"verbs"},
}

labels["pronominal adverbs"] = {
	description = "{{{langname}}} adverbs that are formed by combining a pronoun with a preposition.",
	parents = {"adverbs", "prepositions", "pronouns"},
}

labels["pronominal concords"] = {
	description = "{{{langname}}} concords that are prefixed to pronominal stems.",
	parents = {"concords"},
}

labels["pronouns"] = {
	description = "{{{langname}}} terms that refer to and substitute nouns.",
	parents = {"lemmas"},
}

labels["proper nouns"] = {
	description = "{{{langname}}} nouns that indicate individual entities, such as names of persons, places or organizations.",
	parents = {"nouns"},
}

labels["punctual adverbs"] = {
	description = "{{{langname}}} adverbs that express a single point or span in time.",
	parents = {"time adverbs"},
}

labels["raising verbs"] = {
	description = "{{{langname}}} verbs that, in a matrix or main clause, take an argument from an embedded or subordinate clause; in other words, a raising verb appears with a syntactic argument that is not its semantic argument, but is rather the semantic argument of an embedded predicate.",
	parents = {"verbs"},
}

labels["reciprocal pronouns"] = {
	description = "{{{langname}}} pronouns that refer back to a plural subject and express an action done in two or more directions.",
	parents = {"pronouns", "personal pronouns"},
}

labels["reciprocal verbs"] = {
	description = "{{{langname}}} verbs that indicate actions, occurrences or states directed from multiple subjects to each other.",
	parents = {"verbs"},
}

labels["reflexive pronouns"] = {
	description = "{{{langname}}} pronouns that refer back to the subject.",
	parents = {"pronouns", "personal pronouns"},
}

labels["reflexive verbs"] = {
	description = "{{{langname}}} verbs that indicate actions, occurrences or states directed from the grammatical subjects to themselves.",
	parents = {"verbs"},
}

labels["relational adjectives"] = {
	description = "{{{langname}}} adjectives that stand in place of a noun when modifying another noun.",
	parents = {"adjectives"},
}

labels["relational nouns"] = {
	description = "{{{langname}}} nouns used to indicate a relation between other two nouns by means of possession.",
	parents = {"nouns"},
}

labels["relative adjectives"] = {
	description = "{{{langname}}} adjectives used to indicate [[relative clause]]s.",
	parents = {"adjectives", {name = "relative pro-forms", sort = "adjectives"}},
}

labels["relative adverbs"] = {
	description = "{{{langname}}} adverbs used to indicate [[relative clause]]s.",
	parents = {"adverbs", {name = "relative pro-forms", sort = "adverbs"}},
}

labels["relative determiners"] = {
	description = "{{{langname}}} determiners used to indicate [[relative clause]]s.",
	parents = {"determiners", {name = "relative pro-forms", sort = "determiners"}},
}

labels["relative concords"] = {
	description = "{{{langname}}} concords that are prefixed to relative stems.",
	parents = {"concords"},
}

labels["relative pronouns"] = {
	description = "{{{langname}}} pronouns used to indicate [[relative clause]]s.",
	parents = {"pronouns", {name = "relative pro-forms", sort = "pronouns"}},
}

labels["relatives"] = {
	description = "{{{langname}}} terms that give attributes to nouns, acting grammatically as relative clauses.",
	parents = {"lemmas"},
}

labels["repetitive verbs"] = {
	description = "{{{langname}}} verbs that indicate actions or events which are performed or occur again, anew or differently.",
	parents = {"verbs"},
}

labels["resultative verbs"] = {
	description = "{{{langname}}} verbs that indicate a result of some action",
	parents = {"verbs"},
}

labels["reversative verbs"] = {
	description = "{{{langname}}} verbs that indicate that the reversal or undoing of an action, event or state.",
	parents = {"verbs"},
}

labels["saturative verbs"] = {
	description = "{{{langname}}} verbs which indicate that an action is performed to the point of saturation or satisfaction.",
	parents = {"verbs"},
}

labels["semelfactive verbs"] = {
	description = "{{{langname}}} verbs that are punctual (instantaneous, momentive), perfective (treated as a unitary whole with no explicit internal temporal structure), and telic (having a boundary out of which the activity cannot be said to have taken place or continue).",
	parents = {"verbs"},
}

labels["sentence adverbs"] = {
	description = "{{{langname}}} adverbs that modify an entire clause or sentence.",
	parents = {"adverbs"},
}

labels["sequence adverbs"] = {
	description = "{{{langname}}} conjunctive adverbs that express sequence in space or time.",
	parents = {"conjunctive adverbs"},
}

labels["simulfixes"] = {
	description = "Affixes replacing positions in {{{langname}}} words.",
	parents = {"morphemes"},
}

labels["singulative nouns"] = {
	description = "{{{langname}}} nouns that indicate a single item of a group of related things or beings.",
	parents = {"nouns"},
}

labels["singularia tantum"] = {
	description = "{{{langname}}} nouns that are mostly or exclusively used in the singular form.",
	parents = {"nouns"},
}

labels["stative verbs"] = {
	description = "{{{langname}}} verbs that define a state with no or insignificant internal dynamics.",
	parents = {"verbs"},
}

labels["stems"] = {
	description = "Morphemes from which {{{langname}}} words are formed.",
	parents = {"morphemes"},
}

labels["subordinating conjunctions"] = {
	description = "{{{langname}}} conjunctions that indicate relations of syntactic dependence between connected items.",
	parents = {"conjunctions"},
}

labels["subject concords"] = {
	description = "{{{langname}}} concords used to show the grammatical subject.",
	parents = {"concords"},
}

labels["subject pronouns"] = {
	description = "{{{langname}}} pronouns that refer to grammatical subjects.",
	parents = {"pronouns"},
}

labels["suffixes"] = {
	description = "Affixes attached to the end of {{{langname}}} words.",
	parents = {"morphemes"},
}

labels["splitting verbs"] = {
	description = "{{{langname}}} bisyllabic verbs that obligatorily split around a direct object or pronoun.",
	parents = {"verbs"},
}

labels["terminative verbs"] = {
	description = "{{{langname}}} verbs that indicate that an action or event ceases.",
	parents = {"verbs"},
}

labels["time adverbs"] = {
	description = "{{{langname}}} adverbs that indicate time.",
	parents = {"adverbs"},
}

labels["transfixes"] = {
	description = "Discontinuous affixes inserted within a word root.",
	parents = {"morphemes"},
}

labels["transformative verbs"] = {
	description = "{{{langname}}} verbs that indicate a change of state or nature, in the subject for intransitive verbs and in the object for transitive verbs.",
	parents = {"verbs"},
}

labels["transitive verbs"] = {
	description = "{{{langname}}} verbs that indicate actions, occurrences or states directed to one or more grammatical objects.",
	parents = {"verbs"},
}

labels["uncomparable adjectives"] = {
	description = "{{{langname}}} adjectives that are not inflected to display different degrees of comparison.",
	parents = {"adjectives"},
}

labels["uncomparable adverbs"] = {
	description = "{{{langname}}} adverbs that are not inflected to display different degrees of comparison.",
	parents = {"adverbs"},
}

labels["uncountable nouns"] = {
	description = "{{{langname}}} nouns that indicate qualities, ideas, unbounded mass or other abstract concepts that cannot be quantified directly by numerals.",
	parents = {"nouns"},
}

labels["uncountable numerals"] = {
	description = "{{{langname}}} numerals that cannot be quantified directly by other numerals.",
	parents = {"numerals"},
}

labels["uncountable proper nouns"] = {
	description = "{{{langname}}} proper nouns that cannot be quantified directly by numerals.",
	parents = {"proper nouns"},
}

labels["uncountable suffixes"] = {
	description = "{{{langname}}} suffixes that can be used to form nouns that cannot be quantified directly by numerals.",
	parents = {"numerals"},
}

labels["unpossessable nouns"] = {
	description = "{{{langname}}} nouns that cannot have their possession indicated directly by possessive pronouns.",
	parents = {"nouns"},
	umbrella = {
		description = "Categories with nouns that cannot have their possession indicated directly by possessive pronouns or, in some languages, be transformed into adjectives.",
		parents = {"Lemmas subcategories by language"},
		breadcrumb = "Unpossessable nouns by language",
	},
}

labels["verbal nouns"] = {
	description = "{{{langname}}} nouns morphologically related to a verb and similar to it in meaning.",
	parents = {"nouns"},
}

labels["verbal adjectives"] = {
	description = "{{{langname}}} adjectives describing the condition or state resulting from the action of the corresponding verb.",
	parents = {"adjectives"},
}

labels["verbs"] = {
	description = "{{{langname}}} terms that indicate actions, occurrences or states.",
	parents = {"lemmas"},
}

labels["verbs of movement"] = {
	description = "{{{langname}}} verbs that indicate physical movement of the grammatical subject across a trajectory, with a starting point and an endpoint.",
	parents = {"verbs"},
}

-- Add "POS-forming suffixes".
local poses_derived_by_suffix = {
	"adjective", "adverb", "noun", "verb",
}

for _, pos in pairs(poses_derived_by_suffix) do
	labels[pos .. "-forming suffixes"] = {
		description = "{{{langname}}} suffixes that are used to derive " .. pos .. "s from other words.",
		parents = {"derivational suffixes"},
	}
end


local labels2 = {}

-- Add "reconstructed" subcategories; add 'umbrella_parents' key if not
-- already present.
for key, data in pairs(labels) do
	labels2[key] = data
	if not data.umbrella_parents then
		data.umbrella_parents = "Lemmas subcategories by language"
	end
	labels2["reconstructed " .. key] = {
		description = "{{{langname}}} " .. key .. "  that have been linguistically [[Wiktionary:Reconstructed terms|reconstructed]].",
		umbrella_parents = "Lemmas subcategories by language",
		parents = {key, {name = "reconstructed terms", sort = key}}
	}
end



-----------------------------------------------------------------------------
--                                                                         --
--                              RAW CATEGORIES                             --
--                                                                         --
-----------------------------------------------------------------------------


raw_categories["Lemmas subcategories by language"] = {
	description = "Umbrella categories covering topics related to lemmas.",
	additional = "{{{umbrella_meta_msg}}}",
	parents = {
		"Umbrella metacategories",
		{name = "lemmas", is_label = true, sort = " "},
	},
}



-----------------------------------------------------------------------------
--                                                                         --
--                                 HANDLERS                                --
--                                                                         --
-----------------------------------------------------------------------------

-- Handler for e.g. [[:Category:English phrasal verbs with particle (around)]].
table.insert(handlers, function(data)
	local particle = data.label:match("^phrasal verbs with particle %((.-)%)$")
	if particle then
		local tagged_text = require("script utilities").tag_text(particle, data.lang, nil, "term")
		local link = require("links").full_link({ term = particle, lang = data.lang }, "term")
		
		return {
			description = "{{{langname}}} {{w|phrasal verb}}s using the particle " .. link .. ".",
			displaytitle = "{{{langname}}} phrasal verbs with particle (" .. tagged_text .. ")",
			breadcrumb = tagged_text,
			parents = {{ name = "phrasal verbs", sort = particle }},
			umbrella = false,
		}
	end
end)


return {LABELS = labels2, RAW_CATEGORIES = raw_categories, HANDLERS = handlers}