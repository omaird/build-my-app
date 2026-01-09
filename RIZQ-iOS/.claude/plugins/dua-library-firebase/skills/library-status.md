---
name: library-status-firebase
description: "Show current status of the Firebase dua library - counts, categories, journeys, and gaps"
---

# Firebase Library Status Skill

This skill retrieves and displays the current status of the RIZQ dua library in Firebase Firestore.

## Status Report Contents

### 1. Collection Counts

| Collection | Description |
|------------|-------------|
| duas | Total number of duas |
| categories | Number of categories |
| journeys | Number of journeys |
| journey_duas | Number of journey-dua mappings |

### 2. Category Breakdown

```markdown
| Category | Count | % of Library |
|----------|-------|--------------|
| Morning  | X     | X%           |
| Evening  | X     | X%           |
| Rizq     | X     | X%           |
| Gratitude| X     | X%           |
```

### 3. Difficulty Distribution

```markdown
| Difficulty   | Count | % of Library |
|--------------|-------|--------------|
| Beginner     | X     | X%           |
| Intermediate | X     | X%           |
| Advanced     | X     | X%           |
```

### 4. Journey Coverage

```markdown
| Journey | Duas | Total XP | Featured |
|---------|------|----------|----------|
| Name 1  | X    | XXX      | Yes      |
| Name 2  | X    | XXX      | No       |
```

### 5. Quality Metrics

- Duas with prophetic context: X/Total
- Duas with rizq benefit: X/Total
- Average XP per dua: X
- Total possible daily XP: X

## Querying Firebase

Use Firebase MCP tools to gather status:

```
1. mcp__plugin_firebase_firebase__firestore_list_collections
2. Query each collection for counts
3. Aggregate statistics
```

## Status Report Template

```markdown
# RIZQ Firebase Library Status

Generated: [timestamp]

## Overview
- Total Duas: XX
- Categories: 4
- Journeys: X
- Total Daily XP Available: XXX

## Duas by Category
| Category | Count | Avg XP |
|----------|-------|--------|
| Morning  | XX    | XX     |
| Evening  | XX    | XX     |
| Rizq     | XX    | XX     |
| Gratitude| XX    | XX     |

## Duas by Difficulty
| Level        | Count | Percentage |
|--------------|-------|------------|
| Beginner     | XX    | XX%        |
| Intermediate | XX    | XX%        |
| Advanced     | XX    | XX%        |

## Journeys
| Journey | Duas | XP  | Minutes | Featured |
|---------|------|-----|---------|----------|
| Name    | XX   | XXX | XX      | Yes/No   |

## Content Quality
- With Prophetic Context: XX/XX (XX%)
- With Rizq Benefit: XX/XX (XX%)
- With Audio: XX/XX (XX%)

## Gaps Identified
- [ ] Need more evening duas
- [ ] No advanced difficulty duas in Gratitude
- [ ] Journey "X" needs more variety

## Recommendations
1. Add X more duas to evening category
2. Create advanced difficulty duas
3. Add prophetic context to X duas
```

## Identifying Gaps

### Category Gaps
- Each category should have at least 5 duas
- Balanced distribution is ideal

### Difficulty Gaps
- Should have progression from beginner to advanced
- Each category should have all difficulty levels

### Journey Gaps
- Each journey should have 3-5 duas
- Should cover all three time slots

### Content Gaps
- All duas should have prophetic context
- Rizq duas should have rizq benefit

## Quick Status Commands

```bash
# Check total dua count
# Query Firebase duas collection

# Check journey stats
# Query Firebase journeys collection

# Check category distribution
# Group duas by categoryId
```

## Integration

This status can be used to:
1. Plan content additions
2. Balance the library
3. Track progress over time
4. Identify improvement opportunities
