---
name: networking-patterns
description: "URLSession async/await patterns for Neon PostgreSQL API, Codable models, error handling, and caching strategies"
---

# Networking Patterns for iOS

This skill provides patterns for building the networking layer in the RIZQ iOS app, connecting to Neon PostgreSQL via REST API.

---

## Architecture Overview

```
┌─────────────────────────────────────────────────────────────┐
│                      SwiftUI Views                          │
└─────────────────────────┬───────────────────────────────────┘
                          │
┌─────────────────────────▼───────────────────────────────────┐
│                   TCA Features                              │
│  (Actions trigger Effects that call API)                    │
└─────────────────────────┬───────────────────────────────────┘
                          │
┌─────────────────────────▼───────────────────────────────────┐
│                   API Client                                │
│  (Protocol-based, injectable dependency)                    │
└─────────────────────────┬───────────────────────────────────┘
                          │
┌─────────────────────────▼───────────────────────────────────┐
│               URLSession + async/await                      │
└─────────────────────────┬───────────────────────────────────┘
                          │
┌─────────────────────────▼───────────────────────────────────┐
│             Neon PostgreSQL (via REST API)                  │
└─────────────────────────────────────────────────────────────┘
```

---

## API Client Protocol

### Base Protocol Definition

```swift
// MARK: - API Client Protocol
protocol APIClientProtocol: Sendable {
  func fetch<T: Decodable>(_ endpoint: Endpoint) async throws -> T
  func fetchArray<T: Decodable>(_ endpoint: Endpoint) async throws -> [T]
  func execute(_ endpoint: Endpoint) async throws
}

// MARK: - Endpoint Definition
struct Endpoint: Sendable {
  let path: String
  let method: HTTPMethod
  let queryItems: [URLQueryItem]?
  let body: Data?
  let headers: [String: String]?

  init(
    path: String,
    method: HTTPMethod = .get,
    queryItems: [URLQueryItem]? = nil,
    body: Data? = nil,
    headers: [String: String]? = nil
  ) {
    self.path = path
    self.method = method
    self.queryItems = queryItems
    self.body = body
    self.headers = headers
  }
}

enum HTTPMethod: String, Sendable {
  case get = "GET"
  case post = "POST"
  case put = "PUT"
  case patch = "PATCH"
  case delete = "DELETE"
}
```

### Live Implementation

```swift
// MARK: - Live API Client
final class APIClient: APIClientProtocol {
  private let baseURL: URL
  private let session: URLSession
  private let decoder: JSONDecoder
  private let encoder: JSONEncoder

  init(
    baseURL: URL,
    session: URLSession = .shared,
    decoder: JSONDecoder = .rizqDecoder,
    encoder: JSONEncoder = .rizqEncoder
  ) {
    self.baseURL = baseURL
    self.session = session
    self.decoder = decoder
    self.encoder = encoder
  }

  func fetch<T: Decodable>(_ endpoint: Endpoint) async throws -> T {
    let request = try buildRequest(for: endpoint)
    let (data, response) = try await session.data(for: request)
    try validateResponse(response)
    return try decoder.decode(T.self, from: data)
  }

  func fetchArray<T: Decodable>(_ endpoint: Endpoint) async throws -> [T] {
    let request = try buildRequest(for: endpoint)
    let (data, response) = try await session.data(for: request)
    try validateResponse(response)
    return try decoder.decode([T].self, from: data)
  }

  func execute(_ endpoint: Endpoint) async throws {
    let request = try buildRequest(for: endpoint)
    let (_, response) = try await session.data(for: request)
    try validateResponse(response)
  }

  // MARK: - Private Helpers

  private func buildRequest(for endpoint: Endpoint) throws -> URLRequest {
    var components = URLComponents(url: baseURL.appendingPathComponent(endpoint.path), resolvingAgainstBaseURL: true)
    components?.queryItems = endpoint.queryItems

    guard let url = components?.url else {
      throw APIError.invalidURL
    }

    var request = URLRequest(url: url)
    request.httpMethod = endpoint.method.rawValue
    request.httpBody = endpoint.body

    // Default headers
    request.setValue("application/json", forHTTPHeaderField: "Content-Type")
    request.setValue("application/json", forHTTPHeaderField: "Accept")

    // Custom headers
    endpoint.headers?.forEach { key, value in
      request.setValue(value, forHTTPHeaderField: key)
    }

    return request
  }

  private func validateResponse(_ response: URLResponse) throws {
    guard let httpResponse = response as? HTTPURLResponse else {
      throw APIError.invalidResponse
    }

    switch httpResponse.statusCode {
    case 200...299:
      return // Success
    case 401:
      throw APIError.unauthorized
    case 403:
      throw APIError.forbidden
    case 404:
      throw APIError.notFound
    case 422:
      throw APIError.validationError
    case 429:
      throw APIError.rateLimited
    case 500...599:
      throw APIError.serverError(httpResponse.statusCode)
    default:
      throw APIError.unknown(httpResponse.statusCode)
    }
  }
}
```

