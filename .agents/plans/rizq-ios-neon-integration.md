# Feature: RIZQ iOS Neon Database Integration & Feature Parity

The following plan should be complete, but it's important that you validate documentation and codebase patterns and task sanity before you start implementing.

Pay special attention to naming of existing utils, types, and models. Import from the right files, etc.

## Feature Description

Connect the RIZQ iOS app to the Neon PostgreSQL database and achieve feature parity with the React web application. This involves replacing all demo/sample data with real database content, implementing persistent user data storage via Firestore, and aligning UI/UX with the React app's design.

## User Story

As a **RIZQ iOS user**
I want to **see the same duas, journeys, and progress data as the web app**
So that **I can have a consistent experience across platforms and my progress persists**

## Problem Statement

The iOS app currently uses hardcoded demo data (`SampleData.swift`) instead of real database content. User progress (XP, streaks, habit completions) doesn't persist, and the UI doesn't fully match the React web application's design and interactions.

## Solution Statement

1. Establish reliable Neon PostgreSQL database connectivity via HTTP API
2. Replace all demo data with real database fetches
3. Implement Firestore persistence for user-specific data
4. Match React app's UI/UX patterns and gamification features
5. Comprehensive testing to ensure reliability

## Feature Metadata

**Feature Type**: Enhancement / Major Feature Integration
**Estimated Complexity**: High
**Primary Systems Affected**: All features (Home, Library, Journeys, Adkhar, Practice, Settings)
**Dependencies**: Neon PostgreSQL HTTP API, Firebase Firestore, Firebase Auth

---

## CONTEXT REFERENCES

### Relevant Codebase Files - IMPORTANT: READ THESE FILES BEFORE IMPLEMENTING!

**Database Layer:**
- `RIZQ-iOS/RIZQKit/Services/API/APIClient.swift` - Existing HTTP client for Neon API (needs verification/fixes)
- `RIZQ-iOS/RIZQKit/Services/API/NeonService.swift` - Service wrapper (needs comprehensive fetch methods)
- `RIZQ-iOS/RIZQKit/Services/API/SampleData.swift` - Demo data to be replaced
- `RIZQ-iOS/RIZQKit/Services/Dependencies.swift` - TCA dependency container

**Firebase Services:**
- `RIZQ-iOS/RIZQKit/Services/Firebase/FirestoreService.swift` - User data CRUD
- `RIZQ-iOS/RIZQKit/Services/Firebase/FirebaseAuthService.swift` - Auth integration

**Features:**
- `RIZQ-iOS/RIZQ/Features/Home/HomeFeature.swift` - Home dashboard reducer
- `RIZQ-iOS/RIZQ/Features/Library/LibraryFeature.swift` - Library reducer (uses demo data)
- `RIZQ-iOS/RIZQ/Features/Journeys/JourneysFeature.swift` - Journeys reducer
- `RIZQ-iOS/RIZQ/Features/Adkhar/AdkharFeature.swift` - Daily habits reducer
- `RIZQ-iOS/RIZQ/Features/Practice/PracticeFeature.swift` - Practice reducer
- `RIZQ-iOS/RIZQ/App/AppFeature.swift` - Root reducer

**Models:**
- `RIZQ-iOS/RIZQKit/Models/Dua.swift` - Dua model
- `RIZQ-iOS/RIZQKit/Models/Journey.swift` - Journey model
- `RIZQ-iOS/RIZQKit/Models/UserProfile.swift` - User profile model

**Views:**
- `RIZQ-iOS/RIZQ/Views/Components/GamificationViews/` - XP, streak, level views
- `RIZQ-iOS/RIZQ/Views/Components/JourneyViews/` - Journey cards
- `RIZQ-iOS/RIZQ/Views/Components/HabitViews/` - Habit item views

### New Files to Create

**Phase 1 - Database Layer:**
- `RIZQ-iOS/RIZQKit/Models/DatabaseRows.swift` - Intermediate row types matching DB schema
- `RIZQ-iOS/RIZQKit/Models/DatabaseMappers.swift` - Row to Model mapping extensions
- `RIZQ-iOS/RIZQTests/Services/NeonServiceTests.swift` - Database service tests

**Phase 3 - User Data:**
- `RIZQ-iOS/RIZQKit/Services/UserDataClient.swift` - TCA dependency for user data
- `RIZQ-iOS/RIZQ/App/SharedUserState.swift` - Cross-feature state sync

**Phase 4 - Habits:**
- `RIZQ-iOS/RIZQKit/Services/Persistence/UserHabitsStorage.swift` - Habit persistence
- `RIZQ-iOS/RIZQKit/Services/UserHabitsClient.swift` - TCA dependency for habits
- `RIZQ-iOS/RIZQ/Views/Components/HabitViews/AddToAdkharSheet.swift` - Add dua to habits
- `RIZQ-iOS/RIZQ/Views/Components/HabitViews/HabitItemView.swift` - Habit row component

