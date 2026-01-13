import ComposableArchitecture
import Foundation
import RIZQKit

// MARK: - HomeFeature
/// The main dashboard feature for the RIZQ iOS app.
///
/// ## Feature Requirements
/// The home page displays the user's daily progress and gamification stats:
/// - **Greeting Section**: Time-based greeting with user name and motivational phrase
/// - **Streak Badge**: Current consecutive days of practice (animated on increase)
/// - **Level & XP Progress**: Current level with progress bar to next level
/// - **Week Calendar**: Past 7 days of activity with completion indicators
/// - **Today's Progress**: Summary of completed duas and XP earned today
/// - **Daily Adkhar Summary**: Link to today's habits with completion percentage
/// - **Daily Quote**: Inspirational Islamic quote with daily rotation
/// - **Motivational Progress**: Dynamic encouragement based on daily completion
/// - **Navigation CTAs**: Quick access to Journeys and Library
///
/// ## User States
/// - **Loading**: Shows loading overlay while fetching data
/// - **Error**: Shows error overlay with retry button when data fails to load
/// - **Empty**: New user with no activity shows welcome state
/// - **Active**: User with profile data shows full dashboard
///
/// ## New Component Integration (Feature 5)
/// - `dailyQuote` computed property: Deterministic daily rotation via IslamicQuote.quoteForToday()
/// - `motivationState` computed property: TCA "dumb view" pattern - view receives pre-computed state
/// - `nextAchievement` computed property: First locked achievement for upcoming badge preview
/// - `shareQuoteTapped` action: Triggers quote share (view handles haptics)
/// - `motivationActionTapped` action: Routes based on state (noHabits→journeys, others→adkhar)
/// - `achievementTapped` action: Achievement interaction (view handles haptics)
///
/// ## Acceptance Criteria
/// 1. ✅ Displays personalized greeting based on time of day
/// 2. ✅ Shows current streak with celebratory animation when streak increases
/// 3. ✅ Displays accurate XP progress toward next level
/// 4. ✅ Pull-to-refresh reloads all data
/// 5. ✅ Error state allows retry without leaving the screen
/// 6. ✅ All interactive elements have VoiceOver accessibility labels
/// 7. ✅ Daily quote computed property returns consistent quote for same day
/// 8. ✅ Motivation state computed correctly for all 5 states
/// 9. ✅ motivationActionTapped routes intelligently based on state
/// 10. ✅ Unit tests cover all new computed properties and actions
///
/// ## Related Files
/// - HomeView.swift: SwiftUI view consuming this feature
/// - RIZQKit/Models/Achievement.swift: Achievement model with defaults
/// - RIZQKit/Models/IslamicQuote.swift: Quote model with daily rotation
/// - RIZQKit/Models/MotivationState.swift: Extracted motivation state enum
/// - RIZQTests/RIZQTests.swift: Unit tests for HomeFeature integration
@Reducer
struct HomeFeature {
  @ObservableState
  struct State: Equatable {
    // User ID for fetching data (set by parent feature)
    var userId: String?

    // Auth user data (from Firebase Auth - name and photo from Google)
    var authUserName: String?
    var authUserImageURL: URL?

    // User profile data (from Firestore)
    var profileDisplayName: String?
    var streak: Int = 0
    var totalXp: Int = 0
    var level: Int = 1

    // Computed display name: prefer auth user name, then profile, then "Friend"
    var displayName: String {
      if let name = authUserName, !name.isEmpty {
        // Extract first name from full name
        return name.components(separatedBy: " ").first ?? name
      }
      if let profileName = profileDisplayName, !profileName.isEmpty, profileName != "Friend" {
        return profileName.components(separatedBy: " ").first ?? profileName
      }
      return "Friend"
    }

    // Computed profile image: prefer auth user image
    var profileImageURL: URL? {
      authUserImageURL
    }

    // Today's activity
    var todayActivity: UserActivity?

    // Week activities for calendar
    var weekActivities: [UserActivity] = []

