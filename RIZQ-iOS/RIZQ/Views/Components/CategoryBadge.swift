import SwiftUI
import RIZQKit

/// Category badge pill component matching React's badge-morning, badge-evening, etc.
/// Displays category with emoji icon and colored background
struct CategoryBadge: View {
  let category: CategorySlug
  var size: BadgeSize = .regular

  enum BadgeSize {
    case small
    case regular
    case large

    var horizontalPadding: CGFloat {
      switch self {
      case .small: return 8
      case .regular: return 10
      case .large: return 14
      }
    }

    var verticalPadding: CGFloat {
      switch self {
      case .small: return 4
      case .regular: return 6
      case .large: return 8
      }
    }

    var font: Font {
      switch self {
      case .small: return .rizqSansMedium(.caption2)
      case .regular: return .rizqSansMedium(.caption)
      case .large: return .rizqSansMedium(.subheadline)
      }
    }

    var emojiSize: CGFloat {
      switch self {
      case .small: return 10
      case .regular: return 12
      case .large: return 14
      }
    }
  }

  var body: some View {
    HStack(spacing: 4) {
      Text(category.emoji)
        .font(.system(size: size.emojiSize))

      Text(category.displayName)
        .font(size.font)
    }
    .padding(.horizontal, size.horizontalPadding)
    .padding(.vertical, size.verticalPadding)
    .background(category.color.opacity(0.15))
    .foregroundStyle(category.color)
    .clipShape(Capsule())
  }
}

// MARK: - CategorySlug Extensions for Badge Display

extension CategorySlug {
  /// Emoji representation for the category
  var emoji: String {
    switch self {
    case .morning: return "🌅"
    case .evening: return "🌙"
    case .rizq: return "💰"
    case .gratitude: return "🤲"
    }
  }

  /// Display name for the category
  var displayName: String {
    switch self {
    case .morning: return "Morning"
    case .evening: return "Evening"
    case .rizq: return "Rizq"
    case .gratitude: return "Gratitude"
    }
  }

  /// Color for the category badge
  var color: Color {
    switch self {
    case .morning: return .badgeMorning
    case .evening: return .badgeEvening
    case .rizq: return .badgeRizq
    case .gratitude: return .badgeGratitude
    }
  }
}

// MARK: - Time Slot Badge Variant

/// Badge for displaying time slots (morning, anytime, evening)
struct TimeSlotBadge: View {
  let timeSlot: TimeSlot
  var size: CategoryBadge.BadgeSize = .regular

  var body: some View {
    HStack(spacing: 4) {
      Image(systemName: timeSlot.icon)
        .font(.system(size: size.emojiSize))

      Text(timeSlot.displayName)
        .font(size.font)
    }
    .padding(.horizontal, size.horizontalPadding)
    .padding(.vertical, size.verticalPadding)
    .background(timeSlot.badgeColor.opacity(0.15))
    .foregroundStyle(timeSlot.badgeColor)
    .clipShape(Capsule())
  }
}

// MARK: - TimeSlot Badge Extensions

extension TimeSlot {
  /// Color for the time slot badge
  var badgeColor: Color {
    switch self {
    case .morning: return .badgeMorning
    case .anytime: return .tealMuted
    case .evening: return .badgeEvening
    }
  }
}

// MARK: - Previews

#Preview("Category Badges") {
  VStack(spacing: 20) {
    Text("Regular Size")
      .font(.headline)

    HStack(spacing: 12) {
      ForEach(CategorySlug.allCases, id: \.rawValue) { category in
        CategoryBadge(category: category)
      }
    }

    Text("Small Size")
      .font(.headline)
      .padding(.top)

    HStack(spacing: 8) {
      ForEach(CategorySlug.allCases, id: \.rawValue) { category in
        CategoryBadge(category: category, size: .small)
      }
    }

    Text("Large Size")
      .font(.headline)
      .padding(.top)

    HStack(spacing: 16) {
      ForEach(CategorySlug.allCases, id: \.rawValue) { category in
        CategoryBadge(category: category, size: .large)
      }
    }
  }
  .padding()
  .background(Color.rizqBackground)
}

#Preview("Time Slot Badges") {
  VStack(spacing: 16) {
    ForEach(TimeSlot.allCases) { timeSlot in
      TimeSlotBadge(timeSlot: timeSlot)
    }
  }
  .padding()
  .background(Color.rizqBackground)
}
