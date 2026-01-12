---
name: ios-animation
description: "Add SwiftUI animations matching the RIZQ design system - staggered entry, spring physics, celebration effects, progress animations"
---

# iOS Animation Skill

This skill helps add beautiful SwiftUI animations that match the RIZQ design system and align with the React/Framer Motion web app.

## Animation Philosophy

RIZQ uses warm, elegant animations that feel luxurious but not flashy:
- **Entry animations**: Staggered fade + slide for lists and sections
- **Interactions**: Spring physics for taps and hovers
- **Feedback**: Subtle scale and opacity changes
- **Celebrations**: Particles and sparkles for achievements

## Core Animation Patterns

### 1. Staggered Entry Animation (Container → Children)

**React Equivalent:**
```typescript
const containerVariants = {
  hidden: { opacity: 0 },
  visible: {
    opacity: 1,
    transition: { staggerChildren: 0.08, delayChildren: 0.1 },
  },
};

const itemVariants = {
  hidden: { opacity: 0, y: 20 },
  visible: {
    opacity: 1, y: 0,
    transition: { duration: 0.4, ease: [0.25, 0.46, 0.45, 0.94] },
  },
};
```

**SwiftUI Implementation:**
```swift
// StaggeredAnimationModifier.swift
struct StaggeredAnimationModifier: ViewModifier {
  let index: Int
  @State private var isVisible: Bool = false

  private var delay: Double {
    0.1 + Double(index) * 0.08  // delayChildren + (index * staggerChildren)
  }

  func body(content: Content) -> some View {
    content
      .opacity(isVisible ? 1 : 0)
      .offset(y: isVisible ? 0 : 20)
      .onAppear {
        withAnimation(
          .spring(response: 0.4, dampingFraction: 0.75)
          .delay(delay)
        ) {
          isVisible = true
        }
      }
  }
}

// Usage
VStack(spacing: RIZQSpacing.lg) {
  headerSection
    .modifier(StaggeredAnimationModifier(index: 0))

  statsCard
    .modifier(StaggeredAnimationModifier(index: 1))

  weekCalendar
    .modifier(StaggeredAnimationModifier(index: 2))
}
```

### 2. Button Press Animation

**React Equivalent:**
```typescript
<motion.button whileHover={{ y: -2 }} whileTap={{ scale: 0.98 }}>
```

**SwiftUI Implementation:**
```swift
struct ScaleButtonStyle: ButtonStyle {
  func makeBody(configuration: Configuration) -> some View {
    configuration.label
      .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
      .animation(.spring(response: 0.3, dampingFraction: 0.7), value: configuration.isPressed)
  }
}

// With hover effect (macOS/iPadOS with pointer)
struct HoverScaleButtonStyle: ButtonStyle {
  @State private var isHovered = false

  func makeBody(configuration: Configuration) -> some View {
    configuration.label
      .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
      .offset(y: isHovered ? -2 : 0)
      .animation(.spring(response: 0.3, dampingFraction: 0.7), value: configuration.isPressed)
      .animation(.spring(response: 0.2, dampingFraction: 0.8), value: isHovered)
      .onHover { hovering in
        isHovered = hovering
      }
  }
}

// Usage
Button(action: {}) {
  Text("Browse Journeys")
}
.buttonStyle(ScaleButtonStyle())
```

### 3. Progress Bar Animation

**React Equivalent:**
```typescript
<motion.div
  className="h-full rounded-full gradient-primary"
  initial={{ width: 0 }}
  animate={{ width: `${percentage}%` }}
  transition={{ duration: 0.8, delay: 0.3 }}
/>
```

**SwiftUI Implementation:**
```swift
struct AnimatedProgressBar: View {
  let percentage: Double
  @State private var animatedWidth: CGFloat = 0

  var body: some View {
    GeometryReader { geometry in
      ZStack(alignment: .leading) {
        // Track
        Capsule()
          .fill(Color.rizqMuted.opacity(0.3))
          .frame(height: 8)

        // Fill
        Capsule()
          .fill(Color.rizqPrimary)
          .frame(width: geometry.size.width * animatedWidth, height: 8)
      }
    }
    .frame(height: 8)
    .onAppear {
      withAnimation(.easeOut(duration: 0.8).delay(0.3)) {
        animatedWidth = percentage
      }
    }
    .onChange(of: percentage) { _, newValue in
      withAnimation(.easeOut(duration: 0.5)) {
        animatedWidth = newValue
      }
    }
  }
}
```

