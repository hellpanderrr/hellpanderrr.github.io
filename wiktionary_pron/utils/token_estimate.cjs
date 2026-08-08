// Token-weighted estimate: for a real Latin passage, what fraction of words
// have a gloss? Uses the wordlist lemma→form mapping to resolve each token.
const fs = require("fs"), zlib = require("zlib");

// Build form→lemma map from wordlist (lowercased)
const formToLemma = new Map();
for (const l of fs.readFileSync("macronizer/macrons.txt", "utf8").split("\n")) {
  const p = l.split("\t");
  if (p.length < 4) continue;
  const form = p[0].toLowerCase(), lemma = p[2].toLowerCase();
  if (!formToLemma.has(form)) formToLemma.set(form, lemma);
}
const buf = zlib.gunzipSync(fs.readFileSync("macronizer/glosses.tsv.gz")).toString();
const gloss = {};
for (const l of buf.split("\n")) { const i = l.indexOf("\t"); if (i > 0) gloss[l.slice(0, i)] = l.slice(i + 1); }

const passages = {
  caesar: "Gallia est omnis divisa in partes tres quarum unam incolunt Belgae aliam Aquitani tertiam qui ipsorum lingua Celtae nostra Galli appellantur",
  aeneid: "Arma virumque cano Troiae qui primus ab oris Italiam fato profugus Laviniaque venit litora multum ille et terris iactatus et alto vi superum saevae memorem Iunonis ob iram",
  cicero: "Quousque tandem abutere Catilina patientia nostra quam diu etiam furor iste tuus nos eludet quem ad finem sese iactabit audacia",
};
for (const [name, text] of Object.entries(passages)) {
  const toks = text.toLowerCase().replace(/[^a-z\s]/g, "").split(/\s+/).filter(Boolean);
  let glossed = 0, missing = 0, mapped = 0;
  const unmapped = [];
  for (const t of toks) {
    const lem = formToLemma.get(t);
    if (lem && gloss[lem]) glossed++;
    else if (lem) { missing++; unmapped.push(t + "(" + lem + ")"); }
    else { missing++; unmapped.push(t + "(?)"); }
  }
  console.log(`\n${name}: ${toks.length} tokens, ${glossed} glossed (${(100 * glossed / toks.length).toFixed(0)}%), ${missing} missing`);
  if (unmapped.length) console.log("  missing:", unmapped.join(", "));
}