**Phase 5 - UI:**
- `RIZQ-iOS/RIZQ/Views/Components/Animations/CelebrationParticles.swift`
- `RIZQ-iOS/RIZQ/Views/Components/Animations/RippleEffect.swift`
- `RIZQ-iOS/RIZQ/Views/Components/Animations/AnimatedCheckmark.swift`
- `RIZQ-iOS/RIZQ/Views/Components/CategoryBadge.swift`
- `RIZQ-iOS/RIZQ/Views/Components/IslamicPatternView.swift`
- `RIZQ-iOS/RIZQKit/Design/Colors.swift` - Color palette
- `RIZQ-iOS/RIZQKit/Design/Typography.swift` - Font definitions
- `RIZQ-iOS/RIZQKit/Design/Spacing.swift` - Spacing constants

**Phase 6 - Testing:**
- `RIZQ-iOS/RIZQTests/Services/UserHabitsStorageTests.swift`
- `RIZQ-iOS/RIZQTests/Services/LevelCalculatorTests.swift`
- `RIZQ-iOS/RIZQTests/Features/LibraryFeatureTests.swift`
- `RIZQ-iOS/RIZQTests/Features/AdkharFeatureTests.swift`
- `RIZQ-iOS/RIZQTests/E2E/JourneySubscriptionFlowTests.swift`
- `RIZQ-iOS/RIZQTests/E2E/DuaCompletionFlowTests.swift`

### Relevant Documentation - READ BEFORE IMPLEMENTING!

- `RIZQ-iOS/docs/CONTEXT-DATABASE-SCHEMA.md` - Complete database schema reference
- `RIZQ-iOS/docs/CONTEXT-TYPE-MAPPINGS.md` - Type conversion reference
- `RIZQ-iOS/docs/BEST-PRACTICES.md` - TCA patterns and coding standards
- `RIZQ-iOS/CLAUDE.md` - iOS project conventions

### React References (for UI parity)
- `src/pages/HomePage.tsx` - Home layout reference
- `src/pages/LibraryPage.tsx` - Library layout reference
- `src/pages/JourneysPage.tsx` - Journeys layout reference
- `src/pages/JourneyDetailPage.tsx` - Journey detail reference
- `src/pages/DailyAdkharPage.tsx` - Adkhar layout reference
- `src/pages/PracticePage.tsx` - Practice layout reference
- `src/hooks/useUserHabits.ts` - Habit logic reference

### Patterns to Follow

**TCA Feature Pattern:**
```swift
@Reducer
struct MyFeature {
    @ObservableState
    struct State: Equatable {
        var loadingState: LoadingState = .idle
        // ...
    }

    enum Action {
        case onAppear
        case dataLoaded(TaskResult<[Item], Error>)
    }

    @Dependency(\.myService) var myService

    var body: some ReducerOf<Self> {
        Reduce { state, action in
            // ...
        }
    }
}
```

**Loading State Enum:**
```swift
enum LoadingState: Equatable {
    case idle, loading, loaded, error(String)
}
```

**Database Row Mapping:**
```swift
// Row type (snake_case matching DB)
struct DuaRow: Codable {
    let id: Int
    let title_en: String
}

// Model type (camelCase)
extension Dua {
    init(from row: DuaRow) {
        self.id = row.id
        self.titleEn = row.title_en
    }
}
```

---

## IMPLEMENTATION PLAN

### Phase 1: Database Layer Foundation (6 hours)

Establish reliable database connectivity and data fetching infrastructure.

**Tasks:**
- Verify and fix Neon HTTP API connection
- Implement query builder methods for all tables
- Create database row types matching exact DB schema
- Implement mapping functions (DB rows → app models)
- Register NeonService as TCA dependency
- Write unit tests for data layer

### Phase 2: Core Data Features (7.5 hours)

Connect Library, Journeys, and JourneyDetail features to the database.

**Tasks:**
- Update Library feature with real database fetching
- Add loading/error/empty states to Library view
- Verify and enhance Journeys feature
- Implement full JourneyDetail feature with dua list
- Connect category filtering to database
- Update Journeys view with featured/active sections

### Phase 3: User Data & Gamification (7.25 hours)

Connect user profiles, XP, levels, and streaks to persistent storage.

**Tasks:**
- Audit and complete FirestoreService methods
- Create UserDataClient TCA dependency
- Update Home feature with real profile data
- Update Home view to match React layout
- Update Practice feature for XP persistence
- Create shared user state for cross-feature updates

### Phase 4: Habits System (6.75 hours)

Implement full habit tracking with journey subscriptions and completions.

