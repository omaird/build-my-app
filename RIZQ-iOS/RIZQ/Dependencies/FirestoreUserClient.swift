import ComposableArchitecture
import Foundation
import RIZQKit

/// TCA dependency client for Firestore user operations (profiles, activity, progress)
/// This client handles all user data operations, replacing NeonClient's user operations
struct FirestoreUserClient: Sendable {
  // MARK: - User Profile

  /// Fetch a user profile by userId. Returns nil if not found.
  var fetchUserProfile: @Sendable (_ userId: String) async throws -> UserProfile?

  /// Create a new user profile.
  var createUserProfile: @Sendable (_ userId: String, _ displayName: String?) async throws -> UserProfile

  /// Update an existing user profile.
  var updateUserProfile: @Sendable (_ profile: UserProfile) async throws -> UserProfile

  /// Get or create a user profile (fetches if exists, creates if not).
  var getOrCreateUserProfile: @Sendable (_ userId: String, _ displayName: String?) async throws -> UserProfile

  /// Add XP to a user, updating level and streak as needed.
  var addXp: @Sendable (_ userId: String, _ amount: Int) async throws -> UserProfile

  // MARK: - User Activity

  /// Fetch user activity for a specific date.
  var fetchUserActivity: @Sendable (_ userId: String, _ date: Date) async throws -> UserActivity?

  /// Fetch activities for the last 7 days.
  var fetchWeekActivities: @Sendable (_ userId: String) async throws -> [UserActivity]

  /// Record a dua completion for a user.
  var recordDuaCompletion: @Sendable (_ userId: String, _ duaId: Int, _ xpEarned: Int) async throws -> Void

  // MARK: - Batch Operations

  /// Record a complete practice session (activity + progress + XP).
  var recordPracticeCompletion: @Sendable (_ userId: String, _ duaId: Int, _ xp: Int) async throws -> UserProfile
}

// MARK: - Dependency Key

extension FirestoreUserClient: DependencyKey {
  /// Live implementation using FirebaseUserService
  static let liveValue: FirestoreUserClient = {
    let service = FirebaseUserService()
    return FirestoreUserClient(
      fetchUserProfile: { try await service.fetchUserProfile(userId: $0) },
      createUserProfile: { try await service.createUserProfile(userId: $0, displayName: $1) },
      updateUserProfile: { try await service.updateUserProfile($0) },
      getOrCreateUserProfile: { try await service.getOrCreateUserProfile(userId: $0, displayName: $1) },
      addXp: { try await service.addXp(userId: $0, amount: $1) },
      fetchUserActivity: { try await service.fetchUserActivity(userId: $0, date: $1) },
      fetchWeekActivities: { try await service.fetchWeekActivities(userId: $0) },
      recordDuaCompletion: { try await service.recordDuaCompletion(userId: $0, duaId: $1, xpEarned: $2) },
      recordPracticeCompletion: { try await service.recordPracticeCompletion(userId: $0, duaId: $1, xp: $2) }
    )
  }()

  /// Preview implementation with mock data
  static let previewValue: FirestoreUserClient = {
    let service = MockFirebaseUserService()
    return FirestoreUserClient(
      fetchUserProfile: { try await service.fetchUserProfile(userId: $0) },
      createUserProfile: { try await service.createUserProfile(userId: $0, displayName: $1) },
      updateUserProfile: { try await service.updateUserProfile($0) },
      getOrCreateUserProfile: { try await service.getOrCreateUserProfile(userId: $0, displayName: $1) },
      addXp: { try await service.addXp(userId: $0, amount: $1) },
      fetchUserActivity: { try await service.fetchUserActivity(userId: $0, date: $1) },
      fetchWeekActivities: { try await service.fetchWeekActivities(userId: $0) },
      recordDuaCompletion: { try await service.recordDuaCompletion(userId: $0, duaId: $1, xpEarned: $2) },
      recordPracticeCompletion: { try await service.recordPracticeCompletion(userId: $0, duaId: $1, xp: $2) }
    )
  }()

  /// Test implementation with minimal defaults (use withDependencies to inject custom behavior)
  static let testValue = FirestoreUserClient(
    fetchUserProfile: { _ in nil },
    createUserProfile: { userId, displayName in
      UserProfile(
        id: userId,
        userId: userId,
        displayName: displayName,
        streak: 0,
        totalXp: 0,
        level: 1,
        lastActiveDate: nil,
        isAdmin: false,
        createdAt: Date(),
        updatedAt: Date()
      )
    },
    updateUserProfile: { $0 },
    getOrCreateUserProfile: { userId, displayName in
      UserProfile(
        id: userId,
        userId: userId,
        displayName: displayName,
        streak: 0,
        totalXp: 0,
        level: 1,
        lastActiveDate: nil,
        isAdmin: false,
        createdAt: Date(),
        updatedAt: Date()
      )
    },
    addXp: { userId, amount in
      UserProfile(
        id: userId,
        userId: userId,
        displayName: nil,
        streak: 1,
        totalXp: amount,
        level: 1,
        lastActiveDate: Date(),
        isAdmin: false,
        createdAt: Date(),
        updatedAt: Date()
      )
    },
    fetchUserActivity: { _, _ in nil },
    fetchWeekActivities: { _ in [] },
    recordDuaCompletion: { _, _, _ in },
    recordPracticeCompletion: { userId, _, xp in
      UserProfile(
        id: userId,
        userId: userId,
        displayName: nil,
        streak: 1,
        totalXp: xp,
        level: 1,
        lastActiveDate: Date(),
        isAdmin: false,
        createdAt: Date(),
        updatedAt: Date()
      )
    }
  )
}

// MARK: - Dependency Values

extension DependencyValues {
  var firestoreUserClient: FirestoreUserClient {
    get { self[FirestoreUserClient.self] }
    set { self[FirestoreUserClient.self] = newValue }
  }
}
