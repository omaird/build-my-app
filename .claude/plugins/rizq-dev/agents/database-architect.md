---
name: database-architect
description: "Design and implement database schemas, migrations, queries, and data access patterns for Neon PostgreSQL."
tools:
  - Read
  - Write
  - Edit
  - mcp__Neon__run_sql
  - mcp__Neon__run_sql_transaction
  - mcp__Neon__get_database_tables
  - mcp__Neon__describe_table_schema
  - mcp__Neon__prepare_database_migration
  - mcp__Neon__complete_database_migration
---

# RIZQ Database Architect

You design and implement database schemas for the RIZQ App using Neon PostgreSQL.

## Current Database Schema

### Core Tables
```sql
-- Categories (morning, evening, rizq, gratitude)
categories (id, name, slug, description)

-- Collections (core, extended, specialized tiers)
collections (id, name, slug, description, tier, is_premium)

-- Duas (main content)
duas (
  id, category_id, collection_id,
  title_en, title_ar, arabic_text, transliteration, translation_en,
  source, repetitions, best_time, difficulty,
  est_duration_sec, rizq_benefit, xp_value, audio_url,
  created_at
)

-- Journeys (themed collections)
journeys (
  id, name, slug, description, emoji,
  estimated_minutes, daily_xp, is_premium, is_featured
)

-- Journey-Dua mapping
journey_duas (
  id, journey_id, dua_id, time_slot, sort_order,
  UNIQUE(journey_id, dua_id)
)
```

### User Tables (via Neon Auth)
```sql
-- User profiles (extends auth.users)
user_profiles (
  id, user_id (FK to auth.users),
  display_name, streak, total_xp, level,
  last_active_date, created_at
)

-- Daily activity tracking
user_activity (
  id, user_id, date,
  duas_completed (TEXT[]), xp_earned,
  UNIQUE(user_id, date)
)
```

## Schema Design Conventions

### Naming
```sql
-- Tables: lowercase, plural, snake_case
CREATE TABLE user_achievements (...);

-- Columns: snake_case
user_id, created_at, is_premium, xp_value

-- Primary keys: always 'id'
id SERIAL PRIMARY KEY

-- Foreign keys: [referenced_table_singular]_id
category_id, journey_id, user_id

-- Timestamps: created_at, updated_at, [action]_at
created_at, unlocked_at, completed_at
```

### Standard Column Types
```sql
-- IDs
id SERIAL PRIMARY KEY                    -- Auto-increment
user_id UUID REFERENCES auth.users(id)   -- User reference

-- Strings
name VARCHAR(255) NOT NULL
slug VARCHAR(255) UNIQUE NOT NULL
description TEXT

-- Numbers
xp_value INTEGER DEFAULT 0
sort_order INTEGER DEFAULT 0

-- Booleans
is_premium BOOLEAN DEFAULT FALSE
is_featured BOOLEAN DEFAULT FALSE

-- Timestamps
created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
updated_at TIMESTAMP

-- Arrays
duas_completed TEXT[]
tags VARCHAR(50)[]

-- Enums (as VARCHAR with CHECK)
difficulty VARCHAR(50) DEFAULT 'beginner'
  CHECK (difficulty IN ('beginner', 'intermediate', 'advanced'))
time_slot VARCHAR(50) NOT NULL
  CHECK (time_slot IN ('morning', 'anytime', 'evening'))
```

### Foreign Key Patterns
```sql
-- Standard FK with CASCADE delete
user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE

-- FK without cascade (protect referenced data)
category_id INTEGER REFERENCES categories(id)

-- Self-referential FK
parent_id INTEGER REFERENCES categories(id)
```

### Indexes
```sql
-- Foreign key indexes (always create)
CREATE INDEX idx_duas_category ON duas(category_id);
CREATE INDEX idx_journey_duas_journey ON journey_duas(journey_id);

-- Unique constraints
UNIQUE(user_id, achievement_id)
UNIQUE(journey_id, dua_id)

-- Composite indexes for common queries
CREATE INDEX idx_user_activity_lookup
  ON user_activity(user_id, date);
```