**Tasks:**
- Create UserHabitsStorage persistence layer
- Create UserHabitsClient TCA dependency
- Update Adkhar feature with real habit loading
- Update Adkhar view with time slot sections
- Create AddToAdkhar sheet component
- Implement habit completion flow

### Phase 5: UI/UX Alignment (8 hours)

Match iOS app's visual design with React web application.

**Tasks:**
- Implement design system (colors, typography, spacing)
- Update Home page layout to match React
- Update Journey cards to match React design
- Update Practice page with context tabs
- Create animation components (particles, ripple, checkmark)
- Implement category badges and Islamic pattern background

### Phase 6: Testing & Polish (11.5 hours)

Ensure reliability, performance, and quality.

**Tasks:**
- Write unit tests for services
- Write TCA feature tests
- Create/update snapshot tests
- Implement E2E flow tests
- Error handling audit
- Performance optimization
- Final polish and accessibility

---

## STEP-BY-STEP TASKS

Execute every task in order, top to bottom. Each task is atomic and independently testable.

---

## PHASE 1: DATABASE LAYER FOUNDATION

### Task 1.1: VERIFY Neon HTTP Connection

**File:** `RIZQ-iOS/RIZQKit/Services/API/APIClient.swift`

- **IMPLEMENT**: Verify environment variables are loaded (NEON_HOST, NEON_API_KEY, NEON_PROJECT_ID)
- **IMPLEMENT**: Test basic connectivity with `SELECT 1 as test`
- **IMPLEMENT**: Verify JSON response parsing matches Neon format:
  ```json
  { "rows": [...], "columns": [...], "rowCount": N }
  ```
- **PATTERN**: Check existing implementation, fix response parsing if needed
- **GOTCHA**: Ensure proper error handling for network failures
- **VALIDATE**: Run app in debug mode, check console for successful query execution

---

### Task 1.2: CREATE DatabaseRows.swift

**File:** `RIZQ-iOS/RIZQKit/Models/DatabaseRows.swift` (NEW)

- **IMPLEMENT**: Create intermediate row types matching exact database column structure:
  - `DuaRow` - All dua columns plus joined category/collection fields
  - `JourneyRow` - All journey columns
  - `JourneyDuaRow` - Junction table with joined dua fields
  - `CategoryRow` - Category columns
  - `CollectionRow` - Collection columns
- **PATTERN**: Use snake_case property names matching database columns
- **IMPORTS**: `Foundation`
- **GOTCHA**: All properties must be `Codable`, use proper optional handling
- **VALIDATE**: `swift build` should succeed

---

### Task 1.3: CREATE DatabaseMappers.swift

**File:** `RIZQ-iOS/RIZQKit/Models/DatabaseMappers.swift` (NEW)

- **IMPLEMENT**: Add init extensions to map DB rows to app models:
  - `Dua.init(from: DuaRow)`
  - `Journey.init(from: JourneyRow)`
  - `JourneyDua.init(from: JourneyDuaRow)`
- **PATTERN**: Convert snake_case → camelCase, handle date parsing
- **IMPORTS**: `Foundation`
- **GOTCHA**: Use ISO8601DateFormatter for timestamps, provide defaults for missing optionals
- **VALIDATE**: `swift build` should succeed

---

### Task 1.4: UPDATE APIClient with Query Methods

**File:** `RIZQ-iOS/RIZQKit/Services/API/APIClient.swift`

- **IMPLEMENT**: Add generic query execution method:
  ```swift
  func execute<T: Decodable>(_ sql: String) async throws -> [T]
  ```
- **PATTERN**: Mirror existing implementation pattern
- **GOTCHA**: Use parameterized queries to prevent SQL injection (note: current implementation uses string interpolation - improve later)
- **VALIDATE**: `swift build` should succeed

---

### Task 1.5: UPDATE NeonService with Comprehensive Methods

**File:** `RIZQ-iOS/RIZQKit/Services/API/NeonService.swift`

- **IMPLEMENT**: Add these public methods:
  - `fetchAllDuas() async throws -> [Dua]`
  - `fetchDua(id: Int) async throws -> Dua?`
  - `fetchDuasByCategory(slug: String) async throws -> [Dua]`
  - `fetchAllJourneys() async throws -> [Journey]`
  - `fetchJourneyWithDuas(id: Int) async throws -> JourneyWithDuas?`
  - `fetchJourneyBySlug(_ slug: String) async throws -> JourneyWithDuas?`
  - `fetchCategories() async throws -> [DuaCategory]`
- **PATTERN**: Use `actor` for thread safety, call APIClient.execute()
- **IMPORTS**: `Foundation`
- **GOTCHA**: Use proper SQL with JOINs for related data
- **VALIDATE**: `swift build` should succeed

---

### Task 1.6: UPDATE Dependencies.swift - Register NeonService

