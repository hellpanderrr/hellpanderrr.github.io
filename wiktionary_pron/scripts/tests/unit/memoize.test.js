import assert from "node:assert";
import { memoizeLocalStorage } from "../../utils.js";

describe("memoizeLocalStorage", function () {
  beforeEach(function () {
    localStorage.clear();
  });

  it("rejects anonymous functions", function () {
    assert.throws(() => memoizeLocalStorage((x) => x));
  });

  it("caches sync results (miss returns a Promise; hit returns the value)", async function () {
    let calls = 0;
    function counterFn(x) {
      calls++;
      return x * 2;
    }
    const memo = memoizeLocalStorage(counterFn, { ttl: 60000 });
    // Cache miss goes through an async path even for sync functions.
    assert.strictEqual(await memo(21), 42);
    // Cache hit of a sync function returns the bare value.
    assert.strictEqual(memo(21), 42);
    assert.strictEqual(calls, 1);
  });

  it("caches async results and returns a promise on hit", async function () {
    let calls = 0;
    async function asyncFn(x) {
      calls++;
      return x + 1;
    }
    const memo = memoizeLocalStorage(asyncFn, { ttl: 60000 });
    assert.strictEqual(await memo(1), 2);
    const second = memo(1);
    assert.ok(second instanceof Promise, "cache hit should stay a promise");
    assert.strictEqual(await second, 2);
    assert.strictEqual(calls, 1);
  });

  it("distinguishes different arguments", async function () {
    function ident(x, y) {
      return `${x}:${y}`;
    }
    const memo = memoizeLocalStorage(ident, { ttl: 60000 });
    assert.strictEqual(await memo("a", "1"), "a:1");
    assert.strictEqual(await memo("a", "2"), "a:2");
  });

  it("re-executes after ttl expiry", async function () {
    let calls = 0;
    function shortLived() {
      calls++;
      return calls;
    }
    const memo = memoizeLocalStorage(shortLived, { ttl: 1 });
    memo();
    await new Promise((r) => setTimeout(r, 10));
    memo();
    assert.strictEqual(calls, 2);
  });

  it("persists cache to localStorage under the function name", function () {
    function persisted(x) {
      return x;
    }
    const memo = memoizeLocalStorage(persisted, { ttl: 60000 });
    memo("v");
    const stored = JSON.parse(localStorage.getItem("persisted"));
    assert.ok(stored.persisted, "cache object keyed by fn name");
  });
});
