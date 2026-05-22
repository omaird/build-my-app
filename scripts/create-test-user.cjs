#!/usr/bin/env node

/**
 * Create a Firebase Auth user (test/dev accounts) via the Admin SDK.
 *
 * Usage:
 *   node scripts/create-test-user.cjs <email> <password> [displayName]
 *
 * Example:
 *   node scripts/create-test-user.cjs omair@razzaq.app Rizq-Test-2026 "Omair Test"
 *
 * Notes:
 *   - Service account key must exist at scripts/service-account-key.json
 *     (or be pointed to via GOOGLE_APPLICATION_CREDENTIALS).
 *   - The Firestore user_profiles doc is auto-created on first sign-in by
 *     AuthContext.getOrCreateProfile — this script intentionally does NOT
 *     write to Firestore to avoid drift with that source of truth.
 */

const admin = require('firebase-admin');
const path = require('path');
const fs = require('fs');

const [, , email, password, displayName] = process.argv;

if (!email || !password) {
  console.error('Usage: node scripts/create-test-user.cjs <email> <password> [displayName]');
  process.exit(1);
}

const serviceAccountPath =
  process.env.GOOGLE_APPLICATION_CREDENTIALS ||
  path.join(__dirname, 'service-account-key.json');

if (!fs.existsSync(serviceAccountPath)) {
  console.error('Service account key not found at:', serviceAccountPath);
  console.error(
    'Download from: https://console.firebase.google.com/project/rizq-app-c6468/settings/serviceaccounts/adminsdk'
  );
  process.exit(1);
}

const serviceAccount = require(serviceAccountPath);
admin.initializeApp({ credential: admin.credential.cert(serviceAccount) });

async function main() {
  try {
    const userRecord = await admin.auth().createUser({
      email,
      password,
      displayName: displayName || undefined,
      emailVerified: true,
    });
    console.log('✅ Created user');
    console.log('   UID:        ', userRecord.uid);
    console.log('   Email:      ', userRecord.email);
    console.log('   DisplayName:', userRecord.displayName ?? '(none)');
    console.log('');
    console.log('Sign in at /signin with email + password.');
    console.log('To grant admin: node scripts/set-admin.cjs', userRecord.uid);
    process.exit(0);
  } catch (error) {
    if (error.code === 'auth/email-already-exists') {
      const existing = await admin.auth().getUserByEmail(email);
      console.error('⚠️  User already exists with this email');
      console.error('   UID:  ', existing.uid);
      console.error('   Email:', existing.email);
      console.error('');
      console.error('To reset the password instead:');
      console.error(`   firebase auth:import or use the Firebase Console`);
      process.exit(2);
    }
    console.error('❌ Error:', error.message);
    process.exit(1);
  }
}

main();
