import Foundation
import FirebaseAuth
import FirebaseCore
import GoogleSignIn
import AuthenticationServices

// MARK: - Firebase Auth Service

public actor FirebaseAuthService: AuthServiceProtocol {
  private let keychain: KeychainService

  public init() {
    self.keychain = KeychainService.shared
  }

  // MARK: - Email Sign In

  public func signInWithEmail(email: String, password: String) async throws -> AuthResponse {
    do {
      let result = try await Auth.auth().signIn(withEmail: email, password: password)
      let authResponse = try await mapFirebaseUserToAuthResponse(result.user)
      try saveAuthState(authResponse)
      return authResponse
    } catch let error as NSError {
      throw mapFirebaseError(error)
    }
  }

  // MARK: - Email Sign Up

  public func signUpWithEmail(email: String, password: String, name: String?) async throws -> AuthResponse {
    do {
      let result = try await Auth.auth().createUser(withEmail: email, password: password)

      // Update display name if provided
      if let name = name {
        let changeRequest = result.user.createProfileChangeRequest()
        changeRequest.displayName = name
        try await changeRequest.commitChanges()
      }

      let authResponse = try await mapFirebaseUserToAuthResponse(result.user)
      try saveAuthState(authResponse)
      return authResponse
    } catch let error as NSError {
      throw mapFirebaseError(error)
    }
  }

  // MARK: - OAuth Sign In

  public func signInWithOAuth(provider: AuthProvider, presentingWindow: ASPresentationAnchor?) async throws -> AuthResponse {
    switch provider {
    case .google:
      return try await signInWithGoogle(presentingWindow: presentingWindow)
    case .apple:
      return try await signInWithApple(presentingWindow: presentingWindow)
    case .github:
      throw RIZQAuthError.oauthFailed("GitHub sign-in not supported with Firebase")
    case .email:
      throw RIZQAuthError.oauthFailed("Email is not an OAuth provider")
    }
  }

  // MARK: - Google Sign In

  @MainActor
  private func signInWithGoogle(presentingWindow: ASPresentationAnchor?) async throws -> AuthResponse {
    guard let clientID = FirebaseApp.app()?.options.clientID else {
      throw RIZQAuthError.oauthFailed("Firebase client ID not configured")
    }

    let config = GIDConfiguration(clientID: clientID)
    GIDSignIn.sharedInstance.configuration = config

    guard let windowScene = await UIApplication.shared.connectedScenes.first as? UIWindowScene,
          let rootViewController = await windowScene.windows.first?.rootViewController else {
      throw RIZQAuthError.oauthFailed("No root view controller available")
    }

    do {
      let result = try await GIDSignIn.sharedInstance.signIn(withPresenting: rootViewController)

      guard let idToken = result.user.idToken?.tokenString else {
        throw RIZQAuthError.oauthFailed("No ID token received from Google")
      }

      let credential = GoogleAuthProvider.credential(
        withIDToken: idToken,
        accessToken: result.user.accessToken.tokenString
      )

      let authResult = try await Auth.auth().signIn(with: credential)
      let authResponse = try await mapFirebaseUserToAuthResponse(authResult.user)
      try saveAuthState(authResponse)
      return authResponse
    } catch let error as GIDSignInError {
      if error.code == .canceled {
        throw RIZQAuthError.oauthCancelled
      }
      throw RIZQAuthError.oauthFailed(error.localizedDescription)
    } catch let error as NSError {
      throw mapFirebaseError(error)
    }
  }

  // MARK: - Apple Sign In

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
      throw RIZQAuthError.oauthFailed("Unable to get Apple ID token")
    }

    let firebaseCredential = OAuthProvider.appleCredential(
      withIDToken: idTokenString,
      rawNonce: nonce,
      fullName: credential.fullName
    )

    do {
      let authResult = try await Auth.auth().signIn(with: firebaseCredential)
      let authResponse = try await mapFirebaseUserToAuthResponse(authResult.user)
      try saveAuthState(authResponse)
      return authResponse
    } catch let error as NSError {
      throw mapFirebaseError(error)
    }
  }

  // MARK: - Sign Out

  public func signOut() async throws {
    do {
      try Auth.auth().signOut()
      GIDSignIn.sharedInstance.signOut()
      keychain.clearAll()
    } catch {
      keychain.clearAll()
      throw RIZQAuthError.unknown(error.localizedDescription)
    }
  }

  // MARK: - Session Management

  public func getSession() async throws -> AuthSession? {
    guard let user = Auth.auth().currentUser else {
      return nil
    }

    do {
      let token = try await user.getIDToken()
      return AuthSession(
        id: UUID().uuidString,
        userId: user.uid,
        token: token,
        expiresAt: Date().addingTimeInterval(3600) // Firebase tokens expire in 1 hour
      )
    } catch {
      return nil
    }
  }

  public func refreshSession() async throws -> AuthSession {
    guard let user = Auth.auth().currentUser else {
      throw RIZQAuthError.sessionExpired
    }

    do {
      let token = try await user.getIDToken(forcingRefresh: true)
      let session = AuthSession(
        id: UUID().uuidString,
        userId: user.uid,
        token: token,
        expiresAt: Date().addingTimeInterval(3600)
      )
      try keychain.saveSessionToken(token)
      return session
    } catch {
      keychain.clearAll()
      throw RIZQAuthError.sessionExpired
    }
  }

  // MARK: - Current User

  public func getCurrentUser() async throws -> AuthUser? {
    guard let user = Auth.auth().currentUser else {
      return nil
    }
    return mapFirebaseUserToAuthUser(user)
  }

  // MARK: - Linked Accounts

  public func getLinkedAccounts() async throws -> [LinkedAccount] {
    guard let user = Auth.auth().currentUser else {
      return []
    }

    return user.providerData.compactMap { providerInfo -> LinkedAccount? in
      guard let provider = mapProviderID(providerInfo.providerID) else {
        return nil
      }
      return LinkedAccount(
        id: providerInfo.uid,
        provider: provider,
        providerAccountId: providerInfo.uid,
        createdAt: user.metadata.creationDate ?? Date()
      )
    }
  }

  public func linkAccount(provider: AuthProvider, presentingWindow: ASPresentationAnchor?) async throws -> LinkedAccount {
    guard let user = Auth.auth().currentUser else {
      throw RIZQAuthError.sessionExpired
    }

    let credential: AuthCredential

    switch provider {
    case .google:
      credential = try await getGoogleCredential(presentingWindow: presentingWindow)
    case .apple:
      credential = try await getAppleCredential(presentingWindow: presentingWindow)
    case .github, .email:
      throw RIZQAuthError.unknown("Provider not supported for linking")
    }

    do {
      let result = try await user.link(with: credential)
      let providerData = result.user.providerData.first { mapProviderID($0.providerID) == provider }

      return LinkedAccount(
        id: providerData?.uid ?? UUID().uuidString,
        provider: provider,
        providerAccountId: providerData?.uid ?? "",
        createdAt: Date()
      )
    } catch let error as NSError {
      throw mapFirebaseError(error)
    }
  }

  public func unlinkAccount(provider: AuthProvider) async throws {
    guard let user = Auth.auth().currentUser else {
      throw RIZQAuthError.sessionExpired
    }

    let providerID: String
    switch provider {
    case .google:
      providerID = GoogleAuthProviderID
    case .apple:
      providerID = "apple.com"
    case .github:
      providerID = "github.com"
    case .email:
      providerID = EmailAuthProviderID
    }

    do {
      try await user.unlink(fromProvider: providerID)
    } catch let error as NSError {
      throw mapFirebaseError(error)
    }
  }

  // MARK: - Stored Credentials

  public nonisolated func restoreSession() -> (user: AuthUser, session: AuthSession)? {
    // Firebase handles session persistence automatically
    // Check if we have a current user
    guard let firebaseUser = Auth.auth().currentUser else {
      return keychain.restoreAuthState()
    }

    let user = AuthUser(
      id: firebaseUser.uid,
      email: firebaseUser.email,
      name: firebaseUser.displayName,
      image: firebaseUser.photoURL?.absoluteString,
      emailVerified: firebaseUser.isEmailVerified,
      createdAt: firebaseUser.metadata.creationDate ?? Date(),
      updatedAt: Date()
    )

    // We can't get the token synchronously, so use cached session
    if let cachedSession = keychain.restoreAuthState()?.session {
      return (user, cachedSession)
    }

    return nil
  }

  public nonisolated func clearStoredCredentials() {
    keychain.clearAll()
  }

  // MARK: - Helper Methods

  private func mapFirebaseUserToAuthResponse(_ user: FirebaseAuth.User) async throws -> AuthResponse {
    let token = try await user.getIDToken()

    let authUser = mapFirebaseUserToAuthUser(user)
    let session = AuthSession(
      id: UUID().uuidString,
      userId: user.uid,
      token: token,
      expiresAt: Date().addingTimeInterval(3600)
    )

    return AuthResponse(user: authUser, session: session)
  }

  private func mapFirebaseUserToAuthUser(_ user: FirebaseAuth.User) -> AuthUser {
    AuthUser(
      id: user.uid,
      email: user.email,
      name: user.displayName,
      image: user.photoURL?.absoluteString,
      emailVerified: user.isEmailVerified,
      createdAt: user.metadata.creationDate ?? Date(),
      updatedAt: Date()
    )
  }

  private nonisolated func mapFirebaseError(_ error: NSError) -> RIZQAuthError {
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

  private func mapProviderID(_ providerID: String) -> AuthProvider? {
    switch providerID {
    case GoogleAuthProviderID:
      return .google
    case "apple.com":
      return .apple
    case "github.com":
      return .github
    case EmailAuthProviderID:
      return .email
    default:
      return nil
    }
  }

  private nonisolated func saveAuthState(_ response: AuthResponse) throws {
    let keychain = KeychainService.shared
    try keychain.saveSessionToken(response.session.token)
    try keychain.saveUserId(response.user.id)
    try keychain.saveAuthUser(response.user)
    try keychain.saveAuthSession(response.session)
  }

  @MainActor
  private func getGoogleCredential(presentingWindow: ASPresentationAnchor?) async throws -> AuthCredential {
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

    return GoogleAuthProvider.credential(
      withIDToken: idToken,
      accessToken: result.user.accessToken.tokenString
    )
  }

  @MainActor
  private func getAppleCredential(presentingWindow: ASPresentationAnchor?) async throws -> AuthCredential {
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
      throw RIZQAuthError.oauthFailed("Unable to get Apple ID token")
    }

    return OAuthProvider.appleCredential(
      withIDToken: idTokenString,
      rawNonce: nonce,
      fullName: credential.fullName
    )
  }

  // MARK: - Nonce Helpers

  private nonisolated func randomNonceString(length: Int = 32) -> String {
    precondition(length > 0)
    var randomBytes = [UInt8](repeating: 0, count: length)
    let errorCode = SecRandomCopyBytes(kSecRandomDefault, randomBytes.count, &randomBytes)
    if errorCode != errSecSuccess {
      fatalError("Unable to generate nonce. SecRandomCopyBytes failed with OSStatus \(errorCode)")
    }

    let charset: [Character] = Array("0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._")
    return String(randomBytes.map { byte in charset[Int(byte) % charset.count] })
  }

  private nonisolated func sha256(_ input: String) -> String {
    let inputData = Data(input.utf8)
    var hash = [UInt8](repeating: 0, count: Int(CC_SHA256_DIGEST_LENGTH))
    inputData.withUnsafeBytes {
      _ = CC_SHA256($0.baseAddress, CC_LONG(inputData.count), &hash)
    }
    return hash.map { String(format: "%02x", $0) }.joined()
  }
}

