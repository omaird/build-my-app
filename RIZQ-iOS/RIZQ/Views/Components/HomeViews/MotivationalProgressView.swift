import SwiftUI
import RIZQKit

// MARK: - Motivational Progress View
//
// Design Decisions:
// - Receives pre-computed MotivationState from parent (TCA pattern)
// - View is "dumb" - renders state, doesn't compute it
// - Shows upcoming achievement preview with glow effect
// - Contextual call-to-action buttons dispatch to parent
//
// Related Files:
// - MotivationState.swift (state model in RIZQKit)
// - Achievement.swift (nextAchievement preview)
// - AchievementBadgeView.swift (badge component)
// - HomeFeature.swift (state computation)
// - HomeView.swift (integration)
// - RIZQTests.swift (MotivationStateTests)
//
// TCA Integration:
// - Parent computes MotivationState from habit data
// - Parent passes streak for message generation
// - onActionTapped closure maps to TCA action
//
// Acceptance Criteria Met:
// 1. ✓ Receives pre-computed MotivationState (TCA "dumb view" pattern)
// 2. ✓ 5 progress states (noHabits, notStarted, lightDay, productiveDay, perfectDay)
// 3. ✓ Upcoming achievement badge preview with golden glow
// 4. ✓ Dynamic titles and messages based on state
// 5. ✓ Streak-aware messaging for notStarted state
// 6. ✓ Contextual CTA buttons with onActionTapped closure
// 7. ✓ Perfect day celebration with rotating gradient ring
// 8. ✓ Haptic feedback (soft/medium/success for different contexts)
// 9. ✓ VoiceOver accessibility with accessibilityDescription
// 10. ✓ Action button with scale/press animation and arrow icon
// 11. ✓ Spring animations on appear
// 12. ✓ Build verified successful

/// Dynamic motivational section that adapts based on daily activity
/// Shows encouraging messages and upcoming achievement preview.
/// Receives pre-computed MotivationState for TCA-friendly architecture.
struct MotivationalProgressView: View {
  let motivationState: MotivationState
  let streak: Int
  let nextAchievement: Achievement?
  let habitsCompleted: Int
  let totalHabits: Int
  var onActionTapped: (() -> Void)?

  @State private var badgeGlow: Double = 0.3
  @State private var isVisible = false
  @State private var isActionPressed = false
  @State private var celebrationOffset: CGFloat = 0

  var body: some View {
    VStack(spacing: RIZQSpacing.xl) {
      // Badge preview (next achievement or current state icon)
      if let achievement = nextAchievement {
        upcomingBadgeSection(achievement)
      } else {
        currentStateBadge
      }

      // Motivational message
      motivationalMessage
        .opacity(isVisible ? 1 : 0)
        .offset(y: isVisible ? 0 : 15)
        .animation(.easeOut(duration: 0.5).delay(0.3), value: isVisible)

      // Call to action
      if motivationState.hasAction {
        actionSuggestion
          .opacity(isVisible ? 1 : 0)
          .animation(.easeOut(duration: 0.5).delay(0.4), value: isVisible)
      }
    }
    .padding(RIZQSpacing.xl)
    .background(backgroundGradient)
    .clipShape(RoundedRectangle(cornerRadius: RIZQRadius.islamic))
    .shadowSoft()
    .accessibilityElement(children: .combine)
    .accessibilityLabel(
      motivationState.accessibilityDescription(
        streak: streak,
        nextAchievementName: nextAchievement?.name
      )
    )
    .onAppear {
      withAnimation(.easeOut(duration: 0.6).delay(0.3)) {
        isVisible = true
      }
      startBadgeGlow()

      // Subtle haptic on section appearance
      UIImpactFeedbackGenerator(style: .soft).impactOccurred()
    }
  }

  // MARK: - Background

  private var backgroundGradient: some View {
    LinearGradient(
      colors: [Color.rizqCard, Color.rizqBackground.opacity(0.5)],
      startPoint: .top,
      endPoint: .bottom
    )
  }

  // MARK: - Badge Sections

