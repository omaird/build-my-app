# Phase 4: Habits System

> **Objective**: Implement full habit tracking with journey subscriptions, daily completions, and time slot grouping

## Overview

The habits system is the core engagement mechanism of RIZQ. Users subscribe to journeys, which populate their daily adkhar (habits). This phase implements the full habit management system matching React's `useUserHabits` hook functionality.

---

## React Reference: useUserHabits

The React hook provides:
```typescript
{
  // Data
  todaysHabits: HabitWithDua[]       // All habits for today
  groupedHabits: { morning, anytime, evening }
  activeJourneys: Journey[]          // Full journey objects
  progress: { total, completed, percentage, totalXp, earnedXp }

  // Actions
  addJourney(journeyId)
  removeJourney(journeyId)
  toggleJourney(journeyId)
  addCustomHabit(duaId, timeSlot)
  removeCustomHabit(habitId)
  markHabitCompleted(duaId)
  isHabitCompletedToday(duaId)

  // Navigation
  nextUncompletedHabit: HabitWithDua?
}
```

**Storage**: localStorage with key `rizq_user_habits`
**Schema**:
```typescript
{
  activeJourneyIds: string[]
  customHabits: UserHabit[]
  habitCompletions: [{ date, completedDuaIds }]
  lastUpdated: string
}
```

---

## iOS Implementation

### Task 4.1: Create UserHabitsStorage

**File**: `RIZQKit/Services/Persistence/UserHabitsStorage.swift` (NEW)

```swift
import Foundation

public struct UserHabitsData: Codable, Equatable {
    public var activeJourneyIds: [Int]
    public var customHabits: [CustomHabit]
    public var habitCompletions: [HabitCompletion]
    public var lastUpdated: Date

    public init(
        activeJourneyIds: [Int] = [],
        customHabits: [CustomHabit] = [],
        habitCompletions: [HabitCompletion] = [],
        lastUpdated: Date = Date()
    ) {
        self.activeJourneyIds = activeJourneyIds
        self.customHabits = customHabits
        self.habitCompletions = habitCompletions
        self.lastUpdated = lastUpdated
    }
}

public struct CustomHabit: Codable, Equatable, Identifiable {
    public let id: String
    public let duaId: Int
    public let timeSlot: TimeSlot
    public let sortOrder: Int
    public let addedAt: Date

    public init(duaId: Int, timeSlot: TimeSlot, sortOrder: Int = 0) {
        self.id = UUID().uuidString
        self.duaId = duaId
        self.timeSlot = timeSlot
        self.sortOrder = sortOrder
        self.addedAt = Date()
    }
}

public struct HabitCompletion: Codable, Equatable {
    public let date: String  // YYYY-MM-DD
    public var completedDuaIds: [Int]

    public init(date: String, completedDuaIds: [Int] = []) {
        self.date = date
        self.completedDuaIds = completedDuaIds
    }
}

// MARK: - Storage Service

public actor UserHabitsStorage {
    private let defaults: UserDefaults
    private let key = "rizq_user_habits"

    public init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    public func load() -> UserHabitsData {
        guard let data = defaults.data(forKey: key),
              let decoded = try? JSONDecoder().decode(UserHabitsData.self, from: data)
        else {
            return UserHabitsData()
        }
        return decoded
    }

    public func save(_ data: UserHabitsData) {
        var updated = data
        updated.lastUpdated = Date()
        if let encoded = try? JSONEncoder().encode(updated) {
            defaults.set(encoded, forKey: key)
        }
    }

    // MARK: - Journey Management

    public func addJourney(_ journeyId: Int) {
        var data = load()
        if !data.activeJourneyIds.contains(journeyId) {
            data.activeJourneyIds.append(journeyId)
            save(data)
        }
    }

    public func removeJourney(_ journeyId: Int) {
        var data = load()
        data.activeJourneyIds.removeAll { $0 == journeyId }
        save(data)
    }

    public func isJourneyActive(_ journeyId: Int) -> Bool {
        load().activeJourneyIds.contains(journeyId)
    }

    // MARK: - Custom Habits

    public func addCustomHabit(duaId: Int, timeSlot: TimeSlot) {
        var data = load()
        // Check if already exists
        guard !data.customHabits.contains(where: { $0.duaId == duaId }) else { return }
        let habit = CustomHabit(
            duaId: duaId,
            timeSlot: timeSlot,
            sortOrder: data.customHabits.count
        )
        data.customHabits.append(habit)
        save(data)
    }

    public func removeCustomHabit(id: String) {
        var data = load()
        data.customHabits.removeAll { $0.id == id }
        save(data)
    }

    // MARK: - Completions

    private var todayDateString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: Date())
    }

    public func markHabitCompleted(duaId: Int) {
        var data = load()
        let today = todayDateString

        if let index = data.habitCompletions.firstIndex(where: { $0.date == today }) {
            if !data.habitCompletions[index].completedDuaIds.contains(duaId) {
                data.habitCompletions[index].completedDuaIds.append(duaId)
            }
        } else {
            data.habitCompletions.append(HabitCompletion(date: today, completedDuaIds: [duaId]))
        }

        // Keep only last 30 days of completions
        let thirtyDaysAgo = Calendar.current.date(byAdding: .day, value: -30, to: Date())!
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        let cutoffString = formatter.string(from: thirtyDaysAgo)
        data.habitCompletions = data.habitCompletions.filter { $0.date >= cutoffString }

        save(data)
    }

    public func isCompletedToday(duaId: Int) -> Bool {
        let data = load()
        let today = todayDateString
        return data.habitCompletions
            .first { $0.date == today }?
            .completedDuaIds
            .contains(duaId) ?? false
    }

    public func todayCompletedIds() -> [Int] {
        load().habitCompletions
            .first { $0.date == todayDateString }?
            .completedDuaIds ?? []
    }
}
```

