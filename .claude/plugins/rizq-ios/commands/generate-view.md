---
name: generate-view
description: Create a SwiftUI view following RIZQ design system
allowed_tools:
  - Read
  - Write
  - Edit
  - Glob
arguments:
  - name: name
    description: Name of the view (e.g., "DuaCard", "StreakBadge")
    required: true
  - name: type
    description: "Type of view: card, button, badge, list, modal, or custom"
    required: false
---

# Generate SwiftUI View

Create a SwiftUI view component following the RIZQ design system.

## View Type: {{ type | default: "custom" }}

### Card View Template

```swift
import SwiftUI

struct {{ name }}: View {
  // MARK: - Properties
  let data: DataType
  var onTap: (() -> Void)? = nil

  // MARK: - State
  @State private var appeared = false

  var body: some View {
    Button(action: { onTap?() }) {
      VStack(alignment: .leading, spacing: RIZQSpacing.sm) {
        // Header
        HStack {
          Text(data.title)
            .font(.rizqDisplay(.headline))
            .fontWeight(.semibold)
            .foregroundStyle(.rizqForeground)

          Spacer()

          // Optional icon/badge
        }

        // Content
        Text(data.description)
          .font(.rizqDisplay(.subheadline))
          .foregroundStyle(.rizqMutedForeground)
          .lineLimit(2)
      }
      .padding(RIZQSpacing.md)
      .rizqCard()
    }
    .buttonStyle(CardButtonStyle())
    .opacity(appeared ? 1 : 0)
    .offset(y: appeared ? 0 : 15)
    .onAppear {
      withAnimation(.easeOut(duration: 0.4)) {
        appeared = true
      }
    }
  }
}

struct CardButtonStyle: ButtonStyle {
  func makeBody(configuration: Configuration) -> some View {
    configuration.label
      .scaleEffect(configuration.isPressed ? 0.98 : 1)
      .animation(.spring(response: 0.2), value: configuration.isPressed)
  }
}

#Preview {
  {{ name }}(data: .mock)
    .padding()
    .background(.rizqBackground)
}
```

### Badge View Template

```swift
import SwiftUI

struct {{ name }}: View {
  let value: Int
  var size: CGFloat = 40

  var body: some View {
    HStack(spacing: 4) {
      Image(systemName: "star.fill")
        .font(.system(size: size * 0.4))

      Text("\(value)")
        .font(.rizqMono(.headline))
        .fontWeight(.bold)
    }
    .foregroundStyle(.white)
    .padding(.horizontal, RIZQSpacing.sm)
    .padding(.vertical, RIZQSpacing.xs)
    .background(
      Capsule()
        .fill(
          LinearGradient(
            colors: [.rizqPrimary, .sandDeep],
            startPoint: .leading,
            endPoint: .trailing
          )
        )
    )
    .shadow(color: .rizqPrimary.opacity(0.3), radius: 8)
  }
}

#Preview {
  {{ name }}(value: 42)
    .padding()
    .background(.rizqBackground)
}
```

### List View Template

```swift
import SwiftUI

struct {{ name }}: View {
  let items: [ItemType]
  var onItemTap: ((ItemType) -> Void)? = nil

  var body: some View {
    ScrollView {
      LazyVStack(spacing: RIZQSpacing.sm) {
        ForEach(Array(items.enumerated()), id: \.element.id) { index, item in
          ItemRow(item: item)
            .staggeredAppear(index: index)
            .onTapGesture {
              onItemTap?(item)
            }
        }
      }
      .padding(.horizontal, RIZQSpacing.lg)
    }
  }
}

private struct ItemRow: View {
  let item: ItemType

  var body: some View {
    HStack(spacing: RIZQSpacing.md) {
      // Icon
      Image(systemName: item.icon)
        .font(.title3)
        .foregroundStyle(.rizqPrimary)
        .frame(width: 32)

      // Content
      VStack(alignment: .leading, spacing: 2) {
        Text(item.title)
          .font(.rizqDisplay(.body))
          .fontWeight(.medium)
          .foregroundStyle(.rizqForeground)

        Text(item.subtitle)
          .font(.rizqDisplay(.caption))
          .foregroundStyle(.rizqMutedForeground)
      }

      Spacer()

      // Chevron
      Image(systemName: "chevron.right")
        .font(.caption)
        .foregroundStyle(.rizqMutedForeground)
    }
    .padding(RIZQSpacing.md)
    .rizqCard()
  }
}

#Preview {
  {{ name }}(items: [.mock, .mock, .mock])
    .background(.rizqBackground)
}
```

### Modal View Template

```swift
import SwiftUI

struct {{ name }}: View {
  @Binding var isPresented: Bool
  var onConfirm: (() -> Void)? = nil

  var body: some View {
    VStack(spacing: RIZQSpacing.lg) {
      // Header
      HStack {
        Text("Title")
          .font(.rizqDisplay(.title2))
          .fontWeight(.bold)

        Spacer()

        Button {
          isPresented = false
        } label: {
          Image(systemName: "xmark")
            .font(.body)
            .foregroundStyle(.rizqMutedForeground)
        }
      }

      // Content
      Text("Modal content goes here")
        .font(.rizqDisplay(.body))
        .foregroundStyle(.rizqForeground)

      Spacer()

      // Actions
      HStack(spacing: RIZQSpacing.sm) {
        Button("Cancel") {
          isPresented = false
        }
        .buttonStyle(.rizqSecondary)

        Button("Confirm") {
          onConfirm?()
          isPresented = false
        }
        .buttonStyle(.rizqPrimary)
      }
    }
    .padding(RIZQSpacing.lg)
    .background(.rizqCard)
    .clipShape(RoundedRectangle(cornerRadius: RIZQRadius.islamic))
    .padding(RIZQSpacing.lg)
    .transition(.move(edge: .bottom).combined(with: .opacity))
  }
}

#Preview {
  {{ name }}(isPresented: .constant(true))
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(.black.opacity(0.5))
}
```

## Design System Reference

- Colors: `.rizqPrimary`, `.rizqBackground`, `.rizqCard`, `.rizqForeground`, `.rizqMutedForeground`
- Typography: `.rizqDisplay(_:)`, `.rizqMono(_:)`, `.rizqArabic(_:)`
- Spacing: `RIZQSpacing.xs/sm/md/lg/xl/xxl`
- Radius: `RIZQRadius.sm/md/lg/btn/islamic`
- Modifiers: `.rizqCard()`, `.rizqShadowSoft()`, `.islamicPatternBackground()`
