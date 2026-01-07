import Foundation
import Security

// MARK: - Keychain Service

/// Secure storage for authentication tokens using iOS Keychain
public final class KeychainService: Sendable {
  public static let shared = KeychainService()

  private let serviceName = "com.rizq.ios"

  private enum Keys {
    static let sessionToken = "session_token"
    static let userId = "user_id"
    static let authUser = "auth_user"
    static let authSession = "auth_session"
  }

  private init() {}

  // MARK: - Session Token

  public func saveSessionToken(_ token: String) throws {
    try save(key: Keys.sessionToken, data: Data(token.utf8))
  }

  public func getSessionToken() -> String? {
    guard let data = load(key: Keys.sessionToken) else { return nil }
    return String(data: data, encoding: .utf8)
  }

  public func deleteSessionToken() {
    delete(key: Keys.sessionToken)
  }

  // MARK: - User ID

  public func saveUserId(_ userId: String) throws {
    try save(key: Keys.userId, data: Data(userId.utf8))
  }

  public func getUserId() -> String? {
    guard let data = load(key: Keys.userId) else { return nil }
    return String(data: data, encoding: .utf8)
  }

  public func deleteUserId() {
    delete(key: Keys.userId)
  }

  // MARK: - Auth User

  public func saveAuthUser(_ user: AuthUser) throws {
    let encoder = JSONEncoder()
    encoder.dateEncodingStrategy = .iso8601
    let data = try encoder.encode(user)
    try save(key: Keys.authUser, data: data)
  }

  public func getAuthUser() -> AuthUser? {
    guard let data = load(key: Keys.authUser) else { return nil }
    let decoder = JSONDecoder()
    decoder.dateDecodingStrategy = .iso8601
    return try? decoder.decode(AuthUser.self, from: data)
  }

  public func deleteAuthUser() {
    delete(key: Keys.authUser)
  }

  // MARK: - Auth Session

  public func saveAuthSession(_ session: AuthSession) throws {
    let encoder = JSONEncoder()
    encoder.dateEncodingStrategy = .iso8601
    let data = try encoder.encode(session)
    try save(key: Keys.authSession, data: data)
  }

  public func getAuthSession() -> AuthSession? {
    guard let data = load(key: Keys.authSession) else { return nil }
    let decoder = JSONDecoder()
    decoder.dateDecodingStrategy = .iso8601
    return try? decoder.decode(AuthSession.self, from: data)
  }

  public func deleteAuthSession() {
    delete(key: Keys.authSession)
  }

  // MARK: - Clear All Auth Data

  public func clearAll() {
    deleteSessionToken()
    deleteUserId()
    deleteAuthUser()
    deleteAuthSession()
  }

  // MARK: - Restore Auth State

  /// Attempts to restore a valid auth state from keychain
  public func restoreAuthState() -> (user: AuthUser, session: AuthSession)? {
    guard let user = getAuthUser(),
          let session = getAuthSession(),
          !session.isExpired else {
      // Clear invalid state
      clearAll()
      return nil
    }
    return (user, session)
  }

  // MARK: - Private Keychain Operations

  private func save(key: String, data: Data) throws {
    // Delete existing item first
    delete(key: key)

    let query: [String: Any] = [
      kSecClass as String: kSecClassGenericPassword,
      kSecAttrService as String: serviceName,
      kSecAttrAccount as String: key,
      kSecValueData as String: data,
      kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly
    ]

    let status = SecItemAdd(query as CFDictionary, nil)
    guard status == errSecSuccess else {
      throw KeychainError.saveFailed(status)
    }
  }

  private func load(key: String) -> Data? {
    let query: [String: Any] = [
      kSecClass as String: kSecClassGenericPassword,
      kSecAttrService as String: serviceName,
      kSecAttrAccount as String: key,
      kSecReturnData as String: true,
      kSecMatchLimit as String: kSecMatchLimitOne
    ]

    var result: AnyObject?
    let status = SecItemCopyMatching(query as CFDictionary, &result)

    guard status == errSecSuccess else { return nil }
    return result as? Data
  }

  private func delete(key: String) {
    let query: [String: Any] = [
      kSecClass as String: kSecClassGenericPassword,
      kSecAttrService as String: serviceName,
      kSecAttrAccount as String: key
    ]

    SecItemDelete(query as CFDictionary)
  }
}

// MARK: - Keychain Error

public enum KeychainError: Error, Sendable {
  case saveFailed(OSStatus)
  case loadFailed(OSStatus)
  case deleteFailed(OSStatus)
  case dataConversionFailed

  public var localizedDescription: String {
    switch self {
    case .saveFailed(let status):
      return "Failed to save to keychain (status: \(status))"
    case .loadFailed(let status):
      return "Failed to load from keychain (status: \(status))"
    case .deleteFailed(let status):
      return "Failed to delete from keychain (status: \(status))"
    case .dataConversionFailed:
      return "Failed to convert keychain data"
    }
  }
}
