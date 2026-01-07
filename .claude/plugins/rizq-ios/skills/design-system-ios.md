---
name: design-system-ios
description: "RIZQ design system translated to SwiftUI - colors, typography, spacing, shadows, and Islamic-inspired visual elements"
---

# RIZQ iOS Design System

This skill provides the complete translation of the RIZQ design system from Tailwind CSS to SwiftUI.

## Color Palette

### Swift Color Extensions

```swift
// Colors.swift
import SwiftUI

extension Color {
  // MARK: - Primary Colors (Warm Sand)
  static let rizqPrimary = Color(hue: 30/360, saturation: 0.52, brightness: 0.56)
  static let rizqPrimaryForeground = Color(hue: 40/360, saturation: 0.45, brightness: 0.98)

  // MARK: - Accent Colors (Deep Mocha)
  static let rizqAccent = Color(hue: 24/360, saturation: 0.50, brightness: 0.30)
  static let rizqAccentForeground = Color(hue: 38/360, saturation: 0.35, brightness: 0.96)

  // MARK: - Background & Surface
  static let rizqBackground = Color(hue: 38/360, saturation: 0.35, brightness: 0.96)  // #F5EFE7
  static let rizqCard = Color(hue: 40/360, saturation: 0.45, brightness: 0.98)        // #FFFCF7
  static let rizqMuted = Color(hue: 35/360, saturation: 0.18, brightness: 0.88)       // #E8DFD4

  // MARK: - Text Colors
  static let rizqForeground = Color(hue: 24/360, saturation: 0.40, brightness: 0.18)       // #2C2416
  static let rizqMutedForeground = Color(hue: 24/360, saturation: 0.15, brightness: 0.45)  // #7A7067

  // MARK: - Semantic Colors
  static let rizqSuccess = Color(hue: 158/360, saturation: 0.35, brightness: 0.42)    // #5B8A8A
  static let rizqDestructive = Color(hue: 0, saturation: 0.84, brightness: 0.60)      // #EF4444
  static let rizqWarning = Color(hue: 38/360, saturation: 0.92, brightness: 0.50)     // #F59E0B

  // MARK: - Border Colors
  static let rizqBorder = Color(hue: 30/360, saturation: 0.25, brightness: 0.88)      // #E8DFD4

  // MARK: - Named Design Tokens
  static let sandWarm = Color(hex: "D4A574")
  static let sandLight = Color(hex: "E6C79C")
  static let sandDeep = Color(hex: "A67C52")
  static let mocha = Color(hex: "6B4423")
  static let mochaDeep = Color(hex: "2C2416")
  static let cream = Color(hex: "F5EFE7")
  static let creamWarm = Color(hex: "FFFCF7")
  static let goldSoft = Color(hex: "E6C79C")
  static let goldBright = Color(hex: "FFEBB3")
  static let tealMuted = Color(hex: "5B8A8A")
  static let tealSuccess = Color(hex: "6B9B7C")
}

// MARK: - Hex Color Initializer
extension Color {
  init(hex: String) {
    let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
    var int: UInt64 = 0
    Scanner(string: hex).scanHexInt64(&int)
    let r, g, b: UInt64
    switch hex.count {
    case 6:
      (r, g, b) = (int >> 16, int >> 8 & 0xFF, int & 0xFF)
    case 8:
      (r, g, b) = (int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
    default:
      (r, g, b) = (0, 0, 0)
    }
    self.init(
      .sRGB,
      red: Double(r) / 255,
      green: Double(g) / 255,
      blue: Double(b) / 255
    )
  }
}
```

### Color Mapping (Tailwind → SwiftUI)

| Tailwind Class | SwiftUI |
|----------------|---------|
| `bg-background` | `.background(.rizqBackground)` |
| `bg-card` | `.background(.rizqCard)` |
| `bg-primary` | `.background(.rizqPrimary)` |
| `bg-primary/10` | `.background(.rizqPrimary.opacity(0.1))` |
| `text-foreground` | `.foregroundStyle(.rizqForeground)` |
| `text-muted-foreground` | `.foregroundStyle(.rizqMutedForeground)` |
| `text-primary` | `.foregroundStyle(.rizqPrimary)` |
| `border-border` | `.stroke(.rizqBorder)` |
| `border-border/50` | `.stroke(.rizqBorder.opacity(0.5))` |

