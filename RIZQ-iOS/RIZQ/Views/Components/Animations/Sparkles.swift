import SwiftUI
import RIZQKit

/// A decorative sparkle effect overlay
/// Matches the React Sparkles component with randomly positioned, animated sparkles
struct Sparkles: View {
  var count: Int = 20
  var minSize: CGFloat = 1
  var maxSize: CGFloat = 3

  @State private var sparkles: [Sparkle] = []

  struct Sparkle: Identifiable {
    let id = UUID()
    let x: CGFloat // percentage
    let y: CGFloat // percentage
    let size: CGFloat
    let duration: TimeInterval
    let delay: TimeInterval
  }

  var body: some View {
    GeometryReader { geometry in
      ZStack {
        ForEach(sparkles) { sparkle in
          SparkleView(sparkle: sparkle)
            .position(
              x: geometry.size.width * sparkle.x / 100,
              y: geometry.size.height * sparkle.y / 100
            )
        }
      }
    }
    .allowsHitTesting(false)
    .onAppear {
      generateSparkles()
    }
  }

  private func generateSparkles() {
    sparkles = (0..<count).map { _ in
      Sparkle(
        x: CGFloat.random(in: 0...100),
        y: CGFloat.random(in: 0...100),
        size: CGFloat.random(in: minSize...maxSize),
        duration: Double.random(in: 1.5...3.5),
        delay: Double.random(in: 0...2)
      )
    }
  }
}

// MARK: - Sparkle View
private struct SparkleView: View {
  let sparkle: Sparkles.Sparkle

  @State private var opacity: Double = 0
  @State private var scale: CGFloat = 0.5

  var body: some View {
    Circle()
      .fill(Color(hex: "FDE68A")) // amber-200
      .frame(width: sparkle.size, height: sparkle.size)
      .shadow(color: Color(hex: "FBBF24").opacity(0.6), radius: 4, x: 0, y: 0) // amber glow
      .opacity(opacity)
      .scaleEffect(scale)
      .onAppear {
        startAnimation()
      }
  }

  private func startAnimation() {
    // Initial delay
    DispatchQueue.main.asyncAfter(deadline: .now() + sparkle.delay) {
      animateSparkle()
    }
  }

  private func animateSparkle() {
    // Fade in and scale up
    withAnimation(.easeInOut(duration: sparkle.duration / 2)) {
      opacity = 1
      scale = 1.2
    }

    // Fade out and scale down
    DispatchQueue.main.asyncAfter(deadline: .now() + sparkle.duration / 2) {
      withAnimation(.easeInOut(duration: sparkle.duration / 2)) {
        opacity = 0
        scale = 0.5
      }

      // Repeat
      DispatchQueue.main.asyncAfter(deadline: .now() + sparkle.duration / 2) {
        animateSparkle()
      }
    }
  }
}

// MARK: - Mini Celebration
/// A smaller celebration effect for inline completions
struct MiniCelebration: View {
  @Binding var isActive: Bool
  var onComplete: (() -> Void)?

  @State private var particles: [MiniParticle] = []

  struct MiniParticle: Identifiable {
    let id = UUID()
    let angle: Double
    let distance: CGFloat
    let size: CGFloat
    let color: Color
  }

  var body: some View {
    ZStack {
      ForEach(particles) { particle in
        MiniParticleView(particle: particle, isActive: isActive)
      }
    }
    .frame(width: 60, height: 60)
    .onChange(of: isActive) { _, newValue in
      if newValue {
        generateParticles()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
          particles = []
          onComplete?()
        }
      } else {
        particles = []
      }
    }
  }

  private func generateParticles() {
    let colors: [Color] = [.rizqPrimary, .goldSoft, .streakGlow, .sandLight]
    particles = (0..<8).map { i in
      MiniParticle(
        angle: Double(i) * 45,
        distance: CGFloat.random(in: 20...35),
        size: CGFloat.random(in: 4...8),
        color: colors.randomElement()!
      )
    }
  }
}

private struct MiniParticleView: View {
  let particle: MiniCelebration.MiniParticle
  let isActive: Bool

  @State private var offset: CGSize = .zero
  @State private var opacity: Double = 0
  @State private var scale: CGFloat = 0

