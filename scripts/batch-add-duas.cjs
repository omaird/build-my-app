#!/usr/bin/env node

/**
 * Batch add multiple duas to Firebase Firestore
 *
 * Usage: node scripts/batch-add-duas.cjs <duas-file.json>
 *
 * The JSON file should contain:
 * {
 *   "duas": [ ... array of dua objects ... ]
 * }
 */

const admin = require('firebase-admin');
const path = require('path');
const fs = require('fs');

// Initialize Firebase Admin
const serviceAccountPath = process.env.GOOGLE_APPLICATION_CREDENTIALS ||
  path.join(__dirname, 'service-account-key.json');

if (!admin.apps.length) {
  if (fs.existsSync(serviceAccountPath)) {
    const serviceAccount = require(serviceAccountPath);
    admin.initializeApp({
      credential: admin.credential.cert(serviceAccount)
    });
  } else {
    console.error('Error: Service account key not found at:', serviceAccountPath);
    process.exit(1);
  }
}

const db = admin.firestore();

function hasArabicText(text) {
  return /[\u0600-\u06FF]/.test(text);
}

function calculateXp(dua) {
  let xp = 15;
  const arabicLen = dua.arabicText.length;
  if (arabicLen > 150) xp += 10;
  else if (arabicLen > 50) xp += 5;
  xp += Math.min(((dua.repetitions || 1) - 1) * 5, 20);
  if (dua.difficulty === 'intermediate') xp += 10;
  if (dua.difficulty === 'advanced') xp += 20;
  return Math.min(xp, 100);
}

function validateDua(dua, index) {
  const errors = [];
  const prefix = `duas[${index}]`;

  if (!dua.id) errors.push(`${prefix}: Missing id`);
  if (!dua.titleEn) errors.push(`${prefix}: Missing titleEn`);
  if (!dua.arabicText) errors.push(`${prefix}: Missing arabicText`);
  if (!dua.translationEn) errors.push(`${prefix}: Missing translationEn`);
  if (!dua.transliteration) errors.push(`${prefix}: Missing transliteration`);
  if (!dua.source) errors.push(`${prefix}: Missing source`);
  if (!dua.categoryId) errors.push(`${prefix}: Missing categoryId`);

  if (dua.arabicText && !hasArabicText(dua.arabicText)) {
    errors.push(`${prefix}: arabicText has no Arabic characters`);
  }

  if (dua.categoryId && ![1, 2, 3, 4].includes(dua.categoryId)) {
    errors.push(`${prefix}: Invalid categoryId`);
  }

  return errors;
}

async function getExistingIds() {
  const snapshot = await db.collection('duas').get();
  return new Set(snapshot.docs.map(doc => parseInt(doc.id)));
}

async function getExistingTitles() {
  const snapshot = await db.collection('duas').get();
  return new Set(snapshot.docs.map(doc => doc.data().titleEn));
}

