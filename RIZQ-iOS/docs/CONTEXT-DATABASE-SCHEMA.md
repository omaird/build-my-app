# Database Schema Reference

This document provides a complete reference of the Neon PostgreSQL database schema used by RIZQ.

---

## Entity Relationship Diagram

```
┌─────────────┐     ┌─────────────┐     ┌─────────────┐
│ categories  │     │    duas     │     │ collections │
├─────────────┤     ├─────────────┤     ├─────────────┤
│ id (PK)     │◄────│ category_id │────►│ id (PK)     │
│ name        │     │ collection_id│    │ name        │
│ slug        │     │ id (PK)     │     │ slug        │
│ description │     │ title_en    │     │ description │
└─────────────┘     │ arabic_text │     │ is_premium  │
                    │ ...         │     └─────────────┘
                    └──────┬──────┘
                           │
                           │
┌─────────────┐     ┌──────┴──────┐
│  journeys   │     │ journey_duas│
├─────────────┤     ├─────────────┤
│ id (PK)     │◄────│ journey_id  │
│ name        │     │ dua_id      │────►(duas.id)
│ slug        │     │ time_slot   │
│ emoji       │     │ sort_order  │
│ daily_xp    │     └─────────────┘
│ ...         │
└─────────────┘

┌─────────────────┐     ┌─────────────────┐     ┌─────────────────┐
│  user_profiles  │     │  user_activity  │     │  user_progress  │
├─────────────────┤     ├─────────────────┤     ├─────────────────┤
│ id (PK)         │     │ id (PK)         │     │ id (PK)         │
│ user_id (UUID)  │◄────│ user_id (UUID)  │     │ user_id (UUID)  │
│ display_name    │     │ date            │     │ dua_id          │────►(duas.id)
│ streak          │     │ duas_completed[]│     │ completed_count │
│ total_xp        │     │ xp_earned       │     │ last_completed  │
│ level           │     └─────────────────┘     └─────────────────┘
│ last_active_date│
│ is_admin        │
└─────────────────┘
```

---

## Table Definitions

### categories

| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| `id` | SERIAL | PRIMARY KEY | Auto-increment ID |
| `name` | VARCHAR(255) | UNIQUE, NOT NULL | Display name |
| `slug` | VARCHAR(255) | UNIQUE | URL-safe identifier |
| `description` | TEXT | | Optional description |

**Values**: morning, evening, rizq, gratitude

---

### collections

| Column | Type | Constraints | Default | Description |
|--------|------|-------------|---------|-------------|
| `id` | SERIAL | PRIMARY KEY | | Auto-increment ID |
| `name` | VARCHAR(255) | UNIQUE, NOT NULL | | Display name |
| `slug` | VARCHAR(255) | UNIQUE | | URL-safe identifier |
| `description` | TEXT | | | Optional description |
| `is_premium` | BOOLEAN | | FALSE | Premium tier flag |

**Values**: core, extended, specialized

---

### duas

| Column | Type | Constraints | Default | Description |
|--------|------|-------------|---------|-------------|
| `id` | SERIAL | PRIMARY KEY | | Auto-increment ID |
| `category_id` | INTEGER | FK → categories.id | | Category reference |
| `collection_id` | INTEGER | FK → collections.id | | Collection reference |
| `title_en` | VARCHAR(255) | NOT NULL | | English title |
| `title_ar` | VARCHAR(255) | | | Arabic title |
| `arabic_text` | TEXT | NOT NULL | | Full Arabic dua text |
| `transliteration` | TEXT | | | Phonetic transliteration |
| `translation_en` | TEXT | | | English translation |
| `source` | VARCHAR(255) | | | Hadith/Quran reference |
| `repetitions` | INTEGER | | 1 | Recommended repeat count |
| `best_time` | VARCHAR(255) | | | morning/anytime/evening |
| `difficulty` | VARCHAR(50) | | | Beginner/Intermediate/Advanced |
| `est_duration_sec` | INTEGER | | | Estimated seconds to recite |
| `rizq_benefit` | TEXT | | | Benefit for provision |
| `context` | TEXT | | | Story/background narrative |
| `prophetic_context` | TEXT | | | Prophet's guidance on dua |
| `xp_value` | INTEGER | | 10 | XP awarded on completion |
| `audio_url` | VARCHAR(255) | | | Audio recitation URL |
| `created_at` | TIMESTAMP WITH TZ | | NOW() | Creation timestamp |
| `updated_at` | TIMESTAMP WITH TZ | | NOW() | Last update timestamp |

