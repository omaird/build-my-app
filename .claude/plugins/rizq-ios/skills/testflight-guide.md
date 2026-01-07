---
name: testflight-guide
description: Comprehensive guide for TestFlight beta testing - requirements, preparation, submission, tester management, and troubleshooting
---

# TestFlight Complete Guide

This skill covers everything needed to successfully deploy and manage TestFlight beta builds.

## TestFlight Overview

TestFlight is Apple's beta testing platform that allows you to:
- Distribute builds to up to 10,000 external testers
- Distribute to unlimited internal testers (App Store Connect users)
- Collect crash reports and feedback
- Test in-app purchases in sandbox mode
- Test on real devices before App Store release

---

## Requirements Checklist

### Apple Developer Account Requirements

| Requirement | Details |
|-------------|---------|
| Apple Developer Program | $99/year membership required |
| App Store Connect Access | Admin or App Manager role |
| Bundle ID | Registered in Developer Portal |
| App Record | Created in App Store Connect |

### Technical Requirements

| Requirement | Details |
|-------------|---------|
| Xcode Version | Latest stable recommended |
| iOS Deployment Target | iOS 12.0+ for TestFlight |
| Valid Signing | Distribution certificate + provisioning profile |
| App Icons | All sizes including 1024x1024 App Store icon |
| Build Number | Must be unique and incrementing |

### App Store Connect App Record

Before uploading, ensure your app has:
- [ ] App name (can be placeholder)
- [ ] Primary language
- [ ] Bundle ID selected
- [ ] SKU (unique identifier)
- [ ] Primary category selected

---

## Build Versioning Strategy

### Version Number (CFBundleShortVersionString)
Semantic versioning: `MAJOR.MINOR.PATCH`
- **MAJOR**: Breaking changes, major features
- **MINOR**: New features, backwards compatible
- **PATCH**: Bug fixes

### Build Number (CFBundleVersion)
Must be unique and incrementing for each upload:

```swift
// Strategies:
// 1. Simple increment: 1, 2, 3, 4...
// 2. Date-based: 20240115.1, 20240115.2...
// 3. CI build number: from GitHub Actions run number
```

### fastlane Auto-Increment

```ruby
# Get latest TestFlight build and increment
lane :bump_testflight_build do
  latest = latest_testflight_build_number(
    app_identifier: "com.rizq.app",
    initial_build_number: 0
  )

  increment_build_number(
    build_number: latest + 1,
    xcodeproj: "RIZQ.xcodeproj"
  )
end
```

---

## Code Signing for TestFlight

### Certificate Types

| Certificate | Purpose | Max Active |
|-------------|---------|------------|
| iOS Distribution | App Store & TestFlight | 3 per account |
| Apple Distribution | Universal (recommended) | 3 per account |

### Provisioning Profile Types

| Profile | Use Case |
|---------|----------|
| App Store | TestFlight + App Store distribution |
| Ad Hoc | Direct device installation (limited) |

### Using match for Code Signing

```ruby
# Matchfile
git_url("git@github.com:rizq/certificates.git")
storage_mode("git")
type("appstore")  # Use appstore for TestFlight
app_identifier([
  "com.rizq.app",
  "com.rizq.app.widget"  # Include extensions
])

# Generate/sync certificates
# Run once to create, then readonly in CI
lane :sync_certs do
  match(
    type: "appstore",
    readonly: is_ci,
    app_identifier: [
      "com.rizq.app",
      "com.rizq.app.widget"
    ]
  )
end
```

---

## Export Compliance

### Encryption Declaration

If your app uses HTTPS (most do), you need to declare encryption:

**Info.plist Addition:**
```xml
<key>ITSAppUsesNonExemptEncryption</key>
<false/>
```

This declares your app only uses exempt encryption (standard HTTPS).

**If using custom encryption:**
- Set to `<true/>`
- May require export compliance documentation
- Annual self-classification report to US government

### When `false` is Appropriate
- Standard HTTPS/TLS for API calls
- Using Apple's built-in encryption APIs
- Using standard authentication protocols

### When `true` is Required
- Custom encryption algorithms
- Encryption for purposes other than authentication
- Apps distributed in embargoed countries

---

## App Privacy Details

TestFlight builds require privacy information in App Store Connect:

### Privacy Questions to Answer

1. **Data Collection**: What data does your app collect?
2. **Data Linking**: Is collected data linked to user identity?
3. **Data Tracking**: Is data used for tracking across apps/websites?

### RIZQ App Data Types

| Data Type | Collected | Linked to User | Used for Tracking |
|-----------|-----------|----------------|-------------------|
| Email | Yes | Yes | No |
| Name | Yes | Yes | No |
| User ID | Yes | Yes | No |
| Usage Data | Yes | Yes | No |
| Crash Data | Yes | No | No |

### Privacy Manifest (iOS 17+)

```xml
<!-- PrivacyInfo.xcprivacy -->
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>NSPrivacyTracking</key>
  <false/>
  <key>NSPrivacyCollectedDataTypes</key>
  <array>
    <dict>
      <key>NSPrivacyCollectedDataType</key>
      <string>NSPrivacyCollectedDataTypeEmailAddress</string>
      <key>NSPrivacyCollectedDataTypeLinked</key>
      <true/>
      <key>NSPrivacyCollectedDataTypeTracking</key>
      <false/>
      <key>NSPrivacyCollectedDataTypePurposes</key>
      <array>
        <string>NSPrivacyCollectedDataTypePurposeAppFunctionality</string>
      </array>
    </dict>
  </array>
  <key>NSPrivacyAccessedAPITypes</key>
  <array>
    <dict>
      <key>NSPrivacyAccessedAPIType</key>
      <string>NSPrivacyAccessedAPICategoryUserDefaults</string>
      <key>NSPrivacyAccessedAPITypeReasons</key>
      <array>
        <string>CA92.1</string>
      </array>
    </dict>
  </array>
</dict>
</plist>
```

