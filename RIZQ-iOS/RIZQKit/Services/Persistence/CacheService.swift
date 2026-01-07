import Foundation

// MARK: - Cache Configuration

/// Configuration for cache behavior
public struct CacheConfiguration: Sendable {
  /// Maximum age for cached data before it's considered stale (in seconds)
  public let maxAge: TimeInterval

  /// Whether to use stale data while revalidating
  public let staleWhileRevalidate: Bool

  /// Directory name within caches folder
  public let directoryName: String

  public init(
    maxAge: TimeInterval = 3600, // 1 hour default
    staleWhileRevalidate: Bool = true,
    directoryName: String = "rizq_cache"
  ) {
    self.maxAge = maxAge
    self.staleWhileRevalidate = staleWhileRevalidate
    self.directoryName = directoryName
  }

  /// Default configuration for dua caching
  public static let duas = CacheConfiguration(maxAge: 86400, directoryName: "rizq_cache") // 24 hours

  /// Default configuration for journey caching
  public static let journeys = CacheConfiguration(maxAge: 86400, directoryName: "rizq_cache") // 24 hours

  /// Short-lived cache for user data
  public static let userData = CacheConfiguration(maxAge: 300, directoryName: "rizq_cache") // 5 minutes
}

// MARK: - Cache Entry

/// Wrapper for cached data with metadata
public struct CacheEntry<T: Codable>: Codable {
  public let data: T
  public let timestamp: Date
  public let expiresAt: Date

  public init(data: T, maxAge: TimeInterval) {
    self.data = data
    self.timestamp = Date()
    self.expiresAt = Date().addingTimeInterval(maxAge)
  }

  public var isExpired: Bool {
    Date() > expiresAt
  }

  public var age: TimeInterval {
    Date().timeIntervalSince(timestamp)
  }
}

// MARK: - Cache Key

/// Type-safe cache keys
public enum CacheKey: String, CaseIterable, Sendable {
  case allDuas = "all_duas"
  case allJourneys = "all_journeys"
  case allCategories = "all_categories"
  case allCollections = "all_collections"
  case journeyDuas = "journey_duas" // Requires suffix: journey_duas_{id}
  case userProfile = "user_profile"
  case userActivity = "user_activity"

  /// Get the filename for this cache key
  public func filename(suffix: String? = nil) -> String {
    if let suffix = suffix {
      return "\(rawValue)_\(suffix).json"
    }
    return "\(rawValue).json"
  }
}

// MARK: - Cache Service Protocol

/// Protocol for cache operations
public protocol CacheServiceProtocol: Sendable {
  func get<T: Codable>(_ type: T.Type, forKey key: CacheKey, suffix: String?) async throws -> CacheEntry<T>?
  func set<T: Codable>(_ value: T, forKey key: CacheKey, suffix: String?, maxAge: TimeInterval?) async throws
  func remove(forKey key: CacheKey, suffix: String?) async throws
  func clear() async throws
  func clearExpired() async throws -> Int
}

// MARK: - Cache Errors

public enum CacheError: Error, LocalizedError {
  case directoryCreationFailed
  case encodingFailed(Error)
  case decodingFailed(Error)
  case writeFailed(Error)
  case readFailed(Error)
  case fileNotFound

  public var errorDescription: String? {
    switch self {
    case .directoryCreationFailed:
      return "Failed to create cache directory"
    case .encodingFailed(let error):
      return "Failed to encode cache data: \(error.localizedDescription)"
    case .decodingFailed(let error):
      return "Failed to decode cache data: \(error.localizedDescription)"
    case .writeFailed(let error):
      return "Failed to write cache file: \(error.localizedDescription)"
    case .readFailed(let error):
      return "Failed to read cache file: \(error.localizedDescription)"
    case .fileNotFound:
      return "Cache file not found"
    }
  }
}

// MARK: - Cache Service

