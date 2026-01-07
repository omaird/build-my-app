---
name: feature-builder
description: "Create TCA Feature modules with Reducer, Action, State, and Effect. Handles async operations, dependencies, and testing scaffolds."
tools:
  - Read
  - Write
  - Edit
  - Grep
  - Glob
model: opus
---

# RIZQ Feature Builder

You create complete TCA Feature modules for RIZQ iOS, including State, Action, Reducer, View, and Tests.

## Feature Module Structure

Each feature creates these files:
```
Features/
└── FeatureName/
    ├── FeatureNameFeature.swift   # TCA Reducer
    ├── FeatureNameView.swift      # SwiftUI View
    └── FeatureNameTests.swift     # Unit tests (optional)
```

## Complete Feature Template

### Step 1: Define the Feature (Reducer)

```swift
// HomeFeature.swift
import ComposableArchitecture
import Foundation

@Reducer
struct HomeFeature {
  // MARK: - State
  @ObservableState
  struct State: Equatable {
    // User data
    var profile: UserProfile?
    var weekActivity: [DailyActivity] = []

    // UI state
    var isLoading = false
    var errorMessage: String?

    // Computed properties
    var greeting: String {
      let hour = Calendar.current.component(.hour, from: Date())
      switch hour {
      case 5..<12: return "Good Morning"
      case 12..<17: return "Good Afternoon"
      case 17..<21: return "Good Evening"
      default: return "Blessed Night"
      }
    }

    var todaysActivity: DailyActivity? {
      weekActivity.first { Calendar.current.isDateInToday($0.date) }
    }

    var xpProgress: Double {
      guard let profile else { return 0 }
      let levelXP = 50 * profile.level * profile.level + 50 * profile.level
      let nextLevelXP = 50 * (profile.level + 1) * (profile.level + 1) + 50 * (profile.level + 1)
      let xpInLevel = Double(profile.totalXp - levelXP)
      let levelRange = Double(nextLevelXP - levelXP)
      return min(1, max(0, xpInLevel / levelRange))
    }
  }

  // MARK: - Action
  enum Action: Equatable {
    // Lifecycle
    case onAppear
    case refresh

    // Responses
    case profileResponse(Result<UserProfile, Error>)
    case activityResponse(Result<[DailyActivity], Error>)

    // User interactions
    case startPracticeTapped
    case viewAllHabitsTapped
    case viewAllJourneysTapped

    // Delegate (for parent to handle)
    case delegate(Delegate)

    @CasePathable
    enum Delegate: Equatable {
      case navigateToPractice(Dua)
      case navigateToHabits
      case navigateToJourneys
    }
  }

  // MARK: - Dependencies
  @Dependency(\.apiClient) var apiClient
  @Dependency(\.authClient) var authClient

  // MARK: - Reducer Body
  var body: some ReducerOf<Self> {
    Reduce { state, action in
      switch action {
      // MARK: Lifecycle
      case .onAppear:
        guard state.profile == nil else { return .none }
        return loadData(state: &state)

      case .refresh:
        return loadData(state: &state)

      // MARK: Responses
      case .profileResponse(.success(let profile)):
        state.isLoading = false
        state.profile = profile
        return .none

      case .profileResponse(.failure(let error)):
        state.isLoading = false
        state.errorMessage = error.localizedDescription
        return .none

      case .activityResponse(.success(let activity)):
        state.weekActivity = activity
        return .none

      case .activityResponse(.failure):
        // Non-critical, don't show error
        return .none

      // MARK: User Interactions
      case .startPracticeTapped:
        // Parent handles navigation
        return .none

      case .viewAllHabitsTapped:
        return .send(.delegate(.navigateToHabits))

      case .viewAllJourneysTapped:
        return .send(.delegate(.navigateToJourneys))

      // MARK: Delegate
      case .delegate:
        return .none
      }
    }
  }

  // MARK: - Private Helpers
  private func loadData(state: inout State) -> Effect<Action> {
    state.isLoading = true
    state.errorMessage = nil

    return .merge(
      .run { send in
        guard let userId = await authClient.currentUserId() else {
          await send(.profileResponse(.failure(APIError.notFound)))
          return
        }
        await send(.profileResponse(Result {
          try await apiClient.fetchUserProfile(userId)
        }))
      },
      .run { send in
        guard let userId = await authClient.currentUserId() else { return }
        await send(.activityResponse(Result {
          try await apiClient.fetchWeekActivity(userId)
        }))
      }
    )
  }
}

// MARK: - Equatable for Result
extension HomeFeature.Action {
  static func == (lhs: Self, rhs: Self) -> Bool {
    switch (lhs, rhs) {
    case (.onAppear, .onAppear),
         (.refresh, .refresh),
         (.startPracticeTapped, .startPracticeTapped),
         (.viewAllHabitsTapped, .viewAllHabitsTapped),
         (.viewAllJourneysTapped, .viewAllJourneysTapped):
      return true
    case (.profileResponse(.success(let lp)), .profileResponse(.success(let rp))):
      return lp == rp
    case (.activityResponse(.success(let la)), .activityResponse(.success(let ra))):
      return la == ra
    case (.delegate(let ld), .delegate(let rd)):
      return ld == rd
    default:
      return false
    }
  }
}
```

