---
name: auth-patterns-ios
description: "Firebase Auth (recommended), OAuth with ASWebAuthenticationSession, Keychain storage, and session management"
---

# Authentication Patterns for iOS

This skill provides patterns for implementing authentication in the RIZQ iOS app. **Firebase Auth is the recommended approach.**

---

## Firebase Auth (Recommended)

### Architecture Overview

```
┌─────────────────────────────────────────────────────────────┐
│                      SwiftUI Views                          │
│              (AuthView, ProfileView)                        │
└─────────────────────────┬───────────────────────────────────┘
                          │
┌─────────────────────────▼───────────────────────────────────┐
│                   TCA Auth Feature                          │
│            (AuthFeature with AuthClient dependency)         │
└─────────────────────────┬───────────────────────────────────┘
                          │
┌─────────────────────────▼───────────────────────────────────┐
│              FirebaseAuthService                            │
│  (AuthServiceProtocol implementation)                       │
└─────────────────────────┬───────────────────────────────────┘
                          │
         ┌────────────────┼────────────────┐
         ▼                ▼                ▼
┌─────────────┐   ┌─────────────┐   ┌─────────────┐
│ Firebase    │   │ GoogleSignIn│   │ ASAuth      │
│ Auth        │   │ SDK         │   │ Controller  │
└─────────────┘   └─────────────┘   └─────────────┘
                          │
                 ┌────────▼────────┐
                 │ Keychain        │
                 │ Storage         │
                 └─────────────────┘
```

### FirebaseAuthService Pattern

```swift
public actor FirebaseAuthService: AuthServiceProtocol {
  private let keychain: KeychainService

  public init() {
    self.keychain = KeychainService.shared
  }

  // Email Authentication
  public func signInWithEmail(email: String, password: String) async throws -> AuthResponse {
    let result = try await Auth.auth().signIn(withEmail: email, password: password)
    let authResponse = try await mapFirebaseUserToAuthResponse(result.user)
    try saveAuthState(authResponse)
    return authResponse
  }

  // Google Sign-In
  @MainActor
  private func signInWithGoogle(presentingWindow: ASPresentationAnchor?) async throws -> AuthResponse {
    guard let clientID = FirebaseApp.app()?.options.clientID else {
      throw RIZQAuthError.oauthFailed("Firebase client ID not configured")
    }

    let config = GIDConfiguration(clientID: clientID)
    GIDSignIn.sharedInstance.configuration = config

    guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
          let rootViewController = windowScene.windows.first?.rootViewController else {
      throw RIZQAuthError.oauthFailed("No root view controller available")
    }

    let result = try await GIDSignIn.sharedInstance.signIn(withPresenting: rootViewController)

    guard let idToken = result.user.idToken?.tokenString else {
      throw RIZQAuthError.oauthFailed("No ID token received from Google")
    }

    let credential = GoogleAuthProvider.credential(
      withIDToken: idToken,
      accessToken: result.user.accessToken.tokenString
    )

    let authResult = try await Auth.auth().signIn(with: credential)
    return try await mapFirebaseUserToAuthResponse(authResult.user)
  }

  // Apple Sign-In (with nonce)
  @MainActor
  private func signInWithApple(presentingWindow: ASPresentationAnchor?) async throws -> AuthResponse {
    let nonce = randomNonceString()
    let hashedNonce = sha256(nonce)

    let appleIDProvider = ASAuthorizationAppleIDProvider()
    let request = appleIDProvider.createRequest()
    request.requestedScopes = [.fullName, .email]
    request.nonce = hashedNonce

    let credential = try await performAppleSignIn(request: request)

    guard let appleIDToken = credential.identityToken,
          let idTokenString = String(data: appleIDToken, encoding: .utf8) else {
      throw RIZQAuthError.oauthFailed("Unable to get Apple ID token")
    }

    let firebaseCredential = OAuthProvider.appleCredential(
      withIDToken: idTokenString,
      rawNonce: nonce,
      fullName: credential.fullName
    )

    let authResult = try await Auth.auth().signIn(with: firebaseCredential)
    return try await mapFirebaseUserToAuthResponse(authResult.user)
  }

  // Session Management
  public func getSession() async throws -> AuthSession? {
    guard let user = Auth.auth().currentUser else { return nil }
    let token = try await user.getIDToken()
    return AuthSession(
      id: UUID().uuidString,
      userId: user.uid,
      token: token,
      expiresAt: Date().addingTimeInterval(3600)
    )
  }

  public func refreshSession() async throws -> AuthSession {
    guard let user = Auth.auth().currentUser else {
      throw RIZQAuthError.sessionExpired
    }
    let token = try await user.getIDToken(forcingRefresh: true)
    return AuthSession(
      id: UUID().uuidString,
      userId: user.uid,
      token: token,
      expiresAt: Date().addingTimeInterval(3600)
    )
  }
}
```

