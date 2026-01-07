---
name: tca-patterns
description: "The Composable Architecture patterns for RIZQ iOS - Reducer, Effect, Dependency, Store composition, and testing"
---

# TCA Patterns for RIZQ iOS

The Composable Architecture (TCA) is the state management framework for RIZQ iOS. This skill covers all the patterns you need.

## Core Concepts

### 1. Reducer Structure

Every feature has a `@Reducer` that combines:
- **State**: Data the feature needs
- **Action**: All possible events
- **body**: Logic that transforms state based on actions

```swift
import ComposableArchitecture

@Reducer
struct MyFeature {
  @ObservableState
  struct State: Equatable {
    // Data goes here
  }

  enum Action {
    // Events go here
  }

  var body: some ReducerOf<Self> {
    Reduce { state, action in
      switch action {
      // Handle each action
      }
    }
  }
}
```

---

## Feature Module Pattern (RIZQ Standard)

### Basic Feature

```swift
// PracticeFeature.swift
import ComposableArchitecture

@Reducer
struct PracticeFeature {
  // MARK: - State
  @ObservableState
  struct State: Equatable {
    var dua: Dua
    var tapCount: Int = 0
    var isCompleted: Bool = false
    var showCelebration: Bool = false
    var showTransliteration: Bool = true

    // Computed properties are fine
    var progress: Double {
      guard dua.repetitions > 0 else { return 0 }
      return Double(tapCount) / Double(dua.repetitions)
    }

    var remainingTaps: Int {
      max(0, dua.repetitions - tapCount)
    }
  }

  // MARK: - Action
  enum Action: Equatable {
    // User actions
    case tapped
    case resetTapped
    case toggleTransliteration
    case celebrationDismissed

    // Delegate actions (for parent communication)
    case delegate(Delegate)

    @CasePathable
    enum Delegate: Equatable {
      case practiceCompleted(duaId: String, xpEarned: Int)
    }
  }

  // MARK: - Dependencies
  @Dependency(\.hapticsClient) var haptics
  @Dependency(\.continuousClock) var clock

  // MARK: - Reducer Body
  var body: some ReducerOf<Self> {
    Reduce { state, action in
      switch action {
      case .tapped:
        guard !state.isCompleted else { return .none }
        state.tapCount += 1

        let isComplete = state.tapCount >= state.dua.repetitions

        return .run { _ in
          await haptics.impact(isComplete ? .heavy : .light)
        }
        .concatenate(with: isComplete ? completeEffect(state: &state) : .none)

      case .resetTapped:
        state.tapCount = 0
        state.isCompleted = false
        return .run { _ in await haptics.impact(.medium) }

      case .toggleTransliteration:
        state.showTransliteration.toggle()
        return .none

      case .celebrationDismissed:
        state.showCelebration = false
        return .none

      case .delegate:
        // Handled by parent
        return .none
      }
    }
  }

  // MARK: - Private Helpers
  private func completeEffect(state: inout State) -> Effect<Action> {
    state.isCompleted = true
    state.showCelebration = true

    return .send(.delegate(.practiceCompleted(
      duaId: state.dua.id,
      xpEarned: state.dua.xpValue
    )))
  }
}
```

---

## Async Data Loading Pattern

```swift
@Reducer
struct LibraryFeature {
  @ObservableState
  struct State: Equatable {
    var duas: [Dua] = []
    var isLoading = false
    var errorMessage: String?
    var searchQuery = ""

    var filteredDuas: [Dua] {
      guard !searchQuery.isEmpty else { return duas }
      return duas.filter { $0.title.localizedCaseInsensitiveContains(searchQuery) }
    }
  }

  enum Action: Equatable {
    case onAppear
    case refresh
    case searchQueryChanged(String)
    case duasResponse(Result<[Dua], Error>)
    case duaTapped(Dua)
    case delegate(Delegate)

    enum Delegate: Equatable {
      case navigateToPractice(Dua)
    }
  }

  @Dependency(\.apiClient) var apiClient

  var body: some ReducerOf<Self> {
    Reduce { state, action in
      switch action {
      case .onAppear:
        guard state.duas.isEmpty else { return .none }
        return loadDuas(state: &state)

      case .refresh:
        return loadDuas(state: &state)

      case .searchQueryChanged(let query):
        state.searchQuery = query
        return .none

      case .duasResponse(.success(let duas)):
        state.isLoading = false
        state.duas = duas
        state.errorMessage = nil
        return .none

      case .duasResponse(.failure(let error)):
        state.isLoading = false
        state.errorMessage = error.localizedDescription
        return .none

      case .duaTapped(let dua):
        return .send(.delegate(.navigateToPractice(dua)))

      case .delegate:
        return .none
      }
    }
  }

  private func loadDuas(state: inout State) -> Effect<Action> {
    state.isLoading = true
    state.errorMessage = nil

    return .run { send in
      await send(.duasResponse(Result {
        try await apiClient.fetchDuas()
      }))
    }
  }
}
```

---

