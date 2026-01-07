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

  // Users
  func fetchAllUsersAdmin() async throws -> [UserProfile]
  func updateUserAdmin(userId: String, isAdmin: Bool) async throws -> UserProfile
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
  public var bestTime: TimeSlot?
  public var difficulty: DuaDifficulty
  public var estDurationSec: Int?
  public var rizqBenefit: String?
  public var context: String?
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
    bestTime: TimeSlot? = nil,
    difficulty: DuaDifficulty = .beginner,
    estDurationSec: Int? = nil,
    rizqBenefit: String? = nil,
    context: String? = nil,
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
    self.context = context
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
    self.context = dua.context
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

// MARK: - Admin Service Implementation

public actor AdminService: AdminServiceProtocol {
  private let apiClient: APIClientProtocol

  public init(apiClient: APIClientProtocol) {
    self.apiClient = apiClient
  }

  public init(configuration: APIConfiguration) {
    self.apiClient = APIClient(configuration: configuration)
  }

  // MARK: - Stats

  public func fetchAdminStats() async throws -> AdminStats {
    // Fetch counts in parallel
    async let duasCount = fetchCount("duas")
    async let journeysCount = fetchCount("journeys")
    async let categoriesCount = fetchCount("categories")
    async let usersCount = fetchCount("user_profiles")
    async let activeToday = fetchActiveUsersToday()

    return try await AdminStats(
      totalDuas: duasCount,
      totalJourneys: journeysCount,
      totalCategories: categoriesCount,
      totalUsers: usersCount,
      activeUsersToday: activeToday
    )
  }

  private func fetchCount(_ table: String) async throws -> Int {
    let query = "SELECT COUNT(*) as count FROM \(table)"
    let results: [[String: Any]] = try await apiClient.executeRaw(query, params: nil)
    return (results.first?["count"] as? Int) ?? 0
  }

  private func fetchActiveUsersToday() async throws -> Int {
    let query = """
      SELECT COUNT(DISTINCT user_id) as count
      FROM user_activity
      WHERE date = CURRENT_DATE
    """
    let results: [[String: Any]] = try await apiClient.executeRaw(query, params: nil)
    return (results.first?["count"] as? Int) ?? 0
  }

  // MARK: - Duas CRUD

  public func fetchAllDuasAdmin() async throws -> [Dua] {
    let query = """
      SELECT * FROM duas
      ORDER BY updated_at DESC
    """
    return try await apiClient.execute(query, params: nil)
  }

  public func createDua(_ input: DuaInput) async throws -> Dua {
    let query = """
      INSERT INTO duas (
        category_id, collection_id, title_en, title_ar, arabic_text,
        transliteration, translation_en, source, repetitions, best_time,
        difficulty, est_duration_sec, rizq_benefit, context, prophetic_context,
        xp_value, audio_url, created_at, updated_at
      ) VALUES (
        $1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, $13, $14, $15, $16, $17, NOW(), NOW()
      )
      RETURNING *
    """

    let params: [SQLValue] = [
      input.categoryId.map { .int($0) } ?? .null,
      input.collectionId.map { .int($0) } ?? .null,
      .string(input.titleEn.trimmingCharacters(in: .whitespacesAndNewlines)),
      input.titleAr.map { .string($0) } ?? .null,
      .string(input.arabicText.trimmingCharacters(in: .whitespacesAndNewlines)),
      input.transliteration.map { .string($0) } ?? .null,
      .string(input.translationEn.trimmingCharacters(in: .whitespacesAndNewlines)),
      input.source.map { .string($0) } ?? .null,
      .int(input.repetitions),
      input.bestTime.map { .string($0.rawValue) } ?? .null,
      .string(input.difficulty.rawValue),
      input.estDurationSec.map { .int($0) } ?? .null,
      input.rizqBenefit.map { .string($0) } ?? .null,
      input.context.map { .string($0) } ?? .null,
      input.propheticContext.map { .string($0) } ?? .null,
      .int(input.xpValue),
      input.audioUrl.map { .string($0) } ?? .null
    ]

    let results: [Dua] = try await apiClient.execute(query, params: params)
    guard let dua = results.first else {
      throw APIError.serverError("Failed to create dua")
    }
    return dua
  }

  public func updateDua(id: Int, input: DuaInput) async throws -> Dua {
    let query = """
      UPDATE duas SET
        category_id = $2,
        collection_id = $3,
        title_en = $4,
        title_ar = $5,
        arabic_text = $6,
        transliteration = $7,
        translation_en = $8,
        source = $9,
        repetitions = $10,
        best_time = $11,
        difficulty = $12,
        est_duration_sec = $13,
        rizq_benefit = $14,
        context = $15,
        prophetic_context = $16,
        xp_value = $17,
        audio_url = $18,
        updated_at = NOW()
      WHERE id = $1
      RETURNING *
    """

    let params: [SQLValue] = [
      .int(id),
      input.categoryId.map { .int($0) } ?? .null,
      input.collectionId.map { .int($0) } ?? .null,
      .string(input.titleEn.trimmingCharacters(in: .whitespacesAndNewlines)),
      input.titleAr.map { .string($0) } ?? .null,
      .string(input.arabicText.trimmingCharacters(in: .whitespacesAndNewlines)),
      input.transliteration.map { .string($0) } ?? .null,
      .string(input.translationEn.trimmingCharacters(in: .whitespacesAndNewlines)),
      input.source.map { .string($0) } ?? .null,
      .int(input.repetitions),
      input.bestTime.map { .string($0.rawValue) } ?? .null,
      .string(input.difficulty.rawValue),
      input.estDurationSec.map { .int($0) } ?? .null,
      input.rizqBenefit.map { .string($0) } ?? .null,
      input.context.map { .string($0) } ?? .null,
      input.propheticContext.map { .string($0) } ?? .null,
      .int(input.xpValue),
      input.audioUrl.map { .string($0) } ?? .null
    ]

    let results: [Dua] = try await apiClient.execute(query, params: params)
    guard let dua = results.first else {
      throw APIError.notFound
    }
    return dua
  }

  public func deleteDua(id: Int) async throws {
    // First remove from journey_duas
    let deleteJourneyDuas = """
      DELETE FROM journey_duas WHERE dua_id = $1
    """
    _ = try await apiClient.executeUpdate(deleteJourneyDuas, params: [.int(id)])

    // Then delete the dua
    let query = """
      DELETE FROM duas WHERE id = $1
    """
    let affected = try await apiClient.executeUpdate(query, params: [.int(id)])
    if affected == 0 {
      throw APIError.notFound
    }
  }

  // MARK: - Journeys CRUD

  public func fetchAllJourneysAdmin() async throws -> [Journey] {
    let query = """
      SELECT * FROM journeys
      ORDER BY sort_order, name
    """
    return try await apiClient.execute(query, params: nil)
  }

  public func createJourney(_ input: JourneyInput) async throws -> Journey {
    let query = """
      INSERT INTO journeys (
        name, slug, description, emoji, estimated_minutes,
        daily_xp, is_premium, is_featured, sort_order
      ) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9)
      RETURNING *
    """

    let params: [SQLValue] = [
      .string(input.name.trimmingCharacters(in: .whitespacesAndNewlines)),
      .string(input.slug.trimmingCharacters(in: .whitespacesAndNewlines)),
      input.description.map { .string($0) } ?? .null,
      .string(input.emoji),
      .int(input.estimatedMinutes),
      .int(input.dailyXp),
      .bool(input.isPremium),
      .bool(input.isFeatured),
      .int(input.sortOrder)
    ]

    let results: [Journey] = try await apiClient.execute(query, params: params)
    guard let journey = results.first else {
      throw APIError.serverError("Failed to create journey")
    }
    return journey
  }

  public func updateJourney(id: Int, input: JourneyInput) async throws -> Journey {
    let query = """
      UPDATE journeys SET
        name = $2,
        slug = $3,
        description = $4,
        emoji = $5,
        estimated_minutes = $6,
        daily_xp = $7,
        is_premium = $8,
        is_featured = $9,
        sort_order = $10
      WHERE id = $1
      RETURNING *
    """

    let params: [SQLValue] = [
      .int(id),
      .string(input.name.trimmingCharacters(in: .whitespacesAndNewlines)),
      .string(input.slug.trimmingCharacters(in: .whitespacesAndNewlines)),
      input.description.map { .string($0) } ?? .null,
      .string(input.emoji),
      .int(input.estimatedMinutes),
      .int(input.dailyXp),
      .bool(input.isPremium),
      .bool(input.isFeatured),
      .int(input.sortOrder)
    ]

    let results: [Journey] = try await apiClient.execute(query, params: params)
    guard let journey = results.first else {
      throw APIError.notFound
    }
    return journey
  }

  public func deleteJourney(id: Int) async throws {
    // First remove all journey_duas
    let deleteJourneyDuas = """
      DELETE FROM journey_duas WHERE journey_id = $1
    """
    _ = try await apiClient.executeUpdate(deleteJourneyDuas, params: [.int(id)])

    // Then delete the journey
    let query = """
      DELETE FROM journeys WHERE id = $1
    """
    let affected = try await apiClient.executeUpdate(query, params: [.int(id)])
    if affected == 0 {
      throw APIError.notFound
    }
  }

  // MARK: - Journey Duas

  public func fetchJourneyDuasAdmin(journeyId: Int) async throws -> [JourneyDua] {
    let query = """
      SELECT * FROM journey_duas
      WHERE journey_id = $1
      ORDER BY sort_order
    """
    return try await apiClient.execute(query, params: [.int(journeyId)])
  }

  public func addDuaToJourney(journeyId: Int, duaId: Int, timeSlot: TimeSlot, sortOrder: Int) async throws {
    let query = """
      INSERT INTO journey_duas (journey_id, dua_id, time_slot, sort_order)
      VALUES ($1, $2, $3, $4)
      ON CONFLICT (journey_id, dua_id) DO UPDATE SET
        time_slot = $3,
        sort_order = $4
    """
    _ = try await apiClient.executeUpdate(query, params: [
      .int(journeyId),
      .int(duaId),
      .string(timeSlot.rawValue),
      .int(sortOrder)
    ])
  }

  public func removeDuaFromJourney(journeyId: Int, duaId: Int) async throws {
    let query = """
      DELETE FROM journey_duas
      WHERE journey_id = $1 AND dua_id = $2
    """
    _ = try await apiClient.executeUpdate(query, params: [.int(journeyId), .int(duaId)])
  }

  public func updateJourneyDuaOrder(journeyId: Int, duaId: Int, sortOrder: Int) async throws {
    let query = """
      UPDATE journey_duas
      SET sort_order = $3
      WHERE journey_id = $1 AND dua_id = $2
    """
    _ = try await apiClient.executeUpdate(query, params: [.int(journeyId), .int(duaId), .int(sortOrder)])
  }

  // MARK: - Categories CRUD

  public func fetchAllCategoriesAdmin() async throws -> [DuaCategory] {
    let query = """
      SELECT * FROM categories
      ORDER BY name
    """
    return try await apiClient.execute(query, params: nil)
  }

  public func createCategory(_ input: CategoryInput) async throws -> DuaCategory {
    let query = """
      INSERT INTO categories (name, slug, description)
      VALUES ($1, $2, $3)
      RETURNING *
    """

    let params: [SQLValue] = [
      .string(input.name.trimmingCharacters(in: .whitespacesAndNewlines)),
      .string(input.slug.rawValue),
      input.description.map { .string($0) } ?? .null
    ]

    let results: [DuaCategory] = try await apiClient.execute(query, params: params)
    guard let category = results.first else {
      throw APIError.serverError("Failed to create category")
    }
    return category
  }

  public func updateCategory(id: Int, input: CategoryInput) async throws -> DuaCategory {
    let query = """
      UPDATE categories SET
        name = $2,
        slug = $3,
        description = $4
      WHERE id = $1
      RETURNING *
    """

    let params: [SQLValue] = [
      .int(id),
      .string(input.name.trimmingCharacters(in: .whitespacesAndNewlines)),
      .string(input.slug.rawValue),
      input.description.map { .string($0) } ?? .null
    ]

    let results: [DuaCategory] = try await apiClient.execute(query, params: params)
    guard let category = results.first else {
      throw APIError.notFound
    }
    return category
  }

  public func deleteCategory(id: Int) async throws {
    // Set category_id to null for duas in this category
    let updateDuas = """
      UPDATE duas SET category_id = NULL WHERE category_id = $1
    """
    _ = try await apiClient.executeUpdate(updateDuas, params: [.int(id)])

    // Then delete the category
    let query = """
      DELETE FROM categories WHERE id = $1
    """
    let affected = try await apiClient.executeUpdate(query, params: [.int(id)])
    if affected == 0 {
      throw APIError.notFound
    }
  }

  // MARK: - Users

  public func fetchAllUsersAdmin() async throws -> [UserProfile] {
    let query = """
      SELECT * FROM user_profiles
      ORDER BY created_at DESC
    """
    return try await apiClient.execute(query, params: nil)
  }

  public func updateUserAdmin(userId: String, isAdmin: Bool) async throws -> UserProfile {
    let query = """
      UPDATE user_profiles SET
        is_admin = $2,
        updated_at = NOW()
      WHERE user_id = $1::uuid
      RETURNING *
    """

    let results: [UserProfile] = try await apiClient.execute(query, params: [
      .string(userId),
      .bool(isAdmin)
    ])
    guard let user = results.first else {
      throw APIError.notFound
    }
    return user
  }

  public func deleteUserAdmin(userId: String) async throws {
    // Delete user activity
    let deleteActivity = """
      DELETE FROM user_activity WHERE user_id = $1::uuid
    """
    _ = try await apiClient.executeUpdate(deleteActivity, params: [.string(userId)])

    // Delete user progress
    let deleteProgress = """
      DELETE FROM user_progress WHERE user_id = $1::uuid
    """
    _ = try await apiClient.executeUpdate(deleteProgress, params: [.string(userId)])

    // Delete user profile
    let query = """
      DELETE FROM user_profiles WHERE user_id = $1::uuid
    """
    let affected = try await apiClient.executeUpdate(query, params: [.string(userId)])
    if affected == 0 {
      throw APIError.notFound
    }
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
      context: input.context,
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
      context: input.context,
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

  public func fetchAllUsersAdmin() async throws -> [UserProfile] {
    [SampleData.userProfile]
  }

  public func updateUserAdmin(userId: String, isAdmin: Bool) async throws -> UserProfile {
    SampleData.userProfile
  }

  public func deleteUserAdmin(userId: String) async throws {}
}
