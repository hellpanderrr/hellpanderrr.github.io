import { test, expect } from "@playwright/test";

const APP = "/wiktionary_pron/index.html";

async function appReady(page) {
  await expect(page.locator("#lang")).toBeEnabled({ timeout: 60_000 });
}

async function selectLanguage(page, lang, timeout = 120_000) {
  await appReady(page);
  await page.selectOption("#lang", lang);
  await expect(page.locator("#submit")).toBeEnabled({ timeout });
}

test.describe("lexicon path", () => {
  test("Czech: dictionary word served from the lexicon", async ({ page }) => {
    // Visit 1 parses the zip and persists chunk records in the background
    const persisted = page.waitForEvent("console", {
      predicate: (m) => m.text().includes("persisted") && m.text().includes("chunks"),
      timeout: 120_000,
    });
    await page.goto(APP); // dict defaults to true → czech_lexicon.zip loads
    await selectLanguage(page, "Czech");
    await page.fill("#text_to_transcribe", "pes");
    await page.click("#submit");
    // czech_lexicon.zip has pes → /ˈpɛs/; processGermanIpa strips the slashes
    await expect(page.locator("#result .ipa").first()).toContainText("ˈpɛs");
    await persisted;

    // Visit 2: same context → lexicon must come up from the chunk store
    // (no zip parse) and still resolve dictionary words via prefetch
    await page.reload();
    await selectLanguage(page, "Czech");
    await page.fill("#text_to_transcribe", "den");
    await page.click("#submit");
    await expect(page.locator("#result .ipa").first()).toContainText("dɛn");
    const servedFromChunks = await page.evaluate(
      () => globalThis.lexicon["Czech"]?.mode,
    );
    expect(servedFromChunks).toBe("chunked");
  });

  test("Russian: V4 lexicon loads and multi-form word offers alternatives", async ({
    page,
  }) => {
    test.slow(); // ~5 MB zip + several-hundred-k-entry parse
    await page.goto(APP);
    await selectLanguage(page, "Russian", 300_000);

    // замок is the canonical ambiguous word: за́мок (castle) vs замо́к (lock).
    // The dictionary stores both forms, so the rendered span must be cyclable.
    await page.fill("#text_to_transcribe", "замок");
    await page.click("#submit");
    const span = page.locator("#result .ipa").first();
    await expect(span).toHaveClass(/multiple-values/);

    const first = (await span.textContent()).trim();
    await span.click();
    const second = (await span.textContent()).trim();
    expect(second).not.toStrictEqual(first);
    // Cycling far enough returns to the first value
    const values = (await span.getAttribute("all_values")).split("\n");
    expect(values.length).toBeGreaterThan(1);
  });

  test("Russian: dictionary stress is transferred onto the displayed word", async ({
    page,
  }) => {
    test.slow();
    await page.goto(APP);
    await selectLanguage(page, "Russian", 300_000);

    // Line mode renders .input_text elements, which get stress marks applied
    // from the dictionary. Must be a single-form entry: multi-form records
    // (e.g. вода → "во́да, вода́") deliberately skip the transfer.
    await page.fill("#text_to_transcribe", "голова");
    await page.click("#submit_by_line");
    await expect(page.locator("#result .input_text").first()).toContainText(
      "голова́",
    );
  });
});
