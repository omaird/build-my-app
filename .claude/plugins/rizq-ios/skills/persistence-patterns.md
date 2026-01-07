---
name: persistence-patterns
description: "SwiftData models, @AppStorage patterns, UserDefaults wrappers, and migration strategies for iOS persistence"
---

# Persistence Patterns for iOS

This skill provides patterns for local data persistence in the RIZQ iOS app, mapping React localStorage patterns to native iOS storage.

---

## Storage Strategy Overview

| Data Type | React Web | iOS | Notes |
|-----------|-----------|-----|-------|
| User preferences | localStorage | @AppStorage / UserDefaults | Small key-value data |
| Habit completions | localStorage | SwiftData | Structured, queryable |
| User profile | PostgreSQL + localStorage | SwiftData + Sync | Offline-first |
| Auth tokens | localStorage | Keychain | Secure storage |
| Cache | Memory | URLCache / SwiftData | Temporary data |
| App state | React Context | @Observable + SwiftData | Session state |

---

## @AppStorage Patterns

### Basic Usage

```swift
import SwiftUI

// MARK: - @AppStorage in Views
struct SettingsView: View {
  // Simple types
  @AppStorage("notifications_enabled") private var notificationsEnabled = true
  @AppStorage("haptics_enabled") private var hapticsEnabled = true
  @AppStorage("theme_mode") private var themeMode = "system"
  @AppStorage("daily_reminder_time") private var reminderTime = "06:00"

  // With App Group (for widgets)
  @AppStorage("streak", store: UserDefaults(suiteName: "group.com.rizq.app"))
  private var streak = 0

  var body: some View {
    Form {
      Toggle("Notifications", isOn: $notificationsEnabled)
      Toggle("Haptics", isOn: $hapticsEnabled)

      Picker("Theme", selection: $themeMode) {
        Text("System").tag("system")
        Text("Light").tag("light")
        Text("Dark").tag("dark")
      }
    }
  }
}
```

### Custom Types with RawRepresentable

```swift
// MARK: - Time Slot Storage
enum TimeSlot: String, CaseIterable, Codable {
  case morning
  case anytime
  case evening
}

// @AppStorage works with RawRepresentable
struct HabitSettingsView: View {
  @AppStorage("default_time_slot") private var defaultTimeSlot = TimeSlot.morning

  var body: some View {
    Picker("Default Time", selection: $defaultTimeSlot) {
      ForEach(TimeSlot.allCases, id: \.self) { slot in
        Text(slot.rawValue.capitalized).tag(slot)
      }
    }
  }
}
```

### Codable Types via RawRepresentable

```swift
// MARK: - Codable AppStorage Wrapper
struct CodableAppStorage<T: Codable>: RawRepresentable {
  var rawValue: String
  var value: T

  init?(rawValue: String) {
    guard let data = rawValue.data(using: .utf8),
          let decoded = try? JSONDecoder().decode(T.self, from: data) else {
      return nil
    }
    self.rawValue = rawValue
    self.value = decoded
  }

  init(_ value: T) {
    self.value = value
    let data = (try? JSONEncoder().encode(value)) ?? Data()
    self.rawValue = String(data: data, encoding: .utf8) ?? ""
  }
}

// MARK: - Usage with Complex Types
struct UserPreferences: Codable, Equatable {
  var notificationsEnabled: Bool = true
  var hapticsEnabled: Bool = true
  var dailyGoal: Int = 5
  var preferredTimeSlots: [TimeSlot] = [.morning, .evening]
}

struct PreferencesView: View {
  @AppStorage("user_preferences")
  private var preferencesData = CodableAppStorage(UserPreferences())

  var body: some View {
    Form {
      Toggle("Notifications", isOn: Binding(
        get: { preferencesData.value.notificationsEnabled },
        set: { preferencesData.value.notificationsEnabled = $0 }
      ))

      Stepper("Daily Goal: \(preferencesData.value.dailyGoal)",
              value: Binding(
                get: { preferencesData.value.dailyGoal },
                set: { preferencesData.value.dailyGoal = $0 }
              ),
              in: 1...20)
    }
  }
}
```

---

## UserDefaults Wrapper

### Type-Safe UserDefaults Keys

