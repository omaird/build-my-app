---
name: journey-create-firebase
description: "Interactive command to create a new journey in Firebase with guided prompts"
---

# Create Journey in Firebase Command

You are helping the user create a new themed journey (dua collection) in Firebase Firestore. Guide them through the process step by step.

## Step 1: Check Current State

Query Firebase to:
1. Find the highest existing journey ID
2. Get the list of available duas to choose from

## Step 2: Gather Journey Details

Use AskUserQuestion to collect:

### Required Fields
1. **Name** - Display name for the journey (e.g., "Rizq Seeker")
2. **Slug** - URL-friendly identifier (e.g., "rizq-seeker")
3. **Description** - What this journey helps users achieve
4. **Emoji** - Representative emoji (e.g., 💰, 🌅, 🌙)

### Optional Fields
5. **Is Premium** - Premium content flag (default: false)
6. **Is Featured** - Show on home page (default: false)
7. **Sort Order** - Display order (default: next available)

## Step 3: Select Duas for Journey

Show available duas grouped by category:

```
📿 Available Duas
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Morning (Category 1):
  [1] Morning Dhikr (10 XP)
  [2] Seeking Protection (15 XP)
  ...

Evening (Category 2):
  [5] Evening Protection (10 XP)
  [6] Ayatul Kursi (25 XP)
  ...

Rizq (Category 3):
  [3] Seeking Rizq (20 XP)
  [7] Istighfar for Rizq (15 XP)
  ...

Gratitude (Category 4):
  [4] Gratitude Upon Waking (10 XP)
  [9] Praising Allah (20 XP)
  ...

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

Ask user to select dua IDs to include.

## Step 4: Assign Time Slots

For each selected dua, assign a time slot:
- **morning** - For duas best recited after Fajr
- **anytime** - For duas that can be recited throughout the day
- **evening** - For duas best recited after Maghrib

Suggest time slots based on dua's bestTime field.

## Step 5: Calculate Totals

Calculate and display:
- **Daily XP**: Sum of all dua XP values
- **Estimated Minutes**: Based on duration and repetitions

```
Journey Statistics:
  - Total Duas: X
  - Daily XP: XXX
  - Estimated Time: XX minutes
```

## Step 6: Preview Journey

```
🌟 New Journey Preview
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

[Emoji] [Name]
"[Description]"

ID: [Next ID]
Slug: [slug]
Daily XP: [dailyXp]
Time: ~[estimatedMinutes] minutes
Featured: [Yes/No]
Premium: [Yes/No]

Duas:
┌─────────────────────────────────────┐
│ MORNING                             │
│   1. [Dua Name] (XX XP)             │
│   2. [Dua Name] (XX XP)             │
├─────────────────────────────────────┤
│ ANYTIME                             │
│   3. [Dua Name] (XX XP)             │
├─────────────────────────────────────┤
│ EVENING                             │
│   4. [Dua Name] (XX XP)             │
└─────────────────────────────────────┘

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

Ask for confirmation before proceeding.

## Step 7: Insert into Firebase

Create JSON and use admin script:

```bash
# Create the journey JSON
cat > /tmp/new-journey.json << 'EOF'
{
  "journey": {
    "id": [id],
    "name": "[name]",
    "slug": "[slug]",
    "description": "[description]",
    "emoji": "[emoji]",
    "estimatedMinutes": [estimatedMinutes],
    "dailyXp": [dailyXp],
    "isPremium": [isPremium],
    "isFeatured": [isFeatured],
    "sortOrder": [sortOrder]
  },
  "journeyDuas": [
    { "journeyId": [id], "duaId": [duaId], "timeSlot": "[timeSlot]", "sortOrder": 1 },
    ...
  ]
}
EOF

# Run the add script
cd /Users/omairdawood/Projects/RIZQ\ App && node scripts/add-journey.cjs /tmp/new-journey.json
```

## Step 8: Confirm Success

```
✅ Journey Created Successfully in Firebase!

ID: [journey_id]
Name: [name]
Slug: [slug]

Collections updated:
  - journeys: 1 document added
  - journey_duas: [X] documents added

The journey is now available in the app!

Would you like to:
1. Feature this journey on the home page?
2. Create another journey?
3. View the library status?
```

## Error Handling

If creation fails:
- Check for duplicate journey IDs or slugs
- Verify all dua IDs exist
- Ensure Firebase Admin SDK is configured
- Check service account credentials
- Report specific error to user

## Best Practices

- Include 3-5 duas per journey
- Mix difficulty levels for progression
- Balance time slots (don't overload one)
- Write compelling descriptions
- Choose relevant emojis
