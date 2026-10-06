// Same as playwright.config.js but runs on the system Chrome install, for machines
// where Playwright's bundled browser is not downloaded:
//   npx playwright test -c playwright.chrome.config.js
import base from "./playwright.config.js";

export default { ...base, use: { ...base.use, channel: "chrome" } };
