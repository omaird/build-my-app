# TestFlight Setup Guide

This guide walks through the steps to submit RIZQ to TestFlight.

## Prerequisites

1. **Apple Developer Program membership** ($99/year)
   - Sign up at https://developer.apple.com/programs/

2. **Xcode installed** with command line tools

3. **Homebrew Ruby** (already configured)
   ```bash
   # Fastlane uses Homebrew Ruby at /opt/homebrew/opt/ruby/bin/ruby
   ```

## Step 1: App Store Connect API Key

Create an API key for automated uploads:

1. Go to https://appstoreconnect.apple.com/access/api
2. Click "+" to create a new key
3. Name it "Fastlane CI"
4. Select "App Manager" role
5. Download the `.p8` file

Save the key as `fastlane/AuthKey_XXXXXX.p8` (already in .gitignore)

Create `fastlane/api_key.json`:
```json
{
  "key_id": "YOUR_KEY_ID",
  "issuer_id": "YOUR_ISSUER_ID",
  "key_filepath": "fastlane/AuthKey_XXXXXX.p8"
}
```

Then update `fastlane/Appfile`:
```ruby
app_identifier("com.rizq.app")
apple_id("your@email.com")
team_id("YOUR_TEAM_ID")

# For App Store Connect API
json_key_file("fastlane/api_key.json")
```

## Step 2: Code Signing with Match

Match stores certificates in a private Git repo for team sharing.

### First-time setup:

1. Create a private Git repo for certificates (e.g., `github.com/yourorg/certificates`)

2. Update `fastlane/Matchfile`:
   ```ruby
   git_url("git@github.com:yourorg/certificates.git")
   storage_mode("git")
   type("appstore")
   app_identifier(["com.rizq.app", "com.rizq.app.widget"])
   ```

3. Run Match to create certificates:
   ```bash
   cd RIZQ-iOS
   /opt/homebrew/opt/ruby/bin/bundle exec fastlane match appstore
   ```

4. For development certificates:
   ```bash
   /opt/homebrew/opt/ruby/bin/bundle exec fastlane match development
   ```

## Step 3: Submit to TestFlight

### Quick submission:
```bash
cd RIZQ-iOS
/opt/homebrew/opt/ruby/bin/bundle exec fastlane beta
```

This will:
1. Run all tests
2. Increment build number
3. Build release IPA
4. Upload to TestFlight

### Version bump and release:
```bash
/opt/homebrew/opt/ruby/bin/bundle exec fastlane release version:1.0.1
```

## Available Fastlane Lanes

| Lane | Description |
|------|-------------|
| `test` | Run all unit and snapshot tests |
| `build` | Build release IPA |
| `beta` | Full TestFlight submission pipeline |
| `release version:X.Y.Z` | Bump version and submit |
| `certificates` | Sync code signing (read-only) |
| `add_device name:'...' udid:'...'` | Register new test device |

## Troubleshooting

### Ruby version issues
Always use Homebrew Ruby:
```bash
/opt/homebrew/opt/ruby/bin/bundle exec fastlane <lane>
```

### Certificate issues
Reset and re-download:
```bash
/opt/homebrew/opt/ruby/bin/bundle exec fastlane match nuke appstore
/opt/homebrew/opt/ruby/bin/bundle exec fastlane match appstore
```

### Build failures
Check logs at:
- `~/Library/Logs/scan/RIZQ-RIZQ.log`
- `fastlane/test_output/`

## CI/CD Integration (GitHub Actions)

Create `.github/workflows/testflight.yml`:
```yaml
name: TestFlight

on:
  push:
    tags:
      - 'v*'

jobs:
  deploy:
    runs-on: macos-latest
    steps:
      - uses: actions/checkout@v4

      - name: Setup Ruby
        uses: ruby/setup-ruby@v1
        with:
          ruby-version: '3.3'
          bundler-cache: true

      - name: Install dependencies
        run: bundle install

      - name: Setup certificates
        env:
          MATCH_PASSWORD: ${{ secrets.MATCH_PASSWORD }}
          MATCH_GIT_BASIC_AUTHORIZATION: ${{ secrets.MATCH_GIT_AUTH }}
        run: bundle exec fastlane certificates

      - name: Deploy to TestFlight
        env:
          APP_STORE_CONNECT_API_KEY_KEY_ID: ${{ secrets.ASC_KEY_ID }}
          APP_STORE_CONNECT_API_KEY_ISSUER_ID: ${{ secrets.ASC_ISSUER_ID }}
          APP_STORE_CONNECT_API_KEY_KEY: ${{ secrets.ASC_KEY }}
        run: bundle exec fastlane beta
```

Required GitHub Secrets:
- `MATCH_PASSWORD` - Password for Match encryption
- `MATCH_GIT_AUTH` - Base64 encoded `username:token` for Git
- `ASC_KEY_ID` - App Store Connect API Key ID
- `ASC_ISSUER_ID` - App Store Connect Issuer ID
- `ASC_KEY` - Contents of the .p8 file
