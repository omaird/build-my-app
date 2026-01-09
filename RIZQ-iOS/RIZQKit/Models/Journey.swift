import Foundation

// MARK: - Journey

public struct Journey: Codable, Identifiable, Equatable, Sendable {
  public let id: Int
  public let name: String
  public let slug: String
  public let description: String?
  public let emoji: String
  public let estimatedMinutes: Int
  public let dailyXp: Int
  public let isPremium: Bool
  public let isFeatured: Bool
  public let sortOrder: Int

  public init(
    id: Int,
    name: String,
    slug: String,
    description: String? = nil,
    emoji: String = "📿",
    estimatedMinutes: Int = 10,
    dailyXp: Int = 50,
    isPremium: Bool = false,
    isFeatured: Bool = false,
    sortOrder: Int = 0
  ) {
    self.id = id
    self.name = name
    self.slug = slug
    self.description = description
    self.emoji = emoji
    self.estimatedMinutes = estimatedMinutes
    self.dailyXp = dailyXp
    self.isPremium = isPremium
    self.isFeatured = isFeatured
    self.sortOrder = sortOrder
  }

  private enum CodingKeys: String, CodingKey {
    case id, name, slug, description, emoji
    case estimatedMinutes = "estimated_minutes"
    case dailyXp = "daily_xp"
    case isPremium = "is_premium"
    case isFeatured = "is_featured"
    case sortOrder = "sort_order"
  }

  /// Computed property to get dua count (set after fetching journey duas)
  public var duaCount: Int {
    // This will be populated from the relationship
    0
  }

  // MARK: - Image Support

  /// Returns true if the emoji field contains an image path instead of an actual emoji
  public var hasImageAsset: Bool {
    emoji.hasPrefix("/images/")
  }

  /// Returns the asset catalog name for this journey's illustration
  /// Uses the journey slug to map to bundled images
  public var imageAssetName: String {
    // Use slug directly - assets are named by slug (e.g., "rizq-seeker")
    slug
  }

  /// Fallback asset name if the journey's image is not found
  public static let defaultImageAsset = "default-journey"
}

// MARK: - Journey Dua (Join Table)

public struct JourneyDua: Codable, Equatable, Sendable {
  public let journeyId: Int
  public let duaId: Int
  public let timeSlot: TimeSlot
  public let sortOrder: Int

  public init(journeyId: Int, duaId: Int, timeSlot: TimeSlot, sortOrder: Int = 0) {
    self.journeyId = journeyId
    self.duaId = duaId
    self.timeSlot = timeSlot
    self.sortOrder = sortOrder
  }

  private enum CodingKeys: String, CodingKey {
    case journeyId = "journey_id"
    case duaId = "dua_id"
    case timeSlot = "time_slot"
    case sortOrder = "sort_order"
  }
}

// MARK: - Journey with Duas

public struct JourneyDuaFull: Equatable, Sendable {
  public let journeyDua: JourneyDua
  public let dua: Dua

  public init(journeyDua: JourneyDua, dua: Dua) {
    self.journeyDua = journeyDua
    self.dua = dua
  }
}

public struct JourneyWithDuas: Equatable, Sendable {
  public let journey: Journey
  public let duas: [JourneyDuaFull]

  public init(journey: Journey, duas: [JourneyDuaFull]) {
    self.journey = journey
    self.duas = duas
  }

  public var duaCount: Int {
    duas.count
  }

  public var duasByTimeSlot: [TimeSlot: [JourneyDuaFull]] {
    Dictionary(grouping: duas, by: { $0.journeyDua.timeSlot })
  }
}
