# iOS Testing Best Practices Reference

A concise reference guide for testing the RIZQ iOS app with XCTest, TCA TestStore, and Snapshot Testing.

---

## Table of Contents

1. [Testing Strategy](#1-testing-strategy)
2. [TCA Reducer Testing](#2-tca-reducer-testing)
3. [Async Effects Testing](#3-async-effects-testing)
4. [Dependency Mocking](#4-dependency-mocking)
5. [Snapshot Testing](#5-snapshot-testing)
6. [Test Organization](#6-test-organization)
7. [Test Fixtures](#7-test-fixtures)
8. [Common Patterns](#8-common-patterns)
9. [Debugging Tests](#9-debugging-tests)
10. [Anti-Patterns](#10-anti-patterns)

---

## 1. Testing Strategy

### Testing Pyramid

```
        ╱╲
       ╱  ╲       Snapshot Tests (UI verification)
      ╱────╲
     ╱      ╲     Integration Tests (feature flows)
    ╱────────╲
   ╱          ╲   Unit Tests (reducers, logic)
  ╱────────────╲
```

### What to Test

| Layer | What to Test | Tools |
|-------|--------------|-------|
| Reducers | State mutations, effect triggers | TCA TestStore |
| Views | Visual appearance | swift-snapshot-testing |
| Services | API responses, data mapping | XCTest async |
| Models | Equatable, Codable, computed props | XCTest |

### Test Targets in project.yml

```yaml
targets:
  RIZQTests:
    type: bundle.unit-test
    platform: iOS
    sources:
      - path: RIZQTests
    dependencies:
      - target: RIZQKit
      - package: ComposableArchitecture

  RIZQSnapshotTests:
    type: bundle.unit-test
    platform: iOS
    sources:
      - path: RIZQSnapshotTests
    dependencies:
      - target: RIZQ
      - package: SnapshotTesting
```

---

## 2. TCA Reducer Testing

### Basic TestStore Setup

```swift
import XCTest
@testable import RIZQ
import ComposableArchitecture

final class JourneysFeatureTests: XCTestCase {
    @MainActor
    func testOnAppearLoadsJourneys() async {
        let store = TestStore(
            initialState: JourneysFeature.State()
        ) {
            JourneysFeature()
        } withDependencies: {
            $0.firestoreClient.fetchJourneys = {
                [.mock, .mock2]
            }
        }

        await store.send(.onAppear) {
            $0.isLoading = true
        }

        await store.receive(.journeysLoaded(.success([.mock, .mock2]))) {
            $0.isLoading = false
            $0.journeys = [.mock, .mock2]
        }
    }
}
```

### Testing State Changes

```swift
@MainActor
func testItemSelection() async {
    let store = TestStore(
        initialState: MyFeature.State(items: [.mock1, .mock2])
    ) {
        MyFeature()
    }

    await store.send(.itemTapped(.mock1)) {
        $0.selectedId = .mock1.id
    }

    await store.send(.itemTapped(.mock2)) {
        $0.selectedId = .mock2.id
    }
}
```

### Testing Error States

```swift
@MainActor
func testLoadingFailure() async {
    let store = TestStore(
        initialState: JourneysFeature.State()
    ) {
        JourneysFeature()
    } withDependencies: {
        $0.firestoreClient.fetchJourneys = {
            throw TestError.networkError
        }
    }

    await store.send(.onAppear) {
        $0.isLoading = true
    }

    await store.receive(.journeysLoaded(.failure(TestError.networkError))) {
        $0.isLoading = false
        $0.error = "Network error"
    }
}
```

---

## 3. Async Effects Testing

### Receiving Effect Results

```swift
@MainActor
func testAsyncDataLoad() async {
    let store = TestStore(
        initialState: MyFeature.State()
    ) {
        MyFeature()
    } withDependencies: {
        $0.apiClient.fetchData = { ["item1", "item2"] }
    }

    await store.send(.loadData) {
        $0.isLoading = true
    }

    // Wait for the effect to complete and receive the action
    await store.receive(.dataLoaded(.success(["item1", "item2"]))) {
        $0.isLoading = false
        $0.data = ["item1", "item2"]
    }
}
```

### Testing Debounced Effects

```swift
@MainActor
func testDebouncedSearch() async {
    let clock = TestClock()

    let store = TestStore(
        initialState: SearchFeature.State()
    ) {
        SearchFeature()
    } withDependencies: {
        $0.continuousClock = clock
        $0.apiClient.search = { query in
            [SearchResult(query: query)]
        }
    }

    await store.send(.searchTextChanged("test")) {
        $0.searchText = "test"
    }

    // Advance past debounce delay
    await clock.advance(by: .milliseconds(300))

    await store.receive(.searchResults([SearchResult(query: "test")])) {
        $0.results = [SearchResult(query: "test")]
    }
}
```

### Testing Cancellation

```swift
@MainActor
func testSearchCancellation() async {
    let clock = TestClock()

    let store = TestStore(
        initialState: SearchFeature.State()
    ) {
        SearchFeature()
    } withDependencies: {
        $0.continuousClock = clock
    }

    await store.send(.searchTextChanged("first")) {
        $0.searchText = "first"
    }

    // Type again before debounce completes - cancels first search
    await store.send(.searchTextChanged("second")) {
        $0.searchText = "second"
    }

    // Only the second search should complete
    await clock.advance(by: .milliseconds(300))
    // ...receive only second search results
}
```

---

## 4. Dependency Mocking

### Inline Mocking

```swift
let store = TestStore(initialState: MyFeature.State()) {
    MyFeature()
} withDependencies: {
    // Mock specific endpoints
    $0.apiClient.fetchJourneys = { [.mock] }
    $0.apiClient.fetchDuas = { [.mock1, .mock2] }
    $0.authService.getCurrentUser = { .mockUser }
}
```

### Full Mock Client

```swift
// In test target
struct MockAPIClient: APIClientProtocol {
    var fetchJourneys: () async throws -> [Journey] = { [] }
    var fetchDuas: () async throws -> [Dua] = { [] }
    var saveProfile: (UserProfile) async throws -> Void = { _ in }
}

// Usage
let mockClient = MockAPIClient()
mockClient.fetchJourneys = { [.mock] }

let store = TestStore(initialState: MyFeature.State()) {
    MyFeature()
} withDependencies: {
    $0.apiClient = mockClient
}
```

### Capturing Calls

```swift
@MainActor
func testSaveProfile() async {
    var savedProfile: UserProfile?

    let store = TestStore(
        initialState: SettingsFeature.State(profile: .mock)
    ) {
        SettingsFeature()
    } withDependencies: {
        $0.apiClient.saveProfile = { profile in
            savedProfile = profile
        }
    }

    await store.send(.saveButtonTapped)
    await store.receive(.saveCompleted)

    XCTAssertEqual(savedProfile?.displayName, "Mock User")
}
```

---

## 5. Snapshot Testing

### Basic View Snapshot

```swift
import XCTest
import SnapshotTesting
@testable import RIZQ

final class JourneyCardSnapshotTests: XCTestCase {
    func testJourneyCard() {
        let view = JourneyCardView(journey: .mock)
            .frame(width: 350)
            .padding()

        assertSnapshot(of: view, as: .image)
    }
}
```

### Multiple Device Sizes

```swift
func testHomeScreenDevices() {
    let view = HomeView(store: .mock)

    assertSnapshot(of: view, as: .image(layout: .device(config: .iPhone13)))
    assertSnapshot(of: view, as: .image(layout: .device(config: .iPhone13Pro)))
    assertSnapshot(of: view, as: .image(layout: .device(config: .iPhoneSe)))
}
```

### Dark Mode Testing

```swift
func testDarkMode() {
    let view = JourneyCardView(journey: .mock)
        .frame(width: 350)
        .padding()
        .preferredColorScheme(.dark)

    assertSnapshot(of: view, as: .image, named: "dark")
}
```

### Testing with Mock Store

```swift
func testJourneysViewLoading() {
    let store = Store(
        initialState: JourneysFeature.State(isLoading: true)
    ) {
        EmptyReducer()
    }

    let view = JourneysView(store: store)
    assertSnapshot(of: view, as: .image(layout: .device(config: .iPhone13)))
}

func testJourneysViewEmpty() {
    let store = Store(
        initialState: JourneysFeature.State(journeys: [])
    ) {
        EmptyReducer()
    }

    let view = JourneysView(store: store)
    assertSnapshot(of: view, as: .image(layout: .device(config: .iPhone13)), named: "empty")
}
```

### Recording New Snapshots

```swift
// Set record = true to capture new baseline
assertSnapshot(of: view, as: .image, record: true)

// Or use environment variable
// Run with: SNAPSHOT_RECORDING=1 xcodebuild test ...
```

---

## 6. Test Organization

### File Structure

```
RIZQTests/
├── Features/
│   ├── JourneysFeatureTests.swift
│   ├── PracticeFeatureTests.swift
│   └── AuthFeatureTests.swift
├── Services/
│   ├── APIClientTests.swift
│   └── AuthServiceTests.swift
├── Models/
│   └── DuaTests.swift
├── Mocks/
│   ├── MockAPIClient.swift
│   └── MockAuthService.swift
├── Fixtures/
│   ├── Journey+Mock.swift
│   └── Dua+Mock.swift
└── Helpers/
    └── XCTestCase+Async.swift

RIZQSnapshotTests/
├── Components/
│   ├── JourneyCardSnapshotTests.swift
│   └── StreakBadgeSnapshotTests.swift
├── Screens/
│   └── HomeViewSnapshotTests.swift
└── __Snapshots__/
    └── (auto-generated)
```

### Naming Conventions

```swift
// Test class: [Feature]Tests
class JourneysFeatureTests: XCTestCase { }

// Test method: test[Scenario]
func testOnAppearLoadsJourneys() async { }
func testRefreshUpdatesData() async { }
func testErrorShowsAlert() async { }

// Snapshot test: test[Component][State]
func testJourneyCardDefault() { }
func testJourneyCardPremium() { }
func testJourneyCardDarkMode() { }
```

---

## 7. Test Fixtures

### Model Mocks

```swift
// Fixtures/Journey+Mock.swift
extension Journey {
    static let mock = Journey(
        id: "journey-1",
        name: "Morning Adhkar",
        description: "Start your day with remembrance",
        emoji: "🌅",
        estimatedMinutes: 10,
        dailyXp: 50,
        isPremium: false,
        isFeatured: true
    )

    static let mock2 = Journey(
        id: "journey-2",
        name: "Rizq Path",
        description: "Duas for sustenance",
        emoji: "💰",
        estimatedMinutes: 15,
        dailyXp: 75,
        isPremium: true,
        isFeatured: false
    )

    static let mockList: [Journey] = [.mock, .mock2]
}
```

### Store Mocks for SwiftUI Previews

```swift
extension Store where State == JourneysFeature.State, Action == JourneysFeature.Action {
    static var mock: Self {
        Store(initialState: .init(journeys: Journey.mockList)) {
            EmptyReducer()
        }
    }

    static var loading: Self {
        Store(initialState: .init(isLoading: true)) {
            EmptyReducer()
        }
    }

    static var empty: Self {
        Store(initialState: .init(journeys: [])) {
            EmptyReducer()
        }
    }
}
```

---

## 8. Common Patterns

### Testing Navigation

```swift
@MainActor
func testNavigatesToDetail() async {
    let store = TestStore(
        initialState: JourneysFeature.State(journeys: [.mock])
    ) {
        JourneysFeature()
    }

    await store.send(.journeyTapped(.mock)) {
        $0.detail = JourneyDetailFeature.State(journey: .mock)
    }
}
```

### Testing Dismissal

```swift
@MainActor
func testDismissesOnClose() async {
    let store = TestStore(
        initialState: DetailFeature.State(item: .mock)
    ) {
        DetailFeature()
    }

    await store.send(.closeTapped)

    // Verify dismiss was called
    // (typically verified via parent catching the action)
}
```

### Testing Delegate Actions

```swift
@MainActor
func testDelegateAction() async {
    let store = TestStore(
        initialState: ChildFeature.State()
    ) {
        ChildFeature()
    }

    await store.send(.confirmTapped)

    await store.receive(.delegate(.didConfirm)) {
        // State doesn't change - parent handles this
    }
}
```

### Non-Exhaustive Testing

```swift
@MainActor
func testComplexFlow() async {
    let store = TestStore(initialState: MyFeature.State()) {
        MyFeature()
    }

    // Skip asserting every state change
    store.exhaustivity = .off

    await store.send(.startFlow)

    // Just verify end state
    XCTAssertTrue(store.state.isComplete)
}
```

---

## 9. Debugging Tests

### Print State Changes

```swift
@MainActor
func testWithDebugPrinting() async {
    let store = TestStore(initialState: MyFeature.State()) {
        MyFeature()
    }

    store.send(.action) {
        print("Before: \($0)")
        $0.field = newValue
        print("After: \($0)")
    }
}
```

### Timeout Issues

```swift
// If test hangs, check:
// 1. Missing store.receive() for effects
// 2. Effects that never complete
// 3. Wrong action being sent

// Add timeout to catch hangs
await store.receive(.someAction, timeout: .seconds(1)) {
    // ...
}
```

### Failed Assertions

```swift
// TestStore will show diff:
// Expected:
//   State(isLoading: true, items: [])
// Actual:
//   State(isLoading: false, items: [])
//              ~~~~~ ← difference
```

---

## 10. Anti-Patterns

### Don't Test Implementation Details

```swift
// Bad - tests internal state
func testInternalFlag() async {
    await store.send(.action) {
        $0._internalProcessingFlag = true  // Don't test this
    }
}

// Good - test observable behavior
func testLoadingState() async {
    await store.send(.action) {
        $0.isLoading = true  // User-visible state
    }
}
```

### Don't Skip Effect Assertions

```swift
// Bad - missing receive
await store.send(.onAppear) {
    $0.isLoading = true
}
// Test ends, but effect is still running!

// Good - wait for effect
await store.send(.onAppear) {
    $0.isLoading = true
}
await store.receive(.dataLoaded(..)) {
    $0.isLoading = false
}
```

### Don't Use Real Network in Unit Tests

```swift
// Bad
let store = TestStore(initialState: State()) {
    MyFeature()  // Uses real API client
}

// Good
let store = TestStore(initialState: State()) {
    MyFeature()
} withDependencies: {
    $0.apiClient = MockAPIClient()
}
```

### Don't Over-Mock

```swift
// Bad - mocking everything
withDependencies: {
    $0.date = .constant(Date())
    $0.uuid = .incrementing
    $0.calendar = .current
    $0.locale = .current
    // ... 20 more mocks
}

// Good - only mock what's needed
withDependencies: {
    $0.apiClient.fetchData = { [.mock] }
}
```

### Don't Ignore Flaky Tests

```swift
// Bad - random pass/fail
func testSometimesWorks() async {
    // Uses real timers, network, or random data
}

// Good - deterministic
func testAlwaysWorks() async {
    // Uses TestClock, mocked network, fixed data
}
```
