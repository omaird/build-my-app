---
name: create-journey
description: "Create a new themed journey (collection of duas) with time-slot assignments"
---

# Create Journey Skill

This skill helps create a new journey with linked duas.

## Journey Structure

A journey consists of:
1. **Journey metadata** - Name, description, emoji, duration, XP
2. **Linked duas** - 4-7 duas with time slots and sort order

## Required Information

### Journey Table
| Field | Required | Description |
|-------|----------|-------------|
| name | ✅ | Journey name (e.g., "Rizq Seeker") |
| slug | ✅ | URL-friendly version (e.g., "rizq-seeker") |
| description | ✅ | 2-3 sentence description |
| emoji | ✅ | Representative emoji |
| estimated_minutes | ✅ | Total time (sum of duas) |
| daily_xp | ✅ | Total XP (sum of duas) |
| is_premium | ❌ | Premium content (default: false) |
| is_featured | ❌ | Show on homepage (default: false) |

### Journey Duas Table
| Field | Required | Description |
|-------|----------|-------------|
| journey_id | ✅ | References journeys.id |
| dua_id | ✅ | References duas.id |
| time_slot | ✅ | morning/anytime/evening |
| sort_order | ✅ | Display order (1, 2, 3...) |

## SQL Templates

### Create Journey
```sql
INSERT INTO journeys (
  name, slug, description, emoji,
  estimated_minutes, daily_xp,
  is_premium, is_featured
) VALUES (
  'Journey Name',
  'journey-slug',
  'Description of this spiritual journey.',
  '🌟',
  10,
  125,
  false,
  true
) RETURNING id;
```

### Link Duas
```sql
INSERT INTO journey_duas (journey_id, dua_id, time_slot, sort_order)
VALUES
  (1, 1, 'morning', 1),
  (1, 2, 'morning', 2),
  (1, 5, 'anytime', 3),
  (1, 6, 'evening', 4),
  (1, 7, 'evening', 5);
```

## Time Slot Guidelines

| Slot | Typical Count | Purpose |
|------|---------------|---------|
| morning | 2-3 | Protection, intention, energy |
| anytime | 1-2 | Flexible, situational |
| evening | 2-3 | Gratitude, reflection, protection |

## Calculating Metrics

```sql
-- Get total XP and duration for selected duas
SELECT
  SUM(xp_value) as total_xp,
  SUM(est_duration_sec) / 60.0 as total_minutes
FROM duas
WHERE id IN (1, 2, 5, 6, 7);
```

## Verification

After creation:
```sql
SELECT
  j.name,
  j.daily_xp,
  COUNT(jd.id) as dua_count,
  SUM(d.xp_value) as calculated_xp
FROM journeys j
LEFT JOIN journey_duas jd ON j.id = jd.journey_id
LEFT JOIN duas d ON jd.dua_id = d.id
WHERE j.id = [new_id]
GROUP BY j.id;
```
