# Phase 6: Testing & Polish

> **Objective**: Ensure reliability, performance, and quality before release

## Overview

This final phase focuses on comprehensive testing, edge case handling, and performance optimization. The goal is a stable, polished app ready for production use.

---

## Test Categories

### 1. Unit Tests
- Model mapping functions
- Service layer methods
- State calculations (XP, level, streak)
- Data transformations

### 2. Integration Tests
- Database connectivity
- Authentication flows
- Data fetching and caching
- Habit completion flow

### 3. Snapshot Tests
- All major views in different states
- Loading, error, empty, loaded states
- Light and dark mode
- Different device sizes

### 4. End-to-End Tests
- Complete user journeys
- Multi-step flows
- Error recovery scenarios

---

## Tasks

### Task 6.1: Unit Tests for Services

**File**: `RIZQTests/Services/`

**Test Cases**:

```swift
// NeonServiceTests.swift
final class NeonServiceTests: XCTestCase {
    var sut: NeonService!

    override func setUp() {
        sut = NeonService(client: .mock)
    }

    func test_fetchAllDuas_returnsValidData() async throws {
        let duas = try await sut.fetchAllDuas()
        XCTAssertFalse(duas.isEmpty)
        XCTAssertTrue(duas.allSatisfy { !$0.titleEn.isEmpty })
    }

    func test_fetchDua_byId_returnsCorrectDua() async throws {
        let dua = try await sut.fetchDua(id: 1)
        XCTAssertNotNil(dua)
        XCTAssertEqual(dua?.id, 1)
    }

    func test_fetchJourneys_sortedByFeaturedFirst() async throws {
        let journeys = try await sut.fetchAllJourneys()
        let featuredCount = journeys.prefix(while: { $0.isFeatured }).count
        let firstNonFeaturedIndex = journeys.firstIndex { !$0.isFeatured } ?? journeys.count
        XCTAssertEqual(featuredCount, firstNonFeaturedIndex)
    }

    func test_fetchJourneyWithDuas_includesAllDuas() async throws {
        let result = try await sut.fetchJourneyWithDuas(id: 1)
        XCTAssertNotNil(result)
        XCTAssertFalse(result!.duas.isEmpty)
    }
}

// UserHabitsStorageTests.swift
final class UserHabitsStorageTests: XCTestCase {
    var sut: UserHabitsStorage!
    var mockDefaults: UserDefaults!

    override func setUp() {
        mockDefaults = UserDefaults(suiteName: "test")!
        mockDefaults.removePersistentDomain(forName: "test")
        sut = UserHabitsStorage(defaults: mockDefaults)
    }

    func test_addJourney_persistsToStorage() async {
        await sut.addJourney(1)
        let data = await sut.load()
        XCTAssertTrue(data.activeJourneyIds.contains(1))
    }

    func test_addJourney_doesNotDuplicate() async {
        await sut.addJourney(1)
        await sut.addJourney(1)
        let data = await sut.load()
        XCTAssertEqual(data.activeJourneyIds.filter { $0 == 1 }.count, 1)
    }

    func test_removeJourney_removesFromStorage() async {
        await sut.addJourney(1)
        await sut.removeJourney(1)
        let data = await sut.load()
        XCTAssertFalse(data.activeJourneyIds.contains(1))
    }

    func test_markHabitCompleted_persistsTodayOnly() async {
        await sut.markHabitCompleted(duaId: 5)
        let isCompleted = await sut.isCompletedToday(duaId: 5)
        XCTAssertTrue(isCompleted)
    }

    func test_completions_cleansOldEntries() async {
        // Add old completion manually
        var data = await sut.load()
        data.habitCompletions.append(HabitCompletion(date: "2024-01-01", completedDuaIds: [1]))
        // This should trigger cleanup
        await sut.markHabitCompleted(duaId: 2)
        let newData = await sut.load()
        XCTAssertFalse(newData.habitCompletions.contains { $0.date == "2024-01-01" })
    }
}

// LevelCalculatorTests.swift
final class LevelCalculatorTests: XCTestCase {
    func test_calculateLevel_level1() {
        XCTAssertEqual(LevelCalculator.calculateLevel(from: 0), 1)
        XCTAssertEqual(LevelCalculator.calculateLevel(from: 50), 1)
        XCTAssertEqual(LevelCalculator.calculateLevel(from: 99), 1)
    }

    func test_calculateLevel_level2() {
        XCTAssertEqual(LevelCalculator.calculateLevel(from: 100), 2)
        XCTAssertEqual(LevelCalculator.calculateLevel(from: 200), 2)
        XCTAssertEqual(LevelCalculator.calculateLevel(from: 299), 2)
    }

    func test_calculateLevel_level3() {
        XCTAssertEqual(LevelCalculator.calculateLevel(from: 300), 3)
        XCTAssertEqual(LevelCalculator.calculateLevel(from: 500), 3)
        XCTAssertEqual(LevelCalculator.calculateLevel(from: 599), 3)
    }

    func test_xpThreshold_formula() {
        // Formula: 50 * level^2 + 50 * level
        XCTAssertEqual(LevelCalculator.xpThreshold(for: 1), 100)   // 50 + 50
        XCTAssertEqual(LevelCalculator.xpThreshold(for: 2), 300)   // 200 + 100
        XCTAssertEqual(LevelCalculator.xpThreshold(for: 3), 600)   // 450 + 150
        XCTAssertEqual(LevelCalculator.xpThreshold(for: 10), 5500) // 5000 + 500
    }

    func test_xpProgressInLevel_calculatesCorrectly() {
        let (current, needed) = LevelCalculator.xpProgressInLevel(totalXp: 150, level: 2)
        XCTAssertEqual(current, 50)   // 150 - 100
        XCTAssertEqual(needed, 200)   // 300 - 100
    }
}
```

