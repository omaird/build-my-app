# RIZQ iOS Implementation Master Plan

> **Goal**: Connect the iOS app to the Neon database and align the UI/UX with the React web application

## Current State Assessment

### What's Working ✅
- **TCA Architecture**: Proper state isolation, reducers, and dependency injection
- **Authentication**: Firebase Auth with Google/Apple OAuth flows
- **Practice Feature**: Counter mechanics, haptics, celebration animations
- **UI Components**: Gamification views, habit views, journey cards
- **Services Infrastructure**: APIClient.swift exists for Neon HTTP API

### What's Missing/Placeholder 🟡
- **Data Loading**: All features use `SampleData.swift` demo data
- **Home Dashboard**: Simulated profile with hardcoded values
- **Library**: Demo duas array, no database connection
- **Adkhar**: UI works but no persistent backend integration
- **Journey Detail**: Doesn't match React's rich preview layout

---

## Scope Definition

### In Scope ✅
1. **Database Integration**: Connect all features to Neon PostgreSQL
2. **Page Parity**: Match React app's page structure and data display
3. **State Persistence**: Implement proper habit storage and user progress
4. **Gamification**: Real XP, levels, and streak tracking from database
5. **Journey System**: Full subscribe/unsubscribe with backend persistence

### Out of Scope ❌
1. **Admin Panel**: Not reimplementing CRUD admin features (web-only)
2. **Social Features**: No social/sharing features in this phase
3. **Premium/IAP**: No in-app purchases or premium journey gating
4. **Notifications**: Push notifications deferred to future phase
5. **Offline Mode**: Full offline support with sync deferred
6. **Widget**: Widget data refresh deferred to future phase

---

## Implementation Phases

### Phase 1: Database Layer Foundation
**Duration**: 2-3 focused sessions
**Files**: See `01-PHASE1-DATABASE-LAYER.md`

- [ ] Fix and verify `APIClient.swift` Neon HTTP connection
- [ ] Implement SQL query builders for all table types
- [ ] Create comprehensive mapping functions (DB ↔ Swift types)
- [ ] Add `NeonService` methods for all data fetching needs
- [ ] Write unit tests for API client and services

### Phase 2: Core Data Features
**Duration**: 3-4 focused sessions
**Files**: See `02-PHASE2-CORE-FEATURES.md`

- [ ] Integrate Library feature with real duas from database
- [ ] Connect Journeys feature to fetch real journey data
- [ ] Implement JourneyDetail with full dua list display
- [ ] Wire up search and category filtering to database queries

### Phase 3: User Data & Gamification
**Duration**: 2-3 focused sessions
**Files**: See `03-PHASE3-USER-DATA.md`

- [ ] Connect UserProfile to database (or Firestore for user data)
- [ ] Implement XP and level tracking with database persistence
- [ ] Add streak calculation and maintenance
- [ ] Wire up daily activity tracking (user_activity table)

### Phase 4: Habits System
**Duration**: 2-3 focused sessions
**Files**: See `04-PHASE4-HABITS.md`

- [ ] Implement journey subscription persistence
- [ ] Connect habit completions to user_progress table
- [ ] Match React's useUserHabits hook functionality
- [ ] Implement habit grouping by time slot with deduplication

### Phase 5: UI/UX Alignment
**Duration**: 2-3 focused sessions
**Files**: See `05-PHASE5-UI-ALIGNMENT.md`

- [ ] Match HomePage layout with React (stats, calendar, habits)
- [ ] Align JourneysPage card design and sections
- [ ] Match DailyAdkharPage with time slot grouping
- [ ] Ensure Practice page matches React's context tabs

### Phase 6: Testing & Polish
**Duration**: 1-2 focused sessions
**Files**: See `06-PHASE6-TESTING.md`

- [ ] End-to-end flow testing
- [ ] Snapshot test updates
- [ ] Performance optimization
- [ ] Error handling and edge cases

---

## File Structure

```
docs/
├── 00-MASTER-PLAN.md           # This file - overall roadmap
├── 01-PHASE1-DATABASE-LAYER.md # Database connection details
├── 02-PHASE2-CORE-FEATURES.md  # Duas, Journeys implementation
├── 03-PHASE3-USER-DATA.md      # Profile, XP, Streaks
├── 04-PHASE4-HABITS.md         # Habits system implementation
├── 05-PHASE5-UI-ALIGNMENT.md   # UI matching React app
├── 06-PHASE6-TESTING.md        # Testing strategy
├── BEST-PRACTICES.md           # Coding standards and patterns
├── CONTEXT-DATABASE-SCHEMA.md  # Database reference
├── CONTEXT-REACT-PAGES.md      # React page structures
└── CONTEXT-TYPE-MAPPINGS.md    # Type conversion reference
```

---

## Key Technical Decisions

### 1. Data Architecture
- **Content Data** (duas, journeys, categories): Fetch from Neon PostgreSQL
- **User Data** (profiles, progress, activity): Use Firestore (already partially integrated)
- **Local State** (habit selections, completions): UserDefaults with Firestore sync

### 2. ID Type Handling
- Database uses `Int` for IDs
- iOS will use `Int` consistently (not String like React)
- Conversion layer only needed for cross-platform serialization

### 3. State Management
- Continue using TCA with `@Dependency` injection
- Services registered in `ServiceContainer`
- Effects handle all async database operations

### 4. Caching Strategy
- React Query equivalent: TCA's `TaskResult` with in-memory cache
- Stale-while-revalidate pattern for content data
- Immediate updates for user actions (optimistic UI)

---

## Success Criteria

1. **Data Parity**: iOS displays same data as React web app
2. **Feature Parity**: All core flows work identically
3. **Performance**: Data loads within 2 seconds on good network
4. **Reliability**: Graceful error handling, no crashes
5. **Testability**: Core paths covered with tests

---

## Quick Reference

| Page | React File | iOS Feature | Status |
|------|------------|-------------|--------|
| Home | HomePage.tsx | HomeFeature | 🟡 Demo data |
| Library | LibraryPage.tsx | LibraryFeature | 🟡 Demo data |
| Journeys | JourneysPage.tsx | JourneysFeature | 🟢 Partial |
| Journey Detail | JourneyDetailPage.tsx | JourneysFeature | 🟡 Basic |
| Daily Adkhar | DailyAdkharPage.tsx | AdkharFeature | 🟡 UI only |
| Practice | PracticePage.tsx | PracticeFeature | 🟢 Working |
| Settings | SettingsPage.tsx | SettingsFeature | 🟡 Basic |

---

## Commands & Agents to Use

### Available Commands
- `/commit` - Commit changes with proper message
- `/review-pr` - Review pull request for issues

### Recommended Agents
- `Explore` - Understand code patterns before implementation
- `Plan` - Design architecture for complex features
- `code-reviewer` - Review implementation for issues

### Skills to Create (if needed)
- `/ios-build` - Build and run iOS app
- `/ios-test` - Run iOS test suite
- `/sync-types` - Verify type alignment React ↔ iOS

---

## Next Steps

1. **Read**: Review Phase 1 details in `01-PHASE1-DATABASE-LAYER.md`
2. **Verify**: Ensure Neon credentials are configured
3. **Execute**: Start with APIClient.swift improvements
4. **Test**: Validate database connectivity before proceeding

---

*Last Updated: 2026-01-08*
*Version: 1.0*
