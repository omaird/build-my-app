import ComposableArchitecture
import Foundation
import RIZQKit

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

    )
  }()

  static let testValue = AdkharServiceClient(
    computeHabits: { _, _, _, _ in ([], [], []) },
    fetchStreak: { _ in 7 },
    recordCompletion: { _, _, _ in },
    fetchTodayCompletions: { _ in [] },
    getActiveJourneyIds: { [] },
    getCustomHabits: { [] },
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