---

## Typography

### Font Registration

```swift
// Typography.swift
import SwiftUI

extension Font {
  // MARK: - Display Font (Playfair Display)
  static func rizqDisplay(_ style: TextStyle) -> Font {
    switch style {
    case .largeTitle: return .custom("PlayfairDisplay-Bold", size: 34)
    case .title: return .custom("PlayfairDisplay-SemiBold", size: 28)
    case .title2: return .custom("PlayfairDisplay-SemiBold", size: 22)
    case .title3: return .custom("PlayfairDisplay-SemiBold", size: 20)
    case .headline: return .custom("PlayfairDisplay-SemiBold", size: 17)
    case .body: return .custom("CrimsonPro-Regular", size: 17)
    case .callout: return .custom("CrimsonPro-Regular", size: 16)
    case .subheadline: return .custom("CrimsonPro-Regular", size: 15)
    case .footnote: return .custom("CrimsonPro-Regular", size: 13)
    case .caption: return .custom("CrimsonPro-Regular", size: 12)
    case .caption2: return .custom("CrimsonPro-Regular", size: 11)
    @unknown default: return .custom("CrimsonPro-Regular", size: 17)
    }
  }

  // MARK: - Arabic Font (Amiri)
  static func rizqArabic(_ size: CGFloat) -> Font {
    .custom("Amiri-Regular", size: size)
  }

  static func rizqArabicBold(_ size: CGFloat) -> Font {
    .custom("Amiri-Bold", size: size)
  }

  // MARK: - Mono Font (JetBrains Mono)
  static func rizqMono(_ style: TextStyle) -> Font {
    switch style {
    case .body: return .custom("JetBrainsMono-Regular", size: 17)
    case .caption: return .custom("JetBrainsMono-Regular", size: 12)
    case .caption2: return .custom("JetBrainsMono-Regular", size: 11)
    default: return .custom("JetBrainsMono-Regular", size: 14)
    }
  }
}

// MARK: - Font Mapping (Tailwind → SwiftUI)
// font-display     → .font(.rizqDisplay(.title))
// font-serif       → .font(.rizqDisplay(.body))
// font-arabic      → .font(.rizqArabic(28))
// font-mono        → .font(.rizqMono(.body))
```

### Info.plist Font Configuration

```xml
<key>UIAppFonts</key>
<array>
  <string>PlayfairDisplay-Bold.ttf</string>
  <string>PlayfairDisplay-SemiBold.ttf</string>
  <string>CrimsonPro-Regular.ttf</string>
  <string>CrimsonPro-SemiBold.ttf</string>
  <string>Amiri-Regular.ttf</string>
  <string>Amiri-Bold.ttf</string>
  <string>JetBrainsMono-Regular.ttf</string>
</array>
```

---

## Spacing System

```swift
// Spacing.swift
enum RIZQSpacing {
  static let xxxs: CGFloat = 2   // 0.5 in Tailwind
  static let xxs: CGFloat = 4    // 1
  static let xs: CGFloat = 8     // 2
  static let sm: CGFloat = 12    // 3
  static let md: CGFloat = 16    // 4
  static let lg: CGFloat = 20    // 5
  static let xl: CGFloat = 24    // 6
  static let xxl: CGFloat = 32   // 8
  static let xxxl: CGFloat = 40  // 10
  static let huge: CGFloat = 48  // 12
  static let giant: CGFloat = 64 // 16

  // Bottom nav safe area
  static let navSafeArea: CGFloat = 96  // pb-24
}

// Usage: .padding(RIZQSpacing.md)
```

### Spacing Mapping

| Tailwind | SwiftUI |
|----------|---------|
| `p-4` | `.padding(RIZQSpacing.md)` |
| `px-5` | `.padding(.horizontal, RIZQSpacing.lg)` |
| `py-3` | `.padding(.vertical, RIZQSpacing.sm)` |
| `gap-4` | `spacing: RIZQSpacing.md` in VStack/HStack |
| `pb-24` | `.padding(.bottom, RIZQSpacing.navSafeArea)` |
| `space-y-6` | `VStack(spacing: RIZQSpacing.xl)` |

