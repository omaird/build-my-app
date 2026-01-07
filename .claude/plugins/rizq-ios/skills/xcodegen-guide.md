---
name: xcodegen-guide
description: "XcodeGen project generation: project.yml schema, targets, schemes, SPM dependencies, and build settings"
---

# XcodeGen Guide for iOS

This skill provides patterns for generating and maintaining the RIZQ iOS Xcode project using XcodeGen.

---

## Why XcodeGen?

| Problem | Solution |
|---------|----------|
| Merge conflicts in `.xcodeproj` | YAML is human-readable, easy to merge |
| Team onboarding | `xcodegen generate` creates project instantly |
| Consistent build settings | Single source of truth in `project.yml` |
| SPM dependency management | Declarative package definitions |
| Multi-target setup | Easy to add test targets, extensions, widgets |

---

## Installation

```bash
# Homebrew (recommended)
brew install xcodegen

# Mint
mint install yonaskolb/XcodeGen

# From source
git clone https://github.com/yonaskolb/XcodeGen.git
cd XcodeGen
swift build -c release
cp .build/release/xcodegen /usr/local/bin/
```

---

## Basic Usage

```bash
# Generate Xcode project
xcodegen generate

# Generate with specific spec file
xcodegen generate --spec project.yml

# Generate and open Xcode
xcodegen generate && open RIZQ.xcodeproj

# Use with cache (faster regeneration)
xcodegen generate --use-cache
```

---

## Complete project.yml for RIZQ

