import SwiftUI
import RIZQKit

// MARK: - Today's Progress Card

/// Card showing today's completed duas and XP earned
/// Matches the React app's "Today's Progress" card with animated XP badge
struct TodaysProgressCard: View {
  let duasCompleted: Int
  let xpEarned: Int

  @State private var badgeScale: CGFloat = 0.8
  @State private var badgeOpacity: CGFloat = 0
  @State private var sparkleRotation: Double = 0

  var body: some View {
    HStack {
      // Left side - text
      VStack(alignment: .leading, spacing: RIZQSpacing.xs) {
        Text("Today's Progress")
          .font(.rizqDisplayMedium(.subheadline))
          .foregroundStyle(Color.rizqText)

        Text("\(duasCompleted) duas completed")
          .font(.rizqSans(.caption))
          .foregroundStyle(Color.rizqTextSecondary)
      }

      Spacer()

      // Right side - XP badge with animation
      if xpEarned > 0 {
        xpBadge
      }
    }
    .padding(RIZQSpacing.lg)
    .background(Color.rizqPrimary.opacity(0.03))
    .overlay(
      RoundedRectangle(cornerRadius: RIZQRadius.islamic)
        .stroke(Color.rizqPrimary.opacity(0.15), lineWidth: 1)
    )
    .clipShape(RoundedRectangle(cornerRadius: RIZQRadius.islamic))
    .shadowSoft()
    .onAppear {
      animateBadge()
    }
  }

  // MARK: - XP Badge

  private var xpBadge: some View {
    HStack(spacing: RIZQSpacing.xs) {
      // Sparkle icon with rotation animation
      Image(systemName: "sparkles")
        .font(.system(size: 16, weight: .medium))
        .foregroundStyle(Color.rizqPrimary)
        .rotationEffect(.degrees(sparkleRotation))

      // XP amount
      Text("+\(xpEarned)")
        .font(.rizqDisplayBold(.title3))
        .foregroundStyle(Color.rizqPrimary)

      Text("XP")
        .font(.rizqSans(.caption))
        .foregroundStyle(Color.rizqTextSecondary)
    }
    .padding(.horizontal, RIZQSpacing.md)
    .padding(.vertical, RIZQSpacing.sm)
    .background(Color.goldSoft.opacity(0.2))
    .overlay(
      RoundedRectangle(cornerRadius: 20)
        .stroke(Color.goldSoft.opacity(0.3), lineWidth: 1)
    )
    .clipShape(RoundedRectangle(cornerRadius: 20))
    .scaleEffect(badgeScale)
    .opacity(badgeOpacity)
  }

  // MARK: - Animation

  private func animateBadge() {
    // Initial pop-in animation
    withAnimation(.spring(response: 0.5, dampingFraction: 0.6).delay(0.5)) {
      badgeScale = 1.0
      badgeOpacity = 1.0
    }

    // Subtle sparkle rotation
    withAnimation(
      Animation.easeInOut(duration: 2.0)
        .repeatForever(autoreverses: true)
        .delay(1.0)
    ) {
      sparkleRotation = 15
    }
  }
}

// MARK: - Compact Streak Badge

/// Compact streak badge for use in the header
/// Shows flame icon with streak count
struct CompactStreakBadge: View {
  let streak: Int
  let size: CGFloat

  @State private var isAnimating = false

  init(streak: Int, size: CGFloat = 56) {
    self.streak = streak
    self.size = size
  }

  var body: some View {
    VStack(spacing: 2) {
      ZStack {
        // Background circle
        Circle()
          .fill(Color.cream)
          .frame(width: size, height: size)
          .shadow(color: streak > 0 ? Color.streakGlow.opacity(0.3) : .clear, radius: 8)

        // Flame icon
        Image(systemName: "flame.fill")
          .font(.system(size: size * 0.4))
          .foregroundStyle(streak > 0 ? Color.streakGlow : Color.rizqMuted)
          .scaleEffect(isAnimating ? 1.1 : 1.0)
      }

      // Streak count
      Text("\(streak)")
        .font(.rizqMonoMedium(.caption))
        .foregroundStyle(Color.rizqText)

      Text("days")
        .font(.rizqSans(.caption2))
        .foregroundStyle(Color.rizqTextSecondary)
    }
    .onAppear {
      if streak > 0 {
        withAnimation(
          Animation.easeInOut(duration: 0.5)
            .repeatForever(autoreverses: true)
        ) {
          isAnimating = true
        }
      }
    }
  }
}

// MARK: - User Avatar

/// User profile avatar with fallback
struct UserAvatar: View {
  let imageURL: URL?
  let displayName: String
  let size: CGFloat

  init(imageURL: URL? = nil, displayName: String, size: CGFloat = 56) {
    self.imageURL = imageURL
    self.displayName = displayName
    self.size = size
  }

  var body: some View {
    ZStack {
      if let imageURL = imageURL {
        AsyncImage(url: imageURL) { phase in
          switch phase {
          case .success(let image):
            image
              .resizable()
              .scaledToFill()
          case .failure, .empty:
            fallbackAvatar
          @unknown default:
            fallbackAvatar
          }
        }
      } else {
        fallbackAvatar
      }
    }
    .frame(width: size, height: size)
    .clipShape(Circle())
    .overlay(
      Circle()
        .stroke(Color.rizqPrimary.opacity(0.2), lineWidth: 2)
    )
    .shadow(color: Color.black.opacity(0.1), radius: 4, y: 2)
  }

  private var fallbackAvatar: some View {
    ZStack {
      LinearGradient(
        colors: [Color.rizqPrimary.opacity(0.2), Color.rizqPrimary.opacity(0.1)],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
      )

      Text(initials)
        .font(.rizqDisplayBold(.headline))
        .foregroundStyle(Color.rizqPrimary)
    }
  }

  private var initials: String {
    let components = displayName.components(separatedBy: " ")
    let firstInitial = components.first?.prefix(1) ?? ""
    let lastInitial = components.count > 1 ? components.last?.prefix(1) ?? "" : ""
    return "\(firstInitial)\(lastInitial)".uppercased()
  }
}

// MARK: - Previews

#Preview("Today's Progress Card") {
  VStack(spacing: 20) {
    TodaysProgressCard(duasCompleted: 5, xpEarned: 160)
    TodaysProgressCard(duasCompleted: 3, xpEarned: 95)
    TodaysProgressCard(duasCompleted: 0, xpEarned: 0)
  }
  .padding()
  .background(Color.rizqBackground)
}

#Preview("Compact Streak Badge") {
  HStack(spacing: 20) {
    CompactStreakBadge(streak: 0)
    CompactStreakBadge(streak: 7)
    CompactStreakBadge(streak: 30)
  }
  .padding()
  .background(Color.rizqBackground)
}

#Preview("User Avatar") {
  HStack(spacing: 20) {
    UserAvatar(displayName: "Omair Dawood")
    UserAvatar(displayName: "John")
    UserAvatar(displayName: "A")
  }
  .padding()
  .background(Color.rizqBackground)
}
