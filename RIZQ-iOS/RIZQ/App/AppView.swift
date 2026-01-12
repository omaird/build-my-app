import SwiftUI
import ComposableArchitecture
import RIZQKit

struct AppView: View {
  @Bindable var store: StoreOf<AppFeature>

  var body: some View {
    Group {
      if store.isAuthenticated {
        TabView(selection: $store.selectedTab.sending(\.tabSelected)) {
          HomeView(store: store.scope(state: \.home, action: \.home))
            .tabItem {
              Label(AppFeature.Tab.home.title, systemImage: AppFeature.Tab.home.icon)
            }
            .tag(AppFeature.Tab.home)

          LibraryView(store: store.scope(state: \.library, action: \.library))
            .tabItem {
              Label(AppFeature.Tab.library.title, systemImage: AppFeature.Tab.library.icon)
            }
            .tag(AppFeature.Tab.library)

          AdkharView(store: store.scope(state: \.adkhar, action: \.adkhar))
            .tabItem {
              Label(AppFeature.Tab.adkhar.title, systemImage: AppFeature.Tab.adkhar.icon)
            }
            .tag(AppFeature.Tab.adkhar)

          JourneysView(store: store.scope(state: \.journeys, action: \.journeys))
            .tabItem {
              Label(AppFeature.Tab.journeys.title, systemImage: AppFeature.Tab.journeys.icon)
            }
            .tag(AppFeature.Tab.journeys)

          SettingsView(store: store.scope(state: \.settings, action: \.settings))
            .tabItem {
              Label(AppFeature.Tab.settings.title, systemImage: AppFeature.Tab.settings.icon)
            }
            .tag(AppFeature.Tab.settings)
        }
        .tint(.rizqPrimary)
        .onChange(of: store.selectedTab) { oldTab, newTab in
          print("📱 AppView: Tab changed from \(oldTab.rawValue) to \(newTab.rawValue)")
        }
        // Admin Panel Full Screen Cover
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
      print("📱 AppView: onAppear, isAuthenticated=\(store.isAuthenticated), selectedTab=\(store.selectedTab.rawValue)")
      store.send(.onAppear)
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
