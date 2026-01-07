import SwiftUI
import RIZQKit

/// Large decorative header for journey detail page
struct JourneyHeaderView: View {
  let journey: Journey
  let isSubscribed: Bool

  @State private var isAnimating = false

  var body: some View {
    VStack(spacing: RIZQSpacing.md) {
      // Decorative emoji container
      decorativeEmojiContainer

      // Journey name
      Text(journey.name)
        .font(.rizqDisplayBold(.title2))
        .foregroundStyle(Color.rizqText)
        .multilineTextAlignment(.center)

      // Description
      if let description = journey.description {
        Text(description)
          .font(.rizqSans(.body))
          .foregroundStyle(Color.rizqTextSecondary)
          .multilineTextAlignment(.center)
          .padding(.horizontal, RIZQSpacing.xl)
      }

      // Badges
      badgesRow
    }
    .onAppear {
      isAnimating = true
    }
  }

  // MARK: - Decorative Emoji Container

  private var decorativeEmojiContainer: some View {
    ZStack {
      // Outer rotating dashed ring
      Circle()
        .stroke(style: StrokeStyle(lineWidth: 2, dash: [5, 5]))
        .foregroundStyle(Color.rizqPrimary.opacity(0.2))
        .frame(width: 100, height: 100)
        .rotationEffect(.degrees(isAnimating ? 360 : 0))
        .animation(
          .linear(duration: 20).repeatForever(autoreverses: false),
          value: isAnimating
        )

      // Pulsing glow
      Circle()
        .fill(Color.rizqPrimary.opacity(0.15))
        .frame(width: 80, height: 80)
        .blur(radius: 15)
        .scaleEffect(isAnimating ? 1.1 : 1.0)
        .animation(
          .easeInOut(duration: 2).repeatForever(autoreverses: true),
          value: isAnimating
        )

      // Main emoji container
      ZStack {
        // Background circle with gradient
        Circle()
          .fill(
            LinearGradient(
              colors: isSubscribed
                ? [Color.rizqPrimary.opacity(0.2), Color.rizqPrimary.opacity(0.05)]
                : [Color.cream, Color.cream.opacity(0.3)],
              startPoint: .topLeading,
              endPoint: .bottomTrailing
            )
          )
          .frame(width: 80, height: 80)
          .overlay(
            Circle()
              .stroke(Color.rizqPrimary.opacity(0.2), lineWidth: 2)
          )

        // Corner decorations
        cornerDecoration(offset: CGPoint(x: 32, y: -32))
        cornerDecoration(offset: CGPoint(x: -32, y: 32))

        // Emoji
        Text(journey.emoji)
          .font(.system(size: 40))
      }
      .shadowElevated()

      // Subscribed indicator
      if isSubscribed {
        VStack {
          Spacer()
          HStack {
            Spacer()
            Image(systemName: "checkmark.circle.fill")
              .font(.system(size: 24))
              .foregroundStyle(Color.tealSuccess)
              .background(
                Circle()
                  .fill(Color.white)
                  .frame(width: 20, height: 20)
              )
          }
        }
        .frame(width: 90, height: 90)
      }
    }
    .padding(.top, RIZQSpacing.xl)
  }

  private func cornerDecoration(offset: CGPoint) -> some View {
    RoundedRectangle(cornerRadius: 1)
      .fill(Color.rizqPrimary.opacity(0.3))
      .frame(width: 6, height: 6)
      .offset(x: offset.x, y: offset.y)
  }

  // MARK: - Badges Row

  private var badgesRow: some View {
    HStack(spacing: RIZQSpacing.sm) {
      if journey.isPremium {
        badgeView(
          icon: "lock.fill",
          text: "Premium",
          backgroundColor: Color.goldSoft.opacity(0.2),
          foregroundColor: Color.goldSoft
        )
      }

      if journey.isFeatured {
        badgeView(
          icon: "star.fill",
          text: "Featured",
          backgroundColor: Color.rizqPrimary.opacity(0.15),
          foregroundColor: Color.rizqPrimary
        )
      }

      if isSubscribed {
        badgeView(
          icon: "checkmark.circle.fill",
          text: "Active",
          backgroundColor: Color.tealSuccess.opacity(0.15),
          foregroundColor: Color.tealSuccess
        )
      }
    }
  }

  private func badgeView(
    icon: String,
    text: String,
    backgroundColor: Color,
    foregroundColor: Color
  ) -> some View {
    HStack(spacing: RIZQSpacing.xs) {
      Image(systemName: icon)
        .font(.system(size: 10))
      Text(text)
        .font(.rizqSansMedium(.caption))
    }
    .foregroundStyle(foregroundColor)
    .padding(.horizontal, RIZQSpacing.md)
    .padding(.vertical, RIZQSpacing.xs)
    .background(backgroundColor)
    .clipShape(Capsule())
  }
}

// MARK: - Journey Stats View

/// Stats row showing journey metrics
struct JourneyStatsView: View {
  let duaCount: Int
  let estimatedMinutes: Int
  let totalXp: Int

  var body: some View {
    HStack(spacing: RIZQSpacing.xl) {
      statItem(
        icon: "book.fill",
        value: "\(duaCount)",
        label: "Duas"
      )

      statItem(
        icon: "clock.fill",
        value: "~\(estimatedMinutes)",
        label: "Min/day"
      )

      statItem(
        icon: "star.fill",
        value: "+\(totalXp)",
        label: "XP/day",
        accentColor: Color.rizqPrimary
      )
    }
    .padding(.vertical, RIZQSpacing.md)
    .padding(.horizontal, RIZQSpacing.lg)
    .background(Color.rizqCard)
    .clipShape(RoundedRectangle(cornerRadius: RIZQRadius.islamic))
    .shadowSoft()
  }

  private func statItem(
    icon: String,
    value: String,
    label: String,
    accentColor: Color = Color.rizqTextSecondary
  ) -> some View {
    VStack(spacing: RIZQSpacing.xs) {
      Image(systemName: icon)
        .font(.system(size: 16))
        .foregroundStyle(accentColor)

      Text(value)
        .font(.rizqMonoMedium(.headline))
        .foregroundStyle(Color.rizqText)

      Text(label)
        .font(.rizqSans(.caption2))
        .foregroundStyle(Color.rizqTextSecondary)
    }
    .frame(maxWidth: .infinity)
  }
}

// MARK: - Preview

#Preview("Journey Header") {
  ScrollView {
    VStack(spacing: 30) {
      JourneyHeaderView(
        journey: SampleData.journeys[0],
        isSubscribed: false
      )

      JourneyHeaderView(
        journey: SampleData.journeys[1],
        isSubscribed: true
      )

      JourneyStatsView(
        duaCount: 6,
        estimatedMinutes: 10,
        totalXp: 50
      )
      .padding(.horizontal)
    }
  }
  .background(Color.rizqBackground)
}
