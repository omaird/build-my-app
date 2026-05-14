import { defineConfig, devices } from "@playwright/test";

export default defineConfig({
  testDir: "./e2e",
  globalSetup: "./e2e/global-setup.ts",
  fullyParallel: true,
  forbidOnly: !!process.env.CI,
  retries: process.env.CI ? 2 : 0,
  workers: process.env.CI ? 1 : undefined,
  reporter: "html",
  timeout: 60000,
  use: {
    baseURL: "http://localhost:8081",
    trace: "on-first-retry",
    screenshot: "only-on-failure",
  },
  projects: [
    {
      name: "chromium",
      use: { ...devices["Desktop Chrome"] },
    },
  ],
  webServer: {
    command: "npm run dev",
    url: "http://localhost:8081",
    reuseExistingServer: true,
    timeout: 30000,
    env: {
      VITE_USE_FIREBASE_EMULATORS: "true",
      VITE_FIREBASE_API_KEY: "demo-api-key",
      VITE_FIREBASE_AUTH_DOMAIN: "rizq-app-c6468.firebaseapp.com",
      VITE_FIREBASE_PROJECT_ID: "rizq-app-c6468",
      VITE_FIREBASE_STORAGE_BUCKET: "rizq-app-c6468.appspot.com",
      VITE_FIREBASE_MESSAGING_SENDER_ID: "demo-sender-id",
      VITE_FIREBASE_APP_ID: "demo-app-id",
    },
  },
});
