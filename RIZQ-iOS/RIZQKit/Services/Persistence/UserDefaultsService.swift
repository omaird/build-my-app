import Foundation

// MARK: - Storage Keys

/// Storage keys for UserDefaults - matches web app localStorage keys where applicable
public enum StorageKey: String, CaseIterable, Sendable {
  // Habit-related keys (match web app)
  case userHabits = "rizq_user_habits"
  case dailyActivity = "rizq_daily_activity"

  // User preferences
  case welcomeShown = "rizq_welcome_shown"
  case lastUsedProvider = "rizq_last_used_provider"
  case notificationsEnabled = "rizq_notifications_enabled"
  case darkModeEnabled = "rizq_dark_mode_enabled"
  case hapticFeedbackEnabled = "rizq_haptic_feedback_enabled"
  case arabicTextSize = "rizq_arabic_text_size"
  case showTransliteration = "rizq_show_transliteration"

  // Cache metadata
  case duasCacheTimestamp = "rizq_duas_cache_timestamp"
  case journeysCacheTimestamp = "rizq_journeys_cache_timestamp"

  // User session
  case lastActiveDate = "rizq_last_active_date"
  case currentUserId = "rizq_current_user_id"
}

// MARK: - UserDefaults Service Protocol

/// Protocol for UserDefaults operations to enable mocking
public protocol UserDefaultsServiceProtocol: Sendable {
  // Generic operations
  func set<T: Codable>(_ value: T, forKey key: StorageKey) async throws
  func get<T: Codable>(_ type: T.Type, forKey key: StorageKey) async throws -> T?
  func remove(forKey key: StorageKey) async
  func exists(forKey key: StorageKey) async -> Bool

  // Primitive operations
  func setBool(_ value: Bool, forKey key: StorageKey) async
  func getBool(forKey key: StorageKey) async -> Bool
  func setInt(_ value: Int, forKey key: StorageKey) async
  func getInt(forKey key: StorageKey) async -> Int
  func setDouble(_ value: Double, forKey key: StorageKey) async
  func getDouble(forKey key: StorageKey) async -> Double
  func setString(_ value: String, forKey key: StorageKey) async
  func getString(forKey key: StorageKey) async -> String?
  func setDate(_ value: Date, forKey key: StorageKey) async
  func getDate(forKey key: StorageKey) async -> Date?

  // Array operations for journey IDs
  func setIntArray(_ value: [Int], forKey key: StorageKey) async
  func getIntArray(forKey key: StorageKey) async -> [Int]

  // Cleanup
  func clearAll() async
}

// MARK: - UserDefaults Service

/// Actor-based service for thread-safe UserDefaults access with App Groups support
public actor UserDefaultsService: UserDefaultsServiceProtocol {

  // MARK: - Properties

  private let defaults: UserDefaults
  private let encoder: JSONEncoder
  private let decoder: JSONDecoder

  /// App Group identifier for sharing data with extensions/widgets
  public static let appGroupIdentifier = "group.com.rizq.app"

  // MARK: - Singleton

  /// Shared instance using App Group UserDefaults
  public static let shared: UserDefaultsService = {
    if let groupDefaults = UserDefaults(suiteName: appGroupIdentifier) {
      return UserDefaultsService(defaults: groupDefaults)
    } else {
      // Fallback to standard UserDefaults if App Group not available
      return UserDefaultsService(defaults: .standard)
    }
  }()

  // MARK: - Initialization

  public init(defaults: UserDefaults = .standard) {
    self.defaults = defaults

    self.encoder = JSONEncoder()
    self.encoder.dateEncodingStrategy = .iso8601

    self.decoder = JSONDecoder()
    self.decoder.dateDecodingStrategy = .iso8601
  }

  // MARK: - Generic Codable Operations

  public func set<T: Codable>(_ value: T, forKey key: StorageKey) throws {
    let data = try encoder.encode(value)
    defaults.set(data, forKey: key.rawValue)
  }

  public func get<T: Codable>(_ type: T.Type, forKey key: StorageKey) throws -> T? {
    guard let data = defaults.data(forKey: key.rawValue) else {
      return nil
    }
    return try decoder.decode(type, from: data)
  }

  public func remove(forKey key: StorageKey) {
    defaults.removeObject(forKey: key.rawValue)
  }

  public func exists(forKey key: StorageKey) -> Bool {
    defaults.object(forKey: key.rawValue) != nil
  }

  // MARK: - Primitive Operations

  public func setBool(_ value: Bool, forKey key: StorageKey) {
    defaults.set(value, forKey: key.rawValue)
  }

  public func getBool(forKey key: StorageKey) -> Bool {
    defaults.bool(forKey: key.rawValue)
  }

  public func setInt(_ value: Int, forKey key: StorageKey) {
    defaults.set(value, forKey: key.rawValue)
  }

  public func getInt(forKey key: StorageKey) -> Int {
    defaults.integer(forKey: key.rawValue)
  }

  public func setDouble(_ value: Double, forKey key: StorageKey) {
    defaults.set(value, forKey: key.rawValue)
  }

  public func getDouble(forKey key: StorageKey) -> Double {
    defaults.double(forKey: key.rawValue)
  }

  public func setString(_ value: String, forKey key: StorageKey) {
    defaults.set(value, forKey: key.rawValue)
  }

  public func getString(forKey key: StorageKey) -> String? {
    defaults.string(forKey: key.rawValue)
  }

  public func setDate(_ value: Date, forKey key: StorageKey) {
    defaults.set(value, forKey: key.rawValue)
  }

  public func getDate(forKey key: StorageKey) -> Date? {
    defaults.object(forKey: key.rawValue) as? Date
  }

  // MARK: - Array Operations

  public func setIntArray(_ value: [Int], forKey key: StorageKey) {
    defaults.set(value, forKey: key.rawValue)
  }

  public func getIntArray(forKey key: StorageKey) -> [Int] {
    defaults.array(forKey: key.rawValue) as? [Int] ?? []
  }

  // MARK: - Cleanup

  public func clearAll() {
    for key in StorageKey.allCases {
      defaults.removeObject(forKey: key.rawValue)
    }
  }

  /// Clear only cache-related keys
  public func clearCaches() {
    defaults.removeObject(forKey: StorageKey.duasCacheTimestamp.rawValue)
    defaults.removeObject(forKey: StorageKey.journeysCacheTimestamp.rawValue)
  }
}