---

## Corner Radius

```swift
// CornerRadius.swift
enum RIZQRadius {
  static let sm: CGFloat = 8      // rounded-sm
  static let md: CGFloat = 10     // rounded-md
  static let lg: CGFloat = 12     // rounded-lg
  static let btn: CGFloat = 16    // rounded-btn
  static let islamic: CGFloat = 20 // rounded-islamic
  static let full: CGFloat = 9999 // rounded-full (use .clipShape(Capsule()))
}

// Usage: .clipShape(RoundedRectangle(cornerRadius: RIZQRadius.islamic, style: .continuous))
```

---

## Shadows

```swift
// Shadows.swift
extension View {
  /// Subtle elevation for cards
  func rizqShadowSoft() -> some View {
    self
      .shadow(color: .black.opacity(0.07), radius: 15, x: 0, y: 2)
      .shadow(color: .black.opacity(0.04), radius: 20, x: 0, y: 10)
  }

  /// Elevated hover state
  func rizqShadowElevated() -> some View {
    self
      .shadow(color: Color.mocha.opacity(0.15), radius: 40, x: 0, y: 10)
      .shadow(color: Color.mocha.opacity(0.05), radius: 6, x: 0, y: 4)
  }

  /// Primary button glow
  func rizqShadowGlowPrimary() -> some View {
    self.shadow(color: Color.sandWarm.opacity(0.4), radius: 30, x: 0, y: 0)
  }

  /// Streak badge glow
  func rizqShadowGlowStreak() -> some View {
    self.shadow(color: Color.goldSoft.opacity(0.6), radius: 25, x: 0, y: 0)
  }

  /// Inner glow for inputs
  func rizqInnerGlow() -> some View {
    self.overlay(
      RoundedRectangle(cornerRadius: RIZQRadius.lg, style: .continuous)
        .stroke(Color.sandWarm.opacity(0.1), lineWidth: 2)
        .blur(radius: 2)
        .offset(y: 1)
    )
  }
}
```

---

## View Modifiers

### Card Style

```swift
struct RIZQCardStyle: ViewModifier {
  var padding: CGFloat = RIZQSpacing.md

  func body(content: Content) -> some View {
    content
      .padding(padding)
      .background(.rizqCard)
      .clipShape(RoundedRectangle(cornerRadius: RIZQRadius.islamic, style: .continuous))
      .overlay(
        RoundedRectangle(cornerRadius: RIZQRadius.islamic, style: .continuous)
          .stroke(.rizqBorder.opacity(0.5), lineWidth: 1)
      )
      .rizqShadowSoft()
  }
}

extension View {
  func rizqCard(padding: CGFloat = RIZQSpacing.md) -> some View {
    modifier(RIZQCardStyle(padding: padding))
  }
}
```

### Button Styles

```swift
struct RIZQPrimaryButtonStyle: ButtonStyle {
  func makeBody(configuration: Configuration) -> some View {
    configuration.label
      .font(.rizqDisplay(.headline))
      .fontWeight(.semibold)
      .foregroundStyle(.rizqPrimaryForeground)
      .padding(.horizontal, RIZQSpacing.lg)
      .padding(.vertical, RIZQSpacing.sm)
      .background(
        LinearGradient(
          colors: [.sandWarm, .sandDeep],
          startPoint: .topLeading,
          endPoint: .bottomTrailing
        )
      )
      .clipShape(RoundedRectangle(cornerRadius: RIZQRadius.btn, style: .continuous))
      .rizqShadowSoft()
      .scaleEffect(configuration.isPressed ? 0.98 : 1)
      .animation(.spring(response: 0.2), value: configuration.isPressed)
  }
}

struct RIZQSecondaryButtonStyle: ButtonStyle {
  func makeBody(configuration: Configuration) -> some View {
    configuration.label
      .font(.rizqDisplay(.headline))
      .fontWeight(.medium)
      .foregroundStyle(.rizqAccent)
      .padding(.horizontal, RIZQSpacing.lg)
      .padding(.vertical, RIZQSpacing.sm)
      .background(.rizqMuted.opacity(0.5))
      .clipShape(RoundedRectangle(cornerRadius: RIZQRadius.btn, style: .continuous))
      .overlay(
        RoundedRectangle(cornerRadius: RIZQRadius.btn, style: .continuous)
          .stroke(.rizqBorder, lineWidth: 1)
      )
      .scaleEffect(configuration.isPressed ? 0.98 : 1)
      .animation(.spring(response: 0.2), value: configuration.isPressed)
  }
}

extension ButtonStyle where Self == RIZQPrimaryButtonStyle {
  static var rizqPrimary: RIZQPrimaryButtonStyle { RIZQPrimaryButtonStyle() }
}

extension ButtonStyle where Self == RIZQSecondaryButtonStyle {
  static var rizqSecondary: RIZQSecondaryButtonStyle { RIZQSecondaryButtonStyle() }
}
```