  private func upcomingBadgeSection(_ achievement: Achievement) -> some View {
    VStack(spacing: RIZQSpacing.md) {
      // Glowing badge preview
      ZStack {
        // Glow effect
        Circle()
          .fill(Color.goldSoft.opacity(badgeGlow))
          .frame(width: 100, height: 100)
          .blur(radius: 30)

        // Badge (locked, showing progress if available)
        AchievementBadgeView(
          achievement: achievement,
          size: .medium,
          showDetails: false
        )
      }

      Text("Next: \(achievement.name)")
        .font(.rizqSansMedium(.caption))
        .foregroundStyle(Color.rizqTextSecondary)
    }
    .opacity(isVisible ? 1 : 0)
    .scaleEffect(isVisible ? 1 : 0.8)
    .animation(.spring(response: 0.5, dampingFraction: 0.7).delay(0.2), value: isVisible)
  }

  private var currentStateBadge: some View {
    ZStack {
      // Outer glow
      Circle()
        .fill(motivationState.glowColor.opacity(badgeGlow))
        .frame(width: 100, height: 100)
        .blur(radius: 30)

      // Perfect day celebration ring
      if motivationState == .perfectDay {
        celebrationRing
      }

      // Icon
      Image(systemName: motivationState.iconName)
        .font(.system(size: 40))
        .foregroundStyle(motivationState.glowColor)
        .shadow(
          color: motivationState.glowColor.opacity(motivationState == .perfectDay ? 0.6 : 0),
          radius: 8
        )
    }
    .opacity(isVisible ? 1 : 0)
    .scaleEffect(isVisible ? 1 : 0.8)
    .animation(.spring(response: 0.5, dampingFraction: 0.7).delay(0.2), value: isVisible)
    .onAppear {
      if motivationState == .perfectDay {
        // Success haptic for perfect day
        UINotificationFeedbackGenerator().notificationOccurred(.success)
      }
    }
  }

  private var celebrationRing: some View {
    Circle()
      .stroke(
        AngularGradient(
          colors: [
            Color.tealSuccess.opacity(0.8),
            Color.goldBright.opacity(0.6),
            Color.tealSuccess.opacity(0.4),
            Color.goldBright.opacity(0.8),
            Color.tealSuccess.opacity(0.8)
          ],
          center: .center,
          startAngle: .degrees(celebrationOffset),
          endAngle: .degrees(celebrationOffset + 360)
        ),
        lineWidth: 3
      )
      .frame(width: 90, height: 90)
      .onAppear {
        withAnimation(
          .linear(duration: 4.0)
            .repeatForever(autoreverses: false)
        ) {
          celebrationOffset = 360
        }
      }
  }

  // MARK: - Motivational Message

  private var motivationalMessage: some View {
    VStack(spacing: RIZQSpacing.sm) {
      Text(motivationState.title)
        .font(.rizqDisplayBold(.title2))
        .foregroundStyle(Color.rizqText)

      // Progress stats (shows concrete feedback)
      if totalHabits > 0 && motivationState != .noHabits {
        progressStats
      }

      Text(motivationState.message(streak: streak))
        .font(.rizqSans(.body))
        .foregroundStyle(Color.rizqTextSecondary)
        .multilineTextAlignment(.center)
        .lineLimit(nil)
        .fixedSize(horizontal: false, vertical: true)
    }
  }

  private var progressStats: some View {
    HStack(spacing: RIZQSpacing.lg) {
      // Habits completed stat
      statBadge(
        value: "\(habitsCompleted)/\(totalHabits)",
        label: "Habits",
        icon: "checkmark.circle.fill",
        color: habitsCompleted == totalHabits ? .tealSuccess : .rizqPrimary
      )

      // Streak stat (if has streak)
      if streak > 0 {
        statBadge(
          value: "\(streak)",
          label: "Day Streak",
          icon: "flame.fill",
          color: .streakGlow
        )
      }
    }
    .padding(.vertical, RIZQSpacing.sm)
  }