```swift
// MARK: - UserDefaults Keys
enum UserDefaultsKey: String {
  // Onboarding
  case hasCompletedOnboarding = "has_completed_onboarding"
  case welcomeShown = "rizq_welcome_shown"

  // User State
  case lastActiveDate = "last_active_date"
  case currentStreak = "current_streak"
  case totalXP = "total_xp"
  case currentLevel = "current_level"

  // Preferences
  case notificationsEnabled = "notifications_enabled"
  case hapticsEnabled = "haptics_enabled"
  case themeMode = "theme_mode"

  // Auth
  case lastUsedProvider = "last_used_provider"
  case userId = "user_id"

  // Cache
  case lastSyncTimestamp = "last_sync_timestamp"
  case cachedJourneyIds = "cached_journey_ids"
}

// MARK: - UserDefaults Manager
@propertyWrapper
struct UserDefault<T> {
  let key: UserDefaultsKey
  let defaultValue: T
  let store: UserDefaults

  init(_ key: UserDefaultsKey, defaultValue: T, store: UserDefaults = .standard) {
    self.key = key
    self.defaultValue = defaultValue
    self.store = store
  }

  var wrappedValue: T {
    get {
      store.object(forKey: key.rawValue) as? T ?? defaultValue
    }
    set {
      store.set(newValue, forKey: key.rawValue)
    }
  }
}

// MARK: - Codable UserDefault
@propertyWrapper
struct CodableUserDefault<T: Codable> {
  let key: UserDefaultsKey
  let defaultValue: T
  let store: UserDefaults

  init(_ key: UserDefaultsKey, defaultValue: T, store: UserDefaults = .standard) {
    self.key = key
    self.defaultValue = defaultValue
    self.store = store
  }

  var wrappedValue: T {
    get {
      guard let data = store.data(forKey: key.rawValue),
            let value = try? JSONDecoder().decode(T.self, from: data) else {
        return defaultValue
      }
      return value
    }
    set {
      if let data = try? JSONEncoder().encode(newValue) {
        store.set(data, forKey: key.rawValue)
      }
    }
  }
}
```

### App Settings Manager

```swift
// MARK: - App Settings
@Observable
final class AppSettings {
  static let shared = AppSettings()

  // Onboarding
  @UserDefault(.hasCompletedOnboarding, defaultValue: false)
  var hasCompletedOnboarding: Bool

  @UserDefault(.welcomeShown, defaultValue: false)
  var welcomeShown: Bool

  // User State
  @UserDefault(.currentStreak, defaultValue: 0)
  var currentStreak: Int

  @UserDefault(.totalXP, defaultValue: 0)
  var totalXP: Int

  @UserDefault(.currentLevel, defaultValue: 1)
  var currentLevel: Int

  // Preferences
  @UserDefault(.notificationsEnabled, defaultValue: true)
  var notificationsEnabled: Bool

  @UserDefault(.hapticsEnabled, defaultValue: true)
  var hapticsEnabled: Bool

  @UserDefault(.themeMode, defaultValue: "system")
  var themeMode: String

  // Computed
  var colorScheme: ColorScheme? {
    switch themeMode {
    case "light": return .light
    case "dark": return .dark
    default: return nil
    }
  }

  // Methods
  func resetAll() {
    let domain = Bundle.main.bundleIdentifier!
    UserDefaults.standard.removePersistentDomain(forName: domain)
  }
}
```

---

## SwiftData Models

### Core Models

