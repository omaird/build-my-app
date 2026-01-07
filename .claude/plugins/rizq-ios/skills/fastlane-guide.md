---
name: fastlane-guide
description: "fastlane configuration for iOS CI/CD: lanes, match for code signing, pilot for TestFlight, deliver for App Store"
---

# fastlane Guide for iOS

This skill provides patterns for configuring fastlane for the RIZQ iOS app CI/CD pipeline.

---

## Installation & Setup

### Install fastlane

```bash
# Using Homebrew (recommended)
brew install fastlane

# Or using RubyGems
gem install fastlane

# Or using Bundler (best for CI)
bundle init
echo 'gem "fastlane"' >> Gemfile
bundle install
```

### Initialize fastlane

```bash
cd /path/to/ios/project
fastlane init

# Choose option 4: Manual setup
# This creates fastlane/ directory with Fastfile and Appfile
```

### Project Structure

```
RIZQ/
├── RIZQ.xcodeproj
├── RIZQ/
├── RIZQTests/
├── fastlane/
│   ├── Appfile           # App identifiers and Apple ID
│   ├── Fastfile          # Lane definitions
│   ├── Matchfile         # Code signing config
│   ├── Deliverfile       # App Store metadata config
│   ├── Gymfile           # Build settings
│   ├── Pluginfile        # fastlane plugins
│   ├── metadata/         # App Store metadata
│   └── screenshots/      # App Store screenshots
├── Gemfile               # Ruby dependencies
└── Gemfile.lock
```

---

## Appfile Configuration

```ruby
# fastlane/Appfile

# App Identifier (Bundle ID)
app_identifier("com.rizq.app")

# Your Apple Developer Account email
apple_id("developer@rizq.app")

# Team ID from Apple Developer Portal
team_id("XXXXXXXXXX")

# App Store Connect Team ID (if different from Dev Portal)
itc_team_id("XXXXXXXXXX")

# For multiple apps/environments
for_platform :ios do
  for_lane :beta do
    app_identifier("com.rizq.app.beta")
  end

  for_lane :release do
    app_identifier("com.rizq.app")
  end
end
```

---

## Fastfile - Lane Definitions

### Complete Fastfile

