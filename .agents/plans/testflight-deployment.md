# TestFlight Deployment Plan for RIZQ iOS

**Created**: 2026-01-11
**Status**: Ready to Execute
**Estimated Phases**: 5

---

## Overview

This plan guides you through deploying the RIZQ iOS app to TestFlight for beta testing. It's designed for "vibe coding" with Claude Code—each phase is a conversation you can have with Claude to complete that step.

### Available Tools & Plugins

Your project already has excellent TestFlight infrastructure:

| Plugin/Tool | Commands & Agents | Purpose |
|-------------|-------------------|---------|
| **rizq-ios** | `/prepare-testflight`, `/submit-testflight` | Validation & submission |
| **rizq-ios** | `testflight-preparer`, `testflight-submitter`, `testflight-manager` agents | Automated preparation & management |
| **rizq-ios** | `testflight-guide` skill | Complete TestFlight documentation |
| **fastlane** | `beta`, `build`, `test`, `certificates` lanes | Automation |
| **XcodeGen** | `project.yml` | Project generation |

---

## Phase 1: Apple Developer Account Setup

**Goal**: Ensure you have Apple Developer Program membership and App Store Connect access.

### Prerequisites Checklist

```
□ Apple ID with Apple Developer Program membership ($99/year)
□ App Store Connect access (Admin or App Manager role)
□ Physical Mac with Xcode installed
```

### Conversation Prompt

> "Help me verify my Apple Developer account is set up correctly for TestFlight. Check if I have Xcode installed and the command line tools configured."

### Expected Actions

Claude will:
1. Check Xcode installation: `xcodebuild -version`
2. Verify command line tools: `xcode-select -p`
3. Guide you to https://developer.apple.com/programs/ if needed
4. Verify you can access App Store Connect

### Manual Steps (You Must Do)

1. **Sign up for Apple Developer Program** at https://developer.apple.com/programs/
2. **Accept agreements** in App Store Connect (paid apps agreement may be needed)
3. **Note your Team ID** from https://developer.apple.com/account → Membership

---

## Phase 2: App Store Connect App Record

**Goal**: Create the app record in App Store Connect that your TestFlight builds will upload to.

### Conversation Prompt

> "Help me create an App Store Connect app record for RIZQ. The bundle ID is `com.rizq.app` and it's an Islamic dua practice app."

### Required Information

| Field | Value |
|-------|-------|
| Bundle ID | `com.rizq.app` |
| Name | RIZQ (or your preferred display name) |
| Primary Language | English |
| SKU | `rizq-ios-app` (or any unique identifier) |
| Primary Category | Lifestyle or Health & Fitness |

### Manual Steps (You Must Do)

1. Go to https://appstoreconnect.apple.com
2. Click "Apps" → "+" → "New App"
3. Fill in:
   - Platform: iOS
   - Name: RIZQ
   - Primary Language: English
   - Bundle ID: Select `com.rizq.app` (must be registered first)
   - SKU: `rizq-ios-app`
4. Click "Create"

### Register Bundle ID (if not done)

1. Go to https://developer.apple.com/account/resources/identifiers
2. Click "+" → "App IDs" → "App"
3. Description: RIZQ iOS App
4. Bundle ID: Explicit → `com.rizq.app`
5. Enable capabilities:
   - Push Notifications (if using)
   - Sign in with Apple (if using)
6. Click "Register"

Also register the widget: `com.rizq.app.widget`

---

## Phase 3: Authentication & Code Signing Setup

**Goal**: Configure fastlane authentication and code signing for automated builds.

### Conversation Prompt

> "Help me set up fastlane authentication and code signing for TestFlight. I need to configure the Appfile with my Apple ID and Team ID, and set up App Store Connect API key for automation."

### Step 3.1: Update Appfile

Claude will help update `RIZQ-iOS/fastlane/Appfile`:

```ruby
# App identifiers
app_identifier("com.rizq.app")

# Apple Developer account
apple_id("YOUR_APPLE_ID@example.com")  # Your Apple ID email
team_id("YOUR_TEAM_ID")                 # From developer.apple.com/account

# For App Store Connect API (recommended for CI/CD)
# json_key_file("./fastlane/api_key.json")
```

### Step 3.2: Create App Store Connect API Key

**Manual Steps:**

1. Go to https://appstoreconnect.apple.com/access/api
2. Click "+" to generate a new key
3. Name: "Fastlane CI"
4. Access: "App Manager" role
5. Download the `.p8` file (you can only download once!)
6. Save to `RIZQ-iOS/fastlane/AuthKey_XXXXXX.p8`

Create `RIZQ-iOS/fastlane/api_key.json`:

```json
{
  "key_id": "XXXXXXXXXX",
  "issuer_id": "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx",
  "key_filepath": "fastlane/AuthKey_XXXXXXXXXX.p8"
}
```

Then uncomment in Appfile:
```ruby
json_key_file("./fastlane/api_key.json")
```

### Step 3.3: Code Signing with Match (Optional but Recommended)

