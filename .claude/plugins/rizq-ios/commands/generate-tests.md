---
name: generate-tests
description: Generate unit tests and snapshot tests for an iOS feature
arguments:
  - name: feature
    description: Name of the feature to generate tests for (e.g., Home, Practice, Journeys)
    required: true
  - name: type
    description: Type of tests to generate
    required: false
    default: both
    options:
      - unit
      - snapshot
      - both
---

# Generate Tests for {{feature}} Feature

Generate comprehensive tests for the **{{feature}}** feature in the RIZQ iOS app.

## Test Type: {{type}}

## Instructions

### Step 1: Locate the Feature

Find the feature implementation:

```bash
# Find the feature file
find RIZQ-iOS/RIZQ/Features -name "{{feature}}Feature.swift" -o -name "{{feature}}*.swift" | head -5

# Find the view file
find RIZQ-iOS/RIZQ/Features -name "{{feature}}View.swift" | head -5
```

Read the feature file to understand:
- State structure
- Actions
- Effects and dependencies
- Navigation patterns

### Step 2: Generate Unit Tests (if type is "unit" or "both")

Create `RIZQ-iOS/RIZQTests/Features/{{feature}}/{{feature}}FeatureTests.swift`:

```swift
import ComposableArchitecture
import XCTest

@testable import RIZQ

@MainActor
final class {{feature}}FeatureTests: XCTestCase {

  // MARK: - Lifecycle

  func testOnAppear() async {
    let store = TestStore(initialState: {{feature}}Feature.State()) {
      {{feature}}Feature()
    } withDependencies: {
      // Mock dependencies
    }

    await store.send(.onAppear) {
      // Assert initial state changes
    }
  }

  // MARK: - Actions
  // Add tests for each action...

  // MARK: - Error Handling
  // Add error case tests...

  // MARK: - Navigation
  // Add navigation tests if applicable...
}
```

### Step 3: Generate Snapshot Tests (if type is "snapshot" or "both")

Create `RIZQ-iOS/RIZQSnapshotTests/Features/{{feature}}/{{feature}}ViewSnapshotTests.swift`:

```swift
import ComposableArchitecture
import SnapshotTesting
import SwiftUI
import XCTest

@testable import RIZQ

final class {{feature}}ViewSnapshotTests: SnapshotTestCase {

  func test{{feature}}View_Default() {
    let store = Store(
      initialState: {{feature}}Feature.State()
    ) {
      {{feature}}Feature()
    }

    let view = {{feature}}View(store: store)
    assertSnapshotBothModes(view)
  }

  func test{{feature}}View_Loading() {
    let store = Store(
      initialState: {{feature}}Feature.State(isLoading: true)
    ) {
      {{feature}}Feature()
    }

    let view = {{feature}}View(store: store)
    assertSnapshotSingleDevice(view)
  }

  // Add more state variations...
}
```

### Step 4: Add Mock Data (if needed)

Check if mock factories exist in `RIZQ-iOS/RIZQTests/Mocks/MockData.swift`. If the feature uses models without mocks, add them:

```swift
extension {{Model}} {
  static func mock(
    id: Int = 1
    // Add properties with defaults
  ) -> Self {
    Self(
      id: id
      // ...
    )
  }
}
```

### Step 5: Verify Tests

```bash
cd RIZQ-iOS

# Run just the new tests
xcodebuild test \
  -project RIZQ.xcodeproj \
  -scheme RIZQ \
  -destination 'platform=iOS Simulator,name=iPhone 15 Pro' \
  -only-testing:RIZQTests/{{feature}}FeatureTests \
  2>&1 | xcpretty

# For snapshot tests (first run records)
RECORD_SNAPSHOTS=1 xcodebuild test \
  -project RIZQ.xcodeproj \
  -scheme RIZQ \
  -destination 'platform=iOS Simulator,name=iPhone 15 Pro' \
  -only-testing:RIZQSnapshotTests/{{feature}}ViewSnapshotTests
```

## Feature-Specific Patterns

### If {{feature}} involves XP/Levels
```swift
func testXpAwarded() async {
  let store = TestStore(
    initialState: {{feature}}Feature.State(/* state with XP context */)
  ) {
    {{feature}}Feature()
  } withDependencies: {
    $0.apiClient.updateUserProfile = { _, _ in }
  }

  await store.send(.completeAction) {
    $0.xpEarned = /* expected XP */
  }
}
```

### If {{feature}} involves Streaks
```swift
func testStreakUpdated() async {
  let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: Date())!

  let store = TestStore(
    initialState: {{feature}}Feature.State(
      user: .mock(streak: 5, lastActiveDate: yesterday)
    )
  ) {
    {{feature}}Feature()
  } withDependencies: {
    $0.date.now = Date()
  }

  await store.send(.dailyActionCompleted) {
    $0.user?.streak = 6
  }
}
```

### If {{feature}} involves Navigation
```swift
func testNavigateToDetail() async {
  let item = Item.mock()

  let store = TestStore(
    initialState: {{feature}}Feature.State(items: [item])
  ) {
    {{feature}}Feature()
  }

  await store.send(.itemTapped(item)) {
    $0.path.append(.detail(DetailFeature.State(item: item)))
  }
}
```

### If {{feature}} involves Alerts/Sheets
```swift
func testShowConfirmation() async {
  let store = TestStore(
    initialState: {{feature}}Feature.State()
  ) {
    {{feature}}Feature()
  }

  await store.send(.deleteButtonTapped) {
    $0.alert = AlertState {
      TextState("Confirm Delete")
    } actions: {
      ButtonState(role: .destructive, action: .confirmDelete) {
        TextState("Delete")
      }
    }
  }
}
```

## Output Files

After running this command, you should have:

1. **Unit Tests**: `RIZQ-iOS/RIZQTests/Features/{{feature}}/{{feature}}FeatureTests.swift`
2. **Snapshot Tests**: `RIZQ-iOS/RIZQSnapshotTests/Features/{{feature}}/{{feature}}ViewSnapshotTests.swift`
3. **Reference Snapshots**: `RIZQ-iOS/RIZQSnapshotTests/__Snapshots__/{{feature}}ViewSnapshotTests/`

## Skills Referenced

- **testing-patterns**: Full testing pattern reference
- **tca-patterns**: TCA reducer and state patterns
- **swiftui-patterns**: View patterns for snapshot testing