---

### Task 4.2: Create UserHabitsClient

**File**: `RIZQKit/Services/UserHabitsClient.swift` (NEW)

```swift
import ComposableArchitecture

@DependencyClient
public struct UserHabitsClient {
    // Data
    public var loadHabitsData: @Sendable () async -> UserHabitsData
    public var getActiveJourneyIds: @Sendable () async -> [Int]

    // Journey Management
    public var addJourney: @Sendable (_ journeyId: Int) async -> Void
    public var removeJourney: @Sendable (_ journeyId: Int) async -> Void
    public var isJourneyActive: @Sendable (_ journeyId: Int) async -> Bool

    // Custom Habits
    public var addCustomHabit: @Sendable (_ duaId: Int, _ timeSlot: TimeSlot) async -> Void
    public var removeCustomHabit: @Sendable (_ habitId: String) async -> Void

    // Completions
    public var markCompleted: @Sendable (_ duaId: Int) async -> Void
    public var isCompletedToday: @Sendable (_ duaId: Int) async -> Bool
    public var todayCompletedIds: @Sendable () async -> [Int]
}

extension UserHabitsClient: DependencyKey {
    public static let liveValue: UserHabitsClient = {
        let storage = UserHabitsStorage()

        return UserHabitsClient(
            loadHabitsData: { await storage.load() },
            getActiveJourneyIds: { await storage.load().activeJourneyIds },
            addJourney: { await storage.addJourney($0) },
            removeJourney: { await storage.removeJourney($0) },
            isJourneyActive: { await storage.isJourneyActive($0) },
            addCustomHabit: { await storage.addCustomHabit(duaId: $0, timeSlot: $1) },
            removeCustomHabit: { await storage.removeCustomHabit(id: $0) },
            markCompleted: { await storage.markHabitCompleted(duaId: $0) },
            isCompletedToday: { await storage.isCompletedToday(duaId: $0) },
            todayCompletedIds: { await storage.todayCompletedIds() }
        )
    }()

    public static let previewValue = UserHabitsClient(
        loadHabitsData: { UserHabitsData(activeJourneyIds: [1, 2]) },
        getActiveJourneyIds: { [1, 2] },
        addJourney: { _ in },
        removeJourney: { _ in },
        isJourneyActive: { _ in true },
        addCustomHabit: { _, _ in },
        removeCustomHabit: { _ in },
        markCompleted: { _ in },
        isCompletedToday: { _ in false },
        todayCompletedIds: { [] }
    )
}

extension DependencyValues {
    public var userHabitsClient: UserHabitsClient {
        get { self[UserHabitsClient.self] }
        set { self[UserHabitsClient.self] = newValue }
    }
}
```

---

### Task 4.3: Update Adkhar Feature

**File**: `RIZQ/Features/Adkhar/AdkharFeature.swift`

