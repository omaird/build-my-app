import Foundation

// MARK: - App Configuration

/// Combined configuration for all services
public struct AppConfiguration: Sendable {
  public let api: APIConfiguration
  public let auth: AuthConfiguration

  public init(api: APIConfiguration, auth: AuthConfiguration) {
    self.api = api
    self.auth = auth
  }

  /// Initialize with individual configuration values
  public init(
    neonHost: String,
    neonApiKey: String,
    projectId: String,
    authURL: String,
    callbackScheme: String = "rizq"
  ) {
    self.api = APIConfiguration(neonHost: neonHost, neonApiKey: neonApiKey, projectId: projectId)
    self.auth = AuthConfiguration(authURLString: authURL, callbackScheme: callbackScheme)
  }

  /// Create configuration from environment or Info.plist
  public static func fromEnvironment() -> AppConfiguration? {
    guard let apiConfig = APIConfiguration.fromEnvironment(),
          let authURL = ProcessInfo.processInfo.environment["AUTH_URL"]
            ?? Bundle.main.object(forInfoDictionaryKey: "AuthURL") as? String
    else {
      return nil
    }

    let callbackScheme = ProcessInfo.processInfo.environment["AUTH_CALLBACK_SCHEME"]
      ?? Bundle.main.object(forInfoDictionaryKey: "AuthCallbackScheme") as? String
      ?? "rizq"

    return AppConfiguration(
      api: apiConfig,
      auth: AuthConfiguration(authURLString: authURL, callbackScheme: callbackScheme)
    )
  }
}

// MARK: - Service Container

/// Central container for all services used by the app
public final class ServiceContainer: @unchecked Sendable {
  public static let shared = ServiceContainer()

  private var _neonService: (any NeonServiceProtocol)?
  private var _authService: (any AuthServiceProtocol)?
  private var _adminService: (any AdminServiceProtocol)?
  private var _userDefaultsService: UserDefaultsService?
  private var _habitStorage: HabitStorage?
  private var _cacheService: CacheService?
  private var _appConfiguration: AppConfiguration?
  private let lock = NSLock()

  private init() {
    // Initialize persistence services with defaults
    _userDefaultsService = .shared
    _habitStorage = .shared
    _cacheService = .shared
  }

  // MARK: - Configuration

  public func configure(with configuration: AppConfiguration) {
    lock.lock()
    defer { lock.unlock() }
    self._appConfiguration = configuration
    self._neonService = NeonService(configuration: configuration.api)
    self._authService = AuthService(configuration: configuration.auth)
    self._adminService = AdminService(configuration: configuration.api)
  }

  public func configureForPreview(authenticated: Bool = false) {
    lock.lock()
    defer { lock.unlock() }
    self._neonService = MockNeonService()
    self._authService = MockAuthService(authenticated: authenticated)
    self._adminService = MockAdminService()
  }

  // MARK: - Services

  public var neonService: any NeonServiceProtocol {
    lock.lock()
    defer { lock.unlock() }

    if let service = _neonService {
      return service
    }

    // Fallback to mock if not configured
    let mock = MockNeonService()
    _neonService = mock
    return mock
  }

  public var authService: any AuthServiceProtocol {
    lock.lock()
    defer { lock.unlock() }

    if let service = _authService {
      return service
    }

    // Fallback to mock if not configured
    let mock = MockAuthService()
    _authService = mock
    return mock
  }

  public var adminService: any AdminServiceProtocol {
    lock.lock()
    defer { lock.unlock() }

    if let service = _adminService {
      return service
    }

    // Fallback to mock if not configured
    let mock = MockAdminService()
    _adminService = mock
    return mock
  }

  public var appConfiguration: AppConfiguration? {
    lock.lock()
    defer { lock.unlock() }
    return _appConfiguration
  }

  public var isConfigured: Bool {
    lock.lock()
    defer { lock.unlock() }
    return _appConfiguration != nil
  }

  // MARK: - Persistence Services

