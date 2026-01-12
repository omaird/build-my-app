# Feature: iOS Home Page Redesign with Gamification

The following plan should be complete, but it's important that you validate documentation and codebase patterns and task sanity before you start implementing.

Pay special attention to naming of existing utils, types, and models. Import from the right files etc.

## Feature Description

Transform the iOS home page into a beautiful, engaging dashboard that tracks daily adkhar (habits) with rich gamification elements. The redesign introduces:

1. **Weekly Habit Tracker** - A horizontal week view at the top showing daily completion dots with the current day highlighted
2. **Achievement Badge System** - Beautiful hexagonal milestone badges that users unlock through consistent practice
3. **Islamic Inspirational Quotes** - Daily rotating quotes with elegant typography and subtle animations
4. **Enhanced Habit Cards** - Improved habit display with progress indicators, time tracking, and quick actions
5. **Motivational Progress Section** - Dynamic encouragement based on daily activity with glowing badge visuals

**Design Inspiration Sources:**
- Weekly tracker inspired by the horizontal date row with completion dots
- Achievement badges using hexagonal shapes with celebratory particle effects
- Motivational quotes section with elegant typography
- Dark luxurious aesthetic adapted to RIZQ's warm Islamic color palette

## User Story

As a Muslim practicing daily duas,
I want to see my progress visualized beautifully with weekly tracking, achievement badges, and inspiring quotes,
So that I feel motivated and rewarded for maintaining consistent spiritual habits.

## Problem Statement

The current home page displays basic progress information but lacks the visual engagement and gamification depth needed to encourage daily return and habit formation. Users don't have:
- Clear weekly progress visualization
- Milestone achievements to work toward
- Daily inspiration to motivate practice
- Rich visual feedback for progress

## Solution Statement

Redesign the home page with a gamification-first approach featuring:
1. A weekly tracker strip showing 7 days with completion indicators
2. An achievement badge system with beautiful hexagonal badges for milestones
3. A daily Islamic quote section with elegant presentation
4. Enhanced habit cards with better progress visualization
5. A motivational section that adapts messaging based on daily activity

## Feature Metadata

**Feature Type**: Enhancement
**Estimated Complexity**: High
**Primary Systems Affected**: HomeFeature, HomeView, GamificationViews, New Achievement System
**Dependencies**: Existing TCA infrastructure, RIZQKit Design System, Firebase for persistence

---

## CONTEXT REFERENCES

### Relevant Codebase Files - IMPORTANT: YOU MUST READ THESE FILES BEFORE IMPLEMENTING!

**Core Feature Files:**
- `RIZQ-iOS/RIZQ/Features/Home/HomeFeature.swift` - Current TCA reducer with State, Actions, Effects
- `RIZQ-iOS/RIZQ/Features/Home/HomeView.swift` - Current UI layout with staggered animations
- `RIZQ-iOS/RIZQ/App/AppFeature.swift` - Parent feature handling navigation

**Design System (Critical for Consistency):**
- `RIZQ-iOS/RIZQKit/Design/Colors.swift` - Full color palette (sandWarm, mocha, cream, gold, teal, streakGlow, etc.)
- `RIZQ-iOS/RIZQKit/Design/Typography.swift` - Font styles (.rizqSans, .rizqDisplay, .rizqArabic, .rizqMono)
- `RIZQ-iOS/RIZQKit/Design/Spacing.swift` - Spacing scale (xs:4, sm:8, md:12, lg:16, xl:20, xxl:24, xxxl:32, huge:48)

**Existing Home Components:**
- `RIZQ-iOS/RIZQ/Views/Components/HomeViews/WeekCalendarView.swift` - Week activity display with animations
- `RIZQ-iOS/RIZQ/Views/Components/HomeViews/TodaysProgressCard.swift` - Progress card, CompactStreakBadge, UserAvatar

**Gamification Components:**
- `RIZQ-iOS/RIZQ/Views/Components/GamificationViews/GamificationViews.swift` - StreakBadge, LevelBadge, CircularXpProgress, XpProgressBar, StatsCard, AnimatedNumber

**Animation Components:**
- `RIZQ-iOS/RIZQ/Views/Components/Animations/CelebrationParticles.swift` - Particle system with stars, sparkles, dots
- `RIZQ-iOS/RIZQ/Views/Components/Animations/AnimatedCheckmark.swift` - Checkmark with glow
- `RIZQ-iOS/RIZQ/Views/Components/Animations/AnimatedCounter.swift` - Counter with ripple effect

**Habit Components:**
- `RIZQ-iOS/RIZQ/Views/Components/HabitViews/HabitItemView.swift` - Single habit row with checkbox
- `RIZQ-iOS/RIZQ/Views/Components/HabitViews/HabitsSummaryCard.swift` - Summary card for habits
- `RIZQ-iOS/RIZQ/Views/Components/HabitViews/TimeSlotSectionView.swift` - Grouped habit sections

**Models:**
- `RIZQ-iOS/RIZQKit/Models/User.swift` - UserProfile (streak, totalXp, level), UserActivity, LevelCalculator
- `RIZQ-iOS/RIZQKit/Models/Habit.swift` - TodayProgress, UserHabit, HabitCompletion

### New Files to Create

**New Components:**
- `RIZQ-iOS/RIZQ/Views/Components/HomeViews/WeeklyTrackerView.swift` - Horizontal week tracker with completion dots
- `RIZQ-iOS/RIZQ/Views/Components/HomeViews/AchievementBadgeView.swift` - Hexagonal milestone badge component
- `RIZQ-iOS/RIZQ/Views/Components/HomeViews/DailyQuoteView.swift` - Islamic quote card component
- `RIZQ-iOS/RIZQ/Views/Components/HomeViews/MotivationalProgressView.swift` - Dynamic motivation section
- `RIZQ-iOS/RIZQ/Views/Components/HomeViews/EnhancedHabitCard.swift` - Improved habit card design

**New Models:**
- `RIZQ-iOS/RIZQKit/Models/Achievement.swift` - Achievement/Badge data model and definitions

**New Features (Optional - for badge details):**
- `RIZQ-iOS/RIZQ/Features/Achievements/AchievementsFeature.swift` - Badge detail view TCA feature

### Relevant Documentation - YOU SHOULD READ THESE BEFORE IMPLEMENTING!

- TCA Best Practices: `RIZQ-iOS/CLAUDE.md` (lines 1-300) - TCA patterns, naming conventions
- SwiftUI Animation Guide: Apple's SwiftUI Animation documentation
- SF Symbols: Use system icons for consistency

### Patterns to Follow

**TCA State Pattern:**
```swift
@ObservableState
struct State: Equatable {
  var propertyName: Type = defaultValue
  @Presents var childFeature: ChildFeature.State?
}
```

**View Composition Pattern:**
```swift
struct HomeView: View {
  @Bindable var store: StoreOf<HomeFeature>

  var body: some View {
    ScrollView {
      VStack(spacing: RIZQSpacing.lg) {
        sectionOne.modifier(StaggeredAnimationModifier(index: 0))
        sectionTwo.modifier(StaggeredAnimationModifier(index: 1))
      }
    }
  }

  private var sectionOne: some View { ... }
}
```

**Animation Pattern (Staggered Entry):**
```swift
struct StaggeredAnimationModifier: ViewModifier {
  let index: Int
  @State private var isVisible: Bool = false

  private var delay: Double { 0.1 + Double(index) * 0.08 }

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
```

**Color Usage:**
```swift
Color.rizqPrimary      // sandWarm #D4A574
Color.rizqAccent       // mocha #6B4423
Color.rizqCard         // creamWarm #FFFCF7
Color.rizqBackground   // cream #F5EFE7
Color.streakGlow       // amber #F59E0B
Color.goldBright       // #FFEBB3
Color.tealSuccess      // #6B9B7C
```

**Typography:**
```swift
.font(.rizqDisplayBold(.title2))    // Playfair Display Bold
.font(.rizqSansMedium(.body))       // Crimson Pro Medium
.font(.rizqArabic(.title3))         // Amiri
.font(.rizqMono(.caption))          // JetBrains Mono
```

