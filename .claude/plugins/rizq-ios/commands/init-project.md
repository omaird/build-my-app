---
name: init-project
description: Scaffold a new iOS project with XcodeGen, TCA, SwiftUI, and RIZQ design system
allowed_tools:
  - Write
  - Edit
  - Bash
  - Glob
  - Read
arguments:
  - name: name
    description: "Project name (default: RIZQ)"
    required: false
  - name: bundle_id
    description: "Bundle identifier (default: com.rizq.app)"
    required: false
  - name: team_id
    description: "Apple Developer Team ID"
    required: false
  - name: min_ios
    description: "Minimum iOS version (default: 17.0)"
    required: false
---

# Initialize RIZQ iOS Project

Create a new iOS project structure with XcodeGen, The Composable Architecture (TCA), SwiftUI, and the RIZQ design system.

## Configuration

- **Project Name**: {{ name | default: "RIZQ" }}
- **Bundle ID**: {{ bundle_id | default: "com.rizq.app" }}
- **Team ID**: {{ team_id | default: "XXXXXXXXXX" }}
- **Min iOS**: {{ min_ios | default: "17.0" }}

---

## Step 1: Install Prerequisites

```bash
echo "=== Checking Prerequisites ==="

# Check for Homebrew
if ! command -v brew &> /dev/null; then
  echo "❌ Homebrew not found. Install from https://brew.sh"
  exit 1
fi
echo "✅ Homebrew installed"

# Install XcodeGen
if ! command -v xcodegen &> /dev/null; then
  echo "Installing XcodeGen..."
  brew install xcodegen
fi
echo "✅ XcodeGen $(xcodegen --version)"

# Install SwiftLint (optional)
if ! command -v swiftlint &> /dev/null; then
  echo "Installing SwiftLint..."
  brew install swiftlint
fi
echo "✅ SwiftLint installed"

# Check Xcode
XCODE_VERSION=$(xcodebuild -version | head -1)
echo "✅ $XCODE_VERSION"
```

---

## Step 2: Create Project Structure

```bash
PROJECT_NAME="{{ name | default: 'RIZQ' }}"
PROJECT_ROOT="${PROJECT_NAME}-iOS"

echo "=== Creating Project Structure ==="

mkdir -p "$PROJECT_ROOT"
cd "$PROJECT_ROOT"

# Main app target
mkdir -p "$PROJECT_NAME/App"
mkdir -p "$PROJECT_NAME/Features/Home"
mkdir -p "$PROJECT_NAME/Features/Library"
mkdir -p "$PROJECT_NAME/Features/Practice"
mkdir -p "$PROJECT_NAME/Features/Journeys"
mkdir -p "$PROJECT_NAME/Features/Settings"
mkdir -p "$PROJECT_NAME/Features/Auth"
mkdir -p "$PROJECT_NAME/Views/Components"
mkdir -p "$PROJECT_NAME/Views/Screens"
mkdir -p "$PROJECT_NAME/Resources/Fonts"
mkdir -p "$PROJECT_NAME/Assets.xcassets/AppIcon.appiconset"
mkdir -p "$PROJECT_NAME/Assets.xcassets/Colors"

# Shared framework
mkdir -p "${PROJECT_NAME}Kit/Models"
mkdir -p "${PROJECT_NAME}Kit/Services/API"
mkdir -p "${PROJECT_NAME}Kit/Services/Auth"
mkdir -p "${PROJECT_NAME}Kit/Services/Persistence"
mkdir -p "${PROJECT_NAME}Kit/Design"
mkdir -p "${PROJECT_NAME}Kit/Extensions"
mkdir -p "${PROJECT_NAME}Kit/Utilities"

# Test targets
mkdir -p "${PROJECT_NAME}Tests/Features"
mkdir -p "${PROJECT_NAME}Tests/Mocks"
mkdir -p "${PROJECT_NAME}SnapshotTests/Features"
mkdir -p "${PROJECT_NAME}SnapshotTests/__Snapshots__"

# Widget
mkdir -p "${PROJECT_NAME}Widget"

# CI/CD
mkdir -p "fastlane"

echo "✅ Project structure created"
```

---

## Step 3: Create project.yml (XcodeGen Spec)

