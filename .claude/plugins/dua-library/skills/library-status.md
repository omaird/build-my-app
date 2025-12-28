---
name: library-status
description: "Show current status of the dua library - counts, categories, journeys, and gaps"
---

# Library Status Skill

Quick overview of the dua library's current state.

## Quick Stats Query

```sql
SELECT
  'Duas' as metric, COUNT(*)::text as value FROM duas
UNION ALL SELECT
  'Journeys', COUNT(*)::text FROM journeys
UNION ALL SELECT
  'Categories', COUNT(*)::text FROM categories
UNION ALL SELECT
  'Avg XP', ROUND(AVG(xp_value))::text FROM duas
UNION ALL SELECT
  'Total XP', SUM(xp_value)::text FROM duas;
```

## Category Breakdown

```sql
SELECT
  c.name,
  COUNT(d.id) as count,
  ROUND(COUNT(d.id) * 100.0 / (SELECT COUNT(*) FROM duas)) as pct
FROM categories c
LEFT JOIN duas d ON c.id = d.category_id
GROUP BY c.id
ORDER BY count DESC;
```

## Journey Summary

```sql
SELECT
  j.emoji || ' ' || j.name as journey,
  COUNT(jd.id) as duas,
  j.daily_xp as xp
FROM journeys j
LEFT JOIN journey_duas jd ON j.id = jd.journey_id
GROUP BY j.id
ORDER BY j.is_featured DESC, j.name;
```

## Roadmap Progress

Compare against targets:
- Phase 1 (MVP): 15 duas
- Phase 2 (Extended): 35 duas
- Phase 3 (Specialized): 50+ duas

```sql
SELECT
  COUNT(*) as current,
  15 as phase1_target,
  35 as phase2_target,
  50 as phase3_target,
  ROUND(COUNT(*) * 100.0 / 15) as phase1_pct,
  ROUND(COUNT(*) * 100.0 / 35) as phase2_pct,
  ROUND(COUNT(*) * 100.0 / 50) as phase3_pct
FROM duas;
```

## Status Display Format

```
📿 DUA LIBRARY STATUS
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

📊 Overview
   Duas:      [X]
   Journeys:  [X]
   Total XP:  [X]

📂 By Category
   🌅 Morning:   [X]
   🌙 Evening:   [X]
   💰 Rizq:      [X]
   🙏 Gratitude: [X]

🗺️ Journeys
   💰 Rizq Seeker      [X] duas
   🌅 Morning Warrior  [X] duas
   💳 Debt Freedom     [X] duas
   🌙 Evening Peace    [X] duas
   🙏 Gratitude Builder [X] duas

📈 Roadmap
   Phase 1: [██████░░░░] [X]/15
   Phase 2: [██░░░░░░░░] [X]/35
   Phase 3: [░░░░░░░░░░] [X]/50

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

## Quick Actions

After showing status, suggest:
1. `/dua-add` - Add a new dua
2. `/journey-create` - Create a new journey
3. `/library-sync` - Sync from documentation
4. `/library-report` - Full detailed report