**Spacing:**
```swift
.padding(RIZQSpacing.lg)           // 16pt
.spacing(RIZQSpacing.md)           // 12pt
RoundedRectangle(cornerRadius: RIZQRadius.islamic)  // 20pt
```

---

## IMPLEMENTATION PLAN

### Phase 1: Data Models & Achievement System Foundation

Create the achievement/badge data model and define milestone achievements.

**Tasks:**
- Create Achievement model with badge types, unlock criteria, visual properties
- Define default achievements (First Step, Week Warrior, Month Master, etc.)
- Add achievements state to HomeFeature
- Create achievement persistence/loading logic

### Phase 2: Weekly Tracker Component

Build the horizontal week tracker showing daily completion status.

**Tasks:**
- Create WeeklyTrackerView component
- Implement day selection/highlighting for current day
- Add completion dot indicators with animations
- Connect to existing weekActivities data in HomeFeature

### Phase 3: Achievement Badge Component

Create the hexagonal badge component with celebration effects.

**Tasks:**
- Design HexagonShape for badge background
- Create AchievementBadgeView with glow and particle effects
- Implement badge unlock animation sequence
- Create badge detail sheet/modal

### Phase 4: Daily Quote Component

Build the Islamic inspirational quote section.

**Tasks:**
- Create DailyQuoteView component
- Define quote data structure and sample quotes
- Implement elegant typography and subtle animations
- Add daily rotation logic

### Phase 5: Motivational Progress Section

Create the dynamic motivation area that responds to daily activity.

**Tasks:**
- Create MotivationalProgressView component
- Implement dynamic messaging based on habit completion
- Add glowing badge preview for upcoming achievement
- Create "Light Day" / "Productive Day" states

### Phase 6: Home View Integration & Polish

Integrate all new components into HomeView.

**Tasks:**
- Restructure HomeView layout with new sections
- Update HomeFeature state with new requirements
- Add staggered animations to new components
- Implement pull-to-refresh for all data
- Polish transitions and interactions

---

## FEATURES (For Plan-Loop Execution)

The following features group the atomic tasks for multi-persona iterative review. Each feature goes through a 6-persona cycle before moving to the next.

### 1. Data Models Foundation

**Description:** Create the Achievement and IslamicQuote data models that power the gamification and motivational features. These models define badge types, unlock criteria, and quote rotation logic.

**Files:**
- `RIZQ-iOS/RIZQKit/Models/Achievement.swift` - Create
- `RIZQ-iOS/RIZQKit/Models/IslamicQuote.swift` - Create

**Tasks Included:** Task 1, Task 2

**Acceptance Criteria:**
- [ ] Achievement model has id, name, description, emoji, category, requirement, xpReward, unlockedAt
- [ ] AchievementCategory enum covers streak, practice, level, special
- [ ] AchievementRequirement supports streakDays, totalDuas, levelReached, perfectWeek
- [ ] 5 default achievements defined (First Step, Week Warrior, Month Master, Rising Star, Perfect Week)
- [ ] IslamicQuote model has id, arabicText (optional), englishText, source, category
- [ ] QuoteCategory enum covers quran, hadith, wisdom
- [ ] 7 daily quotes defined with mix of categories
- [ ] quoteForToday() returns consistent quote for the same day
- [ ] All models conform to Codable, Identifiable, Equatable, Sendable
- [ ] Build compiles without errors

---

### 2. Shape & Weekly Tracker Components

**Description:** Create the custom HexagonShape for achievement badges and the WeeklyTrackerView component showing 7-day progress at a glance.

**Files:**
- `RIZQ-iOS/RIZQ/Views/Components/Shapes/HexagonShape.swift` - Create
- `RIZQ-iOS/RIZQ/Views/Components/HomeViews/WeeklyTrackerView.swift` - Create

**Tasks Included:** Task 3, Task 4

**Acceptance Criteria:**
- [ ] HexagonShape draws a proper 6-sided polygon starting from top
- [ ] RoundedHexagonShape provides softer corners for badges
- [ ] WeeklyTrackerView displays 7 days horizontally
- [ ] Current day has pulsing ring indicator
- [ ] Completed days show teal checkmark with scale animation
- [ ] Day abbreviations and date numbers display correctly
- [ ] Sequential animation on appear (staggered dots)
- [ ] Uses existing DailyActivityItem model
- [ ] VoiceOver accessibility for each day
- [ ] Build compiles without errors

---

### 3. Achievement Badge System

**Description:** Create the hexagonal achievement badge component with glow effects, unlock animations, and the full-screen celebration overlay for new unlocks.

**Files:**
- `RIZQ-iOS/RIZQ/Views/Components/HomeViews/AchievementBadgeView.swift` - Create

**Tasks Included:** Task 5

**Acceptance Criteria:**
- [ ] AchievementBadgeView renders hexagonal badge with RoundedHexagonShape
- [ ] Unlocked badges have category-colored glow animation
- [ ] Locked badges appear muted with gray tones
- [ ] Badge shows emoji text centered in hexagon
- [ ] Unlock animation scales badge with spring effect
- [ ] showDetails flag enables name/description display
- [ ] AchievementUnlockOverlay provides full-screen celebration
- [ ] Celebration includes CelebrationParticles
- [ ] XP reward displayed with gold styling
- [ ] Dismiss on background tap works correctly
- [ ] Build compiles without errors

---

### 4. Quote & Motivation Components

**Description:** Create the DailyQuoteView for Islamic inspiration and the MotivationalProgressView that adapts messaging based on daily habit completion.

**Files:**
- `RIZQ-iOS/RIZQ/Views/Components/HomeViews/DailyQuoteView.swift` - Create
- `RIZQ-iOS/RIZQ/Views/Components/HomeViews/MotivationalProgressView.swift` - Create

**Tasks Included:** Task 6, Task 7

**Acceptance Criteria:**
- [ ] DailyQuoteView displays quote icon, category badge, source
- [ ] Arabic text displays RTL with proper font (Amiri)
- [ ] English text uses elegant italic typography
- [ ] Subtle gold gradient background for quote card
- [ ] MotivationalProgressView shows 5 states: noHabits, notStarted, lightDay, productiveDay, perfectDay
- [ ] Each state has unique title, message, icon, and glow color
- [ ] Shows next unlockable achievement preview with glow
- [ ] Action text provides contextual CTA
- [ ] Streak count influences not-started messaging
- [ ] Animations feel smooth and polished
- [ ] Build compiles without errors

---

### 5. HomeFeature Integration & Polish

**Description:** Integrate all new components into HomeFeature state management and HomeView layout. Add achievement checking logic, wire up data flow, and polish the final experience.

**Files:**
- `RIZQ-iOS/RIZQ/Features/Home/HomeFeature.swift` - Modify
- `RIZQ-iOS/RIZQ/Features/Home/HomeView.swift` - Modify
- `RIZQ-iOS/RIZQKit/RIZQKit.h` (or exports) - Modify if needed

**Tasks Included:** Task 8, Task 9, Task 10, Task 11

**Acceptance Criteria:**
- [ ] HomeFeature.State includes achievements array, unlockedAchievementIds, dailyQuote
- [ ] HomeFeature.State includes showAchievementUnlock, newlyUnlockedAchievement
- [ ] nextUnlockableAchievement computed property works correctly
- [ ] achievementsLoaded, checkAchievements, achievementUnlocked, dismissAchievementUnlock actions added
- [ ] Achievement check triggers after profile loads
- [ ] Achievement unlock logic covers all requirement types
- [ ] HomeView renders new section order: header, weeklyTracker, quote, adkhar, motivation, badges, stats, CTA
- [ ] StaggeredAnimationModifier applied to all sections
- [ ] Achievement badges section shows horizontal scrolling grid
- [ ] Stats row shows circular XP progress, level, mini progress bar, streak badge
- [ ] fullScreenCover binding works for achievement unlock overlay
- [ ] Pull-to-refresh updates all data
- [ ] New models exported from RIZQKit
- [ ] All previews render correctly
- [ ] Build compiles without errors
- [ ] Unit tests pass for new HomeFeature logic
- [ ] Snapshot tests capture new component states

---

## STEP-BY-STEP TASKS

IMPORTANT: Execute every task in order, top to bottom. Each task is atomic and independently testable.

