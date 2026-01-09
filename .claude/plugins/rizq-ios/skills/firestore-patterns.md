---
description: Firestore data modeling, query patterns, and best practices for iOS apps using Swift Concurrency
when_to_use: When working with Firestore in iOS apps - designing collections, writing queries, handling real-time updates, or managing transactions
---

# Firestore Patterns for iOS

## Collection Design

### Document IDs
- Use authenticated user's UID as document ID for user-specific data
- Use predictable IDs when data needs to be looked up directly
- Firestore generates random IDs via `addDocument()` for other cases

### Subcollections vs. Arrays
- Use subcollections for unbounded or queryable data
- Use arrays for small, bounded data (< 20 items) that's always fetched together

```swift
// Subcollection: Good for querying individual dates
user_activity/{userId}/dates/{date}

// Array: Good for small, bounded data
user_profiles/{userId} { duasCompleted: [1, 2, 3] }
```

## Service Pattern with Swift Concurrency

```swift
public actor FirestoreService {
  private let db: Firestore

  public init() {
    self.db = Firestore.firestore()
  }

  // MARK: - Read Operations

  public func fetchDocument<T: Decodable>(
    collection: String,
    documentId: String
  ) async throws -> T? {
    let snapshot = try await db.collection(collection).document(documentId).getDocument()
    guard snapshot.exists else { return nil }
    return try snapshot.data(as: T.self)
  }

  public func fetchDocuments<T: Decodable>(
    collection: String,
    query: @escaping (Query) -> Query = { $0 }
  ) async throws -> [T] {
    let baseQuery = db.collection(collection)
    let snapshot = try await query(baseQuery).getDocuments()
    return snapshot.documents.compactMap { try? $0.data(as: T.self) }
  }

  // MARK: - Write Operations

  public func setDocument<T: Encodable>(
    collection: String,
    documentId: String,
    data: T,
    merge: Bool = false
  ) async throws {
    let docRef = db.collection(collection).document(documentId)
    try docRef.setData(from: data, merge: merge)
  }

  public func updateDocument(
    collection: String,
    documentId: String,
    fields: [String: Any]
  ) async throws {
    let docRef = db.collection(collection).document(documentId)
    try await docRef.updateData(fields)
  }

  public func deleteDocument(
    collection: String,
    documentId: String
  ) async throws {
    try await db.collection(collection).document(documentId).delete()
  }
}
```

## Query Patterns

### Basic Queries

```swift
// Filter by field
let query = db.collection("user_profiles")
  .whereField("level", isGreaterThan: 5)

// Order and limit
let query = db.collection("user_profiles")
  .order(by: "totalXp", descending: true)
  .limit(to: 10)

// Compound queries (require composite index)
let query = db.collection("user_profiles")
  .whereField("isAdmin", isEqualTo: true)
  .order(by: "totalXp", descending: true)
```

### Pagination

```swift
public func fetchPaginated<T: Decodable>(
  collection: String,
  pageSize: Int,
  lastDocument: DocumentSnapshot?
) async throws -> (items: [T], lastDoc: DocumentSnapshot?) {
  var query = db.collection(collection)
    .order(by: "createdAt", descending: true)
    .limit(to: pageSize)

  if let lastDoc = lastDocument {
    query = query.start(afterDocument: lastDoc)
  }

  let snapshot = try await query.getDocuments()
  let items = snapshot.documents.compactMap { try? $0.data(as: T.self) }
  return (items, snapshot.documents.last)
}
```

### Subcollection Queries

```swift
// Query subcollection
public func fetchUserActivity(userId: String, date: String) async throws -> UserActivity? {
  let docRef = db.collection("user_activity")
    .document(userId)
    .collection("dates")
    .document(date)

  let snapshot = try await docRef.getDocument()
  return try? snapshot.data(as: UserActivity.self)
}

// Query across all subcollections (collection group query)
let allActivities = db.collectionGroup("dates")
  .whereField("xpEarned", isGreaterThan: 100)
```

## Transactions

Use transactions for atomic multi-document updates:

```swift
public func addXpWithTransaction(userId: String, amount: Int) async throws {
  let profileRef = db.collection("user_profiles").document(userId)

  try await db.runTransaction { transaction, errorPointer in
    let snapshot: DocumentSnapshot
    do {
      snapshot = try transaction.getDocument(profileRef)
    } catch let fetchError as NSError {
      errorPointer?.pointee = fetchError
      return nil
    }

    let currentXp = snapshot.data()?["totalXp"] as? Int ?? 0
    let newXp = currentXp + amount
    let newLevel = self.calculateLevel(xp: newXp)

    transaction.updateData([
      "totalXp": newXp,
      "level": newLevel,
      "updatedAt": Timestamp(date: Date())
    ], forDocument: profileRef)

    return nil
  }
}
```

