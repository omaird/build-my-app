# Phase 5: UI/UX Alignment

> **Objective**: Ensure iOS app pages match the React web application's visual design and user experience

## Overview

With all data flowing correctly, this phase focuses on visual and interaction parity with the React app. The goal is a consistent experience across platforms while respecting iOS design conventions.

---

## Design System Reference

### Colors (from React's tailwind.config.ts)

```swift
// Colors.swift additions
extension Color {
    // Primary palette
    static let sand = Color(red: 212/255, green: 165/255, blue: 116/255)  // #D4A574
    static let sandLight = Color(red: 230/255, green: 199/255, blue: 156/255)  // #E6C79C
    static let sandDeep = Color(red: 166/255, green: 124/255, blue: 82/255)  // #A67C52

    static let mocha = Color(red: 107/255, green: 68/255, blue: 35/255)  // #6B4423
    static let mochaDeep = Color(red: 44/255, green: 36/255, blue: 22/255)  // #2C2416

    static let cream = Color(red: 245/255, green: 239/255, blue: 231/255)  // #F5EFE7
    static let creamWarm = Color(red: 255/255, green: 252/255, blue: 247/255)  // #FFFCF7

    static let goldSoft = Color(red: 230/255, green: 199/255, blue: 156/255)  // #E6C79C
    static let goldBright = Color(red: 255/255, green: 235/255, blue: 179/255)  // #FFEBB3

    static let tealMuted = Color(red: 91/255, green: 138/255, blue: 138/255)  // #5B8A8A
    static let tealSuccess = Color(red: 107/255, green: 155/255, blue: 124/255)  // #6B9B7C

    // Semantic colors
    static let card = Color.creamWarm
    static let background = Color.cream
    static let primaryText = Color.mochaDeep
    static let secondaryText = Color.mocha.opacity(0.7)
}
```

### Typography

```swift
// Typography.swift
extension Font {
    // Headings - Playfair Display style
    static let displayLarge = Font.system(size: 32, weight: .bold, design: .serif)
    static let displayMedium = Font.system(size: 24, weight: .bold, design: .serif)
    static let displaySmall = Font.system(size: 20, weight: .semibold, design: .serif)

    // Body - Crimson Pro style
    static let bodyLarge = Font.system(size: 18, weight: .regular)
    static let bodyMedium = Font.system(size: 16, weight: .regular)
    static let bodySmall = Font.system(size: 14, weight: .regular)

    // Arabic - Amiri style
    static let arabicLarge = Font.custom("Amiri", size: 28)
    static let arabicMedium = Font.custom("Amiri", size: 24)
    static let arabicSmall = Font.custom("Amiri", size: 20)

    // Monospace for numbers
    static let counter = Font.system(size: 48, weight: .bold, design: .monospaced)
}
```

### Spacing & Radii

```swift
// Spacing.swift
enum Spacing {
    static let xs: CGFloat = 4
    static let sm: CGFloat = 8
    static let md: CGFloat = 16
    static let lg: CGFloat = 24
    static let xl: CGFloat = 32
    static let xxl: CGFloat = 48
}

enum CornerRadius {
    static let small: CGFloat = 8
    static let medium: CGFloat = 12
    static let large: CGFloat = 16
    static let islamic: CGFloat = 20  // Cards
    static let button: CGFloat = 16
}
```

---

## Tasks

### Task 5.1: Home Page Alignment

**File**: `RIZQ/Features/Home/HomeView.swift`

**React Reference**: `src/pages/HomePage.tsx`

**Key Elements to Match**:

1. **Greeting Header**
   - Time-based greeting (Good morning/afternoon/evening)
   - User's display name
   - Streak badge with flame icon and glow

2. **Stats Card**
   - Circular XP progress ring with level
   - Linear XP bar with shimmer animation
   - Level and total XP display

3. **Week Calendar**
   - 7-day horizontal strip
   - Active days highlighted with dot
   - Today emphasized