```yaml
# project.yml

name: RIZQ
options:
  bundleIdPrefix: com.rizq
  deploymentTarget:
    iOS: "17.0"
  xcodeVersion: "15.2"
  generateEmptyDirectories: true
  groupSortPosition: top
  createIntermediateGroups: true
  indentWidth: 2
  tabWidth: 2
  usesTabs: false

settings:
  base:
    MARKETING_VERSION: "1.0.0"
    CURRENT_PROJECT_VERSION: "1"
    DEVELOPMENT_TEAM: XXXXXXXXXX
    CODE_SIGN_STYLE: Automatic
    SWIFT_VERSION: "5.9"
    IPHONEOS_DEPLOYMENT_TARGET: "17.0"
    ENABLE_USER_SCRIPT_SANDBOXING: false

configs:
  Debug:
    buildSettings:
      SWIFT_ACTIVE_COMPILATION_CONDITIONS: DEBUG
      SWIFT_OPTIMIZATION_LEVEL: "-Onone"
  Release:
    buildSettings:
      SWIFT_ACTIVE_COMPILATION_CONDITIONS: RELEASE
      SWIFT_OPTIMIZATION_LEVEL: "-O"

# ============================================
# PACKAGES (Swift Package Manager)
# ============================================

packages:
  ComposableArchitecture:
    url: https://github.com/pointfreeco/swift-composable-architecture
    version: "1.15.0"

  SnapshotTesting:
    url: https://github.com/pointfreeco/swift-snapshot-testing
    version: "1.17.0"

  Nuke:
    url: https://github.com/kean/Nuke
    version: "12.8.0"

# ============================================
# TARGETS
# ============================================

targets:

  # === MAIN APP ===
  RIZQ:
    type: application
    platform: iOS
    sources:
      - path: RIZQ
        excludes:
          - "**/*.md"
          - "**/__Snapshots__/**"
    resources:
      - path: RIZQ/Resources
        buildPhase: resources
      - path: RIZQ/Assets.xcassets
    dependencies:
      - package: ComposableArchitecture
      - package: Nuke
      - target: RIZQKit
    settings:
      base:
        PRODUCT_BUNDLE_IDENTIFIER: com.rizq.app
        INFOPLIST_FILE: RIZQ/Info.plist
        CODE_SIGN_ENTITLEMENTS: RIZQ/RIZQ.entitlements
        ASSETCATALOG_COMPILER_APPICON_NAME: AppIcon
        ASSETCATALOG_COMPILER_GLOBAL_ACCENT_COLOR_NAME: AccentColor
        PRODUCT_NAME: RIZQ
        TARGETED_DEVICE_FAMILY: "1"  # iPhone only
    preBuildScripts:
      - name: SwiftLint
        script: |
          if which swiftlint > /dev/null; then
            swiftlint
          else
            echo "warning: SwiftLint not installed"
          fi
        basedOnDependencyAnalysis: false
    scheme:
      testTargets:
        - RIZQTests
        - RIZQSnapshotTests
      gatherCoverageData: true
      coverageTargets:
        - RIZQ

  # === SHARED KIT (Core logic) ===
  RIZQKit:
    type: framework
    platform: iOS
    sources:
      - path: RIZQKit
    dependencies:
      - package: ComposableArchitecture
    settings:
      base:
        PRODUCT_BUNDLE_IDENTIFIER: com.rizq.app.kit
        INFOPLIST_FILE: RIZQKit/Info.plist
        DEFINES_MODULE: YES
        PRODUCT_NAME: RIZQKit

  # === UNIT TESTS ===
  RIZQTests:
    type: bundle.unit-test
    platform: iOS
    sources:
      - path: RIZQTests
        excludes:
          - "**/__Snapshots__/**"
    dependencies:
      - target: RIZQ
      - target: RIZQKit
      - package: ComposableArchitecture
        product: ComposableArchitecture
    settings:
      base:
        PRODUCT_BUNDLE_IDENTIFIER: com.rizq.app.tests
        INFOPLIST_FILE: RIZQTests/Info.plist
        TEST_HOST: "$(BUILT_PRODUCTS_DIR)/RIZQ.app/$(BUNDLE_EXECUTABLE_FOLDER_PATH)/RIZQ"
        BUNDLE_LOADER: "$(TEST_HOST)"

  # === SNAPSHOT TESTS ===
  RIZQSnapshotTests:
    type: bundle.unit-test
    platform: iOS
    sources:
      - path: RIZQSnapshotTests
    resources:
      - path: RIZQSnapshotTests/__Snapshots__
        buildPhase: resources
    dependencies:
      - target: RIZQ
      - target: RIZQKit
      - package: SnapshotTesting
    settings:
      base:
        PRODUCT_BUNDLE_IDENTIFIER: com.rizq.app.snapshottests
        INFOPLIST_FILE: RIZQSnapshotTests/Info.plist
        TEST_HOST: "$(BUILT_PRODUCTS_DIR)/RIZQ.app/$(BUNDLE_EXECUTABLE_FOLDER_PATH)/RIZQ"
        BUNDLE_LOADER: "$(TEST_HOST)"

  # === WIDGET EXTENSION ===
  RIZQWidget:
    type: app-extension
    platform: iOS
    sources:
      - path: RIZQWidget
    dependencies:
      - target: RIZQKit
      - sdk: WidgetKit.framework
      - sdk: SwiftUI.framework
    settings:
      base:
        PRODUCT_BUNDLE_IDENTIFIER: com.rizq.app.widget
        INFOPLIST_FILE: RIZQWidget/Info.plist
        CODE_SIGN_ENTITLEMENTS: RIZQWidget/RIZQWidget.entitlements
        ASSETCATALOG_COMPILER_WIDGET_BACKGROUND_COLOR_NAME: WidgetBackground
        PRODUCT_NAME: RIZQWidget
        SKIP_INSTALL: YES
        LD_RUNPATH_SEARCH_PATHS:
          - "$(inherited)"
          - "@executable_path/Frameworks"
          - "@executable_path/../../Frameworks"

# ============================================
# SCHEMES
# ============================================

schemes:
  RIZQ:
    build:
      targets:
        RIZQ: all
        RIZQKit: [run, test]
        RIZQWidget: all
    run:
      config: Debug
      commandLineArguments:
        "-UITesting_skipOnboarding": false
      environmentVariables:
        - variable: RIZQ_DEBUG
          value: "1"
          isEnabled: true
    test:
      config: Debug
      gatherCoverageData: true
      coverageTargets:
        - RIZQ
        - RIZQKit
      targets:
        - name: RIZQTests
          parallelizable: true
          randomExecutionOrder: true
        - name: RIZQSnapshotTests
          parallelizable: false
    profile:
      config: Release
    analyze:
      config: Debug
    archive:
      config: Release

  RIZQKit:
    build:
      targets:
        RIZQKit: all
    test:
      config: Debug
      targets:
        - RIZQTests
```

---

## Project Structure

