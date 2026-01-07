---
name: animation-mapping
description: "Framer Motion to SwiftUI animation translation guide with comprehensive code examples"
---

# Animation Mapping: Framer Motion → SwiftUI

This skill provides a comprehensive reference for translating Framer Motion animations from the RIZQ React app to native SwiftUI animations.

---

## Spring Physics Conversion

### Framer Motion Spring Config

```typescript
// Framer Motion
spring({ stiffness: 400, damping: 30, mass: 1 })

// Framer Motion presets
transition: { type: "spring", stiffness: 300, damping: 24 }
```

### SwiftUI Spring Equivalents

```swift
// Modern SwiftUI (iOS 17+)
.spring(duration: 0.5, bounce: 0.3)

// Classic spring parameters
.spring(response: 0.3, dampingFraction: 0.6, blendDuration: 0)

// Interruptible spring (best for gestures)
.interactiveSpring(response: 0.3, dampingFraction: 0.6, blendDuration: 0.25)
```

### Conversion Formula

| Framer Motion | SwiftUI | Notes |
|---------------|---------|-------|
| `stiffness: 400, damping: 30` | `.spring(response: 0.3, dampingFraction: 0.6)` | Standard UI feel |
| `stiffness: 300, damping: 24` | `.spring(response: 0.35, dampingFraction: 0.65)` | Slightly bouncy |
| `stiffness: 500, damping: 35` | `.spring(response: 0.25, dampingFraction: 0.7)` | Snappy |
| `stiffness: 200, damping: 20` | `.spring(response: 0.5, dampingFraction: 0.5)` | Bouncy celebration |

### RIZQ Standard Springs

```swift
extension Animation {
  /// Standard UI spring (buttons, cards)
  static let rizqStandard = Animation.spring(response: 0.3, dampingFraction: 0.7)

  /// Bouncy spring (celebrations, rewards)
  static let rizqBouncy = Animation.spring(response: 0.5, dampingFraction: 0.5)

  /// Quick snap (toggles, small elements)
  static let rizqSnap = Animation.spring(response: 0.2, dampingFraction: 0.8)

  /// Smooth ease (page transitions)
  static let rizqSmooth = Animation.easeInOut(duration: 0.3)
}
```

---

## Staggered List Animations

### Framer Motion Pattern

```typescript
// Container
const containerVariants = {
  hidden: { opacity: 0 },
  visible: {
    opacity: 1,
    transition: {
      staggerChildren: 0.08,
      delayChildren: 0.1,
    },
  },
};

// Item
const itemVariants = {
  hidden: { opacity: 0, y: 20 },
  visible: {
    opacity: 1,
    y: 0,
    transition: { duration: 0.4 },
  },
};
```

### SwiftUI Equivalent

```swift
// MARK: - Staggered List View
struct StaggeredListView<Item: Identifiable, Content: View>: View {
  let items: [Item]
  let staggerDelay: Double
  let content: (Item) -> Content

  @State private var appeared = false

  var body: some View {
    LazyVStack(spacing: 12) {
      ForEach(Array(items.enumerated()), id: \.element.id) { index, item in
        content(item)
          .opacity(appeared ? 1 : 0)
          .offset(y: appeared ? 0 : 20)
          .animation(
            .spring(response: 0.4, dampingFraction: 0.7)
            .delay(Double(index) * staggerDelay),
            value: appeared
          )
      }
    }
    .onAppear {
      withAnimation { appeared = true }
    }
  }
}

// Usage
StaggeredListView(items: duas, staggerDelay: 0.08) { dua in
  DuaCard(dua: dua)
}
```

### ViewModifier Approach

```swift
struct StaggeredAppearModifier: ViewModifier {
  let index: Int
  let baseDelay: Double
  @State private var appeared = false

  func body(content: Content) -> some View {
    content
      .opacity(appeared ? 1 : 0)
      .offset(y: appeared ? 0 : 20)
      .scaleEffect(appeared ? 1 : 0.95)
      .onAppear {
        withAnimation(
          .spring(response: 0.4, dampingFraction: 0.7)
          .delay(baseDelay + Double(index) * 0.08)
        ) {
          appeared = true
        }
      }
  }
}

extension View {
  func staggeredAppear(index: Int, baseDelay: Double = 0.1) -> some View {
    modifier(StaggeredAppearModifier(index: index, baseDelay: baseDelay))
  }
}

// Usage
ForEach(Array(items.enumerated()), id: \.element.id) { index, item in
  ItemRow(item: item)
    .staggeredAppear(index: index)
}
```

---

## Gesture Animations

### Framer Motion Press/Tap

```typescript
<motion.div
  whileTap={{ scale: 0.98 }}
  whileHover={{ scale: 1.02 }}
  transition={{ duration: 0.1 }}
>
```

### SwiftUI Button Style