```yaml
# project.yml

name: {{ name | default: "RIZQ" }}
options:
  bundleIdPrefix: {{ bundle_id | default: "com.rizq" | split: "." | slice: 0, 2 | join: "." }}
  deploymentTarget:
    iOS: "{{ min_ios | default: '17.0' }}"
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
    DEVELOPMENT_TEAM: {{ team_id | default: "XXXXXXXXXX" }}
    CODE_SIGN_STYLE: Automatic
    SWIFT_VERSION: "5.9"
    IPHONEOS_DEPLOYMENT_TARGET: "{{ min_ios | default: '17.0' }}"
    ENABLE_USER_SCRIPT_SANDBOXING: false
    SWIFT_STRICT_CONCURRENCY: complete

configs:
  Debug:
    buildSettings:
      SWIFT_ACTIVE_COMPILATION_CONDITIONS: DEBUG
      SWIFT_OPTIMIZATION_LEVEL: "-Onone"
  Release:
    buildSettings:
      SWIFT_ACTIVE_COMPILATION_CONDITIONS: RELEASE
      SWIFT_OPTIMIZATION_LEVEL: "-O"

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

targets:
  {{ name | default: "RIZQ" }}:
    type: application
    platform: iOS
    sources:
      - path: {{ name | default: "RIZQ" }}
        excludes:
          - "**/*.md"
    resources:
      - path: {{ name | default: "RIZQ" }}/Resources
      - path: {{ name | default: "RIZQ" }}/Assets.xcassets
    dependencies:
      - package: ComposableArchitecture
      - package: Nuke
      - target: {{ name | default: "RIZQ" }}Kit
    settings:
      base:
        PRODUCT_BUNDLE_IDENTIFIER: {{ bundle_id | default: "com.rizq.app" }}
        INFOPLIST_FILE: {{ name | default: "RIZQ" }}/Info.plist
        CODE_SIGN_ENTITLEMENTS: {{ name | default: "RIZQ" }}/{{ name | default: "RIZQ" }}.entitlements
        ASSETCATALOG_COMPILER_APPICON_NAME: AppIcon
        PRODUCT_NAME: {{ name | default: "RIZQ" }}
        TARGETED_DEVICE_FAMILY: "1"
    preBuildScripts:
      - name: SwiftLint
        script: |
          if which swiftlint > /dev/null; then
            swiftlint
          fi
        basedOnDependencyAnalysis: false
    scheme:
      testTargets:
        - {{ name | default: "RIZQ" }}Tests
        - {{ name | default: "RIZQ" }}SnapshotTests
      gatherCoverageData: true

  {{ name | default: "RIZQ" }}Kit:
    type: framework
    platform: iOS
    sources:
      - path: {{ name | default: "RIZQ" }}Kit
    dependencies:
      - package: ComposableArchitecture
    settings:
      base:
        PRODUCT_BUNDLE_IDENTIFIER: {{ bundle_id | default: "com.rizq.app" }}.kit
        INFOPLIST_FILE: {{ name | default: "RIZQ" }}Kit/Info.plist
        DEFINES_MODULE: YES

  {{ name | default: "RIZQ" }}Tests:
    type: bundle.unit-test
    platform: iOS
    sources:
      - path: {{ name | default: "RIZQ" }}Tests
    dependencies:
      - target: {{ name | default: "RIZQ" }}
      - target: {{ name | default: "RIZQ" }}Kit
      - package: ComposableArchitecture
    settings:
      base:
        PRODUCT_BUNDLE_IDENTIFIER: {{ bundle_id | default: "com.rizq.app" }}.tests
        INFOPLIST_FILE: {{ name | default: "RIZQ" }}Tests/Info.plist
        TEST_HOST: "$(BUILT_PRODUCTS_DIR)/{{ name | default: 'RIZQ' }}.app/$(BUNDLE_EXECUTABLE_FOLDER_PATH)/{{ name | default: 'RIZQ' }}"
        BUNDLE_LOADER: "$(TEST_HOST)"

  {{ name | default: "RIZQ" }}SnapshotTests:
    type: bundle.unit-test
    platform: iOS
    sources:
      - path: {{ name | default: "RIZQ" }}SnapshotTests
    resources:
      - path: {{ name | default: "RIZQ" }}SnapshotTests/__Snapshots__
    dependencies:
      - target: {{ name | default: "RIZQ" }}
      - package: SnapshotTesting
    settings:
      base:
        PRODUCT_BUNDLE_IDENTIFIER: {{ bundle_id | default: "com.rizq.app" }}.snapshottests
        INFOPLIST_FILE: {{ name | default: "RIZQ" }}SnapshotTests/Info.plist
        TEST_HOST: "$(BUILT_PRODUCTS_DIR)/{{ name | default: 'RIZQ' }}.app/$(BUNDLE_EXECUTABLE_FOLDER_PATH)/{{ name | default: 'RIZQ' }}"
        BUNDLE_LOADER: "$(TEST_HOST)"

  {{ name | default: "RIZQ" }}Widget:
    type: app-extension
    platform: iOS
    sources:
      - path: {{ name | default: "RIZQ" }}Widget
    dependencies:
      - target: {{ name | default: "RIZQ" }}Kit
      - sdk: WidgetKit.framework
      - sdk: SwiftUI.framework
    settings:
      base:
        PRODUCT_BUNDLE_IDENTIFIER: {{ bundle_id | default: "com.rizq.app" }}.widget
        INFOPLIST_FILE: {{ name | default: "RIZQ" }}Widget/Info.plist
        CODE_SIGN_ENTITLEMENTS: {{ name | default: "RIZQ" }}Widget/{{ name | default: "RIZQ" }}Widget.entitlements
        SKIP_INSTALL: YES

schemes:
  {{ name | default: "RIZQ" }}:
    build:
      targets:
        {{ name | default: "RIZQ" }}: all
        {{ name | default: "RIZQ" }}Kit: [run, test]
        {{ name | default: "RIZQ" }}Widget: all
    run:
      config: Debug
    test:
      config: Debug
      gatherCoverageData: true
      targets:
        - name: {{ name | default: "RIZQ" }}Tests
          parallelizable: true
        - name: {{ name | default: "RIZQ" }}SnapshotTests
          parallelizable: false
    archive:
      config: Release
```

