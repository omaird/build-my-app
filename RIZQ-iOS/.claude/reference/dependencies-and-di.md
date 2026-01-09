# Dependencies & Dependency Injection Reference

A concise reference guide for using swift-dependencies in the RIZQ iOS app.

---

## Table of Contents

1. [Overview](#1-overview)
2. [Declaring Dependencies](#2-declaring-dependencies)
3. [Using Dependencies](#3-using-dependencies)
4. [Creating Custom Dependencies](#4-creating-custom-dependencies)
5. [Live vs Test vs Preview](#5-live-vs-test-vs-preview)
6. [Common Dependencies](#6-common-dependencies)
7. [Testing with Dependencies](#7-testing-with-dependencies)
8. [Best Practices](#8-best-practices)
9. [Anti-Patterns](#9-anti-patterns)

---

## 1. Overview

### Why swift-dependencies?

| Feature | Traditional DI | swift-dependencies |
|---------|---------------|-------------------|
| Setup | Manual injection | Automatic via property wrapper |
| Testing | Pass mocks manually | Override in `withDependencies` |
| Previews | Create mock instances | Use `previewValue` |
| Scope | Constructor injection | Context-based resolution |

### Core Concepts

- **DependencyKey**: Protocol that defines how a dependency is resolved
- **DependencyValues**: Container that holds all dependencies
- **@Dependency**: Property wrapper to access dependencies
- **withDependencies**: Override dependencies for a scope

---

## 2. Declaring Dependencies

### In Reducers

```swift
import ComposableArchitecture

@Reducer
struct JourneysFeature {
    @Dependency(\.firestoreClient) var firestoreClient
    @Dependency(\.authService) var authService
    @Dependency(\.date.now) var now
    @Dependency(\.uuid) var uuid

    var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .onAppear:
                return .run { send in
                    let journeys = try await firestoreClient.fetchJourneys()
                    await send(.journeysLoaded(.success(journeys)))
                }
            // ...
            }
        }
    }
}
```

### Multiple Dependencies

```swift
@Dependency(\.firestoreClient) var firestoreClient
@Dependency(\.authService) var authService
@Dependency(\.continuousClock) var clock
@Dependency(\.dismiss) var dismiss
@Dependency(\.openURL) var openURL
```

---

## 3. Using Dependencies

### In Effects

```swift
case .saveTapped:
    return .run { [state] send in
        try await firestoreClient.saveProfile(state.profile)
        await send(.saveSucceeded)
    } catch: { error, send in
        await send(.saveFailed(error))
    }
```

### Capturing State

```swift
case .submitTapped:
    // Capture state values before entering .run
    let data = state.formData
    let userId = state.userId

    return .run { send in
        try await firestoreClient.submit(data, userId: userId)
        await send(.submitSucceeded)
    }
```

### Dismissing Sheets

```swift
@Dependency(\.dismiss) var dismiss

case .closeTapped:
    return .run { _ in
        await dismiss()
    }
```

### Opening URLs

```swift
@Dependency(\.openURL) var openURL

case .learnMoreTapped:
    return .run { _ in
        await openURL(URL(string: "https://rizq.app/learn")!)
    }
```

---

## 4. Creating Custom Dependencies

### Protocol-Based Dependency

**Step 1: Define the protocol**

```swift
// RIZQKit/Services/API/FirestoreClientProtocol.swift
public protocol FirestoreClientProtocol: Sendable {
    func fetchJourneys() async throws -> [Journey]
    func fetchDuas() async throws -> [Dua]
    func saveProfile(_ profile: UserProfile) async throws
}
```

**Step 2: Create the live implementation**

```swift
// RIZQKit/Services/API/FirestoreClient.swift
public actor FirestoreClient: FirestoreClientProtocol {
    public func fetchJourneys() async throws -> [Journey] {
        // Real Firestore implementation
    }

    public func fetchDuas() async throws -> [Dua] {
        // Real Firestore implementation
    }

    public func saveProfile(_ profile: UserProfile) async throws {
        // Real Firestore implementation
    }
}
```

**Step 3: Register the dependency**

```swift
// RIZQKit/Dependencies/FirestoreClient+Dependency.swift
import Dependencies

extension DependencyValues {
    public var firestoreClient: FirestoreClientProtocol {
        get { self[FirestoreClientKey.self] }
        set { self[FirestoreClientKey.self] = newValue }
    }
}

private enum FirestoreClientKey: DependencyKey {
    static let liveValue: FirestoreClientProtocol = FirestoreClient()
}
```

### Struct-Based Dependency

For simpler dependencies, use a struct with closures:

```swift
public struct HapticClient: Sendable {
    public var impact: @Sendable (UIImpactFeedbackGenerator.FeedbackStyle) -> Void
    public var notification: @Sendable (UINotificationFeedbackGenerator.FeedbackType) -> Void
    public var selection: @Sendable () -> Void
}

extension HapticClient: DependencyKey {
    public static let liveValue = HapticClient(
        impact: { style in
            UIImpactFeedbackGenerator(style: style).impactOccurred()
        },
        notification: { type in
            UINotificationFeedbackGenerator().notificationOccurred(type)
        },
        selection: {
            UISelectionFeedbackGenerator().selectionChanged()
        }
    )
}

extension DependencyValues {
    public var haptics: HapticClient {
        get { self[HapticClient.self] }
        set { self[HapticClient.self] = newValue }
    }
}
```

---

## 5. Live vs Test vs Preview

### Defining All Values

```swift
private enum FirestoreClientKey: DependencyKey {
    // Production - uses real Firestore
    static let liveValue: FirestoreClientProtocol = FirestoreClient()

    // Tests - unimplemented by default (will fail if called)
    static let testValue: FirestoreClientProtocol = UnimplementedFirestoreClient()

    // SwiftUI Previews - returns mock data
    static let previewValue: FirestoreClientProtocol = MockFirestoreClient()
}
```

### Unimplemented Client

```swift
struct UnimplementedFirestoreClient: FirestoreClientProtocol {
    func fetchJourneys() async throws -> [Journey] {
        XCTFail("fetchJourneys was called but not implemented")
        return []
    }

    func fetchDuas() async throws -> [Dua] {
        XCTFail("fetchDuas was called but not implemented")
        return []
    }

    func saveProfile(_ profile: UserProfile) async throws {
        XCTFail("saveProfile was called but not implemented")
    }
}
```

### Mock Client for Previews

```swift
actor MockFirestoreClient: FirestoreClientProtocol {
    func fetchJourneys() async throws -> [Journey] {
        [.mock, .mock2]
    }

    func fetchDuas() async throws -> [Dua] {
        [.mock1, .mock2, .mock3]
    }

    func saveProfile(_ profile: UserProfile) async throws {
        // No-op
    }
}
```

---

## 6. Common Dependencies

### Built-in Dependencies

```swift
// Time
@Dependency(\.date.now) var now              // Current date
@Dependency(\.continuousClock) var clock     // For delays/timing
@Dependency(\.calendar) var calendar         // Calendar operations

// Identifiers
@Dependency(\.uuid) var uuid                 // UUID generation

// Navigation
@Dependency(\.dismiss) var dismiss           // Dismiss presented view
@Dependency(\.openURL) var openURL           // Open external URLs

// System
@Dependency(\.mainQueue) var mainQueue       // Main dispatch queue
@Dependency(\.locale) var locale             // Current locale
@Dependency(\.timeZone) var timeZone         // Current timezone
```

### RIZQ Custom Dependencies

```swift
// Data Layer
@Dependency(\.firestoreClient) var firestoreClient
@Dependency(\.apiClient) var apiClient

// Auth
@Dependency(\.authService) var authService

// Device
@Dependency(\.haptics) var haptics

// Persistence
@Dependency(\.userDefaults) var userDefaults
@Dependency(\.keychain) var keychain
```

---

## 7. Testing with Dependencies

### Override in TestStore

```swift
@MainActor
func testFetchJourneys() async {
    let store = TestStore(
        initialState: JourneysFeature.State()
    ) {
        JourneysFeature()
    } withDependencies: {
        $0.firestoreClient.fetchJourneys = {
            [.mock, .mock2]
        }
    }

    await store.send(.onAppear) {
        $0.isLoading = true
    }

    await store.receive(.journeysLoaded(.success([.mock, .mock2]))) {
        $0.isLoading = false
        $0.journeys = [.mock, .mock2]
    }
}
```

### Override Specific Endpoints

```swift
withDependencies: {
    // Override just the methods you need
    $0.firestoreClient.fetchJourneys = { [.mock] }
    $0.authService.getCurrentUser = { .mockUser }

    // Other methods remain unimplemented (will fail if called)
}
```

### Using withDependencies in Production

```swift
// Temporarily override dependencies (useful for feature flags)
await withDependencies {
    $0.featureFlags.isNewUIEnabled = true
} operation: {
    // Code here sees new UI enabled
}
```

---

## 8. Best Practices

### Keep Dependencies in RIZQKit

```
RIZQKit/
├── Dependencies/
│   ├── FirestoreClient+Dependency.swift
│   ├── AuthService+Dependency.swift
│   └── HapticClient.swift
├── Services/
│   ├── API/
│   │   ├── FirestoreClient.swift
│   │   └── FirestoreClientProtocol.swift
│   └── Auth/
│       ├── AuthService.swift
│       └── AuthServiceProtocol.swift
```

### Use Protocols for Complex Dependencies

```swift
// Prefer protocols when:
// - Multiple methods
// - Need actor isolation
// - Complex state

public protocol AuthServiceProtocol: Sendable {
    func signIn(email: String, password: String) async throws -> User
    func signOut() throws
    func getCurrentUser() -> User?
}
```

### Use Structs for Simple Dependencies

```swift
// Prefer structs when:
// - Few methods
// - Stateless
// - Easy to mock inline

public struct HapticClient: Sendable {
    public var impact: @Sendable (UIImpactFeedbackGenerator.FeedbackStyle) -> Void
}
```

### Document Dependencies

```swift
extension DependencyValues {
    /// Client for interacting with Firestore database.
    ///
    /// Use this dependency to fetch and save app data like journeys,
    /// duas, and user profiles.
    ///
    /// - Note: Requires Firebase to be configured before use.
    public var firestoreClient: FirestoreClientProtocol {
        get { self[FirestoreClientKey.self] }
        set { self[FirestoreClientKey.self] = newValue }
    }
}
```

---

## 9. Anti-Patterns

### Don't Access Dependencies Outside Reducers

```swift
// Bad - won't resolve correctly
class SomeClass {
    @Dependency(\.apiClient) var apiClient

    func doSomething() {
        apiClient.fetch()  // Won't work!
    }
}

// Good - access inside TCA reducer
@Reducer
struct MyFeature {
    @Dependency(\.apiClient) var apiClient

    var body: some ReducerOf<Self> {
        Reduce { state, action in
            // Access here
        }
    }
}
```

### Don't Create Singletons

```swift
// Bad - defeats dependency injection
class FirestoreClient {
    static let shared = FirestoreClient()
}

// Good - let the dependency system manage instances
extension DependencyValues {
    var firestoreClient: FirestoreClientProtocol {
        get { self[FirestoreClientKey.self] }
        set { self[FirestoreClientKey.self] = newValue }
    }
}
```

### Don't Make Dependencies Non-Sendable

```swift
// Bad - won't compile with strict concurrency
class NonSendableClient {
    var state: [String] = []  // Mutable, not Sendable
}

// Good - use actors for mutable state
actor SendableClient: ClientProtocol {
    private var state: [String] = []

    func getState() -> [String] { state }
    func updateState(_ new: [String]) { state = new }
}
```

### Don't Forget Test Values

```swift
// Bad - missing testValue will use unimplemented
private enum MyClientKey: DependencyKey {
    static let liveValue: MyClient = MyClient()
    // Missing testValue!
}

// Good - provide explicit test behavior
private enum MyClientKey: DependencyKey {
    static let liveValue: MyClient = MyClient()
    static let testValue: MyClient = MockMyClient()
    static let previewValue: MyClient = MockMyClient()
}
```

### Don't Over-Inject

```swift
// Bad - too many dependencies in one feature
@Dependency(\.api) var api
@Dependency(\.auth) var auth
@Dependency(\.analytics) var analytics
@Dependency(\.logger) var logger
@Dependency(\.cache) var cache
@Dependency(\.network) var network
@Dependency(\.storage) var storage
// ... 10 more

// Good - consolidate related functionality
@Dependency(\.dataClient) var dataClient  // Combines api, cache, storage
@Dependency(\.authClient) var authClient  // Combines auth, session
```

### Don't Ignore Unimplemented Failures

```swift
// In tests, if you see:
// "XCTFail: fetchJourneys was called but not implemented"

// It means you forgot to mock that method:
withDependencies: {
    $0.firestoreClient.fetchJourneys = { [.mock] }  // Add this!
}
```
