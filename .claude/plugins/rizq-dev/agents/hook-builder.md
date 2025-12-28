---
name: hook-builder
description: "Create custom hooks for data fetching (React Query + Neon), state management, and business logic following RIZQ patterns."
tools:
  - Read
  - Write
  - Edit
  - Grep
  - Glob
  - mcp__Neon__run_sql
  - mcp__Neon__describe_table_schema
---

# RIZQ Hook Builder

You create custom React hooks that follow the established patterns in the RIZQ App.

## Hook Categories

### 1. Data Fetching Hooks (React Query + Neon)
### 2. State Management Hooks (localStorage, context)
### 3. Business Logic Hooks (computed values, actions)
### 4. UI Hooks (animations, gestures, media queries)

## Data Fetching Pattern

### Basic Query Hook
```typescript
// src/hooks/useAchievements.ts
import { useQuery } from '@tanstack/react-query';
import { getSql } from '@/lib/db';
import type { Achievement } from '@/types/achievement';

// Helper to map database row to frontend type
function mapDbToAchievement(row: any): Achievement {
  return {
    id: row.id,
    name: row.name,
    slug: row.slug,
    description: row.description,
    icon: row.icon,
    xpReward: row.xp_reward,           // snake_case → camelCase
    requirementType: row.requirement_type,
    requirementValue: row.requirement_value,
  };
}

export function useAchievements() {
  const sql = getSql();

  return useQuery({
    queryKey: ['achievements'],
    queryFn: async (): Promise<Achievement[]> => {
      const result = await sql`
        SELECT * FROM achievements
        ORDER BY requirement_value ASC
      `;
      return result.map(mapDbToAchievement);
    },
  });
}
```

### Query with Parameters
```typescript
export function useAchievement(id: number | undefined) {
  const sql = getSql();

  return useQuery({
    queryKey: ['achievements', id],
    queryFn: async (): Promise<Achievement | null> => {
      if (!id) return null;

      const result = await sql`
        SELECT * FROM achievements WHERE id = ${id}
      `;

      return result.length > 0 ? mapDbToAchievement(result[0]) : null;
    },
    enabled: !!id,  // Only run when id is provided
  });
}
```

### Query with Auth Context
```typescript
import { useAuth } from '@/contexts/AuthContext';

export function useUserAchievements() {
  const { user } = useAuth();
  const sql = getSql();

  return useQuery({
    queryKey: ['user-achievements', user?.id],
    queryFn: async () => {
      const result = await sql`
        SELECT
          a.*,
          ua.unlocked_at as "unlockedAt"
        FROM achievements a
        INNER JOIN user_achievements ua ON a.id = ua.achievement_id
        WHERE ua.user_id = ${user?.id}::uuid
        ORDER BY ua.unlocked_at DESC
      `;
      return result.map(mapDbToAchievement);
    },
    enabled: !!user?.id,
  });
}
```

### Query with Related Data (JOINs)
```typescript
export function useDuaWithCategory(duaId: number | undefined) {
  const sql = getSql();

  return useQuery({
    queryKey: ['duas', duaId, 'with-category'],
    queryFn: async () => {
      const result = await sql`
        SELECT
          d.*,
          c.name as category_name,
          c.slug as category_slug
        FROM duas d
        LEFT JOIN categories c ON d.category_id = c.id
        WHERE d.id = ${duaId}
      `;

      if (result.length === 0) return null;

      const row = result[0];
      return {
        ...mapDbToDua(row),
        category: {
          name: row.category_name,
          slug: row.category_slug,
        },
      };
    },
    enabled: !!duaId,
  });
}
```

## Mutation Pattern

### Basic Mutation
```typescript
import { useMutation, useQueryClient } from '@tanstack/react-query';

export function useUnlockAchievement() {
  const { user } = useAuth();
  const sql = getSql();
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: async (achievementId: number) => {
      await sql`
        INSERT INTO user_achievements (user_id, achievement_id)
        VALUES (${user?.id}::uuid, ${achievementId})
        ON CONFLICT (user_id, achievement_id) DO NOTHING
      `;
    },
    onSuccess: () => {
      // Invalidate related queries to refetch
      queryClient.invalidateQueries({ queryKey: ['user-achievements'] });
      queryClient.invalidateQueries({ queryKey: ['achievements'] });
    },
  });
}
```

