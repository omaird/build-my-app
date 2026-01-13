import SwiftUI
import RIZQKit

/// A horizontal card view for displaying a dua in the Library.
/// Redesigned for reference/discovery (not practice):
/// - Shows Arabic preview, source, and difficulty
/// - Removes XP, repetitions, completion state (those belong in Adkhar)
struct DuaListCardView: View {
  let dua: Dua
  let isActive: Bool       // In user's daily habits (shown subtly)
  let onTap: () -> Void
  let onAddToAdkhar: () -> Void

  // Legacy init for backward compatibility - isCompleted is now ignored
  init(
    dua: Dua,
    isActive: Bool,
    isCompleted: Bool = false,  // Ignored - Library doesn't track completion
    onTap: @escaping () -> Void,
    onAddToAdkhar: @escaping () -> Void
  ) {
    self.dua = dua
    self.isActive = isActive
    self.onTap = onTap
    self.onAddToAdkhar = onAddToAdkhar
  }

  var body: some View {
    Button(action: onTap) {
      HStack(spacing: RIZQSpacing.md) {
        // Arabic text preview snippet (left side visual)
        arabicPreviewView

        // Main content
        VStack(alignment: .leading, spacing: RIZQSpacing.sm) {
          // Title
          Text(dua.titleEn)
            .font(.rizqDisplayMedium(.headline))
            .foregroundStyle(Color.rizqText)
            .lineLimit(1)

          // Category + Source row
          HStack(spacing: RIZQSpacing.sm) {
            // Category emoji
            Text(categoryEmoji(for: dua.categoryId))
              .font(.system(size: 12))

            // Category name
            Text(categoryName(for: dua.categoryId).uppercased())
              .font(.rizqSans(.caption2))
              .foregroundStyle(Color.rizqPrimary)
              .tracking(0.5)

            // Source (if available)
            if let source = dua.source {
              Text("•")
                .font(.rizqSans(.caption2))
                .foregroundStyle(Color.rizqMuted)

              Text(source)
                .font(.rizqSans(.caption))
                .foregroundStyle(Color.rizqTextSecondary)
                .lineLimit(1)
            }
          }

          // Translation excerpt
          Text(dua.translationEn)
            .font(.rizqSans(.caption))
            .foregroundStyle(Color.rizqTextSecondary)
            .lineLimit(2)
            .multilineTextAlignment(.leading)

          // Difficulty indicator (subtle footer)
          if let difficulty = dua.difficulty {
            HStack(spacing: 6) {
              Circle()
                .fill(difficultyColor(for: difficulty))
                .frame(width: 6, height: 6)
              Text(difficultyLabel(for: difficulty))
                .font(.rizqSans(.caption2))
                .foregroundStyle(Color.rizqMuted)
            }
            .padding(.top, 2)
          }
        }

        Spacer(minLength: 0)

        // Right side: Add button (always show for quick add)
        addButton
      }
      .padding(RIZQSpacing.lg)
      .background(Color.rizqCard)
      .clipShape(RoundedRectangle(cornerRadius: RIZQRadius.islamic))
      .overlay(cardBorderOverlay)
      .shadowSoft()
    }
    .buttonStyle(.plain)
  }

  // MARK: - Arabic Preview (Left side visual element)

  private var arabicPreviewView: some View {
    // Show first few words of Arabic text as a visual preview
    let preview = String(dua.arabicText.prefix(20))

    return VStack {
      Text(preview)
        .font(.rizqArabic(.caption))
        .foregroundStyle(Color.rizqText.opacity(0.8))
        .multilineTextAlignment(.center)
        .lineLimit(2)
        .environment(\.layoutDirection, .rightToLeft)
    }
    .frame(width: 56, height: 56)
    .background(
      RoundedRectangle(cornerRadius: RIZQRadius.md)
        .fill(Color.cream)
    )
    .overlay(
      RoundedRectangle(cornerRadius: RIZQRadius.md)
        .stroke(Color.goldSoft.opacity(0.4), lineWidth: 1)
    )
  }

  // MARK: - Add Button

  private var addButton: some View {
    Button {
      onAddToAdkhar()
    } label: {
      ZStack {
        Circle()
          .fill(isActive ? Color.tealSuccess.opacity(0.1) : Color.rizqPrimary.opacity(0.1))
          .frame(width: 36, height: 36)

        Image(systemName: isActive ? "checkmark" : "plus")
          .font(.system(size: 14, weight: .medium))
          .foregroundStyle(isActive ? Color.tealSuccess : Color.rizqPrimary)
      }
    }
    .buttonStyle(.plain)
    .disabled(isActive)
    .accessibilityLabel(isActive ? "Already in Daily Adkhar" : "Add to Daily Adkhar")
  }

  // MARK: - Card Border Overlay

  private var cardBorderOverlay: some View {
    RoundedRectangle(cornerRadius: RIZQRadius.islamic)
      .stroke(Color.rizqBorder.opacity(0.5), lineWidth: 1)
  }

  // MARK: - Helpers

  private func categoryEmoji(for categoryId: Int?) -> String {
    switch categoryId {
    case 1: return "🌅"  // Morning
    case 2: return "🌙"  // Evening
    case 3: return "💫"  // Rizq
    case 4: return "🤲"  // Gratitude
    default: return "📿"  // Default
    }
  }

  private func categoryName(for categoryId: Int?) -> String {
    switch categoryId {
    case 1: return "Morning"
    case 2: return "Evening"
    case 3: return "Rizq"
    case 4: return "Gratitude"
    default: return "Dua"
    }
  }

  private func difficultyColor(for difficulty: DuaDifficulty) -> Color {
    switch difficulty {
    case .beginner: return Color.tealSuccess
    case .intermediate: return Color.sandWarm
    case .advanced: return Color.rizqPrimary
    }
  }

  private func difficultyLabel(for difficulty: DuaDifficulty) -> String {
    switch difficulty {
    case .beginner: return "Beginner-friendly"
    case .intermediate: return "Intermediate"
    case .advanced: return "Advanced"
    }
  }
}

// MARK: - Preview

#Preview("Library Cards") {
  ScrollView {
    VStack(spacing: RIZQSpacing.md) {
      // Not in habits - shows + button
      Text("Not in Adkhar (shows + button)")
        .font(.caption)
        .foregroundStyle(.secondary)
        .frame(maxWidth: .infinity, alignment: .leading)

      DuaListCardView(
        dua: Dua.demoData[0],
        isActive: false,
        onTap: {},
        onAddToAdkhar: {}
      )

      // Already in habits - shows checkmark
      Text("Already in Adkhar (shows ✓)")
        .font(.caption)
        .foregroundStyle(.secondary)
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.top, RIZQSpacing.md)

      DuaListCardView(
        dua: Dua.demoData[1],
        isActive: true,
        onTap: {},
        onAddToAdkhar: {}
      )

      // With source and difficulty
      Text("With source and difficulty")
        .font(.caption)
        .foregroundStyle(.secondary)
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.top, RIZQSpacing.md)

      DuaListCardView(
        dua: Dua.demoData[2],
        isActive: false,
        onTap: {},
        onAddToAdkhar: {}
      )
    }
    .padding()
  }
  .background(Color.rizqBackground)
}
