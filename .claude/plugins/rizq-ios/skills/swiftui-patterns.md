---
name: swiftui-patterns
description: "SwiftUI patterns equivalent to React: view composition, state management, environment, property wrappers"
---

# SwiftUI Patterns for React Developers

This skill maps React patterns to SwiftUI equivalents for the RIZQ iOS conversion.

## State Management Mapping

### React Hooks → SwiftUI Property Wrappers

| React | SwiftUI | Use Case |
|-------|---------|----------|
| `useState` | `@State` | Local component state |
| `useState` + parent callback | `@Binding` | Two-way binding from parent |
| `useReducer` | `@Reducer` (TCA) | Complex state logic |
| `useContext` | `@Environment` | App-wide values |
| `useContext` | `@EnvironmentObject` | Shared observable objects |
| `useRef` | `let` constant or `@State` | Persist without re-render |
| `useMemo` | Computed property | Derived values |
| `useCallback` | Regular function | No memoization needed in SwiftUI |
| `useEffect` (mount) | `.onAppear` | Run on view appear |
| `useEffect` (deps) | `.onChange(of:)` | React to value changes |
| `useEffect` (async) | `.task` | Async work on appear |

---

## Component Translation Examples

### useState → @State

**React:**
```typescript
function Counter() {
  const [count, setCount] = useState(0);

  return (
    <button onClick={() => setCount(count + 1)}>
      Count: {count}
    </button>
  );
}
```

**SwiftUI:**
```swift
struct Counter: View {
  @State private var count = 0

  var body: some View {
    Button("Count: \(count)") {
      count += 1
    }
  }
}
```

### Props with Callback → @Binding

**React:**
```typescript
interface ToggleProps {
  isOn: boolean;
  onChange: (value: boolean) => void;
}

function Toggle({ isOn, onChange }: ToggleProps) {
  return (
    <button onClick={() => onChange(!isOn)}>
      {isOn ? 'ON' : 'OFF'}
    </button>
  );
}

// Parent
function Parent() {
  const [enabled, setEnabled] = useState(false);
  return <Toggle isOn={enabled} onChange={setEnabled} />;
}
```

**SwiftUI:**
```swift
struct Toggle: View {
  @Binding var isOn: Bool

  var body: some View {
    Button(isOn ? "ON" : "OFF") {
      isOn.toggle()
    }
  }
}

// Parent
struct Parent: View {
  @State private var enabled = false

  var body: some View {
    Toggle(isOn: $enabled)
  }
}
```

### useContext → @Environment

**React:**
```typescript
const ThemeContext = createContext<Theme>({ mode: 'light' });

function ThemedButton() {
  const theme = useContext(ThemeContext);
  return <button className={theme.mode}>Click</button>;
}
```

**SwiftUI:**
```swift
// Define environment key
struct ThemeKey: EnvironmentKey {
  static let defaultValue: Theme = .light
}

extension EnvironmentValues {
  var theme: Theme {
    get { self[ThemeKey.self] }
    set { self[ThemeKey.self] = newValue }
  }
}

// Use in view
struct ThemedButton: View {
  @Environment(\.theme) var theme

  var body: some View {
    Button("Click") { }
      .foregroundStyle(theme == .dark ? .white : .black)
  }
}

// Provide in parent
ContentView()
  .environment(\.theme, .dark)
```

### useEffect → .onAppear / .task / .onChange

**React (mount):**
```typescript
useEffect(() => {
  fetchData();
}, []);
```

**SwiftUI:**
```swift
.onAppear {
  fetchData()
}

// Or for async:
.task {
  await fetchData()
}
```

**React (dependency):**
```typescript
useEffect(() => {
  console.log('userId changed:', userId);
}, [userId]);
```

**SwiftUI:**
```swift
.onChange(of: userId) { oldValue, newValue in
  print("userId changed: \(newValue)")
}
```

**React (cleanup):**
```typescript
useEffect(() => {
  const timer = setInterval(tick, 1000);
  return () => clearInterval(timer);
}, []);
```

