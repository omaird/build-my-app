import Foundation

// MARK: - Achievement Model
//
// Design Decisions:
// - Uses String IDs for flexibility with future Firestore persistence
// - Emoji stored as String (not SF Symbol) for cross-platform consistency
// - unlockedAt is optional - nil means locked, Date means unlocked with timestamp
// - All types are Sendable for TCA compatibility
//
// Related Files:
// - AchievementBadgeView.swift (UI component)
// - HomeFeature.swift (state management)
// - RIZQTests.swift (unit tests)

/// Represents a gamification achievement/badge that users can unlock
/// through consistent practice and milestones.
public struct Achievement: Codable, Identifiable, Equatable, Sendable {
  public let id: String
  public let name: String
  public let description: String
  public let emoji: String
  public let category: AchievementCategory
  public let requirement: AchievementRequirement
  public let xpReward: Int
  public let unlockedAt: Date?

  /// Whether this achievement has been unlocked
  public var isUnlocked: Bool { unlockedAt != nil }

  /// VoiceOver accessibility description
  public var accessibilityDescription: String {
    if isUnlocked {
      return "\(name) achievement, unlocked. \(description). Worth \(xpReward) XP."
    } else {
      return "\(name) achievement, locked. \(description). Worth \(xpReward) XP when unlocked."
    }
  }

  public init(
    id: String,
    name: String,
    description: String,
    emoji: String,
    category: AchievementCategory,
    requirement: AchievementRequirement,
    xpReward: Int,
    unlockedAt: Date? = nil
  ) {
    self.id = id
    self.name = name
    self.description = description
    self.emoji = emoji
    self.category = category
    self.requirement = requirement
    self.xpReward = xpReward
    self.unlockedAt = unlockedAt
  }
}

// MARK: - Achievement Category

public enum AchievementCategory: String, Codable, CaseIterable, Sendable {
  case streak      // Consistency-based achievements
  case practice    // Practice count-based achievements
  case level       // Level milestone achievements
  case special     // Special occasion achievements

  /// Human-readable display name for the category
  public var displayName: String {
    switch self {
    case .streak: return "Consistency"
    case .practice: return "Practice"
    case .level: return "Milestone"
    case .special: return "Special"
    }
  }

  /// SF Symbol icon name for the category
  public var iconName: String {
    switch self {
    case .streak: return "flame.fill"
    case .practice: return "hands.clap.fill"
    case .level: return "star.fill"
    case .special: return "sparkles"
    }
  }

  /// Badge glow color for this category (used by AchievementBadgeView)
  /// Returns color name as string for SwiftUI Color extension lookup
  public var badgeColorName: String {
    switch self {
    case .streak: return "streakGlow"
    case .practice: return "tealSuccess"
    case .level: return "badgeEvening"
    case .special: return "goldBright"
    }
  }
}

// MARK: - Achievement Requirement

public struct AchievementRequirement: Codable, Equatable, Sendable {
  public let type: RequirementType
  public let value: Int

  public enum RequirementType: String, Codable, Sendable {
    case streakDays
    case totalDuas
    case levelReached
    case perfectWeek
  }

  public init(type: RequirementType, value: Int) {
    self.type = type
    self.value = value
  }
}

// MARK: - Achievement Progress (for TCA state calculations)

/// Holds current user stats needed to evaluate achievement progress
public struct AchievementEvaluationContext: Equatable, Sendable {
  public let currentStreak: Int
  public let totalDuasCompleted: Int
  public let currentLevel: Int
  public let perfectWeekCount: Int

  public init(
    currentStreak: Int = 0,
    totalDuasCompleted: Int = 0,
    currentLevel: Int = 1,
    perfectWeekCount: Int = 0
  ) {
    self.currentStreak = currentStreak
    self.totalDuasCompleted = totalDuasCompleted
    self.currentLevel = currentLevel
    self.perfectWeekCount = perfectWeekCount
  }
}

public extension Achievement {
  /// Calculate progress towards this achievement (0.0 to 1.0)
  func progress(with context: AchievementEvaluationContext) -> Double {
    guard !isUnlocked else { return 1.0 }

    let currentValue: Int
    switch requirement.type {
    case .streakDays:
      currentValue = context.currentStreak
    case .totalDuas:
      currentValue = context.totalDuasCompleted
    case .levelReached:
      currentValue = context.currentLevel
    case .perfectWeek:
      currentValue = context.perfectWeekCount
    }

    return min(1.0, Double(currentValue) / Double(requirement.value))
  }

  /// Check if achievement should be unlocked based on current stats
  func shouldUnlock(with context: AchievementEvaluationContext) -> Bool {
    guard !isUnlocked else { return false }
    return progress(with: context) >= 1.0
  }

  /// Create a new Achievement instance with unlockedAt set to now
  func unlocked(at date: Date = Date()) -> Achievement {
    Achievement(
      id: id,
      name: name,
      description: description,
      emoji: emoji,
      category: category,
      requirement: requirement,
      xpReward: xpReward,
      unlockedAt: date
    )
  }
}

// MARK: - Default Achievements

public extension Achievement {
  /// Default achievements available to all users
  /// Ordered by expected unlock progression for optimal user motivation
  static let defaults: [Achievement] = [
    // Early game (Day 1)
    Achievement(
      id: "first-step",
      name: "First Step",
      description: "Complete your first dua",
      emoji: "1",
      category: .practice,
      requirement: AchievementRequirement(type: .totalDuas, value: 1),
      xpReward: 50
    ),
    // Early game (Day 3)
    Achievement(
      id: "getting-started",
      name: "Getting Started",
      description: "Maintain a 3-day streak",
      emoji: "3",
      category: .streak,
      requirement: AchievementRequirement(type: .streakDays, value: 3),
      xpReward: 75
    ),
    // Week 1
    Achievement(
      id: "week-warrior",
      name: "Week Warrior",
      description: "Maintain a 7-day streak",
      emoji: "7",
      category: .streak,
      requirement: AchievementRequirement(type: .streakDays, value: 7),
      xpReward: 100
    ),
    // Week 2
    Achievement(
      id: "fortnight-faithful",
      name: "Fortnight Faithful",
      description: "Maintain a 14-day streak",
      emoji: "14",
      category: .streak,
      requirement: AchievementRequirement(type: .streakDays, value: 14),
      xpReward: 200
    ),
    // Month 1
    Achievement(
      id: "month-master",
      name: "Month Master",
      description: "Maintain a 30-day streak",
      emoji: "30",
      category: .streak,
      requirement: AchievementRequirement(type: .streakDays, value: 30),
      xpReward: 500
    ),
    // Level milestones
    Achievement(
      id: "level-5",
      name: "Rising Star",
      description: "Reach Level 5",
      emoji: "5",
      category: .level,
      requirement: AchievementRequirement(type: .levelReached, value: 5),
      xpReward: 200
    ),
    // Special
    Achievement(
      id: "perfect-week",
      name: "Perfect Week",
      description: "Complete all habits for 7 consecutive days",
      emoji: "W",
      category: .special,
      requirement: AchievementRequirement(type: .perfectWeek, value: 7),
      xpReward: 300
    )
  ]
}
