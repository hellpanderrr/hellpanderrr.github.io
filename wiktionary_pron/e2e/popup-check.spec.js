import { test, expect } from "@playwright/test";

const PAGE = "/wiktionary_pron/macronizer.html";

test.describe.configure({ mode: "serial" });

// One shared page for all four tests: the 812k wordlist parses ONCE into
// IndexedDB (first test), then each later test reloads from the chunk store
// instead of re-downloading + re-parsing (M-015: 4 parses → 1).
let sharedPage;
test.beforeAll(async ({ browser }) => {
  const context = await browser.newContext();
  sharedPage = await context.newPage();
});
test.afterAll(async () => {
  if (sharedPage) await sharedPage.context().close();
});

test("popup shows RFTagger disagreement + Morpheus dedup for currito", async () => {
  const page = sharedPage;
  test.setTimeout(300_000);
  await page.goto(PAGE);
  await expect(page.locator("#macronize_btn")).toBeEnabled({ timeout: 240_000 });

  await page.fill("#text_to_macronize", "currito");
  await page.click("#macronize_btn");
  await expect(page.locator("#resultText .ipa").first()).toBeVisible({ timeout: 120_000 });

  // Desktop: hovering a flagged word opens the popup (single-click toggles a vowel).
  await page.locator("#resultText .ipa").first().hover();

  // 0. Readings come FIRST (the debug detail is collapsed behind <details>)
  const readings = page.locator(".word-popup .popup-section", { hasText: /^Possible readings/ });
  await expect(readings).toBeVisible({ timeout: 5000 });
  const details = page.locator(".word-popup details.popup-analysis");
  await expect(details).toBeVisible();
  await expect(details).not.toHaveAttribute("open");

  // 1. RFTagger disagreement note — now inside the collapsed details; open it.
  await details.locator("summary").click();
  const note = page.locator(".word-popup .popup-note", { hasText: /RFTagger classifies/ });
  await expect(note).toBeVisible({ timeout: 5000 });
  await expect(note).toContainText("adverb");
  await expect(note).toContainText("verb");

  // 2. Morpheus rows deduped to ONE identical row
  const morpheusSection = page.locator(".popup-section", { hasText: "Morpheus analyses" });
  const rows = morpheusSection.locator("tr");
  await expect(rows).toHaveCount(1, { timeout: 5000 });

  // 3. Wordlist label honest
  const wlLabel = page.locator(".word-popup tr", { hasText: "Wordlist:" });
  await expect(wlLabel).toContainText("Not found");

  // 4. Dictionary gloss column (M-005) — currito is Morpheus-rescued (not in the
  // wordlist), so its lemma curro carries an L&S gloss; the column fills in after
  // the glosses.tsv.gz download lands.
  const defCell = page.locator(".word-popup table.readings td.r-def").first();
  await expect(defCell).toBeVisible({ timeout: 10_000 });
  await expect(defCell).not.toContainText("—");
});

test("dictionary gloss disambiguates homographs in the readings popup", async () => {
  const page = sharedPage;
  test.setTimeout(300_000);
  await page.goto(PAGE);
  await expect(page.locator("#macronize_btn")).toBeEnabled({ timeout: 240_000 });

  // populus = people (bare), populus2 = poplar tree (numbered) — the exact
  // homograph pair the M-005 feature exists for. popule is the poplar's vocative
  // (wordlist lemma populus2), so its gloss must be the poplar, NOT the people.
  await page.fill("#text_to_macronize", "popule");
  await page.click("#macronize_btn");
  const span = page.locator("#resultText .ipa").first();
  await expect(span).toBeVisible({ timeout: 120_000 });
  await span.hover();

  const defCells = page.locator(".word-popup table.readings td.r-def");
  await expect(defCells.first()).toBeVisible({ timeout: 10_000 });
  const defs = await defCells.allTextContents();
  expect(defs.length).toBeGreaterThan(0);
  // The poplar reading must carry the poplar gloss — proving exact-key homograph
  // resolution reaches the browser (not the bare-lemma "people").
  expect(defs.join(" ")).toContain("poplar");
  // And no placeholder "—" should survive once the glosses have loaded.
  expect(defs.every((d) => d.trim() && d.trim() !== "—")).toBeTruthy();
});