### Task 1: CREATE Achievement Model

**File:** `RIZQ-iOS/RIZQKit/Models/Achievement.swift`

**IMPLEMENT:**
```swift
import Foundation

// MARK: - Achievement Model

public struct Achievement: Codable, Identifiable, Equatable, Sendable {
  public let id: String
  public let name: String
  public let description: String
  public let emoji: String
  public let category: AchievementCategory
  public let requirement: AchievementRequirement
  public let xpReward: Int
  public let unlockedAt: Date?

  public var isUnlocked: Bool { unlockedAt != nil }
}

public enum AchievementCategory: String, Codable, CaseIterable, Sendable {
  case streak      // Consistency-based
  case practice    // Practice count-based
  case level       // Level-based
  case special     // Special occasions
}

public struct AchievementRequirement: Codable, Equatable, Sendable {
  public let type: RequirementType
  public let value: Int

  public enum RequirementType: String, Codable, Sendable {
    case streakDays
    case totalDuas
    case levelReached
    case perfectWeek
  }
}

// MARK: - Default Achievements

public extension Achievement {
  static let defaults: [Achievement] = [
    Achievement(
      id: "first-step",
      name: "First Step",
      description: "Complete your first dua",
      emoji: "1",
      category: .practice,
      requirement: AchievementRequirement(type: .totalDuas, value: 1),
      xpReward: 50,
      unlockedAt: nil
    ),
    Achievement(
      id: "week-warrior",
      name: "Week Warrior",
      description: "Maintain a 7-day streak",
      emoji: "7",
      category: .streak,
      requirement: AchievementRequirement(type: .streakDays, value: 7),
      xpReward: 100,
      unlockedAt: nil
    ),
    Achievement(
      id: "month-master",
      name: "Month Master",
      description: "Maintain a 30-day streak",
      emoji: "30",
      category: .streak,
      requirement: AchievementRequirement(type: .streakDays, value: 30),
      xpReward: 500,
      unlockedAt: nil
    ),
    Achievement(
      id: "level-5",
      name: "Rising Star",
      description: "Reach Level 5",
      emoji: "5",
      category: .level,
      requirement: AchievementRequirement(type: .levelReached, value: 5),
      xpReward: 200,
      unlockedAt: nil
    ),
    Achievement(
      id: "perfect-week",
      name: "Perfect Week",
      description: "Complete all habits for 7 consecutive days",
      emoji: "W",
      category: .special,
      requirement: AchievementRequirement(type: .perfectWeek, value: 7),
      xpReward: 300,
      unlockedAt: nil
    )
  ]
}
```

**PATTERN:** Mirror `RIZQ-iOS/RIZQKit/Models/User.swift` struct pattern
**IMPORTS:** `import Foundation`
**GOTCHA:** Ensure Sendable conformance for TCA compatibility
**VALIDATE:** `cd RIZQ-iOS && xcodebuild -scheme RIZQ -destination 'platform=iOS Simulator,name=iPhone 17' build 2>&1 | grep -E "(error:|BUILD SUCCEEDED|BUILD FAILED)"`

---

### Task 2: CREATE Islamic Quotes Data

**File:** `RIZQ-iOS/RIZQKit/Models/IslamicQuote.swift`

**IMPLEMENT:**
```swift
import Foundation

public struct IslamicQuote: Codable, Identifiable, Equatable, Sendable {
  public let id: String
  public let arabicText: String?
  public let englishText: String
  public let source: String
  public let category: QuoteCategory

  public enum QuoteCategory: String, Codable, CaseIterable, Sendable {
    case quran
    case hadith
    case wisdom
  }
}

public extension IslamicQuote {
  static let dailyQuotes: [IslamicQuote] = [
    IslamicQuote(
      id: "q1",
      arabicText: "فَإِنَّ مَعَ الْعُسْرِ يُسْرًا",
      englishText: "For indeed, with hardship comes ease.",
      source: "Quran 94:5",
      category: .quran
    ),
    IslamicQuote(
      id: "q2",
      arabicText: "وَاذْكُر رَّبَّكَ كَثِيرًا",
      englishText: "And remember your Lord much.",
      source: "Quran 3:41",
      category: .quran
    ),
    IslamicQuote(
      id: "q3",
      arabicText: nil,
      englishText: "The best among you are those who have the best manners and character.",
      source: "Sahih Bukhari",
      category: .hadith
    ),
    IslamicQuote(
      id: "q4",
      arabicText: "مَن لَزِمَ الاستغفارَ جعل اللهُ له من كلِّ همٍّ فرجًا",
      englishText: "Whoever remains constant in seeking forgiveness, Allah will grant them relief from every worry.",
      source: "Abu Dawud",
      category: .hadith
    ),
    IslamicQuote(
      id: "q5",
      arabicText: nil,
      englishText: "Take benefit of five before five: your youth before your old age, your health before your sickness, your wealth before your poverty, your free time before your preoccupation, and your life before your death.",
      source: "Sahih Hadith",
      category: .wisdom
    ),
    IslamicQuote(
      id: "q6",
      arabicText: "الدُّعَاءُ هُوَ الْعِبَادَةُ",
      englishText: "Dua is the essence of worship.",
      source: "Tirmidhi",
      category: .hadith
    ),
    IslamicQuote(
      id: "q7",
      arabicText: nil,
      englishText: "Be in this world as if you were a stranger or a traveler along a path.",
      source: "Sahih Bukhari",
      category: .wisdom
    )
  ]

  /// Get quote for a specific day (rotates through quotes)
  static func quoteForToday() -> IslamicQuote {
    let dayOfYear = Calendar.current.ordinality(of: .day, in: .year, for: Date()) ?? 1
    let index = (dayOfYear - 1) % dailyQuotes.count
    return dailyQuotes[index]
  }
}
```

**PATTERN:** Similar to other model files
**IMPORTS:** `import Foundation`
**GOTCHA:** Arabic text is optional since not all quotes have it
**VALIDATE:** `cd RIZQ-iOS && xcodebuild -scheme RIZQ -destination 'platform=iOS Simulator,name=iPhone 17' build 2>&1 | grep -E "(error:|BUILD SUCCEEDED|BUILD FAILED)"`

---

### Task 3: CREATE Hexagon Shape

**File:** `RIZQ-iOS/RIZQ/Views/Components/Shapes/HexagonShape.swift`

**IMPLEMENT:**
```swift
import SwiftUI

/// Hexagon shape for achievement badges
struct HexagonShape: Shape {
  func path(in rect: CGRect) -> Path {
    let width = rect.width
    let height = rect.height
    let centerX = rect.midX
    let centerY = rect.midY
    let radius = min(width, height) / 2

    var path = Path()

    // Start from top center and go clockwise
    for i in 0..<6 {
      let angle = Double(i) * .pi / 3 - .pi / 2
      let x = centerX + CGFloat(cos(angle)) * radius
      let y = centerY + CGFloat(sin(angle)) * radius

      if i == 0 {
        path.move(to: CGPoint(x: x, y: y))
      } else {
        path.addLine(to: CGPoint(x: x, y: y))
      }
    }
    path.closeSubpath()

    return path
  }
}

/// Rounded hexagon for softer appearance
struct RoundedHexagonShape: Shape {
  var cornerRadius: CGFloat = 8

  func path(in rect: CGRect) -> Path {
    let width = rect.width
    let height = rect.height
    let centerX = rect.midX
    let centerY = rect.midY
    let radius = min(width, height) / 2 - cornerRadius

    var points: [CGPoint] = []

    for i in 0..<6 {
      let angle = Double(i) * .pi / 3 - .pi / 2
      let x = centerX + CGFloat(cos(angle)) * radius
      let y = centerY + CGFloat(sin(angle)) * radius
      points.append(CGPoint(x: x, y: y))
    }

    var path = Path()

    for i in 0..<6 {
      let currentPoint = points[i]
      let nextPoint = points[(i + 1) % 6]

      if i == 0 {
        path.move(to: CGPoint(
          x: currentPoint.x + (nextPoint.x - currentPoint.x) * 0.1,
          y: currentPoint.y + (nextPoint.y - currentPoint.y) * 0.1
        ))
      }

      // Add rounded corner
      path.addLine(to: CGPoint(
        x: nextPoint.x - (nextPoint.x - currentPoint.x) * 0.1,
        y: nextPoint.y - (nextPoint.y - currentPoint.y) * 0.1
      ))

      let afterNext = points[(i + 2) % 6]
      path.addQuadCurve(
        to: CGPoint(
          x: nextPoint.x + (afterNext.x - nextPoint.x) * 0.1,
          y: nextPoint.y + (afterNext.y - nextPoint.y) * 0.1
        ),
        control: nextPoint
      )
    }

    path.closeSubpath()
    return path
  }
}

#Preview {
  VStack(spacing: 20) {
    HexagonShape()
      .fill(Color.rizqPrimary)
      .frame(width: 100, height: 100)

    RoundedHexagonShape(cornerRadius: 10)
      .fill(Color.badgeEvening)
      .frame(width: 100, height: 100)
  }
  .padding()
}
```

