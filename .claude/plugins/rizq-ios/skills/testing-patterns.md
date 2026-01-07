# iOS Testing Patterns for RIZQ

Comprehensive testing patterns using XCTest, TCA TestStore, and swift-snapshot-testing.

---

## Testing Architecture

### Test Target Structure

```
RIZQTests/                          # Unit tests
├── Features/
│   ├── Home/
│   │   └── HomeFeatureTests.swift
│   ├── Practice/
│   │   └── PracticeFeatureTests.swift
│   ├── Journeys/
│   │   └── JourneysFeatureTests.swift
│   └── Auth/
│       └── AuthFeatureTests.swift
├── Services/
│   ├── APIClientTests.swift
│   └── KeychainManagerTests.swift
├── Helpers/
│   └── TestDependencies.swift
└── Mocks/
    ├── MockAPIClient.swift
    └── MockAuthService.swift

RIZQSnapshotTests/                  # Snapshot tests
├── Features/
│   ├── Home/
│   │   └── HomeViewSnapshotTests.swift
│   ├── Practice/
│   │   └── PracticeViewSnapshotTests.swift
│   └── Journeys/
│       └── JourneyCardSnapshotTests.swift
├── Components/
│   ├── DuaCardSnapshotTests.swift
│   ├── StreakBadgeSnapshotTests.swift
│   └── XpProgressBarSnapshotTests.swift
├── __Snapshots__/                  # Generated reference images
└── SnapshotTestCase.swift          # Base test class
```

---

## TCA TestStore Patterns

### Basic TestStore Setup

```swift
import ComposableArchitecture
import XCTest

@testable import RIZQ

@MainActor
final class HomeFeatureTests: XCTestCase {

  func testLoadDuas() async {
    // Arrange: Create TestStore with mocked dependencies
    let store = TestStore(
      initialState: HomeFeature.State()
    ) {
      HomeFeature()
    } withDependencies: {
      // Override dependencies with test values
      $0.apiClient.fetchDuas = {
        [Dua.mock(id: 1), Dua.mock(id: 2)]
      }
      $0.date.now = Date(timeIntervalSince1970: 0)
    }

    // Act & Assert: Send action and verify state changes
    await store.send(.onAppear) {
      $0.isLoading = true
    }

    await store.receive(\.duasLoaded) {
      $0.isLoading = false
      $0.duas = [Dua.mock(id: 1), Dua.mock(id: 2)]
    }
  }
}
```

### Exhaustive vs Non-Exhaustive Testing

```swift
// EXHAUSTIVE (default) - Must assert ALL state changes
func testExhaustive() async {
  let store = TestStore(initialState: CounterFeature.State(count: 0)) {
    CounterFeature()
  }

  await store.send(.incrementTapped) {
    $0.count = 1  // MUST assert this change
  }
}

// NON-EXHAUSTIVE - Only assert what you care about
func testNonExhaustive() async {
  let store = TestStore(initialState: ComplexFeature.State()) {
    ComplexFeature()
  }
  store.exhaustivity = .off  // Disable exhaustive testing

  await store.send(.loadData)

  // Only verify specific fields
  await store.receive(\.dataLoaded) {
    $0.items.count = 5  // Only check count, not all properties
  }
}

// NON-EXHAUSTIVE with warnings (recommended for debugging)
func testNonExhaustiveWithWarnings() async {
  let store = TestStore(initialState: ComplexFeature.State()) {
    ComplexFeature()
  }
  store.exhaustivity = .off(showSkippedAssertions: true)

  // Will print warnings about unasserted changes
  await store.send(.complexAction)
}
```

### Testing Effects

```swift
func testAsyncEffect() async {
  let clock = TestClock()

  let store = TestStore(initialState: TimerFeature.State()) {
    TimerFeature()
  } withDependencies: {
    $0.continuousClock = clock
  }

  await store.send(.startTimer) {
    $0.isTimerRunning = true
  }

  // Advance clock to trigger timer effect
  await clock.advance(by: .seconds(1))

  await store.receive(\.timerTicked) {
    $0.secondsElapsed = 1
  }

  await store.send(.stopTimer) {
    $0.isTimerRunning = false
  }
}
```

