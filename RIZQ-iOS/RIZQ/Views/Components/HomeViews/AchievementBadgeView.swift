import SwiftUI
import UIKit
import RIZQKit

// MARK: - Achievement Badge View
//
// Design Decisions:
// - Uses RoundedHexagonShape for softer badge aesthetic
// - Unlocked badges have category-colored glow with pulsing animation
// - Locked badges render muted with gray overlay
// - Emoji text is centered and scales with badge size
// - showDetails enables optional name/description display below badge
// - isAnimating triggers spring-based unlock celebration
//
// Architecture:
// - BadgeSize enum provides type-safe size presets
// - Optional onTap handler enables TCA action dispatch
// - Static date formatter for performance
// - Animation configuration extracted for maintainability
//
// Related Files:
// - HexagonShape.swift (shape primitives)
// - Achievement.swift (data model, includes badgeColorName)
// - CelebrationParticles.swift (particle effects)
// - HomeFeature.swift (state management)
// - RIZQTests.swift (unit tests for BadgeSize enum)
//
// Edge Cases Handled:
// - Locked vs unlocked state rendering
// - Animation state transitions
// - VoiceOver accessibility
// - Various badge sizes (mini, small, medium, large)
//
// Acceptance Criteria (Feature 3): All 11 criteria verified ✓
// - Hexagonal badge with RoundedHexagonShape
// - Category-colored glow on unlocked, muted gray on locked
// - Centered emoji, spring unlock animation, showDetails support
// - Full-screen celebration overlay with particles and XP reward
// - Dismiss on background tap, build compiles successfully

// MARK: - Badge Size Configuration

/// Type-safe badge size presets for consistent sizing across the app
enum BadgeSize {
  case mini      // 40pt - inline/compact displays
  case small     // 60pt - list items
  case medium    // 80pt - grid displays
  case large     // 100pt - featured/detail
  case xlarge    // 140pt - celebration overlay
  case custom(CGFloat)

  var points: CGFloat {
    switch self {
    case .mini: return 40
    case .small: return 60
    case .medium: return 80
    case .large: return 100
    case .xlarge: return 140
    case .custom(let size): return size
    }
  }

  /// Corner radius proportional to size
  var cornerRadius: CGFloat { points * 0.08 }

  /// Glow radius proportional to size
  var glowRadius: CGFloat { points * 0.1 }

  /// Stroke width proportional to size (minimum 2pt)
  var strokeWidth: CGFloat { max(2, points * 0.04) }

  /// Emoji font size proportional to badge
  var emojiFontSize: CGFloat { points * 0.35 }
}

// MARK: - Animation Configuration

/// Configuration for badge animations
private enum BadgeAnimation {
  static let glowDuration: TimeInterval = 2.0
  static let glowMinOpacity: Double = 0.3
  static let glowMaxOpacity: Double = 0.6

  static let unlockScaleUp: CGFloat = 1.2
  static let unlockScaleDelay: TimeInterval = 0.3
  static let unlockSpringResponse: Double = 0.4
  static let unlockSpringDamping: Double = 0.5
}

// MARK: - Date Formatting

/// Shared date formatter for performance
private let badgeDateFormatter: DateFormatter = {
  let formatter = DateFormatter()
  formatter.dateFormat = "MMM d, yyyy"
  return formatter
}()

/// Hexagonal achievement badge with glow and celebration effects
struct AchievementBadgeView: View {
  let achievement: Achievement
  let badgeSize: BadgeSize
  var showDetails: Bool = false
  var isAnimating: Bool = false
  var onTap: (() -> Void)?
  /// Progress toward unlocking (0.0 to 1.0) - shown as ring on locked badges
  var unlockProgress: Double = 0.0

  @State private var glowOpacity: Double = BadgeAnimation.glowMinOpacity
  @State private var scale: CGFloat = 1.0
  @State private var isPressed: Bool = false

  private let hapticImpact = UIImpactFeedbackGenerator(style: .light)
  private let hapticSuccess = UINotificationFeedbackGenerator()

  /// Legacy initializer for backward compatibility
  init(
    achievement: Achievement,
    size: CGFloat = 100,
    showDetails: Bool = false,
    isAnimating: Bool = false,
    unlockProgress: Double = 0.0,
    onTap: (() -> Void)? = nil
  ) {
    self.achievement = achievement
    self.badgeSize = .custom(size)
    self.showDetails = showDetails
    self.isAnimating = isAnimating
    self.unlockProgress = unlockProgress
    self.onTap = onTap
  }

