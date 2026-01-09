# Best Practices for RIZQ iOS Development

This document outlines coding standards, patterns, and conventions for the RIZQ iOS application.

---

## TCA (The Composable Architecture) Patterns

### Feature Structure

Every feature should follow this organization:

```swift
@Reducer
struct MyFeature {
    // 1. State - Always @ObservableState
    @ObservableState
    struct State: Equatable {
        var loadingState: LoadingState = .idle
        var data: [Item] = []
        var error: String?

        // Computed properties
        var isEmpty: Bool { data.isEmpty }

        // Child feature state (optional)
        @Presents var detail: DetailFeature.State?
    }

    // 2. Actions - Enum with clear naming
    enum Action {
        // User actions (verbs)
        case onAppear
        case refreshTapped
        case itemTapped(Item)

        // Effect responses (past tense)
        case dataLoaded(TaskResult<[Item], Error>)

        // Child actions
        case detail(PresentationAction<DetailFeature.Action>)
    }

    // 3. Dependencies
    @Dependency(\.myService) var myService
    @Dependency(\.dismiss) var dismiss

    // 4. Body
    var body: some ReducerOf<Self> {
        Reduce { state, action in
            // Handle actions
        }
        .ifLet(\.$detail, action: \.detail) {
            DetailFeature()
        }
    }
}
```

### Loading State Enum

Use a consistent loading state pattern:

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
```

### Effect Patterns

```swift
// Simple async effect
case .onAppear:
    state.loadingState = .loading
    return .run { send in
        await send(.dataLoaded(TaskResult {
            try await service.fetchData()
        }))
    }

// Parallel effects
case .onAppear:
    return .merge(
        .run { send in await send(.profileLoaded(/* ... */)) },
        .run { send in await send(.activityLoaded(/* ... */)) }
    )

// Debounced effect
case .searchQueryChanged(let query):
    state.searchQuery = query
    return .run { send in
        try await Task.sleep(for: .milliseconds(300))
        await send(.performSearch)
    }
    .cancellable(id: CancelID.search, cancelInFlight: true)

// Fire and forget
case .habitCompleted(let id):
    return .run { _ in
        await habitsClient.markCompleted(id)
    }
```

---

## SwiftUI View Patterns

### View Structure

```swift
struct MyView: View {
    @Bindable var store: StoreOf<MyFeature>

    var body: some View {
        content
            .navigationTitle("Title")
            .task { store.send(.onAppear) }
            .sheet(item: $store.scope(state: \.detail, action: \.detail)) { detailStore in
                DetailView(store: detailStore)
            }
    }

    // MARK: - Subviews

    @ViewBuilder
    private var content: some View {
        switch store.loadingState {
        case .loading:
            loadingView
        case .error(let message):
            errorView(message)
        case .loaded where store.isEmpty:
            emptyView
        default:
            loadedView
        }
    }

    private var loadingView: some View { /* ... */ }
    private var emptyView: some View { /* ... */ }
    private var loadedView: some View { /* ... */ }
    private func errorView(_ message: String) -> some View { /* ... */ }
}
```

### Reusable Components

Components should be stateless and take closures for actions:

```swift
struct JourneyCard: View {
    let journey: Journey
    let isActive: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            // Card content
        }
        .buttonStyle(.plain)
    }
}

// Usage
JourneyCard(journey: journey, isActive: true) {
    store.send(.journeyTapped(journey))
}
```

### Animation Patterns

```swift
// Implicit animations
.animation(.spring(response: 0.3), value: isExpanded)

// Explicit animations
withAnimation(.easeInOut(duration: 0.2)) {
    isExpanded.toggle()
}

// Transitions
.transition(.move(edge: .bottom).combined(with: .opacity))

// Scale on tap
.buttonStyle(TapScaleButtonStyle())

struct TapScaleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.95 : 1)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}
```

---

## Data Layer Patterns

### Service Actor Pattern

```swift
public actor MyService {
    private let client: APIClient

    public init(client: APIClient = .live) {
        self.client = client
    }

    public func fetchData() async throws -> [Item] {
        let rows: [ItemRow] = try await client.execute("SELECT * FROM items")
        return rows.map(Item.init(from:))
    }
}
```

### Database Row Mapping

Always map database rows to domain models:

```swift
// Database row (snake_case)
struct ItemRow: Codable {
    let id: Int
    let title_en: String
    let created_at: String
}

// Domain model (camelCase)
struct Item: Identifiable, Equatable {
    let id: Int
    let titleEn: String
    let createdAt: Date
}

// Mapping
extension Item {
    init(from row: ItemRow) {
        self.id = row.id
        self.titleEn = row.title_en
        self.createdAt = ISO8601DateFormatter().date(from: row.created_at) ?? Date()
    }
}
```

### TCA Dependency Client

```swift
@DependencyClient
struct MyServiceClient {
    var fetchItems: @Sendable () async throws -> [Item]
    var saveItem: @Sendable (_ item: Item) async throws -> Void
}

extension MyServiceClient: DependencyKey {
    static let liveValue = MyServiceClient(
        fetchItems: { try await MyService.shared.fetchItems() },
        saveItem: { try await MyService.shared.saveItem($0) }
    )

