import Foundation

// MARK: - User Habit

/// Represents a dua in the user's daily routine
public struct UserHabit: Identifiable, Equatable, Sendable {
  /// Unique ID format: "journey-{journeyId}-dua-{duaId}" or "custom-{customId}"
  public let id: String
  public let duaId: Int
  public let journeyId: Int?
  public let timeSlot: TimeSlot
  public let title: String
  public let arabicText: String
  public let transliteration: String?
  public let translation: String
  public let repetitions: Int
  public let xpValue: Int
  public let isCustom: Bool

  public init(
    id: String,
    duaId: Int,
    journeyId: Int?,
    timeSlot: TimeSlot,
    title: String,
    arabicText: String,
    transliteration: String?,
    translation: String,
    repetitions: Int,
    xpValue: Int,
    isCustom: Bool
  ) {
    self.id = id
    self.duaId = duaId
    self.journeyId = journeyId
    self.timeSlot = timeSlot
    self.title = title
    self.arabicText = arabicText
    self.transliteration = transliteration
    self.translation = translation
    self.repetitions = repetitions
    self.xpValue = xpValue
    self.isCustom = isCustom
  }

  /// Create a UserHabit from a Dua and Journey
  public static func from(dua: Dua, journeyId: Int, timeSlot: TimeSlot) -> UserHabit {
    UserHabit(
      id: "journey-\(journeyId)-dua-\(dua.id)",
      duaId: dua.id,
      journeyId: journeyId,
      timeSlot: timeSlot,
      title: dua.titleEn,
      arabicText: dua.arabicText,
      transliteration: dua.transliteration,
      translation: dua.translationEn,
      repetitions: dua.repetitions,
      xpValue: dua.xpValue,
      isCustom: false
    )
  }
}

// MARK: - Habit Completion

/// Record of a habit being completed
public struct HabitCompletion: Codable, Equatable, Sendable {
  public let habitId: String
  /// ISO date string YYYY-MM-DD
  public let date: String
  /// ISO timestamp
  public let completedAt: Date
  public let xpEarned: Int

  public init(habitId: String, date: String, completedAt: Date, xpEarned: Int) {
    self.habitId = habitId
    self.date = date
    self.completedAt = completedAt
    self.xpEarned = xpEarned
  }

  private enum CodingKeys: String, CodingKey {
    case habitId = "habit_id"
    case date
    case completedAt = "completed_at"
    case xpEarned = "xp_earned"
  }
}

// MARK: - Custom Habit

/// A habit added by the user (not from a journey)
public struct CustomHabit: Codable, Identifiable, Equatable, Sendable {
  public let id: String
  public let duaId: Int
  public let timeSlot: TimeSlot
  public let addedAt: Date

  public init(id: String, duaId: Int, timeSlot: TimeSlot, addedAt: Date = Date()) {
    self.id = id
    self.duaId = duaId
    self.timeSlot = timeSlot
    self.addedAt = addedAt
  }

  private enum CodingKeys: String, CodingKey {
    case id
    case duaId = "dua_id"
    case timeSlot = "time_slot"
    case addedAt = "added_at"
  }
}

// MARK: - User Habits Storage

/// Storage structure for user habits (persisted locally)
public struct UserHabitsStorage: Codable, Equatable, Sendable {
  public var activeJourneyIds: [Int]
  public var customHabits: [CustomHabit]
  public var habitCompletions: [HabitCompletion]

  public init(
    activeJourneyIds: [Int] = [],
    customHabits: [CustomHabit] = [],
    habitCompletions: [HabitCompletion] = []
  ) {
    self.activeJourneyIds = activeJourneyIds
    self.customHabits = customHabits
    self.habitCompletions = habitCompletions
  }

  private enum CodingKeys: String, CodingKey {
    case activeJourneyIds = "active_journey_ids"
    case customHabits = "custom_habits"
    case habitCompletions = "habit_completions"
  }

  /// Get completions for today
  public func completionsForToday() -> [HabitCompletion] {
    let today = Self.todayDateString()
    return habitCompletions.filter { $0.date == today }
  }

  /// Check if a habit is completed today
  public func isCompletedToday(habitId: String) -> Bool {
    let today = Self.todayDateString()
    return habitCompletions.contains { $0.habitId == habitId && $0.date == today }
  }

  /// Get today's date as YYYY-MM-DD string
  public static func todayDateString() -> String {
    let formatter = DateFormatter()
    formatter.dateFormat = "yyyy-MM-dd"
    return formatter.string(from: Date())
  }
}

// MARK: - Daily Activity

public struct DailyActivity: Equatable, Sendable {
  public let date: String
  public let completed: Bool
  public let duasCompleted: [Int]
  public let xpEarned: Int

  public init(date: String, completed: Bool, duasCompleted: [Int], xpEarned: Int) {
    self.date = date
    self.completed = completed
    self.duasCompleted = duasCompleted
    self.xpEarned = xpEarned
  }
}

// MARK: - Today's Progress

public struct TodayProgress: Equatable, Sendable {
  public let completed: Int
  public let total: Int
  public let percentage: Double
  public let xpEarned: Int

  public init(completed: Int, total: Int, xpEarned: Int) {
    self.completed = completed
    self.total = total
    self.percentage = total > 0 ? Double(completed) / Double(total) : 0
    self.xpEarned = xpEarned
  }
}

// MARK: - Time Slot Progress

public struct TimeSlotProgress: Equatable, Sendable {
  public let slot: TimeSlot
  public let completed: Int
  public let total: Int
  public let percentage: Double

  public init(slot: TimeSlot, completed: Int, total: Int) {
    self.slot = slot
    self.completed = completed
    self.total = total
    self.percentage = total > 0 ? Double(completed) / Double(total) : 0
  }
}
