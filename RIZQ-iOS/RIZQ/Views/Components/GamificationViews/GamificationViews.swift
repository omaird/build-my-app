import SwiftUI
import RIZQKit

// MARK: - Streak Badge

/// Animated streak badge with flame icon and count
/// Matches the web GamificationUI.tsx StreakBadge component
struct StreakBadge: View {
  let streak: Int
  let isAnimating: Bool

  @State private var animationPhase: CGFloat = 0

  var body: some View {
    VStack(spacing: RIZQSpacing.md) {
      ZStack {
        // Background circle with glow when streak > 0
        Circle()
          .fill(Color.streakGlow.opacity(0.15))
          .frame(width: 44, height: 44)
          .scaleEffect(isAnimating ? 1.3 : 1.0)
          .opacity(streak > 0 ? 1 : 0.5)

        // Flame icon
        Image(systemName: "flame.fill")
          .font(.title2)
          .foregroundStyle(streak > 0 ? Color.streakGlow : Color.rizqMuted)
          .rotationEffect(.degrees(isAnimating ? -10 : 0))
          .scaleEffect(isAnimating ? 1.2 : 1.0)
      }
      .animation(
        isAnimating
          ? Animation.easeInOut(duration: 0.3).repeatCount(3, autoreverses: true)
          : .default,
        value: isAnimating
      )

      VStack(spacing: RIZQSpacing.xs) {
        Text("\(streak)")
          .font(.rizqMonoMedium(.title2))
          .foregroundStyle(Color.rizqText)
          .scaleEffect(isAnimating ? 1.3 : 1.0)
          .animation(.spring(response: 0.4, dampingFraction: 0.6), value: streak)

        Text("Day Streak")
          .font(.rizqSans(.caption))
          .foregroundStyle(Color.rizqTextSecondary)
      }
    }
    .frame(maxWidth: .infinity)
    .padding(.vertical, RIZQSpacing.xl)
    .background(Color.rizqCard)
    .clipShape(RoundedRectangle(cornerRadius: RIZQRadius.islamic))
    .overlay(
      RoundedRectangle(cornerRadius: RIZQRadius.islamic)
        .stroke(isAnimating ? Color.streakGlow : Color.clear, lineWidth: 2)
    )
    .shadowSoft()
    .overlay(alignment: .topTrailing) {
      // Celebration badge when animating
      if isAnimating {
        Text("+1")
          .font(.rizqSansBold(.caption2))
          .foregroundStyle(.white)
          .padding(.horizontal, 8)
          .padding(.vertical, 4)
          .background(Color.streakGlow)
          .clipShape(Capsule())
          .offset(x: 8, y: -8)
          .transition(.scale.combined(with: .opacity))
      }
    }
  }
}

// MARK: - Level Badge

/// Level indicator with star icon
struct LevelBadge: View {
  let level: Int
  let size: CGFloat

  init(level: Int, size: CGFloat = 80) {
    self.level = level
    self.size = size
  }

  var body: some View {
    ZStack {
      // Background circle
      Circle()
        .fill(Color.levelBadge.opacity(0.1))
        .frame(width: size, height: size)

      VStack(spacing: 4) {
        Image(systemName: "star.fill")
          .font(.system(size: size * 0.25))
          .foregroundStyle(Color.levelBadge)

        Text("\(level)")
          .font(.rizqMonoMedium(.title3))
          .foregroundStyle(Color.rizqText)
      }
    }
  }
}

// MARK: - Circular XP Progress

/// Circular progress indicator showing level progress
/// Matches the web CircularXpProgress component
struct CircularXpProgress: View {
  let level: Int
  let percentage: Double
  let size: CGFloat
  let strokeWidth: CGFloat

  @State private var animatedProgress: Double = 0

  init(level: Int, percentage: Double, size: CGFloat = 80, strokeWidth: CGFloat = 6) {
    self.level = level
    self.percentage = percentage
    self.size = size
    self.strokeWidth = strokeWidth
  }

