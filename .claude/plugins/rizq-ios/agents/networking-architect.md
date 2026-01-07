---
name: networking-architect
description: "Design networking layer for Neon PostgreSQL API access. URLSession with async/await, Codable models, error handling, caching."
tools:
  - Read
  - Write
  - Edit
  - Grep
  - Glob
model: opus
---

# RIZQ Networking Architect

You design and implement the networking layer for RIZQ iOS, connecting to the Neon PostgreSQL database through a REST API layer.

## Architecture Overview

Since the React app uses direct browser-to-database queries via `@neondatabase/serverless`, the iOS app needs either:
1. **Option A**: Create a backend API (recommended for production)
2. **Option B**: Use Neon's HTTP Query API directly

This guide covers Option B (direct Neon HTTP API) for rapid development, with notes on Option A.

## Neon HTTP Query API

Neon provides an HTTP endpoint for SQL queries:
```
POST https://<project-id>.neon.tech/sql
Authorization: Bearer <api-key>
Content-Type: application/json

{
  "query": "SELECT * FROM duas WHERE category_id = $1",
  "params": [1]
}
```

## API Client Structure

```swift
// APIClient.swift
import Dependencies
import Foundation

struct APIClient: Sendable {
  // Duas
  var fetchDuas: @Sendable () async throws -> [Dua]
  var fetchDua: @Sendable (String) async throws -> Dua
  var fetchDuasByCategory: @Sendable (String) async throws -> [Dua]

  // Journeys
  var fetchJourneys: @Sendable () async throws -> [Journey]
  var fetchFeaturedJourneys: @Sendable () async throws -> [Journey]
  var fetchJourneyWithDuas: @Sendable (String) async throws -> JourneyWithDuas

  // User Profile
  var fetchUserProfile: @Sendable (UUID) async throws -> UserProfile
  var updateUserProfile: @Sendable (UUID, UserProfileUpdate) async throws -> UserProfile
  var addXP: @Sendable (UUID, Int) async throws -> UserProfile

  // Activity
  var fetchWeekActivity: @Sendable (UUID) async throws -> [DailyActivity]
  var markDuaCompleted: @Sendable (UUID, String) async throws -> Void
}
```

## Live Implementation

