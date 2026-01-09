import Foundation
import os.log

private let apiLogger = Logger(subsystem: "com.rizq.app", category: "APIClient")

// MARK: - API Error

public enum APIError: Error, LocalizedError, Sendable {
  case invalidURL
  case invalidResponse
  case httpError(statusCode: Int, message: String?)
  case decodingError(Error)
  case networkError(Error)
  case sqlError(String)
  case unauthorized
  case notFound
  case serverError(String)

  public var errorDescription: String? {
    switch self {
    case .invalidURL:
      return "Invalid URL"
    case .invalidResponse:
      return "Invalid response from server"
    case .httpError(let statusCode, let message):
      return "HTTP Error \(statusCode): \(message ?? "Unknown error")"
    case .decodingError(let error):
      return "Failed to decode response: \(error.localizedDescription)"
    case .networkError(let error):
      return "Network error: \(error.localizedDescription)"
    case .sqlError(let message):
      return "SQL error: \(message)"
    case .unauthorized:
      return "Unauthorized - please sign in"
    case .notFound:
      return "Resource not found"
    case .serverError(let message):
      return "Server error: \(message)"
    }
  }
}

// MARK: - API Configuration

public struct APIConfiguration: Sendable {
  public let neonHost: String
  public let neonApiKey: String
  public let projectId: String
  public let databaseUrl: String

  /// The HTTP endpoint for Neon SQL API
  public var sqlEndpoint: String {
    "https://\(neonHost)/sql"
  }

  public init(neonHost: String, neonApiKey: String, projectId: String, databaseUrl: String = "") {
    self.neonHost = neonHost
    self.neonApiKey = neonApiKey
    self.projectId = projectId
    self.databaseUrl = databaseUrl
  }

  /// Create configuration from environment or Info.plist
  public static func fromEnvironment() -> APIConfiguration? {
    guard let host = ProcessInfo.processInfo.environment["NEON_HOST"]
            ?? Bundle.main.object(forInfoDictionaryKey: "NeonHost") as? String,
          let apiKey = ProcessInfo.processInfo.environment["NEON_API_KEY"]
            ?? Bundle.main.object(forInfoDictionaryKey: "NeonApiKey") as? String,
          let projectId = ProcessInfo.processInfo.environment["NEON_PROJECT_ID"]
            ?? Bundle.main.object(forInfoDictionaryKey: "NeonProjectId") as? String
    else {
      return nil
    }

    // Database URL is required for Neon HTTP SQL API
    let databaseUrl = ProcessInfo.processInfo.environment["NEON_DATABASE_URL"]
            ?? Bundle.main.object(forInfoDictionaryKey: "NeonDatabaseUrl") as? String
            ?? ""

    return APIConfiguration(
      neonHost: host,
      neonApiKey: apiKey,
      projectId: projectId,
      databaseUrl: databaseUrl
    )
  }
}

// MARK: - Neon SQL Request/Response

/// Request body for Neon HTTP SQL API
struct NeonSQLRequest: Encodable {
  let query: String
  let params: [SQLValue]?

  init(query: String, params: [SQLValue]? = nil) {
    self.query = query
    self.params = params
  }
}

/// SQL parameter value wrapper
public enum SQLValue: Encodable, Sendable {
  case string(String)
  case int(Int)
  case double(Double)
  case bool(Bool)
  case null
  case intArray([Int])
  case stringArray([String])

  public func encode(to encoder: Encoder) throws {
    var container = encoder.singleValueContainer()
    switch self {
    case .string(let value):
      try container.encode(value)
    case .int(let value):
      try container.encode(value)
    case .double(let value):
      try container.encode(value)
    case .bool(let value):
      try container.encode(value)
    case .null:
      try container.encodeNil()
    case .intArray(let value):
      try container.encode(value)
    case .stringArray(let value):
      try container.encode(value)
    }
  }
}

/// Response from Neon HTTP SQL API
struct NeonSQLResponse: Decodable {
  let fields: [NeonField]
  let rows: [NeonRow]  // Rows are objects, not arrays
  let rowAsArray: Bool?

  struct NeonField: Decodable {
    let name: String
    let dataTypeID: Int
  }
}

