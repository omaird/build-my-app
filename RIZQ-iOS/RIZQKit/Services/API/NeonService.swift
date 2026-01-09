import Foundation

// MARK: - Neon Service Protocol

public protocol NeonServiceProtocol: Sendable {
  // Duas
  func fetchAllDuas() async throws -> [Dua]
  func fetchDua(id: Int) async throws -> Dua?
  func fetchDuasByCategory(categoryId: Int) async throws -> [Dua]
  func fetchDuasByCategory(slug: CategorySlug) async throws -> [Dua]
  func searchDuas(query: String) async throws -> [Dua]

  // Categories
  func fetchAllCategories() async throws -> [DuaCategory]
  func fetchCategory(id: Int) async throws -> DuaCategory?

  // Collections
  func fetchAllCollections() async throws -> [DuaCollection]

  // Journeys
  func fetchAllJourneys() async throws -> [Journey]
  func fetchFeaturedJourneys() async throws -> [Journey]
  func fetchJourney(id: Int) async throws -> Journey?
  func fetchJourneyBySlug(_ slug: String) async throws -> Journey?
  func fetchJourneyDuas(journeyId: Int) async throws -> [JourneyDuaFull]
  func fetchJourneyWithDuas(id: Int) async throws -> JourneyWithDuas?
  func fetchMultipleJourneysDuas(journeyIds: [Int]) async throws -> [JourneyDuaFull]

  // User Profile
  func fetchUserProfile(userId: String) async throws -> UserProfile?
  func createUserProfile(userId: String, displayName: String?) async throws -> UserProfile
  func updateUserProfile(_ profile: UserProfile) async throws -> UserProfile
  func addXp(userId: String, amount: Int) async throws -> UserProfile

  // User Activity
  func fetchUserActivity(userId: String, date: Date) async throws -> UserActivity?
  func fetchWeekActivities(userId: String) async throws -> [UserActivity]
  func recordDuaCompletion(userId: String, duaId: Int, xpEarned: Int) async throws
}

// MARK: - Neon Service Implementation