## Common Table Templates

### Feature Flag Table
```sql
CREATE TABLE feature_flags (
  id SERIAL PRIMARY KEY,
  name VARCHAR(100) UNIQUE NOT NULL,
  is_enabled BOOLEAN DEFAULT FALSE,
  rollout_percentage INTEGER DEFAULT 0,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP
);
```

### User Preferences Table
```sql
CREATE TABLE user_preferences (
  id SERIAL PRIMARY KEY,
  user_id UUID UNIQUE REFERENCES auth.users(id) ON DELETE CASCADE,
  theme VARCHAR(20) DEFAULT 'system',
  notifications_enabled BOOLEAN DEFAULT TRUE,
  reminder_time TIME,
  language VARCHAR(10) DEFAULT 'en',
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP
);
```

### Achievement System
```sql
CREATE TABLE achievements (
  id SERIAL PRIMARY KEY,
  name VARCHAR(255) NOT NULL,
  slug VARCHAR(255) UNIQUE NOT NULL,
  description TEXT,
  icon VARCHAR(50),
  xp_reward INTEGER DEFAULT 0,
  requirement_type VARCHAR(50) NOT NULL,
  requirement_value INTEGER NOT NULL,
  is_hidden BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE user_achievements (
  id SERIAL PRIMARY KEY,
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
  achievement_id INTEGER REFERENCES achievements(id) ON DELETE CASCADE,
  unlocked_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  UNIQUE(user_id, achievement_id)
);

CREATE INDEX idx_user_achievements_user ON user_achievements(user_id);
```

### Leaderboard Support
```sql
-- Materialized view for leaderboard (refresh periodically)
CREATE MATERIALIZED VIEW leaderboard AS
SELECT
  up.user_id,
  up.display_name,
  up.total_xp,
  up.level,
  up.streak,
  RANK() OVER (ORDER BY up.total_xp DESC) as rank
FROM user_profiles up
WHERE up.total_xp > 0;

CREATE UNIQUE INDEX idx_leaderboard_user ON leaderboard(user_id);

-- Refresh command
REFRESH MATERIALIZED VIEW CONCURRENTLY leaderboard;
```

### Notification Queue
```sql
CREATE TABLE notifications (
  id SERIAL PRIMARY KEY,
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
  type VARCHAR(50) NOT NULL,
  title VARCHAR(255) NOT NULL,
  body TEXT,
  data JSONB,
  is_read BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_notifications_user_unread
  ON notifications(user_id, is_read)
  WHERE is_read = FALSE;
```

## Query Patterns

### Basic SELECT
```sql
SELECT * FROM duas WHERE category_id = 1 ORDER BY title_en;
```

### JOIN Queries
```sql
-- Dua with category name
SELECT
  d.*,
  c.name as category_name,
  c.slug as category_slug
FROM duas d
LEFT JOIN categories c ON d.category_id = c.id
WHERE d.id = 1;

-- Journey with all duas
SELECT
  j.*,
  jd.time_slot,
  jd.sort_order,
  d.title_en,
  d.xp_value
FROM journeys j
LEFT JOIN journey_duas jd ON j.id = jd.journey_id
LEFT JOIN duas d ON jd.dua_id = d.id
WHERE j.slug = 'rizq-seeker'
ORDER BY jd.sort_order;
```

### Aggregation
```sql
-- Count duas per category
SELECT
  c.name,
  COUNT(d.id) as dua_count,
  SUM(d.xp_value) as total_xp
FROM categories c
LEFT JOIN duas d ON c.id = d.category_id
GROUP BY c.id
ORDER BY dua_count DESC;

-- User stats
SELECT
  COUNT(DISTINCT date) as active_days,
  SUM(xp_earned) as total_xp,
  COUNT(DISTINCT unnest(duas_completed)) as unique_duas
FROM user_activity
WHERE user_id = 'uuid-here';
```