### Nonce Generation for Apple Sign-In

```swift
private func randomNonceString(length: Int = 32) -> String {
  precondition(length > 0)
  var randomBytes = [UInt8](repeating: 0, count: length)
  let errorCode = SecRandomCopyBytes(kSecRandomDefault, randomBytes.count, &randomBytes)
  if errorCode != errSecSuccess {
    fatalError("Unable to generate nonce")
  }
  let charset: [Character] = Array("0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._")
  return String(randomBytes.map { byte in charset[Int(byte) % charset.count] })
}

private func sha256(_ input: String) -> String {
  let inputData = Data(input.utf8)
  var hash = [UInt8](repeating: 0, count: Int(CC_SHA256_DIGEST_LENGTH))
  inputData.withUnsafeBytes {
    _ = CC_SHA256($0.baseAddress, CC_LONG(inputData.count), &hash)
  }
  return hash.map { String(format: "%02x", $0) }.joined()
}
```

### Firebase Error Mapping

```swift
private func mapFirebaseError(_ error: NSError) -> RIZQAuthError {
  guard let errorCode = AuthErrorCode(rawValue: error.code) else {
    return .unknown(error.localizedDescription)
  }
  switch errorCode {
  case .wrongPassword, .invalidCredential:
    return .invalidCredentials
  case .emailAlreadyInUse:
    return .emailAlreadyExists
  case .userNotFound:
    return .userNotFound
  case .userTokenExpired, .invalidUserToken:
    return .sessionExpired
  case .networkError:
    return .networkError(error.localizedDescription)
  default:
    return .unknown(error.localizedDescription)
  }
}
```

---

## Legacy: Better Auth / Neon Auth

The patterns below are for the legacy Better Auth + Neon Auth integration using ASWebAuthenticationSession.

### Architecture Overview

```
┌─────────────────────────────────────────────────────────────┐
│                      SwiftUI Views                          │
│              (SignInView, ProfileView)                      │
└─────────────────────────┬───────────────────────────────────┘
                          │
┌─────────────────────────▼───────────────────────────────────┐
│                   TCA Auth Feature                          │
│            (AuthReducer, AuthState, AuthAction)             │
└─────────────────────────┬───────────────────────────────────┘
                          │
┌─────────────────────────▼───────────────────────────────────┐
│                   Auth Client                               │
│  (Protocol for OAuth flow, token management, session)       │
└─────────────────────────┬───────────────────────────────────┘
                          │
           ┌──────────────┼──────────────┐
           ▼              ▼              ▼
┌─────────────────┐ ┌──────────┐ ┌─────────────────┐
│ ASWebAuth       │ │ Keychain │ │ Better Auth API │
│ Session         │ │ Storage  │ │ (Neon Auth)     │
└─────────────────┘ └──────────┘ └─────────────────┘
```

---

## Better Auth / Neon Auth Integration

### Auth Configuration

```swift
// MARK: - Auth Configuration
struct AuthConfiguration: Sendable {
  let authURL: URL
  let callbackScheme: String
  let clientId: String

  static let production = AuthConfiguration(
    authURL: URL(string: "https://your-project.neon.tech/auth")!,
    callbackScheme: "rizq",
    clientId: "your-client-id"
  )

  static let development = AuthConfiguration(
    authURL: URL(string: "http://localhost:3000/auth")!,
    callbackScheme: "rizq-dev",
    clientId: "dev-client-id"
  )

  // OAuth endpoints
  var googleAuthURL: URL {
    authURL.appendingPathComponent("sign-in/social")
  }

  var githubAuthURL: URL {
    authURL.appendingPathComponent("sign-in/social")
  }

  var sessionURL: URL {
    authURL.appendingPathComponent("get-session")
  }

  var signOutURL: URL {
    authURL.appendingPathComponent("sign-out")
  }
}
```

### Auth Provider Enum

```swift
// MARK: - OAuth Providers
enum AuthProvider: String, CaseIterable, Sendable {
  case google
  case github
  case apple

  var displayName: String {
    switch self {
    case .google: return "Google"
    case .github: return "GitHub"
    case .apple: return "Apple"
    }
  }

  var iconName: String {
    switch self {
    case .google: return "g.circle.fill"
    case .github: return "chevron.left.forwardslash.chevron.right"
    case .apple: return "apple.logo"
    }
  }

  var backgroundColor: Color {
    switch self {
    case .google: return .white
    case .github: return .black
    case .apple: return .black
    }
  }

  var foregroundColor: Color {
    switch self {
    case .google: return .black
    case .github: return .white
    case .apple: return .white
    }
  }
}
```

---

## ASWebAuthenticationSession

### OAuth Flow Implementation