  /// UserDefaults service for storing preferences and simple data
  public var userDefaultsService: UserDefaultsService {
    lock.lock()
    defer { lock.unlock() }
    return _userDefaultsService ?? .shared
  }

  /// Habit storage service for managing habit data
  public var habitStorage: HabitStorage {
    lock.lock()
    defer { lock.unlock() }
    return _habitStorage ?? .shared
  }

  /// Cache service for offline data storage
  public var cacheService: CacheService {
    lock.lock()
    defer { lock.unlock() }
    return _cacheService ?? .shared
  }

  /// Configure persistence services with custom instances (for testing)
  public func configurePersistence(
    userDefaults: UserDefaultsService? = nil,
    habitStorage: HabitStorage? = nil,
    cacheService: CacheService? = nil
  ) {
    lock.lock()
    defer { lock.unlock() }
    if let userDefaults = userDefaults {
      _userDefaultsService = userDefaults
    }
    if let habitStorage = habitStorage {
      _habitStorage = habitStorage
    }
    if let cacheService = cacheService {
      _cacheService = cacheService
    }
  }

  /// Clear all local data (for logout or reset)
  public func clearAllLocalData() async {
    try? await habitStorage.clearAllData()
    await userDefaultsService.clearAll()
    try? await cacheService.clear()
  }
}

// MARK: - Environment Keys (for SwiftUI)

import SwiftUI

private struct NeonServiceKey: EnvironmentKey {
  static let defaultValue: any NeonServiceProtocol = MockNeonService()
}

private struct AuthServiceKey: EnvironmentKey {
  static let defaultValue: any AuthServiceProtocol = MockAuthService()
}

private struct HabitStorageKey: EnvironmentKey {
  static let defaultValue: HabitStorage = .shared
}

private struct CacheServiceKey: EnvironmentKey {
  static let defaultValue: CacheService = .shared
}

private struct UserDefaultsServiceKey: EnvironmentKey {
  static let defaultValue: UserDefaultsService = .shared
}

public extension EnvironmentValues {
  var neonService: any NeonServiceProtocol {
    get { self[NeonServiceKey.self] }
    set { self[NeonServiceKey.self] = newValue }
  }

  var authService: any AuthServiceProtocol {
    get { self[AuthServiceKey.self] }
    set { self[AuthServiceKey.self] = newValue }
  }

  var habitStorage: HabitStorage {
    get { self[HabitStorageKey.self] }
    set { self[HabitStorageKey.self] = newValue }
  }

  var cacheService: CacheService {
    get { self[CacheServiceKey.self] }
    set { self[CacheServiceKey.self] = newValue }
  }

  var userDefaultsService: UserDefaultsService {
    get { self[UserDefaultsServiceKey.self] }
    set { self[UserDefaultsServiceKey.self] = newValue }
  }
}

// MARK: - View Extensions

public extension View {
  func withNeonService(_ service: any NeonServiceProtocol) -> some View {
    environment(\.neonService, service)
  }

  func withAuthService(_ service: any AuthServiceProtocol) -> some View {
    environment(\.authService, service)
  }

  func withHabitStorage(_ storage: HabitStorage) -> some View {
    environment(\.habitStorage, storage)
  }

  func withCacheService(_ cache: CacheService) -> some View {
    environment(\.cacheService, cache)
  }

  func withUserDefaultsService(_ defaults: UserDefaultsService) -> some View {
    environment(\.userDefaultsService, defaults)
  }

  func withServices(neon: any NeonServiceProtocol, auth: any AuthServiceProtocol) -> some View {
    self
      .environment(\.neonService, neon)
      .environment(\.authService, auth)
  }

  /// Configure all services from ServiceContainer
  func withAllServices() -> some View {
    let container = ServiceContainer.shared
    return self
      .environment(\.neonService, container.neonService)
      .environment(\.authService, container.authService)
      .environment(\.habitStorage, container.habitStorage)
      .environment(\.cacheService, container.cacheService)
      .environment(\.userDefaultsService, container.userDefaultsService)
  }
}
