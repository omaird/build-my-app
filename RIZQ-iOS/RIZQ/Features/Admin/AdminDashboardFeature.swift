import ComposableArchitecture
import Foundation
import RIZQKit

/// Admin Dashboard Feature - Overview of admin statistics
@Reducer
struct AdminDashboardFeature {
  @ObservableState
  struct State: Equatable {
    var stats: AdminStats = AdminStats()
    var isLoading: Bool = false
    var errorMessage: String?
  }

  enum Action {
    case loadStats
    case statsLoaded(Result<AdminStats, Error>)
    case navigateToSection(AdminFeature.AdminTab)
    case dismissError
  }

  @Dependency(\.adminService) var adminService

  var body: some ReducerOf<Self> {
    Reduce { state, action in
      switch action {
      case .loadStats:
        state.isLoading = true
        state.errorMessage = nil
        return .run { send in
          do {
            let stats = try await adminService.fetchAdminStats()
            await send(.statsLoaded(.success(stats)))
          } catch {
            await send(.statsLoaded(.failure(error)))
          }
        }

      case .statsLoaded(.success(let stats)):
        state.isLoading = false
        state.stats = stats
        return .none

      case .statsLoaded(.failure(let error)):
        state.isLoading = false
        state.errorMessage = error.localizedDescription
        return .none

      case .navigateToSection:
        // Handled by parent
        return .none

      case .dismissError:
        state.errorMessage = nil
        return .none
      }
    }
  }
}

// MARK: - Dependency

private enum AdminServiceKey: DependencyKey {
  // Use FirebaseAdminService for all admin operations
  // No longer requires Neon API configuration
  static let liveValue: any AdminServiceProtocol = FirebaseAdminService()

  static let testValue: any AdminServiceProtocol = MockAdminService()
  static let previewValue: any AdminServiceProtocol = MockAdminService()
}

extension DependencyValues {
  var adminService: any AdminServiceProtocol {
    get { self[AdminServiceKey.self] }
    set { self[AdminServiceKey.self] = newValue }
  }
}