async function batchAddDuas(duas) {
  // Validate all duas first
  const allErrors = [];
  duas.forEach((dua, i) => {
    allErrors.push(...validateDua(dua, i));
  });

  if (allErrors.length > 0) {
    console.error('\n❌ Validation errors:');
    allErrors.forEach(e => console.error(`  - ${e}`));
    process.exit(1);
  }

  // Check for duplicates
  const existingIds = await getExistingIds();
  const existingTitles = await getExistingTitles();

  const duplicateIds = duas.filter(d => existingIds.has(d.id));
  const duplicateTitles = duas.filter(d => existingTitles.has(d.titleEn));

  if (duplicateIds.length > 0) {
    console.warn(`\n⚠️ Skipping ${duplicateIds.length} duas with existing IDs: ${duplicateIds.map(d => d.id).join(', ')}`);
  }

  if (duplicateTitles.length > 0) {
    console.warn(`\n⚠️ Skipping ${duplicateTitles.length} duas with existing titles`);
  }

  // Filter out duplicates
  const newDuas = duas.filter(d =>
    !existingIds.has(d.id) && !existingTitles.has(d.titleEn)
  );

  if (newDuas.length === 0) {
    console.log('\nNo new duas to add (all were duplicates)');
    return { added: 0, skipped: duas.length };
  }

  console.log(`\nAdding ${newDuas.length} new duas...`);

  // Firestore batch limit is 500
  const BATCH_SIZE = 500;
  let addedCount = 0;

  for (let i = 0; i < newDuas.length; i += BATCH_SIZE) {
    const batchDuas = newDuas.slice(i, i + BATCH_SIZE);
    const batch = db.batch();

    for (const dua of batchDuas) {
      // Calculate XP if not provided
      if (!dua.xpValue) {
        dua.xpValue = calculateXp(dua);
      }

      const docData = {
        id: dua.id,
        categoryId: dua.categoryId,
        titleEn: dua.titleEn,
        arabicText: dua.arabicText,
        transliteration: dua.transliteration,
        translationEn: dua.translationEn,
        source: dua.source,
        repetitions: dua.repetitions || 1,
        difficulty: dua.difficulty || 'beginner',
        xpValue: dua.xpValue,
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
        updatedAt: admin.firestore.FieldValue.serverTimestamp()
      };

      // Add optional fields
      if (dua.titleAr) docData.titleAr = dua.titleAr;
      if (dua.collectionId) docData.collectionId = dua.collectionId;
      if (dua.bestTime) docData.bestTime = dua.bestTime;
      if (dua.estDurationSec) docData.estDurationSec = dua.estDurationSec;
      if (dua.rizqBenefit) docData.rizqBenefit = dua.rizqBenefit;
      if (dua.propheticContext) docData.propheticContext = dua.propheticContext;
      if (dua.audioUrl) docData.audioUrl = dua.audioUrl;

      const docRef = db.collection('duas').doc(String(dua.id));
      batch.set(docRef, docData);
      console.log(`  + duas/${dua.id} - ${dua.titleEn}`);
    }

    await batch.commit();
    addedCount += batchDuas.length;
    console.log(`  Batch ${Math.floor(i / BATCH_SIZE) + 1} committed (${batchDuas.length} docs)`);
  }

  return {
    added: addedCount,
    skipped: duas.length - addedCount
  };
}

async function main() {
  const args = process.argv.slice(2);

  if (args.length === 0) {
    console.log('Usage: node scripts/batch-add-duas.cjs <duas-file.json>');
    console.log('\nExample JSON file:');
    console.log(JSON.stringify({
      duas: [
        {
          id: 11,
          categoryId: 3,
          titleEn: "Dua 1",
          arabicText: "Arabic...",
          transliteration: "...",
          translationEn: "Translation...",
          source: "Sahih Muslim 123"
        },
        {
          id: 12,
          categoryId: 1,
          titleEn: "Dua 2",
          arabicText: "Arabic...",
          transliteration: "...",
          translationEn: "Translation...",
          source: "Bukhari 456"
        }
      ]
    }, null, 2));
    process.exit(1);
  }

  const jsonPath = args[0];
  if (!fs.existsSync(jsonPath)) {
    console.error(`Error: File not found: ${jsonPath}`);
    process.exit(1);
  }

  let data;
  try {
    data = JSON.parse(fs.readFileSync(jsonPath, 'utf8'));
  } catch (e) {
    console.error(`Error parsing JSON: ${e.message}`);
    process.exit(1);
  }

  if (!data.duas || !Array.isArray(data.duas)) {
    console.error('Error: JSON must contain "duas" array');
    process.exit(1);
  }

  console.log('='.repeat(50));
  console.log('Batch Adding Duas to Firebase');
  console.log('='.repeat(50));
  console.log(`\nTotal duas in file: ${data.duas.length}`);

  try {
    const result = await batchAddDuas(data.duas);
    console.log('\n' + '='.repeat(50));
    console.log('✅ BATCH ADD COMPLETE!');
    console.log('='.repeat(50));
    console.log(`\nAdded: ${result.added}`);
    console.log(`Skipped: ${result.skipped}`);
    console.log(`\nView in Firebase Console:`);
    console.log(`https://console.firebase.google.com/project/rizq-app-c6468/firestore/data/duas`);
  } catch (error) {
    console.error('\n❌ Error in batch add:', error.message);
    process.exit(1);
  }

  process.exit(0);
}

main();
