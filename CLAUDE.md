# RIZQ App - Development Guide

This document contains conventions and patterns that Claude should follow when working on this codebase.

## Project Overview

RIZQ is a gamified Islamic dua (supplication) practice and habit-tracking app. Users practice authentic duas, build daily routines through "Journeys," earn XP, level up, and track streaks. The app features a warm, luxury Islamic aesthetic with smooth animations.

### Core Features
- **Dua Practice**: Practice duas with Arabic text, transliteration, translation, and repetition counter
- **Journeys**: Pre-built themed dua collections (e.g., "Morning Adhkar", "Rizq Path") users subscribe to
- **Daily Adkhar**: Habit system with morning/anytime/evening time slots
- **Gamification**: XP, levels, streaks, and celebratory animations
- **Authentication**: Social login (Google, GitHub) via Better Auth + Neon Auth

## Tech Stack

| Layer | Technology | Notes |
|-------|------------|-------|
| Frontend | React 18 + TypeScript + Vite | SWC for fast builds |
| Styling | Tailwind CSS + shadcn/ui | Warm Islamic color palette |
| Animations | Framer Motion | Rich micro-interactions |
| State (Server) | TanStack React Query v5 | Data fetching and caching |
| State (Client) | React Context + localStorage | Auth state, habit completions |
| Database | Neon PostgreSQL (serverless) | Direct browser queries via `@neondatabase/serverless` |
| Auth | Better Auth + Neon Auth | Managed auth service |
| Testing | Playwright | E2E tests |

## Project Structure

```
src/
├── components/
│   ├── ui/              # shadcn/ui primitives (don't modify)
│   ├── animations/      # Celebration, ripple, checkmark, counter animations
│   ├── dua/             # Dua-specific components (DuaContextView, PracticeContextTabs)
│   ├── habits/          # Habit feature (TodaysHabits, HabitsSummaryCard, AddToAdkharSheet)
│   └── journeys/        # Journey feature (JourneyList, JourneyCard, JourneyPreview)
├── pages/               # Route page components
│   ├── HomePage.tsx         # Dashboard with stats, streak, habits summary
│   ├── LibraryPage.tsx      # Browse all duas
│   ├── DailyAdkharPage.tsx  # Today's habits by time slot
│   ├── PracticePage.tsx     # Dua practice with counter
│   ├── JourneysPage.tsx     # Journey selection
│   ├── JourneyDetailPage.tsx # Single journey view
│   ├── SettingsPage.tsx     # Profile, linked accounts
│   ├── SignInPage.tsx       # Social + email login
│   └── SignUpPage.tsx       # Registration
├── hooks/
│   ├── useDuas.ts           # Fetch duas from DB
│   ├── useJourneys.ts       # Fetch journeys and journey duas
│   ├── useUserHabits.ts     # Habit state (localStorage + journeys)
│   ├── useUserData.ts       # Legacy localStorage profile hooks
│   └── useActivity.ts       # Daily activity tracking (localStorage)
├── contexts/
│   └── AuthContext.tsx      # Auth state, profile, XP, streak management
├── lib/
│   ├── db.ts                # Neon SQL client + DB types
│   ├── auth-client.ts       # Better Auth client + social helpers
│   └── utils.ts             # cn() utility
├── types/
│   ├── dua.ts               # Dua, DuaContext, DuaCategory types
│   └── habit.ts             # Journey, UserHabit, TimeSlot types
├── data/
│   └── duaLibrary.ts        # Fallback/demo dua data
└── App.tsx                  # Router + providers
```

## Code Conventions

### Naming

| Type | Convention | Example |
|------|------------|---------|
| Components | PascalCase | `DuaCard.tsx` |
| Hooks | camelCase with `use` | `useDuas.ts` |
| Types | PascalCase interfaces | `interface Dua` |
| DB Tables | snake_case plural | `user_profiles` |
| DB Columns | snake_case | `created_at` |
| Constants | UPPER_SNAKE | `HABITS_KEY` |
| localStorage keys | snake_case with prefix | `rizq_user_habits` |

### Component Pattern

```typescript
import { motion } from 'framer-motion';
import { cn } from '@/lib/utils';

interface MyComponentProps {
  // Props interface
}

export function MyComponent({ prop }: MyComponentProps) {
  return (
    <motion.div
      initial={{ opacity: 0, y: 20 }}
      animate={{ opacity: 1, y: 0 }}
      className={cn("base-classes", conditionalClass && "conditional")}
    >
      {/* Content */}
    </motion.div>
  );
}
```

### Hook Pattern (Data Fetching)

```typescript
import { useQuery } from '@tanstack/react-query';
import { getSql } from '@/lib/db';

interface DbRow {
  id: number;
  title_en: string;
  // DB columns in snake_case
}

function mapDbToFrontend(row: DbRow): FrontendType {
  return {
    id: row.id,
    title: row.title_en,
    // Map snake_case → camelCase
  };
}

export function useMyData() {
  return useQuery({
    queryKey: ['my-data'],
    queryFn: async () => {
      const sql = getSql();
      const result = await sql`SELECT * FROM my_table`;
      return (result as DbRow[]).map(mapDbToFrontend);
    },
  });
}
```

