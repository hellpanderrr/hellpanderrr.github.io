/**
 * Insert/refresh search metadata in help pages: title, h1, meta description, canonical,
 * Open Graph, and JSON-LD (Article + BreadcrumbList). Idempotent: the block between the
 * SEO markers is replaced on each run.
 *   node utils/help_seo_head.mjs russian ukrainian ...   (run from wiktionary_pron/)
 */
import { readFileSync, writeFileSync } from "node:fs";

const BASE = "https://hellpanderrr.github.io/wiktionary_pron/";
const SITE = "IPA Transcription Tool";
const MODIFIED = "2026-10-05";

const PAGES = {
  russian: {
    lang: "Russian",
    title: "Russian Pronunciation and IPA Transcription Guide",
    desc: "Russian pronunciation in IPA: stress and vowel reduction, hard and soft consonants, devoicing and assimilation, with a free Russian-to-IPA converter.",
  },
  ukrainian: {
    lang: "Ukrainian",
    title: "Ukrainian Pronunciation and IPA Transcription Guide",
    desc: "Ukrainian pronunciation in IPA: stress, unstressed vowels, г and ґ, the sounds of в, soft consonants and the apostrophe, with a free converter.",
  },
  belorussian: {
    lang: "Belarusian",
    title: "Belarusian Pronunciation and IPA Transcription Guide",
    desc: "Belarusian pronunciation in IPA: akanye and yakanye, ў, дз and дж, hard and soft consonants, and stress marking, with a free converter.",
  },
  bulgarian: {
    lang: "Bulgarian",
    title: "Bulgarian Pronunciation and IPA Transcription Guide",
    desc: "Bulgarian pronunciation in IPA: stress and vowel reduction, ъ, щ and дж, soft consonants and final devoicing, with a free Bulgarian-to-IPA converter.",
  },
  icelandic: {
    lang: "Icelandic",
    title: "Icelandic Pronunciation and IPA Transcription Guide",
    desc: "Icelandic pronunciation in IPA: vowel length, preaspiration, voiceless sonorants, pre-stopped ll and nn, ð and þ, with a free Icelandic-to-IPA converter.",
  },
  lithuanian: {
    lang: "Lithuanian",
    title: "Lithuanian Pronunciation and IPA Transcription Guide",
    desc: "Lithuanian pronunciation in IPA: long and short vowels, diphthongs, palatalization and syllables, with a free converter backed by a Wiktionary lexicon.",
  },
  mongolian: {
    lang: "Mongolian",
    title: "Mongolian Pronunciation and IPA Transcription Guide",
    desc: "Khalkha Mongolian pronunciation in IPA: vowel harmony, long vowels, aspirated stops, palatalized consonants and the velar nasal, with a free converter.",
  },
  portuguese: {
    lang: "Portuguese",
    title: "Brazilian and European Portuguese Pronunciation: IPA Guide",
    desc: "Portuguese pronunciation in IPA for Brazil (Rio) and Portugal: stress, open and closed e and o, nasal vowels, t and d before i, coda s and l.",
  },
  german: {
    lang: "German",
    title: "German Pronunciation and IPA Transcription Guide",
    desc: "German pronunciation in IPA: long and short vowels, umlauts, the ich- and ach-sounds, final devoicing and uvular r, with a free German-to-IPA converter.",
  },
  french: {
    lang: "French",
    title: "French Pronunciation and IPA Transcription Guide",
    desc: "French pronunciation in IPA: nasal vowels, silent final letters, schwa, semivowels and spelling rules, with a free French-to-IPA converter and lexicon.",
  },
  czech: {
    lang: "Czech",
    title: "Czech Pronunciation and IPA Transcription Guide",
    desc: "Czech pronunciation in IPA: vowel length, soft consonants and ě, the sound ř, voicing assimilation and first-syllable stress, with a free converter.",
  },
  polish: {
    lang: "Polish",
    title: "Polish Pronunciation and IPA Transcription Guide",
    desc: "Polish pronunciation in IPA: nasal vowels ą and ę, soft consonants, sz and cz against ś and ć, devoicing and penultimate stress, with a free converter.",
  },
  spanish: {
    lang: "Spanish",
    title: "Spanish Pronunciation and IPA Transcription Guide",
    desc: "Castilian and Latin American Spanish in IPA: stress and written accents, distinción and seseo, yeísmo and soft b, d, g, with a free converter.",
  },
  latin: {
    lang: "Latin",
    title: "Latin Pronunciation and IPA Transcription Guide",
    desc: "Classical, Ecclesiastical and Vulgar Latin pronunciation in IPA: vowel length and macrons, stress, diphthongs and consonants, with a free converter.",
  },
  greek: {
    lang: "Ancient Greek",
    title: "Ancient Greek Pronunciation and IPA Transcription Guide",
    desc: "Ancient Greek in IPA from Attic to Byzantine: pitch accent, vowel length, aspirated stops and the changes of the Koine period, with a free converter.",
  },
  armenian: {
    lang: "Armenian",
    title: "Armenian Pronunciation and IPA Transcription Guide",
    desc: "Eastern and Western Armenian pronunciation in IPA: the voicing swap between the dialects, aspiration, schwa and stress, with a free converter.",
  },
  irish: {
    lang: "Irish",
    title: "Irish (Gaeilge) Pronunciation and IPA Transcription Guide",
    desc: "Irish pronunciation in IPA for Connacht, Munster and Ulster: broad and slender consonants, vowel digraphs and mutations, with a free converter.",
  },
  macronizer: {
    lang: "Latin",
    title: "Latin Macronizer: Adding Vowel Length Marks to Latin Text",
    desc: "How the Latin macronizer marks long vowels using a wordlist, a part-of-speech tagger and Morpheus, how to read its output, and how it scans verse.",
  },
  index: {
    lang: null,
    title: "Pronunciation Guides and IPA Transcription Help",
    desc: "Pronunciation guides with IPA for seventeen languages, from Russian and German to Latin, Ancient Greek and Irish, and help for the free IPA converter.",
  },
};

