import SwiftUI
import RIZQKit

/// A horizontal card view for displaying a dua in the library list
/// Redesigned to match JourneyCardView layout with icon, content, and chevron
struct DuaListCardView: View {
  let dua: Dua
  let isActive: Bool       // In user's daily habits
  let isCompleted: Bool    // Completed today
  let onTap: () -> Void
  let onAddToAdkhar: () -> Void

  @State private var isPressed = false

  // Convenience init for backward compatibility
  init(
    dua: Dua,
    isActive: Bool,
    isCompleted: Bool = false,
    onTap: @escaping () -> Void,
    onAddToAdkhar: @escaping () -> Void
  ) {
    self.dua = dua
    self.isActive = isActive
    self.isCompleted = isCompleted
    self.onTap = onTap
    self.onAddToAdkhar = onAddToAdkhar
  }

  var body: some View {
    Button(action: onTap) {
      HStack(spacing: RIZQSpacing.lg) {
        // Category icon (matching JourneyCardView icon placement)
        categoryIconView

        // Main content
        VStack(alignment: .leading, spacing: RIZQSpacing.sm) {
          // Title row with checkmark (if completed today)
          HStack(spacing: RIZQSpacing.sm) {
            Text(dua.titleEn)
              .font(.rizqDisplayMedium(.headline))  // Changed from .title3 to match Journeys
              .foregroundStyle(Color.rizqText)
              .lineLimit(1)

            // Checkmark for completed duas
            if isCompleted {
              Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 18))
                .foregroundStyle(Color.tealSuccess)
            }
          }

          // Metadata row: XP + Repetitions + Active badge
          HStack(spacing: RIZQSpacing.sm) {
            // XP value with sparkles (gold color)
            HStack(spacing: 4) {
              Image(systemName: "sparkles")
                .font(.system(size: 12))
              Text("+\(dua.xpValue)")
                .font(.rizqMonoMedium(.caption))
            }
            .foregroundStyle(Color.rizqPrimary)

            // Separator dot
            Text("•")
              .font(.rizqSans(.caption))
              .foregroundStyle(Color.rizqMuted)

            // Repetitions
            Text("\(dua.repetitions)×")
              .font(.rizqMono(.caption))
              .foregroundStyle(Color.rizqTextSecondary)

            // Active badge (if in habits)
            if isActive {
              activeBadge
            }

            Spacer()
          }

          // Arabic preview (single line, matches Journey description placement)
          Text(dua.arabicText)
            .font(.rizqArabic(.caption))
            .foregroundStyle(Color.rizqTextSecondary)
            .lineLimit(1)
            .environment(\.layoutDirection, .rightToLeft)
        }

        Spacer(minLength: 0)

        // Right side: Add button (if not in habits) or Chevron (if in habits)
        if !isActive {
          // Add to Adkhar button
          Button {
            onAddToAdkhar()
          } label: {
            ZStack {
              Circle()
                .fill(Color.rizqPrimary.opacity(0.1))
                .frame(width: 36, height: 36)

              Image(systemName: "plus")
                .font(.system(size: 16, weight: .medium))
                .foregroundStyle(Color.rizqPrimary)
            }
          }
          .buttonStyle(.plain)
        } else {
          // Chevron indicator (matching JourneyCardView)
          Image(systemName: "chevron.right")
            .font(.system(size: 14, weight: .medium))
            .foregroundStyle(Color.rizqMuted)
        }
      }
      .padding(RIZQSpacing.lg)
      .background(cardBackground)
      .clipShape(RoundedRectangle(cornerRadius: RIZQRadius.islamic))
      .overlay(cardBorderOverlay)
      .shadowSoft()  // Changed from direct .shadow() to use modifier
      .scaleEffect(isPressed ? 0.98 : 1.0)
      .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isPressed)
    }
    .buttonStyle(.plain)
    .simultaneousGesture(
      DragGesture(minimumDistance: 0)
        .onChanged { _ in isPressed = true }
        .onEnded { _ in isPressed = false }
    )
  }

  // MARK: - Category Icon (Matching JourneyIconView style)

  private var categoryIconView: some View {
    let emoji = categoryEmoji(for: dua.categoryId)
    let icon = categoryIcon(for: dua.categoryId)

    return ZStack {
      // Background circle with subtle gradient
      Circle()
        .fill(
          LinearGradient(
            colors: [Color.cream, Color.creamWarm],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
          )
        )
        .frame(width: 48, height: 48)

      // Border
      Circle()
        .stroke(Color.rizqBorder, lineWidth: 1.5)
        .frame(width: 48, height: 48)

      // Icon or emoji
      if !emoji.isEmpty {
        Text(emoji)
          .font(.system(size: 22))
      } else {
        Image(systemName: icon)
          .font(.system(size: 20))
          .foregroundStyle(Color.rizqPrimary)
      }
    }
  }

  private func categoryEmoji(for categoryId: Int?) -> String {
    switch categoryId {
    case 1: return "🌅"  // Morning
    case 2: return "🌙"  // Evening
    case 3: return "💫"  // Rizq
    case 4: return "🤲"  // Gratitude
    default: return "📿"  // Default
    }
  }

  private func categoryIcon(for categoryId: Int?) -> String {
    switch categoryId {
    case 1: return "sun.max.fill"
    case 2: return "moon.fill"
    case 3: return "sparkles"
    case 4: return "heart.fill"
    default: return "book.fill"
    }
  }

  // MARK: - Card Background

  private var cardBackground: some View {
    Group {
      if isCompleted {
        Color.tealSuccess.opacity(0.05)
      } else {
        Color.rizqCard
      }
    }
  }

  // MARK: - Card Border Overlay

  private var cardBorderOverlay: some View {
    RoundedRectangle(cornerRadius: RIZQRadius.islamic)
      .stroke(
        isCompleted ? Color.tealSuccess.opacity(0.3) :
          (isActive ? Color.rizqPrimary.opacity(0.2) : Color.clear),
        lineWidth: 1
      )
  }

  // MARK: - Active Badge (Matches JourneyCardView style)

  private var activeBadge: some View {
    HStack(spacing: 4) {
      Image(systemName: "sparkles")
        .font(.system(size: 10))
      Text("Active")
        .font(.rizqSansMedium(.caption))
    }
    .foregroundStyle(Color.sandWarm)
    .padding(.horizontal, RIZQSpacing.sm)
    .padding(.vertical, 4)
    .background(Color.sandWarm.opacity(0.12))
    .clipShape(Capsule())
  }
}

