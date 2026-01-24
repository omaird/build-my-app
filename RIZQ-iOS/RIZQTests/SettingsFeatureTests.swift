import XCTest
import ComposableArchitecture
@testable import RIZQKit
@testable import RIZQ

@MainActor
final class SettingsFeatureTests: XCTestCase {

  // MARK: - Display Name Tests

  func testEditDisplayNameTapped() async {
    let store = TestStore(initialState: SettingsFeature.State()) {
      SettingsFeature()
    }

    store.state.profile = UserProfile(
      id: "test",
      userId: "test",
      displayName: "Original Name",
      streak: 5,
      totalXp: 100,
      level: 2,
      lastActiveDate: nil,
      isAdmin: false,
      createdAt: Date(),
      updatedAt: Date()
    )

    await store.send(.editDisplayNameTapped) {
      $0.isEditingDisplayName = true
      $0.editedDisplayName = "Original Name"
    }
  }

  func testCancelEditDisplayName() async {
    let store = TestStore(initialState: SettingsFeature.State()) {
      SettingsFeature()
    }

    store.state.isEditingDisplayName = true
    store.state.editedDisplayName = "New Name"

    await store.send(.cancelEditDisplayName) {
      $0.isEditingDisplayName = false
      $0.editedDisplayName = ""
    }
  }

  func testSaveDisplayNameEmpty() async {
    let store = TestStore(initialState: SettingsFeature.State()) {
      SettingsFeature()
    }

    store.state.editedDisplayName = "   "

    await store.send(.saveDisplayNameTapped) {
      $0.errorMessage = "Display name cannot be empty"
    }
  }

  func testSaveDisplayNameNotAuthenticated() async {
    let store = TestStore(initialState: SettingsFeature.State()) {
      SettingsFeature()
    }

    store.state.editedDisplayName = "New Name"
    store.state.user = nil

    await store.send(.saveDisplayNameTapped) {
      $0.errorMessage = "Not authenticated"
    }
  }

