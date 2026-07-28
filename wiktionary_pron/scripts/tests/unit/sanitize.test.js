import assert from "node:assert";
import { sanitize } from "../../utils.js";

describe("sanitize", function () {
  it("strips punctuation but keeps letters", function () {
    assert.strictEqual(sanitize("Hello,"), "Hello");
    assert.strictEqual(sanitize("(word)"), "word");
    assert.strictEqual(sanitize("word!?"), "word");
  });

  it("keeps combining marks and hyphens", function () {
    assert.strictEqual(sanitize("está"), "está");
    assert.strictEqual(sanitize("well-known"), "well-known");
  });

  it("normalizes curly apostrophe to straight", function () {
    assert.strictEqual(sanitize("l’ami"), "l'ami");
  });

  it("keeps the liaison tie character", function () {
    assert.strictEqual(sanitize("les‿amis"), "les‿amis");
  });

  it("keeps Cyrillic with stress marks", function () {
    assert.strictEqual(sanitize("замо́к"), "замо́к");
  });

  it("returns empty string for pure punctuation", function () {
    assert.strictEqual(sanitize("..."), "");
    assert.strictEqual(sanitize("123"), "");
  });
});