  private func statBadge(value: String, label: String, icon: String, color: Color) -> some View {
    HStack(spacing: RIZQSpacing.xs) {
      Image(systemName: icon)
        .font(.caption)
        .foregroundStyle(color)

      VStack(alignment: .leading, spacing: 0) {
        Text(value)
          .font(.rizqSansMedium(.subheadline))
          .foregroundStyle(Color.rizqText)

        Text(label)
          .font(.rizqSans(.caption2))
          .foregroundStyle(Color.rizqTextSecondary)
      }
    }
    .padding(.horizontal, RIZQSpacing.md)
    .padding(.vertical, RIZQSpacing.xs)
    .background(color.opacity(0.1))
    .clipShape(Capsule())
  }

  // MARK: - Action Suggestion

  private var actionSuggestion: some View {
    Button {
      UIImpactFeedbackGenerator(style: .medium).impactOccurred()
      onActionTapped?()
    } label: {
      HStack(spacing: RIZQSpacing.sm) {
        Text(motivationState.actionText)
          .font(.rizqSansMedium(.subheadline))

        Image(systemName: "arrow.right")
          .font(.caption)
      }
      .foregroundStyle(Color.rizqPrimary)
      .padding(.horizontal, RIZQSpacing.lg)
      .padding(.vertical, RIZQSpacing.sm)
      .background(Color.rizqPrimary.opacity(isActionPressed ? 0.2 : 0.1))
      .clipShape(Capsule())
    }
    .buttonStyle(.plain)
    .scaleEffect(isActionPressed ? 0.95 : 1.0)
    .animation(.spring(response: 0.2, dampingFraction: 0.6), value: isActionPressed)
    .simultaneousGesture(
      DragGesture(minimumDistance: 0)
        .onChanged { _ in isActionPressed = true }
        .onEnded { _ in isActionPressed = false }
    )
    .disabled(onActionTapped == nil)
    .accessibilityHint("Tap to \(motivationState.actionText.lowercased())")
  }

  // MARK: - Animation

  private func startBadgeGlow() {
    withAnimation(
      .easeInOut(duration: 2.0)
        .repeatForever(autoreverses: true)
    ) {
      badgeGlow = 0.6
    }
  }

}

// MARK: - Previews

#Preview("Motivational - No Habits") {
  MotivationalProgressView(
    motivationState: .noHabits,
    streak: 0,
    nextAchievement: Achievement.defaults[0],
    habitsCompleted: 0,
    totalHabits: 0
  )
  .padding()
  .background(Color.rizqBackground)
}

#Preview("Motivational - Not Started (No Streak)") {
  MotivationalProgressView(
    motivationState: MotivationState(habitsCompleted: 0, totalHabits: 5),
    streak: 0,
    nextAchievement: Achievement.defaults[0],
    habitsCompleted: 0,
    totalHabits: 5
  )
  .padding()
  .background(Color.rizqBackground)
}

#Preview("Motivational - Not Started (With Streak)") {
  MotivationalProgressView(
    motivationState: MotivationState(habitsCompleted: 0, totalHabits: 5),
    streak: 4,
    nextAchievement: Achievement.defaults[1],
    habitsCompleted: 0,
    totalHabits: 5
  )
  .padding()
  .background(Color.rizqBackground)
}

#Preview("Motivational - Light Day") {
  MotivationalProgressView(
    motivationState: MotivationState(habitsCompleted: 1, totalHabits: 5),
    streak: 3,
    nextAchievement: Achievement.defaults[0],
    habitsCompleted: 1,
    totalHabits: 5
  )
  .padding()
  .background(Color.rizqBackground)
}

#Preview("Motivational - Productive Day") {
  MotivationalProgressView(
    motivationState: MotivationState(habitsCompleted: 3, totalHabits: 5),
    streak: 5,
    nextAchievement: Achievement.defaults[2],
    habitsCompleted: 3,
    totalHabits: 5
  )
  .padding()
  .background(Color.rizqBackground)
}

#Preview("Motivational - Perfect Day") {
  MotivationalProgressView(
    motivationState: .perfectDay,
    streak: 7,
    nextAchievement: nil,
    habitsCompleted: 5,
    totalHabits: 5
  )
  .padding()
  .background(Color.rizqBackground)
}