**Indexes**:
- `idx_duas_category_id` ON (category_id)
- `idx_duas_collection_id` ON (collection_id)

---

### journeys

| Column | Type | Constraints | Default | Description |
|--------|------|-------------|---------|-------------|
| `id` | SERIAL | PRIMARY KEY | | Auto-increment ID |
| `name` | VARCHAR(255) | NOT NULL | | Display name |
| `slug` | VARCHAR(100) | UNIQUE | | URL-safe identifier |
| `description` | TEXT | | | Journey description |
| `emoji` | VARCHAR(255) | | '📿' | Emoji icon or image path |
| `estimated_minutes` | INTEGER | | 15 | Daily time estimate |
| `daily_xp` | INTEGER | | 100 | XP available per day |
| `is_premium` | BOOLEAN | | FALSE | Premium tier flag |
| `is_featured` | BOOLEAN | | FALSE | Featured on home |
| `sort_order` | INTEGER | | 0 | Display order |
| `created_at` | TIMESTAMP WITH TZ | | NOW() | Creation timestamp |

**Indexes**:
- `idx_journeys_slug` ON (slug)
- `idx_journeys_featured` ON (is_featured) WHERE is_featured = TRUE

---

### journey_duas

| Column | Type | Constraints | Default | Description |
|--------|------|-------------|---------|-------------|
| `id` | SERIAL | PRIMARY KEY | | Auto-increment ID |
| `journey_id` | INTEGER | FK → journeys.id (CASCADE) | | Journey reference |
| `dua_id` | INTEGER | FK → duas.id (CASCADE) | | Dua reference |
| `time_slot` | VARCHAR(50) | | | morning/anytime/evening |
| `sort_order` | INTEGER | | 0 | Order within time slot |

**Constraints**:
- UNIQUE(journey_id, dua_id) - No duplicate duas in journey

**Indexes**:
- `idx_journey_duas_journey_id` ON (journey_id)
- `idx_journey_duas_dua_id` ON (dua_id)

---

### user_profiles

| Column | Type | Constraints | Default | Description |
|--------|------|-------------|---------|-------------|
| `id` | SERIAL | PRIMARY KEY | | Auto-increment ID |
| `user_id` | UUID | UNIQUE, NOT NULL | | Auth user reference |
| `display_name` | VARCHAR(255) | | | User's display name |
| `streak` | INTEGER | | 0 | Current streak days |
| `total_xp` | INTEGER | | 0 | Lifetime XP earned |
| `level` | INTEGER | | 1 | Current level |
| `last_active_date` | DATE | | | Last activity date |
| `is_admin` | BOOLEAN | | FALSE | Admin privileges |
| `created_at` | TIMESTAMP WITH TZ | | NOW() | Account creation |
| `updated_at` | TIMESTAMP WITH TZ | | NOW() | Last profile update |

**Indexes**:
- `idx_user_profiles_user_id` ON (user_id)
- `idx_user_profiles_is_admin` ON (is_admin) WHERE is_admin = TRUE

---

### user_activity

| Column | Type | Constraints | Default | Description |
|--------|------|-------------|---------|-------------|
| `id` | SERIAL | PRIMARY KEY | | Auto-increment ID |
| `user_id` | UUID | NOT NULL | | Auth user reference |
| `date` | DATE | NOT NULL | | Activity date |
| `duas_completed` | INTEGER[] | | {} | Array of dua IDs |
| `xp_earned` | INTEGER | | 0 | XP earned that day |

**Constraints**:
- UNIQUE(user_id, date) - One row per user per day

**Indexes**:
- `idx_user_activity_user_id` ON (user_id)
- `idx_user_activity_date` ON (date)

---

### user_progress

| Column | Type | Constraints | Default | Description |
|--------|------|-------------|---------|-------------|
| `id` | SERIAL | PRIMARY KEY | | Auto-increment ID |
| `user_id` | UUID | NOT NULL | | Auth user reference |
| `dua_id` | INTEGER | FK → duas.id (CASCADE) | | Dua reference |
| `completed_count` | INTEGER | | 0 | Lifetime completions |
| `last_completed` | DATE | | | Most recent completion |
| `updated_at` | TIMESTAMP WITH TZ | | NOW() | Last update |

**Constraints**:
- UNIQUE(user_id, dua_id) - One row per user per dua

**Indexes**:
- `idx_user_progress_user_id` ON (user_id)
- `idx_user_progress_dua_id` ON (dua_id)

---

## Common Queries

### Fetch All Duas with Relations

