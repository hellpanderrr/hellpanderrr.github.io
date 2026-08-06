// Merge c8 (unit + IPA) and V8 (e2e) coverage into one istanbul map and report.
// Usage: npm run test:coverage  (writes coverage/coverage-summary.json + prints %)
import istanbulCov from "istanbul-lib-coverage";
import istanbulReport from "istanbul-lib-report";
import istanbulReports from "istanbul-reports";
import v8toIstanbul from "v8-to-istanbul";
import fs from "fs";
import path from "path";
import { fileURLToPath } from "url";

const { createCoverageMap } = istanbulCov;
const { createContext } = istanbulReport;

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const covDir = path.resolve(__dirname, "..", "..", "coverage");

const map = createCoverageMap();

// ---- 1. c8 (unit + IPA) coverage-final.json ----
for (const rel of ["unit/coverage-final.json", "ipa/coverage-final.json"]) {
  const p = path.join(covDir, rel);
  if (!fs.existsSync(p)) continue;
  const raw = JSON.parse(fs.readFileSync(p, "utf8"));
  map.merge(createCoverageMap(raw));
}

// ---- 2. V8 (e2e) coverage -> istanbul via v8-to-istanbul ----
const v8Path = path.join(covDir, "v8-e2e.json");
if (fs.existsSync(v8Path)) {
  const entries = JSON.parse(fs.readFileSync(v8Path, "utf8"));
  for (const entry of entries) {
    if (!entry.url.includes("/wiktionary_pron/")) continue;
    // v8-to-istanbul's `sources` arg is { source, ... } (not keyed by path), and
    // it normalizes http URLs into mangled local paths — so re-key each file's
    // coverage to a clean page-relative path. Strip any //# sourceMappingURL comment
    // first: v8-to-istanbul would otherwise try to read the .map from the mangled
    // path and throw. Coverage maps to the shipped JS, not the TS source — fine for
    // a percentage.
    const src = (entry.source || "").replace(/\/\/#\s*sourceMappingURL=[^\n]*\n?/g, "");
    const script = v8toIstanbul(entry.url, 0, { source: src });
    await script.load();
    script.applyCoverage(entry.functions);
    const clean = entry.url.replace(/^https?:\/\/[^/]+/, "");   // /wiktionary_pron/...
    for (const fc of Object.values(script.toIstanbul())) {
      map.merge(createCoverageMap({ [clean]: fc }));
    }
  }
}

// ---- 3. Exclude the app's test/lua/third-party code from the summary ----
map.filter((k) => {
  if (k.includes("/scripts/tests/")) return false;
  if (k.includes("/lua_modules/")) return false;
  if (k.includes("/node_modules/")) return false;
  if (k.includes("/utils/ext_tmp/")) return false;
  return true;
});

// ---- 4. Report ----
fs.mkdirSync(covDir, { recursive: true });
const context = createContext({ dir: covDir, coverageMap: map, defaultSummarizer: "nested" });
const tree = context.getTree();
tree.visit(istanbulReports.create("text"), context);
tree.visit(istanbulReports.create("json-summary", { file: "coverage-summary.json" }), context);

const s = map.getCoverageSummary();
console.log("\n=== OVERALL COVERAGE ===");
for (const k of ["statements", "branches", "functions", "lines"]) {
  const m = s[k];
  console.log(
    `${k.padEnd(10)} ${String(m.pct).padStart(6)}%   (${m.covered}/${m.total})`,
  );
}