```
RIZQ/
├── project.yml                 # XcodeGen spec
├── RIZQ.xcodeproj/             # Generated (gitignore)
├── RIZQ/                       # Main app target
│   ├── App/
│   │   ├── RIZQApp.swift
│   │   └── AppDelegate.swift
│   ├── Features/
│   │   ├── Home/
│   │   ├── Library/
│   │   ├── Practice/
│   │   ├── Journeys/
│   │   └── Settings/
│   ├── Views/
│   │   ├── Components/
│   │   └── Screens/
│   ├── Resources/
│   │   ├── Localizable.strings
│   │   └── Fonts/
│   ├── Assets.xcassets
│   ├── Info.plist
│   └── RIZQ.entitlements
├── RIZQKit/                    # Shared framework
│   ├── Models/
│   ├── Services/
│   ├── Networking/
│   ├── Persistence/
│   ├── Design/
│   └── Info.plist
├── RIZQTests/                  # Unit tests
│   ├── Features/
│   ├── Mocks/
│   └── Info.plist
├── RIZQSnapshotTests/          # Snapshot tests
│   ├── Features/
│   ├── __Snapshots__/
│   └── Info.plist
├── RIZQWidget/                 # Widget extension
│   ├── RIZQWidget.swift
│   ├── RIZQWidgetBundle.swift
│   ├── Info.plist
│   └── RIZQWidget.entitlements
├── fastlane/
├── Gemfile
└── .gitignore
```

---

## Target Configuration Reference

### Application Target

```yaml
targets:
  MyApp:
    type: application
    platform: iOS
    deploymentTarget: "17.0"

    # Source files
    sources:
      - path: Sources
        name: Source Files
        group: Sources
        type: group
        excludes:
          - "**/*.md"
          - "**/Tests/**"
        compilerFlags:
          - "-Werror"

    # Resources
    resources:
      - path: Resources
        buildPhase: resources
      - path: Assets.xcassets

    # Dependencies
    dependencies:
      - target: MyFramework
      - package: SomePackage
      - framework: SomeFramework.framework
        embed: true
      - sdk: CoreData.framework

    # Build settings
    settings:
      base:
        PRODUCT_BUNDLE_IDENTIFIER: com.example.myapp
        INFOPLIST_FILE: Sources/Info.plist
        DEVELOPMENT_TEAM: XXXXXXXXXX
      configs:
        Debug:
          SWIFT_OPTIMIZATION_LEVEL: "-Onone"
        Release:
          SWIFT_OPTIMIZATION_LEVEL: "-O"

    # Info.plist values (alternative to file)
    info:
      path: Sources/Info.plist
      properties:
        CFBundleDisplayName: My App
        UILaunchScreen: {}

    # Entitlements
    entitlements:
      path: Sources/MyApp.entitlements
      properties:
        com.apple.developer.associated-domains:
          - "applinks:example.com"

    # Build phases
    preBuildScripts:
      - name: SwiftLint
        script: swiftlint
        basedOnDependencyAnalysis: false

    postBuildScripts:
      - name: Copy Files
        script: cp -r "$SRCROOT/Files" "$TARGET_BUILD_DIR/$PRODUCT_NAME.app/"
```

### Framework Target

```yaml
targets:
  MyFramework:
    type: framework
    platform: iOS

    sources:
      - path: Framework

    settings:
      base:
        PRODUCT_BUNDLE_IDENTIFIER: com.example.framework
        DEFINES_MODULE: YES
        INFOPLIST_FILE: Framework/Info.plist
        SKIP_INSTALL: YES
        INSTALL_PATH: "$(LOCAL_LIBRARY_DIR)/Frameworks"
        DYLIB_INSTALL_NAME_BASE: "@rpath"
        LD_RUNPATH_SEARCH_PATHS:
          - "$(inherited)"
          - "@executable_path/Frameworks"
          - "@loader_path/Frameworks"
```

### Test Target

```yaml
targets:
  MyAppTests:
    type: bundle.unit-test
    platform: iOS

    sources:
      - path: Tests

    dependencies:
      - target: MyApp

    settings:
      base:
        PRODUCT_BUNDLE_IDENTIFIER: com.example.tests
        TEST_HOST: "$(BUILT_PRODUCTS_DIR)/MyApp.app/$(BUNDLE_EXECUTABLE_FOLDER_PATH)/MyApp"
        BUNDLE_LOADER: "$(TEST_HOST)"
        INFOPLIST_FILE: Tests/Info.plist
```

