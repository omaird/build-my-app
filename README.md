# RIZQ

A gamified Islamic dua (supplication) practice and habit-tracking app. Users practice authentic duas, build daily routines through "Journeys," earn XP, level up, and track streaks. Features a warm, luxury Islamic aesthetic with smooth animations and a mobile-first design.

## Prerequisites

- **Node.js 18+** with npm
- **Neon PostgreSQL** account (database)
- **Firebase** account (authentication)
- **Git** (optional, for cloning)

## Quick Start

### 1. Clone and Install Dependencies

```bash
git clone <YOUR_GIT_URL>
cd rizq-app
npm install
```

### 2. Configure Environment

Create a `.env` file in the root directory:

```env
VITE_DATABASE_URL=postgresql://...  # Neon connection string
VITE_FIREBASE_API_KEY=...           # Firebase config
VITE_FIREBASE_AUTH_DOMAIN=...
VITE_FIREBASE_PROJECT_ID=...
```

### 3. Start Development Server

```bash
npm run dev
```

App runs at http://localhost:5173

### 4. Open the App

Navigate to **http://localhost:5173** in your browser. Sign in with Google or GitHub and start your dua practice journey!

## Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                     React + Vite (5173)                     │
│  ┌──────────┐  ┌──────────┐  ┌──────────┐  ┌──────────┐    │
│  │ Journeys │  │  Adkhar  │  │ Practice │  │  Admin   │    │
│  └──────────┘  └──────────┘  └──────────┘  └──────────┘    │
│                          │                                  │
│              ┌───────────┴───────────┐                     │
│              │   TanStack Query v5   │                     │
│              └───────────┬───────────┘                     │
└──────────────────────────┼──────────────────────────────────┘
                           │
           ┌───────────────┴───────────────┐
           │                               │
   ┌───────▼───────┐             ┌─────────▼────────┐
   │   Firebase    │             │  Neon PostgreSQL │
   │     Auth      │             │   (Serverless)   │
   └───────────────┘             └──────────────────┘
```

### Tech Stack

| Layer | Technology |
|-------|------------|
| Frontend | React 18, TypeScript, Vite (SWC) |
| Styling | Tailwind CSS, shadcn/ui |
| Animations | Framer Motion |
| State (Server) | TanStack React Query v5 |
| State (Client) | React Context + localStorage |
| Database | Neon PostgreSQL (serverless) |
| Auth | Firebase Authentication |
| Testing | Playwright (E2E) |

### Project Structure

```
rizq-app/
├── src/
│   ├── components/
│   │   ├── ui/              # shadcn/ui primitives
│   │   ├── admin/           # Admin panel components
│   │   ├── animations/      # Celebration, ripple, sparkles
│   │   ├── dua/             # Dua practice components
│   │   ├── habits/          # Habit tracking components
│   │   └── journeys/        # Journey feature components
│   ├── pages/
│   │   ├── admin/           # Admin CRUD pages
│   │   ├── LandingPage.tsx  # Public marketing page
│   │   ├── HomePage.tsx     # Dashboard with stats
│   │   ├── DailyAdkharPage.tsx # Daily habits view
│   │   ├── PracticePage.tsx # Dua practice with counter
│   │   └── JourneysPage.tsx # Journey selection
│   ├── hooks/
│   │   ├── admin/           # Admin CRUD hooks
│   │   ├── useDuas.ts       # Dua data fetching
│   │   ├── useJourneys.ts   # Journey management
│   │   └── useUserHabits.ts # Habit state
│   ├── contexts/
│   │   └── AuthContext.tsx  # Auth + profile state
│   ├── lib/
│   │   ├── db.ts            # Neon SQL client
│   │   └── auth-client.ts   # Firebase auth client
│   └── types/               # TypeScript definitions
├── RIZQ-iOS/                # Native iOS app (Swift/TCA)
└── README.md
```

## Features

- **Dua Practice** — Practice duas with Arabic text, transliteration, translation, and repetition counter
- **Journeys** — Pre-built themed dua collections (e.g., "Morning Adhkar", "Rizq Path")
- **Daily Adkhar** — Habit system with morning/anytime/evening time slots
- **Quick Practice** — Bottom sheet for rapid dua practice without leaving current page
- **Gamification** — XP, levels, streaks, and celebratory animations
- **Admin Panel** — Full CRUD management for duas, journeys, categories, and users
- **Social Auth** — Sign in with Google or GitHub via Firebase
- **Mobile-First** — Responsive design optimized for mobile devices

## Database Schema

| Table | Purpose |
|-------|---------|
| `duas` | Main dua content (Arabic, transliteration, translation, source) |
| `journeys` | Themed dua collections with XP rewards |
| `journey_duas` | Journey-dua mapping with time slots |
| `categories` | Dua categories (morning, evening, rizq, gratitude) |
| `collections` | Content tiers (free, premium) |
| `user_profiles` | User stats (streak, XP, level) |
| `user_activity` | Daily tracking and completions |

## iOS App

The `RIZQ-iOS/` directory contains a native iOS app built with Swift 5.9, SwiftUI, and The Composable Architecture (TCA).

**[→ iOS README](RIZQ-iOS/README.md)** — Full setup instructions, architecture, and Fastlane commands

## Claude Commands

Slash commands for Claude Code to assist with development:

### Development
| Command | Description |
|---------|-------------|
| `/commit` | Create atomic commit with conventional commit format |
| `/feature-dev` | Guided feature development with architecture focus |
| `/frontend-design` | Create production-grade frontend interfaces |

### Code Quality
| Command | Description |
|---------|-------------|
| `/review-pr` | Comprehensive PR review using specialized agents |
| `/code-review` | Review code for bugs, security, and best practices |

### Firebase Integration
| Command | Description |
|---------|-------------|
| `/setup-firebase` | Configure Firebase services for the project |

## Design System

The app uses a warm, luxury Islamic color palette:

| Token | Color | Usage |
|-------|-------|-------|
| Primary (Sand) | `#D4A574` | Buttons, XP bars |
| Accent (Mocha) | `#6B4423` | Headers, badges |
| Background (Cream) | `#F5EFE7` | Page backgrounds |
| Success (Teal) | `#5B8A8A` | Completions |

Typography uses Crimson Pro (body), Playfair Display (headings), and Amiri (Arabic text).

## Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes using conventional commits
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## License

This project is private and not licensed for public use.
