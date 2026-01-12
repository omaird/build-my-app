---
name: ios-design-tokens
description: "Reference guide for RIZQ iOS design tokens - colors, typography, spacing, shadows, and radius values"
---

# RIZQ iOS Design Tokens Reference

Quick reference for all design tokens in the RIZQKit framework.

## File Locations

| Token Type | File |
|------------|------|
| Colors | `/RIZQKit/Design/Colors.swift` |
| Typography | `/RIZQKit/Design/Typography.swift` |
| Spacing & Shadows | `/RIZQKit/Design/Spacing.swift` |

## Colors

### Brand Colors

| Token | Value | Usage |
|-------|-------|-------|
| `Color.rizqPrimary` | `#D4A574` (Sand Warm) | Primary actions, accents |
| `Color.rizqAccent` | `#6B4423` (Mocha) | Deep accents, level badge |

### Sand Palette

| Token | Hex | Usage |
|-------|-----|-------|
| `Color.sandWarm` | `#D4A574` | Primary buttons, progress |
| `Color.sandLight` | `#E6C79C` | Highlights |
| `Color.sandDeep` | `#A67C52` | Gradient end |

### Mocha Palette

| Token | Hex | Usage |
|-------|-----|-------|
| `Color.mocha` | `#6B4423` | Level badge, deep accents |
| `Color.mochaDeep` | `#2C2416` | Primary text |

### Cream Palette

| Token | Hex | Usage |
|-------|-----|-------|
| `Color.cream` | `#F5EFE7` | Page background |
| `Color.creamWarm` | `#FFFCF7` | Card background |

### Gold Palette

| Token | Hex | Usage |
|-------|-----|-------|
| `Color.goldSoft` | `#E6C79C` | XP badge background |
| `Color.goldBright` | `#FFEBB3` | Celebrations |

### Teal Palette

| Token | Hex | Usage |
|-------|-----|-------|
| `Color.tealMuted` | `#5B8A8A` | Anytime time slot |
| `Color.tealSuccess` | `#6B9B7C` | Completion states |

### Semantic Colors

| Token | Usage |
|-------|-------|
| `Color.rizqBackground` | Page backgrounds |
| `Color.rizqCard` | Card backgrounds |
| `Color.rizqSurface` | Input backgrounds |
| `Color.rizqText` | Primary text |
| `Color.rizqTextSecondary` | Secondary/muted text |
| `Color.rizqTextTertiary` | Tertiary/placeholder text |
| `Color.rizqMuted` | Disabled states, tracks |
| `Color.rizqBorder` | Card/input borders |

### Category Badge Colors

| Token | Hex | Category |
|-------|-----|----------|
| `Color.badgeMorning` | `#F59E0B` (Amber) | Morning adhkar |
| `Color.badgeEvening` | `#6366F1` (Indigo) | Evening adhkar |
| `Color.badgeRizq` | `#10B981` (Emerald) | Rizq/provision |
| `Color.badgeGratitude` | `#EC4899` (Pink) | Gratitude |

### Gamification Colors

| Token | Hex | Usage |
|-------|-----|-------|
| `Color.xpBar` | `#D4A574` | XP progress bar |
| `Color.streakGlow` | `#F59E0B` | Streak flame glow |
| `Color.levelBadge` | `#6B4423` | Level badge star |

## Typography

### Display Font (Playfair Display)

```swift
.font(.rizqDisplay(.title))        // Regular
.font(.rizqDisplayMedium(.title))  // Medium weight
.font(.rizqDisplaySemiBold(.title)) // SemiBold
.font(.rizqDisplayBold(.title))    // Bold
```

**Common Usage:**
| Style | SwiftUI |
|-------|---------|
| Page title | `.rizqDisplayBold(.largeTitle)` |
| Card title | `.rizqDisplayMedium(.headline)` |
| Section header | `.rizqDisplayMedium(.title3)` |
| User name | `.rizqDisplayBold(.title2)` |

### Sans Font (Crimson Pro)

```swift
.font(.rizqSans(.body))         // Regular
.font(.rizqSansMedium(.body))   // Medium weight
.font(.rizqSansSemiBold(.body)) // SemiBold
.font(.rizqSansBold(.body))     // Bold
```

**Common Usage:**
| Style | SwiftUI |
|-------|---------|
| Body text | `.rizqSans(.body)` |
| Caption | `.rizqSans(.caption)` |
| Subtitle | `.rizqSans(.subheadline)` |
| Button label | `.rizqSansSemiBold(.headline)` |
| Section label | `.rizqSansSemiBold(.caption).tracking(1)` |

### Arabic Font (Amiri)

```swift
.font(.rizqArabic(.title))     // Regular (1.3x size)
.font(.rizqArabicBold(.title)) // Bold (1.3x size)
```

**Usage:**
```swift
Text(arabicText)
  .font(.rizqArabic(.title))
  .environment(\.layoutDirection, .rightToLeft)
  .lineSpacing(12)
```

### Mono Font (JetBrains Mono)

```swift
.font(.rizqMono(.body))       // Regular
.font(.rizqMonoMedium(.body)) // Medium weight
```