**SwiftUI:**
```swift
.task {
  // Auto-cancelled when view disappears
  while !Task.isCancelled {
    try? await Task.sleep(for: .seconds(1))
    tick()
  }
}
```

---

## Component Composition

### Children → @ViewBuilder

**React:**
```typescript
function Card({ children }: { children: React.ReactNode }) {
  return <div className="card">{children}</div>;
}

<Card>
  <h1>Title</h1>
  <p>Content</p>
</Card>
```

**SwiftUI:**
```swift
struct Card<Content: View>: View {
  @ViewBuilder let content: () -> Content

  var body: some View {
    VStack {
      content()
    }
    .rizqCard()
  }
}

Card {
  Text("Title").font(.title)
  Text("Content")
}
```

### Render Props → ViewBuilder Parameters

**React:**
```typescript
function List<T>({
  items,
  renderItem
}: {
  items: T[];
  renderItem: (item: T) => React.ReactNode
}) {
  return <div>{items.map(renderItem)}</div>;
}

<List items={users} renderItem={(user) => <UserRow user={user} />} />
```

**SwiftUI:**
```swift
struct List<Item: Identifiable, Content: View>: View {
  let items: [Item]
  @ViewBuilder let content: (Item) -> Content

  var body: some View {
    VStack {
      ForEach(items) { item in
        content(item)
      }
    }
  }
}

List(items: users) { user in
  UserRow(user: user)
}
```

---

## Conditional Rendering

### Ternary / && Operator

**React:**
```typescript
{isLoading ? <Spinner /> : <Content />}
{error && <ErrorMessage error={error} />}
```

**SwiftUI:**
```swift
if isLoading {
  ProgressView()
} else {
  ContentView()
}

if let error {
  ErrorMessage(error: error)
}

// Or with Group for inline:
Group {
  if isLoading {
    ProgressView()
  } else {
    ContentView()
  }
}
```

### Optional Chaining

**React:**
```typescript
{user?.name && <Text>{user.name}</Text>}
```

**SwiftUI:**
```swift
if let name = user?.name {
  Text(name)
}
```

---

## List Rendering

### map() → ForEach

**React:**
```typescript
{items.map((item) => (
  <ItemRow key={item.id} item={item} />
))}
```

**SwiftUI:**
```swift
ForEach(items) { item in
  ItemRow(item: item)
}

// If not Identifiable:
ForEach(items, id: \.id) { item in
  ItemRow(item: item)
}

// With index:
ForEach(Array(items.enumerated()), id: \.element.id) { index, item in
  ItemRow(item: item, index: index)
}
```

---

## Event Handling

### onClick → Button / onTapGesture

**React:**
```typescript
<div onClick={handleClick}>Click me</div>
<button onClick={() => setCount(c => c + 1)}>+</button>
```

**SwiftUI:**
```swift
// For semantic buttons:
Button("Click me") {
  handleClick()
}

// For any view:
Text("Click me")
  .onTapGesture {
    handleClick()
  }

// With gesture options:
Text("Click me")
  .onTapGesture(count: 2) { // double tap
    handleDoubleTap()
  }
```

### onChange → onChange modifier or Binding

**React:**
```typescript
<input value={text} onChange={(e) => setText(e.target.value)} />
```

**SwiftUI:**
```swift
TextField("Placeholder", text: $text)

// With side effect:
TextField("Placeholder", text: $text)
  .onChange(of: text) { _, newValue in
    validateInput(newValue)
  }
```

---

## Styling Patterns

### className → View Modifiers

**React:**
```typescript
<div className="p-4 bg-card rounded-islamic shadow-soft">
  <h1 className="text-lg font-semibold text-foreground">Title</h1>
</div>
```

