# Firebase Configuration Best Practices

This skill provides best practices for configuring Firebase in iOS applications.

## When to Use This Skill

Use this skill when:
- Setting up Firebase in a new iOS project
- Configuring authentication providers
- Setting up URL schemes and entitlements
- Configuring Firebase emulator for development
- Troubleshooting configuration issues

## Project Setup

### 1. Add Firebase SDK to project.yml (XcodeGen)

```yaml
packages:
  Firebase:
    url: https://github.com/firebase/firebase-ios-sdk
    from: "11.0.0"
  GoogleSignIn:
    url: https://github.com/google/GoogleSignIn-iOS
    from: "8.0.0"

targets:
  YourApp:
    dependencies:
      - package: Firebase
        product: FirebaseAuth
      - package: Firebase
        product: FirebaseFirestore
      - package: GoogleSignIn
        product: GoogleSignIn
```

### 2. Add GoogleService-Info.plist

1. Download from Firebase Console > Project Settings > Your apps > iOS
2. Place in `YourApp/Resources/GoogleService-Info.plist`
3. Add to resources in project.yml:
```yaml
resources:
  - path: YourApp/Resources
```

### 3. Initialize Firebase

```swift
import SwiftUI
import FirebaseCore

@main
struct YourApp: App {
  init() {
    FirebaseApp.configure()
  }

  var body: some Scene {
    WindowGroup {
      ContentView()
    }
  }
}
```

## URL Schemes Configuration

### For Google Sign-In

Add reversed client ID from GoogleService-Info.plist:

**Info.plist:**
```xml
<key>CFBundleURLTypes</key>
<array>
  <dict>
    <key>CFBundleTypeRole</key>
    <string>Editor</string>
    <key>CFBundleURLSchemes</key>
    <array>
      <string>com.googleusercontent.apps.YOUR_CLIENT_ID</string>
    </array>
  </dict>
</array>
```

**project.yml alternative:**
```yaml
targets:
  YourApp:
    info:
      properties:
        CFBundleURLTypes:
          - CFBundleTypeRole: Editor
            CFBundleURLSchemes:
              - com.googleusercontent.apps.YOUR_CLIENT_ID
```

### For Custom OAuth Callback

```yaml
targets:
  YourApp:
    info:
      properties:
        CFBundleURLTypes:
          - CFBundleTypeRole: Editor
            CFBundleURLSchemes:
              - yourapp  # For yourapp://auth/callback
```

## Entitlements Configuration

### Sign in with Apple

**YourApp.entitlements:**
```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>com.apple.developer.applesignin</key>
  <array>
    <string>Default</string>
  </array>
</dict>
</plist>
```

### Associated Domains (for Universal Links)

```xml
<key>com.apple.developer.associated-domains</key>
<array>
  <string>applinks:yourapp.page.link</string>
</array>
```

## Firebase Configuration Struct

```swift
public struct FirebaseConfiguration: Sendable {
  public let projectId: String
  public let useEmulator: Bool
  public let emulatorHost: String
  public let authEmulatorPort: Int
  public let firestoreEmulatorPort: Int

  public init(
    projectId: String,
    useEmulator: Bool = false,
    emulatorHost: String = "localhost",
    authEmulatorPort: Int = 9099,
    firestoreEmulatorPort: Int = 8080
  ) {
    self.projectId = projectId
    self.useEmulator = useEmulator
    self.emulatorHost = emulatorHost
    self.authEmulatorPort = authEmulatorPort
    self.firestoreEmulatorPort = firestoreEmulatorPort
  }
}
```

## Emulator Configuration

### Local Development Setup

```swift
import FirebaseAuth
import FirebaseFirestore

func configureForEmulator() {
  #if DEBUG
  let useEmulator = ProcessInfo.processInfo.environment["USE_FIREBASE_EMULATOR"] == "true"
  if useEmulator {
    // Auth emulator
    Auth.auth().useEmulator(withHost: "localhost", port: 9099)

    // Firestore emulator
    let settings = Firestore.firestore().settings
    settings.host = "localhost:8080"
    settings.isSSLEnabled = false
    Firestore.firestore().settings = settings
  }
  #endif
}
```

### Running Firebase Emulators

```bash
# Install Firebase CLI
npm install -g firebase-tools

# Initialize project (if not done)
firebase init emulators

# Start emulators
firebase emulators:start --only auth,firestore

# Or with export on shutdown
firebase emulators:start --only auth,firestore --export-on-exit=./emulator-data --import=./emulator-data
```

### firebase.json for Emulators

```json
{
  "emulators": {
    "auth": {
      "port": 9099
    },
    "firestore": {
      "port": 8080
    },
    "ui": {
      "enabled": true,
      "port": 4000
    }
  }
}
```

## Environment-Based Configuration

```swift
public static func fromEnvironment() -> AppConfiguration? {
  // Check for Firebase config (via GoogleService-Info.plist)
  if Bundle.main.path(forResource: "GoogleService-Info", ofType: "plist") != nil {
    let useEmulator = ProcessInfo.processInfo.environment["USE_FIREBASE_EMULATOR"] == "true"
    let projectId = ProcessInfo.processInfo.environment["FIREBASE_PROJECT_ID"] ?? "your-project-id"
    return AppConfiguration(firebase: FirebaseConfiguration(projectId: projectId, useEmulator: useEmulator))
  }
  return nil
}
```

## Security Best Practices

### 1. Never commit GoogleService-Info.plist with sensitive data

Add to `.gitignore`:
```
**/GoogleService-Info.plist
```

Use CI/CD to inject the file:
```yaml
# GitHub Actions example
- name: Create GoogleService-Info.plist
  run: echo "${{ secrets.GOOGLE_SERVICE_INFO_PLIST }}" | base64 --decode > YourApp/Resources/GoogleService-Info.plist
```

### 2. Use App Check for API protection

```swift
import FirebaseAppCheck

// In app initialization
let providerFactory = AppCheckDebugProviderFactory()
AppCheck.setAppCheckProviderFactory(providerFactory)
```

### 3. Disable analytics in debug builds

```swift
#if DEBUG
Analytics.setAnalyticsCollectionEnabled(false)
#endif
```

## Common Configuration Issues

### Issue: "Firebase not configured" error

**Solution**: Ensure `FirebaseApp.configure()` is called before any Firebase service:
```swift
@main
struct YourApp: App {
  init() {
    FirebaseApp.configure()  // Must be first!
    // ... other setup
  }
}
```

### Issue: Google Sign-In shows "Developer Error"

**Solutions**:
1. Check OAuth client ID matches in Firebase Console and GoogleService-Info.plist
2. Verify bundle ID matches exactly
3. Ensure SHA-1 fingerprint is added (for Android, but good practice)

### Issue: Apple Sign-In not appearing

**Solutions**:
1. Enable "Sign in with Apple" capability in Xcode
2. Configure in Apple Developer portal
3. Enable in Firebase Console > Authentication > Sign-in method

### Issue: Emulator connection refused

**Solutions**:
1. Ensure emulators are running: `firebase emulators:start`
2. Check ports are correct (default: auth=9099, firestore=8080)
3. For device testing, use machine's IP instead of localhost