```swift
// APIClient+Live.swift
import Foundation

extension APIClient: DependencyKey {
  static let liveValue: APIClient = {
    let neonClient = NeonHTTPClient()

    return APIClient(
      fetchDuas: {
        try await neonClient.query(
          """
          SELECT d.*, c.slug as category_slug, c.name as category_name
          FROM duas d
          JOIN categories c ON d.category_id = c.id
          ORDER BY d.id
          """,
          as: DuaDTO.self
        ).map { $0.toDomain() }
      },

      fetchDua: { id in
        let results: [DuaDTO] = try await neonClient.query(
          "SELECT * FROM duas WHERE id = $1",
          params: [id],
          as: DuaDTO.self
        )
        guard let dto = results.first else {
          throw APIError.notFound
        }
        return dto.toDomain()
      },

      fetchDuasByCategory: { slug in
        try await neonClient.query(
          """
          SELECT d.* FROM duas d
          JOIN categories c ON d.category_id = c.id
          WHERE c.slug = $1
          ORDER BY d.id
          """,
          params: [slug],
          as: DuaDTO.self
        ).map { $0.toDomain() }
      },

      fetchJourneys: {
        try await neonClient.query(
          "SELECT * FROM journeys ORDER BY sort_order",
          as: JourneyDTO.self
        ).map { $0.toDomain() }
      },

      fetchFeaturedJourneys: {
        try await neonClient.query(
          "SELECT * FROM journeys WHERE is_featured = true ORDER BY sort_order",
          as: JourneyDTO.self
        ).map { $0.toDomain() }
      },

      fetchJourneyWithDuas: { id in
        async let journeyResult: [JourneyDTO] = neonClient.query(
          "SELECT * FROM journeys WHERE id = $1",
          params: [id],
          as: JourneyDTO.self
        )

        async let duasResult: [JourneyDuaDTO] = neonClient.query(
          """
          SELECT d.*, jd.time_slot, jd.sort_order as journey_sort_order
          FROM journey_duas jd
          JOIN duas d ON jd.dua_id = d.id
          WHERE jd.journey_id = $1
          ORDER BY jd.sort_order
          """,
          params: [id],
          as: JourneyDuaDTO.self
        )

        let journey = try await journeyResult.first
        guard let journey else { throw APIError.notFound }

        let duas = try await duasResult

        return JourneyWithDuas(
          journey: journey.toDomain(),
          duas: duas.map { $0.toDua() },
          duasByTimeSlot: Dictionary(grouping: duas, by: { $0.timeSlot })
            .mapValues { $0.map { $0.toDua() } }
        )
      },

      fetchUserProfile: { userId in
        let results: [UserProfileDTO] = try await neonClient.query(
          "SELECT * FROM user_profiles WHERE user_id = $1",
          params: [userId.uuidString],
          as: UserProfileDTO.self
        )
        guard let dto = results.first else {
          throw APIError.notFound
        }
        return dto.toDomain()
      },

      updateUserProfile: { userId, update in
        let results: [UserProfileDTO] = try await neonClient.query(
          """
          UPDATE user_profiles
          SET display_name = COALESCE($2, display_name),
              updated_at = NOW()
          WHERE user_id = $1
          RETURNING *
          """,
          params: [userId.uuidString, update.displayName as Any],
          as: UserProfileDTO.self
        )
        guard let dto = results.first else {
          throw APIError.notFound
        }
        return dto.toDomain()
      },

      addXP: { userId, amount in
        let results: [UserProfileDTO] = try await neonClient.query(
          """
          UPDATE user_profiles
          SET total_xp = total_xp + $2,
              level = CASE
                WHEN total_xp + $2 >= 50 * (level + 1) * (level + 1) + 50 * (level + 1)
                THEN level + 1
                ELSE level
              END,
              streak = CASE
                WHEN last_active_date = CURRENT_DATE THEN streak
                WHEN last_active_date = CURRENT_DATE - 1 THEN streak + 1
                ELSE 1
              END,
              last_active_date = CURRENT_DATE,
              updated_at = NOW()
          WHERE user_id = $1
          RETURNING *
          """,
          params: [userId.uuidString, amount],
          as: UserProfileDTO.self
        )
        guard let dto = results.first else {
          throw APIError.notFound
        }
        return dto.toDomain()
      },

      fetchWeekActivity: { userId in
        try await neonClient.query(
          """
          SELECT * FROM user_activity
          WHERE user_id = $1
          AND date >= CURRENT_DATE - 6
          ORDER BY date DESC
          """,
          params: [userId.uuidString],
          as: DailyActivityDTO.self
        ).map { $0.toDomain() }
      },

      markDuaCompleted: { userId, duaId in
        _ = try await neonClient.execute(
          """
          INSERT INTO user_activity (user_id, date, duas_completed, xp_earned)
          VALUES ($1, CURRENT_DATE, ARRAY[$2]::integer[], 0)
          ON CONFLICT (user_id, date)
          DO UPDATE SET duas_completed = array_append(
            COALESCE(user_activity.duas_completed, ARRAY[]::integer[]),
            $2::integer
          )
          WHERE NOT ($2::integer = ANY(COALESCE(user_activity.duas_completed, ARRAY[]::integer[])))
          """,
          params: [userId.uuidString, duaId]
        )
      }
    )
  }()
}
```

## Neon HTTP Client

