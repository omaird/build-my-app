import Foundation

// MARK: - Auth Provider

public enum AuthProvider: String, Codable, Sendable, CaseIterable {
  case google
  case apple
  case github
  case email

  public var displayName: String {
    switch self {
    case .google: return "Google"
    case .apple: return "Apple"
    case .github: return "GitHub"
    case .email: return "Email"
    }
  }

  public var iconName: String {
    switch self {
    case .google: return "g.circle.fill"
    case .apple: return "apple.logo"
    case .github: return "chevron.left.forwardslash.chevron.right"
    case .email: return "envelope.fill"
    }
  }
}

// MARK: - Auth User

public struct AuthUser: Codable, Identifiable, Equatable, Sendable {
  public let id: String
  public let email: String?
  public let name: String?
  public let image: String?
  public let emailVerified: Bool
  public let createdAt: Date
  public let updatedAt: Date

  public init(
    id: String,
    email: String? = nil,
    name: String? = nil,
    image: String? = nil,
    emailVerified: Bool = false,
    createdAt: Date = Date(),
    updatedAt: Date = Date()
  ) {
    self.id = id
    self.email = email
    self.name = name
    self.image = image
    self.emailVerified = emailVerified
    self.createdAt = createdAt
    self.updatedAt = updatedAt
  }

  private enum CodingKeys: String, CodingKey {
    case id
    case email
    case name
    case image
    case emailVerified = "email_verified"
    case createdAt = "created_at"
    case updatedAt = "updated_at"
  }
}

// MARK: - Auth Session

public struct AuthSession: Codable, Identifiable, Equatable, Sendable {
  public let id: String
  public let userId: String
  public let token: String
  public let expiresAt: Date
  public let createdAt: Date
  public let updatedAt: Date
  public let ipAddress: String?
  public let userAgent: String?

  public init(
    id: String,
    userId: String,
    token: String,
    expiresAt: Date,
    createdAt: Date = Date(),
    updatedAt: Date = Date(),
    ipAddress: String? = nil,
    userAgent: String? = nil
  ) {
    self.id = id
    self.userId = userId
    self.token = token
    self.expiresAt = expiresAt
    self.createdAt = createdAt
    self.updatedAt = updatedAt
    self.ipAddress = ipAddress
    self.userAgent = userAgent
  }

  private enum CodingKeys: String, CodingKey {
    case id
    case userId = "user_id"
    case token
    case expiresAt = "expires_at"
    case createdAt = "created_at"
    case updatedAt = "updated_at"
    case ipAddress = "ip_address"
    case userAgent = "user_agent"
  }

  public var isExpired: Bool {
    expiresAt < Date()
  }
}

// MARK: - Auth State

public struct AuthState: Equatable, Sendable {
  public var user: AuthUser?
  public var session: AuthSession?
  public var profile: UserProfile?
  public var isLoading: Bool
  public var error: AuthError?

  public init(
    user: AuthUser? = nil,
    session: AuthSession? = nil,
    profile: UserProfile? = nil,
    isLoading: Bool = false,
    error: AuthError? = nil
  ) {
    self.user = user
    self.session = session
    self.profile = profile
    self.isLoading = isLoading
    self.error = error
  }

  public var isAuthenticated: Bool {
    user != nil && session != nil && !(session?.isExpired ?? true)
  }

  public var isAdmin: Bool {
    profile?.isAdmin ?? false
  }
}

// MARK: - Auth Error

public enum AuthError: Error, Equatable, Sendable {
  case invalidCredentials
  case emailAlreadyExists
  case userNotFound
  case sessionExpired
  case networkError(String)
  case oauthCancelled
  case oauthFailed(String)
  case keychainError(String)
  case unknown(String)

  public var localizedDescription: String {
    switch self {
    case .invalidCredentials:
      return "Invalid email or password"
    case .emailAlreadyExists:
      return "An account with this email already exists"
    case .userNotFound:
      return "No account found with this email"
    case .sessionExpired:
      return "Your session has expired. Please sign in again."
    case .networkError(let message):
      return "Network error: \(message)"
    case .oauthCancelled:
      return "Sign in was cancelled"
    case .oauthFailed(let message):
      return "Sign in failed: \(message)"
    case .keychainError(let message):
      return "Security error: \(message)"
    case .unknown(let message):
      return message
    }
  }
}

// MARK: - Auth Response Types

public struct AuthResponse: Codable, Sendable {
  public let user: AuthUser
  public let session: AuthSession

  public init(user: AuthUser, session: AuthSession) {
    self.user = user
    self.session = session
  }
}

public struct SignUpRequest: Codable, Sendable {
  public let email: String
  public let password: String
  public let name: String?

  public init(email: String, password: String, name: String? = nil) {
    self.email = email
    self.password = password
    self.name = name
  }
}

public struct SignInRequest: Codable, Sendable {
  public let email: String
  public let password: String

  public init(email: String, password: String) {
    self.email = email
    self.password = password
  }
}

// MARK: - Linked Account

public struct LinkedAccount: Codable, Identifiable, Equatable, Sendable {
  public let id: String
  public let provider: AuthProvider
  public let providerAccountId: String
  public let createdAt: Date

  public init(
    id: String,
    provider: AuthProvider,
    providerAccountId: String,
    createdAt: Date = Date()
  ) {
    self.id = id
    self.provider = provider
    self.providerAccountId = providerAccountId
    self.createdAt = createdAt
  }

  private enum CodingKeys: String, CodingKey {
    case id
    case provider
    case providerAccountId = "provider_account_id"
    case createdAt = "created_at"
  }
}