```swift
struct ScaleButtonStyle: ButtonStyle {
  func makeBody(configuration: Configuration) -> some View {
    configuration.label
      .scaleEffect(configuration.isPressed ? 0.98 : 1)
      .animation(.spring(response: 0.2, dampingFraction: 0.7), value: configuration.isPressed)
  }
}

// Card button with scale and shadow
struct CardPressStyle: ButtonStyle {
  func makeBody(configuration: Configuration) -> some View {
    configuration.label
      .scaleEffect(configuration.isPressed ? 0.98 : 1)
      .opacity(configuration.isPressed ? 0.9 : 1)
      .shadow(
        color: .black.opacity(configuration.isPressed ? 0.1 : 0.15),
        radius: configuration.isPressed ? 4 : 8,
        y: configuration.isPressed ? 2 : 4
      )
      .animation(.spring(response: 0.2), value: configuration.isPressed)
  }
}

// Usage
Button(action: { }) {
  Text("Tap Me")
}
.buttonStyle(CardPressStyle())
```

### Drag Gesture

```swift
struct DraggableCard: View {
  @State private var offset = CGSize.zero
  @State private var isDragging = false

  var body: some View {
    RoundedRectangle(cornerRadius: 20)
      .fill(.rizqCard)
      .frame(width: 200, height: 150)
      .offset(offset)
      .scaleEffect(isDragging ? 1.05 : 1)
      .shadow(radius: isDragging ? 20 : 8)
      .gesture(
        DragGesture()
          .onChanged { gesture in
            offset = gesture.translation
            isDragging = true
          }
          .onEnded { _ in
            withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
              offset = .zero
              isDragging = false
            }
          }
      )
      .animation(.spring(response: 0.2), value: isDragging)
  }
}
```

---

## Page/Screen Transitions

### Framer Motion AnimatePresence

```typescript
<AnimatePresence mode="wait">
  <motion.div
    key={page}
    initial={{ opacity: 0, x: 20 }}
    animate={{ opacity: 1, x: 0 }}
    exit={{ opacity: 0, x: -20 }}
    transition={{ duration: 0.3 }}
  >
    {children}
  </motion.div>
</AnimatePresence>
```

### SwiftUI Transition

```swift
struct ContentView: View {
  @State private var showDetail = false

  var body: some View {
    ZStack {
      if showDetail {
        DetailView()
          .transition(.asymmetric(
            insertion: .move(edge: .trailing).combined(with: .opacity),
            removal: .move(edge: .leading).combined(with: .opacity)
          ))
      } else {
        ListView()
          .transition(.asymmetric(
            insertion: .move(edge: .leading).combined(with: .opacity),
            removal: .move(edge: .trailing).combined(with: .opacity)
          ))
      }
    }
    .animation(.spring(response: 0.3, dampingFraction: 0.8), value: showDetail)
  }
}

// Custom Transition
extension AnyTransition {
  static var rizqSlide: AnyTransition {
    .asymmetric(
      insertion: .move(edge: .trailing)
        .combined(with: .opacity)
        .combined(with: .scale(scale: 0.95)),
      removal: .move(edge: .leading)
        .combined(with: .opacity)
        .combined(with: .scale(scale: 0.95))
    )
  }
}
```

---

## Counter/Number Animations

### Framer Motion useSpring

```typescript
const count = useSpring(0, { stiffness: 100, damping: 30 })
useEffect(() => { count.set(target) }, [target])
```

### SwiftUI Animated Counter

```swift
struct AnimatedCounter: View {
  let value: Int
  @State private var displayValue: Int = 0

  var body: some View {
    Text("\(displayValue)")
      .font(.rizqMono(.title))
      .fontWeight(.bold)
      .contentTransition(.numericText())
      .onChange(of: value) { oldValue, newValue in
        withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
          displayValue = newValue
        }
      }
      .onAppear {
        displayValue = value
      }
  }
}

// With rolling digit effect (iOS 17+)
struct RollingCounter: View {
  let value: Int

  var body: some View {
    Text("\(value)")
      .font(.rizqMono(.largeTitle))
      .contentTransition(.numericText(countsDown: false))
      .transaction { transaction in
        transaction.animation = .spring(duration: 0.5, bounce: 0.3)
      }
  }
}
```

---

## Celebration/Reward Animations

### Confetti Particles

