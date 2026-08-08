#!/usr/bin/env node
// Build macronizer/glosses.tsv.gz — one-line English gloss per lemma, for the
// word popup (M-005), so users can tell homographs apart (populus "people" vs
// "poplar", malus "apple-tree" vs "bad").
//
// Source of truth: the refined pipeline in `_probe_refined.cjs` (ported here
// verbatim). Do NOT reintroduce the old first-clause extraction — it shipped
// ~15% fragment glosses. This build was audited at 99.1% usable / 0.9% wrong
// on a 120-row labeled holdout (2026-08-07).
//
// Node (not Python) because the WORDS fallback needs the `whitakers-words` npm
// engine. Run from the repo root:
//   node utils/build_glosses.cjs            # full build (WORDS fallback, ~3 min)
//   SKIP_WORDS=1 node utils/build_glosses.cjs   # L&S only (~2 min, for iteration)
//
// Output: macronizer/glosses.tsv.gz  — gzip of `lemma<TAB>gloss` lines, one per
// lemma (lowercased key), first-seen across (lemma|tag) rows.

const { createEngine } = require("whitakers-words/node");
const fs = require("fs");
const path = require("path");
const zlib = require("zlib");
const engine = createEngine();

// ---- L&S index ----
const lsByKey = new Map(), lsByBase = new Map();
for (const c of "ABCDEFGHIJKLMNOPQRSTUVXYZ") {
  const p = path.join("utils","ext_tmp",`ls_${c}.json`);
  if (!fs.existsSync(p)) continue;
  for (const e of JSON.parse(fs.readFileSync(p,"utf8"))) {
    if (!e || !e.key) continue;
    const key = String(e.key).toLowerCase();
    lsByKey.set(key, e);
    const base = key.replace(/\d+$/,"");
    if (!lsByBase.has(base)) lsByBase.set(base, []);
    lsByBase.get(base).push(e);
  }
}

// ---- CORE_GLOSS override table ----
// Hand-curated everyday glosses for the closed function-word stratum (conjunctions,
// prepositions, pronouns, copula, core adverbs) + a few homograph-inverted common
// content words. L&S never states "and"/"but"/"to be" — its function-word primaries
// are usage-notes ("a particle of limitation...") and etymology scaffolding ("Conj.
// [Sanscr. ati...]"), and it numbers the RARE homograph as -1 (caelum1=chisel,
// lego1=bequeath). No scoring rule can recover these; the class is closed and finite
// (~100 entries). Applied FIRST in resolve(), before L&S/WORDS. Every key must have
// a row in utils/gloss_golden.json (enforced by test_gloss_regression.cjs).
// Source: utils/core_gloss.json (hand-reviewed; drafted 2026-08-08 by panel).
const coreGloss = (() => {
  try { return JSON.parse(fs.readFileSync("utils/core_gloss.json", "utf8")); }
  catch { return {}; }
})();

