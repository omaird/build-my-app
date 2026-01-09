import FirebaseFirestore
import Foundation

// MARK: - Firestore Content Service Protocol

/// Protocol for fetching content data (duas, categories, journeys) from Firestore
public protocol FirestoreContentServiceProtocol: Sendable {
  func fetchAllDuas() async throws -> [Dua]
  func fetchDuasByCategory(_ slug: CategorySlug) async throws -> [Dua]
  func fetchAllCategories() async throws -> [DuaCategory]
  func fetchAllJourneys() async throws -> [Journey]
  func fetchJourneyDuas(_ journeyId: Int) async throws -> [JourneyDua]
}

// MARK: - Live Implementation

/// Firestore service for fetching content data (duas, categories, journeys, collections)
/// This replaces the Neon database for read-only content that doesn't need user-specific data
public final class FirestoreContentService: FirestoreContentServiceProtocol, @unchecked Sendable {
  /// Lazy Firestore reference - ensures Firebase is configured before accessing
  private var db: Firestore {
    Firestore.firestore()
  }

  // Collection names matching Firestore structure
  private let duasCollection = "duas"
  private let categoriesCollection = "categories"
  private let collectionsCollection = "collections"
  private let journeysCollection = "journeys"
  private let journeyDuasCollection = "journey_duas"

  public init() {
    // Firestore is accessed lazily to ensure FirebaseApp.configure() has been called
  }

  // MARK: - Duas

  public func fetchAllDuas() async throws -> [Dua] {
    let snapshot = try await db.collection(duasCollection)
      .order(by: "id")
      .getDocuments()

    return snapshot.documents.compactMap { doc -> Dua? in
      try? mapDocumentToDua(doc.data(), documentId: doc.documentID)
    }
  }

  public func fetchDuasByCategory(_ slug: CategorySlug) async throws -> [Dua] {
    // First get the category ID for the given slug
    let categories = try await fetchAllCategories()
    guard let category = categories.first(where: { $0.slug == slug }) else {
      return []
    }

    let snapshot = try await db.collection(duasCollection)
      .whereField("categoryId", isEqualTo: category.id)
      .order(by: "id")
      .getDocuments()

    return snapshot.documents.compactMap { doc -> Dua? in
      try? mapDocumentToDua(doc.data(), documentId: doc.documentID)
    }
  }

  public func fetchDua(id: Int) async throws -> Dua? {
    let snapshot = try await db.collection(duasCollection)
      .whereField("id", isEqualTo: id)
      .limit(to: 1)
      .getDocuments()

    guard let doc = snapshot.documents.first else { return nil }
    return try? mapDocumentToDua(doc.data(), documentId: doc.documentID)
  }

  // MARK: - Categories

  public func fetchAllCategories() async throws -> [DuaCategory] {
    let snapshot = try await db.collection(categoriesCollection)
      .order(by: "id")
      .getDocuments()

    return snapshot.documents.compactMap { doc -> DuaCategory? in
      try? mapDocumentToCategory(doc.data(), documentId: doc.documentID)
    }
  }

  // MARK: - Collections

  public func fetchAllCollections() async throws -> [DuaCollection] {
    let snapshot = try await db.collection(collectionsCollection)
      .order(by: "id")
      .getDocuments()

    return snapshot.documents.compactMap { doc -> DuaCollection? in
      try? mapDocumentToCollection(doc.data(), documentId: doc.documentID)
    }
  }

  // MARK: - Journeys

  public func fetchAllJourneys() async throws -> [Journey] {
    let snapshot = try await db.collection(journeysCollection)
      .order(by: "sortOrder")
      .getDocuments()

    return snapshot.documents.compactMap { doc -> Journey? in
      try? mapDocumentToJourney(doc.data(), documentId: doc.documentID)
    }
  }

  public func fetchFeaturedJourneys() async throws -> [Journey] {
    let snapshot = try await db.collection(journeysCollection)
      .whereField("isFeatured", isEqualTo: true)
      .order(by: "sortOrder")
      .getDocuments()

    return snapshot.documents.compactMap { doc -> Journey? in
      try? mapDocumentToJourney(doc.data(), documentId: doc.documentID)
    }
  }

  public func fetchJourney(id: Int) async throws -> Journey? {
    let snapshot = try await db.collection(journeysCollection)
      .whereField("id", isEqualTo: id)
      .limit(to: 1)
      .getDocuments()

    guard let doc = snapshot.documents.first else { return nil }
    return try? mapDocumentToJourney(doc.data(), documentId: doc.documentID)
  }

  // MARK: - Journey Duas

  public func fetchJourneyDuas(_ journeyId: Int) async throws -> [JourneyDua] {
    let snapshot = try await db.collection(journeyDuasCollection)
      .whereField("journeyId", isEqualTo: journeyId)
      .order(by: "sortOrder")
      .getDocuments()

    return snapshot.documents.compactMap { doc -> JourneyDua? in
      try? mapDocumentToJourneyDua(doc.data(), documentId: doc.documentID)
    }
  }