  var body: some View {
    ZStack {
      // Background track
      Circle()
        .stroke(Color.rizqMuted.opacity(0.3), lineWidth: strokeWidth)

      // Progress arc
      Circle()
        .trim(from: 0, to: animatedProgress)
        .stroke(
          Color.rizqPrimary,
          style: StrokeStyle(lineWidth: strokeWidth, lineCap: .round)
        )
        .rotationEffect(.degrees(-90))

      // Center content
      VStack(spacing: 2) {
        Image(systemName: "star.fill")
          .font(.system(size: size * 0.2))
          .foregroundStyle(Color.levelBadge)

        Text("\(level)")
          .font(.rizqMonoMedium(.headline))
          .foregroundStyle(Color.rizqText)
      }
    }
    .frame(width: size, height: size)
    .onAppear {
      withAnimation(.easeOut(duration: 1.0)) {
        animatedProgress = percentage
      }
    }
    .onChange(of: percentage) { _, newValue in
      withAnimation(.easeOut(duration: 0.5)) {
        animatedProgress = newValue
      }
    }
  }
}

// MARK: - XP Progress Bar

/// Linear XP progress bar with shimmer effect
/// Matches the web XpProgressBar component
struct XpProgressBar: View {
  let current: Int
  let needed: Int
  let level: Int
  let xpToNextLevel: Int

  @State private var animatedProgress: CGFloat = 0
  @State private var shimmerOffset: CGFloat = -1

  private var percentage: CGFloat {
    needed > 0 ? CGFloat(current) / CGFloat(needed) : 0
  }

  var body: some View {
    VStack(alignment: .leading, spacing: RIZQSpacing.md) {
      // Header
      HStack {
        HStack(spacing: RIZQSpacing.sm) {
          Image(systemName: "bolt.fill")
            .foregroundStyle(Color.rizqPrimary)

          Text("Experience")
            .font(.rizqSansSemiBold(.headline))
            .foregroundStyle(Color.rizqText)
        }

        Spacer()

        Text("\(current) / \(needed) XP")
          .font(.rizqMono(.subheadline))
          .foregroundStyle(Color.rizqTextSecondary)
      }

      // Progress bar
      GeometryReader { geometry in
        ZStack(alignment: .leading) {
          // Track
          Capsule()
            .fill(Color.rizqMuted.opacity(0.3))
            .frame(height: 12)

          // Progress fill with shimmer
          Capsule()
            .fill(Color.rizqPrimary)
            .frame(width: geometry.size.width * animatedProgress, height: 12)
            .overlay(
              // Shimmer effect
              LinearGradient(
                colors: [
                  .clear,
                  .white.opacity(0.3),
                  .clear
                ],
                startPoint: .leading,
                endPoint: .trailing
              )
              .offset(x: shimmerOffset * geometry.size.width)
              .mask(
                Capsule()
                  .frame(width: geometry.size.width * animatedProgress, height: 12)
              )
            )
            .clipShape(Capsule())
        }
      }
      .frame(height: 12)

      // Footer
      Text("\(xpToNextLevel) XP to Level \(level + 1)")
        .font(.rizqSans(.caption))
        .foregroundStyle(Color.rizqTextSecondary)
    }
    .padding(RIZQSpacing.lg)
    .background(Color.rizqCard)
    .clipShape(RoundedRectangle(cornerRadius: RIZQRadius.islamic))
    .shadowSoft()
    .onAppear {
      // Animate progress bar
      withAnimation(.easeOut(duration: 1.0)) {
        animatedProgress = percentage
      }

      // Start shimmer animation
      withAnimation(
        Animation.linear(duration: 2.0)
          .repeatForever(autoreverses: false)
          .delay(1.0)
      ) {
        shimmerOffset = 2
      }
    }
  }
}

// MARK: - XP Earned Badge

/// Animated badge showing XP earned
struct XpEarnedBadge: View {
  let xpAmount: Int
  let isVisible: Bool

