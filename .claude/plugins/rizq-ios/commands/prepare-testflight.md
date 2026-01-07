---
name: prepare-testflight
description: Validate iOS project readiness for TestFlight submission
allowed_tools:
  - Bash
  - Read
  - Glob
  - Grep
arguments:
  - name: fix
    description: "Automatically fix common issues (true/false)"
    required: false
---

# Prepare for TestFlight

Run comprehensive validation checks to ensure the iOS project is ready for TestFlight submission.

## Auto-Fix Mode: {{ fix | default: "false" }}

When `fix=true`, the command will attempt to automatically fix common issues like missing Info.plist keys.

---

## Validation Steps

### 1. Project Structure

```bash
echo "=== Project Structure ==="

# Check for Xcode project
if ls *.xcodeproj 1> /dev/null 2>&1; then
  echo "✅ Xcode project found"
  ls *.xcodeproj
else
  echo "❌ No Xcode project found"
fi

# Check for workspace (if using SPM or CocoaPods)
if ls *.xcworkspace 1> /dev/null 2>&1; then
  echo "✅ Workspace found"
  ls *.xcworkspace
fi

# Check fastlane setup
if [ -d "fastlane" ]; then
  echo "✅ fastlane directory exists"
else
  echo "⚠️  fastlane not configured"
fi
```

### 2. Version & Build Number

```bash
echo "=== Version Info ==="

# Get marketing version
VERSION=$(agvtool what-marketing-version -terse1 2>/dev/null || echo "not found")
echo "Marketing Version: $VERSION"

# Get build number
BUILD=$(agvtool what-version -terse 2>/dev/null || echo "not found")
echo "Build Number: $BUILD"

# Check if build needs incrementing
if command -v bundle &> /dev/null && [ -f "fastlane/Fastfile" ]; then
  LATEST_TF=$(bundle exec fastlane run latest_testflight_build_number app_identifier:"com.rizq.app" 2>/dev/null | grep -o '[0-9]*$' || echo "0")
  echo "Latest TestFlight Build: $LATEST_TF"

  if [ "$BUILD" -le "$LATEST_TF" ]; then
    echo "⚠️  Build number needs incrementing (current: $BUILD, TestFlight: $LATEST_TF)"
  else
    echo "✅ Build number is ahead of TestFlight"
  fi
fi
```

### 3. App Icons

```bash
echo "=== App Icons ==="

ICON_PATH=$(find . -name "AppIcon.appiconset" -type d | head -1)

if [ -n "$ICON_PATH" ]; then
  echo "✅ AppIcon.appiconset found: $ICON_PATH"

  # Count icon files
  ICON_COUNT=$(ls "$ICON_PATH"/*.png 2>/dev/null | wc -l | tr -d ' ')
  echo "   PNG files: $ICON_COUNT"

  # Check for 1024pt icon (required for App Store)
  if ls "$ICON_PATH"/*1024* 1> /dev/null 2>&1; then
    echo "✅ 1024x1024 App Store icon present"
  else
    echo "❌ Missing 1024x1024 App Store icon"
  fi
else
  echo "❌ AppIcon.appiconset not found"
fi
```

### 4. Info.plist Validation

```bash
echo "=== Info.plist ==="

INFO_PLIST=$(find . -name "Info.plist" -path "*/RIZQ/*" ! -path "*/Tests/*" | head -1)

if [ -n "$INFO_PLIST" ]; then
  echo "Found: $INFO_PLIST"

  # Required keys
  echo ""
  echo "Required Keys:"

  # Bundle Display Name
  DISPLAY_NAME=$(/usr/libexec/PlistBuddy -c "Print :CFBundleDisplayName" "$INFO_PLIST" 2>/dev/null)
  if [ -n "$DISPLAY_NAME" ]; then
    echo "✅ CFBundleDisplayName: $DISPLAY_NAME"
  else
    echo "⚠️  CFBundleDisplayName not set (using CFBundleName as fallback)"
  fi

  # Version
  VERSION=$(/usr/libexec/PlistBuddy -c "Print :CFBundleShortVersionString" "$INFO_PLIST" 2>/dev/null)
  if [ -n "$VERSION" ]; then
    echo "✅ CFBundleShortVersionString: $VERSION"
  else
    echo "❌ CFBundleShortVersionString missing"
  fi

  # Build
  BUILD=$(/usr/libexec/PlistBuddy -c "Print :CFBundleVersion" "$INFO_PLIST" 2>/dev/null)
  if [ -n "$BUILD" ]; then
    echo "✅ CFBundleVersion: $BUILD"
  else
    echo "❌ CFBundleVersion missing"
  fi

  # Encryption
  ENCRYPTION=$(/usr/libexec/PlistBuddy -c "Print :ITSAppUsesNonExemptEncryption" "$INFO_PLIST" 2>/dev/null)
  if [ -n "$ENCRYPTION" ]; then
    echo "✅ ITSAppUsesNonExemptEncryption: $ENCRYPTION"
  else
    echo "❌ ITSAppUsesNonExemptEncryption missing (will cause 'Missing Compliance' status)"
  fi
else
  echo "❌ Info.plist not found"
fi
```

### 5. Privacy Manifest (iOS 17+)