// MARK: - Apple Sign In Delegate

@MainActor
private final class AppleSignInDelegate: NSObject, ASAuthorizationControllerDelegate {
  private var continuation: CheckedContinuation<ASAuthorizationAppleIDCredential, Error>?

  func waitForCredential() async throws -> ASAuthorizationAppleIDCredential {
    try await withCheckedThrowingContinuation { continuation in
      self.continuation = continuation
    }
  }

  func authorizationController(controller: ASAuthorizationController, didCompleteWithAuthorization authorization: ASAuthorization) {
    guard let credential = authorization.credential as? ASAuthorizationAppleIDCredential else {
      continuation?.resume(throwing: RIZQAuthError.oauthFailed("Invalid Apple credential"))
      return
    }
    continuation?.resume(returning: credential)
  }

  func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: Error) {
    if let authError = error as? ASAuthorizationError, authError.code == .canceled {
      continuation?.resume(throwing: RIZQAuthError.oauthCancelled)
    } else {
      continuation?.resume(throwing: RIZQAuthError.oauthFailed(error.localizedDescription))
    }
  }
}

// MARK: - Presentation Context Provider

@MainActor
private final class ApplePresentationContextProvider: NSObject, ASAuthorizationControllerPresentationContextProviding {
  private let anchor: ASPresentationAnchor

  init(anchor: ASPresentationAnchor) {
    self.anchor = anchor
  }

  func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
    anchor
  }
}

// MARK: - Common Crypto Import

import CommonCrypto
