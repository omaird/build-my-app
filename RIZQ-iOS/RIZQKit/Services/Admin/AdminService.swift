import Foundation

// MARK: - Admin Service Protocol

/// Protocol for admin CRUD operations
public protocol AdminServiceProtocol: Sendable {
  // Stats
  func fetchAdminStats() async throws -> AdminStats

  // Duas CRUD
  func fetchAllDuasAdmin() async throws -> [Dua]
  func createDua(_ input: DuaInput) async throws -> Dua
  func updateDua(id: Int, input: DuaInput) async throws -> Dua
  func deleteDua(id: Int) async throws

  // Journeys CRUD
  func fetchAllJourneysAdmin() async throws -> [Journey]
  func createJourney(_ input: JourneyInput) async throws -> Journey
  func updateJourney(id: Int, input: JourneyInput) async throws -> Journey
  func deleteJourney(id: Int) async throws

  // Journey Duas
  func fetchJourneyDuasAdmin(journeyId: Int) async throws -> [JourneyDua]
  func addDuaToJourney(journeyId: Int, duaId: Int, timeSlot: TimeSlot, sortOrder: Int) async throws
  func removeDuaFromJourney(journeyId: Int, duaId: Int) async throws
  func updateJourneyDuaOrder(journeyId: Int, duaId: Int, sortOrder: Int) async throws

  // Categories CRUD
  func fetchAllCategoriesAdmin() async throws -> [DuaCategory]
  func createCategory(_ input: CategoryInput) async throws -> DuaCategory
  func updateCategory(id: Int, input: CategoryInput) async throws -> DuaCategory
  func deleteCategory(id: Int) async throws

  // Collections CRUD
  func fetchAllCollectionsAdmin() async throws -> [DuaCollection]
  func createCollection(_ input: CollectionInput) async throws -> DuaCollection
  func updateCollection(id: Int, input: CollectionInput) async throws -> DuaCollection
  func deleteCollection(id: Int) async throws

  // Users
  func fetchAllUsersAdmin() async throws -> [UserProfile]
  func updateUserAdmin(userId: String, isAdmin: Bool) async throws -> UserProfile
  func updateUserPremium(userId: String, isPremium: Bool) async throws -> UserProfile
  func deleteUserAdmin(userId: String) async throws
}

// MARK: - Admin Stats

public struct AdminStats: Equatable, Sendable {
  public let totalDuas: Int
  public let totalJourneys: Int
  public let totalCategories: Int
  public let totalUsers: Int
  public let activeUsersToday: Int

  public init(
    totalDuas: Int = 0,
    totalJourneys: Int = 0,
    totalCategories: Int = 0,
    totalUsers: Int = 0,
    activeUsersToday: Int = 0
  ) {
    self.totalDuas = totalDuas
    self.totalJourneys = totalJourneys
    self.totalCategories = totalCategories
    self.totalUsers = totalUsers
    self.activeUsersToday = activeUsersToday
  }
}

// MARK: - Input Types

public struct DuaInput: Equatable, Sendable {
  public var titleEn: String
  public var titleAr: String?
  public var arabicText: String
  public var transliteration: String?
  public var translationEn: String
  public var source: String?
  public var repetitions: Int
  public var bestTime: String?  // Changed from TimeSlot? to match Dua model
  public var difficulty: DuaDifficulty?  // Made optional to match Dua model
  public var estDurationSec: Int?
  public var rizqBenefit: String?
  public var propheticContext: String?
  public var xpValue: Int
  public var audioUrl: String?
  public var categoryId: Int?
  public var collectionId: Int?

  public init(
    titleEn: String = "",
    titleAr: String? = nil,
    arabicText: String = "",
    transliteration: String? = nil,
    translationEn: String = "",
    source: String? = nil,
    repetitions: Int = 1,
    bestTime: String? = nil,
    difficulty: DuaDifficulty? = .beginner,
    estDurationSec: Int? = nil,
    rizqBenefit: String? = nil,
    propheticContext: String? = nil,
    xpValue: Int = 10,
    audioUrl: String? = nil,
    categoryId: Int? = nil,
    collectionId: Int? = nil
  ) {
    self.titleEn = titleEn
    self.titleAr = titleAr
    self.arabicText = arabicText
    self.transliteration = transliteration
    self.translationEn = translationEn
    self.source = source
    self.repetitions = repetitions
    self.bestTime = bestTime
    self.difficulty = difficulty
    self.estDurationSec = estDurationSec
    self.rizqBenefit = rizqBenefit
    self.propheticContext = propheticContext
    self.xpValue = xpValue
    self.audioUrl = audioUrl
    self.categoryId = categoryId
    self.collectionId = collectionId
  }