**PATTERN:** Mirror `CelebrationParticles.swift` StarShape pattern
**IMPORTS:** `import SwiftUI`
**GOTCHA:** Hexagon starts at top, goes clockwise
**VALIDATE:** `cd RIZQ-iOS && xcodebuild -scheme RIZQ -destination 'platform=iOS Simulator,name=iPhone 17' build 2>&1 | grep -E "(error:|BUILD SUCCEEDED|BUILD FAILED)"`

---

### Task 4: CREATE Weekly Tracker View

**File:** `RIZQ-iOS/RIZQ/Views/Components/HomeViews/WeeklyTrackerView.swift`

**IMPLEMENT:**
```swift
import SwiftUI
import RIZQKit

/// Horizontal week tracker showing daily completion status
/// Inspired by the habit app's weekly tracker at top
struct WeeklyTrackerView: View {
  let activities: [DailyActivityItem]
  var onDayTapped: ((Date) -> Void)?

  @State private var animatedDays: Set<Int> = []

  var body: some View {
    VStack(spacing: RIZQSpacing.md) {
      // Week days horizontal scroll
      HStack(spacing: 0) {
        ForEach(Array(activities.enumerated()), id: \.offset) { index, item in
          dayView(item: item, index: index)
            .frame(maxWidth: .infinity)
        }
      }
    }
    .padding(.vertical, RIZQSpacing.lg)
    .padding(.horizontal, RIZQSpacing.md)
    .background(Color.rizqCard)
    .clipShape(RoundedRectangle(cornerRadius: RIZQRadius.islamic))
    .shadowSoft()
    .onAppear {
      animateDaysSequentially()
    }
  }

  private func dayView(item: DailyActivityItem, index: Int) -> some View {
    VStack(spacing: RIZQSpacing.sm) {
      // Day abbreviation
      Text(shortDayLabel(from: item.dayLabel))
        .font(.rizqSans(.caption2))
        .foregroundStyle(item.isToday ? Color.rizqPrimary : Color.rizqTextSecondary)
        .textCase(.uppercase)

      // Date number
      Text(dateNumber(from: item.date))
        .font(item.isToday ? .rizqSansBold(.subheadline) : .rizqSans(.subheadline))
        .foregroundStyle(item.isToday ? Color.rizqText : Color.rizqTextSecondary)

      // Completion indicator
      ZStack {
        Circle()
          .fill(circleBackground(for: item))
          .frame(width: 32, height: 32)

        if item.completed {
          Circle()
            .fill(Color.tealSuccess)
            .frame(width: 32, height: 32)
            .scaleEffect(animatedDays.contains(index) ? 1 : 0)
            .animation(.spring(response: 0.4, dampingFraction: 0.6).delay(Double(index) * 0.05), value: animatedDays.contains(index))

          Image(systemName: "checkmark")
            .font(.system(size: 12, weight: .bold))
            .foregroundStyle(.white)
            .scaleEffect(animatedDays.contains(index) ? 1 : 0)
            .animation(.spring(response: 0.4, dampingFraction: 0.6).delay(Double(index) * 0.05 + 0.1), value: animatedDays.contains(index))
        } else if item.isToday {
          // Pulsing ring for today
          Circle()
            .stroke(Color.rizqPrimary, lineWidth: 2)
            .frame(width: 32, height: 32)
            .modifier(PulsingModifier())
        }
      }
    }
    .contentShape(Rectangle())
    .onTapGesture {
      onDayTapped?(item.date)
    }
  }

  private func shortDayLabel(from label: String) -> String {
    // Convert single letter to 3-letter abbreviation
    let formatter = DateFormatter()
    formatter.dateFormat = "EEE"
    // This will be handled by the caller providing the right format
    return String(label.prefix(3))
  }

  private func dateNumber(from date: Date) -> String {
    let formatter = DateFormatter()
    formatter.dateFormat = "d"
    return formatter.string(from: date)
  }

  private func circleBackground(for item: DailyActivityItem) -> Color {
    if item.completed {
      return Color.clear
    } else if item.isToday {
      return Color.rizqPrimary.opacity(0.1)
    } else {
      return Color.rizqMuted.opacity(0.2)
    }
  }

  private func animateDaysSequentially() {
    for i in 0..<activities.count {
      DispatchQueue.main.asyncAfter(deadline: .now() + 0.1 + Double(i) * 0.05) {
        animatedDays.insert(i)
      }
    }
  }
}

// MARK: - Pulsing Modifier (reuse from WeekCalendarView)
private struct PulsingModifier: ViewModifier {
  @State private var isPulsing = false

  func body(content: Content) -> some View {
    content
      .scaleEffect(isPulsing ? 1.1 : 1.0)
      .opacity(isPulsing ? 0.6 : 1.0)
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

#Preview("Weekly Tracker") {
  let activities = (0..<7).reversed().map { daysAgo in
    DailyActivityItem(
      date: Calendar.current.date(byAdding: .day, value: -daysAgo, to: Date())!,
      completed: [0, 2, 3, 5].contains(6 - daysAgo)
    )
  }

  WeeklyTrackerView(activities: activities)
    .padding()
    .background(Color.rizqBackground)
}
```

**PATTERN:** Mirror `WeekCalendarView.swift` animation and structure patterns
**IMPORTS:** `import SwiftUI`, `import RIZQKit`
**GOTCHA:** Use existing `DailyActivityItem` model from `WeekCalendarView.swift`
**VALIDATE:** `cd RIZQ-iOS && xcodebuild -scheme RIZQ -destination 'platform=iOS Simulator,name=iPhone 17' build 2>&1 | grep -E "(error:|BUILD SUCCEEDED|BUILD FAILED)"`

---

### Task 5: CREATE Achievement Badge View

**File:** `RIZQ-iOS/RIZQ/Views/Components/HomeViews/AchievementBadgeView.swift`

