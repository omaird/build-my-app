import SwiftUI
import RIZQKit

/// Compact, non-blocking celebration shown when a habit is completed.
///
/// Replaces the previous full-screen teal overlay with a pill anchored in the
/// upper third of its container. The sheet content remains visible behind it
/// (softly dimmed), and a small particle burst plays around the pill.
///
/// Visual structure:
///   [✓ animated checkmark]   MashaAllah!
///                            +N XP earned
struct CompletionToast: View {
  let xpValue: Int
  let isVisible: Bool

  @State private var particlesActive: Bool = false
  @State private var pillOffset: CGFloat = -40
  @State private var pillOpacity: Double = 0

  var body: some View {
    ZStack(alignment: .top) {
      // Soft backdrop — much gentler than the previous 95% teal overlay.
      // Lets the dua content show through while still focusing the eye.
      Color.black
        .opacity(pillOpacity * 0.12)
        .ignoresSafeArea()
        .allowsHitTesting(false)

      VStack {
        ZStack {
          // Small, contained particle burst — sized to the pill area.
          CelebrationParticles(
            isActive: $particlesActive,
            particleCount: 6,
            duration: 1.6
          )
          .frame(width: 320, height: 200)
          .allowsHitTesting(false)

          pill
        }
        .padding(.top, 64) // Anchor in upper third of sheet content

        Spacer()
      }
    }
    .onChange(of: isVisible) { _, newValue in
      if newValue {
        animateIn()
      } else {
        animateOut()
      }
    }
    .onAppear {
      if isVisible { animateIn() }
    }
    .accessibilityElement(children: .ignore)
    .accessibilityLabel("MashaAllah! You earned \(xpValue) XP")
    .accessibilityAddTraits(.isModal)
  }

  // MARK: - Pill

  private var pill: some View {
    HStack(spacing: 14) {
      AnimatedCheckmark(
        isVisible: isVisible,
        size: 44,
        strokeWidth: 3,
        delay: 0.05
      )

      VStack(alignment: .leading, spacing: 2) {
        Text("MashaAllah!")
          .font(.rizqDisplaySemiBold(.title3))
          .foregroundStyle(Color.rizqText)

        Text("+\(xpValue) XP earned")
          .font(.rizqMono(.subheadline))
          .foregroundStyle(Color.rizqPrimary)
      }
    }
    .padding(.horizontal, 20)
    .padding(.vertical, 14)
    .background(
      RoundedRectangle(cornerRadius: 20, style: .continuous)
        .fill(Color.rizqCard)
    )
    .shadowGlowPrimary()
    .offset(y: pillOffset)
    .opacity(pillOpacity)
  }

  // MARK: - Animation

  private func animateIn() {
    withAnimation(.spring(response: 0.45, dampingFraction: 0.72)) {
      pillOffset = 0
      pillOpacity = 1
    }
    // Slight stagger so particles erupt as the pill lands
    DispatchQueue.main.asyncAfter(deadline: .now() + 0.08) {
      particlesActive = true
    }
  }

  private func animateOut() {
    withAnimation(.easeIn(duration: 0.25)) {
      pillOffset = -30
      pillOpacity = 0
    }
    particlesActive = false
  }
}

#Preview {
  struct PreviewWrapper: View {
    @State private var visible = false

    var body: some View {
      ZStack {
        Color.rizqBackground.ignoresSafeArea()

        VStack {
          Spacer()
          Text("Sheet content sits behind…")
            .font(.rizqSans(.body))
            .foregroundStyle(Color.rizqText)
          Spacer()
          Button(visible ? "Hide" : "Show celebration") {
            visible.toggle()
          }
          .buttonStyle(.borderedProminent)
          Spacer().frame(height: 60)
        }

        if visible {
          CompletionToast(xpValue: 15, isVisible: visible)
        }
      }
    }
  }

  return PreviewWrapper()
}
