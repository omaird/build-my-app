---
name: dua-add
description: "Interactive command to add a new dua to the database with guided prompts"
---

# Add Dua Command

You are helping the user add a new dua to the RIZQ App database. Guide them through the process step by step.

## Step 1: Gather Information

Use AskUserQuestion to collect the following information:

### Required Fields
1. **English Title** - What should this dua be called?
2. **Arabic Text** - The full dua in Arabic script
3. **Transliteration** - Romanized Arabic for learners
4. **English Translation** - Clear meaning in English
5. **Source** - Hadith reference (e.g., "Sahih Muslim 2723") or Quran reference

### Optional but Recommended
6. **Arabic Title** - Title in Arabic (if different)
7. **Best Time** - When to recite (After Fajr, Before work, etc.)
8. **Repetitions** - How many times to recite (default: 1)
9. **Difficulty** - beginner, intermediate, or advanced

## Step 2: Category Selection

Ask which category the dua belongs to:
- morning - Morning adhkar and duas
- evening - Evening adhkar and duas
- rizq - Provision, sustenance, wealth
- gratitude - Thankfulness and contentment

## Step 3: Calculate XP Value

Based on the information provided:
- Base: 15 XP
- Length bonus: +5 (medium) or +10 (long)
- Repetition bonus: +5 per rep (max +20)
- Difficulty bonus: +10 (intermediate) or +20 (advanced)

Present the calculated XP to the user for approval.

## Step 4: Verify Before Insertion

Show a preview:
```
📿 New Dua Preview
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Title: [English Title]
Category: [Category]
Difficulty: [Difficulty]
XP Value: [Calculated XP]

Arabic:
[Arabic Text]

Transliteration:
[Transliteration]

Translation:
[Translation]

Source: [Source]
Best Time: [Best Time]
Repetitions: [Count]x

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

Ask for confirmation before proceeding.

## Step 5: Insert into Database

First, get the category ID:
```sql
SELECT id FROM categories WHERE slug = '[category_slug]';
```

Then insert the dua:
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
  xp_value
) VALUES (
  [category_id],
  '[title_en]',
  '[title_ar]',
  '[arabic_text]',
  '[transliteration]',
  '[translation_en]',
  '[source]',
  [repetitions],
  '[best_time]',
  '[difficulty]',
  [xp_value]
) RETURNING id, title_en;
```

## Step 6: Confirm Success

After successful insertion:
```
✅ Dua Added Successfully!

ID: [new_id]
Title: [title]

The dua is now available in the library under the [category] category.

Would you like to:
1. Add this dua to a journey?
2. Add another dua?
3. View the dua in the library?
```

## Error Handling

If insertion fails:
- Check for duplicate titles
- Verify category exists
- Ensure Arabic text is not empty
- Report specific error to user