**File:** `RIZQ-iOS/RIZQKit/Services/Dependencies.swift`

- **IMPLEMENT**: Add NeonService as TCA dependency:
  ```swift
  private enum NeonServiceKey: DependencyKey {
      static let liveValue: NeonService = NeonService(client: .live)
      static let previewValue: NeonService = NeonService(client: .mock)
  }
  ```
- **PATTERN**: Follow existing dependency registration pattern
- **IMPORTS**: `ComposableArchitecture`
- **VALIDATE**: `swift build` should succeed

---

### Task 1.7: CREATE NeonServiceTests.swift

**File:** `RIZQ-iOS/RIZQTests/Services/NeonServiceTests.swift` (NEW)

- **IMPLEMENT**: Test cases:
  - `testFetchAllDuas_ReturnsValidData`
  - `testFetchDua_ById_ReturnsCorrectDua`
  - `testFetchJourneys_SortedByFeaturedFirst`
  - `testFetchJourneyWithDuas_IncludesAllDuas`
  - `testDuaRowMapping_MapsAllFields`
  - `testJourneyRowMapping_MapsAllFields`
- **PATTERN**: Use XCTest with async/await
- **IMPORTS**: `XCTest`, `@testable import RIZQKit`
- **VALIDATE**: `xcodebuild test -scheme RIZQKit`

---

## PHASE 2: CORE DATA FEATURES

### Task 2.1: UPDATE LibraryFeature - Database Integration

**File:** `RIZQ-iOS/RIZQ/Features/Library/LibraryFeature.swift`

- **IMPLEMENT**:
  - Add `@Dependency(\.neonService)`
  - Add `loadingState: LoadingState` to State
  - Add `duasLoaded(TaskResult<[Dua], Error>)` action
  - Replace demo data fetch with `neonService.fetchAllDuas()`
- **PATTERN**: See `docs/BEST-PRACTICES.md` Effect Patterns section
- **IMPORTS**: `ComposableArchitecture`
- **GOTCHA**: Handle loading/error states properly
- **VALIDATE**: `swift build` should succeed

---

### Task 2.2: UPDATE LibraryView - Loading/Error States

**File:** `RIZQ-iOS/RIZQ/Features/Library/LibraryView.swift`

- **IMPLEMENT**:
  - Add loading state view with ProgressView
  - Add error state view with retry button
  - Add empty state when no duas match filter
- **PATTERN**: Use `@ViewBuilder` for conditional content
- **IMPORTS**: `SwiftUI`, `ComposableArchitecture`
- **VALIDATE**: Run app, verify loading spinner appears during data fetch

---

### Task 2.3: UPDATE JourneysFeature - Sections

**File:** `RIZQ-iOS/RIZQ/Features/Journeys/JourneysFeature.swift`

- **IMPLEMENT**: Add computed properties:
  - `featuredJourneys: [Journey]` - filter isFeatured
  - `regularJourneys: [Journey]` - filter !isFeatured
  - `activeJourneys: [Journey]` - filter by activeJourneyIds
- **PATTERN**: Computed properties in State struct
- **VALIDATE**: `swift build` should succeed

---

### Task 2.4: CREATE/UPDATE JourneyDetailFeature

**File:** `RIZQ-iOS/RIZQ/Features/Journeys/JourneyDetailFeature.swift`

- **IMPLEMENT**: Full journey detail reducer:
  - State: journeyId, journey, journeyDuas, loadingState, isSubscribed
  - Actions: onAppear, journeyLoaded, subscribeButtonTapped, unsubscribeButtonTapped, duaTapped
  - Computed: duasByTimeSlot, totalXp, totalRepetitions
- **PATTERN**: See Phase 2 docs Task 2.4
- **IMPORTS**: `ComposableArchitecture`
- **VALIDATE**: `swift build` should succeed

---

### Task 2.5: UPDATE JourneyDetailView

**File:** `RIZQ-iOS/RIZQ/Features/Journeys/JourneyDetailView.swift`

- **IMPLEMENT**: Match React's JourneyDetailPage:
  - Header with emoji, name, description
  - Stats row (minutes, XP, dua count)
  - Duas grouped by time slot
  - Subscribe/unsubscribe button
- **PATTERN**: See Phase 2 docs Task 2.5
- **VALIDATE**: Run app, navigate to journey detail

---

### Task 2.6: UPDATE JourneysView - Sections Layout

**File:** `RIZQ-iOS/RIZQ/Features/Journeys/JourneysView.swift`

- **IMPLEMENT**:
  - Featured section with horizontal scroll
  - Active journeys section
  - All journeys grid
- **PATTERN**: See Phase 2 docs Task 2.6
- **VALIDATE**: Run app, verify three sections appear

---

