import { test, expect } from '@playwright/test';
import {
  resetEmulatorState,
  seedFirestoreDoc,
  signInAsEmulatorUser,
} from './helpers/auth';

test.describe('Journey subscription -> Daily Adkhar', () => {
  test.beforeEach(async ({ page }) => {
    await resetEmulatorState(page);

    // Seed iOS-shape content (camelCase fields, matches scripts/seed-firestore.cjs).
    // One dua, one journey, one journey_duas assignment is enough to verify the
    // subscribe flow surfaces a habit on /daily-adkhar.
    await seedFirestoreDoc(page, 'duas', '1', {
      id: 1,
      categoryId: 1,
      titleEn: 'Morning Dhikr',
      titleAr: 'أذكار الصباح',
      arabicText: 'أَصْبَحْنَا وَأَصْبَحَ الْمُلْكُ لِلَّهِ',
      transliteration: 'Asbahna wa asbahal-mulku lillah',
      translationEn: 'We have entered the morning and so has the dominion of Allah.',
      source: 'Abu Dawud 5071',
      repetitions: 1,
      bestTime: 'After Fajr',
      difficulty: 'beginner',
      xpValue: 15,
    });

    await seedFirestoreDoc(page, 'journeys', '1', {
      id: 1,
      name: 'Morning Warrior',
      slug: 'morning-warrior',
      description: 'Start your day with powerful duas.',
      emoji: '🌅',
      estimatedMinutes: 5,
      dailyXp: 15,
      isPremium: false,
      isFeatured: true,
      sortOrder: 0,
    });

    await seedFirestoreDoc(page, 'journey_duas', '1_1', {
      journeyId: 1,
      duaId: 1,
      timeSlot: 'morning',
      sortOrder: 1,
    });
  });

  test('subscribing to a journey surfaces its dua as a habit on /adkhar', async ({
    page,
  }) => {
    await page.goto('/signin');
    await signInAsEmulatorUser(page, {
      email: 'journeytester@example.com',
      displayName: 'Journey Tester',
    });

    // Browse to the journey, open detail, and subscribe.
    await page.goto('/journeys');
    await page.click('text=Morning Warrior');
    await page.click(
      'button:has-text("Start This Journey"), button:has-text("Add to My Journeys")'
    );

    // The subscribe action navigates home; explicitly walk to the adkhar page.
    await page.goto('/adkhar');

    // The seeded dua should appear as a habit in the morning slot.
    await expect(page.getByText('Morning Dhikr')).toBeVisible({ timeout: 20_000 });
  });
});
