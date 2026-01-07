---
name: persistence-architect
description: "Design local data storage with SwiftData for structured data, UserDefaults/@AppStorage for preferences, and migration strategies from localStorage."
tools:
  - Read
  - Write
  - Edit
  - Grep
  - Glob
model: opus
---

# RIZQ Persistence Architect

You design and implement local data persistence for RIZQ iOS, mapping the React app's localStorage patterns to native iOS storage solutions.

## Storage Strategy Overview

| React Storage | iOS Storage | Use Case |
|---------------|-------------|----------|
| localStorage (JSON) | SwiftData | Structured data (habits, activity, progress) |
| localStorage (simple) | UserDefaults/@AppStorage | Preferences, flags, small values |
| In-memory (React Query) | TCA State + Effects | Server data caching |

## localStorage Keys → iOS Storage

| localStorage Key | iOS Storage | Model |
|------------------|-------------|-------|
| `rizq_user_habits` | SwiftData | `HabitStorage` |
| `rizq_daily_activity` | SwiftData | `DailyActivityRecord` |
| `rizq_welcome_shown` | @AppStorage | `Bool` |
| `lastUsedProvider` | @AppStorage | `String` |
| User preferences | @AppStorage | Various types |

---

## SwiftData Models

### Habit Storage Model

```swift
// HabitStorage.swift
import Foundation
import SwiftData

@Model
final class HabitStorage {
  @Attribute(.unique) var id: UUID

  // Active journey IDs (maps to activeJourneyIds in React)
  var activeJourneyIds: [Int]

  // Custom habits
  @Relationship(deleteRule: .cascade)
  var customHabits: [CustomHabit]

  // Timestamps
  var createdAt: Date
  var updatedAt: Date

  init(
    id: UUID = UUID(),
    activeJourneyIds: [Int] = [],
    customHabits: [CustomHabit] = [],
    createdAt: Date = Date(),
    updatedAt: Date = Date()
  ) {
    self.id = id
    self.activeJourneyIds = activeJourneyIds
    self.customHabits = customHabits
    self.createdAt = createdAt
    self.updatedAt = updatedAt
  }
}

@Model
final class CustomHabit {
  @Attribute(.unique) var id: UUID
  var duaId: String
  var duaTitle: String
  var timeSlot: String // "morning" | "anytime" | "evening"
  var addedAt: Date

  init(
    id: UUID = UUID(),
    duaId: String,
    duaTitle: String,
    timeSlot: String,
    addedAt: Date = Date()
  ) {
    self.id = id
    self.duaId = duaId
    self.duaTitle = duaTitle
    self.timeSlot = timeSlot
    self.addedAt = addedAt
  }
}
```

### Habit Completion Model

```swift
// HabitCompletionRecord.swift
import Foundation
import SwiftData

@Model
final class HabitCompletionRecord {
  @Attribute(.unique) var id: UUID

  // Composite key: date string (YYYY-MM-DD)
  var dateString: String

  // Completed habit IDs (combines journey dua IDs and custom habit IDs)
  var completedHabitIds: [String]

  // Timestamp
  var lastUpdated: Date

  init(
    id: UUID = UUID(),
    dateString: String,
    completedHabitIds: [String] = [],
    lastUpdated: Date = Date()
  ) {
    self.id = id
    self.dateString = dateString
    self.completedHabitIds = completedHabitIds
    self.lastUpdated = lastUpdated
  }

  // Helper to get Date from dateString
  var date: Date {
    let formatter = DateFormatter()
    formatter.dateFormat = "yyyy-MM-dd"
    return formatter.date(from: dateString) ?? Date()
  }

  // Helper to create dateString from Date
  static func dateKey(from date: Date) -> String {
    let formatter = DateFormatter()
    formatter.dateFormat = "yyyy-MM-dd"
    return formatter.string(from: date)
  }
}
```

### Daily Activity Model

```swift
// DailyActivityRecord.swift
import Foundation
import SwiftData

@Model
final class DailyActivityRecord {
  @Attribute(.unique) var dateString: String

  var duasCompleted: [String]
  var xpEarned: Int
  var practiceMinutes: Int

  init(
    dateString: String,
    duasCompleted: [String] = [],
    xpEarned: Int = 0,
    practiceMinutes: Int = 0
  ) {
    self.dateString = dateString
    self.duasCompleted = duasCompleted
    self.xpEarned = xpEarned
    self.practiceMinutes = practiceMinutes
  }
}
```