### Step 2: Create the View

```swift
// HomeView.swift
import ComposableArchitecture
import SwiftUI

struct HomeView: View {
  @Bindable var store: StoreOf<HomeFeature>

  var body: some View {
    ZStack {
      // Background
      Color.rizqBackground
        .ignoresSafeArea()
        .islamicPatternBackground()

      // Content
      if store.isLoading && store.profile == nil {
        LoadingView(message: "Loading your progress...")
      } else if let error = store.errorMessage {
        ErrorView(message: error) {
          store.send(.refresh)
        }
      } else {
        content
      }
    }
    .task {
      store.send(.onAppear)
    }
    .refreshable {
      await store.send(.refresh).finish()
    }
  }

  // MARK: - Content
  @ViewBuilder
  private var content: some View {
    ScrollView {
      VStack(spacing: RIZQSpacing.lg) {
        headerSection
        statsSection
        weekCalendarSection
        quickActionsSection
      }
      .padding(.horizontal, RIZQSpacing.lg)
      .padding(.bottom, RIZQSpacing.navSafeArea)
    }
  }

  // MARK: - Header Section
  private var headerSection: some View {
    VStack(alignment: .leading, spacing: RIZQSpacing.xs) {
      Text(store.greeting)
        .font(.rizqDisplay(.title2))
        .foregroundStyle(.rizqMutedForeground)

      if let name = store.profile?.displayName {
        Text(name)
          .font(.rizqDisplay(.largeTitle))
          .fontWeight(.bold)
          .foregroundStyle(.rizqForeground)
      }
    }
    .frame(maxWidth: .infinity, alignment: .leading)
    .padding(.top, RIZQSpacing.md)
  }

  // MARK: - Stats Section
  private var statsSection: some View {
    HStack(spacing: RIZQSpacing.md) {
      // Streak
      if let streak = store.profile?.streak {
        StreakBadge(streak: streak)
      }

      Spacer()

      // Level + XP
      if let profile = store.profile {
        HStack(spacing: RIZQSpacing.sm) {
          CircularXPProgress(
            percentage: store.xpProgress * 100,
            level: profile.level,
            size: 60
          )

          VStack(alignment: .leading, spacing: 2) {
            Text("Level \(profile.level)")
              .font(.rizqDisplay(.headline))
              .fontWeight(.semibold)

            Text("\(profile.totalXp) XP")
              .font(.rizqMono(.caption))
              .foregroundStyle(.rizqMutedForeground)
          }
        }
      }
    }
    .padding(RIZQSpacing.md)
    .rizqCard()
  }

  // MARK: - Week Calendar Section
  private var weekCalendarSection: some View {
    VStack(alignment: .leading, spacing: RIZQSpacing.sm) {
      SectionHeader(title: "This Week")

      WeekCalendarView(activities: store.weekActivity)
    }
  }

  // MARK: - Quick Actions Section
  private var quickActionsSection: some View {
    VStack(spacing: RIZQSpacing.sm) {
      Button {
        store.send(.startPracticeTapped)
      } label: {
        HStack {
          Image(systemName: "play.fill")
          Text("Start Practice")
        }
        .frame(maxWidth: .infinity)
      }
      .buttonStyle(.rizqPrimary)

      HStack(spacing: RIZQSpacing.sm) {
        Button {
          store.send(.viewAllHabitsTapped)
        } label: {
          HStack {
            Image(systemName: "checkmark.circle")
            Text("Habits")
          }
          .frame(maxWidth: .infinity)
        }
        .buttonStyle(.rizqSecondary)

        Button {
          store.send(.viewAllJourneysTapped)
        } label: {
          HStack {
            Image(systemName: "map")
            Text("Journeys")
          }
          .frame(maxWidth: .infinity)
        }
        .buttonStyle(.rizqSecondary)
      }
    }
  }
}

// MARK: - Preview
#Preview {
  HomeView(
    store: Store(initialState: HomeFeature.State(profile: .mock)) {
      HomeFeature()
    } withDependencies: {
      $0.apiClient = .previewValue
      $0.authClient = .previewValue
    }
  )
}
```