---

### Task 6.2: TCA Feature Tests

**File**: `RIZQTests/Features/`

```swift
// LibraryFeatureTests.swift
@MainActor
final class LibraryFeatureTests: XCTestCase {
    func test_onAppear_fetchesDuas() async {
        let store = TestStore(initialState: LibraryFeature.State()) {
            LibraryFeature()
        } withDependencies: {
            $0.neonService = .mock
        }

        await store.send(.onAppear) {
            $0.loadingState = .loading
        }

        await store.receive(\.duasLoaded.success) {
            $0.loadingState = .loaded
            $0.duas = // expected mock data
        }
    }

    func test_search_filtersDuas() async {
        let store = TestStore(initialState: LibraryFeature.State(
            duas: [
                Dua(id: 1, titleEn: "Ayatul Kursi", ...),
                Dua(id: 2, titleEn: "Morning Protection", ...),
            ]
        )) {
            LibraryFeature()
        }

        await store.send(.searchQueryChanged("kursi")) {
            $0.searchQuery = "kursi"
        }

        XCTAssertEqual(store.state.filteredDuas.count, 1)
        XCTAssertEqual(store.state.filteredDuas.first?.id, 1)
    }

    func test_categoryFilter_filtersByCategory() async {
        let store = TestStore(initialState: LibraryFeature.State(
            duas: [
                Dua(id: 1, categorySlug: "morning", ...),
                Dua(id: 2, categorySlug: "evening", ...),
            ]
        )) {
            LibraryFeature()
        }

        await store.send(.categorySelected(.morning)) {
            $0.selectedCategory = .morning
        }

        XCTAssertEqual(store.state.filteredDuas.count, 1)
        XCTAssertEqual(store.state.filteredDuas.first?.categorySlug, "morning")
    }
}

// AdkharFeatureTests.swift
@MainActor
final class AdkharFeatureTests: XCTestCase {
    func test_habitCompleted_updatesState() async {
        let store = TestStore(initialState: AdkharFeature.State(
            habits: [Habit(id: "1", duaId: 1, ...)],
            completedDuaIds: []
        )) {
            AdkharFeature()
        } withDependencies: {
            $0.userHabitsClient = .preview
        }

        await store.send(.habitCompleted(duaId: 1)) {
            $0.completedDuaIds = [1]
        }
    }

    func test_allCompleted_calculatesCorrectly() {
        var state = AdkharFeature.State(
            habits: [
                Habit(id: "1", duaId: 1, ...),
                Habit(id: "2", duaId: 2, ...),
            ],
            completedDuaIds: [1, 2]
        )
        XCTAssertTrue(state.allCompleted)

        state.completedDuaIds = [1]
        XCTAssertFalse(state.allCompleted)
    }

    func test_progress_calculatesXpCorrectly() {
        let state = AdkharFeature.State(
            habits: [
                Habit(id: "1", duaId: 1, xpValue: 10, ...),
                Habit(id: "2", duaId: 2, xpValue: 20, ...),
                Habit(id: "3", duaId: 3, xpValue: 15, ...),
            ],
            completedDuaIds: [1, 3]
        )

        XCTAssertEqual(state.progress.totalXp, 45)
        XCTAssertEqual(state.progress.earnedXp, 25)  // 10 + 15
        XCTAssertEqual(state.progress.completed, 2)
        XCTAssertEqual(state.progress.total, 3)
    }
}
```