---

## SwiftData Container Setup

```swift
// PersistenceContainer.swift
import SwiftData
import Foundation

enum PersistenceContainer {
  static let shared: ModelContainer = {
    let schema = Schema([
      HabitStorage.self,
      CustomHabit.self,
      HabitCompletionRecord.self,
      DailyActivityRecord.self,
    ])

    let modelConfiguration = ModelConfiguration(
      schema: schema,
      isStoredInMemoryOnly: false,
      allowsSave: true
    )

    do {
      return try ModelContainer(for: schema, configurations: [modelConfiguration])
    } catch {
      fatalError("Failed to create SwiftData container: \(error)")
    }
  }()

  // Preview container for SwiftUI previews
  static let preview: ModelContainer = {
    let schema = Schema([
      HabitStorage.self,
      CustomHabit.self,
      HabitCompletionRecord.self,
      DailyActivityRecord.self,
    ])

    let modelConfiguration = ModelConfiguration(
      schema: schema,
      isStoredInMemoryOnly: true
    )

    do {
      let container = try ModelContainer(for: schema, configurations: [modelConfiguration])

      // Add preview data
      Task { @MainActor in
        let context = container.mainContext

        let habitStorage = HabitStorage(activeJourneyIds: [1, 2])
        context.insert(habitStorage)

        let completion = HabitCompletionRecord(
          dateString: HabitCompletionRecord.dateKey(from: Date()),
          completedHabitIds: ["1", "2", "custom-1"]
        )
        context.insert(completion)
      }

      return container
    } catch {
      fatalError("Failed to create preview container: \(error)")
    }
  }()
}
```

---

## Persistence Client (TCA Dependency)

```swift
// PersistenceClient.swift
import Dependencies
import Foundation
import SwiftData

struct PersistenceClient: Sendable {
  // Habits
  var fetchHabitStorage: @Sendable () async throws -> HabitStorageData
  var saveHabitStorage: @Sendable (HabitStorageData) async throws -> Void
  var addCustomHabit: @Sendable (CustomHabitData) async throws -> Void
  var removeCustomHabit: @Sendable (UUID) async throws -> Void
  var addJourney: @Sendable (Int) async throws -> Void
  var removeJourney: @Sendable (Int) async throws -> Void

  // Completions
  var fetchCompletions: @Sendable (Date) async throws -> Set<String>
  var markCompleted: @Sendable (String, Date) async throws -> Void
  var markIncomplete: @Sendable (String, Date) async throws -> Void

  // Activity
  var fetchWeekActivity: @Sendable () async throws -> [DailyActivityData]
  var logActivity: @Sendable (String, Int) async throws -> Void
}

// MARK: - Data Transfer Objects (not SwiftData models)

struct HabitStorageData: Equatable, Sendable {
  var activeJourneyIds: [Int]
  var customHabits: [CustomHabitData]
}

struct CustomHabitData: Equatable, Sendable, Identifiable {
  let id: UUID
  var duaId: String
  var duaTitle: String
  var timeSlot: TimeSlot
  var addedAt: Date
}

struct DailyActivityData: Equatable, Sendable, Identifiable {
  var id: String { dateString }
  let dateString: String
  var duasCompleted: [String]
  var xpEarned: Int
  var practiceMinutes: Int

  var date: Date {
    let formatter = DateFormatter()
    formatter.dateFormat = "yyyy-MM-dd"
    return formatter.date(from: dateString) ?? Date()
  }
}
```

### Live Implementation

