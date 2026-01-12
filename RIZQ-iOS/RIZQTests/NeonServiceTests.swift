import XCTest
@testable import RIZQKit

// MARK: - DEPRECATED: Neon Service Tests
// ============================================================================
// These tests are DEPRECATED and kept for potential rollback.
// The app has migrated from Neon PostgreSQL to Firebase Firestore.
// MockNeonService is still available for backward compatibility testing.
//
// For new tests, use:
// - FirestoreUserClient for user data operations
// - FirestoreContentClient for content (duas, journeys, categories)
// - FirebaseAdminService for admin operations
// ============================================================================

final class NeonServiceTests: XCTestCase {

  // MARK: - MockNeonService Dua Tests

  func testMockFetchAllDuas() async throws {
    let service = MockNeonService()
    let duas = try await service.fetchAllDuas()

    XCTAssertFalse(duas.isEmpty)
    XCTAssertTrue(duas.allSatisfy { $0.id > 0 })
    XCTAssertTrue(duas.allSatisfy { !$0.titleEn.isEmpty })
    XCTAssertTrue(duas.allSatisfy { !$0.arabicText.isEmpty })
  }

  func testMockFetchDuaById() async throws {
    let service = MockNeonService()
    let allDuas = try await service.fetchAllDuas()

    guard let firstDua = allDuas.first else {
      XCTFail("No duas available for testing")
      return
    }

    let dua = try await service.fetchDua(id: firstDua.id)
    XCTAssertNotNil(dua)
    XCTAssertEqual(dua?.id, firstDua.id)
  }

  func testMockFetchDuaByIdNotFound() async throws {
    let service = MockNeonService()
    let dua = try await service.fetchDua(id: 9999)
    XCTAssertNil(dua)
  }

  func testMockFetchDuasByCategory() async throws {
    let service = MockNeonService()
    let allDuas = try await service.fetchAllDuas()

    // Find a category that has duas
    guard let categoryId = allDuas.first?.categoryId else {
      XCTFail("No duas with category available")
      return
    }

    let duas = try await service.fetchDuasByCategory(categoryId: categoryId)
    XCTAssertFalse(duas.isEmpty)
    XCTAssertTrue(duas.allSatisfy { $0.categoryId == categoryId })
  }

  func testMockFetchDuasByCategorySlug() async throws {
    let service = MockNeonService()
    let duas = try await service.fetchDuasByCategory(slug: .morning)

    // Morning category has categoryId 1
    XCTAssertTrue(duas.allSatisfy { $0.categoryId == 1 })
  }

  func testMockSearchDuas() async throws {
    let service = MockNeonService()
    let allDuas = try await service.fetchAllDuas()

    guard let firstDua = allDuas.first else {
      XCTFail("No duas available for testing")
      return
    }

    // Search for part of the first dua's title
    let searchTerm = String(firstDua.titleEn.prefix(4))
    let duas = try await service.searchDuas(query: searchTerm)

    XCTAssertFalse(duas.isEmpty)
    XCTAssertTrue(duas.allSatisfy {
      $0.titleEn.localizedCaseInsensitiveContains(searchTerm)
    })
  }

  func testMockSearchDuasNoResults() async throws {
    let service = MockNeonService()
    let duas = try await service.searchDuas(query: "xyznonexistent123")
    XCTAssertTrue(duas.isEmpty)
  }

  // MARK: - Category Tests

  func testMockFetchAllCategories() async throws {
    let service = MockNeonService()
    let categories = try await service.fetchAllCategories()

    XCTAssertFalse(categories.isEmpty)
    XCTAssertTrue(categories.allSatisfy { $0.id > 0 })
    XCTAssertTrue(categories.allSatisfy { !$0.name.isEmpty })
  }

  func testMockFetchCategoryById() async throws {
    let service = MockNeonService()
    let allCategories = try await service.fetchAllCategories()

    guard let firstCategory = allCategories.first else {
      XCTFail("No categories available for testing")
      return
    }

    let category = try await service.fetchCategory(id: firstCategory.id)
    XCTAssertNotNil(category)
    XCTAssertEqual(category?.id, firstCategory.id)
  }