## Navigation Pattern (Stack-Based)

```swift
@Reducer
struct AppFeature {
  @ObservableState
  struct State: Equatable {
    var path = StackState<Path.State>()
    var selectedTab: Tab = .home

    // Tab features
    var home = HomeFeature.State()
    var library = LibraryFeature.State()
    var adkhar = AdkharFeature.State()
    var journeys = JourneysFeature.State()
    var settings = SettingsFeature.State()

    enum Tab: Equatable, CaseIterable {
      case home, library, adkhar, journeys, settings
    }
  }

  enum Action {
    case path(StackActionOf<Path>)
    case tabSelected(State.Tab)

    // Tab feature actions
    case home(HomeFeature.Action)
    case library(LibraryFeature.Action)
    case adkhar(AdkharFeature.Action)
    case journeys(JourneysFeature.Action)
    case settings(SettingsFeature.Action)
  }

  // MARK: - Path Reducer (Push destinations)
  @Reducer
  struct Path {
    @ObservableState
    enum State: Equatable {
      case practice(PracticeFeature.State)
      case journeyDetail(JourneyDetailFeature.State)
      case duaDetail(DuaDetailFeature.State)
    }

    enum Action {
      case practice(PracticeFeature.Action)
      case journeyDetail(JourneyDetailFeature.Action)
      case duaDetail(DuaDetailFeature.Action)
    }

    var body: some ReducerOf<Self> {
      Scope(state: \.practice, action: \.practice) {
        PracticeFeature()
      }
      Scope(state: \.journeyDetail, action: \.journeyDetail) {
        JourneyDetailFeature()
      }
      Scope(state: \.duaDetail, action: \.duaDetail) {
        DuaDetailFeature()
      }
    }
  }

  var body: some ReducerOf<Self> {
    // Scope each tab
    Scope(state: \.home, action: \.home) { HomeFeature() }
    Scope(state: \.library, action: \.library) { LibraryFeature() }
    Scope(state: \.adkhar, action: \.adkhar) { AdkharFeature() }
    Scope(state: \.journeys, action: \.journeys) { JourneysFeature() }
    Scope(state: \.settings, action: \.settings) { SettingsFeature() }

    Reduce { state, action in
      switch action {
      case .tabSelected(let tab):
        state.selectedTab = tab
        return .none

      // Handle delegate actions from children
      case .library(.delegate(.navigateToPractice(let dua))):
        state.path.append(.practice(PracticeFeature.State(dua: dua)))
        return .none

      case .journeys(.delegate(.navigateToDetail(let journey))):
        state.path.append(.journeyDetail(JourneyDetailFeature.State(journey: journey)))
        return .none

      // Handle practice completion
      case .path(.element(id: _, action: .practice(.delegate(.practiceCompleted(let duaId, let xp))))):
        // Update XP in home state
        state.home.profile?.totalXp += xp
        return .none

      default:
        return .none
      }
    }
    .forEach(\.path, action: \.path) {
      Path()
    }
  }
}
```

### Navigation View

```swift
struct AppView: View {
  @Bindable var store: StoreOf<AppFeature>

  var body: some View {
    NavigationStack(path: $store.scope(state: \.path, action: \.path)) {
      TabView(selection: $store.selectedTab.sending(\.tabSelected)) {
        HomeView(store: store.scope(state: \.home, action: \.home))
          .tag(AppFeature.State.Tab.home)
          .tabItem { Label("Home", systemImage: "house") }

        LibraryView(store: store.scope(state: \.library, action: \.library))
          .tag(AppFeature.State.Tab.library)
          .tabItem { Label("Library", systemImage: "books.vertical") }

        // ... other tabs
      }
    } destination: { store in
      switch store.case {
      case .practice(let store):
        PracticeView(store: store)
      case .journeyDetail(let store):
        JourneyDetailView(store: store)
      case .duaDetail(let store):
        DuaDetailView(store: store)
      }
    }
  }
}
```

---

## Dependency Injection Pattern

### Defining a Dependency Client

```swift
// APIClient.swift
import Dependencies
import Foundation

struct APIClient: Sendable {
  var fetchDuas: @Sendable () async throws -> [Dua]
  var fetchJourneys: @Sendable () async throws -> [Journey]
  var fetchUserProfile: @Sendable (UUID) async throws -> UserProfile
  var updateXP: @Sendable (UUID, Int) async throws -> UserProfile
  var markDuaCompleted: @Sendable (UUID, String) async throws -> Void
}

// MARK: - DependencyKey Conformance
extension APIClient: DependencyKey {
  static let liveValue = APIClient(
    fetchDuas: {
      // Real API call to Neon
      let data = try await URLSession.shared.data(from: URL(string: "\(baseURL)/duas")!).0
      return try JSONDecoder().decode([Dua].self, from: data)
    },
    fetchJourneys: {
      // Real API call
    },
    fetchUserProfile: { userId in
      // Real API call
    },
    updateXP: { userId, amount in
      // Real API call
    },
    markDuaCompleted: { userId, duaId in
      // Real API call
    }
  )

  static let testValue = APIClient(
    fetchDuas: { [] },
    fetchJourneys: { [] },
    fetchUserProfile: { _ in .mock },
    updateXP: { _, _ in .mock },
    markDuaCompleted: { _, _ in }
  )

  static let previewValue = APIClient(
    fetchDuas: { Dua.mockList },
    fetchJourneys: { Journey.mockList },
    fetchUserProfile: { _ in .mock },
    updateXP: { _, _ in .mock },
    markDuaCompleted: { _, _ in }
  )
}

// MARK: - Register in DependencyValues
extension DependencyValues {
  var apiClient: APIClient {
    get { self[APIClient.self] }
    set { self[APIClient.self] = newValue }
  }
}
```

