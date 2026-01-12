import SwiftUI
import UIKit
import RIZQKit

// MARK: - Weekly Tracker View
//
// Design Decisions:
// - Compact horizontal tracker showing 7-day progress at a glance
// - Current day highlighted with pulsing ring indicator
// - Completed days show teal checkmark with scale animation
// - Staggered animation on appear for visual interest
// - Uses existing DailyActivityItem model from WeekCalendarView
//
// Related Files:
// - WeekCalendarView.swift (DailyActivityItem model)
// - HomeView.swift (integration)
// - HomeFeature.swift (state management)

/// Horizontal week tracker showing daily completion status
/// A streamlined version optimized for the home screen header
struct WeeklyTrackerView: View {
  let activities: [DailyActivityItem]
  var onDayTapped: ((Date) -> Void)?

  @State private var animatedDays: Set<Int> = []
  @State private var showPerfectWeekCelebration = false

  private let hapticImpact = UIImpactFeedbackGenerator(style: .light)

  var body: some View {
    VStack(spacing: RIZQSpacing.md) {
      // Header with completion count
      headerRow

      // Day indicators
      dayIndicators

      // Motivational message (if applicable)
      if let message = motivationMessage {
        Text(message)
          .font(.rizqSans(.caption))
          .foregroundStyle(Color.rizqTextSecondary)
          .frame(maxWidth: .infinity)
          .padding(.top, RIZQSpacing.xs)
      }
    }
    .padding(RIZQSpacing.lg)
    .background(Color.rizqCard)
    .clipShape(RoundedRectangle(cornerRadius: RIZQRadius.islamic))
    .overlay(
      RoundedRectangle(cornerRadius: RIZQRadius.islamic)
        .stroke(isPerfectWeek ? Color.goldBright.opacity(0.5) : Color.rizqBorder, lineWidth: isPerfectWeek ? 2 : 1)
    )
    .shadowSoft()
    .accessibilityElement(children: .combine)
    .accessibilityLabel(accessibilityDescription)
    .accessibilityHint("Double tap on a day to view details")
    .onAppear {
      animateDaysSequentially()
      if isPerfectWeek {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
          withAnimation(.spring(response: 0.5, dampingFraction: 0.6)) {
            showPerfectWeekCelebration = true
          }
        }
      }
    }
  }

  // MARK: - Header Row

  private var headerRow: some View {
    HStack {
      Text("THIS WEEK")
        .font(.rizqSansSemiBold(.caption))
        .foregroundStyle(Color.rizqTextSecondary)
        .tracking(1)

      Spacer()

      // Completion summary
      HStack(spacing: RIZQSpacing.xs) {
        Text("\(completedCount)/7")
          .font(.rizqSansSemiBold(.caption))
          .foregroundStyle(isPerfectWeek ? Color.goldBright : Color.rizqPrimary)
          .scaleEffect(isPerfectWeek && showPerfectWeekCelebration ? 1.1 : 1.0)
          .animation(.spring(response: 0.3, dampingFraction: 0.6), value: showPerfectWeekCelebration)

        Text("days")
          .font(.rizqSans(.caption))
          .foregroundStyle(Color.rizqTextSecondary)

        if isPerfectWeek {
          Image(systemName: "sparkles")
            .font(.caption)
            .foregroundStyle(Color.goldBright)
            .scaleEffect(showPerfectWeekCelebration ? 1.2 : 0.8)
            .opacity(showPerfectWeekCelebration ? 1.0 : 0.6)
            .animation(
              .spring(response: 0.4, dampingFraction: 0.5)
                .repeatForever(autoreverses: true),
              value: showPerfectWeekCelebration
            )
        }
      }
    }
  }

  // MARK: - Day Indicators

  private var dayIndicators: some View {
    HStack(spacing: 0) {
      ForEach(Array(activities.enumerated()), id: \.offset) { index, activity in
        dayColumn(activity: activity, index: index)
          .frame(maxWidth: .infinity)
          .contentShape(Rectangle())
          .onTapGesture {
            hapticImpact.impactOccurred()
            onDayTapped?(activity.date)
          }
          .accessibilityElement(children: .ignore)
          .accessibilityLabel(dayAccessibilityLabel(for: activity))
          .accessibilityAddTraits(activity.isToday ? .isSelected : [])
      }
    }
  }

  private func dayAccessibilityLabel(for activity: DailyActivityItem) -> String {
    let dayFormatter = DateFormatter()
    dayFormatter.dateFormat = "EEEE, MMMM d"
    let dateStr = dayFormatter.string(from: activity.date)
    let status = activity.completed ? "completed" : "not completed"
    let todayIndicator = activity.isToday ? "Today, " : ""
    return "\(todayIndicator)\(dateStr), \(status)"
  }

  private func dayColumn(activity: DailyActivityItem, index: Int) -> some View {
    VStack(spacing: RIZQSpacing.sm) {
      // Day abbreviation
      Text(activity.dayLabel)
        .font(.rizqSansSemiBold(.caption2))
        .foregroundStyle(activity.isToday ? Color.rizqPrimary : Color.rizqTextSecondary)
        .textCase(.uppercase)

      // Day indicator
      dayIndicator(for: activity, index: index)

      // Date number
      Text(dayNumber(from: activity.date))
        .font(.rizqMono(.caption2))
        .foregroundStyle(activity.isToday ? Color.rizqText : Color.rizqTextTertiary)
    }
  }

  @ViewBuilder
  private func dayIndicator(for activity: DailyActivityItem, index: Int) -> some View {
    ZStack {
      // Background circle
      Circle()
        .fill(indicatorBackground(for: activity))
        .frame(width: 32, height: 32)

      if activity.completed {
        // Checkmark for completed days
        Image(systemName: "checkmark")
          .font(.system(size: 12, weight: .bold))
          .foregroundStyle(.white)
          .scaleEffect(animatedDays.contains(index) ? 1 : 0)
          .animation(
            .spring(response: 0.4, dampingFraction: 0.6)
              .delay(0.05 * Double(index)),
            value: animatedDays.contains(index)
          )
      } else if activity.isToday {
        // Pulsing ring for today
        Circle()
          .stroke(Color.rizqPrimary, lineWidth: 2)
          .frame(width: 32, height: 32)
          .modifier(PulsingRingModifier())
      } else {
        // Empty dot for future/incomplete days
        Circle()
          .fill(Color.rizqMuted.opacity(0.3))
          .frame(width: 8, height: 8)
      }
    }
    .shadow(
      color: activity.completed ? Color.tealSuccess.opacity(0.3) : .clear,
      radius: 4
    )
  }

  private func indicatorBackground(for activity: DailyActivityItem) -> Color {
    if activity.completed {
      return Color.tealSuccess
    } else if activity.isToday {
      return Color.rizqMuted.opacity(0.2)
    } else {
      return Color.rizqMuted.opacity(0.1)
    }
  }

  // MARK: - Computed Properties

  private var completedCount: Int {
    activities.filter { $0.completed }.count
  }

  private var isPerfectWeek: Bool {
    completedCount == 7
  }

  /// Contextual motivation message based on current progress
  private var motivationMessage: String? {
    switch completedCount {
    case 0:
      return "Start your journey today!"
    case 1...2:
      return "Great start! Keep building momentum."
    case 3...4:
      return "You're doing amazing!"
    case 5...6:
      return "Almost there! Stay consistent."
    case 7:
      return nil // Perfect week has its own celebration
    default:
      return nil
    }
  }

  private func dayNumber(from date: Date) -> String {
    let formatter = DateFormatter()
    formatter.dateFormat = "d"
    return formatter.string(from: date)
  }

  // MARK: - Animation

  private func animateDaysSequentially() {
    for i in 0..<activities.count {
      DispatchQueue.main.asyncAfter(deadline: .now() + 0.1 + 0.05 * Double(i)) {
        animatedDays.insert(i)
      }
    }
  }
}

