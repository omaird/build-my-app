# Task: Commit Design System Changes

## Status: Completed

## Summary
Committed all pending changes to the iOS app design system.

## Changes Committed

**Commit:** `e41f7bf`
**Message:** feat(ios): Add adaptive color assets and enhance design system

### Files Changed (42 total)

**New Color Assets (28 files):**
- Badge colors: `badgeEveningAdaptive`, `badgeGratitudeAdaptive`, `badgeMorningAdaptive`, `badgeRizqAdaptive`
- Difficulty colors: `difficultyAdvancedBg/Text`, `difficultyBeginnerBg/Text`, `difficultyIntermediateBg/Text`
- Gradient colors: `gradientCardStart/End`, `gradientPrimaryStart/End`, `gradientStreakStart/End`
- Semantic tokens: `rizqBackground`, `rizqBorder`, `rizqCard`, `rizqMuted`, `rizqPrimaryAdaptive`, `rizqSurface`, `rizqText`, `rizqTextSecondary`, `rizqTextTertiary`
- Time slot colors: `timeSlotAnytimeBg`, `timeSlotEveningBg`, `timeSlotMorningBg`

**New Font:**
- `AmiriQuran-Regular.ttf`

**Modified Files:**
- `Colors.swift` - Updated color definitions
- `Typography.swift` - Added Amiri Quran font support
- `RIZQWidget.swift` - Enhanced widget styling
- `DuaCardView.swift`, `DuaListCardView.swift` - Updated color references
- `DuaContextView.swift` - Refined styling
- `SettingsView.swift`, `LinkedAccountRow.swift` - UI updates
- `RippleEffect.swift`, `Sparkles.swift` - Animation refinements
- `TimeSlot+SwiftUI.swift` - Time slot color updates
- `Info.plist` - Font registration

## Result
All changes staged and committed successfully. Branch is 1 commit ahead of origin/main.
