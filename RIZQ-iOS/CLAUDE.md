# RIZQ iOS - Development Guide

This document contains conventions and patterns that Claude should follow when working on the RIZQ iOS codebase.

## Project Overview

RIZQ iOS is a native iOS app for the RIZQ dua practice platform. Built with SwiftUI and The Composable Architecture (TCA), it mirrors the React web app's functionality with a native iOS experience.

### Core Features
- **Dua Practice**: Arabic text, transliteration, translation with repetition counter
- **Journeys**: Themed dua collections users subscribe to
- **Daily Adkhar**: Habit system with morning/anytime/evening time slots
- **Gamification**: XP, levels, streaks, celebratory animations
- **Home Screen Widget**: Quick access to daily progress
- **Offline Support**: Cached data for offline practice

## Tech Stack

| Layer | Technology | Version |
|-------|------------|---------|
| Language | Swift | 5.9 |
| UI | SwiftUI | iOS 17+ |
| Architecture | The Composable Architecture (TCA) | 1.17 |
| Auth | Firebase Auth | 11.0+ |
| Database | Firebase Firestore | 11.0+ |
| OAuth | Google Sign-In | 8.0+ |
| Images | Nuke | 12.8 |
| Testing | XCTest, swift-snapshot-testing | - |
| Build | XcodeGen, Fastlane | - |

## Project Structure

```
RIZQ-iOS/
├── RIZQ/                        # Main app target
│   ├── App/
│   │   ├── RIZQApp.swift            # App entry point
│   │   ├── AppFeature.swift         # Root TCA reducer
│   │   └── AppView.swift            # Root view with navigation
│   ├── Features/
│   │   ├── Adkhar/                  # Daily habits
│   │   │   ├── AdkharFeature.swift
│   │   │   └── AdkharView.swift
│   │   ├── Auth/                    # Authentication
│   │   │   ├── AuthFeature.swift
│   │   │   └── AuthView.swift
│   │   ├── Journeys/                # Journey browsing & detail
│   │   │   ├── JourneysFeature.swift
│   │   │   ├── JourneysView.swift
│   │   │   └── JourneyDetailView.swift
│   │   ├── Practice/                # Dua practice with counter
│   │   │   ├── PracticeFeature.swift
│   │   │   └── PracticeView.swift
│   │   └── Settings/                # User settings
│   │       ├── SettingsFeature.swift
│   │       └── SettingsView.swift
│   ├── Views/Components/            # Reusable UI components
│   ├── Resources/                   # GoogleService-Info.plist, etc.
│   └── Assets.xcassets
├── RIZQKit/                     # Shared framework
│   ├── Models/                      # Domain models
│   │   ├── Dua.swift
│   │   ├── Journey.swift
│   │   └── UserProfile.swift
│   ├── Services/
│   │   ├── API/                     # Firestore client
│   │   └── Auth/                    # Auth service
│   └── Dependencies/                # TCA dependencies
├── RIZQTests/                   # Unit tests
├── RIZQSnapshotTests/           # Snapshot tests
├── RIZQWidget/                  # Home screen widget
├── fastlane/                    # Build automation
├── docs/                        # Implementation docs
├── .claude/reference/           # Claude reference docs
└── project.yml                  # XcodeGen spec
```

## Code Conventions

### Naming

| Type | Convention | Example |
|------|------------|---------|
| Features | `[Name]Feature.swift` | `JourneysFeature.swift` |
| Views | `[Name]View.swift` | `JourneysView.swift` |
| Models | PascalCase struct | `struct Journey` |
| Protocols | `[Name]Protocol` | `AuthServiceProtocol` |
| Dependencies | camelCase key path | `\.firestoreClient` |
| Test files | `[Name]Tests.swift` | `JourneysFeatureTests.swift` |

### TCA Feature Pattern

Every feature follows this structure:

```swift
import ComposableArchitecture

@Reducer
struct MyFeature {
    // 1. State
    @ObservableState
    struct State: Equatable {
        var items: [Item] = []
        var isLoading = false
        @Presents var detail: DetailFeature.State?
    }

    // 2. Actions
    enum Action {
        case onAppear
        case itemTapped(Item)
        case itemsLoaded(Result<[Item], Error>)
        case detail(PresentationAction<DetailFeature.Action>)
    }

    // 3. Dependencies
    @Dependency(\.firestoreClient) var firestoreClient

    // 4. Body
    var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .onAppear:
                state.isLoading = true
                return .run { send in
                    let items = try await firestoreClient.fetchItems()
                    await send(.itemsLoaded(.success(items)))
                } catch: { error, send in
                    await send(.itemsLoaded(.failure(error)))
                }
            // ... other cases
            }
        }
        .ifLet(\.$detail, action: \.detail) {
            DetailFeature()
        }
    }
}
```

### SwiftUI View Pattern

