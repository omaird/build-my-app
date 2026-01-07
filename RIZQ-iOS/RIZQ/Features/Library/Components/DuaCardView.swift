import SwiftUI
import RIZQKit

/// A card view displaying a dua in the library grid
struct DuaCardView: View {
  let dua: Dua
  let onTap: () -> Void
  let onAddToAdkhar: () -> Void

  var body: some View {
    Button(action: onTap) {
      VStack(alignment: .leading, spacing: RIZQSpacing.md) {
        // Header with category badge
        headerRow

        // Arabic text
        arabicTextView

        // Footer with difficulty and XP
        footerRow
      }
      .padding(RIZQSpacing.lg)
      .background(Color.rizqCard)
      .clipShape(RoundedRectangle(cornerRadius: RIZQRadius.islamic))
      .shadowSoft()
    }
    .buttonStyle(.plain)
    .contextMenu {
      contextMenuItems
    }
  }

  // MARK: - Header Row
  private var headerRow: some View {
    VStack(alignment: .leading, spacing: RIZQSpacing.sm) {
      // Category icon and badge
      HStack {
        categoryBadge

        Spacer()

        // Add to Adkhar button
        Button(action: onAddToAdkhar) {
          Image(systemName: "plus.circle")
            .font(.system(size: 20, weight: .medium))
            .foregroundStyle(Color.rizqPrimary)
        }
        .buttonStyle(.plain)
      }

      // Title
      Text(dua.titleEn)
        .font(.rizqSansSemiBold(.subheadline))
        .foregroundStyle(Color.rizqText)
        .lineLimit(2)
        .fixedSize(horizontal: false, vertical: true)
    }
  }

  // MARK: - Category Badge
  private var categoryBadge: some View {
    let displayCategory = categoryDisplay

    return HStack(spacing: RIZQSpacing.xs) {
      Image(systemName: displayCategory.icon)
        .font(.system(size: 10))

      Text(displayCategory.name)
        .font(.rizqSans(.caption2))
    }
    .foregroundStyle(.white)
    .padding(.horizontal, RIZQSpacing.sm)
    .padding(.vertical, RIZQSpacing.xs)
    .background(categoryColor)
    .clipShape(Capsule())
  }

  /// Derive category display from bestTime
  private var categoryDisplay: CategoryDisplay {
    guard let bestTime = dua.bestTime else {
      // Default to "Anytime" if no bestTime
      return CategoryDisplay(slug: .rizq, name: "Anytime", icon: "clock.fill")
    }

    switch bestTime {
    case .morning:
      return CategoryDisplay.display(for: .morning)
    case .evening:
      return CategoryDisplay.display(for: .evening)
    case .anytime:
      return CategoryDisplay(slug: .rizq, name: "Anytime", icon: "clock.fill")
    }
  }

  // MARK: - Arabic Text
  private var arabicTextView: some View {
    Text(dua.arabicText)
      .font(.rizqArabic(.subheadline))
      .foregroundStyle(Color.rizqText.opacity(0.8))
      .lineLimit(2)
      .frame(maxWidth: .infinity, alignment: .trailing)
      .environment(\.layoutDirection, .rightToLeft)
  }

  // MARK: - Footer Row
  private var footerRow: some View {
    HStack {
      // Difficulty badge
      difficultyBadge

      Spacer()

      // XP value
      HStack(spacing: RIZQSpacing.xs) {
        Image(systemName: "star.fill")
          .font(.system(size: 10))
          .foregroundStyle(Color.streakGlow)

        Text("+\(dua.xpValue) XP")
          .font(.rizqSansMedium(.caption2))
          .foregroundStyle(Color.rizqPrimary)
      }
    }
  }

  // MARK: - Difficulty Badge
  private var difficultyBadge: some View {
    Text(dua.difficulty.rawValue)
      .font(.rizqSans(.caption2))
      .foregroundStyle(difficultyTextColor)
      .padding(.horizontal, RIZQSpacing.sm)
      .padding(.vertical, RIZQSpacing.xs)
      .background(difficultyBackgroundColor)
      .clipShape(Capsule())
  }

  // MARK: - Context Menu
  private var contextMenuItems: some View {
    Group {
      Button {
        onTap()
      } label: {
        Label("Practice", systemImage: "play.fill")
      }

      Button {
        onAddToAdkhar()
      } label: {
        Label("Add to Adkhar", systemImage: "plus.circle")
      }

      if dua.repetitions > 1 {
        Text("Repeat \(dua.repetitions)x")
      }
    }
  }

  // MARK: - Category Color
  private var categoryColor: Color {
    guard let bestTime = dua.bestTime else {
      return .badgeRizq // Default color
    }

    switch bestTime {
    case .morning:
      return .badgeMorning
    case .evening:
      return .badgeEvening
    case .anytime:
      return .badgeRizq
    }
  }

  // MARK: - Difficulty Colors
  private var difficultyTextColor: Color {
    switch dua.difficulty {
    case .beginner:
      return Color(hex: "15803D") // Green-700
    case .intermediate:
      return Color(hex: "B45309") // Amber-700
    case .advanced:
      return Color(hex: "B91C1C") // Red-700
    }
  }

  private var difficultyBackgroundColor: Color {
    switch dua.difficulty {
    case .beginner:
      return Color(hex: "DCFCE7") // Green-100
    case .intermediate:
      return Color(hex: "FEF3C7") // Amber-100
    case .advanced:
      return Color(hex: "FEE2E2") // Red-100
    }
  }
}

// MARK: - Preview
#Preview {
  VStack {
    LazyVGrid(
      columns: [
        GridItem(.flexible()),
        GridItem(.flexible()),
      ],
      spacing: 16
    ) {
      DuaCardView(
        dua: Dua.demoData[0],
        onTap: {},
        onAddToAdkhar: {}
      )

      DuaCardView(
        dua: Dua.demoData[2],
        onTap: {},
        onAddToAdkhar: {}
      )

      DuaCardView(
        dua: Dua.demoData[5],
        onTap: {},
        onAddToAdkhar: {}
      )
    }
    .padding()
  }
  .background(Color.rizqBackground)
}
