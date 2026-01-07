---
name: run-tests
description: Execute iOS tests with optional coverage reporting
arguments:
  - name: target
    description: Which tests to run
    required: false
    default: all
    options:
      - unit
      - snapshot
      - all
  - name: coverage
    description: Enable code coverage reporting
    required: false
    default: "false"
    options:
      - "true"
      - "false"
  - name: filter
    description: Optional test filter (e.g., HomeFeatureTests, *Snapshot*)
    required: false
---

# Run RIZQ iOS Tests

Execute tests for the RIZQ iOS app with the specified configuration.

## Configuration
- **Target**: {{target}}
- **Coverage**: {{coverage}}
- **Filter**: {{filter}}

## Prerequisites

Ensure the Xcode project is generated:

```bash
cd RIZQ-iOS

# Generate project if needed
if [ ! -d "RIZQ.xcodeproj" ]; then
  xcodegen generate
fi

# Install xcpretty for better output (optional)
gem install xcpretty 2>/dev/null || true
```

## Run Tests

### Target: {{target}}

{{#if (eq target "unit")}}
```bash
cd RIZQ-iOS

xcodebuild test \
  -project RIZQ.xcodeproj \
  -scheme RIZQ \
  -destination 'platform=iOS Simulator,name=iPhone 15 Pro' \
  -only-testing:RIZQTests \
  {{#if filter}}-only-testing:RIZQTests/{{filter}}{{/if}} \
  {{#if (eq coverage "true")}}-enableCodeCoverage YES \
  -resultBundlePath TestResults.xcresult{{/if}} \
  2>&1 | xcpretty --test
```
{{/if}}

{{#if (eq target "snapshot")}}
```bash
cd RIZQ-iOS

xcodebuild test \
  -project RIZQ.xcodeproj \
  -scheme RIZQ \
  -destination 'platform=iOS Simulator,name=iPhone 15 Pro' \
  -only-testing:RIZQSnapshotTests \
  {{#if filter}}-only-testing:RIZQSnapshotTests/{{filter}}{{/if}} \
  {{#if (eq coverage "true")}}-enableCodeCoverage YES \
  -resultBundlePath SnapshotResults.xcresult{{/if}} \
  2>&1 | xcpretty --test
```
{{/if}}

{{#if (eq target "all")}}
```bash
cd RIZQ-iOS

xcodebuild test \
  -project RIZQ.xcodeproj \
  -scheme RIZQ \
  -destination 'platform=iOS Simulator,name=iPhone 15 Pro' \
  {{#if filter}}-only-testing:RIZQTests/{{filter}} -only-testing:RIZQSnapshotTests/{{filter}}{{/if}} \
  {{#if (eq coverage "true")}}-enableCodeCoverage YES \
  -resultBundlePath TestResults.xcresult{{/if}} \
  2>&1 | xcpretty --test
```
{{/if}}

## Practical Commands to Execute

Run the appropriate command based on your parameters:

```bash
cd RIZQ-iOS

# Unit tests only
xcodebuild test \
  -project RIZQ.xcodeproj \
  -scheme RIZQ \
  -destination 'platform=iOS Simulator,name=iPhone 15 Pro' \
  -only-testing:RIZQTests \
  2>&1 | xcpretty --test || xcodebuild test -project RIZQ.xcodeproj -scheme RIZQ -destination 'platform=iOS Simulator,name=iPhone 15 Pro' -only-testing:RIZQTests

# Snapshot tests only
xcodebuild test \
  -project RIZQ.xcodeproj \
  -scheme RIZQ \
  -destination 'platform=iOS Simulator,name=iPhone 15 Pro' \
  -only-testing:RIZQSnapshotTests \
  2>&1 | xcpretty --test || xcodebuild test -project RIZQ.xcodeproj -scheme RIZQ -destination 'platform=iOS Simulator,name=iPhone 15 Pro' -only-testing:RIZQSnapshotTests

# All tests
xcodebuild test \
  -project RIZQ.xcodeproj \
  -scheme RIZQ \
  -destination 'platform=iOS Simulator,name=iPhone 15 Pro' \
  2>&1 | xcpretty --test || xcodebuild test -project RIZQ.xcodeproj -scheme RIZQ -destination 'platform=iOS Simulator,name=iPhone 15 Pro'
```

## Coverage Report

{{#if (eq coverage "true")}}
Generate coverage report after tests complete:

```bash
cd RIZQ-iOS

# View coverage summary
xcrun xccov view --report TestResults.xcresult

# Export coverage to JSON
xcrun xccov view --report --json TestResults.xcresult > coverage.json

# View file-by-file coverage
xcrun xccov view --files-for-target RIZQ.app TestResults.xcresult

# View coverage for specific file
xcrun xccov view --file RIZQ/Features/Home/HomeFeature.swift TestResults.xcresult
```

### Coverage Thresholds

The project targets these coverage levels:
- **Features**: 80%+ coverage
- **Services**: 90%+ coverage
- **Models**: 70%+ coverage (mostly just initialization)
- **Views**: Not included (tested via snapshots)
{{/if}}

## Filtering Tests

Run specific test classes or methods:

```bash
# Single test class
xcodebuild test \
  -project RIZQ.xcodeproj \
  -scheme RIZQ \
  -destination 'platform=iOS Simulator,name=iPhone 15 Pro' \
  -only-testing:RIZQTests/HomeFeatureTests

# Single test method
xcodebuild test \
  -project RIZQ.xcodeproj \
  -scheme RIZQ \
  -destination 'platform=iOS Simulator,name=iPhone 15 Pro' \
  -only-testing:RIZQTests/HomeFeatureTests/testOnAppear

# Pattern matching (all Practice tests)
xcodebuild test \
  -project RIZQ.xcodeproj \
  -scheme RIZQ \
  -destination 'platform=iOS Simulator,name=iPhone 15 Pro' \
  -only-testing:RIZQTests/PracticeFeatureTests \
  -only-testing:RIZQSnapshotTests/PracticeViewSnapshotTests
```

## Parallel Testing

Speed up test execution on CI:

```bash
xcodebuild test \
  -project RIZQ.xcodeproj \
  -scheme RIZQ \
  -destination 'platform=iOS Simulator,name=iPhone 15 Pro' \
  -parallel-testing-enabled YES \
  -parallel-testing-worker-count 4
```

## Handling Test Failures

### Unit Test Failures

1. Check the test output for assertion failures
2. Read the failing test to understand expected vs actual
3. Fix the feature code or update the test

### Snapshot Test Failures

1. Check `RIZQSnapshotTests/__Snapshots__/[TestName]/` for diff images
2. If intentional UI change, re-record:
   ```bash
   RECORD_SNAPSHOTS=1 xcodebuild test \
     -project RIZQ.xcodeproj \
     -scheme RIZQ \
     -destination 'platform=iOS Simulator,name=iPhone 15 Pro' \
     -only-testing:RIZQSnapshotTests/[FailingTest]
   ```
3. Review the new snapshots and commit

## CI Integration

For GitHub Actions, use this workflow step:

```yaml
- name: Run Tests
  run: |
    cd RIZQ-iOS
    xcodebuild test \
      -project RIZQ.xcodeproj \
      -scheme RIZQ \
      -destination 'platform=iOS Simulator,name=iPhone 15 Pro' \
      -enableCodeCoverage YES \
      -resultBundlePath ${{ runner.temp }}/TestResults.xcresult

- name: Upload Test Results
  uses: actions/upload-artifact@v4
  if: always()
  with:
    name: test-results
    path: ${{ runner.temp }}/TestResults.xcresult
```

## Quick Reference

| Command | Description |
|---------|-------------|
| `/run-tests` | Run all tests |
| `/run-tests --target unit` | Run unit tests only |
| `/run-tests --target snapshot` | Run snapshot tests only |
| `/run-tests --coverage true` | Run with coverage |
| `/run-tests --filter HomeFeatureTests` | Run specific test class |