**IMPLEMENT:**
```swift
import SwiftUI
import RIZQKit

/// Hexagonal achievement badge with glow and celebration effects
struct AchievementBadgeView: View {
  let achievement: Achievement
  let size: CGFloat
  var showDetails: Bool = false
  var isAnimating: Bool = false

  @State private var glowOpacity: Double = 0.3
  @State private var scale: CGFloat = 1.0

  init(
    achievement: Achievement,
    size: CGFloat = 100,
    showDetails: Bool = false,
    isAnimating: Bool = false
  ) {
    self.achievement = achievement
    self.size = size
    self.showDetails = showDetails
    self.isAnimating = isAnimating
  }

  var body: some View {
    VStack(spacing: RIZQSpacing.md) {
      // Badge hexagon
      ZStack {
        // Outer glow
        if achievement.isUnlocked {
          RoundedHexagonShape(cornerRadius: size * 0.1)
            .fill(badgeColor.opacity(glowOpacity))
            .frame(width: size * 1.2, height: size * 1.2)
            .blur(radius: 20)
        }

        // Badge border
        RoundedHexagonShape(cornerRadius: size * 0.08)
          .stroke(
            achievement.isUnlocked ? badgeColor : Color.rizqMuted.opacity(0.5),
            lineWidth: 4
          )
          .frame(width: size, height: size)

        // Badge fill
        RoundedHexagonShape(cornerRadius: size * 0.08)
          .fill(
            achievement.isUnlocked
              ? LinearGradient(
                  colors: [badgeColor.opacity(0.3), badgeColor.opacity(0.1)],
                  startPoint: .topLeading,
                  endPoint: .bottomTrailing
                )
              : LinearGradient(
                  colors: [Color.rizqMuted.opacity(0.1), Color.rizqMuted.opacity(0.05)],
                  startPoint: .topLeading,
                  endPoint: .bottomTrailing
                )
          )
          .frame(width: size - 8, height: size - 8)

        // Badge content
        Text(achievement.emoji)
          .font(.system(size: size * 0.35, weight: .bold, design: .rounded))
          .foregroundStyle(achievement.isUnlocked ? badgeColor : Color.rizqMuted)
      }
      .scaleEffect(scale)
      .onAppear {
        if achievement.isUnlocked {
          startGlowAnimation()
        }
      }
      .onChange(of: isAnimating) { _, newValue in
        if newValue {
          playUnlockAnimation()
        }
      }

      // Details section
      if showDetails {
        VStack(spacing: RIZQSpacing.xs) {
          Text(achievement.name)
            .font(.rizqDisplayMedium(.subheadline))
            .foregroundStyle(Color.rizqText)

          Text(achievement.description)
            .font(.rizqSans(.caption))
            .foregroundStyle(Color.rizqTextSecondary)
            .multilineTextAlignment(.center)

          if achievement.isUnlocked, let unlockedAt = achievement.unlockedAt {
            Text(formattedDate(unlockedAt))
              .font(.rizqSans(.caption2))
              .foregroundStyle(Color.rizqTextTertiary)
          }
        }
      }
    }
  }

  private var badgeColor: Color {
    switch achievement.category {
    case .streak: return .streakGlow
    case .practice: return .tealSuccess
    case .level: return .badgeEvening
    case .special: return .goldBright
    }
  }

  private func startGlowAnimation() {
    withAnimation(
      Animation.easeInOut(duration: 2.0)
        .repeatForever(autoreverses: true)
    ) {
      glowOpacity = 0.6
    }
  }

  private func playUnlockAnimation() {
    withAnimation(.spring(response: 0.4, dampingFraction: 0.5)) {
      scale = 1.2
    }
    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
      withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
        scale = 1.0
      }
    }
  }

  private func formattedDate(_ date: Date) -> String {
    let formatter = DateFormatter()
    formatter.dateFormat = "MMM d, yyyy"
    return formatter.string(from: date)
  }
}

/// Full achievement unlock celebration overlay
struct AchievementUnlockOverlay: View {
  let achievement: Achievement
  @Binding var isPresented: Bool

  @State private var showContent = false
  @State private var showParticles = false

  var body: some View {
    ZStack {
      // Dimmed background
      Color.black.opacity(0.7)
        .ignoresSafeArea()
        .onTapGesture {
          dismiss()
        }

      VStack(spacing: RIZQSpacing.xxl) {
        // Badge with particles
        ZStack {
          CelebrationParticles(isActive: $showParticles, particleCount: 20)

          AchievementBadgeView(
            achievement: achievement,
            size: 140,
            showDetails: false,
            isAnimating: showContent
          )
        }
        .frame(width: 200, height: 200)

        // Achievement info
        VStack(spacing: RIZQSpacing.md) {
          Text(achievement.name)
            .font(.rizqDisplayBold(.title2))
            .foregroundStyle(.white)

          Text(achievement.description)
            .font(.rizqSans(.body))
            .foregroundStyle(.white.opacity(0.8))
            .multilineTextAlignment(.center)

          // XP reward
          HStack(spacing: RIZQSpacing.sm) {
            Image(systemName: "sparkles")
              .foregroundStyle(Color.goldBright)

            Text("+\(achievement.xpReward) XP")
              .font(.rizqMonoMedium(.headline))
              .foregroundStyle(Color.goldBright)
          }
          .padding(.horizontal, RIZQSpacing.lg)
          .padding(.vertical, RIZQSpacing.sm)
          .background(Color.goldBright.opacity(0.2))
          .clipShape(Capsule())
        }
        .opacity(showContent ? 1 : 0)
        .offset(y: showContent ? 0 : 20)

        // Share button (optional)
        Button {
          // TODO: Implement share
        } label: {
          Text("Share Achievement")
            .font(.rizqSansMedium(.subheadline))
            .foregroundStyle(.white)
            .padding(.horizontal, RIZQSpacing.xl)
            .padding(.vertical, RIZQSpacing.md)
            .background(Color.white.opacity(0.2))
            .clipShape(Capsule())
        }
        .opacity(showContent ? 1 : 0)
      }
      .padding(RIZQSpacing.xxl)
    }
    .onAppear {
      withAnimation(.easeOut(duration: 0.5)) {
        showContent = true
      }
      showParticles = true
    }
  }

  private func dismiss() {
    withAnimation(.easeIn(duration: 0.3)) {
      showContent = false
      showParticles = false
    }
    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
      isPresented = false
    }
  }
}

#Preview("Achievement Badge - Unlocked") {
  let achievement = Achievement(
    id: "first-step",
    name: "First Step",
    description: "Complete your first dua",
    emoji: "1",
    category: .practice,
    requirement: AchievementRequirement(type: .totalDuas, value: 1),
    xpReward: 50,
    unlockedAt: Date()
  )

  AchievementBadgeView(achievement: achievement, size: 120, showDetails: true)
    .padding()
    .background(Color.rizqBackground)
}

#Preview("Achievement Badge - Locked") {
  let achievement = Achievement.defaults[1]

  AchievementBadgeView(achievement: achievement, size: 120, showDetails: true)
    .padding()
    .background(Color.rizqBackground)
}

#Preview("Achievement Grid") {
  LazyVGrid(columns: [GridItem(.adaptive(minimum: 100))], spacing: 20) {
    ForEach(Achievement.defaults) { achievement in
      AchievementBadgeView(achievement: achievement, size: 80, showDetails: true)
    }
  }
  .padding()
  .background(Color.rizqBackground)
}
```

**PATTERN:** Mirror `GamificationViews.swift` animation patterns
**IMPORTS:** `import SwiftUI`, `import RIZQKit`
**GOTCHA:** Need to import/reference HexagonShape from Task 3, CelebrationParticles from existing animations
**VALIDATE:** `cd RIZQ-iOS && xcodebuild -scheme RIZQ -destination 'platform=iOS Simulator,name=iPhone 17' build 2>&1 | grep -E "(error:|BUILD SUCCEEDED|BUILD FAILED)"`

---

### Task 6: CREATE Daily Quote View

**File:** `RIZQ-iOS/RIZQ/Views/Components/HomeViews/DailyQuoteView.swift`

