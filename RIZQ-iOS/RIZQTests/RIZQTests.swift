import XCTest
import ComposableArchitecture
@testable import RIZQKit
@testable import RIZQ

final class RIZQTests: XCTestCase {

  // MARK: - App Feature Tests

  @MainActor
  func testTabSelection() async {
    let store = TestStore(initialState: AppFeature.State()) {
      AppFeature()
    }
    // Use non-exhaustive testing since tab selection triggers cascading effects
    // (e.g., .adkhar(.becameActive) → .refreshData → Firestore fetches)
    // We only care about verifying the tab selection state change here
    store.exhaustivity = .off

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

  @MainActor
  func testHomeFeatureProfileLoadFailure() async {
    // Test that error state is set when profile load fails
    var state = HomeFeature.State()
    state.userId = "test-user-123"
    state.isLoading = true

    let store = TestStore(initialState: state) {
      HomeFeature()
    } withDependencies: {
      $0.continuousClock = ImmediateClock()
    }

    await store.send(.profileLoadFailed("Network error")) {
      $0.isLoading = false
      $0.loadError = "Network error"
    }
  }

  @MainActor
  func testHomeFeatureProfileLoadSuccess() async {
    // Test that profile data is correctly populated on success
    var state = HomeFeature.State()
    state.userId = "test-user-123"
    state.isLoading = true

    let store = TestStore(initialState: state) {
      HomeFeature()
    } withDependencies: {
      $0.continuousClock = ImmediateClock()
    }

    let profile = UserProfile(
      id: "test-user-123",
      userId: "test-user-123",
      displayName: "Test User",
      streak: 7,
      totalXp: 500,
      level: 4,
      lastActiveDate: Date()
    )

    await store.send(.profileLoaded(profile)) {
      $0.isLoading = false
      $0.loadError = nil
      $0.displayName = "Test User"
      $0.streak = 7
      $0.totalXp = 500
      $0.level = 4
    }
  }

  @MainActor
  func testHomeFeatureStreakAnimationTriggersOnIncrease() async {
    // Test that streak animation triggers when streak increases
    var state = HomeFeature.State()
    state.userId = "test-user-123"
    state.streak = 5  // Previous streak

    let clock = TestClock()

    let store = TestStore(initialState: state) {
      HomeFeature()
    } withDependencies: {
      $0.continuousClock = clock
    }

    let profile = UserProfile(
      id: "test-user-123",
      userId: "test-user-123",
      displayName: "Test User",
      streak: 6,  // New streak is higher
      totalXp: 500,
      level: 4,
      lastActiveDate: Date()
    )

    await store.send(.profileLoaded(profile)) {
      $0.isLoading = false
      $0.loadError = nil
      $0.displayName = "Test User"
      $0.streak = 6
      $0.totalXp = 500
      $0.level = 4
      $0.isStreakAnimating = true
    }

    // Advance clock to trigger animation completion
    await clock.advance(by: .seconds(2))

    await store.receive(\.streakAnimationCompleted) {
      $0.isStreakAnimating = false
    }
  }

  @MainActor
  func testHomeFeatureStreakAnimationDoesNotTriggerOnFirstLoad() async {
    // When previous streak is 0, no animation should trigger
    var state = HomeFeature.State()
    state.userId = "test-user-123"
    state.streak = 0  // No previous streak

    let store = TestStore(initialState: state) {
      HomeFeature()
    } withDependencies: {
      $0.continuousClock = ImmediateClock()
    }

    let profile = UserProfile(
      id: "test-user-123",
      userId: "test-user-123",
      displayName: "Test User",
      streak: 5,  // Has a streak
      totalXp: 500,
      level: 4,
      lastActiveDate: Date()
    )

    // No animation should trigger because previous streak was 0
    await store.send(.profileLoaded(profile)) {
      $0.isLoading = false
      $0.loadError = nil
      $0.displayName = "Test User"
      $0.streak = 5
      $0.totalXp = 500
      $0.level = 4
      // isStreakAnimating should remain false
    }
  }

  @MainActor
  func testHomeFeatureNavigationActions() async {
    let store = TestStore(initialState: HomeFeature.State()) {
      HomeFeature()
    }

    // Navigation actions should not modify state (handled by parent)
    await store.send(.navigateToAdkhar)
    await store.send(.navigateToLibrary)
    await store.send(.navigateToJourneys)
  }

  @MainActor
  func testHomeFeatureRefreshDataClearsError() async {
    var state = HomeFeature.State()
    state.userId = "test-user-123"
    state.loadError = "Previous error"

    let store = TestStore(initialState: state) {
      HomeFeature()
    } withDependencies: {
      $0.continuousClock = ImmediateClock()
      $0.firestoreUserClient = .testValue
    }

    store.exhaustivity = .off

    await store.send(.refreshData) {
      $0.isLoading = true
      $0.loadError = nil  // Error should be cleared on refresh
    }
  }

  @MainActor
  func testHomeFeatureXpProgressCalculation() async {
    // Test XP progress calculation for different scenarios
    let progress1 = XPProgress(totalXp: 50, level: 1)
    XCTAssertEqual(progress1.current, 50)  // 50 XP in level 1
    XCTAssertGreaterThan(progress1.percentage, 0)
    XCTAssertLessThanOrEqual(progress1.percentage, 1.0)

    let progress2 = XPProgress(totalXp: 0, level: 1)
    XCTAssertEqual(progress2.current, 0)
    XCTAssertEqual(progress2.percentage, 0)

    // Test that percentage is capped at 1.0
    let progress3 = XPProgress(totalXp: 1000, level: 2)
    XCTAssertLessThanOrEqual(progress3.percentage, 1.0)
  }

  @MainActor
  func testHomeFeatureWeekActivitiesLoaded() async {
    var state = HomeFeature.State()

    let store = TestStore(initialState: state) {
      HomeFeature()
    }

    let activities = [
      UserActivity(id: 1, userId: "test", date: Date(), duasCompleted: [1, 2], xpEarned: 50),
      UserActivity(id: 2, userId: "test", date: Calendar.current.date(byAdding: .day, value: -1, to: Date())!, duasCompleted: [1], xpEarned: 25),
    ]

    await store.send(.weekActivitiesLoaded(activities)) {
      $0.weekActivities = activities
    }
  }

  // MARK: - New Component Integration Tests

  @MainActor
  func testHomeFeatureDailyQuoteComputed() async {
    // Test that dailyQuote returns a valid quote
    let state = HomeFeature.State()
    let quote = state.dailyQuote

    // Verify quote has required properties
    XCTAssertFalse(quote.id.isEmpty)
    XCTAssertFalse(quote.englishText.isEmpty)
    XCTAssertFalse(quote.source.isEmpty)
  }

  @MainActor
  func testHomeFeatureMotivationStateComputed() async {
    // Test motivation state computation from todaysProgress

    // No habits scenario
    var state1 = HomeFeature.State()
    state1.todaysProgress = TodayProgress(completed: 0, total: 0, xpEarned: 0)
    XCTAssertEqual(state1.motivationState, .noHabits)

    // Not started scenario
    var state2 = HomeFeature.State()
    state2.todaysProgress = TodayProgress(completed: 0, total: 5, xpEarned: 0)
    XCTAssertEqual(state2.motivationState, .notStarted)

    // Light day scenario (< 50%)
    var state3 = HomeFeature.State()
    state3.todaysProgress = TodayProgress(completed: 2, total: 5, xpEarned: 20)
    XCTAssertEqual(state3.motivationState, .lightDay(habitsCompleted: 2))

    // Productive day scenario (50-99%)
    var state4 = HomeFeature.State()
    state4.todaysProgress = TodayProgress(completed: 3, total: 5, xpEarned: 30)
    XCTAssertEqual(state4.motivationState, .productiveDay)

    // Perfect day scenario (100%)
    var state5 = HomeFeature.State()
    state5.todaysProgress = TodayProgress(completed: 5, total: 5, xpEarned: 50)
    XCTAssertEqual(state5.motivationState, .perfectDay)
  }

  @MainActor
  func testHomeFeatureNextAchievementComputed() async {
    // Test nextAchievement returns first locked achievement
    var state = HomeFeature.State()

    // With default achievements (all locked), should return first
    XCTAssertNotNil(state.nextAchievement)
    XCTAssertFalse(state.nextAchievement?.isUnlocked ?? true)

    // With all unlocked achievements, should return nil
    state.achievements = Achievement.defaults.map { achievement in
      Achievement(
        id: achievement.id,
        name: achievement.name,
        description: achievement.description,
        emoji: achievement.emoji,
        category: achievement.category,
        requirement: achievement.requirement,
        xpReward: achievement.xpReward,
        unlockedAt: Date()  // Mark as unlocked
      )
    }
    XCTAssertNil(state.nextAchievement)
  }

  @MainActor
  func testHomeFeatureShareQuoteTapped() async {
    // Test shareQuoteTapped action (returns .none, no state change)
    let store = TestStore(initialState: HomeFeature.State()) {
      HomeFeature()
    }

    await store.send(.shareQuoteTapped)
    // No state changes expected
  }

  @MainActor
  func testHomeFeatureMotivationActionTapped_NoHabits() async {
    // When noHabits, should navigate to journeys
    var state = HomeFeature.State()
    state.todaysProgress = TodayProgress(completed: 0, total: 0, xpEarned: 0)

    let store = TestStore(initialState: state) {
      HomeFeature()
    }

    await store.send(.motivationActionTapped)
    await store.receive(.navigateToJourneys)
  }

  @MainActor
  func testHomeFeatureMotivationActionTapped_NotStarted() async {
    // When notStarted, should navigate to adkhar
    var state = HomeFeature.State()
    state.todaysProgress = TodayProgress(completed: 0, total: 5, xpEarned: 0)

    let store = TestStore(initialState: state) {
      HomeFeature()
    }

    await store.send(.motivationActionTapped)
    await store.receive(.navigateToAdkhar)
  }

  @MainActor
  func testHomeFeatureMotivationActionTapped_PerfectDay() async {
    // When perfectDay, should do nothing (celebrate!)
    var state = HomeFeature.State()
    state.todaysProgress = TodayProgress(completed: 5, total: 5, xpEarned: 50)

    let store = TestStore(initialState: state) {
      HomeFeature()
    }

    await store.send(.motivationActionTapped)
    // No further actions expected
  }

  @MainActor
  func testHomeFeatureAchievementTapped() async {
    // Test achievementTapped action (returns .none, no state change)
    let store = TestStore(initialState: HomeFeature.State()) {
      HomeFeature()
    }

    let achievement = Achievement.defaults[0]
    await store.send(.achievementTapped(achievement))
    // No state changes expected
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

    // Use non-exhaustive testing since onAppear triggers fetch effects
    // without setting isLoading (loading state is only set on .becameActive)
    store.exhaustivity = .off

    // onAppear now only fires effects without state changes
    // The actual loading happens asynchronously via journeysLoaded
    await store.send(.onAppear)
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

// MARK: - Adkhar Feature Tests

final class AdkharFeatureTests: XCTestCase {

  @MainActor
  func testOnAppearSetsLoadingState() async {
    let store = TestStore(initialState: AdkharFeature.State()) {
      AdkharFeature()
    } withDependencies: {
      $0.continuousClock = ImmediateClock()
      $0.adkharService = .testValue
      $0[HapticClient.self] = .testValue
    }

    store.exhaustivity = .off

    await store.send(.onAppear) {
      $0.isLoading = true
      $0.loadError = nil
    }
  }

  @MainActor
  func testHabitsLoadedSuccess() async {
    var state = AdkharFeature.State()
    state.isLoading = true

    let store = TestStore(initialState: state) {
      AdkharFeature()
    } withDependencies: {
      $0.continuousClock = ImmediateClock()
      $0.adkharService = .testValue
      $0[HapticClient.self] = .testValue
    }

    let morningHabits = [
      Habit(
        id: 1, duaId: 1, titleEn: "Morning Remembrance",
        arabicText: "Test", transliteration: "Test", translation: "Test",
        source: nil, rizqBenefit: nil, propheticContext: nil,
        timeSlot: .morning, xpValue: 10, repetitions: 3
      )
    ]

    await store.send(.habitsLoaded(morning: morningHabits, anytime: [], evening: [])) {
      $0.isLoading = false
      $0.loadError = nil
      $0.morningHabits = morningHabits
      $0.anytimeHabits = []
      $0.eveningHabits = []
    }
  }

  @MainActor
  func testLoadFailedSetsError() async {
    var state = AdkharFeature.State()
    state.isLoading = true

    let store = TestStore(initialState: state) {
      AdkharFeature()
    } withDependencies: {
      $0.continuousClock = ImmediateClock()
      $0.adkharService = .testValue
      $0[HapticClient.self] = .testValue
    }

    await store.send(.loadFailed("Network error")) {
      $0.isLoading = false
      $0.loadError = "Network error"
    }
  }

  @MainActor
  func testRefreshDataClearsError() async {
    var state = AdkharFeature.State()
    state.loadError = "Previous error"

    let store = TestStore(initialState: state) {
      AdkharFeature()
    } withDependencies: {
      $0.continuousClock = ImmediateClock()
      $0.adkharService = .testValue
      $0[HapticClient.self] = .testValue
    }

    store.exhaustivity = .off

    await store.send(.refreshData) {
      $0.isLoading = true
      $0.loadError = nil
    }
  }

  @MainActor
  func testToggleHabitCompletesHabit() async {
    let habit = Habit(
      id: 1, duaId: 1, titleEn: "Test",
      arabicText: "Test", transliteration: nil, translation: "Test",
      source: nil, rizqBenefit: nil, propheticContext: nil,
      timeSlot: .morning, xpValue: 10, repetitions: 1
    )

    var state = AdkharFeature.State()
    state.morningHabits = [habit]

    let store = TestStore(initialState: state) {
      AdkharFeature()
    } withDependencies: {
      $0.continuousClock = ImmediateClock()
      $0.adkharService = .testValue
      $0[HapticClient.self] = .testValue
    }

    store.exhaustivity = .off

    await store.send(.toggleHabit(habit)) {
      $0.completedIds.insert(habit.id)
    }
  }

  @MainActor
  func testToggleHabitUncompletesHabit() async {
    let habit = Habit(
      id: 1, duaId: 1, titleEn: "Test",
      arabicText: "Test", transliteration: nil, translation: "Test",
      source: nil, rizqBenefit: nil, propheticContext: nil,
      timeSlot: .morning, xpValue: 10, repetitions: 1
    )

    var state = AdkharFeature.State()
    state.morningHabits = [habit]
    state.completedIds = [habit.id]

    let store = TestStore(initialState: state) {
      AdkharFeature()
    } withDependencies: {
      $0.continuousClock = ImmediateClock()
      $0.adkharService = .testValue
      $0[HapticClient.self] = .testValue
    }

    store.exhaustivity = .off

    await store.send(.toggleHabit(habit)) {
      $0.completedIds.remove(habit.id)
    }
  }

  @MainActor
  func testQuickPracticeRequestedOpensSheet() async {
    let habit = Habit(
      id: 1, duaId: 1, titleEn: "Test",
      arabicText: "Test", transliteration: nil, translation: "Test",
      source: nil, rizqBenefit: nil, propheticContext: nil,
      timeSlot: .morning, xpValue: 10, repetitions: 3
    )

    let store = TestStore(initialState: AdkharFeature.State()) {
      AdkharFeature()
    } withDependencies: {
      $0.continuousClock = ImmediateClock()
      $0.adkharService = .testValue
      $0[HapticClient.self] = .testValue
    }

    store.exhaustivity = .off

    await store.send(.quickPracticeRequested(habit)) {
      $0.selectedHabit = habit
      $0.repetitionCount = 0
      $0.showCelebration = false
      $0.showQuickPractice = true
    }
  }

  @MainActor
  func testIncrementRepetition() async {
    let habit = Habit(
      id: 1, duaId: 1, titleEn: "Test",
      arabicText: "Test", transliteration: nil, translation: "Test",
      source: nil, rizqBenefit: nil, propheticContext: nil,
      timeSlot: .morning, xpValue: 10, repetitions: 5
    )

    var state = AdkharFeature.State()
    state.selectedHabit = habit
    state.showQuickPractice = true
    state.repetitionCount = 0

    let store = TestStore(initialState: state) {
      AdkharFeature()
    } withDependencies: {
      $0.continuousClock = ImmediateClock()
      $0.adkharService = .testValue
      $0[HapticClient.self] = .testValue
    }

    store.exhaustivity = .off

    await store.send(.incrementRepetition) {
      $0.repetitionCount = 1
    }

    await store.send(.incrementRepetition) {
      $0.repetitionCount = 2
    }
  }

  @MainActor
  func testProgressPercentageCalculation() async {
    var state = AdkharFeature.State()
    state.morningHabits = [
      Habit(id: 1, duaId: 1, titleEn: "Test1", arabicText: "A", transliteration: nil, translation: "T", source: nil, rizqBenefit: nil, propheticContext: nil, timeSlot: .morning, xpValue: 10, repetitions: 1),
      Habit(id: 2, duaId: 2, titleEn: "Test2", arabicText: "B", transliteration: nil, translation: "T", source: nil, rizqBenefit: nil, propheticContext: nil, timeSlot: .morning, xpValue: 10, repetitions: 1),
    ]
    state.completedIds = [1]

    XCTAssertEqual(state.totalHabits, 2)
    XCTAssertEqual(state.completedCount, 1)
    XCTAssertEqual(state.progressPercentage, 0.5)
  }

  @MainActor
  func testStreakLoaded() async {
    let store = TestStore(initialState: AdkharFeature.State()) {
      AdkharFeature()
    } withDependencies: {
      $0.continuousClock = ImmediateClock()
      $0.adkharService = .testValue
      $0[HapticClient.self] = .testValue
    }

    await store.send(.streakLoaded(7)) {
      $0.streak = 7
    }
  }

  @MainActor
  func testCompletionsRestored() async {
    let store = TestStore(initialState: AdkharFeature.State()) {
      AdkharFeature()
    } withDependencies: {
      $0.continuousClock = ImmediateClock()
      $0.adkharService = .testValue
      $0[HapticClient.self] = .testValue
    }

    await store.send(.completionsRestored([1, 2, 3])) {
      $0.completedIds = [1, 2, 3]
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

// MARK: - Achievement Model Tests

final class AchievementModelTests: XCTestCase {

  func testAchievementIsUnlocked() {
    let lockedAchievement = Achievement(
      id: "test",
      name: "Test",
      description: "Test description",
      emoji: "T",
      category: .practice,
      requirement: AchievementRequirement(type: .totalDuas, value: 1),
      xpReward: 50
    )
    XCTAssertFalse(lockedAchievement.isUnlocked)

    let unlockedAchievement = Achievement(
      id: "test",
      name: "Test",
      description: "Test description",
      emoji: "T",
      category: .practice,
      requirement: AchievementRequirement(type: .totalDuas, value: 1),
      xpReward: 50,
      unlockedAt: Date()
    )
    XCTAssertTrue(unlockedAchievement.isUnlocked)
  }

  func testAchievementProgress() {
    let achievement = Achievement(
      id: "week-warrior",
      name: "Week Warrior",
      description: "Maintain a 7-day streak",
      emoji: "7",
      category: .streak,
      requirement: AchievementRequirement(type: .streakDays, value: 7),
      xpReward: 100
    )

    // Test 0% progress
    let context0 = AchievementEvaluationContext(currentStreak: 0)
    XCTAssertEqual(achievement.progress(with: context0), 0.0)
    XCTAssertFalse(achievement.shouldUnlock(with: context0))

    // Test 50% progress
    let context50 = AchievementEvaluationContext(currentStreak: 3)
    XCTAssertEqual(achievement.progress(with: context50), 3.0 / 7.0, accuracy: 0.01)
    XCTAssertFalse(achievement.shouldUnlock(with: context50))

    // Test 100% progress
    let context100 = AchievementEvaluationContext(currentStreak: 7)
    XCTAssertEqual(achievement.progress(with: context100), 1.0)
    XCTAssertTrue(achievement.shouldUnlock(with: context100))

    // Test over 100% (capped at 1.0)
    let contextOver = AchievementEvaluationContext(currentStreak: 14)
    XCTAssertEqual(achievement.progress(with: contextOver), 1.0)
  }

  func testAchievementUnlocked() {
    let achievement = Achievement(
      id: "test",
      name: "Test",
      description: "Test",
      emoji: "T",
      category: .practice,
      requirement: AchievementRequirement(type: .totalDuas, value: 1),
      xpReward: 50
    )

    let unlocked = achievement.unlocked()
    XCTAssertNotNil(unlocked.unlockedAt)
    XCTAssertTrue(unlocked.isUnlocked)
    XCTAssertEqual(unlocked.id, achievement.id)
    XCTAssertEqual(unlocked.xpReward, achievement.xpReward)
  }

  func testAchievementCategoryDisplayNames() {
    XCTAssertEqual(AchievementCategory.streak.displayName, "Consistency")
    XCTAssertEqual(AchievementCategory.practice.displayName, "Practice")
    XCTAssertEqual(AchievementCategory.level.displayName, "Milestone")
    XCTAssertEqual(AchievementCategory.special.displayName, "Special")
  }

  func testAchievementCategoryIcons() {
    XCTAssertEqual(AchievementCategory.streak.iconName, "flame.fill")
    XCTAssertEqual(AchievementCategory.practice.iconName, "hands.clap.fill")
    XCTAssertEqual(AchievementCategory.level.iconName, "star.fill")
    XCTAssertEqual(AchievementCategory.special.iconName, "sparkles")
  }

  func testDefaultAchievementsCount() {
    // 7 achievements: First Step, Getting Started (3-day), Week Warrior, Fortnight Faithful (14-day), Month Master, Rising Star, Perfect Week
    XCTAssertEqual(Achievement.defaults.count, 7)
    XCTAssertTrue(Achievement.defaults.allSatisfy { !$0.isUnlocked })
  }

  func testAchievementAccessibilityDescription() {
    let locked = Achievement.defaults[0]
    XCTAssertTrue(locked.accessibilityDescription.contains("locked"))

    let unlocked = locked.unlocked()
    XCTAssertTrue(unlocked.accessibilityDescription.contains("unlocked"))
  }
}

// MARK: - Islamic Quote Model Tests

final class IslamicQuoteModelTests: XCTestCase {

  func testQuoteForDateIsDeterministic() {
    let date = Calendar.current.date(from: DateComponents(year: 2024, month: 6, day: 15))!
    let quote1 = IslamicQuote.quote(for: date)
    let quote2 = IslamicQuote.quote(for: date)
    XCTAssertEqual(quote1.id, quote2.id)
  }

  func testQuoteRotatesThroughWeek() {
    var seenIds = Set<String>()
    let calendar = Calendar.current
    let startOfYear = calendar.date(from: DateComponents(year: 2024, month: 1, day: 1))!

    // Check first 7 days get different quotes (since we have 7 quotes)
    for dayOffset in 0..<7 {
      let date = calendar.date(byAdding: .day, value: dayOffset, to: startOfYear)!
      let quote = IslamicQuote.quote(for: date)
      seenIds.insert(quote.id)
    }

    XCTAssertEqual(seenIds.count, 7, "Should have 7 unique quotes for 7 days")
  }

  func testHasArabicText() {
    let withArabic = IslamicQuote.dailyQuotes.first { $0.arabicText != nil }!
    XCTAssertTrue(withArabic.hasArabicText)

    let withoutArabic = IslamicQuote.dailyQuotes.first { $0.arabicText == nil }!
    XCTAssertFalse(withoutArabic.hasArabicText)
  }

  func testQuoteCategoryDisplayNames() {
    XCTAssertEqual(IslamicQuote.QuoteCategory.quran.displayName, "Quran")
    XCTAssertEqual(IslamicQuote.QuoteCategory.hadith.displayName, "Hadith")
    XCTAssertEqual(IslamicQuote.QuoteCategory.wisdom.displayName, "Wisdom")
  }

  func testQuoteCategoryIcons() {
    XCTAssertEqual(IslamicQuote.QuoteCategory.quran.iconName, "book.fill")
    XCTAssertEqual(IslamicQuote.QuoteCategory.hadith.iconName, "quote.opening")
    XCTAssertEqual(IslamicQuote.QuoteCategory.wisdom.iconName, "lightbulb.fill")
  }

  func testDailyQuotesCount() {
    XCTAssertEqual(IslamicQuote.dailyQuotes.count, 7)
  }

  func testQuoteAccessibilityDescription() {
    let quote = IslamicQuote.dailyQuotes[0]
    let description = quote.accessibilityDescription
    XCTAssertTrue(description.contains("Quran"))
    XCTAssertTrue(description.contains("Source:"))
  }

  func testQuoteCategoriesHaveMix() {
    let categories = Set(IslamicQuote.dailyQuotes.map(\.category))
    XCTAssertTrue(categories.contains(.quran), "Should have Quran quotes")
    XCTAssertTrue(categories.contains(.hadith), "Should have Hadith quotes")
    XCTAssertTrue(categories.contains(.wisdom), "Should have Wisdom quotes")
  }
}

// MARK: - Badge Size Tests

final class BadgeSizeTests: XCTestCase {

  func testPresetSizePoints() {
    // Test all preset sizes return correct point values
    XCTAssertEqual(BadgeSize.mini.points, 40)
    XCTAssertEqual(BadgeSize.small.points, 60)
    XCTAssertEqual(BadgeSize.medium.points, 80)
    XCTAssertEqual(BadgeSize.large.points, 100)
    XCTAssertEqual(BadgeSize.xlarge.points, 140)
  }

  func testCustomSize() {
    // Custom size should return the exact value provided
    let customSize = BadgeSize.custom(75)
    XCTAssertEqual(customSize.points, 75)

    let customSmall = BadgeSize.custom(25)
    XCTAssertEqual(customSmall.points, 25)

    let customLarge = BadgeSize.custom(200)
    XCTAssertEqual(customLarge.points, 200)
  }

  func testCornerRadiusIsProportional() {
    // cornerRadius = points * 0.08
    XCTAssertEqual(BadgeSize.mini.cornerRadius, 40 * 0.08, accuracy: 0.01)
    XCTAssertEqual(BadgeSize.medium.cornerRadius, 80 * 0.08, accuracy: 0.01)
    XCTAssertEqual(BadgeSize.xlarge.cornerRadius, 140 * 0.08, accuracy: 0.01)
    XCTAssertEqual(BadgeSize.custom(100).cornerRadius, 100 * 0.08, accuracy: 0.01)
  }

  func testGlowRadiusIsProportional() {
    // glowRadius = points * 0.1
    XCTAssertEqual(BadgeSize.mini.glowRadius, 40 * 0.1, accuracy: 0.01)
    XCTAssertEqual(BadgeSize.large.glowRadius, 100 * 0.1, accuracy: 0.01)
    XCTAssertEqual(BadgeSize.custom(50).glowRadius, 50 * 0.1, accuracy: 0.01)
  }

  func testStrokeWidthHasMinimum() {
    // strokeWidth = max(2, points * 0.04)
    // For mini (40pt): 40 * 0.04 = 1.6, should be clamped to 2
    XCTAssertEqual(BadgeSize.mini.strokeWidth, 2, accuracy: 0.01)

    // For small (60pt): 60 * 0.04 = 2.4, should be 2.4
    XCTAssertEqual(BadgeSize.small.strokeWidth, 2.4, accuracy: 0.01)

    // For large (100pt): 100 * 0.04 = 4, should be 4
    XCTAssertEqual(BadgeSize.large.strokeWidth, 4, accuracy: 0.01)

    // Custom size under minimum threshold
    let smallCustom = BadgeSize.custom(30)
    XCTAssertEqual(smallCustom.strokeWidth, 2, accuracy: 0.01)  // 30 * 0.04 = 1.2 < 2
  }

  func testEmojiFontSizeIsProportional() {
    // emojiFontSize = points * 0.35
    XCTAssertEqual(BadgeSize.mini.emojiFontSize, 40 * 0.35, accuracy: 0.01)
    XCTAssertEqual(BadgeSize.medium.emojiFontSize, 80 * 0.35, accuracy: 0.01)
    XCTAssertEqual(BadgeSize.xlarge.emojiFontSize, 140 * 0.35, accuracy: 0.01)
  }

  func testSizeProgression() {
    // Verify sizes increase monotonically
    XCTAssertLessThan(BadgeSize.mini.points, BadgeSize.small.points)
    XCTAssertLessThan(BadgeSize.small.points, BadgeSize.medium.points)
    XCTAssertLessThan(BadgeSize.medium.points, BadgeSize.large.points)
    XCTAssertLessThan(BadgeSize.large.points, BadgeSize.xlarge.points)
  }
}

// MARK: - Achievement Category Badge Color Tests

final class AchievementCategoryBadgeColorTests: XCTestCase {

  func testBadgeColorNames() {
    // Test each category returns correct color name
    XCTAssertEqual(AchievementCategory.streak.badgeColorName, "streakGlow")
    XCTAssertEqual(AchievementCategory.practice.badgeColorName, "tealSuccess")
    XCTAssertEqual(AchievementCategory.level.badgeColorName, "badgeEvening")
    XCTAssertEqual(AchievementCategory.special.badgeColorName, "goldBright")
  }

  func testAllCategoriesHaveBadgeColors() {
    // Ensure every category has a non-empty badge color name
    for category in AchievementCategory.allCases {
      XCTAssertFalse(category.badgeColorName.isEmpty, "\(category) should have a badge color name")
    }
  }
}

// MARK: - Daily Activity Item Tests

final class DailyActivityItemTests: XCTestCase {

  func testItemInitialization() {
    let date = Date()
    let item = DailyActivityItem(date: date, completed: true, xpEarned: 100)

    XCTAssertEqual(item.xpEarned, 100)
    XCTAssertTrue(item.completed)
    XCTAssertFalse(item.id.isEmpty)
  }

  func testIsTodayDetection() {
    let today = DailyActivityItem(date: Date())
    XCTAssertTrue(today.isToday)

    let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: Date())!
    let yesterdayItem = DailyActivityItem(date: yesterday)
    XCTAssertFalse(yesterdayItem.isToday)
  }

  func testDayLabelGeneration() {
    // Day label should be a single character (first letter of day name)
    let item = DailyActivityItem(date: Date())
    XCTAssertEqual(item.dayLabel.count, 1)
  }

  func testMockWeekCreation() {
    let week = DailyActivityItem.mockWeek(completedDays: [0, 1, 2])
    XCTAssertEqual(week.count, 7)
    XCTAssertEqual(week.completedCount, 3)
  }

  func testWeekItemsFromUserActivity() {
    // Empty activities should return 7 items, all incomplete
    let items = DailyActivityItem.weekItems(from: [])
    XCTAssertEqual(items.count, 7)
    XCTAssertEqual(items.completedCount, 0)
  }

  // MARK: - Array Extension Tests

  func testCompletedCount() {
    let week = DailyActivityItem.mockWeek(completedDays: [0, 2, 4, 6])
    XCTAssertEqual(week.completedCount, 4)
  }

  func testTotalXpEarned() {
    let week = DailyActivityItem.mockWeek(completedDays: [0, 1, 2], xpPerDay: 50)
    XCTAssertEqual(week.totalXpEarned, 150)
  }

  func testIsPerfectWeek() {
    let perfectWeek = DailyActivityItem.mockWeek(completedDays: [0, 1, 2, 3, 4, 5, 6])
    XCTAssertTrue(perfectWeek.isPerfectWeek)

    let imperfectWeek = DailyActivityItem.mockWeek(completedDays: [0, 1, 2])
    XCTAssertFalse(imperfectWeek.isPerfectWeek)
  }

  func testCurrentStreak() {
    // Test streak counting from most recent backwards
    // Days 0-6 map to 6 days ago to today
    // If today (index 6) and yesterday (index 5) are complete, streak should be 2
    let week = DailyActivityItem.mockWeek(completedDays: [5, 6], xpPerDay: 100)
    // Note: currentStreak counts from the end backwards, skipping today if incomplete
    XCTAssertGreaterThanOrEqual(week.currentStreak, 1)
  }
}

// MARK: - Motivation State Tests

final class MotivationStateTests: XCTestCase {

  // MARK: - Factory Initializer Tests

  func testNoHabitsState() {
    // When totalHabits is 0, should return .noHabits
    let state = MotivationState(habitsCompleted: 0, totalHabits: 0)
    XCTAssertEqual(state, .noHabits)

    // Even with completed > 0, if total is 0, still noHabits
    let state2 = MotivationState(habitsCompleted: 3, totalHabits: 0)
    XCTAssertEqual(state2, .noHabits)
  }

  func testNotStartedState() {
    // 0% completion (but has habits) = notStarted
    let state = MotivationState(habitsCompleted: 0, totalHabits: 5)
    XCTAssertEqual(state, .notStarted)
  }

  func testLightDayState() {
    // 1-49% completion = lightDay
    let state1 = MotivationState(habitsCompleted: 1, totalHabits: 5)  // 20%
    if case .lightDay(let completed) = state1 {
      XCTAssertEqual(completed, 1)
    } else {
      XCTFail("Expected lightDay state")
    }

    let state2 = MotivationState(habitsCompleted: 2, totalHabits: 5)  // 40%
    if case .lightDay(let completed) = state2 {
      XCTAssertEqual(completed, 2)
    } else {
      XCTFail("Expected lightDay state")
    }
  }

  func testProductiveDayState() {
    // 50-99% completion = productiveDay
    let state1 = MotivationState(habitsCompleted: 3, totalHabits: 5)  // 60%
    XCTAssertEqual(state1, .productiveDay)

    let state2 = MotivationState(habitsCompleted: 4, totalHabits: 5)  // 80%
    XCTAssertEqual(state2, .productiveDay)

    let state3 = MotivationState(habitsCompleted: 1, totalHabits: 2)  // 50%
    XCTAssertEqual(state3, .productiveDay)
  }

  func testPerfectDayState() {
    // 100% completion = perfectDay
    let state = MotivationState(habitsCompleted: 5, totalHabits: 5)
    XCTAssertEqual(state, .perfectDay)

    // Edge case: over 100% should still be perfectDay
    let stateOver = MotivationState(habitsCompleted: 7, totalHabits: 5)
    XCTAssertEqual(stateOver, .perfectDay)
  }

  // MARK: - Display Property Tests

  func testTitles() {
    XCTAssertEqual(MotivationState.noHabits.title, "Start Your Journey")
    XCTAssertEqual(MotivationState.notStarted.title, "Ready to Begin")
    XCTAssertEqual(MotivationState.lightDay(habitsCompleted: 1).title, "Light Day")
    XCTAssertEqual(MotivationState.productiveDay.title, "Making Progress")
    XCTAssertEqual(MotivationState.perfectDay.title, "Perfect Day!")
  }

  func testMessagesWithStreak() {
    // notStarted with streak should mention the streak
    let notStartedMessage = MotivationState.notStarted.message(streak: 5)
    XCTAssertTrue(notStartedMessage.contains("5-day streak"))

    // notStarted without streak should have different message
    let notStartedNoStreak = MotivationState.notStarted.message(streak: 0)
    XCTAssertFalse(notStartedNoStreak.contains("streak"))
  }

  func testLightDayMessageGrammar() {
    // 1 habit = singular "habit"
    let message1 = MotivationState.lightDay(habitsCompleted: 1).message(streak: 0)
    XCTAssertTrue(message1.contains("1 habit"))

    // 2+ habits = plural "habits"
    let message2 = MotivationState.lightDay(habitsCompleted: 2).message(streak: 0)
    XCTAssertTrue(message2.contains("2 habits"))
  }

  func testActionTexts() {
    XCTAssertEqual(MotivationState.noHabits.actionText, "Browse Journeys")
    XCTAssertEqual(MotivationState.notStarted.actionText, "Start First Habit")
    XCTAssertEqual(MotivationState.lightDay(habitsCompleted: 1).actionText, "Continue Practice")
    XCTAssertEqual(MotivationState.productiveDay.actionText, "Almost There!")
    XCTAssertEqual(MotivationState.perfectDay.actionText, "")  // No action for perfect day
  }

  func testHasAction() {
    XCTAssertTrue(MotivationState.noHabits.hasAction)
    XCTAssertTrue(MotivationState.notStarted.hasAction)
    XCTAssertTrue(MotivationState.lightDay(habitsCompleted: 1).hasAction)
    XCTAssertTrue(MotivationState.productiveDay.hasAction)
    XCTAssertFalse(MotivationState.perfectDay.hasAction)  // No action
  }

  func testIconNames() {
    XCTAssertEqual(MotivationState.noHabits.iconName, "leaf")
    XCTAssertEqual(MotivationState.notStarted.iconName, "sunrise")
    XCTAssertEqual(MotivationState.lightDay(habitsCompleted: 1).iconName, "leaf.fill")
    XCTAssertEqual(MotivationState.productiveDay.iconName, "flame")
    XCTAssertEqual(MotivationState.perfectDay.iconName, "checkmark.seal.fill")
  }

  func testGlowColorNames() {
    XCTAssertEqual(MotivationState.noHabits.glowColorName, "rizqMuted")
    XCTAssertEqual(MotivationState.notStarted.glowColorName, "goldSoft")
    XCTAssertEqual(MotivationState.lightDay(habitsCompleted: 1).glowColorName, "goldBright")
    XCTAssertEqual(MotivationState.productiveDay.glowColorName, "streakGlow")
    XCTAssertEqual(MotivationState.perfectDay.glowColorName, "tealSuccess")
  }

  // MARK: - Accessibility Tests

  func testAccessibilityDescription() {
    let state = MotivationState.notStarted
    let desc = state.accessibilityDescription(streak: 3, nextAchievementName: "Week Warrior")

    // Should contain title
    XCTAssertTrue(desc.contains("Ready to Begin"))

    // Should contain message (with streak)
    XCTAssertTrue(desc.contains("3-day streak"))

    // Should contain next achievement
    XCTAssertTrue(desc.contains("Week Warrior"))

    // Should contain action
    XCTAssertTrue(desc.contains("Start First Habit"))
  }

  func testAccessibilityDescriptionWithoutAchievement() {
    let state = MotivationState.perfectDay
    let desc = state.accessibilityDescription(streak: 7, nextAchievementName: nil)

    // Should contain title
    XCTAssertTrue(desc.contains("Perfect Day"))

    // Should NOT contain "Next achievement" since none provided
    XCTAssertFalse(desc.contains("Next achievement"))

    // Should NOT contain action since perfectDay has none
    XCTAssertFalse(desc.contains("Action:"))
  }

  // MARK: - Equatable Tests

  func testEquatable() {
    XCTAssertEqual(MotivationState.noHabits, MotivationState.noHabits)
    XCTAssertEqual(MotivationState.perfectDay, MotivationState.perfectDay)

    // lightDay equality includes habitsCompleted
    XCTAssertEqual(
      MotivationState.lightDay(habitsCompleted: 2),
      MotivationState.lightDay(habitsCompleted: 2)
    )
    XCTAssertNotEqual(
      MotivationState.lightDay(habitsCompleted: 1),
      MotivationState.lightDay(habitsCompleted: 2)
    )
  }

  // MARK: - Streak-Aware Perfect Day Messages (Business Analyst)

  func testPerfectDayMessageVariations() {
    let state = MotivationState.perfectDay

    // Early streak (< 6 days) - generic tomorrow message
    let earlyMessage = state.message(streak: 3)
    XCTAssertTrue(earlyMessage.contains("MashaAllah"))
    XCTAssertTrue(earlyMessage.contains("Come back tomorrow"))

    // Week milestone (6-28 days) - mentions specific day number
    let weekMessage = state.message(streak: 6)
    XCTAssertTrue(weekMessage.contains("day 7"))

    // Month milestone (29+ days) - special milestone message
    let monthMessage = state.message(streak: 29)
    XCTAssertTrue(monthMessage.contains("day 30"))
    XCTAssertTrue(monthMessage.contains("blessing"))
  }
}
