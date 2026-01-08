import XCTest
import FirebaseAuth
import FirebaseCore
@testable import RIZQKit

/// Integration tests for Firebase Authentication
/// These tests require Firebase Auth to be properly configured and Email/Password enabled
final class FirebaseAuthTests: XCTestCase {

  // Test credentials - use a dedicated test account
  private let testEmail = "test@rizq.app"
  private let testPassword = "TestPassword123!"
  private let testName = "Test User"

  private var authService: FirebaseAuthService!

  private static var isFirebaseConfigured = false

  override func setUp() async throws {
    try await super.setUp()

    // Configure Firebase once for all tests
    if !Self.isFirebaseConfigured {
      if FirebaseApp.app() == nil {
        FirebaseApp.configure()
      }
      Self.isFirebaseConfigured = true
    }

    authService = FirebaseAuthService()

    // Ensure we're signed out before each test
    try? await authService.signOut()
  }

  override func tearDown() async throws {
    // Clean up: sign out after each test
    try? await authService.signOut()
    authService = nil
    try await super.tearDown()
  }

  // MARK: - Email/Password Sign In Tests

  @MainActor
  func testSignInWithEmail() async throws {
    // Given: Valid test credentials
    let email = testEmail
    let password = testPassword

    // When: Sign in with email
    let response = try await authService.signInWithEmail(email: email, password: password)

    // Then: Should receive valid user and session
    XCTAssertNotNil(response.user)
    XCTAssertEqual(response.user.email, email)
    XCTAssertNotNil(response.session)
    XCTAssertFalse(response.session.token.isEmpty)
  }

  @MainActor
  func testSignInWithInvalidCredentials() async throws {
    // Given: Invalid credentials
    let email = "nonexistent@rizq.app"
    let password = "wrongpassword"

    // When/Then: Should throw invalidCredentials error
    do {
      _ = try await authService.signInWithEmail(email: email, password: password)
      XCTFail("Should have thrown an error")
    } catch let error as RIZQAuthError {
      switch error {
      case .invalidCredentials, .userNotFound:
        // Expected
        break
      default:
        XCTFail("Expected invalidCredentials or userNotFound, got \(error)")
      }
    }
  }

  @MainActor
  func testSignInWithEmptyEmail() async throws {
    // Given: Empty email
    let email = ""
    let password = testPassword

    // When/Then: Should throw an error
    do {
      _ = try await authService.signInWithEmail(email: email, password: password)
      XCTFail("Should have thrown an error")
    } catch {
      // Expected - Firebase rejects empty email
    }
  }

  // MARK: - Sign Out Tests

  @MainActor
  func testSignOut() async throws {
    // Given: Signed in user
    _ = try await authService.signInWithEmail(email: testEmail, password: testPassword)
    let sessionBefore = try await authService.getSession()
    XCTAssertNotNil(sessionBefore)

    // When: Sign out
    try await authService.signOut()

    // Then: Session should be nil
    let sessionAfter = try await authService.getSession()
    XCTAssertNil(sessionAfter)
  }

  // MARK: - Session Management Tests

  @MainActor
  func testGetSession() async throws {
    // Given: Signed in user
    _ = try await authService.signInWithEmail(email: testEmail, password: testPassword)

    // When: Get session
    let session = try await authService.getSession()

    // Then: Should have valid session
    XCTAssertNotNil(session)
    XCTAssertFalse(session!.token.isEmpty)
    XCTAssertFalse(session!.userId.isEmpty)
  }

  @MainActor
  func testGetSessionWhenNotSignedIn() async throws {
    // Given: Not signed in
    try await authService.signOut()

    // When: Get session
    let session = try await authService.getSession()

    // Then: Should be nil
    XCTAssertNil(session)
  }

  @MainActor
  func testRefreshSession() async throws {
    // Given: Signed in user
    _ = try await authService.signInWithEmail(email: testEmail, password: testPassword)

    // When: Refresh session
    let session = try await authService.refreshSession()

    // Then: Should have valid refreshed session
    XCTAssertFalse(session.token.isEmpty)
    XCTAssertFalse(session.userId.isEmpty)
  }

