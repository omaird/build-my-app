# Fix Journeys Tab: Scrolling & Icons Plan

## Problem Statement

The Journeys tab on iOS has two critical UX issues:

### Issue 1: Scrolling is Blocked
Users cannot scroll the Journeys list by swiping on the journey cards. They can only scroll by touching the gaps between cards. This makes the tab feel broken on a phone.

**Root Cause**: `JourneyCardView.swift` uses a `DragGesture(minimumDistance: 0)` for press feedback animation. This gesture captures ALL touch events immediately (zero minimum distance), preventing the parent `ScrollView` from receiving scroll gestures.

**Location**: `RIZQ-iOS/RIZQ/Views/Components/JourneyViews/JourneyCardView.swift` (lines 76-80)

```swift
.simultaneousGesture(
  DragGesture(minimumDistance: 0)  // ⚠️ BLOCKS SCROLL
    .onChanged { _ in isPressed = true }
    .onEnded { _ in isPressed = false }
)
```

### Issue 2: Icons Not Matching Web App
The journey icons displayed in the iOS app should use the custom PNG icons from the web app's `/public/images/icons/` folder, but the icons may not be displaying correctly.

**Current Architecture**:
- Web app stores icons in: `/public/images/icons/[Journey Name].png`
- iOS app has asset catalog: `Assets.xcassets/Images/Journeys/[slug].imageset`
- Database `emoji` field contains either:
  - An emoji character (e.g., `"📿"`)
  - An image path (e.g., `"/images/icons/The Rizq Seeker.png"`)

---

## Technical Analysis

### Scrolling Problem Deep Dive

**How SwiftUI Gesture Recognition Works:**

1. `ScrollView` listens for vertical drag gestures to initiate scrolling
2. Child views with gesture modifiers can intercept these gestures
3. `DragGesture(minimumDistance: 0)` starts tracking immediately on touch
4. The parent `ScrollView` never gets the gesture to determine it's a scroll

**Why This Is Wrong:**

| Gesture Setting | Behavior | Scrolling Works? |
|-----------------|----------|------------------|
| `minimumDistance: 0` | Captures touch instantly | ❌ No |
| `minimumDistance: 10` | Allows small movement first | ✅ Yes |
| No DragGesture | No interference | ✅ Yes |
| `LongPressGesture` | Only on held touch | ✅ Yes |

### Icon System Analysis

**Web App Icons** (`/public/images/icons/`):
```
Evening Peace.png
Family provider.png
Gratitude Builder.png
Istighfar Habit.png
Job Seeker.png
Morning Adhkar.png
Morning Warrior.png
New Muslim Starter.png
Quran Reflection.png
Salah Companion.png
Salawat on Prophet.png
Tahajjud Night Warrior.png
The Rizq Seeker.png
default-journey.png
```

**iOS App Assets** (`Assets.xcassets/Images/Journeys/`):
```
debt-freedom.imageset
default-journey.imageset
evening-peace.imageset
family-provider.imageset
gratitude-builder.imageset
istighfar-habit.imageset
job-seeker.imageset
morning-adhkar.imageset
morning-warrior.imageset
new-muslim-starter.imageset
quran-reflection.imageset
rizq-seeker.imageset
salah-companion.imageset
salawat-on-prophet.imageset
tahajjud-night-warrior.imageset
```

**Naming Mapping** (Web → iOS slug):
| Web File Name | iOS Asset Name |
|---------------|----------------|
| `The Rizq Seeker.png` | `rizq-seeker` |
| `Morning Warrior.png` | `morning-warrior` |
| `Evening Peace.png` | `evening-peace` |
| etc. | etc. |

**How Icon Loading Works** (`JourneyIconView.swift`):

```swift
// Checks if emoji field has an image path
if journey.hasImageAsset {  // emoji.hasPrefix("/images/")
  // Uses journey.slug to load from asset catalog
  Image(journey.imageAssetName)  // journey.imageAssetName = journey.slug
}
```

