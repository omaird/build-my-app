import { test, expect } from '@playwright/test';

const EMULATOR_AUTH_URL = 'http://127.0.0.1:9099';
const EMULATOR_FIRESTORE_URL = 'http://127.0.0.1:8080';

test.describe('Firebase Auth flow', () => {
  test.beforeEach(async ({ page }) => {
    // Reset emulator state
    await page.request.delete(
      `${EMULATOR_AUTH_URL}/emulator/v1/projects/rizq-app-c6468/accounts`
    );
    await page.request.delete(
      `${EMULATOR_FIRESTORE_URL}/emulator/v1/projects/rizq-app-c6468/databases/(default)/documents`
    );
  });

  test('signing in with Google creates a user_profiles doc', async ({ page }) => {
    await page.goto('/');
    await page.click('text=Sign In');

    const popupPromise = page.waitForEvent('popup');
    await page.click('button:has-text("Continue with Google")');
    const popup = await popupPromise;
    await popup.waitForLoadState('domcontentloaded');

    // Auth emulator may show an existing-accounts list first; click "Add new
    // account" if present, then fall through to the form.
    const addAccountButton = popup.locator('#add-account-button');
    if (await addAccountButton.isVisible({ timeout: 1000 }).catch(() => false)) {
      await addAccountButton.click();
    }

    await popup.waitForSelector('#email-input');
    await popup.fill('#email-input', 'newuser@example.com');
    await popup.fill('#display-name-input', 'New User');
    await popup.click('#sign-in');

    await page.waitForURL((url) => !url.pathname.includes('signin'), { timeout: 10000 });

    // Bearer owner bypasses security rules — necessary because rules disallow
    // listing user_profiles (only the owner can read their own doc).
    // Poll because the profile write fires from onAuthStateChanged after the
    // redirect, so it may not be visible the instant the URL changes.
    await expect
      .poll(
        async () => {
          const res = await page.request.get(
            `${EMULATOR_FIRESTORE_URL}/v1/projects/rizq-app-c6468/databases/(default)/documents/user_profiles`,
            { headers: { Authorization: 'Bearer owner' } }
          );
          const data = await res.json();
          return data.documents?.length ?? 0;
        },
        { timeout: 5000 }
      )
      .toBe(1);
  });
});
