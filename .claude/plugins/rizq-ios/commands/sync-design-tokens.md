---
name: sync-design-tokens
description: Sync design tokens from tailwind.config.ts to Swift
allowed_tools:
  - Read
  - Write
  - Edit
  - Grep
---

# Sync Design Tokens

Update iOS design system files to match the React app's Tailwind configuration.

## Source Files

- `tailwind.config.ts` - Tailwind color/spacing/typography definitions
- `src/index.css` - CSS custom properties

## Target Files

- `Shared/DesignSystem/Colors.swift`
- `Shared/DesignSystem/Typography.swift`
- `Shared/DesignSystem/Spacing.swift`

## Sync Process

1. **Read Tailwind config** and extract:
   - Color palette (sand, mocha, cream, gold, teal)
   - Spacing scale
   - Border radius values
   - Shadow definitions

2. **Read CSS variables** from index.css:
   - Background/foreground colors
   - Primary/secondary/accent
   - Muted colors
   - Destructive/success colors

3. **Generate Swift extensions**:

### Colors.swift Template

```swift
import SwiftUI

// MARK: - Semantic Colors (CSS Variables)
extension Color {
  static let rizqBackground = Color(hex: "#F5EFE7")      // --background
  static let rizqForeground = Color(hex: "#2C2416")      // --foreground
  static let rizqPrimary = Color(hex: "#D4A574")         // --primary
  static let rizqSecondary = Color(hex: "#E8DFD4")       // --secondary
  static let rizqAccent = Color(hex: "#6B4423")          // --accent
  static let rizqMuted = Color(hex: "#D9D0C4")           // --muted
  static let rizqMutedForeground = Color(hex: "#78716C") // --muted-foreground
  static let rizqCard = Color(hex: "#FFFCF7")            // --card
  static let rizqBorder = Color(hex: "#E6C79C")          // --border
  static let rizqDestructive = Color(hex: "#DC2626")     // --destructive
  static let rizqSuccess = Color(hex: "#5B8A8A")         // --success
}

// MARK: - Named Colors (Tailwind Palette)
extension Color {
  // Sand palette
  static let sandWarm = Color(hex: "#D4A574")
  static let sandLight = Color(hex: "#E6C79C")
  static let sandDeep = Color(hex: "#A67C52")

  // Mocha palette
  static let mocha = Color(hex: "#6B4423")
  static let mochaDeep = Color(hex: "#2C2416")

  // Cream palette
  static let cream = Color(hex: "#F5EFE7")
  static let creamWarm = Color(hex: "#FFFCF7")

  // Gold palette
  static let goldSoft = Color(hex: "#E6C79C")
  static let goldBright = Color(hex: "#FFEBB3")

  // Teal palette
  static let tealMuted = Color(hex: "#5B8A8A")
  static let tealSuccess = Color(hex: "#6B9B7C")
}

// MARK: - Hex Initializer
extension Color {
  init(hex: String) {
    let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
    var int: UInt64 = 0
    Scanner(string: hex).scanHexInt64(&int)
    let a, r, g, b: UInt64
    switch hex.count {
    case 3: // RGB (12-bit)
      (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
    case 6: // RGB (24-bit)
      (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
    case 8: // ARGB (32-bit)
      (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
    default:
      (a, r, g, b) = (255, 0, 0, 0)
    }
    self.init(
      .sRGB,
      red: Double(r) / 255,
      green: Double(g) / 255,
      blue: Double(b) / 255,
      opacity: Double(a) / 255
    )
  }
}
```

## Token Mapping Table

| CSS Variable | Tailwind Class | Swift Color |
|--------------|----------------|-------------|
| `--background` | `bg-background` | `.rizqBackground` |
| `--foreground` | `text-foreground` | `.rizqForeground` |
| `--primary` | `bg-primary` | `.rizqPrimary` |
| `--secondary` | `bg-secondary` | `.rizqSecondary` |
| `--accent` | `bg-accent` | `.rizqAccent` |
| `--muted` | `bg-muted` | `.rizqMuted` |
| `--card` | `bg-card` | `.rizqCard` |
| `--border` | `border-border` | `.rizqBorder` |

## Spacing Mapping

| Tailwind | Value | Swift |
|----------|-------|-------|
| `p-1` | 4px | `RIZQSpacing.xxs` |
| `p-2` | 8px | `RIZQSpacing.xs` |
| `p-3` | 12px | `RIZQSpacing.sm` |
| `p-4` | 16px | `RIZQSpacing.md` |
| `p-5` | 20px | `RIZQSpacing.lg` |
| `p-6` | 24px | `RIZQSpacing.xl` |
| `p-8` | 32px | `RIZQSpacing.xxl` |

## After Syncing

1. Build the iOS project to verify no compile errors
2. Check color contrast meets WCAG guidelines
3. Test in both light and dark modes
4. Update any hardcoded color values in views