  var body: some View {
    Circle()
      .fill(particle.color)
      .frame(width: particle.size, height: particle.size)
      .offset(offset)
      .opacity(opacity)
      .scaleEffect(scale)
      .onChange(of: isActive) { _, newValue in
        if newValue {
          animateOut()
        } else {
          reset()
        }
      }
  }

  private func animateOut() {
    let radians = particle.angle * .pi / 180
    let targetX = cos(radians) * particle.distance
    let targetY = sin(radians) * particle.distance

    withAnimation(.easeOut(duration: 0.5)) {
      offset = CGSize(width: targetX, height: targetY)
      opacity = 1
      scale = 1
    }

    withAnimation(.easeIn(duration: 0.3).delay(0.3)) {
      opacity = 0
      scale = 0.5
    }
  }

  private func reset() {
    offset = .zero
    opacity = 0
    scale = 0
  }
}

// MARK: - Celebration Overlay
/// Full-screen celebration overlay with particles and message
struct CelebrationOverlay: View {
  @Binding var isVisible: Bool
  var title: String = "Completed!"
  var subtitle: String?
  var xpEarned: Int?
  var onDismiss: (() -> Void)?

  @State private var contentOpacity: Double = 0
  @State private var contentScale: CGFloat = 0.8
  @State private var showParticles = false

  var body: some View {
    ZStack {
      // Dimmed background
      Color.black.opacity(0.4)
        .ignoresSafeArea()
        .onTapGesture {
          dismiss()
        }

      // Celebration particles
      CelebrationParticles(isActive: $showParticles)

      // Content
      VStack(spacing: 24) {
        // Checkmark
        AnimatedCheckmark(isVisible: isVisible, size: 100)

        // Title
        Text(title)
          .font(.rizqDisplayBold(.title))
          .foregroundStyle(Color.white)

        // Subtitle
        if let subtitle {
          Text(subtitle)
            .font(.rizqSans(.body))
            .foregroundStyle(Color.white.opacity(0.8))
        }

        // XP Badge
        if let xp = xpEarned {
          XpEarnedBadge(amount: xp, isVisible: isVisible)
        }
      }
      .padding(40)
      .background(
        RoundedRectangle(cornerRadius: RIZQRadius.islamic)
          .fill(.ultraThinMaterial)
      )
      .opacity(contentOpacity)
      .scaleEffect(contentScale)
    }
    .opacity(isVisible ? 1 : 0)
    .onChange(of: isVisible) { _, newValue in
      if newValue {
        animateIn()
      }
    }
  }

  private func animateIn() {
    showParticles = true

    withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
      contentOpacity = 1
      contentScale = 1
    }

    // Auto-dismiss after delay
    DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
      dismiss()
    }
  }

  private func dismiss() {
    withAnimation(.easeOut(duration: 0.3)) {
      contentOpacity = 0
      contentScale = 0.8
    }

    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
      isVisible = false
      showParticles = false
      onDismiss?()
    }
  }
}

// MARK: - Preview
#Preview("Sparkles") {
  ZStack {
    Color.rizqBackground.ignoresSafeArea()

    VStack {
      Text("Sparkles Background")
        .font(.title)
    }

    Sparkles(count: 30)
  }
}

#Preview("Mini Celebration") {
  struct PreviewWrapper: View {
    @State private var isActive = false

    var body: some View {
      VStack(spacing: 40) {
        ZStack {
          Circle()
            .fill(Color.rizqPrimary)
            .frame(width: 50, height: 50)

          MiniCelebration(isActive: $isActive)
        }

        Button("Celebrate") {
          isActive = true
          DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            isActive = false
          }
        }
      }
    }
  }

  return PreviewWrapper()
}

#Preview("Celebration Overlay") {
  struct PreviewWrapper: View {
    @State private var showCelebration = false

    var body: some View {
      ZStack {
        Color.rizqBackground.ignoresSafeArea()

        Button("Show Celebration") {
          showCelebration = true
        }
        .buttonStyle(.borderedProminent)

        CelebrationOverlay(
          isVisible: $showCelebration,
          title: "Dua Completed!",
          subtitle: "MashaAllah, keep going!",
          xpEarned: 25
        )
      }
    }
  }

  return PreviewWrapper()
}
