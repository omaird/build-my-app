# Firebase Authentication Patterns for iOS

This skill provides code patterns and best practices for implementing Firebase Authentication in iOS apps using Swift.

## When to Use This Skill

Use this skill when:
- Implementing user authentication with Firebase
- Adding social login providers (Google, Apple)
- Managing user sessions and tokens
- Handling authentication state changes
- Implementing account linking

## Core Dependencies

```yaml
# In project.yml packages section
Firebase:
  url: https://github.com/firebase/firebase-ios-sdk
  from: "11.0.0"
GoogleSignIn:
  url: https://github.com/google/GoogleSignIn-iOS
  from: "8.0.0"

# In target dependencies
dependencies:
  - package: Firebase
    product: FirebaseAuth
  - package: GoogleSignIn
    product: GoogleSignIn
```

## Firebase Auth Service Pattern

### Protocol-Based Architecture

```swift
import FirebaseAuth
import AuthenticationServices

public protocol AuthServiceProtocol: Sendable {
  func signInWithEmail(email: String, password: String) async throws -> AuthResponse
  func signUpWithEmail(email: String, password: String, name: String?) async throws -> AuthResponse
  func signInWithOAuth(provider: AuthProvider, presentingWindow: ASPresentationAnchor?) async throws -> AuthResponse
  func signOut() async throws
  func getSession() async throws -> AuthSession?
  func refreshSession() async throws -> AuthSession
  func getCurrentUser() async throws -> AuthUser?
  func restoreSession() -> (user: AuthUser, session: AuthSession)?
  func clearStoredCredentials()
}
```

### Actor-Based Implementation

```swift
public actor FirebaseAuthService: AuthServiceProtocol {
  private let keychain: KeychainService

  public init() {
    self.keychain = KeychainService.shared
  }

  // MARK: - Email Authentication

  public func signInWithEmail(email: String, password: String) async throws -> AuthResponse {
    do {
      let result = try await Auth.auth().signIn(withEmail: email, password: password)
      return try await mapFirebaseUserToAuthResponse(result.user)
    } catch let error as NSError {
      throw mapFirebaseError(error)
    }
  }

  public func signUpWithEmail(email: String, password: String, name: String?) async throws -> AuthResponse {
    let result = try await Auth.auth().createUser(withEmail: email, password: password)

    if let name = name {
      let changeRequest = result.user.createProfileChangeRequest()
      changeRequest.displayName = name
      try await changeRequest.commitChanges()
    }

    return try await mapFirebaseUserToAuthResponse(result.user)
  }
}
```

## Google Sign-In Pattern

```swift
import GoogleSignIn

@MainActor
private func signInWithGoogle(presentingWindow: ASPresentationAnchor?) async throws -> AuthResponse {
  guard let clientID = FirebaseApp.app()?.options.clientID else {
    throw AuthError.oauthFailed("Firebase client ID not configured")
  }

  let config = GIDConfiguration(clientID: clientID)
  GIDSignIn.sharedInstance.configuration = config

  guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
        let rootViewController = windowScene.windows.first?.rootViewController else {
    throw AuthError.oauthFailed("No root view controller available")
  }

  let result = try await GIDSignIn.sharedInstance.signIn(withPresenting: rootViewController)

  guard let idToken = result.user.idToken?.tokenString else {
    throw AuthError.oauthFailed("No ID token received from Google")
  }

  let credential = GoogleAuthProvider.credential(
    withIDToken: idToken,
    accessToken: result.user.accessToken.tokenString
  )

  let authResult = try await Auth.auth().signIn(with: credential)
  return try await mapFirebaseUserToAuthResponse(authResult.user)
}
```

## Apple Sign-In Pattern

```swift
import AuthenticationServices
import CryptoKit

@MainActor
private func signInWithApple(presentingWindow: ASPresentationAnchor?) async throws -> AuthResponse {
  let nonce = randomNonceString()

  let appleIDProvider = ASAuthorizationAppleIDProvider()
  let request = appleIDProvider.createRequest()
  request.requestedScopes = [.fullName, .email]
  request.nonce = sha256(nonce)

  let authorizationController = ASAuthorizationController(authorizationRequests: [request])
  let delegate = AppleSignInDelegate()
  authorizationController.delegate = delegate

  if let anchor = presentingWindow {
    let contextProvider = ApplePresentationContextProvider(anchor: anchor)
    authorizationController.presentationContextProvider = contextProvider
  }

  authorizationController.performRequests()

  let credential = try await delegate.waitForCredential()

  guard let appleIDToken = credential.identityToken,
        let idTokenString = String(data: appleIDToken, encoding: .utf8) else {
    throw AuthError.oauthFailed("Unable to get Apple ID token")
  }

  let firebaseCredential = OAuthProvider.appleCredential(
    withIDToken: idTokenString,
    rawNonce: nonce,
    fullName: credential.fullName
  )

  let authResult = try await Auth.auth().signIn(with: firebaseCredential)
  return try await mapFirebaseUserToAuthResponse(authResult.user)
}

// MARK: - Nonce Helpers

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
  let hashedData = SHA256.hash(data: inputData)
  return hashedData.compactMap { String(format: "%02x", $0) }.joined()
}
```