// ---- extraction regexes (from the refined probe) ----
const XREF = /^(v\.\s*(the|a|id)|init\.|fin\.|q\.\s*v\.|perh\.|etym\.|lit\.|esp\.|abb\.)$/i;
const ABBR_TOK = /^(v\.|a\.|n\.|adj\.|adv\.|conj\.|prep\.|pron\.|interj\.|num\.|part\.|ger\.|sup\.|imper\.|inf\.|lit\.|in\s+gen\.|in\s+partic\.|prop\.|trop\.|transf\.|inch\.|patron\.|m\.|f\.|dim\.|eccl\.|subst\.|poet\.|arch\.|old\.|dep\.|freq\.)/i;
const CIT = /[,;]\s*(?:id\.\s*)?(?:ap\.\s*)?(Plaut|Cic|Liv|Ov|Hor|Verg|Virg|Cat|Sen|Tac|Caes|Ter|Juv|Stat|Col|Plin|Suet|Lucr|Tert|Aug|Gell|Curt|Varr|Enn|Id|Eur|Hdt|Hom|Her|Isid|Amm|Spart|Vulg|Luc|Prop|Tib|Ulp|Paul|Fest|Dig|Cod|Hyg|Front|Charis|Prisc|Donat|Serv|Solin|Pan|App|Lampr|Ambros|Val|Macr|Nep|Aus|Flor|Hier|Cassiod|Sid|Pall)\b/i;
const TAIL_CIT = /[.,;:]\s*(?:[A-Z][a-z]{2,8}\.\s*)?(?:[IVXLCDM]+|\d+)(?:\s*,\s*(?:§\s*)?[IVXLCDM\d]+)*\s*[,;]?\s*(?:§\s*\d+)?\s*(?:[A-Z][a-z]+\.?\s*\d*)?\s*\.?$/;
const TAIL_AUTHOR = /[.,;:]\s*(?:[A-Z][a-z]{2,8}\.|[A-Z]\.\s*[A-Z]\.?)(?:\s*[A-Z]?\.?\s*(?:p\.\s*)?\d*)?\s*\.?$/;
const CIT_FULL = /[.,;:]\s*(?:id\.\s*)?(?:ap\.\s*)?[A-Z][a-z]{2,8}\.\s*(?:[IVXLCDM]+|\d+)(?:\s*,\s*(?:§\s*)?[IVXLCDM\d]+)*\s*[,;]?\s*(?:§\s*\d+)?\s*(?:fin\.?)?\s*\.?$/;
const HEADER = /^(?:In\s+(?:gen\.|partic\.|the\s+widest\s+sense)|Lit\.?|Transf\.?|Esp\.?|Fin\.?|Neutr\.?|Act\.?|Pass\.?|Absol\.?|P\.\s*a\.|Prop\.?|Trop\.?)$/i;
const SAME_AS = /^the\s+same\s+as/i;
const SCOPE_LABEL = /^Of\s+(?:persons|things|place|time|animals|men|women|gods|goddesses|trees|plants|birds|fish|beasts|cattle|places|cities|countries|seasons|years|days|letters|sounds|manners|affairs|actions|events|the\s+mind|the\s+body|nature|divine\s+things|human\s+things)\.?\s*$/i;
const PAREN_REF = /\((?:cf\.?|syn\.?|v\.|q\.\s*v\.|opp\.|i\.\s*e\.|viz\.|etc\.)[^)]*\)/gi;
const PAREN_REF_TAIL = /\((?:cf\.?|syn\.?|v\.|opp\.)[^)]*\)\s*$/i;
const FRAG_START = new Set(("Fin Lit Esp Transf Neutr Act Pass Absol Justi Inf Fut Perf Imperf Pluperf Sup Comp Gen Dat Acc Abl Nom Voc Loc Part P. a. v. cf. etc. q. v. i. e. ap. id. Virg Verg Ov Hor Cic Caes Ter Plaut Sen Tac Gell Plin Suet Lucr App Charis Prisc Donat Serv Macr Pan Aug Orell Varr Fest Cato Cap Stich Rud Truc Pseud Most Poen").split(" "));
const MACRON = /[āēīōūĂĒĪŌŪƏ]|[àáâãåäèéêëìíîïòóôõöùúûü]/;
const GREEK = /[αβγδεζηθικλμνξοπρστυφχψωΑΒΓΔΕΖΗΘΙΚΛΜΝΞΟΠΡΣΤΥΦΧΨΩ]/;
const STRONG_OPEN = /^(?:to\s|a\s|an\s|the\s|one who\s|that which\s|a person who\s|a thing which\s|who\s|which\s|what\s|any\s|some\s|having\s|being\s|full of\s|made of\s|containing\s|capable\s|able\s|worthy\s|mindful of\s|out of one's\s|beside one's\s|pertaining to\s|belonging to\s|relating to\s|of or belonging to\s|of or pertaining to\s|used for\s|so called\s|called\s|all\b|every\b|each\b|another\b|who\b|which\b|what\b|whose\b|how\b|where\b|why\b)/i;
// grammar-abbrev density — the tell of a usage note ("The rel. freq. agrees with
// the foll. word") vs a real gloss ("All, every", "who? which?"). Also author
// names glued to the end of an example clause ("...dissolverunt?Cic").
const GRAMMAR_ABBR = /\b(?:neutr|plur|sing|freq|rel|foll|subst|interrog|impers|gen|dat|acc|abl|voc|nom|gramm|ellipt|collect|perh|esp|opp)\b\.?/i;
const TRAIL_AUTHOR_BARE = /(?:Cic|Liv|Plaut|Ter|Verg|Virg|Ov|Hor|Caes|Sen|Tac|Cat|Juv|Stat|Plin|Suet|Lucr|Tert|Gell|Curt|Varr|Enn|Isid|Amm|Charis|Prisc|Donat|Serv|Pan|App|Front|Lampr|Ambros|Val|Macr|Nep|Aus|Flor|Hier|Cassiod|Sid|Pall|Quint|Colum)\b\.?\s*$/i;
const WEAK_OPEN = /^(?:of\s|in\s|by\s|for\s|from\s|with\s|at\s|on\s|into\s|against\s|around\s|before\s|beyond\s|per\s|and\s|also\s|such\s|same\s|hence\s|esp\.\s|perh\.\s|that\s|those\s|this\s)/i;
const LATIN_FORM = /(?:isse|asse|unt|erit|tur|mus|tis|ium|ibus|arum|orum|ens)$/;
const ETYM = /(?:Sanscr\.|Germ\.|Engl\.|orig\.|collat\.\s+form|root\s+[a-z]+|perh\.\s+root|etym\.|cf\.\s+[A-Z][a-z]+\s+root|Osc\.|Goth\.|O\.?\s*H\.?\s*Germ\.|Lith\.|Slav\.|Skt\.|Icel\.|A.-S\.|O\.?\s*Lat\.)/i;
const LATIN_LOOKING = /^(?:sum|es|est|sumus|estis|sunt|eram|eras|erat|ero|eris|erit|sim|sis|sit|essem|esses|esset|fui|fuisti|fuit|fueram|fueras|fuerat|fuero|fueris|fuerit|fiam|fias|fiat|fiebam|fiebas|fiebat|fio|fimus|fitis|fiant|fierem|fieres|fieret|fierent|fiamus|fiatis|erimus|eritis)$/i;
const EN_WORDS = new Set(`to a an the of in by for from with at on into one who which what any some used having being full made containing capable able worthy called such same so hence also pertaining belonging relating or and but not as up down over under through between about after before during without within across toward against around above below near off out per than then there their they he she it we you do does did done make makes made give gives gave taken take took turn turns turned call calls called come comes came put puts find finds found keep keeps kept see sees saw seen set sets lead leads led hold holds held bring brings brought run runs running move moves moved stand stands lie lies lay born living thing person people place time day night hand head eye ear foot body blood water fire earth land sea sky sun moon star year month week end part side kind sort way manner means mode fashion force power strength might authority rule government law right wrong good bad evil great small large big high low deep broad wide long short old new young early late quick slow fast hard soft light heavy warm cold hot dry wet clean pure holy sacred common private public open shut close together apart alone single double triple fold like love hate fear joy grief sorrow pain hurt wound injury harm evil ill sick well whole safe sound strong weak feeble faint dim bright clear dark obscure hidden secret plain simple complex subtle keen sharp dull blunt rough smooth level even flat straight curved bent round square long broad short gentle mild harsh stern fierce wild tame soft sweet bitter sour acid tart sharp hot cold very really quite rather somewhat slightly wholly entirely utterly quite eg viz namely useful serviceable beneficial profitable advantageous pleasant agreeable delightful pleasing empty waste desert powerful prudent violent foreign blessed unlike resembling green wasteful effective valuable excellent worthy active passable capable ready fit suitable proper fitting meet convenient opportune seasonable timely becoming decorous fair beautiful handsome comely shapely well-made well-formed graceful elegant refined polished finished perfect complete whole entire total full crowded thick numerous many much great immense vast huge large spacious broad wide extensive far-far distant remote separated parted divided separate distinct several various diverse different varied manifold rich wealthy opulent sumptuous costly dear expensive precious rare valuable choice select exquisite superb superb fine nice delicious savory tasteful good savory wholesome healthy salubrious healthful sound firm stable steady constant continual perpetual everlasting eternal immortal lasting enduring abiding durable permanent lasting solid substantial strong mighty potent powerful forcible vigorous active energetic spirited mettlesome manly brave courageous valiant bold daring fearless intrepid dauntless resolute firm steadfast unyielding inflexible stubborn obstinate headstrong willful perverse wayward froward forward bold daring rash reckless heedless careless negligent remiss slack idle lazy indolent slothful sluggish torpid inert sluggish dull heavy stupid senseless foolish silly fatuous imbecile weak-minded witless simple foolish silly childish puerile boyish girlish womanish effeminate soft delicate tender fragile frail brittle weak feeble languid faint exhausted wearied tired weary fatigued jaded worn-out spent exhausted energy vigor virtue potency anger wrath rage fury passion upper lower higher outer inner former latter savage ferocious barbarous furious plain soil shore coast wave storm breeze grove meadow valley ridge cliff sand bloom blossom root branch leaf seed fruit flower corn grain wheat barley wine oil milk honey salt stone rock metal gold silver brass bronze iron copper tin lead vein mine quarry chasm cave shelter refuge haven port harbor bay gulf strait isle island cape headland promontory marsh fen bog morass heath moor down hill hilltop knoll summit peak crest precipice crag scar shelf ledge terrace bank mound heap pile stack mass bulk lump piece portion share lot quantity number amount sum total whole entire all every each both neither either any some few several many much more most least little smaller greater lesser upper lower inner outer former latter nearest farthest outermost innermost honey sweet darling wonderful strange thousand weary angry immense countless hungry himself exclusively times famine dearth sense senses insane mad frantic sleep sleepy drowsy dozy somnolent list register together always forever ever within upon among company along however nevertheless mount mountain sea heaven sky yours ours theirs hers its thy thine thou thee ye mine my your our their`.split(/\s+/));
const BIO_WORDS = new Set("king queen prince princess daughter son father mother brother sister wife husband god goddess nymph giant hero heroine warrior king king's people nation tribe city town river mountain island kingdom region country land sea kingly royal".split(/\s+/));
const FUNCTION = new Set(("to a an the of in by for from with at on into who which what and or but not as up down over under through between about after before during without within across toward against around above below near off out per than then there their they he she it we you so hence also such same perh esp etc i e v s c m n t o r or in for with out by of on at".split(" ")));
// GLOSS_RUN: "force, vigor, power, energy, virtue", "land, ground, soil", "much,
// great, many" — L&S's bare synonym-run primary senses. The old scorer only caught
// capitalized ADJ runs (isBareAdj), so common noun/adjective primaries scored 0
// and lost to a translated example ("terra"→"the sea", "vis"→"the same as Juno").
const GLOSS_RUN = /^[A-Z]?[a-z]{3,}(?:-[a-z]{3,})?(?:,\s*[a-z]{3,}(?:-[a-z]{3,})?)+$/;
// Latin inflections that rarely end English words — used to (a) exclude Latin
// runs from GLOSS_RUN and (b) reject pure-Latin clauses ("a proelio" = article +
// Latin ablative, an example not a gloss).
const LATIN_INFL = /(?:us|um|ae|is|em|am|as|es|os|unt|tur|mus|tis|ntur|ibus|orum|arum|oque|que)$/;
// "i. e." / "viz." introduce an explication of a specific referent, the signature
// of a translated example ("the upper, i. e. the Adriatic and Ionian Sea") rather
// than the general gloss. Slight penalty so the general gloss wins.
const IE_MARK = /(?:i\.\s*e\.|viz\.|id\s*est)/i;
function isEnglishWord(w) {
  const x = w.toLowerCase().replace(/^[^a-z]*|[^a-z]*$/g, "");
  return EN_WORDS.has(x) || BIO_WORDS.has(x) || /(?:ous|ful|able|ible|ive|ish|less|like|some|ed|ing|tion|ness|ment)$/.test(x);
}
// Count Latin-inflected tokens in a clause (lowercase, ≥4 chars, Latin inflection
// ending, not an English word, not an English-morphology word). "pisces,Aus" → 1;
// "the master, himself" → 0; "the famous" → 0 (-ous is English).
function latinCount(g) {
  let n = 0;
  for (const t of g.split(/[\s,]/)) {
    // skip capitalized words — proper nouns ("Samnium", "Hirpini") aren't Latin
    // inflections of English words, and counting them loses a real gloss to a
    // Latin-looking place name ("a city of the Hirpini in Samnium" vs "the
    // inhabitants of Aec").
    if (/^[A-Z]/.test(t)) continue;
    const w = t.toLowerCase();
    if (w.length >= 4 && /^[a-z]/.test(w) && LATIN_INFL.test(w) && !EN_WORDS.has(w)
        && !/(?:ous|ful|able|ible|ive|ish|less|like|some|ed|ing|tion|ness|ment)$/.test(w)
        // English plural of an EN_WORDS singular: "senses"→sense, "heavens"→heaven,
        // "things"→thing. Latin ablatives (-ibus) and genitives (-ae, -is) aren't
        // English plurals; require the singular in EN_WORDS so it's safe.
        && !(w.endsWith("es") && EN_WORDS.has(w.slice(0, -2) + "e"))
        && !(w.endsWith("s") && !w.endsWith("is") && !w.endsWith("us") && EN_WORDS.has(w.slice(0, -1)))) n++;
  }
  return n;
}
function isGlossRun(g) {
  if (!GLOSS_RUN.test(g)) return false;
  const toks = g.split(",").map(x => x.trim().toLowerCase());
  const firstRaw = g.split(",")[0].trim(); // original case — the capital check needs it
  // The FIRST token must be English (hyphen-compounds split for the check: a
  // honey-sweet first token is honey+sweet, both English) — kills Latin example
  // runs ("veni, vidi, vici", "omnia, adverbially, altogether, entirely").
  const firstWords = toks[0].split("-");
  // Abstract-noun primaries ("Godhead, divinity", "Deformity, ugliness",
  // "Debility, infirmity", "Disunion, disagreement") open with words ending
  // -ness/-head/-hood/-ity/-tion/-ion/-ment that aren't in EN_WORDS. L&S also
  // CAPITALIZES the first token of a primary run ("Mouldy, musty", "Greatness,
  // size"). Accept any capitalized first token that isn't a frag/author label.
  // (P2a — divinitas "Godhead, divinity" was losing to "The power of divining".)
  // Etymology language-name fragments ("Erse, aile", "Osc., Goth.") are capitalized
  // and would pass the capital-accept — but they're NOT glosses (alius2 was
  // getting "Erse, aile" for its old-form note before "another, other"). (P2a)
  const ETYM_LANG = new Set(["erse","osc","goth","gothic","skr","skt","a.-s","icel","old","lit","russ","cesc","bohem","irish","welsh","cornish","breton","gaul","celtic","slav","slavic","prus","pers","sanscr","sanscrit","lith","germ","engl","hibern","pol","polish","czech","hung","bulg","serb","lett","est","fin","norse","saxon","anglo"]);
  const firstOk = firstWords.some(w => EN_WORDS.has(w)
    || /(?:ous|ful|able|ible|ive|ish|less|like|some|ed|ing|ness|head|hood|ity|tion|ion|ment)$/.test(w)
    || (/^[A-Z]/.test(firstRaw) && !FRAG_START.has(toks[0]) && !FUNCTION.has(toks[0]) && !ETYM_LANG.has(toks[0])));
  if (!firstOk) return false;
  for (const t of toks) {
    if (FUNCTION.has(t)) return false;
    if (t.length >= 5 && LATIN_INFL.test(t) && !EN_WORDS.has(t)) return false;
  }
  return true;
}
function enCount(g) {
  // split on spaces AND hyphens so hyphen-compounds ("honey-sweet") count as English
  const toks = g.toLowerCase().replace(/[^a-z\s-]/g," ").split(/[\s-]+/).filter(w=>w.length>=3);
  let n = 0;
  for (const w of toks) {
    if (FUNCTION.has(w)) continue;
    if (EN_WORDS.has(w)) n++;
    else if (BIO_WORDS.has(w)) n++;
    else if (/(?:ous|ful|able|ible|ive|ish|less|like|some|ed|ing)$/.test(w) && !/^[a-z]{2,4}$/.test(w)) n++;
  }
  return n;
}
function isBareAdj(g, pos) {
  if (pos !== "ADJ") return false;
  const first = g.split(/[\s,]/)[0].toLowerCase();
  if (FRAG_START.has(first)) return false;
  if (FUNCTION.has(first)) return false;   // "With inf", "Of persons" are NOT adjectives
  // L&S bare adjectives open capitalized ("Useful", "Empty", "Desolate") or with
  // a known English word. A lowercase Latin verb form like "vive" (ends -ive) must
  // NOT qualify — it was getting a bare-ADJ bonus and beating the real gloss.
  if (!/^[A-Z]/.test(g) && !EN_WORDS.has(first)) return false;
  if (!EN_WORDS.has(first) && !/(?:ous|ful|able|ible|ive|ish|less|like|some|ed|ing)$/.test(first)) return false;
  return true;
}
function cleanOne(t) {
  t = t.trim();
  if (XREF.test(t)) return null;
  if (HEADER.test(t)) return null;
  if (SCOPE_LABEL.test(t)) return null;
  if (SAME_AS.test(t)) return null;
  if (/^(?:hence|whence|thence|wherefore|whereby)\b/i.test(t)) return null;
  if (ETYM.test(t)) return null;
  let m = t.match(/^((?:[a-z]+\.\s*)+(?:\[[^\]]*\]\s*)?),\s+/i);
  if (m) {
    const head = m[1].replace(/\[.*?\]/g,"").trim();
    const all = head.split(/\s+/).filter(Boolean).every(tok => ABBR_TOK.test(tok));
    // Don't strip a "Adj. dim. [mellitus]" head when it's followed by a hyphenated
    // English compound ("honey-sweet") — the [] is a cross-ref, not a section
    // label, and stripping it over-fragments the gloss. Only strip when the next
    // token is a plain gloss opener.
    const rest = t.slice(m[0].length);
    if (all && !/^[a-z]+-[a-z]/.test(rest) && !/^[a-z]+,/.test(rest)) t = rest.trim();
  }
  t = t.replace(/^In\s+(?:gen\.|partic\.|the\s+widest\s+sense),?\s*/i,"").replace(/^Lit\.\s*/i,"");
  // A standalone "Adj. dim. [mellitus]," / "Adj. of ..." / "dim. [X]" head before
  // the gloss — the [] is a cross-ref to the base form. Strip it so the gloss
  // survives ("Adj. dim. [mellitus], honey-sweet, darling" → "honey-sweet, darling").
  t = t.replace(/^(?:adj\.|dim\.|adv\.|freq\.|rare\.?|subst\.|m\.|f\.)\s+[a-z]+\.\s*\[[^\]]*\]\s*,\s*/i,"").trim();
  // section labels for pronoun/adverb senses: "Rel., who, which...", "Interrog., who?",
  // "Act., ...", "Neutr., ..." — strip so the real gloss opener survives
  t = t.replace(/^(?:Rel|Interrog|Act|Pass|Neutr|Absol|Lit|Transf|Esp|Prop|Trop|Subst|P\. a\.|In\s+gen|In\s+partic)\.?,?\s*/i,"");
  // pronoun labels with an optional etymology bracket: "Pron. poss. [tu], thy, thine..."
  // → "thy, thine..." (L&S gives the lemma's parent word in [] for derived pronouns).
  t = t.replace(/^(?:Pron\.?|Pronom\.?)(?:\s+[a-z]+\.?)?(?:\s*\[[^\]]*\])?\s*,?\s*/i,"");
  t = t.replace(PAREN_REF,"").trim();
  t = t.replace(PAREN_REF_TAIL,"").trim();
  t = t.replace(CIT_FULL,"").trim();
  t = t.replace(TAIL_CIT,"").trim();
  t = t.replace(TAIL_AUTHOR,"").trim();
  // Book-part / treatise-name residue that survives author stripping: the author
  // abbrev (Ambros., Tert., Coel. Aur., Macr.) is stripped but the book-part that
  // FOLLOWED it survives as ". de Tob", ". adv. Marc", ". Res. carn", ". Coel.
  // Aur", ". Od", ". C", ". S" etc. (P6 — decorosus "Elegant, beautiful. de Tob",
  // delatura "An accusation, information. adv", devorator "A devourer. Res. carn").
  t = t.replace(/[.,;:]\s*(?:de\s+[A-Za-z]+|adv|init|med|fin|od|c\.?\s*s|res\.?\s+carn|eccl|in\s+[A-Za-z]+|ep|sat|de\s+benef)\.?\s*$/i,"").trim();
  t = t.replace(/[.,;:]\s*[A-Z][a-z]{2,8}\.\s*$/,"").trim();
  // "Coel. Aur" / "Coel. Aurel" — Caelius Aurelianus cited by two-part name.
  t = t.replace(/[.,;:]\s*Coel\.?\s+Aur(?:el)?\.?\s*$/i,"").trim();
  // Short citation tails (H4, corpus-audit): 1-2 letter author abbrevs + book
  // refs that the 3+-letter CIT strips miss — "Inscr. Orell. no. 3199 and 7205",
  // ". R. R. 2, 1 med", "* Vitr. 1, 1 med", "* Hor. C. 1, 28, 5 al", "Cato,
  // R. R. 76 init", "Fl. 1, 742". Lowercase words (no., med, init, al) break the
  // digit-terminated assumption.
  t = t.replace(/[.,;:]\s*(?:no\.?\s*[\dIVXLCDM]+(?:\s*and\s*[\dIVXLCDM]+)*|Inscr\.?\s*Orell\.?|R\.\s*R\.?|Vitr\.|Hor\.\s*C\.?|Fl\.|Cels|Cato\s*,?\s*R\.?\s*R\.?|init|med|fin|al\.?)[\s\S]*$/i,"").trim();
  // "* Vitr. 1, 1 med" / "* Hor. C. 1, 28, 5 al" — a leading asterisk before the
  // author abbrev (L&S's note marker for a rare/uncertain reading).
  t = t.replace(/[.,;:]\s*\*\s*(?:Vitr\.|Hor\.\s*C\.?|Cic\.|Ov\.|Plin\.?|Tac\.?|Liv\.?|Verg\.?)[\s\S]*$/i,"").trim();
  // citation chains: "ap. Serv. l. l", "Arn. 3, p", "Arat. Phaen. 394 B. and K",
  // ", Treb. Poll", ", Firm" — an L&S author reference glued to the clause end
  // ("the plough-beam. ap. Serv. l. l", "a constellation, usu. called Bootes.
  // Arat. Phaen. 394 B. and K").
  t = t.replace(/[.,;:]\s*[A-Z][a-z]{2,8}\.\s*(?:[A-Z][a-z]{2,8}\.\s*)?(?:l\.\s*)?(?:p\.\s*)?\s*[\dIVXLCDM]+[\s\S]*$/,"").trim();
  t = t.replace(/\s+ap\.\s*[A-Z][a-z]{2,8}\..*$/,"").trim();
  t = t.replace(/[.,;:]\s*[A-Z][a-z]{3,}(?:\s*[A-Z][a-z]{2,8}\.?)?\s*$/,"").trim();
  // "Cic. de Or. 1, 43, 191; 2, 1, 2 al." — L&S cites the De Oratore by
  // "de Or." (after stripping the author + book digits, the "de Or." fragment
  // survives: "a famous lawyer, friend of L. Licinius Crassus. de Or").
  // REQUIRE a real separator AND a word boundary: a bare /de\s+or/i would match
  // the "de or" inside English words — "asiDE OR away" → declino "to turn asi",
  // "disquietUDE OR confusion" → interturbo "To produce disquietu".
  t = t.replace(/[.,;:]\s+\bde\s+Or\.?[\s\S]*$/i,"").trim();
  t = t.replace(CIT,"");
  t = t.replace(/\([^)]*\)\s*$/,"").trim();
  t = t.replace(/\([^)]*$/,"").trim();   // unclosed trailing paren (clause-split broke "(syn.: ...)" across clauses)
  t = t.replace(/[.,;]$/,"").trim();
  t = t.replace(/\s+(?:etc\.?|al\.|sq\.)$/i,"").trim();
  t = t.replace(/[.,;]$/,"").trim();
  // Terminal parenthetical with its trailing punctuation: L&S's usage-note tails
  // arrive as "(not in Cic.)." (paren + period) — the earlier `\([^)]*\)\s*$` strip
  // (line 201) can't match while the string ends in ".", and the period-strips above
  // run too late. Loop so "(rare but class.)." and "(not in Cic.)" both clear.
  // Guard: only strip when the paren content is a NOTE, not a real gloss qualifier
  // ("eat up (dainties)", "(of a law)", "(female)" are meaningful — keep them).
  {
    let guard = 0;
    let prev = "";
    while (t !== prev && guard++ < 4) {
      prev = t;
      // strip trailing "..., (NOTE)" where NOTE is a usage/era/frequency marker —
      // the note may be followed by a period "(not in Cic.)." or bare "(not in Cic.)".
      t = t.replace(/\s*\([.,;:.\s]*(?:not in [A-Z][a-z.]*|in [A-Z][a-z]*\.? (?:rare|several times)|late Lat\.|post-?aug\.?|ante-?class\.?|ante\s*-?\s*class\.?|eccl\.? Lat\.?|very rare|rare but class\.?|rarely|arch\.?|perh\.?|so, rarely|used chiefly|a few places|very\s+freq\.?\s+and\s+class\.?|freq\.?\s+and\s+class\.?|class\.?\s+and\s+freq\.?|except\s+in\s+[A-Z][a-z]+\.?|class\.?)[^)]*\)[.,;:]*\s*$/i,"").trim();
      t = t.replace(/[.,;:]\s*$/,"").trim();
    }
  }
  // Citation/note tails that survived the strip: "—Hence", "—Prov", "—Subst",
  // ", i. e", "belua, i. e" (cross-ref markers), ", 6, 495 sq" (pure locator).
  t = t.replace(/\s*—[A-Za-z.]{2,15}\s*$/,"").trim();
  t = t.replace(/[.,;:]\s*(?:i\.\s*e\.|cf\.|v\.\s*infra|q\.\s*v\.|id\.|ap\.)\s*$/i,"").trim();
  // ", v. X" / ". v. X" cross-ref tails (H3, corpus-audit): L&S appends the base
  // form to derived words — "A goddess, v. divus", "A cloud, v. nubes", "The left
  // hand, v. laevus". The cross-ref is NOT part of the gloss.
  t = t.replace(/[.,;:]\s*v\.\s*[A-Z][a-z]*\.?\s*$/i,"").trim();
  // ", opp. X" opposition note (H3): "Smooth, smoothed, not rough, opp. asper
  // (class.)" — the opposition note is a usage note, not the gloss, and it
  // triggers the GRAMMAR_ABBR "opp" penalty killing legitimate primaries (levis2).
  t = t.replace(/[.,;:]\s*opp\.\s*[a-zA-Z ]+\.?\s*$/i,"").trim();
  t = t.replace(/[.,;:]\s*\d+(?:\s*,\s*[IVXLCDM\d]+)*\s*(?:sq\.|sqq\.)?\s*$/,"").trim();
  // Proper-noun preamble: "Aeculanum (Aecae?), f. A city..." / "Roma, f. Rome" —
  // the entry's headword+gender is glued to the gloss and kills its STRONG_OPEN.
  t = t.replace(/^[A-Z][a-z]+(?:\s*\([^)]*\)\s*)?,\s*[fmn]\.\s+/i,"").trim();
  // Leading etymology/orthography prefix glued before the gloss: "memoria, mora,
  // etc., not from memini, mindful of a thing, remembering". Strip the leading
  // non-English prefix ONLY when it contains a clearly-Latin token (ends -ia/-ini/
  // -orum...), so "That may be easily united or joined together, sociable" (no
  // Latin token) is untouched.
  {
    const toks = t.split(/\s+/);
    const LATIN_ISH = /(?:ia|ini|orum|arum|oque|que|ibus|atur|antur|entur|atur|itur|atis|orum)$/;
    let hasLatin = false, firstEn = -1;
    for (let i = 0; i < toks.length; i++) {
      const w = toks[i].toLowerCase().replace(/^[^a-z]*|[^a-z]*$/g, "");
      if (!w) continue;
      // FUNCTION words are transparent — "not from memini, mindful..." must not
      // stop the scan at "not" (which is in EN_WORDS).
      if (FUNCTION.has(w)) continue;
      // isEn must recognize hyphen-compounds: "honey-sweet" splits into honey+sweet
      // (both English). A plain "honey" (tok[0]) would otherwise not be English and
      // firstEn skips past it to "darling", truncating the gloss.
      const isEn = EN_WORDS.has(w) || BIO_WORDS.has(w)
        || w.split("-").some(x => EN_WORDS.has(x) || BIO_WORDS.has(x))
        || /(?:ous|ful|able|ible|ive|ish|less|like|some|ed|ing|tion|ness|ment)$/.test(w);
      if (isEn) { firstEn = i; break; }
      if (LATIN_ISH.test(w)) hasLatin = true;
    }
    // Drop the leading non-gloss prefix (Latin etymology OR function-word run) so
    // the gloss starts at the first English content word: "not from memini,
    // mindful of a thing, remembering" → "mindful of a thing, remembering".
    // Only when a Latin token preceded it ("memini") — a first-token gloss like
    // "honey-sweet" must not be dropped.
    if (firstEn > 0 && hasLatin) t = toks.slice(firstEn).join(" ");
  }
  // Latin example glued after the English gloss: "Wonderful! how strange! indeed!
  // papae! divitias tu quidem habuisti luculentas" — the gloss ends at the first
  // Latin word that is followed by more Latin example text. "a market-place,
  // public square, forum" survives ("forum" is last; no English seen before it).
  // "Easily broken, or crumbled to pieces, friable" survives ("pieces" looks
  // Latin-ish but is followed by more gloss, not a citation).
  {
    const toks = t.split(/\s+/);
    let seenEn = false;
    for (let i = 0; i < toks.length; i++) {
      const w = toks[i].toLowerCase().replace(/^[^a-z]*|[^a-z]*$/g, "");
      if (!w) continue;
      if (FUNCTION.has(w)) continue;
      if (EN_WORDS.has(w) || BIO_WORDS.has(w) || /(?:ous|ful|able|ible|ive|ish|less|like|some|ed|ing|tion|ness|ment)$/.test(w)) { seenEn = true; continue; }
      // lowercase only — a capitalized word is a proper noun ("Son of Priam and
      // Hecuba": Priam ends in -am but is a name, not a Latin example tail).
      // Only truncate when a LATIN word follows the Latin one — a citation tail
      // ("...luculentas") — NOT when it's a gloss synonym ("...to pieces, friable").
      if (seenEn && w.length >= 4 && !/^[A-Z]/.test(toks[i]) && LATIN_INFL.test(w) && i < toks.length - 1) {
        const next = toks[i + 1].toLowerCase().replace(/^[^a-z]*|[^a-z]*$/g, "");
        // Require the following word to be ACTUALLY Latin-inflected too, not just
        // not-English. "prickles, thorny" (aculeatus) was truncating to "Furnished
        // with stings or" because "prickles" ends in -es (LATIN_INFL) and "thorny"
        // isn't in EN_WORDS — but neither is Latin. Real example tails always carry
        // Latin inflection ("...habuisti luculentas" → -as). Without this, English
        // plurals/adjectives in -y after an -es/-is word get cut mid-gloss.
        const nextLatin = next.length >= 4 && !EN_WORDS.has(next) && !/(?:ous|ful|able|ible|ive|ish|less|like|some|ed|ing|tion|ness|ment)$/.test(next)
          && !/^[A-Z]/.test(toks[i + 1]) && LATIN_INFL.test(next);
        if (nextLatin) { t = toks.slice(0, i).join(" "); break; }
      }
    }
  }
  // Pure-Latin clause, not a gloss: "a proelio" (article + Latin ablative) and
  // "a qua (gratia) te flecti... quam Herculem" are example translations, not
  // definitions. Reject an all-non-English clause with Latin-inflected tokens —
  // short ("a proelio": 1 Latin token) or long (2+ tokens).
  if (t.length >= 4 && enCount(t) === 0) {
    const toks = t.split(/\s+/).filter(Boolean);
    const latToks = toks.filter(tk => {
      // Proper nouns ("Senones", "Euryalus", "Venus") are NOT Latin inflections —
      // skip capitalized tokens before the lowercase check, mirroring latinCount.
      if (/^[A-Z]/.test(tk)) return false;
      const w = tk.toLowerCase();
      return w.length >= 4 && /^[a-z]/.test(w) && LATIN_INFL.test(w) && !EN_WORDS.has(w);
    });
    const nonFn = toks.filter(tk => !FUNCTION.has(tk.toLowerCase()) && tk.length >= 3 && !/^[A-Z]/.test(tk));
    const hasProperNoun = toks.some(tk => /^[A-Z]/.test(tk));
    // A relative-clause gloss ("mistress, she who rules or commands", "one who
    // watches over", "a person that takes") is ENGLISH, never a pure-Latin
    // example — the "she/he/one/those who" opener is an L&S definition pattern.
    // Its content words ("rules", "commands", "mistress") aren't in EN_WORDS and
    // look Latin-ish, which was triggering this rejection. (P2 straggler: domina)
    if (/^(?:she|he|one|those|they|a\s+person|a\s+thing)\s+who\b/i.test(t) || /\b(?:one|she|he|those)\s+who\b/i.test(t)) return t;
    if (latToks.length >= 2) return null;
    // A strong-opener gloss with a proper noun ("A festival of Venus", "A chieftain
    // of the Senones") is English, never a pure-Latin clause — escape the short-clause
    // reject. "a proelio" (no capital) still dies here.
    if (latToks.length >= 1 && nonFn.length <= 2 && !(hasProperNoun && STRONG_OPEN.test(t))) return null;
    // A pure Latin phrase: ≥2 non-function tokens, at least one Latin-inflected,
    // and NONE English-morphology ("consortio inter reges", "natura nos sociabiles
    // fecit", "sive ex inferiore loco... loquitur"). Short citation tokens ("Ep")
    // and capitals are filtered out of nonFn. "to shackle, hamper, hinder, hold
    // fast" has no Latin-inflected token; "poplar, poplar-tree" likewise survives.
    // A STRONG opener or comma-run shape ("A list, register, syllabus") is an
    // English gloss even if its words aren't in EN_WORDS — don't reject it.
    const glossShaped = STRONG_OPEN.test(t) || GLOSS_RUN.test(t);
    if (!glossShaped && nonFn.length >= 2 && latToks.length >= 1 && nonFn.every(tk => {
      const w = tk.toLowerCase().replace(/^[^a-z]*|[^a-z]*$/g, "");
      return w.length >= 3 && !EN_WORDS.has(w) && !/(?:ous|ful|able|ible|ive|ish|less|like|some|ed|ing|tion|ness|ment)$/.test(w);
    })) return null;
    // article + a Latin ablative: "a proelio" (-io isn't in LATIN_INFL). "an
    // appletree" and "a poplar, poplar-tree" don't end in a Latin ablative.
    const abl = toks.some(tk => /[aeiou]o$/.test(tk.toLowerCase()) && !EN_WORDS.has(tk.toLowerCase()));
    if (/^(?:a|an|the)\s+/i.test(t) && toks.length <= 4 && abl) return null;
  }
  if (!t || t.length < 4) return null;
  return t;
}
function scoreGloss(g, pos) {
  let s = 0;
  // Test run/adj shapes on the gloss WITHOUT trailing parenthetical notes —
  // "(good prose)", "(class.)", "(esp. of females, rarely of males)" survive
  // cleanOne and break GLOSS_RUN ("Deformity, ugliness (good prose)" fails the
  // run test → scores 0 and loses to a later sense). The note is not the gloss.
  // Only strip TRAILING parens — an internal parenthetical is real content
  // ("a teat, dug of animals (of a female)") and must not be removed.
  const shape = g.replace(/\s*\([^)]*\)\s*$/g, "");
  if (STRONG_OPEN.test(g)) s += 3;
  else if (isBareAdj(shape, pos)) s += 3;
  else if (isGlossRun(shape)) s += 3;
  else if (WEAK_OPEN.test(g)) s += 1;
  if (pos === "V" && /\bto\s+[a-z]/i.test(g)) s += 2;
  else if (pos !== "V" && /^to\s+[a-z]/i.test(g)) s -= 3;
  if (MACRON.test(g)) s -= 5;
  if (GREEK.test(g)) s -= 5;
  if (/=\s*[a-z]/i.test(g)) s -= 3;
  if (/^[a-z]+\d*$/.test(g) && !/^(to|a|an|the|of|in|by|for|from|with|at|on)$/.test(g)) s -= 2;
  const first = g.split(/[\s,]/)[0].toLowerCase();
  if (LATIN_FORM.test(first)) s -= 3;
  if (LATIN_LOOKING.test(first)) s -= 3;
  if (/^[A-Z]/.test(g) && FRAG_START.has(first)) s -= 3;
  // grammar-note density: "The rel. freq. agrees..." / "the neutr. plur. omnia
  // is often closely connected..." — these are usage notes, not definitions.
  // Test on `shape` (paren-stripped): a trailing "(class.)"/"(freq. and class.)"
  // that scoreGloss already strips as a note must NOT also trigger the tail
  // penalty — "Greatness, size, bulk, magnitude (class.)" was getting the run +3
  // then a −4 (line 380's class\.) and −2 (line 381's class\.) for the same note.
  if (GRAMMAR_ABBR.test(g)) s -= 4;
  // a bare author name glued to the clause end = a translated example, not a gloss
  if (TRAIL_AUTHOR_BARE.test(g)) s -= 4;
  if (/(?:\s(?:hence|cf|syn|freq\.|class\.|absol|neutr|act\.|pass\.|in\s+gen\.))\s*,?\s*(?:\([^)]*\))?$/i.test(shape)) s -= 4;
  if (/\((?:cf\.?|syn\.?|freq\.?|rare|class\.?|poet\.?|ante-?class\.?)\)?$/i.test(shape)) s -= 2;
  if (IE_MARK.test(g)) s -= 3;
  // "very rare, and only of the eyes" — a usage-restriction note, not a gloss.
  if (/^(?:very\s+rare(?:ly)?|rarely|in\s+very\s+rare|rare\b)/i.test(g)) s -= 3;
  return s;
}
// Selection is DECOUPLED from detection (panel M-008 consensus):
//  - detection = cleanOne + the hard gates below (a clause is usable or not);
//  - selection = score desc → latinCount asc → EARLIEST SENSE asc → shorter.
// No comma-count/runTokens preference — it rewarded citation fragments.
// L&S primacy is positional (senses are ordered by primacy), so among equal-score
// candidates the earliest sense is the primary. Verbs need no special case:
// "to bear..." in s[4] beats "to move or go swiftly" in s[6] by sense order.
function better(cand, best, pos) {
  if (cand.sc !== best.sc) return cand.sc > best.sc;
  const la = latinCount(cand.g), lb = latinCount(best.g);
  if (la !== lb) return la < lb;
  // L&S orders senses by primacy — among equal-score, equal-latin candidates the
  // EARLIEST sense is the primary ("to bear, carry" in s[0] beats "to move or go
  // swiftly" in s[6]; "a needle" in s[0] beats "a buckle" in s[3]; malus's "an
  // evil" in s[1] beats the narrower "hurt, harm" in s[4]).
  if (cand.sense !== best.sense) return cand.sense < best.sense;
  // English synonym-run richness within a sense: "upper, higher" (2) beats "the
  // lower or Etruscan Sea)" (0); "land, ground, soil" (3) beats "the sea" (0).
  // Fragments like "pisces,Aus" score 0 because their segments aren't English.
  const a = runTokens(cand.g), b = runTokens(best.g);
  if (a !== b) return a > b;
  // English content within a sense: "A city of the Hirpini" (en 1) beats "the
  // inhabitants of Aec" (en 0).
  if (cand.en !== best.en) return cand.en > best.en;
  if (cand.g.length !== best.g.length) return cand.g.length < best.g.length;
  return false;
}
// Count comma-segments that are a SINGLE English content word ("land, ground,
// soil" = 3). Latin fragments ("pisces,Aus"), abbreviation fragments (", , f") and
// multi-word segments don't count.
function runTokens(g) {
  return g.split(",").filter(seg => {
    const w = seg.trim();
    if (!/^[A-Za-z-]{3,}$/.test(w)) return false;
    const words = w.toLowerCase().split("-");
    return words.some(x => EN_WORDS.has(x) || BIO_WORDS.has(x) || /(?:ous|ful|able|ible|ive|ish|less|like|some|ed|ing|tion)$/.test(x));
  }).length;
}
// Hard gates that remove a clause from the candidate set before ranking. These
// are boolean rejections, not soft penalties — rejection is monotone (it only
// removes candidates, never flips a right answer to a wrong one) and recoverable
// (fall through to the next sense → WORDS).
function usable(g, pos) {
  if (!g || g.length < 4) return false;
  // citation/author residue survived cleanOne: "Ov. M", "Treb", "puella,Hier. Ep"
  if (TRAIL_AUTHOR_BARE.test(g)) return false;
  // abbreviation-only fragment: ", , f", "Hence, adv", "belua, i. e"
  // Interrogative glosses ("in what manner? how? whereby?") carry "?" — strip the
  // trailing punct before the token test so qui2's "how? whereby?" isn't dropped
  // to just FUNCTION words. (H4, corpus-audit — qui2 was MISSING.)
  const realWords = g.split(/[\s,]/).map(w => w.replace(/[?!,;:.]+$/, "")).filter(w => /^[A-Za-z-]{3,}$/.test(w));
  if (realWords.length === 0) return false;
  if (realWords.every(w => FRAG_START.has(w) || FUNCTION.has(w.toLowerCase()))) return false;
  // A clause opening with the INDEFINITE/definite article that contains ZERO
  // English content words AND ≥2 non-capital non-English tokens is a translated
  // Latin example, not a gloss: "an quod te imperator consulit", "a mima uxore",
  // "a se dolores, morbos, debilitates repellere". The article gives such clauses
  // STRONG_OPEN +3 and they beat the real primary. The ≥2-word requirement keeps
  // legitimate 1-2 word article glosses ("A sponge", "A poplar, poplar-tree",
  // "The antipodes", "A stopple, plug") — their single content word isn't in
  // EN_WORDS but IS the gloss. "A festival of Venus" (proper noun) survives via
  // the capital check. (P3)
  if (/^(?:a|an|the)\s+/i.test(g) && enCount(g) === 0) {
    const after = g.replace(/^(?:a|an|the)\s+/i, "");
    const tokens = after.split(/[\s,;:]+/).filter(t => /^[a-z]{3,}/i.test(t));
    const nonEn = tokens.filter(t => !EN_WORDS.has(t.toLowerCase()) && !/^[A-Z]/.test(t)
      && !/(?:ous|ful|able|ible|ive|ish|less|like|some|ed|ing|tion|ness|ment)$/.test(t.toLowerCase()));
    // ≥3 non-English tokens = a Latin example ("an quod te imperator consulit",
    // "a se dolores, morbos, debilitates repellere"). 1-2 non-English content
    // words are legitimate rare-English glosses ("A sponge", "A poplar,
    // poplar-tree", "The antipodes", "A stopple, plug"). (P3)
    if (nonEn.length >= 3) return false;
  }
  // A single CAPITALIZED short word is usually an author/fragment ("in Psa",
  // "Pers", "Vulg", "Ov"), not a gloss. BUT it also kills real one-word primaries
  // ("Sweet", "Great", "Bad", "Good", "High") that L&S capitalizes — dulcis was
  // losing its "Sweet" primary this way. Only reject when the word is a KNOWN
  // author/frag token (FRAG_START + author abbrevs), never a real English word. (P2b)
  if (realWords.length === 1 && /^[A-Z][a-z]{1,4}$/.test(realWords[0])
      && (FRAG_START.has(realWords[0]) || /^(?:Cic|Liv|Plaut|Ter|Verg|Virg|Ov|Hor|Caes|Sen|Tac|Cat|Juv|Stat|Plin|Suet|Lucr|Tert|Gell|Curt|Varr|Enn|Isid|Amm|Charis|Prisc|Donat|Serv|Pan|App|Vulg|Pers|Psa|Macr|Col|Quint|Flor|Aus|Hier|Lampr|Ambros|Nep|Cassiod|Sid|Pall)$/.test(realWords[0]))) return false;
  // a pure Latin/abbrev tail glued to an example: "in fame frumentum exportare. Fl"
  if (/[.,;:]\s*[A-Z][a-z]{2,8}\.\s*$/.test(g)) return false;
  // usage/construction explanations, not glosses: "Where the person or thing
  // referred to is to be emphatically distinguished from others", "the person or
  // thing referred to is to be emphatically distinguished", "When a thing is
  // predicated of..." — relative-clause sentences explaining a construction.
  if (/^(?:where|when|how|why)\b/i.test(g)) return false;
  if (/^the\s+(?:person|thing|object|subject|word|pronoun|noun|verb)\s+(?:or\s+\w+\s+)?referred to\s+(?:is|was) to be/i.test(g)) return false;
  // grammatical meta-notes, not glosses: "in two forms", "in three ways", "in
  // four senses" — the declension/orthography section headers of a complex entry.
  if (/^in\s+(?:one|two|three|four|five|both|a|an)\s+(?:forms?|ways?|senses?|numbers?|syllables?)\b/i.test(g)) return false;
  // Text-critical / orthography editor notes, not glosses (P4): "the best reading
  // is", "the correct read. is", "the form discribo seems to have been used", "an
  // ancient and rare form", "In a double sense". These are English and score via
  // STRONG_OPEN "the"/"an" +3, beating the real primary (declinatus "Variation,
  // inflection of words" was losing to "the best reading is"). (P4)
  if (/^(?:the\s+(?:best|correct|true|right|more\s+usual)\s+(?:reading|read\.|form|orthogr|spelling)\b|an\s+(?:ancient|old)\s+and\s+rare\s+form\b|in\s+a\s+double\s+sense\b|the\s+form\s+[a-z]+)/i.test(g)) return false;
  return true;
}
// R2 (panel data-expert): a clause that OPENS an English gloss run is the primary
// even when its 40-char `before` window contains etymology/Greek ("Sanscr. root
// smar-... mindful of a thing", "...prop. the dry land, ... land, ground, soil").
// L&S puts the noun/verb primary at the TAIL of senses[0] AFTER the etymology
// block; the old guard skipped exactly those.
function isGlossyOpen(raw) {
  // NOT WEAK_OPEN: etymology fragments also open with "in/of/with" ("in smarti,
  // memory" is Sanskrit etymology, not a gloss). Only a strong opener, a bare
  // synonym run, or an English content word is a real gloss opener.
  if (STRONG_OPEN.test(raw) || isGlossRun(cleanOne(raw) || "")) return true;
  const first = ((cleanOne(raw) || "").split(/[\s,]/)[0] || "").toLowerCase();
  return first.length >= 3 && (EN_WORDS.has(first) || BIO_WORDS.has(first) || /(?:ous|ful|able|ible|ive|ish|less|like|some|ed|ing)$/.test(first));
}
function bestClause(s, pos) {
  const clauses = s.split(/[;:]/).flatMap(c => c.split(/,\s+(?=to\s|a\s|an\s|the\s|of\s|in\s|by\s|for\s|from\s|with\s|who\s|which\s|one\s|that\s|much\b|few\b|little\b|many\b|great\b|upper\b|lower\b|former\b|latter\b)/))
    // definitions that follow a closing etymology bracket: "Engl. else], another, other"
    .flatMap(c => c.split(/\]\s*,?\s+(?=a\b|an\b|the\b|one\b|who\b|which\b|what\b|to\b|another\b|other\b)/))
    // L&S chains subordinate notes with an em-dash ("a probe, Cels. 7, 17.—Hence,
    // acu pingere..."). A gloss never contains an em-dash; split so the note is
    // its own (rejected) clause instead of gluing a citation to the gloss.
    .flatMap(c => c.split(/—/));
  let best = null;
  let cursor = 0;
  for (const c of clauses) {
    const start = s.indexOf(c, cursor);
    const before = start >= 0 ? s.slice(Math.max(0, start - 40), start) : "";
    cursor = start >= 0 ? start + c.length : cursor;
    // GREEK context is ALWAYS etymology ("Gr. φλυω, to bubble up") — skip it,
    // UNLESS the Greek is separated from the clause by a ";" or "]" (the etymology
    // block closed and the real gloss follows: "Gr. μάρτυς, witness; ... mindful
    // of a thing"). Check the segment AFTER the last ";" in the 40-char window:
    // "φλυ-; Gr. φλυω, " has Greek after the ";" → reject; "μεριμνα, care; cf.: "
    // has Greek BEFORE the ";" → allow.
    if (GREEK.test(before)) {
      const cut = Math.max(before.lastIndexOf(";"), before.lastIndexOf("]"));
      const seg = before.slice(cut + 1);
      if (GREEK.test(seg)) continue;
    }
    if (ETYM.test(before) && !/[\]\)][\s.,;:]*$/.test(before) && !isGlossyOpen(c)) continue;
    const r = cleanOne(c);
    if (!r) continue;
    if (!usable(r, pos)) continue;
    // era preference on the RAW clause (cleanOne strips the era note): the
    // classical sense is the primary one users want, the late/post-Aug./rare
    // sense is a marginal add-on — "to inhabit (class.)" beats "to cultivate (late Lat.)"
    let era = 0;
    // standalone "class." (not "post-class."/"ante-class.") is the classical marker.
    // +1 kept (2026-08-08): the panel's "cap the class. era bonus" idea was tried
    // (era=0) and REVERTED — it regressed impedio golden (a class.-marked earlier
    // sense "To entangle, embarrass (class.)" needs the +1 to tie-and-win on
    // sense-order over a later higher-scoring clause). The sum/lego/dico cases it
    // was meant to fix are handled by the CORE_GLOSS override table instead.
    // A standalone "(class.)" marker is the legit classical signal (impedio's
    // "To entangle, embarrass (class.)" needs the +1). But "class." buried in a
    // usage-note paren ("(freq. and class.)", "(very freq. and class.)") is a
    // note cleanOne strips — it must NOT award the era bonus (levo's trop. sense
    // "to lighten, relieve... (freq. and class.)" was scoring 6 via the +1 and
    // beating the primary "to lift up, raise" at 5). Distinguish: a paren whose
    // content is ONLY the class. marker is standalone; one with other words is a note.
    const pm = c.match(/\(([^)]*class\.[^)]*)\)/i);
    if (pm) {
      const inner = pm[1].replace(/class\./gi, "").replace(/[^a-z]/gi, "");
      era = inner.length === 0 ? 1 : 0;
    } else if (/(?:^|[\s(])class\./i.test(c)) era = 1;
    // late/rare senses are demoted hard (data-expert R7): they should only win by
    // the fallback, never beat the classical primary ("a violent longing" (post-Aug.)
    // must not beat "Famine, dearth" (class.)). "perh." (perhaps) is a FREQUENCY
    // hedge, not a late/rare marker — "(so, rarely, and perh. only in Cic.)" is a
    // classical primary and must NOT be demoted (dignitas s[1] was losing to a
    // marginal clause).
    else if (/\b(?:late|post-?aug|ante-?class|arch\.?|very\s+rare)\b/i.test(c)) era = -3;
    const baseSc = scoreGloss(r, pos), sc = baseSc + era, en = enCount(r);
    if (!best || better({ sc, baseSc, g: r, en, sense: -1 }, best, pos)) best = { sc, baseSc, g: r, en, sense: -1 };
  }
  return { best: best && best.g, bestScore: best && best.sc, bestBase: best && best.baseSc, bestEn: best && best.en };
}
function flattenSenses(senses) {
  const out = [];
  const walk = (arr) => { for (const s of arr) { if (typeof s === "string") out.push(s); else if (Array.isArray(s)) walk(s); } };
  walk(senses);
  return out;
}
function lsExtract(e, pos) {
  if (!e || !e.senses || e.senses.length === 0) return null;
  const all = flattenSenses(e.senses);
  // SINGLE GATED PASS (panel M-008): walk every sense in order; the best clause
  // of each sense is a candidate. Selection = score → latinCount → earliest
  // sense → shorter. L&S orders senses by primacy, so "upper, higher" in s[3]
  // beats the later superlative run "the highest, greatest, most exalted,
  // supreme" (equal score, earlier sense). Verbs resolve the same way ("to bear"
  // in s[4] beats "to move or go swiftly" in s[6]).
  let cand = null;
  for (let i = 0; i < all.length; i++) {
    const b = bestClause(all[i], pos);
    if (!b.best) continue;
    const c = { sc: b.bestScore, baseSc: b.bestBase, g: b.best, en: b.bestEn, sense: i };
    if (!cand || better(c, cand, pos)) cand = c;
  }
  if (!cand) return null;
  // ACCEPTANCE FLOOR (detection, decoupled from selection): a selected clause is
  // only usable if it scores well OR carries ≥2 English content words. Uses the
  // BASE score (without era penalty) so a legitimate rare/era gloss ("A stopple,
  // plug (post-Aug.)", "A sponge (late Lat.)") isn't nulled — the era penalty
  // demotes RANKING (a post-Aug. secondary must not beat the classical primary)
  // but must not reject a real gloss outright.
  if (cand.baseSc >= 2 || (cand.baseSc >= 0 && cand.en >= 2)) return cand.g;
  return null;
}