```swift
import SwiftData

// MARK: - Dua Model
@Model
final class DuaModel {
  @Attribute(.unique) var id: Int
  var categoryId: Int
  var collectionId: Int?
  var titleEn: String
  var arabicText: String
  var transliteration: String
  var translationEn: String
  var source: String?
  var repetitions: Int
  var bestTime: String?
  var difficulty: String?
  var rizqBenefit: String?
  var context: String?
  var propheticContext: String?
  var xpValue: Int
  var createdAt: Date?
  var updatedAt: Date?

  // Relationships
  @Relationship(deleteRule: .cascade, inverse: \UserDuaProgress.dua)
  var progressRecords: [UserDuaProgress]?

  @Relationship(inverse: \JourneyDuaModel.dua)
  var journeyDuas: [JourneyDuaModel]?

  init(
    id: Int,
    categoryId: Int,
    titleEn: String,
    arabicText: String,
    transliteration: String,
    translationEn: String,
    repetitions: Int = 1,
    xpValue: Int = 10
  ) {
    self.id = id
    self.categoryId = categoryId
    self.titleEn = titleEn
    self.arabicText = arabicText
    self.transliteration = transliteration
    self.translationEn = translationEn
    self.repetitions = repetitions
    self.xpValue = xpValue
  }
}

// MARK: - Journey Model
@Model
final class JourneyModel {
  @Attribute(.unique) var id: Int
  var name: String
  var slug: String
  var journeyDescription: String?
  var emoji: String?
  var estimatedMinutes: Int?
  var dailyXP: Int?
  var isPremium: Bool
  var isFeatured: Bool
  var sortOrder: Int?

  @Relationship(deleteRule: .cascade, inverse: \JourneyDuaModel.journey)
  var journeyDuas: [JourneyDuaModel]?

  init(id: Int, name: String, slug: String, isPremium: Bool = false, isFeatured: Bool = false) {
    self.id = id
    self.name = name
    self.slug = slug
    self.isPremium = isPremium
    self.isFeatured = isFeatured
  }
}

// MARK: - Journey-Dua Relationship
@Model
final class JourneyDuaModel {
  var journey: JourneyModel?
  var dua: DuaModel?
  var timeSlot: String
  var sortOrder: Int

  init(journey: JourneyModel, dua: DuaModel, timeSlot: String, sortOrder: Int) {
    self.journey = journey
    self.dua = dua
    self.timeSlot = timeSlot
    self.sortOrder = sortOrder
  }
}

// MARK: - User Progress
@Model
final class UserDuaProgress {
  var dua: DuaModel?
  var userId: String
  var completedCount: Int
  var lastCompletedAt: Date?

  init(dua: DuaModel, userId: String) {
    self.dua = dua
    self.userId = userId
    self.completedCount = 0
  }

  func markCompleted() {
    completedCount += 1
    lastCompletedAt = Date()
  }
}

// MARK: - Daily Activity
@Model
final class DailyActivity {
  @Attribute(.unique) var id: String // "{userId}_{date}"
  var userId: String
  var date: Date
  var duasCompleted: [Int] // Array of dua IDs
  var xpEarned: Int

  init(userId: String, date: Date) {
    self.userId = userId
    self.date = date
    self.id = "\(userId)_\(date.formatted(.iso8601.year().month().day()))"
    self.duasCompleted = []
    self.xpEarned = 0
  }

  func addCompletion(duaId: Int, xp: Int) {
    if !duasCompleted.contains(duaId) {
      duasCompleted.append(duaId)
    }
    xpEarned += xp
  }
}

// MARK: - User Habit
@Model
final class UserHabit {
  @Attribute(.unique) var id: String
  var journeyId: Int?
  var duaId: Int?
  var isCustom: Bool
  var customTitle: String?
  var timeSlot: String
  var createdAt: Date

  init(journeyId: Int, timeSlot: String) {
    self.id = "journey_\(journeyId)_\(timeSlot)"
    self.journeyId = journeyId
    self.timeSlot = timeSlot
    self.isCustom = false
    self.createdAt = Date()
  }

  init(customTitle: String, timeSlot: String) {
    self.id = "custom_\(UUID().uuidString)"
    self.customTitle = customTitle
    self.timeSlot = timeSlot
    self.isCustom = true
    self.createdAt = Date()
  }
}

// MARK: - Habit Completion
@Model
final class HabitCompletion {
  @Attribute(.unique) var id: String // "{habitId}_{date}"
  var habitId: String
  var date: Date
  var completedAt: Date

  init(habitId: String, date: Date) {
    self.id = "\(habitId)_\(date.formatted(.iso8601.year().month().day()))"
    self.habitId = habitId
    self.date = date
    self.completedAt = Date()
  }
}
```

### Model Container Setup