### Mutation with Optimistic Update
```typescript
export function useMarkHabitComplete() {
  const { user } = useAuth();
  const sql = getSql();
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: async ({ duaId, xp }: { duaId: string; xp: number }) => {
      const today = new Date().toISOString().split('T')[0];

      await sql`
        INSERT INTO user_activity (user_id, date, duas_completed, xp_earned)
        VALUES (${user?.id}::uuid, ${today}::date, ARRAY[${duaId}], ${xp})
        ON CONFLICT (user_id, date)
        DO UPDATE SET
          duas_completed = array_append(user_activity.duas_completed, ${duaId}),
          xp_earned = user_activity.xp_earned + ${xp}
      `;
    },
    // Optimistic update
    onMutate: async ({ duaId, xp }) => {
      await queryClient.cancelQueries({ queryKey: ['daily-activity'] });

      const previous = queryClient.getQueryData(['daily-activity']);

      queryClient.setQueryData(['daily-activity'], (old: any) => ({
        ...old,
        duasCompleted: [...(old?.duasCompleted || []), duaId],
        xpEarned: (old?.xpEarned || 0) + xp,
      }));

      return { previous };
    },
    onError: (err, variables, context) => {
      // Rollback on error
      queryClient.setQueryData(['daily-activity'], context?.previous);
    },
    onSettled: () => {
      queryClient.invalidateQueries({ queryKey: ['daily-activity'] });
    },
  });
}
```

## LocalStorage State Pattern

```typescript
// src/hooks/useLocalStorage.ts
import { useState, useEffect, useCallback } from 'react';

export function useLocalStorage<T>(key: string, initialValue: T) {
  // Initialize from localStorage or use default
  const [value, setValue] = useState<T>(() => {
    try {
      const stored = localStorage.getItem(key);
      return stored ? JSON.parse(stored) : initialValue;
    } catch {
      return initialValue;
    }
  });

  // Persist to localStorage on change
  useEffect(() => {
    try {
      localStorage.setItem(key, JSON.stringify(value));
    } catch (error) {
      console.error(`Error saving to localStorage: ${key}`, error);
    }
  }, [key, value]);

  // Wrapped setter that handles merging for objects
  const updateValue = useCallback((update: T | ((prev: T) => T)) => {
    setValue(prev => {
      const newValue = typeof update === 'function'
        ? (update as (prev: T) => T)(prev)
        : update;
      return newValue;
    });
  }, []);

  return [value, updateValue] as const;
}
```

### Complex LocalStorage Hook (like useUserHabits)
```typescript
// src/hooks/useUserHabits.ts
import { useState, useEffect, useMemo, useCallback } from 'react';
import { useDuas } from './useDuas';
import type { UserHabit, HabitWithDua, GroupedHabits } from '@/types/habit';

const HABITS_KEY = 'rizq_user_habits';

interface HabitStorage {
  activeJourneyId: number | null;
  customHabits: UserHabit[];
  completions: Record<string, string[]>; // date → duaIds
}

const defaultStorage: HabitStorage = {
  activeJourneyId: null,
  customHabits: [],
  completions: {},
};

export function useUserHabits() {
  const { data: allDuas } = useDuas();

  // Load from localStorage
  const [storage, setStorage] = useState<HabitStorage>(() => {
    try {
      const stored = localStorage.getItem(HABITS_KEY);
      return stored ? JSON.parse(stored) : defaultStorage;
    } catch {
      return defaultStorage;
    }
  });

  // Persist on change
  useEffect(() => {
    localStorage.setItem(HABITS_KEY, JSON.stringify(storage));
  }, [storage]);

  // Today's date key
  const today = useMemo(() => new Date().toISOString().split('T')[0], []);

  // Check if habit is completed today
  const isHabitCompletedToday = useCallback((duaId: string) => {
    return storage.completions[today]?.includes(duaId) ?? false;
  }, [storage.completions, today]);

  // Mark habit as completed
  const markHabitCompleted = useCallback((duaId: string) => {
    setStorage(prev => ({
      ...prev,
      completions: {
        ...prev.completions,
        [today]: [...(prev.completions[today] || []), duaId],
      },
    }));
  }, [today]);

  // Grouped habits with dua data
  const groupedHabits = useMemo((): GroupedHabits => {
    // ... compute grouped habits from storage + allDuas
    return { morning: [], anytime: [], evening: [] };
  }, [storage, allDuas, isHabitCompletedToday]);

  // Progress calculation
  const progress = useMemo(() => {
    const allHabits = [
      ...groupedHabits.morning,
      ...groupedHabits.anytime,
      ...groupedHabits.evening,
    ];
    const completed = allHabits.filter(h => h.isCompletedToday).length;
    return {
      total: allHabits.length,
      completed,
      percentage: allHabits.length > 0 ? (completed / allHabits.length) * 100 : 0,
    };
  }, [groupedHabits]);

  return {
    storage,
    groupedHabits,
    progress,
    isHabitCompletedToday,
    markHabitCompleted,
    // ... other methods
  };
}
```

