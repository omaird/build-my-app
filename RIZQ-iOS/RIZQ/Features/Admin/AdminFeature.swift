import ComposableArchitecture
import Foundation

/// Root Admin Feature with tab navigation
@Reducer
struct AdminFeature {
  @ObservableState
  struct State: Equatable {
    var selectedTab: AdminTab = .dashboard
    var dashboard = AdminDashboardFeature.State()
    var duas = AdminDuasFeature.State()
    var journeys = AdminJourneysFeature.State()
    var categories = AdminCategoriesFeature.State()
    var users = AdminUsersFeature.State()
    var isShowingAdmin: Bool = true
  }

  enum AdminTab: String, CaseIterable, Identifiable {
    case dashboard
    case duas
    case journeys
    case categories
    case users

    var id: String { rawValue }

    var title: String {
      switch self {
      case .dashboard: return "Dashboard"
      case .duas: return "Duas"
      case .journeys: return "Journeys"
      case .categories: return "Categories"
      case .users: return "Users"
      }
    }

    var icon: String {
      switch self {
      case .dashboard: return "chart.bar.fill"
      case .duas: return "book.fill"
      case .journeys: return "map.fill"
      case .categories: return "tag.fill"
      case .users: return "person.2.fill"
      }
    }

    var description: String {
      switch self {
      case .dashboard: return "Overview & stats"
      case .duas: return "Manage supplications"
      case .journeys: return "Manage dua collections"
      case .categories: return "Organize duas"
      case .users: return "Manage users"
      }
    }
  }

  enum Action {
    case onAppear
    case tabSelected(AdminTab)
    case closeAdmin
    case dashboard(AdminDashboardFeature.Action)
    case duas(AdminDuasFeature.Action)
    case journeys(AdminJourneysFeature.Action)
    case categories(AdminCategoriesFeature.Action)
    case users(AdminUsersFeature.Action)
  }

  var body: some ReducerOf<Self> {
    Reduce { state, action in
      switch action {
      case .onAppear:
        // Load initial data for dashboard
        return .send(.dashboard(.loadStats))

      case .tabSelected(let tab):
        state.selectedTab = tab

        // Load data for the selected tab
        switch tab {
        case .dashboard:
          return .send(.dashboard(.loadStats))
        case .duas:
          return .send(.duas(.loadDuas))
        case .journeys:
          return .send(.journeys(.loadJourneys))
        case .categories:
          return .send(.categories(.loadCategories))
        case .users:
          return .send(.users(.loadUsers))
        }

      case .closeAdmin:
        state.isShowingAdmin = false
        return .none

      case .dashboard, .duas, .journeys, .categories, .users:
        return .none
      }
    }

    Scope(state: \.dashboard, action: \.dashboard) {
      AdminDashboardFeature()
    }

    Scope(state: \.duas, action: \.duas) {
      AdminDuasFeature()
    }

    Scope(state: \.journeys, action: \.journeys) {
      AdminJourneysFeature()
    }

    Scope(state: \.categories, action: \.categories) {
      AdminCategoriesFeature()
    }

    Scope(state: \.users, action: \.users) {
      AdminUsersFeature()
    }
  }
}