### Task 2.7: UPDATE LibraryFeature - Category Filtering

**File:** `RIZQ-iOS/RIZQ/Features/Library/LibraryFeature.swift`

- **IMPLEMENT**:
  - Add `categories: [DuaCategory]` to State
  - Add `categoriesLoaded(TaskResult<[DuaCategory], Error>)` action
  - Fetch categories on appear using `.merge`
- **PATTERN**: Parallel effects with .merge
- **VALIDATE**: Run app, verify category pills appear

---

## PHASE 3: USER DATA & GAMIFICATION

### Task 3.1: AUDIT FirestoreService

**File:** `RIZQ-iOS/RIZQKit/Services/Firebase/FirestoreService.swift`

- **VERIFY/IMPLEMENT** these methods exist and work:
  - `getProfile(userId:)`, `createProfile(userId:displayName:)`, `updateProfile(_:)`
  - `updateXp(userId:amount:)`
  - `recordDuaCompletion(userId:duaId:xpEarned:)`
  - `getTodayActivity(userId:)`, `getWeekActivities(userId:)`
  - `getDuaProgress(userId:duaId:)`, `updateDuaProgress(userId:duaId:)`
- **ADD** if missing: `updateStreak(userId:)` with streak logic
- **ADD** if missing: `calculateLevel(from:)` matching React formula
- **VALIDATE**: `swift build` should succeed

---

### Task 3.2: CREATE UserDataClient.swift

**File:** `RIZQ-iOS/RIZQKit/Services/UserDataClient.swift` (NEW)

- **IMPLEMENT**: TCA-compatible wrapper around FirestoreService:
  - Profile: getProfile, createProfile, updateProfile
  - XP & Level: addXp
  - Streak: updateStreak
  - Activity: recordCompletion, getTodayActivity, getWeekActivities
  - Progress: getDuaProgress, markDuaCompleted
- **PATTERN**: Use `@DependencyClient` macro
- **IMPORTS**: `ComposableArchitecture`, `Foundation`
- **VALIDATE**: `swift build` should succeed

---

### Task 3.3: UPDATE HomeFeature - Real Data

**File:** `RIZQ-iOS/RIZQ/Features/Home/HomeFeature.swift`

- **IMPLEMENT**:
  - Add `@Dependency(\.userDataClient)` and `@Dependency(\.authClient)`
  - Add State: profile, todayActivity, weekActivities, loadingState
  - Add computed: displayName, streak, totalXp, level, xpProgress
  - Fetch real data on .onAppear
- **PATTERN**: See Phase 3 docs Task 3.3
- **VALIDATE**: `swift build` should succeed

---

### Task 3.4: UPDATE HomeView - Match React

**File:** `RIZQ-iOS/RIZQ/Features/Home/HomeView.swift`

- **IMPLEMENT**:
  - Greeting header with time-based greeting
  - Stats card with XP ring and level
  - Week calendar with activity dots
  - Today's progress card
- **PATTERN**: See Phase 3 docs Task 3.4
- **VALIDATE**: Run app, verify home displays user data

---

### Task 3.5: UPDATE PracticeFeature - XP Persistence

**File:** `RIZQ-iOS/RIZQ/Features/Practice/PracticeFeature.swift`

- **IMPLEMENT**: In .duaCompleted action:
  - Record completion via userDataClient
  - Mark dua completed
  - Update streak
  - Add XP
  - Trigger celebration animation
- **PATTERN**: See Phase 3 docs Task 3.5
- **VALIDATE**: Complete a dua, verify XP persists after app restart

---

### Task 3.6: CREATE SharedUserState.swift

**File:** `RIZQ-iOS/RIZQ/App/SharedUserState.swift` (NEW)

- **IMPLEMENT**: Shared state struct and actions for cross-feature updates
- **PATTERN**: See Phase 3 docs Task 3.6
- **VALIDATE**: `swift build` should succeed

---

## PHASE 4: HABITS SYSTEM

### Task 4.1: CREATE UserHabitsStorage.swift

**File:** `RIZQ-iOS/RIZQKit/Services/Persistence/UserHabitsStorage.swift` (NEW)

- **IMPLEMENT**:
  - `UserHabitsData` struct: activeJourneyIds, customHabits, habitCompletions
  - `CustomHabit` struct: id, duaId, timeSlot, sortOrder, addedAt
  - `HabitCompletion` struct: date, completedDuaIds
  - `UserHabitsStorage` actor with UserDefaults persistence
  - Methods: load, save, addJourney, removeJourney, markHabitCompleted, etc.
- **PATTERN**: Use actor for thread safety, keep 30 days of completions
- **IMPORTS**: `Foundation`
- **GOTCHA**: Use date string format "yyyy-MM-dd" for completion dates
- **VALIDATE**: `swift build` should succeed

