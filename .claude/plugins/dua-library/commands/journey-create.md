---
name: journey-create
description: "Interactive command to create a new journey (themed collection of duas)"
---

# Create Journey Command

You are helping the user create a new journey for the RIZQ App. A journey is a curated path of daily duas organized around a theme.

## Step 1: Define the Journey

Use AskUserQuestion to gather:

1. **Journey Name** - A compelling, descriptive name
   - Examples: "Rizq Seeker", "Morning Warrior", "Debt Freedom Path"

2. **Description** - 2-3 sentences explaining the journey's purpose and benefit

3. **Emoji** - A single emoji that represents the theme
   - 💰 for wealth, 🌅 for morning, 🙏 for gratitude, etc.

4. **Premium Status** - Is this a premium journey?

5. **Featured Status** - Should it be highlighted on the journeys page?

## Step 2: Select Duas

Query available duas:
```sql
SELECT
  id,
  title_en,
  difficulty,
  xp_value,
  best_time,
  (SELECT name FROM categories WHERE id = category_id) as category
FROM duas
ORDER BY category, title_en;
```

Present the list and ask the user to select 4-7 duas for the journey.

## Step 3: Assign Time Slots

For each selected dua, ask which time slot it belongs to:
- **morning** - After Fajr prayers
- **anytime** - Throughout the day
- **evening** - After Maghrib prayers

Aim for balance:
- 2-3 morning duas
- 1-2 anytime duas
- 2-3 evening duas

## Step 4: Calculate Metrics

Based on selections:
- **estimated_minutes**: Sum of est_duration_sec / 60, rounded up
- **daily_xp**: Sum of all dua xp_values

## Step 5: Preview Journey

```
🌟 New Journey Preview
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

[Emoji] [Journey Name]
[Description]

📊 Stats:
• Duas: [count]
• Duration: ~[X] minutes
• Daily XP: [total_xp]
• Premium: [Yes/No]
• Featured: [Yes/No]

📅 Daily Schedule:

🌅 Morning
  1. [Dua Title] ([XP] XP)
  2. [Dua Title] ([XP] XP)

⏰ Anytime
  3. [Dua Title] ([XP] XP)

🌙 Evening
  4. [Dua Title] ([XP] XP)
  5. [Dua Title] ([XP] XP)

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

Ask for confirmation.

## Step 6: Create Journey

```sql
-- Insert the journey
INSERT INTO journeys (
  name,
  slug,
  description,
  emoji,
  estimated_minutes,
  daily_xp,
  is_premium,
  is_featured
) VALUES (
  '[name]',
  '[slug-from-name]',
  '[description]',
  '[emoji]',
  [estimated_minutes],
  [daily_xp],
  [is_premium],
  [is_featured]
) RETURNING id;
```

Then link the duas:
```sql
INSERT INTO journey_duas (journey_id, dua_id, time_slot, sort_order)
VALUES
  ([journey_id], [dua1_id], 'morning', 1),
  ([journey_id], [dua2_id], 'morning', 2),
  ([journey_id], [dua3_id], 'anytime', 3),
  ([journey_id], [dua4_id], 'evening', 4),
  ([journey_id], [dua5_id], 'evening', 5);
```

## Step 7: Confirm Success

```
✅ Journey Created Successfully!

[Emoji] [Journey Name]
ID: [journey_id]

The journey is now available with [X] duas.

Users can now:
• Browse it on the Journeys page
• Subscribe to add it to their daily routine
• Start earning [daily_xp] XP per day!

Would you like to:
1. Create another journey?
2. View all journeys?
3. Edit this journey?
```

## Slug Generation

Convert journey name to URL-friendly slug:
- Lowercase all letters
- Replace spaces with hyphens
- Remove special characters
- Example: "Rizq Seeker's Path" → "rizq-seekers-path"
