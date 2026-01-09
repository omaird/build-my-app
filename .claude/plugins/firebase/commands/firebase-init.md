---
description: Initialize Firebase in an iOS project - add SDK packages, create service files, configure app initialization
argument_description: Optional project path or --minimal flag
---

# Firebase Init Command

Quick initialization of Firebase in an iOS project. Creates all necessary service files and configuration.

## Usage

```
/firebase-init [path] [--minimal]
```

## Arguments

- `path` - Path to iOS project (default: current directory)
- `--minimal` - Only add packages and initialization, skip service files
- `--auth` - Include Firebase Auth setup
- `--firestore` - Include Firestore setup

## Prerequisites

Before running this command:
1. Have a Firebase project created at console.firebase.google.com
2. Have GoogleService-Info.plist downloaded
3. Have XcodeGen installed (`brew install xcodegen`)

## What This Command Does

### 1. Add Firebase Packages to project.yml

```yaml
packages:
  Firebase:
    url: https://github.com/firebase/firebase-ios-sdk
    from: "11.0.0"
  GoogleSignIn:
    url: https://github.com/google/GoogleSignIn-iOS
    from: "8.0.0"
```

### 2. Add Package Dependencies to Targets

```yaml
targets:
  YourKit:
    dependencies:
      - package: Firebase
        product: FirebaseAuth
      - package: Firebase
        product: FirebaseFirestore
      - package: GoogleSignIn
        product: GoogleSignIn
```

### 3. Create Configuration Structure

```swift
// Dependencies.swift
public struct FirebaseConfiguration: Sendable {
  public let projectId: String
  public let useEmulator: Bool
  public let emulatorHost: String
  public let authEmulatorPort: Int
  public let firestoreEmulatorPort: Int
}
```

### 4. Add Firebase Initialization

```swift
// YourApp.swift
import FirebaseCore

@main
struct YourApp: App {
  init() {
    FirebaseApp.configure()
  }
}
```

### 5. (If --auth) Create Auth Service

Creates `FirebaseAuthService.swift` with:
- Email/password authentication
- Google Sign-In
- Apple Sign-In
- Session management

### 6. (If --firestore) Create Firestore Service

Creates `FirestoreService.swift` with:
- Document CRUD operations
- Query patterns
- Real-time listeners
- Offline persistence

## File Structure Created

```
YourKit/
├── Services/
│   ├── Auth/
│   │   ├── FirebaseAuthService.swift
│   │   └── KeychainService.swift
│   ├── Firebase/
│   │   ├── FirestoreService.swift
│   │   └── FirebaseConfiguration.swift
│   └── Dependencies.swift
```

## Post-Init Steps

After running this command:

1. **Add GoogleService-Info.plist**
   - Download from Firebase Console
   - Place in `YourApp/Resources/`

2. **Configure URL Schemes**
   - Get `REVERSED_CLIENT_ID` from plist
   - Add to Info.plist or project.yml

3. **Enable Sign in with Apple**
   - Add entitlement
   - Enable capability in Xcode

4. **Regenerate Project**
   ```bash
   xcodegen generate
   ```

5. **Verify Build**
   ```bash
   xcodebuild -scheme YourScheme build
   ```

## Example Output

```
Firebase Initialization
═══════════════════════════════════════

✓ Added Firebase packages to project.yml
✓ Added package dependencies to RIZQKit
✓ Created FirebaseConfiguration struct
✓ Added FirebaseApp.configure() to RIZQApp
✓ Created FirebaseAuthService
✓ Created FirestoreService
✓ Created KeychainService

Next steps:
1. Add GoogleService-Info.plist to Resources/
2. Configure URL schemes for Google Sign-In
3. Run 'xcodegen generate' to regenerate project
4. Build and verify
```

## Related Commands

- `/setup-firebase` - Full setup with verification
- `/firebase-status` - Check configuration status
