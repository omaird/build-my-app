import SwiftUI
import RIZQKit

// MARK: - Hexagon Shape
//
// Design Decisions:
// - Flat-top hexagon (point at left/right) for badge aesthetic
// - Starts drawing from top-right point, proceeds clockwise
// - Uses proportional sizing based on rect dimensions
//
// Related Files:
// - AchievementBadgeView.swift (primary consumer)
// - Achievement.swift (data model)

/// A flat-top hexagon shape for achievement badges
/// Points are at left and right, flat edges at top and bottom
struct HexagonShape: Shape {
  func path(in rect: CGRect) -> Path {
    let width = rect.width
    let height = rect.height
    let centerX = rect.midX
    let centerY = rect.midY

    // Hexagon proportions for flat-top orientation
    // Width at widest point (between left/right points)
    let horizontalRadius = width / 2
    // Height of the flat top/bottom edges
    let verticalRadius = height / 2

    var path = Path()

    // Start from top-right point, go clockwise
    // Point 1: Top-right
    path.move(to: CGPoint(
      x: centerX + horizontalRadius * 0.5,
      y: centerY - verticalRadius
    ))

    // Point 2: Right point
    path.addLine(to: CGPoint(
      x: centerX + horizontalRadius,
      y: centerY
    ))

    // Point 3: Bottom-right
    path.addLine(to: CGPoint(
      x: centerX + horizontalRadius * 0.5,
      y: centerY + verticalRadius
    ))

    // Point 4: Bottom-left
    path.addLine(to: CGPoint(
      x: centerX - horizontalRadius * 0.5,
      y: centerY + verticalRadius
    ))

    // Point 5: Left point
    path.addLine(to: CGPoint(
      x: centerX - horizontalRadius,
      y: centerY
    ))

    // Point 6: Top-left
    path.addLine(to: CGPoint(
      x: centerX - horizontalRadius * 0.5,
      y: centerY - verticalRadius
    ))

    // Close back to start
    path.closeSubpath()

    return path
  }
}

// MARK: - Rounded Hexagon Shape

/// A hexagon shape with rounded corners for a softer badge appearance
struct RoundedHexagonShape: Shape {
  var cornerRadius: CGFloat = 8

  func path(in rect: CGRect) -> Path {
    let width = rect.width
    let height = rect.height
    let centerX = rect.midX
    let centerY = rect.midY

    let horizontalRadius = width / 2
    let verticalRadius = height / 2

    // Define the 6 corner points
    let points: [CGPoint] = [
      CGPoint(x: centerX + horizontalRadius * 0.5, y: centerY - verticalRadius), // Top-right
      CGPoint(x: centerX + horizontalRadius, y: centerY),                         // Right
      CGPoint(x: centerX + horizontalRadius * 0.5, y: centerY + verticalRadius),  // Bottom-right
      CGPoint(x: centerX - horizontalRadius * 0.5, y: centerY + verticalRadius),  // Bottom-left
      CGPoint(x: centerX - horizontalRadius, y: centerY),                         // Left
      CGPoint(x: centerX - horizontalRadius * 0.5, y: centerY - verticalRadius),  // Top-left
    ]

    var path = Path()

    // Calculate the effective corner radius (don't exceed half the shortest edge)
    let edgeLength = min(
      distance(from: points[0], to: points[1]),
      distance(from: points[1], to: points[2])
    )
    let effectiveRadius = min(cornerRadius, edgeLength / 2)

    for i in 0..<6 {
      let currentPoint = points[i]
      let nextPoint = points[(i + 1) % 6]
      let prevPoint = points[(i + 5) % 6]

      // Direction vectors
      let toPrev = unitVector(from: currentPoint, to: prevPoint)
      let toNext = unitVector(from: currentPoint, to: nextPoint)

      // Points offset from corner by radius
      let startOfArc = CGPoint(
        x: currentPoint.x + toPrev.x * effectiveRadius,
        y: currentPoint.y + toPrev.y * effectiveRadius
      )
      let endOfArc = CGPoint(
        x: currentPoint.x + toNext.x * effectiveRadius,
        y: currentPoint.y + toNext.y * effectiveRadius
      )

      if i == 0 {
        path.move(to: startOfArc)
      } else {
        path.addLine(to: startOfArc)
      }

      path.addQuadCurve(to: endOfArc, control: currentPoint)
    }

    path.closeSubpath()
    return path
  }

  // MARK: - Geometry Helpers

  private func distance(from p1: CGPoint, to p2: CGPoint) -> CGFloat {
    let dx = p2.x - p1.x
    let dy = p2.y - p1.y
    return sqrt(dx * dx + dy * dy)
  }

  private func unitVector(from p1: CGPoint, to p2: CGPoint) -> CGPoint {
    let dist = distance(from: p1, to: p2)
    guard dist > 0 else { return .zero }
    return CGPoint(
      x: (p2.x - p1.x) / dist,
      y: (p2.y - p1.y) / dist
    )
  }
}

// MARK: - Animatable Corner Radius

extension RoundedHexagonShape: Animatable {
  var animatableData: CGFloat {
    get { cornerRadius }
    set { cornerRadius = newValue }
  }
}

// MARK: - Preview

#Preview("Hexagon Shapes") {
  VStack(spacing: 30) {
    HexagonShape()
      .fill(Color.rizqPrimary)
      .frame(width: 100, height: 100)

    RoundedHexagonShape(cornerRadius: 10)
      .fill(Color.badgeEvening)
      .frame(width: 100, height: 100)

    RoundedHexagonShape(cornerRadius: 15)
      .stroke(Color.tealSuccess, lineWidth: 3)
      .frame(width: 100, height: 100)

    // Badge example
    ZStack {
      RoundedHexagonShape(cornerRadius: 8)
        .fill(
          LinearGradient(
            colors: [Color.goldBright, Color.goldSoft],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
          )
        )
        .frame(width: 80, height: 80)

      Text("7")
        .font(.system(size: 32, weight: .bold, design: .rounded))
        .foregroundStyle(Color.mocha)
    }
  }
  .padding()
  .background(Color.rizqBackground)
}
