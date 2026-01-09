import XCTest
import ComposableArchitecture
@testable import RIZQKit

final class RIZQTests: XCTestCase {

  // MARK: - App Feature Tests

  @MainActor
  func testTabSelection() async {
    let store = TestStore(initialState: AppFeature.State()) {
      AppFeature()
    }

    await store.send(.tabSelected(.library)) {
      $0.selectedTab = .library
    }

    await store.send(.tabSelected(.adkhar)) {
      $0.selectedTab = .adkhar
    }

    await store.send(.tabSelected(.journeys)) {
      $0.selectedTab = .journeys
    }

    await store.send(.tabSelected(.home)) {
      $0.selectedTab = .home
    }
  }

  // MARK: - Auth Feature Tests

  @MainActor
  func testAuthToggleMode() async {
    let store = TestStore(initialState: AuthFeature.State()) {
      AuthFeature()
    }

    XCTAssertFalse(store.state.isSignUp)

    await store.send(.toggleAuthMode) {
      $0.isSignUp = true
    }

    await store.send(.toggleAuthMode) {
      $0.isSignUp = false
    }
  }

  @MainActor
  func testAuthEmailValidation() async {
    let store = TestStore(initialState: AuthFeature.State()) {
      AuthFeature()
    }

    await store.send(.set(\.email, "invalid")) {
      $0.email = "invalid"
    }

    await store.send(.set(\.email, "test@example.com")) {
      $0.email = "test@example.com"
    }
  }

  @MainActor
  func testAuthPasswordValidation() async {
    let store = TestStore(initialState: AuthFeature.State()) {
      AuthFeature()
    }

    await store.send(.set(\.password, "short")) {
      $0.password = "short"
    }

    await store.send(.set(\.password, "validpassword123")) {
      $0.password = "validpassword123"
    }
  }

  // MARK: - Home Feature Tests

  @MainActor
  func testHomeFeatureOnAppear() async {
    // Test that onAppear does nothing without a userId (returns early)
    let store = TestStore(initialState: HomeFeature.State()) {
      HomeFeature()
    } withDependencies: {
      $0.continuousClock = ImmediateClock()
    }

    // No userId set, so onAppear should return early with no state change
    await store.send(.onAppear)
  }

  @MainActor
  func testHomeFeatureStreakAndXp() async {
    var state = HomeFeature.State()
    state.streak = 5
    state.totalXp = 250
    state.level = 2

    let store = TestStore(initialState: state) {
      HomeFeature()
    }

    XCTAssertEqual(store.state.streak, 5)
    XCTAssertEqual(store.state.totalXp, 250)
    XCTAssertEqual(store.state.level, 2)
  }

  @MainActor
  func testHomeFeatureProgress() async {
    var state = HomeFeature.State()
    state.todaysProgress = TodayProgress(completed: 3, total: 5, xpEarned: 30)

    let store = TestStore(initialState: state) {
      HomeFeature()
    }

    XCTAssertEqual(store.state.todaysProgress.completed, 3)
    XCTAssertEqual(store.state.todaysProgress.total, 5)
  }
}

// MARK: - Practice Feature Tests

final class PracticeFeatureTests: XCTestCase {

  @MainActor
  func testCounterIncrement() async {
    let clock = TestClock()

    let store = TestStore(initialState: PracticeFeature.State()) {
      PracticeFeature()
    } withDependencies: {
      $0.continuousClock = clock
      $0[HapticClient.self] = .testValue
    }

    // Set up a dua with 3 repetitions
    let testDua = Dua(
      id: 1,
      categoryId: 1,
      titleEn: "Test Dua",
      arabicText: "Test Arabic",
      transliteration: "Test Transliteration",
      translationEn: "Test Translation",
      source: nil,
      repetitions: 3,
      bestTime: "After Fajr",
      difficulty: .beginner,
      xpValue: 10
    )

    await store.send(.setDua(testDua)) {
      $0.dua = testDua
      $0.targetCount = 3
      $0.currentCount = 0
      $0.isCompleted = false
      $0.showCelebration = false
      $0.selectedTab = .practice
    }

    await store.send(.incrementCounter) {
      $0.currentCount = 1
    }

    await store.send(.incrementCounter) {
      $0.currentCount = 2
    }
  }

