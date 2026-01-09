# Feature: iOS Library Page Rebuild with Firestore Migration

The following plan should be complete, but it's important that you validate documentation and codebase patterns and task sanity before you start implementing.

Pay special attention to naming of existing utils types and models. Import from the right files etc.

## Feature Description

Rebuild the iOS dua library page from scratch to match the React web app's design. This involves:
1. Migrating all dua-related data from Neon PostgreSQL to Firebase Firestore
2. Creating a new `FirestoreContentService` for content data (duas, categories, journeys, collections)
3. Rebuilding `LibraryFeature.swift` and `LibraryView.swift` to match the React `LibraryPage.tsx` design
4. Updating the UI to use a vertical list layout with category filter pills

## User Story

As a RIZQ iOS app user
I want to browse the dua library with category filters and search
So that I can easily find and practice duas that match my needs

## Problem Statement

The current iOS Library page differs significantly from the React web app:
- Uses a 2-column grid layout instead of a vertical list
- Data comes from Neon PostgreSQL (requires separate backend)
- Category filtering and search UX doesn't match web
- Dua cards don't show all the information (XP, repetitions, active status)

## Solution Statement

Migrate all content data to Firebase Firestore and rebuild the Library page to:
- Use vertical list layout matching React design
- Show category filter pills with emojis (📿 All, 🌅 Morning, 🌙 Evening, 💫 Rizq, 🤲 Gratitude)
- Display dua cards with title, category badge, XP value, repetitions, and active status
- Support real-time search filtering
- Integrate with Firebase Firestore for data fetching

## Feature Metadata

**Feature Type**: Enhancement + Data Migration
**Estimated Complexity**: High
**Primary Systems Affected**:
- `RIZQKit/Services/` - New Firestore content service
- `RIZQ/Features/Library/` - LibraryFeature and LibraryView rebuild
- `RIZQKit/Models/` - Minor model updates
**Dependencies**: Firebase Firestore SDK (already installed)

---

## CONTEXT REFERENCES

### Relevant Codebase Files IMPORTANT: YOU MUST READ THESE FILES BEFORE IMPLEMENTING!

**React Reference (Target Design)**:
- `src/pages/LibraryPage.tsx` - Target design with header, search, category pills, dua list
- `src/components/DuaCard.tsx` - Card design with title, category badge, XP, repetitions

**iOS Current Implementation**:
- `RIZQ-iOS/RIZQ/Features/Library/LibraryFeature.swift` - Current TCA reducer (needs rebuild)
- `RIZQ-iOS/RIZQ/Features/Library/LibraryView.swift` - Current view (needs rebuild)
- `RIZQ-iOS/RIZQKit/Models/Dua.swift` - Dua model (may need minor updates)
- `RIZQ-iOS/RIZQKit/Models/Journey.swift` - Journey model
- `RIZQ-iOS/RIZQKit/Services/Firebase/FirestoreService.swift` - Existing user data service
- `RIZQ-iOS/RIZQKit/Services/Firebase/FirebaseNeonService.swift` - Current adapter pattern

**Design System**:
- `RIZQ-iOS/RIZQ/Views/Components/JourneyViews/JourneyCardView.swift` - Card styling reference
- `RIZQ-iOS/RIZQ/Views/Components/CategoryBadge.swift` - Category badge component
- `RIZQ-iOS/RIZQ/Views/Components/GamificationViews/GamificationViews.swift` - XP display

**Firebase Config**:
- `firestore.rules` - Security rules (duas, categories collections already configured)

### New Files to Create

- `RIZQ-iOS/RIZQKit/Services/Firebase/FirestoreContentService.swift` - New service for content data
- Updated `RIZQ-iOS/RIZQ/Features/Library/LibraryFeature.swift` - Rebuilt reducer
- Updated `RIZQ-iOS/RIZQ/Features/Library/LibraryView.swift` - Rebuilt view
- Updated `RIZQ-iOS/RIZQ/Views/Components/DuaViews/DuaCardView.swift` - Updated card design

### Relevant Documentation

