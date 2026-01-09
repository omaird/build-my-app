import SwiftUI
import RIZQKit

/// Islamic geometric pattern background view
/// Renders a subtle 8-point star pattern matching the React web app's islamic-pattern class
struct IslamicPatternView: View {
  var opacity: Double = 0.05
  var color: Color = .sandWarm

  var body: some View {
    GeometryReader { geometry in
      Canvas { context, size in
        let pattern = createIslamicPattern(size: size)
        context.fill(pattern, with: .color(color.opacity(opacity)))
      }
    }
    .ignoresSafeArea()
  }

  /// Creates an 8-point star pattern arranged in a grid
  private func createIslamicPattern(size: CGSize) -> Path {
    var path = Path()
    let spacing: CGFloat = 40
    let rows = Int(size.height / spacing) + 1
    let cols = Int(size.width / spacing) + 1

    for row in 0..<rows {
      for col in 0..<cols {
        let x = CGFloat(col) * spacing
        let y = CGFloat(row) * spacing
        // Offset alternating rows for a more organic feel
        let offset = row.isMultiple(of: 2) ? spacing / 2 : 0

        addStar(to: &path, center: CGPoint(x: x + offset, y: y), size: 8)
      }
    }

    return path
  }

  /// Adds an 8-point star to the path at the given center point
  private func addStar(to path: inout Path, center: CGPoint, size: CGFloat) {
    let points = 8
    let innerRadius = size * 0.4
    let outerRadius = size

    var starPath = Path()
    for i in 0..<(points * 2) {
      let radius = i.isMultiple(of: 2) ? outerRadius : innerRadius
      let angle = Double(i) * .pi / Double(points) - .pi / 2
      let point = CGPoint(
        x: center.x + CGFloat(cos(angle)) * radius,
        y: center.y + CGFloat(sin(angle)) * radius
      )

      if i == 0 {
        starPath.move(to: point)
      } else {
        starPath.addLine(to: point)
      }
    }
    starPath.closeSubpath()
    path.addPath(starPath)
  }
}

// MARK: - Animated Variant

/// Islamic pattern with subtle animation
struct AnimatedIslamicPatternView: View {
  var opacity: Double = 0.05
  var color: Color = .sandWarm

  @State private var phase: CGFloat = 0

  var body: some View {
    GeometryReader { geometry in
      Canvas { context, size in
        let pattern = createAnimatedPattern(size: size, phase: phase)
        context.fill(pattern, with: .color(color.opacity(opacity)))
      }
    }
    .ignoresSafeArea()
    .onAppear {
      withAnimation(
        .linear(duration: 20)
        .repeatForever(autoreverses: false)
      ) {
        phase = 1
      }
    }
  }

  private func createAnimatedPattern(size: CGSize, phase: CGFloat) -> Path {
    var path = Path()
    let spacing: CGFloat = 50
    let rows = Int(size.height / spacing) + 2
    let cols = Int(size.width / spacing) + 2

    for row in 0..<rows {
      for col in 0..<cols {
        let baseX = CGFloat(col) * spacing
        let baseY = CGFloat(row) * spacing
        let offset = row.isMultiple(of: 2) ? spacing / 2 : 0

        // Add gentle movement
        let moveX = sin(phase * .pi * 2 + CGFloat(row) * 0.5) * 2
        let moveY = cos(phase * .pi * 2 + CGFloat(col) * 0.5) * 2

        let center = CGPoint(x: baseX + offset + moveX, y: baseY + moveY)
        addStar(to: &path, center: center, size: 6)
      }
    }

    return path
  }

  private func addStar(to path: inout Path, center: CGPoint, size: CGFloat) {
    let points = 8
    let innerRadius = size * 0.4
    let outerRadius = size

    var starPath = Path()
    for i in 0..<(points * 2) {
      let radius = i.isMultiple(of: 2) ? outerRadius : innerRadius
      let angle = Double(i) * .pi / Double(points) - .pi / 2
      let point = CGPoint(
        x: center.x + CGFloat(cos(angle)) * radius,
        y: center.y + CGFloat(sin(angle)) * radius
      )

      if i == 0 {
        starPath.move(to: point)
      } else {
        starPath.addLine(to: point)
      }
    }
    starPath.closeSubpath()
    path.addPath(starPath)
  }
}

// MARK: - View Modifier

/// View modifier to add Islamic pattern background
struct IslamicPatternBackground: ViewModifier {
  var opacity: Double = 0.05
  var color: Color = .sandWarm

  func body(content: Content) -> some View {
    content
      .background {
        IslamicPatternView(opacity: opacity, color: color)
      }
  }
}

extension View {
  /// Adds a subtle Islamic geometric pattern to the background
  func islamicPatternBackground(opacity: Double = 0.05, color: Color = .sandWarm) -> some View {
    modifier(IslamicPatternBackground(opacity: opacity, color: color))
  }
}

// MARK: - Previews

#Preview("Islamic Pattern - Default") {
  ZStack {
    Color.rizqBackground.ignoresSafeArea()
    IslamicPatternView()

    Text("Islamic Pattern Background")
      .font(.title)
      .foregroundStyle(Color.rizqText)
  }
}

#Preview("Islamic Pattern - Higher Opacity") {
  ZStack {
    Color.rizqBackground.ignoresSafeArea()
    IslamicPatternView(opacity: 0.15, color: .mocha)

    Text("Higher Opacity")
      .font(.title)
      .foregroundStyle(Color.rizqText)
  }
}

#Preview("Animated Islamic Pattern") {
  ZStack {
    Color.rizqBackground.ignoresSafeArea()
    AnimatedIslamicPatternView()

    Text("Animated Pattern")
      .font(.title)
      .foregroundStyle(Color.rizqText)
  }
}

#Preview("View Modifier Usage") {
  VStack(spacing: 20) {
    Text("Content with Pattern")
      .font(.title)
      .foregroundStyle(Color.rizqText)

    Text("Using the .islamicPatternBackground() modifier")
      .font(.subheadline)
      .foregroundStyle(Color.rizqTextSecondary)
  }
  .frame(maxWidth: .infinity, maxHeight: .infinity)
  .background(Color.rizqBackground)
  .islamicPatternBackground()
}