```swift
import AuthenticationServices

// MARK: - Web Auth Manager
@MainActor
final class WebAuthManager: NSObject {
  private var session: ASWebAuthenticationSession?
  private var presentationAnchor: ASPresentationAnchor?

  func authenticate(
    provider: AuthProvider,
    config: AuthConfiguration
  ) async throws -> AuthTokens {
    // Build OAuth URL
    let authURL = buildAuthURL(provider: provider, config: config)

    return try await withCheckedThrowingContinuation { continuation in
      session = ASWebAuthenticationSession(
        url: authURL,
        callbackURLScheme: config.callbackScheme
      ) { callbackURL, error in
        if let error = error {
          if (error as NSError).code == ASWebAuthenticationSessionError.canceledLogin.rawValue {
            continuation.resume(throwing: AuthError.userCancelled)
          } else {
            continuation.resume(throwing: AuthError.webAuthFailed(error.localizedDescription))
          }
          return
        }

        guard let callbackURL = callbackURL else {
          continuation.resume(throwing: AuthError.noCallbackURL)
          return
        }

        do {
          let tokens = try self.parseCallback(callbackURL)
          continuation.resume(returning: tokens)
        } catch {
          continuation.resume(throwing: error)
        }
      }

      session?.presentationContextProvider = self
      session?.prefersEphemeralWebBrowserSession = false // Keep session for "remember me"

      guard session?.start() == true else {
        continuation.resume(throwing: AuthError.sessionStartFailed)
        return
      }
    }
  }

  private func buildAuthURL(provider: AuthProvider, config: AuthConfiguration) -> URL {
    var components = URLComponents(url: config.googleAuthURL, resolvingAgainstBaseURL: true)!

    components.queryItems = [
      URLQueryItem(name: "provider", value: provider.rawValue),
      URLQueryItem(name: "callbackURL", value: "\(config.callbackScheme)://auth/callback"),
    ]

    return components.url!
  }

  private func parseCallback(_ url: URL) throws -> AuthTokens {
    guard let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
          let queryItems = components.queryItems else {
      throw AuthError.invalidCallback
    }

    // Check for error
    if let error = queryItems.first(where: { $0.name == "error" })?.value {
      throw AuthError.providerError(error)
    }

    // Extract tokens
    guard let accessToken = queryItems.first(where: { $0.name == "access_token" })?.value else {
      throw AuthError.missingToken
    }

    let refreshToken = queryItems.first(where: { $0.name == "refresh_token" })?.value
    let expiresIn = queryItems.first(where: { $0.name == "expires_in" })?.value
      .flatMap { Int($0) } ?? 3600

    return AuthTokens(
      accessToken: accessToken,
      refreshToken: refreshToken,
      expiresAt: Date().addingTimeInterval(TimeInterval(expiresIn))
    )
  }

  func setPresentationAnchor(_ anchor: ASPresentationAnchor) {
    self.presentationAnchor = anchor
  }
}

// MARK: - Presentation Context Provider
extension WebAuthManager: ASWebAuthenticationPresentationContextProviding {
  func presentationAnchor(for session: ASWebAuthenticationSession) -> ASPresentationAnchor {
    presentationAnchor ?? ASPresentationAnchor()
  }
}
```

### SwiftUI Integration

```swift
// MARK: - Web Auth View Modifier
struct WebAuthAnchorModifier: ViewModifier {
  @State private var anchor: ASPresentationAnchor?
  let manager: WebAuthManager

  func body(content: Content) -> some View {
    content
      .background(
        WebAuthAnchorView { anchor in
          self.anchor = anchor
          manager.setPresentationAnchor(anchor)
        }
      )
  }
}

struct WebAuthAnchorView: UIViewRepresentable {
  let onAnchor: (ASPresentationAnchor) -> Void

  func makeUIView(context: Context) -> UIView {
    let view = UIView()
    DispatchQueue.main.async {
      if let window = view.window {
        onAnchor(window)
      }
    }
    return view
  }

  func updateUIView(_ uiView: UIView, context: Context) {
    if let window = uiView.window {
      onAnchor(window)
    }
  }
}

extension View {
  func webAuthAnchor(_ manager: WebAuthManager) -> some View {
    modifier(WebAuthAnchorModifier(manager: manager))
  }
}
```

---

## Sign in with Apple

### Apple Sign In Implementation