  @MainActor
  func testCounterDecrement() async {
    let clock = TestClock()

    var state = PracticeFeature.State()
    state.currentCount = 2
    state.targetCount = 5

    let store = TestStore(initialState: state) {
      PracticeFeature()
    } withDependencies: {
      $0.continuousClock = clock
      $0[HapticClient.self] = .testValue
    }

    await store.send(.decrementCounter) {
      $0.currentCount = 1
    }

    await store.send(.decrementCounter) {
      $0.currentCount = 0
    }

    // Should not go below 0
    await store.send(.decrementCounter)
  }

  @MainActor
  func testResetCounter() async {
    let clock = TestClock()

    var state = PracticeFeature.State()
    state.currentCount = 3
    state.targetCount = 5

    let store = TestStore(initialState: state) {
      PracticeFeature()
    } withDependencies: {
      $0.continuousClock = clock
      $0[HapticClient.self] = .testValue
    }

    await store.send(.resetCounter) {
      $0.currentCount = 0
      $0.isCompleted = false
      $0.showCelebration = false
    }
  }

  @MainActor
  func testCompletion() async {
    let clock = TestClock()

    var state = PracticeFeature.State()
    state.currentCount = 2
    state.targetCount = 3

    let store = TestStore(initialState: state) {
      PracticeFeature()
    } withDependencies: {
      $0.continuousClock = clock
      $0[HapticClient.self] = .testValue
    }

    await store.send(.incrementCounter) {
      $0.currentCount = 3
    }

    await store.receive(\.completionReached) {
      $0.isCompleted = true
      $0.showCelebration = true
    }

    await clock.advance(by: .milliseconds(300))
  }

  @MainActor
  func testProgressCalculation() async {
    var state = PracticeFeature.State()
    state.currentCount = 5
    state.targetCount = 10

    XCTAssertEqual(state.progress, 0.5)

    state.currentCount = 10
    XCTAssertEqual(state.progress, 1.0)

    state.currentCount = 15 // Capped at 1.0
    XCTAssertEqual(state.progress, 1.0)

    state.targetCount = 0 // Edge case
    XCTAssertEqual(state.progress, 0.0)
  }

  @MainActor
  func testTabSelection() async {
    let clock = TestClock()

    let testDua = Dua(
      id: 1,
      categoryId: 1,
      titleEn: "Test",
      arabicText: "Arabic",
      transliteration: "Transliteration",
      translationEn: "Translation",
      source: "Source",
      repetitions: 3,
      bestTime: "After Fajr",
      difficulty: .beginner,
      rizqBenefit: "Benefit",
      propheticContext: "Context",
      xpValue: 10
    )

    var state = PracticeFeature.State()
    state.dua = testDua

    let store = TestStore(initialState: state) {
      PracticeFeature()
    } withDependencies: {
      $0.continuousClock = clock
      $0[HapticClient.self] = .testValue
    }

    await store.send(.tabSelected(.context)) {
      $0.selectedTab = .context
    }

    await store.send(.tabSelected(.practice)) {
      $0.selectedTab = .practice
    }
  }

  @MainActor
  func testTransliterationToggle() async {
    let clock = TestClock()

    let store = TestStore(initialState: PracticeFeature.State()) {
      PracticeFeature()
    } withDependencies: {
      $0.continuousClock = clock
      $0[HapticClient.self] = .testValue
    }

    XCTAssertTrue(store.state.showTransliteration)

    await store.send(.toggleTransliteration) {
      $0.showTransliteration = false
    }

    await store.send(.toggleTransliteration) {
      $0.showTransliteration = true
    }
  }