```ruby
# fastlane/Fastfile

default_platform(:ios)

platform :ios do

  # ============================================
  # SETUP LANES
  # ============================================

  desc "Install dependencies and certificates"
  lane :setup do
    # Sync code signing certificates
    match(type: "development", readonly: true)
    match(type: "appstore", readonly: true)

    # Install CocoaPods if needed
    cocoapods if File.exist?("Podfile")
  end

  # ============================================
  # BUILD LANES
  # ============================================

  desc "Build for testing"
  lane :build_for_testing do
    scan(
      scheme: "RIZQ",
      build_for_testing: true,
      derived_data_path: "build/DerivedData"
    )
  end

  desc "Run unit tests"
  lane :test do
    scan(
      scheme: "RIZQ",
      devices: ["iPhone 15 Pro"],
      code_coverage: true,
      output_directory: "build/test_output",
      result_bundle: true
    )
  end

  desc "Run snapshot tests"
  lane :snapshot_tests do
    scan(
      scheme: "RIZQSnapshotTests",
      devices: ["iPhone 15 Pro", "iPhone SE (3rd generation)"],
      result_bundle: true
    )
  end

  # ============================================
  # BETA LANES (TestFlight)
  # ============================================

  desc "Build and upload to TestFlight"
  lane :beta do |options|
    # Ensure clean git state
    ensure_git_status_clean unless options[:skip_git_check]

    # Sync certificates
    match(type: "appstore", readonly: true)

    # Increment build number
    increment_build_number(
      build_number: latest_testflight_build_number + 1
    )

    # Build
    gym(
      scheme: "RIZQ",
      export_method: "app-store",
      output_directory: "build",
      output_name: "RIZQ.ipa",
      clean: true,
      include_bitcode: false,
      include_symbols: true
    )

    # Upload to TestFlight
    pilot(
      skip_waiting_for_build_processing: options[:skip_wait] || false,
      skip_submission: options[:skip_submit] || false,
      distribute_external: false,
      notify_external_testers: false
    )

    # Commit version bump
    commit_version_bump(
      message: "Build #{lane_context[SharedValues::BUILD_NUMBER]} for TestFlight",
      xcodeproj: "RIZQ.xcodeproj"
    )

    # Tag
    add_git_tag(
      tag: "testflight/#{get_version_number}/#{get_build_number}"
    )

    # Push
    push_to_git_remote if options[:push]
  end

  desc "Distribute latest build to testers"
  lane :distribute do |options|
    groups = options[:groups] || ["Internal Testers"]
    changelog = options[:changelog] || "Bug fixes and improvements"

    pilot(
      distribute_external: true,
      groups: groups,
      changelog: changelog,
      notify_external_testers: true
    )
  end

  # ============================================
  # RELEASE LANES (App Store)
  # ============================================

  desc "Build and submit to App Store"
  lane :release do |options|
    # Ensure clean git state
    ensure_git_status_clean

    # Sync certificates
    match(type: "appstore", readonly: true)

    # Increment version if specified
    if options[:bump]
      increment_version_number(
        bump_type: options[:bump] # "patch", "minor", "major"
      )
    end

    # Reset build number for new version
    increment_build_number(build_number: 1)

    # Build
    gym(
      scheme: "RIZQ",
      export_method: "app-store",
      output_directory: "build",
      output_name: "RIZQ.ipa"
    )

    # Upload to App Store Connect
    deliver(
      submit_for_review: options[:submit] || false,
      automatic_release: options[:auto_release] || false,
      force: true, # Skip HTML preview
      skip_screenshots: options[:skip_screenshots] || false,
      skip_metadata: options[:skip_metadata] || false
    )

    # Git operations
    commit_version_bump(
      message: "Release #{get_version_number}",
      xcodeproj: "RIZQ.xcodeproj"
    )

    add_git_tag(tag: "v#{get_version_number}")

    push_to_git_remote if options[:push]
  end

  desc "Download dSYMs from App Store Connect"
  lane :dsyms do
    download_dsyms(
      version: "latest",
      app_identifier: "com.rizq.app"
    )

    # Upload to crash reporting service (e.g., Firebase Crashlytics)
    # upload_symbols_to_crashlytics(dsym_path: lane_context[SharedValues::DSYM_OUTPUT_PATH])
  end

  # ============================================
  # CODE SIGNING LANES
  # ============================================

  desc "Sync development certificates"
  lane :certs_dev do
    match(type: "development", force_for_new_devices: true)
  end

  desc "Sync App Store certificates"
  lane :certs_appstore do
    match(type: "appstore")
  end

  desc "Revoke and regenerate all certificates"
  lane :certs_nuke do
    match_nuke(type: "development")
    match_nuke(type: "appstore")
    match(type: "development", force: true)
    match(type: "appstore", force: true)
  end

  desc "Register new device"
  lane :register_device do |options|
    device_name = options[:name] || prompt(text: "Device name: ")
    device_udid = options[:udid] || prompt(text: "Device UDID: ")

    register_devices(
      devices: {
        device_name => device_udid
      }
    )

    # Re-generate development provisioning profile
    match(type: "development", force_for_new_devices: true)
  end

  # ============================================
  # UTILITY LANES
  # ============================================

  desc "Increment build number"
  lane :bump_build do
    increment_build_number
    commit_version_bump(
      message: "Bump build number to #{get_build_number}",
      xcodeproj: "RIZQ.xcodeproj"
    )
  end

  desc "Increment version number"
  lane :bump_version do |options|
    bump_type = options[:type] || "patch"
    increment_version_number(bump_type: bump_type)
    commit_version_bump(
      message: "Bump version to #{get_version_number}",
      xcodeproj: "RIZQ.xcodeproj"
    )
  end

  desc "Generate App Store screenshots"
  lane :screenshots do
    capture_screenshots(
      scheme: "RIZQUITests",
      devices: [
        "iPhone 15 Pro Max",
        "iPhone 15 Pro",
        "iPhone SE (3rd generation)",
        "iPad Pro (12.9-inch) (6th generation)"
      ],
      languages: ["en-US"],
      output_directory: "fastlane/screenshots",
      clear_previous_screenshots: true
    )
    frame_screenshots(white: true)
  end

  # ============================================
  # ERROR HANDLING
  # ============================================

  error do |lane, exception|
    # Slack notification on failure
    # slack(
    #   message: "Lane #{lane} failed with #{exception.message}",
    #   success: false
    # )
  end
end
```

