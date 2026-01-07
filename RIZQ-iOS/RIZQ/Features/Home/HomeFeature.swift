import ComposableArchitecture
import Foundation
import RIZQKit

@Reducer
struct HomeFeature {
  @ObservableState
  struct State: Equatable {
    // User profile data
    var displayName: String = ""
    var streak: Int = 0
    var totalXp: Int = 0
    var level: Int = 1

    // Today's habits progress
    var todaysProgress: TodayProgress = TodayProgress(completed: 0, total: 0, xpEarned: 0)
    var todaysHabits: [UserHabit] = []

    // UI state
    var isLoading: Bool = false
    var isStreakAnimating: Bool = false
    var showWelcomeSheet: Bool = false

    // Computed properties
    var greeting: String {
      let hour = Calendar.current.component(.hour, from: Date())
      if hour < 12 { return "Good morning" }
      if hour < 17 { return "Good afternoon" }
      return "Good evening"
    }

    var motivationalPhrase: String {
      if streak == 0 { return "Start your journey today!" }
      if streak < 3 { return "Great start! Keep going!" }
      if streak < 7 { return "You're building momentum!" }
      if streak < 14 { return "Amazing consistency!" }
      if streak < 30 { return "You're on fire!" }
      return "Incredible dedication!"
    }

    var xpProgress: XPProgress {
      XPProgress(totalXp: totalXp, level: level)
    }
  }

  enum Action: Equatable {
    case onAppear
    case refreshData
    case profileLoaded(displayName: String, streak: Int, xp: Int, level: Int)
    case habitsProgressLoaded(TodayProgress)
    case todaysHabitsLoaded([UserHabit])
    case streakIncremented
    case streakAnimationCompleted
    case dismissWelcomeSheet
    case navigateToPractice(TimeSlot)
    case navigateToAdkhar
    case navigateToLibrary
  }

  @Dependency(\.continuousClock) var clock

  var body: some ReducerOf<Self> {
    Reduce { state, action in
      switch action {
      case .onAppear:
        state.isLoading = true
        // Demo data - in production, fetch from UserService
        return .run { send in
          // Simulate loading delay
          try await clock.sleep(for: .milliseconds(500))
          await send(.profileLoaded(displayName: "Friend", streak: 7, xp: 450, level: 3))
          await send(.habitsProgressLoaded(TodayProgress(completed: 3, total: 5, xpEarned: 45)))
        }

      case .refreshData:
        state.isLoading = true
        return .run { send in
          try await clock.sleep(for: .milliseconds(300))
          await send(.profileLoaded(displayName: "Friend", streak: 7, xp: 450, level: 3))
          await send(.habitsProgressLoaded(TodayProgress(completed: 3, total: 5, xpEarned: 45)))
        }

      case .profileLoaded(let displayName, let streak, let xp, let level):
        let previousStreak = state.streak
        state.isLoading = false
        state.displayName = displayName
        state.streak = streak
        state.totalXp = xp
        state.level = level

        // Trigger streak animation if streak increased
        if previousStreak > 0 && streak > previousStreak {
          state.isStreakAnimating = true
          return .run { send in
            try await clock.sleep(for: .seconds(2))
            await send(.streakAnimationCompleted)
          }
        }
        return .none

      case .habitsProgressLoaded(let progress):
        state.todaysProgress = progress
        return .none

      case .todaysHabitsLoaded(let habits):
        state.todaysHabits = habits
        return .none

      case .streakIncremented:
        state.isStreakAnimating = true
        return .run { send in
          try await clock.sleep(for: .seconds(2))
          await send(.streakAnimationCompleted)
        }

      case .streakAnimationCompleted:
        state.isStreakAnimating = false
        return .none

      case .dismissWelcomeSheet:
        state.showWelcomeSheet = false
        return .none

      case .navigateToPractice, .navigateToAdkhar, .navigateToLibrary:
        // Handled by parent feature for navigation
        return .none
      }
    }
  }
}

// MARK: - XP Progress Calculation

struct XPProgress: Equatable {
  let current: Int
  let needed: Int
  let percentage: Double
  let xpToNextLevel: Int

  init(totalXp: Int, level: Int) {
    let currentLevelXp = level > 1 ? LevelCalculator.xpNeeded(for: level - 1) : 0
    let nextLevelXp = LevelCalculator.xpNeeded(for: level)
    let xpInCurrentLevel = totalXp - currentLevelXp
    let xpNeededForNext = nextLevelXp - currentLevelXp

    self.current = xpInCurrentLevel
    self.needed = xpNeededForNext
    self.percentage = xpNeededForNext > 0 ? min(Double(xpInCurrentLevel) / Double(xpNeededForNext), 1.0) : 0
    self.xpToNextLevel = max(0, nextLevelXp - totalXp)
  }
}
