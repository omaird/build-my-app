import Foundation
import FirebaseCore

// MARK: - App Configuration

/// Firebase-specific configuration
public struct FirebaseConfiguration: Sendable {
  public let projectId: String
  public let useEmulator: Bool
  public let emulatorHost: String
  public let authEmulatorPort: Int
  public let firestoreEmulatorPort: Int

  public init(
    projectId: String,
    useEmulator: Bool = false,
    emulatorHost: String = "localhost",
    authEmulatorPort: Int = 9099,
    firestoreEmulatorPort: Int = 8080
  ) {
    self.projectId = projectId
    self.useEmulator = useEmulator
    self.emulatorHost = emulatorHost
    self.authEmulatorPort = authEmulatorPort
    self.firestoreEmulatorPort = firestoreEmulatorPort
  }
}

/// Combined configuration for all services
public struct AppConfiguration: Sendable {
  public let firebase: FirebaseConfiguration

  public init(firebase: FirebaseConfiguration) {
    self.firebase = firebase
  }

  /// Create configuration from environment or Info.plist
  public static func fromEnvironment() -> AppConfiguration? {
    // Firebase auto-configures from GoogleService-Info.plist
    guard Bundle.main.path(forResource: "GoogleService-Info", ofType: "plist") != nil else {
      return nil
    }

    let useEmulator = ProcessInfo.processInfo.environment["USE_FIREBASE_EMULATOR"] == "true"
    let projectId = ProcessInfo.processInfo.environment["FIREBASE_PROJECT_ID"] ?? "rizq-app-c6468"
    return AppConfiguration(firebase: FirebaseConfiguration(projectId: projectId, useEmulator: useEmulator))
  }
}

// MARK: - Service Container

/// Central container for app-wide services.
/// User data and admin operations use TCA dependencies (\.firestoreUserClient, \.adminService).
/// This container holds auth + persistence services that are accessed outside reducers.
public final class ServiceContainer: @unchecked Sendable {
  public static let shared = ServiceContainer()

  private var _authService: (any AuthServiceProtocol)?
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

    // Firebase is configured via GoogleService-Info.plist
    // FirebaseApp.configure() should be called in RIZQApp.init()

    // Set up Firebase Auth service
    self._authService = FirebaseAuthService()
  }

  public func configureForPreview(authenticated: Bool = false) {
    lock.lock()
    defer { lock.unlock() }
    self._authService = MockAuthService(authenticated: authenticated)
  }

  // MARK: - Services

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

  /// Configure all services from ServiceContainer
  func withAllServices() -> some View {
    let container = ServiceContainer.shared
    return self
      .environment(\.authService, container.authService)
      .environment(\.habitStorage, container.habitStorage)
      .environment(\.cacheService, container.cacheService)
      .environment(\.userDefaultsService, container.userDefaultsService)
  }
}
