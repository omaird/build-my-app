# Phase 1: Database Layer Foundation

> **Objective**: Establish reliable database connectivity and data fetching infrastructure

## Overview

The iOS app has an existing `APIClient.swift` that can communicate with Neon's HTTP SQL API, but it's not being utilized by most features. This phase focuses on:

1. Verifying and fixing the Neon HTTP API connection
2. Building comprehensive query methods
3. Creating type-safe mapping functions
4. Testing the data layer thoroughly

---

## Current State Analysis

### Existing Files
```
RIZQKit/Services/
├── API/
│   ├── APIClient.swift      # HTTP client for Neon - EXISTS
│   ├── NeonService.swift    # Service wrapper - EXISTS
│   └── SampleData.swift     # Mock data - TO BE REPLACED
├── Dependencies.swift       # Service container - EXISTS
```

### APIClient.swift Current Implementation
- Uses URLSession for HTTP requests
- Sends SQL queries to Neon HTTP endpoint
- Has mock implementation for testing
- **Issue**: May not be correctly configured for all query types

---

## Tasks

### Task 1.1: Verify Neon HTTP Connection

**File**: `RIZQKit/Services/API/APIClient.swift`

**Actions**:
1. Verify environment variables are loaded:
   - `NEON_HOST` or `NEON_DATABASE_URL`
   - `NEON_API_KEY` (if using HTTP API)
   - `NEON_PROJECT_ID`

2. Test basic connectivity with simple query:
   ```sql
   SELECT 1 as test
   ```

3. Verify JSON response parsing matches Neon format:
   ```json
   {
     "rows": [...],
     "columns": [...],
     "rowCount": N
   }
   ```

**Verification**:
- Run app in debug mode
- Check console for successful query execution
- Validate response parsing

---

### Task 1.2: Implement Query Builder Methods

**File**: `RIZQKit/Services/API/APIClient.swift`

**Add these methods**:

```swift
// Generic query execution
func execute<T: Decodable>(_ sql: String, params: [Any] = []) async throws -> [T]

// Specialized queries
func fetchDuas() async throws -> [DuaRow]
func fetchDua(id: Int) async throws -> DuaRow?
func fetchDuasByCategory(slug: String) async throws -> [DuaRow]
func fetchJourneys() async throws -> [JourneyRow]
func fetchJourneyWithDuas(id: Int) async throws -> JourneyWithDuasRow?
func fetchJourneyBySlug(_ slug: String) async throws -> JourneyRow?
func fetchCategories() async throws -> [CategoryRow]
func fetchCollections() async throws -> [CollectionRow]
```

**SQL Queries to Implement**:

```sql
-- Fetch all duas with relations
SELECT d.*,
  c.name as category_name, c.slug as category_slug,
  col.name as collection_name, col.slug as collection_slug
FROM duas d
LEFT JOIN categories c ON d.category_id = c.id
LEFT JOIN collections col ON d.collection_id = col.id
ORDER BY d.id;

-- Fetch journey with duas
SELECT jd.dua_id, jd.time_slot, jd.sort_order,
  d.id, d.title_en, d.title_ar, d.arabic_text, d.transliteration,
  d.translation_en, d.source, d.repetitions, d.xp_value,
  d.rizq_benefit, d.prophetic_context, d.difficulty,
  c.slug as category_slug
FROM journey_duas jd
JOIN duas d ON jd.dua_id = d.id
LEFT JOIN categories c ON d.category_id = c.id
WHERE jd.journey_id = $1
ORDER BY jd.sort_order ASC;

-- Fetch categories
SELECT * FROM categories ORDER BY id;

-- Fetch collections
SELECT * FROM collections ORDER BY id;
```

---

### Task 1.3: Create Database Row Types

**File**: `RIZQKit/Models/DatabaseRows.swift` (NEW)

**Purpose**: Intermediate types that match exact database column structure

```swift
// MARK: - Database Row Types (snake_case matching DB)

struct DuaRow: Codable {
    let id: Int
    let category_id: Int?
    let collection_id: Int?
    let title_en: String
    let title_ar: String?
    let arabic_text: String
    let transliteration: String?
    let translation_en: String?
    let source: String?
    let repetitions: Int
    let best_time: String?
    let difficulty: String?
    let est_duration_sec: Int?
    let rizq_benefit: String?
    let context: String?
    let prophetic_context: String?
    let xp_value: Int
    let audio_url: String?
    let created_at: String
    let updated_at: String

    // Joined columns (optional)
    let category_name: String?
    let category_slug: String?
    let collection_name: String?
    let collection_slug: String?
}

struct JourneyRow: Codable {
    let id: Int
    let name: String
    let slug: String
    let description: String?
    let emoji: String
    let estimated_minutes: Int
    let daily_xp: Int
    let is_premium: Bool
    let is_featured: Bool
    let sort_order: Int
    let created_at: String
}

struct JourneyDuaRow: Codable {
    let journey_id: Int
    let dua_id: Int
    let time_slot: String
    let sort_order: Int

    // Joined dua fields
    let title_en: String?
    let title_ar: String?
    let arabic_text: String?
    let transliteration: String?
    let translation_en: String?
    let source: String?
    let repetitions: Int?
    let xp_value: Int?
    let rizq_benefit: String?
    let prophetic_context: String?
    let difficulty: String?
    let category_slug: String?
}

struct CategoryRow: Codable {
    let id: Int
    let name: String
    let slug: String
    let description: String?
}

struct CollectionRow: Codable {
    let id: Int
    let name: String
    let slug: String
    let description: String?
    let is_premium: Bool
}
```

