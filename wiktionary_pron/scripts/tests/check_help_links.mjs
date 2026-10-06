// Check every href/src in help/*.html: external URLs by HTTP status, local paths by file (+ #anchor) existence.
// Run: node scripts/tests/check_help_links.mjs   (internationalphoneticassociation.org answers 429/captcha to bots — not dead)
import { readFileSync, readdirSync, existsSync } from "node:fs";
import { fileURLToPath } from "node:url";
import path from "node:path";

const HELP = fileURLToPath(new URL("../../help/", import.meta.url));
const SITE_ROOT = fileURLToPath(new URL("../../../", import.meta.url));
const pages = readdirSync(HELP).filter((f) => f.endsWith(".html"));

const ext = new Map(); // url -> [page,...]
const local = [];
for (const p of pages) {
  const html = readFileSync(path.join(HELP, p), "utf8");
  for (const m of html.matchAll(/(?:href|src)="([^"]+)"/g)) {
    const u = m[1].replace(/&amp;/g, "&");
    if (/^https?:\/\//.test(u)) {
      if (!ext.has(u)) ext.set(u, new Set());
      ext.get(u).add(p);
    } else if (!u.startsWith("#") && !u.startsWith("mailto:") && !u.startsWith("javascript:")) {
      local.push({ page: p, u });
    }
  }
}

// local links
const localBad = [];
for (const { page, u } of local) {
  const [pathPart, anchor] = u.split("#");
  const noQuery = pathPart.split("?")[0];
  let target = path.resolve(HELP, noQuery || page);
  if (noQuery.endsWith("/") || noQuery === "..") target = path.join(target, "index.html");
  if (target.startsWith(path.resolve(SITE_ROOT)) && !existsSync(target)) { localBad.push(`${page}: ${u} (missing file)`); continue; }
  if (anchor && existsSync(target) && target.endsWith(".html")) {
    const t = readFileSync(target, "utf8");
    if (!t.includes(`id="${anchor}"`)) localBad.push(`${page}: ${u} (missing anchor)`);
  }
}

// external links
const urls = [...ext.keys()];
const results = [];
async function check(u) {
  const opts = { redirect: "follow", headers: { "User-Agent": "Mozilla/5.0 (link checker; wiktionary_pron help pages)" } };
  for (let attempt = 0; attempt < 2; attempt++) {
    try {
      const r = await fetch(u, { ...opts, method: "GET", signal: AbortSignal.timeout(20000) });
      let note = "";
      if (r.ok && /wiktionary\.org\/wiki\//.test(u)) {
        const body = await r.text();
        if (/noarticletext|There is currently no text in this page|does not have a module/i.test(body)) note = "EMPTY-WIKI-PAGE";
      }
      return { u, status: r.status, final: r.url !== u ? r.url : "", note };
    } catch (e) {
      if (attempt === 1) return { u, status: "ERR", final: "", note: String(e.cause?.code || e.name) };
    }
  }
}
const queue = [...urls];
await Promise.all(Array.from({ length: 6 }, async () => {
  while (queue.length) results.push(await check(queue.shift()));
}));

console.log(`pages=${pages.length} external=${urls.length} local=${local.length}`);
console.log("\n== LOCAL PROBLEMS ==");
for (const l of [...new Set(localBad)]) console.log("  " + l);
console.log("\n== EXTERNAL PROBLEMS (non-200 or empty wiki page) ==");
for (const r of results.sort((a, b) => String(a.status).localeCompare(String(b.status)))) {
  if (r.status === 200 && !r.note) continue;
  console.log(`  ${r.status} ${r.note} ${r.u}${r.final ? "  -> " + r.final : ""}\n      on: ${[...ext.get(r.u)].join(", ")}`);
}
console.log("\n== REDIRECTED (200) ==");
for (const r of results) if (r.status === 200 && r.final && !r.note) console.log(`  ${r.u} -> ${r.final}`);