---

## Step 4: Create Info.plist Files

### Main App Info.plist

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>CFBundleDevelopmentRegion</key>
  <string>$(DEVELOPMENT_LANGUAGE)</string>
  <key>CFBundleDisplayName</key>
  <string>{{ name | default: "RIZQ" }}</string>
  <key>CFBundleExecutable</key>
  <string>$(EXECUTABLE_NAME)</string>
  <key>CFBundleIdentifier</key>
  <string>$(PRODUCT_BUNDLE_IDENTIFIER)</string>
  <key>CFBundleInfoDictionaryVersion</key>
  <string>6.0</string>
  <key>CFBundleName</key>
  <string>$(PRODUCT_NAME)</string>
  <key>CFBundlePackageType</key>
  <string>APPL</string>
  <key>CFBundleShortVersionString</key>
  <string>$(MARKETING_VERSION)</string>
  <key>CFBundleVersion</key>
  <string>$(CURRENT_PROJECT_VERSION)</string>
  <key>LSRequiresIPhoneOS</key>
  <true/>
  <key>UIApplicationSceneManifest</key>
  <dict>
    <key>UIApplicationSupportsMultipleScenes</key>
    <false/>
    <key>UISceneConfigurations</key>
    <dict/>
  </dict>
  <key>UILaunchScreen</key>
  <dict>
    <key>UIColorName</key>
    <string>LaunchBackground</string>
  </dict>
  <key>UISupportedInterfaceOrientations</key>
  <array>
    <string>UIInterfaceOrientationPortrait</string>
  </array>
  <key>ITSAppUsesNonExemptEncryption</key>
  <false/>
  <key>CFBundleURLTypes</key>
  <array>
    <dict>
      <key>CFBundleURLName</key>
      <string>{{ bundle_id | default: "com.rizq.app" }}</string>
      <key>CFBundleURLSchemes</key>
      <array>
        <string>rizq</string>
      </array>
    </dict>
  </array>
</dict>
</plist>
```

### Framework Info.plist

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>CFBundleDevelopmentRegion</key>
  <string>$(DEVELOPMENT_LANGUAGE)</string>
  <key>CFBundleExecutable</key>
  <string>$(EXECUTABLE_NAME)</string>
  <key>CFBundleIdentifier</key>
  <string>$(PRODUCT_BUNDLE_IDENTIFIER)</string>
  <key>CFBundleInfoDictionaryVersion</key>
  <string>6.0</string>
  <key>CFBundleName</key>
  <string>$(PRODUCT_NAME)</string>
  <key>CFBundlePackageType</key>
  <string>FMWK</string>
  <key>CFBundleShortVersionString</key>
  <string>$(MARKETING_VERSION)</string>
  <key>CFBundleVersion</key>
  <string>$(CURRENT_PROJECT_VERSION)</string>
</dict>
</plist>
```

