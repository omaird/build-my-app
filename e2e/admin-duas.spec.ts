import { test, expect, type Page } from "@playwright/test";

// Firebase emulator endpoints (must match playwright env wiring)
const EMULATOR_AUTH_URL = "http://127.0.0.1:9099";
const EMULATOR_FIRESTORE_URL = "http://127.0.0.1:8080";
const PROJECT_ID = "rizq-app-c6468";

const ADMIN_EMAIL = "admin-duas-test@example.com";
const ADMIN_PASSWORD = "adminpassword123";
const ADMIN_NAME = "Admin Test User";

const NON_ADMIN_EMAIL = "regular-duas-test@example.com";
const NON_ADMIN_PASSWORD = "regularpassword123";
const NON_ADMIN_NAME = "Regular Test User";

/**
 * Wipe the emulators between tests so each test has a clean slate.
 */
async function resetEmulators(page: Page) {
  await page.request.delete(
    `${EMULATOR_AUTH_URL}/emulator/v1/projects/${PROJECT_ID}/accounts`,
  );
  await page.request.delete(
    `${EMULATOR_FIRESTORE_URL}/emulator/v1/projects/${PROJECT_ID}/databases/(default)/documents`,
  );
}

/**
 * Sign up a brand-new email-password account via the UI. After signup the app
 * redirects to "/", which auto-creates the user_profiles doc.
 */
async function signUpViaUI(
  page: Page,
  email: string,
  password: string,
  name: string,
) {
  await page.goto("/signup");
  await page.waitForLoadState("networkidle");

  await page.locator("#name").fill(name);
  await page.locator("#email").fill(email);
  await page.locator("#password").fill(password);
  await page.locator("#confirmPassword").fill(password);

  await page.getByRole("button", { name: /create account/i }).click();

  // After signup, the app routes to "/" once the profile is created.
  await page.waitForURL((url) => !url.pathname.includes("signup"), {
    timeout: 15000,
  });
}

/**
 * Promote a Firestore user_profiles/{uid} doc to admin by writing isAdmin=true.
 * Uses `Bearer owner` to bypass security rules (emulator-only).
 */
async function promoteToAdmin(page: Page, uid: string) {
  const res = await page.request.patch(
    `${EMULATOR_FIRESTORE_URL}/v1/projects/${PROJECT_ID}/databases/(default)/documents/user_profiles/${uid}?updateMask.fieldPaths=isAdmin`,
    {
      headers: { Authorization: "Bearer owner" },
      data: { fields: { isAdmin: { booleanValue: true } } },
    },
  );
  if (!res.ok()) {
    throw new Error(
      `Failed to promote ${uid} to admin: ${res.status()} ${await res.text()}`,
    );
  }
}

/**
 * Read all user_profiles via `Bearer owner` (bypasses rules) so we can grab the
 * uid for the freshly signed-up account.
 */
async function findUserIdByEmail(
  page: Page,
  email: string,
): Promise<string> {
  // Try a few times — the profile is written from onAuthStateChanged after
  // redirect, so it may not be immediately visible.
  for (let attempt = 0; attempt < 10; attempt++) {
    const usersRes = await page.request.get(
      `${EMULATOR_AUTH_URL}/emulator/v1/projects/${PROJECT_ID}/accounts`,
      { headers: { Authorization: "Bearer owner" } },
    );
    if (usersRes.ok()) {
      const json = (await usersRes.json()) as {
        userInfo?: Array<{ localId: string; email: string }>;
      };
      const match = json.userInfo?.find(
        (u) => u.email?.toLowerCase() === email.toLowerCase(),
      );
      if (match?.localId) {
        // Ensure the profile doc exists too.
        const profileRes = await page.request.get(
          `${EMULATOR_FIRESTORE_URL}/v1/projects/${PROJECT_ID}/databases/(default)/documents/user_profiles/${match.localId}`,
          { headers: { Authorization: "Bearer owner" } },
        );
        if (profileRes.ok()) return match.localId;
      }
    }
    await page.waitForTimeout(500);
  }
  throw new Error(`Could not find uid for ${email} after polling`);
}

async function signOutViaUI(page: Page) {
  // The simplest reliable sign-out for tests: clear storage + reload.
  await page.context().clearCookies();
  await page.evaluate(() => {
    window.localStorage.clear();
    window.sessionStorage.clear();
  });
}

