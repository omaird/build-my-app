import Foundation
import FirebaseFirestore
import os.log

private let logger = Logger(subsystem: "com.rizq.app", category: "FirebaseAdminService")

// MARK: - Firebase Admin Service

/// Admin service implementation using Firebase Firestore
/// Replaces the Neon-based AdminService for all admin operations
public actor FirebaseAdminService: AdminServiceProtocol {
  /// Lazy Firestore reference - ensures Firebase is configured before accessing
  private var db: Firestore {
    Firestore.firestore()
  }

  // Collection names
  private let duasCollection = "duas"
  private let categoriesCollection = "categories"
  private let collectionsCollection = "collections"
  private let journeysCollection = "journeys"
  private let journeyDuasCollection = "journey_duas"
  private let userProfilesCollection = "user_profiles"
  private let userActivityCollection = "user_activity"
  private let userProgressCollection = "user_progress"

  public init() {
    // Firestore is accessed lazily to ensure FirebaseApp.configure() has been called
  }

  // MARK: - Stats

  public func fetchAdminStats() async throws -> AdminStats {
    // Fetch counts in parallel
    async let duasCount = fetchCollectionCount(duasCollection)
    async let journeysCount = fetchCollectionCount(journeysCollection)
    async let categoriesCount = fetchCollectionCount(categoriesCollection)
    async let usersCount = fetchCollectionCount(userProfilesCollection)
    async let activeToday = fetchActiveUsersToday()

    return try await AdminStats(
      totalDuas: duasCount,
      totalJourneys: journeysCount,
      totalCategories: categoriesCount,
      totalUsers: usersCount,
      activeUsersToday: activeToday
    )
  }

  private func fetchCollectionCount(_ collection: String) async throws -> Int {
    let snapshot = try await db.collection(collection).getDocuments()
    return snapshot.documents.count
  }

  private func fetchActiveUsersToday() async throws -> Int {
    let today = dateString(from: Date())

    // Query all user_activity documents where the date subcollection has today's document
    // This is tricky with Firestore's structure - we need to check each user
    let usersSnapshot = try await db.collection(userProfilesCollection).getDocuments()
    var activeCount = 0

    for userDoc in usersSnapshot.documents {
      let userId = userDoc.documentID
      let activityDoc = try? await db.collection(userActivityCollection)
        .document(userId)
        .collection("dates")
        .document(today)
        .getDocument()

      if activityDoc?.exists == true {
        activeCount += 1
      }
    }

    return activeCount
  }

  // MARK: - Duas CRUD

  public func fetchAllDuasAdmin() async throws -> [Dua] {
    logger.info("Fetching all duas for admin")

    let snapshot = try await db.collection(duasCollection)
      .order(by: "id")
      .getDocuments()

    let duas = snapshot.documents.compactMap { doc -> Dua? in
      try? mapDocumentToDua(doc.data(), documentId: doc.documentID)
    }

    logger.info("Fetched \(duas.count) duas")
    return duas
  }

  public func createDua(_ input: DuaInput) async throws -> Dua {
    logger.info("Creating new dua: \(input.titleEn)")

    // Generate new ID (find max ID and increment)
    let maxId = try await fetchMaxId(collection: duasCollection)
    let newId = maxId + 1

    let now = Date()
    let data = mapDuaInputToDocument(input, id: newId, createdAt: now, updatedAt: now)

    let docRef = db.collection(duasCollection).document(String(newId))
    try await docRef.setData(data)

    logger.info("Created dua with ID \(newId)")

    return Dua(
      id: newId,
      categoryId: input.categoryId,
      collectionId: input.collectionId,
      titleEn: input.titleEn.trimmingCharacters(in: .whitespacesAndNewlines),
      titleAr: input.titleAr,
      arabicText: input.arabicText.trimmingCharacters(in: .whitespacesAndNewlines),
      transliteration: input.transliteration,
      translationEn: input.translationEn.trimmingCharacters(in: .whitespacesAndNewlines),
      source: input.source,
      repetitions: input.repetitions,
      bestTime: input.bestTime,
      difficulty: input.difficulty,
      estDurationSec: input.estDurationSec,
      rizqBenefit: input.rizqBenefit,
      propheticContext: input.propheticContext,
      xpValue: input.xpValue,
      audioUrl: input.audioUrl,
      createdAt: now,
      updatedAt: now
    )
  }

  public func updateDua(id: Int, input: DuaInput) async throws -> Dua {
    logger.info("Updating dua ID \(id)")

    let docRef = db.collection(duasCollection).document(String(id))
    let snapshot = try await docRef.getDocument()

    guard snapshot.exists else {
      logger.error("Dua not found: \(id)")
      throw FirebaseAdminError.notFound("Dua with ID \(id) not found")
    }

    let existingData = snapshot.data() ?? [:]
    let createdAt = (existingData["createdAt"] as? Timestamp)?.dateValue() ?? Date()
    let now = Date()

    let data = mapDuaInputToDocument(input, id: id, createdAt: createdAt, updatedAt: now)
    try await docRef.setData(data)

    logger.info("Updated dua ID \(id)")

    return Dua(
      id: id,
      categoryId: input.categoryId,
      collectionId: input.collectionId,
      titleEn: input.titleEn.trimmingCharacters(in: .whitespacesAndNewlines),
      titleAr: input.titleAr,
      arabicText: input.arabicText.trimmingCharacters(in: .whitespacesAndNewlines),
      transliteration: input.transliteration,
      translationEn: input.translationEn.trimmingCharacters(in: .whitespacesAndNewlines),
      source: input.source,
      repetitions: input.repetitions,
      bestTime: input.bestTime,
      difficulty: input.difficulty,
      estDurationSec: input.estDurationSec,
      rizqBenefit: input.rizqBenefit,
      propheticContext: input.propheticContext,
      xpValue: input.xpValue,
      audioUrl: input.audioUrl,
      createdAt: createdAt,
      updatedAt: now
    )
  }

  public func deleteDua(id: Int) async throws {
    logger.info("Deleting dua ID \(id)")

    // First remove from journey_duas
    let journeyDuasSnapshot = try await db.collection(journeyDuasCollection)
      .whereField("duaId", isEqualTo: id)
      .getDocuments()

    let batch = db.batch()

    for doc in journeyDuasSnapshot.documents {
      batch.deleteDocument(doc.reference)
    }

    // Delete the dua
    let duaRef = db.collection(duasCollection).document(String(id))
    batch.deleteDocument(duaRef)

    try await batch.commit()
    logger.info("Deleted dua ID \(id) and associated journey_duas")
  }

  // MARK: - Journeys CRUD

  public func fetchAllJourneysAdmin() async throws -> [Journey] {
    logger.info("Fetching all journeys for admin")

    let snapshot = try await db.collection(journeysCollection)
      .order(by: "sortOrder")
      .getDocuments()

    let journeys = snapshot.documents.compactMap { doc -> Journey? in
      try? mapDocumentToJourney(doc.data(), documentId: doc.documentID)
    }

    logger.info("Fetched \(journeys.count) journeys")
    return journeys
  }

  public func createJourney(_ input: JourneyInput) async throws -> Journey {
    logger.info("Creating new journey: \(input.name)")

    let maxId = try await fetchMaxId(collection: journeysCollection)
    let newId = maxId + 1

    let data = mapJourneyInputToDocument(input, id: newId)

    let docRef = db.collection(journeysCollection).document(String(newId))
    try await docRef.setData(data)

    logger.info("Created journey with ID \(newId)")

    return Journey(
      id: newId,
      name: input.name.trimmingCharacters(in: .whitespacesAndNewlines),
      slug: input.slug.trimmingCharacters(in: .whitespacesAndNewlines),
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
    logger.info("Updating journey ID \(id)")

    let docRef = db.collection(journeysCollection).document(String(id))
    let snapshot = try await docRef.getDocument()

    guard snapshot.exists else {
      logger.error("Journey not found: \(id)")
      throw FirebaseAdminError.notFound("Journey with ID \(id) not found")
    }

    let data = mapJourneyInputToDocument(input, id: id)
    try await docRef.setData(data)

    logger.info("Updated journey ID \(id)")

    return Journey(
      id: id,
      name: input.name.trimmingCharacters(in: .whitespacesAndNewlines),
      slug: input.slug.trimmingCharacters(in: .whitespacesAndNewlines),
      description: input.description,
      emoji: input.emoji,
      estimatedMinutes: input.estimatedMinutes,
      dailyXp: input.dailyXp,
      isPremium: input.isPremium,
      isFeatured: input.isFeatured,
      sortOrder: input.sortOrder
    )
  }

  public func deleteJourney(id: Int) async throws {
    logger.info("Deleting journey ID \(id)")

    // First remove all journey_duas
    let journeyDuasSnapshot = try await db.collection(journeyDuasCollection)
      .whereField("journeyId", isEqualTo: id)
      .getDocuments()

    let batch = db.batch()

    for doc in journeyDuasSnapshot.documents {
      batch.deleteDocument(doc.reference)
    }

    // Delete the journey
    let journeyRef = db.collection(journeysCollection).document(String(id))
    batch.deleteDocument(journeyRef)

    try await batch.commit()
    logger.info("Deleted journey ID \(id) and associated journey_duas")
  }

  // MARK: - Journey Duas

  public func fetchJourneyDuasAdmin(journeyId: Int) async throws -> [JourneyDua] {
    logger.info("Fetching journey duas for journey ID \(journeyId)")

    let snapshot = try await db.collection(journeyDuasCollection)
      .whereField("journeyId", isEqualTo: journeyId)
      .order(by: "sortOrder")
      .getDocuments()

    let journeyDuas = snapshot.documents.compactMap { doc -> JourneyDua? in
      try? mapDocumentToJourneyDua(doc.data(), documentId: doc.documentID)
    }

    logger.info("Fetched \(journeyDuas.count) journey duas")
    return journeyDuas
  }

  public func addDuaToJourney(journeyId: Int, duaId: Int, timeSlot: TimeSlot, sortOrder: Int) async throws {
    logger.info("Adding dua \(duaId) to journey \(journeyId)")

    // Use composite document ID for upsert behavior
    let docId = "\(journeyId)_\(duaId)"
    let docRef = db.collection(journeyDuasCollection).document(docId)

    let data: [String: Any] = [
      "journeyId": journeyId,
      "duaId": duaId,
      "timeSlot": timeSlot.rawValue,
      "sortOrder": sortOrder
    ]

    try await docRef.setData(data)
    logger.info("Added dua \(duaId) to journey \(journeyId)")
  }

  public func removeDuaFromJourney(journeyId: Int, duaId: Int) async throws {
    logger.info("Removing dua \(duaId) from journey \(journeyId)")

    let docId = "\(journeyId)_\(duaId)"
    let docRef = db.collection(journeyDuasCollection).document(docId)

    try await docRef.delete()
    logger.info("Removed dua \(duaId) from journey \(journeyId)")
  }

  public func updateJourneyDuaOrder(journeyId: Int, duaId: Int, sortOrder: Int) async throws {
    logger.info("Updating order for dua \(duaId) in journey \(journeyId)")

    let docId = "\(journeyId)_\(duaId)"
    let docRef = db.collection(journeyDuasCollection).document(docId)

    try await docRef.updateData(["sortOrder": sortOrder])
    logger.info("Updated order for dua \(duaId) in journey \(journeyId)")
  }

  // MARK: - Categories CRUD

  public func fetchAllCategoriesAdmin() async throws -> [DuaCategory] {
    logger.info("Fetching all categories for admin")

    let snapshot = try await db.collection(categoriesCollection)
      .order(by: "id")
      .getDocuments()

    let categories = snapshot.documents.compactMap { doc -> DuaCategory? in
      try? mapDocumentToCategory(doc.data(), documentId: doc.documentID)
    }

    logger.info("Fetched \(categories.count) categories")
    return categories
  }

  public func createCategory(_ input: CategoryInput) async throws -> DuaCategory {
    logger.info("Creating new category: \(input.name)")

    let maxId = try await fetchMaxId(collection: categoriesCollection)
    let newId = maxId + 1

    let data = mapCategoryInputToDocument(input, id: newId)

    let docRef = db.collection(categoriesCollection).document(String(newId))
    try await docRef.setData(data)

    logger.info("Created category with ID \(newId)")

    return DuaCategory(
      id: newId,
      name: input.name.trimmingCharacters(in: .whitespacesAndNewlines),
      slug: input.slug,
      description: input.description
    )
  }

  public func updateCategory(id: Int, input: CategoryInput) async throws -> DuaCategory {
    logger.info("Updating category ID \(id)")

    let docRef = db.collection(categoriesCollection).document(String(id))
    let snapshot = try await docRef.getDocument()

    guard snapshot.exists else {
      logger.error("Category not found: \(id)")
      throw FirebaseAdminError.notFound("Category with ID \(id) not found")
    }

    let data = mapCategoryInputToDocument(input, id: id)
    try await docRef.setData(data)

    logger.info("Updated category ID \(id)")

    return DuaCategory(
      id: id,
      name: input.name.trimmingCharacters(in: .whitespacesAndNewlines),
      slug: input.slug,
      description: input.description
    )
  }

  public func deleteCategory(id: Int) async throws {
    logger.info("Deleting category ID \(id)")

    // Set category_id to null for duas in this category
    let duasSnapshot = try await db.collection(duasCollection)
      .whereField("categoryId", isEqualTo: id)
      .getDocuments()

    let batch = db.batch()

    for doc in duasSnapshot.documents {
      batch.updateData(["categoryId": FieldValue.delete()], forDocument: doc.reference)
    }

    // Delete the category
    let categoryRef = db.collection(categoriesCollection).document(String(id))
    batch.deleteDocument(categoryRef)

    try await batch.commit()
    logger.info("Deleted category ID \(id)")
  }

  // MARK: - Users

  public func fetchAllUsersAdmin() async throws -> [UserProfile] {
    logger.info("Fetching all users for admin")

    let snapshot = try await db.collection(userProfilesCollection)
      .order(by: "createdAt", descending: true)
      .getDocuments()

    let users = snapshot.documents.compactMap { doc -> UserProfile? in
      try? mapDocumentToUserProfile(doc.data(), userId: doc.documentID)
    }

    logger.info("Fetched \(users.count) users")
    return users
  }

  public func updateUserAdmin(userId: String, isAdmin: Bool) async throws -> UserProfile {
    logger.info("Updating admin status for user \(userId) to \(isAdmin)")

    let docRef = db.collection(userProfilesCollection).document(userId)
    let snapshot = try await docRef.getDocument()

    guard snapshot.exists, let data = snapshot.data() else {
      logger.error("User not found: \(userId)")
      throw FirebaseAdminError.notFound("User with ID \(userId) not found")
    }

    let now = Date()
    try await docRef.updateData([
      "isAdmin": isAdmin,
      "updatedAt": Timestamp(date: now)
    ])

    logger.info("Updated admin status for user \(userId)")

    // Return updated profile
    var updatedData = data
    updatedData["isAdmin"] = isAdmin
    updatedData["updatedAt"] = Timestamp(date: now)

    return try mapDocumentToUserProfile(updatedData, userId: userId)
  }

  public func updateUserPremium(userId: String, isPremium: Bool) async throws -> UserProfile {
    logger.info("Updating premium status for user \(userId) to \(isPremium)")

    let docRef = db.collection(userProfilesCollection).document(userId)
    let snapshot = try await docRef.getDocument()

    guard snapshot.exists, let data = snapshot.data() else {
      logger.error("User not found: \(userId)")
      throw FirebaseAdminError.notFound("User with ID \(userId) not found")
    }

    let now = Date()
    try await docRef.updateData([
      "isPremium": isPremium,
      "updatedAt": Timestamp(date: now)
    ])

    logger.info("Updated premium status for user \(userId)")

    // Return updated profile
    var updatedData = data
    updatedData["isPremium"] = isPremium
    updatedData["updatedAt"] = Timestamp(date: now)

    return try mapDocumentToUserProfile(updatedData, userId: userId)
  }

  public func deleteUserAdmin(userId: String) async throws {
    logger.info("Deleting user \(userId) and all associated data")

    let batch = db.batch()

    // Delete user activity dates subcollection
    let activityDatesSnapshot = try await db.collection(userActivityCollection)
      .document(userId)
      .collection("dates")
      .getDocuments()

    for doc in activityDatesSnapshot.documents {
      batch.deleteDocument(doc.reference)
    }

    // Delete user activity document
    let activityRef = db.collection(userActivityCollection).document(userId)
    batch.deleteDocument(activityRef)

    // Delete user progress duas subcollection
    let progressDuasSnapshot = try await db.collection(userProgressCollection)
      .document(userId)
      .collection("duas")
      .getDocuments()

    for doc in progressDuasSnapshot.documents {
      batch.deleteDocument(doc.reference)
    }

    // Delete user progress document
    let progressRef = db.collection(userProgressCollection).document(userId)
    batch.deleteDocument(progressRef)

    // Delete user profile
    let profileRef = db.collection(userProfilesCollection).document(userId)
    batch.deleteDocument(profileRef)

    try await batch.commit()
    logger.info("Deleted user \(userId) and all associated data")
  }

  // MARK: - Helper Methods

  private func fetchMaxId(collection: String) async throws -> Int {
    let snapshot = try await db.collection(collection)
      .order(by: "id", descending: true)
      .limit(to: 1)
      .getDocuments()

    if let doc = snapshot.documents.first,
       let id = doc.data()["id"] as? Int {
      return id
    }
    return 0
  }

  private static let dateFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateFormat = "yyyy-MM-dd"
    formatter.timeZone = TimeZone.current
    return formatter
  }()

  private func dateString(from date: Date) -> String {
    Self.dateFormatter.string(from: date)
  }

  // MARK: - Document Mapping

  private func mapDocumentToDua(_ data: [String: Any], documentId: String) throws -> Dua {
    guard let id = data["id"] as? Int,
          let titleEn = data["titleEn"] as? String,
          let arabicText = data["arabicText"] as? String,
          let translationEn = data["translationEn"] as? String
    else {
      throw FirebaseAdminError.invalidData("Invalid dua document: \(documentId)")
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

  private func mapDuaInputToDocument(_ input: DuaInput, id: Int, createdAt: Date, updatedAt: Date) -> [String: Any] {
    var doc: [String: Any] = [
      "id": id,
      "titleEn": input.titleEn.trimmingCharacters(in: .whitespacesAndNewlines),
      "arabicText": input.arabicText.trimmingCharacters(in: .whitespacesAndNewlines),
      "translationEn": input.translationEn.trimmingCharacters(in: .whitespacesAndNewlines),
      "repetitions": input.repetitions,
      "xpValue": input.xpValue,
      "createdAt": Timestamp(date: createdAt),
      "updatedAt": Timestamp(date: updatedAt)
    ]

    if let categoryId = input.categoryId { doc["categoryId"] = categoryId }
    if let collectionId = input.collectionId { doc["collectionId"] = collectionId }
    if let titleAr = input.titleAr { doc["titleAr"] = titleAr }
    if let transliteration = input.transliteration { doc["transliteration"] = transliteration }
    if let source = input.source { doc["source"] = source }
    if let bestTime = input.bestTime { doc["bestTime"] = bestTime }
    if let difficulty = input.difficulty { doc["difficulty"] = difficulty.rawValue }
    if let estDurationSec = input.estDurationSec { doc["estDurationSec"] = estDurationSec }
    if let rizqBenefit = input.rizqBenefit { doc["rizqBenefit"] = rizqBenefit }
    if let propheticContext = input.propheticContext { doc["propheticContext"] = propheticContext }
    if let audioUrl = input.audioUrl { doc["audioUrl"] = audioUrl }

    return doc
  }

  private func mapDocumentToJourney(_ data: [String: Any], documentId: String) throws -> Journey {
    guard let id = data["id"] as? Int,
          let name = data["name"] as? String,
          let slug = data["slug"] as? String
    else {
      throw FirebaseAdminError.invalidData("Invalid journey document: \(documentId)")
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

  private func mapJourneyInputToDocument(_ input: JourneyInput, id: Int) -> [String: Any] {
    var doc: [String: Any] = [
      "id": id,
      "name": input.name.trimmingCharacters(in: .whitespacesAndNewlines),
      "slug": input.slug.trimmingCharacters(in: .whitespacesAndNewlines),
      "emoji": input.emoji,
      "estimatedMinutes": input.estimatedMinutes,
      "dailyXp": input.dailyXp,
      "isPremium": input.isPremium,
      "isFeatured": input.isFeatured,
      "sortOrder": input.sortOrder
    ]

    if let description = input.description { doc["description"] = description }

    return doc
  }

  private func mapDocumentToJourneyDua(_ data: [String: Any], documentId: String) throws -> JourneyDua {
    guard let journeyId = data["journeyId"] as? Int,
          let duaId = data["duaId"] as? Int
    else {
      throw FirebaseAdminError.invalidData("Invalid journey_dua document: \(documentId)")
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

  private func mapDocumentToCategory(_ data: [String: Any], documentId: String) throws -> DuaCategory {
    guard let id = data["id"] as? Int,
          let name = data["name"] as? String,
          let slugString = data["slug"] as? String,
          let slug = CategorySlug(rawValue: slugString)
    else {
      throw FirebaseAdminError.invalidData("Invalid category document: \(documentId)")
    }

    return DuaCategory(
      id: id,
      name: name,
      slug: slug,
      description: data["description"] as? String
    )
  }

  private func mapCategoryInputToDocument(_ input: CategoryInput, id: Int) -> [String: Any] {
    var doc: [String: Any] = [
      "id": id,
      "name": input.name.trimmingCharacters(in: .whitespacesAndNewlines),
      "slug": input.slug.rawValue
    ]

    if let description = input.description { doc["description"] = description }

    return doc
  }

  private func mapDocumentToUserProfile(_ data: [String: Any], userId: String) throws -> UserProfile {
    return UserProfile(
      id: userId,
      userId: userId,
      displayName: data["displayName"] as? String,
      email: data["email"] as? String,
      streak: data["streak"] as? Int ?? 0,
      totalXp: data["totalXp"] as? Int ?? 0,
      level: data["level"] as? Int ?? 1,
      lastActiveDate: (data["lastActiveDate"] as? Timestamp)?.dateValue(),
      isAdmin: data["isAdmin"] as? Bool ?? false,
      isPremium: data["isPremium"] as? Bool ?? false,
      createdAt: (data["createdAt"] as? Timestamp)?.dateValue() ?? Date(),
      updatedAt: (data["updatedAt"] as? Timestamp)?.dateValue() ?? Date()
    )
  }
}

// MARK: - Firebase Admin Errors

public enum FirebaseAdminError: Error, LocalizedError {
  case notFound(String)
  case invalidData(String)
  case operationFailed(String)

  public var errorDescription: String? {
    switch self {
    case .notFound(let message):
      return "Not found: \(message)"
    case .invalidData(let message):
      return "Invalid data: \(message)"
    case .operationFailed(let message):
      return "Operation failed: \(message)"
    }
  }
}
