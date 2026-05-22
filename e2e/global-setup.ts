import { chromium, type FullConfig } from "@playwright/test";

/**
 * Pre-warm the Vite dev server by hitting the routes the test suite uses.
 * Vite compiles route chunks on first request — without this warm-up the
 * first sign-in test routinely blows past its 25s URL-wait budget.
 */
export default async function globalSetup(config: FullConfig) {
  const baseURL = config.projects[0]?.use?.baseURL ?? "http://localhost:8081";
  const browser = await chromium.launch();
  const page = await browser.newPage();
  try {
    for (const path of ["/", "/signin", "/journeys", "/library", "/adkhar", "/admin/duas"]) {
      await page.goto(`${baseURL}${path}`, { waitUntil: "networkidle", timeout: 60_000 });
    }
  } finally {
    await browser.close();
  }
}
