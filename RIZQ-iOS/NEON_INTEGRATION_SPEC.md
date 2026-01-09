# iOS Neon Database Integration Specification

> **Purpose**: Connect the RIZQ iOS app to Neon PostgreSQL for live data instead of mock SampleData.
> **Architecture**: Hybrid (Neon for content, Firebase for user data)
> **Last Updated**: January 2026

---

## Table of Contents

1. [Executive Summary](#executive-summary)
2. [Current State Analysis](#current-state-analysis)
3. [Available Tools & Skills](#available-tools--skills)
4. [Phase 1: Configuration](#phase-1-configuration)
5. [Phase 2: Journeys Integration](#phase-2-journeys-integration)
6. [Phase 3: Adkhar Integration](#phase-3-adkhar-integration)
7. [Phase 4: Persistence & Sync](#phase-4-persistence--sync)
8. [Phase 5: Testing & Verification](#phase-5-testing--verification)
9. [Code Reference](#code-reference)
10. [Troubleshooting Guide](#troubleshooting-guide)

---

## Executive Summary

### What We're Building

The iOS app currently uses hardcoded mock data (`SampleData`) in its TCA features. The backend infrastructure (`NeonService`, `APIClient`) is already complete but not connected to the UI. This spec details how to wire everything together.

### Scope

| In Scope | Out of Scope |
|----------|--------------|
| Connect Journeys tab to Neon | Migrating content to Firebase |
| Connect Daily Adkhar to Neon | Offline caching for content |
| Persist habit completions to Firestore | Admin panel changes |
| Load user streak/XP from Firestore | New features |

### Success Criteria

- [ ] Journeys tab displays live data from Neon
- [ ] Subscribing to a journey loads its duas in Daily Adkhar
- [ ] Completing a habit updates Firestore
- [ ] User XP/streak reflects completions

---

## Current State Analysis

### Architecture Overview

```
┌─────────────────────────────────────────────────────────────────┐
│                         iOS App (SwiftUI + TCA)                 │
├─────────────────────────────────────────────────────────────────┤
│  Features (TCA Reducers)                                        │
│  ┌──────────────────┐  ┌──────────────────┐  ┌───────────────┐ │
│  │ JourneysFeature  │  │  AdkharFeature   │  │PracticeFeature│ │
│  │ ❌ Uses SampleData │  │ ❌ Hardcoded data │  │ ✅ Works       │ │
│  └────────┬─────────┘  └────────┬─────────┘  └───────────────┘ │
│           │                      │                               │
│           ▼                      ▼                               │
│  ┌──────────────────────────────────────────────────────────┐   │
│  │              ServiceContainer (Dependency Injection)      │   │
│  │  ┌──────────────────────────────────────────────────────┐│   │
│  │  │        FirebaseNeonService (Adapter Pattern)         ││   │
│  │  │  ┌─────────────────┐    ┌─────────────────────┐     ││   │
│  │  │  │   NeonService   │    │   FirestoreService   │     ││   │
│  │  │  │ ✅ Complete      │    │   ✅ Complete         │     ││   │
│  │  │  │ (Content Data)  │    │   (User Data)        │     ││   │
│  │  │  └────────┬────────┘    └──────────┬──────────┘     ││   │
│  │  └───────────┼────────────────────────┼────────────────┘│   │
│  └──────────────┼────────────────────────┼─────────────────┘   │
└─────────────────┼────────────────────────┼──────────────────────┘
                  │                        │
                  ▼                        ▼
        ┌─────────────────┐      ┌─────────────────┐
        │ Neon PostgreSQL │      │    Firebase     │
        │  (HTTP SQL API) │      │   Firestore     │
        │                 │      │                 │
        │ • duas          │      │ • user_profiles │
        │ • journeys      │      │ • user_activity │
        │ • categories    │      │ • user_progress │
        │ • collections   │      │                 │
        │ • journey_duas  │      │                 │
        └─────────────────┘      └─────────────────┘
```

### Files Status

| File | Status | Description |
|------|--------|-------------|
| `RIZQKit/Services/API/NeonService.swift` | ✅ Complete | Queries Neon via HTTP SQL API |
| `RIZQKit/Services/API/APIClient.swift` | ✅ Complete | HTTP transport layer |
| `RIZQKit/Services/Firebase/FirestoreService.swift` | ✅ Complete | User data CRUD |
| `RIZQKit/Services/Firebase/FirebaseNeonService.swift` | ✅ Complete | Adapter combining both |
| `RIZQKit/Services/Dependencies.swift` | ✅ Complete | ServiceContainer DI |
| `RIZQ/Features/Journeys/JourneysFeature.swift` | ❌ Mock | Line 193 returns SampleData |
| `RIZQ/Features/Adkhar/AdkharFeature.swift` | ❌ Mock | Lines 111-174 hardcoded |
| `RIZQ/Info.plist` | ❌ Missing | No Neon credentials |

### Database Schema (Neon)

```sql
-- Content tables (read-only from app)
duas (id, title_en, arabic_text, transliteration, translation_en, source,
      repetitions, best_time, difficulty, rizq_benefit, context,
      prophetic_context, xp_value, category_id, collection_id)

journeys (id, name, slug, description, emoji, estimated_minutes,
          daily_xp, is_premium, is_featured, sort_order)

journey_duas (journey_id, dua_id, time_slot, sort_order)

categories (id, name, slug, description)

collections (id, name, slug, description, is_premium)
```

---

## Available Tools & Skills

### Claude Code Plugins

Located in `.claude/plugins/`:

| Plugin | Agents | Skills | Use Case |
|--------|--------|--------|----------|
| `rizq-ios` | `auth-architect`, `firebase-integrator` | `auth-patterns-ios`, `firestore-patterns` | iOS-specific Firebase patterns |
| `firebase` | `firebase-setup`, `firebase-auth-integrator`, `firebase-debugger` | `firebase-auth-patterns`, `firebase-config`, `firestore-patterns` | Firebase configuration |

### MCP Tools (Firebase)

Available via `mcp__plugin_firebase_firebase__*`:

| Tool | Purpose |
|------|---------|
| `firebase_get_environment` | Check current Firebase project/auth state |
| `firebase_get_project` | Get active project details |
| `firestore_list_collections` | List Firestore collections |
| `firestore_get_documents` | Fetch documents by path |
| `firestore_query_collection` | Query with filters |
| `auth_get_users` | Fetch Firebase Auth users |

### Xcode Tools

| Tool | Purpose |
|------|---------|
| Build & Run | Test changes in simulator |
| Console | Debug network requests, view logs |
| Network Debugger | Inspect HTTP requests to Neon |

### CLI Commands

```bash
# Build iOS app
cd RIZQ-iOS && xcodebuild -scheme RIZQ -destination 'platform=iOS Simulator,name=iPhone 15'

# Run tests
xcodebuild test -scheme RIZQ -destination 'platform=iOS Simulator,name=iPhone 15'

# Check Neon connection (from web app)
npm run db:check  # If script exists
```

---

## Phase 1: Configuration

### Task 1.1: Add Neon Credentials to Info.plist

**File**: `RIZQ-iOS/RIZQ/Info.plist`

**What to add** (inside `<dict>`):

```xml
<key>NeonHost</key>
<string>YOUR_NEON_HOST.neon.tech</string>
<key>NeonApiKey</key>
<string>YOUR_NEON_API_KEY</string>
<key>NeonProjectId</key>
<string>YOUR_PROJECT_ID</string>
```

**Where to get values**:
1. Web app's `.env` file: `VITE_DATABASE_URL` contains the host
2. Neon Console → Project Settings → API Keys

**Security considerations**:
- For production, use Xcode build configurations
- Consider `.xcconfig` files for different environments
- Never commit API keys to git (add to `.gitignore`)

### Task 1.2: Verify ServiceContainer Configuration

**File**: `RIZQKit/Services/Dependencies.swift`

Verify that `configure()` method properly initializes services:

```swift
public func configure(with configuration: AppConfiguration) {
    let apiConfig = configuration.api
    let apiClient = APIClient(
        host: apiConfig.neonHost,
        apiKey: apiConfig.neonApiKey,
        projectId: apiConfig.neonProjectId
    )
    let neonService = NeonService(apiClient: apiClient)
    let firestoreService = FirestoreService()

    self._neonService = FirebaseNeonService(
        neonService: neonService,
        firestoreService: firestoreService
    )
}
```

### Task 1.3: Verify App Initialization

**File**: `RIZQ/App/RIZQApp.swift`

Ensure `ServiceContainer.shared.configure()` is called at app launch:

```swift
@main
struct RIZQApp: App {
    init() {
        FirebaseApp.configure()
        ServiceContainer.shared.configure(with: .live)
    }
}
```

---

## Phase 2: Journeys Integration

### Task 2.1: Update JourneyServiceClient.liveValue

**File**: `RIZQ-iOS/RIZQ/Features/Journeys/JourneysFeature.swift`

**Lines to change**: 187-200

**Current code (BEFORE)**:

```swift
extension JourneyServiceClient: DependencyKey {
  static let liveValue: JourneyServiceClient = {
    JourneyServiceClient(
      fetchJourneys: {
        // TODO: Replace with actual API call
        try await Task.sleep(for: .milliseconds(500))
        return SampleData.journeys
      },
      fetchJourneyDuas: { journeyId in
        try await Task.sleep(for: .milliseconds(300))
        return SampleData.journeyDuas.filter { $0.journeyDua.journeyId == journeyId }
      }
    )
  }()
```

**New code (AFTER)**:

```swift
extension JourneyServiceClient: DependencyKey {
  static let liveValue: JourneyServiceClient = {
    // Get the neonService from ServiceContainer
    // Note: This captures the service at initialization time

    return JourneyServiceClient(
      fetchJourneys: {
        let neonService = ServiceContainer.shared.neonService
        return try await neonService.fetchAllJourneys()
      },
      fetchJourneyDuas: { journeyId in
        let neonService = ServiceContainer.shared.neonService
        return try await neonService.fetchJourneyDuas(journeyId: journeyId)
      }
    )
  }()
```

### Task 2.2: Add Error Handling UI

**File**: `RIZQ-iOS/RIZQ/Features/Journeys/JourneysView.swift`

Ensure the view handles error states gracefully:

```swift
if let error = store.errorMessage {
    VStack {
        Image(systemName: "wifi.slash")
        Text("Unable to load journeys")
        Text(error)
            .font(.caption)
            .foregroundColor(.secondary)
        Button("Retry") {
            store.send(.onAppear)
        }
    }
}
```

### Task 2.3: Test Journeys Loading

**Verification steps**:
1. Run app in simulator
2. Navigate to Journeys tab
3. Should see loading spinner, then journeys from database
4. Check Xcode console for any network errors
5. Tap a journey → should load its duas

---

## Phase 3: Adkhar Integration

### Task 3.1: Create AdkharServiceClient

**File**: `RIZQ-iOS/RIZQ/Features/Adkhar/AdkharFeature.swift`

**Add after line 325** (after `Habit` struct):

```swift
// MARK: - Adkhar Service Client

struct AdkharServiceClient: Sendable {
  var fetchHabitsForJourneys: @Sendable ([Int]) async throws -> (morning: [Habit], anytime: [Habit], evening: [Habit])
  var fetchStreak: @Sendable (String) async throws -> Int
  var recordCompletion: @Sendable (String, Int, Int) async throws -> Void
}

extension AdkharServiceClient: DependencyKey {
  static let liveValue: AdkharServiceClient = {
    return AdkharServiceClient(
      fetchHabitsForJourneys: { journeyIds in
        let neonService = ServiceContainer.shared.neonService

        var morning: [Habit] = []
        var anytime: [Habit] = []
        var evening: [Habit] = []

        for journeyId in journeyIds {
          let journeyDuas = try await neonService.fetchJourneyDuas(journeyId: journeyId)

          for jd in journeyDuas {
            let habit = Habit(
              id: jd.dua.id,
              duaId: jd.dua.id,
              titleEn: jd.dua.titleEn,
              arabicText: jd.dua.arabicText,
              transliteration: jd.dua.transliteration,
              translation: jd.dua.translationEn,
              source: jd.dua.source,
              rizqBenefit: jd.dua.rizqBenefit,
              propheticContext: jd.dua.propheticContext,
              timeSlot: jd.journeyDua.timeSlot,
              xpValue: jd.dua.xpValue,
              repetitions: jd.dua.repetitions
            )

            switch jd.journeyDua.timeSlot {
            case .morning: morning.append(habit)
            case .anytime: anytime.append(habit)
            case .evening: evening.append(habit)
            }
          }
        }

        // Sort by ID for consistent ordering
        morning.sort { $0.id < $1.id }
        anytime.sort { $0.id < $1.id }
        evening.sort { $0.id < $1.id }

        return (morning: morning, anytime: anytime, evening: evening)
      },

      fetchStreak: { userId in
        let neonService = ServiceContainer.shared.neonService
        let profile = try await neonService.fetchUserProfile(userId: userId)
        return profile?.streak ?? 0
      },

      recordCompletion: { userId, duaId, xpEarned in
        let neonService = ServiceContainer.shared.neonService
        try await neonService.recordDuaCompletion(
          userId: userId,
          duaId: duaId,
          xpEarned: xpEarned
        )
      }
    )
  }()

  static let testValue = AdkharServiceClient(
    fetchHabitsForJourneys: { _ in ([], [], []) },
    fetchStreak: { _ in 7 },
    recordCompletion: { _, _, _ in }
  )

  static let previewValue = AdkharServiceClient(
    fetchHabitsForJourneys: { _ in
      // Return sample habits for previews
      let morning = [
        Habit(id: 1, duaId: 1, titleEn: "Morning Remembrance",
              arabicText: "أَصْبَحْنَا وَأَصْبَحَ الْمُلْكُ لِلَّهِ",
              transliteration: "Asbahna wa asbahal mulku lillah",
              translation: "We have reached the morning...",
              source: "Muslim", rizqBenefit: nil, propheticContext: nil,
              timeSlot: .morning, xpValue: 10, repetitions: 3)
      ]
      return (morning, [], [])
    },
    fetchStreak: { _ in 7 },
    recordCompletion: { _, _, _ in }
  )
}

extension DependencyValues {
  var adkharService: AdkharServiceClient {
    get { self[AdkharServiceClient.self] }
    set { self[AdkharServiceClient.self] = newValue }
  }
}
```

### Task 3.2: Add Dependency to AdkharFeature

**File**: `RIZQ-iOS/RIZQ/Features/Adkhar/AdkharFeature.swift`

**Add after line 98** (after existing dependencies):

```swift
@Dependency(\.adkharService) var adkharService
```

### Task 3.3: Update onAppear Action

**File**: `RIZQ-iOS/RIZQ/Features/Adkhar/AdkharFeature.swift`

**Replace lines 103-178** (the `.onAppear` case):

```swift
case .onAppear:
  state.isLoading = true

  return .run { [adkharService] send in
    // Load subscribed journey IDs from UserDefaults
    let subscribedIds = loadSubscribedJourneyIds()

    // If no subscriptions, show empty state
    guard !subscribedIds.isEmpty else {
      await send(.habitsLoaded(morning: [], anytime: [], evening: []))
      await send(.streakLoaded(0))
      return
    }

    do {
      // Fetch habits from subscribed journeys
      let habits = try await adkharService.fetchHabitsForJourneys(Array(subscribedIds))

      // Fetch streak (requires auth)
      var streak = 0
      if let userId = await getCurrentUserId() {
        streak = try await adkharService.fetchStreak(userId)
      }

      await send(.habitsLoaded(morning: habits.morning, anytime: habits.anytime, evening: habits.evening))
      await send(.streakLoaded(streak))

    } catch {
      // On error, show empty state
      print("Error loading habits: \(error)")
      await send(.habitsLoaded(morning: [], anytime: [], evening: []))
      await send(.streakLoaded(0))
    }
  }
```

### Task 3.4: Add Helper Functions

**File**: `RIZQ-iOS/RIZQ/Features/Adkhar/AdkharFeature.swift`

**Add at the bottom of the file**:

```swift
// MARK: - Helper Functions

private func loadSubscribedJourneyIds() -> Set<Int> {
  guard let data = UserDefaults.standard.data(forKey: "subscribedJourneyIds"),
        let ids = try? JSONDecoder().decode(Set<Int>.self, from: data) else {
    return []
  }
  return ids
}

private func getCurrentUserId() async -> String? {
  // Get from Firebase Auth
  return Auth.auth().currentUser?.uid
}
```

---

## Phase 4: Persistence & Sync

### Task 4.1: Update habitCompleted Action

**File**: `RIZQ-iOS/RIZQ/Features/Adkhar/AdkharFeature.swift`

**Replace the `.habitCompleted` case** (around line 205):

```swift
case .habitCompleted(let habit):
  let completedCount = state.completedCount
  let totalCount = state.totalHabits
  let streak = state.streak
  let xpEarned = habit.xpValue

  return .run { [adkharService] _ in
    // Update widget with current progress
    WidgetDataManager.shared.updateDailyProgress(
      completedCount: completedCount,
      totalCount: totalCount,
      streak: streak,
      currentXp: 0,  // Will be updated from profile
      xpToNextLevel: 100,
      level: 1
    )

    // Persist completion to Firestore
    guard let userId = await getCurrentUserId() else { return }

    do {
      try await adkharService.recordCompletion(userId, habit.duaId, xpEarned)
      print("Recorded completion: dua \(habit.duaId), xp: \(xpEarned)")
    } catch {
      print("Error recording completion: \(error)")
    }
  }
```

### Task 4.2: Load Today's Completions

Add logic to restore completion state when app opens:

```swift
// In .onAppear, after loading habits:
// Load today's completions from Firestore
if let userId = await getCurrentUserId() {
  let neonService = ServiceContainer.shared.neonService
  if let activity = try? await neonService.fetchUserActivity(userId: userId, date: Date()) {
    let completedIds = Set(activity.duasCompleted)
    await send(.completionsRestored(completedIds))
  }
}
```

**Add new action**:

```swift
case completionsRestored(Set<Int>)

// In reducer:
case .completionsRestored(let ids):
  state.completedIds = ids
  return .none
```

---

## Phase 5: Testing & Verification

### Manual Testing Checklist

#### Configuration
- [ ] Info.plist has valid Neon credentials
- [ ] App builds without errors
- [ ] App launches without crashes

#### Journeys Tab
- [ ] Loading spinner appears
- [ ] Journeys load from database (not SampleData)
- [ ] Journey count matches database
- [ ] Tapping journey shows detail with duas
- [ ] Subscribe button works
- [ ] Unsubscribe button works

#### Daily Adkhar
- [ ] With no subscriptions: shows empty state
- [ ] After subscribing to journey: shows that journey's duas
- [ ] Duas are grouped correctly by time slot (morning/anytime/evening)
- [ ] Arabic text displays correctly (RTL)
- [ ] Transliteration shows if available

#### Habit Completion
- [ ] Tapping habit toggles completion state
- [ ] Completion persists (close and reopen app)
- [ ] XP is added to user profile
- [ ] Widget updates with progress

#### Error Handling
- [ ] Graceful error on network failure
- [ ] Retry button works
- [ ] Fallback to empty state (not crash)

### Automated Tests

**File to create**: `RIZQ-iOS/RIZQTests/NeonIntegrationTests.swift`

```swift
import XCTest
@testable import RIZQ
@testable import RIZQKit

final class NeonIntegrationTests: XCTestCase {

  func testFetchJourneys() async throws {
    let neonService = ServiceContainer.shared.neonService
    let journeys = try await neonService.fetchAllJourneys()

    XCTAssertFalse(journeys.isEmpty, "Should fetch at least one journey")

    // Verify journey structure
    let journey = journeys.first!
    XCTAssertFalse(journey.name.isEmpty)
    XCTAssertFalse(journey.slug.isEmpty)
  }

  func testFetchJourneyDuas() async throws {
    let neonService = ServiceContainer.shared.neonService
    let journeys = try await neonService.fetchAllJourneys()

    guard let journey = journeys.first else {
      XCTFail("No journeys found")
      return
    }

    let duas = try await neonService.fetchJourneyDuas(journeyId: journey.id)
    XCTAssertFalse(duas.isEmpty, "Journey should have duas")

    // Verify dua structure
    let duaFull = duas.first!
    XCTAssertFalse(duaFull.dua.arabicText.isEmpty)
    XCTAssertNotNil(duaFull.journeyDua.timeSlot)
  }
}
```

---

## Code Reference

### Key Service Methods

#### NeonService

```swift
// Journeys
func fetchAllJourneys() async throws -> [Journey]
func fetchFeaturedJourneys() async throws -> [Journey]
func fetchJourney(id: Int) async throws -> Journey?
func fetchJourneyDuas(journeyId: Int) async throws -> [JourneyDuaFull]

// Duas
func fetchAllDuas() async throws -> [Dua]
func fetchDua(id: Int) async throws -> Dua?
func searchDuas(query: String) async throws -> [Dua]

// Categories
func fetchAllCategories() async throws -> [DuaCategory]

// User (delegated to FirestoreService)
func fetchUserProfile(userId: String) async throws -> UserProfile?
func createUserProfile(userId: String) async throws -> UserProfile
func addXp(userId: String, amount: Int) async throws
func recordDuaCompletion(userId: String, duaId: Int, xpEarned: Int) async throws
```

#### ServiceContainer

```swift
// Access the shared container
ServiceContainer.shared

// Get services
ServiceContainer.shared.neonService  // -> NeonServiceProtocol
ServiceContainer.shared.authService  // -> AuthServiceProtocol

// Configure (call at app launch)
ServiceContainer.shared.configure(with: .live)
```

### Model Mappings

#### Dua (Database → Swift)

| Database Column | Swift Property | Type |
|-----------------|----------------|------|
| `id` | `id` | `Int` |
| `title_en` | `titleEn` | `String` |
| `title_ar` | `titleAr` | `String?` |
| `arabic_text` | `arabicText` | `String` |
| `transliteration` | `transliteration` | `String?` |
| `translation_en` | `translationEn` | `String` |
| `source` | `source` | `String?` |
| `repetitions` | `repetitions` | `Int` |
| `best_time` | `bestTime` | `TimeSlot?` |
| `difficulty` | `difficulty` | `DuaDifficulty` |
| `rizq_benefit` | `rizqBenefit` | `String?` |
| `context` | `context` | `String?` |
| `prophetic_context` | `propheticContext` | `String?` |
| `xp_value` | `xpValue` | `Int` |

---

## Troubleshooting Guide

### Common Issues

#### "No journeys displayed"

**Symptoms**: Journeys tab shows empty or loading forever

**Possible causes**:
1. Missing Neon credentials in Info.plist
2. Invalid API key
3. Network connectivity issue

**Debug steps**:
```swift
// Add to JourneyServiceClient.fetchJourneys
print("Fetching journeys...")
let result = try await neonService.fetchAllJourneys()
print("Fetched \(result.count) journeys")
return result
```

#### "Empty habits despite subscriptions"

**Symptoms**: Daily Adkhar shows empty even after subscribing

**Possible causes**:
1. Subscribed journey IDs not persisting
2. Journey has no duas in database
3. UserDefaults key mismatch

**Debug steps**:
```swift
let ids = loadSubscribedJourneyIds()
print("Subscribed IDs: \(ids)")

for id in ids {
  let duas = try await neonService.fetchJourneyDuas(journeyId: id)
  print("Journey \(id) has \(duas.count) duas")
}
```

#### "Completion not persisting"

**Symptoms**: Completions reset when app restarts

**Possible causes**:
1. User not authenticated
2. Firestore write failing
3. Completion restore not implemented

**Debug steps**:
1. Check Firebase Auth state: `Auth.auth().currentUser`
2. Check Firestore Console for `user_activity` collection
3. Add try/catch with error logging

### Xcode Console Commands

```swift
// Print current user
po Auth.auth().currentUser?.uid

// Print subscribed journeys
po UserDefaults.standard.data(forKey: "subscribedJourneyIds")

// Check service container
po ServiceContainer.shared.neonService
```

---

## Appendix: File Locations

```
RIZQ-iOS/
├── RIZQ/
│   ├── App/
│   │   └── RIZQApp.swift              # App entry point
│   ├── Features/
│   │   ├── Journeys/
│   │   │   ├── JourneysFeature.swift  # ⭐ MODIFY (Phase 2)
│   │   │   └── JourneysView.swift
│   │   ├── Adkhar/
│   │   │   ├── AdkharFeature.swift    # ⭐ MODIFY (Phase 3)
│   │   │   └── AdkharView.swift
│   │   └── Practice/
│   │       └── PracticeFeature.swift
│   ├── Info.plist                      # ⭐ MODIFY (Phase 1)
│   └── Resources/
│       └── GoogleService-Info.plist
├── RIZQKit/
│   ├── Services/
│   │   ├── API/
│   │   │   ├── APIClient.swift        # ✅ Complete
│   │   │   ├── NeonService.swift      # ✅ Complete
│   │   │   └── SampleData.swift       # Fallback data
│   │   ├── Firebase/
│   │   │   ├── FirestoreService.swift # ✅ Complete
│   │   │   └── FirebaseNeonService.swift # ✅ Complete
│   │   └── Dependencies.swift          # ServiceContainer
│   └── Models/
│       ├── Dua.swift
│       ├── Journey.swift
│       ├── User.swift
│       └── Habit.swift
└── RIZQTests/
    └── NeonIntegrationTests.swift      # ⭐ CREATE (Phase 5)
```

---

## Quick Start Checklist

When you're ready to implement, follow this order:

1. [ ] **Phase 1.1**: Add Neon credentials to `Info.plist`
2. [ ] **Phase 1.2**: Verify app builds and launches
3. [ ] **Phase 2.1**: Update `JourneyServiceClient.liveValue`
4. [ ] **Phase 2.3**: Test journeys loading
5. [ ] **Phase 3.1**: Create `AdkharServiceClient`
6. [ ] **Phase 3.3**: Update `.onAppear` action
7. [ ] **Phase 4.1**: Wire up completion persistence
8. [ ] **Phase 5**: Run manual testing checklist

**Estimated time**: 2-3 hours for full implementation