- [Firebase iOS Firestore Guide](https://firebase.google.com/docs/firestore/quickstart#ios)
  - Collection queries and document fetching
  - Why: Pattern for fetching duas and categories
- [TCA Dependencies](https://pointfreeco.github.io/swift-composable-architecture/main/documentation/composablearchitecture/dependencymanagement)
  - Creating and registering dependencies
  - Why: Creating FirestoreContentClient dependency

### Patterns to Follow

**TCA Feature Pattern** (from `JourneysFeature.swift`):
```swift
@Reducer
struct LibraryFeature {
    @ObservableState
    struct State: Equatable {
        var duas: [Dua] = []
        var isLoading = false
        // ...
    }

    enum Action {
        case onAppear
        case duasLoaded(Result<[Dua], Error>)
        // ...
    }

    @Dependency(\.firestoreContentClient) var contentClient
}
```

**Firestore Query Pattern** (from `FirestoreService.swift`):
```swift
func fetchDuas() async throws -> [Dua] {
    let snapshot = try await db.collection("duas").getDocuments()
    return snapshot.documents.compactMap { doc in
        try? doc.data(as: Dua.self)
    }
}
```

**List View Pattern** (matching React):
```swift
ScrollView {
    LazyVStack(spacing: RIZQSpacing.md) {
        ForEach(filteredDuas) { dua in
            DuaCardView(dua: dua)
        }
    }
}
```

---

## IMPLEMENTATION PLAN

### Phase 1: Data Migration (Neon → Firestore)

Use MCP tools to migrate data from Neon PostgreSQL to Firebase Firestore.

**Data to Migrate**:
- `categories` (4 records): Morning, Evening, Rizq, Gratitude
- `collections` (3 records): Essential Duas, Premium Collection
- `duas` (8 records): All dua content
- `journeys` (14 records): Journey definitions
- `journey_duas` (19 records): Journey-dua mappings

### Phase 2: Create Firestore Content Service

Create new `FirestoreContentService` for fetching content data (duas, categories, journeys).

### Phase 3: Rebuild Library Feature

Rebuild `LibraryFeature.swift` to:
- Use new Firestore content client
- Support category filtering with slugs
- Implement debounced search
- Match React action patterns

### Phase 4: Rebuild Library View

Rebuild `LibraryView.swift` to:
- Match React design (vertical list, not grid)
- Add category filter pills with emojis
- Update dua card design
- Add proper loading/error/empty states

### Phase 5: Testing & Validation

Test the complete flow from data fetch to UI display.

---

## STEP-BY-STEP TASKS

### Task 1: MIGRATE Data from Neon to Firestore

Use MCP tools to migrate data. Execute these operations:

**1.1 Migrate Categories**

```javascript
// Firestore document structure for /categories/{id}
{
  "id": 1,
  "name": "Morning",
  "slug": "morning",
  "description": "Morning adhkar and supplications"
}
```

**1.2 Migrate Collections**

```javascript
// Firestore document structure for /collections/{id}
{
  "id": 1,
  "name": "Essential Duas",
  "slug": "essential",
  "description": "Core duas every Muslim should know",
  "is_premium": false
}
```

**1.3 Migrate Duas**

```javascript
// Firestore document structure for /duas/{id}
{
  "id": 1,
  "category_id": 1,
  "collection_id": 1,
  "title_en": "Morning Supplication",
  "title_ar": "أذكار الصباح",
  "arabic_text": "أَصْبَحْنَا وَأَصْبَحَ الْمُلْكُ لِلَّهِ",
  "transliteration": "Asbahna wa asbahal mulku lillah",
  "translation_en": "We have entered upon morning...",
  "source": "Muslim",
  "repetitions": 1,
  "best_time": "morning",
  "difficulty": "Beginner",
  "xp_value": 10,
  "rizq_benefit": "...",
  "prophetic_context": "..."
}
```

**1.4 Migrate Journeys**

```javascript
// Firestore document structure for /journeys/{id}
{
  "id": 1,
  "name": "Morning Adhkar",
  "slug": "morning-adhkar",
  "description": "Start your day blessed",
  "emoji": "🌅",
  "estimated_minutes": 10,
  "daily_xp": 50,
  "is_premium": false,
  "is_featured": true,
  "sort_order": 1
}
```

**1.5 Migrate Journey Duas**

```javascript
// Firestore document structure for /journey_duas/{journey_id}_{dua_id}
{
  "journey_id": 1,
  "dua_id": 1,
  "time_slot": "morning",
  "sort_order": 1
}
```

- **VALIDATE**: Use Firebase MCP tool `firestore_list_collections` to verify collections exist
- **VALIDATE**: Use Firebase MCP tool `firestore_get_documents` to verify data integrity

---

### Task 2: CREATE FirestoreContentService

- **FILE**: `RIZQ-iOS/RIZQKit/Services/Firebase/FirestoreContentService.swift`
- **PATTERN**: Mirror `FirestoreService.swift` structure
- **IMPORTS**: `FirebaseFirestore`, `Foundation`

```swift
import FirebaseFirestore
import Foundation

// MARK: - Firestore Content Service Protocol
public protocol FirestoreContentServiceProtocol: Sendable {
    func fetchAllDuas() async throws -> [Dua]
    func fetchDuasByCategory(_ slug: CategorySlug) async throws -> [Dua]
    func fetchAllCategories() async throws -> [DuaCategory]
    func fetchAllJourneys() async throws -> [Journey]
    func fetchJourneyDuas(_ journeyId: Int) async throws -> [JourneyDua]
}

// MARK: - Live Implementation
public final class FirestoreContentService: FirestoreContentServiceProtocol, @unchecked Sendable {
    private let db = Firestore.firestore()

    public init() {}

    public func fetchAllDuas() async throws -> [Dua] {
        let snapshot = try await db.collection("duas")
            .order(by: "id")
            .getDocuments()
        return snapshot.documents.compactMap { try? $0.data(as: Dua.self) }
    }

    public func fetchDuasByCategory(_ slug: CategorySlug) async throws -> [Dua] {
        // First get category ID for the slug
        let categories = try await fetchAllCategories()
        guard let category = categories.first(where: { $0.slug == slug }) else {
            return []
        }

        let snapshot = try await db.collection("duas")
            .whereField("category_id", isEqualTo: category.id)
            .getDocuments()
        return snapshot.documents.compactMap { try? $0.data(as: Dua.self) }
    }

    public func fetchAllCategories() async throws -> [DuaCategory] {
        let snapshot = try await db.collection("categories")
            .order(by: "id")
            .getDocuments()
        return snapshot.documents.compactMap { try? $0.data(as: DuaCategory.self) }
    }

    public func fetchAllJourneys() async throws -> [Journey] {
        let snapshot = try await db.collection("journeys")
            .order(by: "sort_order")
            .getDocuments()
        return snapshot.documents.compactMap { try? $0.data(as: Journey.self) }
    }

    public func fetchJourneyDuas(_ journeyId: Int) async throws -> [JourneyDua] {
        let snapshot = try await db.collection("journey_duas")
            .whereField("journey_id", isEqualTo: journeyId)
            .order(by: "sort_order")
            .getDocuments()
        return snapshot.documents.compactMap { try? $0.data(as: JourneyDua.self) }
    }
}
```

- **GOTCHA**: Ensure `Dua` and `DuaCategory` conform to `Codable` with Firestore field names
- **VALIDATE**: Build project with `xcodebuild -scheme RIZQ -destination 'platform=iOS Simulator,name=iPhone 16'`

---

### Task 3: CREATE FirestoreContentClient Dependency

- **FILE**: `RIZQ-iOS/RIZQKit/Services/Dependencies.swift` (add to existing)
- **PATTERN**: Follow existing dependency patterns in the file

```swift
// MARK: - Firestore Content Client
public struct FirestoreContentClient: Sendable {
    public var fetchAllDuas: @Sendable () async throws -> [Dua]
    public var fetchDuasByCategory: @Sendable (CategorySlug) async throws -> [Dua]
    public var fetchAllCategories: @Sendable () async throws -> [DuaCategory]
    public var fetchAllJourneys: @Sendable () async throws -> [Journey]
    public var fetchJourneyDuas: @Sendable (Int) async throws -> [JourneyDua]
}

extension FirestoreContentClient: DependencyKey {
    public static let liveValue: FirestoreContentClient = {
        let service = FirestoreContentService()
        return FirestoreContentClient(
            fetchAllDuas: { try await service.fetchAllDuas() },
            fetchDuasByCategory: { try await service.fetchDuasByCategory($0) },
            fetchAllCategories: { try await service.fetchAllCategories() },
            fetchAllJourneys: { try await service.fetchAllJourneys() },
            fetchJourneyDuas: { try await service.fetchJourneyDuas($0) }
        )
    }()

    public static let testValue = FirestoreContentClient(
        fetchAllDuas: { Dua.demoData },
        fetchDuasByCategory: { _ in Dua.demoData },
        fetchAllCategories: { DuaCategory.demoData },
        fetchAllJourneys: { [] },
        fetchJourneyDuas: { _ in [] }
    )
}

extension DependencyValues {
    public var firestoreContentClient: FirestoreContentClient {
        get { self[FirestoreContentClient.self] }
        set { self[FirestoreContentClient.self] = newValue }
    }
}
```

- **VALIDATE**: Build succeeds

---

### Task 4: UPDATE Dua Model for Firestore

- **FILE**: `RIZQ-iOS/RIZQKit/Models/Dua.swift`
- **IMPLEMENT**: Ensure `@DocumentID` for Firestore compatibility

The model already has proper `CodingKeys` for snake_case mapping. Add demo data for categories:

```swift
// Add to DuaCategory extension
extension DuaCategory {
    public static let demoData: [DuaCategory] = [
        DuaCategory(id: 1, name: "Morning", slug: .morning, description: "Morning adhkar"),
        DuaCategory(id: 2, name: "Evening", slug: .evening, description: "Evening adhkar"),
        DuaCategory(id: 3, name: "Rizq", slug: .rizq, description: "Supplications for provision"),
        DuaCategory(id: 4, name: "Gratitude", slug: .gratitude, description: "Gratitude prayers"),
    ]
}
```

- **VALIDATE**: Build succeeds

---

### Task 5: REBUILD LibraryFeature.swift

- **FILE**: `RIZQ-iOS/RIZQ/Features/Library/LibraryFeature.swift`
- **PATTERN**: Match React `LibraryPage.tsx` behavior
- **IMPORTS**: `ComposableArchitecture`, `Foundation`, `RIZQKit`

```swift
import ComposableArchitecture
import Foundation
import RIZQKit

// MARK: - Category Display Model (matches React)
struct CategoryDisplay: Equatable, Identifiable {
    let slug: CategorySlug?  // nil = "All"
    let name: String
    let emoji: String

    var id: String { slug?.rawValue ?? "all" }

    static let all: [CategoryDisplay] = [
        CategoryDisplay(slug: nil, name: "All", emoji: "📿"),
        CategoryDisplay(slug: .morning, name: "Morning", emoji: "🌅"),
        CategoryDisplay(slug: .evening, name: "Evening", emoji: "🌙"),
        CategoryDisplay(slug: .rizq, name: "Rizq", emoji: "💫"),
        CategoryDisplay(slug: .gratitude, name: "Gratitude", emoji: "🤲"),
    ]
}

// MARK: - Library Feature
@Reducer
struct LibraryFeature {
    @ObservableState
    struct State: Equatable {
        var duas: [Dua] = []
        var allDuas: [Dua] = []  // Cache for filtering
        var categories: [CategoryDisplay] = CategoryDisplay.all
        var searchText: String = ""
        var selectedCategory: CategorySlug?
        var isLoading: Bool = false
        var errorMessage: String?
        var activeHabitDuaIds: Set<Int> = []  // Track which duas are in habits

        @Presents var addToAdkharSheet: AddToAdkharSheetFeature.State?

        /// Computed filtered duas (search + category)
        var filteredDuas: [Dua] {
            var result = selectedCategory == nil ? allDuas : duas

            if !searchText.isEmpty {
                let query = searchText.lowercased()
                result = result.filter {
                    $0.titleEn.lowercased().contains(query) ||
                    $0.arabicText.contains(query) ||
                    ($0.transliteration?.lowercased().contains(query) ?? false) ||
                    $0.translationEn.lowercased().contains(query)
                }
            }

            return result
        }
    }

    enum Action: BindableAction {
        case binding(BindingAction<State>)
        case onAppear
        case duasLoaded(Result<[Dua], Error>)
        case categorySelected(CategorySlug?)
        case categoryDuasLoaded(Result<[Dua], Error>)
        case duaTapped(Dua)
        case addToAdkharTapped(Dua)
        case addToAdkharSheet(PresentationAction<AddToAdkharSheetFeature.Action>)
        case retryTapped
    }

    @Dependency(\.firestoreContentClient) var contentClient
    @Dependency(\.continuousClock) var clock

    private enum CancelID { case search }

    var body: some ReducerOf<Self> {
        BindingReducer()

        Reduce { state, action in
            switch action {
            case .binding(\.searchText):
                // Search filtering is handled by computed property
                return .none

            case .binding:
                return .none

            case .onAppear:
                guard state.allDuas.isEmpty else { return .none }
                state.isLoading = true
                state.errorMessage = nil

                return .run { send in
                    do {
                        let duas = try await contentClient.fetchAllDuas()
                        await send(.duasLoaded(.success(duas)))
                    } catch {
                        await send(.duasLoaded(.failure(error)))
                    }
                }

            case .duasLoaded(.success(let duas)):
                state.isLoading = false
                state.duas = duas
                state.allDuas = duas
                return .none

            case .duasLoaded(.failure(let error)):
                state.isLoading = false
                state.errorMessage = error.localizedDescription
                return .none

            case .categorySelected(let category):
                state.selectedCategory = category

                guard let categorySlug = category else {
                    // "All" selected - show cached duas
                    state.duas = state.allDuas
                    return .none
                }

                state.isLoading = true
                return .run { send in
                    do {
                        let duas = try await contentClient.fetchDuasByCategory(categorySlug)
                        await send(.categoryDuasLoaded(.success(duas)))
                    } catch {
                        await send(.categoryDuasLoaded(.failure(error)))
                    }
                }

            case .categoryDuasLoaded(.success(let duas)):
                state.isLoading = false
                state.duas = duas
                return .none

            case .categoryDuasLoaded(.failure(let error)):
                state.isLoading = false
                state.errorMessage = error.localizedDescription
                // Fallback to client-side filtering
                if let slug = state.selectedCategory {
                    state.duas = state.allDuas.filter { dua in
                        // Match by bestTime field
                        dua.bestTime == slug.rawValue
                    }
                }
                return .none

            case .duaTapped:
                // Navigate to practice - handled by parent
                return .none

            case .addToAdkharTapped(let dua):
                state.addToAdkharSheet = AddToAdkharSheetFeature.State(dua: dua)
                return .none

            case .addToAdkharSheet(.presented(.delegate(.habitAdded(let duaId, _)))):
                state.activeHabitDuaIds.insert(duaId)
                return .none

            case .addToAdkharSheet:
                return .none

            case .retryTapped:
                state.errorMessage = nil
                state.selectedCategory = nil
                return .send(.onAppear)
            }
        }
        .ifLet(\.$addToAdkharSheet, action: \.addToAdkharSheet) {
            AddToAdkharSheetFeature()
        }
    }
}
```

- **VALIDATE**: Build succeeds

---

### Task 6: REBUILD LibraryView.swift

- **FILE**: `RIZQ-iOS/RIZQ/Features/Library/LibraryView.swift`
- **PATTERN**: Match React `LibraryPage.tsx` layout (vertical list, not grid)
- **IMPORTS**: `SwiftUI`, `ComposableArchitecture`, `RIZQKit`

```swift
import SwiftUI
import ComposableArchitecture
import RIZQKit

struct LibraryView: View {
    @Bindable var store: StoreOf<LibraryFeature>

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: RIZQSpacing.lg) {
                    // Header (matches React)
                    headerSection

                    // Search Bar
                    searchBar

                    // Category Filter Pills (matches React emojis)
                    categoryPills

                    // Dua List (vertical, not grid)
                    duaList
                }
                .padding(.horizontal, RIZQSpacing.lg)
                .padding(.bottom, RIZQSpacing.huge)
            }
            .rizqPageBackground()
            .navigationBarHidden(true)
        }
        .onAppear {
            store.send(.onAppear)
        }
        .sheet(
            item: $store.scope(state: \.addToAdkharSheet, action: \.addToAdkharSheet)
        ) { sheetStore in
            AddToAdkharSheetView(store: sheetStore)
                .presentationDetents([.medium])
                .presentationDragIndicator(.visible)
        }
    }

    // MARK: - Header (matches React BookOpen icon + title)
    private var headerSection: some View {
        VStack(alignment: .leading, spacing: RIZQSpacing.sm) {
            HStack(spacing: RIZQSpacing.sm) {
                Image(systemName: "book.fill")
                    .font(.system(size: 28))
                    .foregroundStyle(Color.rizqPrimary)

                Text("Dua Library")
                    .font(.rizqDisplayBold(.largeTitle))
                    .foregroundStyle(Color.rizqText)
            }

            Text("\(store.allDuas.count) authentic duas to explore")
                .font(.rizqSans(.subheadline))
                .foregroundStyle(Color.rizqTextSecondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.top, RIZQSpacing.lg)
    }

    // MARK: - Search Bar
    private var searchBar: some View {
        HStack(spacing: RIZQSpacing.sm) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(Color.rizqMuted)

            TextField("Search duas...", text: $store.searchText)
                .font(.rizqSans(.body))
        }
        .padding(RIZQSpacing.md)
        .background(Color.rizqCard)
        .clipShape(RoundedRectangle(cornerRadius: RIZQRadius.btn))
        .overlay(
            RoundedRectangle(cornerRadius: RIZQRadius.btn)
                .stroke(Color.rizqBorder, lineWidth: 1)
        )
    }

    // MARK: - Category Pills (matches React emojis)
    private var categoryPills: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: RIZQSpacing.sm) {
                ForEach(store.categories) { category in
                    categoryPill(category)
                }
            }
            .padding(.horizontal, 1) // Prevent clipping
        }
    }

    private func categoryPill(_ category: CategoryDisplay) -> some View {
        let isSelected = store.selectedCategory == category.slug

        return Button {
            store.send(.categorySelected(category.slug))
        } label: {
            HStack(spacing: RIZQSpacing.xs) {
                Text(category.emoji)
                    .font(.system(size: 16))
                Text(category.name)
                    .font(.rizqSansMedium(.subheadline))
            }
            .padding(.horizontal, RIZQSpacing.md)
            .padding(.vertical, RIZQSpacing.sm)
            .background(isSelected ? Color.rizqPrimary : Color.rizqCard)
            .foregroundStyle(isSelected ? .white : Color.rizqText)
            .clipShape(Capsule())
            .overlay(
                Capsule()
                    .stroke(isSelected ? Color.clear : Color.rizqBorder, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Dua List (vertical layout, matches React)
    private var duaList: some View {
        Group {
            if store.isLoading {
                loadingState
            } else if let error = store.errorMessage {
                errorState(error)
            } else if store.filteredDuas.isEmpty {
                emptyState
            } else {
                LazyVStack(spacing: RIZQSpacing.md) {
                    ForEach(store.filteredDuas) { dua in
                        DuaListCardView(
                            dua: dua,
                            isActive: store.activeHabitDuaIds.contains(dua.id),
                            onTap: { store.send(.duaTapped(dua)) },
                            onAddToAdkhar: { store.send(.addToAdkharTapped(dua)) }
                        )
                    }
                }

                // Results count
                Text("\(store.filteredDuas.count) duas")
                    .font(.rizqSans(.footnote))
                    .foregroundStyle(Color.rizqMuted)
                    .padding(.top, RIZQSpacing.sm)
            }
        }
    }

    // MARK: - Loading State
    private var loadingState: some View {
        VStack(spacing: RIZQSpacing.lg) {
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle(tint: Color.rizqPrimary))
                .scaleEffect(1.2)

            Text("Loading duas...")
                .font(.rizqSans(.subheadline))
                .foregroundStyle(Color.rizqTextSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, RIZQSpacing.huge)
    }

    // MARK: - Error State
    private func errorState(_ message: String) -> some View {
        VStack(spacing: RIZQSpacing.lg) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 48))
                .foregroundStyle(Color.red.opacity(0.7))

            Text("Unable to load duas")
                .font(.rizqSansSemiBold(.headline))
                .foregroundStyle(Color.rizqText)

            Text(message)
                .font(.rizqSans(.subheadline))
                .foregroundStyle(Color.rizqMuted)
                .multilineTextAlignment(.center)

            Button {
                store.send(.retryTapped)
            } label: {
                HStack(spacing: RIZQSpacing.sm) {
                    Image(systemName: "arrow.clockwise")
                    Text("Retry")
                }
                .rizqPrimaryButton()
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, RIZQSpacing.huge)
    }

    // MARK: - Empty State
    private var emptyState: some View {
        VStack(spacing: RIZQSpacing.lg) {
            Image(systemName: "book.closed")
                .font(.system(size: 48))
                .foregroundStyle(Color.rizqMuted)

            Text("No duas found")
                .font(.rizqSansSemiBold(.headline))
                .foregroundStyle(Color.rizqText)

            Text("Try adjusting your search or filters")
                .font(.rizqSans(.subheadline))
                .foregroundStyle(Color.rizqMuted)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, RIZQSpacing.huge)
    }
}
```

- **VALIDATE**: Build succeeds

---

### Task 7: CREATE DuaListCardView (matches React DuaCard)

- **FILE**: `RIZQ-iOS/RIZQ/Views/Components/DuaViews/DuaListCardView.swift`
- **PATTERN**: Match React `DuaCard.tsx` design
- **IMPLEMENTS**: Title, category badge, XP value, repetitions, "Active" badge

```swift
import SwiftUI
import RIZQKit

struct DuaListCardView: View {
    let dua: Dua
    let isActive: Bool
    let onTap: () -> Void
    let onAddToAdkhar: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: RIZQSpacing.md) {
                // Main content
                VStack(alignment: .leading, spacing: RIZQSpacing.sm) {
                    // Title row with category badge
                    HStack(spacing: RIZQSpacing.sm) {
                        Text(dua.titleEn)
                            .font(.rizqSansSemiBold(.headline))
                            .foregroundStyle(Color.rizqText)
                            .lineLimit(1)

                        // Category badge
                        if let categoryId = dua.categoryId {
                            CategoryBadgeView(categoryId: categoryId)
                        }

                        Spacer()

                        // Active badge (if in habits)
                        if isActive {
                            Text("Active")
                                .font(.rizqSans(.caption2))
                                .foregroundStyle(Color.rizqSuccess)
                                .padding(.horizontal, RIZQSpacing.sm)
                                .padding(.vertical, 2)
                                .background(Color.rizqSuccess.opacity(0.15))
                                .clipShape(Capsule())
                        }
                    }

                    // Metadata row: XP + Repetitions
                    HStack(spacing: RIZQSpacing.md) {
                        // XP value
                        HStack(spacing: 4) {
                            Image(systemName: "sparkles")
                                .font(.system(size: 12))
                            Text("+\(dua.xpValue)")
                                .font(.rizqMono(.caption))
                        }
                        .foregroundStyle(Color.rizqPrimary)

                        // Repetitions
                        HStack(spacing: 4) {
                            Image(systemName: "repeat")
                                .font(.system(size: 12))
                            Text("×\(dua.repetitions)")
                                .font(.rizqMono(.caption))
                        }
                        .foregroundStyle(Color.rizqMuted)

                        Spacer()
                    }
                }

                // Action button
                Button(action: onAddToAdkhar) {
                    Image(systemName: isActive ? "checkmark" : "plus")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundStyle(isActive ? Color.rizqSuccess : Color.rizqPrimary)
                        .frame(width: 32, height: 32)
                        .background(
                            Circle()
                                .fill(isActive ? Color.rizqSuccess.opacity(0.15) : Color.rizqPrimary.opacity(0.1))
                        )
                }
                .buttonStyle(.plain)
                .disabled(isActive)
            }
            .padding(RIZQSpacing.md)
            .background(Color.rizqCard)
            .clipShape(RoundedRectangle(cornerRadius: RIZQRadius.card))
            .shadow(color: .black.opacity(0.05), radius: 4, y: 2)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Category Badge View
struct CategoryBadgeView: View {
    let categoryId: Int

    private var categoryInfo: (name: String, color: Color) {
        switch categoryId {
        case 1: return ("Morning", .orange)
        case 2: return ("Evening", .purple)
        case 3: return ("Rizq", .green)
        case 4: return ("Gratitude", .pink)
        default: return ("Other", .gray)
        }
    }

    var body: some View {
        Text(categoryInfo.name)
            .font(.rizqSans(.caption2))
            .foregroundStyle(categoryInfo.color)
            .padding(.horizontal, RIZQSpacing.sm)
            .padding(.vertical, 2)
            .background(categoryInfo.color.opacity(0.15))
            .clipShape(Capsule())
    }
}
```

- **VALIDATE**: Build succeeds

---

### Task 8: UPDATE Dependencies.swift

- **FILE**: `RIZQ-iOS/RIZQKit/Services/Dependencies.swift`
- **IMPLEMENT**: Add `firestoreContentClient` dependency (from Task 3)
- **VALIDATE**: Build succeeds

---

### Task 9: INTEGRATION Testing

Run full test suite to ensure no regressions:

```bash
cd RIZQ-iOS && bundle exec fastlane test
```

Or manual build:

```bash
xcodebuild -scheme RIZQ -destination 'platform=iOS Simulator,name=iPhone 16' test
```

---

## TESTING STRATEGY

### Unit Tests

Create `LibraryFeatureTests.swift`:

```swift
@MainActor
func testOnAppearLoadsDuas() async {
    let store = TestStore(initialState: LibraryFeature.State()) {
        LibraryFeature()
    } withDependencies: {
        $0.firestoreContentClient.fetchAllDuas = { Dua.demoData }
    }

    await store.send(.onAppear) {
        $0.isLoading = true
    }

    await store.receive(.duasLoaded(.success(Dua.demoData))) {
        $0.isLoading = false
        $0.duas = Dua.demoData
        $0.allDuas = Dua.demoData
    }
}

@MainActor
func testCategoryFilter() async {
    let store = TestStore(initialState: LibraryFeature.State(allDuas: Dua.demoData)) {
        LibraryFeature()
    } withDependencies: {
        $0.firestoreContentClient.fetchDuasByCategory = { _ in
            [Dua.demoData[0]]
        }
    }

    await store.send(.categorySelected(.morning)) {
        $0.selectedCategory = .morning
        $0.isLoading = true
    }

    await store.receive(.categoryDuasLoaded(.success([Dua.demoData[0]]))) {
        $0.isLoading = false
        $0.duas = [Dua.demoData[0]]
    }
}

@MainActor
func testSearchFiltering() async {
    var state = LibraryFeature.State(allDuas: Dua.demoData)
    state.searchText = "morning"

    // Verify computed property filters correctly
    XCTAssertTrue(state.filteredDuas.allSatisfy {
        $0.titleEn.lowercased().contains("morning")
    })
}
```

### Snapshot Tests

Add to `RIZQSnapshotTests.swift`:

```swift
func testLibraryView() {
    let store = Store(initialState: LibraryFeature.State(
        duas: Dua.demoData,
        allDuas: Dua.demoData
    )) {
        LibraryFeature()
    }

    let view = LibraryView(store: store)
        .frame(width: 390, height: 844) // iPhone 14 Pro

    assertSnapshot(of: view, as: .image)
}

func testDuaListCardView() {
    let view = DuaListCardView(
        dua: Dua.demoData[0],
        isActive: false,
        onTap: {},
        onAddToAdkhar: {}
    )
    .frame(width: 350)
    .padding()

    assertSnapshot(of: view, as: .image)
}
```

---

## VALIDATION COMMANDS

### Level 1: Syntax & Style

```bash
cd RIZQ-iOS && swiftlint lint
```

### Level 2: Build

```bash
cd RIZQ-iOS && xcodebuild -scheme RIZQ -destination 'platform=iOS Simulator,name=iPhone 16' build
```

### Level 3: Unit Tests

```bash
cd RIZQ-iOS && xcodebuild -scheme RIZQ -destination 'platform=iOS Simulator,name=iPhone 16' test
```

### Level 4: Manual Validation

1. Launch app in simulator
2. Navigate to Library tab
3. Verify header shows "Dua Library" with book icon
4. Verify category pills display with emojis (📿 All, 🌅 Morning, etc.)
5. Tap category pill - verify filtering works
6. Type in search - verify search filtering works
7. Verify dua cards show title, category badge, XP, repetitions
8. Tap "+" button - verify Add to Adkhar sheet appears
9. Verify "Active" badge appears for duas already in habits

---

## DATA MIGRATION COMMANDS (MCP Tools)

### Step 1: Query Existing Data from Neon

```
mcp__Neon__run_sql: SELECT * FROM categories ORDER BY id
mcp__Neon__run_sql: SELECT * FROM collections ORDER BY id
mcp__Neon__run_sql: SELECT * FROM duas ORDER BY id
mcp__Neon__run_sql: SELECT * FROM journeys ORDER BY sort_order
mcp__Neon__run_sql: SELECT * FROM journey_duas ORDER BY journey_id, sort_order
```

### Step 2: Write Data to Firestore

For each record, use the Firebase MCP tools to create documents in the appropriate collections.

---

## ACCEPTANCE CRITERIA

- [ ] All dua data migrated from Neon to Firestore
- [ ] LibraryView displays vertical list (not grid)
- [ ] Category filter pills match React design with emojis
- [ ] Dua cards show title, category badge, XP, repetitions
- [ ] Search filtering works correctly
- [ ] Category filtering fetches from Firestore
- [ ] "Active" badge displays for duas in user's habits
- [ ] Add to Adkhar sheet works correctly
- [ ] Loading, error, and empty states display properly
- [ ] All unit tests pass
- [ ] Build succeeds without errors

---

## COMPLETION CHECKLIST

- [ ] Data migration completed (Neon → Firestore)
- [ ] FirestoreContentService created
- [ ] FirestoreContentClient dependency registered
- [ ] LibraryFeature.swift rebuilt
- [ ] LibraryView.swift rebuilt with vertical list
- [ ] DuaListCardView created matching React design
- [ ] Unit tests added and passing
- [ ] Snapshot tests added
- [ ] Manual testing completed
- [ ] All validation commands pass

---

## NOTES

### Design Decisions

1. **Vertical List vs Grid**: Changed from 2-column grid to vertical list to match React design and improve readability on mobile.

2. **Category Emojis**: Using emojis (📿 🌅 🌙 💫 🤲) instead of SF Symbols to match React exactly.

3. **Firestore vs Neon**: Migrating to Firestore provides:
   - Better offline support (built into Firebase SDK)
   - Simpler auth integration (already using Firebase Auth)
   - No separate backend required
   - Real-time sync capability for future features

4. **Active Badge**: Shows "Active" for duas already added to user's daily habits, matching React behavior.

### Migration Considerations

- Keep Neon data as backup until migration verified
- Test Firestore security rules with authenticated user
- Verify Codable mapping works with Firestore document structure
- Handle potential data type differences (Neon integers vs Firestore numbers)

### Confidence Score: 8/10

High confidence due to:
- Clear target design from React screenshots
- Existing patterns in codebase to follow
- Well-documented TCA architecture
- Firebase already integrated for auth

Minor risks:
- Firestore Codable mapping may need adjustments
- Category ID lookup for filtering adds complexity
- Need to verify security rules allow reads
