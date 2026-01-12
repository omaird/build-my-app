import ComposableArchitecture
import Foundation
import RIZQKit

// MARK: - DEPRECATED: Neon Client
// ============================================================================
// This file is DEPRECATED and kept for potential rollback.
// Use FirestoreUserClient for user data operations.
// Use FirestoreContentClient for content (duas, journeys, categories).
// ============================================================================

/// TCA dependency client for Neon database operations
/// Provides async closures that wrap the NeonServiceProtocol for easy testing
@available(*, deprecated, message: "Use FirestoreUserClient for user data and FirestoreContentClient for content")
@DependencyClient
struct NeonClient: Sendable {
  // MARK: - Duas

  var fetchAllDuas: @Sendable () async throws -> [Dua] = { [] }
  var fetchDua: @Sendable (_ id: Int) async throws -> Dua?
  var fetchDuasByCategory: @Sendable (_ slug: CategorySlug) async throws -> [Dua] = { _ in [] }
  var searchDuas: @Sendable (_ query: String) async throws -> [Dua] = { _ in [] }

  // MARK: - Categories

  var fetchAllCategories: @Sendable () async throws -> [DuaCategory] = { [] }
  var fetchCategory: @Sendable (_ id: Int) async throws -> DuaCategory?

  // MARK: - Collections

  var fetchAllCollections: @Sendable () async throws -> [DuaCollection] = { [] }

  // MARK: - Journeys

  var fetchAllJourneys: @Sendable () async throws -> [Journey] = { [] }
  var fetchFeaturedJourneys: @Sendable () async throws -> [Journey] = { [] }
  var fetchJourney: @Sendable (_ id: Int) async throws -> Journey?
  var fetchJourneyBySlug: @Sendable (_ slug: String) async throws -> Journey?
  var fetchJourneyDuas: @Sendable (_ journeyId: Int) async throws -> [JourneyDuaFull] = { _ in [] }
  var fetchJourneyWithDuas: @Sendable (_ id: Int) async throws -> JourneyWithDuas?
  var fetchMultipleJourneysDuas: @Sendable (_ journeyIds: [Int]) async throws -> [JourneyDuaFull] = { _ in [] }

  // MARK: - User Profile

  var fetchUserProfile: @Sendable (_ userId: String) async throws -> UserProfile?
  var createUserProfile: @Sendable (_ userId: String, _ displayName: String?) async throws -> UserProfile
  var updateUserProfile: @Sendable (_ profile: UserProfile) async throws -> UserProfile
  var addXp: @Sendable (_ userId: String, _ amount: Int) async throws -> UserProfile

  // MARK: - User Activity

  var fetchUserActivity: @Sendable (_ userId: String, _ date: Date) async throws -> UserActivity?
  var fetchWeekActivities: @Sendable (_ userId: String) async throws -> [UserActivity] = { _ in [] }
  var recordDuaCompletion: @Sendable (_ userId: String, _ duaId: Int, _ xpEarned: Int) async throws -> Void
}

// MARK: - Dependency Key