test("glosses land in every reading row even when popups open before the download finishes", async () => {
  const page = sharedPage;
  test.setTimeout(300_000);
  await page.goto(PAGE);
  await expect(page.locator("#macronize_btn")).toBeEnabled({ timeout: 240_000 });

  // Race: hover every word IMMEDIATELY after the result renders, while the
  // glosses.tsv.gz download is still in flight. Every span's __popupHtml was
  // built with a "—" placeholder; the fix must rebuild them all once the
  // gloss cache lands, not just the popup open at that instant.
  await page.fill("#text_to_macronize", "Gallia est omnis divisa in partes tres");
  await page.click("#macronize_btn");
  const spans = page.locator("#resultText .ipa");
  await expect(spans.first()).toBeVisible({ timeout: 120_000 });
  for (let i = 0; i < (await spans.count()); i++) {
    await spans.nth(i).hover();
    await page.waitForTimeout(120);
  }
  // Let the gloss download finish, then re-hover and assert no "—" survives.
  await page.waitForTimeout(10_000);
  const failures = [];
  for (let i = 0; i < (await spans.count()); i++) {
    const tok = (await spans.nth(i).textContent()).trim();
    await spans.nth(i).hover();
    await page.waitForTimeout(300);
    const defs = await page.locator(".word-popup table.readings td.r-def").allTextContents();
    if (!defs.length || defs.some((d) => !d.trim() || d.trim() === "—")) {
      failures.push(`${tok}: [${defs.join(" | ")}]`);
    }
  }
  expect(failures).toEqual([]);
});

test("v/u words cycle reversibly — divisa's original spelling must come back", async () => {
  const page = sharedPage;
  test.setTimeout(300_000);
  await page.goto(PAGE);
  await expect(page.locator("#macronize_btn")).toBeEnabled({ timeout: 240_000 });

  await page.fill("#text_to_macronize", "divisa");
  await page.click("#macronize_btn");
  const span = page.locator("#resultText .ipa").first();
  await expect(span).toBeVisible({ timeout: 120_000 });

  // Input mirroring: the word was typed with v, so it must display dīvīsa (v) —
  // not dīuīsa. And that spelling must already be a candidate, or the first cycle
  // jumps somewhere and the original is unreachable forever (the divisa bug).
  await expect(span).toHaveAttribute("content", "dīvīsa");
  const initial = await span.getAttribute("content");

  // Desktop: hovering the flagged word opens the popup (a single click would toggle).
  await span.hover();
  const nextBtn = page.locator(".word-popup .popup-cycle");
  await expect(nextBtn).toBeVisible({ timeout: 5000 });

  // Keep clicking "Next spelling" until we wrap back to the initial spelling —
  // that is exactly what the old code could never do.
  for (let i = 0; i < 8; i++) {
    if ((await span.getAttribute("content")) === initial) break;
    await nextBtn.click();
  }
  await expect(span).toHaveAttribute("content", initial);
});

test("prose shows no grey placeholders; numbered verse scans after line-number strip", async () => {
  const page = sharedPage;
  test.setTimeout(300_000);
  await page.goto(PAGE);
  await expect(page.locator("#macronize_btn")).toBeEnabled({ timeout: 240_000 });

  // Prose mode (default): no scansion requested, so no grey "—" placeholders at all.
  await page.fill("#text_to_macronize", "Cui dono lepidum novum libellum");
  await page.click("#macronize_btn");
  await expect(page.locator("#resultText .ipa").first()).toBeVisible({ timeout: 120_000 });
  await expect(page.locator("#resultText .verse-foot")).toHaveCount(0);

  // Meter mode + trailing line numbers: stripped before processing, so both scan.
  await page.selectOption("#scan", "hendecasyllable");
  await page.fill(
    "#text_to_macronize",
    "Cui dono lepidum novum libellum 1.1\niam tum, cum ausus es unus Italorum 5",
  );
  await page.click("#macronize_btn");
  await expect(page.locator("#resultText .verse-foot").first()).toBeVisible({ timeout: 120_000 });
  await expect(page.locator("#resultText .verse-foot")).toHaveCount(2);
  await expect(page.locator("#resultText .verse-foot.no-scan")).toHaveCount(0);
  // The line numbers are reference noise — they must not survive into the output.
  await expect(page.locator("#resultText")).not.toContainText("1.1");

  // M-014 regression: in dark mode the "—" placeholder must NOT pick up the
  // real-feet purple. Force a line that cannot scan so a .no-scan chip exists,
  // then toggle dark mode and assert the chip is the muted grey, not purple.
  await page.fill("#text_to_macronize", "zzzzqzzz\nCui dono lepidum novum libellum");
  await page.click("#macronize_btn");
  await expect(page.locator("#resultText .verse-foot.no-scan").first()).toBeVisible({ timeout: 120_000 });
  await page.click("#dark_mode");
  await expect(page.locator("body")).toHaveClass(/dark_mode/);
  const chipColor = await page.locator("#resultText .verse-foot.no-scan").first().evaluate(
    (el) => getComputedStyle(el).color,
  );
  // .no-scan is #777 in dark mode — NOT the #CE93D8 purple of real feet.
  expect(chipColor).toBe("rgb(119, 119, 119)");
  await page.click("#dark_mode");
});

