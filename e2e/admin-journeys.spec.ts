import { test, expect } from "@playwright/test";

// Test credentials (admin user)
const TEST_EMAIL = "omairdawood@gmail.com";
const TEST_PASSWORD = "omair123";

// Helper function to generate unique test journey names
const generateTestJourneyName = () => `Test Journey ${Date.now()}`;

// TODO(M1-Step5): rewrite for Firebase Auth emulator + Firestore-seeded admin user.
// These tests were written for Better Auth (email/password) and the Neon-backed
// admin flow. Both have been replaced (Step 2 auth cutover, Step 3 firestore
// cutover). The new admin coverage lives in e2e/admin-duas.spec.ts.
test.describe.skip("Admin Journeys Management", () => {
  test.beforeEach(async ({ page }) => {
    // Clear any existing session
    await page.context().clearCookies();

    // Sign in as admin
    await page.goto("/signin");
    await page.waitForLoadState("networkidle");

    await page.getByLabel(/email/i).fill(TEST_EMAIL);
    await page.getByLabel(/password/i).fill(TEST_PASSWORD);
    await page.getByRole("button", { name: /sign in/i }).click();

    // Wait for successful login
    await page.waitForURL("/", { timeout: 15000 });
    await expect(page.getByText(/good (morning|afternoon|evening)/i)).toBeVisible({ timeout: 10000 });

    // Navigate to admin journeys page
    await page.goto("/admin/journeys");
    await page.waitForLoadState("networkidle");
  });

  test("should display journeys manager page", async ({ page }) => {
    // Verify page header is visible
    await expect(page.getByRole("heading", { name: /journeys manager/i })).toBeVisible();

    // Verify Add Journey button is visible
    await expect(page.getByRole("button", { name: /add journey/i })).toBeVisible();

    // Verify search input is visible
    await expect(page.getByPlaceholder(/search journeys/i)).toBeVisible();
  });

  test("should display journeys table with headers", async ({ page }) => {
    // Wait for table to load
    await page.waitForTimeout(1000);

    // Verify table headers
    await expect(page.getByRole("columnheader", { name: /journey/i })).toBeVisible();
    await expect(page.getByRole("columnheader", { name: /duas/i })).toBeVisible();
    await expect(page.getByRole("columnheader", { name: /duration/i })).toBeVisible();
    await expect(page.getByRole("columnheader", { name: /daily xp/i })).toBeVisible();
    await expect(page.getByRole("columnheader", { name: /featured/i })).toBeVisible();
    await expect(page.getByRole("columnheader", { name: /premium/i })).toBeVisible();
  });

  test("should search journeys by name", async ({ page }) => {
    // Wait for journeys to load
    await page.waitForTimeout(1000);

    // Type in search box
    const searchInput = page.getByPlaceholder(/search journeys/i);
    await searchInput.fill("morning");

    // Wait for filter to apply
    await page.waitForTimeout(500);

    // Verify filtered results (if Morning journey exists, it should be visible)
    // If no results, verify empty state message
    const table = page.getByRole("table");
    const emptyState = page.getByText(/no journeys match/i);

    // Either should be true
    const hasResults = await table.isVisible().catch(() => false);
    const hasEmptyState = await emptyState.isVisible().catch(() => false);

    expect(hasResults || hasEmptyState).toBeTruthy();
  });

  test("should open create journey dialog", async ({ page }) => {
    // Click Add Journey button
    await page.getByRole("button", { name: /add journey/i }).click();

    // Wait for dialog to appear
    await page.waitForTimeout(500);

    // Verify dialog is open
    await expect(page.getByRole("dialog")).toBeVisible();
    await expect(page.getByRole("heading", { name: /create new journey/i })).toBeVisible();

    // Verify form fields are present
    await expect(page.getByLabel(/journey name/i)).toBeVisible();
    await expect(page.getByLabel(/slug/i)).toBeVisible();
    await expect(page.getByLabel(/description/i)).toBeVisible();
    await expect(page.getByLabel(/est\. duration/i)).toBeVisible();
    await expect(page.getByLabel(/daily xp/i)).toBeVisible();

    // Verify submit button
    await expect(page.getByRole("button", { name: /create journey/i })).toBeVisible();
  });

  test("should create a new journey", async ({ page }) => {
    const journeyName = generateTestJourneyName();

    // Click Add Journey button
    await page.getByRole("button", { name: /add journey/i }).click();
    await page.waitForTimeout(500);

    // Fill in the form
    await page.getByLabel(/journey name/i).fill(journeyName);
    await page.getByLabel(/description/i).fill("A test journey for E2E testing");

    // Scroll down to see submit button if needed
    await page.getByRole("button", { name: /create journey/i }).scrollIntoViewIfNeeded();

    // Submit the form
    await page.getByRole("button", { name: /create journey/i }).click();

    // Wait for success message
    await expect(page.getByText(/journey created/i)).toBeVisible({ timeout: 10000 });

    // Verify dialog closed
    await expect(page.getByRole("dialog")).not.toBeVisible({ timeout: 5000 });

    // Verify journey appears in the list
    await expect(page.getByText(journeyName)).toBeVisible({ timeout: 5000 });
  });

  test("should show validation errors for invalid journey", async ({ page }) => {
    // Click Add Journey button
    await page.getByRole("button", { name: /add journey/i }).click();
    await page.waitForTimeout(500);

    // Try to submit with empty name
    await page.getByRole("button", { name: /create journey/i }).click();

    // Should show validation error
    await expect(page.getByText(/name must be at least 3 characters/i)).toBeVisible({ timeout: 5000 });
  });

  test("should open edit journey dialog", async ({ page }) => {
    // Wait for journeys to load
    await page.waitForTimeout(1000);

    // Find the first journey row's menu button
    const menuButton = page.locator("table tbody tr").first().getByRole("button");
    await menuButton.click();

    // Wait for dropdown menu
    await page.waitForTimeout(300);

    // Click Edit option
    await page.getByRole("menuitem", { name: /edit/i }).click();

    // Verify edit dialog opened
    await expect(page.getByRole("dialog")).toBeVisible();
    await expect(page.getByRole("heading", { name: /edit journey/i })).toBeVisible();

    // Verify form is populated (name field should have a value)
    const nameInput = page.getByLabel(/journey name/i);
    await expect(nameInput).not.toHaveValue("");
  });

  test("should show delete confirmation dialog", async ({ page }) => {
    // Wait for journeys to load
    await page.waitForTimeout(1000);

    // Find the first journey row's menu button
    const menuButton = page.locator("table tbody tr").first().getByRole("button");
    await menuButton.click();

    // Wait for dropdown menu
    await page.waitForTimeout(300);

    // Click Delete option
    await page.getByRole("menuitem", { name: /delete/i }).click();

    // Verify confirmation dialog appears
    await expect(page.getByRole("alertdialog")).toBeVisible();
    await expect(page.getByText(/delete journey/i)).toBeVisible();
    await expect(page.getByText(/are you sure/i)).toBeVisible();

    // Verify Cancel and Delete buttons
    await expect(page.getByRole("button", { name: /cancel/i })).toBeVisible();
    await expect(page.getByRole("button", { name: /delete/i })).toBeVisible();

    // Click cancel to close
    await page.getByRole("button", { name: /cancel/i }).click();
    await expect(page.getByRole("alertdialog")).not.toBeVisible();
  });

  test("should toggle featured status", async ({ page }) => {
    // Wait for journeys to load
    await page.waitForTimeout(1000);

    // Find the featured toggle in the first row
    const firstRow = page.locator("table tbody tr").first();
    const featuredToggle = firstRow.locator("role=switch").first();

    // Get initial state
    const initialChecked = await featuredToggle.isChecked();

    // Click to toggle
    await featuredToggle.click();

    // Wait for update
    await page.waitForTimeout(1000);

    // Verify toast appears (success message)
    await expect(
      page.getByText(initialChecked ? /removed from featured/i : /added to featured/i)
    ).toBeVisible({ timeout: 5000 });
  });
});