### 4. Circular Progress Animation

```swift
struct CircularXpProgress: View {
  let level: Int
  let percentage: Double
  let size: CGFloat
  let strokeWidth: CGFloat

  @State private var animatedProgress: Double = 0

  var body: some View {
    ZStack {
      // Background track
      Circle()
        .stroke(Color.rizqMuted.opacity(0.3), lineWidth: strokeWidth)

      // Progress arc
      Circle()
        .trim(from: 0, to: animatedProgress)
        .stroke(
          Color.rizqPrimary,
          style: StrokeStyle(lineWidth: strokeWidth, lineCap: .round)
        )
        .rotationEffect(.degrees(-90))

      // Center content
      VStack(spacing: 2) {
        Image(systemName: "star.fill")
          .foregroundStyle(Color.levelBadge)
        Text("\(level)")
          .font(.rizqMonoMedium(.headline))
      }
    }
    .frame(width: size, height: size)
    .onAppear {
      withAnimation(.easeOut(duration: 1.0)) {
        animatedProgress = percentage
      }
    }
  }
}
```

### 5. Number Counter Animation

**React Equivalent:**
```typescript
<AnimatedNumber value={xpEarned} />
```

**SwiftUI Implementation:**
```swift
struct AnimatedNumber: View {
  let value: Int
  @State private var displayValue: Int = 0

  var body: some View {
    Text("\(displayValue)")
      .contentTransition(.numericText(countsDown: displayValue > value))
      .onAppear { displayValue = value }
      .onChange(of: value) { _, newValue in
        withAnimation(.spring(response: 0.4, dampingFraction: 0.6)) {
          displayValue = newValue
        }
      }
  }
}
```

### 6. Pulsing Animation (e.g., "Today" indicator)

```swift
struct PulsingModifier: ViewModifier {
  @State private var isPulsing = false

  func body(content: Content) -> some View {
    content
      .scaleEffect(isPulsing ? 1.15 : 1.0)
      .opacity(isPulsing ? 0.5 : 1.0)
      .onAppear {
        withAnimation(
          Animation.easeInOut(duration: 1.0)
            .repeatForever(autoreverses: true)
        ) {
          isPulsing = true
        }
      }
  }
}

// Usage - pulsing border for "today" in calendar
Circle()
  .stroke(Color.rizqPrimary, lineWidth: 2)
  .modifier(PulsingModifier())
```

### 7. Pop-in Badge Animation

**React Equivalent:**
```typescript
<motion.div
  initial={{ scale: 0.8, opacity: 0 }}
  animate={{ scale: 1, opacity: 1 }}
  transition={{ delay: 0.5 }}
>
```

**SwiftUI Implementation:**
```swift
struct PopInModifier: ViewModifier {
  let delay: Double
  @State private var isVisible = false

  func body(content: Content) -> some View {
    content
      .scaleEffect(isVisible ? 1 : 0.8)
      .opacity(isVisible ? 1 : 0)
      .onAppear {
        withAnimation(.spring(response: 0.5, dampingFraction: 0.6).delay(delay)) {
          isVisible = true
        }
      }
  }
}

// Usage - XP earned badge
HStack {
  Image(systemName: "sparkles")
  Text("+\(xpEarned)")
  Text("XP")
}
.modifier(PopInModifier(delay: 0.5))
```

### 8. Shimmer Effect (Progress bar highlight)

```swift
struct ShimmerModifier: ViewModifier {
  @State private var offset: CGFloat = -1

  func body(content: Content) -> some View {
    content
      .overlay(
        GeometryReader { geometry in
          LinearGradient(
            colors: [.clear, .white.opacity(0.3), .clear],
            startPoint: .leading,
            endPoint: .trailing
          )
          .offset(x: offset * geometry.size.width)
          .onAppear {
            withAnimation(
              Animation.linear(duration: 2.0)
                .repeatForever(autoreverses: false)
                .delay(1.0)
            ) {
              offset = 2
            }
          }
        }
        .mask(content)
      )
  }
}
```

