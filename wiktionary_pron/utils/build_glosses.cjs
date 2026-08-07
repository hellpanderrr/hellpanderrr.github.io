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

// ---- extraction regexes (from the refined probe) ----
const XREF = /^(v\.\s*(the|a|id)|init\.|fin\.|q\.\s*v\.|perh\.|etym\.|lit\.|esp\.|abb\.)$/i;
const ABBR_TOK = /^(v\.|a\.|n\.|adj\.|adv\.|conj\.|prep\.|pron\.|interj\.|num\.|part\.|ger\.|sup\.|imper\.|inf\.|lit\.|in\s+gen\.|in\s+partic\.|prop\.|trop\.|transf\.|inch\.|patron\.|m\.|f\.|dim\.|eccl\.|subst\.|poet\.|arch\.|old\.|dep\.|freq\.)/i;
const CIT = /[,;]\s*(?:id\.\s*)?(?:ap\.\s*)?(Plaut|Cic|Liv|Ov|Hor|Verg|Virg|Cat|Sen|Tac|Caes|Ter|Juv|Stat|Col|Plin|Suet|Lucr|Tert|Aug|Gell|Curt|Varr|Enn|Id|Eur|Hdt|Hom|Her|Isid|Amm|Spart|Vulg|Luc|Prop|Tib|Ulp|Paul|Fest|Dig|Cod|Hyg|Front|Charis|Prisc|Donat|Serv|Solin|Pan|App)\b/i;
const TAIL_CIT = /[.,;:]\s*(?:[A-Z][a-z]{2,8}\.\s*)?(?:[IVXLCDM]+|\d+)(?:\s*,\s*(?:§\s*)?[IVXLCDM\d]+)*\s*[,;]?\s*(?:§\s*\d+)?\s*(?:[A-Z][a-z]+\.?\s*\d*)?\s*\.?$/;
const TAIL_AUTHOR = /[.,;:]\s*(?:[A-Z][a-z]{2,8}\.|[A-Z]\.\s*[A-Z]\.?)(?:\s*[A-Z]?\.?\s*(?:p\.\s*)?\d*)?\s*\.?$/;
const CIT_FULL = /[.,;:]\s*(?:id\.\s*)?(?:ap\.\s*)?[A-Z][a-z]{2,8}\.\s*(?:[IVXLCDM]+|\d+)(?:\s*,\s*(?:§\s*)?[IVXLCDM\d]+)*\s*[,;]?\s*(?:§\s*\d+)?\s*(?:fin\.?)?\s*\.?$/;
const HEADER = /^(?:In\s+(?:gen\.|partic\.|the\s+widest\s+sense)|Lit\.?|Transf\.?|Esp\.?|Fin\.?|Neutr\.?|Act\.?|Pass\.?|Absol\.?|P\.\s*a\.|Prop\.?|Trop\.?)$/i;
const SCOPE_LABEL = /^Of\s+(?:persons|things|place|time|animals|men|women|gods|goddesses|trees|plants|birds|fish|beasts|cattle|places|cities|countries|seasons|years|days|letters|sounds|manners|affairs|actions|events|the\s+mind|the\s+body|nature|divine\s+things|human\s+things)\.?\s*$/i;
const PAREN_REF = /\((?:cf\.?|syn\.?|v\.|q\.\s*v\.|opp\.|i\.\s*e\.|viz\.|etc\.)[^)]*\)/gi;
const PAREN_REF_TAIL = /\((?:cf\.?|syn\.?|v\.|opp\.)[^)]*\)\s*$/i;
const FRAG_START = new Set(("Fin Lit Esp Transf Neutr Act Pass Absol Justi Inf Fut Perf Imperf Pluperf Sup Comp Gen Dat Acc Abl Nom Voc Loc Part P. a. v. cf. etc. q. v. i. e. ap. id. Virg Verg Ov Hor Cic Caes Ter Plaut Sen Tac Gell Plin Suet Lucr App Charis Prisc Donat Serv Macr Pan Aug Orell Varr Fest Cato Cap Stich Rud Truc Pseud Most Poen").split(" "));
const MACRON = /[āēīōūĂĒĪŌŪƏ]|[àáâãåäèéêëìíîïòóôõöùúûü]/;
const GREEK = /[αβγδεζηθικλμνξοπρστυφχψωΑΒΓΔΕΖΗΘΙΚΛΜΝΞΟΠΡΣΤΥΦΧΨΩ]/;
const STRONG_OPEN = /^(?:to\s|a\s|an\s|the\s|one who\s|that which\s|a person who\s|a thing which\s|who\s|which\s|what\s|any\s|some\s|having\s|being\s|full of\s|made of\s|containing\s|capable\s|able\s|worthy\s|pertaining to\s|belonging to\s|relating to\s|of or belonging to\s|of or pertaining to\s|used for\s|so called\s|called\s)/i;
const WEAK_OPEN = /^(?:of\s|in\s|by\s|for\s|from\s|with\s|at\s|on\s|into\s|against\s|around\s|before\s|beyond\s|per\s|and\s|also\s|such\s|same\s|hence\s|esp\.\s|perh\.\s)/i;
const LATIN_FORM = /(?:isse|asse|unt|erit|tur|mus|tis|ium|ibus|arum|orum|ens)$/;
const ETYM = /(?:Sanscr\.|Germ\.|Engl\.|orig\.|collat\.\s+form|root\s+[a-z]+|perh\.\s+root|etym\.|cf\.\s+[A-Z][a-z]+\s+root)/i;
const LATIN_LOOKING = /^(?:sum|es|est|sumus|estis|sunt|eram|eras|erat|ero|eris|erit|sim|sis|sit|essem|esses|esset|fui|fuisti|fuit|fueram|fueras|fuerat|fuero|fueris|fuerit|fiam|fias|fiat|fiebam|fiebas|fiebat|fio|fimus|fitis|fiant|fierem|fieres|fieret|fierent|fiamus|fiatis|erimus|eritis)$/i;
const EN_WORDS = new Set(`to a an the of in by for from with at on into one who which what any some used having being full made containing capable able worthy called such same so hence also pertaining belonging relating or and but not as up down over under through between about after before during without within across toward against around above below near off out per than then there their they he she it we you do does did done make makes made give gives gave taken take took turn turns turned call calls called come comes came put puts find finds found keep keeps kept see sees saw seen set sets lead leads led hold holds held bring brings brought run runs running move moves moved stand stands lie lies lay born living thing person people place time day night hand head eye ear foot body blood water fire earth land sea sky sun moon star year month week end part side kind sort way manner means mode fashion force power strength might authority rule government law right wrong good bad evil great small large big high low deep broad wide long short old new young early late quick slow fast hard soft light heavy warm cold hot dry wet clean pure holy sacred common private public open shut close together apart alone single double triple fold like love hate fear joy grief sorrow pain hurt wound injury harm evil ill sick well whole safe sound strong weak feeble faint dim bright clear dark obscure hidden secret plain simple complex subtle keen sharp dull blunt rough smooth level even flat straight curved bent round square long broad short gentle mild harsh stern fierce wild tame soft sweet bitter sour acid tart sharp hot cold very really quite rather somewhat slightly wholly entirely utterly quite eg viz namely useful serviceable beneficial profitable advantageous pleasant agreeable delightful pleasing empty waste desert powerful prudent violent foreign blessed unlike resembling green wasteful effective valuable excellent worthy active passable capable ready fit suitable proper fitting meet convenient opportune seasonable timely becoming decorous fair beautiful handsome comely shapely well-made well-formed graceful elegant refined polished finished perfect complete whole entire total full crowded thick numerous many much great immense vast huge large spacious broad wide extensive far-far distant remote separated parted divided separate distinct several various diverse different varied manifold rich wealthy opulent sumptuous costly dear expensive precious rare valuable choice select exquisite superb superb fine nice delicious savory tasteful good savory wholesome healthy salubrious healthful sound firm stable steady constant continual perpetual everlasting eternal immortal lasting enduring abiding durable permanent lasting solid substantial strong mighty potent powerful forcible vigorous active energetic spirited mettlesome manly brave courageous valiant bold daring fearless intrepid dauntless resolute firm steadfast unyielding inflexible stubborn obstinate headstrong willful perverse wayward froward forward bold daring rash reckless heedless careless negligent remiss slack idle lazy indolent slothful sluggish torpid inert sluggish dull heavy stupid senseless foolish silly fatuous imbecile weak-minded witless simple foolish silly childish puerile boyish girlish womanish effeminate soft delicate tender fragile frail brittle weak feeble languid faint exhausted wearied tired weary fatigued jaded worn-out spent exhausted`.split(/\s+/));
const BIO_WORDS = new Set("king queen prince princess daughter son father mother brother sister wife husband god goddess nymph giant hero heroine warrior king king's people nation tribe city town river mountain island kingdom region country land sea kingly royal".split(/\s+/));
const FUNCTION = new Set(("to a an the of in by for from with at on into who which what and or but not as up down over under through between about after before during without within across toward against around above below near off out per than then there their they he she it we you so hence also such same perh esp etc i e v s c m n t o r or in for with out by of on at".split(" ")));
function enCount(g) {
  const toks = g.toLowerCase().replace(/[^a-z\s]/g," ").split(/\s+/).filter(w=>w.length>=3);
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
  if (!/^[A-Z]/.test(g)) return false;
  const first = g.split(/[\s,]/)[0].toLowerCase();
  if (FRAG_START.has(first)) return false;
  if (FUNCTION.has(first)) return false;   // "With inf", "Of persons" are NOT adjectives
  if (!EN_WORDS.has(first) && !/(?:ous|ful|able|ible|ive|ish|less|like|some|ed|ing)$/.test(first)) return false;
  return true;
}
function cleanOne(t) {
  t = t.trim();
  if (XREF.test(t)) return null;
  if (HEADER.test(t)) return null;
  if (SCOPE_LABEL.test(t)) return null;
  if (ETYM.test(t)) return null;
  let m = t.match(/^((?:[a-z]+\.\s*)+(?:\[[^\]]*\]\s*)?),\s+/i);
  if (m) {
    const head = m[1].replace(/\[.*?\]/g,"").trim();
    const all = head.split(/\s+/).filter(Boolean).every(tok => ABBR_TOK.test(tok));
    if (all) t = t.slice(m[0].length).trim();
  }
  t = t.replace(/^In\s+(?:gen\.|partic\.|the\s+widest\s+sense),?\s*/i,"").replace(/^Lit\.\s*/i,"");
  t = t.replace(PAREN_REF,"").trim();
  t = t.replace(PAREN_REF_TAIL,"").trim();
  t = t.replace(CIT_FULL,"").trim();
  t = t.replace(TAIL_CIT,"").trim();
  t = t.replace(TAIL_AUTHOR,"").trim();
  t = t.replace(CIT,"");
  t = t.replace(/\([^)]*\)\s*$/,"").trim();
  t = t.replace(/\([^)]*$/,"").trim();   // unclosed trailing paren (clause-split broke "(syn.: ...)" across clauses)
  t = t.replace(/[.,;]$/,"").trim();
  t = t.replace(/\s+(?:etc\.?|al\.|sq\.)$/i,"").trim();
  t = t.replace(/[.,;]$/,"").trim();
  if (!t || t.length < 4) return null;
  return t;
}
function scoreGloss(g, pos) {
  let s = 0;
  if (STRONG_OPEN.test(g)) s += 3;
  else if (isBareAdj(g, pos)) s += 3;
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
  if (/(?:\s(?:hence|cf|syn|freq\.|class\.|absol|neutr|act\.|pass\.|in\s+gen\.))\s*,?\s*(?:\([^)]*\))?$/i.test(g)) s -= 4;
  if (/\((?:cf\.?|syn\.?|freq\.?|rare|class\.?|poet\.?|ante-?class\.?)\)?$/i.test(g)) s -= 2;
  return s;
}
function bestClause(s, pos) {
  const clauses = s.split(/[;:]/).flatMap(c => c.split(/,\s+(?=to\s|a\s|an\s|the\s|of\s|in\s|by\s|for\s|from\s|with\s|who\s|which\s|one\s|that\s)/));
  let best = null, bestScore = -99, bestEn = -1;
  let cursor = 0;
  for (const c of clauses) {
    const start = s.indexOf(c, cursor);
    const before = start >= 0 ? s.slice(Math.max(0, start - 40), start) : "";
    cursor = start >= 0 ? start + c.length : cursor;
    if ((ETYM.test(before) || GREEK.test(before)) && !/[\]\)][\s.,;:]*$/.test(before)) continue;
    const r = cleanOne(c);
    if (!r) continue;
    const sc = scoreGloss(r, pos), en = enCount(r);
    if (sc > bestScore) { bestScore = sc; best = r; bestEn = en; }
  }
  return {best, bestScore, bestEn};
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
  let best = null, bestScore = -99, bestEn = -1;
  for (let i=0;i<all.length;i++) {
    const b = bestClause(all[i], pos);
    if (!b.best) continue;
    if (b.bestScore > bestScore) { best = b.best; bestScore = b.bestScore; bestEn = b.bestEn; }
  }
  if (!best) return null;
  if (bestScore >= 2 || (bestScore >= 0 && bestEn >= 2)) return best;
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
  formSets.get(lem).add(p[0]+"|"+p[1]);
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
function resolve(lemma, pos, depth = 0) {
  const l = lemma.toLowerCase();
  const base = l.replace(/\d+$/,"");
  let e;
  if (isSpurious(l)) e = lsByKey.get(base) || lsByKey.get(base+"1");
  else e = lsByKey.get(l) || lsByKey.get(base) || lsByKey.get(base+"1");
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
function wGloss(lemma, pos, gender) {
  const base = lemma.replace(/\d+$/,"");
  if (!wc.has(base)) {
    let ps = [];
    try { const a = engine.parseWord(base); ps = (a.results||[]).map(x=>({pofs:(x.ir&&x.ir.qual&&x.ir.qual.pofs)||"",g:(x.ir&&x.ir.qual&&x.ir.qual.noun&&x.ir.qual.noun.gender)||"",m:(x.de&&x.de.mean)||""})); } catch(e){}
    wc.set(base, ps);
  }
  const same = wc.get(base).filter(x=>x.pofs===pos && (!gender||x.g===gender));
  const distinct = new Set(same.map(x=>x.m.split(";")[0].trim().replace(/^\||\||$/g,"")));
  return distinct.size===1 ? [...distinct][0] : null;
}

// ---- build ----
const SKIP_WORDS = process.env.SKIP_WORDS === "1";
const lemmaGloss = new Map();
let lClean=0,wClean=0,none=0, done=0;
const total = rows.size;
const t0 = Date.now();
for (const r of rows.values()) {
  const lem = r.lemma;
  const pos = dominantPos(lem.toLowerCase());
  const g6 = (pos==="N"||pos==="ADJ"||pos==="PRON") ? (GEN_MAP[r.tag[6]]||"") : "";
  const l = resolve(lem, pos);
  const w = SKIP_WORDS ? null : wGloss(lem, pos, g6);
  let gloss = null;
  if (l) { gloss = l; lClean++; }
  else if (w) { gloss = w; wClean++; }
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
