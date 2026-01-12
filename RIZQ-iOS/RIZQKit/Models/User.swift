import Foundation

// MARK: - User Profile

public struct UserProfile: Codable, Identifiable, Equatable, Sendable {
  public var id: String { id_ }
  public let id_: String
  public let userId: String
  public let displayName: String?
  public let email: String?
  public let streak: Int
  public let totalXp: Int
  public let level: Int
  public let lastActiveDate: Date?
  public let isAdmin: Bool
  public let isPremium: Bool
  public let createdAt: Date
  public let updatedAt: Date

  public init(
    id: String,
    userId: String,
    displayName: String? = nil,
    email: String? = nil,
    streak: Int = 0,
    totalXp: Int = 0,
    level: Int = 1,
    lastActiveDate: Date? = nil,
    isAdmin: Bool = false,
    isPremium: Bool = false,
    createdAt: Date = Date(),
    updatedAt: Date = Date()
  ) {
    self.id_ = id
    self.userId = userId
    self.displayName = displayName
    self.email = email
    self.streak = streak
    self.totalXp = totalXp
    self.level = level
    self.lastActiveDate = lastActiveDate
    self.isAdmin = isAdmin
    self.isPremium = isPremium
    self.createdAt = createdAt
    self.updatedAt = updatedAt
  }

  private enum CodingKeys: String, CodingKey {
    case id_ = "id"
    case userId = "user_id"
    case displayName = "display_name"
    case email
    case streak
    case totalXp = "total_xp"
    case level
    case lastActiveDate = "last_active_date"
    case isAdmin = "is_admin"
    case isPremium = "is_premium"
    case createdAt = "created_at"
    case updatedAt = "updated_at"
  }

  // Custom decoder to handle id being either Int (PostgreSQL) or String (Firestore)
  public init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)

    // Handle id as either Int or String
    if let intId = try? container.decode(Int.self, forKey: .id_) {
      self.id_ = String(intId)
    } else {
      self.id_ = try container.decode(String.self, forKey: .id_)
    }

    self.userId = try container.decode(String.self, forKey: .userId)
    self.displayName = try container.decodeIfPresent(String.self, forKey: .displayName)
    self.email = try container.decodeIfPresent(String.self, forKey: .email)
    self.streak = try container.decodeIfPresent(Int.self, forKey: .streak) ?? 0
    self.totalXp = try container.decodeIfPresent(Int.self, forKey: .totalXp) ?? 0
    self.level = try container.decodeIfPresent(Int.self, forKey: .level) ?? 1
    self.lastActiveDate = try container.decodeIfPresent(Date.self, forKey: .lastActiveDate)
    self.isAdmin = try container.decodeIfPresent(Bool.self, forKey: .isAdmin) ?? false
    self.isPremium = try container.decodeIfPresent(Bool.self, forKey: .isPremium) ?? false
    self.createdAt = try container.decodeIfPresent(Date.self, forKey: .createdAt) ?? Date()
    self.updatedAt = try container.decodeIfPresent(Date.self, forKey: .updatedAt) ?? Date()
  }

  /// Calculate XP needed for next level
  /// Formula: 50 * level^2 + 50 * level
  public var xpForNextLevel: Int {
    50 * level * level + 50 * level
  }

  /// Calculate XP threshold for current level
  public var xpForCurrentLevel: Int {
    let prevLevel = level - 1
    return prevLevel > 0 ? 50 * prevLevel * prevLevel + 50 * prevLevel : 0
  }

  /// Progress percentage within current level (0.0 - 1.0)
  public var levelProgress: Double {
    let xpInLevel = totalXp - xpForCurrentLevel
    let xpNeeded = xpForNextLevel - xpForCurrentLevel
    return xpNeeded > 0 ? Double(xpInLevel) / Double(xpNeeded) : 0
  }

  /// XP remaining until next level
  public var xpToNextLevel: Int {
    max(0, xpForNextLevel - totalXp)
  }
}

// MARK: - User Activity

public struct UserActivity: Codable, Identifiable, Equatable, Sendable {
  public let id: Int
  public let userId: String
  public let date: Date
  public let duasCompleted: [Int]
  public let xpEarned: Int

  public init(
    id: Int,
    userId: String,
    date: Date,
    duasCompleted: [Int] = [],
    xpEarned: Int = 0
  ) {
    self.id = id
    self.userId = userId
    self.date = date
    self.duasCompleted = duasCompleted
    self.xpEarned = xpEarned
  }

  private enum CodingKeys: String, CodingKey {
    case id
    case userId = "user_id"
    case date
    case duasCompleted = "duas_completed"
    case xpEarned = "xp_earned"
  }
}

// MARK: - User Progress (per-dua tracking)

public struct UserProgress: Codable, Identifiable, Equatable, Sendable {
  public let id: Int
  public let userId: String
  public let duaId: Int
  public let completedCount: Int
  public let lastCompleted: Date?

  public init(
    id: Int,
    userId: String,
    duaId: Int,
    completedCount: Int = 0,
    lastCompleted: Date? = nil
  ) {
    self.id = id
    self.userId = userId
    self.duaId = duaId
    self.completedCount = completedCount
    self.lastCompleted = lastCompleted
  }

  private enum CodingKeys: String, CodingKey {
    case id
    case userId = "user_id"
    case duaId = "dua_id"
    case completedCount = "completed_count"
    case lastCompleted = "last_completed"
  }
}

// MARK: - Level Calculation Helper

public enum LevelCalculator {
  /// Calculate level from total XP
  /// Formula: Find highest level where 50 * level^2 + 50 * level <= xp
  public static func calculateLevel(from xp: Int) -> Int {
    var level = 1
    while 50 * level * level + 50 * level <= xp {
      level += 1
    }
    return level
  }

  /// Calculate XP threshold for a given level
  public static func xpThreshold(for level: Int) -> Int {
    let prevLevel = level - 1
    return prevLevel > 0 ? 50 * prevLevel * prevLevel + 50 * prevLevel : 0
  }

  /// Calculate XP needed to reach a level
  public static func xpNeeded(for level: Int) -> Int {
    50 * level * level + 50 * level
  }
}
