import ComposableArchitecture
import Foundation
import RIZQKit

/// Admin Users Feature - User management operations
@Reducer
struct AdminUsersFeature {
  @ObservableState
  struct State: Equatable {
    var users: [UserProfile] = []
    var searchQuery: String = ""
    var isLoading: Bool = false
    var errorMessage: String?
    var successMessage: String?

    // User detail
    var selectedUser: UserProfile?
    var isShowingUserDetail: Bool = false

    // Admin toggle confirmation
    var userToToggleAdmin: UserProfile?
    var isToggleAdminConfirmationPresented: Bool = false

    // Premium toggle confirmation
    var userToTogglePremium: UserProfile?
    var isTogglePremiumConfirmationPresented: Bool = false

    // Delete confirmation
    var userToDelete: UserProfile?
    var isDeleteConfirmationPresented: Bool = false

    // Filtered users based on search
    var filteredUsers: [UserProfile] {
      guard !searchQuery.isEmpty else { return users }
      let query = searchQuery.lowercased()
      return users.filter { user in
        user.displayName?.lowercased().contains(query) ?? false ||
        user.userId.lowercased().contains(query)
      }
    }

    // Stats
    var totalUsers: Int { users.count }
    var adminCount: Int { users.filter { $0.isAdmin }.count }
    var premiumCount: Int { users.filter { $0.isPremium }.count }
    var activeToday: Int { users.filter { isActiveToday($0) }.count }

    private func isActiveToday(_ user: UserProfile) -> Bool {
      guard let lastActive = user.lastActiveDate else { return false }
      return Calendar.current.isDateInToday(lastActive)
    }
  }

  enum Action: BindableAction {
    case binding(BindingAction<State>)
    case loadUsers
    case usersLoaded(Result<[UserProfile], Error>)

    // User detail
    case userTapped(UserProfile)
    case closeUserDetail

    // Admin toggle
    case toggleAdminTapped(UserProfile)
    case confirmToggleAdmin
    case cancelToggleAdmin
    case adminToggled(Result<UserProfile, Error>)

    // Premium toggle
    case togglePremiumTapped(UserProfile)
    case confirmTogglePremium
    case cancelTogglePremium
    case premiumToggled(Result<UserProfile, Error>)

    // Delete actions
    case deleteUserTapped(UserProfile)
    case confirmDelete
    case cancelDelete
    case userDeleted(Result<String, Error>)

    // Messages
    case dismissError
    case dismissSuccess
  }

  @Dependency(\.adminService) var adminService

