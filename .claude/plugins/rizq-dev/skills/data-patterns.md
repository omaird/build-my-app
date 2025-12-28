---
name: data-patterns
description: "Patterns for React Query hooks, Neon database access, and type mappings in RIZQ App"
---

# RIZQ Data Patterns

## Database Connection

```typescript
// src/lib/db.ts
import { neon } from '@neondatabase/serverless';

let _sql: ReturnType<typeof neon> | null = null;

export function getSql() {
  if (!_sql) {
    _sql = neon(import.meta.env.VITE_DATABASE_URL, {
      disableWarningInBrowsers: true,
    });
  }
  return _sql;
}
```

## Query Patterns

### Basic SELECT
```typescript
const result = await sql`SELECT * FROM duas ORDER BY title_en`;
```

### With Parameters
```typescript
const result = await sql`
  SELECT * FROM duas
  WHERE category_id = ${categoryId}
  AND difficulty = ${difficulty}
`;
```

### With Type Casting
```typescript
// UUID
await sql`SELECT * FROM user_profiles WHERE user_id = ${userId}::uuid`;

// Date
await sql`SELECT * FROM user_activity WHERE date = ${date}::date`;

// Array
await sql`SELECT * FROM duas WHERE id = ANY(${duaIds}::int[])`;
```

### JOINs
```typescript
const result = await sql`
  SELECT
    d.*,
    c.name as category_name,
    c.slug as category_slug
  FROM duas d
  LEFT JOIN categories c ON d.category_id = c.id
  WHERE d.id = ${id}
`;
```

### Aggregations
```typescript
const result = await sql`
  SELECT
    c.name,
    COUNT(d.id) as dua_count,
    SUM(d.xp_value) as total_xp
  FROM categories c
  LEFT JOIN duas d ON c.id = d.category_id
  GROUP BY c.id
  ORDER BY dua_count DESC
`;
```

### UPSERT (INSERT ... ON CONFLICT)
```typescript
await sql`
  INSERT INTO user_activity (user_id, date, duas_completed, xp_earned)
  VALUES (${userId}::uuid, ${date}::date, ARRAY[${duaId}], ${xp})
  ON CONFLICT (user_id, date)
  DO UPDATE SET
    duas_completed = array_append(user_activity.duas_completed, ${duaId}),
    xp_earned = user_activity.xp_earned + ${xp}
`;
```

### Array Operations
```typescript
// Append
SET duas_completed = array_append(duas_completed, ${duaId})

// Check contains
WHERE ${duaId} = ANY(duas_completed)

// Remove
SET duas_completed = array_remove(duas_completed, ${duaId})
```

## Type Mapping

### Database → TypeScript
```typescript
// Database uses snake_case
// TypeScript uses camelCase

function mapDbToDua(row: any): Dua {
  return {
    id: row.id,
    titleEn: row.title_en,
    titleAr: row.title_ar,
    arabicText: row.arabic_text,
    transliteration: row.transliteration,
    translationEn: row.translation_en,
    source: row.source,
    repetitions: row.repetitions,
    bestTime: row.best_time,
    difficulty: row.difficulty,
    estDurationSec: row.est_duration_sec,
    rizqBenefit: row.rizq_benefit,
    xpValue: row.xp_value,
    audioUrl: row.audio_url,
    categoryId: row.category_id,
    collectionId: row.collection_id,
  };
}
```

### Using SQL Aliases
```typescript
// Alternative: alias in SQL for automatic camelCase
const result = await sql`
  SELECT
    id,
    title_en as "titleEn",
    arabic_text as "arabicText",
    xp_value as "xpValue"
  FROM duas
`;
// Result rows already have camelCase keys
```

## React Query Patterns

### Basic Query Hook
```typescript
import { useQuery } from '@tanstack/react-query';
import { getSql } from '@/lib/db';
import type { Dua } from '@/types/dua';

export function useDuas() {
  const sql = getSql();

  return useQuery({
    queryKey: ['duas'],
    queryFn: async (): Promise<Dua[]> => {
      const result = await sql`SELECT * FROM duas ORDER BY title_en`;
      return result.map(mapDbToDua);
    },
  });
}
```

### Query with Parameter
```typescript
export function useDua(id: number | undefined) {
  const sql = getSql();

  return useQuery({
    queryKey: ['duas', id],
    queryFn: async (): Promise<Dua | null> => {
      if (!id) return null;
      const result = await sql`SELECT * FROM duas WHERE id = ${id}`;
      return result.length > 0 ? mapDbToDua(result[0]) : null;
    },
    enabled: !!id, // Only run when id is defined
  });
}
```