test("CSV split button exports per word (default) and per line from the dropdown", async () => {
  const page = sharedPage;
  test.setTimeout(300_000);
  await page.goto(PAGE);
  await expect(page.locator("#macronize_btn")).toBeEnabled({ timeout: 240_000 });

  await page.fill("#text_to_macronize", "divisa diuisa");
  await page.click("#macronize_btn");
  await expect(page.locator("#resultText .ipa").first()).toBeVisible({ timeout: 120_000 });

  // Cycle the first word (divisa → a dīvīsa/diuīsa variant) so the CSV export
  // reflects a RENDERED spelling, not just the typed input.
  const firstSpan = page.locator("#resultText .ipa").first();
  await expect(firstSpan).toHaveAttribute("content", "dīvīsa", { timeout: 120_000 });
  await firstSpan.hover();
  const nextBtn = page.locator(".word-popup .popup-cycle");
  await expect(nextBtn).toBeVisible({ timeout: 5000 });
  await nextBtn.click();
  const cycled = await firstSpan.getAttribute("content");
  expect(cycled).not.toBe("divisa");   // the cycle actually moved somewhere

  // Default: body runs the last-used mode (per word by default).
  await expect(page.locator("#export_csv")).toHaveAttribute("title", /per word/i);
  const wordDl = page.waitForEvent("download");
  await page.click("#export_csv");
  const wordDownload = await wordDl;
  expect(wordDownload.suggestedFilename()).toMatch(/\.csv$/);
  // M-015: the per-word CSV reads the RENDERED spans, so the cycled spelling must
  // show up in the file (not the original input). Read the download's bytes.
  const wordStream = await wordDownload.createReadStream();
  let wordCsv = "";
  for await (const chunk of wordStream) wordCsv += chunk.toString("utf8");
  expect(wordCsv).toContain(cycled);

  // Caret opens the dropdown with both modes.
  await page.click("#export_csv_caret");
  const menu = page.locator("#csv_menu");
  await expect(menu).toBeVisible();
  await expect(menu.locator('li[data-csv-mode="word"]')).toHaveText(/Per word/);
  await expect(menu.locator('li[data-csv-mode="line"]')).toHaveText(/Per line/);

  // Per-line export from the dropdown.
  const lineDl = page.waitForEvent("download");
  await menu.locator('li[data-csv-mode="line"]').click();
  const lineDownload = await lineDl;
  expect(lineDownload.suggestedFilename()).toMatch(/\.csv$/);

  // After picking per line: checkmark moves there, localStorage saved, and the
  // BODY now surfaces the last-used mode (title + its export becomes per line).
  const saved = await page.evaluate(() => localStorage.getItem("macronizer_csv_mode"));
  expect(saved).toBe("line");
  await expect(page.locator("#export_csv")).toHaveAttribute("title", /per line/i);
  const lineDl2 = page.waitForEvent("download");
  await page.click("#export_csv");
  const lineDownload2 = await lineDl2;
  expect(lineDownload2.suggestedFilename()).toMatch(/\.csv$/);
});

test("popup renders above the word, details toggle keeps it in place", async () => {
  // Regression for M-023h (+ .1–.4): expanding "Analysis details" must NOT move
  // the popup. Growing it upward (when floating above the word) drags the just-
  // clicked <summary> out from under the cursor — the "popup jumps up" complaint.
  // The fix keeps the popup's top pinned and clamps the expanded content into the
  // space below with an internal scrollbar; collapsing restores normal placement.
  const page = sharedPage;
  test.setTimeout(300_000);
  await page.goto(PAGE);
  await expect(page.locator("#macronize_btn")).toBeEnabled({ timeout: 240_000 });
  await page.fill("#text_to_macronize", "in");
  await page.click("#macronize_btn");
  const span = page.locator("#resultText .ipa").first();
  await expect(span).toBeVisible({ timeout: 120_000 });
  await page.waitForTimeout(8000); // glosses load
  await span.hover();
  await page.waitForTimeout(800);
  const wordRect = await span.boundingBox();
  const before = await page.locator(".word-popup").boundingBox();
  // above the word (its bottom edge sits at/above the top of the word's row)
  expect(before.y + before.height).toBeLessThanOrEqual(wordRect.y + wordRect.height + 1);
  const summary = page.locator(".word-popup details.popup-analysis summary");
  const sb = await summary.boundingBox();
  // sample the popup y around the click — the top must NOT move at all (no jump)
  const ys = [];
  const poll = (async () => {
    for (let t = 0; t < 8; t++) {
      await page.waitForTimeout(16);
      const b = await page.locator(".word-popup").boundingBox();
      if (b) ys.push(Math.round(b.y));
    }
  })();
  await page.mouse.click(sb.x + sb.width / 2, sb.y + sb.height / 2);
  await poll;
  // still visible after the toggle
  await expect(page.locator(".word-popup")).toBeVisible({ timeout: 5000 });
  const unique = [...new Set(ys)];
  expect(unique.length).toBeLessThanOrEqual(1);
  if (unique.length) expect(Math.abs(unique[0] - Math.round(before.y))).toBeLessThanOrEqual(1);
  // collapse restores normal placement (top comes back if it had been clamped)
  await page.mouse.click(sb.x + sb.width / 2, sb.y + sb.height / 2);
  await page.waitForTimeout(400);
  const after = await page.locator(".word-popup").boundingBox();
  const vh = await page.evaluate(() => window.innerHeight);
  expect(after.y + after.height).toBeLessThanOrEqual(vh + 1);
});
