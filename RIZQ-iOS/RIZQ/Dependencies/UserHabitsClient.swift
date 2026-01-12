import ComposableArchitecture
import Foundation
import RIZQKit

/// TCA dependency client for user habits operations
/// Wraps HabitStorage for easy testing and provides closures for habit management
/// NOTE: Using manual struct registration instead of @DependencyClient macro per CLAUDE.md guidelines
struct UserHabitsClient: Sendable {
  // MARK: - Storage

  var loadStorage: @Sendable () async throws -> UserHabitsStorage

  // MARK: - Journey Management

  var getActiveJourneyIds: @Sendable () async throws -> [Int]
  var addJourney: @Sendable (_ journeyId: Int) async throws -> Void
  var removeJourney: @Sendable (_ journeyId: Int) async throws -> Void
  var isJourneyActive: @Sendable (_ journeyId: Int) async throws -> Bool

  // MARK: - Custom Habits

  var getCustomHabits: @Sendable () async throws -> [CustomHabit]
  var addCustomHabit: @Sendable (_ duaId: Int, _ timeSlot: TimeSlot) async throws -> CustomHabit
  var removeCustomHabit: @Sendable (_ habitId: String) async throws -> Void

  // MARK: - Completions

  var getCompletionsForToday: @Sendable () async throws -> [HabitCompletion]
  var getCompletedHabitIdsForToday: @Sendable () async throws -> Set<String>
  var isCompletedToday: @Sendable (_ habitId: String) async throws -> Bool
  var completeHabit: @Sendable (_ habitId: String, _ xpEarned: Int) async throws -> HabitCompletion
  var uncompleteHabit: @Sendable (_ habitId: String) async throws -> Void

  // MARK: - Statistics

  var getTodayProgress: @Sendable (_ totalHabits: Int) async throws -> TodayProgress
  var calculateStreak: @Sendable () async throws -> Int

  // MARK: - Cleanup

  var clearOldCompletions: @Sendable (_ keepDays: Int) async throws -> Int
  var clearAllData: @Sendable () async throws -> Void
}

// MARK: - Dependency Key

extension UserHabitsClient: DependencyKey {
  static let liveValue: UserHabitsClient = {
    let storage = ServiceContainer.shared.habitStorage
    return UserHabitsClient(
      loadStorage: { try await storage.loadStorage() },
      getActiveJourneyIds: { try await storage.getActiveJourneyIds() },
      addJourney: { try await storage.addJourney($0) },
      removeJourney: { try await storage.removeJourney($0) },
      isJourneyActive: { try await storage.isJourneyActive($0) },
      getCustomHabits: { try await storage.getCustomHabits() },
      addCustomHabit: { duaId, timeSlot in
        let habit = CustomHabit(
          id: "custom-\(duaId)",
          duaId: duaId,
          timeSlot: timeSlot,
          addedAt: Date()
        )
        try await storage.addCustomHabit(habit)
        return habit
      },
      removeCustomHabit: { try await storage.removeCustomHabit($0) },
      getCompletionsForToday: { try await storage.getCompletionsForToday() },
      getCompletedHabitIdsForToday: { try await storage.getCompletedHabitIdsForToday() },
      isCompletedToday: { try await storage.isCompletedToday($0) },
      completeHabit: { try await storage.completeHabit($0, xpEarned: $1) },
      uncompleteHabit: { try await storage.uncompleteHabit($0, date: storage.todayDateString()) },
      getTodayProgress: { try await storage.getTodayProgress(totalHabits: $0) },
      calculateStreak: { try await storage.calculateStreak() },
      clearOldCompletions: { try await storage.clearOldCompletions(keepDays: $0) },
      clearAllData: { try await storage.clearAllData() }
    )
  }()

  static let previewValue: UserHabitsClient = {
    // Preview value with sample data
    return UserHabitsClient(
      loadStorage: { UserHabitsStorage(activeJourneyIds: [1, 2], customHabits: [], habitCompletions: []) },
      getActiveJourneyIds: { [1, 2] },
      addJourney: { _ in },
      removeJourney: { _ in },
      isJourneyActive: { $0 == 1 || $0 == 2 },
      getCustomHabits: { [] },
      addCustomHabit: { duaId, timeSlot in
        CustomHabit(id: "custom-\(duaId)", duaId: duaId, timeSlot: timeSlot, addedAt: Date())
      },
      removeCustomHabit: { _ in },
      getCompletionsForToday: { [] },
      getCompletedHabitIdsForToday: { [] },
      isCompletedToday: { _ in false },
      completeHabit: { habitId, xpEarned in
        HabitCompletion(habitId: habitId, date: "2024-01-01", completedAt: Date(), xpEarned: xpEarned)
      },
      uncompleteHabit: { _ in },
      getTodayProgress: { TodayProgress(completed: 0, total: $0, xpEarned: 0) },
      calculateStreak: { 7 },
      clearOldCompletions: { _ in 0 },
      clearAllData: { }
    )
  }()

  static let testValue = UserHabitsClient(
    loadStorage: { UserHabitsStorage() },
    getActiveJourneyIds: { [] },
    addJourney: { _ in },
    removeJourney: { _ in },
    isJourneyActive: { _ in false },
    getCustomHabits: { [] },
    addCustomHabit: { duaId, timeSlot in
      CustomHabit(id: "test-\(duaId)", duaId: duaId, timeSlot: timeSlot, addedAt: Date())
    },
    removeCustomHabit: { _ in },
    getCompletionsForToday: { [] },
    getCompletedHabitIdsForToday: { [] },
    isCompletedToday: { _ in false },
    completeHabit: { habitId, xpEarned in
      HabitCompletion(habitId: habitId, date: "2024-01-01", completedAt: Date(), xpEarned: xpEarned)
    },
    uncompleteHabit: { _ in },
    getTodayProgress: { TodayProgress(completed: 0, total: $0, xpEarned: 0) },
    calculateStreak: { 0 },
    clearOldCompletions: { _ in 0 },
    clearAllData: { }
  )
}

// MARK: - Dependency Values

extension DependencyValues {
  var userHabitsClient: UserHabitsClient {
    get { self[UserHabitsClient.self] }
    set { self[UserHabitsClient.self] = newValue }
  }
}
