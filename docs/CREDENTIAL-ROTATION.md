# Credential Rotation Guide

This document describes the credentials used in the RIZQ app and how to rotate them when needed.

## When to Rotate Credentials

Rotate credentials immediately if:
- You suspect they've been exposed (committed to git, shared publicly, etc.)
- An employee with access leaves the team
- As part of regular security hygiene (every 90 days recommended)

---

## Neon PostgreSQL Credentials

**File:** `.env` → `VITE_DATABASE_URL`

### Steps to Rotate:

1. Go to [Neon Console](https://console.neon.tech)
2. Select your project → **Settings** → **Connection string**
3. Click **Reset password** to generate a new password
4. Update your local `.env`:
   ```
   VITE_DATABASE_URL=postgresql://neondb_owner:NEW_PASSWORD@ep-xxx.aws.neon.tech/neondb?sslmode=require
   ```
5. Update CI/CD secrets (GitHub Secrets, Vercel, etc.)
6. Redeploy the web app

**Impact:** Web app will lose database connectivity until updated.

---

## Firebase Service Account Key

**File:** `firebase-service-account.json`

### Steps to Rotate:

1. Go to [Firebase Console](https://console.firebase.google.com)
2. Select your project → **Project Settings** → **Service accounts**
3. Click **Generate new private key**
4. Download the new JSON file
5. Replace `firebase-service-account.json` with new file
6. **Delete the old key:** In Service accounts, click the trash icon next to old keys
7. Update CI/CD secrets if using the key there

**Impact:** Any services using the old key will fail until updated.

---

## App Store Connect API Key

**File:** `RIZQ-iOS/fastlane/api_key.json`

### Steps to Rotate:

1. Go to [App Store Connect](https://appstoreconnect.apple.com)
2. Navigate to **Users and Access** → **Keys** → **App Store Connect API**
3. Click **Generate API Key** (or revoke old one first)
4. Download the new `.p8` key file
5. Update `api_key.json`:
   ```json
   {
     "key_id": "NEW_KEY_ID",
     "issuer_id": "YOUR_ISSUER_ID",
     "key": "-----BEGIN PRIVATE KEY-----\n...\n-----END PRIVATE KEY-----"
   }
   ```
6. **Revoke old key:** Click the revoke button next to the old key
7. Update CI/CD secrets

**Note:** Convert the `.p8` file contents to a single-line string with `\n` for newlines.

**Impact:** Fastlane/TestFlight uploads will fail until updated.

---

## Firebase API Key (GoogleService-Info.plist)

**File:** `RIZQ-iOS/RIZQ/Resources/GoogleService-Info.plist`

### Important Notes:

This key is **intended to be public** for mobile apps. Firebase security is enforced through:
- Firestore Security Rules (server-side validation)
- Firebase Authentication (user identity)
- App Check (optional, prevents abuse)

### If you need to rotate:

1. Go to [Google Cloud Console](https://console.cloud.google.com)
2. Select your Firebase project
3. Navigate to **APIs & Services** → **Credentials**
4. Find the iOS API key → **Regenerate key**
5. Download new `GoogleService-Info.plist` from Firebase Console
6. Replace the file in `RIZQ-iOS/RIZQ/Resources/`
7. Rebuild the iOS app

**Impact:** Existing app installations will stop working until updated via App Store.

---

## GitHub Personal Access Token

**File:** `.auto-claude/.env` → `GITHUB_TOKEN`

### Steps to Rotate:

1. Go to [GitHub Settings](https://github.com/settings/tokens)
2. Click **Generate new token (classic)** or **Fine-grained token**
3. Set minimal required permissions:
   - `repo` (for private repos) or just `public_repo`
   - `workflow` (if using GitHub Actions)
4. Copy the new token
5. Update `.auto-claude/.env`
6. **Revoke old token:** Delete it from the tokens list

**Impact:** GitHub operations in development tools will fail until updated.

---

## Rotation Schedule Recommendation

| Credential | Frequency | Last Rotated | Next Due |
|------------|-----------|--------------|----------|
| Neon DB Password | 90 days | _________ | _________ |
| Firebase Service Account | 90 days | _________ | _________ |
| App Store Connect Key | 180 days | _________ | _________ |
| GitHub Token | 30 days | _________ | _________ |

---

## Emergency Response

If credentials are exposed publicly:

1. **Immediately rotate** all affected credentials using steps above
2. **Check access logs:**
   - Neon: Dashboard → Project → Activity
   - Firebase: Console → Project → Usage/Audit logs
   - App Store Connect: Users and Access → Activity
3. **Review for unauthorized changes:**
   - Database data integrity
   - Firebase data/config changes
   - App Store submissions
4. **Document the incident** with timeline and remediation steps

---

## CI/CD Secrets Management

Store credentials in your CI/CD platform, not in code:

### GitHub Actions
```yaml
# Reference secrets in workflow
env:
  DATABASE_URL: ${{ secrets.VITE_DATABASE_URL }}
```

### Vercel
- Project Settings → Environment Variables
- Add variables for each environment (Production, Preview, Development)

### Fastlane Match (Recommended for iOS)
- Use [Fastlane Match](https://docs.fastlane.tools/actions/match/) for certificate management
- Stores encrypted certs in private git repo or cloud storage
