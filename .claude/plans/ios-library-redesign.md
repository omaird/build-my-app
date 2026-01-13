# iOS Library Page Redesign Plan

## Core Insight: Library vs Practice

The fundamental problem is that the current Library feels like another practice screen, not a **reference collection**. We need to create two distinct mental models:

| Aspect | Library (Reference) | Adkhar (Practice) |
|--------|---------------------|-------------------|
| **Purpose** | Discover, learn, explore | Do, complete, track |
| **Mental Model** | Bookshelf / Encyclopedia | Daily checklist |
| **Time Context** | Timeless | Time-based (morning/evening) |
| **Progress** | None | Completion tracking |
| **Gamification** | Minimal (discovery focus) | Heavy (XP, streaks, progress) |
| **Primary Action** | "Add to my Adkhar" | "Tap to count" |
| **Card Focus** | Content & authenticity | Task completion |

---

## Problem Statement

The iOS Library currently feels like a duplicate of Adkhar because:

1. **Cards show gamification metrics** (XP, repetitions) — practice language
2. **Tapping opens a practice counter** — wrong for discovery
3. **Progress/completion states visible** — implies tasks to finish
4. **No source/authenticity info** — critical for Islamic reference
5. **Same visual language as habits** — no differentiation

### What's MISSING that makes it not feel like a Library:

- **Source/Hadith references on cards** — Authenticity matters
- **Educational framing** — "Learn about this dua" not "Practice this"
- **Content preview** — See the actual Arabic or key meaning
- **Topic/category prominence** — Browse by theme, not time slot
- **No completion indicators** — You don't "finish" a library

---

## Design Philosophy: The Two Tabs

### 📚 Library Tab = "The Catalog"
> *"What duas exist? What do they mean? Where do they come from?"*

- Browse the full collection of authentic duas
- Learn about each dua's meaning, source, and context
- Discover duas you didn't know existed
- **Action**: Add interesting ones to your daily practice

### ☀️ Adkhar Tab = "My Daily Practice"
> *"What do I need to recite today? How am I progressing?"*

- Your personalized daily habit list
- Organized by time of day (morning/anytime/evening)
- Track completion, streaks, XP earned
- **Action**: Practice and complete each dua

---

## Proposed Library Redesign

### Visual Differentiation Strategy

**Remove from Library cards:**
- ❌ XP values ("+10 XP") — gamification belongs in practice
- ❌ Repetition counts ("3×") — practice metric
- ❌ Completion checkmarks — no completion in a library
- ❌ "Active" badges — habit language
- ❌ Progress indicators

**Add to Library cards:**
- ✅ **Source reference** ("Sahih Muslim", "Quran 2:201")
- ✅ **Arabic preview** — See the actual text
- ✅ **Category/topic label** — What this dua is for
- ✅ **Difficulty indicator** — "Beginner-friendly" style

### New Library Card Design

```
┌─────────────────────────────────────────────────────┐
│                                                     │
│  ┌──────┐   Seeking Provision                       │
│  │ أصبح │   ────────────────────────────────────    │
│  │ نا و │   RIZQ • Sahih Muslim                     │
│  └──────┘                                           │
│            "O Allah, suffice me with what is        │
│            lawful against what is unlawful..."      │
│                                                     │
│            ○ Beginner-friendly                [+]   │
│                                                     │
└─────────────────────────────────────────────────────┘
```

**Card elements:**
1. **Arabic snippet** — Visual preview of the text (left side)
2. **Title** — Descriptive name of what this dua is for
3. **Category • Source** — Topic and authenticity reference
4. **Translation excerpt** — What it means
5. **Difficulty dot** — Accessibility indicator
6. **Add button** — "Add to my Adkhar"

### New Library Detail Sheet (Tap destination)

