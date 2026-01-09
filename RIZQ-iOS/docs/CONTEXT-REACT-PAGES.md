# React Pages Reference

This document details each React page's structure, data requirements, and key components for iOS implementation reference.

---

## HomePage.tsx

### Layout Structure

```
┌─────────────────────────────┐
│ Greeting + Streak Badge     │
├─────────────────────────────┤
│ ┌─────────────────────────┐ │
│ │   XP Ring + Level Card  │ │
│ │   ○○○   Level 5         │ │
│ │   350/600 XP            │ │
│ └─────────────────────────┘ │
├─────────────────────────────┤
│ Week Calendar (7 days)      │
│ [M][T][W][T][F][S][S]       │
├─────────────────────────────┤
│ Today's Habits Summary      │
│ 3/5 complete • 75 XP        │
│ [Continue Practice →]       │
├─────────────────────────────┤
│ Motivational Message        │
└─────────────────────────────┘
```

### Data Requirements

```typescript
// From AuthContext
user: { id, name, email, image }
profile: { streak, totalXp, level, lastActiveDate }

// From useDailyActivity
todayActivity: { duasCompleted[], xpEarned }
weekActivities: (DailyActivity | null)[]  // Last 7 days

// Computed
xpProgress: number  // 0-1 progress in current level
```

### Key Components

- `StreakBadge` - Flame icon with count and glow animation
- `CircularXpProgress` - SVG ring with level display
- `XpProgressBar` - Linear bar with shimmer effect
- `WeekCalendar` - 7-day activity indicator strip
- `HabitsSummaryCard` - Today's completion stats

---

## LibraryPage.tsx

### Layout Structure

```
┌─────────────────────────────┐
│ Header: "Dua Library"       │
├─────────────────────────────┤
│ [🔍 Search duas...]         │
├─────────────────────────────┤
│ Category Pills              │
│ [All][🌅Morning][🌙Eve]...  │
├─────────────────────────────┤
│ ┌─────────────────────────┐ │
│ │ Dua Card                │ │
│ │ Title • Category Badge  │ │
│ │ Arabic preview...       │ │
│ │ [+Add] [Practice →]     │ │
│ └─────────────────────────┘ │
│ ┌─────────────────────────┐ │
│ │ Dua Card...             │ │
│ └─────────────────────────┘ │
└─────────────────────────────┘
```

### Data Requirements

```typescript
// From useDuas()
duas: Dua[]

// From useUserProgress()
completedToday: Set<duaId>

// From useUserHabits()
habitsInclude: (duaId) => boolean

// Local state
searchQuery: string
selectedCategory: CategorySlug | null
```

### Key Components

- `SearchInput` - Debounced text input (300ms)
- `CategoryPill` - Toggleable filter chip
- `DuaCard` - Card with title, preview, actions
- `AddToAdkharSheet` - Bottom sheet for time slot selection

### Filter Logic

```typescript
const filteredDuas = duas.filter(dua => {
  const matchesSearch = !searchQuery ||
    dua.title.toLowerCase().includes(searchQuery.toLowerCase()) ||
    dua.transliteration?.toLowerCase().includes(searchQuery.toLowerCase())

  const matchesCategory = !selectedCategory ||
    dua.category === selectedCategory

  return matchesSearch && matchesCategory
})
```

---

## JourneysPage.tsx

### Layout Structure

```
┌─────────────────────────────┐
│ Header: "Journeys"          │
├─────────────────────────────┤
│ Featured Section            │
│ ┌───────┐ ┌───────┐         │
│ │ 💎    │ │ 🌅    │  →      │
│ │ Rizq  │ │Morning│         │
│ └───────┘ └───────┘         │
├─────────────────────────────┤
│ Your Journeys (if any)      │
│ ┌─────────────────────────┐ │
│ │ Active Journey Card     │ │
│ └─────────────────────────┘ │
├─────────────────────────────┤
│ Explore                     │
│ ┌─────────────────────────┐ │
│ │ Journey Card            │ │
│ │ Emoji • Name • Stats    │ │
│ │ 15 min • 270 XP/day     │ │
│ └─────────────────────────┘ │
└─────────────────────────────┘
```