```swift
import AuthenticationServices

// MARK: - Apple Sign In Manager
@MainActor
final class AppleSignInManager: NSObject {
  private var continuation: CheckedContinuation<AppleCredential, Error>?

  func signIn() async throws -> AppleCredential {
    try await withCheckedThrowingContinuation { continuation in
      self.continuation = continuation

      let request = ASAuthorizationAppleIDProvider().createRequest()
      request.requestedScopes = [.fullName, .email]

      let controller = ASAuthorizationController(authorizationRequests: [request])
      controller.delegate = self
      controller.presentationContextProvider = self
      controller.performRequests()
    }
  }
}

// MARK: - ASAuthorizationControllerDelegate
extension AppleSignInManager: ASAuthorizationControllerDelegate {
  func authorizationController(
    controller: ASAuthorizationController,
    didCompleteWithAuthorization authorization: ASAuthorization
  ) {
    guard let credential = authorization.credential as? ASAuthorizationAppleIDCredential else {
      continuation?.resume(throwing: AuthError.invalidCredential)
      return
    }

    let appleCredential = AppleCredential(
      userIdentifier: credential.user,
      email: credential.email,
      fullName: credential.fullName,
      identityToken: credential.identityToken,
      authorizationCode: credential.authorizationCode
    )

    continuation?.resume(returning: appleCredential)
  }

  func authorizationController(
    controller: ASAuthorizationController,
    didCompleteWithError error: Error
  ) {
    if (error as NSError).code == ASAuthorizationError.canceled.rawValue {
      continuation?.resume(throwing: AuthError.userCancelled)
    } else {
      continuation?.resume(throwing: AuthError.appleFailed(error.localizedDescription))
    }
  }
}

// MARK: - ASAuthorizationControllerPresentationContextProviding
extension AppleSignInManager: ASAuthorizationControllerPresentationContextProviding {
  func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
    ASPresentationAnchor()
  }
}

// MARK: - Apple Credential
struct AppleCredential: Sendable {
  let userIdentifier: String
  let email: String?
  let fullName: PersonNameComponents?
  let identityToken: Data?
  let authorizationCode: Data?

  var identityTokenString: String? {
    identityToken.flatMap { String(data: $0, encoding: .utf8) }
  }

  var authorizationCodeString: String? {
    authorizationCode.flatMap { String(data: $0, encoding: .utf8) }
  }
}
```

### Sign in with Apple SwiftUI Button

```swift
// MARK: - Apple Sign In Button
struct AppleSignInButton: View {
  let onSignIn: () -> Void

  var body: some View {
    SignInWithAppleButton(.signIn) { request in
      request.requestedScopes = [.fullName, .email]
    } onCompletion: { result in
      switch result {
      case .success:
        onSignIn()
      case .failure(let error):
        print("Apple Sign In failed: \(error)")
      }
    }
    .signInWithAppleButtonStyle(.black)
    .frame(height: 50)
    .cornerRadius(12)
  }
}
```

---

## Keychain Storage

### Keychain Wrapper

```swift
import Security

// MARK: - Keychain Manager
actor KeychainManager {
  static let shared = KeychainManager()

  private let service = "com.rizq.app"

  private init() {}

  // MARK: - Save

  func save(_ data: Data, for key: KeychainKey) throws {
    // Delete existing item first
    try? delete(key)

    let query: [String: Any] = [
      kSecClass as String: kSecClassGenericPassword,
      kSecAttrService as String: service,
      kSecAttrAccount as String: key.rawValue,
      kSecValueData as String: data,
      kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly
    ]

    let status = SecItemAdd(query as CFDictionary, nil)

    guard status == errSecSuccess else {
      throw KeychainError.saveFailed(status)
    }
  }

  func save(_ string: String, for key: KeychainKey) throws {
    guard let data = string.data(using: .utf8) else {
      throw KeychainError.encodingFailed
    }
    try save(data, for: key)
  }

  func save<T: Encodable>(_ value: T, for key: KeychainKey) throws {
    let data = try JSONEncoder().encode(value)
    try save(data, for: key)
  }

  // MARK: - Read

  func read(_ key: KeychainKey) throws -> Data {
    let query: [String: Any] = [
      kSecClass as String: kSecClassGenericPassword,
      kSecAttrService as String: service,
      kSecAttrAccount as String: key.rawValue,
      kSecReturnData as String: true,
      kSecMatchLimit as String: kSecMatchLimitOne
    ]

    var result: AnyObject?
    let status = SecItemCopyMatching(query as CFDictionary, &result)

    guard status == errSecSuccess, let data = result as? Data else {
      throw KeychainError.itemNotFound
    }

    return data
  }

  func readString(_ key: KeychainKey) throws -> String {
    let data = try read(key)
    guard let string = String(data: data, encoding: .utf8) else {
      throw KeychainError.decodingFailed
    }
    return string
  }

  func read<T: Decodable>(_ key: KeychainKey, as type: T.Type) throws -> T {
    let data = try read(key)
    return try JSONDecoder().decode(type, from: data)
  }

  // MARK: - Delete

  func delete(_ key: KeychainKey) throws {
    let query: [String: Any] = [
      kSecClass as String: kSecClassGenericPassword,
      kSecAttrService as String: service,
      kSecAttrAccount as String: key.rawValue
    ]

    let status = SecItemDelete(query as CFDictionary)

    guard status == errSecSuccess || status == errSecItemNotFound else {
      throw KeychainError.deleteFailed(status)
    }
  }

  // MARK: - Clear All

  func clearAll() throws {
    for key in KeychainKey.allCases {
      try? delete(key)
    }
  }
}

// MARK: - Keychain Keys
enum KeychainKey: String, CaseIterable {
  case accessToken = "access_token"
  case refreshToken = "refresh_token"
  case tokenExpiry = "token_expiry"
  case userId = "user_id"
  case userEmail = "user_email"
  case appleUserIdentifier = "apple_user_id"
}

// MARK: - Keychain Errors
enum KeychainError: Error, LocalizedError {
  case saveFailed(OSStatus)
  case itemNotFound
  case deleteFailed(OSStatus)
  case encodingFailed
  case decodingFailed

  var errorDescription: String? {
    switch self {
    case .saveFailed(let status):
      return "Failed to save to keychain (status: \(status))"
    case .itemNotFound:
      return "Item not found in keychain"
    case .deleteFailed(let status):
      return "Failed to delete from keychain (status: \(status))"
    case .encodingFailed:
      return "Failed to encode data"
    case .decodingFailed:
      return "Failed to decode data"
    }
  }
}
```

