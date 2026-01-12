---
name: react-to-ios
description: "Translate React/Framer Motion UI to SwiftUI - match layouts, animations, and styling from the React web app"
---

# React to iOS Translation Skill

This skill helps translate React components from the RIZQ web app to SwiftUI for the iOS app, ensuring visual consistency across platforms.

## Project Locations

| Platform | Path |
|----------|------|
| React Web App | `/Users/omairdawood/Projects/RIZQ App/src/` |
| iOS App | `/Users/omairdawood/Projects/RIZQ App/RIZQ-iOS/RIZQ/` |
| iOS Framework | `/Users/omairdawood/Projects/RIZQ App/RIZQ-iOS/RIZQKit/` |

## Translation Process

### Step 1: Read the React Component

First, read and understand the React component:
```bash
# Example: Read the React home page
Read /Users/omairdawood/Projects/RIZQ\ App/src/pages/HomePage.tsx
```

### Step 2: Identify Key Elements

Map React concepts to SwiftUI:

| React | SwiftUI |
|-------|---------|
| `<div>` | `VStack`, `HStack`, `ZStack` |
| `<motion.div>` | View + `.modifier()` |
| `className="..."` | `.font()`, `.foregroundStyle()`, modifiers |
| `variants` | `@State` + `withAnimation()` |
| Tailwind classes | RIZQKit design tokens |
| Framer Motion | SwiftUI animations |

### Step 3: Map Styling

#### Tailwind to RIZQKit Mapping

**Colors:**
| Tailwind | RIZQKit |
|----------|---------|
| `bg-background` | `Color.rizqBackground` |
| `bg-card` | `Color.rizqCard` |
| `bg-primary` | `Color.rizqPrimary` |
| `text-foreground` | `Color.rizqText` |
| `text-muted-foreground` | `Color.rizqTextSecondary` |
| `text-primary` | `Color.rizqPrimary` |
| `border-primary/10` | `Color.rizqPrimary.opacity(0.1)` |

**Typography:**
| Tailwind | RIZQKit |
|----------|---------|
| `font-display text-2xl font-bold` | `.font(.rizqDisplayBold(.title2))` |
| `font-display text-lg font-semibold` | `.font(.rizqDisplayMedium(.title3))` |
| `text-sm text-muted-foreground` | `.font(.rizqSans(.subheadline)).foregroundStyle(.rizqTextSecondary)` |
| `text-xs font-semibold uppercase` | `.font(.rizqSansSemiBold(.caption)).tracking(1)` |
| `font-mono` | `.font(.rizqMono(.subheadline))` |

**Spacing:**
| Tailwind | RIZQKit |
|----------|---------|
| `gap-1`, `space-y-1` | `RIZQSpacing.xs` (4pt) |
| `gap-2`, `space-y-2` | `RIZQSpacing.sm` (8pt) |
| `gap-3`, `space-y-3` | `RIZQSpacing.md` (12pt) |
| `gap-4`, `space-y-4`, `p-4` | `RIZQSpacing.lg` (16pt) |
| `gap-5`, `space-y-5`, `p-5` | `RIZQSpacing.xl` (20pt) |
| `gap-6`, `space-y-6`, `p-6` | `RIZQSpacing.xxl` (24pt) |
| `pb-24` | `RIZQSpacing.huge` (48pt) |

**Border Radius:**
| Tailwind | RIZQKit |
|----------|---------|
| `rounded-lg` | `RIZQRadius.md` (12pt) |
| `rounded-btn` | `RIZQRadius.btn` (16pt) |
| `rounded-islamic` | `RIZQRadius.islamic` (20pt) |
| `rounded-full` | `.clipShape(Circle())` |

**Shadows:**
| Tailwind | RIZQKit |
|----------|---------|
| `shadow-soft` | `.shadowSoft()` |
| `shadow-elevated` | `.shadowElevated()` |
| `shadow-glow-primary` | `.shadowGlowPrimary()` |

### Step 4: Translate Layout

#### Flex Layout
```tsx
// React
<div className="flex items-center justify-between">
  <div className="flex items-center gap-4">
    {/* content */}
  </div>
  <StreakBadge />
</div>
```

```swift
// SwiftUI
HStack {
  HStack(spacing: RIZQSpacing.lg) {
    // content
  }
  Spacer()
  StreakBadge(streak: store.streak)
}
```

