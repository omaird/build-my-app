import ComposableArchitecture
import Foundation
import RIZQKit

/// TCA dependency client for Firestore content operations (duas, categories, journeys)
/// This client fetches read-only content data from Firestore, replacing the Neon database for content
struct FirestoreContentClient: Sendable {
  // MARK: - Duas

  var fetchAllDuas: @Sendable () async throws -> [Dua]
  var fetchDuasByCategory: @Sendable (_ slug: CategorySlug) async throws -> [Dua]

  // MARK: - Categories

  var fetchAllCategories: @Sendable () async throws -> [DuaCategory]

  // MARK: - Journeys

  var fetchAllJourneys: @Sendable () async throws -> [Journey]
  var fetchJourneyDuas: @Sendable (_ journeyId: Int) async throws -> [JourneyDua]
}

// MARK: - Dependency Key

extension FirestoreContentClient: DependencyKey {
  /// Live implementation using FirestoreContentService
  static let liveValue: FirestoreContentClient = {
    let service = FirestoreContentService()
    return FirestoreContentClient(
      fetchAllDuas: { try await service.fetchAllDuas() },
      fetchDuasByCategory: { try await service.fetchDuasByCategory($0) },
      fetchAllCategories: { try await service.fetchAllCategories() },
      fetchAllJourneys: { try await service.fetchAllJourneys() },
      fetchJourneyDuas: { try await service.fetchJourneyDuas($0) }
    )
  }()

  /// Preview implementation with demo data
  static let previewValue: FirestoreContentClient = {
    let service = MockFirestoreContentService()
    return FirestoreContentClient(
      fetchAllDuas: { try await service.fetchAllDuas() },
      fetchDuasByCategory: { try await service.fetchDuasByCategory($0) },
      fetchAllCategories: { try await service.fetchAllCategories() },
      fetchAllJourneys: { try await service.fetchAllJourneys() },
      fetchJourneyDuas: { try await service.fetchJourneyDuas($0) }
    )
  }()

  /// Test implementation with empty defaults (use withDependencies to inject)
  static let testValue = FirestoreContentClient(
    fetchAllDuas: { [] },
    fetchDuasByCategory: { _ in [] },
    fetchAllCategories: { [] },
    fetchAllJourneys: { [] },
    fetchJourneyDuas: { _ in [] }
  )
}

// MARK: - Dependency Values

extension DependencyValues {
  var firestoreContentClient: FirestoreContentClient {
    get { self[FirestoreContentClient.self] }
    set { self[FirestoreContentClient.self] = newValue }
  }
}
