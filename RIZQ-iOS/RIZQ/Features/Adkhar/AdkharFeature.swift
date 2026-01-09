import ComposableArchitecture
import FirebaseAuth
import Foundation
import SwiftUI
import RIZQKit

// MARK: - Adkhar Feature
@Reducer
struct AdkharFeature {
  @ObservableState
  struct State: Equatable {
    var morningHabits: [Habit] = []
    var anytimeHabits: [Habit] = []
    var eveningHabits: [Habit] = []
    var completedIds: Set<Int> = []
    var isLoading: Bool = false
    var streak: Int = 0

    // Quick Practice Sheet State
    var selectedHabit: Habit?
    var showQuickPractice: Bool = false
    var repetitionCount: Int = 0
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
    case habitsLoaded(morning: [Habit], anytime: [Habit], evening: [Habit])
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
  }

  @Dependency(\.continuousClock) var clock
  @Dependency(HapticClient.self) var haptics
  @Dependency(\.adkharService) var adkharService

  var body: some ReducerOf<Self> {
    Reduce { state, action in
      switch action {
      case .onAppear:
        state.isLoading = true

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
            if let userId = getCurrentUserId() {
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
            // On error, show empty state with logged error
            print("Error loading habits: \(error)")
            await send(.habitsLoaded(morning: [], anytime: [], evening: []))
            await send(.streakLoaded(0))
          }
        }

      case .habitsLoaded(let morning, let anytime, let evening):
        state.isLoading = false
        state.morningHabits = morning
        state.anytimeHabits = anytime
        state.eveningHabits = evening
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
          guard let userId = getCurrentUserId() else { return }

          do {
            try await adkharService.recordCompletion(userId, habit.duaId, xpEarned)
            print("Recorded completion: dua \(habit.duaId), xp: \(xpEarned)")
          } catch {
            print("Error recording completion: \(error)")
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
        return .run { _ in
          try await clock.sleep(for: .milliseconds(300))
          // Note: We don't clear selectedHabit to preserve UI during dismiss animation
        }

      case .setShowQuickPractice(let show):
        state.showQuickPractice = show
        if !show {
          // Same cleanup as quickPracticeDismissed
          return .run { _ in
            try await clock.sleep(for: .milliseconds(300))
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

          return .run { send in
            // Trigger completion haptics
            haptics.counterComplete()
            try await clock.sleep(for: .milliseconds(300))
            haptics.celebration()
            // Persist completion to Firestore
            await send(.habitCompleted(habit))
            try await clock.sleep(for: .milliseconds(1200))
            await send(.celebrationFinished)
          }
        }

        // Tap haptic for each increment
        return .run { _ in
          haptics.counterIncrement()
        }

      case .resetRepetitions:
        state.repetitionCount = 0
        return .run { _ in
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
}

extension AdkharServiceClient: DependencyKey {
  static let liveValue: AdkharServiceClient = {
    let neonService = ServiceContainer.shared.neonService
    let habitStorage = ServiceContainer.shared.habitStorage

    // Helper function to convert JourneyDuaFull to Habit
    func convertToHabits(
      journeyDuas: [JourneyDuaFull]
    ) -> (morning: [Habit], anytime: [Habit], evening: [Habit]) {
      var morning: [Habit] = []
      var anytime: [Habit] = []
      var evening: [Habit] = []

      for jd in journeyDuas {
        let habit = Habit(
          id: jd.dua.id,
          duaId: jd.dua.id,
          titleEn: jd.dua.titleEn,
          arabicText: jd.dua.arabicText,
          transliteration: jd.dua.transliteration,
          translation: jd.dua.translationEn,
          source: jd.dua.source,
          rizqBenefit: jd.dua.rizqBenefit,
          propheticContext: jd.dua.propheticContext,
          timeSlot: jd.journeyDua.timeSlot,
          xpValue: jd.dua.xpValue,
          repetitions: jd.dua.repetitions
        )

        switch jd.journeyDua.timeSlot {
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

        var morning: [Habit] = []
        var anytime: [Habit] = []
        var evening: [Habit] = []

        // Fetch journey habits
        for journeyId in journeyIds {
          let journeyDuas = try await neonService.fetchJourneyDuas(journeyId: journeyId)
          let habits = convertToHabits(journeyDuas: journeyDuas)
          morning.append(contentsOf: habits.morning)
          anytime.append(contentsOf: habits.anytime)
          evening.append(contentsOf: habits.evening)
        }

        // Fetch custom habits
        let customHabits = try await habitStorage.getCustomHabits()
        for customHabit in customHabits {
          // Fetch the dua details for each custom habit
          if let dua = try await neonService.fetchDua(id: customHabit.duaId) {
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
        var morning: [Habit] = []
        var anytime: [Habit] = []
        var evening: [Habit] = []

        for journeyId in journeyIds {
          let journeyDuas = try await neonService.fetchJourneyDuas(journeyId: journeyId)
          let habits = convertToHabits(journeyDuas: journeyDuas)
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
        let profile = try await neonService.fetchUserProfile(userId: userId)
        return profile?.streak ?? 0
      },

      recordCompletion: { userId, duaId, xpEarned in
        try await neonService.recordDuaCompletion(
          userId: userId,
          duaId: duaId,
          xpEarned: xpEarned
        )
      },

      fetchTodayCompletions: { userId in
        if let activity = try await neonService.fetchUserActivity(userId: userId, date: Date()) {
          return Set(activity.duasCompleted)
        }
        return []
      },

      getActiveJourneyIds: {
        try await habitStorage.getActiveJourneyIds()
      }
    )
  }()

  static let testValue = AdkharServiceClient(
    fetchAllHabits: { ([], [], []) },
    fetchHabitsForJourneys: { _ in ([], [], []) },
    fetchStreak: { _ in 7 },
    recordCompletion: { _, _, _ in },
    fetchTodayCompletions: { _ in [] },
    getActiveJourneyIds: { [] }
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
    getActiveJourneyIds: { [1, 2] }
  )
}

extension DependencyValues {
  var adkharService: AdkharServiceClient {
    get { self[AdkharServiceClient.self] }
    set { self[AdkharServiceClient.self] = newValue }
  }
}

// MARK: - Helper Functions

/// Gets the current Firebase Auth user ID, if authenticated
private func getCurrentUserId() -> String? {
  Auth.auth().currentUser?.uid
}
