import Foundation

// MARK: - Habit Storage Protocol

/// Protocol for habit storage operations
public protocol HabitStorageProtocol: Sendable {
  // Storage operations
  func loadStorage() async throws -> UserHabitsStorage
  func saveStorage(_ storage: UserHabitsStorage) async throws

  // Journey management
  func getActiveJourneyIds() async throws -> [Int]
  func setActiveJourneyIds(_ ids: [Int]) async throws
  func addJourney(_ journeyId: Int) async throws
  func removeJourney(_ journeyId: Int) async throws
  func isJourneyActive(_ journeyId: Int) async throws -> Bool

  // Custom habits
  func getCustomHabits() async throws -> [CustomHabit]
  func addCustomHabit(_ habit: CustomHabit) async throws
  func removeCustomHabit(_ habitId: String) async throws

  // Completions
  func getCompletionsForDate(_ date: String) async throws -> [HabitCompletion]
  func getCompletionsForToday() async throws -> [HabitCompletion]
  func isCompletedToday(_ habitId: String) async throws -> Bool
  func completeHabit(_ habitId: String, xpEarned: Int) async throws -> HabitCompletion
  func uncompleteHabit(_ habitId: String, date: String) async throws

  // Cleanup
  func clearOldCompletions(keepDays: Int) async throws -> Int
  func clearAllData() async throws
}

// MARK: - Habit Storage

