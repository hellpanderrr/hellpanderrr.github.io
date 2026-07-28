import assert from "node:assert";
import "fake-indexeddb/auto";

globalThis.document = {
  getElementById: () => ({ innerHTML: "", style: {} }),
};

const { ChunkedLexicon } = await import("../../lexicon.js");

// Letter-only synthetic words: prefetch strips non-letters (mirroring
// lookupInLexicon), so digit-bearing test words would never match.
function wordFor(i) {
  const letters = String(i)
    .padStart(6, "0")
    .replace(/\d/g, (d) => "abcdefghij"[d]);
  return "word" + letters;
}

// Build a lexicon big enough to span several chunks (1000 words per chunk)
function makeEntries(n) {
  const m = new Map();
  for (let i = 0; i < n; i++) {
    m.set(wordFor(i), "/ipa-" + i + "/");
  }
  m.set("Zürich", "/ˈtsyːrɪç/"); // non-ASCII + uppercase
  m.set("well-known", "/wɛl noʊn/"); // hyphen survives lookup cleaning
  return m;
}

describe("ChunkedLexicon", function () {
  it("memory mode serves the full map and persist() writes chunks", async function () {
    const lex = new ChunkedLexicon("TestLang");
    lex.fullMap = makeEntries(2500);
    assert.strictEqual(lex.mode, "memory");
    assert.strictEqual(lex.get(wordFor(42)), "/ipa-42/");
    assert.strictEqual(lex.get("missing"), null);

    lex.persistInBackground("testlang_v1.zip");
    await lex.persistPromise;
  });

  it("chunked mode: prefetch pulls the right chunks and get() is sync", async function () {
    const lex = new ChunkedLexicon("TestLang");
    await lex.loadChunkKeys();
    assert.ok(lex.chunkKeys.length >= 3, "should span multiple chunks");
    assert.strictEqual(lex.mode, "chunked");

    await lex.prefetch([wordFor(42), wordFor(2400), "Zürich", "well-known"]);
    assert.strictEqual(lex.get(wordFor(42)), "/ipa-42/");
    assert.strictEqual(lex.get(wordFor(2400)), "/ipa-2400/");
    assert.strictEqual(lex.get("Zürich"), "/ˈtsyːrɪç/");
    assert.strictEqual(lex.get("well-known"), "/wɛl noʊn/");
  });

  it("prefetch covers the lowercase lookup variant", async function () {
    const lex = new ChunkedLexicon("TestLang");
    await lex.loadChunkKeys();
    // Caller passes the capitalized surface form; sync code retries lowercase
    await lex.prefetch([wordFor(7).toUpperCase()]);
    assert.strictEqual(lex.get(wordFor(7)), "/ipa-7/");
  });

  it("prefetch strips punctuation like the sync lookup does", async function () {
    const lex = new ChunkedLexicon("TestLang");
    await lex.loadChunkKeys();
    await lex.prefetch([wordFor(100) + ",", "(" + wordFor(200) + ")"]);
    assert.strictEqual(lex.get(wordFor(100)), "/ipa-100/");
    assert.strictEqual(lex.get(wordFor(200)), "/ipa-200/");
  });

  it("unprefetched words miss gracefully (null, no throw)", async function () {
    const lex = new ChunkedLexicon("TestLang");
    await lex.loadChunkKeys();
    assert.strictEqual(lex.get(wordFor(500)), null);
  });

  it("languages are isolated in the shared store", async function () {
    const shared = wordFor(42);
    const other = new ChunkedLexicon("OtherLang");
    other.fullMap = new Map([[shared, "/other/"]]);
    other.persistInBackground("other_v1.zip");
    await other.persistPromise;

    const test = new ChunkedLexicon("TestLang");
    await test.loadChunkKeys();
    await test.prefetch([shared]);
    assert.strictEqual(test.get(shared), "/ipa-42/");

    const reload = new ChunkedLexicon("OtherLang");
    await reload.loadChunkKeys();
    assert.strictEqual(reload.chunkKeys.length, 1);
    await reload.prefetch([shared]);
    assert.strictEqual(reload.get(shared), "/other/");
  });
});
