import Foundation

// MARK: - Firebase Neon Service Adapter

/// Adapter that implements NeonServiceProtocol using Firestore for user data
/// while delegating content queries to the underlying NeonService.
///
/// This enables a gradual migration from Neon-based user data to Firestore
/// while keeping dua content queries unchanged.
public actor FirebaseNeonService: NeonServiceProtocol {
  private let neonService: NeonService
  private let firestoreService: FirestoreService

  public init(neonService: NeonService, firestoreService: FirestoreService) {
    self.neonService = neonService
    self.firestoreService = firestoreService
  }

  public init(apiConfiguration: APIConfiguration) {
    self.neonService = NeonService(configuration: apiConfiguration)
    self.firestoreService = FirestoreService()
  }

  // MARK: - Duas (Delegated to NeonService)

  public func fetchAllDuas() async throws -> [Dua] {
    try await neonService.fetchAllDuas()
  }

  public func fetchDua(id: Int) async throws -> Dua? {
    try await neonService.fetchDua(id: id)
  }

  public func fetchDuasByCategory(categoryId: Int) async throws -> [Dua] {
    try await neonService.fetchDuasByCategory(categoryId: categoryId)
  }

  public func fetchDuasByCategory(slug: CategorySlug) async throws -> [Dua] {
    try await neonService.fetchDuasByCategory(slug: slug)
  }

  public func searchDuas(query: String) async throws -> [Dua] {
    try await neonService.searchDuas(query: query)
  }

  // MARK: - Categories (Delegated to NeonService)

  public func fetchAllCategories() async throws -> [DuaCategory] {
    try await neonService.fetchAllCategories()
  }

  public func fetchCategory(id: Int) async throws -> DuaCategory? {
    try await neonService.fetchCategory(id: id)
  }

  // MARK: - Collections (Delegated to NeonService)

  public func fetchAllCollections() async throws -> [DuaCollection] {
    try await neonService.fetchAllCollections()
  }

  // MARK: - Journeys (Delegated to NeonService)

  public func fetchAllJourneys() async throws -> [Journey] {
    try await neonService.fetchAllJourneys()
  }

  public func fetchFeaturedJourneys() async throws -> [Journey] {
    try await neonService.fetchFeaturedJourneys()
  }

  public func fetchJourney(id: Int) async throws -> Journey? {
    try await neonService.fetchJourney(id: id)
  }

  public func fetchJourneyDuas(journeyId: Int) async throws -> [JourneyDuaFull] {
    try await neonService.fetchJourneyDuas(journeyId: journeyId)
  }

  public func fetchJourneyBySlug(_ slug: String) async throws -> Journey? {
    try await neonService.fetchJourneyBySlug(slug)
  }

  public func fetchJourneyWithDuas(id: Int) async throws -> JourneyWithDuas? {
    try await neonService.fetchJourneyWithDuas(id: id)
  }

  public func fetchMultipleJourneysDuas(journeyIds: [Int]) async throws -> [JourneyDuaFull] {
    try await neonService.fetchMultipleJourneysDuas(journeyIds: journeyIds)
  }

  // MARK: - User Profile (Firestore-backed)

  public func fetchUserProfile(userId: String) async throws -> UserProfile? {
    guard let firestoreProfile = try await firestoreService.fetchUserProfile(userId: userId) else {
      return nil
    }
    return mapFirestoreToUserProfile(firestoreProfile)
  }

  public func createUserProfile(userId: String, displayName: String?) async throws -> UserProfile {
    let firestoreProfile = try await firestoreService.createUserProfile(userId: userId, displayName: displayName)
    return mapFirestoreToUserProfile(firestoreProfile)
  }

  public func updateUserProfile(_ profile: UserProfile) async throws -> UserProfile {
    let firestoreProfile = mapUserProfileToFirestore(profile)
    let updated = try await firestoreService.updateUserProfile(firestoreProfile)
    return mapFirestoreToUserProfile(updated)
  }

  public func addXp(userId: String, amount: Int) async throws -> UserProfile {
    let updated = try await firestoreService.addXp(userId: userId, amount: amount)
    return mapFirestoreToUserProfile(updated)
  }

  // MARK: - User Activity (Firestore-backed)

  public func fetchUserActivity(userId: String, date: Date) async throws -> UserActivity? {
    guard let firestoreActivity = try await firestoreService.fetchUserActivity(userId: userId, date: date) else {
      return nil
    }
    return mapFirestoreToUserActivity(firestoreActivity, date: date)
  }

  public func fetchWeekActivities(userId: String) async throws -> [UserActivity] {
    let activities = try await firestoreService.fetchWeekActivities(userId: userId)
    return activities.compactMap { activity -> UserActivity? in
      guard let date = dateFromString(activity.date) else { return nil }
      return mapFirestoreToUserActivity(activity, date: date)
    }
  }

  public func recordDuaCompletion(userId: String, duaId: Int, xpEarned: Int) async throws {
    try await firestoreService.recordDuaCompletion(userId: userId, duaId: duaId, xp: xpEarned)
  }

  // MARK: - Mapping Helpers

  private func mapFirestoreToUserProfile(_ profile: FirestoreUserProfile) -> UserProfile {
    UserProfile(
      id: profile.userId, // Use userId as id for Firestore
      userId: profile.userId,
      displayName: profile.displayName,
      streak: profile.streak,
      totalXp: profile.totalXp,
      level: profile.level,
      lastActiveDate: profile.lastActiveDate,
      isAdmin: profile.isAdmin,
      createdAt: profile.createdAt,
      updatedAt: profile.updatedAt
    )
  }

  private func mapUserProfileToFirestore(_ profile: UserProfile) -> FirestoreUserProfile {
    FirestoreUserProfile(
      userId: profile.userId,
      displayName: profile.displayName,
      streak: profile.streak,
      totalXp: profile.totalXp,
      level: profile.level,
      lastActiveDate: profile.lastActiveDate,
      isAdmin: profile.isAdmin,
      createdAt: profile.createdAt,
      updatedAt: profile.updatedAt
    )
  }

  private func mapFirestoreToUserActivity(_ activity: FirestoreUserActivity, date: Date) -> UserActivity {
    UserActivity(
      id: activity.date.hashValue, // Generate stable ID from date
      userId: activity.userId,
      date: date,
      duasCompleted: activity.duasCompleted,
      xpEarned: activity.xpEarned
    )
  }

  private func dateFromString(_ string: String) -> Date? {
    let formatter = DateFormatter()
    formatter.dateFormat = "yyyy-MM-dd"
    return formatter.date(from: string)
  }
}
