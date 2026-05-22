import ComposableArchitecture
import Foundation
import RIZQKit
import UserNotifications

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
    var notificationsEnabled: Bool = UserDefaults.standard.bool(forKey: "rizq_notifications_enabled")
    var soundEffectsEnabled: Bool = {
      // Default ON when the key has never been set (matches SoundPlayer)
      let key = SoundPlayer.soundEffectsEnabledKey
      if UserDefaults.standard.object(forKey: key) == nil { return true }
      return UserDefaults.standard.bool(forKey: key)
    }()

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
    case displayNameSaved(UserProfile)
    case displayNameSaveFailed(String)

    // Preferences
    case darkModeToggled(Bool)
    case notificationsToggled(Bool)
    case soundEffectsToggled(Bool)

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
    case progressReset(UserProfile)
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
  @Dependency(\.authClient) var authClient
  @Dependency(\.firestoreUserClient) var firestoreUserClient

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
        // Load real user data from AuthService and Firestore
        return .run { [authClient, firestoreUserClient] send in
          do {
            // Fetch the current authenticated user from Firebase Auth
            guard let user = try await authClient.getCurrentUser() else {
              await send(.loadFailed("Not authenticated"))
              return
            }
            await send(.userLoaded(user))

            // Fetch the user profile from Firestore (or create if doesn't exist)
            let profile = try await firestoreUserClient.getOrCreateUserProfile(user.id, user.name)
            await send(.profileLoaded(profile))

            // Fetch linked OAuth accounts from Firebase Auth
            let accounts = try await authClient.getLinkedAccounts()
            await send(.linkedAccountsLoaded(accounts))
          } catch {
            await send(.loadFailed(error.localizedDescription))
          }
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
        guard let userId = state.user?.id else {
          state.errorMessage = "Not authenticated"
          return .none
        }
        state.isSavingDisplayName = true
        let newName = state.editedDisplayName.trimmingCharacters(in: .whitespaces)
        return .run { [firestoreUserClient] send in
          do {
            let updatedProfile = try await firestoreUserClient.updateDisplayName(userId, newName)
            await send(.displayNameSaved(updatedProfile))
          } catch {
            await send(.displayNameSaveFailed(error.localizedDescription))
          }
        }

      case .displayNameSaved(let profile):
        state.isSavingDisplayName = false
        state.isEditingDisplayName = false
        state.profile = profile
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

      case .soundEffectsToggled(let isOn):
        state.soundEffectsEnabled = isOn
        UserDefaults.standard.set(isOn, forKey: SoundPlayer.soundEffectsEnabledKey)
        return .none

      case .notificationsToggled(let isOn):
        state.notificationsEnabled = isOn
        UserDefaults.standard.set(isOn, forKey: "rizq_notifications_enabled")
        if isOn {
          return .run { send in
            let center = UNUserNotificationCenter.current()
            let settings = await center.notificationSettings()
            if settings.authorizationStatus == .notDetermined {
              do {
                let granted = try await center.requestAuthorization(options: [.alert, .badge, .sound])
                if !granted {
                  await send(.notificationsToggled(false))
                }
              } catch {
                await send(.notificationsToggled(false))
              }
            } else if settings.authorizationStatus == .denied {
              // User previously denied - can't re-request, they need to go to Settings
              await send(.notificationsToggled(false))
            }
          }
        }
        return .none

      // MARK: - Linked Accounts

      case .linkAccountTapped(let provider):
        state.isLinkingAccount = provider
        return .run { [authClient] send in
          do {
            let account = try await authClient.linkAccount(provider)
            await send(.accountLinked(account))
          } catch {
            await send(.linkAccountFailed(error.localizedDescription))
          }
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
        return .run { [authClient, provider] send in
          do {
            try await authClient.unlinkAccount(provider)
            await send(.accountUnlinked(provider))
          } catch {
            await send(.unlinkAccountFailed(error.localizedDescription))
          }
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
        guard let userId = state.user?.id else {
          state.errorMessage = "Not authenticated"
          return .none
        }
        state.isResettingProgress = true
        return .run { [firestoreUserClient] send in
          do {
            let profile = try await firestoreUserClient.resetUserProgress(userId)
            await send(.progressReset(profile))
          } catch {
            await send(.resetProgressFailed(error.localizedDescription))
          }
        }

      case .cancelResetProgress:
        state.showingResetProgressAlert = false
        return .none

      case .progressReset(let profile):
        state.isResettingProgress = false
        state.profile = profile
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
        return .run { [authClient] send in
          do {
            try await authClient.signOut()
          } catch {
            // Sign out locally even if server call fails
          }
          await send(.signedOut)
        }

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
