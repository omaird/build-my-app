# SwiftUI Best Practices Reference

A concise reference guide for building SwiftUI views in the RIZQ iOS app (iOS 17+).

---

## Table of Contents

1. [View Structure](#1-view-structure)
2. [View Composition](#2-view-composition)
3. [State & Bindings](#3-state--bindings)
4. [TCA Store Integration](#4-tca-store-integration)
5. [Lists & Collections](#5-lists--collections)
6. [Navigation](#6-navigation)
7. [Sheets & Alerts](#7-sheets--alerts)
8. [Animations](#8-animations)
9. [Custom Components](#9-custom-components)
10. [Accessibility](#10-accessibility)
11. [Performance](#11-performance)
12. [Anti-Patterns](#12-anti-patterns)

---

## 1. View Structure

### Standard View Layout

```swift
import SwiftUI
import ComposableArchitecture

struct JourneysView: View {
    @Bindable var store: StoreOf<JourneysFeature>

    var body: some View {
        NavigationStack {
            content
                .navigationTitle("Journeys")
                .toolbar { toolbarContent }
        }
        .onAppear { store.send(.onAppear) }
    }

    // MARK: - Content

    @ViewBuilder
    private var content: some View {
        if store.isLoading {
            loadingView
        } else if store.journeys.isEmpty {
            emptyView
        } else {
            journeyList
        }
    }

    private var loadingView: some View {
        ProgressView()
            .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var emptyView: some View {
        ContentUnavailableView(
            "No Journeys",
            systemImage: "book.closed",
            description: Text("Subscribe to a journey to get started")
        )
    }

    private var journeyList: some View {
        List(store.journeys) { journey in
            JourneyRow(journey: journey)
                .onTapGesture {
                    store.send(.journeyTapped(journey))
                }
        }
    }

    // MARK: - Toolbar

    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .primaryAction) {
            Button("Refresh") {
                store.send(.refreshTapped)
            }
        }
    }
}
```

### File Naming

| Type | Convention | Example |
|------|------------|---------|
| Feature view | `[Feature]View.swift` | `JourneysView.swift` |
| Detail view | `[Feature]DetailView.swift` | `JourneyDetailView.swift` |
| Row/Cell | `[Thing]Row.swift` | `JourneyRow.swift` |
| Reusable | `[Name]View.swift` | `StreakBadgeView.swift` |

---

## 2. View Composition

### Extract Subviews

```swift
struct PracticeView: View {
    @Bindable var store: StoreOf<PracticeFeature>

    var body: some View {
        VStack(spacing: 24) {
            arabicSection
            translationSection
            counterSection
        }
    }

    private var arabicSection: some View {
        Text(store.dua.arabicText)
            .font(.custom("Amiri", size: 28))
            .multilineTextAlignment(.center)
            .environment(\.layoutDirection, .rightToLeft)
    }

    private var translationSection: some View {
        VStack(spacing: 8) {
            Text(store.dua.transliteration)
                .font(.subheadline)
                .foregroundStyle(.secondary)

            Text(store.dua.translation)
                .font(.body)
        }
    }

    private var counterSection: some View {
        CounterView(
            current: store.currentCount,
            total: store.dua.repetitions,
            onTap: { store.send(.counterTapped) }
        )
    }
}
```

### Reusable Components

```swift
// Views/Components/StreakBadgeView.swift
struct StreakBadgeView: View {
    let streak: Int

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: "flame.fill")
                .foregroundStyle(.orange)
            Text("\(streak)")
                .fontWeight(.semibold)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(.orange.opacity(0.15))
        .clipShape(Capsule())
    }
}
```

---

## 3. State & Bindings

### @Bindable for TCA Stores

```swift
struct SettingsView: View {
    @Bindable var store: StoreOf<SettingsFeature>

    var body: some View {
        Form {
            // Two-way binding from store
            Toggle("Dark Mode", isOn: $store.isDarkMode.sending(\.darkModeToggled))

            TextField("Name", text: $store.displayName.sending(\.nameChanged))
        }
    }
}
```

### Sending Actions from Bindings

```swift
// Method 1: .sending() modifier
$store.value.sending(\.valueChanged)

// Method 2: onChange
.onChange(of: someValue) { _, newValue in
    store.send(.valueChanged(newValue))
}
```

### Local View State

Use `@State` only for purely visual, ephemeral state:

```swift
struct ExpandableRow: View {
    let item: Item
    @State private var isExpanded = false  // OK - purely visual

    var body: some View {
        VStack {
            Button(item.title) { isExpanded.toggle() }
            if isExpanded {
                Text(item.details)
            }
        }
    }
}
```

---

## 4. TCA Store Integration

### Basic Store Usage

```swift
struct MyView: View {
    let store: StoreOf<MyFeature>

    var body: some View {
        VStack {
            // Read state
            Text(store.title)

            // Send actions
            Button("Tap") {
                store.send(.buttonTapped)
            }
        }
    }
}
```

### @Bindable for Bindings

```swift
struct MyView: View {
    @Bindable var store: StoreOf<MyFeature>

    var body: some View {
        // Now you can use $store for bindings
        TextField("Name", text: $store.name.sending(\.nameChanged))
    }
}
```

### Scoping Stores

```swift
struct ParentView: View {
    let store: StoreOf<ParentFeature>

    var body: some View {
        // Scope to child feature
        ChildView(
            store: store.scope(state: \.child, action: \.child)
        )
    }
}
```

### Conditional Rendering with Store

```swift
struct MyView: View {
    let store: StoreOf<MyFeature>

    var body: some View {
        if store.isLoading {
            ProgressView()
        } else {
            ContentView(items: store.items)
        }
    }
}
```

---

## 5. Lists & Collections

### List with ForEach

```swift
struct JourneyListView: View {
    let journeys: [Journey]
    let onTap: (Journey) -> Void

    var body: some View {
        List {
            ForEach(journeys) { journey in
                JourneyRow(journey: journey)
                    .onTapGesture { onTap(journey) }
            }
        }
        .listStyle(.plain)
    }
}
```

### Scoped ForEach with TCA

```swift
struct ItemListView: View {
    let store: StoreOf<ItemListFeature>

    var body: some View {
        List {
            ForEach(
                store.scope(state: \.items, action: \.item)
            ) { itemStore in
                ItemRow(store: itemStore)
            }
        }
    }
}
```

### Lazy Stacks for Performance

```swift
ScrollView {
    LazyVStack(spacing: 16) {
        ForEach(items) { item in
            ItemCard(item: item)
        }
    }
    .padding()
}
```

### Grid Layout

```swift
let columns = [
    GridItem(.flexible()),
    GridItem(.flexible())
]

LazyVGrid(columns: columns, spacing: 16) {
    ForEach(journeys) { journey in
        JourneyCard(journey: journey)
    }
}
```

---

## 6. Navigation

### NavigationStack with TCA

```swift
struct AppView: View {
    @Bindable var store: StoreOf<AppFeature>

    var body: some View {
        NavigationStack(path: $store.scope(state: \.path, action: \.path)) {
            HomeView(store: store.scope(state: \.home, action: \.home))
        } destination: { store in
            switch store.case {
            case .detail(let store):
                DetailView(store: store)
            case .settings(let store):
                SettingsView(store: store)
            }
        }
    }
}
```

### NavigationLink

```swift
NavigationLink(value: Route.detail(item.id)) {
    ItemRow(item: item)
}
```

### Programmatic Navigation

```swift
// In reducer
case .navigateToDetail(let item):
    state.path.append(.detail(DetailFeature.State(item: item)))
    return .none

case .popToRoot:
    state.path.removeAll()
    return .none
```

---

## 7. Sheets & Alerts

### Sheet with TCA

```swift
struct MyView: View {
    @Bindable var store: StoreOf<MyFeature>

    var body: some View {
        List { /* ... */ }
            .sheet(
                item: $store.scope(state: \.detail, action: \.detail)
            ) { detailStore in
                DetailView(store: detailStore)
            }
    }
}
```

### Full Screen Cover

```swift
.fullScreenCover(
    item: $store.scope(state: \.fullScreenFeature, action: \.fullScreenFeature)
) { featureStore in
    FeatureView(store: featureStore)
}
```

### Alerts with TCA

```swift
// State
@Presents var alert: AlertState<Action.Alert>?

// Action
enum Alert {
    case confirmDelete
    case cancel
}

// Reducer
case .deleteConfirmTapped:
    state.alert = AlertState {
        TextState("Delete Item?")
    } actions: {
        ButtonState(role: .destructive, action: .confirmDelete) {
            TextState("Delete")
        }
        ButtonState(role: .cancel, action: .cancel) {
            TextState("Cancel")
        }
    } message: {
        TextState("This action cannot be undone.")
    }
    return .none

// View
.alert($store.scope(state: \.alert, action: \.alert))
```

### Confirmation Dialog

```swift
.confirmationDialog(
    $store.scope(state: \.confirmationDialog, action: \.confirmationDialog)
)
```

---

## 8. Animations

### Implicit Animations

```swift
Text(store.count.description)
    .font(.largeTitle)
    .animation(.spring, value: store.count)
```

### Explicit Animations

```swift
Button("Toggle") {
    withAnimation(.easeInOut(duration: 0.3)) {
        store.send(.toggleTapped)
    }
}
```

### Transitions

```swift
if store.isVisible {
    ContentView()
        .transition(.opacity.combined(with: .scale))
}
```

### Custom Animations

```swift
extension Animation {
    static let rizqSpring = Animation.spring(
        response: 0.4,
        dampingFraction: 0.7
    )

    static let celebrationBounce = Animation.spring(
        response: 0.3,
        dampingFraction: 0.5,
        blendDuration: 0.2
    )
}

// Usage
.animation(.rizqSpring, value: store.isExpanded)
```

### Phase Animator (iOS 17+)

```swift
PhaseAnimator([false, true], trigger: store.didComplete) { phase in
    Image(systemName: "checkmark.circle.fill")
        .scaleEffect(phase ? 1.2 : 1.0)
        .foregroundStyle(phase ? .green : .gray)
}
```

---

## 9. Custom Components

### View Modifier Pattern

```swift
struct CardStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding()
            .background(Color(.systemBackground))
            .cornerRadius(16)
            .shadow(color: .black.opacity(0.1), radius: 8, y: 4)
    }
}

extension View {
    func cardStyle() -> some View {
        modifier(CardStyle())
    }
}

// Usage
VStack { content }
    .cardStyle()
```

### Button Styles

```swift
struct PrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .foregroundStyle(.white)
            .padding(.horizontal, 24)
            .padding(.vertical, 12)
            .background(Color.accentColor)
            .cornerRadius(12)
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

extension ButtonStyle where Self == PrimaryButtonStyle {
    static var primary: PrimaryButtonStyle { PrimaryButtonStyle() }
}

// Usage
Button("Continue") { }
    .buttonStyle(.primary)
```

### Custom Shapes

```swift
struct RoundedCornerShape: Shape {
    var corners: UIRectCorner
    var radius: CGFloat

    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(
            roundedRect: rect,
            byRoundingCorners: corners,
            cornerRadii: CGSize(width: radius, height: radius)
        )
        return Path(path.cgPath)
    }
}
```

---

## 10. Accessibility

### Labels

```swift
Image(systemName: "flame.fill")
    .accessibilityLabel("Current streak")
    .accessibilityValue("\(streak) days")

Button(action: { }) {
    Image(systemName: "plus")
}
.accessibilityLabel("Add new journey")
```

### Hints

```swift
Button("Complete") { }
    .accessibilityHint("Marks this dua as completed for today")
```

### Hide Decorative Elements

```swift
Image("decorative-pattern")
    .accessibilityHidden(true)
```

### Grouping

```swift
HStack {
    Image(systemName: "star.fill")
    Text("Level \(level)")
}
.accessibilityElement(children: .combine)
```

---

## 11. Performance

### Avoid Heavy Computation in Body

```swift
// Bad
var body: some View {
    let filtered = items.filter { $0.isActive }.sorted()  // Every render!
    List(filtered) { item in ... }
}

// Good - compute in reducer or use memoization
var body: some View {
    List(store.filteredItems) { item in ... }
}
```

### Use Lazy Containers

```swift
// For large lists
LazyVStack { }
LazyHStack { }
LazyVGrid { }
LazyHGrid { }

// Not
VStack { }  // Loads all children immediately
```

### Equatable Conformance

```swift
struct ItemRow: View, Equatable {
    let item: Item

    static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.item.id == rhs.item.id &&
        lhs.item.title == rhs.item.title
    }

    var body: some View { /* ... */ }
}
```

### Image Caching with Nuke

```swift
import NukeUI

LazyImage(url: imageURL) { state in
    if let image = state.image {
        image.resizable().aspectRatio(contentMode: .fill)
    } else if state.isLoading {
        ProgressView()
    } else {
        Color.gray.opacity(0.2)
    }
}
.frame(width: 100, height: 100)
.clipShape(Circle())
```

---

## 12. Anti-Patterns

### Don't Put Business Logic in Views

```swift
// Bad
Button("Submit") {
    if isValid && !isLoading {
        Task { await api.submit(data) }
    }
}

// Good - logic in reducer
Button("Submit") {
    store.send(.submitTapped)
}
```

### Don't Use @State for Domain Data

```swift
// Bad - domain data in view
@State private var journeys: [Journey] = []

// Good - domain data in TCA store
let store: StoreOf<JourneysFeature>
// Access via store.journeys
```

### Don't Force Unwrap in Views

```swift
// Bad
Text(store.selectedItem!.title)

// Good
if let item = store.selectedItem {
    Text(item.title)
}
```

### Don't Nest Too Many Views

```swift
// Bad - deeply nested
var body: some View {
    VStack {
        HStack {
            VStack {
                HStack {
                    // 4+ levels deep
                }
            }
        }
    }
}

// Good - extract subviews
var body: some View {
    VStack {
        headerSection
        contentSection
    }
}
```

### Don't Ignore Environment

```swift
// Bad - hardcoded
Text("Hello").foregroundStyle(.black)

// Good - respects dark mode
Text("Hello").foregroundStyle(.primary)
```
