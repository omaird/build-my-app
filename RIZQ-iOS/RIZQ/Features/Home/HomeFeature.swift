import ComposableArchitecture
import Foundation
import RIZQKit

@Reducer
struct HomeFeature {
  @ObservableState
  struct State: Equatable {
    // User ID for fetching data (set by parent feature)
    var userId: String?

    // User profile data
    var displayName: String = ""
    var streak: Int = 0
    var totalXp: Int = 0
    var level: Int = 1

    // Today's activity
    var todayActivity: UserActivity?

    // Today's habits progress
    var todaysProgress: TodayProgress = TodayProgress(completed: 0, total: 0, xpEarned: 0)
    var todaysHabits: [UserHabit] = []

    // UI state
    var isLoading: Bool = false
    var isStreakAnimating: Bool = false
    var showWelcomeSheet: Bool = false
    var loadError: String?

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
    case setUserId(String?)
    case profileLoaded(UserProfile)
    case profileLoadFailed(String)
    case activityLoaded(UserActivity?)
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
  @Dependency(\.neonClient) var neonClient

  var body: some ReducerOf<Self> {
    Reduce { state, action in
      switch action {
      case .onAppear:
        guard let userId = state.userId else {
          // No user ID yet, wait for it to be set
          return .none
        }
        state.isLoading = true
        state.loadError = nil

        return .run { [userId] send in
          // Fetch user profile from Firestore via NeonClient
          do {
            if let profile = try await neonClient.fetchUserProfile(userId) {
              await send(.profileLoaded(profile))
            } else {
              // Create a new profile if none exists
              let newProfile = try await neonClient.createUserProfile(userId, nil)
              await send(.profileLoaded(newProfile))
            }

            // Fetch today's activity
            let activity = try await neonClient.fetchUserActivity(userId, Date())
            await send(.activityLoaded(activity))
          } catch {
            await send(.profileLoadFailed(error.localizedDescription))
          }
        }

      case .refreshData:
        guard let userId = state.userId else { return .none }
        state.isLoading = true
        state.loadError = nil

        return .run { [userId] send in
          do {
            if let profile = try await neonClient.fetchUserProfile(userId) {
              await send(.profileLoaded(profile))
            }
            let activity = try await neonClient.fetchUserActivity(userId, Date())
            await send(.activityLoaded(activity))
          } catch {
            await send(.profileLoadFailed(error.localizedDescription))
          }
        }

      case .setUserId(let userId):
        state.userId = userId
        // Trigger data load if userId is set
        if userId != nil {
          return .send(.onAppear)
        }
        return .none

      case .profileLoaded(let profile):
        let previousStreak = state.streak
        state.isLoading = false
        state.loadError = nil
        state.displayName = profile.displayName ?? "Friend"
        state.streak = profile.streak
        state.totalXp = profile.totalXp
        state.level = profile.level

        // Trigger streak animation if streak increased
        if previousStreak > 0 && profile.streak > previousStreak {
          state.isStreakAnimating = true
          return .run { send in
            try await clock.sleep(for: .seconds(2))
            await send(.streakAnimationCompleted)
          }
        }
        return .none

      case .profileLoadFailed(let error):
        state.isLoading = false
        state.loadError = error
        return .none

      case .activityLoaded(let activity):
        state.todayActivity = activity
        if let activity = activity {
          // Update today's progress based on activity
          let duasCount = activity.duasCompleted.count
          state.todaysProgress = TodayProgress(
            completed: duasCount,
            total: max(duasCount, state.todaysHabits.count),
            xpEarned: activity.xpEarned
          )
        }
        return .none

      case .habitsProgressLoaded(let progress):
        state.todaysProgress = progress
        return .none

      case .todaysHabitsLoaded(let habits):
        state.todaysHabits = habits
        // Update progress total
        let completed = state.todayActivity?.duasCompleted.count ?? state.todaysProgress.completed
        state.todaysProgress = TodayProgress(
          completed: completed,
          total: habits.count,
          xpEarned: state.todaysProgress.xpEarned
        )
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