/// Actor-based service for thread-safe habit persistence
/// Matches the web app's localStorage patterns in useUserHabits.ts
public actor HabitStorage: HabitStorageProtocol {

  // MARK: - Properties

  private let defaults: UserDefaultsService
  private let storageKey: StorageKey = .userHabits

  private let dateFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateFormat = "yyyy-MM-dd"
    formatter.timeZone = TimeZone.current
    return formatter
  }()

  // MARK: - Singleton

  public static let shared = HabitStorage()

  // MARK: - Initialization

  public init(defaults: UserDefaultsService = .shared) {
    self.defaults = defaults
  }

  // MARK: - Date Helpers

  /// Get today's date as YYYY-MM-DD string (matches web app getToday())
  public func todayDateString() -> String {
    dateFormatter.string(from: Date())
  }

  /// Parse a date string to Date
  public func parseDate(_ dateString: String) -> Date? {
    dateFormatter.date(from: dateString)
  }

  // MARK: - Storage Operations

  public func loadStorage() async throws -> UserHabitsStorage {
    do {
      if let storage = try await defaults.get(UserHabitsStorage.self, forKey: storageKey) {
        return storage
      }
    } catch {
      // If decoding fails, return default storage
      print("HabitStorage: Failed to decode storage, returning default: \(error)")
    }

    // Default: empty storage (web app defaults to journey 1 active)
    return UserHabitsStorage(
      activeJourneyIds: [],
      customHabits: [],
      habitCompletions: []
    )
  }

  public func saveStorage(_ storage: UserHabitsStorage) async throws {
    try await defaults.set(storage, forKey: storageKey)
  }

  // MARK: - Journey Management

  public func getActiveJourneyIds() async throws -> [Int] {
    try await loadStorage().activeJourneyIds
  }

  public func setActiveJourneyIds(_ ids: [Int]) async throws {
    var storage = try await loadStorage()
    storage.activeJourneyIds = ids
    try await saveStorage(storage)
  }

  public func addJourney(_ journeyId: Int) async throws {
    var storage = try await loadStorage()
    guard !storage.activeJourneyIds.contains(journeyId) else { return }
    storage.activeJourneyIds.append(journeyId)
    try await saveStorage(storage)
  }

  public func removeJourney(_ journeyId: Int) async throws {
    var storage = try await loadStorage()
    storage.activeJourneyIds.removeAll { $0 == journeyId }
    try await saveStorage(storage)
  }

  public func isJourneyActive(_ journeyId: Int) async throws -> Bool {
    try await loadStorage().activeJourneyIds.contains(journeyId)
  }

  // MARK: - Custom Habits

  public func getCustomHabits() async throws -> [CustomHabit] {
    try await loadStorage().customHabits
  }

  public func addCustomHabit(_ habit: CustomHabit) async throws {
    var storage = try await loadStorage()
    // Prevent duplicates
    guard !storage.customHabits.contains(where: { $0.id == habit.id }) else { return }
    storage.customHabits.append(habit)
    try await saveStorage(storage)
  }

  public func removeCustomHabit(_ habitId: String) async throws {
    var storage = try await loadStorage()
    storage.customHabits.removeAll { $0.id == habitId }
    try await saveStorage(storage)
  }

  // MARK: - Completions

  public func getCompletionsForDate(_ date: String) async throws -> [HabitCompletion] {
    try await loadStorage().habitCompletions.filter { $0.date == date }
  }

  public func getCompletionsForToday() async throws -> [HabitCompletion] {
    let today = todayDateString()
    return try await getCompletionsForDate(today)
  }

  public func isCompletedToday(_ habitId: String) async throws -> Bool {
    let today = todayDateString()
    return try await loadStorage().habitCompletions.contains { completion in
      completion.habitId == habitId && completion.date == today
    }
  }

  /// Complete a habit and return the completion record
  /// Idempotent: returns existing completion if already completed today
  public func completeHabit(_ habitId: String, xpEarned: Int) async throws -> HabitCompletion {
    let today = todayDateString()
    var storage = try await loadStorage()

    // Check if already completed today (idempotency)
    if let existing = storage.habitCompletions.first(where: {
      $0.habitId == habitId && $0.date == today
    }) {
      return existing
    }

    // Create new completion
    let completion = HabitCompletion(
      habitId: habitId,
      date: today,
      completedAt: Date(),
      xpEarned: xpEarned
    )

    storage.habitCompletions.append(completion)
    try await saveStorage(storage)

    return completion
  }

  public func uncompleteHabit(_ habitId: String, date: String) async throws {
    var storage = try await loadStorage()
    storage.habitCompletions.removeAll { completion in
      completion.habitId == habitId && completion.date == date
    }
    try await saveStorage(storage)
  }

  // MARK: - Cleanup

  /// Remove completions older than specified days
  /// Returns the number of completions removed
  public func clearOldCompletions(keepDays: Int = 30) async throws -> Int {
    var storage = try await loadStorage()
    let originalCount = storage.habitCompletions.count

    // Calculate cutoff date
    guard let cutoffDate = Calendar.current.date(byAdding: .day, value: -keepDays, to: Date()) else {
      return 0
    }
    let cutoffDateString = dateFormatter.string(from: cutoffDate)

    // Filter to keep only recent completions
    storage.habitCompletions = storage.habitCompletions.filter { completion in
      completion.date >= cutoffDateString
    }

    try await saveStorage(storage)
    return originalCount - storage.habitCompletions.count
  }

  public func clearAllData() async throws {
    try await saveStorage(UserHabitsStorage())
  }

  // MARK: - Statistics

  /// Get today's progress statistics
  public func getTodayProgress(totalHabits: Int) async throws -> TodayProgress {
    let completions = try await getCompletionsForToday()
    let xpEarned = completions.reduce(0) { $0 + $1.xpEarned }

    return TodayProgress(
      completed: completions.count,
      total: totalHabits,
      xpEarned: xpEarned
    )
  }

  /// Get completed habit IDs for today
  public func getCompletedHabitIdsForToday() async throws -> Set<String> {
    let completions = try await getCompletionsForToday()
    return Set(completions.map { $0.habitId })
  }

  /// Get completion history for the last N days
  public func getCompletionHistory(days: Int) async throws -> [String: [HabitCompletion]] {
    var history: [String: [HabitCompletion]] = [:]
    let storage = try await loadStorage()

    // Calculate date range
    let today = Date()
    for dayOffset in 0..<days {
      guard let date = Calendar.current.date(byAdding: .day, value: -dayOffset, to: today) else {
        continue
      }
      let dateString = dateFormatter.string(from: date)
      let completions = storage.habitCompletions.filter { $0.date == dateString }
      history[dateString] = completions
    }

    return history
  }

  /// Calculate streak (consecutive days with completions)
  public func calculateStreak() async throws -> Int {
    let storage = try await loadStorage()

    // Get unique dates with completions, sorted descending
    let completionDates = Set(storage.habitCompletions.map { $0.date })
      .sorted(by: >)

    guard !completionDates.isEmpty else { return 0 }

    var streak = 0
    let currentDate = Date()

    // Check each day going backwards
    for dayOffset in 0..<365 {
      guard let checkDate = Calendar.current.date(byAdding: .day, value: -dayOffset, to: currentDate) else {
        break
      }
      let dateString = dateFormatter.string(from: checkDate)

      if completionDates.contains(dateString) {
        streak += 1
      } else if dayOffset > 0 {
        // Allow missing today, but break on any other missing day
        break
      }
    }

    return streak
  }
}

