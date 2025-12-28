---
name: new-hook
description: "Create a new custom React hook following RIZQ patterns"
---

# New Hook Command

Create a new custom hook following RIZQ App patterns.

## Usage

```
/new-hook [hookName] [--type=query|mutation|state|computed]
```

## Hook Types

### Query Hook (React Query)

For fetching data from the database:

```typescript
// src/hooks/use[Entity]s.ts
import { useQuery } from '@tanstack/react-query';
import { getSql } from '@/lib/db';
import type { [Entity] } from '@/types/[entity]';

function mapDbTo[Entity](row: any): [Entity] {
  return {
    id: row.id,
    name: row.name,
    // Map snake_case → camelCase
  };
}

export function use[Entity]s() {
  const sql = getSql();

  return useQuery({
    queryKey: ['[entities]'],
    queryFn: async (): Promise<[Entity][]> => {
      const result = await sql`
        SELECT * FROM [entities]
        ORDER BY created_at DESC
      `;
      return result.map(mapDbTo[Entity]);
    },
  });
}

// Single entity by ID
export function use[Entity](id: number | undefined) {
  const sql = getSql();

  return useQuery({
    queryKey: ['[entities]', id],
    queryFn: async (): Promise<[Entity] | null> => {
      if (!id) return null;
      const result = await sql`
        SELECT * FROM [entities] WHERE id = ${id}
      `;
      return result.length > 0 ? mapDbTo[Entity](result[0]) : null;
    },
    enabled: !!id,
  });
}
```

### Mutation Hook

For creating, updating, or deleting data:

```typescript
// src/hooks/use[Action][Entity].ts
import { useMutation, useQueryClient } from '@tanstack/react-query';
import { getSql } from '@/lib/db';
import { useAuth } from '@/contexts/AuthContext';

interface Create[Entity]Input {
  name: string;
  // ... other fields
}

export function useCreate[Entity]() {
  const { user } = useAuth();
  const sql = getSql();
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: async (input: Create[Entity]Input) => {
      const [result] = await sql`
        INSERT INTO [entities] (name, user_id)
        VALUES (${input.name}, ${user?.id}::uuid)
        RETURNING *
      `;
      return result;
    },
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['[entities]'] });
    },
  });
}

export function useDelete[Entity]() {
  const sql = getSql();
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: async (id: number) => {
      await sql`DELETE FROM [entities] WHERE id = ${id}`;
    },
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['[entities]'] });
    },
  });
}
```

### State Hook (localStorage)

For persistent client-side state:

```typescript
// src/hooks/use[Feature]State.ts
import { useState, useEffect, useCallback } from 'react';

const STORAGE_KEY = 'rizq_[feature]';

interface [Feature]State {
  selectedId: number | null;
  preferences: Record<string, boolean>;
  // ... other state
}

const defaultState: [Feature]State = {
  selectedId: null,
  preferences: {},
};

export function use[Feature]State() {
  const [state, setState] = useState<[Feature]State>(() => {
    try {
      const stored = localStorage.getItem(STORAGE_KEY);
      return stored ? JSON.parse(stored) : defaultState;
    } catch {
      return defaultState;
    }
  });

  // Persist to localStorage
  useEffect(() => {
    localStorage.setItem(STORAGE_KEY, JSON.stringify(state));
  }, [state]);

  // Actions
  const setSelectedId = useCallback((id: number | null) => {
    setState(prev => ({ ...prev, selectedId: id }));
  }, []);

  const setPreference = useCallback((key: string, value: boolean) => {
    setState(prev => ({
      ...prev,
      preferences: { ...prev.preferences, [key]: value },
    }));
  }, []);

  const reset = useCallback(() => {
    setState(defaultState);
  }, []);

  return {
    ...state,
    setSelectedId,
    setPreference,
    reset,
  };
}
```

### Computed Hook

For derived/computed values:

```typescript
// src/hooks/use[Computed].ts
import { useMemo } from 'react';
import { useAuth } from '@/contexts/AuthContext';

interface [Computed]Result {
  // ... computed values
}

export function use[Computed](): [Computed]Result {
  const { profile } = useAuth();

  return useMemo(() => {
    if (!profile) {
      return {
        // Default values
      };
    }

    // Compute derived values
    const level = profile.level;
    const xpToNext = calculateXpToNextLevel(profile.totalXp);
    const streakStatus = getStreakStatus(profile.lastActiveDate, profile.streak);

    return {
      level,
      xpToNext,
      streakStatus,
      // ... other computed values
    };
  }, [profile]);
}
```

## File Naming

| Hook Type | Naming Pattern | Example |
|-----------|----------------|---------|
| Query (list) | `use[Entity]s` | `useDuas`, `useJourneys` |
| Query (single) | `use[Entity]` | `useDua(id)` |
| Query (filtered) | `use[Entity]sBy[Field]` | `useDuasByCategory` |
| Mutation | `use[Action][Entity]` | `useCreateDua`, `useDeleteJourney` |
| State | `use[Feature]State` | `useHabitState` |
| Computed | `use[Description]` | `useStreakStatus`, `useProgress` |

## Checklist

- [ ] Proper TypeScript types for input/output
- [ ] Uses correct React Query hooks
- [ ] Query keys follow conventions
- [ ] Handles loading/error states
- [ ] Uses `enabled` when conditional
- [ ] Invalidates related queries on mutation
- [ ] Uses `useCallback` for action functions
- [ ] Uses `useMemo` for computed values
