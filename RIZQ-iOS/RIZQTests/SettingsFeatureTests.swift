import XCTest
import ComposableArchitecture
@testable import RIZQKit
@testable import RIZQ

@MainActor
final class SettingsFeatureTests: XCTestCase {

  // MARK: - Helpers

  private let fixedDate = Date(timeIntervalSince1970: 1_000_000)

  private func makeProfile(
    displayName: String? = "Original Name",
    streak: Int = 5,
    totalXp: Int = 100,
    level: Int = 2,
    lastActiveDate: Date? = nil,
    isAdmin: Bool = false
  ) -> UserProfile {
    UserProfile(
      id: "test",
      userId: "test",
      displayName: displayName,
      streak: streak,
      totalXp: totalXp,
      level: level,
      lastActiveDate: lastActiveDate,
      isAdmin: isAdmin,
      createdAt: fixedDate,
      updatedAt: fixedDate
    )
  }

  private func makeUser(
    name: String? = "Test"
  ) -> AuthUser {
    AuthUser(id: "test", email: "test@example.com", name: name)
  }

  // MARK: - Display Name Tests

  func testEditDisplayNameTapped() async {
    var initialState = SettingsFeature.State()
    initialState.profile = makeProfile()

    let store = TestStore(initialState: initialState) {
      SettingsFeature()
    }

    await store.send(.editDisplayNameTapped) {
      $0.isEditingDisplayName = true
      $0.editedDisplayName = "Original Name"
    }
  }

  func testCancelEditDisplayName() async {
    var initialState = SettingsFeature.State()
    initialState.isEditingDisplayName = true
    initialState.editedDisplayName = "New Name"

    let store = TestStore(initialState: initialState) {
      SettingsFeature()
    }

    await store.send(.cancelEditDisplayName) {
      $0.isEditingDisplayName = false
      $0.editedDisplayName = ""
    }
  }

  func testSaveDisplayNameEmpty() async {
    var initialState = SettingsFeature.State()
    initialState.editedDisplayName = "   "

    let store = TestStore(initialState: initialState) {
      SettingsFeature()
    }

    await store.send(.saveDisplayNameTapped) {
      $0.errorMessage = "Display name cannot be empty"
    }
  }

  func testSaveDisplayNameNotAuthenticated() async {
    var initialState = SettingsFeature.State()
    initialState.editedDisplayName = "New Name"
    initialState.user = nil

    let store = TestStore(initialState: initialState) {
      SettingsFeature()
    }

    await store.send(.saveDisplayNameTapped) {
      $0.errorMessage = "Not authenticated"
    }
  }

  func testSaveDisplayNameSuccess() async {
    let updatedProfile = makeProfile(displayName: "New Name")

    var initialState = SettingsFeature.State()
    initialState.user = makeUser()
    initialState.profile = makeProfile(displayName: "Original")
    initialState.editedDisplayName = "New Name"

    let store = TestStore(initialState: initialState) {
      SettingsFeature()
    } withDependencies: {
      $0.firestoreUserClient.updateDisplayName = { _, _ in updatedProfile }
      $0.continuousClock = ImmediateClock()
    }

    await store.send(.saveDisplayNameTapped) {
      $0.isSavingDisplayName = true
    }

    await store.receive(\.displayNameSaved) {
      $0.isSavingDisplayName = false
      $0.isEditingDisplayName = false
      $0.profile = updatedProfile
      $0.successMessage = "Display name updated"
      $0.editedDisplayName = ""
    }

    await store.receive(\.clearSuccess) {
      $0.successMessage = nil
    }
  }

  // MARK: - Preference Tests

  func testDarkModeToggled() async {
    let store = TestStore(initialState: SettingsFeature.State()) {
      SettingsFeature()
    }

    await store.send(.darkModeToggled(true)) {
      $0.isDarkMode = true
    }

    await store.send(.darkModeToggled(false)) {
      $0.isDarkMode = false
    }
  }

  // MARK: - Account Linking Tests

  func testLinkAccountSuccess() async {
    let linkedAccount = LinkedAccount(
      id: "google-123",
      provider: .google,
      providerAccountId: "google-user-123"
    )

    let store = TestStore(initialState: SettingsFeature.State()) {
      SettingsFeature()
    } withDependencies: {
      $0.authClient.linkAccount = { _ in linkedAccount }
      $0.continuousClock = ImmediateClock()
    }

    await store.send(.linkAccountTapped(.google)) {
      $0.isLinkingAccount = .google
    }

    await store.receive(\.accountLinked) {
      $0.isLinkingAccount = nil
      $0.linkedAccounts = [linkedAccount]
      $0.successMessage = "Google account linked"
    }

    await store.receive(\.clearSuccess) {
      $0.successMessage = nil
    }
  }

