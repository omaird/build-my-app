import { test, expect } from '@playwright/test';

test('user can browse duas in Library page (read from Firestore)', async ({ page }) => {
  // Seed: insert a dua via the emulator REST API
  await page.request.patch(
    'http://127.0.0.1:8080/emulator/v1/projects/rizq-app-c6468/databases/(default)/documents/duas/1',
    { data: { fields: { titleEn: { stringValue: 'Test Morning Dua' } } } }
  );

  await page.goto('/library');
  await expect(page.locator('text=Test Morning Dua')).toBeVisible({ timeout: 5000 });
});