  func testMockFetchCategoryByIdNotFound() async throws {
    let service = MockNeonService()
    let category = try await service.fetchCategory(id: 9999)
    XCTAssertNil(category)
  }

  // MARK: - Collection Tests

  func testMockFetchAllCollections() async throws {
    let service = MockNeonService()
    let collections = try await service.fetchAllCollections()

    XCTAssertFalse(collections.isEmpty)
    XCTAssertTrue(collections.allSatisfy { $0.id > 0 })
    XCTAssertTrue(collections.allSatisfy { !$0.name.isEmpty })
  }

  // MARK: - Journey Tests

  func testMockFetchAllJourneys() async throws {
    let service = MockNeonService()
    let journeys = try await service.fetchAllJourneys()

    XCTAssertFalse(journeys.isEmpty)
    XCTAssertTrue(journeys.allSatisfy { $0.id > 0 })
    XCTAssertTrue(journeys.allSatisfy { !$0.name.isEmpty })
  }

  func testMockFetchFeaturedJourneys() async throws {
    let service = MockNeonService()
    let journeys = try await service.fetchFeaturedJourneys()

    // Featured journeys should all have isFeatured = true
    XCTAssertTrue(journeys.allSatisfy { $0.isFeatured })
  }

  func testMockFetchJourneyById() async throws {
    let service = MockNeonService()
    let allJourneys = try await service.fetchAllJourneys()

    guard let firstJourney = allJourneys.first else {
      XCTFail("No journeys available for testing")
      return
    }

    let journey = try await service.fetchJourney(id: firstJourney.id)
    XCTAssertNotNil(journey)
    XCTAssertEqual(journey?.id, firstJourney.id)
  }

  func testMockFetchJourneyByIdNotFound() async throws {
    let service = MockNeonService()
    let journey = try await service.fetchJourney(id: 9999)
    XCTAssertNil(journey)
  }

  func testMockFetchJourneyBySlug() async throws {
    let service = MockNeonService()
    let allJourneys = try await service.fetchAllJourneys()

    guard let firstJourney = allJourneys.first else {
      XCTFail("No journeys available for testing")
      return
    }

    let journey = try await service.fetchJourneyBySlug(firstJourney.slug)
    XCTAssertNotNil(journey)
    XCTAssertEqual(journey?.slug, firstJourney.slug)
  }

  func testMockFetchJourneyDuas() async throws {
    let service = MockNeonService()
    let journeyDuas = try await service.fetchJourneyDuas(journeyId: 1)

    // Journey duas may be empty depending on sample data
    XCTAssertNotNil(journeyDuas)
  }

  func testMockFetchJourneyWithDuas() async throws {
    let service = MockNeonService()
    let allJourneys = try await service.fetchAllJourneys()

    guard let firstJourney = allJourneys.first else {
      XCTFail("No journeys available for testing")
      return
    }

    let journeyWithDuas = try await service.fetchJourneyWithDuas(id: firstJourney.id)
    XCTAssertNotNil(journeyWithDuas)
    XCTAssertEqual(journeyWithDuas?.journey.id, firstJourney.id)
  }

  func testMockFetchMultipleJourneysDuas() async throws {
    let service = MockNeonService()
    let journeyDuas = try await service.fetchMultipleJourneysDuas(journeyIds: [1, 2])

    // Should return without throwing
    XCTAssertNotNil(journeyDuas)
  }

  // MARK: - User Profile Tests (Mock behavior)

  func testMockFetchUserProfile() async throws {
    let service = MockNeonService()

    // MockNeonService always returns SampleData.userProfile regardless of userId
    let profile = try await service.fetchUserProfile(userId: "any-user-id")
    XCTAssertNotNil(profile)
  }

