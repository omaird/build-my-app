#!/usr/bin/env node

/**
 * Set admin rights for a user in Firestore
 *
 * Usage:
 * 1. Download service account key from Firebase Console:
 *    Project Settings > Service Accounts > Generate new private key
 * 2. Save it as scripts/service-account-key.json
 * 3. Run: node scripts/set-admin.cjs <userId>
 *
 * Example: node scripts/set-admin.cjs txe0udnuu9bQODZ8kxpRyOilA083
 */

const admin = require('firebase-admin');
const path = require('path');
const fs = require('fs');

const userId = process.argv[2];

if (!userId) {
  console.error('Usage: node scripts/set-admin.cjs <userId>');
  console.error('Example: node scripts/set-admin.cjs txe0udnuu9bQODZ8kxpRyOilA083');
  process.exit(1);
}

// Initialize Firebase Admin
const serviceAccountPath = process.env.GOOGLE_APPLICATION_CREDENTIALS ||
  path.join(__dirname, 'service-account-key.json');

if (!fs.existsSync(serviceAccountPath)) {
  console.error('Service account key not found at:', serviceAccountPath);
  console.error('Download from: https://console.firebase.google.com/project/rizq-app-c6468/settings/serviceaccounts/adminsdk');
  process.exit(1);
}

const serviceAccount = require(serviceAccountPath);
admin.initializeApp({
  credential: admin.credential.cert(serviceAccount)
});

const db = admin.firestore();

async function setAdmin() {
  try {
    await db.collection('user_profiles').doc(userId).update({
      isAdmin: true,
      updatedAt: admin.firestore.FieldValue.serverTimestamp()
    });
    console.log('✅ Admin rights granted to user:', userId);
    process.exit(0);
  } catch (error) {
    console.error('❌ Error setting admin:', error.message);
    process.exit(1);
  }
}

setAdmin();