```swift
import SwiftUI
import ComposableArchitecture

struct MyView: View {
    @Bindable var store: StoreOf<MyFeature>

    var body: some View {
        NavigationStack {
            content
                .navigationTitle("My Feature")
        }
        .onAppear { store.send(.onAppear) }
        .sheet(item: $store.scope(state: \.detail, action: \.detail)) { store in
            DetailView(store: store)
        }
    }

    @ViewBuilder
    private var content: some View {
        if store.isLoading {
            ProgressView()
        } else if store.items.isEmpty {
            ContentUnavailableView("No Items", systemImage: "tray")
        } else {
            List(store.items) { item in
                ItemRow(item: item)
                    .onTapGesture { store.send(.itemTapped(item)) }
            }
        }
    }
}
```

## Key Patterns

### Action Naming

| Type | Convention | Example |
|------|------------|---------|
| User tap | `[thing]Tapped` | `refreshTapped` |
| Lifecycle | `on[Event]` | `onAppear` |
| Text change | `[field]Changed` | `searchTextChanged` |
| Effect result | `[thing][PastVerb]` | `itemsLoaded` |
| Delegate | `delegate(Delegate)` | `delegate(.didComplete)` |

### Effect Patterns

```swift
// Basic async
case .onAppear:
    return .run { send in
        let data = try await apiClient.fetch()
        await send(.dataLoaded(.success(data)))
    }

// Parallel effects
case .onAppear:
    return .merge(
        .run { send in await send(.profileLoaded(...)) },
        .run { send in await send(.journeysLoaded(...)) }
    )

// Debounced
case .searchChanged(let query):
    return .run { send in
        try await Task.sleep(for: .milliseconds(300))
        await send(.searchResults(...))
    }
    .cancellable(id: CancelID.search, cancelInFlight: true)
```

### Navigation

```swift
// Modal presentation
@Presents var detail: DetailFeature.State?

// Show
state.detail = DetailFeature.State(item: item)

// Dismiss
state.detail = nil

// View
.sheet(item: $store.scope(state: \.detail, action: \.detail)) { ... }
```

## Data Layer Architecture

### Firebase-Only Architecture (Current)

As of January 2026, the iOS app uses **Firebase Firestore exclusively** for all data operations:

| Data Type | TCA Dependency | Service |
|-----------|----------------|---------|
| Content (duas, journeys, categories) | `\.firestoreContentClient` | `FirestoreContentService` |
| User data (profiles, activity) | `\.firestoreUserClient` | `FirebaseUserService` |
| Admin operations | `\.adminService` | `FirebaseAdminService` |
| Authentication | `\.authClient` | `FirebaseAuthService` |

### Deprecated: Neon PostgreSQL

The following Neon-related code is **deprecated but preserved** for potential rollback:

| Deprecated File | Replacement |
|-----------------|-------------|
| `NeonService.swift` | `FirebaseUserService`, `FirestoreContentService` |
| `NeonClient.swift` | `FirestoreUserClient`, `FirestoreContentClient` |
| `AdminService.swift` | `FirebaseAdminService` |
| `APIClient.swift` | Firebase services |
| `FirebaseNeonService.swift` | Direct Firebase services |

**Do NOT use deprecated Neon services in new code.**

### Rollback Procedure (If Needed)

If issues arise requiring Neon rollback:
1. Revert `AdminServiceKey.liveValue` to use `AdminService` in `AdminDashboardFeature.swift`
2. Update features to use `neonClient` instead of `firestoreUserClient`
3. Restore `ServiceContainer` Neon initialization in `Dependencies.swift`
4. Re-add Neon environment variables to `Info.plist`

## Dependencies

### Accessing Dependencies

```swift
@Dependency(\.firestoreContentClient) var firestoreContentClient  // Content data
@Dependency(\.firestoreUserClient) var firestoreUserClient        // User data
@Dependency(\.authClient) var authClient                          // Authentication
@Dependency(\.date.now) var now
@Dependency(\.dismiss) var dismiss
```

### Key Dependencies

| Dependency | Purpose |
|------------|---------|
| `\.firestoreContentClient` | Content (duas, journeys, categories) from Firestore |
| `\.firestoreUserClient` | User data (profiles, activity, completions) from Firestore |
| `\.authClient` | Firebase Authentication (sign in, sign up, OAuth) |
| `\.adminService` | Admin panel operations (user management) |
| `\.haptics` | Haptic feedback |
| `\.dismiss` | Dismiss presented views |
| `\.continuousClock` | Timing and delays |

## Testing

### Reducer Tests

```swift
@MainActor
func testOnAppearLoadsData() async {
    let store = TestStore(
        initialState: MyFeature.State()
    ) {
        MyFeature()
    } withDependencies: {
        $0.firestoreClient.fetchItems = { [.mock] }
    }

    await store.send(.onAppear) {
        $0.isLoading = true
    }

    await store.receive(.itemsLoaded(.success([.mock]))) {
        $0.isLoading = false
        $0.items = [.mock]
    }
}
```