  /// Create from existing Dua for editing
  public init(from dua: Dua) {
    self.titleEn = dua.titleEn
    self.titleAr = dua.titleAr
    self.arabicText = dua.arabicText
    self.transliteration = dua.transliteration
    self.translationEn = dua.translationEn
    self.source = dua.source
    self.repetitions = dua.repetitions
    self.bestTime = dua.bestTime
    self.difficulty = dua.difficulty
    self.estDurationSec = dua.estDurationSec
    self.rizqBenefit = dua.rizqBenefit
    self.propheticContext = dua.propheticContext
    self.xpValue = dua.xpValue
    self.audioUrl = dua.audioUrl
    self.categoryId = dua.categoryId
    self.collectionId = dua.collectionId
  }

  /// Validate required fields
  public var isValid: Bool {
    !titleEn.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
    !arabicText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
    !translationEn.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
    xpValue >= 1 && xpValue <= 100 &&
    repetitions >= 1 && repetitions <= 100
  }

  /// Validation errors
  public var validationErrors: [String] {
    var errors: [String] = []
    if titleEn.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
      errors.append("Title (English) is required")
    }
    if arabicText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
      errors.append("Arabic text is required")
    }
    if translationEn.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
      errors.append("Translation (English) is required")
    }
    if xpValue < 1 || xpValue > 100 {
      errors.append("XP value must be between 1 and 100")
    }
    if repetitions < 1 || repetitions > 100 {
      errors.append("Repetitions must be between 1 and 100")
    }
    return errors
  }
}

public struct JourneyInput: Equatable, Sendable {
  public var name: String
  public var slug: String
  public var description: String?
  public var emoji: String
  public var estimatedMinutes: Int
  public var dailyXp: Int
  public var isPremium: Bool
  public var isFeatured: Bool
  public var sortOrder: Int

  public init(
    name: String = "",
    slug: String = "",
    description: String? = nil,
    emoji: String = "📿",
    estimatedMinutes: Int = 10,
    dailyXp: Int = 50,
    isPremium: Bool = false,
    isFeatured: Bool = false,
    sortOrder: Int = 0
  ) {
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

  /// Create from existing Journey for editing
  public init(from journey: Journey) {
    self.name = journey.name
    self.slug = journey.slug
    self.description = journey.description
    self.emoji = journey.emoji
    self.estimatedMinutes = journey.estimatedMinutes
    self.dailyXp = journey.dailyXp
    self.isPremium = journey.isPremium
    self.isFeatured = journey.isFeatured
    self.sortOrder = journey.sortOrder
  }

  /// Generate slug from name
  public mutating func generateSlug() {
    slug = name
      .lowercased()
      .replacingOccurrences(of: " ", with: "-")
      .replacingOccurrences(of: "[^a-z0-9-]", with: "", options: .regularExpression)
  }

  /// Validate required fields
  public var isValid: Bool {
    !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
    !slug.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
    !emoji.isEmpty &&
    estimatedMinutes >= 1 &&
    dailyXp >= 0
  }

  /// Validation errors
  public var validationErrors: [String] {
    var errors: [String] = []
    if name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
      errors.append("Name is required")
    }
    if slug.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
      errors.append("Slug is required")
    }
    if emoji.isEmpty {
      errors.append("Emoji is required")
    }
    if estimatedMinutes < 1 {
      errors.append("Estimated minutes must be at least 1")
    }
    if dailyXp < 0 {
      errors.append("Daily XP cannot be negative")
    }
    return errors
  }
}

public struct CategoryInput: Equatable, Sendable {
  public var name: String
  public var slug: CategorySlug
  public var description: String?

  public init(
    name: String = "",
    slug: CategorySlug = .morning,
    description: String? = nil
  ) {
    self.name = name
    self.slug = slug
    self.description = description
  }

  /// Create from existing Category for editing
  public init(from category: DuaCategory) {
    self.name = category.name
    self.slug = category.slug
    self.description = category.description
  }

  /// Validate required fields
  public var isValid: Bool {
    !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
  }
}

public struct CollectionInput: Equatable, Sendable {
  public var name: String
  public var slug: String
  public var isPremium: Bool

  public init(
    name: String = "",
    slug: String = "",
    isPremium: Bool = false
  ) {
    self.name = name
    self.slug = slug
    self.isPremium = isPremium
  }

  /// Create from existing DuaCollection for editing
  public init(from collection: DuaCollection) {
    self.name = collection.name
    self.slug = collection.slug
    self.isPremium = collection.isPremium
  }

  /// Generate slug from name
  public mutating func generateSlug() {
    slug = name
      .lowercased()
      .replacingOccurrences(of: " ", with: "-")
      .replacingOccurrences(of: "[^a-z0-9-]", with: "", options: .regularExpression)
  }

  /// Validate required fields
  public var isValid: Bool {
    !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
    !slug.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
  }

  /// Validation errors
  public var validationErrors: [String] {
    var errors: [String] = []
    if name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
      errors.append("Name is required")
    }
    if slug.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
      errors.append("Slug is required")
    }
    return errors
  }
}

// MARK: - Mock Admin Service