### Widget Extension

```yaml
targets:
  MyWidget:
    type: app-extension
    platform: iOS

    sources:
      - path: Widget

    dependencies:
      - sdk: WidgetKit.framework
      - sdk: SwiftUI.framework

    settings:
      base:
        PRODUCT_BUNDLE_IDENTIFIER: com.example.myapp.widget
        INFOPLIST_FILE: Widget/Info.plist
        SKIP_INSTALL: YES
        LD_RUNPATH_SEARCH_PATHS:
          - "$(inherited)"
          - "@executable_path/Frameworks"
          - "@executable_path/../../Frameworks"

    # Add to main app
    # In main app target:
    # dependencies:
    #   - target: MyWidget
    #     embed: true
    #     codeSign: true
```

---

## Swift Package Manager

### Package Definitions

```yaml
packages:
  # Version-based
  TCA:
    url: https://github.com/pointfreeco/swift-composable-architecture
    version: "1.15.0"

  # Branch-based
  MyPackage:
    url: https://github.com/example/package
    branch: main

  # Exact version
  AnotherPackage:
    url: https://github.com/example/another
    exactVersion: "2.0.0"

  # Version range
  RangePackage:
    url: https://github.com/example/range
    minVersion: "1.0.0"
    maxVersion: "2.0.0"

  # Local package
  LocalPackage:
    path: ../LocalPackage

  # GitHub shorthand
  GitHubPackage:
    github: owner/repo
    version: "1.0.0"
```

### Using Package Products

```yaml
targets:
  MyApp:
    dependencies:
      # Default product (same name as package)
      - package: TCA

      # Specific product
      - package: TCA
        product: ComposableArchitecture

      # Multiple products from same package
      - package: Firebase
        product: FirebaseAnalytics
      - package: Firebase
        product: FirebaseAuth
```

---

## Build Settings

### Common Settings

```yaml
settings:
  base:
    # Swift
    SWIFT_VERSION: "5.9"
    SWIFT_STRICT_CONCURRENCY: complete

    # Deployment
    IPHONEOS_DEPLOYMENT_TARGET: "17.0"
    TARGETED_DEVICE_FAMILY: "1,2"  # 1=iPhone, 2=iPad

    # Code Signing
    DEVELOPMENT_TEAM: XXXXXXXXXX
    CODE_SIGN_STYLE: Automatic
    CODE_SIGN_IDENTITY: "Apple Development"

    # Versioning
    MARKETING_VERSION: "1.0.0"
    CURRENT_PROJECT_VERSION: "1"

    # Module
    DEFINES_MODULE: YES
    PRODUCT_MODULE_NAME: "$(PRODUCT_NAME:c99extidentifier)"

    # Build
    ENABLE_BITCODE: NO
    ENABLE_TESTABILITY: YES
    DEBUG_INFORMATION_FORMAT: "dwarf-with-dsym"

    # Warnings
    CLANG_WARN_DOCUMENTATION_COMMENTS: YES
    SWIFT_TREAT_WARNINGS_AS_ERRORS: NO
```

### Per-Configuration Settings

```yaml
configs:
  Debug:
    buildSettings:
      SWIFT_OPTIMIZATION_LEVEL: "-Onone"
      SWIFT_ACTIVE_COMPILATION_CONDITIONS: "DEBUG"
      ENABLE_TESTABILITY: YES
      ONLY_ACTIVE_ARCH: YES
      MTL_ENABLE_DEBUG_INFO: INCLUDE_SOURCE

  Release:
    buildSettings:
      SWIFT_OPTIMIZATION_LEVEL: "-O"
      SWIFT_ACTIVE_COMPILATION_CONDITIONS: "RELEASE"
      ENABLE_TESTABILITY: NO
      VALIDATE_PRODUCT: YES
      STRIP_INSTALLED_PRODUCT: YES
```

---

## Schemes

### Full Scheme Definition