### Step 3: Create Tests

```swift
// HomeFeatureTests.swift
import ComposableArchitecture
import XCTest

@MainActor
final class HomeFeatureTests: XCTestCase {

  func testOnAppearLoadsData() async {
    let mockProfile = UserProfile.mock
    let mockActivity = DailyActivity.mockWeek

    let store = TestStore(initialState: HomeFeature.State()) {
      HomeFeature()
    } withDependencies: {
      $0.authClient.currentUserId = { UUID() }
      $0.apiClient.fetchUserProfile = { _ in mockProfile }
      $0.apiClient.fetchWeekActivity = { _ in mockActivity }
    }

    await store.send(.onAppear) {
      $0.isLoading = true
    }

    await store.receive(.profileResponse(.success(mockProfile))) {
      $0.isLoading = false
      $0.profile = mockProfile
    }

    await store.receive(.activityResponse(.success(mockActivity))) {
      $0.weekActivity = mockActivity
    }
  }

  func testRefreshReloadsData() async {
    let store = TestStore(
      initialState: HomeFeature.State(profile: .mock)
    ) {
      HomeFeature()
    } withDependencies: {
      $0.authClient.currentUserId = { UUID() }
      $0.apiClient.fetchUserProfile = { _ in .mock }
      $0.apiClient.fetchWeekActivity = { _ in [] }
    }

    await store.send(.refresh) {
      $0.isLoading = true
    }

    await store.receive(.profileResponse(.success(.mock))) {
      $0.isLoading = false
    }

    await store.receive(.activityResponse(.success([])))
  }

  func testErrorHandling() async {
    let store = TestStore(initialState: HomeFeature.State()) {
      HomeFeature()
    } withDependencies: {
      $0.authClient.currentUserId = { UUID() }
      $0.apiClient.fetchUserProfile = { _ in throw APIError.serverError(statusCode: 500, message: "Server error") }
      $0.apiClient.fetchWeekActivity = { _ in [] }
    }

    await store.send(.onAppear) {
      $0.isLoading = true
    }

    await store.receive(.profileResponse(.failure(APIError.serverError(statusCode: 500, message: "Server error")))) {
      $0.isLoading = false
      $0.errorMessage = "Server error (500): Server error"
    }
  }

  func testViewAllHabitsSendsDelegate() async {
    let store = TestStore(initialState: HomeFeature.State()) {
      HomeFeature()
    }

    await store.send(.viewAllHabitsTapped)
    await store.receive(.delegate(.navigateToHabits))
  }

  func testGreetingBasedOnTime() {
    var state = HomeFeature.State()
    // Greeting is computed based on current time
    XCTAssertFalse(state.greeting.isEmpty)
  }

  func testXpProgressCalculation() {
    var state = HomeFeature.State()
    state.profile = UserProfile(
      userId: UUID(),
      displayName: "Test",
      streak: 5,
      totalXp: 150, // Level 1 is 0-100, Level 2 is 100-300
      level: 1,
      lastActiveDate: Date(),
      isAdmin: false
    )

    // At 150 XP, should be 25% through level 2 (100-300 range)
    // Actually level 1 ends at 100, level 2 at 300
    // So at level 1 with 150 XP: progress = (150-100)/(300-100) = 50/200 = 0.25
    XCTAssertEqual(state.xpProgress, 0.25, accuracy: 0.01)
  }
}
```

## Feature Checklist

When creating a new feature:

- [ ] State contains all data needed for the view
- [ ] State has computed properties for derived values
- [ ] Actions cover all user interactions and async responses
- [ ] Delegate actions for navigation (parent handles)
- [ ] Dependencies declared with `@Dependency`
- [ ] Reducer handles loading, success, and error states
- [ ] View uses `@Bindable var store`
- [ ] View has `.task { store.send(.onAppear) }`
- [ ] View handles loading, error, and empty states
- [ ] View follows RIZQ design system
- [ ] Tests cover happy path and error cases
- [ ] Preview configured with mock dependencies
