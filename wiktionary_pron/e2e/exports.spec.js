import { test, expect } from "@playwright/test";
import fs from "node:fs";

const APP = "/wiktionary_pron/index.html";

async function selectLanguage(page, lang) {
  await expect(page.locator("#lang")).toBeEnabled({ timeout: 60_000 });
  await page.selectOption("#lang", lang);
  await expect(page.locator("#submit")).toBeEnabled({ timeout: 90_000 });
}

test.describe("exports", () => {
  test("CSV export (line mode) contains words and IPA", async ({ page }) => {
    await page.goto(APP);
    await selectLanguage(page, "Polish");
    await page.fill("#text_to_transcribe", "dobry wieczór");
    await page.click("#submit_by_line");
    await expect(page.locator("#result .ipa").first()).toBeVisible();

    const downloadPromise = page.waitForEvent("download");
    await page.click("#export_csv");
    const download = await downloadPromise;

    expect(download.suggestedFilename()).toMatch(/^transcription_.*\.csv$/);
    const content = fs.readFileSync(await download.path(), "utf8");
    expect(content).toContain("Text\tIPA");
    expect(content).toContain("dobry");
    expect(content).toContain("ˈdɔb.rɨ");
  });

  test("PDF export produces a non-empty .pdf download", async ({ page }) => {
    await page.goto(APP);
    await selectLanguage(page, "Polish");
    await page.fill("#text_to_transcribe", "dobry wieczór");
    await page.click("#submit_by_line");
    await expect(page.locator("#result .ipa").first()).toBeVisible();

    const downloadPromise = page.waitForEvent("download", { timeout: 60_000 });
    await page.click("#export_pdf");
    const download = await downloadPromise;

    expect(download.suggestedFilename()).toMatch(/\.pdf$/);
    const buf = fs.readFileSync(await download.path());
    expect(buf.length).toBeGreaterThan(1000);
    expect(buf.subarray(0, 5).toString()).toBe("%PDF-");
  });
});