// MARK: - Preview

#Preview("All States") {
  ScrollView {
    VStack(spacing: RIZQSpacing.md) {
      // Not in habits - shows add button
      Text("Not in Adkhar (shows + button)")
        .font(.caption)
        .foregroundStyle(.secondary)
        .frame(maxWidth: .infinity, alignment: .leading)

      DuaListCardView(
        dua: Dua.demoData[0],
        isActive: false,
        isCompleted: false,
        onTap: {},
        onAddToAdkhar: {}
      )

      // In habits, not completed - shows chevron
      Text("In Adkhar, not completed (shows chevron)")
        .font(.caption)
        .foregroundStyle(.secondary)
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.top, RIZQSpacing.md)

      DuaListCardView(
        dua: Dua.demoData[1],
        isActive: true,
        isCompleted: false,
        onTap: {},
        onAddToAdkhar: {}
      )

      // In habits and completed - shows checkmark + accent
      Text("In Adkhar, completed today (teal styling)")
        .font(.caption)
        .foregroundStyle(.secondary)
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.top, RIZQSpacing.md)

      DuaListCardView(
        dua: Dua.demoData[2],
        isActive: true,
        isCompleted: true,
        onTap: {},
        onAddToAdkhar: {}
      )
    }
    .padding()
  }
  .background(Color.rizqBackground)
}