## Batch Writes

Use batches for multiple independent writes:

```swift
public func recordMultipleCompletions(userId: String, duaIds: [Int]) async throws {
  let batch = db.batch()
  let today = dateString(from: Date())

  for duaId in duaIds {
    let progressRef = db.collection("user_progress")
      .document(userId)
      .collection("duas")
      .document(String(duaId))

    batch.setData([
      "completedCount": FieldValue.increment(Int64(1)),
      "lastCompleted": Timestamp(date: Date())
    ], forDocument: progressRef, merge: true)
  }

  try await batch.commit()
}
```

## Real-Time Listeners

```swift
public func observeUserProfile(
  userId: String,
  onChange: @escaping (FirestoreUserProfile?) -> Void
) -> ListenerRegistration {
  return db.collection("user_profiles")
    .document(userId)
    .addSnapshotListener { snapshot, error in
      guard let snapshot = snapshot else {
        onChange(nil)
        return
      }
      onChange(try? snapshot.data(as: FirestoreUserProfile.self))
    }
}

// AsyncStream wrapper for SwiftUI
public func profileUpdates(userId: String) -> AsyncStream<FirestoreUserProfile?> {
  AsyncStream { continuation in
    let listener = observeUserProfile(userId: userId) { profile in
      continuation.yield(profile)
    }
    continuation.onTermination = { _ in
      listener.remove()
    }
  }
}
```

## Codable Models

```swift
public struct FirestoreUserProfile: Codable, Sendable {
  @DocumentID var id: String?
  var displayName: String?
  var streak: Int
  var totalXp: Int
  var level: Int
  @ServerTimestamp var lastActiveDate: Timestamp?
  var isAdmin: Bool
  @ServerTimestamp var createdAt: Timestamp?
  @ServerTimestamp var updatedAt: Timestamp?

  enum CodingKeys: String, CodingKey {
    case id
    case displayName
    case streak
    case totalXp
    case level
    case lastActiveDate
    case isAdmin
    case createdAt
    case updatedAt
  }
}
```

## Error Handling

```swift
public enum FirestoreError: Error, LocalizedError {
  case documentNotFound
  case invalidData
  case permissionDenied
  case networkError
  case transactionFailed(String)

  public var errorDescription: String? {
    switch self {
    case .documentNotFound: return "Document not found"
    case .invalidData: return "Invalid data format"
    case .permissionDenied: return "Permission denied"
    case .networkError: return "Network error"
    case .transactionFailed(let msg): return "Transaction failed: \(msg)"
    }
  }
}

// Map Firestore errors
private func mapError(_ error: Error) -> FirestoreError {
  let nsError = error as NSError
  switch nsError.code {
  case FirestoreErrorCode.notFound.rawValue:
    return .documentNotFound
  case FirestoreErrorCode.permissionDenied.rawValue:
    return .permissionDenied
  case FirestoreErrorCode.unavailable.rawValue:
    return .networkError
  default:
    return .invalidData
  }
}
```

## Offline Support

Firestore has built-in offline support. Configure persistence:

```swift
let settings = FirestoreSettings()
settings.cacheSettings = PersistentCacheSettings(sizeBytes: 100_000_000) // 100MB cache
Firestore.firestore().settings = settings
```

## Security Rules Patterns

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Helper functions
    function isAuthenticated() {
      return request.auth != null;
    }

    function isOwner(userId) {
      return isAuthenticated() && request.auth.uid == userId;
    }

    function isAdmin() {
      return isAuthenticated() &&
        get(/databases/$(database)/documents/user_profiles/$(request.auth.uid)).data.isAdmin == true;
    }

    // User profiles - owner access
    match /user_profiles/{userId} {
      allow read: if isOwner(userId) || isAdmin();
      allow write: if isOwner(userId);
    }

    // User activity - owner access only
    match /user_activity/{userId}/{path=**} {
      allow read, write: if isOwner(userId);
    }

    // User progress - owner access only
    match /user_progress/{userId}/{path=**} {
      allow read, write: if isOwner(userId);
    }
  }
}
```

## Performance Best Practices

1. **Limit document size**: Keep documents under 1MB
2. **Denormalize for reads**: Duplicate data to avoid joins
3. **Use indexes**: Create composite indexes for complex queries
4. **Batch writes**: Group multiple writes together
5. **Paginate**: Never fetch unbounded collections
6. **Cache aggressively**: Firestore caches automatically, trust it
