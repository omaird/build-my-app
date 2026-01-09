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

// MARK: - Auth Service Implementation

public actor AuthService: AuthServiceProtocol {
  private let configuration: AuthConfiguration
  private let keychain: KeychainService
  private let urlSession: URLSession

  public init(configuration: AuthConfiguration) {
    self.configuration = configuration
    self.keychain = KeychainService.shared
    self.urlSession = URLSession.shared
  }

  // MARK: - Email Sign In

  public func signInWithEmail(email: String, password: String) async throws -> AuthResponse {
    let url = configuration.baseURL.appendingPathComponent("/sign-in/email")

    var request = URLRequest(url: url)
    request.httpMethod = "POST"
    request.setValue("application/json", forHTTPHeaderField: "Content-Type")
    request.setValue("no-cache", forHTTPHeaderField: "Cache-Control")
    request.cachePolicy = .reloadIgnoringLocalAndRemoteCacheData

    let body = SignInRequest(email: email, password: password)
    request.httpBody = try JSONEncoder().encode(body)

    let (data, response) = try await urlSession.data(for: request)

    guard let httpResponse = response as? HTTPURLResponse else {
      throw AuthError.networkError("Invalid response")
    }

    print("[AuthService] Sign in response status: \(httpResponse.statusCode)")

    switch httpResponse.statusCode {
    case 200, 201:
      do {
        let authResponse = try decodeAuthResponse(from: data)
        try saveAuthState(authResponse)
        return authResponse
      } catch {
        // Log the raw response for debugging
        let rawResponse = String(data: data, encoding: .utf8) ?? "Unable to decode"
        print("[AuthService] Failed to decode response: \(error)")
        print("[AuthService] Raw response: \(rawResponse)")
        throw error
      }

    case 401:
      throw AuthError.invalidCredentials

    case 403:
      // Parse error message from response
      let errorMessage = String(data: data, encoding: .utf8) ?? "Access forbidden"
      print("[AuthService] Sign in 403 error: \(errorMessage)")
      throw AuthError.networkError(errorMessage)

    case 404:
      throw AuthError.userNotFound

    default:
      let errorMessage = String(data: data, encoding: .utf8) ?? "Unknown error"
      print("[AuthService] Sign in error (\(httpResponse.statusCode)): \(errorMessage)")
      throw AuthError.networkError(errorMessage)
    }
  }

  // MARK: - Email Sign Up

  public func signUpWithEmail(email: String, password: String, name: String?) async throws -> AuthResponse {
    let url = configuration.baseURL.appendingPathComponent("/sign-up/email")

    var request = URLRequest(url: url)
    request.httpMethod = "POST"
    request.setValue("application/json", forHTTPHeaderField: "Content-Type")
    request.setValue("no-cache", forHTTPHeaderField: "Cache-Control")
    request.cachePolicy = .reloadIgnoringLocalAndRemoteCacheData

    let body = SignUpRequest(email: email, password: password, name: name)
    request.httpBody = try JSONEncoder().encode(body)

    let (data, response) = try await urlSession.data(for: request)

    guard let httpResponse = response as? HTTPURLResponse else {
      throw AuthError.networkError("Invalid response")
    }

    print("[AuthService] Sign up response status: \(httpResponse.statusCode)")

    switch httpResponse.statusCode {
    case 200, 201:
      let authResponse = try decodeAuthResponse(from: data)
      try saveAuthState(authResponse)
      return authResponse

    case 409:
      throw AuthError.emailAlreadyExists

    default:
      let errorMessage = String(data: data, encoding: .utf8) ?? "Unknown error"
      print("[AuthService] Sign up error: \(errorMessage)")
      throw AuthError.networkError(errorMessage)
    }
  }

  // MARK: - OAuth Sign In

  public func signInWithOAuth(provider: AuthProvider, presentingWindow: ASPresentationAnchor?) async throws -> AuthResponse {
    guard provider != .email else {
      throw AuthError.oauthFailed("Email is not an OAuth provider")
    }

    // Build OAuth URL
    let callbackScheme = configuration.callbackScheme
    let callbackURL = "\(callbackScheme)://auth/callback"

    var components = URLComponents(url: configuration.baseURL.appendingPathComponent("/sign-in/social"), resolvingAgainstBaseURL: false)!
    components.queryItems = [
      URLQueryItem(name: "provider", value: provider.rawValue),
      URLQueryItem(name: "callbackURL", value: callbackURL)
    ]

    guard let authURL = components.url else {
      throw AuthError.oauthFailed("Failed to build OAuth URL")
    }

    // Perform OAuth flow using ASWebAuthenticationSession
    let callbackURLReceived = try await performOAuthFlow(url: authURL, callbackScheme: callbackScheme, presentingWindow: presentingWindow)

    // Extract token from callback URL
    guard let components = URLComponents(url: callbackURLReceived, resolvingAgainstBaseURL: false),
          let token = components.queryItems?.first(where: { $0.name == "token" })?.value else {
      throw AuthError.oauthFailed("No token in callback")
    }

    // Exchange token for session
    return try await exchangeToken(token)
  }

  private func performOAuthFlow(url: URL, callbackScheme: String, presentingWindow: ASPresentationAnchor?) async throws -> URL {
    // Use a class to track whether we've already resumed (must be reference type for capture)
    final class ResumeState: @unchecked Sendable {
      var hasResumed = false
      let lock = NSLock()

      func tryResume() -> Bool {
        lock.lock()
        defer { lock.unlock() }
        if hasResumed { return false }
        hasResumed = true
        return true
      }
    }

    return try await withCheckedThrowingContinuation { continuation in
      let state = ResumeState()

      let session = ASWebAuthenticationSession(url: url, callbackURLScheme: callbackScheme) { callbackURL, error in
        guard state.tryResume() else { return }

        if let error = error as? ASWebAuthenticationSessionError {
          if error.code == .canceledLogin {
            continuation.resume(throwing: AuthError.oauthCancelled)
          } else {
            continuation.resume(throwing: AuthError.oauthFailed(error.localizedDescription))
          }
          return
        }

        guard let callbackURL = callbackURL else {
          continuation.resume(throwing: AuthError.oauthFailed("No callback URL received"))
          return
        }

        continuation.resume(returning: callbackURL)
      }

      session.presentationContextProvider = OAuthPresentationContextProvider(anchor: presentingWindow)
      session.prefersEphemeralWebBrowserSession = false

      if !session.start() {
        guard state.tryResume() else { return }
        continuation.resume(throwing: AuthError.oauthFailed("Failed to start OAuth session"))
      }
    }
  }

  private func exchangeToken(_ token: String) async throws -> AuthResponse {
    let url = configuration.baseURL.appendingPathComponent("/get-session")

    var request = URLRequest(url: url)
    request.httpMethod = "GET"
    request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

    let (data, response) = try await urlSession.data(for: request)

    guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
      throw AuthError.oauthFailed("Failed to exchange token for session")
    }

    let authResponse = try decodeAuthResponse(from: data)
    try saveAuthState(authResponse)
    return authResponse
  }

  // MARK: - Sign Out

  public func signOut() async throws {
    // Call server to invalidate session
    if let token = keychain.getSessionToken() {
      let url = configuration.baseURL.appendingPathComponent("/sign-out")
      var request = URLRequest(url: url)
      request.httpMethod = "POST"
      request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

      // Fire and forget - we'll clear local state regardless
      _ = try? await urlSession.data(for: request)
    }

    // Clear local state
    keychain.clearAll()
  }

  // MARK: - Session Management

  public func getSession() async throws -> AuthSession? {
    guard let token = keychain.getSessionToken() else { return nil }

    let url = configuration.baseURL.appendingPathComponent("/get-session")
    var request = URLRequest(url: url)
    request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

    let (data, response) = try await urlSession.data(for: request)

    guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
      // Session invalid, clear local state
      keychain.clearAll()
      return nil
    }

    let authResponse = try decodeAuthResponse(from: data)
    try saveAuthState(authResponse)
    return authResponse.session
  }

  public func refreshSession() async throws -> AuthSession {
    guard let token = keychain.getSessionToken() else {
      throw AuthError.sessionExpired
    }

    let url = configuration.baseURL.appendingPathComponent("/session")
    var request = URLRequest(url: url)
    request.httpMethod = "POST"
    request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

    let (data, response) = try await urlSession.data(for: request)

    guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
      keychain.clearAll()
      throw AuthError.sessionExpired
    }

    let authResponse = try decodeAuthResponse(from: data)
    try saveAuthState(authResponse)
    return authResponse.session
  }

  // MARK: - Current User

  public func getCurrentUser() async throws -> AuthUser? {
    guard let token = keychain.getSessionToken() else { return nil }

    let url = configuration.baseURL.appendingPathComponent("/get-session")
    var request = URLRequest(url: url)
    request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

    let (data, response) = try await urlSession.data(for: request)

    guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
      return nil
    }

    let authResponse = try decodeAuthResponse(from: data)
    return authResponse.user
  }

  // MARK: - Linked Accounts

  public func getLinkedAccounts() async throws -> [LinkedAccount] {
    guard let token = keychain.getSessionToken() else {
      throw AuthError.sessionExpired
    }

    let url = configuration.baseURL.appendingPathComponent("/list-accounts")
    var request = URLRequest(url: url)
    request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

    let (data, response) = try await urlSession.data(for: request)

    guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
      throw AuthError.networkError("Failed to fetch linked accounts")
    }

    let decoder = JSONDecoder()
    decoder.dateDecodingStrategy = .iso8601
    return try decoder.decode([LinkedAccount].self, from: data)
  }

  public func linkAccount(provider: AuthProvider, presentingWindow: ASPresentationAnchor?) async throws -> LinkedAccount {
    guard provider != .email else {
      throw AuthError.oauthFailed("Cannot link email accounts")
    }

    guard let token = keychain.getSessionToken() else {
      throw AuthError.sessionExpired
    }

    // Build link account OAuth URL
    let callbackScheme = configuration.callbackScheme
    let callbackURL = "\(callbackScheme)://auth/link-callback"

    var components = URLComponents(url: configuration.baseURL.appendingPathComponent("/link-social"), resolvingAgainstBaseURL: false)!
    components.queryItems = [
      URLQueryItem(name: "provider", value: provider.rawValue),
      URLQueryItem(name: "callbackURL", value: callbackURL)
    ]

    guard let authURL = components.url else {
      throw AuthError.oauthFailed("Failed to build link account URL")
    }

    // Perform OAuth flow
    _ = try await performOAuthFlow(url: authURL, callbackScheme: callbackScheme, presentingWindow: presentingWindow)

    // Fetch updated linked accounts
    let accounts = try await getLinkedAccounts()
    guard let linkedAccount = accounts.first(where: { $0.provider == provider }) else {
      throw AuthError.oauthFailed("Account linking failed")
    }

    return linkedAccount
  }

  public func unlinkAccount(provider: AuthProvider) async throws {
    guard let token = keychain.getSessionToken() else {
      throw AuthError.sessionExpired
    }

    let url = configuration.baseURL.appendingPathComponent("/unlink-account")
    var request = URLRequest(url: url)
    request.httpMethod = "POST"
    request.setValue("application/json", forHTTPHeaderField: "Content-Type")
    request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

    let body = ["provider": provider.rawValue]
    request.httpBody = try JSONEncoder().encode(body)

    let (_, response) = try await urlSession.data(for: request)

    guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
      throw AuthError.networkError("Failed to unlink account")
    }
  }

  // MARK: - Stored Credentials

  public nonisolated func restoreSession() -> (user: AuthUser, session: AuthSession)? {
    keychain.restoreAuthState()
  }

  public nonisolated func clearStoredCredentials() {
    keychain.clearAll()
  }

  // MARK: - Helpers

  private func decodeAuthResponse(from data: Data) throws -> AuthResponse {
    let decoder = JSONDecoder()
    decoder.dateDecodingStrategy = .iso8601
    // Decode the Neon Auth response format and convert to our AuthResponse
    // Format: { "data": { "session": { "access_token", "expires_at" }, "user": {...} } }
    let neonAuthResponse = try decoder.decode(NeonAuthResponse.self, from: data)
    return AuthResponse(from: neonAuthResponse)
  }

  private func saveAuthState(_ response: AuthResponse) throws {
    try keychain.saveSessionToken(response.session.token)
    try keychain.saveUserId(response.user.id)
    try keychain.saveAuthUser(response.user)
    try keychain.saveAuthSession(response.session)
  }
}

// MARK: - Auth Configuration

public struct AuthConfiguration: Sendable {
  public let baseURL: URL
  public let callbackScheme: String

  public init(baseURL: URL, callbackScheme: String = "rizq") {
    self.baseURL = baseURL
    self.callbackScheme = callbackScheme
  }

  public init(authURLString: String, callbackScheme: String = "rizq") {
    self.baseURL = URL(string: authURLString)!
    self.callbackScheme = callbackScheme
  }
}

// MARK: - OAuth Presentation Context Provider

private final class OAuthPresentationContextProvider: NSObject, ASWebAuthenticationPresentationContextProviding, @unchecked Sendable {
  private let anchor: ASPresentationAnchor?

  init(anchor: ASPresentationAnchor?) {
    self.anchor = anchor
  }

  func presentationAnchor(for session: ASWebAuthenticationSession) -> ASPresentationAnchor {
    anchor ?? ASPresentationAnchor()
  }
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
