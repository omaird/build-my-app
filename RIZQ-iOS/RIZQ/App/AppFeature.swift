import ComposableArchitecture
import Foundation
import RIZQKit

@Reducer
struct AppFeature {
  @ObservableState
  struct State: Equatable {
    var selectedTab: Tab = .home
    var isAuthenticated: Bool = false
    var home = HomeFeature.State()
    var library = LibraryFeature.State()
    var adkhar = AdkharFeature.State()
    var journeys = JourneysFeature.State()
    var settings = SettingsFeature.State()
    var auth = AuthFeature.State()
  }

  enum Tab: String, CaseIterable, Identifiable {
    case home
    case library
    case adkhar
    case journeys
    case settings

    var id: String { rawValue }

    var title: String {
      switch self {
      case .home: return "Home"
      case .library: return "Library"
      case .adkhar: return "Adkhar"
      case .journeys: return "Journeys"
      case .settings: return "Settings"
      }
    }

    var icon: String {
      switch self {
      case .home: return "house.fill"
      case .library: return "book.fill"
      case .adkhar: return "sun.max.fill"
      case .journeys: return "map.fill"
      case .settings: return "gearshape.fill"
      }
    }
  }

  enum Action {
    case onAppear
    case tabSelected(Tab)
    case home(HomeFeature.Action)
    case library(LibraryFeature.Action)
    case adkhar(AdkharFeature.Action)
    case journeys(JourneysFeature.Action)
    case settings(SettingsFeature.Action)
    case auth(AuthFeature.Action)
    case authStateChanged(Bool)
  }

  var body: some ReducerOf<Self> {
    Reduce { state, action in
      switch action {
      case .onAppear:
        // Check authentication state on app launch
        return .none

      case .tabSelected(let tab):
        state.selectedTab = tab
        return .none

      case .authStateChanged(let isAuthenticated):
        state.isAuthenticated = isAuthenticated
        return .none

      // Handle navigation from Home
      case .home(.navigateToAdkhar):
        state.selectedTab = .adkhar
        return .none

      case .home(.navigateToLibrary):
        state.selectedTab = .library
        return .none

      case .home(.navigateToPractice(let timeSlot)):
        // Navigate to Adkhar with specific time slot filter
        state.selectedTab = .adkhar
        // TODO: Pass timeSlot to AdkharFeature
        return .none

      case .home, .library, .adkhar, .journeys, .settings, .auth:
        return .none
      }
    }

    Scope(state: \.home, action: \.home) {
      HomeFeature()
    }

    Scope(state: \.library, action: \.library) {
      LibraryFeature()
    }

    Scope(state: \.adkhar, action: \.adkhar) {
      AdkharFeature()
    }

    Scope(state: \.journeys, action: \.journeys) {
      JourneysFeature()
    }

    Scope(state: \.settings, action: \.settings) {
      SettingsFeature()
    }

    Scope(state: \.auth, action: \.auth) {
      AuthFeature()
    }
  }
}