const POS_MAP = { n:"N", v:"V", a:"ADJ", d:"ADV", r:"PREP", c:"CONJ", e:"INTERJ", p:"PRON", m:"NUM" };
const GEN_MAP = { m:"M", f:"F", n:"N", c:"C" };

// ---- wordlist index ----
const rows = new Map();
const formSets = new Map();
const lemmaPosCount = new Map();
for (const line of fs.readFileSync("macronizer/macrons.txt","utf8").split("\n")) {
  const p = line.split("\t"); if (p.length<4) continue;
  const lem = p[2].toLowerCase();
  rows.set(p[2]+"|"+p[1], {lemma:p[2], tag:p[1]});
  if (!formSets.has(lem)) formSets.set(lem, new Set());
  // ACCENT-BASED form signature (form + accented form): distinct vowel length
  // proves two homograph keys are DISTINCT words (levo "levo" vs levo2 "levare"
  // to smooth — le^v- vs le_va-), while an identical signature means the wordlist
  // duplicated one word under two keys (paro/paro2, acceptor/acceptor2). The old
  // form+tag signature conflated distinct words (levo2 got the bare levo1 "to lift
  // up" instead of "to smooth, polish"). H1 fix (corpus-audit 2026-08-08).
  formSets.get(lem).add(p[0]+"|"+p[3]);
  const pos = POS_MAP[p[1][0]] || p[1][0];
  if (!lemmaPosCount.has(lem)) lemmaPosCount.set(lem, {});
  lemmaPosCount.get(lem)[pos] = (lemmaPosCount.get(lem)[pos]||0)+1;
}
function dominantPos(lem) {
  const cnt = lemmaPosCount.get(lem) || {};
  let best=null,bestN=0;
  for (const [p,n] of Object.entries(cnt)) if (n>bestN) {best=p;bestN=n;}
  return best || "N";
}
function isSpurious(l) {
  const m = l.match(/^(.*?)(\d+)$/);
  if (!m) return false;
  const bare = m[1];
  const a = formSets.get(l), b = formSets.get(bare);
  if (!a || !b || a.size !== b.size) return false;
  for (const k of a) if (!b.has(k)) return false;
  return true;
}
// For a base like "alius", find the numbered sibling key the WORDLIST carries
// (alius2) — used by the case-collision guard to steer a capitalized wordlist
// lemma (Alius) away from a proper-noun L&S homograph-1 onto the common-word
// numbered key. Returns the highest existing sibling key (alius2 > alius3...).
// Precomputed once so resolve() is O(1) per lemma (the naive per-call scan of all
// ~40k L&S keys made the full build O(n²) — a hidden ~minutes).
const lsSibling = new Map();
for (const k of lsByKey.keys()) {
  const m = k.match(/^(.*?)(\d+)$/);
  if (!m) continue;
  const base = m[1], n = +m[2];
  const prev = lsSibling.get(base);
  if (!prev || n > prev.n) lsSibling.set(base, { key: k, n });
}
function numberedSibling(base) {
  const s = lsSibling.get(base);
  return s ? s.key : null;
}
function resolve(lemma, pos, depth = 0) {
  const l = lemma.toLowerCase();
  const base = l.replace(/\d+$/,"");
  // CORE_GLOSS is a human assertion — it wins over any extractor output. Keyed by
  // the FULL lowercase lemma (NOT number-stripped base): populus2 (poplar) must not
  // hit a coreGloss.populus ("a people"), and malus2 (apple-tree) must not hit
  // coreGloss.malus ("bad"). Core keys are all bare lemmas, so a numbered wordlist
  // lemma simply won't collide. An EXPLICIT null value = force fail-safe "—"
  // (strip the gloss entirely — a wrong gloss is worse than none).
  if (Object.prototype.hasOwnProperty.call(coreGloss, l)) {
    if (coreGloss[l] === null) return null;
    return coreGloss[l];
  }
  let e;
  if (isSpurious(l)) {
    // Spurious-homograph skip normally prefers the bare key (the wordlist
    // duplicated one homograph under two keys — paro2 is the same *prepare* verb
    // as paro, so bare paro1 "make ready" is right). BUT when the bare twin's
    // homograph-1 is a CAPITALIZED proper noun (wordlist alius2 = the pronoun,
    // bare "Alius1" = "native of Elis"), the numbered key is the common word and
    // must win (alius2 → "another, other").
    const h1 = lsByKey.get(base + "1");
    if (h1 && /^[A-Z]/.test(h1.key)) e = lsByKey.get(l) || null;
    else e = lsByKey.get(base) || lsByKey.get(base + "1");
  }
  else {
    // CASE-COLLISION GUARD: a capitalized wordlist lemma can be a case-variant of
    // a common word (wordlist "Alius" = the pronoun "other", capitalized because
    // Perseus treated it as a proper noun), which would collide with an L&S
    // proper-noun homograph-1 ("Alius1" = "native of Elis"). If the L&S homograph-1
    // key is itself capitalized (proper noun) and the wordlist has a numbered
    // sibling for the same base, resolve the sibling instead (alius2 = the pronoun).
    const h1 = lsByKey.get(base + "1");
    if (/^[A-Z]/.test(lemma) && h1 && /^[A-Z]/.test(h1.key)) {
      const sib = numberedSibling(base);
      if (sib) {
        const se = lsByKey.get(sib);
        if (se) {
          const sg = lsExtract(se, pos);
          if (sg) return sg;
        }
      }
    }
    e = lsByKey.get(l) || lsByKey.get(base) || lsByKey.get(base+"1");
  }
  if (!e) return null;
  let gloss = lsExtract(e, pos);
  if (!gloss && depth < 2 && e.main_notes) {
    const m = e.main_notes.match(/(?:^|[,;]|\s)(?:v|cf)\.\s*([a-z]+)/i);
    if (m) {
      const tgt = m[1].toLowerCase();
      const te = lsByKey.get(tgt) || lsByKey.get(tgt+"1");
      if (te && te !== e) gloss = resolve(tgt, dominantPos(tgt), depth + 1);
    }
  }
  return gloss;
}
const wc = new Map();
function wcLoad(base) {
  if (!wc.has(base)) {
    let ps = [];
    try { const a = engine.parseWord(base); ps = (a.results||[]).map(x=>({pofs:(x.ir&&x.ir.qual&&x.ir.qual.pofs)||"",g:(x.ir&&x.ir.qual&&x.ir.qual.noun&&x.ir.qual.noun.gender)||"",m:(x.de&&x.de.mean)||""})); } catch(e){}
    wc.set(base, ps);
  }
  return wc.get(base);
}
function wGloss(lemma, pos, gender) {
  const base = lemma.replace(/\d+$/,"");
  const all = wcLoad(base).filter(x=>x.pofs===pos);
  // Use gender only when it disambiguates: the wordlist tag's gender is often
  // wrong/imprecise (inoblitus tagged "m" but WORDS says "f"), and dropping to
  // an empty list silently loses a good gloss. Fall back to POS-only.
  let same = all;
  if (gender) { const gf = all.filter(x=>x.g===gender); if (gf.length) same = gf; }
  const distinct = new Set(same.map(x=>x.m.split(";")[0].trim().replace(/^\||\||$/g,"")));
  return distinct.size===1 ? [...distinct][0] : null;
}
// WORDS FIRST-RESULT mode for the closed particle class (M-005 fix, 2026-08-08).
// WORDS lists senses in frequency order; for function words the first sense IS the
// everyday one (et→"and", sed→"but", semper→"always", cum→"when/with"). L&S's
// function-word primaries are usage-notes ("a particle of limitation...") that
// lose the STRONG_OPEN ranking, so for the closed class WORDS wins. Result is
// cached through wcLoad (shared with wGloss).
function wGlossFirst(lemma) {
  const base = lemma.replace(/\d+$/,"");
  for (const x of wcLoad(base)) {
    const g = (x.m||"").split(";")[0].trim().replace(/^\||\||$/g,"");
    if (g) return g;
  }
  return null;
}