```swift
import SwiftData

// MARK: - Model Container Configuration
extension ModelContainer {
  static var rizqContainer: ModelContainer {
    let schema = Schema([
      DuaModel.self,
      JourneyModel.self,
      JourneyDuaModel.self,
      UserDuaProgress.self,
      DailyActivity.self,
      UserHabit.self,
      HabitCompletion.self
    ])

    let configuration = ModelConfiguration(
      schema: schema,
      isStoredInMemoryOnly: false,
      allowsSave: true,
      groupContainer: .identifier("group.com.rizq.app") // For widgets
    )

    do {
      return try ModelContainer(for: schema, configurations: [configuration])
    } catch {
      fatalError("Failed to create ModelContainer: \(error)")
    }
  }

  static var previewContainer: ModelContainer {
    let schema = Schema([
      DuaModel.self,
      JourneyModel.self,
      JourneyDuaModel.self,
      UserDuaProgress.self,
      DailyActivity.self,
      UserHabit.self,
      HabitCompletion.self
    ])

    let configuration = ModelConfiguration(
      schema: schema,
      isStoredInMemoryOnly: true
    )

    do {
      let container = try ModelContainer(for: schema, configurations: [configuration])
      // Insert sample data
      Task { @MainActor in
        insertSampleData(into: container.mainContext)
      }
      return container
    } catch {
      fatalError("Failed to create preview container: \(error)")
    }
  }

  @MainActor
  private static func insertSampleData(into context: ModelContext) {
    let sampleDua = DuaModel(
      id: 1,
      categoryId: 1,
      titleEn: "Morning Remembrance",
      arabicText: "أَصْبَحْنَا وَأَصْبَحَ الْمُلْكُ لِلَّهِ",
      transliteration: "Asbahnaa wa asbahal-mulku lillaah",
      translationEn: "We have entered the morning and the dominion belongs to Allah"
    )
    context.insert(sampleDua)
  }
}

// MARK: - App Setup
@main
struct RIZQApp: App {
  var body: some Scene {
    WindowGroup {
      ContentView()
    }
    .modelContainer(.rizqContainer)
  }
}
```

---

## SwiftData Queries

### Basic Queries

```swift
import SwiftData

// MARK: - Query in Views
struct DuaListView: View {
  @Query(sort: \DuaModel.id) private var duas: [DuaModel]

  var body: some View {
    List(duas) { dua in
      DuaRow(dua: dua)
    }
  }
}

// MARK: - Filtered Queries
struct MorningDuasView: View {
  @Query(
    filter: #Predicate<DuaModel> { dua in
      dua.bestTime == "morning"
    },
    sort: \DuaModel.id
  )
  private var morningDuas: [DuaModel]

  var body: some View {
    List(morningDuas) { dua in
      DuaRow(dua: dua)
    }
  }
}

// MARK: - Dynamic Queries
struct CategoryDuasView: View {
  let categoryId: Int

  @Query private var duas: [DuaModel]

  init(categoryId: Int) {
    self.categoryId = categoryId
    _duas = Query(
      filter: #Predicate<DuaModel> { dua in
        dua.categoryId == categoryId
      },
      sort: \DuaModel.id
    )
  }

  var body: some View {
    List(duas) { dua in
      DuaRow(dua: dua)
    }
  }
}
```

### Repository Pattern with SwiftData

```swift
// MARK: - Dua Repository
@MainActor
protocol DuaRepositoryProtocol {
  func fetchAll() async throws -> [DuaModel]
  func fetchById(_ id: Int) async throws -> DuaModel?
  func fetchByCategory(_ categoryId: Int) async throws -> [DuaModel]
  func save(_ dua: DuaModel) async throws
  func delete(_ dua: DuaModel) async throws
}

@MainActor
final class DuaRepository: DuaRepositoryProtocol {
  private let modelContext: ModelContext

  init(modelContext: ModelContext) {
    self.modelContext = modelContext
  }

  func fetchAll() async throws -> [DuaModel] {
    let descriptor = FetchDescriptor<DuaModel>(sortBy: [SortDescriptor(\.id)])
    return try modelContext.fetch(descriptor)
  }

  func fetchById(_ id: Int) async throws -> DuaModel? {
    let descriptor = FetchDescriptor<DuaModel>(
      predicate: #Predicate { $0.id == id }
    )
    return try modelContext.fetch(descriptor).first
  }

  func fetchByCategory(_ categoryId: Int) async throws -> [DuaModel] {
    let descriptor = FetchDescriptor<DuaModel>(
      predicate: #Predicate { $0.categoryId == categoryId },
      sortBy: [SortDescriptor(\.id)]
    )
    return try modelContext.fetch(descriptor)
  }

  func save(_ dua: DuaModel) async throws {
    modelContext.insert(dua)
    try modelContext.save()
  }

  func delete(_ dua: DuaModel) async throws {
    modelContext.delete(dua)
    try modelContext.save()
  }
}
```

