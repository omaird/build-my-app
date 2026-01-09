import SwiftUI

/// A ripple effect that emanates from touch points
/// Matches the React RippleEffect component with expanding circle animation
struct RippleEffect: ViewModifier {
  var rippleColor: Color = Color(hex: "D4A574").opacity(0.35) // Primary sand color
  var isDisabled: Bool = false

  @State private var ripples: [Ripple] = []

  struct Ripple: Identifiable {
    let id = UUID()
    let location: CGPoint
    let startTime: Date
  }

  func body(content: Content) -> some View {
    content
      .overlay(
        GeometryReader { geometry in
          ZStack {
            ForEach(ripples) { ripple in
              RippleCircle(color: rippleColor)
                .position(ripple.location)
            }
          }
          .allowsHitTesting(false)
        }
      )
      .contentShape(Rectangle())
      .simultaneousGesture(
        DragGesture(minimumDistance: 0)
          .onEnded { value in
            guard !isDisabled else { return }
            addRipple(at: value.location)
          }
      )
  }

  private func addRipple(at location: CGPoint) {
    let ripple = Ripple(location: location, startTime: Date())
    ripples.append(ripple)

    // Remove ripple after animation
    DispatchQueue.main.asyncAfter(deadline: .now() + 0.7) {
      ripples.removeAll { $0.id == ripple.id }
    }
  }
}

// MARK: - Ripple Circle
private struct RippleCircle: View {
  let color: Color

  @State private var scale: CGFloat = 0
  @State private var opacity: Double = 0.6

  var body: some View {
    Circle()
      .fill(color)
      .frame(width: 300, height: 300)
      .scaleEffect(scale)
      .opacity(opacity)
      .onAppear {
        withAnimation(.easeOut(duration: 0.6)) {
          scale = 1
          opacity = 0
        }
      }
  }
}

// MARK: - View Extension
extension View {
  /// Adds a ripple effect on tap
  func rippleEffect(
    color: Color = Color(hex: "D4A574").opacity(0.35),
    isDisabled: Bool = false
  ) -> some View {
    modifier(RippleEffect(rippleColor: color, isDisabled: isDisabled))
  }
}

// MARK: - Tap Scale Effect
/// A simple scale effect on tap, commonly used for buttons
struct TapScaleEffect: ViewModifier {
  var scale: CGFloat = 0.95

  @State private var isPressed = false

  func body(content: Content) -> some View {
    content
      .scaleEffect(isPressed ? scale : 1)
      .animation(.spring(response: 0.2, dampingFraction: 0.6), value: isPressed)
      .simultaneousGesture(
        DragGesture(minimumDistance: 0)
          .onChanged { _ in isPressed = true }
          .onEnded { _ in isPressed = false }
      )
  }
}

extension View {
  /// Adds a scale effect on tap
  func tapScale(_ scale: CGFloat = 0.95) -> some View {
    modifier(TapScaleEffect(scale: scale))
  }
}

// MARK: - Hover Lift Effect
/// A lift effect for cards on hover/press
struct HoverLiftEffect: ViewModifier {
  var lift: CGFloat = -2

  @State private var isHovered = false

  func body(content: Content) -> some View {
    content
      .offset(y: isHovered ? lift : 0)
      .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isHovered)
      .simultaneousGesture(
        DragGesture(minimumDistance: 0)
          .onChanged { _ in isHovered = true }
          .onEnded { _ in isHovered = false }
      )
  }
}

extension View {
  /// Adds a lift effect on hover/press
  func hoverLift(_ amount: CGFloat = -2) -> some View {
    modifier(HoverLiftEffect(lift: amount))
  }
}

// MARK: - Pulse Effect
/// A pulsing glow effect for attention-grabbing elements
struct PulseEffect: ViewModifier {
  var color: Color = .rizqPrimary
  var duration: TimeInterval = 2
  var isActive: Bool = true

  @State private var isPulsing = false

  func body(content: Content) -> some View {
    content
      .overlay(
        content
          .blur(radius: 8)
          .opacity(isPulsing ? 0.6 : 0.2)
          .foregroundStyle(color)
          .allowsHitTesting(false)
      )
      .onAppear {
        guard isActive else { return }
        startPulsing()
      }
      .onChange(of: isActive) { _, newValue in
        if newValue {
          startPulsing()
        } else {
          isPulsing = false
        }
      }
  }

  private func startPulsing() {
    withAnimation(
      .easeInOut(duration: duration / 2)
        .repeatForever(autoreverses: true)
    ) {
      isPulsing = true
    }
  }
}

extension View {
  /// Adds a pulsing glow effect
  func pulseGlow(color: Color = .rizqPrimary, duration: TimeInterval = 2, isActive: Bool = true) -> some View {
    modifier(PulseEffect(color: color, duration: duration, isActive: isActive))
  }
}

// MARK: - Preview
#Preview("Ripple Effect") {
  VStack(spacing: 20) {
    RoundedRectangle(cornerRadius: 16)
      .fill(Color.rizqPrimary)
      .frame(height: 100)
      .overlay(
        Text("Tap me!")
          .foregroundStyle(.white)
      )
      .rippleEffect()
      .clipShape(RoundedRectangle(cornerRadius: 16))

    Text("Tap the card above to see the ripple effect")
      .font(.caption)
      .foregroundStyle(.secondary)
  }
  .padding()
}

#Preview("Tap Scale") {
  VStack(spacing: 20) {
    Button("Tap Scale Button") {}
      .buttonStyle(.borderedProminent)
      .tapScale()

    Text("Press and hold to see scale effect")
      .font(.caption)
      .foregroundStyle(.secondary)
  }
}

#Preview("Hover Lift") {
  VStack(spacing: 20) {
    RoundedRectangle(cornerRadius: 16)
      .fill(Color.rizqCard)
      .frame(height: 100)
      .shadowSoft()
      .overlay(
        Text("Press to lift")
      )
      .hoverLift()

    Text("Press and hold to see lift effect")
      .font(.caption)
      .foregroundStyle(.secondary)
  }
  .padding()
}

#Preview("Pulse Glow") {
  VStack {
    Image(systemName: "star.fill")
      .font(.system(size: 50))
      .foregroundStyle(Color.streakGlow)
      .pulseGlow(color: .streakGlow)
  }
}
