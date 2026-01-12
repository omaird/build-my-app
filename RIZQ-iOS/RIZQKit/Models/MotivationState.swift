import SwiftUI

// MARK: - Motivation State Model
//
// Design Decisions:
// - Extracted from MotivationalProgressView for separation of concerns
// - Computed from habit data - TCA reducers can create and pass to views
// - All display properties pre-computed for "dumb" view rendering
// - Sendable for TCA state compatibility
//
// Related Files:
// - MotivationalProgressView.swift (primary consumer)
// - HomeFeature.swift (state computation)
// - RIZQWidget (potential future use)
// - RIZQTests.swift (MotivationStateTests - 16 unit tests)
//
// Usage in TCA:
// ```swift
// struct State {
//   var motivationState: MotivationState
// }
// case .habitsUpdated:
//   state.motivationState = MotivationState(
//     habitsCompleted: state.completedCount,
//     totalHabits: state.totalHabits
//   )
// ```

/// Represents the user's daily progress state for motivational display.
/// Computed from habit completion data, providing all display properties.
public enum MotivationState: Equatable, Sendable {
  case noHabits
  case notStarted
  case lightDay(habitsCompleted: Int)
  case productiveDay
  case perfectDay

  // MARK: - Factory Initializer

  /// Create motivation state from habit completion data
  public init(habitsCompleted: Int, totalHabits: Int) {
    guard totalHabits > 0 else {
      self = .noHabits
      return
    }

    let percentage = Double(habitsCompleted) / Double(totalHabits)
    if percentage == 0 {
      self = .notStarted
    } else if percentage < 0.5 {
      self = .lightDay(habitsCompleted: habitsCompleted)
    } else if percentage < 1.0 {
      self = .productiveDay
    } else {
      self = .perfectDay
    }
  }

  // MARK: - Display Properties

  /// Primary motivational title
  public var title: String {
    switch self {
    case .noHabits: return "Start Your Journey"
    case .notStarted: return "Ready to Begin"
    case .lightDay: return "Light Day"
    case .productiveDay: return "Making Progress"
    case .perfectDay: return "Perfect Day!"
    }
  }

  /// Contextual message based on state and streak
  public func message(streak: Int) -> String {
    switch self {
    case .noHabits:
      return "Subscribe to a journey to start building your daily practice."
    case .notStarted:
      if streak > 0 {
        return "You have a \(streak)-day streak going! Don't break the chain."
      }
      return "Your habits are waiting. Start your day with remembrance."
    case .lightDay(let habitsCompleted):
      let habitWord = habitsCompleted == 1 ? "habit" : "habits"
      return "You've planted \(habitsCompleted) \(habitWord) today. Each small step strengthens your practice."
    case .productiveDay:
      return "Great momentum! You're more than halfway through your daily practice."
    case .perfectDay:
      // Tease tomorrow's streak to create return hook
      let nextStreak = streak + 1
      if streak >= 29 {
        // Approaching or at month milestone
        return "MashaAllah! You've completed all your habits. Tomorrow marks day \(nextStreak) — keep the blessing flowing!"
      } else if streak >= 6 {
        // Approaching week milestone
        return "MashaAllah! You've completed all your habits. Return tomorrow to reach day \(nextStreak)!"
      } else {
        // Building early momentum
        return "MashaAllah! You've completed all your habits today. Come back tomorrow to grow your streak!"
      }
    }
  }

  /// Call-to-action button text (empty string means no action shown)
  public var actionText: String {
    switch self {
    case .noHabits: return "Browse Journeys"
    case .notStarted: return "Start First Habit"
    case .lightDay: return "Continue Practice"
    case .productiveDay: return "Almost There!"
    case .perfectDay: return ""  // No action needed on perfect day
    }
  }

  /// Whether an action button should be shown
  public var hasAction: Bool {
    !actionText.isEmpty
  }

  /// SF Symbol icon name for the state
  public var iconName: String {
    switch self {
    case .noHabits: return "leaf"
    case .notStarted: return "sunrise"
    case .lightDay: return "leaf.fill"
    case .productiveDay: return "flame"
    case .perfectDay: return "checkmark.seal.fill"
    }
  }

  /// Color name for glow effect (maps to RIZQColors)
  public var glowColorName: String {
    switch self {
    case .noHabits: return "rizqMuted"
    case .notStarted: return "goldSoft"
    case .lightDay: return "goldBright"
    case .productiveDay: return "streakGlow"
    case .perfectDay: return "tealSuccess"
    }
  }

  /// SwiftUI Color for glow effect
  public var glowColor: Color {
    switch self {
    case .noHabits: return .rizqMuted
    case .notStarted: return .goldSoft
    case .lightDay: return .goldBright
    case .productiveDay: return .streakGlow
    case .perfectDay: return .tealSuccess
    }
  }
}

// MARK: - VoiceOver Support

public extension MotivationState {
  /// Accessibility description for VoiceOver
  func accessibilityDescription(streak: Int, nextAchievementName: String?) -> String {
    var desc = title + ". " + message(streak: streak)
    if let achievementName = nextAchievementName {
      desc += " Next achievement: \(achievementName)."
    }
    if hasAction {
      desc += " Action: \(actionText)."
    }
    return desc
  }
}
