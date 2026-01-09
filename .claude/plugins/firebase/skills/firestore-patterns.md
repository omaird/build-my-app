# Firestore Database Patterns for iOS

This skill provides patterns and best practices for using Firestore in iOS applications.

## When to Use This Skill

Use this skill when:
- Implementing data persistence with Firestore
- Setting up real-time listeners
- Querying and filtering documents
- Managing offline data sync
- Designing data models for Firestore

## Core Setup

### Dependencies

```yaml
# project.yml
packages:
  Firebase:
    url: https://github.com/firebase/firebase-ios-sdk
    from: "11.0.0"

targets:
  YourFramework:
    dependencies:
      - package: Firebase
        product: FirebaseFirestore
```

### Basic Service

```swift
import FirebaseFirestore

public actor FirestoreService {
  private let db = Firestore.firestore()

  public init() {}
}
```

## Document Operations

### Create Document

```swift
public func createDocument<T: Encodable>(
  collection: String,
  document: T,
  id: String? = nil
) async throws -> String {
  let collectionRef = db.collection(collection)

  if let id = id {
    try collectionRef.document(id).setData(from: document)
    return id
  } else {
    let docRef = try collectionRef.addDocument(from: document)
    return docRef.documentID
  }
}
```

### Read Document

```swift
public func getDocument<T: Decodable>(
  collection: String,
  id: String
) async throws -> T? {
  let snapshot = try await db.collection(collection).document(id).getDocument()
  return try snapshot.data(as: T.self)
}
```

### Update Document

```swift
public func updateDocument(
  collection: String,
  id: String,
  fields: [String: Any]
) async throws {
  try await db.collection(collection).document(id).updateData(fields)
}

// Type-safe update with Codable
public func updateDocument<T: Encodable>(
  collection: String,
  id: String,
  document: T,
  merge: Bool = true
) async throws {
  try db.collection(collection).document(id).setData(from: document, merge: merge)
}
```

### Delete Document

```swift
public func deleteDocument(
  collection: String,
  id: String
) async throws {
  try await db.collection(collection).document(id).delete()
}
```

## Query Patterns

### Basic Query

```swift
public func query<T: Decodable>(
  collection: String,
  whereField field: String,
  isEqualTo value: Any
) async throws -> [T] {
  let snapshot = try await db.collection(collection)
    .whereField(field, isEqualTo: value)
    .getDocuments()

  return snapshot.documents.compactMap { try? $0.data(as: T.self) }
}
```

### Compound Query

```swift
public func queryUserProgress(userId: String, limit: Int = 50) async throws -> [DuaProgress] {
  let snapshot = try await db.collection("user_progress")
    .whereField("userId", isEqualTo: userId)
    .whereField("completedCount", isGreaterThan: 0)
    .order(by: "lastCompleted", descending: true)
    .limit(to: limit)
    .getDocuments()

  return snapshot.documents.compactMap { try? $0.data(as: DuaProgress.self) }
}
```

### Pagination

```swift
public func queryPaginated<T: Decodable>(
  collection: String,
  orderBy field: String,
  limit: Int,
  startAfter lastDocument: DocumentSnapshot? = nil
) async throws -> (items: [T], lastDocument: DocumentSnapshot?) {
  var query = db.collection(collection)
    .order(by: field)
    .limit(to: limit)

  if let lastDoc = lastDocument {
    query = query.start(afterDocument: lastDoc)
  }

  let snapshot = try await query.getDocuments()
  let items = snapshot.documents.compactMap { try? $0.data(as: T.self) }

  return (items, snapshot.documents.last)
}
```

## Real-Time Listeners

### Single Document Listener

```swift
public func listenToDocument<T: Decodable>(
  collection: String,
  id: String,
  onChange: @escaping (T?) -> Void
) -> ListenerRegistration {
  return db.collection(collection).document(id)
    .addSnapshotListener { snapshot, error in
      guard let snapshot = snapshot else {
        onChange(nil)
        return
      }
      onChange(try? snapshot.data(as: T.self))
    }
}
```

### Collection Listener

```swift
public func listenToCollection<T: Decodable>(
  collection: String,
  whereField field: String,
  isEqualTo value: Any,
  onChange: @escaping ([T]) -> Void
) -> ListenerRegistration {
  return db.collection(collection)
    .whereField(field, isEqualTo: value)
    .addSnapshotListener { snapshot, error in
      guard let snapshot = snapshot else {
        onChange([])
        return
      }
      let items = snapshot.documents.compactMap { try? $0.data(as: T.self) }
      onChange(items)
    }
}
```

### AsyncStream Pattern