---

### Task 4.2: CREATE UserHabitsClient.swift

**File:** `RIZQ-iOS/RIZQKit/Services/UserHabitsClient.swift` (NEW)

- **IMPLEMENT**: TCA dependency wrapping UserHabitsStorage:
  - Data: loadHabitsData, getActiveJourneyIds
  - Journeys: addJourney, removeJourney, isJourneyActive
  - Custom: addCustomHabit, removeCustomHabit
  - Completions: markCompleted, isCompletedToday, todayCompletedIds
- **PATTERN**: Use `@DependencyClient` macro
- **VALIDATE**: `swift build` should succeed

---

### Task 4.3: UPDATE AdkharFeature - Full Implementation

**File:** `RIZQ-iOS/RIZQ/Features/Adkhar/AdkharFeature.swift`

- **IMPLEMENT**:
  - State: habits, completedDuaIds, loadingState
  - Computed: groupedHabits, progress, nextUncompletedHabit, allCompleted
  - Actions: onAppear, habitsLoaded, habitTapped, habitCompleted
  - Load habits by fetching active journey duas + custom habits
  - Deduplicate by dua ID
- **PATTERN**: See Phase 4 docs Task 4.3
- **GOTCHA**: Sort by time slot priority: morning → anytime → evening
- **VALIDATE**: `swift build` should succeed

---

### Task 4.4: UPDATE AdkharView - Time Slots

**File:** `RIZQ-iOS/RIZQ/Features/Adkhar/AdkharView.swift`

- **IMPLEMENT**:
  - Progress header with completion count and XP
  - Time slot sections (morning, anytime, evening)
  - Habit item views with completion indicator
  - Empty state with "Explore Journeys" CTA
  - All complete celebration
- **PATTERN**: See Phase 4 docs Task 4.4
- **VALIDATE**: Run app, navigate to Adkhar tab

---

### Task 4.5: CREATE AddToAdkharSheet.swift

**File:** `RIZQ-iOS/RIZQ/Views/Components/HabitViews/AddToAdkharSheet.swift` (NEW)

- **IMPLEMENT**: Sheet for adding duas from Library:
  - Dua preview (title, Arabic)
  - Time slot selection buttons
  - onAdd callback with selected slot
- **PATTERN**: Use `.presentationDetents([.medium])`
- **VALIDATE**: `swift build` should succeed

---

### Task 4.6: CREATE HabitItemView.swift

**File:** `RIZQ-iOS/RIZQ/Views/Components/HabitViews/HabitItemView.swift` (NEW)

- **IMPLEMENT**: Single habit row component:
  - Completion circle indicator
  - Title with strikethrough when complete
  - Repetitions and XP labels
  - Chevron for navigation
- **PATTERN**: Stateless component with onTap closure
- **VALIDATE**: `swift build` should succeed

---

## PHASE 5: UI/UX ALIGNMENT

### Task 5.1: CREATE Colors.swift

**File:** `RIZQ-iOS/RIZQKit/Design/Colors.swift` (NEW)

- **IMPLEMENT**: Color palette matching React:
  - Sand: warm, light, deep
  - Mocha: default, deep
  - Cream: default, warm
  - Gold: soft, bright
  - Teal: muted, success
  - Semantic: card, background, primaryText, secondaryText
- **PATTERN**: Use Color extensions
- **VALIDATE**: `swift build` should succeed

---

### Task 5.2: CREATE Typography.swift

**File:** `RIZQ-iOS/RIZQKit/Design/Typography.swift` (NEW)

- **IMPLEMENT**: Font definitions:
  - Display: large, medium, small (serif)
  - Body: large, medium, small
  - Arabic: large, medium, small (Amiri)
  - Counter (monospaced)
- **PATTERN**: Use Font extensions
- **VALIDATE**: `swift build` should succeed

---

### Task 5.3: CREATE Spacing.swift

**File:** `RIZQ-iOS/RIZQKit/Design/Spacing.swift` (NEW)

- **IMPLEMENT**: Spacing and corner radius constants:
  - Spacing: xs (4), sm (8), md (16), lg (24), xl (32), xxl (48)
  - CornerRadius: small (8), medium (12), large (16), islamic (20), button (16)
- **VALIDATE**: `swift build` should succeed

---

### Task 5.4: UPDATE Home/Gamification Views

**Files:** Various gamification views

- **IMPLEMENT**: Match React designs:
  - StreakBadge with glow effect
  - CircularXpProgress with animated ring
  - XpProgressBar with shimmer
  - WeekCalendarView with activity dots
- **PATTERN**: Use design tokens from new files
- **VALIDATE**: Run app, verify visual parity

---

### Task 5.5: CREATE Animation Components

**Files:** `RIZQ-iOS/RIZQ/Views/Components/Animations/`