#### Grid Layout
```tsx
// React
<div className="flex gap-3">
  <Link to="/journeys" className="flex-1">
    <Button>Browse Journeys</Button>
  </Link>
  <Link to="/library" className="flex-1">
    <Button variant="outline">Explore All Duas</Button>
  </Link>
</div>
```

```swift
// SwiftUI
HStack(spacing: RIZQSpacing.md) {
  Button { store.send(.navigateToJourneys) } label: {
    // Primary button content
  }

  Button { store.send(.navigateToLibrary) } label: {
    // Secondary button content
  }
}
```

### Step 5: Translate Animations

#### Framer Motion Variants to SwiftUI

**Container with staggered children:**
```tsx
// React
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

<motion.div variants={containerVariants} initial="hidden" animate="visible">
  <motion.div variants={itemVariants}>Item 1</motion.div>
  <motion.div variants={itemVariants}>Item 2</motion.div>
</motion.div>
```

```swift
// SwiftUI
struct StaggeredAnimationModifier: ViewModifier {
  let index: Int
  @State private var isVisible: Bool = false

  private var delay: Double {
    0.1 + Double(index) * 0.08
  }

  func body(content: Content) -> some View {
    content
      .opacity(isVisible ? 1 : 0)
      .offset(y: isVisible ? 0 : 20)
      .onAppear {
        withAnimation(.spring(response: 0.4, dampingFraction: 0.75).delay(delay)) {
          isVisible = true
        }
      }
  }
}

// Usage
VStack {
  headerSection.modifier(StaggeredAnimationModifier(index: 0))
  statsCard.modifier(StaggeredAnimationModifier(index: 1))
  weekCalendar.modifier(StaggeredAnimationModifier(index: 2))
}
```

**Hover and Tap:**
```tsx
// React
<motion.div whileHover={{ y: -2 }} whileTap={{ scale: 0.98 }}>
```

```swift
// SwiftUI
struct ScaleButtonStyle: ButtonStyle {
  func makeBody(configuration: Configuration) -> some View {
    configuration.label
      .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
      .animation(.spring(response: 0.3, dampingFraction: 0.7), value: configuration.isPressed)
  }
}

Button(action: {}) { /* content */ }
  .buttonStyle(ScaleButtonStyle())
```

**Animated Progress Bar:**
```tsx
// React
<motion.div
  initial={{ width: 0 }}
  animate={{ width: `${percentage}%` }}
  transition={{ duration: 0.8, delay: 0.3 }}
/>
```

```swift
// SwiftUI
@State private var animatedWidth: CGFloat = 0

Capsule()
  .fill(Color.rizqPrimary)
  .frame(width: geometry.size.width * animatedWidth, height: 8)
  .onAppear {
    withAnimation(.easeOut(duration: 0.8).delay(0.3)) {
      animatedWidth = percentage
    }
  }
```

## Page-by-Page Translation Reference

### HomePage.tsx → HomeView.swift

| React Element | SwiftUI Equivalent |
|---------------|-------------------|
| Header with Avatar + Greeting | `headerSection` with `UserAvatar` + `VStack` |
| `<StreakBadge size="md" />` | `CompactStreakBadge(streak: store.streak)` |
| Hero Stats Card | `heroStatsCard` with `CircularXpProgress` |
| `<WeekCalendar />` | `WeekCalendarView(activities:)` |
| Today's Progress card | `TodaysProgressCard(duasCompleted:xpEarned:)` |
| `<HabitsSummaryCard />` | `HabitsSummaryCard(completed:total:percentage:xpEarned:onTap:)` |
| Bottom CTA buttons | `bottomCTAButtons` with `HStack` of buttons |

### LibraryPage.tsx → LibraryView.swift

| React Element | SwiftUI Equivalent |
|---------------|-------------------|
| Search input | `TextField` with `.textFieldStyle()` |
| Category filter chips | `ScrollView(.horizontal)` with `CategoryBadge` |
| Dua list | `LazyVStack` with `DuaListCardView` |

### DailyAdkharPage.tsx → AdkharView.swift

| React Element | SwiftUI Equivalent |
|---------------|-------------------|
| Time slot sections | `Section` with `TimeSlotSectionView` |
| Habit items | `HabitItemView` |
| Quick practice sheet | `.sheet()` with `QuickPracticeSheet` |

