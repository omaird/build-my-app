---
name: dua-add-firebase
description: "Interactive command to add a new dua to Firebase Firestore with guided prompts"
---

# Add Dua to Firebase Command

You are helping the user add a new dua to the RIZQ App Firebase Firestore database. Guide them through the process step by step.

## Step 1: Check Current Library State

First, query Firebase to find the highest existing dua ID:

Use the Firebase MCP to query the duas collection and find the maximum ID.

## Step 2: Gather Information

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
10. **Prophetic Context** - Background on when/why the Prophet (ﷺ) recited this
11. **Rizq Benefit** - How this dua relates to provision (if applicable)

## Step 3: Category Selection

Ask which category the dua belongs to:
- **morning** (ID: 1) - Morning adhkar and duas
- **evening** (ID: 2) - Evening adhkar and duas
- **rizq** (ID: 3) - Provision, sustenance, wealth
- **gratitude** (ID: 4) - Thankfulness and contentment

## Step 4: Calculate XP Value

Based on the information provided:
- Base: 15 XP
- Length bonus: +5 (medium) or +10 (long)
- Repetition bonus: +5 per rep (max +20)
- Difficulty bonus: +10 (intermediate) or +20 (advanced)

Present the calculated XP to the user for approval.

## Step 5: Verify Before Insertion

Show a preview:
```
📿 New Dua Preview
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

ID: [Next ID]
Title: [English Title]
Category: [Category Name]
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

## Step 6: Insert into Firebase

Create a JSON file with the dua data and use the admin script:

```bash
# Create the dua JSON
cat > /tmp/new-dua.json << 'EOF'
{
  "id": [id],
  "categoryId": [categoryId],
  "titleEn": "[titleEn]",
  "titleAr": "[titleAr]",
  "arabicText": "[arabicText]",
  "transliteration": "[transliteration]",
  "translationEn": "[translationEn]",
  "source": "[source]",
  "repetitions": [repetitions],
  "bestTime": "[bestTime]",
  "difficulty": "[difficulty]",
  "xpValue": [xpValue],
  "rizqBenefit": "[rizqBenefit]",
  "propheticContext": "[propheticContext]"
}
EOF

# Run the add script
cd /Users/omairdawood/Projects/RIZQ\ App && node scripts/add-dua.cjs /tmp/new-dua.json
```

## Step 7: Confirm Success

After successful insertion:
```
✅ Dua Added Successfully to Firebase!

ID: [new_id]
Title: [title]
Collection: duas

The dua is now available in the library under the [category] category.

Would you like to:
1. Add this dua to a journey?
2. Add another dua?
3. View the library status?
```

## Error Handling

If insertion fails:
- Check for duplicate IDs
- Verify Firebase Admin SDK is configured
- Ensure Arabic text is not empty
- Check service account credentials
- Report specific error to user

## Verification

After adding, verify by querying Firebase:
```
Query the duas collection for the new document to confirm it was created correctly.
```