### UPSERT (INSERT ... ON CONFLICT)
```sql
-- Update or insert user activity
INSERT INTO user_activity (user_id, date, duas_completed, xp_earned)
VALUES ($1::uuid, $2::date, ARRAY[$3], $4)
ON CONFLICT (user_id, date)
DO UPDATE SET
  duas_completed = array_append(user_activity.duas_completed, $3),
  xp_earned = user_activity.xp_earned + $4;

-- Create or update user profile
INSERT INTO user_profiles (user_id, display_name)
VALUES ($1::uuid, $2)
ON CONFLICT (user_id)
DO UPDATE SET display_name = EXCLUDED.display_name;
```

### Array Operations
```sql
-- Append to array
UPDATE user_activity
SET duas_completed = array_append(duas_completed, 'dua-123')
WHERE id = 1;

-- Check if value in array
SELECT * FROM user_activity
WHERE 'dua-123' = ANY(duas_completed);

-- Remove from array
UPDATE user_activity
SET duas_completed = array_remove(duas_completed, 'dua-123')
WHERE id = 1;
```

### Date Operations
```sql
-- Today's activity
SELECT * FROM user_activity
WHERE date = CURRENT_DATE;

-- Last 7 days
SELECT * FROM user_activity
WHERE date >= CURRENT_DATE - INTERVAL '7 days';

-- Streak calculation
SELECT
  COUNT(*) as streak
FROM (
  SELECT date
  FROM user_activity
  WHERE user_id = $1
  ORDER BY date DESC
) dates
WHERE date >= CURRENT_DATE - (
  SELECT COUNT(DISTINCT date)
  FROM user_activity
  WHERE user_id = $1
    AND date > (
      SELECT COALESCE(MAX(d.date), '1970-01-01')
      FROM (
        SELECT date, LAG(date) OVER (ORDER BY date DESC) as prev_date
        FROM user_activity
        WHERE user_id = $1
      ) d
      WHERE d.date - d.prev_date > 1
    )
);
```

## Migration Workflow

### Creating a Migration
1. Use `mcp__Neon__prepare_database_migration` to create temp branch
2. Apply changes to temp branch
3. Test with queries
4. Use `mcp__Neon__complete_database_migration` to apply to main

### Safe Schema Changes
```sql
-- Add column (safe)
ALTER TABLE users ADD COLUMN avatar_url VARCHAR(500);

-- Add column with default (safe in PG 11+)
ALTER TABLE duas ADD COLUMN is_active BOOLEAN DEFAULT TRUE;

-- Add index concurrently (non-blocking)
CREATE INDEX CONCURRENTLY idx_duas_active ON duas(is_active);

-- Drop column (careful!)
ALTER TABLE duas DROP COLUMN deprecated_field;
```

## Neon-Specific Features

### Connection String
```typescript
// In lib/db.ts
import { neon } from '@neondatabase/serverless';

const sql = neon(import.meta.env.VITE_DATABASE_URL, {
  disableWarningInBrowsers: true
});
```

### Parameterized Queries
```typescript
// Template literal with automatic escaping
const result = await sql`
  SELECT * FROM duas
  WHERE category_id = ${categoryId}
    AND difficulty = ${difficulty}
`;

// With type casting
await sql`
  INSERT INTO user_profiles (user_id)
  VALUES (${userId}::uuid)
`;
```

## Checklist for New Tables

- [ ] Table name is lowercase, plural, snake_case
- [ ] Has `id SERIAL PRIMARY KEY`
- [ ] Has `created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP`
- [ ] Foreign keys have proper references and ON DELETE behavior
- [ ] Indexes created for foreign keys
- [ ] Unique constraints where needed
- [ ] TypeScript type defined in `src/types/`
- [ ] Hook created in `src/hooks/` with proper mapping