---

## Token Management

### Auth Tokens Model

```swift
// MARK: - Auth Tokens
struct AuthTokens: Codable, Equatable, Sendable {
  let accessToken: String
  let refreshToken: String?
  let expiresAt: Date

  var isExpired: Bool {
    Date() >= expiresAt
  }

  var isExpiringSoon: Bool {
    Date().addingTimeInterval(300) >= expiresAt // 5 minutes buffer
  }
}
```

### Token Storage

```swift
// MARK: - Token Storage
actor TokenStorage {
  static let shared = TokenStorage()

  private let keychain = KeychainManager.shared

  private init() {}

  func saveTokens(_ tokens: AuthTokens) async throws {
    try await keychain.save(tokens.accessToken, for: .accessToken)
    if let refreshToken = tokens.refreshToken {
      try await keychain.save(refreshToken, for: .refreshToken)
    }
    try await keychain.save(tokens, for: .tokenExpiry)
  }

  func getTokens() async throws -> AuthTokens {
    try await keychain.read(.tokenExpiry, as: AuthTokens.self)
  }

  func getAccessToken() async throws -> String {
    try await keychain.readString(.accessToken)
  }

  func getRefreshToken() async throws -> String {
    try await keychain.readString(.refreshToken)
  }

  func clearTokens() async throws {
    try await keychain.delete(.accessToken)
    try await keychain.delete(.refreshToken)
    try await keychain.delete(.tokenExpiry)
  }
}
```

### Token Refresh

```swift
// MARK: - Token Refresh Manager
actor TokenRefreshManager {
  static let shared = TokenRefreshManager()

  private var refreshTask: Task<AuthTokens, Error>?
  private let config: AuthConfiguration

  private init(config: AuthConfiguration = .production) {
    self.config = config
  }

  func refreshTokenIfNeeded() async throws -> AuthTokens {
    let tokens = try await TokenStorage.shared.getTokens()

    // If token is not expiring soon, return current tokens
    if !tokens.isExpiringSoon {
      return tokens
    }

    // If refresh is already in progress, wait for it
    if let existingTask = refreshTask {
      return try await existingTask.value
    }

    // Start new refresh task
    let task = Task<AuthTokens, Error> {
      defer { refreshTask = nil }

      guard let refreshToken = tokens.refreshToken else {
        throw AuthError.noRefreshToken
      }

      return try await performRefresh(refreshToken: refreshToken)
    }

    refreshTask = task
    return try await task.value
  }

  private func performRefresh(refreshToken: String) async throws -> AuthTokens {
    var request = URLRequest(url: config.authURL.appendingPathComponent("refresh"))
    request.httpMethod = "POST"
    request.setValue("application/json", forHTTPHeaderField: "Content-Type")

    let body = ["refreshToken": refreshToken]
    request.httpBody = try JSONEncoder().encode(body)

    let (data, response) = try await URLSession.shared.data(for: request)

    guard let httpResponse = response as? HTTPURLResponse,
          (200...299).contains(httpResponse.statusCode) else {
      throw AuthError.refreshFailed
    }

    let newTokens = try JSONDecoder().decode(AuthTokens.self, from: data)
    try await TokenStorage.shared.saveTokens(newTokens)

    return newTokens
  }
}
```

---

## Auth Client (TCA Dependency)

### Auth Client Protocol

```swift
import ComposableArchitecture

// MARK: - Auth Client Protocol
protocol AuthClientProtocol: Sendable {
  func signIn(provider: AuthProvider) async throws -> User
  func signInWithApple() async throws -> User
  func signOut() async throws
  func getCurrentUser() async throws -> User?
  func refreshSession() async throws -> User
}

// MARK: - User Model
struct User: Codable, Equatable, Identifiable, Sendable {
  let id: String
  let email: String?
  let name: String?
  let image: String?
  let provider: String?
  let createdAt: Date?

  var displayName: String {
    name ?? email ?? "User"
  }

  var initials: String {
    let components = (name ?? "U").split(separator: " ")
    if components.count >= 2 {
      return String(components[0].prefix(1) + components[1].prefix(1)).uppercased()
    }
    return String(components.first?.prefix(2) ?? "U").uppercased()
  }
}
```