**Potential Issues:**
1. The `emoji` field in the database may not have `/images/` prefix
2. Asset catalog may be missing some images or have wrong names
3. iOS assets may not be populated correctly in the imagesets

---

## Implementation Plan

### Task 1: Fix Scrolling (Remove Blocking DragGesture)

**File**: `RIZQ-iOS/RIZQ/Views/Components/JourneyViews/JourneyCardView.swift`

**Option A: Remove gesture entirely** (Simplest)
Remove the `DragGesture` and keep only the button tap behavior. Loses press feedback animation.

```swift
// REMOVE these lines (76-80):
.simultaneousGesture(
  DragGesture(minimumDistance: 0)
    .onChanged { _ in isPressed = true }
    .onEnded { _ in isPressed = false }
)

// REMOVE isPressed state variable (line 12):
@State private var isPressed = false

// REMOVE press animation (lines 72-73):
.scaleEffect(isPressed ? 0.98 : 1.0)
.animation(.spring(response: 0.3, dampingFraction: 0.7), value: isPressed)
```

**Option B: Use ButtonStyle instead** (Recommended)
Create a custom `ButtonStyle` that provides press feedback without blocking scroll.

```swift
struct PressableButtonStyle: ButtonStyle {
  func makeBody(configuration: Configuration) -> some View {
    configuration.label
      .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
      .animation(.spring(response: 0.3, dampingFraction: 0.7), value: configuration.isPressed)
  }
}

// Usage:
Button(action: onTap) { ... }
  .buttonStyle(PressableButtonStyle())
```

**Option C: Increase minimum distance** (Alternative)
Set a minimum drag distance before the gesture activates, allowing scroll first.

```swift
.simultaneousGesture(
  DragGesture(minimumDistance: 50)  // Allow scroll to win
    .onChanged { _ in isPressed = true }
    .onEnded { _ in isPressed = false }
)
```

**Recommendation**: Use **Option B** (ButtonStyle) — it's the proper SwiftUI pattern and preserves press feedback without interfering with scroll.

### Task 2: Verify and Fix Icon Display

**Step 2.1: Verify Database Has Image Paths**

Check that the Firestore `journeys` collection has `emoji` fields with `/images/icons/...` paths, not just emoji characters.

**Step 2.2: Verify Asset Catalog Contents**

Each imageset should contain the actual PNG files. Check one:

```bash
ls -la RIZQ-iOS/RIZQ/Assets.xcassets/Images/Journeys/rizq-seeker.imageset/
```

Should contain: `Contents.json` + image files

**Step 2.3: Ensure Image Fallback Works**

If an image fails to load, the fallback to emoji or default should work:

```swift
// In JourneyIconView.swift - add fallback
if let uiImage = UIImage(named: journey.imageAssetName) {
  Image(uiImage: uiImage)
    .resizable()
    // ...
} else {
  // Fallback: try default-journey or show emoji
  Image(Journey.defaultImageAsset)
    .resizable()
    // ... or Text(journey.emoji)
}
```

### Task 3: Update CompactJourneyCardView (Also Has Gesture Issue)

The `CompactJourneyCardView` in the same file doesn't have the DragGesture issue, but should use the same ButtonStyle for consistency.

---

## Files to Modify

| File | Action | Changes |
|------|--------|---------|
| `JourneyCardView.swift` | **MODIFY** | Replace DragGesture with ButtonStyle |
| `JourneyIconView.swift` | **VERIFY** | Add fallback if image not found |
| `Journey.swift` | **VERIFY** | Confirm hasImageAsset logic |

---

## What NOT to Do (Out of Scope)

1. **Don't modify JourneysView.swift** — The ScrollView implementation is correct
2. **Don't change JourneysFeature.swift** — TCA reducer logic is fine
3. **Don't redesign the journey card layout** — Only fix gestures and icons
4. **Don't add new icon files** — Assets already exist, just verify they work
5. **Don't modify the web app** — Focus on iOS only
6. **Don't change database/Firestore** — Assume data is correct
7. **Don't add complex gesture recognizers** — Keep it simple with ButtonStyle

