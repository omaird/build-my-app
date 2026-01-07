---
name: setup-fastlane
description: Initialize fastlane with match and deliver for CI/CD
allowed_tools:
  - Read
  - Write
  - Edit
  - Bash
  - Glob
arguments:
  - name: bundle_id
    description: App bundle identifier (e.g., com.rizq.app)
    required: true
  - name: team_id
    description: Apple Developer Team ID
    required: true
---

# Setup fastlane

Initialize fastlane for automated builds and App Store deployment.

## Prerequisites

1. Apple Developer account
2. App Store Connect access
3. Xcode installed
4. Ruby installed (via Homebrew recommended)

## Files Created

```
fastlane/
├── Appfile           # App identifiers
├── Fastfile          # Lane definitions
├── Matchfile         # Code signing config
├── Deliverfile       # App Store metadata config
├── Pluginfile        # fastlane plugins
└── metadata/         # App Store metadata
    └── en-US/
        ├── name.txt
        ├── subtitle.txt
        ├── description.txt
        ├── keywords.txt
        └── release_notes.txt
Gemfile               # Ruby dependencies
```

## Setup Commands

```bash
# Install bundler if needed
gem install bundler

# Create Gemfile
cat > Gemfile << 'EOF'
source "https://rubygems.org"

gem "fastlane"

plugins_path = File.join(File.dirname(__FILE__), 'fastlane', 'Pluginfile')
eval_gemfile(plugins_path) if File.exist?(plugins_path)
EOF

# Install gems
bundle install

# Initialize fastlane
bundle exec fastlane init

# Initialize match (code signing)
bundle exec fastlane match init
```

## Configuration Details

### Appfile

```ruby
app_identifier("{{ bundle_id }}")
apple_id("your-apple-id@example.com")  # Update this
itc_team_id("123456789")               # App Store Connect Team ID
team_id("{{ team_id }}")
```

### Matchfile

```ruby
git_url("git@github.com:your-org/certificates.git")  # Update this
storage_mode("git")
type("appstore")
app_identifier(["{{ bundle_id }}", "{{ bundle_id }}.widget"])
```

## Code Signing Setup

1. **Create certificate repository**:
   ```bash
   # Create private GitHub repo for certificates
   gh repo create certificates --private
   ```

2. **Generate certificates**:
   ```bash
   # Development certificates
   bundle exec fastlane match development

   # App Store certificates
   bundle exec fastlane match appstore
   ```

3. **Add device for testing**:
   ```bash
   bundle exec fastlane match development --force_for_new_devices
   ```

## App Store Connect API Key

1. Go to App Store Connect → Users and Access → Keys
2. Generate key with "App Manager" role
3. Download .p8 file
4. Store as environment variables:
   - `APP_STORE_CONNECT_API_KEY_KEY_ID`
   - `APP_STORE_CONNECT_API_KEY_ISSUER_ID`
   - `APP_STORE_CONNECT_API_KEY_KEY` (contents of .p8)

## Available Lanes

After setup, these lanes are available:

| Lane | Command | Purpose |
|------|---------|---------|
| test | `bundle exec fastlane test` | Run unit tests |
| beta | `bundle exec fastlane beta` | Deploy to TestFlight |
| release | `bundle exec fastlane release` | Deploy to App Store |
| sync_dev_certs | `bundle exec fastlane sync_dev_certs` | Sync development certificates |
| sync_appstore_certs | `bundle exec fastlane sync_appstore_certs` | Sync App Store certificates |
| bump_build | `bundle exec fastlane bump_build` | Increment build number |
| bump_version | `bundle exec fastlane bump_version type:minor` | Increment version |

## GitHub Actions Integration

After setup, create workflows:

1. `.github/workflows/test.yml` - Run tests on PRs
2. `.github/workflows/beta.yml` - Deploy to TestFlight on main push
3. `.github/workflows/release.yml` - Deploy to App Store on release

Required GitHub secrets:
- `ASC_KEY_ID`
- `ASC_ISSUER_ID`
- `ASC_PRIVATE_KEY`
- `MATCH_PASSWORD`
- `MATCH_GIT_PRIVATE_KEY`

## Next Steps

1. Update Appfile with your Apple ID
2. Create certificate repository
3. Run `bundle exec fastlane match appstore`
4. Set up GitHub secrets
5. Create GitHub Actions workflows
