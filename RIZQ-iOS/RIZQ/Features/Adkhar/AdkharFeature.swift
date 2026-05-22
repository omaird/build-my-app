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

    // MARK: - Parent-Pushed Content
    //
    // Mirrored from ContentFeature via .contentUpdated. Used to recompute the
    // habit lists locally instead of triggering another Firestore round trip.
    // Default empty — habits stay empty until content arrives.
    var availableDuas: [Dua] = []
    var availableJourneyDuas: [JourneyDua] = []

    // MARK: - Error State

    /// Error message from failed data load, nil when no error
    var loadError: String?

    // MARK: - Filter State

    /// Optional time slot filter - when set, auto-scrolls to that section
    var selectedTimeSlotFilter: TimeSlot?

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
    /// Parent-pushed master content. Stored locally and used as the source for
    /// `computeHabits` on the next user-data refresh (or immediately if user
    /// data is already loaded).
    case contentUpdated(duas: [Dua], journeyDuas: [JourneyDua])
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

    // Time slot filtering (called by parent when navigating with time slot)
    case filterByTimeSlot(TimeSlot?)
    case clearTimeSlotFilter
  }

  @Dependency(\.continuousClock) var clock
  @Dependency(HapticClient.self) var haptics
  @Dependency(SoundClient.self) var sound
  @Dependency(\.adkharService) var adkharService
  @Dependency(\.userHabitsClient) var userHabitsClient

  var body: some ReducerOf<Self> {
    Reduce { state, action in
      switch action {
      case .onAppear, .refreshData:
        state.isLoading = true
        state.loadError = nil

        // Pre-warm audio so the first counter tap has no decode latency.
        sound.prepare()

        // Capture content snapshot for use inside the effect (state isn't
        // accessible after we leave the reducer body).
        let allDuas = state.availableDuas
        let allJourneyDuas = state.availableJourneyDuas

        return .run { [adkharService, userHabitsClient] send in
          do {
            // User-data: subscribed journeys + custom habits (local, fast).
            async let activeJourneyIdsTask = adkharService.getActiveJourneyIds()
            async let customHabitsTask = adkharService.getCustomHabits()
            let activeJourneyIds = try await activeJourneyIdsTask
            let customHabits = try await customHabitsTask

            // Pure transformation — no network, no timeout, no fallback.
            let habits = adkharService.computeHabits(
              activeJourneyIds,
              allDuas,
              allJourneyDuas,
              customHabits
            )
            await send(.habitsLoaded(
              morning: habits.morning,
              anytime: habits.anytime,
              evening: habits.evening
            ))

            // Cloud user-data: streak + today's completions (requires auth).
            if let userId = adkharService.currentUserId() {
              let streak = try await adkharService.fetchStreak(userId)
              await send(.streakLoaded(streak))

              let completedIds = try await adkharService.fetchTodayCompletions(userId)
              if !completedIds.isEmpty {
                await send(.completionsRestored(completedIds))
                do {
                  try await userHabitsClient.syncCompletionsFromCloud(completedIds)
                } catch {
                  adkharLogger.error("📱 Failed to sync cloud completions: \(error.localizedDescription, privacy: .public)")
                }
              }
            } else {
              await send(.streakLoaded(0))
            }
          } catch {
            adkharLogger.error("📱 Error loading habits: \(error.localizedDescription, privacy: .public)")
            await send(.loadFailed(error.localizedDescription))
          }
        }

      case let .contentUpdated(duas, journeyDuas):
        // Cache the latest master content and trigger an immediate recompute.
        // The recompute is cheap (pure local transformation) and ensures users
        // who landed on Adkhar before content arrived see habits the moment
        // ContentFeature settles.
        state.availableDuas = duas
        state.availableJourneyDuas = journeyDuas
        return .send(.refreshData)

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
        let duaId = habit.duaId

        return .run { [adkharService, userHabitsClient] _ in
          // Update widget with current progress
          WidgetDataManager.shared.updateDailyProgress(
            completedCount: completedCount,
            totalCount: totalCount,
            streak: streak,
            currentXp: 0,
            xpToNextLevel: 100,
            level: 1
          )

          // Persist completion to local storage (fast, offline-safe cache)
          do {
            _ = try await userHabitsClient.completeHabit(String(duaId), xpEarned)
            adkharLogger.info("Cached completion locally: dua \(duaId, privacy: .public)")
          } catch {
            adkharLogger.error("Failed to cache completion locally: \(error.localizedDescription, privacy: .public)")
          }

          // Persist completion to Firestore (cloud source of truth)
          guard let userId = adkharService.currentUserId() else { return }

          do {
            try await adkharService.recordCompletion(userId, duaId, xpEarned)
            adkharLogger.info("Recorded completion to Firestore: dua \(duaId, privacy: .public), xp: \(xpEarned, privacy: .public)")
          } catch {
            adkharLogger.error("Error recording completion to Firestore: \(error.localizedDescription, privacy: .public)")
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

          return .run { [clock, haptics, sound] send in
            // Audio + haptic land together with the toast appearing
            sound.completion()
            haptics.counterComplete()
            do {
              try await clock.sleep(for: .milliseconds(300))
            } catch {
              // Sleep cancelled - continue with celebration
            }
            haptics.celebration()
            await send(.habitCompleted(habit))
            do {
              try await clock.sleep(for: .milliseconds(900))
            } catch {
              // Sleep cancelled - still finish celebration
            }
            await send(.celebrationFinished)
          }
        }

        // Tap feedback: haptic + soft bead sound
        return .run { [haptics, sound] _ in
          haptics.counterIncrement()
          sound.beadTap()
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
        // Handled by parent AppFeature.
        return .none

      case .becameActive:
        // Refresh when tab becomes active to pick up any journey subscription
        // changes the user made in another tab.
        return .send(.refreshData)

      case .filterByTimeSlot(let timeSlot):
        // Set the filter - the view will respond by scrolling to this section.
        state.selectedTimeSlotFilter = timeSlot
        return .none

      case .clearTimeSlotFilter:
        state.selectedTimeSlotFilter = nil
        return .none
      }
    }
  }
}

// MARK: - Habit Model
struct Habit: Equatable, Identifiable, Hashable {
  let id: Int
  let duaId: Int
  let categoryId: Int?
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

/// Dependency client for habit-related operations.
///
/// Habit construction is now a **pure transformation** over pre-fetched master
/// content (duas + journey-dua mappings) and user-data (active journey IDs +
/// custom habits). Callers fetch content via ContentFeature/cachedContentClient
/// and user-data via this client + habitStorage, then call `computeHabits` to
/// assemble the habit lists.
struct AdkharServiceClient: Sendable {
  /// Pure transformation: combines master content + user-data into time-slotted
  /// habit lists. No I/O, no errors. Replaces the prior `fetchAllHabits` which
  /// did its own content fetching, timeout, and SampleData fallback (now
  /// redundant because CachedContentClient handles offline resilience and
  /// content is owned by ContentFeature).
  var computeHabits: @Sendable (
    _ activeJourneyIds: [Int],
    _ allDuas: [Dua],
    _ allJourneyDuas: [JourneyDua],
    _ customHabits: [CustomHabit]
  ) -> (morning: [Habit], anytime: [Habit], evening: [Habit])

  /// Fetches the user's current streak
  var fetchStreak: @Sendable (String) async throws -> Int
  /// Records a dua completion and awards XP
  var recordCompletion: @Sendable (String, Int, Int) async throws -> Void
  /// Fetches today's completed dua IDs for restoring state
  var fetchTodayCompletions: @Sendable (String) async throws -> Set<Int>
  /// Gets active journey IDs from local storage
  var getActiveJourneyIds: @Sendable () async throws -> [Int]
  /// Gets user-added custom habits from local storage
  var getCustomHabits: @Sendable () async throws -> [CustomHabit]
  /// Gets the current authenticated user's ID (nil if not signed in)
  var currentUserId: @Sendable () -> String?
}

extension AdkharServiceClient: DependencyKey {
  static let liveValue: AdkharServiceClient = {
    let firestoreService = FirestoreService()
    let habitStorage = ServiceContainer.shared.habitStorage

    return AdkharServiceClient(
      computeHabits: { activeJourneyIds, allDuas, allJourneyDuas, customHabits in
        computeHabitsImpl(
          activeJourneyIds: activeJourneyIds,
          allDuas: allDuas,
          allJourneyDuas: allJourneyDuas,
          customHabits: customHabits
        )
      },

      fetchStreak: { userId in
        let profile = try await firestoreService.fetchUserProfile(userId: userId)
        return profile?.streak ?? 0
      },

      recordCompletion: { userId, duaId, xpEarned in
        // Updates user_activity, user_progress, AND user_profiles.totalXp so
        // completions reflect on Home and XP is properly awarded.
        _ = try await firestoreService.recordPracticeCompletion(
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

      getCustomHabits: {
        try await habitStorage.getCustomHabits()
      },

      currentUserId: {
        Auth.auth().currentUser?.uid
      }
    )
  }()

  static let testValue = AdkharServiceClient(
    computeHabits: { _, _, _, _ in ([], [], []) },
    fetchStreak: { _ in 7 },
    recordCompletion: { _, _, _ in },
    fetchTodayCompletions: { _ in [] },
    getActiveJourneyIds: { [] },
    getCustomHabits: { [] },
    currentUserId: { "test-user-id" }
  )

  static let previewValue = AdkharServiceClient(
    computeHabits: { _, _, _, _ in
      let morning = [
        Habit(
          id: 1, duaId: 1, categoryId: 1, titleEn: "Morning Remembrance",
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
          id: 2, duaId: 2, categoryId: 2, titleEn: "Evening Protection",
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
    fetchStreak: { _ in 7 },
    recordCompletion: { _, _, _ in },
    fetchTodayCompletions: { _ in [] },
    getActiveJourneyIds: { [1, 2] },
    getCustomHabits: { [] },
    currentUserId: { "preview-user-id" }
  )
}

// MARK: - Pure Habit Computation
//
// Extracted from the legacy `fetchAllHabits` closure so it can be unit-tested
// and reused by both AdkharFeature and HomeFeature without re-fetching master
// content. Assumes inputs are already loaded — caller is responsible for
// supplying `allDuas` / `allJourneyDuas` via ContentFeature and the user-data
// arrays via habitStorage.

private func computeHabitsImpl(
  activeJourneyIds: [Int],
  allDuas: [Dua],
  allJourneyDuas: [JourneyDua],
  customHabits: [CustomHabit]
) -> (morning: [Habit], anytime: [Habit], evening: [Habit]) {
  let duasById = Dictionary(uniqueKeysWithValues: allDuas.map { ($0.id, $0) })
  let activeJourneySet = Set(activeJourneyIds)

  var morning: [Habit] = []
  var anytime: [Habit] = []
  var evening: [Habit] = []

  // Journey habits: walk every mapping, keep only those in subscribed journeys.
  for mapping in allJourneyDuas where activeJourneySet.contains(mapping.journeyId) {
    guard let dua = duasById[mapping.duaId] else { continue }
    let habit = Habit(
      id: dua.id,
      duaId: dua.id,
      categoryId: dua.categoryId,
      titleEn: dua.titleEn,
      arabicText: dua.arabicText,
      transliteration: dua.transliteration,
      translation: dua.translationEn,
      source: dua.source,
      rizqBenefit: dua.rizqBenefit,
      propheticContext: dua.propheticContext,
      timeSlot: mapping.timeSlot,
      xpValue: dua.xpValue,
      repetitions: dua.repetitions
    )
    switch mapping.timeSlot {
    case .morning: morning.append(habit)
    case .anytime: anytime.append(habit)
    case .evening: evening.append(habit)
    }
  }

  // Custom habits: same shape but timeSlot comes from the custom record.
  for customHabit in customHabits {
    guard let dua = duasById[customHabit.duaId] else { continue }
    let habit = Habit(
      id: dua.id,
      duaId: dua.id,
      categoryId: dua.categoryId,
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

  // De-dupe (a dua may appear in multiple subscribed journeys) + stable sort.
  return (
    morning: Array(Set(morning)).sorted { $0.id < $1.id },
    anytime: Array(Set(anytime)).sorted { $0.id < $1.id },
    evening: Array(Set(evening)).sorted { $0.id < $1.id }
  )
}

extension DependencyValues {
  var adkharService: AdkharServiceClient {
    get { self[AdkharServiceClient.self] }
    set { self[AdkharServiceClient.self] = newValue }
  }
}
