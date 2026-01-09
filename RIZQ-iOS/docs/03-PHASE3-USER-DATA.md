# Phase 3: User Data & Gamification

> **Objective**: Connect user profiles, XP, levels, and streaks to persistent storage

## Overview

This phase focuses on the user data layer - ensuring that XP earned, levels achieved, and streaks maintained are properly tracked and persisted across sessions.

---

## Architecture Decision

### Data Split
- **Firestore**: User profiles, activity, progress (already partially integrated)
- **Neon**: Read-only content data (duas, journeys)

### Why Firestore for User Data?
1. Real-time sync capabilities (future feature)
2. Already has Firebase Auth integration
3. Better for user-specific data vs. shared content
4. Offline persistence built-in

---

## Current State

### Existing Files
```
RIZQKit/Services/Firebase/
├── FirestoreService.swift       # User data CRUD - EXISTS
├── FirebaseAuthService.swift    # Auth integration - EXISTS
└── FirebaseNeonService.swift    # Hybrid adapter - EXISTS
```

### FirestoreService Current Implementation
- Has `UserProfile` CRUD methods
- Has activity tracking methods
- Uses Firebase SDK directly
- **Issue**: Not fully integrated with TCA features

---

## Tasks

### Task 3.1: Audit FirestoreService

**File**: `RIZQKit/Services/Firebase/FirestoreService.swift`

**Verify these methods exist and work**:
```swift
// User Profile
func getProfile(userId: String) async throws -> UserProfile?
func createProfile(userId: String, displayName: String?) async throws -> UserProfile
func updateProfile(_ profile: UserProfile) async throws
func updateXp(userId: String, amount: Int) async throws

// Activity Tracking
func recordDuaCompletion(userId: String, duaId: Int, xpEarned: Int) async throws
func getTodayActivity(userId: String) async throws -> UserActivity?
func getWeekActivities(userId: String) async throws -> [UserActivity]

// Progress Tracking
func getDuaProgress(userId: String, duaId: Int) async throws -> UserProgress?
func updateDuaProgress(userId: String, duaId: Int) async throws
```

**Add if missing**:
```swift
// Streak Management
func updateStreak(userId: String) async throws -> Int {
    let profile = try await getProfile(userId: userId)
    let today = Calendar.current.startOfDay(for: Date())

    guard let lastActive = profile?.lastActiveDate else {
        // First activity - start streak at 1
        try await updateProfileStreak(userId: userId, streak: 1, lastActive: today)
        return 1
    }

    let daysSinceLastActive = Calendar.current.dateComponents(
        [.day], from: lastActive, to: today
    ).day ?? 0

    let newStreak: Int
    switch daysSinceLastActive {
    case 0:
        // Same day - no change
        newStreak = profile?.streak ?? 1
    case 1:
        // Consecutive day - increment
        newStreak = (profile?.streak ?? 0) + 1
    default:
        // Missed days - reset
        newStreak = 1
    }

    try await updateProfileStreak(userId: userId, streak: newStreak, lastActive: today)
    return newStreak
}

// Level Calculation (matches React formula)
func calculateLevel(from xp: Int) -> Int {
    var level = 1
    while 50 * level * level + 50 * level <= xp {
        level += 1
    }
    return level
}

func xpForLevel(_ level: Int) -> Int {
    return 50 * level * level + 50 * level
}

func xpProgressInLevel(totalXp: Int, level: Int) -> (current: Int, needed: Int) {
    let previousLevelXp = level > 1 ? xpForLevel(level - 1) : 0
    let currentLevelXp = xpForLevel(level)
    let current = totalXp - previousLevelXp
    let needed = currentLevelXp - previousLevelXp
    return (current, needed)
}
```

---

### Task 3.2: Create User Data TCA Client

**File**: `RIZQKit/Services/UserDataClient.swift` (NEW)

**Purpose**: TCA-compatible wrapper around FirestoreService

