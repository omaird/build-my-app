import SwiftUI
import RIZQKit

// MARK: - Week Calendar View

/// Weekly activity calendar showing this week's progress
/// Matches the web WeekCalendar.tsx component
struct WeekCalendarView: View {
  let activities: [DailyActivityItem]

  @State private var animatedDots: Set<Int> = []
  @State private var animatedDays: Set<Int> = []

  private let dayLabels = ["S", "M", "T", "W", "T", "F", "S"]

  private var completedCount: Int {
    activities.filter { $0.completed }.count
  }

  var body: some View {
    VStack(spacing: RIZQSpacing.md) {
      // Header
      headerRow

      // Calendar grid
      calendarGrid
    }
    .padding(RIZQSpacing.lg)
    .background(Color.rizqCard)
    .clipShape(RoundedRectangle(cornerRadius: RIZQRadius.islamic))
    .overlay(
      // Subtle pattern overlay
      RoundedRectangle(cornerRadius: RIZQRadius.islamic)
        .stroke(Color.rizqBorder, lineWidth: 1)
    )
    .shadowSoft()
    .onAppear {
      animateDotsSequentially()
      animateDaysSequentially()
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

      HStack(spacing: RIZQSpacing.sm) {
        Text("\(completedCount)/7 days")
          .font(.rizqSans(.caption))
          .foregroundStyle(Color.rizqTextSecondary)

        // Progress dots
        HStack(spacing: 4) {
          ForEach(0..<7, id: \.self) { index in
            Circle()
              .fill(index < completedCount ? Color.rizqPrimary : Color.rizqMuted.opacity(0.4))
              .frame(width: 6, height: 6)
              .scaleEffect(animatedDots.contains(index) ? 1 : 0)
              .animation(
                .spring(response: 0.3, dampingFraction: 0.6)
                  .delay(0.05 * Double(index)),
                value: animatedDots.contains(index)
              )
          }
        }
      }
    }
  }

  // MARK: - Calendar Grid

  private var calendarGrid: some View {
    HStack(spacing: 0) {
      ForEach(Array(activities.enumerated()), id: \.offset) { index, item in
        dayColumn(item: item, index: index)
          .frame(maxWidth: .infinity)
      }
    }
  }

  private func dayColumn(item: DailyActivityItem, index: Int) -> some View {
    VStack(spacing: RIZQSpacing.sm) {
      // Day label
      Text(item.dayLabel)
        .font(.rizqSansSemiBold(.caption2))
        .foregroundStyle(item.isToday ? Color.rizqPrimary : Color.rizqTextSecondary)
        .textCase(.uppercase)
        .tracking(0.5)

      // Day circle
      ZStack {
        Circle()
          .fill(dayCircleBackground(for: item))
          .frame(width: 36, height: 36)
          .shadow(color: item.completed ? Color.rizqPrimary.opacity(0.3) : .clear, radius: 4)

        if item.completed {
          // Checkmark
          Image(systemName: "checkmark")
            .font(.system(size: 14, weight: .bold))
            .foregroundStyle(.white)
            .scaleEffect(animatedDays.contains(index) ? 1 : 0)
            .animation(
              .spring(response: 0.4, dampingFraction: 0.6)
                .delay(0.05 * Double(index)),
              value: animatedDays.contains(index)
            )
        } else if item.isToday {
          // Pulsing border for today
          Circle()
            .stroke(Color.rizqPrimary, lineWidth: 2)
            .frame(width: 36, height: 36)
            .modifier(PulsingModifier())
        } else {
          // Empty dot
          Circle()
            .fill(Color.rizqMuted.opacity(0.2))
            .frame(width: 6, height: 6)
        }
      }

      // XP earned indicator
      if item.xpEarned > 0 {
        Text("+\(item.xpEarned)")
          .font(.rizqMono(.caption2))
          .foregroundStyle(Color.rizqPrimary)
          .opacity(animatedDays.contains(index) ? 1 : 0)
          .offset(y: animatedDays.contains(index) ? 0 : -5)
          .animation(
            .easeOut(duration: 0.3)
              .delay(0.3 + 0.05 * Double(index)),
            value: animatedDays.contains(index)
          )
      } else {
        // Placeholder to maintain layout
        Text(" ")
          .font(.rizqMono(.caption2))
      }
    }
  }

  private func dayCircleBackground(for item: DailyActivityItem) -> Color {
    if item.completed {
      return Color.rizqPrimary
    } else if item.isToday {
      return Color.rizqMuted.opacity(0.3)
    } else {
      return Color.rizqMuted.opacity(0.15)
    }
  }

  // MARK: - Animation Helpers

  private func animateDotsSequentially() {
    for i in 0..<7 {
      DispatchQueue.main.asyncAfter(deadline: .now() + 0.3 + 0.05 * Double(i)) {
        animatedDots.insert(i)
      }
    }
  }

  private func animateDaysSequentially() {
    for i in 0..<activities.count {
      DispatchQueue.main.asyncAfter(deadline: .now() + 0.1 + 0.05 * Double(i)) {
        animatedDays.insert(i)
      }
    }
  }
}

// MARK: - Pulsing Modifier

/// Creates a pulsing animation effect for the "today" indicator
private struct PulsingModifier: ViewModifier {
  @State private var isPulsing = false

  func body(content: Content) -> some View {
    content
      .scaleEffect(isPulsing ? 1.15 : 1.0)
      .opacity(isPulsing ? 0.5 : 1.0)
      .onAppear {
        withAnimation(
          Animation.easeInOut(duration: 1.0)
            .repeatForever(autoreverses: true)
        ) {
          isPulsing = true
        }
      }
  }
}

// MARK: - Preview
// Note: DailyActivityItem is now in RIZQKit/Models/DailyActivity.swift

#Preview("Week Calendar - Active Week") {
  let activities = [
    DailyActivityItem(
      date: Calendar.current.date(byAdding: .day, value: -6, to: Date())!,
      completed: true,
      xpEarned: 125
    ),
    DailyActivityItem(
      date: Calendar.current.date(byAdding: .day, value: -5, to: Date())!,
      completed: true,
      xpEarned: 80
    ),
    DailyActivityItem(
      date: Calendar.current.date(byAdding: .day, value: -4, to: Date())!,
      completed: false
    ),
    DailyActivityItem(
      date: Calendar.current.date(byAdding: .day, value: -3, to: Date())!,
      completed: true,
      xpEarned: 160
    ),
    DailyActivityItem(
      date: Calendar.current.date(byAdding: .day, value: -2, to: Date())!,
      completed: false
    ),
    DailyActivityItem(
      date: Calendar.current.date(byAdding: .day, value: -1, to: Date())!,
      completed: true,
      xpEarned: 95
    ),
    DailyActivityItem(
      date: Date(),
      completed: false
    ),
  ]

  WeekCalendarView(activities: activities)
    .padding()
    .background(Color.rizqBackground)
}

#Preview("Week Calendar - New User") {
  let activities = (0..<7).reversed().map { daysAgo in
    DailyActivityItem(
      date: Calendar.current.date(byAdding: .day, value: -daysAgo, to: Date())!,
      completed: false
    )
  }

  WeekCalendarView(activities: activities)
    .padding()
    .background(Color.rizqBackground)
}