---

## match - Code Signing

### Matchfile Configuration

```ruby
# fastlane/Matchfile

# Git repository for certificates
git_url("git@github.com:rizq-app/certificates.git")

# Storage mode (git, s3, google_cloud)
storage_mode("git")

# App identifiers to manage
app_identifier(["com.rizq.app", "com.rizq.app.widget"])

# Apple Developer account
username("developer@rizq.app")

# Team ID
team_id("XXXXXXXXXX")

# Keychain (for CI)
keychain_name("fastlane_keychain")
keychain_password(ENV["MATCH_KEYCHAIN_PASSWORD"])

# Certificate types
type("appstore") # or "development", "adhoc", "enterprise"

# Clone branch
git_branch("main")

# Read-only mode (recommended for CI)
readonly(true)

# Force regeneration
force(false)

# Platform
platform("ios")
```

### Initial Setup

```bash
# 1. Create private Git repository for certificates
# (on GitHub, GitLab, or Bitbucket)

# 2. Initialize match
fastlane match init

# 3. Generate certificates (run once, locally)
fastlane match development
fastlane match appstore

# 4. On CI/other machines, use readonly mode
fastlane match appstore --readonly
```

### match Usage

```ruby
# In Fastfile

# Development certificates
match(type: "development")

# App Store certificates
match(type: "appstore")

# Force regeneration
match(type: "appstore", force: true)

# For new devices
match(type: "development", force_for_new_devices: true)

# Readonly (CI)
match(type: "appstore", readonly: true)
```

---

## gym - Build Configuration

### Gymfile

```ruby
# fastlane/Gymfile

# Scheme to build
scheme("RIZQ")

# Workspace or project
# workspace("RIZQ.xcworkspace")  # If using CocoaPods
project("RIZQ.xcodeproj")

# Configuration
configuration("Release")

# Export method: app-store, ad-hoc, development, enterprise
export_method("app-store")

# Output settings
output_directory("build")
output_name("RIZQ")

# Build settings
clean(true)
include_bitcode(false)
include_symbols(true)

# Archive path
archive_path("build/RIZQ.xcarchive")

# Derived data
derived_data_path("build/DerivedData")

# Destination
destination("generic/platform=iOS")

# Export options
export_options({
  provisioningProfiles: {
    "com.rizq.app" => "match AppStore com.rizq.app",
    "com.rizq.app.widget" => "match AppStore com.rizq.app.widget"
  },
  signingStyle: "manual",
  teamID: "XXXXXXXXXX"
})

# Suppress xcodebuild output
suppress_xcode_output(true)

# Xcode toolchain
xcargs("-allowProvisioningUpdates")
```

---

## pilot - TestFlight

### Common pilot Commands

```ruby
# Upload to TestFlight
pilot(
  ipa: "build/RIZQ.ipa",
  skip_waiting_for_build_processing: true
)

# List builds
pilot(
  list: true
)

# Distribute to group
pilot(
  distribute_external: true,
  groups: ["Beta Testers"],
  changelog: "What's new in this version"
)

# Add tester
pilot(
  add_tester: true,
  email: "tester@example.com",
  first_name: "Test",
  last_name: "User",
  groups: ["Beta Testers"]
)

# Remove tester
pilot(
  remove_tester: true,
  email: "tester@example.com"
)
```