For team collaboration and CI/CD:

> "Help me set up fastlane match for code signing. I want to use Git storage for certificates."

**Manual Steps:**

1. Create a **private** Git repo for certificates (e.g., `github.com/your-org/certificates`)
2. Update `RIZQ-iOS/fastlane/Matchfile`:

```ruby
git_url("git@github.com:your-org/certificates.git")
storage_mode("git")
type("appstore")
app_identifier(["com.rizq.app", "com.rizq.app.widget"])
```

3. Run initial match setup:

```bash
cd RIZQ-iOS
bundle exec fastlane match appstore
```

### Alternative: Automatic Signing (Simpler)

If you're a solo developer, Xcode's automatic signing works:

1. Open `RIZQ.xcodeproj` in Xcode
2. Select RIZQ target → Signing & Capabilities
3. Enable "Automatically manage signing"
4. Select your team
5. Do the same for RIZQWidget target

---

## Phase 4: Prepare Build for TestFlight

**Goal**: Validate the app is ready for TestFlight submission.

### Conversation Prompt

> "Run `/prepare-testflight` to validate my iOS app is ready for TestFlight."

### What the Command Checks

The `/prepare-testflight` command validates:

1. ✅ **Project Structure** - Xcode project exists
2. ✅ **Version & Build Number** - Properly set and incrementing
3. ✅ **App Icons** - All required sizes including 1024x1024
4. ✅ **Info.plist** - Required keys present
5. ✅ **Export Compliance** - `ITSAppUsesNonExemptEncryption` set
6. ✅ **Privacy Manifest** - `PrivacyInfo.xcprivacy` exists (iOS 17+)
7. ✅ **Code Signing** - Certificates available
8. ✅ **Build Test** - Release build succeeds

### Fix Common Issues

If issues are found, use:

> "Run `/prepare-testflight fix=true` to automatically fix common issues."

Or fix manually with Claude:

> "Help me fix the missing `ITSAppUsesNonExemptEncryption` key in Info.plist"

> "Create a Privacy Manifest file for RIZQ"

### Validation Output Example

```
╔═══════════════════════════════════════════════════════╗
║           TESTFLIGHT PREPARATION REPORT               ║
╠═══════════════════════════════════════════════════════╣
║ Project Structure    │ ✅ PASS                        ║
║ Version/Build        │ ✅ 1.0.0 (1)                   ║
║ App Icons            │ ✅ All sizes present           ║
║ Info.plist           │ ✅ All required keys           ║
║ Privacy Manifest     │ ✅ Present                     ║
║ Code Signing         │ ✅ Certificate valid           ║
║ fastlane             │ ✅ Configured                  ║
║ Build Test           │ ✅ PASS                        ║
╠═══════════════════════════════════════════════════════╣
║ OVERALL STATUS       │ ✅ READY FOR SUBMISSION        ║
╚═══════════════════════════════════════════════════════╝
```

---

## Phase 5: Submit to TestFlight

**Goal**: Build, archive, and upload the app to TestFlight.

### Conversation Prompt

> "Run `/submit-testflight` to build and upload RIZQ to TestFlight."

### What the Command Does

1. **Pre-validation** - Quick checks before building
2. **Sync certificates** - Ensure signing is set up
3. **Increment build number** - Auto-increment beyond TestFlight latest
4. **Build archive** - Create release IPA
5. **Upload** - Send to App Store Connect
6. **Git tag** - Tag the release (e.g., `testflight/v1.0.0/1`)

### Alternative: Direct fastlane Command

```bash
cd RIZQ-iOS
bundle exec fastlane beta
```

### With Specific Options

```bash
# Skip tests (not recommended for first submission)
bundle exec fastlane beta skip_tests:true

# With specific version bump
bundle exec fastlane release version:1.0.1
```

### Upload Success Output

```
╔═══════════════════════════════════════════════════════╗
║           TESTFLIGHT SUBMISSION COMPLETE              ║
╠═══════════════════════════════════════════════════════╣
║ Version              │ 1.0.0                          ║
║ Build                │ 1                              ║
║ Archive Size         │ ~25 MB                         ║
║ Status               │ Processing                     ║
╠═══════════════════════════════════════════════════════╣
║ Git Tag              │ testflight/v1.0.0/1            ║
╚═══════════════════════════════════════════════════════╝

⏳ Build is processing on Apple's servers (10-30 min)
```

---

## Post-Submission: Managing TestFlight

### Monitor Build Processing

> "Check the status of my TestFlight build processing."

Claude can run:
```bash
bundle exec fastlane pilot builds
```

Or check manually at App Store Connect → TestFlight

### Add Testers

> "Help me add testers to TestFlight."

**Internal Testers** (App Store Connect users):
- No review required
- Up to 100 testers
- Access immediately after processing

**External Testers** (anyone):
- First build requires Beta App Review (24-48h)
- Up to 10,000 testers
- Create groups for staged rollout

```bash
# Add tester via fastlane
bundle exec fastlane pilot add email:"tester@example.com" --groups "Beta Testers"
```

