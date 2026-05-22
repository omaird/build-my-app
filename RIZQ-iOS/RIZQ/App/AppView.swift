import SwiftUI
import ComposableArchitecture
import RIZQKit

struct AppView: View {
  @Bindable var store: StoreOf<AppFeature>

  var body: some View {
    Group {
      if store.isAuthenticated {
        currentTabContent
          .frame(maxWidth: .infinity, maxHeight: .infinity)
          .background(Color.rizqBackground.ignoresSafeArea())
          .safeAreaInset(edge: .bottom, spacing: 0) {
            RIZQTabBar(
              selectedTab: $store.selectedTab.sending(\.tabSelected)
            )
          }
          .fullScreenCover(
            item: $store.scope(state: \.admin, action: \.admin)
          ) { adminStore in
            AdminTabView(store: adminStore)
          }
      } else {
        AuthView(store: store.scope(state: \.auth, action: \.auth))
      }
    }
    .preferredColorScheme(store.settings.isDarkMode ? .dark : .light)
    .onAppear {
      store.send(.onAppear)
    }
  }

  @ViewBuilder
  private var currentTabContent: some View {
    switch store.selectedTab {
    case .home:
      HomeView(store: store.scope(state: \.home, action: \.home))
    case .journeys:
      JourneysView(store: store.scope(state: \.journeys, action: \.journeys))
    case .adkhar:
      AdkharView(store: store.scope(state: \.adkhar, action: \.adkhar))
    case .library:
      LibraryView(store: store.scope(state: \.library, action: \.library))
    case .settings:
      SettingsView(store: store.scope(state: \.settings, action: \.settings))
    }
  }
}

#Preview {
  AppView(
    store: Store(initialState: AppFeature.State(isAuthenticated: true)) {
      AppFeature()
    }
  )
}
