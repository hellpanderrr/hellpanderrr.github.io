/**
 * One-way sync: copies shared scripts from the main app into the extension's
 * scripts/ directory. Run this after any change to the shared files so the
 * extension doesn't drift.
 *
 * Usage:  node utils/sync_extension.cjs
 * Add to package.json as `npm run build:ext`.
 */

const fs = require("node:fs");
const path = require("node:path");

const ROOT = path.resolve(__dirname, "..");
const EXT = path.join(ROOT, "utils", "ext_tmp");

// Only files that are identical between the main app and the extension.
// tts_engine.js is extension-specific (not scripts/tts.js) — skip it.
const FILES = [
  "scripts/languages.js",
  "scripts/lexicon.js",
  "scripts/utils.js",
  "scripts/lua_init.js",
  // Classic script — must stay extension-side, but rebuilt alongside the sync
  "utils/ext_tmp/options_lexicon_shim.js",
];

let copied = 0;
for (const rel of FILES) {
  const src = path.join(ROOT, rel);
  const dest = path.join(EXT, rel);
  if (!fs.existsSync(src)) {
    console.warn(`  SKIP ${rel} — source not found`);
    continue;
  }
  const content = fs.readFileSync(src, "utf8");
  fs.mkdirSync(path.dirname(dest), { recursive: true });
  fs.writeFileSync(dest, content, "utf8");
  console.log(`  ${rel} -> utils/ext_tmp/${rel}`);
  copied++;
}
console.log(`Synced ${copied} file(s).`);