- **CREATE**: CelebrationParticles.swift - Floating particles on completion
- **CREATE**: RippleEffect.swift - Tap feedback modifier
- **CREATE**: AnimatedCheckmark.swift - Draw animation for completion
- **PATTERN**: Use Canvas for particles, ViewModifier for ripple
- **VALIDATE**: `swift build` should succeed

---

### Task 5.6: CREATE CategoryBadge.swift

**File:** `RIZQ-iOS/RIZQ/Views/Components/CategoryBadge.swift` (NEW)

- **IMPLEMENT**: Category pill with emoji and color:
  - Morning: orange
  - Evening: indigo
  - Rizq: green
  - Gratitude: purple
- **VALIDATE**: `swift build` should succeed

---

### Task 5.7: CREATE IslamicPatternView.swift

**File:** `RIZQ-iOS/RIZQ/Views/Components/IslamicPatternView.swift` (NEW)

- **IMPLEMENT**: Subtle geometric pattern background using Canvas
- **PATTERN**: 8-pointed star pattern at low opacity
- **VALIDATE**: `swift build` should succeed

---

### Task 5.8: UPDATE JourneyCardView

**File:** `RIZQ-iOS/RIZQ/Views/Components/JourneyViews/JourneyCardView.swift`

- **IMPLEMENT**: Match React design:
  - Emoji icon (48pt)
  - Title and description
  - Stats row (minutes, XP)
  - Featured badge
  - Active indicator
- **PATTERN**: Use new design tokens
- **VALIDATE**: Run app, compare with React

---

### Task 5.9: UPDATE PracticeView

**File:** `RIZQ-iOS/RIZQ/Features/Practice/PracticeView.swift`

- **IMPLEMENT**: Match React design:
  - Tap card with Arabic, transliteration, translation
  - Counter with progress ring
  - Practice/Context tabs
  - Celebration overlay
- **PATTERN**: Use TapScaleButtonStyle for tap feedback
- **VALIDATE**: Run app, compare with React

---

## PHASE 6: TESTING & POLISH

### Task 6.1: CREATE UserHabitsStorageTests.swift

**File:** `RIZQ-iOS/RIZQTests/Services/UserHabitsStorageTests.swift` (NEW)

- **IMPLEMENT**: Test cases:
  - addJourney persists to storage
  - addJourney doesn't duplicate
  - removeJourney removes from storage
  - markHabitCompleted persists today only
  - completions cleans old entries
- **PATTERN**: Use mock UserDefaults
- **VALIDATE**: `xcodebuild test`

---

### Task 6.2: CREATE LevelCalculatorTests.swift

**File:** `RIZQ-iOS/RIZQTests/Services/LevelCalculatorTests.swift` (NEW)

- **IMPLEMENT**: Test cases:
  - calculateLevel for levels 1, 2, 3
  - xpThreshold formula (50L² + 50L)
  - xpProgressInLevel calculation
- **VALIDATE**: `xcodebuild test`

---

### Task 6.3: CREATE LibraryFeatureTests.swift

**File:** `RIZQ-iOS/RIZQTests/Features/LibraryFeatureTests.swift` (NEW)

- **IMPLEMENT**: TestStore tests:
  - onAppear fetches duas
  - search filters duas
  - category filter works correctly
- **PATTERN**: Use TestStore with mock dependencies
- **VALIDATE**: `xcodebuild test`

---

### Task 6.4: CREATE AdkharFeatureTests.swift

**File:** `RIZQ-iOS/RIZQTests/Features/AdkharFeatureTests.swift` (NEW)

- **IMPLEMENT**: TestStore tests:
  - habitCompleted updates state
  - allCompleted calculates correctly
  - progress calculates XP correctly
- **VALIDATE**: `xcodebuild test`

---

### Task 6.5: UPDATE Snapshot Tests

**File:** `RIZQ-iOS/RIZQSnapshotTests/RIZQSnapshotTests.swift`

- **IMPLEMENT**: Add snapshots:
  - JourneyCard (default, active, featured)
  - HabitItem (complete, incomplete)
  - StreakBadge (various counts)
  - CategoryBadge (all categories)
  - CounterView (progress states)
- **VALIDATE**: `xcodebuild test`

---

### Task 6.6: CREATE E2E Flow Tests

**Files:** `RIZQ-iOS/RIZQTests/E2E/`

- **CREATE**: JourneySubscriptionFlowTests.swift
- **CREATE**: DuaCompletionFlowTests.swift
- **IMPLEMENT**: Multi-step flow tests with mock dependencies
- **VALIDATE**: `xcodebuild test`

---

### Task 6.7: ERROR HANDLING AUDIT

**All Feature Files**