---

## TestFlight Build States

| State | Meaning | Action |
|-------|---------|--------|
| Processing | Apple processing build | Wait 10-30 minutes |
| Ready to Submit | Processing complete | Can distribute |
| Approved | Ready for distribution | Add testers |
| Rejected | Failed review | Fix issues, resubmit |
| Expired | 90 days since upload | Upload new build |

### Build Expiration
- TestFlight builds expire after **90 days**
- Testers receive warning at 60 days
- Must upload new build before expiration

---

## Tester Types

### Internal Testers
- **Who**: App Store Connect users with roles
- **Limit**: Up to 100 testers
- **Review**: No Beta App Review required
- **Access**: Immediate after processing

### External Testers
- **Who**: Anyone with email/public link
- **Limit**: Up to 10,000 testers
- **Review**: First build requires Beta App Review
- **Access**: After approval (usually 24-48 hours)

### Tester Groups
Organize testers into groups for staged rollouts:

```
Groups:
├── Internal Team (internal)
├── QA Team (external)
├── Beta Testers (external)
└── Public Beta (external, public link)
```

---

## Beta App Review

### What Triggers Review
- First external tester build
- Significant changes to app functionality
- Changes to export compliance answers

### Review Guidelines (Subset)
Beta builds must:
- Be complete and functional (no placeholder UI)
- Not crash on launch
- Include working authentication (if applicable)
- Have accurate app description

### What to Include in Test Notes
```
Beta Test Notes:
- What to test: [specific features]
- Known issues: [list any known bugs]
- Test accounts: [if needed]
- Feedback: [how to report issues]
```

### Review Timeline
- **First submission**: 24-48 hours typically
- **Subsequent builds**: Usually automatic if no major changes
- **Rejected builds**: Fix and resubmit, re-reviewed

---

## TestFlight Feedback

### In-App Feedback
TestFlight provides built-in feedback:
- Screenshot annotation
- Typed feedback
- Automatically includes:
  - Device model
  - iOS version
  - App version
  - Crash logs

### Accessing Feedback
1. App Store Connect → My Apps → TestFlight
2. Select build
3. View "Feedback" tab

### Crash Reports
- Automatically collected
- Symbolicated with uploaded dSYMs
- Grouped by crash signature

---

## Common TestFlight Issues

### "Missing Compliance"
**Cause**: No encryption declaration
**Fix**: Add `ITSAppUsesNonExemptEncryption` to Info.plist

### "Invalid Binary"
**Causes**:
- Missing required icons
- Invalid provisioning profile
- Unsupported architectures

**Fix**: Check email from Apple for specific error

### "Build Processing Failed"
**Causes**:
- Corrupted binary
- Missing required capabilities
- Invalid entitlements

**Fix**: Clean build, re-archive, re-upload

### "Beta App Rejected"
**Common Reasons**:
- Crashes on launch
- Incomplete features
- Placeholder content
- Login issues

**Fix**: Address specific feedback, resubmit

### "Testers Can't Install"
**Causes**:
- Build not distributed to their group
- Build expired
- Device not compatible
- Tester didn't accept invite

---

## TestFlight URLs

| Purpose | URL |
|---------|-----|
| App Store Connect | https://appstoreconnect.apple.com |
| TestFlight App | https://apps.apple.com/app/testflight/id899247664 |
| Public Link Format | https://testflight.apple.com/join/{code} |

---

## Automation with fastlane

### Upload Build

```ruby
lane :upload_testflight do
  sync_certs

  gym(
    scheme: "RIZQ",
    export_method: "app-store",
    output_directory: "build"
  )

  pilot(
    skip_waiting_for_build_processing: false,
    distribute_external: false
  )
end
```

### Distribute to Testers

```ruby
lane :distribute_to_testers do
  pilot(
    distribute_external: true,
    groups: ["Beta Testers"],
    changelog: "Bug fixes and improvements"
  )
end
```

### Add External Tester

```ruby
lane :add_tester do |options|
  pilot(
    email: options[:email],
    groups: ["Beta Testers"]
  )
end
```

---

## Pre-Flight Checklist

Before uploading to TestFlight:

### Code Quality
- [ ] All tests passing
- [ ] No compiler warnings
- [ ] No console errors/warnings in release build
- [ ] Memory leaks checked

### Configuration
- [ ] Version number updated
- [ ] Build number incremented
- [ ] Bundle ID correct
- [ ] Signing identity: Distribution
- [ ] Provisioning profile: App Store

### Required Files
- [ ] App icons (all sizes)
- [ ] Launch screen configured
- [ ] Info.plist complete
- [ ] Privacy manifest (iOS 17+)
- [ ] Export compliance declared

### Functionality
- [ ] App launches without crash
- [ ] Core flows working
- [ ] Authentication working
- [ ] Network requests succeeding
- [ ] No placeholder content visible

### App Store Connect
- [ ] App record exists
- [ ] Privacy details completed
- [ ] Test information filled
- [ ] Tester groups configured
