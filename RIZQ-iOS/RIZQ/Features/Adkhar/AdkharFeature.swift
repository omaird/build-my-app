import ComposableArchitecture
import FirebaseAuth
import Foundation
import os.log
import SwiftUI
import RIZQKit

private let adkharLogger = Logger(subsystem: "com.rizq.app", category: "Adkhar")

// MARK: - Adkhar Feature
/// The daily habits (adkhar) feature for practicing duas by time of day.
///
/// ## Feature Requirements
/// The Daily Adkhar page displays the user's subscribed habits organized by time slot:
/// - **Morning Adhkar**: Duas to recite after Fajr prayer
/// - **Anytime Adhkar**: Duas that can be recited throughout the day
/// - **Evening Adhkar**: Duas to recite after Maghrib prayer
///
/// ## User States
/// - **Loading**: Shows loading overlay while fetching habits from journeys and custom habits
/// - **Error**: Shows error overlay with retry button when data fails to load
/// - **Empty**: No habits subscribed - shows empty state with "Browse Journeys" CTA
/// - **Active**: User has habits to practice with progress tracking
///
/// ## Quick Practice Flow
/// 1. User taps a habit card to open Quick Practice sheet
/// 2. User taps to increment repetition counter
/// 3. Upon reaching target repetitions, celebration animation plays
/// 4. Habit is marked complete and XP is awarded
/// 5. Completion is persisted to Firestore
///
/// ## Acceptance Criteria
/// 1. Habits are grouped by time slot (morning/anytime/evening)
/// 2. Progress is tracked per habit and shown in progress bar
/// 3. Streak badge shows current consecutive days
/// 4. Pull-to-refresh reloads all data
/// 5. Quick practice allows completing repetitions with haptic feedback
/// 6. Completions persist across app restarts
/// 7. All interactive elements have VoiceOver accessibility labels
@Reducer
struct AdkharFeature {
  @ObservableState
  struct State: Equatable {
    // MARK: - Habit Data

    /// Morning adhkar from subscribed journeys and custom habits
    var morningHabits: [Habit] = []
    /// Anytime adhkar from subscribed journeys and custom habits
    var anytimeHabits: [Habit] = []
    /// Evening adhkar from subscribed journeys and custom habits
    var eveningHabits: [Habit] = []
    /// Set of habit IDs completed today
    var completedIds: Set<Int> = []
    /// Whether data is being loaded
    var isLoading: Bool = false
    /// Current streak (consecutive days of practice)
    var streak: Int = 0

    // MARK: - Error State

    /// Error message from failed data load, nil when no error
    var loadError: String?

    // MARK: - Quick Practice Sheet State

    /// Currently selected habit for quick practice
    var selectedHabit: Habit?
    /// Whether quick practice sheet is visible
    var showQuickPractice: Bool = false
    /// Current repetition count in quick practice
    var repetitionCount: Int = 0
    /// Whether celebration animation is playing
    var showCelebration: Bool = false

    // Computed properties
    var totalHabits: Int {
      morningHabits.count + anytimeHabits.count + eveningHabits.count
    }

    var completedCount: Int {
      completedIds.count
    }

    var progressPercentage: Double {
      guard totalHabits > 0 else { return 0 }
      return Double(completedCount) / Double(totalHabits)
    }

    var totalXpAvailable: Int {
      (morningHabits + anytimeHabits + eveningHabits).reduce(0) { $0 + $1.xpValue }
    }

    var earnedXp: Int {
      (morningHabits + anytimeHabits + eveningHabits)
        .filter { completedIds.contains($0.id) }
        .reduce(0) { $0 + $1.xpValue }
    }

    // Progress by time slot - computed properties for TCA binding compatibility
    var morningProgress: TimeSlotProgress {
      let completed = morningHabits.filter { completedIds.contains($0.id) }.count
      return TimeSlotProgress(slot: .morning, completed: completed, total: morningHabits.count)
    }

    var anytimeProgress: TimeSlotProgress {
      let completed = anytimeHabits.filter { completedIds.contains($0.id) }.count
      return TimeSlotProgress(slot: .anytime, completed: completed, total: anytimeHabits.count)
    }

    var eveningProgress: TimeSlotProgress {
      let completed = eveningHabits.filter { completedIds.contains($0.id) }.count
      return TimeSlotProgress(slot: .evening, completed: completed, total: eveningHabits.count)
    }

    func isCompleted(_ habitId: Int) -> Bool {
      completedIds.contains(habitId)
    }