    // Today's habits progress
    var todaysProgress: TodayProgress = TodayProgress(completed: 0, total: 0, xpEarned: 0)
    var todaysHabits: [UserHabit] = []

    // Achievements (use defaults until Firestore integration is added)
    var achievements: [Achievement] = Achievement.defaults

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

    /// Rotating inspirational Islamic quotes about beginning and Allah
    var inspirationalQuote: String {
      InspirationalQuotes.quoteForCurrentMinute()
    }

    var xpProgress: XPProgress {
      XPProgress(totalXp: totalXp, level: level)
    }

    // Week activity items for the calendar
    var weekActivityItems: [DailyActivityItem] {
      DailyActivityItem.weekItems(from: weekActivities)
    }

    // MARK: - New Component Computed Properties

    /// Daily quote computed from IslamicQuote's deterministic rotation
    var dailyQuote: IslamicQuote {
      IslamicQuote.quoteForToday()
    }

    /// Motivation state computed from today's progress (TCA "dumb view" pattern)
    var motivationState: MotivationState {
      MotivationState(
        habitsCompleted: todaysProgress.completed,
        totalHabits: todaysProgress.total
      )
    }

    /// Next achievement to unlock (first locked achievement by category priority)
    var nextAchievement: Achievement? {
      achievements.first { !$0.isUnlocked }
    }
  }

  enum Action: Equatable {
    case onAppear
    case refreshData
    case setUserId(String?)
    case setAuthUser(id: String, name: String?, imageURL: String?)
    case profileLoaded(UserProfile)
    case profileLoadFailed(String)
    case activityLoaded(UserActivity?)
    case weekActivitiesLoaded([UserActivity])
    case habitsProgressLoaded(TodayProgress)
    case todaysHabitsLoaded([UserHabit])
    case streakIncremented
    case streakAnimationCompleted
    case dismissWelcomeSheet
    case navigateToPractice(TimeSlot)
    case navigateToAdkhar
    case navigateToLibrary
    case navigateToJourneys

    // New component actions
    case shareQuoteTapped
    case motivationActionTapped
    case achievementTapped(Achievement)
  }

  @Dependency(\.continuousClock) var clock
  @Dependency(\.firestoreUserClient) var userClient
  @Dependency(\.adkharService) var adkharService

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

        return .run { [userId, adkharService] send in
          // Fetch user profile from Firestore via FirestoreUserClient
          do {
            if let profile = try await userClient.fetchUserProfile(userId) {
              await send(.profileLoaded(profile))
            } else {
              // Create a new profile if none exists
              let newProfile = try await userClient.createUserProfile(userId, nil)
              await send(.profileLoaded(newProfile))
            }

            // Fetch today's activity
            let activity = try await userClient.fetchUserActivity(userId, Date())
            await send(.activityLoaded(activity))

            // Fetch week activities for calendar
            let weekActivities = try await userClient.fetchWeekActivities(userId)
            await send(.weekActivitiesLoaded(weekActivities))

            // Fetch total habits for progress display
            let habits = try await adkharService.fetchAllHabits()
            let totalHabits = habits.morning.count + habits.anytime.count + habits.evening.count
            let habitsProgress = TodayProgress(
              completed: activity?.duasCompleted.count ?? 0,
              total: totalHabits,
              xpEarned: activity?.xpEarned ?? 0
            )
            await send(.habitsProgressLoaded(habitsProgress))
          } catch {
            await send(.profileLoadFailed(error.localizedDescription))
          }
        }

      case .refreshData:
        guard let userId = state.userId else { return .none }
        state.isLoading = true
        state.loadError = nil