---

## Error Handling

### API Error Types

```swift
// MARK: - API Errors
enum APIError: Error, Equatable, LocalizedError {
  case invalidURL
  case invalidResponse
  case unauthorized
  case forbidden
  case notFound
  case validationError
  case rateLimited
  case serverError(Int)
  case networkError(String)
  case decodingError(String)
  case unknown(Int)

  var errorDescription: String? {
    switch self {
    case .invalidURL:
      return "Invalid URL"
    case .invalidResponse:
      return "Invalid server response"
    case .unauthorized:
      return "Please sign in to continue"
    case .forbidden:
      return "You don't have permission to access this"
    case .notFound:
      return "Resource not found"
    case .validationError:
      return "Please check your input"
    case .rateLimited:
      return "Too many requests. Please wait a moment."
    case .serverError(let code):
      return "Server error (\(code)). Please try again later."
    case .networkError(let message):
      return "Network error: \(message)"
    case .decodingError(let message):
      return "Data error: \(message)"
    case .unknown(let code):
      return "Unknown error (\(code))"
    }
  }

  var isRetryable: Bool {
    switch self {
    case .rateLimited, .serverError, .networkError:
      return true
    default:
      return false
    }
  }
}
```

### Error Mapping

```swift
// MARK: - Error Mapping Extension
extension APIClient {
  func fetchWithErrorMapping<T: Decodable>(_ endpoint: Endpoint) async throws -> T {
    do {
      return try await fetch(endpoint)
    } catch let urlError as URLError {
      throw mapURLError(urlError)
    } catch let decodingError as DecodingError {
      throw mapDecodingError(decodingError)
    } catch {
      throw error
    }
  }

  private func mapURLError(_ error: URLError) -> APIError {
    switch error.code {
    case .notConnectedToInternet, .networkConnectionLost:
      return .networkError("No internet connection")
    case .timedOut:
      return .networkError("Request timed out")
    case .cannotFindHost, .cannotConnectToHost:
      return .networkError("Cannot connect to server")
    default:
      return .networkError(error.localizedDescription)
    }
  }

  private func mapDecodingError(_ error: DecodingError) -> APIError {
    switch error {
    case .keyNotFound(let key, _):
      return .decodingError("Missing key: \(key.stringValue)")
    case .typeMismatch(let type, let context):
      return .decodingError("Type mismatch for \(type) at \(context.codingPath)")
    case .valueNotFound(let type, _):
      return .decodingError("Missing value for \(type)")
    default:
      return .decodingError(error.localizedDescription)
    }
  }
}
```

---

## Codable Patterns

### JSON Decoder/Encoder Configuration

```swift
// MARK: - JSON Configuration
extension JSONDecoder {
  static let rizqDecoder: JSONDecoder = {
    let decoder = JSONDecoder()
    decoder.keyDecodingStrategy = .convertFromSnakeCase
    decoder.dateDecodingStrategy = .custom { decoder in
      let container = try decoder.singleValueContainer()
      let dateString = try container.decode(String.self)

      // Try ISO8601 with fractional seconds
      if let date = ISO8601DateFormatter.rizqFormatter.date(from: dateString) {
        return date
      }

      // Try simple date format
      if let date = DateFormatter.rizqDateFormatter.date(from: dateString) {
        return date
      }

      throw DecodingError.dataCorruptedError(
        in: container,
        debugDescription: "Cannot decode date: \(dateString)"
      )
    }
    return decoder
  }()
}

extension JSONEncoder {
  static let rizqEncoder: JSONEncoder = {
    let encoder = JSONEncoder()
    encoder.keyEncodingStrategy = .convertToSnakeCase
    encoder.dateEncodingStrategy = .iso8601
    return encoder
  }()
}

extension ISO8601DateFormatter {
  static let rizqFormatter: ISO8601DateFormatter = {
    let formatter = ISO8601DateFormatter()
    formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
    return formatter
  }()
}

extension DateFormatter {
  static let rizqDateFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateFormat = "yyyy-MM-dd"
    formatter.locale = Locale(identifier: "en_US_POSIX")
    formatter.timeZone = TimeZone(identifier: "UTC")
    return formatter
  }()
}
```