### PracticePage.tsx → PracticeView.swift

| React Element | SwiftUI Equivalent |
|---------------|-------------------|
| Arabic text | `Text().font(.rizqArabic()).environment(\.layoutDirection, .rightToLeft)` |
| Transliteration | `Text().font(.rizqSans(.title3)).italic()` |
| Translation | `Text().font(.rizqSans(.body))` |
| Repetition counter | `AnimatedCounter` + tap area |
| Celebration on complete | `CelebrationParticles` |

## Component Mapping Reference

### React Components → iOS Components

| React Component | iOS Component | Location |
|-----------------|---------------|----------|
| `<StreakBadge />` | `StreakBadge` | `GamificationViews.swift` |
| `<CircularXpProgress />` | `CircularXpProgress` | `GamificationViews.swift` |
| `<XpProgressBar />` | `XpProgressBar` | `GamificationViews.swift` |
| `<WeekCalendar />` | `WeekCalendarView` | `HomeViews/WeekCalendarView.swift` |
| `<HabitsSummaryCard />` | `HabitsSummaryCard` | `HabitViews/HabitsSummaryCard.swift` |
| `<JourneyCard />` | `JourneyCardView` | `JourneyViews/JourneyCardView.swift` |
| `<JourneyIcon />` | `JourneyIconView` | `JourneyViews/JourneyIconView.swift` |
| `<CelebrationParticles />` | `CelebrationParticles` | `Animations/CelebrationParticles.swift` |
| `<AnimatedCheckmark />` | `AnimatedCheckmark` | `Animations/AnimatedCheckmark.swift` |
| `<Sparkles />` | `Sparkles` | `Animations/Sparkles.swift` |

## Translation Checklist

When translating a React screen to iOS:

1. **Read the React file**
   - [ ] Identify layout structure (flex, grid)
   - [ ] Note all Tailwind classes used
   - [ ] List Framer Motion animations
   - [ ] Identify data dependencies (hooks, context)

2. **Create TCA Feature** (if new screen)
   - [ ] Define State with required properties
   - [ ] Define Actions for user interactions
   - [ ] Implement reducer with effects
   - [ ] Wire up navigation in parent feature

3. **Build SwiftUI View**
   - [ ] Match layout hierarchy
   - [ ] Apply RIZQKit design tokens
   - [ ] Add staggered entry animations
   - [ ] Implement button interactions
   - [ ] Add loading/empty states

4. **Verify Visual Parity**
   - [ ] Compare screenshots side-by-side
   - [ ] Check spacing and alignment
   - [ ] Verify colors match
   - [ ] Test animations feel similar
   - [ ] Confirm typography is correct

5. **Build Verification**
   ```bash
   cd RIZQ-iOS && xcodebuild -scheme RIZQ \
     -destination 'platform=iOS Simulator,name=iPhone 17' \
     build 2>&1 | grep -E "(error:|BUILD SUCCEEDED|BUILD FAILED)"
   ```

## Quick Reference Card

### Layout
```swift
// Horizontal with spacing
HStack(spacing: RIZQSpacing.md) { }

// Vertical with spacing
VStack(spacing: RIZQSpacing.lg) { }

// Full width
.frame(maxWidth: .infinity)

// Alignment
VStack(alignment: .leading) { }
HStack(alignment: .top) { }
```

### Styling
```swift
// Card styling
.padding(RIZQSpacing.lg)
.background(Color.rizqCard)
.clipShape(RoundedRectangle(cornerRadius: RIZQRadius.islamic))
.shadowSoft()

// Border
.overlay(
  RoundedRectangle(cornerRadius: RIZQRadius.islamic)
    .stroke(Color.rizqPrimary.opacity(0.2), lineWidth: 1)
)

// Gradient button
.background(
  LinearGradient(
    colors: [Color.rizqPrimary, Color.sandDeep],
    startPoint: .leading,
    endPoint: .trailing
  )
)
```

### Animation
```swift
// Entry animation
.modifier(StaggeredAnimationModifier(index: 0))

// Button press
.buttonStyle(ScaleButtonStyle())

// Animate value change
.animation(.easeOut(duration: 0.5), value: someValue)

// Spring
withAnimation(.spring(response: 0.4, dampingFraction: 0.75)) {
  isVisible = true
}
```
