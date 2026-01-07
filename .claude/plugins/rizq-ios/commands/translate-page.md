---
name: translate-page
description: Convert an entire React page to SwiftUI with TCA Feature
allowed_tools:
  - Read
  - Write
  - Edit
  - Grep
  - Glob
arguments:
  - name: page
    description: Name of the page to translate (e.g., "Home", "Library", "Practice")
    required: true
---

# Translate React Page to SwiftUI + TCA Feature

Convert a complete React page from the RIZQ web app to a native iOS feature module with TCA state management.

## Output Files Created

For page `{{ page }}`:

```
Features/{{ page }}/
├── {{ page }}Feature.swift   # TCA Reducer with State/Action
├── {{ page }}View.swift      # SwiftUI View
└── {{ page }}Tests.swift     # Unit tests (optional)
```

## Translation Process

1. **Analyze the React page** at `src/pages/{{ page }}Page.tsx`:
   - Identify data dependencies (useQuery hooks)
   - Find user interactions (onClick, onChange)
   - Map navigation patterns
   - Extract loading/error states

2. **Create TCA Feature**:
   - Define State with all necessary properties
   - Create Actions for user interactions and async responses
   - Build Reducer with effect handling
   - Add delegate actions for parent communication

3. **Create SwiftUI View**:
   - Use @Bindable store pattern
   - Handle loading, error, empty states
   - Apply RIZQ design system
   - Add entry animations

4. **Wire up navigation**:
   - Add to parent's navigation path
   - Configure deeplinks if needed

## Page Mapping Reference

| React Page | iOS Feature | Data Source |
|------------|-------------|-------------|
| HomePage | HomeFeature | Profile + Activity (API) |
| LibraryPage | LibraryFeature | Duas (API) |
| PracticePage | PracticeFeature | Single Dua (API) |
| JourneysPage | JourneysFeature | Journeys (API) |
| DailyAdkharPage | DailyAdkharFeature | Habits (Local + API) |
| SettingsPage | SettingsFeature | Profile (API) + Prefs (Local) |

## Example: HomePage Translation

**React dependencies found:**
- useAuth() → profile, streak, XP
- useQuery for week activity
- Navigation to Practice, Habits, Journeys

**Generated HomeFeature.swift:**
```swift
@Reducer
struct HomeFeature {
  @ObservableState
  struct State: Equatable {
    var profile: UserProfile?
    var weekActivity: [DailyActivity] = []
    var isLoading = false
    var errorMessage: String?
  }

  enum Action: Equatable {
    case onAppear
    case profileResponse(Result<UserProfile, Error>)
    case activityResponse(Result<[DailyActivity], Error>)
    case startPracticeTapped
    case delegate(Delegate)

    @CasePathable
    enum Delegate: Equatable {
      case navigateToPractice
      case navigateToHabits
    }
  }

  @Dependency(\.apiClient) var apiClient
  @Dependency(\.authClient) var authClient

  var body: some ReducerOf<Self> {
    Reduce { state, action in
      // ... implementation
    }
  }
}
```

## Reference Skills

- feature-builder agent
- component-translator agent
- tca-patterns skill
