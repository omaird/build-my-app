import SwiftUI
import RIZQKit

/// An animated progress bar for habit completion tracking
struct HabitProgressBar: View {
  let progress: Double
  let color: Color
  var height: CGFloat = 8
  var backgroundColor: Color = Color.rizqMuted.opacity(0.3)
  var animationDuration: Double = 0.5

  @State private var animatedProgress: Double = 0

  var body: some View {
    GeometryReader { geometry in
      ZStack(alignment: .leading) {
        // Background Track
        Capsule()
          .fill(backgroundColor)

        // Progress Fill
        Capsule()
          .fill(
            LinearGradient(
              colors: [color.opacity(0.8), color],
              startPoint: .leading,
              endPoint: .trailing
            )
          )
          .frame(width: max(0, geometry.size.width * animatedProgress))
          .animation(.easeOut(duration: animationDuration), value: animatedProgress)
      }
    }
    .frame(height: height)
    .clipShape(Capsule())
    .onAppear {
      animatedProgress = progress
    }
    .onChange(of: progress) { _, newValue in
      animatedProgress = newValue
    }
  }
}

/// A circular progress indicator for XP or level progression
struct CircularProgressBar: View {
  let progress: Double
  let color: Color
  var lineWidth: CGFloat = 6
  var size: CGFloat = 60

  @State private var animatedProgress: Double = 0

  var body: some View {
    ZStack {
      // Background Circle
      Circle()
        .stroke(
          Color.rizqMuted.opacity(0.3),
          lineWidth: lineWidth
        )

      // Progress Arc
      Circle()
        .trim(from: 0, to: animatedProgress)
        .stroke(
          color,
          style: StrokeStyle(
            lineWidth: lineWidth,
            lineCap: .round
          )
        )
        .rotationEffect(.degrees(-90))
        .animation(.easeOut(duration: 0.6), value: animatedProgress)
    }
    .frame(width: size, height: size)
    .onAppear {
      animatedProgress = progress
    }
    .onChange(of: progress) { _, newValue in
      animatedProgress = newValue
    }
  }
}

/// A compact progress indicator showing completion count
struct CompactProgressIndicator: View {
  let completed: Int
  let total: Int
  let color: Color

  private var percentage: Double {
    guard total > 0 else { return 0 }
    return Double(completed) / Double(total)
  }

  var body: some View {
    HStack(spacing: 8) {
      HabitProgressBar(
        progress: percentage,
        color: color,
        height: 4
      )
      .frame(width: 40)

      Text("\(completed)/\(total)")
        .font(.rizqMono(.caption2))
        .foregroundStyle(Color.rizqTextSecondary)
    }
  }
}

#Preview {
  VStack(spacing: 32) {
    // Linear Progress Bars
    VStack(alignment: .leading, spacing: 16) {
      Text("Linear Progress Bars")
        .font(.rizqDisplayMedium(.headline))

      HabitProgressBar(progress: 0.25, color: .badgeMorning)
        .frame(height: 8)

      HabitProgressBar(progress: 0.5, color: .tealMuted)
        .frame(height: 8)

      HabitProgressBar(progress: 0.75, color: .badgeEvening)
        .frame(height: 8)

      HabitProgressBar(progress: 1.0, color: .tealSuccess)
        .frame(height: 8)
    }

    // Circular Progress
    VStack(spacing: 16) {
      Text("Circular Progress")
        .font(.rizqDisplayMedium(.headline))

      HStack(spacing: 24) {
        CircularProgressBar(progress: 0.25, color: .badgeMorning)
        CircularProgressBar(progress: 0.5, color: .rizqPrimary)
        CircularProgressBar(progress: 0.75, color: .tealSuccess)
      }
    }

    // Compact Indicators
    VStack(spacing: 16) {
      Text("Compact Indicators")
        .font(.rizqDisplayMedium(.headline))

      HStack(spacing: 24) {
        CompactProgressIndicator(completed: 1, total: 4, color: .badgeMorning)
        CompactProgressIndicator(completed: 2, total: 2, color: .tealSuccess)
        CompactProgressIndicator(completed: 0, total: 3, color: .badgeEvening)
      }
    }
  }
  .padding()
  .background(Color.rizqBackground)
}