  @MainActor
  func testCannotTapWhenCompleted() async {
    var state = PracticeFeature.State()
    state.isCompleted = true
    state.alreadyCompletedToday = false

    XCTAssertFalse(state.canTap)
  }

  @MainActor
  func testCannotTapWhenAlreadyCompletedToday() async {
    var state = PracticeFeature.State()
    state.isCompleted = false
    state.alreadyCompletedToday = true

    XCTAssertFalse(state.canTap)
  }
}

// MARK: - Library Feature Tests

final class LibraryFeatureTests: XCTestCase {

  @MainActor
  func testOnAppearLoadsData() async {
    let store = TestStore(initialState: LibraryFeature.State()) {
      LibraryFeature()
    } withDependencies: {
      $0.firestoreContentClient.fetchAllDuas = { Dua.demoData }
    }

    await store.send(.onAppear) {
      $0.isLoading = true
    }

    await store.receive(\.duasLoaded) {
      $0.isLoading = false
      $0.duas = Dua.demoData
      $0.allDuas = Dua.demoData
    }
  }

  @MainActor
  func testCategoryFilter() async {
    let morningDuas = Dua.demoData.filter { $0.categoryId == 1 }

    var state = LibraryFeature.State()
    state.duas = Dua.demoData
    state.allDuas = Dua.demoData

    let store = TestStore(initialState: state) {
      LibraryFeature()
    } withDependencies: {
      $0.firestoreContentClient.fetchDuasByCategory = { slug in
        switch slug {
        case .morning: return morningDuas
        default: return []
        }
      }
    }

    await store.send(.categorySelected(.morning)) {
      $0.selectedCategory = .morning
      $0.isLoading = true
    }

    await store.receive(\.categoryDuasLoaded) {
      $0.isLoading = false
      $0.duas = morningDuas
    }

    // Verify filtering works - morning category has categoryId 1
    let results = store.state.filteredDuas
    XCTAssertTrue(results.allSatisfy { $0.categoryId == 1 })

    await store.send(.categorySelected(nil)) {
      $0.selectedCategory = nil
      $0.duas = Dua.demoData
    }

    // All duas should be visible
    XCTAssertEqual(store.state.filteredDuas.count, Dua.demoData.count)
  }

  @MainActor
  func testSearchFilter() async {
    var state = LibraryFeature.State()
    state.duas = Dua.demoData
    state.allDuas = Dua.demoData

    let store = TestStore(initialState: state) {
      LibraryFeature()
    }

    // Use binding action for searchText
    await store.send(.binding(.set(\.searchText, "Morning"))) {
      $0.searchText = "Morning"
    }

    // Verify search results contain "Morning"
    let results = store.state.filteredDuas
    XCTAssertTrue(results.allSatisfy {
      $0.titleEn.lowercased().contains("morning") ||
      $0.translationEn.lowercased().contains("morning")
    })
  }

  @MainActor
  func testAddToAdkharSheet() async {
    var state = LibraryFeature.State()
    state.duas = Dua.demoData
    let testDua = Dua.demoData[0]

    let store = TestStore(initialState: state) {
      LibraryFeature()
    }

    await store.send(.addToAdkharTapped(testDua)) {
      $0.addToAdkharSheet = AddToAdkharSheetFeature.State(dua: testDua)
    }
  }

  @MainActor
  func testSearchAndCategoryCombined() async {
    let morningDuas = Dua.demoData.filter { $0.categoryId == 1 }

    var state = LibraryFeature.State()
    state.duas = Dua.demoData
    state.allDuas = Dua.demoData

    let store = TestStore(initialState: state) {
      LibraryFeature()
    } withDependencies: {
      $0.firestoreContentClient.fetchDuasByCategory = { _ in morningDuas }
    }

    // Filter by category first (morning = categoryId 1)
    await store.send(.categorySelected(.morning)) {
      $0.selectedCategory = .morning
      $0.isLoading = true
    }

    // Must receive the category action before sending search
    await store.receive(\.categoryDuasLoaded) {
      $0.isLoading = false
      $0.duas = morningDuas
    }

    // Then add search using binding action
    await store.send(.binding(.set(\.searchText, "Protection"))) {
      $0.searchText = "Protection"
    }

    // Verify filtering works - morning category has categoryId 1
    // Note: filteredDuas is a computed property, so we check current state
    let results = store.state.filteredDuas
    XCTAssertTrue(results.allSatisfy { $0.categoryId == 1 })
    XCTAssertTrue(results.allSatisfy {
      $0.titleEn.lowercased().contains("protection") ||
      $0.translationEn.lowercased().contains("protection")
    })
  }
}