### Snapshot Tests

```swift
func testJourneyCard() {
    let view = JourneyCardView(journey: .mock)
        .frame(width: 350)
        .padding()

    assertSnapshot(of: view, as: .image)
}
```

## Fastlane Commands

| Command | Description |
|---------|-------------|
| `bundle exec fastlane test` | Run all tests |
| `bundle exec fastlane build` | Build release IPA |
| `bundle exec fastlane beta` | Test + build + upload to TestFlight |

## Reference Documents

Detailed guides in `.claude/reference/`:

| Document | Topics |
|----------|--------|
| `tca-best-practices.md` | Feature structure, effects, navigation |
| `swiftui-best-practices.md` | View composition, bindings, animations |
| `firebase-ios-integration.md` | Auth, Firestore, offline support |
| `testing-ios.md` | TestStore, snapshots, mocking |
| `dependencies-and-di.md` | Custom dependencies, testing |

## Build Verification (REQUIRED)

**CRITICAL: Always verify the build compiles after making changes.**

```bash
# Standard build command - use iPhone 17 simulator
cd RIZQ-iOS && xcodebuild -scheme RIZQ \
  -destination 'platform=iOS Simulator,name=iPhone 17' \
  build 2>&1 | grep -E "(error:|BUILD SUCCEEDED|BUILD FAILED)"
```

**Build verification is mandatory after:**
- Adding or modifying any Swift file
- Changing model properties
- Adding new dependencies
- Modifying TCA features or views

## Type Safety Rules (CRITICAL)

### 1. Always Check Model Definitions Before Using Properties

Before accessing a property, verify its actual type in the model:

```swift
// ❌ WRONG - Assuming bestTime is an enum
dua.bestTime.rawValue  // bestTime is String?, not TimeSlot!

// ✅ CORRECT - Check the actual type in Dua.swift first
if let time = dua.bestTime {  // String?
  Label(time, systemImage: bestTimeIcon(for: time))
}
```

### 2. Handle Optionals Explicitly

Many model properties are optional - always handle nil cases:

```swift
// ❌ WRONG - difficulty is optional
switch dua.difficulty {  // DuaDifficulty? - won't compile!

// ✅ CORRECT - provide default or use optional chaining
switch dua.difficulty ?? .beginner {
// or
dua.difficulty?.rawValue ?? "Beginner"
```

### 3. Use SampleData for Previews

Preview demo data is in `SampleData`, not on models directly:

```swift
// ❌ WRONG - Dua doesn't have demoData
Dua.demoData[0]

// ✅ CORRECT - Use SampleData or add extension
SampleData.duas[0]
// or if extension exists:
Dua.demoData[0]  // Check if extension exists first!
```

### 4. TCA Dependencies - No Macros

This codebase uses manual dependency registration, not the `@DependencyClient` macro:

```swift
// ❌ WRONG - Macro may not work
@DependencyClient
struct MyClient: Sendable { ... }

// ✅ CORRECT - Manual struct with all closures defined
struct MyClient: Sendable {
  var fetch: @Sendable () async throws -> [Item]
}

extension MyClient: DependencyKey {
  static let liveValue = MyClient(fetch: { ... })
  static let testValue = MyClient(fetch: { [] })  // Provide all closures!
}
```

## Common Type Pitfalls

| Property | Actual Type | Common Mistake |
|----------|-------------|----------------|
| `dua.bestTime` | `String?` | Treating as `TimeSlot` enum |
| `dua.difficulty` | `DuaDifficulty?` | Treating as non-optional |
| `CategoryDisplay` | struct with `emoji` | Using `.icon` (add computed property) |
| `dua.context` | Does not exist | Using without checking model |

## Simulator Information

| Simulator | Status |
|-----------|--------|
| iPhone 17 | ✅ Current (use this) |
| iPhone 16 | ❌ Deprecated |

## Do

- Use `@ObservableState` for all TCA state
- Use `@Bindable var store` for binding support
- Extract subviews for complex views
- Test reducer logic with TestStore
- Use `.run` effects for async work
- Capture state values before entering `.run` blocks
- **Always read model definitions before using properties**
- **Run build verification after every change**
- **Check SampleData.swift for available demo data**

## Don't

- Don't put business logic in views
- Don't use `@State` for domain data
- Don't access dependencies outside reducers
- Don't block the main thread
- Don't skip effect assertions in tests
- Don't use real network in unit tests
- **Don't assume property types - verify in model files**
- **Don't use `@DependencyClient` macro - use manual registration**
- **Don't skip build verification after changes**
- **Don't reference properties that don't exist on models**