### Testing Navigation

```swift
func testNavigationToDetail() async {
  let store = TestStore(
    initialState: JourneysFeature.State(
      journeys: [Journey.mock(id: 1)]
    )
  ) {
    JourneysFeature()
  }

  // Test pushing to detail
  await store.send(.journeyTapped(Journey.mock(id: 1))) {
    $0.path.append(.detail(JourneyDetailFeature.State(journey: .mock(id: 1))))
  }

  // Test popping
  await store.send(.path(.popFrom(id: 0))) {
    $0.path.removeLast()
  }
}
```

### Testing Alerts and Confirmations

```swift
func testDeleteConfirmation() async {
  let store = TestStore(
    initialState: HabitFeature.State(
      habit: .mock(id: 1)
    )
  ) {
    HabitFeature()
  }

  // Show delete confirmation
  await store.send(.deleteButtonTapped) {
    $0.alert = AlertState {
      TextState("Delete Habit?")
    } actions: {
      ButtonState(role: .destructive, action: .confirmDelete) {
        TextState("Delete")
      }
      ButtonState(role: .cancel) {
        TextState("Cancel")
      }
    }
  }

  // Confirm deletion
  await store.send(.alert(.presented(.confirmDelete))) {
    $0.alert = nil
  }

  await store.receive(\.habitDeleted)
}
```

---

## Dependency Mocking

### Creating Mock Dependencies

```swift
// In TestDependencies.swift
import ComposableArchitecture

@testable import RIZQ

extension DependencyValues {
  mutating func setUpTestDependencies() {
    self.apiClient = .testValue
    self.authClient = .testValue
    self.keychainManager = .testValue
    self.hapticClient = .testValue
    self.date = .constant(Date(timeIntervalSince1970: 1704067200)) // 2024-01-01
    self.uuid = .incrementing
  }
}

// Mock API Client
extension APIClient {
  static let testValue = Self(
    fetchDuas: { [] },
    fetchJourneys: { [] },
    fetchUserProfile: { _ in .mock() },
    updateUserProfile: { _, _ in },
    recordActivity: { _, _ in }
  )

  static func mock(
    fetchDuas: @escaping @Sendable () async throws -> [Dua] = { [] },
    fetchJourneys: @escaping @Sendable () async throws -> [Journey] = { [] }
  ) -> Self {
    var client = Self.testValue
    client.fetchDuas = fetchDuas
    client.fetchJourneys = fetchJourneys
    return client
  }
}

// Mock Auth Client
extension AuthClient {
  static let testValue = Self(
    currentUser: { nil },
    signIn: { _, _ in .mock() },
    signOut: { },
    signInWithApple: { .mock() },
    refreshToken: { }
  )
}
```

### Using withDependencies

```swift
func testWithCustomDependencies() async {
  let testDuas = [Dua.mock(id: 1, title: "Test Dua")]

  let store = TestStore(initialState: LibraryFeature.State()) {
    LibraryFeature()
  } withDependencies: {
    $0.apiClient.fetchDuas = { testDuas }
    $0.apiClient.fetchCategories = { [Category.mock(id: 1)] }
  }

  await store.send(.onAppear)
  await store.receive(\.dataLoaded) {
    $0.duas = testDuas
  }
}
```

---

## Mock Data Factories

### Creating Test Fixtures