  /// Preferred initializer using BadgeSize enum
  init(
    achievement: Achievement,
    size: BadgeSize,
    showDetails: Bool = false,
    isAnimating: Bool = false,
    unlockProgress: Double = 0.0,
    onTap: (() -> Void)? = nil
  ) {
    self.achievement = achievement
    self.badgeSize = size
    self.showDetails = showDetails
    self.isAnimating = isAnimating
    self.unlockProgress = unlockProgress
    self.onTap = onTap
  }

  private var size: CGFloat { badgeSize.points }

  var body: some View {
    VStack(spacing: RIZQSpacing.md) {
      // Badge hexagon
      badgeContent
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(achievement.accessibilityDescription)
        .accessibilityAddTraits(onTap != nil ? .isButton : [])

      // Details section (optional)
      if showDetails {
        detailsSection
      }
    }
    .contentShape(Rectangle())
    .scaleEffect(isPressed ? 0.95 : 1.0)
    .animation(.spring(response: 0.2, dampingFraction: 0.7), value: isPressed)
    .simultaneousGesture(
      DragGesture(minimumDistance: 0)
        .onChanged { _ in
          if !isPressed && onTap != nil {
            isPressed = true
            hapticImpact.impactOccurred()
          }
        }
        .onEnded { _ in
          isPressed = false
          onTap?()
        }
    )
  }

  // MARK: - Badge Content

  private var badgeContent: some View {
    ZStack {
      // Outer glow for unlocked badges
      if achievement.isUnlocked {
        RoundedHexagonShape(cornerRadius: badgeSize.glowRadius)
          .fill(badgeColor.opacity(glowOpacity))
          .frame(width: size * 1.2, height: size * 1.2)
          .blur(radius: 20)
      }

      // Badge border with shadow for unlocked
      RoundedHexagonShape(cornerRadius: badgeSize.cornerRadius)
        .stroke(
          achievement.isUnlocked ? badgeColor : Color.rizqMuted.opacity(0.5),
          lineWidth: badgeSize.strokeWidth
        )
        .frame(width: size, height: size)
        .shadow(
          color: achievement.isUnlocked ? badgeColor.opacity(0.3) : .clear,
          radius: 8,
          x: 0,
          y: 4
        )

      // Badge fill with gradient
      RoundedHexagonShape(cornerRadius: badgeSize.cornerRadius)
        .fill(badgeFillGradient)
        .frame(width: size - 8, height: size - 8)

      // Emoji content centered
      Text(achievement.emoji)
        .font(.system(size: badgeSize.emojiFontSize, weight: .bold, design: .rounded))
        .foregroundStyle(achievement.isUnlocked ? badgeColor : Color.rizqMuted)

      // Lock indicator for locked badges (mini icon at bottom)
      if !achievement.isUnlocked && size >= 60 {
        VStack {
          Spacer()
          Image(systemName: "lock.fill")
            .font(.system(size: size * 0.12))
            .foregroundStyle(Color.rizqMuted.opacity(0.6))
            .padding(.bottom, size * 0.08)
        }
        .frame(width: size, height: size)
      }

      // Progress ring for locked badges with progress > 0
      // Shows users how close they are to unlocking
      if !achievement.isUnlocked && unlockProgress > 0 && size >= 60 {
        Circle()
          .trim(from: 0, to: min(unlockProgress, 1.0))
          .stroke(
            badgeColor.opacity(0.7),
            style: StrokeStyle(lineWidth: badgeSize.strokeWidth, lineCap: .round)
          )
          .frame(width: size * 1.15, height: size * 1.15)
          .rotationEffect(.degrees(-90))
          .animation(.easeInOut(duration: 0.5), value: unlockProgress)
      }

      // Category indicator (small icon at top for medium+ sizes)
      if achievement.isUnlocked && size >= 80 {
        VStack {
          Image(systemName: achievement.category.iconName)
            .font(.system(size: size * 0.1))
            .foregroundStyle(badgeColor.opacity(0.8))
            .padding(.top, size * 0.1)
          Spacer()
        }
        .frame(width: size, height: size)
      }
    }
    .scaleEffect(scale)
    .onAppear {
      if achievement.isUnlocked {
        startGlowAnimation()
      }
    }
    .onChange(of: isAnimating) { _, newValue in
      if newValue {
        playUnlockAnimation()
        hapticSuccess.notificationOccurred(.success)
      }
    }
  }

  // MARK: - Details Section