```
┌─────────────────────────────────────────┐
│                                    [X]  │
│  📿 RIZQ                                │
│                                         │
│  Seeking Provision                      │
│  ══════════════════════════════════     │
│                                         │
│  ┌───────────────────────────────────┐  │
│  │                                   │  │
│  │   أَصْبَحْنَا وَأَصْبَحَ الْمُلْكُ   │  │
│  │           لِلَّهِ                   │  │
│  │                                   │  │
│  └───────────────────────────────────┘  │
│                                         │
│  PRONUNCIATION                          │
│  Asbahna wa asbahal mulku lillah        │
│                                         │
│  MEANING                                │
│  We have entered upon morning and       │
│  the whole kingdom belongs to Allah     │
│                                         │
│  ════════════════════════════════════   │
│                                         │
│  WHY RECITE THIS DUA?                   │
│  This dua helps establish gratitude     │
│  and recognition of Allah's sovereignty │
│  at the start of your day...            │
│                                         │
│  ┌───────────────────────────────────┐  │
│  │ 📜 PROPHETIC TRADITION            │  │
│  │ The Prophet (ﷺ) would say this    │  │
│  │ every morning upon waking...      │  │
│  └───────────────────────────────────┘  │
│                                         │
│  ┌───────────────────────────────────┐  │
│  │ 📖 SOURCE                         │  │
│  │ Sahih Muslim, Book of Adhkar      │  │
│  │ Hadith #2723                      │  │
│  └───────────────────────────────────┘  │
│                                         │
│  ○ Beginner-friendly • 1 recitation     │
│                                         │
├─────────────────────────────────────────┤
│                                         │
│  [      Add to Daily Adkhar  ☀️       ]  │
│                                         │
└─────────────────────────────────────────┘
```

**Key differences from practice sheet:**
- **No counter** — This is reading/learning, not doing
- **Educational language** — "Pronunciation" not "Transliteration"
- **"Why recite this?"** — Explains the benefit contextually
- **Source with detail** — Book name, hadith number if available
- **Single CTA** — "Add to Daily Adkhar" bridges to practice

---

## User Journey Analysis

### Current Flow (Problematic)
```
Library List → Tap Card → Practice Counter (wrong context)
                      ↘→ Tap + → Add to Adkhar (works)
```

### Redesigned Flow
```
Library List → Tap Card → Dua Reference View (learn & explore)
                              ↳ Read about the dua
                              ↳ Understand its significance
                              ↳ See authentic source
                              ↳ "Add to Daily Adkhar" → Goes to Adkhar tab
                      ↘→ Tap + → Quick Add Sheet (shortcut)
```

---

## Data Available in Dua Model

From `Dua.swift`, we have rich fields — reframed for Library vs Adkhar usage:

| Field | Type | Library (Reference) | Adkhar (Practice) |
|-------|------|---------------------|-------------------|
| `titleEn` | String | ✅ Primary title | ✅ Habit name |
| `arabicText` | String | ✅ **PROMINENT** preview | ✅ For recitation |
| `transliteration` | String? | ✅ "Pronunciation" | ✅ For practice |
| `translationEn` | String | ✅ "Meaning" | ✅ Understanding |
| `source` | String? | ✅ **CRITICAL** for authenticity | ⚪ Optional |
| `propheticContext` | String? | ✅ Educational content | ✅ Context |
| `rizqBenefit` | String? | ✅ "Why recite this?" | ⚪ Optional |
| `bestTime` | String? | ⚪ Informational | ✅ Time slot sorting |
| `difficulty` | DuaDifficulty? | ✅ Accessibility indicator | ⚪ Not shown |
| `repetitions` | Int | ⚪ Footnote info | ✅ Practice counter |
| `xpValue` | Int | ❌ **HIDE** (not reference) | ✅ Gamification |

---

## Implementation Plan

### Phase 1: Redesign Library Cards

**Goal**: Make cards feel like library entries, not habit items.

**Current Card (Practice-focused):**
```
[🌅]  Morning Dhikr
      ✨ +10 • 1×                    ← Gamification metrics
      We have entered upon morning...
      [Active badge]            [+]  ← Habit language
```

**Redesigned Card (Reference-focused):**
```
┌─────────────────────────────────────────────────────┐
│  ┌────────┐                                         │
│  │ أَصْبَحْ │  Seeking Provision                     │
│  │  نَا    │  ─────────────────────                 │
│  └────────┘  RIZQ • Sahih Muslim                   │
│                                                     │
│  "O Allah, suffice me with what is lawful          │
│  against what is unlawful..."                      │
│                                                     │
│  ○ Beginner-friendly                         [+]   │
└─────────────────────────────────────────────────────┘
```

**Changes:**
- Add Arabic text preview snippet (left side visual)
- Replace XP/repetitions with **Source reference**
- Replace "Active" badge with **Difficulty indicator**
- Remove completion checkmarks entirely
- Keep category emoji but make source more prominent

