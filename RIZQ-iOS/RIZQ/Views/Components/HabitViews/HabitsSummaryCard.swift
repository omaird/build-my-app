import SwiftUI
import RIZQKit

// MARK: - Habits Summary Card

/// Dashboard summary card showing today's habit progress
/// Matches the web HabitsSummaryCard.tsx component
struct HabitsSummaryCard: View {
  let completed: Int
  let total: Int
  let percentage: Double
  let xpEarned: Int
  let onTap: () -> Void

  @State private var animatedProgress: CGFloat = 0
  @State private var isPressed: Bool = false

  private var isAllComplete: Bool {
    total > 0 && completed == total
  }

  var body: some View {
    Button(action: onTap) {
      VStack(alignment: .leading, spacing: RIZQSpacing.md) {
        // Header row
        HStack {
          HStack(spacing: RIZQSpacing.sm) {
            ZStack {
              Circle()
                .fill(isAllComplete ? Color.tealSuccess.opacity(0.2) : Color.rizqPrimary.opacity(0.1))
                .frame(width: 32, height: 32)

              Image(systemName: isAllComplete ? "checkmark" : "target")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(isAllComplete ? Color.tealSuccess : Color.rizqPrimary)
            }

            Text("Today's Habits")
              .font(.rizqSansSemiBold(.headline))
              .foregroundStyle(Color.rizqText)
          }

          Spacer()

          Text("\(completed)/\(total)")
            .font(.rizqMono(.subheadline))
            .foregroundStyle(Color.rizqTextSecondary)
        }

        // Progress bar
        GeometryReader { geometry in
          ZStack(alignment: .leading) {
            Capsule()
              .fill(Color.rizqMuted.opacity(0.3))
              .frame(height: 8)

            Capsule()
              .fill(isAllComplete ? Color.tealSuccess : Color.rizqPrimary)
              .frame(width: geometry.size.width * animatedProgress, height: 8)
          }
        }
        .frame(height: 8)

        // Footer row
        HStack {
          Text(isAllComplete ? "All habits complete!" : "\(total - completed) remaining")
            .font(.rizqSans(.caption))
            .foregroundStyle(Color.rizqTextSecondary)

          Spacer()

          if xpEarned > 0 {
            Text("+\(xpEarned) XP earned")
              .font(.rizqSansMedium(.caption))
              .foregroundStyle(Color.rizqPrimary)
          }
        }
      }
      .padding(RIZQSpacing.lg)
      .background(
        RoundedRectangle(cornerRadius: RIZQRadius.islamic)
          .fill(isAllComplete ? Color.tealSuccess.opacity(0.05) : Color.rizqCard)
      )
      .overlay(
        RoundedRectangle(cornerRadius: RIZQRadius.islamic)
          .stroke(
            isAllComplete ? Color.tealSuccess.opacity(0.3) : Color.rizqBorder,
            lineWidth: 1
          )
      )
      .scaleEffect(isPressed ? 0.98 : 1.0)
      .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isPressed)
      .shadowSoft()
    }
    .buttonStyle(.plain)
    .onLongPressGesture(minimumDuration: .infinity, maximumDistance: .infinity) {
      // No action on complete
    } onPressingChanged: { pressing in
      isPressed = pressing
    }
    .onAppear {
      withAnimation(.easeOut(duration: 0.5)) {
        animatedProgress = CGFloat(percentage)
      }
    }
    .onChange(of: percentage) { _, newValue in
      withAnimation(.easeOut(duration: 0.3)) {
        animatedProgress = CGFloat(newValue)
      }
    }
  }
}

// MARK: - Habit Progress Row

/// A single row showing habit progress by time slot
struct HabitProgressRow: View {
  let timeSlot: TimeSlot
  let completed: Int
  let total: Int

  private var progress: Double {
    total > 0 ? Double(completed) / Double(total) : 0
  }

  private var isComplete: Bool {
    total > 0 && completed == total
  }

  var body: some View {
    HStack(spacing: RIZQSpacing.md) {
      // Time slot icon
      ZStack {
        Circle()
          .fill(timeSlotColor.opacity(0.15))
          .frame(width: 36, height: 36)

        Image(systemName: timeSlot.icon)
          .font(.subheadline)
          .foregroundStyle(timeSlotColor)
      }

      // Label and progress
      VStack(alignment: .leading, spacing: 4) {
        Text(timeSlot.displayName)
          .font(.rizqSansMedium(.subheadline))
          .foregroundStyle(Color.rizqText)

        GeometryReader { geometry in
          ZStack(alignment: .leading) {
            Capsule()
              .fill(Color.rizqMuted.opacity(0.3))
              .frame(height: 4)

            Capsule()
              .fill(isComplete ? Color.tealSuccess : timeSlotColor)
              .frame(width: geometry.size.width * progress, height: 4)
          }
        }
        .frame(height: 4)
      }

      Spacer()

      // Count
      Text("\(completed)/\(total)")
        .font(.rizqMono(.caption))
        .foregroundStyle(Color.rizqTextSecondary)

      // Checkmark if complete
      if isComplete {
        Image(systemName: "checkmark.circle.fill")
          .foregroundStyle(Color.tealSuccess)
          .font(.subheadline)
      }
    }
    .padding(.vertical, RIZQSpacing.sm)
  }

  private var timeSlotColor: Color {
    switch timeSlot {
    case .morning: return .badgeMorning
    case .anytime: return .tealMuted
    case .evening: return .badgeEvening
    }
  }
}

// MARK: - Empty Habits State

/// Empty state shown when no habits are configured
struct EmptyHabitsState: View {
  let onAddHabits: () -> Void

  var body: some View {
    VStack(spacing: RIZQSpacing.lg) {
      Image(systemName: "sun.and.horizon")
        .font(.system(size: 48))
        .foregroundStyle(Color.rizqPrimary.opacity(0.5))

      VStack(spacing: RIZQSpacing.sm) {
        Text("No habits yet")
          .font(.rizqDisplayMedium(.headline))
          .foregroundStyle(Color.rizqText)

        Text("Start a journey to build your daily routine")
          .font(.rizqSans(.subheadline))
          .foregroundStyle(Color.rizqTextSecondary)
          .multilineTextAlignment(.center)
      }

      Button(action: onAddHabits) {
        Text("Browse Journeys")
          .rizqSecondaryButton()
      }
    }
    .frame(maxWidth: .infinity)
    .padding(RIZQSpacing.xxl)
    .rizqCard()
  }
}

// MARK: - Previews

#Preview("Habits Summary Card") {
  VStack(spacing: 20) {
    HabitsSummaryCard(
      completed: 3,
      total: 5,
      percentage: 0.6,
      xpEarned: 45,
      onTap: {}
    )

    HabitsSummaryCard(
      completed: 5,
      total: 5,
      percentage: 1.0,
      xpEarned: 75,
      onTap: {}
    )

    HabitsSummaryCard(
      completed: 0,
      total: 5,
      percentage: 0,
      xpEarned: 0,
      onTap: {}
    )
  }
  .padding()
  .background(Color.rizqBackground)
}

#Preview("Habit Progress Row") {
  VStack(spacing: 8) {
    HabitProgressRow(timeSlot: .morning, completed: 2, total: 3)
    HabitProgressRow(timeSlot: .anytime, completed: 1, total: 2)
    HabitProgressRow(timeSlot: .evening, completed: 3, total: 3)
  }
  .padding()
  .rizqCard()
  .padding()
  .background(Color.rizqBackground)
}

#Preview("Empty Habits State") {
  EmptyHabitsState(onAddHabits: {})
    .padding()
    .background(Color.rizqBackground)
}
