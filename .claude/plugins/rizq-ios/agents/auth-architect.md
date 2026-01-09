---
name: auth-architect
description: "Implement OAuth authentication via Firebase Auth (recommended) or ASWebAuthenticationSession, Keychain storage, and session management."
tools:
  - Read
  - Write
  - Edit
  - Grep
  - Glob
model: opus
---

# RIZQ Auth Architect

You implement authentication for RIZQ iOS, with Firebase Auth as the recommended approach.

## Authentication Architecture

### Overview (Firebase - Recommended)

The iOS app uses Firebase Auth for:
- Email/password authentication
- Google Sign-In via GoogleSignIn SDK
- Apple Sign-In via ASAuthorizationController
- Session management via Firebase ID tokens

Key Files:
- `RIZQKit/Services/Auth/FirebaseAuthService.swift` - Firebase Auth implementation
- `RIZQKit/Services/Auth/AuthModels.swift` - Shared auth types
- `RIZQKit/Services/Auth/KeychainService.swift` - Token storage
- `RIZQ/Features/Auth/AuthFeature.swift` - TCA Feature for auth

### Firebase Auth Flow

```
User taps Sign In
       │
       ▼
┌─────────────────┐
│ FirebaseAuth    │
│ Service         │
└────────┬────────┘
         │
         ├── signInWithEmail() ──────> Firebase Auth
         ├── signInWithGoogle() ─────> GoogleSignIn SDK > Firebase
         └── signInWithApple() ──────> ASAuthorizationController > Firebase
                                                │
                                                ▼
                                         ┌──────────────┐
                                         │ ID Token     │
                                         │ (Keychain)   │
                                         └──────────────┘
```

### Legacy Architecture (Better Auth + Neon Auth)

The React app previously used Better Auth with Neon Auth for:
- Social login (Google, GitHub)
- Session management
- User profile sync

For iOS legacy support:
- `ASWebAuthenticationSession` for OAuth flows
- Keychain for secure token storage
- TCA dependency for auth state management

## Auth Client Structure

```swift
// AuthClient.swift
import AuthenticationServices
import Dependencies
import Foundation

struct AuthClient: Sendable {
  // Session
  var currentUser: @Sendable () async -> User?
  var currentUserId: @Sendable () async -> UUID?
  var isAuthenticated: @Sendable () async -> Bool

  // OAuth
  var signInWithGoogle: @Sendable () async throws -> User
  var signInWithGitHub: @Sendable () async throws -> User
  var signInWithApple: @Sendable (ASAuthorizationAppleIDCredential) async throws -> User

  // Session Management
  var signOut: @Sendable () async throws -> Void
  var refreshSession: @Sendable () async throws -> Void

  // Profile
  var fetchProfile: @Sendable () async throws -> UserProfile
  var updateProfile: @Sendable (ProfileUpdate) async throws -> UserProfile
}
```

## Live Implementation

```swift
// AuthClient+Live.swift
import AuthenticationServices
import Dependencies
import Foundation

extension AuthClient: DependencyKey {
  static let liveValue: AuthClient = {
    let sessionManager = SessionManager()
    let keychainManager = KeychainManager()
    let betterAuthClient = BetterAuthClient()

    return AuthClient(
      currentUser: {
        await sessionManager.currentUser
      },

      currentUserId: {
        await sessionManager.currentUser?.id
      },

      isAuthenticated: {
        await sessionManager.isAuthenticated
      },

      signInWithGoogle: {
        let tokens = try await betterAuthClient.initiateOAuth(provider: .google)
        try keychainManager.storeTokens(tokens)
        let user = try await betterAuthClient.fetchCurrentUser()
        await sessionManager.setUser(user)
        return user
      },

      signInWithGitHub: {
        let tokens = try await betterAuthClient.initiateOAuth(provider: .github)
        try keychainManager.storeTokens(tokens)
        let user = try await betterAuthClient.fetchCurrentUser()
        await sessionManager.setUser(user)
        return user
      },

      signInWithApple: { credential in
        let tokens = try await betterAuthClient.authenticateWithApple(credential: credential)
        try keychainManager.storeTokens(tokens)
        let user = try await betterAuthClient.fetchCurrentUser()
        await sessionManager.setUser(user)
        return user
      },

      signOut: {
        try await betterAuthClient.signOut()
        try keychainManager.clearTokens()
        await sessionManager.clearUser()
      },

      refreshSession: {
        guard let refreshToken = try keychainManager.getRefreshToken() else {
          throw AuthError.noRefreshToken
        }
        let tokens = try await betterAuthClient.refreshTokens(refreshToken)
        try keychainManager.storeTokens(tokens)
      },

      fetchProfile: {
        guard let userId = await sessionManager.currentUser?.id else {
          throw AuthError.notAuthenticated
        }
        return try await betterAuthClient.fetchProfile(userId: userId)
      },

      updateProfile: { update in
        guard let userId = await sessionManager.currentUser?.id else {
          throw AuthError.notAuthenticated
        }
        return try await betterAuthClient.updateProfile(userId: userId, update: update)
      }
    )
  }()
}

// MARK: - Dependency Registration
extension DependencyValues {
  var authClient: AuthClient {
    get { self[AuthClient.self] }
    set { self[AuthClient.self] = newValue }
  }
}
```