```swift
// PersistenceClient+Live.swift
import Dependencies
import Foundation
import SwiftData

extension PersistenceClient: DependencyKey {
  static let liveValue: PersistenceClient = {
    let container = PersistenceContainer.shared

    return PersistenceClient(
      fetchHabitStorage: {
        let context = ModelContext(container)
        let descriptor = FetchDescriptor<HabitStorage>()
        let results = try context.fetch(descriptor)

        if let storage = results.first {
          return HabitStorageData(
            activeJourneyIds: storage.activeJourneyIds,
            customHabits: storage.customHabits.map { habit in
              CustomHabitData(
                id: habit.id,
                duaId: habit.duaId,
                duaTitle: habit.duaTitle,
                timeSlot: TimeSlot(rawValue: habit.timeSlot) ?? .anytime,
                addedAt: habit.addedAt
              )
            }
          )
        }

        // Return empty storage if none exists
        return HabitStorageData(activeJourneyIds: [], customHabits: [])
      },

      saveHabitStorage: { data in
        let context = ModelContext(container)
        let descriptor = FetchDescriptor<HabitStorage>()
        let results = try context.fetch(descriptor)

        let storage: HabitStorage
        if let existing = results.first {
          storage = existing
        } else {
          storage = HabitStorage()
          context.insert(storage)
        }

        storage.activeJourneyIds = data.activeJourneyIds
        storage.updatedAt = Date()

        // Update custom habits
        // (Note: For simplicity, this replaces all - production code should diff)
        for habit in storage.customHabits {
          context.delete(habit)
        }

        for habitData in data.customHabits {
          let habit = CustomHabit(
            id: habitData.id,
            duaId: habitData.duaId,
            duaTitle: habitData.duaTitle,
            timeSlot: habitData.timeSlot.rawValue,
            addedAt: habitData.addedAt
          )
          storage.customHabits.append(habit)
        }

        try context.save()
      },

      addCustomHabit: { habitData in
        let context = ModelContext(container)
        let descriptor = FetchDescriptor<HabitStorage>()
        let results = try context.fetch(descriptor)

        let storage: HabitStorage
        if let existing = results.first {
          storage = existing
        } else {
          storage = HabitStorage()
          context.insert(storage)
        }

        let habit = CustomHabit(
          id: habitData.id,
          duaId: habitData.duaId,
          duaTitle: habitData.duaTitle,
          timeSlot: habitData.timeSlot.rawValue,
          addedAt: habitData.addedAt
        )

        storage.customHabits.append(habit)
        storage.updatedAt = Date()

        try context.save()
      },

      removeCustomHabit: { habitId in
        let context = ModelContext(container)
        let descriptor = FetchDescriptor<HabitStorage>()
        let results = try context.fetch(descriptor)

        guard let storage = results.first else { return }

        storage.customHabits.removeAll { $0.id == habitId }
        storage.updatedAt = Date()

        try context.save()
      },

      addJourney: { journeyId in
        let context = ModelContext(container)
        let descriptor = FetchDescriptor<HabitStorage>()
        let results = try context.fetch(descriptor)

        let storage: HabitStorage
        if let existing = results.first {
          storage = existing
        } else {
          storage = HabitStorage()
          context.insert(storage)
        }

        if !storage.activeJourneyIds.contains(journeyId) {
          storage.activeJourneyIds.append(journeyId)
          storage.updatedAt = Date()
        }

        try context.save()
      },

      removeJourney: { journeyId in
        let context = ModelContext(container)
        let descriptor = FetchDescriptor<HabitStorage>()
        let results = try context.fetch(descriptor)

        guard let storage = results.first else { return }

        storage.activeJourneyIds.removeAll { $0 == journeyId }
        storage.updatedAt = Date()

        try context.save()
      },

      fetchCompletions: { date in
        let context = ModelContext(container)
        let dateKey = HabitCompletionRecord.dateKey(from: date)

        var descriptor = FetchDescriptor<HabitCompletionRecord>(
          predicate: #Predicate { $0.dateString == dateKey }
        )
        descriptor.fetchLimit = 1

        let results = try context.fetch(descriptor)
        return Set(results.first?.completedHabitIds ?? [])
      },

      markCompleted: { habitId, date in
        let context = ModelContext(container)
        let dateKey = HabitCompletionRecord.dateKey(from: date)

        var descriptor = FetchDescriptor<HabitCompletionRecord>(
          predicate: #Predicate { $0.dateString == dateKey }
        )
        descriptor.fetchLimit = 1

        let results = try context.fetch(descriptor)

        let record: HabitCompletionRecord
        if let existing = results.first {
          record = existing
        } else {
          record = HabitCompletionRecord(dateString: dateKey)
          context.insert(record)
        }

        if !record.completedHabitIds.contains(habitId) {
          record.completedHabitIds.append(habitId)
          record.lastUpdated = Date()
        }

        try context.save()
      },

      markIncomplete: { habitId, date in
        let context = ModelContext(container)
        let dateKey = HabitCompletionRecord.dateKey(from: date)

        var descriptor = FetchDescriptor<HabitCompletionRecord>(
          predicate: #Predicate { $0.dateString == dateKey }
        )
        descriptor.fetchLimit = 1

        let results = try context.fetch(descriptor)

        guard let record = results.first else { return }

        record.completedHabitIds.removeAll { $0 == habitId }
        record.lastUpdated = Date()

        try context.save()
      },

      fetchWeekActivity: {
        let context = ModelContext(container)
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let weekAgo = calendar.date(byAdding: .day, value: -6, to: today)!

        let weekAgoKey = HabitCompletionRecord.dateKey(from: weekAgo)

        var descriptor = FetchDescriptor<DailyActivityRecord>(
          predicate: #Predicate { $0.dateString >= weekAgoKey },
          sortBy: [SortDescriptor(\.dateString, order: .reverse)]
        )
        descriptor.fetchLimit = 7

        let results = try context.fetch(descriptor)

        return results.map { record in
          DailyActivityData(
            dateString: record.dateString,
            duasCompleted: record.duasCompleted,
            xpEarned: record.xpEarned,
            practiceMinutes: record.practiceMinutes
          )
        }
      },

      logActivity: { duaId, xpEarned in
        let context = ModelContext(container)
        let dateKey = HabitCompletionRecord.dateKey(from: Date())

        var descriptor = FetchDescriptor<DailyActivityRecord>(
          predicate: #Predicate { $0.dateString == dateKey }
        )
        descriptor.fetchLimit = 1

        let results = try context.fetch(descriptor)

        let record: DailyActivityRecord
        if let existing = results.first {
          record = existing
        } else {
          record = DailyActivityRecord(dateString: dateKey)
          context.insert(record)
        }

        if !record.duasCompleted.contains(duaId) {
          record.duasCompleted.append(duaId)
        }
        record.xpEarned += xpEarned

        try context.save()
      }
    )
  }()
}

// MARK: - Dependency Registration

extension DependencyValues {
  var persistenceClient: PersistenceClient {
    get { self[PersistenceClient.self] }
    set { self[PersistenceClient.self] = newValue }
  }
}
```