### Haptics Client

```swift
// HapticsClient.swift
import Dependencies
import UIKit

struct HapticsClient: Sendable {
  var impact: @Sendable (UIImpactFeedbackGenerator.FeedbackStyle) async -> Void
  var notification: @Sendable (UINotificationFeedbackGenerator.FeedbackType) async -> Void
  var selection: @Sendable () async -> Void
}

extension HapticsClient: DependencyKey {
  static let liveValue = HapticsClient(
    impact: { style in
      await MainActor.run {
        UIImpactFeedbackGenerator(style: style).impactOccurred()
      }
    },
    notification: { type in
      await MainActor.run {
        UINotificationFeedbackGenerator().notificationOccurred(type)
      }
    },
    selection: {
      await MainActor.run {
        UISelectionFeedbackGenerator().selectionChanged()
      }
    }
  )

  static let testValue = HapticsClient(
    impact: { _ in },
    notification: { _ in },
    selection: { }
  )
}

extension DependencyValues {
  var hapticsClient: HapticsClient {
    get { self[HapticsClient.self] }
    set { self[HapticsClient.self] = newValue }
  }
}
```

---

## Testing Pattern

```swift
import ComposableArchitecture
import XCTest

@MainActor
final class PracticeFeatureTests: XCTestCase {

  func testTapIncrementsCount() async {
    let store = TestStore(
      initialState: PracticeFeature.State(dua: .mock(repetitions: 3))
    ) {
      PracticeFeature()
    } withDependencies: {
      $0.hapticsClient = .testValue
    }

    await store.send(.tapped) {
      $0.tapCount = 1
    }

    await store.send(.tapped) {
      $0.tapCount = 2
    }
  }

  func testCompletionTriggersCelebration() async {
    let store = TestStore(
      initialState: PracticeFeature.State(dua: .mock(repetitions: 2))
    ) {
      PracticeFeature()
    } withDependencies: {
      $0.hapticsClient = .testValue
    }

    await store.send(.tapped) { $0.tapCount = 1 }

    await store.send(.tapped) {
      $0.tapCount = 2
      $0.isCompleted = true
      $0.showCelebration = true
    }

    await store.receive(.delegate(.practiceCompleted(duaId: "mock-id", xpEarned: 10)))
  }

  func testResetClearsState() async {
    var state = PracticeFeature.State(dua: .mock(repetitions: 3))
    state.tapCount = 2
    state.isCompleted = true

    let store = TestStore(initialState: state) {
      PracticeFeature()
    } withDependencies: {
      $0.hapticsClient = .testValue
    }

    await store.send(.resetTapped) {
      $0.tapCount = 0
      $0.isCompleted = false
    }
  }
}
```

---

## React Query → TCA Mapping

| React Query | TCA Equivalent |
|-------------|----------------|
| `useQuery` | `Effect` + `@Dependency` |
| `queryKey` | State property + dependency |
| `isLoading` | `state.isLoading` boolean |
| `data` | State property (e.g., `state.duas`) |
| `error` | `state.errorMessage: String?` |
| `refetch` | Send `.refresh` action |
| `enabled` | Guard in reducer or `.onAppear` |
| `staleTime` | Cache in dependency or state |

---

## Effect Patterns

### Sequential Effects

```swift
// Run one after another
return .concatenate(
  .run { _ in await haptics.impact(.light) },
  .send(.delegate(.completed))
)
```

### Parallel Effects

```swift
// Run simultaneously
return .merge(
  .run { send in await send(.profileResponse(try await api.fetchProfile())) },
  .run { send in await send(.activityResponse(try await api.fetchActivity())) }
)
```

### Debounced Effect (Search)

```swift
case .searchQueryChanged(let query):
  state.searchQuery = query
  return .run { send in
    try await clock.sleep(for: .milliseconds(300))
    await send(.performSearch)
  }
  .cancellable(id: CancelID.search, cancelInFlight: true)

private enum CancelID { case search }
```

### Timer Effect

```swift
case .startTimer:
  return .run { send in
    for await _ in clock.timer(interval: .seconds(1)) {
      await send(.timerTick)
    }
  }
  .cancellable(id: CancelID.timer)

case .stopTimer:
  return .cancel(id: CancelID.timer)
```