### TestFlight Submission Options

```ruby
pilot(
  # IPA file
  ipa: "build/RIZQ.ipa",

  # Skip build processing wait
  skip_waiting_for_build_processing: false,

  # Skip TestFlight upload (just submit existing)
  skip_submission: false,

  # Distribute to external testers
  distribute_external: true,

  # Notify testers
  notify_external_testers: true,

  # Tester groups
  groups: ["Internal Testers", "Beta Testers"],

  # What's new
  changelog: "Bug fixes and improvements",

  # Beta App Review info (for first external build)
  beta_app_review_info: {
    contact_email: "support@rizq.app",
    contact_first_name: "RIZQ",
    contact_last_name: "Support",
    contact_phone: "+1-555-555-5555",
    demo_account_name: "demo@rizq.app",
    demo_account_password: "demo123",
    notes: "Use demo account to test all features"
  },

  # Localized build info
  localized_build_info: {
    "en-US" => {
      whats_new: "New features and bug fixes"
    }
  }
)
```

---

## deliver - App Store

### Deliverfile

```ruby
# fastlane/Deliverfile

# App identifier
app_identifier("com.rizq.app")

# Metadata path
metadata_path("./fastlane/metadata")

# Screenshots path
screenshots_path("./fastlane/screenshots")

# App review info
app_review_information(
  first_name: "RIZQ",
  last_name: "Support",
  phone_number: "+1-555-555-5555",
  email_address: "support@rizq.app",
  demo_user: "demo@rizq.app",
  demo_password: "demo123",
  notes: "Use demo account to test all features"
)

# Submission info
submission_information({
  add_id_info_limits_tracking: true,
  add_id_info_serves_ads: false,
  add_id_info_tracks_action: true,
  add_id_info_tracks_install: true,
  add_id_info_uses_idfa: false,
  content_rights_has_rights: true,
  content_rights_contains_third_party_content: false,
  export_compliance_platform: "ios",
  export_compliance_compliance_required: false,
  export_compliance_encryption_updated: false,
  export_compliance_uses_encryption: false,
  export_compliance_is_exempt: false,
  export_compliance_contains_third_party_cryptography: false,
  export_compliance_contains_proprietary_cryptography: false
})

# Categories
primary_category("Lifestyle")
secondary_category("Health & Fitness")

# Rating
app_rating_config_path("./fastlane/rating_config.json")

# Price tier (0 = Free)
price_tier(0)

# Availability
available_primary_locale("en-US")

# Copyright
copyright("#{Time.now.year} RIZQ App")

# Auto-release
automatic_release(false)
phased_release(true)

# Skip options
skip_screenshots(false)
skip_metadata(false)
skip_app_version_update(false)

# Force submission
force(true)

# Run precheck
run_precheck_before_submit(true)
precheck_include_in_app_purchases(false)
```

### Metadata Structure

```
fastlane/metadata/
├── en-US/
│   ├── name.txt                    # App name (30 chars)
│   ├── subtitle.txt                # Subtitle (30 chars)
│   ├── description.txt             # Full description (4000 chars)
│   ├── keywords.txt                # Keywords (100 chars, comma-separated)
│   ├── promotional_text.txt        # Promotional text (170 chars)
│   ├── release_notes.txt           # What's new (4000 chars)
│   ├── support_url.txt             # Support URL
│   ├── marketing_url.txt           # Marketing URL
│   └── privacy_url.txt             # Privacy policy URL
├── ar-SA/                          # Arabic
│   └── ...
├── copyright.txt                   # Copyright notice
├── primary_category.txt            # Primary category
├── secondary_category.txt          # Secondary category
└── review_information/
    ├── first_name.txt
    ├── last_name.txt
    ├── phone_number.txt
    ├── email_address.txt
    ├── demo_user.txt
    ├── demo_password.txt
    └── notes.txt
```