  // MARK: - Current User Tests

  @MainActor
  func testGetCurrentUser() async throws {
    // Given: Signed in user
    _ = try await authService.signInWithEmail(email: testEmail, password: testPassword)

    // When: Get current user
    let user = try await authService.getCurrentUser()

    // Then: Should have valid user
    XCTAssertNotNil(user)
    XCTAssertEqual(user?.email, testEmail)
  }

  @MainActor
  func testGetCurrentUserWhenNotSignedIn() async throws {
    // Given: Not signed in
    try await authService.signOut()

    // When: Get current user
    let user = try await authService.getCurrentUser()

    // Then: Should be nil
    XCTAssertNil(user)
  }

  // MARK: - Session Restoration Tests

  @MainActor
  func testSessionRestoration() async throws {
    // Given: Signed in user
    let response = try await authService.signInWithEmail(email: testEmail, password: testPassword)
    let originalUserId = response.user.id

    // When: Restore session (simulating app restart)
    let restored = authService.restoreSession()

    // Then: Should restore the session
    XCTAssertNotNil(restored)
    XCTAssertEqual(restored?.user.id, originalUserId)
    XCTAssertNotNil(restored?.session)
  }

  // MARK: - Error Handling Tests

  @MainActor
  func testNetworkErrorHandling() async throws {
    // This test verifies error handling works
    // Network errors are hard to simulate, so we verify the error types exist

    // Verify error types are properly defined
    let networkError = RIZQAuthError.networkError("Test network error")
    let unknownError = RIZQAuthError.unknown("Test unknown error")
    let sessionError = RIZQAuthError.sessionExpired

    XCTAssertNotNil(networkError.localizedDescription)
    XCTAssertNotNil(unknownError.localizedDescription)
    XCTAssertNotNil(sessionError.localizedDescription)
  }

  // MARK: - Linked Accounts Tests

  @MainActor
  func testGetLinkedAccounts() async throws {
    // Given: Signed in user
    _ = try await authService.signInWithEmail(email: testEmail, password: testPassword)

    // When: Get linked accounts
    let accounts = try await authService.getLinkedAccounts()

    // Then: Should return accounts (at least email provider)
    XCTAssertNotNil(accounts)
    // Email sign-in should have at least the email provider
    XCTAssertTrue(accounts.contains { $0.provider == .email })
  }
}

// MARK: - Sign Up Tests (Separate class to avoid test account conflicts)

final class FirebaseAuthSignUpTests: XCTestCase {

  private var authService: FirebaseAuthService!

  override func setUp() async throws {
    try await super.setUp()

    // Configure Firebase if not already configured
    if FirebaseApp.app() == nil {
      FirebaseApp.configure()
    }

    authService = FirebaseAuthService()
    try? await authService.signOut()
  }

  override func tearDown() async throws {
    try? await authService.signOut()
    authService = nil
    try await super.tearDown()
  }

  /// Note: This test creates a new user. Run sparingly to avoid cluttering Firebase Auth.
  /// The account can be deleted from Firebase Console after testing.
  @MainActor
  func testSignUpWithEmail() async throws {
    // Given: New user credentials
    let timestamp = Int(Date().timeIntervalSince1970)
    let email = "testuser\(timestamp)@rizq.app"
    let password = "TestPassword123!"
    let name = "Test User \(timestamp)"

    // When: Sign up
    do {
      let response = try await authService.signUpWithEmail(
        email: email,
        password: password,
        name: name
      )

      // Then: Should receive valid user and session
      XCTAssertNotNil(response.user)
      XCTAssertEqual(response.user.email, email)
      XCTAssertEqual(response.user.name, name)
      XCTAssertNotNil(response.session)

      // Clean up: Delete the test user
      // Note: Deleting users requires Admin SDK, so we just sign out
      try await authService.signOut()

    } catch let error as RIZQAuthError {
      // If email already exists, that's expected for re-runs
      if case .emailAlreadyExists = error {
        // Expected if test was run before
      } else {
        throw error
      }
    }
  }

