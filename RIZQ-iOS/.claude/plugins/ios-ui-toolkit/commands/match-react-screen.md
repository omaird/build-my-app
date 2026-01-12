---
name: match-react-screen
description: "Interactive command to match a React screen to iOS SwiftUI implementation"
allowed_tools:
  - Read
  - Write
  - Edit
  - Glob
  - Grep
  - Bash
  - AskUserQuestion
arguments:
  - name: react_file
    description: "Path to the React component file (e.g., HomePage.tsx)"
    required: false
  - name: ios_file
    description: "Path to the iOS SwiftUI view file (e.g., HomeView.swift)"
    required: false
---

# Match React Screen to iOS

You are helping the user translate a React component from the RIZQ web app to SwiftUI for the iOS app.

## Workflow

### Step 1: Identify the Files

If the user didn't provide file paths, ask which screen they want to match:

<questions>
- Which React screen do you want to match to iOS?
  - HomePage.tsx → HomeView.swift
  - LibraryPage.tsx → LibraryView.swift
  - DailyAdkharPage.tsx → AdkharView.swift
  - PracticePage.tsx → PracticeView.swift
  - JourneysPage.tsx → JourneysView.swift
  - Other (specify path)
</questions>

### Step 2: Read Both Files

Read the React file to understand:
- Layout structure (flex, grid, containers)
- Tailwind CSS classes used
- Framer Motion animations
- State and props
- User interactions

Read the iOS file to understand:
- Current implementation status
- Existing TCA state and actions
- Views and subviews used

### Step 3: Identify Gaps

Compare the two implementations and create a checklist of differences:

**Layout:**
- [ ] Container structure matches
- [ ] Spacing and padding match
- [ ] Flex direction and alignment match

**Styling:**
- [ ] Colors match (using RIZQKit tokens)
- [ ] Typography matches (font families and sizes)
- [ ] Shadows match
- [ ] Border radius matches

**Components:**
- [ ] All subcomponents are implemented
- [ ] Component props match
- [ ] States (loading, empty, error) match

**Animations:**
- [ ] Entry animations match (staggered, fade, slide)
- [ ] Interaction animations match (tap, hover)
- [ ] Progress animations match
- [ ] Celebration effects present if needed

**Data:**
- [ ] Same data is displayed
- [ ] Data transformations match
- [ ] Empty/null handling matches

### Step 4: Implement Missing Pieces

For each gap identified, implement the missing functionality:

1. **Create missing components** in `/RIZQ/Views/Components/`
2. **Update the view** to match React layout
3. **Add animations** using StaggeredAnimationModifier and spring physics
4. **Apply design tokens** from RIZQKit

### Step 5: Build Verification

After making changes, verify the build:

```bash
cd "/Users/omairdawood/Projects/RIZQ App/RIZQ-iOS" && xcodebuild -scheme RIZQ \
  -destination 'platform=iOS Simulator,name=iPhone 17' \
  build 2>&1 | grep -E "(error:|BUILD SUCCEEDED|BUILD FAILED)"
```

## Key Translation References

### Tailwind → RIZQKit

| Tailwind | RIZQKit |
|----------|---------|
| `bg-background` | `Color.rizqBackground` |
| `bg-card` | `Color.rizqCard` |
| `bg-primary` | `Color.rizqPrimary` |
| `text-foreground` | `Color.rizqText` |
| `text-muted-foreground` | `Color.rizqTextSecondary` |
| `gap-4`, `p-4` | `RIZQSpacing.lg` (16pt) |
| `rounded-islamic` | `RIZQRadius.islamic` (20pt) |
| `shadow-soft` | `.shadowSoft()` |

### Framer Motion → SwiftUI

| Framer Motion | SwiftUI |
|---------------|---------|
| `variants` with stagger | `StaggeredAnimationModifier(index:)` |
| `whileTap: { scale: 0.98 }` | `.buttonStyle(ScaleButtonStyle())` |
| `initial/animate` opacity/y | `.opacity()` + `.offset(y:)` + `.onAppear` |
| `transition: { duration: 0.4 }` | `.animation(.easeOut(duration: 0.4))` |

### Layout

| React | SwiftUI |
|-------|---------|
| `flex flex-col` | `VStack` |
| `flex flex-row` | `HStack` |
| `items-center justify-between` | `HStack { ... Spacer() ... }` |
| `grid grid-cols-2` | `LazyVGrid(columns: [.flexible(), .flexible()])` |

## Output

After completing the translation:

1. List all changes made
2. Show before/after comparison for key sections
3. Confirm build succeeded
4. Note any manual testing needed