### Live Auth Client

```swift
// MARK: - Live Auth Client
final class AuthClient: AuthClientProtocol {
  private let config: AuthConfiguration
  private let webAuthManager: WebAuthManager
  private let appleSignInManager: AppleSignInManager
  private let tokenStorage: TokenStorage
  private let apiClient: APIClientProtocol

  init(
    config: AuthConfiguration = .production,
    webAuthManager: WebAuthManager = WebAuthManager(),
    appleSignInManager: AppleSignInManager = AppleSignInManager(),
    tokenStorage: TokenStorage = .shared,
    apiClient: APIClientProtocol
  ) {
    self.config = config
    self.webAuthManager = webAuthManager
    self.appleSignInManager = appleSignInManager
    self.tokenStorage = tokenStorage
    self.apiClient = apiClient
  }

  @MainActor
  func signIn(provider: AuthProvider) async throws -> User {
    // Perform OAuth flow
    let tokens = try await webAuthManager.authenticate(provider: provider, config: config)

    // Save tokens
    try await tokenStorage.saveTokens(tokens)

    // Fetch user profile
    return try await fetchCurrentUser(accessToken: tokens.accessToken)
  }

  @MainActor
  func signInWithApple() async throws -> User {
    // Get Apple credential
    let credential = try await appleSignInManager.signIn()

    // Exchange with backend
    let tokens = try await exchangeAppleToken(credential)

    // Save tokens
    try await tokenStorage.saveTokens(tokens)

    // Save Apple user identifier for future sign-ins
    if let data = credential.userIdentifier.data(using: .utf8) {
      try await KeychainManager.shared.save(data, for: .appleUserIdentifier)
    }

    // Fetch user profile
    return try await fetchCurrentUser(accessToken: tokens.accessToken)
  }

  func signOut() async throws {
    // Call sign out endpoint
    do {
      let tokens = try await tokenStorage.getTokens()
      var request = URLRequest(url: config.signOutURL)
      request.httpMethod = "POST"
      request.setValue("Bearer \(tokens.accessToken)", forHTTPHeaderField: "Authorization")
      _ = try await URLSession.shared.data(for: request)
    } catch {
      // Continue with local sign out even if server call fails
    }

    // Clear local tokens
    try await tokenStorage.clearTokens()
    try await KeychainManager.shared.delete(.userId)
    try await KeychainManager.shared.delete(.userEmail)
  }

  func getCurrentUser() async throws -> User? {
    do {
      let tokens = try await tokenStorage.getTokens()

      // Check if expired
      if tokens.isExpired {
        return nil
      }

      return try await fetchCurrentUser(accessToken: tokens.accessToken)
    } catch KeychainError.itemNotFound {
      return nil
    }
  }

  func refreshSession() async throws -> User {
    let tokens = try await TokenRefreshManager.shared.refreshTokenIfNeeded()
    return try await fetchCurrentUser(accessToken: tokens.accessToken)
  }

  // MARK: - Private Helpers

  private func fetchCurrentUser(accessToken: String) async throws -> User {
    var request = URLRequest(url: config.sessionURL)
    request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")

    let (data, response) = try await URLSession.shared.data(for: request)

    guard let httpResponse = response as? HTTPURLResponse,
          (200...299).contains(httpResponse.statusCode) else {
      throw AuthError.sessionFetchFailed
    }

    let sessionResponse = try JSONDecoder.rizqDecoder.decode(SessionResponse.self, from: data)
    return sessionResponse.user
  }

  private func exchangeAppleToken(_ credential: AppleCredential) async throws -> AuthTokens {
    var request = URLRequest(url: config.authURL.appendingPathComponent("sign-in/apple"))
    request.httpMethod = "POST"
    request.setValue("application/json", forHTTPHeaderField: "Content-Type")

    let body: [String: Any?] = [
      "idToken": credential.identityTokenString,
      "authorizationCode": credential.authorizationCodeString,
      "user": [
        "email": credential.email,
        "name": credential.fullName.map { "\($0.givenName ?? "") \($0.familyName ?? "")" }
      ]
    ]

    request.httpBody = try JSONSerialization.data(withJSONObject: body.compactMapValues { $0 })

    let (data, response) = try await URLSession.shared.data(for: request)

    guard let httpResponse = response as? HTTPURLResponse,
          (200...299).contains(httpResponse.statusCode) else {
      throw AuthError.appleExchangeFailed
    }

    return try JSONDecoder().decode(AuthTokens.self, from: data)
  }
}

// MARK: - Session Response
struct SessionResponse: Decodable {
  let user: User
  let session: Session?

  struct Session: Decodable {
    let expiresAt: Date?
  }
}
```