```bash
echo "=== Privacy Manifest ==="

PRIVACY_MANIFEST=$(find . -name "PrivacyInfo.xcprivacy" | head -1)

if [ -n "$PRIVACY_MANIFEST" ]; then
  echo "✅ PrivacyInfo.xcprivacy found: $PRIVACY_MANIFEST"

  # Check for tracking declaration
  TRACKING=$(grep -l "NSPrivacyTracking" "$PRIVACY_MANIFEST" 2>/dev/null)
  if [ -n "$TRACKING" ]; then
    echo "✅ NSPrivacyTracking declared"
  else
    echo "⚠️  NSPrivacyTracking not declared"
  fi
else
  echo "⚠️  PrivacyInfo.xcprivacy not found (required for iOS 17+)"
fi
```

### 6. Code Signing

```bash
echo "=== Code Signing ==="

# Check for valid signing identities
IDENTITIES=$(security find-identity -v -p codesigning 2>/dev/null | grep "Apple Distribution" | wc -l | tr -d ' ')

if [ "$IDENTITIES" -gt 0 ]; then
  echo "✅ Apple Distribution certificate(s) found: $IDENTITIES"
else
  echo "❌ No Apple Distribution certificates found"
fi

# Check match configuration
if [ -f "fastlane/Matchfile" ]; then
  echo "✅ fastlane match configured"
else
  echo "⚠️  fastlane match not configured"
fi

# Check provisioning profiles
PROFILES=$(ls ~/Library/MobileDevice/Provisioning\ Profiles/*.mobileprovision 2>/dev/null | wc -l | tr -d ' ')
echo "   Provisioning profiles installed: $PROFILES"
```

### 7. fastlane Configuration

```bash
echo "=== fastlane Configuration ==="

if [ -f "Gemfile" ]; then
  echo "✅ Gemfile exists"
else
  echo "❌ Gemfile missing"
fi

if [ -f "fastlane/Fastfile" ]; then
  echo "✅ Fastfile exists"

  # Check for beta lane
  if grep -q "lane :beta" fastlane/Fastfile; then
    echo "✅ Beta lane defined"
  else
    echo "⚠️  No 'beta' lane found"
  fi
else
  echo "❌ Fastfile missing"
fi

if [ -f "fastlane/Appfile" ]; then
  echo "✅ Appfile exists"

  # Check app identifier
  APP_ID=$(grep "app_identifier" fastlane/Appfile | head -1)
  echo "   $APP_ID"
else
  echo "⚠️  Appfile missing"
fi
```

### 8. Build Test

```bash
echo "=== Build Test ==="

# Try a quick build validation
echo "Running build validation (this may take a minute)..."

xcodebuild -project RIZQ.xcodeproj \
  -scheme RIZQ \
  -configuration Release \
  -destination 'generic/platform=iOS' \
  -quiet \
  build 2>&1 | tail -5

if [ ${PIPESTATUS[0]} -eq 0 ]; then
  echo "✅ Release build succeeds"
else
  echo "❌ Release build failed"
fi
```

---

## Auto-Fix Actions

If `fix=true`, these issues will be automatically fixed:

### Fix Missing Encryption Declaration

```bash
INFO_PLIST=$(find . -name "Info.plist" -path "*/RIZQ/*" ! -path "*/Tests/*" | head -1)

# Add encryption declaration
/usr/libexec/PlistBuddy -c "Add :ITSAppUsesNonExemptEncryption bool false" "$INFO_PLIST" 2>/dev/null || \
/usr/libexec/PlistBuddy -c "Set :ITSAppUsesNonExemptEncryption false" "$INFO_PLIST"

echo "✅ Added ITSAppUsesNonExemptEncryption = false"
```

### Fix Build Number

```bash
# Increment build number
CURRENT=$(agvtool what-version -terse)
NEW=$((CURRENT + 1))
agvtool new-version -all $NEW
echo "✅ Build number incremented: $CURRENT → $NEW"
```

### Create Basic Privacy Manifest

```bash
if [ ! -f "RIZQ/PrivacyInfo.xcprivacy" ]; then
  cat > RIZQ/PrivacyInfo.xcprivacy << 'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>NSPrivacyTracking</key>
  <false/>
  <key>NSPrivacyCollectedDataTypes</key>
  <array/>
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
EOF
  echo "✅ Created PrivacyInfo.xcprivacy"
fi
```

---

## Summary Report

After running all checks, generate a summary:

```
╔═══════════════════════════════════════════════════════╗
║           TESTFLIGHT PREPARATION REPORT               ║
╠═══════════════════════════════════════════════════════╣
║ Project Structure    │ ✅ PASS                        ║
║ Version/Build        │ ✅ 1.2.0 (45)                  ║
║ App Icons            │ ✅ All sizes present           ║
║ Info.plist           │ ⚠️  Missing encryption key     ║
║ Privacy Manifest     │ ❌ Not found                   ║
║ Code Signing         │ ✅ Certificate valid           ║
║ fastlane             │ ✅ Configured                  ║
║ Build Test           │ ✅ PASS                        ║
╠═══════════════════════════════════════════════════════╣
║ OVERALL STATUS       │ ⚠️  NEEDS ATTENTION            ║
╚═══════════════════════════════════════════════════════╝

Issues to Fix:
1. Add ITSAppUsesNonExemptEncryption to Info.plist
2. Create PrivacyInfo.xcprivacy file

Run with fix=true to auto-fix these issues, or use:
  /submit-testflight

After fixing all issues.
```

---

## Next Steps

After preparation passes:

1. **Run `/submit-testflight`** to build and upload
2. **Monitor build processing** in App Store Connect
3. **Add testers** using testflight-manager agent