**IMPLEMENT:**
```swift
import SwiftUI
import RIZQKit

/// Islamic quote card with elegant typography
struct DailyQuoteView: View {
  let quote: IslamicQuote

  @State private var isVisible = false

  var body: some View {
    VStack(alignment: .leading, spacing: RIZQSpacing.lg) {
      // Quote icon
      HStack {
        Image(systemName: "quote.opening")
          .font(.title2)
          .foregroundStyle(Color.goldSoft)

        Spacer()

        // Category badge
        Text(quote.category.displayName)
          .font(.rizqSans(.caption2))
          .foregroundStyle(Color.rizqTextSecondary)
          .padding(.horizontal, RIZQSpacing.sm)
          .padding(.vertical, RIZQSpacing.xs)
          .background(Color.rizqMuted.opacity(0.2))
          .clipShape(Capsule())
      }

      // Arabic text (if available)
      if let arabicText = quote.arabicText {
        Text(arabicText)
          .font(.rizqArabic(.title3))
          .foregroundStyle(Color.rizqText)
          .multilineTextAlignment(.trailing)
          .frame(maxWidth: .infinity, alignment: .trailing)
          .environment(\.layoutDirection, .rightToLeft)
          .opacity(isVisible ? 1 : 0)
          .offset(y: isVisible ? 0 : 10)
      }

      // English translation
      Text(quote.englishText)
        .font(.rizqDisplayMedium(.body))
        .foregroundStyle(Color.rizqText)
        .italic()
        .multilineTextAlignment(.leading)
        .opacity(isVisible ? 1 : 0)
        .offset(y: isVisible ? 0 : 10)

      // Source
      HStack {
        Spacer()

        Text("— \(quote.source)")
          .font(.rizqSansMedium(.caption))
          .foregroundStyle(Color.rizqPrimary)
      }
      .opacity(isVisible ? 1 : 0)
    }
    .padding(RIZQSpacing.xl)
    .background(
      LinearGradient(
        colors: [Color.goldSoft.opacity(0.08), Color.goldBright.opacity(0.03)],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
      )
    )
    .overlay(
      RoundedRectangle(cornerRadius: RIZQRadius.islamic)
        .stroke(Color.goldSoft.opacity(0.3), lineWidth: 1)
    )
    .clipShape(RoundedRectangle(cornerRadius: RIZQRadius.islamic))
    .shadowSoft()
    .onAppear {
      withAnimation(.easeOut(duration: 0.6).delay(0.2)) {
        isVisible = true
      }
    }
  }
}

extension IslamicQuote.QuoteCategory {
  var displayName: String {
    switch self {
    case .quran: return "Quran"
    case .hadith: return "Hadith"
    case .wisdom: return "Wisdom"
    }
  }
}

#Preview("Daily Quote - Quran") {
  DailyQuoteView(quote: IslamicQuote.dailyQuotes[0])
    .padding()
    .background(Color.rizqBackground)
}

#Preview("Daily Quote - Hadith") {
  DailyQuoteView(quote: IslamicQuote.dailyQuotes[2])
    .padding()
    .background(Color.rizqBackground)
}

#Preview("Daily Quote - Today") {
  DailyQuoteView(quote: IslamicQuote.quoteForToday())
    .padding()
    .background(Color.rizqBackground)
}
```

**PATTERN:** Mirror card styling from `TodaysProgressCard.swift`
**IMPORTS:** `import SwiftUI`, `import RIZQKit`
**GOTCHA:** Arabic text is optional; handle RTL layout correctly
**VALIDATE:** `cd RIZQ-iOS && xcodebuild -scheme RIZQ -destination 'platform=iOS Simulator,name=iPhone 17' build 2>&1 | grep -E "(error:|BUILD SUCCEEDED|BUILD FAILED)"`

---

### Task 7: CREATE Motivational Progress View

**File:** `RIZQ-iOS/RIZQ/Views/Components/HomeViews/MotivationalProgressView.swift`

**IMPLEMENT:**
```swift
import SwiftUI
import RIZQKit

/// Dynamic motivational section that adapts based on daily activity
/// Shows encouraging messages and upcoming achievement preview
struct MotivationalProgressView: View {
  let habitsCompleted: Int
  let totalHabits: Int
  let streak: Int
  let nextAchievement: Achievement?

  @State private var badgeGlow: Double = 0.3
  @State private var isVisible = false

  private var progressState: ProgressState {
    guard totalHabits > 0 else { return .noHabits }

    let percentage = Double(habitsCompleted) / Double(totalHabits)
    if percentage == 0 { return .notStarted }
    if percentage < 0.5 { return .lightDay }
    if percentage < 1.0 { return .productiveDay }
    return .perfectDay
  }

  var body: some View {
    VStack(spacing: RIZQSpacing.xl) {
      // Badge preview (next achievement or current state)
      if let achievement = nextAchievement {
        upcomingBadgeSection(achievement)
      } else {
        currentStateBadge
      }

      // Motivational message
      motivationalMessage
        .opacity(isVisible ? 1 : 0)
        .offset(y: isVisible ? 0 : 15)

      // Call to action
      if progressState != .perfectDay && progressState != .noHabits {
        actionSuggestion
          .opacity(isVisible ? 1 : 0)
      }
    }
    .padding(RIZQSpacing.xl)
    .background(
      LinearGradient(
        colors: [Color.rizqCard, Color.rizqBackground.opacity(0.5)],
        startPoint: .top,
        endPoint: .bottom
      )
    )
    .clipShape(RoundedRectangle(cornerRadius: RIZQRadius.islamic))
    .shadowSoft()
    .onAppear {
      withAnimation(.easeOut(duration: 0.6).delay(0.3)) {
        isVisible = true
      }
      startBadgeGlow()
    }
  }

  // MARK: - Badge Sections

  private func upcomingBadgeSection(_ achievement: Achievement) -> some View {
    VStack(spacing: RIZQSpacing.md) {
      // Glowing badge preview
      ZStack {
        // Glow effect
        Circle()
          .fill(Color.goldSoft.opacity(badgeGlow))
          .frame(width: 100, height: 100)
          .blur(radius: 30)

        // Badge placeholder
        AchievementBadgeView(
          achievement: achievement,
          size: 80,
          showDetails: false
        )
      }

      Text("Next: \(achievement.name)")
        .font(.rizqSansMedium(.caption))
        .foregroundStyle(Color.rizqTextSecondary)
    }
  }

  private var currentStateBadge: some View {
    ZStack {
      Circle()
        .fill(progressState.glowColor.opacity(badgeGlow))
        .frame(width: 100, height: 100)
        .blur(radius: 30)

      Image(systemName: progressState.icon)
        .font(.system(size: 40))
        .foregroundStyle(progressState.glowColor)
    }
  }

  // MARK: - Motivational Message

  private var motivationalMessage: some View {
    VStack(spacing: RIZQSpacing.sm) {
      Text(progressState.title)
        .font(.rizqDisplayBold(.title2))
        .foregroundStyle(Color.rizqText)

      Text(progressState.message(habitsCompleted: habitsCompleted, streak: streak))
        .font(.rizqSans(.body))
        .foregroundStyle(Color.rizqTextSecondary)
        .multilineTextAlignment(.center)
    }
  }

  private var actionSuggestion: some View {
    Text(progressState.actionText)
      .font(.rizqSansMedium(.subheadline))
      .foregroundStyle(Color.rizqPrimary)
      .padding(.horizontal, RIZQSpacing.lg)
      .padding(.vertical, RIZQSpacing.sm)
      .background(Color.rizqPrimary.opacity(0.1))
      .clipShape(Capsule())
  }

  private func startBadgeGlow() {
    withAnimation(
      Animation.easeInOut(duration: 2.0)
        .repeatForever(autoreverses: true)
    ) {
      badgeGlow = 0.6
    }
  }
}

// MARK: - Progress State

private enum ProgressState {
  case noHabits
  case notStarted
  case lightDay
  case productiveDay
  case perfectDay

  var title: String {
    switch self {
    case .noHabits: return "Start Your Journey"
    case .notStarted: return "Ready to Begin"
    case .lightDay: return "Light Day"
    case .productiveDay: return "Making Progress"
    case .perfectDay: return "Perfect Day!"
    }
  }

  func message(habitsCompleted: Int, streak: Int) -> String {
    switch self {
    case .noHabits:
      return "Subscribe to a journey to start building your daily practice."
    case .notStarted:
      if streak > 0 {
        return "You have a \(streak)-day streak going! Don't break the chain."
      }
      return "Your habits are waiting. Start your day with remembrance."
    case .lightDay:
      return "You've planted \(habitsCompleted) habit\(habitsCompleted == 1 ? "" : "s") today. You can keep it light — or add another small one to grow alongside it."
    case .productiveDay:
      return "Great momentum! You're more than halfway through your daily practice."
    case .perfectDay:
      return "MashaAllah! You've completed all your habits today. Rest knowing you've done well."
    }
  }

  var actionText: String {
    switch self {
    case .noHabits: return "Browse Journeys"
    case .notStarted: return "Start First Habit"
    case .lightDay: return "Continue Practice"
    case .productiveDay: return "Almost There!"
    case .perfectDay: return ""
    }
  }

  var icon: String {
    switch self {
    case .noHabits: return "leaf"
    case .notStarted: return "sunrise"
    case .lightDay: return "leaf.fill"
    case .productiveDay: return "flame"
    case .perfectDay: return "checkmark.seal.fill"
    }
  }

  var glowColor: Color {
    switch self {
    case .noHabits: return .rizqMuted
    case .notStarted: return .goldSoft
    case .lightDay: return .goldBright
    case .productiveDay: return .streakGlow
    case .perfectDay: return .tealSuccess
    }
  }
}

#Preview("Motivational - Light Day") {
  MotivationalProgressView(
    habitsCompleted: 1,
    totalHabits: 5,
    streak: 3,
    nextAchievement: Achievement.defaults[0]
  )
  .padding()
  .background(Color.rizqBackground)
}

#Preview("Motivational - Perfect Day") {
  MotivationalProgressView(
    habitsCompleted: 5,
    totalHabits: 5,
    streak: 7,
    nextAchievement: nil
  )
  .padding()
  .background(Color.rizqBackground)
}

#Preview("Motivational - Not Started") {
  MotivationalProgressView(
    habitsCompleted: 0,
    totalHabits: 5,
    streak: 0,
    nextAchievement: Achievement.defaults[0]
  )
  .padding()
  .background(Color.rizqBackground)
}
```

