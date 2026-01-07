---
name: submit-testflight
description: Build, archive, and upload to TestFlight
allowed_tools:
  - Bash
  - Read
  - Edit
arguments:
  - name: skip_validation
    description: "Skip pre-flight validation (not recommended)"
    required: false
  - name: distribute
    description: "Automatically distribute to group after upload"
    required: false
  - name: group
    description: "Tester group to distribute to (default: Internal)"
    required: false
  - name: changelog
    description: "What's new in this build"
    required: false
---

# Submit to TestFlight

Build, archive, and upload the iOS app to TestFlight.

## Options

- **skip_validation**: {{ skip_validation | default: "false" }}
- **distribute**: {{ distribute | default: "false" }}
- **group**: {{ group | default: "Internal" }}
- **changelog**: {{ changelog | default: "Bug fixes and improvements" }}

---

## Pre-Submission Checks

Unless `skip_validation=true`, run validation first:

```bash
echo "=== Pre-Submission Validation ==="

# Check git status
if [ -z "$(git status --porcelain)" ]; then
  echo "✅ Git working directory is clean"
else
  echo "⚠️  Uncommitted changes detected"
  git status --short
fi

# Quick Info.plist check
INFO_PLIST=$(find . -name "Info.plist" -path "*/RIZQ/*" ! -path "*/Tests/*" | head -1)
ENCRYPTION=$(/usr/libexec/PlistBuddy -c "Print :ITSAppUsesNonExemptEncryption" "$INFO_PLIST" 2>/dev/null)
if [ -z "$ENCRYPTION" ]; then
  echo "❌ Missing ITSAppUsesNonExemptEncryption - run /prepare-testflight first"
  exit 1
fi
echo "✅ Encryption declaration present"

# Check certificates
if security find-identity -v -p codesigning | grep -q "Apple Distribution"; then
  echo "✅ Signing certificate available"
else
  echo "❌ No Apple Distribution certificate found"
  exit 1
fi
```

---

## Submission Workflow

### Step 1: Sync Certificates

```bash
echo "=== Syncing Certificates ==="
bundle exec fastlane match appstore --readonly

if [ $? -eq 0 ]; then
  echo "✅ Certificates synced"
else
  echo "❌ Certificate sync failed"
  echo "Try: bundle exec fastlane match appstore --force"
  exit 1
fi
```

### Step 2: Increment Build Number

```bash
echo "=== Incrementing Build Number ==="

# Get latest from TestFlight
LATEST=$(bundle exec fastlane run latest_testflight_build_number \
  app_identifier:"com.rizq.app" 2>/dev/null | grep -o '[0-9]*$' || echo "0")

NEW_BUILD=$((LATEST + 1))
agvtool new-version -all $NEW_BUILD

echo "✅ Build number: $LATEST → $NEW_BUILD"
```

### Step 3: Build Archive

```bash
echo "=== Building Archive ==="

# Using fastlane gym
bundle exec fastlane gym \
  --scheme "RIZQ" \
  --export_method "app-store" \
  --output_directory "build" \
  --output_name "RIZQ.ipa" \
  --clean \
  --silent

if [ $? -eq 0 ]; then
  echo "✅ Archive created: build/RIZQ.ipa"
  ls -lh build/RIZQ.ipa
else
  echo "❌ Archive build failed"
  exit 1
fi
```

### Step 4: Upload to TestFlight

```bash
echo "=== Uploading to TestFlight ==="

bundle exec fastlane pilot upload \
  --ipa "build/RIZQ.ipa" \
  --skip_waiting_for_build_processing

if [ $? -eq 0 ]; then
  echo "✅ Upload complete"
else
  echo "❌ Upload failed"
  exit 1
fi
```

### Step 5: Wait for Processing (Optional)

```bash
echo "=== Waiting for Processing ==="
echo "Build is processing on Apple's servers..."
echo "This typically takes 10-30 minutes."

# Poll for completion
bundle exec fastlane pilot builds \
  --wait_for_build_processing \
  --wait_processing_interval 60

echo "✅ Build processing complete"
```