```swift
struct ConfettiView: View {
  @State private var particles: [ConfettiParticle] = []
  let colors: [Color] = [.rizqPrimary, .goldBright, .tealMuted, .sandLight]

  var body: some View {
    TimelineView(.animation) { timeline in
      Canvas { context, size in
        let now = timeline.date.timeIntervalSinceReferenceDate

        for particle in particles {
          let age = now - particle.createdAt
          guard age < particle.lifetime else { continue }

          let progress = age / particle.lifetime
          let y = particle.startY + particle.velocityY * age + 0.5 * 500 * age * age
          let x = particle.startX + sin(age * particle.wobbleFrequency) * particle.wobbleAmplitude
          let opacity = 1 - progress

          context.opacity = opacity
          context.fill(
            Path(ellipseIn: CGRect(x: x, y: y, width: particle.size, height: particle.size)),
            with: .color(particle.color)
          )
        }
      }
    }
  }

  func burst(at point: CGPoint, count: Int = 50) {
    let newParticles = (0..<count).map { _ in
      ConfettiParticle(
        startX: point.x,
        startY: point.y,
        velocityY: Double.random(in: -300...(-100)),
        wobbleFrequency: Double.random(in: 5...15),
        wobbleAmplitude: Double.random(in: 20...60),
        lifetime: Double.random(in: 1...2),
        size: Double.random(in: 6...12),
        color: colors.randomElement()!,
        createdAt: Date.timeIntervalSinceReferenceDate
      )
    }
    particles.append(contentsOf: newParticles)
  }
}

struct ConfettiParticle: Identifiable {
  let id = UUID()
  let startX: Double
  let startY: Double
  let velocityY: Double
  let wobbleFrequency: Double
  let wobbleAmplitude: Double
  let lifetime: Double
  let size: Double
  let color: Color
  let createdAt: TimeInterval
}
```

### Scale Pop Animation

```swift
struct PopAnimationModifier: ViewModifier {
  @State private var scale: CGFloat = 0

  func body(content: Content) -> some View {
    content
      .scaleEffect(scale)
      .onAppear {
        withAnimation(.spring(response: 0.4, dampingFraction: 0.5)) {
          scale = 1
        }
      }
  }
}

extension View {
  func popIn() -> some View {
    modifier(PopAnimationModifier())
  }
}
```

### XP Earned Badge

```swift
struct XPEarnedBadge: View {
  let amount: Int
  @State private var appeared = false
  @State private var floatUp = false

  var body: some View {
    Text("+\(amount) XP")
      .font(.rizqMono(.headline))
      .fontWeight(.bold)
      .foregroundStyle(.white)
      .padding(.horizontal, 12)
      .padding(.vertical, 6)
      .background(
        Capsule()
          .fill(LinearGradient(
            colors: [.rizqPrimary, .sandDeep],
            startPoint: .leading,
            endPoint: .trailing
          ))
      )
      .scaleEffect(appeared ? 1 : 0)
      .offset(y: floatUp ? -30 : 0)
      .opacity(floatUp ? 0 : 1)
      .onAppear {
        withAnimation(.spring(response: 0.4, dampingFraction: 0.5)) {
          appeared = true
        }

        withAnimation(.easeOut(duration: 1.5).delay(0.8)) {
          floatUp = true
        }
      }
  }
}
```

---

## Shimmer/Loading Animations

### Framer Motion Shimmer

```typescript
<motion.div
  animate={{ backgroundPosition: ["0% 50%", "100% 50%", "0% 50%"] }}
  transition={{ duration: 2, repeat: Infinity }}
  style={{
    background: "linear-gradient(90deg, #f0f0f0 25%, #e0e0e0 50%, #f0f0f0 75%)",
    backgroundSize: "200% 100%"
  }}
/>
```

### SwiftUI Shimmer

```swift
struct ShimmerModifier: ViewModifier {
  @State private var phase: CGFloat = 0

  func body(content: Content) -> some View {
    content
      .overlay(
        GeometryReader { geometry in
          LinearGradient(
            gradient: Gradient(colors: [
              .clear,
              .white.opacity(0.5),
              .clear
            ]),
            startPoint: .leading,
            endPoint: .trailing
          )
          .frame(width: geometry.size.width * 2)
          .offset(x: -geometry.size.width + phase * geometry.size.width * 2)
        }
        .mask(content)
      )
      .onAppear {
        withAnimation(.linear(duration: 1.5).repeatForever(autoreverses: false)) {
          phase = 1
        }
      }
  }
}

extension View {
  func shimmer() -> some View {
    modifier(ShimmerModifier())
  }
}

// Usage
RoundedRectangle(cornerRadius: 12)
  .fill(.rizqMuted)
  .shimmer()
```

---

## Animation Reference Table

| Framer Motion | SwiftUI | Use Case |
|---------------|---------|----------|
| `initial={{ opacity: 0 }}` | `.opacity(0)` + `.onAppear` | Entry animation |
| `animate={{ opacity: 1 }}` | `withAnimation { opacity = 1 }` | Triggered animation |
| `exit={{ opacity: 0 }}` | `.transition(.opacity)` | Exit animation |
| `whileTap={{ scale: 0.95 }}` | `ButtonStyle` + `isPressed` | Press feedback |
| `whileHover={{ scale: 1.02 }}` | `.hoverEffect()` (visionOS) | Hover state |
| `staggerChildren: 0.08` | `.delay(index * 0.08)` | List stagger |
| `layoutId="shared"` | `.matchedGeometryEffect(id:in:)` | Shared element |
| `useSpring(0)` | `withAnimation(.spring)` | Continuous animation |
| `AnimatePresence` | `if/switch` + `.transition()` | Conditional views |
| `drag` | `DragGesture()` | Draggable elements |
