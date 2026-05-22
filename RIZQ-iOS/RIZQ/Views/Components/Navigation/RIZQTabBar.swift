import SwiftUI
import RIZQKit

struct RIZQTabBar: View {
  @Binding var selectedTab: AppFeature.Tab

  var body: some View {
    HStack(spacing: 0) {
      TabBarItem(tab: .home, selectedTab: selectedTab) {
        selectedTab = .home
      }
      TabBarItem(tab: .journeys, selectedTab: selectedTab) {
        selectedTab = .journeys
      }
      AdkharFABItem(isSelected: selectedTab == .adkhar) {
        selectedTab = .adkhar
      }
      TabBarItem(tab: .library, selectedTab: selectedTab) {
        selectedTab = .library
      }
      TabBarItem(tab: .settings, selectedTab: selectedTab) {
        selectedTab = .settings
      }
    }
    .frame(height: 68)
    .background(
      RoundedRectangle(cornerRadius: 28, style: .continuous)
        .fill(Color.rizqCard)
        .shadowSoft()
    )
    .padding(.horizontal, RIZQSpacing.md)
    .padding(.bottom, RIZQSpacing.xs)
  }
}

private struct TabBarItem: View {
  let tab: AppFeature.Tab
  let selectedTab: AppFeature.Tab
  let action: () -> Void

  private var isSelected: Bool { tab == selectedTab }

  var body: some View {
    Button(action: action) {
      VStack(spacing: 3) {
        Image(systemName: tab.icon)
          .font(.system(size: 20, weight: isSelected ? .semibold : .regular))
          .frame(height: 24)
        Text(tab.title)
          .font(.system(size: 10, weight: .medium))
      }
      .foregroundStyle(isSelected ? Color.rizqPrimary : Color.rizqTextSecondary)
      .frame(maxWidth: .infinity)
      .contentShape(Rectangle())
    }
    .buttonStyle(.plain)
  }
}

private struct AdkharFABItem: View {
  let isSelected: Bool
  let action: () -> Void

  var body: some View {
    Button(action: action) {
      VStack(spacing: 3) {
        fabCircle
          .offset(y: -18)
          .padding(.bottom, -18)

        Text(AppFeature.Tab.adkhar.title)
          .font(.system(size: 10, weight: .semibold))
          .foregroundStyle(isSelected ? Color.rizqPrimary : Color.rizqTextSecondary)
      }
      .frame(maxWidth: .infinity)
      .contentShape(Rectangle())
    }
    .buttonStyle(.plain)
  }

  // ─────────────────────────────────────────────────────────────────────
  // TODO: pick treatment — this is the block that defines the FAB's feel.
  //
  // Knobs to tune (try one at a time):
  //   • Fill: swap LinearGradient.rizqPrimaryGradient for a brighter
  //     sand→gold gradient, e.g.
  //         LinearGradient(colors: [.sandWarm, .goldBright],
  //                        startPoint: .top, endPoint: .bottom)
  //     …or a flat fill: `.fill(Color.rizqPrimary)` for a more restrained
  //     look closer to the rest of the bar.
  //   • Size: 56pt feels prominent but balanced. Push to 60–64pt for a
  //     bolder, more obviously-the-main-action vibe.
  //   • Glow: `.shadowGlowPrimary()` is the warm halo. Stack with
  //     `.shadowSoft()` for more depth, or replace with a custom shadow.
  //   • Ring/stroke: add `.overlay(Circle().stroke(Color.creamWarm
  //     .opacity(0.5), lineWidth: 2))` for a subtle inner ring that
  //     reads as a "badge."
  //   • Icon: weight `.bold` is assertive; `.semibold` is calmer.
  //     `.foregroundStyle(.white)` for max contrast, or `Color.mocha`
  //     for a warmer, embossed feel against the sand fill.
  //   • Selected feedback: `scaleEffect(isSelected ? 1.08 : 1.0)` is
  //     subtle. Bump to 1.12 for a more dramatic press response, or
  //     pair with a brighter glow when selected.
  // ─────────────────────────────────────────────────────────────────────
  private var fabCircle: some View {
    ZStack {
      Circle()
        .fill(LinearGradient.rizqPrimaryGradient)
        .frame(width: 56, height: 56)
        .shadowGlowPrimary()

      Image(systemName: AppFeature.Tab.adkhar.icon)
        .font(.system(size: 24, weight: .bold))
        .foregroundStyle(.white)
    }
    .scaleEffect(isSelected ? 1.08 : 1.0)
    .animation(.spring(response: 0.35, dampingFraction: 0.7), value: isSelected)
  }
}

#Preview("Light") {
  StatefulPreviewWrapper(AppFeature.Tab.adkhar) { tab in
    VStack {
      Spacer()
      Rectangle().fill(Color.rizqBackground).overlay(
        Text("Content area").foregroundStyle(.secondary)
      )
      RIZQTabBar(selectedTab: tab)
    }
    .ignoresSafeArea(edges: .top)
  }
  .preferredColorScheme(.light)
}

#Preview("Dark") {
  StatefulPreviewWrapper(AppFeature.Tab.home) { tab in
    VStack {
      Spacer()
      Rectangle().fill(Color.rizqBackground).overlay(
        Text("Content area").foregroundStyle(.secondary)
      )
      RIZQTabBar(selectedTab: tab)
    }
    .ignoresSafeArea(edges: .top)
  }
  .preferredColorScheme(.dark)
}

/// Tiny helper for previews that need a mutable binding.
private struct StatefulPreviewWrapper<Value, Content: View>: View {
  @State private var value: Value
  let content: (Binding<Value>) -> Content

  init(_ initialValue: Value, @ViewBuilder content: @escaping (Binding<Value>) -> Content) {
    self._value = State(initialValue: initialValue)
    self.content = content
  }

  var body: some View { content($value) }
}
