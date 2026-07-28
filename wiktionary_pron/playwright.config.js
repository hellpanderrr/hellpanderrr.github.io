import { defineConfig } from "@playwright/test";

export default defineConfig({
  testDir: "./e2e",
  timeout: 120_000,
  expect: { timeout: 60_000 },
  retries: 1,
  workers: 1, // serial: each test boots a Lua VM in the page; parallel runs thrash CI
  use: {
    baseURL: "http://127.0.0.1:8993",
    trace: "retain-on-failure",
  },
  webServer: {
    // Serve the repo root (parent dir) — the Lua require shim fetches
    // ../wiktionary_pron/lua_modules/... relative to the page URL.
    command: "npx http-server .. -p 8993 -s -c-1",
    url: "http://127.0.0.1:8993/wiktionary_pron/index.html",
    reuseExistingServer: true,
    timeout: 30_000,
  },
});