### Database Query Patterns

```typescript
// Template literal with auto-parameterization (safe from SQL injection)
const result = await sql`
  SELECT * FROM duas
  WHERE category_id = ${categoryId}
`;

// UPSERT pattern for user data
await sql`
  INSERT INTO user_activity (user_id, date, xp_earned)
  VALUES (${userId}::uuid, ${date}::date, ${xp})
  ON CONFLICT (user_id, date)
  DO UPDATE SET xp_earned = user_activity.xp_earned + ${xp}
`;

// Array parameter pattern
const result = await sql`
  SELECT * FROM journeys
  WHERE id = ANY(${journeyIds}::int[])
`;

// UUID casting (required for user_id from auth)
WHERE user_id = ${userId}::uuid
```

## Database Schema

### Core Tables (public schema)

| Table | Purpose | Key Columns |
|-------|---------|-------------|
| `categories` | Dua categories | `id`, `name`, `slug`, `description` |
| `collections` | Content tiers | `id`, `name`, `slug`, `is_premium` |
| `duas` | Main dua content | `id`, `category_id`, `collection_id`, `title_en`, `arabic_text`, `transliteration`, `translation_en`, `source`, `repetitions`, `best_time`, `difficulty`, `rizq_benefit`, `context`, `prophetic_context`, `xp_value` |
| `journeys` | Themed dua collections | `id`, `name`, `slug`, `description`, `emoji`, `estimated_minutes`, `daily_xp`, `is_premium`, `is_featured`, `sort_order` |
| `journey_duas` | Journey-dua mapping | `journey_id`, `dua_id`, `time_slot`, `sort_order` |
| `user_profiles` | User stats | `user_id` (uuid), `display_name`, `streak`, `total_xp`, `level`, `last_active_date` |
| `user_activity` | Daily tracking | `user_id`, `date`, `duas_completed[]`, `xp_earned` |
| `user_progress` | Per-dua progress | `user_id`, `dua_id`, `completed_count`, `last_completed` |

### Auth Tables (neon_auth schema)
Managed by Neon Auth. Key table: `neon_auth.user` with `id`, `email`, `name`, `image`.

### Time Slots
Values: `"morning"` | `"anytime"` | `"evening"` (matches Islamic prayer structure)

### Category Slugs
Values: `"morning"` | `"evening"` | `"rizq"` | `"gratitude"`

## Design System

### Color Palette (CSS Variables)

```css
/* Light Theme */
--background: 38 35% 96%;      /* Warm Cream #F5EFE7 */
--foreground: 24 40% 18%;      /* Deep Charcoal */
--primary: 30 52% 56%;         /* Warm Sand #D4A574 */
--accent: 24 50% 30%;          /* Deep Mocha #6B4423 */
--secondary: 36 30% 91%;       /* Soft Sand */
--muted: 35 18% 88%;           /* Warm Gray */
--success: 158 35% 42%;        /* Muted Teal */
--card: 40 45% 98%;            /* Warm White */

/* Custom Tokens */
--xp-bar: 30 52% 56%;          /* Primary sand */
--streak-glow: 38 75% 58%;     /* Bright gold */
--level-badge: 24 50% 30%;     /* Mocha */
```

### Named Color Utilities
```typescript
// Direct color classes available in tailwind.config.ts
sand: { warm: '#D4A574', light: '#E6C79C', deep: '#A67C52' }
mocha: { DEFAULT: '#6B4423', deep: '#2C2416' }
cream: { DEFAULT: '#F5EFE7', warm: '#FFFCF7' }
gold: { soft: '#E6C79C', bright: '#FFEBB3' }
teal: { muted: '#5B8A8A', success: '#6B9B7C' }
```

### Typography
```css
font-sans: 'Crimson Pro'     /* Body text - elegant serif */
font-display: 'Playfair Display'  /* Headings - luxury feel */
font-arabic: 'Amiri'         /* Arabic text */
font-mono: 'JetBrains Mono'  /* Numbers, counters */
```

### Border Radius
- `rounded-islamic` (20px) - Cards, major containers
- `rounded-btn` (16px) - Buttons
- `rounded-lg` (12px) - Default

### Shadows
```css
shadow-soft        /* Subtle elevation */
shadow-elevated    /* Card hover state */
shadow-glow-primary /* Primary button glow */
shadow-glow-streak /* Streak badge glow */
shadow-inner-glow  /* Input inner glow */
```

### Animation Pattern

```typescript
// Container with staggered children
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

// Usage
<motion.div variants={containerVariants} initial="hidden" animate="visible">
  <motion.div variants={itemVariants}>Item 1</motion.div>
  <motion.div variants={itemVariants}>Item 2</motion.div>
</motion.div>
```

