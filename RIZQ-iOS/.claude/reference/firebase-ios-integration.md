# Firebase iOS Integration Reference

A concise reference guide for integrating Firebase services in the RIZQ iOS app.

---

## Table of Contents

1. [Project Setup](#1-project-setup)
2. [Firebase Auth](#2-firebase-auth)
3. [Google Sign-In](#3-google-sign-in)
4. [Firestore Database](#4-firestore-database)
5. [Offline Support](#5-offline-support)
6. [Error Handling](#6-error-handling)
7. [TCA Integration](#7-tca-integration)
8. [Security Patterns](#8-security-patterns)
9. [Testing](#9-testing)
10. [Anti-Patterns](#10-anti-patterns)

---

## 1. Project Setup

### SPM Dependencies

In `project.yml`:

```yaml
packages:
  Firebase:
    url: https://github.com/firebase/firebase-ios-sdk
    from: "11.0.0"
  GoogleSignIn:
    url: https://github.com/google/GoogleSignIn-iOS
    from: "8.0.0"

targets:
  RIZQKit:
    dependencies:
      - package: Firebase
        product: FirebaseAuth
      - package: Firebase
        product: FirebaseFirestore
      - package: GoogleSignIn
        product: GoogleSignIn
```

### Firebase Configuration

1. Add `GoogleService-Info.plist` to `RIZQ/Resources/`
2. Initialize Firebase in app entry point:

```swift
import Firebase

@main
struct RIZQApp: App {
    init() {
        FirebaseApp.configure()
    }

    var body: some Scene {
        WindowGroup {
            AppView(store: Store(initialState: AppFeature.State()) {
                AppFeature()
            })
        }
    }
}
```

### Info.plist Configuration

```xml
<!-- URL Schemes for Google Sign-In -->
<key>CFBundleURLTypes</key>
<array>
    <dict>
        <key>CFBundleURLSchemes</key>
        <array>
            <string>com.googleusercontent.apps.YOUR_CLIENT_ID</string>
        </array>
    </dict>
</array>

<!-- Google Sign-In Client ID -->
<key>GIDClientID</key>
<string>YOUR_CLIENT_ID.apps.googleusercontent.com</string>
```

---

## 2. Firebase Auth

### Auth Service Protocol

```swift
import FirebaseAuth

public protocol AuthServiceProtocol: Sendable {
    func signInWithEmail(email: String, password: String) async throws -> User
    func signUpWithEmail(email: String, password: String) async throws -> User
    func signInWithGoogle(presenting: UIViewController) async throws -> User
    func signOut() throws
    func getCurrentUser() -> User?
    func addAuthStateListener(_ listener: @escaping (User?) -> Void) -> AuthStateDidChangeListenerHandle
    func removeAuthStateListener(_ handle: AuthStateDidChangeListenerHandle)
}
```

### Auth Service Implementation

```swift
import FirebaseAuth

public final class FirebaseAuthService: AuthServiceProtocol, @unchecked Sendable {
    private let auth = Auth.auth()

    // MARK: - Email Auth

    public func signInWithEmail(email: String, password: String) async throws -> User {
        let result = try await auth.signIn(withEmail: email, password: password)
        return result.user
    }

    public func signUpWithEmail(email: String, password: String) async throws -> User {
        let result = try await auth.createUser(withEmail: email, password: password)
        return result.user
    }

    // MARK: - Google Sign-In

    public func signInWithGoogle(presenting viewController: UIViewController) async throws -> User {
        // Get Google credential
        let credential = try await getGoogleCredential(presenting: viewController)

        // Sign in with Firebase
        let result = try await auth.signIn(with: credential)
        return result.user
    }

    private func getGoogleCredential(presenting viewController: UIViewController) async throws -> AuthCredential {
        guard let clientID = FirebaseApp.app()?.options.clientID else {
            throw AuthError.configurationError("Missing Google Client ID")
        }

        let config = GIDConfiguration(clientID: clientID)
        GIDSignIn.sharedInstance.configuration = config

        let result = try await GIDSignIn.sharedInstance.signIn(withPresenting: viewController)
        guard let idToken = result.user.idToken?.tokenString else {
            throw AuthError.tokenError("Missing Google ID token")
        }

        return GoogleAuthProvider.credential(
            withIDToken: idToken,
            accessToken: result.user.accessToken.tokenString
        )
    }

    // MARK: - Sign Out

    public func signOut() throws {
        try auth.signOut()
        GIDSignIn.sharedInstance.signOut()
    }

    // MARK: - Current User

    public func getCurrentUser() -> User? {
        auth.currentUser
    }

    // MARK: - Auth State Listener

    public func addAuthStateListener(_ listener: @escaping (User?) -> Void) -> AuthStateDidChangeListenerHandle {
        auth.addStateDidChangeListener { _, user in
            listener(user)
        }
    }

    public func removeAuthStateListener(_ handle: AuthStateDidChangeListenerHandle) {
        auth.removeStateDidChangeListener(handle)
    }
}
```

### Auth User Model

```swift
public struct AuthUser: Equatable, Sendable {
    public let id: String
    public let email: String?
    public let displayName: String?
    public let photoURL: URL?
    public let isEmailVerified: Bool

    public init(from firebaseUser: User) {
        self.id = firebaseUser.uid
        self.email = firebaseUser.email
        self.displayName = firebaseUser.displayName
        self.photoURL = firebaseUser.photoURL
        self.isEmailVerified = firebaseUser.isEmailVerified
    }
}
```

---

## 3. Google Sign-In

### SwiftUI Integration

```swift
import GoogleSignIn
import GoogleSignInSwift

struct GoogleSignInButton: View {
    let onSignIn: () -> Void

    var body: some View {
        Button(action: onSignIn) {
            HStack(spacing: 12) {
                Image("google-logo")
                    .resizable()
                    .frame(width: 20, height: 20)
                Text("Continue with Google")
                    .font(.headline)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(Color(.systemBackground))
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color(.separator), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
}
```

### Presenting View Controller

```swift
// Get the presenting view controller for Google Sign-In
extension View {
    func getRootViewController() -> UIViewController? {
        guard let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let rootViewController = scene.windows.first?.rootViewController else {
            return nil
        }
        return getVisibleViewController(from: rootViewController)
    }

    private func getVisibleViewController(from vc: UIViewController) -> UIViewController {
        if let nav = vc as? UINavigationController {
            return getVisibleViewController(from: nav.visibleViewController ?? vc)
        }
        if let tab = vc as? UITabBarController {
            return getVisibleViewController(from: tab.selectedViewController ?? vc)
        }
        if let presented = vc.presentedViewController {
            return getVisibleViewController(from: presented)
        }
        return vc
    }
}
```

---

## 4. Firestore Database

### Firestore Client Protocol

```swift
import FirebaseFirestore

public protocol FirestoreClientProtocol: Sendable {
    // Duas
    func fetchDuas() async throws -> [Dua]
    func fetchDua(id: String) async throws -> Dua?

    // Journeys
    func fetchJourneys() async throws -> [Journey]
    func fetchJourneyDuas(journeyId: String) async throws -> [JourneyDua]

    // User Data
    func fetchUserProfile(userId: String) async throws -> UserProfile?
    func saveUserProfile(_ profile: UserProfile) async throws
    func updateUserXP(userId: String, xpToAdd: Int) async throws

    // Activity
    func logActivity(userId: String, duaId: String, xp: Int) async throws
}
```

### Firestore Client Implementation

```swift
import FirebaseFirestore

public actor FirestoreClient: FirestoreClientProtocol {
    private let db = Firestore.firestore()

    // MARK: - Duas

    public func fetchDuas() async throws -> [Dua] {
        let snapshot = try await db.collection("duas").getDocuments()
        return try snapshot.documents.map { doc in
            try doc.data(as: DuaDTO.self).toDomain()
        }
    }

    public func fetchDua(id: String) async throws -> Dua? {
        let doc = try await db.collection("duas").document(id).getDocument()
        guard doc.exists else { return nil }
        return try doc.data(as: DuaDTO.self).toDomain()
    }

    // MARK: - Journeys

    public func fetchJourneys() async throws -> [Journey] {
        let snapshot = try await db.collection("journeys")
            .order(by: "sortOrder")
            .getDocuments()
        return try snapshot.documents.map { doc in
            try doc.data(as: JourneyDTO.self).toDomain()
        }
    }

    public func fetchJourneyDuas(journeyId: String) async throws -> [JourneyDua] {
        let snapshot = try await db.collection("journeys")
            .document(journeyId)
            .collection("duas")
            .order(by: "sortOrder")
            .getDocuments()
        return try snapshot.documents.map { doc in
            try doc.data(as: JourneyDuaDTO.self).toDomain()
        }
    }

    // MARK: - User Profile

    public func fetchUserProfile(userId: String) async throws -> UserProfile? {
        let doc = try await db.collection("userProfiles").document(userId).getDocument()
        guard doc.exists else { return nil }
        return try doc.data(as: UserProfileDTO.self).toDomain()
    }

    public func saveUserProfile(_ profile: UserProfile) async throws {
        try db.collection("userProfiles")
            .document(profile.userId)
            .setData(from: UserProfileDTO(from: profile), merge: true)
    }

    public func updateUserXP(userId: String, xpToAdd: Int) async throws {
        let docRef = db.collection("userProfiles").document(userId)
        try await docRef.updateData([
            "totalXp": FieldValue.increment(Int64(xpToAdd)),
            "lastActiveDate": FieldValue.serverTimestamp()
        ])
    }

    // MARK: - Activity Logging

    public func logActivity(userId: String, duaId: String, xp: Int) async throws {
        let today = Calendar.current.startOfDay(for: Date())
        let activityId = "\(userId)_\(today.timeIntervalSince1970)"

        try await db.collection("userActivity").document(activityId).setData([
            "userId": userId,
            "date": Timestamp(date: today),
            "duasCompleted": FieldValue.arrayUnion([duaId]),
            "xpEarned": FieldValue.increment(Int64(xp))
        ], merge: true)
    }
}
```

### Firestore DTOs

```swift
import FirebaseFirestore

// Use DTOs for Firestore serialization, then map to domain models
struct DuaDTO: Codable {
    @DocumentID var id: String?
    let titleEn: String
    let arabicText: String
    let transliteration: String
    let translationEn: String
    let source: String?
    let repetitions: Int
    let xpValue: Int
    let categoryId: String?
    let propheticContext: String?

    func toDomain() -> Dua {
        Dua(
            id: id ?? "",
            title: titleEn,
            arabicText: arabicText,
            transliteration: transliteration,
            translation: translationEn,
            source: source,
            repetitions: repetitions,
            xpValue: xpValue,
            categoryId: categoryId,
            propheticContext: propheticContext
        )
    }
}
```

### Real-time Listeners

```swift
public func observeUserProfile(userId: String) -> AsyncStream<UserProfile?> {
    AsyncStream { continuation in
        let listener = db.collection("userProfiles")
            .document(userId)
            .addSnapshotListener { snapshot, error in
                if let error {
                    print("Firestore listener error: \(error)")
                    continuation.yield(nil)
                    return
                }

                guard let snapshot, snapshot.exists else {
                    continuation.yield(nil)
                    return
                }

                do {
                    let profile = try snapshot.data(as: UserProfileDTO.self).toDomain()
                    continuation.yield(profile)
                } catch {
                    print("Decode error: \(error)")
                    continuation.yield(nil)
                }
            }

        continuation.onTermination = { _ in
            listener.remove()
        }
    }
}
```

---

## 5. Offline Support

### Enable Persistence

```swift
// In app initialization
let settings = FirestoreSettings()
settings.cacheSettings = PersistentCacheSettings(sizeBytes: 100 * 1024 * 1024) // 100 MB
Firestore.firestore().settings = settings
```

### Cache-First Reads

```swift
public func fetchDuasCached() async throws -> [Dua] {
    // Try cache first
    do {
        let snapshot = try await db.collection("duas")
            .getDocuments(source: .cache)
        if !snapshot.isEmpty {
            return try snapshot.documents.map { try $0.data(as: DuaDTO.self).toDomain() }
        }
    } catch {
        // Cache miss, fall through to server
    }

    // Fetch from server
    let snapshot = try await db.collection("duas").getDocuments(source: .server)
    return try snapshot.documents.map { try $0.data(as: DuaDTO.self).toDomain() }
}
```

### Network Status Monitoring

```swift
import Network

@Observable
final class NetworkMonitor {
    static let shared = NetworkMonitor()

    private let monitor = NWPathMonitor()
    private let queue = DispatchQueue(label: "NetworkMonitor")

    var isConnected = true

    private init() {
        monitor.pathUpdateHandler = { [weak self] path in
            DispatchQueue.main.async {
                self?.isConnected = path.status == .satisfied
            }
        }
        monitor.start(queue: queue)
    }
}
```

---

## 6. Error Handling

### Firebase Error Types

```swift
public enum RIZQFirebaseError: Error, LocalizedError {
    case notAuthenticated
    case userNotFound
    case networkError(String)
    case permissionDenied
    case documentNotFound(String)
    case decodingError(String)
    case unknown(Error)

    public var errorDescription: String? {
        switch self {
        case .notAuthenticated:
            return "Please sign in to continue"
        case .userNotFound:
            return "User not found"
        case .networkError(let message):
            return "Network error: \(message)"
        case .permissionDenied:
            return "Permission denied"
        case .documentNotFound(let id):
            return "Document not found: \(id)"
        case .decodingError(let message):
            return "Data error: \(message)"
        case .unknown(let error):
            return error.localizedDescription
        }
    }
}
```

### Error Mapping

```swift
extension FirestoreClient {
    private func mapError(_ error: Error) -> RIZQFirebaseError {
        if let firestoreError = error as? FirestoreErrorCode {
            switch firestoreError.code {
            case .permissionDenied:
                return .permissionDenied
            case .notFound:
                return .documentNotFound("")
            case .unavailable:
                return .networkError("Service unavailable")
            default:
                return .unknown(error)
            }
        }
        return .unknown(error)
    }
}
```

---

## 7. TCA Integration

### Firestore Dependency

```swift
import Dependencies

extension DependencyValues {
    var firestoreClient: FirestoreClientProtocol {
        get { self[FirestoreClientKey.self] }
        set { self[FirestoreClientKey.self] = newValue }
    }
}

private enum FirestoreClientKey: DependencyKey {
    static let liveValue: FirestoreClientProtocol = FirestoreClient()
    static let testValue: FirestoreClientProtocol = MockFirestoreClient()
    static let previewValue: FirestoreClientProtocol = MockFirestoreClient()
}
```

### Auth Dependency

```swift
extension DependencyValues {
    var authService: AuthServiceProtocol {
        get { self[AuthServiceKey.self] }
        set { self[AuthServiceKey.self] = newValue }
    }
}

private enum AuthServiceKey: DependencyKey {
    static let liveValue: AuthServiceProtocol = FirebaseAuthService()
    static let testValue: AuthServiceProtocol = MockAuthService()
}
```

### Using in Features

```swift
@Reducer
struct JourneysFeature {
    @Dependency(\.firestoreClient) var firestoreClient
    @Dependency(\.authService) var authService

    var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .onAppear:
                guard authService.getCurrentUser() != nil else {
                    state.error = "Please sign in"
                    return .none
                }

                state.isLoading = true
                return .run { send in
                    let journeys = try await firestoreClient.fetchJourneys()
                    await send(.journeysLoaded(.success(journeys)))
                } catch: { error, send in
                    await send(.journeysLoaded(.failure(error)))
                }

            case .journeysLoaded(.success(let journeys)):
                state.isLoading = false
                state.journeys = journeys
                return .none

            case .journeysLoaded(.failure(let error)):
                state.isLoading = false
                state.error = error.localizedDescription
                return .none
            }
        }
    }
}
```

---

## 8. Security Patterns

### Secure User ID Access

```swift
// Always verify the current user before operations
func updateProfile(name: String) async throws {
    guard let userId = authService.getCurrentUser()?.uid else {
        throw RIZQFirebaseError.notAuthenticated
    }

    try await firestoreClient.updateProfile(userId: userId, name: name)
}
```

### Firestore Security Rules Reference

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Users can only access their own profile
    match /userProfiles/{userId} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }

    // Duas are read-only for authenticated users
    match /duas/{duaId} {
      allow read: if request.auth != null;
      allow write: if false;
    }

    // Journeys are read-only for authenticated users
    match /journeys/{journeyId} {
      allow read: if request.auth != null;

      match /duas/{duaId} {
        allow read: if request.auth != null;
      }
    }
  }
}
```

---

## 9. Testing

### Mock Firestore Client

```swift
public actor MockFirestoreClient: FirestoreClientProtocol {
    public var mockDuas: [Dua] = []
    public var mockJourneys: [Journey] = []
    public var mockProfile: UserProfile?

    public func fetchDuas() async throws -> [Dua] {
        mockDuas
    }

    public func fetchJourneys() async throws -> [Journey] {
        mockJourneys
    }

    public func fetchUserProfile(userId: String) async throws -> UserProfile? {
        mockProfile
    }

    // ... other methods
}
```

### Mock Auth Service

```swift
public final class MockAuthService: AuthServiceProtocol, @unchecked Sendable {
    public var currentUser: User?
    public var shouldFailSignIn = false

    public func signInWithEmail(email: String, password: String) async throws -> User {
        if shouldFailSignIn {
            throw AuthError.invalidCredentials
        }
        // Return mock user
        return MockUser(uid: "mock-uid", email: email)
    }

    public func getCurrentUser() -> User? {
        currentUser
    }
}
```

### Testing with Dependencies

```swift
@MainActor
func testFetchJourneys() async {
    let store = TestStore(
        initialState: JourneysFeature.State()
    ) {
        JourneysFeature()
    } withDependencies: {
        $0.firestoreClient = MockFirestoreClient()
        $0.authService = MockAuthService(currentUser: MockUser())
    }

    // Test...
}
```

---

## 10. Anti-Patterns

### Don't Block Main Thread

```swift
// Bad - blocks main thread
let docs = try! Firestore.firestore().collection("duas").getDocuments().documents

// Good - async/await
let docs = try await Firestore.firestore().collection("duas").getDocuments().documents
```

### Don't Ignore Errors

```swift
// Bad
db.collection("activity").addDocument(data: activityData) { _ in }

// Good
do {
    try await db.collection("activity").addDocument(data: activityData)
} catch {
    logger.error("Failed to log activity: \(error)")
}
```

### Don't Store Sensitive Data in Firestore

```swift
// Bad - storing password
try db.collection("users").document(userId).setData(["password": password])

// Good - only store non-sensitive profile data
try db.collection("userProfiles").document(userId).setData([
    "displayName": name,
    "lastActiveDate": FieldValue.serverTimestamp()
])
```

### Don't Create Listeners Without Cleanup

```swift
// Bad - listener leak
db.collection("users").addSnapshotListener { ... }

// Good - store and remove listener
private var listener: ListenerRegistration?

func startListening() {
    listener = db.collection("users").addSnapshotListener { ... }
}

func stopListening() {
    listener?.remove()
    listener = nil
}
```

### Don't Fetch All Documents

```swift
// Bad - fetches everything
let allDocs = try await db.collection("activity").getDocuments()

// Good - use pagination and filtering
let recentDocs = try await db.collection("activity")
    .whereField("userId", isEqualTo: userId)
    .order(by: "date", descending: true)
    .limit(to: 50)
    .getDocuments()
```
