// Node shims for browser globals that scripts/utils.js touches at import time.
const storage = new Map();
const storageShim = {
  getItem: (k) => (storage.has(k) ? storage.get(k) : null),
  setItem: (k, v) => storage.set(k, String(v)),
  removeItem: (k) => storage.delete(k),
  clear: () => storage.clear(),
  key: (i) => [...storage.keys()][i] ?? null,
  get length() {
    return storage.size;
  },
};

if (typeof globalThis.localStorage === "undefined") {
  Object.defineProperty(globalThis, "localStorage", { value: storageShim });
}

// NOTE: do NOT shim `document` here — wasmoon's Emscripten glue uses its
// presence for environment detection and breaks under Node if it exists.