**SwiftUI:**
```swift
VStack {
  Text("Title")
    .font(.rizqDisplay(.headline))
    .foregroundStyle(.rizqForeground)
}
.padding(RIZQSpacing.md)
.background(.rizqCard)
.clipShape(RoundedRectangle(cornerRadius: RIZQRadius.islamic))
.rizqShadowSoft()
```

### Inline Styles → Modifiers

**React:**
```typescript
<div style={{ opacity: isVisible ? 1 : 0, transform: `translateY(${offset}px)` }}>
```

**SwiftUI:**
```swift
SomeView()
  .opacity(isVisible ? 1 : 0)
  .offset(y: offset)
```

### Conditional Classes → Conditional Modifiers

**React:**
```typescript
<div className={cn("base-class", isActive && "active-class")}>
```

**SwiftUI:**
```swift
SomeView()
  .foregroundStyle(isActive ? .rizqPrimary : .rizqMutedForeground)
  .fontWeight(isActive ? .bold : .regular)
```

---

## Navigation Patterns

### React Router → NavigationStack

**React:**
```typescript
<Routes>
  <Route path="/" element={<Home />} />
  <Route path="/library" element={<Library />} />
  <Route path="/practice/:duaId" element={<Practice />} />
</Routes>

// Navigate
navigate('/practice/123');
```

**SwiftUI with TCA:**
```swift
// In AppFeature:
var path = StackState<Path.State>()

// Push:
state.path.append(.practice(PracticeFeature.State(dua: dua)))

// Pop:
state.path.removeLast()

// View:
NavigationStack(path: $store.scope(state: \.path, action: \.path)) {
  HomeView()
} destination: { store in
  switch store.case {
  case .practice(let store):
    PracticeView(store: store)
  case .library(let store):
    LibraryView(store: store)
  }
}
```

### useParams → State from Parent

**React:**
```typescript
const { duaId } = useParams();
```

**SwiftUI:**
```swift
// Parameter passed in State from parent
struct PracticeFeature {
  struct State {
    var dua: Dua  // Passed when pushed
  }
}
```

---

## Form Patterns

### Controlled Inputs

**React:**
```typescript
const [email, setEmail] = useState('');
const [password, setPassword] = useState('');

<input type="email" value={email} onChange={e => setEmail(e.target.value)} />
<input type="password" value={password} onChange={e => setPassword(e.target.value)} />
```

**SwiftUI:**
```swift
@State private var email = ""
@State private var password = ""

TextField("Email", text: $email)
  .textContentType(.emailAddress)
  .keyboardType(.emailAddress)

SecureField("Password", text: $password)
  .textContentType(.password)
```

---

## Async Patterns

### useEffect with async

**React:**
```typescript
useEffect(() => {
  async function load() {
    setLoading(true);
    try {
      const data = await fetchData();
      setData(data);
    } catch (e) {
      setError(e);
    } finally {
      setLoading(false);
    }
  }
  load();
}, []);
```

**SwiftUI with TCA:**
```swift
// In Reducer:
case .onAppear:
  state.isLoading = true
  return .run { send in
    await send(.dataResponse(Result {
      try await apiClient.fetchData()
    }))
  }

case .dataResponse(.success(let data)):
  state.isLoading = false
  state.data = data
  return .none

case .dataResponse(.failure(let error)):
  state.isLoading = false
  state.errorMessage = error.localizedDescription
  return .none
```

---

## Common Gotchas

### 1. Views are Structs (Value Types)
Unlike React components, SwiftUI views are structs. They're recreated frequently, so keep them lightweight.

### 2. @State is Private
`@State` should always be `private` - it's owned by the view.

### 3. Binding Syntax
Use `$` prefix to create a binding: `$text`, `$store.scope(...)`

### 4. Identity for ForEach
Items must be `Identifiable` or provide `id` parameter.

### 5. MainActor for UI Updates
UI updates must be on main thread. TCA handles this, but for manual async:
```swift
await MainActor.run {
  // UI update
}
```

### 6. No Fragments
SwiftUI requires a single root view. Use `Group` or `VStack` to group multiple views.