### Data Requirements

```typescript
// From useJourneys()
journeys: Journey[]

// From useUserHabits()
activeJourneyIds: number[]

// Computed
featuredJourneys: journeys.filter(j => j.isFeatured)
activeJourneys: journeys.filter(j => activeJourneyIds.includes(j.id))
regularJourneys: journeys.filter(j => !j.isFeatured)
```

### Key Components

- `FeaturedJourneyCard` - Horizontal scroll card
- `JourneyCard` - Standard list card
- `JourneyIcon` - Emoji or image display

---

## JourneyDetailPage.tsx

### Layout Structure

```
┌─────────────────────────────┐
│ [←] Journey Name            │
├─────────────────────────────┤
│        💎                   │
│    Rizq Seeker              │
│ "Description text..."       │
├─────────────────────────────┤
│ ⏱15min  ⭐270XP  📿8duas    │
├─────────────────────────────┤
│ Morning Duas                │
│ ├─ Dua 1 • 10XP • 3x        │
│ ├─ Dua 2 • 15XP • 1x        │
│ Anytime Duas                │
│ ├─ Dua 3 • 25XP • 7x        │
│ Evening Duas                │
│ └─ Dua 4 • 20XP • 3x        │
├─────────────────────────────┤
│ [   Add to Daily Adkhar   ] │
│        or                   │
│ [Remove from Daily Adkhar]  │
└─────────────────────────────┘
```

### Data Requirements

```typescript
// From useJourneyBySlugWithDuas(slug)
journey: Journey
journeyDuas: JourneyDua[]

// From useUserHabits()
isSubscribed: boolean = activeJourneyIds.includes(journey.id)

// Computed
duasByTimeSlot: { morning: [], anytime: [], evening: [] }
totalXp: sum of all dua xpValues
totalDuas: journeyDuas.length
```

### Key Components

- `JourneyHeader` - Emoji, name, description
- `StatsRow` - Minutes, XP, dua count
- `TimeSlotSection` - Grouped duas list
- `DuaListItem` - Title, XP, repetitions

---

## DailyAdkharPage.tsx

### Layout Structure

```
┌─────────────────────────────┐
│ Daily Adkhar                │
├─────────────────────────────┤
│ Today's Progress            │
│ ████████░░ 80%              │
│ 4/5 complete • 85/100 XP    │
├─────────────────────────────┤
│ 🌅 Morning                  │
│ ┌─────────────────────────┐ │
│ │ ☑ Dua 1 (completed)     │ │
│ │ ☐ Dua 2 (tap to start)  │ │
│ └─────────────────────────┘ │
├─────────────────────────────┤
│ ⏰ Anytime                  │
│ ┌─────────────────────────┐ │
│ │ ☑ Dua 3                 │ │
│ └─────────────────────────┘ │
├─────────────────────────────┤
│ 🌙 Evening                  │
│ ┌─────────────────────────┐ │
│ │ ☐ Dua 4                 │ │
│ └─────────────────────────┘ │
└─────────────────────────────┘
```

### Data Requirements

```typescript
// From useUserHabits()
todaysHabits: HabitWithDua[]
groupedHabits: {
  morning: HabitWithDua[],
  anytime: HabitWithDua[],
  evening: HabitWithDua[]
}
progress: {
  total: number,
  completed: number,
  percentage: number,
  totalXp: number,
  earnedXp: number
}
nextUncompletedHabit: HabitWithDua | null

// Methods
markHabitCompleted(duaId)
isHabitCompletedToday(duaId)
```

### Key Components

- `HabitProgressBar` - Overall completion bar
- `HabitTimeSlotSection` - Grouped section with header
- `HabitItem` - Checkable habit row
- `QuickPracticeSheet` - Bottom sheet for practice
- `CelebrationParticles` - When all complete

---

## PracticePage.tsx

### Layout Structure