public actor NeonService: NeonServiceProtocol {
  private let apiClient: APIClientProtocol

  public init(apiClient: APIClientProtocol) {
    self.apiClient = apiClient
  }

  public init(configuration: APIConfiguration) {
    self.apiClient = APIClient(configuration: configuration)
  }

  // MARK: - Duas

  public func fetchAllDuas() async throws -> [Dua] {
    let query = """
      SELECT * FROM duas
      ORDER BY category_id, title_en
    """
    return try await apiClient.execute(query, params: nil)
  }

  public func fetchDua(id: Int) async throws -> Dua? {
    let query = """
      SELECT * FROM duas
      WHERE id = $1
      LIMIT 1
    """
    let results: [Dua] = try await apiClient.execute(query, params: [.int(id)])
    return results.first
  }

  public func fetchDuasByCategory(categoryId: Int) async throws -> [Dua] {
    let query = """
      SELECT * FROM duas
      WHERE category_id = $1
      ORDER BY title_en
    """
    return try await apiClient.execute(query, params: [.int(categoryId)])
  }

  public func fetchDuasByCategory(slug: CategorySlug) async throws -> [Dua] {
    // Join with categories to filter by slug
    let query = """
      SELECT d.* FROM duas d
      JOIN categories c ON d.category_id = c.id
      WHERE c.slug = $1
      ORDER BY d.title_en
    """
    return try await apiClient.execute(query, params: [.string(slug.rawValue)])
  }

  public func searchDuas(query searchText: String) async throws -> [Dua] {
    let query = """
      SELECT * FROM duas
      WHERE title_en ILIKE $1
         OR arabic_text ILIKE $1
         OR transliteration ILIKE $1
         OR translation_en ILIKE $1
      ORDER BY title_en
    """
    let searchPattern = "%\(searchText)%"
    return try await apiClient.execute(query, params: [.string(searchPattern)])
  }

  // MARK: - Categories

  public func fetchAllCategories() async throws -> [DuaCategory] {
    let query = """
      SELECT * FROM categories
      ORDER BY name
    """
    return try await apiClient.execute(query, params: nil)
  }

  public func fetchCategory(id: Int) async throws -> DuaCategory? {
    let query = """
      SELECT * FROM categories
      WHERE id = $1
      LIMIT 1
    """
    let results: [DuaCategory] = try await apiClient.execute(query, params: [.int(id)])
    return results.first
  }

  // MARK: - Collections

  public func fetchAllCollections() async throws -> [DuaCollection] {
    let query = """
      SELECT * FROM collections
      ORDER BY name
    """
    return try await apiClient.execute(query, params: nil)
  }

  // MARK: - Journeys

  public func fetchAllJourneys() async throws -> [Journey] {
    let query = """
      SELECT * FROM journeys
      ORDER BY sort_order, name
    """
    return try await apiClient.execute(query, params: nil)
  }

  public func fetchFeaturedJourneys() async throws -> [Journey] {
    let query = """
      SELECT * FROM journeys
      WHERE is_featured = true
      ORDER BY sort_order, name
    """
    return try await apiClient.execute(query, params: nil)
  }

  public func fetchJourney(id: Int) async throws -> Journey? {
    let query = """
      SELECT * FROM journeys
      WHERE id = $1
      LIMIT 1
    """
    let results: [Journey] = try await apiClient.execute(query, params: [.int(id)])
    return results.first
  }

  public func fetchJourneyDuas(journeyId: Int) async throws -> [JourneyDuaFull] {
    // First fetch the journey_duas join table
    let joinQuery = """
      SELECT journey_id, dua_id, time_slot, sort_order
      FROM journey_duas
      WHERE journey_id = $1
      ORDER BY sort_order
    """
    let journeyDuas: [JourneyDua] = try await apiClient.execute(joinQuery, params: [.int(journeyId)])

    guard !journeyDuas.isEmpty else { return [] }

    // Get all dua IDs
    let duaIds = journeyDuas.map { $0.duaId }

    // Fetch all duas in one query
    let duasQuery = """
      SELECT * FROM duas
      WHERE id = ANY($1::int[])
    """
    let duas: [Dua] = try await apiClient.execute(duasQuery, params: [.intArray(duaIds)])

    // Map duas by ID for quick lookup
    let duaMap = Dictionary(uniqueKeysWithValues: duas.map { ($0.id, $0) })

    // Combine journey_duas with dua data
    return journeyDuas.compactMap { journeyDua in
      guard let dua = duaMap[journeyDua.duaId] else { return nil }
      return JourneyDuaFull(journeyDua: journeyDua, dua: dua)
    }
  }

  public func fetchJourneyBySlug(_ slug: String) async throws -> Journey? {
    let query = """
      SELECT * FROM journeys
      WHERE slug = $1
      LIMIT 1
    """
    let results: [Journey] = try await apiClient.execute(query, params: [.string(slug)])
    return results.first
  }

  public func fetchJourneyWithDuas(id: Int) async throws -> JourneyWithDuas? {
    guard let journey = try await fetchJourney(id: id) else {
      return nil
    }
    let duas = try await fetchJourneyDuas(journeyId: id)
    return JourneyWithDuas(journey: journey, duas: duas)
  }

  public func fetchMultipleJourneysDuas(journeyIds: [Int]) async throws -> [JourneyDuaFull] {
    guard !journeyIds.isEmpty else { return [] }

    // Fetch all journey_duas for the given journey IDs
    let joinQuery = """
      SELECT journey_id, dua_id, time_slot, sort_order
      FROM journey_duas
      WHERE journey_id = ANY($1::int[])
      ORDER BY sort_order
    """
    let journeyDuas: [JourneyDua] = try await apiClient.execute(joinQuery, params: [.intArray(journeyIds)])

    guard !journeyDuas.isEmpty else { return [] }

    // Get unique dua IDs
    let duaIds = Array(Set(journeyDuas.map { $0.duaId }))

    // Fetch all duas in one query
    let duasQuery = """
      SELECT * FROM duas
      WHERE id = ANY($1::int[])
    """
    let duas: [Dua] = try await apiClient.execute(duasQuery, params: [.intArray(duaIds)])

    // Map duas by ID for quick lookup
    let duaMap = Dictionary(uniqueKeysWithValues: duas.map { ($0.id, $0) })

    // Combine journey_duas with dua data
    return journeyDuas.compactMap { journeyDua in
      guard let dua = duaMap[journeyDua.duaId] else { return nil }
      return JourneyDuaFull(journeyDua: journeyDua, dua: dua)
    }
  }

  // MARK: - User Profile

  public func fetchUserProfile(userId: String) async throws -> UserProfile? {
    let query = """
      SELECT * FROM user_profiles
      WHERE user_id = $1::uuid
      LIMIT 1
    """
    let results: [UserProfile] = try await apiClient.execute(query, params: [.string(userId)])
    return results.first
  }

  public func createUserProfile(userId: String, displayName: String?) async throws -> UserProfile {
    let query = """
      INSERT INTO user_profiles (user_id, display_name, streak, total_xp, level, is_admin)
      VALUES ($1::uuid, $2, 0, 0, 1, false)
      RETURNING *
    """
    let params: [SQLValue] = [
      .string(userId),
      displayName.map { .string($0) } ?? .null
    ]
    let results: [UserProfile] = try await apiClient.execute(query, params: params)
    guard let profile = results.first else {
      throw APIError.serverError("Failed to create user profile")
    }
    return profile
  }

  public func updateUserProfile(_ profile: UserProfile) async throws -> UserProfile {
    let query = """
      UPDATE user_profiles
      SET display_name = $2,
          streak = $3,
          total_xp = $4,
          level = $5,
          last_active_date = $6::date,
          updated_at = NOW()
      WHERE user_id = $1::uuid
      RETURNING *
    """
    let lastActiveStr = profile.lastActiveDate.map {
      let formatter = DateFormatter()
      formatter.dateFormat = "yyyy-MM-dd"
      return formatter.string(from: $0)
    }
    let params: [SQLValue] = [
      .string(profile.userId),
      profile.displayName.map { .string($0) } ?? .null,
      .int(profile.streak),
      .int(profile.totalXp),
      .int(profile.level),
      lastActiveStr.map { .string($0) } ?? .null
    ]
    let results: [UserProfile] = try await apiClient.execute(query, params: params)
    guard let updated = results.first else {
      throw APIError.serverError("Failed to update user profile")
    }
    return updated
  }

  public func addXp(userId: String, amount: Int) async throws -> UserProfile {
    // Use UPSERT to handle both new and existing profiles
    let query = """
      UPDATE user_profiles
      SET total_xp = total_xp + $2,
          level = (
            SELECT CASE
              WHEN (total_xp + $2) >= 50 * level * level + 50 * level
              THEN level + 1
              ELSE level
            END
          ),
          last_active_date = CURRENT_DATE,
          updated_at = NOW()
      WHERE user_id = $1::uuid
      RETURNING *
    """
    let results: [UserProfile] = try await apiClient.execute(query, params: [.string(userId), .int(amount)])
    guard let profile = results.first else {
      throw APIError.serverError("Failed to add XP")
    }
    return profile
  }

  // MARK: - User Activity

  public func fetchUserActivity(userId: String, date: Date) async throws -> UserActivity? {
    let dateStr = formatDate(date)
    let query = """
      SELECT * FROM user_activity
      WHERE user_id = $1::uuid AND date = $2::date
      LIMIT 1
    """
    let results: [UserActivity] = try await apiClient.execute(query, params: [.string(userId), .string(dateStr)])
    return results.first
  }

  public func fetchWeekActivities(userId: String) async throws -> [UserActivity] {
    // Get activity for the last 7 days
    let query = """
      SELECT * FROM user_activity
      WHERE user_id = $1::uuid
        AND date >= CURRENT_DATE - INTERVAL '6 days'
      ORDER BY date ASC
    """
    return try await apiClient.execute(query, params: [.string(userId)])
  }

  public func recordDuaCompletion(userId: String, duaId: Int, xpEarned: Int) async throws {
    let today = formatDate(Date())

    // UPSERT pattern - insert or update activity
    let query = """
      INSERT INTO user_activity (user_id, date, duas_completed, xp_earned)
      VALUES ($1::uuid, $2::date, ARRAY[$3], $4)
      ON CONFLICT (user_id, date)
      DO UPDATE SET
        duas_completed = array_append(user_activity.duas_completed, $3),
        xp_earned = user_activity.xp_earned + $4
    """
    _ = try await apiClient.executeUpdate(query, params: [
      .string(userId),
      .string(today),
      .int(duaId),
      .int(xpEarned)
    ])

    // Also update user progress
    let progressQuery = """
      INSERT INTO user_progress (user_id, dua_id, completed_count, last_completed)
      VALUES ($1::uuid, $2, 1, NOW())
      ON CONFLICT (user_id, dua_id)
      DO UPDATE SET
        completed_count = user_progress.completed_count + 1,
        last_completed = NOW()
    """
    _ = try await apiClient.executeUpdate(progressQuery, params: [
      .string(userId),
      .int(duaId)
    ])
  }

  // MARK: - Helpers

  private func formatDate(_ date: Date) -> String {
    let formatter = DateFormatter()
    formatter.dateFormat = "yyyy-MM-dd"
    return formatter.string(from: date)
  }
}