```sql
SELECT d.*,
  c.name as category_name,
  c.slug as category_slug,
  col.name as collection_name,
  col.slug as collection_slug
FROM duas d
LEFT JOIN categories c ON d.category_id = c.id
LEFT JOIN collections col ON d.collection_id = col.id
ORDER BY d.id;
```

### Fetch Journey with Duas

```sql
SELECT
  jd.dua_id, jd.time_slot, jd.sort_order,
  d.id, d.title_en, d.title_ar, d.arabic_text,
  d.transliteration, d.translation_en, d.source,
  d.repetitions, d.xp_value, d.rizq_benefit,
  d.prophetic_context, d.difficulty,
  c.slug as category_slug
FROM journey_duas jd
JOIN duas d ON jd.dua_id = d.id
LEFT JOIN categories c ON d.category_id = c.id
WHERE jd.journey_id = $1
ORDER BY jd.sort_order ASC;
```

### Fetch Multiple Journeys' Duas

```sql
SELECT
  jd.journey_id, jd.dua_id, jd.time_slot, jd.sort_order,
  d.title_en, d.xp_value, d.repetitions,
  c.slug as category_slug
FROM journey_duas jd
JOIN duas d ON jd.dua_id = d.id
LEFT JOIN categories c ON d.category_id = c.id
WHERE jd.journey_id = ANY($1::int[])
ORDER BY jd.sort_order ASC;
```

### Record Dua Completion (Upsert)

```sql
INSERT INTO user_activity (user_id, date, duas_completed, xp_earned)
VALUES ($1::uuid, $2::date, ARRAY[$3], $4)
ON CONFLICT (user_id, date)
DO UPDATE SET
  duas_completed = array_append(user_activity.duas_completed, $3),
  xp_earned = user_activity.xp_earned + $4;
```

### Update User Progress (Upsert)

```sql
INSERT INTO user_progress (user_id, dua_id, completed_count, last_completed)
VALUES ($1::uuid, $2, 1, $3::date)
ON CONFLICT (user_id, dua_id)
DO UPDATE SET
  completed_count = user_progress.completed_count + 1,
  last_completed = $3::date,
  updated_at = NOW();
```

### Get User Profile with Level Calculation

```sql
SELECT *,
  CASE
    WHEN total_xp < 100 THEN 1
    WHEN total_xp < 300 THEN 2
    WHEN total_xp < 600 THEN 3
    ELSE FLOOR((-1 + SQRT(1 + 8 * total_xp / 50)) / 2)::int
  END as calculated_level
FROM user_profiles
WHERE user_id = $1::uuid;
```

---

## Seed Data Summary

### Categories (4 rows)
| id | name | slug |
|----|------|------|
| 1 | Morning | morning |
| 2 | Evening | evening |
| 3 | Rizq | rizq |
| 4 | Gratitude | gratitude |

### Collections (3 rows)
| id | name | slug | is_premium |
|----|------|------|------------|
| 1 | Core | core | false |
| 2 | Extended | extended | false |
| 3 | Specialized | specialized | false |

### Duas (10 rows)
| id | title_en | category | xp_value |
|----|----------|----------|----------|
| 1 | Ayatul Kursi | evening | 50 |
| 2 | Morning Protection | morning | 30 |
| 3 | Dua Upon Leaving Home | morning | 15 |
| 4 | Sayyidul Istighfar | rizq | 40 |
| 5 | Dua for Halal Provision | rizq | 25 |
| 6 | Evening Protection | evening | 30 |
| 7 | Dua for Relief from Debt | rizq | 35 |
| 8 | Dua for Beneficial Knowledge | morning | 30 |
| 9 | Dua for Barakah | gratitude | 15 |
| 10 | Dua of Prophet Yunus | rizq | 25 |

### Journeys (14 rows)
| id | name | emoji | daily_xp | is_featured |
|----|------|-------|----------|-------------|
| 1 | Rizq Seeker | 💎 | 270 | true |
| 2 | Morning Warrior | 🌅 | 250 | true |
| 3 | Debt Freedom | 💳 | 125 | true |
| 4 | Evening Guardian | 🌙 | 200 | false |
| ... | ... | ... | ... | ... |

---

## Notes

1. **UUID Casting**: Always cast user IDs with `::uuid` in queries
2. **Array Operations**: PostgreSQL arrays use `ARRAY[]` syntax and `array_append()`
3. **Timestamps**: Use `TIMESTAMP WITH TIME ZONE` for proper timezone handling
4. **Cascade Deletes**: journey_duas and user_progress cascade on parent delete
5. **Indexes**: Critical for performance on user_id and foreign key columns
