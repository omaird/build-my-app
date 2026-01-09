---
description: Check Firebase configuration status and diagnose common issues in iOS projects
argument_description: Optional --verbose flag for detailed output
---

# Firebase Status Command

Quickly check Firebase configuration status and identify issues.

## Usage

```
/firebase-status [--verbose]
```

## Flags

- `--verbose` - Show detailed configuration values
- `--fix` - Attempt to fix simple issues automatically

## Checks Performed

### 1. Configuration Files

| Check | File | Status |
|-------|------|--------|
| GoogleService-Info.plist | `Resources/GoogleService-Info.plist` | Required |
| Entitlements | `*.entitlements` | Required for Apple Sign-In |
| project.yml | `project.yml` | Firebase packages |

### 2. GoogleService-Info.plist Validation

Verifies presence of:
- `CLIENT_ID` - Google OAuth client
- `REVERSED_CLIENT_ID` - URL scheme
- `PROJECT_ID` - Firebase project
- `BUNDLE_ID` - App bundle ID match

### 3. Package Dependencies

Checks `project.yml` for:
- `FirebaseAuth` package
- `FirebaseFirestore` package
- `GoogleSignIn` package

### 4. URL Schemes

Verifies URL schemes in Info.plist or project.yml:
- `REVERSED_CLIENT_ID` for Google Sign-In
- Custom scheme for OAuth callbacks

### 5. Entitlements

Checks entitlements file for:
- `com.apple.developer.applesignin` for Apple Sign-In
- `keychain-access-groups` for secure storage

### 6. Code Configuration

Verifies in source code:
- `FirebaseApp.configure()` called in app init
- Emulator configuration for DEBUG
- Auth service properly implemented

### 7. Service Files

Checks existence of:
- `FirebaseAuthService.swift`
- `FirestoreService.swift`
- `KeychainService.swift`

## Output Format

### Healthy Configuration

```
Firebase Status
═══════════════════════════════════════

Configuration Files
  ✓ GoogleService-Info.plist
  ✓ RIZQ.entitlements
  ✓ project.yml Firebase packages

GoogleService-Info.plist
  ✓ CLIENT_ID present
  ✓ REVERSED_CLIENT_ID present
  ✓ PROJECT_ID: rizq-app-xxxxx
  ✓ BUNDLE_ID matches app

URL Schemes
  ✓ Google Sign-In URL scheme configured

Entitlements
  ✓ Sign in with Apple enabled
  ✓ Keychain sharing enabled

Code Configuration
  ✓ FirebaseApp.configure() in RIZQApp
  ✓ Emulator support configured

Service Files
  ✓ FirebaseAuthService.swift
  ✓ FirestoreService.swift
  ✓ KeychainService.swift

Status: Firebase is properly configured ✓
```

### Configuration Issues

```
Firebase Status
═══════════════════════════════════════

Configuration Files
  ✓ GoogleService-Info.plist
  ✗ RIZQ.entitlements - Missing Sign in with Apple
  ✓ project.yml Firebase packages

GoogleService-Info.plist
  ✓ CLIENT_ID present
  ✓ REVERSED_CLIENT_ID present
  ✓ PROJECT_ID: rizq-app-xxxxx
  ⚠ BUNDLE_ID mismatch: expected com.rizq.app, got com.example.app

URL Schemes
  ✗ Google Sign-In URL scheme NOT configured

Issues Found:
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
1. Missing Sign in with Apple entitlement
   Fix: Add com.apple.developer.applesignin to entitlements

2. Bundle ID mismatch in GoogleService-Info.plist
   Fix: Re-download plist with correct bundle ID

3. Missing URL scheme for Google Sign-In
   Fix: Add REVERSED_CLIENT_ID to URL schemes in project.yml

Run '/firebase-status --fix' to attempt automatic fixes
```

## Verbose Output

With `--verbose` flag, shows:
- Full CLIENT_ID value
- Complete URL scheme configuration
- Firebase package versions
- All entitlement values

## Quick Fixes

The `--fix` flag can automatically:
- Add URL schemes to project.yml
- Create missing entitlements file
- Add Sign in with Apple entitlement
- Regenerate Xcode project

## Related Commands

- `/firebase-init` - Initialize Firebase
- `/setup-firebase` - Full setup guide

## Diagnostic Commands

If issues persist, these bash commands help diagnose:

```bash
# Check plist exists
ls -la */Resources/GoogleService-Info.plist

# Verify Firebase packages
grep -A 10 "Firebase:" project.yml

# Check URL schemes
grep -A 5 "CFBundleURLSchemes" project.yml

# Verify initialization
grep -r "FirebaseApp.configure" *.swift

# Check entitlements
cat *.entitlements
```
