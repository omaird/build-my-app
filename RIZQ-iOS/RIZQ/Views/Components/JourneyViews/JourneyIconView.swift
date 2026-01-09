import SwiftUI
import RIZQKit

/// A view that renders either an image or emoji for a journey
/// Handles the fact that the `emoji` field in the database can contain
/// either an actual emoji character or an image path
struct JourneyIconView: View {
  let journey: Journey
  let size: CGFloat
  var showDecorations: Bool = true

  var body: some View {
    ZStack {
      // Decorative background
      if showDecorations {
        decorativeFrame
      }

      // Main icon content
      iconContent
    }
    .frame(width: size, height: size)
  }

  // MARK: - Icon Content

  @ViewBuilder
  private var iconContent: some View {
    if journey.hasImageAsset {
      // Try to load the image asset using the journey slug
      Image(journey.imageAssetName)
        .resizable()
        .aspectRatio(contentMode: .fit)
        .frame(width: size * 0.85, height: size * 0.85)
        .clipShape(Circle())
    } else {
      // Fall back to displaying the emoji as text
      Text(journey.emoji)
        .font(.system(size: size * 0.5))
    }
  }

  // MARK: - Decorative Frame

  private var decorativeFrame: some View {
    ZStack {
      // Background circle with gradient
      Circle()
        .fill(
          LinearGradient(
            colors: [Color.cream, Color.cream.opacity(0.3)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
          )
        )

      // Subtle border
      Circle()
        .stroke(Color.rizqPrimary.opacity(0.15), lineWidth: 1.5)

      // Corner decorations (top-right and bottom-left)
      RoundedRectangle(cornerRadius: 2)
        .stroke(Color.rizqPrimary.opacity(0.25), lineWidth: 1)
        .frame(width: 6, height: 6)
        .offset(x: size * 0.35, y: -size * 0.35)

      RoundedRectangle(cornerRadius: 2)
        .stroke(Color.rizqPrimary.opacity(0.25), lineWidth: 1)
        .frame(width: 6, height: 6)
        .offset(x: -size * 0.35, y: size * 0.35)
    }
  }
}

// MARK: - Large Journey Icon (for detail view)

/// A larger, more ornate version of the journey icon for detail views
struct LargeJourneyIconView: View {
  let journey: Journey
  let size: CGFloat
  @State private var isAnimating = false

  var body: some View {
    ZStack {
      // Outer rotating dashed ring
      Circle()
        .stroke(style: StrokeStyle(lineWidth: 2, dash: [5, 5]))
        .foregroundStyle(Color.rizqPrimary.opacity(0.2))
        .frame(width: size * 1.25, height: size * 1.25)
        .rotationEffect(.degrees(isAnimating ? 360 : 0))
        .animation(.linear(duration: 20).repeatForever(autoreverses: false), value: isAnimating)

      // Inner glow
      Circle()
        .fill(Color.rizqPrimary.opacity(0.1))
        .frame(width: size, height: size)
        .blur(radius: 12)

      // Main icon
      JourneyIconView(journey: journey, size: size, showDecorations: true)
        .shadowSoft()
    }
    .onAppear {
      isAnimating = true
    }
  }
}

// MARK: - Preview

#Preview("Journey Icon - Image") {
  VStack(spacing: 20) {
    JourneyIconView(
      journey: Journey(
        id: 1,
        name: "Rizq Seeker",
        slug: "rizq-seeker",
        description: "A comprehensive daily practice",
        emoji: "/images/icons/The Rizq Seeker.png"
      ),
      size: 80
    )

    JourneyIconView(
      journey: Journey(
        id: 2,
        name: "Test Emoji",
        slug: "test",
        emoji: "🌅"
      ),
      size: 80
    )
  }
  .padding()
  .background(Color.rizqBackground)
}

#Preview("Large Journey Icon") {
  LargeJourneyIconView(
    journey: Journey(
      id: 1,
      name: "Rizq Seeker",
      slug: "rizq-seeker",
      emoji: "/images/icons/The Rizq Seeker.png"
    ),
    size: 100
  )
  .padding(40)
  .background(Color.rizqBackground)
}
