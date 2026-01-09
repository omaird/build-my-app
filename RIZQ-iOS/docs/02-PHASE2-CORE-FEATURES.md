# Phase 2: Core Data Features

> **Objective**: Connect Library, Journeys, and JourneyDetail features to the database

## Overview

With the database layer established in Phase 1, this phase wires up the core content features to display real data from Neon PostgreSQL.

---

## Current State

### Library Feature (LibraryFeature.swift)
- Uses `demoData` array with 6 hardcoded duas
- Search and filter logic works on demo data
- Add to adkhar UI exists but doesn't persist

### Journeys Feature (JourneysFeature.swift)
- **Partially working**: Fetches from Neon already
- Journey subscription uses UserDefaults
- Detail view is basic

### Practice Feature (PracticeFeature.swift)
- **Working well**: Counter, haptics, celebrations
- Receives dua from navigation, doesn't need DB changes

---

## Tasks

### Task 2.1: Update Library Feature

**File**: `RIZQ/Features/Library/LibraryFeature.swift`

**Current**:
```swift
// Uses static demoData
case .onAppear:
    state.duas = SampleData.duas  // Replace this
```

**Target**:
```swift
case .onAppear:
    return .run { send in
        await send(.duasLoaded(TaskResult {
            try await neonService.fetchAllDuas()
        }))
    }
```

**Changes**:
1. Add `@Dependency(\.neonService)` to reducer
2. Add loading state enum: `.idle`, `.loading`, `.loaded`, `.error(Error)`
3. Add action: `duasLoaded(TaskResult<[Dua], Error>)`
4. Replace demo data with async fetch on `.onAppear`
5. Implement error state handling

**State Changes**:
```swift
@ObservableState
struct State: Equatable {
    var loadingState: LoadingState = .idle
    var duas: [Dua] = []
    var categories: [DuaCategory] = []
    var searchQuery: String = ""
    var selectedCategory: CategorySlug? = nil
    var filteredDuas: [Dua] {
        // Same filtering logic, applied to fetched data
    }
}

enum LoadingState: Equatable {
    case idle
    case loading
    case loaded
    case error(String)
}
```

---

### Task 2.2: Update Library View

**File**: `RIZQ/Features/Library/LibraryView.swift`

**Changes**:
1. Show loading spinner when `loadingState == .loading`
2. Show error state with retry button when `.error`
3. Show empty state when loaded but no duas match filter
4. Maintain existing search/filter UI

**Loading State View**:
```swift
if state.loadingState == .loading {
    VStack {
        ProgressView()
            .scaleEffect(1.2)
        Text("Loading duas...")
            .font(.subheadline)
            .foregroundStyle(.secondary)
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
}
```

**Error State View**:
```swift
if case .error(let message) = state.loadingState {
    VStack(spacing: 16) {
        Image(systemName: "exclamationmark.triangle")
            .font(.largeTitle)
            .foregroundStyle(.orange)
        Text("Failed to load duas")
            .font(.headline)
        Text(message)
            .font(.caption)
            .foregroundStyle(.secondary)
        Button("Try Again") {
            store.send(.onAppear)
        }
        .buttonStyle(.borderedProminent)
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
}
```

---

### Task 2.3: Update Journeys Feature

**File**: `RIZQ/Features/Journeys/JourneysFeature.swift`

**Current State**: Already fetches journeys from Neon but may need refinement.

**Verify/Update**:
1. Confirm `fetchJourneys` action uses `neonService.fetchAllJourneys()`
2. Add featured section logic: `state.featuredJourneys` and `state.regularJourneys`
3. Match React's sorting: featured first, then by sort_order

**State Enhancement**:
```swift
var featuredJourneys: [Journey] {
    journeys.filter { $0.isFeatured }
}

var regularJourneys: [Journey] {
    journeys.filter { !$0.isFeatured }
}

var activeJourneys: [Journey] {
    journeys.filter { activeJourneyIds.contains($0.id) }
}
```

---

### Task 2.4: Implement Journey Detail Feature

**File**: `RIZQ/Features/Journeys/JourneyDetailFeature.swift` (NEW or UPDATE)

