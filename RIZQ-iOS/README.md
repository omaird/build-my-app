# RIZQ iOS

Native iOS app for the RIZQ dua practice platform. Built with SwiftUI and The Composable Architecture (TCA), featuring Firebase Authentication, offline-first design, and a home screen widget.

## Prerequisites

- **Xcode 15.2+** (Swift 5.9)
- **iOS 17.0+** deployment target
- **Ruby 3.0+** with Bundler (for Fastlane)
- **XcodeGen** (`brew install xcodegen`)
- **SwiftLint** (`brew install swiftlint`) — optional but recommended

## Quick Start

### 1. Install Dependencies

```bash
cd RIZQ-iOS

# Install Ruby dependencies (Fastlane)
bundle install

# Generate Xcode project from project.yml
xcodegen generate
```

### 2. Open in Xcode

```bash
open RIZQ.xcodeproj
```

Swift Package Manager will automatically resolve dependencies on first open.

### 3. Configure Firebase

1. Add your `GoogleService-Info.plist` to `RIZQ/Resources/`
2. Ensure the file is included in the RIZQ target

### 4. Run the App

Select the **RIZQ** scheme and run on simulator or device (⌘R).

## Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                      SwiftUI Views                          │
└─────────────────────────────┬───────────────────────────────┘
                              │
┌─────────────────────────────▼───────────────────────────────┐
│              The Composable Architecture (TCA)              │
│  ┌──────────┐  ┌──────────┐  ┌──────────┐  ┌──────────┐    │
│  │  State   │  │  Action  │  │ Reducer  │  │  Store   │    │
│  └──────────┘  └──────────┘  └──────────┘  └──────────┘    │
└─────────────────────────────┬───────────────────────────────┘
                              │
              ┌───────────────┴───────────────┐
              │                               │
      ┌───────▼───────┐             ┌─────────▼────────┐
      │   RIZQKit     │             │    Dependencies  │
      │  (Framework)  │             │   (DI Container) │
      └───────┬───────┘             └──────────────────┘
              │
      ┌───────┴───────┐
      │               │
┌─────▼─────┐   ┌─────▼─────┐
│ Firebase  │   │   Neon    │
│   Auth    │   │ PostgreSQL│
└───────────┘   └───────────┘
```

### Tech Stack

| Layer | Technology |
|-------|------------|
| UI | SwiftUI, iOS 17+ |
| Architecture | The Composable Architecture (TCA) 1.17 |
| Auth | Firebase Auth 11.0, Google Sign-In 8.0 |
| Images | Nuke 12.8 |
| Testing | XCTest, swift-snapshot-testing 1.17 |
| Build | XcodeGen, Fastlane |
| Linting | SwiftLint |

### Project Structure

```
RIZQ-iOS/
├── RIZQ/                    # Main app target
│   ├── App/
│   │   ├── RIZQApp.swift        # App entry point
│   │   ├── AppFeature.swift     # Root TCA feature
│   │   └── AppView.swift        # Root view with tab bar
│   ├── Features/
│   │   ├── Adkhar/              # Daily habits feature
│   │   ├── Admin/               # Admin panel
│   │   ├── Auth/                # Authentication flow
│   │   ├── Home/                # Dashboard
│   │   ├── Journeys/            # Journey selection & detail
│   │   ├── Library/             # Dua library browser
│   │   ├── Practice/            # Dua practice with counter
│   │   └── Settings/            # User settings
│   ├── Views/Components/        # Reusable UI components
│   ├── Resources/               # GoogleService-Info.plist, etc.
│   └── Assets.xcassets          # Images, colors, app icon
├── RIZQKit/                 # Shared framework
│   ├── Models/                  # Data models (Dua, Journey, etc.)
│   └── Services/
│       ├── API/                 # API client for Neon
│       └── Auth/                # Firebase auth service
├── RIZQTests/               # Unit tests
├── RIZQSnapshotTests/       # Snapshot tests
├── RIZQWidget/              # Home screen widget
├── fastlane/                # Build automation
├── docs/                    # Implementation documentation
└── project.yml              # XcodeGen specification
```

### TCA Feature Pattern

Each feature follows the TCA pattern:

```swift
@Reducer
struct MyFeature {
  @ObservableState
  struct State: Equatable {
    var items: [Item] = []
    var isLoading = false
  }

  enum Action {
    case onAppear
    case itemsLoaded([Item])
    case itemTapped(Item)
  }

