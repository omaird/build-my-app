import Foundation
import FirebaseFirestore

// MARK: - Firestore Models

public struct FirestoreUserProfile: Codable, Sendable {
  public let userId: String
  public var displayName: String?
  public var streak: Int
  public var totalXp: Int
  public var level: Int
  public var lastActiveDate: Date?
  public var isAdmin: Bool
  public let createdAt: Date
  public var updatedAt: Date

  public init(
    userId: String,
    displayName: String? = nil,
    streak: Int = 0,
    totalXp: Int = 0,
    level: Int = 1,
    lastActiveDate: Date? = nil,
    isAdmin: Bool = false,
    createdAt: Date = Date(),
    updatedAt: Date = Date()
  ) {
    self.userId = userId
    self.displayName = displayName
    self.streak = streak
    self.totalXp = totalXp
    self.level = level
    self.lastActiveDate = lastActiveDate
    self.isAdmin = isAdmin
    self.createdAt = createdAt
    self.updatedAt = updatedAt
  }
}

public struct FirestoreUserActivity: Codable, Sendable {
  public let userId: String
  public let date: String // YYYY-MM-DD format
  public var duasCompleted: [Int]
  public var xpEarned: Int

  public init(userId: String, date: String, duasCompleted: [Int] = [], xpEarned: Int = 0) {
    self.userId = userId
    self.date = date
    self.duasCompleted = duasCompleted
    self.xpEarned = xpEarned
  }
}

public struct FirestoreUserProgress: Codable, Sendable {
  public let userId: String
  public let duaId: Int
  public var completedCount: Int
  public var lastCompleted: Date?

  public init(userId: String, duaId: Int, completedCount: Int = 0, lastCompleted: Date? = nil) {
    self.userId = userId
    self.duaId = duaId
    self.completedCount = completedCount
    self.lastCompleted = lastCompleted
  }
}

// MARK: - Firestore Service