### Model Mapping (DB → Swift)

```swift
// MARK: - Database Response Models
// Mirror the snake_case from PostgreSQL

struct DuaDTO: Decodable {
  let id: Int
  let categoryId: Int  // Auto-converted from category_id
  let collectionId: Int?
  let titleEn: String
  let arabicText: String
  let transliteration: String
  let translationEn: String
  let source: String?
  let repetitions: Int
  let bestTime: String?
  let difficulty: String?
  let rizqBenefit: String?
  let context: String?
  let propheticContext: String?
  let xpValue: Int
  let createdAt: Date?
}

// MARK: - Domain Models
// camelCase Swift conventions

struct Dua: Identifiable, Equatable, Sendable {
  let id: Int
  let categoryId: Int
  let title: String
  let arabicText: String
  let transliteration: String
  let translation: String
  let source: String?
  let repetitions: Int
  let bestTime: TimeSlot?
  let difficulty: Difficulty?
  let rizqBenefit: String?
  let context: String?
  let propheticContext: String?
  let xpValue: Int
}

// MARK: - Mapping Extension
extension DuaDTO {
  func toDomain() -> Dua {
    Dua(
      id: id,
      categoryId: categoryId,
      title: titleEn,
      arabicText: arabicText,
      transliteration: transliteration,
      translation: translationEn,
      source: source,
      repetitions: repetitions,
      bestTime: bestTime.flatMap { TimeSlot(rawValue: $0) },
      difficulty: difficulty.flatMap { Difficulty(rawValue: $0) },
      rizqBenefit: rizqBenefit,
      context: context,
      propheticContext: propheticContext,
      xpValue: xpValue
    )
  }
}

// MARK: - Array Mapping
extension Array where Element == DuaDTO {
  func toDomain() -> [Dua] {
    map { $0.toDomain() }
  }
}
```

---

## Neon PostgreSQL Integration

### Direct SQL Queries via REST

```swift
// MARK: - Neon SQL Client
final class NeonClient: Sendable {
  private let connectionString: String
  private let session: URLSession

  init(connectionString: String, session: URLSession = .shared) {
    self.connectionString = connectionString
    self.session = session
  }

  /// Execute a SQL query and decode results
  func query<T: Decodable>(_ sql: String, parameters: [Any] = []) async throws -> [T] {
    let endpoint = URL(string: "\(connectionString)/sql")!

    var request = URLRequest(url: endpoint)
    request.httpMethod = "POST"
    request.setValue("application/json", forHTTPHeaderField: "Content-Type")

    let body: [String: Any] = [
      "query": sql,
      "params": parameters
    ]
    request.httpBody = try JSONSerialization.data(withJSONObject: body)

    let (data, response) = try await session.data(for: request)

    guard let httpResponse = response as? HTTPURLResponse,
          (200...299).contains(httpResponse.statusCode) else {
      throw APIError.serverError((response as? HTTPURLResponse)?.statusCode ?? 500)
    }

    // Neon returns { rows: [...], fields: [...] }
    let result = try JSONDecoder.rizqDecoder.decode(NeonResponse<T>.self, from: data)
    return result.rows
  }

  /// Execute a SQL statement (INSERT, UPDATE, DELETE)
  func execute(_ sql: String, parameters: [Any] = []) async throws {
    let _: [EmptyRow] = try await query(sql, parameters: parameters)
  }
}

// MARK: - Neon Response Wrapper
struct NeonResponse<T: Decodable>: Decodable {
  let rows: [T]
  let rowCount: Int?
}

struct EmptyRow: Decodable {}
```