### Test Implementation

```swift
// PersistenceClient+Test.swift
extension PersistenceClient {
  static let testValue = PersistenceClient(
    fetchHabitStorage: { HabitStorageData(activeJourneyIds: [], customHabits: []) },
    saveHabitStorage: { _ in },
    addCustomHabit: { _ in },
    removeCustomHabit: { _ in },
    addJourney: { _ in },
    removeJourney: { _ in },
    fetchCompletions: { _ in Set() },
    markCompleted: { _, _ in },
    markIncomplete: { _, _ in },
    fetchWeekActivity: { [] },
    logActivity: { _, _ in }
  )

  static let previewValue = PersistenceClient(
    fetchHabitStorage: {
      HabitStorageData(
        activeJourneyIds: [1, 2],
        customHabits: [
          CustomHabitData(
            id: UUID(),
            duaId: "1",
            duaTitle: "Morning Supplication",
            timeSlot: .morning,
            addedAt: Date()
          )
        ]
      )
    },
    saveHabitStorage: { _ in },
    addCustomHabit: { _ in },
    removeCustomHabit: { _ in },
    addJourney: { _ in },
    removeJourney: { _ in },
    fetchCompletions: { _ in Set(["1", "2"]) },
    markCompleted: { _, _ in },
    markIncomplete: { _, _ in },
    fetchWeekActivity: {
      (0..<7).map { dayOffset in
        let date = Calendar.current.date(byAdding: .day, value: -dayOffset, to: Date())!
        return DailyActivityData(
          dateString: HabitCompletionRecord.dateKey(from: date),
          duasCompleted: Array(repeating: "dua", count: Int.random(in: 0...5)),
          xpEarned: Int.random(in: 0...100),
          practiceMinutes: Int.random(in: 0...30)
        )
      }
    },
    logActivity: { _, _ in }
  )
}
```

---

## @AppStorage for Preferences