// TODO(M1-Step5): rewrite for Firebase Auth emulator + Firestore-seeded admin user.
// These tests were written for Better Auth (email/password) and the Neon-backed
// admin flow. Both have been replaced (Step 2 auth cutover, Step 3 firestore
// cutover). The new admin coverage lives in e2e/admin-duas.spec.ts.
test.describe.skip("Admin Journey-Dua Assignment", () => {
  test.beforeEach(async ({ page }) => {
    // Clear any existing session
    await page.context().clearCookies();

    // Sign in as admin
    await page.goto("/signin");
    await page.waitForLoadState("networkidle");

    await page.getByLabel(/email/i).fill(TEST_EMAIL);
    await page.getByLabel(/password/i).fill(TEST_PASSWORD);
    await page.getByRole("button", { name: /sign in/i }).click();

    // Wait for successful login
    await page.waitForURL("/", { timeout: 15000 });
    await expect(page.getByText(/good (morning|afternoon|evening)/i)).toBeVisible({ timeout: 10000 });

    // Navigate to admin journeys page first
    await page.goto("/admin/journeys");
    await page.waitForLoadState("networkidle");
  });

  test("should navigate to journey duas manager from dropdown", async ({ page }) => {
    // Wait for journeys to load
    await page.waitForTimeout(1000);

    // Find the first journey row's menu button
    const menuButton = page.locator("table tbody tr").first().getByRole("button");
    await menuButton.click();

    // Wait for dropdown menu
    await page.waitForTimeout(300);

    // Click "Manage Duas" option
    await page.getByRole("menuitem", { name: /manage duas/i }).click();

    // Wait for navigation
    await page.waitForURL(/\/admin\/journeys\/\d+\/duas/, { timeout: 10000 });

    // Verify we're on the journey duas page
    await expect(page.getByText(/assigned duas/i)).toBeVisible({ timeout: 5000 });
  });

  test("should display journey duas manager page", async ({ page }) => {
    // Navigate directly to first journey's duas page
    // First, get a journey ID from the journeys list
    await page.waitForTimeout(1000);

    // Find the first journey row's menu button and click Manage Duas
    const menuButton = page.locator("table tbody tr").first().getByRole("button");
    await menuButton.click();
    await page.waitForTimeout(300);
    await page.getByRole("menuitem", { name: /manage duas/i }).click();

    // Wait for page load
    await page.waitForURL(/\/admin\/journeys\/\d+\/duas/, { timeout: 10000 });
    await page.waitForLoadState("networkidle");

    // Verify page elements
    await expect(page.getByRole("button", { name: /add dua/i })).toBeVisible();
    await expect(page.getByText(/assigned duas/i)).toBeVisible();

    // Back button should be visible
    await expect(page.locator("a[href='/admin/journeys']")).toBeVisible();
  });

  test("should show add dua dialog", async ({ page }) => {
    // Navigate to journey duas page
    await page.waitForTimeout(1000);
    const menuButton = page.locator("table tbody tr").first().getByRole("button");
    await menuButton.click();
    await page.waitForTimeout(300);
    await page.getByRole("menuitem", { name: /manage duas/i }).click();
    await page.waitForURL(/\/admin\/journeys\/\d+\/duas/, { timeout: 10000 });

    // Click Add Dua button
    await page.getByRole("button", { name: /add dua/i }).click();

    // Wait for dialog
    await page.waitForTimeout(500);

    // Verify dialog elements
    await expect(page.getByRole("dialog")).toBeVisible();
    await expect(page.getByRole("heading", { name: /add dua to journey/i })).toBeVisible();

    // Verify dua selector is present
    await expect(page.getByText(/select a dua/i)).toBeVisible();

    // Verify time slot selector is present
    await expect(page.getByText(/time slot/i)).toBeVisible();
  });

  test("should display time slot options in add dialog", async ({ page }) => {
    // Navigate to journey duas page
    await page.waitForTimeout(1000);
    const menuButton = page.locator("table tbody tr").first().getByRole("button");
    await menuButton.click();
    await page.waitForTimeout(300);
    await page.getByRole("menuitem", { name: /manage duas/i }).click();
    await page.waitForURL(/\/admin\/journeys\/\d+\/duas/, { timeout: 10000 });

    // Click Add Dua button
    await page.getByRole("button", { name: /add dua/i }).click();
    await page.waitForTimeout(500);

    // Click time slot dropdown
    const timeSlotTrigger = page.locator("text=Time Slot").locator("..").getByRole("combobox");
    await timeSlotTrigger.click();

    // Verify time slot options
    await expect(page.getByRole("option", { name: /morning/i })).toBeVisible();
    await expect(page.getByRole("option", { name: /anytime/i })).toBeVisible();
    await expect(page.getByRole("option", { name: /evening/i })).toBeVisible();
  });

  test("should navigate back to journeys list", async ({ page }) => {
    // Navigate to journey duas page
    await page.waitForTimeout(1000);
    const menuButton = page.locator("table tbody tr").first().getByRole("button");
    await menuButton.click();
    await page.waitForTimeout(300);
    await page.getByRole("menuitem", { name: /manage duas/i }).click();
    await page.waitForURL(/\/admin\/journeys\/\d+\/duas/, { timeout: 10000 });

    // Click back button
    await page.locator("a[href='/admin/journeys']").click();

    // Verify we're back on journeys list
    await page.waitForURL("/admin/journeys", { timeout: 10000 });
    await expect(page.getByRole("heading", { name: /journeys manager/i })).toBeVisible();
  });

  test("should show assigned duas in table", async ({ page }) => {
    // Navigate to journey duas page
    await page.waitForTimeout(1000);
    const menuButton = page.locator("table tbody tr").first().getByRole("button");
    await menuButton.click();
    await page.waitForTimeout(300);
    await page.getByRole("menuitem", { name: /manage duas/i }).click();
    await page.waitForURL(/\/admin\/journeys\/\d+\/duas/, { timeout: 10000 });
    await page.waitForLoadState("networkidle");

    // Wait for content to load
    await page.waitForTimeout(1000);

    // Check if we have assigned duas (table visible) or empty state
    const table = page.locator("table");
    const emptyState = page.getByText(/no duas assigned/i);

    const hasTable = await table.isVisible().catch(() => false);
    const hasEmptyState = await emptyState.isVisible().catch(() => false);

    // Either should be true depending on journey content
    expect(hasTable || hasEmptyState).toBeTruthy();

    // If table is visible, verify headers
    if (hasTable) {
      await expect(page.getByRole("columnheader", { name: /dua/i })).toBeVisible();
      await expect(page.getByRole("columnheader", { name: /time slot/i })).toBeVisible();
      await expect(page.getByRole("columnheader", { name: /xp/i })).toBeVisible();
    }
  });

  test("should change time slot for assigned dua", async ({ page }) => {
    // Navigate to journey duas page
    await page.waitForTimeout(1000);
    const menuButton = page.locator("table tbody tr").first().getByRole("button");
    await menuButton.click();
    await page.waitForTimeout(300);
    await page.getByRole("menuitem", { name: /manage duas/i }).click();
    await page.waitForURL(/\/admin\/journeys\/\d+\/duas/, { timeout: 10000 });
    await page.waitForLoadState("networkidle");
    await page.waitForTimeout(1000);

    // Check if there are assigned duas
    const tableRow = page.locator("table tbody tr").first();
    const hasRows = await tableRow.isVisible().catch(() => false);

    if (hasRows) {
      // Find the time slot dropdown in the first row
      const timeSlotSelect = tableRow.getByRole("combobox");
      await timeSlotSelect.click();

      // Select a different time slot
      await page.getByRole("option", { name: /evening/i }).click();

      // Wait for update
      await page.waitForTimeout(1000);

      // Should show success message
      await expect(page.getByText(/time slot updated/i)).toBeVisible({ timeout: 5000 });
    } else {
      // Skip if no duas assigned - test passes
      test.skip();
    }
  });

  test("should show remove confirmation for assigned dua", async ({ page }) => {
    // Navigate to journey duas page
    await page.waitForTimeout(1000);
    const menuButton = page.locator("table tbody tr").first().getByRole("button");
    await menuButton.click();
    await page.waitForTimeout(300);
    await page.getByRole("menuitem", { name: /manage duas/i }).click();
    await page.waitForURL(/\/admin\/journeys\/\d+\/duas/, { timeout: 10000 });
    await page.waitForLoadState("networkidle");
    await page.waitForTimeout(1000);

    // Check if there are assigned duas
    const tableRow = page.locator("table tbody tr").first();
    const hasRows = await tableRow.isVisible().catch(() => false);

    if (hasRows) {
      // Find and click the remove button (trash icon)
      const removeButton = tableRow.getByRole("button").filter({ hasText: "" });
      // Try clicking the last button in the row (usually the delete button)
      await tableRow.locator("button").last().click();

      // Verify confirmation dialog appears
      await expect(page.getByRole("alertdialog")).toBeVisible({ timeout: 5000 });
      await expect(page.getByText(/remove dua from journey/i)).toBeVisible();

      // Cancel to close
      await page.getByRole("button", { name: /cancel/i }).click();
      await expect(page.getByRole("alertdialog")).not.toBeVisible();
    } else {
      // Skip if no duas assigned - test passes
      test.skip();
    }
  });
});