// MARK: - Journeys Feature Tests

final class JourneysFeatureTests: XCTestCase {

  @MainActor
  func testOnAppearLoadsJourneys() async {
    let store = TestStore(initialState: JourneysFeature.State()) {
      JourneysFeature()
    } withDependencies: {
      $0.journeyService = .testValue
      $0.continuousClock = ImmediateClock()
    }

    store.exhaustivity = .off

    await store.send(.onAppear) {
      $0.isLoading = true
    }
  }

  @MainActor
  func testSubscribeToggle() async {
    var state = JourneysFeature.State()
    state.journeys = SampleData.journeys

    let testJourney = SampleData.journeys[0]

    let store = TestStore(initialState: state) {
      JourneysFeature()
    } withDependencies: {
      $0.journeyService = .testValue
    }

    // Subscribe
    await store.send(.subscribeToggled(testJourney)) {
      $0.subscribedJourneyIds.insert(testJourney.id)
    }

    await store.receive(\.subscriptionUpdated)

    // Unsubscribe
    await store.send(.subscribeToggled(testJourney)) {
      $0.subscribedJourneyIds.remove(testJourney.id)
    }

    await store.receive(\.subscriptionUpdated)
  }

  @MainActor
  func testFeaturedJourneysFilter() async {
    var state = JourneysFeature.State()
    state.journeys = SampleData.journeys

    let featuredJourneys = state.featuredJourneys
    XCTAssertTrue(featuredJourneys.allSatisfy { $0.isFeatured })
  }

  @MainActor
  func testActiveJourneysFilter() async {
    var state = JourneysFeature.State()
    state.journeys = SampleData.journeys
    state.subscribedJourneyIds = [1, 3]

    let activeJourneys = state.activeJourneys
    XCTAssertTrue(activeJourneys.allSatisfy { state.subscribedJourneyIds.contains($0.id) })
  }

  @MainActor
  func testAvailableJourneysFilter() async {
    var state = JourneysFeature.State()
    state.journeys = SampleData.journeys
    state.subscribedJourneyIds = [1]

    let availableJourneys = state.availableJourneys
    XCTAssertTrue(availableJourneys.allSatisfy { !state.subscribedJourneyIds.contains($0.id) })
    XCTAssertTrue(availableJourneys.allSatisfy { !$0.isFeatured })
  }

  @MainActor
  func testDismissError() async {
    var state = JourneysFeature.State()
    state.errorMessage = "Test error"

    let store = TestStore(initialState: state) {
      JourneysFeature()
    } withDependencies: {
      $0.journeyService = .testValue
    }

    await store.send(.dismissError) {
      $0.errorMessage = nil
    }
  }
}

// MARK: - Add To Adkhar Sheet Tests

final class AddToAdkharSheetFeatureTests: XCTestCase {

  @MainActor
  func testTimeSlotSelection() async {
    let testDua = Dua.demoData[0]
    let state = AddToAdkharSheetFeature.State(dua: testDua)

    let store = TestStore(initialState: state) {
      AddToAdkharSheetFeature()
    }

    XCTAssertEqual(store.state.selectedTimeSlot, .morning)

    await store.send(.timeSlotSelected(.evening)) {
      $0.selectedTimeSlot = .evening
    }

    await store.send(.timeSlotSelected(.anytime)) {
      $0.selectedTimeSlot = .anytime
    }
  }
}