### Phase 2: New DuaReferenceSheet (Tap Destination)

**Goal**: Educational detail view, not practice interface.

Create `DuaReferenceSheet` — a contemplative, learning-focused view:

```swift
struct DuaReferenceSheet: View {
  let dua: Dua
  let onAddToAdkhar: () -> Void

  // Sections:
  // 1. Category badge + Title header
  // 2. Arabic text card (prominent, centered)
  // 3. "Pronunciation" section (transliteration)
  // 4. "Meaning" section (translation)
  // 5. "Why Recite This Dua?" section (rizqBenefit)
  // 6. "Prophetic Tradition" card (propheticContext)
  // 7. "Source" card (source + any additional reference)
  // 8. Footer: Difficulty • Recitations info
  // 9. CTA: "Add to Daily Adkhar" button
}
```

**Language changes (educational framing):**
| Current (Practice) | New (Reference) |
|--------------------|-----------------|
| "Transliteration" | "Pronunciation" |
| "Translation" | "Meaning" |
| "Benefits" | "Why Recite This Dua?" |
| "Prophetic Guidance" | "Prophetic Tradition" |
| "+10 XP" | *(removed)* |
| "Tap to Count" | *(removed)* |

### Phase 3: Update Library Page Header

**Current:**
```
📖 Dua Library
16 duas to practice        ← Practice language
```

**Redesigned:**
```
📚 Dua Library
Explore 16 authentic duas  ← Discovery language
```

Or even more library-like:
```
📚 Dua Collection
Browse by category or search the collection
```

### Phase 4: Remove Practice Elements from LibraryFeature

**Remove:**
- `@Presents var practiceSheet: PracticeSheetFeature.State?`
- `completedTodayDuaIds` tracking
- `isCompletedToday()` checks
- Any XP-related state

**Add:**
- `@Presents var duaReferenceSheet: DuaReferenceSheetFeature.State?`
- Focus on category filtering and search

---

## Implementation Tasks

### Task 1: Redesign DuaListCardView (Library Card)
- [ ] Remove XP display (`+10 XP`)
- [ ] Remove repetition count (`1×`, `3×`)
- [ ] Remove completion checkmark indicator
- [ ] Remove "Active" badge
- [ ] Add Arabic text preview snippet (left side)
- [ ] Add Source reference prominently (`Sahih Muslim`)
- [ ] Add Difficulty indicator (`○ Beginner-friendly`)
- [ ] Keep category emoji
- [ ] Keep translation excerpt
- [ ] Keep `+` button for quick add

### Task 2: Create DuaReferenceSheetFeature
- [ ] Create `DuaReferenceSheetFeature.swift` (new TCA feature)
- [ ] State: `dua: Dua` (read-only, no practice state)
- [ ] Actions: `addToAdkharTapped`, `closeTapped`
- [ ] Effect: Present AddToAdkharSheet when button tapped
- [ ] **No practice counter, no XP, no completion tracking**

### Task 3: Create DuaReferenceSheetView
- [ ] Create `DuaReferenceSheetView.swift` (educational layout)
- [ ] Header: Category badge + Dua title
- [ ] Arabic card: Large, centered, contemplative
- [ ] "Pronunciation" section (transliteration)
- [ ] "Meaning" section (translation)
- [ ] "Why Recite This Dua?" section (rizqBenefit — if available)
- [ ] "Prophetic Tradition" card (propheticContext — if available)
- [ ] "Source" card (source with styling)
- [ ] Footer info: Difficulty label + recitation count (subtle)
- [ ] CTA: Single "Add to Daily Adkhar" button
- [ ] **No counter, no "Practice Now", no XP display**

### Task 4: Update LibraryFeature
- [ ] Remove `@Presents var practiceSheet: PracticeSheetFeature.State?`
- [ ] Remove `completedTodayDuaIds` state
- [ ] Remove `isCompletedToday()` function
- [ ] Remove `.practiceSheet` presentation action handling
- [ ] Add `@Presents var referenceSheet: DuaReferenceSheetFeature.State?`
- [ ] Update `duaTapped` to present reference sheet
- [ ] Keep `addToAdkharTapped` for direct `+` button

### Task 5: Update LibraryView
- [ ] Update sheet to present `DuaReferenceSheetView`
- [ ] Update header text: "Explore X authentic duas"
- [ ] Remove completed state passing to cards
- [ ] Use `.presentationDetents([.large])` for full scroll