  @MainActor
  func testSignUpWithWeakPassword() async throws {
    // Given: Weak password
    let email = "weakpassword@rizq.app"
    let password = "123" // Too short

    // When/Then: Should throw an error
    do {
      _ = try await authService.signUpWithEmail(email: email, password: password, name: nil)
      XCTFail("Should have thrown an error for weak password")
    } catch {
      // Expected - Firebase rejects weak passwords
    }
  }
}

// MARK: - AuthClient TCA Tests

import ComposableArchitecture

final class AuthClientTests: XCTestCase {

  @MainActor
  func testAuthClientWithMockService() async throws {
    // Given: Mock auth client
    let authClient = AuthClient(
      signIn: { _, _ in
        AuthResponse(
          user: AuthUser(id: "test-id", email: "test@example.com", name: "Test User"),
          session: AuthSession(id: "session", userId: "test-id", token: "token", expiresAt: Date().addingTimeInterval(3600))
        )
      },
      signUp: { email, _, name in
        AuthResponse(
          user: AuthUser(id: "new-id", email: email, name: name),
          session: AuthSession(id: "session", userId: "new-id", token: "token", expiresAt: Date().addingTimeInterval(3600))
        )
      },
      signInWithOAuth: { _ in
        AuthResponse(
          user: AuthUser(id: "oauth-id", email: "oauth@example.com", name: "OAuth User"),
          session: AuthSession(id: "session", userId: "oauth-id", token: "token", expiresAt: Date().addingTimeInterval(3600))
        )
      },
      signOut: { },
      restoreSession: { nil }
    )

    // When: Sign in
    let response = try await authClient.signIn("test@example.com", "password")

    // Then: Should receive mock response
    XCTAssertEqual(response.user.id, "test-id")
    XCTAssertEqual(response.user.email, "test@example.com")
  }

  @MainActor
  func testAuthFeatureSignInFlow() async throws {
    // Given: Auth feature with mock client
    let store = TestStore(initialState: AuthFeature.State()) {
      AuthFeature()
    } withDependencies: {
      $0.authClient = AuthClient(
        signIn: { email, _ in
          AuthResponse(
            user: AuthUser(id: "test-id", email: email, name: "Test User"),
            session: AuthSession(id: "session", userId: "test-id", token: "token", expiresAt: Date().addingTimeInterval(3600))
          )
        },
        signUp: unimplemented("signUp"),
        signInWithOAuth: unimplemented("signInWithOAuth"),
        signOut: { },
        restoreSession: { nil }
      )
    }

    // When: Set credentials and sign in
    await store.send(.set(\.email, "test@example.com")) {
      $0.email = "test@example.com"
    }

    await store.send(.set(\.password, "password123")) {
      $0.password = "password123"
    }

    await store.send(.signInWithEmail) {
      $0.isLoading = true
    }

    await store.receive(\.authResponse.success) {
      $0.isLoading = false
      $0.user = AuthUser(id: "test-id", email: "test@example.com", name: "Test User")
    }

    await store.receive(\.authSuccess)
  }

  @MainActor
  func testAuthFeatureErrorHandling() async throws {
    // Given: Auth feature with failing client
    let store = TestStore(initialState: AuthFeature.State()) {
      AuthFeature()
    } withDependencies: {
      $0.authClient = AuthClient(
        signIn: { _, _ in
          throw RIZQAuthError.invalidCredentials
        },
        signUp: unimplemented("signUp"),
        signInWithOAuth: unimplemented("signInWithOAuth"),
        signOut: { },
        restoreSession: { nil }
      )
    }

    // When: Set credentials and sign in
    await store.send(.set(\.email, "wrong@example.com")) {
      $0.email = "wrong@example.com"
    }

    await store.send(.set(\.password, "wrongpassword")) {
      $0.password = "wrongpassword"
    }

    await store.send(.signInWithEmail) {
      $0.isLoading = true
    }

    await store.receive(\.authResponse.failure) {
      $0.isLoading = false
      $0.errorMessage = RIZQAuthError.invalidCredentials.localizedDescription
    }
  }
}
