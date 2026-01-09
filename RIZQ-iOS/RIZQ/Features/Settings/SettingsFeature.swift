import ComposableArchitecture
import Foundation
import RIZQKit

@Reducer
struct SettingsFeature {
  @ObservableState
  struct State: Equatable {
    // User & Profile
    var user: AuthUser?
    var profile: UserProfile?
    var linkedAccounts: [LinkedAccount] = []

    // Edit Profile
    var isEditingDisplayName: Bool = false
    var editedDisplayName: String = ""
    var isSavingDisplayName: Bool = false

    // Preferences
    var isDarkMode: Bool = UserDefaults.standard.bool(forKey: "rizq_dark_mode")
    var notificationsEnabled: Bool = true

    // Loading States
    var isLoading: Bool = false
    var isLoadingAccounts: Bool = false
    var isLinkingAccount: AuthProvider? = nil
    var isUnlinkingAccount: AuthProvider? = nil

    // Alerts
    var showingSignOutAlert: Bool = false
    var showingUnlinkAlert: Bool = false
    var providerToUnlink: AuthProvider? = nil
    var showingResetProgressAlert: Bool = false
    var isResettingProgress: Bool = false

    // Error & Success
    var errorMessage: String? = nil
    var successMessage: String? = nil

    // Computed Properties
    var displayName: String {
      profile?.displayName ?? user?.name ?? "User"
    }

    var email: String {
      user?.email ?? ""
    }

    var profileImageUrl: String? {
      user?.image
    }

    var availableProviders: [AuthProvider] {
      [.google]
    }

    var canUnlinkAccount: Bool {
      linkedAccounts.count > 1
    }

    func isProviderLinked(_ provider: AuthProvider) -> Bool {
      linkedAccounts.contains { $0.provider == provider }
    }
  }

  enum Action: BindableAction {
    case binding(BindingAction<State>)

    // Lifecycle
    case onAppear
    case refreshData

    // Profile Loading
    case userLoaded(AuthUser)
    case profileLoaded(UserProfile)
    case linkedAccountsLoaded([LinkedAccount])
    case loadFailed(String)

    // Display Name Editing
    case editDisplayNameTapped
    case cancelEditDisplayName
    case saveDisplayNameTapped
    case displayNameSaved(String)
    case displayNameSaveFailed(String)

    // Preferences
    case darkModeToggled(Bool)
    case notificationsToggled(Bool)

    // Linked Accounts
    case linkAccountTapped(AuthProvider)
    case unlinkAccountTapped(AuthProvider)
    case confirmUnlinkAccount
    case cancelUnlinkAccount
    case accountLinked(LinkedAccount)
    case accountUnlinked(AuthProvider)
    case linkAccountFailed(String)
    case unlinkAccountFailed(String)

    // Reset Progress
    case resetProgressTapped
    case confirmResetProgress
    case cancelResetProgress
    case progressReset
    case resetProgressFailed(String)

    // Sign Out
    case signOutTapped
    case confirmSignOut
    case cancelSignOut
    case signedOut

    // Admin
    case adminPanelTapped

    // Messages
    case clearError
    case clearSuccess
  }

  @Dependency(\.continuousClock) var clock

