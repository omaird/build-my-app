---
name: create-journey
description: "Create a new themed journey (collection of duas) with time-slot assignments in Firebase Firestore"
---

# Create Journey Skill

This skill helps create a new journey with linked duas in Firebase Firestore.

## Journey Structure

A journey consists of:
1. **Journey metadata** - Name, description, emoji, duration, XP
2. **Linked duas** - 4-7 duas with time slots and sort order

## Firestore Schema

### Journeys Collection
```javascript
{
  id: number,              // Sequential ID
  name: string,            // "Rizq Seeker"
  slug: string,            // "rizq-seeker"
  description: string,     // 2-3 sentence description
  emoji: string,           // "💰"
  estimatedMinutes: number, // Total time (sum of duas)
  dailyXp: number,         // Total XP (sum of duas)
  isPremium: boolean,      // Premium content (default: false)
  isFeatured: boolean,     // Show on homepage (default: false)
  sortOrder: number        // Display order
}
```

### Journey Duas Collection
```javascript
{
  // Document ID format: "{journeyId}_{duaId}"
  journeyId: number,
  duaId: number,
  timeSlot: string,  // "morning", "anytime", "evening"
  sortOrder: number  // Display order (1, 2, 3...)
}
```

## Required Information

| Field | Required | Description |
|-------|----------|-------------|
| name | Yes | Journey name (e.g., "Rizq Seeker") |
| slug | Yes | URL-friendly version (e.g., "rizq-seeker") |
| description | Yes | 2-3 sentence description |
| emoji | Yes | Representative emoji |
| estimatedMinutes | Yes | Total time (sum of duas) |
| dailyXp | Yes | Total XP (sum of duas) |
| isPremium | No | Premium content (default: false) |
| isFeatured | No | Show on homepage (default: false) |

## Creation Process

### Step 1: Query Available Duas

Query the `duas` collection to see available duas:
- Get all duas
- Note their IDs, titles, categories, and XP values

### Step 2: Select Duas for Journey

Choose 4-7 duas that fit the journey theme:
- Consider thematic cohesion
- Balance difficulty levels
- Distribute across time slots

### Step 3: Calculate Metrics

Sum the selected duas' values:
- Total `xpValue` → journey's `dailyXp`
- Total `estDurationSec` / 60 → journey's `estimatedMinutes`

### Step 4: Prepare Journey Data

```javascript
// Add to journeys array in scripts/seed-firestore.cjs
{
  id: 6,  // Next available ID
  name: "Journey Name",
  slug: "journey-slug",
  description: "Description of this spiritual journey.",
  emoji: "🌟",
  estimatedMinutes: 10,
  dailyXp: 125,
  isPremium: false,
  isFeatured: true,
  sortOrder: 5
}
```

### Step 5: Prepare Journey Duas Data

```javascript
// Add to journeyDuas array in scripts/seed-firestore.cjs
{ journeyId: 6, duaId: 1, timeSlot: "morning", sortOrder: 1 },
{ journeyId: 6, duaId: 2, timeSlot: "morning", sortOrder: 2 },
{ journeyId: 6, duaId: 5, timeSlot: "anytime", sortOrder: 3 },
{ journeyId: 6, duaId: 8, timeSlot: "evening", sortOrder: 4 },
{ journeyId: 6, duaId: 9, timeSlot: "evening", sortOrder: 5 }
```

### Step 6: Run Seed Script

```bash
node scripts/seed-firestore.cjs
```

## Time Slot Guidelines

| Slot | Typical Count | Purpose |
|------|---------------|---------|
| morning | 2-3 | Protection, intention, energy |
| anytime | 1-2 | Flexible, situational |
| evening | 2-3 | Gratitude, reflection, protection |

## Verification

After creation, verify by querying Firestore:

1. Check the journey document exists
2. Query `journey_duas` where `journeyId` matches
3. Verify all linked duas exist
4. Confirm XP sum matches `dailyXp`

## Example Journey

```javascript
// Journey
{
  id: 6,
  name: "Student Success",
  slug: "student-success",
  description: "Daily duas for students seeking knowledge and success in their studies. Build focus, retain knowledge, and seek Allah's guidance.",
  emoji: "📚",
  estimatedMinutes: 8,
  dailyXp: 85,
  isPremium: false,
  isFeatured: false,
  sortOrder: 5
}

// Journey Duas
{ journeyId: 6, duaId: 1, timeSlot: "morning", sortOrder: 1 },
{ journeyId: 6, duaId: 4, timeSlot: "anytime", sortOrder: 2 },
{ journeyId: 6, duaId: 9, timeSlot: "evening", sortOrder: 3 }
```

## Firestore Console

View and verify data directly at:
https://console.firebase.google.com/project/rizq-app-c6468/firestore
