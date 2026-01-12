---
name: add-animation
description: "Interactive command to add animations to an existing SwiftUI view"
allowed_tools:
  - Read
  - Write
  - Edit
  - Glob
  - Grep
  - Bash
  - AskUserQuestion
arguments:
  - name: view_file
    description: "Path to the SwiftUI view file to add animations to"
    required: false
  - name: animation_type
    description: "Type of animation to add (entry, interaction, progress, celebration)"
    required: false
---

# Add Animation to SwiftUI View

You are helping the user add beautiful animations to their SwiftUI view, matching the RIZQ design system.

## Step 1: Identify the Target

If the user didn't specify a file, ask:

<questions>
- Which view do you want to animate?
- What type of animation do you need?
  - Entry animation (fade in, slide up, stagger children)
  - Interaction (button press, tap feedback)
  - Progress (bars, circles, counters)
  - Celebration (particles, sparkles, checkmark)
</questions>

## Step 2: Read the View

Read the target SwiftUI view to understand:
- View hierarchy and structure
- Existing animations (if any)
- State variables available
- Content that should animate

## Step 3: Select Animation Pattern

Based on the view type and user's goal, recommend the appropriate animation:

### Entry Animations

**Staggered Container (for lists/sections):**
```swift
// Add state
@State private var isVisible: Bool = false

// Add modifier to each child
VStack(spacing: RIZQSpacing.lg) {
  headerSection
    .modifier(StaggeredAnimationModifier(index: 0))
  cardSection
    .modifier(StaggeredAnimationModifier(index: 1))
  listSection
    .modifier(StaggeredAnimationModifier(index: 2))
}
```

**Single View Fade-In:**
```swift
@State private var isVisible: Bool = false

content
  .opacity(isVisible ? 1 : 0)
  .offset(y: isVisible ? 0 : 20)
  .onAppear {
    withAnimation(.spring(response: 0.4, dampingFraction: 0.75)) {
      isVisible = true
    }
  }
```

### Interaction Animations

**Button Press:**
```swift
Button(action: {}) {
  Text("Tap Me")
    .rizqPrimaryButton()
}
.buttonStyle(ScaleButtonStyle())
```

**Card Tap:**
```swift
cardContent
  .contentShape(Rectangle())
  .onTapGesture { /* action */ }
  .buttonStyle(ScaleButtonStyle())
```

### Progress Animations

**Linear Progress Bar:**
```swift
struct AnimatedProgressBar: View {
  let percentage: Double
  @State private var animatedWidth: CGFloat = 0

  var body: some View {
    GeometryReader { geometry in
      Capsule()
        .fill(Color.rizqPrimary)
        .frame(width: geometry.size.width * animatedWidth)
    }
    .onAppear {
      withAnimation(.easeOut(duration: 0.8).delay(0.3)) {
        animatedWidth = percentage
      }
    }
  }
}
```

**Circular Progress:**
```swift
Circle()
  .trim(from: 0, to: animatedProgress)
  .stroke(Color.rizqPrimary, style: StrokeStyle(lineWidth: 8, lineCap: .round))
  .rotationEffect(.degrees(-90))
  .onAppear {
    withAnimation(.easeOut(duration: 1.0)) {
      animatedProgress = percentage
    }
  }
```

**Animated Counter:**
```swift
Text("\(displayValue)")
  .contentTransition(.numericText())
  .onChange(of: targetValue) { _, newValue in
    withAnimation(.spring(response: 0.4, dampingFraction: 0.6)) {
      displayValue = newValue
    }
  }
```

### Celebration Animations

**Pop-In Badge:**
```swift
badge
  .modifier(PopInModifier(delay: 0.5))
```

**Pulsing Indicator:**
```swift
indicator
  .modifier(PulsingModifier())
```

**Celebration Particles:**
```swift
ZStack {
  content
  if showCelebration {
    CelebrationParticles()
  }
}
```

## Step 4: Implement the Animation

1. Add required `@State` variables
2. Add the animation modifier or code
3. Ensure timing matches React equivalents (0.08s stagger, 0.4s duration)
4. Use spring physics for interactions (response: 0.3-0.5, dampingFraction: 0.6-0.8)

## Step 5: Verify Build

```bash
cd "/Users/omairdawood/Projects/RIZQ App/RIZQ-iOS" && xcodebuild -scheme RIZQ \
  -destination 'platform=iOS Simulator,name=iPhone 17' \
  build 2>&1 | grep -E "(error:|BUILD SUCCEEDED|BUILD FAILED)"
```

## Animation Quick Reference

| Animation | Spring Response | Damping | Duration |
|-----------|-----------------|---------|----------|
| Button tap | 0.3 | 0.7 | - |
| Entry | 0.4 | 0.75 | - |
| Pop-in | 0.5 | 0.6 | - |
| Counter | 0.4 | 0.6 | - |
| Progress bar | - | - | 0.8s |
| Stagger delay | - | - | 0.08s per item |
| Initial delay | - | - | 0.1s |

## Accessibility

Always check for reduced motion preference:

```swift
@Environment(\.accessibilityReduceMotion) var reduceMotion

withAnimation(reduceMotion ? .none : .spring(response: 0.4, dampingFraction: 0.75)) {
  isVisible = true
}
```

## Output

After adding animations:
1. List the animations added
2. Show the modified code sections
3. Confirm build succeeded
4. Remind about testing on device (simulator animations feel different)