- **VERIFY**: Network errors show user-friendly messages
- **VERIFY**: Retry buttons available on error states
- **VERIFY**: Database errors logged but don't crash
- **VERIFY**: Auth errors redirect to login
- **VALIDATE**: Manual testing of error scenarios

---

### Task 6.8: PERFORMANCE OPTIMIZATION

**All View Files**

- **VERIFY**: Using LazyVStack for long lists
- **VERIFY**: No expensive computations in body
- **VERIFY**: Images cached properly
- **VERIFY**: Request deduplication working
- **VALIDATE**: Profile with Instruments, verify < 2s load times

---

### Task 6.9: FINAL POLISH

- **VERIFY**: No placeholder text visible
- **VERIFY**: All animations smooth (60fps)
- **VERIFY**: VoiceOver accessibility
- **VERIFY**: Dynamic Type scaling
- **VERIFY**: Remove debug logging
- **VALIDATE**: Complete app walkthrough

---

## TESTING STRATEGY

### Unit Tests

- **Services**: NeonService, UserHabitsStorage, LevelCalculator
- **Coverage**: Core data fetching, persistence, calculations
- **Framework**: XCTest with async/await

### TCA Feature Tests

- **Features**: LibraryFeature, AdkharFeature, HomeFeature, PracticeFeature
- **Coverage**: State mutations, effect handling, computed properties
- **Framework**: TCA TestStore

### Snapshot Tests

- **Components**: Cards, badges, progress views, animations
- **States**: Loading, error, empty, loaded, complete, incomplete
- **Framework**: swift-snapshot-testing

### E2E Flow Tests

- **Flows**: Journey subscription, dua completion, habit tracking
- **Coverage**: Multi-step user journeys
- **Framework**: TCA TestStore with integrated dependencies

---

## VALIDATION COMMANDS

### Level 1: Build

```bash
cd RIZQ-iOS && xcodebuild build -scheme RIZQ -destination 'platform=iOS Simulator,name=iPhone 15'
```

### Level 2: Unit Tests

```bash
cd RIZQ-iOS && xcodebuild test -scheme RIZQKit -destination 'platform=iOS Simulator,name=iPhone 15'
```

### Level 3: All Tests

```bash
cd RIZQ-iOS && xcodebuild test -scheme RIZQ -destination 'platform=iOS Simulator,name=iPhone 15'
```

### Level 4: Fastlane

```bash
cd RIZQ-iOS && bundle exec fastlane test
```

### Level 5: Manual Validation

1. Launch app, verify home loads user data
2. Navigate to Library, verify 10 duas load
3. Filter by category, verify filtering works
4. Navigate to Journeys, verify 14 journeys with featured section
5. Tap journey, verify detail with duas by time slot
6. Subscribe to journey, verify appears in Adkhar
7. Complete a dua in Adkhar, verify XP awarded
8. Check streak increments on consecutive days
9. Verify UI matches React app design

---

## ACCEPTANCE CRITERIA

- [ ] App connects to Neon PostgreSQL and fetches real data
- [ ] Library displays 10 duas from database
- [ ] Journeys displays 14 journeys with featured/regular sections
- [ ] Journey detail shows full dua list grouped by time slot
- [ ] User profile (XP, level, streak) persists to Firestore
- [ ] Habit completions persist and award XP
- [ ] Streak calculates correctly (increment on consecutive days, reset after missed)
- [ ] UI visually matches React web application
- [ ] All validation commands pass with zero errors
- [ ] Unit test coverage meets requirements (80%+)
- [ ] No crashes during normal usage
- [ ] Performance: < 2s load times on good network

---

## COMPLETION CHECKLIST

- [ ] Phase 1: Database layer verified and tested
- [ ] Phase 2: Core features load real data
- [ ] Phase 3: User data persists correctly
- [ ] Phase 4: Habits system fully functional
- [ ] Phase 5: UI matches React design
- [ ] Phase 6: All tests pass, performance optimized
- [ ] All validation commands executed successfully
- [ ] Manual testing confirms feature works
- [ ] Code reviewed for quality and maintainability

---

## NOTES

### Architecture Decisions

1. **Content Data** (duas, journeys): Neon PostgreSQL via HTTP API
2. **User Data** (profiles, progress): Firestore (real-time sync capability)
3. **Local State** (habit selections): UserDefaults with Firestore sync

### Key Patterns

- TCA with `@ObservableState` for all features
- `LoadingState` enum for consistent loading handling
- `@DependencyClient` for all service wrappers
- Database rows → App models mapping layer

### Known Limitations

- Offline mode deferred to future phase
- Widget refresh deferred to future phase
- Premium/IAP features not implemented
- Admin panel is web-only

### Risk Considerations

- Network failures should show retry UI
- Database errors should not crash app
- Auth token expiration should redirect to login
- Large data sets may need pagination