    // Quick practice progress
    var quickPracticeProgress: Double {
      guard let habit = selectedHabit, habit.repetitions > 0 else { return 0 }
      return min(Double(repetitionCount) / Double(habit.repetitions), 1.0)
    }

    var isQuickPracticeComplete: Bool {
      guard let habit = selectedHabit else { return false }
      return repetitionCount >= habit.repetitions || isCompleted(habit.id)
    }
  }

  enum Action {
    case onAppear
    case refreshData
    case habitsLoaded(morning: [Habit], anytime: [Habit], evening: [Habit])
    case loadFailed(String)
    case streakLoaded(Int)
    case completionsRestored(Set<Int>)
    case toggleHabit(Habit)
    case habitCompleted(Habit)

    // Quick Practice Actions
    case quickPracticeRequested(Habit)
    case quickPracticeDismissed
    case setShowQuickPractice(Bool)
    case incrementRepetition
    case resetRepetitions
    case practiceCompleted
    case celebrationFinished

    // Navigation (handled by parent AppFeature)
    case navigateToJourneys

    // Tab became active (called by parent when tab is selected)
    case becameActive
  }

  @Dependency(\.continuousClock) var clock
  @Dependency(HapticClient.self) var haptics
  @Dependency(\.adkharService) var adkharService

