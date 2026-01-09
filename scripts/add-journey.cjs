#!/usr/bin/env node

/**
 * Add a journey with its dua mappings to Firebase Firestore
 *
 * Usage: node scripts/add-journey.cjs <journey-file.json>
 *
 * The JSON file should contain:
 * {
 *   "journey": { ... journey object ... },
 *   "journeyDuas": [ ... array of journey-dua mappings ... ]
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

function validateJourney(journey) {
  const errors = [];

  if (!journey.id) errors.push('Missing required field: id');
  if (!journey.name) errors.push('Missing required field: name');
  if (!journey.slug) errors.push('Missing required field: slug');
  if (!journey.description) errors.push('Missing required field: description');
  if (!journey.emoji) errors.push('Missing required field: emoji');

  // Slug validation
  if (journey.slug && !/^[a-z0-9-]+$/.test(journey.slug)) {
    errors.push('slug must be lowercase alphanumeric with hyphens only');
  }

  return errors;
}

function validateJourneyDua(jd, index) {
  const errors = [];

  if (!jd.journeyId) errors.push(`journeyDuas[${index}]: Missing journeyId`);
  if (!jd.duaId) errors.push(`journeyDuas[${index}]: Missing duaId`);
  if (!jd.timeSlot) errors.push(`journeyDuas[${index}]: Missing timeSlot`);
  if (jd.timeSlot && !['morning', 'anytime', 'evening'].includes(jd.timeSlot)) {
    errors.push(`journeyDuas[${index}]: Invalid timeSlot (must be morning/anytime/evening)`);
  }

  return errors;
}

async function checkDuplicates(journey) {
  // Check by ID
  const idDoc = await db.collection('journeys').doc(String(journey.id)).get();
  if (idDoc.exists) {
    return { type: 'id', value: journey.id };
  }

  // Check by slug
  const slugQuery = await db.collection('journeys')
    .where('slug', '==', journey.slug)
    .limit(1)
    .get();
  if (!slugQuery.empty) {
    return { type: 'slug', value: journey.slug };
  }

  return null;
}

async function verifyDuasExist(duaIds) {
  const missing = [];
  for (const duaId of duaIds) {
    const doc = await db.collection('duas').doc(String(duaId)).get();
    if (!doc.exists) {
      missing.push(duaId);
    }
  }
  return missing;
}

async function addJourney(data) {
  const { journey, journeyDuas } = data;

  // Validate journey
  const journeyErrors = validateJourney(journey);
  if (journeyErrors.length > 0) {
    console.error('\n❌ Journey validation errors:');
    journeyErrors.forEach(e => console.error(`  - ${e}`));
    process.exit(1);
  }

  // Validate journey duas
  const jdErrors = [];
  journeyDuas.forEach((jd, i) => {
    jdErrors.push(...validateJourneyDua(jd, i));
  });
  if (jdErrors.length > 0) {
    console.error('\n❌ Journey duas validation errors:');
    jdErrors.forEach(e => console.error(`  - ${e}`));
    process.exit(1);
  }

  // Check for duplicates
  const duplicate = await checkDuplicates(journey);
  if (duplicate) {
    console.error(`\n❌ Duplicate found: ${duplicate.type} = ${duplicate.value}`);
    process.exit(1);
  }

  // Verify all referenced duas exist
  const duaIds = [...new Set(journeyDuas.map(jd => jd.duaId))];
  const missingDuas = await verifyDuasExist(duaIds);
  if (missingDuas.length > 0) {
    console.error(`\n❌ Referenced duas not found: ${missingDuas.join(', ')}`);
    process.exit(1);
  }

  // Create journey document
  const journeyDoc = {
    id: journey.id,
    name: journey.name,
    slug: journey.slug,
    description: journey.description,
    emoji: journey.emoji,
    estimatedMinutes: journey.estimatedMinutes || 10,
    dailyXp: journey.dailyXp || 100,
    isPremium: journey.isPremium || false,
    isFeatured: journey.isFeatured || false,
    sortOrder: journey.sortOrder || 0,
    createdAt: admin.firestore.FieldValue.serverTimestamp(),
    updatedAt: admin.firestore.FieldValue.serverTimestamp()
  };

  // Use batch write for atomicity
  const batch = db.batch();

  // Add journey
  const journeyRef = db.collection('journeys').doc(String(journey.id));
  batch.set(journeyRef, journeyDoc);
  console.log(`  + journeys/${journey.id}`);

  // Add journey duas
  for (const jd of journeyDuas) {
    const docId = `${jd.journeyId}_${jd.duaId}`;
    const jdRef = db.collection('journey_duas').doc(docId);
    batch.set(jdRef, {
      journeyId: jd.journeyId,
      duaId: jd.duaId,
      timeSlot: jd.timeSlot,
      sortOrder: jd.sortOrder || 0,
      createdAt: admin.firestore.FieldValue.serverTimestamp()
    });
    console.log(`  + journey_duas/${docId}`);
  }

  // Commit batch
  await batch.commit();

  return {
    journeyId: journey.id,
    journeyDuasCount: journeyDuas.length
  };
}

async function main() {
  const args = process.argv.slice(2);

  if (args.length === 0) {
    console.log('Usage: node scripts/add-journey.cjs <journey-file.json>');
    console.log('\nExample JSON file:');
    console.log(JSON.stringify({
      journey: {
        id: 6,
        name: "Barakah Builder",
        slug: "barakah-builder",
        description: "Invoke divine blessings into all aspects of your life.",
        emoji: "✨",
        estimatedMinutes: 12,
        dailyXp: 180,
        isPremium: false,
        isFeatured: true,
        sortOrder: 5
      },
      journeyDuas: [
        { journeyId: 6, duaId: 3, timeSlot: "morning", sortOrder: 1 },
        { journeyId: 6, duaId: 7, timeSlot: "anytime", sortOrder: 2 },
        { journeyId: 6, duaId: 9, timeSlot: "evening", sortOrder: 3 }
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

  if (!data.journey || !data.journeyDuas) {
    console.error('Error: JSON must contain "journey" and "journeyDuas" keys');
    process.exit(1);
  }

  console.log('='.repeat(50));
  console.log('Adding Journey to Firebase');
  console.log('='.repeat(50));
  console.log(`\nJourney: ${data.journey.emoji} ${data.journey.name}`);
  console.log(`ID: ${data.journey.id}`);
  console.log(`Duas: ${data.journeyDuas.length}`);
  console.log('\nCreating documents:');

  try {
    const result = await addJourney(data);
    console.log('\n' + '='.repeat(50));
    console.log('✅ JOURNEY ADDED SUCCESSFULLY!');
    console.log('='.repeat(50));
    console.log(`\nJourney ID: ${result.journeyId}`);
    console.log(`Journey Duas Added: ${result.journeyDuasCount}`);
    console.log(`\nView in Firebase Console:`);
    console.log(`https://console.firebase.google.com/project/rizq-app-c6468/firestore/data/journeys/${result.journeyId}`);
  } catch (error) {
    console.error('\n❌ Error adding journey:', error.message);
    process.exit(1);
  }

  process.exit(0);
}

main();