---

## TCA Auth Feature

### Auth Reducer

```swift
import ComposableArchitecture

// MARK: - Auth Feature
@Reducer
struct AuthFeature {
  @ObservableState
  struct State: Equatable {
    var user: User?
    var isLoading = false
    var isSigningIn = false
    var error: String?
    var selectedProvider: AuthProvider?

    var isAuthenticated: Bool { user != nil }
  }

  enum Action {
    // Lifecycle
    case onAppear
    case checkSession

    // Sign In
    case signInTapped(AuthProvider)
    case signInWithAppleTapped
    case signInCompleted(Result<User, Error>)

    // Sign Out
    case signOutTapped
    case signOutCompleted(Result<Void, Error>)

    // Session
    case sessionChecked(Result<User?, Error>)
    case refreshSession

    // UI
    case dismissError
  }

  @Dependency(\.authClient) var authClient
  @Dependency(\.mainQueue) var mainQueue

  var body: some ReducerOf<Self> {
    Reduce { state, action in
      switch action {
      case .onAppear:
        return .send(.checkSession)

      case .checkSession:
        state.isLoading = true
        return .run { send in
          let result = await Result { try await authClient.getCurrentUser() }
          await send(.sessionChecked(result))
        }

      case .signInTapped(let provider):
        state.isSigningIn = true
        state.selectedProvider = provider
        state.error = nil
        return .run { send in
          let result = await Result { try await authClient.signIn(provider: provider) }
          await send(.signInCompleted(result))
        }

      case .signInWithAppleTapped:
        state.isSigningIn = true
        state.selectedProvider = .apple
        state.error = nil
        return .run { send in
          let result = await Result { try await authClient.signInWithApple() }
          await send(.signInCompleted(result))
        }

      case .signInCompleted(.success(let user)):
        state.user = user
        state.isSigningIn = false
        state.selectedProvider = nil
        return .none

      case .signInCompleted(.failure(let error)):
        state.isSigningIn = false
        state.selectedProvider = nil
        if let authError = error as? AuthError, authError != .userCancelled {
          state.error = authError.errorDescription
        }
        return .none

      case .signOutTapped:
        state.isLoading = true
        return .run { send in
          let result = await Result { try await authClient.signOut() }
          await send(.signOutCompleted(result))
        }

      case .signOutCompleted(.success):
        state.user = nil
        state.isLoading = false
        return .none

      case .signOutCompleted(.failure(let error)):
        state.isLoading = false
        state.error = error.localizedDescription
        return .none

      case .sessionChecked(.success(let user)):
        state.user = user
        state.isLoading = false
        return .none

      case .sessionChecked(.failure):
        state.isLoading = false
        return .none

      case .refreshSession:
        return .run { send in
          let result = await Result { try await authClient.refreshSession() }
          await send(.signInCompleted(result))
        }

      case .dismissError:
        state.error = nil
        return .none
      }
    }
  }
}
```

### Auth Client Dependency

```swift
// MARK: - Auth Client Dependency Key
struct AuthClientKey: DependencyKey {
  static let liveValue: AuthClientProtocol = AuthClient(
    apiClient: APIClient(baseURL: AuthConfiguration.production.authURL)
  )

  static let testValue: AuthClientProtocol = MockAuthClient()
  static let previewValue: AuthClientProtocol = MockAuthClient()
}

extension DependencyValues {
  var authClient: AuthClientProtocol {
    get { self[AuthClientKey.self] }
    set { self[AuthClientKey.self] = newValue }
  }
}
```

---

## Auth Errors

```swift
// MARK: - Auth Errors
enum AuthError: Error, Equatable, LocalizedError {
  case userCancelled
  case webAuthFailed(String)
  case noCallbackURL
  case sessionStartFailed
  case invalidCallback
  case providerError(String)
  case missingToken
  case noRefreshToken
  case refreshFailed
  case sessionFetchFailed
  case invalidCredential
  case appleFailed(String)
  case appleExchangeFailed
  case unauthorized

  var errorDescription: String? {
    switch self {
    case .userCancelled:
      return "Sign in was cancelled"
    case .webAuthFailed(let message):
      return "Authentication failed: \(message)"
    case .noCallbackURL:
      return "No callback URL received"
    case .sessionStartFailed:
      return "Could not start authentication session"
    case .invalidCallback:
      return "Invalid callback received"
    case .providerError(let message):
      return "Provider error: \(message)"
    case .missingToken:
      return "No access token received"
    case .noRefreshToken:
      return "No refresh token available"
    case .refreshFailed:
      return "Session refresh failed"
    case .sessionFetchFailed:
      return "Could not fetch session"
    case .invalidCredential:
      return "Invalid credential received"
    case .appleFailed(let message):
      return "Apple Sign In failed: \(message)"
    case .appleExchangeFailed:
      return "Could not complete Apple Sign In"
    case .unauthorized:
      return "Please sign in to continue"
    }
  }

  static func == (lhs: AuthError, rhs: AuthError) -> Bool {
    lhs.errorDescription == rhs.errorDescription
  }
}
```