```swift
import ComposableArchitecture
import Foundation

@DependencyClient
struct UserDataClient {
    // Profile
    var getProfile: @Sendable (_ userId: String) async throws -> UserProfile?
    var createProfile: @Sendable (_ userId: String, _ displayName: String?) async throws -> UserProfile
    var updateProfile: @Sendable (_ profile: UserProfile) async throws -> Void

    // XP & Level
    var addXp: @Sendable (_ userId: String, _ amount: Int) async throws -> UserProfile

    // Streak
    var updateStreak: @Sendable (_ userId: String) async throws -> Int

    // Activity
    var recordCompletion: @Sendable (_ userId: String, _ duaId: Int, _ xp: Int) async throws -> Void
    var getTodayActivity: @Sendable (_ userId: String) async throws -> UserActivity?
    var getWeekActivities: @Sendable (_ userId: String) async throws -> [UserActivity]

    // Progress
    var getDuaProgress: @Sendable (_ userId: String, _ duaId: Int) async throws -> UserProgress?
    var markDuaCompleted: @Sendable (_ userId: String, _ duaId: Int) async throws -> Void
}

extension UserDataClient: DependencyKey {
    static let liveValue: UserDataClient = {
        let service = FirestoreService.shared

        return UserDataClient(
            getProfile: { userId in
                try await service.getProfile(userId: userId)
            },
            createProfile: { userId, displayName in
                try await service.createProfile(userId: userId, displayName: displayName)
            },
            updateProfile: { profile in
                try await service.updateProfile(profile)
            },
            addXp: { userId, amount in
                try await service.addXp(userId: userId, amount: amount)
            },
            updateStreak: { userId in
                try await service.updateStreak(userId: userId)
            },
            recordCompletion: { userId, duaId, xp in
                try await service.recordDuaCompletion(userId: userId, duaId: duaId, xpEarned: xp)
            },
            getTodayActivity: { userId in
                try await service.getTodayActivity(userId: userId)
            },
            getWeekActivities: { userId in
                try await service.getWeekActivities(userId: userId)
            },
            getDuaProgress: { userId, duaId in
                try await service.getDuaProgress(userId: userId, duaId: duaId)
            },
            markDuaCompleted: { userId, duaId in
                try await service.updateDuaProgress(userId: userId, duaId: duaId)
            }
        )
    }()

    static let previewValue = UserDataClient(
        getProfile: { _ in UserProfile.preview },
        createProfile: { _, name in UserProfile(userId: "preview", displayName: name, streak: 0, totalXp: 0, level: 1) },
        updateProfile: { _ in },
        addXp: { _, amount in UserProfile(userId: "preview", displayName: nil, streak: 1, totalXp: amount, level: 1) },
        updateStreak: { _ in 1 },
        recordCompletion: { _, _, _ in },
        getTodayActivity: { _ in nil },
        getWeekActivities: { _ in [] },
        getDuaProgress: { _, _ in nil },
        markDuaCompleted: { _, _ in }
    )
}

extension DependencyValues {
    var userDataClient: UserDataClient {
        get { self[UserDataClient.self] }
        set { self[UserDataClient.self] = newValue }
    }
}
```

---

### Task 3.3: Update Home Feature with Real Data

**File**: `RIZQ/Features/Home/HomeFeature.swift`

**Current**: Uses demo data with simulated delays

**Target**: Fetch real profile and activity data