// MARK: - Pulsing Ring Modifier

/// Creates a subtle pulsing animation for the "today" indicator
private struct PulsingRingModifier: ViewModifier {
  @State private var isPulsing = false

  func body(content: Content) -> some View {
    content
      .scaleEffect(isPulsing ? 1.1 : 1.0)
      .opacity(isPulsing ? 0.6 : 1.0)
      .onAppear {
        withAnimation(
          .easeInOut(duration: 1.2)
            .repeatForever(autoreverses: true)
        ) {
          isPulsing = true
        }
      }
  }
}

// MARK: - VoiceOver Support

extension WeeklyTrackerView {
  /// Accessibility description for the week tracker
  var accessibilityDescription: String {
    let completed = activities.filter { $0.completed }.count
    let todayStatus = activities.first { $0.isToday }?.completed == true
      ? "completed"
      : "not yet completed"
    return "Week progress: \(completed) of 7 days completed. Today is \(todayStatus)."
  }
}

// MARK: - Preview

#Preview("Weekly Tracker - Mixed Progress") {
  let activities = (0..<7).reversed().map { daysAgo -> DailyActivityItem in
    let date = Calendar.current.date(byAdding: .day, value: -daysAgo, to: Date()) ?? Date()
    // Complete days: 0 (6 days ago), 2 (4 days ago), 3 (3 days ago), 5 (1 day ago)
    let completed = [0, 2, 3, 5].contains(6 - daysAgo)
    return DailyActivityItem(date: date, completed: completed, xpEarned: completed ? 100 : 0)
  }

  WeeklyTrackerView(activities: activities)
    .padding()
    .background(Color.rizqBackground)
}

#Preview("Weekly Tracker - Perfect Week") {
  let activities = (0..<7).reversed().map { daysAgo -> DailyActivityItem in
    let date = Calendar.current.date(byAdding: .day, value: -daysAgo, to: Date()) ?? Date()
    return DailyActivityItem(date: date, completed: true, xpEarned: 100)
  }

  WeeklyTrackerView(activities: activities)
    .padding()
    .background(Color.rizqBackground)
}

#Preview("Weekly Tracker - New User") {
  let activities = (0..<7).reversed().map { daysAgo -> DailyActivityItem in
    let date = Calendar.current.date(byAdding: .day, value: -daysAgo, to: Date()) ?? Date()
    return DailyActivityItem(date: date, completed: false)
  }

  WeeklyTrackerView(activities: activities)
    .padding()
    .background(Color.rizqBackground)
}
