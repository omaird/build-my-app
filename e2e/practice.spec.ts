import { test, expect } from '@playwright/test';

const EMULATOR_AUTH_URL = 'http://127.0.0.1:9099';
const EMULATOR_FIRESTORE_URL = 'http://127.0.0.1:8080';
const PROJECT_ID = 'rizq-app-c6468';

// Seed a single Firestore document using the REST API. The emulator accepts
// writes with `Bearer owner`, bypassing security rules — this is the same
// pattern the auth.spec.ts test uses to read user_profiles.
async function seedFirestoreDocument(
  request: import('@playwright/test').APIRequestContext,
  path: string,
  fields: Record<string, unknown>
) {
  const url = `${EMULATOR_FIRESTORE_URL}/v1/projects/${PROJECT_ID}/databases/(default)/documents/${path}`;
  const res = await request.patch(url, {
    headers: { Authorization: 'Bearer owner' },
    data: { fields },
  });
  if (!res.ok()) {
    throw new Error(
      `Failed to seed ${path}: ${res.status()} ${await res.text()}`
    );
  }
}

test.describe('Library page reads from Firestore', () => {
  test.beforeEach(async ({ page }) => {
    // Reset emulator state (mirror auth.spec.ts).
    await page.request.delete(
      `${EMULATOR_AUTH_URL}/emulator/v1/projects/${PROJECT_ID}/accounts`
    );
    await page.request.delete(
      `${EMULATOR_FIRESTORE_URL}/emulator/v1/projects/${PROJECT_ID}/databases/(default)/documents`
    );

    // Seed a realistic category (slug must match category-slug enum).
    await seedFirestoreDocument(page.request, 'categories/1', {
      id: { integerValue: '1' },
      name: { stringValue: 'Morning' },
      slug: { stringValue: 'morning' },
    });

    // Seed a realistic dua with every field the read-path consumes.
    await seedFirestoreDocument(page.request, 'duas/1', {
      id: { integerValue: '1' },
      titleEn: { stringValue: 'Test Morning Dua' },
      arabicText: {
        stringValue:
          'أَصْبَحْنَا وَأَصْبَحَ الْمُلْكُ لِلَّهِ',
      },
      transliteration: { stringValue: 'Asbahna wa asbahal-mulku lillah' },
      translationEn: {
        stringValue: 'We have entered the morning and so has the dominion of Allah',
      },
      categoryId: { integerValue: '1' },
      collectionId: { integerValue: '1' },
      source: { stringValue: 'Abu Dawud 5071' },
      repetitions: { integerValue: '1' },
      bestTime: { stringValue: 'After Fajr' },
      difficulty: { stringValue: 'beginner' },
      rizqBenefit: { stringValue: 'Start your day acknowledging Allah' },
      xpValue: { integerValue: '15' },
    });
  });

  test('authenticated user sees seeded dua on /library when cutover is enabled', async ({
    page,
  }) => {
    // Sign-in flow inlined from auth.spec.ts. We deliberately don't extract this
    // into e2e/helpers/auth.ts because Task 3.3 (running in a parallel worktree)
    // is creating that helper — sharing the file would conflict at merge time.
    await page.goto('/');
    await page.click('text=Sign In');

    const popupPromise = page.waitForEvent('popup');
    await page.click('button:has-text("Continue with Google")');
    const popup = await popupPromise;
    await popup.waitForLoadState('domcontentloaded');

    const addAccountButton = popup.locator('#add-account-button');
    if (
      await addAccountButton.isVisible({ timeout: 1000 }).catch(() => false)
    ) {
      await addAccountButton.click();
    }

    await popup.waitForSelector('#email-input');
    await popup.fill('#email-input', 'librarytester@example.com');
    await popup.fill('#display-name-input', 'Library Tester');
    await popup.click('#sign-in');

    await page.waitForURL((url) => !url.pathname.includes('signin'), {
      timeout: 10000,
    });

    // Navigate to the library and assert the seeded dua renders.
    await page.goto('/library');
    await expect(page.locator('text=Test Morning Dua')).toBeVisible({
      timeout: 10000,
    });
  });
});
