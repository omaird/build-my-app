import Foundation
import WidgetKit

/// Manages shared data between the main app and widget extensions via App Group
/// Both the main app and widgets use this to read/write shared state
public final class WidgetDataManager: @unchecked Sendable {
  public static let shared = WidgetDataManager()

  // MARK: - App Group Configuration

  /// The App Group identifier - must match capability in both app and widget targets
  public static let appGroupIdentifier = "group.com.rizq.app"

  private var sharedDefaults: UserDefaults? {
    UserDefaults(suiteName: Self.appGroupIdentifier)
  }

  // MARK: - Keys

  private enum Keys {
    static let completedCount = "widget_completed_count"
    static let totalCount = "widget_total_count"
    static let streak = "widget_streak"
    static let bestStreak = "widget_best_streak"
    static let currentXp = "widget_current_xp"
    static let xpToNextLevel = "widget_xp_to_next_level"
    static let level = "widget_level"
    static let totalDuasCompleted = "widget_total_duas"
    static let lastUpdated = "widget_last_updated"
  }

  private init() {}

  // MARK: - Write Methods (Called from main app)

  /// Updates the widget data from the main app
  /// Call this whenever habit completion state changes
  public func updateDailyProgress(
    completedCount: Int,
    totalCount: Int,
    streak: Int,
    currentXp: Int,
    xpToNextLevel: Int,
    level: Int
  ) {
    guard let defaults = sharedDefaults else {
      print("⚠️ WidgetDataManager: Could not access App Group UserDefaults")
      return
    }

    defaults.set(completedCount, forKey: Keys.completedCount)
    defaults.set(totalCount, forKey: Keys.totalCount)
    defaults.set(streak, forKey: Keys.streak)
    defaults.set(currentXp, forKey: Keys.currentXp)
    defaults.set(xpToNextLevel, forKey: Keys.xpToNextLevel)
    defaults.set(level, forKey: Keys.level)
    defaults.set(Date(), forKey: Keys.lastUpdated)

    // Synchronize to ensure data is written immediately
    defaults.synchronize()

    // Request widget refresh
    reloadWidgets()
  }

  /// Updates streak-specific data
  public func updateStreakData(streak: Int, bestStreak: Int, totalDuasCompleted: Int) {
    guard let defaults = sharedDefaults else { return }

    defaults.set(streak, forKey: Keys.streak)
    defaults.set(bestStreak, forKey: Keys.bestStreak)
    defaults.set(totalDuasCompleted, forKey: Keys.totalDuasCompleted)
    defaults.set(Date(), forKey: Keys.lastUpdated)
    defaults.synchronize()

    reloadWidgets()
  }

  // MARK: - Read Methods (Called from widget)

  /// Retrieves daily progress data for the widget
  public func getDailyProgressData() -> DailyProgressData {
    guard let defaults = sharedDefaults else {
      return .placeholder
    }

    return DailyProgressData(
      completedCount: defaults.integer(forKey: Keys.completedCount),
      totalCount: max(defaults.integer(forKey: Keys.totalCount), 1), // Avoid division by zero
      streak: defaults.integer(forKey: Keys.streak),
      currentXp: defaults.integer(forKey: Keys.currentXp),
      xpToNextLevel: max(defaults.integer(forKey: Keys.xpToNextLevel), 100),
      level: max(defaults.integer(forKey: Keys.level), 1),
      lastUpdated: defaults.object(forKey: Keys.lastUpdated) as? Date
    )
  }

  /// Retrieves streak data for the widget
  public func getStreakData() -> StreakData {
    guard let defaults = sharedDefaults else {
      return .placeholder
    }

    return StreakData(
      streak: defaults.integer(forKey: Keys.streak),
      bestStreak: defaults.integer(forKey: Keys.bestStreak),
      totalDuasCompleted: defaults.integer(forKey: Keys.totalDuasCompleted)
    )
  }

  // MARK: - Widget Refresh

  /// Requests all RIZQ widgets to refresh their timelines
  public func reloadWidgets() {
    WidgetCenter.shared.reloadTimelines(ofKind: "DailyProgressWidget")
    WidgetCenter.shared.reloadTimelines(ofKind: "StreakWidget")
  }

  /// Reloads all widget timelines
  public func reloadAllWidgets() {
    WidgetCenter.shared.reloadAllTimelines()
  }
}

// MARK: - Data Structures

public struct DailyProgressData: Sendable {
  public let completedCount: Int
  public let totalCount: Int
  public let streak: Int
  public let currentXp: Int
  public let xpToNextLevel: Int
  public let level: Int
  public let lastUpdated: Date?

  public var progress: Double {
    guard totalCount > 0 else { return 0 }
    return Double(completedCount) / Double(totalCount)
  }

  public static var placeholder: DailyProgressData {
    DailyProgressData(
      completedCount: 4,
      totalCount: 7,
      streak: 12,
      currentXp: 450,
      xpToNextLevel: 600,
      level: 5,
      lastUpdated: nil
    )
  }
}

public struct StreakData: Sendable {
  public let streak: Int
  public let bestStreak: Int
  public let totalDuasCompleted: Int

  public static var placeholder: StreakData {
    StreakData(streak: 12, bestStreak: 45, totalDuasCompleted: 342)
  }
}
