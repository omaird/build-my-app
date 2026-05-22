import Foundation
import AuthenticationServices

// MARK: - Auth Service Protocol

public protocol AuthServiceProtocol: Sendable {
  // Sign In
  func signInWithEmail(email: String, password: String) async throws -> AuthResponse
  func signInWithOAuth(provider: AuthProvider, presentingWindow: ASPresentationAnchor?) async throws -> AuthResponse

  // Sign Up
  func signUpWithEmail(email: String, password: String, name: String?) async throws -> AuthResponse

  // Sign Out
  func signOut() async throws

  // Session Management
  func getSession() async throws -> AuthSession?
  func refreshSession() async throws -> AuthSession

  // User Profile (from auth system)
  func getCurrentUser() async throws -> AuthUser?

  // Linked Accounts
  func getLinkedAccounts() async throws -> [LinkedAccount]
  func linkAccount(provider: AuthProvider, presentingWindow: ASPresentationAnchor?) async throws -> LinkedAccount
  func unlinkAccount(provider: AuthProvider) async throws

  // Stored credentials
  func restoreSession() -> (user: AuthUser, session: AuthSession)?
  func clearStoredCredentials()
}

// MARK: - Mock Auth Service for Previews

public actor MockAuthService: AuthServiceProtocol {
  private var mockUser: AuthUser?
  private var mockSession: AuthSession?

  public init(authenticated: Bool = false) {
    if authenticated {
      mockUser = AuthUser(
        id: "mock-user-id",
        email: "test@example.com",
        name: "Test User",
        image: nil,
        emailVerified: true
      )
      mockSession = AuthSession(
        id: "mock-session-id",
        userId: "mock-user-id",
        token: "mock-token",
        expiresAt: Date().addingTimeInterval(86400)
      )
    }
  }

  public func signInWithEmail(email: String, password: String) async throws -> AuthResponse {
    mockUser = AuthUser(id: UUID().uuidString, email: email, name: nil)
    mockSession = AuthSession(
      id: UUID().uuidString,
      userId: mockUser!.id,
      token: UUID().uuidString,
      expiresAt: Date().addingTimeInterval(86400)
    )
    return AuthResponse(user: mockUser!, session: mockSession!)
  }

  public func signInWithOAuth(provider: AuthProvider, presentingWindow: ASPresentationAnchor?) async throws -> AuthResponse {
    mockUser = AuthUser(
      id: UUID().uuidString,
      email: "\(provider.rawValue)@example.com",
      name: "\(provider.displayName) User"
    )
    mockSession = AuthSession(
      id: UUID().uuidString,
      userId: mockUser!.id,
      token: UUID().uuidString,
      expiresAt: Date().addingTimeInterval(86400)
    )
    return AuthResponse(user: mockUser!, session: mockSession!)
  }

  public func signUpWithEmail(email: String, password: String, name: String?) async throws -> AuthResponse {
    mockUser = AuthUser(id: UUID().uuidString, email: email, name: name)
    mockSession = AuthSession(
      id: UUID().uuidString,
      userId: mockUser!.id,
      token: UUID().uuidString,
      expiresAt: Date().addingTimeInterval(86400)
    )
    return AuthResponse(user: mockUser!, session: mockSession!)
  }

  public func signOut() async throws {
    mockUser = nil
    mockSession = nil
  }

  public func getSession() async throws -> AuthSession? {
    mockSession
  }

  public func refreshSession() async throws -> AuthSession {
    guard let session = mockSession else { throw AuthError.sessionExpired }
    return session
  }

  public func getCurrentUser() async throws -> AuthUser? {
    mockUser
  }

  public func getLinkedAccounts() async throws -> [LinkedAccount] {
    []
  }

  public func linkAccount(provider: AuthProvider, presentingWindow: ASPresentationAnchor?) async throws -> LinkedAccount {
    LinkedAccount(
      id: UUID().uuidString,
      provider: provider,
      providerAccountId: UUID().uuidString
    )
  }

  public func unlinkAccount(provider: AuthProvider) async throws {
    // No-op
  }

  public nonisolated func restoreSession() -> (user: AuthUser, session: AuthSession)? {
    nil
  }

  public nonisolated func clearStoredCredentials() {
    // No-op
  }
}