### Example Metadata Files

```text
# fastlane/metadata/en-US/name.txt
RIZQ - Dua Practice

# fastlane/metadata/en-US/subtitle.txt
Build Your Daily Dua Habit

# fastlane/metadata/en-US/description.txt
RIZQ helps you build a consistent dua (supplication) practice with
authentic Islamic prayers and a beautiful, gamified experience.

Features:
• Authentic duas with Arabic text, transliteration, and translation
• Curated journeys for different life aspects
• Daily adhkar for morning and evening
• XP and streaks to stay motivated
• Offline support
• Beautiful Islamic aesthetic

Start your spiritual journey today with RIZQ.

# fastlane/metadata/en-US/keywords.txt
dua,islamic,prayer,muslim,adhkar,quran,spiritual,meditation,habit

# fastlane/metadata/en-US/release_notes.txt
• New morning adhkar journey
• Improved streak tracking
• Bug fixes and performance improvements
```

---

## GitHub Actions Integration

### CI/CD Workflow

```yaml
# .github/workflows/ios.yml

name: iOS CI/CD

on:
  push:
    branches: [main, develop]
  pull_request:
    branches: [main]

env:
  MATCH_PASSWORD: ${{ secrets.MATCH_PASSWORD }}
  MATCH_GIT_BASIC_AUTHORIZATION: ${{ secrets.MATCH_GIT_BASIC_AUTHORIZATION }}
  APP_STORE_CONNECT_API_KEY_KEY_ID: ${{ secrets.ASC_KEY_ID }}
  APP_STORE_CONNECT_API_KEY_ISSUER_ID: ${{ secrets.ASC_ISSUER_ID }}
  APP_STORE_CONNECT_API_KEY_KEY: ${{ secrets.ASC_KEY }}

jobs:
  test:
    name: Build & Test
    runs-on: macos-14
    steps:
      - uses: actions/checkout@v4

      - name: Select Xcode
        run: sudo xcode-select -s /Applications/Xcode_15.2.app

      - name: Setup Ruby
        uses: ruby/setup-ruby@v1
        with:
          ruby-version: '3.2'
          bundler-cache: true

      - name: Install dependencies
        run: bundle install

      - name: Run tests
        run: bundle exec fastlane test

      - name: Upload test results
        uses: actions/upload-artifact@v4
        if: always()
        with:
          name: test-results
          path: build/test_output

  beta:
    name: Deploy to TestFlight
    needs: test
    runs-on: macos-14
    if: github.ref == 'refs/heads/develop'
    steps:
      - uses: actions/checkout@v4

      - name: Select Xcode
        run: sudo xcode-select -s /Applications/Xcode_15.2.app

      - name: Setup Ruby
        uses: ruby/setup-ruby@v1
        with:
          ruby-version: '3.2'
          bundler-cache: true

      - name: Install dependencies
        run: bundle install

      - name: Setup keychain
        run: |
          security create-keychain -p "$KEYCHAIN_PASSWORD" fastlane.keychain
          security default-keychain -s fastlane.keychain
          security unlock-keychain -p "$KEYCHAIN_PASSWORD" fastlane.keychain
          security set-keychain-settings -t 3600 -u fastlane.keychain
        env:
          KEYCHAIN_PASSWORD: ${{ secrets.KEYCHAIN_PASSWORD }}

      - name: Deploy to TestFlight
        run: bundle exec fastlane beta skip_git_check:true

  release:
    name: Deploy to App Store
    runs-on: macos-14
    if: github.ref == 'refs/heads/main' && startsWith(github.event.head_commit.message, 'Release')
    steps:
      - uses: actions/checkout@v4

      - name: Select Xcode
        run: sudo xcode-select -s /Applications/Xcode_15.2.app

      - name: Setup Ruby
        uses: ruby/setup-ruby@v1
        with:
          ruby-version: '3.2'
          bundler-cache: true

      - name: Install dependencies
        run: bundle install

      - name: Setup keychain
        run: |
          security create-keychain -p "$KEYCHAIN_PASSWORD" fastlane.keychain
          security default-keychain -s fastlane.keychain
          security unlock-keychain -p "$KEYCHAIN_PASSWORD" fastlane.keychain
        env:
          KEYCHAIN_PASSWORD: ${{ secrets.KEYCHAIN_PASSWORD }}

      - name: Deploy to App Store
        run: bundle exec fastlane release submit:true
```