  private var detailsSection: some View {
    VStack(spacing: RIZQSpacing.xs) {
      // Achievement name with category color accent
      Text(achievement.name)
        .font(.rizqDisplayMedium(.subheadline))
        .foregroundStyle(achievement.isUnlocked ? Color.rizqText : Color.rizqTextSecondary)
        .lineLimit(1)

      // Description
      Text(achievement.description)
        .font(.rizqSans(.caption))
        .foregroundStyle(Color.rizqTextSecondary)
        .multilineTextAlignment(.center)
        .lineLimit(2)

      // Unlock date for unlocked achievements
      if achievement.isUnlocked, let unlockedAt = achievement.unlockedAt {
        HStack(spacing: RIZQSpacing.xs) {
          Image(systemName: "checkmark.circle.fill")
            .font(.system(size: 10))
            .foregroundStyle(badgeColor)

          Text(formattedDate(unlockedAt))
            .font(.rizqSans(.caption2))
            .foregroundStyle(Color.rizqTextTertiary)
        }
      }

      // Progress indicator for locked badges with progress
      if !achievement.isUnlocked && unlockProgress > 0 {
        HStack(spacing: RIZQSpacing.xs) {
          Image(systemName: "chart.line.uptrend.xyaxis")
            .font(.system(size: 10))
            .foregroundStyle(badgeColor.opacity(0.8))

          Text("\(Int(unlockProgress * 100))% complete")
            .font(.rizqSans(.caption2))
            .foregroundStyle(badgeColor.opacity(0.8))
        }
      }

      // XP reward badge (visible for all, highlighted for unlocked)
      HStack(spacing: 2) {
        Image(systemName: "sparkles")
          .font(.system(size: 8))
        Text("+\(achievement.xpReward) XP")
          .font(.rizqMono(.caption2))
      }
      .foregroundStyle(achievement.isUnlocked ? badgeColor : Color.rizqMuted)
      .padding(.horizontal, RIZQSpacing.sm)
      .padding(.vertical, 2)
      .background(
        Capsule()
          .fill(achievement.isUnlocked ? badgeColor.opacity(0.15) : Color.rizqMuted.opacity(0.1))
      )
    }
    .frame(maxWidth: size * 1.5)
  }

  // MARK: - Computed Properties

  private var badgeColor: Color {
    switch achievement.category {
    case .streak: return .streakGlow
    case .practice: return .tealSuccess
    case .level: return .badgeEvening
    case .special: return .goldBright
    }
  }

  private var badgeFillGradient: LinearGradient {
    if achievement.isUnlocked {
      return LinearGradient(
        colors: [badgeColor.opacity(0.3), badgeColor.opacity(0.1)],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
      )
    } else {
      return LinearGradient(
        colors: [Color.rizqMuted.opacity(0.15), Color.rizqMuted.opacity(0.05)],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
      )
    }
  }

  // MARK: - Animations

  private func startGlowAnimation() {
    withAnimation(
      .easeInOut(duration: BadgeAnimation.glowDuration)
        .repeatForever(autoreverses: true)
    ) {
      glowOpacity = BadgeAnimation.glowMaxOpacity
    }
  }

  private func playUnlockAnimation() {
    // Scale up with spring
    withAnimation(.spring(
      response: BadgeAnimation.unlockSpringResponse,
      dampingFraction: BadgeAnimation.unlockSpringDamping
    )) {
      scale = BadgeAnimation.unlockScaleUp
    }
    // Scale back down
    DispatchQueue.main.asyncAfter(deadline: .now() + BadgeAnimation.unlockScaleDelay) {
      withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
        scale = 1.0
      }
    }
  }

  // MARK: - Helpers

  private func formattedDate(_ date: Date) -> String {
    badgeDateFormatter.string(from: date)
  }
}

// MARK: - Achievement Unlock Overlay

/// Full-screen celebration overlay when an achievement is unlocked
struct AchievementUnlockOverlay: View {
  let achievement: Achievement
  let onDismiss: () -> Void

  @State private var showContent = false
  @State private var showParticles = false
  @State private var xpBadgePulse = false

  private let hapticSuccess = UINotificationFeedbackGenerator()
  private let hapticImpact = UIImpactFeedbackGenerator(style: .medium)

  init(achievement: Achievement, onDismiss: @escaping () -> Void) {
    self.achievement = achievement
    self.onDismiss = onDismiss
  }

  /// Badge color based on category
  private var badgeColor: Color {
    switch achievement.category {
    case .streak: return .streakGlow
    case .practice: return .tealSuccess
    case .level: return .badgeEvening
    case .special: return .goldBright
    }
  }