// MARK: - Mock Implementation

/// Mock implementation for testing and previews
public actor MockHabitStorage: HabitStorageProtocol {
  private var storage: UserHabitsStorage

  public init(storage: UserHabitsStorage = UserHabitsStorage()) {
    self.storage = storage
  }

  public func loadStorage() -> UserHabitsStorage {
    storage
  }

  public func saveStorage(_ newStorage: UserHabitsStorage) {
    storage = newStorage
  }

  public func getActiveJourneyIds() -> [Int] {
    storage.activeJourneyIds
  }

  public func setActiveJourneyIds(_ ids: [Int]) {
    storage.activeJourneyIds = ids
  }

  public func addJourney(_ journeyId: Int) {
    if !storage.activeJourneyIds.contains(journeyId) {
      storage.activeJourneyIds.append(journeyId)
    }
  }

  public func removeJourney(_ journeyId: Int) {
    storage.activeJourneyIds.removeAll { $0 == journeyId }
  }

  public func isJourneyActive(_ journeyId: Int) -> Bool {
    storage.activeJourneyIds.contains(journeyId)
  }

  public func getCustomHabits() -> [CustomHabit] {
    storage.customHabits
  }

  public func addCustomHabit(_ habit: CustomHabit) {
    if !storage.customHabits.contains(where: { $0.id == habit.id }) {
      storage.customHabits.append(habit)
    }
  }

  public func removeCustomHabit(_ habitId: String) {
    storage.customHabits.removeAll { $0.id == habitId }
  }

  private func todayDateString() -> String {
    let formatter = DateFormatter()
    formatter.dateFormat = "yyyy-MM-dd"
    return formatter.string(from: Date())
  }

  public func getCompletionsForDate(_ date: String) -> [HabitCompletion] {
    storage.habitCompletions.filter { $0.date == date }
  }

  public func getCompletionsForToday() -> [HabitCompletion] {
    getCompletionsForDate(todayDateString())
  }

  public func isCompletedToday(_ habitId: String) -> Bool {
    let today = todayDateString()
    return storage.habitCompletions.contains { $0.habitId == habitId && $0.date == today }
  }

  public func completeHabit(_ habitId: String, xpEarned: Int) -> HabitCompletion {
    let today = todayDateString()

    if let existing = storage.habitCompletions.first(where: {
      $0.habitId == habitId && $0.date == today
    }) {
      return existing
    }

    let completion = HabitCompletion(
      habitId: habitId,
      date: today,
      completedAt: Date(),
      xpEarned: xpEarned
    )
    storage.habitCompletions.append(completion)
    return completion
  }

  public func uncompleteHabit(_ habitId: String, date: String) {
    storage.habitCompletions.removeAll { $0.habitId == habitId && $0.date == date }
  }

  public func clearOldCompletions(keepDays: Int) -> Int {
    0 // No-op for mock
  }

  public func clearAllData() {
    storage = UserHabitsStorage()
  }
}
