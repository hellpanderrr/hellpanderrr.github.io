import { test, expect } from "@playwright/test";

const PAGE = "/wiktionary_pron/macronizer.html";

test("popup shows RFTagger disagreement + Morpheus dedup for currito", async ({ page }) => {
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
});

test("v/u words cycle reversibly — divisa's original spelling must come back", async ({ page }) => {
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

test("prose shows no grey placeholders; numbered verse scans after line-number strip", async ({ page }) => {
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
});

test("CSV split button exports per word (default) and per line from the dropdown", async ({ page }) => {
  test.setTimeout(300_000);
  await page.goto(PAGE);
  await expect(page.locator("#macronize_btn")).toBeEnabled({ timeout: 240_000 });

  await page.fill("#text_to_macronize", "divisa diuisa");
  await page.click("#macronize_btn");
  await expect(page.locator("#resultText .ipa").first()).toBeVisible({ timeout: 120_000 });

  // Default: body runs the last-used mode (per word by default).
  await expect(page.locator("#export_csv")).toHaveAttribute("title", /per word/i);
  const wordDl = page.waitForEvent("download");
  await page.click("#export_csv");
  const wordDownload = await wordDl;
  expect(wordDownload.suggestedFilename()).toMatch(/\.csv$/);

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
