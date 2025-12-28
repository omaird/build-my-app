import { test, expect } from "@playwright/test";

// Test credentials (test user)
const TEST_EMAIL = "omairdawood@gmail.com";
const TEST_PASSWORD = "omair123";

test.describe("Authentication Flow", () => {
  test.beforeEach(async ({ page }) => {
    // Clear any existing session
    await page.context().clearCookies();
    await page.goto("/signin");
    // Wait for page to fully load
    await page.waitForLoadState("networkidle");
  });

  test("should show sign-in page when not authenticated", async ({ page }) => {
    // Verify sign-in form elements are visible
    await expect(page.getByRole("heading", { name: /welcome to rizq/i })).toBeVisible();
    await expect(page.getByLabel(/email/i)).toBeVisible();
    await expect(page.getByLabel(/password/i)).toBeVisible();
    await expect(page.getByRole("button", { name: /sign in/i })).toBeVisible();
  });

  test("should show social sign-in buttons", async ({ page }) => {
    // Verify Google and GitHub buttons are visible
    await expect(page.getByRole("button", { name: /google/i })).toBeVisible();
    await expect(page.getByRole("button", { name: /github/i })).toBeVisible();
  });

  test("should sign in with email and password successfully", async ({ page }) => {
    // Fill in credentials
    await page.getByLabel(/email/i).fill(TEST_EMAIL);
    await page.getByLabel(/password/i).fill(TEST_PASSWORD);

    // Click sign in
    await page.getByRole("button", { name: /sign in/i }).click();

    // Wait for navigation to home page
    await page.waitForURL("/", { timeout: 15000 });

    // Verify we're on the home page
    await expect(page).toHaveURL("/");

    // Verify user greeting is visible (shows user is logged in)
    await expect(page.getByText(/good (morning|afternoon|evening)/i)).toBeVisible({ timeout: 10000 });
  });

  test("should show validation errors for invalid credentials", async ({ page }) => {
    // Try to sign in with wrong password
    await page.getByLabel(/email/i).fill(TEST_EMAIL);
    await page.getByLabel(/password/i).fill("wrongpassword");
    await page.getByRole("button", { name: /sign in/i }).click();

    // Should show error message (wait for toast) - use first() to avoid strict mode
    await expect(page.getByText("Sign in failed").first()).toBeVisible({ timeout: 10000 });
  });

  test("should require email and password fields", async ({ page }) => {
    // Try to sign in without credentials
    await page.getByRole("button", { name: /sign in/i }).click();

    // Should show validation error - use first() to avoid strict mode
    await expect(page.getByText(/missing fields/i).first()).toBeVisible({ timeout: 5000 });
  });
});

test.describe("Authenticated User - Settings", () => {
  // Use a shared auth state for all tests in this describe block
  test.beforeEach(async ({ page }) => {
    // Clear cookies first
    await page.context().clearCookies();

    // Sign in
    await page.goto("/signin");
    await page.waitForLoadState("networkidle");

    await page.getByLabel(/email/i).fill(TEST_EMAIL);
    await page.getByLabel(/password/i).fill(TEST_PASSWORD);
    await page.getByRole("button", { name: /sign in/i }).click();

    // Wait for successful login
    await page.waitForURL("/", { timeout: 15000 });
    await expect(page.getByText(/good (morning|afternoon|evening)/i)).toBeVisible({ timeout: 10000 });
  });

  test("should navigate to settings page", async ({ page }) => {
    // Navigate to settings
    await page.goto("/settings");
    await page.waitForLoadState("networkidle");

    // Give it a moment to settle
    await page.waitForTimeout(500);

    // Verify settings page loaded
    await expect(page.getByRole("heading", { name: /settings/i })).toBeVisible();
  });

  test("should display connected accounts section", async ({ page }) => {
    await page.goto("/settings");
    await page.waitForLoadState("networkidle");
    await page.waitForTimeout(500);

    // Verify Connected Accounts section is visible
    await expect(page.getByText("Connected Accounts")).toBeVisible();
    await expect(page.getByText(/link accounts for easier sign-in/i)).toBeVisible();
  });

  test("should show Google connect option", async ({ page }) => {
    await page.goto("/settings");
    await page.waitForLoadState("networkidle");

    // Wait for accounts to load
    await page.waitForTimeout(2000);

    // Look for Google in the connected accounts section
    await expect(page.locator("text=Google").first()).toBeVisible();
  });

  test("should show email/password as connected", async ({ page }) => {
    await page.goto("/settings");
    await page.waitForLoadState("networkidle");

    // Wait for accounts to load
    await page.waitForTimeout(2000);

    // Should show Email & Password section
    await expect(page.getByText("Email & Password")).toBeVisible();
  });

  test("should display user email in profile", async ({ page }) => {
    await page.goto("/settings");
    await page.waitForLoadState("networkidle");
    await page.waitForTimeout(500);

    // Verify user email is displayed (use first() since email appears in multiple places)
    await expect(page.getByText(TEST_EMAIL).first()).toBeVisible();
  });

  test("should have sign out button visible", async ({ page }) => {
    await page.goto("/settings");
    await page.waitForLoadState("networkidle");
    await page.waitForTimeout(500);

    // Verify sign out button is present
    await expect(page.getByRole("button", { name: /sign out/i })).toBeVisible();
  });

  test("should sign out and redirect to signin", async ({ page }) => {
    await page.goto("/settings");
    await page.waitForLoadState("networkidle");
    await page.waitForTimeout(500);

    // Click sign out
    await page.getByRole("button", { name: /sign out/i }).click();

    // Should redirect to sign-in page
    await page.waitForURL(/.*signin/, { timeout: 10000 });
    await expect(page).toHaveURL(/.*signin/);
  });
});

