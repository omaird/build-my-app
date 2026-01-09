# RIZQ - Product Requirements Document

## 1. Executive Summary

RIZQ is a gamified Islamic supplication (dua) practice and spiritual habit-tracking app designed to help Muslims build consistent daily worship routines. The app combines authentic duas with modern gamification mechanics—XP, levels, streaks, and celebratory animations—to make daily spiritual practice engaging and rewarding.

The core value proposition is making daily Islamic devotion accessible, authentic, and habit-forming. Users practice duas with full Arabic text, transliteration, and translation, subscribe to themed "Journeys" (curated dua collections), track their daily Adkhar (remembrances) by time of day, and watch their spiritual commitment grow through visible progress metrics.

**Product Vision:** Become the go-to digital companion for Muslims seeking to strengthen their daily connection with Allah through authentic, consistent dua practice.

**Target Platforms:** Web (React), iOS (SwiftUI with TCA)

---

## 2. Mission

**Mission Statement:** Help Muslims build lasting spiritual habits by making dua practice accessible, authentic, and rewarding through thoughtful design and gentle gamification.

### Core Principles

1. **Authenticity First** — All duas sourced from Quran and authenticated Hadith with proper attribution
2. **Habit Formation** — Design for daily consistency over occasional intensity
3. **Gentle Gamification** — Motivate without trivializing worship; streaks and XP as encouragement, not competition
4. **Beautiful Experience** — Warm, luxury Islamic aesthetic that honors the spiritual nature of the content
5. **Accessibility** — Arabic text with transliteration and translation for all skill levels
6. **Privacy Respected** — User spiritual data treated with appropriate sensitivity

---

## 3. Target Users

### Primary Persona: The Aspiring Consistent Muslim

- **Who:** Muslims (18-45) who want to strengthen their daily worship but struggle with consistency
- **Spiritual Level:** Knows basic prayers, wants to go deeper with duas and Adkhar
- **Tech Comfort:** Daily smartphone user, familiar with habit-tracking and wellness apps
- **Goals:**
  - Build a consistent morning and evening Adkhar routine
  - Learn new duas with proper pronunciation
  - Track spiritual progress without feeling overwhelmed
  - Connect duas to daily situations (rizq/provision, gratitude, protection)
- **Pain Points:**
  - Existing dua apps feel utilitarian or outdated
  - Hard to remember which duas to say when
  - No sense of progress or motivation to continue
  - Guilt when streaks break or habits lapse

### Secondary Persona: The Returning Muslim

- **Who:** Muslims reconnecting with their faith after a period of distance
- **Needs:** Gentle onboarding, no assumptions about prior knowledge, encouragement over judgment
- **Key Feature:** Journeys that guide them through foundational duas

### Secondary Persona: The Parent

- **Who:** Parents teaching children Islamic practices
- **Needs:** Beautiful presentation that appeals to younger users, gamification that motivates kids
- **Key Feature:** Family-friendly achievement system

---

## 4. Product Scope

### In Scope (Current)

**Core Functionality**
- ✅ Dua library with Arabic, transliteration, translation, and source attribution
- ✅ Prophetic context and benefits for duas
- ✅ Practice mode with repetition counter (tap to increment, configurable target)
- ✅ Journeys: themed dua collections users subscribe to (Morning Adhkar, Rizq Path, etc.)
- ✅ Daily Adkhar: habits organized by time slot (morning/anytime/evening)
- ✅ Quick Practice: bottom sheet for practicing a dua without navigation
- ✅ Gamification: XP system, levels, current streak, streak restoration
- ✅ User authentication (Firebase Auth with Google/GitHub social login)
- ✅ Admin panel: full CRUD for duas, journeys, categories, collections, users
- ✅ Responsive web app with warm Islamic aesthetic

**iOS App**
- ✅ Native SwiftUI app with The Composable Architecture (TCA)
- ✅ Feature parity with web for core dua practice
- ✅ iOS-native haptics and animations
- ✅ Widget support for daily reminders