---

### Task 6.3: Snapshot Tests

**File**: `RIZQSnapshotTests/`

```swift
// ViewSnapshotTests.swift
import SnapshotTesting
import SwiftUI

final class ViewSnapshotTests: XCTestCase {
    func test_journeyCard_default() {
        let view = JourneyCardView(
            journey: .preview,
            isActive: false,
            onTap: {}
        )
        assertSnapshot(of: view, as: .image(layout: .fixed(width: 350, height: 160)))
    }

    func test_journeyCard_active() {
        let view = JourneyCardView(
            journey: .preview,
            isActive: true,
            onTap: {}
        )
        assertSnapshot(of: view, as: .image(layout: .fixed(width: 350, height: 160)))
    }

    func test_journeyCard_featured() {
        var journey = Journey.preview
        journey.isFeatured = true
        let view = JourneyCardView(
            journey: journey,
            isActive: false,
            onTap: {}
        )
        assertSnapshot(of: view, as: .image(layout: .fixed(width: 350, height: 180)))
    }

    func test_habitItem_incomplete() {
        let view = HabitItemView(
            habit: .preview,
            isCompleted: false,
            onTap: {}
        )
        assertSnapshot(of: view, as: .image(layout: .fixed(width: 350, height: 80)))
    }

    func test_habitItem_complete() {
        let view = HabitItemView(
            habit: .preview,
            isCompleted: true,
            onTap: {}
        )
        assertSnapshot(of: view, as: .image(layout: .fixed(width: 350, height: 80)))
    }

    func test_streakBadge_variants() {
        for count in [0, 1, 7, 30, 100] {
            let view = StreakBadge(count: count)
            assertSnapshot(of: view, as: .image, named: "streak_\(count)")
        }
    }

    func test_categoryBadge_allCategories() {
        for category in CategorySlug.allCases {
            let view = CategoryBadge(category: category)
            assertSnapshot(of: view, as: .image, named: category.rawValue)
        }
    }

    func test_counterView_progress() {
        for (count, total) in [(0, 10), (5, 10), (10, 10)] {
            let view = CounterView(count: count, total: total)
            assertSnapshot(of: view, as: .image(layout: .fixed(width: 150, height: 150)), named: "\(count)_of_\(total)")
        }
    }
}
```

---

### Task 6.4: End-to-End Flow Tests

**File**: `RIZQTests/E2E/`

```swift
// JourneySubscriptionFlowTests.swift
@MainActor
final class JourneySubscriptionFlowTests: XCTestCase {
    func test_subscribeToJourney_addsToAdkhar() async {
        // 1. Start at journeys page
        let journeysStore = TestStore(initialState: JourneysFeature.State()) {
            JourneysFeature()
        } withDependencies: {
            $0.neonService = .mock
            $0.userHabitsClient = .preview
        }

        // 2. Load journeys
        await journeysStore.send(.onAppear)
        await journeysStore.receive(\.journeysLoaded.success)

        // 3. Tap journey to view detail
        let journey = journeysStore.state.journeys.first!
        await journeysStore.send(.journeyTapped(journey))

        // 4. Subscribe in detail view
        // ... detail store tests ...

        // 5. Verify appears in adkhar
        let adkharStore = TestStore(initialState: AdkharFeature.State()) {
            AdkharFeature()
        } withDependencies: {
            $0.neonService = .mock
            $0.userHabitsClient = UserHabitsClient(
                loadHabitsData: { UserHabitsData(activeJourneyIds: [journey.id]) },
                // ...
            )
        }

        await adkharStore.send(.onAppear)
        await adkharStore.receive(\.habitsLoaded.success)

        XCTAssertFalse(adkharStore.state.habits.isEmpty)
    }
}

// DuaCompletionFlowTests.swift
@MainActor
final class DuaCompletionFlowTests: XCTestCase {
    func test_completeDua_awardsXpAndTracksProgress() async {
        var xpAwarded = 0
        var progressUpdated = false

        let store = TestStore(initialState: PracticeFeature.State(
            dua: .preview
        )) {
            PracticeFeature()
        } withDependencies: {
            $0.userDataClient = UserDataClient(
                addXp: { _, amount in
                    xpAwarded = amount
                    return UserProfile(userId: "test", totalXp: amount, level: 1)
                },
                markDuaCompleted: { _, _ in
                    progressUpdated = true
                },
                // ...
            )
        }

        // Tap to completion
        let repetitions = store.state.dua?.repetitions ?? 1
        for _ in 0..<repetitions {
            await store.send(.cardTapped)
        }

        // Verify
        XCTAssertEqual(xpAwarded, store.state.dua?.xpValue)
        XCTAssertTrue(progressUpdated)
    }
}
```