---

## TCA Integration with SwiftData

### SwiftData Dependency

```swift
import ComposableArchitecture
import SwiftData

// MARK: - Model Context Dependency
struct ModelContextKey: DependencyKey {
  @MainActor
  static let liveValue: ModelContext = ModelContainer.rizqContainer.mainContext

  @MainActor
  static let testValue: ModelContext = ModelContainer.previewContainer.mainContext

  @MainActor
  static let previewValue: ModelContext = ModelContainer.previewContainer.mainContext
}

extension DependencyValues {
  var modelContext: ModelContext {
    get { self[ModelContextKey.self] }
    set { self[ModelContextKey.self] = newValue }
  }
}

// MARK: - Repository Dependencies
struct DuaRepositoryKey: DependencyKey {
  @MainActor
  static let liveValue: DuaRepositoryProtocol = DuaRepository(
    modelContext: ModelContainer.rizqContainer.mainContext
  )

  @MainActor
  static let testValue: DuaRepositoryProtocol = MockDuaRepository()
}

extension DependencyValues {
  var duaRepository: DuaRepositoryProtocol {
    get { self[DuaRepositoryKey.self] }
    set { self[DuaRepositoryKey.self] = newValue }
  }
}
```

### Feature with SwiftData

```swift
import ComposableArchitecture

// MARK: - Dua Library Feature
@Reducer
struct DuaLibraryFeature {
  @ObservableState
  struct State: Equatable {
    var duas: [Dua] = []
    var isLoading = false
    var error: String?
    var selectedCategory: Int?
  }

  enum Action {
    case onAppear
    case loadDuas
    case duasLoaded(Result<[Dua], Error>)
    case categorySelected(Int?)
  }

  @Dependency(\.duaRepository) var duaRepository

  var body: some ReducerOf<Self> {
    Reduce { state, action in
      switch action {
      case .onAppear:
        return .send(.loadDuas)

      case .loadDuas:
        state.isLoading = true
        let categoryId = state.selectedCategory
        return .run { send in
          do {
            let models: [DuaModel]
            if let categoryId {
              models = try await duaRepository.fetchByCategory(categoryId)
            } else {
              models = try await duaRepository.fetchAll()
            }
            let duas = models.map { $0.toDomain() }
            await send(.duasLoaded(.success(duas)))
          } catch {
            await send(.duasLoaded(.failure(error)))
          }
        }

      case .duasLoaded(.success(let duas)):
        state.duas = duas
        state.isLoading = false
        return .none

      case .duasLoaded(.failure(let error)):
        state.error = error.localizedDescription
        state.isLoading = false
        return .none

      case .categorySelected(let categoryId):
        state.selectedCategory = categoryId
        return .send(.loadDuas)
      }
    }
  }
}

// MARK: - Domain Mapping
extension DuaModel {
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
```

---

## Habit Storage (localStorage Equivalent)

### React localStorage Pattern → SwiftData

```typescript
// React Web Pattern
const HABITS_KEY = 'rizq_user_habits';

interface HabitStorage {
  activeJourneyIds: number[];
  customHabits: CustomHabit[];
  habitCompletions: Record<string, HabitCompletion>;
}

const storage = JSON.parse(localStorage.getItem(HABITS_KEY) || '{}');
```

### Swift Equivalent