4. **Habits Summary Card**
   - Progress fraction (3/5 complete)
   - Visual progress bar
   - Quick action to continue

```swift
// HomeView.swift - Updated structure
struct HomeView: View {
    @Bindable var store: StoreOf<HomeFeature>

    var body: some View {
        ScrollView {
            VStack(spacing: Spacing.lg) {
                // Background pattern (islamic geometric)
                islamicPatternBackground

                // Greeting + Streak
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(timeBasedGreeting)
                            .font(.bodySmall)
                            .foregroundStyle(.secondaryText)
                        Text(store.displayName)
                            .font(.displayMedium)
                            .foregroundStyle(.primaryText)
                    }
                    Spacer()
                    StreakBadge(count: store.streak)
                }
                .padding(.horizontal)

                // XP & Level Card
                StatsCard(
                    level: store.level,
                    totalXp: store.totalXp,
                    xpProgress: store.xpProgress
                )
                .padding(.horizontal)

                // Week Calendar
                WeekCalendarView(activities: store.weekActivities)
                    .padding(.horizontal)

                // Today's Habits Summary
                if store.hasHabits {
                    HabitsSummaryCard(
                        progress: store.habitProgress,
                        onContinueTapped: { /* navigate to adkhar */ }
                    )
                    .padding(.horizontal)
                }

                // Motivational Message
                MotivationalCard(streak: store.streak)
                    .padding(.horizontal)
            }
            .padding(.vertical, Spacing.lg)
        }
        .background(Color.background)
    }
}
```

---

### Task 5.2: Journey Cards Alignment

**File**: `RIZQ/Views/Components/JourneyViews/JourneyCardView.swift`

**React Reference**: `src/components/journeys/JourneyCard.tsx`

**Design Specs**:
- Rounded corners: 20px (islamic radius)
- Shadow: soft elevation
- Emoji icon: 48pt
- Stats row: minutes, XP, dua count
- Subscribe button or active indicator

```swift
struct JourneyCardView: View {
    let journey: Journey
    let isActive: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: Spacing.md) {
                // Header: Emoji + Title
                HStack(spacing: Spacing.md) {
                    Text(journey.emoji)
                        .font(.system(size: 48))

                    VStack(alignment: .leading, spacing: 4) {
                        Text(journey.name)
                            .font(.displaySmall)
                            .foregroundStyle(.primaryText)

                        if let description = journey.description {
                            Text(description)
                                .font(.bodySmall)
                                .foregroundStyle(.secondaryText)
                                .lineLimit(2)
                        }
                    }
                }

                // Stats Row
                HStack(spacing: Spacing.lg) {
                    StatBadge(icon: "clock", value: "\(journey.estimatedMinutes) min")
                    StatBadge(icon: "star.fill", value: "\(journey.dailyXp) XP")

                    Spacer()

                    // Status indicator
                    if isActive {
                        Label("Active", systemImage: "checkmark.circle.fill")
                            .font(.caption)
                            .foregroundStyle(.tealSuccess)
                    }
                }

                // Featured badge if applicable
                if journey.isFeatured {
                    Text("Featured")
                        .font(.caption2.bold())
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.goldSoft)
                        .foregroundStyle(.mocha)
                        .clipShape(Capsule())
                }
            }
            .padding(Spacing.md)
            .background(Color.card)
            .clipShape(RoundedRectangle(cornerRadius: CornerRadius.islamic))
            .shadow(color: .black.opacity(0.05), radius: 8, y: 4)
        }
        .buttonStyle(.plain)
    }
}

struct StatBadge: View {
    let icon: String
    let value: String

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.caption)
            Text(value)
                .font(.caption)
        }
        .foregroundStyle(.secondaryText)
    }
}
```

---

### Task 5.3: Practice Page Alignment

**File**: `RIZQ/Features/Practice/PracticeView.swift`

**React Reference**: `src/pages/PracticePage.tsx`