  func testSaveDisplayNameSuccess() async {
    let store = TestStore(initialState: SettingsFeature.State()) {
      SettingsFeature()
    } withDependencies: {
      $0.firestoreUserClient.updateDisplayName = { _, newName in
        UserProfile(
          id: "test",
          userId: "test",
          displayName: newName,
          streak: 5,
          totalXp: 100,
          level: 2,
          lastActiveDate: nil,
          isAdmin: false,
          createdAt: Date(),
          updatedAt: Date()
        )
      }
      $0.continuousClock = ImmediateClock()
    }

    store.state.user = AuthUser(id: "test", email: "test@example.com", name: "Test")
    store.state.profile = UserProfile(
      id: "test",
      userId: "test",
      displayName: "Original",
      streak: 5,
      totalXp: 100,
      level: 2,
      lastActiveDate: nil,
      isAdmin: false,
      createdAt: Date(),
      updatedAt: Date()
    )
    store.state.editedDisplayName = "New Name"

    await store.send(.saveDisplayNameTapped) {
      $0.isSavingDisplayName = true
    }

    await store.receive(.displayNameSaved("New Name")) {
      $0.isSavingDisplayName = false
      $0.isEditingDisplayName = false
      $0.profile?.displayName = "New Name"
      $0.successMessage = "Display name updated"
      $0.editedDisplayName = ""
    }

    await store.receive(.clearSuccess) {
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

    await store.receive(.accountLinked(linkedAccount)) {
      $0.isLinkingAccount = nil
      $0.linkedAccounts = [linkedAccount]
      $0.successMessage = "Google account linked"
    }

    await store.receive(.clearSuccess) {
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

    await store.receive(.linkAccountFailed("Link failed")) {
      $0.isLinkingAccount = nil
      $0.errorMessage = "Link failed"
    }
  }

  func testUnlinkAccountNotAllowed() async {
    let store = TestStore(initialState: SettingsFeature.State()) {
      SettingsFeature()
    }

    // Only one linked account - shouldn't be able to unlink
    store.state.linkedAccounts = [
      LinkedAccount(id: "1", provider: .google, providerAccountId: "google-123")
    ]

    await store.send(.unlinkAccountTapped(.google)) {
      $0.errorMessage = "You must have at least one linked account"
    }
  }

  func testUnlinkAccountSuccess() async {
    let store = TestStore(initialState: SettingsFeature.State()) {
      SettingsFeature()
    } withDependencies: {
      $0.authClient.unlinkAccount = { _ in }
      $0.continuousClock = ImmediateClock()
    }

    // Two linked accounts - can unlink one
    store.state.linkedAccounts = [
      LinkedAccount(id: "1", provider: .google, providerAccountId: "google-123"),
      LinkedAccount(id: "2", provider: .github, providerAccountId: "github-123")
    ]

    await store.send(.unlinkAccountTapped(.google)) {
      $0.providerToUnlink = .google
      $0.showingUnlinkAlert = true
    }

    await store.send(.confirmUnlinkAccount) {
      $0.showingUnlinkAlert = false
      $0.isUnlinkingAccount = .google
    }

    await store.receive(.accountUnlinked(.google)) {
      $0.isUnlinkingAccount = nil
      $0.providerToUnlink = nil
      $0.linkedAccounts = [
        LinkedAccount(id: "2", provider: .github, providerAccountId: "github-123")
      ]
      $0.successMessage = "Google account unlinked"
    }

    await store.receive(.clearSuccess) {
      $0.successMessage = nil
    }
  }

  // MARK: - Reset Progress Tests

  func testResetProgressFlow() async {
    let store = TestStore(initialState: SettingsFeature.State()) {
      SettingsFeature()
    } withDependencies: {
      $0.firestoreUserClient.resetUserProgress = { userId in
        UserProfile(
          id: userId,
          userId: userId,
          displayName: nil,
          streak: 0,
          totalXp: 0,
          level: 1,
          lastActiveDate: nil,
          isAdmin: false,
          createdAt: Date(),
          updatedAt: Date()
        )
      }
      $0.continuousClock = ImmediateClock()
    }

    store.state.user = AuthUser(id: "test", email: "test@example.com", name: nil)
    store.state.profile = UserProfile(
      id: "test",
      userId: "test",
      displayName: "Test User",
      streak: 10,
      totalXp: 500,
      level: 5,
      lastActiveDate: Date(),
      isAdmin: false,
      createdAt: Date(),
      updatedAt: Date()
    )

    await store.send(.resetProgressTapped) {
      $0.showingResetProgressAlert = true
    }

    await store.send(.confirmResetProgress) {
      $0.showingResetProgressAlert = false
      $0.isResettingProgress = true
    }

    await store.receive(.progressReset) {
      $0.isResettingProgress = false
      $0.profile = UserProfile(
        id: $0.profile!.id,
        userId: $0.profile!.userId,
        displayName: $0.profile!.displayName,
        streak: 0,
        totalXp: 0,
        level: 1,
        lastActiveDate: nil,
        isAdmin: $0.profile!.isAdmin,
        createdAt: $0.profile!.createdAt,
        updatedAt: $0.profile!.updatedAt
      )
      $0.successMessage = "Progress has been reset"
    }

    await store.receive(.clearSuccess) {
      $0.successMessage = nil
    }
  }

  func testCancelResetProgress() async {
    let store = TestStore(initialState: SettingsFeature.State()) {
      SettingsFeature()
    }

    store.state.showingResetProgressAlert = true

    await store.send(.cancelResetProgress) {
      $0.showingResetProgressAlert = false
    }
  }

  // MARK: - Sign Out Tests

  func testSignOutFlow() async {
    let store = TestStore(initialState: SettingsFeature.State()) {
      SettingsFeature()
    } withDependencies: {
      $0.authClient.signOut = { }
    }

    store.state.user = AuthUser(id: "test", email: "test@example.com", name: "Test")

    await store.send(.signOutTapped) {
      $0.showingSignOutAlert = true
    }

    await store.send(.confirmSignOut) {
      $0.showingSignOutAlert = false
    }

    await store.receive(.signedOut)
  }

  func testCancelSignOut() async {
    let store = TestStore(initialState: SettingsFeature.State()) {
      SettingsFeature()
    }

    store.state.showingSignOutAlert = true

    await store.send(.cancelSignOut) {
      $0.showingSignOutAlert = false
    }
  }

  // MARK: - Error/Success Message Tests

  func testClearError() async {
    let store = TestStore(initialState: SettingsFeature.State()) {
      SettingsFeature()
    }

    store.state.errorMessage = "Some error"

    await store.send(.clearError) {
      $0.errorMessage = nil
    }
  }

  func testClearSuccess() async {
    let store = TestStore(initialState: SettingsFeature.State()) {
      SettingsFeature()
    }

    store.state.successMessage = "Success!"

    await store.send(.clearSuccess) {
      $0.successMessage = nil
    }
  }
}