### Step 6: Distribute (Optional)

If `distribute=true`:

```bash
echo "=== Distributing to {{ group }} ==="

bundle exec fastlane pilot distribute \
  --groups "{{ group }}" \
  --changelog "{{ changelog }}" \
  --distribute_external false

echo "✅ Distributed to {{ group }}"
```

### Step 7: Git Commit & Tag

```bash
echo "=== Committing Version Bump ==="

VERSION=$(agvtool what-marketing-version -terse1)
BUILD=$(agvtool what-version -terse)

git add -A
git commit -m "Build $BUILD for TestFlight

🤖 Generated with Claude Code"

git tag "testflight/v${VERSION}/${BUILD}"
git push origin HEAD --tags

echo "✅ Tagged: testflight/v${VERSION}/${BUILD}"
```

---

## Complete fastlane Lane

If using fastlane exclusively:

```bash
# Simple one-liner
bundle exec fastlane beta

# Or with options
bundle exec fastlane beta distribute_external:false
```

Where `beta` lane in Fastfile does all the above steps.

---

## Manual Upload Alternative

If fastlane isn't configured:

```bash
# 1. Build archive
xcodebuild archive \
  -project RIZQ.xcodeproj \
  -scheme RIZQ \
  -configuration Release \
  -archivePath build/RIZQ.xcarchive \
  -destination 'generic/platform=iOS'

# 2. Export IPA
xcodebuild -exportArchive \
  -archivePath build/RIZQ.xcarchive \
  -exportPath build \
  -exportOptionsPlist ExportOptions.plist

# 3. Upload via altool
xcrun altool --upload-app \
  --file build/RIZQ.ipa \
  --type ios \
  --apiKey $APP_STORE_CONNECT_API_KEY_KEY_ID \
  --apiIssuer $APP_STORE_CONNECT_API_KEY_ISSUER_ID
```

---

## Troubleshooting

### "No signing certificate"

```bash
# Re-sync certificates
bundle exec fastlane match appstore --force

# Clear Xcode cache
rm -rf ~/Library/Developer/Xcode/DerivedData
```

### "Build number already exists"

```bash
# Force higher build number
LATEST=$(bundle exec fastlane run latest_testflight_build_number app_identifier:"com.rizq.app" | grep -o '[0-9]*$')
agvtool new-version -all $((LATEST + 1))
```

### "Invalid binary"

```bash
# Validate before upload
xcrun altool --validate-app \
  --file build/RIZQ.ipa \
  --type ios \
  --apiKey $KEY_ID \
  --apiIssuer $ISSUER_ID
```

### "Missing compliance"

This means `ITSAppUsesNonExemptEncryption` wasn't in the build. Fix Info.plist and rebuild:

```bash
/usr/libexec/PlistBuddy -c "Add :ITSAppUsesNonExemptEncryption bool false" RIZQ/Info.plist
bundle exec fastlane beta
```

---

## Success Output

```
╔═══════════════════════════════════════════════════════╗
║           TESTFLIGHT SUBMISSION COMPLETE              ║
╠═══════════════════════════════════════════════════════╣
║ Version              │ 1.2.0                          ║
║ Build                │ 47                             ║
║ Archive Size         │ 23.4 MB                        ║
║ Upload Time          │ 2m 34s                         ║
║ Status               │ Processing                     ║
╠═══════════════════════════════════════════════════════╣
║ Git Tag              │ testflight/v1.2.0/47           ║
╚═══════════════════════════════════════════════════════╝

⏳ Build is processing on Apple's servers (10-30 min)

Next Steps:
1. Check status: App Store Connect → TestFlight
2. Once processed, distribute to testers:
   bundle exec fastlane pilot distribute --groups "Beta Testers"
3. For external testers (first build): Beta App Review required (24-48h)
```

---

## Post-Submission

After successful upload:

1. **Monitor processing** in App Store Connect
2. **Add test notes** for this build
3. **Distribute to testers** when ready
4. **Collect feedback** from TestFlight app

Use the **testflight-manager** agent for post-submission tasks.