**Common Usage:**
| Style | SwiftUI |
|-------|---------|
| XP numbers | `.rizqMono(.subheadline)` |
| Streak count | `.rizqMonoMedium(.title2)` |
| Level number | `.rizqMonoMedium(.headline)` |

### Text Style Sizes

| TextStyle | Default Size |
|-----------|--------------|
| `.largeTitle` | 34pt |
| `.title` | 28pt |
| `.title2` | 22pt |
| `.title3` | 20pt |
| `.headline` | 17pt |
| `.subheadline` | 15pt |
| `.body` | 17pt |
| `.callout` | 16pt |
| `.footnote` | 13pt |
| `.caption` | 12pt |
| `.caption2` | 11pt |

## Spacing

| Token | Value | Usage |
|-------|-------|-------|
| `RIZQSpacing.xs` | 4pt | Tight spacing, icon gaps |
| `RIZQSpacing.sm` | 8pt | Small gaps |
| `RIZQSpacing.md` | 12pt | Default component spacing |
| `RIZQSpacing.lg` | 16pt | Card padding, section gaps |
| `RIZQSpacing.xl` | 20pt | Large padding |
| `RIZQSpacing.xxl` | 24pt | Section spacing |
| `RIZQSpacing.xxxl` | 32pt | Large section spacing |
| `RIZQSpacing.huge` | 48pt | Page bottom padding |

## Corner Radius

| Token | Value | Usage |
|-------|-------|-------|
| `RIZQRadius.sm` | 8pt | Small elements |
| `RIZQRadius.md` | 12pt | Default (rounded-lg) |
| `RIZQRadius.btn` | 16pt | Buttons |
| `RIZQRadius.islamic` | 20pt | Cards, major containers |
| `RIZQRadius.lg` | 24pt | Large containers |
| `RIZQRadius.full` | 9999pt | Circles (use `.clipShape(Circle())`) |

## Shadows

### View Modifiers

```swift
// Subtle elevation (cards)
.shadowSoft()
// Shadow: color: black/0.08, radius: 8, y: 4

// Elevated state (hero cards)
.shadowElevated()
// Shadow: color: black/0.12, radius: 16, y: 8

// Primary button glow
.shadowGlowPrimary()
// Shadow: color: sandWarm/0.4, radius: 12, y: 4

// Streak badge glow
.shadowGlowStreak()
// Shadow: color: streakGlow/0.5, radius: 16, y: 0
```

## Gradients

```swift
// Primary gradient (buttons)
LinearGradient.rizqPrimaryGradient
// sandLight → sandWarm, topLeading → bottomTrailing

// Card gradient (subtle)
LinearGradient.rizqCardGradient
// creamWarm → cream, top → bottom

// Streak celebration
LinearGradient.streakGradient
// goldBright → goldSoft, topLeading → bottomTrailing
```

## Common Patterns

### Standard Card

```swift
content
  .padding(RIZQSpacing.lg)
  .background(Color.rizqCard)
  .clipShape(RoundedRectangle(cornerRadius: RIZQRadius.islamic))
  .shadowSoft()
```

### Using `.rizqCard()` modifier

```swift
content
  .rizqCard()  // Applies padding, background, cornerRadius, shadow
```

### Primary Button

```swift
Text("Button")
  .rizqPrimaryButton()  // Full styling
```

### Secondary Button

```swift
Text("Button")
  .rizqSecondaryButton()  // Outline styling
```

### Page Background

```swift
ScrollView {
  content
}
.rizqPageBackground()  // Applies background color
```

## Quick Copy Reference

### Card with border

```swift
.padding(RIZQSpacing.lg)
.background(Color.rizqCard)
.overlay(
  RoundedRectangle(cornerRadius: RIZQRadius.islamic)
    .stroke(Color.rizqBorder, lineWidth: 1)
)
.clipShape(RoundedRectangle(cornerRadius: RIZQRadius.islamic))
.shadowSoft()
```

### Gradient button

```swift
.background(
  LinearGradient(
    colors: [Color.rizqPrimary, Color.sandDeep],
    startPoint: .leading,
    endPoint: .trailing
  )
)
.clipShape(RoundedRectangle(cornerRadius: RIZQRadius.btn))
.shadow(color: Color.rizqPrimary.opacity(0.3), radius: 8, y: 4)
```

### Text styles combo

```swift
// Heading
Text("Title")
  .font(.rizqDisplayBold(.title2))
  .foregroundStyle(Color.rizqText)

// Body
Text("Content")
  .font(.rizqSans(.body))
  .foregroundStyle(Color.rizqText)

// Secondary
Text("Subtitle")
  .font(.rizqSans(.subheadline))
  .foregroundStyle(Color.rizqTextSecondary)

// Section label
Text("SECTION")
  .font(.rizqSansSemiBold(.caption))
  .foregroundStyle(Color.rizqTextSecondary)
  .tracking(1)

// Numbers
Text("\(count)")
  .font(.rizqMonoMedium(.title2))
  .foregroundStyle(Color.rizqText)
```
