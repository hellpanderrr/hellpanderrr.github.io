import { test, expect } from "@playwright/test";

const APP = "/wiktionary_pron/index.html";

/**
 * Acceptance tests for features currently parked in git stashes on `main`
 * (backup on branch `wip-everything`). Un-skip each block when its stash
 * is applied:
 *
 *   stash "french-liaison"     → liaison tests
 *   stash "portuguese-support" → Portuguese tests
 */

async function selectLanguage(page, lang) {
  await expect(page.locator("#lang")).toBeEnabled({ timeout: 60_000 });
  await page.selectOption("#lang", lang);
  await expect(page.locator("#submit")).toBeEnabled({ timeout: 120_000 });
}

test.describe("french-liaison stash", () => {
  test.skip(true, "apply stash 'french-liaison' first");

  test("liaison checkbox appears only for French", async ({ page }) => {
    await page.goto(APP);
    await selectLanguage(page, "French");
    await expect(page.locator("#french_liaison_options")).toBeVisible();
    await selectLanguage(page, "Polish");
    await expect(page.locator("#french_liaison_options")).toBeHidden();
  });

  test("liaison markers render with rule tooltips", async ({ page }) => {
    await page.goto(APP);
    await selectLanguage(page, "French");
    await page.check("#liaison_checkbox");
    await page.fill("#text_to_transcribe", "les amis");
    await page.click("#submit_by_line");
    const marker = page.locator("#result .liaison-marker").first();
    await expect(marker).toBeVisible();
    await expect(marker.locator(".tooltip")).toContainText("les + amis");
  });

  test("CSV export strips liaison ties from text", async ({ page }) => {
    await page.goto(APP);
    await selectLanguage(page, "French");
    await page.check("#liaison_checkbox");
    await page.fill("#text_to_transcribe", "les amis");
    await page.click("#submit_by_line");
    const downloadPromise = page.waitForEvent("download");
    await page.click("#export_csv");
    const download = await downloadPromise;
    const fs = await import("node:fs");
    const content = fs.readFileSync(await download.path(), "utf8");
    expect(content).toContain("les");
    expect(content).not.toContain("les‿amis"); // no tie in the text column
  });
});

test.describe("portuguese-support stash", () => {
  test.skip(true, "apply stash 'portuguese-support' first");

  test("Portuguese loads its lexicon and transcribes", async ({ page }) => {
    await page.goto(APP);
    await selectLanguage(page, "Portuguese");
    await page.fill("#text_to_transcribe", "obrigado");
    await page.click("#submit");
    await expect(page.locator("#result .ipa").first()).toContainText("ɡa");
    await expect(page.locator("#result .error")).toHaveCount(0);
  });

  test("Portuguese multi-variant words are cyclable", async ({ page }) => {
    await page.goto(APP);
    await selectLanguage(page, "Portuguese");
    await page.fill("#text_to_transcribe", "cidade");
    await page.click("#submit");
    // Portuguese is in the multi-value list once the stash is applied
    await expect(page.locator("#result .ipa").first()).toBeVisible();
  });
});