```swift
@Reducer
struct HomeFeature {
    @ObservableState
    struct State: Equatable {
        var profile: UserProfile?
        var todayActivity: UserActivity?
        var weekActivities: [UserActivity?] = []
        var loadingState: LoadingState = .idle

        // Computed
        var displayName: String {
            profile?.displayName ?? "Seeker"
        }
        var streak: Int {
            profile?.streak ?? 0
        }
        var totalXp: Int {
            profile?.totalXp ?? 0
        }
        var level: Int {
            profile?.level ?? 1
        }
        var xpProgress: Double {
            guard let profile else { return 0 }
            let (current, needed) = LevelCalculator.xpProgressInLevel(
                totalXp: profile.totalXp,
                level: profile.level
            )
            return Double(current) / Double(max(needed, 1))
        }
        var todayXpEarned: Int {
            todayActivity?.xpEarned ?? 0
        }
        var todayDuasCompleted: Int {
            todayActivity?.duasCompleted.count ?? 0
        }
    }

    enum Action {
        case onAppear
        case profileLoaded(TaskResult<UserProfile?, Error>)
        case activityLoaded(TaskResult<(UserActivity?, [UserActivity?]), Error>)
        case refreshTapped
    }

    @Dependency(\.userDataClient) var userDataClient
    @Dependency(\.authClient) var authClient

    var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .onAppear:
                guard let userId = authClient.currentUserId else {
                    state.loadingState = .error("Not authenticated")
                    return .none
                }
                state.loadingState = .loading
                return .merge(
                    .run { send in
                        await send(.profileLoaded(TaskResult {
                            try await userDataClient.getProfile(userId)
                        }))
                    },
                    .run { send in
                        await send(.activityLoaded(TaskResult {
                            let today = try await userDataClient.getTodayActivity(userId)
                            let week = try await userDataClient.getWeekActivities(userId)
                            return (today, week)
                        }))
                    }
                )

            case .profileLoaded(.success(let profile)):
                state.profile = profile
                state.loadingState = .loaded
                return .none

            case .profileLoaded(.failure(let error)):
                state.loadingState = .error(error.localizedDescription)
                return .none

            case .activityLoaded(.success(let (today, week))):
                state.todayActivity = today
                state.weekActivities = week
                return .none

            case .activityLoaded(.failure):
                // Non-critical - don't show error
                return .none

            case .refreshTapped:
                return .send(.onAppear)
            }
        }
    }
}
```

---

### Task 3.4: Update Home View

**File**: `RIZQ/Features/Home/HomeView.swift`

**Match React's HomePage Layout**:

```swift
struct HomeView: View {
    @Bindable var store: StoreOf<HomeFeature>

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Greeting Header
                greetingHeader

                // Stats Card
                statsCard

                // Week Calendar
                weekCalendar

                // Today's Progress
                todayProgress

                // Quick Actions
                quickActions
            }
            .padding()
        }
        .task { store.send(.onAppear) }
    }

    private var greetingHeader: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(greeting)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                Text(store.displayName)
                    .font(.title2.bold())
            }
            Spacer()
            StreakBadge(count: store.streak)
        }
    }

    private var statsCard: some View {
        HStack(spacing: 24) {
            // Level + XP Ring
            CircularXpProgress(
                level: store.level,
                progress: store.xpProgress
            )

            VStack(alignment: .leading, spacing: 8) {
                Text("Level \(store.level)")
                    .font(.headline)
                Text("\(store.totalXp) XP total")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                XpProgressBar(progress: store.xpProgress)
            }
        }
        .padding()
        .background(.card)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private var weekCalendar: some View {
        HStack(spacing: 8) {
            ForEach(0..<7, id: \.self) { dayOffset in
                let date = Calendar.current.date(
                    byAdding: .day,
                    value: dayOffset - 6,
                    to: Date()
                )!
                let activity = store.weekActivities[safe: dayOffset] ?? nil

                WeekDayCell(
                    date: date,
                    hasActivity: activity != nil,
                    isToday: dayOffset == 6
                )
            }
        }
    }

    private var todayProgress: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Today")
                .font(.headline)

            HStack {
                StatItem(
                    icon: "checkmark.circle.fill",
                    value: "\(store.todayDuasCompleted)",
                    label: "duas"
                )
                Spacer()
                StatItem(
                    icon: "star.fill",
                    value: "\(store.todayXpEarned)",
                    label: "XP earned"
                )
            }
        }
        .padding()
        .background(.card)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private var greeting: String {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 0..<12: return "Good morning"
        case 12..<17: return "Good afternoon"
        default: return "Good evening"
        }
    }
}
```

