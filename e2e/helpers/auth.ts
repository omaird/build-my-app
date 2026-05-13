import type { Page } from '@playwright/test';

export const EMULATOR_PROJECT_ID = 'rizq-app-c6468';
export const EMULATOR_AUTH_URL = 'http://127.0.0.1:9099';
export const EMULATOR_FIRESTORE_URL = 'http://127.0.0.1:8080';

export interface EmulatorUser {
  email: string;
  displayName: string;
}

/**
 * Wipe all auth + firestore state in the local emulator so each test starts clean.
 * No-ops gracefully if the emulator isn't running (tests that depend on the
 * emulator will fail later with a more specific error).
 */
export async function resetEmulatorState(page: Page): Promise<void> {
  await page.request.delete(
    `${EMULATOR_AUTH_URL}/emulator/v1/projects/${EMULATOR_PROJECT_ID}/accounts`
  );
  await page.request.delete(
    `${EMULATOR_FIRESTORE_URL}/emulator/v1/projects/${EMULATOR_PROJECT_ID}/databases/(default)/documents`
  );
}

/**
 * Drive the Firebase Auth emulator's Google-sign-in popup to create/sign-in as
 * a synthetic test user. Mirrors the manual flow a real user would take, so
 * `signInWithPopup(... GoogleAuthProvider)` returns a real credential and
 * `onAuthStateChanged` fires inside the app.
 *
 * Assumes the SignInPage is already on screen (popup will be opened from the
 * "Continue with Google" button).
 */
export async function signInAsEmulatorUser(
  page: Page,
  { email, displayName }: EmulatorUser
): Promise<void> {
  await runSignInPopup(page, email, displayName);

  // The post-signin handler calls `navigate('/')`, which on a cold dev server
  // forces Vite to compile the HomePage chunk for the first time. That cold
  // compile routinely costs 5-10s, on top of which the popup-to-parent
  // postMessage hop occasionally drops on the first try in the suite. If the
  // URL doesn't change within a reasonable window, reload /signin (which
  // clears the page's stuck `socialLoading` flag) and re-drive the popup once
  // — Vite is warm by then, so the retry typically completes in <2s.
  try {
    await page.waitForURL((url) => !url.pathname.includes('signin'), {
      timeout: 15_000,
    });
  } catch {
    await page.goto('/signin');
    await runSignInPopup(page, email, displayName);
    await page.waitForURL((url) => !url.pathname.includes('signin'), {
      timeout: 15_000,
    });
  }

  // Dismiss the first-run WelcomeModal so it doesn't intercept later clicks.
  await page.evaluate(() => {
    window.localStorage.setItem('rizq_welcome_shown', 'true');
  });
}

async function runSignInPopup(
  page: Page,
  email: string,
  displayName: string
): Promise<void> {
  await page
    .locator('button:has-text("Continue with Google")')
    .waitFor({ state: 'visible' });

  const popupPromise = page.waitForEvent('popup');
  await page.click('button:has-text("Continue with Google")');
  const popup = await popupPromise;
  await popup.waitForLoadState('domcontentloaded');

  // Auth emulator may show an existing-accounts list first; click "Add new
  // account" if present, then fall through to the form. Wait for EITHER the
  // accounts list (with the add-account button) OR the email input to become
  // visible — the popup chooses one of these two screens based on whether the
  // emulator's session-local account picker has any cached entries.
  const addAccountButton = popup.locator('#add-account-button');
  const emailInput = popup.locator('#email-input:visible');
  await Promise.race([
    addAccountButton.waitFor({ state: 'visible', timeout: 5_000 }).catch(() => null),
    emailInput.waitFor({ state: 'visible', timeout: 5_000 }).catch(() => null),
  ]);
  if (await addAccountButton.isVisible().catch(() => false)) {
    await addAccountButton.click();
  }

  await popup.waitForSelector('#email-input:visible');
  await popup.fill('#email-input', email);
  await popup.fill('#display-name-input', displayName);
  await popup.click('#sign-in');
}

/**
 * Seed a single Firestore document via the emulator REST API.
 *
 * Uses PATCH on the documents endpoint (Firestore REST shape) so we can pass
 * an explicit document ID. `fields` must be a plain object of primitive values
 * — they are converted to Firestore's typed-value wire format here.
 */
export async function seedFirestoreDoc(
  page: Page,
  collection: string,
  docId: string,
  fields: Record<string, string | number | boolean>
): Promise<void> {
  const wireFields: Record<string, unknown> = {};
  for (const [key, value] of Object.entries(fields)) {
    if (typeof value === 'string') {
      wireFields[key] = { stringValue: value };
    } else if (typeof value === 'boolean') {
      wireFields[key] = { booleanValue: value };
    } else if (Number.isInteger(value)) {
      wireFields[key] = { integerValue: String(value) };
    } else {
      wireFields[key] = { doubleValue: value };
    }
  }

  const url =
    `${EMULATOR_FIRESTORE_URL}/v1/projects/${EMULATOR_PROJECT_ID}` +
    `/databases/(default)/documents/${collection}/${docId}`;

  const res = await page.request.patch(url, {
    headers: { Authorization: 'Bearer owner' },
    data: { fields: wireFields },
  });

  if (!res.ok()) {
    const body = await res.text();
    throw new Error(
      `Failed to seed ${collection}/${docId}: ${res.status()} ${body}`
    );
  }
}
