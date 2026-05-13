import ComposableArchitecture
import Foundation
import os
import RIZQKit

private let logger = Logger(subsystem: "com.rizq.app", category: "CachedContentClient")

/// TCA dependency client that wraps `FirestoreContentClient` with a last-known-good
/// UserDefaults cache. On each fetch:
/// 1. Attempt the network call via the underlying client.
/// 2. On success: JSON-encode the result and write to UserDefaults under the cache key.
/// 3. On failure: read the cached value and return it. If no cache exists, return `[]`.
///
/// Only the three list-fetch methods are exposed here. The remaining
/// `FirestoreContentClient` methods (`fetchDuasByCategory`, `fetchJourneyDuas`) remain
/// accessible via `\.firestoreContentClient` directly.
struct CachedContentClient: Sendable {
  var fetchAllDuas: @Sendable () async throws -> [Dua]
  var fetchAllJourneys: @Sendable () async throws -> [Journey]
  var fetchAllCategories: @Sendable () async throws -> [DuaCategory]

  init(wrapping underlying: FirestoreContentClient) {
    self.fetchAllDuas = Self.cachedFetch(
      key: "cached_duas",
      fetch: underlying.fetchAllDuas
    )
    self.fetchAllJourneys = Self.cachedFetch(
      key: "cached_journeys",
      fetch: underlying.fetchAllJourneys
    )
    self.fetchAllCategories = Self.cachedFetch(
      key: "cached_categories",
      fetch: underlying.fetchAllCategories
    )
  }

  /// JSON encoder used for cache writes. Dates are serialized as ISO8601 strings so
  /// they round-trip through models (notably `Dua`) whose custom decoders expect
  /// string-formatted dates rather than numeric `Date` defaults.
  private static func makeEncoder() -> JSONEncoder {
    let encoder = JSONEncoder()
    encoder.dateEncodingStrategy = .iso8601
    return encoder
  }

  /// JSON decoder paired with `makeEncoder` for the cache-read path.
  private static func makeDecoder() -> JSONDecoder {
    let decoder = JSONDecoder()
    decoder.dateDecodingStrategy = .iso8601
    return decoder
  }

  /// Build a fetch closure that tries `fetch()` and, on failure, falls back to the
  /// JSON-encoded last-known-good value in UserDefaults under `key`. On success the
  /// result is written back to the cache. On both network failure and absent/corrupt
  /// cache an empty array is returned.
  private static func cachedFetch<T: Codable & Sendable>(
    key: String,
    fetch: @escaping @Sendable () async throws -> [T]
  ) -> @Sendable () async throws -> [T] {
    return {
      do {
        let result = try await fetch()
        if let data = try? makeEncoder().encode(result) {
          UserDefaults.standard.set(data, forKey: key)
        }
        return result
      } catch {
        logger.error("Network fetch failed for \(key, privacy: .public); falling back to cache")
        if let data = UserDefaults.standard.data(forKey: key),
           let cached = try? makeDecoder().decode([T].self, from: data) {
          return cached
        }
        return []
      }
    }
  }
}

// MARK: - Dependency Key

extension CachedContentClient: DependencyKey {
  static let liveValue = CachedContentClient(
    wrapping: FirestoreContentClient.liveValue
  )

  static let testValue = CachedContentClient(
    wrapping: FirestoreContentClient.testValue
  )
}

// MARK: - Dependency Values

extension DependencyValues {
  var cachedContentClient: CachedContentClient {
    get { self[CachedContentClient.self] }
    set { self[CachedContentClient.self] = newValue }
  }
}