        return .run { [userId, adkharService] send in
          do {
            // Fetch profile - create if not found (consistent with onAppear)
            if let profile = try await userClient.fetchUserProfile(userId) {
              await send(.profileLoaded(profile))
            } else {
              // Create a new profile if none exists during refresh
              let newProfile = try await userClient.createUserProfile(userId, nil)
              await send(.profileLoaded(newProfile))
            }

            let activity = try await userClient.fetchUserActivity(userId, Date())
            await send(.activityLoaded(activity))

            // Fetch week activities for calendar
            let weekActivities = try await userClient.fetchWeekActivities(userId)
            await send(.weekActivitiesLoaded(weekActivities))

            // Fetch total habits for progress display
            let habits = try await adkharService.fetchAllHabits()
            let totalHabits = habits.morning.count + habits.anytime.count + habits.evening.count
            let habitsProgress = TodayProgress(
              completed: activity?.duasCompleted.count ?? 0,
              total: totalHabits,
              xpEarned: activity?.xpEarned ?? 0
            )
            await send(.habitsProgressLoaded(habitsProgress))
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

      case .setAuthUser(let id, let name, let imageURL):
        state.userId = id
        state.authUserName = name
        if let urlString = imageURL, let url = URL(string: urlString) {
          state.authUserImageURL = url
        }
        // Trigger data load
        return .send(.onAppear)

      case .profileLoaded(let profile):
        let previousStreak = state.streak
        state.isLoading = false
        state.loadError = nil
        state.profileDisplayName = profile.displayName
        state.streak = profile.streak
        state.totalXp = profile.totalXp
        state.level = profile.level

        // Trigger streak animation if streak increased
        if previousStreak > 0 && profile.streak > previousStreak {
          state.isStreakAnimating = true
          return .run { send in
            // Use do-catch to ensure animation completes even if sleep throws
            do {
              try await clock.sleep(for: .seconds(2))
            } catch {
              // Sleep was cancelled or failed - still complete animation
            }
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

      case .weekActivitiesLoaded(let activities):
        state.weekActivities = activities
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
          // Use do-catch to ensure animation completes even if sleep throws
          do {
            try await clock.sleep(for: .seconds(2))
          } catch {
            // Sleep was cancelled or failed - still complete animation
          }
          await send(.streakAnimationCompleted)
        }

      case .streakAnimationCompleted:
        state.isStreakAnimating = false
        return .none

      case .dismissWelcomeSheet:
        state.showWelcomeSheet = false
        return .none

      case .navigateToPractice, .navigateToAdkhar, .navigateToLibrary, .navigateToJourneys:
        // Handled by parent feature for navigation
        return .none

      // MARK: - New Component Actions

      case .shareQuoteTapped:
        // TODO: Implement share sheet for quote
        // For now, haptic feedback is handled by the view
        return .none

      case .motivationActionTapped:
        // Navigate based on motivation state
        switch state.motivationState {
        case .noHabits:
          // Navigate to journeys to subscribe
          return .send(.navigateToJourneys)
        case .notStarted, .lightDay, .productiveDay:
          // Navigate to adkhar to continue practice
          return .send(.navigateToAdkhar)
        case .perfectDay:
          // No action needed - celebrate!
          return .none
        }

      case .achievementTapped:
        // TODO: Show achievement detail sheet
        // For now, haptic feedback is handled by the view
        return .none
      }
    }
  }
}

// MARK: - Inspirational Quotes

/// Rotating inspirational Islamic quotes about beginning and Allah.
/// Quotes rotate every minute for gentle variety.
enum InspirationalQuotes {
  static let quotes = [
    "Bismillah — In the name of Allah, begin your journey",
    "Every good deed starts with intention and ends with gratitude",
    "The journey of a thousand prayers begins with a single step",
    "Trust in Allah, but tie your camel — begin with purpose",
    "With Allah's name, nothing is impossible",
    "Start each day remembering the One who gave it to you",
    "Your rizq is written — walk towards it with faith",
    "Begin with Bismillah, end with Alhamdulillah",
    "The best provision for the journey is taqwa",
    "When you call upon Allah, know that He hears you",
    "Take the first step, and Allah will guide your path",
    "Patience and prayer — your companions on this journey",
  ]

  /// Returns a quote that rotates every minute
  static func quoteForCurrentMinute() -> String {
    let minutesSinceEpoch = Int(Date().timeIntervalSince1970 / 60)
    let index = minutesSinceEpoch % quotes.count
    return quotes[index]
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
