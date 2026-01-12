---
name: ios-component
description: "Create beautiful SwiftUI components using the RIZQ design system - cards, badges, buttons, progress indicators"
---

# iOS Component Skill

This skill helps create beautiful SwiftUI components that match the RIZQ warm Islamic aesthetic.

## Design Philosophy

RIZQ uses a **warm, luxury Islamic aesthetic**:
- Warm sand/cream color palette
- Elegant serif typography (Playfair Display for headings, Crimson Pro for body)
- Generous spacing and rounded corners
- Soft shadows that feel elevated but not harsh
- Islamic geometric pattern accents

## Component Structure Pattern

```swift
import SwiftUI
import RIZQKit

struct MyComponent: View {
  // 1. Properties with sensible defaults
  let title: String
  let subtitle: String?
  let isHighlighted: Bool

  init(title: String, subtitle: String? = nil, isHighlighted: Bool = false) {
    self.title = title
    self.subtitle = subtitle
    self.isHighlighted = isHighlighted
  }

  // 2. Body with RIZQKit design tokens
  var body: some View {
    VStack(alignment: .leading, spacing: RIZQSpacing.md) {
      Text(title)
        .font(.rizqDisplayMedium(.headline))
        .foregroundStyle(Color.rizqText)

      if let subtitle = subtitle {
        Text(subtitle)
          .font(.rizqSans(.subheadline))
          .foregroundStyle(Color.rizqTextSecondary)
      }
    }
    .padding(RIZQSpacing.lg)
    .background(Color.rizqCard)
    .clipShape(RoundedRectangle(cornerRadius: RIZQRadius.islamic))
    .shadowSoft()
  }
}

// 3. Always include previews
#Preview("My Component") {
  MyComponent(title: "Title", subtitle: "Subtitle")
    .padding()
    .background(Color.rizqBackground)
}
```

## Card Components

### Basic Card

```swift
struct RIZQCard<Content: View>: View {
  let content: Content

  init(@ViewBuilder content: () -> Content) {
    self.content = content()
  }

  var body: some View {
    content
      .padding(RIZQSpacing.lg)
      .background(Color.rizqCard)
      .clipShape(RoundedRectangle(cornerRadius: RIZQRadius.islamic))
      .shadowSoft()
  }
}

// Usage
RIZQCard {
  VStack(alignment: .leading) {
    Text("Card Title")
    Text("Card content here")
  }
}
```

### Elevated Card (Hero sections)

```swift
struct RIZQElevatedCard<Content: View>: View {
  let borderColor: Color
  let content: Content

  init(borderColor: Color = .rizqPrimary.opacity(0.1), @ViewBuilder content: () -> Content) {
    self.borderColor = borderColor
    self.content = content()
  }

  var body: some View {
    content
      .padding(RIZQSpacing.xl)
      .background(Color.rizqCard)
      .overlay(
        RoundedRectangle(cornerRadius: RIZQRadius.islamic)
          .stroke(borderColor, lineWidth: 2)
      )
      .clipShape(RoundedRectangle(cornerRadius: RIZQRadius.islamic))
      .shadowElevated()
  }
}
```

### Tappable Card

```swift
struct TappableCard<Content: View>: View {
  let action: () -> Void
  let content: Content
  @State private var isPressed = false

  init(action: @escaping () -> Void, @ViewBuilder content: () -> Content) {
    self.action = action
    self.content = content()
  }

  var body: some View {
    Button(action: action) {
      content
        .padding(RIZQSpacing.lg)
        .background(Color.rizqCard)
        .clipShape(RoundedRectangle(cornerRadius: RIZQRadius.islamic))
        .shadowSoft()
    }
    .buttonStyle(ScaleButtonStyle())
  }
}
```

## Badge Components

### Category Badge

