import Foundation
import FirebaseFirestore
import os.log

private let logger = Logger(subsystem: "com.rizq.app", category: "FirebaseUserService")

// MARK: - Firebase User Service Protocol

/// Protocol defining all user-related operations backed by Firebase Firestore.
/// This replaces the user operations previously handled by NeonService.
public protocol FirebaseUserServiceProtocol: Sendable {
  // MARK: - User Profile

  /// Fetch a user profile by userId. Returns nil if not found.
  func fetchUserProfile(userId: String) async throws -> UserProfile?

  /// Create a new user profile with the given userId and optional display name.
  func createUserProfile(userId: String, displayName: String?) async throws -> UserProfile

  /// Update an existing user profile.
  func updateUserProfile(_ profile: UserProfile) async throws -> UserProfile

  /// Get or create a user profile (fetches if exists, creates if not).
  func getOrCreateUserProfile(userId: String, displayName: String?) async throws -> UserProfile

  /// Add XP to a user's profile, updating level and streak as needed.
  func addXp(userId: String, amount: Int) async throws -> UserProfile

  // MARK: - User Activity

  /// Fetch user activity for a specific date.
  func fetchUserActivity(userId: String, date: Date) async throws -> UserActivity?

  /// Fetch activities for the last 7 days.
  func fetchWeekActivities(userId: String) async throws -> [UserActivity]

  /// Get today's activity (creates empty one if doesn't exist).
  func getTodayActivity(userId: String) async throws -> UserActivity

  /// Record a dua completion for a user.
  func recordDuaCompletion(userId: String, duaId: Int, xpEarned: Int) async throws

  // MARK: - User Progress

  /// Fetch all progress records for a user.
  func fetchUserProgress(userId: String) async throws -> [UserProgress]

  /// Fetch progress for a specific dua.
  func fetchDuaProgress(userId: String, duaId: Int) async throws -> UserProgress?

  /// Update progress for a specific dua (increment completion count).
  func updateDuaProgress(userId: String, duaId: Int) async throws

  // MARK: - Batch Operations

  /// Record a complete practice session (activity + progress + XP).
  func recordPracticeCompletion(userId: String, duaId: Int, xp: Int) async throws -> UserProfile
}

// MARK: - Firebase User Service Implementation