---

## Implementation Steps (Detailed)

### Step 1: Create PressableButtonStyle

Create a reusable button style that provides press feedback:

**File**: `JourneyCardView.swift` (add at top of file or in separate file)

```swift
/// Button style that provides press feedback without blocking scroll gestures
struct PressableCardStyle: ButtonStyle {
  func makeBody(configuration: Configuration) -> some View {
    configuration.label
      .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
      .animation(.spring(response: 0.3, dampingFraction: 0.7), value: configuration.isPressed)
  }
}
```

### Step 2: Update JourneyCardView

Remove the `@State private var isPressed = false`
Remove the `.simultaneousGesture(...)` modifier
Remove the inline `.scaleEffect(isPressed ? ...)`
Replace `.buttonStyle(.plain)` with `.buttonStyle(PressableCardStyle())`

### Step 3: Verify Icon Loading

Run the app and check:
- Do journey cards show the custom PNG icons?
- If not, debug `JourneyIconView` with print statements
- Verify the asset catalog has actual image files in the imagesets

### Step 4: Test Scrolling

- Launch on iPhone simulator
- Try scrolling by swiping on journey cards (should work now)
- Try tapping cards (should still navigate to detail)
- Verify press animation still works

---

## Success Criteria

### Scrolling Fix ✓
- [ ] User can scroll the Journeys list by swiping anywhere on the cards
- [ ] Tapping a card still opens the journey detail sheet
- [ ] Press feedback animation still works (scale down on press)
- [ ] No visual regressions

### Icons Fix ✓
- [ ] Journey cards display the correct custom PNG icons
- [ ] Icons match those shown in the React web app
- [ ] Fallback works for any missing icons (shows emoji or default)
- [ ] No blank/missing icon states

### Build ✓
- [ ] iOS build compiles successfully on iPhone 17 simulator
- [ ] No SwiftUI warnings related to gestures
- [ ] All existing functionality preserved

---

## Testing Checklist

1. **Scroll Test**
   - [ ] Open Journeys tab
   - [ ] Place finger on a journey card and swipe up/down
   - [ ] List should scroll smoothly
   - [ ] Touch outside cards should also scroll (unchanged behavior)

2. **Tap Test**
   - [ ] Tap any journey card
   - [ ] Detail sheet should appear
   - [ ] Card should show brief press animation (scale to 0.98)

3. **Icon Test**
   - [ ] Check "Rizq Seeker" shows correct icon
   - [ ] Check "Morning Warrior" shows correct icon
   - [ ] Check all visible journeys have proper icons (not emojis unless intentional)

4. **Edge Cases**
   - [ ] Fast scrolling works
   - [ ] Pull-to-refresh still works
   - [ ] Tab switching doesn't cause issues

---

## Risk Assessment

| Risk | Likelihood | Impact | Mitigation |
|------|------------|--------|------------|
| ButtonStyle breaks layout | Low | Medium | Test thoroughly on multiple devices |
| Icons fail to load | Low | Low | Fallback to emoji exists |
| Performance impact | Very Low | Low | ButtonStyle is lightweight |
| Breaks existing tests | Low | Medium | Run test suite after changes |

---

## Estimated Complexity

- **Scrolling fix**: Simple (~15 minutes)
  - Remove gesture, add ButtonStyle
  - Straightforward SwiftUI pattern

- **Icon verification**: Simple (~15 minutes)
  - Check asset catalog
  - Debug if needed

- **Testing**: Moderate (~30 minutes)
  - Manual testing on simulator
  - Verify all journeys

**Total**: ~1 hour

---

## Status

- [x] Problem identified and analyzed
- [x] Root cause found (DragGesture with minimumDistance: 0)
- [x] Solution designed (ButtonStyle approach)
- [x] Implementation plan documented
- [ ] Implementation complete
- [ ] Testing complete
- [ ] Build verified

**Created**: 2026-01-14
**Last Updated**: 2026-01-14
