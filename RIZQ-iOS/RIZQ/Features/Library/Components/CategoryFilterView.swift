import SwiftUI
import RIZQKit

/// Horizontal scrolling category filter chips
struct CategoryFilterView: View {
  let categories: [CategoryDisplay]
  let selectedCategory: CategorySlug?
  let onCategorySelected: (CategorySlug?) -> Void

  var body: some View {
    VStack(alignment: .leading, spacing: RIZQSpacing.md) {
      // Label
      HStack(spacing: RIZQSpacing.sm) {
        Image(systemName: "line.3.horizontal.decrease.circle")
          .font(.system(size: 14))
          .foregroundStyle(Color.rizqTextSecondary)

        Text("Filter by category")
          .font(.rizqSansMedium(.subheadline))
          .foregroundStyle(Color.rizqTextSecondary)
      }

      // Filter chips
      ScrollView(.horizontal, showsIndicators: false) {
        HStack(spacing: RIZQSpacing.md) {
          // "All" chip
          CategoryChip(
            label: "All",
            icon: nil,
            isSelected: selectedCategory == nil,
            color: nil,
            onTap: { onCategorySelected(nil) }
          )

          // Category chips
          ForEach(categories) { category in
            CategoryChip(
              label: category.name,
              icon: category.icon,
              isSelected: selectedCategory == category.slug,
              color: categoryColor(for: category.slug),
              onTap: { onCategorySelected(category.slug) }
            )
          }
        }
      }
    }
  }

  private func categoryColor(for slug: CategorySlug?) -> Color {
    switch slug {
    case .morning: return .badgeMorning
    case .evening: return .badgeEvening
    case .rizq: return .badgeRizq
    case .gratitude: return .badgeGratitude
    case nil: return .rizqPrimary
    }
  }
}

/// Individual filter chip button
struct CategoryChip: View {
  let label: String
  let icon: String?
  let isSelected: Bool
  let color: Color?
  let onTap: () -> Void

  var body: some View {
    Button(action: onTap) {
      HStack(spacing: RIZQSpacing.xs) {
        if let icon = icon {
          Image(systemName: icon)
            .font(.system(size: 12))
        }

        Text(label)
          .font(.rizqSansMedium(.subheadline))
      }
      .padding(.horizontal, RIZQSpacing.lg)
      .padding(.vertical, RIZQSpacing.sm)
      .foregroundStyle(foregroundColor)
      .background(backgroundColor)
      .clipShape(Capsule())
      .overlay(
        Capsule()
          .stroke(borderColor, lineWidth: isSelected ? 0 : 1)
      )
    }
    .buttonStyle(.plain)
    .animation(.easeInOut(duration: 0.2), value: isSelected)
  }

  private var foregroundColor: Color {
    if isSelected {
      return .white
    }
    return Color.rizqText
  }

  private var backgroundColor: Color {
    if isSelected {
      return color ?? Color.rizqPrimary
    }
    return Color.rizqCard
  }

  private var borderColor: Color {
    if isSelected {
      return .clear
    }
    return Color.rizqBorder
  }
}

// MARK: - Preview

#Preview {
  VStack(spacing: 32) {
    CategoryFilterView(
      categories: CategoryDisplay.allCategories,
      selectedCategory: nil,
      onCategorySelected: { _ in }
    )

    CategoryFilterView(
      categories: CategoryDisplay.allCategories,
      selectedCategory: .morning,
      onCategorySelected: { _ in }
    )

    CategoryFilterView(
      categories: CategoryDisplay.allCategories,
      selectedCategory: .rizq,
      onCategorySelected: { _ in }
    )
  }
  .padding()
  .background(Color.rizqBackground)
}