// MARK: - User Preferences

/// User preference settings stored in UserDefaults
public struct UserPreferences: Codable, Equatable, Sendable {
  public var notificationsEnabled: Bool
  public var darkModeEnabled: Bool
  public var hapticFeedbackEnabled: Bool
  public var arabicTextSize: ArabicTextSize
  public var showTransliteration: Bool

  public init(
    notificationsEnabled: Bool = true,
    darkModeEnabled: Bool = false,
    hapticFeedbackEnabled: Bool = true,
    arabicTextSize: ArabicTextSize = .medium,
    showTransliteration: Bool = true
  ) {
    self.notificationsEnabled = notificationsEnabled
    self.darkModeEnabled = darkModeEnabled
    self.hapticFeedbackEnabled = hapticFeedbackEnabled
    self.arabicTextSize = arabicTextSize
    self.showTransliteration = showTransliteration
  }

  public static let `default` = UserPreferences()
}

/// Arabic text size options
public enum ArabicTextSize: String, Codable, CaseIterable, Sendable {
  case small
  case medium
  case large
  case extraLarge = "extra_large"

  public var displayName: String {
    switch self {
    case .small: return "Small"
    case .medium: return "Medium"
    case .large: return "Large"
    case .extraLarge: return "Extra Large"
    }
  }

  /// Dynamic type text style
  public var textStyle: String {
    switch self {
    case .small: return "body"
    case .medium: return "title3"
    case .large: return "title2"
    case .extraLarge: return "title1"
    }
  }
}

// MARK: - Preferences Extension

extension UserDefaultsService {

  /// Load user preferences
  public func loadPreferences() throws -> UserPreferences {
    try get(UserPreferences.self, forKey: .userHabits) ?? .default
  }

  /// Save user preferences
  public func savePreferences(_ preferences: UserPreferences) throws {
    try set(preferences, forKey: .userHabits)
  }

  /// Update a single preference
  public func updatePreference<T>(_ keyPath: WritableKeyPath<UserPreferences, T>, to value: T) throws {
    var preferences = try loadPreferences()
    preferences[keyPath: keyPath] = value
    try savePreferences(preferences)
  }
}

// MARK: - Mock Implementation

/// Mock implementation for testing and previews
public actor MockUserDefaultsService: UserDefaultsServiceProtocol {
  private var storage: [String: Any] = [:]
  private let encoder = JSONEncoder()
  private let decoder = JSONDecoder()

  public init() {
    encoder.dateEncodingStrategy = .iso8601
    decoder.dateDecodingStrategy = .iso8601
  }

  public func set<T: Codable>(_ value: T, forKey key: StorageKey) throws {
    let data = try encoder.encode(value)
    storage[key.rawValue] = data
  }

  public func get<T: Codable>(_ type: T.Type, forKey key: StorageKey) throws -> T? {
    guard let data = storage[key.rawValue] as? Data else {
      return nil
    }
    return try decoder.decode(type, from: data)
  }

  public func remove(forKey key: StorageKey) {
    storage.removeValue(forKey: key.rawValue)
  }

  public func exists(forKey key: StorageKey) -> Bool {
    storage[key.rawValue] != nil
  }

  public func setBool(_ value: Bool, forKey key: StorageKey) {
    storage[key.rawValue] = value
  }

  public func getBool(forKey key: StorageKey) -> Bool {
    storage[key.rawValue] as? Bool ?? false
  }

  public func setInt(_ value: Int, forKey key: StorageKey) {
    storage[key.rawValue] = value
  }

  public func getInt(forKey key: StorageKey) -> Int {
    storage[key.rawValue] as? Int ?? 0
  }

  public func setDouble(_ value: Double, forKey key: StorageKey) {
    storage[key.rawValue] = value
  }

  public func getDouble(forKey key: StorageKey) -> Double {
    storage[key.rawValue] as? Double ?? 0.0
  }

  public func setString(_ value: String, forKey key: StorageKey) {
    storage[key.rawValue] = value
  }

  public func getString(forKey key: StorageKey) -> String? {
    storage[key.rawValue] as? String
  }

  public func setDate(_ value: Date, forKey key: StorageKey) {
    storage[key.rawValue] = value
  }

  public func getDate(forKey key: StorageKey) -> Date? {
    storage[key.rawValue] as? Date
  }

  public func setIntArray(_ value: [Int], forKey key: StorageKey) {
    storage[key.rawValue] = value
  }

  public func getIntArray(forKey key: StorageKey) -> [Int] {
    storage[key.rawValue] as? [Int] ?? []
  }

  public func clearAll() {
    storage.removeAll()
  }
}