```swift
@Reducer
struct AdkharFeature {
    @ObservableState
    struct State: Equatable {
        var loadingState: LoadingState = .idle
        var habits: [Habit] = []
        var completedDuaIds: Set<Int> = []
        var activeJourneyIds: [Int] = []

        // Computed
        var groupedHabits: [TimeSlot: [Habit]] {
            Dictionary(grouping: habits, by: { $0.timeSlot })
        }

        var morningHabits: [Habit] { groupedHabits[.morning] ?? [] }
        var anytimeHabits: [Habit] { groupedHabits[.anytime] ?? [] }
        var eveningHabits: [Habit] { groupedHabits[.evening] ?? [] }

        var progress: HabitProgress {
            let total = habits.count
            let completed = habits.filter { completedDuaIds.contains($0.duaId) }.count
            let totalXp = habits.reduce(0) { $0 + $1.xpValue }
            let earnedXp = habits
                .filter { completedDuaIds.contains($0.duaId) }
                .reduce(0) { $0 + $1.xpValue }

            return HabitProgress(
                total: total,
                completed: completed,
                percentage: total > 0 ? Double(completed) / Double(total) : 0,
                totalXp: totalXp,
                earnedXp: earnedXp
            )
        }

        var nextUncompletedHabit: Habit? {
            habits.first { !completedDuaIds.contains($0.duaId) }
        }

        var allCompleted: Bool {
            !habits.isEmpty && habits.allSatisfy { completedDuaIds.contains($0.duaId) }
        }

        // Quick Practice Sheet
        @Presents var quickPractice: PracticeFeature.State?
    }

    struct HabitProgress: Equatable {
        let total: Int
        let completed: Int
        let percentage: Double
        let totalXp: Int
        let earnedXp: Int
    }

    enum Action {
        case onAppear
        case habitsLoaded(TaskResult<[Habit], Error>)
        case completionsLoaded([Int])
        case habitTapped(Habit)
        case habitCompleted(duaId: Int)
        case refreshTapped

        // Quick Practice
        case quickPractice(PresentationAction<PracticeFeature.Action>)
    }

    @Dependency(\.neonService) var neonService
    @Dependency(\.userHabitsClient) var habitsClient
    @Dependency(\.userDataClient) var userDataClient

    var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .onAppear:
                state.loadingState = .loading
                return .merge(
                    .run { send in
                        await send(.habitsLoaded(TaskResult {
                            try await loadTodaysHabits()
                        }))
                    },
                    .run { send in
                        let ids = await habitsClient.todayCompletedIds()
                        await send(.completionsLoaded(ids))
                    }
                )

            case .habitsLoaded(.success(let habits)):
                state.habits = habits
                state.loadingState = .loaded
                return .none

            case .habitsLoaded(.failure(let error)):
                state.loadingState = .error(error.localizedDescription)
                return .none

            case .completionsLoaded(let ids):
                state.completedDuaIds = Set(ids)
                return .none

            case .habitTapped(let habit):
                // Open quick practice sheet
                state.quickPractice = PracticeFeature.State(dua: habit.toDua())
                return .none

            case .habitCompleted(let duaId):
                state.completedDuaIds.insert(duaId)
                return .run { _ in
                    await habitsClient.markCompleted(duaId)
                }

            case .quickPractice(.presented(.duaCompleted)):
                // Mark habit completed when practice finishes
                if let duaId = state.quickPractice?.dua?.id {
                    state.completedDuaIds.insert(duaId)
                }
                state.quickPractice = nil
                return .none

            case .quickPractice:
                return .none

            case .refreshTapped:
                return .send(.onAppear)
            }
        }
        .ifLet(\.$quickPractice, action: \.quickPractice) {
            PracticeFeature()
        }
    }

    // MARK: - Helpers

    private func loadTodaysHabits() async throws -> [Habit] {
        // 1. Get active journey IDs
        let journeyIds = await habitsClient.getActiveJourneyIds()

        // 2. Fetch journey duas (merged, deduplicated)
        var habits: [Habit] = []
        var seenDuaIds: Set<Int> = []

        for journeyId in journeyIds {
            if let journeyWithDuas = try await neonService.fetchJourneyWithDuas(id: journeyId) {
                for journeyDua in journeyWithDuas.duas {
                    // Deduplicate by dua ID
                    guard !seenDuaIds.contains(journeyDua.dua.id) else { continue }
                    seenDuaIds.insert(journeyDua.dua.id)

                    let habit = Habit(
                        id: "\(journeyId)-\(journeyDua.dua.id)",
                        duaId: journeyDua.dua.id,
                        journeyId: journeyId,
                        timeSlot: journeyDua.journeyDua.timeSlot,
                        title: journeyDua.dua.titleEn,
                        arabicText: journeyDua.dua.arabicText,
                        transliteration: journeyDua.dua.transliteration,
                        translation: journeyDua.dua.translationEn,
                        repetitions: journeyDua.dua.repetitions,
                        xpValue: journeyDua.dua.xpValue,
                        source: journeyDua.dua.source,
                        rizqBenefit: journeyDua.dua.rizqBenefit,
                        propheticContext: journeyDua.dua.propheticContext,
                        isCustom: false
                    )
                    habits.append(habit)
                }
            }
        }

        // 3. Add custom habits
        let habitsData = await habitsClient.loadHabitsData()
        for customHabit in habitsData.customHabits {
            guard !seenDuaIds.contains(customHabit.duaId) else { continue }
            if let dua = try await neonService.fetchDua(id: customHabit.duaId) {
                seenDuaIds.insert(dua.id)
                let habit = Habit(
                    id: customHabit.id,
                    duaId: dua.id,
                    journeyId: nil,
                    timeSlot: customHabit.timeSlot,
                    title: dua.titleEn,
                    arabicText: dua.arabicText,
                    transliteration: dua.transliteration,
                    translation: dua.translationEn,
                    repetitions: dua.repetitions,
                    xpValue: dua.xpValue,
                    source: dua.source,
                    rizqBenefit: dua.rizqBenefit,
                    propheticContext: dua.propheticContext,
                    isCustom: true
                )
                habits.append(habit)
            }
        }

        // 4. Sort by time slot priority, then sort order
        return habits.sorted { h1, h2 in
            if h1.timeSlot.sortPriority != h2.timeSlot.sortPriority {
                return h1.timeSlot.sortPriority < h2.timeSlot.sortPriority
            }
            return false
        }
    }
}

// MARK: - Extensions

extension TimeSlot {
    var sortPriority: Int {
        switch self {
        case .morning: return 0
        case .anytime: return 1
        case .evening: return 2
        }
    }
}
```