public actor MockAdminService: AdminServiceProtocol {
  public init() {}

  public func fetchAdminStats() async throws -> AdminStats {
    AdminStats(
      totalDuas: 8,
      totalJourneys: 3,
      totalCategories: 4,
      totalUsers: 12,
      activeUsersToday: 5
    )
  }

  public func fetchAllDuasAdmin() async throws -> [Dua] {
    SampleData.duas
  }

  public func createDua(_ input: DuaInput) async throws -> Dua {
    Dua(
      id: Int.random(in: 100...999),
      categoryId: input.categoryId,
      collectionId: input.collectionId,
      titleEn: input.titleEn,
      titleAr: input.titleAr,
      arabicText: input.arabicText,
      transliteration: input.transliteration,
      translationEn: input.translationEn,
      source: input.source,
      repetitions: input.repetitions,
      bestTime: input.bestTime,
      difficulty: input.difficulty,
      estDurationSec: input.estDurationSec,
      rizqBenefit: input.rizqBenefit,
      propheticContext: input.propheticContext,
      xpValue: input.xpValue,
      audioUrl: input.audioUrl
    )
  }

  public func updateDua(id: Int, input: DuaInput) async throws -> Dua {
    Dua(
      id: id,
      categoryId: input.categoryId,
      collectionId: input.collectionId,
      titleEn: input.titleEn,
      titleAr: input.titleAr,
      arabicText: input.arabicText,
      transliteration: input.transliteration,
      translationEn: input.translationEn,
      source: input.source,
      repetitions: input.repetitions,
      bestTime: input.bestTime,
      difficulty: input.difficulty,
      estDurationSec: input.estDurationSec,
      rizqBenefit: input.rizqBenefit,
      propheticContext: input.propheticContext,
      xpValue: input.xpValue,
      audioUrl: input.audioUrl
    )
  }

  public func deleteDua(id: Int) async throws {}

  public func fetchAllJourneysAdmin() async throws -> [Journey] {
    SampleData.journeys
  }

  public func createJourney(_ input: JourneyInput) async throws -> Journey {
    Journey(
      id: Int.random(in: 100...999),
      name: input.name,
      slug: input.slug,
      description: input.description,
      emoji: input.emoji,
      estimatedMinutes: input.estimatedMinutes,
      dailyXp: input.dailyXp,
      isPremium: input.isPremium,
      isFeatured: input.isFeatured,
      sortOrder: input.sortOrder
    )
  }

  public func updateJourney(id: Int, input: JourneyInput) async throws -> Journey {
    Journey(
      id: id,
      name: input.name,
      slug: input.slug,
      description: input.description,
      emoji: input.emoji,
      estimatedMinutes: input.estimatedMinutes,
      dailyXp: input.dailyXp,
      isPremium: input.isPremium,
      isFeatured: input.isFeatured,
      sortOrder: input.sortOrder
    )
  }

  public func deleteJourney(id: Int) async throws {}

  public func fetchJourneyDuasAdmin(journeyId: Int) async throws -> [JourneyDua] {
    SampleData.journeyDuas.filter { $0.journeyDua.journeyId == journeyId }.map { $0.journeyDua }
  }

  public func addDuaToJourney(journeyId: Int, duaId: Int, timeSlot: TimeSlot, sortOrder: Int) async throws {}

  public func removeDuaFromJourney(journeyId: Int, duaId: Int) async throws {}

  public func updateJourneyDuaOrder(journeyId: Int, duaId: Int, sortOrder: Int) async throws {}

  public func fetchAllCategoriesAdmin() async throws -> [DuaCategory] {
    SampleData.categories
  }

  public func createCategory(_ input: CategoryInput) async throws -> DuaCategory {
    DuaCategory(id: Int.random(in: 100...999), name: input.name, slug: input.slug, description: input.description)
  }

  public func updateCategory(id: Int, input: CategoryInput) async throws -> DuaCategory {
    DuaCategory(id: id, name: input.name, slug: input.slug, description: input.description)
  }

  public func deleteCategory(id: Int) async throws {}

  public func fetchAllCollectionsAdmin() async throws -> [DuaCollection] {
    SampleData.collections
  }

  public func createCollection(_ input: CollectionInput) async throws -> DuaCollection {
    DuaCollection(id: Int.random(in: 100...999), name: input.name, slug: input.slug, isPremium: input.isPremium)
  }

  public func updateCollection(id: Int, input: CollectionInput) async throws -> DuaCollection {
    DuaCollection(id: id, name: input.name, slug: input.slug, isPremium: input.isPremium)
  }

  public func deleteCollection(id: Int) async throws {}

  public func fetchAllUsersAdmin() async throws -> [UserProfile] {
    [SampleData.userProfile]
  }

  public func updateUserAdmin(userId: String, isAdmin: Bool) async throws -> UserProfile {
    SampleData.userProfile
  }

  public func updateUserPremium(userId: String, isPremium: Bool) async throws -> UserProfile {
    SampleData.userProfile
  }

  public func deleteUserAdmin(userId: String) async throws {}
}