```swift
// In Mocks/MockData.swift

extension Dua {
  static func mock(
    id: Int = 1,
    title: String = "Test Dua",
    arabicText: String = "بِسْمِ اللَّهِ",
    transliteration: String = "Bismillah",
    translation: String = "In the name of Allah",
    repetitions: Int = 3,
    xpValue: Int = 10,
    category: Category = .mock()
  ) -> Self {
    Dua(
      id: id,
      title: title,
      arabicText: arabicText,
      transliteration: transliteration,
      translation: translation,
      repetitions: repetitions,
      xpValue: xpValue,
      category: category
    )
  }
}

extension Journey {
  static func mock(
    id: Int = 1,
    name: String = "Test Journey",
    description: String = "A test journey",
    emoji: String = "🌟",
    estimatedMinutes: Int = 10,
    dailyXp: Int = 50,
    duas: [JourneyDua] = []
  ) -> Self {
    Journey(
      id: id,
      name: name,
      description: description,
      emoji: emoji,
      estimatedMinutes: estimatedMinutes,
      dailyXp: dailyXp,
      duas: duas
    )
  }
}

extension User {
  static func mock(
    id: String = "test-user-id",
    email: String = "test@example.com",
    name: String = "Test User",
    streak: Int = 5,
    totalXp: Int = 500,
    level: Int = 3
  ) -> Self {
    User(
      id: id,
      email: email,
      name: name,
      streak: streak,
      totalXp: totalXp,
      level: level
    )
  }
}
```

---

## Snapshot Testing

### Setup Base Test Class

```swift
// In RIZQSnapshotTests/SnapshotTestCase.swift

import SnapshotTesting
import SwiftUI
import XCTest

@testable import RIZQ

class SnapshotTestCase: XCTestCase {

  // MARK: - Configuration

  /// Set to true to record new snapshots
  var isRecording: Bool {
    // Can be controlled via environment variable for CI
    ProcessInfo.processInfo.environment["RECORD_SNAPSHOTS"] == "1"
  }

  // MARK: - Device Configurations

  enum DeviceConfig {
    static let iPhone15Pro = ViewImageConfig.iPhone15Pro
    static let iPhone15ProMax = ViewImageConfig.iPhone15ProMax
    static let iPhoneSE = ViewImageConfig.iPhoneSE(safeArea: .zero)

    static let all: [String: ViewImageConfig] = [
      "iPhone15Pro": iPhone15Pro,
      "iPhone15ProMax": iPhone15ProMax,
      "iPhoneSE": iPhoneSE,
    ]
  }

  // MARK: - Snapshot Helpers

  /// Snapshot a SwiftUI view on multiple devices
  func assertSnapshot<V: View>(
    _ view: V,
    devices: [String: ViewImageConfig] = DeviceConfig.all,
    precision: Float = 0.99,
    file: StaticString = #file,
    testName: String = #function,
    line: UInt = #line
  ) {
    for (name, config) in devices {
      SnapshotTesting.assertSnapshot(
        of: view,
        as: .image(precision: precision, layout: .device(config: config)),
        named: name,
        record: isRecording,
        file: file,
        testName: testName,
        line: line
      )
    }
  }

  /// Snapshot a single device (faster tests)
  func assertSnapshotSingleDevice<V: View>(
    _ view: V,
    config: ViewImageConfig = DeviceConfig.iPhone15Pro,
    precision: Float = 0.99,
    file: StaticString = #file,
    testName: String = #function,
    line: UInt = #line
  ) {
    SnapshotTesting.assertSnapshot(
      of: view,
      as: .image(precision: precision, layout: .device(config: config)),
      record: isRecording,
      file: file,
      testName: testName,
      line: line
    )
  }

  /// Snapshot in both light and dark mode
  func assertSnapshotBothModes<V: View>(
    _ view: V,
    config: ViewImageConfig = DeviceConfig.iPhone15Pro,
    precision: Float = 0.99,
    file: StaticString = #file,
    testName: String = #function,
    line: UInt = #line
  ) {
    // Light mode
    SnapshotTesting.assertSnapshot(
      of: view.environment(\.colorScheme, .light),
      as: .image(precision: precision, layout: .device(config: config)),
      named: "light",
      record: isRecording,
      file: file,
      testName: testName,
      line: line
    )

    // Dark mode
    SnapshotTesting.assertSnapshot(
      of: view.environment(\.colorScheme, .dark),
      as: .image(precision: precision, layout: .device(config: config)),
      named: "dark",
      record: isRecording,
      file: file,
      testName: testName,
      line: line
    )
  }
}
```

