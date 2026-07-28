import { test, expect } from "@playwright/test";

const APP = "/wiktionary_pron/index.html";

/**
 * Wait for main.js to finish evaluating. The module top-level-awaits the
 * wasmoon engine, and only then enables #lang and attaches all UI listeners —
 * interacting earlier hits dead buttons.
 */
async function appReady(page) {
  await expect(page.locator("#lang")).toBeEnabled({ timeout: 60_000 });
}

/**
 * Select a language via the dropdown and wait until the app has loaded its
 * Lua module (the app disables all form controls while loading and re-enables
 * them when the language is ready).
 */
async function selectLanguage(page, lang) {
  await appReady(page);
  await page.selectOption("#lang", lang);
  await expect(page.locator("#submit")).toBeEnabled({ timeout: 90_000 });
}

async function transcribe(page, text, mode = "#submit") {
  await page.fill("#text_to_transcribe", text);
  await page.click(mode);
}

test.describe("IPA transcriber", () => {
  test("page loads and offers all languages", async ({ page }) => {
    await page.goto(APP);
    await expect(page.locator("#lang")).toBeEnabled();
    const options = await page.locator("#lang option").allTextContents();
    for (const lang of ["Latin", "German", "French", "Polish", "Russian"]) {
      expect(options).toContain(lang);
    }
  });

  test("Polish: transcribes a word (no lexicon needed)", async ({ page }) => {
    await page.goto(APP);
    await selectLanguage(page, "Polish");
    await transcribe(page, "zewnętrzny");
    // Known-good value, same engine as the Node test suite
    await expect(page.locator("#result .ipa").first()).toContainText(
      "zɛvˈnɛn.tʂnɨ",
    );
  });

  test("German (dict=false): phonemic transcription via Lua rules", async ({
    page,
  }) => {
    // ?dict=false skips the large lexicon download — tests the Lua fallback path
    await page.goto(APP + "?dict=false");
    await selectLanguage(page, "German");
    await transcribe(page, "aufeinanderzupassende");
    await expect(page.locator("#result .ipa").first()).toContainText(
      "aʊ̯f(ʔ)aɪ̯ˈnandɐt͡suˌpasəndə",
    );
  });

  test("Latin: style and form selection changes output", async ({ page }) => {
    await page.goto(APP);
    await selectLanguage(page, "Latin");

    // Classical + Phonemic. Unlike the Node suite, the browser pipeline first
    // macronizes Latin input (provinciarum → prōvinciārum), so the IPA carries
    // vowel length — this asserts the full macronize→IPA chain.
    await page.selectOption("#lang_style", { label: "Classical" });
    await page.selectOption("#lang_form", { label: "Phonemic" });
    await transcribe(page, "provinciarum");
    await expect(page.locator("#result .ipa").first()).toContainText(
      "proː.u̯in.kiˈaː.rum",
    );
    await expect(page.locator("#result .ipa").first()).toHaveAttribute(
      "data-word",
      "prōvinciārum",
    );

    // Ecclesiastical: 'ci' becomes the affricate t͡ʃ — diagnostic of the style switch
    await page.selectOption("#lang_style", { label: "Ecclesiastical" });
    await page.selectOption("#lang_form", { label: "Phonetic" });
    await transcribe(page, "provinciarum");
    await expect(page.locator("#result .ipa").first()).toContainText("t͡ʃ");
  });

  test("line-by-line mode renders word and IPA cells", async ({ page }) => {
    await page.goto(APP);
    await selectLanguage(page, "Polish");
    await page.fill("#text_to_transcribe", "dobry wieczór");
    await page.click("#submit_by_line");
    const line = page.locator("#result tr.line").first();
    await expect(line.locator(".input_text")).toHaveCount(2);
    await expect(line.locator(".ipa")).toHaveCount(2);
    await expect(line.locator(".input_text").first()).toContainText("dobry");
  });

  test("unparseable token is marked as error, not silently dropped", async ({
    page,
  }) => {
    await page.goto(APP);
    await selectLanguage(page, "Polish");
    await transcribe(page, "12345");
    await expect(page.locator("#result .error").first()).toBeVisible();
  });

  test("URL params preselect language and transcribe text", async ({
    page,
  }) => {
    await page.goto(APP + "?lang=Polish&text=kot");
    await expect(page.locator("#submit")).toBeEnabled({ timeout: 90_000 });
    // ?text= triggers line-mode transcription automatically
    await expect(page.locator("#result .ipa").first()).toBeVisible();
    await expect(page.locator("#result .input_text").first()).toContainText(
      "kot",
    );
  });

  test("IPA results are cached in localStorage", async ({ page }) => {
    await page.goto(APP);
    await selectLanguage(page, "Polish");
    await transcribe(page, "kot");
    await expect(page.locator("#result .ipa").first()).toBeVisible();
    const cache = await page.evaluate(() =>
      localStorage.getItem("get_ipa_no_cache"),
    );
    expect(cache).toBeTruthy();
    expect(cache).toContain("kot");
  });
});

test.describe("UI chrome", () => {
  test("dark mode toggles body class", async ({ page }) => {
    await page.goto(APP);
    await appReady(page);
    await page.click("#dark_mode");
    await expect(page.locator("body")).toHaveClass(/dark_mode/);
    await page.click("#dark_mode");
    await expect(page.locator("body")).not.toHaveClass(/dark_mode/);
  });

  test("input text persists across reloads", async ({ page }) => {
    await page.goto(APP);
    await appReady(page); // input listener attaches after module evaluation
    await page.fill("#text_to_transcribe", "persistence check");
    await page.reload();
    await appReady(page); // restore also happens at module evaluation
    await expect(page.locator("#text_to_transcribe")).toHaveValue(
      "persistence check",
    );
  });

  test("clear button empties the textarea", async ({ page }) => {
    await page.goto(APP);
    await appReady(page);
    await page.fill("#text_to_transcribe", "something");
    await page.click("#clear_button");
    await expect(page.locator("#text_to_transcribe")).toHaveValue("");
  });

  test("help button appears and points at the language help page", async ({
    page,
  }) => {
    await page.goto(APP);
    await selectLanguage(page, "Polish");
    const helpLink = page.locator("#help_button_link");
    await expect(helpLink).toBeVisible();
    await expect(helpLink).toHaveAttribute("href", "help/polish.html");
  });
});
