# RIZQ App - Development Guide

This document contains conventions and patterns that Claude should follow when working on this codebase.

## Project Overview

RIZQ is a gamified Islamic dua (supplication) practice and habit-tracking app. Users practice authentic duas, build daily routines, earn XP, and track streaks.

## Tech Stack

| Layer | Technology |
|-------|------------|
| Frontend | React 18 + TypeScript + Vite |
| Styling | Tailwind CSS + shadcn/ui |
| Animations | Framer Motion |
| State (Server) | TanStack React Query |
| State (Client) | React Context + localStorage |
| Database | Neon PostgreSQL (serverless) |
| Auth | Better Auth + Neon Auth |

## Project Structure

```
src/
├── components/
│   ├── ui/              # shadcn/ui (don't modify)
│   ├── animations/      # Reusable animation components
│   ├── habits/          # Habit feature components
│   └── journeys/        # Journey feature components
├── pages/               # Route page components
├── hooks/               # Custom React hooks
├── contexts/            # React contexts (AuthContext)
├── lib/                 # Utilities (db.ts, auth-client.ts)
├── types/               # TypeScript interfaces
└── App.tsx              # Router configuration
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

export function useMyData() {
  const sql = getSql();

  return useQuery({
    queryKey: ['my-data'],
    queryFn: async () => {
      const result = await sql`SELECT * FROM my_table`;
      return result.map(mapDbToFrontend);
    },
  });
}
```

### Database Query Pattern

```typescript
// Template literal with auto-parameterization
const result = await sql`
  SELECT * FROM duas
  WHERE category_id = ${categoryId}
`;

// UPSERT pattern
await sql`
  INSERT INTO user_activity (user_id, date, xp_earned)
  VALUES (${userId}::uuid, ${date}::date, ${xp})
  ON CONFLICT (user_id, date)
  DO UPDATE SET xp_earned = user_activity.xp_earned + ${xp}
`;
```

## Design System

### Colors (CSS Variables)

```css
--primary: 30 52% 56%;        /* Warm Sand #D4A574 */
--accent: 24 50% 30%;         /* Deep Mocha #6B4423 */
--background: 38 35% 96%;     /* Cream */
--foreground: 24 32% 12%;     /* Deep Charcoal */
--success: 158 35% 42%;       /* Muted Teal */
```

### Border Radius

- `rounded-islamic` (20px) - Cards, major containers
- `rounded-btn` (16px) - Buttons
- `rounded-lg` (12px) - Default

### Animation Pattern

```typescript
// Staggered list animation
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

### Interactive States

```typescript
// Card hover
<motion.div whileHover={{ y: -2 }} whileTap={{ scale: 0.98 }}>

// Button
<motion.button whileHover={{ scale: 1.02 }} whileTap={{ scale: 0.98 }}>
```

## Key Files

| Purpose | File |
|---------|------|
| Router | `src/App.tsx` |
| Database | `src/lib/db.ts` |
| Auth Client | `src/lib/auth-client.ts` |
| Auth Context | `src/contexts/AuthContext.tsx` |
| Dua Types | `src/types/dua.ts` |
| Habit Types | `src/types/habit.ts` |
| Design Tokens | `tailwind.config.ts` |

## Required Patterns

### Pages Must Have

- Bottom padding: `pb-24` (for nav)
- Loading state with `<Loader2 />`
- Empty state component
- Framer Motion entry animation

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

## Database Tables

| Table | Purpose |
|-------|---------|
| `categories` | Dua categories (morning, evening, rizq, gratitude) |
| `collections` | Content tiers (core, extended, specialized) |
| `duas` | Main dua content |
| `journeys` | Themed dua collections |
| `journey_duas` | Journey-dua mapping with time slots |
| `user_profiles` | User stats (streak, XP, level) |
| `user_activity` | Daily activity tracking |

## Type Mapping

Database columns use snake_case. Map to camelCase in TypeScript:

```typescript
function mapDbToDua(row: any): Dua {
  return {
    id: row.id,
    titleEn: row.title_en,        // snake → camel
    arabicText: row.arabic_text,
    xpValue: row.xp_value,
  };
}
```

## Don't

- Don't modify files in `src/components/ui/` (shadcn/ui)
- Don't hardcode colors (use CSS variables)
- Don't skip loading/empty states
- Don't forget `pb-24` on pages
- Don't use `any` types without mapping
- Don't commit console.log statements