async function signInViaUI(page: Page, email: string, password: string) {
  await page.goto("/signin");
  await page.waitForLoadState("networkidle");

  await page.locator("#email").fill(email);
  await page.locator("#password").fill(password);
  await page.getByRole("button", { name: /^sign in$/i }).click();

  await page.waitForURL((url) => !url.pathname.includes("signin"), {
    timeout: 15000,
  });
}

test.describe("Admin Duas — Firestore write path (cutover)", () => {
  test.beforeEach(async ({ page }) => {
    await resetEmulators(page);
  });

  test("admin can create a dua and it appears in the library", async ({
    page,
  }) => {
    // 1. Sign up as admin.
    await signUpViaUI(page, ADMIN_EMAIL, ADMIN_PASSWORD, ADMIN_NAME);

    // 2. Promote the new account to admin via REST (Bearer owner).
    const adminUid = await findUserIdByEmail(page, ADMIN_EMAIL);
    await promoteToAdmin(page, adminUid);

    // 3. Force the auth context to re-read the profile so isAdmin flips.
    await page.reload();
    await page.waitForLoadState("networkidle");

    // 4. Navigate to admin duas page.
    await page.goto("/admin/duas");
    await expect(
      page.getByRole("heading", { name: /duas manager/i }),
    ).toBeVisible({ timeout: 10000 });

    // 5. Open the Add Dua dialog.
    await page.getByRole("button", { name: /add dua/i }).click();
    await expect(page.getByRole("dialog")).toBeVisible();

    // 6. Fill in minimum required fields.
    const uniqueTitle = `E2E Test Dua ${Date.now()}`;
    await page.getByLabel(/title \(english\)/i).fill(uniqueTitle);
    await page.getByLabel(/arabic text/i).fill("اللَّهُمَّ");
    // Repetitions and XP have number defaults; leave them.

    // 7. Submit.
    await page.getByRole("button", { name: /create dua/i }).click();

    // 8. Expect success toast.
    await expect(page.getByText(/dua created successfully/i)).toBeVisible({
      timeout: 10000,
    });

    // 9. Dua should now appear in the admin table.
    await expect(page.getByText(uniqueTitle)).toBeVisible({ timeout: 10000 });

    // 10. And in the public library page.
    await page.goto("/library");
    await page.waitForLoadState("networkidle");
    await expect(page.getByText(uniqueTitle)).toBeVisible({ timeout: 10000 });
  });

  test("non-admin user is blocked from /admin/duas", async ({ page }) => {
    // Sign up as a regular (non-admin) user.
    await signUpViaUI(page, NON_ADMIN_EMAIL, NON_ADMIN_PASSWORD, NON_ADMIN_NAME);

    // Try to navigate to admin duas page.
    await page.goto("/admin/duas");
    await page.waitForLoadState("networkidle");

    // Should NOT see the Duas Manager heading. Either redirected away or shown
    // an access-denied state.
    await expect(
      page.getByRole("heading", { name: /duas manager/i }),
    ).not.toBeVisible({ timeout: 5000 });

    // Verify an access-denied / not-admin signal is present, OR we got
    // redirected to the home page.
    const accessDenied = page.getByText(/permission|access denied|don't have/i);
    const onHome = page.getByText(/good (morning|afternoon|evening)/i);
    const accessDeniedVisible = await accessDenied
      .isVisible()
      .catch(() => false);
    const onHomeVisible = await onHome.isVisible().catch(() => false);
    expect(accessDeniedVisible || onHomeVisible).toBeTruthy();
  });

  test("admin signs out and a non-admin cannot access admin duas", async ({
    page,
  }) => {
    // First: sign up admin and promote.
    await signUpViaUI(page, ADMIN_EMAIL, ADMIN_PASSWORD, ADMIN_NAME);
    const adminUid = await findUserIdByEmail(page, ADMIN_EMAIL);
    await promoteToAdmin(page, adminUid);
    await page.reload();
    await page.waitForLoadState("networkidle");

    // Sign out.
    await signOutViaUI(page);

    // Sign up a regular user.
    await signUpViaUI(page, NON_ADMIN_EMAIL, NON_ADMIN_PASSWORD, NON_ADMIN_NAME);

    // Try to access admin duas.
    await page.goto("/admin/duas");
    await page.waitForLoadState("networkidle");

    await expect(
      page.getByRole("heading", { name: /duas manager/i }),
    ).not.toBeVisible({ timeout: 5000 });
  });
});