const esc = (s) => s.replace(/&/g, "&amp;").replace(/"/g, "&quot;").replace(/</g, "&lt;");
const START = "<!-- seo:start -->";
const END = "<!-- seo:end -->";

for (const key of process.argv.slice(2)) {
  const p = PAGES[key];
  if (!p) throw new Error(`no SEO config for ${key}`);
  if (p.desc.length > 160) throw new Error(`${key}: description ${p.desc.length} chars > 160`);
  if (p.title.length > 65) throw new Error(`${key}: title ${p.title.length} chars > 65`);
  const file = `help/${key}.html`;
  let html = readFileSync(file, "utf8");
  const url = `${BASE}help/${key}.html`;
  const ld = {
    "@context": "https://schema.org",
    "@graph": [
      {
        "@type": "Article",
        headline: p.title,
        description: p.desc,
        inLanguage: "en",
        url,
        dateModified: MODIFIED,
        ...(p.lang ? { about: { "@type": "Language", name: p.lang } } : {}),
        isPartOf: { "@type": "WebSite", name: SITE, url: BASE },
      },
      {
        "@type": "BreadcrumbList",
        itemListElement: [
          { "@type": "ListItem", position: 1, name: SITE, item: BASE },
          { "@type": "ListItem", position: 2, name: "Help", item: `${BASE}help/index.html` },
          ...(key === "index" ? [] : [{ "@type": "ListItem", position: 3, name: key === "macronizer" ? "Latin Macronizer" : p.lang, item: url }]),
        ],
      },
    ],
  };
  const block = [
    START,
    `    <meta name="description" content="${esc(p.desc)}">`,
    `    <link rel="canonical" href="${url}">`,
    `    <meta property="og:type" content="article">`,
    `    <meta property="og:site_name" content="${SITE}">`,
    `    <meta property="og:title" content="${esc(p.title)}">`,
    `    <meta property="og:description" content="${esc(p.desc)}">`,
    `    <meta property="og:url" content="${url}">`,
    `    <meta name="twitter:card" content="summary">`,
    `    <script type="application/ld+json">${JSON.stringify(ld)}</script>`,
    `    ${END}`,
  ].join("\n");

  html = html.replace(/<title>[^<]*<\/title>/, `<title>${esc(p.title)}</title>`);
  html = html.replace(/<h1>[^<]*<\/h1>/, `<h1>${esc(p.title)}</h1>`);
  if (html.includes(START)) {
    html = html.replace(new RegExp(`${START}[\\s\\S]*?${END}`), block.trimStart());
  } else {
    html = html.replace(/(<title>[^<]*<\/title>)/, `$1\n    ${block}`);
  }
  writeFileSync(file, html, "utf8");
  console.log(`${key}: title ${p.title.length}, desc ${p.desc.length}`);
}