```swift
public func documentStream<T: Decodable>(
  collection: String,
  id: String
) -> AsyncStream<T?> {
  AsyncStream { continuation in
    let listener = db.collection(collection).document(id)
      .addSnapshotListener { snapshot, error in
        let item = try? snapshot?.data(as: T.self)
        continuation.yield(item)
      }

    continuation.onTermination = { _ in
      listener.remove()
    }
  }
}
```

## Data Models

### Firestore Document Model

```swift
import FirebaseFirestore

struct UserProfile: Codable, Identifiable {
  @DocumentID var id: String?
  var userId: String
  var displayName: String
  var streak: Int
  var totalXp: Int
  var level: Int
  @ServerTimestamp var lastActiveDate: Date?
  @ServerTimestamp var createdAt: Date?
  @ServerTimestamp var updatedAt: Date?

  enum CodingKeys: String, CodingKey {
    case id
    case userId = "user_id"
    case displayName = "display_name"
    case streak
    case totalXp = "total_xp"
    case level
    case lastActiveDate = "last_active_date"
    case createdAt = "created_at"
    case updatedAt = "updated_at"
  }
}
```

### Nested Data

```swift
struct Journey: Codable, Identifiable {
  @DocumentID var id: String?
  var name: String
  var description: String
  var emoji: String
  var duas: [JourneyDua]  // Subcollection or embedded array

  struct JourneyDua: Codable {
    var duaId: String
    var timeSlot: String
    var sortOrder: Int
  }
}
```

## Batch Operations

### Batch Write

```swift
public func batchWrite(operations: [(collection: String, id: String, data: [String: Any])]) async throws {
  let batch = db.batch()

  for operation in operations {
    let ref = db.collection(operation.collection).document(operation.id)
    batch.setData(operation.data, forDocument: ref, merge: true)
  }

  try await batch.commit()
}
```

### Transaction

```swift
public func incrementXp(userId: String, amount: Int) async throws -> Int {
  return try await db.runTransaction { transaction, errorPointer in
    let profileRef = db.collection("user_profiles").document(userId)

    let snapshot: DocumentSnapshot
    do {
      snapshot = try transaction.getDocument(profileRef)
    } catch let error as NSError {
      errorPointer?.pointee = error
      return 0
    }

    let currentXp = snapshot.data()?["total_xp"] as? Int ?? 0
    let newXp = currentXp + amount

    transaction.updateData(["total_xp": newXp], forDocument: profileRef)
    return newXp
  }
}
```

## Offline Persistence

### Enable Offline Support

```swift
// Enabled by default on iOS, but can configure:
let settings = FirestoreSettings()
settings.cacheSettings = PersistentCacheSettings(sizeBytes: 100_000_000) // 100MB
db.settings = settings
```

### Handle Offline Writes

```swift
public func saveOfflineAware<T: Encodable>(
  collection: String,
  id: String,
  document: T
) async throws {
  do {
    try db.collection(collection).document(id).setData(from: document)
    // Will succeed even offline, data syncs when online
  } catch {
    throw error
  }
}
```

### Check Pending Writes

```swift
public func hasPendingWrites(collection: String, id: String) async throws -> Bool {
  let snapshot = try await db.collection(collection).document(id).getDocument()
  return snapshot.metadata.hasPendingWrites
}
```

## Security Rules Pattern

```javascript
// firestore.rules
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // User profiles - users can only read/write their own
    match /user_profiles/{userId} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }

    // User progress - users can only read/write their own
    match /user_progress/{docId} {
      allow read, write: if request.auth != null &&
        request.auth.uid == resource.data.user_id;
      allow create: if request.auth != null &&
        request.auth.uid == request.resource.data.user_id;
    }

    // Public content (duas, journeys) - anyone authenticated can read
    match /duas/{duaId} {
      allow read: if request.auth != null;
      allow write: if false; // Admin only via backend
    }

    match /journeys/{journeyId} {
      allow read: if request.auth != null;
      allow write: if false;
    }
  }
}
```

## Common Patterns

### User Profile Upsert

```swift
public func upsertUserProfile(userId: String, updates: [String: Any]) async throws {
  var data = updates
  data["updated_at"] = FieldValue.serverTimestamp()

  try await db.collection("user_profiles").document(userId).setData(data, merge: true)
}
```

### Array Operations

```swift
// Add to array
try await db.collection("users").document(userId)
  .updateData(["favoriteIds": FieldValue.arrayUnion([duaId])])

// Remove from array
try await db.collection("users").document(userId)
  .updateData(["favoriteIds": FieldValue.arrayRemove([duaId])])
```

### Increment Counter

```swift
try await db.collection("user_profiles").document(userId)
  .updateData(["total_xp": FieldValue.increment(Int64(xpAmount))])
```
