import { test } from "@playwright/test";
import fs from "fs";
import path from "path";
import { fileURLToPath } from "url";

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const OUT = path.join(__dirname, "..", "coverage", "v8-e2e.json");

// Coverage collector — OPT-IN (skipped unless COVERAGE=1, so default e2e runs skip it).
// Runs a representative macronizer session with V8 JS coverage on, then dumps the raw
// V8 coverage to coverage/v8-e2e.json for scripts/tests/coverage-merge.mjs.
//
// Single (desktop) context on purpose: V8 coverage roughly doubles memory, and two
// contexts each downloading + parsing the wordlist crashed the browser worker. The
// touch-only handlers (touchend opener, popstate, blur-before-dock) are exercised by
// the hasTouch test in editing.spec.js, so the collector focuses on the desktop paths.
test.skip(process.env.COVERAGE !== "1", "set COVERAGE=1 to collect coverage");

test("collect V8 coverage across the macronizer flow", async ({ page }) => {
  test.setTimeout(600_000);

  await page.coverage.startJSCoverage({ resetOnNavigation: false });

  // Primary flow: load, macronize, inspect, edit.
  await page.goto("/wiktionary_pron/macronizer.html");
  await page.locator("#macronize_btn").waitFor({ state: "visible", timeout: 300_000 });
  await page.fill("#text_to_macronize", "Gallia est omnis divisa in partes tres");
  await page.click("#macronize_btn");
  await page.locator("#resultText .ipa").first().waitFor({ state: "visible", timeout: 120_000 });

  // Desktop: hover opens the popup; cycle via "Next spelling"; click a vowel.
  await page.locator("#resultText .ipa").first().hover();
  await page.locator(".word-popup").waitFor({ state: "visible", timeout: 5000 });
  const cycleBtn = page.locator(".word-popup .popup-cycle");
  if (await cycleBtn.count()) await cycleBtn.click();
  await page.mouse.click(400, 300).catch(() => {});
  await page.keyboard.press("Control+z").catch(() => {});
  await page.keyboard.press("Control+y").catch(() => {});

  // Exports + dark mode.
  await page.click("#copy_btn").catch(() => {});
  await page.click("#export_csv").catch(() => {});
  await page.click("#dark_mode").catch(() => {});
  await page.click("#dark_mode").catch(() => {});

  const cov = await page.coverage.stopJSCoverage();

  // Keep only scripts we own (macronizer page + engine dist + app scripts),
  // not CDN deps (wasmoon, localforage, jszip, pdf-lib, fontkit, fr-compromise).
  const own = cov.filter((e) => e.url.includes("/wiktionary_pron/"));
  fs.mkdirSync(path.dirname(OUT), { recursive: true });
  fs.writeFileSync(OUT, JSON.stringify(own));
  console.log(`[coverage] wrote ${OUT}: ${own.length} scripts`);
});