---

### Task 1.4: Create Mapping Functions

**File**: `RIZQKit/Models/DatabaseMappers.swift` (NEW)

**Purpose**: Convert database rows to app model types

```swift
// MARK: - Database to Model Mappers

extension Dua {
    init(from row: DuaRow) {
        self.id = row.id
        self.categoryId = row.category_id
        self.collectionId = row.collection_id
        self.titleEn = row.title_en
        self.titleAr = row.title_ar
        self.arabicText = row.arabic_text
        self.transliteration = row.transliteration
        self.translationEn = row.translation_en ?? ""
        self.source = row.source
        self.repetitions = row.repetitions
        self.bestTime = TimeSlot(rawValue: row.best_time ?? "anytime")
        self.difficulty = DuaDifficulty(rawValue: row.difficulty?.lowercased() ?? "beginner") ?? .beginner
        self.estDurationSec = row.est_duration_sec
        self.rizqBenefit = row.rizq_benefit
        self.context = row.context
        self.propheticContext = row.prophetic_context
        self.xpValue = row.xp_value
        self.audioUrl = row.audio_url
        self.createdAt = ISO8601DateFormatter().date(from: row.created_at) ?? Date()
        self.updatedAt = ISO8601DateFormatter().date(from: row.updated_at) ?? Date()
        self.categorySlug = row.category_slug
    }
}

extension Journey {
    init(from row: JourneyRow) {
        self.id = row.id
        self.name = row.name
        self.slug = row.slug
        self.description = row.description
        self.emoji = row.emoji
        self.estimatedMinutes = row.estimated_minutes
        self.dailyXp = row.daily_xp
        self.isPremium = row.is_premium
        self.isFeatured = row.is_featured
        self.sortOrder = row.sort_order
    }
}

extension JourneyDua {
    init(from row: JourneyDuaRow) {
        self.journeyId = row.journey_id
        self.duaId = row.dua_id
        self.timeSlot = TimeSlot(rawValue: row.time_slot) ?? .anytime
        self.sortOrder = row.sort_order
    }
}
```

---

### Task 1.5: Update NeonService

**File**: `RIZQKit/Services/API/NeonService.swift`

**Purpose**: High-level service that features use

```swift
public actor NeonService {
    private let client: APIClient

    public init(client: APIClient = .live) {
        self.client = client
    }

    // MARK: - Duas

    public func fetchAllDuas() async throws -> [Dua] {
        let rows: [DuaRow] = try await client.execute("""
            SELECT d.*,
              c.name as category_name, c.slug as category_slug,
              col.name as collection_name, col.slug as collection_slug
            FROM duas d
            LEFT JOIN categories c ON d.category_id = c.id
            LEFT JOIN collections col ON d.collection_id = col.id
            ORDER BY d.id
            """)
        return rows.map(Dua.init(from:))
    }

    public func fetchDua(id: Int) async throws -> Dua? {
        let rows: [DuaRow] = try await client.execute("""
            SELECT d.*,
              c.slug as category_slug
            FROM duas d
            LEFT JOIN categories c ON d.category_id = c.id
            WHERE d.id = \(id)
            """)
        return rows.first.map(Dua.init(from:))
    }

    public func fetchDuasByCategory(slug: String) async throws -> [Dua] {
        let rows: [DuaRow] = try await client.execute("""
            SELECT d.*, c.slug as category_slug
            FROM duas d
            JOIN categories c ON d.category_id = c.id
            WHERE c.slug = '\(slug)'
            ORDER BY d.id
            """)
        return rows.map(Dua.init(from:))
    }

    // MARK: - Journeys

    public func fetchAllJourneys() async throws -> [Journey] {
        let rows: [JourneyRow] = try await client.execute("""
            SELECT * FROM journeys
            ORDER BY is_featured DESC, sort_order ASC
            """)
        return rows.map(Journey.init(from:))
    }

    public func fetchJourneyWithDuas(id: Int) async throws -> JourneyWithDuas? {
        // Fetch journey
        let journeyRows: [JourneyRow] = try await client.execute("""
            SELECT * FROM journeys WHERE id = \(id)
            """)
        guard let journeyRow = journeyRows.first else { return nil }
        let journey = Journey(from: journeyRow)

        // Fetch journey duas with full dua data
        let duaRows: [JourneyDuaRow] = try await client.execute("""
            SELECT jd.*, d.title_en, d.title_ar, d.arabic_text,
                   d.transliteration, d.translation_en, d.source,
                   d.repetitions, d.xp_value, d.rizq_benefit,
                   d.prophetic_context, d.difficulty,
                   c.slug as category_slug
            FROM journey_duas jd
            JOIN duas d ON jd.dua_id = d.id
            LEFT JOIN categories c ON d.category_id = c.id
            WHERE jd.journey_id = \(id)
            ORDER BY jd.sort_order ASC
            """)

        let journeyDuas = duaRows.map { row -> JourneyDuaFull in
            let journeyDua = JourneyDua(from: row)
            // Build minimal Dua from joined fields
            let dua = Dua(
                id: row.dua_id,
                titleEn: row.title_en ?? "",
                arabicText: row.arabic_text ?? "",
                transliteration: row.transliteration,
                translationEn: row.translation_en ?? "",
                source: row.source,
                repetitions: row.repetitions ?? 1,
                xpValue: row.xp_value ?? 10,
                rizqBenefit: row.rizq_benefit,
                propheticContext: row.prophetic_context,
                difficulty: DuaDifficulty(rawValue: row.difficulty?.lowercased() ?? "beginner") ?? .beginner,
                categorySlug: row.category_slug
            )
            return JourneyDuaFull(journeyDua: journeyDua, dua: dua)
        }

        return JourneyWithDuas(journey: journey, duas: journeyDuas)
    }

    public func fetchJourneyBySlug(_ slug: String) async throws -> JourneyWithDuas? {
        let rows: [JourneyRow] = try await client.execute("""
            SELECT * FROM journeys WHERE slug = '\(slug)'
            """)
        guard let row = rows.first else { return nil }
        return try await fetchJourneyWithDuas(id: row.id)
    }

    // MARK: - Categories

    public func fetchCategories() async throws -> [DuaCategory] {
        let rows: [CategoryRow] = try await client.execute("""
            SELECT * FROM categories ORDER BY id
            """)
        return rows.compactMap { row in
            CategorySlug(rawValue: row.slug).map { slug in
                DuaCategory(id: row.id, name: row.name, slug: slug, description: row.description)
            }
        }
    }
}
```