### Test Info.plist

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>CFBundleDevelopmentRegion</key>
  <string>$(DEVELOPMENT_LANGUAGE)</string>
  <key>CFBundleExecutable</key>
  <string>$(EXECUTABLE_NAME)</string>
  <key>CFBundleIdentifier</key>
  <string>$(PRODUCT_BUNDLE_IDENTIFIER)</string>
  <key>CFBundleInfoDictionaryVersion</key>
  <string>6.0</string>
  <key>CFBundleName</key>
  <string>$(PRODUCT_NAME)</string>
  <key>CFBundlePackageType</key>
  <string>BNDL</string>
  <key>CFBundleShortVersionString</key>
  <string>1.0</string>
  <key>CFBundleVersion</key>
  <string>1</string>
</dict>
</plist>
```

---

## Step 5: Create Entitlements Files

### App Entitlements

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>com.apple.security.application-groups</key>
  <array>
    <string>group.{{ bundle_id | default: "com.rizq.app" }}</string>
  </array>
  <key>com.apple.developer.associated-domains</key>
  <array>
    <string>applinks:rizq.app</string>
  </array>
</dict>
</plist>
```

### Widget Entitlements

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>com.apple.security.application-groups</key>
  <array>
    <string>group.{{ bundle_id | default: "com.rizq.app" }}</string>
  </array>
</dict>
</plist>
```

---

## Step 6: Create App Entry Point

### RIZQApp.swift

```swift
import SwiftUI
import ComposableArchitecture

@main
struct RIZQApp: App {
  @MainActor
  static let store = Store(initialState: AppFeature.State()) {
    AppFeature()
  }

  var body: some Scene {
    WindowGroup {
      AppView(store: Self.store)
    }
  }
}
```

### AppFeature.swift

```swift
import ComposableArchitecture

@Reducer
struct AppFeature {
  @ObservableState
  struct State: Equatable {
    var selectedTab: Tab = .home
    var home = HomeFeature.State()
    var library = LibraryFeature.State()
    var journeys = JourneysFeature.State()
    var settings = SettingsFeature.State()
  }

  enum Tab: String, CaseIterable {
    case home, library, journeys, settings
  }

  enum Action {
    case tabSelected(Tab)
    case home(HomeFeature.Action)
    case library(LibraryFeature.Action)
    case journeys(JourneysFeature.Action)
    case settings(SettingsFeature.Action)
  }

  var body: some ReducerOf<Self> {
    Reduce { state, action in
      switch action {
      case .tabSelected(let tab):
        state.selectedTab = tab
        return .none

      case .home, .library, .journeys, .settings:
        return .none
      }
    }

    Scope(state: \.home, action: \.home) {
      HomeFeature()
    }

    Scope(state: \.library, action: \.library) {
      LibraryFeature()
    }

    Scope(state: \.journeys, action: \.journeys) {
      JourneysFeature()
    }

    Scope(state: \.settings, action: \.settings) {
      SettingsFeature()
    }
  }
}
```

### AppView.swift

```swift
import SwiftUI
import ComposableArchitecture

struct AppView: View {
  @Bindable var store: StoreOf<AppFeature>

  var body: some View {
    TabView(selection: $store.selectedTab.sending(\.tabSelected)) {
      HomeView(store: store.scope(state: \.home, action: \.home))
        .tabItem {
          Label("Home", systemImage: "house.fill")
        }
        .tag(AppFeature.Tab.home)

      LibraryView(store: store.scope(state: \.library, action: \.library))
        .tabItem {
          Label("Library", systemImage: "book.fill")
        }
        .tag(AppFeature.Tab.library)

      JourneysView(store: store.scope(state: \.journeys, action: \.journeys))
        .tabItem {
          Label("Journeys", systemImage: "map.fill")
        }
        .tag(AppFeature.Tab.journeys)

      SettingsView(store: store.scope(state: \.settings, action: \.settings))
        .tabItem {
          Label("Settings", systemImage: "gearshape.fill")
        }
        .tag(AppFeature.Tab.settings)
    }
    .tint(.rizqPrimary)
  }
}
```

---

## Step 7: Create Design System

### Colors.swift (in RIZQKit/Design/)

```swift
import SwiftUI

public extension Color {
  // MARK: - Brand Colors
  static let rizqPrimary = Color("Primary", bundle: .module)
  static let rizqAccent = Color("Accent", bundle: .module)

  // MARK: - Sand Palette
  static let sandWarm = Color(hex: "D4A574")
  static let sandLight = Color(hex: "E6C79C")
  static let sandDeep = Color(hex: "A67C52")