### View Snapshot Tests

```swift
// In RIZQSnapshotTests/Components/DuaCardSnapshotTests.swift

import SnapshotTesting
import SwiftUI
import XCTest

@testable import RIZQ

final class DuaCardSnapshotTests: SnapshotTestCase {

  func testDuaCard_Default() {
    let view = DuaCard(dua: .mock())
      .padding()
      .background(Color.cream)

    assertSnapshotBothModes(view)
  }

  func testDuaCard_LongArabicText() {
    let dua = Dua.mock(
      arabicText: "اللَّهُمَّ إِنِّي أَسْأَلُكَ الْهُدَى وَالتُّقَى وَالْعَفَافَ وَالْغِنَى",
      translation: "O Allah, I ask You for guidance, piety, chastity, and self-sufficiency"
    )

    let view = DuaCard(dua: dua)
      .padding()
      .background(Color.cream)

    assertSnapshotSingleDevice(view)
  }

  func testDuaCard_AllCategories() {
    let categories: [Category] = [.morning, .evening, .rizq, .gratitude]

    for category in categories {
      let dua = Dua.mock(category: category)
      let view = DuaCard(dua: dua)
        .padding()
        .background(Color.cream)

      SnapshotTesting.assertSnapshot(
        of: view,
        as: .image(layout: .device(config: DeviceConfig.iPhone15Pro)),
        named: category.slug,
        record: isRecording
      )
    }
  }
}
```

### Feature View Snapshot Tests

```swift
// In RIZQSnapshotTests/Features/Home/HomeViewSnapshotTests.swift

import ComposableArchitecture
import SnapshotTesting
import SwiftUI
import XCTest

@testable import RIZQ

final class HomeViewSnapshotTests: SnapshotTestCase {

  func testHomeView_Loading() {
    let store = Store(
      initialState: HomeFeature.State(isLoading: true)
    ) {
      HomeFeature()
    }

    let view = HomeView(store: store)
    assertSnapshotBothModes(view)
  }

  func testHomeView_Loaded() {
    let store = Store(
      initialState: HomeFeature.State(
        isLoading: false,
        user: .mock(streak: 7, totalXp: 500, level: 3),
        todaysHabits: [
          .mock(timeSlot: .morning, isCompleted: true),
          .mock(timeSlot: .anytime, isCompleted: false),
          .mock(timeSlot: .evening, isCompleted: false),
        ]
      )
    ) {
      HomeFeature()
    }

    let view = HomeView(store: store)
    assertSnapshotBothModes(view)
  }

  func testHomeView_EmptyState() {
    let store = Store(
      initialState: HomeFeature.State(
        isLoading: false,
        user: .mock(),
        todaysHabits: []
      )
    ) {
      HomeFeature()
    }

    let view = HomeView(store: store)
    assertSnapshotSingleDevice(view)
  }

  func testHomeView_StreakMilestone() {
    let store = Store(
      initialState: HomeFeature.State(
        isLoading: false,
        user: .mock(streak: 30, totalXp: 3000, level: 10),
        showingStreakCelebration: true
      )
    ) {
      HomeFeature()
    }

    let view = HomeView(store: store)
    assertSnapshotSingleDevice(view)
  }
}
```

### State Snapshot Testing

```swift
// Snapshot the state itself (useful for complex state)
func testReducerStateChanges() async {
  let store = TestStore(initialState: PracticeFeature.State(dua: .mock())) {
    PracticeFeature()
  }

  await store.send(.incrementCounter) {
    $0.currentCount = 1
  }

  // Snapshot the state
  assertSnapshot(of: store.state, as: .dump)
}
```

