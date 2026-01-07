import SwiftUI
import RIZQKit

/// Full-screen celebration overlay shown when dua is completed
struct CelebrationOverlayView: View {
  let isVisible: Bool
  let title: String
  let subtitle: String
  let xpEarned: Int
  let onDismiss: () -> Void

  @State private var showCheckmark = false
  @State private var showContent = false
  @State private var showXpBadge = false
  @State private var showHint = false

  var body: some View {
    if isVisible {
      ZStack {
        // Background overlay
        backgroundOverlay

        // Content
        VStack(spacing: RIZQSpacing.xxl) {
          Spacer()

          // Animated checkmark
          animatedCheckmark

          // Title and subtitle
          titleSection

          // XP Badge
          xpBadge

          Spacer()

          // Tap to continue hint
          tapHint
        }
        .padding(RIZQSpacing.xxl)
      }
      .transition(.opacity)
      .onAppear {
        startAnimations()
      }
      .onTapGesture {
        onDismiss()
      }
    }
  }

  // MARK: - Background

  private var backgroundOverlay: some View {
    ZStack {
      // Gradient background
      LinearGradient(
        colors: [
          Color.creamWarm.opacity(0.98),
          Color.cream.opacity(0.95),
          Color.sandLight.opacity(0.3)
        ],
        startPoint: .top,
        endPoint: .bottom
      )
      .ignoresSafeArea()

      // Celebration particles effect
      celebrationParticles
    }
  }

  // MARK: - Celebration Particles

  private var celebrationParticles: some View {
    GeometryReader { geometry in
      ForEach(0..<20, id: \.self) { index in
        ParticleView(
          size: CGFloat.random(in: 4...12),
          color: particleColors[index % particleColors.count],
          delay: Double(index) * 0.05
        )
        .position(
          x: CGFloat.random(in: 0...geometry.size.width),
          y: CGFloat.random(in: 0...geometry.size.height)
        )
      }
    }
    .opacity(showContent ? 1 : 0)
  }

  private var particleColors: [Color] {
    [.goldBright, .goldSoft, .sandWarm, .sandLight, .rizqPrimary]
  }

  // MARK: - Animated Checkmark

  private var animatedCheckmark: some View {
    ZStack {
      // Outer glow ring
      Circle()
        .fill(
          RadialGradient(
            colors: [Color.rizqPrimary.opacity(0.3), Color.clear],
            center: .center,
            startRadius: 40,
            endRadius: 80
          )
        )
        .frame(width: 160, height: 160)
        .scaleEffect(showCheckmark ? 1.0 : 0.5)
        .opacity(showCheckmark ? 1 : 0)

      // Main circle
      Circle()
        .fill(LinearGradient.rizqPrimaryGradient)
        .frame(width: 100, height: 100)
        .shadowGlowPrimary()
        .scaleEffect(showCheckmark ? 1.0 : 0.3)

      // Checkmark
      Image(systemName: "checkmark")
        .font(.system(size: 44, weight: .bold))
        .foregroundStyle(.white)
        .scaleEffect(showCheckmark ? 1.0 : 0.0)
    }
    .animation(.spring(response: 0.5, dampingFraction: 0.6), value: showCheckmark)
  }

  // MARK: - Title Section

  private var titleSection: some View {
    VStack(spacing: RIZQSpacing.sm) {
      Text(title)
        .font(.rizqDisplayBold(.largeTitle))
        .foregroundStyle(Color.mocha)
        .opacity(showContent ? 1 : 0)
        .offset(y: showContent ? 0 : 10)

      Text(subtitle)
        .font(.rizqSans(.title3))
        .foregroundStyle(Color.rizqTextSecondary)
        .opacity(showContent ? 1 : 0)
        .offset(y: showContent ? 0 : 10)
    }
    .animation(.easeOut(duration: 0.4).delay(0.3), value: showContent)
  }

  // MARK: - XP Badge

