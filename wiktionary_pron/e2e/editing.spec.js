import { test, expect } from "@playwright/test";

const PAGE = "/wiktionary_pron/macronizer.html";

async function macronize(page, text) {
  await page.fill("#text_to_macronize", text);
  await page.click("#macronize_btn");
  await expect(page.locator("#resultText .ipa").first()).toBeVisible({ timeout: 120_000 });
}

// Client-rect centre of one character of the first word span. Uses a Range over the
// span's text node so the click lands inside the glyph, not on the span's padding.
async function charCenter(page, charIndex) {
  return await page.evaluate((charIndex) => {
    const span = document.querySelector("#resultText .ipa");
    const tn = span.firstChild;
    const range = document.createRange();
    range.setStart(tn, charIndex);
    range.setEnd(tn, Math.min(charIndex + 1, tn.length));
    const r = range.getBoundingClientRect();
    return { x: (r.left + r.right) / 2, y: (r.top + r.bottom) / 2 };
  }, charIndex);
}

test.describe("Phase 2 editing", () => {
  test("click a vowel toggles its macron; Ctrl+Z / Ctrl+Y / Ctrl+Shift+Z round-trip", async ({ page }) => {
    test.setTimeout(360_000);
    await page.goto(PAGE);
    await expect(page.locator("#macronize_btn")).toBeEnabled({ timeout: 240_000 });

    await macronize(page, "divisa");
    const span = page.locator("#resultText .ipa").first();
    await expect(span).toHaveAttribute("content", "dīvīsa");

    // Toggle the ī at index 1 → "divīsa" (that single vowel flips).
    const pt = await charCenter(page, 1);
    await page.mouse.click(pt.x, pt.y);
    await expect(span).toHaveAttribute("content", "divīsa");

    // Ctrl+Z undoes the toggle.
    await page.keyboard.press("Control+z");
    await expect(span).toHaveAttribute("content", "dīvīsa");

    // Ctrl+Y redoes.
    await page.keyboard.press("Control+y");
    await expect(span).toHaveAttribute("content", "divīsa");

    // Ctrl+Shift+Z is the other redo chord — the word stays toggled.
    await page.keyboard.press("Control+Shift+z");
    await expect(span).toHaveAttribute("content", "divīsa");

    // Undo again — the round-trip is fully reversible.
    await page.keyboard.press("Control+z");
    await expect(span).toHaveAttribute("content", "dīvīsa");
  });

  test("clicking a consonant does not toggle; typing edits and Ctrl+Z reverts", async ({ page }) => {
    test.setTimeout(360_000);
    await page.goto(PAGE);
    await expect(page.locator("#macronize_btn")).toBeEnabled({ timeout: 240_000 });

    await macronize(page, "divisa");
    const span = page.locator("#resultText .ipa").first();
    await expect(span).toHaveAttribute("content", "dīvīsa");

    // Click the consonant v (index 2) — precise hit-testing must NOT toggle a neighbour.
    const pt = await charCenter(page, 2);
    await page.mouse.click(pt.x, pt.y);
    await expect(span).toHaveAttribute("content", "dīvīsa");

    // The caret sits inside the word; typing edits it and the content attr follows.
    await page.keyboard.type("x");
    const edited = await span.textContent();
    expect(edited).toContain("x");
    await expect(span).toHaveAttribute("content", edited);

    await page.keyboard.press("Control+z");
    await expect(span).toHaveAttribute("content", "dīvīsa");
  });

  test("keyboard: Enter on a flagged word opens the readings popup", async ({ page }) => {
    test.setTimeout(360_000);
    await page.goto(PAGE);
    await expect(page.locator("#macronize_btn")).toBeEnabled({ timeout: 240_000 });

    await macronize(page, "divisa");
    const span = page.locator("#resultText .ipa").first();
    await expect(span).toHaveAttribute("content", "dīvīsa");

    // Flagged span is focusable; Enter opens the dialog. The word must NOT change
    // (no accidental toggle from the activation).
    await span.focus();
    await page.keyboard.press("Enter");
    await expect(page.locator(".word-popup .popup-cycle")).toBeVisible({ timeout: 5000 });
    await expect(span).toHaveAttribute("content", "dīvīsa");
  });

  test("touch: tap a flagged word opens the sheet, tap a clean word does not", async ({ browser }) => {
    // hasTouch context so isTouch() is true and the sheet path runs.
    const context = await browser.newContext({ hasTouch: true, viewport: { width: 390, height: 844 } });
    const page = await context.newPage();
    test.setTimeout(360_000);
    await page.goto(PAGE);
    await expect(page.locator("#macronize_btn")).toBeEnabled({ timeout: 240_000 });

    await macronize(page, "provinciarum divisa");
    const clean = page.locator("#resultText .ipa").nth(0);   // prōvinciārum — unambiguous
    const flagged = page.locator("#resultText .ipa").nth(1); // divisa — 2 readings
    await expect(clean).toHaveAttribute("content", "prōvinciārum");
    await expect(clean).not.toHaveClass(/ambig|unknown/);   // premise: provinciarum is clean
    await expect(flagged).toHaveAttribute("content", "dīvīsa");
    await expect(flagged).toHaveClass(/ambig/);             // premise: divisa is flagged

    // Tap the CLEAN word → no sheet, no toggle (caret lands for editing).
    await clean.tap();
    await expect(page.locator(".word-popup")).not.toBeVisible({ timeout: 5000 });
    await expect(clean).toHaveAttribute("content", "prōvinciārum");

    // Tap the FLAGGED word → the sheet (readings-first) appears.
    await flagged.tap();
    await expect(page.locator(".word-popup.sheet")).toBeVisible({ timeout: 5000 });
    const readings = page.locator(".word-popup .popup-section", { hasText: /^Possible readings/ });
    await expect(readings).toBeVisible({ timeout: 5000 });

    // Tap a reading row → the word changes to that spelling and the sheet closes.
    const rows = page.locator(".word-popup table.readings tr");
    const rowCount = await rows.count();
    expect(rowCount).toBeGreaterThan(1);
    await rows.nth(1).tap();
    await expect(flagged).not.toHaveAttribute("content", "dīvīsa", { timeout: 5000 });
    await expect(page.locator(".word-popup.sheet")).not.toBeVisible({ timeout: 5000 });

    await context.close();
  });
});