  var body: some View {
    if isVisible && xpAmount > 0 {
      Text("+\(xpAmount) XP")
        .font(.rizqSansBold(.caption))
        .foregroundStyle(Color.rizqPrimary)
        .padding(.horizontal, 10)
        .padding(.vertical, 4)
        .background(Color.rizqPrimary.opacity(0.15))
        .clipShape(Capsule())
        .transition(.scale.combined(with: .opacity))
    }
  }
}

// MARK: - Stats Card

/// Generic stats card for displaying a single statistic
struct StatsCard: View {
  let icon: String
  let iconColor: Color
  let value: String
  let label: String
  let isHighlighted: Bool

  init(
    icon: String,
    iconColor: Color,
    value: String,
    label: String,
    isHighlighted: Bool = false
  ) {
    self.icon = icon
    self.iconColor = iconColor
    self.value = value
    self.label = label
    self.isHighlighted = isHighlighted
  }

  var body: some View {
    VStack(spacing: RIZQSpacing.md) {
      ZStack {
        Circle()
          .fill(iconColor.opacity(0.15))
          .frame(width: 44, height: 44)

        Image(systemName: icon)
          .font(.title2)
          .foregroundStyle(iconColor)
      }

      VStack(spacing: RIZQSpacing.xs) {
        Text(value)
          .font(.rizqMonoMedium(.title2))
          .foregroundStyle(Color.rizqText)

        Text(label)
          .font(.rizqSans(.caption))
          .foregroundStyle(Color.rizqTextSecondary)
      }
    }
    .frame(maxWidth: .infinity)
    .padding(.vertical, RIZQSpacing.xl)
    .background(Color.rizqCard)
    .clipShape(RoundedRectangle(cornerRadius: RIZQRadius.islamic))
    .overlay(
      RoundedRectangle(cornerRadius: RIZQRadius.islamic)
        .stroke(isHighlighted ? iconColor.opacity(0.5) : Color.clear, lineWidth: 2)
    )
    .shadowSoft()
  }
}

// MARK: - Animated Number

/// Number that animates when value changes
struct AnimatedNumber: View {
  let value: Int

  @State private var displayValue: Int = 0

  var body: some View {
    Text("\(displayValue)")
      .contentTransition(.numericText(countsDown: displayValue > value))
      .onAppear {
        displayValue = value
      }
      .onChange(of: value) { _, newValue in
        withAnimation(.spring(response: 0.4, dampingFraction: 0.6)) {
          displayValue = newValue
        }
      }
  }
}

// MARK: - Previews

#Preview("Streak Badge") {
  VStack(spacing: 20) {
    HStack(spacing: 16) {
      StreakBadge(streak: 0, isAnimating: false)
      StreakBadge(streak: 7, isAnimating: false)
    }
    StreakBadge(streak: 7, isAnimating: true)
  }
  .padding()
  .background(Color.rizqBackground)
}

#Preview("Circular XP Progress") {
  HStack(spacing: 20) {
    CircularXpProgress(level: 1, percentage: 0.25)
    CircularXpProgress(level: 3, percentage: 0.65)
    CircularXpProgress(level: 10, percentage: 0.9)
  }
  .padding()
  .background(Color.rizqBackground)
}

#Preview("XP Progress Bar") {
  VStack(spacing: 20) {
    XpProgressBar(current: 150, needed: 300, level: 2, xpToNextLevel: 150)
    XpProgressBar(current: 50, needed: 100, level: 1, xpToNextLevel: 50)
  }
  .padding()
  .background(Color.rizqBackground)
}

#Preview("Stats Card") {
  HStack(spacing: 16) {
    StatsCard(
      icon: "flame.fill",
      iconColor: .streakGlow,
      value: "7",
      label: "Day Streak",
      isHighlighted: true
    )
    StatsCard(
      icon: "star.fill",
      iconColor: .levelBadge,
      value: "Level 3",
      label: "450 XP"
    )
  }
  .padding()
  .background(Color.rizqBackground)
}