**Technical**
- ✅ React 18 + TypeScript + Vite (Web)
- ✅ SwiftUI + TCA (iOS)
- ✅ Neon PostgreSQL (serverless database)
- ✅ Firebase Authentication
- ✅ TanStack React Query for server state
- ✅ Framer Motion animations
- ✅ Tailwind CSS + shadcn/ui components

### Out of Scope (Future)

**Deferred Features**
- ❌ Audio recitation of duas
- ❌ Prayer times integration
- ❌ Qibla compass
- ❌ Social features (friends, leaderboards)
- ❌ Push notifications / reminders
- ❌ Offline mode with sync
- ❌ Android app
- ❌ Subscription/premium tiers
- ❌ User-created custom duas
- ❌ Community-submitted content
- ❌ Apple Watch app
- ❌ Multiple language support beyond English

---

## 5. User Stories

### Onboarding & Discovery

1. **As a new user, I want to see what the app offers before signing up, so that I can decide if it's right for me.**
   - Landing page with feature showcase, sample journeys, and testimonials

2. **As a new user, I want to sign up quickly with my Google account, so that I can start practicing immediately.**
   - Social login with Google/GitHub, minimal form fields

3. **As a new user, I want to receive a welcome guide, so that I understand how to use journeys and daily adkhar.**
   - Welcome modal explaining core concepts after first login

### Daily Practice

4. **As a user, I want to see my daily habits organized by time of day, so that I know what to practice when.**
   - Morning/Anytime/Evening sections on Daily Adkhar page

5. **As a user, I want to practice a dua with a tap counter, so that I can track my repetitions easily.**
   - Practice page with large counter, Arabic text, and progress indicator

6. **As a user, I want to quickly practice a dua without leaving my current page, so that practice is frictionless.**
   - Quick Practice bottom sheet accessible from any dua card

7. **As a user, I want to see the Arabic text with transliteration, so that I can learn proper pronunciation.**
   - All duas display: Arabic (RTL), transliteration (Latin), translation (English)

8. **As a user, I want to understand the prophetic context of a dua, so that my practice is more meaningful.**
   - Dua detail view with source, context, and benefits sections

### Journeys & Habits

9. **As a user, I want to browse themed dua collections (Journeys), so that I can choose a focus area.**
   - Journeys page with cards showing name, emoji, estimated time, XP potential

10. **As a user, I want to subscribe to a Journey, so that its duas appear in my daily habits.**
    - Subscribe button adds journey duas to appropriate time slots

11. **As a user, I want to add a single dua to my daily habits without subscribing to a full journey.**
    - "Add to Adkhar" action on any dua card

12. **As a user, I want to see my progress through a Journey, so that I feel accomplishment.**
    - Journey detail page with completion percentage and dua checklist

### Gamification & Progress

13. **As a user, I want to see my current streak, so that I'm motivated to maintain it.**
    - Prominent streak badge on home page with flame icon

14. **As a user, I want to earn XP when I complete duas, so that I feel rewarded for practice.**
    - XP earned animation on completion, XP value varies by dua difficulty

15. **As a user, I want to see my level and progress to next level, so that I have a long-term goal.**
    - Level badge and XP progress bar on home/settings pages

16. **As a user, I want to see a celebration animation when I complete a milestone, so that achievements feel special.**
    - Particle effects and full-screen celebration on level up, journey completion

### Library & Exploration

17. **As a user, I want to browse all available duas by category, so that I can discover new ones.**
    - Library page with category filters (Morning, Evening, Rizq, Gratitude)

18. **As a user, I want to search for duas by topic or phrase, so that I can find specific ones.**
    - Search functionality in library (future enhancement)

### Settings & Profile

19. **As a user, I want to view my profile and stats, so that I can see my overall progress.**
    - Settings page with total XP, level, streak, account info

20. **As a user, I want to link additional social accounts, so that I can sign in multiple ways.**
    - Account linking for Google/GitHub in settings