**PATTERN:** Dynamic state-based messaging similar to HomeFeature motivationalPhrase
**IMPORTS:** `import SwiftUI`, `import RIZQKit`
**GOTCHA:** Requires AchievementBadgeView from Task 5
**VALIDATE:** `cd RIZQ-iOS && xcodebuild -scheme RIZQ -destination 'platform=iOS Simulator,name=iPhone 17' build 2>&1 | grep -E "(error:|BUILD SUCCEEDED|BUILD FAILED)"`

---

### Task 8: UPDATE HomeFeature with Achievement State

**File:** `RIZQ-iOS/RIZQ/Features/Home/HomeFeature.swift`

**ADD to State struct (after line ~33):**
```swift
// Achievement state
var achievements: [Achievement] = Achievement.defaults
var unlockedAchievementIds: Set<String> = []
var showAchievementUnlock: Bool = false
var newlyUnlockedAchievement: Achievement?

// Daily quote
var dailyQuote: IslamicQuote = IslamicQuote.quoteForToday()
```

**ADD to Action enum (after line ~103):**
```swift
case achievementsLoaded([Achievement])
case checkAchievements
case achievementUnlocked(Achievement)
case dismissAchievementUnlock
```

**ADD computed property (after line ~85):**
```swift
var nextUnlockableAchievement: Achievement? {
  achievements
    .filter { !$0.isUnlocked }
    .sorted { $0.requirement.value < $1.requirement.value }
    .first
}
```

**ADD cases to reducer body (before the final return):**
```swift
case .achievementsLoaded(let achievements):
  state.achievements = achievements
  state.unlockedAchievementIds = Set(achievements.filter { $0.isUnlocked }.map { $0.id })
  return .none

case .checkAchievements:
  // Check each achievement against current stats
  var newUnlock: Achievement?

  for achievement in state.achievements where !achievement.isUnlocked {
    let isEarned: Bool
    switch achievement.requirement.type {
    case .streakDays:
      isEarned = state.streak >= achievement.requirement.value
    case .totalDuas:
      let totalCompleted = state.todayActivity?.duasCompleted.count ?? 0
      isEarned = totalCompleted >= achievement.requirement.value
    case .levelReached:
      isEarned = state.level >= achievement.requirement.value
    case .perfectWeek:
      let perfectDays = state.weekActivities.filter { !$0.duasCompleted.isEmpty }.count
      isEarned = perfectDays >= achievement.requirement.value
    }

    if isEarned {
      newUnlock = Achievement(
        id: achievement.id,
        name: achievement.name,
        description: achievement.description,
        emoji: achievement.emoji,
        category: achievement.category,
        requirement: achievement.requirement,
        xpReward: achievement.xpReward,
        unlockedAt: Date()
      )
      break
    }
  }

  if let unlocked = newUnlock {
    return .send(.achievementUnlocked(unlocked))
  }
  return .none

case .achievementUnlocked(let achievement):
  // Update the achievement in the list
  if let index = state.achievements.firstIndex(where: { $0.id == achievement.id }) {
    state.achievements[index] = achievement
  }
  state.unlockedAchievementIds.insert(achievement.id)
  state.newlyUnlockedAchievement = achievement
  state.showAchievementUnlock = true
  return .none

case .dismissAchievementUnlock:
  state.showAchievementUnlock = false
  state.newlyUnlockedAchievement = nil
  return .none
```

**MODIFY profileLoaded case to trigger achievement check:**
After the streak animation check (around line 188), add:
```swift
// Check for new achievements
return .send(.checkAchievements)
```

**PATTERN:** Follow existing TCA patterns in the file
**IMPORTS:** Add `import RIZQKit` if not present at top
**GOTCHA:** Achievement check should happen after profile loads, not during
**VALIDATE:** `cd RIZQ-iOS && xcodebuild -scheme RIZQ -destination 'platform=iOS Simulator,name=iPhone 17' build 2>&1 | grep -E "(error:|BUILD SUCCEEDED|BUILD FAILED)"`

---

### Task 9: UPDATE HomeView with New Layout

**File:** `RIZQ-iOS/RIZQ/Features/Home/HomeView.swift`

**REPLACE entire body content with new layout structure:**

```swift
var body: some View {
  NavigationStack {
    ScrollView {
      VStack(spacing: RIZQSpacing.lg) {
        // 1. Header with avatar, greeting, and streak
        headerSection
          .modifier(StaggeredAnimationModifier(index: 0))

        // 2. Weekly Tracker (NEW)
        WeeklyTrackerView(activities: store.weekActivityItems)
          .modifier(StaggeredAnimationModifier(index: 1))

        // 3. Daily Quote (NEW)
        DailyQuoteView(quote: store.dailyQuote)
          .modifier(StaggeredAnimationModifier(index: 2))

        // 4. Daily Adkhar Section (Enhanced)
        dailyAdkharSection
          .modifier(StaggeredAnimationModifier(index: 3))

        // 5. Motivational Progress (NEW)
        MotivationalProgressView(
          habitsCompleted: store.todaysProgress.completed,
          totalHabits: store.todaysProgress.total,
          streak: store.streak,
          nextAchievement: store.nextUnlockableAchievement
        )
        .modifier(StaggeredAnimationModifier(index: 4))

        // 6. Achievement Badges Preview (NEW)
        achievementBadgesSection
          .modifier(StaggeredAnimationModifier(index: 5))

        // 7. Stats Row (XP and Level)
        statsRow
          .modifier(StaggeredAnimationModifier(index: 6))

        // 8. Bottom CTA Buttons
        bottomCTAButtons
          .modifier(StaggeredAnimationModifier(index: 7))
      }
      .padding(.horizontal, RIZQSpacing.lg)
      .padding(.top, RIZQSpacing.lg)
      .padding(.bottom, RIZQSpacing.huge)
    }
    .refreshable {
      store.send(.refreshData)
    }
    .rizqPageBackground()
    .overlay {
      if store.isLoading {
        loadingOverlay
      }
    }
    // Achievement unlock overlay
    .fullScreenCover(isPresented: $store.showAchievementUnlock.sending(\.dismissAchievementUnlock)) {
      if let achievement = store.newlyUnlockedAchievement {
        AchievementUnlockOverlay(achievement: achievement, isPresented: $store.showAchievementUnlock.sending(\.dismissAchievementUnlock))
      }
    }
  }
  .onAppear {
    store.send(.onAppear)
  }
}
```

**ADD new section computed properties:**