  var body: some ReducerOf<Self> {
    Reduce { state, action in
      switch action {
      case .onAppear:
        state.isLoading = true
        state.loadError = nil

        return .run { [adkharService] send in
          do {
            // Fetch all habits (journey + custom) from storage and database
            let habits = try await adkharService.fetchAllHabits()

            await send(.habitsLoaded(
              morning: habits.morning,
              anytime: habits.anytime,
              evening: habits.evening
            ))

            // Fetch streak and today's completions (requires auth)
            if let userId = adkharService.currentUserId() {
              let streak = try await adkharService.fetchStreak(userId)
              await send(.streakLoaded(streak))

              // Restore today's completions
              let completedIds = try await adkharService.fetchTodayCompletions(userId)
              if !completedIds.isEmpty {
                await send(.completionsRestored(completedIds))
              }
            } else {
              await send(.streakLoaded(0))
            }

          } catch {
            await send(.loadFailed(error.localizedDescription))
          }
        }

      case .refreshData:
        state.isLoading = true
        state.loadError = nil

        return .run { [adkharService] send in
          do {
            let habits = try await adkharService.fetchAllHabits()

            await send(.habitsLoaded(
              morning: habits.morning,
              anytime: habits.anytime,
              evening: habits.evening
            ))

            if let userId = adkharService.currentUserId() {
              let streak = try await adkharService.fetchStreak(userId)
              await send(.streakLoaded(streak))

              let completedIds = try await adkharService.fetchTodayCompletions(userId)
              if !completedIds.isEmpty {
                await send(.completionsRestored(completedIds))
              }
            } else {
              await send(.streakLoaded(0))
            }

          } catch {
            await send(.loadFailed(error.localizedDescription))
          }
        }

      case .habitsLoaded(let morning, let anytime, let evening):
        state.isLoading = false
        state.loadError = nil
        state.morningHabits = morning
        state.anytimeHabits = anytime
        state.eveningHabits = evening
        return .none

      case .loadFailed(let error):
        state.isLoading = false
        state.loadError = error
        return .none

      case .streakLoaded(let streak):
        state.streak = streak
        return .none

      case .completionsRestored(let ids):
        state.completedIds = ids
        return .none

      case .toggleHabit(let habit):
        if state.completedIds.contains(habit.id) {
          state.completedIds.remove(habit.id)
          return .run { _ in
            haptics.lightTap()
          }
        } else {
          state.completedIds.insert(habit.id)
          return .run { send in
            haptics.habitComplete()
            await send(.habitCompleted(habit))
          }
        }

      case .habitCompleted(let habit):
        // Capture state values for the effect
        let completedCount = state.completedCount
        let totalCount = state.totalHabits
        let streak = state.streak
        let xpEarned = habit.xpValue

        return .run { [adkharService] _ in
          // Update widget with current progress
          WidgetDataManager.shared.updateDailyProgress(
            completedCount: completedCount,
            totalCount: totalCount,
            streak: streak,
            currentXp: 0,
            xpToNextLevel: 100,
            level: 1
          )

          // Persist completion to Firestore
          guard let userId = adkharService.currentUserId() else { return }

          do {
            try await adkharService.recordCompletion(userId, habit.duaId, xpEarned)
            adkharLogger.info("Recorded completion: dua \(habit.duaId, privacy: .public), xp: \(xpEarned, privacy: .public)")
          } catch {
            adkharLogger.error("Error recording completion: \(error.localizedDescription, privacy: .public)")
          }
        }

      case .quickPracticeRequested(let habit):
        state.selectedHabit = habit
        state.repetitionCount = 0
        state.showCelebration = false
        state.showQuickPractice = true
        return .run { _ in
          haptics.mediumTap()
        }

      case .quickPracticeDismissed:
        state.showQuickPractice = false
        // Clear selected habit after animation
        return .run { [clock] _ in
          // Use do-catch to handle cancellation gracefully
          do {
            try await clock.sleep(for: .milliseconds(300))
          } catch {
            // Sleep was cancelled - this is expected if user navigates away quickly
          }
          // Note: We don't clear selectedHabit to preserve UI during dismiss animation
        }

      case .setShowQuickPractice(let show):
        state.showQuickPractice = show
        if !show {
          // Same cleanup as quickPracticeDismissed
          return .run { [clock] _ in
            do {
              try await clock.sleep(for: .milliseconds(300))
            } catch {
              // Sleep was cancelled - this is expected behavior
            }
          }
        }
        return .none

      case .incrementRepetition:
        guard let habit = state.selectedHabit else { return .none }
        guard !state.isCompleted(habit.id) else { return .none }

        state.repetitionCount += 1

        // Check if completed all repetitions
        if state.repetitionCount >= habit.repetitions {
          state.showCelebration = true
          state.completedIds.insert(habit.id)

          return .run { [clock, haptics] send in
            // Trigger completion haptics
            haptics.counterComplete()
            // Use do-catch to ensure celebrationFinished is always sent
            do {
              try await clock.sleep(for: .milliseconds(300))
            } catch {
              // Sleep cancelled - continue with celebration
            }
            haptics.celebration()
            // Persist completion to Firestore
            await send(.habitCompleted(habit))
            do {
              try await clock.sleep(for: .milliseconds(1200))
            } catch {
              // Sleep cancelled - still finish celebration
            }
            await send(.celebrationFinished)
          }
        }

        // Tap haptic for each increment
        return .run { _ in
          haptics.counterIncrement()
        }

      case .resetRepetitions:
        // Guard: Don't allow reset if habit is already completed
        guard let habit = state.selectedHabit, !state.isCompleted(habit.id) else {
          return .none
        }
        state.repetitionCount = 0
        return .run { [haptics] _ in
          haptics.warning()
        }

      case .practiceCompleted:
        guard let habit = state.selectedHabit else { return .none }
        state.completedIds.insert(habit.id)
        return .run { send in
          haptics.habitComplete()
          await send(.habitCompleted(habit))
        }

      case .celebrationFinished:
        state.showQuickPractice = false
        return .none

      case .navigateToJourneys:
        // Handled by parent AppFeature
        adkharLogger.info("🚀 navigateToJourneys action sent from AdkharFeature - bubbling up to parent")
        return .none

      case .becameActive:
        // Refresh data when tab becomes active to pick up any journey subscription changes
        // Always refresh to ensure we have latest data (handles stuck loading state too)
        let currentlyLoading = state.isLoading
        adkharLogger.info("becameActive: Refreshing habits, isLoading: \(currentlyLoading, privacy: .public)")
        return .send(.refreshData)
      }
    }
  }
}

// MARK: - Habit Model
struct Habit: Equatable, Identifiable, Hashable {
  let id: Int
  let duaId: Int
  let titleEn: String
  let arabicText: String
  let transliteration: String?
  let translation: String
  let source: String?
  let rizqBenefit: String?
  let propheticContext: String?
  let timeSlot: TimeSlot
  let xpValue: Int
  let repetitions: Int

  func hash(into hasher: inout Hasher) {
    hasher.combine(id)
  }
}

// MARK: - Greeting Helper
func getGreeting() -> String {
  let hour = Calendar.current.component(.hour, from: Date())
  if hour < 12 {
    return "Good Morning"
  } else if hour < 17 {
    return "Assalamu Alaikum"
  } else {
    return "Good Evening"
  }
}

// MARK: - Adkhar Service Client