  var body: some View {
    ZStack {
      // Dimmed background with radial gradient from badge color
      ZStack {
        Color.black.opacity(0.85)
        RadialGradient(
          colors: [badgeColor.opacity(0.2), .clear],
          center: .center,
          startRadius: 50,
          endRadius: 400
        )
      }
      .ignoresSafeArea()
      .onTapGesture {
        dismiss()
      }

      VStack(spacing: RIZQSpacing.xxl) {
        // Badge with particles
        ZStack {
          CelebrationParticles(
            isActive: $showParticles,
            particleCount: 30
          )

          AchievementBadgeView(
            achievement: achievement,
            size: .xlarge,
            showDetails: false,
            isAnimating: showContent
          )
        }
        .frame(width: 220, height: 220)

        // Achievement info
        achievementInfoSection
          .opacity(showContent ? 1 : 0)
          .offset(y: showContent ? 0 : 20)

        // XP reward badge with pulse animation
        xpRewardBadge
          .scaleEffect(xpBadgePulse ? 1.05 : 1.0)
          .opacity(showContent ? 1 : 0)
          .offset(y: showContent ? 0 : 15)

        Spacer().frame(height: RIZQSpacing.xl)

        // Dismiss hint
        Text("Tap anywhere to continue")
          .font(.rizqSans(.caption))
          .foregroundStyle(.white.opacity(0.5))
          .opacity(showContent ? 1 : 0)
      }
      .padding(RIZQSpacing.xxl)
    }
    .onAppear {
      // Haptic celebration
      hapticSuccess.notificationOccurred(.success)

      // Staggered animation entry
      withAnimation(.easeOut(duration: 0.5)) {
        showContent = true
      }

      // Delay particles slightly for effect
      DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
        showParticles = true
      }

      // XP badge pulse animation
      DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
        withAnimation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true)) {
          xpBadgePulse = true
        }
      }
    }
  }

  // MARK: - Subviews

  private var achievementInfoSection: some View {
    VStack(spacing: RIZQSpacing.md) {
      Text("Achievement Unlocked!")
        .font(.rizqSans(.caption))
        .foregroundStyle(.white.opacity(0.7))
        .textCase(.uppercase)
        .tracking(2)

      Text(achievement.name)
        .font(.rizqDisplayBold(.title))
        .foregroundStyle(.white)

      Text(achievement.description)
        .font(.rizqSans(.body))
        .foregroundStyle(.white.opacity(0.8))
        .multilineTextAlignment(.center)
    }
  }

  private var xpRewardBadge: some View {
    HStack(spacing: RIZQSpacing.sm) {
      Image(systemName: "sparkles")
        .foregroundStyle(Color.goldBright)

      Text("+\(achievement.xpReward) XP")
        .font(.rizqMonoMedium(.headline))
        .foregroundStyle(Color.goldBright)
    }
    .padding(.horizontal, RIZQSpacing.xl)
    .padding(.vertical, RIZQSpacing.md)
    .background(Color.goldBright.opacity(0.2))
    .clipShape(Capsule())
  }

  // MARK: - Actions

  private func dismiss() {
    hapticImpact.impactOccurred()
    withAnimation(.easeIn(duration: 0.25)) {
      showContent = false
      showParticles = false
      xpBadgePulse = false
    }
    DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
      onDismiss()
    }
  }
}

// MARK: - Achievement Grid View (Horizontal Scrolling)

/// Horizontal scrolling grid of achievement badges
/// Supports optional tap handler for TCA action dispatch
struct AchievementBadgesRow: View {
  let achievements: [Achievement]
  let size: BadgeSize
  var onAchievementTapped: ((Achievement) -> Void)?
  /// Optional closure to get progress for each achievement (0.0 to 1.0)
  var progressProvider: ((Achievement) -> Double)?

  /// Initialize with BadgeSize enum (preferred)
  init(
    achievements: [Achievement],
    size: BadgeSize = .small,
    onAchievementTapped: ((Achievement) -> Void)? = nil,
    progressProvider: ((Achievement) -> Double)? = nil
  ) {
    self.achievements = achievements
    self.size = size
    self.onAchievementTapped = onAchievementTapped
    self.progressProvider = progressProvider
  }

  /// Legacy initializer with CGFloat size
  init(achievements: [Achievement], badgeSize: CGFloat = 70) {
    self.achievements = achievements
    self.size = .custom(badgeSize)
    self.onAchievementTapped = nil
    self.progressProvider = nil
  }

