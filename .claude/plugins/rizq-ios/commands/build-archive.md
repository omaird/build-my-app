---
name: build-archive
description: Build and archive the iOS app for distribution
allowed_tools:
  - Bash
  - Read
arguments:
  - name: target
    description: "Distribution target: testflight, appstore, or adhoc"
    required: false
---

# Build and Archive

Build the RIZQ iOS app and create an archive for distribution.

## Distribution Target: {{ target | default: "testflight" }}

## Build Options

| Target | Export Method | Use Case |
|--------|---------------|----------|
| testflight | app-store | Internal testing via TestFlight |
| appstore | app-store | App Store submission |
| adhoc | ad-hoc | Direct device installation |

## Build Commands

### TestFlight Build

```bash
# Sync certificates
bundle exec fastlane sync_appstore_certs

# Build and upload to TestFlight
bundle exec fastlane beta
```

### App Store Build

```bash
# Sync certificates
bundle exec fastlane sync_appstore_certs

# Build and upload to App Store Connect
bundle exec fastlane release
```

### Local Archive (Manual)

```bash
# Clean build folder
xcodebuild clean -project RIZQ.xcodeproj -scheme RIZQ

# Archive
xcodebuild archive \
  -project RIZQ.xcodeproj \
  -scheme RIZQ \
  -configuration Release \
  -archivePath build/RIZQ.xcarchive \
  -destination 'generic/platform=iOS'

# Export IPA
xcodebuild -exportArchive \
  -archivePath build/RIZQ.xcarchive \
  -exportPath build \
  -exportOptionsPlist ExportOptions.plist
```

### ExportOptions.plist

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>method</key>
    <string>app-store</string>
    <key>teamID</key>
    <string>YOUR_TEAM_ID</string>
    <key>uploadBitcode</key>
    <false/>
    <key>uploadSymbols</key>
    <true/>
    <key>signingStyle</key>
    <string>automatic</string>
</dict>
</plist>
```

## Pre-Build Checklist

- [ ] Version number updated (`bundle exec fastlane bump_version`)
- [ ] Build number incremented (`bundle exec fastlane bump_build`)
- [ ] All tests passing (`bundle exec fastlane test`)
- [ ] No uncommitted changes
- [ ] Correct provisioning profile selected

## Post-Build Actions

### TestFlight
1. Build uploads automatically
2. Processing takes 10-30 minutes
3. Add testers to build in App Store Connect
4. Testers receive notification to update

### App Store
1. Build uploads to App Store Connect
2. Select build in "iOS App" section
3. Complete App Information if needed
4. Add "What's New" for this version
5. Submit for Review

## Troubleshooting

### "No signing certificate"

```bash
# Re-sync certificates
bundle exec fastlane match appstore --force
```

### "Provisioning profile doesn't include device"

```bash
# Add device and regenerate profiles
bundle exec fastlane add_device name:"iPhone" udid:"XXXX"
bundle exec fastlane match development --force_for_new_devices
```

### "Build number already exists"

```bash
# Increment build number
bundle exec fastlane bump_build
git add .
git commit -m "Bump build number"
```

### "Archive failed"

```bash
# Clean and rebuild
rm -rf ~/Library/Developer/Xcode/DerivedData
xcodebuild clean -project RIZQ.xcodeproj -scheme RIZQ
bundle exec fastlane beta
```

## Output Location

- Archive: `build/RIZQ.xcarchive`
- IPA: `build/RIZQ.ipa`
- dSYM: `build/RIZQ.app.dSYM.zip`

## CI/CD Integration

For GitHub Actions, the `beta` and `release` workflows handle:
1. Checking out code
2. Setting up certificates
3. Building archive
4. Uploading to App Store Connect
5. Tagging release
6. Notifying team

See `.github/workflows/beta.yml` and `.github/workflows/release.yml`.