  @Dependency(\.apiClient) var apiClient

  var body: some ReducerOf<Self> {
    Reduce { state, action in
      switch action {
      case .onAppear:
        state.isLoading = true
        return .run { send in
          let items = try await apiClient.fetchItems()
          await send(.itemsLoaded(items))
        }
      // ...
      }
    }
  }
}
```

## Targets

| Target | Type | Description |
|--------|------|-------------|
| `RIZQ` | Application | Main iOS app |
| `RIZQKit` | Framework | Shared models, services, auth |
| `RIZQTests` | Unit Tests | TCA reducer tests |
| `RIZQSnapshotTests` | Snapshot Tests | UI screenshot tests |
| `RIZQWidget` | Widget Extension | Home screen widget |

## Fastlane

Available lanes for build automation:

| Lane | Description |
|------|-------------|
| `fastlane test` | Run all unit and snapshot tests |
| `fastlane build` | Build release IPA |
| `fastlane beta` | Run tests, build, upload to TestFlight |
| `fastlane release version:X.Y.Z` | Bump version and upload to TestFlight |
| `fastlane certificates` | Sync code signing with Match |
| `fastlane add_device name:'iPhone' udid:'xxx'` | Register test device |

### Running Tests

```bash
# Via Fastlane (recommended)
bundle exec fastlane test

# Via xcodebuild
xcodebuild test \
  -project RIZQ.xcodeproj \
  -scheme RIZQ \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro'
```

### Building for TestFlight

```bash
# Full beta flow: test → build → upload
bundle exec fastlane beta

# Release with version bump
bundle exec fastlane release version:1.2.0
```

## Dependencies

Managed via Swift Package Manager (SPM):

| Package | Version | Purpose |
|---------|---------|---------|
| [ComposableArchitecture](https://github.com/pointfreeco/swift-composable-architecture) | 1.17.0 | State management |
| [swift-dependencies](https://github.com/pointfreeco/swift-dependencies) | 1.0+ | Dependency injection |
| [swift-case-paths](https://github.com/pointfreeco/swift-case-paths) | 1.0+ | Enum utilities |
| [Firebase iOS SDK](https://github.com/firebase/firebase-ios-sdk) | 11.0+ | Auth, Firestore |
| [GoogleSignIn-iOS](https://github.com/google/GoogleSignIn-iOS) | 8.0+ | Google OAuth |
| [Nuke](https://github.com/kean/Nuke) | 12.8 | Image loading |
| [swift-snapshot-testing](https://github.com/pointfreeco/swift-snapshot-testing) | 1.17+ | Snapshot tests |

## XcodeGen

The Xcode project is generated from `project.yml`. After modifying the YAML:

```bash
xcodegen generate
```

Fastlane lanes automatically regenerate the project before building.

## SwiftLint

Runs as a pre-build script. Configuration in `.swiftlint.yml`:

- Disabled: `line_length`, `trailing_whitespace`, `identifier_name`
- Enabled: `force_unwrapping`, `empty_count`, `empty_string`

## Documentation

Detailed implementation docs in `docs/`:

| Document | Description |
|----------|-------------|
| `00-MASTER-PLAN.md` | Overall implementation roadmap |
| `01-PHASE1-DATABASE-LAYER.md` | Neon database integration |
| `02-PHASE2-CORE-FEATURES.md` | Core feature implementation |
| `03-PHASE3-USER-DATA.md` | User data and profiles |
| `04-PHASE4-HABITS.md` | Habit tracking system |
| `05-PHASE5-UI-ALIGNMENT.md` | UI/UX alignment with web app |
| `06-PHASE6-TESTING.md` | Testing strategy |
| `BEST-PRACTICES.md` | TCA patterns and conventions |

## Troubleshooting

### Package Resolution Failed

If SPM fails to resolve packages:
```bash
# Clean derived data
rm -rf ~/Library/Developer/Xcode/DerivedData/RIZQ-*

# Reset package caches
xcodegen generate
```

### SwiftLint Not Found

```bash
brew install swiftlint
```

### Ruby/Bundler Issues

```bash
# Install Ruby version manager
brew install rbenv

# Install required Ruby
rbenv install 3.4.7
rbenv local 3.4.7

# Install Bundler and gems
gem install bundler
bundle install
```

## Related

- [Root README](../README.md) — Project overview and web app setup
- [Fastlane Setup](fastlane/TESTFLIGHT_SETUP.md) — TestFlight configuration guide