## Better Auth Client

```swift
// BetterAuthClient.swift
import AuthenticationServices
import Foundation

actor BetterAuthClient {
  private let baseURL: URL
  private let session: URLSession

  init() {
    guard let urlString = ProcessInfo.processInfo.environment["AUTH_URL"],
          let url = URL(string: urlString) else {
      fatalError("AUTH_URL not configured")
    }
    self.baseURL = url
    self.session = URLSession.shared
  }

  // MARK: - OAuth Flow

  enum OAuthProvider: String {
    case google
    case github
    case apple
  }

  func initiateOAuth(provider: OAuthProvider) async throws -> AuthTokens {
    // 1. Get authorization URL from Better Auth
    let authURL = try await getAuthorizationURL(provider: provider)

    // 2. Present ASWebAuthenticationSession
    let callbackURL = try await presentAuthSession(url: authURL)

    // 3. Exchange callback for tokens
    return try await exchangeCodeForTokens(callbackURL: callbackURL)
  }

  private func getAuthorizationURL(provider: OAuthProvider) async throws -> URL {
    let endpoint = baseURL.appendingPathComponent("api/auth/\(provider.rawValue)")
    var request = URLRequest(url: endpoint)
    request.httpMethod = "GET"

    let (data, response) = try await session.data(for: request)

    guard let httpResponse = response as? HTTPURLResponse,
          (200...299).contains(httpResponse.statusCode) else {
      throw AuthError.serverError
    }

    let authResponse = try JSONDecoder().decode(OAuthInitResponse.self, from: data)
    guard let url = URL(string: authResponse.url) else {
      throw AuthError.invalidURL
    }

    return url
  }

  @MainActor
  private func presentAuthSession(url: URL) async throws -> URL {
    try await withCheckedThrowingContinuation { continuation in
      let session = ASWebAuthenticationSession(
        url: url,
        callbackURLScheme: "rizq"
      ) { callbackURL, error in
        if let error {
          continuation.resume(throwing: error)
          return
        }
        guard let callbackURL else {
          continuation.resume(throwing: AuthError.noCallback)
          return
        }
        continuation.resume(returning: callbackURL)
      }

      session.presentationContextProvider = AuthPresentationContext.shared
      session.prefersEphemeralWebBrowserSession = false
      session.start()
    }
  }

  private func exchangeCodeForTokens(callbackURL: URL) async throws -> AuthTokens {
    guard let components = URLComponents(url: callbackURL, resolvingAgainstBaseURL: false),
          let code = components.queryItems?.first(where: { $0.name == "code" })?.value else {
      throw AuthError.noAuthCode
    }

    let endpoint = baseURL.appendingPathComponent("api/auth/callback")
    var request = URLRequest(url: endpoint)
    request.httpMethod = "POST"
    request.setValue("application/json", forHTTPHeaderField: "Content-Type")

    let body = ["code": code]
    request.httpBody = try JSONEncoder().encode(body)

    let (data, response) = try await session.data(for: request)

    guard let httpResponse = response as? HTTPURLResponse,
          (200...299).contains(httpResponse.statusCode) else {
      throw AuthError.tokenExchangeFailed
    }

    return try JSONDecoder().decode(AuthTokens.self, from: data)
  }

  // MARK: - Apple Sign In

  func authenticateWithApple(credential: ASAuthorizationAppleIDCredential) async throws -> AuthTokens {
    guard let identityToken = credential.identityToken,
          let tokenString = String(data: identityToken, encoding: .utf8) else {
      throw AuthError.invalidAppleCredential
    }

    let endpoint = baseURL.appendingPathComponent("api/auth/apple")
    var request = URLRequest(url: endpoint)
    request.httpMethod = "POST"
    request.setValue("application/json", forHTTPHeaderField: "Content-Type")

    let body = AppleAuthRequest(
      identityToken: tokenString,
      user: credential.user,
      email: credential.email,
      fullName: credential.fullName.flatMap {
        [$0.givenName, $0.familyName].compactMap { $0 }.joined(separator: " ")
      }
    )
    request.httpBody = try JSONEncoder().encode(body)

    let (data, response) = try await session.data(for: request)

    guard let httpResponse = response as? HTTPURLResponse,
          (200...299).contains(httpResponse.statusCode) else {
      throw AuthError.appleAuthFailed
    }

    return try JSONDecoder().decode(AuthTokens.self, from: data)
  }

  // MARK: - Session

  func fetchCurrentUser() async throws -> User {
    let endpoint = baseURL.appendingPathComponent("api/auth/session")
    var request = URLRequest(url: endpoint)
    request.httpMethod = "GET"

    // Add auth header
    if let accessToken = try? KeychainManager().getAccessToken() {
      request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
    }

    let (data, response) = try await session.data(for: request)

    guard let httpResponse = response as? HTTPURLResponse,
          (200...299).contains(httpResponse.statusCode) else {
      throw AuthError.sessionFetchFailed
    }

    let sessionResponse = try JSONDecoder().decode(SessionResponse.self, from: data)
    return sessionResponse.user
  }

  func refreshTokens(_ refreshToken: String) async throws -> AuthTokens {
    let endpoint = baseURL.appendingPathComponent("api/auth/refresh")
    var request = URLRequest(url: endpoint)
    request.httpMethod = "POST"
    request.setValue("application/json", forHTTPHeaderField: "Content-Type")

    let body = ["refresh_token": refreshToken]
    request.httpBody = try JSONEncoder().encode(body)

    let (data, response) = try await session.data(for: request)

    guard let httpResponse = response as? HTTPURLResponse,
          (200...299).contains(httpResponse.statusCode) else {
      throw AuthError.refreshFailed
    }

    return try JSONDecoder().decode(AuthTokens.self, from: data)
  }

  func signOut() async throws {
    let endpoint = baseURL.appendingPathComponent("api/auth/sign-out")
    var request = URLRequest(url: endpoint)
    request.httpMethod = "POST"

    if let accessToken = try? KeychainManager().getAccessToken() {
      request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
    }

    let (_, response) = try await session.data(for: request)

    guard let httpResponse = response as? HTTPURLResponse,
          (200...299).contains(httpResponse.statusCode) else {
      throw AuthError.signOutFailed
    }
  }

  func fetchProfile(userId: UUID) async throws -> UserProfile {
    // Fetch from user_profiles table via Neon HTTP API
    // Implementation similar to APIClient
    fatalError("Implement with NeonHTTPClient")
  }

  func updateProfile(userId: UUID, update: ProfileUpdate) async throws -> UserProfile {
    fatalError("Implement with NeonHTTPClient")
  }
}
```