```swift
struct CategoryBadge: View {
  let category: CategorySlug

  var body: some View {
    HStack(spacing: RIZQSpacing.xs) {
      Image(systemName: category.icon)
        .font(.caption2)

      Text(category.displayName)
        .font(.rizqSansMedium(.caption))
    }
    .foregroundStyle(category.color)
    .padding(.horizontal, RIZQSpacing.sm)
    .padding(.vertical, RIZQSpacing.xs)
    .background(category.color.opacity(0.15))
    .clipShape(Capsule())
  }
}

extension CategorySlug {
  var icon: String {
    switch self {
    case .morning: return "sun.max.fill"
    case .evening: return "moon.fill"
    case .rizq: return "leaf.fill"
    case .gratitude: return "heart.fill"
    }
  }

  var color: Color {
    switch self {
    case .morning: return .badgeMorning
    case .evening: return .badgeEvening
    case .rizq: return .badgeRizq
    case .gratitude: return .badgeGratitude
    }
  }
}
```

### XP Earned Badge

```swift
struct XpEarnedBadge: View {
  let xp: Int
  @State private var isVisible = false

  var body: some View {
    HStack(spacing: RIZQSpacing.xs) {
      Image(systemName: "sparkles")
        .font(.system(size: 16, weight: .medium))

      Text("+\(xp)")
        .font(.rizqDisplayBold(.title3))

      Text("XP")
        .font(.rizqSans(.caption))
        .foregroundStyle(Color.rizqTextSecondary)
    }
    .foregroundStyle(Color.rizqPrimary)
    .padding(.horizontal, RIZQSpacing.md)
    .padding(.vertical, RIZQSpacing.sm)
    .background(Color.goldSoft.opacity(0.2))
    .overlay(
      RoundedRectangle(cornerRadius: 20)
        .stroke(Color.goldSoft.opacity(0.3), lineWidth: 1)
    )
    .clipShape(RoundedRectangle(cornerRadius: 20))
    .scaleEffect(isVisible ? 1 : 0.8)
    .opacity(isVisible ? 1 : 0)
    .onAppear {
      withAnimation(.spring(response: 0.5, dampingFraction: 0.6).delay(0.5)) {
        isVisible = true
      }
    }
  }
}
```

### Level Badge

```swift
struct LevelBadge: View {
  let level: Int
  let size: CGFloat

  init(level: Int, size: CGFloat = 80) {
    self.level = level
    self.size = size
  }

  var body: some View {
    ZStack {
      Circle()
        .fill(Color.levelBadge.opacity(0.1))
        .frame(width: size, height: size)

      VStack(spacing: 4) {
        Image(systemName: "star.fill")
          .font(.system(size: size * 0.25))
          .foregroundStyle(Color.levelBadge)

        Text("\(level)")
          .font(.rizqMonoMedium(.title3))
          .foregroundStyle(Color.rizqText)
      }
    }
  }
}
```

## Button Components

### Primary Button

```swift
struct RIZQPrimaryButton: View {
  let title: String
  let icon: String?
  let action: () -> Void

  init(_ title: String, icon: String? = nil, action: @escaping () -> Void) {
    self.title = title
    self.icon = icon
    self.action = action
  }

  var body: some View {
    Button(action: action) {
      HStack(spacing: RIZQSpacing.sm) {
        if let icon = icon {
          Image(systemName: icon)
            .font(.body.weight(.medium))
        }

        Text(title)
          .font(.rizqDisplayMedium(.subheadline))
      }
      .foregroundStyle(.white)
      .frame(maxWidth: .infinity)
      .padding(.vertical, RIZQSpacing.md)
      .background(
        LinearGradient(
          colors: [Color.rizqPrimary, Color.sandDeep],
          startPoint: .leading,
          endPoint: .trailing
        )
      )
      .clipShape(RoundedRectangle(cornerRadius: RIZQRadius.btn))
      .shadow(color: Color.rizqPrimary.opacity(0.3), radius: 8, y: 4)
    }
    .buttonStyle(ScaleButtonStyle())
  }
}

// Usage
RIZQPrimaryButton("Browse Journeys", icon: "compass") {
  // action
}
```

### Secondary Button