---

## Async Testing Patterns

### Testing Async Effects

```swift
func testAsyncDataLoading() async {
  let expectation = XCTestExpectation(description: "Data loaded")

  let store = TestStore(initialState: LibraryFeature.State()) {
    LibraryFeature()
  } withDependencies: {
    $0.apiClient.fetchDuas = {
      // Simulate network delay
      try await Task.sleep(for: .milliseconds(100))
      return [.mock()]
    }
  }

  await store.send(.loadData) {
    $0.isLoading = true
  }

  // Wait for effect to complete
  await store.receive(\.dataLoaded, timeout: .seconds(1)) {
    $0.isLoading = false
    $0.duas = [.mock()]
  }
}
```

### Testing Debounced Actions

```swift
func testSearchDebounce() async {
  let clock = TestClock()

  let store = TestStore(initialState: SearchFeature.State()) {
    SearchFeature()
  } withDependencies: {
    $0.continuousClock = clock
    $0.apiClient.search = { query in
      [Dua.mock(title: "Result for: \(query)")]
    }
  }

  // Type quickly
  await store.send(.searchTextChanged("a")) {
    $0.searchText = "a"
  }
  await store.send(.searchTextChanged("ab")) {
    $0.searchText = "ab"
  }
  await store.send(.searchTextChanged("abc")) {
    $0.searchText = "abc"
  }

  // Advance past debounce interval
  await clock.advance(by: .milliseconds(300))

  // Should only search once with final text
  await store.receive(\.searchResultsLoaded) {
    $0.results = [Dua.mock(title: "Result for: abc")]
  }
}
```

---

## Test Organization

### Test Naming Convention

```swift
// Pattern: test_[methodName]_[scenario]_[expectedResult]
func test_incrementCounter_whenAtMaximum_doesNotIncrement() async { }
func test_loadDuas_whenNetworkError_showsErrorState() async { }
func test_signIn_withValidCredentials_navigatesToHome() async { }

// Or simpler pattern for straightforward tests:
func testIncrementCounter() async { }
func testLoadDuas_Error() async { }
func testSignIn_Success() async { }
```

### Test File Organization

```swift
// Group related tests with MARK comments
final class PracticeFeatureTests: XCTestCase {

  // MARK: - Setup

  var store: TestStore<PracticeFeature.State, PracticeFeature.Action>!

  override func setUp() async throws {
    store = TestStore(initialState: PracticeFeature.State(dua: .mock())) {
      PracticeFeature()
    }
  }

  // MARK: - Counter Tests

  func testIncrementCounter() async { }
  func testDecrementCounter() async { }
  func testResetCounter() async { }

  // MARK: - Completion Tests

  func testMarkComplete() async { }
  func testXpAwarded() async { }

  // MARK: - Navigation Tests

  func testNavigateToNextDua() async { }
  func testNavigateBack() async { }
}
```

---

## CI Configuration

### GitHub Actions Test Workflow