  func testLinkAccountFailure() async {
    struct LinkError: Error, LocalizedError {
      var errorDescription: String? { "Link failed" }
    }

    let store = TestStore(initialState: SettingsFeature.State()) {
      SettingsFeature()
    } withDependencies: {
      $0.authClient.linkAccount = { _ in throw LinkError() }
    }

    await store.send(.linkAccountTapped(.google)) {
      $0.isLinkingAccount = .google
    }

    await store.receive(\.linkAccountFailed) {
      $0.isLinkingAccount = nil
      $0.errorMessage = "Link failed"
    }
  }

  func testUnlinkAccountNotAllowed() async {
    var initialState = SettingsFeature.State()
    initialState.linkedAccounts = [
      LinkedAccount(id: "1", provider: .google, providerAccountId: "google-123")
    ]

    let store = TestStore(initialState: initialState) {
      SettingsFeature()
    }

    await store.send(.unlinkAccountTapped(.google)) {
      $0.errorMessage = "You must have at least one linked account"
    }
  }

  func testUnlinkAccountSuccess() async {
    let googleAccount = LinkedAccount(id: "1", provider: .google, providerAccountId: "google-123")
    let githubAccount = LinkedAccount(id: "2", provider: .github, providerAccountId: "github-123")

    var initialState = SettingsFeature.State()
    initialState.linkedAccounts = [googleAccount, githubAccount]

    let store = TestStore(initialState: initialState) {
      SettingsFeature()
    } withDependencies: {
      $0.authClient.unlinkAccount = { _ in }
      $0.continuousClock = ImmediateClock()
    }

    await store.send(.unlinkAccountTapped(.google)) {
      $0.providerToUnlink = .google
      $0.showingUnlinkAlert = true
    }

    await store.send(.confirmUnlinkAccount) {
      $0.showingUnlinkAlert = false
      $0.isUnlinkingAccount = .google
    }

    await store.receive(\.accountUnlinked) {
      $0.isUnlinkingAccount = nil
      $0.providerToUnlink = nil
      $0.linkedAccounts = [githubAccount]
      $0.successMessage = "Google account unlinked"
    }

    await store.receive(\.clearSuccess) {
      $0.successMessage = nil
    }
  }

  // MARK: - Reset Progress Tests

  func testResetProgressFlow() async {
    let resetProfile = makeProfile(
      displayName: "Test User",
      streak: 0,
      totalXp: 0,
      level: 1,
      lastActiveDate: nil
    )

    var initialState = SettingsFeature.State()
    initialState.user = makeUser(name: nil)
    initialState.profile = makeProfile(
      displayName: "Test User",
      streak: 10,
      totalXp: 500,
      level: 5,
      lastActiveDate: fixedDate
    )

    let store = TestStore(initialState: initialState) {
      SettingsFeature()
    } withDependencies: {
      $0.firestoreUserClient.resetUserProgress = { _ in resetProfile }
      $0.continuousClock = ImmediateClock()
    }

    await store.send(.resetProgressTapped) {
      $0.showingResetProgressAlert = true
    }

    await store.send(.confirmResetProgress) {
      $0.showingResetProgressAlert = false
      $0.isResettingProgress = true
    }

    await store.receive(\.progressReset) {
      $0.isResettingProgress = false
      $0.profile = resetProfile
      $0.successMessage = "Progress has been reset"
    }

    await store.receive(\.clearSuccess) {
      $0.successMessage = nil
    }
  }

  func testCancelResetProgress() async {
    var initialState = SettingsFeature.State()
    initialState.showingResetProgressAlert = true

    let store = TestStore(initialState: initialState) {
      SettingsFeature()
    }

    await store.send(.cancelResetProgress) {
      $0.showingResetProgressAlert = false
    }
  }

  // MARK: - Sign Out Tests

  func testSignOutFlow() async {
    var initialState = SettingsFeature.State()
    initialState.user = makeUser()

    let store = TestStore(initialState: initialState) {
      SettingsFeature()
    } withDependencies: {
      $0.authClient.signOut = { }
    }

    await store.send(.signOutTapped) {
      $0.showingSignOutAlert = true
    }

    await store.send(.confirmSignOut) {
      $0.showingSignOutAlert = false
    }

    await store.receive(\.signedOut)
  }

  func testCancelSignOut() async {
    var initialState = SettingsFeature.State()
    initialState.showingSignOutAlert = true

    let store = TestStore(initialState: initialState) {
      SettingsFeature()
    }

    await store.send(.cancelSignOut) {
      $0.showingSignOutAlert = false
    }
  }

  // MARK: - Error/Success Message Tests

  func testClearError() async {
    var initialState = SettingsFeature.State()
    initialState.errorMessage = "Some error"

    let store = TestStore(initialState: initialState) {
      SettingsFeature()
    }

    await store.send(.clearError) {
      $0.errorMessage = nil
    }
  }

  func testClearSuccess() async {
    var initialState = SettingsFeature.State()
    initialState.successMessage = "Success!"

    let store = TestStore(initialState: initialState) {
      SettingsFeature()
    }

    await store.send(.clearSuccess) {
      $0.successMessage = nil
    }
  }
}