### App Store Connect API Key

```ruby
# In Fastfile, use API key for CI

lane :setup_api_key do
  app_store_connect_api_key(
    key_id: ENV["APP_STORE_CONNECT_API_KEY_KEY_ID"],
    issuer_id: ENV["APP_STORE_CONNECT_API_KEY_ISSUER_ID"],
    key_content: ENV["APP_STORE_CONNECT_API_KEY_KEY"],
    is_key_content_base64: true
  )
end
```

---

## Useful fastlane Plugins

### Pluginfile

```ruby
# fastlane/Pluginfile

# Badge plugin (add build info to app icon)
gem 'fastlane-plugin-badge'

# Versioning plugin
gem 'fastlane-plugin-versioning'

# Firebase distribution
gem 'fastlane-plugin-firebase_app_distribution'

# Slack notifications
gem 'fastlane-plugin-slack'

# Changelog from Git
gem 'fastlane-plugin-changelog'
```

### Install Plugins

```bash
fastlane add_plugin badge
fastlane add_plugin versioning
```

---

## Environment Variables

### Required Environment Variables

```bash
# For match
export MATCH_PASSWORD="your-match-encryption-password"
export MATCH_GIT_BASIC_AUTHORIZATION="base64-encoded-credentials"

# For App Store Connect API
export APP_STORE_CONNECT_API_KEY_KEY_ID="ABC123"
export APP_STORE_CONNECT_API_KEY_ISSUER_ID="xxx-xxx-xxx"
export APP_STORE_CONNECT_API_KEY_KEY="-----BEGIN PRIVATE KEY-----\n..."

# For Keychain (CI)
export KEYCHAIN_NAME="fastlane_keychain"
export KEYCHAIN_PASSWORD="temporary-password"

# App-specific
export TEAM_ID="XXXXXXXXXX"
export APP_IDENTIFIER="com.rizq.app"
```

### .env Files

```bash
# fastlane/.env.default
TEAM_ID=XXXXXXXXXX
APP_IDENTIFIER=com.rizq.app
SLACK_URL=https://hooks.slack.com/services/xxx

# fastlane/.env.beta
APP_IDENTIFIER=com.rizq.app.beta
SCHEME=RIZQ-Beta

# fastlane/.env.production
APP_IDENTIFIER=com.rizq.app
SCHEME=RIZQ
```

---

## Common Commands Reference

```bash
# === CERTIFICATES ===
fastlane match development              # Sync dev certs
fastlane match appstore                 # Sync App Store certs
fastlane match appstore --readonly      # Read-only (CI)

# === BUILD ===
fastlane gym                            # Build IPA
fastlane build_for_testing              # Build for tests

# === TEST ===
fastlane test                           # Run tests
fastlane snapshot                       # Capture screenshots

# === TESTFLIGHT ===
fastlane beta                           # Build + upload
fastlane pilot upload                   # Upload existing IPA
fastlane pilot list                     # List builds
fastlane pilot distribute               # Distribute to testers

# === APP STORE ===
fastlane deliver                        # Upload metadata/screenshots
fastlane release                        # Full release flow

# === UTILITIES ===
fastlane increment_build_number         # Bump build
fastlane increment_version_number       # Bump version
fastlane precheck                       # Validate metadata
```