test.describe("Last Used Provider Indicator", () => {
  test("should show last used indicator after email sign-in", async ({ page }) => {
    // Clear everything
    await page.context().clearCookies();

    // Sign in with email
    await page.goto("/signin");
    await page.waitForLoadState("networkidle");

    await page.getByLabel(/email/i).fill(TEST_EMAIL);
    await page.getByLabel(/password/i).fill(TEST_PASSWORD);
    await page.getByRole("button", { name: /sign in/i }).click();
    await page.waitForURL("/", { timeout: 15000 });

    // Wait for home page to fully load
    await expect(page.getByText(/good (morning|afternoon|evening)/i)).toBeVisible({ timeout: 10000 });

    // Navigate to settings using the avatar click (more reliable)
    await page.locator("a[href='/settings']").first().click();
    await page.waitForURL("/settings", { timeout: 10000 });
    await page.waitForLoadState("networkidle");

    // Sign out
    await page.getByRole("button", { name: /sign out/i }).click();
    await page.waitForURL(/.*signin/, { timeout: 10000 });

    // Wait for page to stabilize
    await page.waitForLoadState("networkidle");

    // Now verify the "last used" indicator is shown for email
    await expect(page.getByText(/you last signed in with email/i)).toBeVisible({ timeout: 5000 });
  });
});

test.describe("Protected Routes", () => {
  test("should redirect unauthenticated users to signin", async ({ page }) => {
    // Clear cookies to ensure not logged in
    await page.context().clearCookies();

    // Try to access a protected route directly
    await page.goto("/library");
    await page.waitForLoadState("networkidle");

    // Should be redirected to signin
    await expect(page).toHaveURL(/.*signin/);
  });

  test("should allow authenticated users to access protected routes", async ({ page }) => {
    // Clear and sign in
    await page.context().clearCookies();
    await page.goto("/signin");
    await page.waitForLoadState("networkidle");

    await page.getByLabel(/email/i).fill(TEST_EMAIL);
    await page.getByLabel(/password/i).fill(TEST_PASSWORD);
    await page.getByRole("button", { name: /sign in/i }).click();
    await page.waitForURL("/", { timeout: 15000 });

    // Wait for home page to be fully loaded
    await expect(page.getByText(/good (morning|afternoon|evening)/i)).toBeVisible({ timeout: 10000 });

    // Now access library via navigation
    await page.locator("a[href='/library']").first().click();
    await page.waitForURL("/library", { timeout: 10000 });
    await expect(page).toHaveURL("/library");

    // And settings via avatar
    await page.locator("a[href='/settings']").first().click();
    await page.waitForURL("/settings", { timeout: 10000 });
    await expect(page).toHaveURL("/settings");
  });
});
