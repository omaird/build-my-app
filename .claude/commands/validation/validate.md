---
description: Run comprehensive validation of the RIZQ project
---

Run comprehensive validation of the RIZQ App project.

Execute the following commands in sequence and report results:

## 1. Web App - Type Checking

```bash
cd "/Users/omairdawood/Projects/RIZQ App" && npm run build 2>&1 | head -50
```

**Expected:** Build completes successfully with no TypeScript errors

## 2. Web App - Linting (if configured)

```bash
cd "/Users/omairdawood/Projects/RIZQ App" && npm run lint 2>&1 || echo "Lint script not configured"
```

**Expected:** No linting errors

## 3. Web App - Tests (if configured)

```bash
cd "/Users/omairdawood/Projects/RIZQ App" && npm test 2>&1 || echo "Test script not configured"
```

**Expected:** All tests pass

## 4. iOS App - Build

```bash
cd "/Users/omairdawood/Projects/RIZQ App/RIZQ-iOS" && xcodebuild -scheme RIZQ -destination 'platform=iOS Simulator,name=iPhone 17' build 2>&1 | tail -30
```

**Expected:** Build completes with "BUILD SUCCEEDED"

## 5. iOS App - Tests

```bash
cd "/Users/omairdawood/Projects/RIZQ App/RIZQ-iOS" && xcodebuild -scheme RIZQ -destination 'platform=iOS Simulator,name=iPhone 17' test 2>&1 | tail -50
```

**Expected:** All tests pass with "TEST SUCCEEDED"

## 6. Firebase Rules Validation (if applicable)

```bash
cd "/Users/omairdawood/Projects/RIZQ App" && cat firestore.rules 2>/dev/null || echo "No firestore.rules file"
```

**Expected:** Rules file exists and is properly formatted

## 7. Git Status Check

```bash
cd "/Users/omairdawood/Projects/RIZQ App" && git status --short
```

**Expected:** Shows changed files, no unexpected modifications

## 8. Summary Report

After all validations complete, provide a summary report with:

### Web App
- TypeScript/Build status: [PASS/FAIL]
- Linting status: [PASS/FAIL/NOT CONFIGURED]
- Tests status: [PASS/FAIL/NOT CONFIGURED]

### iOS App
- Build status: [PASS/FAIL]
- Tests status: [PASS/FAIL]

### Firebase
- Rules validation: [PASS/FAIL/NOT APPLICABLE]

### Overall
- Any errors or warnings encountered
- Files with issues
- Overall health assessment: **[PASS/FAIL]**

**Format the report clearly with sections and status indicators**

## Quick Validation (Web Only)

For quick web-only validation:

```bash
cd "/Users/omairdawood/Projects/RIZQ App" && npm run build
```

## Quick Validation (iOS Only)

For quick iOS-only validation:

```bash
cd "/Users/omairdawood/Projects/RIZQ App/RIZQ-iOS" && xcodebuild -scheme RIZQ -destination 'platform=iOS Simulator,name=iPhone 17' build
```
