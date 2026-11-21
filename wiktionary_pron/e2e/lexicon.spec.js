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

  // Stress is not in Bulgarian or Belarusian spelling, so each has an IPA dictionary
  // (kaikki.org -> utils/bg_lexicon.zip, be_lexicon.zip). Without it the rules print no
  // stress mark at all ("работа" -> rɐbotɐ).
  for (const [lang, word, expected] of [
    ["Bulgarian", "работа", "ˈrabotɐ"], // has its own Wiktionary entry: its IPA, as written
    ["Belorussian", "вада", "vaˈda"],
    // only in a lemma's inflection table (no page, no IPA): the dictionary holds the stressed
    // spelling and the rules transcribe it, like Russian/Ukrainian
    ["Bulgarian", "приятели", "priˈja"],
    ["Belorussian", "настаўніка", "naˈstau"],
  ]) {
    test(`${lang}: stress comes from the dictionary (${word})`, async ({ page }) => {
      await page.goto(APP);
      await selectLanguage(page, lang, 180_000);
      await page.fill("#text_to_transcribe", word);
      await page.click("#submit");
      const ipa = page.locator("#result .ipa").first();
      await expect(ipa).toContainText(expected);
      // like every other dictionary the app shows bare IPA: no brackets, no slashes
      expect(await ipa.textContent()).not.toMatch(/[[\]/]/);
    });
  }

  // A word with ONE pronunciation has no all_values; clicking it used to throw
  // "Cannot read properties of null (reading 'split')" (the variant-cycling handler).
  test("Bulgarian: clicking a single-pronunciation word does not throw", async ({ page }) => {
    const errors = [];
    page.on("pageerror", (e) => errors.push(e.message));
    await page.goto(APP);
    await selectLanguage(page, "Bulgarian", 180_000);
    await page.fill("#text_to_transcribe", "работа");
    await page.click("#submit");
    const span = page.locator("#result .ipa").first();
    await expect(span).toBeVisible();
    await span.click();
    await page.waitForTimeout(300);
    expect(errors).toEqual([]);
  });

  // get_ipa_cache keeps results for 7 days. Results cached BEFORE the dictionary (unstressed) must not
  // be served after it: the Bulgarian/Belorussian cache keys carry a revision.
  test("Bulgarian: a result cached before the dictionary is not served", async ({ page }) => {
    await page.goto(APP);
    await selectLanguage(page, "Bulgarian", 180_000);
    await page.fill("#text_to_transcribe", "работа");
    await page.click("#submit");
    await expect(page.locator("#result .ipa").first()).toContainText("ˈrabotɐ");
    // Rewrite the cache as the OLD code would have left it: the key without the revision, an unstressed result.
    await page.evaluate(() => {
      const store = JSON.parse(localStorage.getItem("get_ipa_no_cache"));
      const m = store.get_ipa_no_cache;
      for (const key of Object.keys(m)) {
        const args = JSON.parse(key);
        if (args[0] !== "работа") continue;
        const entry = m[key];
        delete m[key];
        const old = args.slice();
        old[1] = String(old[1]).split(";").slice(0, 3).join(";"); // drop the revision part
        entry.result = { ...entry.result, value: "rɐbotɐ", source: "rules" };
        entry.expiration = Date.now() + 86_400_000;
        m[JSON.stringify(old)] = entry;
      }
      localStorage.setItem("get_ipa_no_cache", JSON.stringify(store));
    });
    await page.reload();
    await selectLanguage(page, "Bulgarian", 180_000);
    await page.fill("#text_to_transcribe", "работа");
    await page.click("#submit");
    await expect(page.locator("#result .ipa").first()).toContainText("ˈrabotɐ");
  });

  // Like Russian/Ukrainian, line mode shows the word with the dictionary's stress mark inserted
  // (голова -> голова́). For Bulgarian/Belorussian the stressed spelling comes from the dictionary record.
  for (const [lang, word, shown] of [
    ["Bulgarian", "работа", "ра́бота"], // has its own Wiktionary IPA, spelling stored after "|"
    ["Bulgarian", "приятели", "прия́тели"], // only in a declension table
    ["Belorussian", "хата", "ха́та"],
    ["Belorussian", "настаўніка", "наста́ўніка"],
  ]) {
    test(`${lang}: the dictionary stress is inserted into the shown word (${word})`, async ({ page }) => {
      await page.goto(APP);
      await selectLanguage(page, lang, 180_000);
      await page.fill("#text_to_transcribe", word);
      await page.click("#submit_by_line");
      await expect(page.locator("#result .input_text").first()).toContainText(shown);
    });
  }

  // Bulgarian text marks stress with a GRAVE accent (Wikipedia does); the rules used to error on it
  // ("Бълга̀рия" -> an error cell), and on the pronoun "ѝ".
  test("Bulgarian: a typed grave accent is the stress, and ѝ transcribes", async ({ page }) => {
    await page.goto(APP);
    await selectLanguage(page, "Bulgarian", 180_000);
    await page.fill("#text_to_transcribe", "Бълга̀рия ѝ");
    await page.click("#submit");
    await expect(page.locator("#result .ipa")).toHaveCount(2);
    // (the app appends one empty error cell after every line; only a cell with text is a failure)
    await expect(page.locator("#result .error").filter({ hasText: /\S/ })).toHaveCount(0);
    const [a, b] = await page.locator("#result .ipa").allTextContents();
    expect(a).toContain("ˈɡarijɐ");
    expect(b.trim()).toBe("i");
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
