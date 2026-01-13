import SwiftUI
import RIZQKit

/// Displays dua context information: source, benefits, prophetic context
struct DuaContextView: View {
  let dua: Dua

  private var contextItems: [ContextItem] {
    var items: [ContextItem] = []

    if let source = dua.source {
      items.append(ContextItem(
        icon: "book.fill",
        label: "Source",
        value: source,
        color: .badgeMorning // Adaptive amber
      ))
    }

    if let rizqBenefit = dua.rizqBenefit {
      items.append(ContextItem(
        icon: "sparkles",
        label: "Benefits & Virtues",
        value: rizqBenefit,
        color: .badgeRizq // Adaptive emerald
      ))
    }

    if let bestTime = dua.bestTime {
      items.append(ContextItem(
        icon: "clock.fill",
        label: "Best Time to Recite",
        value: bestTime,
        color: .badgeEvening // Adaptive indigo
      ))
    }

    if let propheticContext = dua.propheticContext {
      items.append(ContextItem(
        icon: "quote.opening",
        label: "Prophetic Guidance",
        value: propheticContext,
        color: .badgeGratitude // Adaptive rose
      ))
    }

    return items
  }

  var body: some View {
    if contextItems.isEmpty {
      emptyState
    } else {
      contextList
    }
  }

  // MARK: - Context List

  private var contextList: some View {
    VStack(spacing: RIZQSpacing.md) {
      // Difficulty and duration badge (if available)
      difficultyBadge

      // Context items
      ForEach(Array(contextItems.enumerated()), id: \.element.label) { index, item in
        contextItemView(item, index: index)
      }
    }
  }

  // MARK: - Difficulty Badge

  @ViewBuilder
  private var difficultyBadge: some View {
    let hasDifficulty = dua.difficulty != nil
    let hasDuration = dua.estDurationSec != nil

    if hasDifficulty || hasDuration {
      HStack(spacing: RIZQSpacing.md) {
        // Difficulty
        if let difficulty = dua.difficulty {
          HStack(spacing: RIZQSpacing.xs) {
            Image(systemName: "graduationcap.fill")
              .font(.system(size: 12))
            Text(difficulty.rawValue)
              .font(.rizqSans(.caption))
          }
          .foregroundStyle(Color.rizqTextSecondary)
        }

        if hasDuration {
          Text("|")
            .foregroundStyle(Color.rizqMuted.opacity(0.5))

          // Duration
          HStack(spacing: RIZQSpacing.xs) {
            Image(systemName: "clock.fill")
              .font(.system(size: 12))
            if let seconds = dua.estDurationSec {
              Text("~\(max(1, seconds / 60)) min")
                .font(.rizqSans(.caption))
            }
          }
          .foregroundStyle(Color.rizqTextSecondary)
        }
      }
      .padding(.vertical, RIZQSpacing.sm)
    }
  }

  // MARK: - Context Item View

  private func contextItemView(_ item: ContextItem, index: Int) -> some View {
    HStack(alignment: .top, spacing: RIZQSpacing.md) {
      // Icon
      ZStack {
        RoundedRectangle(cornerRadius: RIZQRadius.sm)
          .fill(item.color.opacity(0.15))
          .frame(width: 40, height: 40)

        Image(systemName: item.icon)
          .font(.system(size: 16, weight: .medium))
          .foregroundStyle(item.color)
      }

      // Content
      VStack(alignment: .leading, spacing: RIZQSpacing.xs) {
        Text(item.label)
          .font(.rizqSans(.caption))
          .fontWeight(.medium)
          .foregroundStyle(Color.rizqTextSecondary)
          .textCase(.uppercase)
          .tracking(0.5)

        Text(item.value)
          .font(.rizqSans(.body))
          .foregroundStyle(Color.rizqText)
          .fixedSize(horizontal: false, vertical: true)
      }
      .frame(maxWidth: .infinity, alignment: .leading)
    }
    .padding(RIZQSpacing.lg)
    .background(Color.rizqCard.opacity(0.6))
    .clipShape(RoundedRectangle(cornerRadius: RIZQRadius.islamic))
    .overlay(
      RoundedRectangle(cornerRadius: RIZQRadius.islamic)
        .stroke(Color.rizqPrimary.opacity(0.1), lineWidth: 1)
    )
  }

  // MARK: - Empty State

  private var emptyState: some View {
    VStack(spacing: RIZQSpacing.lg) {
      Image(systemName: "scroll.fill")
        .font(.system(size: 48))
        .foregroundStyle(Color.rizqMuted.opacity(0.4))

      Text("No additional context available for this dua.")
        .font(.rizqSans(.body))
        .foregroundStyle(Color.rizqTextSecondary)
        .multilineTextAlignment(.center)
    }
    .frame(maxWidth: .infinity)
    .padding(.vertical, RIZQSpacing.huge)
  }
}

// MARK: - Context Item Model

private struct ContextItem {
  let icon: String
  let label: String
  let value: String
  let color: Color
}

// MARK: - Previews

#Preview("Dua Context View") {
  ScrollView {
    // Use first sample dua which has full context
    DuaContextView(dua: SampleData.duas[0])
      .padding()
  }
  .rizqPageBackground()
}

#Preview("Empty Context") {
  // Create a minimal dua without context for empty state
  let minimalDua = Dua(
    id: 999,
    titleEn: "Simple Dua",
    arabicText: "الْحَمْدُ لِلَّهِ",
    transliteration: "Alhamdulillah",
    translationEn: "All praise is due to Allah"
  )

  DuaContextView(dua: minimalDua)
    .padding()
    .rizqPageBackground()
}