---

## 6. Core Architecture

### High-Level Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                         Clients                                  │
├─────────────────────────┬───────────────────────────────────────┤
│   React Web App         │         iOS App (SwiftUI + TCA)       │
│   (Vite + TypeScript)   │         (Swift + Composable Arch)     │
│   Port 5173             │         Native iOS                     │
└───────────┬─────────────┴──────────────────┬────────────────────┘
            │                                 │
            ▼                                 ▼
┌───────────────────────────────────────────────────────────────────┐
│                    Firebase Authentication                         │
│                    (Google, GitHub OAuth)                          │
└───────────────────────────────────┬───────────────────────────────┘
                                    │
                                    ▼
┌───────────────────────────────────────────────────────────────────┐
│                    Neon PostgreSQL (Serverless)                    │
│                    Direct browser queries via                      │
│                    @neondatabase/serverless                        │
└───────────────────────────────────────────────────────────────────┘
```

### Web Project Structure

```
src/
├── components/
│   ├── ui/              # shadcn/ui primitives (don't modify)
│   ├── admin/           # Admin panel components
│   ├── animations/      # Celebration, ripple, sparkles
│   ├── dua/             # Dua-specific components
│   ├── habits/          # Habit/Adkhar components
│   ├── journeys/        # Journey components
│   ├── ProtectedRoute.tsx
│   └── AdminRoute.tsx
├── pages/
│   ├── admin/           # Admin CRUD pages
│   ├── LandingPage.tsx  # Public marketing page
│   ├── HomePage.tsx     # Authenticated dashboard
│   ├── LibraryPage.tsx  # Dua library
│   ├── DailyAdkharPage.tsx
│   ├── PracticePage.tsx
│   ├── JourneysPage.tsx
│   ├── JourneyDetailPage.tsx
│   └── SettingsPage.tsx
├── hooks/
│   ├── admin/           # Admin CRUD hooks
│   ├── useDuas.ts
│   ├── useJourneys.ts
│   └── useUserHabits.ts
├── contexts/
│   └── AuthContext.tsx
├── lib/
│   ├── db.ts            # Neon SQL client
│   ├── auth-client.ts   # Firebase Auth client
│   └── utils.ts
├── types/
│   ├── dua.ts
│   ├── habit.ts
│   └── admin.ts
└── App.tsx
```

### iOS Project Structure

```
RIZQ-iOS/
├── RIZQ/
│   ├── App/
│   │   ├── RIZQApp.swift
│   │   ├── AppFeature.swift    # Root TCA feature
│   │   └── AppView.swift
│   ├── Features/
│   │   ├── Auth/
│   │   ├── Adkhar/
│   │   ├── Journeys/
│   │   ├── Practice/
│   │   ├── Settings/
│   │   └── Admin/
│   ├── Views/Components/
│   │   ├── Animations/
│   │   ├── GamificationViews/
│   │   └── JourneyViews/
│   └── Dependencies/
├── RIZQKit/
│   ├── Models/
│   ├── Services/
│   │   ├── API/
│   │   └── Auth/
│   └── Dependencies.swift
├── RIZQTests/
├── RIZQSnapshotTests/
└── RIZQWidget/
```

### Key Design Patterns

- **Feature-Based Architecture** — Both web and iOS organize code by feature domain
- **TCA (iOS)** — The Composable Architecture for unidirectional data flow
- **React Query (Web)** — Server state management with caching and invalidation
- **Snake-to-Camel Mapping** — Explicit functions convert DB snake_case to frontend camelCase
- **Component Composition** — Small, focused components composed into features
- **Framer Motion Variants** — Consistent animation patterns with containerVariants/itemVariants

---

## 7. Features

### 7.1 Authentication

**Purpose:** Secure user identity with minimal friction

**Methods:**
- Google OAuth (primary)
- GitHub OAuth (developer-friendly)
- Email/password (future)

**Key Features:**
- Firebase Authentication handles OAuth flow
- User profile synced to Neon database
- Last used provider remembered for returning users
- Account linking for multiple providers

### 7.2 Dua Practice

**Purpose:** Core value—practicing duas with proper form

**Components:**
- Arabic text (RTL, Amiri font)
- Transliteration (Latin script)
- English translation
- Source attribution (Quran/Hadith reference)
- Prophetic context (when/why revealed)
- Benefits/virtues of the dua

**Practice Mode:**
- Large tap target for counter increment
- Progress circle showing repetitions completed
- XP earned displayed on completion
- Quick practice bottom sheet for in-context use

### 7.3 Journeys

**Purpose:** Curated dua collections for guided spiritual growth

**Examples:**
- Morning Adhkar (Essential morning remembrances)
- Evening Adhkar (Essential evening remembrances)
- Rizq Path (Duas for provision and sustenance)
- Gratitude Journey (Duas of thankfulness)

**Features:**
- Subscribe to add all journey duas to daily habits
- Time slot assignment (morning/anytime/evening)
- Progress tracking per journey
- Estimated daily time commitment
- Daily XP potential displayed

### 7.4 Daily Adkhar

**Purpose:** Habit system for consistent daily practice

**Time Slots:**
- **Morning** (Fajr to Dhuhr) — Morning adhkar
- **Anytime** — Duas for general situations
- **Evening** (Maghrib to Isha) — Evening adhkar

**Features:**
- Grouped display by time slot
- Completion toggle per dua
- Progress bar for each slot
- Quick practice without full navigation
- Custom habit addition (single duas)

### 7.5 Gamification

**Purpose:** Motivate consistency through visible progress

**XP System:**
- XP earned per dua completion (varies by difficulty: 10-50 XP)
- Bonus XP for completing all daily habits
- Streak bonus multiplier (future)

**Levels:**
- Formula: `50 * level² + 50 * level` XP per level
- Level 1: 0-100 XP
- Level 2: 100-300 XP
- Level 3: 300-600 XP
- Visual level badge with star icon

**Streaks:**
- Current streak (consecutive active days)
- Streak preserved if at least one dua completed
- Flame icon with animated glow
- Streak restoration (future: via ad or payment)

**Celebrations:**
- Particle effects on completion
- Full-screen celebration on milestones
- Confetti on level up
- Checkmark animation with haptics (iOS)

### 7.6 Library

**Purpose:** Browse and discover all available duas

**Organization:**
- Categories: Morning, Evening, Rizq, Gratitude
- Collections: Free, Premium (future)
- Sort by: Popular, Recent, Alphabetical

**Actions:**
- View full dua details
- Add to daily Adkhar
- Quick practice
- Share (future)

### 7.7 Admin Panel

**Purpose:** Content management for administrators

**Capabilities:**
- Full CRUD for Duas (with all fields)
- Full CRUD for Journeys (with dua assignment)
- Category management
- Collection management
- User management (view, disable)
- Dashboard with usage stats

---

## 8. Technology Stack

### Web Frontend

| Component | Technology | Version |
|-----------|------------|---------|
| Framework | React | 18.x |
| Language | TypeScript | 5.x |
| Build Tool | Vite | 5.x (SWC) |
| Styling | Tailwind CSS | 3.x |
| Components | shadcn/ui | Latest |
| Animations | Framer Motion | 10.x |
| Server State | TanStack Query | 5.x |
| Routing | React Router | 6.x |
| Date Utils | date-fns | 3.x |
| Icons | Lucide React | Latest |

### iOS App

| Component | Technology | Version |
|-----------|------------|---------|
| Framework | SwiftUI | iOS 17+ |
| Architecture | TCA (Composable) | 1.x |
| Networking | Custom APIClient | - |
| Testing | XCTest + Snapshots | - |
| Widgets | WidgetKit | iOS 17+ |

### Backend Services

| Component | Technology | Notes |
|-----------|------------|-------|
| Database | Neon PostgreSQL | Serverless, direct browser queries |
| Auth | Firebase Authentication | Google, GitHub OAuth |
| Hosting | Vercel (Web) | Edge functions compatible |
| iOS Backend | Same Neon DB | Via RIZQKit APIClient |

### Design System

| Element | Specification |
|---------|---------------|
| Primary Font | Crimson Pro (body) |
| Display Font | Playfair Display (headings) |
| Arabic Font | Amiri |
| Mono Font | JetBrains Mono (counters) |
| Primary Color | Warm Sand #D4A574 |
| Accent Color | Deep Mocha #6B4423 |
| Background | Warm Cream #F5EFE7 |
| Border Radius | 20px (cards), 16px (buttons) |

---

## 9. Database Schema

### Core Tables

```sql
-- Categories for organizing duas
CREATE TABLE categories (
    id SERIAL PRIMARY KEY,
    name TEXT NOT NULL,
    slug TEXT NOT NULL UNIQUE,  -- 'morning', 'evening', 'rizq', 'gratitude'
    description TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Collections for content tiers
CREATE TABLE collections (
    id SERIAL PRIMARY KEY,
    name TEXT NOT NULL,
    slug TEXT NOT NULL UNIQUE,
    is_premium BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Main dua content
CREATE TABLE duas (
    id SERIAL PRIMARY KEY,
    category_id INTEGER REFERENCES categories(id),
    collection_id INTEGER REFERENCES collections(id),
    title_en TEXT NOT NULL,
    arabic_text TEXT NOT NULL,
    transliteration TEXT,
    translation_en TEXT NOT NULL,
    source TEXT,              -- 'Quran 2:201', 'Sahih Bukhari'
    repetitions INTEGER DEFAULT 1,
    best_time TEXT,           -- 'morning', 'evening', 'anytime'
    difficulty TEXT DEFAULT 'easy',  -- 'easy', 'medium', 'hard'
    rizq_benefit TEXT,        -- Specific rizq-related benefit
    context TEXT,             -- When/how to use this dua
    prophetic_context TEXT,   -- Historical/prophetic background
    xp_value INTEGER DEFAULT 10,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Themed dua collections
CREATE TABLE journeys (
    id SERIAL PRIMARY KEY,
    name TEXT NOT NULL,
    slug TEXT NOT NULL UNIQUE,
    description TEXT,
    emoji TEXT,               -- '🌅', '🌙', '💰'
    estimated_minutes INTEGER DEFAULT 5,
    daily_xp INTEGER DEFAULT 50,
    is_premium BOOLEAN DEFAULT FALSE,
    is_featured BOOLEAN DEFAULT FALSE,
    sort_order INTEGER DEFAULT 0,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Journey-dua mapping
CREATE TABLE journey_duas (
    id SERIAL PRIMARY KEY,
    journey_id INTEGER REFERENCES journeys(id) ON DELETE CASCADE,
    dua_id INTEGER REFERENCES duas(id) ON DELETE CASCADE,
    time_slot TEXT NOT NULL,  -- 'morning', 'anytime', 'evening'
    sort_order INTEGER DEFAULT 0,
    UNIQUE(journey_id, dua_id)
);

-- User profiles and stats
CREATE TABLE user_profiles (
    user_id UUID PRIMARY KEY,  -- Firebase Auth UID
    display_name TEXT,
    streak INTEGER DEFAULT 0,
    total_xp INTEGER DEFAULT 0,
    level INTEGER DEFAULT 1,
    last_active_date DATE,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Daily activity tracking
CREATE TABLE user_activity (
    id SERIAL PRIMARY KEY,
    user_id UUID REFERENCES user_profiles(user_id),
    date DATE NOT NULL,
    duas_completed INTEGER[] DEFAULT '{}',
    xp_earned INTEGER DEFAULT 0,
    UNIQUE(user_id, date)
);

-- Per-dua progress tracking
CREATE TABLE user_progress (
    id SERIAL PRIMARY KEY,
    user_id UUID REFERENCES user_profiles(user_id),
    dua_id INTEGER REFERENCES duas(id),
    completed_count INTEGER DEFAULT 0,
    last_completed TIMESTAMPTZ,
    UNIQUE(user_id, dua_id)
);

-- Indexes
CREATE INDEX idx_duas_category ON duas(category_id);
CREATE INDEX idx_journey_duas_journey ON journey_duas(journey_id);
CREATE INDEX idx_user_activity_user_date ON user_activity(user_id, date);
CREATE INDEX idx_user_progress_user ON user_progress(user_id);
```

---

## 10. API Patterns

### Database Query Pattern (Web)

```typescript
// Direct browser queries via @neondatabase/serverless
import { getSql } from '@/lib/db';

const result = await sql`
  SELECT * FROM duas
  WHERE category_id = ${categoryId}
  ORDER BY created_at DESC
`;
```

### React Query Hook Pattern

```typescript
export function useDuas() {
  return useQuery({
    queryKey: ['duas'],
    queryFn: async () => {
      const sql = getSql();
      const result = await sql`SELECT * FROM duas`;
      return (result as DuaRow[]).map(mapDuaRowToFrontend);
    },
  });
}
```

### iOS API Pattern (TCA)

```swift
// Dependency-injected API client
@Dependency(\.apiClient) var apiClient

case .fetchDuas:
  return .run { send in
    let duas = try await apiClient.fetchDuas()
    await send(.duasLoaded(duas))
  }
```

---

## 11. Success Criteria

### MVP Success Definition

The MVP is successful when a user can:
1. Sign up with Google and see a personalized dashboard
2. Browse available journeys and subscribe to Morning Adhkar
3. Practice their morning duas with the tap counter
4. See XP earned and streak maintained
5. Return the next day and continue their streak
6. Feel motivated by visible progress

### Functional Requirements

- ✅ OAuth authentication with Firebase
- ✅ Full dua practice with Arabic/transliteration/translation
- ✅ Journey subscription and daily habit generation
- ✅ XP and level system with progress visualization
- ✅ Streak tracking with daily activity logging
- ✅ Admin panel for content management
- ✅ Mobile-responsive web design
- ✅ iOS app with feature parity

### Quality Indicators

| Metric | Target |
|--------|--------|
| Page load (web) | < 2 seconds |
| Practice tap response | < 50ms |
| Animation frame rate | 60 fps |
| Lighthouse score | > 90 |
| iOS app launch | < 1 second |
| Database query time | < 100ms |

---

## 12. Implementation Phases

### Phase 1: Foundation ✅

**Delivered:**
- React + Vite project with Tailwind + shadcn/ui
- Neon PostgreSQL database with schema
- Firebase Authentication integration
- Basic dua library with practice mode
- Design system with warm Islamic aesthetic

### Phase 2: Core Features ✅

**Delivered:**
- Journey system with subscription
- Daily Adkhar with time slots
- XP and level system
- Streak tracking
- Celebration animations
- Quick Practice bottom sheet

### Phase 3: iOS App ✅

**Delivered:**
- SwiftUI app with TCA architecture
- Feature parity for practice and journeys
- Native haptics and animations
- Widget for daily reminders
- Snapshot testing setup

### Phase 4: Admin & Polish ✅

**Delivered:**
- Full admin panel (duas, journeys, categories, collections, users)
- Landing page for unauthenticated users
- Welcome modal for new users
- Error and loading states
- Mobile-responsive refinements

### Phase 5: Growth (Current)

**In Progress:**
- Firebase migration (from Supabase)
- Performance optimizations
- Additional journeys and duas content
- User feedback integration

### Phase 6: Expansion (Future)

**Planned:**
- Audio recitation
- Push notifications
- Offline mode
- Android app
- Subscription tiers

---

## 13. Future Considerations

### Content Expansion

- **Audio Recitation** — Native speaker recordings for each dua
- **More Journeys** — Protection, Travel, Healing, Parenting
- **Ramadan Special** — Seasonal journey with iftar/suhoor duas
- **Quran Integration** — Duas from Quran with ayah context

### Platform Expansion

- **Android App** — Kotlin with similar architecture
- **Apple Watch** — Quick practice complication
- **Web PWA** — Installable with offline support
- **Browser Extension** — New tab dua of the day

### Social Features

- **Family Groups** — Shared streaks for families
- **Community Challenges** — Group journey completions
- **Leaderboards** — Optional competitive element
- **Sharing** — Beautiful dua cards for social media

### Monetization

- **Premium Journeys** — Advanced/specialized content
- **Streak Protection** — Pay to restore broken streak
- **Ad-Supported Free** — With ad removal subscription
- **Family Plan** — Multiple users under one subscription

---

## 14. Risks & Mitigations

| Risk | Impact | Mitigation |
|------|--------|------------|
| **Inauthentic content** | Trust destruction | All duas vetted by Islamic scholars; clear source attribution |
| **Gamification trivialization** | Spiritual value undermined | Gentle, optional gamification; focus on habit formation over competition |
| **Streak pressure** | User guilt and abandonment | Completion rate shown alongside streak; grace periods |
| **Arabic rendering issues** | Core feature broken | Amiri font tested across devices; RTL handling verified |
| **Database costs** | Unexpected expenses | Neon serverless scales to zero; query optimization |
| **iOS app rejection** | Launch blocked | Follow Apple guidelines; no gambling-like mechanics |
| **Content moderation** | Inappropriate submissions | Admin-only content creation; no UGC in MVP |
| **Authentication failures** | User lockout | Multiple OAuth providers; Firebase reliability |

---

## 15. Appendix

### XP & Level Formula

```typescript
// Level threshold: 50 * level² + 50 * level
// Level 1: 0-100 XP
// Level 2: 100-300 XP
// Level 3: 300-600 XP
// Level 4: 600-1000 XP

const calculateLevel = (xp: number): number => {
  let level = 1;
  while (50 * level * level + 50 * level <= xp) {
    level++;
  }
  return level;
};

const xpForLevel = (level: number): number => {
  return 50 * level * level + 50 * level;
};
```

### Time Slot Definitions

| Slot | Islamic Timing | Icon |
|------|----------------|------|
| Morning | Fajr → Dhuhr | ☀️ Sun |
| Anytime | All day | 🕐 Clock |
| Evening | Maghrib → Isha | 🌙 Moon |

### Category Slugs

| Slug | Description |
|------|-------------|
| `morning` | Morning adhkar and duas |
| `evening` | Evening adhkar and duas |
| `rizq` | Provision, sustenance, wealth |
| `gratitude` | Thankfulness and praise |

### Key Dependencies

- [React Documentation](https://react.dev/)
- [TanStack Query](https://tanstack.com/query/latest)
- [Framer Motion](https://www.framer.com/motion/)
- [The Composable Architecture](https://github.com/pointfreeco/swift-composable-architecture)
- [Neon Database](https://neon.tech/docs)
- [Firebase Auth](https://firebase.google.com/docs/auth)
- [shadcn/ui](https://ui.shadcn.com/)
- [Tailwind CSS](https://tailwindcss.com/)

---

## 16. Glossary

| Term | Definition |
|------|------------|
| **Dua** | Supplication; a prayer or invocation to Allah |
| **Adhkar** | Plural of dhikr; remembrances of Allah, typically short phrases repeated |
| **Journey** | A curated collection of related duas with a theme |
| **Time Slot** | Morning, anytime, or evening—when a dua is best practiced |
| **Rizq** | Provision, sustenance, wealth—all blessings from Allah |
| **XP** | Experience points earned for completing duas |
| **Streak** | Consecutive days of practice |
| **TCA** | The Composable Architecture—SwiftUI state management pattern |
