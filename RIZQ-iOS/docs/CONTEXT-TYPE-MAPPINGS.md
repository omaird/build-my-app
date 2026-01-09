# Type Mappings Reference

This document maps types between the database, React frontend, and iOS app.

---

## ID Types

| Context | Type | Example |
|---------|------|---------|
| Database | INTEGER (SERIAL) | `1`, `2`, `3` |
| React | string | `"1"`, `"2"`, `"3"` |
| iOS | Int | `1`, `2`, `3` |

**Note**: React converts database integers to strings for flexibility. iOS keeps them as Int.

---

## Dua Type Mapping

### Database → iOS

| Database Column | iOS Property | Type |
|-----------------|--------------|------|
| `id` | `id` | Int |
| `category_id` | `categoryId` | Int? |
| `collection_id` | `collectionId` | Int? |
| `title_en` | `titleEn` | String |
| `title_ar` | `titleAr` | String? |
| `arabic_text` | `arabicText` | String |
| `transliteration` | `transliteration` | String? |
| `translation_en` | `translationEn` | String |
| `source` | `source` | String? |
| `repetitions` | `repetitions` | Int |
| `best_time` | `bestTime` | TimeSlot? |
| `difficulty` | `difficulty` | DuaDifficulty |
| `est_duration_sec` | `estDurationSec` | Int? |
| `rizq_benefit` | `rizqBenefit` | String? |
| `context` | `context` | String? |
| `prophetic_context` | `propheticContext` | String? |
| `xp_value` | `xpValue` | Int |
| `audio_url` | `audioUrl` | String? |
| `created_at` | `createdAt` | Date |
| `updated_at` | `updatedAt` | Date |

### React Type

```typescript
interface Dua {
  id: string
  title: string           // maps to title_en
  arabic: string          // maps to arabic_text
  transliteration: string
  translation: string     // maps to translation_en
  category: DuaCategory   // derived from category.slug
  xpValue: number
  repetitions: number
  context: DuaContext
}

interface DuaContext {
  source: string | null
  bestTime: string | null
  benefits: string | null      // maps to rizq_benefit
  story: string | null         // maps to context
  propheticContext: string | null
  difficulty: DuaDifficulty | null
  estimatedDuration: number | null
}
```

### iOS Type

```swift
struct Dua: Codable, Identifiable, Equatable {
    let id: Int
    let categoryId: Int?
    let collectionId: Int?
    let titleEn: String
    let titleAr: String?
    let arabicText: String
    let transliteration: String?
    let translationEn: String
    let source: String?
    let repetitions: Int
    let bestTime: TimeSlot?
    let difficulty: DuaDifficulty
    let estDurationSec: Int?
    let rizqBenefit: String?
    let context: String?
    let propheticContext: String?
    let xpValue: Int
    let audioUrl: String?
    let createdAt: Date
    let updatedAt: Date

    // Derived
    var categorySlug: String?
}
```

---

## Journey Type Mapping

### Database → iOS

| Database Column | iOS Property | Type |
|-----------------|--------------|------|
| `id` | `id` | Int |
| `name` | `name` | String |
| `slug` | `slug` | String |
| `description` | `description` | String? |
| `emoji` | `emoji` | String |
| `estimated_minutes` | `estimatedMinutes` | Int |
| `daily_xp` | `dailyXp` | Int |
| `is_premium` | `isPremium` | Bool |
| `is_featured` | `isFeatured` | Bool |
| `sort_order` | `sortOrder` | Int |
| `created_at` | `createdAt` | Date |

### React Type

```typescript
interface Journey {
  id: number
  name: string
  slug: string
  description: string | null
  emoji: string
  estimatedMinutes: number
  dailyXp: number
  isPremium: boolean
  isFeatured: boolean
}
```

### iOS Type

```swift
struct Journey: Codable, Identifiable, Equatable {
    let id: Int
    let name: String
    let slug: String
    let description: String?
    let emoji: String
    let estimatedMinutes: Int
    let dailyXp: Int
    let isPremium: Bool
    let isFeatured: Bool
    let sortOrder: Int
}
```

---

## User Profile Type Mapping

### Database → iOS

| Database Column | iOS Property | Type |
|-----------------|--------------|------|
| `id` | (internal) | Int |
| `user_id` | `userId` | String (UUID) |
| `display_name` | `displayName` | String? |
| `streak` | `streak` | Int |
| `total_xp` | `totalXp` | Int |
| `level` | `level` | Int |
| `last_active_date` | `lastActiveDate` | Date? |
| `is_admin` | `isAdmin` | Bool |
| `created_at` | `createdAt` | Date |
| `updated_at` | `updatedAt` | Date |

### React Type

```typescript
interface UserProfile {
  userId: string       // UUID
  displayName: string | null
  streak: number
  totalXp: number
  level: number
  lastActiveDate: string | null  // ISO date string
  isAdmin: boolean
}
```

### iOS Type

```swift
struct UserProfile: Codable, Identifiable, Equatable {
    let userId: String
    let displayName: String?
    var streak: Int
    var totalXp: Int
    var level: Int
    var lastActiveDate: Date?
    let isAdmin: Bool
    let createdAt: Date
    var updatedAt: Date

    var id: String { userId }

    // Computed
    var xpForNextLevel: Int { LevelCalculator.xpThreshold(for: level) }
    var levelProgress: Double { /* ... */ }
}
```