    static let previewValue = MyServiceClient(
        fetchItems: { [.preview] },
        saveItem: { _ in }
    )
}

extension DependencyValues {
    var myServiceClient: MyServiceClient {
        get { self[MyServiceClient.self] }
        set { self[MyServiceClient.self] = newValue }
    }
}
```

---

## Error Handling

### User-Friendly Errors

```swift
enum AppError: LocalizedError {
    case networkUnavailable
    case serverError(statusCode: Int)
    case invalidData
    case unauthorized

    var errorDescription: String? {
        switch self {
        case .networkUnavailable:
            return "Unable to connect. Please check your internet connection."
        case .serverError(let code):
            return "Server error (\(code)). Please try again later."
        case .invalidData:
            return "Invalid data received. Please try again."
        case .unauthorized:
            return "Please sign in to continue."
        }
    }
}
```

### Error State View

```swift
struct ErrorView: View {
    let message: String
    let onRetry: () -> Void

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle")
                .font(.largeTitle)
                .foregroundStyle(.orange)

            Text("Something went wrong")
                .font(.headline)

            Text(message)
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            Button("Try Again", action: onRetry)
                .buttonStyle(.borderedProminent)
        }
        .padding()
    }
}
```

---

## Testing Patterns

### TestStore Setup

```swift
@MainActor
func test_example() async {
    let store = TestStore(initialState: MyFeature.State()) {
        MyFeature()
    } withDependencies: {
        $0.myService = .mock
        $0.uuid = .incrementing
    }

    await store.send(.onAppear) {
        $0.loadingState = .loading
    }

    await store.receive(\.dataLoaded.success) {
        $0.loadingState = .loaded
        $0.items = [/* expected items */]
    }
}
```

### Mock Services

```swift
extension MyServiceClient {
    static let mock = MyServiceClient(
        fetchItems: { [Item(id: 1, titleEn: "Test")] },
        saveItem: { _ in }
    )

    static func failing(_ error: Error) -> MyServiceClient {
        MyServiceClient(
            fetchItems: { throw error },
            saveItem: { _ in throw error }
        )
    }
}
```

### Snapshot Testing

```swift
func test_view_snapshot() {
    let view = MyView()
        .frame(width: 375, height: 812)

    assertSnapshot(of: view, as: .image)
}
```

---

## Naming Conventions

| Type | Convention | Example |
|------|------------|---------|
| Features | PascalCase + Feature | `HomeFeature`, `PracticeFeature` |
| Views | PascalCase + View | `HomeView`, `JourneyCardView` |
| Services | PascalCase + Service | `NeonService`, `FirestoreService` |
| Clients | PascalCase + Client | `UserDataClient`, `UserHabitsClient` |
| Actions | camelCase (verb) | `onAppear`, `itemTapped`, `dataLoaded` |
| State props | camelCase (noun) | `loadingState`, `items`, `selectedItem` |
| DB rows | snake_case | `title_en`, `created_at` |
| Models | camelCase | `titleEn`, `createdAt` |

---

## File Organization

```
Features/
├── Home/
│   ├── HomeFeature.swift      # TCA reducer
│   └── HomeView.swift         # SwiftUI view
├── Library/
│   ├── LibraryFeature.swift
│   └── LibraryView.swift

Views/
├── Components/
│   ├── Animations/
│   │   ├── CelebrationParticles.swift
│   │   └── RippleEffect.swift
│   ├── GamificationViews/
│   │   ├── StreakBadge.swift
│   │   └── XpProgressBar.swift
│   └── Cards/
│       ├── JourneyCardView.swift
│       └── DuaCardView.swift

Services/
├── API/
│   ├── APIClient.swift
│   └── NeonService.swift
├── Firebase/
│   ├── FirestoreService.swift
│   └── FirebaseAuthService.swift
├── Persistence/
│   └── UserHabitsStorage.swift
└── Dependencies.swift
```

---

## Performance Guidelines

### Do
- Use `LazyVStack` for long lists
- Cache computed properties when expensive
- Use `@ViewBuilder` for conditional content
- Debounce search inputs
- Cancel in-flight requests on new requests

### Don't
- Perform heavy computation in `body`
- Create new closures in loops
- Fetch data multiple times unnecessarily
- Block the main thread
- Store large data in @State

---

## Accessibility

```swift
// Add accessibility labels
Text("XP")
    .accessibilityLabel("Experience points: \(xp)")

// Group related elements
HStack { /* streak info */ }
    .accessibilityElement(children: .combine)
    .accessibilityLabel("Streak: \(streak) days")

// Mark decorative elements
Image("pattern")
    .accessibilityHidden(true)
```

---

## Common Pitfalls to Avoid

1. **Don't use `any` or `AnyView`** - Always use concrete types
2. **Don't ignore task cancellation** - Use `.cancellable()` for long-running effects
3. **Don't mutate state outside reducers** - All state changes go through actions
4. **Don't skip error states** - Every async operation needs error handling
5. **Don't hardcode strings** - Use constants or localization
6. **Don't forget `Equatable`** - TCA requires equatable state
7. **Don't block main thread** - Use async/await properly
8. **Don't forget preview data** - Every model needs `.preview` static
