import { test, expect, type Page } from "@playwright/test";
import {
  EMULATOR_FIRESTORE_URL,
  EMULATOR_PROJECT_ID as PROJECT_ID,
  resetEmulatorState,
  signInAsEmulatorUser,
} from "./helpers/auth";

const ADMIN_EMAIL = "admin-duas-test@example.com";
const ADMIN_NAME = "Admin Test User";

const NON_ADMIN_EMAIL = "regular-duas-test@example.com";
const NON_ADMIN_NAME = "Regular Test User";

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
 * Resolve the uid for a freshly signed-in account by scanning the Firestore
 * user_profiles collection (Bearer owner bypasses rules) for the doc whose
 * denormalized `email` field matches. The profile is written from
 * onAuthStateChanged after the post-sign-in redirect, so we poll until it
 * materializes. We use Firestore instead of the Auth `/accounts` REST endpoint
 * because that endpoint's response shape varies across emulator versions.
 */
async function findUserIdByEmail(
  page: Page,
  email: string,
): Promise<string> {
  for (let attempt = 0; attempt < 20; attempt++) {
    const docsRes = await page.request.get(
      `${EMULATOR_FIRESTORE_URL}/v1/projects/${PROJECT_ID}/databases/(default)/documents/user_profiles`,
      { headers: { Authorization: "Bearer owner" } },
    );
    if (docsRes.ok()) {
      const data = (await docsRes.json()) as {
        documents?: Array<{
          name: string;
          fields?: { email?: { stringValue?: string | null } };
        }>;
      };
      const target = email.toLowerCase();
      const match = data.documents?.find(
        (d) => d.fields?.email?.stringValue?.toLowerCase() === target,
      );
      if (match?.name) {
        // name format: projects/{pid}/databases/(default)/documents/user_profiles/{uid}
        const uid = match.name.split("/").pop();
        if (uid) return uid;
      }
    }
    await page.waitForTimeout(500);
  }
  throw new Error(`Could not find uid for ${email} after polling`);
}


test.describe("Admin Duas — Firestore write path (cutover)", () => {
  // The popup-driven sign-in flow plus Vite's first-request compile can push a
  // single test past the default 30s timeout. Give each test a roomier budget
  // so cold-start latency doesn't masquerade as a real failure.
  test.slow();

  test.beforeEach(async ({ page }) => {
    await resetEmulatorState(page);
  });

  test("admin can create a dua and it appears in the library", async ({
    page,
  }) => {
    // 1. Sign in as admin via the Google emulator popup.
    await page.goto("/signin");
    await signInAsEmulatorUser(page, {
      email: ADMIN_EMAIL,
      displayName: ADMIN_NAME,
    });

    // 2. Promote the new account to admin via REST (Bearer owner).
    const adminUid = await findUserIdByEmail(page, ADMIN_EMAIL);
    await promoteToAdmin(page, adminUid);

    // 3. Force the auth context to re-read the profile so isAdmin flips.
    await page.reload();
    await page.waitForLoadState("domcontentloaded");

    // 4. Navigate to admin duas page.
    await page.goto("/admin/duas");
    await expect(
      page.getByRole("heading", { name: /duas manager/i }),
    ).toBeVisible({ timeout: 15000 });

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
    await expect(page.getByText(uniqueTitle)).toBeVisible({ timeout: 15000 });
  });

  test("non-admin user is blocked from /admin/duas", async ({ page }) => {
    // Sign in as a regular (non-admin) user.
    await page.goto("/signin");
    await signInAsEmulatorUser(page, {
      email: NON_ADMIN_EMAIL,
      displayName: NON_ADMIN_NAME,
    });

    // Try to navigate to admin duas page.
    await page.goto("/admin/duas");
    await page.waitForLoadState("domcontentloaded");

    // Either we got redirected to the home page (most common AdminRoute
    // behavior), or the page rendered an access-denied state. Wait for one of
    // those terminal states before asserting the admin heading is absent.
    const accessDenied = page.getByText(/permission|access denied|don't have/i);
    const onHome = page.getByText(/good (morning|afternoon|evening)/i);
    await expect(accessDenied.or(onHome)).toBeVisible({ timeout: 15000 });

    await expect(
      page.getByRole("heading", { name: /duas manager/i }),
    ).not.toBeVisible();
  });

  test("admin signs out and a non-admin cannot access admin duas", async ({
    page,
    browser,
  }) => {
    // First: sign in admin and promote. We only use this leg to seed the admin
    // account + isAdmin flag — we don't actually click sign-out in the UI
    // because re-driving the popup flow inside the same browser context is
    // unreliable (Firebase Auth's IndexedDB persistence + the emulator's
    // existing-account picker can wedge `signInWithPopup` in a loading state).
    await page.goto("/signin");
    await signInAsEmulatorUser(page, {
      email: ADMIN_EMAIL,
      displayName: ADMIN_NAME,
    });
    const adminUid = await findUserIdByEmail(page, ADMIN_EMAIL);
    await promoteToAdmin(page, adminUid);

    // Open a brand-new browser context for the regular user. This is the
    // moral equivalent of "log out of this device, log in as a different
    // person" — fresh cookies, fresh storage, fresh IndexedDB.
    const newContext = await browser.newContext();
    const newPage = await newContext.newPage();
    await newPage.goto("/signin");
    await signInAsEmulatorUser(newPage, {
      email: NON_ADMIN_EMAIL,
      displayName: NON_ADMIN_NAME,
    });

    // Try to access admin duas as the non-admin user.
    await newPage.goto("/admin/duas");
    await newPage.waitForLoadState("domcontentloaded");

    const accessDenied = newPage.getByText(
      /permission|access denied|don't have/i,
    );
    const onHome = newPage.getByText(/good (morning|afternoon|evening)/i);
    await expect(accessDenied.or(onHome)).toBeVisible({ timeout: 15000 });

    await expect(
      newPage.getByRole("heading", { name: /duas manager/i }),
    ).not.toBeVisible();

    await newContext.close();
  });
});