---

## Enum Mappings

### TimeSlot

| Database Value | React Value | iOS Value |
|----------------|-------------|-----------|
| `"morning"` | `"morning"` | `.morning` |
| `"anytime"` | `"anytime"` | `.anytime` |
| `"evening"` | `"evening"` | `.evening` |

```swift
enum TimeSlot: String, Codable, CaseIterable {
    case morning
    case anytime
    case evening
}
```

### DuaDifficulty

| Database Value | React Value | iOS Value |
|----------------|-------------|-----------|
| `"Beginner"` | `"beginner"` | `.beginner` |
| `"Intermediate"` | `"intermediate"` | `.intermediate` |
| `"Advanced"` | `"advanced"` | `.advanced` |

```swift
enum DuaDifficulty: String, Codable, CaseIterable {
    case beginner
    case intermediate
    case advanced

    init(from rawValue: String) {
        switch rawValue.lowercased() {
        case "beginner": self = .beginner
        case "intermediate": self = .intermediate
        case "advanced": self = .advanced
        default: self = .beginner
        }
    }
}
```

### CategorySlug

| Database Value | iOS Value |
|----------------|-----------|
| `"morning"` | `.morning` |
| `"evening"` | `.evening` |
| `"rizq"` | `.rizq` |
| `"gratitude"` | `.gratitude` |

```swift
enum CategorySlug: String, Codable, CaseIterable {
    case morning
    case evening
    case rizq
    case gratitude
}
```

---

## Habit Storage Mapping

### React localStorage Schema

```typescript
interface UserHabitsStorage {
  activeJourneyIds: string[]        // String array!
  customHabits: UserHabit[]
  habitCompletions: HabitCompletion[]
  lastUpdated: string               // ISO timestamp
}

interface UserHabit {
  id: string
  duaId: string                     // String!
  timeSlot: TimeSlot
  sortOrder: number
  addedAt: string
  source: "journey" | "custom"
}

interface HabitCompletion {
  date: string                      // YYYY-MM-DD
  completedDuaIds: string[]         // String array!
}
```

### iOS UserDefaults Schema

```swift
struct UserHabitsData: Codable {
    var activeJourneyIds: [Int]     // Int array!
    var customHabits: [CustomHabit]
    var habitCompletions: [HabitCompletion]
    var lastUpdated: Date
}

struct CustomHabit: Codable {
    let id: String
    let duaId: Int                  // Int!
    let timeSlot: TimeSlot
    let sortOrder: Int
    let addedAt: Date
}

struct HabitCompletion: Codable {
    let date: String                // YYYY-MM-DD
    var completedDuaIds: [Int]      // Int array!
}
```

**Key Difference**: React stores IDs as strings, iOS stores as Int.

---

## Date/Time Formatting

| Context | Format | Example |
|---------|--------|---------|
| Database (timestamp) | ISO 8601 with timezone | `2026-01-08T14:30:00+00:00` |
| Database (date) | YYYY-MM-DD | `2026-01-08` |
| React | ISO string or YYYY-MM-DD | `"2026-01-08"` |
| iOS | Date object | `Date()` |

### Conversion Functions (iOS)

```swift
extension Date {
    var yyyyMMdd: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: self)
    }

    init?(yyyyMMdd string: String) {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        guard let date = formatter.date(from: string) else { return nil }
        self = date
    }
}

extension String {
    var iso8601Date: Date? {
        ISO8601DateFormatter().date(from: self)
    }
}
```

---

## API Response Mapping

### Neon HTTP API Response Format

```json
{
  "rows": [
    {
      "id": 1,
      "title_en": "Ayatul Kursi",
      "arabic_text": "اللَّهُ لَا إِلَٰهَ إِلَّا هُوَ...",
      ...
    }
  ],
  "columns": [
    {"name": "id", "dataTypeID": 23},
    {"name": "title_en", "dataTypeID": 1043},
    ...
  ],
  "rowCount": 1
}
```

### iOS Parsing

```swift
struct NeonResponse<T: Codable>: Codable {
    let rows: [T]
    let columns: [NeonColumn]?
    let rowCount: Int?
}

struct NeonColumn: Codable {
    let name: String
    let dataTypeID: Int
}

// Usage
let response: NeonResponse<DuaRow> = try JSONDecoder().decode(...)
let duas = response.rows.map(Dua.init(from:))
```

---

## Cross-Platform Considerations

1. **ID Consistency**: When iOS and web need to share data (e.g., user switches devices), ensure ID types are handled correctly at the API boundary.

2. **Date Parsing**: Always handle timezone-aware timestamps from the database. Store dates as UTC.

3. **Optional Handling**: React uses `null`, iOS uses `nil`. Both mean "no value" but handle differently in JSON.

4. **Enum Case Sensitivity**: Database stores title-case ("Beginner"), code uses lowercase. Always normalize in parsing.

5. **Array Types**: PostgreSQL arrays serialize as JSON arrays. iOS `Codable` handles this automatically.
