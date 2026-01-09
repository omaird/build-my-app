#!/usr/bin/env node

/**
 * Add a single dua to Firebase Firestore
 *
 * Usage: node scripts/add-dua.cjs <dua-file.json>
 *
 * The JSON file should contain a dua object with these fields:
 * - id (required): Unique integer ID
 * - categoryId (required): Category (1=morning, 2=evening, 3=rizq, 4=gratitude)
 * - titleEn (required): English title
 * - arabicText (required): Full Arabic text
 * - transliteration (required): Romanized Arabic
 * - translationEn (required): English translation
 * - source (required): Hadith/Quran reference
 * - And optional fields: titleAr, repetitions, bestTime, difficulty, xpValue, etc.
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
    console.error('Please download it from Firebase Console > Project Settings > Service Accounts');
    process.exit(1);
  }
}

const db = admin.firestore();

// Validation functions
function hasArabicText(text) {
  return /[\u0600-\u06FF]/.test(text);
}

function calculateXp(dua) {
  let xp = 15; // base

  // Length bonus
  const arabicLen = dua.arabicText.length;
  if (arabicLen > 150) xp += 10;
  else if (arabicLen > 50) xp += 5;

  // Repetition bonus
  xp += Math.min(((dua.repetitions || 1) - 1) * 5, 20);

  // Difficulty bonus
  if (dua.difficulty === 'intermediate') xp += 10;
  if (dua.difficulty === 'advanced') xp += 20;

  return Math.min(xp, 100);
}

async function checkDuplicates(dua) {
  // Check by ID
  const idDoc = await db.collection('duas').doc(String(dua.id)).get();
  if (idDoc.exists) {
    return { type: 'id', value: dua.id };
  }

  // Check by title
  const titleQuery = await db.collection('duas')
    .where('titleEn', '==', dua.titleEn)
    .limit(1)
    .get();
  if (!titleQuery.empty) {
    return { type: 'title', value: dua.titleEn };
  }

  return null;
}

function validateDua(dua) {
  const errors = [];

  // Required fields
  if (!dua.id) errors.push('Missing required field: id');
  if (!dua.titleEn) errors.push('Missing required field: titleEn');
  if (!dua.arabicText) errors.push('Missing required field: arabicText');
  if (!dua.translationEn) errors.push('Missing required field: translationEn');
  if (!dua.transliteration) errors.push('Missing required field: transliteration');
  if (!dua.source) errors.push('Missing required field: source');
  if (!dua.categoryId) errors.push('Missing required field: categoryId');

  // Arabic text validation
  if (dua.arabicText && !hasArabicText(dua.arabicText)) {
    errors.push('arabicText does not contain Arabic characters');
  }

  // Category validation
  if (dua.categoryId && ![1, 2, 3, 4].includes(dua.categoryId)) {
    errors.push('categoryId must be 1 (morning), 2 (evening), 3 (rizq), or 4 (gratitude)');
  }

  // XP validation
  if (dua.xpValue && (dua.xpValue < 15 || dua.xpValue > 100)) {
    errors.push('xpValue must be between 15 and 100');
  }

  return errors;
}

async function addDua(dua) {
  // Validate
  const errors = validateDua(dua);
  if (errors.length > 0) {
    console.error('\n❌ Validation errors:');
    errors.forEach(e => console.error(`  - ${e}`));
    process.exit(1);
  }

  // Check for duplicates
  const duplicate = await checkDuplicates(dua);
  if (duplicate) {
    console.error(`\n❌ Duplicate found: ${duplicate.type} = ${duplicate.value}`);
    process.exit(1);
  }

  // Calculate XP if not provided
  if (!dua.xpValue) {
    dua.xpValue = calculateXp(dua);
    console.log(`Calculated XP value: ${dua.xpValue}`);
  }

  // Set defaults
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

  // Add optional fields if provided
  if (dua.titleAr) docData.titleAr = dua.titleAr;
  if (dua.collectionId) docData.collectionId = dua.collectionId;
  if (dua.bestTime) docData.bestTime = dua.bestTime;
  if (dua.estDurationSec) docData.estDurationSec = dua.estDurationSec;
  if (dua.rizqBenefit) docData.rizqBenefit = dua.rizqBenefit;
  if (dua.propheticContext) docData.propheticContext = dua.propheticContext;
  if (dua.audioUrl) docData.audioUrl = dua.audioUrl;

  // Add to Firestore
  const docRef = db.collection('duas').doc(String(dua.id));
  await docRef.set(docData);

  return docRef.id;
}

async function main() {
  const args = process.argv.slice(2);

  if (args.length === 0) {
    console.log('Usage: node scripts/add-dua.cjs <dua-file.json>');
    console.log('\nExample JSON file:');
    console.log(JSON.stringify({
      id: 11,
      categoryId: 3,
      titleEn: "Dua for Barakah",
      arabicText: "اللَّهُمَّ بَارِكْ لِي",
      transliteration: "Allahumma barik li",
      translationEn: "O Allah, bless me",
      source: "General Dua",
      repetitions: 1,
      difficulty: "beginner"
    }, null, 2));
    process.exit(1);
  }

  const jsonPath = args[0];
  if (!fs.existsSync(jsonPath)) {
    console.error(`Error: File not found: ${jsonPath}`);
    process.exit(1);
  }

  let dua;
  try {
    dua = JSON.parse(fs.readFileSync(jsonPath, 'utf8'));
  } catch (e) {
    console.error(`Error parsing JSON: ${e.message}`);
    process.exit(1);
  }

  console.log('='.repeat(50));
  console.log('Adding Dua to Firebase');
  console.log('='.repeat(50));
  console.log(`\nTitle: ${dua.titleEn}`);
  console.log(`ID: ${dua.id}`);
  console.log(`Category: ${dua.categoryId}`);

  try {
    const docId = await addDua(dua);
    console.log('\n' + '='.repeat(50));
    console.log('✅ DUA ADDED SUCCESSFULLY!');
    console.log('='.repeat(50));
    console.log(`\nDocument ID: ${docId}`);
    console.log(`Collection: duas`);
    console.log(`\nView in Firebase Console:`);
    console.log(`https://console.firebase.google.com/project/rizq-app-c6468/firestore/data/duas/${docId}`);
  } catch (error) {
    console.error('\n❌ Error adding dua:', error.message);
    process.exit(1);
  }

  process.exit(0);
}

main();
