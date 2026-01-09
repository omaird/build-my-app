---
name: create-journey-firebase
description: "Create a new themed journey (collection of duas) in Firebase with time-slot assignments"
---

# Create Journey in Firebase Skill

This skill helps create a new themed journey (collection of duas) in Firebase Firestore.

## Firestore Collections

- Journeys: `journeys`
- Journey-Dua mappings: `journey_duas`

## Journey Document Schema

| Field | Required | Type | Description |
|-------|----------|------|-------------|
| id | ✅ | `Int` | Unique journey ID |
| name | ✅ | `String` | Display name |
| slug | ✅ | `String` | URL-friendly identifier |
| description | ✅ | `String` | Journey description |
| emoji | ✅ | `String` | Representative emoji |
| estimatedMinutes | ❌ | `Int` | Total practice time (default: 10) |
| dailyXp | ❌ | `Int` | Total XP per day (calculated from duas) |
| isPremium | ❌ | `Bool` | Premium content flag (default: false) |
| isFeatured | ❌ | `Bool` | Featured on home (default: false) |
| sortOrder | ❌ | `Int` | Display order |

## Journey Dua Document Schema

| Field | Required | Type | Description |
|-------|----------|------|-------------|
| journeyId | ✅ | `Int` | Reference to journey |
| duaId | ✅ | `Int` | Reference to dua |
| timeSlot | ✅ | `String` | morning/anytime/evening |
| sortOrder | ❌ | `Int` | Order within time slot |

Document ID format: `{journeyId}_{duaId}`

## Time Slot Guidelines

| Time Slot | Best For |
|-----------|----------|
| morning | Duas recited after Fajr, upon waking |
| anytime | Duas that can be recited throughout the day |
| evening | Duas recited after Maghrib, before sleep |

## Daily XP Calculation

Sum of all dua XP values in the journey:
```javascript
dailyXp = journeyDuas.reduce((sum, jd) => {
  const dua = duas.find(d => d.id === jd.duaId);
  return sum + (dua?.xpValue || 10);
}, 0);
```

## Estimated Minutes Calculation

```javascript
estimatedMinutes = Math.ceil(journeyDuas.reduce((sum, jd) => {
  const dua = duas.find(d => d.id === jd.duaId);
  const duration = dua?.estDurationSec || 30;
  const reps = dua?.repetitions || 1;
  return sum + (duration * reps);
}, 0) / 60);
```

## Example Journey JSON

```json
// journey-to-add.json
{
  "journey": {
    "id": 6,
    "name": "Barakah Builder",
    "slug": "barakah-builder",
    "description": "A focused journey to invite divine blessings into all aspects of your life.",
    "emoji": "✨",
    "estimatedMinutes": 12,
    "dailyXp": 180,
    "isPremium": false,
    "isFeatured": true,
    "sortOrder": 5
  },
  "journeyDuas": [
    { "journeyId": 6, "duaId": 3, "timeSlot": "morning", "sortOrder": 1 },
    { "journeyId": 6, "duaId": 7, "timeSlot": "anytime", "sortOrder": 2 },
    { "journeyId": 6, "duaId": 9, "timeSlot": "evening", "sortOrder": 3 }
  ]
}
```

## Adding via Firebase Admin Script

```bash
cd /Users/omairdawood/Projects/RIZQ\ App && node scripts/add-journey.cjs journey-to-add.json
```

## Journey Theme Ideas

| Theme | Emoji | Focus |
|-------|-------|-------|
| Rizq Seeker | 💰 | Provision and sustenance duas |
| Morning Warrior | 🌅 | Morning adhkar collection |
| Debt Freedom | 🔓 | Financial relief duas |
| Evening Peace | 🌙 | Evening protection duas |
| Gratitude Builder | 🤲 | Thankfulness duas |
| Barakah Builder | ✨ | Blessing invocation duas |
| Protection Shield | 🛡️ | Protection from harm |
| Heart Healer | 💚 | Duas for anxiety and peace |

## Validation Checklist

Before creating:
- [ ] Journey ID is unique
- [ ] Slug is unique and URL-friendly
- [ ] All referenced dua IDs exist
- [ ] Time slots are valid (morning/anytime/evening)
- [ ] dailyXp matches sum of dua XP values
- [ ] At least 2 duas in the journey

## Workflow

1. Query existing journeys to find next ID
2. Select duas for the journey from the library
3. Assign time slots based on dua best times
4. Calculate dailyXp and estimatedMinutes
5. Create journey document
6. Create journey_duas mapping documents
7. Verify all documents were created
