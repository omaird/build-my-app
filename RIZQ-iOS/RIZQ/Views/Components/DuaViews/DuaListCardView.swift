import SwiftUI
import RIZQKit

/// A horizontal card view for displaying a dua in the library list
/// Matches the React DuaCard design with title, category badge, XP, repetitions, and active status
struct DuaListCardView: View {
  let dua: Dua
  let isActive: Bool
  let onTap: () -> Void
  let onAddToAdkhar: () -> Void

  var body: some View {
    Button(action: onTap) {
      HStack(spacing: RIZQSpacing.lg) {
        // Main content
        VStack(alignment: .leading, spacing: RIZQSpacing.md) {
          // Title row with checkmark (if active)
          HStack(spacing: RIZQSpacing.sm) {
            Text(dua.titleEn)
              .font(.rizqDisplaySemiBold(.title3))
              .foregroundStyle(Color.rizqText)
              .lineLimit(1)

            // Checkmark for active duas (matches React design)
            if isActive {
              Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 20))
                .foregroundStyle(Color.rizqPrimary)
            }
          }

          // Metadata row: Category badge + XP + Repetitions + Active
          HStack(spacing: RIZQSpacing.sm) {
            // Category badge (muted style matching React)
            if let categoryId = dua.categoryId {
              categoryBadge(for: categoryId)
            }

            // XP value
            HStack(spacing: 4) {
              Image(systemName: "sparkles")
                .font(.system(size: 12))
              Text("+\(dua.xpValue)")
                .font(.rizqMonoMedium(.subheadline))
            }
            .foregroundStyle(Color.sandWarm)

            // Separator dot
            Text("•")
              .font(.rizqSans(.caption))
              .foregroundStyle(Color.rizqMuted)

            // Repetitions
            Text("\(dua.repetitions)×")
              .font(.rizqMono(.subheadline))
              .foregroundStyle(Color.rizqTextSecondary)

            // Active badge (if in habits)
            if isActive {
              activeBadge
            }

            Spacer()
          }
        }

        // Chevron indicator
        Image(systemName: "chevron.right")
          .font(.system(size: 14, weight: .medium))
          .foregroundStyle(Color.rizqMuted)
      }
      .padding(RIZQSpacing.lg)
      .background(Color.rizqCard)
      .clipShape(RoundedRectangle(cornerRadius: RIZQRadius.islamic))
      .shadow(color: .black.opacity(0.04), radius: 8, y: 2)
    }
    .buttonStyle(.plain)
  }

  // MARK: - Category Badge (Muted style matching React)

  private func categoryBadge(for categoryId: Int) -> some View {
    let name = categoryName(for: categoryId)

    return Text(name)
      .font(.rizqSansMedium(.caption))
      .foregroundStyle(Color.rizqTextSecondary)
      .padding(.horizontal, RIZQSpacing.sm)
      .padding(.vertical, 4)
      .background(Color.rizqBorder.opacity(0.5))
      .clipShape(Capsule())
  }

  private func categoryName(for categoryId: Int) -> String {
    switch categoryId {
    case 1: return "Morning"
    case 2: return "Evening"
    case 3: return "Rizq"
    case 4: return "Gratitude"
    default: return "Other"
    }
  }

  // MARK: - Active Badge (Matches React sparkle + Active style)

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

#Preview {
  VStack(spacing: RIZQSpacing.md) {
    DuaListCardView(
      dua: Dua.demoData[0],
      isActive: false,
      onTap: {},
      onAddToAdkhar: {}
    )

    DuaListCardView(
      dua: Dua.demoData[1],
      isActive: true,
      onTap: {},
      onAddToAdkhar: {}
    )

    DuaListCardView(
      dua: Dua.demoData[2],
      isActive: false,
      onTap: {},
      onAddToAdkhar: {}
    )
  }
  .padding()
  .background(Color.rizqBackground)
}