/// A row from Neon can be either an object (dictionary) or array depending on rowAsArray setting
struct NeonRow: Decodable {
  let values: [String: NeonValue]

  init(from decoder: Decoder) throws {
    let container = try decoder.singleValueContainer()
    values = try container.decode([String: NeonValue].self)
  }
}

/// Neon value can be various types
enum NeonValue: Decodable {
  case string(String)
  case int(Int)
  case double(Double)
  case bool(Bool)
  case null
  case array([NeonValue])

  init(from decoder: Decoder) throws {
    let container = try decoder.singleValueContainer()

    if container.decodeNil() {
      self = .null
      return
    }

    if let intValue = try? container.decode(Int.self) {
      self = .int(intValue)
      return
    }

    if let doubleValue = try? container.decode(Double.self) {
      self = .double(doubleValue)
      return
    }

    if let boolValue = try? container.decode(Bool.self) {
      self = .bool(boolValue)
      return
    }

    if let stringValue = try? container.decode(String.self) {
      self = .string(stringValue)
      return
    }

    if let arrayValue = try? container.decode([NeonValue].self) {
      self = .array(arrayValue)
      return
    }

    self = .null
  }

  var stringValue: String? {
    if case .string(let value) = self { return value }
    return nil
  }

  var intValue: Int? {
    switch self {
    case .int(let value): return value
    case .double(let value): return Int(value)
    case .string(let value): return Int(value)
    default: return nil
    }
  }

  var doubleValue: Double? {
    switch self {
    case .double(let value): return value
    case .int(let value): return Double(value)
    case .string(let value): return Double(value)
    default: return nil
    }
  }

  var boolValue: Bool? {
    switch self {
    case .bool(let value): return value
    case .string(let value): return value.lowercased() == "true" || value == "1"
    case .int(let value): return value != 0
    default: return nil
    }
  }

  var isNull: Bool {
    if case .null = self { return true }
    return false
  }
}

// MARK: - API Client Protocol

public protocol APIClientProtocol: Sendable {
  func execute<T: Decodable>(_ query: String, params: [SQLValue]?) async throws -> [T]
  func executeRaw(_ query: String, params: [SQLValue]?) async throws -> [[String: Any]]
  func executeUpdate(_ query: String, params: [SQLValue]?) async throws -> Int
}

// MARK: - API Client Implementation