```swift
struct RIZQSecondaryButton: View {
  let title: String
  let icon: String?
  let iconPosition: IconPosition
  let action: () -> Void

  enum IconPosition { case leading, trailing }

  init(_ title: String, icon: String? = nil, iconPosition: IconPosition = .leading, action: @escaping () -> Void) {
    self.title = title
    self.icon = icon
    self.iconPosition = iconPosition
    self.action = action
  }

  var body: some View {
    Button(action: action) {
      HStack(spacing: RIZQSpacing.sm) {
        if iconPosition == .leading, let icon = icon {
          Image(systemName: icon).font(.body.weight(.medium))
        }

        Text(title)
          .font(.rizqDisplayMedium(.subheadline))

        if iconPosition == .trailing, let icon = icon {
          Image(systemName: icon).font(.body.weight(.medium))
        }
      }
      .foregroundStyle(Color.rizqText)
      .frame(maxWidth: .infinity)
      .padding(.vertical, RIZQSpacing.md)
      .background(Color.rizqCard)
      .overlay(
        RoundedRectangle(cornerRadius: RIZQRadius.islamic)
          .stroke(Color.rizqPrimary.opacity(0.2), lineWidth: 1)
      )
      .clipShape(RoundedRectangle(cornerRadius: RIZQRadius.islamic))
    }
    .buttonStyle(ScaleButtonStyle())
  }
}

// Usage
RIZQSecondaryButton("Explore All Duas", icon: "arrow.right", iconPosition: .trailing) {
  // action
}
```

## Progress Components

### Habits Summary Card

```swift
struct HabitsSummaryCard: View {
  let completed: Int
  let total: Int
  let percentage: Double
  let xpEarned: Int
  let onTap: () -> Void

  private var isAllComplete: Bool {
    total > 0 && completed == total
  }

  var body: some View {
    Button(action: onTap) {
      VStack(alignment: .leading, spacing: RIZQSpacing.md) {
        // Header row
        HStack {
          HStack(spacing: RIZQSpacing.sm) {
            iconCircle
            Text("Today's Habits")
              .font(.rizqSansSemiBold(.headline))
              .foregroundStyle(Color.rizqText)
          }
          Spacer()
          Text("\(completed)/\(total)")
            .font(.rizqMono(.subheadline))
            .foregroundStyle(Color.rizqTextSecondary)
        }

        // Progress bar
        progressBar

        // Footer
        HStack {
          Text(isAllComplete ? "All habits complete!" : "\(total - completed) remaining")
            .font(.rizqSans(.caption))
            .foregroundStyle(Color.rizqTextSecondary)
          Spacer()
          if xpEarned > 0 {
            Text("+\(xpEarned) XP earned")
              .font(.rizqSansMedium(.caption))
              .foregroundStyle(Color.rizqPrimary)
          }
        }
      }
      .padding(RIZQSpacing.lg)
      .background(isAllComplete ? Color.tealSuccess.opacity(0.05) : Color.rizqCard)
      .overlay(
        RoundedRectangle(cornerRadius: RIZQRadius.islamic)
          .stroke(isAllComplete ? Color.tealSuccess.opacity(0.3) : Color.rizqBorder, lineWidth: 1)
      )
      .clipShape(RoundedRectangle(cornerRadius: RIZQRadius.islamic))
      .shadowSoft()
    }
    .buttonStyle(ScaleButtonStyle())
  }

  private var iconCircle: some View {
    ZStack {
      Circle()
        .fill(isAllComplete ? Color.tealSuccess.opacity(0.2) : Color.rizqPrimary.opacity(0.1))
        .frame(width: 32, height: 32)

      Image(systemName: isAllComplete ? "checkmark" : "target")
        .font(.subheadline.weight(.semibold))
        .foregroundStyle(isAllComplete ? Color.tealSuccess : Color.rizqPrimary)
    }
  }

  private var progressBar: some View {
    GeometryReader { geometry in
      ZStack(alignment: .leading) {
        Capsule()
          .fill(Color.rizqMuted.opacity(0.3))
          .frame(height: 8)

        Capsule()
          .fill(isAllComplete ? Color.tealSuccess : Color.rizqPrimary)
          .frame(width: geometry.size.width * percentage, height: 8)
          .animation(.easeOut(duration: 0.5), value: percentage)
      }
    }
    .frame(height: 8)
  }
}
```

## Row Components

### Action Row (Navigation)