// MARK: - Mock Neon Service for Previews

public actor MockNeonService: NeonServiceProtocol {
  public init() {}

  public func fetchAllDuas() async throws -> [Dua] {
    SampleData.duas
  }

  public func fetchDua(id: Int) async throws -> Dua? {
    SampleData.duas.first { $0.id == id }
  }

  public func fetchDuasByCategory(categoryId: Int) async throws -> [Dua] {
    SampleData.duas.filter { $0.categoryId == categoryId }
  }

  public func fetchDuasByCategory(slug: CategorySlug) async throws -> [Dua] {
    SampleData.duas.filter { dua in
      switch slug {
      case .morning: return dua.categoryId == 1
      case .evening: return dua.categoryId == 2
      case .rizq: return dua.categoryId == 3
      case .gratitude: return dua.categoryId == 4
      }
    }
  }

  public func searchDuas(query: String) async throws -> [Dua] {
    SampleData.duas.filter { $0.titleEn.localizedCaseInsensitiveContains(query) }
  }

  public func fetchAllCategories() async throws -> [DuaCategory] {
    SampleData.categories
  }

  public func fetchCategory(id: Int) async throws -> DuaCategory? {
    SampleData.categories.first { $0.id == id }
  }

  public func fetchAllCollections() async throws -> [DuaCollection] {
    SampleData.collections
  }

  public func fetchAllJourneys() async throws -> [Journey] {
    SampleData.journeys
  }

  public func fetchFeaturedJourneys() async throws -> [Journey] {
    SampleData.journeys.filter { $0.isFeatured }
  }

  public func fetchJourney(id: Int) async throws -> Journey? {
    SampleData.journeys.first { $0.id == id }
  }

  public func fetchJourneyDuas(journeyId: Int) async throws -> [JourneyDuaFull] {
    // Return mock journey duas
    SampleData.journeyDuas.filter { $0.journeyDua.journeyId == journeyId }
  }

  public func fetchJourneyBySlug(_ slug: String) async throws -> Journey? {
    SampleData.journeys.first { $0.slug == slug }
  }

  public func fetchJourneyWithDuas(id: Int) async throws -> JourneyWithDuas? {
    guard let journey = SampleData.journeys.first(where: { $0.id == id }) else {
      return nil
    }
    let duas = SampleData.journeyDuas.filter { $0.journeyDua.journeyId == id }
    return JourneyWithDuas(journey: journey, duas: duas)
  }

  public func fetchMultipleJourneysDuas(journeyIds: [Int]) async throws -> [JourneyDuaFull] {
    SampleData.journeyDuas.filter { journeyIds.contains($0.journeyDua.journeyId) }
  }

  public func fetchUserProfile(userId: String) async throws -> UserProfile? {
    SampleData.userProfile
  }

  public func createUserProfile(userId: String, displayName: String?) async throws -> UserProfile {
    UserProfile(id: UUID().uuidString, userId: userId, displayName: displayName)
  }

  public func updateUserProfile(_ profile: UserProfile) async throws -> UserProfile {
    profile
  }

  public func addXp(userId: String, amount: Int) async throws -> UserProfile {
    let profile = SampleData.userProfile
    return UserProfile(
      id: profile.id,
      userId: profile.userId,
      displayName: profile.displayName,
      streak: profile.streak,
      totalXp: profile.totalXp + amount,
      level: LevelCalculator.calculateLevel(from: profile.totalXp + amount),
      lastActiveDate: Date(),
      isAdmin: profile.isAdmin
    )
  }

  public func fetchUserActivity(userId: String, date: Date) async throws -> UserActivity? {
    nil
  }

  public func fetchWeekActivities(userId: String) async throws -> [UserActivity] {
    []
  }

  public func recordDuaCompletion(userId: String, duaId: Int, xpEarned: Int) async throws {
    // No-op for mock
  }
}