public actor FirestoreService {
  private let db: Firestore

  // Collection names
  private let userProfilesCollection = "user_profiles"
  private let userActivityCollection = "user_activity"
  private let userProgressCollection = "user_progress"

  public init() {
    self.db = Firestore.firestore()
  }

  // MARK: - Date Formatting

  private static let dateFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateFormat = "yyyy-MM-dd"
    formatter.timeZone = TimeZone.current
    return formatter
  }()

  private func dateString(from date: Date) -> String {
    Self.dateFormatter.string(from: date)
  }

  // MARK: - User Profile Operations

  public func fetchUserProfile(userId: String) async throws -> FirestoreUserProfile? {
    let docRef = db.collection(userProfilesCollection).document(userId)
    let snapshot = try await docRef.getDocument()

    guard snapshot.exists, let data = snapshot.data() else {
      return nil
    }

    return try mapDocumentToUserProfile(data, userId: userId)
  }

  public func createUserProfile(userId: String, displayName: String?) async throws -> FirestoreUserProfile {
    let profile = FirestoreUserProfile(
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

    let docRef = db.collection(userProfilesCollection).document(userId)
    try await docRef.setData(mapUserProfileToDocument(profile))

    return profile
  }

  public func updateUserProfile(_ profile: FirestoreUserProfile) async throws -> FirestoreUserProfile {
    var updatedProfile = profile
    updatedProfile.updatedAt = Date()

    let docRef = db.collection(userProfilesCollection).document(profile.userId)
    try await docRef.setData(mapUserProfileToDocument(updatedProfile), merge: true)

    return updatedProfile
  }

  public func getOrCreateUserProfile(userId: String, displayName: String?) async throws -> FirestoreUserProfile {
    if let existing = try await fetchUserProfile(userId: userId) {
      return existing
    }
    return try await createUserProfile(userId: userId, displayName: displayName)
  }

  public func addXp(userId: String, amount: Int) async throws -> FirestoreUserProfile {
    guard var profile = try await fetchUserProfile(userId: userId) else {
      throw FirestoreError.userNotFound
    }

    profile.totalXp += amount
    profile.level = calculateLevel(xp: profile.totalXp)

    // Update streak if active today
    let today = dateString(from: Date())
    let lastActive = profile.lastActiveDate.map { dateString(from: $0) }

    if lastActive != today {
      let yesterday = dateString(from: Date().addingTimeInterval(-86400))
      if lastActive == yesterday {
        profile.streak += 1
      } else if lastActive != today {
        profile.streak = 1
      }
      profile.lastActiveDate = Date()
    }

    return try await updateUserProfile(profile)
  }

  // MARK: - User Activity Operations

  public func fetchUserActivity(userId: String, date: Date) async throws -> FirestoreUserActivity? {
    let dateStr = dateString(from: date)
    let docRef = db.collection(userActivityCollection)
      .document(userId)
      .collection("dates")
      .document(dateStr)

    let snapshot = try await docRef.getDocument()

    guard snapshot.exists, let data = snapshot.data() else {
      return nil
    }

    return FirestoreUserActivity(
      userId: userId,
      date: dateStr,
      duasCompleted: data["duasCompleted"] as? [Int] ?? [],
      xpEarned: data["xpEarned"] as? Int ?? 0
    )
  }

  public func recordDuaCompletion(userId: String, duaId: Int, xp: Int) async throws {
    let today = dateString(from: Date())
    let docRef = db.collection(userActivityCollection)
      .document(userId)
      .collection("dates")
      .document(today)

    try await db.runTransaction { transaction, errorPointer in
      do {
        let snapshot = try transaction.getDocument(docRef)

        var duasCompleted = snapshot.data()?["duasCompleted"] as? [Int] ?? []
        var xpEarned = snapshot.data()?["xpEarned"] as? Int ?? 0

        if !duasCompleted.contains(duaId) {
          duasCompleted.append(duaId)
        }
        xpEarned += xp

        transaction.setData([
          "userId": userId,
          "date": today,
          "duasCompleted": duasCompleted,
          "xpEarned": xpEarned
        ], forDocument: docRef, merge: true)

        return nil
      } catch {
        errorPointer?.pointee = error as NSError
        return nil
      }
    }
  }

  public func getTodayActivity(userId: String) async throws -> FirestoreUserActivity {
    let today = Date()
    if let activity = try await fetchUserActivity(userId: userId, date: today) {
      return activity
    }
    return FirestoreUserActivity(userId: userId, date: dateString(from: today))
  }

  // MARK: - User Progress Operations

  public func fetchUserProgress(userId: String) async throws -> [FirestoreUserProgress] {
    let snapshot = try await db.collection(userProgressCollection)
      .document(userId)
      .collection("duas")
      .getDocuments()

    return snapshot.documents.compactMap { doc -> FirestoreUserProgress? in
      guard let duaId = Int(doc.documentID) else { return nil }
      let data = doc.data()
      return FirestoreUserProgress(
        userId: userId,
        duaId: duaId,
        completedCount: data["completedCount"] as? Int ?? 0,
        lastCompleted: (data["lastCompleted"] as? Timestamp)?.dateValue()
      )
    }
  }

  public func fetchDuaProgress(userId: String, duaId: Int) async throws -> FirestoreUserProgress? {
    let docRef = db.collection(userProgressCollection)
      .document(userId)
      .collection("duas")
      .document(String(duaId))

    let snapshot = try await docRef.getDocument()

    guard snapshot.exists, let data = snapshot.data() else {
      return nil
    }

    return FirestoreUserProgress(
      userId: userId,
      duaId: duaId,
      completedCount: data["completedCount"] as? Int ?? 0,
      lastCompleted: (data["lastCompleted"] as? Timestamp)?.dateValue()
    )
  }

  public func updateDuaProgress(userId: String, duaId: Int) async throws {
    let docRef = db.collection(userProgressCollection)
      .document(userId)
      .collection("duas")
      .document(String(duaId))

    try await db.runTransaction { transaction, errorPointer in
      do {
        let snapshot = try transaction.getDocument(docRef)
        let currentCount = snapshot.data()?["completedCount"] as? Int ?? 0

        transaction.setData([
          "userId": userId,
          "duaId": duaId,
          "completedCount": currentCount + 1,
          "lastCompleted": Timestamp(date: Date())
        ], forDocument: docRef, merge: true)

        return nil
      } catch {
        errorPointer?.pointee = error as NSError
        return nil
      }
    }
  }

  // MARK: - Batch Operations

  public func recordPracticeCompletion(userId: String, duaId: Int, xp: Int) async throws -> FirestoreUserProfile {
    // Update activity, progress, and XP atomically
    try await recordDuaCompletion(userId: userId, duaId: duaId, xp: xp)
    try await updateDuaProgress(userId: userId, duaId: duaId)
    return try await addXp(userId: userId, amount: xp)
  }

  // MARK: - Helper Methods

  private func mapDocumentToUserProfile(_ data: [String: Any], userId: String) throws -> FirestoreUserProfile {
    FirestoreUserProfile(
      userId: userId,
      displayName: data["displayName"] as? String,
      streak: data["streak"] as? Int ?? 0,
      totalXp: data["totalXp"] as? Int ?? 0,
      level: data["level"] as? Int ?? 1,
      lastActiveDate: (data["lastActiveDate"] as? Timestamp)?.dateValue(),
      isAdmin: data["isAdmin"] as? Bool ?? false,
      createdAt: (data["createdAt"] as? Timestamp)?.dateValue() ?? Date(),
      updatedAt: (data["updatedAt"] as? Timestamp)?.dateValue() ?? Date()
    )
  }

  private func mapUserProfileToDocument(_ profile: FirestoreUserProfile) -> [String: Any] {
    var doc: [String: Any] = [
      "userId": profile.userId,
      "streak": profile.streak,
      "totalXp": profile.totalXp,
      "level": profile.level,
      "isAdmin": profile.isAdmin,
      "createdAt": Timestamp(date: profile.createdAt),
      "updatedAt": Timestamp(date: profile.updatedAt)
    ]

    if let displayName = profile.displayName {
      doc["displayName"] = displayName
    }

    if let lastActiveDate = profile.lastActiveDate {
      doc["lastActiveDate"] = Timestamp(date: lastActiveDate)
    }

    return doc
  }

  private func calculateLevel(xp: Int) -> Int {
    // Level threshold formula: 50 * level^2 + 50 * level
    // Level 1: 0-100 XP, Level 2: 100-300 XP, Level 3: 300-600 XP, etc.
    var level = 1
    while 50 * level * level + 50 * level <= xp {
      level += 1
    }
    return level
  }
}

// MARK: - Firestore Errors

public enum FirestoreError: Error, LocalizedError {
  case userNotFound
  case documentNotFound
  case invalidData
  case transactionFailed(String)

  public var errorDescription: String? {
    switch self {
    case .userNotFound:
      return "User profile not found"
    case .documentNotFound:
      return "Document not found"
    case .invalidData:
      return "Invalid data format"
    case .transactionFailed(let message):
      return "Transaction failed: \(message)"
    }
  }
}