  // MARK: - Mocha Palette
  static let mocha = Color(hex: "6B4423")
  static let mochaDeep = Color(hex: "2C2416")

  // MARK: - Cream Palette
  static let cream = Color(hex: "F5EFE7")
  static let creamWarm = Color(hex: "FFFCF7")

  // MARK: - Gold Palette
  static let goldSoft = Color(hex: "E6C79C")
  static let goldBright = Color(hex: "FFEBB3")

  // MARK: - Teal Palette
  static let tealMuted = Color(hex: "5B8A8A")
  static let tealSuccess = Color(hex: "6B9B7C")

  // MARK: - Semantic Colors
  static let rizqBackground = cream
  static let rizqCard = creamWarm
  static let rizqText = mochaDeep
  static let rizqSecondary = Color(hex: "8B7355")
  static let rizqMuted = Color(hex: "C4B8A8")
}

// MARK: - Hex Initializer
public extension Color {
  init(hex: String) {
    let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
    var int: UInt64 = 0
    Scanner(string: hex).scanHexInt64(&int)
    let a, r, g, b: UInt64
    switch hex.count {
    case 3: // RGB (12-bit)
      (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
    case 6: // RGB (24-bit)
      (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
    case 8: // ARGB (32-bit)
      (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
    default:
      (a, r, g, b) = (255, 0, 0, 0)
    }
    self.init(
      .sRGB,
      red: Double(r) / 255,
      green: Double(g) / 255,
      blue: Double(b) / 255,
      opacity: Double(a) / 255
    )
  }
}
```

### Typography.swift (in RIZQKit/Design/)

```swift
import SwiftUI

public extension Font {
  // MARK: - Display (Headings)
  static func rizqDisplay(_ style: Font.TextStyle) -> Font {
    .custom("PlayfairDisplay-Regular", size: UIFont.preferredFont(forTextStyle: style.uiKit).pointSize, relativeTo: style)
  }

  // MARK: - Sans (Body)
  static func rizqSans(_ style: Font.TextStyle) -> Font {
    .custom("CrimsonPro-Regular", size: UIFont.preferredFont(forTextStyle: style.uiKit).pointSize, relativeTo: style)
  }

  // MARK: - Arabic
  static func rizqArabic(_ style: Font.TextStyle) -> Font {
    .custom("Amiri-Regular", size: UIFont.preferredFont(forTextStyle: style.uiKit).pointSize * 1.2, relativeTo: style)
  }

  // MARK: - Mono (Numbers)
  static func rizqMono(_ style: Font.TextStyle) -> Font {
    .custom("JetBrainsMono-Regular", size: UIFont.preferredFont(forTextStyle: style.uiKit).pointSize, relativeTo: style)
  }
}

// MARK: - TextStyle Extension
private extension Font.TextStyle {
  var uiKit: UIFont.TextStyle {
    switch self {
    case .largeTitle: return .largeTitle
    case .title: return .title1
    case .title2: return .title2
    case .title3: return .title3
    case .headline: return .headline
    case .subheadline: return .subheadline
    case .body: return .body
    case .callout: return .callout
    case .footnote: return .footnote
    case .caption: return .caption1
    case .caption2: return .caption2
    @unknown default: return .body
    }
  }
}
```

---

## Step 8: Create Placeholder Features

### HomeFeature.swift

```swift
import ComposableArchitecture

@Reducer
struct HomeFeature {
  @ObservableState
  struct State: Equatable {
    var streak: Int = 0
    var todaysProgress: Int = 0
    var totalHabits: Int = 5
  }

  enum Action {
    case onAppear
  }

  var body: some ReducerOf<Self> {
    Reduce { state, action in
      switch action {
      case .onAppear:
        return .none
      }
    }
  }
}
```

### HomeView.swift

```swift
import SwiftUI
import ComposableArchitecture

struct HomeView: View {
  let store: StoreOf<HomeFeature>

  var body: some View {
    NavigationStack {
      ScrollView {
        VStack(spacing: 20) {
          Text("Welcome to RIZQ")
            .font(.rizqDisplay(.largeTitle))

          Text("Your dua practice journey starts here")
            .font(.rizqSans(.body))
            .foregroundStyle(.secondary)
        }
        .padding()
      }
      .background(Color.rizqBackground)
      .navigationTitle("Home")
    }
    .onAppear { store.send(.onAppear) }
  }
}
```

---

## Step 9: Create Gemfile and fastlane

### Gemfile

```ruby
source "https://rubygems.org"

gem "fastlane"
gem "cocoapods" # If needed
```

### fastlane/Appfile

```ruby
app_identifier("{{ bundle_id | default: 'com.rizq.app' }}")
apple_id("developer@rizq.app")
team_id("{{ team_id | default: 'XXXXXXXXXX' }}")
```

---

## Step 10: Create .gitignore

```gitignore
# Xcode
*.xcodeproj/
!*.xcodeproj/xcshareddata/
*.xcuserdata
*.xcscmblueprint
build/
DerivedData/
*.ipa
*.dSYM.zip
*.dSYM

# Swift Package Manager
.build/
.swiftpm/
Package.resolved

# CocoaPods
Pods/

# fastlane
fastlane/report.xml
fastlane/Preview.html
fastlane/screenshots
fastlane/test_output

# Ruby
.bundle/
vendor/bundle

# Misc
.DS_Store
*.swp
*~
```

---

## Step 11: Generate and Open Project

```bash
echo "=== Generating Xcode Project ==="

cd "$PROJECT_ROOT"

# Generate project
xcodegen generate

if [ $? -eq 0 ]; then
  echo "✅ Project generated successfully"

  # Install Ruby dependencies
  bundle install

  # Open in Xcode
  open {{ name | default: "RIZQ" }}.xcodeproj

  echo ""
  echo "╔══════════════════════════════════════════════════════════╗"
  echo "║               PROJECT SETUP COMPLETE                     ║"
  echo "╠══════════════════════════════════════════════════════════╣"
  echo "║  Project:     {{ name | default: 'RIZQ' }}                                         ║"
  echo "║  Bundle ID:   {{ bundle_id | default: 'com.rizq.app' }}                       ║"
  echo "║  Min iOS:     {{ min_ios | default: '17.0' }}                                     ║"
  echo "╠══════════════════════════════════════════════════════════╣"
  echo "║  Next Steps:                                             ║"
  echo "║  1. Select your Development Team in Xcode                ║"
  echo "║  2. Build and run to verify setup (Cmd+R)                ║"
  echo "║  3. Use /generate-feature to add features                ║"
  echo "║  4. Use /setup-fastlane to configure CI/CD               ║"
  echo "╚══════════════════════════════════════════════════════════╝"
else
  echo "❌ Project generation failed"
  exit 1
fi
```

---

## Project Structure Created

```
{{ name | default: "RIZQ" }}-iOS/
├── project.yml                      # XcodeGen spec (source of truth)
├── {{ name | default: "RIZQ" }}.xcodeproj/              # Generated (gitignored)
├── {{ name | default: "RIZQ" }}/                        # Main app target
│   ├── App/
│   │   ├── RIZQApp.swift
│   │   ├── AppFeature.swift
│   │   └── AppView.swift
│   ├── Features/
│   │   ├── Home/
│   │   ├── Library/
│   │   ├── Practice/
│   │   ├── Journeys/
│   │   ├── Settings/
│   │   └── Auth/
│   ├── Views/
│   │   ├── Components/
│   │   └── Screens/
│   ├── Resources/
│   │   └── Fonts/
│   ├── Assets.xcassets/
│   ├── Info.plist
│   └── {{ name | default: "RIZQ" }}.entitlements
├── {{ name | default: "RIZQ" }}Kit/                     # Shared framework
│   ├── Models/
│   ├── Services/
│   ├── Design/
│   │   ├── Colors.swift
│   │   └── Typography.swift
│   ├── Extensions/
│   └── Info.plist
├── {{ name | default: "RIZQ" }}Tests/                   # Unit tests
│   ├── Features/
│   ├── Mocks/
│   └── Info.plist
├── {{ name | default: "RIZQ" }}SnapshotTests/           # Snapshot tests
│   ├── Features/
│   ├── __Snapshots__/
│   └── Info.plist
├── {{ name | default: "RIZQ" }}Widget/                  # Widget extension
├── fastlane/
├── Gemfile
└── .gitignore
```

---

## After Running

1. **Select Development Team** in Xcode Signing & Capabilities
2. **Build and Run** to verify setup works
3. **Add fonts** to `Resources/Fonts/` (Crimson Pro, Playfair Display, Amiri, JetBrains Mono)
4. **Use `/generate-feature`** to create new TCA features
5. **Use `/translate-page`** to convert React pages to SwiftUI
6. **Use `/setup-fastlane`** to configure CI/CD