### Query with Auth
```typescript
import { useAuth } from '@/contexts/AuthContext';

export function useUserActivity() {
  const { user } = useAuth();
  const sql = getSql();

  return useQuery({
    queryKey: ['user-activity', user?.id],
    queryFn: async () => {
      const result = await sql`
        SELECT * FROM user_activity
        WHERE user_id = ${user?.id}::uuid
        ORDER BY date DESC
      `;
      return result.map(mapDbToActivity);
    },
    enabled: !!user?.id,
  });
}
```

### Multiple Related Queries
```typescript
export function useJourneyWithDuas(journeyId: number | undefined) {
  const sql = getSql();

  return useQuery({
    queryKey: ['journeys', journeyId, 'with-duas'],
    queryFn: async () => {
      // Get journey
      const [journey] = await sql`
        SELECT * FROM journeys WHERE id = ${journeyId}
      `;
      if (!journey) return null;

      // Get linked duas
      const duas = await sql`
        SELECT d.*, jd.time_slot, jd.sort_order
        FROM journey_duas jd
        JOIN duas d ON jd.dua_id = d.id
        WHERE jd.journey_id = ${journeyId}
        ORDER BY jd.sort_order
      `;

      return {
        ...mapDbToJourney(journey),
        duas: duas.map(row => ({
          ...mapDbToDua(row),
          timeSlot: row.time_slot,
          sortOrder: row.sort_order,
        })),
      };
    },
    enabled: !!journeyId,
  });
}
```

## Mutation Patterns

### Basic Mutation
```typescript
import { useMutation, useQueryClient } from '@tanstack/react-query';

export function useCreateDua() {
  const sql = getSql();
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: async (dua: NewDua) => {
      const [result] = await sql`
        INSERT INTO duas (title_en, arabic_text, ...)
        VALUES (${dua.titleEn}, ${dua.arabicText}, ...)
        RETURNING *
      `;
      return mapDbToDua(result);
    },
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['duas'] });
    },
  });
}
```

### Mutation with Optimistic Update
```typescript
export function useMarkComplete() {
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
      queryClient.setQueryData(['daily-activity'], context?.previous);
    },
    onSettled: () => {
      queryClient.invalidateQueries({ queryKey: ['daily-activity'] });
    },
  });
}
```

## Query Key Conventions

```typescript
// Entity list
queryKey: ['duas']
queryKey: ['journeys']
queryKey: ['categories']

// Single entity
queryKey: ['duas', id]
queryKey: ['journeys', slug]

// Filtered list
queryKey: ['duas', { category: 'morning' }]
queryKey: ['duas', { difficulty: 'beginner' }]

// Related data
queryKey: ['journeys', id, 'with-duas']
queryKey: ['duas', id, 'with-category']

// User-specific
queryKey: ['user-activity', userId]
queryKey: ['user-achievements', userId]
```

## LocalStorage Patterns

### Simple Persistence
```typescript
const STORAGE_KEY = 'rizq_my_data';

export function useMyData() {
  const [data, setData] = useState(() => {
    try {
      const stored = localStorage.getItem(STORAGE_KEY);
      return stored ? JSON.parse(stored) : defaultValue;
    } catch {
      return defaultValue;
    }
  });

  useEffect(() => {
    localStorage.setItem(STORAGE_KEY, JSON.stringify(data));
  }, [data]);

  return [data, setData] as const;
}
```

### Complex State (like useUserHabits)
```typescript
interface HabitStorage {
  activeJourneyId: number | null;
  customHabits: UserHabit[];
  completions: Record<string, string[]>; // date → duaIds
}

export function useUserHabits() {
  const [storage, setStorage] = useState<HabitStorage>(() => {
    // Load from localStorage
  });

  // Persist on change
  useEffect(() => {
    localStorage.setItem(HABITS_KEY, JSON.stringify(storage));
  }, [storage]);

  // Derived state
  const today = useMemo(() => new Date().toISOString().split('T')[0], []);

  const isCompletedToday = useCallback((duaId: string) => {
    return storage.completions[today]?.includes(duaId) ?? false;
  }, [storage.completions, today]);

  // Actions
  const markCompleted = useCallback((duaId: string) => {
    setStorage(prev => ({
      ...prev,
      completions: {
        ...prev.completions,
        [today]: [...(prev.completions[today] || []), duaId],
      },
    }));
  }, [today]);

  return { storage, isCompletedToday, markCompleted };
}
```

## Error Handling

```typescript
export function useMyData() {
  return useQuery({
    queryKey: ['my-data'],
    queryFn: async () => {
      try {
        const result = await sql`SELECT * FROM my_table`;
        return result.map(mapToType);
      } catch (error) {
        console.error('Failed to fetch data:', error);
        throw error; // Re-throw for React Query to handle
      }
    },
    retry: 2, // Retry twice on failure
    staleTime: 5 * 60 * 1000, // 5 minutes
  });
}
```