---

### Task 3.5: Update Practice Feature for XP Award

**File**: `RIZQ/Features/Practice/PracticeFeature.swift`

**Current**: Awards XP but may not persist to database

**Add to completion action**:
```swift
case .duaCompleted:
    state.isCompleted = true
    let xpEarned = state.dua?.xpValue ?? 10

    return .run { [duaId = state.dua?.id] send in
        guard let userId = authClient.currentUserId,
              let duaId else { return }

        // Record completion and XP
        try await userDataClient.recordCompletion(userId, duaId, xpEarned)
        try await userDataClient.markDuaCompleted(userId, duaId)
        let _ = try await userDataClient.updateStreak(userId)
        let updatedProfile = try await userDataClient.addXp(userId, xpEarned)

        await send(.xpAwarded(xpEarned, newTotal: updatedProfile.totalXp))
    }

case .xpAwarded(let amount, let newTotal):
    // Trigger celebration animation
    state.xpEarnedAmount = amount
    state.showXpAnimation = true
    return .none
```

---

### Task 3.6: Create Shared User State

**File**: `RIZQ/App/SharedUserState.swift` (NEW)

**Purpose**: Broadcast user profile updates across features

```swift
import ComposableArchitecture

// Shared state that multiple features can observe
struct SharedUserState: Equatable {
    var profile: UserProfile?
    var isAuthenticated: Bool { profile != nil }
}

// Action to update shared state from any feature
enum SharedUserAction: Equatable {
    case profileUpdated(UserProfile?)
    case xpEarned(Int)
    case streakUpdated(Int)
}

// Extend features to receive shared updates
extension AppFeature {
    func handleSharedUserAction(_ action: SharedUserAction) -> Effect<Action> {
        switch action {
        case .profileUpdated(let profile):
            // Broadcast to home feature
            return .send(.home(.profileLoaded(.success(profile))))

        case .xpEarned(let amount):
            // Could trigger global celebration
            return .none

        case .streakUpdated:
            return .none
        }
    }
}
```

---

## Verification Checklist

- [ ] Home page loads real profile data on appear
- [ ] XP, level, streak display correctly from Firestore
- [ ] Week calendar shows actual activity days
- [ ] Completing a dua awards XP and persists to Firestore
- [ ] Streak increments on consecutive days
- [ ] Streak resets after missed day
- [ ] Level calculates correctly using formula (50L² + 50L)
- [ ] Profile updates reflect across app without restart

---

## Files Modified/Created

| File | Action | Description |
|------|--------|-------------|
| `FirestoreService.swift` | MODIFY | Add missing methods, fix streak logic |
| `UserDataClient.swift` | CREATE | TCA dependency client |
| `HomeFeature.swift` | MODIFY | Real data fetching |
| `HomeView.swift` | MODIFY | Match React layout |
| `PracticeFeature.swift` | MODIFY | Persist XP awards |
| `SharedUserState.swift` | CREATE | Cross-feature state sync |

---

## Estimated Effort

| Task | Complexity | Estimate |
|------|------------|----------|
| 3.1 Audit FirestoreService | Medium | 1 hour |
| 3.2 UserDataClient | Medium | 1.5 hours |
| 3.3 Home Feature | Medium | 1.5 hours |
| 3.4 Home View | Medium | 1.5 hours |
| 3.5 Practice XP | Low | 45 min |
| 3.6 Shared State | Medium | 1 hour |
| **Total** | | **~7.25 hours** |

---

## Dependencies

- **Prerequisites**: Phase 1 (database layer), Firebase configured
- **Blockers**: Firebase Firestore must be set up
- **Enables**: Phase 4 (habits use user data for completions)