```yaml
schemes:
  MyApp:
    build:
      preActions:
        - script: echo "Starting build"
          name: Pre-Build
          settingsTarget: MyApp
      targets:
        MyApp: all
        MyFramework: [run, test, profile]
      postActions:
        - script: echo "Build complete"
          name: Post-Build

    run:
      config: Debug
      commandLineArguments:
        "-FIRDebugEnabled": true
        "-FIRAnalyticsDebugEnabled": false
      environmentVariables:
        - variable: API_URL
          value: "https://dev.api.example.com"
          isEnabled: true
      preActions:
        - script: echo "Starting run"
      launchAutomaticallySubstyle: 2  # Wait for launch

    test:
      config: Debug
      gatherCoverageData: true
      coverageTargets:
        - MyApp
        - MyFramework
      targets:
        - name: MyAppTests
          parallelizable: true
          randomExecutionOrder: true
          skipped: false
        - name: MyAppUITests
          parallelizable: false
      testPlans:
        - path: TestPlans/AllTests.xctestplan
          defaultPlan: true

    profile:
      config: Release

    analyze:
      config: Debug

    archive:
      config: Release
      revealArchiveInOrganizer: true
```

---

## Info.plist Configuration

### Inline Properties

```yaml
targets:
  MyApp:
    info:
      path: Sources/Info.plist
      properties:
        CFBundleDisplayName: "$(PRODUCT_NAME)"
        CFBundleShortVersionString: "$(MARKETING_VERSION)"
        CFBundleVersion: "$(CURRENT_PROJECT_VERSION)"
        UILaunchScreen:
          UIColorName: "LaunchBackground"
          UIImageName: "LaunchLogo"
        UIApplicationSceneManifest:
          UIApplicationSupportsMultipleScenes: true
          UISceneConfigurations:
            UIWindowSceneSessionRoleApplication:
              - UISceneConfigurationName: "Default Configuration"
                UISceneDelegateClassName: "$(PRODUCT_MODULE_NAME).SceneDelegate"
        UISupportedInterfaceOrientations:
          - UIInterfaceOrientationPortrait
        ITSAppUsesNonExemptEncryption: false
        NSAppTransportSecurity:
          NSAllowsArbitraryLoads: false
        CFBundleURLTypes:
          - CFBundleURLName: "com.rizq.app"
            CFBundleURLSchemes:
              - "rizq"
```

---

## CI/CD Integration

### Generate in CI

```yaml
# .github/workflows/ios.yml
jobs:
  build:
    runs-on: macos-14
    steps:
      - uses: actions/checkout@v4

      - name: Install XcodeGen
        run: brew install xcodegen

      - name: Generate Project
        run: xcodegen generate

      - name: Build
        run: xcodebuild build -scheme RIZQ -destination 'platform=iOS Simulator,name=iPhone 15 Pro'
```

### Makefile

```makefile
# Makefile

.PHONY: project clean build test

project:
	xcodegen generate
	open RIZQ.xcodeproj

clean:
	rm -rf RIZQ.xcodeproj
	rm -rf build
	rm -rf DerivedData

build: project
	xcodebuild build \
		-scheme RIZQ \
		-configuration Debug \
		-destination 'platform=iOS Simulator,name=iPhone 15 Pro' \
		-derivedDataPath build/DerivedData

test: project
	xcodebuild test \
		-scheme RIZQ \
		-configuration Debug \
		-destination 'platform=iOS Simulator,name=iPhone 15 Pro' \
		-derivedDataPath build/DerivedData \
		-resultBundlePath build/TestResults.xcresult
```

---

## .gitignore

```gitignore
# XcodeGen - Generated project
*.xcodeproj/

# But keep shared schemes if manually added
!*.xcodeproj/xcshareddata/
!*.xcodeproj/xcshareddata/xcschemes/

# Build
build/
DerivedData/
*.ipa
*.dSYM.zip
*.dSYM

# CocoaPods (if used alongside SPM)
Pods/

# Carthage (if used)
Carthage/Build/

# Xcode
*.xcuserdata
*.xcscmblueprint
*.xccheckout

# Swift Package Manager
.build/
.swiftpm/

# fastlane
fastlane/report.xml
fastlane/Preview.html
fastlane/screenshots
fastlane/test_output
```

---

## Migration from Existing Project

```bash
# 1. Export current settings
xcodebuild -showBuildSettings -project MyApp.xcodeproj > settings.txt

# 2. Create initial project.yml
xcodegen init

# 3. Review and adjust project.yml based on settings.txt

# 4. Generate and compare
xcodegen generate
# Open both old and new projects to compare

# 5. Once validated, remove old project
rm -rf MyApp.xcodeproj.backup

# 6. Update CI/CD to use xcodegen
```
