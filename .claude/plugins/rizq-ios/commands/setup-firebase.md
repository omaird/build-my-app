---
description: Configure Firebase Auth and Firestore for the iOS app
argument_description: Optional flags like --emulator, --auth-only, --firestore-only
---

# Setup Firebase Command

Set up Firebase Authentication and Firestore in the RIZQ iOS app.

## Usage

```
/setup-firebase [flags]
```

## Flags

- `--emulator` - Configure for Firebase Emulator Suite
- `--auth-only` - Only set up Firebase Auth
- `--firestore-only` - Only set up Firestore
- `--check` - Verify existing Firebase configuration

## Steps

### 1. Check Prerequisites

Verify the following exist:
- `RIZQ-iOS/RIZQ/Resources/GoogleService-Info.plist`
- Firebase packages in `project.yml`
- Required entitlements for Sign in with Apple

```bash
# Check GoogleService-Info.plist
ls -la RIZQ-iOS/RIZQ/Resources/GoogleService-Info.plist

# Check project.yml has Firebase
grep -A 5 "Firebase:" RIZQ-iOS/project.yml
```

### 2. Verify GoogleService-Info.plist

Read and verify the configuration file contains:
- `CLIENT_ID` - For Google Sign-In
- `REVERSED_CLIENT_ID` - URL scheme for OAuth callback
- `PROJECT_ID` - Firebase project identifier
- `BUNDLE_ID` - Must match app bundle ID

### 3. Check URL Schemes

Verify `RIZQ-iOS/RIZQ/Info.plist` has the correct URL schemes:

```xml
<key>CFBundleURLTypes</key>
<array>
  <dict>
    <key>CFBundleURLSchemes</key>
    <array>
      <string>com.googleusercontent.apps.YOUR_CLIENT_ID</string>
    </array>
  </dict>
</array>
```

### 4. Verify Entitlements

Check `RIZQ-iOS/RIZQ/RIZQ.entitlements` for Sign in with Apple:

```xml
<key>com.apple.developer.applesignin</key>
<array>
  <string>Default</string>
</array>
```

### 5. Verify Firebase Initialization

Check `RIZQ-iOS/RIZQ/App/RIZQApp.swift`:
- `FirebaseApp.configure()` is called in init
- Emulator configuration for DEBUG builds

### 6. Verify Service Layer

Check these files exist and are properly configured:
- `RIZQKit/Services/Auth/FirebaseAuthService.swift`
- `RIZQKit/Services/Firebase/FirestoreService.swift`
- `RIZQKit/Services/Firebase/FirebaseNeonService.swift`

### 7. (If --emulator) Configure Emulator

For local development with Firebase Emulator Suite:

```bash
# Install Firebase CLI
npm install -g firebase-tools

# Initialize emulators
cd RIZQ-iOS && firebase init emulators

# Start emulators
firebase emulators:start --only auth,firestore
```

Add to `firebase.json`:
```json
{
  "emulators": {
    "auth": { "port": 9099 },
    "firestore": { "port": 8080 },
    "ui": { "enabled": true, "port": 4000 }
  }
}
```

Set environment variable before running app:
```bash
USE_FIREBASE_EMULATOR=true xcodebuild ...
```

### 8. Generate Project

Run XcodeGen to regenerate the project with new dependencies:

```bash
cd RIZQ-iOS && xcodegen generate
```

### 9. Build Verification

Attempt a build to verify configuration:

```bash
cd RIZQ-iOS && xcodebuild -scheme RIZQ -destination 'platform=iOS Simulator,name=iPhone 16' build
```

## Common Issues

### Missing GoogleService-Info.plist
Download from Firebase Console → Project Settings → Your apps → iOS

### Google Sign-In "Developer Error"
- Verify CLIENT_ID matches in Firebase Console
- Ensure bundle ID matches exactly
- Check URL scheme is reversed client ID

### Apple Sign-In Not Working
- Enable capability in Xcode project
- Configure in Apple Developer Portal
- Enable in Firebase Console → Authentication → Sign-in method

### Firestore Permission Denied
- Check security rules allow authenticated user
- Verify user is authenticated before accessing
- Ensure userId matches authenticated UID

## Output

Report setup status for each component:

```
Firebase Setup Status
═══════════════════════════════════════

✓ GoogleService-Info.plist found
✓ Firebase packages configured in project.yml
✓ URL schemes configured
✓ Sign in with Apple entitlement
✓ FirebaseApp.configure() in RIZQApp
✓ FirebaseAuthService exists
✓ FirestoreService exists
✓ FirebaseNeonService exists

Firebase is properly configured!
```

Or list any issues that need to be addressed.