### Type-Safe Query Builder

```swift
// MARK: - Query Builder
struct SQLQuery: Sendable {
  private var sql: String
  private var parameters: [Any]

  init(_ sql: String) {
    self.sql = sql
    self.parameters = []
  }

  mutating func bind(_ value: Any) -> Self {
    parameters.append(value)
    return self
  }

  var parameterizedSQL: String {
    var result = sql
    for (index, _) in parameters.enumerated() {
      result = result.replacingOccurrences(of: "$\(index + 1)", with: "$\(index + 1)")
    }
    return result
  }
}

// MARK: - Dua Repository
protocol DuaRepositoryProtocol: Sendable {
  func fetchAll() async throws -> [Dua]
  func fetchById(_ id: Int) async throws -> Dua?
  func fetchByCategory(_ categoryId: Int) async throws -> [Dua]
  func fetchByJourney(_ journeyId: Int) async throws -> [Dua]
}

final class DuaRepository: DuaRepositoryProtocol {
  private let client: NeonClient

  init(client: NeonClient) {
    self.client = client
  }

  func fetchAll() async throws -> [Dua] {
    let dtos: [DuaDTO] = try await client.query("""
      SELECT * FROM duas ORDER BY id
    """)
    return dtos.toDomain()
  }

  func fetchById(_ id: Int) async throws -> Dua? {
    let dtos: [DuaDTO] = try await client.query("""
      SELECT * FROM duas WHERE id = $1
    """, parameters: [id])
    return dtos.first?.toDomain()
  }

  func fetchByCategory(_ categoryId: Int) async throws -> [Dua] {
    let dtos: [DuaDTO] = try await client.query("""
      SELECT * FROM duas WHERE category_id = $1 ORDER BY id
    """, parameters: [categoryId])
    return dtos.toDomain()
  }

  func fetchByJourney(_ journeyId: Int) async throws -> [Dua] {
    let dtos: [DuaDTO] = try await client.query("""
      SELECT d.* FROM duas d
      INNER JOIN journey_duas jd ON d.id = jd.dua_id
      WHERE jd.journey_id = $1
      ORDER BY jd.sort_order
    """, parameters: [journeyId])
    return dtos.toDomain()
  }
}
```

---

## Retry Logic

### Exponential Backoff

```swift
// MARK: - Retry Configuration
struct RetryConfiguration: Sendable {
  let maxAttempts: Int
  let initialDelay: TimeInterval
  let maxDelay: TimeInterval
  let multiplier: Double

  static let `default` = RetryConfiguration(
    maxAttempts: 3,
    initialDelay: 1.0,
    maxDelay: 30.0,
    multiplier: 2.0
  )

  static let aggressive = RetryConfiguration(
    maxAttempts: 5,
    initialDelay: 0.5,
    maxDelay: 60.0,
    multiplier: 2.0
  )
}

// MARK: - Retry Extension
extension APIClient {
  func fetchWithRetry<T: Decodable>(
    _ endpoint: Endpoint,
    config: RetryConfiguration = .default
  ) async throws -> T {
    var lastError: Error?
    var delay = config.initialDelay

    for attempt in 1...config.maxAttempts {
      do {
        return try await fetch(endpoint)
      } catch let error as APIError where error.isRetryable {
        lastError = error

        if attempt < config.maxAttempts {
          try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
          delay = min(delay * config.multiplier, config.maxDelay)
        }
      } catch {
        throw error // Non-retryable error
      }
    }

    throw lastError ?? APIError.unknown(0)
  }
}
```

### Retry with Jitter

```swift
// MARK: - Jittered Retry
extension APIClient {
  func fetchWithJitteredRetry<T: Decodable>(
    _ endpoint: Endpoint,
    config: RetryConfiguration = .default
  ) async throws -> T {
    var lastError: Error?
    var delay = config.initialDelay

    for attempt in 1...config.maxAttempts {
      do {
        return try await fetch(endpoint)
      } catch let error as APIError where error.isRetryable {
        lastError = error

        if attempt < config.maxAttempts {
          // Add jitter: 0.5x to 1.5x of calculated delay
          let jitter = Double.random(in: 0.5...1.5)
          let jitteredDelay = delay * jitter

          try await Task.sleep(nanoseconds: UInt64(jitteredDelay * 1_000_000_000))
          delay = min(delay * config.multiplier, config.maxDelay)
        }
      } catch {
        throw error
      }
    }

    throw lastError ?? APIError.unknown(0)
  }
}
```

