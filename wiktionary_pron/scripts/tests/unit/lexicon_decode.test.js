import assert from "node:assert";

// lexicon.js calls updateLoadingText() during parsing, which touches the DOM.
// The unit-test process never loads wasmoon, so a document stub is safe here
// (unlike in setup.cjs, where it would break wasmoon's environment detection).
globalThis.document = {
  getElementById: () => ({ innerHTML: "", style: {} }),
};

const { OptimizedV3Lexicon } = await import("../../lexicon.js");

describe("OptimizedV3Lexicon prefix decoding", function () {
  it("decodes V3 format: [prefixLen, suffix, ipa]", async function () {
    const lex = new OptimizedV3Lexicon();
    const data = [
      [0, "abend", "ˈaːbn̩t"],
      [4, "ds", "ˈaːbn̩t͡s"], // "aben" + "ds" = "abends"
      [1, "rm", "aʁm"], // "a" + "rm" = "arm"
    ];
    await lex.parseV3Data(JSON.stringify(data), "German");
    assert.strictEqual(lex.get("abend"), "ˈaːbn̩t");
    assert.strictEqual(lex.get("abends"), "ˈaːbn̩t͡s");
    assert.strictEqual(lex.get("arm"), "aʁm");
    assert.strictEqual(lex.get("missing"), null);
    assert.strictEqual(lex.size(), 3);
  });

  it("decodes V4 format: integer value = stressed vowel index", async function () {
    const lex = new OptimizedV3Lexicon();
    // For Russian, value 1 means: insert U+0301 after position 1
    const data = [
      [0, "вода", 3], // вода́
      [2, "рота", 1], // во + "рота" = "ворота"? no: prefixLen=2 keeps "во", suffix "рота" → "ворота", stress idx 1 → во́рота
    ];
    await lex.parseV3Data(JSON.stringify(data), "Russian");
    assert.strictEqual(lex.get("вода"), "вода́");
    assert.strictEqual(lex.get("ворота"), "во́рота");
  });

  it("decodes V4 string values verbatim (multi-form exceptions)", async function () {
    const lex = new OptimizedV3Lexicon();
    const data = [[0, "замок", "замо́к,за́мок"]];
    await lex.parseV3Data(JSON.stringify(data), "Russian");
    assert.strictEqual(lex.get("замок"), "замо́к,за́мок");
  });

  it("parses standard dictionary format (plain object)", async function () {
    const lex = new OptimizedV3Lexicon();
    await lex.parseV3Data(JSON.stringify({ kočka: "ˈkotʃka" }), "Czech");
    assert.strictEqual(lex.get("kočka"), "ˈkotʃka");
  });
});