**Key Elements**:
1. **Tap Area**: Large card for counting taps
2. **Counter Display**: Big number with progress arc
3. **Arabic Text**: Prominent, RTL, with toggle for transliteration
4. **Context Tabs**: Practice / Context toggle
5. **Celebration**: Confetti + sound on completion

```swift
struct PracticeView: View {
    @Bindable var store: StoreOf<PracticeFeature>

    var body: some View {
        ZStack {
            // Background
            Color.background.ignoresSafeArea()

            VStack(spacing: Spacing.lg) {
                // Header with back and eye toggle
                practiceHeader

                // Main tap area
                TapCard(
                    arabicText: store.dua?.arabicText ?? "",
                    transliteration: store.showTransliteration ? store.dua?.transliteration : nil,
                    translation: store.dua?.translationEn ?? "",
                    onTap: { store.send(.cardTapped) }
                )
                .padding(.horizontal)

                // Counter with progress ring
                CounterView(
                    count: store.tapCount,
                    total: store.dua?.repetitions ?? 1
                )

                // Tab selector: Practice / Context
                if store.activeTab == .context {
                    ContextView(dua: store.dua)
                        .transition(.move(edge: .trailing))
                }

                Spacer()

                // Action buttons
                actionButtons
            }
            .padding(.vertical)

            // Celebration overlay
            if store.showCelebration {
                CelebrationOverlay(xpEarned: store.dua?.xpValue ?? 0) {
                    store.send(.celebrationDismissed)
                }
            }
        }
    }

    private var practiceHeader: some View {
        HStack {
            Button { store.send(.backTapped) } label: {
                Image(systemName: "chevron.left")
                    .font(.title2)
            }

            Spacer()

            Text(store.dua?.titleEn ?? "Practice")
                .font(.headline)

            Spacer()

            Button { store.send(.toggleTransliteration) } label: {
                Image(systemName: store.showTransliteration ? "eye.fill" : "eye.slash")
                    .font(.title2)
            }
        }
        .padding(.horizontal)
    }

    private var actionButtons: some View {
        HStack(spacing: Spacing.md) {
            Button {
                store.send(.resetTapped)
            } label: {
                Label("Reset", systemImage: "arrow.counterclockwise")
                    .padding()
                    .background(Color.card)
                    .clipShape(RoundedRectangle(cornerRadius: CornerRadius.button))
            }

            if store.hasNextDua {
                Button {
                    store.send(.nextTapped)
                } label: {
                    Label("Next", systemImage: "chevron.right")
                        .padding()
                        .background(Color.sand)
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: CornerRadius.button))
                }
            }
        }
        .padding(.horizontal)
    }
}

struct TapCard: View {
    let arabicText: String
    let transliteration: String?
    let translation: String
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(spacing: Spacing.lg) {
                // Arabic text
                Text(arabicText)
                    .font(.arabicLarge)
                    .multilineTextAlignment(.center)
                    .environment(\.layoutDirection, .rightToLeft)

                // Transliteration if shown
                if let trans = transliteration {
                    Text(trans)
                        .font(.bodyMedium)
                        .italic()
                        .foregroundStyle(.secondaryText)
                }

                Divider()

                // Translation
                Text(translation)
                    .font(.bodyMedium)
                    .foregroundStyle(.secondaryText)
                    .multilineTextAlignment(.center)
            }
            .padding(Spacing.xl)
            .frame(maxWidth: .infinity)
            .background(Color.card)
            .clipShape(RoundedRectangle(cornerRadius: CornerRadius.islamic))
            .shadow(color: .black.opacity(0.08), radius: 12, y: 6)
        }
        .buttonStyle(TapScaleButtonStyle())
    }
}

struct CounterView: View {
    let count: Int
    let total: Int

    private var progress: Double {
        Double(count) / Double(max(total, 1))
    }

    var body: some View {
        ZStack {
            // Background ring
            Circle()
                .stroke(Color.sand.opacity(0.2), lineWidth: 8)

            // Progress ring
            Circle()
                .trim(from: 0, to: progress)
                .stroke(Color.sand, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .animation(.spring(response: 0.3), value: progress)

            // Count display
            VStack(spacing: 4) {
                Text("\(count)")
                    .font(.counter)
                    .foregroundStyle(.primaryText)
                Text("of \(total)")
                    .font(.caption)
                    .foregroundStyle(.secondaryText)
            }
        }
        .frame(width: 120, height: 120)
    }
}
```

