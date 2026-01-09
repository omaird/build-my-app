import SwiftUI
import RIZQKit

/// Tab bar for switching between Practice and Context views
/// Matches React design with rounded pill tabs and subtle shadow
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
    .background(Color.rizqSurface)
    .clipShape(RoundedRectangle(cornerRadius: RIZQRadius.islamic))
    .overlay(
      RoundedRectangle(cornerRadius: RIZQRadius.islamic)
        .stroke(Color.rizqBorder.opacity(0.5), lineWidth: 1)
    )
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
      .padding(.horizontal, RIZQSpacing.xl)
      .padding(.vertical, RIZQSpacing.md)
      .frame(maxWidth: .infinity)
      .background {
        if isSelected {
          RoundedRectangle(cornerRadius: RIZQRadius.btn)
            .fill(Color.rizqCard)
            .shadow(color: .black.opacity(0.06), radius: 4, y: 2)
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