---

### Task 1.6: Register Service as TCA Dependency

**File**: `RIZQKit/Services/Dependencies.swift`

**Add**:
```swift
// MARK: - NeonService Dependency

private enum NeonServiceKey: DependencyKey {
    static let liveValue: NeonService = NeonService(client: .live)
    static let previewValue: NeonService = NeonService(client: .mock)
    static let testValue: NeonService = NeonService(client: .mock)
}

extension DependencyValues {
    var neonService: NeonService {
        get { self[NeonServiceKey.self] }
        set { self[NeonServiceKey.self] = newValue }
    }
}
```

---

### Task 1.7: Write Unit Tests

**File**: `RIZQTests/Services/NeonServiceTests.swift` (NEW)

**Test Cases**:
1. `testFetchAllDuas_ReturnsValidData`
2. `testFetchDua_ById_ReturnsCorrectDua`
3. `testFetchJourneys_SortedByFeaturedFirst`
4. `testFetchJourneyWithDuas_IncludesAllDuas`
5. `testDuaRowMapping_MapsAllFields`
6. `testJourneyRowMapping_MapsAllFields`
7. `testTimeSlotParsing_HandlesAllValues`
8. `testDifficultyParsing_DefaultsToBeginner`

---

## Verification Checklist

- [ ] App launches without crashes
- [ ] Debug console shows successful Neon connection
- [ ] `NeonService.fetchAllDuas()` returns 10 duas
- [ ] `NeonService.fetchAllJourneys()` returns 14 journeys
- [ ] `NeonService.fetchJourneyWithDuas(id:)` returns journey with its duas
- [ ] All unit tests pass
- [ ] No hardcoded credentials in code

---

## Files Modified/Created

| File | Action | Description |
|------|--------|-------------|
| `APIClient.swift` | MODIFY | Add query methods, fix response parsing |
| `NeonService.swift` | MODIFY | Add comprehensive fetch methods |
| `DatabaseRows.swift` | CREATE | Intermediate row types matching DB |
| `DatabaseMappers.swift` | CREATE | Row → Model mapping extensions |
| `Dependencies.swift` | MODIFY | Register NeonService dependency |
| `NeonServiceTests.swift` | CREATE | Unit tests for data layer |

---

## Estimated Effort

| Task | Complexity | Estimate |
|------|------------|----------|
| 1.1 Verify Connection | Low | 30 min |
| 1.2 Query Builders | Medium | 1 hour |
| 1.3 Row Types | Low | 45 min |
| 1.4 Mapping Functions | Medium | 1 hour |
| 1.5 NeonService Update | Medium | 1.5 hours |
| 1.6 Dependency Registration | Low | 15 min |
| 1.7 Unit Tests | Medium | 1 hour |
| **Total** | | **~6 hours** |

---

## Dependencies

- **Prerequisites**: None (Phase 1 is foundational)
- **Blockers**: Valid Neon credentials required
- **Enables**: All subsequent phases depend on this

---

## Notes

- Use parameterized queries to prevent SQL injection (currently using string interpolation - needs improvement)
- Consider adding retry logic for network failures
- Cache results in memory for frequently accessed data (categories, collections)