  func testMockCreateUserProfile() async throws {
    let service = MockNeonService()
    let userId = "new-user-456"
    let displayName = "New User"

    let profile = try await service.createUserProfile(userId: userId, displayName: displayName)

    XCTAssertEqual(profile.userId, userId)
    XCTAssertEqual(profile.displayName, displayName)
    XCTAssertEqual(profile.streak, 0)
    XCTAssertEqual(profile.totalXp, 0)
    XCTAssertEqual(profile.level, 1)
  }

  func testMockUpdateUserProfile() async throws {
    let service = MockNeonService()

    // Create a profile to update
    let profile = UserProfile(
      id: "test-id",
      userId: "test-user",
      displayName: "Test User",
      streak: 5,
      totalXp: 100,
      level: 2
    )

    // MockNeonService.updateUserProfile just returns the input profile unchanged
    let updatedProfile = try await service.updateUserProfile(profile)

    XCTAssertEqual(updatedProfile.displayName, profile.displayName)
    XCTAssertEqual(updatedProfile.streak, profile.streak)
    XCTAssertEqual(updatedProfile.totalXp, profile.totalXp)
  }

  func testMockAddXp() async throws {
    let service = MockNeonService()

    // MockNeonService.addXp uses SampleData.userProfile as base
    let profileBefore = try await service.fetchUserProfile(userId: "any")
    let xpBefore = profileBefore?.totalXp ?? 0

    let profileAfter = try await service.addXp(userId: "any", amount: 50)

    XCTAssertEqual(profileAfter.totalXp, xpBefore + 50)
  }

  // MARK: - User Activity Tests (Mock behavior)

  func testMockFetchUserActivity() async throws {
    let service = MockNeonService()

    // MockNeonService always returns nil for fetchUserActivity
    let activity = try await service.fetchUserActivity(userId: "any-user", date: Date())
    XCTAssertNil(activity)
  }

  func testMockFetchWeekActivities() async throws {
    let service = MockNeonService()

    // MockNeonService always returns empty array
    let activities = try await service.fetchWeekActivities(userId: "any-user")
    XCTAssertTrue(activities.isEmpty)
  }

  func testMockRecordDuaCompletion() async throws {
    let service = MockNeonService()

    // MockNeonService.recordDuaCompletion is a no-op, should not throw
    try await service.recordDuaCompletion(userId: "any-user", duaId: 1, xpEarned: 10)
    // Success if no error thrown
  }
}

// MARK: - NeonServiceProtocol Conformance Tests

final class NeonServiceProtocolTests: XCTestCase {

  func testProtocolConformance() async throws {
    // Verify MockNeonService conforms to NeonServiceProtocol
    let service: NeonServiceProtocol = MockNeonService()

    // All protocol methods should be callable without throwing
    _ = try await service.fetchAllDuas()
    _ = try await service.fetchDua(id: 1)
    _ = try await service.fetchDuasByCategory(categoryId: 1)
    _ = try await service.fetchDuasByCategory(slug: .morning)
    _ = try await service.searchDuas(query: "test")
    _ = try await service.fetchAllCategories()
    _ = try await service.fetchCategory(id: 1)
    _ = try await service.fetchAllCollections()
    _ = try await service.fetchAllJourneys()
    _ = try await service.fetchFeaturedJourneys()
    _ = try await service.fetchJourney(id: 1)
    _ = try await service.fetchJourneyBySlug("test")
    _ = try await service.fetchJourneyDuas(journeyId: 1)
    _ = try await service.fetchJourneyWithDuas(id: 1)
    _ = try await service.fetchMultipleJourneysDuas(journeyIds: [1])
    _ = try await service.fetchUserProfile(userId: "test")
    _ = try await service.createUserProfile(userId: "protocol-test", displayName: nil)
    _ = try await service.fetchUserActivity(userId: "test", date: Date())
    _ = try await service.fetchWeekActivities(userId: "test")
    try await service.recordDuaCompletion(userId: "test", duaId: 1, xpEarned: 10)
  }
}
