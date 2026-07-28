import { test, expect } from "@playwright/test";

const PAGE = "/wiktionary_pron/macronizer.html";

/**
 * Smoke test for the WASM Latin macronizer. First run downloads ~10 MB of
 * gzipped engine assets and parses the 812k-entry wordlist into IndexedDB,
 * so this test gets a large timeout. Within one Playwright run the browser
 * context is fresh each test, so keep it to a single test that covers the
 * whole pipeline.
 */
test.describe("macronizer", () => {
  test("initializes and macronizes provinciarum", async ({ page }) => {
    // The 812k-entry IndexedDB insert alone takes ~10 min in a fresh profile
    // (measured ~150k entries/100s), and Playwright contexts never reuse it.
    test.setTimeout(1_200_000);
    await page.goto(PAGE);

    // Ready when the macronize button is enabled (init + wordlist load done)
    await expect(page.locator("#macronize_btn")).toBeEnabled({
      timeout: 1_140_000,
    });

    await page.fill("#text_to_macronize", "provinciarum");
    await page.click("#macronize_btn");

    await expect(page.locator("#result")).toBeVisible({ timeout: 120_000 });
    // prōvinciārum: gen.pl. of prōvincia — both long vowels must be marked.
    // Words render via a `content` attribute painted with CSS attr(content),
    // so the span's text is empty — assert the attribute, not the text.
    await expect(page.locator("#resultText .ipa").first()).toHaveAttribute(
      "content",
      "prōvinciārum",
      { timeout: 120_000 },
    );
  });
});
