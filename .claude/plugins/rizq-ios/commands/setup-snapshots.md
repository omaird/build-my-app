---
name: setup-snapshots
description: Configure snapshot testing infrastructure for RIZQ iOS
arguments: []
---

# Setup Snapshot Testing Infrastructure

Configure swift-snapshot-testing for the RIZQ iOS app with proper directory structure, base test class, and CI configuration.

## Step 1: Verify SPM Dependency

Check that swift-snapshot-testing is in the project.yml:

```yaml
# In RIZQ-iOS/project.yml under packages:
packages:
  SnapshotTesting:
    url: https://github.com/pointfreeco/swift-snapshot-testing
    from: "1.15.0"
```

If missing, add it and regenerate:

```bash
cd RIZQ-iOS
xcodegen generate
```

## Step 2: Create Directory Structure

```bash
cd RIZQ-iOS

# Create snapshot test directories
mkdir -p RIZQSnapshotTests/Features/Home
mkdir -p RIZQSnapshotTests/Features/Practice
mkdir -p RIZQSnapshotTests/Features/Journeys
mkdir -p RIZQSnapshotTests/Features/Library
mkdir -p RIZQSnapshotTests/Features/Habits
mkdir -p RIZQSnapshotTests/Features/Auth
mkdir -p RIZQSnapshotTests/Features/Settings
mkdir -p RIZQSnapshotTests/Components
mkdir -p RIZQSnapshotTests/__Snapshots__
```

## Step 3: Create Base Test Class

Create `RIZQ-iOS/RIZQSnapshotTests/SnapshotTestCase.swift`:

```swift
import SnapshotTesting
import SwiftUI
import XCTest

@testable import RIZQ

/// Base class for all snapshot tests in RIZQ iOS
/// Provides helper methods for consistent snapshot testing across the app
class SnapshotTestCase: XCTestCase {

  // MARK: - Configuration

  /// Set to true to record new reference snapshots
  /// Control via environment variable in CI: RECORD_SNAPSHOTS=1
  var isRecording: Bool {
    ProcessInfo.processInfo.environment["RECORD_SNAPSHOTS"] == "1"
  }

  // MARK: - Device Configurations

  /// Standard device configurations for testing
  enum DeviceConfig {
    /// iPhone 15 Pro - Primary development device
    static let iPhone15Pro = ViewImageConfig.iPhone15Pro

    /// iPhone 15 Pro Max - Large screen
    static let iPhone15ProMax = ViewImageConfig.iPhone15ProMax

    /// iPhone SE (3rd gen) - Small screen
    static let iPhoneSE = ViewImageConfig(
      safeArea: UIEdgeInsets(top: 20, left: 0, bottom: 0, right: 0),
      size: CGSize(width: 375, height: 667),
      traits: UITraitCollection(userInterfaceIdiom: .phone)
    )

    /// All devices for comprehensive testing
    static let allDevices: [String: ViewImageConfig] = [
      "iPhone15Pro": iPhone15Pro,
      "iPhone15ProMax": iPhone15ProMax,
      "iPhoneSE": iPhoneSE,
    ]

    /// Primary device for quick tests
    static let primary = iPhone15Pro
  }

  // MARK: - Theme Configurations

  /// RIZQ app color scheme wrapper
  private func themedView<V: View>(_ view: V, colorScheme: ColorScheme) -> some View {
    view
      .environment(\.colorScheme, colorScheme)
      .background(colorScheme == .dark ? Color.mocha.deep : Color.cream)
  }

  // MARK: - Snapshot Helpers

  /// Snapshot a view on all configured devices
  /// - Parameters:
  ///   - view: The SwiftUI view to snapshot
  ///   - precision: Pixel comparison precision (0.99 = 99% match required)
  func assertSnapshot<V: View>(
    _ view: V,
    devices: [String: ViewImageConfig] = DeviceConfig.allDevices,
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

  /// Snapshot on a single device (faster for development)
  func assertSnapshotSingleDevice<V: View>(
    _ view: V,
    config: ViewImageConfig = DeviceConfig.primary,
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
    config: ViewImageConfig = DeviceConfig.primary,
    precision: Float = 0.99,
    file: StaticString = #file,
    testName: String = #function,
    line: UInt = #line
  ) {
    // Light mode
    SnapshotTesting.assertSnapshot(
      of: themedView(view, colorScheme: .light),
      as: .image(precision: precision, layout: .device(config: config)),
      named: "light",
      record: isRecording,
      file: file,
      testName: testName,
      line: line
    )

    // Dark mode
    SnapshotTesting.assertSnapshot(
      of: themedView(view, colorScheme: .dark),
      as: .image(precision: precision, layout: .device(config: config)),
      named: "dark",
      record: isRecording,
      file: file,
      testName: testName,
      line: line
    )
  }

  /// Snapshot all modes on all devices (comprehensive but slow)
  func assertSnapshotComprehensive<V: View>(
    _ view: V,
    precision: Float = 0.99,
    file: StaticString = #file,
    testName: String = #function,
    line: UInt = #line
  ) {
    for (deviceName, config) in DeviceConfig.allDevices {
      for mode in [ColorScheme.light, .dark] {
        let modeName = mode == .light ? "light" : "dark"
        SnapshotTesting.assertSnapshot(
          of: themedView(view, colorScheme: mode),
          as: .image(precision: precision, layout: .device(config: config)),
          named: "\(deviceName)_\(modeName)",
          record: isRecording,
          file: file,
          testName: testName,
          line: line
        )
      }
    }
  }

  /// Snapshot a component with padding and background
  func assertComponentSnapshot<V: View>(
    _ view: V,
    padding: CGFloat = 16,
    file: StaticString = #file,
    testName: String = #function,
    line: UInt = #line
  ) {
    let wrappedView = view
      .padding(padding)
      .background(Color.cream)
      .fixedSize()

    SnapshotTesting.assertSnapshot(
      of: wrappedView,
      as: .image(precision: 0.99),
      record: isRecording,
      file: file,
      testName: testName,
      line: line
    )
  }

  /// Snapshot a scrollable view
  func assertScrollableSnapshot<V: View>(
    _ view: V,
    height: CGFloat = 800,
    config: ViewImageConfig = DeviceConfig.primary,
    file: StaticString = #file,
    testName: String = #function,
    line: UInt = #line
  ) {
    let wrappedView = ScrollView {
      view
    }
    .frame(height: height)

    assertSnapshotSingleDevice(
      wrappedView,
      config: config,
      file: file,
      testName: testName,
      line: line
    )
  }
}

// MARK: - ViewImageConfig Extensions

extension ViewImageConfig {
  /// iPhone 15 Pro configuration
  static let iPhone15Pro = ViewImageConfig(
    safeArea: UIEdgeInsets(top: 59, left: 0, bottom: 34, right: 0),
    size: CGSize(width: 393, height: 852),
    traits: UITraitCollection(userInterfaceIdiom: .phone)
  )

  /// iPhone 15 Pro Max configuration
  static let iPhone15ProMax = ViewImageConfig(
    safeArea: UIEdgeInsets(top: 59, left: 0, bottom: 34, right: 0),
    size: CGSize(width: 430, height: 932),
    traits: UITraitCollection(userInterfaceIdiom: .phone)
  )
}
```

## Step 4: Create Example Component Test

Create `RIZQ-iOS/RIZQSnapshotTests/Components/StreakBadgeSnapshotTests.swift`:

```swift
import SnapshotTesting
import SwiftUI
import XCTest

@testable import RIZQ

final class StreakBadgeSnapshotTests: SnapshotTestCase {

  func testStreakBadge_SingleDigit() {
    let view = StreakBadge(streak: 5)
      .padding()
      .background(Color.cream)

    assertSnapshotBothModes(view)
  }

  func testStreakBadge_DoubleDigit() {
    let view = StreakBadge(streak: 42)
      .padding()
      .background(Color.cream)

    assertSnapshotSingleDevice(view)
  }

  func testStreakBadge_TripleDigit() {
    let view = StreakBadge(streak: 365)
      .padding()
      .background(Color.cream)

    assertSnapshotSingleDevice(view)
  }

  func testStreakBadge_Milestone_Seven() {
    let view = StreakBadge(streak: 7, showGlow: true)
      .padding()
      .background(Color.cream)

    assertSnapshotSingleDevice(view)
  }

  func testStreakBadge_Milestone_Thirty() {
    let view = StreakBadge(streak: 30, showGlow: true)
      .padding()
      .background(Color.cream)

    assertSnapshotSingleDevice(view)
  }
}
```