// ---- build ----
const SKIP_WORDS = process.env.SKIP_WORDS === "1";
const lemmaGloss = new Map();
let lClean=0,wClean=0,none=0, done=0;
const total = rows.size;
const t0 = Date.now();
// CLOSED-CLASS SET (M-005 fix, 2026-08-08): lemmas with ANY preposition/conjunction/
// interjection attestation (tag[0] ∈ {r,c,e}). Latin's prepositions are tagged both
// "d" (adv) and "r" (prep) in the wordlist (de, pro, inter, contra...), so dominant-POS
// undercounts them; the any-attestation set (157 lemmas) is the true closed class.
// For these, WORDS-first wins over L&S (see wGlossFirst); coreGloss entries still win
// over everything (checked inside resolve()). Counted once here for the build loop.
const closedSet = new Set();
for (const r of rows.values()) if (r.tag[0] === "r" || r.tag[0] === "c" || r.tag[0] === "e") closedSet.add(r.lemma.toLowerCase());
// resolve() is pure per lemma (same lem + dominantPos → same result) but the
// wordlist carries ~673k (lemma|tag) rows over only ~40k unique lemmas. Memoize
// by the EXACT lemma string (resolve is case-sensitive in the collision guard,
// so "Gallia" ≠ "gallia") to cut ~17× redundant work: ~330s → ~20s.
const resolveCache = new Map();
const wGlossCache = new Map();
const wGlossFirstCache = new Map();
for (const r of rows.values()) {
  const lem = r.lemma;
  const pos = dominantPos(lem.toLowerCase());
  const g6 = (pos==="N"||pos==="ADJ"||pos==="PRON") ? (GEN_MAP[r.tag[6]]||"") : "";
  let l = resolveCache.get(lem);
  if (l === undefined) { l = resolve(lem, pos); resolveCache.set(lem, l); }
  let w = null;
  let wFirst = null;
  let wFirstAny = null;
  if (!SKIP_WORDS) {
    const lemLower = lem.toLowerCase();
    // WORDS-first only for the closed particle class — cheap (157 lemmas), memoized
    // through wcLoad so the same parse serves both wGlossFirst and wGloss.
    if (closedSet.has(lemLower)) {
      wFirst = wGlossFirstCache.get(lemLower);
      if (wFirst === undefined) { wFirst = wGlossFirst(lem); wGlossFirstCache.set(lemLower, wFirst); }
    }
    const wk = lem + " " + pos + " " + g6;
    w = wGlossCache.get(wk);
    if (w === undefined) { w = wGloss(lem, pos, g6); wGlossCache.set(wk, w); }
    // P8: first WORDS result regardless of POS-uniqueness — the fallback for
    // common V/N lemmas whose WORDS POS-filter has >1 distinct meaning.
    wFirstAny = wGlossFirst(lem);
  } else wFirstAny = null;
  let gloss = null;
  const lemLower = lem.toLowerCase();
  // Precedence (M-005 fix): coreGloss > WORDS-first (closed particle class) > L&S
  // > WORDS-distinct (general fallback). `l` IS the core gloss when the lemma is a
  // core key (resolve short-circuits to it), so it must win even over wFirst —
  // enim→"for" (core) must beat WORDS' "namely", cis→"this side of" (core) must
  // beat WORDS' "move, set in motion". For the non-core closed class WORDS-first
  // wins over L&S, whose function-word primaries are usage-notes that lose the
  // STRONG_OPEN ranking (et→"used for et...et").
  if (Object.prototype.hasOwnProperty.call(coreGloss, lemLower)) {
    // coreGloss says something explicit: a string gloss OR null (force "—").
    // An explicit-null key must NOT fall through to L&S/WORDS — the curated
    // decision is "show nothing" (fail-safe over fail-loud).
    gloss = coreGloss[lemLower];
    if (gloss) lClean++; else none++;
  }
  else if (closedSet.has(lemLower)) {
    if (wFirst) { gloss = wFirst; wClean++; }
    else if (l) { gloss = l; lClean++; }
    else none++;
  }
  // L&S CROSS-REF VERB-LEAK GUARD (bug-hunter 2026-08-08): L&S main_notes
  // ("amanter, adv., v. amo", "potens, v. possum") makes resolve() recurse into
  // the base verb, so ADV/ADJ lemmas get the verb's INFINITIVE gloss (cito→"to
  // put in motion" should be "quickly", mortuus→"to die" should be "dead",
  // potens→"to be able" should be "powerful"). WORDS POS-filtered (wGloss) gives
  // the correct POS-aware gloss. Rule: an ADV/ADJ-dominant lemma whose L&S result
  // is a verb-infinitive ("to X") prefers WORDS-POS. Scoped narrowly so memor/
  // superus/saevus/certo (real adjective glosses, golden-locked) are untouched.
  else if ((pos === "ADV" || pos === "ADJ") && l && /^to\s+[a-z]/i.test(l)) {
    if (w) { gloss = w; wClean++; }
    else if (l) { gloss = l; lClean++; }
    else none++;
  }
  else if (l) { gloss = l; lClean++; }
  else if (w) { gloss = w; wClean++; }
  // P8 fallback (corpus audit): common V/N lemmas whose L&S entry is
  // orthography-heavy and whose WORDS POS-filter has >1 distinct meaning
  // (differo "postpone/delay" + "spread abroad") fell to "—". Relax to the
  // FIRST WORDS result (frequency-ordered) — a real gloss beats "—" for a
  // common verb. Scoped to V/N (the classes WORDS covers well).
  else if ((pos === "V" || pos === "N") && wFirstAny) { gloss = wFirstAny; wClean++; }
  else none++;
  if (gloss && !lemmaGloss.has(lem.toLowerCase())) lemmaGloss.set(lem.toLowerCase(), gloss);
  if (++done % 100000 === 0) console.log(`  ${done}/${total} (${((Date.now()-t0)/1000).toFixed(0)}s)`);
}

// ---- write artifact ----
const lines = [...lemmaGloss.entries()].map(([k,v])=>k+"\t"+v).join("\n");
fs.writeFileSync("macronizer/glosses.tsv.gz", zlib.gzipSync(lines,{level:9}));
const rawKB = (lines.length/1024).toFixed(0);
const gzKB = (fs.statSync("macronizer/glosses.tsv.gz").size/1024).toFixed(0);

// ---- metrics ----
console.log(`\nbuilt macronizer/glosses.tsv.gz in ${((Date.now()-t0)/1000).toFixed(0)}s`);
console.log(`unique (lemma|tag): ${total}`);
console.log(`L&S: ${lClean} (${(100*lClean/total).toFixed(1)}%)  WORDS: ${wClean} (${(100*wClean/total).toFixed(1)}%)  none: ${none} (${(100*none/total).toFixed(1)}%)  TOTAL: ${lClean+wClean} (${(100*(lClean+wClean)/total).toFixed(1)}%)`);
console.log(`unique glossed lemmas: ${lemmaGloss.size}`);
console.log(`artifact raw: ${rawKB} KB  gz: ${gzKB} KB`);