```swift
// MARK: - Achievement Badges Section

private var achievementBadgesSection: some View {
  VStack(alignment: .leading, spacing: RIZQSpacing.md) {
    HStack {
      Text("ACHIEVEMENTS")
        .font(.rizqSansSemiBold(.caption))
        .foregroundStyle(Color.rizqTextSecondary)
        .tracking(1)

      Spacer()

      Text("\(store.unlockedAchievementIds.count)/\(store.achievements.count)")
        .font(.rizqMono(.caption))
        .foregroundStyle(Color.rizqTextSecondary)
    }

    // Horizontal scroll of badges
    ScrollView(.horizontal, showsIndicators: false) {
      HStack(spacing: RIZQSpacing.lg) {
        ForEach(store.achievements) { achievement in
          AchievementBadgeView(
            achievement: achievement,
            size: 70,
            showDetails: false
          )
        }
      }
      .padding(.horizontal, RIZQSpacing.xs)
    }
  }
  .padding(RIZQSpacing.lg)
  .background(Color.rizqCard)
  .clipShape(RoundedRectangle(cornerRadius: RIZQRadius.islamic))
  .shadowSoft()
}

// MARK: - Stats Row

private var statsRow: some View {
  HStack(spacing: RIZQSpacing.md) {
    // Circular XP Progress
    CircularXpProgress(
      level: store.level,
      percentage: store.xpProgress.percentage,
      size: 70,
      strokeWidth: 6
    )

    // Progress details
    VStack(alignment: .leading, spacing: RIZQSpacing.xs) {
      Text("Level \(store.level)")
        .font(.rizqDisplayMedium(.headline))
        .foregroundStyle(Color.rizqText)

      Text("\(store.xpProgress.current) / \(store.xpProgress.needed) XP")
        .font(.rizqSans(.caption))
        .foregroundStyle(Color.rizqTextSecondary)

      // Mini progress bar
      GeometryReader { geometry in
        ZStack(alignment: .leading) {
          Capsule()
            .fill(Color.rizqMuted.opacity(0.3))
            .frame(height: 6)

          Capsule()
            .fill(Color.rizqPrimary)
            .frame(width: geometry.size.width * store.xpProgress.percentage, height: 6)
            .animation(.easeOut(duration: 0.8), value: store.xpProgress.percentage)
        }
      }
      .frame(height: 6)
    }

    Spacer()

    // Streak badge
    CompactStreakBadge(streak: store.streak, size: 50)
  }
  .padding(RIZQSpacing.lg)
  .background(Color.rizqCard)
  .clipShape(RoundedRectangle(cornerRadius: RIZQRadius.islamic))
  .shadowSoft()
}
```

**ADD required binding extension at bottom of file:**
```swift
// MARK: - Binding Extension for fullScreenCover

extension Binding where Value == Bool {
  func sending(_ action: HomeFeature.Action) -> Binding<Bool> {
    Binding(
      get: { self.wrappedValue },
      set: { newValue in
        if !newValue {
          // This is handled by the dismiss action
        }
      }
    )
  }
}
```

**PATTERN:** Follow existing section patterns in HomeView
**IMPORTS:** Ensure imports include all new components
**GOTCHA:** fullScreenCover binding needs special handling for TCA
**VALIDATE:** `cd RIZQ-iOS && xcodebuild -scheme RIZQ -destination 'platform=iOS Simulator,name=iPhone 17' build 2>&1 | grep -E "(error:|BUILD SUCCEEDED|BUILD FAILED)"`

---

### Task 10: ADD RIZQKit Exports

**File:** `RIZQ-iOS/RIZQKit/RIZQKit.h` or appropriate export file

If using Swift Package, ensure new models are public and exported.

**VALIDATE:** Verify Achievement and IslamicQuote models are accessible from main app target.

---

### Task 11: UPDATE Previews and Polish

**IMPLEMENT:** Update all preview providers with realistic sample data.

**Files to update:**
- `HomeView.swift` - Add comprehensive previews
- All new component files - Ensure previews work

**VALIDATE:** Run all previews in Xcode to ensure they render correctly.

---

## TESTING STRATEGY

### Unit Tests

**File:** `RIZQ-iOS/RIZQTests/HomeFeatureTests.swift`

Test cases to add:
1. `testAchievementUnlockOnStreakIncrease` - Verify streak achievements unlock
2. `testAchievementUnlockOnLevelUp` - Verify level achievements unlock
3. `testDailyQuoteRotation` - Verify quotes rotate by day
4. `testProgressStateCalculation` - Verify motivational state logic

### Snapshot Tests

**File:** `RIZQ-iOS/RIZQSnapshotTests/HomeViewSnapshotTests.swift`

Snapshot tests for:
1. `testWeeklyTrackerView_allComplete`
2. `testWeeklyTrackerView_partial`
3. `testAchievementBadge_locked`
4. `testAchievementBadge_unlocked`
5. `testDailyQuoteView_withArabic`
6. `testMotivationalProgress_lightDay`
7. `testMotivationalProgress_perfectDay`
8. `testHomeView_newUser`
9. `testHomeView_activeUser`

### Edge Cases

1. New user with no habits or achievements
2. User with all achievements unlocked
3. User with 0 streak
4. User with very long streak (100+ days)
5. Empty week activities array
6. Quote without Arabic text

---

## VALIDATION COMMANDS

Execute every command to ensure zero regressions and 100% feature correctness.

### Level 1: Syntax & Build

```bash
cd RIZQ-iOS && xcodebuild -scheme RIZQ \
  -destination 'platform=iOS Simulator,name=iPhone 17' \
  build 2>&1 | grep -E "(error:|BUILD SUCCEEDED|BUILD FAILED)"
```

### Level 2: Unit Tests

```bash
cd RIZQ-iOS && xcodebuild -scheme RIZQ \
  -destination 'platform=iOS Simulator,name=iPhone 17' \
  test 2>&1 | grep -E "(Test Suite|Executed|error:|FAILED)"
```

### Level 3: SwiftLint (if configured)

```bash
cd RIZQ-iOS && swiftlint lint --path RIZQ/Features/Home --path RIZQ/Views/Components/HomeViews
```

### Level 4: Manual Validation

1. Launch app in simulator
2. Navigate to Home tab
3. Verify weekly tracker shows correct days
4. Verify daily quote displays
5. Verify achievement badges render
6. Verify motivational section responds to habit completion
7. Complete a habit and verify UI updates
8. Test pull-to-refresh
9. Test on both light appearance (app uses warm theme)

---

## ACCEPTANCE CRITERIA

- [ ] Weekly tracker displays 7 days with correct completion indicators
- [ ] Current day is highlighted with pulsing indicator
- [ ] Achievement badges display in hexagonal shape
- [ ] Unlocked achievements have glow effect
- [ ] Locked achievements appear muted
- [ ] Daily quote rotates based on day
- [ ] Arabic text displays RTL when present
- [ ] Motivational section shows appropriate message based on progress
- [ ] "Light Day" state shows when 1+ habit complete
- [ ] "Perfect Day" state shows when all habits complete
- [ ] Achievement unlock overlay triggers on new unlock
- [ ] Celebration particles animate on achievement unlock
- [ ] All animations are smooth (60fps)
- [ ] Pull-to-refresh updates all data
- [ ] New user state renders correctly (empty)
- [ ] Build succeeds with zero warnings
- [ ] All unit tests pass
- [ ] Snapshot tests match expected output

---

## COMPLETION CHECKLIST

- [ ] All tasks completed in order
- [ ] Each task validation passed immediately
- [ ] All validation commands executed successfully
- [ ] Full test suite passes (unit + snapshot)
- [ ] No linting or type checking errors
- [ ] Manual testing confirms feature works
- [ ] Acceptance criteria all met
- [ ] Code reviewed for quality and maintainability

---

## NOTES

### Design Decisions

1. **Warm Theme Adaptation**: The inspiration images showed a dark theme, but RIZQ uses a warm cream/sand palette. All new components use the existing color system for consistency.

2. **Hexagonal Badges**: Chose hexagonal shape for badges (vs circular) to differentiate from existing streak/level circles and add visual interest.

3. **Achievement Categories**: Organized into streak, practice, level, and special to provide variety in milestone types.

4. **Quote Rotation**: Daily rotation based on day-of-year ensures consistency within a day but variety across days.

5. **State-Based Motivation**: The motivational section dynamically adjusts messaging based on completion percentage, providing relevant encouragement at each stage.

### Implementation Risks

1. **Animation Performance**: Multiple animated components may impact scrolling performance on older devices. Profile and optimize if needed.

2. **Achievement Persistence**: Current implementation stores achievements in memory. Consider persisting to Firestore for cross-device sync.

3. **Quote Content**: Sample quotes provided; consider expanding library and potentially fetching from backend.

### Future Enhancements

1. Add share functionality for achievements
2. Add achievement detail sheet with history
3. Add custom achievement notifications
4. Add quote favorites/saving
5. Add badge collections (morning master, evening expert, etc.)