## Step 5: Create Example Feature View Test

Create `RIZQ-iOS/RIZQSnapshotTests/Features/Home/HomeViewSnapshotTests.swift`:

```swift
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

  func testHomeView_LoadedWithData() {
    let store = Store(
      initialState: HomeFeature.State(
        isLoading: false,
        user: .mock(
          streak: 12,
          totalXp: 1250,
          level: 5
        ),
        todaysHabits: [
          .mock(id: UUID(), timeSlot: .morning, isCompleted: true),
          .mock(id: UUID(), timeSlot: .anytime, isCompleted: false),
          .mock(id: UUID(), timeSlot: .evening, isCompleted: false),
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
        user: .mock(streak: 0, totalXp: 0, level: 1),
        todaysHabits: []
      )
    ) {
      HomeFeature()
    }

    let view = HomeView(store: store)
    assertSnapshotSingleDevice(view)
  }

  func testHomeView_AllDevices() {
    let store = Store(
      initialState: HomeFeature.State(
        isLoading: false,
        user: .mock(streak: 7, totalXp: 500, level: 3),
        todaysHabits: [
          .mock(id: UUID(), timeSlot: .morning, isCompleted: true),
        ]
      )
    ) {
      HomeFeature()
    }

    let view = HomeView(store: store)
    assertSnapshot(view, devices: DeviceConfig.allDevices)
  }
}
```

## Step 6: Update .gitignore

Add to `RIZQ-iOS/.gitignore`:

```gitignore
# Snapshot test failures (diff images)
**/Failures/
```

Note: Reference snapshots (`__Snapshots__/`) SHOULD be committed to git.

## Step 7: Configure Test Scheme for CI

Update the test scheme to set recording mode via environment variable:

In Xcode:
1. Edit Scheme → Test → Arguments
2. Add Environment Variable: `RECORD_SNAPSHOTS` = `0`

Or in `project.yml`:

```yaml
schemes:
  RIZQ:
    test:
      environmentVariables:
        RECORD_SNAPSHOTS: "0"
```

## Step 8: Record Initial Snapshots

```bash
cd RIZQ-iOS

# Generate project
xcodegen generate

# Record all snapshots
RECORD_SNAPSHOTS=1 xcodebuild test \
  -project RIZQ.xcodeproj \
  -scheme RIZQ \
  -destination 'platform=iOS Simulator,name=iPhone 15 Pro' \
  -only-testing:RIZQSnapshotTests
```

## Step 9: Verify Setup

```bash
cd RIZQ-iOS

# Run without recording (should pass with recorded snapshots)
xcodebuild test \
  -project RIZQ.xcodeproj \
  -scheme RIZQ \
  -destination 'platform=iOS Simulator,name=iPhone 15 Pro' \
  -only-testing:RIZQSnapshotTests
```

## Workflow Summary

### Recording New Snapshots (Local)

```bash
# Record for specific test
RECORD_SNAPSHOTS=1 xcodebuild test \
  -only-testing:RIZQSnapshotTests/StreakBadgeSnapshotTests

# Record all snapshots
RECORD_SNAPSHOTS=1 xcodebuild test \
  -only-testing:RIZQSnapshotTests
```

### Asserting in CI

```bash
# CI runs with RECORD_SNAPSHOTS=0 (default)
xcodebuild test -only-testing:RIZQSnapshotTests
```

### Handling Failures

1. Review failed snapshots in `__Snapshots__/[TestName]/`
2. Check `Failures/` directory for diff images
3. If change is intentional, re-record locally
4. Commit updated reference snapshots

## Files Created

- `RIZQSnapshotTests/SnapshotTestCase.swift` - Base test class
- `RIZQSnapshotTests/Components/StreakBadgeSnapshotTests.swift` - Example component test
- `RIZQSnapshotTests/Features/Home/HomeViewSnapshotTests.swift` - Example feature test
- `RIZQSnapshotTests/__Snapshots__/` - Reference snapshot directory

## Skills Referenced

- **testing-patterns**: Full snapshot testing documentation
- **design-system-ios**: RIZQ color and typography tokens
- **swiftui-patterns**: View patterns for proper snapshot setup