---

## Caching Strategies

### In-Memory Cache

```swift
// MARK: - Cache Entry
struct CacheEntry<T: Sendable>: Sendable {
  let value: T
  let timestamp: Date
  let ttl: TimeInterval

  var isExpired: Bool {
    Date().timeIntervalSince(timestamp) > ttl
  }
}

// MARK: - In-Memory Cache
actor APICache {
  private var storage: [String: Any] = [:]
  private let defaultTTL: TimeInterval = 300 // 5 minutes

  func get<T: Sendable>(_ key: String) -> T? {
    guard let entry = storage[key] as? CacheEntry<T>,
          !entry.isExpired else {
      storage.removeValue(forKey: key)
      return nil
    }
    return entry.value
  }

  func set<T: Sendable>(_ key: String, value: T, ttl: TimeInterval? = nil) {
    let entry = CacheEntry(
      value: value,
      timestamp: Date(),
      ttl: ttl ?? defaultTTL
    )
    storage[key] = entry
  }

  func invalidate(_ key: String) {
    storage.removeValue(forKey: key)
  }

  func invalidateAll() {
    storage.removeAll()
  }

  func invalidateExpired() {
    for (key, value) in storage {
      if let entry = value as? CacheEntry<Any>, entry.isExpired {
        storage.removeValue(forKey: key)
      }
    }
  }
}

// MARK: - Cached API Client
final class CachedAPIClient: APIClientProtocol {
  private let client: APIClient
  private let cache: APICache

  init(client: APIClient, cache: APICache = APICache()) {
    self.client = client
    self.cache = cache
  }

  func fetch<T: Decodable>(_ endpoint: Endpoint) async throws -> T {
    let cacheKey = endpoint.cacheKey

    // Check cache first
    if let cached: T = await cache.get(cacheKey) {
      return cached
    }

    // Fetch from network
    let result: T = try await client.fetch(endpoint)

    // Cache result
    if let sendable = result as? (T & Sendable) {
      await cache.set(cacheKey, value: sendable)
    }

    return result
  }

  func fetchArray<T: Decodable>(_ endpoint: Endpoint) async throws -> [T] {
    try await client.fetchArray(endpoint)
  }

  func execute(_ endpoint: Endpoint) async throws {
    try await client.execute(endpoint)
    // Optionally invalidate related cache entries
  }
}

// MARK: - Cache Key Generation
extension Endpoint {
  var cacheKey: String {
    var components = [path, method.rawValue]
    if let queryItems = queryItems {
      components.append(queryItems.map { "\($0.name)=\($0.value ?? "")" }.joined(separator: "&"))
    }
    return components.joined(separator: ":")
  }
}
```

### Disk Cache with URLCache

```swift
// MARK: - URLSession with Caching
extension URLSession {
  static let cachedSession: URLSession = {
    let config = URLSessionConfiguration.default

    // 50 MB memory cache, 100 MB disk cache
    config.urlCache = URLCache(
      memoryCapacity: 50 * 1024 * 1024,
      diskCapacity: 100 * 1024 * 1024,
      diskPath: "rizq_api_cache"
    )

    config.requestCachePolicy = .returnCacheDataElseLoad
    config.timeoutIntervalForRequest = 30
    config.timeoutIntervalForResource = 60

    return URLSession(configuration: config)
  }()
}

// MARK: - Cache Control Headers
extension URLRequest {
  mutating func setCachePolicy(maxAge: Int) {
    setValue("max-age=\(maxAge)", forHTTPHeaderField: "Cache-Control")
  }

  mutating func forceRefresh() {
    setValue("no-cache", forHTTPHeaderField: "Cache-Control")
  }
}
```

---

## TCA Integration

### API Client Dependency