extension NeonClient: DependencyKey {
  /// Live implementation that accesses ServiceContainer.neonService at call time (not capture time).
  /// This ensures the properly configured service is always used, even if liveValue is evaluated
  /// before ServiceContainer.configure() completes.
  static let liveValue = NeonClient(
    fetchAllDuas: { try await ServiceContainer.shared.neonService.fetchAllDuas() },
    fetchDua: { try await ServiceContainer.shared.neonService.fetchDua(id: $0) },
    fetchDuasByCategory: { try await ServiceContainer.shared.neonService.fetchDuasByCategory(slug: $0) },
    searchDuas: { try await ServiceContainer.shared.neonService.searchDuas(query: $0) },
    fetchAllCategories: { try await ServiceContainer.shared.neonService.fetchAllCategories() },
    fetchCategory: { try await ServiceContainer.shared.neonService.fetchCategory(id: $0) },
    fetchAllCollections: { try await ServiceContainer.shared.neonService.fetchAllCollections() },
    fetchAllJourneys: { try await ServiceContainer.shared.neonService.fetchAllJourneys() },
    fetchFeaturedJourneys: { try await ServiceContainer.shared.neonService.fetchFeaturedJourneys() },
    fetchJourney: { try await ServiceContainer.shared.neonService.fetchJourney(id: $0) },
    fetchJourneyBySlug: { try await ServiceContainer.shared.neonService.fetchJourneyBySlug($0) },
    fetchJourneyDuas: { try await ServiceContainer.shared.neonService.fetchJourneyDuas(journeyId: $0) },
    fetchJourneyWithDuas: { try await ServiceContainer.shared.neonService.fetchJourneyWithDuas(id: $0) },
    fetchMultipleJourneysDuas: { try await ServiceContainer.shared.neonService.fetchMultipleJourneysDuas(journeyIds: $0) },
    fetchUserProfile: { try await ServiceContainer.shared.neonService.fetchUserProfile(userId: $0) },
    createUserProfile: { try await ServiceContainer.shared.neonService.createUserProfile(userId: $0, displayName: $1) },
    updateUserProfile: { try await ServiceContainer.shared.neonService.updateUserProfile($0) },
    addXp: { try await ServiceContainer.shared.neonService.addXp(userId: $0, amount: $1) },
    fetchUserActivity: { try await ServiceContainer.shared.neonService.fetchUserActivity(userId: $0, date: $1) },
    fetchWeekActivities: { try await ServiceContainer.shared.neonService.fetchWeekActivities(userId: $0) },
    recordDuaCompletion: { try await ServiceContainer.shared.neonService.recordDuaCompletion(userId: $0, duaId: $1, xpEarned: $2) }
  )

  static let previewValue: NeonClient = {
    let service = MockNeonService()
    return NeonClient(
      fetchAllDuas: { try await service.fetchAllDuas() },
      fetchDua: { try await service.fetchDua(id: $0) },
      fetchDuasByCategory: { try await service.fetchDuasByCategory(slug: $0) },
      searchDuas: { try await service.searchDuas(query: $0) },
      fetchAllCategories: { try await service.fetchAllCategories() },
      fetchCategory: { try await service.fetchCategory(id: $0) },
      fetchAllCollections: { try await service.fetchAllCollections() },
      fetchAllJourneys: { try await service.fetchAllJourneys() },
      fetchFeaturedJourneys: { try await service.fetchFeaturedJourneys() },
      fetchJourney: { try await service.fetchJourney(id: $0) },
      fetchJourneyBySlug: { try await service.fetchJourneyBySlug($0) },
      fetchJourneyDuas: { try await service.fetchJourneyDuas(journeyId: $0) },
      fetchJourneyWithDuas: { try await service.fetchJourneyWithDuas(id: $0) },
      fetchMultipleJourneysDuas: { try await service.fetchMultipleJourneysDuas(journeyIds: $0) },
      fetchUserProfile: { try await service.fetchUserProfile(userId: $0) },
      createUserProfile: { try await service.createUserProfile(userId: $0, displayName: $1) },
      updateUserProfile: { try await service.updateUserProfile($0) },
      addXp: { try await service.addXp(userId: $0, amount: $1) },
      fetchUserActivity: { try await service.fetchUserActivity(userId: $0, date: $1) },
      fetchWeekActivities: { try await service.fetchWeekActivities(userId: $0) },
      recordDuaCompletion: { try await service.recordDuaCompletion(userId: $0, duaId: $1, xpEarned: $2) }
    )
  }()

  static let testValue = NeonClient()
}

// MARK: - Dependency Values

extension DependencyValues {
  var neonClient: NeonClient {
    get { self[NeonClient.self] }
    set { self[NeonClient.self] = newValue }
  }
}