  var body: some ReducerOf<Self> {
    BindingReducer()

    Reduce { state, action in
      switch action {
      case .binding:
        return .none

      // MARK: - Lifecycle

      case .onAppear:
        state.isLoading = true
        state.isLoadingAccounts = true
        // Load persisted dark mode preference
        state.isDarkMode = UserDefaults.standard.bool(forKey: "rizq_dark_mode")
        // TODO: Load user data from AuthService
        // For now, simulate loading with demo data
        return .run { send in
          try await clock.sleep(for: .milliseconds(500))

          let demoUser = AuthUser(
            id: "demo-user-001",
            email: "omairdawood@gmail.com",
            name: "Omar Dawood",
            image: nil,
            emailVerified: true
          )
          await send(.userLoaded(demoUser))

          let demoProfile = UserProfile(
            id: "profile-001",
            userId: "demo-user-001",
            displayName: "Omar Dawood",
            streak: 5,
            totalXp: 350,
            level: 2,
            isAdmin: true  // Enable admin access for testing
          )
          await send(.profileLoaded(demoProfile))

          let demoAccounts: [LinkedAccount] = [
            LinkedAccount(
              id: "account-001",
              provider: .google,
              providerAccountId: "google-123"
            )
          ]
          await send(.linkedAccountsLoaded(demoAccounts))
        }

      case .refreshData:
        return .send(.onAppear)

      // MARK: - Profile Loading

      case .userLoaded(let user):
        state.isLoading = false
        state.user = user
        return .none

      case .profileLoaded(let profile):
        state.profile = profile
        return .none

      case .linkedAccountsLoaded(let accounts):
        state.isLoadingAccounts = false
        state.linkedAccounts = accounts
        return .none

      case .loadFailed(let message):
        state.isLoading = false
        state.isLoadingAccounts = false
        state.errorMessage = message
        return .none

      // MARK: - Display Name Editing

      case .editDisplayNameTapped:
        state.isEditingDisplayName = true
        state.editedDisplayName = state.displayName
        return .none

      case .cancelEditDisplayName:
        state.isEditingDisplayName = false
        state.editedDisplayName = ""
        return .none

      case .saveDisplayNameTapped:
        guard !state.editedDisplayName.trimmingCharacters(in: .whitespaces).isEmpty else {
          state.errorMessage = "Display name cannot be empty"
          return .none
        }
        state.isSavingDisplayName = true
        let newName = state.editedDisplayName.trimmingCharacters(in: .whitespaces)
        // TODO: Save to server
        return .run { send in
          try await clock.sleep(for: .milliseconds(300))
          await send(.displayNameSaved(newName))
        }

      case .displayNameSaved(let newName):
        state.isSavingDisplayName = false
        state.isEditingDisplayName = false
        if var profile = state.profile {
          state.profile = UserProfile(
            id: profile.id,
            userId: profile.userId,
            displayName: newName,
            streak: profile.streak,
            totalXp: profile.totalXp,
            level: profile.level,
            lastActiveDate: profile.lastActiveDate,
            isAdmin: profile.isAdmin,
            createdAt: profile.createdAt,
            updatedAt: Date()
          )
        }
        state.successMessage = "Display name updated"
        state.editedDisplayName = ""
        return .run { send in
          try await clock.sleep(for: .seconds(3))
          await send(.clearSuccess)
        }

      case .displayNameSaveFailed(let message):
        state.isSavingDisplayName = false
        state.errorMessage = message
        return .none

      // MARK: - Preferences

      case .darkModeToggled(let isOn):
        state.isDarkMode = isOn
        UserDefaults.standard.set(isOn, forKey: "rizq_dark_mode")
        return .none

      case .notificationsToggled(let isOn):
        state.notificationsEnabled = isOn
        // TODO: Request notification permissions if enabling
        return .none

      // MARK: - Linked Accounts

      case .linkAccountTapped(let provider):
        state.isLinkingAccount = provider
        // TODO: Initiate OAuth flow via AuthService
        return .run { send in
          try await clock.sleep(for: .seconds(1))
          let newAccount = LinkedAccount(
            id: UUID().uuidString,
            provider: provider,
            providerAccountId: "\(provider.rawValue)-\(UUID().uuidString.prefix(8))"
          )
          await send(.accountLinked(newAccount))
        }

      case .unlinkAccountTapped(let provider):
        guard state.canUnlinkAccount else {
          state.errorMessage = "You must have at least one linked account"
          return .none
        }
        state.providerToUnlink = provider
        state.showingUnlinkAlert = true
        return .none

      case .confirmUnlinkAccount:
        state.showingUnlinkAlert = false
        guard let provider = state.providerToUnlink else { return .none }
        state.isUnlinkingAccount = provider
        // TODO: Unlink via AuthService
        return .run { [provider] send in
          try await clock.sleep(for: .milliseconds(500))
          await send(.accountUnlinked(provider))
        }

      case .cancelUnlinkAccount:
        state.showingUnlinkAlert = false
        state.providerToUnlink = nil
        return .none

      case .accountLinked(let account):
        state.isLinkingAccount = nil
        state.linkedAccounts.append(account)
        state.successMessage = "\(account.provider.displayName) account linked"
        return .run { send in
          try await clock.sleep(for: .seconds(3))
          await send(.clearSuccess)
        }

      case .accountUnlinked(let provider):
        state.isUnlinkingAccount = nil
        state.providerToUnlink = nil
        state.linkedAccounts.removeAll { $0.provider == provider }
        state.successMessage = "\(provider.displayName) account unlinked"
        return .run { send in
          try await clock.sleep(for: .seconds(3))
          await send(.clearSuccess)
        }

      case .linkAccountFailed(let message):
        state.isLinkingAccount = nil
        state.errorMessage = message
        return .none

      case .unlinkAccountFailed(let message):
        state.isUnlinkingAccount = nil
        state.errorMessage = message
        return .none

      // MARK: - Reset Progress

      case .resetProgressTapped:
        state.showingResetProgressAlert = true
        return .none

      case .confirmResetProgress:
        state.showingResetProgressAlert = false
        state.isResettingProgress = true
        // TODO: Reset progress via API
        return .run { send in
          try await clock.sleep(for: .milliseconds(500))
          await send(.progressReset)
        }

      case .cancelResetProgress:
        state.showingResetProgressAlert = false
        return .none

      case .progressReset:
        state.isResettingProgress = false
        if let profile = state.profile {
          state.profile = UserProfile(
            id: profile.id,
            userId: profile.userId,
            displayName: profile.displayName,
            streak: 0,
            totalXp: 0,
            level: 1,
            lastActiveDate: nil,
            isAdmin: profile.isAdmin,
            createdAt: profile.createdAt,
            updatedAt: Date()
          )
        }
        state.successMessage = "Progress has been reset"
        return .run { send in
          try await clock.sleep(for: .seconds(3))
          await send(.clearSuccess)
        }

      case .resetProgressFailed(let message):
        state.isResettingProgress = false
        state.errorMessage = message
        return .none

      // MARK: - Sign Out

      case .signOutTapped:
        state.showingSignOutAlert = true
        return .none

      case .confirmSignOut:
        state.showingSignOutAlert = false
        // TODO: Clear keychain and user data via AuthService
        return .send(.signedOut)

      case .cancelSignOut:
        state.showingSignOutAlert = false
        return .none

      case .signedOut:
        // Parent reducer should handle navigation to auth screen
        return .none

      // MARK: - Admin

      case .adminPanelTapped:
        // Parent reducer (AppFeature) will handle showing the admin panel
        return .none

      // MARK: - Messages

      case .clearError:
        state.errorMessage = nil
        return .none

      case .clearSuccess:
        state.successMessage = nil
        return .none
      }
    }
  }
}
