import SwiftUI
import ComposableArchitecture
import RIZQKit

/// Main Admin Tab View with sidebar on iPad / tab bar on iPhone
struct AdminTabView: View {
  @Bindable var store: StoreOf<AdminFeature>
  @Environment(\.horizontalSizeClass) var horizontalSizeClass

  var body: some View {
    Group {
      if horizontalSizeClass == .regular {
        // iPad: Sidebar navigation
        NavigationSplitView {
          sidebarContent
        } detail: {
          detailContent
        }
      } else {
        // iPhone: Navigation stack with list
        NavigationStack {
          tabSelectionList
        }
      }
    }
    .onAppear {
      store.send(.onAppear)
    }
  }

  // MARK: - Sidebar (iPad)

  private var sidebarContent: some View {
    List(AdminFeature.AdminTab.allCases, selection: Binding(
      get: { store.selectedTab },
      set: { tab in
        if let tab = tab {
          store.send(.tabSelected(tab))
        }
      }
    )) { tab in
      Label {
        VStack(alignment: .leading, spacing: 2) {
          Text(tab.title)
            .font(.rizqSans(.body))
          Text(tab.description)
            .font(.rizqSans(.caption))
            .foregroundStyle(Color.rizqTextSecondary)
        }
      } icon: {
        Image(systemName: tab.icon)
          .foregroundStyle(tabColor(for: tab))
      }
      .tag(tab)
    }
    .listStyle(.sidebar)
    .navigationTitle("Admin")
    .toolbar {
      ToolbarItem(placement: .primaryAction) {
        Button {
          store.send(.closeAdmin)
        } label: {
          Image(systemName: "xmark.circle.fill")
            .foregroundStyle(Color.rizqTextSecondary)
        }
      }
    }
  }

  // MARK: - Tab Selection List (iPhone)

  private var tabSelectionList: some View {
    List {
      ForEach(AdminFeature.AdminTab.allCases) { tab in
        NavigationLink {
          destinationView(for: tab)
        } label: {
          HStack(spacing: 16) {
            ZStack {
              Circle()
                .fill(tabColor(for: tab).opacity(0.15))
                .frame(width: 44, height: 44)

              Image(systemName: tab.icon)
                .font(.title3)
                .foregroundStyle(tabColor(for: tab))
            }

            VStack(alignment: .leading, spacing: 2) {
              Text(tab.title)
                .font(.rizqSans(.body))
                .foregroundStyle(Color.rizqText)
              Text(tab.description)
                .font(.rizqSans(.caption))
                .foregroundStyle(Color.rizqTextSecondary)
            }

            Spacer()

            Image(systemName: "chevron.right")
              .font(.caption)
              .foregroundStyle(Color.rizqTextSecondary)
          }
          .padding(.vertical, 8)
        }
      }
    }
    .listStyle(.plain)
    .navigationTitle("Admin")
    .navigationBarTitleDisplayMode(.large)
    .toolbar {
      ToolbarItem(placement: .primaryAction) {
        Button {
          store.send(.closeAdmin)
        } label: {
          Image(systemName: "xmark.circle.fill")
            .foregroundStyle(Color.rizqTextSecondary)
        }
      }
    }
    .rizqPageBackground()
  }

  // MARK: - Detail Content (iPad)

  @ViewBuilder
  private var detailContent: some View {
    destinationView(for: store.selectedTab)
  }

  // MARK: - Destination Views

  @ViewBuilder
  private func destinationView(for tab: AdminFeature.AdminTab) -> some View {
    switch tab {
    case .dashboard:
      AdminDashboardView(
        store: store.scope(state: \.dashboard, action: \.dashboard)
      )
    case .duas:
      AdminDuasView(
        store: store.scope(state: \.duas, action: \.duas)
      )
    case .journeys:
      AdminJourneysView(
        store: store.scope(state: \.journeys, action: \.journeys)
      )
    case .categories:
      AdminCategoriesView(
        store: store.scope(state: \.categories, action: \.categories)
      )
    case .users:
      AdminUsersView(
        store: store.scope(state: \.users, action: \.users)
      )
    }
  }

  // MARK: - Tab Colors

  private func tabColor(for tab: AdminFeature.AdminTab) -> Color {
    switch tab {
    case .dashboard: return .rizqPrimary
    case .duas: return .badgeMorning
    case .journeys: return .tealMuted
    case .categories: return .badgeGratitude
    case .users: return .badgeEvening
    }
  }
}

#Preview {
  AdminTabView(
    store: Store(initialState: AdminFeature.State()) {
      AdminFeature()
    }
  )
}