```swift
// UserPreferences.swift
import SwiftUI

// MARK: - Keys
enum PreferenceKey: String {
  case welcomeShown = "rizq_welcome_shown"
  case lastUsedProvider = "rizq_last_provider"
  case showTransliteration = "rizq_show_transliteration"
  case showDiacritics = "rizq_show_diacritics"
  case arabicFontSize = "rizq_arabic_font_size"
  case hapticFeedback = "rizq_haptic_feedback"
  case notificationsEnabled = "rizq_notifications_enabled"
  case morningReminderTime = "rizq_morning_reminder"
  case eveningReminderTime = "rizq_evening_reminder"
}

// MARK: - AppStorage Property Wrapper Usage
struct SettingsView: View {
  @AppStorage(PreferenceKey.showTransliteration.rawValue)
  private var showTransliteration = true

  @AppStorage(PreferenceKey.showDiacritics.rawValue)
  private var showDiacritics = true

  @AppStorage(PreferenceKey.arabicFontSize.rawValue)
  private var arabicFontSize = 28.0

  @AppStorage(PreferenceKey.hapticFeedback.rawValue)
  private var hapticFeedback = true

  var body: some View {
    Form {
      Section("Display") {
        Toggle("Show Transliteration", isOn: $showTransliteration)
        Toggle("Show Diacritics (Tashkeel)", isOn: $showDiacritics)

        VStack(alignment: .leading) {
          Text("Arabic Font Size: \(Int(arabicFontSize))")
          Slider(value: $arabicFontSize, in: 20...40, step: 2)
        }
      }

      Section("Feedback") {
        Toggle("Haptic Feedback", isOn: $hapticFeedback)
      }
    }
  }
}
```

### Preferences Client (for TCA)

```swift
// PreferencesClient.swift
import Dependencies
import Foundation

struct PreferencesClient: Sendable {
  var getBool: @Sendable (String) -> Bool
  var setBool: @Sendable (String, Bool) -> Void
  var getString: @Sendable (String) -> String?
  var setString: @Sendable (String, String?) -> Void
  var getDouble: @Sendable (String) -> Double
  var setDouble: @Sendable (String, Double) -> Void
}

extension PreferencesClient: DependencyKey {
  static let liveValue = PreferencesClient(
    getBool: { key in
      UserDefaults.standard.bool(forKey: key)
    },
    setBool: { key, value in
      UserDefaults.standard.set(value, forKey: key)
    },
    getString: { key in
      UserDefaults.standard.string(forKey: key)
    },
    setString: { key, value in
      UserDefaults.standard.set(value, forKey: key)
    },
    getDouble: { key in
      UserDefaults.standard.double(forKey: key)
    },
    setDouble: { key, value in
      UserDefaults.standard.set(value, forKey: key)
    }
  )

  static let testValue = PreferencesClient(
    getBool: { _ in false },
    setBool: { _, _ in },
    getString: { _ in nil },
    setString: { _, _ in },
    getDouble: { _ in 0 },
    setDouble: { _, _ in }
  )
}

extension DependencyValues {
  var preferencesClient: PreferencesClient {
    get { self[PreferencesClient.self] }
    set { self[PreferencesClient.self] = newValue }
  }
}
```

---

## Migration from localStorage

When users migrate from web to iOS (shared account), you may need to sync:

```swift
// DataMigrationService.swift
import Foundation

struct DataMigrationService {
  let apiClient: APIClient
  let persistenceClient: PersistenceClient

  /// Syncs server data to local storage for offline access
  func syncFromServer(userId: UUID) async throws {
    // 1. Fetch user's journey subscriptions from server
    // (If the React app stored these server-side)

    // 2. Fetch recent activity
    let weekActivity = try await apiClient.fetchWeekActivity(userId)

    // 3. Store locally for offline access
    for activity in weekActivity {
      // Convert and store in SwiftData
    }
  }

  /// Uploads local changes to server
  func syncToServer(userId: UUID) async throws {
    // 1. Get local completions not yet synced
    // 2. Batch upload to server
    // 3. Mark as synced
  }
}
```

---

## App Setup with SwiftData

```swift
// RIZQApp.swift
import SwiftData
import SwiftUI

@main
struct RIZQApp: App {
  var body: some Scene {
    WindowGroup {
      AppView(
        store: Store(initialState: AppFeature.State()) {
          AppFeature()
        }
      )
    }
    .modelContainer(PersistenceContainer.shared)
  }
}
```

---

## Checklist

When implementing persistence:

- [ ] SwiftData models defined with @Model macro
- [ ] Relationships properly configured with @Relationship
- [ ] Unique constraints on appropriate fields
- [ ] ModelContainer configured in App entry point
- [ ] Preview container with mock data
- [ ] PersistenceClient dependency created
- [ ] Test/preview implementations provided
- [ ] Date keys formatted consistently (yyyy-MM-dd)
- [ ] @AppStorage keys use consistent prefix (rizq_)
- [ ] Migration path from localStorage documented