  @ViewBuilder
  private var xpBadge: some View {
    if xpEarned > 0 {
      HStack(spacing: RIZQSpacing.sm) {
        Text("\u{2728}") // Sparkles emoji
          .font(.title2)

        Text("+\(xpEarned) XP")
          .font(.rizqDisplaySemiBold(.title2))
          .foregroundStyle(
            LinearGradient(
              colors: [.sandWarm, .sandDeep],
              startPoint: .leading,
              endPoint: .trailing
            )
          )
      }
      .padding(.horizontal, RIZQSpacing.xl)
      .padding(.vertical, RIZQSpacing.md)
      .background(
        Capsule()
          .fill(.white.opacity(0.9))
          .shadow(color: Color.goldSoft.opacity(0.4), radius: 12, y: 4)
      )
      .overlay(
        Capsule()
          .stroke(Color.goldSoft.opacity(0.5), lineWidth: 1)
      )
      .scaleEffect(showXpBadge ? 1.0 : 0.5)
      .opacity(showXpBadge ? 1 : 0)
      .animation(.spring(response: 0.5, dampingFraction: 0.7).delay(0.5), value: showXpBadge)
    }
  }

  // MARK: - Tap Hint

  private var tapHint: some View {
    Text("Tap anywhere to continue")
      .font(.rizqSans(.footnote))
      .foregroundStyle(Color.rizqTextSecondary.opacity(0.6))
      .opacity(showHint ? 1 : 0)
      .animation(.easeIn(duration: 0.3).delay(1.0), value: showHint)
  }

  // MARK: - Animations

  private func startAnimations() {
    withAnimation(.spring(response: 0.5, dampingFraction: 0.6)) {
      showCheckmark = true
    }

    withAnimation(.easeOut(duration: 0.4).delay(0.3)) {
      showContent = true
    }

    withAnimation(.spring(response: 0.5, dampingFraction: 0.7).delay(0.5)) {
      showXpBadge = true
    }

    withAnimation(.easeIn(duration: 0.3).delay(1.0)) {
      showHint = true
    }
  }
}

// MARK: - Particle View

private struct ParticleView: View {
  let size: CGFloat
  let color: Color
  let delay: Double

  @State private var isAnimating = false

  var body: some View {
    Circle()
      .fill(color)
      .frame(width: size, height: size)
      .opacity(isAnimating ? 0 : 0.8)
      .offset(y: isAnimating ? -100 : 0)
      .animation(
        Animation
          .easeOut(duration: 2.0)
          .delay(delay)
          .repeatForever(autoreverses: false),
        value: isAnimating
      )
      .onAppear {
        isAnimating = true
      }
  }
}

// MARK: - Mini Celebration

/// Smaller inline celebration for completing items in a list
struct MiniCelebrationView: View {
  let isVisible: Bool
  let message: String

  var body: some View {
    if isVisible {
      HStack(spacing: RIZQSpacing.sm) {
        Text("\u{2713}") // Checkmark
          .font(.system(size: 14, weight: .bold))

        Text(message)
          .font(.rizqSansMedium(.subheadline))
      }
      .foregroundStyle(Color.rizqPrimary)
      .padding(.horizontal, RIZQSpacing.md)
      .padding(.vertical, RIZQSpacing.sm)
      .background(
        Capsule()
          .fill(Color.rizqPrimary.opacity(0.1))
      )
      .transition(.asymmetric(
        insertion: .scale(scale: 0.8).combined(with: .opacity),
        removal: .scale(scale: 0.8).combined(with: .opacity)
      ))
    }
  }
}

// MARK: - Previews

#Preview("Celebration Overlay") {
  CelebrationOverlayView(
    isVisible: true,
    title: "Masha'Allah!",
    subtitle: "Dua completed",
    xpEarned: 15,
    onDismiss: {}
  )
}

#Preview("Mini Celebration") {
  VStack(spacing: 20) {
    MiniCelebrationView(isVisible: true, message: "Done!")
    MiniCelebrationView(isVisible: true, message: "Completed!")
  }
  .padding()
  .rizqPageBackground()
}
