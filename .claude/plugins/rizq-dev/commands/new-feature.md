---
name: new-feature
description: "Scaffold a new feature with all necessary files (types, hooks, components, page, route)"
---

# New Feature Command

Scaffold a complete feature for the RIZQ App.

## Usage

```
/new-feature [feature-name]
```

## What This Creates

1. **Types** - `src/types/[feature].ts`
2. **Hook** - `src/hooks/use[Feature].ts`
3. **Components** - `src/components/[feature]/`
4. **Page** - `src/pages/[Feature]Page.tsx`
5. **Route** - Added to `src/App.tsx`

## Process

### Step 1: Gather Information

Ask the user:
1. What is this feature for? (purpose)
2. Does it need database storage? (new tables)
3. Is it user-specific? (requires auth)
4. What's the main entity? (e.g., Achievement, Reminder)

### Step 2: Create Types

```typescript
// src/types/[feature].ts
export interface [Entity] {
  id: number;
  // ... fields based on requirements
}

export interface [Entity]WithStatus extends [Entity] {
  // ... computed/joined fields
}
```

### Step 3: Create Database (if needed)

```sql
CREATE TABLE [entities] (
  id SERIAL PRIMARY KEY,
  -- ... columns
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
```

### Step 4: Create Hook

```typescript
// src/hooks/use[Feature].ts
import { useQuery } from '@tanstack/react-query';
import { getSql } from '@/lib/db';
import type { [Entity] } from '@/types/[feature]';

export function use[Feature]() {
  const sql = getSql();

  return useQuery({
    queryKey: ['[feature]'],
    queryFn: async (): Promise<[Entity][]> => {
      const result = await sql`SELECT * FROM [entities]`;
      return result.map(mapDbTo[Entity]);
    },
  });
}
```

### Step 5: Create Components

```typescript
// src/components/[feature]/[Entity]Card.tsx
import { motion } from 'framer-motion';
import type { [Entity] } from '@/types/[feature]';

interface [Entity]CardProps {
  [entity]: [Entity];
}

export function [Entity]Card({ [entity] }: [Entity]CardProps) {
  return (
    <motion.div
      initial={{ opacity: 0, y: 20 }}
      animate={{ opacity: 1, y: 0 }}
      className="p-4 rounded-islamic bg-card border border-border/50"
    >
      {/* Content */}
    </motion.div>
  );
}
```

### Step 6: Create Page

```typescript
// src/pages/[Feature]Page.tsx
import { motion } from 'framer-motion';
import { use[Feature] } from '@/hooks/use[Feature]';
import { [Entity]Card } from '@/components/[feature]/[Entity]Card';
import { Loader2 } from 'lucide-react';

const containerVariants = {
  hidden: { opacity: 0 },
  visible: {
    opacity: 1,
    transition: { staggerChildren: 0.08 },
  },
};

const itemVariants = {
  hidden: { opacity: 0, y: 20 },
  visible: { opacity: 1, y: 0 },
};

export default function [Feature]Page() {
  const { data, isLoading } = use[Feature]();

  if (isLoading) {
    return (
      <div className="flex items-center justify-center min-h-[50vh]">
        <Loader2 className="w-8 h-8 animate-spin text-primary" />
      </div>
    );
  }

  return (
    <div className="min-h-screen bg-background pb-24">
      <div className="px-5 pt-6 pb-4">
        <h1 className="text-2xl font-bold">[Feature Title]</h1>
      </div>

      <motion.div
        variants={containerVariants}
        initial="hidden"
        animate="visible"
        className="px-5 space-y-4"
      >
        {data?.map(item => (
          <motion.div key={item.id} variants={itemVariants}>
            <[Entity]Card [entity]={item} />
          </motion.div>
        ))}
      </motion.div>
    </div>
  );
}
```

### Step 7: Add Route

```typescript
// Add to src/App.tsx
import [Feature]Page from '@/pages/[Feature]Page';

// In Routes:
<Route
  path="/[feature]"
  element={
    <ProtectedRoute>
      <[Feature]Page />
    </ProtectedRoute>
  }
/>
```

## Example

```
/new-feature achievements
```

Creates:
- `src/types/achievement.ts`
- `src/hooks/useAchievements.ts`
- `src/components/achievements/AchievementCard.tsx`
- `src/pages/AchievementsPage.tsx`
- Route: `/achievements`

## Checklist

After scaffolding, verify:
- [ ] Types match database schema
- [ ] Hook queries correct table
- [ ] Component has loading state
- [ ] Page has pb-24 for bottom nav
- [ ] Route is protected if needed
- [ ] Navigation link added (if in main nav)
