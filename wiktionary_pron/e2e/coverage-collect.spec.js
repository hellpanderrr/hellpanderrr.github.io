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
// contexts each downloading + parsing the wordlist crashed the browser worker. So the
// touch-only handlers (touchend opener, scrim, popstate, blur-before-dock) can NOT be
// measured here — a hasTouch context would need its own wordlist parse. Instead the
// collector drives the DESKTOP paths exhaustively (hover, cycle, Escape, outside-click,
// multi-line undo, unknown word, scansion, dark-mode chip) and relies on editing.spec.js
// to functionally cover the touch paths.
test.skip(process.env.COVERAGE !== "1", "set COVERAGE=1 to collect coverage");

test("collect V8 coverage across the macronizer flow", async ({ page, context }) => {
  test.setTimeout(600_000);

  await page.coverage.startJSCoverage({ resetOnNavigation: false });

  // ---- 1. Primary flow: load, macronize, inspect, edit ----
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

  // Escape closes a pinned popup and returns focus (hidePopup(returnFocus=true)).
  await page.locator("#resultText .ipa").first().hover();
  await page.locator(".word-popup").waitFor({ state: "visible", timeout: 5000 });
  await page.keyboard.press("Escape");
  await page.locator(".word-popup").waitFor({ state: "hidden", timeout: 5000 });
  await page.mouse.move(5, 5);   // leave the span so a fresh hover re-opens the popup

  // Outside-click (document click, not inside the popup) closes an unpinned popup.
  await page.locator("#resultText .ipa").first().hover();
  await page.locator(".word-popup").waitFor({ state: "visible", timeout: 5000 });
  await page.mouse.click(5, 5).catch(() => {});   // away from both the word and popup
  await page.locator(".word-popup").waitFor({ state: "hidden", timeout: 5000 });
  await page.mouse.move(5, 5);   // ditto — next flow re-macronizes, but keep the cursor clear

  // ---- 2. Multi-line editing + undo across two lines ----
  await page.fill("#text_to_macronize", "divisa\nprovinciarum");
  await page.click("#macronize_btn");
  await page.locator("#resultText .ipa").first().waitFor({ state: "visible", timeout: 120_000 });
  const toggled = await page.locator("#resultText .ipa").first().evaluate(() => {
    const span = document.querySelector("#resultText .ipa");
    const tn = span.firstChild;
    const r = document.createRange();
    r.setStart(tn, 1); r.setEnd(tn, 2);
    const rc = r.getBoundingClientRect();
    return { x: (rc.left + rc.right) / 2, y: (rc.top + rc.bottom) / 2 };
  });
  await page.mouse.click(toggled.x, toggled.y);   // toggles the macron
  await page.keyboard.press("Control+z");         // undo line 1

  // ---- 3. Unknown word: red flag + popup honesty ----
  await page.fill("#text_to_macronize", "zyxwvut");
  await page.click("#macronize_btn");
  await page.locator("#resultText .ipa").first().waitFor({ state: "visible", timeout: 120_000 });
  await page.locator("#resultText .ipa").first().hover();
  await page.locator(".word-popup").waitFor({ state: "visible", timeout: 5000 });

  // ---- 4. Scansion + dark-mode chip (M-014) ----
  await page.selectOption("#scan", "hendecasyllable");
  await page.fill("#text_to_macronize", "zzzzqzzz\nCui dono lepidum novum libellum");
  await page.click("#macronize_btn");
  await page.locator("#resultText .verse-foot.no-scan").first().waitFor({ state: "visible", timeout: 120_000 });
  await page.click("#dark_mode");   // dark-mode .no-scan chip color (specificity win)
  await page.click("#dark_mode");   // back to light

  // Exports.
  await page.click("#copy_btn").catch(() => {});
  await page.click("#export_csv").catch(() => {});

  // ---- 5. Touch paths in the SAME context (no second wordlist parse) ----
  // A second page shares the context's IndexedDB (wordlist already parsed), and CDP
  // touch emulation flips (pointer: coarse) so the app takes the touch/sheet branch.
  const touchPage = await context.newPage();
  const tcdp = await context.newCDPSession(touchPage);
  await tcdp.send("Emulation.setTouchEmulationEnabled", { enabled: true, maxTouchPoints: 5 });
  await tcdp.send("Emulation.setDeviceMetricsOverride", { width: 390, height: 844, deviceScaleFactor: 2, mobile: true });
  await touchPage.goto("/wiktionary_pron/macronizer.html");
  await touchPage.locator("#macronize_btn").waitFor({ state: "visible", timeout: 300_000 });
  await touchPage.fill("#text_to_macronize", "provinciarum divisa");
  await touchPage.click("#macronize_btn");
  await touchPage.locator("#resultText .ipa").nth(1).waitFor({ state: "visible", timeout: 120_000 });

  async function cdpTap(el) {
    const pt = await el.evaluate((node) => {
      const r = node.getBoundingClientRect();
      return { x: r.x + r.width / 2, y: r.y + r.height / 2 };
    });
    await tcdp.send("Input.dispatchTouchEvent", { type: "touchStart", touchPoints: [{ x: pt.x, y: pt.y }] });
    await tcdp.send("Input.dispatchTouchEvent", { type: "touchEnd", touchPoints: [] });
  }

  const flagged = touchPage.locator("#resultText .ipa").nth(1);
  await cdpTap(flagged);   // tap flagged → docked sheet
  await touchPage.locator(".word-popup.sheet").waitFor({ state: "visible", timeout: 5000 });
  // blur-before-dock: focus is NOT in the editable cell while the sheet is open.
  await touchPage.locator("#sheet-scrim").waitFor({ state: "visible", timeout: 5000 });
  // scrim tap closes.
  const scrim = touchPage.locator("#sheet-scrim");
  await cdpTap(scrim);
  await touchPage.locator(".word-popup.sheet").waitFor({ state: "hidden", timeout: 5000 });
  // Android Back (popstate) closes the reopened sheet.
  await cdpTap(flagged);
  await touchPage.locator(".word-popup.sheet").waitFor({ state: "visible", timeout: 5000 });
  await touchPage.goBack();
  await touchPage.locator(".word-popup.sheet").waitFor({ state: "hidden", timeout: 5000 });

  const cov = await page.coverage.stopJSCoverage();

  // Keep only scripts we own (macronizer page + engine dist + app scripts),
  // not CDN deps (wasmoon, localforage, jszip, pdf-lib, fontkit, fr-compromise).
  const own = cov.filter((e) => e.url.includes("/wiktionary_pron/"));
  fs.mkdirSync(path.dirname(OUT), { recursive: true });
  fs.writeFileSync(OUT, JSON.stringify(own));
  console.log(`[coverage] wrote ${OUT}: ${own.length} scripts`);
});
