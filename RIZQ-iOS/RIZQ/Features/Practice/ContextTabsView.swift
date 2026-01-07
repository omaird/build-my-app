import SwiftUI
import RIZQKit

/// Tab bar for switching between Practice and Context views
struct ContextTabsView: View {
  @Binding var selectedTab: PracticeFeature.ContextTab
  let hasContext: Bool

  @Namespace private var animation

  var body: some View {
    HStack(spacing: 0) {
      ForEach(PracticeFeature.ContextTab.allCases) { tab in
        tabButton(for: tab)
      }
    }
    .padding(4)
    .background(Color.rizqMuted.opacity(0.2))
    .clipShape(RoundedRectangle(cornerRadius: RIZQRadius.btn))
  }

  // MARK: - Tab Button

  private func tabButton(for tab: PracticeFeature.ContextTab) -> some View {
    let isSelected = selectedTab == tab
    let isDisabled = tab == .context && !hasContext

    return Button {
      guard !isDisabled else { return }
      withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
        selectedTab = tab
      }
    } label: {
      HStack(spacing: RIZQSpacing.sm) {
        Image(systemName: tab.icon)
          .font(.system(size: 14, weight: .medium))

        Text(tab.title)
          .font(.rizqSansMedium(.subheadline))
      }
      .foregroundStyle(
        isSelected ? Color.rizqPrimary : Color.rizqTextSecondary
      )
      .opacity(isDisabled ? 0.4 : 1.0)
      .padding(.horizontal, RIZQSpacing.lg)
      .padding(.vertical, RIZQSpacing.md)
      .frame(maxWidth: .infinity)
      .background {
        if isSelected {
          RoundedRectangle(cornerRadius: RIZQRadius.md)
            .fill(Color.rizqCard)
            .shadowSoft()
            .matchedGeometryEffect(id: "tab-indicator", in: animation)
        }
      }
    }
    .buttonStyle(.plain)
    .disabled(isDisabled)
  }
}

// MARK: - Previews

#Preview("Context Tabs - With Context") {
  VStack(spacing: 40) {
    ContextTabsView(
      selectedTab: .constant(.practice),
      hasContext: true
    )

    ContextTabsView(
      selectedTab: .constant(.context),
      hasContext: true
    )
  }
  .padding()
  .rizqPageBackground()
}

#Preview("Context Tabs - No Context") {
  ContextTabsView(
    selectedTab: .constant(.practice),
    hasContext: false
  )
  .padding()
  .rizqPageBackground()
}
