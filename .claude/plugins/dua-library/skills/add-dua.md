---
name: add-dua
description: "Add a single dua to the database with all required fields (Arabic text, transliteration, translation, source, etc.)"
---

# Add Dua Skill

This skill helps add a single dua to the RIZQ App database.

## Required Information

To add a dua, you need:

| Field | Required | Description |
|-------|----------|-------------|
| title_en | ✅ | English title |
| arabic_text | ✅ | Full Arabic script |
| transliteration | ✅ | Romanized Arabic |
| translation_en | ✅ | English meaning |
| source | ✅ | Hadith/Quran reference |
| category_id | ✅ | Category (1=morning, 2=evening, 3=rizq, 4=gratitude) |
| title_ar | ❌ | Arabic title |
| repetitions | ❌ | Times to recite (default: 1) |
| best_time | ❌ | When to recite |
| difficulty | ❌ | beginner/intermediate/advanced |
| xp_value | ❌ | XP points (calculated if not provided) |
| rizq_benefit | ❌ | Description of provision benefit |

## XP Calculation

If xp_value not provided, calculate:
- Base: 15 XP
- Medium length (50-150 chars): +5
- Long (>150 chars): +10
- Per repetition: +5 (max +20)
- Intermediate difficulty: +10
- Advanced difficulty: +20

## SQL Template

```sql
INSERT INTO duas (
  category_id,
  title_en,
  title_ar,
  arabic_text,
  transliteration,
  translation_en,
  source,
  repetitions,
  best_time,
  difficulty,
  est_duration_sec,
  rizq_benefit,
  xp_value
) VALUES (
  $1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, $13
) RETURNING id, title_en;
```

## Validation Checklist

Before inserting:
- [ ] Arabic text contains Arabic Unicode characters
- [ ] Source follows format: "[Collection] [Number]" or "Quran [S]:[A]"
- [ ] Category ID exists (1-4)
- [ ] No duplicate title_en exists
- [ ] XP value is between 15-100

## Example Usage

Adding "Dua for Barakah in Work":

```sql
INSERT INTO duas (
  category_id,
  title_en,
  arabic_text,
  transliteration,
  translation_en,
  source,
  repetitions,
  best_time,
  difficulty,
  xp_value,
  rizq_benefit
) VALUES (
  3,
  'Dua for Barakah in Work',
  'اللَّهُمَّ بَارِكْ لِي فِي عَمَلِي',
  'Allahumma barik li fi ''amali',
  'O Allah, bless me in my work',
  'General Dua',
  1,
  'Before starting work',
  'beginner',
  20,
  'Invites divine blessing into your daily work and efforts'
) RETURNING id, title_en;
```