public actor APIClient: APIClientProtocol {
  private let configuration: APIConfiguration
  private let urlSession: URLSession
  private let decoder: JSONDecoder

  public init(configuration: APIConfiguration) {
    self.configuration = configuration
    self.urlSession = URLSession.shared
    self.decoder = JSONDecoder()
    self.decoder.dateDecodingStrategy = .iso8601
  }

  /// Execute a SQL query and decode results to a specific type
  public func execute<T: Decodable>(_ query: String, params: [SQLValue]? = nil) async throws -> [T] {
    let rawResults = try await executeRaw(query, params: params)
    let data = try JSONSerialization.data(withJSONObject: rawResults)
    return try decoder.decode([T].self, from: data)
  }

  /// Execute a SQL query and return raw dictionary results
  public func executeRaw(_ query: String, params: [SQLValue]? = nil) async throws -> [[String: Any]] {
    guard let url = URL(string: configuration.sqlEndpoint) else {
      throw APIError.invalidURL
    }

    // Validate database URL is configured
    guard !configuration.databaseUrl.isEmpty else {
      throw APIError.serverError("Neon database URL is not configured. Please set NEON_DATABASE_URL environment variable or NeonDatabaseUrl in Info.plist.")
    }

    var request = URLRequest(url: url)
    request.httpMethod = "POST"
    request.setValue("application/json", forHTTPHeaderField: "Content-Type")
    // Neon HTTP SQL API authenticates via the connection string, not Bearer token
    request.setValue(configuration.databaseUrl, forHTTPHeaderField: "Neon-Connection-String")

    let requestBody = NeonSQLRequest(query: query, params: params)
    request.httpBody = try JSONEncoder().encode(requestBody)

    let (data, response) = try await urlSession.data(for: request)

    guard let httpResponse = response as? HTTPURLResponse else {
      throw APIError.invalidResponse
    }

    switch httpResponse.statusCode {
    case 200..<300:
      break
    case 401:
      throw APIError.unauthorized
    case 404:
      throw APIError.notFound
    case 400..<500:
      let message = String(data: data, encoding: .utf8)
      throw APIError.httpError(statusCode: httpResponse.statusCode, message: message)
    default:
      let message = String(data: data, encoding: .utf8)
      throw APIError.serverError(message ?? "Unknown error")
    }

    // Parse Neon response format
    // Log raw response for debugging
    let rawResponse = String(data: data, encoding: .utf8) ?? "Unable to decode response"
    apiLogger.debug("Raw response length: \(rawResponse.count, privacy: .public) chars")

    do {
      let neonResponse = try decoder.decode(NeonSQLResponse.self, from: data)
      apiLogger.info("Decoded \(neonResponse.rows.count, privacy: .public) rows with \(neonResponse.fields.count, privacy: .public) fields")
      return mapNeonResponse(neonResponse)
    } catch let decodingError as DecodingError {
      // Get detailed decoding error info
      switch decodingError {
      case .typeMismatch(let type, let context):
        apiLogger.error("Type mismatch: expected \(String(describing: type), privacy: .public) at \(context.codingPath.map { $0.stringValue }.joined(separator: "."), privacy: .public)")
      case .valueNotFound(let type, let context):
        apiLogger.error("Value not found: \(String(describing: type), privacy: .public) at \(context.codingPath.map { $0.stringValue }.joined(separator: "."), privacy: .public)")
      case .keyNotFound(let key, let context):
        apiLogger.error("Key not found: \(key.stringValue, privacy: .public) at \(context.codingPath.map { $0.stringValue }.joined(separator: "."), privacy: .public)")
      case .dataCorrupted(let context):
        apiLogger.error("Data corrupted at \(context.codingPath.map { $0.stringValue }.joined(separator: "."), privacy: .public): \(context.debugDescription, privacy: .public)")
      @unknown default:
        apiLogger.error("Unknown decoding error: \(decodingError.localizedDescription, privacy: .public)")
      }
      apiLogger.error("Raw response (first 1000 chars): \(String(rawResponse.prefix(1000)), privacy: .public)")
      throw APIError.decodingError(decodingError)
    } catch {
      apiLogger.error("Unexpected error: \(error.localizedDescription, privacy: .public)")
      throw APIError.decodingError(error)
    }
  }

  /// Execute an UPDATE/INSERT/DELETE and return affected row count
  public func executeUpdate(_ query: String, params: [SQLValue]? = nil) async throws -> Int {
    let results = try await executeRaw(query, params: params)
    // For UPDATE/INSERT/DELETE, Neon returns the affected rows
    return results.count
  }

  /// Map Neon response to array of dictionaries
  private func mapNeonResponse(_ response: NeonSQLResponse) -> [[String: Any]] {
    response.rows.map { row in
      var dict: [String: Any] = [:]
      for (fieldName, value) in row.values {
        dict[fieldName] = neonValueToAny(value)
      }
      return dict
    }
  }

  /// Convert NeonValue to Any
  private func neonValueToAny(_ value: NeonValue) -> Any {
    switch value {
    case .string(let v): return v
    case .int(let v): return v
    case .double(let v): return v
    case .bool(let v): return v
    case .null: return NSNull()
    case .array(let v): return v.map { neonValueToAny($0) }
    }
  }
}

// MARK: - Mock API Client for Testing/Preview

public actor MockAPIClient: APIClientProtocol {
  private var mockResponses: [String: Any] = [:]

  public init() {}

  public func setMockResponse<T: Encodable>(_ response: T, for query: String) {
    mockResponses[query] = response
  }

  public func execute<T: Decodable>(_ query: String, params: [SQLValue]?) async throws -> [T] {
    if let response = mockResponses[query] as? [T] {
      return response
    }
    return []
  }

  public func executeRaw(_ query: String, params: [SQLValue]?) async throws -> [[String: Any]] {
    return []
  }

  public func executeUpdate(_ query: String, params: [SQLValue]?) async throws -> Int {
    return 0
  }
}