### Input Style

```swift
struct RIZQTextFieldStyle: TextFieldStyle {
  func _body(configuration: TextField<Self._Label>) -> some View {
    configuration
      .font(.rizqDisplay(.body))
      .padding(RIZQSpacing.md)
      .background(.rizqBackground)
      .clipShape(RoundedRectangle(cornerRadius: RIZQRadius.lg, style: .continuous))
      .overlay(
        RoundedRectangle(cornerRadius: RIZQRadius.lg, style: .continuous)
          .stroke(.rizqBorder, lineWidth: 1)
      )
  }
}
```

---

## Islamic Pattern Overlay

```swift
struct IslamicPatternOverlay: View {
  var opacity: Double = 0.04

  var body: some View {
    GeometryReader { geometry in
      // Use actual pattern image from Assets
      Image("islamic-pattern")
        .resizable(resizingMode: .tile)
        .opacity(opacity)
    }
    .allowsHitTesting(false)
  }
}

extension View {
  func islamicPatternBackground(opacity: Double = 0.04) -> some View {
    self.background(IslamicPatternOverlay(opacity: opacity))
  }
}
```

---

## Badge Styles

```swift
struct RIZQBadge: View {
  let text: String
  var color: Color = .rizqPrimary

  var body: some View {
    Text(text)
      .font(.rizqDisplay(.caption2))
      .fontWeight(.medium)
      .foregroundStyle(color)
      .padding(.horizontal, RIZQSpacing.xs + 2)
      .padding(.vertical, RIZQSpacing.xxxs)
      .background(color.opacity(0.1))
      .clipShape(Capsule())
  }
}

// Category-specific badges
extension RIZQBadge {
  static func morning(_ text: String) -> RIZQBadge {
    RIZQBadge(text: text, color: .orange)
  }

  static func evening(_ text: String) -> RIZQBadge {
    RIZQBadge(text: text, color: .indigo)
  }

  static func rizq(_ text: String) -> RIZQBadge {
    RIZQBadge(text: text, color: .tealMuted)
  }

  static func gratitude(_ text: String) -> RIZQBadge {
    RIZQBadge(text: text, color: .pink)
  }
}
```

---

## Arabic Text View

```swift
struct ArabicText: View {
  let text: String
  var size: CGFloat = 28
  var alignment: TextAlignment = .center

  var body: some View {
    Text(text)
      .font(.rizqArabic(size))
      .multilineTextAlignment(alignment)
      .lineSpacing(size * 0.5) // leading-[2.2] equivalent
      .environment(\.layoutDirection, .rightToLeft)
  }
}
```

---

## Complete Card Example

```swift
struct DuaCard: View {
  let dua: Dua
  var isCompleted: Bool = false

  var body: some View {
    VStack(alignment: .leading, spacing: RIZQSpacing.sm) {
      // Header
      HStack {
        Text(dua.title)
          .font(.rizqDisplay(.headline))
          .foregroundStyle(.rizqForeground)

        Spacer()

        if isCompleted {
          Image(systemName: "checkmark.circle.fill")
            .foregroundStyle(.rizqPrimary)
        }
      }

      // XP Badge
      HStack(spacing: RIZQSpacing.xxs) {
        Image(systemName: "sparkles")
          .font(.caption2)
          .foregroundStyle(.rizqPrimary)
        Text("+\(dua.xpValue) XP")
          .font(.rizqMono(.caption))
          .foregroundStyle(.rizqMutedForeground)
      }
    }
    .rizqCard()
  }
}
```