---

## SwiftUI Sign In View

```swift
// MARK: - Sign In View
struct SignInView: View {
  @Bindable var store: StoreOf<AuthFeature>
  @Environment(\.webAuthManager) var webAuthManager

  var body: some View {
    VStack(spacing: 24) {
      // Logo & Welcome
      VStack(spacing: 12) {
        Image("AppLogo")
          .resizable()
          .frame(width: 80, height: 80)

        Text("Welcome to RIZQ")
          .font(.rizqDisplay(.title))

        Text("Sign in to sync your progress")
          .font(.rizqSans(.body))
          .foregroundStyle(.secondary)
      }
      .padding(.vertical, 40)

      // OAuth Buttons
      VStack(spacing: 12) {
        // Sign in with Apple
        AppleSignInButton {
          store.send(.signInWithAppleTapped)
        }
        .disabled(store.isSigningIn)

        // Google
        OAuthButton(
          provider: .google,
          isLoading: store.isSigningIn && store.selectedProvider == .google
        ) {
          store.send(.signInTapped(.google))
        }
        .disabled(store.isSigningIn)

        // GitHub
        OAuthButton(
          provider: .github,
          isLoading: store.isSigningIn && store.selectedProvider == .github
        ) {
          store.send(.signInTapped(.github))
        }
        .disabled(store.isSigningIn)
      }

      // Error
      if let error = store.error {
        Text(error)
          .font(.rizqSans(.caption))
          .foregroundStyle(.red)
          .multilineTextAlignment(.center)
      }

      Spacer()

      // Terms
      Text("By signing in, you agree to our Terms of Service and Privacy Policy")
        .font(.rizqSans(.caption2))
        .foregroundStyle(.tertiary)
        .multilineTextAlignment(.center)
    }
    .padding()
    .webAuthAnchor(webAuthManager)
  }
}

// MARK: - OAuth Button
struct OAuthButton: View {
  let provider: AuthProvider
  let isLoading: Bool
  let action: () -> Void

  var body: some View {
    Button(action: action) {
      HStack(spacing: 12) {
        if isLoading {
          ProgressView()
            .tint(provider.foregroundColor)
        } else {
          Image(systemName: provider.iconName)
        }

        Text("Continue with \(provider.displayName)")
          .fontWeight(.medium)
      }
      .frame(maxWidth: .infinity)
      .frame(height: 50)
      .background(provider.backgroundColor)
      .foregroundStyle(provider.foregroundColor)
      .clipShape(RoundedRectangle(cornerRadius: 12))
      .overlay(
        RoundedRectangle(cornerRadius: 12)
          .stroke(Color.gray.opacity(0.3), lineWidth: provider == .google ? 1 : 0)
      )
    }
    .buttonStyle(.plain)
  }
}
```

---

## Mock Auth Client (Testing)

```swift
// MARK: - Mock Auth Client
final class MockAuthClient: AuthClientProtocol {
  var mockUser: User?
  var shouldFail = false
  var failureError: AuthError = .unauthorized

  init(mockUser: User? = nil) {
    self.mockUser = mockUser ?? User(
      id: "mock-user-id",
      email: "test@example.com",
      name: "Test User",
      image: nil,
      provider: "google",
      createdAt: Date()
    )
  }

  func signIn(provider: AuthProvider) async throws -> User {
    if shouldFail { throw failureError }
    return mockUser!
  }

  func signInWithApple() async throws -> User {
    if shouldFail { throw failureError }
    return mockUser!
  }

  func signOut() async throws {
    if shouldFail { throw failureError }
    mockUser = nil
  }

  func getCurrentUser() async throws -> User? {
    if shouldFail { throw failureError }
    return mockUser
  }

  func refreshSession() async throws -> User {
    if shouldFail { throw failureError }
    return mockUser!
  }
}
```

---

## URL Scheme Configuration

### Info.plist

```xml
<key>CFBundleURLTypes</key>
<array>
  <dict>
    <key>CFBundleURLName</key>
    <string>com.rizq.app</string>
    <key>CFBundleURLSchemes</key>
    <array>
      <string>rizq</string>
    </array>
  </dict>
</array>
```

### Handle Callback in App

```swift
@main
struct RIZQApp: App {
  var body: some Scene {
    WindowGroup {
      ContentView()
        .onOpenURL { url in
          // Handle OAuth callback
          handleAuthCallback(url)
        }
    }
  }

  private func handleAuthCallback(_ url: URL) {
    // ASWebAuthenticationSession handles this automatically
    // This is for deep link callbacks if needed
    print("Received callback: \(url)")
  }
}
```
