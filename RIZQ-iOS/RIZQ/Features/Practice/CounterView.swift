import SwiftUI
import RIZQKit

/// Circular counter view with progress ring and tap interaction
struct CounterView: View {
  let currentCount: Int
  let targetCount: Int
  let isCompleted: Bool
  let onTap: () -> Void

  private var progress: Double {
    guard targetCount > 0 else { return 0 }
    return min(Double(currentCount) / Double(targetCount), 1.0)
  }

  private let size: CGFloat = 100
  private let lineWidth: CGFloat = 6

  var body: some View {
    ZStack {
      if isCompleted {
        completedView
      } else {
        counterView
      }
    }
    .contentShape(Circle())
    .onTapGesture {
      if !isCompleted {
        // Prepare haptic feedback (ready for Phase 6)
        let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
        impactFeedback.impactOccurred()

        onTap()
      }
    }
  }

  // MARK: - Counter View

  private var counterView: some View {
    ZStack {
      // Background circle
      Circle()
        .stroke(
          Color.rizqMuted.opacity(0.3),
          lineWidth: lineWidth
        )
        .frame(width: size, height: size)

      // Progress circle
      Circle()
        .trim(from: 0, to: progress)
        .stroke(
          LinearGradient.rizqPrimaryGradient,
          style: StrokeStyle(
            lineWidth: lineWidth,
            lineCap: .round
          )
        )
        .frame(width: size, height: size)
        .rotationEffect(.degrees(-90))
        .animation(.easeInOut(duration: 0.3), value: progress)

      // Center content
      VStack(spacing: 4) {
        Text("\(currentCount)")
          .font(.rizqMonoMedium(.largeTitle))
          .foregroundStyle(Color.rizqText)
          .contentTransition(.numericText())
          .animation(.spring(response: 0.3), value: currentCount)

        Text("of \(targetCount)")
          .font(.rizqSans(.caption))
          .foregroundStyle(Color.rizqTextSecondary)
      }
    }
    .scaleEffect(1.0)
    .animation(.spring(response: 0.2, dampingFraction: 0.6), value: currentCount)
  }

  // MARK: - Completed View

  private var completedView: some View {
    ZStack {
      // Glowing background
      Circle()
        .fill(LinearGradient.rizqPrimaryGradient)
        .frame(width: size, height: size)
        .shadowGlowPrimary()

      // Checkmark
      Image(systemName: "checkmark")
        .font(.system(size: 40, weight: .bold))
        .foregroundStyle(.white)
    }
  }
}

// MARK: - Previews

#Preview("Counter - In Progress") {
  VStack(spacing: 40) {
    CounterView(
      currentCount: 0,
      targetCount: 3,
      isCompleted: false,
      onTap: {}
    )

    CounterView(
      currentCount: 2,
      targetCount: 3,
      isCompleted: false,
      onTap: {}
    )
  }
  .padding()
  .rizqPageBackground()
}

#Preview("Counter - Completed") {
  CounterView(
    currentCount: 3,
    targetCount: 3,
    isCompleted: true,
    onTap: {}
  )
  .padding()
  .rizqPageBackground()
}
