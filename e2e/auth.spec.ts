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
    await popup.waitForLoadState();
    await popup.fill('input[type="email"]', 'newuser@example.com');
    await popup.fill('input[type="text"]', 'New User');
    await popup.click('button:has-text("Sign in with Google.com")');

    await page.waitForURL((url) => !url.pathname.includes('signin'), { timeout: 10000 });

    const dbResponse = await page.request.get(
      `${EMULATOR_FIRESTORE_URL}/emulator/v1/projects/rizq-app-c6468/databases/(default)/documents/user_profiles`
    );
    const docs = await dbResponse.json();
    expect(docs.documents).toBeDefined();
    expect(docs.documents.length).toBe(1);
  });
});
