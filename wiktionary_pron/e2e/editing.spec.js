import { test, expect } from "@playwright/test";

const PAGE = "/wiktionary_pron/macronizer.html";

async function macronize(page, text) {
  await page.fill("#text_to_macronize", text);
  await page.click("#macronize_btn");
  await expect(page.locator("#resultText .ipa").first()).toBeVisible({ timeout: 120_000 });
}

// Client-rect centre of one character of a word span. Uses a Range over the span's
// text node so the click lands inside the glyph, not on the span's padding.
// spanIndex selects among #resultText .ipa spans (default 0 = first word).
async function charCenter(page, charIndex, spanIndex = 0) {
  return await page.evaluate(([charIndex, spanIndex]) => {
    const span = document.querySelectorAll("#resultText .ipa")[spanIndex];
    const tn = span.firstChild;
    const range = document.createRange();
    range.setStart(tn, charIndex);
    range.setEnd(tn, Math.min(charIndex + 1, tn.length));
    const r = range.getBoundingClientRect();
    return { x: (r.left + r.right) / 2, y: (r.top + r.bottom) / 2 };
  }, [charIndex, spanIndex]);
}

test.describe.configure({ mode: "serial" });

test.describe("Phase 2 editing", () => {
  // One shared page for all desktop tests in this file: the 812k wordlist parses
  // once into IndexedDB (first test), then each later test just reloads from the
  // chunk store. The touch test below opens its OWN context (hasTouch) and pays
  // its own parse — that one cannot share (it needs touch semantics).
  let sharedPage;
  test.beforeAll(async ({ browser }) => {
    const context = await browser.newContext();
    sharedPage = await context.newPage();
  });
  test.afterAll(async () => {
    if (sharedPage) await sharedPage.context().close();
  });

  test("click a vowel toggles its macron; Ctrl+Z / Ctrl+Y / Ctrl+Shift+Z round-trip", async () => {
    const page = sharedPage;
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

  test("clicking a consonant does not toggle; typing edits and Ctrl+Z reverts", async () => {
    const page = sharedPage;
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

  test("keyboard: Enter on a flagged word opens the readings popup", async () => {
    const page = sharedPage;
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

    // M-015: Escape closes the dialog AND returns focus to the word it was opened
    // from (hidePopup(returnFocus=true) refocuses the span).
    await expect
      .poll(() => page.evaluate(() => document.activeElement === document.querySelector(".word-popup")))
      .toBe(true);
    await page.keyboard.press("Escape");
    await expect(page.locator(".word-popup")).toBeHidden({ timeout: 5000 });
    await expect
      .poll(() => page.evaluate(() => document.activeElement === document.querySelector("#resultText .ipa")))
      .toBe(true);
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

    // M-015: docked sheet shows a scrim, and focus is NOT in the editable cell
    // (blur-before-dock — the sheet anchors to the viewport bottom, not the keyboard).
    await expect(page.locator("#sheet-scrim")).toBeVisible();
    await expect
      .poll(() => page.evaluate(() => {
        const ae = document.activeElement;
        return ae && !ae.closest("#result");
      }))
      .toBe(true);

    // Tapping the SCRIM (tap elsewhere) closes the sheet; the word is unchanged.
    await page.locator("#sheet-scrim").tap();
    await expect(page.locator(".word-popup.sheet")).not.toBeVisible({ timeout: 5000 });
    await expect(flagged).toHaveAttribute("content", "dīvīsa");

    // Android Back (popstate) closes the sheet instead of navigating away.
    await flagged.tap();
    await expect(page.locator(".word-popup.sheet")).toBeVisible({ timeout: 5000 });
    await page.goBack();
    await expect(page.locator(".word-popup.sheet")).not.toBeVisible({ timeout: 5000 });
    await expect(flagged).toHaveAttribute("content", "dīvīsa");

    // Tap a reading row → the word changes to that spelling and the sheet closes.
    await flagged.tap();
    await expect(page.locator(".word-popup.sheet")).toBeVisible({ timeout: 5000 });
    const rows = page.locator(".word-popup table.readings tr");
    const rowCount = await rows.count();
    expect(rowCount).toBeGreaterThan(1);
    await rows.nth(1).tap();
    await expect(flagged).not.toHaveAttribute("content", "dīvīsa", { timeout: 5000 });
    await expect(page.locator(".word-popup.sheet")).not.toBeVisible({ timeout: 5000 });

    await context.close();
  });

  test("multi-line undo: an edit on line 2 does not clobber line 1's edit; both undo", async () => {
    const page = sharedPage;
    test.setTimeout(360_000);
    await page.goto(PAGE);
    await expect(page.locator("#macronize_btn")).toBeEnabled({ timeout: 240_000 });

    // Two lines, each with a togglable macron vowel (divisa → dīvīsa, provinciarum → prōvinciārum).
    await macronize(page, "divisa\nprovinciarum");
    const line1 = page.locator("#resultText .ipa").first();
    const line2 = page.locator("#resultText .ipa").nth(1);
    await expect(line1).toHaveAttribute("content", "dīvīsa");
    await expect(line2).toHaveAttribute("content", "prōvinciārum");

    // Toggle ī in line 1 (index 1) → divīsa.
    const p1 = await charCenter(page, 1, 0);
    await page.mouse.click(p1.x, p1.y);
    await expect(line1).toHaveAttribute("content", "divīsa");

    // Toggle ō in line 2 (index 2 of prōvinciārum) → provinciārum.
    const p2 = await charCenter(page, 2, 1);
    await page.mouse.click(p2.x, p2.y);
    await expect(line2).toHaveAttribute("content", "provinciārum");

    // One undo: line 2 reverts, line 1 KEEPS its toggle — the snapshot is whole-result.
    await page.keyboard.press("Control+z");
    await expect(line2).toHaveAttribute("content", "prōvinciārum");
    await expect(line1).toHaveAttribute("content", "divīsa");

    // Second undo: line 1 reverts too.
    await page.keyboard.press("Control+z");
    await expect(line1).toHaveAttribute("content", "dīvīsa");
  });

  test("unknown word renders the red flag; popup admits it is not in the wordlist", async () => {
    const page = sharedPage;
    test.setTimeout(360_000);
    await page.goto(PAGE);
    await expect(page.locator("#macronize_btn")).toBeEnabled({ timeout: 240_000 });

    // zyxwvut is in neither the wordlist nor Morpheus — the "guessed from ending" path.
    await macronize(page, "zyxwvut");
    const span = page.locator("#resultText .ipa").first();
    await expect(span).toHaveClass(/unknown/);
    await expect(span).toHaveText("zyxwvut");

    // The legend admits the guess (this is what the red means).
    await expect(page.locator("#legend")).toContainText("not in the wordlist");

    // Hover opens the popup, which says so plainly (details collapse first).
    await span.hover();
    const details = page.locator(".word-popup details.popup-analysis");
    await expect(details).toBeVisible({ timeout: 5000 });
    await details.locator("summary").click();
    const wl = page.locator(".word-popup tr", { hasText: "Wordlist:" });
    await expect(wl).toBeVisible({ timeout: 5000 });
    await expect(wl).toContainText("Not found");
    // And Morpheus genuinely found nothing for it.
    const morph = page.locator(".word-popup tr", { hasText: "Morpheus:" });
    await expect(morph).toContainText("No analysis found");
  });

  test("copy-after-edit: the copy button exports the edited spelling, not the original", async () => {
    const page = sharedPage;
    test.setTimeout(360_000);
    await page.goto(PAGE);
    await expect(page.locator("#macronize_btn")).toBeEnabled({ timeout: 240_000 });

    // Clipboard write/read requires permissions on this context.
    await page.context().grantPermissions(["clipboard-read", "clipboard-write"]);

    await macronize(page, "divisa");
    const span = page.locator("#resultText .ipa").first();
    await expect(span).toHaveAttribute("content", "dīvīsa");

    // Toggle ī → divīsa (an edit, not the dictionary spelling).
    const pt = await charCenter(page, 1);
    await page.mouse.click(pt.x, pt.y);
    await expect(span).toHaveAttribute("content", "divīsa");

    // Copy reads the RENDERED result (resultToPlainText → synced content attr).
    await page.click("#copy_btn");
    await expect(page.locator("#copy_btn")).toHaveText("Copied!", { timeout: 5000 });
    const clip = await page.evaluate(() => navigator.clipboard.readText());
    expect(clip).toContain("divīsa");
    await expect(page.locator("#copy_btn")).not.toHaveText("Copied!", { timeout: 5000 });
  });
});