---

### Task 4.4: Update Adkhar View

**File**: `RIZQ/Features/Adkhar/AdkharView.swift`

```swift
struct AdkharView: View {
    @Bindable var store: StoreOf<AdkharFeature>

    var body: some View {
        Group {
            switch store.loadingState {
            case .loading:
                loadingView
            case .error(let message):
                errorView(message)
            case .loaded where store.habits.isEmpty:
                emptyView
            default:
                contentView
            }
        }
        .navigationTitle("Daily Adkhar")
        .task { store.send(.onAppear) }
        .sheet(item: $store.scope(state: \.quickPractice, action: \.quickPractice)) { practiceStore in
            QuickPracticeSheet(store: practiceStore)
        }
    }

    private var contentView: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Progress Header
                progressHeader

                // Time Slot Sections
                ForEach([TimeSlot.morning, .anytime, .evening], id: \.self) { slot in
                    if let habits = store.groupedHabits[slot], !habits.isEmpty {
                        TimeSlotSection(
                            slot: slot,
                            habits: habits,
                            completedIds: store.completedDuaIds
                        ) { habit in
                            store.send(.habitTapped(habit))
                        }
                    }
                }

                // All Complete Celebration
                if store.allCompleted {
                    allCompleteCelebration
                }
            }
            .padding()
        }
    }

    private var progressHeader: some View {
        VStack(spacing: 12) {
            HStack {
                Text("Today's Progress")
                    .font(.headline)
                Spacer()
                Text("\(store.progress.completed)/\(store.progress.total)")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            HabitProgressBar(progress: store.progress.percentage)

            HStack {
                Label("\(store.progress.earnedXp) XP", systemImage: "star.fill")
                    .foregroundStyle(.orange)
                Spacer()
                Label("\(store.progress.totalXp - store.progress.earnedXp) XP remaining", systemImage: "star")
                    .foregroundStyle(.secondary)
            }
            .font(.caption)
        }
        .padding()
        .background(.card)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private var allCompleteCelebration: some View {
        VStack(spacing: 16) {
            Image(systemName: "checkmark.seal.fill")
                .font(.system(size: 48))
                .foregroundStyle(.green)

            Text("All Complete!")
                .font(.title2.bold())

            Text("You've completed all your duas for today. MashaAllah!")
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(Color.green.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private var emptyView: some View {
        VStack(spacing: 24) {
            Image(systemName: "moon.stars")
                .font(.system(size: 64))
                .foregroundStyle(.secondary)

            Text("No Daily Adkhar")
                .font(.title2.bold())

            Text("Subscribe to a journey or add duas to your daily routine.")
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            NavigationLink(destination: JourneysView(store: /* journeys store */)) {
                Text("Explore Journeys")
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.accentColor)
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }
        }
        .padding()
    }

    private var loadingView: some View {
        VStack(spacing: 12) {
            ProgressView()
            Text("Loading habits...")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func errorView(_ message: String) -> some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle")
                .font(.largeTitle)
                .foregroundStyle(.orange)
            Text("Failed to load habits")
                .font(.headline)
            Text(message)
                .font(.caption)
                .foregroundStyle(.secondary)
            Button("Try Again") {
                store.send(.onAppear)
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()
    }
}

// MARK: - Subviews

struct TimeSlotSection: View {
    let slot: TimeSlot
    let habits: [Habit]
    let completedIds: Set<Int>
    let onTap: (Habit) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                slot.icon
                    .foregroundStyle(slot.color)
                Text(slot.displayName)
                    .font(.headline)
            }

            ForEach(habits) { habit in
                HabitItemView(
                    habit: habit,
                    isCompleted: completedIds.contains(habit.duaId),
                    onTap: { onTap(habit) }
                )
            }
        }
    }
}

struct HabitItemView: View {
    let habit: Habit
    let isCompleted: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                // Completion indicator
                Image(systemName: isCompleted ? "checkmark.circle.fill" : "circle")
                    .foregroundStyle(isCompleted ? .green : .secondary)
                    .font(.title2)

                VStack(alignment: .leading, spacing: 4) {
                    Text(habit.title)
                        .font(.body)
                        .foregroundStyle(isCompleted ? .secondary : .primary)
                        .strikethrough(isCompleted)

                    HStack(spacing: 8) {
                        Label("\(habit.repetitions)x", systemImage: "repeat")
                        Label("\(habit.xpValue) XP", systemImage: "star.fill")
                    }
                    .font(.caption)
                    .foregroundStyle(.secondary)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .foregroundStyle(.tertiary)
            }
            .padding()
            .background(isCompleted ? Color.green.opacity(0.05) : Color.card)
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .buttonStyle(.plain)
    }
}
```