---

### Task 5.4: Animation Components

**File**: `RIZQ/Views/Components/Animations/`

**Components to Match React**:

1. **CelebrationParticles.swift**
```swift
struct CelebrationParticles: View {
    @State private var particles: [Particle] = []
    let colors: [Color] = [.goldBright, .sand, .tealSuccess, .sandLight]

    var body: some View {
        TimelineView(.animation) { timeline in
            Canvas { context, size in
                for particle in particles {
                    let rect = CGRect(
                        x: particle.x * size.width,
                        y: particle.y * size.height,
                        width: particle.size,
                        height: particle.size
                    )
                    context.fill(
                        Circle().path(in: rect),
                        with: .color(particle.color.opacity(particle.opacity))
                    )
                }
            }
        }
        .onAppear { generateParticles() }
    }

    private func generateParticles() {
        particles = (0..<50).map { _ in
            Particle(
                x: .random(in: 0...1),
                y: .random(in: 0...1),
                size: .random(in: 4...12),
                color: colors.randomElement()!,
                opacity: .random(in: 0.6...1),
                velocity: CGPoint(x: .random(in: -0.01...0.01), y: .random(in: 0.005...0.02))
            )
        }
    }
}
```

2. **RippleEffect.swift**
```swift
struct RippleEffect: ViewModifier {
    let origin: CGPoint
    @State private var scale: CGFloat = 0
    @State private var opacity: Double = 0.5

    func body(content: Content) -> some View {
        content.overlay(
            Circle()
                .fill(Color.sand.opacity(opacity))
                .scaleEffect(scale)
                .position(origin)
                .animation(.easeOut(duration: 0.4), value: scale)
        )
        .onAppear {
            scale = 3
            opacity = 0
        }
    }
}
```

3. **AnimatedCheckmark.swift**
```swift
struct AnimatedCheckmark: View {
    @State private var trimEnd: CGFloat = 0

    var body: some View {
        Circle()
            .fill(Color.tealSuccess)
            .frame(width: 48, height: 48)
            .overlay(
                Path { path in
                    path.move(to: CGPoint(x: 14, y: 24))
                    path.addLine(to: CGPoint(x: 20, y: 30))
                    path.addLine(to: CGPoint(x: 34, y: 16))
                }
                .trim(from: 0, to: trimEnd)
                .stroke(Color.white, style: StrokeStyle(lineWidth: 3, lineCap: .round, lineJoin: .round))
            )
            .onAppear {
                withAnimation(.easeOut(duration: 0.3).delay(0.1)) {
                    trimEnd = 1
                }
            }
    }
}
```

---

### Task 5.5: Category Badges

**File**: `RIZQ/Views/Components/CategoryBadge.swift`

```swift
struct CategoryBadge: View {
    let category: CategorySlug

    var body: some View {
        HStack(spacing: 4) {
            Text(category.emoji)
            Text(category.displayName)
                .font(.caption.bold())
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(category.color.opacity(0.15))
        .foregroundStyle(category.color)
        .clipShape(Capsule())
    }
}

extension CategorySlug {
    var emoji: String {
        switch self {
        case .morning: return "🌅"
        case .evening: return "🌙"
        case .rizq: return "💰"
        case .gratitude: return "🤲"
        }
    }

    var displayName: String {
        switch self {
        case .morning: return "Morning"
        case .evening: return "Evening"
        case .rizq: return "Rizq"
        case .gratitude: return "Gratitude"
        }
    }

    var color: Color {
        switch self {
        case .morning: return .orange
        case .evening: return .indigo
        case .rizq: return .green
        case .gratitude: return .purple
        }
    }
}
```