/// Dependency client for fetching habits from subscribed journeys and managing completions
struct AdkharServiceClient: Sendable {
  /// Fetches habits grouped by time slot from all subscribed journeys and custom habits
  var fetchAllHabits: @Sendable () async throws -> (morning: [Habit], anytime: [Habit], evening: [Habit])
  /// Fetches habits grouped by time slot from specified journeys only
  var fetchHabitsForJourneys: @Sendable ([Int]) async throws -> (morning: [Habit], anytime: [Habit], evening: [Habit])
  /// Fetches the user's current streak
  var fetchStreak: @Sendable (String) async throws -> Int
  /// Records a dua completion and awards XP
  var recordCompletion: @Sendable (String, Int, Int) async throws -> Void
  /// Fetches today's completed dua IDs for restoring state
  var fetchTodayCompletions: @Sendable (String) async throws -> Set<Int>
  /// Gets active journey IDs from local storage
  var getActiveJourneyIds: @Sendable () async throws -> [Int]
  /// Gets the current authenticated user's ID (nil if not signed in)
  var currentUserId: @Sendable () -> String?
}

extension AdkharServiceClient: DependencyKey {
  static let liveValue: AdkharServiceClient = {
    // Use FirestoreContentService for content data (duas, journeys)
    // This fixes the issue where neonService falls back to MockNeonService
    // when Neon credentials are not configured (Firebase-only setup)
    let firestoreContentService = FirestoreContentService()
    let firestoreService = FirestoreService()
    let habitStorage = ServiceContainer.shared.habitStorage

    // Helper function to convert JourneyDua + Dua to Habit
    func convertToHabit(journeyDua: JourneyDua, dua: Dua) -> Habit {
      Habit(
        id: dua.id,
        duaId: dua.id,
        titleEn: dua.titleEn,
        arabicText: dua.arabicText,
        transliteration: dua.transliteration,
        translation: dua.translationEn,
        source: dua.source,
        rizqBenefit: dua.rizqBenefit,
        propheticContext: dua.propheticContext,
        timeSlot: journeyDua.timeSlot,
        xpValue: dua.xpValue,
        repetitions: dua.repetitions
      )
    }

    // Helper to fetch journey habits with full dua data
    func fetchJourneyHabits(journeyId: Int, duasCache: [Int: Dua]) async throws -> (morning: [Habit], anytime: [Habit], evening: [Habit]) {
      var morning: [Habit] = []
      var anytime: [Habit] = []
      var evening: [Habit] = []

      let journeyDuas = try await firestoreContentService.fetchJourneyDuas(journeyId)

      for journeyDua in journeyDuas {
        guard let dua = duasCache[journeyDua.duaId] else { continue }
        let habit = convertToHabit(journeyDua: journeyDua, dua: dua)

        switch journeyDua.timeSlot {
        case .morning: morning.append(habit)
        case .anytime: anytime.append(habit)
        case .evening: evening.append(habit)
        }
      }

      return (morning, anytime, evening)
    }

    return AdkharServiceClient(
      fetchAllHabits: {
        // Get active journey IDs from habit storage
        let journeyIds = try await habitStorage.getActiveJourneyIds()

        // Fetch all duas once and create a lookup cache
        let allDuas = try await firestoreContentService.fetchAllDuas()
        let duasCache = Dictionary(uniqueKeysWithValues: allDuas.map { ($0.id, $0) })

        var morning: [Habit] = []
        var anytime: [Habit] = []
        var evening: [Habit] = []

        // Fetch journey habits using Firestore
        for journeyId in journeyIds {
          let habits = try await fetchJourneyHabits(journeyId: journeyId, duasCache: duasCache)
          morning.append(contentsOf: habits.morning)
          anytime.append(contentsOf: habits.anytime)
          evening.append(contentsOf: habits.evening)
        }

        // Fetch custom habits
        let customHabits = try await habitStorage.getCustomHabits()
        for customHabit in customHabits {
          // Use cached dua if available
          if let dua = duasCache[customHabit.duaId] {
            let habit = Habit(
              id: dua.id,
              duaId: dua.id,
              titleEn: dua.titleEn,
              arabicText: dua.arabicText,
              transliteration: dua.transliteration,
              translation: dua.translationEn,
              source: dua.source,
              rizqBenefit: dua.rizqBenefit,
              propheticContext: dua.propheticContext,
              timeSlot: customHabit.timeSlot,
              xpValue: dua.xpValue,
              repetitions: dua.repetitions
            )

            switch customHabit.timeSlot {
            case .morning: morning.append(habit)
            case .anytime: anytime.append(habit)
            case .evening: evening.append(habit)
            }
          }
        }

        // Sort by ID and remove duplicates (same dua might be in journey + custom)
        morning = Array(Set(morning)).sorted { $0.id < $1.id }
        anytime = Array(Set(anytime)).sorted { $0.id < $1.id }
        evening = Array(Set(evening)).sorted { $0.id < $1.id }

        return (morning: morning, anytime: anytime, evening: evening)
      },

      fetchHabitsForJourneys: { journeyIds in
        // Fetch all duas once and create a lookup cache
        let allDuas = try await firestoreContentService.fetchAllDuas()
        let duasCache = Dictionary(uniqueKeysWithValues: allDuas.map { ($0.id, $0) })

        var morning: [Habit] = []
        var anytime: [Habit] = []
        var evening: [Habit] = []

        for journeyId in journeyIds {
          let habits = try await fetchJourneyHabits(journeyId: journeyId, duasCache: duasCache)
          morning.append(contentsOf: habits.morning)
          anytime.append(contentsOf: habits.anytime)
          evening.append(contentsOf: habits.evening)
        }

        // Sort by ID for consistent ordering and remove duplicates
        morning = Array(Set(morning)).sorted { $0.id < $1.id }
        anytime = Array(Set(anytime)).sorted { $0.id < $1.id }
        evening = Array(Set(evening)).sorted { $0.id < $1.id }

        return (morning: morning, anytime: anytime, evening: evening)
      },

      fetchStreak: { userId in
        // Use FirestoreService for user data
        let profile = try await firestoreService.fetchUserProfile(userId: userId)
        return profile?.streak ?? 0
      },

      recordCompletion: { userId, duaId, xpEarned in
        try await firestoreService.recordDuaCompletion(
          userId: userId,
          duaId: duaId,
          xp: xpEarned
        )
      },

      fetchTodayCompletions: { userId in
        if let activity = try await firestoreService.fetchUserActivity(userId: userId, date: Date()) {
          return Set(activity.duasCompleted)
        }
        return []
      },

      getActiveJourneyIds: {
        try await habitStorage.getActiveJourneyIds()
      },

      currentUserId: {
        Auth.auth().currentUser?.uid
      }
    )
  }()