### Create Public Link

In App Store Connect → TestFlight → External Testing:
1. Create a new group or use existing
2. Enable "Public Link"
3. Share link: `https://testflight.apple.com/join/XXXXX`

---

## Quick Reference: All Commands

| Task | Command |
|------|---------|
| Validate readiness | `/prepare-testflight` |
| Fix common issues | `/prepare-testflight fix=true` |
| Submit to TestFlight | `/submit-testflight` |
| Run tests | `bundle exec fastlane test` |
| Build IPA | `bundle exec fastlane build` |
| Full pipeline | `bundle exec fastlane beta` |
| Version bump + submit | `bundle exec fastlane release version:X.Y.Z` |
| Sync certificates | `bundle exec fastlane certificates` |
| Add test device | `bundle exec fastlane add_device name:'iPhone' udid:'xxx'` |
| List TestFlight builds | `bundle exec fastlane pilot builds` |

---

## Troubleshooting Quick Guide

### "No signing certificate"
```bash
# Re-sync with match
bundle exec fastlane match appstore --force

# Or reset Xcode signing
# In Xcode: Signing → Automatically manage signing → Re-select team
```

### "Build number already exists"
```bash
# Auto-increment beyond TestFlight
agvtool next-version -all
```

### "Missing compliance"
```bash
# Add to Info.plist
/usr/libexec/PlistBuddy -c "Add :ITSAppUsesNonExemptEncryption bool false" RIZQ/Info.plist
```

### "Beta App Rejected"
Common reasons:
- App crashes on launch
- Placeholder content visible
- Login doesn't work
- Missing privacy policy

---

## Timeline Checklist

Use this to track progress:

### ✅ AUTOMATED (Claude completed these)

```
Phase 4: Prepare Build (AUTOMATED)
  ✅ PrivacyInfo.xcprivacy created (iOS 17+ requirement)
  ✅ Info.plist has ITSAppUsesNonExemptEncryption
  ✅ LaunchBackground color asset created
  ✅ Release build configuration validated
  ✅ Appfile template with instructions prepared
  ✅ Matchfile template with instructions prepared
```

### 📋 MANUAL STEPS (You must complete these)

```
Phase 1: Apple Developer Setup
  □ Apple Developer Program membership active ($99/year)
    → https://developer.apple.com/programs/
  □ App Store Connect access verified
    → https://appstoreconnect.apple.com
  □ Team ID noted (10-character alphanumeric)
    → https://developer.apple.com/account → Membership

Phase 2: App Store Connect App Record
  □ Bundle ID registered: com.rizq.app
    → https://developer.apple.com/account/resources/identifiers
    → Enable: App Groups, Associated Domains
  □ Bundle ID registered: com.rizq.app.widget
    → Enable: App Groups
  □ App Group registered: group.com.rizq.app
    → https://developer.apple.com/account/resources/identifiers/applicationGroup/add
  □ App record created in App Store Connect
    → https://appstoreconnect.apple.com → Apps → "+"

Phase 3: Authentication & Signing
  □ Appfile updated with your apple_id and team_id
    → Edit: RIZQ-iOS/fastlane/Appfile
  □ (Optional) App Store Connect API key created
    → https://appstoreconnect.apple.com/access/api
  □ Code signing configured
    → Option A: Xcode automatic signing (easier)
    → Option B: fastlane match (for teams)

Phase 4: Prepare Build
  □ App icon added (1024x1024 PNG)
    → Save as: RIZQ-iOS/RIZQ/Assets.xcassets/AppIcon.appiconset/AppIcon.png
    → See: AppIcon.appiconset/README.md for design tips

Phase 5: Submit
  □ Run: /prepare-testflight (validation check)
  □ Run: /submit-testflight (build & upload)
  □ Build processing on Apple's servers (10-30 min)
  □ Build approved/ready for testing
  □ Testers added via App Store Connect
  □ Testing in progress!
```

---

## Next Steps After First TestFlight

1. **Gather Feedback** - Use TestFlight feedback feature
2. **Iterate** - Fix issues, add features
3. **Subsequent Builds** - Just run `/submit-testflight`
4. **App Store Submission** - When ready, submit for full review

---

## Files Reference

| File | Purpose |
|------|---------|
| `RIZQ-iOS/fastlane/Appfile` | Apple ID, Team ID configuration |
| `RIZQ-iOS/fastlane/Fastfile` | Automation lanes |
| `RIZQ-iOS/fastlane/Matchfile` | Code signing configuration |
| `RIZQ-iOS/fastlane/api_key.json` | App Store Connect API credentials |
| `RIZQ-iOS/project.yml` | XcodeGen project spec |
| `RIZQ-iOS/RIZQ/Info.plist` | App configuration |
| `RIZQ-iOS/RIZQ/PrivacyInfo.xcprivacy` | Privacy manifest |

---

*This plan leverages your existing rizq-ios plugin infrastructure for a smooth TestFlight deployment experience.*