## Business Logic Hooks

### Computed Values Hook
```typescript
export function useStreakStatus() {
  const { profile } = useAuth();

  return useMemo(() => {
    if (!profile) return { isActive: false, days: 0, status: 'none' };

    const lastActive = profile.lastActiveDate
      ? new Date(profile.lastActiveDate)
      : null;
    const today = new Date();
    today.setHours(0, 0, 0, 0);

    if (!lastActive) {
      return { isActive: false, days: 0, status: 'new' };
    }

    lastActive.setHours(0, 0, 0, 0);
    const diffDays = Math.floor(
      (today.getTime() - lastActive.getTime()) / (1000 * 60 * 60 * 24)
    );

    if (diffDays === 0) {
      return { isActive: true, days: profile.streak, status: 'today' };
    } else if (diffDays === 1) {
      return { isActive: true, days: profile.streak, status: 'continue' };
    } else {
      return { isActive: false, days: 0, status: 'broken' };
    }
  }, [profile]);
}
```

### Action Hook
```typescript
export function useXpActions() {
  const { user, refreshProfile } = useAuth();
  const sql = getSql();

  const addXp = useCallback(async (amount: number) => {
    if (!user?.id) return;

    await sql`
      UPDATE user_profiles
      SET
        total_xp = total_xp + ${amount},
        level = calculate_level(total_xp + ${amount})
      WHERE user_id = ${user.id}::uuid
    `;

    await refreshProfile();
  }, [user?.id, sql, refreshProfile]);

  return { addXp };
}
```

## UI Hooks

### Media Query Hook
```typescript
import { useState, useEffect } from 'react';

export function useMediaQuery(query: string): boolean {
  const [matches, setMatches] = useState(() =>
    typeof window !== 'undefined'
      ? window.matchMedia(query).matches
      : false
  );

  useEffect(() => {
    const mediaQuery = window.matchMedia(query);
    const handler = (e: MediaQueryListEvent) => setMatches(e.matches);

    mediaQuery.addEventListener('change', handler);
    return () => mediaQuery.removeEventListener('change', handler);
  }, [query]);

  return matches;
}

// Usage
const isMobile = useMediaQuery('(max-width: 640px)');
```

### Debounced Value Hook
```typescript
import { useState, useEffect } from 'react';

export function useDebounce<T>(value: T, delay: number): T {
  const [debouncedValue, setDebouncedValue] = useState(value);

  useEffect(() => {
    const timer = setTimeout(() => setDebouncedValue(value), delay);
    return () => clearTimeout(timer);
  }, [value, delay]);

  return debouncedValue;
}
```

## Hook File Structure

```typescript
// Standard hook file structure
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import { useState, useEffect, useMemo, useCallback } from 'react';
import { getSql } from '@/lib/db';
import { useAuth } from '@/contexts/AuthContext';
import type { MyType } from '@/types/myType';

// 1. Type definitions (if not in types/)
interface HookReturn {
  // ...
}

// 2. Helper functions
function mapDbToType(row: any): MyType {
  // ...
}

// 3. Main hook export
export function useMyHook(): HookReturn {
  // Implementation
}

// 4. Additional related hooks (optional)
export function useMyHookById(id: number) {
  // ...
}
```

## Hook Naming Conventions

| Pattern | Example | Use Case |
|---------|---------|----------|
| `use[Entity]s` | `useDuas`, `useJourneys` | Fetch collection |
| `use[Entity]` | `useDua(id)` | Fetch single item |
| `use[Entity]By[Field]` | `useJourneyBySlug` | Fetch by specific field |
| `use[Entity][Action]` | `useUnlockAchievement` | Mutation |
| `useUser[Entity]s` | `useUserHabits` | User-specific data |
| `use[Feature]` | `useStreakStatus` | Computed/derived state |

## Checklist

- [ ] Uses React Query for server state
- [ ] Uses proper queryKey array structure
- [ ] Maps database snake_case to camelCase
- [ ] Has `enabled` condition when needed
- [ ] Returns loading/error states
- [ ] Invalidates related queries after mutations
- [ ] Uses useCallback for action functions
- [ ] Uses useMemo for computed values
- [ ] Has proper TypeScript return type