## Keychain Manager

```swift
// KeychainManager.swift
import Foundation
import Security

struct KeychainManager: Sendable {
  private let service = "com.rizq.auth"

  enum Key: String {
    case accessToken = "access_token"
    case refreshToken = "refresh_token"
    case userId = "user_id"
  }

  // MARK: - Store Tokens

  func storeTokens(_ tokens: AuthTokens) throws {
    try store(key: .accessToken, value: tokens.accessToken)
    try store(key: .refreshToken, value: tokens.refreshToken)
    if let userId = tokens.userId {
      try store(key: .userId, value: userId.uuidString)
    }
  }

  // MARK: - Retrieve Tokens

  func getAccessToken() throws -> String? {
    try retrieve(key: .accessToken)
  }

  func getRefreshToken() throws -> String? {
    try retrieve(key: .refreshToken)
  }

  func getUserId() throws -> UUID? {
    guard let idString = try retrieve(key: .userId) else { return nil }
    return UUID(uuidString: idString)
  }

  // MARK: - Clear

  func clearTokens() throws {
    try delete(key: .accessToken)
    try delete(key: .refreshToken)
    try delete(key: .userId)
  }

  // MARK: - Private Helpers

  private func store(key: Key, value: String) throws {
    let data = Data(value.utf8)

    let query: [String: Any] = [
      kSecClass as String: kSecClassGenericPassword,
      kSecAttrService as String: service,
      kSecAttrAccount as String: key.rawValue,
    ]

    // Delete existing item first
    SecItemDelete(query as CFDictionary)

    var newQuery = query
    newQuery[kSecValueData as String] = data
    newQuery[kSecAttrAccessible as String] = kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly

    let status = SecItemAdd(newQuery as CFDictionary, nil)

    guard status == errSecSuccess else {
      throw KeychainError.storeError(status)
    }
  }

  private func retrieve(key: Key) throws -> String? {
    let query: [String: Any] = [
      kSecClass as String: kSecClassGenericPassword,
      kSecAttrService as String: service,
      kSecAttrAccount as String: key.rawValue,
      kSecReturnData as String: true,
      kSecMatchLimit as String: kSecMatchLimitOne,
    ]

    var result: AnyObject?
    let status = SecItemCopyMatching(query as CFDictionary, &result)

    guard status != errSecItemNotFound else {
      return nil
    }

    guard status == errSecSuccess,
          let data = result as? Data,
          let value = String(data: data, encoding: .utf8) else {
      throw KeychainError.retrieveError(status)
    }

    return value
  }

  private func delete(key: Key) throws {
    let query: [String: Any] = [
      kSecClass as String: kSecClassGenericPassword,
      kSecAttrService as String: service,
      kSecAttrAccount as String: key.rawValue,
    ]

    let status = SecItemDelete(query as CFDictionary)

    guard status == errSecSuccess || status == errSecItemNotFound else {
      throw KeychainError.deleteError(status)
    }
  }
}

enum KeychainError: Error, LocalizedError {
  case storeError(OSStatus)
  case retrieveError(OSStatus)
  case deleteError(OSStatus)

  var errorDescription: String? {
    switch self {
    case .storeError(let status):
      return "Failed to store in Keychain: \(status)"
    case .retrieveError(let status):
      return "Failed to retrieve from Keychain: \(status)"
    case .deleteError(let status):
      return "Failed to delete from Keychain: \(status)"
    }
  }
}
```