```swift
// MARK: - Habit Storage Manager
@MainActor
@Observable
final class HabitStorageManager {
  private let modelContext: ModelContext

  // In-memory cache for quick access
  private(set) var activeJourneyIds: Set<Int> = []
  private(set) var todaysCompletions: Set<String> = []

  init(modelContext: ModelContext) {
    self.modelContext = modelContext
    Task {
      await loadInitialState()
    }
  }

  private func loadInitialState() async {
    // Load active journeys
    let habits = try? modelContext.fetch(FetchDescriptor<UserHabit>())
    activeJourneyIds = Set(habits?.compactMap { $0.journeyId } ?? [])

    // Load today's completions
    let today = Calendar.current.startOfDay(for: Date())
    let completions = try? modelContext.fetch(
      FetchDescriptor<HabitCompletion>(
        predicate: #Predicate { $0.date >= today }
      )
    )
    todaysCompletions = Set(completions?.map { $0.habitId } ?? [])
  }

  // MARK: - Journey Subscription

  func subscribeToJourney(_ journeyId: Int) async throws {
    // Create habits for each time slot
    for slot in ["morning", "anytime", "evening"] {
      let habit = UserHabit(journeyId: journeyId, timeSlot: slot)
      modelContext.insert(habit)
    }
    try modelContext.save()
    activeJourneyIds.insert(journeyId)
  }

  func unsubscribeFromJourney(_ journeyId: Int) async throws {
    let descriptor = FetchDescriptor<UserHabit>(
      predicate: #Predicate { $0.journeyId == journeyId }
    )
    let habits = try modelContext.fetch(descriptor)
    habits.forEach { modelContext.delete($0) }
    try modelContext.save()
    activeJourneyIds.remove(journeyId)
  }

  // MARK: - Habit Completion

  func markHabitComplete(_ habitId: String) async throws {
    let today = Calendar.current.startOfDay(for: Date())
    let completion = HabitCompletion(habitId: habitId, date: today)
    modelContext.insert(completion)
    try modelContext.save()
    todaysCompletions.insert(habitId)
  }

  func isHabitCompletedToday(_ habitId: String) -> Bool {
    todaysCompletions.contains(habitId)
  }

  // MARK: - Today's Habits

  func getTodaysHabits() async throws -> [TodayHabit] {
    let habits = try modelContext.fetch(FetchDescriptor<UserHabit>())
    return habits.map { habit in
      TodayHabit(
        id: habit.id,
        journeyId: habit.journeyId,
        customTitle: habit.customTitle,
        timeSlot: TimeSlot(rawValue: habit.timeSlot) ?? .anytime,
        isCompleted: isHabitCompletedToday(habit.id)
      )
    }
  }
}

// MARK: - Today Habit View Model
struct TodayHabit: Identifiable, Equatable {
  let id: String
  let journeyId: Int?
  let customTitle: String?
  let timeSlot: TimeSlot
  var isCompleted: Bool
}
```

---

## Data Sync Strategy

### Sync Manager

```swift
// MARK: - Sync Manager
@MainActor
@Observable
final class SyncManager {
  private let modelContext: ModelContext
  private let apiClient: APIClientProtocol

  var lastSyncDate: Date? {
    get { UserDefaults.standard.object(forKey: "last_sync_date") as? Date }
    set { UserDefaults.standard.set(newValue, forKey: "last_sync_date") }
  }

  var isSyncing = false
  var syncError: String?

  init(modelContext: ModelContext, apiClient: APIClientProtocol) {
    self.modelContext = modelContext
    self.apiClient = apiClient
  }

  // MARK: - Full Sync

  func performFullSync() async {
    guard !isSyncing else { return }
    isSyncing = true
    syncError = nil

    do {
      // Sync duas
      try await syncDuas()

      // Sync journeys
      try await syncJourneys()

      // Upload local changes
      try await uploadLocalChanges()

      lastSyncDate = Date()
    } catch {
      syncError = error.localizedDescription
    }

    isSyncing = false
  }

  // MARK: - Sync Duas

  private func syncDuas() async throws {
    let remoteDuas: [DuaDTO] = try await apiClient.fetchArray(
      Endpoint(path: "/duas")
    )

    for dto in remoteDuas {
      let descriptor = FetchDescriptor<DuaModel>(
        predicate: #Predicate { $0.id == dto.id }
      )

      if let existing = try modelContext.fetch(descriptor).first {
        // Update existing
        existing.titleEn = dto.titleEn
        existing.arabicText = dto.arabicText
        // ... update other fields
      } else {
        // Insert new
        let model = DuaModel(
          id: dto.id,
          categoryId: dto.categoryId,
          titleEn: dto.titleEn,
          arabicText: dto.arabicText,
          transliteration: dto.transliteration,
          translationEn: dto.translationEn,
          repetitions: dto.repetitions,
          xpValue: dto.xpValue
        )
        modelContext.insert(model)
      }
    }

    try modelContext.save()
  }

  // MARK: - Sync Journeys

  private func syncJourneys() async throws {
    let remoteJourneys: [JourneyDTO] = try await apiClient.fetchArray(
      Endpoint(path: "/journeys")
    )

    for dto in remoteJourneys {
      let descriptor = FetchDescriptor<JourneyModel>(
        predicate: #Predicate { $0.id == dto.id }
      )

      if let existing = try modelContext.fetch(descriptor).first {
        existing.name = dto.name
        // ... update other fields
      } else {
        let model = JourneyModel(
          id: dto.id,
          name: dto.name,
          slug: dto.slug,
          isPremium: dto.isPremium,
          isFeatured: dto.isFeatured
        )
        modelContext.insert(model)
      }
    }

    try modelContext.save()
  }

  // MARK: - Upload Local Changes

  private func uploadLocalChanges() async throws {
    // Upload activity since last sync
    guard let lastSync = lastSyncDate else { return }

    let descriptor = FetchDescriptor<DailyActivity>(
      predicate: #Predicate { $0.date > lastSync }
    )
    let activities = try modelContext.fetch(descriptor)

    for activity in activities {
      try await apiClient.execute(
        Endpoint(
          path: "/users/\(activity.userId)/activity",
          method: .post,
          body: try JSONEncoder().encode(activity)
        )
      )
    }
  }
}
```