## Apple Sign-In Delegate Pattern

```swift
@MainActor
private final class AppleSignInDelegate: NSObject, ASAuthorizationControllerDelegate {
  private var continuation: CheckedContinuation<ASAuthorizationAppleIDCredential, Error>?

  func waitForCredential() async throws -> ASAuthorizationAppleIDCredential {
    try await withCheckedThrowingContinuation { continuation in
      self.continuation = continuation
    }
  }

  func authorizationController(controller: ASAuthorizationController,
                               didCompleteWithAuthorization authorization: ASAuthorization) {
    guard let credential = authorization.credential as? ASAuthorizationAppleIDCredential else {
      continuation?.resume(throwing: AuthError.oauthFailed("Invalid Apple credential"))
      return
    }
    continuation?.resume(returning: credential)
  }

  func authorizationController(controller: ASAuthorizationController,
                               didCompleteWithError error: Error) {
    if let authError = error as? ASAuthorizationError, authError.code == .canceled {
      continuation?.resume(throwing: AuthError.oauthCancelled)
    } else {
      continuation?.resume(throwing: AuthError.oauthFailed(error.localizedDescription))
    }
  }
}
```

## Session Management

```swift
public func getSession() async throws -> AuthSession? {
  guard let user = Auth.auth().currentUser else {
    return nil
  }

  let token = try await user.getIDToken()
  return AuthSession(
    id: UUID().uuidString,
    userId: user.uid,
    token: token,
    expiresAt: Date().addingTimeInterval(3600) // Firebase tokens expire in 1 hour
  )
}

public func refreshSession() async throws -> AuthSession {
  guard let user = Auth.auth().currentUser else {
    throw AuthError.sessionExpired
  }

  let token = try await user.getIDToken(forcingRefresh: true)
  return AuthSession(
    id: UUID().uuidString,
    userId: user.uid,
    token: token,
    expiresAt: Date().addingTimeInterval(3600)
  )
}
```

## Error Mapping

```swift
private func mapFirebaseError(_ error: NSError) -> AuthError {
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

## TCA Integration Pattern

```swift
import ComposableArchitecture

struct AuthClient: Sendable {
  var signIn: @Sendable (String, String) async throws -> AuthResponse
  var signUp: @Sendable (String, String, String?) async throws -> AuthResponse
  var signInWithOAuth: @Sendable (AuthProvider) async throws -> AuthResponse
  var signOut: @Sendable () async throws -> Void
  var restoreSession: @Sendable () -> (AuthUser, AuthSession)?
}

extension AuthClient: DependencyKey {
  static let liveValue = AuthClient(
    signIn: { email, password in
      let service = ServiceContainer.shared.authService
      return try await service.signInWithEmail(email: email, password: password)
    },
    signUp: { email, password, name in
      let service = ServiceContainer.shared.authService
      return try await service.signUpWithEmail(email: email, password: password, name: name)
    },
    signInWithOAuth: { provider in
      let service = ServiceContainer.shared.authService
      let presentingWindow = await MainActor.run {
        UIApplication.shared.connectedScenes
          .compactMap { $0 as? UIWindowScene }
          .flatMap { $0.windows }
          .first { $0.isKeyWindow }
      }
      return try await service.signInWithOAuth(provider: provider, presentingWindow: presentingWindow)
    },
    signOut: {
      try await ServiceContainer.shared.authService.signOut()
    },
    restoreSession: {
      ServiceContainer.shared.authService.restoreSession()
    }
  )
}
```

## Common Issues and Solutions

### Issue: Google Sign-In not showing

**Cause**: Missing URL scheme configuration
**Solution**: Add URL scheme to Info.plist:
```xml
<key>CFBundleURLTypes</key>
<array>
  <dict>
    <key>CFBundleURLSchemes</key>
    <array>
      <string>com.googleusercontent.apps.YOUR_CLIENT_ID</string>
    </array>
  </dict>
</array>
```

### Issue: Apple Sign-In fails silently

**Cause**: Missing Sign in with Apple capability
**Solution**:
1. Add capability in Xcode
2. Add to entitlements file:
```xml
<key>com.apple.developer.applesignin</key>
<array>
  <string>Default</string>
</array>
```

### Issue: Token refresh failing

**Cause**: User session invalidated server-side
**Solution**: Clear local credentials and prompt re-authentication:
```swift
keychain.clearAll()
throw AuthError.sessionExpired
```