### 9. Streak Flame Animation

```swift
struct StreakBadge: View {
  let streak: Int
  let isAnimating: Bool

  var body: some View {
    ZStack {
      Circle()
        .fill(Color.streakGlow.opacity(0.15))
        .scaleEffect(isAnimating ? 1.3 : 1.0)

      Image(systemName: "flame.fill")
        .foregroundStyle(streak > 0 ? Color.streakGlow : Color.rizqMuted)
        .rotationEffect(.degrees(isAnimating ? -10 : 0))
        .scaleEffect(isAnimating ? 1.2 : 1.0)
    }
    .animation(
      isAnimating
        ? Animation.easeInOut(duration: 0.3).repeatCount(3, autoreverses: true)
        : .default,
      value: isAnimating
    )
  }
}
```

### 10. Celebration Particles

```swift
struct CelebrationParticles: View {
  @State private var particles: [ParticleData] = []

  var body: some View {
    ZStack {
      ForEach(particles) { particle in
        Circle()
          .fill(particle.color)
          .frame(width: particle.size, height: particle.size)
          .position(particle.position)
          .opacity(particle.opacity)
      }
    }
    .onAppear { generateParticles() }
  }

  private func generateParticles() {
    let colors: [Color] = [.goldSoft, .goldBright, .rizqPrimary, .streakGlow]

    for i in 0..<20 {
      let particle = ParticleData(
        id: i,
        color: colors.randomElement()!,
        size: CGFloat.random(in: 4...12),
        position: CGPoint(x: CGFloat.random(in: 0...300), y: 300),
        opacity: 1
      )
      particles.append(particle)

      // Animate upward and fade
      withAnimation(.easeOut(duration: Double.random(in: 1...2)).delay(Double(i) * 0.05)) {
        particles[i].position.y = CGFloat.random(in: -100...100)
        particles[i].opacity = 0
      }
    }
  }
}
```

## Spring Physics Reference

| Use Case | Response | Damping | Notes |
|----------|----------|---------|-------|
| Button tap | 0.3 | 0.7 | Quick, snappy |
| Entry animation | 0.4 | 0.75 | Smooth entrance |
| Pop-in badge | 0.5 | 0.6 | Bouncy emphasis |
| Counter number | 0.4 | 0.6 | Playful increment |
| Hover effect | 0.2 | 0.8 | Subtle, immediate |

## Timing Reference

| Animation | Duration | Delay | Notes |
|-----------|----------|-------|-------|
| Progress bar | 0.8s | 0.3s | Initial fill |
| Stagger start | - | 0.1s | Before first item |
| Stagger between | - | 0.08s | Between items |
| Shimmer cycle | 2.0s | 1.0s | After progress fills |
| Celebration | 1-2s | 0.05s incremental | Per particle |

## Existing Animation Components

Located in `/RIZQ/Views/Components/`:

| Component | File | Purpose |
|-----------|------|---------|
| `CelebrationParticles` | `Animations/CelebrationParticles.swift` | Full-screen celebration |
| `AnimatedCheckmark` | `Animations/AnimatedCheckmark.swift` | Completion checkmark |
| `AnimatedCounter` | `Animations/AnimatedCounter.swift` | Number counting |
| `RippleEffect` | `Animations/RippleEffect.swift` | Tap ripple |
| `Sparkles` | `Animations/Sparkles.swift` | Decorative sparkles |
| `StreakBadge` | `GamificationViews/GamificationViews.swift` | Animated streak |
| `CircularXpProgress` | `GamificationViews/GamificationViews.swift` | XP ring |
| `XpProgressBar` | `GamificationViews/GamificationViews.swift` | Linear XP bar |

## Implementation Checklist

When adding animations:
- [ ] Use RIZQKit design tokens (colors, spacing, radius)
- [ ] Match React timing (stagger 0.08s, delay 0.1s)
- [ ] Use spring physics for interactions
- [ ] Add `.animation()` modifier with explicit `value:` parameter
- [ ] Test on device (animations feel different on simulator)
- [ ] Consider reduced motion accessibility (`@Environment(\.accessibilityReduceMotion)`)
