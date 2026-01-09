import SwiftUI
import RIZQKit

/// Full-width journey card matching the React web app design
/// Layout: Image on left, text content on right, stats row at bottom
struct JourneyCardView: View {
  let journey: Journey
  let isSubscribed: Bool
  let isFeatured: Bool
  let onTap: () -> Void

  var body: some View {
    Button(action: onTap) {
      VStack(spacing: 0) {
        // Main content
        HStack(alignment: .top, spacing: RIZQSpacing.lg) {
          // Journey illustration
          JourneyIconView(journey: journey, size: 72, showDecorations: true)
            .overlay {
              // Active glow effect
              if isSubscribed {
                Circle()
                  .fill(Color.rizqPrimary.opacity(0.25))
                  .blur(radius: 12)
                  .frame(width: 72, height: 72)
              }
            }

          // Text content
          VStack(alignment: .leading, spacing: RIZQSpacing.xs) {
            // Title row with premium badge
            HStack(spacing: RIZQSpacing.sm) {
              Text(journey.name)
                .font(.rizqDisplayMedium(.headline))
                .foregroundStyle(Color.rizqText)
                .lineLimit(2)

              if journey.isPremium {
                premiumBadge
              }
            }

            // Description
            if let description = journey.description {
              Text(description)
                .font(.rizqSans(.subheadline))
                .foregroundStyle(Color.rizqTextSecondary)
                .lineLimit(2)
                .fixedSize(horizontal: false, vertical: true)
            }
          }

          Spacer(minLength: 0)

          // Active indicator
          if isSubscribed {
            activeCheckmark
          }
        }

        // Stats row
        statsRow
          .padding(.top, RIZQSpacing.md)
      }
      .padding(RIZQSpacing.lg)
      .background(cardBackground)
      .clipShape(RoundedRectangle(cornerRadius: RIZQRadius.islamic))
      .overlay(cardOverlay)
      .shadowSoft()
    }
    .buttonStyle(.plain)
    .overlay(alignment: .topTrailing) {
      // Featured badge (diagonal ribbon style)
      if isFeatured && !isSubscribed {
        featuredBadge
      }
    }
  }

  // MARK: - Stats Row

  private var statsRow: some View {
    HStack(spacing: RIZQSpacing.xl) {
      // Estimated time
      HStack(spacing: RIZQSpacing.xs) {
        Image(systemName: "clock")
          .font(.system(size: 12))
        Text("\(journey.estimatedMinutes) min/day")
      }
      .font(.rizqSans(.caption))
      .foregroundStyle(Color.rizqTextSecondary)

      // XP per day
      HStack(spacing: RIZQSpacing.xs) {
        Image(systemName: "sparkles")
          .font(.system(size: 12))
        Text("\(journey.dailyXp) XP/day")
          .font(.rizqMonoMedium(.caption))
      }
      .foregroundStyle(Color.rizqPrimary)

      Spacer()
    }
  }

  // MARK: - Active Checkmark

  private var activeCheckmark: some View {
    ZStack {
      Circle()
        .fill(
          LinearGradient(
            colors: [Color.rizqPrimary, Color.rizqPrimary.opacity(0.8)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
          )
        )
        .frame(width: 28, height: 28)

      Image(systemName: "checkmark")
        .font(.system(size: 14, weight: .bold))
        .foregroundStyle(.white)
    }
  }

  // MARK: - Premium Badge

  private var premiumBadge: some View {
    HStack(spacing: 4) {
      Image(systemName: "lock.fill")
        .font(.system(size: 8))
      Text("Premium")
        .font(.rizqSansMedium(.caption2))
    }
    .foregroundStyle(Color.goldSoft)
    .padding(.horizontal, RIZQSpacing.sm)
    .padding(.vertical, 3)
    .background(Color.goldSoft.opacity(0.15))
    .clipShape(Capsule())
  }

  // MARK: - Featured Badge

  private var featuredBadge: some View {
    HStack(spacing: 4) {
      Image(systemName: "star.fill")
        .font(.system(size: 8))
      Text("Featured")
        .font(.rizqSansMedium(.caption2))
    }
    .foregroundStyle(.white)
    .padding(.horizontal, RIZQSpacing.md)
    .padding(.vertical, 5)
    .background(Color.rizqPrimary)
    .clipShape(Capsule())
    .offset(x: -RIZQSpacing.sm, y: RIZQSpacing.sm)
  }

  // MARK: - Card Background

  private var cardBackground: some View {
    ZStack {
      Color.rizqCard

      // Subtle pattern for featured cards
      if isFeatured && !isSubscribed {
        GeometryReader { geometry in
          Path { path in
            let width = geometry.size.width
            let height = geometry.size.height
            path.move(to: CGPoint(x: width * 0.7, y: 0))
            path.addLine(to: CGPoint(x: width, y: 0))
            path.addLine(to: CGPoint(x: width, y: height * 0.3))
            path.closeSubpath()
          }
          .fill(Color.rizqPrimary.opacity(0.04))
        }
      }
    }
  }

  // MARK: - Card Overlay

  private var cardOverlay: some View {
    RoundedRectangle(cornerRadius: RIZQRadius.islamic)
      .stroke(
        isSubscribed
          ? Color.rizqPrimary.opacity(0.5)
          : (isFeatured ? Color.rizqPrimary.opacity(0.2) : Color.clear),
        lineWidth: isSubscribed ? 2 : 1
      )
  }
}

// MARK: - Compact Journey Card (for grid layouts if needed)

/// Smaller card variant for when space is limited
struct CompactJourneyCardView: View {
  let journey: Journey
  let isSubscribed: Bool
  let onTap: () -> Void

