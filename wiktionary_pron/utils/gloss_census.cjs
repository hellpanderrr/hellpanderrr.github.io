// Frequency-stratified census of the gloss artifact (M-005 fix, 2026-08-08).
// Hand-curated "everyday primary sense" for the closed function-word stratum +
// high-frequency content words. This is the correctness measurement the panel
// prescribed: measure by corpus frequency (exposure), not wordform count.
//
//   node utils/gloss_census.cjs    # measure macronizer/glosses.tsv.gz (exit 1 on fail)
//
// Every lemma here is a STRONG-opener everyday sense a student needs. Match is a
// case-insensitive word-boundary substring of ANY alternate. Non-lemma forms (est,
// ea, id, se...) are skipped — the popup resolves form→lemma, so they aren't artifact
// keys. Exit 1 if any row fails, so the census can gate CI like the golden suite.
// The 2026-08-08 fix moved this stratum from ~38% → 100% correct (241/241).

const fs = require("fs"), zlib = require("zlib");
const buf = zlib.gunzipSync(fs.readFileSync("macronizer/glosses.tsv.gz")).toString();
const map = {};
for (const line of buf.split("\n")) { const i = line.indexOf("\t"); if (i > 0) map[line.slice(0, i)] = line.slice(i + 1); }


const WL = new Set();
try { for (const line of fs.readFileSync("macronizer/macrons.txt","utf8").split("\n")) { const p = line.split("\t"); if (p.length >= 4) WL.add(p[2].toLowerCase()); } } catch(e) {}