  static let testValue = AdkharServiceClient(
    fetchAllHabits: { ([], [], []) },
    fetchHabitsForJourneys: { _ in ([], [], []) },
    fetchStreak: { _ in 7 },
    recordCompletion: { _, _, _ in },
    fetchTodayCompletions: { _ in [] },
    getActiveJourneyIds: { [] },
    currentUserId: { "test-user-id" }
  )

  static let previewValue = AdkharServiceClient(
    fetchAllHabits: {
      // Return sample habits for previews
      let morning = [
        Habit(
          id: 1, duaId: 1, titleEn: "Morning Remembrance",
          arabicText: "أَصْبَحْنَا وَأَصْبَحَ الْمُلْكُ لِلَّهِ",
          transliteration: "Asbahna wa asbahal mulku lillah",
          translation: "We have reached the morning and at this very time unto Allah belongs all sovereignty",
          source: "Muslim", rizqBenefit: "Protection throughout the day",
          propheticContext: "The Prophet (PBUH) would say this every morning",
          timeSlot: .morning, xpValue: 10, repetitions: 3
        )
      ]
      let evening = [
        Habit(
          id: 2, duaId: 2, titleEn: "Evening Protection",
          arabicText: "أَمْسَيْنَا وَأَمْسَى الْمُلْكُ لِلَّهِ",
          transliteration: "Amsayna wa amsal mulku lillah",
          translation: "We have reached the evening and at this very time unto Allah belongs all sovereignty",
          source: "Muslim", rizqBenefit: "Protection throughout the night",
          propheticContext: nil,
          timeSlot: .evening, xpValue: 10, repetitions: 3
        )
      ]
      return (morning, [], evening)
    },
    fetchHabitsForJourneys: { _ in
      let morning = [
        Habit(
          id: 1, duaId: 1, titleEn: "Morning Remembrance",
          arabicText: "أَصْبَحْنَا وَأَصْبَحَ الْمُلْكُ لِلَّهِ",
          transliteration: "Asbahna wa asbahal mulku lillah",
          translation: "We have reached the morning",
          source: "Muslim", rizqBenefit: nil, propheticContext: nil,
          timeSlot: .morning, xpValue: 10, repetitions: 3
        )
      ]
      return (morning, [], [])
    },
    fetchStreak: { _ in 7 },
    recordCompletion: { _, _, _ in },
    fetchTodayCompletions: { _ in [] },
    getActiveJourneyIds: { [1, 2] },
    currentUserId: { "preview-user-id" }
  )
}

extension DependencyValues {
  var adkharService: AdkharServiceClient {
    get { self[AdkharServiceClient.self] }
    set { self[AdkharServiceClient.self] = newValue }
  }
}