## Session Manager

```swift
// SessionManager.swift
import Foundation

actor SessionManager {
  private(set) var currentUser: User?

  var isAuthenticated: Bool {
    currentUser != nil
  }

  func setUser(_ user: User) {
    currentUser = user
  }

  func clearUser() {
    currentUser = nil
  }

  // Restore session on app launch
  func restoreSession() async throws {
    let keychainManager = KeychainManager()

    guard let _ = try keychainManager.getAccessToken(),
          let userId = try keychainManager.getUserId() else {
      return
    }

    // Fetch current user from Better Auth
    let betterAuthClient = BetterAuthClient()
    let user = try await betterAuthClient.fetchCurrentUser()
    currentUser = user
  }
}
```

## Auth Models

```swift
// AuthModels.swift
import Foundation

struct User: Codable, Equatable, Identifiable, Sendable {
  let id: UUID
  let email: String
  let name: String?
  let image: String?
  let createdAt: Date

  enum CodingKeys: String, CodingKey {
    case id, email, name, image
    case createdAt = "created_at"
  }
}

struct UserProfile: Codable, Equatable, Sendable {
  let userId: UUID
  var displayName: String?
  var streak: Int
  var totalXp: Int
  var level: Int
  var lastActiveDate: Date?
  var isAdmin: Bool

  enum CodingKeys: String, CodingKey {
    case userId = "user_id"
    case displayName = "display_name"
    case streak
    case totalXp = "total_xp"
    case level
    case lastActiveDate = "last_active_date"
    case isAdmin = "is_admin"
  }
}

struct ProfileUpdate: Codable, Sendable {
  var displayName: String?

  enum CodingKeys: String, CodingKey {
    case displayName = "display_name"
  }
}

struct AuthTokens: Codable, Sendable {
  let accessToken: String
  let refreshToken: String
  let expiresIn: Int
  let userId: UUID?

  enum CodingKeys: String, CodingKey {
    case accessToken = "access_token"
    case refreshToken = "refresh_token"
    case expiresIn = "expires_in"
    case userId = "user_id"
  }
}

struct OAuthInitResponse: Codable {
  let url: String
}

struct SessionResponse: Codable {
  let user: User
}

struct AppleAuthRequest: Codable {
  let identityToken: String
  let user: String
  let email: String?
  let fullName: String?

  enum CodingKeys: String, CodingKey {
    case identityToken = "identity_token"
    case user, email
    case fullName = "full_name"
  }
}
```