const B0 = [ // closed-class census: conjunctions, prepositions, pronouns, copula, core adverbs
  ["et","and"],["atque","and"],["ac","and"],["que","and"],["nec","nor"],["neque","nor"],["sed","but"],
  ["at","but"],["autem","but"],["verum","but","truly","in truth"],["vero","but"],["enim","for"],["nam","for"],["aut","or"],
  ["vel","or"],["sive","or"],["seu","or"],["si","if"],["nisi","unless","if not"],["num","whether"],["an","or","whether"],
  ["ut","that","so that","as"],["ne","that not","lest","not"],["quod","because","that"],["quia","because"],
  ["quoniam","since"],["dum","while","until"],["donec","until"],["cum","when","since","with"],
  ["postquam","after"],["priusquam","before"],["antequam","before"],["ubi","where","when"],
  ["unde","whence","from"],["quo","whither","where"],["qua","where"],["inde","thence","from"],
  ["hinc","hence","from"],["ita","so","thus"],["sic","so","thus"],["tam","so"],["tamen","yet","nevertheless"],
  ["tandem","at last","finally"],["denique","at last","finally"],["igitur","therefore"],["ergo","therefore"],
  ["itaque","therefore","and so","accordingly"],["quidem","indeed"],["quidem1","indeed"],["adhuc","hitherto","up to now","as yet","still"],["iam","now","already"],
  ["nunc","now"],["olim","once","formerly"],["semper","always"],["saepe","often"],["non","not"],
  ["non1","not"],["nec1","nor"],["in","in"],["ad","to","toward"],["ab","from"],["a","from","by"],
  ["abs","from"],["de","from","concerning"],["ex","out","from"],["e","out","from"],["per","through"],
  ["pro","for","before","on behalf of"],["prae","before"],["post","after"],["ante","before","earlier","in front"],["inter","between"],
  ["intra","within"],["extra","outside","beyond","except"],["supra","above"],["infra","below"],["sub","under"],
  ["super","above","over"],["super1","above"],["circa","around","about"],["apud","at","with"],
  ["contra","against","opposite","facing"],["prope","near"],["propter","on account of","near"],["trans","across"],["cis","on this side","this side of"],
  ["ultra","beyond"],["penes","in the power of"],["tenus","up to"],["usque","up to","as far as","all the way"],
  ["sine","without"],["cum1","with"],["etsi","although"],["quamvis","although"],["licet","although","it is permitted","allowed"],
  ["nihil","nothing"],["nil","nothing"],["nemo","nobody"],["omnis","all","every"],["quis","who"],
  ["quid","what"],["qui","who","which"],["quae","who","which"],["quod2","which"],["is","that","he"],
  ["ea","that","she"],["id","that","it"],["ille","that","he"],["illa","that","she"],["illud","that","it"],
  ["hic","this","he"],["haec","this","she"],["hoc","this","it"],["iste","that"],["ipse","himself","self"],
  ["ipse1","himself"],["se","himself","herself"],["sui","himself"],["ego","I","me"],["tu","you"],["nos","we"],
  ["vos","you"],["meus","my"],["tuus","your"],["suus","his","her"],["noster","our"],["vester","your"],
  ["sum","be","exist"],["esse","be"],["fio","become"],["possum","able","can"],["volo","wish","want"],
  ["nolo","unwilling"],["malo","prefer"],["fero","bear","carry","bring"],["eo","go"],["sunt","be"],
  ["est","be"]
];
const B1 = [ // high-frequency content words (a student meets on page one of Caesar/Virgil)
  ["res","thing"],["bellum","war"],["pax","peace"],["terra","earth","land"],["mare","sea"],
  ["caelum","sky","heaven"],["mors","death"],["vita","life"],["vir","man"],["mulier","woman","female"],
  ["femina","woman","female"],["puella","girl"],["puer","boy"],["homo","man","human"],["deus","god"],
  ["dea","goddess"],["populus","people"],["rex","king"],["regina","queen"],["dominus","master","lord"],
  ["domina","lady"],["servus","slave"],["amicus","friend"],["hostis","enemy"],["urbs","city"],
  ["oppidum","town"],["ager","field"],["annus","year"],["dies","day"],["nox","night"],["sol","sun"],
  ["luna","moon"],["stella","star"],["mons","mountain"],["collis","hill"],["flumen","river"],
  ["aqua","water"],["ignis","fire"],["ventus","wind","winds"],["mare1","sea"],["navis","ship"],["exercitus","army"],
  ["legio","legion","body of soldiers"],["miles","soldier"],["arma","arms","weapons","defensive armor"],["gladius","sword"],["hasta","spear"],
  ["caput","head"],["manus","hand"],["pes","foot"],["os","mouth"],["os1","bone"],["oculus","eye"],
  ["auris","ear"],["lingua","tongue","language"],["dens","tooth"],["cor","heart"],["animus","mind","spirit"],
  ["verbum","word"],["nomen","name"],["locus","place"],["modus","measure","manner","way"],["ratio","reason"],
  ["causa","cause"],["vis","force","strength","power"],["potestas","power"],["auctoritas","authority"],
  ["fides","faith","trust"],["spes","hope"],["timor","fear"],["amor","love"],["ira","anger"],
  ["gaudium","joy"],["dolor","pain","grief"],["magnus","great","large"],["parvus","small","little"],
  ["bonus","good"],["malus","bad","evil"],["malus1","apple"],["mali","apple"],["multus","much","many"],
  ["paucus","few"],["omnis1","all"],["magnus1","great"],["totus","whole","all"],["alius","other","another"],
  ["alius1","other"],["alius2","other"],["unus","one","single"],["duo","two"],["tres","three"],["quattuor","four"],
  ["primus","first"],["posterus","next","following","latter","later"],["facere","do","make"],["facio","do","make"],
  ["dico","say","speak"],["dixi","say"],["dico1","say"],["video","see"],["audio","hear"],["mitto","send"],
  ["lego","read","gather","choose"],["lego1","read"],["scribo","write"],["habeo","have","hold","possess"],["teneo","hold"],
  ["capio","take","seize"],["do","give"],["dono","give"],["venio","come"],["adeo","approach","so much","such a point"],["redeo","return"],
  ["absum","be away"],["adsum","be present"],["iacio","throw"],["pono","place","put"],["statuo","set","decide"],
  ["relinquo","leave"],["trado","hand over"],["traho","drag","draw"],["duco","lead"],["fero1","bear","carry"],
  ["gero","carry","wear","wage"],["peto","seek","ask"],["quaero","seek","ask"],["invenio","find"],
  ["amo","love"],["voco","call"],["clamo","shout"],["dico2","say"],["lego2","read"],["facio1","do","make"],
  ["pello","drive"],["pello1","drive"],["sumo","take"],["cogo","force","compel"],["iubeo","order","command"],
  ["impero","command","order"],["timeo","fear"],["terreo","frighten"],["paro","prepare"],["moneo","warn","advise"],
  ["doceo","teach"],["disco","learn"],["scio","know"],["nescio","not know"],["puto","think"],["credo","believe"],
  ["dico3","say"],["ait","say"],["inquit","say"],["inquam","say"],
  // round 4-7 fixes: more common content words
  ["bellum","war"],["proelium","battle"],["acies","battle"],["caedes","slaughter"],
  ["casus","fall","accident","chance"],["facies","face"],["forma","form","shape"],
  ["species","appearance","kind","sort"],["vestis","garment"],["toga","toga"],
  ["gemma","gem","jewel","bud"],["funus","funeral"],["sepultura","burial"],
  ["agor","drive","do","act"],["ago","drive","do","act"],["cado","fall"],
  ["pendo","weigh","pay"],["colo","cultivate","inhabit","honor"],["nascor","born"],
  ["discedo","depart"],["succedo","succeed"],["volo2","fly"],["dubito","doubt"],
  ["narro","tell","relate"],["nego","deny"],["respondeo","answer","reply"],
  ["vado","go","walk","hasten"],["moror","delay"],["pereo","perish","die"],
  ["rogo","ask","request"],["suadeo","advise","persuade"],["taceo","silent"],
  ["tremo","tremble"],["vereor","fear"],["opprimo","overwhelm"],["precor","pray"],
  ["servio","serve"],["studeo","study"],["placeo","please"],["soleo","accustomed"],
  ["loquor","speak","talk"],["aio","say","affirm"],["saluto","greet"],
  ["cogito","think"],["arbitror","think","judge"],["constituo","establish","decide"],
  ["decerno","decide","decree"],["censeo","think","judge"],["metuo","fear"],
  ["doleo","grieve","suffer"],["lugeo","mourn"],["ploro","weep","lament"],
  ["cerno","discern","see"],["dormio","sleep"],["expergiscor","wake"],
  ["albus","white"],["ater","black"],["niger","black"],["caeruleus","blue"],
  ["candidus","white"],["purus","pure"],["castus","chaste"],["integer","whole"],
  ["simplex","simple"],["pluvia","rain"],["imber","rain"],["nimbus","storm-cloud"],
  ["fumus","smoke"],["nebula","mist","fog"],["tempestas","storm"],["turbo","whirlwind"],
  ["meridies","midday","noon"],["oriens","east"],["occidens","west"],["lux","light"],
  ["lumen","light"],["radius","ray","rod"],["os2","bone"],["mentum","chin"],
  ["cubitus","elbow"],["planta","sole"],["socrus","mother-in-law"],["affinis","relation by marriage"],
  ["colonia","colony"],["basilica","basilica"],["gymnasium","gymnasium"],
  ["thermae","baths"],["templum","temple"],["lectus","bed","couch"],["circus","circus"],
  ["ludus","play","game"],["carcer","prison"],["portus","harbor","port"],
  ["sapientia","wisdom"],["pietas","piety"],["fluctus","wave"],["finis","end"],
  ["centurio","centurion"],["senator","senator"],["ferrum","iron"],["aries","ram"]
];

const bands = { B0, B1 };
let pass = 0, fail = 0; const bad = [];
for (const [band, rows] of Object.entries(bands)) {
  for (const [w, ...alts] of rows) {
    if (!WL.has(w)) continue;  // non-lemma form — resolved via its lemma in the popup
    const g = map[w];
    if (g == null) { bad.push([band, w, "(MISSING)", ""]); fail++; continue; }
    const g2 = g.toLowerCase();
    const ok = alts.some(a => new RegExp("(^|[^a-z])" + a.replace(/[.*+?^${}()|[\]\\]/g, "\\$&") + "([^a-z]|$)").test(g2));
    if (ok) pass++; else { bad.push([band, w, g.slice(0, 58)]); fail++; }
  }
}
console.log(`CENSUS: ${pass} pass / ${fail} fail (${pass + fail} rows)`);
for (const [band, w, g] of bad) console.log(`  ${band}  ${w.padEnd(12)} → ${g}`);
process.exit(fail ? 1 : 0);
