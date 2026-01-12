import Foundation

// MARK: - Daily Activity Item
//
// Design Decisions:
// - Extracted to RIZQKit for sharing across WeekCalendarView, WeeklyTrackerView, and HomeFeature
// - Uses Sendable conformance for TCA compatibility
// - Factory method creates week items from UserActivity array
// - Testable with injected Calendar for deterministic tests
// - Array extensions provide computed properties for common operations
//
// Related Files:
// - WeekCalendarView.swift (original location, now imports this)
// - WeeklyTrackerView.swift (consumer)
// - HomeFeature.swift (state management)
// - User.swift (UserActivity model)
// - RIZQTests.swift (unit tests)

/// Model for a single day's activity in the week calendar/tracker
public struct DailyActivityItem: Equatable, Identifiable, Sendable {
  public let id: String
  public let date: Date
  public let dayLabel: String
  public let isToday: Bool
  public let completed: Bool
  public let xpEarned: Int

  public init(date: Date, completed: Bool = false, xpEarned: Int = 0, calendar: Calendar = .current) {
    self.id = ISO8601DateFormatter().string(from: date)
    self.date = date
    self.dayLabel = Self.dayLabel(for: date)
    self.isToday = calendar.isDateInToday(date)
    self.completed = completed
    self.xpEarned = xpEarned
  }

  // MARK: - Factory Methods

  /// Creates a week of activity items from UserActivity array
  /// - Parameters:
  ///   - activities: User's activity records
  ///   - calendar: Calendar for date calculations (injectable for testing)
  /// - Returns: Array of 7 DailyActivityItem for the current week
  public static func weekItems(
    from activities: [UserActivity],
    calendar: Calendar = .current
  ) -> [DailyActivityItem] {
    var items: [DailyActivityItem] = []

    for daysAgo in (0..<7).reversed() {
      guard let date = calendar.date(byAdding: .day, value: -daysAgo, to: Date()) else {
        continue
      }

      let dayStart = calendar.startOfDay(for: date)
      let activity = activities.first {
        calendar.isDate($0.date, inSameDayAs: dayStart)
      }

      let hasCompletedDuas = activity.map { !$0.duasCompleted.isEmpty } ?? false

      items.append(DailyActivityItem(
        date: date,
        completed: hasCompletedDuas,
        xpEarned: activity?.xpEarned ?? 0,
        calendar: calendar
      ))
    }

    return items
  }

  /// Creates mock week items for previews and testing
  /// - Parameters:
  ///   - completedDays: Set of days ago that are completed (0 = today, 6 = 6 days ago)
  ///   - xpPerDay: XP earned on completed days
  /// - Returns: Array of 7 DailyActivityItem
  public static func mockWeek(
    completedDays: Set<Int> = [0, 2, 3, 5],
    xpPerDay: Int = 100
  ) -> [DailyActivityItem] {
    (0..<7).reversed().map { daysAgo in
      let date = Calendar.current.date(byAdding: .day, value: -daysAgo, to: Date()) ?? Date()
      let dayIndex = 6 - daysAgo
      let completed = completedDays.contains(dayIndex)
      return DailyActivityItem(
        date: date,
        completed: completed,
        xpEarned: completed ? xpPerDay : 0
      )
    }
  }

  // MARK: - Helpers

  private static let dayLabelFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateFormat = "EEEEE"  // Single letter day (S, M, T, W, T, F, S)
    return formatter
  }()

  private static func dayLabel(for date: Date) -> String {
    dayLabelFormatter.string(from: date)
  }
}

// MARK: - Week Summary

public extension Array where Element == DailyActivityItem {
  /// Number of completed days in this week
  var completedCount: Int {
    filter { $0.completed }.count
  }

  /// Total XP earned this week
  var totalXpEarned: Int {
    reduce(0) { $0 + $1.xpEarned }
  }

  /// Whether all 7 days are completed (perfect week)
  var isPerfectWeek: Bool {
    completedCount == 7
  }

  /// Current streak from most recent day backwards
  var currentStreak: Int {
    var streak = 0
    for item in reversed() {
      if item.completed {
        streak += 1
      } else if !item.isToday {
        break
      }
    }
    return streak
  }
}
