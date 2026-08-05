import { test, expect } from "@playwright/test";

const PAGE = "/wiktionary_pron/macronizer.html";

test("popup shows RFTagger disagreement + Morpheus dedup for currito", async ({ page }) => {
  test.setTimeout(300_000);
  await page.goto(PAGE);
  await expect(page.locator("#macronize_btn")).toBeEnabled({ timeout: 240_000 });

  await page.fill("#text_to_macronize", "currito");
  await page.click("#macronize_btn");
  await expect(page.locator("#resultText .ipa").first()).toBeVisible({ timeout: 120_000 });

  await page.locator("#resultText .ipa").first().click();

  // 1. RFTagger disagreement note
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