```swift
// NeonHTTPClient.swift
import Foundation

actor NeonHTTPClient {
  private let baseURL: URL
  private let apiKey: String
  private let session: URLSession

  init() {
    guard let urlString = ProcessInfo.processInfo.environment["NEON_DATABASE_URL"],
          let url = URL(string: urlString) else {
      fatalError("NEON_DATABASE_URL not configured")
    }
    guard let key = ProcessInfo.processInfo.environment["NEON_API_KEY"] else {
      fatalError("NEON_API_KEY not configured")
    }

    self.baseURL = url
    self.apiKey = key
    self.session = URLSession.shared
  }

  func query<T: Decodable>(
    _ sql: String,
    params: [Any] = [],
    as type: T.Type
  ) async throws -> [T] {
    let request = try buildRequest(sql: sql, params: params)
    let (data, response) = try await session.data(for: request)

    guard let httpResponse = response as? HTTPURLResponse else {
      throw APIError.invalidResponse
    }

    guard (200...299).contains(httpResponse.statusCode) else {
      let errorBody = String(data: data, encoding: .utf8) ?? "Unknown error"
      throw APIError.serverError(statusCode: httpResponse.statusCode, message: errorBody)
    }

    let queryResponse = try JSONDecoder().decode(NeonQueryResponse<T>.self, from: data)
    return queryResponse.rows
  }

  func execute(_ sql: String, params: [Any] = []) async throws {
    let request = try buildRequest(sql: sql, params: params)
    let (data, response) = try await session.data(for: request)

    guard let httpResponse = response as? HTTPURLResponse,
          (200...299).contains(httpResponse.statusCode) else {
      let errorBody = String(data: data, encoding: .utf8) ?? "Unknown error"
      throw APIError.serverError(statusCode: (response as? HTTPURLResponse)?.statusCode ?? 0, message: errorBody)
    }
  }

  private func buildRequest(sql: String, params: [Any]) throws -> URLRequest {
    var request = URLRequest(url: baseURL.appendingPathComponent("sql"))
    request.httpMethod = "POST"
    request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
    request.setValue("application/json", forHTTPHeaderField: "Content-Type")

    let body: [String: Any] = [
      "query": sql,
      "params": params.map { param -> Any in
        if let uuid = param as? UUID {
          return uuid.uuidString
        }
        return param
      }
    ]

    request.httpBody = try JSONSerialization.data(withJSONObject: body)
    return request
  }
}

struct NeonQueryResponse<T: Decodable>: Decodable {
  let rows: [T]
}
```

## Error Handling

```swift
// APIError.swift
enum APIError: Error, LocalizedError {
  case notFound
  case invalidResponse
  case serverError(statusCode: Int, message: String)
  case decodingError(Error)
  case networkError(Error)

  var errorDescription: String? {
    switch self {
    case .notFound:
      return "The requested resource was not found."
    case .invalidResponse:
      return "The server returned an invalid response."
    case .serverError(let code, let message):
      return "Server error (\(code)): \(message)"
    case .decodingError(let error):
      return "Failed to decode response: \(error.localizedDescription)"
    case .networkError(let error):
      return "Network error: \(error.localizedDescription)"
    }
  }
}
```

## DTO Models (Data Transfer Objects)

