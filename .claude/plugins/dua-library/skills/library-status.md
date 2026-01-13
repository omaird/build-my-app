---
name: library-status
description: "Show current status of the dua library in Firebase Firestore - counts, categories, journeys, and gaps"
---

# Library Status Skill

Quick overview of the dua library's current state in Firebase Firestore.

## Data Collection

Query the following Firestore collections:

### 1. Overall Counts
- Query `duas` collection - count documents
- Query `journeys` collection - count documents
- Query `categories` collection - count documents

### 2. Category Breakdown
For each category (1-4):
- Query `duas` where `categoryId` equals category
- Count results
- Calculate percentage of total

Categories:
- 1: Morning (🌅)
- 2: Evening (🌙)
- 3: Rizq (💫)
- 4: Gratitude (🤲)

### 3. Journey Summary
For each journey:
- Get journey name and emoji
- Query `journey_duas` where `journeyId` matches
- Count linked duas
- Get `dailyXp` value

### 4. XP Statistics
- Sum all `xpValue` fields from `duas` collection
- Calculate average XP per dua

### 5. Roadmap Progress
Compare current count against targets:
- Phase 1 (MVP): 15 duas
- Phase 2 (Extended): 35 duas
- Phase 3 (Specialized): 50+ duas

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
   💫 Rizq:      [X]
   🤲 Gratitude: [X]

🗺️ Journeys
   💰 Rizq Seeker      [X] duas
   🌅 Morning Warrior  [X] duas
   🔓 Debt Freedom     [X] duas
   🌙 Evening Peace    [X] duas
   🤲 Gratitude Builder [X] duas

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
5. `/dua-pipeline` - Process a new dua through full pipeline

## Firestore Console

View data directly at:
https://console.firebase.google.com/project/rizq-app-c6468/firestore