/// Actor-based file cache service for offline data storage
public actor CacheService: CacheServiceProtocol {

  // MARK: - Properties

  private let fileManager: FileManager
  private let configuration: CacheConfiguration
  private let encoder: JSONEncoder
  private let decoder: JSONDecoder

  private var cacheDirectory: URL?

  // MARK: - Singleton

  public static let shared = CacheService()

  // MARK: - Initialization

  public init(
    configuration: CacheConfiguration = CacheConfiguration(),
    fileManager: FileManager = .default
  ) {
    self.configuration = configuration
    self.fileManager = fileManager

    self.encoder = JSONEncoder()
    self.encoder.dateEncodingStrategy = .iso8601
    self.encoder.outputFormatting = [.prettyPrinted, .sortedKeys]

    self.decoder = JSONDecoder()
    self.decoder.dateDecodingStrategy = .iso8601
  }

  // MARK: - Directory Management

  private func getCacheDirectory() throws -> URL {
    if let existing = cacheDirectory {
      return existing
    }

    guard let cachesDir = fileManager.urls(for: .cachesDirectory, in: .userDomainMask).first else {
      throw CacheError.directoryCreationFailed
    }

    let cacheDir = cachesDir.appendingPathComponent(configuration.directoryName, isDirectory: true)

    // Create directory if it doesn't exist
    if !fileManager.fileExists(atPath: cacheDir.path) {
      do {
        try fileManager.createDirectory(at: cacheDir, withIntermediateDirectories: true)
      } catch {
        throw CacheError.directoryCreationFailed
      }
    }

    cacheDirectory = cacheDir
    return cacheDir
  }

  private func fileURL(forKey key: CacheKey, suffix: String?) throws -> URL {
    let directory = try getCacheDirectory()
    return directory.appendingPathComponent(key.filename(suffix: suffix))
  }

  // MARK: - Cache Operations

  public func get<T: Codable>(_ type: T.Type, forKey key: CacheKey, suffix: String? = nil) throws -> CacheEntry<T>? {
    let url = try fileURL(forKey: key, suffix: suffix)

    guard fileManager.fileExists(atPath: url.path) else {
      return nil
    }

    do {
      let data = try Data(contentsOf: url)
      let entry = try decoder.decode(CacheEntry<T>.self, from: data)
      return entry
    } catch let error as DecodingError {
      // If decoding fails, remove the corrupted cache file
      try? fileManager.removeItem(at: url)
      throw CacheError.decodingFailed(error)
    } catch {
      throw CacheError.readFailed(error)
    }
  }

  public func set<T: Codable>(
    _ value: T,
    forKey key: CacheKey,
    suffix: String? = nil,
    maxAge: TimeInterval? = nil
  ) throws {
    let url = try fileURL(forKey: key, suffix: suffix)
    let effectiveMaxAge = maxAge ?? configuration.maxAge

    let entry = CacheEntry(data: value, maxAge: effectiveMaxAge)

    do {
      let data = try encoder.encode(entry)
      try data.write(to: url, options: [.atomic])
    } catch let error as EncodingError {
      throw CacheError.encodingFailed(error)
    } catch {
      throw CacheError.writeFailed(error)
    }
  }

  public func remove(forKey key: CacheKey, suffix: String? = nil) throws {
    let url = try fileURL(forKey: key, suffix: suffix)

    if fileManager.fileExists(atPath: url.path) {
      try fileManager.removeItem(at: url)
    }
  }

  public func clear() throws {
    let directory = try getCacheDirectory()

    let contents = try fileManager.contentsOfDirectory(at: directory, includingPropertiesForKeys: nil)
    for url in contents {
      try fileManager.removeItem(at: url)
    }
  }

  /// Clear expired cache entries and return count of removed files
  public func clearExpired() throws -> Int {
    let directory = try getCacheDirectory()
    var removedCount = 0

    let contents = try fileManager.contentsOfDirectory(at: directory, includingPropertiesForKeys: nil)

    for url in contents {
      // Try to read and check expiration
      do {
        let data = try Data(contentsOf: url)
        // Decode just the timestamp to check expiration
        struct TimestampOnly: Codable {
          let expiresAt: Date
        }
        let entry = try decoder.decode(TimestampOnly.self, from: data)

        if Date() > entry.expiresAt {
          try fileManager.removeItem(at: url)
          removedCount += 1
        }
      } catch {
        // If we can't read/decode, remove the file
        try? fileManager.removeItem(at: url)
        removedCount += 1
      }
    }

    return removedCount
  }

  // MARK: - Convenience Methods

  /// Get cached data, returning nil if expired (unless staleWhileRevalidate is enabled)
  public func getCachedData<T: Codable>(
    _ type: T.Type,
    forKey key: CacheKey,
    suffix: String? = nil,
    allowStale: Bool? = nil
  ) throws -> T? {
    guard let entry = try get(type, forKey: key, suffix: suffix) else {
      return nil
    }

    let shouldAllowStale = allowStale ?? configuration.staleWhileRevalidate

    if entry.isExpired && !shouldAllowStale {
      // Remove expired entry
      try? remove(forKey: key, suffix: suffix)
      return nil
    }

    return entry.data
  }

  /// Check if cache exists and is valid
  public func hasValidCache(forKey key: CacheKey, suffix: String? = nil) throws -> Bool {
    let url = try fileURL(forKey: key, suffix: suffix)

    guard fileManager.fileExists(atPath: url.path) else {
      return false
    }

    // Check expiration
    do {
      let data = try Data(contentsOf: url)
      struct TimestampOnly: Codable {
        let expiresAt: Date
      }
      let entry = try decoder.decode(TimestampOnly.self, from: data)
      return Date() <= entry.expiresAt
    } catch {
      return false
    }
  }

  /// Get cache age in seconds, or nil if not cached
  public func getCacheAge(forKey key: CacheKey, suffix: String? = nil) throws -> TimeInterval? {
    let url = try fileURL(forKey: key, suffix: suffix)

    guard fileManager.fileExists(atPath: url.path) else {
      return nil
    }

    do {
      let data = try Data(contentsOf: url)
      struct TimestampOnly: Codable {
        let timestamp: Date
      }
      let entry = try decoder.decode(TimestampOnly.self, from: data)
      return Date().timeIntervalSince(entry.timestamp)
    } catch {
      return nil
    }
  }

  /// Get total cache size in bytes
  public func getCacheSize() throws -> Int64 {
    let directory = try getCacheDirectory()
    var totalSize: Int64 = 0

    let contents = try fileManager.contentsOfDirectory(at: directory, includingPropertiesForKeys: [.fileSizeKey])

    for url in contents {
      let values = try url.resourceValues(forKeys: [.fileSizeKey])
      totalSize += Int64(values.fileSize ?? 0)
    }

    return totalSize
  }
}