---

### Task 4.5: Add to Adkhar Sheet

**File**: `RIZQ/Views/Components/HabitViews/AddToAdkharSheet.swift` (NEW)

For adding duas from Library to daily adkhar:

```swift
struct AddToAdkharSheet: View {
    let dua: Dua
    let onAdd: (TimeSlot) -> Void
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                // Dua Preview
                VStack(spacing: 8) {
                    Text(dua.titleEn)
                        .font(.headline)
                    Text(dua.arabicText)
                        .font(.title3)
                        .fontDesign(.serif)
                }
                .padding()
                .frame(maxWidth: .infinity)
                .background(.ultraThinMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 12))

                // Time Slot Selection
                VStack(alignment: .leading, spacing: 12) {
                    Text("When would you like to practice?")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)

                    ForEach([TimeSlot.morning, .anytime, .evening], id: \.self) { slot in
                        Button {
                            onAdd(slot)
                            dismiss()
                        } label: {
                            HStack {
                                slot.icon
                                    .foregroundStyle(slot.color)
                                Text(slot.displayName)
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .foregroundStyle(.tertiary)
                            }
                            .padding()
                            .background(.card)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .padding()
            .navigationTitle("Add to Daily Adkhar")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
        .presentationDetents([.medium])
    }
}
```

---

## Verification Checklist

- [ ] Subscribing to journey populates daily adkhar
- [ ] Unsubscribing removes journey's duas from adkhar
- [ ] Multiple journeys merge correctly (no duplicates)
- [ ] Custom habits can be added from Library
- [ ] Custom habits appear in correct time slot
- [ ] Habit completion persists across app restarts
- [ ] Progress bar shows correct completion percentage
- [ ] XP earned/remaining calculates correctly
- [ ] Time slot sections display in order: morning → anytime → evening
- [ ] Quick practice sheet opens on habit tap
- [ ] Completing practice marks habit done
- [ ] All complete celebration shows when 100%

---

## Files Modified/Created

| File | Action | Description |
|------|--------|-------------|
| `UserHabitsStorage.swift` | CREATE | Persistence layer |
| `UserHabitsClient.swift` | CREATE | TCA dependency |
| `AdkharFeature.swift` | MODIFY | Full habit loading |
| `AdkharView.swift` | MODIFY | Match React layout |
| `AddToAdkharSheet.swift` | CREATE | Add dua to habits |
| `HabitItemView.swift` | CREATE | Habit row component |

---

## Estimated Effort

| Task | Complexity | Estimate |
|------|------------|----------|
| 4.1 UserHabitsStorage | Medium | 1.5 hours |
| 4.2 UserHabitsClient | Medium | 1 hour |
| 4.3 Adkhar Feature | High | 2 hours |
| 4.4 Adkhar View | Medium | 1.5 hours |
| 4.5 Add to Adkhar Sheet | Low | 45 min |
| **Total** | | **~6.75 hours** |

---

## Dependencies

- **Prerequisites**: Phase 1 (database), Phase 2 (journeys)
- **Blockers**: None
- **Enables**: Phase 5 (UI polish with real habit data)