**Purpose**: Display full journey preview with dua list (matches React's JourneyDetailPage)

**State**:
```swift
@Reducer
struct JourneyDetailFeature {
    @ObservableState
    struct State: Equatable {
        var journeyId: Int
        var journey: Journey?
        var journeyDuas: [JourneyDuaFull] = []
        var loadingState: LoadingState = .idle
        var isSubscribed: Bool = false

        // Computed
        var duasByTimeSlot: [TimeSlot: [JourneyDuaFull]] {
            Dictionary(grouping: journeyDuas, by: { $0.journeyDua.timeSlot })
        }
        var totalXp: Int {
            journeyDuas.reduce(0) { $0 + $1.dua.xpValue }
        }
        var totalRepetitions: Int {
            journeyDuas.reduce(0) { $0 + $1.dua.repetitions }
        }
    }

    enum Action {
        case onAppear
        case journeyLoaded(TaskResult<JourneyWithDuas?, Error>)
        case subscribeButtonTapped
        case unsubscribeButtonTapped
        case duaTapped(Dua)
        case dismiss
    }

    @Dependency(\.neonService) var neonService
    @Dependency(\.userHabitsService) var habitsService

    var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .onAppear:
                state.loadingState = .loading
                return .run { [id = state.journeyId] send in
                    await send(.journeyLoaded(TaskResult {
                        try await neonService.fetchJourneyWithDuas(id: id)
                    }))
                }

            case .journeyLoaded(.success(let result)):
                state.loadingState = .loaded
                if let journeyWithDuas = result {
                    state.journey = journeyWithDuas.journey
                    state.journeyDuas = journeyWithDuas.duas
                    state.isSubscribed = habitsService.isJourneyActive(journeyWithDuas.journey.id)
                }
                return .none

            case .journeyLoaded(.failure(let error)):
                state.loadingState = .error(error.localizedDescription)
                return .none

            case .subscribeButtonTapped:
                guard let journey = state.journey else { return .none }
                habitsService.addJourney(journey.id)
                state.isSubscribed = true
                return .none

            case .unsubscribeButtonTapped:
                guard let journey = state.journey else { return .none }
                habitsService.removeJourney(journey.id)
                state.isSubscribed = false
                return .none

            case .duaTapped, .dismiss:
                return .none
            }
        }
    }
}
```

---

### Task 2.5: Create Journey Detail View

**File**: `RIZQ/Features/Journeys/JourneyDetailView.swift`

**Match React's JourneyDetailPage Layout**:

```swift
struct JourneyDetailView: View {
    @Bindable var store: StoreOf<JourneyDetailFeature>

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Header
                journeyHeader

                // Stats Row
                statsRow

                // Duas by Time Slot
                duasSection

                // Subscribe/Unsubscribe Button
                actionButton
            }
            .padding()
        }
        .navigationTitle(store.journey?.name ?? "Journey")
        .navigationBarTitleDisplayMode(.inline)
        .task { store.send(.onAppear) }
    }

    private var journeyHeader: some View {
        VStack(spacing: 12) {
            // Emoji icon
            Text(store.journey?.emoji ?? "📿")
                .font(.system(size: 64))

            Text(store.journey?.name ?? "")
                .font(.title2.bold())

            if let description = store.journey?.description {
                Text(description)
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
        }
    }

    private var statsRow: some View {
        HStack(spacing: 24) {
            StatItem(
                icon: "clock",
                value: "\(store.journey?.estimatedMinutes ?? 0)",
                label: "minutes"
            )
            StatItem(
                icon: "star.fill",
                value: "\(store.totalXp)",
                label: "XP daily"
            )
            StatItem(
                icon: "repeat",
                value: "\(store.journeyDuas.count)",
                label: "duas"
            )
        }
    }

    private var duasSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            ForEach([TimeSlot.morning, .anytime, .evening], id: \.self) { slot in
                if let duas = store.duasByTimeSlot[slot], !duas.isEmpty {
                    TimeSlotSection(slot: slot, duas: duas) { dua in
                        store.send(.duaTapped(dua))
                    }
                }
            }
        }
    }

    private var actionButton: some View {
        Button {
            if store.isSubscribed {
                store.send(.unsubscribeButtonTapped)
            } else {
                store.send(.subscribeButtonTapped)
            }
        } label: {
            HStack {
                Image(systemName: store.isSubscribed ? "minus.circle" : "plus.circle")
                Text(store.isSubscribed ? "Remove from Daily Adkhar" : "Add to Daily Adkhar")
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(store.isSubscribed ? Color.red.opacity(0.1) : Color.accentColor)
            .foregroundStyle(store.isSubscribed ? .red : .white)
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }
}
```

---

### Task 2.6: Update Journeys View

**File**: `RIZQ/Features/Journeys/JourneysView.swift`

**Match React's JourneysPage Layout**:

1. **Featured Section**: Horizontal scroll of featured journeys
2. **Active Section**: User's subscribed journeys (if any)
3. **All Journeys Section**: Grid/list of regular journeys

```swift
var body: some View {
    ScrollView {
        LazyVStack(spacing: 24) {
            // Featured Journeys
            if !store.featuredJourneys.isEmpty {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Featured")
                        .font(.title3.bold())
                        .padding(.horizontal)

                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 16) {
                            ForEach(store.featuredJourneys) { journey in
                                FeaturedJourneyCard(journey: journey) {
                                    store.send(.journeyTapped(journey))
                                }
                            }
                        }
                        .padding(.horizontal)
                    }
                }
            }

            // Active Journeys
            if !store.activeJourneys.isEmpty {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Your Journeys")
                        .font(.title3.bold())
                        .padding(.horizontal)

                    ForEach(store.activeJourneys) { journey in
                        JourneyCard(journey: journey, isActive: true) {
                            store.send(.journeyTapped(journey))
                        }
                        .padding(.horizontal)
                    }
                }
            }

            // All Journeys
            VStack(alignment: .leading, spacing: 12) {
                Text("Explore")
                    .font(.title3.bold())
                    .padding(.horizontal)

                ForEach(store.regularJourneys) { journey in
                    JourneyCard(
                        journey: journey,
                        isActive: store.activeJourneyIds.contains(journey.id)
                    ) {
                        store.send(.journeyTapped(journey))
                    }
                    .padding(.horizontal)
                }
            }
        }
        .padding(.vertical)
    }
}
```

---

### Task 2.7: Connect Category Filtering

**File**: `RIZQ/Features/Library/LibraryFeature.swift`

**Fetch categories from database**:

```swift
case .onAppear:
    state.loadingState = .loading
    return .merge(
        .run { send in
            await send(.duasLoaded(TaskResult {
                try await neonService.fetchAllDuas()
            }))
        },
        .run { send in
            await send(.categoriesLoaded(TaskResult {
                try await neonService.fetchCategories()
            }))
        }
    )

case .categoriesLoaded(.success(let categories)):
    state.categories = categories
    return .none
```

**Category Filter View**:
```swift
ScrollView(.horizontal, showsIndicators: false) {
    HStack(spacing: 8) {
        CategoryPill(
            name: "All",
            isSelected: store.selectedCategory == nil
        ) {
            store.send(.categorySelected(nil))
        }

        ForEach(store.categories) { category in
            CategoryPill(
                name: category.name,
                emoji: category.slug.emoji,
                isSelected: store.selectedCategory == category.slug
            ) {
                store.send(.categorySelected(category.slug))
            }
        }
    }
    .padding(.horizontal)
}
```

---

## Verification Checklist

- [ ] Library shows 10 duas from database
- [ ] Library search filters real data
- [ ] Library category filter works correctly
- [ ] Library loading/error states display properly
- [ ] Journeys shows 14 journeys with featured section
- [ ] Journey detail shows full dua list grouped by time slot
- [ ] Subscribe/unsubscribe updates UI and persists
- [ ] Navigation between features works correctly

---

## Files Modified/Created

| File | Action | Description |
|------|--------|-------------|
| `LibraryFeature.swift` | MODIFY | Add database fetching, loading states |
| `LibraryView.swift` | MODIFY | Add loading/error UI |
| `JourneysFeature.swift` | MODIFY | Enhance with sections |
| `JourneysView.swift` | MODIFY | Match React layout |
| `JourneyDetailFeature.swift` | CREATE/MODIFY | Full detail feature |
| `JourneyDetailView.swift` | CREATE/MODIFY | Match React preview |

---

## Estimated Effort

| Task | Complexity | Estimate |
|------|------------|----------|
| 2.1 Library Feature | Medium | 1.5 hours |
| 2.2 Library View | Low | 45 min |
| 2.3 Journeys Feature | Low | 30 min |
| 2.4 Journey Detail Feature | Medium | 1.5 hours |
| 2.5 Journey Detail View | Medium | 1.5 hours |
| 2.6 Journeys View Update | Medium | 1 hour |
| 2.7 Category Filtering | Low | 45 min |
| **Total** | | **~7.5 hours** |

---

## Dependencies

- **Prerequisites**: Phase 1 complete (database layer working)
- **Blockers**: None
- **Enables**: Phase 4 (Habits system needs journeys working)
