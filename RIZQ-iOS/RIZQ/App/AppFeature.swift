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

    // Admin Panel Presentation
    @Presents var admin: AdminFeature.State?
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
    case userIdUpdated(String?)

    // Admin Panel
    case admin(PresentationAction<AdminFeature.Action>)
  }

  var body: some ReducerOf<Self> {
    Reduce { state, action in
      switch action {
      case .onAppear:
        // Check authentication state on app launch
        return .send(.auth(.checkExistingSession))

      case .tabSelected(let tab):
        state.selectedTab = tab
        // Notify features when their tab becomes active
        switch tab {
        case .adkhar:
          return .send(.adkhar(.becameActive))
        case .journeys:
          return .send(.journeys(.becameActive))
        default:
          return .none
        }

      case .authStateChanged(let isAuthenticated):
        state.isAuthenticated = isAuthenticated
        return .none

      case .userIdUpdated(let userId):
        // Pass user ID to child features that need it
        return .send(.home(.setUserId(userId)))

      // Handle navigation from Home
      case .home(.navigateToAdkhar):
        state.selectedTab = .adkhar
        return .send(.adkhar(.becameActive))

      case .home(.navigateToLibrary):
        state.selectedTab = .library
        return .none

      case .home(.navigateToJourneys):
        state.selectedTab = .journeys
        return .send(.journeys(.becameActive))

      case .home(.navigateToPractice(let timeSlot)):
        // Navigate to Adkhar with specific time slot filter
        state.selectedTab = .adkhar
        // TODO: Pass timeSlot to AdkharFeature
        return .send(.adkhar(.becameActive))

      // Handle navigation from Adkhar
      case .adkhar(.navigateToJourneys):
        state.selectedTab = .journeys
        return .send(.journeys(.becameActive))

      // Handle auth state changes
      case .auth(.authSuccess(let user)):
        state.isAuthenticated = true
        // Pass user ID to features that need it
        return .send(.userIdUpdated(user.id))

      case .settings(.signedOut):
        state.isAuthenticated = false
        state.auth = AuthFeature.State()  // Reset auth state
        return .none

      // MARK: - Admin Panel

      case .settings(.adminPanelTapped):
        state.admin = AdminFeature.State()
        return .none

      case .admin(.presented(.closeAdmin)):
        state.admin = nil
        return .none

      case .admin:
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

    .ifLet(\.$admin, action: \.admin) {
      AdminFeature()
    }
  }
}
