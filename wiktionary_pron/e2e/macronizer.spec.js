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
    // Since the range-chunk wordlist store, first visit = download + parse
    // (~30s); the IndexedDB persist happens in the background.
    test.setTimeout(300_000);
    await page.goto(PAGE);

    // Ready when the macronize button is enabled (init + wordlist parse done)
    await expect(page.locator("#macronize_btn")).toBeEnabled({
      timeout: 240_000,
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

  test("dark mode toggle changes its own icon, not the home button's", async ({
    page,
  }) => {
    // Regression: the toggle used to target '#header > a > i', which is the
    // HOME link's icon — the sun appeared on the wrong side of the header.
    await page.goto(PAGE);
    await page.click("#dark_mode");
    await expect(page.locator("body")).toHaveClass(/dark_mode/);
    await expect(page.locator("#dark_mode i")).toHaveClass(/icon-sun/);
    await expect(page.locator("#home i")).toHaveClass(/icon-home/);
    await page.click("#dark_mode");
    await expect(page.locator("#dark_mode i")).toHaveClass(/icon-moon/);
    await expect(page.locator("#home i")).toHaveClass(/icon-home/);
  });

  test("return visit serves the wordlist from IndexedDB chunks", async ({
    page,
  }) => {
    test.setTimeout(300_000);
    // Visit 1: parse + wait for the background chunk persist to finish
    const persisted = page.waitForEvent("console", {
      predicate: (m) => m.text().includes("background persist complete"),
      timeout: 240_000,
    });
    await page.goto(PAGE);
    await expect(page.locator("#macronize_btn")).toBeEnabled({
      timeout: 240_000,
    });
    await persisted;

    // Visit 2: same context → same IndexedDB. Must come up without re-parsing
    // and answer lookups through the chunk store.
    await page.reload();
    await expect(page.locator("#macronize_btn")).toBeEnabled({
      timeout: 60_000,
    });
    await page.fill("#text_to_macronize", "arma virumque cano");
    await page.click("#macronize_btn");
    await expect(page.locator("#resultText .ipa").first()).toHaveAttribute(
      "content",
      "arma",
      { timeout: 60_000 },
    );
    // virum has a long u — proves chunk lookups return real entries
    await expect(page.locator("#resultText .ipa").nth(1)).toHaveAttribute(
      "content",
      /vir[ūu]mque/,
      { timeout: 60_000 },
    );
  });
});