```swift
struct ActionRow: View {
  let icon: String
  let iconColor: Color
  let title: String
  let subtitle: String
  let action: () -> Void

  var body: some View {
    Button(action: action) {
      HStack(spacing: RIZQSpacing.md) {
        // Icon circle
        ZStack {
          Circle()
            .fill(iconColor.opacity(0.15))
            .frame(width: 44, height: 44)

          Image(systemName: icon)
            .font(.title3)
            .foregroundStyle(iconColor)
        }

        // Text
        VStack(alignment: .leading, spacing: 2) {
          Text(title)
            .font(.rizqSansSemiBold(.body))
            .foregroundStyle(Color.rizqText)

          Text(subtitle)
            .font(.rizqSans(.caption))
            .foregroundStyle(Color.rizqTextSecondary)
        }

        Spacer()

        // Chevron
        Image(systemName: "chevron.right")
          .font(.subheadline.weight(.medium))
          .foregroundStyle(Color.rizqMuted)
      }
      .padding(RIZQSpacing.lg)
      .background(Color.rizqCard)
      .clipShape(RoundedRectangle(cornerRadius: RIZQRadius.islamic))
      .shadowSoft()
    }
    .buttonStyle(ScaleButtonStyle())
  }
}

// Usage
ActionRow(
  icon: "sun.max.fill",
  iconColor: .badgeMorning,
  title: "Morning Adhkar",
  subtitle: "Start your day with remembrance"
) {
  // Navigate to morning adhkar
}
```

## User Components

### User Avatar

```swift
struct UserAvatar: View {
  let imageURL: URL?
  let displayName: String
  let size: CGFloat

  init(imageURL: URL? = nil, displayName: String, size: CGFloat = 56) {
    self.imageURL = imageURL
    self.displayName = displayName
    self.size = size
  }

  var body: some View {
    ZStack {
      if let imageURL = imageURL {
        AsyncImage(url: imageURL) { phase in
          switch phase {
          case .success(let image):
            image.resizable().scaledToFill()
          default:
            fallbackAvatar
          }
        }
      } else {
        fallbackAvatar
      }
    }
    .frame(width: size, height: size)
    .clipShape(Circle())
    .overlay(Circle().stroke(Color.rizqPrimary.opacity(0.2), lineWidth: 2))
    .shadow(color: Color.black.opacity(0.1), radius: 4, y: 2)
  }

  private var fallbackAvatar: some View {
    ZStack {
      LinearGradient(
        colors: [Color.rizqPrimary.opacity(0.2), Color.rizqPrimary.opacity(0.1)],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
      )

      Text(initials)
        .font(.rizqDisplayBold(.headline))
        .foregroundStyle(Color.rizqPrimary)
    }
  }

  private var initials: String {
    let parts = displayName.components(separatedBy: " ")
    let first = parts.first?.prefix(1) ?? ""
    let last = parts.count > 1 ? parts.last?.prefix(1) ?? "" : ""
    return "\(first)\(last)".uppercased()
  }
}
```

## Section Headers

### Section Title

```swift
struct SectionTitle: View {
  let title: String
  let trailing: (() -> AnyView)?

  init(_ title: String, trailing: (() -> AnyView)? = nil) {
    self.title = title
    self.trailing = trailing
  }

  var body: some View {
    HStack {
      Text(title.uppercased())
        .font(.rizqSansSemiBold(.caption))
        .foregroundStyle(Color.rizqTextSecondary)
        .tracking(1)

      Spacer()

      trailing?()
    }
  }
}

// Usage
SectionTitle("Daily Adkhar")
SectionTitle("This Week") {
  AnyView(Text("2/7 days").font(.rizqSans(.caption)))
}
```

## File Organization

Place components in:
```
RIZQ/Views/Components/
├── Cards/
│   ├── RIZQCard.swift
│   └── TappableCard.swift
├── Badges/
│   ├── CategoryBadge.swift
│   ├── XpEarnedBadge.swift
│   └── LevelBadge.swift
├── Buttons/
│   ├── RIZQPrimaryButton.swift
│   └── RIZQSecondaryButton.swift
├── Progress/
│   └── HabitsSummaryCard.swift
├── Rows/
│   └── ActionRow.swift
└── User/
    └── UserAvatar.swift
```

## Component Checklist

When creating components:
- [ ] Use RIZQKit design tokens (RIZQSpacing, RIZQRadius, Color.rizq*)
- [ ] Use RIZQKit typography (.rizqDisplay*, .rizqSans*, .rizqMono*)
- [ ] Add sensible default values to init
- [ ] Include previews with light/dark variants
- [ ] Support accessibility labels
- [ ] Match React component behavior where applicable