  var body: some View {
    Button(action: onTap) {
      VStack(spacing: RIZQSpacing.md) {
        // Illustration
        JourneyIconView(journey: journey, size: 56, showDecorations: true)

        // Name
        Text(journey.name)
          .font(.rizqSansMedium(.subheadline))
          .foregroundStyle(Color.rizqText)
          .multilineTextAlignment(.center)
          .lineLimit(2)

        // XP indicator
        if isSubscribed {
          HStack(spacing: RIZQSpacing.xs) {
            Image(systemName: "checkmark.circle.fill")
              .font(.system(size: 10))
            Text("Active")
          }
          .font(.rizqSans(.caption2))
          .foregroundStyle(Color.tealSuccess)
        } else {
          Text("+\(journey.dailyXp) XP/day")
            .font(.rizqMonoMedium(.caption2))
            .foregroundStyle(Color.rizqPrimary)
        }
      }
      .frame(maxWidth: .infinity)
      .padding(.vertical, RIZQSpacing.lg)
      .padding(.horizontal, RIZQSpacing.md)
      .background(Color.rizqCard)
      .clipShape(RoundedRectangle(cornerRadius: RIZQRadius.islamic))
      .overlay(
        RoundedRectangle(cornerRadius: RIZQRadius.islamic)
          .stroke(
            isSubscribed ? Color.rizqPrimary.opacity(0.5) : Color.clear,
            lineWidth: 2
          )
      )
      .shadowSoft()
    }
    .buttonStyle(.plain)
  }
}

// MARK: - Previews

#Preview("Journey Card - Full Width") {
  VStack(spacing: 16) {
    JourneyCardView(
      journey: Journey(
        id: 1,
        name: "Rizq Seeker",
        slug: "rizq-seeker",
        description: "A comprehensive daily practice focused on increasing provision and blessings in your life.",
        emoji: "/images/icons/The Rizq Seeker.png",
        estimatedMinutes: 15,
        dailyXp: 270,
        isFeatured: true
      ),
      isSubscribed: false,
      isFeatured: true
    ) {}

    JourneyCardView(
      journey: Journey(
        id: 2,
        name: "Morning Warrior",
        slug: "morning-warrior",
        description: "Start your day with powerful duas for protection and blessings.",
        emoji: "/images/icons/Morning Warrior.png",
        estimatedMinutes: 12,
        dailyXp: 250
      ),
      isSubscribed: true,
      isFeatured: false
    ) {}
  }
  .padding()
  .background(Color.rizqBackground)
}

#Preview("Compact Card") {
  HStack(spacing: 16) {
    CompactJourneyCardView(
      journey: Journey(
        id: 1,
        name: "Rizq Seeker",
        slug: "rizq-seeker",
        emoji: "/images/icons/The Rizq Seeker.png",
        dailyXp: 270
      ),
      isSubscribed: false
    ) {}

    CompactJourneyCardView(
      journey: Journey(
        id: 2,
        name: "Morning",
        slug: "morning-warrior",
        emoji: "🌅",
        dailyXp: 250
      ),
      isSubscribed: true
    ) {}
  }
  .padding()
  .background(Color.rizqBackground)
}