  // MARK: - Mapping Functions

  private func mapDocumentToDua(_ data: [String: Any], documentId: String) throws -> Dua {
    guard let id = data["id"] as? Int,
          let titleEn = data["titleEn"] as? String,
          let arabicText = data["arabicText"] as? String,
          let translationEn = data["translationEn"] as? String
    else {
      throw FirestoreError.invalidData
    }

    return Dua(
      id: id,
      categoryId: data["categoryId"] as? Int,
      collectionId: data["collectionId"] as? Int,
      titleEn: titleEn,
      titleAr: data["titleAr"] as? String,
      arabicText: arabicText,
      transliteration: data["transliteration"] as? String,
      translationEn: translationEn,
      source: data["source"] as? String,
      repetitions: data["repetitions"] as? Int ?? 1,
      bestTime: data["bestTime"] as? String,
      difficulty: (data["difficulty"] as? String).flatMap { DuaDifficulty(rawValue: $0) },
      estDurationSec: data["estDurationSec"] as? Int,
      rizqBenefit: data["rizqBenefit"] as? String,
      propheticContext: data["propheticContext"] as? String,
      xpValue: data["xpValue"] as? Int ?? 10,
      audioUrl: data["audioUrl"] as? String,
      createdAt: (data["createdAt"] as? Timestamp)?.dateValue(),
      updatedAt: (data["updatedAt"] as? Timestamp)?.dateValue()
    )
  }

  private func mapDocumentToCategory(_ data: [String: Any], documentId: String) throws -> DuaCategory {
    guard let id = data["id"] as? Int,
          let name = data["name"] as? String,
          let slugString = data["slug"] as? String,
          let slug = CategorySlug(rawValue: slugString)
    else {
      throw FirestoreError.invalidData
    }

    return DuaCategory(
      id: id,
      name: name,
      slug: slug,
      description: data["description"] as? String
    )
  }

  private func mapDocumentToCollection(_ data: [String: Any], documentId: String) throws -> DuaCollection {
    guard let id = data["id"] as? Int,
          let name = data["name"] as? String,
          let slug = data["slug"] as? String
    else {
      throw FirestoreError.invalidData
    }

    return DuaCollection(
      id: id,
      name: name,
      slug: slug,
      description: data["description"] as? String,
      isPremium: data["is_premium"] as? Bool ?? false
    )
  }

  private func mapDocumentToJourney(_ data: [String: Any], documentId: String) throws -> Journey {
    guard let id = data["id"] as? Int,
          let name = data["name"] as? String,
          let slug = data["slug"] as? String
    else {
      throw FirestoreError.invalidData
    }

    return Journey(
      id: id,
      name: name,
      slug: slug,
      description: data["description"] as? String,
      emoji: data["emoji"] as? String ?? "📿",
      estimatedMinutes: data["estimatedMinutes"] as? Int ?? 10,
      dailyXp: data["dailyXp"] as? Int ?? 50,
      isPremium: data["isPremium"] as? Bool ?? false,
      isFeatured: data["isFeatured"] as? Bool ?? false,
      sortOrder: data["sortOrder"] as? Int ?? 0
    )
  }

  private func mapDocumentToJourneyDua(_ data: [String: Any], documentId: String) throws -> JourneyDua {
    guard let journeyId = data["journeyId"] as? Int,
          let duaId = data["duaId"] as? Int
    else {
      throw FirestoreError.invalidData
    }

    let timeSlotString = data["timeSlot"] as? String ?? "anytime"
    let timeSlot = TimeSlot(rawValue: timeSlotString) ?? .anytime

    return JourneyDua(
      journeyId: journeyId,
      duaId: duaId,
      timeSlot: timeSlot,
      sortOrder: data["sortOrder"] as? Int ?? 0
    )
  }
}

// MARK: - Mock Implementation for Testing/Preview

public final class MockFirestoreContentService: FirestoreContentServiceProtocol, @unchecked Sendable {
  public init() {}

  public func fetchAllDuas() async throws -> [Dua] {
    Dua.demoData
  }

  public func fetchDuasByCategory(_ slug: CategorySlug) async throws -> [Dua] {
    Dua.demoData.filter { dua in
      // Match by category ID based on slug
      switch slug {
      case .morning: return dua.categoryId == 1
      case .evening: return dua.categoryId == 2
      case .rizq: return dua.categoryId == 3
      case .gratitude: return dua.categoryId == 4
      }
    }
  }

  public func fetchAllCategories() async throws -> [DuaCategory] {
    DuaCategory.demoData
  }

  public func fetchAllJourneys() async throws -> [Journey] {
    []
  }

  public func fetchJourneyDuas(_ journeyId: Int) async throws -> [JourneyDua] {
    []
  }
}