```
┌─────────────────────────────┐
│ [←]  Dua Title       [👁]   │
├─────────────────────────────┤
│ ┌─────────────────────────┐ │
│ │                         │ │
│ │  اللَّهُ لَا إِلَٰهَ إِلَّا هُوَ    │ │
│ │  Allahu la ilaha...     │ │
│ │  "Allah, there is no..."│ │
│ │                         │ │
│ │     [TAP TO COUNT]      │ │
│ │                         │ │
│ └─────────────────────────┘ │
├─────────────────────────────┤
│        ┌─────┐              │
│        │  3  │              │
│        │ /7  │              │
│        └─────┘              │
├─────────────────────────────┤
│ [Practice] [Context]        │
├─────────────────────────────┤
│ [Reset]        [Next →]     │
└─────────────────────────────┘
```

### Data Requirements

```typescript
// From route params or props
dua: Dua
duaId: string
categoryFilter?: string

// Local state
tapCount: number
showTransliteration: boolean
activeTab: "practice" | "context"
isCompleted: boolean
showCelebration: boolean
```

### Key Components

- `TapCard` - Main practice area with ripple effect
- `AnimatedCounter` - Number with progress ring
- `PracticeContextTabs` - Tab switcher
- `DuaContextView` - Source, benefits, prophetic context
- `CelebrationOverlay` - Full screen celebration

### Tap Flow

```typescript
const handleTap = () => {
  setTapCount(prev => prev + 1)
  haptics.impact()

  if (tapCount + 1 >= dua.repetitions) {
    // Mark complete
    markActivityCompleted(dua.id, dua.xpValue)
    markProgressCompleted(dua.id)
    markHabitCompleted(dua.id)
    addXp(dua.xpValue)

    // Show celebration
    setShowCelebration(true)
  }
}
```

---

## SettingsPage.tsx

### Layout Structure

```
┌─────────────────────────────┐
│ Settings                    │
├─────────────────────────────┤
│ Profile                     │
│ ┌─────────────────────────┐ │
│ │ [Avatar] Display Name   │ │
│ │          email@...      │ │
│ └─────────────────────────┘ │
├─────────────────────────────┤
│ Linked Accounts             │
│ ┌─────────────────────────┐ │
│ │ Google    [Linked ✓]    │ │
│ │ Apple     [Link]        │ │
│ └─────────────────────────┘ │
├─────────────────────────────┤
│ [Sign Out]                  │
└─────────────────────────────┘
```

### Data Requirements

```typescript
// From AuthContext
user: { id, name, email, image }
profile: UserProfile

// From auth service
linkedAccounts: { google: boolean, apple: boolean, github: boolean }
```

### Key Components

- `ProfileCard` - Avatar, name, email
- `LinkedAccountRow` - Provider with link/unlink action
- `SignOutButton` - Confirmation dialog

---

## Animation Patterns

### Page Transitions

```typescript
const containerVariants = {
  hidden: { opacity: 0 },
  visible: {
    opacity: 1,
    transition: {
      staggerChildren: 0.08,
      delayChildren: 0.1,
    },
  },
}

const itemVariants = {
  hidden: { opacity: 0, y: 20 },
  visible: {
    opacity: 1,
    y: 0,
    transition: {
      duration: 0.4,
      ease: [0.25, 0.46, 0.45, 0.94],
    },
  },
}
```

### Card Hover

```typescript
<motion.div
  whileHover={{ y: -2, scale: 1.01 }}
  whileTap={{ scale: 0.98 }}
>
```

### Counter Animation

```typescript
<motion.span
  key={count}
  initial={{ scale: 1.5, opacity: 0 }}
  animate={{ scale: 1, opacity: 1 }}
  transition={{ type: "spring", stiffness: 500 }}
>
  {count}
</motion.span>
```

---

## Responsive Patterns

All pages use:

```css
max-width: 448px;  /* max-w-md */
margin: 0 auto;
padding: 0 16px;
padding-bottom: 96px;  /* pb-24 for nav */
```

Mobile-first design with no breakpoint variations needed for iOS.