### Task 6: Clean Up Unused Code
- [ ] Remove `PracticeSheetFeature` from LibraryFeature.swift (it's inline)
- [ ] Remove `PracticeSheetView` from LibraryView.swift (it's inline)
- [ ] These practice components remain in Adkhar — just removed from Library

### Task 7: Build & Test
- [ ] Verify iOS build compiles on iPhone 17 simulator
- [ ] Test: Tap card → Reference sheet opens (no counter)
- [ ] Test: Reference sheet shows all available dua metadata
- [ ] Test: "Add to Daily Adkhar" button works
- [ ] Test: `+` button still opens quick add sheet
- [ ] Test: Category filtering still works
- [ ] Test: Search still works

---

## Files to Create/Modify

| File | Action | Purpose |
|------|--------|---------|
| `DuaReferenceSheetFeature.swift` | **CREATE** | New TCA feature for reference view |
| `DuaReferenceSheetView.swift` | **CREATE** | Educational detail view |
| `LibraryFeature.swift` | **MODIFY** | Remove practice state, add reference sheet |
| `LibraryView.swift` | **MODIFY** | Update sheet, header, remove practice view |
| `DuaListCardView.swift` | **MODIFY** | Redesign for reference (not practice) |

**Files to NOT touch:**
- `AdkharFeature.swift` — Keep practice-focused
- `QuickPracticeSheet.swift` — Stays in Adkhar
- Anything in `Features/Practice/` — Separate practice flow

---

## Visual Reference

**Borrow styling from `QuickPracticeSheet` but remove practice elements:**

| Keep (Reference styling) | Remove (Practice elements) |
|--------------------------|---------------------------|
| Arabic text card with gold border | Progress bar |
| "PROPHETIC GUIDANCE" gold card | Counter circle |
| "SOURCE" card styling | "Tap to Count" button |
| Section headers (uppercase, tracked) | XP earned display |
| Warm cream/gold color palette | Celebration overlay |

---

## Success Criteria

### Library must feel DIFFERENT from Adkhar:

| Criteria | Library (New) | Adkhar (Unchanged) |
|----------|---------------|-------------------|
| XP visible on cards | ❌ No | ✅ Yes |
| Completion tracking | ❌ No | ✅ Yes |
| Practice counter | ❌ No | ✅ Yes |
| Source on cards | ✅ Yes | ⚪ Optional |
| Arabic preview | ✅ Yes | ⚪ Optional |
| Tap destination | Reference sheet | Practice sheet |
| Primary CTA | "Add to Adkhar" | "Tap to Count" |

### Functional requirements:

1. ✅ Cards show **source** (Sahih Muslim, Quran, etc.)
2. ✅ Cards show **Arabic preview** snippet
3. ✅ Cards do NOT show XP or repetition counts
4. ✅ Tapping opens **reference view** (not practice)
5. ✅ Reference view shows **all metadata** (source, prophetic context, benefits)
6. ✅ Reference view has **no counter**
7. ✅ "Add to Daily Adkhar" is the **only CTA**
8. ✅ `+` button still works for quick add
9. ✅ Build compiles on iPhone 17 simulator

---

## Answered Questions

1. **Card content**: Remove XP/repetitions. Add Source + Arabic preview. Translation excerpt stays.

2. **Practice from Library**: **No.** Library is for discovery. If user wants to practice, they add to Adkhar first, then practice there. This creates clear separation.

3. **Difficulty display**: Show on card as subtle indicator (`○ Beginner-friendly`) and in detail view.

---

## Status

- [x] Problem analysis complete
- [x] Design philosophy defined (Library vs Adkhar)
- [x] Card redesign specified
- [x] Reference sheet designed
- [x] Implementation tasks defined
- [x] Implementation complete (Iteration 3)
- [x] Build verified on iPhone 17 simulator

**Iteration**: 3
**Last Updated**: 2026-01-13

## Implementation Summary

### Created Files
- `DuaReferenceSheetFeature.swift` - TCA feature for educational dua detail
- `DuaReferenceSheetView.swift` - Educational layout with rich context

### Modified Files
- `DuaListCardView.swift` - Redesigned for reference (Arabic preview, source, difficulty)
- `LibraryFeature.swift` - Replaced practice sheet with reference sheet
- `LibraryView.swift` - Updated header text, sheet presentation