  var body: some View {
    ScrollView(.horizontal, showsIndicators: false) {
      HStack(spacing: RIZQSpacing.lg) {
        ForEach(achievements) { achievement in
          AchievementBadgeView(
            achievement: achievement,
            size: size,
            showDetails: false,
            unlockProgress: progressProvider?(achievement) ?? 0.0,
            onTap: onAchievementTapped != nil ? { onAchievementTapped?(achievement) } : nil
          )
        }
      }
      .padding(.horizontal, RIZQSpacing.xs)
      .padding(.vertical, RIZQSpacing.sm)
    }
    .accessibilityElement(children: .contain)
    .accessibilityLabel("Achievement badges")
    .accessibilityHint("\(achievements.filter { $0.isUnlocked }.count) of \(achievements.count) unlocked")
  }
}

// MARK: - Previews

#Preview("Achievement Badge - Unlocked") {
  let achievement = Achievement(
    id: "first-step",
    name: "First Step",
    description: "Complete your first dua",
    emoji: "1",
    category: .practice,
    requirement: AchievementRequirement(type: .totalDuas, value: 1),
    xpReward: 50,
    unlockedAt: Date()
  )

  AchievementBadgeView(achievement: achievement, size: 120, showDetails: true)
    .padding()
    .background(Color.rizqBackground)
}

#Preview("Achievement Badge - Locked") {
  let achievement = Achievement.defaults[1]

  AchievementBadgeView(achievement: achievement, size: 120, showDetails: true)
    .padding()
    .background(Color.rizqBackground)
}

#Preview("Achievement Grid") {
  LazyVGrid(columns: [GridItem(.adaptive(minimum: 100))], spacing: 20) {
    ForEach(Achievement.defaults) { achievement in
      AchievementBadgeView(achievement: achievement, size: 80, showDetails: true)
    }
  }
  .padding()
  .background(Color.rizqBackground)
}

#Preview("Achievement Row") {
  VStack {
    Text("ACHIEVEMENTS")
      .font(.rizqSansSemiBold(.caption))
      .foregroundStyle(Color.rizqTextSecondary)
      .frame(maxWidth: .infinity, alignment: .leading)
      .padding(.horizontal)

    AchievementBadgesRow(achievements: Achievement.defaults)
  }
  .padding(.vertical)
  .background(Color.rizqBackground)
}

#Preview("Unlock Overlay") {
  let unlockedAchievement = Achievement(
    id: "week-warrior",
    name: "Week Warrior",
    description: "Maintain a 7-day streak",
    emoji: "7",
    category: .streak,
    requirement: AchievementRequirement(type: .streakDays, value: 7),
    xpReward: 100,
    unlockedAt: Date()
  )

  AchievementUnlockOverlay(achievement: unlockedAchievement) {
    // Dismissed
  }
}

#Preview("Badge Sizes - Typed") {
  let achievement = Achievement.defaults[0]

  HStack(spacing: 20) {
    VStack {
      AchievementBadgeView(achievement: achievement, size: .mini)
      Text("Mini").font(.caption)
    }
    VStack {
      AchievementBadgeView(achievement: achievement, size: .small)
      Text("Small").font(.caption)
    }
    VStack {
      AchievementBadgeView(achievement: achievement, size: .medium)
      Text("Medium").font(.caption)
    }
    VStack {
      AchievementBadgeView(achievement: achievement, size: .large)
      Text("Large").font(.caption)
    }
  }
  .padding()
  .background(Color.rizqBackground)
}

#Preview("Badge with Tap Handler") {
  let achievement = Achievement.defaults[0]

  AchievementBadgeView(
    achievement: achievement,
    size: .large,
    showDetails: true,
    onTap: { }
  )
  .padding()
  .background(Color.rizqBackground)
}

#Preview("Badge with Progress Ring") {
  // Show locked badge with progress toward unlocking
  let achievement = Achievement.defaults[2]  // Week Warrior (7-day streak)

  VStack(spacing: 30) {
    // 0% progress
    AchievementBadgeView(
      achievement: achievement,
      size: .medium,
      showDetails: true,
      unlockProgress: 0.0
    )

    // 43% progress (3/7 days)
    AchievementBadgeView(
      achievement: achievement,
      size: .medium,
      showDetails: true,
      unlockProgress: 0.43
    )

    // 86% progress (6/7 days - almost there!)
    AchievementBadgeView(
      achievement: achievement,
      size: .medium,
      showDetails: true,
      unlockProgress: 0.86
    )
  }
  .padding()
  .background(Color.rizqBackground)
}