  var body: some ReducerOf<Self> {
    BindingReducer()

    Reduce { state, action in
      switch action {
      case .binding:
        return .none

      case .loadUsers:
        state.isLoading = true
        state.errorMessage = nil
        return .run { send in
          do {
            let users = try await adminService.fetchAllUsersAdmin()
            await send(.usersLoaded(.success(users)))
          } catch {
            await send(.usersLoaded(.failure(error)))
          }
        }

      case .usersLoaded(.success(let users)):
        state.isLoading = false
        state.users = users
        return .none

      case .usersLoaded(.failure(let error)):
        state.isLoading = false
        state.errorMessage = error.localizedDescription
        return .none

      // MARK: - User Detail

      case .userTapped(let user):
        state.selectedUser = user
        state.isShowingUserDetail = true
        return .none

      case .closeUserDetail:
        state.isShowingUserDetail = false
        state.selectedUser = nil
        return .none

      // MARK: - Admin Toggle

      case .toggleAdminTapped(let user):
        state.userToToggleAdmin = user
        state.isToggleAdminConfirmationPresented = true
        return .none

      case .confirmToggleAdmin:
        guard let user = state.userToToggleAdmin else { return .none }
        state.isToggleAdminConfirmationPresented = false
        state.isLoading = true

        let userId = user.userId
        let newIsAdmin = !user.isAdmin

        return .run { send in
          do {
            let updatedUser = try await adminService.updateUserAdmin(userId: userId, isAdmin: newIsAdmin)
            await send(.adminToggled(.success(updatedUser)))
          } catch {
            await send(.adminToggled(.failure(error)))
          }
        }

      case .cancelToggleAdmin:
        state.isToggleAdminConfirmationPresented = false
        state.userToToggleAdmin = nil
        return .none

      case .adminToggled(.success(let updatedUser)):
        state.isLoading = false
        if let index = state.users.firstIndex(where: { $0.userId == updatedUser.userId }) {
          state.users[index] = updatedUser
        }
        // Update selected user if it's the same
        if state.selectedUser?.userId == updatedUser.userId {
          state.selectedUser = updatedUser
        }
        state.userToToggleAdmin = nil
        state.successMessage = updatedUser.isAdmin ? "User promoted to admin" : "Admin rights removed"
        return .none

      case .adminToggled(.failure(let error)):
        state.isLoading = false
        state.errorMessage = error.localizedDescription
        state.userToToggleAdmin = nil
        return .none

      // MARK: - Premium Toggle

      case .togglePremiumTapped(let user):
        state.userToTogglePremium = user
        state.isTogglePremiumConfirmationPresented = true
        return .none

      case .confirmTogglePremium:
        guard let user = state.userToTogglePremium else { return .none }
        state.isTogglePremiumConfirmationPresented = false
        state.isLoading = true

        let userId = user.userId
        let newIsPremium = !user.isPremium

        return .run { send in
          do {
            let updatedUser = try await adminService.updateUserPremium(userId: userId, isPremium: newIsPremium)
            await send(.premiumToggled(.success(updatedUser)))
          } catch {
            await send(.premiumToggled(.failure(error)))
          }
        }

      case .cancelTogglePremium:
        state.isTogglePremiumConfirmationPresented = false
        state.userToTogglePremium = nil
        return .none

      case .premiumToggled(.success(let updatedUser)):
        state.isLoading = false
        if let index = state.users.firstIndex(where: { $0.userId == updatedUser.userId }) {
          state.users[index] = updatedUser
        }
        // Update selected user if it's the same
        if state.selectedUser?.userId == updatedUser.userId {
          state.selectedUser = updatedUser
        }
        state.userToTogglePremium = nil
        state.successMessage = updatedUser.isPremium ? "User upgraded to premium" : "Premium status removed"
        return .none

      case .premiumToggled(.failure(let error)):
        state.isLoading = false
        state.errorMessage = error.localizedDescription
        state.userToTogglePremium = nil
        return .none

      // MARK: - Delete Actions

      case .deleteUserTapped(let user):
        state.userToDelete = user
        state.isDeleteConfirmationPresented = true
        return .none

      case .confirmDelete:
        guard let user = state.userToDelete else { return .none }
        state.isDeleteConfirmationPresented = false
        state.isLoading = true

        let userId = user.userId
        return .run { send in
          do {
            try await adminService.deleteUserAdmin(userId: userId)
            await send(.userDeleted(.success(userId)))
          } catch {
            await send(.userDeleted(.failure(error)))
          }
        }

      case .cancelDelete:
        state.isDeleteConfirmationPresented = false
        state.userToDelete = nil
        return .none

      case .userDeleted(.success(let userId)):
        state.isLoading = false
        state.users.removeAll { $0.userId == userId }
        state.userToDelete = nil
        // Close detail if showing deleted user
        if state.selectedUser?.userId == userId {
          state.isShowingUserDetail = false
          state.selectedUser = nil
        }
        state.successMessage = "User deleted successfully"
        return .none

      case .userDeleted(.failure(let error)):
        state.isLoading = false
        state.errorMessage = error.localizedDescription
        state.userToDelete = nil
        return .none

      // MARK: - Messages

      case .dismissError:
        state.errorMessage = nil
        return .none

      case .dismissSuccess:
        state.successMessage = nil
        return .none
      }
    }
  }
}