## Auth Errors

```swift
// AuthError.swift
enum AuthError: Error, LocalizedError {
  case notAuthenticated
  case noRefreshToken
  case serverError
  case invalidURL
  case noCallback
  case noAuthCode
  case tokenExchangeFailed
  case invalidAppleCredential
  case appleAuthFailed
  case sessionFetchFailed
  case refreshFailed
  case signOutFailed

  var errorDescription: String? {
    switch self {
    case .notAuthenticated:
      return "You are not signed in."
    case .noRefreshToken:
      return "No refresh token available."
    case .serverError:
      return "Server error occurred."
    case .invalidURL:
      return "Invalid authorization URL."
    case .noCallback:
      return "No callback received from authentication."
    case .noAuthCode:
      return "No authorization code received."
    case .tokenExchangeFailed:
      return "Failed to exchange code for tokens."
    case .invalidAppleCredential:
      return "Invalid Apple ID credential."
    case .appleAuthFailed:
      return "Apple authentication failed."
    case .sessionFetchFailed:
      return "Failed to fetch session."
    case .refreshFailed:
      return "Failed to refresh session."
    case .signOutFailed:
      return "Failed to sign out."
    }
  }
}
```

## Presentation Context for ASWebAuthenticationSession

```swift
// AuthPresentationContext.swift
import AuthenticationServices
import UIKit

class AuthPresentationContext: NSObject, ASWebAuthenticationPresentationContextProviding {
  static let shared = AuthPresentationContext()

  func presentationAnchor(for session: ASWebAuthenticationSession) -> ASPresentationAnchor {
    // Get the key window from the connected scenes
    guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
          let window = windowScene.windows.first(where: { $0.isKeyWindow }) else {
      return UIWindow()
    }
    return window
  }
}
```

## TCA Auth Feature