---

### Task 5.6: Islamic Pattern Background

**File**: `RIZQ/Views/Components/IslamicPatternView.swift`

```swift
struct IslamicPatternView: View {
    var opacity: Double = 0.05

    var body: some View {
        GeometryReader { geometry in
            Canvas { context, size in
                let pattern = createIslamicPattern(size: size)
                context.fill(pattern, with: .color(.sand.opacity(opacity)))
            }
        }
        .ignoresSafeArea()
    }

    private func createIslamicPattern(size: CGSize) -> Path {
        var path = Path()
        let spacing: CGFloat = 40
        let rows = Int(size.height / spacing) + 1
        let cols = Int(size.width / spacing) + 1

        for row in 0..<rows {
            for col in 0..<cols {
                let x = CGFloat(col) * spacing
                let y = CGFloat(row) * spacing
                let offset = row.isMultiple(of: 2) ? spacing / 2 : 0

                // Star pattern
                addStar(to: &path, center: CGPoint(x: x + offset, y: y), size: 8)
            }
        }

        return path
    }

    private func addStar(to path: inout Path, center: CGPoint, size: CGFloat) {
        let points = 8
        let innerRadius = size * 0.4
        let outerRadius = size

        var starPath = Path()
        for i in 0..<points * 2 {
            let radius = i.isMultiple(of: 2) ? outerRadius : innerRadius
            let angle = Double(i) * .pi / Double(points) - .pi / 2
            let point = CGPoint(
                x: center.x + CGFloat(cos(angle)) * radius,
                y: center.y + CGFloat(sin(angle)) * radius
            )

            if i == 0 {
                starPath.move(to: point)
            } else {
                starPath.addLine(to: point)
            }
        }
        starPath.closeSubpath()
        path.addPath(starPath)
    }
}
```

---

## Verification Checklist

- [ ] Home page matches React layout and colors
- [ ] Streak badge has glow effect animation
- [ ] XP ring animates on load and update
- [ ] Week calendar highlights today and active days
- [ ] Journey cards match React design
- [ ] Featured badge displays correctly
- [ ] Practice tap card has ripple feedback
- [ ] Counter ring animates smoothly
- [ ] Celebration particles appear on completion
- [ ] Category badges use correct colors
- [ ] Islamic pattern appears subtle in background
- [ ] All fonts match design system
- [ ] Shadows and radii are consistent

---

## Files Modified/Created

| File | Action | Description |
|------|--------|-------------|
| `Colors.swift` | MODIFY | Add full color palette |
| `Typography.swift` | MODIFY | Add font definitions |
| `Spacing.swift` | CREATE | Spacing constants |
| `HomeView.swift` | MODIFY | Match React layout |
| `JourneyCardView.swift` | MODIFY | Match React design |
| `PracticeView.swift` | MODIFY | Match React design |
| `CelebrationParticles.swift` | CREATE | Particle animation |
| `RippleEffect.swift` | CREATE | Tap feedback |
| `AnimatedCheckmark.swift` | CREATE | Completion indicator |
| `CategoryBadge.swift` | CREATE | Category pills |
| `IslamicPatternView.swift` | CREATE | Background pattern |

---

## Estimated Effort

| Task | Complexity | Estimate |
|------|------------|----------|
| 5.1 Home Page | Medium | 2 hours |
| 5.2 Journey Cards | Low | 1 hour |
| 5.3 Practice Page | Medium | 1.5 hours |
| 5.4 Animations | Medium | 2 hours |
| 5.5 Category Badges | Low | 30 min |
| 5.6 Islamic Pattern | Medium | 1 hour |
| **Total** | | **~8 hours** |

---

## Dependencies

- **Prerequisites**: Phases 1-4 (all data flowing)
- **Blockers**: Custom fonts must be added to Xcode project
- **Enables**: Phase 6 (final testing with polished UI)