```swift
import ComposableArchitecture

// MARK: - API Client Dependency Key
struct APIClientKey: DependencyKey {
  static let liveValue: APIClientProtocol = APIClient(
    baseURL: URL(string: "https://your-neon-project.neon.tech")!
  )

  static let testValue: APIClientProtocol = MockAPIClient()
  static let previewValue: APIClientProtocol = MockAPIClient()
}

extension DependencyValues {
  var apiClient: APIClientProtocol {
    get { self[APIClientKey.self] }
    set { self[APIClientKey.self] = newValue }
  }
}

// MARK: - Usage in Feature
@Reducer
struct DuaListFeature {
  @ObservableState
  struct State: Equatable {
    var duas: [Dua] = []
    var isLoading = false
    var error: String?
  }

  enum Action {
    case onAppear
    case duasLoaded(Result<[Dua], Error>)
  }

  @Dependency(\.apiClient) var apiClient

  var body: some ReducerOf<Self> {
    Reduce { state, action in
      switch action {
      case .onAppear:
        state.isLoading = true
        return .run { send in
          do {
            let dtos: [DuaDTO] = try await apiClient.fetchArray(
              Endpoint(path: "/duas")
            )
            await send(.duasLoaded(.success(dtos.toDomain())))
          } catch {
            await send(.duasLoaded(.failure(error)))
          }
        }

      case .duasLoaded(.success(let duas)):
        state.duas = duas
        state.isLoading = false
        return .none

      case .duasLoaded(.failure(let error)):
        state.error = (error as? APIError)?.errorDescription ?? error.localizedDescription
        state.isLoading = false
        return .none
      }
    }
  }
}
```

---

## Request/Response Logging

### Debug Logger

```swift
// MARK: - Network Logger
enum NetworkLogger {
  static var isEnabled = true

  static func logRequest(_ request: URLRequest) {
    guard isEnabled else { return }

    print("🌐 REQUEST ────────────────────────")
    print("   URL: \(request.url?.absoluteString ?? "nil")")
    print("   Method: \(request.httpMethod ?? "GET")")

    if let headers = request.allHTTPHeaderFields, !headers.isEmpty {
      print("   Headers:")
      headers.forEach { print("     \($0.key): \($0.value)") }
    }

    if let body = request.httpBody,
       let json = try? JSONSerialization.jsonObject(with: body),
       let prettyData = try? JSONSerialization.data(withJSONObject: json, options: .prettyPrinted),
       let prettyString = String(data: prettyData, encoding: .utf8) {
      print("   Body: \(prettyString)")
    }
    print("───────────────────────────────────")
  }

  static func logResponse(_ response: HTTPURLResponse, data: Data, duration: TimeInterval) {
    guard isEnabled else { return }

    let statusEmoji = (200...299).contains(response.statusCode) ? "✅" : "❌"

    print("\(statusEmoji) RESPONSE ─────────────────────────")
    print("   Status: \(response.statusCode)")
    print("   Duration: \(String(format: "%.2f", duration * 1000))ms")
    print("   Size: \(ByteCountFormatter.string(fromByteCount: Int64(data.count), countStyle: .memory))")

    if let json = try? JSONSerialization.jsonObject(with: data),
       let prettyData = try? JSONSerialization.data(withJSONObject: json, options: .prettyPrinted),
       let prettyString = String(data: prettyData, encoding: .utf8) {
      let truncated = prettyString.prefix(1000)
      print("   Body: \(truncated)\(prettyString.count > 1000 ? "..." : "")")
    }
    print("───────────────────────────────────")
  }

  static func logError(_ error: Error) {
    guard isEnabled else { return }

    print("❌ ERROR ──────────────────────────")
    print("   \(error.localizedDescription)")
    print("───────────────────────────────────")
  }
}

// MARK: - Logged API Client
final class LoggedAPIClient: APIClientProtocol {
  private let client: APIClient

  init(client: APIClient) {
    self.client = client
  }

  func fetch<T: Decodable>(_ endpoint: Endpoint) async throws -> T {
    let start = Date()
    // Note: For full logging, you'd need access to the raw request/response
    do {
      let result: T = try await client.fetch(endpoint)
      return result
    } catch {
      NetworkLogger.logError(error)
      throw error
    }
  }

  func fetchArray<T: Decodable>(_ endpoint: Endpoint) async throws -> [T] {
    try await client.fetchArray(endpoint)
  }

  func execute(_ endpoint: Endpoint) async throws {
    try await client.execute(endpoint)
  }
}
```