### Interactive States

```typescript
// Card hover
<motion.div whileHover={{ y: -2 }} whileTap={{ scale: 0.98 }}>

// Button
<motion.button whileHover={{ scale: 1.02 }} whileTap={{ scale: 0.98 }}>
```

### Available Animation Components

| Component | Purpose |
|-----------|---------|
| `CelebrationParticles` | Floating particles on completion |
| `CelebrationOverlay` | Full-screen celebration |
| `MiniCelebration` | Smaller inline celebration |
| `RippleEffect` | Tap ripple feedback |
| `AnimatedCheckmark` | Completion checkmark with draw animation |
| `AnimatedCounter` | Number counting animation |
| `NumberPop` | XP pop animation |

### Gamification Components

| Component | Purpose |
|-----------|---------|
| `StreakBadge` | Flame icon with streak count, animated glow |
| `LevelBadge` | Star + level number |
| `XpProgressBar` | Linear XP progress with shimmer |
| `CircularXpProgress` | Circular SVG progress ring |
| `XpEarnedBadge` | "+X XP" animated badge |

## Key Files Reference

| Purpose | File |
|---------|------|
| Router + Providers | `src/App.tsx` |
| Database Client | `src/lib/db.ts` |
| Auth Client | `src/lib/auth-client.ts` |
| Auth Context | `src/contexts/AuthContext.tsx` |
| Dua Types | `src/types/dua.ts` |
| Habit Types | `src/types/habit.ts` |
| Design Tokens | `tailwind.config.ts` |
| CSS Variables | `src/index.css` |

## Required Patterns

### Pages Must Have
- Bottom padding: `pb-24` (for nav bar)
- Loading state with `<Loader2 className="animate-spin" />`
- Empty state component when no data
- Framer Motion entry animation with `containerVariants`/`itemVariants`
- Background pattern: `<div className="fixed inset-0 islamic-pattern opacity-40 pointer-events-none" />`

### Protected Routes

```typescript
<Route
  path="/my-page"
  element={
    <ProtectedRoute>
      <MyPage />
    </ProtectedRoute>
  }
/>
```

### Arabic Text

```typescript
<p
  className="font-arabic text-xl leading-[2.2]"
  dir="rtl"
>
  {arabicText}
</p>
```

### Category Badges
Use CSS classes: `badge-morning`, `badge-evening`, `badge-rizq`, `badge-gratitude`

### Time Slot Icons
```typescript
import { Sun, Clock, Moon } from "lucide-react";
// morning → Sun, anytime → Clock, evening → Moon
```

## State Management

### Auth State (AuthContext)
- `user`: Auth user from Better Auth (id, email, name, image)
- `profile`: User profile from DB (streak, totalXp, level)
- `addXp(amount)`: Updates XP, level, streak, last_active_date
- `refreshProfile()`: Re-fetches profile from DB

### Habit State (useUserHabits)
localStorage-based with React Query integration:
- `activeJourneyIds`: Array of subscribed journey IDs
- `customHabits`: User-added custom habits
- `habitCompletions`: Daily completion records
- Combines journey duas + custom habits into `todaysHabits`

### Local Storage Keys
- `rizq_user_habits` - Habit storage
- `rizq_daily_activity` - Daily activity (legacy)
- `rizq_user_profile` - Profile (legacy, now in DB)
- `rizq_welcome_shown` - Welcome modal flag
- `lastUsedProvider` - Last OAuth provider used

## XP & Level System

```typescript
// Level threshold formula: 50 * level^2 + 50 * level
// Level 1: 0-100 XP, Level 2: 100-300 XP, Level 3: 300-600 XP, etc.
const calculateLevel = (xp: number): number => {
  let level = 1;
  while (50 * level * level + 50 * level <= xp) {
    level++;
  }
  return level;
};
```

## Environment Variables

Required in `.env`:
```
VITE_DATABASE_URL=postgresql://...  # Neon connection string
VITE_AUTH_URL=https://...           # Neon Auth endpoint
```

## Don't

- Don't modify files in `src/components/ui/` (shadcn/ui primitives)
- Don't hardcode colors (use CSS variables or Tailwind classes)
- Don't skip loading/empty states
- Don't forget `pb-24` on pages (nav bar clearance)
- Don't use `any` types without proper mapping functions
- Don't commit console.log statements
- Don't query neon_auth tables directly (except for profile picture sync)
- Don't store passwords or sensitive data in localStorage

## Do

- Use Framer Motion for all animations
- Use `cn()` for conditional class merging
- Map DB snake_case to frontend camelCase with explicit functions
- Use `::uuid` casting for user IDs in SQL
- Use template literals for SQL (auto-parameterized)
- Provide prophetic context for duas when available
- Test on mobile viewport (app is mobile-first)
