# The Composable Architecture (TCA) Best Practices Reference

A concise reference guide for building features with The Composable Architecture in the RIZQ iOS app.

---

## Table of Contents

1. [Feature Structure](#1-feature-structure)
2. [State Design](#2-state-design)
3. [Action Naming](#3-action-naming)
4. [Effects & Side Effects](#4-effects--side-effects)
5. [Navigation & Presentation](#5-navigation--presentation)
6. [Parent-Child Communication](#6-parent-child-communication)
7. [Dependencies](#7-dependencies)
8. [Testing Reducers](#8-testing-reducers)
9. [Performance](#9-performance)
10. [Anti-Patterns](#10-anti-patterns)

---

## 1. Feature Structure

### Standard Feature Layout

```swift
import ComposableArchitecture

@Reducer
struct MyFeature {
    // 1. State
    @ObservableState
    struct State: Equatable {
        var items: [Item] = []
        var isLoading = false
        var error: String?

        // Child feature state (optional)
        @Presents var detail: DetailFeature.State?
    }

    // 2. Actions
    enum Action {
        // User interactions
        case onAppear
        case refreshTapped
        case itemTapped(Item)

        // Effect responses
        case itemsLoaded(Result<[Item], Error>)

        // Child actions
        case detail(PresentationAction<DetailFeature.Action>)
    }

    // 3. Dependencies
    @Dependency(\.apiClient) var apiClient
    @Dependency(\.dismiss) var dismiss

    // 4. Reducer body
    var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .onAppear:
                // Handle action
                return .none
            // ... other cases
            }
        }
        .ifLet(\.$detail, action: \.detail) {
            DetailFeature()
        }
    }
}
```

### File Organization

```
Features/
└── Journeys/
    ├── JourneysFeature.swift    # Reducer + State + Action
    ├── JourneysView.swift       # SwiftUI View
    └── JourneyDetailView.swift  # Child view (if needed)
```

### Key Principles

- **One feature per file**: Keep State, Action, and Reducer together
- **Views in separate files**: View logic stays out of the reducer
- **Explicit dependencies**: Declare all dependencies at the top

---

## 2. State Design

### ObservableState Macro

Always use `@ObservableState` for automatic observation:

```swift
@ObservableState
struct State: Equatable {
    var count = 0
    var name = ""
}
```

### Loading State Pattern

Use a consistent enum for loading states:

```swift
enum LoadingState: Equatable {
    case idle
    case loading
    case loaded
    case error(String)

    var isLoading: Bool {
        if case .loading = self { return true }
        return false
    }
}

@ObservableState
struct State: Equatable {
    var loadingState: LoadingState = .idle
    var items: [Item] = []
}
```

### Computed Properties

Add computed properties for derived state:

```swift
@ObservableState
struct State: Equatable {
    var items: [Item] = []
    var selectedId: Int?

    // Computed
    var selectedItem: Item? {
        items.first { $0.id == selectedId }
    }

    var isEmpty: Bool { items.isEmpty }
    var itemCount: Int { items.count }
}
```

### Optional Child State with @Presents

```swift
@ObservableState
struct State: Equatable {
    // Modal presentation
    @Presents var detail: DetailFeature.State?

    // Alert
    @Presents var alert: AlertState<Action.Alert>?

    // Confirmation dialog
    @Presents var confirmationDialog: ConfirmationDialogState<Action.Dialog>?
}
```

---

## 3. Action Naming

### Naming Conventions

| Action Type | Convention | Example |
|-------------|------------|---------|
| User tap | `[thing]Tapped` | `refreshTapped`, `itemTapped(Item)` |
| Lifecycle | `on[Event]` | `onAppear`, `onDisappear` |
| Text input | `[field]Changed` | `searchTextChanged(String)` |
| Toggle | `[thing]Toggled` | `darkModeToggled` |
| Effect result | `[thing][PastVerb]` | `itemsLoaded`, `saveFailed` |
| Delegate | `delegate(Delegate)` | `delegate(.didComplete)` |

### Action Structure

```swift
enum Action {
    // User interactions (verbs, present tense)
    case onAppear
    case refreshTapped
    case itemTapped(Item)
    case searchTextChanged(String)

    // Effect responses (past tense)
    case itemsLoaded(Result<[Item], Error>)
    case itemSaved(Item)
    case deleteFailed(Error)

    // Child feature actions
    case detail(PresentationAction<DetailFeature.Action>)
    case path(StackActionOf<Path>)

    // Delegate actions (for parent communication)
    enum Delegate {
        case didSelectItem(Item)
        case didComplete
    }
    case delegate(Delegate)
}
```

### Avoid Imperative Names

```swift
// Bad - imperative
case loadItems
case saveItem

// Good - describes what happened
case onAppear        // triggers loading
case saveTapped      // triggers save
case itemsLoaded     // result of loading
```

---

## 4. Effects & Side Effects

### Basic Effect Pattern

```swift
case .onAppear:
    state.loadingState = .loading
    return .run { send in
        let result = await Result {
            try await apiClient.fetchItems()
        }
        await send(.itemsLoaded(result))
    }

case .itemsLoaded(.success(let items)):
    state.loadingState = .loaded
    state.items = items
    return .none

case .itemsLoaded(.failure(let error)):
    state.loadingState = .error(error.localizedDescription)
    return .none
```

### TaskResult Pattern

```swift
case .onAppear:
    return .run { send in
        await send(.dataLoaded(TaskResult {
            try await apiClient.fetchData()
        }))
    }
```

### Parallel Effects with .merge

```swift
case .onAppear:
    return .merge(
        .run { send in
            await send(.profileLoaded(try await apiClient.fetchProfile()))
        },
        .run { send in
            await send(.journeysLoaded(try await apiClient.fetchJourneys()))
        }
    )
```

### Sequential Effects with .concatenate

```swift
case .submitTapped:
    return .concatenate(
        .run { send in
            await send(.validationResult(validate(state)))
        },
        .run { [state] send in
            await send(.saveResult(try await apiClient.save(state.data)))
        }
    )
```

### Debounced Effects

```swift
private enum CancelID { case search }

case .searchTextChanged(let text):
    state.searchText = text
    return .run { send in
        try await Task.sleep(for: .milliseconds(300))
        await send(.searchResults(try await apiClient.search(text)))
    }
    .cancellable(id: CancelID.search, cancelInFlight: true)
```

### Cancellation

```swift
case .onDisappear:
    return .cancel(id: CancelID.search)
```

---

## 5. Navigation & Presentation

### Modal Presentation with @Presents

**Step 1: State**
```swift
@ObservableState
struct State: Equatable {
    @Presents var detail: DetailFeature.State?
}
```

**Step 2: Action**
```swift
enum Action {
    case detail(PresentationAction<DetailFeature.Action>)
    case showDetailTapped(Item)
}
```

**Step 3: Reducer**
```swift
var body: some ReducerOf<Self> {
    Reduce { state, action in
        switch action {
        case .showDetailTapped(let item):
            state.detail = DetailFeature.State(item: item)
            return .none

        case .detail(.presented(.closeTapped)):
            state.detail = nil
            return .none

        case .detail:
            return .none
        }
    }
    .ifLet(\.$detail, action: \.detail) {
        DetailFeature()
    }
}
```

**Step 4: View**
```swift
struct MyView: View {
    @Bindable var store: StoreOf<MyFeature>

    var body: some View {
        List { /* ... */ }
            .sheet(item: $store.scope(state: \.detail, action: \.detail)) { store in
                DetailView(store: store)
            }
    }
}
```

### Stack Navigation

```swift
@Reducer
struct AppFeature {
    @Reducer
    enum Path {
        case detail(DetailFeature)
        case settings(SettingsFeature)
    }

    @ObservableState
    struct State: Equatable {
        var path = StackState<Path.State>()
    }

    enum Action {
        case path(StackActionOf<Path>)
        case pushDetailTapped(Item)
    }

    var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .pushDetailTapped(let item):
                state.path.append(.detail(DetailFeature.State(item: item)))
                return .none
            case .path:
                return .none
            }
        }
        .forEach(\.path, action: \.path)
    }
}
```

---

## 6. Parent-Child Communication

### Child Signals Intent, Parent Decides

**Child Feature**
```swift
@Reducer
struct ChildFeature {
    enum Action {
        case doneTapped
        case delegate(Delegate)

        enum Delegate {
            case didComplete(Item)
        }
    }

    var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .doneTapped:
                return .send(.delegate(.didComplete(state.item)))
            case .delegate:
                return .none
            }
        }
    }
}
```

**Parent Feature**
```swift
@Reducer
struct ParentFeature {
    @ObservableState
    struct State: Equatable {
        @Presents var child: ChildFeature.State?
    }

    enum Action {
        case child(PresentationAction<ChildFeature.Action>)
    }

    var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .child(.presented(.delegate(.didComplete(let item)))):
                // Parent handles the completed item
                state.items.append(item)
                state.child = nil  // Dismiss
                return .none
            case .child:
                return .none
            }
        }
        .ifLet(\.$child, action: \.child) {
            ChildFeature()
        }
    }
}
```

### Key Principle

> Child features signal intent without knowing how the parent will respond. This keeps features decoupled and testable.

---

## 7. Dependencies

### Declaring Dependencies

```swift
@Reducer
struct MyFeature {
    @Dependency(\.apiClient) var apiClient
    @Dependency(\.date.now) var now
    @Dependency(\.uuid) var uuid
    @Dependency(\.dismiss) var dismiss
}
```

### Using Dependencies

```swift
case .saveTapped:
    let id = uuid()
    let timestamp = now
    return .run { [state] send in
        try await apiClient.save(Item(id: id, createdAt: timestamp, data: state.data))
        await send(.saveSucceeded)
    }
```

### Dismissal

```swift
case .closeTapped:
    return .run { _ in
        await dismiss()
    }
```

### Custom Dependencies

See `dependencies-and-di.md` for creating custom dependencies.

---

## 8. Testing Reducers

### Basic Test Structure

```swift
import XCTest
@testable import RIZQ
import ComposableArchitecture

final class JourneysFeatureTests: XCTestCase {
    @MainActor
    func testOnAppearLoadsJourneys() async {
        let store = TestStore(
            initialState: JourneysFeature.State()
        ) {
            JourneysFeature()
        } withDependencies: {
            $0.apiClient.fetchJourneys = {
                [Journey(id: 1, name: "Morning")]
            }
        }

        await store.send(.onAppear) {
            $0.loadingState = .loading
        }

        await store.receive(.journeysLoaded(.success([Journey(id: 1, name: "Morning")]))) {
            $0.loadingState = .loaded
            $0.journeys = [Journey(id: 1, name: "Morning")]
        }
    }
}
```

### Testing Effects

```swift
@MainActor
func testRefreshReloadsData() async {
    let store = TestStore(
        initialState: MyFeature.State(items: [.mock])
    ) {
        MyFeature()
    } withDependencies: {
        $0.apiClient.fetchItems = { [.mock, .mock2] }
    }

    await store.send(.refreshTapped) {
        $0.isRefreshing = true
    }

    await store.receive(.itemsLoaded(.success([.mock, .mock2]))) {
        $0.isRefreshing = false
        $0.items = [.mock, .mock2]
    }
}
```

### Non-Exhaustive Testing

For tests that don't need to verify every state change:

```swift
@MainActor
func testNavigationFlow() async {
    let store = TestStore(initialState: AppFeature.State()) {
        AppFeature()
    }
    store.exhaustivity = .off

    await store.send(.showDetailTapped(.mock))
    XCTAssertNotNil(store.state.detail)
}
```

---

## 9. Performance

### Avoid Expensive Computed Properties

```swift
// Bad - recomputes on every state change
var sortedItems: [Item] {
    items.sorted { $0.date > $1.date }
}

// Good - store sorted or use Identified collections
var items: IdentifiedArrayOf<Item> = []
```

### Use IdentifiedArray

```swift
import IdentifiedCollections

@ObservableState
struct State: Equatable {
    var items: IdentifiedArrayOf<Item> = []
}

// Access by ID in O(1)
state.items[id: itemId]
```

### Scope Stores Efficiently

```swift
// Cache the scoped store in a let binding
let detailStore = store.scope(state: \.detail, action: \.detail)

ForEach(store.scope(state: \.items, action: \.item)) { itemStore in
    ItemRow(store: itemStore)
}
```

---

## 10. Anti-Patterns

### Don't Perform Side Effects in State

```swift
// Bad
@ObservableState
struct State: Equatable {
    var items: [Item] = [] {
        didSet { saveToUserDefaults() }  // Side effect!
    }
}

// Good - effects in reducer
case .itemsChanged(let items):
    state.items = items
    return .run { _ in
        try await persistence.save(items)
    }
```

### Don't Access Dependencies Outside Reducer Body

```swift
// Bad
@Dependency(\.apiClient) var apiClient

func someHelper() {
    apiClient.fetch()  // Won't work correctly
}

// Good - access inside reduce closure
var body: some ReducerOf<Self> {
    Reduce { state, action in
        // Access dependencies here
        return .run { send in
            await apiClient.fetch()
        }
    }
}
```

### Don't Block the Main Thread

```swift
// Bad - synchronous blocking
case .loadData:
    let data = try! Data(contentsOf: url)  // Blocks!
    return .none

// Good - async effect
case .loadData:
    return .run { send in
        let data = try await loadDataAsync()
        await send(.dataLoaded(data))
    }
```

### Don't Ignore Exhaustive Assertions

```swift
// Bad - store.exhaustivity = .off everywhere
// Good - only use .off when testing specific flows

// Tests should verify all state mutations by default
await store.send(.action) {
    $0.field = newValue  // Verify this!
}
```

### Don't Nest Reducers Incorrectly

```swift
// Bad - calling reducer inside Reduce
Reduce { state, action in
    ChildFeature().reduce(into: &state.child, action: action)  // Wrong!
}

// Good - use composition operators
var body: some ReducerOf<Self> {
    Scope(state: \.child, action: \.child) {
        ChildFeature()
    }
    Reduce { state, action in
        // Parent logic
    }
}
```