---

## Offline Support

### Network Reachability

```swift
import Network

// MARK: - Network Monitor
@Observable
final class NetworkMonitor {
  static let shared = NetworkMonitor()

  private let monitor = NWPathMonitor()
  private let queue = DispatchQueue(label: "NetworkMonitor")

  var isConnected = true
  var connectionType: ConnectionType = .unknown

  enum ConnectionType {
    case wifi
    case cellular
    case ethernet
    case unknown
  }

  private init() {
    monitor.pathUpdateHandler = { [weak self] path in
      DispatchQueue.main.async {
        self?.isConnected = path.status == .satisfied
        self?.connectionType = self?.getConnectionType(path) ?? .unknown
      }
    }
    monitor.start(queue: queue)
  }

  private func getConnectionType(_ path: NWPath) -> ConnectionType {
    if path.usesInterfaceType(.wifi) { return .wifi }
    if path.usesInterfaceType(.cellular) { return .cellular }
    if path.usesInterfaceType(.wiredEthernet) { return .ethernet }
    return .unknown
  }
}

// MARK: - Offline-Aware API Client
final class OfflineAwareAPIClient: APIClientProtocol {
  private let client: APIClient
  private let cache: APICache

  init(client: APIClient, cache: APICache = APICache()) {
    self.client = client
    self.cache = cache
  }

  func fetch<T: Decodable>(_ endpoint: Endpoint) async throws -> T {
    // If offline, try cache first
    if !NetworkMonitor.shared.isConnected {
      if let cached: T = await cache.get(endpoint.cacheKey) {
        return cached
      }
      throw APIError.networkError("No internet connection")
    }

    // Online: fetch and cache
    let result: T = try await client.fetch(endpoint)
    if let sendable = result as? (T & Sendable) {
      await cache.set(endpoint.cacheKey, value: sendable, ttl: 3600) // 1 hour for offline
    }
    return result
  }

  func fetchArray<T: Decodable>(_ endpoint: Endpoint) async throws -> [T] {
    try await client.fetchArray(endpoint)
  }

  func execute(_ endpoint: Endpoint) async throws {
    if !NetworkMonitor.shared.isConnected {
      throw APIError.networkError("No internet connection")
    }
    try await client.execute(endpoint)
  }
}
```

---

## Reference: RIZQ API Endpoints

### Duas

```swift
// GET /duas - List all duas
// GET /duas/:id - Get single dua
// GET /duas?category_id=:id - Filter by category
// GET /duas?collection_id=:id - Filter by collection
```

### Journeys

```swift
// GET /journeys - List all journeys
// GET /journeys/:id - Get journey with duas
// GET /journeys/:id/duas - Get journey duas
```

### User Data

```swift
// GET /users/:id/profile - Get user profile
// PUT /users/:id/profile - Update profile
// POST /users/:id/activity - Log activity
// GET /users/:id/progress - Get dua progress
```

---

## Testing Mock

```swift
// MARK: - Mock API Client
final class MockAPIClient: APIClientProtocol {
  var stubbedResponses: [String: Any] = [:]
  var capturedEndpoints: [Endpoint] = []
  var shouldFail = false
  var failureError: APIError = .serverError(500)

  func fetch<T: Decodable>(_ endpoint: Endpoint) async throws -> T {
    capturedEndpoints.append(endpoint)

    if shouldFail {
      throw failureError
    }

    if let response = stubbedResponses[endpoint.path] as? T {
      return response
    }

    throw APIError.notFound
  }

  func fetchArray<T: Decodable>(_ endpoint: Endpoint) async throws -> [T] {
    capturedEndpoints.append(endpoint)

    if shouldFail {
      throw failureError
    }

    if let response = stubbedResponses[endpoint.path] as? [T] {
      return response
    }

    return []
  }

  func execute(_ endpoint: Endpoint) async throws {
    capturedEndpoints.append(endpoint)

    if shouldFail {
      throw failureError
    }
  }

  // MARK: - Test Helpers

  func stub<T>(_ path: String, with response: T) {
    stubbedResponses[path] = response
  }

  func reset() {
    stubbedResponses.removeAll()
    capturedEndpoints.removeAll()
    shouldFail = false
  }
}
```