---

## Migration Strategies

### SwiftData Schema Versioning

```swift
// MARK: - Schema Versions
enum SchemaV1: VersionedSchema {
  static var versionIdentifier: Schema.Version = .init(1, 0, 0)

  static var models: [any PersistentModel.Type] {
    [DuaModelV1.self]
  }

  @Model
  final class DuaModelV1 {
    @Attribute(.unique) var id: Int
    var title: String
    var arabicText: String

    init(id: Int, title: String, arabicText: String) {
      self.id = id
      self.title = title
      self.arabicText = arabicText
    }
  }
}

enum SchemaV2: VersionedSchema {
  static var versionIdentifier: Schema.Version = .init(2, 0, 0)

  static var models: [any PersistentModel.Type] {
    [DuaModel.self] // Current version
  }
}

// MARK: - Migration Plan
enum MigrationPlan: SchemaMigrationPlan {
  static var schemas: [any VersionedSchema.Type] {
    [SchemaV1.self, SchemaV2.self]
  }

  static var stages: [MigrationStage] {
    [migrateV1toV2]
  }

  static let migrateV1toV2 = MigrationStage.custom(
    fromVersion: SchemaV1.self,
    toVersion: SchemaV2.self
  ) { context in
    // Custom migration logic
    let oldDuas = try context.fetch(FetchDescriptor<SchemaV1.DuaModelV1>())

    for oldDua in oldDuas {
      // Migrate data to new schema
      let newDua = DuaModel(
        id: oldDua.id,
        categoryId: 1, // Default value for new field
        titleEn: oldDua.title,
        arabicText: oldDua.arabicText,
        transliteration: "",
        translationEn: ""
      )
      context.insert(newDua)
      context.delete(oldDua)
    }

    try context.save()
  }
}

// MARK: - Container with Migration
extension ModelContainer {
  static var rizqContainerWithMigration: ModelContainer {
    do {
      return try ModelContainer(
        for: DuaModel.self,
        migrationPlan: MigrationPlan.self
      )
    } catch {
      fatalError("Failed to create container with migration: \(error)")
    }
  }
}
```

---

## Reference: localStorage Keys Mapping

| React localStorage Key | iOS Storage | Type |
|------------------------|-------------|------|
| `rizq_user_habits` | SwiftData (UserHabit) | Model |
| `rizq_daily_activity` | SwiftData (DailyActivity) | Model |
| `rizq_user_profile` | SwiftData + UserDefaults | Hybrid |
| `rizq_welcome_shown` | @AppStorage | Bool |
| `lastUsedProvider` | @AppStorage | String |
| `theme_mode` | @AppStorage | String |
| Auth tokens | Keychain | Secure |