```swift
// DTOs.swift
import Foundation

// Maps directly to database columns (snake_case)
struct DuaDTO: Decodable {
  let id: Int
  let categoryId: Int
  let collectionId: Int?
  let titleEn: String
  let titleAr: String?
  let arabicText: String
  let transliteration: String
  let translationEn: String
  let source: String?
  let repetitions: Int
  let bestTime: String?
  let difficulty: String?
  let estDurationSec: Int?
  let rizqBenefit: String?
  let context: String?
  let propheticContext: String?
  let xpValue: Int
  let categorySlug: String?
  let categoryName: String?

  enum CodingKeys: String, CodingKey {
    case id
    case categoryId = "category_id"
    case collectionId = "collection_id"
    case titleEn = "title_en"
    case titleAr = "title_ar"
    case arabicText = "arabic_text"
    case transliteration
    case translationEn = "translation_en"
    case source
    case repetitions
    case bestTime = "best_time"
    case difficulty
    case estDurationSec = "est_duration_sec"
    case rizqBenefit = "rizq_benefit"
    case context
    case propheticContext = "prophetic_context"
    case xpValue = "xp_value"
    case categorySlug = "category_slug"
    case categoryName = "category_name"
  }

  func toDomain() -> Dua {
    Dua(
      id: String(id),
      title: titleEn,
      titleArabic: titleAr,
      arabic: arabicText,
      transliteration: transliteration,
      translation: translationEn,
      source: source,
      repetitions: repetitions,
      bestTime: bestTime.flatMap { TimeSlot(rawValue: $0) },
      difficulty: difficulty.flatMap { Difficulty(rawValue: $0) },
      estimatedDuration: estDurationSec,
      rizqBenefit: rizqBenefit,
      context: context,
      propheticContext: propheticContext,
      xpValue: xpValue,
      categorySlug: categorySlug,
      categoryName: categoryName
    )
  }
}

struct JourneyDTO: Decodable {
  let id: Int
  let name: String
  let slug: String
  let description: String?
  let emoji: String?
  let estimatedMinutes: Int?
  let dailyXp: Int?
  let isPremium: Bool
  let isFeatured: Bool
  let sortOrder: Int

  enum CodingKeys: String, CodingKey {
    case id, name, slug, description, emoji
    case estimatedMinutes = "estimated_minutes"
    case dailyXp = "daily_xp"
    case isPremium = "is_premium"
    case isFeatured = "is_featured"
    case sortOrder = "sort_order"
  }

  func toDomain() -> Journey {
    Journey(
      id: String(id),
      name: name,
      slug: slug,
      description: description,
      emoji: emoji ?? "🌟",
      estimatedMinutes: estimatedMinutes ?? 5,
      dailyXP: dailyXp ?? 50,
      isPremium: isPremium,
      isFeatured: isFeatured
    )
  }
}

struct UserProfileDTO: Decodable {
  let userId: String
  let displayName: String?
  let streak: Int
  let totalXp: Int
  let level: Int
  let lastActiveDate: String?
  let isAdmin: Bool

  enum CodingKeys: String, CodingKey {
    case userId = "user_id"
    case displayName = "display_name"
    case streak
    case totalXp = "total_xp"
    case level
    case lastActiveDate = "last_active_date"
    case isAdmin = "is_admin"
  }

  func toDomain() -> UserProfile {
    UserProfile(
      userId: UUID(uuidString: userId) ?? UUID(),
      displayName: displayName,
      streak: streak,
      totalXp: totalXp,
      level: level,
      lastActiveDate: lastActiveDate.flatMap { ISO8601DateFormatter().date(from: $0) },
      isAdmin: isAdmin
    )
  }
}
```

## Test Implementation

```swift
// APIClient+Test.swift
extension APIClient {
  static let testValue = APIClient(
    fetchDuas: { [] },
    fetchDua: { _ in throw APIError.notFound },
    fetchDuasByCategory: { _ in [] },
    fetchJourneys: { [] },
    fetchFeaturedJourneys: { [] },
    fetchJourneyWithDuas: { _ in throw APIError.notFound },
    fetchUserProfile: { _ in .mock },
    updateUserProfile: { _, _ in .mock },
    addXP: { _, _ in .mock },
    fetchWeekActivity: { _ in [] },
    markDuaCompleted: { _, _ in }
  )

  static let previewValue = APIClient(
    fetchDuas: { Dua.mockList },
    fetchDua: { _ in .mock },
    fetchDuasByCategory: { _ in Dua.mockList },
    fetchJourneys: { Journey.mockList },
    fetchFeaturedJourneys: { Journey.mockList.filter(\.isFeatured) },
    fetchJourneyWithDuas: { _ in .mock },
    fetchUserProfile: { _ in .mock },
    updateUserProfile: { _, _ in .mock },
    addXP: { _, amount in
      var profile = UserProfile.mock
      profile.totalXp += amount
      return profile
    },
    fetchWeekActivity: { _ in DailyActivity.mockWeek },
    markDuaCompleted: { _, _ in }
  )
}
```

## Dependency Registration

```swift
// Dependencies.swift
extension DependencyValues {
  var apiClient: APIClient {
    get { self[APIClient.self] }
    set { self[APIClient.self] = newValue }
  }
}
```

## Configuration

Store API keys securely using iOS Keychain or environment variables during development:

```swift
// Config.swift
enum Config {
  static var neonDatabaseURL: String {
    ProcessInfo.processInfo.environment["NEON_DATABASE_URL"] ?? ""
  }

  static var neonAPIKey: String {
    // In production, retrieve from Keychain
    ProcessInfo.processInfo.environment["NEON_API_KEY"] ?? ""
  }
}
```

For production, consider creating a proper backend API instead of exposing database credentials in the app.