/// Concrete implementation of FirebaseUserServiceProtocol using Firestore.
/// Wraps the existing FirestoreService actor for user operations.
public actor FirebaseUserService: FirebaseUserServiceProtocol {
  /// Lazy Firestore reference - ensures Firebase is configured before accessing
  private var db: Firestore {
    Firestore.firestore()
  }

  // Collection names
  private let userProfilesCollection = "user_profiles"
  private let userActivityCollection = "user_activity"
  private let userProgressCollection = "user_progress"

  public init() {
    // Firestore is accessed lazily to ensure FirebaseApp.configure() has been called
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

  public func fetchUserProfile(userId: String) async throws -> UserProfile? {
    logger.debug("Fetching user profile for userId: \(userId)")

    let docRef = db.collection(userProfilesCollection).document(userId)
    let snapshot = try await docRef.getDocument()

    guard snapshot.exists, let data = snapshot.data() else {
      logger.debug("User profile not found for userId: \(userId)")
      return nil
    }

    return try mapDocumentToUserProfile(data, userId: userId)
  }

  public func createUserProfile(userId: String, displayName: String?) async throws -> UserProfile {
    logger.info("Creating user profile for userId: \(userId)")

    let now = Date()
    let profile = UserProfile(
      id: userId,
      userId: userId,
      displayName: displayName,
      streak: 0,
      totalXp: 0,
      level: 1,
      lastActiveDate: nil,
      isAdmin: false,
      createdAt: now,
      updatedAt: now
    )

    let docRef = db.collection(userProfilesCollection).document(userId)
    try await docRef.setData(mapUserProfileToDocument(profile))

    logger.info("Created user profile for userId: \(userId)")
    return profile
  }

  public func updateUserProfile(_ profile: UserProfile) async throws -> UserProfile {
    logger.debug("Updating user profile for userId: \(profile.userId)")

    let updatedProfile = UserProfile(
      id: profile.id,
      userId: profile.userId,
      displayName: profile.displayName,
      streak: profile.streak,
      totalXp: profile.totalXp,
      level: profile.level,
      lastActiveDate: profile.lastActiveDate,
      isAdmin: profile.isAdmin,
      createdAt: profile.createdAt,
      updatedAt: Date()
    )

    let docRef = db.collection(userProfilesCollection).document(profile.userId)
    try await docRef.setData(mapUserProfileToDocument(updatedProfile), merge: true)

    logger.debug("Updated user profile for userId: \(profile.userId)")
    return updatedProfile
  }

  public func getOrCreateUserProfile(userId: String, displayName: String?) async throws -> UserProfile {
    if let existing = try await fetchUserProfile(userId: userId) {
      return existing
    }
    return try await createUserProfile(userId: userId, displayName: displayName)
  }

  public func addXp(userId: String, amount: Int) async throws -> UserProfile {
    logger.info("Adding \(amount) XP to user: \(userId)")

    guard var profile = try await fetchUserProfile(userId: userId) else {
      throw FirebaseUserError.userNotFound(userId)
    }

    // Update XP and level
    let newTotalXp = profile.totalXp + amount
    let newLevel = LevelCalculator.calculateLevel(from: newTotalXp)

    // Update streak based on last active date
    let today = dateString(from: Date())
    let lastActive = profile.lastActiveDate.map { dateString(from: $0) }
    var newStreak = profile.streak

    if lastActive != today {
      let yesterday = dateString(from: Date().addingTimeInterval(-86400))
      if lastActive == yesterday {
        newStreak += 1
      } else {
        newStreak = 1
      }
    }

    let updatedProfile = UserProfile(
      id: profile.id,
      userId: profile.userId,
      displayName: profile.displayName,
      streak: newStreak,
      totalXp: newTotalXp,
      level: newLevel,
      lastActiveDate: Date(),
      isAdmin: profile.isAdmin,
      createdAt: profile.createdAt,
      updatedAt: Date()
    )

    return try await updateUserProfile(updatedProfile)
  }

  // MARK: - User Activity Operations

  public func fetchUserActivity(userId: String, date: Date) async throws -> UserActivity? {
    let dateStr = dateString(from: date)
    logger.debug("Fetching user activity for userId: \(userId), date: \(dateStr)")

    let docRef = db.collection(userActivityCollection)
      .document(userId)
      .collection("dates")
      .document(dateStr)

    let snapshot = try await docRef.getDocument()

    guard snapshot.exists, let data = snapshot.data() else {
      return nil
    }

    // Generate a consistent ID from date for compatibility with UserActivity model
    let dateComponents = dateStr.split(separator: "-")
    let activityId = Int(dateComponents.joined()) ?? 0

    return UserActivity(
      id: activityId,
      userId: userId,
      date: date,
      duasCompleted: data["duasCompleted"] as? [Int] ?? [],
      xpEarned: data["xpEarned"] as? Int ?? 0
    )
  }

  public func fetchWeekActivities(userId: String) async throws -> [UserActivity] {
    logger.debug("Fetching week activities for userId: \(userId)")

    let calendar = Calendar.current
    let today = Date()

    // Generate date strings for the last 7 days
    let dateStrings = (0..<7).compactMap { offset -> String? in
      guard let date = calendar.date(byAdding: .day, value: -offset, to: today) else { return nil }
      return dateString(from: date)
    }

    let snapshot = try await db.collection(userActivityCollection)
      .document(userId)
      .collection("dates")
      .whereField(FieldPath.documentID(), in: dateStrings)
      .getDocuments()

    return snapshot.documents.compactMap { doc -> UserActivity? in
      let data = doc.data()
      let dateStr = doc.documentID

      guard let date = Self.dateFormatter.date(from: dateStr) else { return nil }

      let dateComponents = dateStr.split(separator: "-")
      let activityId = Int(dateComponents.joined()) ?? 0

      return UserActivity(
        id: activityId,
        userId: userId,
        date: date,
        duasCompleted: data["duasCompleted"] as? [Int] ?? [],
        xpEarned: data["xpEarned"] as? Int ?? 0
      )
    }
  }

  public func getTodayActivity(userId: String) async throws -> UserActivity {
    let today = Date()
    if let activity = try await fetchUserActivity(userId: userId, date: today) {
      return activity
    }

    let dateStr = dateString(from: today)
    let dateComponents = dateStr.split(separator: "-")
    let activityId = Int(dateComponents.joined()) ?? 0

    return UserActivity(
      id: activityId,
      userId: userId,
      date: today,
      duasCompleted: [],
      xpEarned: 0
    )
  }

  public func recordDuaCompletion(userId: String, duaId: Int, xpEarned: Int) async throws {
    logger.info("Recording dua completion for userId: \(userId), duaId: \(duaId), xp: \(xpEarned)")

    let today = dateString(from: Date())
    let docRef = db.collection(userActivityCollection)
      .document(userId)
      .collection("dates")
      .document(today)

    try await db.runTransaction { transaction, errorPointer in
      do {
        let snapshot = try transaction.getDocument(docRef)

        var duasCompleted = snapshot.data()?["duasCompleted"] as? [Int] ?? []
        var currentXp = snapshot.data()?["xpEarned"] as? Int ?? 0

        if !duasCompleted.contains(duaId) {
          duasCompleted.append(duaId)
        }
        currentXp += xpEarned

        transaction.setData([
          "userId": userId,
          "date": today,
          "duasCompleted": duasCompleted,
          "xpEarned": currentXp
        ], forDocument: docRef, merge: true)

        return nil
      } catch {
        errorPointer?.pointee = error as NSError
        return nil
      }
    }

    logger.info("Recorded dua completion for userId: \(userId)")
  }

  // MARK: - User Progress Operations

  public func fetchUserProgress(userId: String) async throws -> [UserProgress] {
    logger.debug("Fetching user progress for userId: \(userId)")

    let snapshot = try await db.collection(userProgressCollection)
      .document(userId)
      .collection("duas")
      .getDocuments()

    return snapshot.documents.compactMap { doc -> UserProgress? in
      guard let duaId = Int(doc.documentID) else { return nil }
      let data = doc.data()

      // Generate consistent ID from duaId
      let progressId = duaId * 1000 + abs(userId.hashValue) % 1000

      return UserProgress(
        id: progressId,
        userId: userId,
        duaId: duaId,
        completedCount: data["completedCount"] as? Int ?? 0,
        lastCompleted: (data["lastCompleted"] as? Timestamp)?.dateValue()
      )
    }
  }

  public func fetchDuaProgress(userId: String, duaId: Int) async throws -> UserProgress? {
    logger.debug("Fetching progress for userId: \(userId), duaId: \(duaId)")

    let docRef = db.collection(userProgressCollection)
      .document(userId)
      .collection("duas")
      .document(String(duaId))

    let snapshot = try await docRef.getDocument()

    guard snapshot.exists, let data = snapshot.data() else {
      return nil
    }

    let progressId = duaId * 1000 + abs(userId.hashValue) % 1000

    return UserProgress(
      id: progressId,
      userId: userId,
      duaId: duaId,
      completedCount: data["completedCount"] as? Int ?? 0,
      lastCompleted: (data["lastCompleted"] as? Timestamp)?.dateValue()
    )
  }

  public func updateDuaProgress(userId: String, duaId: Int) async throws {
    logger.info("Updating dua progress for userId: \(userId), duaId: \(duaId)")

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

    logger.info("Updated dua progress for userId: \(userId), duaId: \(duaId)")
  }

  // MARK: - Batch Operations

  public func recordPracticeCompletion(userId: String, duaId: Int, xp: Int) async throws -> UserProfile {
    logger.info("Recording practice completion for userId: \(userId), duaId: \(duaId), xp: \(xp)")

    // Update activity, progress, and XP
    try await recordDuaCompletion(userId: userId, duaId: duaId, xpEarned: xp)
    try await updateDuaProgress(userId: userId, duaId: duaId)
    return try await addXp(userId: userId, amount: xp)
  }

  // MARK: - Helper Methods

  private func mapDocumentToUserProfile(_ data: [String: Any], userId: String) throws -> UserProfile {
    UserProfile(
      id: userId,
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

  private func mapUserProfileToDocument(_ profile: UserProfile) -> [String: Any] {
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
}

// MARK: - Firebase User Errors

public enum FirebaseUserError: Error, LocalizedError {
  case userNotFound(String)
  case invalidData(String)
  case transactionFailed(String)

  public var errorDescription: String? {
    switch self {
    case .userNotFound(let userId):
      return "User not found: \(userId)"
    case .invalidData(let message):
      return "Invalid data: \(message)"
    case .transactionFailed(let message):
      return "Transaction failed: \(message)"
    }
  }
}

// MARK: - Mock Implementation for Testing/Preview

public actor MockFirebaseUserService: FirebaseUserServiceProtocol {
  private var profiles: [String: UserProfile] = [:]
  private var activities: [String: [String: UserActivity]] = [:] // userId -> date -> activity
  private var progress: [String: [Int: UserProgress]] = [:] // userId -> duaId -> progress

  public init() {
    // Initialize with sample data
    let sampleProfile = SampleData.userProfile
    profiles[sampleProfile.userId] = sampleProfile
  }

  public func fetchUserProfile(userId: String) async throws -> UserProfile? {
    profiles[userId]
  }

  public func createUserProfile(userId: String, displayName: String?) async throws -> UserProfile {
    let profile = UserProfile(
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
    profiles[userId] = profile
    return profile
  }

  public func updateUserProfile(_ profile: UserProfile) async throws -> UserProfile {
    profiles[profile.userId] = profile
    return profile
  }

  public func getOrCreateUserProfile(userId: String, displayName: String?) async throws -> UserProfile {
    if let existing = profiles[userId] {
      return existing
    }
    return try await createUserProfile(userId: userId, displayName: displayName)
  }

  public func addXp(userId: String, amount: Int) async throws -> UserProfile {
    guard var profile = profiles[userId] else {
      throw FirebaseUserError.userNotFound(userId)
    }

    let newXp = profile.totalXp + amount
    let updated = UserProfile(
      id: profile.id,
      userId: profile.userId,
      displayName: profile.displayName,
      streak: profile.streak + 1,
      totalXp: newXp,
      level: LevelCalculator.calculateLevel(from: newXp),
      lastActiveDate: Date(),
      isAdmin: profile.isAdmin,
      createdAt: profile.createdAt,
      updatedAt: Date()
    )
    profiles[userId] = updated
    return updated
  }

  public func fetchUserActivity(userId: String, date: Date) async throws -> UserActivity? {
    let formatter = DateFormatter()
    formatter.dateFormat = "yyyy-MM-dd"
    let dateStr = formatter.string(from: date)
    return activities[userId]?[dateStr]
  }

  public func fetchWeekActivities(userId: String) async throws -> [UserActivity] {
    guard let userActivities = activities[userId] else { return [] }
    return Array(userActivities.values)
  }

  public func getTodayActivity(userId: String) async throws -> UserActivity {
    let formatter = DateFormatter()
    formatter.dateFormat = "yyyy-MM-dd"
    let today = Date()
    let dateStr = formatter.string(from: today)

    if let activity = activities[userId]?[dateStr] {
      return activity
    }

    return UserActivity(
      id: Int(dateStr.replacingOccurrences(of: "-", with: "")) ?? 0,
      userId: userId,
      date: today,
      duasCompleted: [],
      xpEarned: 0
    )
  }

  public func recordDuaCompletion(userId: String, duaId: Int, xpEarned: Int) async throws {
    let formatter = DateFormatter()
    formatter.dateFormat = "yyyy-MM-dd"
    let today = Date()
    let dateStr = formatter.string(from: today)

    var userActivities = activities[userId] ?? [:]
    var activity = userActivities[dateStr] ?? UserActivity(
      id: Int(dateStr.replacingOccurrences(of: "-", with: "")) ?? 0,
      userId: userId,
      date: today,
      duasCompleted: [],
      xpEarned: 0
    )

    var completed = activity.duasCompleted
    if !completed.contains(duaId) {
      completed.append(duaId)
    }

    activity = UserActivity(
      id: activity.id,
      userId: activity.userId,
      date: activity.date,
      duasCompleted: completed,
      xpEarned: activity.xpEarned + xpEarned
    )

    userActivities[dateStr] = activity
    activities[userId] = userActivities
  }

  public func fetchUserProgress(userId: String) async throws -> [UserProgress] {
    guard let userProgress = progress[userId] else { return [] }
    return Array(userProgress.values)
  }

  public func fetchDuaProgress(userId: String, duaId: Int) async throws -> UserProgress? {
    progress[userId]?[duaId]
  }

  public func updateDuaProgress(userId: String, duaId: Int) async throws {
    var userProgress = progress[userId] ?? [:]
    let existing = userProgress[duaId]

    let updated = UserProgress(
      id: (existing?.id ?? duaId * 1000),
      userId: userId,
      duaId: duaId,
      completedCount: (existing?.completedCount ?? 0) + 1,
      lastCompleted: Date()
    )

    userProgress[duaId] = updated
    progress[userId] = userProgress
  }

  public func recordPracticeCompletion(userId: String, duaId: Int, xp: Int) async throws -> UserProfile {
    try await recordDuaCompletion(userId: userId, duaId: duaId, xpEarned: xp)
    try await updateDuaProgress(userId: userId, duaId: duaId)
    return try await addXp(userId: userId, amount: xp)
  }
}