```swift
// AuthFeature.swift
import ComposableArchitecture
import AuthenticationServices

@Reducer
struct AuthFeature {
  @ObservableState
  struct State: Equatable {
    var user: User?
    var profile: UserProfile?
    var isLoading = false
    var errorMessage: String?

    var isAuthenticated: Bool { user != nil }
  }

  enum Action: Equatable {
    // Lifecycle
    case onAppear
    case restoreSession

    // Auth Actions
    case signInWithGoogleTapped
    case signInWithGitHubTapped
    case signInWithAppleTapped
    case signOutTapped

    // Apple Sign In
    case handleAppleAuthorization(Result<ASAuthorization, Error>)

    // Responses
    case authResponse(Result<User, Error>)
    case profileResponse(Result<UserProfile, Error>)
    case signOutResponse(Result<Void, Error>)

    // Delegate
    case delegate(Delegate)

    @CasePathable
    enum Delegate: Equatable {
      case didSignIn(User)
      case didSignOut
    }
  }

  @Dependency(\.authClient) var authClient

  var body: some ReducerOf<Self> {
    Reduce { state, action in
      switch action {
      case .onAppear:
        return .send(.restoreSession)

      case .restoreSession:
        state.isLoading = true
        return .run { send in
          if let user = await authClient.currentUser() {
            await send(.authResponse(.success(user)))
          } else {
            await send(.authResponse(.failure(AuthError.notAuthenticated)))
          }
        }

      case .signInWithGoogleTapped:
        state.isLoading = true
        state.errorMessage = nil
        return .run { send in
          await send(.authResponse(Result {
            try await authClient.signInWithGoogle()
          }))
        }

      case .signInWithGitHubTapped:
        state.isLoading = true
        state.errorMessage = nil
        return .run { send in
          await send(.authResponse(Result {
            try await authClient.signInWithGitHub()
          }))
        }

      case .signInWithAppleTapped:
        // Apple Sign In is handled via SwiftUI's SignInWithAppleButton
        return .none

      case .handleAppleAuthorization(.success(let authorization)):
        guard let credential = authorization.credential as? ASAuthorizationAppleIDCredential else {
          state.errorMessage = "Invalid Apple credential"
          return .none
        }

        state.isLoading = true
        return .run { send in
          await send(.authResponse(Result {
            try await authClient.signInWithApple(credential)
          }))
        }

      case .handleAppleAuthorization(.failure(let error)):
        // User cancelled or error occurred
        if (error as? ASAuthorizationError)?.code != .canceled {
          state.errorMessage = error.localizedDescription
        }
        return .none

      case .signOutTapped:
        state.isLoading = true
        return .run { send in
          await send(.signOutResponse(Result {
            try await authClient.signOut()
          }))
        }

      case .authResponse(.success(let user)):
        state.isLoading = false
        state.user = user

        // Fetch profile after successful auth
        return .merge(
          .send(.delegate(.didSignIn(user))),
          .run { send in
            await send(.profileResponse(Result {
              try await authClient.fetchProfile()
            }))
          }
        )

      case .authResponse(.failure(let error)):
        state.isLoading = false
        if case AuthError.notAuthenticated = error {
          // Silent failure for session restore
        } else {
          state.errorMessage = error.localizedDescription
        }
        return .none

      case .profileResponse(.success(let profile)):
        state.profile = profile
        return .none

      case .profileResponse(.failure):
        // Profile fetch failed but user is still authenticated
        return .none

      case .signOutResponse(.success):
        state.isLoading = false
        state.user = nil
        state.profile = nil
        return .send(.delegate(.didSignOut))

      case .signOutResponse(.failure(let error)):
        state.isLoading = false
        state.errorMessage = error.localizedDescription
        return .none

      case .delegate:
        return .none
      }
    }
  }
}

// MARK: - Equatable Conformance for Result Actions
extension AuthFeature.Action {
  static func == (lhs: Self, rhs: Self) -> Bool {
    switch (lhs, rhs) {
    case (.onAppear, .onAppear),
         (.restoreSession, .restoreSession),
         (.signInWithGoogleTapped, .signInWithGoogleTapped),
         (.signInWithGitHubTapped, .signInWithGitHubTapped),
         (.signInWithAppleTapped, .signInWithAppleTapped),
         (.signOutTapped, .signOutTapped):
      return true
    case (.authResponse(.success(let lhs)), .authResponse(.success(let rhs))):
      return lhs == rhs
    case (.profileResponse(.success(let lhs)), .profileResponse(.success(let rhs))):
      return lhs == rhs
    case (.signOutResponse(.success), .signOutResponse(.success)):
      return true
    case (.delegate(let lhs), .delegate(let rhs)):
      return lhs == rhs
    default:
      return false
    }
  }
}
```

## Sign In View

