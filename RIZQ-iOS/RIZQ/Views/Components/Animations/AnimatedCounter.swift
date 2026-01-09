import SwiftUI

/// An animated circular counter with progress ring
/// Matches the React AnimatedCounter component with spring physics and tap animations
struct AnimatedCounter: View {
  var value: Int
  var max: Int = 33
  var size: CounterSize = .lg
  var showProgress: Bool = true
  var isCompleted: Bool = false
  var onTap: (() -> Void)?

  @State private var displayValue: Int = 0
  @State private var isAnimating = false
  @State private var animatedProgress: CGFloat = 0
  @State private var rippleScale: CGFloat = 1
  @State private var rippleOpacity: Double = 0

  enum CounterSize {
    case sm, md, lg, xl

    var config: (width: CGFloat, fontSize: Font, strokeWidth: CGFloat) {
      switch self {
      case .sm: return (64, .system(size: 24, weight: .bold, design: .monospaced), 3)
      case .md: return (96, .system(size: 32, weight: .bold, design: .monospaced), 4)
      case .lg: return (120, .system(size: 40, weight: .bold, design: .monospaced), 5)
      case .xl: return (160, .system(size: 48, weight: .bold, design: .monospaced), 6)
      }
    }
  }

  private var progress: CGFloat {
    CGFloat(min(value, max)) / CGFloat(max)
  }

  private var config: (width: CGFloat, fontSize: Font, strokeWidth: CGFloat) {
    size.config
  }

  var body: some View {
    ZStack {
      // Background track
      Circle()
        .stroke(Color.secondary.opacity(0.2), lineWidth: config.strokeWidth)
        .frame(width: config.width, height: config.width)

      // Progress ring
      if showProgress {
        Circle()
          .trim(from: 0, to: animatedProgress)
          .stroke(
            LinearGradient(
              colors: [Color.rizqPrimary, Color.sandDeep],
              startPoint: .topLeading,
              endPoint: .bottomTrailing
            ),
            style: StrokeStyle(
              lineWidth: config.strokeWidth,
              lineCap: .round
            )
          )
          .frame(width: config.width - config.strokeWidth, height: config.width - config.strokeWidth)
          .rotationEffect(.degrees(-90))
      }

      // Inner circle with counter
      ZStack {
        Circle()
          .fill(isCompleted ? Color.rizqPrimary.opacity(0.1) : Color.rizqCard)
          .overlay(
            Circle()
              .stroke(
                isCompleted ? Color.rizqPrimary.opacity(0.3) : Color.rizqPrimary.opacity(0.2),
                lineWidth: 2
              )
          )
          .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)

        // Counter value with animation
        Text("\(displayValue)")
          .font(config.fontSize)
          .foregroundStyle(Color.rizqPrimary)
          .contentTransition(.numericText(value: Double(displayValue)))
          .scaleEffect(isAnimating ? 1.15 : 1)
      }
      .frame(width: config.width - config.strokeWidth * 4, height: config.width - config.strokeWidth * 4)

      // Ripple effect
      Circle()
        .stroke(Color.rizqPrimary.opacity(0.4), lineWidth: 2)
        .frame(width: config.width, height: config.width)
        .scaleEffect(rippleScale)
        .opacity(rippleOpacity)
    }
    .frame(width: config.width, height: config.width)
    .contentShape(Circle())
    .scaleEffect(isAnimating ? 0.95 : 1)
    .onTapGesture {
      onTap?()
    }
    .onChange(of: value) { oldValue, newValue in
      animateValueChange(from: oldValue, to: newValue)
    }
    .onAppear {
      displayValue = value
      animatedProgress = progress
    }
  }

  private func animateValueChange(from oldValue: Int, to newValue: Int) {
    // Trigger animations
    isAnimating = true

    // Ripple effect
    rippleScale = 1
    rippleOpacity = 0.6
    withAnimation(.easeOut(duration: 0.4)) {
      rippleScale = 1.3
      rippleOpacity = 0
    }

    // Scale bounce
    withAnimation(.spring(response: 0.3, dampingFraction: 0.5)) {
      // Scale handled by isAnimating state
    }

    // Update display value with animation
    withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
      displayValue = newValue
    }

    // Update progress ring
    withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
      animatedProgress = CGFloat(min(newValue, max)) / CGFloat(max)
    }

    // Reset animation state
    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
      withAnimation(.spring(response: 0.2, dampingFraction: 0.7)) {
        isAnimating = false
      }
    }
  }
}

// MARK: - Number Pop
/// Simple number counter with pop animation for XP displays
struct NumberPop: View {
  var value: Int
  var prefix: String = ""
  var suffix: String = ""

  @State private var displayValue: Int = 0
  @State private var isPopping = false

  var body: some View {
    Text("\(prefix)\(displayValue)\(suffix)")
      .font(.system(.body, design: .monospaced))
      .monospacedDigit()
      .scaleEffect(isPopping ? 1.2 : 1)
      .onChange(of: value) { _, newValue in
        if newValue != displayValue {
          isPopping = true

          withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
            displayValue = newValue
          }

          DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            withAnimation(.spring(response: 0.2, dampingFraction: 0.7)) {
              isPopping = false
            }
          }
        }
      }
      .onAppear {
        displayValue = value
      }
  }
}

// MARK: - XP Earned Badge
/// Animated badge showing earned XP with pop-in effect
struct XpEarnedBadge: View {
  var amount: Int
  var isVisible: Bool

  @State private var scale: CGFloat = 0
  @State private var opacity: Double = 0
  @State private var yOffset: CGFloat = 10

  var body: some View {
    HStack(spacing: 4) {
      Image(systemName: "star.fill")
        .font(.system(size: 12))
        .foregroundStyle(Color.streakGlow)

      Text("+\(amount) XP")
        .font(.rizqSansSemiBold(.caption))
        .foregroundStyle(Color.rizqPrimary)
    }
    .padding(.horizontal, 12)
    .padding(.vertical, 6)
    .background(
      Capsule()
        .fill(Color.goldSoft.opacity(0.3))
        .overlay(
          Capsule()
            .stroke(Color.rizqPrimary.opacity(0.3), lineWidth: 1)
        )
    )
    .scaleEffect(scale)
    .opacity(opacity)
    .offset(y: yOffset)
    .onChange(of: isVisible) { _, newValue in
      if newValue {
        animateIn()
      } else {
        animateOut()
      }
    }
  }

  private func animateIn() {
    withAnimation(.spring(response: 0.4, dampingFraction: 0.6)) {
      scale = 1
      opacity = 1
      yOffset = 0
    }
  }

  private func animateOut() {
    withAnimation(.easeIn(duration: 0.2)) {
      scale = 0.8
      opacity = 0
      yOffset = -10
    }
  }
}

// MARK: - Preview
#Preview("Animated Counter") {
  struct PreviewWrapper: View {
    @State private var count = 0

    var body: some View {
      VStack(spacing: 40) {
        AnimatedCounter(value: count, max: 33) {
          count += 1
        }

        Text("Tap the counter to increment")
          .font(.caption)
          .foregroundStyle(.secondary)

        Button("Reset") {
          count = 0
        }
      }
      .padding()
    }
  }

  return PreviewWrapper()
}

#Preview("Number Pop") {
  struct PreviewWrapper: View {
    @State private var xp = 100

    var body: some View {
      VStack(spacing: 20) {
        NumberPop(value: xp, prefix: "", suffix: " XP")
          .font(.title)

        Button("Add 10 XP") {
          xp += 10
        }
      }
    }
  }

  return PreviewWrapper()
}
