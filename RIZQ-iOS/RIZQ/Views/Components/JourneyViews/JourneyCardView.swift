import SwiftUI
import RIZQKit

/// Card view for displaying a journey in a grid
struct JourneyCardView: View {
  let journey: Journey
  let isSubscribed: Bool
  let isFeatured: Bool
  let onTap: () -> Void

  var body: some View {
    Button(action: onTap) {
      VStack(spacing: RIZQSpacing.md) {
        // Emoji icon with decorative frame
        ZStack {
          // Background circle
          Circle()
            .fill(
              LinearGradient(
                colors: isSubscribed
                  ? [Color.rizqPrimary.opacity(0.2), Color.rizqPrimary.opacity(0.05)]
                  : [Color.cream, Color.cream.opacity(0.5)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
              )
            )
            .frame(width: 56, height: 56)

          // Decorative corners
          RoundedRectangle(cornerRadius: 2)
            .stroke(Color.rizqPrimary.opacity(0.3), lineWidth: 1)
            .frame(width: 8, height: 8)
            .offset(x: 22, y: -22)

          RoundedRectangle(cornerRadius: 2)
            .stroke(Color.rizqPrimary.opacity(0.3), lineWidth: 1)
            .frame(width: 8, height: 8)
            .offset(x: -22, y: 22)

          // Emoji
          Text(journey.emoji)
            .font(.system(size: 28))

          // Active glow
          if isSubscribed {
            Circle()
              .fill(Color.rizqPrimary.opacity(0.3))
              .frame(width: 56, height: 56)
              .blur(radius: 12)
          }
        }

        // Journey name
        Text(journey.name)
          .font(.rizqSansMedium(.subheadline))
          .foregroundStyle(Color.rizqText)
          .multilineTextAlignment(.center)
          .lineLimit(2)
          .minimumScaleFactor(0.9)

        // Status or dua count
        if isSubscribed {
          HStack(spacing: RIZQSpacing.xs) {
            Image(systemName: "checkmark.circle.fill")
              .font(.system(size: 10))
            Text("Subscribed")
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

// MARK: - Featured Journey Card View

/// Larger horizontal card for featured journeys
struct FeaturedJourneyCardView: View {
  let journey: Journey
  let isSubscribed: Bool
  let onTap: () -> Void

  var body: some View {
    Button(action: onTap) {
      VStack(alignment: .leading, spacing: RIZQSpacing.md) {
        // Top row with emoji and subscribed indicator
        HStack(alignment: .top) {
          // Emoji with decorative frame
          ZStack {
            RoundedRectangle(cornerRadius: RIZQRadius.md)
              .fill(
                LinearGradient(
                  colors: [Color.cream, Color.cream.opacity(0.3)],
                  startPoint: .topLeading,
                  endPoint: .bottomTrailing
                )
              )
              .frame(width: 48, height: 48)
              .overlay(
                RoundedRectangle(cornerRadius: RIZQRadius.md)
                  .stroke(Color.rizqPrimary.opacity(0.2), lineWidth: 1)
              )

            Text(journey.emoji)
              .font(.system(size: 24))
          }

          Spacer()

          // Featured badge
          HStack(spacing: 4) {
            Image(systemName: "star.fill")
              .font(.system(size: 8))
            Text("Featured")
              .font(.rizqSansMedium(.caption2))
          }
          .foregroundStyle(Color.white)
          .padding(.horizontal, RIZQSpacing.sm)
          .padding(.vertical, 4)
          .background(Color.rizqPrimary)
          .clipShape(Capsule())

          if isSubscribed {
            Image(systemName: "checkmark.circle.fill")
              .foregroundStyle(Color.tealSuccess)
              .font(.system(size: 20))
          }
        }

        // Journey name
        Text(journey.name)
          .font(.rizqDisplayMedium(.headline))
          .foregroundStyle(Color.rizqText)
          .lineLimit(2)

        // Description
        if let description = journey.description {
          Text(description)
            .font(.rizqSans(.caption))
            .foregroundStyle(Color.rizqTextSecondary)
            .lineLimit(2)
        }

        // Stats row
        HStack(spacing: RIZQSpacing.lg) {
          HStack(spacing: RIZQSpacing.xs) {
            Image(systemName: "clock")
              .font(.system(size: 11))
            Text("\(journey.estimatedMinutes) min")
          }
          .font(.rizqSans(.caption2))
          .foregroundStyle(Color.rizqTextSecondary)

          HStack(spacing: RIZQSpacing.xs) {
            Image(systemName: "star.fill")
              .font(.system(size: 11))
            Text("+\(journey.dailyXp) XP")
          }
          .font(.rizqMonoMedium(.caption2))
          .foregroundStyle(Color.rizqPrimary)

          Spacer()
        }
      }
      .padding(RIZQSpacing.lg)
      .frame(width: 220)
      .background(
        ZStack {
          Color.rizqCard

          // Subtle pattern for featured cards
          GeometryReader { geometry in
            Path { path in
              let width = geometry.size.width
              let height = geometry.size.height
              path.move(to: CGPoint(x: width * 0.7, y: 0))
              path.addLine(to: CGPoint(x: width, y: 0))
              path.addLine(to: CGPoint(x: width, y: height * 0.3))
              path.closeSubpath()
            }
            .fill(Color.rizqPrimary.opacity(0.03))
          }
        }
      )
      .clipShape(RoundedRectangle(cornerRadius: RIZQRadius.islamic))
      .overlay(
        RoundedRectangle(cornerRadius: RIZQRadius.islamic)
          .stroke(Color.rizqPrimary.opacity(0.3), lineWidth: 1)
      )
      .shadowSoft()
    }
    .buttonStyle(.plain)
  }
}

// MARK: - Preview

#Preview("Journey Card") {
  VStack(spacing: 20) {
    HStack(spacing: 16) {
      JourneyCardView(
        journey: SampleData.journeys[0],
        isSubscribed: false,
        isFeatured: false
      ) {}

      JourneyCardView(
        journey: SampleData.journeys[1],
        isSubscribed: true,
        isFeatured: false
      ) {}
    }
    .padding()
  }
  .background(Color.rizqBackground)
}

#Preview("Featured Card") {
  ScrollView(.horizontal) {
    HStack(spacing: 16) {
      FeaturedJourneyCardView(
        journey: SampleData.journeys[0],
        isSubscribed: false
      ) {}

      FeaturedJourneyCardView(
        journey: SampleData.journeys[1],
        isSubscribed: true
      ) {}
    }
    .padding()
  }
  .background(Color.rizqBackground)
}