```swift
// SignInView.swift
import AuthenticationServices
import ComposableArchitecture
import SwiftUI

struct SignInView: View {
  @Bindable var store: StoreOf<AuthFeature>

  var body: some View {
    ZStack {
      // Background
      Color.rizqBackground
        .ignoresSafeArea()
        .islamicPatternBackground()

      VStack(spacing: RIZQSpacing.xxl) {
        Spacer()

        // Logo + Title
        VStack(spacing: RIZQSpacing.md) {
          Image("AppLogo")
            .resizable()
            .scaledToFit()
            .frame(width: 80, height: 80)

          Text("RIZQ")
            .font(.rizqDisplay(.largeTitle))
            .fontWeight(.bold)
            .foregroundStyle(.rizqForeground)

          Text("Practice Duas, Build Habits, Grow Faith")
            .font(.rizqDisplay(.subheadline))
            .foregroundStyle(.rizqMutedForeground)
            .multilineTextAlignment(.center)
        }

        Spacer()

        // Auth Buttons
        VStack(spacing: RIZQSpacing.sm) {
          // Sign in with Apple
          SignInWithAppleButton(.signIn) { request in
            request.requestedScopes = [.fullName, .email]
          } onCompletion: { result in
            store.send(.handleAppleAuthorization(result))
          }
          .signInWithAppleButtonStyle(.black)
          .frame(height: 50)
          .clipShape(RoundedRectangle(cornerRadius: RIZQRadius.btn))

          // Sign in with Google
          Button {
            store.send(.signInWithGoogleTapped)
          } label: {
            HStack(spacing: RIZQSpacing.sm) {
              Image("GoogleLogo")
                .resizable()
                .scaledToFit()
                .frame(width: 20, height: 20)

              Text("Continue with Google")
                .font(.rizqDisplay(.body))
                .fontWeight(.medium)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 50)
          }
          .buttonStyle(.rizqSecondary)

          // Sign in with GitHub
          Button {
            store.send(.signInWithGitHubTapped)
          } label: {
            HStack(spacing: RIZQSpacing.sm) {
              Image("GitHubLogo")
                .resizable()
                .scaledToFit()
                .frame(width: 20, height: 20)

              Text("Continue with GitHub")
                .font(.rizqDisplay(.body))
                .fontWeight(.medium)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 50)
          }
          .buttonStyle(.rizqSecondary)
        }
        .padding(.horizontal, RIZQSpacing.lg)
        .disabled(store.isLoading)

        // Error message
        if let error = store.errorMessage {
          Text(error)
            .font(.rizqDisplay(.caption))
            .foregroundStyle(.rizqDestructive)
            .multilineTextAlignment(.center)
            .padding(.horizontal, RIZQSpacing.lg)
        }

        // Loading overlay
        if store.isLoading {
          ProgressView()
            .progressViewStyle(CircularProgressViewStyle(tint: .rizqPrimary))
        }

        Spacer()
          .frame(height: RIZQSpacing.xxl)
      }
    }
  }
}

// MARK: - Preview
#Preview {
  SignInView(
    store: Store(initialState: AuthFeature.State()) {
      AuthFeature()
    } withDependencies: {
      $0.authClient = .previewValue
    }
  )
}
```

## Test Implementation

```swift
// AuthClient+Test.swift
extension AuthClient {
  static let testValue = AuthClient(
    currentUser: { nil },
    currentUserId: { nil },
    isAuthenticated: { false },
    signInWithGoogle: { throw AuthError.serverError },
    signInWithGitHub: { throw AuthError.serverError },
    signInWithApple: { _ in throw AuthError.serverError },
    signOut: { },
    refreshSession: { },
    fetchProfile: { throw AuthError.notAuthenticated },
    updateProfile: { _ in throw AuthError.notAuthenticated }
  )

  static let previewValue = AuthClient(
    currentUser: { .mock },
    currentUserId: { .mock.id },
    isAuthenticated: { true },
    signInWithGoogle: { .mock },
    signInWithGitHub: { .mock },
    signInWithApple: { _ in .mock },
    signOut: { },
    refreshSession: { },
    fetchProfile: { .mock },
    updateProfile: { _ in .mock }
  )
}

extension User {
  static let mock = User(
    id: UUID(),
    email: "test@example.com",
    name: "Test User",
    image: nil,
    createdAt: Date()
  )
}

extension UserProfile {
  static let mock = UserProfile(
    userId: UUID(),
    displayName: "Test User",
    streak: 7,
    totalXp: 1250,
    level: 3,
    lastActiveDate: Date(),
    isAdmin: false
  )
}
```

## Info.plist Configuration

Add to your Info.plist for OAuth callbacks:

```xml
<key>CFBundleURLTypes</key>
<array>
  <dict>
    <key>CFBundleURLSchemes</key>
    <array>
      <string>rizq</string>
    </array>
    <key>CFBundleURLName</key>
    <string>com.rizq.oauth</string>
  </dict>
</array>
```

## Checklist

When implementing authentication:

- [ ] ASWebAuthenticationSession configured correctly
- [ ] Keychain stores tokens securely (AfterFirstUnlockThisDeviceOnly)
- [ ] Sign in with Apple properly handles name/email
- [ ] Session restoration on app launch
- [ ] Token refresh before expiration
- [ ] Sign out clears all stored data
- [ ] Error handling for all OAuth scenarios
- [ ] URL scheme registered in Info.plist
- [ ] Loading states during auth operations
- [ ] Profile fetched after successful auth
