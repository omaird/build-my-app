import SwiftUI

/// A particle system that displays celebration particles when triggered
/// Matches the React CelebrationParticles component with stars, sparkles, and dots
struct CelebrationParticles: View {
  @Binding var isActive: Bool
  var particleCount: Int = 16
  var duration: TimeInterval = 2.5
  var onComplete: (() -> Void)?

  @State private var particles: [Particle] = []

  struct Particle: Identifiable {
    let id = UUID()
    let x: CGFloat // percentage
    let y: CGFloat // percentage
    let size: CGFloat
    let delay: TimeInterval
    let animationDuration: TimeInterval
    let type: ParticleType
    let horizontalOffset: CGFloat

    enum ParticleType {
      case star, sparkle, dot
    }
  }

  var body: some View {
    GeometryReader { geometry in
      ZStack {
        ForEach(particles) { particle in
          ParticleView(particle: particle)
            .position(
              x: geometry.size.width * particle.x / 100,
              y: geometry.size.height * particle.y / 100
            )
        }
      }
    }
    .allowsHitTesting(false)
    .onChange(of: isActive) { _, newValue in
      if newValue {
        generateParticles()
        DispatchQueue.main.asyncAfter(deadline: .now() + duration) {
          particles = []
          onComplete?()
        }
      } else {
        particles = []
      }
    }
  }

  private func generateParticles() {
    particles = (0..<particleCount).map { _ in
      Particle(
        x: CGFloat.random(in: 0...100),
        y: CGFloat.random(in: 60...90),
        size: CGFloat.random(in: 8...24),
        delay: Double.random(in: 0...0.4),
        animationDuration: Double.random(in: 2...3),
        type: [.star, .sparkle, .dot].randomElement()!,
        horizontalOffset: CGFloat.random(in: -30...30)
      )
    }
  }
}

// MARK: - Particle View
private struct ParticleView: View {
  let particle: CelebrationParticles.Particle

  @State private var isAnimating = false

  var body: some View {
    particleShape
      .foregroundStyle(Color.rizqPrimary)
      .opacity(isAnimating ? 0 : 1)
      .scaleEffect(isAnimating ? 0.5 : 1.2)
      .offset(
        x: isAnimating ? particle.horizontalOffset : 0,
        y: isAnimating ? -180 : 0
      )
      .rotationEffect(.degrees(isAnimating ? 360 : 0))
      .onAppear {
        withAnimation(
          .easeOut(duration: particle.animationDuration)
            .delay(particle.delay)
        ) {
          isAnimating = true
        }
      }
  }

  @ViewBuilder
  private var particleShape: some View {
    switch particle.type {
    case .star:
      StarShape()
        .frame(width: particle.size, height: particle.size)
    case .sparkle:
      SparkleShape()
        .frame(width: particle.size * 0.8, height: particle.size * 0.8)
    case .dot:
      Circle()
        .fill(Color.goldSoft)
        .frame(width: particle.size * 0.5, height: particle.size * 0.5)
    }
  }
}

// MARK: - Star Shape
struct StarShape: Shape {
  func path(in rect: CGRect) -> Path {
    let center = CGPoint(x: rect.midX, y: rect.midY)
    let outerRadius = min(rect.width, rect.height) / 2
    let innerRadius = outerRadius * 0.4
    let points = 4

    var path = Path()

    for i in 0..<(points * 2) {
      let angle = Double(i) * .pi / Double(points) - .pi / 2
      let radius = i.isMultiple(of: 2) ? outerRadius : innerRadius
      let point = CGPoint(
        x: center.x + CGFloat(cos(angle)) * radius,
        y: center.y + CGFloat(sin(angle)) * radius
      )

      if i == 0 {
        path.move(to: point)
      } else {
        path.addLine(to: point)
      }
    }
    path.closeSubpath()
    return path
  }
}

// MARK: - Sparkle Shape
struct SparkleShape: Shape {
  func path(in rect: CGRect) -> Path {
    let center = CGPoint(x: rect.midX, y: rect.midY)
    let size = min(rect.width, rect.height) / 2

    var path = Path()
    path.move(to: CGPoint(x: center.x, y: center.y - size))
    path.addLine(to: CGPoint(x: center.x + size * 0.3, y: center.y - size * 0.3))
    path.addLine(to: CGPoint(x: center.x + size, y: center.y))
    path.addLine(to: CGPoint(x: center.x + size * 0.3, y: center.y + size * 0.3))
    path.addLine(to: CGPoint(x: center.x, y: center.y + size))
    path.addLine(to: CGPoint(x: center.x - size * 0.3, y: center.y + size * 0.3))
    path.addLine(to: CGPoint(x: center.x - size, y: center.y))
    path.addLine(to: CGPoint(x: center.x - size * 0.3, y: center.y - size * 0.3))
    path.closeSubpath()
    return path
  }
}

// MARK: - Preview
#Preview {
  struct PreviewWrapper: View {
    @State private var isActive = false

    var body: some View {
      ZStack {
        Color.rizqBackground.ignoresSafeArea()

        VStack {
          Button("Celebrate!") {
            isActive = true
          }
          .buttonStyle(.borderedProminent)
        }

        CelebrationParticles(isActive: $isActive) {
          isActive = false
        }
      }
    }
  }

  return PreviewWrapper()
}