// MARK: - Typed Cache Extensions

extension CacheService {

  // MARK: - Duas Cache

  public func cacheDuas(_ duas: [Dua]) throws {
    try set(duas, forKey: .allDuas, suffix: nil, maxAge: CacheConfiguration.duas.maxAge)
  }

  public func getCachedDuas() throws -> [Dua]? {
    try getCachedData([Dua].self, forKey: .allDuas)
  }

  // MARK: - Journeys Cache

  public func cacheJourneys(_ journeys: [Journey]) throws {
    try set(journeys, forKey: .allJourneys, suffix: nil, maxAge: CacheConfiguration.journeys.maxAge)
  }

  public func getCachedJourneys() throws -> [Journey]? {
    try getCachedData([Journey].self, forKey: .allJourneys)
  }

  // MARK: - Journey Duas Cache

  public func cacheJourneyDuas(_ duas: [JourneyDua], forJourneyId journeyId: Int) throws {
    try set(duas, forKey: .journeyDuas, suffix: "\(journeyId)", maxAge: CacheConfiguration.journeys.maxAge)
  }

  public func getCachedJourneyDuas(forJourneyId journeyId: Int) throws -> [JourneyDua]? {
    try getCachedData([JourneyDua].self, forKey: .journeyDuas, suffix: "\(journeyId)")
  }

  // MARK: - Categories Cache

  public func cacheCategories(_ categories: [DuaCategory]) throws {
    try set(categories, forKey: .allCategories, suffix: nil, maxAge: CacheConfiguration.duas.maxAge)
  }

  public func getCachedCategories() throws -> [DuaCategory]? {
    try getCachedData([DuaCategory].self, forKey: .allCategories)
  }

  // MARK: - Collections Cache

  public func cacheCollections(_ collections: [DuaCollection]) throws {
    try set(collections, forKey: .allCollections, suffix: nil, maxAge: CacheConfiguration.duas.maxAge)
  }

  public func getCachedCollections() throws -> [DuaCollection]? {
    try getCachedData([DuaCollection].self, forKey: .allCollections)
  }
}

// MARK: - Mock Implementation

/// Mock cache service for testing and previews
public actor MockCacheService: CacheServiceProtocol {
  private var cache: [String: Any] = [:]

  public init() {}

  private func cacheKey(_ key: CacheKey, suffix: String?) -> String {
    if let suffix = suffix {
      return "\(key.rawValue)_\(suffix)"
    }
    return key.rawValue
  }

  public func get<T: Codable>(_ type: T.Type, forKey key: CacheKey, suffix: String?) async throws -> CacheEntry<T>? {
    let cacheKey = cacheKey(key, suffix: suffix)
    return cache[cacheKey] as? CacheEntry<T>
  }

  public func set<T: Codable>(_ value: T, forKey key: CacheKey, suffix: String?, maxAge: TimeInterval?) async throws {
    let cacheKey = cacheKey(key, suffix: suffix)
    let entry = CacheEntry(data: value, maxAge: maxAge ?? 300)
    cache[cacheKey] = entry
  }

  public func remove(forKey key: CacheKey, suffix: String?) async throws {
    let cacheKey = cacheKey(key, suffix: suffix)
    cache.removeValue(forKey: cacheKey)
  }

  public func clear() async throws {
    cache.removeAll()
  }

  public func clearExpired() async throws -> Int {
    0 // No-op for mock
  }
}
