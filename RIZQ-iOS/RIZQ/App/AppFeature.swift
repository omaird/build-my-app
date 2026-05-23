import ComposableArchitecture
import Foundation
import os.log
import RIZQKit

private let appLogger = Logger(subsystem: "com.rizq.app", category: "AppFeature")

@Reducer
struct AppFeature {
  @ObservableState
  struct State: Equatable {
    var selectedTab: Tab = .home
    var isAuthenticated: Bool = false
    /// Shared read-only content (duas/journeys/categories) fetched once on launch
    /// and refreshable on demand. Child features consume this instead of fetching
    /// independently.
    var content = ContentFeature.State()
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
    case journeys
    case adkhar
    case library
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
    case content(ContentFeature.Action)
    case home(HomeFeature.Action)
    case library(LibraryFeature.Action)
    case adkhar(AdkharFeature.Action)
    case journeys(JourneysFeature.Action)
    case settings(SettingsFeature.Action)
    case auth(AuthFeature.Action)
    case authStateChanged(Bool)
    case userIdUpdated(String?)
    case authUserUpdated(id: String, name: String?, imageURL: String?)

    // Admin Panel
    case admin(PresentationAction<AdminFeature.Action>)
  }

  var body: some ReducerOf<Self> {
    Reduce { state, action in
      switch action {
      case .onAppear:
        // Check authentication state on app launch and kick off the shared
        // content fetch in parallel.
        return .merge(
          .send(.auth(.checkExistingSession)),
          .send(.content(.task))
        )

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
        // Pass user ID to child features that need it (legacy, use setAuthUser instead)
        return .send(.home(.setUserId(userId)))

      case .authUserUpdated(let id, let name, let imageURL):
        // Pass full auth user info to Home for display name and profile picture
        return .send(.home(.setAuthUser(id: id, name: name, imageURL: imageURL)))

      // Handle navigation from Home
      case .home(.navigateToAdkhar):
        state.selectedTab = .adkhar
        return .send(.adkhar(.becameActive))

      case .home(.navigateToLibrary):
        state.selectedTab = .library
        return .none

      case .home(.navigateToJourneys):
        state.selectedTab = .journeys
        return .run { send in
          try? await Task.sleep(for: .milliseconds(100))
          await send(.journeys(.becameActive))
        }

      case .home(.navigateToPractice(let timeSlot)):
        // Navigate to Adkhar with specific time slot filter
        state.selectedTab = .adkhar
        // First refresh the data, then set the filter for auto-scroll
        return .merge(
          .send(.adkhar(.becameActive)),
          .send(.adkhar(.filterByTimeSlot(timeSlot)))
        )

      // Handle navigation from Adkhar
      case .adkhar(.navigateToJourneys):
        state.selectedTab = .journeys
        // Send becameActive after a short delay to ensure tab switch completes.
        return .run { send in
          try? await Task.sleep(for: .milliseconds(100))
          await send(.journeys(.becameActive))
        }

      // Handle auth state changes
      case .auth(.authSuccess(let user)):
        state.isAuthenticated = true
        // Pass full auth user info (name, photo) to Home for personalized display
        return .send(.authUserUpdated(id: user.id, name: user.name, imageURL: user.image))

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

      // Forward ContentFeature loads down to child features. Each child gets a
      // single setter action; this is the parent-forwarding pattern in lieu of
      // children peeking at sibling state.
      //
      // Note on Adkhar/Home: they need duas AND journey-dua mappings together
      // to compute habit lists, but the two fetches resolve independently. We
      // forward on each event using the action payload for the freshly-arrived
      // value and `state.content.{other}` for whatever's already settled. The
      // last forward of a given fetch cycle has both values populated.
      case let .content(.duasLoaded(duas)):
        return .merge(
          .send(.library(.contentDuasUpdated(duas))),
          .send(.adkhar(.contentUpdated(duas: duas, journeyDuas: state.content.journeyDuas))),
          .send(.home(.contentUpdated(duas: duas, journeyDuas: state.content.journeyDuas)))
        )

      case let .content(.journeysLoaded(journeys)):
        return .send(.journeys(.contentJourneysUpdated(journeys)))

      case let .content(.categoriesLoaded(categories)):
        // Library uses this to build a slug→id map for in-memory filtering
        // (replaces previously-hardcoded category-id literals).
        return .send(.library(.contentCategoriesUpdated(categories)))

      case let .content(.journeyDuasLoaded(mappings)):
        return .merge(
          .send(.adkhar(.contentUpdated(duas: state.content.duas, journeyDuas: mappings))),
          .send(.home(.contentUpdated(duas: state.content.duas, journeyDuas: mappings)))
        )

      case .content(.loadFailed(.duasFailed)),
           .content(.loadFailed(.categoriesFailed)),
           .content(.loadFailed(.journeyDuasFailed)):
        // No per-feature error surface for these yet — logged at ContentFeature.
        return .none

      case .content(.loadFailed(.journeysFailed)):
        return .send(.journeys(.contentJourneysFailed("Couldn't reach the network")))

      // Retry from a child fans out to a real content refresh.
      case .library(.retryTapped), .journeys(.refreshJourneys):
        return .send(.content(.refresh))

      case .content, .home, .library, .adkhar, .journeys, .settings, .auth:
        return .none
      }
    }

    Scope(state: \.content, action: \.content) {
      ContentFeature()
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