---

### Task 6.5: Error Handling Audit

Review all features for proper error handling:

**Checklist**:
- [ ] Network errors show user-friendly messages
- [ ] Retry buttons available on error states
- [ ] Database errors logged but don't crash
- [ ] Auth errors redirect to login
- [ ] Empty states don't show "error" styling
- [ ] Loading states have reasonable timeouts
- [ ] Optimistic updates rollback on failure

**Common Error Handling Pattern**:
```swift
case .dataLoaded(.failure(let error)):
    state.loadingState = .error(userFriendlyMessage(for: error))
    // Log detailed error for debugging
    logger.error("Failed to load data: \(error)")
    return .none

private func userFriendlyMessage(for error: Error) -> String {
    switch error {
    case is URLError:
        return "Unable to connect. Please check your internet connection."
    case is DecodingError:
        return "Data format error. Please try again later."
    default:
        return "Something went wrong. Please try again."
    }
}
```

---

### Task 6.6: Performance Optimization

**Areas to Check**:

1. **View Rendering**
   - Use `@ViewBuilder` for conditional content
   - Avoid expensive computations in body
   - Use `EquatableView` for complex views

2. **List Performance**
   - Use `LazyVStack` / `LazyHStack`
   - Implement proper `Identifiable`
   - Avoid inline closures that recreate

3. **Image Loading**
   - Cache downloaded images
   - Use appropriate image sizes
   - Lazy load off-screen images

4. **Data Fetching**
   - Implement request deduplication
   - Cache responses appropriately
   - Paginate large lists

**Measurement**:
```swift
// Add to debug builds
#if DEBUG
extension View {
    func measureRenderTime(_ label: String) -> some View {
        let start = CFAbsoluteTimeGetCurrent()
        return self.onAppear {
            let end = CFAbsoluteTimeGetCurrent()
            print("[\(label)] Render time: \(end - start)s")
        }
    }
}
#endif
```

---

### Task 6.7: Final Polish

**Pre-Release Checklist**:

- [ ] All features load real data
- [ ] No placeholder text visible
- [ ] All animations smooth (60fps)
- [ ] Dark mode supported (if applicable)
- [ ] VoiceOver accessibility
- [ ] Dynamic Type scaling
- [ ] Keyboard navigation (iPad)
- [ ] No memory leaks (Instruments)
- [ ] No crashes in Crashlytics (if set up)
- [ ] App size optimized
- [ ] Remove debug logging
- [ ] Update version number
- [ ] Update build number
- [ ] Archive and test TestFlight build

---

## Verification Checklist

- [ ] All unit tests pass
- [ ] All snapshot tests pass
- [ ] E2E flows work correctly
- [ ] Error handling covers all cases
- [ ] Performance is acceptable (< 2s load times)
- [ ] No memory leaks
- [ ] No crashes in testing
- [ ] Accessibility audit passes
- [ ] App Store screenshots updated

---

## Files Modified/Created

| File | Action | Description |
|------|--------|-------------|
| `NeonServiceTests.swift` | CREATE | Service unit tests |
| `UserHabitsStorageTests.swift` | CREATE | Storage unit tests |
| `LevelCalculatorTests.swift` | CREATE | XP/Level unit tests |
| `LibraryFeatureTests.swift` | CREATE | TCA feature tests |
| `AdkharFeatureTests.swift` | CREATE | TCA feature tests |
| `ViewSnapshotTests.swift` | UPDATE | Add new snapshots |
| `JourneySubscriptionFlowTests.swift` | CREATE | E2E tests |
| `DuaCompletionFlowTests.swift` | CREATE | E2E tests |

---

## Estimated Effort

| Task | Complexity | Estimate |
|------|------------|----------|
| 6.1 Service Unit Tests | Medium | 2 hours |
| 6.2 TCA Feature Tests | Medium | 2 hours |
| 6.3 Snapshot Tests | Medium | 1.5 hours |
| 6.4 E2E Flow Tests | High | 2 hours |
| 6.5 Error Handling Audit | Medium | 1.5 hours |
| 6.6 Performance Optimization | Medium | 1.5 hours |
| 6.7 Final Polish | Low | 1 hour |
| **Total** | | **~11.5 hours** |

---

## Dependencies

- **Prerequisites**: All previous phases complete
- **Blockers**: None
- **Enables**: Production release