```yaml
# .github/workflows/test.yml
name: Tests

on:
  push:
    branches: [main]
  pull_request:
    branches: [main]

jobs:
  unit-tests:
    runs-on: macos-14
    steps:
      - uses: actions/checkout@v4

      - name: Select Xcode
        run: sudo xcode-select -s /Applications/Xcode_15.4.app

      - name: Generate Xcode Project
        run: |
          brew install xcodegen
          cd RIZQ-iOS && xcodegen

      - name: Run Unit Tests
        run: |
          xcodebuild test \
            -project RIZQ-iOS/RIZQ.xcodeproj \
            -scheme RIZQ \
            -destination 'platform=iOS Simulator,name=iPhone 15 Pro' \
            -only-testing:RIZQTests \
            -resultBundlePath TestResults.xcresult

      - name: Upload Test Results
        uses: actions/upload-artifact@v4
        if: always()
        with:
          name: test-results
          path: TestResults.xcresult

  snapshot-tests:
    runs-on: macos-14
    steps:
      - uses: actions/checkout@v4

      - name: Select Xcode
        run: sudo xcode-select -s /Applications/Xcode_15.4.app

      - name: Generate Xcode Project
        run: |
          brew install xcodegen
          cd RIZQ-iOS && xcodegen

      - name: Run Snapshot Tests
        run: |
          xcodebuild test \
            -project RIZQ-iOS/RIZQ.xcodeproj \
            -scheme RIZQ \
            -destination 'platform=iOS Simulator,name=iPhone 15 Pro' \
            -only-testing:RIZQSnapshotTests \
            -resultBundlePath SnapshotResults.xcresult

      - name: Upload Failed Snapshots
        uses: actions/upload-artifact@v4
        if: failure()
        with:
          name: failed-snapshots
          path: |
            **/Failures/**
```

### Code Coverage

```yaml
# Add to test job
- name: Run Tests with Coverage
  run: |
    xcodebuild test \
      -project RIZQ-iOS/RIZQ.xcodeproj \
      -scheme RIZQ \
      -destination 'platform=iOS Simulator,name=iPhone 15 Pro' \
      -enableCodeCoverage YES \
      -resultBundlePath TestResults.xcresult

- name: Generate Coverage Report
  run: |
    xcrun xccov view --report TestResults.xcresult > coverage.txt
    cat coverage.txt
```

---

## Common Test Patterns

### Testing Error Handling

```swift
func testLoadDuas_NetworkError() async {
  let store = TestStore(initialState: LibraryFeature.State()) {
    LibraryFeature()
  } withDependencies: {
    $0.apiClient.fetchDuas = {
      throw APIError.networkError(URLError(.notConnectedToInternet))
    }
  }

  await store.send(.loadData) {
    $0.isLoading = true
  }

  await store.receive(\.loadFailed) {
    $0.isLoading = false
    $0.errorMessage = "No internet connection. Please check your network."
  }
}
```

### Testing Optional State

```swift
func testSelectDua() async {
  let dua = Dua.mock(id: 1)

  let store = TestStore(
    initialState: LibraryFeature.State(duas: [dua])
  ) {
    LibraryFeature()
  }

  await store.send(.duaSelected(dua)) {
    $0.selectedDua = dua
  }

  await store.send(.clearSelection) {
    $0.selectedDua = nil
  }
}
```

### Testing Collections

```swift
func testAddHabit() async {
  let store = TestStore(
    initialState: HabitsFeature.State(habits: [])
  ) {
    HabitsFeature()
  } withDependencies: {
    $0.uuid = .incrementing
  }

  await store.send(.addHabitTapped(dua: .mock())) {
    $0.habits = [
      UserHabit(
        id: UUID(0),
        duaId: 1,
        timeSlot: .anytime
      )
    ]
  }
}
```

---

## Tips and Best Practices

### 1. Use @MainActor for All Tests

```swift
@MainActor
final class MyFeatureTests: XCTestCase {
  // All test methods automatically run on main actor
}
```

### 2. Prefer Exhaustive Testing

Start with exhaustive testing and only switch to non-exhaustive when tests become brittle.

### 3. Test State Transitions, Not Implementation

```swift
// Good: Test what changes
await store.send(.login(email: "test@test.com", password: "pass")) {
  $0.isLoading = true
}

// Bad: Test how it changes (implementation detail)
// Don't test that a specific API was called, test the resulting state
```

### 4. Use Timeout for Slow Effects

```swift
await store.receive(\.slowEffect, timeout: .seconds(5)) {
  $0.result = .success
}
```

### 5. Record Snapshots Locally, Assert in CI

```swift
var isRecording: Bool {
  #if DEBUG
  return false  // Change to true locally to record
  #else
  return false  // Always assert in CI
  #endif
}
```
