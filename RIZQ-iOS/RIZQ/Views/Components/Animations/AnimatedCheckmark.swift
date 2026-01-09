import SwiftUI

/// An animated checkmark with a glow ring effect
/// Matches the React AnimatedCheckmark component with spring animation and path drawing
struct AnimatedCheckmark: View {
  var isVisible: Bool
  var size: CGFloat = 64
  var strokeWidth: CGFloat = 4
  var delay: TimeInterval = 0.2
  var onComplete: (() -> Void)?

  @State private var scale: CGFloat = 0
  @State private var opacity: Double = 0
  @State private var checkmarkProgress: CGFloat = 0
  @State private var glowScale: CGFloat = 0.8
  @State private var glowOpacity: Double = 0

  var body: some View {
    ZStack {
      // Outer glow ring
      Circle()
        .fill(Color.rizqPrimary.opacity(0.2))
        .frame(width: size * 1.3, height: size * 1.3)
        .scaleEffect(glowScale)
        .opacity(glowOpacity)

      // Main circle with gradient
      Circle()
        .fill(
          LinearGradient(
            colors: [Color.rizqPrimary, Color.sandDeep],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
          )
        )
        .frame(width: size, height: size)
        .shadow(color: Color.rizqPrimary.opacity(0.4), radius: 10, x: 0, y: 4)

      // Checkmark path
      CheckmarkPath()
        .trim(from: 0, to: checkmarkProgress)
        .stroke(
          Color.white,
          style: StrokeStyle(
            lineWidth: strokeWidth,
            lineCap: .round,
            lineJoin: .round
          )
        )
        .frame(width: size * 0.5, height: size * 0.5)
    }
    .scaleEffect(scale)
    .opacity(opacity)
    .onChange(of: isVisible) { _, newValue in
      if newValue {
        animateIn()
      } else {
        animateOut()
      }
    }
    .onAppear {
      if isVisible {
        animateIn()
      }
    }
  }

  private func animateIn() {
    // Main container spring animation
    withAnimation(
      .spring(response: 0.4, dampingFraction: 0.6)
        .delay(delay)
    ) {
      scale = 1
      opacity = 1
    }

    // Glow ring animation
    withAnimation(
      .easeOut(duration: 0.8)
        .delay(delay + 0.1)
    ) {
      glowScale = 1.3
    }

    withAnimation(
      .easeInOut(duration: 0.4)
        .delay(delay + 0.1)
    ) {
      glowOpacity = 0.5
    }

    withAnimation(
      .easeInOut(duration: 0.4)
        .delay(delay + 0.5)
    ) {
      glowOpacity = 0
    }

    // Checkmark drawing animation
    withAnimation(
      .easeOut(duration: 0.4)
        .delay(delay + 0.3)
    ) {
      checkmarkProgress = 1
    }

    // Completion callback
    DispatchQueue.main.asyncAfter(deadline: .now() + delay + 0.7) {
      onComplete?()
    }
  }

  private func animateOut() {
    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
      scale = 0
      opacity = 0
      checkmarkProgress = 0
      glowOpacity = 0
      glowScale = 0.8
    }
  }
}

// MARK: - Checkmark Path
struct CheckmarkPath: Shape {
  func path(in rect: CGRect) -> Path {
    var path = Path()
    let width = rect.width
    let height = rect.height

    // Draw checkmark: M5 13l4 4L19 7 (normalized to rect)
    path.move(to: CGPoint(x: width * 0.2, y: height * 0.55))
    path.addLine(to: CGPoint(x: width * 0.4, y: height * 0.75))
    path.addLine(to: CGPoint(x: width * 0.8, y: height * 0.3))

    return path
  }
}

// MARK: - Inline Checkmark
/// Smaller inline checkmark for lists
struct InlineCheckmark: View {
  var isChecked: Bool
  var size: CGFloat = 20

  @State private var scale: CGFloat = 1
  @State private var checkmarkScale: CGFloat = 0

  var body: some View {
    ZStack {
      Circle()
        .fill(isChecked ? Color.rizqPrimary : Color.clear)
        .overlay(
          Circle()
            .stroke(
              isChecked ? Color.rizqPrimary : Color.gray.opacity(0.3),
              lineWidth: 2
            )
        )
        .frame(width: size, height: size)

      if isChecked {
        CheckmarkPath()
          .stroke(
            Color.white,
            style: StrokeStyle(lineWidth: 2, lineCap: .round, lineJoin: .round)
          )
          .frame(width: size * 0.5, height: size * 0.5)
          .scaleEffect(checkmarkScale)
      }
    }
    .scaleEffect(scale)
    .onChange(of: isChecked) { _, newValue in
      if newValue {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
          scale = 1.2
        }
        withAnimation(.spring(response: 0.3, dampingFraction: 0.6).delay(0.1)) {
          scale = 1
          checkmarkScale = 1
        }
      } else {
        withAnimation(.spring(response: 0.2, dampingFraction: 0.8)) {
          checkmarkScale = 0
        }
      }
    }
    .onAppear {
      checkmarkScale = isChecked ? 1 : 0
    }
  }
}

// MARK: - Preview
#Preview("Animated Checkmark") {
  struct PreviewWrapper: View {
    @State private var isVisible = false

    var body: some View {
      VStack(spacing: 40) {
        AnimatedCheckmark(isVisible: isVisible, size: 80)

        Button(isVisible ? "Hide" : "Show") {
          isVisible.toggle()
        }
        .buttonStyle(.borderedProminent)
      }
      .padding()
    }
  }

  return PreviewWrapper()
}

#Preview("Inline Checkmark") {
  struct PreviewWrapper: View {
    @State private var isChecked = false

    var body: some View {
      HStack {
        InlineCheckmark(isChecked: isChecked)

        Text("Tap to toggle")

        Spacer()
      }
      .padding()
      .onTapGesture {
        isChecked.toggle()
      }
    }
  }

  return PreviewWrapper()
}