// TODO(M1-Step5): rewrite for Firebase Auth emulator + Firestore-seeded admin user.
// These tests were written for Better Auth (email/password) and the Neon-backed
// admin flow. Both have been replaced (Step 2 auth cutover, Step 3 firestore
// cutover). The new admin coverage lives in e2e/admin-duas.spec.ts.
test.describe.skip("Admin Journeys - Error Handling", () => {
  test.beforeEach(async ({ page }) => {
    // Clear any existing session
    await page.context().clearCookies();

    // Sign in as admin
    await page.goto("/signin");
    await page.waitForLoadState("networkidle");

    await page.getByLabel(/email/i).fill(TEST_EMAIL);
    await page.getByLabel(/password/i).fill(TEST_PASSWORD);
    await page.getByRole("button", { name: /sign in/i }).click();

    await page.waitForURL("/", { timeout: 15000 });
  });

  test("should handle loading states gracefully", async ({ page }) => {
    // Navigate to journeys page
    await page.goto("/admin/journeys");

    // Should show loading skeleton initially or data
    // Wait for either loading skeleton or table to appear
    await page.waitForTimeout(500);

    // Verify page eventually loads successfully
    await expect(page.getByRole("heading", { name: /journeys manager/i })).toBeVisible({ timeout: 10000 });
  });

  test("should show admin page for authenticated admin user", async ({ page }) => {
    await page.goto("/admin/journeys");
    await page.waitForLoadState("networkidle");

    // If user is admin, should see the page
    // If not admin, might redirect - either way, verify we're somewhere valid
    const isOnAdminPage = await page.getByRole("heading", { name: /journeys manager/i }).isVisible().catch(() => false);
    const isOnHomePage = await page.getByText(/good (morning|afternoon|evening)/i).isVisible().catch(() => false);

    // Should be on either admin page (if admin) or redirected (if not admin)
    expect(isOnAdminPage || isOnHomePage).toBeTruthy();
  });
});
